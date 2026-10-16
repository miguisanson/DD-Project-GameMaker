function DSList_ToArray(_list) {
    var arr = [];
    if (!ds_exists(_list, ds_type_list)) return arr;
    for (var i = 0; i < ds_list_size(_list); i++) {
        array_push(arr, _list[| i]);
    }
    return arr;
}

function Array_ToDSList(_arr) {
    var list = ds_list_create();
    for (var i = 0; i < array_length(_arr); i++) ds_list_add(list, _arr[i]);
    return list;
}

function Save_ToReal(_value, _fallback) {
    if (is_real(_value)) return _value;
    if (is_string(_value)) {
        // real() throws on non-numeric text (SAVE-05); a corrupt value must fall back instead.
        try { return real(_value); } catch (_e) { return _fallback; }
    }
    if (is_bool(_value)) return _value ? 1 : 0;
    return _fallback;
}

// ---- SAVE-04: atomic, crash-safe file helpers (used by save slots and settings_config.json) ----
// Layout for a file F: F (current), F.bak (previous good copy), F.tmp (in-flight write; never loaded).
function Save_ReadTextFile(_path) {
    if (!file_exists(_path)) return undefined;
    var buf = buffer_load(_path);
    if (buf == -1) return undefined;
    var text = undefined;
    if (buffer_get_size(buf) > 0) {
        try { text = buffer_read(buf, buffer_string); } catch (_e) { text = undefined; }
    }
    buffer_delete(buf);
    return text;
}

// Parses JSON text; undefined when the text is empty, is not JSON, or fails the optional validator.
function Save_ParseJsonText(_text, _validate = undefined) {
    if (!is_string(_text) || string_length(_text) == 0) return undefined;
    var c0 = string_char_at(_text, 1);
    if (c0 != "{" && c0 != "[") return undefined;
    var value = undefined;
    try { value = json_parse(_text); } catch (_e) { return undefined; }
    if (!is_undefined(_validate)) {
        var good = false;
        try { good = _validate(value); } catch (_e2) { good = false; }
        if (!good) return undefined;
    }
    return value;
}

// Reads F; if F is missing, unparsable or invalid, reads F.bak instead. Never throws; undefined if neither is usable.
function Save_ReadJsonFile(_path, _validate = undefined) {
    var value = Save_ParseJsonText(Save_ReadTextFile(_path), _validate);
    if (!is_undefined(value)) return value;
    return Save_ParseJsonText(Save_ReadTextFile(_path + ".bak"), _validate);
}

function Save_DeleteFileSet(_path) {
    if (file_exists(_path)) file_delete(_path);
    if (file_exists(_path + ".bak")) file_delete(_path + ".bak");
    if (file_exists(_path + ".tmp")) file_delete(_path + ".tmp");
}

// Writes _text to F.tmp, re-reads and parses it, then swaps it in: the old good F becomes F.bak, F.tmp becomes F.
// Returns true when F now holds _text. On any failure F and F.bak are left as they were and F.tmp is removed.
function Save_WriteFileAtomic(_path, _text, _validate = undefined) {
    var tmp = _path + ".tmp";
    var bak = _path + ".bak";
    if (file_exists(tmp)) file_delete(tmp);

    var buf = buffer_create(string_length(_text) + 1, buffer_grow, 1);
    buffer_write(buf, buffer_string, _text);
    buffer_save(buf, tmp);
    buffer_delete(buf);

    var back = Save_ReadTextFile(tmp);
    if (!is_string(back) || back != _text || is_undefined(Save_ParseJsonText(back, _validate))) {
        if (file_exists(tmp)) file_delete(tmp);
        return false;
    }

    // Keep the previous save as .bak, but only if it is itself good (never replace a good .bak with a bad file).
    if (file_exists(_path) && !is_undefined(Save_ParseJsonText(Save_ReadTextFile(_path), _validate))) {
        if (file_exists(bak)) file_delete(bak);
        file_copy(_path, bak);
    }

    if (file_exists(_path)) file_delete(_path);
    var ok = file_rename(tmp, _path);
    if (!ok || !file_exists(_path)) {
        ok = file_copy(tmp, _path);
        if (file_exists(tmp)) file_delete(tmp);
    }
    return ok && file_exists(_path);
}

function Save_IsStructValue(_value) {
    return is_struct(_value);
}

function Save_SettingsPath() {
    return "settings_config.json";
}

function Save_ReadSettingsConfig(_path = undefined) {
    var path = is_undefined(_path) ? Save_SettingsPath() : _path;
    var raw = Save_ReadJsonFile(path, Save_IsStructValue);   // falls back to settings_config.json.bak
    if (!is_struct(raw)) return undefined;
    var settings_version = 0;
    if (variable_struct_exists(raw, "settings_version")) settings_version = Save_ToReal(raw.settings_version, 0);

    var out = {};
    if (variable_struct_exists(raw, "vol_ui")) out.audio_ui = raw.vol_ui;
    if (variable_struct_exists(raw, "vol_sfx")) out.audio_sfx = raw.vol_sfx;
    if (variable_struct_exists(raw, "vol_bgm")) out.audio_bgm = raw.vol_bgm;
    if (variable_struct_exists(raw, "display_scale")) out.display_scale = raw.display_scale;
    var legacy_fit_screen = variable_struct_exists(raw, "fit_screen") && (Save_ToReal(raw.fit_screen, 0) != 0);
    if (variable_struct_exists(raw, "language")) out.language = raw.language;
    // Version 9 (D0): text_speed, screen_shake, qte_assist. An older file lacks them and gets the defaults from GameSettings_Normalize.
    if (variable_struct_exists(raw, "text_speed")) out.text_speed = raw.text_speed;
    if (variable_struct_exists(raw, "screen_shake")) out.screen_shake = raw.screen_shake;
    if (variable_struct_exists(raw, "qte_assist")) out.qte_assist = raw.qte_assist;
    // G8 (D136): rumble. No version bump: a file of any version without the field gets the default (On) from GameSettings_Normalize.
    if (variable_struct_exists(raw, "rumble")) out.rumble = raw.rumble;
    // Version 10 (D49): keys, the keyboard keys per rebindable action. An older file has none and gets the default keys.
    if (settings_version >= 10 && variable_struct_exists(raw, "keys")) out.keys = raw.keys;

    // Migrate older configs that defaulted to tiny 1x startup scale.
    if (settings_version < 2) {
        var loaded_scale = DISPLAY_SCALE_DEFAULT;
        if (variable_struct_exists(out, "display_scale")) loaded_scale = Save_ToReal(out.display_scale, DISPLAY_SCALE_DEFAULT);
        if (loaded_scale <= 1) out.display_scale = DISPLAY_SCALE_DEFAULT;
    }

    // Migration: disable legacy monitor-fit startup to prevent fullscreen-like launch on fresh/old configs.
    if (settings_version < 6) legacy_fit_screen = false;

    // Migration 7 -> 8 (D91, DISP-14): fit_screen (a fullscreen switch) became window_mode. Old files keep what they had: fit_screen on
    // is the exclusive fullscreen it always was, off is windowed at their scale. A version 8 file carries window_mode itself, and one that
    // lacks it gets the default (borderless, same as a fresh install).
    if (settings_version < 8) out.window_mode = Display_ModeFromLegacy(legacy_fit_screen);
    else if (variable_struct_exists(raw, "window_mode")) out.window_mode = raw.window_mode;

    return GameSettings_Normalize(out);
}

function Save_WriteSettingsConfig(_settings, _path = undefined) {
    var s = GameSettings_Normalize(_settings);
    var raw = {
        settings_version: 10,
        vol_ui: s.audio_ui,
        vol_sfx: s.audio_sfx,
        vol_bgm: s.audio_bgm,
        display_scale: s.display_scale,
        window_mode: s.window_mode,
        language: s.language,
        text_speed: s.text_speed,
        screen_shake: s.screen_shake,
        rumble: s.rumble,
        qte_assist: s.qte_assist,
        keys: s.keys
    };

    var path = is_undefined(_path) ? Save_SettingsPath() : _path;
    return Save_WriteFileAtomic(path, json_stringify(raw), Save_IsStructValue);
}

function Save_IsCurrentSnapshot(_snap) {
    if (!is_struct(_snap)) return false;
    if (!variable_struct_exists(_snap, "save_version")) return false;
    var ver = Save_ToReal(_snap.save_version, -1);
    if (ver != SAVE_SNAPSHOT_VERSION) return false;
    if (!variable_struct_exists(_snap, "statData")) return false;
    return is_struct(_snap.statData);
}

// Loads a snapshot from F, or from F.bak when F is corrupt or not a current snapshot. Never throws. Nothing is ever deleted (D16).
function Save_LoadSnapshotFile(_path) {
    return Save_ReadJsonFile(_path, Save_IsCurrentSnapshot);
}

function Save_LoadLatestSettings() {
    var cfg = Save_ReadSettingsConfig();
    if (is_struct(cfg)) return cfg;
    return undefined;
}

