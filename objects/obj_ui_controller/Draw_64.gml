var gs = GameState_Get();
var w = display_get_gui_width();
var h = display_get_gui_height();
var margin = 8;

draw_set_alpha(1);

// HUD (battle only)
var ch = gs.player_ch;
if (room == rm_battle && instance_exists(obj_battle_controller)) {
    var bc = instance_find(obj_battle_controller, 0);
    if (instance_exists(bc) && is_struct(bc.p)) ch = bc.p;
}

if (room == rm_battle && is_struct(ch)) {
    var hp_bar_sprite = hp_bar;
    var mp_bar_sprite = mp_bar;
    var max_frame = min(10, sprite_get_number(hp_bar_sprite) - 1);
    if (max_frame < 0) max_frame = 0;

    var hp_ratio = 0;
    if (ch.max_hp > 0) hp_ratio = clamp(ch.hp / ch.max_hp, 0, 1);
    var hp_frame = clamp(floor(hp_ratio * max_frame), 0, max_frame);

    var mp_ratio = 0;
    if (ch.max_mp > 0) mp_ratio = clamp(ch.mp / ch.max_mp, 0, 1);
    var mp_frame = clamp(floor(mp_ratio * max_frame), 0, max_frame);

    var scale = UI_BAR_SCALE;
    var bar_w = sprite_get_width(hp_bar_sprite) * scale;
    var bar_h = sprite_get_height(hp_bar_sprite) * scale;

    var bar_x = margin;
    var bar_y = margin;
    draw_sprite_ext(hp_bar_sprite, hp_frame, bar_x, bar_y, scale, scale, 0, c_white, 1);
    draw_sprite_ext(mp_bar_sprite, mp_frame, bar_x, bar_y + bar_h + 4, scale, scale, 0, c_white, 1);

    // Player status icons below MP bar
    var icon_y = bar_y + (bar_h * 2) + 10;
    Status_DrawIcons(ch, bar_x, icon_y, 12, false);

}

if (gs.ui.mode == UI_MENU) {
    Menu_Draw();
    exit;
}

// Dialogue box
if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
    var bx = margin;
    var by = h - 64 - margin;
    var bw = w - margin * 2;
    var bh = 64;

    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);

    var line = "";
    if (array_length(gs.ui.lines) > 0) {
        line = gs.ui.lines[gs.ui.index];
    }

    var speaker = "";
    if (variable_struct_exists(gs.ui, "speaker")) speaker = gs.ui.speaker;

    draw_set_color(c_white);
    if (speaker != "") {
        draw_text(bx + 8, by + 6, speaker + ":");
        draw_text(bx + 8, by + 22, line);
    } else {
        draw_text(bx + 8, by + 8, line);
    }
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
        var dy = by + bh - 32 - 6;
        draw_sprite_ext(icon, frame, dx, dy, scale_x, scale_y, 0, c_white, 1);
    }

}


// Debug indicator
if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
    draw_set_color(c_yellow);
    draw_text(8, 8, "DEBUG MODE: ON");
}
