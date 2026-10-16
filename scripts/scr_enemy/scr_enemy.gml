function Enemy_ZoneLevelForRoom(_room) {
    switch (_room) {
        case rm_floor1: return 1;
        case rm_floor2: return 2;
        case rm_floor3: return 3;
        case rm_floor4: return 4;
        case rm_floor5: return 5;
        case rm_floor6: return 6;
        case rm_floor6_5: return 6;
        case rm_floor7: return 7;
        case rm_floor8: return 8;
        case rm_floor9: return 9;
        case rm_floor9_5: return 10;
    }
    return 1;
}

function Enemy_ResolveLevel(_cfg, _room) {
    if (!is_struct(_cfg)) return 1;

    var min_lvl = variable_struct_exists(_cfg, "species_min_level") ? max(1, round(_cfg.species_min_level)) : max(1, round(_cfg.level));
    var max_lvl = variable_struct_exists(_cfg, "species_max_level") ? max(min_lvl, round(_cfg.species_max_level)) : max(min_lvl, round(_cfg.level));
    max_lvl = min(max_lvl, LEVEL_CAP_TECHNICAL);

    if (variable_struct_exists(_cfg, "is_boss") && _cfg.is_boss) {
        return clamp(round(_cfg.level), min_lvl, max_lvl);
    }

    var zone_level = Enemy_ZoneLevelForRoom(_room);
    var offset = variable_struct_exists(_cfg, "species_level_offset") ? round(_cfg.species_level_offset) : 0;
    var roll = RunRng_Range("enemy", -1, 1);
    var lvl = zone_level + roll + offset;
    return clamp(lvl, min_lvl, max_lvl);
}

function Enemy_CanAutoResolve(_cfg, _player_level, _enemy_level) {
    if (!is_struct(_cfg)) return false;
    if (variable_struct_exists(_cfg, "is_boss") && _cfg.is_boss) return false;
    if (!variable_struct_exists(_cfg, "can_auto_resolve") || !_cfg.can_auto_resolve) return false;
    if (variable_struct_exists(_cfg, "threat_rank") && _cfg.threat_rank > 1) return false;
    return (_player_level >= _enemy_level + ENEMY_AUTO_RESOLVE_LEVEL_DELTA);
}

function Enemy_AutoResolveBuildMessage(_cfg, _result, _verb_prefix = undefined) {
    if (is_undefined(_verb_prefix)) _verb_prefix = Loc_T("combat.msg.overpower_prefix", "You overpower {enemy}.");   // D9: Korean has its own wording
    var enemy_name = "";
    if (is_struct(_cfg) && variable_struct_exists(_cfg, "name")) enemy_name = string(_cfg.name);
    if (enemy_name == "") enemy_name = Loc_T("enemy.name.unknown", "Enemy");

    var prefix_template = string(_verb_prefix);
    var msg = "";
    if (string_pos("{enemy}", prefix_template) > 0) {
        msg = string_replace_all(prefix_template, "{enemy}", enemy_name);
    } else {
        var prefix = string_replace_all(prefix_template, "\n", " ");
        while (string_length(prefix) > 0 && string_char_at(prefix, 1) == " ") {
            prefix = string_delete(prefix, 1, 1);
        }
        while (string_length(prefix) > 0 && string_char_at(prefix, string_length(prefix)) == " ") {
            prefix = string_delete(prefix, string_length(prefix), 1);
        }
        if (prefix == "") msg = enemy_name;
        else msg = prefix + " " + enemy_name;
    }

    var msg_len = string_length(msg);
    if (msg_len > 0) {
        var tail = string_char_at(msg, msg_len);
        if (tail != "." && tail != "!" && tail != "?") msg += ".";
    } else {
        msg = enemy_name + ".";
    }

    if (!is_struct(_result)) return msg;

    var parts = [];
    if (variable_struct_exists(_result, "exp_gain") && _result.exp_gain > 0) {
        array_push(parts, Loc_T("combat.msg.exp_gain", "(+{exp} EXP)", { exp: _result.exp_gain }));
    }
    if (variable_struct_exists(_result, "gold_gain") && _result.gold_gain > 0) {   // C3 (D23)
        array_push(parts, Loc_T("combat.msg.gold_gain", "(+{gold} gold)", { gold: _result.gold_gain }));
    }

    var levels = (variable_struct_exists(_result, "levels_gained")) ? max(0, round(real(_result.levels_gained))) : 0;
    var stat_points = (variable_struct_exists(_result, "stat_points_gained")) ? max(0, round(real(_result.stat_points_gained))) : 0;
    if (levels > 0) {
        var lvl_msg = Loc_T("combat.msg.level_up", "Level up x{levels}!", { levels: levels });
        // D143: the class's automatic gains are shown on the level-up screen (LevelUp_GrowthText), no longer listed here
        if (stat_points == 1) lvl_msg += " (" + Loc_T("combat.msg.stat_point_one", "+{n} stat point", { n: stat_points }) + ")";
        else if (stat_points > 1) lvl_msg += " (" + Loc_T("combat.msg.stat_points_many", "+{n} stat points", { n: stat_points }) + ")";
        array_push(parts, lvl_msg);
    } else if (variable_struct_exists(_result, "at_level_cap") && _result.at_level_cap) {
        array_push(parts, Loc_T("combat.msg.max_level", "Max level reached."));
    }

    if (variable_struct_exists(_result, "loot_gained") && _result.loot_gained) {
        array_push(parts, Loc_T("combat.msg.loot_gained", "Loot gained."));
    }

    if (array_length(parts) <= 0) return msg;
    msg += " ";
    for (var i = 0; i < array_length(parts); i++) {
        if (i > 0) msg += " ";
        msg += parts[i];
    }
    return msg;
}

function Enemy_AutoResolveFinalize(_enemy_id, _enemy_level, _loot_key, _enemy_name) {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return { message: "", loot_entries: [] };
    var p = gs.player_ch;
    var cfg = EnemyDB_Get(_enemy_id);
    Codex_RecordMeeting(_enemy_id, false);   // D88: the bestiary

    var exp_mult = variable_struct_exists(cfg, "auto_resolve_exp_mult") ? max(0, real(cfg.auto_resolve_exp_mult)) : ENEMY_AUTO_RESOLVE_EXP_MULT_DEFAULT;
    var loot_mult = variable_struct_exists(cfg, "auto_resolve_loot_mult") ? clamp(real(cfg.auto_resolve_loot_mult), 0, 1) : ENEMY_AUTO_RESOLVE_LOOT_MULT_DEFAULT;
    var diff = Difficulty_Profile();   // D35: only player_exp_mult (1) is left
    var at_cap_before = Level_IsAtCap(p.level);

    var level_exp_mult = 1;
    if (variable_struct_exists(cfg, "level")) {
        level_exp_mult = clamp(1 + ((_enemy_level - round(cfg.level)) * 0.10), 0.70, 1.40);
    }
    var exp_gain = 0;
    if (!Level_IsAtCap(p.level)) {
        exp_gain = max(1, round(real(cfg.exp) * level_exp_mult * exp_mult));
        if (is_struct(diff) && variable_struct_exists(diff, "player_exp_mult")) {
            exp_gain = max(1, round(exp_gain * max(0, real(diff.player_exp_mult))));
        }
        p = Player_AddExp(p, exp_gain);
    } else {
        p.last_levels_gained = 0;
        p.last_stat_points_gained = 0;
        p.last_auto_stat_gained = 0;
    }

    var run_ar = Run_Get();
    var dry_before = (is_struct(run_ar) && run_ar.active) ? run_ar.drop_dry : 0;
    var loot = Loot_RollEnemy({ id: _enemy_id, level: _enemy_level, loot_key: _loot_key });
    if (loot_mult < 1 && is_array(loot)) {
        var kept = [];
        for (var i = 0; i < array_length(loot); i++) {
            if (RunRng_Float("loot") <= loot_mult) array_push(kept, loot[i]);
        }
        // R1 (D120): an item thinned away here was never received, so the fight still counts as a dry one
        if (array_length(loot) > 0 && array_length(kept) == 0 && is_struct(run_ar) && run_ar.active) run_ar.drop_dry = dry_before + 1;
        loot = kept;
    }
    p.inventory = Loot_Grant(p.inventory, loot);
    p = Card_OnVictory(p);   // C2: Field Medic, Second Wind, Scrounger
    var gold_gain = Gold_ForEnemy(Run_Stream("loot"), { level: _enemy_level, threat_rank: variable_struct_exists(cfg, "threat_rank") ? cfg.threat_rank : 1, is_boss: false, is_elite: false }, p);   // C3 (D23)
    Gold_Add(Run_Get(), gold_gain);
    GameState_SetPlayer(p);

    var result = {
        exp_gain: exp_gain,
        levels_gained: variable_struct_exists(p, "last_levels_gained") ? max(0, round(real(p.last_levels_gained))) : 0,
        stat_points_gained: variable_struct_exists(p, "last_stat_points_gained") ? max(0, round(real(p.last_stat_points_gained))) : 0,
        auto_stat_summary: LevelUp_AutoGainSummary(p),
        gold_gain: gold_gain,
        loot_gained: is_array(loot) && array_length(loot) > 0,
        at_level_cap: at_cap_before || Level_IsAtCap(p.level)
    };

    Dialogue_NarrativeOnLevelUp(result.levels_gained);
    Dialogue_NarrativeOnEnemyDefeated(_enemy_id, room);

    if (variable_struct_exists(cfg, "name")) _enemy_name = cfg.name;
    var summary = Enemy_AutoResolveBuildMessage({ name: _enemy_name }, result);
    var loot_entries = Loot_BuildMessageEntries(loot, Loc_T("combat.msg.loot_prefix", "Loot: "));
    return {
        message: summary,
        loot_entries: loot_entries
    };
}

function Enemy_AutoResolveFinalizePending() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "auto_resolve_pending") || !is_struct(gs.auto_resolve_pending)) return;
    var pending = gs.auto_resolve_pending;
    gs.auto_resolve_pending = undefined;

    var enemy_id = variable_struct_exists(pending, "enemy_id") ? pending.enemy_id : -1;
    if (enemy_id < 0) return;
    var enemy_level = variable_struct_exists(pending, "enemy_level") ? max(1, round(real(pending.enemy_level))) : 1;
    var loot_key = variable_struct_exists(pending, "loot_key") ? pending.loot_key : "";
    var enemy_name = variable_struct_exists(pending, "enemy_name") ? string(pending.enemy_name) : "Enemy";
    var enemy_inst = variable_struct_exists(pending, "enemy_inst") ? pending.enemy_inst : noone;
    var player_inst = variable_struct_exists(pending, "player_inst") ? pending.player_inst : noone;
    var persist_id = variable_struct_exists(pending, "persist_id") ? string(pending.persist_id) : "";

    var final = Enemy_AutoResolveFinalize(enemy_id, enemy_level, loot_key, enemy_name);
    var msg = "";
    if (is_struct(final) && variable_struct_exists(final, "message")) msg = string(final.message);

    if (persist_id != "") {
        RoomState_Save(room);   // D33: the others keep their place, type and elite; unsaved they would be dealt again with one slot fewer after a Continue
        RoomState_SetRemoved(room, persist_id, obj_enemy, enemy_id);
    }
    if (instance_exists(enemy_inst)) {
        instance_destroy(enemy_inst);
    }

    if (!instance_exists(player_inst) && instance_exists(obj_player)) {
        player_inst = instance_find(obj_player, 0);
    }
    if (instance_exists(player_inst)) {
        Player_StartAutoResolveRecover(player_inst, ENEMY_AUTO_RESOLVE_RECOVER_FRAMES);
    }

    if (msg != "") {
        var lines = [msg];
        if (is_struct(final) && variable_struct_exists(final, "loot_entries") && is_array(final.loot_entries)) {
            for (var li = 0; li < array_length(final.loot_entries); li++) {
                array_push(lines, final.loot_entries[li]);
            }
        }
        Dialogue_StartLines(lines);
    }
}

