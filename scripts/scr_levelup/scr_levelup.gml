function Level_IsAtCap(_level) {
    return (round(_level) >= LEVEL_CAP_TECHNICAL);
}

// D177: the levels won in a fight that wait for the player to confirm the level-up screen (ch.levels_owed). The character's level, stats, Max HP / Max MP and bank of points
// stay as they were until then; the EXP bar counts from level + levels_owed.
function LevelUp_Owed(_ch) {
    return (is_struct(_ch) && variable_struct_exists(_ch, "levels_owed")) ? max(0, round(real(_ch.levels_owed))) : 0;
}

// The level the character counts as everywhere a number about the run is told (the run summary, the history, the save list): the level plus the owed levels, so a death
// before the screen keeps the levels he had won.
function Player_EffLevel(_ch) {
    if (!is_struct(_ch)) return 1;
    return clamp((variable_struct_exists(_ch, "level") ? round(real(_ch.level)) : 1) + LevelUp_Owed(_ch), 1, LEVEL_CAP_TECHNICAL);
}

// In a run the level-ups wait for the screen (D177); outside one (tests, tools) EXP levels the character at once, the points auto-placed, as before.
function LevelUp_Deferred() {
    return Run_IsActive();
}

function Player_NormalizeProgression(_ch, _recompute_resources = true, _clamp_exp_for_ui = true) {
    if (!is_struct(_ch)) return _ch;

    if (!variable_struct_exists(_ch, "class_id")) _ch.class_id = CLASS_NOBODY;
    _ch.class_cfg = DB_PlayerClass(_ch.class_id);

    if (!variable_struct_exists(_ch, "level")) _ch.level = 1;
    _ch.level = clamp(round(_ch.level), 1, LEVEL_CAP_TECHNICAL);

    if (!is_struct(_ch.stats)) _ch.stats = StatsCreateBase();
    // Old STR/AGI/INT keys (pre-B1 characters) map to ATK/SPD/MAG; LUCK is dropped.
    if (!variable_struct_exists(_ch.stats, "atk")) _ch.stats.atk = variable_struct_exists(_ch.stats, "str") ? _ch.stats.str : 10;
    if (!variable_struct_exists(_ch.stats, "def")) _ch.stats.def = 10;
    if (!variable_struct_exists(_ch.stats, "spd")) _ch.stats.spd = variable_struct_exists(_ch.stats, "agi") ? _ch.stats.agi : 10;
    if (!variable_struct_exists(_ch.stats, "mag")) _ch.stats.mag = variable_struct_exists(_ch.stats, "intt") ? _ch.stats.intt : 10;
    var st = { atk: _ch.stats.atk, def: _ch.stats.def, spd: _ch.stats.spd, mag: _ch.stats.mag };
    if (variable_struct_exists(_ch.stats, "vig")) st.vig = _ch.stats.vig;
    if (variable_struct_exists(_ch.stats, "mnd")) st.mnd = _ch.stats.mnd;
    _ch.stats = StatsClampAll(st);
    // D176: a character made before VIG and MND (its Max HP / Max MP bought with free points as hp_bonus / mp_bonus) gets them, once.
    _ch = Player_MigrateVigMnd(_ch);

    // Banked free points (D76) survive; a character without the field has none.
    if (!variable_struct_exists(_ch, "stat_points")) _ch.stat_points = 0;
    _ch.stat_points = max(0, round(_ch.stat_points));

    Card_EnsureFields(_ch);

    if (!variable_struct_exists(_ch, "exp")) _ch.exp = 0;
    _ch.exp = max(0, round(_ch.exp));

    // D177: owed levels (won, not yet confirmed) never take the character past the cap; the EXP bar is the one of the level he will be
    _ch.levels_owed = clamp(LevelUp_Owed(_ch), 0, LEVEL_CAP_TECHNICAL - _ch.level);
    var eff_level = _ch.level + _ch.levels_owed;
    if (Level_IsAtCap(eff_level)) {
        if (Level_IsAtCap(_ch.level)) _ch.level = LEVEL_CAP_TECHNICAL;
        _ch.exp = 0;
        _ch.exp_next = 0;
    } else {
        _ch.exp_next = Exp_NextLevel(eff_level);
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

// D176: a character made before VIG and MND has no vig / mnd. They become what the class growth gave up to its level, plus a point for every LEGACY_HP_PER_POINT (3) of
// hp_bonus and LEGACY_MP_PER_POINT (2) of mp_bonus (the Max HP / Max MP it bought with free points; a bonus that is not a whole number of points rounds down). hp_bonus and
// mp_bonus are dropped. A struct with no stats is left alone; one that already has vig and mnd only loses the old fields. Safe on a character loaded as plain data
// (no class_cfg needed), so RunSave_Migrate can use it on a save file.
function Player_MigrateVigMnd(_ch) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "stats") || !is_struct(_ch.stats)) return _ch;
    if (!variable_struct_exists(_ch.stats, "vig") || !variable_struct_exists(_ch.stats, "mnd")) {
        var cid = variable_struct_exists(_ch, "class_id") ? round(real(_ch.class_id)) : CLASS_NOBODY;
        var lvl = variable_struct_exists(_ch, "level") ? clamp(round(real(_ch.level)), 1, LEVEL_CAP_TECHNICAL) : 1;
        var vig = VIG_START;
        var mnd = DB_PlayerClass(cid).stats.mnd;
        for (var l = 2; l <= lvl; l++) {
            var g = LevelUp_ClassGrowthGain(cid, l);
            vig += g.vig;
            mnd += g.mnd;
        }
        var hb = variable_struct_exists(_ch, "hp_bonus") ? max(0, round(real(_ch.hp_bonus))) : 0;
        var mb = variable_struct_exists(_ch, "mp_bonus") ? max(0, round(real(_ch.mp_bonus))) : 0;
        _ch.stats.vig = StatClamp(vig + hb div LEGACY_HP_PER_POINT);
        _ch.stats.mnd = StatClamp(mnd + mb div LEGACY_MP_PER_POINT);
    }
    if (variable_struct_exists(_ch, "hp_bonus")) variable_struct_remove(_ch, "hp_bonus");
    if (variable_struct_exists(_ch, "mp_bonus")) variable_struct_remove(_ch, "mp_bonus");
    return _ch;
}

