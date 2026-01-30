Input_PreStep();
Debug_Update();
if (!instance_exists(obj_ui_controller)) {
    instance_create_layer(0, 0, "Instances", obj_ui_controller);
}

var gs = GameState_Get();
if (!variable_struct_exists(gs, "last_room")) gs.last_room = room;

if (gs.last_room != room) {
    if (room != rm_battle) {
        if (variable_global_exists("room_state_ready") && global.room_state_ready) {
            RoomState_Save(gs.last_room);
        }
    }
    gs.last_room = room;
    if (variable_global_exists("room_state_ready") && global.room_state_ready) {
        RoomState_Apply(room);
    }
    RoomTransition_Apply();
}

