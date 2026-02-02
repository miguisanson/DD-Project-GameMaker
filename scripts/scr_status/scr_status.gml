function StatusDB_Init() {
    if (variable_global_exists("status_db") && ds_exists(global.status_db, ds_type_map)) return;
    global.status_db = ds_map_create();

    global.status_db[? STATUS_POISON] = {
        id: STATUS_POISON,
        name: "Poison",
        icon_sprite: antidote,
        stat_mods: { str:0, agi:0, def:-1, intt:0, luck:0 },
        tick: { hp_min:-4, hp_max:-2, mp_min:0, mp_max:0 },
        stackable: false,
        excludes: [STATUS_BLEED]
    };

    global.status_db[? STATUS_BLEED] = {
        id: STATUS_BLEED,
        name: "Bleeding",
        icon_sprite: bandage,
        stat_mods: { str:0, agi:-1, def:0, intt:0, luck:0 },
        tick: { hp_min:-4, hp_max:-2, mp_min:0, mp_max:0 },
        stackable: false,
        excludes: [STATUS_POISON, STATUS_BURN]
    };

    global.status_db[? STATUS_BURN] = {
        id: STATUS_BURN,
        name: "Burning",
        icon_sprite: fire_stand_moving,
        stat_mods: { str:0, agi:0, def:-1, intt:0, luck:0 },
        tick: { hp_min:-5, hp_max:-3, mp_min:0, mp_max:0 },
        stackable: false,
        excludes: [STATUS_BLEED]
    };

    global.status_db[? STATUS_STUN] = {
        id: STATUS_STUN,
        name: "Stun",
        icon_sprite: skull_1_asset,
        stat_mods: { str:0, agi:-2, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        skip_turn: true
    };

    global.status_db[? STATUS_GUARD] = {
        id: STATUS_GUARD,
        name: "Guard",
        icon_sprite: rock1,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        guard_mult: 0,
        consume_on_hit: true
    };

    global.status_db[? STATUS_DMG_UP] = {
        id: STATUS_DMG_UP,
        name: "Rev Up",
        icon_sprite: torch_asset_moving,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        dmg_mult: 2,
        consume_on_attack: true
    };

    global.status_db[? STATUS_EVASION] = {
        id: STATUS_EVASION,
        name: "Evasion",
        icon_sprite: tall_grass_asset,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        force_dodge: true,
        consume_on_defend: true
    };

    global.status_db[? STATUS_CRIT_UP] = {
        id: STATUS_CRIT_UP,
        name: "Take Aim",
        icon_sprite: skull_2_asset,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        crit_bonus: 25
    };

    global.status_db[? STATUS_HIT_UP] = {
        id: STATUS_HIT_UP,
        name: "Foresight",
        icon_sprite: horned_skull_asset,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        always_hit: true,
        consume_on_attack: true
    };

    global.status_db[? STATUS_MEDITATION] = {
        id: STATUS_MEDITATION,
        name: "Meditation",
        icon_sprite: mp_potion,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:2, mp_max:4 },
        stackable: false
    };

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.status_db = global.status_db;
    }
}

function StatusDB_Get(_status_id) {
    if (!variable_global_exists("status_db") || !ds_exists(global.status_db, ds_type_map)) {
        StatusDB_Init();
    }
    if (ds_map_exists(global.status_db, _status_id)) {
        return global.status_db[? _status_id];
    }
    return { id: -1, name: "Unknown", icon_sprite: noone, stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 }, tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 }, stackable: false };
}

function Status_Has(_ch, _status_id) {
    if (!is_array(_ch.status)) return false;
    for (var i = 0; i < array_length(_ch.status); i++) {
        if (_ch.status[i].id == _status_id) return true;
    }
    return false;
}

function Status_Remove(_ch, _status_id) {
    if (!is_array(_ch.status)) return _ch;
    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        if (_ch.status[i].id == _status_id) array_delete(_ch.status, i, 1);
    }
    return _ch;
}

function Status_RemoveList(_ch, _list) {
    if (!is_array(_ch.status)) return _ch;
    if (!is_array(_list)) return _ch;
    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var sid = _ch.status[i].id;
        for (var j = 0; j < array_length(_list); j++) {
            if (sid == _list[j]) {
                array_delete(_ch.status, i, 1);
                break;
            }
        }
    }
    return _ch;
}

