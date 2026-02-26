main_index = 0;
main_options = ["New Game", "Load Game", "Settings", "Exit Game"];

settings_index = 0;
settings_volume_step = SETTINGS_VOLUME_STEP;
settings_dirty = false;
intro_dialogue_id = "sys_intro_cutscene";
intro_bg_sprite = intro_scene;
ending_dialogue_id = "sys_ending_cutscene";
ending_bg_sprite = ending_scene;
cutscene_id = "";
cutscene_started = false;

var gs = GameState_Get();
settings_pending = GameSettings_Copy(GameSettings_Ensure());
load_available = Save_HasAnySlot();

if (room == rm_start) {
    gs.in_main_menu = true;
    state = "main";
} else if (room == rm_cutscene) {
    state = "cutscene";
} else {
    state = "main";
} // main, cutscene, settings