function Save_PersistEntryEnemyId(_entry, _key = "") {
    if (!is_struct(_entry)) return -1;
    if (variable_struct_exists(_entry, "enemy_id")) return _entry.enemy_id;
    if (variable_struct_exists(_entry, "vars") && is_struct(_entry.vars) && variable_struct_exists(_entry.vars, "enemy_id")) {
        return _entry.vars.enemy_id;
    }

    // Backward-compat fallback for older auto-generated persist keys.
    if (_key != "") {
        if (string_pos(":obj_mini_boss:", _key) > 0) return ENEMY_MINI_BOSS;
        if (string_pos(":obj_final_boss:", _key) > 0) return ENEMY_FINAL_BOSS;
    }
    return -1;
}

function Save_IsEnemyPersistEntry(_entry, _key = "") {
    if (!is_struct(_entry)) return false;
    if (Save_PersistEntryEnemyId(_entry, _key) != -1) return true;
    if (variable_struct_exists(_entry, "removed_reset_version")) return true;
    if (variable_struct_exists(_entry, "obj_name")) {
        var obj_name = string(_entry.obj_name);
        if (obj_name != "") {
            var obj_idx = asset_get_index(obj_name);
            if (obj_idx != -1 && (obj_idx == obj_enemy || object_is_ancestor(obj_idx, obj_enemy))) {
                return true;
            }
        }
    }
    return false;
}

function Save_DeriveBossFlagsFromPersist(_persist) {
    var out = { mini_boss: false, final_boss: false };
    if (!is_struct(_persist)) return out;

    var keys = variable_struct_get_names(_persist);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var entry = variable_struct_get(_persist, key);
        if (!Save_IsEnemyPersistEntry(entry, key)) continue;
        if (!is_struct(entry)) continue;
        if (!variable_struct_exists(entry, "removed") || !entry.removed) continue;

        var enemy_id = Save_PersistEntryEnemyId(entry, key);
        if (enemy_id == ENEMY_MINI_BOSS) out.mini_boss = true;
        if (enemy_id == ENEMY_FINAL_BOSS) out.final_boss = true;
    }

    return out;
}

function Save_FilterPersistWithoutEnemies(_persist) {
    var out = {};
    if (!is_struct(_persist)) return out;

    var keys = variable_struct_get_names(_persist);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var entry = variable_struct_get(_persist, key);
        if (Save_IsEnemyPersistEntry(entry, key)) continue;
        variable_struct_set(out, key, entry);
    }
    return out;
}

// Where the player is: the live player in the current room, else the checkpoint.
function Save_CapturePosition() {
    var gs = GameState_Get();
    var px = 0;
    var py = 0;
    var face = DOWN;
    var room_name = "";
    var pl_inst = gs.player_inst;
    if (!instance_exists(pl_inst) && instance_exists(obj_player)) pl_inst = instance_find(obj_player, 0);
    if (instance_exists(pl_inst)) {
        room_name = room_get_name(room);
        px = pl_inst.x;
        py = pl_inst.y;
        if (variable_instance_exists(pl_inst, "face")) face = pl_inst.face;
    } else {
        room_name = room_get_name(gs.checkpoint.room);
        px = gs.checkpoint.x;
        py = gs.checkpoint.y;
    }
    return { room_name: room_name, x: px, y: py, face: face };
}

function Save_BuildSnapshot() {
    var gs = GameState_Get();
    var stat = {};
    stat.selected_class = gs.selected_class;
    stat.difficulty = Difficulty_Normalize(gs.difficulty);
    stat.player = gs.player_ch;
    stat.flags = gs.flags;
    stat.checkpoint = gs.checkpoint;
    stat.defeated = DSList_ToArray(gs.defeated_enemies);
    stat.uid_counter = gs.uid_counter;
    stat.enemy_reset_version = gs.enemy_reset_version;
    stat.save_slot = gs.save_slot;
    stat.saved_at = date_current_datetime();

    var boss_flags = Save_DeriveBossFlagsFromPersist(gs.persist);
    if (variable_struct_exists(gs, "boss_defeated") && is_struct(gs.boss_defeated)) {
        if (variable_struct_exists(gs.boss_defeated, "mini_boss") && gs.boss_defeated.mini_boss) boss_flags.mini_boss = true;
        if (variable_struct_exists(gs.boss_defeated, "final_boss") && gs.boss_defeated.final_boss) boss_flags.final_boss = true;
    }
    stat.boss_defeated = boss_flags;

    var where = Save_CapturePosition();
    stat.save_room_name = where.room_name;
    stat.save_x = where.x;
    stat.save_y = where.y;
    stat.save_face = where.face;

    var snap = {};
    snap.save_version = SAVE_SNAPSHOT_VERSION;
    snap.statData = stat;
    snap.levelData = Save_FilterPersistWithoutEnemies(gs.persist);
    return snap;
}

// Puts a snapshot's state into the game and returns where to enter: { room_id, x, y, face }. Starts no transition.
// _keep_enemies: a run save keeps the room-state entries of enemies (which ones are defeated this run); a slot snapshot drops them.
function Save_ApplySnapshotState(_snap, _keep_enemies = false) {
    var gs = GameState_Init();
    var stat = {};
    if (variable_struct_exists(_snap, "statData")) stat = _snap.statData; else stat = _snap;

    gs.selected_class = stat.selected_class;
    if (variable_struct_exists(stat, "difficulty")) {
        gs.difficulty = Difficulty_Normalize(stat.difficulty);
    } else {
        gs.difficulty = DIFFICULTY_NORMAL;
    }
    gs.player_ch = stat.player;
    if (is_struct(gs.player_ch)) {
        if (!variable_struct_exists(gs.player_ch, "class_id")) gs.player_ch.class_id = gs.selected_class;
        gs.player_ch = Player_NormalizeProgression(gs.player_ch, true);
        gs.selected_class = gs.player_ch.class_id;
    }
    if (variable_struct_exists(stat, "flags") && is_struct(stat.flags)) gs.flags = stat.flags;
    else gs.flags = {};
    var skillbook_done_key = Dialogue_SkillbookFirstReadDoneFlagKey();
    var skillbook_pending_key = Dialogue_SkillbookFirstReadPendingFlagKey();
    if (!variable_struct_exists(gs.flags, skillbook_done_key)) variable_struct_set(gs.flags, skillbook_done_key, false);
    if (!variable_struct_exists(gs.flags, skillbook_pending_key)) variable_struct_set(gs.flags, skillbook_pending_key, false);
    gs.checkpoint = stat.checkpoint;
    if (variable_struct_exists(stat, "uid_counter")) gs.uid_counter = stat.uid_counter;

    if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_destroy(gs.defeated_enemies);
    var defeated_arr = variable_struct_exists(stat, "defeated") ? stat.defeated : [];
    gs.defeated_enemies = Array_ToDSList(defeated_arr);

    var levelData = {};
    if (variable_struct_exists(_snap, "levelData")) levelData = _snap.levelData;
    else if (variable_struct_exists(_snap, "persist")) levelData = _snap.persist;

    var boss_flags = Save_DeriveBossFlagsFromPersist(levelData);
    if (variable_struct_exists(stat, "boss_defeated") && is_struct(stat.boss_defeated)) {
        if (variable_struct_exists(stat.boss_defeated, "mini_boss") && stat.boss_defeated.mini_boss) boss_flags.mini_boss = true;
        if (variable_struct_exists(stat.boss_defeated, "final_boss") && stat.boss_defeated.final_boss) boss_flags.final_boss = true;
    }
    gs.boss_defeated = boss_flags;

    gs.persist = _keep_enemies ? levelData : Save_FilterPersistWithoutEnemies(levelData);
    gs.persist_applied = {};

    if (variable_struct_exists(stat, "enemy_reset_version")) gs.enemy_reset_version = stat.enemy_reset_version; else gs.enemy_reset_version = 0;
    if (variable_struct_exists(stat, "save_slot")) gs.save_slot = stat.save_slot; else gs.save_slot = 0;
    var room_name = "";
    if (variable_struct_exists(stat, "save_room_name")) room_name = stat.save_room_name;
    if (room_name == "" && variable_struct_exists(_snap, "room")) room_name = room_get_name(_snap.room);
    if (room_name == "") room_name = room_get_name(gs.checkpoint.room);

    var px = variable_struct_exists(stat, "save_x") ? stat.save_x : (variable_struct_exists(_snap, "player_x") ? _snap.player_x : gs.checkpoint.x);
    var py = variable_struct_exists(stat, "save_y") ? stat.save_y : (variable_struct_exists(_snap, "player_y") ? _snap.player_y : gs.checkpoint.y);
    var face = variable_struct_exists(stat, "save_face") ? stat.save_face : DOWN;
    px = Save_ToReal(px, gs.checkpoint.x);
    py = Save_ToReal(py, gs.checkpoint.y);
    face = round(Save_ToReal(face, DOWN));

    var room_id = asset_get_index(room_name);
    if (room_id == -1) room_id = rm_floor1;

    gs.in_main_menu = false;
    gs.last_room = noone;

    // Save-load should always restore exact saved coordinates, never queued room spawns.
    RoomTransition_Clear();
    Transition_Finish();

    GameState_SyncLegacy();
    GameSettings_ApplyAll();
    Save_WriteSettingsConfig(gs.settings);

    gs.skip_room_save = true;

    gs.load_spawn_pending = true;
    gs.load_spawn_room = room_id;
    gs.load_spawn_x = px;
    gs.load_spawn_y = py;
    gs.load_spawn_face = face;

    // Preserve exact saved position when loading from a slot.
    GameState_SetBattleReturn(room_id, px, py, face, false);
    GameState_SetJustReturned(true);
    return { room_id: room_id, x: px, y: py, face: face };
}

