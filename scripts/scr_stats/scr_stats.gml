// Stats (D22, D176): ATK DEF SPD MAG, plus VIG (Max HP) and MND (Max MP). Formulas: .planning/research/combat-spec.md sections 1-3; the VIG / MND curves: tools/balance/vig_mnd.py.
function StatsCreateBase() {
    return { atk:10, def:10, spd:10, mag:10, vig:VIG_START, mnd:MND_BASE };
}

// A stats struct whose vig / mnd are missing (a character made before D176) is left without them: Player_MigrateVigMnd gives them.
function StatsClampAll(_s) {
    _s.atk = StatClamp(_s.atk);
    _s.def = StatClamp(_s.def);
    _s.spd = StatClamp(_s.spd);
    _s.mag = StatClamp(_s.mag);
    if (variable_struct_exists(_s, "vig")) _s.vig = StatClamp(_s.vig);
    if (variable_struct_exists(_s, "mnd")) _s.mnd = StatClamp(_s.mnd);
    return _s;
}

// The four combat stats (what damage, equipment and statuses work on).
function Stat_IsValid(_stat_id) {
    return (_stat_id == STAT_ATK || _stat_id == STAT_DEF || _stat_id == STAT_SPD || _stat_id == STAT_MAG);
}

// The six stats a free point may go to (D176): the four above, VIG and MND.
function Stat_IsTrainable(_stat_id) {
    return (Stat_IsValid(_stat_id) || _stat_id == STAT_VIG || _stat_id == STAT_MND);
}

function Stat_Key(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return "atk";
        case STAT_DEF: return "def";
        case STAT_SPD: return "spd";
        case STAT_MAG: return "mag";
        case STAT_VIG: return "vig";
        case STAT_MND: return "mnd";
    }
    return "";
}

function Stat_ShortName(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return "ATK";
        case STAT_DEF: return "DEF";
        case STAT_SPD: return "SPD";
        case STAT_MAG: return "MAG";
        case STAT_VIG: return "VIG";
        case STAT_MND: return "MND";
    }
    return "";
}

function HPGainPerLevel(_hd) { return ceil(_hd / 2) + 2; }

// The pre-D176 curves: Max HP and Max MP grew silently with the level (and MAG added MP). The game no longer reads them: they stay as the reference the VIG / MND numbers are
// compared with (scr_test "vec" lines, tools/balance/check_combat_vectors.py, the old-vs-new table).
function Resource_MaxHp(_hd, _level) {
    return PLAYER_BASE_HP + (max(1, round(_level)) - 1) * HPGainPerLevel(_hd);
}

function Resource_MaxMp(_mp_gain, _level, _mag) {
    return PLAYER_BASE_MP + (max(1, round(_level)) - 1) * _mp_gain + floor(_mag / 2);
}

// D176: Max HP from VIG: 3 per point above VIG 10 up to VIG 28 (18 points), then 2 per point up to VIG 38 (10 points), then 1. Below 10 it is 10.
function Resource_MaxHpOfVig(_vig) {
    var d = max(0, round(_vig) - VIG_START);
    var b1 = min(d, 18);
    d -= b1;
    var b2 = min(d, 10);
    d -= b2;
    return PLAYER_BASE_HP + b1 * 3 + b2 * 2 + d;
}

// D176: Max MP from MND: 1 per point above MND 10 up to MND 44 (34 points), then 1/2 per point up to MND 56 (12 points), then 1/4, the whole sum rounded down.
function Resource_MaxMpOfMnd(_mnd) {
    var d = max(0, round(_mnd) - MND_BASE);
    var b1 = min(d, 34);
    d -= b1;
    var b2 = min(d, 12);
    d -= b2;
    return PLAYER_BASE_MP + b1 + ((b2 * 2 + d) div 4);
}

function RecomputeResources(_ch) {
    // D176: Max HP and Max MP are VIG and MND (a stats struct without them, made before, counts the class's starting values until Player_MigrateVigMnd has run)
    var vig = variable_struct_exists(_ch.stats, "vig") ? _ch.stats.vig : VIG_START;
    var mnd = variable_struct_exists(_ch.stats, "mnd") ? _ch.stats.mnd : (is_struct(_ch.class_cfg) ? _ch.class_cfg.stats.mnd : MND_BASE);
    _ch.max_hp = max(1, Resource_MaxHpOfVig(vig));
    _ch.max_mp = max(0, Resource_MaxMpOfMnd(mnd));

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
        case STAT_VIG: return variable_struct_exists(_ch.stats, "vig") ? _ch.stats.vig : VIG_START;   // D176: base only, no gear or status touches them
        case STAT_MND: return variable_struct_exists(_ch.stats, "mnd") ? _ch.stats.mnd : MND_BASE;
    }

    var equip_bonus = Equip_GetStatBonus(_ch, _stat_id);
    var status_bonus = Status_ModStat(_ch, _stat_id);

    return base + equip_bonus + status_bonus;
}
