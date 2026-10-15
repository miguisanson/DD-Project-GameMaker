Scenario_Step();   // scr_debug: inert without -smoke / -bot / -shots; runs before Input_PreStep so simulated keys are seen this frame
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
    Merchant_EnsureInRoom();   // C3 (D85): the merchant of floors 2, 5 and 8 stands in an existing room

    if (variable_struct_exists(gs, "skip_room_save")) gs.skip_room_save = false;

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

    Notes_SpawnForRoom();   // C5 (D107): the lore notes of this room (by death count)
    Run_AutoSave();   // C1 (D46): the run is saved on every room change; coming back from a fight is one too
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

// C5 (D102): after a death the next run starts at the tunnel entrance with one short wake line.
if (room == rm_floor1 && variable_struct_exists(gs, "pending_wake_line") && gs.pending_wake_line) {
    if (instance_exists(obj_player) && !Transition_IsActive() && gs.ui.mode == UI_NONE && array_length(gs.ui.lines) <= 0) {
        gs.pending_wake_line = false;
        var wake = WakeLine_Pick(Profile_Get().deaths);
        Dialogue_StartLines([Loc_T(wake.key, wake.text)]);
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
            Player_ArmExitIgnore(pl_load);   // D64: Continue / load put the player on an exit tile: it ignores them until they step off it
            gs.load_cooldown = true;   // D141: an enemy standing on the spot (Quit in a fight) does not start the fight again at once: see below
        }
        gs.load_spawn_pending = false;
    }
}

// D141: after Continue the player has a short battle cooldown that starts when the loading fade is over (the fade would eat it): it is kept full until then.
if (variable_struct_exists(gs, "load_cooldown") && gs.load_cooldown) {
    if (room == rm_start || room == rm_battle) {
        gs.load_cooldown = false;
    } else if (instance_exists(obj_player)) {
        var pl_cd = instance_find(obj_player, 0);
        if (Transition_IsActive()) {
            if (variable_instance_exists(pl_cd, "battle_cooldown")) pl_cd.battle_cooldown = max(pl_cd.battle_cooldown, BATTLE_COOLDOWN_FRAMES);
        } else {
            gs.load_cooldown = false;
        }
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

RunStats_Tick(Presentation_StepMs(delta_time));   // G9 (D137): run time, only while the run is active, in front and not paused
Run_AutosaveTick();   // C1 (D46): also every few seconds of a quiet moment, so closing the window loses almost nothing

// apply persistence once on initial room load
if (room != rm_battle && variable_global_exists("room_state_ready") && global.room_state_ready) {
    var gs_apply = GameState_Get();
    var rname = room_get_name(room);
    if (!variable_struct_exists(gs_apply, "persist_applied") || !variable_struct_exists(gs_apply.persist_applied, rname) || variable_struct_get(gs_apply.persist_applied, rname) == false) {
        RoomState_Apply(room);
    }
}
