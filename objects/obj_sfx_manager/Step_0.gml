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

if (!variable_global_exists("mouse_cursor_hidden")) global.mouse_cursor_hidden = false;
var hide_cursor = window_has_focus();
if (hide_cursor != global.mouse_cursor_hidden) {
    if (hide_cursor) window_set_cursor(cr_none);
    else window_set_cursor(cr_default);
    global.mouse_cursor_hidden = hide_cursor;
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

// One-time skillbook ambience: loop only while the special dialogue is active.
if (!variable_global_exists("skillbook_mana_ambience_handle")) global.skillbook_mana_ambience_handle = -1;
if (!variable_global_exists("skillbook_mana_ambience_gain")) global.skillbook_mana_ambience_gain = 0;
if (!variable_global_exists("skillbook_mana_ambience_playing")) global.skillbook_mana_ambience_playing = false;

var skillbook_should_play = false;
var gs_audio = GameState_Get();
if (is_struct(gs_audio) && variable_struct_exists(gs_audio, "ui") && is_struct(gs_audio.ui)) {
    var ui_audio = gs_audio.ui;
    var mana_dialogue_active = Dialogue_IsSkillbookFirstReadUIActive();
    if (mana_dialogue_active) {
        var has_lines = variable_struct_exists(ui_audio, "lines") && is_array(ui_audio.lines) && array_length(ui_audio.lines) > 0;
        skillbook_should_play = has_lines || (variable_struct_exists(ui_audio, "mode") && ui_audio.mode == UI_DIALOGUE);
        var pending_key = Dialogue_SkillbookFirstReadPendingFlagKey();
        if (!skillbook_should_play && variable_struct_exists(gs_audio, "flags") && is_struct(gs_audio.flags) && variable_struct_exists(gs_audio.flags, pending_key) && variable_struct_get(gs_audio.flags, pending_key)) {
            Dialogue_SkillbookFirstReadMarkDone();
        }
    }
}

var ambience_key = Dialogue_SkillbookAmbienceSfxKey();
var skillbook_asset = noone;
if (variable_global_exists("sfx_db") && ds_exists(global.sfx_db, ds_type_map) && ds_map_exists(global.sfx_db, ambience_key)) {
    skillbook_asset = global.sfx_db[? ambience_key];
}
if (!SFX_IsValidSoundAsset(skillbook_asset)) skillbook_asset = noone;

if (skillbook_should_play && global.skillbook_mana_ambience_handle == -1 && skillbook_asset != noone) {
    global.skillbook_mana_ambience_handle = audio_play_sound(skillbook_asset, 0, true);
    global.skillbook_mana_ambience_gain = 0;
    if (global.skillbook_mana_ambience_handle != -1) {
        audio_sound_gain(global.skillbook_mana_ambience_handle, 0, 0);
    }
}

if (global.skillbook_mana_ambience_handle != -1 && !audio_is_playing(global.skillbook_mana_ambience_handle)) {
    global.skillbook_mana_ambience_handle = -1;
    global.skillbook_mana_ambience_gain = 0;
}

SFX_ClampVolumes();
var skillbook_trim = SFX_GetGain(ambience_key);
var skillbook_target = clamp(SKILLBOOK_MANA_AMBIENCE_BASE_GAIN, 0, 1) * skillbook_trim * global.vol_master * global.vol_sfx;

if (skillbook_should_play) {
    if (global.skillbook_mana_ambience_gain < skillbook_target) {
        var fade_step_in = max(0.0001, skillbook_target / max(1, SKILLBOOK_MANA_AMBIENCE_FADE_IN_FRAMES));
        global.skillbook_mana_ambience_gain = min(skillbook_target, global.skillbook_mana_ambience_gain + fade_step_in);
    } else {
        // Follow SFX volume changes immediately while active.
        global.skillbook_mana_ambience_gain = skillbook_target;
    }
    global.skillbook_mana_ambience_playing = true;
} else {
    if (global.skillbook_mana_ambience_gain > 0) {
        var fade_step_out = max(0.0001, max(global.skillbook_mana_ambience_gain, skillbook_target) / max(1, SKILLBOOK_MANA_AMBIENCE_FADE_OUT_FRAMES));
        global.skillbook_mana_ambience_gain = max(0, global.skillbook_mana_ambience_gain - fade_step_out);
    }
    if (global.skillbook_mana_ambience_gain <= 0.0001) {
        global.skillbook_mana_ambience_gain = 0;
        global.skillbook_mana_ambience_playing = false;
        if (global.skillbook_mana_ambience_handle != -1 && audio_is_playing(global.skillbook_mana_ambience_handle)) {
            audio_stop_sound(global.skillbook_mana_ambience_handle);
        }
        global.skillbook_mana_ambience_handle = -1;
    }
}

if (global.skillbook_mana_ambience_handle != -1 && audio_is_playing(global.skillbook_mana_ambience_handle)) {
    audio_sound_gain(global.skillbook_mana_ambience_handle, global.skillbook_mana_ambience_gain, 0);
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
