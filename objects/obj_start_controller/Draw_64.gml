var w = display_get_gui_width();
var h = display_get_gui_height();
var gs = GameState_Get();
if (gs.ui.mode == UI_SAVE) exit;

UI_SetFont();
var line_h = string_height("A");

// main menu
var title = "MAIN MENU";
var tx = (w - string_width(title)) * 0.5;
var ty = h * 0.2;
var row_gap = max(18, line_h + 4);

draw_set_color(c_white);
draw_text(tx, ty, title);

var start_y = h * 0.35;
var bx1 = w * 0.3;
var bx2 = w * 0.7;
var pad_x = 6;
var pad_y = 4;

for (var i = 0; i < array_length(main_options); i++) {
    var label = main_options[i];
    var yy = start_y + i * row_gap;
    if (state == "main" && i == main_index) {
        draw_set_color(c_white);
        draw_rectangle(bx1 - pad_x, yy - pad_y, bx2 + pad_x, yy + line_h + pad_y, false);
        draw_set_color(c_black);
        draw_rectangle(bx1 - pad_x, yy - pad_y, bx2 + pad_x, yy + line_h + pad_y, true);
        draw_set_color(c_black);
    } else {
        draw_set_color(c_white);
    }
    draw_text(bx1 + 8, yy, label);
}

// class select popup
if (state == "class") {
    var bw = w * 0.6;
    var bh = h * 0.5;
    var bx = (w - bw) * 0.5;
    var by = (h - bh) * 0.5;

    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);

    var ctitle = "Select Class";
    draw_set_color(c_white);
    draw_text(bx + 12, by + 12, ctitle);

    var cy = by + 40;
    for (var j = 0; j < array_length(choices); j++) {
        var c = choices[j];
        var yy2 = cy + j * row_gap;
        if (j == class_index) {
            draw_set_color(c_white);
            draw_rectangle(bx + 10 - pad_x, yy2 - pad_y, bx + bw - 10 + pad_x, yy2 + line_h + pad_y, false);
            draw_set_color(c_black);
            draw_rectangle(bx + 10 - pad_x, yy2 - pad_y, bx + bw - 10 + pad_x, yy2 + line_h + pad_y, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        draw_text(bx + 18, yy2, c);
    }

    // Back label
    var back_y = by + bh - (line_h + 4);
    if (class_index == array_length(choices)) {
        draw_set_color(c_white);
        draw_rectangle(bx + 10 - pad_x, back_y - pad_y, bx + bw - 10 + pad_x, back_y + line_h + pad_y, false);
        draw_set_color(c_black);
        draw_rectangle(bx + 10 - pad_x, back_y - pad_y, bx + bw - 10 + pad_x, back_y + line_h + pad_y, true);
        draw_set_color(c_black);
    } else {
        draw_set_color(c_white);
    }
    draw_text(bx + 18, back_y, "Back");
}

// settings popup
if (state == "settings") {
    var sw = w * 0.6;
    var sh = h * 0.4;
    var sx = (w - sw) * 0.5;
    var sy = (h - sh) * 0.5;

    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(sx, sy, sx + sw, sy + sh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(sx, sy, sx + sw, sy + sh, true);
    draw_text(sx + 12, sy + 12, "Settings");

    var sbx = sx + 12;
    var sby = sy + sh - (line_h + 4);
    var swid = string_width("Back");
    if (settings_index == 0) {
        draw_set_color(c_white);
        draw_rectangle(sbx - 4, sby - 2, sbx + swid + 4, sby + line_h + 2, false);
        draw_set_color(c_black);
        draw_rectangle(sbx - 4, sby - 2, sbx + swid + 4, sby + line_h + 2, true);
        draw_set_color(c_black);
    } else {
        draw_set_color(c_white);
    }
    draw_text(sbx, sby, "Back");
}
