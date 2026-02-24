function SFX_Register(_key, _asset) {
    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) return;

    // Accept both legacy numeric asset ids and new runtime asset references.
    var snd = _asset;
    if (is_undefined(snd)) snd = noone;
    if (is_string(snd)) {
        var idx = asset_get_index(_asset);
        if (idx >= 0) snd = idx;
        else snd = noone;
    }
    if (is_real(snd) && snd < 0) {
        snd = noone;
    }

    if (ds_map_exists(global.sfx_db, _key)) {
        ds_map_replace(global.sfx_db, _key, snd);
    } else {
        ds_map_add(global.sfx_db, _key, snd);
    }
}

function SFX_EnsureManager() {
    if (instance_exists(obj_sfx_manager)) return;
    if (!object_exists(obj_sfx_manager)) return;
    if (layer_exists("Instances")) {
        instance_create_layer(0, 0, "Instances", obj_sfx_manager);
    } else {
        instance_create_depth(0, 0, 0, obj_sfx_manager);
    }
}

function SFX_RegisterDefaults() {
    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) return;

    ds_map_clear(global.sfx_db);

    // UI
    SFX_Register("ui_move", Modern2);
    SFX_Register("ui_confirm", Modern5);
    SFX_Register("ui_back", Modern6);
    SFX_Register("ui_openclose", Modern14);

    // Dialogue
    SFX_Register("dialogue_open", Modern8);
    SFX_Register("dialogue_advance", Abstract1);
    SFX_Register("dialogue_close", Modern9);

    // World / Interaction
    SFX_Register("pickup", Retro8);
    SFX_Register("push_rock", African1);
    SFX_Register("dog_pet", Retro10);
    SFX_Register("switch_on", Wood_Block1);
    SFX_Register("umbrella_give", African4);
    SFX_Register("kdrama_complete", Retro7);

    // Pickleball
    SFX_Register("hit_good", Retro3);
    SFX_Register("hit_perfect", Retro5);
    SFX_Register("miss", Retro4);
    SFX_Register("win", Retro7);

    // Save / Load
    SFX_Register("save_confirm", Modern5);
    SFX_Register("load_confirm", Modern5);
    SFX_Register("delete_confirm", Modern5);

    // Intentionally silent hooks
    SFX_Register("interact", noone);
    SFX_Register("interact_fail", noone);
    SFX_Register("step", noone);
    SFX_Register("move_blocked", noone);
    SFX_Register("rock_blocked", noone);
    SFX_Register("crater_break", noone);
    SFX_Register("dog_move", noone);
    SFX_Register("image_open", noone);
    SFX_Register("image_advance", noone);
    SFX_Register("image_close", noone);
}

function SFX_ClampVolumes() {
    if (!variable_global_exists("vol_master")) global.vol_master = VOL_MASTER_DEFAULT;
    if (!variable_global_exists("vol_sfx")) global.vol_sfx = VOL_SFX_DEFAULT;
    if (!variable_global_exists("vol_music")) global.vol_music = VOL_MUSIC_DEFAULT;

    global.vol_master = clamp(global.vol_master, 0, 1);
    global.vol_sfx = clamp(global.vol_sfx, 0, 1);
    global.vol_music = clamp(global.vol_music, 0, 1);
}

function SFX_Play(_key, _vol = 1, _pitch = 1) {
    SFX_EnsureManager();
    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) {
        global.sfx_last_key = _key;
        global.sfx_last_handle = -1;
        return -1;
    }
    if (!ds_map_exists(global.sfx_db, _key)) {
        global.sfx_last_key = _key;
        global.sfx_last_handle = -1;
        return -1;
    }
    SFX_ClampVolumes();

    var snd = global.sfx_db[? _key];
    if (is_undefined(snd) || snd == noone) {
        global.sfx_last_key = _key;
        global.sfx_last_handle = -1;
        return -1;
    }
    if (is_real(snd) && snd < 0) {
        global.sfx_last_key = _key;
        global.sfx_last_handle = -1;
        return -1;
    }

    var snd_handle = audio_play_sound(snd, 0, false);
    if (snd_handle == -1) {
        global.sfx_last_key = _key;
        global.sfx_last_handle = -1;
        return -1;
    }

    var gain = clamp(_vol, 0, 1) * global.vol_master * global.vol_sfx;
    audio_sound_gain(snd_handle, gain, 0);
    audio_sound_pitch(snd_handle, max(0.01, _pitch));
    global.sfx_last_key = _key;
    global.sfx_last_handle = snd_handle;
    return snd_handle;
}

function SFX_PlayUI(_key, _vol = 1, _pitch = 1) {
    return SFX_Play(_key, _vol, _pitch);
}

function BGM_ResolveTrack(_candidates) {
    if (!is_array(_candidates)) return noone;
    for (var i = 0; i < array_length(_candidates); i++) {
        var name = _candidates[i];
        if (!is_string(name) || name == "") continue;
        var snd = asset_get_index(name);
        if (snd != -1) return snd;
    }
    return noone;
}

