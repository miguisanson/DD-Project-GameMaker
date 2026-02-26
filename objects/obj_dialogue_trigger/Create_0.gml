if (!variable_instance_exists(id, "persist_id")) persist_id = "";
RoomState_EnsurePersistId(id);

dialogue_id = "default";
dialogue_lines = [];
dialogue_speaker = "";

trigger_once = true;
triggered = false;
trigger_cooldown_frames = 15;
trigger_cooldown = 0;
destroy_after_trigger = false;
save_trigger_state = true;

visible = false;
