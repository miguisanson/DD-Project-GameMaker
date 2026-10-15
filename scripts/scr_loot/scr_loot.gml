function Loot_Init() {
    if (variable_global_exists("loot_tables") && ds_exists(global.loot_tables, ds_type_map)) return;

    global.loot_tables = ds_map_create();
    global.loot_configs = ds_map_create();
    global.loot_tier_weights = [
        { low:1.0, mid:0.25, high:0.05 },
        { low:0.7, mid:0.6,  high:0.2  },
        { low:0.4, mid:0.7,  high:0.5  }
    ];
    // R1 (D117): [low, mid, high] odds of the tier, per table and container level 1..3 (today's effective odds). The tier is rolled first, then an item of it.
    // global.loot_tier_weights is only kept for the old simulator data; nothing in the game rolls with it.
    global.loot_tier_odds = {
        chest:  [[0.87, 0.115, 0.015], [0.65, 0.285, 0.065], [0.43, 0.38, 0.19]],
        barrel: [[0.95, 0.05, 0], [0.85, 0.15, 0], [0.74, 0.26, 0]],
        enemy:  [[0.914, 0.084, 0.002], [0.754, 0.236, 0.010], [0.588, 0.376, 0.036]]
    };

    // --- item tables (NO skillbooks) ---
    var chest = [
        { item_id:10, weight:32, tier:1, qty_min:1, qty_max:3 }, // HP Potion Lv1
        { item_id:11, weight:28, tier:1, qty_min:1, qty_max:3 }, // MP Potion Lv1
        { item_id:12, weight:20, tier:1, qty_min:1, qty_max:2 }, // Antidote
        { item_id:13, weight:20, tier:1, qty_min:1, qty_max:2 }, // Bandage
        { item_id:1,  weight:8,  tier:1, qty_min:1, qty_max:1 }, // Wooden Sword
        { item_id:4,  weight:8,  tier:1, qty_min:1, qty_max:1 }, // Wooden Bow
        { item_id:7,  weight:8,  tier:1, qty_min:1, qty_max:1 }, // Wooden Staff
        { item_id:20, weight:6,  tier:1, qty_min:1, qty_max:1 }, // Leather Armor
        { item_id:23, weight:6,  tier:1, qty_min:1, qty_max:1 }, // Cloth Robe

        { item_id:14, weight:20, tier:2, qty_min:1, qty_max:4 }, // HP Potion Lv2
        { item_id:17, weight:18, tier:2, qty_min:1, qty_max:4 }, // MP Potion Lv2
        { item_id:2,  weight:7,  tier:2, qty_min:1, qty_max:1 }, // Iron Sword
        { item_id:5,  weight:7,  tier:2, qty_min:1, qty_max:1 }, // Iron Bow
        { item_id:8,  weight:6,  tier:2, qty_min:1, qty_max:1 }, // Ruby Staff
        { item_id:21, weight:6,  tier:2, qty_min:1, qty_max:1 }, // Iron Armor
        { item_id:24, weight:6,  tier:2, qty_min:1, qty_max:1 }, // Silk Robe

        { item_id:15, weight:14, tier:3, qty_min:1, qty_max:5 }, // HP Potion Lv3
        { item_id:18, weight:12, tier:3, qty_min:1, qty_max:5 }, // MP Potion Lv3
        { item_id:3,  weight:5,  tier:3, qty_min:1, qty_max:1 }, // Platinum Sword
        { item_id:6,  weight:5,  tier:3, qty_min:1, qty_max:1 }, // Platinum Bow
        { item_id:9,  weight:4,  tier:3, qty_min:1, qty_max:1 }, // Diamond Staff
        { item_id:22, weight:4,  tier:3, qty_min:1, qty_max:1 }, // Platinum Armor
        { item_id:25, weight:4,  tier:3, qty_min:1, qty_max:1 }  // Mithril Robe
    ];

    var barrel = [
        { item_id:0,  weight:24, tier:1, qty_min:0, qty_max:0 }, // Nothing found
        { item_id:10, weight:30, tier:1, qty_min:1, qty_max:2 }, // HP Potion Lv1
        { item_id:11, weight:26, tier:1, qty_min:1, qty_max:2 }, // MP Potion Lv1
        { item_id:12, weight:20, tier:1, qty_min:1, qty_max:2 }, // Antidote
        { item_id:13, weight:20, tier:1, qty_min:1, qty_max:2 }, // Bandage
        { item_id:14, weight:12, tier:2, qty_min:1, qty_max:3 }, // HP Potion Lv2
        { item_id:17, weight:10, tier:2, qty_min:1, qty_max:3 }, // MP Potion Lv2
        { item_id:1,  weight:6,  tier:1, qty_min:1, qty_max:1 }, // Wooden Sword
        { item_id:4,  weight:6,  tier:1, qty_min:1, qty_max:1 }  // Wooden Bow
    ];

    var enemy = [
        { item_id:10, weight:30, tier:1, qty_min:1, qty_max:2 }, // HP Potion Lv1
        { item_id:11, weight:22, tier:1, qty_min:1, qty_max:2 }, // MP Potion Lv1
        { item_id:12, weight:12, tier:1, qty_min:1, qty_max:1 }, // Antidote
        { item_id:13, weight:12, tier:1, qty_min:1, qty_max:1 }, // Bandage
        { item_id:14, weight:10, tier:2, qty_min:1, qty_max:2 }, // HP Potion Lv2
        { item_id:17, weight:8,  tier:2, qty_min:1, qty_max:2 }, // MP Potion Lv2
        { item_id:2,  weight:4,  tier:2, qty_min:1, qty_max:1 }, // Iron Sword
        { item_id:5,  weight:4,  tier:2, qty_min:1, qty_max:1 }, // Iron Bow
        { item_id:3,  weight:2,  tier:3, qty_min:1, qty_max:1 }, // Platinum Sword
        { item_id:6,  weight:2,  tier:3, qty_min:1, qty_max:1 }, // Platinum Bow
        { item_id:33, weight:6,  tier:1, qty_min:1, qty_max:1 }, // C3: Smoke Bomb
        { item_id:30, weight:4,  tier:2, qty_min:1, qty_max:1 }  // C3: Firebomb
    ];

    ds_map_add(global.loot_tables, "chest", chest);
    ds_map_add(global.loot_tables, "barrel", barrel);
    ds_map_add(global.loot_tables, "enemy", enemy);

    // --- configs ---
    // Containers always yield 1 item by default (chest/barrel should always have loot)
    ds_map_add(global.loot_configs, "chest_basic",  { table:"chest",  chance:[1, 1, 1], max_items:1 });
    ds_map_add(global.loot_configs, "barrel_basic", { table:"barrel", chance:[1, 1, 1], max_items:1 });
    ds_map_add(global.loot_configs, "enemy_basic",  { table:"enemy",  chance:[0.2, 0.3, 0.4], max_items:1 });
    ds_map_add(global.loot_configs, "enemy_mid",    { table:"enemy",  chance:[0.3, 0.45, 0.6], max_items:1 });
    ds_map_add(global.loot_configs, "enemy_elite",  { table:"enemy",  chance:[0.55, 0.75, 0.95], max_items:1 });
    ds_map_add(global.loot_configs, "enemy_boss",   { table:"enemy",  chance:[1, 1, 1], max_items:2 });

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
    if (is_string(_key) && string_pos("enemy_", _key) == 1 && ds_map_exists(global.loot_configs, "enemy_basic")) {
        return global.loot_configs[? "enemy_basic"];
    }
    return { table:"chest", chance:[0.5, 0.6, 0.7], max_items:1 };
}