// Fixed growth per class for reaching _new_level (>= 2); combat-spec.md section 2. The level's ONE free point is separate (D76).
// D176: VIG and MND are listed with the other stats (they make Max HP and Max MP): Knight ATK+1 DEF+1 VIG+2 (3 on levels 4, 7, 10) MND+1; Archer ATK+1 SPD+1 VIG+2 MND+2;
// Mage MAG+2 VIG+2 on even levels and +1 on odd MND+3 (the glass cannon: the least Max HP, the most Max MP); Nobody the rotation below, VIG+2, MND+1 (+2 on levels 5 and 9).
function LevelUp_ClassGrowthGain(_class_id, _new_level) {
    var lvl = max(2, round(_new_level));
    switch (_class_id) {
        case CLASS_KNIGHT: return { atk:1, def:1, spd:0, mag:0, vig:(((lvl - 2) mod 3 == 2) ? 3 : 2), mnd:1 };
        case CLASS_ARCHER: return { atk:1, def:0, spd:1, mag:0, vig:2, mnd:2 };
        case CLASS_MAGE:   return { atk:0, def:0, spd:0, mag:2, vig:((lvl mod 2 == 0) ? 2 : 1), mnd:3 };
        case CLASS_NOBODY:
            // Balanced-low (D83), two points a level since D111 (E1-6): the point that cycles ATK, DEF, SPD, MAG, plus the one two steps further on the cycle.
            var rot = [
                { atk:1, def:0, spd:0, mag:0 },
                { atk:0, def:1, spd:0, mag:0 },
                { atk:0, def:0, spd:1, mag:0 },
                { atk:0, def:0, spd:0, mag:1 }
            ];
            var ri = (lvl - 2) mod array_length(rot);
            var r1 = rot[ri];
            var r2 = rot[(ri + 2) mod array_length(rot)];
            return { atk:r1.atk + r2.atk, def:r1.def + r2.def, spd:r1.spd + r2.spd, mag:r1.mag + r2.mag, vig:2, mnd:(((lvl - 2) mod 4 == 3) ? 2 : 1) };
    }
    return { atk:0, def:0, spd:0, mag:0, vig:0, mnd:0 };
}