function Save_ApplySnapshot(_snap) {
    var info = Save_ApplySnapshotState(_snap, false);
    Save_BeginLoadTransition(info.room_id);
}

function Save_BeginLoadTransition(_room_id) {
    var room_id = _room_id;
    // Use a slower loading-style fade so loaded rooms stay hidden until the black screen fully owns the transition.
    var load_transition_ok = Transition_RequestLoadingRoomFade(room_id);
    if (!load_transition_ok) {
        // If a previous transition is stuck active, force-finish and retry once.
        Transition_Finish();
        load_transition_ok = Transition_RequestLoadingRoomFade(room_id);
    }
    if (!load_transition_ok) {
        // Last-resort fallback: still honor the loaded snapshot and room target.
        Transition_PreRoomChange();
        room_goto(room_id);
    }
}

// Text of the "game saved" popup: the existing dialogue key sys_save_ok (scr_dialogue.gml), so it follows the language.
function Save_SuccessText() {
    return Loc_T("dialogue.sys_save_ok.0", "Game saved.");
}

function Save_Path(_slot) {
    var idx = _slot;
    if (idx <= 0) idx = 0; else idx = _slot - 1;
    return "savedata" + string(idx) + ".sav";
}

// ============================================================================================================
// C1: profile + run saves (D16, D36, D46), per profile since D175 (saves1). Files, each with its own version:
//   profiles.sav        the index of up to 4 profiles (D175): names, the active profile, the save file last used. Its own validator, version 1.
//   profile_<id>.sav    what outlives a run: story seen, unlocks, the echo waiting for the next run, run history, counters (id 0..3).
//   run_<id>_<slot>.sav the run in progress in save file <slot> (0..2) of profile <id>: seed, RNG stream states, player, room state, position. Deleted when the run ends.
// Before D175 there was one profile.sav and one run.sav: Profiles_EnsureInit migrates them to profile_0.sav / run_0_0.sav once and keeps the originals as *.pre-profiles.
// Everything goes through the SAVE-04 atomic helpers (.tmp -> verify -> .bak). The old slot files (savedata0..3.sav) are never read as
// current, never written and never deleted: they are only recognised, so the title screen can say why they cannot be loaded.
// ============================================================================================================
#macro PROFILE_VERSION 3   // 3 (D175): name, a copy of the index name (the index is authoritative). 2 (D148): skills_known, the skill memory. An older file is read and migrated.
#macro RUN_SAVE_VERSION 3   // 3 (D175): the summary block (class, level, floor, run time, seed, saved_at) the save-file list reads. A version 2 file still loads (migrated in memory).
#macro RUN_SAVE_MIN_VERSION 2
#macro PROFILE_HISTORY_MAX 50
#macro PROFILES_MAX 4
#macro PROFILE_SLOTS 3
#macro PROFILE_NAME_MAX 12
#macro PROFILES_INDEX_VERSION 1

// Prefix of every profile/save file name: "" in the game; a test sandbox sets global.save_prefix so it never touches the real files.
function Save_Prefix() {
    return (variable_global_exists("save_prefix") && is_string(global.save_prefix)) ? global.save_prefix : "";
}

function Profiles_IndexPath() {
    return Save_Prefix() + "profiles.sav";
}

function Profiles_PathOf(_id) {
    return Save_Prefix() + "profile_" + string(_id) + ".sav";
}

function Slots_PathOf(_id, _slot) {
    return Save_Prefix() + "run_" + string(_id) + "_" + string(_slot) + ".sav";
}

// The ACTIVE profile's file.
function Profile_Path() {
    return Profiles_PathOf(Profiles_Active());
}

// The ACTIVE profile's ACTIVE save file (the global save slot, set by New Game / Load Game / Continue through Slot_SetActive).
function RunSave_Path() {
    return Slots_PathOf(Profiles_Active(), Slot_Active());
}

// ---- old slot files (D16) ----
function Save_LegacyPaths() {
    return [Save_Path(0), Save_Path(1), Save_Path(2), Save_Path(3)];
}

function Save_LegacyFilesExist(_paths = undefined) {
    var paths = is_undefined(_paths) ? Save_LegacyPaths() : _paths;
    for (var i = 0; i < array_length(paths); i++) {
        if (file_exists(paths[i])) return true;
    }
    return false;
}

function Save_LegacyNotice() {
    return Loc_T("save.legacy.notice", "Saves from the earlier version cannot be loaded in this one. They have been left untouched. Start a new run.");
}

// Keeps a file that could not be read next to the new one instead of silently losing it.
function Save_QuarantineFile(_path) {
    if (!file_exists(_path)) return false;
    var dst = _path + ".corrupt";
    if (file_exists(dst)) file_delete(dst);
    return file_copy(_path, dst);
}

// ---- profile ----
function Profile_Default() {
    return {
        profile_version: PROFILE_VERSION,
        story_seen: {},                        // key -> true: cutscenes, camera pans, story dialogue (D26)
        unlocks: {},                           // key -> true: "nobody_class", "item_<id>" ... (D88)
        echo_pool: [],                         // OLD (D130): the item pool of the lost run. D144 stopped filling it; it is still read so an old file loads, and the class pick empties it
        skills_known: {},                      // D148: "<skill id>" -> true for every player skill the profile has ever had in a run (skill memory); the class screen and the echo (D144) read it
        history: [],                           // one entry per finished run, newest last
        bestiary: {},                          // "e<enemy id>" -> { met, elite }: the enemies met in a fight, for the Codex (D88; Codex_Met)
        deaths: 0,
        wins: 0,
        runs_started: 0,
        best_floor: 0,
        legacy_notice_seen: false,
        name: "",                              // D175: a copy of the profile's name in the index (the index is authoritative); "" until a flush
        last_title: "",                        // D183: the text key of the run summary's title shown last, so the next one differs ("" = none yet; an older file reads as none)
        settings_file: Save_SettingsPath()     // settings stay in their own file
    };
}

function Profile_IsCurrentRaw(_raw) {
    if (!is_struct(_raw)) return false;
    if (!variable_struct_exists(_raw, "profile_version")) return false;
    var ver = Save_ToReal(_raw.profile_version, -1);
    return ver >= 1 && ver <= PROFILE_VERSION;   // an older file is migrated by Profile_Normalize
}

// A valid profile file with some keys missing is filled up from the defaults; wrong-typed keys fall back too.
function Profile_Normalize(_raw) {
    var p = Profile_Default();
    if (!is_struct(_raw)) return p;
    if (variable_struct_exists(_raw, "story_seen") && is_struct(_raw.story_seen)) p.story_seen = _raw.story_seen;
    if (variable_struct_exists(_raw, "unlocks") && is_struct(_raw.unlocks)) p.unlocks = _raw.unlocks;
    // D130: echo_pool is what a death left for the next class pick. A file without it has no echo pending. A file from the build before D130 may hold a death
    // whose pick was not made (echo_offer) or made but not used yet (echo): either becomes the pool, so that death still gives its gift.
    var pool_src = [];
    if (variable_struct_exists(_raw, "echo_pool") && is_array(_raw.echo_pool)) pool_src = _raw.echo_pool;
    else if (variable_struct_exists(_raw, "echo") && is_struct(_raw.echo) && variable_struct_exists(_raw.echo, "kind") && (string(_raw.echo.kind) == "item" || string(_raw.echo.kind) == "skill")) pool_src = [_raw.echo];
    else if (variable_struct_exists(_raw, "echo_offer") && is_array(_raw.echo_offer)) pool_src = _raw.echo_offer;
    for (var i = 0; i < array_length(pool_src); i++) {
        var o = pool_src[i];
        if (!is_struct(o) || !variable_struct_exists(o, "kind") || !variable_struct_exists(o, "id")) continue;
        var okind = string(o.kind);
        var oid = Save_ToReal(o.id, -1);
        if ((okind == "item" || okind == "skill") && !Run_EchoHas(p.echo_pool, okind, oid)) array_push(p.echo_pool, { kind: okind, id: oid });
    }
    var raw_ver = Save_ToReal(variable_struct_exists(_raw, "profile_version") ? _raw.profile_version : 0, 0);
    // Review 6: a version 1 file has no skill memory field, but what it does hold is the echo of its last death (echo_pool, or the older echo_offer / echo): "everything the lost run had",
    // skills included (Run_EchoPoolAfter, before D144). Those skills were held in a run, so they are discovered (D148); without this the first playtest after the update showed "???"
    // for them and the echo had nothing to offer. Items in the pool are not skills. v1 holds no other skill list: a history entry has the class and level only.
    if (raw_ver < 2) {
        for (var ek = 0; ek < array_length(p.echo_pool); ek++) {
            if (p.echo_pool[ek].kind == "skill") Profile_SkillLearn(p, p.echo_pool[ek].id);
        }
    }
    // D148: version 2 added the skill memory; a version 1 file has none of its own, so it starts from the pool above (whatever the file holds under that name is not trusted)
    if (raw_ver >= 2 && variable_struct_exists(_raw, "skills_known") && is_struct(_raw.skills_known)) {
        var sknames = variable_struct_get_names(_raw.skills_known);
        for (var sk = 0; sk < array_length(sknames); sk++) {
            if (sknames[sk] != "" && string_digits(sknames[sk]) == sknames[sk] && variable_struct_get(_raw.skills_known, sknames[sk]) == true) variable_struct_set(p.skills_known, string(real(sknames[sk])), true);
        }
    }
    if (variable_struct_exists(_raw, "history") && is_array(_raw.history)) {
        for (var h = 0; h < array_length(_raw.history); h++) {
            if (is_struct(_raw.history[h])) array_push(p.history, _raw.history[h]);
        }
        while (array_length(p.history) > PROFILE_HISTORY_MAX) array_delete(p.history, 0, 1);
    }
    if (variable_struct_exists(_raw, "bestiary") && is_struct(_raw.bestiary)) {
        var bkeys = variable_struct_get_names(_raw.bestiary);
        for (var bi = 0; bi < array_length(bkeys); bi++) {
            var be = variable_struct_get(_raw.bestiary, bkeys[bi]);
            if (is_struct(be) && variable_struct_exists(be, "met")) {
                variable_struct_set(p.bestiary, bkeys[bi], { met: max(1, Save_ToReal(be.met, 1)), elite: variable_struct_exists(be, "elite") && (Save_ToReal(be.elite, 0) != 0) });
            }
        }
    }
    var counters = ["deaths", "wins", "runs_started", "best_floor"];
    for (var c = 0; c < array_length(counters); c++) {
        if (variable_struct_exists(_raw, counters[c])) variable_struct_set(p, counters[c], max(0, Save_ToReal(variable_struct_get(_raw, counters[c]), 0)));
    }
    if (variable_struct_exists(_raw, "legacy_notice_seen")) p.legacy_notice_seen = (Save_ToReal(_raw.legacy_notice_seen, 0) != 0);
    if (variable_struct_exists(_raw, "name") && is_string(_raw.name)) p.name = _raw.name;
    if (variable_struct_exists(_raw, "last_title") && is_string(_raw.last_title)) p.last_title = _raw.last_title;
    return p;
}

