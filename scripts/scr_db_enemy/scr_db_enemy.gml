function EnemyDB_Init() {
    if (variable_global_exists("enemy_db") && ds_exists(global.enemy_db, ds_type_map)) {
        return;
    }

    global.enemy_db = ds_map_create();

    global.enemy_db[? ENEMY_SLIME] = {
        id: ENEMY_SLIME,
        name: "Slime",
        level: 1,
        stats: { str: 8, agi: 9, def: 7, intt: 5, luck: 7 },
        base_hp: 9,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: slime_profile,
        sprite_world: slime_moving,
        exp: 8,
        species_min_level: 1,
        species_max_level: 1,
        species_level_offset: 0,
        threat_rank: 1,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.90,
        loot_key: "enemy_basic",
        ai: { scan_radius: 32, think_rate: 20, forget_delay: 15, leash_mult: 3, wander_chance: 4, move_speed: 1 },
        skills: [SKILL_SOLIDIFY],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_SPIDER] = {
        id: ENEMY_SPIDER,
        name: "Spider",
        level: 2,
        stats: { str: 8, agi: 10, def: 7, intt: 5, luck: 7 },
        base_hp: 10,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: spider_profile,
        sprite_world: spider_moving,
        exp: 8,
        species_min_level: 2,
        species_max_level: 3,
        species_level_offset: 0,
        threat_rank: 1,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.90,
        loot_key: "enemy_basic",
        ai: { scan_radius: 32, think_rate: 14, forget_delay: 30, leash_mult: 3, wander_chance: 3, move_speed: 1.1 },
        skills: [SKILL_POISON_FANGS],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_SNAKE] = {
        id: ENEMY_SNAKE,
        name: "Snake",
        level: 2,
        stats: { str: 9, agi: 10, def: 7, intt: 5, luck: 7 },
        base_hp: 10,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: snake_profile,
        sprite_world: snake_moving,
        exp: 10,
        species_min_level: 2,
        species_max_level: 4,
        species_level_offset: 0,
        threat_rank: 1,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.90,
        loot_key: "enemy_basic",
        ai: { scan_radius: 36, think_rate: 14, forget_delay: 30, leash_mult: 3, wander_chance: 3, move_speed: 1.1 },
        skills: [SKILL_BITE],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_MADWHISP] = {
        id: ENEMY_MADWHISP,
        name: "Mad Whisp",
        level: 5,
        stats: { str: 10, agi: 12, def: 9, intt: 13, luck: 10 },
        base_hp: 12,
        base_mp: 8,
        hd: 6,
        mp_gain: 2,
        weapon_id: 0,
        sprite: mad_whisp_profile,
        sprite_world: mad_whisp_moving,
        exp: 28,
        species_min_level: 5,
        species_max_level: 7,
        species_level_offset: 0,
        threat_rank: 2,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.75,
        loot_key: "enemy_mid",
        ai: { scan_radius: 80, think_rate: 10, forget_delay: 75, leash_mult: 5, wander_chance: 1, move_speed: 1.3 },
        skills: [SKILL_SCORCHING_TOUCH],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_KILLER_PLANT] = {
        id: ENEMY_KILLER_PLANT,
        name: "Killer Plant",
        level: 4,
        stats: { str: 12, agi: 9, def: 11, intt: 10, luck: 8 },
        base_hp: 14,
        base_mp: 6,
        hd: 8,
        mp_gain: 1,
        weapon_id: 0,
        sprite: killer_plant_profile,
        sprite_world: killer_plant_moving,
        exp: 20,
        species_min_level: 4,
        species_max_level: 6,
        species_level_offset: 0,
        threat_rank: 2,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.75,
        loot_key: "enemy_mid",
        ai: { scan_radius: 44, think_rate: 12, forget_delay: 45, leash_mult: 3, wander_chance: 2, move_speed: 1 },
        skills: [SKILL_VINE_TRAP],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_DIREWOLF] = {
        id: ENEMY_DIREWOLF,
        name: "Dire Wolf",
        level: 3,
        stats: { str: 11, agi: 11, def: 9, intt: 6, luck: 8 },
        base_hp: 12,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: dire_wolf_profile,
        sprite_world: dire_wolf_moving,
        exp: 14,
        species_min_level: 3,
        species_max_level: 5,
        species_level_offset: 0,
        threat_rank: 1,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.85,
        loot_key: "enemy_mid",
        ai: { scan_radius: 64, think_rate: 8, forget_delay: 45, leash_mult: 4, wander_chance: 2, move_speed: 1.2 },
        skills: [SKILL_BLOODTHIRSTY],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_GHOSTSWORD] = {
        id: ENEMY_GHOSTSWORD,
        name: "Ghost Sword",
        level: 6,
        stats: { str: 14, agi: 12, def: 12, intt: 10, luck: 11 },
        base_hp: 14,
        base_mp: 4,
        hd: 8,
        mp_gain: 1,
        weapon_id: 0,
        sprite: ghost_sword_profile,
        sprite_world: ghost_sword_moving,
        exp: 38,
        species_min_level: 6,
        species_max_level: 8,
        species_level_offset: 0,
        threat_rank: 2,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.70,
        loot_key: "enemy_mid",
        ai: { scan_radius: 40, think_rate: 1, forget_delay: 60, leash_mult: 4, wander_chance: 0, move_speed: 3 },
        skills: [SKILL_GHOST_CUT],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_STRANGER] = {
        id: ENEMY_STRANGER,
        name: "Stranger",
        level: 7,
        stats: { str: 16, agi: 13, def: 14, intt: 15, luck: 12 },
        base_hp: 16,
        base_mp: 8,
        hd: 8,
        mp_gain: 2,
        weapon_id: 0,
        sprite: stranger_profile,
        sprite_world: stranger_moving,
        exp: 50,
        species_min_level: 7,
        species_max_level: 9,
        species_level_offset: 0,
        threat_rank: 2,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.65,
        loot_key: "enemy_elite",
        ai: { scan_radius: 88, think_rate: 8, forget_delay: 80, leash_mult: 5, wander_chance: 1, move_speed: 1.3 },
        skills: [SKILL_STEAL],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_MINI_BOSS] = {
        id: ENEMY_MINI_BOSS,
        name: "Mini Boss",
        level: 8,
        stats: { str: 18, agi: 12, def: 16, intt: 14, luck: 12 },
        base_hp: 22,
        base_mp: 8,
        hd: 10,
        mp_gain: 2,
        weapon_id: 0,
        sprite: mini_boss_profile,
        sprite_world: mini_boss_moving,
        exp: 75,
        species_min_level: 8,
        species_max_level: 9,
        species_level_offset: 0,
        threat_rank: 3,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 1.00,
        loot_key: "enemy_boss",
        ai: { scan_radius: 64, think_rate: 8, forget_delay: 60, leash_mult: 4, wander_chance: 2, move_speed: 1.15 },
        skills: [SKILL_RAMMING, SKILL_RAMPAGE],
        traits: [],
        is_boss: true
    };

    global.enemy_db[? ENEMY_FINAL_BOSS] = {
        id: ENEMY_FINAL_BOSS,
        name: "Final Boss",
        level: 10,
        stats: { str: 21, agi: 14, def: 18, intt: 19, luck: 14 },
        base_hp: 30,
        base_mp: 12,
        hd: 10,
        mp_gain: 3,
        weapon_id: 0,
        sprite: final_boss_profile,
        sprite_world: final_boss_moving,
        exp: 110,
        species_min_level: 10,
        species_max_level: 10,
        species_level_offset: 0,
        threat_rank: 4,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 1.00,
        loot_key: "enemy_boss",
        ai: { scan_radius: 0, think_rate: 30, forget_delay: 0, leash_mult: 1, wander_chance: 0, move_speed: 1 },
        skills: [SKILL_CURSE, SKILL_BLESSING, SKILL_FINAL_FURY],
        traits: [],
        is_boss: true
    };

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.enemy_db = global.enemy_db;
    }
}

function EnemyDB_Get(_enemy_id) {
    if (!variable_global_exists("enemy_db") || !ds_exists(global.enemy_db, ds_type_map)) {
        EnemyDB_Init();
    }
    if (ds_map_exists(global.enemy_db, _enemy_id)) {
        return global.enemy_db[? _enemy_id];
    }

    return {
        id: -1,
        name: "Unknown",
        level: 1,
        stats: { str: 10, agi: 10, def: 10, intt: 10, luck: 10 },
        base_hp: 10,
        base_mp: 0,
        hd: 6,
        mp_gain: 0,
        weapon_id: 0,
        sprite: slime_profile,
        sprite_world: noone,
        exp: 1,
        species_min_level: 1,
        species_max_level: LEVEL_CAP_TECHNICAL,
        species_level_offset: 0,
        threat_rank: 1,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.85,
        loot_key: "enemy_basic",
        ai: { scan_radius: ENEMY_SCAN_RADIUS_DEFAULT, think_rate: 15, forget_delay: 30, leash_mult: 2, wander_chance: 4, move_speed: 1 },
        skills: [],
        traits: [],
        is_boss: false
    };
}

function DB_Enemy(_enemy_id) {
    return EnemyDB_Get(_enemy_id);
}