function Loot_PlayerStruct(_player = undefined) {
    if (is_struct(_player)) return _player;
    var gs = GameState_Get();
    if (is_struct(gs.player_ch)) return gs.player_ch;
    return undefined;
}

function Loot_PlayerClassId(_player = undefined) {
    var p = Loot_PlayerStruct(_player);
    if (is_struct(p) && variable_struct_exists(p, "class_id")) return p.class_id;
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "selected_class")) return gs.selected_class;
    return CLASS_NOBODY;
}

function Loot_PlayerOwnsItem(_player, _item_id) {
    if (!is_struct(_player)) return false;
    if (variable_struct_exists(_player, "inventory") && is_array(_player.inventory) && Inv_Has(_player.inventory, _item_id, 1)) {
        return true;
    }

    if (variable_struct_exists(_player, "equip") && is_struct(_player.equip)) {
        var slots = ["weapon", "head", "body", "ring1", "ring2", "accessory"];   // C3: the accessory slot (D92)
        for (var i = 0; i < array_length(slots); i++) {
            var key = slots[i];
            if (!variable_struct_exists(_player.equip, key)) continue;
            if (round(real(variable_struct_get(_player.equip, key))) == _item_id) return true;
        }
    }

    return false;
}

function Loot_ArrayHasItemId(_arr, _item_id) {
    if (!is_array(_arr)) return false;
    for (var i = 0; i < array_length(_arr); i++) {
        if (round(real(_arr[i])) == _item_id) return true;
    }
    return false;
}

function Loot_ItemClassAllowed(_item, _class_id) {
    if (!is_struct(_item)) return false;

    var class_id = round(real(_class_id));
    if (class_id < 0 || class_id == CLASS_NOBODY) return true;

    if (variable_struct_exists(_item, "preferred_class") && _item.preferred_class != -1 && _item.preferred_class != class_id) {
        return false;
    }

    if (variable_struct_exists(_item, "allowed_classes") && is_array(_item.allowed_classes) && array_length(_item.allowed_classes) > 0) {
        var allowed = false;
        for (var i = 0; i < array_length(_item.allowed_classes); i++) {
            if (_item.allowed_classes[i] == class_id) {
                allowed = true;
                break;
            }
        }
        if (!allowed) return false;
    }

    return true;
}

function Loot_ItemEligibleForPlayer(_item_id, _player = undefined, _class_id = -1, _exclude_ids = undefined) {
    var item = ItemDB_Get(_item_id);
    if (!is_struct(item) || item.id == 0) return false;

    var p = Loot_PlayerStruct(_player);
    var class_id = round(real(_class_id));
    if (class_id < 0) class_id = Loot_PlayerClassId(p);

    if (Loot_ArrayHasItemId(_exclude_ids, _item_id)) return false;

    var is_equip = (variable_struct_exists(item, "type") && (item.type == ITEM_WEAPON || item.type == ITEM_ARMOR || item.type == ITEM_ACCESSORY));
    if (is_equip) {
        if (!Loot_ItemClassAllowed(item, class_id)) return false;
        if (Loot_PlayerOwnsItem(p, _item_id)) return false;
    }

    return true;
}

// R1 (D117): [low, mid, high] tier odds of a table at a container level (clamped 1..3). An unknown table is all low.
function Loot_TierOdds(_table_key, _level) {
    if (!variable_global_exists("loot_tier_odds")) Loot_Init();
    var lvl = clamp(round(_level), 1, 3);
    if (variable_struct_exists(global.loot_tier_odds, _table_key)) return variable_struct_get(global.loot_tier_odds, _table_key)[lvl - 1];
    return [1, 0, 0];
}

// R1 (D117): the tier, rarest first: high? else mid (of what is left)? else low. Returns 1, 2 or 3.
function Loot_RollTier(_rng, _odds) {
    var hi = _odds[2];
    var mid = _odds[1];
    if (Rng_Float(_rng) < hi) return 3;
    if (hi < 1 && Rng_Float(_rng) < mid / (1 - hi)) return 2;
    return 1;
}