// Free points are placed by the player in a run (the stat prompt, CardsUi); outside a run (tests, tools) they go to the class default at once.
function Level_AutoPlaceEnabled() {
    if (!variable_global_exists("levelup_auto_place")) global.levelup_auto_place = true;
    return global.levelup_auto_place && !Run_IsActive();   // C2: during a run the player places the point (the stat prompt); tests and tools still auto-place
}

// D76: spends one banked free point on _stat_id (STAT_ATK/DEF/SPD/MAG, D176: also STAT_VIG / STAT_MND). Does nothing without a point or with an unknown stat.
// The stat only moves: Max HP / Max MP follow in RecomputeResources (Cards_PlaceStat also raises the current HP / MP by what the point added).
function Level_ApplyFreePoint(_ch, _stat_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "stat_points") || _ch.stat_points <= 0) return _ch;
    if (!Stat_IsTrainable(_stat_id)) return _ch;
    var key = Stat_Key(_stat_id);
    variable_struct_set(_ch.stats, key, StatClamp(variable_struct_get(_ch.stats, key) + 1));
    _ch.stat_points -= 1;
    if (variable_struct_exists(_ch, "last_growth") && is_struct(_ch.last_growth)) variable_struct_set(_ch.last_growth, key, variable_struct_get(_ch.last_growth, key) + 1);
    return _ch;
}

function LevelUp_ApplyLevel(_ch) {
    // Do not clamp the EXP to the old level's bar here: LevelUp_FromExp carries the rest over when one grant crosses several levels.
    _ch = Player_NormalizeProgression(_ch, false, false);
    if (Level_IsAtCap(_ch.level)) return _ch;

    var hp_before = variable_struct_exists(_ch, "hp") ? _ch.hp : 0;
    var mp_before = variable_struct_exists(_ch, "mp") ? _ch.mp : 0;
    var max_hp_before = variable_struct_exists(_ch, "max_hp") ? _ch.max_hp : hp_before;
    var max_mp_before = variable_struct_exists(_ch, "max_mp") ? _ch.max_mp : mp_before;

    _ch.level += 1;
    _ch.levels_owed = max(0, LevelUp_Owed(_ch) - 1);   // D177: an owed level, now given (the EXP bar is already the one of level + owed: it does not move)
    if (!is_struct(_ch.stats)) _ch.stats = StatsCreateBase();

    var class_id = variable_struct_exists(_ch, "class_id") ? _ch.class_id : CLASS_NOBODY;
    var gain = LevelUp_ClassGrowthGain(class_id, _ch.level);
    _ch.stats.atk = StatClamp(_ch.stats.atk + gain.atk);
    _ch.stats.def = StatClamp(_ch.stats.def + gain.def);
    _ch.stats.spd = StatClamp(_ch.stats.spd + gain.spd);
    _ch.stats.mag = StatClamp(_ch.stats.mag + gain.mag);
    _ch.stats.vig = StatClamp(_ch.stats.vig + gain.vig);   // D176: Max HP and Max MP follow from these two (RecomputeResources below)
    _ch.stats.mnd = StatClamp(_ch.stats.mnd + gain.mnd);

    if (!variable_struct_exists(_ch, "last_growth") || !is_struct(_ch.last_growth)) _ch.last_growth = { atk:0, def:0, spd:0, mag:0, vig:0, mnd:0 };
    _ch.last_growth.atk += gain.atk;
    _ch.last_growth.def += gain.def;
    _ch.last_growth.spd += gain.spd;
    _ch.last_growth.mag += gain.mag;
    _ch.last_growth.vig = (variable_struct_exists(_ch.last_growth, "vig") ? _ch.last_growth.vig : 0) + gain.vig;
    _ch.last_growth.mnd = (variable_struct_exists(_ch.last_growth, "mnd") ? _ch.last_growth.mnd : 0) + gain.mnd;

    // D81: a 1-of-3 card pick at every level-up.
    _ch.card_picks = max(0, _ch.card_picks) + 1;

    // D76: one free point per level.
    _ch.stat_points = max(0, _ch.stat_points) + LEVEL_FREE_POINTS_PER_LEVEL;
    if (Level_AutoPlaceEnabled()) {
        var def_stat = LevelUp_AutoStatForClass(_ch);
        while (_ch.stat_points > 0 && Stat_IsValid(def_stat)) _ch = Level_ApplyFreePoint(_ch, def_stat);
    }

    _ch = RecomputeResources(_ch);
    _ch.hp = clamp(hp_before + max(0, _ch.max_hp - max_hp_before), 0, _ch.max_hp);
    _ch.mp = clamp(mp_before + max(0, _ch.max_mp - max_mp_before), 0, _ch.max_mp);
    return _ch;
}