function Status_Add(_ch, _status_id, _turns, _power) {
    if (!is_array(_ch.status)) _ch.status = [];
    var cfg = StatusDB_Get(_status_id);

    if (variable_struct_exists(cfg, "excludes")) {
        _ch = Status_RemoveList(_ch, cfg.excludes);
    }

    if (!cfg.stackable && Status_Has(_ch, _status_id)) {
        for (var i = 0; i < array_length(_ch.status); i++) {
            if (_ch.status[i].id == _status_id) {
                _ch.status[i].turns = max(_ch.status[i].turns, _turns);
                _ch.status[i].power = max(_ch.status[i].power, _power);
                return _ch;
            }
        }
    }

    array_push(_ch.status, { id: _status_id, turns: _turns, power: _power });
    return _ch;
}

function Status_ModStat(_ch, _stat_id) {
    var total = 0;
    if (!is_array(_ch.status)) return 0;

    for (var i = 0; i < array_length(_ch.status); i++) {
        var s = _ch.status[i];
        var cfg = StatusDB_Get(s.id);
        var mods = cfg.stat_mods;
        switch (_stat_id) {
            case STAT_STR:  total += mods.str; break;
            case STAT_AGI:  total += mods.agi; break;
            case STAT_DEF:  total += mods.def; break;
            case STAT_INT:  total += mods.intt; break;
            case STAT_LUCK: total += mods.luck; break;
        }
    }

    return total;
}

function Status_GetSum(_ch, _field) {
    var total = 0;
    if (!is_array(_ch.status)) return 0;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field)) {
            total += variable_struct_get(cfg, _field);
        }
    }
    return total;
}

function Status_GetMul(_ch, _field) {
    var mult = 1;
    if (!is_array(_ch.status)) return 1;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field)) {
            mult *= variable_struct_get(cfg, _field);
        }
    }
    return mult;
}

function Status_HasFlag(_ch, _field) {
    if (!is_array(_ch.status)) return false;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field) && variable_struct_get(cfg, _field)) return true;
    }
    return false;
}

function Status_ConsumeByField(_ch, _field) {
    if (!is_array(_ch.status)) return _ch;
    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field) && variable_struct_get(cfg, _field)) {
            array_delete(_ch.status, i, 1);
        }
    }
    return _ch;
}

function Status_Tick(_ch) {
    if (!is_array(_ch.status)) return _ch;

    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var s = _ch.status[i];
        var cfg = StatusDB_Get(s.id);
        var t = cfg.tick;

        var hp_min = 0;
        var hp_max = 0;
        var mp_min = 0;
        var mp_max = 0;
        if (is_struct(t)) {
            if (variable_struct_exists(t, "hp_min")) hp_min = t.hp_min;
            if (variable_struct_exists(t, "hp_max")) hp_max = t.hp_max;
            if (variable_struct_exists(t, "mp_min")) mp_min = t.mp_min;
            if (variable_struct_exists(t, "mp_max")) mp_max = t.mp_max;
        }

        if (hp_min != 0 || hp_max != 0) {
            var delta_hp = (hp_min == hp_max) ? hp_min : irandom_range(hp_min, hp_max);
            _ch.hp = clamp(_ch.hp + delta_hp, 0, _ch.max_hp);
        }

        if (mp_min != 0 || mp_max != 0) {
            var delta_mp = (mp_min == mp_max) ? mp_min : irandom_range(mp_min, mp_max);
            _ch.mp = clamp(_ch.mp + delta_mp, 0, _ch.max_mp);
        }

        s.turns -= 1;
        if (s.turns <= 0) {
            array_delete(_ch.status, i, 1);
        }
    }

    return _ch;
}

function Status_CanAct(_ch) {
    if (Status_HasFlag(_ch, "skip_turn")) return false;
    return true;
}

function Status_DrawIcons(_ch, _x, _y, _spacing, _rtl) {
    if (!is_array(_ch.status)) return;

    var spacing = 10;
    if (argument_count >= 4) spacing = _spacing;
    var rtl = false;
    if (argument_count >= 5) rtl = _rtl;

    var off = 0;
    if (rtl) {
        for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
            var cfg = StatusDB_Get(_ch.status[i].id);
            if (variable_struct_exists(cfg, "icon_sprite") && cfg.icon_sprite != noone) {
                draw_sprite(cfg.icon_sprite, 0, _x + off, _y);
                off += spacing;
            }
        }
    } else {
        for (var i = 0; i < array_length(_ch.status); i++) {
            var cfg2 = StatusDB_Get(_ch.status[i].id);
            if (variable_struct_exists(cfg2, "icon_sprite") && cfg2.icon_sprite != noone) {
                draw_sprite(cfg2.icon_sprite, 0, _x + off, _y);
                off += spacing;
            }
        }
    }
}