// _rng / _extra (C3, D33): a chest rolls from its own stream and from the table plus this floor band's extra rows; without them the run's loot stream.
// R1 (D117): the tier is rolled first, then an item of that tier by weight alone; a tier with nothing eligible steps down, then up.
function Loot_RollFromTable(_table_key, _level, _player = undefined, _class_id = -1, _exclude_ids = undefined, _rng = undefined, _extra = undefined) {
    var entries = Loot_TableGet(_table_key);
    if (is_array(_extra) && array_length(_extra) > 0) {
        var joined = [];
        for (var ji = 0; ji < array_length(entries); ji++) array_push(joined, entries[ji]);
        for (var jk = 0; jk < array_length(_extra); jk++) array_push(joined, _extra[jk]);
        entries = joined;
    }
    var player = Loot_PlayerStruct(_player);
    var class_id = round(real(_class_id));
    if (class_id < 0) class_id = Loot_PlayerClassId(player);

    var rng = is_undefined(_rng) ? Run_Stream("loot") : _rng;
    var by_tier = [[], [], []];
    var total = [0, 0, 0];
    for (var i = 0; i < array_length(entries); i++) {
        var e = entries[i];
        if (e.weight <= 0) continue;

        if (variable_struct_exists(e, "item_id")) {
            var iid = round(real(e.item_id));
            if (iid > 0 && !Loot_ItemEligibleForPlayer(iid, player, class_id, _exclude_ids)) continue;
        }

        var ti = clamp(round(e.tier), 1, 3) - 1;
        array_push(by_tier[ti], e);
        total[ti] += e.weight;
    }

    var tier = Loot_RollTier(rng, Loot_TierOdds(_table_key, _level));
    var use = -1;
    for (var d = tier; d >= 1 && use < 0; d--) if (total[d - 1] > 0) use = d - 1;
    for (var u = tier + 1; u <= 3 && use < 0; u++) if (total[u - 1] > 0) use = u - 1;
    if (use < 0) return undefined;

    var r = Rng_Float(rng) * total[use];
    var acc = 0;
    var rows = by_tier[use];
    for (var j = 0; j < array_length(rows); j++) {
        var e2 = rows[j];
        acc += e2.weight;
        if (r <= acc) {
            var minv = 1;
            var maxv = 1;
            if (variable_struct_exists(e2, "qty_min")) minv = e2.qty_min; else if (variable_struct_exists(e2, "min_qty")) minv = e2.min_qty; else if (variable_struct_exists(e2, "min")) minv = e2.min;
            if (variable_struct_exists(e2, "qty_max")) maxv = e2.qty_max; else if (variable_struct_exists(e2, "max_qty")) maxv = e2.max_qty; else if (variable_struct_exists(e2, "max")) maxv = e2.max;
            if (maxv < minv) maxv = minv;
            var qty = (minv == maxv) ? minv : Rng_Range(rng, minv, maxv);
            if (qty <= 0) return undefined;
            if (variable_struct_exists(e2, "item_id") && e2.item_id <= 0) return undefined;
            return { item_id: e2.item_id, qty: qty };
        }
    }

    return undefined;
}

function Loot_RollContainer(_level, _key, _rng = undefined, _extra = undefined, _player_in = undefined) {
    var cfg = Loot_ConfigGet(_key);
    var lvl = clamp(round(_level), 1, 3);
    var chance = cfg.chance[lvl - 1];
    var gs = GameState_Get();
    var player = is_undefined(_player_in) ? Loot_PlayerStruct(gs.player_ch) : _player_in;
    var class_id = Loot_PlayerClassId(player);

    if ((is_undefined(_rng) ? RunRng_Float("loot") : Rng_Float(_rng)) > chance) return [];

    var items = [];
    var count = max(1, cfg.max_items);
    var exclude_ids = [];
    for (var i = 0; i < count; i++) {
        var it = Loot_RollFromTable(cfg.table, lvl, player, class_id, exclude_ids, _rng, _extra);
        if (is_struct(it)) {
            array_push(items, it);

            var item_cfg = ItemDB_Get(it.item_id);
            var unique_drop = is_struct(item_cfg) && (item_cfg.type == ITEM_WEAPON || item_cfg.type == ITEM_ARMOR || item_cfg.type == ITEM_ACCESSORY);
            if (unique_drop && !Loot_ArrayHasItemId(exclude_ids, it.item_id)) {
                array_push(exclude_ids, it.item_id);
            }
        }
    }

    return items;
}

// R1 (D120): +10 points of drop chance for every won fight in a row without an item.
function Loot_EnemyDropChance(_base, _dry) {
    return min(1, _base + LOOT_DRY_STEP * _dry);
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
    var run = Run_Get();
    var counting = is_struct(run) && run.active;
    if (counting) chance = Loot_EnemyDropChance(chance, run.drop_dry);   // R1 (D120)

    var it = undefined;
    if (RunRng_Float("loot") <= chance) {
        var player = Loot_PlayerStruct();
        var class_id = Loot_PlayerClassId(player);
        it = Loot_RollFromTable(cfg.table, lvl, player, class_id, []);
    }
    if (counting) run.drop_dry = is_struct(it) ? 0 : run.drop_dry + 1;
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
            qty = max(1, qty);
            if (Item_IsThrowable(ItemDB_Get(it.item_id))) {   // C3 (D84): the throwable stack cap (5, Nobody 8); what does not fit is left behind
                qty = min(qty, max(0, Throw_Cap(Loot_PlayerStruct()) - Inv_Count(_inv, it.item_id)));
                it.qty = qty;
                if (qty <= 0) continue;
            }
            _inv = Inv_Add(_inv, it.item_id, qty);
        }
    }
    Dialogue_NarrativeOnLootGranted(_loot);
    return _inv;
}

function Loot_BuildMessageEntries(_loot, _prefix = "Loot: ") {
    var out = [];
    if (!is_array(_loot)) return out;
    var prefix = string(_prefix);

    for (var i = 0; i < array_length(_loot); i++) {
        var it = _loot[i];
        if (!is_struct(it) || !variable_struct_exists(it, "item_id")) continue;
        if (variable_struct_exists(it, "qty") && it.qty <= 0) continue;   // C3: a throwable that did not fit the stack
        var qty = variable_struct_exists(it, "qty") ? max(1, round(real(it.qty))) : 1;
        var item = ItemDB_Get(it.item_id);
        if (!is_struct(item)) continue;
        var txt = prefix + string(item.name) + " x" + string(qty);
        array_push(out, {
            text: txt,
            icon_sprite: variable_struct_exists(item, "sprite") ? item.sprite : noone,
            icon_subimg: 0
        });
    }

    return out;
}

