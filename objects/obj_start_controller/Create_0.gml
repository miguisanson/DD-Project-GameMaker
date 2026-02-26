main_index = 0;
main_options = ["New Game", "Load Game", "Settings", "Exit Game"];

class_index = 0;
choices = ["Warrior", "Archer", "Mage"];
choice_ids = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];

settings_index = 0;
settings_volume_step = SETTINGS_VOLUME_STEP;
settings_dirty = false;
intro_dialogue_id = "sys_intro_cutscene";
intro_bg_sprite = intro_scene;

var gs = GameState_Get();
gs.in_main_menu = true;
settings_pending = GameSettings_Copy(GameSettings_Ensure());

if (room == rm_character_class) {
    state = "class";
    class_index = 0;
} else {
    state = "main";
} // main, intro, class, settings
