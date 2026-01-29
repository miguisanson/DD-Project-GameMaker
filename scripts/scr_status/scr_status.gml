function StatusDB_Init() {
    if (variable_global_exists("status_db") && ds_exists(global.status_db, ds_type_map)) return;
    global.status_db = ds_map_create();

    global.status_db[? STATUS_POISON] = {
        id: STATUS_POISON,
        name: "Poison",
        stat_mods: { str:0, agi:0, def:-1, intt:0, luck:0 },
        tick: { hp: -2, mp: 0 },
        stackable: false
    };

    global.status_db[? STATUS_REGEN] = {
        id: STATUS_REGEN,
        name: "Regen",
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp: 2, mp: 0 },
        stackable: false
    };

    global.status_db[? STATUS_STUN] = {
        id: STATUS_STUN,
        name: "Stun",
        stat_mods: { str:0, agi:-2, def:0, intt:0, luck:0 },
        tick: { hp: 0, mp: 0 },
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
    return { id: -1, name: "Unknown", stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 }, tick: { hp:0, mp:0 }, stackable: false };
}

function Status_Has(_ch, _status_id) {
    if (!is_array(_ch.status)) return false;
    for (var i = 0; i < array_length(_ch.status); i++) {
        if (_ch.status[i].id == _status_id) return true;
    }
    return false;
}

function Status_Add(_ch, _status_id, _turns, _power) {
    if (!is_array(_ch.status)) _ch.status = [];
    var cfg = StatusDB_Get(_status_id);
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

function Status_Tick(_ch) {
    if (!is_array(_ch.status)) return _ch;

    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var s = _ch.status[i];
        var cfg = StatusDB_Get(s.id);
        if (cfg.tick.hp != 0) {
            _ch.hp = clamp(_ch.hp + cfg.tick.hp, 0, _ch.max_hp);
        }
        if (cfg.tick.mp != 0) {
            _ch.mp = clamp(_ch.mp + cfg.tick.mp, 0, _ch.max_mp);
        }
        s.turns -= 1;
        if (s.turns <= 0) {
            array_delete(_ch.status, i, 1);
        }
    }

    return _ch;
}

function Status_CanAct(_ch) {
    if (Status_Has(_ch, STATUS_STUN)) return false;
    return true;
}
