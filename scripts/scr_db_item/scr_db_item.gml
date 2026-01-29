function ItemDB_Init() {
    if (variable_global_exists("item_db") && ds_exists(global.item_db, ds_type_map)) {
        return;
    }

    global.item_db = ds_map_create();

    // Example weapon (Slime club)
    var w0 = {
        id: 1,
        name: "Rusty Sword",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        power: 3,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: CLASS_KNIGHT,
        sprite: noone,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 10
    };
    ds_map_add(global.item_db, w0.id, w0);

    // Example bow
    var w1 = {
        id: 2,
        name: "Short Bow",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        power: 2,
        stat_type: STAT_AGI,
        acc: 1,
        preferred_class: CLASS_ARCHER,
        sprite: noone,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 12
    };
    ds_map_add(global.item_db, w1.id, w1);

    // Example staff
    var w2 = {
        id: 3,
        name: "Oak Staff",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        power: 2,
        stat_type: STAT_INT,
        acc: 0,
        preferred_class: CLASS_MAGE,
        sprite: noone,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 12
    };
    ds_map_add(global.item_db, w2.id, w2);

    // Consumables
    var c0 = {
        id: 10,
        name: "Potion",
        type: ITEM_CONSUMABLE,
        stackable: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: noone,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "heal", power: 10, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 8
    };
    ds_map_add(global.item_db, c0.id, c0);

    var c1 = {
        id: 11,
        name: "Ether",
        type: ITEM_CONSUMABLE,
        stackable: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: noone,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "mp", power: 5, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 10
    };
    ds_map_add(global.item_db, c1.id, c1);

    var c2 = {
        id: 12,
        name: "Antidote",
        type: ITEM_CONSUMABLE,
        stackable: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: noone,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "cure", power: 0, status: STATUS_POISON, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 6
    };
    ds_map_add(global.item_db, c2.id, c2);

    // Skill book (teaches Power Strike)
    var b0 = {
        id: 30,
        name: "Skill Book: Power",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: noone,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_POWER_STRIKE },
        value: 25
    };
    ds_map_add(global.item_db, b0.id, b0);

    // Armor
    var a0 = {
        id: 20,
        name: "Leather Armor",
        type: ITEM_ARMOR,
        stackable: false,
        max_stack: 1,
        equip_slot: "body",
        power: 0,
        stat_type: STAT_DEF,
        acc: 0,
        preferred_class: -1,
        sprite: noone,
        bonus: { str:0, agi:0, def:1, intt:0, luck:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 20
    };
    ds_map_add(global.item_db, a0.id, a0);

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.item_db = global.item_db;
    }
}

function ItemDB_Get(_id) {
    if (!variable_global_exists("item_db") || !ds_exists(global.item_db, ds_type_map)) {
        ItemDB_Init();
    }
    var db = global.item_db;
    if (variable_global_exists("state") && is_struct(global.state) && variable_struct_exists(global.state, "item_db")) {
        db = global.state.item_db;
    }

    if (ds_map_exists(db, _id)) return db[? _id];
    return { id: 0, name: "None", type: ITEM_KEY, stackable: false, max_stack: 0, equip_slot: "", power: 0, stat_type: -1, acc: 0, preferred_class: -1, sprite: noone, bonus: { str:0, agi:0, def:0, intt:0, luck:0 }, use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 }, value: 0 };
}

function Item_IsConsumable(_item) {
    return _item.type == ITEM_CONSUMABLE;
}

function Item_Use(_item_id, _user, _target) {
    var item = ItemDB_Get(_item_id);
    var result = { ok: true, msg: "", fx_sprite: item.use.fx_sprite, fx_frames: item.use.fx_frames, fx_speed: item.use.fx_speed };

    if (!Item_IsConsumable(item)) {
        result.ok = false;
        result.msg = "Can't use that.";
        return result;
    }

    var eff = item.use.effect;
    if (eff == "heal") {
        var amt = item.use.power;
        _target.hp = clamp(_target.hp + amt, 0, _target.max_hp);
        result.msg = "Healed " + string(amt) + " HP.";
    } else if (eff == "mp") {
        var amt2 = item.use.power;
        _target.mp = clamp(_target.mp + amt2, 0, _target.max_mp);
        result.msg = "Recovered " + string(amt2) + " MP.";
    } else if (eff == "cure") {
        if (is_array(_target.status)) {
            for (var i = array_length(_target.status) - 1; i >= 0; i--) {
                if (_target.status[i].id == item.use.status) {
                    array_delete(_target.status, i, 1);
                }
            }
        }
        result.msg = "Status cured.";
    } else if (eff == "learn_skill") {
        if (variable_struct_exists(item.use, "skill_id")) {
            _user = Player_LearnSkill(_user, item.use.skill_id);
            result.msg = "You learned a skill!";
        }
    }

    return result;
}
