var debug_enabled = variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled;
var audio_debug_enabled = variable_global_exists("audio_debug_enabled") && global.audio_debug_enabled;
if (!debug_enabled && !audio_debug_enabled) exit;

var ui_x = 8;
var ui_y = 8;
var line_h = 14;
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
var ui_w = max(180, gui_w - 16);

draw_set_alpha(1);
draw_set_color(c_white);
draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var gs = GameState_Get();
var class_name = "Unknown";
var class_id = variable_global_exists("selected_class") ? global.selected_class : -1;
switch (class_id) {
    case CLASS_KNIGHT: class_name = "Knight"; break;
    case CLASS_ARCHER: class_name = "Archer"; break;
    case CLASS_MAGE: class_name = "Mage"; break;
    case CLASS_NOBODY: class_name = "Nobody"; break;
}

var difficulty_name = "Unknown";
var diff_id = variable_global_exists("difficulty") ? global.difficulty : DIFFICULTY_NORMAL;
switch (diff_id) {
    case DIFFICULTY_EASY: difficulty_name = "Easy"; break;
    case DIFFICULTY_NORMAL: difficulty_name = "Normal"; break;
    case DIFFICULTY_HARD: difficulty_name = "Hard"; break;
}

var ui_mode_name = "None";
var ui_mode_id = (variable_struct_exists(gs, "ui") && variable_struct_exists(gs.ui, "mode")) ? gs.ui.mode : UI_NONE;
switch (ui_mode_id) {
    case UI_DIALOGUE: ui_mode_name = "Dialogue"; break;
    case UI_MENU: ui_mode_name = "Menu"; break;
    case UI_SAVE: ui_mode_name = "Save"; break;
    case UI_PAUSE: ui_mode_name = "Pause"; break;
    case UI_CLASS_SELECT: ui_mode_name = "Class Select"; break;
    case UI_BED: ui_mode_name = "Bed"; break;
}

var player_hp = "n/a";
var player_max_hp = "n/a";
if (is_struct(gs.player_ch)) {
    if (variable_struct_exists(gs.player_ch, "hp")) player_hp = string(gs.player_ch.hp);
    if (variable_struct_exists(gs.player_ch, "max_hp")) player_max_hp = string(gs.player_ch.max_hp);
}

var last_debug_cmd = "";
if (variable_global_exists("debug") && is_struct(global.debug)) {
    if (variable_struct_exists(global.debug, "last_command")) last_debug_cmd = string(global.debug.last_command);
}

var lines = [];
array_push(lines, "DEBUG OVERLAY");
array_push(lines, "commands:");
array_push(lines, "- Toggle Debug: " + Input_Label("debug_toggle"));
array_push(lines, "- Kill Player (death test): " + Input_Label("debug_kill"));
array_push(lines, "- Level Up: " + Input_Label("debug_levelup"));
array_push(lines, "- Get All Items: " + Input_Label("debug_all_items"));
array_push(lines, "");
array_push(lines, "active:");
array_push(lines, "- debug_enabled: " + string(debug_enabled));
array_push(lines, "- audio_debug_enabled: " + string(audio_debug_enabled));
array_push(lines, "- room: " + room_get_name(room));
array_push(lines, "- ui_mode: " + string(ui_mode_id) + " (" + ui_mode_name + ")");
array_push(lines, "- transition_active: " + string(Transition_IsActive()));
array_push(lines, "- player_hp: " + player_hp + " / " + player_max_hp);
array_push(lines, "- class: " + class_name + " (" + string(class_id) + ")");
array_push(lines, "- difficulty: " + difficulty_name + " (" + string(diff_id) + ")");
if (last_debug_cmd != "") {
    array_push(lines, "- last_debug_command: " + last_debug_cmd);
}

if (variable_struct_exists(gs, "ui") && variable_struct_exists(gs.ui, "debug_warns")) {
    var dw = gs.ui.debug_warns;
    if (is_array(dw) && array_length(dw) > 0) {
        array_push(lines, "- last_warning: " + string(dw[array_length(dw) - 1]));
    }
}