function Enemy_AutoResolveEncounter(_enemy_inst, _player_inst) {
    if (!instance_exists(_enemy_inst) || !instance_exists(_player_inst)) return false;
    if (!variable_instance_exists(_enemy_inst, "enemy_id")) return false;

    var cfg = EnemyDB_Get(_enemy_inst.enemy_id);
    var enemy_level = (variable_instance_exists(_enemy_inst, "enemy_level") ? _enemy_inst.enemy_level : cfg.level);
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return false;
    var p = gs.player_ch;

    if (!Enemy_CanAutoResolve(cfg, p.level, enemy_level)) return false;
    if (variable_instance_exists(_enemy_inst, "elite_mod") && _enemy_inst.elite_mod != "") return false;   // C3 (D86): an elite is always fought (its card pick)
    if (!RoomState_EnsurePersistId(_enemy_inst)) return false;

    if (variable_instance_exists(_enemy_inst, "moving")) _enemy_inst.moving = false;
    if (variable_instance_exists(_enemy_inst, "move_timer")) _enemy_inst.move_timer = 0;
    if (variable_instance_exists(_enemy_inst, "move_dir")) _enemy_inst.move_dir = -1;
    if (variable_instance_exists(_enemy_inst, "ai_state")) _enemy_inst.ai_state = ENEMY_IDLE;
    if (variable_instance_exists(_enemy_inst, "forget_time")) _enemy_inst.forget_time = 0;

    if (variable_instance_exists(_player_inst, "moving")) _player_inst.moving = false;
    if (variable_instance_exists(_player_inst, "move_timer")) _player_inst.move_timer = 0;
    if (variable_instance_exists(_player_inst, "move_dir")) _player_inst.move_dir = -1;

    // Encounter interruptions can happen while a modal is open (inventory/pause/save).
    // Force-close all UI modals and let the shared modal root fade the dim out cleanly.
    UI_InterruptCloseAll(true);

    gs.auto_resolve_pending = {
        enemy_inst: _enemy_inst,
        player_inst: _player_inst,
        enemy_id: _enemy_inst.enemy_id,
        enemy_level: enemy_level,
        loot_key: variable_struct_exists(cfg, "loot_key") ? cfg.loot_key : "",
        enemy_name: variable_struct_exists(cfg, "name") ? cfg.name : "Enemy",
        persist_id: variable_instance_exists(_enemy_inst, "persist_id") ? string(_enemy_inst.persist_id) : ""
    };

    var ok = Transition_RequestBlackFlash(
        TRANSITION_FLASH_FADE_OUT_FRAMES,
        TRANSITION_FLASH_FADE_IN_FRAMES,
        -1,
        "auto_resolve"
    );
    if (!ok) {
        gs.auto_resolve_pending = undefined;
        return false;
    }

    return true;
}

function EnemyCreate(_enemy_id) {
    var base = EnemyDB_Get(_enemy_id);
    var gs = GameState_Get();

    // build battle character struct
    var ch = {};
    ch.id = base.id;
    ch.name = base.name;
    var resolved_level = base.level;
    if (is_struct(gs) && variable_struct_exists(gs, "battle") && is_struct(gs.battle)
    && variable_struct_exists(gs.battle, "enemy_level") && gs.battle.enemy_level > 0) {
        resolved_level = gs.battle.enemy_level;
    }
    var min_lvl = variable_struct_exists(base, "species_min_level") ? max(1, round(base.species_min_level)) : max(1, round(base.level));
    var max_lvl = variable_struct_exists(base, "species_max_level") ? max(min_lvl, round(base.species_max_level)) : max(min_lvl, round(base.level));
    ch.level = clamp(round(resolved_level), min_lvl, max_lvl);
    ch.is_player = false;

    // copy stats (keep same keys you use everywhere)
    ch.stats = {
        atk: max(1, round(base.stats.atk)),
        def: max(1, round(base.stats.def)),
        spd: max(1, round(base.stats.spd)),
        mag: max(1, round(base.stats.mag))
    };
    ch.basic_power = base.basic_power;

    ch.base_hp = base.base_hp;
    ch.base_mp = base.base_mp;
    ch.hd = base.hd;
    ch.mp_gain = base.mp_gain;

    // Spec section 6: no stat adds HP (the old DEF bonus is folded into base_hp); one difficulty, no multipliers (D35).
    var hp_gain = ceil(ch.hd / 2) + 1;
    ch.max_hp = max(1, ch.base_hp + (ch.level - 1) * hp_gain);
    ch.max_mp = max(0, ch.base_mp + (ch.level - 1) * ch.mp_gain);

    // current resources start full
    ch.hp = ch.max_hp;
    ch.mp = ch.max_mp;

    // weapon & sprite (important!)
    ch.weapon_id = base.weapon_id;
    ch.sprite = base.sprite;
    var exp_mult = clamp(1 + ((ch.level - base.level) * 0.10), 0.70, 1.40);
    ch.exp = max(1, round(base.exp * exp_mult));
    ch.skills = base.skills;
    ch.status = [];
    ch.is_boss = base.is_boss;
    ch.brain = variable_struct_exists(base, "brain") ? base.brain : AI_Brain([], [ AI_Weight("attack", -1, 1) ]);   // B4: the battle AI's rules (read only; a phase changes the stats above, not this)
    ch.threat_rank = variable_struct_exists(base, "threat_rank") ? base.threat_rank : 1;
    ch.stagger_max = Stagger_Max(ch.threat_rank, ch.is_boss);   // spec section 11: the BREAK meter
    ch.stagger = 0;
    ch.broken = false;

    return ch;
}

function Enemy_ApplyConfig(_inst) {
    if (_inst.enemy_id == -1) return;

    var cfg = EnemyDB_Get(_inst.enemy_id);
    _inst.enemy_cfg = cfg;
    if (!variable_instance_exists(_inst, "enemy_level") || _inst.enemy_level <= 0) {
        _inst.enemy_level = Enemy_ResolveLevel(cfg, room);
    }

    if (is_struct(cfg) && variable_struct_exists(cfg, "ai")) {
        var ai = cfg.ai;
        if (variable_struct_exists(ai, "scan_radius")) _inst.scan_radius = ai.scan_radius;
        if (variable_struct_exists(ai, "think_rate")) _inst.think_rate = ai.think_rate;
        if (variable_struct_exists(ai, "forget_delay")) _inst.forget_delay = ai.forget_delay;
        if (variable_struct_exists(ai, "leash_mult")) _inst.leash_mult = ai.leash_mult;
        if (variable_struct_exists(ai, "wander_chance")) _inst.wander_chance = ai.wander_chance;
        if (variable_struct_exists(ai, "move_speed")) _inst.move_speed = ai.move_speed;
    }

    if (is_struct(cfg) && variable_struct_exists(cfg, "sprite_world") && cfg.sprite_world != noone) {
        _inst.sprite_index = cfg.sprite_world;
    }

    _inst.leash_radius = _inst.scan_radius * _inst.leash_mult;
    _inst.think_delay = irandom(_inst.think_rate);
}

// C3 (D33): an enemy whose type was changed by the run's shuffle (or restored with a changed type) takes the new type's sprite, AI numbers and profile.
function Enemy_ReapplyConfig(_inst) {
    if (!variable_instance_exists(_inst, "enemy_id") || _inst.enemy_id == -1) return;
    Enemy_ApplyConfig(_inst);
    if (variable_instance_exists(_inst, "prof")) {   // the AI had started already: its profile follows the type
        _inst.prof = EnemyAI_Profile(_inst.enemy_id);
        _inst.step_tx = _inst.x;
        _inst.step_ty = _inst.y;
        _inst.patrol_cx = -1;
        _inst.patrol_cy = -1;
        _inst.home_cx = Nav_CellOf(Grid_Snap(_inst.home_x) + GRID_TILE_SIZE / 2);
        _inst.home_cy = Nav_CellOf(Grid_Snap(_inst.home_y) + GRID_TILE_SIZE / 2);
    }
}

// --------------------
// ENEMY AI
// --------------------
function EnemyAI_ApplyTraits(_inst, _cfg, _ctx, _hook) {
    if (!is_struct(_cfg) || !variable_struct_exists(_cfg, "traits")) return;

    var traits = _cfg.traits;
    if (!is_array(traits)) return;

    var count = array_length(traits);
    for (var i = 0; i < count; i++) {
        var t = traits[i];
        if (!is_struct(t) || !variable_struct_exists(t, _hook)) continue;
        var fn = t[_hook];
        if (is_callable(fn)) fn(_inst, _cfg, _ctx);
    }
}

// True when the whole 16 px tile one step away is free (wall, interactable, exit tile), tested with the enemy's own mask.
function EnemyAI_CanStep(_inst, _mx, _my) {
    return Grid_TileFree(_inst, _inst.x + _mx * GRID_TILE_SIZE, _inst.y + _my * GRID_TILE_SIZE);
}

// ----------------------------------------------------------------------------
// Per-type overworld personality (D63 sight, D66 idle personalities, D67 chase speed). Data, not code paths.
// Speeds are pixels per frame; the player walks at 1 and runs at 2, so chase < 1 means "you can walk away" and wolves (1.0) keep up.
//   sight       tiles; an enemy notices the player inside a 90 degree CONE in front of it (D179) of this radius, when nothing that blocks sight is between (see_through ignores walls
//               and props), and always within 1 tile all round it. 3 for every enemy, 4 for the dire wolf and the mad whisp.
//   chase       speed while chasing / walking to the last seen spot
//   idle        "wander" (pause, one step, pause), "drift" (steps almost without pause), "patrol" (walks legs to far spots),
//               "still" (ambusher: stays on its post)
//   idle_speed  speed while idling;  pause_min..pause_max frames between idle steps;  roam tiles from home
//   search      the time it spends looking: a third of it at the last seen cell and a third again before it gives up (D153);  react frames between spotting the player and moving
//   pass        true = ignores walls and objects (ghosts), only the room edge stops it
//   fixed       true = never moves (bosses): the old square-trigger rules still apply to ai_stationary enemies
// The numbers are first guesses for the owner to tune by playing (reported in the packet notes).
// ----------------------------------------------------------------------------
function EnemyAI_Profile(_enemy_id) {
    var _p = { sight: 3, chase: 0.8, idle: "wander", idle_speed: 0.6, pause_min: 40, pause_max: 100, roam: 3,
               search: 90, react: 14, pass: false, see_through: false, fixed: false, ret_speed: 0.8 };
    switch (_enemy_id) {
        case ENEMY_SLIME:        _p.chase = 0.7;  _p.idle_speed = 0.4; _p.pause_min = 60; _p.pause_max = 140; _p.roam = 2; _p.ret_speed = 0.6; break;
        case ENEMY_SPIDER:       _p.chase = 0.85; _p.idle_speed = 0.8; _p.pause_min = 25; _p.pause_max = 70; break;
        case ENEMY_SNAKE:        _p.chase = 0.85; _p.idle_speed = 0.7; _p.pause_min = 30; _p.pause_max = 80; break;
        case ENEMY_MADWHISP:     _p.sight = 4; _p.chase = 0.85; _p.idle = "drift"; _p.idle_speed = 0.5; _p.pause_min = 0; _p.pause_max = 8; _p.roam = 4; break;
        case ENEMY_KILLER_PLANT: _p.chase = 0.8; _p.idle = "still"; _p.roam = 0; _p.search = 60; _p.react = 20; break;
        case ENEMY_DIREWOLF:     _p.sight = 4; _p.chase = 1.0; _p.idle = "patrol"; _p.idle_speed = 0.9; _p.pause_min = 20; _p.pause_max = 50; _p.roam = 5; _p.react = 8; _p.ret_speed = 0.9; break;
        case ENEMY_GHOSTSWORD:   _p.chase = 0.85; _p.idle = "drift"; _p.idle_speed = 0.6; _p.pause_min = 0; _p.pause_max = 10; _p.roam = 4; _p.pass = true; _p.see_through = true; break;
        case ENEMY_STRANGER:     _p.chase = 0.9; _p.idle_speed = 0.7; _p.pause_min = 40; _p.pause_max = 90; _p.react = 20; break;
        case ENEMY_MINI_BOSS:
        case ENEMY_FINAL_BOSS:   _p.sight = 0; _p.idle = "still"; _p.roam = 0; _p.fixed = true; break;
    }
    return _p;
}

// ----------------------------------------------------------------------------
// Room integration of the pure Nav code: one grid and one reservation table per loaded room, built lazily from the instances.
// Rebuilt when a blocker appears or disappears (barrel broken, chest opened and replaced). Nothing hooks into the game controller.
// ----------------------------------------------------------------------------
function Nav_MarkInstance(_g, _block, _sight, _exit = false) {
    // runs in the scope of the instance being marked
    var _t = GRID_TILE_SIZE;
    var _x0 = floor(bbox_left / _t);
    var _x1 = floor((bbox_right - 0.01) / _t);
    var _y0 = floor(bbox_top / _t);
    var _y1 = floor((bbox_bottom - 0.01) / _t);
    for (var _cx = _x0; _cx <= _x1; _cx++) {
        for (var _cy = _y0; _cy <= _y1; _cy++) {
            Nav_GridSet(_g, _cx, _cy, _block, _sight);
            if (_exit && Nav_GridInside(_g, _cx, _cy)) Nav_GridAddExit(_g, _cx, _cy);
        }
    }
}

