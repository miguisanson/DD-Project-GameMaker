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

function Enemy_AutoResolveBuildMessage(_cfg, _result, _verb_prefix = "You overpower ") {
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

    var levels = (variable_struct_exists(_result, "levels_gained")) ? max(0, round(real(_result.levels_gained))) : 0;
    var stat_points = (variable_struct_exists(_result, "stat_points_gained")) ? max(0, round(real(_result.stat_points_gained))) : 0;
    var auto_summary = (variable_struct_exists(_result, "auto_stat_summary")) ? string(_result.auto_stat_summary) : "";
    if (levels > 0) {
        var lvl_msg = Loc_T("combat.msg.level_up", "Level up x{levels}!", { levels: levels });
        if (stat_points > 0 || auto_summary != "") {
            lvl_msg += " (";
            var sub = [];
            if (stat_points == 1) array_push(sub, Loc_T("combat.msg.stat_point_one", "+{n} stat point", { n: stat_points }));
            else if (stat_points > 1) array_push(sub, Loc_T("combat.msg.stat_points_many", "+{n} stat points", { n: stat_points }));
            if (auto_summary != "") array_push(sub, Loc_T("combat.msg.auto_stats", "auto {summary}", { summary: auto_summary }));
            for (var si = 0; si < array_length(sub); si++) {
                if (si > 0) lvl_msg += ", ";
                lvl_msg += sub[si];
            }
            lvl_msg += ")";
        }
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

    var loot = Loot_RollEnemy({ id: _enemy_id, level: _enemy_level, loot_key: _loot_key });
    if (loot_mult < 1 && is_array(loot)) {
        var kept = [];
        for (var i = 0; i < array_length(loot); i++) {
            if (RunRng_Float("loot") <= loot_mult) array_push(kept, loot[i]);
        }
        loot = kept;
    }
    p.inventory = Loot_Grant(p.inventory, loot);
    p = Card_OnVictory(p);   // C2: Field Medic, Second Wind, Scrounger
    GameState_SetPlayer(p);

    var result = {
        exp_gain: exp_gain,
        levels_gained: variable_struct_exists(p, "last_levels_gained") ? max(0, round(real(p.last_levels_gained))) : 0,
        stat_points_gained: variable_struct_exists(p, "last_stat_points_gained") ? max(0, round(real(p.last_stat_points_gained))) : 0,
        auto_stat_summary: LevelUp_AutoGainSummary(p),
        loot_gained: is_array(loot) && array_length(loot) > 0,
        at_level_cap: at_cap_before || Level_IsAtCap(p.level)
    };

    Dialogue_NarrativeOnLevelUp(result.levels_gained);
    Dialogue_NarrativeOnEnemyDefeated(_enemy_id, room);

    if (variable_struct_exists(cfg, "name")) _enemy_name = cfg.name;
    var summary = Enemy_AutoResolveBuildMessage({ name: _enemy_name }, result);
    var loot_entries = Loot_BuildMessageEntries(loot, "Loot: ");
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
//   sight       tiles; an enemy notices the player inside this circle when no wall is between (see_through ignores walls)
//   chase       speed while chasing / walking to the last seen spot
//   idle        "wander" (pause, one step, pause), "drift" (steps almost without pause), "patrol" (walks legs to far spots),
//               "still" (ambusher: stays on its post)
//   idle_speed  speed while idling;  pause_min..pause_max frames between idle steps;  roam tiles from home
//   search      frames spent looking at the last seen spot;  react frames between spotting the player and moving
//   pass        true = ignores walls and objects (ghosts), only the room edge stops it
//   fixed       true = never moves (bosses): the old square-trigger rules still apply to ai_stationary enemies
// The numbers are first guesses for the owner to tune by playing (reported in the packet notes).
// ----------------------------------------------------------------------------
function EnemyAI_Profile(_enemy_id) {
    var _p = { sight: 4, chase: 0.8, idle: "wander", idle_speed: 0.6, pause_min: 40, pause_max: 100, roam: 3,
               search: 90, react: 14, pass: false, see_through: false, fixed: false, ret_speed: 0.8 };
    switch (_enemy_id) {
        case ENEMY_SLIME:        _p.chase = 0.7;  _p.idle_speed = 0.4; _p.pause_min = 60; _p.pause_max = 140; _p.roam = 2; _p.ret_speed = 0.6; break;
        case ENEMY_SPIDER:       _p.chase = 0.85; _p.idle_speed = 0.8; _p.pause_min = 25; _p.pause_max = 70; break;
        case ENEMY_SNAKE:        _p.chase = 0.85; _p.idle_speed = 0.7; _p.pause_min = 30; _p.pause_max = 80; break;
        case ENEMY_MADWHISP:     _p.sight = 5; _p.chase = 0.85; _p.idle = "drift"; _p.idle_speed = 0.5; _p.pause_min = 0; _p.pause_max = 8; _p.roam = 4; break;
        case ENEMY_KILLER_PLANT: _p.sight = 3; _p.chase = 0.8; _p.idle = "still"; _p.roam = 0; _p.search = 60; _p.react = 20; break;
        case ENEMY_DIREWOLF:     _p.sight = 5; _p.chase = 1.0; _p.idle = "patrol"; _p.idle_speed = 0.9; _p.pause_min = 20; _p.pause_max = 50; _p.roam = 5; _p.react = 8; _p.ret_speed = 0.9; break;
        case ENEMY_GHOSTSWORD:   _p.chase = 0.85; _p.idle = "drift"; _p.idle_speed = 0.6; _p.pause_min = 0; _p.pause_max = 10; _p.roam = 4; _p.pass = true; _p.see_through = true; break;
        case ENEMY_STRANGER:     _p.sight = 5; _p.chase = 0.9; _p.idle_speed = 0.7; _p.pause_min = 40; _p.pause_max = 90; _p.react = 20; break;
        case ENEMY_MINI_BOSS:
        case ENEMY_FINAL_BOSS:   _p.sight = 0; _p.idle = "still"; _p.roam = 0; _p.fixed = true; break;
    }
    return _p;
}

// ----------------------------------------------------------------------------
// Room integration of the pure Nav code: one grid and one reservation table per loaded room, built lazily from the instances.
// Rebuilt when a blocker appears or disappears (barrel broken, chest opened and replaced). Nothing hooks into the game controller.
// ----------------------------------------------------------------------------
function Nav_MarkInstance(_g, _block, _sight) {
    // runs in the scope of the instance being marked
    var _t = GRID_TILE_SIZE;
    var _x0 = floor(bbox_left / _t);
    var _x1 = floor((bbox_right - 0.01) / _t);
    var _y0 = floor(bbox_top / _t);
    var _y1 = floor((bbox_bottom - 0.01) / _t);
    for (var _cx = _x0; _cx <= _x1; _cx++) {
        for (var _cy = _y0; _cy <= _y1; _cy++) Nav_GridSet(_g, _cx, _cy, _block, _sight);
    }
}

function Nav_BuildGrid() {
    var _g = Nav_GridCreate(ceil(room_width / GRID_TILE_SIZE), ceil(room_height / GRID_TILE_SIZE));
    with (obj_wall) Nav_MarkInstance(_g, true, true);
    with (obj_interactable) Nav_MarkInstance(_g, true, false);
    with (obj_room_transition) Nav_MarkInstance(_g, true, false);   // enemies never park on an exit
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
// Overworld AI (D63, D66, D67). Modes: idle -> chase (sees the player) -> search (lost sight: wait at the last seen spot)
// -> return (walk home) -> idle. Movement is always a 16 px step toward a path cell; the enemy rests on the grid between steps.
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
    _inst.search_timer = 0;
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
}

// Notices the player: inside the sight circle and (unless see_through) no wall on the line between the two cells.
function EnemyAI_CanSee(_inst, _pl, _nav, _tiles) {
    if (_tiles <= 0) return false;
    var _half = GRID_TILE_SIZE / 2;
    if (point_distance(_inst.x, _inst.y, _pl.x, _pl.y) > _tiles * GRID_TILE_SIZE) return false;
    if (_inst.prof.see_through) return true;
    return Nav_LineClear(_nav.grid, Nav_CellOf(_inst.x + _half), Nav_CellOf(_inst.y + _half), Nav_CellOf(_pl.x + _half), Nav_CellOf(_pl.y + _half));
}

function EnemyAI_BeginStep(_inst, _dir, _speed) {
    var _t = GRID_TILE_SIZE;
    var _mx = (_dir == RIGHT) - (_dir == LEFT);
    var _my = (_dir == DOWN) - (_dir == UP);
    _inst.move_dir = _dir;
    _inst.last_dir = _dir;
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
    World_RegisterFx(_inst);   // the "!" and the sight circle are drawn by the world layer script (objects have no Draw event, no .yy edits)

    var _t = GRID_TILE_SIZE;
    if (_inst.alert_pop > 0) _inst.alert_pop--;
    if (_inst.spot_cooldown > 0) _inst.spot_cooldown--;

    // ---- senses ----
    var _pcx = Nav_CellOf(_pl.x + _t / 2);
    var _pcy = Nav_CellOf(_pl.y + _t / 2);
    var _sees = (_inst.spot_cooldown <= 0) && EnemyAI_CanSee(_inst, _pl, _nav, _p.sight);
    if (_inst.ai_mode == "chase") {
        // a little extra range once chasing so the edge of the circle does not flicker
        if (_sees || EnemyAI_CanSee(_inst, _pl, _nav, _p.sight + 1)) {
            _inst.last_seen_cx = _pcx;
            _inst.last_seen_cy = _pcy;
            _inst.search_timer = 0;
            _sees = true;
        }
    } else if (_sees) {
        _inst.ai_mode = "chase";
        _inst.last_seen_cx = _pcx;
        _inst.last_seen_cy = _pcy;
        _inst.alert_pop = 50;
        _inst.react_timer = _p.react;
        _inst.patrol_cx = -1;
        _inst.stuck_frames = 0;
        Nav_Stats().spots++;
        SFX_Play("ui_confirm", 0.5, 1.5);   // existing sound, small and high: "!"
    }
    _inst.ai_state = (_inst.ai_mode == "chase" || _inst.ai_mode == "search") ? ENEMY_ALERT : ENEMY_IDLE;
    if (_inst.ai_state == ENEMY_ALERT) _inst.forget_time = _inst.forget_delay;

    // ---- decide (only between steps) ----
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
                        _inst.ai_mode = "search";
                        _inst.search_timer = _p.search;
                    } else if (_ecx != _gx || _ecy != _gy) {
                        EnemyAI_Pursue(_inst, _nav, _gx, _gy, _p.chase);
                    }
                    break;
                case "search":
                    _inst.stuck_frames = 0;
                    _inst.search_timer--;
                    if (_inst.search_timer <= 0) _inst.ai_mode = "return";
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
                _inst.search_timer = _p.search;
                _inst.spot_cooldown = 180;
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
            for (var _try = 0; _try < 8; _try++) {
                var _cx = _inst.home_cx + irandom_range(-_p.roam, _p.roam);
                var _cy = _inst.home_cy + irandom_range(-_p.roam, _p.roam);
                if (abs(_cx - _ecx) + abs(_cy - _ecy) < 2) continue;
                if (Nav_CellBlocked(_nav.grid, _cx, _cy)) continue;
                _inst.patrol_cx = _cx;
                _inst.patrol_cy = _cy;
                break;
            }
            if (_inst.patrol_cx < 0) { _inst.idle_timer = 30; return; }
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

// ONE layer script draws every world mark (the sight rings and "!" of enemies, the interact arrow of the player): a layer has only one end script,
// and the player and the enemies share the "Instances" layer, so two registrations would replace each other (measured: the arrow vanished).
// Registered once per room START by whoever gets here first (the player's Step, an enemy's update): a re-entered room (after a battle, a run,
// a save load) has new layers, and the old once-ever flag left it without any mark (I-056).
function World_RegisterFx(_inst) {
    var _st = Room_Stamp();
    if (variable_global_exists("world_fx_stamp") && global.world_fx_stamp == _st) return;
    if (!layer_exists(_inst.layer)) return;
    global.world_fx_stamp = _st;
    layer_script_end(_inst.layer, World_DrawFx);
}

function World_DrawFx() {
    Nav_DrawWorldFx();
    Player_DrawWorldFx();
}

// Called by World_DrawFx (a layer script, see World_RegisterFx): the "!" over an enemy that just spotted the
// player and a faint dotted ring of its sight range while the player is near. 4-colour palette, no new assets.
function Nav_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    if (!variable_global_exists("nav_fx_calls")) global.nav_fx_calls = 0;
    global.nav_fx_calls++;
    if (!instance_exists(obj_enemy)) return;
    var _pl = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
    var _c0 = make_color_rgb(7, 24, 33);
    var _c1 = make_color_rgb(48, 104, 80);
    var _c2 = make_color_rgb(134, 192, 108);
    var _c3 = make_color_rgb(224, 248, 207);
    var _oc = draw_get_color();
    var _oa = draw_get_alpha();
    draw_set_alpha(1);
    with (obj_enemy) {
        if (!defeated && variable_instance_exists(id, "prof")) {
            var _cx = x + GRID_TILE_SIZE / 2;
            var _cy = y + GRID_TILE_SIZE / 2;
            if (instance_exists(_pl) && prof.sight > 0 && !prof.fixed && point_distance(_cx, _cy, _pl.x + 8, _pl.y + 8) <= (prof.sight + 2) * GRID_TILE_SIZE) {
                var _r = prof.sight * GRID_TILE_SIZE;
                var _n = max(12, round(2 * pi * _r / 6));
                for (var _k = 0; _k < _n; _k++) {
                    draw_set_color((_k mod 2 == 0) ? _c1 : _c2);   // two greens: faint on both a light and a dark floor
                    var _a = (_k / _n) * 2 * pi;
                    draw_rectangle(floor(_cx + cos(_a) * _r), floor(_cy + sin(_a) * _r), floor(_cx + cos(_a) * _r), floor(_cy + sin(_a) * _r), false);
                }
            }
            if (alert_pop > 0) {
                var _bx = floor(_cx);
                var _by = floor(y) - 11;
                draw_set_color(_c0);
                draw_rectangle(_bx - 2, _by, _bx + 2, _by + 10, false);
                draw_set_color(_c3);
                draw_rectangle(_bx - 1, _by + 1, _bx + 1, _by + 6, false);
                draw_rectangle(_bx - 1, _by + 8, _bx + 1, _by + 9, false);
            }
        }
    }
    draw_set_color(_oc);
    draw_set_alpha(_oa);
}


// ============================================================================
// NAV (D63, I-047): pure grid pathfinding, line of sight and cell reservations.
// A grid is a struct { w, h, block[], sight[] } of 16 px cells with the origin at world (0,0) (D65: room sizes are not changed).
// block = movement blocked (wall, rock, chest, exit tile); sight = line of sight blocked (wall only).
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
    return { w: _w, h: _h, block: array_create(_w * _h, 0), sight: array_create(_w * _h, 0) };
}

// rows: array of strings. "." free, "#" wall (blocks movement and sight), "~" blocks movement only.
function Nav_GridFromRows(_rows) {
    var _h = array_length(_rows);
    var _w = 1;
    for (var _y = 0; _y < _h; _y++) _w = max(_w, string_length(_rows[_y]));
    var _g = Nav_GridCreate(_w, _h);
    for (var _y2 = 0; _y2 < _h; _y2++) {
        for (var _x = 0; _x < string_length(_rows[_y2]); _x++) {
            var _ch = string_char_at(_rows[_y2], _x + 1);
            if (_ch == "#") Nav_GridSet(_g, _x, _y2, true, true);
            else if (_ch == "~") Nav_GridSet(_g, _x, _y2, true, false);
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
    if (_sight) _g.sight[_i] = 1;
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
    var _c0 = make_color_rgb(7, 24, 33);
    var _c3 = make_color_rgb(224, 248, 207);
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
