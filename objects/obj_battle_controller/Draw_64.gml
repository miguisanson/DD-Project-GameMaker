var margin = 16;
var box_h = 96;

var w = display_get_gui_width();
var h = display_get_gui_height();

var gs = GameState_Get();

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
    var base_x = w - margin;
    var base_y = margin;

    draw_set_alpha(1);
    draw_set_color(c_white);
    for (var li2 = log_start; li2 < log_count; li2++) {
        var row = li2 - log_start;
        var line = log_lines[li2];
        while (string_width(line) > max_w && string_length(line) > 3) {
            line = string_copy(line, 1, string_length(line) - 4) + "...";
        }
        var lx = base_x - string_width(line);
        var ly = base_y + row * log_line_h;
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

// FX draw (battle-only), over enemy sprite
with (obj_fx) {
    if (sprite_index != noone) {
        var fx_x = (x - sprite_get_xoffset(sprite_index) - vx) * sx;
        var fx_y = (y - sprite_get_yoffset(sprite_index) - vy) * sy;
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
    var row_h = 16;
    var box_pad = 12;
    if (battle_state == BSTATE_MENU) {
        var max_label_w = 0;
        for (var i = 0; i < array_length(battle_actions); i++) {
            max_label_w = max(max_label_w, string_width(battle_actions[i].label));
        }
        bw = max_label_w + box_pad * 2 + 12;
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
    var mx = bx + 12;
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
        var yy = my2 + row * 16;
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
        var yy2 = my3 + row * 16;
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
