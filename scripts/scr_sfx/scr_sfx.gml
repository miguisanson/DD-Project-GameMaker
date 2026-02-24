function SFX_Register(_key, _asset) {
    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) return;

    var snd = _asset;
    if (is_undefined(snd)) snd = noone;
    if (is_string(snd)) snd = asset_get_index(snd);
    if (!SFX_IsValidSoundAsset(snd)) snd = noone;

    if (ds_map_exists(global.sfx_db, _key)) ds_map_replace(global.sfx_db, _key, snd);
    else ds_map_add(global.sfx_db, _key, snd);
}

function BGM_Register(_key, _asset) {
    if (!variable_global_exists("bgm_db") || !ds_exists(global.bgm_db, ds_type_map)) return;

    var snd = _asset;
    if (is_undefined(snd)) snd = noone;
    if (is_string(snd)) snd = asset_get_index(snd);
    if (!SFX_IsValidSoundAsset(snd)) snd = noone;

    if (ds_map_exists(global.bgm_db, _key)) ds_map_replace(global.bgm_db, _key, snd);
    else ds_map_add(global.bgm_db, _key, snd);
}

function SFX_ResolveAsset(_candidates) {
    if (is_undefined(_candidates)) return noone;
    if (!is_string(_candidates) && SFX_IsValidSoundAsset(_candidates)) return _candidates;

    if (is_string(_candidates)) {
        var idx = asset_get_index(_candidates);
        return SFX_IsValidSoundAsset(idx) ? idx : noone;
    }

    if (is_array(_candidates)) {
        for (var i = 0; i < array_length(_candidates); i++) {
            var candidate = _candidates[i];
            if (is_string(candidate)) {
                var idx2 = asset_get_index(candidate);
                if (SFX_IsValidSoundAsset(idx2)) return idx2;
            } else if (SFX_IsValidSoundAsset(candidate)) {
                return candidate;
            }
        }
    }

    return noone;
}

function SFX_RegisterResolved(_key, _candidates) {
    SFX_Register(_key, SFX_ResolveAsset(_candidates));
}

function BGM_RegisterResolved(_key, _candidates) {
    BGM_Register(_key, SFX_ResolveAsset(_candidates));
}

function SFX_EnsureManager() {
    if (instance_exists(obj_sfx_manager)) return;
    if (!object_exists(obj_sfx_manager)) return;
    if (layer_exists("Instances")) instance_create_layer(0, 0, "Instances", obj_sfx_manager);
    else instance_create_depth(0, 0, 0, obj_sfx_manager);
}

function SFX_IsValidSoundAsset(_asset) {
    if (is_undefined(_asset)) return false;
    if (is_string(_asset)) {
        var idx = asset_get_index(_asset);
        return (idx != -1) && (idx != noone);
    }
    if (is_array(_asset) || is_struct(_asset)) return false;
    if (_asset == noone || _asset == -1) return false;
    if (is_real(_asset)) return _asset >= 0;
    // Resource references in newer runtimes can be non-real values.
    return true;
}

function SFX_CategoryForKey(_key) {
    var key = string_lower(string(_key));

    if (string_copy(key, 1, 3) == "ui_") return "ui";
    if (string_copy(key, 1, 9) == "dialogue_") return "ui";
    if (key == "save_confirm" || key == "load_confirm" || key == "delete_confirm") return "ui";
    if (key == "barrel_break" || key == "chest_open" || key == "kill_torch") return "ui";

    return "sfx";
}

function SFX_CleanupActive() {
    if (!variable_global_exists("sfx_active") || !is_array(global.sfx_active)) {
        global.sfx_active = [];
        return;
    }

    var active = global.sfx_active;
    for (var i = array_length(active) - 1; i >= 0; i--) {
        var rec = active[i];
        var keep = is_struct(rec) && variable_struct_exists(rec, "handle") && rec.handle != -1 && audio_is_playing(rec.handle);
        if (!keep) array_delete(active, i, 1);
    }
    global.sfx_active = active;
}

