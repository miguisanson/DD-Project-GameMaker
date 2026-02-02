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

function Save_BuildSnapshot() {
    var gs = GameState_Get();
    var stat = {};
    stat.selected_class = gs.selected_class;
    stat.player = gs.player_ch;
    stat.flags = gs.flags;
    stat.checkpoint = gs.checkpoint;
    stat.defeated = DSList_ToArray(gs.defeated_enemies);
    stat.uid_counter = gs.uid_counter;
    stat.enemy_reset_version = gs.enemy_reset_version;
    stat.save_slot = gs.save_slot;

    var px = 0;
    var py = 0;
    var face = DOWN;
    var room_name = "";
    if (instance_exists(gs.player_inst)) {
        room_name = room_get_name(room);
        px = gs.player_inst.x;
        py = gs.player_inst.y;
        if (variable_instance_exists(gs.player_inst, "face")) face = gs.player_inst.face;
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
    snap.statData = stat;
    snap.levelData = gs.persist;
    return snap;
}

function Save_ApplySnapshot(_snap) {
    var gs = GameState_Init();
    var stat = {};
    if (variable_struct_exists(_snap, "statData")) stat = _snap.statData; else stat = _snap;

    gs.selected_class = stat.selected_class;
    gs.player_ch = stat.player;
    gs.flags = stat.flags;
    gs.checkpoint = stat.checkpoint;
    if (variable_struct_exists(stat, "uid_counter")) gs.uid_counter = stat.uid_counter;

    if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_destroy(gs.defeated_enemies);
    var defeated_arr = variable_struct_exists(stat, "defeated") ? stat.defeated : [];
    gs.defeated_enemies = Array_ToDSList(defeated_arr);

    var levelData = {};
    if (variable_struct_exists(_snap, "levelData")) levelData = _snap.levelData;
    else if (variable_struct_exists(_snap, "persist")) levelData = _snap.persist;
    gs.persist = levelData;
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

    var room_id = asset_get_index(room_name);
    if (room_id == -1) room_id = rm_floor1;

    gs.in_main_menu = false;
    gs.last_room = noone;

    global.statData = stat;
    global.levelData = gs.persist;

    GameState_SyncLegacy();

    gs.skip_room_save = true;
    global.skipRoomSave = true;

    GameState_SetBattleReturn(room_id, px, py, face);
    GameState_SetJustReturned(true);
    room_goto(room_id);
}

function Save_Path(_slot) {
    var idx = _slot;
    if (idx <= 0) idx = 0; else idx = _slot - 1;
    return "savedata" + string(idx) + ".sav";
}

function Save_Write(_slot) {
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

function Save_Read(_slot) {
    var path = Save_Path(_slot);
    if (!file_exists(path)) return false;
    var buf = buffer_load(path);
    var json = buffer_read(buf, buffer_string);
    buffer_delete(buf);

    var snap = json_parse(json);
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
    var path = Save_Path(_slot);
    if (!file_exists(path)) return { exists: false, class_name: "", level: 0, room: "" };

    var buf = buffer_load(path);
    var json = buffer_read(buf, buffer_string);
    buffer_delete(buf);

    var snap = json_parse(json);
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
