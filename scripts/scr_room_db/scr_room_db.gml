function RoomDB_Init() {
    if (variable_global_exists("room_db") && is_struct(global.room_db)) return;
    global.room_db = {};

    // Floor 1 <-> 2
    global.room_db.floor1_to_floor2 = { target_room: rm_floor2, target_spawn_id: "spawn_from_floor1", face: -1 };
    global.room_db.floor2_to_floor1 = { target_room: rm_floor1, target_spawn_id: "spawn_from_floor2", face: -1 };

    // Floor 2 <-> 3
    global.room_db.floor2_to_floor3 = { target_room: rm_floor3, target_spawn_id: "spawn_from_floor2", face: -1 };
    global.room_db.floor3_to_floor2 = { target_room: rm_floor2, target_spawn_id: "spawn_from_floor3", face: -1 };

    // Floor 3 <-> 4 (up branch)
    global.room_db.floor3_to_floor4 = { target_room: rm_floor4, target_spawn_id: "spawn_from_floor3", face: -1 };
    global.room_db.floor4_to_floor3 = { target_room: rm_floor3, target_spawn_id: "spawn_from_floor4", face: -1 };

    // Floor 3 <-> 5 (right branch)
    global.room_db.floor3_to_floor5 = { target_room: rm_floor5, target_spawn_id: "spawn_from_floor3", face: -1 };
    global.room_db.floor5_to_floor3 = { target_room: rm_floor3, target_spawn_id: "spawn_from_floor5", face: -1 };

    // Floor 5 <-> 6
    global.room_db.floor5_to_floor6 = { target_room: rm_floor6, target_spawn_id: "spawn_from_floor5", face: -1 };
    global.room_db.floor6_to_floor5 = { target_room: rm_floor5, target_spawn_id: "spawn_from_floor6", face: -1 };

    // Floor 6 <-> 7
    global.room_db.floor6_to_floor7 = { target_room: rm_floor7, target_spawn_id: "spawn_from_floor6", face: -1 };
    global.room_db.floor7_to_floor6 = { target_room: rm_floor6, target_spawn_id: "spawn_from_floor7", face: -1 };

    // Floor 6 <-> 6_5 (middle branch)
    global.room_db.floor6_to_floor6_5 = { target_room: rm_floor6_5, target_spawn_id: "spawn_from_floor6", face: -1 };
    global.room_db.floor6_5_to_floor6 = { target_room: rm_floor6, target_spawn_id: "spawn_from_floor6_5", face: -1 };

    // Floor 7 <-> 8
    global.room_db.floor7_to_floor8 = { target_room: rm_floor8, target_spawn_id: "spawn_from_floor7", face: -1 };
    global.room_db.floor8_to_floor7 = { target_room: rm_floor7, target_spawn_id: "spawn_from_floor8", face: -1 };

    // Floor 8 <-> 9
    global.room_db.floor8_to_floor9 = { target_room: rm_floor9, target_spawn_id: "spawn_from_floor8", face: -1 };
    global.room_db.floor9_to_floor8 = { target_room: rm_floor8, target_spawn_id: "spawn_from_floor9", face: -1 };

    // Floor 9 <-> 9_5
    global.room_db.floor9_to_floor9_5 = { target_room: rm_floor9_5, target_spawn_id: "spawn_from_floor9", face: -1 };
    global.room_db.floor9_5_to_floor9 = { target_room: rm_floor9, target_spawn_id: "spawn_from_floor9_5", face: -1 };
}

function RoomDB_Get(_id) {
    RoomDB_Init();
    if (!variable_struct_exists(global.room_db, _id)) return undefined;
    return variable_struct_get(global.room_db, _id);
}
