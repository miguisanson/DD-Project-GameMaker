function Level_IsAtCap(_level) {
    return (round(_level) >= LEVEL_CAP_TECHNICAL);
}

function Player_NormalizeProgression(_ch, _recompute_resources = true) {
    if (!is_struct(_ch)) return _ch;

    if (!variable_struct_exists(_ch, "class_id")) _ch.class_id = CLASS_NOBODY;
    _ch.class_cfg = DB_PlayerClass(_ch.class_id);

    if (!variable_struct_exists(_ch, "level")) _ch.level = 1;
    _ch.level = clamp(round(_ch.level), 1, LEVEL_CAP_TECHNICAL);

    if (!is_struct(_ch.stats)) _ch.stats = StatsCreateBase();
    if (!variable_struct_exists(_ch.stats, "str")) _ch.stats.str = 10;
    if (!variable_struct_exists(_ch.stats, "agi")) _ch.stats.agi = 10;
    if (!variable_struct_exists(_ch.stats, "def")) _ch.stats.def = 10;
    if (!variable_struct_exists(_ch.stats, "intt")) _ch.stats.intt = 10;
    if (!variable_struct_exists(_ch.stats, "luck")) _ch.stats.luck = 10;
    _ch.stats = StatsClampAll(_ch.stats);

    if (!variable_struct_exists(_ch, "stat_points")) _ch.stat_points = 0;
    _ch.stat_points = max(0, round(_ch.stat_points));

    if (!variable_struct_exists(_ch, "exp")) _ch.exp = 0;
    _ch.exp = max(0, round(_ch.exp));

    if (Level_IsAtCap(_ch.level)) {
        _ch.level = LEVEL_CAP_TECHNICAL;
        _ch.exp = 0;
        _ch.exp_next = 0;
    } else {
        _ch.exp_next = Exp_NextLevel(_ch.level);
        if (_ch.exp_next <= 0) _ch.exp_next = 1;
        _ch.exp = min(_ch.exp, _ch.exp_next - 1);
    }

    if (_recompute_resources) {
        if (!variable_struct_exists(_ch, "hp")) _ch.hp = 9999;
        if (!variable_struct_exists(_ch, "mp")) _ch.mp = 9999;
        _ch = RecomputeResources(_ch);
    }

    return _ch;
}

function LevelUp_AddStat(_ch, _stat_id) {
    _ch = Player_NormalizeProgression(_ch, false);
    if (Level_IsAtCap(_ch.level)) return _ch;

    _ch.level += 1;
    if (!is_struct(_ch.stats)) _ch.stats = StatsCreateBase();
    switch (_stat_id) {
        case STAT_STR:  _ch.stats.str = StatClamp(_ch.stats.str + 1); break;
        case STAT_AGI:  _ch.stats.agi = StatClamp(_ch.stats.agi + 1); break;
        case STAT_DEF:  _ch.stats.def = StatClamp(_ch.stats.def + 1); break;
        case STAT_INT:  _ch.stats.intt = StatClamp(_ch.stats.intt + 1); break;
        case STAT_LUCK: _ch.stats.luck = StatClamp(_ch.stats.luck + 1); break;
    }
    if (!variable_struct_exists(_ch, "stat_points")) _ch.stat_points = 0;
    _ch.stat_points += 1;
    _ch = RecomputeResources(_ch);
    return _ch;
}

function LevelUp_StatName(_stat_id) {
    switch (_stat_id) {
        case STAT_STR:  return "STR";
        case STAT_AGI:  return "AGI";
        case STAT_DEF:  return "DEF";
        case STAT_INT:  return "INT";
        case STAT_LUCK: return "LUCK";
    }
    return "";
}

