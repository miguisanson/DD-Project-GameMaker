function RoomDB_Init() {
    if (variable_global_exists("room_db") && is_struct(global.room_db)) return;
    global.room_db = {};

    // Transition entries (example)
    global.room_db.floor1_to_floor2 = { target_room: rm_floor2, target_spawn_id: "spawn_from_floor1", face: -1 };
    global.room_db.floor2_to_floor1 = { target_room: rm_floor1, target_spawn_id: "spawn_from_floor2", face: -1 };
}

function RoomDB_Get(_id) {
    RoomDB_Init();
    if (!variable_struct_exists(global.room_db, _id)) return undefined;
    return variable_struct_get(global.room_db, _id);
}
