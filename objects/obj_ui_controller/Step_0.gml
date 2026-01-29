var gs = GameState_Get();

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