function LevelUp_AutoStatForClass(_ch) {
    var cfg = undefined;
    if (is_struct(_ch) && variable_struct_exists(_ch, "class_cfg") && is_struct(_ch.class_cfg)) {
        cfg = _ch.class_cfg;
    }
    if ((!is_struct(cfg) || !variable_struct_exists(cfg, "auto_stat"))
    && is_struct(_ch) && variable_struct_exists(_ch, "class_id")) {
        cfg = DB_PlayerClass(_ch.class_id);
    }
    if (is_struct(cfg) && variable_struct_exists(cfg, "auto_stat")) {
        var stat_id = round(real(cfg.auto_stat));
        switch (stat_id) {
            case STAT_STR:
            case STAT_AGI:
            case STAT_DEF:
            case STAT_INT:
            case STAT_LUCK:
                return stat_id;
        }
    }
    return -1;
}

function LevelUp_AutoGainSummary(_ch) {
    if (!is_struct(_ch)) return "";
    var stat_id = -1;
    var gained = 0;
    if (variable_struct_exists(_ch, "last_auto_stat_id")) stat_id = round(real(_ch.last_auto_stat_id));
    if (variable_struct_exists(_ch, "last_auto_stat_gained")) gained = max(0, round(real(_ch.last_auto_stat_gained)));
    if (stat_id == -1 || gained <= 0) return "";
    var nm = LevelUp_StatName(stat_id);
    if (nm == "") return "";
    return nm + " +" + string(gained);
}

function Exp_NextLevel(_level) {
    var lvl = max(1, round(_level));
    if (lvl >= LEVEL_CAP_TECHNICAL) return 0;

    switch (lvl) {
        case 1: return 15;
        case 2: return 30;
        case 3: return 50;
        case 4: return 75;
        case 5: return 105;
        case 6: return 140;
        case 7: return 180;
        case 8: return 225;
        case 9: return 275;
    }

    return 0;
}

function LevelUp_Auto(_ch) {
    var pick = LevelUp_AutoStatForClass(_ch);
    return LevelUp_AddStat(_ch, pick);
}

function LevelUp_FromExp(_ch) {
    _ch = Player_NormalizeProgression(_ch, false);
    _ch.last_levels_gained = 0;
    _ch.last_stat_points_gained = 0;
    _ch.last_auto_stat_id = LevelUp_AutoStatForClass(_ch);
    _ch.last_auto_stat_gained = 0;

    if (Level_IsAtCap(_ch.level)) {
        _ch.exp = 0;
        _ch.exp_next = 0;
        return _ch;
    }
    if (_ch.exp_next <= 0) _ch.exp_next = Exp_NextLevel(_ch.level);

    var guard = 0;
    while (_ch.exp_next > 0 && _ch.exp >= _ch.exp_next && !Level_IsAtCap(_ch.level)) {
        _ch.exp -= _ch.exp_next;
        _ch = LevelUp_AddStat(_ch, _ch.last_auto_stat_id);
        _ch.exp_next = Exp_NextLevel(_ch.level);
        _ch.last_levels_gained += 1;
        _ch.last_stat_points_gained += 1;
        if (_ch.last_auto_stat_id != -1) _ch.last_auto_stat_gained += 1;

        guard += 1;
        if (guard > 200) break;
    }

    if (Level_IsAtCap(_ch.level)) {
        _ch.level = LEVEL_CAP_TECHNICAL;
        _ch.exp = 0;
        _ch.exp_next = 0;
    } else {
        _ch.exp = min(_ch.exp, max(0, _ch.exp_next - 1));
    }

    return _ch;
}

function Player_AddExp(_ch, _amount) {
    _ch = Player_NormalizeProgression(_ch, false);
    if (Level_IsAtCap(_ch.level)) {
        _ch.last_exp_gain = 0;
        _ch.last_levels_gained = 0;
        _ch.last_stat_points_gained = 0;
        _ch.last_auto_stat_gained = 0;
        _ch.exp = 0;
        _ch.exp_next = 0;
        return _ch;
    }

    var grant = max(0, round(_amount));
    _ch.last_exp_gain = grant;
    _ch.exp += grant;
    _ch = LevelUp_FromExp(_ch);
    return _ch;
}
