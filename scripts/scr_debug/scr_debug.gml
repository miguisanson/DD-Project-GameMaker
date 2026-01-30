function Debug_Init() {
    if (!variable_global_exists("debug") || !is_struct(global.debug)) {
        global.debug = {};
    }
    if (!variable_struct_exists(global.debug, "enabled")) {
        global.debug.enabled = false;
    }
}

function Debug_Toggle() {
    Debug_Init();
    global.debug.enabled = !global.debug.enabled;
}

function Debug_IsEnabled() {
    Debug_Init();
    return global.debug.enabled;
}

function Debug_GiveAllItems() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    if (!variable_global_exists("item_db") || !is_struct(global.item_db)) ItemDB_Init();

    var ch = gs.player_ch;
    var max_qty = 99;

    var keys = variable_struct_get_names(global.item_db);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var item = variable_struct_get(global.item_db, key);
        if (!is_struct(item) || !variable_struct_exists(item, "id")) continue;
        if (item.id <= 0) continue;

        var qty = 1;
        if (variable_struct_exists(item, "stackable") && item.stackable) {
            qty = max_qty;
            if (variable_struct_exists(item, "max_stack")) qty = min(item.max_stack, max_qty);
        }

        ch.inventory = Inv_Add(ch.inventory, item.id, qty);
    }

    GameState_SetPlayer(ch);
}

function Debug_LevelUp() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    var ch = gs.player_ch;
    var before = ch.level;
    ch.exp += ch.exp_next;
    ch = LevelUp_FromExp(ch);
    if (!variable_struct_exists(ch, "stat_points")) ch.stat_points = 0;
    if (ch.level > before) ch.stat_points += (ch.level - before);
    GameState_SetPlayer(ch);
}

function Debug_Save() {
    Save_Write(0);
    Dialogue_Start("sys_save_ok");
}

function Debug_Load() {
    if (Save_Read(0)) {
        Dialogue_Start("sys_load_ok");
    } else {
        Dialogue_Start("sys_load_missing");
    }
}

function Debug_Update() {
    Debug_Init();
    if (Input_Pressed("debug_toggle")) Debug_Toggle();
    if (!Debug_IsEnabled()) return;
    if (Input_Pressed("debug_levelup")) Debug_LevelUp();
    if (Input_Pressed("debug_all_items")) Debug_GiveAllItems();
    if (Input_Pressed("debug_save")) Debug_Save();
    if (Input_Pressed("debug_load")) Debug_Load();
}