function SFX_ApplyActiveGains(_fade_ms = 0) {
    SFX_ClampVolumes();
    SFX_CleanupActive();
    if (!variable_global_exists("sfx_active") || !is_array(global.sfx_active)) return;

    var active = global.sfx_active;
    for (var i = 0; i < array_length(active); i++) {
        var rec = active[i];
        if (!is_struct(rec)) continue;
        if (!variable_struct_exists(rec, "handle")) continue;
        var h = rec.handle;
        if (h == -1 || !audio_is_playing(h)) continue;
        var key = variable_struct_exists(rec, "key") ? rec.key : "";
        var base = variable_struct_exists(rec, "base") ? rec.base : 1;
        var cat = SFX_CategoryForKey(key);
        var cat_gain = (cat == "ui") ? global.vol_ui : global.vol_sfx;
        var gain = clamp(base, 0, 1) * global.vol_master * cat_gain;
        audio_sound_gain(h, gain, max(0, _fade_ms));
    }
}

function SFX_RegisterDefaults() {
    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) return;
    ds_map_clear(global.sfx_db);

    // UI_Soundpack
    SFX_RegisterResolved("ui_move", [Modern2, "Modern2", "ui_move"]);
    SFX_RegisterResolved("ui_confirm", [Modern5, "Modern5", "ui_confirm"]);
    SFX_RegisterResolved("ui_back", [Modern6, "Modern6", "ui_back"]);
    SFX_RegisterResolved("ui_openclose", [Modern14, "Modern14", "ui_openclose"]);

    // Dialogue (muted by design)
    SFX_Register("dialogue_open", noone);
    SFX_Register("dialogue_advance", noone);
    SFX_Register("dialogue_close", noone);

    // Save/Load
    SFX_RegisterResolved("save_confirm", [Modern5, "Modern5", "save_confirm"]);
    SFX_RegisterResolved("load_confirm", [Modern5, "Modern5", "load_confirm"]);
    SFX_RegisterResolved("delete_confirm", [Modern5, "Modern5", "delete_confirm"]);

    // World/Interact
    SFX_RegisterResolved("barrel_break", ["barrel_break"]);
    SFX_RegisterResolved("chest_open", ["chest_open"]);
    SFX_RegisterResolved("kill_torch", ["kill_torch"]);

    // Battle Basic
    SFX_RegisterResolved("bow_attack", ["Bow_Attack_", "bow_attack"]);
    SFX_RegisterResolved("mage_attack", ["mage_attack"]);
    SFX_RegisterResolved("sword_attack", ["sword_attack"]);

    // Miss/Blocked
    SFX_RegisterResolved("miss_effect", ["miss_effect"]);
    SFX_RegisterResolved("blocked", ["Blocked", "blocked"]);

    // Skill Effects
    SFX_Register("skill_generic", noone);
    SFX_RegisterResolved("skill_bleed", ["bleed"]);
    SFX_RegisterResolved("skill_double_shot", ["double_shot"]);
    SFX_RegisterResolved("skill_evasion_up", ["evasion_up"]);
    SFX_RegisterResolved("skill_fireball", ["fireball"]);
    SFX_RegisterResolved("skill_foresight", ["foresight"]);
    SFX_RegisterResolved("skill_horizontal_slash", ["horizontal_slash", "horinzotal_slash"]);
    SFX_RegisterResolved("skill_ice_spear", ["ice_spear"]);
    SFX_RegisterResolved("skill_meditation", ["meditation35", "meditation"]);
    SFX_RegisterResolved("skill_muscle_up", ["muscle_up"]);
    SFX_RegisterResolved("skill_poison_arrow", ["waterspray"]);
    SFX_RegisterResolved("skill_poison_mist", ["GooeySlime___Sound_Effect"]);
    SFX_RegisterResolved("skill_rev_up", ["rev_up"]);
    SFX_RegisterResolved("skill_stun", ["stun"]);
    SFX_RegisterResolved("skill_take_aim", ["take_aim"]);

    // Monsters - Spawn
    SFX_RegisterResolved("enemy_spawn_slime", ["slime_spawn", "Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing"]);
    SFX_RegisterResolved("enemy_spawn_spider", ["spider_spawn", "spider_both_attack_and_spawn"]);
    SFX_RegisterResolved("enemy_spawn_mad_whisp", ["mad_whisp_spawn"]);
    SFX_RegisterResolved("enemy_spawn_ghost_sword", ["ghost_sword_spawn"]);
    SFX_RegisterResolved("enemy_spawn_dire_wolf", ["dire_wolf_spawn"]);
    SFX_RegisterResolved("enemy_spawn_snake", ["snake_spawn", "snake_spaawn_and_attack"]);
    SFX_RegisterResolved("enemy_spawn_killer_plant", ["killer_plant_spawn"]);
    SFX_RegisterResolved("enemy_spawn_stranger", ["stranger_spawn"]);
    SFX_RegisterResolved("enemy_spawn_mini_boss", ["mini_boss_spawn"]);
    SFX_RegisterResolved("enemy_spawn_final_boss", ["final_boss_spawn"]);

    // Monsters - Special
    SFX_RegisterResolved("enemy_special_slime", ["slime_attack", "Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing"]);
    SFX_RegisterResolved("enemy_special_spider", ["spider_attack", "spider_both_attack_and_spawn"]);
    SFX_RegisterResolved("enemy_special_mad_whisp", ["mad_whisp_attack"]);
    SFX_RegisterResolved("enemy_special_ghost_sword", ["ghost_sword_attack"]);
    SFX_RegisterResolved("enemy_special_dire_wolf", ["dire_wolf_attack"]);
    SFX_RegisterResolved("enemy_special_snake", ["snake_attack", "snake_spaawn_and_attack"]);
    SFX_RegisterResolved("enemy_special_killer_plant", ["killer_plant_attack"]);
    SFX_RegisterResolved("enemy_special_stranger", ["stranger_attack"]);
    SFX_RegisterResolved("enemy_special_mini_boss", ["mini_boss_attack"]);
    SFX_RegisterResolved("enemy_special_final_boss", ["final_boss_attack"]);

    // Legacy/Fallback (safe no-op keys)
    SFX_Register("enemy_spawn_unknown", noone);
    SFX_Register("enemy_special_unknown", noone);
    SFX_Register("pickup", noone);
    SFX_Register("push_rock", noone);
    SFX_Register("dog_pet", noone);
    SFX_Register("switch_on", noone);
    SFX_Register("umbrella_give", noone);
    SFX_Register("kdrama_complete", noone);
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

