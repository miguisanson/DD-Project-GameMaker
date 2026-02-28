if (trigger_cooldown > 0) trigger_cooldown -= 1;

DialogueTrigger_UpdateCinematic(id);

if (!trigger_enabled) exit;
if (!pending_trigger) exit;
if (trigger_once && triggered) {
    pending_trigger = false;
    pending_wait_for_settle = false;
    pending_player_id = noone;
    exit;
}
if (trigger_cooldown > 0) exit;
if (UI_IsBlocking()) exit;

if (pending_wait_for_settle && instance_exists(pending_player_id)) {
    var pl = pending_player_id;
    var still_moving = false;
    if (variable_instance_exists(pl, "moving") && pl.moving) still_moving = true;
    if (variable_instance_exists(pl, "move_timer") && pl.move_timer > 0) still_moving = true;
    if (still_moving) exit;
}

var lines = [];
if (is_array(dialogue_lines) && array_length(dialogue_lines) > 0) lines = dialogue_lines;
else lines = DialogueDB_Get(dialogue_id);

if (string(dialogue_speaker) != "") Dialogue_StartWithSpeaker(dialogue_speaker, lines);
else Dialogue_StartLines(lines);
if (is_string(trigger_sfx_on_fire_key) && trigger_sfx_on_fire_key != "") {
    SFX_Play(trigger_sfx_on_fire_key);
}

trigger_fired_once = true;
DialogueTrigger_StartCinematic(id);

pending_trigger = false;
pending_wait_for_settle = false;
pending_player_id = noone;

if (trigger_once) {
    triggered = true;
    if (save_trigger_state) RoomState_SaveInstance(id, ["triggered"], false);
    if (destroy_after_trigger) {
        if (cine_runtime_active || lock_enemy_acquired) {
            destroy_pending_after_cinematic = true;
        } else {
            instance_destroy();
            exit;
        }
    }
}

trigger_cooldown = max(0, trigger_cooldown_frames);
