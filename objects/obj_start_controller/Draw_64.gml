var w = display_get_gui_width();
var h = display_get_gui_height();
var gs = GameState_Get();
if (state == "cutscene") exit;
var loading_into_game = Transition_IsActive()
&& variable_struct_exists(gs, "in_main_menu")
&& !gs.in_main_menu;

if (room == rm_start && title_bg_sprite != noone) {
    draw_sprite_stretched(title_bg_sprite, 0, 0, 0, w, h);
}

UI_SetFont();
var line_h = string_height("A");

var row_gap = max(18, line_h + 4);
var pad_x = 6;
var pad_y = 4;

if (!variable_instance_exists(id, "difficulty_options") || !is_array(difficulty_options) || array_length(difficulty_options) <= 0) {
    difficulty_options = ["Easy", "Normal", "Hard"];
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
        var yy = start_y + i * row_gap;
        var load_disabled = (label == "Load Game" && !can_load);
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
        draw_text(bx1 + 8, yy, label);
    }
}

if (state == "difficulty" && gs.ui.mode != UI_SAVE && !loading_into_game) {
    var difficulty_alpha = UI_PopupAlpha(difficulty_opened_frame, difficulty_closing, difficulty_close_frame, 1);
    var dw = w * 0.62;
    var dh = h * 0.44;
    var dx = (w - dw) * 0.5;
    var dy = (h - dh) * 0.5;

    draw_set_alpha(difficulty_alpha * 0.88);
    draw_set_color(c_black);
    draw_rectangle(dx, dy, dx + dw, dy + dh, false);
    draw_set_alpha(difficulty_alpha);
    draw_set_color(c_white);
    draw_rectangle(dx, dy, dx + dw, dy + dh, true);
    draw_text(dx + 12, dy + 12, "Select Difficulty");

    var drow_gap = max(18, line_h + 6);
    var start_y2 = dy + 36;
    for (var di2 = 0; di2 < array_length(difficulty_options); di2++) {
        var dlabel = difficulty_options[di2];
        var dyy = start_y2 + di2 * drow_gap;
        var dsel = (di2 == difficulty_index);

        if (dsel) {
            draw_set_color(c_white);
            draw_rectangle(dx + 10 - pad_x, dyy - pad_y, dx + dw - 10 + pad_x, dyy + line_h + pad_y, false);
            draw_set_color(c_black);
            draw_rectangle(dx + 10 - pad_x, dyy - pad_y, dx + dw - 10 + pad_x, dyy + line_h + pad_y, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }

        draw_text(dx + 18, dyy, dlabel);
    }

    var back_y = dy + dh - (line_h + 8);
    var back_sel = (difficulty_index == array_length(difficulty_options));
    if (back_sel) {
        draw_set_color(c_white);
        draw_rectangle(dx + 10 - pad_x, back_y - pad_y, dx + dw - 10 + pad_x, back_y + line_h + pad_y, false);
        draw_set_color(c_black);
        draw_rectangle(dx + 10 - pad_x, back_y - pad_y, dx + dw - 10 + pad_x, back_y + line_h + pad_y, true);
        draw_set_color(c_black);
    } else {
        draw_set_color(c_white);
    }
    draw_text(dx + 18, back_y, "Back");
}

if (SettingsPopup_IsOpen("title") && !loading_into_game) {
    SettingsPopup_Draw();
}
draw_set_alpha(1);