function BGM_ApplyGain(_fade_ms = 0) {
    SFX_ClampVolumes();
    if (!variable_global_exists("bgm_current_handle")) return;
    var h = global.bgm_current_handle;
    if (h == -1) return;
    if (!audio_is_playing(h)) return;

    var gain = global.vol_master * global.vol_music;
    audio_sound_gain(h, gain, max(0, _fade_ms));
}

function BGM_Play(_track_sound, _force_restart = false) {
    SFX_ClampVolumes();
    var snd = _track_sound;
    if (is_undefined(snd)) return -1;
    if (is_string(snd)) {
        snd = asset_get_index(snd);
    }
    if (snd == noone || snd == -1) return -1;
    if (is_real(snd) && snd < 0) return -1;

    if (!variable_global_exists("bgm_current_sound")) global.bgm_current_sound = noone;
    if (!variable_global_exists("bgm_current_handle")) global.bgm_current_handle = -1;
    if (!variable_global_exists("bgm_pending_stop_handle")) global.bgm_pending_stop_handle = -1;
    if (!variable_global_exists("bgm_pending_stop_frames")) global.bgm_pending_stop_frames = 0;

    var same_track = (global.bgm_current_sound == snd);
    var cur_h = global.bgm_current_handle;
    var playing = (cur_h != -1) && audio_is_playing(cur_h);
    if (same_track && playing && !_force_restart) {
        BGM_ApplyGain(100);
        return cur_h;
    }

    if (playing) {
        audio_sound_gain(cur_h, 0, 250);
        global.bgm_pending_stop_handle = cur_h;
        var game_fps = max(1, game_get_speed(gamespeed_fps));
        global.bgm_pending_stop_frames = max(1, ceil((250 / 1000) * game_fps));
    }

    var h = audio_play_sound(snd, 10, true);
    if (h != -1) {
        global.bgm_current_sound = snd;
        global.bgm_current_handle = h;
        // Set an immediately audible gain first; avoids silent start if fade state is interrupted.
        audio_sound_gain(h, global.vol_master * global.vol_music, 0);
    } else {
        global.bgm_current_sound = noone;
        global.bgm_current_handle = -1;
    }
    return h;
}

function BGM_Stop(_fade_ms = 250) {
    if (!variable_global_exists("bgm_current_handle")) return;
    var h = global.bgm_current_handle;
    if (h == -1) return;

    if (audio_is_playing(h)) {
        var fade = max(0, _fade_ms);
        audio_sound_gain(h, 0, fade);
        if (fade <= 0) {
            audio_stop_sound(h);
        } else {
            global.bgm_pending_stop_handle = h;
            var game_fps = max(1, game_get_speed(gamespeed_fps));
            global.bgm_pending_stop_frames = max(1, ceil((fade / 1000) * game_fps));
        }
    }

    global.bgm_current_handle = -1;
    global.bgm_current_sound = noone;
}

function BGM_SetVolume(_v) {
    global.vol_music = clamp(_v, 0, 1);
    BGM_ApplyGain(100);
}

function SFX_SetVolume(_v) {
    global.vol_sfx = clamp(_v, 0, 1);
}

function Master_SetVolume(_v) {
    global.vol_master = clamp(_v, 0, 1);
    BGM_ApplyGain(100);
}

function BGM_GetTrackForRoom(_room_id) {
    var room_name = string_lower(room_get_name(_room_id));
    switch (room_name) {
        case "rm_start":   return _01_Main_Theme___Towballs_Crossing;
        case "room1":      return _03_7am___Towballs_Crossing;
        case "room2":      return _07_11am___Towball_s_Crossing;
        case "room3":      return _11_3pm___Towballs_Crossing;
        case "room4":      return _15_6pm___Towball_s_Crossing_1;
        case "room5":      return _24_3am___Towball_s_Crossing;
        case "rm_thankyou": return noone;
    }
    return -1;
}

function BGM_GetTrackNameForRoom(_room_id) {
    var room_name = string_lower(room_get_name(_room_id));
    switch (room_name) {
        case "rm_start":   return "_01_Main_Theme___Towballs_Crossing";
        case "room1":      return "_03_7am___Towballs_Crossing";
        case "room2":      return "_07_11am___Towball_s_Crossing";
        case "room3":      return "_11_3pm___Towballs_Crossing";
        case "room4":      return "_15_6pm___Towball_s_Crossing_1";
        case "room5":      return "_24_3am___Towball_s_Crossing";
        case "rm_thankyou": return "(none)";
    }
    return "(unmapped)";
}

function BGM_ApplyForRoom(_room_id) {
    SFX_EnsureManager();
    var track = BGM_GetTrackForRoom(_room_id);
    if (track == noone) {
        BGM_Stop(250);
        return;
    }
    if (track != -1) {
        BGM_Play(track, false);
    }
}
