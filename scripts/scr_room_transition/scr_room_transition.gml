function RoomTransition_Init() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "transition")) {
        gs.transition = { pending: false, room: noone, spawn_id: "", face: -1 };
    }
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "debug_warns")) gs.ui.debug_warns = [];
}

function RoomTransition_Warn(_msg) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "debug_warns")) gs.ui.debug_warns = [];
    array_push(gs.ui.debug_warns, _msg);
    show_debug_message(_msg);
}

function RoomTransition_FindSpawn(_spawn_id) {
    if (!object_exists(obj_room_spawn)) return noone;
    if (!instance_exists(obj_room_spawn)) return noone;
    var n = instance_number(obj_room_spawn);
    var first = noone;
    for (var i = 0; i < n; i++) {
        var inst = instance_find(obj_room_spawn, i);
        if (first == noone) first = inst;
        if (_spawn_id != "" && inst.spawn_id == _spawn_id) return inst;
    }
    return (_spawn_id == "") ? first : noone;
}

function RoomTransition_Set(_room, _spawn_id, _face) {
    RoomTransition_Init();
    var gs = GameState_Get();
    gs.transition.pending = true;
    gs.transition.room = _room;
    gs.transition.spawn_id = _spawn_id;
    gs.transition.face = _face;
}

function RoomTransition_Clear() {
    RoomTransition_Init();
    var gs = GameState_Get();
    gs.transition.pending = false;
    gs.transition.room = noone;
    gs.transition.spawn_id = "";
    gs.transition.face = -1;
}

function RoomTransition_Apply() {
    RoomTransition_Init();
    var gs = GameState_Get();
    if (!gs.transition.pending) return;
    if (room == rm_battle) return;

    var pl = noone;
    if (instance_exists(obj_player)) pl = instance_find(obj_player, 0);

    var sid = gs.transition.spawn_id;
    var target = RoomTransition_FindSpawn(sid);

    if (pl == noone) {
        if (target != noone) {
            pl = instance_create_layer(target.x, target.y, "Instances", obj_player);
        } else {
            RoomTransition_Warn("[RoomTransition] Missing spawn '" + string(sid) + "' in " + room_get_name(room));
            pl = instance_create_layer(0, 0, "Instances", obj_player);
        }
    }

    if (target != noone) {
        pl.x = target.x;
        pl.y = target.y;
    } else {
        RoomTransition_Warn("[RoomTransition] Missing spawn '" + string(sid) + "' in " + room_get_name(room));
    }

    if (gs.transition.face != -1) {
        pl.face = gs.transition.face;
    } else if (target != noone && variable_instance_exists(target, "spawn_facing") && target.spawn_facing != -1) {
        pl.face = target.spawn_facing;
    }

    if (variable_instance_exists(pl, "moving")) pl.moving = false;
    if (variable_instance_exists(pl, "move_timer")) pl.move_timer = 0;
    if (variable_instance_exists(pl, "move_dir")) pl.move_dir = -1;

    RoomTransition_Clear();
}
