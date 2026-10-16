Display_DrawFrame();   // first Draw GUI of the frame draws the world

var w = Display_GuiW();
var h = Display_GuiH();

var gs = GameState_Get();
var transition_alpha = 0;
if (is_struct(gs)
&& variable_struct_exists(gs, "transition_fx")
&& is_struct(gs.transition_fx)
&& variable_struct_exists(gs.transition_fx, "active")
&& gs.transition_fx.active
&& variable_struct_exists(gs.transition_fx, "alpha")) {
    transition_alpha = clamp(real(gs.transition_fx.alpha), 0, 1);
}
var enemy_fade_alpha = 1 - transition_alpha;

UI_SetFont();

var cam = view_camera[0];
var base_x = cam_base_x;
var base_y = cam_base_y;
var cam_off = CameraShake_Offset();
var vx = base_x + cam_off.x;
var vy = base_y + cam_off.y;
camera_set_view_pos(cam, vx, vy);
var port_x = 0;   // the GUI origin is the picture's corner, so there is no port offset
var port_y = 0;
var sx = Display_WorldScale();
var sy = sx;

Battle_HudFrameBegin(self);   // D108 F1d-1: the strip's metrics, the enemy header rect and the chips are built once for this frame (End below)
var zones = Battle_Zones();   // D99: where the panels, the log and the menus sit
hud.rects.log = undefined;
hud.rects.preview = undefined;   // D135: the plate beside the command menu (Battle_DrawAttackPreview sets it while the cursor is on ATTACK)

// enemy sprite draw with shake/flash. D138 / D139: through the picture's push-in (zr), squashed by the recoil, light-flashed in the hit freeze and the death
// freeze, and not drawn once it has burst.
var zr = feel_zr;
var dp = death_pop;
var dying = is_struct(dp);
if (instance_exists(enemy_inst) && (!dying || Feel_SpriteVisible(dp.t_ms))) {
    var off = SpriteShake_Offset(enemy_inst);
    var espr = enemy_inst.sprite_index;
    var rec = Feel_RecoilScale(feel_ms - feel_hit_start, Settings_ShakeOn());
    var base_sx = enemy_inst.image_xscale * sx * zr.kx;
    var base_sy = enemy_inst.image_yscale * sx * zr.ky;
    var exs = port_x + (((enemy_inst.x + off.x - vx) - zr.sx) * zr.kx * sx);
    var eys = port_y + (((enemy_inst.y + off.y - vy) - zr.sy) * zr.ky * sx);
    var scx = base_sx * rec.x;
    var scy = base_sy * rec.y;
    if (espr != noone && (rec.x != 1 || rec.y != 1)) {   // squash about the bottom centre: the feet stay put
        var sw_g = sprite_get_width(espr) * abs(base_sx);
        var sh_g = sprite_get_height(espr) * abs(base_sy);
        var left = exs - sprite_get_xoffset(espr) * base_sx;
        var top = eys - sprite_get_yoffset(espr) * base_sy;
        left += (sw_g - sw_g * rec.x) * 0.5;
        top += (sh_g - sh_g * rec.y);
        exs = left + sprite_get_xoffset(espr) * scx;
        eys = top + sprite_get_yoffset(espr) * scy;
    }
    Battle_DrawEnemyShadow(espr, exs, eys, scx, scy, sx * zr.ky, enemy_fade_alpha);   // R3 (note 5): a soft shadow under the feet, in the same guard as the sprite (gone once it has burst)
    var white = (dying && !Battle_DeathPopHeld(self) && dp.t_ms < FEEL_DEATH_FREEZE_MS) || (hitstop_ms > 0 && feel_contact && last_dmg > 0);   // IDEA-21: not during a boss's held beat (the flash is the pop's)
    if (white) gpu_set_fog(true, UI_C_LIGHTEST, 0, 1);   // every opaque pixel in the lightest palette colour
    else if (off.flash) gpu_set_blendmode(bm_add);
    draw_sprite_ext(enemy_inst.sprite_index, enemy_inst.image_index, exs, eys, scx, scy, enemy_inst.image_angle, c_white, enemy_fade_alpha);
    if (white) gpu_set_fog(false, c_white, 0, 0);
    else if (off.flash) gpu_set_blendmode(bm_normal);
}
var header_a = dying ? clamp(1 - (dp.t_ms - FEEL_DEATH_FREEZE_MS) / 100, 0, 1) : 1;   // the name and bars fade as the enemy bursts
Battle_DrawEnemyHeader(self, enemy_fade_alpha * header_a);   // name, HP, stagger meter and status chips above the enemy (D99, D75)

