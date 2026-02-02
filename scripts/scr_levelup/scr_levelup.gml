function LevelUp_AddStat(_ch, _stat_id) {
    _ch.level += 1;
    if (!variable_struct_exists(_ch, "stat_points")) _ch.stat_points = 0;
    _ch.stat_points += 1;
    _ch = RecomputeResources(_ch);
    return _ch;
}

function Exp_NextLevel(_level) {
    return 10 + (_level * _level * 10);
}

function LevelUp_Auto(_ch) {
    var pick = STAT_STR;
    switch (_ch.class_id) {
        case CLASS_KNIGHT: pick = STAT_STR; break;
        case CLASS_ARCHER: pick = STAT_AGI; break;
        case CLASS_MAGE:   pick = STAT_INT; break;
    }

    return LevelUp_AddStat(_ch, pick);
}

function LevelUp_FromExp(_ch) {
    if (!variable_struct_exists(_ch, "exp")) _ch.exp = 0;
    if (!variable_struct_exists(_ch, "exp_next")) _ch.exp_next = Exp_NextLevel(_ch.level);

    while (_ch.exp >= _ch.exp_next) {
        _ch.exp -= _ch.exp_next;
        _ch = LevelUp_Auto(_ch);
        _ch.exp_next = Exp_NextLevel(_ch.level);
    }

    return _ch;
}

function Player_AddExp(_ch, _amount) {
    _ch.exp += _amount;
    _ch = LevelUp_FromExp(_ch);
    return _ch;
}
