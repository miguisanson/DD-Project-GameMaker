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
        { item_id:10, weight:30, tier:1, min:1, max:1 }, // HP Lv1
        { item_id:11, weight:25, tier:1, min:1, max:1 }, // MP Lv1
        { item_id:12, weight:18, tier:1, min:1, max:1 }, // Antidote
        { item_id:13, weight:18, tier:1, min:1, max:1 }, // Bandage
        { item_id:1,  weight:10, tier:1, min:1, max:1 }, // Wooden Sword
        { item_id:4,  weight:10, tier:1, min:1, max:1 }, // Wooden Bow
        { item_id:7,  weight:10, tier:1, min:1, max:1 }, // Wooden Staff
        { item_id:20, weight:8,  tier:1, min:1, max:1 }, // Leather Armor
        { item_id:23, weight:8,  tier:1, min:1, max:1 }, // Cloth Robe

        { item_id:14, weight:18, tier:2, min:1, max:1 }, // HP Lv2
        { item_id:17, weight:15, tier:2, min:1, max:1 }, // MP Lv2
        { item_id:2,  weight:8,  tier:2, min:1, max:1 }, // Iron Sword
        { item_id:5,  weight:8,  tier:2, min:1, max:1 }, // Iron Bow
        { item_id:8,  weight:6,  tier:2, min:1, max:1 }, // Ruby Staff
        { item_id:21, weight:6,  tier:2, min:1, max:1 }, // Iron Armor
        { item_id:24, weight:6,  tier:2, min:1, max:1 }, // Silk Robe

        { item_id:15, weight:12, tier:3, min:1, max:1 }, // HP Lv3
        { item_id:18, weight:10, tier:3, min:1, max:1 }, // MP Lv3
        { item_id:3,  weight:5,  tier:3, min:1, max:1 }, // Platinum Sword
        { item_id:6,  weight:5,  tier:3, min:1, max:1 }, // Platinum Bow
        { item_id:9,  weight:4,  tier:3, min:1, max:1 }, // Diamond Staff
        { item_id:22, weight:4,  tier:3, min:1, max:1 }, // Platinum Armor
        { item_id:25, weight:4,  tier:3, min:1, max:1 }  // Mithril Robe
    ];

    var barrel = [
        { item_id:10, weight:30, tier:1, min:1, max:1 },
        { item_id:11, weight:25, tier:1, min:1, max:1 },
        { item_id:12, weight:18, tier:1, min:1, max:1 },
        { item_id:13, weight:18, tier:1, min:1, max:1 },
        { item_id:14, weight:10, tier:2, min:1, max:1 },
        { item_id:17, weight:8,  tier:2, min:1, max:1 },
        { item_id:1,  weight:6,  tier:1, min:1, max:1 },
        { item_id:4,  weight:6,  tier:1, min:1, max:1 }
    ];

    var enemy = [
        { item_id:10, weight:30, tier:1, min:1, max:1 },
        { item_id:11, weight:22, tier:1, min:1, max:1 },
        { item_id:12, weight:12, tier:1, min:1, max:1 },
        { item_id:13, weight:12, tier:1, min:1, max:1 },
        { item_id:14, weight:10, tier:2, min:1, max:1 },
        { item_id:17, weight:8,  tier:2, min:1, max:1 },
        { item_id:2,  weight:4,  tier:2, min:1, max:1 },
        { item_id:5,  weight:4,  tier:2, min:1, max:1 },
        { item_id:3,  weight:2,  tier:3, min:1, max:1 },
        { item_id:6,  weight:2,  tier:3, min:1, max:1 }
    ];

    ds_map_add(global.loot_tables, "chest", chest);
    ds_map_add(global.loot_tables, "barrel", barrel);
    ds_map_add(global.loot_tables, "enemy", enemy);

    // --- configs ---
    ds_map_add(global.loot_configs, "chest_basic",  { table:"chest",  chance:[0.65, 0.8, 0.9], max_items:1 });
    ds_map_add(global.loot_configs, "barrel_basic", { table:"barrel", chance:[0.35, 0.45, 0.55], max_items:1 });
    ds_map_add(global.loot_configs, "enemy_basic",  { table:"enemy",  chance:[0.2, 0.3, 0.4], max_items:1 });

    if (variable_global_exists("state") && is_struct(global.state)) {
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
            var qty = (e2.min == e2.max) ? e2.min : irandom_range(e2.min, e2.max);
            return { item_id: e2.item_id, qty: max(1, qty) };
        }
    }

    return undefined;
}

function Loot_RollContainer(_level, _key) {
    var cfg = Loot_ConfigGet(_key);
    var lvl = clamp(round(_level), 1, 3);
    var chance = cfg.chance[lvl - 1];

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