// D179 (R-098): what blocks sight. ONE list for the whole game (the room grid and the checks both ask here). Walls, trees, stumps, rocks, barrels (whole or broken),
// chests (closed or open), graves and tall grass / bushes do. Everything else a room holds does not: torches and fire stands (lit or out), skulls, bones, dung,
// NPCs, doors, switches and beds, and any plain obj_interactable. _obj is an object index (a child counts as its parent).
function Sight_BlocksObject(_obj) {
    static _list = [obj_wall, obj_tree_1, obj_tree_2, obj_tree_stump1, obj_tree_stump2, obj_rock1, obj_rock2, obj_barrel, obj_barrel_broken,
                    obj_chest, obj_chest_opened, obj_grave, obj_tall_grass];
    for (var _i = 0; _i < array_length(_list); _i++) {
        if (_obj == _list[_i] || object_is_ancestor(_obj, _list[_i])) return true;
    }
    return false;
}

function Nav_BuildGrid() {
    var _g = Nav_GridCreate(ceil(room_width / GRID_TILE_SIZE), ceil(room_height / GRID_TILE_SIZE));
    with (obj_wall) Nav_MarkInstance(_g, true, true);
    with (obj_interactable) Nav_MarkInstance(_g, true, Sight_BlocksObject(object_index));
    with (obj_room_transition) Nav_MarkInstance(_g, true, false, true);   // enemies never park on an exit; the exit cells are kept for the clear zones (D158)
    return _g;
}

// Gives back the cells of enemies that no longer exist (defeated, destroyed). Called when the number of enemies changes.
function Nav_ResPruneDead(_r) {
    var _names = variable_struct_get_names(_r.cells);
    for (var _i = 0; _i < array_length(_names); _i++) {
        if (!instance_exists(variable_struct_get(_r.cells, _names[_i]))) variable_struct_remove(_r.cells, _names[_i]);
    }
}

function Nav_Get() {
    var _wall0 = instance_exists(obj_wall) ? instance_find(obj_wall, 0) : noone;
    var _nw = instance_number(obj_wall);
    var _ni = instance_number(obj_interactable);
    var _nt = instance_number(obj_room_transition);
    var _fresh = !variable_global_exists("nav") || global.nav.room != room || global.nav.wall0 != _wall0;
    if (_fresh) {
        global.nav = { room: room, wall0: _wall0, nw: -1, ni: -1, nt: -1, ne: -1, grid: undefined, res: Nav_ResCreate(), builds: 0 };
    }
    var _n = global.nav;
    var _ne = instance_number(obj_enemy);
    if (_n.ne != _ne) {
        Nav_ResPruneDead(_n.res);
        _n.ne = _ne;
    }
    if (_n.nw != _nw || _n.ni != _ni || _n.nt != _nt) {
        _n.grid = Nav_BuildGrid();
        _n.nw = _nw;
        _n.ni = _ni;
        _n.nt = _nt;
        _n.builds++;
    }
    return _n;
}

function Nav_Stats() {
    if (!variable_global_exists("nav_stats")) global.nav_stats = { stuck_events: 0, spots: 0, repaths: 0 };
    return global.nav_stats;
}

// ----------------------------------------------------------------------------
// Overworld AI (D63, D66, D67, D153). Modes: idle -> chase (sees the player, or heard him run) -> search (lost him: look at the last seen cell, walk the way he fled,
// look again, ONE "?") -> return (walk home) -> idle. Movement is always a 16 px step toward a path cell; the enemy rests on the grid between steps.
// ----------------------------------------------------------------------------
function EnemyAI_BuildContext(_inst, _cfg) {
    return { move_speed_mult: 1 };
}

function EnemyAI_Init(_inst) {
    if (variable_instance_exists(_inst, "ai_mode")) return;
    var _p = EnemyAI_Profile(_inst.enemy_id);
    _inst.prof = _p;
    _inst.ai_mode = "idle";
    _inst.last_seen_cx = 0;
    _inst.last_seen_cy = 0;
    _inst.last_seen_dir = -1;
    _inst.srch = undefined;
    _inst.question_pop = 0;
    _inst.q_pops = 0;
    _inst.alert_pop = 0;
    _inst.react_timer = 0;
    _inst.spot_cooldown = 0;
    _inst.idle_timer = irandom_range(0, max(1, _p.pause_max));
    _inst.patrol_cx = -1;
    _inst.patrol_cy = -1;
    _inst.step_tx = _inst.x;
    _inst.step_ty = _inst.y;
    _inst.cur_speed = 0.5;
    _inst.last_dir = -1;
    _inst.retry_timer = 0;
    _inst.stuck_frames = 0;
    _inst.stuck_max = 0;
    _inst.stuck_events = 0;
    _inst.home_cx = Nav_CellOf(Grid_Snap(_inst.home_x) + GRID_TILE_SIZE / 2);
    _inst.home_cy = Nav_CellOf(Grid_Snap(_inst.home_y) + GRID_TILE_SIZE / 2);
    _inst.look_dir = (abs(_inst.home_cx * 3 + _inst.home_cy * 5)) mod 4;   // D179: the way it faces (RIGHT, UP, LEFT, DOWN): from where it stands, so a room looks the same every time
    _inst.turn_timer = AI_TURN_MIN_FRAMES + (abs(_inst.home_cx * 7 + _inst.home_cy * 11)) mod (AI_TURN_MAX_FRAMES - AI_TURN_MIN_FRAMES + 1);
}

// Notices the player: inside the cone in front of it (the way it faces, D179) or within 1 tile, and (unless see_through) nothing that blocks sight on the line between the two cells;
// a hidden player (D153) only from 1 tile (Sight_CanSee). An enemy without a facing (a stand-in in a check) sees all round.
function EnemyAI_CanSee(_inst, _pl, _nav, _tiles, _hidden = false) {
    var _face = variable_instance_exists(_inst, "look_dir") ? _inst.look_dir : -1;
    return Sight_CanSee(_nav.grid, _inst.x, _inst.y, _pl.x, _pl.y, _tiles, _inst.prof.see_through, _hidden, _face);
}

// The cardinal direction that points most nearly from cell (_ecx,_ecy) at cell (_tx,_ty); _keep when they are the same cell. Ties go to the horizontal.
function Look_DirToward(_ecx, _ecy, _tx, _ty, _keep) {
    var _dx = _tx - _ecx;
    var _dy = _ty - _ecy;
    if (_dx == 0 && _dy == 0) return _keep;
    if (abs(_dx) >= abs(_dy)) return (_dx > 0) ? RIGHT : LEFT;
    return (_dy > 0) ? DOWN : UP;
}

// A new facing for an idle enemy: never the same, any of the other three (_r 0..2).
function Look_NextDir(_dir, _r) {
    return (_dir + 1 + clamp(floor(_r), 0, 2)) mod 4;
}

// An enemy that waits turns to a new random direction every 2 to 4 seconds (D179); one that walks faces where it walks (EnemyAI_BeginStep), one that has just spotted the player faces him.
function EnemyAI_TurnTick(_inst) {
    if (_inst.moving || _inst.ai_mode != "idle") return;
    if (_inst.turn_timer > 0) {
        _inst.turn_timer--;
        return;
    }
    _inst.look_dir = Look_NextDir(_inst.look_dir, irandom(2));
    _inst.turn_timer = irandom_range(AI_TURN_MIN_FRAMES, AI_TURN_MAX_FRAMES);
}

function EnemyAI_BeginStep(_inst, _dir, _speed) {
    var _t = GRID_TILE_SIZE;
    var _mx = (_dir == RIGHT) - (_dir == LEFT);
    var _my = (_dir == DOWN) - (_dir == UP);
    _inst.move_dir = _dir;
    _inst.last_dir = _dir;
    _inst.look_dir = _dir;   // D179: it faces where it walks
    _inst.moving = true;
    _inst.move_timer = _t;
    _inst.step_tx = _inst.x + _mx * _t;
    _inst.step_ty = _inst.y + _my * _t;
    _inst.cur_speed = _speed;
    _inst.stuck_frames = 0;
}

// Keeps the reservation table in step with where the enemy is: its own cell while resting.
function EnemyAI_HoldOwnCell(_inst, _nav) {
    Nav_ResRelease(_nav.res, _inst.id);
    Nav_ResClaim(_nav.res, _inst.id, Nav_CellOf(_inst.x + GRID_TILE_SIZE / 2), Nav_CellOf(_inst.y + GRID_TILE_SIZE / 2));
}

// Ghost step: straight toward the goal along the longer axis, then the other; walls and objects do not matter, the room edge does.
function EnemyAI_TryPassStep(_inst, _nav, _ecx, _ecy, _gx, _gy, _speed) {
    var _dx = _gx - _ecx;
    var _dy = _gy - _ecy;
    if (_dx == 0 && _dy == 0) return false;
    var _dirs = [];
    var _hdir = (_dx > 0) ? RIGHT : LEFT;
    var _vdir = (_dy > 0) ? DOWN : UP;
    if (abs(_dx) >= abs(_dy)) { if (_dx != 0) array_push(_dirs, _hdir); if (_dy != 0) array_push(_dirs, _vdir); }
    else { array_push(_dirs, _vdir); if (_dx != 0) array_push(_dirs, _hdir); }
    for (var _i = 0; _i < array_length(_dirs); _i++) {
        var _d = _dirs[_i];
        var _tcx = _ecx + (_d == RIGHT) - (_d == LEFT);
        var _tcy = _ecy + (_d == DOWN) - (_d == UP);
        if (!Nav_GridInside(_nav.grid, _tcx, _tcy)) continue;
        if (!(_tcx == _gx && _tcy == _gy) && !Nav_ResClaim(_nav.res, _inst.id, _tcx, _tcy)) continue;
        EnemyAI_BeginStep(_inst, _d, _speed);
        return true;
    }
    return false;
}

// One step toward a goal cell along the A* path. Returns true when a step started.
function EnemyAI_TryStepToCell(_inst, _nav, _gx, _gy, _speed) {
    var _t = GRID_TILE_SIZE;
    var _ecx = Nav_CellOf(_inst.x + _t / 2);
    var _ecy = Nav_CellOf(_inst.y + _t / 2);
    if (_inst.prof.pass) return EnemyAI_TryPassStep(_inst, _nav, _ecx, _ecy, _gx, _gy, _speed);
    Nav_Stats().repaths++;
    var _st = Nav_StepToward(_nav.grid, _nav.res, _inst.id, _ecx, _ecy, _gx, _gy);
    if (!_st.ok) return false;
    var _mx = (_st.dir == RIGHT) - (_st.dir == LEFT);
    var _my = (_st.dir == DOWN) - (_st.dir == UP);
    if (!(_st.cx == _gx && _st.cy == _gy) && !EnemyAI_CanStep(_inst, _mx, _my)) {
        // the live instances disagree with the grid (something moved or was just created): give the claim back and wait
        EnemyAI_HoldOwnCell(_inst, _nav);
        _nav.nw = -1;   // rebuild the grid next frame
        return false;
    }
    EnemyAI_BeginStep(_inst, _st.dir, _speed);
    return true;
}

// The shared "walk toward a goal" with the stuck watchdog. Returns true while a step is running or just started.
function EnemyAI_Pursue(_inst, _nav, _gx, _gy, _speed) {
    if (_inst.retry_timer > 0) {
        _inst.retry_timer--;
        _inst.stuck_frames++;
    } else if (EnemyAI_TryStepToCell(_inst, _nav, _gx, _gy, _speed)) {
        return true;
    } else {
        _inst.retry_timer = 6;
        _inst.stuck_frames++;
    }
    _inst.stuck_max = max(_inst.stuck_max, _inst.stuck_frames);
    return false;
}

