var gs = GameState_Get();

var k_up = keyboard_check_pressed(ord("W"));
var k_down = keyboard_check_pressed(ord("S"));
var k_ok = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter);
var k_back = keyboard_check_pressed(ord("X")) || keyboard_check_pressed(vk_escape);

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
