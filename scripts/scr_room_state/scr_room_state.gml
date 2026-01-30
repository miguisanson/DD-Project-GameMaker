function RoomState_Key(_room) {
    return room_get_name(_room);
}

function RoomState_Init() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "room_states")) {
        gs.room_states = {};
    }
    if (!variable_struct_exists(gs, "room_state_version")) {
        gs.room_state_version = 0;
    }
    global.room_state_ready = true;
}

function RoomState_SnapshotInstance(_inst, _fields) {
    var data = { obj: _inst.object_index, x: _inst.x, y: _inst.y, vars: {} };

    for (var i = 0; i < array_length(_fields); i++) {
        var f = _fields[i];
        if (variable_instance_exists(_inst, f)) {
            variable_struct_set(data.vars, f, variable_instance_get(_inst, f));
        }
    }

    return data;
}

function RoomState_RestoreInstance(_data) {
    var inst = instance_create_layer(_data.x, _data.y, "Instances", _data.obj);
    var names = variable_struct_get_names(_data.vars);
    for (var i = 0; i < array_length(names); i++) {
        var n = names[i];
        variable_instance_set(inst, n, variable_struct_get(_data.vars, n));
    }
    return inst;
}

function RoomState_Save(_room) {
    if (_room == rm_battle) return;

    RoomState_Init();
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "uid_counter")) gs.uid_counter = 1;
    var key = RoomState_Key(_room);

    var state = { version: gs.room_state_version, enemies: [], interactables: [], pickups: [] };

    var enemy_fields = ["enemy_id","enemy_uid","ai_state","forget_time","home_x","home_y","moving","move_dir","move_timer","think_delay","scan_radius","think_rate","forget_delay","leash_mult","wander_chance","move_speed","sprite_index"];
    with (obj_enemy) {
        var snap = RoomState_SnapshotInstance(self, enemy_fields);
        array_push(state.enemies, snap);
    }

    var interact_fields = ["interact_kind","sprite_id","sprite_index","interact_name","dialogue_id","dialogue_id_after","swap_on_interact","swap_sprite","swapped","container_level","loot_table_key","switch_id","npc_id","checkpoint_id","door_room","door_x","door_y"];
    with (obj_interactable) {
        var snap2 = RoomState_SnapshotInstance(self, interact_fields);
        array_push(state.interactables, snap2);
    }

    if (object_exists(obj_item_pickup)) {
        var item_fields = ["item_id","qty","sprite_id","sprite_index"];
        with (obj_item_pickup) {
            var snap3 = RoomState_SnapshotInstance(self, item_fields);
            array_push(state.pickups, snap3);
        }
    }

    variable_struct_set(gs.room_states, key, state);
}

function RoomState_Apply(_room) {
    if (_room == rm_battle) return;

    RoomState_Init();
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "uid_counter")) gs.uid_counter = 1;
    var key = RoomState_Key(_room);
    if (!variable_struct_exists(gs.room_states, key)) return;

    var state = variable_struct_get(gs.room_states, key);
    if (variable_struct_exists(state, "version") && state.version != gs.room_state_version) return;

    with (obj_enemy) instance_destroy();
    with (obj_interactable) instance_destroy();
    if (object_exists(obj_item_pickup)) with (obj_item_pickup) instance_destroy();

    var defeated = noone;
    if (ds_exists(gs.defeated_enemies, ds_type_list)) defeated = gs.defeated_enemies;

    for (var i = 0; i < array_length(state.enemies); i++) {
        var data = state.enemies[i];
        var skip = false;
        if (is_struct(data.vars)) {
            var uid = -1;
            if (variable_struct_exists(data.vars, "enemy_uid")) {
                uid = variable_struct_get(data.vars, "enemy_uid");
            } else {
                uid = gs.uid_counter;
                gs.uid_counter += 1;
                variable_struct_set(data.vars, "enemy_uid", uid);
            }

            if (uid >= gs.uid_counter) gs.uid_counter = uid + 1;
            if (defeated != noone && ds_list_find_index(defeated, uid) != -1) skip = true;
        }
        if (!skip) {
            RoomState_RestoreInstance(data);
        }
    }
    for (var j = 0; j < array_length(state.interactables); j++) {
        RoomState_RestoreInstance(state.interactables[j]);
    }
    for (var k = 0; k < array_length(state.pickups); k++) {
        RoomState_RestoreInstance(state.pickups[k]);
    }
}
