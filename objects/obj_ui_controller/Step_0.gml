Input_PreStep();
var gs = GameState_Get();
var game_fps = max(1, game_get_speed(gamespeed_fps));
gs.ui.icon_frame += max(0, UI_DIALOGUE_ARROW_FPS) / game_fps;
if (gs.ui.icon_frame >= 2) gs.ui.icon_frame -= 2;

if (variable_struct_exists(gs.ui, "dialogue_lock") && gs.ui.dialogue_lock > 0) {
    gs.ui.dialogue_lock -= 1;
}
if (variable_struct_exists(gs.ui, "dialogue_require_release") && gs.ui.dialogue_require_release && !Input_Held("interact")) {
    gs.ui.dialogue_require_release = false;
}

var k_ok = Input_UIConfirm();
var k_back = Input_UIBack();
var k_menu = Input_UIPressed("menu");

if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
    Dialogue_TypewriterStep();
    if (k_ok) {
        Dialogue_Advance();
    }
    exit;
}

if (gs.ui.mode == UI_SAVE) {
    SaveMenu_Handle();
    exit;
}

// Pause menu (Esc)
if (k_back) {
    if (gs.ui.mode == UI_PAUSE) {
        PauseMenu_Close();
        exit;
    }
    if (gs.ui.mode == UI_NONE) {
        var pl = gs.player_inst;
        if (instance_exists(pl) && Player_IsSettled(pl)) {
            PauseMenu_Open();
            exit;
        }
    }
}

if (gs.ui.mode == UI_PAUSE) {
    PauseMenu_HandleInput();
    exit;
}

if (k_menu) {
    if (gs.ui.mode == UI_MENU) {
        Menu_Close();
    } else if (gs.ui.mode == UI_NONE) {
        var pl = gs.player_inst;
        if (instance_exists(pl) && Player_IsSettled(pl)) {
            Menu_Open();
        }
    }
}

if (gs.ui.mode == UI_MENU) {
    Menu_HandleInput();
    exit;
}