function EnemyAI_Update(_inst, _cfg, _pl) {
    if (_inst.defeated) return;

    // I-048: never stay between tiles (aborted step, save/load, room restore).
    if (!_inst.moving) Enemy_SnapToGrid(_inst);

    var ctx = EnemyAI_BuildContext(_inst, _cfg);
    EnemyAI_ApplyTraits(_inst, _cfg, ctx, "on_update");

    if (!instance_exists(_pl)) return;

    EnemyAI_Init(_inst);
    var _p = _inst.prof;

    // Bosses on their post (the old square trigger lives in obj_enemy Step for ai_stationary): they never walk.
    if (_p.fixed || (variable_instance_exists(_inst, "ai_stationary") && _inst.ai_stationary)) {
        var sdx = _pl.x - _inst.x;
        var sdy = _pl.y - _inst.y;
        if (abs(sdx) <= _inst.scan_radius && abs(sdy) <= _inst.scan_radius) {
            _inst.ai_state = ENEMY_ALERT;
            _inst.forget_time = _inst.forget_delay;
        } else if (_inst.forget_time > 0) {
            _inst.forget_time--;
            _inst.ai_state = ENEMY_ALERT;
        } else {
            _inst.ai_state = ENEMY_IDLE;
        }
        _inst.moving = false;
        _inst.move_timer = 0;
        _inst.move_dir = -1;
        return;
    }

    var _nav = Nav_Get();
    World_RegisterFx(_inst);   // the "!" and the sight cone are drawn by the world layer script (objects have no Draw event, no .yy edits)

    var _t = GRID_TILE_SIZE;
    if (_inst.alert_pop > 0) _inst.alert_pop--;
    if (_inst.question_pop > 0) _inst.question_pop--;
    if (_inst.spot_cooldown > 0) _inst.spot_cooldown--;

    // ---- senses ----
    var _pcx = Nav_CellOf(_pl.x + _t / 2);
    var _pcy = Nav_CellOf(_pl.y + _t / 2);
    var _hidden = Player_IsHidden(_pl);   // D153: still on a hiding cell: only seen from 1 tile
    var _per = EnemyAI_Perceive(_nav.grid, _p, _inst.x, _inst.y, _pl.x, _pl.y, Player_IsRunning(_pl), _hidden, _inst.look_dir);   // sight (the cone in front of it, D179), and the noise of a RUN (D153)
    var _sees = (_inst.spot_cooldown <= 0) && _per.sees;
    var _heard = (_inst.spot_cooldown <= 0) && _per.heard;
    if (_inst.ai_mode == "chase") {
        // a little extra range once chasing so the edge of the cone does not flicker
        if (_sees || EnemyAI_CanSee(_inst, _pl, _nav, _p.sight + 1, _hidden)) {
            _inst.last_seen_cx = _pcx;
            _inst.last_seen_cy = _pcy;
            _inst.last_seen_dir = _pl.face;
            _sees = true;
        } else if (_heard) {
            _inst.last_seen_cx = _pcx;   // out of sight but running: it follows the noise
            _inst.last_seen_cy = _pcy;
            _inst.last_seen_dir = _pl.face;
        }
    } else if (_sees) {
        _inst.ai_mode = "chase";
        _inst.look_dir = Look_DirToward(Nav_CellOf(_inst.x + _t / 2), Nav_CellOf(_inst.y + _t / 2), _pcx, _pcy, _inst.look_dir);   // D179: it turns to face him
        _inst.last_seen_cx = _pcx;
        _inst.last_seen_cy = _pcy;
        _inst.last_seen_dir = _pl.face;
        _inst.srch = undefined;
        _inst.question_pop = 0;
        _inst.alert_pop = 50;
        _inst.react_timer = _p.react;
        _inst.patrol_cx = -1;
        _inst.stuck_frames = 0;
        Nav_Stats().spots++;
        SFX_Play("alert_spotted", 0.5, 1.5);   // existing sound, small and high: "!" (a world sound: SFX bus)
    } else if (_heard) {
        // D153: it heard the player run: turn and go to where the noise came from, no "!" (it has not seen anyone); once there it searches like after a lost sight
        _inst.ai_mode = "chase";
        _inst.last_seen_cx = _pcx;
        _inst.last_seen_cy = _pcy;
        _inst.last_seen_dir = _pl.face;
        _inst.srch = undefined;
        _inst.question_pop = 0;
        _inst.react_timer = _p.react;
        _inst.patrol_cx = -1;
        _inst.stuck_frames = 0;
    }
    _inst.ai_state = (_inst.ai_mode == "chase" || _inst.ai_mode == "search") ? ENEMY_ALERT : ENEMY_IDLE;
    if (_inst.ai_state == ENEMY_ALERT) _inst.forget_time = _inst.forget_delay;

    // ---- decide (only between steps) ----
    EnemyAI_TurnTick(_inst);
    if (!_inst.moving) {
        EnemyAI_HoldOwnCell(_inst, _nav);
        var _ecx = Nav_CellOf(_inst.x + _t / 2);
        var _ecy = Nav_CellOf(_inst.y + _t / 2);

        if (_inst.react_timer > 0) {
            _inst.react_timer--;
        } else {
            switch (_inst.ai_mode) {
                case "chase":
                    var _gx = _inst.last_seen_cx;
                    var _gy = _inst.last_seen_cy;
                    if (!_sees && _ecx == _gx && _ecy == _gy) {
                        _inst.ai_mode = "search";   // D153: look, then the way the player fled, then one "?" and home
                        _inst.srch = Search_Create(_gx, _gy, _inst.last_seen_dir, max(10, round(_p.search / 3)));
                    } else if (_ecx != _gx || _ecy != _gy) {
                        EnemyAI_Pursue(_inst, _nav, _gx, _gy, _p.chase);
                    }
                    break;
                case "search":
                    if (!is_struct(_inst.srch)) _inst.srch = Search_Create(_ecx, _ecy, -1, max(10, round(_p.search / 3)));
                    var _sr = Search_Step(_inst.srch, _nav.grid, _ecx, _ecy);
                    if (_sr.pop) EnemyAI_PopQuestion(_inst);
                    if (_sr.done) {
                        _inst.ai_mode = "return";
                        _inst.srch = undefined;
                        _inst.stuck_frames = 0;
                    } else if (_sr.goal_cx >= 0) {
                        EnemyAI_Pursue(_inst, _nav, _sr.goal_cx, _sr.goal_cy, _p.ret_speed);
                    } else {
                        _inst.stuck_frames = 0;
                    }
                    break;
                case "return":
                    if (_ecx == _inst.home_cx && _ecy == _inst.home_cy) {
                        _inst.stuck_frames = 0;
                        _inst.ai_mode = "idle";
                        _inst.idle_timer = irandom_range(_p.pause_min, max(_p.pause_min, _p.pause_max));
                    } else {
                        EnemyAI_Pursue(_inst, _nav, _inst.home_cx, _inst.home_cy, _p.ret_speed);
                    }
                    break;
                default:
                    EnemyAI_Idle(_inst, _nav, _ecx, _ecy);
                    break;
            }
        }

        // watchdog: wanted to move and could not for more than a second
        if (_inst.stuck_frames > 60) {
            _inst.stuck_events++;
            Nav_Stats().stuck_events++;
            show_debug_message("[NAV] stuck enemy_uid=" + string(_inst.enemy_uid) + " room=" + room_get_name(room) + " mode=" + _inst.ai_mode + " cell=" + string(_ecx) + "," + string(_ecy));
            _inst.stuck_frames = 0;
            _inst.retry_timer = 0;
            if (_inst.ai_mode == "chase") {
                _inst.ai_mode = "search";
                _inst.srch = Search_Create(_ecx, _ecy, -1, max(10, round(_p.search / 3)));
                _inst.spot_cooldown = 180;
            } else if (_inst.ai_mode == "search") {
                if (is_struct(_inst.srch)) Search_GiveUp(_inst.srch);   // cannot reach the end of the flee leg: give up here
            } else if (_inst.ai_mode == "return") {
                _inst.home_cx = _ecx;   // cannot get home from here: make here the new home
                _inst.home_cy = _ecy;
                _inst.home_x = _inst.x;
                _inst.home_y = _inst.y;
            } else {
                _inst.patrol_cx = -1;
            }
        }
    }

    // ---- move ----
    if (_inst.moving) {
        var _mx = (_inst.move_dir == RIGHT) - (_inst.move_dir == LEFT);
        var _my = (_inst.move_dir == DOWN) - (_inst.move_dir == UP);
        var _step = min(_inst.cur_speed * ctx.move_speed_mult, _inst.move_timer);
        _inst.x += _mx * _step;
        _inst.y += _my * _step;
        _inst.move_timer -= _step;
        if (_inst.move_timer <= 0.0001) {
            _inst.x = _inst.step_tx;
            _inst.y = _inst.step_ty;
            _inst.moving = false;
            _inst.move_timer = 0;
            _inst.move_dir = -1;
            EnemyAI_HoldOwnCell(_inst, _nav);
        }
    }
}

// Idle personalities. Picks the next idle step (or does nothing) when the pause is over.
function EnemyAI_Idle(_inst, _nav, _ecx, _ecy) {
    var _p = _inst.prof;
    if (_p.idle == "still") return;
    // pushed or displaced beyond the roaming range: walk home first
    if (max(abs(_ecx - _inst.home_cx), abs(_ecy - _inst.home_cy)) > _p.roam + 1) {
        _inst.ai_mode = "return";
        return;
    }
    if (_inst.idle_timer > 0) {
        _inst.idle_timer--;
        return;
    }
    if (_p.idle == "patrol") {
        if (_inst.patrol_cx < 0 || (_ecx == _inst.patrol_cx && _ecy == _inst.patrol_cy) || _inst.stuck_frames > 20) {
            var _arrived = (_inst.patrol_cx >= 0 && _ecx == _inst.patrol_cx && _ecy == _inst.patrol_cy);
            _inst.patrol_cx = -1;
            _inst.stuck_frames = 0;
            if (_arrived) {
                _inst.idle_timer = irandom_range(_p.pause_min, max(_p.pause_min, _p.pause_max));
                return;
            }
            var _pt = Idle_PatrolTarget(_nav.grid, _inst.home_cx, _inst.home_cy, _p.roam, _ecx, _ecy);   // D158: never a target near an exit
            if (is_undefined(_pt)) { _inst.idle_timer = 30; return; }
            _inst.patrol_cx = _pt[0];
            _inst.patrol_cy = _pt[1];
        }
        EnemyAI_Pursue(_inst, _nav, _inst.patrol_cx, _inst.patrol_cy, _p.idle_speed);
        return;
    }
    // wander / drift: one neighbouring cell inside the roaming range that is free right now
    var _order = [];
    if (_p.idle == "drift" && _inst.last_dir != -1 && irandom(9) < 7) array_push(_order, _inst.last_dir);   // drift keeps its heading
    var _dirs4 = [RIGHT, UP, LEFT, DOWN];
    var _base = irandom(3);
    for (var _j = 0; _j < 4; _j++) array_push(_order, _dirs4[(_base + _j) mod 4]);
    for (var _i = 0; _i < array_length(_order); _i++) {
        var _d = _order[_i];
        var _tcx = _ecx + (_d == RIGHT) - (_d == LEFT);
        var _tcy = _ecy + (_d == DOWN) - (_d == UP);
        if (max(abs(_tcx - _inst.home_cx), abs(_tcy - _inst.home_cy)) > _p.roam) continue;
        if (!Nav_GridInside(_nav.grid, _tcx, _tcy)) continue;
        if (!Idle_StepAllowed(_nav.grid, _ecx, _ecy, _tcx, _tcy)) continue;   // D158: not into the zone round an exit
        if (!_p.pass) {
            if (Nav_CellBlocked(_nav.grid, _tcx, _tcy)) continue;
            if (!EnemyAI_CanStep(_inst, (_d == RIGHT) - (_d == LEFT), (_d == DOWN) - (_d == UP))) continue;
        }
        if (!Nav_ResClaim(_nav.res, _inst.id, _tcx, _tcy)) continue;
        EnemyAI_BeginStep(_inst, _d, _p.idle_speed);
        _inst.idle_timer = irandom_range(_p.pause_min, max(_p.pause_min, _p.pause_max));
        return;
    }
    _inst.idle_timer = 20;   // nowhere to go right now
}

// A layer script is called once per draw PASS of the engine, not once per frame (measured, I-056/I-058): pre draw, draw begin, draw, draw end,
// post draw AND the three Draw GUI passes (view_current 7, the back buffer, GUI units). Only the normal Draw pass paints the world picture
// (the application surface, world pixels); the others would land the same marks at the top-left of the window, in GUI units.
function Fx_IsWorldPass() {
    return (event_type == ev_draw && event_number == ev_draw_normal);
}

// Counts room starts (obj_game_controller Create runs in every room). A layer script belongs to the room it was registered in.
function Room_StampBump() {
    global.room_stamp = (variable_global_exists("room_stamp") ? global.room_stamp : 0) + 1;
}

function Room_Stamp() {
    return variable_global_exists("room_stamp") ? global.room_stamp : 0;
}

// The world pass draws in TWO places (R-089..R-091), because a room's Foreground layer (rm_floor1, rm_floor2: a pale haze above the Instances) lies between them:
//   body pass, the end of the Instances layer: the pictures of world objects that have no Draw event of their own (the player's step squash, the merchant's glow). They are
//     drawn where the plain player, the enemies and the merchant's sprite are, under the haze and before the darkness, so they look like them whatever the player is doing.
//   top pass, the end of the Foreground layer (the end of Instances in a room without one): the lore notes, the darkness (D159: it covers the haze too) and the marks after it.
// A layer has only one end script, and a room without a Foreground layer has one layer for both, so that room gets one script that draws every part in order.
// Registered once per room START by whoever gets here first (the player's Step, an enemy's update): a re-entered room (after a battle, a run,
// a save load) has new layers, and the old once-ever flag left it without any mark (I-056).
function World_RegisterFx(_inst) {
    var _st = Room_Stamp();
    if (variable_global_exists("world_fx_stamp") && global.world_fx_stamp == _st) return;
    if (!layer_exists(_inst.layer)) return;
    global.world_fx_stamp = _st;
    var _plan = World_FxPlan(layer_exists("Foreground"));
    if (_plan.split) {
        layer_script_end(layer_exists(_plan.body_layer) ? layer_get_id(_plan.body_layer) : _inst.layer, World_DrawBodyFx);
        layer_script_end(layer_get_id(_plan.top_layer), World_DrawFx);
    } else {
        layer_script_end(_inst.layer, World_DrawFx);
    }
}