// ============================================================================================================
// C3 ECONOMY (D23 D33 D84 D85 D86 D92): gold, prices, the merchant's stock, elites, per-run shuffles. Pure functions first (Test_Suite_Economy),
// the room and battle hooks that call them are in scr_room_state / scr_combat / scr_menu and are marked "C3".
// Numbers are starting values for the simulator (balance proposals go to the owner):
//   gold per fight = (10 + 2 x enemy level) x (1.2 for threat rank 2, x3 for a boss, x2 for an elite), rolled +-25%, then Coin Sense / Lucky Charm
//   price = ceil(item value x 1.5), sell = half; a card is 80 (skill) / 60 (upgrade) / 55 (passive)
// Everything random about a layout (enemies, elites, chest contents, the stock) is derived from the run's seed and a label (research/roguelike-cases.md 4.2),
// so the same seed gives the same run whatever order things happen in; the run's own streams are not used for layout.
// ============================================================================================================
#macro GOLD_BASE 10
#macro GOLD_PER_LEVEL 2
#macro GOLD_RANK2_MULT 1.2
#macro GOLD_BOSS_MULT 3
#macro GOLD_ELITE_MULT 2
#macro GOLD_SPREAD 0.25
#macro SHOP_PRICE_MULT 1.5
#macro SHOP_SELL_FRAC 0.5
#macro ELITE_CHANCE 0.15
#macro LOOT_DRY_STEP 0.1
#macro ELITE_DEF_BONUS 4
#macro ELITE_SPD_BONUS 3
#macro ELITE_ATK_BONUS 4
#macro ELITE_VENOM_STACKS 2
#macro ELITE_REGEN_FRAC 0.10
#macro ELITE_HP_MULT 1.8
#macro THROW_CAP 5
#macro THROW_CAP_NOBODY 8
#macro THROW_NOBODY_MULT 2
#macro THROW_STAT_BASE 12

// ---- gold ----
function Gold_Base(_level, _rank, _is_boss, _elite) {
    var m = 1;
    if (_is_boss) m = GOLD_BOSS_MULT;
    else if (_rank >= 2) m = GOLD_RANK2_MULT;
    if (_elite) m *= GOLD_ELITE_MULT;
    return RoundHalfUp((GOLD_BASE + GOLD_PER_LEVEL * max(1, _level)) * m);
}

function Gold_Range(_base) {
    return { lo: floor(_base * (1 - GOLD_SPREAD) + 0.0000001), hi: ceil(_base * (1 + GOLD_SPREAD) - 0.0000001) };
}

function Gold_Roll(_rng, _base) {
    var r = Gold_Range(_base);
    return Rng_Range(_rng, r.lo, r.hi);
}

// Gold bonus of what is worn (the Lucky Charm); Coin Sense is a card passive (Card_GoldMult).
function Gold_EquipBonus(_ch) {
    var total = 0;
    var worn = Equip_GetEquippedItems(_ch);
    for (var i = 0; i < array_length(worn); i++) {
        if (variable_struct_exists(worn[i], "passive_params") && is_struct(worn[i].passive_params) && variable_struct_exists(worn[i].passive_params, "gold_mult")) total += real(worn[i].passive_params.gold_mult);
    }
    return total;
}

function Gold_Mult(_ch) {
    return Card_GoldMult(_ch) + Gold_EquipBonus(_ch);
}

function Gold_Scale(_amount, _ch) {
    if (_amount <= 0) return 0;
    return max(1, RoundHalfUp(_amount * Gold_Mult(_ch)));
}

// The gold one beaten enemy pays: its level, rank, boss and elite flags, a roll from _rng, then the bonuses of _ch.
function Gold_ForEnemy(_rng, _e, _ch) {
    var lvl = variable_struct_exists(_e, "level") ? _e.level : 1;
    var rank = variable_struct_exists(_e, "threat_rank") ? _e.threat_rank : 1;
    var boss = variable_struct_exists(_e, "is_boss") && _e.is_boss;
    var elite = variable_struct_exists(_e, "is_elite") && _e.is_elite;
    return Gold_Scale(Gold_Roll(_rng, Gold_Base(lvl, rank, boss, elite)), _ch);
}

function Gold_Add(_run, _n) {
    if (!is_struct(_run)) return 0;
    if (_n > 0) _run.gold += _n;
    return _run.gold;
}

function Gold_Spend(_run, _n) {
    if (!is_struct(_run) || _n < 0 || _n > _run.gold) return false;
    _run.gold -= _n;
    return true;
}

function Gold_Get() {
    var run = Run_Get();
    return is_struct(run) ? run.gold : 0;
}

// ---- prices ----
function Shop_Price(_item_id) {
    var it = ItemDB_Get(_item_id);
    if (!is_struct(it) || it.id == 0) return 0;
    return max(1, ceil(it.value * SHOP_PRICE_MULT - 0.000001));
}

function Shop_SellPrice(_item_id) {
    return floor(Shop_Price(_item_id) * SHOP_SELL_FRAC + 0.000001);
}

function Shop_CardPrice(_card_id) {
    var c = CardDB_Get(_card_id);
    if (!is_struct(c)) return 0;
    switch (c.kind) {
        case "skill": return 80;
        case "upgrade": return 60;
        case "passive": return 55;
    }
    return 40;
}

// ---- the stock of one shop (D85): made once per run and shop from the seed ----
function Shop_Row(_kind, _id, _qty) {
    var price = (_kind == "card") ? Shop_CardPrice(_id) : Shop_Price(_id);
    return { kind: _kind, id: _id, qty: _qty, price: price };
}

