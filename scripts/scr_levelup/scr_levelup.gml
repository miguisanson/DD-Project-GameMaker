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
    // Old STR/AGI/INT keys (pre-B1 characters) map to ATK/SPD/MAG; LUCK is dropped.
    if (!variable_struct_exists(_ch.stats, "atk")) _ch.stats.atk = variable_struct_exists(_ch.stats, "str") ? _ch.stats.str : 10;
    if (!variable_struct_exists(_ch.stats, "def")) _ch.stats.def = 10;
    if (!variable_struct_exists(_ch.stats, "spd")) _ch.stats.spd = variable_struct_exists(_ch.stats, "agi") ? _ch.stats.agi : 10;
    if (!variable_struct_exists(_ch.stats, "mag")) _ch.stats.mag = variable_struct_exists(_ch.stats, "intt") ? _ch.stats.intt : 10;
    _ch.stats = StatsClampAll({ atk: _ch.stats.atk, def: _ch.stats.def, spd: _ch.stats.spd, mag: _ch.stats.mag });

    // Banked free points (D76) survive; a character without the field has none.
    if (!variable_struct_exists(_ch, "stat_points")) _ch.stat_points = 0;
    _ch.stat_points = max(0, round(_ch.stat_points));

    Card_EnsureFields(_ch);

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

// Fixed growth per class for reaching _new_level (>= 2); combat-spec.md section 2. The level's ONE free point is separate (D76).
function LevelUp_ClassGrowthGain(_class_id, _new_level) {
    var lvl = max(2, round(_new_level));
    switch (_class_id) {
        case CLASS_KNIGHT: return { atk:1, def:1, spd:0, mag:0 };
        case CLASS_ARCHER: return { atk:1, def:0, spd:1, mag:0 };
        case CLASS_MAGE:   return { atk:0, def:0, spd:0, mag:2 };
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
            return { atk:r1.atk + r2.atk, def:r1.def + r2.def, spd:r1.spd + r2.spd, mag:r1.mag + r2.mag };
    }
    return { atk:0, def:0, spd:0, mag:0 };
}

// Free points are placed by the player in a run (the stat prompt, CardsUi); outside a run (tests, tools) they go to the class default at once.
function Level_AutoPlaceEnabled() {
    if (!variable_global_exists("levelup_auto_place")) global.levelup_auto_place = true;
    return global.levelup_auto_place && !Run_IsActive();   // C2: during a run the player places the point (the stat prompt); tests and tools still auto-place
}

// D76: spends one banked free point on _stat_id (STAT_ATK/DEF/SPD/MAG). Does nothing without a point or with an unknown stat.
function Level_ApplyFreePoint(_ch, _stat_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "stat_points") || _ch.stat_points <= 0) return _ch;
    if (!Stat_IsValid(_stat_id)) return _ch;
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
    if (!is_struct(_ch.stats)) _ch.stats = StatsCreateBase();

    var class_id = variable_struct_exists(_ch, "class_id") ? _ch.class_id : CLASS_NOBODY;
    var gain = LevelUp_ClassGrowthGain(class_id, _ch.level);
    _ch.stats.atk = StatClamp(_ch.stats.atk + gain.atk);
    _ch.stats.def = StatClamp(_ch.stats.def + gain.def);
    _ch.stats.spd = StatClamp(_ch.stats.spd + gain.spd);
    _ch.stats.mag = StatClamp(_ch.stats.mag + gain.mag);

    if (!variable_struct_exists(_ch, "last_growth") || !is_struct(_ch.last_growth)) _ch.last_growth = { atk:0, def:0, spd:0, mag:0 };
    _ch.last_growth.atk += gain.atk;
    _ch.last_growth.def += gain.def;
    _ch.last_growth.spd += gain.spd;
    _ch.last_growth.mag += gain.mag;

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
    _ch.last_growth = { atk:0, def:0, spd:0, mag:0 };

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
    if (!Level_AutoPlaceEnabled() && _ch.stat_points > 0) return "stat";
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

// The four rows of the free-point prompt: the stat, its value now and after the point.
function Cards_StatOptions(_ch) {
    var ids = [STAT_ATK, STAT_DEF, STAT_SPD, STAT_MAG];
    var out = [];
    for (var i = 0; i < 4; i++) {
        var from = variable_struct_get(_ch.stats, Stat_Key(ids[i]));
        array_push(out, { stat: ids[i], label: Stat_ShortName(ids[i]), from: from, to: StatClamp(from + 1) });
    }
    return out;
}

// Spends one banked point on _stat_id (Level_ApplyFreePoint) and gives the extra MP a MAG point adds.
function Cards_PlaceStat(_ch, _stat_id) {
    var max_mp0 = _ch.max_mp;
    _ch = Level_ApplyFreePoint(_ch, _stat_id);
    _ch = RecomputeResources(_ch);
    _ch.mp = clamp(_ch.mp + max(0, _ch.max_mp - max_mp0), 0, _ch.max_mp);
    return _ch;
}

// The pick screen's cursor: positions 0.._n-1 are the cards, _n is Skip. Left / right walk the cards (wrapping, D95); down goes to Skip; up
// returns to the card it came from (_last).
function Cards_PickMove(_cur, _n, _dx, _dy, _last) {
    if (_cur >= _n) {
        if (_dy < 0) return clamp(_last, 0, _n - 1);
        return _n;
    }
    if (_dy > 0) return _n;
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
// Returns { ok, ch }; _flags is changed in place.
function Bed_Choose(_ch, _flags, _key, _choice, _skill_id) {
    var out = { ok: false, ch: _ch };
    if (Bed_Used(_flags, _key)) return out;
    if (_choice == "heal") {
        out.ch = Bed_Heal(_ch);
        out.ok = true;
    } else if (_choice == "upgrade") {
        var u = Bed_Upgrade(_ch, _skill_id);
        if (!u.ok) return out;
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
    var heal = {
        id: "heal", label: Loc_T("bed.option.heal", "Rest"), value: "", kind: "button", enabled: true,
        help: Loc_T("bed.help.heal", "Sleep a while and wake with all your HP and MP."),
        lines: [
            { label: Loc_T("bed.lbl.hp", "HP"), value: string(_ch.hp) + " > " + string(_ch.max_hp) },
            { label: Loc_T("bed.lbl.mp", "MP"), value: string(_ch.mp) + " > " + string(_ch.max_mp) }
        ]
    };
    var up = {
        id: "upgrade", label: Loc_T("bed.option.upgrade", "Upgrade a skill"), value: (n > 0) ? "" : "-", kind: "button", enabled: (n > 0),
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