// Where the passes run, by name: body_layer is the layer the player and the enemies are on; top_layer is the top layer of the world; split: two scripts instead of one.
function World_FxPlan(_has_foreground) {
    return { body_layer: "Instances", top_layer: _has_foreground ? "Foreground" : "Instances", split: _has_foreground };
}

// The parts of the world pass in drawing order (bug hunt 7). body: the part draws a picture of a WORLD OBJECT (a figure, a note on the floor), which belongs under the room's
// darkness like the figures drawn by their own Draw events: a figure standing in the dark must look like it, also for the 120 ms of a step squash. The marks (the "!" and "?", the
// interact arrow, the elite outline, chest bursts) come after the darkness and stay bright. pass (R-089..R-091): "body" parts are drawn at the end of the Instances layer
// (World_DrawBodyFx, under the Foreground haze), "top" parts at the end of the top layer (World_DrawFx). Test_Hunt7MapDraw and Test_R3LightParts hold the order.
function World_FxParts() {
    static _parts = [
        { name: "note", body: true, pass: "top" },             // C5 (D107): the lore notes lie under everything else
        { name: "sight", body: true, pass: "top" },            // D179 (R-098): the very faint cone in front of each enemy, a tint on the floor under the darkness
        { name: "player_squash", body: true, pass: "body" },   // D138 (G6): the player's step squash, drawn here while his plain sprite is off
        { name: "merchant_glow", body: true, pass: "body" },   // D113: the pulsing gold glow round the merchant, darkened like him (R-091)
        { name: "light", body: false, pass: "top" },           // H14 (D157, D159): the room's darkness with the fires cut out of it; everything after it stays at full brightness
        { name: "nav", body: false, pass: "top" },
        { name: "player_prompt", body: false, pass: "top" },
        { name: "elite", body: false, pass: "top" },          // C3 (D86): the pulsing outline round elites
        { name: "mapfx", body: false, pass: "top" }           // D138 (G6): chest burst, the rising item, the level-up sparkle
    ];
    return _parts;
}

function World_DrawFxPart(_name) {
    switch (_name) {
        case "note": Note_DrawWorldFx(); break;
        case "sight": Sight_DrawWorldFx(); break;
        case "player_squash": MapFx_DrawPlayerSquash(); break;
        case "light": Light_DrawPass(); break;
        case "nav": Nav_DrawWorldFx(); break;
        case "player_prompt": Player_DrawWorldFx(); break;
        case "elite": Elite_DrawWorldFx(); break;
        case "merchant_glow": Merchant_DrawWorldFx(); break;
        case "mapfx": MapFx_DrawWorldFx(); break;
    }
}

// Draws the parts of one pass in order ("" = every part, for a room with one script); _layer_name is recorded for the checks (Fx_NotePlayerDraw).
function World_DrawFxParts(_pass, _layer_name) {
    global.world_pass_layer = _layer_name;
    var _parts = World_FxParts();
    for (var _i = 0; _i < array_length(_parts); _i++) {
        if (_pass == "" || _parts[_i].pass == _pass) World_DrawFxPart(_parts[_i].name);
    }
}

// The layer script at the end of the Instances layer in a room with a Foreground layer (World_RegisterFx).
function World_DrawBodyFx() {
    World_DrawFxParts("body", World_FxPlan(true).body_layer);
}

// The layer script at the end of the top layer: only the top parts when the body parts have their own script, else every part.
function World_DrawFx() {
    var _plan = World_FxPlan(layer_exists("Foreground"));
    World_DrawFxParts(_plan.split ? "top" : "", _plan.top_layer);
}

// (D157: the sight ring is no longer drawn; this cache stays only until D108's clean-up removes it with Test_SightRingCache.)
// D108 F1d-3: the dot offsets of a sight ring depend only on its radius in pixels, so they are built once per radius (cos/sin of each dot, NOT yet
// floored: the draw floors cx + offset, the same float sum as the per-frame formula it replaced, so every dot lands on the same pixel).
// Returns { n, ox[], oy[] }. global.nav_ring_builds counts the builds (Test_SightRingCache).
function Nav_SightRing(_r) {
    if (!variable_global_exists("nav_ring_cache") || !is_struct(global.nav_ring_cache)) global.nav_ring_cache = {};
    if (!variable_global_exists("nav_ring_builds")) global.nav_ring_builds = 0;
    var _key = string(_r);
    if (variable_struct_exists(global.nav_ring_cache, _key)) return variable_struct_get(global.nav_ring_cache, _key);
    var _n = max(12, round(2 * pi * _r / 6));
    var _ring = { n: _n, ox: array_create(_n, 0), oy: array_create(_n, 0) };
    for (var _k = 0; _k < _n; _k++) {
        var _a = (_k / _n) * 2 * pi;
        _ring.ox[_k] = cos(_a) * _r;
        _ring.oy[_k] = sin(_a) * _r;
    }
    variable_struct_set(global.nav_ring_cache, _key, _ring);
    global.nav_ring_builds++;
    return _ring;
}

// The 4-colour palette of the world marks, built once (make_color_rgb every frame was the old cost).
function Nav_FxColors() {
    if (!variable_global_exists("nav_fx_colors") || !is_struct(global.nav_fx_colors)) {
        global.nav_fx_colors = { c0: UI_C_DARKEST, c1: UI_C_DARK, c2: UI_C_LIGHT, c3: UI_C_LIGHTEST };
    }
    return global.nav_fx_colors;
}

// ---- the faint sight cone (D179, R-098) ----
// The tint of one cell of an enemy's cone: _band 2 near the enemy .. 0 at the edge (softer), a little stronger while it chases. Alpha of AI_CONE_COLOUR.
function Sight_ConeAlpha(_band, _chasing) {
    var _a = (_band >= 2) ? AI_CONE_ALPHA_NEAR : ((_band == 1) ? AI_CONE_ALPHA_MID : AI_CONE_ALPHA_FAR);
    return _chasing ? _a * AI_CONE_CHASE_MULT : _a;
}

// What the last pass drew (the pictures check it): { calls, enemies, cells, alpha_max }.
function Sight_ConeStats() {
    if (!variable_global_exists("sight_cone_stats") || !is_struct(global.sight_cone_stats)) global.sight_cone_stats = { calls: 0, enemies: 0, cells: 0, alpha_max: 0 };
    return global.sight_cone_stats;
}

// Does this enemy show a cone: awake and roaming (not defeated, not a boss or an enemy that stays on its post, not held by a cut scene), with a sight at all.
function Sight_ConeShown(_inst) {
    if (_inst.defeated || !variable_instance_exists(_inst, "prof") || !variable_instance_exists(_inst, "look_dir")) return false;
    if (_inst.prof.fixed || _inst.prof.sight <= 0) return false;
    if (variable_instance_exists(_inst, "ai_stationary") && _inst.ai_stationary) return false;
    if (variable_instance_exists(_inst, "cine_lock_count") && _inst.cine_lock_count > 0) return false;
    return true;
}

// Called by World_DrawFx (a layer script, see World_RegisterFx), before the darkness: the cells every roaming enemy on screen can see right now, as a very faint shade of
// AI_CONE_COLOUR on the floor, near cells a little stronger than the edge, a chasing enemy's a little stronger again. It is the very set the sight test uses (Vis_Cone with the
// facing), so what is tinted is what it sees: the cone, cut off by props and walls. The cells of the props themselves are not tinted.
function Sight_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    var _st = Sight_ConeStats();
    _st.calls++;
    _st.enemies = 0;
    _st.cells = 0;
    _st.alpha_max = 0;
    if (!instance_exists(obj_enemy)) return;
    var _cam = view_camera[0];
    if (is_undefined(_cam) || _cam == -1) return;
    var _vx = camera_get_view_x(_cam);
    var _vy = camera_get_view_y(_cam);
    var _vw = camera_get_view_width(_cam);
    var _vh = camera_get_view_height(_cam);
    var _T = GRID_TILE_SIZE;
    var _g = Nav_Get().grid;
    var _oc = draw_get_color();
    var _oa = draw_get_alpha();
    draw_set_color(AI_CONE_COLOUR);
    with (obj_enemy) {
        if (!Sight_ConeShown(id)) continue;
        var _ecx = Nav_CellOf(x + _T / 2);
        var _ecy = Nav_CellOf(y + _T / 2);
        var _tiles = Vis_EnemyTiles(prof, ai_mode);
        var _reach = (ceil(_tiles) + 1) * _T;
        if (_ecx * _T + _reach < _vx || _ecx * _T - _reach > _vx + _vw || _ecy * _T + _reach < _vy || _ecy * _T - _reach > _vy + _vh) continue;   // off screen
        var _cone = Vis_Cone(_g, _ecx, _ecy, _tiles, prof.see_through, look_dir);
        var _chasing = (ai_mode == "chase");
        _st.enemies++;
        for (var _i = 0; _i < array_length(_cone.runs); _i += 4) {
            var _a = Sight_ConeAlpha(_cone.runs[_i + 3], _chasing);
            var _x0 = (_ecx + _cone.runs[_i]) * _T;
            var _y0 = (_ecy + _cone.runs[_i + 1]) * _T;
            draw_set_alpha(_a);
            draw_rectangle(_x0, _y0, _x0 + _cone.runs[_i + 2] * _T - 1, _y0 + _T - 1, false);
            _st.cells += _cone.runs[_i + 2];
            _st.alpha_max = max(_st.alpha_max, _a);
        }
    }
    draw_set_color(_oc);
    draw_set_alpha(_oa);
}

// Called by World_DrawFx (a layer script, see World_RegisterFx): the "!" over an enemy that just spotted the player and the "?" over one that gave up.
// The old dotted ring of its sight range (D63) is gone: sight is shown as light now (D157, Light_DrawPass). 4-colour palette, no new assets.
function Nav_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    if (!variable_global_exists("nav_fx_calls")) global.nav_fx_calls = 0;
    global.nav_fx_calls++;
    if (!instance_exists(obj_enemy)) return;
    var _pal = Nav_FxColors();
    var _c0 = _pal.c0;
    var _c3 = _pal.c3;
    var _oc = draw_get_color();
    var _oa = draw_get_alpha();
    draw_set_alpha(1);
    with (obj_enemy) {
        if (!defeated && variable_instance_exists(id, "prof")) {
            var _cx = x + GRID_TILE_SIZE / 2;
            var _cy = y + GRID_TILE_SIZE / 2;
            if (alert_pop > 0) {
                var _bx = floor(_cx);
                var _by = floor(y) - 11;
                draw_set_color(_c0);
                draw_rectangle(_bx - 2, _by, _bx + 2, _by + 10, false);
                draw_set_color(_c3);
                draw_rectangle(_bx - 1, _by + 1, _bx + 1, _by + 6, false);
                draw_rectangle(_bx - 1, _by + 8, _bx + 1, _by + 9, false);
            }
            // D153: the "?" of a given-up search. Small tier of feedback: it pops up with a little overshoot (ease-back, 10 frames), rests, then flickers out. No shake, no stop.
            var _qage = AI_QUESTION_FRAMES - question_pop;
            if (question_pop > 0 && !(question_pop < 12 && ((question_pop div 3) mod 2) == 0)) {
                var _qt = clamp(_qage / 10, 0, 1);
                var _qs = 1.70158;
                var _qe = 1 + (_qs + 1) * power(_qt - 1, 3) + _qs * power(_qt - 1, 2);   // ease-out-back: 0 -> overshoots 1 -> settles on 1
                var _qx = floor(_cx);
                var _qy = floor(y) - 11 + round(6 * (1 - _qe));   // starts 6 px low, rises past its place by a pixel, settles
                draw_set_color(_c0);
                draw_rectangle(_qx - 3, _qy, _qx + 3, _qy + 10, false);
                draw_set_color(_c3);
                // the glyph, row by row: x offsets of its light pixels
                var _qpix = [[-1, 0, 1], [-2, 2], [2], [0, 1], [0], [], [0]];
                for (var _qr = 0; _qr < array_length(_qpix); _qr++) {
                    for (var _qc = 0; _qc < array_length(_qpix[_qr]); _qc++) {
                        draw_rectangle(_qx + _qpix[_qr][_qc], _qy + 2 + _qr, _qx + _qpix[_qr][_qc], _qy + 2 + _qr, false);
                    }
                }
            }
        }
    }
    draw_set_color(_oc);
    draw_set_alpha(_oa);
}


