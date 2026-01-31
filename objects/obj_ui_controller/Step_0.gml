Input_PreStep();
var gs = GameState_Get();
var icon = -1;
if (variable_struct_exists(gs.ui, "icon_sprite")) icon = gs.ui.icon_sprite;
if (icon == -1) {
    icon = asset_get_index("button_A_icon");
    gs.ui.icon_sprite = icon;
}
if (icon != -1) {
    var frames = sprite_get_number(icon);
    if (frames > 1) {
        var spd = sprite_get_speed(icon);
        if (sprite_get_speed_type(icon) == SPR_SPEED_FPS) {
            var game_fps = game_get_speed(gamespeed_fps);
            if (game_fps <= 0) game_fps = 60;
            spd = spd / game_fps;
        }
        gs.ui.icon_frame += spd;
        if (gs.ui.icon_frame >= frames) gs.ui.icon_frame -= frames;
    } else {
        gs.ui.icon_frame = 0;
    }
}
if (variable_struct_exists(gs.ui, "lock_actions") && gs.ui.lock_actions > 0) gs.ui.lock_actions -= 1;

var k_up = Input_Pressed("menu_up");
var k_down = Input_Pressed("menu_down");
var k_ok = Input_Pressed("confirm");
var k_back = Input_Pressed("cancel");
var k_menu = Input_Pressed("menu");

if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
    if (variable_struct_exists(gs.ui, "just_opened") && gs.ui.just_opened) {
        gs.ui.just_opened = false;
        exit;
    }
    if (k_ok) {
        Dialogue_Advance();
    }
    exit;
}

if (gs.ui.mode == UI_SAVE) {
    SaveMenu_Handle();
    exit;
}

if (k_menu) {
    if (gs.ui.mode == UI_MENU) {
        Menu_Close();
    } else {
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

