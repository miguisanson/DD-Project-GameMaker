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
// C1: profile + run saves (D16, D36, D46). Two files, each with its own version:
//   profile.sav  what outlives a run: story seen, unlocks, the echo waiting for the next run, run history, counters.
//   run.sav      the run in progress: seed, RNG stream states, player, room state, position. Deleted when the run ends.
// Both go through the SAVE-04 atomic helpers (.tmp -> verify -> .bak). The old slot files (savedata0..3.sav) are never read as
// current, never written and never deleted: they are only recognised, so the title screen can say why they cannot be loaded.
// ============================================================================================================
#macro PROFILE_VERSION 2   // 2 (D148): skills_known, the skill memory. A version 1 file is read and migrated (no skill memory yet).
#macro RUN_SAVE_VERSION 2
#macro PROFILE_HISTORY_MAX 50

function Profile_Path() {
    return "profile.sav";
}

function RunSave_Path() {
    return "run.sav";
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
    // D148: version 2 added the skill memory; a version 1 file has none, so it starts empty (whatever the file holds under that name is not trusted)
    if (Save_ToReal(variable_struct_exists(_raw, "profile_version") ? _raw.profile_version : 0, 0) >= 2 && variable_struct_exists(_raw, "skills_known") && is_struct(_raw.skills_known)) {
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
    }
    return global.profile;
}

function Profile_Flush() {
    return Profile_SaveTo(Profile_Path(), Profile_Get());
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
    if (Save_ToReal(_raw.run_version, -1) != RUN_SAVE_VERSION) return false;
    if (!variable_struct_exists(_raw, "seed") || !variable_struct_exists(_raw, "statData")) return false;
    return is_struct(_raw.statData);
}

// "ok" | "newer" | "old" (no run_version: the old slot format or anything else) | "corrupt"
function RunSave_Check(_raw) {
    if (!is_struct(_raw)) return "corrupt";
    if (!variable_struct_exists(_raw, "run_version")) return "old";
    var ver = Save_ToReal(_raw.run_version, 0);
    if (ver > RUN_SAVE_VERSION) return "newer";
    if (ver < RUN_SAVE_VERSION) return "old";
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

// Returns { status, run }: status as for Profile_Load (ok, missing, newer, old, corrupt); run is the parsed save when ok.
function RunSave_LoadFrom(_path = undefined) {
    var path = is_undefined(_path) ? RunSave_Path() : _path;
    var out = { status: "missing", run: undefined };
    var cur = Save_ReadJsonFile(path, RunSave_IsCurrentRaw);
    if (is_struct(cur)) {
        out.status = "ok";
        out.run = cur;
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
        drop_dry: run.drop_dry,   // R1 (D120), run save v2
        gold_bag: run.gold_bag,   // D126: no version bump; a save without them loads with empty bags
        find_bag: run.find_bag,
        started_at: run.started_at,
        floor: Run_FloorOfRoomName(where.room_name),
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