function BGM_RegisterDefaults() {
    if (!variable_global_exists("bgm_db") || !ds_exists(global.bgm_db, ds_type_map)) return;
    ds_map_clear(global.bgm_db);
    // BGM
    BGM_RegisterResolved("overall_bgm", [overall_bgm, "overall_bgm"]);
}

function SFX_ClampVolumes() {
    if (!variable_global_exists("vol_master")) global.vol_master = VOL_MASTER_DEFAULT;
    if (!variable_global_exists("vol_ui")) global.vol_ui = VOL_UI_DEFAULT;
    if (!variable_global_exists("vol_sfx")) global.vol_sfx = VOL_SFX_DEFAULT;
    if (!variable_global_exists("vol_music")) global.vol_music = VOL_MUSIC_DEFAULT;
    global.vol_master = clamp(global.vol_master, 0, 1);
    global.vol_ui = clamp(global.vol_ui, 0, 1);
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
    if (!SFX_IsValidSoundAsset(snd)) {
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

    var category = SFX_CategoryForKey(_key);
    var cat_gain = global.vol_sfx;
    if (category == "ui") cat_gain = global.vol_ui;
    var base_gain = clamp(_vol, 0, 1);
    var gain = base_gain * global.vol_master * cat_gain;
    audio_sound_gain(snd_handle, gain, 0);
    audio_sound_pitch(snd_handle, max(0.01, _pitch));

    if (!variable_global_exists("sfx_active") || !is_array(global.sfx_active)) global.sfx_active = [];
    SFX_CleanupActive();
    array_push(global.sfx_active, { handle: snd_handle, key: _key, base: base_gain });

    global.sfx_last_key = _key;
    global.sfx_last_handle = snd_handle;
    return snd_handle;
}

function SFX_Stop(_key = "") {
    if (_key == "") {
        if (variable_global_exists("sfx_last_handle") && global.sfx_last_handle != -1 && audio_is_playing(global.sfx_last_handle)) {
            audio_stop_sound(global.sfx_last_handle);
        }
        return;
    }
    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) return;
    if (!ds_map_exists(global.sfx_db, _key)) return;
    var snd = global.sfx_db[? _key];
    if (SFX_IsValidSoundAsset(snd)) audio_stop_sound(snd);
}