// Gear value window per shop (shop 0 = after floor 2, 1 = after floor 5, 2 = after floor 8): the loot gets better per floor.
function Shop_GearWindow(_idx) {
    if (_idx <= 0) return { lo: 0, hi: 20 };
    if (_idx == 1) return { lo: 18, hi: 40 };
    return { lo: 34, hi: 70 };
}

// Can this class equip the item (the Equip_CanEquip rule, class part)?
function Shop_ClassOk(_item, _class_id) {
    if (variable_struct_exists(_item, "preferred_class") && _item.preferred_class != -1 && _item.preferred_class != _class_id) return false;
    if (variable_struct_exists(_item, "allowed_classes") && is_array(_item.allowed_classes) && array_length(_item.allowed_classes) > 0) return Card_ArrayHas(_item.allowed_classes, _class_id);
    return true;
}

// In the inventory or worn.
function Shop_Owned(_ch, _item_id) {
    if (!is_struct(_ch)) return false;
    if (variable_struct_exists(_ch, "inventory") && is_array(_ch.inventory) && Inv_Has(_ch.inventory, _item_id, 1)) return true;
    return Loot_PlayerOwnsItem(_ch, _item_id);
}

function Shop_GearPick(_rng, _ch, _type, _idx) {
    var win = Shop_GearWindow(_idx);
    var ids = (_type == ITEM_WEAPON) ? [1,2,3,4,5,6,7,8,9] : [20,21,22,23,24,25];
    var cands = [];
    for (var i = 0; i < array_length(ids); i++) {
        var it = ItemDB_Get(ids[i]);
        if (it.id == 0 || it.type != _type) continue;
        if (it.value < win.lo || it.value > win.hi) continue;
        if (!Shop_ClassOk(it, _ch.class_id) || Shop_Owned(_ch, it.id)) continue;
        array_push(cands, it.id);
    }
    if (array_length(cands) <= 0) return -1;
    return cands[Rng_Int(_rng, array_length(cands))];
}

function Shop_StockGenerate(_seed, _idx, _ch) {
    var rng = Rng_New(_seed, "shop:" + string(_idx));
    var tier = clamp(_idx, 0, 2);
    var rows = [];
    // potions: a heal potion every time (as Slay the Spire's shop), plus one of MP / Antidote / Bandage
    var hp_ids = [10, 14, 15];
    var mp_ids = [11, 17, 18];
    array_push(rows, Shop_Row("item", hp_ids[tier], 3));
    array_push(rows, Shop_Row("item", Rng_Pick(rng, [mp_ids[tier], mp_ids[tier], 12, 13]), 2));
    // throwables: two of the four, more for a character that has no gear to buy
    var thr = Rng_Shuffle(rng, [30, 31, 32, 33]);
    var gear = [];
    var w = Shop_GearPick(rng, _ch, ITEM_WEAPON, _idx);
    if (w > 0) array_push(gear, w);
    var a = Shop_GearPick(rng, _ch, ITEM_ARMOR, _idx);
    if (a > 0) array_push(gear, a);
    var n_thr = 2 + (2 - array_length(gear));
    for (var t = 0; t < n_thr && t < array_length(thr); t++) array_push(rows, Shop_Row("item", thr[t], 2));
    for (var g = 0; g < array_length(gear); g++) array_push(rows, Shop_Row("item", gear[g], 1));
    // one accessory
    var accs = [];
    var acc_pool = (_idx <= 0) ? [40, 41, 42, 43] : ((_idx == 1) ? [40, 41, 42, 43, 44, 45] : [41, 42, 43, 44, 45, 46]);
    for (var i = 0; i < array_length(acc_pool); i++) if (!Shop_Owned(_ch, acc_pool[i])) array_push(accs, acc_pool[i]);
    if (array_length(accs) > 0) array_push(rows, Shop_Row("item", accs[Rng_Int(rng, array_length(accs))], 1));
    // one or two cards the character could take (no skill card while all slots are full: the shop has no swap screen)
    var n_cards = 1 + Rng_Int(rng, 2);
    var lists = Card_EligibleLists(_ch);
    var cands = [];
    if (array_length(_ch.skills) < CARD_MAX_SKILLS) for (var s = 0; s < array_length(lists.skill); s++) array_push(cands, lists.skill[s]);
    for (var u = 0; u < array_length(lists.upgrade); u++) array_push(cands, lists.upgrade[u]);
    for (var pp = 0; pp < array_length(lists.passive); pp++) array_push(cands, lists.passive[pp]);
    cands = Rng_Shuffle(rng, cands);
    for (var c = 0; c < n_cards && c < array_length(cands); c++) array_push(rows, Shop_Row("card", cands[c], 1));
    return rows;
}

// The stock a run keeps for shop _idx: made on the first visit (from the seed and the character then), saved with the run (run.shop), so
// what was bought stays bought and a reload does not restock.
function Shop_RunStock(_run, _idx, _ch) {
    var key = "s" + string(_idx);
    if (!variable_struct_exists(_run.shop, key)) variable_struct_set(_run.shop, key, Shop_StockGenerate(_run.seed, _idx, _ch));
    return variable_struct_get(_run.shop, key);
}

// Buys one of a row. Returns { ok, reason ("gold" | "sold_out" | "full" | "owned" | "slots"), ch (a changed copy), price }. Changes the row's stock and the run's gold.
function Shop_Buy(_ch, _run, _row) {
    var out = { ok: false, reason: "", ch: _ch, price: _row.price };
    if (_row.qty <= 0) { out.reason = "sold_out"; return out; }
    if (_run.gold < _row.price) { out.reason = "gold"; return out; }
    var ch = variable_clone(_ch);
    if (_row.kind == "item") {
        var it = ItemDB_Get(_row.id);
        var unique = (it.type == ITEM_WEAPON || it.type == ITEM_ARMOR || it.type == ITEM_ACCESSORY);
        if (unique && Shop_Owned(ch, _row.id)) { out.reason = "owned"; return out; }
        var add = Inv_AddCapped(ch, _row.id, 1);
        if (add.added < 1) { out.reason = "full"; return out; }
        ch = add.ch;
    } else {
        var c = CardDB_Get(_row.id);
        if (!is_struct(c)) { out.reason = "owned"; return out; }
        if (c.kind == "skill" && array_length(ch.skills) >= CARD_MAX_SKILLS) { out.reason = "slots"; return out; }
        if (!Card_Eligible(ch, c)) { out.reason = "owned"; return out; }
        ch = Card_Take(ch, _row.id).ch;
    }
    Gold_Spend(_run, _row.price);
    _row.qty -= 1;
    out.ok = true;
    out.ch = ch;
    return out;
}

