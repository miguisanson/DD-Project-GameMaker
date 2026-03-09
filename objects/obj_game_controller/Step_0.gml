Input_PreStep();
Debug_Update();
if (!instance_exists(obj_ui_controller)) {
    instance_create_layer(0, 0, "Instances", obj_ui_controller);
}

var gs = GameState_Get();
if (!variable_struct_exists(gs, "last_room")) gs.last_room = room;

if (gs.last_room != room) {
    gs.last_room = room;
    // Room-exit snapshots are captured at transition/encounter hooks before room_goto.
    if (variable_global_exists("room_state_ready") && global.room_state_ready) {
        RoomState_ClearApplied(room);
        RoomState_Apply(room);
    }
    RoomTransition_Apply();

    if (variable_struct_exists(gs, "skip_room_save")) gs.skip_room_save = false;
    global.skipRoomSave = false;

    // ensure player exists if no transition pending (e.g. initial room / battle return)
    // Cutscene room must never spawn player visuals.
    if (room != rm_start && room != rm_battle && room != rm_cutscene && (!variable_struct_exists(gs, "in_main_menu") || !gs.in_main_menu) && !instance_exists(obj_player)) {
        var sp = RoomTransition_FindSpawn("start");
        if (sp == noone) sp = RoomTransition_FindSpawn("");
        if (sp != noone) {
            instance_create_layer(sp.x, sp.y, "Instances", obj_player);
        } else {
            instance_create_layer(0, 0, "Instances", obj_player);
        }
    }
}

// Safety: keep cutscene room free of stray player instance to avoid one-frame flash.
if (room == rm_cutscene && instance_exists(obj_player)) {
    with (obj_player) instance_destroy();
}

if (room == rm_floor1 && variable_struct_exists(gs, "pending_floor1_intro_dialogue") && gs.pending_floor1_intro_dialogue) {
    if (instance_exists(obj_player) && gs.ui.mode == UI_NONE && array_length(gs.ui.lines) <= 0) {
        gs.pending_floor1_intro_dialogue = false;
        SFX_Play("body_falling_wood");
        Dialogue_Start("sys_floor1_intro");
    }
}

// One-shot load spawn override: ensure slot-load position always beats room default spawn.
if (variable_struct_exists(gs, "load_spawn_pending") && gs.load_spawn_pending) {
    var load_room_ok = (!variable_struct_exists(gs, "load_spawn_room") || room == gs.load_spawn_room);
    if (load_room_ok && instance_exists(obj_player)) {
        var pl_load = instance_find(obj_player, 0);
        if (instance_exists(pl_load)) {
            if (variable_struct_exists(gs, "load_spawn_x")) pl_load.x = gs.load_spawn_x;
            if (variable_struct_exists(gs, "load_spawn_y")) pl_load.y = gs.load_spawn_y;
            if (variable_struct_exists(gs, "load_spawn_face") && gs.load_spawn_face != -1 && variable_instance_exists(pl_load, "face")) {
                pl_load.face = gs.load_spawn_face;
            }
            if (variable_instance_exists(pl_load, "moving")) pl_load.moving = false;
            if (variable_instance_exists(pl_load, "move_timer")) pl_load.move_timer = 0;
            if (variable_instance_exists(pl_load, "move_dir")) pl_load.move_dir = -1;
        }
        gs.load_spawn_pending = false;
    }
}

if (variable_struct_exists(gs, "pending_save_success_popup") && gs.pending_save_success_popup) {
    if (!Transition_IsActive() && gs.ui.mode == UI_NONE) {
        gs.pending_save_success_popup = false;
        SaveMenu_OpenMessage("Game saved.", true);
    }
}

if (room != rm_battle && variable_struct_exists(gs, "pending_post_battle_dialogue_lines") && is_array(gs.pending_post_battle_dialogue_lines) && array_length(gs.pending_post_battle_dialogue_lines) > 0) {
    if (!Transition_IsActive() && instance_exists(obj_player) && gs.ui.mode == UI_NONE && array_length(gs.ui.lines) <= 0) {
        var lines = gs.pending_post_battle_dialogue_lines;
        gs.pending_post_battle_dialogue_lines = [];
        Dialogue_StartLines(lines);
    }
}

if (room != rm_battle) {
    EndingExitSequence_Update();
    Dialogue_NarrativeTryStartPending();
}

// apply persistence once on initial room load
if (room != rm_battle && variable_global_exists("room_state_ready") && global.room_state_ready) {
    var gs_apply = GameState_Get();
    var rname = room_get_name(room);
    if (!variable_struct_exists(gs_apply, "persist_applied") || !variable_struct_exists(gs_apply.persist_applied, rname) || variable_struct_get(gs_apply.persist_applied, rname) == false) {
        RoomState_Apply(room);
    }
}
