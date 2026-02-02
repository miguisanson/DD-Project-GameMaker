function Loot_Init() {
    if (variable_global_exists("loot_tables") && ds_exists(global.loot_tables, ds_type_map)) return;

    global.loot_tables = ds_map_create();
    global.loot_configs = ds_map_create();
    global.loot_tier_weights = [
        { low:1.0, mid:0.25, high:0.05 },
        { low:0.7, mid:0.6,  high:0.2  },
        { low:0.4, mid:0.7,  high:0.5  }
    ];

    // --- item tables (NO skillbooks) ---
    var chest = [
        { item_id:0,  weight:6,  tier:1, qty_min:0, qty_max:0 }, // Nothing found
        { item_id:10, weight:32, tier:1, qty_min:1, qty_max:3 }, // HP Potion Lv1
        { item_id:11, weight:28, tier:1, qty_min:1, qty_max:3 }, // MP Potion Lv1
        { item_id:12, weight:20, tier:1, qty_min:1, qty_max:2 }, // Antidote
        { item_id:13, weight:20, tier:1, qty_min:1, qty_max:2 }, // Bandage
        { item_id:1,  weight:8,  tier:1, qty_min:0, qty_max:1 }, // Wooden Sword
        { item_id:4,  weight:8,  tier:1, qty_min:0, qty_max:1 }, // Wooden Bow
        { item_id:7,  weight:8,  tier:1, qty_min:0, qty_max:1 }, // Wooden Staff
        { item_id:20, weight:6,  tier:1, qty_min:0, qty_max:1 }, // Leather Armor
        { item_id:23, weight:6,  tier:1, qty_min:0, qty_max:1 }, // Cloth Robe

        { item_id:14, weight:20, tier:2, qty_min:1, qty_max:4 }, // HP Potion Lv2
        { item_id:17, weight:18, tier:2, qty_min:1, qty_max:4 }, // MP Potion Lv2
        { item_id:2,  weight:7,  tier:2, qty_min:0, qty_max:1 }, // Iron Sword
        { item_id:5,  weight:7,  tier:2, qty_min:0, qty_max:1 }, // Iron Bow
        { item_id:8,  weight:6,  tier:2, qty_min:0, qty_max:1 }, // Ruby Staff
        { item_id:21, weight:6,  tier:2, qty_min:0, qty_max:1 }, // Iron Armor
        { item_id:24, weight:6,  tier:2, qty_min:0, qty_max:1 }, // Silk Robe

        { item_id:15, weight:14, tier:3, qty_min:1, qty_max:5 }, // HP Potion Lv3
        { item_id:18, weight:12, tier:3, qty_min:1, qty_max:5 }, // MP Potion Lv3
        { item_id:3,  weight:5,  tier:3, qty_min:0, qty_max:1 }, // Platinum Sword
        { item_id:6,  weight:5,  tier:3, qty_min:0, qty_max:1 }, // Platinum Bow
        { item_id:9,  weight:4,  tier:3, qty_min:0, qty_max:1 }, // Diamond Staff
        { item_id:22, weight:4,  tier:3, qty_min:0, qty_max:1 }, // Platinum Armor
        { item_id:25, weight:4,  tier:3, qty_min:0, qty_max:1 }  // Mithril Robe
    ];

    var barrel = [
        { item_id:0,  weight:24, tier:1, qty_min:0, qty_max:0 }, // Nothing found
        { item_id:10, weight:30, tier:1, qty_min:1, qty_max:2 }, // HP Potion Lv1
        { item_id:11, weight:26, tier:1, qty_min:1, qty_max:2 }, // MP Potion Lv1
        { item_id:12, weight:20, tier:1, qty_min:1, qty_max:2 }, // Antidote
        { item_id:13, weight:20, tier:1, qty_min:1, qty_max:2 }, // Bandage
        { item_id:14, weight:12, tier:2, qty_min:1, qty_max:3 }, // HP Potion Lv2
        { item_id:17, weight:10, tier:2, qty_min:1, qty_max:3 }, // MP Potion Lv2
        { item_id:1,  weight:6,  tier:1, qty_min:0, qty_max:1 }, // Wooden Sword
        { item_id:4,  weight:6,  tier:1, qty_min:0, qty_max:1 }  // Wooden Bow
    ];

    var enemy = [
        { item_id:10, weight:30, tier:1, qty_min:1, qty_max:2 }, // HP Potion Lv1
        { item_id:11, weight:22, tier:1, qty_min:1, qty_max:2 }, // MP Potion Lv1
        { item_id:12, weight:12, tier:1, qty_min:1, qty_max:1 }, // Antidote
        { item_id:13, weight:12, tier:1, qty_min:1, qty_max:1 }, // Bandage
        { item_id:14, weight:10, tier:2, qty_min:1, qty_max:2 }, // HP Potion Lv2
        { item_id:17, weight:8,  tier:2, qty_min:1, qty_max:2 }, // MP Potion Lv2
        { item_id:2,  weight:4,  tier:2, qty_min:0, qty_max:1 }, // Iron Sword
        { item_id:5,  weight:4,  tier:2, qty_min:0, qty_max:1 }, // Iron Bow
        { item_id:3,  weight:2,  tier:3, qty_min:0, qty_max:1 }, // Platinum Sword
        { item_id:6,  weight:2,  tier:3, qty_min:0, qty_max:1 }  // Platinum Bow
    ];

    ds_map_add(global.loot_tables, "chest", chest);
    ds_map_add(global.loot_tables, "barrel", barrel);
    ds_map_add(global.loot_tables, "enemy", enemy);

    // --- configs ---
    // Containers always yield 1 item by default (chest/barrel should always have loot)
    ds_map_add(global.loot_configs, "chest_basic",  { table:"chest",  chance:[1, 1, 1], max_items:1 });
    ds_map_add(global.loot_configs, "barrel_basic", { table:"barrel", chance:[1, 1, 1], max_items:1 });
    ds_map_add(global.loot_configs, "enemy_basic",  { table:"enemy",  chance:[0.2, 0.3, 0.4], max_items:1 });
    ds_map_add(global.loot_configs, "skillbook",  { table:"skillbook", chance:[1, 1, 1], max_items:1, mode:"skillbook" });

    Loot_BuildSkillbookLists();

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.skillbook_by_class = global.skillbook_by_class;

        global.state.loot_tables = global.loot_tables;
        global.state.loot_configs = global.loot_configs;
        global.state.loot_tier_weights = global.loot_tier_weights;
    }
}