// D177: every owed level given at once (the free points banked, or placed when auto-place is on). The screen gives them one at a time (Cards_PlaceStat); this is for
// callers that want the level now (a class change, scenarios, tools).
function LevelUp_ApplyOwed(_ch) {
    var guard = 0;
    while (LevelUp_Owed(_ch) > 0 && guard < LEVEL_CAP_TECHNICAL) {
        _ch = LevelUp_ApplyLevel(_ch);
        guard++;
    }
    return _ch;
}

// D177: the character as he will be once the level the screen is for is confirmed (class growth in; the point not yet placed): what the screen shows as "now > after".
// A copy: the character is not touched. With nothing owed (a point banked by an older save) it is just a copy.
function LevelUp_PreviewCharacter(_ch) {
    var pv = variable_clone(_ch);
    if (LevelUp_Owed(pv) > 0 && pv.stat_points <= 0) pv = LevelUp_ApplyLevel(pv);
    return pv;
}

// The class's default free-point stat (-1 when it has none).
function LevelUp_AutoStatForClass(_ch) {
    var cfg = undefined;
    if (is_struct(_ch) && variable_struct_exists(_ch, "class_cfg") && is_struct(_ch.class_cfg)) {
        cfg = _ch.class_cfg;
    }
    if ((!is_struct(cfg) || !variable_struct_exists(cfg, "free_default"))
    && is_struct(_ch) && variable_struct_exists(_ch, "class_id")) {
        cfg = DB_PlayerClass(_ch.class_id);
    }
    if (is_struct(cfg) && variable_struct_exists(cfg, "free_default")) {
        var stat_id = round(real(cfg.free_default));
        if (Stat_IsValid(stat_id)) return stat_id;
    }
    return -1;
}

function LevelUp_AutoGainSummary(_ch) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "last_growth") || !is_struct(_ch.last_growth)) return "";
    var g = _ch.last_growth;
    var parts = [];
    if (g.atk > 0) array_push(parts, "ATK +" + string(g.atk));
    if (g.def > 0) array_push(parts, "DEF +" + string(g.def));
    if (g.spd > 0) array_push(parts, "SPD +" + string(g.spd));
    if (g.mag > 0) array_push(parts, "MAG +" + string(g.mag));
    if (variable_struct_exists(g, "vig") && g.vig > 0) array_push(parts, "VIG +" + string(g.vig));
    if (variable_struct_exists(g, "mnd") && g.mnd > 0) array_push(parts, "MND +" + string(g.mnd));
    var out = "";
    for (var i = 0; i < array_length(parts); i++) {
        if (i > 0) out += ", ";
        out += parts[i];
    }
    return out;
}

