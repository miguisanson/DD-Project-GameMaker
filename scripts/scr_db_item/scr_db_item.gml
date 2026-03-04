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
        power: 2,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: CLASS_KNIGHT,
        sprite: wooden_sword,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 4,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: CLASS_KNIGHT,
        sprite: iron_sword,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 6,
        stat_type: STAT_STR,
        acc: 1,
        preferred_class: CLASS_KNIGHT,
        sprite: platinum_sword,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 2,
        stat_type: STAT_AGI,
        acc: 1,
        preferred_class: CLASS_ARCHER,
        sprite: wooden_bow,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 4,
        stat_type: STAT_AGI,
        acc: 1,
        preferred_class: CLASS_ARCHER,
        sprite: iron_bow,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 6,
        stat_type: STAT_AGI,
        acc: 2,
        preferred_class: CLASS_ARCHER,
        sprite: platinum_bow,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 2,
        stat_type: STAT_INT,
        acc: 0,
        preferred_class: CLASS_MAGE,
        sprite: wooden_staff,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 4,
        stat_type: STAT_INT,
        acc: 0,
        preferred_class: CLASS_MAGE,
        sprite: ruby_staff,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        power: 6,
        stat_type: STAT_INT,
        acc: 1,
        preferred_class: CLASS_MAGE,
        sprite: diamond_staff,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: hp_potion,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: hp_potion,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: hp_potion,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: mp_potion,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: mp_potion,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: mp_potion,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: antidote,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: bandage,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "cure", power: 0, status: STATUS_BLEED, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 6
    };
    ds_map_add(global.item_db, c7.id, c7);

    // Skillbooks (one per skill, shared sprite)
    var sb1 = {
        id: 101,
        name: "Skillbook: Wound",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_WOUND },
        value: 25
    };
    ds_map_add(global.item_db, sb1.id, sb1);

    var sb2 = {
        id: 102,
        name: "Skillbook: Hilt Bash",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_HILT_BASH },
        value: 30
    };
    ds_map_add(global.item_db, sb2.id, sb2);

    var sb3 = {
        id: 103,
        name: "Skillbook: Muscle Up",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_MUSCLE_UP },
        value: 30
    };
    ds_map_add(global.item_db, sb3.id, sb3);

    var sb4 = {
        id: 104,
        name: "Skillbook: Rev Up",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_REV_UP },
        value: 30
    };
    ds_map_add(global.item_db, sb4.id, sb4);

    var sb5 = {
        id: 105,
        name: "Skillbook: Horizontal Slash",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_HORIZ_SLASH },
        value: 35
    };
    ds_map_add(global.item_db, sb5.id, sb5);

    var sb6 = {
        id: 106,
        name: "Skillbook: Poison Arrow",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_POISON_ARROW },
        value: 30
    };
    ds_map_add(global.item_db, sb6.id, sb6);

    var sb7 = {
        id: 107,
        name: "Skillbook: Evasion",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_EVASION },
        value: 28
    };
    ds_map_add(global.item_db, sb7.id, sb7);

    var sb8 = {
        id: 108,
        name: "Skillbook: Double Shot",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_DOUBLE_SHOT },
        value: 35
    };
    ds_map_add(global.item_db, sb8.id, sb8);

    var sb9 = {
        id: 109,
        name: "Skillbook: Take Aim",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_TAKE_AIM },
        value: 30
    };
    ds_map_add(global.item_db, sb9.id, sb9);

    var sb10 = {
        id: 110,
        name: "Skillbook: Fireball",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_FIREBALL },
        value: 35
    };
    ds_map_add(global.item_db, sb10.id, sb10);

    var sb11 = {
        id: 111,
        name: "Skillbook: Poison Mist",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_POISON_MIST },
        value: 35
    };
    ds_map_add(global.item_db, sb11.id, sb11);

    var sb12 = {
        id: 112,
        name: "Skillbook: Ice Spear",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_ICE_SPEAR },
        value: 40
    };
    ds_map_add(global.item_db, sb12.id, sb12);

    var sb13 = {
        id: 113,
        name: "Skillbook: Meditation",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_MEDITATION },
        value: 35
    };
    ds_map_add(global.item_db, sb13.id, sb13);

    var sb14 = {
        id: 114,
        name: "Skillbook: Foresight",
        type: ITEM_CONSUMABLE,
        stackable: false,
        max_stack: 1,
        equip_slot: "",
        power: 0,
        stat_type: STAT_STR,
        acc: 0,
        preferred_class: -1,
        sprite: skill_book,
        bonus: { str:0, agi:0, def:0, intt:0, luck:0 },
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_FORESIGHT },
        value: 35
    };
    ds_map_add(global.item_db, sb14.id, sb14);

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
        bonus: { str:0, agi:0, def:1, intt:0, luck:0 },
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
        bonus: { str:0, agi:0, def:2, intt:0, luck:0 },
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
        bonus: { str:0, agi:0, def:3, intt:0, luck:0 },
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
        stat_type: STAT_INT,
        acc: 0,
        preferred_class: CLASS_MAGE,
        allowed_classes: [CLASS_MAGE],
        sprite: cloth_robe,
        bonus: { str:0, agi:0, def:0, intt:1, luck:0 },
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
        stat_type: STAT_INT,
        acc: 0,
        preferred_class: CLASS_MAGE,
        allowed_classes: [CLASS_MAGE],
        sprite: silk_robe,
        bonus: { str:0, agi:0, def:0, intt:2, luck:0 },
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
        stat_type: STAT_INT,
        acc: 0,
        preferred_class: CLASS_MAGE,
        allowed_classes: [CLASS_MAGE],
        sprite: mithril_robe,
        bonus: { str:0, agi:0, def:0, intt:3, luck:0 },
        use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
        value: 60
    };
    ds_map_add(global.item_db, a5.id, a5);

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
    return { id: 0, name: Loc_T("item.name.0", "None"), type: ITEM_KEY, stackable: false, max_stack: 0, equip_slot: "", power: 0, stat_type: -1, acc: 0, preferred_class: -1, sprite: noone, bonus: { str:0, agi:0, def:0, intt:0, luck:0 }, use: { effect: "none", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 }, value: 0 };
}