// Sells one item for half its price. Returns { ok, reason ("none" | "equipped" | "key"), ch, gold }.
function Shop_Sell(_ch, _run, _item_id) {
    var out = { ok: false, reason: "", ch: _ch, gold: 0 };
    if (_item_id <= 0 || !Inv_Has(_ch.inventory, _item_id, 1)) { out.reason = "none"; return out; }
    var it = ItemDB_Get(_item_id);
    if (it.type == ITEM_KEY) { out.reason = "key"; return out; }
    if (Menu_IsEquipped(_ch, _item_id) || Loot_PlayerOwnsItem({ equip: _ch.equip, inventory: [] }, _item_id)) { out.reason = "equipped"; return out; }
    var ch = variable_clone(_ch);
    ch.inventory = Inv_Remove(ch.inventory, _item_id, 1);
    out.gold = Shop_SellPrice(_item_id);
    Gold_Add(_run, out.gold);
    out.ok = true;
    out.ch = ch;
    return out;
}

// ---- the merchant's places (D85): existing rooms, on the 16 px grid, off the path to the exit ----
function Merchant_SpotFor(_room) {
    switch (_room) {
        case rm_floor2: return { x: 192, y: 64, shop: 0 };
        case rm_floor5: return { x: 240, y: 64, shop: 1 };
        case rm_floor8: return { x: 128, y: 64, shop: 2 };   // an alcove off the stair (its only free side is the cell below); (16,48) was behind the carved-arrow note
    }
    return undefined;
}

// The merchant's sprite (D113, candidate A: art/merchant/spr_merchant_idle, two idle frames, imported by the owner). Looked up by name (D94).
function Merchant_SpriteName() {
    return "spr_merchant_idle";
}

// The pulse of the gold glow round the merchant (D113): alpha 0.35..1.0, a cosine with a 1.2 s period, brightest at 0 ms. Pure: ms in, alpha out.
function Merchant_GlowAlpha(_ms) {
    var _phase = (_ms mod 1200) / 1200;
    return 0.675 + 0.325 * cos(_phase * 2 * pi);
}

// Puts the merchant of this room (if it has one) in place with an obj_npc (no new resource): called once per room start in a run.
// Until the owner imports spr_merchant_idle it falls back to the Nobody sprite, untinted (D113: no gold tint; the glow carries the highlight).
function Merchant_EnsureInRoom() {
    var spot = Merchant_SpotFor(room);
    if (is_undefined(spot) || !Run_IsActive()) return noone;
    var found = noone;
    with (obj_npc) {
        if (variable_instance_exists(id, "merchant") && merchant) found = id;
    }
    if (found != noone) return found;
    var inst = instance_create_layer(spot.x, spot.y, "Instances", obj_npc);
    inst.merchant = true;
    inst.shop_index = spot.shop;
    inst.interact_name = Loc_T("merchant.name", "Merchant");
    var spr = asset_get_index(Merchant_SpriteName());
    if (spr == -1) spr = nobody_down;
    inst.sprite_index = spr;
    inst.image_speed = 0;   // the frame is chosen in Merchant_DrawWorldFx (2 frames a second), whatever playback speed the sprite was imported with
    inst.image_index = 0;
    inst.persist_id = "merchant_" + string(spot.shop);
    return inst;
}

// The gold glow round the merchant on the map (World_DrawFx, scr_enemy): the sprite's silhouette in #E8C547 one pixel out in 8 directions,
// pulsing with Merchant_GlowAlpha, then the sprite itself on top. obj_npc has no Draw event, so this also steps the 2-frame idle (2 fps).
function Merchant_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    if (!instance_exists(obj_npc)) return;
    var _gold = make_color_rgb(232, 197, 71);
    var _idle = asset_get_index(Merchant_SpriteName());
    var _alpha = Merchant_GlowAlpha(current_time);
    var _oa = draw_get_alpha();
    with (obj_npc) {
        if (!variable_instance_exists(id, "merchant") || !merchant) continue;
        if (sprite_index == _idle && _idle != -1) image_index = (current_time div 500) mod max(1, sprite_get_number(_idle));
        gpu_set_fog(true, _gold, 0, 1);
        for (var _dy = -1; _dy <= 1; _dy++) {
            for (var _dx = -1; _dx <= 1; _dx++) {
                if (_dx == 0 && _dy == 0) continue;
                draw_sprite_ext(sprite_index, image_index, x + _dx, y + _dy, 1, 1, 0, c_white, _alpha);
            }
        }
        gpu_set_fog(false, c_white, 0, 1);
        draw_sprite_ext(sprite_index, image_index, x, y, 1, 1, 0, c_white, 1);
    }
    draw_set_alpha(_oa);
}

// ---- elites (D86) ----
function Elite_Mods() {
    return ["armored", "venomous", "swift", "brutal", "regenerating"];
}

function Elite_Name(_mod) {
    switch (_mod) {
        case "armored": return Loc_T("elite.name.armored", "Armored");
        case "venomous": return Loc_T("elite.name.venomous", "Venomous");
        case "swift": return Loc_T("elite.name.swift", "Swift");
        case "brutal": return Loc_T("elite.name.brutal", "Brutal");
        case "regenerating": return Loc_T("elite.name.regenerating", "Regenerating");
    }
    return "";
}