function Loot_TableGet(_key) {
    if (!variable_global_exists("loot_tables") || !ds_exists(global.loot_tables, ds_type_map)) Loot_Init();
    if (ds_map_exists(global.loot_tables, _key)) return global.loot_tables[? _key];
    return [];
}

function Loot_ConfigGet(_key) {
    if (!variable_global_exists("loot_configs") || !ds_exists(global.loot_configs, ds_type_map)) Loot_Init();
    if (ds_map_exists(global.loot_configs, _key)) return global.loot_configs[? _key];
    return { table:"chest", chance:[0.5, 0.6, 0.7], max_items:1 };
}

function Loot_BuildSkillbookLists() {
    if (!variable_global_exists("item_db") || !ds_exists(global.item_db, ds_type_map)) ItemDB_Init();
    if (!variable_global_exists("skill_db") || !ds_exists(global.skill_db, ds_type_map)) SkillDB_Init();

    if (variable_global_exists("skillbook_by_class") && ds_exists(global.skillbook_by_class, ds_type_map)) {
        ds_map_destroy(global.skillbook_by_class);
    }
    global.skillbook_by_class = ds_map_create();

    var classes = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];
    for (var c = 0; c < array_length(classes); c++) {
        global.skillbook_by_class[? classes[c]] = [];
    }

    var key = ds_map_find_first(global.item_db);
    while (key != undefined) {
        var item = global.item_db[? key];
        if (is_struct(item) && variable_struct_exists(item, "use") && variable_struct_exists(item.use, "effect") && item.use.effect == "learn_skill") {
            var skill = SkillDB_Get(item.use.skill_id);
            if (!is_struct(skill) || !variable_struct_exists(skill, "class_list")) {
                for (var c2 = 0; c2 < array_length(classes); c2++) {
                    var arr = global.skillbook_by_class[? classes[c2]];
                    array_push(arr, item.id);
                    global.skillbook_by_class[? classes[c2]] = arr;
                }
            } else {
                var cl = skill.class_list;
                if (!is_array(cl) || array_length(cl) == 0) {
                    for (var c3 = 0; c3 < array_length(classes); c3++) {
                        var arr2 = global.skillbook_by_class[? classes[c3]];
                        array_push(arr2, item.id);
                        global.skillbook_by_class[? classes[c3]] = arr2;
                    }
                } else {
                    for (var j = 0; j < array_length(cl); j++) {
                        var cls = cl[j];
                        if (ds_map_exists(global.skillbook_by_class, cls)) {
                            var arr3 = global.skillbook_by_class[? cls];
                            array_push(arr3, item.id);
                            global.skillbook_by_class[? cls] = arr3;
                        }
                    }
                }
            }
        }
        key = ds_map_find_next(global.item_db, key);
    }
}

function Loot_SkillbookList(_class_id) {
    if (!variable_global_exists("skillbook_by_class") || !ds_exists(global.skillbook_by_class, ds_type_map)) Loot_BuildSkillbookLists();
    if (ds_map_exists(global.skillbook_by_class, _class_id)) return global.skillbook_by_class[? _class_id];
    return [];
}