function SFX_PlayUI(_key, _vol = 1, _pitch = 1) {
    return SFX_Play(_key, _vol, _pitch);
}

function SFX_DebugRequiredKeys() {
    return [
        "ui_move",
        "ui_confirm",
        "ui_back",
        "ui_openclose",
        "dialogue_open",
        "dialogue_advance",
        "dialogue_close",
        "save_confirm",
        "load_confirm",
        "delete_confirm"
    ];
}

function SFX_DebugWarnOnce(_reason, _key) {
    if (!variable_global_exists("sfx_debug_warned") || !is_struct(global.sfx_debug_warned)) {
        global.sfx_debug_warned = {};
    }
    var tag = string_lower(string(_reason));
    tag = string_replace_all(tag, " ", "_");
    tag = string_replace_all(tag, "/", "_");
    tag = string_replace_all(tag, "-", "_");
    tag += "__" + string(_key);
    if (variable_struct_exists(global.sfx_debug_warned, tag)) return;
    variable_struct_set(global.sfx_debug_warned, tag, true);
    show_debug_message("[AUDIO DEBUG] " + string(_reason) + " key=" + string(_key));
}

function SFX_DebugResolve(_key) {
    var out = {
        key: string(_key),
        ok: false,
        asset: noone,
        asset_name: "",
        reason: ""
    };

    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) {
        out.reason = "SFX DB MISSING";
        return out;
    }

    if (!ds_map_exists(global.sfx_db, _key)) {
        out.reason = "MISSING KEY";
        SFX_DebugWarnOnce(out.reason, _key);
        return out;
    }

    var snd = global.sfx_db[? _key];
    if (!SFX_IsValidSoundAsset(snd)) {
        out.reason = "NO ASSET / noone";
        SFX_DebugWarnOnce(out.reason, _key);
        return out;
    }

    out.ok = true;
    out.asset = snd;
    // Avoid asset_get_name(): not available on all runtime versions.
    out.asset_name = string(snd);
    if (!is_string(out.asset_name) || out.asset_name == "") out.asset_name = "(asset)";
    out.reason = "OK";
    return out;
}

function SFX_DebugAuditRequired(_log = true) {
    var keys = SFX_DebugRequiredKeys();
    var report = [];
    var missing = 0;

    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var info = SFX_DebugResolve(key);
        var asset_name = info.asset_name;
        if (!is_string(asset_name) || asset_name == "") asset_name = "(none)";
        var line = key + " -> id=" + string(info.asset) + " name=" + asset_name + " ok=" + string(info.ok) + " reason=" + string(info.reason);
        array_push(report, line);
        if (_log) show_debug_message("[SFX MAP] " + line);
        if (!info.ok) missing += 1;
    }

    global.audio_debug_map_report = report;
    global.audio_debug_missing_count = missing;
    global.audio_debug_total_count = array_length(keys);

    return {
        missing: missing,
        total: array_length(keys),
        report: report
    };
}

