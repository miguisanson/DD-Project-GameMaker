var margin = 16;
var box_h = 96;

var w = display_get_gui_width();
var h = display_get_gui_height();

var gs = GameState_Get();

var cam = view_camera[0];
var vx = camera_get_view_x(cam);
var vy = camera_get_view_y(cam);
var vw = camera_get_view_width(cam);
var vh = camera_get_view_height(cam);
var sx = w / vw;
var sy = h / vh;

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
var bx = margin;
var by = h - box_h - margin;
var bw = w - margin * 2;
var bh = box_h;

// MESSAGE STATE ONLY
if (battle_state == BSTATE_MESSAGE) {
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, true);

    draw_set_color(c_black);
    draw_text(bx + 12, by + 12, message_text);
    var icon = asset_get_index("button_A_icon");
    if (icon != -1) {
        var iw = sprite_get_width(icon);
        var ih = sprite_get_height(icon);
        var scale_x = 32 / max(1, iw);
        var scale_y = 32 / max(1, ih);
        var frames = sprite_get_number(icon);
        var frame = 0;
        if (frames > 1) frame = floor(gs.ui.icon_frame);
        var dx = bx + bw - 32 - 6;
        var dy = by + bh - 32 - 10;
        draw_sprite_ext(icon, frame, dx, dy, scale_x, scale_y, 0, c_white, 1);
    }
}

// MENU STATES ONLY
if (battle_state == BSTATE_MENU || battle_state == BSTATE_SKILL_MENU || battle_state == BSTATE_ITEM_MENU) {
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, true);
}

// command menu
if (battle_state == BSTATE_MENU && turn == TURN_PLAYER) {
    var menu_w = 60;
    var mx = bx + bw - menu_w;
    var my = by + 12;

    for (var i = 0; i < array_length(battle_actions); i++) {
        var yy = my + i * 18;
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
    for (var s = 0; s < skill_count; s++) {
        var sk = SkillDB_Get(skills[s]);
        var yy = my2 + s * 16;
        if (s == skill_index) draw_text(mx2 - 10, yy, ">");
        var tx = mx2;
        if (sk.icon_sprite != noone) {
            draw_sprite(sk.icon_sprite, 0, mx2, yy + 2);
            tx += 16;
        }
        draw_text(tx, yy, sk.name + " (" + string(sk.mp_cost) + "MP)");
    }

    var back_y = my2 + skill_count * 16;
    if (skill_index == skill_count) draw_text(mx2 - 10, back_y, ">");
    draw_text(mx2, back_y, "Back");
}

// item menu
if (battle_state == BSTATE_ITEM_MENU) {
    var items = Battle_GetItemList(self);
    var mx3 = bx + 12;
    var my3 = by + 12;

    var item_count = array_length(items);
    for (var it = 0; it < item_count; it++) {
        var item = ItemDB_Get(items[it].id);
        var yy2 = my3 + it * 16;
        if (it == item_index) draw_text(mx3 - 10, yy2, ">");
        var tx2 = mx3;
        if (item.sprite != noone) {
            draw_sprite(item.sprite, 0, mx3, yy2 + 2);
            tx2 += 16;
        }
        draw_text(tx2, yy2, item.name + " x" + string(items[it].qty));
    }

    var back_y2 = my3 + item_count * 16;
    if (item_index == item_count) draw_text(mx3 - 10, back_y2, ">");
    draw_text(mx3, back_y2, "Back");
}
