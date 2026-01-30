var gs = GameState_Get();
var k_up = Input_Pressed("menu_up");
var k_down = Input_Pressed("menu_down");
var k_ok = Input_Pressed("confirm");

if (k_up) choice_index = (choice_index + array_length(choices) - 1) mod array_length(choices);
if (k_down) choice_index = (choice_index + 1) mod array_length(choices);

if (k_ok) {
    var class_id = choice_ids[choice_index];
    GameState_SetSelectedClass(class_id);

    // reset core state for new game
    if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_clear(gs.defeated_enemies);
    gs.room_states = {};
    gs.uid_counter = 1;

    gs.player_ch = CharacterCreate_Player(class_id);
    GameState_SetPlayer(gs.player_ch);

    RoomTransition_Set(rm_floor1, "start", -1);
    room_goto(rm_floor1);
}