// Loads a profile file. Returns { status, profile }. status:
//   ok       a current profile (falls back to .bak when the main file is damaged)
//   missing  no file; a default profile
//   newer    written by a newer game; a default profile marked locked, the file is left alone and never written
//   old      a file without a current version; same as newer
//   corrupt  unreadable; a default profile, the bad file is kept as <file>.corrupt
function Profile_Load(_path = undefined) {
    var path = is_undefined(_path) ? Profile_Path() : _path;
    var out = { status: "missing", profile: Profile_Default() };

    var cur = Save_ReadJsonFile(path, Profile_IsCurrentRaw);
    if (is_struct(cur)) {
        out.status = "ok";
        out.profile = Profile_Normalize(cur);
        return out;
    }

    var raw = Save_ParseJsonText(Save_ReadTextFile(path), Save_IsStructValue);
    if (is_struct(raw)) {
        var ver = variable_struct_exists(raw, "profile_version") ? Save_ToReal(raw.profile_version, 0) : 0;
        out.status = (ver > PROFILE_VERSION) ? "newer" : "old";
        out.profile.locked = true;
        return out;
    }

    if (file_exists(path)) {
        Save_QuarantineFile(path);
        out.status = "corrupt";
    }
    return out;
}

// false when the profile came from a file that must not be overwritten (newer / old) or the write failed.
function Profile_SaveTo(_path, _profile) {
    if (!is_struct(_profile)) return false;
    if (variable_struct_exists(_profile, "locked") && _profile.locked) return false;
    _profile.profile_version = PROFILE_VERSION;
    return Save_WriteFileAtomic(_path, json_stringify(_profile), Profile_IsCurrentRaw);
}

function Profile_StorySeen(_p, _key) {
    return variable_struct_exists(_p.story_seen, _key) && (variable_struct_get(_p.story_seen, _key) == true);
}

function Profile_StoryMark(_p, _key) {
    variable_struct_set(_p.story_seen, _key, true);
}

function Profile_IsUnlocked(_p, _key) {
    return variable_struct_exists(_p.unlocks, _key) && (variable_struct_get(_p.unlocks, _key) == true);
}

function Profile_Unlock(_p, _key) {
    variable_struct_set(_p.unlocks, _key, true);
}

// ---- skill memory (D148): the player skills this profile has ever had in a run ----
function Profile_SkillKnown(_p, _skill_id) {
    if (!is_struct(_p) || !variable_struct_exists(_p, "skills_known") || !is_struct(_p.skills_known)) return false;
    var key = string(floor(Save_ToReal(_skill_id, -1)));
    return variable_struct_exists(_p.skills_known, key) && (variable_struct_get(_p.skills_known, key) == true);
}

// Remembers a skill id. Returns true when it was new, false when it was known already (or is no id).
function Profile_SkillLearn(_p, _skill_id) {
    var sid = floor(Save_ToReal(_skill_id, -1));
    if (!is_struct(_p) || sid < 0 || Profile_SkillKnown(_p, sid)) return false;
    if (!variable_struct_exists(_p, "skills_known") || !is_struct(_p.skills_known)) _p.skills_known = {};
    variable_struct_set(_p.skills_known, string(sid), true);
    return true;
}

// THE helper every way of getting a skill goes through (card pick, swap, echo, direct learn, the class pick and the end of a run): remembers a player
// skill in the profile and writes the profile when it is new. Enemy skills and ids that are no skill are ignored. Returns true when it was new.
// With _prof given (tests) that profile is changed in memory only.
function Skill_Discover(_skill_id, _prof = undefined) {
    var sid = floor(Save_ToReal(_skill_id, -1));
    if (sid < 0) return false;
    var sk = SkillDB_GetBase(sid);
    if (sk.id < 0 || !is_array(sk.class_list) || array_length(sk.class_list) <= 0) return false;
    var own = is_undefined(_prof);
    var prof = own ? Profile_Get() : _prof;
    if (!Profile_SkillLearn(prof, sid)) return false;
    if (own) Profile_Flush();
    return true;
}

function Skills_DiscoverAll(_ids, _prof = undefined) {
    if (!is_array(_ids)) return false;
    var any = false;
    for (var i = 0; i < array_length(_ids); i++) {
        if (Skill_Discover(_ids[i], _prof)) any = true;
    }
    return any;
}

// A finished run: history (newest last, capped), the death or win counter, the best floor, and the first win's unlock (D88).
function Profile_RecordRun(_p, _entry) {
    array_push(_p.history, _entry);
    while (array_length(_p.history) > PROFILE_HISTORY_MAX) array_delete(_p.history, 0, 1);
    var result = variable_struct_exists(_entry, "result") ? string(_entry.result) : "died";
    if (result == "won") {
        _p.wins += 1;
        Profile_Unlock(_p, "nobody_class");
    } else {
        _p.deaths += 1;
    }
    if (variable_struct_exists(_entry, "floor")) _p.best_floor = max(_p.best_floor, Save_ToReal(_entry.floor, 0));
}

// ---- the profile of this game session (loaded from disk on first use) ----
function Profile_Get() {
    if (!variable_global_exists("profile") || !is_struct(global.profile)) {
        var r = Profile_Load(Profile_Path());
        global.profile = r.profile;
        global.profile_status = r.status;
        global.profile.name = Profiles_ActiveName();
    }
    return global.profile;
}

function Profile_Flush() {
    var p = Profile_Get();
    p.name = Profiles_ActiveName();   // D175: the file keeps a copy of the name; the index is authoritative
    return Profile_SaveTo(Profile_Path(), p);
}

// What to tell the player about the profile file at launch: "" when it loaded fine or did not exist yet.
function Profile_NoticeText() {
    Profile_Get();
    var st = global.profile_status;
    if (st == "newer" || st == "old") return Loc_T("profile.notice.locked", "Your profile was saved by a different version of the game. It has been left untouched, and progress will not be saved this time.");
    if (st == "corrupt") return Loc_T("profile.notice.corrupt", "Your profile file was damaged, so a fresh one was started. The damaged file was kept next to it.");
    return "";
}

// ---- unlocks (D88): the Nobody class (first win) and extra pool items/cards/passives; no permanent power ----
// Keys: "nobody_class", "item_<id>", "skill_<id>" ... Anything that offers a pool entry asks Profile_IsUnlocked first.

// A fresh in-memory profile and no profile file (scenarios and tests only).
function Profile_ResetForTest() {
    global.profile = Profile_Default();
    global.profile.name = Profiles_ActiveName();
    global.profile_status = "missing";
    Save_DeleteFileSet(Profile_Path());
}

// ---- story seen once per profile (D26, D106) ----
// Profile key of a cutscene ("intro", "ending"); dialogue triggers use "trigger:<room>:<id>", one-time reactions "flag:<name>".
function Story_CutsceneKey(_cutscene_id) {
    return "cutscene:" + string(_cutscene_id);
}

function Story_Seen(_key) {
    return Profile_StorySeen(Profile_Get(), _key);
}

function Story_Mark(_key) {
    var p = Profile_Get();
    if (Profile_StorySeen(p, _key)) return;
    Profile_StoryMark(p, _key);
    Profile_Flush();
}

