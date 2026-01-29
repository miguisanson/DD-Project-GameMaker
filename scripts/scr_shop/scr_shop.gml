function ShopDB_Init() {
    if (variable_global_exists("shop_db") && ds_exists(global.shop_db, ds_type_map)) return;
    global.shop_db = ds_map_create();

    global.shop_db[? SHOP_BASIC] = [
        { item_id: 10, price: 8 },
        { item_id: 11, price: 10 },
        { item_id: 12, price: 6 }
    ];

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.shop_db = global.shop_db;
    }
}

function ShopDB_Get(_shop_id) {
    if (ds_exists(global.shop_db, ds_type_map) && ds_map_exists(global.shop_db, _shop_id)) {
        return global.shop_db[? _shop_id];
    }
    return [];
}

function Shop_Open(_shop_id) {
    var gs = GameState_Get();
    gs.ui.mode = UI_SHOP;
    gs.ui.shop_items = ShopDB_Get(_shop_id);
    gs.ui.shop_index = 0;
    gs.ui.prompt = "";
}

function Shop_Buy(_index) {
    var gs = GameState_Get();
    var list = gs.ui.shop_items;
    if (_index < 0 || _index >= array_length(list)) return;

    var entry = list[_index];
    var price = entry.price;
    var p = gs.player_ch;

    if (p.gold < price) {
        gs.ui.prompt = "Not enough gold.";
        return;
    }

    p.gold -= price;
    p.inventory = Inv_Add(p.inventory, entry.item_id, 1);
    gs.player_ch = p;
    gs.ui.prompt = "Purchased.";
    GameState_SyncLegacy();
}
