function RoomTransition_Init() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "transition")) {
        gs.transition = { pending: false, room: noone, spawn_id: "", face: -1 };
    }
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

    if (!instance_exists(obj_player)) return;
    var pl = instance_find(obj_player, 0);
    if (!instance_exists(pl)) return;

    var sid = gs.transition.spawn_id;
    var target = noone;
    if (instance_exists(obj_room_spawn)) {
        var n = instance_number(obj_room_spawn);
        for (var i = 0; i < n; i++) {
            var inst = instance_find(obj_room_spawn, i);
            if (sid != "" && inst.spawn_id == sid) { target = inst; break; }
            if (sid == "" && target == noone) target = inst;
        }
    }

    if (target != noone) {
        pl.x = target.x;
        pl.y = target.y;
        if (gs.transition.face != -1) {
            pl.face = gs.transition.face;
        } else if (variable_instance_exists(target, "spawn_facing") && target.spawn_facing != -1) {
            pl.face = target.spawn_facing;
        }
        if (variable_instance_exists(pl, "moving")) pl.moving = false;
        if (variable_instance_exists(pl, "move_timer")) pl.move_timer = 0;
        if (variable_instance_exists(pl, "move_dir")) pl.move_dir = -1;
    }

    RoomTransition_Clear();
}
