var gs = GameState_Get();
var w = display_get_gui_width();
var h = display_get_gui_height();
var margin = 8;

draw_set_alpha(1);

// HUD (overworld only)
if (room != rm_battle && gs.ui.mode == UI_NONE) {
    if (is_struct(gs.player_ch)) {
        draw_set_color(c_white);
        draw_text(margin, margin, "HP: " + string(gs.player_ch.hp) + "/" + string(gs.player_ch.max_hp));
        draw_text(margin, margin + 12, "MP: " + string(gs.player_ch.mp) + "/" + string(gs.player_ch.max_mp));
        draw_text(margin, margin + 24, "G: " + string(gs.player_ch.gold));
    }
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
        draw_sprite(icon, 0, bx + bw - iw - 6, by + bh - ih - 6);
    }

}

// Shop UI
if (gs.ui.mode == UI_SHOP) {
    var bx2 = margin;
    var by2 = h - 96 - margin;
    var bw2 = w - margin * 2;
    var bh2 = 96;

    draw_set_color(c_black);
    draw_rectangle(bx2, by2, bx2 + bw2, by2 + bh2, false);
    draw_set_color(c_white);
    draw_rectangle(bx2, by2, bx2 + bw2, by2 + bh2, true);

    draw_set_color(c_white);
    draw_text(bx2 + 8, by2 + 8, "Shop  Gold: " + string(gs.player_ch.gold));

    var list = gs.ui.shop_items;
    for (var i = 0; i < array_length(list); i++) {
        var item = ItemDB_Get(list[i].item_id);
        var yy = by2 + 28 + i * 14;
        if (i == gs.ui.shop_index) draw_text(bx2 + 6, yy, ">");
        draw_text(bx2 + 16, yy, item.name + "  " + string(list[i].price) + "G");
    }

    if (gs.ui.prompt != "") {
        draw_text(bx2 + 8, by2 + bh2 - 16, gs.ui.prompt);
    }
}
