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
    if (is_string(_value)) return real(_value);
    if (_value == true) return 1;
    if (_value == false) return 0;
    return _fallback;
}

function Save_SettingsPath() {
    return "settings_config.json";
}

function Save_ReadSettingsConfig() {
    var path = Save_SettingsPath();
    if (!file_exists(path)) return undefined;

    var buf = buffer_load(path);
    var json = buffer_read(buf, buffer_string);
    buffer_delete(buf);

    var raw = json_parse(json);
    if (!is_struct(raw)) return undefined;
    var settings_version = 0;
    if (variable_struct_exists(raw, "settings_version")) settings_version = Save_ToReal(raw.settings_version, 0);

    var out = {};
    if (variable_struct_exists(raw, "vol_ui")) out.audio_ui = raw.vol_ui;
    if (variable_struct_exists(raw, "vol_sfx")) out.audio_sfx = raw.vol_sfx;
    if (variable_struct_exists(raw, "vol_bgm")) out.audio_bgm = raw.vol_bgm;
    if (variable_struct_exists(raw, "display_scale")) out.display_scale = raw.display_scale;
    if (variable_struct_exists(raw, "fit_screen")) out.fit_screen = raw.fit_screen;
    else if (settings_version > 0) out.fit_screen = false;
    if (variable_struct_exists(raw, "language")) out.language = raw.language;

    // Migrate older configs that defaulted to tiny 1x startup scale.
    if (settings_version < 2) {
        var loaded_scale = DISPLAY_SCALE_DEFAULT;
        if (variable_struct_exists(out, "display_scale")) loaded_scale = Save_ToReal(out.display_scale, DISPLAY_SCALE_DEFAULT);
        if (loaded_scale <= 1) out.display_scale = DISPLAY_SCALE_DEFAULT;
    }

    // Migration: disable legacy monitor-fit startup to prevent fullscreen-like launch on fresh/old configs.
    if (settings_version < 6) out.fit_screen = false;

    return GameSettings_Normalize(out);
}

function Save_WriteSettingsConfig(_settings) {
    var s = GameSettings_Normalize(_settings);
    var raw = {
        settings_version: 7,
        vol_ui: s.audio_ui,
        vol_sfx: s.audio_sfx,
        vol_bgm: s.audio_bgm,
        display_scale: s.display_scale,
        fit_screen: s.fit_screen,
        language: s.language
    };

    var json = json_stringify(raw);
    var path = Save_SettingsPath();
    var buf = buffer_create(string_length(json) + 1, buffer_fixed, 1);
    buffer_write(buf, buffer_string, json);
    buffer_save(buf, path);
    buffer_delete(buf);
}

function Save_IsCurrentSnapshot(_snap) {
    if (!is_struct(_snap)) return false;
    if (!variable_struct_exists(_snap, "save_version")) return false;
    var ver = Save_ToReal(_snap.save_version, -1);
    if (ver != SAVE_SNAPSHOT_VERSION) return false;
    if (!variable_struct_exists(_snap, "statData")) return false;
    return is_struct(_snap.statData);
}

function Save_TryLoadSnapshot(_slot, _delete_legacy = true) {
    var path = Save_Path(_slot);
    if (!file_exists(path)) return undefined;

    var snap = undefined;
    var ok = false;

    var buf = buffer_load(path);
    if (buf != -1) {
        var json = buffer_read(buf, buffer_string);
        buffer_delete(buf);
        if (is_string(json) && string_length(json) > 0) {
            var c0 = string_char_at(json, 1);
            if (c0 == "{" || c0 == "[") {
                snap = json_parse(json);
                ok = Save_IsCurrentSnapshot(snap);
            }
        }
    }

    if (!ok) {
        if (_delete_legacy && file_exists(path)) file_delete(path);
        return undefined;
    }
    return snap;
}

function Save_LoadSlotStat(_slot) {
    var snap = Save_TryLoadSnapshot(_slot, true);
    if (!is_struct(snap)) return undefined;
    if (variable_struct_exists(snap, "statData")) return snap.statData;
    return snap;
}

function Save_LoadLatestSettings() {
    var cfg = Save_ReadSettingsConfig();
    if (is_struct(cfg)) return cfg;
    return undefined;
}

function Save_HasSlot(_slot) {
    var info = Save_SlotInfo(_slot);
    return is_struct(info) && variable_struct_exists(info, "exists") && info.exists;
}