function SFX_DebugPlayTest(_key) {
    var resolve = SFX_DebugResolve(_key);
    var out = {
        key: string(_key),
        channel: -1,
        status: "",
        playing: false,
        resolve: resolve
    };

    if (!resolve.ok) {
        out.status = resolve.reason;
        return out;
    }

    var h = SFX_Play(_key);
    out.channel = h;
    if (h == -1) {
        out.status = "PLAY FAILED (channel=-1)";
        return out;
    }

    out.playing = audio_is_playing(h);
    if (out.playing) out.status = "PLAYING";
    else {
        out.status = "CHANNEL NOT PLAYING";
        SFX_DebugWarnOnce(out.status, _key);
    }
    return out;
}

function BGM_GetSound(_key_or_asset) {
    if (!is_string(_key_or_asset) && SFX_IsValidSoundAsset(_key_or_asset)) return _key_or_asset;
    if (is_string(_key_or_asset)) {
        if (variable_global_exists("bgm_db") && ds_exists(global.bgm_db, ds_type_map) && ds_map_exists(global.bgm_db, _key_or_asset)) {
            var from_db = global.bgm_db[? _key_or_asset];
            return SFX_IsValidSoundAsset(from_db) ? from_db : noone;
        }
        var idx = asset_get_index(_key_or_asset);
        return SFX_IsValidSoundAsset(idx) ? idx : noone;
    }
    return noone;
}

function BGM_ApplyGain(_fade_ms = 0) {
    SFX_ClampVolumes();
    if (!variable_global_exists("bgm_current_handle")) return;
    var h = global.bgm_current_handle;
    if (h == -1 || !audio_is_playing(h)) return;
    audio_sound_gain(h, global.vol_master * global.vol_music, max(0, _fade_ms));
}

