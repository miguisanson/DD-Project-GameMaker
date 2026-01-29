function StatsCreateBase() {
    return { str:10, agi:10, def:10, intt:10, luck:10 };
}

function StatsClampAll(_s) {
    _s.str  = StatClamp(_s.str);
    _s.agi  = StatClamp(_s.agi);
    _s.def  = StatClamp(_s.def);
    _s.intt = StatClamp(_s.intt);
    _s.luck = StatClamp(_s.luck);
    return _s;
}

function HPGainPerLevel(_hd) { return ceil(_hd / 2) + 1; }

function RecomputeResources(_ch) {
    var lvl = _ch.level;
    var cfg = _ch.class_cfg;
    var s = _ch.stats;

    var def_mod = StatMod(s.def);
    var int_mod = StatMod(s.intt);

    var hp_gain = HPGainPerLevel(cfg.hd);
    var mp_gain = cfg.mp_gain;

    _ch.max_hp = cfg.base_hp + (lvl - 1) * (hp_gain + def_mod);
    _ch.max_hp = max(1, _ch.max_hp);

    _ch.max_mp = cfg.base_mp + (lvl - 1) * (mp_gain + int_mod);
    _ch.max_mp = max(0, _ch.max_mp);

    _ch.hp = clamp(_ch.hp, 0, _ch.max_hp);
    _ch.mp = clamp(_ch.mp, 0, _ch.max_mp);

    return _ch;
}

function Stat_Get(_ch, _stat_id) {
    var base = 0;
    switch (_stat_id) {
        case STAT_STR:  base = _ch.stats.str; break;
        case STAT_AGI:  base = _ch.stats.agi; break;
        case STAT_DEF:  base = _ch.stats.def; break;
        case STAT_INT:  base = _ch.stats.intt; break;
        case STAT_LUCK: base = _ch.stats.luck; break;
    }

    var equip_bonus = Equip_GetStatBonus(_ch, _stat_id);
    var status_bonus = Status_ModStat(_ch, _stat_id);

    return base + equip_bonus + status_bonus;
}
