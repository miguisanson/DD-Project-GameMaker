Input_PreStep();
Display_Update();   // the display owner's per-frame check (applies only on a real window change); moves to obj_display's Begin Step
var step_ms = Presentation_StepMs(delta_time);   // D108 F2b-2: the banner, the hold-to-skip, the arrow blink and the dialogue lock run on a ms clock
Skip_Tick(step_ms);       // D48: hold-to-skip count (steps only while a cutscene or camera pan claims it)
Banner_Step(step_ms);     // C5 (D106): the boss name banner (about 1 s)
var gs = GameState_Get();
Transition_Update();
if (!variable_global_exists("scn")) Focus_Step(window_has_focus());   // R1b (D122): the window lost focus -> pause, lower the music (scripted runs are never in front: they call Focus_Step themselves)
Rumble_Step(step_ms);   // G8 (D136): controller rumble reads the Perfect freeze, BREAK, HP drops and death; it stops on pause, focus loss and a room change
if (Tutorial_Step()) exit;   // C4 (D45): a tutorial pop-up takes every key until it is dismissed

if (!variable_instance_exists(id, "hud_hurt_flash_ms")) hud_hurt_flash_ms = 0;
if (!variable_instance_exists(id, "hud_prev_hp")) hud_prev_hp = -1;

var hud_ch = gs.player_ch;
if (room == rm_battle && instance_exists(obj_battle_controller)) {
    var hud_bc = instance_find(obj_battle_controller, 0);
    if (instance_exists(hud_bc) && is_struct(hud_bc.p)) hud_ch = hud_bc.p;
}
if (is_struct(hud_ch)) {
    if (hud_prev_hp >= 0 && hud_ch.hp < hud_prev_hp) hud_hurt_flash_ms = max(hud_hurt_flash_ms, UI_HUD_HURT_FLASH_MS);
    hud_prev_hp = hud_ch.hp;
} else {
    hud_prev_hp = -1;
}
if (hud_hurt_flash_ms > 0) hud_hurt_flash_ms = Hud_HurtFlashStep(hud_hurt_flash_ms, step_ms);   // D108 F2b-1: ms, was frames

if (Transition_IsInputLocked()) exit;

// C2: the screens a character owes (class choice, free stat point, card pick, replace a skill) open and run here.
if (CardsUi_Step()) exit;
if (ShopUi_Step()) exit;   // C3 (D85): the merchant's shop

gs.ui.icon_frame = Dialogue_IconStep(gs.ui.icon_frame, step_ms);

if (variable_struct_exists(gs.ui, "dialogue_lock") && gs.ui.dialogue_lock > 0) {
    gs.ui.dialogue_lock = Dialogue_LockStep(gs.ui.dialogue_lock, step_ms);
}
if (variable_struct_exists(gs.ui, "dialogue_require_release") && gs.ui.dialogue_require_release && !Input_Held("interact")) {
    gs.ui.dialogue_require_release = false;
}

var k_ok = Input_UIConfirm();
var k_menu = Input_UIPressed("menu");
var k_pause = Input_UIPressed("pause");

if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
    Dialogue_TypewriterStep();
    if (Dialogue_ChoiceIsOpen()) {
        Dialogue_ChoiceStep();   // D101: the choices above the box answer to the shared menu controls
    } else if (k_ok) {
        Dialogue_Advance();
    }
    exit;
}

if (Notice_IsOpen()) {   // F3a: the notice pop-up (title and in game) takes every key until it is gone
    Notice_Step();
    exit;
}

if (gs.ui.mode == UI_BED) {
    BedMenu_Handle();
    exit;
}

// D140: Esc and Tab (the pad's X, Y and Start) are the same menu, on the map and in a fight. Inside it Tab closes from any depth and Esc is Back (it closes at the root
// of a tab). In a fight Esc is Back in a list, so there the battle controller opens the menu on Esc at the root command menu; Tab opens it anywhere that is safe.
if (gs.ui.mode == UI_MENU) {
    if (k_menu && !Menu_CaptureActive()) Menu_Close();
} else if ((k_menu || (k_pause && room != rm_battle)) && Menu_CanOpen()) {
    Menu_Open();
    exit;   // the key that opened it does not answer it
}

if (gs.ui.mode == UI_MENU) {
    Menu_HandleInput();
    exit;
}
