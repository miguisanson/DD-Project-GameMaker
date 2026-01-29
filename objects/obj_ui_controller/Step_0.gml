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
            spd = spd / max(1, room_speed);
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

if (gs.ui.mode == UI_SHOP) {
    var list = gs.ui.shop_items;
    if (array_length(list) > 0) {
        if (k_down) gs.ui.shop_index = (gs.ui.shop_index + 1) mod array_length(list);
        if (k_up)   gs.ui.shop_index = (gs.ui.shop_index + array_length(list) - 1) mod array_length(list);
    }

    if (k_ok) {
        Shop_Buy(gs.ui.shop_index);
    }
    if (k_back) {
        gs.ui.mode = UI_NONE;
        gs.ui.prompt = "";
    }
    exit;
}
