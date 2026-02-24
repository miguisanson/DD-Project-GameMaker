if (!variable_global_exists("audio_debug_enabled")) global.audio_debug_enabled = false;
if (!variable_global_exists("audio_debug_test_key")) global.audio_debug_test_key = "ui_confirm";
if (!variable_global_exists("audio_debug_last_key")) global.audio_debug_last_key = global.audio_debug_test_key;
if (!variable_global_exists("audio_debug_last_channel")) global.audio_debug_last_channel = -1;
if (!variable_global_exists("audio_debug_last_status")) global.audio_debug_last_status = "Audio debug OFF";
if (!variable_global_exists("audio_debug_last_ok")) global.audio_debug_last_ok = false;
if (!variable_global_exists("audio_debug_last_asset")) global.audio_debug_last_asset = noone;
if (!variable_global_exists("audio_debug_last_asset_name")) global.audio_debug_last_asset_name = "";
if (!variable_global_exists("audio_debug_last_reason")) global.audio_debug_last_reason = "";
if (!variable_global_exists("audio_debug_direct_handle")) global.audio_debug_direct_handle = -1;
if (!variable_global_exists("audio_debug_direct_playing")) global.audio_debug_direct_playing = false;
if (!variable_global_exists("audio_debug_group_loaded")) global.audio_debug_group_loaded = false;
if (!variable_global_exists("audio_group_load_requested")) global.audio_group_load_requested = false;
if (!variable_global_exists("audio_debug_missing_count")) global.audio_debug_missing_count = 0;
if (!variable_global_exists("audio_debug_total_count")) global.audio_debug_total_count = 0;

var group_loaded = audio_group_is_loaded(audiogroup_default);
global.audio_debug_group_loaded = group_loaded;
if (!group_loaded && !global.audio_group_load_requested) {
    audio_group_load(audiogroup_default);
    global.audio_group_load_requested = true;
}
if (group_loaded) global.audio_group_load_requested = false;

if (keyboard_check_pressed(ord("P"))) {
    global.audio_debug_enabled = !global.audio_debug_enabled;
    if (global.audio_debug_enabled) {
        global.audio_debug_last_key = global.audio_debug_test_key;
        var _audit = SFX_DebugAuditRequired(true);
        global.audio_debug_missing_count = _audit.missing;
        global.audio_debug_total_count = _audit.total;
        var test = SFX_DebugPlayTest(global.audio_debug_last_key);
        global.audio_debug_last_channel = test.channel;
        global.audio_debug_last_status = "Played: " + string(global.audio_debug_last_key) + " -> " + string(test.status);
        if (is_struct(test.resolve)) {
            global.audio_debug_last_ok = test.resolve.ok;
            global.audio_debug_last_asset = test.resolve.asset;
            global.audio_debug_last_asset_name = test.resolve.asset_name;
            global.audio_debug_last_reason = test.resolve.reason;
        }

        // Direct engine smoke test to isolate mapping vs runtime audio path.
        global.audio_debug_direct_handle = audio_play_sound(Modern5, 0, false);
        global.audio_debug_direct_playing = (global.audio_debug_direct_handle != -1) && audio_is_playing(global.audio_debug_direct_handle);
        if (global.audio_debug_direct_handle == -1) {
            global.audio_debug_last_status += " | direct=FAILED";
        } else if (!global.audio_debug_direct_playing) {
            global.audio_debug_last_status += " | direct=CHANNEL NOT PLAYING";
        } else {
            global.audio_debug_last_status += " | direct=PLAYING";
        }
    } else {
        global.audio_debug_last_status = "Audio debug OFF";
    }
}

if (global.audio_debug_enabled) {
    var info = SFX_DebugResolve(global.audio_debug_last_key);
    global.audio_debug_last_ok = info.ok;
    global.audio_debug_last_asset = info.asset;
    global.audio_debug_last_asset_name = info.asset_name;
    global.audio_debug_last_reason = info.reason;
    global.audio_debug_direct_playing = (global.audio_debug_direct_handle != -1) && audio_is_playing(global.audio_debug_direct_handle);
}

if (!variable_instance_exists(id, "last_room_id")) {
    last_room_id = room;
}

if (room != last_room_id) {
    last_room_id = room;
    BGM_ApplyForRoom(room);
    GameSettings_ApplyDisplay();
}

// Guard against any room/view/window overrides: keep display state aligned to settings.
var ds = GameSettings_Ensure();
var needs_display_apply = false;
if (window_get_fullscreen() != ds.fullscreen) {
    needs_display_apply = true;
} else if (!ds.fullscreen) {
    var exp_w = DISPLAY_BASE_W * ds.display_scale;
    var exp_h = DISPLAY_BASE_H * ds.display_scale;
    if (window_get_width() != exp_w || window_get_height() != exp_h) {
        needs_display_apply = true;
    }
}
if (view_wview[0] != DISPLAY_BASE_W || view_hview[0] != DISPLAY_BASE_H) {
    needs_display_apply = true;
}
if (needs_display_apply) {
    GameSettings_ApplyDisplay();
}

var expected_key = BGM_GetTrackForRoom(room);
if (group_loaded) {
    if (!is_string(expected_key) || expected_key == "") {
        if (global.bgm_current_handle != -1 && audio_is_playing(global.bgm_current_handle)) {
            BGM_Stop(250);
        }
    } else {
        var should_restart = false;
        if (!variable_global_exists("bgm_current_key")) should_restart = true;
        else if (global.bgm_current_key != expected_key) should_restart = true;
        if (!variable_global_exists("bgm_current_handle")) should_restart = true;
        else if (global.bgm_current_handle == -1 || !audio_is_playing(global.bgm_current_handle)) should_restart = true;

        if (should_restart) {
            BGM_Play(expected_key, true, true);
        } else {
            BGM_ApplyGain(0);
        }
    }
}

if (global.bgm_pending_stop_frames > 0) {
    global.bgm_pending_stop_frames -= 1;
    if (global.bgm_pending_stop_frames <= 0) {
        var h = global.bgm_pending_stop_handle;
        if (h != -1 && audio_is_playing(h)) {
            audio_stop_sound(h);
        }
        global.bgm_pending_stop_handle = -1;
        global.bgm_pending_stop_frames = 0;
    }
}