function Item_LocalizeRuntime(_item) {
    if (!is_struct(_item)) return _item;

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
        case 1: return { id: "steady_strike", params: { once_per_turn: true }, desc: ["Steady Strike", "MISS->BAD, BAD->OKAY (1/turn)"] };
        case 2: return { id: "sunder_edge", params: { first_hit_def_down: 1, turns: 2 }, desc: ["Sunder Edge", "1st hit: -1 DEF for 2 turns"] };
        case 3: return { id: "executioner", params: { hp_ratio: 0.35, mult: 1.35 }, desc: ["Executioner", "+35% damage vs <35% HP"] };
        case 4: return { id: "aim_assist", params: { upgrade_good_to_perfect_once_per_turn: true }, desc: ["Aim Assist", "GOOD->PERFECT (1/turn)"] };
        case 5: return { id: "pinning_shot", params: { stun_chance: 0.15, stun_turns: 1, cooldown_turns: 3, requires_good_or_perfect: true }, desc: ["Pinning Shot", "GOOD+: may Stun (cd 3 turns)"] };
        case 6: return { id: "predator", params: { mult: 1.30, requires_target_statused: true }, desc: ["Predator", "+30% damage vs statused foes"] };
        case 7: return { id: "mana_trickle", params: { mp_gain: 1, every_n_turns: 2 }, desc: ["Mana Trickle", "+1 MP every 2 turns"] };
        case 8: return { id: "ember_lens", params: { skill_mult: 1.15, status_turn_bonus: 1 }, desc: ["Ember Lens", "+15% skill damage, +1 status turn"] };
        case 9: return { id: "arcane_surge", params: { skill_mult: 1.25, perfect_mp: 1 }, desc: ["Arcane Surge", "+25% skill damage, PERFECT +1 MP"] };

        // Armor
        case 20: return { id: "first_impact", params: { flat_reduction_first_hit: 3, once_per_battle: true }, desc: ["First Impact", "1st hit -3 damage (each battle)"] };
        case 21: return { id: "brace", params: { guard_mult_next_hit: 0.60, cooldown_turns: 2, triggers_on_take_damage: true }, desc: ["Brace", "After hit: next hit -40% (cd2)"] };
        case 22: return { id: "debt_plate", params: { big_hit_threshold: 6, big_hit_reduction: 0.30 }, desc: ["Debt Plate", "Big hits reduced by 30%"] };
        case 23: return { id: "thin_veil", params: { mp_gain: 1, every_n_turns: 2, physical_vuln_flat: 1 }, desc: ["Thin Veil", "+1 MP/2 turns, take +1 phys damage"] };
        case 24: return { id: "silk_flow", params: { skill_mult: 1.10, status_turn_bonus: 1 }, desc: ["Silk Flow", "+10% skill damage, +1 status turn"] };
        case 25: return { id: "mirror_stitch", params: { reflect_first_status_once_per_battle: true, mp_cost_on_trigger: 1 }, desc: ["Mirror Stitch", "Reflect 1st status (cost 1 MP)"] };
    }
    return { id: "", params: {}, desc: [] };
}

