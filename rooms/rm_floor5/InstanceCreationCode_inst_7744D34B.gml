dialogue_id = "first_encounter_mini_boss";

trigger_enabled = true;
trigger_once = true;
trigger_sfx_on_fire_key = "metal_resonance";

// Enemy lock (freeze mode): target by unique cine_id tag so this setup
// is reusable in any room without hardcoding script logic.
lock_enemy_enabled = true;
lock_mode = "freeze";
lock_enemy_object = obj_mini_boss;
lock_enemy_tag = "floor5_intro_mini_boss";
lock_enemy_tag_var = "cine_id";
lock_enemy_search_radius = 96;
lock_enemy_release_on_fire = false;
lock_enemy_prevent_until_trigger = true;

// Cinematic camera focus uses the same target tag.
camera_focus_enabled = true;
camera_focus_object = obj_mini_boss;
camera_focus_tag = "floor5_intro_mini_boss";
camera_focus_tag_var = "cine_id";
camera_focus_search_radius = 96;
camera_focus_duration_in = 0.60;
camera_focus_hold = -1;
camera_focus_duration_out = 0.55;
camera_restore_blend_sec = 0.22;
camera_handoff_use_black = true;
camera_handoff_fade_out_frames = 14;
camera_handoff_fade_in_frames = 16;
camera_ease = "smoothstep";
