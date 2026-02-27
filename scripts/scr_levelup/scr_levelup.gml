function LevelUp_AddStat(_ch, _stat_id) {
    if (_ch.level >= LEVEL_CAP_TECHNICAL) return _ch;

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

function Exp_NextLevel(_level) {
    var lvl = max(1, round(_level));
    if (lvl >= LEVEL_CAP_TECHNICAL) return 999999999;

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

    // Soft cap pacing for chapter-1 balance; expandable later if new content extends level range.
    return 10 + (lvl * lvl * 10);
}

function LevelUp_Auto(_ch) {
    var pick = -1;
    switch (_ch.class_id) {
        case CLASS_KNIGHT: pick = STAT_STR; break;
        case CLASS_ARCHER: pick = STAT_AGI; break;
        case CLASS_MAGE:   pick = STAT_INT; break;
        case CLASS_NOBODY: pick = -1; break;
    }

    return LevelUp_AddStat(_ch, pick);
}

function LevelUp_FromExp(_ch) {
    if (!variable_struct_exists(_ch, "exp")) _ch.exp = 0;
    if (!variable_struct_exists(_ch, "exp_next")) _ch.exp_next = Exp_NextLevel(_ch.level);
    _ch.last_levels_gained = 0;
    _ch.last_stat_points_gained = 0;

    var guard = 0;
    while (_ch.exp >= _ch.exp_next && _ch.level < LEVEL_CAP_TECHNICAL) {
        _ch.exp -= _ch.exp_next;
        _ch = LevelUp_Auto(_ch);
        _ch.exp_next = Exp_NextLevel(_ch.level);
        _ch.last_levels_gained += 1;
        _ch.last_stat_points_gained += 1;

        guard += 1;
        if (guard > 200) break;
    }

    if (_ch.level >= LEVEL_CAP_TECHNICAL) {
        _ch.exp = min(_ch.exp, _ch.exp_next - 1);
    }

    return _ch;
}

function Player_AddExp(_ch, _amount) {
    var grant = max(0, round(_amount));
    _ch.last_exp_gain = grant;
    _ch.exp += grant;
    _ch = LevelUp_FromExp(_ch);
    return _ch;
}
