main_index = 0;
main_options = ["New Game", "Load Game", "Settings", "Exit Game"];

class_index = 0;
choices = ["Warrior", "Archer", "Mage"];
choice_ids = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];

settings_index = 0;
settings_col = 2;
settings_volume_step = SETTINGS_VOLUME_STEP;

var gs = GameState_Get();
gs.in_main_menu = true;
GameSettings_Ensure();

state = "main"; // main, class, settings
