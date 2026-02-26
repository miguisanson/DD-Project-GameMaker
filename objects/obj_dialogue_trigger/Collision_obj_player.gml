if (trigger_once && triggered) exit;
if (trigger_cooldown > 0) exit;
if (Transition_IsInputLocked()) exit;

var gs = GameState_Get();
if (gs.ui.mode != UI_NONE) exit;
if (array_length(gs.ui.lines) > 0) exit;
if (variable_struct_exists(gs.ui, "dialogue_lock") && gs.ui.dialogue_lock > 0) exit;

var lines = [];
if (is_array(dialogue_lines) && array_length(dialogue_lines) > 0) {
    lines = dialogue_lines;
} else {
    lines = DialogueDB_Get(dialogue_id);
}

if (string(dialogue_speaker) != "") {
    Dialogue_StartWithSpeaker(dialogue_speaker, lines);
} else {
    Dialogue_StartLines(lines);
}

if (trigger_once) {
    triggered = true;
    if (save_trigger_state) {
        RoomState_SaveInstance(id, ["triggered"], false);
    }
    if (destroy_after_trigger) {
        instance_destroy();
        exit;
    }
}

trigger_cooldown = max(0, trigger_cooldown_frames);
