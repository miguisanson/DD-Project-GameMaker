if (!variable_global_exists("audio_debug_enabled") || !global.audio_debug_enabled) exit;

var ui_x = 8;
var ui_y = 8;
var line_h = 14;
var ui_w = 780;
var ui_h = 300;

draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(ui_x - 4, ui_y - 4, ui_x + ui_w, ui_y + ui_h, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_font(UI_FONT);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

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

var lines = [
    "DEBUG (P to toggle)",
    "manager exists: " + string(manager_ok),
    "sfx_db exists: " + string(sfx_db_ok),
    "bgm_db exists: " + string(bgm_db_ok),
    "audiogroup_default loaded: " + string(group_loaded),
    "vol master/ui/sfx/music: " + vol_master + " / " + vol_ui + " / " + vol_sfx + " / " + vol_music,
    "ui_confirm resolve: ok=" + string(ui_confirm_info.ok) + " id=" + string(ui_confirm_info.asset) + " name=" + ui_confirm_name + " reason=" + string(ui_confirm_info.reason),
    "missing required keys: " + string(missing_count) + " / " + string(total_count),
    "last_test_key: " + test_key,
    "resolved asset: ok=" + string(resolve.ok) + " index=" + string(resolve.asset) + " name=" + resolved_name + " reason=" + string(resolve.reason),
    "last_channel: " + string(last_channel) + " playing=" + string(last_channel_playing),
    "last_sfx_handle: " + string(last_sfx_handle) + " playing=" + string(last_sfx_playing),
    "direct_test_handle: " + string(direct_handle) + " playing=" + string(direct_playing),
    "current_bgm: key=" + bgm_key + " handle=" + string(bgm_handle) + " playing=" + string(bgm_playing),
    "status: " + last_status
];

var ds = GameSettings_Ensure();
var desired_scale = variable_struct_exists(ds, "display_scale") ? ds.display_scale : -1;
var desired_full = variable_struct_exists(ds, "fullscreen") ? ds.fullscreen : false;
var actual_win_w = window_get_width();
var actual_win_h = window_get_height();
var actual_full = window_get_fullscreen();
var cam = view_camera[0];
var cam_w = -1;
var cam_h = -1;
if (!is_undefined(cam) && cam != -1) {
    cam_w = camera_get_view_width(cam);
    cam_h = camera_get_view_height(cam);
}
array_push(lines, "display desired: scale=" + string(desired_scale) + " fullscreen=" + string(desired_full));
array_push(lines, "display actual: window=" + string(actual_win_w) + "x" + string(actual_win_h) + " fullscreen=" + string(actual_full));
array_push(lines, "view0: cam=" + string(cam_w) + "x" + string(cam_h) + " wport=" + string(view_wport[0]) + " hport=" + string(view_hport[0]));
array_push(lines, "camera0 view: " + string(cam_w) + "x" + string(cam_h));

for (var i = 0; i < array_length(lines); i++) {
    draw_text(ui_x, ui_y + i * line_h, lines[i]);
}
