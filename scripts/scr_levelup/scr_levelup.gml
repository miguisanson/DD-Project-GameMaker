function Level_IsAtCap(_level) {
    return (round(_level) >= LEVEL_CAP_TECHNICAL);
}

function Player_NormalizeProgression(_ch, _recompute_resources = true, _clamp_exp_for_ui = true) {
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

    // Stat allocation was removed; stats now grow automatically by class table.
    _ch.stat_points = 0;

    if (!variable_struct_exists(_ch, "stun_immune_turns")) _ch.stun_immune_turns = 0;
    _ch.stun_immune_turns = max(0, round(_ch.stun_immune_turns));

    if (!variable_struct_exists(_ch, "exp")) _ch.exp = 0;
    _ch.exp = max(0, round(_ch.exp));

    if (Level_IsAtCap(_ch.level)) {
        _ch.level = LEVEL_CAP_TECHNICAL;
        _ch.exp = 0;
        _ch.exp_next = 0;
    } else {
        _ch.exp_next = Exp_NextLevel(_ch.level);
        if (_ch.exp_next <= 0) _ch.exp_next = 1;
        if (_clamp_exp_for_ui) {
            _ch.exp = min(_ch.exp, _ch.exp_next - 1);
        }
    }

    if (_recompute_resources) {
        if (!variable_struct_exists(_ch, "hp")) _ch.hp = 9999;
        if (!variable_struct_exists(_ch, "mp")) _ch.mp = 9999;
        _ch = RecomputeResources(_ch);
    }

    return _ch;
}

function LevelUp_ClassGrowthGain(_class_id, _new_level) {
    // Per-level stat growth table (replaces manual point allocation).
    // Specialists raise their primary stat every level plus a secondary on
    // even levels. Nobody is an even all-rounder with no specialization,
    // rotating two stats per level so everything climbs at the same pace.
    var lvl = max(2, round(_new_level));
    var even = ((lvl mod 2) == 0);
    switch (_class_id) {
        case CLASS_KNIGHT: return { str:1, agi:0, def:(even ? 1 : 0), intt:0, luck:0 };
        case CLASS_ARCHER: return { str:0, agi:1, def:0, intt:0, luck:(even ? 1 : 0) };
        case CLASS_MAGE:   return { str:0, agi:0, def:0, intt:1, luck:(even ? 1 : 0) };
        case CLASS_NOBODY:
            var rot = [
                { str:1, agi:1, def:0, intt:0, luck:0 },
                { str:0, agi:0, def:1, intt:1, luck:0 },
                { str:0, agi:0, def:0, intt:1, luck:1 },
                { str:1, agi:0, def:1, intt:0, luck:0 },
                { str:0, agi:1, def:0, intt:0, luck:1 }
            ];
            return rot[(lvl - 2) mod array_length(rot)];
    }
    return { str:0, agi:0, def:0, intt:0, luck:0 };
}

function LevelUp_ApplyLevel(_ch) {
    _ch = Player_NormalizeProgression(_ch, false, true);
    if (Level_IsAtCap(_ch.level)) return _ch;

    var hp_before = variable_struct_exists(_ch, "hp") ? _ch.hp : 0;
    var mp_before = variable_struct_exists(_ch, "mp") ? _ch.mp : 0;
    var max_hp_before = variable_struct_exists(_ch, "max_hp") ? _ch.max_hp : hp_before;
    var max_mp_before = variable_struct_exists(_ch, "max_mp") ? _ch.max_mp : mp_before;

    _ch.level += 1;
    if (!is_struct(_ch.stats)) _ch.stats = StatsCreateBase();

    var class_id = variable_struct_exists(_ch, "class_id") ? _ch.class_id : CLASS_NOBODY;
    var gain = LevelUp_ClassGrowthGain(class_id, _ch.level);
    _ch.stats.str  = StatClamp(_ch.stats.str  + gain.str);
    _ch.stats.agi  = StatClamp(_ch.stats.agi  + gain.agi);
    _ch.stats.def  = StatClamp(_ch.stats.def  + gain.def);
    _ch.stats.intt = StatClamp(_ch.stats.intt + gain.intt);
    _ch.stats.luck = StatClamp(_ch.stats.luck + gain.luck);

    if (!is_struct(_ch.last_growth)) _ch.last_growth = { str:0, agi:0, def:0, intt:0, luck:0 };
    _ch.last_growth.str  += gain.str;
    _ch.last_growth.agi  += gain.agi;
    _ch.last_growth.def  += gain.def;
    _ch.last_growth.intt += gain.intt;
    _ch.last_growth.luck += gain.luck;

    _ch.stat_points = 0;
    _ch = RecomputeResources(_ch);
    _ch.hp = clamp(hp_before + max(0, _ch.max_hp - max_hp_before), 0, _ch.max_hp);
    _ch.mp = clamp(mp_before + max(0, _ch.max_mp - max_mp_before), 0, _ch.max_mp);
    return _ch;
}

// Backwards-compatible shim: the stat id is ignored; growth follows the class table.
function LevelUp_AddStat(_ch, _stat_id) {
    return LevelUp_ApplyLevel(_ch);
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
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "last_growth") || !is_struct(_ch.last_growth)) return "";
    var g = _ch.last_growth;
    var parts = [];
    if (g.str  > 0) array_push(parts, "STR +"  + string(g.str));
    if (g.agi  > 0) array_push(parts, "AGI +"  + string(g.agi));
    if (g.def  > 0) array_push(parts, "DEF +"  + string(g.def));
    if (g.intt > 0) array_push(parts, "INT +"  + string(g.intt));
    if (g.luck > 0) array_push(parts, "LUCK +" + string(g.luck));
    var out = "";
    for (var i = 0; i < array_length(parts); i++) {
        if (i > 0) out += ", ";
        out += parts[i];
    }
    return out;
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
    return LevelUp_ApplyLevel(_ch);
}

function LevelUp_FromExp(_ch) {
    _ch = Player_NormalizeProgression(_ch, false, false);
    _ch.last_levels_gained = 0;
    _ch.last_stat_points_gained = 0;
    _ch.last_auto_stat_id = -1;
    _ch.last_auto_stat_gained = 0;
    _ch.last_growth = { str:0, agi:0, def:0, intt:0, luck:0 };

    if (Level_IsAtCap(_ch.level)) {
        _ch.exp = 0;
        _ch.exp_next = 0;
        return _ch;
    }
    if (_ch.exp_next <= 0) _ch.exp_next = Exp_NextLevel(_ch.level);

    var guard = 0;
    while (_ch.exp_next > 0 && _ch.exp >= _ch.exp_next && !Level_IsAtCap(_ch.level)) {
        _ch.exp -= _ch.exp_next;
        _ch = LevelUp_ApplyLevel(_ch);
        _ch.exp_next = Exp_NextLevel(_ch.level);
        _ch.last_levels_gained += 1;

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
    _ch = Player_NormalizeProgression(_ch, false, false);
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
