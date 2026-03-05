var w = display_get_gui_width();
var h = display_get_gui_height();
var gs = GameState_Get();
if (state == "boot_logo") {
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);

    var logo_spr = boot_logo_sprite;
    if (logo_spr == noone || logo_spr == -1) logo_spr = pale_rook_1;
    if (logo_spr != noone && logo_spr != -1 && boot_logo_alpha > 0) {
        var logo_scale = 3;
        var lw = sprite_get_width(logo_spr) * logo_scale;
        var lh = sprite_get_height(logo_spr) * logo_scale;
        var lx = round((w - lw) * 0.5);
        var ly = round((h - lh) * 0.5);
        draw_set_color(c_white);
        draw_sprite_ext(logo_spr, 0, lx, ly, logo_scale, logo_scale, 0, c_white, clamp(boot_logo_alpha, 0, 1));
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
    exit;
}
if (state == "cutscene") exit;
var loading_into_game = Transition_IsActive()
&& variable_struct_exists(gs, "in_main_menu")
&& !gs.in_main_menu;

if (room == rm_start && title_bg_sprite != noone) {
    draw_sprite_stretched(title_bg_sprite, 0, 0, 0, w, h);
}

UI_SetFont();
var line_h = UI_TextHeight("A");

var row_gap = max(18, line_h + 4);
var pad_x = 6;
var pad_y = 4;
var text_pad = max(8, round(line_h * 0.25));

if (!variable_instance_exists(id, "difficulty_options") || !is_array(difficulty_options) || array_length(difficulty_options) <= 0) {
    difficulty_options = [
        Loc_T("settings.difficulty.option.0", "Easy"),
        Loc_T("settings.difficulty.option.1", "Normal"),
        Loc_T("settings.difficulty.option.2", "Hard")
    ];
}
if (!variable_instance_exists(id, "difficulty_values") || !is_array(difficulty_values) || array_length(difficulty_values) != array_length(difficulty_options)) {
    difficulty_values = [DIFFICULTY_EASY, DIFFICULTY_NORMAL, DIFFICULTY_HARD];
}
if (!variable_instance_exists(id, "difficulty_index")) {
    difficulty_index = 1;
}
var difficulty_row_count = array_length(difficulty_options) + 1; // + Back row
difficulty_index = clamp(difficulty_index, 0, max(0, difficulty_row_count - 1));

if (state == "main" && gs.ui.mode != UI_SAVE && !loading_into_game) {
    var can_load = true;
    if (variable_instance_exists(id, "load_available")) can_load = load_available;
    else can_load = Save_HasAnySlot();

    // main menu
    var bx1 = w * 0.3;
    var bx2 = w * 0.7;
    var list_rows = array_length(main_options);
    var list_h = max(0, list_rows - 1) * row_gap + line_h + pad_y * 2;
    var start_target_y = h * 0.62;
    var start_min_y = h * 0.35;
    var start_max_y = max(start_min_y, h - (h * 0.10) - list_h);
    var start_y = clamp(start_target_y, start_min_y, start_max_y);

    for (var i = 0; i < array_length(main_options); i++) {
        var label = main_options[i];
        if (variable_instance_exists(id, "main_option_keys") && is_array(main_option_keys) && i < array_length(main_option_keys)) {
            label = Loc_T(main_option_keys[i], label);
        }
        var yy = start_y + i * row_gap;
        var load_disabled = (i == 1 && !can_load);
        var selected = (state == "main" && i == main_index && !load_disabled);

        if (selected) {
            draw_set_color(c_white);
            draw_rectangle(bx1 - pad_x, yy - pad_y, bx2 + pad_x, yy + line_h + pad_y, false);
            draw_set_color(c_black);
            draw_rectangle(bx1 - pad_x, yy - pad_y, bx2 + pad_x, yy + line_h + pad_y, true);
            draw_set_color(c_black);
        } else {
            if (load_disabled) draw_set_color(c_gray);
            else draw_set_color(c_white);
        }
        UI_DrawText(bx1 + text_pad, yy, label);
    }
}