// EXP needed to leave level _level (spec section 7; D30: ~level 9 at the final boss after a clean pass). 0 at the cap.
function Exp_NextLevel(_level) {
    var lvl = max(1, round(_level));
    if (lvl >= LEVEL_CAP_TECHNICAL) return 0;

    switch (lvl) {
        case 1: return 12;
        case 2: return 24;
        case 3: return 40;
        case 4: return 58;
        case 5: return 80;
        case 6: return 105;
        case 7: return 135;
        case 8: return 170;
        case 9: return 210;
    }

    return 0;
}

function LevelUp_FromExp(_ch) {
    _ch = Player_NormalizeProgression(_ch, false, false);
    _ch.last_levels_gained = 0;
    _ch.last_stat_points_gained = 0;
    _ch.last_auto_stat_id = -1;
    _ch.last_auto_stat_gained = 0;
    _ch.last_growth = { atk:0, def:0, spd:0, mag:0, vig:0, mnd:0 };

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
    _ch.last_stat_points_gained = _ch.last_levels_gained * LEVEL_FREE_POINTS_PER_LEVEL;   // R-113: it was reset to 0 above and never set

    return _ch;
}

// D177: the same bookkeeping as LevelUp_FromExp, but the levels are only OWED: the level, the stats, Max HP / Max MP, the points and the card picks stay as they were until
// the player confirms the level-up screen (Cards_PlaceStat gives one owed level per confirm). The EXP bar is the one of the level he will be (level + owed).
function LevelUp_OweFromExp(_ch) {
    _ch = Player_NormalizeProgression(_ch, false, false);
    _ch.last_levels_gained = 0;
    _ch.last_stat_points_gained = 0;
    _ch.last_auto_stat_id = -1;
    _ch.last_auto_stat_gained = 0;
    _ch.last_growth = { atk:0, def:0, spd:0, mag:0, vig:0, mnd:0 };

    var owed0 = LevelUp_Owed(_ch);
    var owed = owed0;
    var eff = _ch.level + owed;
    if (Level_IsAtCap(eff)) {
        _ch.exp = 0;
        _ch.exp_next = 0;
        return _ch;
    }
    var need = Exp_NextLevel(eff);
    var guard = 0;
    while (need > 0 && _ch.exp >= need && !Level_IsAtCap(eff)) {
        _ch.exp -= need;
        owed += 1;
        eff += 1;
        need = Exp_NextLevel(eff);
        guard += 1;
        if (guard > 200) break;
    }
    _ch.levels_owed = owed;
    if (Level_IsAtCap(eff)) {
        _ch.exp = 0;
        _ch.exp_next = 0;
    } else {
        _ch.exp_next = need;
        _ch.exp = min(_ch.exp, max(0, need - 1));
    }
    _ch.last_levels_gained = owed - owed0;
    _ch.last_stat_points_gained = _ch.last_levels_gained * LEVEL_FREE_POINTS_PER_LEVEL;
    return _ch;
}

