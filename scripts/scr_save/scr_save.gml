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
    var snap = {};
    snap.selected_class = gs.selected_class;
    snap.player = gs.player_ch;
    snap.flags = gs.flags;
    snap.checkpoint = gs.checkpoint;
    snap.defeated = DSList_ToArray(gs.defeated_enemies);
    snap.room_states = gs.room_states;

    if (instance_exists(gs.player_inst)) {
        snap.room = room;
        snap.player_x = gs.player_inst.x;
        snap.player_y = gs.player_inst.y;
    } else {
        snap.room = gs.checkpoint.room;
        snap.player_x = gs.checkpoint.x;
        snap.player_y = gs.checkpoint.y;
    }

    return snap;
}

function Save_ApplySnapshot(_snap) {
    var gs = GameState_Init();
    gs.selected_class = _snap.selected_class;
    gs.player_ch = _snap.player;
    gs.flags = _snap.flags;
    gs.checkpoint = _snap.checkpoint;

    if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_destroy(gs.defeated_enemies);
    gs.defeated_enemies = Array_ToDSList(_snap.defeated);
    if (variable_struct_exists(_snap, "room_states")) gs.room_states = _snap.room_states;
    gs.last_room = _snap.room;

    GameState_SyncLegacy();

    GameState_SetBattleReturn(_snap.room, _snap.player_x, _snap.player_y);
    GameState_SetJustReturned(true);
    room_goto(_snap.room);
}

function Save_Path(_slot) {
    return save_directory + "save_slot_" + string(_slot) + ".sav";
}

function Save_Write(_slot) {
    var snap = Save_BuildSnapshot();
    var json = json_stringify(snap);
    var path = Save_Path(_slot);
    var f = file_text_open_write(path);
    file_text_write_string(f, json);
    file_text_close(f);
}

function Save_Read(_slot) {
    var path = Save_Path(_slot);
    if (!file_exists(path)) return false;
    var f = file_text_open_read(path);
    var json = "";
    while (!file_text_eof(f)) {
        json += file_text_read_string(f);
        file_text_readln(f);
    }
    file_text_close(f);

    var snap = json_parse(json);
    Save_ApplySnapshot(snap);
    return true;
}
