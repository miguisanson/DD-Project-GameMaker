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
        array_push(parts, "(+" + string(_result.exp_gain) + " EXP)");
    }

    var levels = (variable_struct_exists(_result, "levels_gained")) ? max(0, round(real(_result.levels_gained))) : 0;
    var stat_points = (variable_struct_exists(_result, "stat_points_gained")) ? max(0, round(real(_result.stat_points_gained))) : 0;
    var auto_summary = (variable_struct_exists(_result, "auto_stat_summary")) ? string(_result.auto_stat_summary) : "";
    if (levels > 0) {
        var lvl_msg = "Level up x" + string(levels) + "!";
        if (stat_points > 0 || auto_summary != "") {
            lvl_msg += " (";
            var sub = [];
            if (stat_points > 0) array_push(sub, "+" + string(stat_points) + " stat point" + ((stat_points == 1) ? "" : "s"));
            if (auto_summary != "") array_push(sub, "auto " + auto_summary);
            for (var si = 0; si < array_length(sub); si++) {
                if (si > 0) lvl_msg += ", ";
                lvl_msg += sub[si];
            }
            lvl_msg += ")";
        }
        array_push(parts, lvl_msg);
    } else if (variable_struct_exists(_result, "at_level_cap") && _result.at_level_cap) {
        array_push(parts, "Max level reached.");
    }

    if (variable_struct_exists(_result, "loot_gained") && _result.loot_gained) {
        array_push(parts, "Loot gained.");
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
    var diff = Difficulty_Profile();
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
            if (random(1) <= loot_mult) array_push(kept, loot[i]);
        }
        loot = kept;
    }
    p.inventory = Loot_Grant(p.inventory, loot);
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
    // DEF adds a one-time flat bonus instead of compounding every level, so
    // high-DEF enemies stay meaty without ballooning into HP sponges.
    ch.max_hp = max(1, ch.base_hp + (ch.level - 1) * hp_gain + max(0, def_mod));

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

    if (variable_instance_exists(_inst, "ai_stationary") && _inst.ai_stationary) {
        _inst.moving = false;
        _inst.move_timer = 0;
        _inst.move_dir = -1;
        return;
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