function BGM_Play(_key, _loop = true, _force_restart = false) {
    SFX_EnsureManager();
    SFX_ClampVolumes();
    var snd = BGM_GetSound(_key);
    if (!SFX_IsValidSoundAsset(snd)) return -1;

    if (!variable_global_exists("bgm_current_key")) global.bgm_current_key = "";
    if (!variable_global_exists("bgm_current_sound")) global.bgm_current_sound = noone;
    if (!variable_global_exists("bgm_current_handle")) global.bgm_current_handle = -1;
    if (!variable_global_exists("bgm_pending_stop_handle")) global.bgm_pending_stop_handle = -1;
    if (!variable_global_exists("bgm_pending_stop_frames")) global.bgm_pending_stop_frames = 0;

    var cur_h = global.bgm_current_handle;
    var playing = (cur_h != -1) && audio_is_playing(cur_h);
    var same_track = (global.bgm_current_sound == snd);
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

    var h = audio_play_sound(snd, 10, _loop);
    if (h != -1) {
        global.bgm_current_key = is_string(_key) ? _key : "";
        global.bgm_current_sound = snd;
        global.bgm_current_handle = h;
        audio_sound_gain(h, global.vol_master * global.vol_music, 0);
    } else {
        global.bgm_current_key = "";
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

    global.bgm_current_key = "";
    global.bgm_current_handle = -1;
    global.bgm_current_sound = noone;
}

function BGM_IsPlaying(_key = "") {
    if (!variable_global_exists("bgm_current_handle")) return false;
    var h = global.bgm_current_handle;
    if (h == -1 || !audio_is_playing(h)) return false;
    if (_key == "") return true;
    if (!variable_global_exists("bgm_current_key")) return false;
    return global.bgm_current_key == _key;
}

function Audio_SetMasterVolume(_v) {
    global.vol_master = clamp(_v, 0, 1);
    SFX_ApplyActiveGains(100);
    BGM_ApplyGain(100);
}

function Audio_SetUIVolume(_v) {
    global.vol_ui = clamp(_v, 0, 1);
    SFX_ApplyActiveGains(100);
}

function Audio_SetSFXVolume(_v) {
    global.vol_sfx = clamp(_v, 0, 1);
    SFX_ApplyActiveGains(100);
}

function Audio_SetMusicVolume(_v) {
    global.vol_music = clamp(_v, 0, 1);
    BGM_ApplyGain(100);
}

// Backward-compatible aliases
function Master_SetVolume(_v) { Audio_SetMasterVolume(_v); }
function UI_SetVolume(_v) { Audio_SetUIVolume(_v); }
function SFX_SetVolume(_v) { Audio_SetSFXVolume(_v); }
function BGM_SetVolume(_v) { Audio_SetMusicVolume(_v); }

function SFX_EnemyKeySuffix(_enemy_id) {
    switch (_enemy_id) {
        case ENEMY_SLIME: return "slime";
        case ENEMY_SPIDER: return "spider";
        case ENEMY_MADWHISP: return "mad_whisp";
        case ENEMY_GHOSTSWORD: return "ghost_sword";
        case ENEMY_DIREWOLF: return "dire_wolf";
        case ENEMY_SNAKE: return "snake";
        case ENEMY_KILLER_PLANT: return "killer_plant";
        case ENEMY_STRANGER: return "stranger";
        case ENEMY_MINI_BOSS: return "mini_boss";
        case ENEMY_FINAL_BOSS: return "final_boss";
    }
    return "unknown";
}

function SFX_PlayEnemySpawn(_enemy_id) {
    return SFX_Play("enemy_spawn_" + SFX_EnemyKeySuffix(_enemy_id));
}

function SFX_PlayEnemySpecial(_enemy_id) {
    return SFX_Play("enemy_special_" + SFX_EnemyKeySuffix(_enemy_id));
}

function SFX_PlayClassAttack(_class_id) {
    switch (_class_id) {
        case CLASS_ARCHER: return SFX_Play("bow_attack");
        case CLASS_MAGE: return SFX_Play("mage_attack");
        case CLASS_KNIGHT: return SFX_Play("sword_attack");
    }
    return -1;
}

function SFX_SkillKey(_skill_id) {
    switch (_skill_id) {
        case SKILL_WOUND: return "skill_bleed";
        case SKILL_HILT_BASH: return "skill_stun";
        case SKILL_MUSCLE_UP: return "skill_muscle_up";
        case SKILL_REV_UP: return "skill_rev_up";
        case SKILL_HORIZ_SLASH: return "skill_horizontal_slash";
        case SKILL_POISON_ARROW: return "skill_poison_arrow";
        case SKILL_EVASION: return "skill_evasion_up";
        case SKILL_DOUBLE_SHOT: return "skill_double_shot";
        case SKILL_TAKE_AIM: return "skill_take_aim";
        case SKILL_FIREBALL: return "skill_fireball";
        case SKILL_POISON_MIST: return "skill_poison_mist";
        case SKILL_ICE_SPEAR: return "skill_ice_spear";
        case SKILL_MEDITATION: return "skill_meditation";
        case SKILL_FORESIGHT: return "skill_foresight";
    }
    return "skill_generic";
}

function SFX_PlaySkill(_skill_id) {
    var key = SFX_SkillKey(_skill_id);
    var h = SFX_Play(key);
    if (h == -1 && key != "skill_generic") return SFX_Play("skill_generic");
    return h;
}

function SFX_PlayMissOrBlocked(_attacker_is_monster, _defender_class_id) {
    if (_attacker_is_monster && _defender_class_id == CLASS_KNIGHT) return SFX_Play("blocked");
    return SFX_Play("miss_effect");
}

function BGM_GetTrackForRoom(_room_id) {
    return "overall_bgm";
}

function BGM_GetTrackNameForRoom(_room_id) {
    return BGM_GetTrackForRoom(_room_id);
}

function BGM_ApplyForRoom(_room_id) {
    SFX_EnsureManager();
    var track_key = BGM_GetTrackForRoom(_room_id);
    if (track_key == "") {
        BGM_Stop(250);
        return;
    }
    BGM_Play(track_key, true, false);
}