function Save_HasAnySlot() {
    for (var i = 1; i <= 3; i++) {
        if (Save_HasSlot(i)) return true;
    }
    return false;
}

function Save_FindLatestSlot() {
    var best_slot = 0;
    var best_stamp = -1;

    for (var slot = 1; slot <= 3; slot++) {
        var stat = Save_LoadSlotStat(slot);
        if (!is_struct(stat)) continue;

        var stamp = slot;
        if (variable_struct_exists(stat, "saved_at")) {
            stamp = Save_ToReal(stat.saved_at, slot);
        }

        if (best_slot == 0 || stamp >= best_stamp) {
            best_slot = slot;
            best_stamp = stamp;
        }
    }

    return best_slot;
}

function Save_IsBossEnemyId(_enemy_id) {
    return (_enemy_id == ENEMY_MINI_BOSS || _enemy_id == ENEMY_FINAL_BOSS);
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

    stat.save_room_name = room_name;
    stat.save_x = px;
    stat.save_y = py;
    stat.save_face = face;

    var snap = {};
    snap.save_version = SAVE_SNAPSHOT_VERSION;
    snap.statData = stat;
    snap.levelData = Save_FilterPersistWithoutEnemies(gs.persist);
    return snap;
}

function Save_ApplySnapshot(_snap) {
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

    gs.persist = Save_FilterPersistWithoutEnemies(levelData);
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

    global.statData = stat;
    global.levelData = gs.persist;

    GameState_SyncLegacy();
    GameSettings_ApplyAll();
    Save_WriteSettingsConfig(gs.settings);

    gs.skip_room_save = true;
    global.skipRoomSave = true;

    gs.load_spawn_pending = true;
    gs.load_spawn_room = room_id;
    gs.load_spawn_x = px;
    gs.load_spawn_y = py;
    gs.load_spawn_face = face;

    // Preserve exact saved position when loading from a slot.
    GameState_SetBattleReturn(room_id, px, py, face, false);
    GameState_SetJustReturned(true);
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

function Save_Path(_slot) {
    var idx = _slot;
    if (idx <= 0) idx = 0; else idx = _slot - 1;
    return "savedata" + string(idx) + ".sav";
}

function Save_Write(_slot) {
    // Saving resets regular enemies globally; boss defeat flags remain authoritative.
    Enemy_ResetAll();
    var snap = Save_BuildSnapshot();
    var json = json_stringify(snap);
    var path = Save_Path(_slot);
    var buf = buffer_create(string_length(json) + 1, buffer_fixed, 1);
    buffer_write(buf, buffer_string, json);
    buffer_save(buf, path);
    buffer_delete(buf);
    var gs = GameState_Get();
    gs.save_slot = _slot;
}

function Save_HealPlayerToFull() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;

    var ch = Player_NormalizeProgression(gs.player_ch, true, false);
    ch.hp = ch.max_hp;
    ch.mp = ch.max_mp;

    gs.player_ch = ch;
    GameState_SyncLegacy();

    var pl = gs.player_inst;
    if (!instance_exists(pl) && instance_exists(obj_player)) pl = instance_find(obj_player, 0);
    if (instance_exists(pl) && variable_instance_exists(pl, "character")) {
        pl.character = ch;
    }
}

function Save_Read(_slot) {
    var snap = Save_TryLoadSnapshot(_slot, true);
    if (!is_struct(snap)) return false;
    Save_ApplySnapshot(snap);
    var gs = GameState_Get();
    gs.save_slot = _slot;
    return true;
}

function Save_Delete(_slot) {
    var path = Save_Path(_slot);
    if (file_exists(path)) file_delete(path);
}

function Save_SlotInfo(_slot) {
    var snap = Save_TryLoadSnapshot(_slot, true);
    if (!is_struct(snap)) return { exists: false, class_name: "", level: 0, room: "" };
    var stat = {};
    if (variable_struct_exists(snap, "statData")) stat = snap.statData; else stat = snap;

    var class_name = "";
    var lvl = 1;
    if (variable_struct_exists(stat, "player") && variable_struct_exists(stat.player, "level")) lvl = stat.player.level;
    if (variable_struct_exists(stat, "selected_class")) {
        var cfg = DB_PlayerClass(stat.selected_class);
        if (is_struct(cfg) && variable_struct_exists(cfg, "name")) class_name = cfg.name;
    }
    var room_name = "";
    if (variable_struct_exists(stat, "save_room_name")) room_name = stat.save_room_name;

    return { exists: true, class_name: class_name, level: lvl, room: room_name };
}
