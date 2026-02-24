var w = display_get_gui_width();
var h = display_get_gui_height();
var gs = GameState_Get();
if (gs.ui.mode == UI_SAVE) exit;

UI_SetFont();
var line_h = string_height("A");

// main menu
var row_gap = max(18, line_h + 4);
var bx1 = w * 0.3;
var bx2 = w * 0.7;
var pad_x = 6;
var pad_y = 4;
var list_rows = array_length(main_options);
var list_h = max(0, list_rows - 1) * row_gap + line_h + pad_y * 2;
var start_target_y = h * 0.62;
var start_min_y = h * 0.35;
var start_max_y = max(start_min_y, h - (h * 0.10) - list_h);
var start_y = clamp(start_target_y, start_min_y, start_max_y);

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
    var sw = w * 0.72;
    var sh = h * 0.62;
    var sx = (w - sw) * 0.5;
    var sy = (h - sh) * 0.5;
    var settings = GameSettings_Ensure();

    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(sx, sy, sx + sw, sy + sh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(sx, sy, sx + sw, sy + sh, true);
    draw_text(sx + 12, sy + 12, "Settings");

    var row_gap_s = max(18, line_h + 6);
    var audio_header_y = sy + 34;
    var audio_row_y0 = audio_header_y + row_gap_s;
    var display_header_y = audio_row_y0 + row_gap_s * 3 + 4;
    var display_row_y0 = display_header_y + row_gap_s;

    var row_y = [];
    row_y[0] = audio_row_y0;
    row_y[1] = audio_row_y0 + row_gap_s;
    row_y[2] = audio_row_y0 + row_gap_s * 2;
    row_y[3] = display_row_y0;
    row_y[4] = display_row_y0 + row_gap_s;
    row_y[5] = display_row_y0 + row_gap_s * 2;

    draw_set_color(c_white);
    draw_text(sx + 12, audio_header_y, "Audio");
    draw_text(sx + 12, display_header_y, "Display");

    var right_pad = 14;
    var btn_w = max(14, string_width("+") + 8);
    var btn_h = line_h + 4;
    var plus_x = sx + sw - right_pad - btn_w;
    var minus_x = plus_x - 6 - btn_w;
    var value_w = max(52, string_width("100%") + 8);
    var value_x = minus_x - 6 - value_w;

    for (var r = 0; r <= 5; r++) {
        var yy = row_y[r];
        var selected_row = (settings_index == r);
        var label = "";
        var value = "";

        switch (r) {
            case 0:
                label = "UI";
                value = string(round(settings.audio_ui * 100)) + "%";
                break;
            case 1:
                label = "SFX";
                value = string(round(settings.audio_sfx * 100)) + "%";
                break;
            case 2:
                label = "BGM";
                value = string(round(settings.audio_bgm * 100)) + "%";
                break;
            case 3:
                label = "Scale";
                value = string(settings.display_scale) + "x";
                break;
            case 4:
                label = "Fullscreen";
                value = settings.display_fullscreen ? "On" : "Off";
                break;
            case 5:
                label = "Back";
                break;
        }

        if (selected_row) {
            draw_set_color(c_white);
            draw_rectangle(sx + 8, yy - 3, sx + sw - 8, yy + line_h + 5, false);
            draw_set_color(c_black);
            draw_rectangle(sx + 8, yy - 3, sx + sw - 8, yy + line_h + 5, true);
        }

        draw_set_color(selected_row ? c_black : c_white);
        draw_text(sx + 16, yy, label);

        if (r <= 3) {
            var sel_minus = selected_row && settings_col == 0;
            var sel_plus = selected_row && settings_col == 2;

            if (sel_minus) {
                draw_set_color(c_white);
                draw_rectangle(minus_x - 1, yy - 2, minus_x + btn_w + 1, yy + btn_h + 1, false);
                draw_set_color(c_black);
                draw_rectangle(minus_x - 1, yy - 2, minus_x + btn_w + 1, yy + btn_h + 1, true);
            } else {
                draw_set_color(selected_row ? c_black : c_white);
                draw_rectangle(minus_x - 1, yy - 2, minus_x + btn_w + 1, yy + btn_h + 1, true);
            }

            if (sel_plus) {
                draw_set_color(c_white);
                draw_rectangle(plus_x - 1, yy - 2, plus_x + btn_w + 1, yy + btn_h + 1, false);
                draw_set_color(c_black);
                draw_rectangle(plus_x - 1, yy - 2, plus_x + btn_w + 1, yy + btn_h + 1, true);
            } else {
                draw_set_color(selected_row ? c_black : c_white);
                draw_rectangle(plus_x - 1, yy - 2, plus_x + btn_w + 1, yy + btn_h + 1, true);
            }

            draw_set_color(sel_minus ? c_black : (selected_row ? c_black : c_white));
            draw_text(minus_x + (btn_w - string_width("-")) * 0.5, yy, "-");

            draw_set_color(selected_row ? c_black : c_white);
            draw_text(value_x + (value_w - string_width(value)) * 0.5, yy, value);

            draw_set_color(sel_plus ? c_black : (selected_row ? c_black : c_white));
            draw_text(plus_x + (btn_w - string_width("+")) * 0.5, yy, "+");
        } else if (r == 4) {
            draw_set_color(selected_row ? c_black : c_white);
            draw_rectangle(value_x - 1, yy - 2, plus_x + btn_w + 1, yy + btn_h + 1, true);
            draw_text(value_x + (plus_x + btn_w - value_x - string_width(value)) * 0.5, yy, value);
        }
    }
}
