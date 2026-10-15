if (!variable_instance_exists(id, "persist_id")) persist_id = "";
RoomState_EnsurePersistId(id);

trigger_enabled = true;
dialogue_id = "default";
dialogue_lines = [];
dialogue_speaker = "";
trigger_sfx_on_fire_key = "";

trigger_once = true;
triggered = false;
trigger_cooldown_frames = 15;
trigger_cooldown = 0;
destroy_after_trigger = false;
save_trigger_state = true;
trigger_fired_once = false;
pending_trigger = false;
pending_wait_for_settle = false;
pending_player_id = noone;
destroy_pending_after_cinematic = false;

// Reusable cinematic trigger settings (overridden per-instance in creation code).
lock_enemy_enabled = false;
lock_mode = "freeze";
lock_enemy_target = noone;
lock_enemy_tag = "";
lock_enemy_tag_var = "cine_id";
lock_enemy_object = obj_enemy;
lock_enemy_search_radius = DIALOGUE_TRIGGER_TARGET_SEARCH_RADIUS;
lock_enemy_release_on_fire = false;
lock_enemy_prevent_until_trigger = true;
lock_enemy_runtime_target = noone;
lock_enemy_acquired = false;

camera_focus_enabled = false;
camera_focus_target = noone;
camera_focus_tag = "";
camera_focus_tag_var = "cine_id";
camera_focus_object = obj_enemy;
camera_focus_search_radius = DIALOGUE_TRIGGER_TARGET_SEARCH_RADIUS;
camera_focus_duration_in = DIALOGUE_TRIGGER_CAM_IN_SEC;
camera_focus_hold = DIALOGUE_TRIGGER_CAM_HOLD_SEC;
camera_focus_duration_out = DIALOGUE_TRIGGER_CAM_OUT_SEC;
camera_restore_blend_sec = DIALOGUE_TRIGGER_CAM_RESTORE_SEC;
camera_handoff_use_black = true;
camera_handoff_fade_out_frames = TRANSITION_FLASH_FADE_OUT_FRAMES;
camera_handoff_fade_in_frames = TRANSITION_FLASH_FADE_IN_FRAMES;
camera_ease = DIALOGUE_TRIGGER_EASE_DEFAULT;
camera_suspend_follow = true;
camera_restore_target_object = obj_player;

cine_runtime_active = false;
cine_phase = "";
cine_cam_id = -1;
cine_follow_suspended = false;
cine_step = 0;
cine_frames = 0;
cine_from_x = 0;
cine_from_y = 0;
cine_to_x = 0;
cine_to_y = 0;
cine_hold_frames = 0;
cine_target_inst = noone;
cine_dialogue_started = false;
cine_wait_dialogue_end = false;
cine_input_lock_acquired = false;

visible = false;
