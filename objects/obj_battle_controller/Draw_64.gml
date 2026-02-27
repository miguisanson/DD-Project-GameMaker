var margin = 16;
var box_h = 96;

var w = display_get_gui_width();
var h = display_get_gui_height();

var gs = GameState_Get();

UI_SetFont();

var cam = view_camera[0];
var base_x = cam_base_x;
var base_y = cam_base_y;
var cam_off = CameraShake_Offset();
var vx = base_x + cam_off.x;
var vy = base_y + cam_off.y;
camera_set_view_pos(cam, vx, vy);
var vw = camera_get_view_width(cam);
var vh = camera_get_view_height(cam);
var sx = w / vw;
var sy = h / vh;
var gui_off_x = cam_off.x * sx;
var gui_off_y = cam_off.y * sy;
var row_h = max(16, string_height("A") + 2);

// Combat log (top-right, text-only)
if (!is_array(combat_log)) combat_log = [];
var log_lines = combat_log;
var log_count = array_length(log_lines);
var log_visible = 3;
var log_line_h = string_height("A") + 2;
var log_bottom = margin + (log_visible * log_line_h);
if (log_count > 0) {
    var log_start = max(0, log_count - log_visible);
    var max_w = w * 0.45;
    var log_base_x = w - margin;
    var log_base_y = margin;

    draw_set_alpha(1);
    draw_set_color(c_white);
    for (var li2 = log_start; li2 < log_count; li2++) {
        var row = li2 - log_start;
        var entry = log_lines[li2];
        var line = "";
        var icon_sprite = noone;
        var icon_subimg = 0;
        if (is_struct(entry) && variable_struct_exists(entry, "text")) {
            line = string(entry.text);
            if (variable_struct_exists(entry, "icon_sprite")) icon_sprite = entry.icon_sprite;
            if (variable_struct_exists(entry, "icon_subimg")) icon_subimg = round(entry.icon_subimg);
        } else {
            line = string(entry);
        }

        var icon_w = 0;
        if (icon_sprite != noone && icon_sprite != -1) {
            var iw = max(1, sprite_get_width(icon_sprite));
            icon_w = max(10, iw);
            var max_sub = max(0, sprite_get_number(icon_sprite) - 1);
            icon_subimg = clamp(icon_subimg, 0, max_sub);
        }

        var max_text_w = max_w - ((icon_w > 0) ? (icon_w + 4) : 0);
        while (string_width(line) > max_text_w && string_length(line) > 3) {
            line = string_copy(line, 1, string_length(line) - 4) + "...";
        }

        var line_w = string_width(line) + ((icon_w > 0) ? (icon_w + 4) : 0);
        var lx = log_base_x - line_w;
        var ly = log_base_y + row * log_line_h;
        if (icon_w > 0) {
            draw_sprite(icon_sprite, icon_subimg, lx, ly + 1);
            lx += icon_w + 4;
        }
        draw_text(lx, ly, line);
    }
}