// The basic attack's sliding bar (D56), sized in world pixels (sx GUI units each) so it is crisp at every window scale: below the enemy
// (no menu is up during the bar). Fades in during the lead-in.
if (battle_state == BSTATE_ATTACK_TIMING && qte_active) {
    var bar_w = round(QTE_BAR_W * sx);
    var bar_h = round(QTE_BAR_H * sx);
    var bar_x = round((w - bar_w) * 0.5);
    var bar_y = Battle_QteAnchorY(self, bar_h);
    var bar_alpha = clamp((qte_ms + QTE_LEAD_IN_MS) / 100, 0, 1);
    Qte_DrawBar(bar_x, bar_y, bar_w, bar_h, qte_params, qte_assist, qte_ms, sx, bar_alpha);
}

// The grade word over the enemy, in its own colour and size.
if (qte_result_ms > 0 && qte_result_text != "") {
    Qte_DrawGradeWord(qte_result_key, qte_result_text, qte_word_x, qte_word_y - round(8 * sx), qte_result_ms, sx);
}

// FX draw (battle-only), over enemy sprite
with (obj_fx) {
    if (sprite_index != noone) {
        var fx_x = port_x + (((x - vx) - zr.sx) * zr.kx * sx);
        var fx_y = port_y + (((y - vy) - zr.sy) * zr.ky * sy);
        var fx_sx = image_xscale * sx * zr.kx;
        var fx_sy = image_yscale * sy * zr.ky;
        draw_sprite_ext(sprite_index, image_index, fx_x, fx_y, fx_sx, fx_sy, image_angle, image_blend, image_alpha * enemy_fade_alpha);
    }
}

Battle_DrawFeelFx(self, vx, vy, sx);   // D138: hit sparks and the death burst
Battle_DrawPops(self);   // floating damage numbers and the BREAK word (D92)
Battle_DrawFeelEdges(self, sx);   // D138 / D139: the dark edge flash of a big hit taken and the faint low-HP pulse, under the HUD

Battle_DrawTimeline(self);   // the turn strip across the top (D74, D99)
Battle_DrawBanner(self, 1);  // the move's name (or the wind-up / phase line) while it is up
Battle_DrawPlayerPanel(self, zones, 1);   // HP, MP and statuses, bottom left (D99)

// The log: a plate above the bottom panels for the latest lines, only while no list or bar is up (I-067)
if (battle_state != BSTATE_SKILL_MENU && battle_state != BSTATE_ITEM_MENU && battle_state != BSTATE_ATTACK_TIMING
&& battle_state != BSTATE_SKILL_QTE && battle_state != BSTATE_ENEMY_DEFENCE) {
    Battle_DrawLog(self, zones);
}

// A player skill's arrow sequence (D57) and its time bar, in the same place as the attack bar.
if (battle_state == BSTATE_SKILL_QTE && sq_active) {
    Qte_DrawSequence(round(w * 0.5), Battle_QteAnchorY(self, Qte_SequenceHeight(sx)), sq_st, sq_wrong_ms, sq_pop_ms, sq_pop_idx, sx, clamp((sq_ms + QTE_SEQ_LEAD_IN_MS) / 100, 0, 1));
}