// One sentence with the real numbers (D100).
function Elite_Sentence(_mod) {
    switch (_mod) {
        case "armored": return Loc_T("elite.line.armored", "Armored: +{n} DEF.", { n: string(ELITE_DEF_BONUS) });
        case "venomous": return Loc_T("elite.line.venomous", "Venomous: its hits poison you for {n} stacks.", { n: string(ELITE_VENOM_STACKS) });
        case "swift": return Loc_T("elite.line.swift", "Swift: +{n} SPD.", { n: string(ELITE_SPD_BONUS) });
        case "brutal": return Loc_T("elite.line.brutal", "Brutal: +{n} ATK.", { n: string(ELITE_ATK_BONUS) });
        case "regenerating": return Loc_T("elite.line.regenerating", "Regenerating: heals {pct}% of its HP each turn.", { pct: string(round(ELITE_REGEN_FRAC * 100)) });
    }
    return "";
}

// Gives a freshly made battle enemy (EnemyCreate) its modifier. "" = a normal enemy. The name gets the modifier in front.
function Elite_Apply(_e, _mod) {
    _e.elite = _mod;
    _e.is_elite = (_mod != "");
    if (_mod == "") return _e;
    _e.name = Elite_Name(_mod) + " " + _e.name;
    _e.max_hp = max(1, RoundHalfUp(_e.max_hp * ELITE_HP_MULT));   // D111 (E1-2): every elite is tougher, whatever the modifier
    _e.hp = _e.max_hp;
    switch (_mod) {
        case "armored": _e.stats.def += ELITE_DEF_BONUS; break;
        case "swift": _e.stats.spd += ELITE_SPD_BONUS; break;
        case "brutal": _e.stats.atk += ELITE_ATK_BONUS; break;
    }
    return _e;
}

// The modifier of the enemy of the battle that is about to start ("" = none): set by EnemyPersist_BeginEncounter from the map enemy.
function Elite_BattleMod() {
    var gs = GameState_Get();
    if (is_struct(gs) && variable_struct_exists(gs, "battle") && is_struct(gs.battle) && variable_struct_exists(gs.battle, "enemy_elite")) return gs.battle.enemy_elite;
    return "";
}

function Elite_RegenAmount(_max_hp) {
    return max(2, RoundHalfUp(_max_hp * ELITE_REGEN_FRAC));
}

// Regenerating heals at the start of its turn; returns the HP healed.
function Elite_Regen(_e) {
    if (!is_struct(_e) || !variable_struct_exists(_e, "elite") || _e.elite != "regenerating" || _e.hp <= 0) return 0;
    var amt = min(Elite_RegenAmount(_e.max_hp), _e.max_hp - _e.hp);
    if (amt <= 0) return 0;
    _e.hp += amt;
    return amt;
}

// The outline pulse drawn round an elite on the map (World_DrawFx, scr_enemy): the palette's light colours, two beats a second.
function Elite_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    if (!instance_exists(obj_enemy)) return;
    var c_a = make_color_rgb(224, 248, 207);
    var c_b = make_color_rgb(134, 192, 108);
    var c_c = make_color_rgb(7, 24, 33);
    var oc = draw_get_color();
    var oa = draw_get_alpha();
    draw_set_alpha(1);
    var beat = (current_time div 250) mod 2;
    with (obj_enemy) {
        if (defeated || !variable_instance_exists(id, "elite_mod") || elite_mod == "") continue;
        var l = floor(bbox_left) - 1;
        var r = floor(bbox_right) + 1;
        var t = floor(bbox_top) - 1;
        var b = floor(bbox_bottom) + 1;
        draw_set_color(c_c);
        draw_rectangle(l - 1, t - 1, r + 1, b + 1, true);
        draw_set_color(beat == 0 ? c_a : c_b);
        draw_rectangle(l, t, r, b, true);
    }
    draw_set_color(oc);
    draw_set_alpha(oa);
}

// ---- per-run shuffles (D33) ----
// Which enemies a floor can have. The mini boss, the final boss and the Stranger (story) are never drawn; the rooms between floors have none.
function Shuffle_EnemyPool(_floor) {
    if (_floor != floor(_floor)) return [];
    switch (_floor) {
        case 1: return [ENEMY_SLIME];
        case 2: return [ENEMY_SLIME, ENEMY_DIREWOLF, ENEMY_SPIDER];
        case 3: return [ENEMY_SPIDER, ENEMY_SNAKE, ENEMY_DIREWOLF, ENEMY_SLIME];
        case 4: return [ENEMY_DIREWOLF, ENEMY_KILLER_PLANT, ENEMY_SPIDER, ENEMY_SNAKE];
        case 5: return [ENEMY_SNAKE, ENEMY_DIREWOLF, ENEMY_KILLER_PLANT];
        case 6: return [ENEMY_GHOSTSWORD, ENEMY_MADWHISP, ENEMY_KILLER_PLANT, ENEMY_DIREWOLF];
        case 7: return [ENEMY_MADWHISP, ENEMY_GHOSTSWORD, ENEMY_SPIDER, ENEMY_KILLER_PLANT];
        case 8: return [ENEMY_MADWHISP, ENEMY_GHOSTSWORD, ENEMY_KILLER_PLANT, ENEMY_SPIDER];
        case 9: return [ENEMY_MADWHISP, ENEMY_GHOSTSWORD, ENEMY_KILLER_PLANT];
    }
    return [];
}

// R1 (D123): elites per floor: ~15% of the free enemies (rounded half up), at least 1 from floor 2 on, never more than there are.
function Shuffle_EliteCount(_floor, _free) {
    if (_free <= 0) return 0;
    var c = RoundHalfUp(ELITE_CHANCE * _free);
    if (floor(_floor) >= 2) c = max(c, 1);
    return min(c, _free);
}