// ============================================================================
// NAV (D63, I-047): pure grid pathfinding, line of sight and cell reservations.
// A grid is a struct { w, h, block[], sight[], exits[], vis } of 16 px cells (vis: the sets of light kept per cell, see Vis_Cone) with the origin at world (0,0) (D65: room sizes are not changed).
// block = movement blocked (wall, rock, chest, exit tile); sight = line of sight blocked (wall only); exits = [[cx, cy], ...] the exit cells (D158).
// Nothing here touches instances, so Test_Suite_Nav can run it on hand-made maps. Room integration is Nav_Get() further down.
// ============================================================================
function Nav_CellOf(_v) {
    return floor(_v / GRID_TILE_SIZE);
}

function Nav_WorldOf(_c) {
    return _c * GRID_TILE_SIZE;
}

function Nav_GridCreate(_w, _h) {
    _w = max(1, _w);
    _h = max(1, _h);
    return { w: _w, h: _h, block: array_create(_w * _h, 0), sight: array_create(_w * _h, 0), exits: [], vis: undefined };
}

// rows: array of strings. "." free, "#" wall (blocks movement and sight), "~" blocks movement only (a torch), "o" blocks both (a barrel, a tree: D179),
// "g" blocks sight only (tall grass: it can be walked through, D179).
function Nav_GridFromRows(_rows) {
    var _h = array_length(_rows);
    var _w = 1;
    for (var _y = 0; _y < _h; _y++) _w = max(_w, string_length(_rows[_y]));
    var _g = Nav_GridCreate(_w, _h);
    for (var _y2 = 0; _y2 < _h; _y2++) {
        for (var _x = 0; _x < string_length(_rows[_y2]); _x++) {
            var _ch = string_char_at(_rows[_y2], _x + 1);
            if (_ch == "#" || _ch == "o") Nav_GridSet(_g, _x, _y2, true, true);
            else if (_ch == "~") Nav_GridSet(_g, _x, _y2, true, false);
            else if (_ch == "g") Nav_GridSet(_g, _x, _y2, false, true);
        }
    }
    return _g;
}

function Nav_GridInside(_g, _cx, _cy) {
    return (_cx >= 0 && _cy >= 0 && _cx < _g.w && _cy < _g.h);
}

function Nav_GridSet(_g, _cx, _cy, _block, _sight) {
    if (!Nav_GridInside(_g, _cx, _cy)) return;
    var _i = _cy * _g.w + _cx;
    if (_block) _g.block[_i] = 1;
    if (_sight) {
        _g.sight[_i] = 1;
        _g.vis = undefined;   // the sets of light worked out so far (Vis_Cone) no longer hold
    }
}

// Outside the map counts as blocked.
function Nav_CellBlocked(_g, _cx, _cy) {
    if (!Nav_GridInside(_g, _cx, _cy)) return true;
    return (_g.block[_cy * _g.w + _cx] != 0);
}

function Nav_SightBlocked(_g, _cx, _cy) {
    if (!Nav_GridInside(_g, _cx, _cy)) return true;
    return (_g.sight[_cy * _g.w + _cx] != 0);
}

// Line of sight between two cells (Bresenham on cell centres). Only the cells strictly between the ends can block.
function Nav_LineClear(_g, _x0, _y0, _x1, _y1) {
    var _dx = abs(_x1 - _x0);
    var _dy = abs(_y1 - _y0);
    var _sx = (_x0 < _x1) ? 1 : -1;
    var _sy = (_y0 < _y1) ? 1 : -1;
    var _err = _dx - _dy;
    var _x = _x0;
    var _y = _y0;
    var _guard = _dx + _dy + 2;
    while (_guard-- > 0) {
        if (_x == _x1 && _y == _y1) return true;
        if ((_x != _x0 || _y != _y0) && Nav_SightBlocked(_g, _x, _y)) return false;
        var _e2 = 2 * _err;
        if (_e2 > -_dy) { _err -= _dy; _x += _sx; }
        if (_e2 < _dx) { _err += _dx; _y += _sy; }
    }
    return true;
}

// ---- vision as a set of cells (D157, D159): ONE set per enemy, used for the sight test AND for the light that is drawn ----
// Shadowcasting on the 16 px grid, from the middle of the viewer's cell: a cell is lit when some part of it can be seen past the cells that block sight
// (a wall cell itself is lit on its near face). Only cells whose middle is within the radius count (the circle of D63). A ghost that sees through walls gets
// the whole circle. A set is { cx, cy, tiles, r, side, see_through, cells[], runs[] }: cells is (2r+1)^2 flags, row by row from (cx-r, cy-r);
// runs is the same set as horizontal runs [dx, dy, length, band] (dx, dy from the viewer's cell, band 2 = near .. 0 = far), sorted by band, for drawing.
// The sets are kept on the grid per (cell, radius) and dropped when a sight blocker is added (Nav_GridSet), so a still enemy costs nothing per frame.

function Vis_BuildCount() {
    return variable_global_exists("vis_builds") ? global.vis_builds : 0;
}

function Vis_Mark(_cone, _dx, _dy) {
    _cone.cells[(_dy + _cone.r) * _cone.side + _dx + _cone.r] = 1;
}

// Scans one octant row by row (_row = distance from the viewer, _start .. _end the slopes still open).
// The eight octants (static tables): how a (column, row) step of the scan maps onto the grid.
function Vis_Scan(_g, _cone, _row, _start, _end, _oct, _r2) {
    static _xx = [1, 0, 0, -1, -1, 0, 0, 1];
    static _xy = [0, 1, -1, 0, 0, -1, 1, 0];
    static _yx = [0, 1, 1, 0, 0, -1, -1, 0];
    static _yy = [1, 0, 0, 1, -1, 0, 0, -1];
    if (_start < _end) return;
    var _r = _cone.r;
    var _new_start = _start;
    for (var _j = _row; _j <= _r; _j++) {
        var _dy = -_j;
        var _dx = -_j - 1;
        var _blocked = false;
        while (_dx <= 0) {
            _dx++;
            var _mx = _dx * _xx[_oct] + _dy * _xy[_oct];
            var _my = _dx * _yx[_oct] + _dy * _yy[_oct];
            var _l = (_dx - 0.5) / (_dy + 0.5);
            var _rs = (_dx + 0.5) / (_dy - 0.5);
            if (_start < _rs) continue;
            if (_end > _l) break;
            if (_dx * _dx + _dy * _dy <= _r2) Vis_Mark(_cone, _mx, _my);
            var _wall = Nav_SightBlocked(_g, _cone.cx + _mx, _cone.cy + _my);
            if (_blocked) {
                if (_wall) {
                    _new_start = _rs;
                    continue;
                }
                _blocked = false;
                _start = _new_start;
            } else if (_wall && _j < _r) {
                _blocked = true;
                Vis_Scan(_g, _cone, _j + 1, _start, _l, _oct, _r2);
                _new_start = _rs;
            }
        }
        if (_blocked) break;
    }
}

// D179: is the cell (_dx,_dy) away from the viewer inside the 90 degree cone round the way it faces (_face: RIGHT, UP, LEFT or DOWN)? In front, and no further off to the side
// than it is ahead: the edge (45 degrees) counts. -1 (no facing) means all round. The viewer's own cell is not asked.
function Vis_InCone(_dx, _dy, _face) {
    switch (_face) {
        case RIGHT: return (_dx > 0 && abs(_dy) <= _dx);
        case LEFT:  return (_dx < 0 && abs(_dy) <= -_dx);
        case DOWN:  return (_dy > 0 && abs(_dx) <= _dy);
        case UP:    return (_dy < 0 && abs(_dx) <= -_dy);
    }
    return true;
}

// The set of cells lit from cell (_cx,_cy) with radius _tiles (not kept: Vis_Cone is the cached way). _face (D179): only the cone in front of a viewer that faces that way,
// plus the ring of 1 tile all round it (every cell next to it that does not block sight itself, even round a corner); -1 = the whole circle (the old shape).
function Vis_Compute(_g, _cx, _cy, _tiles, _see_through = false, _face = -1) {
    var _r = max(0, floor(_tiles));
    var _side = 2 * _r + 1;
    var _cone = { cx: _cx, cy: _cy, tiles: _tiles, r: _r, side: _side, see_through: _see_through, face: _face, cells: array_create(_side * _side, 0), runs: [] };
    var _r2 = _tiles * _tiles;
    Vis_Mark(_cone, 0, 0);
    if (_see_through) {
        for (var _dy = -_r; _dy <= _r; _dy++) {
            for (var _dx = -_r; _dx <= _r; _dx++) {
                if (_dx * _dx + _dy * _dy <= _r2) Vis_Mark(_cone, _dx, _dy);
            }
        }
    } else {
        for (var _oct = 0; _oct < 8; _oct++) Vis_Scan(_g, _cone, 1, 1.0, 0.0, _oct, _r2);
    }
    if (_face >= 0) {
        for (var _fy = -_r; _fy <= _r; _fy++) {
            for (var _fx = -_r; _fx <= _r; _fx++) {
                if ((_fx != 0 || _fy != 0) && max(abs(_fx), abs(_fy)) > 1 && !Vis_InCone(_fx, _fy, _face)) _cone.cells[(_fy + _r) * _side + _fx + _r] = 0;
            }
        }
        for (var _ry = -1; _ry <= 1; _ry++) {
            for (var _rx = -1; _rx <= 1; _rx++) {
                if (!Nav_SightBlocked(_g, _cx + _rx, _cy + _ry)) Vis_Mark(_cone, _rx, _ry);
            }
        }
    }
    // the runs for drawing: three bands by distance, near ones first. A cell that blocks sight is lit (its near face) but is not drawn: the tint stops in front of the prop.
    for (var _b = 2; _b >= 0; _b--) {
        for (var _y = -_r; _y <= _r; _y++) {
            var _x = -_r;
            while (_x <= _r) {
                if (Vis_Band(_cone, _x, _y) != _b || Nav_SightBlocked(_g, _cx + _x, _cy + _y)) { _x++; continue; }
                var _x0 = _x;
                while (_x <= _r && Vis_Band(_cone, _x, _y) == _b && !Nav_SightBlocked(_g, _cx + _x, _cy + _y)) _x++;
                array_push(_cone.runs, _x0, _y, _x - _x0, _b);
            }
        }
    }
    global.vis_builds = Vis_BuildCount() + 1;
    return _cone;
}

// The band of the cell (_dx,_dy) from the viewer: 2 within 40% of the radius, 1 within 75%, 0 beyond; -1 when the cell is not lit.
function Vis_Band(_cone, _dx, _dy) {
    if (_cone.cells[(_dy + _cone.r) * _cone.side + _dx + _cone.r] == 0) return -1;
    var _d = sqrt(_dx * _dx + _dy * _dy) / max(0.001, _cone.tiles);
    return (_d <= 0.4) ? 2 : ((_d <= 0.75) ? 1 : 0);
}

// The set for a cell, radius and facing, worked out once and kept on the grid.
function Vis_Cone(_g, _cx, _cy, _tiles, _see_through = false, _face = -1) {
    if (!Nav_GridInside(_g, _cx, _cy)) return Vis_Compute(_g, _cx, _cy, _tiles, _see_through, _face);
    if (!is_array(_g.vis)) _g.vis = array_create(_g.w * _g.h, undefined);
    var _i = _cy * _g.w + _cx;
    var _list = _g.vis[_i];
    if (is_array(_list)) {
        for (var _k = 0; _k < array_length(_list); _k++) {
            var _c = _list[_k];
            if (_c.tiles == _tiles && _c.see_through == _see_through && _c.face == _face) return _c;
        }
    } else {
        _list = [];
        _g.vis[_i] = _list;
    }
    var _n = Vis_Compute(_g, _cx, _cy, _tiles, _see_through, _face);
    array_push(_list, _n);
    return _n;
}

// Is the cell (_cx,_cy) lit in this set? (a cell outside the set's window is not)
function Vis_Has(_cone, _cx, _cy) {
    var _dx = _cx - _cone.cx + _cone.r;
    var _dy = _cy - _cone.cy + _cone.r;
    if (_dx < 0 || _dy < 0 || _dx >= _cone.side || _dy >= _cone.side) return false;
    return (_cone.cells[_dy * _cone.side + _dx] != 0);
}

// The radius (tiles) an enemy sees and lights with: its sight, one more while it chases (the same extra tile EnemyAI_Update gives it), nothing for a boss.
function Vis_EnemyTiles(_prof, _ai_mode) {
    if (_prof.fixed || _prof.sight <= 0) return 0;
    return _prof.sight + ((_ai_mode == "chase") ? 1 : 0);
}

// ---- reservations: which enemy holds which cell (its own cell and the one it is stepping into) ----
function Nav_ResCreate() {
    return { cells: {} };
}

function Nav_ResKey(_cx, _cy) {
    return string(_cx) + "," + string(_cy);
}

// -1 when nobody holds the cell.
function Nav_ResOwnerAt(_r, _cx, _cy) {
    var _k = Nav_ResKey(_cx, _cy);
    if (!variable_struct_exists(_r.cells, _k)) return -1;
    return variable_struct_get(_r.cells, _k);
}

