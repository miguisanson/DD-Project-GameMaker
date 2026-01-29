function EnemyDB_Init() {
    if (variable_global_exists("enemy_db") && ds_exists(global.enemy_db, ds_type_map)) {
        return;
    }

    global.enemy_db = ds_map_create();

    global.enemy_db[? ENEMY_SLIME] = {
        id: ENEMY_SLIME,
        name: "Slime",
        level: 1,
        stats: { str: 8, agi: 8, def: 8, intt: 6, luck: 6 },
        base_hp: 10,
        base_mp: 0,
        hd: 6,
        mp_gain: 0,
        weapon_id: 0,
        sprite: slime_profile,
        sprite_world: slime_moving,
        exp: 6,
        loot_key: "enemy_basic",
        ai: { scan_radius: 32, think_rate: 20, forget_delay: 15, leash_mult: 3, wander_chance: 4, move_speed: 1 },
        skills: [],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_DIREWOLF] = {
        id: ENEMY_DIREWOLF,
        name: "Dire Wolf",
        level: 3,
        stats: { str: 12, agi: 14, def: 10, intt: 6, luck: 8 },
        base_hp: 10,
        base_mp: 0,
        hd: 8,
        mp_gain: 0,
        weapon_id: 0,
        sprite: dire_wolf_profile,
        sprite_world: dire_wolf_moving,
        exp: 18,
        loot_key: "enemy_basic",
        ai: { scan_radius: 64, think_rate: 8, forget_delay: 45, leash_mult: 4, wander_chance: 2, move_speed: 1.2 },
        skills: [SKILL_POWER_STRIKE],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_GHOSTSWORD] = {
        id: ENEMY_GHOSTSWORD,
        name: "Ghost Sword",
        level: 4,
        stats: { str: 16, agi: 10, def: 12, intt: 8, luck: 10 },
        base_hp: 10,
        base_mp: 2,
        hd: 8,
        mp_gain: 1,
        weapon_id: 0,
        sprite: ghost_sword_profile,
        sprite_world: ghost_sword_moving,
        exp: 28,
        loot_key: "enemy_basic",
        ai: { scan_radius: 40, think_rate: 1, forget_delay: 60, leash_mult: 4, wander_chance: 0, move_speed: 3 },
        skills: [SKILL_POWER_STRIKE],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_MADWHISP] = {
        id: ENEMY_MADWHISP,
        name: "Mad Whisp",
        level: 4,
        stats: { str: 6, agi: 12, def: 8, intt: 16, luck: 12 },
        base_hp: 8,
        base_mp: 10,
        hd: 6,
        mp_gain: 2,
        weapon_id: 0,
        sprite: mad_whisp_profile,
        sprite_world: mad_whisp_moving,
        exp: 26,
        loot_key: "enemy_basic",
        ai: { scan_radius: 80, think_rate: 10, forget_delay: 75, leash_mult: 5, wander_chance: 1, move_speed: 1.3 },
        skills: [SKILL_FIREBALL],
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_SPIDER] = {
        id: ENEMY_SPIDER,
        name: "Spider",
        level: 2,
        stats: { str: 10, agi: 12, def: 10, intt: 6, luck: 10 },
        base_hp: 10,
        base_mp: 0,
        hd: 8,
        mp_gain: 0,
        weapon_id: 0,
        sprite: spider_profile,
        sprite_world: spider_moving,
        exp: 12,
        loot_key: "enemy_basic",
        ai: { scan_radius: 32, think_rate: 14, forget_delay: 30, leash_mult: 3, wander_chance: 3, move_speed: 1.1 },
        skills: [],
        traits: [],
        is_boss: false
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