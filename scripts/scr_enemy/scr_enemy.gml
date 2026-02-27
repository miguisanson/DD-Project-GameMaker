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
    var roll = irandom_range(-1, 1);
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

    var exp_mult = variable_struct_exists(cfg, "auto_resolve_exp_mult") ? max(0, real(cfg.auto_resolve_exp_mult)) : ENEMY_AUTO_RESOLVE_EXP_MULT_DEFAULT;
    var loot_mult = variable_struct_exists(cfg, "auto_resolve_loot_mult") ? clamp(real(cfg.auto_resolve_loot_mult), 0, 1) : ENEMY_AUTO_RESOLVE_LOOT_MULT_DEFAULT;
    var diff = Difficulty_Profile();

    var level_exp_mult = 1;
    if (variable_struct_exists(cfg, "level")) {
        level_exp_mult = clamp(1 + ((enemy_level - round(cfg.level)) * 0.10), 0.70, 1.40);
    }
    var exp_gain = max(1, round(real(cfg.exp) * level_exp_mult * exp_mult));
    if (is_struct(diff) && variable_struct_exists(diff, "player_exp_mult")) {
        exp_gain = max(1, round(exp_gain * max(0, real(diff.player_exp_mult))));
    }
    p = Player_AddExp(p, exp_gain);

    var loot = Loot_RollEnemy({ id: cfg.id, level: enemy_level, loot_key: cfg.loot_key });
    if (loot_mult < 1 && is_array(loot)) {
        var kept = [];
        for (var i = 0; i < array_length(loot); i++) {
            if (random(1) <= loot_mult) array_push(kept, loot[i]);
        }
        loot = kept;
    }
    p.inventory = Loot_Grant(p.inventory, loot);
    GameState_SetPlayer(p);

    RoomState_SetRemoved(room, _enemy_inst.persist_id, obj_enemy, _enemy_inst.enemy_id);
    instance_destroy(_enemy_inst);

    var msg = "You overpower " + string(cfg.name) + " (+"
        + string(exp_gain) + " EXP).";
    if (variable_struct_exists(p, "last_levels_gained") && p.last_levels_gained > 0) {
        var lvl_msg = " Level up x" + string(p.last_levels_gained);
        var pts = variable_struct_exists(p, "last_stat_points_gained") ? max(0, round(real(p.last_stat_points_gained))) : 0;
        lvl_msg += " (+" + string(pts) + " points";
        var auto_summary = LevelUp_AutoGainSummary(p);
        var auto_gained = variable_struct_exists(p, "last_auto_stat_gained") ? max(0, round(real(p.last_auto_stat_gained))) : 0;
        if (auto_gained > 0 && auto_summary != "") {
            lvl_msg += ", auto " + auto_summary;
        }
        lvl_msg += ").";
        msg += lvl_msg;
    }
    if (is_array(loot) && array_length(loot) > 0) {
        msg += " Loot gained.";
    }
    Dialogue_StartLines([msg]);
    return true;
}

function EnemyCreate(_enemy_id) {
    var base = EnemyDB_Get(_enemy_id);
    var diff = Difficulty_Profile();
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
        str:  max(1, round(base.stats.str)),
        agi:  max(1, round(base.stats.agi)),
        def:  max(1, round(base.stats.def)),
        intt: max(1, round(base.stats.intt)),
        luck: max(1, round(base.stats.luck))
    };

    ch.base_hp = base.base_hp;
    ch.base_mp = base.base_mp;
    ch.hd = base.hd;
    ch.mp_gain = base.mp_gain;

    // compute resources using your formula style
    var def_mod = StatMod(ch.stats.def);
    var int_mod = StatMod(ch.stats.intt);

    var hp_gain = ceil(ch.hd / 2) + 1; // BG3 average
    ch.max_hp = max(1, ch.base_hp + (ch.level - 1) * (hp_gain + def_mod));

    ch.max_mp = max(0, ch.base_mp + (ch.level - 1) * (ch.mp_gain + int_mod));
    ch.max_hp = max(1, round(ch.max_hp * diff.enemy_hp_mult));
    ch.max_mp = max(0, round(ch.max_mp * diff.enemy_mp_mult));

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
function EnemyAI_BuildContext(_inst, _cfg) {
    return { move_speed_mult: 1 };
}

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

 function EnemyAI_CanStep(_inst, _mx, _my) {
    var nx = _inst.x + _mx;
    var ny = _inst.y + _my;
    return !place_meeting(nx, ny, obj_wall)
        && !place_meeting(nx, ny, obj_interactable)
        && !place_meeting(nx, ny, obj_room_transition);
}