function Nav_ResClaim(_r, _owner, _cx, _cy) {
    var _o = Nav_ResOwnerAt(_r, _cx, _cy);
    if (_o != -1 && _o != _owner) return false;
    variable_struct_set(_r.cells, Nav_ResKey(_cx, _cy), _owner);
    return true;
}

function Nav_ResRelease(_r, _owner) {
    var _names = variable_struct_get_names(_r.cells);
    for (var _i = 0; _i < array_length(_names); _i++) {
        if (variable_struct_get(_r.cells, _names[_i]) == _owner) variable_struct_remove(_r.cells, _names[_i]);
    }
}

// ---- A* on the 4-neighbour cell grid ----
// Returns the cells to walk as [[cx,cy], ...], first step first, the goal last; [] when already there or no way.
// The goal cell is always enterable (it is where the target stands: contact starts the fight). Cells held by another owner
// in _res are walls for this query.
function Nav_FindPath(_g, _sx, _sy, _gx, _gy, _res = undefined, _owner = -1) {
    if (!Nav_GridInside(_g, _sx, _sy) || !Nav_GridInside(_g, _gx, _gy)) return [];
    if (_sx == _gx && _sy == _gy) return [];
    var _w = _g.w;
    var _n = _w * _g.h;
    var _cost = array_create(_n, -1);
    var _par = array_create(_n, -1);
    var _done = array_create(_n, false);
    var _open = [];
    var _s = _sy * _w + _sx;
    var _goal = _gy * _w + _gx;
    _cost[_s] = 0;
    array_push(_open, _s);
    var _dxs = [1, 0, -1, 0];
    var _dys = [0, -1, 0, 1];
    while (array_length(_open) > 0) {
        // cheapest f = cost + Manhattan distance; ties go to the cell nearer the goal, then to the lower index
        var _bi = 0;
        var _bf = -1;
        for (var _i = 0; _i < array_length(_open); _i++) {
            var _idx = _open[_i];
            var _h = abs((_idx mod _w) - _gx) + abs((_idx div _w) - _gy);
            var _f = (_cost[_idx] + _h) * 1000 + _h;
            if (_bf < 0 || _f < _bf || (_f == _bf && _idx < _open[_bi])) { _bf = _f; _bi = _i; }
        }
        var _cur = _open[_bi];
        _open[_bi] = _open[array_length(_open) - 1];
        array_pop(_open);
        if (_cur == _goal) {
            var _rev = [];
            var _c = _cur;
            while (_c != _s) {
                array_push(_rev, [_c mod _w, _c div _w]);
                _c = _par[_c];
            }
            var _out = [];
            for (var _j = array_length(_rev) - 1; _j >= 0; _j--) array_push(_out, _rev[_j]);
            return _out;
        }
        _done[_cur] = true;
        var _cx = _cur mod _w;
        var _cy = _cur div _w;
        for (var _d = 0; _d < 4; _d++) {
            var _nx = _cx + _dxs[_d];
            var _ny = _cy + _dys[_d];
            if (!Nav_GridInside(_g, _nx, _ny)) continue;
            var _ni = _ny * _w + _nx;
            if (_done[_ni]) continue;
            if (_ni != _goal) {
                if (_g.block[_ni] != 0) continue;
                if (!is_undefined(_res)) {
                    var _o = Nav_ResOwnerAt(_res, _nx, _ny);
                    if (_o != -1 && _o != _owner) continue;
                }
            }
            var _ng = _cost[_cur] + 1;
            if (_cost[_ni] == -1) {
                _cost[_ni] = _ng;
                _par[_ni] = _cur;
                array_push(_open, _ni);
            } else if (_ng < _cost[_ni]) {
                _cost[_ni] = _ng;
                _par[_ni] = _cur;
            }
        }
    }
    return [];
}

// One step for an enemy at cell (_sx,_sy) toward (_gx,_gy): { ok, cx, cy, dir, len }. ok=false means stay (no way, or every way
// is held by another enemy). On ok the next cell is claimed for _owner (except the target's own cell: touching it is the fight).
function Nav_StepToward(_g, _r, _owner, _sx, _sy, _gx, _gy) {
    var _res = { ok: false, cx: _sx, cy: _sy, dir: -1, len: 0 };
    var _p = Nav_FindPath(_g, _sx, _sy, _gx, _gy, _r, _owner);
    if (array_length(_p) == 0) return _res;
    var _c = _p[0];
    if (!(_c[0] == _gx && _c[1] == _gy)) {
        if (!Nav_ResClaim(_r, _owner, _c[0], _c[1])) return _res;
    }
    _res.ok = true;
    _res.cx = _c[0];
    _res.cy = _c[1];
    _res.len = array_length(_p);
    if (_c[0] > _sx) _res.dir = RIGHT;
    else if (_c[0] < _sx) _res.dir = LEFT;
    else if (_c[1] > _sy) _res.dir = DOWN;
    else _res.dir = UP;
    return _res;
}

// ============================================================================
// SNAP (I-048, D69): everything that walks lives on the 16 px grid (origin 0,0 in every room, D65). Nearest multiple of 16.
// ============================================================================
function Grid_Snap(_v) {
    return round(_v / GRID_TILE_SIZE) * GRID_TILE_SIZE;
}

function Grid_SnapPoint(_x, _y) {
    return { x: Grid_Snap(_x), y: Grid_Snap(_y) };
}

function Grid_IsAligned(_v) {
    return (abs(_v - Grid_Snap(_v)) < 0.001);
}

// True when the 16 px tile at (_x,_y) is free for _inst (wall, interactable, exit tile), tested with the instance's own mask.
function Grid_TileFree(_inst, _x, _y) {
    var _free = true;
    with (_inst) {
        _free = !place_meeting(_x, _y, obj_wall) && !place_meeting(_x, _y, obj_interactable) && !place_meeting(_x, _y, obj_room_transition);
    }
    return _free;
}

// The nearest grid cell that is free for _inst: the rounded cell first, then the other three cells touching the point
// (nearest first). Falls back to the rounded cell when all are blocked, so a snap never leaves the instance off-grid.
function Grid_FindFreeSnap(_inst, _x, _y, _is_free = Grid_TileFree) {
    var _fx = floor(_x / GRID_TILE_SIZE) * GRID_TILE_SIZE;
    var _fy = floor(_y / GRID_TILE_SIZE) * GRID_TILE_SIZE;
    var _best = Grid_SnapPoint(_x, _y);
    if (_is_free(_inst, _best.x, _best.y)) return _best;
    var _cand = [];
    for (var _ix = 0; _ix < 2; _ix++) {
        for (var _iy = 0; _iy < 2; _iy++) {
            var _cx = _fx + _ix * GRID_TILE_SIZE;
            var _cy = _fy + _iy * GRID_TILE_SIZE;
            if (_cx == _best.x && _cy == _best.y) continue;
            array_push(_cand, { x: _cx, y: _cy, d: point_distance(_x, _y, _cx, _cy) });
        }
    }
    array_sort(_cand, function(_a, _b) { return _a.d - _b.d; });
    for (var _i = 0; _i < array_length(_cand); _i++) {
        if (_is_free(_inst, _cand[_i].x, _cand[_i].y)) return { x: _cand[_i].x, y: _cand[_i].y };
    }
    return _best;
}

// Moves an enemy (or the player) onto the grid. Returns true when it had to move. Never called mid-step.
function Enemy_SnapToGrid(_inst) {
    if (Grid_IsAligned(_inst.x) && Grid_IsAligned(_inst.y)) return false;
    var _p = Grid_FindFreeSnap(_inst, _inst.x, _inst.y);
    _inst.x = _p.x;
    _inst.y = _p.y;
    return true;
}

// ============================================================================
// PLAYER WORLD FX (D70): the interact prompt. A small bobbing arrow over the interactable the player faces, drawn by World_DrawFx
// (a layer script registered from obj_player Step: objects have no Draw event, and .yy files are not edited).
// ============================================================================
function Player_PromptWorthy(_t) {
    if (!instance_exists(_t)) return false;
    if (_t.visible) return true;
    return (variable_instance_exists(_t, "interact_kind") && _t.interact_kind != INTERACT_NONE);
}

function Player_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    if (!variable_global_exists("player_fx_calls")) global.player_fx_calls = 0;
    global.player_fx_calls++;
    if (!instance_exists(obj_player)) return;
    var _pl = instance_find(obj_player, 0);
    if (!variable_instance_exists(_pl, "prompt_target") || !instance_exists(_pl.prompt_target)) return;
    var _t = _pl.prompt_target;
    var _c0 = UI_C_DARKEST;
    var _c3 = UI_C_LIGHTEST;
    var _oc = draw_get_color();
    var _oa = draw_get_alpha();
    draw_set_alpha(1);
    var _bob = (current_time div 260) mod 2;
    var _cx = floor((_t.bbox_left + _t.bbox_right) / 2);
    var _y = floor(_t.bbox_top) - 7 - _bob;
    // I-059: a one pixel #071821 outline all the way round the light arrow, so it reads on a light floor too.
    // Rows are [offset from the light top row, half width]: the light arrow is 5, 3, 1 wide; the outline is the pixels touching it above, below and beside.
    var _outline = [[-1, 2], [0, 3], [1, 2], [2, 1], [3, 0]];
    var _light = [[0, 2], [1, 1], [2, 0]];
    draw_set_color(_c0);
    for (var _r = 0; _r < array_length(_outline); _r++) draw_rectangle(_cx - _outline[_r][1], _y + _outline[_r][0], _cx + _outline[_r][1], _y + _outline[_r][0], false);
    draw_set_color(_c3);
    for (var _r2 = 0; _r2 < array_length(_light); _r2++) draw_rectangle(_cx - _light[_r2][1], _y + _light[_r2][0], _cx + _light[_r2][1], _y + _light[_r2][0], false);
    draw_set_color(_oc);
    draw_set_alpha(_oa);
}

// ============================================================================
// H11 (D153, D158): smarter map AI, hiding spots, no spawn camping. Pure functions first (Test_Suite_MapAI); the instance code only calls them.
// ============================================================================
// True when an enemy standing on cell (_ecx,_ecy) hears a player on cell (_pcx,_pcy): running only, straight-line distance, walls do not matter.
function Hear_RunHeard(_ecx, _ecy, _pcx, _pcy, _running) {
    if (!_running) return false;
    return point_distance(_ecx, _ecy, _pcx, _pcy) <= AI_HEAR_RUN_TILES;
}

// The cell a fleeing player most likely ran to: from the last seen cell straight on in _dir (RIGHT, UP, LEFT, DOWN, or -1 for none), up to _tiles cells, stopping before a blocked cell or the room edge.
function Search_FleeCell(_g, _lcx, _lcy, _dir, _tiles) {
    var _dx = (_dir == RIGHT) - (_dir == LEFT);
    var _dy = (_dir == DOWN) - (_dir == UP);
    var _cx = _lcx;
    var _cy = _lcy;
    if (_dx == 0 && _dy == 0) return { cx: _cx, cy: _cy };
    for (var _i = 0; _i < _tiles; _i++) {
        if (Nav_CellBlocked(_g, _cx + _dx, _cy + _dy)) break;
        _cx += _dx;
        _cy += _dy;
    }
    return { cx: _cx, cy: _cy };
}

// A search that starts when the enemy stands on the last seen cell: look (stage 0), walk the flee leg (1), look again and give up with ONE "?" (2), done (3).
function Search_Create(_lcx, _lcy, _dir, _look_frames) {
    return { stage: 0, lcx: _lcx, lcy: _lcy, dir: _dir, look: max(1, _look_frames), timer: 0, fcx: _lcx, fcy: _lcy, popped: false };
}

// One decision of a search for an enemy on cell (_ecx,_ecy). Returns { goal_cx, goal_cy, pop, done }: goal_cx < 0 means stay here; pop is true on the one step the "?" goes up; done ends the search.
function Search_Step(_se, _g, _ecx, _ecy) {
    var _out = { goal_cx: -1, goal_cy: -1, pop: false, done: false };
    switch (_se.stage) {
        case 0:
            _se.timer++;
            if (_se.timer >= _se.look) {
                var _fc = Search_FleeCell(_g, _se.lcx, _se.lcy, _se.dir, AI_FLEE_SEARCH_TILES);
                _se.fcx = _fc.cx;
                _se.fcy = _fc.cy;
                _se.stage = (_fc.cx != _se.lcx || _fc.cy != _se.lcy) ? 1 : 2;
                _se.timer = 0;
            }
            break;
        case 1:
            if (_ecx == _se.fcx && _ecy == _se.fcy) {
                _se.stage = 2;
                _se.timer = 0;
            } else {
                _out.goal_cx = _se.fcx;
                _out.goal_cy = _se.fcy;
            }
            break;
        case 2:
            if (!_se.popped) {
                _se.popped = true;
                _out.pop = true;
            }
            _se.timer++;
            if (_se.timer >= _se.look) {
                _se.stage = 3;
                _out.done = true;
            }
            break;
        default:
            _out.done = true;
            break;
    }
    return _out;
}