// Story that the older code keeps as run flags (gs.flags): the one-time reactions. They are copied to the profile when a run
// is saved or ends, and copied back into the flags of the next run, so those reactions do not replay (D26).
function Story_IsFlagKey(_name) {
    if (_name == "floor1_slime_kill_reaction_done") return true;
    if (_name == "skillbook_first_read_done") return true;
    if (string_pos("narrative_event_done_", _name) == 1) return true;
    return false;
}

// R-103: a one-time reaction that lives as a run flag has just been shown. Set the run flag AND the profile's story key, and flush the profile at once
// (like Story_Mark for a trigger): the 10 s autosave, a run end or a clean close would be too late if the game is killed before them.
function Story_MarkFlag(_name) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    variable_struct_set(gs.flags, _name, true);
    Story_Mark("flag:" + _name);
}

// Has this profile seen the one-time reaction (whatever the run's flags say)?
function Story_FlagSeen(_name) {
    return Story_Seen("flag:" + _name);
}

function Story_CopyFlagsToProfile(_p, _flags) {
    if (!is_struct(_flags)) return false;
    var changed = false;
    var names = variable_struct_get_names(_flags);
    for (var i = 0; i < array_length(names); i++) {
        if (!Story_IsFlagKey(names[i])) continue;
        if (variable_struct_get(_flags, names[i]) != true) continue;
        var key = "flag:" + names[i];
        if (!Profile_StorySeen(_p, key)) {
            Profile_StoryMark(_p, key);
            changed = true;
        }
    }
    return changed;
}

function Story_CopyProfileToFlags(_p, _flags) {
    var names = variable_struct_get_names(_p.story_seen);
    for (var i = 0; i < array_length(names); i++) {
        if (string_pos("flag:", names[i]) != 1) continue;
        if (variable_struct_get(_p.story_seen, names[i]) != true) continue;
        variable_struct_set(_flags, string_delete(names[i], 1, 5), true);
    }
}

// ---- run save ----
function RunSave_IsCurrentRaw(_raw) {
    if (!is_struct(_raw)) return false;
    if (!variable_struct_exists(_raw, "run_version")) return false;
    var ver = Save_ToReal(_raw.run_version, -1);
    if (ver < RUN_SAVE_MIN_VERSION || ver > RUN_SAVE_VERSION) return false;   // D175: a version 2 file is still good (RunSave_LoadFrom migrates it in memory)
    if (!variable_struct_exists(_raw, "seed") || !variable_struct_exists(_raw, "statData")) return false;
    return is_struct(_raw.statData);
}

// "ok" | "newer" | "old" (no run_version: the old slot format or anything else) | "corrupt"
function RunSave_Check(_raw) {
    if (!is_struct(_raw)) return "corrupt";
    if (!variable_struct_exists(_raw, "run_version")) return "old";
    var ver = Save_ToReal(_raw.run_version, 0);
    if (ver > RUN_SAVE_VERSION) return "newer";
    if (ver < RUN_SAVE_MIN_VERSION) return "old";
    return RunSave_IsCurrentRaw(_raw) ? "ok" : "corrupt";
}

function RunSave_ExistsAt(_path) {
    return file_exists(_path) || file_exists(_path + ".bak");
}

function RunSave_HasSave() {
    return RunSave_ExistsAt(RunSave_Path());
}

function RunSave_Delete(_path = undefined) {
    Save_DeleteFileSet(is_undefined(_path) ? RunSave_Path() : _path);
}

// Moves a run file this build must not delete (a newer version's, or a damaged one) to a sibling name in the same folder, "run.kept-<unix time>.sav" ("-2", "-3" ... when that name is
// taken), with its .bak next to it. A rename, so it either happened or it did not; nothing leaves the save folder. Done before a new run can write run.sav (review 6, finding 1: the
// new run's first autosave replaced the file that New Game had "kept"). Returns the new name of the run file, "" when there was nothing to move or the move failed (the file is then
// left where it is and a line goes to the log).
function RunSave_KeepAside(_path = undefined) {
    var path = is_undefined(_path) ? RunSave_Path() : _path;
    if (!file_exists(path) && !file_exists(path + ".bak")) return "";
    var tz = date_get_timezone();
    date_set_timezone(timezone_utc);
    var stamp = floor((date_current_datetime() - 25569) * 86400);   // days since 1899-12-30 -> seconds since 1970-01-01 UTC
    date_set_timezone(tz);
    var base = filename_path(path) + filename_change_ext(filename_name(path), "");
    var ext = filename_ext(path);
    var dst = base + ".kept-" + string(stamp) + ext;
    var n = 1;
    while (file_exists(dst) || file_exists(dst + ".bak")) {
        n++;
        dst = base + ".kept-" + string(stamp) + "-" + string(n) + ext;
    }
    var parts = ["", ".bak"];
    var moved = true;
    for (var i = 0; i < array_length(parts); i++) {
        if (!file_exists(path + parts[i])) continue;
        if (!file_rename(path + parts[i], dst + parts[i]) || !file_exists(dst + parts[i])) moved = false;
    }
    if (file_exists(path + ".tmp")) file_delete(path + ".tmp");   // a half-written file of ours, never the kept one
    if (!moved) {
        show_debug_message("[SAVE] could not move " + path + " aside; it stays where it is");
        return "";
    }
    return dst;
}

// The files RunSave_KeepAside left next to a run file ("run.kept-<unix time>.sav", "run.kept-<unix time>-2.sav" ...), oldest name first. Names are relative to the save folder like the run file's own.
function RunSave_KeptFiles(_path = undefined) {
    var path = is_undefined(_path) ? RunSave_Path() : _path;
    var dir = filename_path(path);
    var ext = filename_ext(path);
    var base = filename_change_ext(filename_name(path), "");
    var out = [];
    var f = file_find_first(dir + base + ".kept-*" + ext, 0);
    while (f != "") {
        array_push(out, dir + f);
        f = file_find_next();
    }
    file_find_close();
    array_sort(out, true);
    return out;
}

// Returns { status, run }: status as for Profile_Load (ok, missing, newer, old, corrupt); run is the parsed save when ok.
function RunSave_LoadFrom(_path = undefined) {
    var path = is_undefined(_path) ? RunSave_Path() : _path;
    var out = { status: "missing", run: undefined };
    var cur = Save_ReadJsonFile(path, RunSave_IsCurrentRaw);
    if (is_struct(cur)) {
        out.status = "ok";
        out.run = RunSave_Migrate(cur);
        return out;
    }
    var raw = Save_ParseJsonText(Save_ReadTextFile(path), Save_IsStructValue);
    if (is_struct(raw)) {
        var st = RunSave_Check(raw);
        out.status = (st == "ok") ? "corrupt" : st;
        return out;
    }
    if (file_exists(path)) out.status = "corrupt";
    return out;
}

// The run as plain data. Enemy room-state entries are kept (which enemies are defeated this run). The player struct is saved whole,
// so stats, skills, inventory, equipment and statuses follow whatever the character holds.
function RunSave_Build() {
    var gs = GameState_Get();
    var run = Run_Get();
    if (!is_struct(run)) run = Run_Create(0);

    var stat = {};
    stat.selected_class = gs.selected_class;
    stat.difficulty = Difficulty_Normalize(gs.difficulty);
    stat.player = gs.player_ch;
    stat.flags = gs.flags;
    stat.checkpoint = gs.checkpoint;
    stat.defeated = DSList_ToArray(gs.defeated_enemies);
    stat.uid_counter = gs.uid_counter;
    stat.enemy_reset_version = gs.enemy_reset_version;
    stat.save_slot = 0;
    stat.saved_at = date_current_datetime();

    var boss_flags = Save_DeriveBossFlagsFromPersist(gs.persist);
    if (variable_struct_exists(gs, "boss_defeated") && is_struct(gs.boss_defeated)) {
        if (variable_struct_exists(gs.boss_defeated, "mini_boss") && gs.boss_defeated.mini_boss) boss_flags.mini_boss = true;
        if (variable_struct_exists(gs.boss_defeated, "final_boss") && gs.boss_defeated.final_boss) boss_flags.final_boss = true;
    }
    stat.boss_defeated = boss_flags;

    var where = Save_CapturePosition();
    var run_floor = Run_FloorOfRoomName(where.room_name);
    var pl = gs.player_ch;
    var summary = {   // D175: what the save-file list shows, readable without applying the run (Slots_Summary)
        class_id: (is_struct(pl) && variable_struct_exists(pl, "class_id")) ? pl.class_id : gs.selected_class,
        level: (is_struct(pl) && variable_struct_exists(pl, "level")) ? pl.level : 1,
        floor: run_floor,
        run_time_ms: RunStats_Of(run).play_ms,
        seed: run.seed,
        saved_at: stat.saved_at
    };
    stat.save_room_name = where.room_name;
    stat.save_x = where.x;
    stat.save_y = where.y;
    stat.save_face = where.face;

    var rng = {};
    var names = Run_StreamNames();
    for (var i = 0; i < array_length(names); i++) {
        variable_struct_set(rng, names[i], Rng_Save(variable_struct_get(run.rng, names[i])));
    }

    return {
        run_version: RUN_SAVE_VERSION,
        seed: run.seed,
        rng: rng,
        gold: run.gold,
        shop: run.shop,        // C3 (D85)
        cards: run.cards,
        kills: run.kills,
        stats: RunStats_Of(run),   // G9 (D137): no version bump; a save without them loads with zeros
        drop_dry: run.drop_dry,   // R1 (D120), run save v2
        gold_bag: run.gold_bag,   // D126: no version bump; a save without them loads with empty bags
        find_bag: run.find_bag,
        started_at: run.started_at,
        floor: run_floor,
        summary: summary,
        statData: stat,
        levelData: gs.persist
    };
}