if (audio_debug_enabled) {
    var manager_ok = instance_exists(obj_sfx_manager);
    var sfx_db_ok = variable_global_exists("sfx_db") && ds_exists(global.sfx_db, ds_type_map);
    var bgm_db_ok = variable_global_exists("bgm_db") && ds_exists(global.bgm_db, ds_type_map);

    var vol_master = variable_global_exists("vol_master") ? string(global.vol_master) : "n/a";
    var vol_ui = variable_global_exists("vol_ui") ? string(global.vol_ui) : "n/a";
    var vol_sfx = variable_global_exists("vol_sfx") ? string(global.vol_sfx) : "n/a";
    var vol_music = variable_global_exists("vol_music") ? string(global.vol_music) : "n/a";

    var test_key = variable_global_exists("audio_debug_last_key") ? string(global.audio_debug_last_key) : "";
    var resolve = SFX_DebugResolve(test_key);
    var ui_confirm_info = SFX_DebugResolve("ui_confirm");
    var resolved_name = resolve.ok ? resolve.asset_name : "(none)";
    var ui_confirm_name = ui_confirm_info.ok ? ui_confirm_info.asset_name : "(none)";

    var last_channel = variable_global_exists("audio_debug_last_channel") ? global.audio_debug_last_channel : -1;
    var last_channel_playing = (last_channel != -1) && audio_is_playing(last_channel);
    var last_sfx_handle = variable_global_exists("sfx_last_handle") ? global.sfx_last_handle : -1;
    var last_sfx_playing = (last_sfx_handle != -1) && audio_is_playing(last_sfx_handle);

    var bgm_key = variable_global_exists("bgm_current_key") ? string(global.bgm_current_key) : "(unset)";
    var bgm_handle = variable_global_exists("bgm_current_handle") ? global.bgm_current_handle : -1;
    var bgm_playing = (bgm_handle != -1) && audio_is_playing(bgm_handle);

    var last_status = variable_global_exists("audio_debug_last_status") ? string(global.audio_debug_last_status) : "";
    var missing_count = variable_global_exists("audio_debug_missing_count") ? global.audio_debug_missing_count : -1;
    var total_count = variable_global_exists("audio_debug_total_count") ? global.audio_debug_total_count : -1;
    var group_loaded = variable_global_exists("audio_debug_group_loaded") ? global.audio_debug_group_loaded : audio_group_is_loaded(audiogroup_default);
    var direct_handle = variable_global_exists("audio_debug_direct_handle") ? global.audio_debug_direct_handle : -1;
    var direct_playing = variable_global_exists("audio_debug_direct_playing") ? global.audio_debug_direct_playing : ((direct_handle != -1) && audio_is_playing(direct_handle));

    array_push(lines, "");
    array_push(lines, "audio diagnostics:");
    array_push(lines, "- manager exists: " + string(manager_ok));
    array_push(lines, "- sfx_db exists: " + string(sfx_db_ok));
    array_push(lines, "- bgm_db exists: " + string(bgm_db_ok));
    array_push(lines, "- audiogroup_default loaded: " + string(group_loaded));
    array_push(lines, "- vol master/ui/sfx/music: " + vol_master + " / " + vol_ui + " / " + vol_sfx + " / " + vol_music);
    array_push(lines, "- ui_confirm resolve: ok=" + string(ui_confirm_info.ok) + " id=" + string(ui_confirm_info.asset) + " name=" + ui_confirm_name + " reason=" + string(ui_confirm_info.reason));
    array_push(lines, "- missing required keys: " + string(missing_count) + " / " + string(total_count));
    array_push(lines, "- last_test_key: " + test_key);
    array_push(lines, "- resolved asset: ok=" + string(resolve.ok) + " index=" + string(resolve.asset) + " name=" + resolved_name + " reason=" + string(resolve.reason));
    array_push(lines, "- last_channel: " + string(last_channel) + " playing=" + string(last_channel_playing));
    array_push(lines, "- last_sfx_handle: " + string(last_sfx_handle) + " playing=" + string(last_sfx_playing));
    array_push(lines, "- direct_test_handle: " + string(direct_handle) + " playing=" + string(direct_playing));
    array_push(lines, "- current_bgm: key=" + bgm_key + " handle=" + string(bgm_handle) + " playing=" + string(bgm_playing));
    array_push(lines, "- status: " + last_status);
}

var text_blob = "";
for (var li = 0; li < array_length(lines); li++) {
    if (li > 0) text_blob += "\n";
    text_blob += lines[li];
}

var text_w = ui_w - 8;
var text_h = string_height_ext(text_blob, line_h, text_w);
var ui_h = min(gui_h - 16, max(220, text_h + 12));
draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(ui_x - 4, ui_y - 4, ui_x + ui_w, ui_y + ui_h, false);
draw_set_alpha(1);
draw_set_color(c_white);

draw_text_ext(ui_x, ui_y, text_blob, line_h, text_w);