// A big enemy attack (D59): "!" over the enemy while it winds up (its name is the skill banner), then the defence bar.
if (battle_state == BSTATE_ENEMY_DEFENCE && def_active) {
    if (def_ms < -QTE_LEAD_IN_MS) {
        var tele_x = round(w * 0.5);
        var tele_y = round(h * 0.3);
        if (instance_exists(enemy_inst) && enemy_inst.sprite_index != noone) {
            var tspr = enemy_inst.sprite_index;
            // beside the enemy's upper right, clear of the header plate over its head
            var tele_left = port_x + ((enemy_inst.x - sprite_get_xoffset(tspr) - vx) * sx);
            var tele_top = port_y + ((enemy_inst.y - sprite_get_yoffset(tspr) - vy) * sy);
            tele_x = tele_left + (sprite_get_width(tspr) * abs(enemy_inst.image_xscale) * sx) + (8 * sx);
            tele_y = tele_top + (sprite_get_height(tspr) * abs(enemy_inst.image_yscale) * sy * 0.3);
        }
        Qte_DrawTelegraph(tele_x, tele_y, def_ms + QTE_TELEGRAPH_MS + QTE_LEAD_IN_MS, sx);
    } else {
        var dbar_w = round(QTE_BAR_W * sx);
        var dbar_h = round(QTE_BAR_H * sx);
        var dbar_alpha = clamp((def_ms + QTE_LEAD_IN_MS) / 100, 0, 1);
        Qte_DrawBar(round((w - dbar_w) * 0.5), Battle_QteAnchorY(self, dbar_h), dbar_w, dbar_h, def_params, def_assist, def_ms, sx, dbar_alpha);
    }
}

// DEBUG ENEMY HP
if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
    if (instance_exists(enemy_inst)) {
        var off2 = SpriteShake_Offset(enemy_inst);
        var espr2 = enemy_inst.sprite_index;
        var ex2 = port_x + ((enemy_inst.x + off2.x - sprite_get_xoffset(espr2) - vx) * sx);
        var ey2 = port_y + ((enemy_inst.y + off2.y - sprite_get_yoffset(espr2) - vy) * sy);
        draw_set_color(c_white);
        UI_DrawText(ex2, ey2 - 12, string(e.hp));
    }
}

// The command menu, or the skill / item list with its details panel (D95, D99, D100): last, so it is on top of everything.
Battle_DrawMenus(self);
Battle_DrawSpeedMark(self);   // D134: "x2" in the top right corner while run is held and no QTE is up
Battle_DrawChipTip(self);   // D150: the full sentence of the status chip under the mouse

// what the last draw used, for the tests (nothing may overlap, I-067) and the shots
hud.rects.zones = zones;
hud.rects.chips = Battle_HudFrame().chip_rects;   // D150: every chip with its label, as drawn
var tl_m = Battle_TimelineMetrics(self);
hud.rects.timeline = { x: tl_m.x0, y: tl_m.y0, w: tl_m.w, h: tl_m.plate_h };
var hdr_r = Battle_EnemyHeaderRect(self);
hud.rects.header = { x: hdr_r.x1, y: hdr_r.y1, w: hdr_r.bw, h: hdr_r.h };
hud.rects.cmd = is_struct(ui_cmd) ? ui_cmd.rect : undefined;
hud.rects.list = (battle_state == BSTATE_SKILL_MENU) ? ui_skill.rect : ((battle_state == BSTATE_ITEM_MENU) ? ui_item.rect : undefined);
hud.rects.details = (battle_state == BSTATE_SKILL_MENU) ? ui_skill.det_rect : ((battle_state == BSTATE_ITEM_MENU) ? ui_item.det_rect : undefined);
Battle_HudFrameEnd();

draw_set_alpha(1);
draw_set_color(c_white);

if (gs.ui.mode == UI_MENU) Menu_Draw();   // R1b (D122), D140: the one menu goes over the battle HUD, dimming it
Tutorial_Draw();   // C4 (D45): the first-time pop-up goes over the whole battle screen (the ui controller draws it in the other rooms)
MouseCursor_Draw();   // D182: the mouse cursor, over the battle HUD, the menu and the pop-up (the ui controller draws it too, for the rooms without a fight)