function RunSave_WriteTo(_path = undefined) {
    var path = is_undefined(_path) ? RunSave_Path() : _path;
    return Save_WriteFileAtomic(path, json_stringify(RunSave_Build()), RunSave_IsCurrentRaw);
}

// Puts a loaded run save into the game: run struct (seed, stream states, gold, kills) and the world/player state.
// Returns { room_id, x, y, face }; the caller starts the transition (Save_BeginLoadTransition).
function RunSave_ApplyState(_raw) {
    EnemyPersist_ClearSnapshot();   // review 6: a loaded run has no fight behind it
    var gs = GameState_Init();
    var info = Save_ApplySnapshotState({ statData: _raw.statData, levelData: variable_struct_exists(_raw, "levelData") ? _raw.levelData : {} }, true);

    var seed = Save_ToReal(_raw.seed, 0);
    var run = Run_Create(seed);
    var names = Run_StreamNames();
    for (var i = 0; i < array_length(names); i++) {
        if (variable_struct_exists(_raw, "rng") && is_struct(_raw.rng) && variable_struct_exists(_raw.rng, names[i])) {
            variable_struct_set(run.rng, names[i], Rng_Load(variable_struct_get(_raw.rng, names[i])));
        }
    }
    if (variable_struct_exists(_raw, "gold")) run.gold = Save_ToReal(_raw.gold, 0);
    if (variable_struct_exists(_raw, "shop") && is_struct(_raw.shop)) run.shop = _raw.shop;   // C3 (D85)
    if (variable_struct_exists(_raw, "cards")) run.cards = Card_StateNormalize(_raw.cards);
    if (variable_struct_exists(_raw, "kills")) run.kills = Save_ToReal(_raw.kills, 0);
    if (variable_struct_exists(_raw, "stats") && is_struct(_raw.stats)) run.stats = RunStats_Normalize(_raw.stats);   // G9 (D137)
    if (variable_struct_exists(_raw, "drop_dry")) run.drop_dry = Save_ToReal(_raw.drop_dry, 0);
    if (variable_struct_exists(_raw, "gold_bag") && is_array(_raw.gold_bag)) {   // D126
        run.gold_bag = [];
        for (var gb = 0; gb < array_length(_raw.gold_bag); gb++) array_push(run.gold_bag, Save_ToReal(_raw.gold_bag[gb], 0));
    }
    if (variable_struct_exists(_raw, "find_bag") && is_struct(_raw.find_bag) && variable_struct_exists(_raw.find_bag, "left") && is_array(_raw.find_bag.left)) {
        var fb_left = [];
        for (var fb = 0; fb < array_length(_raw.find_bag.left); fb++) array_push(fb_left, bool(_raw.find_bag.left[fb]));
        run.find_bag = { p: variable_struct_exists(_raw.find_bag, "p") ? Save_ToReal(_raw.find_bag.p, 0) : 0, left: fb_left };
    }
    if (variable_struct_exists(_raw, "started_at")) run.started_at = Save_ToReal(_raw.started_at, run.started_at);
    gs.run = run;
    return info;
}

// ============================================================================================================
// D175 (saves1): profiles and save files. The data layer only; the title/menu UI comes next.
//   Up to 4 named profiles (ids 0..3). A profile owns profile_<id>.sav (Codex, run history, bestiary, story seen, unlocks, skill memory, echo pool)
//   and 3 save files run_<id>_<slot>.sav (a run in progress each). Settings stay global (settings_config.json).
//   profiles.sav is the index: { index_version: 1, active, profiles: [ { id, name, created, last_slot, last_played } ] }.
//   Profile_Path() / RunSave_Path() answer for the active profile and its active save file, so every older call site keeps working.
// ============================================================================================================

// ---- run save: summary block (what Slots_Summary lists) and the in-memory migration of a version 2 file ----

// The summary of a run file as { class_id, level, floor, run_time_ms, seed, saved_at }; a field the file does not have is -1 (missing).
// Reads the file's own summary block when it has one, else works the same values out from the fields every version has.
function RunSave_SummaryOf(_raw) {
    var out = { class_id: -1, level: -1, floor: -1, run_time_ms: -1, seed: -1, saved_at: -1 };
    if (!is_struct(_raw)) return out;
    var st = (variable_struct_exists(_raw, "statData") && is_struct(_raw.statData)) ? _raw.statData : {};
    var pl = (variable_struct_exists(st, "player") && is_struct(st.player)) ? st.player : {};
    if (variable_struct_exists(pl, "class_id")) out.class_id = Save_ToReal(pl.class_id, -1);
    else if (variable_struct_exists(st, "selected_class")) out.class_id = Save_ToReal(st.selected_class, -1);
    if (variable_struct_exists(pl, "level")) out.level = Save_ToReal(pl.level, -1);
    if (variable_struct_exists(_raw, "floor")) out.floor = Save_ToReal(_raw.floor, -1);
    if (variable_struct_exists(_raw, "stats") && is_struct(_raw.stats) && variable_struct_exists(_raw.stats, "play_ms")) out.run_time_ms = Save_ToReal(_raw.stats.play_ms, -1);
    if (variable_struct_exists(_raw, "seed")) out.seed = Save_ToReal(_raw.seed, -1);
    if (variable_struct_exists(st, "saved_at")) out.saved_at = Save_ToReal(st.saved_at, -1);
    if (variable_struct_exists(_raw, "summary") && is_struct(_raw.summary)) {
        var keys = variable_struct_get_names(out);
        for (var i = 0; i < array_length(keys); i++) {
            if (variable_struct_exists(_raw.summary, keys[i])) variable_struct_set(out, keys[i], Save_ToReal(variable_struct_get(_raw.summary, keys[i]), -1));
        }
    }
    return out;
}

// A loaded run file brought to the current version in memory: the summary block is filled in (version 2 has none). The file itself is
// rewritten as version 3 by the next autosave; nothing is written here.
function RunSave_Migrate(_raw) {
    if (!is_struct(_raw)) return _raw;
    if (!variable_struct_exists(_raw, "summary") || !is_struct(_raw.summary)) _raw.summary = RunSave_SummaryOf(_raw);
    _raw.run_version = RUN_SAVE_VERSION;
    return _raw;
}

// ---- names ----
// Control characters dropped, spaces trimmed at both ends, cut to PROFILE_NAME_MAX letters. "" when nothing is left.
function Profiles_CleanName(_name) {
    if (!is_string(_name)) return "";
    var s = "";
    for (var i = 1; i <= string_length(_name); i++) {
        var c = string_char_at(_name, i);
        if (ord(c) >= 32) s += c;
    }
    while (string_length(s) > 0 && string_char_at(s, 1) == " ") s = string_delete(s, 1, 1);
    if (string_length(s) > PROFILE_NAME_MAX) s = string_copy(s, 1, PROFILE_NAME_MAX);
    while (string_length(s) > 0 && string_char_at(s, string_length(s)) == " ") s = string_delete(s, string_length(s), 1);
    return s;
}

// "Profile 1" for id 0, "Profile 2" for id 1 ... (the first word follows the language).
function Profiles_DefaultName(_id) {
    return Profiles_CleanName(Loc_T("profile.default_name", "Profile") + " " + string(_id + 1));
}

// ---- the index ----
// true for a usable index: version 1, 1..4 entries, each with a unique id 0..3 and a text name. Fields that are missing or odd (active, last_slot ...) are repaired by Profiles_IndexNormalize.
function Profiles_IndexIsValid(_raw) {
    if (!is_struct(_raw)) return false;
    if (!variable_struct_exists(_raw, "index_version") || Save_ToReal(_raw.index_version, -1) != PROFILES_INDEX_VERSION) return false;
    if (!variable_struct_exists(_raw, "profiles") || !is_array(_raw.profiles)) return false;
    var n = array_length(_raw.profiles);
    if (n < 1 || n > PROFILES_MAX) return false;
    var seen = [false, false, false, false];
    for (var i = 0; i < n; i++) {
        var e = _raw.profiles[i];
        if (!is_struct(e) || !variable_struct_exists(e, "id") || !variable_struct_exists(e, "name") || !is_string(e.name)) return false;
        var pid = Save_ToReal(e.id, -1);
        if (pid < 0 || pid >= PROFILES_MAX || pid != floor(pid) || seen[pid]) return false;
        seen[pid] = true;
    }
    return true;
}

function Profiles_CmpId(_a, _b) {
    return _a.id - _b.id;
}

function Profiles_NewEntry(_id, _name) {
    return { id: _id, name: _name, created: date_current_datetime(), last_slot: 0, last_played: 0 };
}

