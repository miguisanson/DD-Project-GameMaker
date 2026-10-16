function ItemDB_Init() {
    if (variable_global_exists("item_db") && ds_exists(global.item_db, ds_type_map)) {
        ItemDB_AssignEquipPassives(global.item_db);
        return;
    }

    global.item_db = ds_map_create();

    // Weapons - Swords
    var w0 = {
        id: 1,
        name: "Wooden Sword",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "sword",   // row of Qte_BarParams (D60)
        power: 3,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: CLASS_KNIGHT,
        sprite: wooden_sword,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 8
    };
    ds_map_add(global.item_db, w0.id, w0);

    var w1 = {
        id: 2,
        name: "Iron Sword",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "sword",   // row of Qte_BarParams (D60)
        power: 6,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: CLASS_KNIGHT,
        sprite: iron_sword,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 18
    };
    ds_map_add(global.item_db, w1.id, w1);

    var w2 = {
        id: 3,
        name: "Platinum Sword",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "sword",   // row of Qte_BarParams (D60)
        power: 9,
        stat_type: STAT_ATK,
        acc: 1,
        preferred_class: CLASS_KNIGHT,
        sprite: platinum_sword,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 35
    };
    ds_map_add(global.item_db, w2.id, w2);

    // Weapons - Bows
    var w3 = {
        id: 4,
        name: "Wooden Bow",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "bow",   // row of Qte_BarParams (D60)
        power: 3,
        stat_type: STAT_ATK,
        acc: 1,
        preferred_class: CLASS_ARCHER,
        sprite: wooden_bow,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 8
    };
    ds_map_add(global.item_db, w3.id, w3);

    var w4 = {
        id: 5,
        name: "Iron Bow",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "bow",   // row of Qte_BarParams (D60)
        power: 6,
        stat_type: STAT_ATK,
        acc: 1,
        preferred_class: CLASS_ARCHER,
        sprite: iron_bow,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 18
    };
    ds_map_add(global.item_db, w4.id, w4);

    var w5 = {
        id: 6,
        name: "Platinum Bow",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "bow",   // row of Qte_BarParams (D60)
        power: 9,
        stat_type: STAT_ATK,
        acc: 2,
        preferred_class: CLASS_ARCHER,
        sprite: platinum_bow,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 35
    };
    ds_map_add(global.item_db, w5.id, w5);

    // Weapons - Staves
    var w6 = {
        id: 7,
        name: "Wooden Staff",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "staff",   // row of Qte_BarParams (D60)
        power: 3,
        stat_type: STAT_MAG,
        acc: 0,
        preferred_class: CLASS_MAGE,
        sprite: wooden_staff,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 8
    };
    ds_map_add(global.item_db, w6.id, w6);

    var w7 = {
        id: 8,
        name: "Ruby Staff",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "staff",   // row of Qte_BarParams (D60)
        power: 6,
        stat_type: STAT_MAG,
        acc: 0,
        preferred_class: CLASS_MAGE,
        sprite: ruby_staff,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 20
    };
    ds_map_add(global.item_db, w7.id, w7);

    var w8 = {
        id: 9,
        name: "Diamond Staff",
        type: ITEM_WEAPON,
        stackable: false,
        max_stack: 1,
        equip_slot: "weapon",
        weapon_kind: "staff",   // row of Qte_BarParams (D60)
        power: 9,
        stat_type: STAT_MAG,
        acc: 1,
        preferred_class: CLASS_MAGE,
        sprite: diamond_staff,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 40
    };
    ds_map_add(global.item_db, w8.id, w8);

    // Consumables - HP Potions
    var c0 = {
        id: 10,
        name: "HP Potion Lv1",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: hp_potion,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "heal", min: 5, max: 10, scale: 1.0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 8
    };
    ds_map_add(global.item_db, c0.id, c0);

    var c1 = {
        id: 14,
        name: "HP Potion Lv2",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: hp_potion,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "heal", min: 10, max: 20, scale: 0.8, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 14
    };
    ds_map_add(global.item_db, c1.id, c1);

    var c2 = {
        id: 15,
        name: "HP Potion Lv3",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: hp_potion,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "heal", min: 20, max: 35, scale: 1.2, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 25
    };
    ds_map_add(global.item_db, c2.id, c2);

    // Consumables - MP Potions
    var c3 = {
        id: 11,
        name: "MP Potion Lv1",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: mp_potion,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "mp", min: 4, max: 8, scale: 0.4, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 10
    };
    ds_map_add(global.item_db, c3.id, c3);

    var c4 = {
        id: 17,
        name: "MP Potion Lv2",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: mp_potion,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "mp", min: 8, max: 14, scale: 0.7, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 16
    };
    ds_map_add(global.item_db, c4.id, c4);

    var c5 = {
        id: 18,
        name: "MP Potion Lv3",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: mp_potion,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "mp", min: 12, max: 20, scale: 1.0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 28
    };
    ds_map_add(global.item_db, c5.id, c5);

    // Status cures
    var c6 = {
        id: 12,
        name: "Antidote",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: antidote,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "cure", power: 0, status: STATUS_POISON, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 6
    };
    ds_map_add(global.item_db, c6.id, c6);

    var c7 = {
        id: 13,
        name: "Bandage",
        type: ITEM_CONSUMABLE,
        stackable: true,
        usable_battle: true,
        max_stack: 99,
        equip_slot: "",
        power: 0,
        stat_type: STAT_ATK,
        acc: 0,
        preferred_class: -1,
        sprite: bandage,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "cure", power: 0, status: STATUS_BLEED, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 6
    };
    ds_map_add(global.item_db, c7.id, c7);

    // Armor - Warrior/Archer
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
        allowed_classes: [CLASS_KNIGHT, CLASS_ARCHER],
        sprite: leather_armor,
        bonus: { atk:0, def:1, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 20
    };
    ds_map_add(global.item_db, a0.id, a0);

    var a1 = {
        id: 21,
        name: "Iron Armor",
        type: ITEM_ARMOR,
        stackable: false,
        max_stack: 1,
        equip_slot: "body",
        power: 0,
        stat_type: STAT_DEF,
        acc: 0,
        preferred_class: -1,
        allowed_classes: [CLASS_KNIGHT, CLASS_ARCHER],
        sprite: iron_armor,
        bonus: { atk:0, def:2, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 40
    };
    ds_map_add(global.item_db, a1.id, a1);

    var a2 = {
        id: 22,
        name: "Platinum Armor",
        type: ITEM_ARMOR,
        stackable: false,
        max_stack: 1,
        equip_slot: "body",
        power: 0,
        stat_type: STAT_DEF,
        acc: 0,
        preferred_class: -1,
        allowed_classes: [CLASS_KNIGHT, CLASS_ARCHER],
        sprite: platinum_armor,
        bonus: { atk:0, def:3, spd:0, mag:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 70
    };
    ds_map_add(global.item_db, a2.id, a2);

    // Armor - Mage
    var a3 = {
        id: 23,
        name: "Cloth Robe",
        type: ITEM_ARMOR,
        stackable: false,
        max_stack: 1,
        equip_slot: "body",
        power: 0,
        stat_type: STAT_MAG,
        acc: 0,
        preferred_class: CLASS_MAGE,
        allowed_classes: [CLASS_MAGE],
        sprite: cloth_robe,
        bonus: { atk:0, def:0, spd:0, mag:1 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 16
    };
    ds_map_add(global.item_db, a3.id, a3);

    var a4 = {
        id: 24,
        name: "Silk Robe",
        type: ITEM_ARMOR,
        stackable: false,
        max_stack: 1,
        equip_slot: "body",
        power: 0,
        stat_type: STAT_MAG,
        acc: 0,
        preferred_class: CLASS_MAGE,
        allowed_classes: [CLASS_MAGE],
        sprite: silk_robe,
        bonus: { atk:0, def:0, spd:0, mag:2 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 34
    };
    ds_map_add(global.item_db, a4.id, a4);

    var a5 = {
        id: 25,
        name: "Mithril Robe",
        type: ITEM_ARMOR,
        stackable: false,
        max_stack: 1,
        equip_slot: "body",
        power: 0,
        stat_type: STAT_MAG,
        acc: 0,
        preferred_class: CLASS_MAGE,
        allowed_classes: [CLASS_MAGE],
        sprite: mithril_robe,
        bonus: { atk:0, def:0, spd:0, mag:3 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 60
    };
    ds_map_add(global.item_db, a5.id, a5);


    // ---- C3 (D84): throwables. Any class throws them from the Items menu; a throw costs the turn and uses the sliding bar's grade (Throw_Resolve).
    // use: power (formula power / 2, damage), burn_turns, stacks (poison), stun (push-back, not on Weak), evade_turns (Evasion on the thrower), escape (Perfect, not a boss).
    // Numbers are starting values for the simulator; the text on screen is built from them (Item_Sentence, Item_NumberLines).
    var t0 = {
        id: 30, name: "Firebomb", type: ITEM_CONSUMABLE, stackable: true, usable_battle: true, throwable: true, max_stack: 8, equip_slot: "",
        power: 0, stat_type: STAT_ATK, acc: 0, preferred_class: -1, sprite: noone, icon_kind: "throwable", icon_sub: 0,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "throw", power: 3, burn_turns: 2, stacks: 0, stun: false, evade_turns: 0, escape: false, status: -1, target: TGT_ENEMY, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 18
    };
    ds_map_add(global.item_db, t0.id, t0);

    var t1 = {
        id: 31, name: "Poison Pot", type: ITEM_CONSUMABLE, stackable: true, usable_battle: true, throwable: true, max_stack: 8, equip_slot: "",
        power: 0, stat_type: STAT_ATK, acc: 0, preferred_class: -1, sprite: noone, icon_kind: "throwable", icon_sub: 1,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "throw", power: 0, burn_turns: 0, stacks: 4, stun: false, evade_turns: 0, escape: false, status: STATUS_POISON, target: TGT_ENEMY, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 18
    };
    ds_map_add(global.item_db, t1.id, t1);

    var t2 = {
        id: 32, name: "Ice Flask", type: ITEM_CONSUMABLE, stackable: true, usable_battle: true, throwable: true, max_stack: 8, equip_slot: "",
        power: 0, stat_type: STAT_ATK, acc: 0, preferred_class: -1, sprite: noone, icon_kind: "throwable", icon_sub: 2,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "throw", power: 3, burn_turns: 0, stacks: 0, stun: true, evade_turns: 0, escape: false, status: STATUS_STUN, target: TGT_ENEMY, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 20
    };
    ds_map_add(global.item_db, t2.id, t2);

    var t3 = {
        id: 33, name: "Smoke Bomb", type: ITEM_CONSUMABLE, stackable: true, usable_battle: true, throwable: true, max_stack: 8, equip_slot: "",
        power: 0, stat_type: STAT_ATK, acc: 0, preferred_class: -1, sprite: noone, icon_kind: "throwable", icon_sub: 3,
        bonus: { atk:0, def:0, spd:0, mag:0 },
        use: { effect: "throw", power: 0, burn_turns: 0, stacks: 0, stun: false, evade_turns: 2, escape: true, status: STATUS_EVASION, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 14
    };
    ds_map_add(global.item_db, t3.id, t3);

    // ---- C3 (D92): accessories, the third gear slot ("accessory"): rings and charms with a small stat or a small passive. One copy each.
    var ac_rows = [
        [40, "Copper Ring",  0, { atk:1, def:0, spd:0, mag:0 }, 28],
        [41, "Guard Ring",   0, { atk:0, def:1, spd:0, mag:0 }, 28],
        [42, "Swift Charm",  1, { atk:0, def:0, spd:1, mag:0 }, 28],
        [43, "Sage Charm",   1, { atk:0, def:0, spd:0, mag:1 }, 28],
        [44, "Stone Charm",  1, { atk:0, def:0, spd:0, mag:0 }, 36],
        [45, "Spring Ring",  0, { atk:0, def:0, spd:0, mag:0 }, 36],
        [46, "Lucky Charm",  1, { atk:0, def:0, spd:0, mag:0 }, 30]
    ];
    for (var ai = 0; ai < array_length(ac_rows); ai++) {
        var acr = ac_rows[ai];
        var acc_item = {
            id: acr[0], name: acr[1], type: ITEM_ACCESSORY, stackable: false, max_stack: 1, equip_slot: "accessory",
            power: 0, stat_type: -1, acc: 0, preferred_class: -1, sprite: noone, icon_kind: "accessory", icon_sub: acr[2],
            bonus: acr[3],
            use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
            value: acr[4]
        };
        ds_map_add(global.item_db, acc_item.id, acc_item);
    }

    ItemDB_AssignEquipPassives(global.item_db);

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

    ItemDB_AssignEquipPassives(db);
    if (ds_map_exists(db, _id)) return Item_LocalizeRuntime(db[? _id]);
    return { id: 0, name: Loc_T("item.name.0", "None"), type: ITEM_KEY, stackable: false, max_stack: 0, equip_slot: "", power: 0, stat_type: -1, acc: 0, preferred_class: -1, sprite: noone, bonus: { atk:0, def:0, spd:0, mag:0 }, use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 }, value: 0 };
}

// ---- rarity (D178, R-110): every item is Common (1, white), Rare (2, gold #E8C547) or Epic (3, gold that pulses to a lighter gold). ONE explicit table, filled from the
// highest loot tier each item appears at (scr_loot.gml: chest, barrel and enemy tables carry tier 1..3 per entry; D117 rolls the tier first). Items that are in no loot table
// go by their price (value): under 18 Common, 18 to 39 Rare, 40 and up Epic. That rule gives: Poison Pot 18, Ice Flask 20 and the rings and charms 40..46 (28 to 36) Rare.
//   Common (1): 1 Wooden Sword, 4 Wooden Bow, 7 Wooden Staff, 20 Leather Armor, 23 Cloth Robe, 10 HP Potion Lv1, 11 MP Potion Lv1, 12 Antidote, 13 Bandage, 33 Smoke Bomb
//   Rare   (2): 2 Iron Sword, 5 Iron Bow, 8 Ruby Staff, 21 Iron Armor, 24 Silk Robe, 14 HP Potion Lv2, 17 MP Potion Lv2, 30 Firebomb, 31 Poison Pot, 32 Ice Flask, 40..46 the accessories
//   Epic   (3): 3 Platinum Sword, 6 Platinum Bow, 9 Diamond Staff, 22 Platinum Armor, 25 Mithril Robe, 15 HP Potion Lv3, 18 MP Potion Lv3
// An id that is not in the table (a new item, nothing at all) is rated by its price too; the unknown id 0 / 9999 has value 0, so Common.
function Item_Rarity(_id) {
    switch (_id) {
        case 1: case 4: case 7: case 20: case 23: case 10: case 11: case 12: case 13: case 33: return 1;
        case 2: case 5: case 8: case 21: case 24: case 14: case 17: case 30: case 31: case 32:
        case 40: case 41: case 42: case 43: case 44: case 45: case 46: return 2;
        case 3: case 6: case 9: case 22: case 25: case 15: case 18: return 3;
    }
    var it = ItemDB_Get(_id);
    var v = (is_struct(it) && variable_struct_exists(it, "value")) ? it.value : 0;
    return (v >= 40) ? 3 : ((v >= 18) ? 2 : 1);
}

// The clock the Epic pulse and gem run on: the game's own time, or a held time for the pictures (global.rarity_clock >= 0).
function Rarity_Clock() {
    if (variable_global_exists("rarity_clock") && global.rarity_clock >= 0) return global.rarity_clock;
    return current_time;
}

// 0..1: 0 at the start of every 600 ms, 1 in the middle (a smooth rise and fall).
function Rarity_Pulse(_now = undefined) {
    var t = is_undefined(_now) ? Rarity_Clock() : _now;
    return 0.5 - 0.5 * cos(2 * pi * ((t mod 600) / 600));
}

// The colour of an item name: Common white, Rare gold (the merchant gold #E8C547), Epic the gold pulsing to a lighter gold every ~600 ms. _now: a time in ms (the live clock by default).
function Rarity_Color(_r, _now = undefined) {
    if (_r >= 3) return merge_color(UI_C_MERCHANT_GOLD, UI_C_RARITY_EPIC, Rarity_Pulse(_now));
    if (_r == 2) return UI_C_MERCHANT_GOLD;
    return UI_C_TEXT;
}

// An item's name for a sentence: "[r2]Iron Sword[/r2]" (the tag is the item's rarity, drawn by the rich-text drawer); with _qty the count follows the tag, uncoloured.
// Every message that names an item uses this (D178); never put an item's plain name in a sentence.
function Item_NameMarked(_id, _qty = undefined) {
    var it = ItemDB_Get(_id);
    var nm = (is_struct(it) && variable_struct_exists(it, "name")) ? string(it.name) : "";
    var tag = "r" + string(Item_Rarity(_id));
    var out = "[" + tag + "]" + nm + "[/" + tag + "]";
    if (!is_undefined(_qty)) out = Loc_T("battle.menu.item_row", "{name} x{qty}", { name: out, qty: string(_qty) });   // the same "name xN" row the battle list uses
    return out;
}

// D108 F1a: a serial number for "the language and string table as they are now". It changes when the language, its revision (Loc_SetLanguage)
// or the string table (a payload load) changes, so each item localizes once per change instead of on every ItemDB_Get.
function Item_LocSerial() {
    Loc_Init();
    var loc = Loc_GetData();
    var st = variable_global_exists("item_loc_stamp") ? global.item_loc_stamp : undefined;
    if (!is_struct(st) || st.lang != loc.lang || st.rev != loc.revision || st.strings != loc.strings) {
        global.item_loc_stamp = { lang: loc.lang, rev: loc.revision, strings: loc.strings, serial: is_struct(st) ? st.serial + 1 : 1 };
    }
    return global.item_loc_stamp.serial;
}

function Item_LocalizeRuntime(_item) {
    if (!is_struct(_item)) return _item;
    var serial = Item_LocSerial();
    if (variable_struct_exists(_item, "loc_serial") && _item.loc_serial == serial) return _item;
    _item.loc_serial = serial;

    if (!variable_struct_exists(_item, "name_en")) _item.name_en = string(_item.name);
    _item.name = Loc_T("item.name." + string(_item.id), string(_item.name_en));

    if (variable_struct_exists(_item, "passive_desc") && is_array(_item.passive_desc) && array_length(_item.passive_desc) > 0) {
        if (!variable_struct_exists(_item, "passive_desc_en") || !is_array(_item.passive_desc_en)) {
            var base_desc = [];
            for (var i = 0; i < array_length(_item.passive_desc); i++) {
                array_push(base_desc, string(_item.passive_desc[i]));
            }
            _item.passive_desc_en = base_desc;
        }

        if (array_length(_item.passive_desc_en) > 0) {
            _item.passive_desc[0] = Loc_T("item.passive.name." + string(_item.id), string(_item.passive_desc_en[0]));
        }
        if (array_length(_item.passive_desc_en) > 1) {
            _item.passive_desc[1] = Loc_T("item.passive.desc." + string(_item.id), string(_item.passive_desc_en[1]));
        }
    }

    return _item;
}

function ItemDB_GetPassiveTemplate(_item_id) {
    switch (_item_id) {
        // Weapons
        case 1: return { id: "steady_strike", params: { once_per_turn: true }, desc: ["Steady Strike", "WEAK->OK (1/turn)"] };
        case 2: return { id: "sunder_edge", params: { first_hit_def_down: 1, turns: 2 }, desc: ["Sunder Edge", "Your first hit cuts the enemy's [t]DEF[/t] by 1 for 2 turns"] };
        case 3: return { id: "executioner", params: { hp_ratio: 0.35, mult: 1.35 }, desc: ["Executioner", "+35% damage to enemies under 35% [t]HP[/t]"] };
        case 4: return { id: "aim_assist", params: { upgrade_good_to_perfect_once_per_turn: true }, desc: ["Aim Assist", "GOOD->PERFECT (1/turn)"] };
        case 5: return { id: "pinning_shot", params: { stun_chance: 0.15, stun_turns: 1, cooldown_turns: 3, requires_good_or_perfect: true }, desc: ["Pinning Shot", "A [t]Good[/t] or [a]Perfect[/a] press may [t]Stun[/t] the enemy (3-turn cooldown)"] };
        case 6: return { id: "predator", params: { mult: 1.30, requires_target_statused: true }, desc: ["Predator", "+30% damage to enemies with a status"] };
        case 7: return { id: "mana_trickle", params: { mp_gain: 1, every_n_turns: 2 }, desc: ["Mana Trickle", "+1 MP every 2 turns"] };
        case 8: return { id: "ember_lens", params: { skill_mult: 1.15, status_turn_bonus: 1 }, desc: ["Ember Lens", "Skills deal +15% damage; your statuses last 1 turn longer"] };
        case 9: return { id: "arcane_surge", params: { skill_mult: 1.25, perfect_mp: 1 }, desc: ["Arcane Surge", "Skills deal +25% damage; a [a]Perfect[/a] press gives +1 [t]MP[/t]"] };

        // Armor
        case 20: return { id: "first_impact", params: { flat_reduction_first_hit: 3, once_per_battle: true }, desc: ["First Impact", "The first hit you take deals 3 less damage (once per battle)"] };
        case 21: return { id: "brace", params: { guard_mult_next_hit: 0.60, cooldown_turns: 2, triggers_on_take_damage: true }, desc: ["Brace", "After you are hit, the next hit deals 40% less (2-turn cooldown)"] };
        case 22: return { id: "debt_plate", params: { big_hit_threshold: 6, big_hit_reduction: 0.30 }, desc: ["Debt Plate", "Big hits deal 30% less damage"] };
        case 23: return { id: "thin_veil", params: { mp_gain: 1, every_n_turns: 2, physical_vuln_flat: 1 }, desc: ["Thin Veil", "+1 [t]MP[/t] every 2 turns, but physical hits deal 1 more damage"] };
        case 24: return { id: "silk_flow", params: { skill_mult: 1.10, status_turn_bonus: 1 }, desc: ["Silk Flow", "Skills deal +10% damage; your statuses last 1 turn longer"] };
        case 25: return { id: "mirror_stitch", params: { reflect_first_status_once_per_battle: true, mp_cost_on_trigger: 1 }, desc: ["Mirror Stitch", "Reflects the first status cast on you (once per battle, costs 1 [t]MP[/t])"] };

        // Accessories (C3, D92): small passives; the stat rings and charms 40-43 carry a plain +1 stat bonus instead.
        case 44: return { id: "hardened", params: { damage_reduction: 0.10 }, desc: ["Hardened", "Take 10% less damage"] };
        case 45: return { id: "ring_mana", params: { mp_gain: 1, every_n_turns: 3 }, desc: ["Spring", "+1 MP every 3 turns"] };
        case 46: return { id: "lucky", params: { gold_mult: 0.15 }, desc: ["Lucky", "Find 15% more gold"] };
    }
    return { id: "", params: {}, desc: [] };
}

function ItemDB_AssignEquipPassives(_db) {
    if (!ds_exists(_db, ds_type_map)) return;
    // D108 F1a: once per database. Item 1 already carrying its passive means ItemDB_Init (or an earlier call) did the assignment, and nothing
    // changes the passives afterwards; a fresh map from ItemDB_Init has no passive_params yet, so it is assigned again.
    if (ds_map_exists(_db, 1)) {
        var first = _db[? 1];
        if (is_struct(first) && variable_struct_exists(first, "passive_params")) return;
    }
    var ids = [1,2,3,4,5,6,7,8,9,20,21,22,23,24,25,44,45,46];
    for (var i = 0; i < array_length(ids); i++) {
        var iid = ids[i];
        if (!ds_map_exists(_db, iid)) continue;
        var item = _db[? iid];
        if (!is_struct(item)) continue;
        var tpl = ItemDB_GetPassiveTemplate(iid);
        if (!is_struct(tpl)) continue;
        if (!variable_struct_exists(tpl, "id") || string(tpl.id) == "") continue;

        item.passive_id = tpl.id;
        item.passive_params = variable_struct_exists(tpl, "params") && is_struct(tpl.params) ? tpl.params : {};
        item.passive_desc = variable_struct_exists(tpl, "desc") && is_array(tpl.desc) ? tpl.desc : [];
    }
}

function Item_IsConsumable(_item) {
    return _item.type == ITEM_CONSUMABLE;
}

// A base amount after the user's level scaling and potion passives (the part of a roll that is not random).
function Item_AdjustAmount(_user, _use, _base) {
    var amt = _base;
    if (is_struct(_user) && variable_struct_exists(_user, "level") && variable_struct_exists(_use, "scale")) {
        var lvl = max(0, _user.level - 1);
        amt += floor(lvl * _use.scale);
    }
    var power_bonus = Card_PassiveSum(_user, "item_power");   // C2: Potion Lore, Apothecary
    if (power_bonus > 0) amt = max(amt, round(amt * (1 + power_bonus)));
    return amt;
}

// D126: a heal or MP use that is written as min..max gives the exact average (rounded half up), then the user's level scaling and potion passives.
// No dice: the same potion heals the same every time, and the details panel shows that one number.
function Item_BaseAmount(_use) {
    var minv = variable_struct_exists(_use, "min") ? _use.min : _use.power;
    var maxv = variable_struct_exists(_use, "max") ? _use.max : _use.power;
    if (maxv < minv) maxv = minv;
    return RoundHalfUp((minv + maxv) / 2);
}

function Item_ComputeAmount(_user, _use) {
    return Item_AdjustAmount(_user, _use, Item_BaseAmount(_use));
}

// Hunt 7 (D100): the number a screen shows for a potion: what Item_Use applies to _ch (level scaling, Potion Lore), or the base without a character.
function Item_ShownAmount(_ch, _use) {
    return is_struct(_ch) ? Item_ComputeAmount(_ch, _use) : Item_BaseAmount(_use);
}

function Item_Use(_item_id, _user, _target) {
    var item = ItemDB_Get(_item_id);
    var result = { ok: true, msg: "", fx_sprite: item.use.fx_sprite, fx_frames: item.use.fx_frames, fx_speed: item.use.fx_speed };

    if (!Item_IsConsumable(item)) {
        result.ok = false;
        result.msg = Loc_T("item.msg.cant_use", "Can't use that.");
        return result;
    }

    if (Item_IsThrowable(item)) {   // C3 (D84): thrown in battle only
        result.ok = false;
        result.msg = Loc_T("item.msg.throw_in_battle", "Throw it at an enemy in battle.");
        return result;
    }

    var eff = item.use.effect;
    if (eff == "heal") {
        var before_hp = _target.hp;
        var amt = Item_ComputeAmount(_user, item.use);
        _target.hp = clamp(_target.hp + amt, 0, _target.max_hp);
        if (_target.hp == before_hp) {
            result.ok = false;
            result.msg = Loc_T("item.msg.full_health", "Already full health.");
        } else {
            result.msg = Loc_T("item.msg.healed_hp", "Healed {amt} HP.", { amt: string(amt) });
            var potion_mp = round(Card_PassiveSum(_user, "potion_mp"));   // C2: Tonic Blend
            if (potion_mp > 0 && variable_struct_exists(_target, "mp") && variable_struct_exists(_target, "max_mp")) _target.mp = clamp(_target.mp + potion_mp, 0, _target.max_mp);
        }
    } else if (eff == "mp") {
        var before_mp = _target.mp;
        var amt2 = Item_ComputeAmount(_user, item.use);
        _target.mp = clamp(_target.mp + amt2, 0, _target.max_mp);
        if (_target.mp == before_mp) {
            result.ok = false;
            result.msg = Loc_T("item.msg.full_mana", "Already full mana.");
        } else {
            result.msg = Loc_T("item.msg.recovered_mp", "Recovered {amt} MP.", { amt: string(amt2) });
        }
    } else if (eff == "cure") {
        var cured_name = "";
        if (is_array(_target.status)) {
            for (var i = array_length(_target.status) - 1; i >= 0; i--) {
                if (_target.status[i].id == item.use.status) {
                    var cfg = StatusDB_Get(item.use.status);
                    cured_name = cfg.name;
                    array_delete(_target.status, i, 1);
                }
            }
        }
        if (cured_name != "") {
            result.msg = Loc_T("item.msg.status_cured", "{status} cured.", { status: cured_name });
        } else {
            result.ok = false;
            result.msg = Loc_T("item.msg.no_status_cure", "No status to cure.");
        }
    } else {   // D156: an effect this function does not know would be used up for nothing
        result.ok = false;
        result.msg = Loc_T("item.msg.nothing_happens", "Nothing happens.");
    }

    return result;
}

// ============================================================================================================
// C3 (D84): throwables. Used from the battle's Items menu by any class; the throw costs the turn and the sliding bar's grade (D61) sets how
// strong it is. Nobody throws 1.5x as hard and carries 8 of each instead of 5. The thrower's "stat" is 12 + its level, the same for every class.
// ============================================================================================================
function Item_IsThrowable(_item) {
    return is_struct(_item) && variable_struct_exists(_item, "throwable") && _item.throwable;
}

function Throw_Cap(_ch) {
    return (is_struct(_ch) && variable_struct_exists(_ch, "class_id") && _ch.class_id == CLASS_NOBODY) ? THROW_CAP_NOBODY : THROW_CAP;
}

function Throw_Mult(_ch) {
    return (is_struct(_ch) && variable_struct_exists(_ch, "class_id") && _ch.class_id == CLASS_NOBODY) ? THROW_NOBODY_MULT : 1;
}

function Throw_Stat(_ch) {
    return THROW_STAT_BASE + ((is_struct(_ch) && variable_struct_exists(_ch, "level")) ? _ch.level : 1);
}

// Poison stacks by grade: Perfect one more than the base, Good and OK the base, Weak one fewer (never below 1).
function Throw_Stacks(_base, _key) {
    switch (_key) {
        case QTE_PERFECT: return _base + 1;
        case QTE_GOOD: return _base;
        case QTE_OK: return _base;
    }
    return max(1, _base - 1);
}

// Burn per turn of a firebomb thrown by _ch at OK (before the grade).
function Throw_BurnBase(_ch) {
    return RoundHalfUp(Status_BurnTick(Throw_Stat(_ch)) * Throw_Mult(_ch));
}

// Throws item _item_id at _target for _user at grade _key. Changes both (damage, statuses). The caller removes the item from the inventory.
// Returns { ok, msg, dmg, burn, stacks, stun, evade, escape }.
function Throw_Resolve(_item_id, _user, _target, _key) {
    var item = ItemDB_Get(_item_id);
    var res = { ok: false, msg: "", dmg: 0, burn: 0, stacks: 0, stun: false, evade: 0, escape: false };
    if (!Item_IsThrowable(item)) {
        res.msg = Loc_T("item.msg.cant_use", "Can't use that.");
        return res;
    }
    res.ok = true;
    var u = item.use;
    var gm = Qte_GradeMult(_key);
    var nm = Throw_Mult(_user);
    var parts = [];

    if (u.power > 0) {
        var mult = nm * Combat_BreakMult(_target);
        var guard = Status_GetMul(_target, "guard_mult");
        if (guard != 1) {
            mult *= guard;
            _target = Status_ConsumeByField(_target, "consume_on_hit");
        }
        res.dmg = Combat_RatioDamage(COMBAT_POWER_SCALE * u.power, Throw_Stat(_user), Combat_EffectiveStat(_target, STAT_DEF), gm, mult);
        _target.hp = max(0, _target.hp - res.dmg);
        array_push(parts, Loc_T("throw.msg.damage", "{dmg} damage.", { dmg: string(res.dmg) }));
    }
    if (u.burn_turns > 0 && _target.hp > 0) {
        res.burn = Qte_ScaleAmount(Throw_BurnBase(_user), gm, 1);
        Status_Add(_target, STATUS_BURN, u.burn_turns, res.burn);
        array_push(parts, Loc_T("throw.msg.burn", "It burns for {n} a turn.", { n: string(res.burn) }));
    }
    if (u.stacks > 0) {
        res.stacks = Throw_Stacks(RoundHalfUp(u.stacks * nm), _key);
        Status_Add(_target, STATUS_POISON, res.stacks, 1, res.stacks);
        array_push(parts, Loc_T("throw.msg.poison", "{n} stacks of poison.", { n: string(res.stacks) }));
    }
    if (u.stun && _key != QTE_WEAK && _target.hp > 0) {
        Status_Add(_target, STATUS_STUN, 1, 1);
        res.stun = true;
    }
    if (u.evade_turns > 0) {
        res.evade = Qte_ScaleAmount(RoundHalfUp(u.evade_turns * nm), gm, 1);
        Status_Add(_user, STATUS_EVASION, res.evade, 1);
        array_push(parts, Loc_T("throw.msg.evade", "You will dodge the next attack."));
    }
    if (u.escape && _key == QTE_PERFECT && !(variable_struct_exists(_target, "is_boss") && _target.is_boss)) {
        res.escape = true;
        array_push(parts, Loc_T("throw.msg.escape", "You slip away in the smoke!"));
    }
    var msg = Loc_T("throw.msg.thrown", "You throw the {item}!", { item: Item_NameMarked(item.id) });
    for (var i = 0; i < array_length(parts); i++) msg += " " + parts[i];
    res.msg = msg;
    return res;
}

// ---- text generated from the item data (D100): a plain sentence and number lines, so the screen can never disagree with the game ----
// "ATK +1, DEF +2" for the stat bonus an item gives, "" when it gives none.
function Item_BonusText(_item) {
    if (!is_struct(_item) || !variable_struct_exists(_item, "bonus") || !is_struct(_item.bonus)) return "";
    var b = _item.bonus;
    var parts = [];
    if (variable_struct_exists(b, "atk") && b.atk != 0) array_push(parts, "ATK " + ((b.atk > 0) ? "+" : "") + string(b.atk));
    if (variable_struct_exists(b, "def") && b.def != 0) array_push(parts, "DEF " + ((b.def > 0) ? "+" : "") + string(b.def));
    if (variable_struct_exists(b, "spd") && b.spd != 0) array_push(parts, "SPD " + ((b.spd > 0) ? "+" : "") + string(b.spd));
    if (variable_struct_exists(b, "mag") && b.mag != 0) array_push(parts, "MAG " + ((b.mag > 0) ? "+" : "") + string(b.mag));
    if (array_length(parts) <= 0) return "";
    var txt = parts[0];
    for (var i = 1; i < array_length(parts); i++) txt += ", " + parts[i];
    return txt;
}

// _ch (optional): the viewer. A heal or MP potion then says what it will really give that character (level scaling, Potion Lore); without one, the base number.
function Item_Sentence(_item, _ch = undefined) {
    if (!is_struct(_item) || !variable_struct_exists(_item, "id") || _item.id == 0) return "";
    if (Item_IsThrowable(_item)) {
        var u = _item.use;
        switch (_item.id) {
            case 30: return Loc_T("item.sent.30", "Hits for {power} power. Inflicts [t]Burn[/t] for {turns} turns. Costs your turn.", { power: string(u.power), turns: string(u.burn_turns) });
            case 31: return Loc_T("item.sent.31", "Inflicts {n} stacks of [t]Poison[/t]. Costs your turn.", { n: string(u.stacks) });
            case 32: return Loc_T("item.sent.32", "Hits for {power} power. [t]Stun[/t] and push back. Costs your turn.", { power: string(u.power) });
            case 33: return Loc_T("item.sent.33", "Dodge for {turns} turns. [a]Perfect[/a]: escape. Costs your turn.", { turns: string(u.evade_turns) });
        }
        return Loc_T("item.sent.throw", "Throw it at the enemy. Costs your turn.");
    }
    if (_item.type == ITEM_ACCESSORY) {
        var bonus = Item_BonusText(_item);
        if (bonus != "") return Loc_T("item.sent.accessory_stat", "Gives {bonus} while equipped.", { bonus: bonus });
        if (variable_struct_exists(_item, "passive_desc") && is_array(_item.passive_desc) && array_length(_item.passive_desc) > 1) return Loc_T("item.sent.accessory_passive", "While equipped: {line}.", { line: string(_item.passive_desc[1]) });
        return Loc_T("item.sent.accessory", "A ring or charm for the accessory slot.");
    }
    if (_item.type == ITEM_CONSUMABLE && variable_struct_exists(_item, "use")) {
        var us = _item.use;
        switch (us.effect) {
            case "heal": return Loc_T("item.sent.heal", "Restores {n} HP.", { n: string(Item_ShownAmount(_ch, us)) });   // D126: one number
            case "mp": return Loc_T("item.sent.mp", "Restores {n} MP.", { n: string(Item_ShownAmount(_ch, us)) });
            case "cure": return Loc_T("item.sent.cure", "Cures {status}.", { status: StatusDB_Get(us.status).name });
        }
    }
    if (_item.type == ITEM_WEAPON) return Loc_T("item.sent.weapon", "A weapon with {power} power.", { power: string(_item.power) });
    if (_item.type == ITEM_ARMOR) {
        var ab = Item_BonusText(_item);
        return Loc_T("item.sent.armor", "Armor: {bonus}.", { bonus: ab });
    }
    return string(_item.name);
}

// [{ label, value }] for the details panel. _ch is the viewer (a Nobody sees its own, stronger numbers).
function Item_NumberLines(_item, _ch) {
    var lines = [];
    if (!is_struct(_item) || !variable_struct_exists(_item, "id") || _item.id == 0) return lines;
    var nm = Throw_Mult(_ch);
    if (Item_IsThrowable(_item)) {
        var u = _item.use;
        if (u.power > 0) array_push(lines, { label: Loc_T("shop.lbl.power", "Power"), value: string(u.power) });
        if (u.burn_turns > 0) array_push(lines, { label: Loc_T("shop.lbl.burn", "Burn"), value: string(Throw_BurnBase(_ch)) + " x " + string(u.burn_turns) });
        if (u.stacks > 0) array_push(lines, { label: Loc_T("shop.lbl.poison", "Poison"), value: string(RoundHalfUp(u.stacks * nm)) });
        if (u.stun) array_push(lines, { label: Loc_T("shop.lbl.stun", "Stun"), value: Loc_T("shop.val.pushback", "Push Back") });
        if (u.evade_turns > 0) array_push(lines, { label: Loc_T("shop.lbl.evade", "Evasion"), value: Loc_T("shop.val.turns", "{n} turns", { n: string(RoundHalfUp(u.evade_turns * nm)) }) });
        if (u.escape) array_push(lines, { label: Loc_T("shop.lbl.perfect", "Perfect"), value: Loc_T("shop.val.escape", "Escape") });
        if (nm != 1) array_push(lines, { label: Loc_T("shop.lbl.nobody", "Nobody"), value: "x" + string_format(nm, 1, 1) });
        array_push(lines, { label: Loc_T("shop.lbl.carry", "Carry Limit"), value: string(Throw_Cap(_ch)) });
        return lines;
    }
    if (_item.type == ITEM_ACCESSORY) {
        var b = _item.bonus;
        if (b.atk != 0) array_push(lines, { label: Stat_ShortName(STAT_ATK), value: ((b.atk > 0) ? "+" : "") + string(b.atk) });
        if (b.def != 0) array_push(lines, { label: Stat_ShortName(STAT_DEF), value: ((b.def > 0) ? "+" : "") + string(b.def) });
        if (b.spd != 0) array_push(lines, { label: Stat_ShortName(STAT_SPD), value: ((b.spd > 0) ? "+" : "") + string(b.spd) });
        if (b.mag != 0) array_push(lines, { label: Stat_ShortName(STAT_MAG), value: ((b.mag > 0) ? "+" : "") + string(b.mag) });
        if (variable_struct_exists(_item, "passive_params")) {
            var pp = _item.passive_params;
            if (variable_struct_exists(pp, "damage_reduction")) array_push(lines, { label: Loc_T("shop.lbl.damage_taken", "Damage Taken"), value: "-" + string(round(pp.damage_reduction * 100)) + "%" });
            if (variable_struct_exists(pp, "mp_gain")) array_push(lines, { label: Loc_T("shop.lbl.mp", "MP"), value: Loc_T("shop.val.mp_every", "+{n} every {k} turns", { n: string(pp.mp_gain), k: string(pp.every_n_turns) }) });
            if (variable_struct_exists(pp, "gold_mult")) array_push(lines, { label: Loc_T("shop.lbl.gold", "Gold"), value: "+" + string(round(pp.gold_mult * 100)) + "%" });
        }
        return lines;
    }
    if (_item.type == ITEM_CONSUMABLE && variable_struct_exists(_item, "use")) {
        var us = _item.use;
        if (us.effect == "heal") array_push(lines, { label: Loc_T("shop.lbl.hp", "HP"), value: string(Item_ShownAmount(_ch, us)) });   // D126: the exact number the viewer gets
        else if (us.effect == "mp") array_push(lines, { label: Loc_T("shop.lbl.mp", "MP"), value: string(Item_ShownAmount(_ch, us)) });
        else if (us.effect == "cure") array_push(lines, { label: Loc_T("shop.lbl.cures", "Cures"), value: StatusDB_Get(us.status).name });
        return lines;
    }
    if (_item.type == ITEM_WEAPON) {
        array_push(lines, { label: Loc_T("shop.lbl.power", "Power"), value: string(_item.power) });
        array_push(lines, { label: Loc_T("shop.lbl.stat", "Uses"), value: Stat_ShortName(_item.stat_type) });
    }
    var ib = Item_BonusText(_item);
    if (_item.type == ITEM_ARMOR && ib != "") array_push(lines, { label: Loc_T("shop.lbl.bonus", "Bonus"), value: ib });
    return lines;
}
