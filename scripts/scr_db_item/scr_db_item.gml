function ItemDB_Init() {
    if (variable_global_exists("item_db") && ds_exists(global.item_db, ds_type_map)) {
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
        use: { effect: "heal", min: 5, max: 10, scale: 0.5, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: -1 },
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
    var sb0 = {
        id: 100,
        name: "Skillbook: Power Strike",
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
        use: { effect: "learn_skill", power: 0, status: -1, target: TGT_SELF, fx_sprite:noone, fx_frames:12, fx_speed:0.2, skill_id: SKILL_POWER_STRIKE },
        value: 25
    };
    ds_map_add(global.item_db, sb0.id, sb0);

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
        result.msg = "Can't use that.";
        return result;
    }

    var eff = item.use.effect;
    if (eff == "heal") {
        var before_hp = _target.hp;
        var amt = Item_ComputeAmount(_user, item.use);
        _target.hp = clamp(_target.hp + amt, 0, _target.max_hp);
        if (_target.hp == before_hp) {
            result.ok = false;
            result.msg = "No effect.";
        } else {
            result.msg = "Healed " + string(amt) + " HP.";
        }
    } else if (eff == "mp") {
        var before_mp = _target.mp;
        var amt2 = Item_ComputeAmount(_user, item.use);
        _target.mp = clamp(_target.mp + amt2, 0, _target.max_mp);
        if (_target.mp == before_mp) {
            result.ok = false;
            result.msg = "No effect.";
        } else {
            result.msg = "Recovered " + string(amt2) + " MP.";
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
            result.msg = cured_name + " cured.";
        } else {
            result.ok = false;
            result.msg = "No status to cure.";
        }
    } else if (eff == "learn_skill") {
        if (variable_struct_exists(item.use, "skill_id")) {
            var sk = item.use.skill_id;
            var already = false;
            if (is_array(_user.skills) && array_index_of(_user.skills, sk) != -1) already = true;
            if (already) {
                var s_cfg = SkillDB_Get(sk);
                result.ok = false;
                result.msg = "Already know " + s_cfg.name + ".";
            } else {
                _user = Player_LearnSkill(_user, sk);
                var s_cfg2 = SkillDB_Get(sk);
                result.msg = "Learned " + s_cfg2.name + ".";
            }
        }
    }

    return result;
}