// Skill banner (full-width, below HP/MP + log)
if (skill_banner_active && skill_banner_name != "") {
    var bar_scale = UI_BAR_SCALE;
    var hp_bar_h = sprite_get_height(hp_bar) * bar_scale;
    var mp_bar_h = sprite_get_height(mp_bar) * bar_scale;
    var hud_margin = 8;
    var hud_top = hud_margin + gui_off_y;
    var hud_bottom = hud_top + hp_bar_h + mp_bar_h + 4;
    var banner_y = max(hud_bottom + 6, log_bottom + 6);
    var banner_h = string_height("A") + 8;

    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(0, banner_y, w, banner_y + banner_h, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    var tx = (w - string_width(skill_banner_name)) * 0.5;
    var ty = banner_y + (banner_h - string_height("A")) * 0.5;
    draw_text(tx, ty, skill_banner_name);
}

// Enemy status icons below sprite (battle only)
if (instance_exists(enemy_inst)) {
    var espr = enemy_inst.sprite_index;
    var ex = (enemy_inst.x - sprite_get_xoffset(espr) - vx) * sx;
    var ey = (enemy_inst.y - sprite_get_yoffset(espr) - vy) * sy;
    var ew = sprite_get_width(espr) * sx;
    var eh = sprite_get_height(espr) * sy;
    var icon_y = ey + eh + 4;
    Status_DrawIcons(e, ex, icon_y, 12, false);
}

// bottom box rect
var bx = margin + gui_off_x;
var by = h - box_h - margin + gui_off_y;
var bw = w - margin * 2;
var bh = box_h;

// enemy sprite draw with shake/flash
if (instance_exists(enemy_inst)) {
    var off = SpriteShake_Offset(enemy_inst);
    var exs = (enemy_inst.x + off.x - vx) * sx;
    var eys = (enemy_inst.y + off.y - vy) * sy;
    var scx = enemy_inst.image_xscale * sx;
    var scy = enemy_inst.image_yscale * sy;
    if (off.flash) gpu_set_blendmode(bm_add);
    draw_sprite_ext(enemy_inst.sprite_index, enemy_inst.image_index, exs, eys, scx, scy, enemy_inst.image_angle, c_white, 1);
    if (off.flash) gpu_set_blendmode(bm_normal);
}

// Timed ATTACK UI
if (battle_state == BSTATE_ATTACK_TIMING && attack_timing_active) {
    var tx_t = round(attack_timing_target_x);
    var ty_t = round(attack_timing_target_y);
    var cx_t = round(attack_timing_x);
    var cy_t = round(attack_timing_y);
    var marker_alpha = clamp(attack_timing_marker_alpha, 0, 1);
    var pulse = 0.75 + (0.25 * sin(current_time * 0.02));
    marker_alpha = clamp(marker_alpha * pulse, 0, 1);

    // Target marker: black fill + thick white outline (fade in/pulse).
    draw_set_alpha(marker_alpha * 0.90);
    draw_set_color(c_black);
    draw_circle(tx_t, ty_t, ATTACK_TIMING_TARGET_RADIUS, true);

    draw_set_alpha(marker_alpha);
    draw_set_color(c_white);
    draw_circle(tx_t, ty_t, ATTACK_TIMING_TARGET_RADIUS, false);
    draw_circle(tx_t, ty_t, max(1, ATTACK_TIMING_TARGET_RADIUS - 1), false);
    draw_circle(tx_t, ty_t, max(1, ATTACK_TIMING_TARGET_RADIUS - 2), false);

    // Falling marker: thick white outline only, no fill.
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_circle(cx_t, cy_t, ATTACK_TIMING_RING_RADIUS, false);
    draw_circle(cx_t, cy_t, max(1, ATTACK_TIMING_RING_RADIUS - 1), false);
    draw_circle(cx_t, cy_t, max(1, ATTACK_TIMING_RING_RADIUS - 2), false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// Timed ATTACK feedback text
if (attack_timing_result_timer > 0 && attack_timing_result_text != "") {
    var t_norm = clamp(attack_timing_result_timer / max(1, ATTACK_TIMING_FEEDBACK_FRAMES), 0, 1);
    var tyf = attack_timing_target_y - 12 - ((1 - t_norm) * 6);
    var txf = attack_timing_target_x - (string_width(attack_timing_result_text) * 0.5);
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_text(txf + 1, tyf + 1, attack_timing_result_text);
    draw_set_color(c_white);
    draw_text(txf, tyf, attack_timing_result_text);
}

// FX draw (battle-only), over enemy sprite
with (obj_fx) {
    if (sprite_index != noone) {
        var fx_x = (x - vx) * sx;
        var fx_y = (y - vy) * sy;
        var fx_sx = image_xscale * sx;
        var fx_sy = image_yscale * sy;
        draw_sprite_ext(sprite_index, image_index, fx_x, fx_y, fx_sx, fx_sy, image_angle, image_blend, image_alpha);
    }
}


// DEBUG ENEMY HP
if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
    if (instance_exists(enemy_inst)) {
        var off2 = SpriteShake_Offset(enemy_inst);
        var espr2 = enemy_inst.sprite_index;
        var ex2 = (enemy_inst.x + off2.x - sprite_get_xoffset(espr2) - vx) * sx;
        var ey2 = (enemy_inst.y + off2.y - sprite_get_yoffset(espr2) - vy) * sy;
        draw_set_color(c_white);
        draw_text(ex2, ey2 - 12, string(e.hp));
    }
}

// MENU STATES ONLY
if (battle_state == BSTATE_MENU || battle_state == BSTATE_SKILL_MENU || battle_state == BSTATE_ITEM_MENU) {
    var box_pad = 12;
    if (battle_state == BSTATE_MENU) {
        var max_label_w = 0;
        for (var i = 0; i < array_length(battle_actions); i++) {
            max_label_w = max(max_label_w, string_width(battle_actions[i].label));
        }
        var selector_pad = 16;
        bw = max_label_w + box_pad * 2 + selector_pad;
        bh = (array_length(battle_actions) * row_h) + box_pad * 2;
        bx = w - margin - bw + gui_off_x;
        by = h - margin - bh + gui_off_y;
    } else {
        var rows_visible = 4;
        bh = (rows_visible * row_h) + box_pad * 2;
        bw = w - margin * 2;
        bx = margin + gui_off_x;
        by = h - margin - bh + gui_off_y;
    }
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, true);
}

// command menu
if (battle_state == BSTATE_MENU && turn == TURN_PLAYER) {
    var mx = bx + 16;
    var my = by + 12;

    for (var i = 0; i < array_length(battle_actions); i++) {
        var yy = my + i * row_h;
        if (i == menu_index) {
            draw_text(mx - 12, yy, ">");
        }
        draw_text(mx, yy, battle_actions[i].label);
    }
}

// skill menu
if (battle_state == BSTATE_SKILL_MENU) {
    var skills = Battle_GetSkillList(self);
    var mx2 = bx + 12;
    var my2 = by + 12;

    var skill_count = array_length(skills);
    var total = skill_count + 1;
    var rows_visible = 4;
    var start = clamp(skill_index - (rows_visible - 1), 0, max(0, total - rows_visible));
    var endv = min(total, start + rows_visible);

    for (var s = start; s < endv; s++) {
        var row = s - start;
        var yy = my2 + row * row_h;
        if (s == skill_count) {
            if (s == skill_index) draw_text(mx2 - 10, yy, ">");
            draw_text(mx2, yy, "Back");
        } else {
            var sk = SkillDB_Get(skills[s]);
            if (s == skill_index) draw_text(mx2 - 10, yy, ">");
            var tx = mx2;
            if (sk.icon_sprite != noone) {
                draw_sprite(sk.icon_sprite, 0, mx2, yy + 2);
                tx += 16;
            }
            draw_text(tx, yy, sk.name + " (" + string(sk.mp_cost) + "MP)");
        }
    }
}

// item menu
if (battle_state == BSTATE_ITEM_MENU) {
    var items = Battle_GetItemList(self);
    var mx3 = bx + 12;
    var my3 = by + 12;

    var item_count = array_length(items);
    var total = item_count + 1;
    var rows_visible = 4;
    var start = clamp(item_index - (rows_visible - 1), 0, max(0, total - rows_visible));
    var endv = min(total, start + rows_visible);

    for (var it = start; it < endv; it++) {
        var row = it - start;
        var yy2 = my3 + row * row_h;
        if (it == item_count) {
            if (it == item_index) draw_text(mx3 - 10, yy2, ">");
            draw_text(mx3, yy2, "Back");
        } else {
            var item = ItemDB_Get(items[it].id);
            if (it == item_index) draw_text(mx3 - 10, yy2, ">");
            var tx2 = mx3;
            if (item.sprite != noone) {
                draw_sprite(item.sprite, 0, mx3, yy2 + 2);
                tx2 += 16;
            }
            draw_text(tx2, yy2, item.name + " x" + string(items[it].qty));
        }
    }
}
