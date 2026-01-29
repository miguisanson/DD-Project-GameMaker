function EnemyCreate(_enemy_id) {
    var base = EnemyDB_Get(_enemy_id);

    // build battle character struct
    var ch = {};
    ch.id = base.id;
    ch.name = base.name;
    ch.level = base.level;

    // copy stats (keep same keys you use everywhere)
    ch.stats = {
        str:  base.stats.str,
        agi:  base.stats.agi,
        def:  base.stats.def,
        intt: base.stats.intt,
        luck: base.stats.luck
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

    // current resources start full
    ch.hp = ch.max_hp;
    ch.mp = ch.max_mp;

    // weapon & sprite (important!)
    ch.weapon_id = base.weapon_id;
    ch.sprite = base.sprite;
    ch.exp = base.exp;
    ch.skills = base.skills;
    ch.status = [];
    ch.is_boss = base.is_boss;

    return ch;
}

function Enemy_ApplyConfig(_inst) {
    if (_inst.enemy_id == -1) return;

    var cfg = EnemyDB_Get(_inst.enemy_id);
    _inst.enemy_cfg = cfg;

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
                    _inst.move_timer = _inst.tile_size;
                    _inst.moving = true;
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

                _inst.move_timer = _inst.tile_size;
                _inst.moving = true;
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

        if (!place_meeting(_inst.x + mx, _inst.y + my, obj_wall)) {
            var step = _inst.move_speed * ctx.move_speed_mult;
            if (step > _inst.move_timer) step = _inst.move_timer;

            _inst.x += mx * step;
            _inst.y += my * step;
            _inst.move_timer -= step;
        } else {
            _inst.moving = false;
        }

        if (_inst.move_timer <= 0) {
            _inst.moving = false;
        }
    }
}
