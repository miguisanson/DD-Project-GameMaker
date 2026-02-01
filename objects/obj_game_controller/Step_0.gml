Input_PreStep();
Debug_Update();
if (!instance_exists(obj_ui_controller)) {
    instance_create_layer(0, 0, "Instances", obj_ui_controller);
}

var gs = GameState_Get();
if (!variable_struct_exists(gs, "last_room")) gs.last_room = room;

if (gs.last_room != room) {
    if (room != rm_battle) {
        var skip_save = false;
        if (variable_struct_exists(gs, "skip_room_save") && gs.skip_room_save) skip_save = true;
        if (variable_global_exists("skipRoomSave") && global.skipRoomSave) skip_save = true;
        if (!skip_save) {
            if (variable_global_exists("room_state_ready") && global.room_state_ready) {
                RoomState_Save(gs.last_room);
            }
        }
    }
    gs.last_room = room;
    if (variable_global_exists("room_state_ready") && global.room_state_ready) {
        RoomState_ClearApplied(room);
        RoomState_Apply(room);
    }
    RoomTransition_Apply();

    if (variable_struct_exists(gs, "skip_room_save")) gs.skip_room_save = false;
    global.skipRoomSave = false;

    // ensure player exists if no transition pending (e.g. initial room / battle return)
    if (room != rm_battle && (!variable_struct_exists(gs, "in_main_menu") || !gs.in_main_menu) && !instance_exists(obj_player)) {
        var sp = RoomTransition_FindSpawn("start");
        if (sp == noone) sp = RoomTransition_FindSpawn("");
        if (sp != noone) {
            instance_create_layer(sp.x, sp.y, "Instances", obj_player);
        } else {
            instance_create_layer(0, 0, "Instances", obj_player);
        }
    }
}

// apply persistence once on initial room load
if (room != rm_battle && variable_global_exists("room_state_ready") && global.room_state_ready) {
    var gs_apply = GameState_Get();
    var rname = room_get_name(room);
    if (!variable_struct_exists(gs_apply, "persist_applied") || !variable_struct_exists(gs_apply.persist_applied, rname) || variable_struct_get(gs_apply.persist_applied, rname) == false) {
        RoomState_Apply(room);
    }
}