function ItemDB_AssignEquipPassives(_db) {
    if (!ds_exists(_db, ds_type_map)) return;
    var ids = [1,2,3,4,5,6,7,8,9,20,21,22,23,24,25];
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

function Item_IsSkillbook(_item_or_id) {
    var item = _item_or_id;
    if (!is_struct(item)) item = ItemDB_Get(_item_or_id);
    if (!is_struct(item)) return false;
    if (!Item_IsConsumable(item)) return false;
    if (!variable_struct_exists(item, "use") || !is_struct(item.use)) return false;
    if (!variable_struct_exists(item.use, "effect") || item.use.effect != "learn_skill") return false;
    if (!variable_struct_exists(item.use, "skill_id")) return false;
    return true;
}

function Item_SkillbookValidate(_item_or_id, _user) {
    var out = { ok: false, msg: Loc_T("item.msg.cant_use", "Can't use that."), skill_id: -1, skill_name: "" };
    var item = _item_or_id;
    if (!is_struct(item)) item = ItemDB_Get(_item_or_id);
    if (!Item_IsSkillbook(item)) return out;

    var skill_id = item.use.skill_id;
    var skill_cfg = SkillDB_Get(skill_id);
    var skill_name = Loc_T("item.msg.that_skill", "that skill");
    if (is_struct(skill_cfg) && variable_struct_exists(skill_cfg, "name")) {
        skill_name = string(skill_cfg.name);
    }

    out.skill_id = skill_id;
    out.skill_name = skill_name;

    if (!is_struct(_user) || !variable_struct_exists(_user, "class_id")) {
        out.msg = Loc_T("item.msg.cant_use", "Can't use that.");
        return out;
    }

    var class_id = _user.class_id;
    if (class_id == CLASS_NOBODY) {
        out.msg = Loc_T("item.msg.not_ready_skill", "You are not ready to learn this yet.");
        return out;
    }

    if (!Skill_ClassAllowed(skill_cfg, class_id)) {
        out.msg = Loc_T("item.msg.class_cannot_learn", "Your class cannot learn {skill}.", { skill: skill_name });
        return out;
    }

    var already_known = false;
    if (is_array(_user.skills)) {
        for (var si = 0; si < array_length(_user.skills); si++) {
            if (_user.skills[si] == skill_id) {
                already_known = true;
                break;
            }
        }
    }
    if (already_known) {
        out.msg = Loc_T("item.msg.already_know", "Already know {skill}.", { skill: skill_name });
        return out;
    }

    out.ok = true;
    out.msg = Loc_T("item.msg.learned", "Learned {skill}.", { skill: skill_name });
    return out;
}

function Item_ComputeAmount(_user, _use) {
    var minv = 0;
    var maxv = 0;

    if (variable_struct_exists(_use, "min")) minv = _use.min; else minv = _use.power;
    if (variable_struct_exists(_use, "max")) maxv = _use.max; else maxv = _use.power;
    if (maxv < minv) maxv = minv;

    var amt = (minv == maxv) ? minv : irandom_range(minv, maxv);

    if (is_struct(_user) && variable_struct_exists(_user, "level") && variable_struct_exists(_use, "scale")) {
        var lvl = max(0, _user.level - 1);
        amt += floor(lvl * _use.scale);
    }

    return amt;
}

function Item_Use(_item_id, _user, _target) {
    var item = ItemDB_Get(_item_id);
    var result = { ok: true, msg: "", fx_sprite: item.use.fx_sprite, fx_frames: item.use.fx_frames, fx_speed: item.use.fx_speed };

    if (!Item_IsConsumable(item)) {
        result.ok = false;
        result.msg = Loc_T("item.msg.cant_use", "Can't use that.");
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
    } else if (eff == "learn_skill") {
        var learn = Item_SkillbookValidate(item, _user);
        if (!learn.ok) {
            result.ok = false;
            result.msg = learn.msg;
            result.skillbook_first_read_dialogue = false;
        } else {
            _user = Player_LearnSkill(_user, learn.skill_id);
            result.msg = learn.msg;
            var class_id = CLASS_NOBODY;
            if (is_struct(_user) && variable_struct_exists(_user, "class_id")) class_id = _user.class_id;
            result.skillbook_first_read_dialogue = Dialogue_SkillbookFirstReadShouldTrigger(class_id);
        }
    }

    return result;
}
