Input_PreStep();
var gs = GameState_Get();
Transition_Update();
UI_UpdateModalDimState();

if (!variable_instance_exists(id, "hud_hurt_flash_timer")) hud_hurt_flash_timer = 0;
if (!variable_instance_exists(id, "hud_prev_hp")) hud_prev_hp = -1;
if (!variable_instance_exists(id, "hud_prev_mp")) hud_prev_mp = -1;

var hud_ch = gs.player_ch;
if (room == rm_battle && instance_exists(obj_battle_controller)) {
    var hud_bc = instance_find(obj_battle_controller, 0);
    if (instance_exists(hud_bc) && is_struct(hud_bc.p)) hud_ch = hud_bc.p;
}
if (is_struct(hud_ch)) {
    if (hud_prev_hp >= 0 && hud_ch.hp < hud_prev_hp) hud_hurt_flash_timer = UI_HUD_HURT_FLASH_FRAMES;
    hud_prev_hp = hud_ch.hp;
    hud_prev_mp = hud_ch.mp;
} else {
    hud_prev_hp = -1;
    hud_prev_mp = -1;
}
if (hud_hurt_flash_timer > 0) hud_hurt_flash_timer -= 1;

if (Transition_IsInputLocked()) exit;

if (variable_struct_exists(gs, "pending_class_select_open") && gs.pending_class_select_open) {
    if (!variable_struct_exists(gs, "pending_class_select_block_frame")) gs.pending_class_select_block_frame = UI_OPENED_FRAME_NONE;
    var frame = Input_Frame();
    var block_ok = (gs.pending_class_select_block_frame == UI_OPENED_FRAME_NONE || frame > gs.pending_class_select_block_frame);
    if (block_ok && gs.ui.mode == UI_NONE && array_length(gs.ui.lines) <= 0) {
        if (ClassSelect_Open(true)) {
            gs.pending_class_select_open = false;
            gs.pending_class_select_block_frame = UI_OPENED_FRAME_NONE;
            exit;
        }
    }
}

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
var k_menu = Input_UIPressed("menu");
var k_pause = Input_UIPressed("pause");

if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
    Dialogue_TypewriterStep();
    if (k_ok) {
        Dialogue_Advance();
    }
    exit;
}

if (gs.ui.mode == UI_CLASS_SELECT) {
    ClassSelect_HandleInput();
    exit;
}

if (gs.ui.mode == UI_SAVE) {
    SaveMenu_Handle();
    exit;
}

if (gs.ui.mode == UI_BED) {
    BedMenu_Handle();
    exit;
}

if (SettingsPopup_IsOpen("pause")) {
    PauseMenu_HandleInput();
    exit;
}

// Pause menu (Esc / controller top face button)
if (k_pause) {
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
