var gs = GameState_Get();

if (gs.ui.mode == UI_SAVE) exit;

var k_up = Input_Pressed("menu_up");
var k_down = Input_Pressed("menu_down");
var k_ok = Input_Pressed("confirm");
var k_back = Input_Pressed("cancel");

if (state == "main") {
    if (k_up) main_index = (main_index + array_length(main_options) - 1) mod array_length(main_options);
    if (k_down) main_index = (main_index + 1) mod array_length(main_options);

    if (k_ok) {
        var opt = main_options[main_index];
        if (opt == "New Game") {
            state = "class";
        } else if (opt == "Load Game") {
            SaveMenu_Open("load", "main");
        } else if (opt == "Settings") {
            state = "settings";
        } else if (opt == "Exit Game") {
            game_end();
        }
    }
    return;
}

if (state == "class") {
    var total = array_length(choices) + 1; // +1 for Back
    if (k_up) class_index = (class_index + total - 1) mod total;
    if (k_down) class_index = (class_index + 1) mod total;

    if (k_back) {
        state = "main";
        return;
    }

    if (k_ok) {
        if (class_index == array_length(choices)) {
            state = "main";
            return;
        }
        var class_id = choice_ids[class_index];
        GameState_SetSelectedClass(class_id);

        // reset core state for new game
        if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_clear(gs.defeated_enemies);
        gs.room_states = {};
        gs.persist = {};
        gs.persist_applied = {};
        gs.uid_counter = 1;
        gs.enemy_reset_version = 0;

        gs.player_ch = CharacterCreate_Player(class_id);
        GameState_SetPlayer(gs.player_ch);

        gs.in_main_menu = false;
        RoomTransition_Set(rm_floor1, "start", -1);
        room_goto(rm_floor1);
    }
    return;
}

if (state == "settings") {
    if (k_up || k_down) settings_index = 0;
    if (k_back || k_ok) {
        state = "main";
    }
    return;
}