// A valid raw index as the in-memory index: entries sorted by id, names cleaned, last_slot inside 0..2, active one of the entries.
function Profiles_IndexNormalize(_raw) {
    var entries = [];
    for (var i = 0; i < array_length(_raw.profiles); i++) {
        var e = _raw.profiles[i];
        var pid = floor(Save_ToReal(e.id, 0));
        var name = Profiles_CleanName(e.name);
        if (name == "") name = Profiles_DefaultName(pid);
        array_push(entries, {
            id: pid,
            name: name,
            created: variable_struct_exists(e, "created") ? Save_ToReal(e.created, 0) : 0,
            last_slot: clamp(floor(variable_struct_exists(e, "last_slot") ? Save_ToReal(e.last_slot, 0) : 0), 0, PROFILE_SLOTS - 1),
            last_played: variable_struct_exists(e, "last_played") ? Save_ToReal(e.last_played, 0) : 0
        });
    }
    array_sort(entries, Profiles_CmpId);
    var active = variable_struct_exists(_raw, "active") ? floor(Save_ToReal(_raw.active, -1)) : -1;
    var found = false;
    for (var k = 0; k < array_length(entries); k++) if (entries[k].id == active) found = true;
    if (!found) active = entries[0].id;
    return { index_version: PROFILES_INDEX_VERSION, active: active, profiles: entries };
}

function Profiles_Save() {
    if (!variable_global_exists("profiles_index") || !is_struct(global.profiles_index)) return false;
    return Save_WriteFileAtomic(Profiles_IndexPath(), json_stringify(global.profiles_index), Profiles_IndexIsValid);
}

// A fresh profile file with a name (a default profile otherwise).
function Profiles_WriteFresh(_id, _name) {
    var p = Profile_Default();
    p.name = _name;
    return Profile_SaveTo(Profiles_PathOf(_id), p);
}

// An index rebuilt from the profile_<id>.sav files that exist (index lost or damaged). Names come from the files' name copy; the lowest id is active;
// last_slot is the newest save file. undefined when no profile file exists.
function Profiles_RebuildFromFiles() {
    var entries = [];
    for (var pid = 0; pid < PROFILES_MAX; pid++) {
        var path = Profiles_PathOf(pid);
        if (!file_exists(path) && !file_exists(path + ".bak")) continue;
        var name = "";
        var cur = Save_ReadJsonFile(path, Profile_IsCurrentRaw);
        if (is_struct(cur) && variable_struct_exists(cur, "name") && is_string(cur.name)) name = Profiles_CleanName(cur.name);
        if (name == "") name = Profiles_DefaultName(pid);
        var e = Profiles_NewEntry(pid, name);
        var newest = Slots_NewestExisting(pid);
        e.last_slot = (newest >= 0) ? newest : 0;
        array_push(entries, e);
    }
    if (array_length(entries) == 0) return undefined;
    return { index_version: PROFILES_INDEX_VERSION, active: entries[0].id, profiles: entries };
}

// ---- migration of the single profile.sav / run.sav (before D175) ----
function Profiles_LegacyPaths() {
    var pre = Save_Prefix();
    return [pre + "profile.sav", pre + "profile.sav.bak", pre + "run.sav", pre + "run.sav.bak"];
}

function Profiles_LegacyPresent() {
    var paths = Profiles_LegacyPaths();
    for (var i = 0; i < array_length(paths); i++) if (file_exists(paths[i])) return true;
    return false;
}

// Copies src to dst (a .bak next to it comes along by the caller). false when dst does not hold the same text afterwards. A different file already at dst is moved aside, never overwritten.
function Profiles_CopyFile(_src, _dst) {
    if (!file_exists(_src)) return true;
    var text = Save_ReadTextFile(_src);
    if (file_exists(_dst)) {
        if (is_string(text) && Save_ReadTextFile(_dst) == text) return true;   // an earlier, interrupted migration already copied it
        RunSave_KeepAside(_dst);
        if (file_exists(_dst)) return false;
    }
    file_copy(_src, _dst);   // the answer is not trusted: the copy is checked by reading it back
    return file_exists(_dst) && Save_ReadTextFile(_dst) == text;
}

// Renames a file to <file>.pre-profiles ("-2", "-3" ... when that name is taken). Never deletes.
function Profiles_RetireFile(_path) {
    if (!file_exists(_path)) return;
    var dst = _path + ".pre-profiles";
    var n = 1;
    while (file_exists(dst)) {
        n++;
        dst = _path + ".pre-profiles-" + string(n);
    }
    if (!file_rename(_path, dst)) show_debug_message("[SAVE] could not rename " + _path + " to " + dst + "; it stays where it is");
}

// First launch with no profiles.sav and no profile_<id>.sav: the old profile.sav and run.sav (whichever exist) become profile 0 ("Profile 1") and its save file 1.
// Copies first (run, then profile), writes the index, and only then renames the originals to *.pre-profiles. With nothing at all: a fresh "Profile 1".
function Profiles_MigrateLegacy() {
    var name = Profiles_DefaultName(0);
    var idx = { index_version: PROFILES_INDEX_VERSION, active: 0, profiles: [Profiles_NewEntry(0, name)] };
    var pre = Save_Prefix();
    var have = Profiles_LegacyPresent();
    var copied = true;
    if (have) {
        if (!Profiles_CopyFile(pre + "run.sav", Slots_PathOf(0, 0))) copied = false;
        if (!Profiles_CopyFile(pre + "run.sav.bak", Slots_PathOf(0, 0) + ".bak")) copied = false;
        if (file_exists(pre + "profile.sav") || file_exists(pre + "profile.sav.bak")) {
            if (!Profiles_CopyFile(pre + "profile.sav", Profiles_PathOf(0))) copied = false;
            if (!Profiles_CopyFile(pre + "profile.sav.bak", Profiles_PathOf(0) + ".bak")) copied = false;
        } else {
            Profiles_WriteFresh(0, name);
        }
    } else {
        Profiles_WriteFresh(0, name);
    }
    global.profiles_index = idx;
    if (!have) {
        Profiles_Save();
        return idx;
    }
    if (!copied) {
        // Could not copy everything: do not claim the migration and do not touch the originals; the next launch tries again.
        show_debug_message("[SAVE] profile migration could not copy every file; the old files were left as they are");
        return idx;
    }
    if (Profiles_Save()) {
        var paths = Profiles_LegacyPaths();
        for (var i = 0; i < array_length(paths); i++) Profiles_RetireFile(paths[i]);
    }
    return idx;
}

// Loads profiles.sav (or its .bak). A missing or damaged index is rebuilt: from the profile files if any, else from the old single-file save, else a fresh "Profile 1".
// A damaged index file is copied to profiles.sav.corrupt first.
function Profiles_LoadIndex() {
    var path = Profiles_IndexPath();
    var raw = Save_ReadJsonFile(path, Profiles_IndexIsValid);
    if (is_struct(raw)) return Profiles_IndexNormalize(raw);
    if (file_exists(path)) Save_QuarantineFile(path);
    var idx = Profiles_RebuildFromFiles();
    if (is_struct(idx)) {
        global.profiles_index = idx;
        Profiles_Save();
        return idx;
    }
    return Profiles_MigrateLegacy();   // sets global.profiles_index itself (the copies need the paths)
}

// Makes sure the index is loaded (the first call of a game session, or of a test sandbox). Cheap afterwards.
function Profiles_EnsureInit() {
    if (variable_global_exists("profiles_index") && is_struct(global.profiles_index)) return;
    var idx = Profiles_LoadIndex();
    global.profiles_index = idx;
    global.save_slot_active = 0;
    var e = Profiles_FindEntry(idx.active);
    global.save_slot_active = Profiles_StartSlot(e.id, e.last_slot);
}

// The save file a profile starts on: the Continue target when there is one, else the slot it last used.
function Profiles_StartSlot(_id, _last_slot) {
    var target = Slots_ContinueTarget(_id);
    return (target >= 0) ? target : _last_slot;
}

// The entry (the index's own struct) of a profile id, undefined when there is none.
function Profiles_FindEntry(_id) {
    if (!variable_global_exists("profiles_index") || !is_struct(global.profiles_index)) return undefined;
    var l = global.profiles_index.profiles;
    for (var i = 0; i < array_length(l); i++) if (l[i].id == _id) return l[i];
    return undefined;
}

// ---- profiles API ----
// The profiles as copies of their index entries { id, name, created, last_slot, last_played }, sorted by id.
function Profiles_List() {
    Profiles_EnsureInit();
    var out = [];
    var l = global.profiles_index.profiles;
    for (var i = 0; i < array_length(l); i++) {
        array_push(out, { id: l[i].id, name: l[i].name, created: l[i].created, last_slot: l[i].last_slot, last_played: l[i].last_played });
    }
    return out;
}

// The id of the active profile.
function Profiles_Active() {
    Profiles_EnsureInit();
    return global.profiles_index.active;
}

function Profiles_ActiveName() {
    Profiles_EnsureInit();
    return Profiles_FindEntry(global.profiles_index.active).name;
}

// Makes a profile with a name (trimmed, 1..12 letters, longer is cut) and its own empty profile file. Returns its id (the lowest free one), or -1 when the name is empty or 4 profiles exist.
// It does not switch to it.
function Profiles_Create(_name) {
    Profiles_EnsureInit();
    var name = Profiles_CleanName(_name);
    if (name == "") return -1;
    var l = global.profiles_index.profiles;
    if (array_length(l) >= PROFILES_MAX) return -1;
    var pid = 0;
    while (is_struct(Profiles_FindEntry(pid))) pid++;
    Profiles_PurgeFiles(pid);   // what a profile of that id left behind (an interrupted delete)
    if (!Profiles_WriteFresh(pid, name)) return -1;
    array_push(l, Profiles_NewEntry(pid, name));
    array_sort(l, Profiles_CmpId);
    if (!Profiles_Save()) {
        for (var i = 0; i < array_length(l); i++) if (l[i].id == pid) { array_delete(l, i, 1); break; }
        return -1;
    }
    return pid;
}