if (state == "difficulty" && gs.ui.mode != UI_SAVE && !loading_into_game) {
    var difficulty_alpha = UI_PopupAlpha(difficulty_opened_frame, difficulty_closing, difficulty_close_frame, 1);
    var title_txt = Loc_T("menu.difficulty.title", "Select Difficulty");
    var side_pad = max(18, round(line_h * 0.45));
    var title_pad_x = max(12, round(line_h * 0.30));
    var title_pad_y = max(12, round(line_h * 0.30));
    var section_gap = max(6, round(line_h * 0.25));
    var drow_gap = max(18, line_h + max(6, round(line_h * 0.15)));

    var widest = max(UI_TextWidth(title_txt), UI_TextWidth(Loc_T("menu.common.back", "Back")));
    for (var diw = 0; diw < array_length(difficulty_options); diw++) {
        var dlbl_w = difficulty_options[diw];
        if (variable_instance_exists(id, "difficulty_option_keys") && is_array(difficulty_option_keys) && diw < array_length(difficulty_option_keys)) {
            dlbl_w = Loc_T(difficulty_option_keys[diw], dlbl_w);
        }
        widest = max(widest, UI_TextWidth(dlbl_w));
    }

    var need_w = widest + side_pad * 2;
    var need_h = title_pad_y + line_h + section_gap + (array_length(difficulty_options) * drow_gap) + section_gap + line_h + title_pad_y;
    var dw = min(w - 24, max(w * 0.62, need_w));
    var dh = min(h - 24, max(h * 0.44, need_h));
    var dx = (w - dw) * 0.5;
    var dy = (h - dh) * 0.5;
    var title_y = dy + title_pad_y;
    var start_y2 = title_y + line_h + section_gap;
    var back_y = dy + dh - (title_pad_y + line_h);
    var row_left = dx + max(10, round(line_h * 0.25));
    var row_right = dx + dw - max(10, round(line_h * 0.25));

    draw_set_alpha(difficulty_alpha * 0.6);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);
    draw_set_alpha(difficulty_alpha * 0.88);
    draw_set_color(c_black);
    draw_rectangle(dx, dy, dx + dw, dy + dh, false);
    draw_set_alpha(difficulty_alpha);
    draw_set_color(c_white);
    draw_rectangle(dx, dy, dx + dw, dy + dh, true);
    draw_set_alpha(difficulty_alpha);
    UI_DrawText(dx + title_pad_x, title_y, title_txt);

    for (var di2 = 0; di2 < array_length(difficulty_options); di2++) {
        var dlabel = difficulty_options[di2];
        if (variable_instance_exists(id, "difficulty_option_keys") && is_array(difficulty_option_keys) && di2 < array_length(difficulty_option_keys)) {
            dlabel = Loc_T(difficulty_option_keys[di2], dlabel);
        }
        var dyy = start_y2 + di2 * drow_gap;
        var dsel = (di2 == difficulty_index);

        if (dsel) {
            draw_set_color(c_white);
            draw_rectangle(row_left - pad_x, dyy - pad_y, row_right + pad_x, dyy + line_h + pad_y, false);
            draw_set_color(c_black);
            draw_rectangle(row_left - pad_x, dyy - pad_y, row_right + pad_x, dyy + line_h + pad_y, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }

        UI_DrawText(dx + side_pad, dyy, dlabel);
    }

    var back_sel = (difficulty_index == array_length(difficulty_options));
    if (back_sel) {
        draw_set_color(c_white);
        draw_rectangle(row_left - pad_x, back_y - pad_y, row_right + pad_x, back_y + line_h + pad_y, false);
        draw_set_color(c_black);
        draw_rectangle(row_left - pad_x, back_y - pad_y, row_right + pad_x, back_y + line_h + pad_y, true);
        draw_set_color(c_black);
    } else {
        draw_set_color(c_white);
    }
    UI_DrawText(dx + side_pad, back_y, Loc_T("menu.common.back", "Back"));
}

if (SettingsPopup_IsOpen("title") && !loading_into_game) {
    SettingsPopup_Draw();
}
draw_set_alpha(1);
