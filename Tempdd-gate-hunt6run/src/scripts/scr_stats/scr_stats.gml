// Stats (D22): ATK DEF SPD MAG plus HP and MP. Formulas: .planning/research/combat-spec.md sections 1-3.
function StatsCreateBase() {
    return { atk:10, def:10, spd:10, mag:10 };
}

function StatsClampAll(_s) {
    _s.atk = StatClamp(_s.atk);
    _s.def = StatClamp(_s.def);
    _s.spd = StatClamp(_s.spd);
    _s.mag = StatClamp(_s.mag);
    return _s;
}

function Stat_IsValid(_stat_id) {
    return (_stat_id == STAT_ATK || _stat_id == STAT_DEF || _stat_id == STAT_SPD || _stat_id == STAT_MAG);
}

function Stat_Key(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return "atk";
        case STAT_DEF: return "def";
        case STAT_SPD: return "spd";
        case STAT_MAG: return "mag";
    }
    return "";
}

function Stat_ShortName(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return "ATK";
        case STAT_DEF: return "DEF";
        case STAT_SPD: return "SPD";
        case STAT_MAG: return "MAG";
    }
    return "";
}

function HPGainPerLevel(_hd) { return ceil(_hd / 2) + 2; }

// Spec section 3. No stat adds HP; MAG adds to MP (raw MAG, equipment not included).
function Resource_MaxHp(_hd, _level) {
    return PLAYER_BASE_HP + (max(1, round(_level)) - 1) * HPGainPerLevel(_hd);
}

function Resource_MaxMp(_mp_gain, _level, _mag) {
    return PLAYER_BASE_MP + (max(1, round(_level)) - 1) * _mp_gain + floor(_mag / 2);
}

function RecomputeResources(_ch) {
    var cfg = _ch.class_cfg;

    // D143: + the Max HP / Max MP bought with free points (absent on a character made before them)
    var hp_bonus = variable_struct_exists(_ch, "hp_bonus") ? _ch.hp_bonus : 0;
    var mp_bonus = variable_struct_exists(_ch, "mp_bonus") ? _ch.mp_bonus : 0;
    _ch.max_hp = max(1, Resource_MaxHp(cfg.hd, _ch.level) + hp_bonus);
    _ch.max_mp = max(0, Resource_MaxMp(cfg.mp_gain, _ch.level, _ch.stats.mag) + mp_bonus);

    _ch.hp = clamp(_ch.hp, 0, _ch.max_hp);
    _ch.mp = clamp(_ch.mp, 0, _ch.max_mp);

    return _ch;
}

function Stat_Get(_ch, _stat_id) {
    var base = 0;
    switch (_stat_id) {
        case STAT_ATK: base = _ch.stats.atk; break;
        case STAT_DEF: base = _ch.stats.def; break;
        case STAT_SPD: base = _ch.stats.spd; break;
        case STAT_MAG: base = _ch.stats.mag; break;
    }

    var equip_bonus = Equip_GetStatBonus(_ch, _stat_id);
    var status_bonus = Status_ModStat(_ch, _stat_id);

    return base + equip_bonus + status_bonus;
}