function Loot_RollSkillbook(_class_id) {
    var list = Loot_SkillbookList(_class_id);
    if (!is_array(list) || array_length(list) <= 0) return undefined;
    var idx = irandom(array_length(list) - 1);
    return { item_id: list[idx], qty: 1 };
}

function Loot_TierMult(_level, _tier) {
    var lvl = clamp(_level, 1, 3);
    var tw = global.loot_tier_weights[lvl - 1];
    switch (_tier) {
        case 1: return tw.low;
        case 2: return tw.mid;
        case 3: return tw.high;
    }
    return 1;
}

function Loot_RollFromTable(_table_key, _level) {
    var entries = Loot_TableGet(_table_key);
    var total = 0;
    for (var i = 0; i < array_length(entries); i++) {
        var e = entries[i];
        total += e.weight * Loot_TierMult(_level, e.tier);
    }
    if (total <= 0) return undefined;

    var r = random(total);
    var acc = 0;
    for (var j = 0; j < array_length(entries); j++) {
        var e2 = entries[j];
        acc += e2.weight * Loot_TierMult(_level, e2.tier);
        if (r <= acc) {
            var minv = 1;
            var maxv = 1;
            if (variable_struct_exists(e2, "qty_min")) minv = e2.qty_min; else if (variable_struct_exists(e2, "min_qty")) minv = e2.min_qty; else if (variable_struct_exists(e2, "min")) minv = e2.min;
            if (variable_struct_exists(e2, "qty_max")) maxv = e2.qty_max; else if (variable_struct_exists(e2, "max_qty")) maxv = e2.max_qty; else if (variable_struct_exists(e2, "max")) maxv = e2.max;
            if (maxv < minv) maxv = minv;
            var qty = (minv == maxv) ? minv : irandom_range(minv, maxv);
            if (qty <= 0) return undefined;
            if (variable_struct_exists(e2, "item_id") && e2.item_id <= 0) return undefined;
            return { item_id: e2.item_id, qty: qty };
        }
    }

    return undefined;
}

function Loot_RollContainer(_level, _key) {
    var cfg = Loot_ConfigGet(_key);
    var lvl = clamp(round(_level), 1, 3);
    var chance = cfg.chance[lvl - 1];

    if (variable_struct_exists(cfg, "mode") && cfg.mode == "skillbook") {
        var gs = GameState_Get();
        var class_id = gs.selected_class;
        if (is_struct(gs.player_ch) && variable_struct_exists(gs.player_ch, "class_id")) class_id = gs.player_ch.class_id;
        var it_sb = Loot_RollSkillbook(class_id);
        if (is_struct(it_sb)) return [it_sb];
        return [];
    }

    if (random(1) > chance) return [];

    var items = [];
    var count = max(1, cfg.max_items);
    for (var i = 0; i < count; i++) {
        var it = Loot_RollFromTable(cfg.table, lvl);
        if (is_struct(it)) array_push(items, it);
    }

    return items;
}

function Loot_RollEnemy(_enemy_or_id) {
    var lvl = 1;
    var key = "enemy_basic";

    if (is_struct(_enemy_or_id)) {
        if (variable_struct_exists(_enemy_or_id, "level")) lvl = _enemy_or_id.level;
        if (variable_struct_exists(_enemy_or_id, "loot_key")) key = _enemy_or_id.loot_key;
        if (variable_struct_exists(_enemy_or_id, "id")) {
            var cfg = EnemyDB_Get(_enemy_or_id.id);
            if (is_struct(cfg) && variable_struct_exists(cfg, "loot_key")) key = cfg.loot_key;
        }
    } else {
        var cfg2 = EnemyDB_Get(_enemy_or_id);
        if (is_struct(cfg2)) {
            if (variable_struct_exists(cfg2, "level")) lvl = cfg2.level;
            if (variable_struct_exists(cfg2, "loot_key")) key = cfg2.loot_key;
        }
    }

    var cfg = Loot_ConfigGet(key);
    var chance = cfg.chance[clamp(round(lvl), 1, 3) - 1];
    if (random(1) > chance) return [];

    var it = Loot_RollFromTable(cfg.table, lvl);
    if (is_struct(it)) return [it];
    return [];
}

function Loot_Grant(_inv, _loot) {
    if (!is_array(_loot)) return _inv;
    for (var i = 0; i < array_length(_loot); i++) {
        var it = _loot[i];
        if (is_struct(it) && variable_struct_exists(it, "item_id")) {
            var qty = 1;
            if (variable_struct_exists(it, "qty")) qty = it.qty;
            _inv = Inv_Add(_inv, it.item_id, max(1, qty));
        }
    }
    return _inv;
}
