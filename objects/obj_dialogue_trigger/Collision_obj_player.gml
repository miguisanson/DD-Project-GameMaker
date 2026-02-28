if (trigger_once && triggered) exit;
if (trigger_cooldown > 0) exit;
if (Transition_IsInputLocked()) exit;
if (pending_trigger) exit;

var gs = GameState_Get();
if (gs.ui.mode != UI_NONE) exit;
if (array_length(gs.ui.lines) > 0) exit;
if (variable_struct_exists(gs.ui, "dialogue_lock") && gs.ui.dialogue_lock > 0) exit;
pending_trigger = true;
pending_player_id = other.id;
pending_wait_for_settle = false;
if (variable_instance_exists(other, "moving") && other.moving) pending_wait_for_settle = true;
if (variable_instance_exists(other, "move_timer") && other.move_timer > 0) pending_wait_for_settle = true;
