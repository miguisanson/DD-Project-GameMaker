function Debug_Init() {
    if (!variable_global_exists("debug") || !is_struct(global.debug)) {
        global.debug = {};
    }
    if (!variable_struct_exists(global.debug, "enabled")) {
        global.debug.enabled = false;
    }
    if (!variable_struct_exists(global.debug, "last_command")) {
        global.debug.last_command = "";
    }
    if (!variable_struct_exists(global.debug, "last_command_frame")) {
        global.debug.last_command_frame = -1;
    }
    if (!variable_struct_exists(global.debug, "enemy_damage_skill_only")) {
        global.debug.enemy_damage_skill_only = false;
    }
}

function Debug_Record(_label) {
    Debug_Init();
    global.debug.last_command = string(_label);
    global.debug.last_command_frame = Input_Frame();
}

function Debug_Toggle() {
    Debug_Init();
    global.debug.enabled = !global.debug.enabled;
    if (!global.debug.enabled) {
        global.debug.enemy_damage_skill_only = false;
    }
    Debug_Record("Toggle Debug: " + (global.debug.enabled ? "ON" : "OFF"));
}

function Debug_IsEnabled() {
    Debug_Init();
    return global.debug.enabled;
}

function Debug_EnemyForceDamageSkillOnly() {
    Debug_Init();
    return global.debug.enabled && global.debug.enemy_damage_skill_only;
}

function Debug_ToggleEnemyDamageSkillOnly() {
    Debug_Init();
    if (!global.debug.enabled) return;
    global.debug.enemy_damage_skill_only = !global.debug.enemy_damage_skill_only;
    Debug_Record("Enemy Damaging Skills Only: " + (global.debug.enemy_damage_skill_only ? "ON" : "OFF"));
}

function Debug_GiveAllItems() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    if (!variable_global_exists("item_db")) ItemDB_Init();

    var ch = gs.player_ch;
    var max_qty = 99;

    if (ds_exists(global.item_db, ds_type_map)) {
        var keylist = ds_map_keys_to_array(global.item_db);
        var count = array_length(keylist);
        for (var i = 0; i < count; i++) {
            var key = keylist[i];
            var item = ds_map_find_value(global.item_db, key);
            if (!is_struct(item) || !variable_struct_exists(item, "id")) continue;
            if (item.id <= 0) continue;

            var qty = 1;
            if (variable_struct_exists(item, "stackable") && item.stackable) {
                qty = max_qty;
                if (variable_struct_exists(item, "max_stack")) qty = min(item.max_stack, max_qty);
            }

            ch.inventory = Inv_Add(ch.inventory, item.id, qty);
        }
    } else if (is_struct(global.item_db)) {
        var keys = variable_struct_get_names(global.item_db);
        for (var j = 0; j < array_length(keys); j++) {
            var key2 = keys[j];
            var item2 = variable_struct_get(global.item_db, key2);
            if (!is_struct(item2) || !variable_struct_exists(item2, "id")) continue;
            if (item2.id <= 0) continue;

            var qty2 = 1;
            if (variable_struct_exists(item2, "stackable") && item2.stackable) {
                qty2 = max_qty;
                if (variable_struct_exists(item2, "max_stack")) qty2 = min(item2.max_stack, max_qty);
            }

            ch.inventory = Inv_Add(ch.inventory, item2.id, qty2);
        }
    }

    GameState_SetPlayer(ch);
    Debug_Record("Give All Items");
}


function Debug_LevelUp() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    var ch = Player_NormalizeProgression(gs.player_ch, false);

    if (Level_IsAtCap(ch.level)) {
        GameState_SetPlayer(ch);
        Debug_Record("Level Up (at cap)");
        return;
    }

    var exp_needed = max(1, ch.exp_next - ch.exp);
    ch = Player_AddExp(ch, exp_needed);
    GameState_SetPlayer(ch);
    Debug_Record("Level Up -> Lv " + string(ch.level));
}

function Debug_Save() {
    Save_Write(0);
    Dialogue_Start("sys_save_ok");
    Debug_Record("Quick Save");
}

function Debug_Load() {
    if (Save_Read(0)) {
        Dialogue_Start("sys_load_ok");
    } else {
        Dialogue_Start("sys_load_missing");
    }
    Debug_Record("Quick Load");
}

function Debug_KillPlayer() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;

    var ch = gs.player_ch;
    ch.hp = 0;
    GameState_SetPlayer(ch);

    // Mirror in-battle runtime struct too (if present), then invoke the standard death cutscene flow.
    if (room == rm_battle && instance_exists(obj_battle_controller)) {
        var bc = instance_find(obj_battle_controller, 0);
        if (instance_exists(bc) && variable_instance_exists(bc, "p") && is_struct(bc.p)) {
            bc.p.hp = 0;
        }
    }

    if (!Transition_IsActive()) {
        Transition_RequestCutsceneById("game_over");
    }
    Debug_Record("Kill Player");
}

function Debug_Update() {
    Debug_Init();
    if (Input_Pressed("debug_toggle")) Debug_Toggle();
    if (!Debug_IsEnabled()) return;
    if (Input_Pressed("debug_enemy_damage_skill")) Debug_ToggleEnemyDamageSkillOnly();
    if (Input_Pressed("debug_levelup")) Debug_LevelUp();
    if (Input_Pressed("debug_all_items")) Debug_GiveAllItems();
    if (Input_Pressed("debug_save")) Debug_Save();
    if (Input_Pressed("debug_load")) Debug_Load();
    if (Input_Pressed("debug_kill")) Debug_KillPlayer();
}