function EnemyAI_Update(_inst, _cfg, _pl) {
    if (_inst.defeated) return;

    var ctx = EnemyAI_BuildContext(_inst, _cfg);
    EnemyAI_ApplyTraits(_inst, _cfg, ctx, "on_update");

    // --------------------
    // LEASH CHECK
    // --------------------
    if (_inst.leash_radius > 0) {
        if (point_distance(_inst.x, _inst.y, _inst.home_x, _inst.home_y) > _inst.leash_radius) {
            _inst.ai_state = ENEMY_IDLE;
            _inst.forget_time = 0;
        }
    }

    // --------------------
    // PLAYER VALIDATION
    // --------------------
    if (!instance_exists(_pl)) return;

    var dx = _pl.x - _inst.x;
    var dy = _pl.y - _inst.y;

    // --------------------
    // DETECTION + MEMORY
    // --------------------
    if (abs(dx) <= _inst.scan_radius && abs(dy) <= _inst.scan_radius) {
        _inst.ai_state = ENEMY_ALERT;
        _inst.forget_time = _inst.forget_delay;
    } else {
        if (_inst.forget_time > 0) {
            _inst.forget_time--;
            _inst.ai_state = ENEMY_ALERT;
        } else {
            _inst.ai_state = ENEMY_IDLE;
        }
    }

    // --------------------
    // DECISION LOGIC
    // --------------------
    if (!_inst.moving) {
        if (_inst.think_delay > 0) {
            _inst.think_delay--;
        } else {
            _inst.think_delay = _inst.think_rate;

            // IDLE (OPTIONAL WANDER)
            if (_inst.ai_state == ENEMY_IDLE && _inst.wander_chance > 0) {
                if (irandom(_inst.wander_chance - 1) == 0) {
                    _inst.move_dir = choose(UP, DOWN, LEFT, RIGHT);
                    var mxw = (_inst.move_dir == RIGHT) - (_inst.move_dir == LEFT);
                    var myw = (_inst.move_dir == DOWN) - (_inst.move_dir == UP);
                    if (EnemyAI_CanStep(_inst, mxw, myw)) {
                        _inst.move_timer = _inst.tile_size;
                        _inst.moving = true;
                    }
                }
            }

            // ALERT (CHASE)
            if (_inst.ai_state == ENEMY_ALERT) {
                EnemyAI_ApplyTraits(_inst, _cfg, ctx, "on_alert");

                if (abs(dx) > abs(dy)) {
                    if (dx > 0) _inst.move_dir = RIGHT;
                    else        _inst.move_dir = LEFT;
                } else {
                    if (dy > 0) _inst.move_dir = DOWN;
                    else        _inst.move_dir = UP;
                }

                var mxa = (_inst.move_dir == RIGHT) - (_inst.move_dir == LEFT);
                var mya = (_inst.move_dir == DOWN) - (_inst.move_dir == UP);
                if (EnemyAI_CanStep(_inst, mxa, mya)) {
                    _inst.move_timer = _inst.tile_size;
                    _inst.moving = true;
                }
            }
        }
    }

    // --------------------
    // MOVEMENT
    // --------------------
    if (_inst.moving) {
        var mx = 0;
        var my = 0;

        switch (_inst.move_dir) {
            case RIGHT: mx = 1; break;
            case LEFT:  mx = -1; break;
            case DOWN:  my = 1; break;
            case UP:    my = -1; break;
        }

        if (EnemyAI_CanStep(_inst, mx, my)) {
            var step = _inst.move_speed * ctx.move_speed_mult;
            if (step > _inst.move_timer) step = _inst.move_timer;

            _inst.x += mx * step;
            _inst.y += my * step;
            _inst.move_timer -= step;
        } else {
            _inst.moving = false;
            _inst.move_timer = 0;
        }

        if (_inst.move_timer <= 0) {
            _inst.moving = false;
        }
    }
}