function Player_AddExp(_ch, _amount) {
    _ch = Player_NormalizeProgression(_ch, false, false);
    if (Level_IsAtCap(_ch.level + LevelUp_Owed(_ch))) {
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
    _ch = LevelUp_Deferred() ? LevelUp_OweFromExp(_ch) : LevelUp_FromExp(_ch);   // D177: in a run the levels wait for the screen
    return _ch;
}

// ==========================================================================================================================
// C2: what a character owes the player (D73, D76, D81, D82, D130): a class choice, the echo of the last fall, a place for a taken skill, a free stat point,
// a 1-of-3 card pick. The debts live on the character (class_pick, echo_offer, skill_pending, stat_points, card_picks), so a save or a reload cannot lose them;
// the screens (scr_menu: CardsUi_*) open them one by one, in the order below.
// ==========================================================================================================================
function Cards_NextOwed(_ch) {
    if (!is_struct(_ch)) return "";
    Card_EnsureFields(_ch);
    if (_ch.class_pick) return "class";
    if (array_length(_ch.echo_offer) > 0) return "echo";   // D130: the lost run's gift, right after the class pick
    if (_ch.skill_pending >= 0) return "replace";
    if (!Level_AutoPlaceEnabled() && (_ch.stat_points > 0 || LevelUp_Owed(_ch) > 0)) return "stat";   // D177: a banked point, or a level won and not yet confirmed
    if (_ch.card_picks > 0 && _ch.class_chosen) return "cards";   // picks wait for the class (so they come from its pool)
    return "";
}

// A pick was answered (a card taken or skipped): one less owed, the shown offer forgotten.
function Cards_ConsumePick(_ch) {
    Card_EnsureFields(_ch);
    _ch.card_picks = max(0, _ch.card_picks - 1);
    _ch.offer = [];
    _ch.skill_pending = -1;
    return _ch;
}

// A class or skill chest was opened (D73): the first one owes the class choice, every later one a 1-of-3 pick. Returns a changed copy.
function Cards_ChestOpened(_ch) {
    var ch = Card_EnsureFields(variable_clone(_ch));
    if (!ch.class_chosen) ch.class_pick = true;
    else ch.card_picks += 1;
    return ch;
}

// D177: what a row of the level-up screen reads. A row the class grows shows "now > now + growth" (gold); a row it does not grow shows only the number; the row under the
// cursor (keyboard or mouse) shows its "> +1" on top: a growth row "now > now + growth + 1", another "now > now + 1". Never past the stat maximum.
function Cards_StatRowValue(_now, _grow, _hover) {
    var g = max(0, _grow);
    if (g <= 0 && !_hover) return string(_now);
    return string(_now) + " > " + string(StatClamp(_now + g + (_hover ? 1 : 0)));
}

// Hunt 7 (D143): the level a free-point prompt is for. A fight that gives several levels owes one point per level and the prompts open one by one, so the
// prompt for the oldest point still owed is the character's level minus the points still owed, plus one (never below 2 or above the level).
function LevelUp_PromptLevel(_ch) {
    if (LevelUp_Owed(_ch) > 0 && _ch.stat_points <= 0) return _ch.level + 1;   // D177: the screen is for the next owed level
    var owed = (variable_struct_exists(_ch, "stat_points") ? max(0, _ch.stat_points) : 0) / LEVEL_FREE_POINTS_PER_LEVEL;
    return clamp(_ch.level - ceil(owed) + 1, min(2, _ch.level), _ch.level);
}

// D143, D176: the free-point prompt's rows: the six stats ATK DEF SPD MAG VIG MND (value now > after the point).
function Cards_FreePointOptions(_ch) {
    return Cards_StatOptions(_ch);
}

// The rows of the free-point prompt: the stat, its value now and after the point.
function Cards_StatOptions(_ch) {
    var ids = [STAT_ATK, STAT_DEF, STAT_SPD, STAT_MAG, STAT_VIG, STAT_MND];
    var out = [];
    for (var i = 0; i < array_length(ids); i++) {
        var from = Stat_Get(_ch, ids[i]);
        array_push(out, { stat: ids[i], label: Stat_ShortName(ids[i]), from: from, to: StatClamp(from + 1) });
    }
    return out;
}

// The level-up screen's confirm (D177): with a level owed and no point banked, the level comes first (class growth, one free point, one card pick), then the point goes on
// _stat_id (Level_ApplyFreePoint); the current HP / MP rise by the Max HP / Max MP the level and the point added (VIG, MND). A banked point of an older save is just spent.
function Cards_PlaceStat(_ch, _stat_id) {
    if (!is_struct(_ch)) return _ch;
    if (LevelUp_Owed(_ch) > 0 && _ch.stat_points <= 0) _ch = LevelUp_ApplyLevel(_ch);   // the level raises Max HP / MP, and the current HP / MP with them
    var max_hp0 = _ch.max_hp;
    var max_mp0 = _ch.max_mp;
    _ch = Level_ApplyFreePoint(_ch, _stat_id);
    _ch = RecomputeResources(_ch);
    _ch.hp = clamp(_ch.hp + max(0, _ch.max_hp - max_hp0), 0, _ch.max_hp);
    _ch.mp = clamp(_ch.mp + max(0, _ch.max_mp - max_mp0), 0, _ch.max_mp);
    return _ch;
}

// The pick screen's cursor: positions 0.._n-1 are the cards, nothing else (R3: the Skip row is gone). Left / right walk the cards (wrapping, D95); up and
// down stay where they are. _last is kept for the callers' signature.
function Cards_PickMove(_cur, _n, _dx, _dy, _last) {
    if (_n <= 0) return 0;
    _cur = clamp(_cur, 0, _n - 1);
    if (_dx != 0) return (_cur + ((_dx < 0) ? -1 : 1) + _n) mod _n;
    return _cur;
}

// ==========================================================================================================================
// C4 (D47): beds are rest sites. Once per run per bed the player chooses: heal (full HP and MP) OR upgrade one owned skill (its upgrade
// card, scr_db_skill). A used bed is remembered in the run's flags (gs.flags, saved with the run, wiped by a new run) under
// Bed_Key = "bed:<room>:<x>,<y>". Everything here is pure; the menu is BedUi_* (scr_menu).
// ==========================================================================================================================
function Bed_Key(_room_name, _x, _y) {
    return "bed:" + string(_room_name) + ":" + string(round(_x)) + "," + string(round(_y));
}

function Bed_Used(_flags, _key) {
    return is_struct(_flags) && variable_struct_exists(_flags, _key) && (variable_struct_get(_flags, _key) == true);
}

function Bed_CanUse(_flags, _key) {
    return !Bed_Used(_flags, _key);
}

function Bed_MarkUsed(_flags, _key) {
    variable_struct_set(_flags, _key, true);
}

// The skills the character owns whose upgrade he does not have yet, in slot order.
function Bed_UpgradableSkills(_ch) {
    var out = [];
    if (!is_struct(_ch)) return out;
    var skills = (variable_struct_exists(_ch, "skills") && is_array(_ch.skills)) ? _ch.skills : [];
    var ups = (variable_struct_exists(_ch, "upgrades") && is_array(_ch.upgrades)) ? _ch.upgrades : [];
    for (var i = 0; i < array_length(skills); i++) {
        if (array_contains(ups, skills[i])) continue;
        if (!is_struct(CardDB_Get(Card_UpgradeId(skills[i])))) continue;
        array_push(out, skills[i]);
    }
    return out;
}

// D156: resting only helps while HP or MP is missing.
function Bed_CanRest(_ch) {
    return is_struct(_ch) && (_ch.hp < _ch.max_hp || _ch.mp < _ch.max_mp);
}

// A changed copy with full HP and MP.
function Bed_Heal(_ch) {
    var ch = variable_clone(_ch);
    ch.hp = ch.max_hp;
    ch.mp = ch.max_mp;
    return ch;
}

// { ok, ch }: a changed copy holding the skill's upgrade; not ok (and ch unchanged) when he does not own the skill or has the upgrade already.
function Bed_Upgrade(_ch, _skill_id) {
    var out = { ok: false, ch: _ch };
    if (!array_contains(Bed_UpgradableSkills(_ch), _skill_id)) return out;
    var r = Card_Take(_ch, Card_UpgradeId(_skill_id));
    out.ok = true;
    out.ch = r.ch;
    return out;
}

// The whole choice. _choice is "heal" or "upgrade" (with the skill id). Marks the bed used only when something happened.
// Returns { ok, ch, msg }; _flags is changed in place. A refused choice (D156: already rested, nothing to upgrade) changes nothing and has a line in msg.
function Bed_Choose(_ch, _flags, _key, _choice, _skill_id) {
    var out = { ok: false, ch: _ch, msg: "" };
    if (Bed_Used(_flags, _key)) {
        out.msg = Loc_T("bed.used", "You have rested here already. The bed is still warm.");
        return out;
    }
    if (_choice == "heal") {
        if (!Bed_CanRest(_ch)) {
            out.msg = Loc_T("bed.msg.rested", "You are already rested.");
            return out;
        }
        out.ch = Bed_Heal(_ch);
        out.ok = true;
    } else if (_choice == "upgrade") {
        var u = Bed_Upgrade(_ch, _skill_id);
        if (!u.ok) {
            out.msg = Loc_T("bed.msg.nothing_to_upgrade", "Nothing to upgrade there.");
            return out;
        }
        out.ch = u.ch;
        out.ok = true;
    } else {
        return out;
    }
    Bed_MarkUsed(_flags, _key);
    return out;
}

// The bed's first menu (Ui framework items): Rest, Upgrade a skill, Leave. Upgrade is greyed when nothing can be upgraded.
function Bed_MenuItems(_ch) {
    var n = array_length(Bed_UpgradableSkills(_ch));
    var rested = !Bed_CanRest(_ch);   // D156: nothing to restore: the row stays selectable (it says why) but looks unavailable
    var heal = {
        id: "heal", label: Loc_T("bed.option.heal", "Rest"), value: "", kind: "button", enabled: true, dim: rested,
        help: rested ? Loc_T("bed.help.heal_rested", "You are already rested. Come back when HP or MP is missing.") : Loc_T("bed.help.heal", "Sleep a while and wake with all your HP and MP."),
        lines: [
            { label: Loc_T("bed.lbl.hp", "HP"), value: string(_ch.hp) + " > " + string(_ch.max_hp) },
            { label: Loc_T("bed.lbl.mp", "MP"), value: string(_ch.mp) + " > " + string(_ch.max_mp) }
        ]
    };
    var up = {
        id: "upgrade", label: Loc_T("bed.option.upgrade", "Upgrade a Skill"), value: (n > 0) ? "" : "-", kind: "button", enabled: (n > 0),
        help: (n > 0) ? Loc_T("bed.help.upgrade", "Think over one of your skills and make it better for good.")
                      : Loc_T("bed.help.upgrade_none", "None of your skills can be upgraded any more."),
        lines: []
    };
    var leave = {
        id: "leave", label: Loc_T("bed.option.leave", "Leave"), value: "", kind: "button", enabled: true,
        help: Loc_T("bed.help.leave", "Walk away. The bed stays free for later."), lines: []
    };
    return [heal, up, leave];
}

// The second menu: one row per skill that can be upgraded (the details panel shows what changes), then Back.
function Bed_UpgradeItems(_ch) {
    var items = [];
    var list = Bed_UpgradableSkills(_ch);
    for (var i = 0; i < array_length(list); i++) {
        var card = CardDB_Get(Card_UpgradeId(list[i]));
        array_push(items, {
            id: "skill", label: SkillDB_GetBase(list[i]).name, value: "+", kind: "button", enabled: true,
            help: Card_Sentence(card), lines: Card_Lines(card), skill_id: list[i]
        });
    }
    array_push(items, {
        id: "back", label: Loc_T("bed.option.back", "Back"), value: "", kind: "button", enabled: true,
        help: Loc_T("bed.help.back", "Go back without choosing."), lines: [], skill_id: -1
    });
    return items;
}