// Makes another profile the active one: the current profile is written, the other is loaded into global.profile (global.profile_status is reset by that load), and the save file
// in use becomes the other profile's Continue file. false for an unknown id (nothing changes).
function Profiles_Switch(_id) {
    Profiles_EnsureInit();
    var e = Profiles_FindEntry(_id);
    if (!is_struct(e)) return false;
    if (_id == global.profiles_index.active) return true;
    Profile_Flush();
    var old_active = global.profiles_index.active;
    global.profiles_index.active = _id;
    if (!Profiles_Save()) {
        global.profiles_index.active = old_active;
        return false;
    }
    global.profile = undefined;
    Profile_Get();
    global.save_slot_active = Profiles_StartSlot(_id, e.last_slot);
    return true;
}

// Gives a profile a new name (same rules as Profiles_Create). The index is written, and the profile file's name copy follows. false for an unknown id or an empty name.
function Profiles_Rename(_id, _name) {
    Profiles_EnsureInit();
    var name = Profiles_CleanName(_name);
    var e = Profiles_FindEntry(_id);
    if (name == "" || !is_struct(e)) return false;
    var old = e.name;
    e.name = name;
    if (!Profiles_Save()) {
        e.name = old;
        return false;
    }
    if (_id == global.profiles_index.active) {
        Profile_Flush();
    } else {
        var path = Profiles_PathOf(_id);
        var r = Profile_Load(path);
        if (r.status == "ok") {
            r.profile.name = name;
            Profile_SaveTo(path, r.profile);
        }
    }
    return true;
}

// Removes the files of a profile id: its profile file and its 3 save files. A file this build cannot read (newer, damaged) is moved aside as <name>.kept-<time>.sav instead of deleted (D16).
function Profiles_PurgeFiles(_id) {
    for (var s = 0; s < PROFILE_SLOTS; s++) {
        var rp = Slots_PathOf(_id, s);
        if (RunSave_ExistsAt(rp)) RunSave_DeleteUnlessKept(rp, undefined, true);
    }
    var pp = Profiles_PathOf(_id);
    if (file_exists(pp) || file_exists(pp + ".bak")) {
        if (is_struct(Save_ReadJsonFile(pp, Profile_IsCurrentRaw))) Save_DeleteFileSet(pp);
        else RunSave_KeepAside(pp);
    }
}

// Deletes a profile and its 3 save files (the UI asks first). Deleting the active one makes the lowest remaining id active; deleting the last one makes a fresh "Profile 1".
// The deleted profile is not written first. false for an unknown id.
function Profiles_Delete(_id) {
    Profiles_EnsureInit();
    var idx = global.profiles_index;
    var pos = -1;
    for (var i = 0; i < array_length(idx.profiles); i++) if (idx.profiles[i].id == _id) pos = i;
    if (pos < 0) return false;
    var was_active = (idx.active == _id);
    var old_entries = idx.profiles;
    var old_active = idx.active;
    var rest = [];
    for (var k = 0; k < array_length(old_entries); k++) if (k != pos) array_push(rest, old_entries[k]);
    var fresh = (array_length(rest) == 0);
    if (fresh) array_push(rest, Profiles_NewEntry(0, Profiles_DefaultName(0)));
    idx.profiles = rest;
    if (was_active || fresh) idx.active = rest[0].id;
    if (!Profiles_Save()) {   // the index first: a crash after it leaves orphan files, never an index that names a profile whose files are half gone
        idx.profiles = old_entries;
        idx.active = old_active;
        return false;
    }
    Profiles_PurgeFiles(_id);
    if (fresh) Profiles_WriteFresh(0, rest[0].name);
    if (was_active || fresh) {
        global.profile = undefined;
        Profile_Get();
        global.save_slot_active = Profiles_StartSlot(idx.active, Profiles_FindEntry(idx.active).last_slot);
    }
    return true;
}

// ---- save files (slots) ----
// The save file in use (0..2): set by New Game / Load Game / Continue.
function Slot_Active() {
    Profiles_EnsureInit();
    return clamp(floor(Save_ToReal(global.save_slot_active, 0)), 0, PROFILE_SLOTS - 1);
}

// Uses a save file (0..2) from now on; the active profile remembers it as its last played one. false (nothing changes) for a slot outside 0..2.
function Slot_SetActive(_slot) {
    Profiles_EnsureInit();
    var s = Save_ToReal(_slot, -1);
    if (s < 0 || s >= PROFILE_SLOTS || s != floor(s)) return false;
    global.save_slot_active = s;
    var e = Profiles_FindEntry(global.profiles_index.active);
    e.last_slot = s;
    e.last_played = date_current_datetime();
    Profiles_Save();
    return true;
}

// One save file read without applying it: { slot, exists, status, class_id, level, floor, run_time_ms, seed, saved_at }.
// status: "empty" (no file), "ok", "newer", "old", "corrupt". A field the file does not give (or an unreadable file) is -1.
function Slots_ReadSummary(_slot, _path) {
    var o = { slot: _slot, exists: false, status: "empty", class_id: -1, level: -1, floor: -1, run_time_ms: -1, seed: -1, saved_at: -1 };
    if (!RunSave_ExistsAt(_path)) return o;
    o.exists = true;
    var l = RunSave_LoadFrom(_path);
    o.status = (l.status == "missing") ? "corrupt" : l.status;
    if (o.status == "ok") {
        var sm = RunSave_SummaryOf(l.run);
        o.class_id = sm.class_id;
        o.level = sm.level;
        o.floor = sm.floor;
        o.run_time_ms = sm.run_time_ms;
        o.seed = sm.seed;
        o.saved_at = sm.saved_at;
    }
    return o;
}

// The 3 save files of a profile as Slots_ReadSummary entries; [] for an unknown profile.
function Slots_Summary(_profile_id) {
    Profiles_EnsureInit();
    var out = [];
    if (!is_struct(Profiles_FindEntry(_profile_id))) return out;
    for (var s = 0; s < PROFILE_SLOTS; s++) array_push(out, Slots_ReadSummary(s, Slots_PathOf(_profile_id, s)));
    return out;
}

// The first save file of a profile with no file at all (a damaged file is not empty), -1 when all three are used (or the profile is unknown).
function Slots_FirstEmpty(_profile_id) {
    var l = Slots_Summary(_profile_id);
    for (var i = 0; i < array_length(l); i++) if (!l[i].exists) return l[i].slot;
    return -1;
}

// The existing save file of a profile that was saved last (its summary's saved_at; an unreadable one counts as oldest), -1 when there is none.
function Slots_NewestExisting(_profile_id) {
    var best = -1;
    var best_at = -2;
    for (var s = 0; s < PROFILE_SLOTS; s++) {
        var path = Slots_PathOf(_profile_id, s);
        if (!RunSave_ExistsAt(path)) continue;
        var at = Slots_ReadSummary(s, path).saved_at;
        if (best < 0 || at > best_at) {
            best = s;
            best_at = at;
        }
    }
    return best;
}

// What Continue loads: the profile's last played save file when its file exists, else the newest existing one, else -1 (Continue is off). Defaults to the active profile.
function Slots_ContinueTarget(_profile_id = undefined) {
    Profiles_EnsureInit();
    var pid = is_undefined(_profile_id) ? Profiles_Active() : _profile_id;
    var e = Profiles_FindEntry(pid);
    if (!is_struct(e)) return -1;
    if (RunSave_ExistsAt(Slots_PathOf(pid, e.last_slot))) return e.last_slot;
    return Slots_NewestExisting(pid);
}

// Deletes one save file of a profile (the UI asks first). A run that is there counts as abandoned in that profile's history, as Run_AbandonSaved does when New Game replaces a run.
// A file this build cannot read (newer, damaged) is moved aside, not deleted (D16). true when the slot is empty afterwards and there was something in it.
function Slot_Delete(_profile_id, _slot) {
    Profiles_EnsureInit();
    if (!is_struct(Profiles_FindEntry(_profile_id))) return false;
    var s = Save_ToReal(_slot, -1);
    if (s < 0 || s >= PROFILE_SLOTS || s != floor(s)) return false;
    var path = Slots_PathOf(_profile_id, s);
    if (!RunSave_ExistsAt(path)) return false;
    var l = RunSave_LoadFrom(path);
    if (l.status == "ok") {
        var entry = Run_HistoryEntryFromSave(l.run);
        if (_profile_id == global.profiles_index.active) {
            Profile_RecordRun(Profile_Get(), entry);
            Profile_Flush();
        } else {
            var ppath = Profiles_PathOf(_profile_id);
            var r = Profile_Load(ppath);
            if (r.status == "ok") {
                Profile_RecordRun(r.profile, entry);
                Profile_SaveTo(ppath, r.profile);
            }
        }
    }
    RunSave_DeleteUnlessKept(path, l.status, true);
    return !RunSave_ExistsAt(path);
}