// A search that cannot go on (the enemy is stuck on its way): straight to giving up.
function Search_GiveUp(_se) {
    if (_se.stage < 2) {
        _se.stage = 2;
        _se.timer = 0;
    }
}

// The hiding cells of a room (D153): [[cx, cy], ...], picked by hand from the room art (the dark grass patches and the foliage along the walls, see gridshots).
// Free floor cells only; rooms without any return []. The owner reviews them at the playtest.
function Hide_Cells(_room_name) {
    switch (_room_name) {
        case "rm_floor2": return [[3, 3], [12, 3]];
        case "rm_floor3": return [[3, 4]];
        case "rm_floor4": return [[4, 3]];
        case "rm_floor5": return [[4, 2]];
        case "rm_floor6": return [[4, 3]];
        case "rm_floor7": return [[9, 2]];
    }
    return [];
}

function Hide_IsCell(_room_name, _cx, _cy) {
    var _cells = Hide_Cells(_room_name);
    for (var _i = 0; _i < array_length(_cells); _i++) {
        if (_cells[_i][0] == _cx && _cells[_i][1] == _cy) return true;
    }
    return false;
}

// True when the player counts as hidden: standing still (not mid-step) for HIDE_SETTLE_FRAMES on one of the room's hiding cells (_cells = Hide_Cells(room name)).
function Sight_PlayerHidden(_cells, _pcx, _pcy, _moving, _still_frames) {
    if (_moving || _still_frames < HIDE_SETTLE_FRAMES) return false;
    for (var _i = 0; _i < array_length(_cells); _i++) {
        if (_cells[_i][0] == _pcx && _cells[_i][1] == _pcy) return true;
    }
    return false;
}

// Can an enemy at pixel (_ex,_ey) facing _face see a player at pixel (_px,_py)? The player's cell must be one the enemy's sight reaches (Vis_Cone: the 90 degree cone in front of it
// and the ring of 1 tile all round it, out to _tiles, cut off by whatever blocks sight; D179), unless _see_through (the cone still applies); a hidden player only from HIDE_SEEN_TILES.
// _face -1: no facing, the whole circle (only a check that wants the old shape passes it; the game always has a facing).
function Sight_CanSee(_g, _ex, _ey, _px, _py, _tiles, _see_through, _hidden, _face = -1) {
    if (_tiles <= 0) return false;
    var _half = GRID_TILE_SIZE / 2;
    var _ecx = Nav_CellOf(_ex + _half);
    var _ecy = Nav_CellOf(_ey + _half);
    var _pcx = Nav_CellOf(_px + _half);
    var _pcy = Nav_CellOf(_py + _half);
    if (_hidden && max(abs(_ecx - _pcx), abs(_ecy - _pcy)) > HIDE_SEEN_TILES) return false;
    return Vis_Has(Vis_Cone(_g, _ecx, _ecy, _tiles, _see_through, _face), _pcx, _pcy);
}

// What an enemy (profile _prof, pixel position _ex,_ey) notices of a player at pixel (_px,_py): { sees, heard }. heard only counts when it does not see him.
function EnemyAI_Perceive(_g, _prof, _ex, _ey, _px, _py, _running, _hidden, _face = -1) {
    var _half = GRID_TILE_SIZE / 2;
    var _sees = Sight_CanSee(_g, _ex, _ey, _px, _py, _prof.sight, _prof.see_through, _hidden, _face);
    var _heard = !_sees && Hear_RunHeard(Nav_CellOf(_ex + _half), Nav_CellOf(_ey + _half), Nav_CellOf(_px + _half), Nav_CellOf(_py + _half), _running);
    return { sees: _sees, heard: _heard };
}

// Distance in tiles from a cell to the nearest exit cell of the grid (9999 when the room has none).
function Nav_ExitDist(_g, _cx, _cy) {
    var _d = 9999;
    for (var _i = 0; _i < array_length(_g.exits); _i++) _d = min(_d, point_distance(_cx, _cy, _g.exits[_i][0], _g.exits[_i][1]));
    return _d;
}

function Nav_GridAddExit(_g, _cx, _cy) {
    array_push(_g.exits, [_cx, _cy]);
}

// The nearest cell (by walking) from (_fcx,_fcy) that is at least _min_exit tiles from every exit and _arr_clear tiles from the arrival cell (_arr_cx < 0: no arrival). { ok, cx, cy }.
function Nav_SafeCell(_g, _fcx, _fcy, _min_exit, _arr_cx, _arr_cy, _arr_clear) {
    if (!Nav_GridInside(_g, _fcx, _fcy)) return { ok: false, cx: _fcx, cy: _fcy };
    var _seen = array_create(_g.w * _g.h, false);
    var _q = [[_fcx, _fcy]];
    _seen[_fcy * _g.w + _fcx] = true;
    var _dxs = [1, 0, -1, 0];
    var _dys = [0, 1, 0, -1];
    var _i = 0;
    while (_i < array_length(_q)) {
        var _c = _q[_i++];
        if (!Nav_CellBlocked(_g, _c[0], _c[1]) && Nav_ExitDist(_g, _c[0], _c[1]) >= _min_exit
            && (_arr_cx < 0 || point_distance(_c[0], _c[1], _arr_cx, _arr_cy) >= _arr_clear)) {
            return { ok: true, cx: _c[0], cy: _c[1] };
        }
        for (var _d = 0; _d < 4; _d++) {
            var _nx = _c[0] + _dxs[_d];
            var _ny = _c[1] + _dys[_d];
            if (!Nav_GridInside(_g, _nx, _ny) || _seen[_ny * _g.w + _nx]) continue;
            _seen[_ny * _g.w + _nx] = true;
            if (!Nav_CellBlocked(_g, _nx, _ny)) array_push(_q, [_nx, _ny]);
        }
    }
    return { ok: false, cx: _fcx, cy: _fcy };
}

// Where an enemy belongs when the player arrives at cell (_arr_cx,_arr_cy): { cx, cy, moved, home_cx, home_cy }. Left alone unless it stands nearer than AI_EXIT_RELOCATE_TILES
// to an exit or nearer than AI_ARRIVAL_CLEAR_TILES to the arrival. Then it goes home when home is clear of both, else to the nearest clear cell (which becomes its home).
function Enemy_ArrivalCell(_g, _ecx, _ecy, _hcx, _hcy, _arr_cx, _arr_cy) {
    var _out = { cx: _ecx, cy: _ecy, moved: false, home_cx: _hcx, home_cy: _hcy };
    var _has_arr = (_arr_cx >= 0);
    var _bad = (Nav_ExitDist(_g, _ecx, _ecy) < AI_EXIT_RELOCATE_TILES) || (_has_arr && point_distance(_ecx, _ecy, _arr_cx, _arr_cy) < AI_ARRIVAL_CLEAR_TILES);
    if (!_bad) return _out;
    var _home_ok = !Nav_CellBlocked(_g, _hcx, _hcy) && Nav_ExitDist(_g, _hcx, _hcy) >= AI_EXIT_RELOCATE_TILES
        && (!_has_arr || point_distance(_hcx, _hcy, _arr_cx, _arr_cy) >= AI_ARRIVAL_CLEAR_TILES);
    if (_home_ok) {
        _out.cx = _hcx;
        _out.cy = _hcy;
        _out.moved = (_hcx != _ecx || _hcy != _ecy);
        return _out;
    }
    var _s = Nav_SafeCell(_g, _ecx, _ecy, AI_EXIT_RELOCATE_TILES, _arr_cx, _arr_cy, AI_ARRIVAL_CLEAR_TILES);
    if (_s.ok) {
        _out.cx = _s.cx;
        _out.cy = _s.cy;
        _out.moved = (_s.cx != _ecx || _s.cy != _ecy);
        _out.home_cx = _s.cx;
        _out.home_cy = _s.cy;
    }
    return _out;
}

// The next patrol target for an enemy on (_ecx,_ecy) with home (_hcx,_hcy): a free cell inside the roaming range, not near an exit (D158). undefined when none was found.
function Idle_PatrolTarget(_g, _hcx, _hcy, _roam, _ecx, _ecy) {
    for (var _try = 0; _try < 8; _try++) {
        var _cx = _hcx + irandom_range(-_roam, _roam);
        var _cy = _hcy + irandom_range(-_roam, _roam);
        if (abs(_cx - _ecx) + abs(_cy - _ecy) < 2) continue;
        if (Nav_CellBlocked(_g, _cx, _cy)) continue;
        if (Nav_ExitDist(_g, _cx, _cy) < AI_EXIT_CLEAR_TILES) continue;
        return [_cx, _cy];
    }
    return undefined;
}

// May a wandering enemy on (_ecx,_ecy) step to (_tcx,_tcy)? Not into the zone round an exit, unless it is a step away from the exit.
function Idle_StepAllowed(_g, _ecx, _ecy, _tcx, _tcy) {
    var _dt = Nav_ExitDist(_g, _tcx, _tcy);
    if (_dt >= AI_EXIT_CLEAR_TILES) return true;
    return _dt > Nav_ExitDist(_g, _ecx, _ecy);
}

// ---- the player side: running, standing still, hidden ----
// Running = a step that goes at the run speed (fixed for the whole step, obj_player Step).
function Player_IsRunning(_pl) {
    return _pl.moving && _pl.step_speed > _pl.walk_speed;
}

// Counts the frames the player has stood still (reset by any step). Called from obj_player Step.
function Player_TrackStill(_pl) {
    if (!variable_instance_exists(_pl, "still_frames")) _pl.still_frames = 0;
    if (_pl.moving) _pl.still_frames = 0;
    else _pl.still_frames = min(_pl.still_frames + 1, 100000);
}

function Player_IsHidden(_pl) {
    if (!variable_instance_exists(_pl, "still_frames")) return false;
    var _half = GRID_TILE_SIZE / 2;
    return Sight_PlayerHidden(Hide_Cells(room_get_name(room)), Nav_CellOf(_pl.x + _half), Nav_CellOf(_pl.y + _half), _pl.moving, _pl.still_frames);
}

// A hidden player is drawn see-through (obj_player Step, end): readable at a glance, no new asset.
function Player_ApplyHiddenLook(_pl) {
    _pl.image_alpha = Player_IsHidden(_pl) ? HIDE_PLAYER_ALPHA : 1;
}

// ---- the enemy side ----
// The "?" goes up over an enemy that gave up its search (once per search).
function EnemyAI_PopQuestion(_inst) {
    _inst.question_pop = AI_QUESTION_FRAMES;
    _inst.q_pops++;
    SFX_Play("alert_lost", 0.35, 0.9);   // the "!" sound a little lower and softer: "hm?" (SFX bus)
}

// D158: on a room arrival (the player is placed) every enemy that stands near an exit or near the arrival tile is put back (home, or a clear spot) and forgets its chase.
// Bosses and story enemies (cine_id) stay where the room has them; the Stranger does not (bug hunt 7: D158 says "no enemy", and he is one on the map). Returns how many were moved.
// What it moved is saved at once (RoomState_Save): the autosave of the arrival and a Quit to title then hold the room as it stands, so a Continue shows the same room (D132).
function Enemy_ArrivalFix(_pl) {
    if (!instance_exists(_pl)) return 0;
    var _t = GRID_TILE_SIZE;
    var _g = Nav_Get().grid;
    var _acx = Nav_CellOf(_pl.x + _t / 2);
    var _acy = Nav_CellOf(_pl.y + _t / 2);
    var _n = 0;
    with (obj_enemy) {
        if (defeated || enemy_id < 0) continue;
        if (variable_instance_exists(id, "cine_id") && string(cine_id) != "") continue;
        if (EnemyDB_Get(enemy_id).is_boss) continue;
        var _r = Enemy_ArrivalCell(_g, Nav_CellOf(x + _t / 2), Nav_CellOf(y + _t / 2), Nav_CellOf(home_x + _t / 2), Nav_CellOf(home_y + _t / 2), _acx, _acy);
        if (!_r.moved) continue;
        x = _r.cx * _t;
        y = _r.cy * _t;
        home_x = _r.home_cx * _t;
        home_y = _r.home_cy * _t;
        moving = false;
        move_timer = 0;
        move_dir = -1;
        if (variable_instance_exists(id, "ai_mode")) {
            ai_mode = "idle";
            srch = undefined;
            question_pop = 0;
            alert_pop = 0;
            react_timer = 0;
            patrol_cx = -1;
            stuck_frames = 0;
            retry_timer = 0;
            home_cx = _r.home_cx;
            home_cy = _r.home_cy;
        }
        _n++;
    }
    if (_n > 0) RoomState_Save(room);
    return _n;
}