// The layout of one room's map enemies for a seed. _slots: [{ pid, enemy_id, x, y, fixed }] (the room's authored enemies; fixed = a boss or a
// story enemy, left alone). Returns an array of the same length: [{ pid, enemy_id, x, y, level, elite }]. Enemy types come from the floor's pool,
// the authored places are dealt out again among the free slots, Shuffle_EliteCount of them get one modifier.
function Shuffle_RoomPlan(_seed, _room_name, _slots) {
    var out = [];
    var fl = Run_FloorOfRoomName(_room_name);
    var pool = Shuffle_EnemyPool(fl);
    if (array_length(pool) <= 0) return out;
    var rng = Rng_New(_seed, "enemy:" + string(_room_name));
    var free_idx = [];
    var spots = [];
    for (var i = 0; i < array_length(_slots); i++) {
        var s = _slots[i];
        array_push(out, { pid: s.pid, enemy_id: s.enemy_id, x: s.x, y: s.y, level: 0, elite: "" });
        if (!s.fixed) {
            array_push(free_idx, i);
            array_push(spots, { x: s.x, y: s.y });
        }
    }
    spots = Rng_Shuffle(rng, spots);
    var elite_order = Rng_Shuffle(Rng_New(_seed, "elite:" + string(_room_name)), free_idx);   // R1 (D123): the first n of these are the room's elites
    var n_elite = Shuffle_EliteCount(fl, array_length(free_idx));
    for (var k = 0; k < array_length(free_idx); k++) {
        var e = out[free_idx[k]];
        e.x = spots[k].x;
        e.y = spots[k].y;
        e.enemy_id = pool[Rng_Int(rng, array_length(pool))];
        var cfg = EnemyDB_Get(e.enemy_id);
        var lo = max(1, round(cfg.species_min_level));
        var hi = max(lo, round(cfg.species_max_level));
        e.level = clamp(fl + Rng_Range(rng, -1, 1) + round(cfg.species_level_offset), lo, min(hi, LEVEL_CAP_TECHNICAL));
        var key = string(_room_name) + ":" + string(e.pid);
        for (var q = 0; q < n_elite; q++) {
            if (elite_order[q] == free_idx[k]) e.elite = Rng_Pick(Rng_New(_seed, "mod:" + key), Elite_Mods());
        }
    }
    return out;
}

// Chest loot bands: floors 1-3, 4-6, 7-9.
function Loot_FloorBand(_floor) {
    var f = floor(_floor);
    if (f <= 3) return 1;
    if (f <= 6) return 2;
    return 3;
}

// What a floor band adds to the chest table this run: one throwable and one accessory, picked from the seed (the same for every chest of the band).
function Loot_FloorExtras(_seed, _floor) {
    var band = Loot_FloorBand(_floor);
    var rng = Rng_New(_seed, "lootband:" + string(band));
    var thr_bands = [[33, 30], [30, 32, 31], [31, 32, 30, 33]];
    var acc_bands = [[40, 41, 42, 43], [41, 42, 43, 44, 45], [44, 45, 46, 42, 43]];
    var thr = thr_bands[band - 1];
    var acc = acc_bands[band - 1];
    var t = thr[Rng_Int(rng, array_length(thr))];
    var a = acc[Rng_Int(rng, array_length(acc))];
    return [
        { item_id: t, weight: 12, tier: 1, qty_min: 1, qty_max: 2 },
        { item_id: a, weight: 8, tier: 2, qty_min: 1, qty_max: 1 }
    ];
}

// The contents of one chest or barrel for a seed: its own stream (seed + room + placement), plus the floor band's extras. Same inputs, same loot.
function Shuffle_ChestLoot(_seed, _room_name, _pid, _level, _key, _player) {
    var rng = Rng_New(_seed, "chest:" + string(_room_name) + ":" + string(_pid));
    var extra = Loot_FloorExtras(_seed, Run_FloorOfRoomName(_room_name));
    return Loot_RollContainer(_level, _key, rng, extra, _player);
}

// An elite always leaves one card pick (D86): the character owes it and the card screen (C2) opens it after the fight.
function Elite_GrantPick(_p) {
    Card_EnsureFields(_p);
    _p.card_picks += 1;
    return _p;
}

// Gives the map enemies of the room their layout for this run (D33): types from the floor's pool, the authored spots dealt out again, Shuffle_EliteCount elites.
// Only enemies the room has no saved state for yet are touched (a room you have been in restores what it saved), so this is the same every time
// for the same seed. Bosses, the Stranger and any enemy a story trigger points at (cine_id) stay as authored. Called from RoomState_Apply.
function Shuffle_ApplyRoom() {
    var run = Run_Get();
    if (!is_struct(run) || !run.active) return 0;
    var rname = room_get_name(room);
    if (array_length(Shuffle_EnemyPool(Run_FloorOfRoomName(rname))) <= 0) return 0;
    var slots = [];
    var insts = [];
    with (obj_enemy) {
        RoomState_EnsurePersistId(id);
        if (!variable_instance_exists(id, "enemy_id") || enemy_id < 0) continue;
        if (is_struct(RoomState_Get(room, persist_id))) continue;
        var cfg = EnemyDB_Get(enemy_id);
        var fixed = cfg.is_boss || enemy_id == ENEMY_STRANGER || (variable_instance_exists(id, "cine_id") && string(cine_id) != "");
        array_push(slots, { pid: persist_id, enemy_id: enemy_id, x: xstart, y: ystart, fixed: fixed });   // the authored place, so applying twice gives the same layout
        array_push(insts, id);
    }
    if (array_length(slots) <= 0) return 0;
    var plan = Shuffle_RoomPlan(run.seed, rname, slots);
    var n = 0;
    for (var i = 0; i < array_length(plan); i++) {
        if (slots[i].fixed) continue;
        var pe = plan[i];
        with (insts[i]) {
            enemy_id = pe.enemy_id;
            enemy_level = pe.level;
            elite_mod = pe.elite;
            x = pe.x;
            y = pe.y;
            home_x = x;
            home_y = y;
            Enemy_ReapplyConfig(id);
        }
        n++;
    }
    return n;
}
