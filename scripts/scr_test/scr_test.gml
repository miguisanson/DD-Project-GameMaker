// Headless test harness (VER-02, VER-05, VER-12). See .planning/research/automation-igor.md section 3.
// Everything here is inert unless the exe is started with -runtests (normal play never touches it).
//   Test_Boot()    called first thing in obj_game_controller Create; returns at once without -runtests
//   Test_Eq/True   assertion helpers: each appends one "[TEST] PASS|FAIL ..." line
//   Test_RunAll()  runs every Test_Suite_* (each wrapped in try/catch) and returns the counts struct
//   Output: stdout (show_debug_message) and test_results.txt in the save area.

function Test_HasFlag(_flag) {
    for (var _i = 0; _i <= parameter_count(); _i++) {
        if (parameter_string(_i) == _flag) return true;
    }
    return false;
}

function Test_Reset() {
    global.test = { lines: [], pass: 0, fail: 0, errors: 0 };
    global.tutorial_off = true;   // C4 (D45): no first-time pop-up opens inside a suite (Test_Suite_Tutorial switches it on for itself)
}

function Test_Log(_line) {
    if (!variable_global_exists("test")) Test_Reset();
    array_push(global.test.lines, _line);
    show_debug_message(_line);
}

function Test_Eq(_name, _got, _want) {
    if (!variable_global_exists("test")) Test_Reset();
    if (_got == _want) {
        global.test.pass++;
        Test_Log("[TEST] PASS " + _name);
    } else {
        global.test.fail++;
        Test_Log("[TEST] FAIL " + _name + " got=" + string(_got) + " want=" + string(_want));
    }
}

function Test_True(_name, _cond) {
    Test_Eq(_name, bool(_cond), true);
}

function Test_WriteResults() {
    var _f = file_text_open_write("test_results.txt");
    if (_f == -1) return;
    for (var _i = 0; _i < array_length(global.test.lines); _i++) {
        file_text_write_string(_f, global.test.lines[_i]);
        file_text_writeln(_f);
    }
    file_text_close(_f);
}

// Runs one suite; any exception counts as an error and does not hide the other suites.
function Test_RunSuite(_name, _fn) {
    try {
        _fn();
    } catch (_e) {
        global.test.errors++;
        Test_Log("[TEST] ERROR " + _name + " " + string(_e.message));
    }
    Test_FixRestore();
}

function Test_RunAll() {
    Test_Reset();
    Test_RunSuite("Math", Test_Suite_Math);
    Test_RunSuite("Stats", Test_Suite_Stats);
    Test_RunSuite("Combat", Test_Suite_Combat);
    Test_RunSuite("Fx", Test_Suite_Fx);
    Test_RunSuite("BattleClock", Test_Suite_BattleClock);
    Test_RunSuite("UiClock", Test_Suite_UiClock);
    Test_RunSuite("Qte", Test_Suite_Qte);
    Test_RunSuite("QteArrows", Test_Suite_QteArrows);
    Test_RunSuite("QteDefence", Test_Suite_QteDefence);
    Test_RunSuite("Status", Test_Suite_Status);
    Test_RunSuite("StatusRules", Test_Suite_StatusRules);
    Test_RunSuite("Turns", Test_Suite_Turns);
    Test_RunSuite("EnemyAI", Test_Suite_EnemyAI);
    Test_RunSuite("Inventory", Test_Suite_Inventory);
    Test_RunSuite("Data", Test_Suite_Data);
    Test_RunSuite("Export", Test_Suite_Export);
    Test_RunSuite("Player", Test_Suite_Player);
    Test_RunSuite("Loc", Test_Suite_Loc);
    Test_RunSuite("Display", Test_Suite_Display);
    Test_RunSuite("WindowModes", Test_Suite_WindowModes);
    Test_RunSuite("Skip", Test_Suite_Skip);
    Test_RunSuite("Nav", Test_Suite_Nav);
    Test_RunSuite("Snap", Test_Suite_Snap);
    Test_RunSuite("SaveAtomic", Test_Suite_SaveAtomic);
    Test_RunSuite("SettingsMigration", Test_Suite_SettingsMigration);
    Test_RunSuite("Rng", Test_Suite_Rng);
    Test_RunSuite("Profile", Test_Suite_Profile);
    Test_RunSuite("RunSave", Test_Suite_RunSave);
    Test_RunSuite("RunLoop", Test_Suite_RunLoop);
    Test_RunSuite("Story", Test_Suite_Story);
    Test_RunSuite("Cards", Test_Suite_Cards);
    Test_RunSuite("Assist", Test_Suite_Assist);
    Test_RunSuite("Binds", Test_Suite_Binds);
    Test_RunSuite("Prompt", Test_Suite_Prompt);
    Test_RunSuite("Tutorial", Test_Suite_Tutorial);
    Test_RunSuite("Notice", Test_Suite_Notice);
    Test_RunSuite("Bed", Test_Suite_Bed);
    Test_RunSuite("Economy", Test_Suite_Economy);
    Test_RunSuite("BattleUi", Test_Suite_BattleUi);
    Test_RunSuite("TabMenu", Test_Suite_TabMenu);
    Test_RunSuite("BalanceD111", Test_Suite_BalanceD111);
    Test_RunSuite("FairRng", Test_Suite_FairRng);
    Test_RunSuite("FairUi", Test_Suite_FairUi);
    Test_RunSuite("Save", Test_Suite_Save); // last: Save_ApplySnapshot replaces global state
    Test_RunSuite("Mem", Test_Suite_Mem);
    Test_RunSuite("Input", Test_Suite_Input);
    Test_RunSuite("UI", Test_Suite_UI);
    Test_RunSuite("MetricsCache", Test_Suite_MetricsCache);
    Test_RunSuite("LayoutCache", Test_Suite_LayoutCache);
    Test_RunSuite("MenuMeasure", Test_Suite_MenuMeasure);
    Test_RunSuite("SfxInit", Test_Suite_SfxInit);
    Test_RunSuite("Audio", Test_Suite_Audio);
    Test_RunSuite("Transition", Test_Suite_Transition);
    Test_RunSuite("Hunt2", Test_Suite_Hunt2);
    Test_RunSuite("Title", Test_Suite_Title);
    if (Test_HasFlag("-testcontrol")) {
        // Deliberately failing assertion: proves a red run is reported (want 2, got 1).
        Test_Eq("negative_control", 1, 2);
    }
    var _t = global.test;
    Test_Log("[TEST-SUMMARY] pass=" + string(_t.pass) + " fail=" + string(_t.fail) + " errors=" + string(_t.errors));
    return _t;
}

function Test_Boot() {
    if (!Test_HasFlag("-runtests")) return;

    // Unhandled GML error: log it, write the results file, end the game.
    // game_end(n) inside this handler still gives exit code 0, so the wrapper must read the log (VER-05).
    exception_unhandled_handler(function(_ex) {
        var _msg = string(_ex.message);
        show_debug_message("[TEST] ERROR UNHANDLED " + _msg);
        show_debug_message("[TEST] CRASH");
        if (!variable_global_exists("test")) Test_Reset();
        array_push(global.test.lines, "[TEST] ERROR UNHANDLED " + _msg);
        array_push(global.test.lines, "[TEST] CRASH");
        Test_WriteResults();
        game_end(2);
        return 0;
    });

    // Fixed seed (VER-12). Mark the RNG as initialised so GameState_Init's randomize() guard is skipped.
    global.rng_inited = true;
    random_set_seed(12345);

    var _t = Test_RunAll();
    Test_WriteResults();
    game_end((_t.fail > 0 || _t.errors > 0) ? 1 : 0);
}

// Pure stat/level functions. Expected values come from .planning/research/combat-spec.md (sections 1-3, 7), not from running the code.
function Test_Suite_Math() {
    // StatClamp keeps stats in 1..60. StatMod and RollD20 are gone (D22, D80): stats are used directly.
    Test_Eq("StatClamp(0)==1", StatClamp(0), 1);
    Test_Eq("StatClamp(99)==60", StatClamp(99), 60);
    Test_Eq("StatClamp(25)==25", StatClamp(25), 25);
    // HP per level = ceil(hd/2)+2: Knight hd10 -> 7, Archer hd8 -> 6, Mage hd6 -> 5.
    Test_Eq("HPGainPerLevel(10)==7", HPGainPerLevel(10), 7);
    Test_Eq("HPGainPerLevel(8)==6", HPGainPerLevel(8), 6);
    Test_Eq("HPGainPerLevel(6)==5", HPGainPerLevel(6), 5);
    // EXP curve (spec section 7): 12,24,40,58,80,105,135,170,210 (L1..L9), 0 at the cap; cumulative to L9 = 624, to L10 = 834.
    Test_Eq("Exp_NextLevel(1)==12", Exp_NextLevel(1), 12);
    Test_Eq("Exp_NextLevel(9)==210", Exp_NextLevel(9), 210);
    Test_Eq("Exp_NextLevel(10)==0", Exp_NextLevel(10), 0);
    var _cum = 0;
    for (var _l = 1; _l < 10; _l++) _cum += Exp_NextLevel(_l);
    Test_Eq("EXP cumulative L1..L10==834", _cum, 834);
    Test_Eq("EXP cumulative L1..L9==624", _cum - Exp_NextLevel(9), 624);
    // Level cap is 10.
    Test_True("Level_IsAtCap(10)", Level_IsAtCap(10));
    Test_False("Level_IsAtCap(9)", Level_IsAtCap(9));
}

// Stats (combat-spec.md sections 1-3, 5-8; STAT-01, STAT-02, STAT-12). The "vec" lines are the cases of
// .planning/research/combat-vectors.json written out by hand (tools/balance/check_combat_vectors.py fails if one is missing or differs).
function Test_ClassAt(_name, _class, _level, _atk, _def, _spd, _mag, _hp, _mp) {
    var _c = CharacterCreate_Player(_class);
    for (var _i = 1; _i < _level; _i++) _c = LevelUp_ApplyLevel(_c);
    Test_Eq(_name + " level", _c.level, _level);
    Test_Eq(_name + " ATK", _c.stats.atk, _atk);
    Test_Eq(_name + " DEF", _c.stats.def, _def);
    Test_Eq(_name + " SPD", _c.stats.spd, _spd);
    Test_Eq(_name + " MAG", _c.stats.mag, _mag);
    Test_Eq(_name + " max HP", _c.max_hp, _hp);
    Test_Eq(_name + " max MP", _c.max_mp, _mp);
}

function Test_EnemyAt(_name, _enemy_id, _level, _atk, _def, _spd, _mag, _hp) {
    var _gs = GameState_Get();
    var _lv0 = _gs.battle.enemy_level;
    _gs.battle.enemy_level = _level;
    var _e = EnemyCreate(_enemy_id);
    _gs.battle.enemy_level = _lv0;
    Test_Eq(_name + " level", _e.level, _level);
    Test_Eq(_name + " ATK", _e.stats.atk, _atk);
    Test_Eq(_name + " DEF", _e.stats.def, _def);
    Test_Eq(_name + " SPD", _e.stats.spd, _spd);
    Test_Eq(_name + " MAG", _e.stats.mag, _mag);
    Test_Eq(_name + " max HP", _e.max_hp, _hp);
}

function Test_Suite_Stats() {
    Test_Hero(CLASS_KNIGHT);
    Test_Eq("vec dmg_01", Combat_RatioDamage(6, 11, 7, 1.0, 1.0), 4);
    Test_Eq("vec dmg_02", Combat_RatioDamage(7, 5, 5, 1.0, 1.0), 4);
    Test_Eq("vec dmg_03", Combat_RatioDamage(1, 1, 60, 1.0, 1.0), 1);
    Test_Eq("vec dmg_04", Combat_RatioDamage(6, 11, 7, 1.3, 1.0), 5);
    Test_Eq("vec dmg_05", Combat_RatioDamage(6, 11, 7, 1.1, 1.0), 5);
    Test_Eq("vec dmg_06", Combat_RatioDamage(6, 11, 7, 0.75, 1.0), 3);
    Test_Eq("vec dmg_07", Combat_RatioDamage(1, 1, 60, 0.75, 1.0), 1);
    Test_Eq("vec dmg_08", Combat_RatioDamage(1, 1, 60, 1.3, 1.0), 2);
    Test_Eq("vec dmg_09", Combat_RatioDamage(6, 11, 7, 1.0, 0.0), 0);
    Test_Eq("vec dmg_10", Combat_RatioDamage(6, 11, 7, 1.0, 0.8), 3);
    Test_Eq("vec dmg_11", Combat_RatioDamage(6, 8, 7, 1.0, 0.25), 1);
    Test_Eq("vec dmg_12", Combat_RatioDamage(6, 11, 7, 1.0, 2.0), 7);
    Test_Eq("vec dmg_13", Combat_RatioDamage(19.5, 11, 7, 1.0, 1.0), 12);
    Test_Eq("vec dmg_14", Combat_RatioDamage(22, 29, 18, 1.0, 1.0), 14);
    Test_Eq("vec dmg_15", Combat_RatioDamage(0, 11, 7, 1.0, 1.0), 0);
    Test_Eq("vec dmg_16", Combat_RatioDamage(4, 8, 12, 1.0, 1.0), 2);
    Test_Eq("vec dmg_17", Combat_RatioDamage(12, 12, 12, 1.3, 1.0), 8);
    Test_Eq("vec dmg_18", Combat_RatioDamage(18, 6, 6, 0.75, 1.0), 7);
    Test_Eq("vec dmg_19", Combat_RatioDamage(9, 21, 18, 1.0, 1.0), 5);
    Test_Eq("vec dmg_20", Combat_RatioDamage(13, 5, 60, 1.0, 1.0), 1);
    Test_Eq("vec dmg_21", Combat_RatioDamage(6, 11, 7, 1.0, 4.0), 15);
    Test_Eq("vec dmg_22", Combat_RatioDamage(6, 11, 7, 1.0, 0.65), 2);
    Test_Eq("vec pow_01", Combat_PowerBasic(3), 6.0);
    Test_Eq("vec pow_02", Combat_PowerBasic(6), 12.0);
    Test_Eq("vec pow_03", Combat_PowerBasic(1), 2.0);
    Test_Eq("vec pow_04", Combat_PowerSkill(5, 1.5, 3), 19.5);
    Test_Eq("vec pow_05", Combat_PowerSkill(4, 1.0, 9), 17.0);
    Test_Eq("vec pow_06", Combat_PowerEnemySkill(4, 1.0), 8.0);
    Test_Eq("vec hp_10_1", Resource_MaxHp(10, 1), 10);
    Test_Eq("vec hp_10_10", Resource_MaxHp(10, 10), 73);
    Test_Eq("vec hp_8_5", Resource_MaxHp(8, 5), 34);
    Test_Eq("vec hp_6_10", Resource_MaxHp(6, 10), 55);
    Test_Eq("vec hp_8_3", Resource_MaxHp(8, 3), 22);
    Test_Eq("vec mp_1_1_3", Resource_MaxMp(1, 1, 3), 11);
    Test_Eq("vec mp_2_10_39", Resource_MaxMp(2, 10, 39), 47);
    Test_Eq("vec mp_2_1_12", Resource_MaxMp(2, 1, 12), 16);
    Test_Eq("vec mp_1_5_4", Resource_MaxMp(1, 5, 4), 16);
    Test_ClassAt("vec cls_knight_1", CLASS_KNIGHT, 1, 11, 12, 10, 3, 10, 11);
    Test_ClassAt("vec cls_knight_2", CLASS_KNIGHT, 2, 12, 14, 10, 3, 17, 12);
    Test_ClassAt("vec cls_knight_3", CLASS_KNIGHT, 3, 13, 16, 10, 3, 24, 13);
    Test_ClassAt("vec cls_knight_5", CLASS_KNIGHT, 5, 15, 20, 10, 3, 38, 15);
    Test_ClassAt("vec cls_knight_10", CLASS_KNIGHT, 10, 20, 30, 10, 3, 73, 20);
    Test_ClassAt("vec cls_archer_1", CLASS_ARCHER, 1, 9, 8, 13, 4, 10, 12);
    Test_ClassAt("vec cls_archer_2", CLASS_ARCHER, 2, 11, 8, 14, 4, 16, 14);
    Test_ClassAt("vec cls_archer_3", CLASS_ARCHER, 3, 13, 8, 15, 4, 22, 16);
    Test_ClassAt("vec cls_archer_5", CLASS_ARCHER, 5, 17, 8, 17, 4, 34, 20);
    Test_ClassAt("vec cls_archer_10", CLASS_ARCHER, 10, 27, 8, 22, 4, 64, 30);
    Test_ClassAt("vec cls_mage_1", CLASS_MAGE, 1, 5, 7, 10, 12, 10, 16);
    Test_ClassAt("vec cls_mage_2", CLASS_MAGE, 2, 5, 7, 10, 15, 15, 19);
    Test_ClassAt("vec cls_mage_3", CLASS_MAGE, 3, 5, 7, 10, 18, 20, 23);
    Test_ClassAt("vec cls_mage_5", CLASS_MAGE, 5, 5, 7, 10, 24, 30, 30);
    Test_ClassAt("vec cls_mage_10", CLASS_MAGE, 10, 5, 7, 10, 39, 55, 47);
    Test_ClassAt("vec cls_nobody_1", CLASS_NOBODY, 1, 8, 8, 9, 3, 10, 11);
    Test_ClassAt("vec cls_nobody_2", CLASS_NOBODY, 2, 10, 8, 10, 3, 16, 12);
    Test_ClassAt("vec cls_nobody_3", CLASS_NOBODY, 3, 11, 9, 10, 4, 22, 14);
    Test_ClassAt("vec cls_nobody_5", CLASS_NOBODY, 5, 14, 10, 11, 5, 34, 16);
    Test_ClassAt("vec cls_nobody_10", CLASS_NOBODY, 10, 22, 12, 14, 7, 64, 22);
    Test_Eq("vec exp_1", Exp_NextLevel(1), 12);
    Test_Eq("vec exp_2", Exp_NextLevel(2), 24);
    Test_Eq("vec exp_3", Exp_NextLevel(3), 40);
    Test_Eq("vec exp_4", Exp_NextLevel(4), 58);
    Test_Eq("vec exp_5", Exp_NextLevel(5), 80);
    Test_Eq("vec exp_6", Exp_NextLevel(6), 105);
    Test_Eq("vec exp_7", Exp_NextLevel(7), 135);
    Test_Eq("vec exp_8", Exp_NextLevel(8), 170);
    Test_Eq("vec exp_9", Exp_NextLevel(9), 210);
    Test_Eq("vec exp_10", Exp_NextLevel(10), 0);
    Test_EnemyAt("vec en_slime_1", ENEMY_SLIME, 1, 8, 7, 9, 5, 9);
    Test_EnemyAt("vec en_spider_3", ENEMY_SPIDER, 3, 8, 7, 10, 5, 20);
    Test_EnemyAt("vec en_snake_4", ENEMY_SNAKE, 4, 9, 7, 10, 5, 25);
    Test_EnemyAt("vec en_mad_whisp_6", ENEMY_MADWHISP, 6, 10, 9, 12, 13, 32);
    Test_EnemyAt("vec en_killer_plant_5", ENEMY_KILLER_PLANT, 5, 12, 11, 9, 10, 34);
    Test_EnemyAt("vec en_dire_wolf_4", ENEMY_DIREWOLF, 4, 11, 9, 11, 6, 27);
    Test_EnemyAt("vec en_ghost_sword_6", ENEMY_GHOSTSWORD, 6, 14, 12, 12, 10, 40);
    Test_EnemyAt("vec en_stranger_8", ENEMY_STRANGER, 8, 16, 14, 13, 15, 53);
    Test_EnemyAt("vec en_palehorn_8", ENEMY_MINI_BOSS, 8, 18, 18, 12, 14, 97);
    Test_EnemyAt("vec en_choirbeast_10", ENEMY_FINAL_BOSS, 10, 21, 24, 14, 19, 194);
    Test_Eq("vec run_8_9", Battle_RunChance(8, 9), 0.470588);
    Test_Eq("vec run_13_9", Battle_RunChance(13, 9), 0.590909);
    Test_Eq("vec run_30_5", Battle_RunChance(30, 5), 0.857143);
    Test_Eq("vec run_1_40", Battle_RunChance(1, 40), 0.02439);
    Test_Eq("vec run_10_10", Battle_RunChance(10, 10), 0.5);
    Test_Eq("vec crit_0", Combat_CritChance(0), 0.0);
    Test_Eq("vec crit_25", Combat_CritChance(25), 0.25);
    Test_Eq("vec crit_80", Combat_CritChance(80), 0.5);
    Test_Eq("vec heal_5_12", Combat_HealAmount(5, 12), 8);
    Test_Eq("vec first_8_9", Combat_PlayerActsFirst(8, 9), false);
    Test_Eq("vec first_9_9", Combat_PlayerActsFirst(9, 9), true);
    Test_Eq("vec first_13_9", Combat_PlayerActsFirst(13, 9), true);
    // The old stats are gone from the character (STAT-01): four stats only.
    var _k = CharacterCreate_Player(CLASS_KNIGHT);
    Test_True("STAT-01 stats are atk, def, spd, mag", variable_struct_exists(_k.stats, "atk") && variable_struct_exists(_k.stats, "def") && variable_struct_exists(_k.stats, "spd") && variable_struct_exists(_k.stats, "mag"));
    Test_False("STAT-01 STR/AGI/INT/LUCK are gone", variable_struct_exists(_k.stats, "str") || variable_struct_exists(_k.stats, "agi") || variable_struct_exists(_k.stats, "intt") || variable_struct_exists(_k.stats, "luck"));
    // Each stat has a felt effect (STAT-01): ATK -> damage dealt, DEF -> damage taken, MAG -> damage and max MP, SPD -> who acts first.
    var _hi = CharacterCreate_Player(CLASS_KNIGHT); _hi.stats.atk = 22;
    var _lo = CharacterCreate_Player(CLASS_KNIGHT);
    Test_True("STAT-01 more ATK deals more damage", Combat_Damage(_hi, EnemyCreate(ENEMY_SLIME), Test_Wpn(10, STAT_ATK, 0)) > Combat_Damage(_lo, EnemyCreate(ENEMY_SLIME), Test_Wpn(10, STAT_ATK, 0)));
    var _tank = CharacterCreate_Player(CLASS_KNIGHT); _tank.stats.def = 30;
    Test_True("STAT-01 more DEF takes less damage", Combat_Damage(EnemyCreate(ENEMY_FINAL_BOSS), _tank, Test_Wpn(9, STAT_ATK, 0)) < Combat_Damage(EnemyCreate(ENEMY_FINAL_BOSS), _lo, Test_Wpn(9, STAT_ATK, 0)));
    var _wiz = CharacterCreate_Player(CLASS_KNIGHT); _wiz.stats.mag = 21; _wiz = RecomputeResources(_wiz);
    Test_True("STAT-01 more MAG gives more max MP", _wiz.max_mp > _lo.max_mp);
    Test_True("STAT-01 more MAG gives more spell damage", Combat_Damage(_wiz, EnemyCreate(ENEMY_SLIME), Test_Wpn(10, STAT_MAG, 0)) > Combat_Damage(_lo, EnemyCreate(ENEMY_SLIME), Test_Wpn(10, STAT_MAG, 0)));
    Test_True("STAT-01 SPD decides who acts first (Archer 13 vs Slime 9)", Combat_PlayerActsFirst(Combat_EffectiveStat(CharacterCreate_Player(CLASS_ARCHER), STAT_SPD), Combat_EffectiveStat(EnemyCreate(ENEMY_SLIME), STAT_SPD)));
    Test_True("STAT-01 SPD decides who acts first (Knight 10 vs Slime 9, D111)", Combat_PlayerActsFirst(Combat_EffectiveStat(_lo, STAT_SPD), Combat_EffectiveStat(EnemyCreate(ENEMY_SLIME), STAT_SPD)));
    // Equipment: a bonus struct with atk/def/spd/mag keys counts as stats; a weapon's power adds to skill power too (D22).
    var _gear = CharacterCreate_Player(CLASS_KNIGHT);
    _gear.inventory = Inv_Add(_gear.inventory, 22, 1);
    Test_True("Equip: Platinum Armor equips", Equip_Item(_gear, 22));
    Test_Eq("Equip: Platinum Armor adds DEF +3 -> effective DEF 15", Combat_EffectiveStat(_gear, STAT_DEF), 15);
    Test_Eq("Equip: Platinum Armor has no ATK bonus", Combat_EffectiveStat(_gear, STAT_ATK), 11);
    var _robed = CharacterCreate_Player(CLASS_MAGE);
    _robed.inventory = Inv_Add(_robed.inventory, 25, 1);
    Test_True("Equip: Mithril Robe equips", Equip_Item(_robed, 25));
    Test_Eq("Equip: Mithril Robe adds MAG +3 -> effective MAG 15", Combat_EffectiveStat(_robed, STAT_MAG), 15);
    var _staffer = CharacterCreate_Player(CLASS_MAGE);
    _staffer.inventory = Inv_Add(_staffer.inventory, 7, 1);
    Test_True("Equip: Wooden Staff equips", Equip_Item(_staffer, 7));
    Test_Eq("D22 weapon power: Wooden Staff (power 3) is the equipped weapon power", Combat_WeaponPower(_staffer), 3);
    Test_Eq("D22 weapon power: no weapon counts as 2 (fists)", Combat_WeaponPower(CharacterCreate_Player(CLASS_MAGE)), 2);
    // D22: the same skill hits harder with a weapon equipped. Fireball (power 6) on a Stranger (DEF14), Mage MAG12: fists 2*(6+1)=14 -> 6.46 = 6; Wooden Staff 2*(6+1.5)=15 -> 6.92 = 7.
    var _bare = CharacterCreate_Player(CLASS_MAGE); _bare.mp = 99;
    var _armed = _staffer; _armed.mp = 99;
    var _fb_bare = Skill_Use(_bare, EnemyCreate(ENEMY_STRANGER), SKILL_FIREBALL);
    var _fb_armed = Skill_Use(_armed, EnemyCreate(ENEMY_STRANGER), SKILL_FIREBALL);
    Test_Eq("D22 Fireball without a weapon deals 6", _fb_bare.dmg, 6);
    Test_Eq("D22 Fireball with the Wooden Staff deals 7", _fb_armed.dmg, 7);
    // STAT-12 / D76: fixed growth plus ONE free point per level. Spending it: Level_ApplyFreePoint.
    var _c = CharacterCreate_Player(CLASS_KNIGHT);
    Test_Eq("D76 a new character has no free points", _c.stat_points, 0);
    Test_True("D76 free points auto-place until the level-up UI exists", Level_AutoPlaceEnabled());
    _c.stat_points = 1;
    var _c2 = Level_ApplyFreePoint(_c, STAT_SPD);
    Test_Eq("Level_ApplyFreePoint adds +1 to the chosen stat", _c2.stats.spd, 11);   // Knight SPD 10 (D111) + 1
    Test_Eq("Level_ApplyFreePoint spends the point", _c2.stat_points, 0);
    var _c3 = Level_ApplyFreePoint(_c2, STAT_SPD);
    Test_Eq("Level_ApplyFreePoint with no points left changes nothing", _c3.stats.spd, 11);
    var _c4 = CharacterCreate_Player(CLASS_KNIGHT); _c4.stat_points = 1;
    _c4 = Level_ApplyFreePoint(_c4, 17);
    Test_Eq("Level_ApplyFreePoint rejects an unknown stat and keeps the point", _c4.stat_points, 1);
    var _cap = CharacterCreate_Player(CLASS_KNIGHT); _cap.stats.mag = 60; _cap.stat_points = 1;
    _cap = Level_ApplyFreePoint(_cap, STAT_MAG);
    Test_Eq("Level_ApplyFreePoint clamps at the stat maximum (60)", _cap.stats.mag, 60);
    // With auto-placement off the level-up banks the point; the UI packet then spends it.
    var _bank = CharacterCreate_Player(CLASS_ARCHER);
    global.levelup_auto_place = false;
    _bank = LevelUp_ApplyLevel(_bank);
    global.levelup_auto_place = true;
    Test_Eq("D76 level-up with auto-place off banks 1 free point", _bank.stat_points, 1);
    Test_Eq("D76 level-up with auto-place off still applies the fixed growth (Archer SPD+1 ATK+1)", _bank.stats.spd + _bank.stats.atk, 13 + 9 + 2);
    Test_Eq("LevelUp_ApplyLevel gives the HP gain as current HP (Archer L2 = 16)", _bank.hp, 16);
    // EXP: 834 exactly reaches the cap; 624 (a clean pass to the final boss) is level 9.
    var _run = Player_AddExp(CharacterCreate_Player(CLASS_KNIGHT), 834);
    Test_Eq("EXP 834 takes a Knight to the cap (10)", _run.level, 10);
    Test_Eq("Knight L10 via EXP matches the class table (ATK 20 DEF 30)", _run.stats.atk * 100 + _run.stats.def, 2030);
    var _run9 = Player_AddExp(CharacterCreate_Player(CLASS_KNIGHT), 624);
    Test_Eq("EXP 624 (a clean pass to the final boss) is level 9", _run9.level, 9);
    // The stat names the menus print (scr_menu helpers that read the stats).
    Test_Eq("Stat_ShortName(STAT_MAG) == MAG", Stat_ShortName(STAT_MAG), "MAG");
    Test_Eq("Stat_ShortName(STAT_SPD) == SPD", Stat_ShortName(STAT_SPD), "SPD");
    Test_Eq("Item_BonusText(Platinum Armor) == DEF +3", Item_BonusText(ItemDB_Get(22)), "DEF +3");
    Test_Eq("Item_BonusText(Mithril Robe) == MAG +3", Item_BonusText(ItemDB_Get(25)), "MAG +3");
    Test_Eq("Item_BonusText of a sword with no bonus is empty", Item_BonusText(ItemDB_Get(1)), "");
    Test_True("Stat_Sentence gives every stat a plain description", string_length(Stat_Sentence(STAT_SPD)) > 0 && Stat_Sentence(STAT_SPD) != Stat_Sentence(STAT_DEF));
    // Enemies carry the same four stats and a basic power by rank (spec section 6).
    var _sl = EnemyCreate(ENEMY_SLIME);
    Test_False("STAT-01 enemies have no luck/intt", variable_struct_exists(_sl.stats, "luck") || variable_struct_exists(_sl.stats, "intt"));
    Test_Eq("Enemy basic power: Slime (rank 1) = 5 (D111)", _sl.basic_power, 5);
    Test_Eq("Enemy basic power: Mad Whisp (rank 2) = 7 (D111)", EnemyCreate(ENEMY_MADWHISP).basic_power, 7);
    Test_Eq("Enemy basic power: Palehorn (rank 3) = 7", EnemyCreate(ENEMY_MINI_BOSS).basic_power, 7);
    Test_Eq("Enemy basic power: Pale Choirbeast (rank 4) = 14 (D111)", EnemyCreate(ENEMY_FINAL_BOSS).basic_power, 14);
}

// ---- Fixtures: shared game state is borrowed and put back by Test_RunSuite (Test_FixRestore). ----
function Test_FixBegin(_diff) {
    var _gs = GameState_Get();
    if (!(variable_global_exists("test_fix") && is_struct(global.test_fix))) {
        global.test_fix = { diff: _gs.difficulty, player: _gs.player_ch, flags: _gs.flags };
    }
    Difficulty_SetCurrent(_diff);
    return _gs;
}

function Test_FixRestore() {
    if (!(variable_global_exists("test_fix") && is_struct(global.test_fix))) return;
    var _gs = GameState_Get();
    _gs.difficulty = global.test_fix.diff;
    _gs.player_ch = global.test_fix.player;
    _gs.flags = global.test_fix.flags;
    global.test_fix = undefined;
}

// Fresh class character at the given difficulty; also installed as the game's player so Inv_Add sees its skills.
function Test_Hero(_class, _diff = DIFFICULTY_NORMAL) {
    var _gs = Test_FixBegin(_diff);
    var _p = CharacterCreate_Player(_class);
    _gs.player_ch = _p;
    return _p;
}

function Test_Wpn(_power, _stat, _acc) {
    return { power: _power, stat_type: _stat, acc: _acc };
}

// The game always calls Combat_ApplyDamage with crit and skill multipliers (scr_combat.gml:564, 1552).
function Test_Hit(_atk, _def, _wpn) {
    return Combat_ApplyDamage(_atk, _def, _wpn, 1, 1);
}

function Test_False(_name, _cond) {
    Test_Eq(_name, bool(_cond), false);
}

// Combat formulas (combat-spec.md sections 1, 4, 5). Start values: Knight ATK11 DEF12 HP10; Slime ATK8 DEF7 HP9 basic power 5 (rank 1, D111);
// Pale Choirbeast (final boss, L10) ATK21 DEF24 HP194 (D111); Mage MAG12 ATK5. A Test_Wpn power is the FINAL formula power (spec section 4).
// No dice anywhere (D80): the only avoidance is Evasion on the player. Expected values are worked out from the spec, not read from the code.
function Test_Suite_Combat() {
    var _k = Test_Hero(CLASS_KNIGHT);
    var _m = CharacterCreate_Player(CLASS_MAGE);
    var _slime = EnemyCreate(ENEMY_SLIME);
    var _boss = EnemyCreate(ENEMY_FINAL_BOSS);
    // Combat_Damage = the grade-OK ratio damage of one hit, no statuses: round_half_up(power x A / (A + D)), at least 1.
    Test_Eq("Combat_Damage knight(ATK11) power6 vs slime(DEF7) == 4", Combat_Damage(_k, _slime, Test_Wpn(6, STAT_ATK, 0)), 4);
    Test_Eq("Combat_Damage slime basic(power3,ATK8) vs knight(DEF12) == 1", Combat_Damage(_slime, _k, Test_Wpn(3, STAT_ATK, 0)), 1);
    Test_Eq("Combat_Damage never below 1 (power1 slime vs boss DEF24)", Combat_Damage(_slime, _boss, Test_Wpn(1, STAT_ATK, 0)), 1);
    Test_Eq("Combat_Damage uses the weapon stat: mage MAG12 power6 vs slime == 4", Combat_Damage(_m, _slime, Test_Wpn(6, STAT_MAG, 0)), 4);
    Test_Eq("Combat_Damage uses the weapon stat: mage ATK5 power6 vs slime == 3", Combat_Damage(_m, _slime, Test_Wpn(6, STAT_ATK, 0)), 3);
    Test_Eq("Combat_Damage a stronger ATK hits harder: boss ATK21 power9 vs knight DEF12 == 6", Combat_Damage(_boss, _k, Test_Wpn(9, STAT_ATK, 0)), 6);
    // Statuses change the effective stat: Poison MAG-1 (power20: MAG12 -> 13, MAG11 -> 12); Burning DEF x0.75 (packet B2, spec section 10).
    Test_Eq("Combat_Damage mage MAG12 power20 vs slime == 13", Combat_Damage(_m, _slime, Test_Wpn(20, STAT_MAG, 0)), 13);
    _m = Status_Add(_m, STATUS_POISON, 3, 0);
    Test_Eq("Combat_EffectiveStat mage poisoned MAG == 11", Combat_EffectiveStat(_m, STAT_MAG), 11);
    Test_Eq("Combat_Damage mage poisoned (MAG11) power20 vs slime == 12", Combat_Damage(_m, _slime, Test_Wpn(20, STAT_MAG, 0)), 12);
    var _burnt = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_BURN, 2, 0);
    Test_Eq("Combat_EffectiveStat knight burning ATK is untouched == 11", Combat_EffectiveStat(_burnt, STAT_ATK), 11);
    Test_Eq("Combat_EffectiveStat knight burning DEF == 9 (12 x 0.75)", Combat_EffectiveStat(_burnt, STAT_DEF), 9);
    Test_Eq("Combat_EffectiveStat knight DEF == 12", Combat_EffectiveStat(_k, STAT_DEF), 12);
    // BUG-21: self-buff animations play on the player, damaging skills on the enemy.
    var _buffs = [SKILL_MUSCLE_UP, SKILL_REV_UP, SKILL_EVASION, SKILL_TAKE_AIM, SKILL_MEDITATION, SKILL_FORESIGHT];
    var _attacks = [SKILL_HILT_BASH, SKILL_ICE_SPEAR, SKILL_HORIZ_SLASH, SKILL_FIREBALL, SKILL_WOUND, SKILL_POISON_ARROW, SKILL_DOUBLE_SHOT, SKILL_POISON_MIST];
    for (var _bi = 0; _bi < array_length(_buffs); _bi++) {
        Test_True("BUG-21 self-buff skill " + SkillDB_Get(_buffs[_bi]).name + " animates on the player", Battle_SkillFxOnPlayer(_buffs[_bi]));
    }
    for (var _ai = 0; _ai < array_length(_attacks); _ai++) {
        Test_False("BUG-21 attack skill " + SkillDB_Get(_attacks[_ai]).name + " animates on the enemy", Battle_SkillFxOnPlayer(_attacks[_ai]));
    }
    // D80: Evasion on the PLAYER fully dodges the next damaging enemy action and is consumed; it does nothing on an enemy (D6: the player never misses).
    var _evader = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_EVASION, 3, 0);
    var _dodge = Combat_TryDodge(EnemyCreate(ENEMY_SLIME), _evader);
    Test_True("Combat_TryDodge Evasion on the player dodges", _dodge.dodged);
    Test_False("Combat_TryDodge Evasion is consumed", Status_Has(_dodge.defender, STATUS_EVASION));
    Test_False("Combat_TryDodge a second attack is not dodged", Combat_TryDodge(EnemyCreate(ENEMY_SLIME), _dodge.defender).dodged);
    Test_False("Combat_TryDodge a player without Evasion is never dodging", Combat_TryDodge(EnemyCreate(ENEMY_SLIME), CharacterCreate_Player(CLASS_KNIGHT)).dodged);
    Test_False("Combat_TryDodge Evasion on an ENEMY does not dodge the player (D6)", Combat_TryDodge(_k, Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_EVASION, 3, 0)).dodged);
    var _bite_foe = EnemyCreate(ENEMY_SNAKE);
    var _bite_hero = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_EVASION, 3, 0);
    var _bite1 = Skill_Use(_bite_foe, _bite_hero, SKILL_BITE);
    Test_False("Skill_Use: an enemy skill against Evasion misses (hit=false)", _bite1.hit);
    Test_Eq("Skill_Use: the dodged skill deals 0", _bite1.dmg, 0);
    Test_Eq("Skill_Use: the dodging player keeps full HP", _bite_hero.hp, _bite_hero.max_hp);
    Test_False("Skill_Use: Evasion was used up by the dodge", Status_Has(_bite_hero, STATUS_EVASION));
    Test_True("Skill_Use: the next enemy skill lands", Skill_Use(_bite_foe, _bite_hero, SKILL_BITE).hit);
    // ApplyDamage: Rev Up (dmg_mult 2), Guard (0, consumed), Blessing (0.8), Solidify (0.25, consumed by the next hit, D80).
    Test_Eq("slime max_hp (L1) == 9", _slime.max_hp, 9);
    Test_Eq("Combat_ApplyDamage knight power6 vs slime dealt 4", Test_Hit(_k, _slime, Test_Wpn(6, STAT_ATK, 0)).dmg, 4);
    Test_Eq("Combat_ApplyDamage slime hp 9 -> 5", _slime.hp, 5);
    var _rev = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_DMG_UP, 6, 0);
    Test_Eq("Combat_ApplyDamage Rev Up doubles the ratio: 7", Test_Hit(_rev, EnemyCreate(ENEMY_SLIME), Test_Wpn(6, STAT_ATK, 0)).dmg, 7);
    var _guarded = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_GUARD, 6, 0);
    Test_Eq("Combat_ApplyDamage Guard blocks the hit (0)", Test_Hit(_k, _guarded, Test_Wpn(6, STAT_ATK, 0)).dmg, 0);
    Test_Eq("Combat_ApplyDamage Guard leaves HP untouched", _guarded.hp, _guarded.max_hp);
    Test_False("Combat_ApplyDamage Guard is consumed by the hit", Status_Has(_guarded, STATUS_GUARD));
    var _blessed = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_BLESSING, 4, 0);
    Test_Eq("Combat_ApplyDamage Blessing x0.8: 3", Test_Hit(_k, _blessed, Test_Wpn(6, STAT_ATK, 0)).dmg, 3);
    var _solid = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_SOLIDIFY, 2, 0);
    Test_Eq("Combat_ApplyDamage Solidify takes 75% less: power20 12 -> 3", Test_Hit(_k, _solid, Test_Wpn(20, STAT_ATK, 0)).dmg, 3);
    Test_False("Combat_ApplyDamage Solidify is consumed by the next hit", Status_Has(_solid, STATUS_SOLIDIFY));
    Test_Eq("Combat_ApplyDamage after Solidify the next hit is full: 12", Test_Hit(_k, _solid, Test_Wpn(20, STAT_ATK, 0)).dmg, 12);
    Test_Eq("boss max_hp (L10) == 194 (D111: 140 + 9 x 6)", _boss.max_hp, 194);
    Test_Eq("Combat_ApplyDamage crit x2: power12 vs boss(DEF24) == 8", Combat_ApplyDamage(_k, _boss, Test_Wpn(12, STAT_ATK, 0), 2).dmg, 8);   // 12 x 11 / (11 + 24) x 2 = 7.54
    Test_Eq("Combat_ApplyDamage boss hp 194 -> 186", _boss.hp, 186);
    var _tiny = EnemyCreate(ENEMY_SLIME);
    Test_Hit(_k, _tiny, Test_Wpn(100, STAT_ATK, 0));
    Test_Eq("Combat_ApplyDamage HP clamps at 0, never negative", _tiny.hp, 0);
    // D35: one difficulty. Whatever id is saved, the profile and the damage are the same; the only knob is the assist multiplier (default 1).
    var _prof_e = Difficulty_Profile(DIFFICULTY_EASY);
    var _prof_h = Difficulty_Profile(DIFFICULTY_HARD);
    Test_Eq("D35 profile: assist_damage_taken_mult is 1 on Easy", _prof_e.assist_damage_taken_mult, 1);
    Test_Eq("D35 profile: assist_damage_taken_mult is 1 on Hard", _prof_h.assist_damage_taken_mult, 1);
    Test_False("D35 profile: no enemy HP multiplier left", variable_struct_exists(_prof_h, "enemy_hp_mult"));
    Test_False("D35 profile: no damage multiplier left", variable_struct_exists(_prof_h, "player_damage_mult") || variable_struct_exists(_prof_h, "enemy_damage_mult"));
    Test_False("D35 profile: no dead stat multipliers left", variable_struct_exists(_prof_h, "player_stat_mult") || variable_struct_exists(_prof_h, "enemy_stat_mult"));
    Test_Hero(CLASS_KNIGHT, DIFFICULTY_HARD);
    Test_Eq("D35: Hard deals the same damage as Normal (4)", Test_Hit(CharacterCreate_Player(CLASS_KNIGHT), EnemyCreate(ENEMY_SLIME), Test_Wpn(6, STAT_ATK, 0)).dmg, 4);
    Test_Eq("D35: Hard enemy damage equals Normal (boss power9 vs knight: 6)", Test_Hit(EnemyCreate(ENEMY_FINAL_BOSS), CharacterCreate_Player(CLASS_KNIGHT), Test_Wpn(9, STAT_ATK, 0)).dmg, 6);
    Test_Hero(CLASS_KNIGHT);
    global.assist_damage_taken_mult = 0.5;
    Test_Eq("D35 assist hook: x0.5 on damage taken: slime power20 vs knight 8 -> 4", Test_Hit(EnemyCreate(ENEMY_SLIME), CharacterCreate_Player(CLASS_KNIGHT), Test_Wpn(20, STAT_ATK, 0)).dmg, 4);
    Test_Eq("D35 assist hook: does not weaken the player's own hits", Test_Hit(CharacterCreate_Player(CLASS_KNIGHT), EnemyCreate(ENEMY_SLIME), Test_Wpn(6, STAT_ATK, 0)).dmg, 4);
    global.assist_damage_taken_mult = 1;
    Test_Eq("D35 assist hook back to 1: slime power20 vs knight 8", Test_Hit(EnemyCreate(ENEMY_SLIME), CharacterCreate_Player(CLASS_KNIGHT), Test_Wpn(20, STAT_ATK, 0)).dmg, 8);
    // Crit has no base chance and no LUCK (spec section 4): only a crit_bonus from statuses.
    var _plain = CharacterCreate_Player(CLASS_KNIGHT);
    var _any_crit = false;
    for (var _ci = 0; _ci < 300; _ci++) if (Combat_CritCheck(_plain, 0)) _any_crit = true;
    Test_False("Crit: 300 rolls with no bonus never crit (no base chance)", _any_crit);
    var _aimed = Status_Add(CharacterCreate_Player(CLASS_ARCHER), STATUS_CRIT_UP, 3, 0);
    Test_Eq("Crit: Take Aim adds a 25 crit bonus", Status_GetSum(_aimed, "crit_bonus"), 25);
    var _crits = 0;
    for (var _cj = 0; _cj < 400; _cj++) if (Combat_CritCheck(_aimed, Status_GetSum(_aimed, "crit_bonus"))) _crits++;
    Test_True("Crit: Take Aim crits roughly 1 in 4 (400 rolls: 60..140)", _crits >= 60 && _crits <= 140);
    // STAT-04 / D6 / D80: nobody misses. Every damaging player skill, 20 casts against every enemy: always a hit with damage; every enemy skill against a plain player too.
    var _never_missed = true;
    var _always_dmg = true;
    var _zero_at = "";
    var _foes = [ENEMY_SLIME, ENEMY_DIREWOLF, ENEMY_GHOSTSWORD, ENEMY_SPIDER, ENEMY_MADWHISP, ENEMY_SNAKE, ENEMY_KILLER_PLANT, ENEMY_STRANGER, ENEMY_MINI_BOSS, ENEMY_FINAL_BOSS];
    for (var _si = 0; _si < array_length(_attacks); _si++) {
        for (var _fi = 0; _fi < array_length(_foes); _fi++) {
            for (var _rep = 0; _rep < 20; _rep++) {
                var _caster = CharacterCreate_Player(SkillDB_Get(_attacks[_si]).class_list[0]);
                _caster.mp = 99;
                var _r = Skill_Use(_caster, EnemyCreate(_foes[_fi]), _attacks[_si]);
                if (!_r.hit) _never_missed = false;
                if (_r.dmg <= 0) { _always_dmg = false; if (_zero_at == "") _zero_at = SkillDB_Get(_attacks[_si]).name + " vs enemy " + string(_foes[_fi]) + " dmg=" + string(_r.dmg) + " ok=" + string(_r.ok); }
            }
        }
    }
    Test_True("STAT-04 player damage skills never miss (8 skills x 10 enemies x 20 casts)", _never_missed);
    Test_True("STAT-04 and every one of those hits deals damage (first zero: " + _zero_at + ")", _always_dmg);
    var _enemy_missed = false;
    for (var _ei = 0; _ei < array_length(_foes); _ei++) {
        var _cfg = EnemyDB_Get(_foes[_ei]);
        for (var _ek = 0; _ek < array_length(_cfg.skills); _ek++) {
            var _sk = SkillDB_Get(_cfg.skills[_ek]);
            if (_sk.effect != "damage") continue;
            for (var _er = 0; _er < 10; _er++) {
                var _target = CharacterCreate_Player(CLASS_KNIGHT);
                if (!Skill_Use(EnemyCreate(_foes[_ei]), _target, _cfg.skills[_ek]).hit) _enemy_missed = true;
            }
        }
    }
    Test_False("D80 enemy damage skills never miss a player without Evasion", _enemy_missed);
}

// D55 / I-052 / I-060: every player skill animation plays in at most 0.75 s (45 game frames at 60 fps; with the 0.3 s hold that is under the 66-frame
// action limit); its VISIBLE part (sprite bounding box x scale) is at least as big as its target's longest side, at most 1.5 x that, and never over 64 world px
// (the screen is 160 x 144), whatever enemy it hits. Limits are the owner's numbers written out here, not read from the macros.
function Test_Suite_Fx() {
    var _ids = Skill_PlayerFxIds();
    Test_Eq("Fx: 14 player skills have an animation", array_length(_ids), 14);
    var _targets = [16, 32, 48, 64, 80];   // a small enemy, slime-sized (also the player's reference size), the mini boss, the final boss, one bigger than the cap
    for (var _i = 0; _i < array_length(_ids); _i++) {
        var _s = SkillDB_Get(_ids[_i]);
        var _frames = FX_PlaybackFrames(_s.fx_sprite, Skill_FxSpeed(_s, true));
        Test_True("D55 " + _s.name + " animation <= 45 frames (got " + string(_frames) + ")", _frames <= 45);
        var _side = FX_ContentSide(_s.fx_sprite);
        Test_True("I-060 " + _s.name + " has a visible box (" + string(_side) + " px)", _side > 0 && _side <= 48);
        for (var _t = 0; _t < array_length(_targets); _t++) {
            var _tp = _targets[_t];
            var _drawn = _side * FX_ScaleFor(_s.fx_sprite, _tp);
            var _lo = min(_tp, 64);
            var _hi = min(_tp * 1.5, 64);
            Test_True("I-060 " + _s.name + " vs " + string(_tp) + " px target: visible effect " + string(_drawn) + " px >= the target (min " + string(_lo) + ")", _drawn >= _lo - 0.01);
            Test_True("I-060 " + _s.name + " vs " + string(_tp) + " px target: visible effect " + string(_drawn) + " px <= 1.5 x target and <= 64 (max " + string(_hi) + ")", _drawn <= _hi + 0.01);
        }
    }
    Test_True("I-060 Ice Spear on a 32 px slime is drawn 48 px (1.5 x) of visible effect", abs(FX_ContentSide(ice_spear_effect) * FX_ScaleFor(ice_spear_effect, 32) - 48) < 0.01);
    Test_True("I-060 an effect on a 64 px target is drawn 64 px", abs(FX_ContentSide(ice_spear_effect) * FX_ScaleFor(ice_spear_effect, 64) - 64) < 0.01);
    Test_True("I-060 an effect on an 80 px target is capped at 64 px", abs(FX_ContentSide(ice_spear_effect) * FX_ScaleFor(ice_spear_effect, 80) - 64) < 0.01);
    Test_Eq("D55 hold after an action is 300 ms", Combat_ActionHoldMs(), 300);   // F2b-1: was "18 frames" (Combat_SecToFrames); the same 0.3 s on a ms clock
    // The pure helpers themselves: a 48 px sprite at 8 fps, 12 frames... uses the real sprites: ice_spear_effect has 12 frames at 8 fps.
    Test_Eq("Fx: ice spear at image_speed 1 plays 12 frames in 90 game frames", FX_PlaybackFrames(ice_spear_effect, 1), 90);
    Test_Eq("Fx: ice spear at image_speed 2 plays in 45 game frames", FX_PlaybackFrames(ice_spear_effect, 2), 45);
    Test_True("Fx: SpeedForMaxFrames never slows an effect down", FX_SpeedForMaxFrames(ice_spear_effect, 5, 42) == 5);
    Test_True("Fx: SpeedForMaxFrames raises a slow effect to fit", FX_PlaybackFrames(ice_spear_effect, FX_SpeedForMaxFrames(ice_spear_effect, 0.1, 42)) <= 42);
}

// D108 F2b-1: the battle message hold, the sprite and camera shakes and the HUD hurt flash run on a ms clock. Expected values are the OLD 60 fps frame
// counts and rhythms written out by hand (60 frames = 1000 ms, 18 frames = 300 ms, the shake sign pattern + - - + + - - +, the flash on/off blocks,
// the hurt flash "mod 4" rhythm), not read from the macros.
function Test_HoldSteps(_start_ms, _step_ms) {
    var _t = _start_ms;
    var _n = 0;
    while (Combat_HoldActive(_t) && _n < 100000) {
        _t = Combat_HoldStep(_t, _step_ms);
        _n++;
    }
    return _n;
}

// The frames of an enemy sprite shake the way the battle controller runs them: Step advances the clock once, then Draw reads the offset _reads times.
function Test_SpriteShakeFrames(_inst, _frames, _step_ms, _reads) {
    var _out = { x: [], flash: [], stable: true };
    for (var _f = 0; _f < _frames; _f++) {
        if (_f > 0) SpriteShake_Step(_inst, _step_ms);
        var _first = SpriteShake_Offset(_inst);
        for (var _r = 1; _r < _reads; _r++) {
            var _again = SpriteShake_Offset(_inst);
            if (_again.x != _first.x || _again.y != _first.y || _again.flash != _first.flash) _out.stable = false;
        }
        array_push(_out.x, _first.x);
        array_push(_out.flash, _first.flash ? 1 : 0);
    }
    return _out;
}

function Test_CameraShakeFrames(_frames, _step_ms, _reads) {
    var _out = { x: [], stable: true };
    for (var _f = 0; _f < _frames; _f++) {
        if (_f > 0) CameraShake_Step(_step_ms);
        var _first = CameraShake_Offset();
        for (var _r = 1; _r < _reads; _r++) {
            var _again = CameraShake_Offset();
            if (_again.x != _first.x || _again.y != _first.y) _out.stable = false;
        }
        array_push(_out.x, _first.x);
    }
    return _out;
}

function Test_SameList(_got, _want, _tol) {
    if (array_length(_got) != array_length(_want)) return false;
    for (var _i = 0; _i < array_length(_want); _i++) { if (abs(_got[_i] - _want[_i]) > _tol) return false; }
    return true;
}

// The HUD hurt flash the way obj_ui_controller Step runs it: arm on a hit, count down once per frame, then Draw reads the sign.
function Test_HurtFlashSigns(_arm_ms, _frames, _step_ms) {
    var _signs = [];
    var _ms = max(0, _arm_ms);
    for (var _f = 0; _f < _frames; _f++) {
        if (_ms > 0) _ms = Hud_HurtFlashStep(_ms, _step_ms);
        array_push(_signs, Hud_HurtFlashSign(_ms));
    }
    return _signs;
}

function Test_Suite_BattleClock() {
    var _f60 = Presentation_StepMs(16667);   // 16.667 ms
    var _f30 = Presentation_StepMs(33333);   // 33.333 ms

    // --- the message hold: 60 frames (intro, kill, run-away) = 1000 ms; the D55 pause after an action, 18 frames = 300 ms
    Test_Eq("F2b-1 COMBAT_ACTION_DELAY_MS is 1000 ms (was 60 frames)", COMBAT_ACTION_DELAY_MS, 1000);
    Test_Eq("F2b-1 the hold after an action is 300 ms", Combat_ActionHoldMs(), 300);
    var _n = Test_HoldSteps(COMBAT_ACTION_DELAY_MS, _f60);
    Test_True("F2b-1 the 1000 ms hold lasts 60 +-1 steps at 16.667 ms (got " + string(_n) + ")", abs(_n - 60) <= 1);
    _n = Test_HoldSteps(Combat_ActionHoldMs(), _f60);
    Test_True("F2b-1 the 300 ms post-action pause lasts 18 +-1 steps at 16.667 ms (got " + string(_n) + ")", abs(_n - 18) <= 1);
    _n = Test_HoldSteps(COMBAT_ACTION_DELAY_MS, _f30);
    Test_True("F2b-1 the 1000 ms hold at 33.333 ms steps lasts 1000 ms +- 1 step (got " + string(_n) + " steps)", abs(_n * _f30 - 1000) <= _f30 + 0.01);
    _n = Test_HoldSteps(Combat_ActionHoldMs(), _f30);
    Test_True("F2b-1 the 300 ms pause at 33.333 ms steps lasts 300 ms +- 1 step (got " + string(_n) + " steps)", abs(_n * _f30 - 300) <= _f30 + 0.01);
    Test_Eq("F2b-1 a 200 ms hitch takes at most 50 ms off the hold", Combat_HoldStep(1000, Presentation_StepMs(200000)), 950);
    Test_False("F2b-1 a spent hold is not active", Combat_HoldActive(0));
    Test_True("F2b-1 the hold-forever value outlasts the old 9999 frames", COMBAT_HOLD_FOREVER_MS >= 9999 * 1000 / 60 - 1);
    var _bm = {};
    Battle_Message(_bm, "x", BSTATE_ENEMY_ACT);
    Test_Eq("F2b-1 Battle_Message holds 300 ms by default", _bm.wait_timer, 300);
    Battle_Message(_bm, "x", BSTATE_END_RUN, noone, COMBAT_ACTION_DELAY_MS);
    Test_Eq("F2b-1 Battle_Message holds the long delay it is given (ms)", _bm.wait_timer, 1000);

    // --- the shake lengths, in ms: 12 frames = 200 ms, 10 frames = 166.67 ms, 8 frames = 133.33 ms, the flash rate 3 frames = 50 ms
    Test_Eq("F2b-1 enemy shake is 200 ms", ENEMY_SHAKE_MS, 200);
    Test_Eq("F2b-1 enemy flash is 200 ms", ENEMY_FLASH_MS, 200);
    Test_Eq("F2b-1 enemy flash rate is 50 ms", ENEMY_FLASH_RATE_MS, 50);
    Test_Eq("F2b-1 player shake is 200 ms", PLAYER_SHAKE_MS, 200);
    Test_True("F2b-1 perfect camera shake is 10 frames (166.67 ms)", abs(QTE_SHAKE_PERFECT_MS - 10000 / 60) < 0.01);
    Test_True("F2b-1 good camera shake is 8 frames (133.33 ms)", abs(QTE_SHAKE_GOOD_MS - 8000 / 60) < 0.01);
    Test_True("F2b-1 hurt flash is 8 frames (133.33 ms)", abs(UI_HUD_HURT_FLASH_MS - 8000 / 60) < 0.01);

    // --- the enemy sprite shake: the old per-frame offset signs (+ - - + + - - + + - - then still) and flash (on 1, off 3, on 3, off 3, on 2)
    var _m = 0.3;
    var _want_x = [_m, -_m, -_m, _m, _m, -_m, -_m, _m, _m, -_m, -_m, 0, 0, 0];
    var _want_fl = [1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0];
    var _inst = instance_create_depth(0, 0, 0, obj_enemy_battle);
    SpriteShake_Start(_inst, SHAKE_DIR_H, _m, ENEMY_SHAKE_MS, ENEMY_FLASH_MS, ENEMY_FLASH_RATE_MS);
    var _r = Test_SpriteShakeFrames(_inst, 14, _f60, 1);
    Test_True("F2b-1 enemy shake offsets at 60 fps equal the old frame pattern (got " + string(_r.x) + ")", Test_SameList(_r.x, _want_x, 0.001));
    Test_True("F2b-1 enemy flash at 60 fps equals the old on/off pattern (got " + string(_r.flash) + ")", Test_SameList(_r.flash, _want_fl, 0));
    SpriteShake_Start(_inst, SHAKE_DIR_H, _m, ENEMY_SHAKE_MS, ENEMY_FLASH_MS, ENEMY_FLASH_RATE_MS);
    _r = Test_SpriteShakeFrames(_inst, 14, _f60, 3);
    Test_True("F2b-1 enemy shake advances once per frame however often it is read (3 reads per frame)", Test_SameList(_r.x, _want_x, 0.001) && Test_SameList(_r.flash, _want_fl, 0));
    Test_True("F2b-1 reading the shake offset again in the same frame gives the same answer", _r.stable);
    SpriteShake_Start(_inst, SHAKE_DIR_H, _m, ENEMY_SHAKE_MS, ENEMY_FLASH_MS, ENEMY_FLASH_RATE_MS);
    _r = Test_SpriteShakeFrames(_inst, 8, _f30, 2);
    var _moving = 0;
    for (var _i = 0; _i < array_length(_r.x); _i++) { if (_r.x[_i] != 0) _moving++; }
    Test_Eq("F2b-1 enemy shake at 33.333 ms steps moves for 6 frames (about 200 ms)", _moving, 6);
    SpriteShake_Start(_inst, SHAKE_DIR_H, _m, ENEMY_SHAKE_MS, ENEMY_FLASH_MS, ENEMY_FLASH_RATE_MS);
    SpriteShake_Step(_inst, Presentation_StepMs(200000));
    Test_Eq("F2b-1 a 200 ms hitch moves the shake on by 50 ms, not to its end", SpriteShake_Offset(_inst).x, _m);
    var _still = instance_create_depth(0, 0, 0, obj_enemy_battle);
    Test_Eq("F2b-1 a sprite that never shook reads zero", SpriteShake_Offset(_still).x, 0);
    instance_destroy(_still);
    instance_destroy(_inst);

    // --- the camera shake (QTE Perfect): 10 frames, the same + - - + + - - + + then still, advanced once per frame however often it is read
    var _gs = GameState_Get();
    var _had = variable_struct_exists(_gs, "cam_shake");
    var _old = _had ? _gs.cam_shake : undefined;
    var _cm = QTE_SHAKE_PERFECT_MAG;
    var _want_c = [_cm, -_cm, -_cm, _cm, _cm, -_cm, -_cm, _cm, _cm, 0, 0];
    CameraShake_Start(_cm, QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
    var _c = Test_CameraShakeFrames(11, _f60, 1);
    Test_True("F2b-1 camera shake offsets at 60 fps equal the old frame pattern (got " + string(_c.x) + ")", Test_SameList(_c.x, _want_c, 0.001));
    CameraShake_Start(_cm, QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
    _c = Test_CameraShakeFrames(11, _f60, 3);
    Test_True("F2b-1 camera shake advances once per frame however often it is read", Test_SameList(_c.x, _want_c, 0.001) && _c.stable);
    CameraShake_Start(_cm, QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
    CameraShake_Step(Presentation_StepMs(200000));
    Test_Eq("F2b-1 a 200 ms hitch moves the camera shake on by 50 ms, not to its end", CameraShake_Offset().x, _cm);
    if (_had) _gs.cam_shake = _old; else variable_struct_remove(_gs, "cam_shake");

    // --- the HUD hurt flash: 8 frames, drawn as - - + + - - + then off (the old "hurt mod 4" rhythm); a poison tick lasts twice as long
    var _sg = Test_HurtFlashSigns(UI_HUD_HURT_FLASH_MS, 10, _f60);
    Test_True("F2b-1 hurt flash at 60 fps equals the old mod-4 rhythm for 7 frames (got " + string(_sg) + ")", Test_SameList(_sg, [-1, -1, 1, 1, -1, -1, 1, 0, 0, 0], 0));
    _sg = Test_HurtFlashSigns(UI_HUD_HURT_FLASH_MS * 2, 18, _f60);
    Test_True("F2b-1 a tick's hurt flash at 60 fps lasts 15 frames of - - + + (got " + string(_sg) + ")", Test_SameList(_sg, [-1, -1, 1, 1, -1, -1, 1, 1, -1, -1, 1, 1, -1, -1, 1, 0, 0, 0], 0));
    _sg = Test_HurtFlashSigns(UI_HUD_HURT_FLASH_MS, 8, _f30);
    var _on = 0;
    for (var _k = 0; _k < array_length(_sg); _k++) { if (_sg[_k] != 0) _on++; }
    Test_Eq("F2b-1 hurt flash at 33.333 ms steps shows for 3 frames (about 100 ms)", _on, 3);
    Test_Eq("F2b-1 a 200 ms hitch takes at most 50 ms off the hurt flash", Hud_HurtFlashStep(UI_HUD_HURT_FLASH_MS * 2, Presentation_StepMs(200000)), UI_HUD_HURT_FLASH_MS * 2 - 50);
    Test_Eq("F2b-1 no hurt flash reads zero", Hud_HurtFlashSign(0), 0);
}

// ---- D108 F2b-2: dialogue typewriter, dialogue lock and icon blink, open-block, banner, hold-to-skip and the input locks on a ms clock ----------------
// Every helper drives the pure step function at one step size (16.667 ms = 60 fps, 33.333 ms = 30 fps, Presentation_StepMs(200000) = a hitch capped at 50 ms).
// Expected frame counts are the old 60 fps numbers (frame counters), expected times come from the design (60 chars/s, 1 s skip hold, 1 s banner).

function Test_UiTw(_cps, _hold_ms) {
    return { dialogue_state: UI_DIALOGUE_STATE_REVEALING, dialogue_visible_count: 0, dialogue_reveal_accum: 0, dialogue_chars_per_sec: _cps, dialogue_hold_ms: 0, dialogue_hold_duration_ms: _hold_ms };
}

// Characters shown after _steps steps of _step_ms on a very long line.
function Test_TwChars(_cps, _step_ms, _steps) {
    var _u = Test_UiTw(_cps, 150);
    for (var _i = 0; _i < _steps; _i++) Typewriter_Step(_u, 100000, _step_ms);
    return _u.dialogue_visible_count;
}

// Steps until a line of _len characters is READY (revealed and held), 100000 when it never is.
function Test_TwReadySteps(_len, _cps, _hold_ms, _step_ms) {
    var _u = Test_UiTw(_cps, _hold_ms);
    for (var _i = 1; _i <= 100000; _i++) {
        Typewriter_Step(_u, _len, _step_ms);
        if (_u.dialogue_state == UI_DIALOGUE_STATE_READY) return _i;
    }
    return 100000;
}

// Steps until the one-step dialogue lock is spent (100000 when it never is).
function Test_LockSpentSteps(_step_ms) {
    var _l = UI_DIALOGUE_REOPEN_LOCK_MS;
    for (var _i = 1; _i <= 100000; _i++) {
        _l = Dialogue_LockStep(_l, _step_ms);
        if (_l <= 0) return _i;
    }
    return 100000;
}

// Steps until the icon blink has flipped once (icon_frame reached 1).
function Test_IconFlipSteps(_step_ms) {
    var _ic = 0;
    for (var _i = 1; _i <= 100000; _i++) {
        _ic = Dialogue_IconStep(_ic, _step_ms);
        if (_ic >= 1) return _i;
    }
    return 100000;
}

// Frames an input lock refuses keys, counting from the frame it was made in (frame 100) with one tick per frame.
function Test_LockBlockedFrames(_ms, _min_frames, _step_ms) {
    var _lk = InputLock_New(_ms, _min_frames, 100);
    for (var _i = 0; _i < 100000; _i++) {
        if (!InputLock_Tick(_lk, 100 + _i, _step_ms)) return _i;
    }
    return 100000;
}

// Steps of a shown banner until it is over.
function Test_BannerSteps(_step_ms) {
    Banner_Show("Test");
    for (var _i = 1; _i <= 100000; _i++) {
        Banner_Step(_step_ms);
        if (!Banner_Active()) return _i;
    }
    return 100000;
}

// Steps of holding confirm (pressed on the first) until the skip fires, 100000 when it never does.
function Test_SkipFireSteps(_step_ms) {
    var _st = Skip_StateNew();
    for (var _i = 1; _i <= 100000; _i++) {
        _st = Skip_Step(_st, true, _i == 1, true, _step_ms);
        if (_st.fired) return _i;
    }
    return 100000;
}

// Steps from the press (the confirm is released at once) until the "hold to skip" hint is gone.
function Test_SkipHintSteps(_step_ms) {
    var _st = Skip_Step(Skip_StateNew(), true, true, false, _step_ms);
    for (var _i = 1; _i <= 100000; _i++) {
        _st = Skip_Step(_st, true, false, false, _step_ms);
        if (_st.hint <= 0) return _i;
    }
    return 100000;
}

function Test_Suite_UiClock() {
    var _f60 = Presentation_StepMs(16667);   // 16.667 ms
    var _f30 = Presentation_StepMs(33333);   // 33.333 ms
    var _hit = Presentation_StepMs(200000);  // a 200 ms hitch, capped at 50 ms

    // --- the typewriter reveals UI_DIALOGUE_CHARS_PER_SEC (60) characters per second, however often the game steps
    Test_Eq("F2b-2 the dialogue speed is 60 chars per second", UI_DIALOGUE_CHARS_PER_SEC, 60);
    Test_Eq("F2b-2 the typewriter shows one character per 60 fps step", Test_TwChars(60, _f60, 1), 1);
    var _n = Test_TwChars(60, _f60, 60);
    Test_True("F2b-2 60 chars/s: 60 +-1 characters after 1 s of 60 fps steps (got " + string(_n) + ")", abs(_n - 60) <= 1);
    _n = Test_TwChars(60, _f30, 30);
    Test_True("F2b-2 60 chars/s: 60 +-1 characters after 1 s of 30 fps steps (got " + string(_n) + ")", abs(_n - 60) <= 1);
    _n = Test_TwChars(30, _f60, 60);
    Test_True("F2b-2 30 chars/s: 30 +-1 characters after 1 s of 60 fps steps (got " + string(_n) + ")", abs(_n - 30) <= 1);
    _n = Test_TwChars(30, _f30, 30);
    Test_True("F2b-2 30 chars/s: 30 +-1 characters after 1 s of 30 fps steps (got " + string(_n) + ")", abs(_n - 30) <= 1);
    Test_Eq("F2b-2 a 200 ms hitch reveals only 50 ms of text (3 characters at 60 chars/s)", Test_TwChars(60, _hit, 1), 3);

    // --- the hold after the last character: a text-only cutscene line 0.75 s, a boxed line 0.15 s (45 and 9 frames at 60 fps)
    _n = Test_TwReadySteps(5, 60, 750, _f60);
    Test_True("F2b-2 a 5-character cutscene line is ready after 5 + 45 steps at 60 fps +-1 (got " + string(_n) + ")", abs(_n - 50) <= 1);
    _n = Test_TwReadySteps(5, 60, 150, _f60);
    Test_True("F2b-2 a 5-character boxed line is ready after 5 + 9 steps at 60 fps +-1 (got " + string(_n) + ")", abs(_n - 14) <= 1);
    _n = Test_TwReadySteps(6, 60, 750, _f30);
    Test_True("F2b-2 a cutscene line at 30 fps is ready after its reveal plus 750 ms, +- 1 step (got " + string(_n) + " steps)", abs(_n * _f30 - (100 + 750)) <= _f30 + 0.01);
    _n = Test_TwReadySteps(6, 60, 150, _f30);
    Test_True("F2b-2 a boxed line at 30 fps is ready after its reveal plus 150 ms, +- 1 step (got " + string(_n) + " steps)", abs(_n * _f30 - (100 + 150)) <= _f30 + 0.01);
    var _hu = Test_UiTw(60, 750);
    _hu.dialogue_state = UI_DIALOGUE_STATE_HOLDING;
    _hu.dialogue_visible_count = 5;
    _hu.dialogue_hold_ms = 750;
    Typewriter_Step(_hu, 5, _hit);
    Test_Eq("F2b-2 a 200 ms hitch takes at most 50 ms off the line hold", _hu.dialogue_hold_ms, 700);
    Test_Eq("F2b-2 a line that is still held is not ready", _hu.dialogue_state, UI_DIALOGUE_STATE_HOLDING);

    // --- the dialogue lock after a close (1 frame): lasts a real step at any rate, never zero steps
    Test_True("F2b-2 the dialogue reopen lock is 1 frame (16.67 ms)", abs(UI_DIALOGUE_REOPEN_LOCK_MS - 1000 / 60) < 0.01);
    Test_Eq("F2b-2 the dialogue lock lasts 1 step at 16.667 ms", Test_LockSpentSteps(_f60), 1);
    Test_Eq("F2b-2 the dialogue lock lasts 1 step at 33.333 ms", Test_LockSpentSteps(_f30), 1);
    Test_Eq("F2b-2 the dialogue lock lasts 1 step after a hitch", Test_LockSpentSteps(_hit), 1);
    Test_True("F2b-2 a step of zero ms does not clear the dialogue lock", Dialogue_LockStep(UI_DIALOGUE_REOPEN_LOCK_MS, 0) > 0);
    Test_Eq("F2b-2 a spent dialogue lock stays 0", Dialogue_LockStep(0, _f60), 0);

    // --- the "continue" arrow blink: UI_DIALOGUE_ARROW_FPS (2) per second, flips every 0.5 s (30 frames at 60 fps)
    _n = Test_IconFlipSteps(_f60);
    Test_True("F2b-2 the arrow flips after 30 +-1 steps at 60 fps (got " + string(_n) + ")", abs(_n - 30) <= 1);
    _n = Test_IconFlipSteps(_f30);
    Test_True("F2b-2 the arrow flips after 15 +-1 steps at 30 fps (got " + string(_n) + ")", abs(_n - 15) <= 1);
    var _ic = 0;
    for (var _i = 0; _i < 120; _i++) _ic = Dialogue_IconStep(_ic, _f60);
    Test_True("F2b-2 the arrow blink wraps at 2 s (120 steps at 60 fps is back at the start, got " + string(_ic) + ")", _ic < 0.1);
    Test_True("F2b-2 the arrow blink never leaves 0 to 2", Dialogue_IconStep(1.99, _hit) >= 0 && Dialogue_IconStep(1.99, _hit) < 2);
    Test_True("F2b-2 a 200 ms hitch moves the arrow on by 50 ms (0.1)", abs(Dialogue_IconStep(0, _hit) - 0.1) < 0.001);   // GML compares within its epsilon (1e-5), so the tolerance is wider than that

    // --- the input locks: the old frame counts at 60 fps, the same ms at 30 fps, and the open frame and the next one never answer a key
    var _locks = [
        { n: "cards screen",    ms: CARDS_UI_INPUT_DELAY_MS,   old: 10, minf: 2, want_ms: 10000 / 60 },
        { n: "shop",            ms: SHOP_UI_INPUT_DELAY_MS,    old: 10, minf: 2, want_ms: 10000 / 60 },
        { n: "tutorial",        ms: TUTORIAL_INPUT_DELAY_MS,   old: 12, minf: 2, want_ms: 200 },
        { n: "help page",       ms: HELP_UI_INPUT_DELAY_MS,    old: 4,  minf: 2, want_ms: 4000 / 60 },
        { n: "controls",        ms: CONTROLS_CAPTURE_DELAY_MS, old: 2,  minf: 2, want_ms: 2000 / 60 },
        { n: "tutorial closed", ms: TUTORIAL_CLOSED_GUARD_MS,  old: 2,  minf: 2, want_ms: 2000 / 60 }
    ];
    for (var _k = 0; _k < array_length(_locks); _k++) {
        var _lc = _locks[_k];
        Test_True("F2b-2 " + _lc.n + " lock is " + string(_lc.old) + " frames in ms", abs(_lc.ms - _lc.want_ms) < 0.01);
        _n = Test_LockBlockedFrames(_lc.ms, _lc.minf, _f60);
        Test_True("F2b-2 " + _lc.n + " lock refuses " + string(_lc.old) + " +-1 frames at 16.667 ms (got " + string(_n) + ")", abs(_n - _lc.old) <= 1);
        _n = Test_LockBlockedFrames(_lc.ms, _lc.minf, _f30);
        Test_True("F2b-2 " + _lc.n + " lock lasts its ms +- 1 step at 33.333 ms (got " + string(_n) + " frames)",
            _n * _f30 >= _lc.ms - _f30 - 0.01 && _n * _f30 <= max(_lc.ms, _lc.minf * _f30) + _f30 + 0.01);
        _n = Test_LockBlockedFrames(_lc.ms, _lc.minf, _hit);
        Test_True("F2b-2 " + _lc.n + " lock holds the open frame and the next one even after a hitch (got " + string(_n) + ")", _n >= 2);
        _n = Test_LockBlockedFrames(_lc.ms, _lc.minf, 5);
        Test_True("F2b-2 " + _lc.n + " lock does not end sooner at a very high frame rate (got " + string(_n) + ")", _n >= _lc.old);
    }
    // the dialogue open block: 2 frames after the open frame (the old "frame <= open + 2") = the open frame plus 2 = 50 ms; the open frame alone at least
    Test_True("F2b-2 the cutscene advance block is 3 frames (50 ms: the open frame and 2 after)", abs(UI_CUTSCENE_ADVANCE_BLOCK_MS - 3000 / 60) < 0.01);
    _n = Test_LockBlockedFrames(UI_CUTSCENE_ADVANCE_BLOCK_MS, 1, _f60);
    Test_Eq("F2b-2 the cutscene advance block refuses 3 frames at 16.667 ms", _n, 3);
    _n = Test_LockBlockedFrames(UI_CUTSCENE_ADVANCE_BLOCK_MS, 1, _f30);
    Test_True("F2b-2 the cutscene advance block refuses its 50 ms +- 1 step at 33.333 ms (got " + string(_n) + " frames)", _n * _f30 >= 50 - _f30 - 0.01 && _n * _f30 <= 50 + _f30 + 0.01);
    _n = Test_LockBlockedFrames(UI_CUTSCENE_ADVANCE_BLOCK_MS, 1, _hit);
    Test_True("F2b-2 the cutscene advance block refuses at least the open frame after a hitch (got " + string(_n) + ")", _n >= 1);
    Test_Eq("F2b-2 a box with no cutscene text blocks the open frame only", Test_LockBlockedFrames(0, 1, _f60), 1);
    // one tick per frame, however often it is asked; a lock nobody asked about for a while is spent when asked
    var _lk = InputLock_New(CARDS_UI_INPUT_DELAY_MS, 2, 200);
    InputLock_Tick(_lk, 200, _f60);
    InputLock_Tick(_lk, 200, _f60);
    InputLock_Tick(_lk, 201, _f60);
    InputLock_Tick(_lk, 201, _f60);
    Test_True("F2b-2 a lock steps once per frame however often it is read (1 frame = 16.7 ms off)", abs(_lk.ms - (CARDS_UI_INPUT_DELAY_MS - _f60)) < 0.01);
    _lk = InputLock_New(CARDS_UI_INPUT_DELAY_MS, 2, 300);
    Test_True("F2b-2 a lock first asked about 6 frames later still has 66.7 ms to go", InputLock_Tick(_lk, 306, _f60) && abs(_lk.ms - (CARDS_UI_INPUT_DELAY_MS - 6 * _f60)) < 0.01);
    Test_False("F2b-2 a lock first asked about 12 frames later is spent", InputLock_Tick(_lk, 312, _f60));
    Test_True("F2b-2 a spent lock reads as settled with no margin", InputLock_Settled(_lk, 0, 312, _f60));
    Test_False("F2b-2 a lock that has only just run out is not settled 4 frames later", InputLock_Settled(InputLock_New(CARDS_UI_INPUT_DELAY_MS, 2, 400), 4000 / 60, 410, _f60));
    Test_False("F2b-2 no lock (undefined) refuses nothing", InputLock_Active(undefined));

    // --- the boss name banner (D106): 1 s, 60 frames at 60 fps; the fade is a fifth at each end
    Test_Eq("F2b-2 the boss banner lasts 1000 ms", Banner_DurMs(), 1000);
    var _had_b = variable_global_exists("banner");
    var _old_b = _had_b ? global.banner : undefined;
    _n = Test_BannerSteps(_f60);
    Test_True("F2b-2 the banner lasts 60 +-1 steps at 16.667 ms (got " + string(_n) + ")", abs(_n - 60) <= 1);
    _n = Test_BannerSteps(_f30);
    Test_True("F2b-2 the banner lasts 1000 ms +- 1 step at 33.333 ms (got " + string(_n) + " steps)", abs(_n * _f30 - 1000) <= _f30 + 0.01);
    Banner_Show("Test");
    Banner_Step(_hit);
    Test_Eq("F2b-2 a 200 ms hitch moves the banner on by 50 ms", global.banner.t, 50);
    Test_True("F2b-2 the banner is still showing after the hitch", Banner_Active());
    global.banner = _old_b;
    var _bad = 0;
    for (var _f = 0; _f <= 60; _f++) {
        var _want = clamp(min(_f / 12, (60 - _f) / 12), 0, 1);   // the old per-frame alpha: a fifth (12 frames) in and out
        if (abs(Banner_Alpha(_f * 1000 / 60, Banner_DurMs()) - _want) > 0.001) _bad++;
    }
    Test_Eq("F2b-2 the banner alpha at 60 fps equals the old per-frame fade for all 61 frames", _bad, 0);

    // --- hold-to-skip (D48): confirm held for 1 s, at 60 and at 30 fps; the hint fills for 2.5 s after the press
    Test_Eq("F2b-2 the skip hold is 1000 ms", SKIP_HOLD_MS, 1000);
    Test_Eq("F2b-2 the skip hint stays 2500 ms (150 frames)", SKIP_HINT_MS, 2500);
    _n = Test_SkipFireSteps(_f60);
    Test_True("F2b-2 hold-to-skip fires after 60 +-1 steps at 60 fps (got " + string(_n) + ")", abs(_n - 60) <= 1);
    Test_True("F2b-2 hold-to-skip needs about 1 s at 60 fps (got " + string(_n * _f60) + " ms)", _n * _f60 >= 983 && _n * _f60 <= 1020);
    _n = Test_SkipFireSteps(_f30);
    Test_True("F2b-2 hold-to-skip fires after 30 +-1 steps at 30 fps (got " + string(_n) + ")", abs(_n - 30) <= 1);
    Test_True("F2b-2 hold-to-skip needs about 1 s at 30 fps (got " + string(_n * _f30) + " ms)", _n * _f30 >= 966 && _n * _f30 <= 1034);
    var _sk = Skip_Step(Skip_StateNew(), true, true, true, _hit);
    Test_Eq("F2b-2 a 200 ms hitch adds 50 ms to the skip hold", _sk.held_ms, 50);
    Test_Eq("F2b-2 a 200 ms hitch cannot fire the skip on its own", _sk.fired, false);
    _n = Test_SkipHintSteps(_f60);
    Test_True("F2b-2 the skip hint fades after 150 +-1 steps at 60 fps (got " + string(_n) + ")", abs(_n - 150) <= 1);
    _n = Test_SkipHintSteps(_f30);
    Test_True("F2b-2 the skip hint fades after 75 +-1 steps at 30 fps (got " + string(_n) + ")", abs(_n - 75) <= 1);
    Test_True("F2b-2 the skip hint fade-out is 20 frames (333 ms)", abs(SKIP_HINT_FADE_MS - 20000 / 60) < 0.01);
}

// QTE part 1 (D5, D6, D20, D35, D56, D60, D61; QTE-01, 03, 07, 14). Expected values are the owner's decisions written out, not read from the macros:
// grade multipliers 1.30 / 1.10 / 1.00 / 0.75, a sliding bar judged in ms, zones widened by one assist multiplier, nothing the player does misses.
// The zone sits at 70% of the sweep (the design number this suite pins); half widths are +/- ms around it.
function Test_Suite_Qte() {
    var _p = { sweep_ms: 1000, perfect_half_width: 50, good_half_width: 100, ok_half_width: 200 };
    // cursor position from elapsed ms
    Test_Eq("Qte cursor at 0 ms == 0", Qte_CursorPos(0, _p), 0);
    Test_Eq("Qte cursor at 500 ms of 1000 == 0.5", Qte_CursorPos(500, _p), 0.5);
    Test_Eq("Qte cursor at the end == 1", Qte_CursorPos(1000, _p), 1);
    Test_Eq("Qte cursor past the end stays at 1", Qte_CursorPos(1500, _p), 1);
    Test_Eq("Qte cursor during the lead-in (negative ms) stays at 0", Qte_CursorPos(-100, _p), 0);
    Test_Eq("Qte zone centre == 700 ms", Qte_ZoneCentreMs(_p), 700);
    // the clock: microseconds from delta_time, a long frame cannot skip the bar (QTE-01, QTE-14)
    Test_Eq("Qte step of 16667 us == 16.667 ms", Qte_StepMs(16667), 16.667);
    Test_Eq("Qte step of a 200 ms hitch is capped at 50 ms", Qte_StepMs(200000), 50);
    // grade from the press position
    Test_Eq("Qte press on the centre == PERFECT", Qte_Grade(700, _p), "PERFECT");
    Test_Eq("Qte press 50 ms early == PERFECT (edge is inside)", Qte_Grade(650, _p), "PERFECT");
    Test_Eq("Qte press 50 ms late == PERFECT (edge is inside)", Qte_Grade(750, _p), "PERFECT");
    Test_Eq("Qte press 51 ms early == GOOD", Qte_Grade(649, _p), "GOOD");
    Test_Eq("Qte press 100 ms late == GOOD", Qte_Grade(800, _p), "GOOD");
    Test_Eq("Qte press 101 ms late == OK", Qte_Grade(801, _p), "OK");
    Test_Eq("Qte press 200 ms early == OK", Qte_Grade(500, _p), "OK");
    Test_Eq("Qte press 201 ms early == WEAK", Qte_Grade(499, _p), "WEAK");
    Test_Eq("Qte press at 0 ms == WEAK", Qte_Grade(0, _p), "WEAK");
    Test_Eq("Qte press as the cursor ends == WEAK", Qte_Grade(1000, _p), "WEAK");
    Test_Eq("Qte no press before the cursor ends == WEAK", Qte_Grade(QTE_NO_PRESS, _p), "WEAK");
    // assist: one multiplier widens every zone (D35)
    Test_Eq("Qte assist x1.5: 75 ms off is PERFECT", Qte_Grade(775, _p, 1.5), "PERFECT");
    Test_Eq("Qte assist x1.5: 76 ms off is GOOD", Qte_Grade(776, _p, 1.5), "GOOD");
    Test_Eq("Qte no assist: 75 ms off is GOOD", Qte_Grade(775, _p, 1), "GOOD");
    Test_Eq("Qte assist x2: 100 ms off is PERFECT", Qte_Grade(800, _p, 2), "PERFECT");
    Test_Eq("Qte assist x2: 200 ms off is GOOD", Qte_Grade(900, _p, 2), "GOOD");
    Test_Eq("Qte assist x2: 201 ms off is OK", Qte_Grade(901, _p, 2), "OK");
    Test_Eq("Qte assist x2: 400 ms off is OK (zone edge)", Qte_Grade(300, _p, 2), "OK");
    Test_Eq("Qte assist x2: 401 ms off is WEAK", Qte_Grade(299, _p, 2), "WEAK");
    // grade -> damage multiplier (D61) and order
    Test_Eq("Qte PERFECT multiplier 1.30", Qte_GradeMult("PERFECT"), 1.30);
    Test_Eq("Qte GOOD multiplier 1.10", Qte_GradeMult("GOOD"), 1.10);
    Test_Eq("Qte OK multiplier 1.00", Qte_GradeMult("OK"), 1.00);
    Test_Eq("Qte WEAK multiplier 0.75", Qte_GradeMult("WEAK"), 0.75);
    Test_True("Qte grades are ordered WEAK < OK < GOOD < PERFECT", Qte_GradeRank("PERFECT") > Qte_GradeRank("GOOD") && Qte_GradeRank("GOOD") > Qte_GradeRank("OK") && Qte_GradeRank("OK") > Qte_GradeRank("WEAK"));
    // early presses (the press that chose ATTACK, mashing) are dropped; a press up to 80 ms before the sweep starts is kept and judged at 0
    Test_Eq("Qte press 81 ms before the sweep is ignored", Qte_BufferPress(-81), QTE_NO_PRESS);
    Test_Eq("Qte press 80 ms before the sweep is buffered, judged at 0", Qte_BufferPress(-80), 0);
    Test_Eq("Qte press 30 ms before the sweep is judged at 0", Qte_BufferPress(-30), 0);
    Test_Eq("Qte press during the sweep keeps its time", Qte_BufferPress(612.5), 612.5);
    // per-weapon starting numbers (D60): daggers and bows fast + wide, heavy slow + narrow, the rest medium
    var _def = Qte_BarParams("default");
    var _bow = Qte_BarParams("bow");
    var _dag = Qte_BarParams("dagger");
    var _hvy = Qte_BarParams("heavy");
    Test_True("Qte bow sweeps faster than the default", _bow.sweep_ms < _def.sweep_ms);
    Test_True("Qte bow's perfect zone is wider on the bar than the default's", _bow.perfect_half_width / _bow.sweep_ms > _def.perfect_half_width / _def.sweep_ms);
    Test_True("Qte dagger sweeps faster than the default", _dag.sweep_ms < _def.sweep_ms);
    Test_True("Qte dagger's perfect zone is wider on the bar than the default's", _dag.perfect_half_width / _dag.sweep_ms > _def.perfect_half_width / _def.sweep_ms);
    Test_True("Qte heavy sweeps slower than the default", _hvy.sweep_ms > _def.sweep_ms);
    Test_True("Qte heavy's perfect zone is narrower on the bar than the default's", _hvy.perfect_half_width / _hvy.sweep_ms < _def.perfect_half_width / _def.sweep_ms);
    Test_Eq("Qte an unknown weapon kind uses the default numbers", Qte_BarParams("no_such_kind").sweep_ms, _def.sweep_ms);
    var _kinds = ["default", "bow", "dagger", "staff", "heavy"];
    for (var _ki = 0; _ki < array_length(_kinds); _ki++) {
        var _q = Qte_BarParams(_kinds[_ki]);
        Test_True("Qte " + _kinds[_ki] + ": zones nest (perfect < good < ok)", _q.perfect_half_width > 0 && _q.perfect_half_width < _q.good_half_width && _q.good_half_width < _q.ok_half_width);
        Test_True("Qte " + _kinds[_ki] + ": the OK zone ends before the cursor does, so a late press can be WEAK", Qte_ZoneCentreMs(_q) + _q.ok_half_width < _q.sweep_ms);
        Test_True("Qte " + _kinds[_ki] + ": the perfect zone is at least 100 ms wide in total (human timing scatter)", _q.perfect_half_width * 2 >= 100);
    }
    Test_Eq("Qte Wooden Sword uses the default bar", Qte_BarParams(Qte_WeaponKind(ItemDB_Get(1))).sweep_ms, _def.sweep_ms);
    Test_Eq("Qte Wooden Bow is a bow", Qte_WeaponKind(ItemDB_Get(4)), "bow");
    Test_Eq("Qte Wooden Staff is a staff", Qte_WeaponKind(ItemDB_Get(7)), "staff");
    Test_Eq("Qte an item with no kind falls back to default", Qte_WeaponKind({ power: 1 }), "default");
    Test_Eq("Qte no assist setting means a multiplier of 1", Qte_AssistMult(), 1);
    // feedback: each grade has its own word and its own existing sound (QTE-12, GAP-01)
    SFX_EnsureManager();
    var _grades = ["PERFECT", "GOOD", "OK", "WEAK"];
    var _words = ["PERFECT", "GOOD", "OK", "WEAK"];
    var _seen = [];
    for (var _gi = 0; _gi < 4; _gi++) {
        var _sk = Qte_GradeSfxKey(_grades[_gi]);
        Test_True("Qte " + _grades[_gi] + " sound " + _sk + " is a real sound asset", ds_map_exists(global.sfx_db, _sk) && SFX_IsValidSoundAsset(global.sfx_db[? _sk]));
        Test_False("Qte " + _grades[_gi] + " sound differs from the other grades", array_contains(_seen, global.sfx_db[? _sk]));
        array_push(_seen, global.sfx_db[? _sk]);
        Test_Eq("Qte " + _grades[_gi] + " word", Qte_GradeLabel(_grades[_gi]), _words[_gi]);
    }

    // never miss (D5, D6, D20): the grade scales damage and never takes it to 0. Knight ATK11 power6 vs slime DEF7 deals 4 at grade OK.
    var _k = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL);
    var _w = Test_Wpn(6, STAT_ATK, 0);
    var _mults = [1.30, 1.10, 1.00, 0.75];
    var _want = [5, 5, 4, 3];   // round-half-up(4 x 1.30) 5; 4 x 1.10 rounds to 4 but a multiplier other than 1.00 moves it by at least 1, so 5; OK 4; 4 x 0.75 = 3
    for (var _g = 0; _g < 4; _g++) {
        var _d = Combat_ApplyDamage(_k, EnemyCreate(ENEMY_SLIME), _w, 1, 1, { is_skill: false, grade_mult: _mults[_g] }).dmg;
        Test_Eq("Combat_ApplyDamage grade x" + string(_mults[_g]) + ": 4 -> " + string(_want[_g]), _d, _want[_g]);
    }
    var _weak_boss = Combat_ApplyDamage(EnemyCreate(ENEMY_SLIME), EnemyCreate(ENEMY_FINAL_BOSS), Test_Wpn(1, STAT_ATK, 0), 1, 1, { is_skill: false, grade_mult: 0.75 }).dmg;
    Test_Eq("Combat_ApplyDamage a WEAK hit of 1 stays 1, never 0 (D20)", _weak_boss, 1);
    var _guarded = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_GUARD, 6, 0);
    Test_Eq("Combat_ApplyDamage Guard still blocks a PERFECT hit", Combat_ApplyDamage(_k, _guarded, _w, 1, 1, { is_skill: false, grade_mult: 1.30 }).dmg, 0);

    // player skills no longer roll to hit: a boss that would force a dodge (Evasion) is hit every time
    var _hit_all = true;
    var _dmg_all = true;
    for (var _i = 0; _i < 60; _i++) {
        var _user = CharacterCreate_Player(CLASS_KNIGHT);
        _user.mp = 99;
        var _foe = Status_Add(EnemyCreate(ENEMY_FINAL_BOSS), STATUS_EVASION, 3, 0);
        var _res = Skill_Use(_user, _foe, SKILL_HORIZ_SLASH);
        if (!_res.hit) _hit_all = false;
        if (_res.dmg <= 0) _dmg_all = false;
    }
    Test_True("Skill_Use: a player skill hits an Evasion boss 60 times in 60 (D6)", _hit_all);
    Test_True("Skill_Use: every one of those hits does damage", _dmg_all);
    var _user2 = CharacterCreate_Player(CLASS_KNIGHT);
    _user2.mp = 99;
    var _res_ok = Skill_Use(_user2, EnemyCreate(ENEMY_SLIME), SKILL_HORIZ_SLASH);
    var _user3 = CharacterCreate_Player(CLASS_KNIGHT);
    _user3.mp = 99;
    var _res_perfect = Skill_Use(_user3, EnemyCreate(ENEMY_SLIME), SKILL_HORIZ_SLASH, 1.30);
    Test_True("Skill_Use: a PERFECT multiplier never lowers the damage of grade OK", _res_perfect.dmg >= _res_ok.dmg);
    // D80: an Evasion player still dodges the next enemy attack (the only avoidance left)
    var _evader = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_EVASION, 3, 0);
    Test_True("Combat_TryDodge: an Evasion player dodges an enemy", Combat_TryDodge(EnemyCreate(ENEMY_SLIME), _evader).dodged);
}

// QTE part 2a: the arrow sequence for a player skill (D57, D58, D61). Pure grader first: scripted presses with times in ms.
// Sequence [UP, LEFT, DOWN] is 3 long: the bar drains over 3400 ms, Perfect needs it finished by 1500 ms with no mistake,
// a wrong press costs 250 ms of that bar. Expected values come from the packet spec (D58), not from the code.
function Test_Suite_QteArrows() {
    var _seq = [UP, LEFT, DOWN];
    var _par = Qte_SeqParams(3);
    Test_Eq("QteArrows 3 arrows: the bar lasts 3400 ms", _par.limit_ms, 3400);
    Test_Eq("QteArrows 3 arrows: Perfect needs <= 1500 ms", _par.fast_ms, 1500);
    Test_Eq("QteArrows a wrong press costs 250 ms", _par.penalty_ms, 250);
    Test_Eq("QteArrows 4 arrows: the bar lasts 4200 ms", Qte_SeqParams(4).limit_ms, 4200);
    Test_Eq("QteArrows 4 arrows: Perfect needs <= 1950 ms", Qte_SeqParams(4).fast_ms, 1950);
    Test_Eq("QteArrows 5 arrows: the bar lasts 5000 ms", Qte_SeqParams(5).limit_ms, 5000);
    Test_Eq("QteArrows 5 arrows: Perfect needs <= 2400 ms", Qte_SeqParams(5).fast_ms, 2400);
    Test_Eq("QteArrows assist x2 doubles the bar", Qte_SeqParams(3, 2).limit_ms, 6800);
    Test_Eq("QteArrows assist x2 doubles the Perfect time", Qte_SeqParams(3, 2).fast_ms, 3000);
    Test_Eq("QteArrows assist x2 leaves the wrong-press cost alone", Qte_SeqParams(3, 2).penalty_ms, 250);

    // no mistakes: fast = PERFECT, slower = GOOD
    var _r = Qte_SeqRun(_seq, [{ t: 300, dir: UP }, { t: 600, dir: LEFT }, { t: 900, dir: DOWN }]);
    Test_Eq("QteArrows clean and fast == PERFECT", _r.key, "PERFECT");
    Test_Eq("QteArrows clean and fast: 0 mistakes", _r.mistakes, 0);
    Test_Eq("QteArrows clean and fast: finished at 900 ms", _r.finish_ms, 900);
    Test_False("QteArrows clean and fast: not a timeout", _r.timed_out);
    _r = Qte_SeqRun(_seq, [{ t: 500, dir: UP }, { t: 1000, dir: LEFT }, { t: 1500, dir: DOWN }]);
    Test_Eq("QteArrows finished exactly on the fast limit (1500 ms) == PERFECT", _r.key, "PERFECT");
    _r = Qte_SeqRun(_seq, [{ t: 500, dir: UP }, { t: 1000, dir: LEFT }, { t: 1501, dir: DOWN }]);
    Test_Eq("QteArrows finished 1 ms after the fast limit == GOOD", _r.key, "GOOD");
    _r = Qte_SeqRun(_seq, [{ t: 1000, dir: UP }, { t: 2000, dir: LEFT }, { t: 3399, dir: DOWN }]);
    Test_Eq("QteArrows clean but slow, finished 1 ms before the bar ran out == GOOD", _r.key, "GOOD");
    // the bar empties at 3400 ms: an arrow at that moment is too late
    _r = Qte_SeqRun(_seq, [{ t: 1000, dir: UP }, { t: 2000, dir: LEFT }, { t: 3400, dir: DOWN }]);
    Test_Eq("QteArrows the last arrow as the bar empties == WEAK", _r.key, "WEAK");
    Test_True("QteArrows the last arrow as the bar empties is a timeout", _r.timed_out);

    // mistakes: a wrong press does not advance the sequence and costs 250 ms
    _r = Qte_SeqRun(_seq, [{ t: 300, dir: UP }, { t: 500, dir: RIGHT }, { t: 700, dir: LEFT }, { t: 900, dir: DOWN }]);
    Test_Eq("QteArrows one wrong press, then finished == OK", _r.key, "OK");
    Test_Eq("QteArrows one wrong press: 1 mistake", _r.mistakes, 1);
    Test_Eq("QteArrows one wrong press: finished at 900 + 250 ms of the bar", _r.finish_ms, 1150);
    _r = Qte_SeqRun(_seq, [{ t: 300, dir: DOWN }, { t: 600, dir: UP }, { t: 900, dir: LEFT }, { t: 1200, dir: DOWN }]);
    Test_Eq("QteArrows a wrong first arrow does not advance: UP is still wanted", _r.mistakes, 1);
    Test_Eq("QteArrows ... and finishing afterwards is still OK", _r.key, "OK");
    _r = Qte_SeqRun(_seq, [{ t: 100, dir: UP }, { t: 200, dir: RIGHT }, { t: 300, dir: RIGHT }, { t: 400, dir: LEFT }, { t: 500, dir: DOWN }]);
    Test_Eq("QteArrows two wrong presses == WEAK", _r.key, "WEAK");
    Test_Eq("QteArrows two wrong presses: 2 mistakes", _r.mistakes, 2);
    Test_False("QteArrows two wrong presses is not a timeout (the skill is still done)", _r.timed_out);
    // the 250 ms is taken from the bar: 1 mistake at real 3200 ms is 3450 of 3400
    _r = Qte_SeqRun(_seq, [{ t: 100, dir: UP }, { t: 200, dir: RIGHT }, { t: 3000, dir: LEFT }, { t: 3100, dir: DOWN }]);
    Test_Eq("QteArrows one mistake, done at real 3100 ms (3350 of 3400) == OK", _r.key, "OK");
    _r = Qte_SeqRun(_seq, [{ t: 100, dir: UP }, { t: 200, dir: RIGHT }, { t: 3000, dir: LEFT }, { t: 3200, dir: DOWN }]);
    Test_Eq("QteArrows one mistake, done at real 3200 ms (3450 of 3400) == WEAK", _r.key, "WEAK");
    Test_True("QteArrows ... because the bar ran out", _r.timed_out);
    // a mistake that spends the whole bar ends it at once
    _r = Qte_SeqRun(_seq, [{ t: 100, dir: UP }, { t: 3200, dir: RIGHT }, { t: 3300, dir: LEFT }]);
    Test_Eq("QteArrows a wrong press that empties the bar ends it", _r.key, "WEAK");
    Test_True("QteArrows ... as a timeout", _r.timed_out);
    // no input at all
    _r = Qte_SeqRun(_seq, []);
    Test_Eq("QteArrows no presses == WEAK", _r.key, "WEAK");
    Test_True("QteArrows no presses is a timeout", _r.timed_out);
    Test_Eq("QteArrows no presses: no arrow done", _r.idx, 0);
    // presses after the end are ignored
    _r = Qte_SeqRun(_seq, [{ t: 300, dir: UP }, { t: 600, dir: LEFT }, { t: 900, dir: DOWN }, { t: 1000, dir: RIGHT }, { t: 1100, dir: RIGHT }]);
    Test_Eq("QteArrows presses after the sequence is done change nothing", _r.key, "PERFECT");
    Test_Eq("QteArrows presses after the sequence is done add no mistakes", _r.mistakes, 0);

    // the live bar: Qte_SeqLeft is 1 at the start and falls with time and mistakes
    var _st = Qte_SeqNew(_seq);
    Test_Eq("QteArrows the bar starts full", Qte_SeqLeft(_st), 1);
    Qte_SeqTick(_st, 1700);
    Test_Eq("QteArrows the bar is half full at 1700 of 3400 ms", Qte_SeqLeft(_st), 0.5);
    Qte_SeqPress(_st, DOWN, 1700);   // wrong: UP is wanted
    Test_Eq("QteArrows a wrong press takes 250 ms off the bar at once", Qte_SeqLeft(_st), (3400 - 1950) / 3400);
    Test_Eq("QteArrows a wrong press reports 'wrong'", _st.last, "wrong");
    Qte_SeqPress(_st, UP, 1800);
    Test_Eq("QteArrows a right press reports 'ok'", _st.last, "ok");
    Test_Eq("QteArrows a right press advances one arrow", _st.idx, 1);
    Qte_SeqTick(_st, 99999);
    Test_Eq("QteArrows the bar ends at 0 with time out", Qte_SeqLeft(_st), 0);
    Test_True("QteArrows time out is done", _st.done);
    Test_Eq("QteArrows time out == WEAK", _st.key, "WEAK");
    // assist x2: the bar and the Perfect time are twice as long
    _r = Qte_SeqRun(_seq, [{ t: 1000, dir: UP }, { t: 2000, dir: LEFT }, { t: 3000, dir: DOWN }], 2);
    Test_Eq("QteArrows assist x2: finished at 3000 ms is PERFECT (limit 3000)", _r.key, "PERFECT");
    _r = Qte_SeqRun(_seq, [{ t: 1000, dir: UP }, { t: 2000, dir: LEFT }, { t: 3001, dir: DOWN }], 2);
    Test_Eq("QteArrows assist x2: finished at 3001 ms is GOOD", _r.key, "GOOD");

    // grade -> multiplier is the same table the bar uses (D61): 1.30 / 1.10 / 1.00 / 0.75 for skills too
    Test_Eq("QteArrows PERFECT multiplier", Qte_GradeMult(Qte_SeqRun(_seq, [{ t: 300, dir: UP }, { t: 600, dir: LEFT }, { t: 900, dir: DOWN }]).key), 1.30);
    Test_Eq("QteArrows no-press multiplier", Qte_GradeMult(Qte_SeqRun(_seq, []).key), 0.75);

    // the fixed sequence of every player skill (D57): length by cost (3 cheap, 4 mid, 5 strongest), valid, memorable (all different)
    SkillDB_Init();
    var _ids = ds_map_keys_to_array(global.skill_db);
    array_sort(_ids, true);
    var _seen = [];
    var _n = 0;
    for (var _i = 0; _i < array_length(_ids); _i++) {
        var _sk = global.skill_db[? _ids[_i]];
        if (!is_struct(_sk) || !is_array(_sk.class_list) || array_length(_sk.class_list) == 0) continue;
        _n++;
        var _q = Qte_SkillSequence(_ids[_i]);
        var _want = (_sk.mp_cost <= 3) ? 3 : ((_sk.mp_cost == 4) ? 4 : 5);
        Test_Eq("QteArrows " + _sk.name + " (" + string(_sk.mp_cost) + " MP) has " + string(_want) + " arrows", array_length(_q), _want);
        var _ok = true;
        var _txt = "";
        for (var _j = 0; _j < array_length(_q); _j++) {
            if (_q[_j] < 0 || _q[_j] > 3) _ok = false;
            _txt += string(_q[_j]);
        }
        Test_True("QteArrows " + _sk.name + " uses only the four arrows", _ok);
        Test_False("QteArrows " + _sk.name + " has its own sequence", array_contains(_seen, _txt));
        array_push(_seen, _txt);
    }
    Test_Eq("QteArrows all 14 player skills are covered", _n, 14);
    Test_Eq("QteArrows an unknown skill still gets a 3-arrow sequence", array_length(Qte_SkillSequence(999)), 3);
    Test_Eq("QteArrows the sequence is the same every time (fixed per skill, D57)", string(Qte_SkillSequence(SKILL_FIREBALL)), string(Qte_SkillSequence(SKILL_FIREBALL)));

    // rounding after a grade multiplier: round half up, at least 1 apart from OK, and a hit that deals damage never drops below 1 (D20)
    Test_Eq("QteArrows scale 4 x 1.30 == 5", Qte_ScaleAmount(4, 1.30, 1), 5);
    Test_Eq("QteArrows scale 4 x 1.10 == 5 (4.4 rounds to 4, but Good is at least 1 above OK)", Qte_ScaleAmount(4, 1.10, 1), 5);
    Test_Eq("QteArrows scale 4 x 1.00 == 4", Qte_ScaleAmount(4, 1.00, 1), 4);
    Test_Eq("QteArrows scale 4 x 0.75 == 3", Qte_ScaleAmount(4, 0.75, 1), 3);
    Test_Eq("QteArrows scale 1 x 1.30 == 2 (Perfect is visible at 1)", Qte_ScaleAmount(1, 1.30, 1), 2);
    Test_Eq("QteArrows scale 1 x 0.75 == 1 (never 0 on a hit, D20)", Qte_ScaleAmount(1, 0.75, 1), 1);
    Test_Eq("QteArrows scale 2 x 0.75 == 1 (1.5 rounds up to 2, but Weak is at least 1 below OK)", Qte_ScaleAmount(2, 0.75, 1), 1);
    Test_Eq("QteArrows scale 6 x 0.75 == 5 (4.5 rounds half up to 5)", Qte_ScaleAmount(6, 0.75, 1), 5);
    Test_Eq("QteArrows scale 10 x 1.30 == 13", Qte_ScaleAmount(10, 1.30, 1), 13);
    Test_Eq("QteArrows scale 10 x 1.10 == 11", Qte_ScaleAmount(10, 1.10, 1), 11);
    Test_Eq("QteArrows scale 10 x 0.75 == 8 (7.5 rounds half up)", Qte_ScaleAmount(10, 0.75, 1), 8);
    Test_Eq("QteArrows scale 0 stays 0", Qte_ScaleAmount(0, 1.30, 1), 0);
    var _distinct = true;
    for (var _b = 3; _b <= 40; _b++) {   // Perfect is above OK and Weak below it at every size from 3 up
        if (Qte_ScaleAmount(_b, 1.30, 1) <= _b) _distinct = false;
        if (Qte_ScaleAmount(_b, 0.75, 1) >= _b) _distinct = false;
    }
    Test_True("QteArrows Perfect beats OK and Weak trails it at every base from 3 to 40", _distinct);
    // the damage path uses it: Knight ATK11 power6 vs Slime DEF7 deals 4 at OK, 5 at Perfect AND at Good
    var _k = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL);
    var _w = Test_Wpn(6, STAT_ATK, 0);
    var _ok_d = Combat_ApplyDamage(_k, EnemyCreate(ENEMY_SLIME), _w, 1, 1, { is_skill: true, grade_mult: 1.00 }).dmg;
    var _pf_d = Combat_ApplyDamage(_k, EnemyCreate(ENEMY_SLIME), _w, 1, 1, { is_skill: true, grade_mult: 1.30 }).dmg;
    var _go_d = Combat_ApplyDamage(_k, EnemyCreate(ENEMY_SLIME), _w, 1, 1, { is_skill: true, grade_mult: 1.10 }).dmg;
    Test_True("QteArrows a skill hit at Perfect is above the same hit at OK", _pf_d > _ok_d);
    Test_True("QteArrows a skill hit at Good is above the same hit at OK", _go_d > _ok_d);
    Test_Eq("QteArrows a hit of 1 at Perfect through Combat_ApplyDamage == 2", Combat_ApplyDamage(EnemyCreate(ENEMY_SLIME), EnemyCreate(ENEMY_FINAL_BOSS), Test_Wpn(1, STAT_ATK, 0), 1, 1, { is_skill: false, grade_mult: 1.30 }).dmg, 2);
}

// QTE part 2b: the defence sliding bar (D59, D60, D21). Grades come from the same Qte_Grade as the attack bar; these checks cover what is new:
// per-attack bar numbers, how much each grade blocks, and that a status can only get shorter.
function Test_Suite_QteDefence() {
    var _big = [SKILL_VINE_TRAP, SKILL_GHOST_CUT, SKILL_RAMMING, SKILL_PALE_HYMN];   // the telegraphed heavy moves: the only ones with a defence bar (D7, I-066)
    var _def = Qte_BarParams("default");
    for (var _i = 0; _i < array_length(_big); _i++) {
        var _sk = SkillDB_Get(_big[_i]);
        var _q = Qte_DefenceParams(_big[_i]);
        Test_True("QteDefence " + _sk.name + " is flagged as a big attack", _sk.uses_defensive_qte);
        Test_True("QteDefence " + _sk.name + ": zones nest (perfect < good < ok)", _q.perfect_half_width > 0 && _q.perfect_half_width < _q.good_half_width && _q.good_half_width < _q.ok_half_width);
        Test_True("QteDefence " + _sk.name + ": the OK zone ends before the cursor does", Qte_ZoneCentreMs(_q) + _q.ok_half_width < _q.sweep_ms);
        Test_True("QteDefence " + _sk.name + ": the perfect zone is at least 100 ms wide", _q.perfect_half_width * 2 >= 100);
        Test_Eq("QteDefence " + _sk.name + " has the same bar every time (D60: learnable)", string(Qte_DefenceParams(_big[_i])), string(_q));
    }
    // heavy hitters are slower and narrower, quick ones faster (D60)
    var _ram = Qte_DefenceParams(SKILL_RAMMING);
    var _cut = Qte_DefenceParams(SKILL_GHOST_CUT);
    var _bit = Qte_DefenceParams(SKILL_PALE_HYMN);
    Test_True("QteDefence Ramming (mini boss) sweeps slower than every other big attack", _ram.sweep_ms > Qte_DefenceParams(SKILL_VINE_TRAP).sweep_ms && _ram.sweep_ms > _cut.sweep_ms && _ram.sweep_ms > _bit.sweep_ms);
    Test_True("QteDefence Ramming's perfect zone is the narrowest on the bar", _ram.perfect_half_width / _ram.sweep_ms < _cut.perfect_half_width / _cut.sweep_ms && _ram.perfect_half_width / _ram.sweep_ms < _bit.perfect_half_width / _bit.sweep_ms);
    Test_True("QteDefence Ghost Cut sweeps faster than the attack default", _cut.sweep_ms < _def.sweep_ms);
    Test_Eq("QteDefence an attack with no row uses the default bar", Qte_DefenceParams(SKILL_SOLIDIFY).sweep_ms, _def.sweep_ms);
    // only damaging enemy hits on the player that are flagged big get the bar
    var _spider = EnemyCreate(ENEMY_SPIDER);
    var _player = CharacterCreate_Player(CLASS_KNIGHT);
    var _fangs = SkillDB_Get(SKILL_VINE_TRAP);
    Test_True("QteDefence a landed Vine Trap is defended", Battle_EnemySkillCanBeDefended(_fangs, { ok: true, hit: true, dmg: 3 }, _player));
    Test_False("QteDefence a Vine Trap that missed is not", Battle_EnemySkillCanBeDefended(_fangs, { ok: true, hit: false, dmg: 0 }, _player));
    Test_False("QteDefence a hit for 0 is not", Battle_EnemySkillCanBeDefended(_fangs, { ok: true, hit: true, dmg: 0 }, _player));
    Test_False("QteDefence Solidify (no damage) is not", Battle_EnemySkillCanBeDefended(SkillDB_Get(SKILL_SOLIDIFY), { ok: true, hit: true, dmg: 3 }, _player));
    Test_False("QteDefence Bloodthirsty (not a big attack) is not", Battle_EnemySkillCanBeDefended(SkillDB_Get(SKILL_BLOODTHIRSTY), { ok: true, hit: true, dmg: 3 }, _player));
    Test_False("QteDefence a hit on the enemy is not", Battle_EnemySkillCanBeDefended(_fangs, { ok: true, hit: true, dmg: 3 }, _spider));

    // how much each grade lets through (starting numbers, tuned by playtest)
    Test_Eq("QteDefence Perfect takes 25%", Qte_DefenceMult("PERFECT"), 0.25);
    Test_Eq("QteDefence Good takes 50%", Qte_DefenceMult("GOOD"), 0.50);
    Test_Eq("QteDefence OK takes 75%", Qte_DefenceMult("OK"), 0.75);
    Test_Eq("QteDefence Weak takes 100%", Qte_DefenceMult("WEAK"), 1.00);
    Test_Eq("QteDefence a hit of 8: Perfect takes 2", Qte_DefenceDamage(8, "PERFECT"), 2);
    Test_Eq("QteDefence a hit of 8: Good takes 4", Qte_DefenceDamage(8, "GOOD"), 4);
    Test_Eq("QteDefence a hit of 8: OK takes 6", Qte_DefenceDamage(8, "OK"), 6);
    Test_Eq("QteDefence a hit of 8: Weak takes 8", Qte_DefenceDamage(8, "WEAK"), 8);
    Test_Eq("QteDefence a hit of 10: Perfect takes 3 (2.5 rounds half up)", Qte_DefenceDamage(10, "PERFECT"), 3);
    Test_Eq("QteDefence a hit of 3: Perfect takes 1", Qte_DefenceDamage(3, "PERFECT"), 1);
    Test_Eq("QteDefence a hit of 3: OK takes 2 (never the full 3)", Qte_DefenceDamage(3, "OK"), 2);
    Test_Eq("QteDefence a hit of 3: Weak takes 3", Qte_DefenceDamage(3, "WEAK"), 3);
    Test_Eq("QteDefence a hit of 1: Perfect blocks it", Qte_DefenceDamage(1, "PERFECT"), 0);
    Test_Eq("QteDefence a hit of 0 stays 0", Qte_DefenceDamage(0, "PERFECT"), 0);
    var _ordered = true;
    for (var _b = 2; _b <= 40; _b++) {   // a better block never lets more through, and anything above Weak is below the full hit
        if (!(Qte_DefenceDamage(_b, "PERFECT") <= Qte_DefenceDamage(_b, "GOOD") && Qte_DefenceDamage(_b, "GOOD") <= Qte_DefenceDamage(_b, "OK") && Qte_DefenceDamage(_b, "OK") < Qte_DefenceDamage(_b, "WEAK"))) _ordered = false;
        if (Qte_DefenceDamage(_b, "WEAK") != _b) _ordered = false;
    }
    Test_True("QteDefence blocks are ordered Perfect <= Good <= OK < Weak == the full hit, for hits of 2 to 40", _ordered);

    // D21: a status can only get shorter. Perfect resists it; Weak leaves it as it was applied, never longer (the old rule made it up to 4x).
    Test_Eq("QteDefence Perfect resists a 4-turn status (0 turns)", Qte_DefenceStatusTurns("PERFECT", 4), 0);
    Test_Eq("QteDefence Good halves a 4-turn status", Qte_DefenceStatusTurns("GOOD", 4), 2);
    Test_Eq("QteDefence OK takes a 4-turn status to 3", Qte_DefenceStatusTurns("OK", 4), 3);
    Test_Eq("QteDefence Weak leaves a 4-turn status at 4", Qte_DefenceStatusTurns("WEAK", 4), 4);
    Test_Eq("QteDefence a 1-turn status stays 1 at Good (never 0 unless resisted)", Qte_DefenceStatusTurns("GOOD", 1), 1);
    Test_Eq("QteDefence a 2-turn status at OK: 1.5 rounds half up to 2", Qte_DefenceStatusTurns("OK", 2), 2);
    var _never_longer = true;
    var _keys = ["PERFECT", "GOOD", "OK", "WEAK"];
    for (var _t = 0; _t <= 12; _t++) {
        for (var _g = 0; _g < 4; _g++) {
            if (Qte_DefenceStatusTurns(_keys[_g], _t) > _t) _never_longer = false;
            if (_t >= 1 && _keys[_g] != "PERFECT" && Qte_DefenceStatusTurns(_keys[_g], _t) < 1) _never_longer = false;
        }
    }
    Test_True("QteDefence no grade ever makes a status longer, and only Perfect removes it (turns 0 to 12)", _never_longer);

    // the same rule on a real character: Poison with 4 stacks added by the hit (a Poison has stacks, not turns: spec section 10)
    var _specs = [STATUS_POISON];
    for (var _g2 = 0; _g2 < 4; _g2++) {
        var _p = CharacterCreate_Player(CLASS_KNIGHT);
        var _before = Battle_StatusSnapshot(_p);
        _p = Status_Add(_p, STATUS_POISON, 0, 1, 4);
        var _pack = Battle_DefenceAdjustStatuses(_p, _specs, _before, _keys[_g2]);
        var _after = Status_Stacks(_pack.player, STATUS_POISON);
        var _want_t = [0, 2, 3, 4][_g2];
        Test_Eq("QteDefence " + _keys[_g2] + ": a hit adding 4 Poison stacks leaves " + string(_want_t), _after, _want_t);
        if (_g2 == 0) Test_False("QteDefence Perfect: the character is not poisoned at all", Status_Has(_pack.player, STATUS_POISON));
        if (_g2 == 0) Test_True("QteDefence Perfect: the message names what was resisted", string_pos(StatusDB_Get(STATUS_POISON).name, _pack.resist_msg) > 0);
    }
    // a Poison the player already had keeps its stacks: Perfect puts it back, a lesser grade only cuts what the hit added (D21: never more than the hit gave)
    var _p2 = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_POISON, 0, 1, 3);
    var _before2 = Battle_StatusSnapshot(_p2);
    _p2 = Status_Add(_p2, STATUS_POISON, 0, 1, 3);   // the hit added 3 more: 6
    var _pack2 = Battle_DefenceAdjustStatuses(_p2, _specs, _before2, "PERFECT");
    Test_Eq("QteDefence Perfect puts a poison hit back to the 3 stacks it had", Status_Stacks(_pack2.player, STATUS_POISON), 3);
    var _p3 = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_POISON, 0, 1, 3);
    var _before3 = Battle_StatusSnapshot(_p3);
    _p3 = Status_Add(_p3, STATUS_POISON, 0, 1, 3);
    var _pack3 = Battle_DefenceAdjustStatuses(_p3, _specs, _before3, "WEAK");
    Test_Eq("QteDefence Weak leaves the 6 stacks the hit made", Status_Stacks(_pack3.player, STATUS_POISON), 6);
    var _p3b = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_POISON, 0, 1, 3);
    var _before3b = Battle_StatusSnapshot(_p3b);
    _p3b = Status_Add(_p3b, STATUS_POISON, 0, 1, 3);
    var _pack3b = Battle_DefenceAdjustStatuses(_p3b, _specs, _before3b, "GOOD");
    Test_Eq("QteDefence Good halves what the hit added (3 -> 2): 3 + 2 = 5 stacks", Status_Stacks(_pack3b.player, STATUS_POISON), 5);
    Test_Eq("QteDefence the poison turns follow the stacks", Battle_StatusCurrentTurns(_pack3b.player, STATUS_POISON), 5);
    // a status the hit did not touch is not touched here
    var _p4 = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_POISON, 0, 1, 3);
    var _before4 = Battle_StatusSnapshot(_p4);
    var _pack4 = Battle_DefenceAdjustStatuses(_p4, _specs, _before4, "OK");
    Test_Eq("QteDefence a status the hit did not change is left alone", Status_Stacks(_pack4.player, STATUS_POISON), 3);
    // Bleeding: the hit adds a stack and 3 turns. Perfect resists it, Good/OK cut the turns of a NEW bleed, Weak leaves it; it never gets longer or bigger
    var _bspec = [STATUS_BLEED];
    var _bw = [0, 2, 2, 3];   // PERFECT resisted, GOOD floor(3 x 0.5 + 0.5) = 2, OK floor(3 x 0.75 + 0.5) = 2, WEAK 3
    for (var _g3 = 0; _g3 < 4; _g3++) {
        var _pb = CharacterCreate_Player(CLASS_KNIGHT);
        var _bb = Battle_StatusSnapshot(_pb);
        _pb = Status_Add(_pb, STATUS_BLEED, 3, 1, 1);
        var _packb = Battle_DefenceAdjustStatuses(_pb, _bspec, _bb, _keys[_g3]);
        Test_Eq("QteDefence " + _keys[_g3] + ": a new 3-turn Bleeding ends at " + string(_bw[_g3]) + " turns", Battle_StatusCurrentTurns(_packb.player, STATUS_BLEED), _bw[_g3]);
        if (_g3 == 0) Test_False("QteDefence Perfect: no Bleeding at all", Status_Has(_packb.player, STATUS_BLEED));
        else Test_Eq("QteDefence " + _keys[_g3] + ": the stack stays", Status_Stacks(_packb.player, STATUS_BLEED), 1);
    }
    var _pb2 = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_BLEED, 1, 1, 2);   // 2 stacks, 1 turn left
    var _bb2 = Battle_StatusSnapshot(_pb2);
    _pb2 = Status_Add(_pb2, STATUS_BLEED, 3, 1, 1);   // the hit: 3 stacks, 3 turns
    var _packb2 = Battle_DefenceAdjustStatuses(_pb2, _bspec, _bb2, "PERFECT");
    Test_True("QteDefence Perfect puts a refreshed Bleeding back to 2 stacks, 1 turn", Status_Stacks(_packb2.player, STATUS_BLEED) == 2 && Battle_StatusCurrentTurns(_packb2.player, STATUS_BLEED) == 1);
    // Burning: 2 turns and a tick of 4. Good cuts the turns to 1, Perfect resists it and puts an older Burning back (turns and tick)
    var _pu = CharacterCreate_Player(CLASS_KNIGHT);
    var _bu = Battle_StatusSnapshot(_pu);
    _pu = Status_Add(_pu, STATUS_BURN, 2, 4);
    var _packu = Battle_DefenceAdjustStatuses(_pu, [STATUS_BURN], _bu, "GOOD");
    Test_Eq("QteDefence Good cuts a new 2-turn Burning to 1", Battle_StatusCurrentTurns(_packu.player, STATUS_BURN), 1);
    var _pu2 = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_BURN, 1, 3);
    var _bu2 = Battle_StatusSnapshot(_pu2);
    _pu2 = Status_Add(_pu2, STATUS_BURN, 2, 6);
    var _packu2 = Battle_DefenceAdjustStatuses(_pu2, [STATUS_BURN], _bu2, "PERFECT");
    Test_True("QteDefence Perfect puts the old Burning back (1 turn, tick 3)", Battle_StatusCurrentTurns(_packu2.player, STATUS_BURN) == 1 && Status_Find(_packu2.player, STATUS_BURN).power == 3);
    // no grade ever makes any DoT longer or bigger than the hit left it
    var _never_more = true;
    for (var _g4 = 0; _g4 < 4; _g4++) {
        var _pm = Status_Add(Status_Add(Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_POISON, 0, 1, 2), STATUS_BLEED, 3, 1, 1), STATUS_BURN, 2, 4);
        var _bm = Battle_StatusSnapshot(CharacterCreate_Player(CLASS_KNIGHT));
        var _hit_snapshot = Battle_StatusSnapshot(_pm);
        var _packm = Battle_DefenceAdjustStatuses(_pm, [STATUS_POISON, STATUS_BLEED, STATUS_BURN], _bm, _keys[_g4]);
        for (var _k4 = 0; _k4 < array_length(_hit_snapshot); _k4++) {
            var _e4 = Status_Find(_packm.player, _hit_snapshot[_k4].id);
            if (is_struct(_e4) && (_e4.turns > _hit_snapshot[_k4].turns || _e4.stacks > _hit_snapshot[_k4].stacks)) _never_more = false;
        }
    }
    Test_True("QteDefence no grade makes Poison, Bleeding or Burning longer or bigger than the hit left it (D21)", _never_more);
}

// Status rules (balance-data.md section 4 "Status effects"; combat-bugs.md section 1; R-005, R-022).
function Test_Suite_Status() {
    var _p = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL); // 10 HP, 10 MP at L1
    Test_Eq("player starts at full HP (10)", _p.hp, _p.max_hp);
    // R-005 / D78: a poisoned PLAYER loses his poison stacks each tick (3, then 2, then 1: 6 HP in all), the friend saw none.
    _p.max_hp = 30;
    _p.hp = 30;
    _p = Status_Add(_p, STATUS_POISON, 0, 0, 3);
    Test_True("Status_Has Poison after Status_Add", Status_Has(_p, STATUS_POISON));
    Test_True("Status_CanAct while poisoned", Status_CanAct(_p));
    var _hp0 = _p.hp;
    _p = Status_Tick(_p);
    Test_Eq("R-005 player poison tick costs the 3 stacks", _hp0 - _p.hp, 3);
    Test_Eq("poison stacks 3 -> 2 after one tick", _p.status[0].stacks, 2);
    _p = Status_Tick(_p);
    _p = Status_Tick(_p);
    Test_Eq("R-005 three ticks cost 3 + 2 + 1 = 6 HP in total", _hp0 - _p.hp, 6);
    Test_False("poison is removed when its stacks reach 0", Status_Has(_p, STATUS_POISON));
    // BUG-08: a poison tick on the player must be seen and heard (log line, sound, HUD flash), not just change the HP number.
    var _fp = Status_Add(Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL), STATUS_POISON, 0, 0, 3);
    var _fhp = _fp.hp;
    global.status_tick_last = undefined;
    _fp = Status_Tick(_fp);
    var _fb = variable_global_exists("status_tick_last") ? global.status_tick_last : undefined;
    Test_True("BUG-08 player poison tick raises feedback", is_struct(_fb));
    Test_True("BUG-08 tick log line names Poison and the HP lost", is_struct(_fb) && string_pos("Poison", _fb.line) > 0 && string_pos(string(_fhp - _fp.hp), _fb.line) > 0);
    Test_True("BUG-08 tick plays a sound", is_struct(_fb) && _fb.sfx != "");
    Test_True("BUG-08 tick flashes the HP bar", is_struct(_fb) && _fb.flash_ms > 0);   // F2b-1: was flash_frames
    global.status_tick_last = undefined;
    var _fe = Status_Tick(Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_POISON, 2, 0));
    Test_True("BUG-08 an enemy poison tick raises no player feedback", !(variable_global_exists("status_tick_last") && is_struct(global.status_tick_last)));
    global.status_tick_last = undefined;
    var _fm = Status_Tick(Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_MEDITATION, 2, 0));
    Test_True("BUG-08 a healing tick (Meditation) raises no damage feedback", !(variable_global_exists("status_tick_last") && is_struct(global.status_tick_last)));
    // HP and MP clamp to [0, max].
    var _low = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL);
    _low.hp = 1;
    _low = Status_Tick(Status_Add(_low, STATUS_BURN, 2, 4));
    Test_Eq("burn tick clamps HP at 0", _low.hp, 0);
    var _med = Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_MEDITATION, 3, 0);
    _med.mp = _med.max_mp - 1;
    _med = Status_Tick(_med);
    Test_Eq("meditation tick clamps MP at max", _med.mp, _med.max_mp);
    _med.mp = 0;
    _med = Status_Tick(_med);
    Test_True("meditation tick restores 2-4 MP", _med.mp >= 2 && _med.mp <= 4);
    // Non-stackable re-apply refreshes to the longer duration (Guard); the three DoTs no longer exclude each other (D78, StatusRules covers them).
    var _r = CharacterCreate_Player(CLASS_KNIGHT);
    _r = Status_Add(_r, STATUS_GUARD, 2, 0);
    _r = Status_Add(_r, STATUS_GUARD, 4, 0);
    _r = Status_Add(_r, STATUS_GUARD, 1, 0);
    Test_Eq("non-stackable status keeps one entry", array_length(_r.status), 1);
    Test_Eq("non-stackable refresh keeps the longest duration (4)", _r.status[0].turns, 4);
    _r = Status_Add(_r, STATUS_POISON, 0, 0, 2);
    _r = Status_Add(_r, STATUS_BURN, 2, 3);
    _r = Status_Add(_r, STATUS_BLEED, 3, 0);
    Test_True("D78 Poison, Burning and Bleeding on one character: all three stay", Status_Has(_r, STATUS_POISON) && Status_Has(_r, STATUS_BURN) && Status_Has(_r, STATUS_BLEED));
    // Stat mods (renamed, same size): Poison MAG-1, Bleeding SPD-2, Stun SPD-2, Sundered DEF-1. Burning has no flat mod: DEF x0.75.
    Test_Eq("Poison gives MAG-1", Status_ModStat(Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_POISON, 2, 0), STAT_MAG), -1);
    Test_Eq("Bleeding gives SPD-2", Status_ModStat(_r, STAT_SPD), -2);
    Test_Eq("Burning gives no flat ATK change", Status_ModStat(Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_BURN, 2, 3), STAT_ATK), 0);
    Test_Eq("Burning gives DEF x0.75", Status_StatMult(Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_BURN, 2, 3), STAT_DEF), 0.75);
    // Stun (D75, spec section 11): a push-back on the turn timeline, not a lost turn. The status is only the marker a skill leaves; the battle turns it into
    // a push-back at once (Battle_ConsumeStun) and nobody is ever unable to act. The old player-only immunity window and the 1-turn cap are gone (D19, S1).
    var _s = CharacterCreate_Player(CLASS_KNIGHT);
    Test_True("Status_CanAct on a clean character", Status_CanAct(_s));
    _s = Status_Add(_s, STATUS_STUN, 3, 0);
    Test_True("a Stun marker does not stop the owner acting (it is a push-back now)", Status_CanAct(_s));
    Test_Eq("player stun marker keeps its turns (no 1-turn cap any more)", _s.status[0].turns, 3);
    var _imm = CharacterCreate_Player(CLASS_KNIGHT);
    _imm.stun_immune_turns = 2;
    _imm = Status_Add(_imm, STATUS_STUN, 1, 0);
    Test_True("the old stun_immune_turns window is gone (Steadfast lives on the timeline)", Status_Has(_imm, STATUS_STUN));
    var _foe = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_STUN, 3, 0);
    Test_Eq("enemy stun marker (3)", _foe.status[0].turns, 3);
    Test_True("Guard does not stop the owner acting", Status_CanAct(Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_GUARD, 2, 0)));
}

// Status rules of packet B2 (combat-spec.md section 10; D21 D24 D59 D78 D79 D100). Expected numbers are worked out from the spec text.
function Test_Suite_StatusRules() {
    // ---- the formulas (combat-vectors.json holds the same cases) ----
    Test_Eq("vec burn_tick_1", Status_BurnTick(1), 2);
    Test_Eq("vec burn_tick_3", Status_BurnTick(3), 2);
    Test_Eq("vec burn_tick_5", Status_BurnTick(5), 2);
    Test_Eq("vec burn_tick_12", Status_BurnTick(12), 4);
    Test_Eq("vec burn_tick_13", Status_BurnTick(13), 4);
    Test_Eq("vec burn_tick_15", Status_BurnTick(15), 5);
    Test_Eq("vec burn_tick_19", Status_BurnTick(19), 6);
    Test_Eq("vec burn_tick_39", Status_BurnTick(39), 12);
    Test_Eq("vec burn_def_1", Status_BurnDef(1), 1);
    Test_Eq("vec burn_def_2", Status_BurnDef(2), 2);
    Test_Eq("vec burn_def_7", Status_BurnDef(7), 5);
    Test_Eq("vec burn_def_12", Status_BurnDef(12), 9);
    Test_Eq("vec burn_def_18", Status_BurnDef(18), 14);
    Test_Eq("vec poison_total_1", Status_PoisonTotal(1), 1);
    Test_Eq("vec poison_total_3", Status_PoisonTotal(3), 6);
    Test_Eq("vec poison_total_5", Status_PoisonTotal(5), 15);
    Test_Eq("vec poison_total_10", Status_PoisonTotal(10), 55);
    Test_Eq("vec poison_add_0_3", Status_PoisonAdd(0, 3), 3);
    Test_Eq("vec poison_add_3_3", Status_PoisonAdd(3, 3), 6);
    Test_Eq("vec poison_add_8_4", Status_PoisonAdd(8, 4), 10);
    Test_Eq("vec bleed_tick_1", Status_BleedTick(1), 2);
    Test_Eq("vec bleed_tick_2", Status_BleedTick(2), 4);
    Test_Eq("vec bleed_tick_3", Status_BleedTick(3), 6);
    Test_Eq("vec widen_55_1_5", Qte_WidenedHalfWidth(55, 1.5), 82.5);
    Test_Eq("vec widen_60_1_5", Qte_WidenedHalfWidth(60, 1.5), 90.0);
    Test_Eq("vec widen_50_1_0", Qte_WidenedHalfWidth(50, 1.0), 50.0);

    // ---- Poison stacks (D78) ----
    var _k = Test_Hero(CLASS_KNIGHT);
    _k.max_hp = 99;
    _k.hp = 99;
    _k = Status_Add(_k, STATUS_POISON, 0, 0, 3);
    Test_Eq("Poison: 3 stacks", Status_Stacks(_k, STATUS_POISON), 3);
    Test_Eq("Poison: the turns mirror the stacks", Battle_StatusCurrentTurns(_k, STATUS_POISON), 3);
    _k = Status_Add(_k, STATUS_POISON, 0, 0, 3);
    Test_Eq("Poison: reapply adds stacks (3 + 3)", Status_Stacks(_k, STATUS_POISON), 6);
    _k = Status_Add(_k, STATUS_POISON, 0, 0, 9);
    Test_Eq("Poison: stacks stop at 10", Status_Stacks(_k, STATUS_POISON), 10);
    var _hp_a = _k.hp;
    _k = Status_Tick(_k);
    Test_Eq("Poison: 10 stacks hurt for 10", _hp_a - _k.hp, 10);
    Test_Eq("Poison: then one stack fades (9)", Status_Stacks(_k, STATUS_POISON), 9);
    Test_Eq("Poison: only one entry", array_length(_k.status), 1);
    var _total = 0;
    var _guard = 0;
    var _hp_b = _k.hp;
    while (Status_Has(_k, STATUS_POISON) && _guard < 20) { _k = Status_Tick(_k); _guard++; }
    Test_Eq("Poison: from 9 stacks the rest costs 9+8+...+1 = 45", _hp_b - _k.hp, 45);
    var _pe = Status_Tick(Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_POISON, 0, 0, 3));
    Test_Eq("Poison: an ENEMY loses the stacks too (slime 9 -> 6)", _pe.hp, 6);

    // ---- Burning (D78) ----
    var _b = Status_Add(Test_Hero(CLASS_KNIGHT), STATUS_BURN, 2, 4);
    _b.max_hp = 99;
    _b.hp = 99;
    Test_Eq("Burning: the knight's DEF 12 is 9 while it burns", Combat_EffectiveStat(_b, STAT_DEF), 9);
    Test_Eq("Burning: the knight's ATK stays 11", Combat_EffectiveStat(_b, STAT_ATK), 11);
    _b = Status_Tick(_b);
    Test_Eq("Burning: a fixed tick of 4", _b.hp, 95);
    Test_Eq("Burning: 2 turns -> 1", Battle_StatusCurrentTurns(_b, STATUS_BURN), 1);
    _b = Status_Add(_b, STATUS_BURN, 2, 6);
    Test_Eq("Burning: reapply never stacks (one entry)", array_length(_b.status), 1);
    Test_Eq("Burning: reapply refreshes the turns to 2", Battle_StatusCurrentTurns(_b, STATUS_BURN), 2);
    Test_Eq("Burning: reapply takes the newer tick (6)", Status_Find(_b, STATUS_BURN).power, 6);
    _b = Status_Tick(Status_Tick(_b));
    Test_Eq("Burning: 6 + 6 more HP gone after its 2 turns", _b.hp, 83);
    Test_False("Burning ends after its 2 turns", Status_Has(_b, STATUS_BURN));
    Test_Eq("Burning over: DEF back to 12", Combat_EffectiveStat(_b, STAT_DEF), 12);
    // the tick comes from the CASTER's MAG when a skill applies it
    var _mage = CharacterCreate_Player(CLASS_MAGE);
    _mage.mp = 99;
    var _burn_target = EnemyCreate(ENEMY_SLIME);
    var _fb_chance = SkillDB_Get(SKILL_FIREBALL).status_chance;
    SkillDB_Get(SKILL_FIREBALL).status_chance = 1;
    Skill_Use(_mage, _burn_target, SKILL_FIREBALL);
    SkillDB_Get(SKILL_FIREBALL).status_chance = _fb_chance;
    Test_Eq("Fireball by a MAG 12 mage burns for 4 per tick (0.3 x 12 = 3.6 -> 4)", Status_Find(_burn_target, STATUS_BURN).power, 4);
    Test_Eq("Fireball's Burning lasts 2 turns", Battle_StatusCurrentTurns(_burn_target, STATUS_BURN), 2);

    // ---- Bleeding (D78): hurts only when its owner ACTS, 3 stacks, 3 turns ----
    var _d = Status_Add(Test_Hero(CLASS_KNIGHT), STATUS_BLEED, 3, 0);
    _d.max_hp = 99;
    _d.hp = 99;
    Test_Eq("Bleeding: 1 stack", Status_Stacks(_d, STATUS_BLEED), 1);
    _d = Status_Add(_d, STATUS_BLEED, 3, 0);
    _d = Status_Add(_d, STATUS_BLEED, 3, 0);
    _d = Status_Add(_d, STATUS_BLEED, 3, 0);
    Test_Eq("Bleeding: stacks stop at 3", Status_Stacks(_d, STATUS_BLEED), 3);
    Test_Eq("Bleeding: one entry", array_length(_d.status), 1);
    _d = Status_Tick(_d, false);
    Test_Eq("Bleeding: a stunned turn (no action) costs no HP", _d.hp, 99);
    Test_Eq("Bleeding: but the turn is counted (3 -> 2)", Battle_StatusCurrentTurns(_d, STATUS_BLEED), 2);
    _d = Status_ActionTick(_d);
    Test_Eq("Bleeding: an action costs 2 per stack = 6", _d.hp, 93);
    Test_Eq("Bleeding: the per-action tick does not count a turn", Battle_StatusCurrentTurns(_d, STATUS_BLEED), 2);
    _d = Status_Tick(_d);
    Test_Eq("Bleeding: a turn with an action costs 6 more", _d.hp, 87);
    Test_Eq("Bleeding: 2 -> 1 turn", Battle_StatusCurrentTurns(_d, STATUS_BLEED), 1);
    _d = Status_Add(_d, STATUS_BLEED, 3, 0);
    Test_Eq("Bleeding: reapply refreshes the turns to 3", Battle_StatusCurrentTurns(_d, STATUS_BLEED), 3);
    Test_Eq("Bleeding: and the stacks stay at the cap 3", Status_Stacks(_d, STATUS_BLEED), 3);
    _d = Status_Tick(Status_Tick(Status_Tick(_d)));
    Test_False("Bleeding ends after 3 turns", Status_Has(_d, STATUS_BLEED));

    // ---- all three at once ----
    var _all = Test_Hero(CLASS_KNIGHT);
    _all.max_hp = 99;
    _all.hp = 99;
    _all = Status_Add(Status_Add(Status_Add(_all, STATUS_POISON, 0, 0, 2), STATUS_BURN, 2, 3), STATUS_BLEED, 3, 0);
    Test_Eq("D78: Poison, Burning and Bleeding are three entries", array_length(_all.status), 3);
    _all = Status_Tick(_all);
    Test_Eq("D78: one turn costs poison 2 + burning 3 + bleeding 2 = 7", _all.hp, 92);
    Test_True("D78: afterwards poison 1 stack, burning 1 turn, bleeding 2 turns",
        Status_Stacks(_all, STATUS_POISON) == 1 && Battle_StatusCurrentTurns(_all, STATUS_BURN) == 1 && Battle_StatusCurrentTurns(_all, STATUS_BLEED) == 2);
    var _list = Status_DisplayList(_all);
    Test_Eq("HUD data: three rows", array_length(_list), 3);
    Test_True("HUD data: the poison row shows its stacks", _list[0].id == STATUS_POISON && _list[0].stacks == 1 && _list[0].label == "x1" && _list[0].tick == 1);
    Test_True("HUD data: the burning row shows the turns left", _list[1].id == STATUS_BURN && _list[1].label == "1t" && _list[1].turns == 1 && _list[1].tick == 3);
    Test_True("HUD data: the bleeding row shows stacks and turns left", _list[2].id == STATUS_BLEED && _list[2].label == "x1 2t" && _list[2].tick == 2);
    Test_True("HUD data: every row is a negative status with an icon sprite entry", _list[0].negative && _list[1].negative && _list[2].negative && variable_struct_exists(_list[0], "icon_sprite"));

    // ---- skills apply the new numbers ----
    var _sp = EnemyCreate(ENEMY_SPIDER);
    var _hero = Test_Hero(CLASS_KNIGHT);
    var _fangs_chance = SkillDB_Get(SKILL_POISON_FANGS).status_chance;
    SkillDB_Get(SKILL_POISON_FANGS).status_chance = 1;
    Skill_Use(_sp, _hero, SKILL_POISON_FANGS);
    SkillDB_Get(SKILL_POISON_FANGS).status_chance = _fangs_chance;
    Test_Eq("Poison Fangs puts 2 Poison stacks on the player", Status_Stacks(_hero, STATUS_POISON), 2);
    var _arch = CharacterCreate_Player(CLASS_ARCHER);
    _arch.mp = 99;
    var _arrow_foe = EnemyCreate(ENEMY_SLIME);
    var _pa_chance = SkillDB_Get(SKILL_POISON_ARROW).status_chance;
    SkillDB_Get(SKILL_POISON_ARROW).status_chance = 1;
    Skill_Use(_arch, _arrow_foe, SKILL_POISON_ARROW);
    Skill_Use(_arch, _arrow_foe, SKILL_POISON_ARROW);
    SkillDB_Get(SKILL_POISON_ARROW).status_chance = _pa_chance;
    Test_Eq("Poison Arrow twice: 3 + 3 = 6 stacks on the enemy", Status_Stacks(_arrow_foe, STATUS_POISON), 6);
    var _kn = CharacterCreate_Player(CLASS_KNIGHT);
    _kn.mp = 99;
    var _wound_foe = EnemyCreate(ENEMY_SLIME);
    var _wound_chance = SkillDB_Get(SKILL_WOUND).status_chance;
    SkillDB_Get(SKILL_WOUND).status_chance = 1;
    Skill_Use(_kn, _wound_foe, SKILL_WOUND);
    SkillDB_Get(SKILL_WOUND).status_chance = _wound_chance;
    Test_True("Wound puts 1 Bleeding stack for 3 turns", Status_Stacks(_wound_foe, STATUS_BLEED) == 1 && Battle_StatusCurrentTurns(_wound_foe, STATUS_BLEED) == 3);

    // ---- BUG-17: Curse respects its chance, applies the three DoTs together and the log tells the truth ----
    var _casts = 240;
    var _landed = [0, 0, 0];
    var _nothing = 0;
    var _all_three = 0;
    var _log_ok = true;
    var _sids = [STATUS_BURN, STATUS_POISON, STATUS_BLEED];
    for (var _c = 0; _c < _casts; _c++) {
        var _victim = CharacterCreate_Player(CLASS_KNIGHT);
        var _cr = Skill_Use(EnemyCreate(ENEMY_FINAL_BOSS), _victim, SKILL_CURSE);
        var _n = 0;
        for (var _si = 0; _si < 3; _si++) {
            var _has = Status_Has(_victim, _sids[_si]);
            if (_has) { _landed[_si]++; _n++; }
            var _named = (string_pos(StatusDB_Get(_sids[_si]).name, _cr.msg) > 0);
            if (_has != _named) _log_ok = false;
        }
        if (_n == 0) { _nothing++; if (string_pos("Applied", _cr.msg) > 0) _log_ok = false; }
        if (_n == 3) _all_three++;
        if (array_length(_victim.status) != _n) _log_ok = false;
    }
    Test_True("Curse: each status lands about half the time (240 casts: 85..155 each: " + string(_landed[0]) + "/" + string(_landed[1]) + "/" + string(_landed[2]) + ")",
        _landed[0] >= 85 && _landed[0] <= 155 && _landed[1] >= 85 && _landed[1] <= 155 && _landed[2] >= 85 && _landed[2] <= 155);
    Test_True("Curse: sometimes nothing lands, sometimes all three coexist", _nothing > 0 && _all_three > 0);
    Test_True("Curse: the log names exactly the statuses that landed, and a miss says nothing was applied", _log_ok);
    var _cv = CharacterCreate_Player(CLASS_KNIGHT);
    var _curse_chance = SkillDB_Get(SKILL_CURSE).status_chance;
    SkillDB_Get(SKILL_CURSE).status_chance = 1;
    var _cr1 = Skill_Use(EnemyCreate(ENEMY_FINAL_BOSS), _cv, SKILL_CURSE);
    SkillDB_Get(SKILL_CURSE).status_chance = _curse_chance;
    Test_True("Curse at 100%: Burning (tick 6 from MAG 19), Poison 2 stacks, Bleeding 1 stack all there",
        Status_Find(_cv, STATUS_BURN).power == 6 && Status_Stacks(_cv, STATUS_POISON) == 2 && Status_Stacks(_cv, STATUS_BLEED) == 1);
    Test_Eq("Curse at 100%: Burning 2 turns, Bleeding 3 turns", Battle_StatusCurrentTurns(_cv, STATUS_BURN) * 10 + Battle_StatusCurrentTurns(_cv, STATUS_BLEED), 23);

    // ---- Foresight (D79, D24) ----
    var _fm = CharacterCreate_Player(CLASS_MAGE);
    _fm.mp = 99;
    Skill_Use(_fm, _fm, SKILL_FORESIGHT);
    Test_Eq("Foresight: the skill gives exactly 3 turns (no x3 any more)", Battle_StatusCurrentTurns(_fm, STATUS_HIT_UP), 3);
    Test_True("Foresight reveals the next action", Status_HasFlag(_fm, "reveals_action"));
    Test_Eq("Foresight widens the Perfect zones x1.5", Qte_PerfectWiden(_fm), 1.5);
    Test_Eq("No Foresight: no widening", Qte_PerfectWiden(CharacterCreate_Player(CLASS_MAGE)), 1);
    Test_False("Foresight has no always_hit flag any more", variable_struct_exists(StatusDB_Get(STATUS_HIT_UP), "always_hit"));
    _fm = Status_ConsumeByField(_fm, "consume_on_attack");
    Test_True("Foresight is not used up by an attack", Status_Has(_fm, STATUS_HIT_UP));
    _fm = Status_Tick(_fm);
    Test_Eq("Foresight: the turn it is cast does not count (still 3)", Battle_StatusCurrentTurns(_fm, STATUS_HIT_UP), 3);
    _fm = Status_Tick(_fm);
    Test_Eq("Foresight: next turn 2 left", Battle_StatusCurrentTurns(_fm, STATUS_HIT_UP), 2);
    _fm = Status_Tick(Status_Tick(_fm));
    Test_False("Foresight is over after 3 of the player's turns", Status_Has(_fm, STATUS_HIT_UP));
    Test_Eq("Foresight over: Perfect zones back to normal", Qte_PerfectWiden(_fm), 1);
    // the bar: dagger Perfect half width 55 ms; 70 ms off the centre is Good, with Foresight (82.5 ms) it is Perfect; 90 ms stays Good
    var _bar = Qte_BarParams("dagger");
    var _centre = Qte_ZoneCentreMs(_bar);
    var _wbar = Qte_WidenPerfect(_bar, 1.5);
    Test_Eq("Foresight bar: 70 ms off the centre is Good without it", Qte_Grade(_centre + 70, _bar), QTE_GOOD);
    Test_Eq("Foresight bar: 70 ms off the centre is Perfect with it", Qte_Grade(_centre + 70, _wbar), QTE_PERFECT);
    Test_Eq("Foresight bar: 90 ms off the centre is still only Good", Qte_Grade(_centre + 90, _wbar), QTE_GOOD);
    Test_True("Foresight bar: only the Perfect zone changed", _wbar.sweep_ms == _bar.sweep_ms && _wbar.good_half_width == _bar.good_half_width && _wbar.ok_half_width == _bar.ok_half_width);
    // arrows: [UP, LEFT, DOWN] must be done in 1500 ms for Perfect (spec D58); x1.5 gives 2250 ms. A finish at 1800 ms is Good, with Foresight Perfect.
    var _seq = [UP, LEFT, DOWN];
    var _slow = [{ t: 600, dir: UP }, { t: 1200, dir: LEFT }, { t: 1800, dir: DOWN }];
    Test_Eq("Foresight arrows: 1800 ms is Good without it", Qte_SeqRun(_seq, _slow).key, QTE_GOOD);
    Test_Eq("Foresight arrows: 1800 ms is Perfect with it", Qte_SeqRun(_seq, _slow, 1, 1.5).key, QTE_PERFECT);
    Test_Eq("Foresight arrows: the time bar itself is not longer", Qte_SeqNew(_seq, 1, 1.5).limit_ms, Qte_SeqNew(_seq).limit_ms);
    Test_Eq("Foresight arrows: the Perfect window is x1.5", Qte_SeqNew(_seq, 1, 1.5).fast_ms, Qte_SeqNew(_seq).fast_ms * 1.5);
    // the preview (pure part): a visible plan shows the action, an invisible one gives nothing away
    var _pv = Battle_ActionPreviewOf({ skill_id: SKILL_RAMMING, announced: false }, true);
    Test_True("Preview: a heavy skill shows its name and that it is a big attack", _pv.visible && _pv.kind == "skill" && _pv.name == SkillDB_Get(SKILL_RAMMING).name && _pv.big);
    Test_Eq("Preview: the log line", _pv.text, "You foresee: " + SkillDB_Get(SKILL_RAMMING).name);
    var _pf = Battle_ActionPreviewOf({ skill_id: SKILL_POISON_FANGS, announced: false }, true);
    Test_True("Preview: a plain skill shows its name but is not a big attack (I-066)", _pf.visible && _pf.name == SkillDB_Get(SKILL_POISON_FANGS).name && !_pf.big);
    var _pa = Battle_ActionPreviewOf({ skill_id: -1, announced: false }, true);
    Test_True("Preview: a plain attack", _pa.visible && _pa.kind == "attack" && !_pa.big);
    var _ps = Battle_ActionPreviewOf({ skill_id: -1, announced: false }, true, true);
    Test_Eq("Preview: a stunned enemy does nothing", _ps.kind, "stunned");
    var _pn = Battle_ActionPreviewOf({ skill_id: SKILL_POISON_FANGS, announced: false }, false);
    Test_True("Preview: without Foresight nothing is given away", !_pn.visible && _pn.name == "" && _pn.skill_id == -1 && _pn.text == "");
    Test_False("Preview: no battle, no preview", Battle_EnemyNextActionPreview().visible);

    // ---- D100 / BUG-16: the text comes from the real numbers ----
    var _dp = Status_Describe(STATUS_POISON, { id: STATUS_POISON, turns: 3, power: 0, stacks: 3 });
    Test_True("Describe: Poison with 3 stacks says it hurts for 3", string_pos("3 HP", _dp.line) > 0 && _dp.tick == 3 && _dp.stacks == 3);
    var _db = Status_Describe(STATUS_BURN, { id: STATUS_BURN, turns: 2, power: 4, stacks: 1 });
    Test_True("Describe: Burning says 4 HP, 2 turns and its DEF change", string_pos("4 HP", _db.line) > 0 && string_pos("2 more turns", _db.line) > 0 && string_pos("DEF -25%", _db.line) > 0);
    var _dl = Status_Describe(STATUS_BLEED, { id: STATUS_BLEED, turns: 3, power: 0, stacks: 2 });
    Test_True("Describe: Bleeding with 2 stacks says 4 HP per action", string_pos("4 HP", _dl.line) > 0 && _dl.tick == 4);
    var _df = Status_Describe(STATUS_HIT_UP);
    Test_True("Describe: Foresight says 3 turns and +50%", string_pos("3 turns", _df.line) > 0 && string_pos("50%", _df.line) > 0);
    var _burn_cfg = StatusDB_Get(STATUS_BURN);
    var _old_dur = _burn_cfg.duration;
    _burn_cfg.duration = 5;
    Test_True("Describe: change the data and the text follows (Burning 5 turns)", string_pos("5 turns", Status_Describe(STATUS_BURN).line) > 0);
    _burn_cfg.duration = _old_dur;
    Test_True("Describe: every status has a sentence", Status_Description(STATUS_POISON) != "" && Status_Description(STATUS_BLEED) != "" && Status_Description(STATUS_STUN) != "" && Status_Description(STATUS_SOLIDIFY) != "");
    Test_True("Describe: Solidify says 75% less, from its data", string_pos("75%", Status_Description(STATUS_SOLIDIFY)) > 0);
    // tooltips cannot disagree with the game: every skill's status_turns is what is really applied; DoT skills match the status data
    var _sk_ok = true;
    var _sk_bad = "";
    var _skills = ds_map_keys_to_array(global.skill_db);
    for (var _ki = 0; _ki < array_length(_skills); _ki++) {
        var _sk = SkillDB_Get(_skills[_ki]);
        var _list_ids = Battle_SkillStatusIds(_sk);
        var _cl = variable_struct_exists(_sk, "class_list") ? _sk.class_list : [];
        var _user_is_p = (array_length(_cl) > 0);
        var _u = _user_is_p ? CharacterCreate_Player(_cl[0]) : EnemyCreate(ENEMY_SLIME);
        var _t = (_sk.target == TGT_SELF) ? _u : (_user_is_p ? EnemyCreate(ENEMY_SLIME) : CharacterCreate_Player(CLASS_KNIGHT));
        for (var _li = 0; _li < array_length(_list_ids); _li++) {
            var _sid = _list_ids[_li];
            var _shown = _sk.status_turns;
            if (variable_struct_exists(_sk, "status_turns_list") && _li < array_length(_sk.status_turns_list) && _sk.status == -1) _shown = _sk.status_turns_list[_li];
            if (_sid == STATUS_POISON) continue;   // a poison lasts as many turns as it has stacks (checked below)
            if (_sid == STATUS_STUN) continue;
            if (Skill_AdjustStatusTurns(_u, _t, _sid, _shown) != _shown) { _sk_ok = false; _sk_bad += " " + _sk.name + "/" + string(_sid); }
        }
        if (_sk.status == STATUS_POISON && _sk.status_turns != _sk.status_stacks) { _sk_ok = false; _sk_bad += " " + _sk.name + " stacks"; }
    }
    Test_True("BUG-16: the turns a skill tooltip shows are the turns the skill applies (bad:" + _sk_bad + ")", _sk_ok);
}

// Packet B3 (combat-spec.md section 11; D19 D74 D75 D92). Expected values come from the spec text and tools/balance/check_combat_vectors.py, not from the code.
// The script runner mirrors the reference's: n = next actor, sP/sE = stun, bP/bE = BREAK push-back, pN = preview of the next N (changes nothing).
function Test_TurnScript(_spd_p, _spd_e, _boss, _script) {
    var _tl = Turn_New([Turn_Fighter(TL_PLAYER, _spd_p), Turn_Fighter(TL_ENEMY, _spd_e, _boss)]);
    var _names = ["P", "E"];
    var _out = "";
    var _toks = string_split(_script, " ");
    for (var _i = 0; _i < array_length(_toks); _i++) {
        var _t = _toks[_i];
        var _c = string_char_at(_t, 1);
        var _who = (string_char_at(_t, 2) == "P") ? TL_PLAYER : TL_ENEMY;
        if (_t == "n") {
            _out += _names[Turn_Next(_tl)];
        } else if (_c == "s") {
            _out += Turn_Stun(_tl, _who) ? "!" : "~";
        } else if (_c == "b") {
            Turn_Push(_tl, _who);
            _out += "B";
        } else if (_c == "p") {
            var _pv = Turn_Preview(_tl, real(string_delete(_t, 1, 1)));
            _out += "(";
            for (var _k = 0; _k < array_length(_pv); _k++) _out += _names[_pv[_k]];
            _out += ")";
        }
    }
    return _out;
}

function Test_Suite_Turns() {
    // ---- the vectors (generated by the reference; the checker fails if one of these lines is missing or differs) ----
    Test_Eq("vec stagger_gain_6_no", Stagger_Gain(6, false, false), 3);
    Test_Eq("vec stagger_gain_6_np", Stagger_Gain(6, false, true), 5);
    Test_Eq("vec stagger_gain_11_so", Stagger_Gain(11, true, false), 11);
    Test_Eq("vec stagger_gain_11_sp", Stagger_Gain(11, true, true), 17);
    Test_Eq("vec stagger_gain_1_no", Stagger_Gain(1, false, false), 1);
    Test_Eq("vec stagger_gain_2_np", Stagger_Gain(2, false, true), 2);
    Test_Eq("vec stagger_max_1_norm", Stagger_Max(1, false), 8);
    Test_Eq("vec stagger_max_2_norm", Stagger_Max(2, false), 12);
    Test_Eq("vec stagger_max_3_boss", Stagger_Max(3, true), 32);
    Test_Eq("vec stagger_max_4_boss", Stagger_Max(4, true), 40);
    Test_Eq("vec stagger_max_4_norm", Stagger_Max(4, false), 20);
    Test_Eq("vec turn_13_9", Test_TurnScript(13, 9, false, "n n n n n n n n n"), "PEPEPPEPE");
    Test_Eq("vec turn_2x", Test_TurnScript(20, 10, false, "n n n n n n n n n n n n"), "PPEPPEPPEPPE");
    Test_Eq("vec turn_tie", Test_TurnScript(10, 10, false, "n n n n"), "PEPE");
    Test_Eq("vec turn_slow_player", Test_TurnScript(9, 13, false, "n n n n n n"), "EPEPEE");
    Test_Eq("vec turn_preview", Test_TurnScript(13, 9, false, "p5 n n p5 n n n"), "(PEPEP)PE(PEPPE)PEP");
    Test_Eq("vec turn_stun", Test_TurnScript(10, 10, false, "n sE p5 n n n n n n"), "P!(PEPEP)PEPEPE");
    Test_Eq("vec turn_stun_steadfast", Test_TurnScript(10, 10, false, "n sE n sE n sE n n sE n"), "P!P~E~PE!P");
    Test_Eq("vec turn_stun_boss", Test_TurnScript(10, 10, true, "n sE n n n n"), "P!EPEP");
    Test_Eq("vec turn_stun_player", Test_TurnScript(10, 10, false, "n n sP n n n n"), "PE!EPEP");
    Test_Eq("vec turn_break", Test_TurnScript(10, 10, false, "n bE n n n n"), "PBPEPE");
    Test_Eq("vec turn_fast_double", Test_TurnScript(20, 8, false, "n n n n n n n"), "PPEPPPE");

    // ---- behaviour ----
    var _tl = Turn_New([Turn_Fighter(TL_PLAYER, 13), Turn_Fighter(TL_ENEMY, 9)]);
    Test_Eq("Turn_Preview defaults to 5 actors", array_length(Turn_Preview(_tl)), 5);
    var _a = Turn_Preview(_tl, 7);
    var _b = Turn_Preview(_tl, 7);
    Test_True("Turn_Preview changes nothing: asking twice gives the same answer", Test_SameArray(_a, _b));
    var _real = [];
    for (var _i = 0; _i < 7; _i++) array_push(_real, Turn_Next(_tl));
    Test_True("Turn_Preview is exactly what the next Turn_Next calls return", Test_SameArray(_a, _real));

    // a fighter with 2x SPD acts about 2x as often (30 turns of 18 vs 9: 20 to 10)
    var _two = Turn_New([Turn_Fighter(TL_PLAYER, 18), Turn_Fighter(TL_ENEMY, 9)]);
    var _np = 0;
    for (var _j = 0; _j < 30; _j++) { if (Turn_Next(_two) == TL_PLAYER) _np++; }
    Test_Eq("2x SPD acts twice as often (20 of 30 turns)", _np, 20);
    var _three = Turn_New([Turn_Fighter(TL_PLAYER, 9), Turn_Fighter(TL_ENEMY, 27)]);
    var _ne = 0;
    for (var _j2 = 0; _j2 < 40; _j2++) { if (Turn_Next(_three) == TL_ENEMY) _ne++; }
    Test_Eq("3x SPD acts three times as often (30 of 40 turns)", _ne, 30);

    // SPD is read again every turn (Bleeding SPD-2 slows the next turns); a tie goes to the player; SPD never drops below 1
    var _slow = Turn_New([Turn_Fighter(TL_PLAYER, 10), Turn_Fighter(TL_ENEMY, 10)]);
    Test_Eq("equal SPD: the player is first", Turn_Next(_slow), TL_PLAYER);
    Turn_SetSpd(_slow, TL_ENEMY, 5);
    Test_Eq("SPD can drop mid-battle (Turn_SetSpd)", Turn_Find(_slow, TL_ENEMY).spd, 5);
    Turn_SetSpd(_slow, TL_ENEMY, 0);
    Test_Eq("SPD never goes below 1", Turn_Find(_slow, TL_ENEMY).spd, 1);

    // the first actor agrees with the initiative rule (spec sections 1 and 8)
    var _pairs = [[8, 9], [9, 9], [13, 9], [12, 14], [30, 5]];
    var _agree = true;
    for (var _pi = 0; _pi < array_length(_pairs); _pi++) {
        var _t0 = Turn_New([Turn_Fighter(TL_PLAYER, _pairs[_pi][0]), Turn_Fighter(TL_ENEMY, _pairs[_pi][1])]);
        if ((Turn_Next(_t0) == TL_PLAYER) != Combat_PlayerActsFirst(_pairs[_pi][0], _pairs[_pi][1])) _agree = false;
    }
    Test_True("the timeline's first actor is the higher SPD, a tie the player", _agree);

    // stun: -100 gauge (a boss -50), then Steadfast for 2 of the target's own turns; nothing gives an extra action
    var _st = Turn_New([Turn_Fighter(TL_PLAYER, 10), Turn_Fighter(TL_ENEMY, 10)]);
    Turn_Next(_st);   // the player acts; the enemy's gauge is 100 and it is next
    Test_True("a stun lands on a fighter that is not Steadfast", Turn_Stun(_st, TL_ENEMY));
    Test_Eq("stun pushes the gauge back one full turn", Turn_Find(_st, TL_ENEMY).gauge, 0);
    Test_Eq("the stunned fighter is Steadfast for 2 turns", Turn_Find(_st, TL_ENEMY).steadfast, 2);
    Test_False("a second stun while Steadfast does nothing", Turn_Stun(_st, TL_ENEMY));
    Test_Eq("a blocked stun pushes nothing", Turn_Find(_st, TL_ENEMY).gauge, 0);
    Turn_Next(_st);   // player
    Turn_Next(_st);   // enemy: its first turn after the stun
    Test_Eq("after its first turn it is Steadfast for 1 more", Turn_Find(_st, TL_ENEMY).steadfast, 1);
    Test_False("still Steadfast between its two turns", Turn_Stun(_st, TL_ENEMY));
    Turn_Next(_st);   // player
    Turn_Next(_st);   // enemy: its second turn
    Test_Eq("after its second turn Steadfast is over", Turn_Find(_st, TL_ENEMY).steadfast, 0);
    Test_True("and it can be stunned again", Turn_Stun(_st, TL_ENEMY));
    var _bs = Turn_New([Turn_Fighter(TL_PLAYER, 10), Turn_Fighter(TL_ENEMY, 10, true)]);
    Turn_Next(_bs);
    Turn_Stun(_bs, TL_ENEMY);
    Test_Eq("a boss is pushed back half as far (100 -> 50)", Turn_Find(_bs, TL_ENEMY).gauge, 50);

    // Battle_ConsumeStun: the Stun status a skill leaves becomes a push-back at once, and is removed
    var _tl2 = Turn_New([Turn_Fighter(TL_PLAYER, 10), Turn_Fighter(TL_ENEMY, 10)]);
    Turn_Next(_tl2);
    var _foe = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_STUN, 1, 0);
    Test_Eq("Battle_ConsumeStun pushes the target back", Battle_ConsumeStun(_tl2, _foe, TL_ENEMY), "pushed");
    Test_False("and the Stun marker is gone", Status_Has(_foe, STATUS_STUN));
    Test_Eq("the enemy was pushed back", Turn_Find(_tl2, TL_ENEMY).gauge, 0);
    _foe = Status_Add(_foe, STATUS_STUN, 1, 0);
    Test_Eq("a Steadfast target resists the next stun", Battle_ConsumeStun(_tl2, _foe, TL_ENEMY), "steadfast");
    Test_False("the resisted marker is removed too", Status_Has(_foe, STATUS_STUN));
    Test_Eq("no marker, no push", Battle_ConsumeStun(_tl2, _foe, TL_ENEMY), "none");
    var _hero = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_STUN, 1, 0);
    Test_Eq("the player can be pushed back too (Vine Trap)", Battle_ConsumeStun(_tl2, _hero, TL_PLAYER), "pushed");

    // stagger meters
    Test_Eq("Slime stagger meter (rank 1)", EnemyCreate(ENEMY_SLIME).stagger_max, 8);
    Test_Eq("Ghost Sword stagger meter (rank 2)", EnemyCreate(ENEMY_GHOSTSWORD).stagger_max, 12);
    Test_Eq("Palehorn (boss, rank 3) stagger meter", EnemyCreate(ENEMY_MINI_BOSS).stagger_max, 32);
    Test_Eq("The Pale Choirbeast (boss, rank 4) stagger meter", EnemyCreate(ENEMY_FINAL_BOSS).stagger_max, 40);
    var _sl = EnemyCreate(ENEMY_SLIME);
    Test_True("a new enemy has an empty meter and is not broken", _sl.stagger == 0 && !_sl.broken);
    Test_False("a hit below the meter does not break", Stagger_Add(_sl, 5));
    Test_Eq("the meter shows the hits so far", _sl.stagger, 5);
    Test_True("filling the meter is a BREAK", Stagger_Add(_sl, 3));
    Test_True("broken: the flag is set", _sl.broken);
    Test_Eq("broken: the meter resets to 0", _sl.stagger, 0);
    Test_False("while broken the meter does not fill and cannot break again", Stagger_Add(_sl, 9) || _sl.stagger != 0);
    Test_Eq("broken takes +50% damage", Combat_BreakMult(_sl), 1.5);
    Test_Eq("not broken takes normal damage", Combat_BreakMult(EnemyCreate(ENEMY_SLIME)), 1);
    Test_Eq("the player has no BREAK multiplier", Combat_BreakMult(CharacterCreate_Player(CLASS_KNIGHT)), 1);
    Stagger_EndBreak(_sl);
    Test_False("the enemy's next turn clears BROKEN", _sl.broken);
    Test_True("and the meter fills again", !Stagger_Add(_sl, 2) && _sl.stagger == 2);
    // +50% in the real damage path: Knight ATK 11 vs Slime DEF 7, power 6: 6x11/18 = 3.67 -> 4; broken: 6x11x1.5/18 = 5.5 -> 6
    var _knight = CharacterCreate_Player(CLASS_KNIGHT);
    var _src = { power: 6, stat_type: STAT_ATK };
    var _plain = EnemyCreate(ENEMY_SLIME);
    var _hit = Combat_ApplyDamage(_knight, _plain, _src);
    Test_Eq("damage to an unbroken Slime (power 6, ATK 11, DEF 7)", _hit.dmg, 4);
    var _brk = EnemyCreate(ENEMY_SLIME);
    _brk.broken = true;
    var _hit2 = Combat_ApplyDamage(_knight, _brk, _src);
    Test_Eq("damage to a broken Slime is +50% (5.5 -> 6)", _hit2.dmg, 6);
}

// Inventory rules (balance-data.md section 6; combat-bugs.md section 4; R-003 skill books appear twice).
// Packet B4 (combat-spec.md section 12; D7 D59 D68 D75 D79). Expected values come from the spec text (rule table, phases, formulas), not from the code.
function Test_AICtx(_turn = 1, _phase = 0) {
    return { turn: _turn, phase: _phase, uses: {}, windup: -1, used_turn: [], actions_left: 1, force_damage_only: false };
}

// _n choices from one stream (nothing changes between them): the skill ids, -1 for the basic attack.
function Test_AIDraws(_e, _p, _ctx, _seed, _n) {
    var _rng = Rng_New(_seed, "combat");
    var _out = [];
    for (var _i = 0; _i < _n; _i++) array_push(_out, EnemyAI_Choose(_e, _p, _ctx, _rng).skill_id);
    return _out;
}

function Test_AICount(_arr, _v) {
    var _n = 0;
    for (var _i = 0; _i < array_length(_arr); _i++) { if (_arr[_i] == _v) _n++; }
    return _n;
}

function Test_AICond(_c, _v = 0, _status = -1) {
    return { c: _c, v: _v, status: _status };
}

// Does a one-rule brain (cond -> Bite, no weights) fire for this enemy / player / context?
function Test_AIRuleFires(_cond, _e, _p, _ctx) {
    _e.skills = [SKILL_BITE];
    _e.brain = { rules: [ { label: "t", when: [_cond], act: "skill", skill: SKILL_BITE, chance: 1, max_uses: -1 } ], weights: [], phases: [] };
    return EnemyAI_Choose(_e, _p, _ctx, Rng_New(1, "combat")).skill_id == SKILL_BITE;
}

function Test_Suite_EnemyAI() {
    GameState_Get();
    EnemyDB_Init(); SkillDB_Init(); StatusDB_Init();
    var _p = CharacterCreate_Player(CLASS_KNIGHT);

    // ---- the brain is data on every enemy, and it only names what exists ----
    var _ids = [ENEMY_SLIME, ENEMY_SPIDER, ENEMY_SNAKE, ENEMY_DIREWOLF, ENEMY_MADWHISP, ENEMY_KILLER_PLANT, ENEMY_GHOSTSWORD, ENEMY_STRANGER, ENEMY_MINI_BOSS, ENEMY_FINAL_BOSS];
    var _data_bad = "";
    for (var _i = 0; _i < array_length(_ids); _i++) {
        var _en = EnemyCreate(_ids[_i]);
        if (!variable_struct_exists(_en, "brain")) { _data_bad += " " + _en.name + ":no-brain"; continue; }
        var _b = _en.brain;
        var _prev_at = 2;
        Test_Eq("AI data: " + _en.name + " has " + (_en.is_boss ? "2 phases" : "no phases"), array_length(_b.phases), _en.is_boss ? 2 : 0);
        for (var _k = 0; _k <= array_length(_b.phases); _k++) {
            var _lists = EnemyAI_Lists(_b, _k);
            var _labels = {};   // a label is unique within one list (a phase may keep a rule of the base list)
            var _wsum = 0;
            for (var _r = 0; _r < array_length(_lists.rules); _r++) {
                var _rule = _lists.rules[_r];
                if (variable_struct_exists(_labels, _rule.label)) _data_bad += " " + _en.name + ":dup-label-" + _rule.label;
                variable_struct_set(_labels, _rule.label, true);
                for (var _c = 0; _c < array_length(_rule.when); _c++) {
                    if (!EnemyAI_KnownCond(_rule.when[_c].c)) _data_bad += " " + _en.name + ":cond-" + string(_rule.when[_c].c);
                    if (_rule.when[_c].c == "every_nth" && _rule.when[_c].v < 2) _data_bad += " " + _en.name + ":nth<2";
                }
                if (_rule.act == "skill" && !array_contains(_en.skills, _rule.skill)) _data_bad += " " + _en.name + ":rule-skill-" + string(_rule.skill);
                if (_rule.act != "skill" && _rule.act != "attack") _data_bad += " " + _en.name + ":do-" + string(_rule.act);
            }
            for (var _w = 0; _w < array_length(_lists.weights); _w++) {
                var _wt = _lists.weights[_w];
                _wsum += _wt.w;
                if (_wt.act == "skill" && !array_contains(_en.skills, _wt.skill)) _data_bad += " " + _en.name + ":weight-skill-" + string(_wt.skill);
            }
            if (_wsum <= 0) _data_bad += " " + _en.name + ":no-weights-in-list-" + string(_k);
            if (_k >= 1) {
                if (_b.phases[_k - 1].at >= _prev_at) _data_bad += " " + _en.name + ":phases-not-falling";
                _prev_at = _b.phases[_k - 1].at;
            }
        }
    }
    Test_Eq("AI data: every brain is complete (bad:" + _data_bad + ")", _data_bad, "");

    // ---- each condition type fires when true and not when false ----
    var _low = EnemyCreate(ENEMY_SLIME);
    _low.hp = 3;   // 3 / 9
    var _pl = CharacterCreate_Player(CLASS_KNIGHT);
    _pl.hp = floor(_pl.max_hp * 0.4);
    var _pbuff = CharacterCreate_Player(CLASS_KNIGHT);
    _pbuff = Status_Add(_pbuff, STATUS_CRIT_UP, 3, 0);
    var _ppoi = CharacterCreate_Player(CLASS_KNIGHT);
    _ppoi = Status_Add(_ppoi, STATUS_POISON, 2, 0, 2);
    var _sbleed = EnemyCreate(ENEMY_SLIME);
    _sbleed = Status_Add(_sbleed, STATUS_BLEED, 3, 0);
    Test_True("AI cond always: fires", Test_AIRuleFires(Test_AICond("always"), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_True("AI cond hp_below 0.5: fires at 3/9", Test_AIRuleFires(Test_AICond("hp_below", 0.5), _low, _p, Test_AICtx()));
    Test_False("AI cond hp_below 0.5: not at full HP", Test_AIRuleFires(Test_AICond("hp_below", 0.5), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_True("AI cond hp_above 0.5: fires at full HP", Test_AIRuleFires(Test_AICond("hp_above", 0.5), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_False("AI cond hp_above 0.5: not at 3/9", Test_AIRuleFires(Test_AICond("hp_above", 0.5), _low, _p, Test_AICtx()));
    Test_True("AI cond player_hp_below 0.5: fires at 40%", Test_AIRuleFires(Test_AICond("player_hp_below", 0.5), EnemyCreate(ENEMY_SLIME), _pl, Test_AICtx()));
    Test_False("AI cond player_hp_below 0.5: not at full HP", Test_AIRuleFires(Test_AICond("player_hp_below", 0.5), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_True("AI cond player_buffed: fires with Take Aim", Test_AIRuleFires(Test_AICond("player_buffed"), EnemyCreate(ENEMY_SLIME), _pbuff, Test_AICtx()));
    Test_False("AI cond player_buffed: not with nothing", Test_AIRuleFires(Test_AICond("player_buffed"), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_False("AI cond player_buffed: a debuff (Poison) is not a buff", Test_AIRuleFires(Test_AICond("player_buffed"), EnemyCreate(ENEMY_SLIME), _ppoi, Test_AICtx()));
    Test_True("AI cond player_has_status Poison: fires when poisoned", Test_AIRuleFires(Test_AICond("player_has_status", 0, STATUS_POISON), EnemyCreate(ENEMY_SLIME), _ppoi, Test_AICtx()));
    Test_False("AI cond player_has_status Poison: not when clean", Test_AIRuleFires(Test_AICond("player_has_status", 0, STATUS_POISON), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_True("AI cond player_missing_status Poison: fires when clean", Test_AIRuleFires(Test_AICond("player_missing_status", 0, STATUS_POISON), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_False("AI cond player_missing_status Poison: not when poisoned", Test_AIRuleFires(Test_AICond("player_missing_status", 0, STATUS_POISON), EnemyCreate(ENEMY_SLIME), _ppoi, Test_AICtx()));
    Test_True("AI cond player_status_at_least Poison 2: fires with 2 stacks", Test_AIRuleFires(Test_AICond("player_status_at_least", 2, STATUS_POISON), EnemyCreate(ENEMY_SLIME), _ppoi, Test_AICtx()));
    Test_False("AI cond player_status_at_least Poison 3: not with 2 stacks", Test_AIRuleFires(Test_AICond("player_status_at_least", 3, STATUS_POISON), EnemyCreate(ENEMY_SLIME), _ppoi, Test_AICtx()));
    Test_True("AI cond self_has_status Bleeding: fires when bleeding", Test_AIRuleFires(Test_AICond("self_has_status", 0, STATUS_BLEED), _sbleed, _p, Test_AICtx()));
    Test_False("AI cond self_has_status Bleeding: not when clean", Test_AIRuleFires(Test_AICond("self_has_status", 0, STATUS_BLEED), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_True("AI cond self_missing_status Bleeding: fires when clean", Test_AIRuleFires(Test_AICond("self_missing_status", 0, STATUS_BLEED), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_False("AI cond self_missing_status Bleeding: not when bleeding", Test_AIRuleFires(Test_AICond("self_missing_status", 0, STATUS_BLEED), _sbleed, _p, Test_AICtx()));
    Test_True("AI cond every_nth 2: fires on turn 2", Test_AIRuleFires(Test_AICond("every_nth", 2), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx(2)));
    Test_False("AI cond every_nth 2: not on turn 3", Test_AIRuleFires(Test_AICond("every_nth", 2), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx(3)));
    Test_True("AI cond every_nth 2: fires on turn 4", Test_AIRuleFires(Test_AICond("every_nth", 2), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx(4)));
    Test_False("AI an unknown condition never fires", Test_AIRuleFires(Test_AICond("no_such_cond"), EnemyCreate(ENEMY_SLIME), _p, Test_AICtx()));
    Test_False("AI EnemyAI_KnownCond says no to a made-up name", EnemyAI_KnownCond("no_such_cond"));

    // ---- Slime: defend when hurt (spec table) ----
    var _sl = EnemyCreate(ENEMY_SLIME);
    _sl.hp = 4;   // 4 / 9 = 44% <= 50%
    var _ch = EnemyAI_Choose(_sl, _p, Test_AICtx(), Rng_New(5, "combat"));
    Test_True("AI Slime at 44% HP uses Solidify by rule solidify_when_hurt", _ch.kind == "skill" && _ch.skill_id == SKILL_SOLIDIFY && _ch.rule == "solidify_when_hurt");
    var _sl_ok = EnemyCreate(ENEMY_SLIME);
    var _d = Test_AIDraws(_sl_ok, _p, Test_AICtx(), 5, 300);
    Test_True("AI Slime at full HP: Solidify only from the weights (about 1 in 5), attack otherwise", Test_AICount(_d, SKILL_SOLIDIFY) >= 30 && Test_AICount(_d, SKILL_SOLIDIFY) <= 90 && Test_AICount(_d, -1) >= 210);
    var _sl_solid = EnemyCreate(ENEMY_SLIME);
    _sl_solid.hp = 4;
    _sl_solid = Status_Add(_sl_solid, STATUS_SOLIDIFY, 2, 0);
    Test_Eq("AI Slime that is already Solid never casts Solidify again", Test_AICount(Test_AIDraws(_sl_solid, _p, Test_AICtx(), 5, 100), SKILL_SOLIDIFY), 0);

    // ---- Spider: a poison stack cap and an opener (spec table) ----
    var _sp = EnemyCreate(ENEMY_SPIDER);
    var _p4 = CharacterCreate_Player(CLASS_KNIGHT);
    _p4 = Status_Add(_p4, STATUS_POISON, 4, 0, 4);
    var _c4 = EnemyAI_Choose(_sp, _p4, Test_AICtx(), Rng_New(2, "combat"));
    Test_True("AI Spider vs 4 Poison stacks: plain attack by rule no_stacking_past_4", _c4.skill_id == -1 && _c4.rule == "no_stacking_past_4");
    Test_Eq("AI Spider vs 4 Poison stacks never uses Poison Fangs", Test_AICount(Test_AIDraws(_sp, _p4, Test_AICtx(), 2, 100), SKILL_POISON_FANGS), 0);
    var _p3 = CharacterCreate_Player(CLASS_KNIGHT);
    _p3 = Status_Add(_p3, STATUS_POISON, 3, 0, 3);
    var _d3 = Test_AIDraws(_sp, _p3, Test_AICtx(), 2, 200);
    Test_True("AI Spider vs 3 stacks: Poison Fangs from the weights only (about 1 in 4)", Test_AICount(_d3, SKILL_POISON_FANGS) >= 25 && Test_AICount(_d3, SKILL_POISON_FANGS) <= 80);
    var _d0 = Test_AIDraws(_sp, _p, Test_AICtx(), 2, 300);
    Test_True("AI Spider vs a clean player: Poison Fangs about 70% (60% rule, then the weights)", Test_AICount(_d0, SKILL_POISON_FANGS) >= 150 && Test_AICount(_d0, SKILL_POISON_FANGS) <= 250);
    Test_True("AI Spider keeps some randomness: the plain attack still happens", Test_AICount(_d0, -1) >= 30);

    // ---- Snake ----
    var _sn = EnemyCreate(ENEMY_SNAKE);
    var _pb3 = CharacterCreate_Player(CLASS_KNIGHT);
    _pb3 = Status_Add(_pb3, STATUS_BLEED, 3, 0, 3);
    Test_Eq("AI Snake vs 3 Bleeding stacks never bites", Test_AICount(Test_AIDraws(_sn, _pb3, Test_AICtx(), 4, 100), SKILL_BITE), 0);
    var _dsn = Test_AIDraws(_sn, _p, Test_AICtx(), 4, 300);
    Test_True("AI Snake vs a clean player: Bite about 67% (50% rule, then 1 in 3)", Test_AICount(_dsn, SKILL_BITE) >= 150 && Test_AICount(_dsn, SKILL_BITE) <= 250);

    // ---- Dire Wolf: howl first, then fight ----
    var _wo = EnemyCreate(ENEMY_DIREWOLF);
    var _dwo = Test_AIDraws(_wo, _p, Test_AICtx(), 9, 300);
    Test_True("AI Dire Wolf without Bloodthirsty: howls about half the time", Test_AICount(_dwo, SKILL_BLOODTHIRSTY) >= 110 && Test_AICount(_dwo, SKILL_BLOODTHIRSTY) <= 190);
    var _wo2 = EnemyCreate(ENEMY_DIREWOLF);
    _wo2 = Status_Add(_wo2, STATUS_BLOODTHIRSTY, 4, 0);
    Test_Eq("AI Dire Wolf with Bloodthirsty never howls again", Test_AICount(Test_AIDraws(_wo2, _p, Test_AICtx(), 9, 100), SKILL_BLOODTHIRSTY), 0);

    // ---- Mad Whisp: a buffed player gets Snuffed ----
    var _wi = EnemyCreate(ENEMY_MADWHISP);
    var _cb = EnemyAI_Choose(_wi, _pbuff, Test_AICtx(), Rng_New(3, "combat"));
    Test_True("AI Mad Whisp vs a buffed player: Snuff by rule snuff_buffs", _cb.kind == "skill" && _cb.skill_id == SKILL_SNUFF && _cb.rule == "snuff_buffs");
    Test_Eq("AI Mad Whisp vs a buffed player: every one of 30 choices is Snuff", Test_AICount(Test_AIDraws(_wi, _pbuff, Test_AICtx(), 3, 30), SKILL_SNUFF), 30);
    var _pguard = CharacterCreate_Player(CLASS_KNIGHT);
    _pguard = Status_Add(_pguard, STATUS_GUARD, 2, 0);
    Test_Eq("AI Mad Whisp also answers Guard", EnemyAI_Choose(_wi, _pguard, Test_AICtx(), Rng_New(3, "combat")).skill_id, SKILL_SNUFF);
    Test_Eq("AI Mad Whisp vs a poisoned (not buffed) player never Snuffs", Test_AICount(Test_AIDraws(_wi, _ppoi, Test_AICtx(), 3, 100), SKILL_SNUFF), 0);
    var _dwi = Test_AIDraws(_wi, _p, Test_AICtx(), 3, 300);
    Test_True("AI Mad Whisp default: Scorching Touch about 40%, attack about 60%", Test_AICount(_dwi, SKILL_SCORCHING_TOUCH) >= 90 && Test_AICount(_dwi, SKILL_SCORCHING_TOUCH) <= 150 && Test_AICount(_dwi, -1) >= 150);

    // ---- Killer Plant: heal when low (once), a telegraphed Vine Trap every 3rd turn ----
    var _kp = EnemyCreate(ENEMY_KILLER_PLANT);
    var _kp_low = EnemyCreate(ENEMY_KILLER_PLANT);
    _kp_low.hp = floor(_kp_low.max_hp * 0.3);
    var _ck = EnemyAI_Choose(_kp_low, _p, Test_AICtx(), Rng_New(1, "combat"));
    Test_True("AI Killer Plant at 30% HP: Regrow by rule low_hp_heal", _ck.kind == "skill" && _ck.skill_id == SKILL_REGROW && _ck.rule == "low_hp_heal");
    var _ctx_used = Test_AICtx();
    variable_struct_set(_ctx_used.uses, "low_hp_heal", 1);
    Test_True("AI Killer Plant already healed once: the heal rule is spent (max_uses 1)", EnemyAI_Choose(_kp_low, _p, _ctx_used, Rng_New(1, "combat")).rule != "low_hp_heal");
    Test_Eq("AI Killer Plant at full HP never heals", Test_AICount(Test_AIDraws(_kp, _p, Test_AICtx(), 1, 60), SKILL_REGROW), 0);
    var _kp_expect = ["attack", "attack", "windup", "attack", "attack", "windup", "attack", "attack", "windup"];
    var _kp_got = true;
    var _kp_txt = "";
    for (var _t = 1; _t <= 9; _t++) {
        var _ct = EnemyAI_Choose(_kp, _p, Test_AICtx(_t), Rng_New(1, "combat"));
        _kp_txt += " " + _ct.kind;
        if (_ct.kind != _kp_expect[_t - 1]) _kp_got = false;
        if (_ct.kind == "windup" && (_ct.skill_id != SKILL_VINE_TRAP || _ct.rule != "vine_every_3rd")) _kp_got = false;
    }
    Test_True("AI Killer Plant turns 1..9: attack attack WINDUP (Vine Trap) every 3rd (got:" + _kp_txt + ")", _kp_got);
    Test_True("AI Killer Plant: a hurt plant on turn 3 heals first (the rules are a priority list)", EnemyAI_Choose(_kp_low, _p, Test_AICtx(3), Rng_New(1, "combat")).skill_id == SKILL_REGROW);

    // ---- Ghost Sword ----
    var _gs = EnemyCreate(ENEMY_GHOSTSWORD);
    var _gs_ok = true;
    for (var _tg = 1; _tg <= 7; _tg++) {
        var _cg = EnemyAI_Choose(_gs, _p, Test_AICtx(_tg), Rng_New(1, "combat"));
        var _want_w = (_tg mod 3 == 0);
        if ((_cg.kind == "windup") != _want_w) _gs_ok = false;
        if (_want_w && _cg.skill_id != SKILL_GHOST_CUT) _gs_ok = false;
    }
    Test_True("AI Ghost Sword: a telegraphed Cut on turns 3 and 6 only", _gs_ok);

    // ---- Stranger: grabs when hurt, once; Steal needs something to steal ----
    var _st = EnemyCreate(ENEMY_STRANGER);
    _st.hp = floor(_st.max_hp * 0.4);
    var _pinv = CharacterCreate_Player(CLASS_KNIGHT);
    _pinv.inventory = Inv_Add([], 10, 2);
    var _cs = EnemyAI_Choose(_st, _pinv, Test_AICtx(), Rng_New(1, "combat"));
    Test_True("AI Stranger at 40% HP vs a player with items: Steal by rule grab_when_hurt", _cs.skill_id == SKILL_STEAL && _cs.rule == "grab_when_hurt");
    var _pnone = CharacterCreate_Player(CLASS_KNIGHT);
    _pnone.inventory = [];
    Test_Eq("AI Stranger vs a player with nothing to steal never uses Steal", Test_AICount(Test_AIDraws(_st, _pnone, Test_AICtx(), 1, 100), SKILL_STEAL), 0);
    var _ctx_grab = Test_AICtx();
    variable_struct_set(_ctx_grab.uses, "grab_when_hurt", 1);
    Test_True("AI Stranger: the grab rule is once per battle", EnemyAI_Choose(_st, _pinv, _ctx_grab, Rng_New(1, "combat")).rule != "grab_when_hurt");

    // ---- rule mechanics: skip what the enemy does not have, chance, telegraph, wind-up resolution, force ----
    var _x = EnemyCreate(ENEMY_SLIME);
    _x.skills = [];
    _x.brain = { rules: [ { label: "r", when: [Test_AICond("always")], act: "skill", skill: SKILL_BITE, chance: 1, max_uses: -1 } ], weights: [ { act: "skill", skill: SKILL_BITE, w: 5 } ], phases: [] };
    Test_Eq("AI a rule and a weight naming a skill the enemy lacks fall back to the basic attack", EnemyAI_Choose(_x, _p, Test_AICtx(), Rng_New(1, "combat")).skill_id, -1);
    _x.skills = [SKILL_BITE];
    _x.brain.rules[0].chance = 0.3;
    _x.brain.weights = [];
    var _dch = Test_AIDraws(_x, _p, Test_AICtx(), 11, 400);
    Test_True("AI a rule with chance 0.3 fires about 30% of the time", Test_AICount(_dch, SKILL_BITE) >= 90 && Test_AICount(_dch, SKILL_BITE) <= 150);
    var _y = EnemyCreate(ENEMY_SLIME);
    _y.skills = [SKILL_VINE_TRAP];
    _y.brain = { rules: [], weights: [ { act: "skill", skill: SKILL_VINE_TRAP, w: 1 } ], phases: [] };
    var _cy = EnemyAI_Choose(_y, _p, Test_AICtx(), Rng_New(1, "combat"));
    Test_True("AI a telegraphed skill chosen from the weights starts as a wind-up", _cy.kind == "windup" && _cy.skill_id == SKILL_VINE_TRAP);
    var _ctx_w = Test_AICtx();
    _ctx_w.windup = SKILL_VINE_TRAP;
    var _rw = Rng_New(1, "combat");
    var _cw = EnemyAI_Choose(_y, _p, _ctx_w, _rw);
    Test_True("AI after a wind-up the big attack comes (rule windup_attack)", _cw.kind == "skill" && _cw.skill_id == SKILL_VINE_TRAP && _cw.rule == "windup_attack");
    Test_Eq("AI resolving a wind-up draws no random number", _rw.calls, 0);
    var _ctx_f = Test_AICtx();
    _ctx_f.force_damage_only = true;
    var _cf = EnemyAI_Choose(_y, _p, _ctx_f, Rng_New(1, "combat"));
    Test_True("AI the debug damage-only switch skips the wind-up", _cf.kind == "skill" && _cf.skill_id == SKILL_VINE_TRAP);
    var _pal = EnemyCreate(ENEMY_MINI_BOSS);
    var _ctx_pf0 = Test_AICtx(1, 0);
    _ctx_pf0.force_damage_only = true;
    var _ctx_pf1 = Test_AICtx(1, 1);
    _ctx_pf1.force_damage_only = true;
    var _pf0 = Test_AIDraws(_pal, _p, _ctx_pf0, 3, 60);
    var _pf1 = Test_AIDraws(_pal, _p, _ctx_pf1, 3, 60);
    Test_Eq("AI the damage-only switch uses only the skills of the lists in force: Palehorn phase 0 is always Ramming", Test_AICount(_pf0, SKILL_RAMMING), 60);
    Test_True("AI the damage-only switch in phase 1 also uses Gore", Test_AICount(_pf1, SKILL_GORE) > 0 && Test_AICount(_pf1, SKILL_RAMMING) > 0);
    var _ctx_once = Test_AICtx();
    _ctx_once.used_turn = [SKILL_BLESSING];
    var _bl = EnemyCreate(ENEMY_FINAL_BOSS);
    _bl.hp = floor(_bl.max_hp * 0.5);
    _bl.brain = { rules: [ { label: "b", when: [Test_AICond("always")], act: "skill", skill: SKILL_BLESSING, chance: 1, max_uses: -1 } ], weights: [], phases: [] };
    Test_Eq("AI a once-per-turn skill already used this turn is not chosen again", EnemyAI_Choose(_bl, _p, _ctx_once, Rng_New(1, "combat")).skill_id, -1);
    Test_Eq("AI the same skill is fine when it was not used yet this turn", EnemyAI_Choose(_bl, _p, Test_AICtx(), Rng_New(1, "combat")).skill_id, SKILL_BLESSING);

    // ---- determinism (the "combat" stream) ----
    var _s1 = Test_AIDraws(_sp, _p, Test_AICtx(), 7, 100);
    var _s2 = Test_AIDraws(_sp, _p, Test_AICtx(), 7, 100);
    var _s3 = Test_AIDraws(_sp, _p, Test_AICtx(), 8, 100);
    Test_True("AI the same seed gives the same 100 choices", Test_SameArray(_s1, _s2));
    Test_False("AI another seed gives another sequence", Test_SameArray(_s1, _s3));
    var _rs = Rng_New(7, "combat");
    EnemyAI_Choose(_sp, _p, Test_AICtx(), _rs);
    Test_True("AI the choice draws from the stream it is given", _rs.calls >= 1);

    // ---- pure state: turn counter, wind-up, BREAK ----
    var _stt = EnemyAI_StateNew();
    Test_True("AI state starts at turn 1, phase 0, no wind-up", EnemyAI_Ctx(_stt).turn == 1 && EnemyAI_Ctx(_stt).phase == 0 && EnemyAI_Ctx(_stt).windup == -1);
    Test_Eq("AI BREAK with no wind-up cancels nothing", EnemyAI_Break(_stt), -1);
    EnemyAI_Take(_stt, { kind: "windup", skill_id: SKILL_RAMMING, rule: "ram_every_3rd" });
    Test_Eq("AI a wind-up is remembered", EnemyAI_Ctx(_stt).windup, SKILL_RAMMING);
    Test_Eq("AI a wind-up counts as a use of its rule", variable_struct_get(_stt.uses, "ram_every_3rd"), 1);
    Test_Eq("AI BREAK during the wind-up cancels the big attack and says which", EnemyAI_Break(_stt), SKILL_RAMMING);
    Test_Eq("AI after the cancel there is no wind-up", EnemyAI_Ctx(_stt).windup, -1);
    Test_Eq("AI a second BREAK cancels nothing", EnemyAI_Break(_stt), -1);
    EnemyAI_Take(_stt, { kind: "windup", skill_id: SKILL_RAMMING, rule: "ram_every_3rd" });
    EnemyAI_Take(_stt, { kind: "skill", skill_id: SKILL_RAMMING, rule: "windup_attack" });
    Test_Eq("AI the big attack ends the wind-up", EnemyAI_Ctx(_stt).windup, -1);
    Test_Eq("AI the big attack is not counted as another use of the rule (2 wind-ups so far)", variable_struct_get(_stt.uses, "ram_every_3rd"), 2);
    EnemyAI_EndTurn(_stt);
    Test_Eq("AI a finished enemy turn moves the counter on", EnemyAI_Ctx(_stt).turn, 2);

    // ---- skills: the heavy moves, the new moves ----
    var _heavy = [SKILL_VINE_TRAP, SKILL_GHOST_CUT, SKILL_RAMMING, SKILL_PALE_HYMN];
    var _light = [SKILL_POISON_FANGS, SKILL_BITE, SKILL_SCORCHING_TOUCH, SKILL_GORE, SKILL_REGROW, SKILL_SNUFF, SKILL_SOLIDIFY, SKILL_BLOODTHIRSTY, SKILL_STEAL, SKILL_CURSE, SKILL_BLESSING];
    for (var _hi = 0; _hi < array_length(_heavy); _hi++) {
        var _hs = SkillDB_Get(_heavy[_hi]);
        Test_True("AI " + _hs.name + " is a telegraphed heavy move with a defence bar", variable_struct_exists(_hs, "telegraphed") && _hs.telegraphed && _hs.uses_defensive_qte);
        Test_True("AI " + _hs.name + " hits harder than a plain move (power_mult 2, D111)", _hs.power_mult == 2);
        Test_True("AI " + _hs.name + " has its own bar", Qte_DefenceParams(_heavy[_hi]).sweep_ms != Qte_BarParams("default").sweep_ms);
        Test_True("AI " + _hs.name + " has a wind-up line that names the enemy", string_pos("Slimey", Skill_WindupText(_hs, "Slimey")) > 0);
    }
    for (var _li = 0; _li < array_length(_light); _li++) {
        var _ls = SkillDB_Get(_light[_li]);
        Test_False("AI " + _ls.name + " is not telegraphed", variable_struct_exists(_ls, "telegraphed") && _ls.telegraphed);
    }
    Test_Eq("AI Regrow heals the user: effect heal on self", SkillDB_Get(SKILL_REGROW).effect + string(SkillDB_Get(SKILL_REGROW).target), "heal" + string(TGT_SELF));
    var _rg = EnemyCreate(ENEMY_KILLER_PLANT);
    _rg.hp = 5;
    var _rgr = Skill_Use(_rg, _rg, SKILL_REGROW);
    Test_True("AI Regrow gives power 5 + floor(MAG/4) HP back (MAG 10 -> 7)", _rgr.ok && _rg.hp == 12);
    var _rg2 = EnemyCreate(ENEMY_KILLER_PLANT);
    _rg2.hp = _rg2.max_hp - 1;
    Skill_Use(_rg2, _rg2, SKILL_REGROW);
    Test_Eq("AI Regrow never heals past max HP", _rg2.hp, _rg2.max_hp);
    var _sn_p = CharacterCreate_Player(CLASS_KNIGHT);
    _sn_p = Status_Add(_sn_p, STATUS_CRIT_UP, 3, 0);
    _sn_p = Status_Add(_sn_p, STATUS_GUARD, 2, 0);
    _sn_p = Status_Add(_sn_p, STATUS_POISON, 2, 0, 2);
    var _snr = Skill_Use(EnemyCreate(ENEMY_MADWHISP), _sn_p, SKILL_SNUFF);
    Test_True("AI Snuff removes every buff of the player", _snr.ok && !Status_Has(_sn_p, STATUS_CRIT_UP) && !Status_Has(_sn_p, STATUS_GUARD));
    Test_True("AI Snuff leaves the player's debuffs alone", Status_Has(_sn_p, STATUS_POISON));
    Test_True("AI Snuff does no damage and says something", _snr.dmg == 0 && _snr.msg != "");
    Test_True("AI Gore is a plain move with Bleeding and no bar", SkillDB_Get(SKILL_GORE).effect == "damage" && SkillDB_Get(SKILL_GORE).status == STATUS_BLEED && !Battle_EnemySkillCanBeDefended(SkillDB_Get(SKILL_GORE), { ok: true, hit: true, dmg: 5 }, _p));
    Test_True("AI Pale Hymn is a MAG attack", SkillDB_Get(SKILL_PALE_HYMN).stat_type == STAT_MAG && SkillDB_Get(SKILL_PALE_HYMN).effect == "damage");

    // ---- bosses: phases ----
    var _bosses = [ENEMY_MINI_BOSS, ENEMY_FINAL_BOSS];
    for (var _bi = 0; _bi < 2; _bi++) {
        var _bb = EnemyCreate(_bosses[_bi]).brain;
        var _bn = EnemyCreate(_bosses[_bi]).name;
        Test_Eq("AI " + _bn + " at 100% is phase 0", EnemyAI_PhaseFor(_bb, 1.0), 0);
        Test_Eq("AI " + _bn + " at 61% is still phase 0", EnemyAI_PhaseFor(_bb, 0.61), 0);
        Test_Eq("AI " + _bn + " at 60% is phase 1", EnemyAI_PhaseFor(_bb, 0.60), 1);
        Test_Eq("AI " + _bn + " at 31% is phase 1", EnemyAI_PhaseFor(_bb, 0.31), 1);
        Test_Eq("AI " + _bn + " at 30% is phase 2", EnemyAI_PhaseFor(_bb, 0.30), 2);
        Test_Eq("AI " + _bn + " at 1% is phase 2", EnemyAI_PhaseFor(_bb, 0.01), 2);
    }
    // Palehorn: the lists change with the phase
    var _ph = EnemyCreate(ENEMY_MINI_BOSS);
    Test_Eq("AI Palehorn phase 0 never uses Gore", Test_AICount(Test_AIDraws(_ph, _p, Test_AICtx(1, 0), 3, 300), SKILL_GORE), 0);
    var _g1 = Test_AICount(Test_AIDraws(_ph, _p, Test_AICtx(1, 1), 3, 300), SKILL_GORE);
    var _g2 = Test_AICount(Test_AIDraws(_ph, _p, Test_AICtx(1, 2), 3, 300), SKILL_GORE);
    Test_True("AI Palehorn phase 1: Gore about 1 in 3", _g1 >= 60 && _g1 <= 140);
    Test_True("AI Palehorn phase 2: Gore about 2 in 3", _g2 >= 160 && _g2 <= 240);
    Test_True("AI Palehorn phase 0: Ramming is telegraphed on turn 3, not on turn 2", EnemyAI_Choose(_ph, _p, Test_AICtx(3, 0), Rng_New(1, "combat")).kind == "windup" && EnemyAI_Choose(_ph, _p, Test_AICtx(2, 0), Rng_New(1, "combat")).kind != "windup");
    var _c2 = EnemyAI_Choose(_ph, _p, Test_AICtx(2, 2), Rng_New(1, "combat"));
    Test_True("AI Palehorn phase 2: Ramming is telegraphed every 2nd turn", _c2.kind == "windup" && _c2.skill_id == SKILL_RAMMING && _c2.rule == "ram_every_2nd");
    var _hy = EnemyCreate(ENEMY_FINAL_BOSS);
    Test_True("AI Choirbeast phase 0: Pale Hymn telegraphed on turn 4 only", EnemyAI_Choose(_hy, _p, Test_AICtx(4, 0), Rng_New(1, "combat")).skill_id == SKILL_PALE_HYMN && EnemyAI_Choose(_hy, _p, Test_AICtx(3, 0), Rng_New(1, "combat")).kind != "windup");
    Test_True("AI Choirbeast phase 1: Pale Hymn on turn 3", EnemyAI_Choose(_hy, _p, Test_AICtx(3, 1), Rng_New(1, "combat")).rule == "hymn_every_3rd");
    Test_True("AI Choirbeast phase 2: Pale Hymn on turn 2", EnemyAI_Choose(_hy, _p, Test_AICtx(2, 2), Rng_New(1, "combat")).rule == "hymn_every_2nd");
    var _hy_bless = EnemyCreate(ENEMY_FINAL_BOSS);
    _hy_bless.hp = floor(_hy_bless.max_hp * 0.55);
    var _bl_n = Test_AICount(Test_AIDraws(_hy_bless, _p, Test_AICtx(1, 1), 3, 300), SKILL_BLESSING);
    Test_True("AI Choirbeast phase 1 without Blessing: casts it about half the time", _bl_n >= 110 && _bl_n <= 190);

    // PhaseSync: forward only, SPD / ATK added, banner on the change, a skipped phase still counts
    var _pst = EnemyAI_StateNew();
    var _pb = EnemyCreate(ENEMY_MINI_BOSS);
    var _spd0 = _pb.stats.spd;
    var _atk0 = _pb.stats.atk;
    Test_False("AI Palehorn at full HP: no phase change", EnemyAI_PhaseSync(_pst, _pb).changed);
    _pb.hp = floor(_pb.max_hp * 0.55);
    var _r1 = EnemyAI_PhaseSync(_pst, _pb);
    Test_True("AI Palehorn at 55%: phase 1 with a banner", _r1.changed && _r1.phase == 1 && _r1.banner != "" && _pst.phase == 1);
    Test_Eq("AI Palehorn phase 1: SPD +2", _pb.stats.spd, _spd0 + 2);
    Test_Eq("AI Palehorn phase 1: ATK unchanged", _pb.stats.atk, _atk0);
    Test_False("AI the same phase twice is not a change (no second SPD bonus)", EnemyAI_PhaseSync(_pst, _pb).changed || _pb.stats.spd != _spd0 + 2);
    _pb.hp = _pb.max_hp;
    Test_False("AI healing does not send a boss back a phase", EnemyAI_PhaseSync(_pst, _pb).changed || _pst.phase != 1);
    _pb.hp = floor(_pb.max_hp * 0.2);
    var _r2 = EnemyAI_PhaseSync(_pst, _pb);
    Test_True("AI Palehorn at 20%: phase 2", _r2.changed && _r2.phase == 2 && _pst.phase == 2);
    Test_Eq("AI Palehorn phase 2: SPD +4 in all", _pb.stats.spd, _spd0 + 4);
    Test_Eq("AI Palehorn phase 2: ATK +3 (enrage)", _pb.stats.atk, _atk0 + 3);
    var _fst = EnemyAI_StateNew();
    var _fb = EnemyCreate(ENEMY_FINAL_BOSS);
    var _fspd = _fb.stats.spd;
    _fb.hp = floor(_fb.max_hp * 0.2);
    var _rf = EnemyAI_PhaseSync(_fst, _fb);
    Test_True("AI Choirbeast jumping from 100% to 20% reaches phase 2 at once", _rf.changed && _rf.phase == 2);
    Test_Eq("AI Choirbeast skipping phase 1 still gets both SPD bonuses (+2 +3)", _fb.stats.spd, _fspd + 5);
    Test_Eq("AI Choirbeast Fury is replaced by SPD: it has one action per turn even at 20% HP", Battle_EnemyActionBudget(_fb), 1);
    Test_False("AI no enemy has Rampage any more", array_contains(EnemyCreate(ENEMY_MINI_BOSS).skills, SKILL_RAMPAGE));
    Test_False("AI no enemy has Fury any more", array_contains(EnemyCreate(ENEMY_FINAL_BOSS).skills, SKILL_FINAL_FURY));
    Test_True("AI Curse stays with the Choirbeast (B2)", array_contains(EnemyCreate(ENEMY_FINAL_BOSS).skills, SKILL_CURSE));
    // the extra SPD is really more turns on the timeline
    var _tl_a = Turn_New([Turn_Fighter(TL_PLAYER, 10), Turn_Fighter(TL_ENEMY, _spd0)]);
    var _tl_b = Turn_New([Turn_Fighter(TL_PLAYER, 10), Turn_Fighter(TL_ENEMY, _spd0 + 4)]);
    var _ea = 0; var _eb = 0;
    for (var _tn = 0; _tn < 40; _tn++) {
        if (Turn_Next(_tl_a) == TL_ENEMY) _ea++;
        if (Turn_Next(_tl_b) == TL_ENEMY) _eb++;
    }
    Test_True("AI Palehorn in phase 2 gets more turns than in phase 0 (" + string(_ea) + " -> " + string(_eb) + " of 40)", _eb > _ea);

    // ---- Foresight (D79): the wind-up is shown, and so is the big attack ----
    var _pw = Battle_ActionPreviewOf({ skill_id: SKILL_RAMMING, kind: "windup" }, true);
    Test_True("AI Foresight: a wind-up shows as kind windup, big, with the skill's name", _pw.visible && _pw.kind == "windup" && _pw.big && string_pos(SkillDB_Get(SKILL_RAMMING).name, _pw.name) > 0);
    var _pa = Battle_ActionPreviewOf({ skill_id: SKILL_RAMMING, kind: "skill" }, true);
    Test_True("AI Foresight: the big attack after it shows as a skill, big", _pa.visible && _pa.kind == "skill" && _pa.big && _pa.skill_id == SKILL_RAMMING);
    Test_False("AI Foresight shows nothing without the status", Battle_ActionPreviewOf({ skill_id: SKILL_RAMMING, kind: "windup" }, false).visible);

    // ---- the old per-skill use chances are gone (the weights replace them, D68) ----
    Test_False("AI the old per-skill use chance is gone from the skill data", variable_struct_exists(SkillDB_Get(SKILL_BITE), "enemy_use_chance_min"));
}

function Test_Suite_Inventory() {
    Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL); // no skills learned yet
    var _max = ItemDB_Get(10).max_stack;
    var _inv = Inv_Add(Inv_Add([], 10, 3), 10, 4);
    Test_Eq("potions stack: one entry", array_length(_inv), 1);
    Test_Eq("potions stack: qty 7", _inv[0].qty, 7);
    var _big = Inv_Add([], 10, _max + 1);
    Test_Eq("stack splits at max_stack: 2 entries", array_length(_big), 2);
    Test_Eq("first stack is full", _big[0].qty, _max);
    Test_Eq("second stack holds the rest (1)", _big[1].qty, 1);
    Test_True("Inv_Has counts across stacks", Inv_Has(_big, 10, _max + 1) && !Inv_Has(_big, 10, _max + 2));
    _big = Inv_Remove(_big, 10, 1);
    Test_True("Inv_Remove takes from the end and drops an empty stack", array_length(_big) == 1 && _big[0].qty == _max);
    _inv = Inv_Remove(_inv, 10, 2);
    Test_Eq("Inv_Remove 7-2 leaves 5", _inv[0].qty, 5);
    _inv = Inv_Remove(_inv, 10, 99);
    Test_Eq("Inv_Remove more than owned empties the stack, no negatives", array_length(_inv), 0);
    Test_False("Inv_Has false after removal", Inv_Has(_inv, 10, 1));
    Test_Eq("Inv_Add qty 0 is a no-op", array_length(Inv_Add([], 10, 0)), 0);
    Test_Eq("Inv_Add negative qty is a no-op", array_length(Inv_Add([], 10, -2)), 0);
    // One-copy rule: weapons and armor are never duplicated (skill books are gone, D18).
    Test_Eq("weapon (Iron Sword 2) added twice -> 1 copy", array_length(Inv_Add(Inv_Add([], 2, 1), 2, 1)), 1);
    Test_Eq("weapon qty 3 in one call -> 1 copy", array_length(Inv_Add([], 2, 3)), 1);
    Test_Eq("armor (Leather Armor 20) added twice -> 1 copy", array_length(Inv_Add(Inv_Add([], 20, 1), 20, 1)), 1);
    Test_True("C2 the old skill book ids (101..114) are not items any more", !ds_map_exists(global.item_db, 101) && !ds_map_exists(global.item_db, 114) && ItemDB_Get(101).id == 0);
}

// Data integrity over the GML databases (VER-11; R-003, R-004). ds_map_add silently drops a repeated key, so a
// duplicate id shows up as a wrong record count; counts come from balance-data.md (23 items after the skill books went with D18, 27 skills + 4 of packet B4, 15 statuses (14 + Braced), 10 enemies).
function Test_Suite_Data() {
    GameState_Get();
    ItemDB_Init(); SkillDB_Init(); StatusDB_Init(); EnemyDB_Init(); Loot_Init();
    Test_Eq("item count == 34 (23 + 4 throwables + 7 accessories, C3; no lost duplicate ids)", ds_map_size(global.item_db), 34);
    Test_Eq("skill count == 31 (27 + Regrow, Snuff, Gore, Pale Hymn of packet B4)", ds_map_size(global.skill_db), 31);
    Test_Eq("status count == 15 (14 + Braced of the Guard command, D1a)", ds_map_size(global.status_db), 15);
    Test_Eq("enemy count == 10", ds_map_size(global.enemy_db), 10);
    var _bad = 0; var _names = {}; var _dupnames = 0;
    var _key = ds_map_find_first(global.item_db);
    while (!is_undefined(_key)) {
        var _it = ItemDB_Get(_key);
        if (_it.id != _key) _bad++;
        if (variable_struct_exists(_names, string(_it.name))) _dupnames++;
        variable_struct_set(_names, string(_it.name), true);
        if (_it.use.status != -1 && StatusDB_Get(_it.use.status).id != _it.use.status) _bad++;
        _key = ds_map_find_next(global.item_db, _key);
    }
    Test_Eq("every item id matches its record; item statuses resolve", _bad, 0);
    Test_Eq("R-003 no two items share a display name", _dupnames, 0);
    var _sbad = 0;
    for (var _s = 1; _s <= 27; _s++) {
        var _sk = SkillDB_Get(_s);
        if (_sk.id != _s) { _sbad++; continue; }
        if (_sk.status != -1 && StatusDB_Get(_sk.status).id != _sk.status) _sbad++;
        if (variable_struct_exists(_sk, "status_list")) {
            for (var _j = 0; _j < array_length(_sk.status_list); _j++) {
                if (StatusDB_Get(_sk.status_list[_j]).id != _sk.status_list[_j]) _sbad++;
            }
        }
    }
    Test_Eq("skills 1..27 exist and their status ids resolve", _sbad, 0);
    var _stbad = 0;
    for (var _t = 0; _t <= 13; _t++) if (StatusDB_Get(_t).id != _t) _stbad++;
    Test_Eq("statuses 0..13 exist", _stbad, 0);
    // R-004: every ENEMY_* macro creates an enemy whose skills and loot_key resolve.
    var _enemies = [ENEMY_SLIME, ENEMY_DIREWOLF, ENEMY_GHOSTSWORD, ENEMY_SPIDER, ENEMY_MADWHISP, ENEMY_SNAKE, ENEMY_KILLER_PLANT, ENEMY_STRANGER, ENEMY_MINI_BOSS, ENEMY_FINAL_BOSS];
    for (var _e = 0; _e < array_length(_enemies); _e++) {
        var _cfg = EnemyDB_Get(_enemies[_e]);
        var _foe = EnemyCreate(_enemies[_e]);
        var _ebad = 0;
        if (_cfg.id != _enemies[_e] || _foe.id != _enemies[_e] || _foe.max_hp < 1) _ebad++;
        for (var _k = 0; _k < array_length(_cfg.skills); _k++) if (SkillDB_Get(_cfg.skills[_k]).id != _cfg.skills[_k]) _ebad++;
        if (!ds_map_exists(global.loot_configs, _cfg.loot_key)) _ebad++;
        Test_Eq("R-004 enemy " + string(_enemies[_e]) + " (" + string(_cfg.name) + ") creates, skills and loot_key resolve", _ebad, 0);
    }
    // R-004: loot configs point at real tables, and table rows point at real items.
    var _cbad = 0;
    var _ck = ds_map_find_first(global.loot_configs);
    while (!is_undefined(_ck)) {
        var _lc = global.loot_configs[? _ck];
        if (!variable_struct_exists(_lc, "mode") && !ds_map_exists(global.loot_tables, _lc.table)) _cbad++;
        _ck = ds_map_find_next(global.loot_configs, _ck);
    }
    Test_Eq("R-004 every loot config names an existing table", _cbad, 0);
    var _tk = ds_map_find_first(global.loot_tables);
    while (!is_undefined(_tk)) {
        var _tab = global.loot_tables[? _tk];
        var _tbad = 0;
        for (var _n = 0; _n < array_length(_tab); _n++) {
            var _row = _tab[_n];
            if (ItemDB_Get(_row.item_id).id != _row.item_id || _row.weight <= 0 || _row.qty_min > _row.qty_max) _tbad++;
        }
        Test_Eq("R-004 loot table '" + string(_tk) + "' rows resolve (item exists, weight > 0, qty_min <= qty_max)", _tbad, 0);
        _tk = ds_map_find_next(global.loot_tables, _tk);
    }
    // D108 F1a: equip passives are assigned once, and localized names still follow the language (ItemDB_Get runs every frame in a battle menu)
    var _p1 = ItemDB_Get(1).passive_params;
    variable_struct_set(_p1, "f1a_probe", 7);
    for (var _g = 0; _g < 300; _g++) ItemDB_Get(1);
    Test_True("F1a ItemDB_Get(1).passive_params is the same struct on every call", ItemDB_Get(1).passive_params == _p1 && variable_struct_exists(ItemDB_Get(1).passive_params, "f1a_probe"));
    variable_struct_remove(_p1, "f1a_probe");
    var _lang1 = Loc_GetLanguage();
    Loc_SetLanguage("en");
    Test_Eq("F1a item 1 name (en)", ItemDB_Get(1).name, "Wooden Sword");
    Test_Eq("F1a item 1 passive name (en)", ItemDB_Get(1).passive_desc[0], "Steady Strike");
    Loc_SetLanguage("ko");
    Test_Eq("F1a item 1 name follows Loc_SetLanguage(ko)", ItemDB_Get(1).name, Loc_GetRaw("item.name.1", "ko"));
    Test_Eq("F1a item 1 passive name follows Loc_SetLanguage(ko)", ItemDB_Get(1).passive_desc[0], Loc_GetRaw("item.passive.name.1", "ko"));
    Test_True("F1a the ko item name is not the English one", ItemDB_Get(1).name != "Wooden Sword");
    Loc_SetLanguage("en");
    Test_Eq("F1a item 1 name back to en", ItemDB_Get(1).name, "Wooden Sword");
    Loc_SetLanguage(_lang1);
    var _t0 = get_timer();
    for (var _g = 0; _g < 1000; _g++) ItemDB_Get(1);
    Test_Log("[PERF] 1000 x ItemDB_Get(1): " + string(get_timer() - _t0) + " us");
}

// -exportdata (B1, spec section 9): the data the simulator reads. Built in memory here (the real file is written and re-read by `-Only exportdata`).
function Test_Suite_Export() {
    var _d = Export_Build();
    var _back = json_parse(json_stringify(_d));
    Test_True("Export: the data survives a JSON round trip", is_struct(_back) && _back.version == 1);
    Test_Eq("Export: 4 classes", array_length(_back.classes), 4);
    Test_Eq("Export: 10 enemies", array_length(_back.enemies), 10);
    Test_Eq("Export: 31 skills (27 + the 4 of packet B4)", array_length(_back.skills), 31);
    Test_Eq("Export: 34 items (C3 adds 4 throwables and 7 accessories)", array_length(_back.items), 34);
    Test_Eq("Export: 51 cards (14 skills, 14 upgrades, 20 passives, 3 fallbacks)", array_length(_back.cards), 51);
    Test_Eq("Export: 15 statuses (14 + Braced of the Guard command)", array_length(_back.statuses), 15);
    Test_Eq("Export: 10 level rows", array_length(_back.levels), 10);
    Test_True("Export: class ids are unique", Export_IdsUnique(_back.classes));
    Test_True("Export: enemy ids are unique", Export_IdsUnique(_back.enemies));
    Test_True("Export: skill ids are unique", Export_IdsUnique(_back.skills));
    Test_True("Export: item ids are unique", Export_IdsUnique(_back.items));
    Test_True("Export: status ids are unique", Export_IdsUnique(_back.statuses));
    Test_False("Export: duplicate ids are detected", Export_IdsUnique([{ id: 1 }, { id: 1 }]));
    Test_Eq("Export: level table row 1 needs 12 EXP", _back.levels[0].exp_next, 12);
    Test_Eq("Export: Knight level 10 HP matches the vector (73)", _back.classes[1].by_level[9].hp, 73);
    Test_Eq("Export: constants carry the power scale", _back.constants.power_scale, 2);
    Test_Eq("Export: the final boss exports its basic power (14, D111)", _back.enemies[9].basic_power, 14);
    Test_False("Export: no asset references leak into the data", string_pos("sprite", json_stringify(_back.enemies)) > 0);
    // E1 (balance simulator): the timeline / stagger constants, the QTE bar numbers, each heavy enemy move's defence bar and the floor pools
    Test_Eq("Export E1: timeline gauge max 100", _back.constants.timeline.gauge_max, 100);
    Test_Eq("Export E1: steadfast lasts 2 turns", _back.constants.timeline.steadfast_turns, 2);
    Test_Eq("Export E1: a boss is pushed half as far", _back.constants.timeline.boss_push, 0.5);
    Test_Eq("Export E1: BREAK takes +50%", _back.constants.timeline.break_mult, 1.5);
    Test_Eq("Export E1: bow bar sweeps 850 ms", _back.qte.bar_params.bow.sweep_ms, 850);
    Test_Eq("Export E1: a Perfect block lets 25% through", _back.qte.defence_mult.perfect, 0.25);
    Test_Eq("Export E1: nine floor pools", array_length(_back.floors), 9);
    Test_True("Export E1: floor 1 only has the Slime", array_length(_back.floors[0].pool) == 1 && _back.floors[0].pool[0] == ENEMY_SLIME);
    Test_Eq("Export E1: floor 6 draws from 4 enemy types", array_length(_back.floors[5].pool), 4);
    var _ram = undefined;
    for (var _ri = 0; _ri < array_length(_back.skills); _ri++) if (_back.skills[_ri].id == SKILL_RAMMING) _ram = _back.skills[_ri];
    Test_True("Export E1: Ramming carries its defence bar (1500 ms sweep)", is_struct(_ram) && variable_struct_exists(_ram, "defence") && _ram.defence.sweep_ms == 1500);
}

// Save: SAVE-05 and the R-008 round trip. Never touches savedata*.sav: the snapshot goes through JSON text only.
// Save_ApplySnapshot also writes settings_config.json, so run it only under the gate wrapper (redirected save area).
function Test_Suite_Save() {
    var _threw = false; var _v = 0;
    try { _v = Save_ToReal("abc", 7); } catch (_e) { _threw = true; }
    Test_False("SAVE-05 Save_ToReal('abc') does not throw", _threw);
    Test_Eq("SAVE-05 Save_ToReal('abc') returns the fallback", _threw ? "threw" : _v, 7);
    Test_Eq("Save_ToReal('12.5') == 12.5", Save_ToReal("12.5", 0), 12.5);
    Test_Eq("Save_ToReal(5) == 5", Save_ToReal(5, 0), 5);
    var _bad = false;
    try { Save_IsCurrentSnapshot({ save_version: "abc", statData: {} }); } catch (_e2) { _bad = true; }
    Test_False("R-019 a snapshot with text save_version is rejected without throwing", _bad);
    Test_False("R-019 old save_version 1 is not current", Save_IsCurrentSnapshot({ save_version: 1, statData: {} }));
    Test_True("current save_version is accepted", Save_IsCurrentSnapshot({ save_version: SAVE_SNAPSHOT_VERSION, statData: {} }));

    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);
    var _p = CharacterCreate_Player(CLASS_MAGE);
    _p.level = 3; _p.exp = 5;
    _p = Player_NormalizeProgression(_p, true);
    _p.hp = 7; _p.mp = 4;
    _p.skills = [SKILL_FIREBALL];
    _p.inventory = Inv_Add(_p.inventory, 11, 2);
    _p = Status_Add(_p, STATUS_POISON, 0, 0, 3);
    _gs.player_ch = _p;
    _gs.selected_class = CLASS_MAGE;
    _gs.flags = { test_flag: 42 };
    Difficulty_SetCurrent(DIFFICULTY_HARD);
    var _snap = Save_BuildSnapshot();
    Test_True("R-008 built snapshot is the current format", Save_IsCurrentSnapshot(_snap));
    var _back = json_parse(json_stringify(_snap));
    Test_True("R-008 snapshot survives JSON text", Save_IsCurrentSnapshot(_back));
    _gs.selected_class = CLASS_KNIGHT; _gs.flags = {}; _gs.difficulty = DIFFICULTY_NORMAL;
    Save_ApplySnapshot(_back);
    var _r = _gs.player_ch;
    Test_Eq("R-008 round trip keeps class", _r.class_id, CLASS_MAGE);
    Test_Eq("R-008 round trip keeps level", _r.level, 3);
    Test_Eq("R-008 round trip keeps HP", _r.hp, 7);
    Test_Eq("R-008 round trip keeps MP", _r.mp, 4);
    Test_Eq("R-008 round trip keeps EXP", _r.exp, 5);
    Test_True("R-008 round trip keeps skills", array_length(_r.skills) == 1 && _r.skills[0] == SKILL_FIREBALL);
    Test_True("R-008 round trip keeps inventory (MP potion x2)", Inv_Has(_r.inventory, 11, 2));
    Test_True("R-008 round trip keeps Poison with 3 stacks", Status_Has(_r, STATUS_POISON) && _r.status[0].stacks == 3 && _r.status[0].turns == 3);
    Test_Eq("R-008 round trip keeps selected class", _gs.selected_class, CLASS_MAGE);
    Test_Eq("R-008 round trip keeps flags", variable_struct_get(_gs.flags, "test_flag"), 42);
    Test_Eq("R-008 round trip keeps difficulty", _gs.difficulty, DIFFICULTY_HARD);
}

// ---- SAVE-04 atomic save ----------------------------------------------------------------------
// Uses test-only file names in the save area (never savedata*.sav / settings_config.json), so even a run outside the
// gate wrapper cannot touch a real save. "Crashes" are simulated by writing the broken files by hand.
function Test_RawWrite(_path, _text) {
    var _b = buffer_create(string_length(_text) + 1, buffer_fixed, 1);
    buffer_write(_b, buffer_string, _text);
    buffer_save(_b, _path);
    buffer_delete(_b);
}

function Test_RawRead(_path) {
    if (!file_exists(_path)) return "";
    var _b = buffer_load(_path);
    var _t = buffer_read(_b, buffer_string);
    buffer_delete(_b);
    return _t;
}

function Test_SnapText(_marker) {
    return json_stringify({ save_version: SAVE_SNAPSHOT_VERSION, statData: { marker: _marker } });
}

function Test_SnapMarker(_snap) {
    if (!is_struct(_snap)) return "none";
    return string(_snap.statData.marker);
}

function Test_Suite_SaveAtomic() {
    var _p = "test_atomic.sav";
    Save_DeleteFileSet(_p);
    Test_False("atomic: clean start, no main file", file_exists(_p));

    // First save: file written, no leftovers, nothing to back up yet.
    Test_True("atomic: first write reports success", Save_WriteFileAtomic(_p, Test_SnapText("A"), Save_IsCurrentSnapshot));
    Test_Eq("atomic: first write loads back", Test_SnapMarker(Save_LoadSnapshotFile(_p)), "A");
    Test_False("atomic: no .tmp left after a write", file_exists(_p + ".tmp"));
    Test_False("atomic: first write makes no .bak", file_exists(_p + ".bak"));

    // Second save: the previous good save is kept as .bak.
    Test_True("atomic: second write reports success", Save_WriteFileAtomic(_p, Test_SnapText("B"), Save_IsCurrentSnapshot));
    Test_Eq("atomic: second write loads back", Test_SnapMarker(Save_LoadSnapshotFile(_p)), "B");
    Test_Eq("atomic: .bak holds the previous good save", Test_SnapMarker(json_parse(Test_RawRead(_p + ".bak"))), "A");
    Test_False("atomic: no .tmp left after the second write", file_exists(_p + ".tmp"));

    // A write whose verification fails leaves the good save alone and cleans up its temp file.
    Test_False("atomic: a write that fails verification reports failure", Save_WriteFileAtomic(_p, "{ not a snapshot", Save_IsCurrentSnapshot));
    Test_Eq("atomic: failed verification keeps the good save", Test_SnapMarker(Save_LoadSnapshotFile(_p)), "B");
    Test_False("atomic: failed verification leaves no .tmp", file_exists(_p + ".tmp"));
    Test_Eq("atomic: failed verification leaves .bak alone", Test_SnapMarker(json_parse(Test_RawRead(_p + ".bak"))), "A");

    // A crash while writing: a leftover .tmp (complete or half-written) never replaces the good save.
    Test_RawWrite(_p + ".tmp", Test_SnapText("CRASH"));
    Test_Eq("atomic: a leftover complete .tmp does not replace the save", Test_SnapMarker(Save_LoadSnapshotFile(_p)), "B");
    Test_RawWrite(_p + ".tmp", string_copy(Test_SnapText("CRASH"), 1, 20));
    Test_Eq("atomic: a leftover half-written .tmp does not replace the save", Test_SnapMarker(Save_LoadSnapshotFile(_p)), "B");
    Test_True("atomic: the next write replaces a stale .tmp", Save_WriteFileAtomic(_p, Test_SnapText("C"), Save_IsCurrentSnapshot));
    Test_Eq("atomic: write after a stale .tmp loads back", Test_SnapMarker(Save_LoadSnapshotFile(_p)), "C");
    Test_False("atomic: stale .tmp is gone after the next write", file_exists(_p + ".tmp"));

    // Corrupt main file: truncated, then garbage. Load falls back to .bak (the save before "C", i.e. "B"), no crash.
    var _good = Test_RawRead(_p);
    Test_RawWrite(_p, string_copy(_good, 1, string_length(_good) div 2));
    var _threw = false; var _snap = undefined;
    try { _snap = Save_LoadSnapshotFile(_p); } catch (_e) { _threw = true; }
    Test_False("atomic: a truncated main file does not throw", _threw);
    Test_Eq("atomic: a truncated main file loads from .bak", Test_SnapMarker(_snap), "B");
    Test_RawWrite(_p, " garbage {{{ ]]");
    _threw = false; _snap = undefined;
    try { _snap = Save_LoadSnapshotFile(_p); } catch (_e2) { _threw = true; }
    Test_False("atomic: a garbage main file does not throw", _threw);
    Test_Eq("atomic: a garbage main file loads from .bak", Test_SnapMarker(_snap), "B");

    // Both files bad: no snapshot, no crash.
    Test_RawWrite(_p + ".bak", "also garbage");
    _threw = false; _snap = 1;
    try { _snap = Save_LoadSnapshotFile(_p); } catch (_e3) { _threw = true; }
    Test_False("atomic: main and .bak both corrupt does not throw", _threw);
    Test_False("atomic: main and .bak both corrupt gives no snapshot", is_struct(_snap));

    // Deleting a save removes its backup too, so a deleted slot cannot come back from .bak.
    Test_RawWrite(_p + ".tmp", "x");
    Save_DeleteFileSet(_p);
    Test_True("atomic: delete removes main, .bak and .tmp", !file_exists(_p) && !file_exists(_p + ".bak") && !file_exists(_p + ".tmp"));

    // settings_config.json takes the same path: write twice, corrupt, read from .bak.
    var _s = "test_settings.json";
    Save_DeleteFileSet(_s);
    Save_WriteSettingsConfig({ audio_bgm: 0.25 }, _s);
    Save_WriteSettingsConfig({ audio_bgm: 0.75 }, _s);
    var _cfg = Save_ReadSettingsConfig(_s);
    Test_Eq("atomic settings: latest value read back", is_struct(_cfg) ? _cfg.audio_bgm : -1, 0.75);
    Test_False("atomic settings: no .tmp left", file_exists(_s + ".tmp"));
    Test_RawWrite(_s, "{\"vol_bgm\": 0.7");
    _threw = false; _cfg = undefined;
    try { _cfg = Save_ReadSettingsConfig(_s); } catch (_e4) { _threw = true; }
    Test_False("atomic settings: a truncated file does not throw", _threw);
    Test_Eq("atomic settings: a truncated file reads the previous good settings", is_struct(_cfg) ? _cfg.audio_bgm : -1, 0.25);
    Save_DeleteFileSet(_s);
    Test_Eq("atomic settings: nothing to read after delete", is_undefined(Save_ReadSettingsConfig(_s)), true);
}

// BUG-27: a fresh character starts at full HP/MP with real numbers; no 9999 placeholder survives creation.
function Test_Suite_Player() {
    var _classes = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];
    for (var _i = 0; _i < array_length(_classes); _i++) {
        var _c = CharacterCreate_Player(_classes[_i]);
        var _n = "BUG-27 class " + string(_classes[_i]);
        Test_Eq(_n + " starts at full HP", _c.hp, _c.max_hp);
        Test_Eq(_n + " starts at full MP", _c.mp, _c.max_mp);
        Test_True(_n + " HP is a real value (< 1000)", _c.hp < 1000 && _c.hp >= 1);
        Test_True(_n + " MP is a real value (< 1000)", _c.mp < 1000 && _c.mp >= 0);
    }
}

// LOC-03: player-facing messages come from the localization table. Korean expectations are read from the table itself
// (Loc_GetRaw ... "ko"); English wording is pinned so the move to keys does not change what English players see.
function Test_Suite_Loc() {
    var _lang0 = Loc_GetLanguage();
    Loc_SetLanguage("ko");
    var _k = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL);
    Test_Eq("LOC-03 Equip_CanEquip refusal follows the language (ko)", Equip_CanEquip(_k, 0).msg, Loc_GetRaw("menu.msg.cant_equip", "ko"));
    Test_True("LOC-03 ko refusal is not the English text", Equip_CanEquip(_k, 0).msg != "Can't equip that.");
    Loc_SetLanguage("en");
    Test_Eq("LOC-03 Equip_CanEquip refusal (en)", Equip_CanEquip(_k, 0).msg, "Can't equip that.");
    Test_Eq("LOC-03 Equip_CanEquip item not owned (en)", Equip_CanEquip(_k, 2).msg, "Item not in inventory.");
    _k.inventory = Inv_Add(_k.inventory, 2, 1);
    var _can = Equip_CanEquip(_k, 2);
    Test_True("LOC-03 Equip_CanEquip owned weapon is ok", _can.ok);
    Test_Eq("LOC-03 Equip_CanEquip success text (en)", _can.msg, "Equipped " + string(_can.item.name) + ".");
    // Auto-resolve result line: exp, level up, loot.
    var _msg = Enemy_AutoResolveBuildMessage({ name: "Slime" }, { exp_gain: 5, levels_gained: 1, loot_gained: true });
    Test_Eq("LOC-03 auto-resolve line (en)", _msg, "You overpower Slime. (+5 EXP) Level up x1! Loot gained.");
    Test_Eq("LOC-03 auto-resolve max level line (en)", Enemy_AutoResolveBuildMessage({ name: "Slime" }, { at_level_cap: true }), "You overpower Slime. Max level reached.");
    // New LOC-03 rows resolve in Korean (not the English fallback).
    Loc_SetLanguage("ko");
    Test_Eq("LOC-03 max-level row resolves in ko", Loc_T("combat.msg.max_level", "Max level reached."), Loc_GetRaw("combat.msg.max_level", "ko"));
    Test_True("LOC-03 max-level ko row differs from English", Loc_GetRaw("combat.msg.max_level", "ko") != "Max level reached.");
    Test_True("LOC-03 ko auto-resolve loot line is not English", string_pos("Loot gained.", Enemy_AutoResolveBuildMessage({ name: "Slime" }, { loot_gained: true })) == 0);
    // BUG-08: the poison / burn / bleed tick line has a Korean row that keeps both placeholders.
    var _tick_ko = Loc_GetRaw("combat.msg.status_tick", "ko");
    Test_True("BUG-08 status_tick ko row is not the English text", _tick_ko != "" && _tick_ko != "{status} hurts you for {dmg}.");
    Test_True("BUG-08 status_tick ko row keeps {status} and {dmg}", string_pos("{status}", _tick_ko) > 0 && string_pos("{dmg}", _tick_ko) > 0);
    Loc_SetLanguage("en");
    Test_Eq("BUG-08 status_tick (en)", Loc_T("combat.msg.status_tick", "x", { status: "Poison", dmg: 2 }), "Poison hurts you for 2.");
    Loc_SetLanguage(_lang0);
    // The save confirmation uses the existing dialogue key sys_save_ok (scr_dialogue.gml).
    Loc_SetLanguage("ko");
    Test_Eq("LOC-03 save-ok text follows the language (ko)", Save_SuccessText(), Loc_GetRaw("dialogue.sys_save_ok.0", "ko"));
    Loc_SetLanguage("en");
    Test_Eq("LOC-03 save-ok text (en)", Save_SuccessText(), "Game saved.");
    Loc_SetLanguage(_lang0);
}


// DISP-03: Display_CalcLayout is pure. Expected values follow the rule in .planning/research/resolution-gamemaker.md 1.2 and 7.1:
// scale = max(1, floor(min(win_w / 160, win_h / 144))), game rectangle centred, offsets rounded down (GML div, windows >= base).
// The UI rule (D8, display-design.md): ui_scale is the integer u whose grid width game_w / u is closest to 640 (compared as a ratio).
function Test_DisplayCase(_w, _h, _scale, _x, _y) {
    var _n = "DISP-03 " + string(_w) + "x" + string(_h);
    var _l = Display_CalcLayout(_w, _h);
    Test_Eq(_n + " scale", _l.scale, _scale);
    Test_Eq(_n + " game_w", _l.game_w, 160 * _scale);
    Test_Eq(_n + " game_h", _l.game_h, 144 * _scale);
    Test_Eq(_n + " game_x", _l.game_x, _x);
    Test_Eq(_n + " game_y", _l.game_y, _y);
}

function Test_Suite_Display() {
    // Window sizes from resolution-gamemaker.md 7.1 (arithmetic redone: 481x433 is scale 3, not 2).
    Test_DisplayCase(160, 144, 1, 0, 0);
    Test_DisplayCase(320, 288, 2, 0, 0);
    Test_DisplayCase(480, 432, 3, 0, 0);
    Test_DisplayCase(1280, 720, 5, 240, 0);
    Test_DisplayCase(1920, 1080, 7, 400, 36);
    Test_DisplayCase(2560, 1440, 10, 480, 0);
    Test_DisplayCase(3840, 2160, 15, 720, 0);
    Test_DisplayCase(3440, 1440, 10, 920, 0);
    Test_DisplayCase(1920, 1200, 8, 320, 24);
    Test_DisplayCase(1024, 768, 5, 112, 24);
    Test_DisplayCase(600, 1000, 3, 60, 284);
    Test_DisplayCase(481, 433, 3, 0, 0);
    Test_DisplayCase(479, 431, 2, 79, 71);
    Test_DisplayCase(319, 287, 1, 79, 71);
    Test_DisplayCase(1919, 1079, 7, 399, 35);
    // Smaller than the base: scale never drops below 1; the picture is cropped evenly, not shrunk.
    Test_DisplayCase(100, 100, 1, -30, -22);
    Test_Eq("DISP-03 0x0 window is clamped, scale 1", Display_CalcLayout(0, 0).scale, 1);

    // Windowed cap (the Settings scale row) applies only when not fullscreen.
    var _c = Display_CalcLayout(1920, 1080, 160, 144, false, 5);
    Test_Eq("DISP-03 windowed cap 5: scale", _c.scale, 5);
    Test_Eq("DISP-03 windowed cap 5: game_x", _c.game_x, 560);
    Test_Eq("DISP-03 windowed cap 5: game_y", _c.game_y, 180);
    _c = Display_CalcLayout(1920, 1080, 160, 144, true, 5);
    Test_Eq("DISP-03 fullscreen ignores the cap", _c.scale, 7);
    _c = Display_CalcLayout(1920, 1080, 160, 144, false, 99);
    Test_Eq("DISP-03 cap above the fit changes nothing", _c.scale, 7);

    // The base size is a parameter, not a baked-in 160x144.
    _c = Display_CalcLayout(1000, 1000, 100, 50);
    Test_Eq("DISP-03 base 100x50 in 1000x1000: scale", _c.scale, 10);
    Test_Eq("DISP-03 base 100x50 in 1000x1000: game_y", _c.game_y, 250);

    // D8 UI grid: windowed 3/4/5 give 480x432, 640x576 (the 4x grid), 800x720; 1080p fullscreen halves to 560x504.
    var _ui = [[3, 1, 480, 432], [4, 1, 640, 576], [5, 1, 800, 720], [6, 2, 480, 432], [7, 2, 560, 504], [9, 2, 720, 648],
               [10, 3, 533, 480], [13, 3, 693, 624], [14, 4, 560, 504], [15, 4, 600, 540]];
    for (var _i = 0; _i < array_length(_ui); _i++) {
        var _r = _ui[_i];
        var _l = Display_CalcLayout(160 * _r[0], 144 * _r[0]);
        var _n = "DISP-09 scale " + string(_r[0]);
        Test_Eq(_n + " ui_scale", _l.ui_scale, _r[1]);
        Test_Eq(_n + " gui_w", _l.gui_w, _r[2]);
        Test_Eq(_n + " gui_h", _l.gui_h, _r[3]);
    }
    // gui_x/gui_y: where GUI (0,0) sits in the window. It is always the picture's top-left corner; when ui_scale does not
    // divide the picture, the 1-2 spare pixels are on the right/bottom (so the surface blit in GUI space is at exactly 0,0).
    _c = Display_CalcLayout(1920, 1080);
    Test_Eq("DISP-09 1080p gui_x", _c.gui_x, 400);
    Test_Eq("DISP-09 1080p gui_y", _c.gui_y, 36);
    _c = Display_CalcLayout(2560, 1440);
    Test_Eq("DISP-09 1440p ui_scale", _c.ui_scale, 3);
    Test_Eq("DISP-09 1440p gui_x", _c.gui_x, 480);
    Test_Eq("DISP-09 1440p gui_y", _c.gui_y, 0);
    _c = Display_CalcLayout(1760, 1584);   // scale 11, ui_scale 3: 1760 = 586 * 3 + 2 spare pixels
    Test_Eq("DISP-09 1760x1584 gui_w", _c.gui_w, 586);
    Test_Eq("DISP-09 1760x1584 gui_x stays at the picture corner", _c.gui_x, 0);
    Test_Eq("DISP-09 1760x1584 gui_h", _c.gui_h, 528);

    // Display_WindowRectInGui: the whole window in GUI units (fades and dims must cover the black bars too).
    _c = Display_CalcLayout(1920, 1080);   // GUI origin at window (400,36), 2 window px per GUI unit
    var _wr = Display_WindowRectInGui(_c);
    Test_Eq("DISP-09 window rect in gui: x", _wr.x, -200);
    Test_Eq("DISP-09 window rect in gui: y", _wr.y, -18);
    Test_Eq("DISP-09 window rect in gui: w", _wr.w, 960);
    Test_Eq("DISP-09 window rect in gui: h", _wr.h, 540);
    _c = Display_CalcLayout(480, 432);
    _wr = Display_WindowRectInGui(_c);
    Test_Eq("DISP-09 window rect in gui, no bars: x", _wr.x, 0);
    Test_Eq("DISP-09 window rect in gui, no bars: w", _wr.w, 480);

    // Display_MaxScale: the largest whole-number scale a monitor/window area allows (never below 1).
    Test_Eq("DISP-03 MaxScale 2560x1440", Display_MaxScale(2560, 1440), 10);
    Test_Eq("DISP-03 MaxScale 1366x768", Display_MaxScale(1366, 768), 5);
    Test_Eq("DISP-03 MaxScale 100x100", Display_MaxScale(100, 100), 1);

    // Display_NeedsRelayout (DISP-08): true only when the window size or fullscreen flag really differs.
    var _a = Display_CalcLayout(1920, 1080);
    Test_Eq("DISP-08 same size, same mode: no relayout", Display_NeedsRelayout(_a, 1920, 1080, false), false);
    Test_Eq("DISP-08 other width: relayout", Display_NeedsRelayout(_a, 1921, 1080, false), true);
    Test_Eq("DISP-08 other height: relayout", Display_NeedsRelayout(_a, 1920, 1079, false), true);
    Test_Eq("DISP-08 fullscreen flag flips: relayout", Display_NeedsRelayout(_a, 1920, 1080, true), true);
    Test_Eq("DISP-08 no layout yet: relayout", Display_NeedsRelayout(undefined, 1920, 1080, false), true);

    // Display_WorldToGui: world point -> GUI coordinates (QTE targets, shake, HUD that follows a sprite). One world pixel = scale / ui_scale GUI units.
    _c = Display_CalcLayout(1920, 1080);   // scale 7, ui_scale 2 -> 3.5 GUI units per world pixel
    var _p = Display_WorldToGui(_c, 80, 72, 0, 0);
    Test_Eq("DISP-09 world centre -> gui x", _p.x, 280);
    Test_Eq("DISP-09 world centre -> gui y", _p.y, 252);
    _p = Display_WorldToGui(_c, 100, 90, 20, 18);   // camera at (20,18): 80,72 on screen
    Test_Eq("DISP-09 camera offset is subtracted", _p.x, 280);
    Test_Eq("DISP-09 camera offset is subtracted (y)", _p.y, 252);
    _c = Display_CalcLayout(480, 432);     // scale 3, ui_scale 1 -> 3 GUI units per world pixel
    _p = Display_WorldToGui(_c, 10, 5, 0, 0);
    Test_Eq("DISP-09 windowed 3x world -> gui x", _p.x, 30);
    Test_Eq("DISP-09 windowed 3x world -> gui y", _p.y, 15);

    // Display_WindowSizeForScale: the windowed size the Settings scale row asks for.
    var _wsz = Display_WindowSizeForScale(4);
    Test_Eq("DISP-03 window for scale 4: w", _wsz.w, 640);
    Test_Eq("DISP-03 window for scale 4: h", _wsz.h, 576);

    // Display_RequestStep (DISP-05/08/11): the pure state machine behind Settings Apply. One call per frame; returns { req, cmd }.
    // cmd.kind is "none", "fullscreen" (set the flag, then wait: it lands over several frames) or "size" (set the window size and re-centre).
    var _obs = { fullscreen: false, win_w: 480, win_h: 432 };
    var _q = Display_RequestNew(false, 480, 432);
    var _st = Display_RequestStep(_q, _obs);
    Test_Eq("DISP-08 request already satisfied: no command", _st.cmd.kind, "none");
    Test_Eq("DISP-08 request already satisfied: done at once (no window call, so no re-centre)", _st.req.phase, "done");

    _q = Display_RequestNew(false, 640, 576);   // scale 3 -> 4
    _st = Display_RequestStep(_q, _obs);
    Test_Eq("DISP-05 size change: command is size", _st.cmd.kind, "size");
    Test_Eq("DISP-05 size change: w", _st.cmd.w, 640);
    Test_Eq("DISP-05 size change: h", _st.cmd.h, 576);
    Test_Eq("DISP-05 size change: centres the window", _st.cmd.center, true);
    Test_Eq("DISP-05 size change: waits for the window", _st.req.phase, "size");
    _q = _st.req;
    _st = Display_RequestStep(_q, _obs);   // the window has not changed yet
    Test_Eq("DISP-05 size change: no second command while waiting", _st.cmd.kind, "none");
    Test_Eq("DISP-05 size change: still waiting", _st.req.phase, "size");
    _q = _st.req;
    _obs = { fullscreen: false, win_w: 640, win_h: 576 };   // the window arrived
    _st = Display_RequestStep(_q, _obs);
    Test_Eq("DISP-05 size change: settles one more frame", _st.req.phase, "settle");
    _q = _st.req;
    _st = Display_RequestStep(_q, _obs);
    _q = _st.req;
    _st = Display_RequestStep(_q, _obs);
    Test_Eq("DISP-05 size change: done after the settle frames (the caller lays out once)", _st.req.phase, "done");
    Test_Eq("DISP-05 size change: no command at the end", _st.cmd.kind, "none");

    _q = Display_RequestNew(false, 640, 576);   // the window never gets there: give up after DISPLAY_REQUEST_TIMEOUT frames
    _obs = { fullscreen: false, win_w: 480, win_h: 432 };
    _st = Display_RequestStep(_q, _obs);
    for (var _k = 0; _k < DISPLAY_REQUEST_TIMEOUT + 2; _k++) _st = Display_RequestStep(_st.req, _obs);
    Test_Eq("DISP-05 size change that never lands times out", _st.req.phase, "done");

    // Fullscreen on: set the flag, wait at least DISPLAY_FS_WAIT frames and for the flag, then done (no size command: the window is the display).
    _q = Display_RequestNew(true, 480, 432);
    _obs = { fullscreen: false, win_w: 480, win_h: 432 };
    _st = Display_RequestStep(_q, _obs);
    Test_Eq("DISP-05 fullscreen on: command", _st.cmd.kind, "fullscreen");
    Test_Eq("DISP-05 fullscreen on: flag", _st.cmd.fullscreen, true);
    _q = _st.req;
    _obs = { fullscreen: true, win_w: 1920, win_h: 1080 };
    for (var _k = 0; _k < DISPLAY_FS_WAIT - 1; _k++) {
        _st = Display_RequestStep(_q, _obs);
        _q = _st.req;
    }
    Test_Eq("DISP-05 fullscreen on: still waiting before DISPLAY_FS_WAIT frames", _q.phase, "fs");
    _st = Display_RequestStep(_q, _obs);
    Test_Eq("DISP-05 fullscreen on: no size command, the window is the display", _st.cmd.kind, "none");
    Test_Eq("DISP-05 fullscreen on: done", _st.req.phase, "done");

    // Fullscreen off: clear the flag, wait, then put the windowed size back and re-centre, then done.
    _q = Display_RequestNew(false, 640, 576);
    _obs = { fullscreen: true, win_w: 1920, win_h: 1080 };
    _st = Display_RequestStep(_q, _obs);
    Test_Eq("DISP-05 fullscreen off: command", _st.cmd.kind, "fullscreen");
    Test_Eq("DISP-05 fullscreen off: flag", _st.cmd.fullscreen, false);
    _q = _st.req;
    _obs = { fullscreen: false, win_w: 1920, win_h: 1080 };   // flag has changed, window still has the old size
    var _got_size = false;
    for (var _k = 0; _k < DISPLAY_FS_WAIT + 3; _k++) {
        _st = Display_RequestStep(_q, _obs);
        _q = _st.req;
        if (_st.cmd.kind == "size") { _got_size = true; Test_Eq("DISP-05 fullscreen off: windowed size is 640", _st.cmd.w, 640); Test_Eq("DISP-05 fullscreen off: re-centres", _st.cmd.center, true); break; }
    }
    Test_Eq("DISP-05 fullscreen off: issues the windowed size", _got_size, true);

    // Five fast toggles: every request is its own state machine; none of them can leave the flag stuck. The last request wins.
    var _fs = false;
    for (var _k = 0; _k < 5; _k++) {
        var _rq = Display_RequestNew(!_fs, 480, 432);
        var _o2 = { fullscreen: _fs, win_w: 480, win_h: 432 };
        var _s2 = Display_RequestStep(_rq, _o2);
        Test_Eq("DISP-05 toggle " + string(_k) + " asks for the opposite flag", _s2.cmd.fullscreen, !_fs);
        _fs = !_fs;
    }
    Test_Eq("DISP-05 five toggles end fullscreen", _fs, true);
}


// D91 / I-054 / DISP-11 / DISP-14: window modes. Expected rectangles are worked out by hand from the spec: windowed = the Settings scale
// (clamped to what the monitor holds, leaving DISPLAY_WINDOW_MARGIN_H = 80 px of height for title bar and taskbar), centred, with a border;
// borderless = the whole monitor at 0,0 with no border and NOT exclusive; exclusive = the fullscreen flag.
function Test_Suite_WindowModes() {
    // Windowed scale choices that fit a monitor: scale s needs 160 s <= width and 144 s + 80 <= height.
    Test_Eq("D91 max windowed scale 1920x1080 (144*6+80=944 fits, 7 does not)", Display_WindowedMaxScale(1920, 1080), 6);
    Test_Eq("D91 max windowed scale 2560x1440", Display_WindowedMaxScale(2560, 1440), 9);
    Test_Eq("D91 max windowed scale 3840x2160", Display_WindowedMaxScale(3840, 2160), 14);
    Test_Eq("D91 max windowed scale 1366x768", Display_WindowedMaxScale(1366, 768), 4);
    Test_Eq("D91 max windowed scale 640x480", Display_WindowedMaxScale(640, 480), 2);
    Test_Eq("D91 max windowed scale 100x100 never below 1", Display_WindowedMaxScale(100, 100), 1);
    var _ch = Display_WindowedScales(1920, 1080);
    Test_Eq("D91 choices at 1080p: count", array_length(_ch), 4);
    Test_Eq("D91 choices at 1080p: first", _ch[0], 3);
    Test_Eq("D91 choices at 1080p: last", _ch[array_length(_ch) - 1], 6);
    _ch = Display_WindowedScales(640, 480);
    Test_Eq("D91 choices on a tiny monitor: the one that fits", array_length(_ch), 1);
    Test_Eq("D91 choices on a tiny monitor: value", _ch[0], 2);

    // The target rectangle (mode, monitor, scale).
    var _r = Display_TargetRect(WINDOW_MODE_WINDOWED, 1920, 1080, 4);
    Test_Eq("D91 windowed 4x: w", _r.w, 640);
    Test_Eq("D91 windowed 4x: h", _r.h, 576);
    Test_Eq("D91 windowed 4x: x centred", _r.x, 640);
    Test_Eq("D91 windowed 4x: y centred", _r.y, 252);
    Test_Eq("D91 windowed has a border", _r.border, true);
    Test_Eq("D91 windowed is not fullscreen", _r.fullscreen, false);
    Test_Eq("D91 windowed asks to be centred", _r.center, true);
    _r = Display_TargetRect(WINDOW_MODE_WINDOWED, 1920, 1080, 9);
    Test_Eq("D91 windowed 9x on 1080p is clamped to 6x: w", _r.w, 960);
    Test_Eq("D91 windowed 9x on 1080p is clamped to 6x: h", _r.h, 864);
    _r = Display_TargetRect(WINDOW_MODE_BORDERLESS, 1920, 1080, 4);
    Test_Eq("D91 borderless: x", _r.x, 0);
    Test_Eq("D91 borderless: y", _r.y, 0);
    Test_Eq("D91 borderless: w is the display width", _r.w, 1920);
    Test_Eq("D91 borderless: h is the display height", _r.h, 1080);
    Test_Eq("D91 borderless: no border", _r.border, false);
    Test_Eq("D91 borderless is NOT the exclusive fullscreen flag", _r.fullscreen, false);
    Test_Eq("D91 borderless is placed at 0,0 (not centred)", _r.center, false);
    _r = Display_TargetRect(WINDOW_MODE_BORDERLESS, 2560, 1440, 3);
    Test_Eq("D91 borderless 1440p: w", _r.w, 2560);
    Test_Eq("D91 borderless 1440p: h", _r.h, 1440);
    _r = Display_TargetRect(WINDOW_MODE_EXCLUSIVE, 2560, 1440, 3);
    Test_Eq("D91 exclusive: fullscreen flag", _r.fullscreen, true);
    Test_Eq("D91 exclusive: w", _r.w, 2560);
    Test_Eq("D91 exclusive: h", _r.h, 1440);
    // The picture a mode gives on the same monitor (existing layout rule).
    var _l = Display_CalcLayout(_r.w, _r.h);
    Test_Eq("D91 exclusive 1440p picture scale", _l.scale, 10);
    _l = Display_CalcLayout(1920, 1080);
    Test_Eq("D91 borderless 1080p picture scale", _l.scale, 7);
    Test_Eq("D91 borderless 1080p picture x", _l.game_x, 400);

    // Modes are normalised: unknown values become the default (borderless), reals are rounded and clamped.
    Test_Eq("D91 normalize 0", Display_NormalizeMode(0), WINDOW_MODE_WINDOWED);
    Test_Eq("D91 normalize 2", Display_NormalizeMode(2), WINDOW_MODE_EXCLUSIVE);
    Test_Eq("D91 normalize 7 clamps", Display_NormalizeMode(7), WINDOW_MODE_EXCLUSIVE);
    Test_Eq("D91 normalize -3 clamps", Display_NormalizeMode(-3), WINDOW_MODE_WINDOWED);
    Test_Eq("D91 normalize a string falls back to the default", Display_NormalizeMode("x"), WINDOW_MODE_BORDERLESS);
    Test_Eq("D91 normalize undefined falls back to the default", Display_NormalizeMode(undefined), WINDOW_MODE_BORDERLESS);
    Test_Eq("D91 legacy fit_screen true -> exclusive", Display_ModeFromLegacy(true), WINDOW_MODE_EXCLUSIVE);
    Test_Eq("D91 legacy fit_screen false -> windowed", Display_ModeFromLegacy(false), WINDOW_MODE_WINDOWED);

    // Tests never touch the owner's screen: whatever mode is asked for, a test run is windowed.
    Test_Eq("D91 test run forces windowed (borderless asked)", Display_EffectiveMode(WINDOW_MODE_BORDERLESS, true), WINDOW_MODE_WINDOWED);
    Test_Eq("D91 test run forces windowed (exclusive asked)", Display_EffectiveMode(WINDOW_MODE_EXCLUSIVE, true), WINDOW_MODE_WINDOWED);
    Test_Eq("D91 a normal run keeps the mode", Display_EffectiveMode(WINDOW_MODE_BORDERLESS, false), WINDOW_MODE_BORDERLESS);

    // The request state machine with borderless: border off, the display-sized window at 0,0, no fullscreen flag, no centring.
    var _q = Display_RequestNew(false, 1920, 1080, false, false, 0, 0);
    var _obs = { fullscreen: false, win_w: 640, win_h: 576, border: true };
    var _st = Display_RequestStep(_q, _obs);
    Test_Eq("D91 windowed -> borderless: size command", _st.cmd.kind, "size");
    Test_Eq("D91 windowed -> borderless: border off", _st.cmd.border, false);
    Test_Eq("D91 windowed -> borderless: w", _st.cmd.w, 1920);
    Test_Eq("D91 windowed -> borderless: not centred", _st.cmd.center, false);
    Test_Eq("D91 windowed -> borderless: x", _st.cmd.x, 0);
    Test_Eq("D91 windowed -> borderless: y", _st.cmd.y, 0);
    _obs = { fullscreen: false, win_w: 1920, win_h: 1080, border: true };   // the right size but the border is still on: not satisfied
    _st = Display_RequestStep(Display_RequestNew(false, 1920, 1080, false, false, 0, 0), _obs);
    Test_Eq("D91 right size but border still on: still a command", _st.cmd.kind, "size");
    _obs = { fullscreen: false, win_w: 1920, win_h: 1080, border: false };
    _st = Display_RequestStep(Display_RequestNew(false, 1920, 1080, false, false, 0, 0), _obs);
    Test_Eq("D91 borderless already in place: no command", _st.cmd.kind, "none");
    Test_Eq("D91 borderless already in place: done", _st.req.phase, "done");
    // borderless -> windowed: the border comes back even when the size already matches.
    _obs = { fullscreen: false, win_w: 640, win_h: 576, border: false };
    _st = Display_RequestStep(Display_RequestNew(false, 640, 576, true, true, 640, 252), _obs);
    Test_Eq("D91 borderless -> windowed: size command", _st.cmd.kind, "size");
    Test_Eq("D91 borderless -> windowed: border on", _st.cmd.border, true);
    Test_Eq("D91 borderless -> windowed: centred", _st.cmd.center, true);
    // exclusive -> borderless: the flag goes off first, then the borderless rectangle.
    _q = Display_RequestNew(false, 1920, 1080, false, false, 0, 0);
    _obs = { fullscreen: true, win_w: 1920, win_h: 1080, border: true };
    _st = Display_RequestStep(_q, _obs);
    Test_Eq("D91 exclusive -> borderless: leaves fullscreen first", _st.cmd.kind, "fullscreen");
    Test_Eq("D91 exclusive -> borderless: flag off", _st.cmd.fullscreen, false);
    _q = _st.req;
    _obs = { fullscreen: false, win_w: 1920, win_h: 1080, border: true };
    var _got_border = false;
    for (var _k = 0; _k < DISPLAY_FS_WAIT + 3; _k++) {
        _st = Display_RequestStep(_q, _obs);
        _q = _st.req;
        if (_st.cmd.kind == "size") { _got_border = (_st.cmd.border == false && _st.cmd.x == 0 && _st.cmd.y == 0); break; }
    }
    Test_Eq("D91 exclusive -> borderless: then the borderless rectangle", _got_border, true);
    // borderless -> exclusive: only the flag.
    _obs = { fullscreen: false, win_w: 1920, win_h: 1080, border: false };
    _st = Display_RequestStep(Display_RequestNew(true, 1920, 1080, true, false, 0, 0), _obs);
    Test_Eq("D91 borderless -> exclusive: fullscreen command", _st.cmd.kind, "fullscreen");
    Test_Eq("D91 borderless -> exclusive: flag on", _st.cmd.fullscreen, true);

    // DISP-10: a room narrower than the 160 px view (rm_floor6_5 is 144 wide, the camera sits at x=-16 against the room's right edge):
    // only the part of the picture inside the room is shown, centred; the rest stays black. Wide rooms are left alone.
    var _c = Display_RoomCrop(144, 144, -16, 0, 160, 144);
    Test_Eq("DISP-10 144 wide room, camera -16: source x", _c.sx, 16);
    Test_Eq("DISP-10 144 wide room, camera -16: source width", _c.sw, 144);
    Test_Eq("DISP-10 144 wide room, camera -16: drawn centred (8 px each side)", _c.dx, 8);
    Test_Eq("DISP-10 144 wide room: full height, source y", _c.sy, 0);
    Test_Eq("DISP-10 144 wide room: full height", _c.sh, 144);
    Test_Eq("DISP-10 144 wide room: no vertical move", _c.dy, 0);
    Test_Eq("DISP-10 crop is active for a narrow room", _c.active, true);
    _c = Display_RoomCrop(144, 144, -8, 0, 160, 144);
    Test_Eq("DISP-10 camera already centred: source x", _c.sx, 8);
    Test_Eq("DISP-10 camera already centred: drawn at 8", _c.dx, 8);
    _c = Display_RoomCrop(144, 144, 0, 0, 160, 144);   // camera at the left edge: the room fills 0..144
    Test_Eq("DISP-10 camera at the left edge: source x", _c.sx, 0);
    Test_Eq("DISP-10 camera at the left edge: still centred", _c.dx, 8);
    _c = Display_RoomCrop(321, 175, 50, 23, 160, 144);
    Test_Eq("DISP-10 wide room: no crop", _c.active, false);
    Test_Eq("DISP-10 wide room: full width", _c.sw, 160);
    Test_Eq("DISP-10 wide room: full height", _c.sh, 144);
    Test_Eq("DISP-10 wide room: drawn at 0", _c.dx, 0);
    _c = Display_RoomCrop(160, 144, 0, 0, 160, 144);
    Test_Eq("DISP-10 room equal to the view: no crop", _c.active, false);
    _c = Display_RoomCrop(150, 100, -5, -22, 160, 144);   // narrow and short
    Test_Eq("DISP-10 short room: source y", _c.sy, 22);
    Test_Eq("DISP-10 short room: height", _c.sh, 100);
    Test_Eq("DISP-10 short room: drawn centred", _c.dy, 22);
    // The shift (drawn x minus source x) moves world-to-GUI points of a narrow room so HUD that follows a sprite stays on it.
    var _lay = Display_CalcLayout(480, 432);
    _lay.shift_x = -8;   // 144 wide room, camera -16: source 16, drawn 8
    var _wp = Display_WorldToGui(_lay, 20, 0, 0, 0);   // 3 GUI units per world pixel: (20 - 8) * 3
    Test_Eq("DISP-10 world -> gui includes the narrow-room shift", _wp.x, 36);
}

// D48 / I-055: hold-to-skip. Skip_Step is the pure core: a fresh press arms it, holding confirm for SKIP_HOLD_MS (one step = 1/60 s here, D108 F2b-2) fires it, a tap never does.
function Test_Suite_Skip() {
    var _f60 = Presentation_StepMs(16667);   // D108 F2b-2: the steps are ms now; one 60 fps frame
    var _hold_frames = round(SKIP_HOLD_MS / _f60);   // 60
    var _hint_frames = round(SKIP_HINT_MS / _f60);   // 150
    var _st = Skip_StateNew();
    var _r = Skip_Step(_st, true, true, true, _f60);   // first frame: pressed and held
    Test_Eq("D48 first press: not fired", _r.fired, false);
    Test_Eq("D48 first press: shows the hint", _r.hint > 0, true);
    Test_Eq("D48 first press: progress started", _r.held_ms, _f60);
    _st = _r;
    for (var _i = 2; _i < _hold_frames; _i++) {
        _st = Skip_Step(_st, true, false, true, _f60);
        if (_st.fired) break;
    }
    Test_Eq("D48 held for one frame less than the hold time: not fired", _st.fired, false);
    _st = Skip_Step(_st, true, false, true, _f60);
    Test_Eq("D48 held for the whole hold time: fires", _st.fired, true);
    Test_Eq("D48 firing resets the hold", _st.held_ms, 0);

    // A tap (a few frames, then released) never skips and the count restarts on the next press.
    _st = Skip_StateNew();
    _st = Skip_Step(_st, true, true, true, _f60);
    _st = Skip_Step(_st, true, false, true, _f60);
    _st = Skip_Step(_st, true, false, true, _f60);
    _st = Skip_Step(_st, true, false, false, _f60);   // released
    Test_Eq("D48 tap: not fired", _st.fired, false);
    Test_Eq("D48 tap: hold count back to 0", _st.held_ms, 0);
    Test_Eq("D48 tap: hint stays on screen for a while", _st.hint > 0, true);
    var _fired = false;
    for (var _i = 0; _i < _hold_frames * 3; _i++) {   // many taps, one every 10 frames
        _st = Skip_Step(_st, true, (_i mod 10) == 0, (_i mod 10) < 3, _f60);
        if (_st.fired) _fired = true;
    }
    Test_Eq("D48 repeated taps never skip", _fired, false);

    // A key already held when the scene starts (no new press) never skips.
    _st = Skip_StateNew();
    _fired = false;
    for (var _i = 0; _i < _hold_frames * 2; _i++) {
        _st = Skip_Step(_st, true, false, true, _f60);
        if (_st.fired) _fired = true;
    }
    Test_Eq("D48 a key held from before the scene does not skip", _fired, false);

    // Not allowed (no skippable scene): everything resets.
    _st = Skip_Step(Skip_StateNew(), true, true, true, _f60);
    _st = Skip_Step(_st, false, false, true, _f60);
    Test_Eq("D48 leaving the scene resets the count", _st.held_ms, 0);
    Test_Eq("D48 leaving the scene hides the hint", _st.hint, 0);

    // The hint fades after _hint_frames without a press.
    _st = Skip_Step(Skip_StateNew(), true, true, true, _f60);
    _st = Skip_Step(_st, true, false, false, _f60);
    for (var _i = 0; _i < _hint_frames + 2; _i++) _st = Skip_Step(_st, true, false, false, _f60);
    Test_Eq("D48 the hint goes away", _st.hint, 0);
    Test_Eq("D48 progress fraction", Skip_Fraction(SKIP_HOLD_MS / 2), 0.5);
}

// DISP-14 / SAVE-06 / D91: settings_version 8. Old fit_screen + scale fields become a window mode; a fresh install is borderless.
function Test_SettingsMigrationCase(_name, _json, _want_mode, _want_scale) {
    var _f = "test_settings_mig.json";
    Save_DeleteFileSet(_f);
    Test_RawWrite(_f, _json);
    var _cfg = Save_ReadSettingsConfig(_f);
    Test_True("DISP-14 " + _name + ": file is read", is_struct(_cfg));
    if (is_struct(_cfg)) {
        Test_Eq("DISP-14 " + _name + ": window_mode", _cfg.window_mode, _want_mode);
        Test_Eq("DISP-14 " + _name + ": scale kept", _cfg.display_scale, _want_scale);
        Test_False("DISP-14 " + _name + ": no fit_screen field any more", variable_struct_exists(_cfg, "fit_screen"));
    }
    Save_DeleteFileSet(_f);
}

function Test_Suite_SettingsMigration() {
    // A fresh install (no file, defaults) is borderless fullscreen (D91).
    Test_Eq("D91 defaults: borderless", GameSettings_Defaults().window_mode, WINDOW_MODE_BORDERLESS);
    Test_Eq("D91 normalizing nothing gives borderless", GameSettings_Normalize(undefined).window_mode, WINDOW_MODE_BORDERLESS);
    Test_Eq("D91 normalizing a partial struct keeps the default mode", GameSettings_Normalize({ audio_bgm: 0.5 }).window_mode, WINDOW_MODE_BORDERLESS);
    // Version 7 files (old fit_screen + display_scale).
    Test_SettingsMigrationCase("v7 fit_screen true", "{\"settings_version\":7,\"vol_ui\":1,\"vol_sfx\":1,\"vol_bgm\":1,\"display_scale\":4,\"fit_screen\":true,\"language\":\"en\"}", WINDOW_MODE_EXCLUSIVE, 4);
    Test_SettingsMigrationCase("v7 fit_screen false", "{\"settings_version\":7,\"vol_ui\":1,\"vol_sfx\":1,\"vol_bgm\":1,\"display_scale\":5,\"fit_screen\":false,\"language\":\"en\"}", WINDOW_MODE_WINDOWED, 5);
    Test_SettingsMigrationCase("v6 fit_screen true", "{\"settings_version\":6,\"display_scale\":3,\"fit_screen\":true}", WINDOW_MODE_EXCLUSIVE, 3);
    // Versions below 6 forced the old fit_screen off (the legacy monitor-fit startup was disabled): they stay windowed.
    Test_SettingsMigrationCase("v5 fit_screen true is dropped", "{\"settings_version\":5,\"display_scale\":4,\"fit_screen\":true}", WINDOW_MODE_WINDOWED, 4);
    Test_SettingsMigrationCase("v1 tiny scale -> default scale", "{\"settings_version\":1,\"display_scale\":1}", WINDOW_MODE_WINDOWED, DISPLAY_SCALE_DEFAULT);
    Test_SettingsMigrationCase("no version, no fields", "{\"vol_bgm\":0.5}", WINDOW_MODE_WINDOWED, DISPLAY_SCALE_DEFAULT);
    // Version 8 files carry the mode itself; a stray fit_screen is ignored.
    Test_SettingsMigrationCase("v8 borderless", "{\"settings_version\":8,\"display_scale\":6,\"window_mode\":1}", WINDOW_MODE_BORDERLESS, 6);
    Test_SettingsMigrationCase("v8 exclusive, stray fit_screen ignored", "{\"settings_version\":8,\"display_scale\":3,\"window_mode\":2,\"fit_screen\":false}", WINDOW_MODE_EXCLUSIVE, 3);
    Test_SettingsMigrationCase("v8 windowed", "{\"settings_version\":8,\"display_scale\":4,\"window_mode\":0}", WINDOW_MODE_WINDOWED, 4);
    Test_SettingsMigrationCase("v8 without the field -> default borderless", "{\"settings_version\":8,\"display_scale\":3}", WINDOW_MODE_BORDERLESS, 3);
    Test_SettingsMigrationCase("v8 bad mode value is clamped", "{\"settings_version\":8,\"display_scale\":3,\"window_mode\":9}", WINDOW_MODE_EXCLUSIVE, 3);
    // Scales above the old 5 are kept (windowed size choices follow the monitor now), up to the hard ceiling.
    Test_SettingsMigrationCase("v8 scale 9 kept", "{\"settings_version\":8,\"display_scale\":9,\"window_mode\":0}", WINDOW_MODE_WINDOWED, 9);

    // Write and read back: the file is version 8, carries window_mode and no fit_screen.
    var _f = "test_settings_mig.json";
    Save_DeleteFileSet(_f);
    Save_WriteSettingsConfig({ window_mode: WINDOW_MODE_BORDERLESS, display_scale: 6, audio_bgm: 0.4 }, _f);
    var _raw = json_parse(Test_RawRead(_f));
    Test_Eq("DISP-14 written settings_version", _raw.settings_version, 10);   // 9 added text_speed, screen_shake, qte_assist (D0); 10 adds keys (D49)
    Test_Eq("DISP-14 written window_mode", _raw.window_mode, WINDOW_MODE_BORDERLESS);
    Test_False("DISP-14 written file has no fit_screen", variable_struct_exists(_raw, "fit_screen"));
    var _back = Save_ReadSettingsConfig(_f);
    Test_Eq("DISP-14 round trip: mode", is_struct(_back) ? _back.window_mode : -1, WINDOW_MODE_BORDERLESS);
    Test_Eq("DISP-14 round trip: scale", is_struct(_back) ? _back.display_scale : -1, 6);
    Test_Eq("DISP-14 round trip: volume", is_struct(_back) ? _back.audio_bgm : -1, 0.4);
    // An old in-memory struct that still says fit_screen (not window_mode) is mapped too.
    Test_Eq("DISP-14 Normalize maps a legacy fit_screen true", GameSettings_Normalize({ fit_screen: true }).window_mode, WINDOW_MODE_EXCLUSIVE);
    Test_Eq("DISP-14 Normalize maps a legacy fit_screen false", GameSettings_Normalize({ fit_screen: false }).window_mode, WINDOW_MODE_WINDOWED);
    Test_Eq("DISP-14 window_mode wins over a legacy fit_screen", GameSettings_Normalize({ fit_screen: true, window_mode: WINDOW_MODE_BORDERLESS }).window_mode, WINDOW_MODE_BORDERLESS);
    Save_DeleteFileSet(_f);
}


// NAV-01 (D63, D65, I-047): pure grid pathfinding on hand-made maps, no room needed. Maps are ASCII: "." free, "#" wall (blocks
// movement and sight), "~" blocks movement only (rock, chest). Expected lengths are counted by hand (4-direction steps).
function Test_PathIsValid(_g, _p, _sx, _sy, _gx, _gy) {
    if (array_length(_p) == 0) return false;
    var _px = _sx, _py = _sy;
    for (var _i = 0; _i < array_length(_p); _i++) {
        var _c = _p[_i];
        if (abs(_c[0] - _px) + abs(_c[1] - _py) != 1) return false;
        if (Nav_CellBlocked(_g, _c[0], _c[1])) return false;
        _px = _c[0];
        _py = _c[1];
    }
    return (_px == _gx && _py == _gy);
}

function Test_Suite_Nav() {
    // cell <-> world conversion (16 px cells, origin 0,0)
    Test_Eq("NAV-01 world 33 is cell 2", Nav_CellOf(33), 2);
    Test_Eq("NAV-01 world 0 is cell 0", Nav_CellOf(0), 0);
    Test_Eq("NAV-01 world 15.9 is cell 0", Nav_CellOf(15.9), 0);
    Test_Eq("NAV-01 world -1 is cell -1", Nav_CellOf(-1), -1);
    Test_Eq("NAV-01 cell 3 is world 48", Nav_WorldOf(3), 48);

    // open ground: shortest path is the Manhattan distance
    var _g = Nav_GridFromRows([".....", ".....", "....."]);
    var _p = Nav_FindPath(_g, 0, 0, 4, 2);
    Test_Eq("NAV-01 open ground: length 6", array_length(_p), 6);
    Test_True("NAV-01 open ground: path is contiguous and ends on the goal", Test_PathIsValid(_g, _p, 0, 0, 4, 2));
    Test_Eq("NAV-01 start equals goal: no steps", array_length(Nav_FindPath(_g, 2, 1, 2, 1)), 0);

    // path around a wall: wall column x=2 open only on row 2
    _g = Nav_GridFromRows(["..#..", "..#..", "....."]);
    _p = Nav_FindPath(_g, 0, 0, 4, 0);
    Test_Eq("NAV-01 around a wall: length 8", array_length(_p), 8);
    Test_True("NAV-01 around a wall: path is contiguous, avoids walls, ends on the goal", Test_PathIsValid(_g, _p, 0, 0, 4, 0));

    // no way through: the goal is sealed off
    _g = Nav_GridFromRows(["..#..", "..#..", "..#.."]);
    Test_Eq("NAV-01 no path: empty", array_length(Nav_FindPath(_g, 0, 0, 4, 0)), 0);
    var _r = Nav_ResCreate();
    var _st = Nav_StepToward(_g, _r, 1, 0, 0, 4, 0);
    Test_Eq("NAV-01 no path: StepToward says stay", _st.ok, false);

    // movement-only blockers also stop paths; the goal cell may be blocked terrain (target stands next to a chest) only if free
    _g = Nav_GridFromRows([".~.", ".~.", ".~."]);
    Test_Eq("NAV-01 rock column seals the map", array_length(Nav_FindPath(_g, 0, 1, 2, 1)), 0);
    Test_Eq("NAV-01 goal outside the map: no path", array_length(Nav_FindPath(_g, 0, 1, 9, 9)), 0);

    // line of sight: only "#" blocks it
    _g = Nav_GridFromRows(["....#....", ".........", "....~...."]);
    Test_Eq("NAV-01 sight along a clear row", Nav_LineClear(_g, 0, 1, 8, 1), true);
    Test_Eq("NAV-01 sight blocked by a wall", Nav_LineClear(_g, 0, 0, 8, 0), false);
    Test_Eq("NAV-01 sight blocked by a wall is symmetric", Nav_LineClear(_g, 8, 0, 0, 0), false);
    Test_Eq("NAV-01 a rock does not block sight", Nav_LineClear(_g, 0, 2, 8, 2), true);
    Test_Eq("NAV-01 sight to the own cell", Nav_LineClear(_g, 3, 1, 3, 1), true);
    Test_Eq("NAV-01 sight under a wall, diagonal", Nav_LineClear(_g, 3, 1, 5, 2), true);
    var _g2 = Nav_GridFromRows([".....", "..#..", "....."]);
    Test_Eq("NAV-01 sight blocked diagonally through a wall", Nav_LineClear(_g2, 0, 0, 4, 2), false);
    Test_Eq("NAV-01 sight diagonal clear of the wall", Nav_LineClear(_g2, 0, 2, 4, 2), true);

    // reservations: two enemies never take the same cell
    _g = Nav_GridFromRows(["..", "..", ".#"]);
    _r = Nav_ResCreate();
    Test_Eq("NAV-01 reserve a free cell", Nav_ResClaim(_r, 1, 0, 0), true);
    Test_Eq("NAV-01 reserve again by the same owner", Nav_ResClaim(_r, 1, 0, 0), true);
    Test_Eq("NAV-01 another owner cannot take it", Nav_ResClaim(_r, 2, 0, 0), false);
    Test_Eq("NAV-01 owner of a cell", Nav_ResOwnerAt(_r, 0, 0), 1);
    Nav_ResClaim(_r, 2, 1, 1);   // enemy 2 stands at (1,1), enemy 1 at (0,0), the target is at (0,2)
    var _a = Nav_StepToward(_g, _r, 1, 0, 0, 0, 2);
    Test_True("NAV-01 enemy 1 steps to (0,1)", _a.ok && _a.cx == 0 && _a.cy == 1);
    Test_Eq("NAV-01 enemy 1 faces DOWN", _a.dir, DOWN);
    var _b = Nav_StepToward(_g, _r, 2, 1, 1, 0, 2);
    Test_Eq("NAV-01 enemy 2 waits: its only way, (0,1), is taken", _b.ok, false);
    Nav_ResRelease(_r, 1);
    _b = Nav_StepToward(_g, _r, 2, 1, 1, 0, 2);
    Test_True("NAV-01 enemy 2 steps once the cell is free", _b.ok && _b.cx == 0 && _b.cy == 1);
    Test_Eq("NAV-01 release frees all cells of an owner", Nav_ResOwnerAt(_r, 0, 0), -1);

    Test_SightRingCache();
    Test_InteractTargetTie();
}

// D108 F1d-3: the sight ring of an enemy (Nav_DrawWorldFx) used to recompute ~2 sin/cos per dot per enemy per frame. Its dot offsets now come from a cache
// keyed on the radius (Nav_SightRing). EXPECTED values below are the OLD formula, copied from Nav_DrawWorldFx as it was before this change:
//   n = max(12, round(2*pi*r/6)); a = (k/n)*2*pi; dot = floor(cx + cos(a)*r), floor(cy + sin(a)*r); colour 1 (even k) / colour 2 (odd k).
function Test_SightRingCache() {
    var _t0 = get_timer();
    var _sink = 0;
    for (var _e = 0; _e < 300; _e++) {   // [PERF] the OLD per-frame work for 300 enemy rings of sight 5, no assertion (the time depends on the PC)
        var _rr = 5 * GRID_TILE_SIZE;
        var _nn = max(12, round(2 * pi * _rr / 6));
        for (var _kk = 0; _kk < _nn; _kk++) {
            var _aa = (_kk / _nn) * 2 * pi;
            _sink += floor(100 + cos(_aa) * _rr) + floor(100 + sin(_aa) * _rr);
        }
    }
    Test_Log("[PERF] 300 x sight ring points (sight 5): old formula " + string(get_timer() - _t0) + " us (" + string(_sink > 0) + ")");
    if (asset_get_index("Nav_SightRing") == -1) {
        Test_True("F1d3 Nav_SightRing exists (cached ring offsets)", false);
        return;
    }
    global.nav_ring_cache = {};
    global.nav_ring_builds = 0;
    var _tiles = [3, 4, 5];
    var _same = true;
    var _px_same = true;
    var _cxs = [208, 208.5, 123.37];   // whole and fractional enemy positions: the draw does floor(cx + offset), the same float sum as before
    for (var _i = 0; _i < 3; _i++) {
        var _r = _tiles[_i] * GRID_TILE_SIZE;
        var _ring = undefined;
        for (var _c = 0; _c < 100; _c++) _ring = Nav_SightRing(_r);   // 300 calls over the three radii
        var _n = max(12, round(2 * pi * _r / 6));
        if (_ring.n != _n || array_length(_ring.ox) != _n || array_length(_ring.oy) != _n) _same = false;
        for (var _k = 0; _k < _n && _same; _k++) {
            var _a = (_k / _n) * 2 * pi;
            for (var _q = 0; _q < 3; _q++) {
                var _cx = _cxs[_q];
                if (floor(_cx + _ring.ox[_k]) != floor(_cx + cos(_a) * _r)) _px_same = false;
                if (floor(_cx + _ring.oy[_k]) != floor(_cx + sin(_a) * _r)) _px_same = false;
            }
        }
        Test_Eq("F1d3 ring r=" + string(_tiles[_i]) + " tiles has the old dot count", _ring.n, _n);
    }
    Test_True("F1d3 ring offsets equal the old formula for radii 3, 4, 5", _same);
    Test_True("F1d3 ring dots land on the same pixels as the old formula (whole and fractional centres)", _px_same);
    Test_Eq("F1d3 the ring offset builder runs once per radius over 300 calls", global.nav_ring_builds, 3);

    var _t1 = get_timer();
    for (var _e2 = 0; _e2 < 300; _e2++) {
        var _rg = Nav_SightRing(5 * GRID_TILE_SIZE);
        var _rox = _rg.ox, _roy = _rg.oy, _rn = _rg.n;   // as Nav_DrawWorldFx reads them
        for (var _k2 = 0; _k2 < _rn; _k2++) _sink += floor(100 + _rox[_k2]) + floor(100 + _roy[_k2]);
    }
    Test_Log("[PERF] 300 x sight ring points (sight 5): cached offsets " + string(get_timer() - _t1) + " us (" + string(_sink > 0) + ")");

}

// D108 F1d-3: Interact_GetTarget now asks for the faced tile once instead of looping every interactable. When several interactables overlap the
// tile, the OLD loop picked the first one in instance order (strict "<" on equal distances); the new code must hand back that same instance.
function Test_InteractTargetTie() {
    var _spr = asset_get_index("barrel_asset");
    if (_spr == -1) return;
    var _gs = GameState_Get();
    var _pl = instance_create_depth(304, 320, 0, obj_interactable);   // stands in for the player: Interact_* only read x, y, face
    _pl.face = RIGHT;                                                  // faces the tile at 320,320 (centre 328,328)
    var _a = instance_create_depth(320, 320, 0, obj_interactable);
    var _b = instance_create_depth(320, 320, 0, obj_interactable);
    var _c = instance_create_depth(320, 320, 0, obj_interactable);
    var _far = instance_create_depth(480, 480, 0, obj_interactable);
    var _all = [_a, _b, _c, _far];
    for (var _i = 0; _i < 4; _i++) {
        _all[_i].sprite_index = _spr;
        _all[_i].mask_index = _spr;
    }
    // reference = the old loop, verbatim
    var _old = noone;
    var _best = 1000000000;
    with (obj_interactable) {
        var _d = Interact_FacingDistance(_pl, self);
        if (_d < _best) {
            _best = _d;
            _old = self;
        }
    }
    _gs.interact_cache_frame = -1;
    var _new = Interact_GetTarget(_pl);
    Test_True("F1d3 interact: three interactables cover the faced tile", Interact_PlayerFacing(_pl, _a) && Interact_PlayerFacing(_pl, _b) && Interact_PlayerFacing(_pl, _c));
    Test_True("F1d3 interact: the old loop found one of them", _old != noone && instance_exists(_old));
    Test_True("F1d3 interact: Interact_GetTarget picks the same instance as the old loop with three overlapping", instance_exists(_new) && instance_exists(_old) && _new.id == _old.id);
    Test_True("F1d3 interact: the value is the same kind of reference as the old loop's self (Interact_Handle compares target != self)", _new == _old);

    // one interactable only on the tile
    instance_destroy(_b);
    instance_destroy(_c);
    with (obj_interactable) {
        var _d1 = Interact_FacingDistance(_pl, self);
        if (_d1 < 1000000000) _old = self;
    }
    _gs.interact_cache_frame = -1;
    _new = Interact_GetTarget(_pl);
    Test_True("F1d3 interact: a single interactable on the tile is found", instance_exists(_new) && _new.id == _a.id);
    var _self_a = noone;
    with (_a) _self_a = self;
    Test_True("F1d3 interact: a single hit is returned as that instance's self (Interact_Handle compares target != self)", _new == _self_a);

    // facing the empty side, or away, finds nothing
    _pl.face = UP;
    _gs.interact_cache_frame = -1;
    Test_Eq("F1d3 interact: facing an empty tile gives noone", Interact_GetTarget(_pl), noone);
    _pl.face = RIGHT;
    instance_destroy(_a);
    _gs.interact_cache_frame = -1;
    Test_Eq("F1d3 interact: nothing on the faced tile gives noone", Interact_GetTarget(_pl), noone);

    instance_destroy(_far);
    instance_destroy(_pl);
    _gs.interact_cache_frame = -1;
    _gs.interact_cache_target = noone;
}

// SNAP-01 (I-048, D69): everything that walks lives on the 16 px grid; the snap is "nearest multiple of 16".
function Test_Suite_Snap() {
    Test_Eq("SNAP-01 0.4 snaps to 0", Grid_Snap(0.4), 0);
    Test_Eq("SNAP-01 15.6 snaps to 16", Grid_Snap(15.6), 16);
    Test_Eq("SNAP-01 8.4 snaps to 16", Grid_Snap(8.4), 16);
    Test_Eq("SNAP-01 7.6 snaps to 0", Grid_Snap(7.6), 0);
    Test_Eq("SNAP-01 an aligned value stays", Grid_Snap(48), 48);
    Test_Eq("SNAP-01 -3 snaps to 0", Grid_Snap(-3), 0);
    Test_Eq("SNAP-01 -9 snaps to -16", Grid_Snap(-9), -16);
    var _p = Grid_SnapPoint(0.4, 15.6);
    Test_True("SNAP-01 point (0.4, 15.6) is (0, 16)", _p.x == 0 && _p.y == 16);
    Test_Eq("SNAP-01 32 is aligned", Grid_IsAligned(32), true);
    Test_Eq("SNAP-01 32.4 is not aligned", Grid_IsAligned(32.4), false);
    Test_Eq("SNAP-01 -16 is aligned", Grid_IsAligned(-16), true);
    Test_Eq("SNAP-01 float noise below 0.001 counts as aligned", Grid_IsAligned(32.000000001), true);
}


// ---- ROB-03 memory hygiene -----------------------------------------------------------------------
// GameMaker has no "count live ds structures" call, so this scans the id space with ds_exists. Ids are small
// integers that are reused after a destroy, so a leak shows up as a count that keeps growing.
// Mem_DsLiveCount() is also meant for the -smoke / -bot run: read it before and after N room changes or battles and
// assert Mem_DsGrowthSince(baseline) == 0 (the scan costs a few thousand cheap calls; do not call it every frame).
function Mem_DsLiveCount(_max_id = 1024) {
    var _types = [ds_type_map, ds_type_list, ds_type_grid, ds_type_queue, ds_type_stack, ds_type_priority];
    var _n = 0;
    for (var _t = 0; _t < array_length(_types); _t++) {
        for (var _i = 0; _i < _max_id; _i++) {
            if (ds_exists(_i, _types[_t])) _n++;
        }
    }
    return _n;
}

function Mem_DsGrowthSince(_baseline) {
    return Mem_DsLiveCount() - _baseline;
}

// One "room or battle worth" of init paths that are re-entered on every room change / battle start / load.
function Test_MemCycle() {
    GameState_Init();
    ItemDB_Init();
    SkillDB_Init();
    EnemyDB_Init();
    StatusDB_Init();
    DialogueDB_Init();
    Loot_Init();
    SFX_EnsureGainMaps();
    SFX_EnsureVariantMaps();
    // a re-created persistent audio manager destroys and rebuilds its four maps in Create
    if (instance_exists(obj_sfx_manager)) instance_destroy(obj_sfx_manager);
    SFX_EnsureManager();
    var _snap = json_parse(json_stringify(Save_BuildSnapshot()));
    Save_ApplySnapshot(_snap);
}

function Test_Suite_Mem() {
    // the counter itself works: a created map is counted, a destroyed one is not
    var _c0 = Mem_DsLiveCount();
    var _m = ds_map_create();
    Test_Eq("ROB-03 counter sees a new ds_map", Mem_DsGrowthSince(_c0), 1);
    var _l = ds_list_create();
    Test_Eq("ROB-03 counter sees a new ds_list", Mem_DsGrowthSince(_c0), 2);
    ds_map_destroy(_m);
    ds_list_destroy(_l);
    Test_Eq("ROB-03 counter drops after destroy", Mem_DsGrowthSince(_c0), 0);

    var _fx = Test_FixBegin(DIFFICULTY_NORMAL);
    Test_MemCycle();   // warm-up: first pass creates the long-lived databases
    var _base = Mem_DsLiveCount();
    for (var _n = 0; _n < 20; _n++) Test_MemCycle();
    Test_Log("[MEM] live ds structures: baseline=" + string(_base) + " after20=" + string(Mem_DsLiveCount()));
    Test_Eq("ROB-03 live ds structures after 20 room/battle init cycles (baseline " + string(_base) + ")", Mem_DsGrowthSince(_base), 0);
    Test_FixRestore();
}

// ---- ROB-03 input: no per-frame allocation ------------------------------------------------------
function Test_Suite_Input() {
    Input_Init();
    var _inp = global.input;
    keyboard_clear(ord("W"));
    _inp.last_step_time = -1;
    Input_Update();
    var _a = variable_struct_get(_inp.state, "move_up");
    var _f0 = _inp.frame;
    _inp.last_step_time = -1;
    Input_Update();
    var _b = variable_struct_get(_inp.state, "move_up");
    Test_Eq("ROB-03 Input_Update advances the frame once per call", _inp.frame, _f0 + 1);
    Test_True("ROB-03 Input_Update reuses the same state struct for an action", _a == _b);
    Test_Eq("ROB-03 idle: move_up not held", _b.held, false);
    Test_Eq("ROB-03 idle: move_up not pressed", _b.pressed, false);

    // a held action that is no longer down is released, and leaves the move order (needs the previous state)
    variable_struct_set(_inp.state, "move_up", { held: true, pressed: false });
    _inp.move_order = ["move_up"];
    _inp.last_step_time = -1;
    Input_Update();
    var _d = variable_struct_get(_inp.state, "move_up");
    Test_Eq("ROB-03 released key: move_up held cleared", _d.held, false);
    Test_Eq("ROB-03 released key: move_up pressed cleared", _d.pressed, false);
    Test_Eq("ROB-03 released key leaves the move order", array_length(_inp.move_order), 0);
    // a foreign struct written into the state (the bot does this) is overwritten in place with fresh values
    var _e = { held: true, pressed: true };
    variable_struct_set(_inp.state, "move_up", _e);
    _inp.last_step_time = -1;
    Input_Update();
    Test_Eq("ROB-03 override then update: held reset", variable_struct_get(_inp.state, "move_up").held, false);
    Test_Eq("ROB-03 override then update: pressed reset", variable_struct_get(_inp.state, "move_up").pressed, false);
    _inp.last_step_time = -1;

    // The input is read once per FRAME, not once per millisecond: two frames that share one current_time value (an unthrottled run, a 1 ms
    // timer) must not let a press of the first one survive into the second (a menu moved twice for one tap). Input_FrameEnd is called by the draw
    // of every frame, after all the Step events, so the next frame's first Input_Update always recomputes.
    var _dn = { held: false, pressed: true };   // the press of frame N, still in the state
    variable_struct_set(_inp.state, "menu_down", _dn);
    _inp.last_step_time = current_time;          // frame N + 1 starts in the same millisecond as frame N
    var _f1 = _inp.frame;
    Input_FrameEnd();
    Input_Update();
    Test_Eq("Input a new frame in the same millisecond still recomputes (frame counter)", _inp.frame, _f1 + 1);
    Test_False("Input a press does not survive into the next frame, even in the same millisecond", variable_struct_get(_inp.state, "menu_down").pressed);
    // without a frame boundary and in the same millisecond nothing is recomputed (many objects call Input_PreStep in one frame)
    variable_struct_set(_inp.state, "menu_down", { held: false, pressed: true });
    _inp.last_step_time = current_time - 5;   // a clock that has moved on inside the frame
    var _f2 = _inp.frame;
    Input_Update();
    Test_Eq("Input inside one frame (no draw in between) does not recompute, whatever the clock says", _inp.frame, _f2);
    Test_True("Input the state of the frame is kept for every later controller of that frame", variable_struct_get(_inp.state, "menu_down").pressed);
    _inp.last_step_time = -1;
    Input_Update();
    // D108 F1a: Input_Init does its work once, not on every Input_Held / Input_Pressed / Prompt_Device call (dozens per frame)
    var _ba = variable_struct_exists(_inp, "binds_applied") && _inp.binds_applied;
    _inp.binds_applied = false;
    _inp.bindings.confirm = [ord("Q")];   // an older table in memory: the first init still repairs it (D95)
    _inp.init_done = false;
    global.input_init_runs = 0;
    Input_Init();
    Test_True("F1a the first init repairs an older confirm table", array_contains(_inp.bindings.confirm, vk_space) && array_contains(_inp.bindings.confirm, ord("Z")));
    var _conf = _inp.bindings.confirm;
    _conf[@ 0] = 12345;   // a probe in the live array: a re-init would write a fresh table over it
    for (var _c = 0; _c < 300; _c++) { Input_Held("confirm"); Input_Pressed("confirm"); Prompt_Device(); }
    Test_Eq("F1a Input_Init body ran once over 300 Input_Held/Input_Pressed/Prompt_Device calls", global.input_init_runs, 1);
    Test_True("F1a bindings.confirm is the same array after 300 calls", _inp.bindings.confirm == _conf && _inp.bindings.confirm[0] == 12345);
    _conf[@ 0] = vk_space;
    var _kp = Binds_Defaults();
    _kp.interact = [ord("T")];
    Binds_Apply(_kp);
    for (var _c = 0; _c < 300; _c++) Input_Held("interact");
    Test_True("F1a after Binds_Apply the new binding takes effect and stays", _inp.bindings.interact[0] == ord("T") && Input_Label("interact") == "T");
    Binds_Apply(Binds_Defaults());
    Test_True("F1a Binds_Apply of the defaults puts Space back", _inp.bindings.interact[0] == vk_space);
    _inp.binds_applied = _ba;
    var _t1 = get_timer();
    for (var _c = 0; _c < 1000; _c++) Input_Held("confirm");
    Test_Log("[PERF] 1000 x Input_Held: " + string(get_timer() - _t1) + " us");
}

// ---- ROB-03 obj_sfx_manager: audio globals are created once, not every Step -----------------------
function Test_Suite_SfxInit() {
    global.audio_globals_ready = false;
    global.sfx_globals_init_runs = 0;
    for (var _f = 0; _f < 300; _f++) SFX_EnsureAudioGlobals();   // what obj_sfx_manager Step does each frame
    Test_Eq("ROB-03 audio globals init runs once over 300 frames", global.sfx_globals_init_runs, 1);
    global.audio_debug_missing_count = 0;
    global.audio_debug_missing_count = 5;
    SFX_EnsureAudioGlobals();
    Test_Eq("ROB-03 later calls do not overwrite live audio state", global.audio_debug_missing_count, 5);
    global.audio_debug_missing_count = 0;

    // D108 F1d-3: obj_sfx_manager Step asks variable_struct_names_count (no array) whether any BGM handle is live; it must agree with the old name list
    var _hs = { a: 1, b: 2 };
    Test_Eq("F1d3 struct names count equals the old get_names length (2)", variable_struct_names_count(_hs), array_length(variable_struct_get_names(_hs)));
    Test_Eq("F1d3 struct names count of an empty struct is 0", variable_struct_names_count({}), 0);
}

// ---- D116 monster sound variation: every enemy_* play gets a small random pitch and volume, and a key with 2+ takes never repeats the last take
function Test_Suite_Audio() {
    if (asset_get_index("SFX_EnemyVariation") == -1 || asset_get_index("SFX_RegisterEnemyVariants") == -1) {
        Test_True("audio: SFX_EnemyVariation and SFX_RegisterEnemyVariants exist (D116)", false);
        return;
    }
    if (!variable_global_exists("sfx_db") || !ds_exists(global.sfx_db, ds_type_map)) global.sfx_db = ds_map_create();   // the manager object may not exist yet in a -runtests boot
    SFX_RegisterDefaults();
    var _keep_rng = variable_global_exists("sfx_rng") ? global.sfx_rng : undefined;

    // the band: pitch +-6 %, volume +-10 %, drawn from the injected RNG
    global.sfx_rng = Rng_New(116, "sfx");
    var _pmin = 99, _pmax = 0, _vmin = 99, _vmax = 0, _inside = true;
    var _keys = ["enemy_spawn_slime", "enemy_special_snake", "enemy_special_final_boss", "enemy_skill_bite", "enemy_spawn_unknown"];
    for (var _i = 0; _i < 500; _i++) {
        var _v = SFX_EnemyVariation(_keys[_i mod array_length(_keys)]);
        if (_v.pitch < 0.94 || _v.pitch > 1.06 || _v.vol < 0.90 || _v.vol > 1.10) _inside = false;
        _pmin = min(_pmin, _v.pitch); _pmax = max(_pmax, _v.pitch);
        _vmin = min(_vmin, _v.vol);   _vmax = max(_vmax, _v.vol);
    }
    Test_True("audio: 500 enemy plays stay inside pitch 0.94..1.06 and volume 0.90..1.10", _inside);
    Test_True("audio: enemy pitch is not always the same (spread over 0.08)", _pmax - _pmin > 0.08);
    Test_True("audio: enemy volume is not always the same (spread over 0.10)", _vmax - _vmin > 0.10);
    Test_True("audio: enemy pitch reaches both sides of 1", _pmin < 0.97 && _pmax > 1.03);

    // same injected seed, same variation; another seed, another one
    global.sfx_rng = Rng_New(7, "sfx");
    var _a1 = SFX_EnemyVariation("enemy_spawn_spider");
    var _a2 = SFX_EnemyVariation("enemy_spawn_spider");
    global.sfx_rng = Rng_New(7, "sfx");
    var _b1 = SFX_EnemyVariation("enemy_spawn_spider");
    var _b2 = SFX_EnemyVariation("enemy_spawn_spider");
    Test_True("audio: same seed repeats the same variation", _a1.pitch == _b1.pitch && _a1.vol == _b1.vol && _a2.pitch == _b2.pitch && _a2.vol == _b2.vol);
    Test_True("audio: two plays in a row differ", _a1.pitch != _a2.pitch);
    global.sfx_rng = Rng_New(8, "sfx");
    Test_True("audio: another seed gives another variation", SFX_EnemyVariation("enemy_spawn_spider").pitch != _a1.pitch);

    // only enemy_ keys vary
    global.sfx_rng = Rng_New(116, "sfx");
    var _calls = global.sfx_rng.calls;
    var _ui = SFX_EnemyVariation("ui_move");
    Test_True("audio: a UI key keeps pitch 1 and volume 1", _ui.pitch == 1 && _ui.vol == 1);
    Test_Eq("audio: a UI key draws nothing from the RNG", global.sfx_rng.calls, _calls);
    Test_True("audio: SFX_IsEnemyKey is true for enemy_ keys only", SFX_IsEnemyKey("enemy_special_dire_wolf") && !SFX_IsEnemyKey("sword_attack") && !SFX_IsEnemyKey("ui_enemy_x"));

    // SFX_Play applies it (pitch recorded in sfx_last_pitch / sfx_last_vary, even without a sound device)
    global.sfx_rng = Rng_New(116, "sfx");
    var _seen = {};
    var _all_in = true;
    repeat (40) {
        SFX_Play("enemy_special_stranger");
        var _p = global.sfx_last_pitch;
        if (_p < 0.94 || _p > 1.06 || global.sfx_last_vary < 0.90 || global.sfx_last_vary > 1.10) _all_in = false;
        variable_struct_set(_seen, string(round(_p * 100000)), 1);
    }
    Test_True("audio: SFX_Play on an enemy key records a pitch inside the band", _all_in);
    Test_True("audio: SFX_Play on an enemy key gives many different pitches", variable_struct_names_count(_seen) > 20);
    SFX_Play("ui_move");
    Test_True("audio: SFX_Play on a UI key is unvaried", global.sfx_last_pitch == 1 && global.sfx_last_vary == 1);
    SFX_Play("enemy_special_stranger", 1, 2);
    Test_True("audio: a caller pitch is multiplied, not replaced", global.sfx_last_pitch >= 1.88 && global.sfx_last_pitch <= 2.12);

    // rotation: a key with 2+ takes never plays the same take twice in a row, and uses every take
    SFX_RegisterEnemyVariants("enemy_test_three", ["Punch_1", "Punch_2", "Punch_3"], "");
    Test_Eq("audio: three listed takes are registered", array_length(global.sfx_variant_db[? "enemy_test_three"]), 3);
    var _last = noone, _repeat = false, _used = {};
    repeat (400) {
        var _snd = SFX_ResolvePlayAsset("enemy_test_three");
        if (_snd == _last) _repeat = true;
        _last = _snd;
        variable_struct_set(_used, string(_snd), 1);
    }
    Test_False("audio: three takes never repeat the previous one (400 plays)", _repeat);
    Test_Eq("audio: three takes all get used", variable_struct_names_count(_used), 3);

    SFX_RegisterEnemyVariants("enemy_test_two", ["Punch_1", "Punch_2"], "");
    _last = noone; _repeat = false; _used = {};
    repeat (200) {
        var _snd2 = SFX_ResolvePlayAsset("enemy_test_two");
        if (_snd2 == _last) _repeat = true;
        _last = _snd2;
        variable_struct_set(_used, string(_snd2), 1);
    }
    Test_False("audio: two takes alternate (200 plays)", _repeat);
    Test_Eq("audio: two takes both get used", variable_struct_names_count(_used), 2);

    // extra takes are found by name (D94 pattern): <prefix>_2, _3, _4 join the listed ones when they exist
    SFX_RegisterEnemyVariants("enemy_test_extra", ["Punch_1"], "Punch");
    Test_Eq("audio: listed take plus Punch_2 and Punch_3 found by name", array_length(global.sfx_variant_db[? "enemy_test_extra"]), 3);
    SFX_RegisterEnemyVariants("enemy_test_missing", ["Punch_1"], "no_such_sound");
    Test_Eq("audio: extra takes that are not imported yet are skipped", array_length(global.sfx_variant_db[? "enemy_test_missing"]), 1);
    SFX_RegisterEnemyVariants("enemy_test_dupe", ["Hiss", "Hiss"], "");
    Test_Eq("audio: the same sound listed twice counts once", array_length(global.sfx_variant_db[? "enemy_test_dupe"]), 1);

    // the real enemy keys: every monster has its spawn and special key, and they all go through the variant path
    var _ids = [ENEMY_SLIME, ENEMY_SPIDER, ENEMY_MADWHISP, ENEMY_GHOSTSWORD, ENEMY_DIREWOLF, ENEMY_SNAKE, ENEMY_KILLER_PLANT, ENEMY_STRANGER, ENEMY_MINI_BOSS, ENEMY_FINAL_BOSS];
    var _ok = true, _bad = "";
    SFX_RegisterDefaults();
    for (var _m = 0; _m < array_length(_ids); _m++) {
        var _suffix = SFX_EnemyKeySuffix(_ids[_m]);
        var _ev = ["enemy_spawn_" + _suffix, "enemy_special_" + _suffix];
        for (var _e = 0; _e < 2; _e++) {
            if (!ds_map_exists(global.sfx_variant_db, _ev[_e])) { _ok = false; _bad += _ev[_e] + " "; }
        }
    }
    Test_True("audio: all 10 monsters have spawn and special registered as variant keys " + _bad, _ok);

    global.sfx_rng = _keep_rng;
    if (is_undefined(_keep_rng)) variable_global_set("sfx_rng", undefined);
    SFX_RegisterDefaults();
}


// ============================================================================================================
// C1 run loop (D25-D27, D33, D36, D46, D87, D88). Expected numbers below were computed by a separate Python
// script that follows the written spec, not by this game's code:
//   Park-Miller (minstd, multiplier 48271, modulus 2147483647): state = state * 48271 mod 2147483647.
//   Stream start state = int(first 8 hex digits of md5("<seed>:<label>")) mod 2147483646 + 1.
//   Float = (state - 1) / 2147483646, Int(n) = floor(Float * n).
// ============================================================================================================
function Test_RngSeq(_r, _n) {
    var _a = [];
    repeat (_n) array_push(_a, Rng_Next(_r));
    return _a;
}

function Test_SameArray(_a, _b) {
    if (!is_array(_a) || !is_array(_b) || array_length(_a) != array_length(_b)) return false;
    for (var _i = 0; _i < array_length(_a); _i++) {
        if (_a[_i] != _b[_i]) return false;
    }
    return true;
}

function Test_Suite_Rng() {
    // the published minstd (48271) sequence from seed 1, and its textbook check value after 10000 steps
    var _r = Rng_NewRaw(1);
    Test_Eq("rng: raw seed 1, value 1", Rng_Next(_r), 48271);
    Test_Eq("rng: raw seed 1, value 2", Rng_Next(_r), 182605794);
    Test_Eq("rng: raw seed 1, value 3", Rng_Next(_r), 1291394886);
    Test_Eq("rng: raw seed 1, value 4", Rng_Next(_r), 1914720637);
    Test_Eq("rng: raw seed 1, value 5", Rng_Next(_r), 2078669041);
    Test_Eq("rng: raw seed 1, value 6", Rng_Next(_r), 407355683);
    var _v = 0;
    repeat (9994) _v = Rng_Next(_r);
    Test_Eq("rng: raw seed 1, value 10000 is the textbook 399268537", _v, 399268537);
    Test_Eq("rng: the stream counts its calls", _r.calls, 10000);

    // derived streams: seed 12345, each label (start state, first 3 values, value 100)
    var _want = [
        ["map",    168073364,  [2023618925, 1667961233, 699784819],   45419093],
        ["loot",   744441128,  [1073824437, 766610788, 1778626091],   935948468],
        ["shop",   1305116111, [679525689, 719309441, 1270421815],    830619925],
        ["enemy",  329470954,  [1776014499, 301209342, 1211857492],   323682109],
        ["cards",  1361448276, [1175165302, 623757337, 1669683387],   365053478],
        ["combat", 1182911836, [894545473, 1150836954, 943625938],    1122180848]
    ];
    for (var _i = 0; _i < array_length(_want); _i++) {
        var _w = _want[_i];
        Test_Eq("rng: derive(12345, " + _w[0] + ") start state", Rng_Derive(12345, _w[0]), _w[1]);
        var _s = Rng_New(12345, _w[0]);
        var _seq = Test_RngSeq(_s, 100);
        Test_True("rng: stream " + _w[0] + " first 3 values", _seq[0] == _w[2][0] && _seq[1] == _w[2][1] && _seq[2] == _w[2][2]);
        Test_Eq("rng: stream " + _w[0] + " value 100", _seq[99], _w[3]);
        var _again = Test_RngSeq(Rng_New(12345, _w[0]), 100);
        Test_True("rng: stream " + _w[0] + " same seed gives the same first 100 values", Test_SameArray(_seq, _again));
    }
    Test_Eq("rng: derive(777, loot) differs from seed 12345", Rng_Derive(777, "loot"), 1414312338);
    Test_Eq("rng: seed 777 loot first value", Rng_Next(Rng_New(777, "loot")), 1765729468);
    Test_True("rng: different labels give different first values", Rng_Next(Rng_New(12345, "loot")) != Rng_Next(Rng_New(12345, "shop")));
    Test_True("rng: different seeds give different first values", Rng_Next(Rng_New(12345, "loot")) != Rng_Next(Rng_New(12346, "loot")));
    Test_True("rng: derived start state is in 1..2147483646", Rng_Derive(0, "x") >= 1 && Rng_Derive(0, "x") <= 2147483646 && Rng_Derive(2147483646, "y") >= 1);

    // floats, ints, ranges
    var _f = Rng_New(12345, "loot");
    Test_Eq("rng: float of loot value 1 is 0.5000384696759642 (to 6 places)", round(Rng_Float(_f) * 1000000), 500038);
    var _digits = [5, 3, 8, 8, 6, 7, 4, 4, 3, 0];   // floor(float * 10) of loot values 1..10 (Python)
    var _t = Rng_New(12345, "loot");
    var _got = [];
    for (var _k = 0; _k < 10; _k++) array_push(_got, Rng_Int(_t, 10));
    Test_True("rng: Rng_Int(10) of loot values 1..10", Test_SameArray(_got, _digits));
    var _u = Rng_New(99, "range");
    var _seen = [0, 0, 0, 0, 0];
    var _in = true;
    for (var _m = 0; _m < 1000; _m++) {
        var _x = Rng_Range(_u, 3, 7);
        if (_x < 3 || _x > 7 || _x != floor(_x)) _in = false; else _seen[_x - 3]++;
    }
    Test_True("rng: Rng_Range(3, 7) stays inside and is whole", _in);
    Test_True("rng: Rng_Range(3, 7) reaches every value", _seen[0] > 100 && _seen[1] > 100 && _seen[2] > 100 && _seen[3] > 100 && _seen[4] > 100);
    Test_Eq("rng: Rng_Int(0) is 0", Rng_Int(Rng_New(1, "z"), 0), 0);
    Test_False("rng: Rng_Chance(0) is never true", Rng_Chance(Rng_New(5, "c"), 0));
    Test_True("rng: Rng_Chance(1) is always true", Rng_Chance(Rng_New(5, "c"), 1));
    var _hits = 0;
    var _c = Rng_New(31, "chance");
    repeat (2000) { if (Rng_Chance(_c, 0.25)) _hits++; }
    Test_True("rng: Rng_Chance(0.25) hits about a quarter", _hits > 400 && _hits < 600);

    // pick and shuffle (shuffle returns a copy; same seed, same order)
    var _src = [10, 20, 30, 40, 50, 60];
    var _p1 = Rng_Shuffle(Rng_New(4, "shuf"), _src);
    var _p2 = Rng_Shuffle(Rng_New(4, "shuf"), _src);
    Test_True("rng: shuffle is repeatable", Test_SameArray(_p1, _p2));
    Test_True("rng: shuffle leaves the input alone", Test_SameArray(_src, [10, 20, 30, 40, 50, 60]));
    var _sorted = [];
    for (var _q = 0; _q < array_length(_p1); _q++) array_push(_sorted, _p1[_q]);
    array_sort(_sorted, true);
    Test_True("rng: shuffle keeps every element once", Test_SameArray(_sorted, _src));
    var _pk = Rng_Pick(Rng_New(8, "pick"), _src);
    Test_True("rng: pick returns an element", _pk == 10 || _pk == 20 || _pk == 30 || _pk == 40 || _pk == 50 || _pk == 60);
    Test_True("rng: pick of an empty array is undefined", is_undefined(Rng_Pick(Rng_New(8, "pick"), [])));

    // save and restore: only integers are stored, the restored stream continues exactly
    var _a = Rng_New(12345, "loot");
    Test_RngSeq(_a, 37);
    var _d = json_parse(json_stringify(Rng_Save(_a)));
    var _rest_a = Test_RngSeq(_a, 20);
    var _b = Rng_Load(_d);
    Test_Eq("rng: restored stream has the saved call count", _b.calls, 37);
    var _rest_b = Test_RngSeq(_b, 20);
    Test_True("rng: a restored stream continues the same sequence", Test_SameArray(_rest_a, _rest_b));
    Test_Eq("rng: save keeps whole numbers (state)", _d.state, floor(_d.state));
    Test_True("rng: Rng_Load of garbage gives a usable stream", is_struct(Rng_Load("nope")) && Rng_Next(Rng_Load(undefined)) > 0);

    // the six run streams are independent
    var _names = Run_StreamNames();
    Test_True("rng: the run has the six named streams", array_length(_names) == 6 && _names[0] == "map" && _names[1] == "loot" && _names[2] == "shop" && _names[3] == "enemy" && _names[4] == "cards" && _names[5] == "combat");
    var _run = Run_Create(12345);
    Test_Eq("run: Run_Create keeps the seed", _run.seed, 12345);
    Test_Eq("run: stream map first value", Rng_Next(_run.rng.map), 2023618925);
    repeat (10) Rng_Next(_run.rng.loot);
    Test_Eq("run: using loot does not move shop", Rng_Next(_run.rng.shop), 679525689);
    Test_Eq("run: Run_Create is active", _run.active, true);
}

function Test_Suite_Profile() {
    var _p = Profile_Default();
    Test_True("profile: default has a version", _p.profile_version == PROFILE_VERSION);
    Test_Eq("profile: default has no deaths", _p.deaths, 0);
    Test_Eq("profile: default has no wins", _p.wins, 0);
    Test_Eq("profile: default history is empty", array_length(_p.history), 0);
    Test_Eq("profile: default has no echo", _p.echo.kind, "");
    Test_False("profile: story not seen at first", Profile_StorySeen(_p, "cutscene:intro"));
    Profile_StoryMark(_p, "cutscene:intro");
    Profile_StoryMark(_p, "cutscene:intro");
    Test_True("profile: story seen after marking", Profile_StorySeen(_p, "cutscene:intro"));
    Test_False("profile: another story key is still unseen", Profile_StorySeen(_p, "cutscene:ending"));
    Test_False("profile: nobody_class starts locked", Profile_IsUnlocked(_p, "nobody_class"));
    Profile_Unlock(_p, "nobody_class");
    Test_True("profile: nobody_class unlocked after the grant", Profile_IsUnlocked(_p, "nobody_class"));
    Test_False("profile: other unlocks stay locked", Profile_IsUnlocked(_p, "item_9"));
    Test_Eq("story: the cutscene key", Story_CutsceneKey("intro"), "cutscene:intro");

    // run history: deaths, wins, best floor, the first win grants the nobody class
    var _q = Profile_Default();
    Profile_RecordRun(_q, { seed: 5, class_id: CLASS_KNIGHT, level: 4, floor: 3, room: "rm_floor3", result: "died", cause: "enemy 0", kills: 6, gold: 0 });
    Test_Eq("profile: a death counts", _q.deaths, 1);
    Test_Eq("profile: a death adds one history entry", array_length(_q.history), 1);
    Test_Eq("profile: best floor follows the run", _q.best_floor, 3);
    Test_False("profile: a death does not grant nobody_class", Profile_IsUnlocked(_q, "nobody_class"));
    Profile_RecordRun(_q, { seed: 6, class_id: CLASS_MAGE, level: 2, floor: 2, room: "rm_floor2", result: "abandoned", cause: "abandoned", kills: 1, gold: 0 });
    Test_Eq("profile: an abandoned run counts as a death", _q.deaths, 2);
    Test_Eq("profile: best floor does not go down", _q.best_floor, 3);
    Profile_RecordRun(_q, { seed: 7, class_id: CLASS_KNIGHT, level: 9, floor: 9.5, room: "rm_floor9_5", result: "won", cause: "", kills: 40, gold: 0 });
    Test_Eq("profile: a win counts", _q.wins, 1);
    Test_Eq("profile: a win is not a death", _q.deaths, 2);
    Test_True("profile: the first win grants nobody_class", Profile_IsUnlocked(_q, "nobody_class"));
    Test_Eq("profile: the newest history entry is last", _q.history[2].result, "won");
    Test_Eq("profile: history keeps the cause", _q.history[0].cause, "enemy 0");
    var _long = Profile_Default();
    for (var _i = 0; _i < PROFILE_HISTORY_MAX + 10; _i++) Profile_RecordRun(_long, { seed: _i, class_id: 0, level: 1, floor: 1, room: "rm_floor1", result: "died", cause: "x", kills: 0, gold: 0 });
    Test_Eq("profile: history is capped", array_length(_long.history), PROFILE_HISTORY_MAX);
    Test_Eq("profile: the cap keeps the newest entry", _long.history[PROFILE_HISTORY_MAX - 1].seed, PROFILE_HISTORY_MAX + 9);
    Test_Eq("profile: deaths are not capped", _long.deaths, PROFILE_HISTORY_MAX + 10);

    // file: round trip, version rejection, corrupt files (test-only names, never profile.sav)
    var _f = "test_profile.sav";
    Save_DeleteFileSet(_f);
    var _r0 = Profile_Load(_f);
    Test_Eq("profile file: missing file is reported as missing", _r0.status, "missing");
    Test_True("profile file: a missing file still gives a usable profile", _r0.profile.profile_version == PROFILE_VERSION);
    var _w = Profile_Default();
    Profile_StoryMark(_w, "cutscene:intro");
    Profile_Unlock(_w, "nobody_class");
    _w.echo = { kind: "item", id: 11 };
    _w.runs_started = 4;
    Profile_RecordRun(_w, { seed: 9, class_id: CLASS_ARCHER, level: 5, floor: 4, room: "rm_floor4", result: "died", cause: "enemy 5", kills: 8, gold: 0 });
    Test_True("profile file: write reports success", Profile_SaveTo(_f, _w));
    var _r1 = Profile_Load(_f);
    Test_Eq("profile file: reads back ok", _r1.status, "ok");
    Test_True("profile file: story survives", Profile_StorySeen(_r1.profile, "cutscene:intro"));
    Test_True("profile file: unlock survives", Profile_IsUnlocked(_r1.profile, "nobody_class"));
    Test_True("profile file: echo survives", _r1.profile.echo.kind == "item" && _r1.profile.echo.id == 11);
    Test_Eq("profile file: deaths survive", _r1.profile.deaths, 1);
    Test_Eq("profile file: runs started survives", _r1.profile.runs_started, 4);
    Test_Eq("profile file: history survives", _r1.profile.history[0].room, "rm_floor4");
    Test_False("profile file: no .tmp left", file_exists(_f + ".tmp"));
    // a second write keeps the first as .bak; a truncated main file loads from it
    _w.deaths = 5;
    Test_True("profile file: second write", Profile_SaveTo(_f, _w));
    var _good = Test_RawRead(_f);
    Test_RawWrite(_f, string_copy(_good, 1, string_length(_good) div 2));
    var _threw = false; var _r2 = undefined;
    try { _r2 = Profile_Load(_f); } catch (_e) { _threw = true; }
    Test_False("profile file: a truncated file does not throw", _threw);
    Test_Eq("profile file: a truncated file loads from .bak", is_struct(_r2) ? _r2.status : "none", "ok");
    Test_Eq("profile file: .bak holds the earlier profile", is_struct(_r2) ? _r2.profile.deaths : -1, 1);

    // newer version: rejected, file left alone, writing refused
    Save_DeleteFileSet(_f);
    var _newer = json_stringify({ profile_version: PROFILE_VERSION + 50, deaths: 3, marker: "keep me" });
    Test_RawWrite(_f, _newer);
    var _r3 = Profile_Load(_f);
    Test_Eq("profile file: a newer version is rejected", _r3.status, "newer");
    Test_True("profile file: a rejected file still gives a default profile", _r3.profile.profile_version == PROFILE_VERSION && _r3.profile.deaths == 0);
    Test_False("profile file: a rejected profile is not written", Profile_SaveTo(_f, _r3.profile));
    Test_Eq("profile file: a newer file is not overwritten", Test_RawRead(_f), _newer);
    Test_False("profile file: a newer file leaves no .bak or .tmp", file_exists(_f + ".bak") || file_exists(_f + ".tmp"));
    // no version at all: old
    Save_DeleteFileSet(_f);
    var _old = json_stringify({ deaths: 3 });
    Test_RawWrite(_f, _old);
    var _r4 = Profile_Load(_f);
    Test_Eq("profile file: no version is rejected as old", _r4.status, "old");
    Test_False("profile file: an old profile is not written", Profile_SaveTo(_f, _r4.profile));
    Test_Eq("profile file: an old file is not overwritten", Test_RawRead(_f), _old);
    // garbage: a fresh profile is usable, the bad file is kept aside as .corrupt
    Save_DeleteFileSet(_f);
    if (file_exists(_f + ".corrupt")) file_delete(_f + ".corrupt");
    Test_RawWrite(_f, " garbage {{{ ]]");
    _threw = false; var _r5 = undefined;
    try { _r5 = Profile_Load(_f); } catch (_e2) { _threw = true; }
    Test_False("profile file: garbage does not throw", _threw);
    Test_Eq("profile file: garbage is reported as corrupt", is_struct(_r5) ? _r5.status : "none", "corrupt");
    Test_True("profile file: garbage still gives a writable default", is_struct(_r5) && _r5.profile.profile_version == PROFILE_VERSION && Profile_SaveTo(_f, _r5.profile));
    Test_True("profile file: the corrupt file was kept as .corrupt", file_exists(_f + ".corrupt"));
    // a valid file that lacks keys is filled in
    Save_DeleteFileSet(_f);
    Test_RawWrite(_f, json_stringify({ profile_version: PROFILE_VERSION, deaths: 2 }));
    var _r6 = Profile_Load(_f);
    Test_True("profile file: missing keys are filled", _r6.status == "ok" && _r6.profile.deaths == 2 && is_array(_r6.profile.history) && is_struct(_r6.profile.story_seen) && is_struct(_r6.profile.unlocks));
    Save_DeleteFileSet(_f);
    if (file_exists(_f + ".corrupt")) file_delete(_f + ".corrupt");
}

function Test_Suite_RunSave() {
    // D132: closing the window saves like an autosave, never under the harness, never without a run
    Test_False("D132 save on close: never while the test harness runs", Run_SaveOnClose());
    var _gs_sc = GameState_Get();
    var _had_sc = variable_struct_exists(_gs_sc, "run");
    var _old_sc = _had_sc ? _gs_sc.run : undefined;
    if (_had_sc) variable_struct_remove(_gs_sc, "run");
    Test_False("D132 save on close: nothing to save without a run", Run_SaveOnClose(true));
    if (_had_sc) _gs_sc.run = _old_sc;
    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);
    var _had_run = variable_struct_exists(_gs, "run");
    var _old_run = _had_run ? _gs.run : undefined;
    var _old_cp = _gs.checkpoint;
    var _old_persist = _gs.persist;

    _gs.run = Run_Create(12345);
    repeat (5) RunRng_Float("loot");
    _gs.run.gold = 7;
    _gs.run.kills = 3;
    _gs.run.drop_dry = 4;   // R1 (D120)
    var _p = CharacterCreate_Player(CLASS_MAGE);
    _p.level = 3; _p.exp = 5;
    _p = Player_NormalizeProgression(_p, true);
    _p.hp = 7; _p.mp = 4;
    _p.skills = [SKILL_FIREBALL];
    _p.inventory = Inv_Add(_p.inventory, 11, 2);
    _p = Status_Add(_p, STATUS_POISON, 0, 1, 3);   // D78: poison is stacks
    _gs.player_ch = _p;
    _gs.selected_class = CLASS_MAGE;
    _gs.flags = { test_flag: 42 };
    _gs.checkpoint = { room: rm_floor3, x: 48, y: 64 };
    _gs.persist = { "rm_floor3:chest_a": { opened: true }, "rm_floor3:e1": { removed: true, enemy_id: 0, removed_reset_version: 0 } };

    var _predicted = Rng_Next(Rng_Load(Rng_Save(_gs.run.rng.loot)));
    var _raw = RunSave_Build();
    Test_Eq("runsave: run_version is current", _raw.run_version, RUN_SAVE_VERSION);
    Test_Eq("runsave: seed", _raw.seed, 12345);
    Test_Eq("runsave: loot stream counter", _raw.rng.loot.calls, 5);
    Test_Eq("runsave: untouched stream counter", _raw.rng.map.calls, 0);
    Test_Eq("runsave: gold", _raw.gold, 7);
    Test_Eq("runsave: kills", _raw.kills, 3);
    Test_Eq("runsave: dry-fight counter (R1 D120)", _raw.drop_dry, 4);
    Test_Eq("runsave: room name", _raw.statData.save_room_name, "rm_floor3");
    Test_Eq("runsave: floor number", _raw.floor, 3);
    Test_Eq("runsave: class", _raw.statData.selected_class, CLASS_MAGE);
    Test_Eq("runsave: level", _raw.statData.player.level, 3);
    Test_Eq("runsave: check says ok", RunSave_Check(json_parse(json_stringify(_raw))), "ok");

    var _f = "test_run.sav";
    Save_DeleteFileSet(_f);
    Test_False("runsave: no file yet", RunSave_ExistsAt(_f));
    Test_True("runsave: write reports success", RunSave_WriteTo(_f));
    Test_True("runsave: file exists after the write", RunSave_ExistsAt(_f));
    var _l = RunSave_LoadFrom(_f);
    Test_Eq("runsave: reads back ok", _l.status, "ok");

    // clobber the live state, then apply the loaded save
    _gs.run = Run_Create(99);
    _gs.player_ch = CharacterCreate_Player(CLASS_KNIGHT);
    _gs.selected_class = CLASS_KNIGHT;
    _gs.flags = {};
    _gs.persist = {};
    var _info = RunSave_ApplyState(_l.run);
    var _r = _gs.player_ch;
    Test_Eq("runsave: restored seed", _gs.run.seed, 12345);
    Test_True("runsave: restored run is active", _gs.run.active);
    Test_Eq("runsave: restored gold", _gs.run.gold, 7);
    Test_Eq("runsave: restored kills", _gs.run.kills, 3);
    Test_Eq("runsave: restored dry-fight counter (R1 D120)", _gs.run.drop_dry, 4);
    Test_Eq("runsave: restored loot counter", _gs.run.rng.loot.calls, 5);
    Test_Eq("runsave: the restored loot stream continues where it stopped", Rng_Next(_gs.run.rng.loot), _predicted);
    Test_Eq("runsave: restored class", _r.class_id, CLASS_MAGE);
    Test_Eq("runsave: restored level", _r.level, 3);
    Test_Eq("runsave: restored HP", _r.hp, 7);
    Test_Eq("runsave: restored MP", _r.mp, 4);
    Test_True("runsave: restored skills", array_length(_r.skills) == 1 && _r.skills[0] == SKILL_FIREBALL);
    Test_True("runsave: restored inventory (MP potion x2)", Inv_Has(_r.inventory, 11, 2));
    Test_True("runsave: restored Poison with 3 stacks (D78)", Status_Has(_r, STATUS_POISON) && Status_Stacks(_r, STATUS_POISON) == 3);
    Test_Eq("runsave: restored flags", variable_struct_get(_gs.flags, "test_flag"), 42);
    Test_Eq("runsave: the room to enter", _info.room_id, rm_floor3);
    Test_True("runsave: the position to enter", _info.x == 48 && _info.y == 64);
    Test_True("runsave: restored room state keeps a defeated enemy (enemies defeated this run)", variable_struct_exists(_gs.persist, "rm_floor3:e1"));
    Test_True("runsave: restored room state keeps an opened chest", variable_struct_exists(_gs.persist, "rm_floor3:chest_a"));

    // a second write keeps the first as .bak; a truncated main file loads from it
    _gs.run.gold = 8;
    Test_True("runsave: second write", RunSave_WriteTo(_f));
    var _good = Test_RawRead(_f);
    Test_RawWrite(_f, string_copy(_good, 1, string_length(_good) div 2));
    var _threw = false; var _l2 = undefined;
    try { _l2 = RunSave_LoadFrom(_f); } catch (_e) { _threw = true; }
    Test_False("runsave: a truncated file does not throw", _threw);
    Test_Eq("runsave: a truncated file loads from .bak", is_struct(_l2) ? _l2.status : "none", "ok");
    Test_Eq("runsave: .bak holds the earlier gold", is_struct(_l2) ? _l2.run.gold : -1, 7);

    // newer / old / garbage: rejected without a crash and without touching the file
    Save_DeleteFileSet(_f);
    var _newer = json_stringify({ run_version: RUN_SAVE_VERSION + 50, seed: 1, marker: "keep me" });
    Test_RawWrite(_f, _newer);
    var _l3 = RunSave_LoadFrom(_f);
    Test_Eq("runsave: a newer version is rejected", _l3.status, "newer");
    Test_Eq("runsave: a newer file is not overwritten", Test_RawRead(_f), _newer);
    Save_DeleteFileSet(_f);
    var _old = json_stringify({ save_version: 1, statData: { selected_class: 1 } });   // an old-format slot file
    Test_RawWrite(_f, _old);
    var _l4 = RunSave_LoadFrom(_f);
    Test_Eq("runsave: an old-format file is rejected", _l4.status, "old");
    Test_Eq("runsave: an old file is not overwritten", Test_RawRead(_f), _old);
    Save_DeleteFileSet(_f);
    var _slot = Test_SnapText("slot");   // the last slot format (D16): a perfectly good old save, but not a run
    Test_RawWrite(_f, _slot);
    Test_Eq("runsave: a last-version slot file is rejected as old", RunSave_LoadFrom(_f).status, "old");
    Test_Eq("runsave: a slot file is not overwritten either", Test_RawRead(_f), _slot);
    Save_DeleteFileSet(_f);
    Test_RawWrite(_f, "{{ not json");
    var _l5 = RunSave_LoadFrom(_f);
    Test_Eq("runsave: garbage is corrupt", _l5.status, "corrupt");
    Save_DeleteFileSet(_f);
    Test_Eq("runsave: a missing file is missing", RunSave_LoadFrom(_f).status, "missing");
    Test_False("runsave: delete leaves nothing", RunSave_ExistsAt(_f) || file_exists(_f + ".bak"));

    // D16: the old slot files are never the new files, and are recognised, not deleted
    Test_True("runsave: run.sav is not an old slot file", RunSave_Path() != Save_Path(0) && RunSave_Path() != Save_Path(1) && RunSave_Path() != Save_Path(2) && RunSave_Path() != Save_Path(3));
    Test_True("runsave: profile.sav is not an old slot file", Profile_Path() != Save_Path(0) && Profile_Path() != Save_Path(1) && Profile_Path() != Save_Path(2) && Profile_Path() != Save_Path(3));
    var _lg = "test_legacy0.sav";
    Test_RawWrite(_lg, _old);
    Test_True("legacy: an old slot file is recognised", Save_LegacyFilesExist([_lg]));
    Test_False("legacy: no old files means no notice", Save_LegacyFilesExist(["test_legacy_none.sav"]));
    Test_True("legacy: the friendly message is not empty", string_length(Save_LegacyNotice()) > 20);
    Test_False("legacy: an old file is not a current snapshot", is_struct(Save_LoadSnapshotFile(_lg)));
    Test_True("legacy: loading the old file does not delete it", file_exists(_lg));
    Test_Eq("legacy: the old file is unchanged", Test_RawRead(_lg), _old);
    file_delete(_lg);

    // Review 1: starting a new game clears an old-format run file (Continue would keep showing the old-slot notice), never a newer one
    var _ab = "test_abandon_run.sav";
    Save_DeleteFileSet(_ab);
    Test_RawWrite(_ab, _old);
    Test_Eq("review1: the old-format run file reads as old", RunSave_LoadFrom(_ab).status, "old");
    Run_AbandonSaved(_ab);
    Test_False("review1: Run_AbandonSaved deletes an old-format run file", RunSave_ExistsAt(_ab));
    Test_RawWrite(_ab, _newer);
    Run_AbandonSaved(_ab);
    Test_True("review1: Run_AbandonSaved keeps a newer-version run file", RunSave_ExistsAt(_ab));
    Test_Eq("review1: the newer run file is unchanged", Test_RawRead(_ab), _newer);
    Save_DeleteFileSet(_ab);
    Run_AbandonSaved(_ab);
    Test_False("review1: Run_AbandonSaved with no file does nothing", RunSave_ExistsAt(_ab));

    // restore the borrowed state
    if (_had_run) _gs.run = _old_run; else variable_struct_remove(_gs, "run");
    _gs.checkpoint = _old_cp;
    _gs.persist = _old_persist;
}

function Test_LootSig(_seed) {
    var _gs = GameState_Get();
    _gs.run = Run_Create(_seed);
    var _sig = "";
    for (var _i = 0; _i < 30; _i++) {
        var _items = Loot_RollContainer(2, "chest_basic");
        for (var _k = 0; _k < array_length(_items); _k++) _sig += string(_items[_k].item_id) + "x" + string(_items[_k].qty) + ",";
        _sig += "|";
        var _drop = Loot_RollEnemy({ id: ENEMY_SLIME, level: 3, loot_key: "enemy_elite" });
        for (var _j = 0; _j < array_length(_drop); _j++) _sig += string(_drop[_j].item_id) + "x" + string(_drop[_j].qty) + ",";
        _sig += ";";
    }
    return _sig;
}

function Test_Suite_RunLoop() {
    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);
    var _had_run = variable_struct_exists(_gs, "run");
    var _old_run = _had_run ? _gs.run : undefined;
    _gs.player_ch = CharacterCreate_Player(CLASS_KNIGHT);

    // D33: loot goes through the loot stream, so the same seed gives the same loot and another seed another
    var _a = Test_LootSig(4242);
    var _b = Test_LootSig(4242);
    var _c = Test_LootSig(4243);
    Test_True("run: the loot signature is not empty", string_length(_a) > 60);
    Test_Eq("run: the same seed gives the same loot", _a, _b);
    Test_True("run: another seed gives other loot", _a != _c);
    // disturbing the global random generator does not change the run's loot
    random_set_seed(1);
    repeat (50) random(1);
    var _d = Test_LootSig(4242);
    Test_Eq("run: global random() calls do not change the loot", _a, _d);

    // floors from room names
    Test_Eq("run: floor of rm_floor1", Run_FloorOfRoomName("rm_floor1"), 1);
    Test_Eq("run: floor of rm_floor9", Run_FloorOfRoomName("rm_floor9"), 9);
    Test_Eq("run: floor of rm_floor6_5", Run_FloorOfRoomName("rm_floor6_5"), 6.5);
    Test_Eq("run: floor of rm_start", Run_FloorOfRoomName("rm_start"), 0);

    // D87 echo: 1 of 3 from what you had
    var _ch = CharacterCreate_Player(CLASS_KNIGHT);   // starts with item 10 x2
    _ch.skills = [SKILL_HORIZ_SLASH, SKILL_FIREBALL];
    _ch.inventory = Inv_Add(_ch.inventory, 11, 1);
    _ch.inventory = Inv_Add(_ch.inventory, 2, 1);
    var _opts = Run_EchoOptions(_ch, Rng_New(4242, "loot"));
    Test_Eq("echo: three options when the run had plenty", array_length(_opts), 3);
    var _ok = true; var _dup = false;
    for (var _i = 0; _i < array_length(_opts); _i++) {
        var _o = _opts[_i];
        var _had = (_o.kind == "skill" && (_o.id == SKILL_HORIZ_SLASH || _o.id == SKILL_FIREBALL))
                || (_o.kind == "item" && (_o.id == 10 || _o.id == 11 || _o.id == 2));
        if (!_had) _ok = false;
        for (var _j = _i + 1; _j < array_length(_opts); _j++) { if (_opts[_j].kind == _o.kind && _opts[_j].id == _o.id) _dup = true; }
    }
    Test_True("echo: every option is something the run had", _ok);
    Test_False("echo: no option twice", _dup);
    var _opts2 = Run_EchoOptions(_ch, Rng_New(4242, "loot"));
    Test_True("echo: same seed, same options", array_length(_opts2) == 3 && _opts2[0].id == _opts[0].id && _opts2[1].id == _opts[1].id && _opts2[2].id == _opts[2].id);
    var _few = CharacterCreate_Player(CLASS_KNIGHT);
    Test_Eq("echo: a run with only the potion offers just that", array_length(Run_EchoOptions(_few, Rng_New(1, "loot"))), 1);
    var _none = CharacterCreate_Player(CLASS_KNIGHT);
    _none.inventory = [];
    _none.skills = [];
    var _fb = Run_EchoOptions(_none, Rng_New(1, "loot"));
    Test_True("echo: a run with nothing still offers one fallback item", array_length(_fb) == 1 && _fb[0].kind == "item" && _fb[0].id == 10);
    var _t1 = Run_ApplyEcho(CharacterCreate_Player(CLASS_KNIGHT), { kind: "item", id: 11 });
    Test_True("echo: an item echo goes into the inventory", Inv_Has(_t1.inventory, 11, 1));
    var _t2 = Run_ApplyEcho(CharacterCreate_Player(CLASS_KNIGHT), { kind: "skill", id: SKILL_FIREBALL });
    Test_True("echo: a skill echo is learned", array_length(_t2.skills) == 1 && _t2.skills[0] == SKILL_FIREBALL);
    var _t3 = Run_ApplyEcho(CharacterCreate_Player(CLASS_KNIGHT), { kind: "", id: -1 });
    Test_Eq("echo: no echo changes nothing", array_length(_t3.skills), 0);

    // enemies defeated this run are counted when the enemy is removed from its room
    _gs.run = Run_Create(5);
    RoomState_SetRemoved(rm_floor1, "c1_test_enemy", obj_enemy, ENEMY_SLIME);
    RoomState_SetRemoved(rm_floor1, "c1_test_pickup", noone);
    Test_Eq("run: a defeated enemy counts as a kill, a pickup does not", _gs.run.kills, 1);
    variable_struct_remove(_gs.persist, RoomState_Key(rm_floor1, "c1_test_enemy"));
    variable_struct_remove(_gs.persist, RoomState_Key(rm_floor1, "c1_test_pickup"));

    // history entry
    var _hr = Run_MakeHistoryEntry(Run_Create(77), _ch, "rm_floor4", "died", "enemy 5");
    Test_True("history: entry fields", _hr.seed == 77 && _hr.class_id == CLASS_KNIGHT && _hr.level == _ch.level && _hr.floor == 4 && _hr.room == "rm_floor4" && _hr.result == "died" && _hr.cause == "enemy 5");

    // story flags that live in the run's flags are copied to the profile and back (D26)
    var _prof = Profile_Default();
    var _fl = { floor1_slime_kill_reaction_done: true, skillbook_first_read_done: false, narrative_event_done_first_level_up_reaction: true, GraveLoot_progress: 2 };
    Story_CopyFlagsToProfile(_prof, _fl);
    Test_True("story: a done reaction flag reaches the profile", Profile_StorySeen(_prof, "flag:floor1_slime_kill_reaction_done"));
    Test_True("story: a narrative event flag reaches the profile", Profile_StorySeen(_prof, "flag:narrative_event_done_first_level_up_reaction"));
    Test_False("story: a flag that is false stays unseen", Profile_StorySeen(_prof, "flag:skillbook_first_read_done"));
    var _nf = {};
    Story_CopyProfileToFlags(_prof, _nf);
    Test_True("story: a new run's flags get the seen events", variable_struct_exists(_nf, "floor1_slime_kill_reaction_done") && variable_struct_get(_nf, "floor1_slime_kill_reaction_done") == true);
    Test_True("story: a new run's flags get the narrative events", variable_struct_exists(_nf, "narrative_event_done_first_level_up_reaction"));
    Test_False("story: unseen events are not set", variable_struct_exists(_nf, "skillbook_first_read_done") && variable_struct_get(_nf, "skillbook_first_read_done") == true);

    if (_had_run) _gs.run = _old_run; else variable_struct_remove(_gs, "run");
}

// ---- C5 story: death lines (D102-D104), wake line, boss banner (D106), lore notes (D107), closing text and credits (D105, D40) ----------
// Expected values come from the decisions: tiers 1st / 2-3 / 4-6 / 7-10 / 11+, a killer line while the tone is still light, never a spoiler
// of the ending (the raid party, the world outside), 2-4 s on screen, a ~1 s banner, 4 notes always plus 2 / 1 / 1 after 3 / 6 / 10 deaths.
function Test_StoryJoin(_arr) {
    var _s = "";
    for (var _i = 0; _i < array_length(_arr); _i++) _s += string(_arr[_i]) + "\n";
    return _s;
}

function Test_StoryVisibleNotes(_deaths) {
    var _c = 0;
    var _rooms = ["rm_floor1", "rm_floor2", "rm_floor3", "rm_floor4", "rm_floor5", "rm_floor6", "rm_floor6_5", "rm_floor7", "rm_floor8", "rm_floor9", "rm_floor9_5"];
    for (var _r = 0; _r < array_length(_rooms); _r++) _c += array_length(Note_ForRoom(_rooms[_r], _deaths));
    return _c;
}

function Test_Suite_Story() {
    // --- death tiers (pure)
    Test_Eq("D103 tier of the 1st death", DeathLine_Tier(1), 1);
    Test_Eq("D103 tier of the 2nd death", DeathLine_Tier(2), 2);
    Test_Eq("D103 tier of the 3rd death", DeathLine_Tier(3), 2);
    Test_Eq("D103 tier of the 4th death", DeathLine_Tier(4), 3);
    Test_Eq("D103 tier of the 6th death", DeathLine_Tier(6), 3);
    Test_Eq("D103 tier of the 7th death", DeathLine_Tier(7), 4);
    Test_Eq("D103 tier of the 10th death", DeathLine_Tier(10), 4);
    Test_Eq("D103 tier of the 11th death", DeathLine_Tier(11), 5);
    Test_Eq("D103 tier of the 80th death", DeathLine_Tier(80), 5);
    Test_Eq("D103 tier of a count of 0 is the first", DeathLine_Tier(0), 1);

    // --- the pick: tier first, killer second
    var _p1 = DeathLine_Pick(1, "enemy_slime", 0);
    Test_Eq("D103 1st death, slime: the slime line", _p1.key, "death.killer.enemy_slime");
    Test_Eq("D103 1st death picks tier 1", _p1.tier, 1);
    var _p1g = DeathLine_Pick(1, "enemy_slime", 1);
    Test_True("D103 1st death, another salt: a tier 1 line", string_pos("death.t1.", _p1g.key) == 1);
    var _p2 = DeathLine_Pick(2, "status_poison", 0);
    Test_Eq("D103 2nd death, poison: the poison line", _p2.key, "death.killer.status_poison");
    var _p3 = DeathLine_Pick(5, "enemy_spider", 0);
    Test_Eq("D103 5th death, spider: the spider line", _p3.key, "death.killer.enemy_spider");
    var _pa = DeathLine_Pick(2, "abandoned", 0);
    Test_Eq("D103 abandoning has its own line", _pa.key, "death.killer.abandoned");
    var _pu = DeathLine_Pick(1, "", 0);
    Test_True("D103 no known killer: a plain tier 1 line", string_pos("death.t1.", _pu.key) == 1);
    var _late = DeathLine_Pick(12, "enemy_spider", 0);
    Test_True("D103 12th death never gets a light killer line", string_pos("death.killer.", _late.key) != 1);
    Test_Eq("D103 12th death picks tier 5", _late.tier, 5);
    var _tiers_ok = true;
    for (var _d = 1; _d <= 14; _d++) {
        for (var _salt = 0; _salt < 6; _salt++) {
            var _pk = DeathLine_Pick(_d, (_salt mod 2 == 0) ? "enemy_snake" : "", _salt);
            if (_pk.tier != DeathLine_Tier(_d) || _pk.text == "") _tiers_ok = false;
            if (_pk.tier >= 4 && string_pos("death.killer.", _pk.key) == 1) _tiers_ok = false;
        }
    }
    Test_True("D103 every count and salt gives a line of its tier, none light at 7+", _tiers_ok);
    var _no_slot = true;
    for (var _s1 = 0; _s1 < 6; _s1++) { if (string_pos("{killer}", DeathLine_Pick(11, "", _s1).text) > 0) _no_slot = false; }
    for (var _s1b = 0; _s1b < 6; _s1b++) { if (string_pos("{killer}", DeathLine_Pick(11, "abandoned", _s1b).text) > 0) _no_slot = false; }
    Test_True("D103 a {killer} line is not offered without a killer", _no_slot);
    var _killer_line_late = false;
    for (var _s2 = 0; _s2 < 6; _s2++) { if (string_pos("{killer}", DeathLine_Pick(8, "enemy_snake", _s2).text) > 0) _killer_line_late = true; }
    Test_True("D103 late deaths still name what killed you", _killer_line_late);

    // --- the lines themselves
    var _all = DeathLine_All();
    Test_True("D103 about 25 death lines are written", array_length(_all) >= 20 && array_length(_all) <= 36);
    var _keys = {};
    var _dup = false;
    var _spoil = "";
    var _long = "";
    var _words = ["raid", "party", "outside", "apocal", "escape", "exit", "hope", "ending", "surface"];
    for (var _i = 0; _i < array_length(_all); _i++) {
        var _l = _all[_i];
        if (variable_struct_exists(_keys, _l.key)) _dup = true;
        variable_struct_set(_keys, _l.key, true);
        var _low = string_lower(_l.text);
        for (var _w = 0; _w < array_length(_words); _w++) { if (string_pos(_words[_w], _low) > 0) _spoil = _l.key; }
        if (string_length(_l.text) > 48) _long = _l.key;
    }
    Test_False("D103 no death line key twice", _dup);
    Test_Eq("D104 no death line gives the ending away", _spoil, "");
    Test_Eq("D103 every death line is terse (48 characters)", _long, "");
    var _early_in_late = false;
    var _pool1 = DeathLine_Pool(1, "");
    var _pool5 = DeathLine_Pool(11, "");
    for (var _i2 = 0; _i2 < array_length(_pool1); _i2++) {
        for (var _j2 = 0; _j2 < array_length(_pool5); _j2++) {
            if (_pool1[_i2].key == _pool5[_j2].key) _early_in_late = true;
        }
    }
    Test_False("D102 the lines darken: tier 1 and tier 5 share no line", _early_in_late);
    Test_True("D102 every tier has at least two lines", array_length(DeathLine_Pool(1, "")) >= 2 && array_length(DeathLine_Pool(3, "")) >= 2 && array_length(DeathLine_Pool(5, "")) >= 2);
    Test_Eq("D103 the {killer} slot is filled with the name", DeathLine_Format({ key: "x", text: "{killer} came." }, "Slime"), "Slime came.");

    // --- on screen 2-4 s (60 fps assumed by the caller)
    Test_Eq("D103 a short line holds the 2 s minimum", DeathScene_Frames("Short.", 60), 120);
    Test_Eq("D103 a long line holds the 4 s maximum", DeathScene_Frames(string_repeat("long ", 60), 60), 240);
    var _mid = DeathScene_Frames("The tunnel is not finished with you.", 60);
    Test_True("D103 a normal line is between 2 and 4 s", _mid >= 120 && _mid <= 240);

    // --- what killed you: a poison tick that takes the last HP is noted (scr_status), read once by Death_KillerKey
    Death_KillerKey("died");             // clears any note an earlier suite left (a status test can take a player to 0 HP)
    var _k0 = Death_KillerKey("died");   // what the battle context alone says
    var _pz = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_POISON, 0, 1, 4);
    _pz.hp = 50;
    _pz = Status_Tick(_pz);
    _pz = Status_Tick(_pz);
    Test_Eq("D103 a tick that leaves you alive is no killer", Death_KillerKey("died"), _k0);
    var _py = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_POISON, 0, 1, 4);
    _py.hp = 1;
    _py = Status_Tick(_py);
    _py = Status_Tick(_py);
    Test_Eq("D103 the poison tick that finishes you is the killer", Death_KillerKey("died"), "status_poison");
    Test_Eq("D103 the killer note is used up once read", Death_KillerKey("died"), _k0);
    Test_Eq("D103 giving up the run is its own killer", Death_KillerKey("abandoned"), "abandoned");

    // --- the wake line
    Test_True("D102 a wake line for every count", WakeLine_Pick(1).text != "" && WakeLine_Pick(3).text != "" && WakeLine_Pick(8).text != "" && WakeLine_Pick(40).text != "");
    Test_True("D102 the wake lines darken too", WakeLine_Pick(1).key != WakeLine_Pick(8).key);

    // --- banner (D106)
    var _bf = Banner_DurMs();   // D108 F2b-2: ms (was Banner_Frames(60) = 60 frames)
    Test_True("D106 the boss banner lasts about 1 s", _bf >= 900 && _bf <= 1200);
    Test_Eq("D106 banner is clear before it starts", Banner_Alpha(0, _bf), 0);
    Test_Eq("D106 banner is full in the middle", Banner_Alpha(_bf / 2, _bf), 1);
    Test_Eq("D106 banner is clear when it ends", Banner_Alpha(_bf, _bf), 0);
    Test_True("D106 banner fades in", Banner_Alpha(4000 / 60, _bf) > 0 && Banner_Alpha(4000 / 60, _bf) < 1);   // 4 frames in

    // --- notes (D107)
    var _defs = Note_Defs();
    Test_Eq("D107 eight notes", array_length(_defs), 8);
    var _n0 = 0; var _n3 = 0; var _n6 = 0; var _n10 = 0; var _ids = {}; var _iddup = false; var _bad_pos = ""; var _bad_room = "";
    for (var _n = 0; _n < array_length(_defs); _n++) {
        var _d2 = _defs[_n];
        if (_d2.min_deaths == 0) _n0++;
        if (_d2.min_deaths == 3) _n3++;
        if (_d2.min_deaths == 6) _n6++;
        if (_d2.min_deaths == 10) _n10++;
        if (variable_struct_exists(_ids, _d2.id)) _iddup = true;
        variable_struct_set(_ids, _d2.id, true);
        if (_d2.tx < 0 || _d2.ty < 0) _bad_pos = _d2.id;
        if (asset_get_index(_d2.room) == -1) _bad_room = _d2.id;
        if (array_length(_d2.lines) < 2) _bad_pos = _d2.id;
    }
    Test_Eq("D107 four notes are always there", _n0, 4);
    Test_Eq("D107 two notes after 3 deaths", _n3, 2);
    Test_Eq("D107 one note after 6 deaths", _n6, 1);
    Test_Eq("D107 one note after 10 deaths", _n10, 1);
    Test_False("D107 note ids are unique", _iddup);
    Test_Eq("D107 every note has a place and a text", _bad_pos, "");
    Test_Eq("D107 every note is in a room that exists", _bad_room, "");
    Test_Eq("D107 no deaths: 4 notes in the world", Test_StoryVisibleNotes(0), 4);
    Test_Eq("D107 2 deaths: still 4", Test_StoryVisibleNotes(2), 4);
    Test_Eq("D107 3 deaths: 6", Test_StoryVisibleNotes(3), 6);
    Test_Eq("D107 5 deaths: 6", Test_StoryVisibleNotes(5), 6);
    Test_Eq("D107 6 deaths: 7", Test_StoryVisibleNotes(6), 7);
    Test_Eq("D107 9 deaths: 7", Test_StoryVisibleNotes(9), 7);
    Test_Eq("D107 10 deaths: 8", Test_StoryVisibleNotes(10), 8);
    Test_Eq("D107 rm_floor1 has a note from the start", array_length(Note_ForRoom("rm_floor1", 0)), 1);
    Test_Eq("D107 a room without notes gives none", array_length(Note_ForRoom("rm_battle", 99)), 0);
    var _prof = Profile_Default();
    Test_Eq("D107 nothing collected in a new profile", array_length(Note_Collected(_prof)), 0);
    Note_MarkCollected(_prof, _defs[2].id);
    Note_MarkCollected(_prof, _defs[0].id);
    Note_MarkCollected(_prof, _defs[0].id);
    var _col = Note_Collected(_prof);
    Test_True("D107 collected notes are recorded once, in note order", array_length(_col) == 2 && _col[0].id == _defs[0].id && _col[1].id == _defs[2].id);
    Test_True("D107 the Codex data has a title and lines", _col[0].title != "" && array_length(_col[0].lines) >= 2);
    var _note_text = "";
    for (var _n2 = 0; _n2 < array_length(_defs); _n2++) { _note_text += string_lower(Test_StoryJoin(_defs[_n2].lines)); }
    Test_True("D104 no note gives the ending away", string_pos("apocal", _note_text) == 0 && string_pos("raid party", _note_text) == 0 && string_pos("end of the world", _note_text) == 0);

    // --- closing text and credits (D105, D40)
    var _close = Story_ClosingLines();
    var _cj = Test_StoryJoin(_close);
    Test_True("D105 the closing text keeps 'Thank you for playing...'", _close[0] == "Thank you for playing...");
    Test_True("D105 the closing text keeps 'by PaleRook'", string_pos("by PaleRook", _cj) > 0);
    Test_True("D105 no prototype wording", string_pos("prototype", string_lower(_cj)) == 0);
    Test_True("D105 no 2 months wording", string_pos("months", string_lower(_cj)) == 0);
    var _loc_ok = true;
    for (var _ci = 0; _ci < array_length(_close); _ci++) {
        var _en = Loc_GetRaw("cutscene.ending.4." + string(_ci), "en");
        var _ko = Loc_GetRaw("cutscene.ending.4." + string(_ci), "ko");
        if (_en != _close[_ci] || _ko == "" || string_digits(_ko) != "") _loc_ok = false;   // the old Korean line named "2 months" (a digit)
    }
    Test_True("D105 the localization workbook has the same closing text in English and Korean", _loc_ok);
    var _cr = Test_StoryJoin(Credits_PlainLines());
    Test_True("D105 credits: game by PaleRook", string_pos("PaleRook", _cr) > 0);
    Test_True("D105 credits: Galmuri by Lee Minseo", string_pos("Galmuri", _cr) > 0 && string_pos("Lee Minseo", _cr) > 0);
    Test_True("D105 credits: the OFL-1.1 licence", string_pos("OFL-1.1", _cr) > 0);
    Test_True("D105 credits: GameMaker", string_pos("GameMaker", _cr) > 0);
    Test_True("D105 credits: the existing pixel font", string_pos("Retro Gaming", _cr) > 0);
    var _snd = Credits_SoundAssets();
    var _snd_missing = "";
    var _snd_dup = false;
    for (var _si = 0; _si < array_length(_snd); _si++) {
        if (string_pos(_snd[_si].asset, _cr) == 0) _snd_missing = _snd[_si].asset;
        for (var _sj = _si + 1; _sj < array_length(_snd); _sj++) { if (_snd[_sj].asset == _snd[_si].asset) _snd_dup = true; }
    }
    // (asset_get_index cannot vouch for every name: a build leaves out sounds no code uses. The list was generated from the sounds/ folder; a Python comparison of the two ran when it was written.)
    Test_True("D40 sounds the game plays are in the list", asset_get_index("Body_falling_wood") != -1 && _snd[array_length(_snd) - 1].asset != "" && string_pos("Body_falling_wood", _cr) > 0 && string_pos("Metal_resonance", _cr) > 0);
    Test_False("D40 no sound listed twice", _snd_dup);
    Test_Eq("D40 every credited sound appears in the credits text", _snd_missing, "");
    var _old_n = 0, _new_n = 0, _new_bad = "", _creators_ok = true;
    for (var _ni = 0; _ni < array_length(_snd); _ni++) {
        if (_snd[_ni].creator == CREDITS_CREATOR_TBD) { _old_n++; continue; }
        _new_n++;
        if (_snd[_ni].creator != "rubberduck" && _snd[_ni].creator != "Ogrebane" && _snd[_ni].creator != "Darsycho") _creators_ok = false;
        var _nm = _snd[_ni].asset;   // <monster>_spawn_N or <monster>_attack_N, N = 2..4 (D116)
        var _us = string_last_pos("_", _nm);
        var _n_ok = _us > 0 && string_digits(string_copy(_nm, _us + 1, 9)) != "" && real(string_copy(_nm, _us + 1, 9)) >= 2 && real(string_copy(_nm, _us + 1, 9)) <= 4;
        var _stem = _us > 0 ? string_copy(_nm, 1, _us - 1) : _nm;
        var _ev_ok = string_pos("_spawn", _stem) == string_length(_stem) - 5 || string_pos("_attack", _stem) == string_length(_stem) - 6;
        if (!_n_ok || !_ev_ok) _new_bad += _nm + " ";
    }
    Test_Eq("D40 all 126 original sounds and music tracks are listed (creator still to supply)", _old_n, 126);
    Test_Eq("D116 the 30 new CC0 monster takes are credited by name", _new_n, 30);
    Test_True("D116 each new take is credited to rubberduck, Ogrebane or Darsycho", _creators_ok);
    Test_Eq("D116 new take names follow <monster>_spawn_N / <monster>_attack_N", _new_bad, "");
    Test_True("D116 the credits name rubberduck, Ogrebane and Darsycho", string_pos("rubberduck", _cr) > 0 && string_pos("Ogrebane", _cr) > 0 && string_pos("Darsycho", _cr) > 0);
    Test_True("D116 the credited takes run from slime_spawn_2 to final_boss_attack_3", _new_n == 30 && string_pos("slime_spawn_2", _cr) > 0 && string_pos("final_boss_attack_3", _cr) > 0);
    Test_Eq("D40 until the owner sends names the creator is the marked placeholder", _snd[0].creator, CREDITS_CREATOR_TBD);
    Test_True("D105 credits come with headings and spacing", array_length(Credits_Lines()) > array_length(Credits_PlainLines()));
    Test_DialogueStartChecks();
}

// D108 F4b: what each Dialogue_Start* leaves in the UI state (characterization: the three openers share one body). Runs on a private copy of
// the UI state; the UI controller is removed again if the openers had to create it.
function Test_DialogueStartCheck(_tag, _gs, _speaker_want, _raw_want) {
    var _u = _gs.ui;
    Test_Eq(_tag + " speaker", _u.speaker, _speaker_want);
    Test_Eq(_tag + " raw lines are the ones given", json_stringify(_u.lines_raw), json_stringify(_raw_want));
    Test_True(_tag + " the lines are paged (at least one)", is_array(_u.lines) && array_length(_u.lines) >= 1);
    Test_Eq(_tag + " index 0", _u.index, 0);
    Test_Eq(_tag + " mode is dialogue", _u.mode, UI_DIALOGUE);
    Test_Eq(_tag + " no ambience key", Dialogue_GetActiveAmbienceSfxKey(), "");
    Test_Eq(_tag + " no choice", is_undefined(_u.choice), true);
    Test_Eq(_tag + " opened this frame", _u.opened_frame, Input_Frame());
    Test_Eq(_tag + " confirm action", _u.confirm_action, "confirm");
    Test_Eq(_tag + " typewriter restarts", _u.dialogue_state, UI_DIALOGUE_STATE_REVEALING);
    Test_Eq(_tag + " typewriter shows nothing yet", _u.dialogue_visible_count, 0);
    Test_Eq(_tag + " typewriter line index reset", _u.dialogue_tw_line_index, -1);
    Test_Eq(_tag + " the layout was recorded", _u.dialogue_layout_has_speaker, (_speaker_want != ""));
}

function Test_DialogueStartChecks() {
    var _gs = GameState_Get();
    var _had_ui = variable_struct_exists(_gs, "ui");
    var _ui0 = _had_ui ? _gs.ui : undefined;
    var _had_ctl = instance_exists(obj_ui_controller);
    var _ui = {};
    if (is_struct(_ui0)) {
        var _names = variable_struct_get_names(_ui0);
        for (var _n = 0; _n < array_length(_names); _n++) variable_struct_set(_ui, _names[_n], variable_struct_get(_ui0, _names[_n]));
    }
    _ui.mode = UI_NONE;
    _ui.cutscene_active = false;
    _ui.cutscene_text_only = true;
    _ui.dialogue_box_half = false;
    _gs.ui = _ui;

    // Dialogue_StartLines: no speaker, the given lines; a stale text-only flag is cleared when no cutscene is on
    var _lines = ["First line.", "Second line."];
    _ui.choice = { stale: true };
    _ui.dialogue_open_lock = undefined;   // D108 F2b-2: was dialogue_open_block_frame = 12345
    Dialogue_StartLines(_lines);
    Test_DialogueStartCheck("F4b StartLines", _gs, "", _lines);
    Test_False("F4b StartLines clears the text-only flag outside a cutscene", _gs.ui.cutscene_text_only);
    Test_True("F4b StartLines open block is the open frame only (no cutscene text)", is_struct(_gs.ui.dialogue_open_lock) && _gs.ui.dialogue_open_lock.frame0 == _gs.ui.opened_frame && _gs.ui.dialogue_open_lock.ms == 0);
    Test_True("F4b StartLines stamps the slide-in time", _gs.ui.dialogue_open_ms <= current_time && _gs.ui.dialogue_open_ms >= 0);
    Dialogue_StartLines("nope");
    Test_Eq("F4b StartLines with a non-array gives no raw lines", array_length(_gs.ui.lines_raw), 0);

    // Dialogue_StartWithSpeaker: the speaker and the given lines
    Dialogue_SetActiveAmbienceSfxKey("stale_key");
    _gs.ui.cutscene_text_only = true;
    Dialogue_StartWithSpeaker("Hero", _lines);
    Test_DialogueStartCheck("F4b StartWithSpeaker", _gs, "Hero", _lines);
    Test_False("F4b StartWithSpeaker clears the text-only flag outside a cutscene", _gs.ui.cutscene_text_only);
    Dialogue_StartWithSpeaker("Hero", 5);
    Test_Eq("F4b StartWithSpeaker with a non-array gives no raw lines", array_length(_gs.ui.lines_raw), 0);

    // Dialogue_Start: no speaker, the lines of the dialogue id from the database ("default" for an unknown id)
    Dialogue_StartWithSpeaker("Hero", _lines);
    Dialogue_Start("no_such_dialogue_id_f4b");
    Test_DialogueStartCheck("F4b Start", _gs, "", DialogueDB_Get("default"));
    Dialogue_SetActiveAmbienceSfxKey("stale_key");
    Dialogue_Start("first_encounter_slime");
    Test_DialogueStartCheck("F4b Start (slime)", _gs, "", DialogueDB_Get("first_encounter_slime"));

    // a cutscene keeps its text-only flag and blocks the advance for the shared number of frames
    _gs.ui.cutscene_active = true;
    _gs.ui.cutscene_text_only = true;
    Dialogue_StartLines(_lines);
    Test_True("F4b StartLines keeps the text-only flag during a cutscene", _gs.ui.cutscene_text_only);
    Test_True("F4b StartLines in a text-only cutscene blocks the advance for the shared frames", is_struct(_gs.ui.dialogue_open_lock) && _gs.ui.dialogue_open_lock.frame0 == _gs.ui.opened_frame && _gs.ui.dialogue_open_lock.ms == UI_CUTSCENE_ADVANCE_BLOCK_MS);
    Dialogue_StartWithSpeaker("Hero", _lines);
    Test_True("F4b StartWithSpeaker in a text-only cutscene blocks the advance for the shared frames", is_struct(_gs.ui.dialogue_open_lock) && _gs.ui.dialogue_open_lock.frame0 == _gs.ui.opened_frame && _gs.ui.dialogue_open_lock.ms == UI_CUTSCENE_ADVANCE_BLOCK_MS);
    Dialogue_Start("first_encounter_slime");
    Test_True("F4b Start in a text-only cutscene blocks the advance for the shared frames", is_struct(_gs.ui.dialogue_open_lock) && _gs.ui.dialogue_open_lock.frame0 == _gs.ui.opened_frame && _gs.ui.dialogue_open_lock.ms == UI_CUTSCENE_ADVANCE_BLOCK_MS);
    _gs.ui.cutscene_active = false;

    // opening closes the pause menu first
    _gs.ui.mode = UI_PAUSE;
    Dialogue_StartLines(_lines);
    Test_Eq("F4b opening over the pause menu leaves the dialogue open", _gs.ui.mode, UI_DIALOGUE);

    // Dialogue_StartChoice picks the opener by the speaker and then sets the choice
    Dialogue_StartChoice("", _lines, ["Yes", "No"], undefined);
    Test_True("F4b StartChoice without a speaker: no speaker and a choice", _gs.ui.speaker == "" && is_struct(_gs.ui.choice) && array_length(_gs.ui.choice.labels) == 2);
    Dialogue_StartChoice("Hero", _lines, ["Yes", "No"], undefined, true);
    Test_True("F4b StartChoice with a speaker: the speaker, the choice and allow_back", _gs.ui.speaker == "Hero" && is_struct(_gs.ui.choice) && _gs.ui.choice.allow_back);

    if (_had_ui) _gs.ui = _ui0; else variable_struct_remove(_gs, "ui");
    if (!_had_ctl && instance_exists(obj_ui_controller)) instance_destroy(obj_ui_controller);
}

// ---- D0 shared UI framework (D95-D98): the pure menu model in scr_menu.gml ("UI FRAMEWORK") ----------------------------------------
// Expected values come from the decisions: D95 (wrap-around, hold-to-scroll after about 300 ms and accelerating, back = ONE level,
// cursor remembered per menu id, hover/click/right-click/wheel), D97 (panels 120 ms) and the Galmuri native sizes (9 and 11 px).
function Test_UiFireTimes(_dir, _ms_total) {
    var _r = Ui_RepeatNew();
    var _t0 = 5000;
    var _times = [];
    if (Ui_RepeatStep(_r, _dir, true, _t0) > 0) array_push(_times, 0);
    for (var _ms = 4; _ms <= _ms_total; _ms += 4) {
        if (Ui_RepeatStep(_r, _dir, false, _t0 + _ms) > 0) array_push(_times, _ms);
    }
    return _times;
}

// D108 F1b: the font scale and Ui_Metrics are built once per (layout, language) and the same struct comes back until one of them changes.
function Test_MetricsSame(_name, _a, _b) {
    var _ok = true;
    var _keys = ["p", "line_h", "row_h", "pad", "margin", "gw", "gh"];
    for (var _i = 0; _i < array_length(_keys); _i++) {
        if (variable_struct_get(_a, _keys[_i]) != variable_struct_get(_b, _keys[_i])) _ok = false;
    }
    Test_True(_name, _ok);
}

function Test_Suite_MetricsCache() {
    var _lang0 = Loc_GetLanguage();
    var _disp0 = variable_global_exists("display") ? global.display : undefined;
    var _own = !(is_struct(_disp0) && is_struct(_disp0.layout));
    var _layout0 = _own ? Display_CalcLayout(480, 432) : _disp0.layout;
    if (_own) global.display = { layout: _layout0, apply_count: 0 };
    var _d = global.display;
    var _f0 = draw_get_font();

    // en, nothing changing: 300 calls build nothing more and return the very same struct; the font is still set each time.
    Loc_SetLanguage("en");
    var _mt_en = Ui_Metrics();
    UI_GetFontScale();
    var _b0 = Ui_MetricsBuilds();
    var _s0 = UI_FontScaleBuilds();
    var _same = true;
    var _font_ok = true;
    for (var _i = 0; _i < 300; _i++) {
        draw_set_font(-1);
        var _m = Ui_Metrics();
        if (_m != _mt_en) _same = false;
        if (draw_get_font() != UI_FONT) _font_ok = false;
        UI_GetFontScale();
    }
    Test_Eq("F1b 300 Ui_Metrics calls build nothing more", Ui_MetricsBuilds() - _b0, 0);
    Test_Eq("F1b 300 UI_GetFontScale calls build nothing more", UI_FontScaleBuilds() - _s0, 0);
    Test_True("F1b Ui_Metrics returns the same struct while nothing changes", _same);
    Test_True("F1b Ui_Metrics still sets the UI font on a cached call", _font_ok);
    var _fs_en = UI_GetFontScale();
    var _ref = Ui_MetricsBuild();
    Test_Eq("F1b en font scale equals the uncached one", _fs_en, UI_FontScaleBuild());
    Test_MetricsSame("F1b en metrics equal the uncached ones", _mt_en, _ref);

    // en -> ko: one rebuild of each, then cached again.
    _b0 = Ui_MetricsBuilds();
    _s0 = UI_FontScaleBuilds();
    Loc_SetLanguage("ko");
    var _mt_ko = Ui_Metrics();
    for (var _i2 = 0; _i2 < 300; _i2++) { Ui_Metrics(); UI_GetFontScale(); }
    Test_Eq("F1b en to ko rebuilds the metrics exactly once", Ui_MetricsBuilds() - _b0, 1);
    Test_Eq("F1b en to ko rebuilds the font scale exactly once", UI_FontScaleBuilds() - _s0, 1);
    Test_True("F1b the ko metrics are a new struct", _mt_ko != _mt_en);
    Test_True("F1b ko returns the same struct on repeat", Ui_Metrics() == _mt_ko);
    var _fs_ko = UI_GetFontScale();
    _ref = Ui_MetricsBuild();
    Test_Eq("F1b ko font scale equals the uncached one", _fs_ko, UI_FontScaleBuild());
    Test_MetricsSame("F1b ko metrics equal the uncached ones", _mt_ko, _ref);
    draw_set_font(-1);
    Ui_Metrics();
    Test_Eq("F1b ko cached call sets the font the uncached call sets", draw_get_font(), (UI_KoFont() != -1) ? UI_KoFont() : UI_FONT);

    // ko -> en: back to the English values.
    _b0 = Ui_MetricsBuilds();
    _s0 = UI_FontScaleBuilds();
    Loc_SetLanguage("en");
    var _mt_en2 = Ui_Metrics();
    for (var _i3 = 0; _i3 < 300; _i3++) { Ui_Metrics(); UI_GetFontScale(); }
    Test_Eq("F1b ko to en rebuilds the metrics exactly once", Ui_MetricsBuilds() - _b0, 1);
    Test_Eq("F1b ko to en rebuilds the font scale exactly once", UI_FontScaleBuilds() - _s0, 1);
    Test_MetricsSame("F1b back in en the metrics equal the first en ones", _mt_en2, _mt_en);
    Test_Eq("F1b back in en the font scale equals the first en one", UI_GetFontScale(), _fs_en);

    // A relayout (a new layout struct, as Display_Relayout makes) rebuilds once; restoring the old layout rebuilds once more.
    _b0 = Ui_MetricsBuilds();
    _s0 = UI_FontScaleBuilds();
    _d.layout = Display_CalcLayout(1280, 720);
    var _mt_big = Ui_Metrics();
    for (var _i4 = 0; _i4 < 300; _i4++) { Ui_Metrics(); UI_GetFontScale(); }
    Test_Eq("F1b a relayout rebuilds the metrics exactly once", Ui_MetricsBuilds() - _b0, 1);
    Test_Eq("F1b a relayout rebuilds the font scale exactly once", UI_FontScaleBuilds() - _s0, 1);
    Test_True("F1b the new layout's metrics are a new struct", _mt_big != _mt_en2);
    Test_Eq("F1b the new layout's gui width is in the metrics", _mt_big.gw, Display_GuiW());
    _ref = Ui_MetricsBuild();
    Test_MetricsSame("F1b relayout metrics equal the uncached ones", _mt_big, _ref);
    Test_Eq("F1b relayout font scale equals the uncached one", UI_GetFontScale(), UI_FontScaleBuild());
    _b0 = Ui_MetricsBuilds();
    _d.layout = _layout0;
    var _mt_back = Ui_Metrics();
    Ui_Metrics();
    Test_Eq("F1b restoring the layout rebuilds the metrics exactly once", Ui_MetricsBuilds() - _b0, 1);
    Test_MetricsSame("F1b the restored layout's metrics equal the first ones", _mt_back, _mt_en);

    // [PERF] 1000 x Ui_Metrics + 1000 x UI_TextWidth (no assertion: the time depends on the PC)
    var _t0 = get_timer();
    for (var _i5 = 0; _i5 < 1000; _i5++) Ui_Metrics();
    var _t1 = get_timer();
    for (var _i6 = 0; _i6 < 1000; _i6++) UI_TextWidth("Wooden Sword");
    var _t2 = get_timer();
    Test_Log("[PERF] 1000 x Ui_Metrics: " + string(_t1 - _t0) + " us, 1000 x UI_TextWidth: " + string(_t2 - _t1) + " us");

    draw_set_font(_f0);
    if (_own) global.display = _disp0;
    Loc_SetLanguage(_lang0);
}

// D108 F1c: the menus measure their rows once per change, and the Tab menu's data is built once.
// A 25-row menu with a details panel (the shop's shape): item rows with a name, a value, a sentence and number lines, one slider row and one choice row.
function Test_MenuRows(_n, _tag) {
    var _rows = [];
    for (var _i = 0; _i < _n; _i++) {
        var _r = {
            id: "r" + string(_i), kind: "button", enabled: true,
            label: _tag + " row " + string(_i) + (((_i mod 5) == 0) ? " with a longer name" : ""),
            value: string(_i * 10) + "g", help: "", lines: []
        };
        repeat ((_i mod 4) + 1) _r.help += "A sentence about row " + string(_i) + " that is long enough to wrap in the details panel. ";
        repeat (_i mod 3) array_push(_r.lines, { label: "Stat", value: string(_i) });
        if (_i == 3) { _r.kind = "slider"; _r.value = "50%"; _r.amount = 0.5; }
        if (_i == 4) { _r.kind = "choice"; _r.value = "On"; _r.measure = ["On", "Off"]; }
        array_push(_rows, _r);
    }
    return _rows;
}

// The measuring as it was before the cache (every frame): the expected widths and heights.
function Test_MenuRef(_m, _mt) {
    var _p = _mt.p;
    var _L = _m.layout;
    var _lw = 0;
    var _vw = 0;
    for (var _i = 0; _i < array_length(_m.items); _i++) {
        var _it = _m.items[_i];
        _lw = max(_lw, UI_TextWidth(_it.label));
        var _kind = variable_struct_exists(_it, "kind") ? _it.kind : "button";
        var _w = 0;
        if (_kind == "slider") _w = 14 * _p + 2 * _p + UI_TextWidth("100%");
        else if (variable_struct_exists(_it, "value") && _it.value != "") {
            var _texts = variable_struct_exists(_it, "measure") ? _it.measure : [_it.value];
            for (var _t = 0; _t < array_length(_texts); _t++) _w = max(_w, UI_TextWidth(_texts[_t]));
            if (_kind == "choice") _w += 10 * _p;
        }
        _vw = max(_vw, _w);
    }
    var _title_w = (_L.title != "") ? UI_TextWidth(_L.title) : 0;
    var _inner = max(5 * _p + _lw + ((_vw > 0) ? 4 * _p + _vw : 0), _title_w);
    var _pw = min(_inner + 8 * _p, _mt.gw - 2 * _mt.margin);
    if (_L.details && _L.panel_w <= 0) _pw = min(max(_pw, round(_mt.gw * 0.78)), _mt.gw - 2 * _mt.margin);
    if (_L.panel_w > 0) _pw = min(_L.panel_w, _mt.gw - 2 * _mt.margin);
    var _dh = 0;
    if (_L.details) {
        for (var _d = 0; _d < array_length(_m.items); _d++) {
            var _di = _m.items[_d];
            _dh = max(_dh, Ui_DetailsHeight(_pw, _di.help, _di.lines, _L.details_cols, 0));
        }
    }
    return { label_w: _lw, val_w: _vw, panel_w: _pw, det_h: _dh };
}

function Test_MenuSame(_name, _mc, _ref) {
    Test_Eq(_name + ": label width", _mc.label_w, _ref.label_w);
    Test_Eq(_name + ": value width", _mc.val_w, _ref.val_w);
    Test_Eq(_name + ": panel width", _mc.panel_w, _ref.panel_w);
    Test_Eq(_name + ": details height", _mc.det_h, _ref.det_h);
}

// The measuring path the way Ui_MenuDraw calls it: Ui_Metrics, then Ui_MenuMeasure. Returns the measured struct of the last call.
function Test_MenuFrames(_m, _n) {
    var _mc = undefined;
    for (var _i = 0; _i < _n; _i++) _mc = Ui_MenuMeasure(_m, Ui_Metrics());
    return _mc;
}

function Test_Suite_MenuMeasure() {
    var _lang0 = Loc_GetLanguage();
    var _disp0 = variable_global_exists("display") ? global.display : undefined;
    var _own = !(is_struct(_disp0) && is_struct(_disp0.layout));
    if (_own) global.display = { layout: Display_CalcLayout(480, 432), apply_count: 0 };
    var _f0 = draw_get_font();
    Loc_SetLanguage("en");
    var _mt = Ui_Metrics();

    // ---- a 25-row details menu: 300 frames measure once ----
    var _m = Ui_MenuNew("f1c_measure", Test_MenuRows(25, "A"), { layout: { title: "Shop", details: true } });
    var _b0 = Ui_MenuMeasureBuilds();
    var _d0 = Ui_MenuDetailsBuilds();
    var _mc = Test_MenuFrames(_m, 300);
    Test_Eq("F1c 300 frames of a 25-row details menu measure the rows once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_Eq("F1c 300 frames of a 25-row details menu measure the details height once", Ui_MenuDetailsBuilds() - _d0, 1);
    Test_True("F1c the details panel has a height", _mc.det_h > 0);
    Test_MenuSame("F1c first measure equals the per-frame one", _mc, Test_MenuRef(_m, Ui_Metrics()));

    // ---- a new items array (a shop after a purchase, a refreshed list) measures again, once ----
    _b0 = Ui_MenuMeasureBuilds();
    _d0 = Ui_MenuDetailsBuilds();
    _m.items = Test_MenuRows(25, "Bb");
    _mc = Test_MenuFrames(_m, 300);
    Test_Eq("F1c a new items array measures the rows exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_Eq("F1c a new items array measures the details height exactly once", Ui_MenuDetailsBuilds() - _d0, 1);
    Test_MenuSame("F1c new items array", _mc, Test_MenuRef(_m, Ui_Metrics()));
    _b0 = Ui_MenuMeasureBuilds();
    _m.items = array_concat(_m.items, [Test_MenuRows(1, "Extra row with a much longer name than all the others")[0]]);   // one more row
    _mc = Test_MenuFrames(_m, 50);
    Test_Eq("F1c one more row measures exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_MenuSame("F1c one more row", _mc, Test_MenuRef(_m, Ui_Metrics()));

    // ---- a row changed in place: a settings volume 50% -> 60%, a label, a sentence ----
    _b0 = Ui_MenuMeasureBuilds();
    _m.items[3].value = "60%";
    _mc = Test_MenuFrames(_m, 50);
    Test_Eq("F1c a value changed in place measures exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_MenuSame("F1c slider value in place", _mc, Test_MenuRef(_m, Ui_Metrics()));
    _b0 = Ui_MenuMeasureBuilds();
    var _lw0 = _mc.label_w;
    _m.items[7].label = "A label changed in place to something very much longer than before, and then some more words to make it the longest label in the whole menu by far";
    _mc = Test_MenuFrames(_m, 50);
    Test_Eq("F1c a label changed in place measures exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_True("F1c the longer label widens the menu", _mc.label_w > _lw0);
    Test_MenuSame("F1c label in place", _mc, Test_MenuRef(_m, Ui_Metrics()));
    _b0 = Ui_MenuMeasureBuilds();
    var _dh0 = _mc.det_h;
    repeat (12) _m.items[9].help += "Many more words that make this sentence a good deal taller than any other. ";
    _mc = Test_MenuFrames(_m, 50);
    Test_Eq("F1c a sentence changed in place measures exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_True("F1c the taller sentence makes the details panel taller", _mc.det_h > _dh0);
    Test_MenuSame("F1c sentence in place", _mc, Test_MenuRef(_m, Ui_Metrics()));
    _b0 = Ui_MenuMeasureBuilds();
    repeat (8) array_push(_m.items[11].lines, { label: "More", value: "1" });   // number lines added in place
    _mc = Test_MenuFrames(_m, 50);
    Test_Eq("F1c number lines added in place measure exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_MenuSame("F1c lines in place", _mc, Test_MenuRef(_m, Ui_Metrics()));

    // ---- the details width or columns change: only the sizes are measured again ----
    _b0 = Ui_MenuMeasureBuilds();
    _d0 = Ui_MenuDetailsBuilds();
    _m.layout.panel_w = 200;
    _mc = Test_MenuFrames(_m, 50);
    Test_Eq("F1c a fixed panel width leaves the rows alone", Ui_MenuMeasureBuilds() - _b0, 0);
    Test_Eq("F1c a fixed panel width measures the details height exactly once", Ui_MenuDetailsBuilds() - _d0, 1);
    Test_MenuSame("F1c fixed panel width", _mc, Test_MenuRef(_m, Ui_Metrics()));
    _d0 = Ui_MenuDetailsBuilds();
    _m.layout.details_cols = 2;
    _mc = Test_MenuFrames(_m, 50);
    Test_Eq("F1c other details columns measure the details height exactly once", Ui_MenuDetailsBuilds() - _d0, 1);
    Test_MenuSame("F1c details columns", _mc, Test_MenuRef(_m, Ui_Metrics()));
    _m.layout.panel_w = 0;
    _m.layout.details_cols = 1;
    Test_MenuFrames(_m, 2);

    // ---- a panel above the list follows the highlighted row ----
    var _ma = Ui_MenuNew("f1c_above", Test_MenuRows(25, "C"), { layout: { title: "", details: true, details_pos: "above", panel_w: 300 } });
    _d0 = Ui_MenuDetailsBuilds();
    Test_MenuFrames(_ma, 100);
    Test_Eq("F1c an above panel measures the highlighted row once", Ui_MenuDetailsBuilds() - _d0, 1);
    _d0 = Ui_MenuDetailsBuilds();
    _ma.cursor = 9;
    _mc = Test_MenuFrames(_ma, 100);
    Test_Eq("F1c an above panel measures again once when the cursor moves", Ui_MenuDetailsBuilds() - _d0, 1);
    Test_Eq("F1c an above panel is as tall as the highlighted row needs", _mc.det_h, Ui_DetailsHeight(_mc.panel_w, _ma.items[9].help, _ma.items[9].lines, 1, 0));

    // ---- the language changes: measured again, once each way ----
    _b0 = Ui_MenuMeasureBuilds();
    Loc_SetLanguage("ko");
    _mc = Test_MenuFrames(_m, 300);
    Test_Eq("F1c en to ko measures the rows exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_MenuSame("F1c ko", _mc, Test_MenuRef(_m, Ui_Metrics()));
    _b0 = Ui_MenuMeasureBuilds();
    Loc_SetLanguage("en");
    _mc = Test_MenuFrames(_m, 300);
    Test_Eq("F1c ko to en measures the rows exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    Test_MenuSame("F1c back in en", _mc, Test_MenuRef(_m, Ui_Metrics()));

    // ---- a row that gains or loses a field, or changes its type, in place is seen (and comparing the kinds never throws) ----
    var _mx = Ui_MenuNew("f1c_mixed", Test_MenuRows(6, "M"), { layout: { title: "Mixed", details: true } });
    Test_MenuFrames(_mx, 3);
    _b0 = Ui_MenuMeasureBuilds();
    variable_struct_remove(_mx.items[2], "help");
    _mc = Test_MenuFrames(_mx, 5);
    Test_Eq("F1c a sentence removed in place measures exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    _b0 = Ui_MenuMeasureBuilds();
    _mx.items[2].help = "A sentence is back.";
    _mc = Test_MenuFrames(_mx, 5);
    Test_Eq("F1c a sentence added in place measures exactly once", Ui_MenuMeasureBuilds() - _b0, 1);
    _b0 = Ui_MenuMeasureBuilds();
    _mx.items[1].value = 75;
    _mx.items[1].kind = "slider";
    _mc = Test_MenuFrames(_mx, 5);
    Test_Eq("F1c a value that turns into a number measures exactly once", Ui_MenuMeasureBuilds() - _b0, 1);

    // ---- [PERF] 1000 frames of the measuring path of a 25-row details menu (no assertion: the time depends on the PC) ----
    var _mp = Ui_MenuNew("f1c_perf", Test_MenuRows(25, "P"), { layout: { title: "Shop", details: true } });
    var _t0 = get_timer();
    for (var _pf = 0; _pf < 1000; _pf++) Ui_MenuMeasure(_mp, Ui_Metrics());
    Test_Log("[PERF] 1000 x Ui_MenuMeasure (25-row details menu): " + string(get_timer() - _t0) + " us");

    // ---- the Tab menu: ids and icons are built once, the labels once per language ----
    var _ids = TabMenu_Ids();
    var _icons = TabMenu_Icons();
    TabMenu_Labels();
    var _tb0 = TabMenu_DataBuilds();
    var _tl0 = TabMenu_LabelBuilds();
    var _same = true;
    for (var _ti = 0; _ti < 300; _ti++) {
        var _ids_i = TabMenu_Ids();
        var _icons_i = TabMenu_Icons();
        var _lb_i = TabMenu_Labels();
        if (array_length(_ids_i) != 6 || array_length(_icons_i) != 6 || array_length(_lb_i) != 6) _same = false;
    }
    Test_Eq("F1c 300 TabMenu_Ids and TabMenu_Icons calls build nothing more", TabMenu_DataBuilds() - _tb0, 0);
    Test_Eq("F1c 300 TabMenu_Labels calls build nothing more", TabMenu_LabelBuilds() - _tl0, 0);
    Test_True("F1c the tab data keeps its shape", _same && _ids[5] == "settings" && array_length(_icons[0]) == 8 && string_length(_icons[5][7]) == 8);
    _tl0 = TabMenu_LabelBuilds();
    Loc_SetLanguage("ko");
    var _lb_ko = TabMenu_Labels();
    for (var _tj = 0; _tj < 300; _tj++) TabMenu_Labels();
    Test_Eq("F1c en to ko builds the tab labels exactly once", TabMenu_LabelBuilds() - _tl0, 1);
    Test_Eq("F1c the ko tab labels are the language's own", _lb_ko[2], Loc_T("tab.items", "Items"));
    _tl0 = TabMenu_LabelBuilds();
    Loc_SetLanguage("en");
    var _lb_en = TabMenu_Labels();
    for (var _tk = 0; _tk < 300; _tk++) TabMenu_Labels();
    Test_Eq("F1c ko to en builds the tab labels exactly once", TabMenu_LabelBuilds() - _tl0, 1);
    Test_Eq("F1c the en tab labels come back", _lb_en[0] + "," + _lb_en[5], "Status,Settings");

    // ---- the Status card's texts: once per (language, metrics) ----
    _mt = Ui_Metrics();
    var _cd = TabMenu_CardData(_mt);
    var _cb0 = TabMenu_CardBuilds();
    for (var _ci = 0; _ci < 300; _ci++) TabMenu_CardData(Ui_Metrics());
    Test_Eq("F1c 300 Status card data calls build nothing more", TabMenu_CardBuilds() - _cb0, 0);
    Test_Eq("F1c the Status card knows its labels", _cd.hp + _cd.mp + _cd.xp, Loc_T("battle.hud.hp", "HP") + Loc_T("battle.hud.mp", "MP") + Loc_T("tab.lbl.xp", "XP"));
    Test_Eq("F1c the Status card's label width is the widest label", _cd.lab_w, max(UI_TextWidth(_cd.hp), max(UI_TextWidth(_cd.mp), UI_TextWidth(_cd.xp))));
    Test_Eq("F1c the level text equals Loc_T's", string_replace_all(_cd.level_tpl, "{n}", "7"), Loc_T("battle.hud.level", "Lv {n}", { n: "7" }));
    Test_Eq("F1c the seed text equals Loc_T's", string_replace_all(_cd.seed_tpl, "{n}", "123"), Loc_T("tab.lbl.seed_small", "Seed {n}", { n: "123" }));
    _cb0 = TabMenu_CardBuilds();
    Loc_SetLanguage("ko");
    for (var _cj = 0; _cj < 300; _cj++) TabMenu_CardData(Ui_Metrics());
    Test_Eq("F1c en to ko builds the Status card data exactly once", TabMenu_CardBuilds() - _cb0, 1);
    Loc_SetLanguage("en");
    Ui_Metrics();

    // ---- input: one snapshot struct is reused and starts clean every frame ----
    var _s1 = Ui_ReadInput();
    _s1.click = true;
    _s1.wheel = 1;
    var _s2 = Ui_ReadInput();
    Test_True("F1c Ui_ReadInput reuses one snapshot struct", _s1 == _s2);
    Test_True("F1c a reused snapshot starts clean", !_s2.click && _s2.wheel == 0);

    draw_set_font(_f0);
    if (_own) global.display = _disp0;
    Loc_SetLanguage(_lang0);
}

function Test_Suite_UI() {
    // --- D108 F4a: the palette macros equal the literals they replaced (written out here, not read from the macros)
    Test_Eq("D108 UI_C_DARKEST = #071821", UI_C_DARKEST, make_color_rgb(7, 24, 33));
    Test_Eq("D108 UI_C_DARK = #306850", UI_C_DARK, make_color_rgb(48, 104, 80));
    Test_Eq("D108 UI_C_LIGHT = #86C06C", UI_C_LIGHT, make_color_rgb(134, 192, 108));
    Test_Eq("D108 UI_C_LIGHTEST = #E0F8CF", UI_C_LIGHTEST, make_color_rgb(224, 248, 207));
    Test_Eq("D108 QTE_COL_DARKEST was $211807", QTE_COL_DARKEST, $211807);
    Test_Eq("D108 QTE_COL_DARK was $506830", QTE_COL_DARK, $506830);
    Test_Eq("D108 QTE_COL_LIGHT was $6CC086", QTE_COL_LIGHT, $6CC086);
    Test_Eq("D108 QTE_COL_LIGHTEST was $CFF8E0", QTE_COL_LIGHTEST, $CFF8E0);
    Test_Eq("D108 Icon_PaletteColour 0 was $211807", Icon_PaletteColour("0"), $211807);
    Test_Eq("D108 Icon_PaletteColour 1 was $506830", Icon_PaletteColour("1"), $506830);
    Test_Eq("D108 Icon_PaletteColour 2 was $6CC086", Icon_PaletteColour("2"), $6CC086);
    Test_Eq("D108 Icon_PaletteColour 3 was $CFF8E0", Icon_PaletteColour("3"), $CFF8E0);
    var _navc = Nav_FxColors();
    Test_Eq("D108 Nav_FxColors c0", _navc.c0, make_color_rgb(7, 24, 33));
    Test_Eq("D108 Nav_FxColors c1", _navc.c1, make_color_rgb(48, 104, 80));
    Test_Eq("D108 Nav_FxColors c2", _navc.c2, make_color_rgb(134, 192, 108));
    Test_Eq("D108 Nav_FxColors c3", _navc.c3, make_color_rgb(224, 248, 207));
    Test_Eq("D113 UI_C_MERCHANT_GOLD was make_color_rgb(232, 197, 71)", UI_C_MERCHANT_GOLD, make_color_rgb(232, 197, 71));
    // --- list cursor with wrap-around
    var _all = [true, true, true, true];
    Test_Eq("D95 up from the first item wraps to the last", Ui_CursorMove(0, -1, _all), 3);
    Test_Eq("D95 down from the last item wraps to the first", Ui_CursorMove(3, 1, _all), 0);
    Test_Eq("D95 down moves one item", Ui_CursorMove(1, 1, _all), 2);
    Test_Eq("D95 up moves one item", Ui_CursorMove(2, -1, _all), 1);
    Test_Eq("D95 without wrap, up on the first stays", Ui_CursorMove(0, -1, _all, false), 0);
    Test_Eq("D95 without wrap, down on the last stays", Ui_CursorMove(3, 1, _all, false), 3);
    var _gap = [true, false, true, false];
    Test_Eq("D95 a disabled item is skipped going down", Ui_CursorMove(0, 1, _gap), 2);
    Test_Eq("D95 wrapping down past a disabled last item lands on the first", Ui_CursorMove(2, 1, _gap), 0);
    Test_Eq("D95 wrapping up from the first skips a disabled last item", Ui_CursorMove(0, -1, _gap), 2);
    Test_Eq("D95 without wrap, a disabled item at the end leaves the cursor", Ui_CursorMove(2, 1, _gap, false), 2);
    Test_Eq("D95 when nothing is enabled the cursor stays", Ui_CursorMove(1, 1, [false, false]), 1);
    Test_Eq("D95 an empty list gives index 0", Ui_CursorMove(0, 1, []), 0);

    // --- hold to scroll: fires on the press, then after 300 ms, then faster (time based, not frames)
    var _ft = Test_UiFireTimes(1, 2400);
    Test_Eq("D95 holding fires on the press", (array_length(_ft) > 0) ? _ft[0] : -1, 0);
    Test_True("D95 nothing repeats before 300 ms", array_length(_ft) > 1 && _ft[1] >= 300);
    Test_True("D95 the first repeat comes soon after 300 ms", array_length(_ft) > 1 && _ft[1] <= 320);
    Test_True("D95 hold repeats at least 8 times in 2.4 s", array_length(_ft) >= 9);
    Test_True("D95 hold does not flood (under 70 steps in 2.4 s)", array_length(_ft) < 70);
    if (array_length(_ft) >= 9) {
        var _first_gap = _ft[2] - _ft[1];
        var _late_gap = _ft[8] - _ft[7];
        Test_True("D95 the repeat accelerates (later gaps are shorter)", _late_gap < _first_gap);
        Test_True("D95 the repeat never goes below 20 ms per step", _late_gap >= 20);
    }
    var _rs = Ui_RepeatNew();
    Ui_RepeatStep(_rs, 1, true, 100);
    Test_Eq("D95 releasing stops repeating", Ui_RepeatStep(_rs, 0, false, 500), 0);
    Test_Eq("D95 a new press after a release fires at once", Ui_RepeatStep(_rs, 1, true, 520), 1);
    Test_Eq("D95 reversing direction fires at once", Ui_RepeatStep(_rs, -1, false, 530), 1);
    Test_Eq("D95 held with no new press and no time passed: no step", Ui_RepeatStep(_rs, -1, false, 540), 0);

    // --- remembered cursor per menu id
    var _mem = Ui_MemNew();
    Test_Eq("D95 an unknown menu starts at 0", Ui_MemGet(_mem, "title", 4), 0);
    Ui_MemSet(_mem, "title", 2);
    Ui_MemSet(_mem, "settings", 5);
    Test_Eq("D95 title cursor is remembered", Ui_MemGet(_mem, "title", 4), 2);
    Test_Eq("D95 settings cursor is remembered separately", Ui_MemGet(_mem, "settings", 10), 5);
    Test_Eq("D95 a remembered cursor is clamped when the menu got shorter", Ui_MemGet(_mem, "settings", 3), 2);

    // --- mouse hover mapping from rectangles
    var _rects = [{ x: 10, y: 10, w: 100, h: 20 }, { x: 10, y: 30, w: 100, h: 20 }, { x: 10, y: 50, w: 100, h: 20 }];
    Test_Eq("D95 hover inside the second row", Ui_HoverIndex(_rects, 50, 35), 1);
    Test_Eq("D95 hover outside every row", Ui_HoverIndex(_rects, 200, 35), -1);
    Test_Eq("D95 the top edge belongs to the row below", Ui_HoverIndex(_rects, 50, 30), 1);
    Test_Eq("D95 one pixel above that edge is the row above", Ui_HoverIndex(_rects, 50, 29), 0);
    Test_Eq("D95 the right edge is outside", Ui_HoverIndex(_rects, 110, 35), -1);
    Test_Eq("D95 a disabled row is not hovered", Ui_HoverIndex(_rects, 50, 35, [true, false, true]), -1);

    // --- scrolling window for lists longer than the panel
    Test_Eq("UI scroll: a list that fits never scrolls", Ui_ScrollTop(3, 0, 6, 5), 0);
    Test_Eq("UI scroll: the cursor below the window pulls it down", Ui_ScrollTop(5, 0, 4, 10), 2);
    Test_Eq("UI scroll: the cursor above the window pulls it up", Ui_ScrollTop(0, 2, 4, 10), 0);
    Test_Eq("UI scroll: the last item shows the last full window", Ui_ScrollTop(9, 0, 4, 10), 6);
    Test_Eq("UI scroll: a cursor inside the window leaves it alone", Ui_ScrollTop(4, 3, 4, 10), 3);

    // --- menu stack: Back always goes up ONE level
    var _items = [
        { id: "new", label: "New Game", kind: "button", enabled: true },
        { id: "load", label: "Load Game", kind: "button", enabled: true },
        { id: "settings", label: "Settings", kind: "button", enabled: true },
        { id: "exit", label: "Exit Game", kind: "button", enabled: true }
    ];
    var _stk = Ui_StackNew();
    Ui_StackPush(_stk, Ui_MenuNew("title", _items, {}));
    Ui_StackPush(_stk, Ui_MenuNew("difficulty", _items, {}));
    Test_Eq("D95 two menus deep", Ui_StackDepth(_stk), 2);
    Test_Eq("D95 the top menu is the last pushed", Ui_StackTop(_stk).id, "difficulty");
    Test_Eq("D95 back pops one level", Ui_StackBack(_stk), "pop");
    Test_Eq("D95 after back the parent is on top", Ui_StackTop(_stk).id, "title");
    Test_Eq("D95 after back one level remains", Ui_StackDepth(_stk), 1);
    Test_Eq("D95 back at the root pops nothing", Ui_StackBack(_stk), "root");
    Test_Eq("D95 the root stays", Ui_StackDepth(_stk), 1);

    // --- one menu step from a snapshot (what the bot drives through the real input)
    var _m = Ui_MenuNew("test_menu", _items, {});
    var _s = Ui_SnapNew();
    _s.up = true; _s.up_p = true;
    var _ev = Ui_MenuStep(_m, _s, 1000);
    Test_Eq("D95 up on the first item lands on the last", _m.cursor, 3);
    Test_True("D95 that move is reported (for the blip)", _ev.moved);
    Ui_MenuStep(_m, Ui_SnapNew(), 1016);   // released
    _s = Ui_SnapNew();
    _s.down = true; _s.down_p = true;
    Ui_MenuStep(_m, _s, 1032);
    Test_Eq("D95 down on the last item wraps to the first", _m.cursor, 0);
    Ui_MenuStep(_m, Ui_SnapNew(), 1048);
    _s = Ui_SnapNew();
    _s.confirm = true;
    _ev = Ui_MenuStep(_m, _s, 1064);
    Test_True("D95 confirm is reported", _ev.confirm);
    Test_Eq("D95 confirm names the item under the cursor", _ev.index, 0);
    _s = Ui_SnapNew();
    _s.back = true;
    _ev = Ui_MenuStep(_m, _s, 1080);
    Test_True("D95 back is reported", _ev.back);
    Test_False("D95 back is not a confirm", _ev.confirm);
    _items[1].enabled = false;
    var _m2 = Ui_MenuNew("test_menu2", _items, {});
    _m2.cursor = 0;
    _s = Ui_SnapNew();
    _s.down = true; _s.down_p = true;
    Ui_MenuStep(_m2, _s, 2000);
    Test_Eq("D95 a disabled item is skipped by the cursor", _m2.cursor, 2);
    _m2.cursor = 1;
    _s = Ui_SnapNew();
    _s.confirm = true;
    _ev = Ui_MenuStep(_m2, _s, 2016);
    Test_False("D95 confirm on a disabled item does nothing", _ev.confirm);
    _items[1].enabled = true;

    // --- mouse: hover moves the cursor, click = confirm, right-click = back, wheel scrolls
    var _mm = Ui_MenuNew("mouse_menu", _items, {});
    _mm.rects = [{ x: 0, y: 0, w: 100, h: 20 }, { x: 0, y: 20, w: 100, h: 20 }, { x: 0, y: 40, w: 100, h: 20 }, { x: 0, y: 60, w: 100, h: 20 }];
    _s = Ui_SnapNew();
    _s.mouse_moved = true; _s.mx = 50; _s.my = 45;
    _ev = Ui_MenuStep(_mm, _s, 3000);
    Test_Eq("D95 hover moves the cursor to the row under the mouse", _mm.cursor, 2);
    Test_True("D95 hover reports a move", _ev.moved);
    Test_False("D95 hover alone does not confirm", _ev.confirm);
    _s = Ui_SnapNew();
    _s.mx = 50; _s.my = 65; _s.click = true;
    _ev = Ui_MenuStep(_mm, _s, 3016);
    Test_True("D95 left click on a row confirms", _ev.confirm);
    Test_Eq("D95 the click selects the clicked row", _ev.index, 3);
    _s = Ui_SnapNew();
    _s.mx = 500; _s.my = 500; _s.click = true;
    _ev = Ui_MenuStep(_mm, _s, 3032);
    Test_False("D95 a click on empty space does nothing", _ev.confirm);
    _s = Ui_SnapNew();
    _s.rclick = true;
    _ev = Ui_MenuStep(_mm, _s, 3048);
    Test_True("D95 right click is back", _ev.back);
    _mm.cursor = 1;
    _s = Ui_SnapNew();
    _s.wheel = -1;   // wheel down
    Ui_MenuStep(_mm, _s, 3064);
    Test_Eq("D95 wheel down moves to the next row", _mm.cursor, 2);
    _s = Ui_SnapNew();
    _s.wheel = 1;
    Ui_MenuStep(_mm, _s, 3080);
    Ui_MenuStep(_mm, _s, 3096);
    Ui_MenuStep(_mm, _s, 3112);
    Test_Eq("D95 wheel up stops at the first row (no wrap)", _mm.cursor, 0);

    // --- left/right adjust (sliders, choices) hold-repeats like the vertical move
    var _ma = Ui_MenuNew("adjust_menu", _items, {});
    _s = Ui_SnapNew();
    _s.right = true; _s.right_p = true;
    _ev = Ui_MenuStep(_ma, _s, 4000);
    Test_Eq("D95 right reports an adjust of +1", _ev.adjust, 1);
    _s = Ui_SnapNew();
    _s.right = true;
    _ev = Ui_MenuStep(_ma, _s, 4100);
    Test_Eq("D95 holding right does not adjust before 300 ms", _ev.adjust, 0);
    _ev = Ui_MenuStep(_ma, _s, 4310);
    Test_Eq("D95 holding right adjusts again after 300 ms", _ev.adjust, 1);
    _s = Ui_SnapNew();
    _s.left = true; _s.left_p = true;
    _ev = Ui_MenuStep(_ma, _s, 4400);
    Test_Eq("D95 left reports an adjust of -1", _ev.adjust, -1);

    // --- D95 bindings: every menu action has its keys and pad buttons
    Input_Init();
    var _bd = global.input.bindings;
    Test_True("D95 confirm: Space", array_contains(_bd.confirm, vk_space));
    Test_True("D95 confirm: Z", array_contains(_bd.confirm, ord("Z")));
    Test_True("D95 confirm: Enter", array_contains(_bd.confirm, vk_enter));
    Test_True("D95 confirm: pad A", array_contains(Input_GamepadButtons("confirm"), gp_face1));
    Test_True("D95 back: Esc", array_contains(_bd.cancel, vk_escape));
    Test_True("D95 back: X", array_contains(_bd.cancel, ord("X")));
    Test_True("D95 back: pad B", array_contains(Input_GamepadButtons("cancel"), gp_face2));
    Test_True("D95 tab_prev: Q", array_contains(_bd.tab_prev, ord("Q")));
    Test_True("D95 tab_next: E", array_contains(_bd.tab_next, ord("E")));
    Test_True("D95 tab_prev: pad left shoulder", array_contains(Input_GamepadButtons("tab_prev"), gp_shoulderl));
    Test_True("D95 tab_next: pad right shoulder", array_contains(Input_GamepadButtons("tab_next"), gp_shoulderr));
    Test_True("D95 run stays on Shift", array_contains(_bd.run, vk_shift));
    Test_False("D95 run no longer uses the shoulder buttons", array_contains(Input_GamepadButtons("run"), gp_shoulderl) || array_contains(Input_GamepadButtons("run"), gp_shoulderr));
    Test_True("D95 run is on the pad triggers", array_contains(Input_GamepadButtons("run"), gp_shoulderlb) && array_contains(Input_GamepadButtons("run"), gp_shoulderrb));
    Test_True("D95 interact stays on Space", array_contains(_bd.interact, vk_space));

    // --- the same keys everywhere: confirm / back / arrows come from the game's input actions
    Input_Init();
    var _inp = global.input;
    _inp.frozen = true;   // freeze Input_Update for this check (a same-millisecond check raced the clock)
    variable_struct_set(_inp.state, "confirm", { held: true, pressed: true });
    variable_struct_set(_inp.state, "cancel", { held: true, pressed: true });
    variable_struct_set(_inp.state, "menu_up", { held: true, pressed: true });
    variable_struct_set(_inp.state, "menu_right", { held: true, pressed: false });
    var _sn = Ui_ReadInput();
    Test_True("D95 snapshot: confirm comes from the confirm action", _sn.confirm);
    Test_True("D95 snapshot: back comes from the cancel action", _sn.back);
    Test_True("D95 snapshot: up held", _sn.up);
    Test_True("D95 snapshot: up pressed", _sn.up_p);
    Test_True("D95 snapshot: right held", _sn.right);
    Test_False("D95 snapshot: right not freshly pressed", _sn.right_p);
    Test_False("D95 snapshot: down not held", _sn.down);
    variable_struct_set(_inp.state, "confirm", { held: false, pressed: false });
    variable_struct_set(_inp.state, "cancel", { held: false, pressed: false });
    variable_struct_set(_inp.state, "menu_up", { held: false, pressed: false });
    variable_struct_set(_inp.state, "menu_right", { held: false, pressed: false });
    _inp.frozen = false;

    // --- motion helpers (D97): 120 ms panels, gliding cursor, gentle bob
    Test_Eq("D97 panel animation starts at 0", Ui_AnimT(1000, 1000), 0);
    Test_Eq("D97 panel animation is done after 120 ms", Ui_AnimT(1000, 1120), 1);
    Test_Eq("D97 panel animation is 0 before its start", Ui_AnimT(1000, 900), 0);
    Test_Eq("D97 panel animation stays at 1", Ui_AnimT(1000, 5000), 1);
    var _mid = Ui_AnimT(1000, 1060);
    Test_True("D97 halfway through it is strictly between 0 and 1", _mid > 0 && _mid < 1);
    var _g1 = Ui_Glide(0, 100, 16);
    Test_True("D97 the cursor glides toward its target without jumping", _g1 > 0 && _g1 < 100);
    Test_True("D97 the cursor keeps gliding (monotonic)", Ui_Glide(_g1, 100, 16) > _g1);
    Test_Eq("D97 the cursor arrives after a long time", Ui_Glide(0, 100, 2000), 100);
    Test_Eq("D97 the cursor glides down too", Ui_Glide(100, 0, 2000), 0);
    Test_Eq("D97 at its target it stays", Ui_Glide(40, 40, 16), 40);
    var _lo = 99, _hi = -99;
    for (var _bt = 0; _bt < 2000; _bt += 20) {
        var _bv = Ui_Bob(_bt);
        _lo = min(_lo, _bv);
        _hi = max(_hi, _bv);
    }
    Test_Eq("D97 the bob never goes below 0", _lo, 0);
    Test_Eq("D97 the bob is one UI pixel at most", _hi, 1);

    // --- tabs header
    Test_Eq("UI tabs: previous from the first wraps to the last", Ui_TabStep(0, 3, -1), 2);
    Test_Eq("UI tabs: next from the last wraps to the first", Ui_TabStep(2, 3, 1), 0);
    Test_Eq("UI tabs: no direction keeps the tab", Ui_TabStep(1, 3, 0), 1);

    // --- Korean pixel font (D98): Galmuri's native sizes are 9 and 11 px, only whole multiples stay crisp
    Test_Eq("D98 18 px target: Galmuri9 x2", Ui_KoFontChoice(18).px, 18);
    Test_Eq("D98 22 px target: Galmuri11 x2", Ui_KoFontChoice(22).px, 22);
    Test_Eq("D98 27 px target: Galmuri9 x3", Ui_KoFontChoice(27).px, 27);
    Test_Eq("D98 33 px target: Galmuri11 x3", Ui_KoFontChoice(33).px, 33);
    var _kc = Ui_KoFontChoice(25);
    Test_True("D98 any target gives a whole multiple of a native size", (_kc.px mod _kc.face) == 0 && (_kc.face == 9 || _kc.face == 11));
    Test_True("D98 any target lands within 3 px of it", abs(_kc.px - 25) <= 3);
    Test_True("D98 tiny targets never go below 1x", Ui_KoFontChoice(3).px >= 9);

    // --- settings model (the new rows persist; the window rows keep D91's logic)
    var _def = GameSettings_Defaults();
    Test_Eq("D0 text speed defaults to normal", _def.text_speed, 1);
    Test_Eq("D0 screen shake defaults to on", _def.screen_shake, 1);
    Test_Eq("D0 QTE assist defaults to off", _def.qte_assist, 0);
    Test_Eq("D0 text speed is clamped high", GameSettings_Normalize({ text_speed: 9 }).text_speed, SETTINGS_TEXT_SPEED_MAX);
    Test_Eq("D0 text speed is clamped low", GameSettings_Normalize({ text_speed: -3 }).text_speed, 0);
    Test_Eq("D0 screen shake is a 0/1 flag", GameSettings_Normalize({ screen_shake: 5 }).screen_shake, 1);
    Test_Eq("D0 QTE assist reads a boolean", GameSettings_Normalize({ qte_assist: true }).qte_assist, 1);
    Test_True("D0 slower text speed is a smaller multiplier", Settings_TextSpeedMul(0) < Settings_TextSpeedMul(1) && Settings_TextSpeedMul(1) < Settings_TextSpeedMul(2));
    Test_Eq("D0 normal text speed leaves the typewriter as it was", Settings_TextSpeedMul(1), 1);
    var _sf = "test_settings_ui.json";
    Save_DeleteFileSet(_sf);
    Save_WriteSettingsConfig({ text_speed: 2, screen_shake: 0, qte_assist: 1 }, _sf);
    var _sb = Save_ReadSettingsConfig(_sf);
    Test_Eq("D0 text speed survives a save", is_struct(_sb) ? _sb.text_speed : -1, 2);
    Test_Eq("D0 screen shake off survives a save", is_struct(_sb) ? _sb.screen_shake : -1, 0);
    Test_Eq("D0 QTE assist on survives a save", is_struct(_sb) ? _sb.qte_assist : -1, 1);
    Save_DeleteFileSet(_sf);
    Test_RawWrite(_sf, "{\"settings_version\":8,\"display_scale\":4,\"window_mode\":0}");
    var _s8 = Save_ReadSettingsConfig(_sf);
    Test_Eq("D0 a version 8 file gets the default text speed", is_struct(_s8) ? _s8.text_speed : -1, 1);
    Test_Eq("D0 a version 8 file gets screen shake on", is_struct(_s8) ? _s8.screen_shake : -1, 1);
    Save_DeleteFileSet(_sf);

    var _p = GameSettings_Defaults();
    _p.audio_ui = 0.5;
    Test_True("D0 volume + steps up", Settings_Adjust(_p, "vol_ui", 1, 16));
    Test_True("D0 volume steps by 5 points", abs(_p.audio_ui - 0.55) < 0.0001);
    _p.audio_ui = 1;
    Test_False("D0 volume stops at 100", Settings_Adjust(_p, "vol_ui", 1, 16));
    _p.window_mode = WINDOW_MODE_WINDOWED;
    Settings_Adjust(_p, "window", -1, 16);
    Test_Eq("D91 window mode wraps backwards to the last", _p.window_mode, WINDOW_MODE_EXCLUSIVE);
    Settings_Adjust(_p, "window", 1, 16);
    Test_Eq("D91 window mode wraps forwards to the first", _p.window_mode, WINDOW_MODE_WINDOWED);
    _p.display_scale = 3;
    Test_True("D91 windowed scale + goes up one", Settings_Adjust(_p, "scale", 1, 6));
    Test_Eq("D91 scale is now 4", _p.display_scale, 4);
    _p.display_scale = 6;
    Test_False("D91 scale stops at the monitor's largest", Settings_Adjust(_p, "scale", 1, 6));
    _p.window_mode = WINDOW_MODE_BORDERLESS;
    _p.display_scale = 4;
    Test_False("D91 scale does nothing outside windowed", Settings_Adjust(_p, "scale", 1, 6));
    Test_Eq("D91 scale is untouched outside windowed", _p.display_scale, 4);
    _p.language = "en";
    Settings_Adjust(_p, "language", 1, 16);
    Test_Eq("D0 language toggles to Korean", _p.language, "ko");
    Settings_Adjust(_p, "language", 1, 16);
    Test_Eq("D0 language toggles back", _p.language, "en");
    _p.text_speed = 1;
    Test_True("D0 text speed + goes faster", Settings_Adjust(_p, "text_speed", 1, 16));
    Test_Eq("D0 text speed is now fast", _p.text_speed, 2);
    Test_False("D0 text speed stops at the fastest", Settings_Adjust(_p, "text_speed", 1, 16));
    Test_True("D0 screen shake toggles", Settings_Adjust(_p, "shake", 1, 16));
    Test_Eq("D0 screen shake is now off", _p.screen_shake, 0);
    Test_True("D0 QTE assist toggles", Settings_Adjust(_p, "qte_assist", -1, 16));
    Test_Eq("D0 QTE assist is now on", _p.qte_assist, 1);

    var _si = SettingsMenu_Items(GameSettings_Defaults(), 16);
    var _ids = "";
    for (var _i = 0; _i < array_length(_si); _i++) _ids += ((_i > 0) ? "," : "") + _si[_i].id;
    Test_Eq("D0 settings rows, in order", _ids, "vol_ui,vol_sfx,vol_bgm,text_speed,shake,qte_assist,window,scale,language,controls,apply");   // C4 adds Controls (D49)
    Test_Eq("D0 settings volume row shows a percentage", _si[2].value, "60%");
    Test_Eq("D0 settings volume row carries its slider fill", _si[2].amount, 0.6);
    Test_False("D0 scale row is greyed outside windowed (borderless is the default)", _si[7].enabled);
    var _pw = GameSettings_Defaults();
    _pw.window_mode = WINDOW_MODE_WINDOWED;
    Test_True("D0 scale row is live while windowed", SettingsMenu_Items(_pw, 16)[7].enabled);
    Test_True("D100 every settings row has a plain help sentence", string_length(_si[0].help) > 0 && string_length(_si[6].help) > 0 && string_length(_si[9].help) > 0);
    var _tm = Title_MainItems(false);
    Test_Eq("D0 title menu has four items", array_length(_tm), 4);
    Test_False("D0 Load Game is greyed with no save", _tm[1].enabled);
    Test_True("D0 Load Game is live with a save", Title_MainItems(true)[1].enabled);
}

// ---- C2: cards (D18, D34, D73, D76, D81-D83, D88, D100) ----------------------------------------------------------------------
// Expected values are the packet's card table (each upgrade's numbers below), D82 (5 skills + 1 upgrade each, 6-8 shared passives, 2-3
// class passives, max 3 skills), D81 (1 of 3, skip for gold), D73 (first class or skill chest = class choice), D83 (Nobody locked until the
// first win) and the offer rules of roguelike-cases.md 2.2 (3 distinct cards, quota, pity, decline memory, same seed = same offers).
function Test_CardPlayer(_class, _skills = [], _upgrades = [], _passives = []) {
    var _ch = CharacterCreate_Player(_class);
    _ch.skills = _skills;
    _ch.upgrades = _upgrades;
    _ch.passives = _passives;
    return _ch;
}

function Test_CardKinds(_ids) {
    var _out = { skill: 0, upgrade: 0, passive: 0, fallback: 0 };
    for (var _i = 0; _i < array_length(_ids); _i++) {
        var _k = CardDB_Get(_ids[_i]).kind;
        variable_struct_set(_out, _k, variable_struct_get(_out, _k) + 1);
    }
    return _out;
}

function Test_CardDistinct(_ids) {
    for (var _i = 0; _i < array_length(_ids); _i++) {
        for (var _j = _i + 1; _j < array_length(_ids); _j++) if (_ids[_i] == _ids[_j]) return false;
    }
    return true;
}

function Test_CardLineValue(_card, _label) {
    var _lines = Card_Lines(_card);
    for (var _i = 0; _i < array_length(_lines); _i++) if (_lines[_i].label == _label) return _lines[_i].value;
    return "";
}

// One run's worth of offers for a build that takes the first card each time (replacing the first skill past 3); a signature string.
function Test_CardRun(_class, _seed, _count) {
    var _ch = Test_CardPlayer(_class);
    var _rng = Rng_New(_seed, "cards");
    var _st = Card_StateNew();
    var _sig = "";
    for (var _i = 0; _i < _count; _i++) {
        var _off = Card_OfferGenerate(_rng, _ch, _st);
        _st = _off.state;
        _sig += _off.cards[0] + "," + _off.cards[1] + "," + _off.cards[2] + "|";
        var _tk = Card_Take(_ch, _off.cards[0]);
        if (_tk.needs_replace) _ch = Card_ReplaceSkill(_ch, _ch.skills[0], CardDB_Get(_off.cards[0]).skill_id);
        else _ch = _tk.ch;
    }
    return _sig;
}

function Test_Suite_Cards() {
    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);
    var _had_run = variable_struct_exists(_gs, "run");
    var _old_run = _had_run ? _gs.run : undefined;
    var _old_player = _gs.player_ch;
    ItemDB_Init(); SkillDB_Init(); StatusDB_Init(); EnemyDB_Init();
    CardDB_Init();

    // ---- the card pool (D82): per class 5 skills, each with 1 upgrade; 7 shared passives; 3 class passives each ----
    var _classes = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];
    var _want_skills = [
        [SKILL_WOUND, SKILL_HILT_BASH, SKILL_MUSCLE_UP, SKILL_REV_UP, SKILL_HORIZ_SLASH],
        [SKILL_WOUND, SKILL_POISON_ARROW, SKILL_EVASION, SKILL_DOUBLE_SHOT, SKILL_TAKE_AIM],
        [SKILL_FIREBALL, SKILL_POISON_MIST, SKILL_ICE_SPEAR, SKILL_MEDITATION, SKILL_FORESIGHT]
    ];
    for (var _c = 0; _c < 3; _c++) {
        var _pool = Card_Pool(_classes[_c]);
        var _sk = 0; var _up = 0; var _pa = 0; var _shared = 0; var _own = 0; var _skill_ok = true; var _up_ok = true;
        for (var _i = 0; _i < array_length(_pool); _i++) {
            var _cd = _pool[_i];
            if (_cd.kind == "skill") {
                _sk++;
                var _in = false;
                for (var _w = 0; _w < 5; _w++) if (_want_skills[_c][_w] == _cd.skill_id) _in = true;
                if (!_in) _skill_ok = false;
            }
            if (_cd.kind == "upgrade") {
                _up++;
                var _has_base = false;
                for (var _j = 0; _j < array_length(_pool); _j++) if (_pool[_j].kind == "skill" && _pool[_j].skill_id == _cd.skill_id) _has_base = true;
                if (!_has_base) _up_ok = false;
            }
            if (_cd.kind == "passive") {
                _pa++;
                if (array_length(_cd.classes) == 0) _shared++; else _own++;
            }
        }
        var _cn = "C2 class " + string(_classes[_c]);
        Test_Eq(_cn + " pool: 5 skill cards", _sk, 5);
        Test_Eq(_cn + " pool: 5 upgrade cards (one per skill)", _up, 5);
        Test_True(_cn + " pool: exactly the class skills", _skill_ok);
        Test_True(_cn + " pool: every upgrade belongs to a skill of the pool", _up_ok);
        Test_Eq(_cn + " pool: 8 shared passives", _shared, 8);
        Test_Eq(_cn + " pool: 3 class passives", _own, 3);
        Test_Eq(_cn + " pool: no fallback cards inside the pool", Test_CardKinds(Card_PoolIds(_classes[_c])).fallback, 0);
    }
    var _nk = Test_CardKinds(Card_PoolIds(CLASS_NOBODY));
    Test_Eq("C2 Nobody pool: no skills (D83)", _nk.skill, 0);
    Test_Eq("C2 Nobody pool: no upgrades (D83)", _nk.upgrade, 0);
    Test_Eq("C2 Nobody pool: 8 shared + 3 item passives", _nk.passive, 11);
    Test_True("C2 card ids are unique over the whole database", Test_CardDistinct(Card_AllIds()));
    Test_Eq("C2 three fallback cards exist so an offer can always be filled", array_length(Card_FallbackIds()), 3);

    // ---- upgrades, concretely (numbers are data; the text is generated from them, D100) ----
    var _ice = SkillDB_Get(SKILL_ICE_SPEAR);
    var _iceu = Skill_WithUpgrade(_ice, CardDB_Get(Card_UpgradeId(SKILL_ICE_SPEAR)));
    Test_Eq("C2 Ice Spear+ power 5 -> 7", _iceu.power, 7);
    Test_Eq("C2 Ice Spear base power stays 5 (the upgrade works on a copy)", _ice.power, 5);
    Test_Eq("C2 Ice Spear+ is named with a plus", _iceu.name, _ice.name + "+");
    Test_Eq("C2 Ice Spear arrows 5", array_length(Qte_SkillSequence(SKILL_ICE_SPEAR)), 5);
    Test_Eq("C2 Ice Spear+ needs 1 arrow less", Card_UpgradedSequenceLength(SKILL_ICE_SPEAR, [SKILL_ICE_SPEAR]), 4);
    Test_Eq("C2 an upgrade of another skill leaves the arrows alone", Card_UpgradedSequenceLength(SKILL_ICE_SPEAR, [SKILL_FIREBALL]), 5);
    var _wu = Skill_WithUpgrade(SkillDB_Get(SKILL_WOUND), CardDB_Get(Card_UpgradeId(SKILL_WOUND)));
    Test_True("C2 Wound+ power 4 -> 6 and bleed chance 75% -> 100%", _wu.power == 6 && _wu.status_chance == 1);
    var _hu = Skill_WithUpgrade(SkillDB_Get(SKILL_HILT_BASH), CardDB_Get(Card_UpgradeId(SKILL_HILT_BASH)));
    Test_True("C2 Hilt Bash+ power 4 -> 5 and stun chance 60% -> 85%", _hu.power == 5 && abs(_hu.status_chance - 0.85) < 0.0001);
    var _mu = Skill_WithUpgrade(SkillDB_Get(SKILL_MUSCLE_UP), CardDB_Get(Card_UpgradeId(SKILL_MUSCLE_UP)));
    Test_True("C2 Muscle Up+ costs 2 MP and guards 8 turns", _mu.mp_cost == 2 && _mu.status_turns == 8);
    var _pu = Skill_WithUpgrade(SkillDB_Get(SKILL_POISON_ARROW), CardDB_Get(Card_UpgradeId(SKILL_POISON_ARROW)));
    Test_True("C2 Poison Arrow+ gives 4 stacks at 100%", _pu.status_stacks == 4 && _pu.status_chance == 1);
    var _fu = Skill_WithUpgrade(SkillDB_Get(SKILL_FORESIGHT), CardDB_Get(Card_UpgradeId(SKILL_FORESIGHT)));
    Test_Eq("C2 Foresight+ lasts 5 turns", _fu.status_turns, 5);
    var _ups_ok = true; var _ups_n = 0;
    for (var _c2 = 0; _c2 < 3; _c2++) {
        var _pl = Card_Pool(_classes[_c2]);
        for (var _k = 0; _k < array_length(_pl); _k++) {
            if (_pl[_k].kind != "upgrade") continue;
            _ups_n++;
            var _base = SkillDB_Get(_pl[_k].skill_id);
            var _upg = Skill_WithUpgrade(_base, _pl[_k]);
            var _bs = variable_struct_exists(_base, "status_stacks") ? _base.status_stacks : 0;
            var _us = variable_struct_exists(_upg, "status_stacks") ? _upg.status_stacks : 0;
            var _changed = (_upg.power != _base.power) || (_upg.mp_cost != _base.mp_cost) || (_upg.status_chance != _base.status_chance) || (_upg.status_turns != _base.status_turns)
                        || (_us != _bs) || (variable_struct_exists(_pl[_k].up, "seq_trim") && _pl[_k].up.seq_trim > 0);
            if (!_changed || _upg.name != _base.name + "+") _ups_ok = false;
            if (array_length(Card_Lines(_pl[_k])) <= 0) _ups_ok = false;
        }
    }
    Test_Eq("C2 15 upgrade cards over the three classes", _ups_n, 15);
    Test_True("C2 every upgrade changes at least one number, is named with + and has number lines", _ups_ok);
    Test_Eq("C2 Ice Spear+ text shows power 5 > 7 (from the data)", Test_CardLineValue(CardDB_Get(Card_UpgradeId(SKILL_ICE_SPEAR)), Loc_T("card.lbl.power", "Power")), "5 > 7");
    Test_Eq("C2 Ice Spear+ text shows arrows 5 > 4", Test_CardLineValue(CardDB_Get(Card_UpgradeId(SKILL_ICE_SPEAR)), Loc_T("card.lbl.arrows", "Arrows")), "5 > 4");
    // the upgrade follows the equipped player: SkillDB_Get and Qte_SkillSequence read the player's upgrades
    _gs.player_ch = Test_CardPlayer(CLASS_MAGE, [SKILL_ICE_SPEAR], [SKILL_ICE_SPEAR]);
    Test_Eq("C2 SkillDB_Get gives the upgraded power to a player who took Ice Spear+", SkillDB_Get(SKILL_ICE_SPEAR).power, 7);
    Test_Eq("C2 Qte_SkillSequence gives 4 arrows to that player", array_length(Qte_SkillSequence(SKILL_ICE_SPEAR)), 4);
    Test_Eq("C2 the other skills stay as they were", SkillDB_Get(SKILL_FIREBALL).power, 6);
    _gs.player_ch = Test_CardPlayer(CLASS_MAGE, [SKILL_ICE_SPEAR]);
    Test_Eq("C2 without the upgrade the skill is the base one", SkillDB_Get(SKILL_ICE_SPEAR).power, 5);

    // ---- text from data (D100): a plain line with the numbers in it, and number lines ----
    var _all_text = true;
    var _ids = Card_AllIds();
    for (var _t = 0; _t < array_length(_ids); _t++) {
        var _cdt = CardDB_Get(_ids[_t]);
        if (string_length(Card_Name(_cdt)) < 2 || string_length(Card_Sentence(_cdt)) < 8 || string_length(Card_TypeTag(_cdt)) < 2) _all_text = false;
        if (string_pos("{", Card_Sentence(_cdt)) > 0) _all_text = false;   // every placeholder was filled
    }
    Test_True("C2 every card has a name, a type tag and a sentence with no open placeholder", _all_text);
    Test_True("C2 Field Medic's sentence carries its number (3 HP) from the data", string_pos("3", Card_Sentence(CardDB_Get("pas:field_medic"))) > 0);
    Test_Eq("C2 a skill card shows its arrow sequence (Ice Spear = 5 arrows)", array_length(Card_Sequence(CardDB_Get(Card_SkillId(SKILL_ICE_SPEAR)))), 5);
    Test_Eq("C2 an upgrade card shows the upgraded sequence (4 arrows)", array_length(Card_Sequence(CardDB_Get(Card_UpgradeId(SKILL_ICE_SPEAR)))), 4);
    Test_Eq("C2 a passive card has no sequence", array_length(Card_Sequence(CardDB_Get("pas:field_medic"))), 0);

    // ---- the offer (roguelike-cases.md 2.2): 3 distinct, eligible, quota, pity, decline memory, deterministic ----
    var _mage0 = Test_CardPlayer(CLASS_MAGE);
    var _st = Card_StateNew();
    var _o1 = Card_OfferGenerate(Rng_New(777, "cards"), _mage0, _st);
    Test_Eq("C2 an offer has 3 cards", array_length(_o1.cards), 3);
    Test_True("C2 an offer has 3 distinct cards", Test_CardDistinct(_o1.cards));
    Test_True("C2 a mage with no skills sees at least one new skill (quota)", Test_CardKinds(_o1.cards).skill >= 1);
    Test_Eq("C2 no upgrade is offered for a skill the player does not own", Test_CardKinds(_o1.cards).upgrade, 0);
    // same seed -> same offers over a whole run of picks; another seed -> other offers
    var _sigA = Test_CardRun(CLASS_MAGE, 4242, 12);
    var _sigB = Test_CardRun(CLASS_MAGE, 4242, 12);
    var _sigC = Test_CardRun(CLASS_MAGE, 4243, 12);
    Test_True("C2 the run signature is not empty", string_length(_sigA) > 40);
    Test_Eq("C2 the same seed gives the same offers (D33)", _sigA, _sigB);
    Test_True("C2 another seed gives other offers", _sigA != _sigC);
    random_set_seed(5);
    repeat (40) random(1);
    Test_Eq("C2 global random() calls do not change the offers", Test_CardRun(CLASS_MAGE, 4242, 12), _sigA);
    // the offers come from the cards stream of the run
    _gs.run = Run_Create(31337);
    var _viaRun = Card_OfferFromRun(_mage0);
    var _copy = Run_Create(31337);
    var _viaDirect = Card_OfferGenerate(_copy.rng.cards, _mage0, Card_StateNew());
    Test_True("C2 Card_OfferFromRun uses the run's cards stream", _viaRun.cards[0] == _viaDirect.cards[0] && _viaRun.cards[1] == _viaDirect.cards[1] && _viaRun.cards[2] == _viaDirect.cards[2]);
    Test_True("C2 drawing an offer advances only the cards stream", _gs.run.rng.cards.calls > 0 && _gs.run.rng.loot.calls == 0 && _gs.run.rng.map.calls == 0);

    // invariants over many offers and builds (what the owner cannot see by playing): eligible, distinct, never three dead options
    var _bad_elig = 0; var _bad_dup = 0; var _bad_size = 0; var _dead3 = 0; var _n_offers = 0;
    var _rng = Rng_New(9, "cards");
    var _builds = [
        [CLASS_KNIGHT, []], [CLASS_KNIGHT, [SKILL_WOUND]], [CLASS_KNIGHT, [SKILL_WOUND, SKILL_HILT_BASH, SKILL_REV_UP]],
        [CLASS_ARCHER, [SKILL_POISON_ARROW, SKILL_EVASION, SKILL_TAKE_AIM]], [CLASS_MAGE, [SKILL_FIREBALL, SKILL_ICE_SPEAR, SKILL_FORESIGHT]],
        [CLASS_MAGE, [SKILL_MEDITATION]], [CLASS_NOBODY, []]
    ];
    for (var _b = 0; _b < array_length(_builds); _b++) {
        var _chb = Test_CardPlayer(_builds[_b][0], _builds[_b][1]);
        var _stb = Card_StateNew();
        for (var _n = 0; _n < 14; _n++) {
            var _off = Card_OfferGenerate(_rng, _chb, _stb);
            _stb = _off.state;
            _n_offers++;
            if (array_length(_off.cards) != 3) _bad_size++;
            if (!Test_CardDistinct(_off.cards)) _bad_dup++;
            var _live = 0;
            for (var _x = 0; _x < array_length(_off.cards); _x++) {
                var _cdx = CardDB_Get(_off.cards[_x]);
                if (!Card_Eligible(_chb, _cdx)) _bad_elig++;
                if (!(_cdx.kind == "skill" && array_length(_chb.skills) >= 3)) _live++;
            }
            if (_live == 0) _dead3++;
            // take the first card the way the player would, so the build grows through the whole run
            var _tk = Card_Take(_chb, _off.cards[0]);
            if (_tk.needs_replace) _chb = Card_ReplaceSkill(_chb, _chb.skills[0], CardDB_Get(_off.cards[0]).skill_id);
            else _chb = _tk.ch;
        }
    }
    Test_Eq("C2 all " + string(_n_offers) + " generated offers have 3 cards", _bad_size, 0);
    Test_Eq("C2 no offer shows a card twice", _bad_dup, 0);
    Test_Eq("C2 every offered card is eligible (owned skills, unowned passives, upgrades of owned skills)", _bad_elig, 0);
    Test_Eq("C2 no offer is three cards that all need a swap", _dead3, 0);

    // 3 skills equipped: at most one new-skill card per offer, and an upgrade shows up when one exists (the max-3 rule, D82)
    var _full = Test_CardPlayer(CLASS_KNIGHT, [SKILL_WOUND, SKILL_HILT_BASH, SKILL_REV_UP]);
    var _most_skills = 0; var _with_up = 0; var _rn = Rng_New(3, "cards"); var _sf = Card_StateNew();
    for (var _m = 0; _m < 40; _m++) {
        var _of = Card_OfferGenerate(_rn, _full, _sf);
        _sf = _of.state;
        var _kk = Test_CardKinds(_of.cards);
        _most_skills = max(_most_skills, _kk.skill);
        if (_kk.upgrade > 0) _with_up++;
    }
    Test_True("C2 with 3 skills equipped an offer holds at most 1 new-skill card", _most_skills <= 1);
    Test_True("C2 with 3 skills equipped upgrades keep showing up (more than a third of offers)", _with_up >= 14);

    // pity (roguelike-cases.md 2.2 step 5): after 2 offers without an upgrade the next one has one
    var _pity = Card_StateNew();
    _pity.pity = CARD_PITY_OFFERS;
    var _poff = Card_OfferGenerate(Rng_New(11, "cards"), _full, _pity);
    Test_True("C2 pity: the offer after 2 upgrade-less offers holds an upgrade", Test_CardKinds(_poff.cards).upgrade >= 1);
    Test_Eq("C2 pity: the counter resets once an upgrade was shown", _poff.state.pity, 0);
    var _forced_ok = true; var _unforced_ok = true; var _quota_ok = true; var _quota1_ok = true;
    var _one = Test_CardPlayer(CLASS_MAGE, [SKILL_FIREBALL]);
    for (var _sd = 1; _sd <= 40; _sd++) {
        var _pf = Card_StateNew(); _pf.pity = CARD_PITY_OFFERS;
        var _pu = Card_StateNew(); _pu.pity = CARD_PITY_OFFERS - 1;
        var _of2 = Card_OfferGenerate(Rng_New(_sd, "cards"), _full, _pf);
        if (!_of2.forced || Test_CardKinds(_of2.cards).upgrade < 1) _forced_ok = false;
        if (Card_OfferGenerate(Rng_New(_sd, "cards"), _full, _pu).forced) _unforced_ok = false;
        if (Test_CardKinds(Card_OfferGenerate(Rng_New(_sd, "cards"), _mage0, Card_StateNew()).cards).skill < 1) _quota_ok = false;
        if (Test_CardKinds(Card_OfferGenerate(Rng_New(_sd, "cards"), _one, Card_StateNew()).cards).skill < 1) _quota1_ok = false;
    }
    Test_True("C2 pity: at the limit the upgrade is forced, for 40 seeds", _forced_ok);
    Test_True("C2 pity: one offer before the limit nothing is forced", _unforced_ok);
    Test_True("C2 quota: a class with no skill always sees a new skill, for 40 seeds", _quota_ok);
    Test_True("C2 quota: a class with one skill still always sees a new skill, for 40 seeds", _quota1_ok);
    var _nopity = Card_OfferGenerate(Rng_New(11, "cards"), Test_CardPlayer(CLASS_KNIGHT), _pity);
    Test_True("C2 pity: with no skill owned there is nothing to force and the counter only counts offers that could have had an upgrade", _nopity.state.pity == CARD_PITY_OFFERS && Test_CardKinds(_nopity.cards).upgrade == 0);
    var _ph = Card_StateNew();
    var _pcount = 0; var _pmax = 0;
    var _rp = Rng_New(21, "cards");
    for (var _q = 0; _q < 60; _q++) {
        var _po = Card_OfferGenerate(_rp, _full, _ph);
        _ph = _po.state;
        _pcount = (Test_CardKinds(_po.cards).upgrade > 0) ? 0 : _pcount + 1;
        _pmax = max(_pmax, _pcount);
    }
    Test_True("C2 pity: the longest upgrade-less streak over 60 offers is at most 2", _pmax <= CARD_PITY_OFFERS);

    // decline memory: a card refused in the previous offer is not shown again right away (when other cards exist)
    var _d1 = Card_OfferGenerate(Rng_New(5, "cards"), _mage0, Card_StateNew());
    var _d2 = Card_OfferGenerate(Rng_New(6, "cards"), _mage0, _d1.state);
    var _overlap = 0;
    for (var _a = 0; _a < 3; _a++) for (var _bb = 0; _bb < 3; _bb++) if (_d1.cards[_a] == _d2.cards[_bb]) _overlap++;
    Test_Eq("C2 decline memory: nothing from the previous offer comes back", _overlap, 0);

    // owned things are not offered; a pool that ran dry is filled with fallbacks, still 3 distinct
    var _ownall = Test_CardPlayer(CLASS_NOBODY, [], [], Card_PoolPassiveIds(CLASS_NOBODY));
    var _fo = Card_OfferGenerate(Rng_New(1, "cards"), _ownall, Card_StateNew());
    Test_True("C2 Nobody with every passive: 3 distinct fallback cards", array_length(_fo.cards) == 3 && Test_CardDistinct(_fo.cards) && Test_CardKinds(_fo.cards).fallback == 3);
    var _some = Test_CardPlayer(CLASS_NOBODY, [], [], ["pas:quick_feet", "pas:field_medic", "pas:mana_spring"]);
    var _so = Card_OfferGenerate(Rng_New(2, "cards"), _some, Card_StateNew());
    var _dupown = false;
    for (var _z = 0; _z < 3; _z++) if (_so.cards[_z] == "pas:quick_feet" || _so.cards[_z] == "pas:field_medic" || _so.cards[_z] == "pas:mana_spring") _dupown = true;
    Test_False("C2 an owned passive is not offered again", _dupown);
    Test_True("C2 Nobody's offers hold passives only (no skills, no upgrades)", Test_CardKinds(_so.cards).skill == 0 && Test_CardKinds(_so.cards).upgrade == 0);
    var _owned_sk = Test_CardPlayer(CLASS_MAGE, [SKILL_FIREBALL, SKILL_ICE_SPEAR]);
    var _sk_dup = false; var _rs = Rng_New(8, "cards"); var _ss = Card_StateNew();
    for (var _y = 0; _y < 30; _y++) {
        var _os = Card_OfferGenerate(_rs, _owned_sk, _ss);
        _ss = _os.state;
        for (var _v = 0; _v < 3; _v++) if (_os.cards[_v] == Card_SkillId(SKILL_FIREBALL) || _os.cards[_v] == Card_SkillId(SKILL_ICE_SPEAR)) _sk_dup = true;
    }
    Test_False("C2 an owned skill is never offered as a new skill", _sk_dup);
    var _foreign = false;
    var _kn = Test_CardPlayer(CLASS_KNIGHT);
    for (var _y2 = 0; _y2 < 30; _y2++) {
        var _om = Card_OfferGenerate(_rs, _kn, Card_StateNew());
        for (var _v2 = 0; _v2 < 3; _v2++) if (!Card_Eligible(_kn, CardDB_Get(_om.cards[_v2]))) _foreign = true;
    }
    Test_False("C2 a knight is never offered another class's cards", _foreign);

    // ---- taking a card ----
    var _t0 = Test_CardPlayer(CLASS_MAGE);
    var _tk1 = Card_Take(_t0, Card_SkillId(SKILL_FIREBALL));
    Test_True("C2 taking a skill card learns the skill", !_tk1.needs_replace && array_length(_tk1.ch.skills) == 1 && _tk1.ch.skills[0] == SKILL_FIREBALL);
    var _tk2 = Card_Take(_tk1.ch, Card_UpgradeId(SKILL_FIREBALL));
    Test_True("C2 taking an upgrade card records it", array_length(_tk2.ch.upgrades) == 1 && _tk2.ch.upgrades[0] == SKILL_FIREBALL);
    var _tk3 = Card_Take(_t0, "pas:quick_feet");
    Test_Eq("C2 Quick Feet: +1 SPD at once", _tk3.ch.stats.spd, _t0.stats.spd + 1);
    Test_True("C2 a taken passive is remembered", Card_HasPassive(_tk3.ch, "pas:quick_feet"));
    var _three = Test_CardPlayer(CLASS_MAGE, [SKILL_FIREBALL, SKILL_ICE_SPEAR, SKILL_FORESIGHT], [SKILL_FORESIGHT]);
    var _tk4 = Card_Take(_three, Card_SkillId(SKILL_MEDITATION));
    Test_True("C2 a 4th skill asks which to replace and changes nothing yet (D82)", _tk4.needs_replace && array_length(_tk4.ch.skills) == 3 && _tk4.ch.skills[2] == SKILL_FORESIGHT);
    var _rep = Card_ReplaceSkill(_three, SKILL_FORESIGHT, SKILL_MEDITATION);
    Test_True("C2 replacing swaps the skill in place and keeps 3", array_length(_rep.skills) == 3 && _rep.skills[2] == SKILL_MEDITATION && _rep.skills[0] == SKILL_FIREBALL);
    Test_Eq("C2 the replaced skill's upgrade goes with it", array_length(_rep.upgrades), 0);
    var _fb_hp = Test_CardPlayer(CLASS_KNIGHT);
    _fb_hp.hp = 2;
    var _tk5 = Card_Take(_fb_hp, "fb:rest");
    Test_Eq("C2 Second Wind (fallback) heals half of max HP", _tk5.ch.hp, min(_fb_hp.max_hp, 2 + floor(_fb_hp.max_hp / 2)));
    Test_Eq("C2 Skip pays a small gold amount", Card_SkipGold(), 5);
    _gs.run = Run_Create(1);
    Card_SkipOffer();
    Test_Eq("C2 skipping adds the gold to the run", _gs.run.gold, 5);

    // ---- passives that act in the game ----
    var _pm = Test_CardPlayer(CLASS_KNIGHT, [], [], ["pas:field_medic"]);
    _pm.hp = 4;
    Test_Eq("C2 Field Medic: +3 HP after a won fight", Card_OnVictory(_pm).hp, 7);
    var _pm2 = Test_CardPlayer(CLASS_KNIGHT, [], [], ["pas:field_medic"]);
    Test_Eq("C2 Field Medic never heals above max HP", Card_OnVictory(_pm2).hp, _pm2.max_hp);
    var _ms = Test_CardPlayer(CLASS_MAGE, [], [], ["pas:mana_spring"]);
    _ms.mp = 0;
    Test_Eq("C2 Mana Spring: +1 MP at the start of the turn (through the equipment passive hook)", Equip_PassiveOnTurnStart(_ms).mp, 1);
    var _sh = Test_CardPlayer(CLASS_KNIGHT, [], [], ["pas:steady_hands"]);
    Test_True("C2 Steady Hands: Perfect zone x1.1", abs(Qte_PerfectWiden(_sh) - 1.1) < 0.0001);
    Test_Eq("C2 no passive: Perfect zone x1", Qte_PerfectWiden(Test_CardPlayer(CLASS_KNIGHT)), 1);
    var _ob = Test_CardPlayer(CLASS_KNIGHT, [], [], ["pas:opening_blow"]);
    var _ob_foe = EnemyCreate(ENEMY_SLIME);
    Card_OnBattleStart(_ob, _ob_foe);
    Test_Eq("C2 Opening Blow: the enemy starts the fight with 1 stagger", _ob_foe.stagger, 1);
    var _ob_none = EnemyCreate(ENEMY_SLIME);
    Card_OnBattleStart(Test_CardPlayer(CLASS_KNIGHT), _ob_none);
    Test_Eq("C2 no passive: the enemy starts at 0 stagger", _ob_none.stagger, 0);
    var _vc = Test_CardPlayer(CLASS_ARCHER, [], [], ["pas:venom_coat"]);
    var _foe = EnemyCreate(ENEMY_SLIME);
    Test_Eq("C2 Venom Coat: poison you apply gets +1 stack", Skill_StatusStacks(_vc, _foe, STATUS_POISON, 3), 4);
    Test_Eq("C2 Venom Coat does not touch bleeding", Skill_StatusStacks(_vc, _foe, STATUS_BLEED, 1), 1);
    Test_Eq("C2 without it poison stacks are as before", Skill_StatusStacks(Test_CardPlayer(CLASS_ARCHER), _foe, STATUS_POISON, 3), 3);
    var _pl2 = Test_CardPlayer(CLASS_KNIGHT, [], [], ["pas:potion_lore"]);
    Test_Eq("C2 Potion Lore: potions work 15% better (20 -> 23)", Item_ComputeAmount(_pl2, { power: 20 }), 23);
    Test_Eq("C2 no passive: a potion of 20 stays 20", Item_ComputeAmount(Test_CardPlayer(CLASS_KNIGHT), { power: 20 }), 20);
    Test_True("C2 Coin Sense: gold x1.1 (for the shop packet to call)", abs(Card_GoldMult(Test_CardPlayer(CLASS_KNIGHT, [], [], ["pas:coin_sense"])) - 1.1) < 0.0001);
    Test_Eq("C2 no Coin Sense: gold x1", Card_GoldMult(Test_CardPlayer(CLASS_KNIGHT)), 1);
    var _bw = Test_CardPlayer(CLASS_KNIGHT, [], [], ["pas:k_bulwark"]);
    var _plain = Test_CardPlayer(CLASS_KNIGHT);
    Test_Eq("C2 Bulwark: Guard cast on yourself lasts 3 turns longer", Skill_AdjustStatusTurns(_bw, _bw, STATUS_GUARD, 6), Skill_AdjustStatusTurns(_plain, _plain, STATUS_GUARD, 6) + 3);
    var _ba = Test_CardPlayer(CLASS_ARCHER, [SKILL_POISON_ARROW], [], ["pas:a_barbed"]);
    _gs.player_ch = _ba;
    Test_Eq("C2 Barbed Arrows: +1 power on your damage skills (Poison Arrow 5 -> 6)", SkillDB_Get(SKILL_POISON_ARROW).power, 6);
    Test_Eq("C2 Barbed Arrows leave buff skills alone", SkillDB_Get(SKILL_EVASION).power, 0);
    var _sw = Test_CardPlayer(CLASS_MAGE, [SKILL_FIREBALL, SKILL_MEDITATION], [SKILL_MEDITATION], ["pas:m_spellweave"]);
    _gs.player_ch = _sw;
    Test_Eq("C2 Spellweave: skills cost 1 MP less (Fireball 4 -> 3)", SkillDB_Get(SKILL_FIREBALL).mp_cost, 3);
    Test_Eq("C2 Spellweave never takes a skill below 1 MP (Meditation+ 2 -> 1)", SkillDB_Get(SKILL_MEDITATION).mp_cost, 1);
    Test_Eq("C2 the MP the game charges follows (Equip_PlayerSkillMPCost of the held skill)", Equip_PlayerSkillMPCost(_sw, SkillDB_Get(SKILL_FIREBALL), SkillDB_Get(SKILL_FIREBALL).mp_cost), 3);
    var _an = Test_CardPlayer(CLASS_NOBODY, [], [], ["pas:n_tonic"]);
    var _tgt = Test_CardPlayer(CLASS_NOBODY, [], [], ["pas:n_tonic"]);
    _tgt.hp = 1;
    _tgt.mp = 0;
    var _pot = Item_Use(10, _an, _tgt);
    Test_True("C2 Tonic Blend: a potion also gives 2 MP", _pot.ok && _tgt.mp == 2, "mp=" + string(_tgt.mp));

    // ---- no inert upgrade (balance report: Foresight+ gave +0 turns because the status's fixed duration won over the skill's turns) ----
    // Foresight+ is +2 turns (card table above: 3 > 5), so a real cast on the player leaves 5 turns, base Foresight 3.
    var _fs_base = Test_CardPlayer(CLASS_MAGE, [SKILL_FORESIGHT]);
    var _fs_up = Test_CardPlayer(CLASS_MAGE, [SKILL_FORESIGHT], [SKILL_FORESIGHT]);
    _gs.player_ch = _fs_base;
    Skill_Use(_fs_base, _fs_base, SKILL_FORESIGHT);
    Test_Eq("Foresight: a cast gives 3 turns", Status_Find(_fs_base, STATUS_HIT_UP).turns, 3);
    _gs.player_ch = _fs_up;
    Skill_Use(_fs_up, _fs_up, SKILL_FORESIGHT);
    Test_Eq("Foresight+: a cast gives 5 turns (card says 3 > 5)", Status_Find(_fs_up, STATUS_HIT_UP).turns, 5);
    // data test: EVERY upgrade card changes at least one number the game really uses when the skill is cast, and EVERY number it declares
    // (power, mp_cost, arrows, turns, stacks, chance) really changes: no upgrade, and no half of one, can be inert again.
    var _inert = "";
    var _ups = [SKILL_WOUND, SKILL_HILT_BASH, SKILL_MUSCLE_UP, SKILL_REV_UP, SKILL_HORIZ_SLASH, SKILL_POISON_ARROW, SKILL_EVASION, SKILL_DOUBLE_SHOT, SKILL_TAKE_AIM, SKILL_FIREBALL, SKILL_POISON_MIST, SKILL_ICE_SPEAR, SKILL_MEDITATION, SKILL_FORESIGHT];
    for (var _ui = 0; _ui < array_length(_ups); _ui++) {
        var _usid = _ups[_ui];
        var _ubase = SkillDB_GetBase(_usid);
        var _ucard = CardDB_Get(Card_UpgradeId(_usid));
        var _uup = Skill_WithUpgrade(_ubase, _ucard);
        var _uuser = Test_CardPlayer(CLASS_KNIGHT);
        var _utgt = (_ubase.target == TGT_SELF) ? _uuser : EnemyCreate(ENEMY_SLIME);
        var _eff_a = { power: _ubase.power, mp_cost: _ubase.mp_cost, seq_trim: Card_UpgradedSequenceLength(_usid, []), status_turns: 0, status_stacks: 0, status_chance: 0 };
        var _eff_b = { power: _uup.power, mp_cost: _uup.mp_cost, seq_trim: Card_UpgradedSequenceLength(_usid, [_usid]), status_turns: 0, status_stacks: 0, status_chance: 0 };
        if (_ubase.status != -1) {
            var _ua = Skill_StatusApplyArgs(_uuser, _utgt, _ubase.status, max(1, round(_ubase.status_turns)), Skill_BaseStacks(_ubase));
            var _ub = Skill_StatusApplyArgs(_uuser, _utgt, _uup.status, max(1, round(_uup.status_turns)), Skill_BaseStacks(_uup));
            _eff_a.status_turns = _ua.turns; _eff_a.status_stacks = _ua.stacks;
            _eff_b.status_turns = _ub.turns; _eff_b.status_stacks = _ub.stacks;
            _eff_a.status_chance = variable_struct_exists(_ubase, "status_chance") ? _ubase.status_chance : 1;
            _eff_b.status_chance = variable_struct_exists(_uup, "status_chance") ? _uup.status_chance : 1;
        }
        var _any_changed = false;
        var _dkeys = variable_struct_get_names(_ucard.up);
        for (var _di = 0; _di < array_length(_dkeys); _di++) {
            var _dk = _dkeys[_di];
            if (variable_struct_get(_eff_a, _dk) == variable_struct_get(_eff_b, _dk)) _inert += " " + string(_ubase.name) + "/" + _dk;
            else _any_changed = true;
        }
        if (!_any_changed) _inert += " " + string(_ubase.name) + "/nothing";
    }
    Test_True("every upgrade changes every number it declares, as the game applies it (inert:" + _inert + ")", _inert == "");

    // ---- the owed screens: class choice (D73), free stat point (D76), card pick (D81) ----
    _gs.player_ch = _old_player;
    _gs.run = Run_Create(5);
    Test_False("C2 with a run going, level-up points are not auto-placed (the player places them)", Level_AutoPlaceEnabled());
    var _lv = Test_CardPlayer(CLASS_KNIGHT);
    var _lv_atk = _lv.stats.atk;
    _lv = LevelUp_ApplyLevel(_lv);
    Test_Eq("C2 a level-up keeps the free point banked for the stat prompt", _lv.stat_points, 1);
    Test_Eq("C2 a level-up owes one card pick (D81)", _lv.card_picks, 1);
    Test_Eq("C2 class growth still applies (Knight ATK +1)", _lv.stats.atk, _lv_atk + 1);
    Test_Eq("C2 the owed screens come in order: stat point first", Cards_NextOwed(_lv), "stat");
    _lv = Level_ApplyFreePoint(_lv, STAT_MAG);
    Test_Eq("C2 then the card pick", Cards_NextOwed(_lv), "cards");
    _lv = Cards_ConsumePick(_lv);
    Test_Eq("C2 nothing owed after the pick", Cards_NextOwed(_lv), "");
    var _two = LevelUp_ApplyLevel(LevelUp_ApplyLevel(Test_CardPlayer(CLASS_MAGE)));
    Test_Eq("C2 two levels at once owe two card picks", _two.card_picks, 2);
    variable_struct_remove(_gs, "run");
    var _auto = LevelUp_ApplyLevel(Test_CardPlayer(CLASS_KNIGHT));
    Test_True("C2 outside a run (tests, tools) the point is still auto-placed", Level_AutoPlaceEnabled() && _auto.stat_points == 0);
    var _opts = Cards_StatOptions(Test_CardPlayer(CLASS_KNIGHT));
    Test_True("C2 the stat prompt offers ATK, DEF, SPD, MAG with from > to values", array_length(_opts) == 4 && _opts[0].stat == STAT_ATK && _opts[3].stat == STAT_MAG && _opts[0].to == _opts[0].from + 1);

    // chests (D73, fixes I-057): the first class or skill chest gives the class choice, later ones a pick
    var _fresh = Test_CardPlayer(CLASS_NOBODY);
    Test_False("C2 a new run has not chosen a class", _fresh.class_chosen);
    var _c1 = Cards_ChestOpened(_fresh);
    Test_True("C2 the first class/skill chest owes the class choice, not cards", _c1.class_pick && _c1.card_picks == 0);
    Test_Eq("C2 the class choice comes before everything", Cards_NextOwed(_c1), "class");
    var _c1b = Cards_ChestOpened(_c1);
    Test_True("C2 an unanswered class choice is not owed twice", _c1b.class_pick && _c1b.card_picks == 0);
    var _picked = Card_ClassCharacter(_c1, CLASS_MAGE);
    Test_True("C2 choosing a class sets it, marks it chosen and clears the owed choice", _picked.class_id == CLASS_MAGE && _picked.class_chosen && !_picked.class_pick);
    Test_True("C2 the new class keeps level and items", _picked.level == _c1.level && array_length(_picked.inventory) == array_length(_c1.inventory));
    var _c2 = Cards_ChestOpened(_picked);
    Test_True("C2 every later class/skill chest owes a 1-of-3 pick", !_c2.class_pick && _c2.card_picks == 1);
    var _echo = Test_CardPlayer(CLASS_NOBODY, [SKILL_FIREBALL, SKILL_WOUND]);
    var _kept = Card_ClassCharacter(_echo, CLASS_MAGE);
    Test_True("C2 an echo skill the new class can use is kept, one it cannot is dropped", array_length(_kept.skills) == 1 && _kept.skills[0] == SKILL_FIREBALL);
    var _nob = Card_ClassCharacter(_echo, CLASS_NOBODY);
    Test_Eq("C2 Nobody has no skills (D83)", array_length(_nob.skills), 0);

    // Nobody is locked until the first win (D83, D88)
    var _prof = Profile_Default();
    var _ch0 = Card_ClassChoices(_prof);
    Test_Eq("C2 the class screen lists Knight, Archer, Mage, Nobody", array_length(_ch0), 4);
    Test_True("C2 Knight, Archer and Mage are open from the start", !_ch0[0].locked && !_ch0[1].locked && !_ch0[2].locked);
    Test_True("C2 Nobody is shown locked with a hint before the first win", _ch0[3].class_id == CLASS_NOBODY && _ch0[3].locked && string_length(_ch0[3].hint) > 5);
    Profile_Unlock(_prof, "nobody_class");
    Test_False("C2 Nobody is open once the profile has won", Card_ClassChoices(_prof)[3].locked);

    // the pick screen's cursor model (D95: wrap-around): cards left/right, Skip below
    Test_Eq("C2 pick cursor: right moves to the next card", Cards_PickMove(0, 3, 1, 0, 0), 1);
    Test_Eq("C2 pick cursor: left from the first card wraps to the last", Cards_PickMove(0, 3, -1, 0, 0), 2);
    Test_Eq("C2 pick cursor: right from the last card wraps to the first", Cards_PickMove(2, 3, 1, 0, 2), 0);
    Test_Eq("C2 pick cursor: down goes to Skip", Cards_PickMove(1, 3, 0, 1, 1), 3);
    Test_Eq("C2 pick cursor: up from Skip returns to the card it left", Cards_PickMove(3, 3, 0, -1, 1), 1);
    Test_Eq("C2 pick cursor: left/right on Skip stay on Skip", Cards_PickMove(3, 3, 1, 0, 1), 3);

    // skill books are gone (D18)
    var _books = 0;
    var _ik = ds_map_find_first(global.item_db);
    while (!is_undefined(_ik)) {
        var _iti = ItemDB_Get(_ik);
        if (variable_struct_exists(_iti, "use") && is_struct(_iti.use) && variable_struct_exists(_iti.use, "effect") && _iti.use.effect == "learn_skill") _books++;
        _ik = ds_map_find_next(global.item_db, _ik);
    }
    Test_Eq("C2 no skill book is left in the item database (D18)", _books, 0);

    _gs.player_ch = _old_player;
    if (_had_run) _gs.run = _old_run; else variable_struct_remove(_gs, "run");
}


// ---- D1a: battle HUD (D99), details (D100), icons (D94), the Guard command, small enemy moves (I-066, D7), I-065 ----
function Test_RowValue(_lines, _label) {
    for (var _i = 0; _i < array_length(_lines); _i++) if (_lines[_i].label == _label) return _lines[_i].value;
    return "";
}

function Test_RectsOverlap(_a, _b) {
    return _a.x < _b.x + _b.w && _b.x < _a.x + _a.w && _a.y < _b.y + _b.h && _b.y < _a.y + _a.h;
}

function Test_Suite_BattleUi() {
    // ---- I-066 / D7: only the telegraphed heavy moves get the defence bar ----
    var _player = CharacterCreate_Player(CLASS_KNIGHT);
    var _landed = { ok: true, hit: true, dmg: 3 };
    var _plain = [SKILL_POISON_FANGS, SKILL_BITE, SKILL_SCORCHING_TOUCH, SKILL_GORE];
    for (var _i = 0; _i < array_length(_plain); _i++) {
        Test_False("BattleUi " + SkillDB_Get(_plain[_i]).name + " is a plain move: no defence bar", Battle_EnemySkillCanBeDefended(SkillDB_Get(_plain[_i]), _landed, _player));
    }
    var _heavy = [SKILL_VINE_TRAP, SKILL_GHOST_CUT, SKILL_RAMMING, SKILL_PALE_HYMN];
    for (var _h = 0; _h < array_length(_heavy); _h++) {
        Test_True("BattleUi " + SkillDB_Get(_heavy[_h]).name + " is a heavy move: defence bar", Battle_EnemySkillCanBeDefended(SkillDB_Get(_heavy[_h]), _landed, _player));
    }
    var _every_defended_is_telegraphed = true;
    for (var _sid = 0; _sid <= 31; _sid++) {
        var _sk = SkillDB_Get(_sid);
        if (is_struct(_sk) && Battle_EnemySkillCanBeDefended(_sk, _landed, _player)) {
            if (!(variable_struct_exists(_sk, "telegraphed") && _sk.telegraphed)) _every_defended_is_telegraphed = false;
        }
    }
    Test_True("BattleUi every skill that gets the defence bar is telegraphed (D7)", _every_defended_is_telegraphed);
    Test_False("BattleUi a plain enemy move does not show the big-attack mark on the strip", Battle_ActionPreviewOf({ kind: "skill", skill_id: SKILL_POISON_FANGS }, true).big);

    // ---- layout: nothing overlaps (I-067), everything is on screen ----
    var _sizes = [[480, 432, 2, 16, 2], [640, 576, 3, 24, 2], [800, 720, 4, 32, 3], [960, 864, 6, 48, 4]];   // gui w, gui h, p, line height, icon pixel size k
    for (var _z = 0; _z < array_length(_sizes); _z++) {
        var _g = _sizes[_z];
        var _tlb = 3 * _g[2] + (16 * _g[4] + 6 * _g[2]) + 2 * _g[2] + (_g[3] + _g[2]);   // the turn strip's bottom edge (margin + slot + chrome + caption)
        var _zn = BattleHud_Zones(_g[0], _g[1], _g[2], _g[3], _tlb, 16 * _g[4]);
        var _tag = "BattleUi zones " + string(_g[0]) + "x" + string(_g[1]);
        Test_True(_tag + ": player panel on screen", _zn.player.x >= _zn.m && _zn.player.y >= 0 && _zn.player.x + _zn.player.w <= _g[0] - _zn.m && _zn.player.y + _zn.player.h <= _g[1] - _zn.m);
        Test_True(_tag + ": the right column starts after the player panel", _zn.right.x >= _zn.player.x + _zn.player.w + _zn.m);
        Test_True(_tag + ": the right column ends inside the screen", _zn.right.x + _zn.right.w <= _g[0] - _zn.m + 0.5);
        Test_True(_tag + ": the log sits above both bottom panels", _zn.msg.y + _zn.msg.h <= _zn.player.y && _zn.msg.y + _zn.msg.h <= _zn.band_top);
        Test_False(_tag + ": the log does not overlap the player panel", Test_RectsOverlap(_zn.msg, _zn.player));
        Test_True(_tag + ": the log is below the turn strip", _zn.msg.y >= _tlb);
        Test_True(_tag + ": the log is on screen", _zn.msg.x >= 0 && _zn.msg.x + _zn.msg.w <= _g[0] && _zn.msg.y + _zn.msg.h <= _g[1]);
        Test_True(_tag + ": the command menu (5 rows) fits the band", _zn.cmd_h <= _zn.band_h && _zn.band_top > _tlb);
    }

    // ---- icons (D94): frames are the positions in art/strips_v2/*.txt ----
    var _st = [[STATUS_POISON, 0], [STATUS_BURN, 1], [STATUS_BLEED, 2], [STATUS_STUN, 3], [STATUS_GUARD, 6], [STATUS_DMG_UP, 7], [STATUS_EVASION, 8], [STATUS_CRIT_UP, 9], [STATUS_HIT_UP, 10],
               [STATUS_MEDITATION, 11], [STATUS_SOLIDIFY, 12], [STATUS_BLOODTHIRSTY, 13], [STATUS_BLESSING, 14], [STATUS_SUNDER, 15], [STATUS_BRACE, 6]];
    for (var _s2 = 0; _s2 < array_length(_st); _s2++) Test_Eq("BattleUi status " + string(_st[_s2][0]) + " icon frame", Icon_StatusFrame(_st[_s2][0]), _st[_s2][1]);
    var _sk2 = [[SKILL_WOUND, 0], [SKILL_HILT_BASH, 1], [SKILL_MUSCLE_UP, 2], [SKILL_REV_UP, 3], [SKILL_HORIZ_SLASH, 4], [SKILL_POWER_STRIKE, 5], [SKILL_POISON_ARROW, 6], [SKILL_EVASION, 7],
                [SKILL_DOUBLE_SHOT, 8], [SKILL_TAKE_AIM, 9], [SKILL_FIREBALL, 10], [SKILL_POISON_MIST, 11], [SKILL_ICE_SPEAR, 12], [SKILL_MEDITATION, 13], [SKILL_FORESIGHT, 14]];
    for (var _k2 = 0; _k2 < array_length(_sk2); _k2++) Test_Eq("BattleUi skill " + string(_sk2[_k2][0]) + " icon frame", Icon_SkillFrame(_sk2[_k2][0]), _sk2[_k2][1]);
    Test_Eq("BattleUi throwable poison_pot icon frame (D114 redo)", Icon_Frame("throwable", "poison_pot"), 1);
    Test_Eq("BattleUi status bloodthirsty and solidify frames (D114 redo)", Icon_Frame("status", "bloodthirsty") * 100 + Icon_Frame("status", "solidify"), 1312);
    var _rows_ok = true;
    for (var _f = 0; _f < 17; _f++) {
        var _r = Icon_Rows("status", _f);
        if (array_length(_r) != 16 || string_length(_r[0]) != 16 || string_length(_r[15]) != 16) _rows_ok = false;
    }
    Test_True("BattleUi the 17 status icons have 16 x 16 pixel rows", _rows_ok);
    Test_Eq("BattleUi a frame past the strip has no rows", array_length(Icon_Rows("status", 17)), 0);

    // ---- status chips (D99): icon frame and the number the player needs (turns, or the stacks of a poison) ----
    var _ch = CharacterCreate_Player(CLASS_MAGE);
    _ch = Status_Add(_ch, STATUS_POISON, 0, 0, 3);
    _ch = Status_Add(_ch, STATUS_BURN, 2, 3);
    _ch = Status_Add(_ch, STATUS_BRACE, 2, 0);
    var _chips = Battle_StatusChips(_ch);
    Test_Eq("BattleUi three statuses make three chips", array_length(_chips), 3);
    Test_Eq("BattleUi poison chip shows its 3 stacks", _chips[0].text, "3");
    Test_True("BattleUi poison is a debuff chip", _chips[0].negative);
    Test_Eq("BattleUi burn chip shows its 2 turns", _chips[1].text, "2");
    Test_Eq("BattleUi braced chip uses the guard icon", _chips[2].frame, 6);
    Test_False("BattleUi braced is a buff chip", _chips[2].negative);
    Test_Eq("BattleUi a chip carries the description from the data", _chips[1].line, Status_Describe(STATUS_BURN, Status_Find(_ch, STATUS_BURN)).line);

    // ---- details panel (D100): generated from the data, never typed ----
    var _fb = SkillDB_Get(SKILL_FIREBALL);
    var _det = Battle_SkillDetails(_fb);
    Test_Eq("BattleUi Fireball sentence comes from the data", _det.sentence, Card_SkillSentence(SkillDB_GetBase(SKILL_FIREBALL)));
    Test_Eq("BattleUi Fireball power line is the data's power", Test_RowValue(_det.lines, Loc_T("card.lbl.power", "Power")), string(round(_fb.power)));
    Test_Eq("BattleUi Fireball MP line is the data's cost", Test_RowValue(_det.lines, Loc_T("card.lbl.mp", "MP")), string(round(_fb.mp_cost)));
    var _pa = SkillDB_Get(SKILL_POISON_ARROW);
    var _pdet = Battle_SkillDetails(_pa);
    Test_Eq("BattleUi Poison Arrow shows its poison stacks from the data", Test_RowValue(_pdet.lines, Loc_T("card.lbl.stacks", "Stacks")), string(round(_pa.status_stacks)));
    Test_Eq("BattleUi Fireball shows the burn turns from the data", Test_RowValue(_det.lines, Loc_T("card.lbl.turns", "Turns")), string(round(_fb.status_turns)));
    Test_Eq("BattleUi Fireball shows the burn chance from the data", Test_RowValue(_det.lines, Loc_T("card.lbl.chance", "Chance")), string(round(_fb.status_chance * 100)) + "%");
    var _mu = SkillDB_Get(SKILL_MUSCLE_UP);
    Test_Eq("BattleUi a buff shows no Power line", Test_RowValue(Battle_SkillDetails(_mu).lines, Loc_T("card.lbl.power", "Power")), "");
    var _hp = ItemDB_Get(10);
    var _idet = Battle_ItemDetails(_hp, _player);
    var _rng = Item_AmountRange(_player, _hp.use);
    Test_Eq("BattleUi HP Potion Lv1 range at level 1 is the data's 5-10", string(_rng.lo) + "-" + string(_rng.hi), "5-10");
    Test_Eq("BattleUi HP Potion row shows that range", Test_RowValue(_idet.lines, Loc_T("battle.det.hp", "HP")), "5-10");
    var _lvl5 = CharacterCreate_Player(CLASS_KNIGHT);
    _lvl5.level = 5;
    var _rng5 = Item_AmountRange(_lvl5, _hp.use);
    Test_Eq("BattleUi HP Potion Lv1 range at level 5 adds the level scaling (4 levels x 1.0)", string(_rng5.lo) + "-" + string(_rng5.hi), "9-14");
    var _inside = true;
    for (var _t = 0; _t < 40; _t++) {
        var _a = Item_ComputeAmount(_lvl5, _hp.use);
        if (_a < _rng5.lo || _a > _rng5.hi) _inside = false;
    }
    Test_True("BattleUi the real roll always falls inside the shown range", _inside);

    // ---- rows of the skill list: MP, arrows, greyed when the MP is short ----
    var _kn = CharacterCreate_Player(CLASS_KNIGHT);
    _kn.skills = [SKILL_WOUND, SKILL_MUSCLE_UP, SKILL_HILT_BASH];   // a fresh Knight has none: they come from cards (D82)
    var _srows = Battle_SkillRows(_kn);
    Test_Eq("BattleUi one row per skill the player knows", array_length(_srows), array_length(_kn.skills));
    Test_Eq("BattleUi the first row is the first skill", _srows[0].skill_id, _kn.skills[0]);
    Test_Eq("BattleUi the arrows are the real sequence", string(_srows[0].seq), string(Qte_SkillSequence(_kn.skills[0])));
    Test_Eq("BattleUi the MP cost is the real cost", _srows[0].cost, Equip_PlayerSkillMPCost(_kn, SkillDB_Get(_kn.skills[0]), SkillDB_Get(_kn.skills[0]).mp_cost));
    Test_False("BattleUi an affordable skill is not greyed", _srows[0].dim);
    _kn.mp = 0;
    Test_True("BattleUi a skill the player cannot pay for is greyed (still selectable, with its details)", Battle_SkillRows(_kn)[0].dim);
    var _irows = Battle_ItemRows(_player);
    Test_True("BattleUi the HP potion is in the item list with its quantity", array_length(_irows) >= 1 && _irows[0].item_id == 10 && _irows[0].qty == 2);

    // ---- the Guard command (D99): the next hit deals half, then it is gone ----
    var _slime = EnemyCreate(ENEMY_SLIME);
    var _src = { power: 6, stat_type: STAT_ATK };
    var _g0 = CharacterCreate_Player(CLASS_KNIGHT);
    var _plain_hit = Combat_ApplyDamage(_slime, _g0, _src, 1, 1, { is_skill: false }).dmg;
    var _g1 = Battle_GuardApply(CharacterCreate_Player(CLASS_KNIGHT));
    Test_True("BattleUi Guard leaves the player Braced", Status_Has(_g1, STATUS_BRACE));
    var _braced_hit = Combat_ApplyDamage(_slime, _g1, _src, 1, 1, { is_skill: false });
    Test_True("BattleUi a Braced hit deals about half (" + string(_plain_hit) + " -> " + string(_braced_hit.dmg) + ")", _plain_hit >= 2 && _braced_hit.dmg < _plain_hit && abs(_braced_hit.dmg - _plain_hit * 0.5) <= 1);
    Test_False("BattleUi the hit used the Brace up", Status_Has(_braced_hit.defender, STATUS_BRACE));
    var _g2 = Battle_GuardApply(CharacterCreate_Player(CLASS_KNIGHT));
    _g2 = Status_Tick(_g2);
    Test_True("BattleUi Brace survives the Guard turn's own tick", Status_Has(_g2, STATUS_BRACE));
    _g2 = Status_Tick(_g2);
    Test_False("BattleUi Brace fades after one more turn when nothing hit", Status_Has(_g2, STATUS_BRACE));

    // ---- I-065: level gains survive the battle's own normalisation (GameState_Init runs it at every battle start) ----
    var _lv = CharacterCreate_Player(CLASS_KNIGHT);
    _lv = Player_AddExp(_lv, 200);
    var _lv_before = { level: _lv.level, max_hp: _lv.max_hp, hp: _lv.hp, atk: _lv.stats.atk, def: _lv.stats.def, spd: _lv.stats.spd, mag: _lv.stats.mag };
    Test_True("BattleUi (I-065) 200 EXP levels the Knight up", _lv_before.level >= 3);
    Test_Eq("BattleUi (I-065) max HP follows the level: base 10 + 7 per level", _lv_before.max_hp, 10 + (_lv_before.level - 1) * 7);
    var _lv2 = Player_NormalizeProgression(_lv, true);
    Test_Eq("BattleUi (I-065) normalising keeps the level", _lv2.level, _lv_before.level);
    Test_Eq("BattleUi (I-065) normalising keeps max HP", _lv2.max_hp, _lv_before.max_hp);
    Test_Eq("BattleUi (I-065) normalising keeps HP", _lv2.hp, _lv_before.hp);
    Test_Eq("BattleUi (I-065) normalising keeps the stats", string(_lv2.stats.atk) + "/" + string(_lv2.stats.def) + "/" + string(_lv2.stats.spd) + "/" + string(_lv2.stats.mag), string(_lv_before.atk) + "/" + string(_lv_before.def) + "/" + string(_lv_before.spd) + "/" + string(_lv_before.mag));

    Test_BattleHudFrame();    // D108 F1d-1: the HUD data is built once per Draw GUI frame
    Test_IconFrames();        // D108 F1d-1: Icon_Frame answers are unchanged
    Test_IconLookups();       // D108 F1d-1: the strip sprite is looked up once per category
}

// ---- D108 F1d-1: battle HUD data built once per Draw GUI frame; icon lookups cached -------------------------------------------------
// A stand-in for obj_battle_controller with the fields the HUD data reads: the player (burning, Steadfast on the timeline), the enemy (poisoned,
// BROKEN) standing as a real obj_enemy_battle instance, and a skill banner up. Returns the struct; the caller destroys bc.enemy_inst.
function Test_HudFakeBattle() {
    var _pl = CharacterCreate_Player(CLASS_MAGE);
    _pl = Status_Add(_pl, STATUS_BURN, 2, 3);
    var _en = EnemyCreate(ENEMY_SLIME);
    _en = Status_Add(_en, STATUS_POISON, 0, 0, 3);
    _en.broken = true;
    var _tl = Turn_New([Turn_Fighter(TL_PLAYER, 5), Turn_Fighter(TL_ENEMY, 4)]);
    _tl.fighters[0].steadfast = 2;
    var _inst = instance_create_depth(0, 0, 0, obj_enemy_battle);
    _inst.sprite_index = _en.sprite;
    _inst.x = 72;
    _inst.y = 60;
    return { p: _pl, e: _en, tl: _tl, enemy_inst: _inst, cam_base_x: 0, cam_base_y: 0, skill_banner_active: true, skill_banner_name: "Fireball",
             battle_state: BSTATE_ATTACK_TIMING, hud: { clock: 0, hp_shown: 1, mp_shown: 1, rects: {} } };
}

// The data calls one Draw GUI frame of the battle controller makes, in the order it makes them (Draw_64.gml and the Battle_Draw* it calls, as they
// were before F1d-1: the zones, the enemy header, the strip, the banner, the player panel, the pops, then the rects kept for the tests).
function Test_HudDrawPattern(_bc) {
    var _o = {};
    Battle_Zones();
    _o.hdr = Battle_EnemyHeaderRect(_bc);
    Battle_FighterChips(_bc, TL_ENEMY);
    _o.tm = Battle_TimelineMetrics(_bc);
    Battle_BannerRect(_bc);
    _o.chips_p = Battle_FighterChips(_bc, TL_PLAYER);
    Battle_TimelineBottom();
    Battle_TimelineMetrics(_bc);
    Battle_TimelineMetrics(_bc);
    Battle_TimelineMetrics(_bc);
    Battle_TimelineMetrics(_bc);
    Battle_EnemyHeaderRect(_bc);
    _o.chips_e = Battle_FighterChips(_bc, TL_ENEMY);
    return _o;
}

function Test_HudJson(_a, _b) {
    return json_stringify(_a) == json_stringify(_b);
}

function Test_BattleHudFrame() {
    var _bc = Test_HudFakeBattle();
    // outside a frame nothing is shared (Step code and the scenarios call these between frames): every call builds and answers from the live data
    Battle_HudBuildsReset();
    var _live = Test_HudDrawPattern(_bc);
    Test_True("BattleUi (D108) outside a frame every call builds (metrics " + string(Battle_HudBuilds().metrics) + ")", Battle_HudBuilds().metrics > 1);

    Battle_HudBuildsReset();
    Battle_HudFrameBegin(_bc);
    var _f1 = Test_HudDrawPattern(_bc);
    Battle_HudFrameEnd();
    var _b = Battle_HudBuilds();
    Test_Eq("BattleUi (D108) one draw frame builds the timeline metrics once", _b.metrics, 1);
    Test_Eq("BattleUi (D108) one draw frame builds the enemy header rect once", _b.header, 1);
    Test_Eq("BattleUi (D108) one draw frame builds the enemy chips once", _b.chips_enemy, 1);
    Test_Eq("BattleUi (D108) one draw frame builds the player chips once", _b.chips_player, 1);
    Test_True("BattleUi (D108) the frame's timeline metrics equal the live ones", Test_HudJson(_f1.tm, _live.tm));
    Test_True("BattleUi (D108) the frame's enemy header rect equals the live one", Test_HudJson(_f1.hdr, _live.hdr));
    Test_True("BattleUi (D108) the frame's enemy chips equal the live ones", Test_HudJson(_f1.chips_e, _live.chips_e));
    Test_True("BattleUi (D108) the frame's player chips equal the live ones", Test_HudJson(_f1.chips_p, _live.chips_p));
    Test_Eq("BattleUi (D108) the test fighters wear 2 enemy chips (poison, BREAK) and 2 player chips (burn, Steadfast)", array_length(_f1.chips_e) * 10 + array_length(_f1.chips_p), 22);

    // the next frame sees what changed in between: a new status, a new HP
    _bc.p = Status_Add(_bc.p, STATUS_BLEED, 3, 2, 2);
    _bc.e.hp = max(1, _bc.e.hp - 1);
    Battle_HudBuildsReset();
    Battle_HudFrameBegin(_bc);
    var _f2 = Test_HudDrawPattern(_bc);
    Battle_HudFrameEnd();
    var _b2 = Battle_HudBuilds();
    Test_Eq("BattleUi (D108) the next frame builds each piece once again", _b2.metrics * 1000 + _b2.header * 100 + _b2.chips_enemy * 10 + _b2.chips_player, 1111);
    Test_Eq("BattleUi (D108) the next frame shows the new status chip", array_length(_f2.chips_p), array_length(_f1.chips_p) + 1);

    // [PERF] the data path of 1000 frames (no assertion: the time depends on the PC)
    var _t0 = get_timer();
    for (var _i = 0; _i < 1000; _i++) {
        Battle_HudFrameBegin(_bc);
        Test_HudDrawPattern(_bc);
        Battle_HudFrameEnd();
    }
    var _ms = (get_timer() - _t0) / 1000;
    show_debug_message("[PERF] battle HUD data path, 1000 frames: " + string_format(_ms, 1, 2) + " ms");
    instance_destroy(_bc.enemy_inst);
}

// Frames of every known icon, taken ONCE from the Icon_Frame of the commit before F1d-1 (the linear scan over the strip's ids) and kept here as literals.
// Icon_Frame must keep answering exactly this. "" and unknown names or categories answer -1.
function Test_IconFrames() {
    var _table = [
        ["skill", [["wound", 0], ["hilt_bash", 1], ["muscle_up", 2], ["rev_up", 3], ["horizontal_slash", 4], ["power_strike", 5], ["poison_arrow", 6], ["evasion", 7], ["double_shot", 8], ["take_aim", 9], ["fireball", 10], ["poison_mist", 11], ["ice_spear", 12], ["meditation", 13], ["foresight", 14]]],
        ["status", [["poison", 0], ["burn", 1], ["bleed", 2], ["stun", 3], ["steadfast", 4], ["break", 5], ["guard", 6], ["rev_up", 7], ["evasion", 8], ["take_aim", 9], ["foresight", 10], ["meditation", 11], ["solidify", 12], ["bloodthirsty", 13], ["blessing", 14], ["sundered", 15], ["curse", 16]]],
        ["accessory", [["ring", 0], ["charm", 1]]],
        ["misc", [["gold_coin", 0]]],
        ["throwable", [["firebomb", 0], ["poison_pot", 1], ["ice_flask", 2], ["smoke_bomb", 3]]],
        ["passive", [["attack", 0], ["defense", 1], ["vitality", 2], ["magic", 3], ["speed", 4], ["critical", 5], ["greed", 6], ["recovery", 7]]]
    ];
    var _n = 0;
    var _bad = "";
    for (var _c = 0; _c < array_length(_table); _c++) {
        for (var _i = 0; _i < array_length(_table[_c][1]); _i++) {
            _n++;
            var _got = Icon_Frame(_table[_c][0], _table[_c][1][_i][0]);
            if (_got != _table[_c][1][_i][1]) _bad += " " + _table[_c][0] + "/" + _table[_c][1][_i][0] + "=" + string(_got);
        }
    }
    Test_Eq("Fx (D108) Icon_Frame answers the same frame for all " + string(_n) + " known icons" + _bad, _bad, "");
    Test_Eq("Fx (D108) Icon_Frame counts 47 known icons", _n, 47);
    Test_Eq("Fx (D108) Icon_Frame of an unknown name, an empty name and an unknown category is -1", Icon_Frame("status", "nope") + Icon_Frame("status", "") + Icon_Frame("nocat", "poison"), -3);
    Test_Eq("Fx (D108) Icon_Frame is per category: rev_up is 7 as a status and 3 as a skill", Icon_Frame("status", "rev_up") * 10 + Icon_Frame("skill", "rev_up"), 73);
}

function Test_IconLookups() {
    global.icon_lookups = 0;
    var _cats = ["status", "skill", "throwable", "passive", "accessory", "misc", "no_such_category"];
    var _same = true;
    for (var _c = 0; _c < array_length(_cats); _c++) {
        var _want = asset_get_index("spr_icons_" + _cats[_c]);
        if (_want == -1) _want = asset_get_index(_cats[_c] + "_strip");   // the owner's import names (2026-10-16)
        for (var _i = 0; _i < 50; _i++) if (Icon_StripSprite(_cats[_c]) != _want) _same = false;
    }
    Test_True("Fx (D108) the cached strip sprite is the one asset_get_index gives (either import name), for every category", _same);
    Test_True("Fx (D108) 350 strip lookups ask asset_get_index at most once per category (" + string(global.icon_lookups) + ")", global.icon_lookups <= array_length(_cats));
}

// ---- D1b: the Tab menu (D90), the pause menu (D92, D95), the Codex (D88, D107), white text (D115) ----------------------------------------
// Expected values come from the decisions and the game data: D90 (Status, Skills, Items, Gear, Codex, Settings), D92 (a pause menu with Abandon run,
// an accessory slot), D95 (wrap-around), D100 (numbers from the data), D115 (item names and list text white, #FFFFFF), D88/D107 (bestiary, notes,
// run history, unlocks). The screens themselves are driven through real input in smoke 181-195.
function Test_RowById(_items, _key, _val) {
    for (var _i = 0; _i < array_length(_items); _i++) {
        if (variable_struct_exists(_items[_i], _key) && variable_struct_get(_items[_i], _key) == _val) return _items[_i];
    }
    return undefined;
}

function Test_LineDelta(_lines, _label) {
    for (var _i = 0; _i < array_length(_lines); _i++) if (_lines[_i].label == _label) return _lines[_i].delta;
    return 0;
}

function Test_FirstPassive() {
    var _all = CardDB_All();
    for (var _i = 0; _i < array_length(_all); _i++) if (_all[_i].kind == "passive") return _all[_i].id;
    return -1;
}

function Test_Suite_TabMenu() {
    ItemDB_Init(); SkillDB_Init(); EnemyDB_Init();

    // ---- D90: six tabs, in this order; Q / E wrap (D95) ----
    var _ids = TabMenu_Ids();
    Test_Eq("D90 six tabs", array_length(_ids), 6);
    Test_Eq("D90 tab order", _ids[0] + "/" + _ids[1] + "/" + _ids[2] + "/" + _ids[3] + "/" + _ids[4] + "/" + _ids[5], "status/skills/items/gear/codex/settings");
    var _lb = TabMenu_Labels();
    Test_Eq("D90 tab labels", _lb[0] + "," + _lb[1] + "," + _lb[2] + "," + _lb[3] + "," + _lb[4] + "," + _lb[5], "Status,Skills,Items,Gear,Codex,Settings");
    Test_Eq("D95 Q on the first tab wraps to the last", Ui_TabStep(0, 6, -1), 5);
    Test_Eq("D95 E on the last tab wraps to the first", Ui_TabStep(5, 6, 1), 0);

    // ---- D115: white text, one place ----
    Test_Eq("D115 the text colour is #FFFFFF", UI_C_TEXT, $FFFFFF);
    Test_Eq("D115 the palette's pale text role is drawn white", Ui_TextColor(UI_C_LIGHTEST), $FFFFFF);
    Test_Eq("D115 the light green accent is left alone", Ui_TextColor(UI_C_LIGHT), UI_C_LIGHT);
    Test_Eq("D115 the dark green is left alone", Ui_TextColor(UI_C_DARK), UI_C_DARK);
    Test_Eq("D115 a list row that is not selected is white", Ui_RowColor(false, true, false), $FFFFFF);
    Test_Eq("D115 the selected row is white too", Ui_RowColor(true, true, false), $FFFFFF);
    Test_Eq("D115 a row you cannot afford is the light green", Ui_RowColor(false, true, true), UI_C_LIGHT);
    Test_Eq("D115 a greyed row is the dark green", Ui_RowColor(false, false, false), UI_C_DARK);

    // ---- Status: ATK DEF SPD MAG with plain descriptions, then statuses ----
    var _k = CharacterCreate_Player(CLASS_KNIGHT);
    var _base_atk = _k.stats.atk;
    var _st = TabStatus_Items(_k);
    Test_Eq("D90 Status lists ATK, DEF, SPD, MAG first", _st[0].label + _st[1].label + _st[2].label + _st[3].label, "ATKDEFSPDMAG");
    Test_Eq("D90 Status shows the character's ATK", _st[0].value, string(_base_atk));
    Test_Eq("D90 Status ATK has a plain description", _st[0].help, Loc_T("menu.tooltip.stat.atk.desc", "Increases physical damage (basic attacks and ATK skills)."));
    Test_Eq("D90 a character with no status has four rows", array_length(_st), 4);
    _k.inventory = Inv_Add(_k.inventory, 40, 1);
    Test_True("D92 the Copper Ring (ATK +1) equips in the accessory slot", Equip_Item(_k, 40) && Equip_SlotGet(_k, "accessory") == 40);
    _st = TabStatus_Items(_k);
    Test_Eq("D92 Status ATK counts the ring (+1)", _st[0].value, string(_base_atk + 1));
    Test_Eq("D100 Status ATK says where the +1 comes from", Test_RowValue(_st[0].lines, Loc_T("tab.lbl.gear", "Gear")), "+1");
    Test_Eq("D100 Status ATK shows the base", Test_RowValue(_st[0].lines, Loc_T("tab.lbl.base", "Base")), string(_base_atk));
    _k = Status_Add(_k, STATUS_POISON, 0, 0, 2);
    _st = TabStatus_Items(_k);
    Test_Eq("D90 a status is listed after the four stats", array_length(_st), 5);
    Test_Eq("D90 the status row is the status's name", _st[4].label, StatusDB_Get(STATUS_POISON).name);

    // ---- Skills: the equipped skills with MP, arrows and numbers from the data (D100); passives after them ----
    var _sk = CharacterCreate_Player(CLASS_KNIGHT);
    var _none = TabSkills_Items(_sk);
    Test_True("D90 no skills: one greyed row says so", array_length(_none) == 1 && !_none[0].enabled);
    _sk.skills = [SKILL_WOUND, SKILL_MUSCLE_UP, SKILL_HILT_BASH];
    var _srows = TabSkills_Items(_sk);
    Test_Eq("D90 one row per equipped skill", array_length(_srows), 3);
    Test_Eq("D90 skill row label is the skill's name", _srows[2].label, SkillDB_Get(SKILL_HILT_BASH).name);
    Test_Eq("D100 skill row shows the real arrows", string(_srows[2].seq), string(Qte_SkillSequence(SKILL_HILT_BASH)));
    Test_Eq("D100 skill power is the data's power", Test_RowValue(_srows[2].lines, Loc_T("card.lbl.power", "Power")), string(round(SkillDB_Get(SKILL_HILT_BASH).power)));
    Test_Eq("D100 skill MP is the data's cost", Test_RowValue(_srows[2].lines, Loc_T("card.lbl.mp", "MP")), string(round(SkillDB_Get(SKILL_HILT_BASH).mp_cost)));
    Test_Eq("D90 a skill with no upgrade says None", Test_RowValue(_srows[0].lines, Loc_T("tab.lbl.upgrade", "Upgrade")), Loc_T("tab.val.none", "None"));
    _sk.upgrades = [SKILL_WOUND];
    Test_Eq("D90 an upgraded skill says Applied", Test_RowValue(TabSkills_Items(_sk)[0].lines, Loc_T("tab.lbl.upgrade", "Upgrade")), Loc_T("tab.val.applied", "Applied"));
    _sk.passives = [Test_FirstPassive()];
    var _prows = TabSkills_Items(_sk);
    Test_Eq("D90 a passive is listed after the skills, under its own heading", array_length(_prows), 5);
    Test_True("D90 the heading is not a row to pick", _prows[3].kind == "head" && !_prows[3].enabled);
    Test_Eq("D90 the passive row is the card's name", _prows[4].label, Card_Name(CardDB_Get(Test_FirstPassive())));

    // ---- Items: potions and throwables with counts; equipment is not listed here ----
    var _ik = CharacterCreate_Player(CLASS_KNIGHT);
    _ik.inventory = Inv_Add(_ik.inventory, 1, 1);
    var _irows = TabItems_Items(_ik);
    Test_Eq("D90 Items lists the two starting potions as one row", array_length(_irows), 1);
    Test_Eq("D90 Items row is the potion", _irows[0].label, ItemDB_Get(10).name);
    Test_Eq("D90 Items row shows the count", _irows[0].value, "x2");
    Test_Eq("D100 Items row sentence is the item's", _irows[0].help, Item_Sentence(ItemDB_Get(10)));
    var _hurt = CharacterCreate_Player(CLASS_KNIGHT);
    _hurt.hp = 1;
    var _used = TabItems_Use(_hurt, 10);
    Test_True("D90 a potion can be used from the menu", _used.ok);
    Test_True("D90 the potion healed (5-10 at level 1)", _used.ch.hp >= 6 && _used.ch.hp <= _used.ch.max_hp);
    Test_Eq("D90 using it spends one", Inv_Count(_used.ch.inventory, 10), 1);
    var _full = CharacterCreate_Player(CLASS_KNIGHT);
    var _refused = TabItems_Use(_full, 10);
    Test_False("D90 a potion is refused at full HP", _refused.ok);
    Test_Eq("D90 a refused potion is not spent", Inv_Count(_full.inventory, 10), 2);
    var _th = CharacterCreate_Player(CLASS_KNIGHT);
    _th.inventory = Inv_Add(_th.inventory, 30, 1);
    var _tr = TabItems_Use(_th, 30);
    Test_False("D84 a throwable is not used from the menu", _tr.ok);
    Test_Eq("D84 a throwable stays in the bag", Inv_Count(_th.inventory, 30), 1);
    Test_Eq("D90 Items lists potions and the throwable", array_length(TabItems_Items(_th)), 2);

    // ---- Gear: weapon, armor and accessory slots; equip with a before / after comparison (D90, D92) ----
    var _g = CharacterCreate_Player(CLASS_KNIGHT);
    _g.inventory = Inv_Add(_g.inventory, 1, 1);
    _g.inventory = Inv_Add(_g.inventory, 2, 1);
    _g.inventory = Inv_Add(_g.inventory, 22, 1);
    _g.inventory = Inv_Add(_g.inventory, 40, 1);
    _g.inventory = Inv_Add(_g.inventory, 23, 1);
    Equip_Item(_g, 1);
    var _def0 = _g.stats.def;
    var _gi = TabGear_Items(_g);
    var _wrow = Test_RowById(_gi, "item_id", 1);
    Test_True("D90 the worn Wooden Sword is listed as worn", is_struct(_wrow) && _wrow.worn);
    var _iron = Test_RowById(_gi, "item_id", 2);
    Test_True("D90 the Iron Sword is in the bag, not worn", is_struct(_iron) && !_iron.worn);
    Test_Eq("D90 weapon comparison: power 3 to 6", Test_RowValue(_iron.lines, Loc_T("card.lbl.power", "Power")), "3 > 6");
    Test_Eq("D90 weapon comparison marks the rise", Test_LineDelta(_iron.lines, Loc_T("card.lbl.power", "Power")), 1);
    var _plat = Test_RowById(_gi, "item_id", 22);
    Test_Eq("D90 armor comparison: DEF " + string(_def0) + " to " + string(_def0 + 3), Test_RowValue(_plat.lines, "DEF"), string(_def0) + " > " + string(_def0 + 3));
    Test_Eq("D90 armor comparison marks the rise", Test_LineDelta(_plat.lines, "DEF"), 1);
    var _ring = Test_RowById(_gi, "item_id", 40);
    Test_Eq("D92 accessory comparison: ATK +1", Test_RowValue(_ring.lines, "ATK"), string(_g.stats.atk) + " > " + string(_g.stats.atk + 1));
    var _robe = Test_RowById(_gi, "item_id", 23);
    Test_True("D90 a robe the Knight cannot wear is greyed", _robe.dim);
    var _eq = Gear_Toggle(_g, 22);
    Test_True("D90 equipping armor works", _eq.ok && _eq.equipped);
    Test_Eq("D90 equipping armor raises DEF by its bonus", Stat_Get(_eq.ch, STAT_DEF), _def0 + 3);
    var _off = Gear_Toggle(_eq.ch, 22);
    Test_True("D90 confirming a worn item takes it off", _off.ok && !_off.equipped && Equip_SlotGet(_off.ch, "body") == 0);
    Test_Eq("D90 taking it off brings DEF back", Stat_Get(_off.ch, STAT_DEF), _def0);
    var _bad = Gear_Toggle(_g, 23);
    Test_False("D90 a robe cannot be equipped by the Knight", _bad.ok);
    Test_True("D90 the three slots come first, then the bag", _gi[0].kind == "head" && _gi[1].slot == "weapon" && _gi[2].slot == "body" && _gi[3].slot == "accessory");
    Test_Eq("D90 an empty slot says what is missing", _gi[2].label + "/" + _gi[3].label, Loc_T("tab.gear.no_armor", "No armor") + "/" + Loc_T("tab.gear.no_accessory", "No accessory"));
    Test_True("D90 a bag item's sentence says what it replaces", string_pos(ItemDB_Get(1).name, _iron.help) > 0);
    Test_False("D90 an item for an empty slot replaces nothing", string_pos(Loc_T("tab.gear.replaces", "Replaces {item}.", { item: "" }), _plat.help) > 0);

    // ---- Codex (D88, D107) ----
    var _p = Profile_Default();
    var _b0 = Codex_BestiaryRows(_p);
    Test_Eq("D88 the bestiary has a row for every enemy", array_length(_b0), 10);
    Test_Eq("D88 an enemy not met yet is ???", _b0[0].label, "???");
    Codex_Met(_p, ENEMY_SLIME, false);
    var _b1 = Codex_BestiaryRows(_p);
    var _slime = EnemyDB_Get(ENEMY_SLIME);
    Test_Eq("D88 a met enemy shows its name", _b1[0].label, _slime.name);
    Test_Eq("D88 a met enemy shows its ATK from the data", Test_RowValue(_b1[0].lines, "ATK"), string(_slime.stats.atk));
    Test_Eq("D88 a met enemy shows its HP from the data", Test_RowValue(_b1[0].lines, Loc_T("tab.lbl.hp", "HP")), string(_slime.base_hp));
    Test_Eq("D88 the others stay ???", _b1[1].label, "???");
    Test_Eq("D88 one meeting is counted", Test_RowValue(_b1[0].lines, Loc_T("tab.lbl.met", "Met")), "1");
    Codex_Met(_p, ENEMY_SLIME, true);
    Test_Eq("D88 meeting it again counts", Test_RowValue(Codex_BestiaryRows(_p)[0].lines, Loc_T("tab.lbl.met", "Met")), "2");
    Test_Eq("D88 an elite seen is noted", Test_RowValue(Codex_BestiaryRows(_p)[0].lines, Loc_T("tab.lbl.elite", "Elite")), Loc_T("tab.val.seen", "Seen"));
    Test_Eq("D88 the bestiary count", Codex_BestiaryCount(_p), 1);
    var _pn = Profile_Normalize(json_parse(json_stringify(_p)));
    Test_Eq("D88 the bestiary survives the profile file", Codex_BestiaryCount(_pn), 1);
    Test_Eq("D88 an old profile with no bestiary is fine", Codex_BestiaryCount(Profile_Normalize({ profile_version: PROFILE_VERSION })), 0);
    var _n0 = Codex_NoteRows(_p);
    Test_Eq("D107 one row for each of the 8 notes", array_length(_n0), 8);
    Test_Eq("D107 an unread note is ???", _n0[0].label, "???");
    Note_MarkCollected(_p, "map_page");
    var _n1 = Codex_NoteRows(_p);
    Test_Eq("D107 a note read shows its title", _n1[0].label, Note_Find("map_page").title);
    Test_True("D107 a note read shows its text", string_pos(Note_Find("map_page").lines[1], _n1[0].help) > 0);
    Test_Eq("D107 notes found count", Codex_NoteCount(_p), 1);
    Test_Eq("D88 no history: no rows to open", array_length(Codex_HistoryRows(_p)), 0);
    Profile_RecordRun(_p, { seed: 1111, class_id: CLASS_KNIGHT, level: 4, floor: 3, room: "rm_floor3", result: "died", cause: "Spider", kills: 7, gold: 52, at: 0 });
    Profile_RecordRun(_p, { seed: 2222, class_id: CLASS_MAGE, level: 6, floor: 9, room: "rm_floor9_5", result: "won", cause: "", kills: 20, gold: 300, at: 0 });
    var _h = Codex_HistoryRows(_p);
    Test_Eq("D88 history has a row per finished run", array_length(_h), 2);
    Test_Eq("D88 the newest run is first", Test_RowValue(_h[0].lines, Loc_T("tab.lbl.seed", "Seed")), "2222");
    Test_Eq("D88 a death shows its floor", Test_RowValue(_h[1].lines, Loc_T("tab.lbl.floor", "Floor")), "3");
    Test_True("D88 a death names what killed you", string_pos("Spider", _h[1].help) > 0);
    var _u = Codex_UnlockRows(_p);
    Test_True("D88 the Nobody class is unlocked by the first win", _u[0].value == Loc_T("tab.val.unlocked", "Unlocked"));
    var _u2 = Codex_UnlockRows(Profile_Default());
    Test_True("D88 before any win it is locked and says how", _u2[0].value == Loc_T("tab.val.locked", "Locked") && _u2[0].help != "");

    // ---- the pause menu (D92, D95): Resume, Help, Settings, Abandon run (two presses), Quit to title ----
    var _pm = PauseMenu_Items(false);
    Test_Eq("D92 pause rows", _pm[0].id + "/" + _pm[1].id + "/" + _pm[2].id + "/" + _pm[3].id + "/" + _pm[4].id, "resume/help/settings/abandon/quit");
    Test_Eq("D92 pause labels", _pm[0].label + "," + _pm[1].label + "," + _pm[2].label + "," + _pm[3].label + "," + _pm[4].label, "Resume,Help,Settings,Abandon run,Quit to title");
    Test_Eq("D92 Abandon is where the constant says", PAUSE_ABANDON_INDEX, 3);
    Test_Eq("D92 the armed Abandon row asks again", PauseMenu_Items(true)[3].label, Loc_T("pause.option.abandon_confirm", "Sure? Confirm again"));
    Test_True("D100 every pause row explains itself", string_length(_pm[0].help) > 0 && string_length(_pm[3].help) > 0 && string_length(_pm[4].help) > 0);
}

// ---- C4: QTE assist (D35), key rebinding (D49), button prompts (D92), tutorial prompts (D45), beds (D47) ----------------------------------
// Expected values come from the decisions: D35 (one assist option widening the zones; the packet's numbers: zones x1.5, arrow time x1.3),
// D49 (rebind keyboard keys; conflicts swap; reset to defaults; gamepad stays default), D92 (prompts match the last-used device),
// D45 (once per profile, 11 mechanics, a Help page lists them all), D47 (a bed: heal OR upgrade one owned skill, once per run per bed).
function Test_Suite_Assist() {
    Test_Eq("D35 assist off: zones x1", Qte_AssistZoneMult(false), 1);
    Test_Eq("D35 assist on: zones x1.5", Qte_AssistZoneMult(true), 1.5);
    Test_Eq("D35 assist off: arrow time x1", Qte_AssistTimeMult(false), 1);
    Test_Eq("D35 assist on: arrow time x1.3", Qte_AssistTimeMult(true), 1.3);
    var _bar = Qte_BarParams("default");   // 1100 ms sweep, Perfect +-60, Good +-120, OK +-200, centre at 770
    var _c = Qte_ZoneCentreMs(_bar);
    Test_Eq("D35 off: 80 ms from the centre is GOOD", Qte_Grade(_c + 80, _bar, Qte_AssistZoneMult(false)), "GOOD");
    Test_Eq("D35 on: 80 ms from the centre is PERFECT (+-90)", Qte_Grade(_c + 80, _bar, Qte_AssistZoneMult(true)), "PERFECT");
    Test_Eq("D35 off: 150 ms from the centre is OK", Qte_Grade(_c - 150, _bar, Qte_AssistZoneMult(false)), "OK");
    Test_Eq("D35 on: 150 ms from the centre is GOOD (+-180)", Qte_Grade(_c - 150, _bar, Qte_AssistZoneMult(true)), "GOOD");
    Test_Eq("D35 off: 250 ms from the centre is WEAK", Qte_Grade(_c - 250, _bar, Qte_AssistZoneMult(false)), "WEAK");
    Test_Eq("D35 on: 250 ms from the centre is OK (+-300)", Qte_Grade(_c - 250, _bar, Qte_AssistZoneMult(true)), "OK");
    // the defence bars use the same grader, so they widen too
    var _def = Qte_DefenceParams(SKILL_BITE);
    Test_Eq("D35 off: a Bite bar press 70 ms off is GOOD", Qte_Grade(Qte_ZoneCentreMs(_def) + 70, _def, 1), "GOOD");
    Test_Eq("D35 on: a Bite bar press 70 ms off is PERFECT (+-82.5)", Qte_Grade(Qte_ZoneCentreMs(_def) + 70, _def, Qte_AssistZoneMult(true)), "PERFECT");
    // the arrow time bar and its Perfect window stretch by x1.3; a wrong press still costs 250 ms
    var _p1 = Qte_SeqParams(3, Qte_AssistTimeMult(false));
    var _p2 = Qte_SeqParams(3, Qte_AssistTimeMult(true));
    Test_Eq("D35 off: 3 arrows keep 3400 ms", _p1.limit_ms, 3400);
    Test_True("D35 on: 3 arrows get 3400 x 1.3 = 4420 ms", abs(_p2.limit_ms - 4420) < 0.001);
    Test_True("D35 on: the Perfect window is 1500 x 1.3 = 1950 ms", abs(_p2.fast_ms - 1950) < 0.001);
    Test_Eq("D35 on: a wrong press still costs 250 ms", _p2.penalty_ms, 250);
    // a slow but clean 3-arrow run: Good without the assist, Perfect with it
    var _slow = [{ t: 600, dir: UP }, { t: 1200, dir: LEFT }, { t: 1800, dir: DOWN }];
    Test_Eq("D35 off: finishing at 1800 ms is only GOOD", Qte_SeqRun([UP, LEFT, DOWN], _slow, Qte_AssistTimeMult(false)).key, "GOOD");
    Test_Eq("D35 on: finishing at 1800 ms is PERFECT", Qte_SeqRun([UP, LEFT, DOWN], _slow, Qte_AssistTimeMult(true)).key, "PERFECT");
    // the live setting: the hooks the battle reads
    var _st = GameSettings_Ensure();
    var _was = _st.qte_assist;
    _st.qte_assist = 0;
    Test_Eq("D35 live: setting off gives x1 zones", Qte_AssistMult(), 1);
    Test_Eq("D35 live: setting off gives x1 arrow time", Qte_AssistTimeMultNow(), 1);
    _st.qte_assist = 1;
    Test_Eq("D35 live: setting on gives x1.5 zones", Qte_AssistMult(), 1.5);
    Test_Eq("D35 live: setting on gives x1.3 arrow time", Qte_AssistTimeMultNow(), 1.3);
    _st.qte_assist = _was;
}

function Test_Suite_Binds() {
    var _ids = Binds_RowIds();
    var _txt = "";
    for (var _i = 0; _i < array_length(_ids); _i++) _txt += ((_i > 0) ? "," : "") + _ids[_i];
    Test_Eq("D49 rebindable rows, in order", _txt, "confirm,back,up,down,left,right,run,tab_prev,tab_next,interact");
    var _d = Binds_Defaults();
    Test_True("D49 default confirm: Space, Z, Enter", Test_SameArray(_d.confirm, [vk_space, ord("Z"), vk_enter]));
    Test_True("D49 default back: Esc, X", Test_SameArray(_d.back, [vk_escape, ord("X")]));
    Test_True("D49 default up: W, Up", Test_SameArray(_d.up, [ord("W"), vk_up]));
    Test_True("D49 default down: S, Down", Test_SameArray(_d.down, [ord("S"), vk_down]));
    Test_True("D49 default left: A, Left", Test_SameArray(_d.left, [ord("A"), vk_left]));
    Test_True("D49 default right: D, Right", Test_SameArray(_d.right, [ord("D"), vk_right]));
    Test_True("D49 default run: Shift", Test_SameArray(_d.run, [vk_shift]));
    Test_True("D49 default tabs: Q and E", Test_SameArray(_d.tab_prev, [ord("Q")]) && Test_SameArray(_d.tab_next, [ord("E")]));
    Test_True("D49 default interact: Space", Test_SameArray(_d.interact, [vk_space]));
    Test_Eq("D49 key text of the default confirm", Binds_KeysText(_d.confirm), "Space / Z / Enter");

    // assigning: the new key replaces the first key (a key the action already has swaps places with it); the others stay
    var _r = Binds_Assign(_d, "confirm", ord("T"));
    Test_True("D49 assign: ok", _r.ok);
    Test_True("D49 assign: the new key replaces the first, the others stay", Test_SameArray(_r.keys.confirm, [ord("T"), ord("Z"), vk_enter]));
    Test_Eq("D49 assign: no swap when the key was free", _r.swapped, "");
    Test_True("D49 assign: the input table is untouched", Test_SameArray(_d.confirm, [vk_space, ord("Z"), vk_enter]));
    // a key the action already has swaps places with the first key
    var _r2 = Binds_Assign(_d, "confirm", ord("Z"));
    Test_True("D49 an owned key moves to the front", _r2.ok && Test_SameArray(_r2.keys.confirm, [ord("Z"), vk_space, vk_enter]));
    Test_Eq("D49 an unrelated key list keeps its length", array_length(_r.keys.confirm), 3);
    Test_Eq("D49 an owned key swaps nothing", _r2.swapped, "");
    // conflicts swap: confirm takes X, back gets confirm's old first key in its place
    var _r3 = Binds_Assign(_d, "confirm", ord("X"));
    Test_Eq("D49 conflict: X was Back's, so Back is swapped", _r3.swapped, "back");
    Test_Eq("D49 conflict: Confirm now starts with X", _r3.keys.confirm[0], ord("X"));
    Test_True("D49 conflict: Back lost X and got Space instead", Test_SameArray(_r3.keys.back, [vk_escape, vk_space]));
    Test_True("D49 conflict: Confirm lost Space (it moved to Back)", Test_SameArray(_r3.keys.confirm, [ord("X"), ord("Z"), vk_enter]));
    Test_Eq("D49 conflict: X is no longer Back's", Binds_Conflict(_r3.keys, "confirm", ord("X")), "");
    // directions are used everywhere, so they conflict with everything
    var _r4 = Binds_Assign(_d, "run", ord("W"));
    Test_Eq("D49 conflict: Run wants W, Up is swapped", _r4.swapped, "up");
    Test_True("D49 conflict: Up got Shift in W's place", Test_SameArray(_r4.keys.up, [vk_shift, vk_up]));
    var _r5 = Binds_Assign(_d, "up", ord("A"));
    Test_Eq("D49 conflict: Up wants A, Left is swapped", _r5.swapped, "left");
    Test_True("D49 conflict: Left got W in A's place", Test_SameArray(_r5.keys.left, [ord("W"), vk_left]));
    // menu-only and world-only actions never meet, so Interact and Confirm may share a key
    var _r6 = Binds_Assign(_d, "interact", ord("Z"));
    Test_Eq("D49 Interact on Z does not touch Confirm (different places)", _r6.swapped, "");
    Test_True("D49 Confirm keeps Z", Test_SameArray(_r6.keys.confirm, [vk_space, ord("Z"), vk_enter]));
    // reserved keys
    var _res = [vk_escape, vk_f5, vk_f9, ord("P"), ord("I"), vk_tab];
    for (var _k = 0; _k < array_length(_res); _k++) {
        var _rr = Binds_Assign(_d, "confirm", _res[_k]);
        Test_False("D49 reserved key " + string(_res[_k]) + " is refused", _rr.ok);
    }
    Test_False("D49 a missing key is refused", Binds_Assign(_d, "confirm", -1).ok);
    Test_False("D49 an unknown action is refused", Binds_Assign(_d, "dance", ord("T")).ok);
    Test_True("D49 letters can be captured", Binds_CanCapture(ord("T")));
    Test_False("D49 Esc cannot be captured (it cancels the capture)", Binds_CanCapture(vk_escape));

    // normalising: bad data falls back to defaults row by row
    var _n0 = Binds_Normalize(undefined);
    Test_True("D49 normalize(nothing) is the defaults", Test_SameArray(_n0.confirm, _d.confirm) && Test_SameArray(_n0.run, _d.run));
    var _n1 = Binds_Normalize({ confirm: [ord("T"), ord("T"), 0, "x", ord("G")], run: "oops", up: [] });
    Test_True("D49 normalize drops duplicates and junk", Test_SameArray(_n1.confirm, [ord("T"), ord("G")]));
    Test_True("D49 normalize: a wrong-typed row gets its default", Test_SameArray(_n1.run, _d.run));
    Test_True("D49 normalize: an empty row gets its default", Test_SameArray(_n1.up, _d.up));
    Test_True("D49 normalize: a missing row gets its default", Test_SameArray(_n1.back, _d.back));
    var _n2 = Binds_Normalize({ confirm: [ord("A"), ord("B"), ord("C"), ord("D"), ord("E")] });
    Test_Eq("D49 normalize keeps at most 3 keys", array_length(_n2.confirm), 3);

    // bindings for the input system: one row feeds several actions
    var _a = Binds_ToActions(_r.keys);
    Test_True("D49 confirm feeds the confirm action", Test_SameArray(_a.confirm, _r.keys.confirm));
    Test_True("D49 back feeds the cancel action", Test_SameArray(_a.cancel, _r.keys.back));
    Test_True("D49 up feeds the world and the menu", Test_SameArray(_a.move_up, _r.keys.up) && Test_SameArray(_a.menu_up, _r.keys.up));
    Test_True("D49 interact feeds the interact action", Test_SameArray(_a.interact, _r.keys.interact));

    // settings: persisted with a version bump; old files get the defaults
    Test_True("D49 settings defaults carry the default keys", Test_SameArray(GameSettings_Defaults().keys.confirm, _d.confirm));
    var _norm = GameSettings_Normalize({ keys: { confirm: [ord("T")] } });
    Test_True("D49 settings normalize keeps a custom row", Test_SameArray(_norm.keys.confirm, [ord("T")]));
    Test_True("D49 settings normalize defaults the other rows", Test_SameArray(_norm.keys.back, _d.back));
    var _f = "test_settings_keys.json";
    Save_DeleteFileSet(_f);
    var _cust = GameSettings_Defaults();
    _cust.keys = _r3.keys;
    Save_WriteSettingsConfig(_cust, _f);
    var _raw = json_parse(Test_RawRead(_f));
    Test_Eq("D49 the file is version 10", _raw.settings_version, 10);
    var _back = Save_ReadSettingsConfig(_f);
    Test_True("D49 custom keys survive a save", is_struct(_back) && Test_SameArray(_back.keys.confirm, _r3.keys.confirm) && Test_SameArray(_back.keys.back, _r3.keys.back));
    Save_DeleteFileSet(_f);
    Test_RawWrite(_f, "{\"settings_version\":9,\"text_speed\":2,\"qte_assist\":1}");
    var _old = Save_ReadSettingsConfig(_f);
    Test_True("D49 a version 9 file gets the default keys", is_struct(_old) && Test_SameArray(_old.keys.confirm, _d.confirm) && Test_SameArray(_old.keys.interact, _d.interact));
    Test_Eq("D49 a version 9 file keeps its other settings", is_struct(_old) ? _old.text_speed : -1, 2);
    Save_DeleteFileSet(_f);

    // the live table and the labels
    Binds_Apply(_r.keys);
    Test_True("D49 apply: the confirm action has the new keys", Test_SameArray(global.input.bindings.confirm, _r.keys.confirm));
    Test_True("D49 apply: the cancel action follows Back", Test_SameArray(global.input.bindings.cancel, _r.keys.back));
    Test_True("D49 apply: menu_up and move_up share the Up row", Test_SameArray(global.input.bindings.menu_up, _r.keys.up) && Test_SameArray(global.input.bindings.move_up, _r.keys.up));
    Input_Init();
    Test_True("D49 apply: a later Input_Init does not put the old keys back", Test_SameArray(global.input.bindings.confirm, _r.keys.confirm));
    Test_Eq("D49 apply: labels follow the keys", Input_Label("confirm"), "T / Z / Enter");
    Binds_Apply(_d);
    Test_Eq("D49 apply the defaults: the labels are back", Input_Label("confirm"), "Space / Z / Enter");
    Test_True("D49 apply the defaults: the pause key is untouched", Test_SameArray(global.input.bindings.pause, [vk_escape]));

    // the Controls page rows
    var _items = Controls_Items(_d, "");
    var _cid = "";
    for (var _j = 0; _j < array_length(_items); _j++) _cid += ((_j > 0) ? "," : "") + _items[_j].id;
    Test_Eq("D49 controls page rows", _cid, "confirm,back,up,down,left,right,run,tab_prev,tab_next,interact,reset");
    Test_Eq("D49 a controls row shows its keys", _items[0].value, "Space / Z / Enter");
    Test_Eq("D49 the row being captured says so", Controls_Items(_d, "back")[1].value, Loc_T("controls.press_key", "Press a key..."));
    var _cr = Controls_Capture(_d, "confirm", ord("X"));
    Test_True("D49 capture: the model is changed", _cr.ok && _cr.keys.confirm[0] == ord("X"));
    Test_True("D49 capture: the message names the swapped action", string_pos(Binds_RowLabel("back"), _cr.message) > 0);
    Test_False("D49 capture of a reserved key says why", Controls_Capture(_d, "confirm", vk_f5).ok);

    // a menu ignores confirm / back for a moment after it opens or becomes the top one again (a key seen on two frames cannot answer two menus)
    var _stk = Ui_StackNew();
    var _m1 = Ui_MenuNew("lock_a", [{ label: "A" }], {});
    var _m2 = Ui_MenuNew("lock_b", [{ label: "B" }], {});
    _m1.lock_ms = current_time - 1000;
    Ui_StackPush(_stk, _m1);
    Ui_StackPush(_stk, _m2);
    _m1.lock_ms = current_time - 1000;
    _m2.lock_ms = current_time - 1000;
    Test_True("UI lock: a new menu starts locked", Ui_MenuNew("lock_c", [{ label: "C" }], {}).lock_ms >= current_time - 1);
    Test_True("UI lock: a pushed menu is locked", abs(Ui_StackPush(Ui_StackNew(), Ui_MenuNew("lock_d", [], {})).lock_ms - current_time) <= 3);
    Ui_StackBack(_stk);
    Test_True("UI lock: the menu that comes back is locked again", abs(_m1.lock_ms - current_time) <= 3);
}

function Test_Suite_Prompt() {
    Test_Eq("D92 a pad press switches to the pad", Prompt_DeviceStep("keyboard", false, true), "gamepad");
    Test_Eq("D92 a key press switches to the keyboard", Prompt_DeviceStep("gamepad", true, false), "keyboard");
    Test_Eq("D92 no input keeps the keyboard", Prompt_DeviceStep("keyboard", false, false), "keyboard");
    Test_Eq("D92 no input keeps the pad", Prompt_DeviceStep("gamepad", false, false), "gamepad");
    Test_Eq("D92 both in one frame keeps what it was (pad)", Prompt_DeviceStep("gamepad", true, true), "gamepad");
    Test_Eq("D92 both in one frame keeps what it was (keyboard)", Prompt_DeviceStep("keyboard", true, true), "keyboard");
    Binds_Apply(Binds_Defaults());
    var _k = Prompt_Info("confirm", "keyboard");
    Test_True("D92 keyboard confirm: a keycap with the first key", _k.kind == "key" && _k.label == "Space");
    var _p = Prompt_Info("confirm", "gamepad");
    Test_True("D92 pad confirm: a round A", _p.kind == "pad" && _p.label == "A");
    Test_Eq("D92 pad back is B", Prompt_Info("cancel", "gamepad").label, "B");
    Test_Eq("D92 pad interact is A", Prompt_Info("interact", "gamepad").label, "A");
    Test_Eq("D92 pad menu is X", Prompt_Info("menu", "gamepad").label, "X");
    Test_Eq("D92 pad pause is Y", Prompt_Info("pause", "gamepad").label, "Y");
    Test_Eq("D92 pad tab_prev is LB", Prompt_Info("tab_prev", "gamepad").label, "LB");
    Test_Eq("D92 pad tab_next is RB", Prompt_Info("tab_next", "gamepad").label, "RB");
    Test_Eq("D92 pad run is LT", Prompt_Info("run", "gamepad").label, "LT");
    Test_Eq("D92 pad up is the D-pad", Prompt_Info("move_up", "gamepad").label, "D-Pad");
    Test_Eq("D92 keyboard up is W", Prompt_Info("move_up", "keyboard").label, "W");
    Test_Eq("D92 keyboard back is Esc", Prompt_Info("cancel", "keyboard").label, "Esc");
    Test_Eq("D92 keyboard tab_prev is Q", Prompt_Info("tab_prev", "keyboard").label, "Q");
    Test_Eq("D92 the row names work too (back)", Prompt_Info("back", "keyboard").label, "Esc");
    Test_Eq("D92 the row names work too (up)", Prompt_Info("up", "keyboard").label, "W");
    Test_Eq("D92 text of a pad prompt", Prompt_Text("confirm", "gamepad"), "A");
    Test_Eq("D92 text of a keyboard prompt", Prompt_Text("run", "keyboard"), "Shift");
    Test_Eq("D92 an unknown action shows its own name", Prompt_Info("dance", "keyboard").label, "dance");
    // rebinding changes the keyboard prompt only
    var _kb = Binds_Assign(Binds_Defaults(), "confirm", ord("T")).keys;
    Binds_Apply(_kb);
    Test_Eq("D92 a rebound key shows on the keyboard prompt", Prompt_Info("confirm", "keyboard").label, "T");
    Test_Eq("D92 the pad prompt stays default", Prompt_Info("confirm", "gamepad").label, "A");
    Binds_Apply(Binds_Defaults());
    // the live device
    global.input.last_device = "gamepad";
    Test_Eq("D92 the live device decides the glyph", Prompt_Info("confirm").label, "A");
    global.input.last_device = "keyboard";
    Test_Eq("D92 the live device decides the glyph (keyboard)", Prompt_Info("confirm").label, "Space");

    // text with prompts inside
    var _t = Prompt_Tokens("Press {confirm} to go, {back} to leave.");
    Test_Eq("D92 tokens: five parts", array_length(_t), 5);
    Test_True("D92 tokens: text, action, text, action, text", _t[0].kind == "text" && _t[1].kind == "action" && _t[2].kind == "text" && _t[3].kind == "action" && _t[4].kind == "text");
    Test_True("D92 tokens: the action names", _t[1].s == "confirm" && _t[3].s == "back");
    Test_Eq("D92 tokens: text between is kept", _t[2].s, " to go, ");
    Test_Eq("D92 tokens: plain text is one part", array_length(Prompt_Tokens("No prompts here.")), 1);
    Test_Eq("D92 tokens: empty text is none", array_length(Prompt_Tokens("")), 0);
    Test_Eq("D92 tokens: a lone action", array_length(Prompt_Tokens("{interact}")), 1);
    Test_Eq("D92 tokens: an unclosed brace is plain text", Prompt_Tokens("a {b")[0].s, "a {b");
    Test_Eq("D92 plain text of a line with prompts", Prompt_Plain("Press {confirm}.", "gamepad"), "Press A.");
    Test_True("D92 has-prompts tells the two apart", Prompt_HasTokens("Press {confirm}.") && !Prompt_HasTokens("Press it."));
}

function Test_Suite_Tutorial() {
    var _ids = Tutorial_Ids();
    var _txt = "";
    for (var _i = 0; _i < array_length(_ids); _i++) _txt += ((_i > 0) ? "," : "") + _ids[_i];
    Test_Eq("D45 the eleven mechanics, in order", _txt, "timeline,bar,arrows,defence,stagger,cards,shop,throwables,bed,elite,status");
    for (var _j = 0; _j < array_length(_ids); _j++) {
        var _e = Tutorial_Get(_ids[_j]);
        Test_True("D45 " + _ids[_j] + " has a title and a short text", is_struct(_e) && string_length(_e.title) > 2 && string_length(_e.body) > 20 && string_length(_e.body) < 260);
    }
    Test_True("D45 the bar text says what to press", string_pos("{confirm}", Tutorial_Get("bar").body) > 0);
    Test_True("D45 the arrows text names the arrow keys", string_pos("{up}", Tutorial_Get("arrows").body) > 0);
    Test_True("D45 the defence text says what to press", string_pos("{confirm}", Tutorial_Get("defence").body) > 0);
    Test_False("D45 an unknown tutorial is nothing", is_struct(Tutorial_Get("dance")));

    var _was_off = variable_global_exists("tutorial_off") ? global.tutorial_off : true;
    Profile_ResetForTest();
    global.tutorial_ui = undefined;
    global.tutorial_off = false;
    Test_False("D45 nothing is seen on a fresh profile", Tutorial_Seen("bar"));
    Test_False("D45 nothing is open at first", Tutorial_IsOpen());
    Test_True("D45 the first trigger opens the pop-up", Tutorial_Trigger("bar"));
    Test_True("D45 the pop-up is open and is the one asked for", Tutorial_IsOpen() && Tutorial_CurrentId() == "bar");
    Test_True("D45 it is marked as seen at once", Tutorial_Seen("bar") && Story_Seen("tutorial:bar"));
    Test_True("D45 a pop-up blocks the world", UI_IsBlocking());
    Test_False("D45 the same one never opens twice", Tutorial_Trigger("bar"));
    Test_True("D45 a second mechanic waits behind the first", Tutorial_Trigger("arrows") && Tutorial_CurrentId() == "bar" && Tutorial_QueueLength() == 1);
    Tutorial_Dismiss();
    Test_True("D45 dismissing shows the queued one", Tutorial_IsOpen() && Tutorial_CurrentId() == "arrows" && Tutorial_QueueLength() == 0);
    Tutorial_Dismiss();
    Test_False("D45 dismissing the last one closes it", Tutorial_IsOpen());
    Test_True("D45 the frame it closes in still blocks (the closing press must not answer what is behind)", Tutorial_JustClosed() && UI_IsBlocking());
    Test_True("F2b-2 the closing press is still guarded one 33 ms frame later", InputLock_Tick(global.tutorial_closed, Input_Frame() + 1, Presentation_StepMs(33333)));
    global.tutorial_closed = undefined;   // D108 F2b-2: was tutorial_closed_frame = Input_Frame() - 5, i.e. long past
    Test_False("D45 a closed pop-up does not block", UI_IsBlocking());
    Test_False("D45 an unknown id opens nothing", Tutorial_Trigger("dance"));
    Test_False("D45 an unknown id marks nothing", Story_Seen("tutorial:dance"));
    // persisted: the flags are in the profile file
    var _disk = Profile_Load(Profile_Path()).profile;
    Test_True("D45 the profile on disk has the flags", Profile_StorySeen(_disk, "tutorial:arrows") && Profile_StorySeen(_disk, "tutorial:bar"));
    Test_False("D45 seen once, never again (same profile)", Tutorial_Trigger("arrows"));
    // the switch for the scripted runs
    global.tutorial_off = true;
    Test_False("D45 off: nothing opens", Tutorial_Trigger("shop"));
    Test_False("D45 off: nothing is marked", Tutorial_Seen("shop"));
    global.tutorial_off = false;
    // the Help page lists all eleven, seen or not
    var _help = Tutorial_HelpItems();
    Test_Eq("D45 the Help page lists all eleven", array_length(_help), 11);
    Test_Eq("D45 the Help rows carry the titles", _help[1].label, Tutorial_Get("bar").title);
    Test_Eq("D45 the Help rows carry the text for the details panel", _help[1].help, Tutorial_Get("bar").body);
    Test_True("D45 the pop-up footer has a prompt", Prompt_HasTokens(Tutorial_Footer()));
    global.tutorial_ui = undefined;
    Profile_ResetForTest();
    global.tutorial_off = _was_off;
}

// D96 / D108 F3a: the notice pop-up (one message, Confirm to dismiss) on the shared UI framework. Time is milliseconds only: every call below
// passes its own clock, the game frame never advances, so a frame count anywhere in the module would make these fail.
function Test_Suite_Notice() {
    var _gs = GameState_Get();
    var _mode0 = _gs.ui.mode;
    var _f0 = Input_Frame();
    global.notice_ui = undefined;
    _gs.ui.mode = UI_NONE;
    var _t0 = 100000;   // a made-up clock, far from current_time
    Test_False("F3a nothing is open at first", Notice_IsOpen());
    Test_Eq("F3a no text while nothing is open", Notice_Text(), "");
    Test_False("F3a a closed notice does not block", UI_IsBlocking());

    var _msg = "Saves from the earlier version cannot be loaded in this one.";
    Notice_Open(_msg, _t0);
    Test_True("F3a open: it is visible", Notice_IsOpen());
    Test_Eq("F3a open: it shows the text it was given", Notice_Text(), _msg);
    Test_Eq("F3a open: the UI mode says a notice is up", _gs.ui.mode, UI_NOTICE);
    Test_True("F3a open: it blocks the world", UI_IsBlocking());
    Test_False("F3a open: it is not closing", Notice_Closing());
    Test_True("F3a the input lock is the menus' one (a few frames, in ms)", UI_INPUT_LOCK_MS > 0 && UI_INPUT_LOCK_MS < 200);

    // the press that opened it must not close it: nothing answers inside the input lock
    Test_True("F3a inside the lock: update reports it is still open", Notice_Update(_t0, true));
    Test_False("F3a confirm at once does nothing", Notice_Closing());
    Notice_Update(_t0 + UI_INPUT_LOCK_MS - 1, true);
    Test_False("F3a confirm 1 ms before the lock ends does nothing", Notice_Closing());
    Test_True("F3a still open and blocking", Notice_IsOpen() && UI_IsBlocking());
    Notice_Update(_t0 + UI_INPUT_LOCK_MS + 500, false);
    Test_False("F3a no press after the lock does nothing", Notice_Closing());

    // confirm after the lock dismisses it: it fades out first (still open, still blocking, so the closing press cannot answer what is behind)
    var _tc = _t0 + UI_INPUT_LOCK_MS;
    Notice_Update(_tc, true);
    Test_True("F3a confirm exactly when the lock ends dismisses it", Notice_Closing());
    Test_True("F3a closing: it still blocks the world", Notice_IsOpen() && UI_IsBlocking() && _gs.ui.mode == UI_NOTICE);
    Notice_Update(_tc + 10, true);
    Test_Eq("F3a a second press while closing changes nothing", global.notice_ui.closed_ms, _tc);
    Notice_Update(_tc + UI_PANEL_MS - 1, false);
    Test_True("F3a closing: still up 1 ms before the fade ends", Notice_IsOpen());
    Test_False("F3a closing: no longer takes an answer", Notice_CanAnswer(_tc + UI_PANEL_MS - 1));
    Test_False("F3a the fade ends: update reports it is gone", Notice_Update(_tc + UI_PANEL_MS, false));
    Test_False("F3a gone: not open", Notice_IsOpen());
    Test_Eq("F3a gone: the UI mode is free again", _gs.ui.mode, UI_NONE);
    Test_False("F3a gone: it does not block", UI_IsBlocking());

    // the fade is a pure function of the clock
    Notice_Open(_msg, _t0);
    Test_Eq("F3a alpha is 0 when it opens", Notice_Alpha(_t0), 0);
    Test_Eq("F3a alpha is 1 after the panel time", Notice_Alpha(_t0 + UI_PANEL_MS), 1);
    var _mid = Notice_Alpha(_t0 + UI_PANEL_MS div 2);
    Test_True("F3a alpha is between 0 and 1 half way", _mid > 0 && _mid < 1);
    var _a_before = Notice_Alpha(_tc);   // dismissed half way through the fade-in: the fade-out starts from where the fade-in was
    Notice_Update(_tc, true);
    Test_Eq("F3a the fade-out starts from the alpha it had", Notice_Alpha(_tc), _a_before);
    Test_Eq("F3a alpha is 0 when the fade-out ends", Notice_Alpha(_tc + UI_PANEL_MS), 0);
    Test_True("F3a alpha falls during the fade-out", Notice_Alpha(_tc + UI_PANEL_MS div 2) < _a_before && Notice_Alpha(_tc + UI_PANEL_MS div 2) > 0);

    // a new notice replaces the one that is up and starts its own lock; an interruption (a room change, a battle) removes it at once
    Notice_Open("first", _t0);
    Notice_Open("second", _t0 + 5000);
    Test_Eq("F3a a second notice replaces the first", Notice_Text(), "second");
    Test_False("F3a the replacement starts its own lock", Notice_CanAnswer(_t0 + 5000 + UI_INPUT_LOCK_MS - 1));
    Test_True("F3a ... and answers after it", Notice_CanAnswer(_t0 + 5000 + UI_INPUT_LOCK_MS));
    Notice_Interrupt();
    Test_False("F3a an interruption removes it", Notice_IsOpen());
    Test_Eq("F3a an interruption frees the UI mode", _gs.ui.mode, UI_NONE);

    // the box sits inside the GUI for the three real texts
    var _texts = [Save_LegacyNotice(), Run_ContinueFailText("corrupt"), Run_ContinueFailText("newer")];
    var _mt = Ui_Metrics();
    for (var _i = 0; _i < array_length(_texts); _i++) {
        var _b = Notice_Box(_texts[_i]);
        Test_True("F3a the box " + string(_i) + " is inside the GUI", _b.x >= 0 && _b.y >= 0 && _b.x + _b.w <= _mt.gw && _b.y + _b.h <= _mt.gh);
        Test_True("F3a the box " + string(_i) + " is wide enough for its text", _b.iw > 0 && _b.w > _b.iw);
    }
    Test_True("F3a the footer carries the Confirm prompt", Prompt_HasTokens(Notice_Footer()));

    Test_Eq("F3a the game frame never moved (nothing above used it)", Input_Frame(), _f0);
    global.notice_ui = undefined;
    _gs.ui.mode = _mode0;
}

function Test_Suite_Bed() {
    Test_Eq("D47 a bed's key is its room and place", Bed_Key("rm_floor3", 48, 64), "bed:rm_floor3:48,64");
    var _flags = {};
    var _key = Bed_Key("rm_floor3", 48, 64);
    Test_False("D47 a bed starts unused", Bed_Used(_flags, _key));
    Bed_MarkUsed(_flags, _key);
    Test_True("D47 used once, it is used", Bed_Used(_flags, _key));
    Test_False("D47 another bed is not used", Bed_Used(_flags, Bed_Key("rm_floor3", 80, 64)));

    var _ch = Test_CardPlayer(CLASS_MAGE, [SKILL_FIREBALL, SKILL_ICE_SPEAR], [SKILL_ICE_SPEAR]);
    _ch.hp = 3;
    _ch.mp = 1;
    var _up = Bed_UpgradableSkills(_ch);
    Test_True("D47 only owned skills without their upgrade can be upgraded", array_length(_up) == 1 && _up[0] == SKILL_FIREBALL);
    Test_Eq("D47 a character with no skills has nothing to upgrade", array_length(Bed_UpgradableSkills(Test_CardPlayer(CLASS_MAGE, [], []))), 0);
    Test_Eq("D47 everything already upgraded: nothing", array_length(Bed_UpgradableSkills(Test_CardPlayer(CLASS_MAGE, [SKILL_FIREBALL], [SKILL_FIREBALL]))), 0);

    var _h = Bed_Heal(_ch);
    Test_True("D47 heal gives full HP and MP", _h.hp == _h.max_hp && _h.mp == _h.max_mp);
    Test_True("D47 heal changes a copy", _ch.hp == 3 && _ch.mp == 1);

    var _u = Bed_Upgrade(_ch, SKILL_FIREBALL);
    Test_True("D47 upgrade adds the skill to the upgrades", _u.ok && array_contains(_u.ch.upgrades, SKILL_FIREBALL) && array_contains(_u.ch.upgrades, SKILL_ICE_SPEAR));
    Test_True("D47 upgrade leaves the original alone", !array_contains(_ch.upgrades, SKILL_FIREBALL));
    Test_False("D47 a skill he does not own cannot be upgraded", Bed_Upgrade(_ch, SKILL_WOUND).ok);
    Test_False("D47 an upgraded skill cannot be upgraded twice", Bed_Upgrade(_ch, SKILL_ICE_SPEAR).ok);

    // the whole choice: once per run per bed
    var _f2 = {};
    var _r = Bed_Choose(_ch, _f2, _key, "heal", -1);
    Test_True("D47 choose heal works", _r.ok && _r.ch.hp == _r.ch.max_hp);
    Test_True("D47 the bed is used after a heal", Bed_Used(_f2, _key));
    var _r2 = Bed_Choose(_r.ch, _f2, _key, "heal", -1);
    Test_False("D47 the same bed cannot be used again", _r2.ok);
    var _r3 = Bed_Choose(_ch, _f2, _key, "upgrade", SKILL_FIREBALL);
    Test_False("D47 not even for the other choice", _r3.ok);
    var _f3 = {};
    var _r4 = Bed_Choose(_ch, _f3, _key, "upgrade", SKILL_WOUND);
    Test_False("D47 a refused upgrade does not use the bed up", _r4.ok || Bed_Used(_f3, _key));
    var _r5 = Bed_Choose(_ch, _f3, _key, "upgrade", SKILL_FIREBALL);
    Test_True("D47 a good upgrade works and uses the bed", _r5.ok && Bed_Used(_f3, _key) && array_contains(_r5.ch.upgrades, SKILL_FIREBALL));
    Test_True("D47 an upgrade leaves HP as it was", _r5.ch.hp == 3);
    Test_True("D47 another bed in the same run is still free", Bed_CanUse(_f3, Bed_Key("rm_floor6", 16, 16)));

    // the menu
    var _items = Bed_MenuItems(_ch);
    Test_Eq("D47 bed menu: heal, upgrade, leave", _items[0].id + "," + _items[1].id + "," + _items[2].id, "heal,upgrade,leave");
    Test_True("D47 bed menu: upgrade is live with something to upgrade", _items[1].enabled);
    Test_False("D47 bed menu: upgrade is greyed with nothing to upgrade", Bed_MenuItems(Test_CardPlayer(CLASS_MAGE, [], []))[1].enabled);
    Test_True("D47 bed menu: heal shows what it restores", array_length(_items[0].lines) == 2 && string_length(_items[0].help) > 5);
    var _sub = Bed_UpgradeItems(_ch);
    Test_Eq("D47 upgrade menu: one row per upgradable skill, then Back", array_length(_sub), 2);
    Test_Eq("D47 upgrade menu: the row is the skill", _sub[0].skill_id, SKILL_FIREBALL);
    Test_True("D47 upgrade menu: the details panel shows what changes", string_length(_sub[0].help) > 5 && array_length(_sub[0].lines) >= 1);
}

// ============================================================================================================
// C3 economy (D23 D33 D84 D85 D86 D92): gold, the merchant's stock and prices, throwables, the accessory slot, elites, per-run shuffles.
// Expected values are worked out by hand from the formulas written in the packet (D61 grade numbers, combat-spec section 4 and 10), not read
// from the code. Gold: 10 + 2 per enemy level, x1.2 for rank 2, x3 for a boss, x2 for an elite, +-25% roll. Price = value x 1.5 rounded up,
// sell = half the price. Throwables: thrower stat 12 + level (Knight L1 = 13), slime DEF 7, firebomb power 3 -> formula power 6.
// ============================================================================================================
function Test_EcoSig(_rows) {
    var _s = "";
    for (var _i = 0; _i < array_length(_rows); _i++) _s += string(_rows[_i].kind) + ":" + string(_rows[_i].id) + "x" + string(_rows[_i].qty) + "@" + string(_rows[_i].price) + ",";
    return _s;
}

function Test_EcoFind(_rows, _kind, _id) {
    for (var _i = 0; _i < array_length(_rows); _i++) if (_rows[_i].kind == _kind && _rows[_i].id == _id) return _i;
    return -1;
}

function Test_EcoCountType(_rows, _type) {
    var _n = 0;
    for (var _i = 0; _i < array_length(_rows); _i++) {
        if (_rows[_i].kind != "item") continue;
        var _it = ItemDB_Get(_rows[_i].id);
        if (_type == "throw" && variable_struct_exists(_it, "throwable") && _it.throwable) _n++;
        else if (_type == "gear" && (_it.type == ITEM_WEAPON || _it.type == ITEM_ARMOR)) _n++;
        else if (_type == "accessory" && _it.type == ITEM_ACCESSORY) _n++;
    }
    return _n;
}

function Test_Suite_Economy() {
    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);
    var _had_run = variable_struct_exists(_gs, "run");
    var _old_run = _had_run ? _gs.run : undefined;
    ItemDB_Init(); SkillDB_Init(); StatusDB_Init(); EnemyDB_Init(); Loot_Init(); CardDB_Init();

    // ---- gold (D23): 10 + 2 per level; rank 2 x1.2; boss x3; elite x2 ----
    Test_Eq("C3 gold: level 1 normal enemy = 12", Gold_Base(1, 1, false, false), 12);
    Test_Eq("C3 gold: level 2 = 14", Gold_Base(2, 1, false, false), 14);
    Test_Eq("C3 gold: level 5 = 20", Gold_Base(5, 1, false, false), 20);
    Test_Eq("C3 gold: an elite pays double (level 5: 40)", Gold_Base(5, 1, false, true), 40);
    Test_Eq("C3 gold: rank 2 pays x1.2 (level 5: 24)", Gold_Base(5, 2, false, false), 24);
    Test_Eq("C3 gold: level 8 rank 2 = 31 (31.2 rounded)", Gold_Base(8, 2, false, false), 31);
    Test_Eq("C3 gold: the mini boss (level 8, boss) = 78", Gold_Base(8, 3, true, false), 78);
    Test_Eq("C3 gold: a rank 2 elite at level 8 = 62", Gold_Base(8, 2, false, true), 62);
    var _r12 = Gold_Range(12);
    Test_True("C3 gold: the range of 12 is 9..15 (+-25%)", _r12.lo == 9 && _r12.hi == 15);
    var _r40 = Gold_Range(40);
    Test_True("C3 gold: the range of 40 is 30..50", _r40.lo == 30 && _r40.hi == 50);
    var _r78 = Gold_Range(78);
    Test_True("C3 gold: the range of 78 is 58..98", _r78.lo == 58 && _r78.hi == 98);
    var _grng = Rng_New(7, "gold");
    var _gmin = 999; var _gmax = 0; var _gok = true;
    repeat (300) {
        var _g = Gold_Roll(_grng, 12);
        _gmin = min(_gmin, _g); _gmax = max(_gmax, _g);
        if (_g < 9 || _g > 15) _gok = false;
    }
    Test_True("C3 gold: 300 rolls of base 12 stay inside 9..15", _gok);
    Test_True("C3 gold: the rolls reach both ends of the range", _gmin == 9 && _gmax == 15);
    var _ga = Rng_New(55, "gold"); var _gb = Rng_New(55, "gold");
    Test_Eq("C3 gold: the same stream gives the same roll", Gold_Roll(_ga, 20), Gold_Roll(_gb, 20));
    var _kn = Test_Hero(CLASS_KNIGHT);
    Test_Eq("C3 gold: no bonus = the plain amount", Gold_Scale(12, _kn), 12);
    var _cs = Card_Take(_kn, "pas:coin_sense").ch;
    Test_Eq("C3 gold: Coin Sense is +10% (12 -> 13)", Gold_Scale(12, _cs), 13);
    Test_Eq("C3 gold: Coin Sense on 20 -> 22", Gold_Scale(20, _cs), 22);
    var _lk = variable_clone(_kn);
    _lk.inventory = Inv_Add(_lk.inventory, 46, 1);
    Test_True("C3 accessory: the Lucky Charm equips", Equip_Item(_lk, 46));
    Test_Eq("C3 gold: the Lucky Charm is +15% (12 -> 14)", Gold_Scale(12, _lk), 14);
    var _lk2 = Card_Take(_lk, "pas:coin_sense").ch;
    Test_Eq("C3 gold: Coin Sense and the Lucky Charm add up (12 -> 15)", Gold_Scale(12, _lk2), 15);

    // the run's gold: added, spent, never negative, empty at the start of a run (so a dead run's gold is gone), kept in the history entry
    var _run = Run_Create(31);
    Test_Eq("C3 gold: a new run starts with 0 gold (what a dead run had is lost)", _run.gold, 0);
    Test_True("C3 gold: a new run has an empty shop record", is_struct(_run.shop) && array_length(variable_struct_get_names(_run.shop)) == 0);
    Gold_Add(_run, 40);
    Test_Eq("C3 gold: Gold_Add", _run.gold, 40);
    Test_False("C3 gold: cannot spend more than held", Gold_Spend(_run, 41));
    Test_Eq("C3 gold: a failed spend changes nothing", _run.gold, 40);
    Test_True("C3 gold: spend 15", Gold_Spend(_run, 15));
    Test_Eq("C3 gold: 25 left", _run.gold, 25);
    Gold_Add(_run, -100);
    Test_Eq("C3 gold: a negative add is ignored", _run.gold, 25);
    var _hist = Run_MakeHistoryEntry(_run, _kn, "rm_floor4", "died", "x");
    Test_Eq("C3 gold: the run history keeps the gold the run had", _hist.gold, 25);

    // income against prices (the target: a floor of gold buys one or two things)
    Test_True("C3 balance: two fights of floor 2 (28 gold) buy a Smoke Bomb (21)", Gold_Base(2, 1, false, false) * 2 >= Shop_Price(33));
    Test_True("C3 balance: but not a Smoke Bomb and a Firebomb together (48)", Gold_Base(2, 1, false, false) * 2 < Shop_Price(33) + Shop_Price(30));

    // ---- prices: ceil(value x 1.5); sell = half ----
    Test_Eq("C3 price: HP Potion Lv1 (value 8) = 12", Shop_Price(10), 12);
    Test_Eq("C3 price: HP Potion Lv2 (14) = 21", Shop_Price(14), 21);
    Test_Eq("C3 price: HP Potion Lv3 (25) = 38", Shop_Price(15), 38);
    Test_Eq("C3 price: Antidote (6) = 9", Shop_Price(12), 9);
    Test_Eq("C3 price: Iron Sword (18) = 27", Shop_Price(2), 27);
    Test_Eq("C3 price: Platinum Sword (35) = 53", Shop_Price(3), 53);
    Test_Eq("C3 price: Platinum Armor (70) = 105", Shop_Price(22), 105);
    Test_Eq("C3 price: Firebomb (18) = 27", Shop_Price(30), 27);
    Test_Eq("C3 price: Ice Flask (20) = 30", Shop_Price(32), 30);
    Test_Eq("C3 price: Smoke Bomb (14) = 21", Shop_Price(33), 21);
    Test_Eq("C3 price: Copper Ring (28) = 42", Shop_Price(40), 42);
    Test_Eq("C3 price: Stone Charm (36) = 54", Shop_Price(44), 54);
    Test_Eq("C3 price: Lucky Charm (30) = 45", Shop_Price(46), 45);
    Test_Eq("C3 sell: half of 12 = 6", Shop_SellPrice(10), 6);
    Test_Eq("C3 sell: half of 27 = 13", Shop_SellPrice(2), 13);
    Test_Eq("C3 sell: half of 105 = 52", Shop_SellPrice(22), 52);
    Test_Eq("C3 price: a skill card 80", Shop_CardPrice("skill:" + string(SKILL_FIREBALL)), 80);
    Test_Eq("C3 price: an upgrade card 60", Shop_CardPrice("up:" + string(SKILL_FIREBALL)), 60);
    Test_Eq("C3 price: a passive card 55", Shop_CardPrice("pas:quick_feet"), 55);

    // ---- throwables (D84): the four items and the stack cap ----
    var _tids = [30, 31, 32, 33];
    var _tok = true;
    for (var _t = 0; _t < 4; _t++) {
        var _ti = ItemDB_Get(_tids[_t]);
        if (!Item_IsThrowable(_ti) || !_ti.usable_battle || _ti.type != ITEM_CONSUMABLE) _tok = false;
    }
    Test_True("C3 throwables: ids 30..33 are throwable battle consumables", _tok);
    Test_False("C3 throwables: a potion is not throwable", Item_IsThrowable(ItemDB_Get(10)));
    var _nb = CharacterCreate_Player(CLASS_NOBODY);
    Test_Eq("C3 throwables: a class carries 5 of each", Throw_Cap(_kn), 5);
    Test_Eq("C3 throwables: Nobody carries 8 of each (D84)", Throw_Cap(_nb), 8);
    Test_Eq("C3 throwables: thrower stat is 12 + level (13 at level 1)", Throw_Stat(_kn), 13);
    var _full = variable_clone(_kn);
    _full.inventory = Inv_Add(_full.inventory, 30, 4);
    var _cap1 = Inv_AddCapped(_full, 30, 3);
    Test_Eq("C3 throwables: only 1 of 3 fits under the cap of 5", _cap1.added, 1);
    Test_Eq("C3 throwables: the stack is 5", Inv_Count(_cap1.ch.inventory, 30), 5);
    var _cap2 = Inv_AddCapped(_nb, 30, 10);
    Test_Eq("C3 throwables: Nobody fits 8 of 10", _cap2.added, 8);
    var _cap3 = Inv_AddCapped(_kn, 10, 3);
    Test_Eq("C3 throwables: potions have no cap but 99", _cap3.added, 3);

    // grades: Perfect 1.30, Good 1.10, OK 1.00, Weak 0.75 (D61). Firebomb on a Slime (DEF 7), Knight (13): raw 3.9 -> OK 4, Good 5, Perfect 5, Weak 3
    var _expect = [[QTE_OK, 4], [QTE_GOOD, 5], [QTE_PERFECT, 5], [QTE_WEAK, 3]];
    for (var _g2 = 0; _g2 < 4; _g2++) {
        var _slime = EnemyCreate(ENEMY_SLIME);
        var _th = Test_Hero(CLASS_KNIGHT);
        var _res = Throw_Resolve(30, _th, _slime, _expect[_g2][0]);
        Test_True("C3 firebomb " + _expect[_g2][0] + ": ok", _res.ok);
        Test_Eq("C3 firebomb " + _expect[_g2][0] + ": damage on a Slime", _res.dmg, _expect[_g2][1]);
        Test_Eq("C3 firebomb " + _expect[_g2][0] + ": the Slime lost that much", _slime.hp, 9 - _expect[_g2][1]);
        Test_True("C3 firebomb " + _expect[_g2][0] + ": the Slime burns", Status_Has(_slime, STATUS_BURN));
    }
    var _s1 = EnemyCreate(ENEMY_SLIME);
    Throw_Resolve(30, Test_Hero(CLASS_KNIGHT), _s1, QTE_OK);
    var _bn = Status_Find(_s1, STATUS_BURN);
    Test_True("C3 firebomb OK: burn 4 for 2 turns", _bn.power == 4 && _bn.turns == 2);
    var _s2 = EnemyCreate(ENEMY_SLIME);
    Throw_Resolve(30, Test_Hero(CLASS_KNIGHT), _s2, QTE_PERFECT);
    Test_Eq("C3 firebomb Perfect: burn 5 per turn", Status_Find(_s2, STATUS_BURN).power, 5);
    var _s3 = EnemyCreate(ENEMY_SLIME);
    Throw_Resolve(30, Test_Hero(CLASS_KNIGHT), _s3, QTE_WEAK);
    Test_Eq("C3 firebomb Weak: burn 3 per turn", Status_Find(_s3, STATUS_BURN).power, 3);
    // Nobody throws twice as strong (D111, THROW_NOBODY_MULT 2): damage 8 (6 x 13 / 20 x 2 = 7.8), burn 8
    var _s4 = EnemyCreate(ENEMY_SLIME);
    var _nr = Throw_Resolve(30, CharacterCreate_Player(CLASS_NOBODY), _s4, QTE_OK);
    Test_Eq("C3 firebomb, Nobody: damage 8 instead of 4", _nr.dmg, 8);
    Test_Eq("C3 firebomb, Nobody: burn 8 per turn", Status_Find(_s4, STATUS_BURN).power, 8);

    // poison pot: Perfect 5, Good 4, OK 4, Weak 3 stacks; Nobody 8 at OK, 9 at Perfect (4 x 2, +1)
    var _pexp = [[QTE_PERFECT, 5], [QTE_GOOD, 4], [QTE_OK, 4], [QTE_WEAK, 3]];
    for (var _p2 = 0; _p2 < 4; _p2++) {
        var _sp = EnemyCreate(ENEMY_SLIME);
        Throw_Resolve(31, Test_Hero(CLASS_KNIGHT), _sp, _pexp[_p2][0]);
        Test_Eq("C3 poison pot " + _pexp[_p2][0] + ": stacks", Status_Stacks(_sp, STATUS_POISON), _pexp[_p2][1]);
        Test_Eq("C3 poison pot " + _pexp[_p2][0] + ": no direct damage", _sp.hp, 9);
    }
    var _spn = EnemyCreate(ENEMY_SLIME);
    Throw_Resolve(31, CharacterCreate_Player(CLASS_NOBODY), _spn, QTE_OK);
    Test_Eq("C3 poison pot, Nobody: 8 stacks (4 x 2)", Status_Stacks(_spn, STATUS_POISON), 8);
    var _spn2 = EnemyCreate(ENEMY_SLIME);
    Throw_Resolve(31, CharacterCreate_Player(CLASS_NOBODY), _spn2, QTE_PERFECT);
    Test_Eq("C3 poison pot, Nobody, Perfect: 9 stacks", Status_Stacks(_spn2, STATUS_POISON), 9);

    // ice flask: damage like the firebomb; the stun (a push-back on the timeline) lands on OK or better, never on Weak
    var _si = EnemyCreate(ENEMY_SLIME);
    var _ir = Throw_Resolve(32, Test_Hero(CLASS_KNIGHT), _si, QTE_OK);
    Test_True("C3 ice flask OK: 4 damage and a stun", _ir.dmg == 4 && _ir.stun && Status_Has(_si, STATUS_STUN));
    var _sw = EnemyCreate(ENEMY_SLIME);
    var _iw = Throw_Resolve(32, Test_Hero(CLASS_KNIGHT), _sw, QTE_WEAK);
    Test_True("C3 ice flask Weak: 3 damage, no stun", _iw.dmg == 3 && !_iw.stun && !Status_Has(_sw, STATUS_STUN));
    var _sn = EnemyCreate(ENEMY_SLIME);
    var _inb = Throw_Resolve(32, CharacterCreate_Player(CLASS_NOBODY), _sn, QTE_OK);
    Test_Eq("C3 ice flask, Nobody: 8 damage", _inb.dmg, 8);

    // smoke bomb: Evasion on the thrower for 3 / 3 / 2 / 1 turns; Perfect against a normal enemy is an escape
    var _sexp = [[QTE_PERFECT, 3], [QTE_GOOD, 3], [QTE_OK, 2], [QTE_WEAK, 1]];
    for (var _m2 = 0; _m2 < 4; _m2++) {
        var _me = Test_Hero(CLASS_KNIGHT);
        var _mt = EnemyCreate(ENEMY_SLIME);
        var _mr = Throw_Resolve(33, _me, _mt, _sexp[_m2][0]);
        Test_True("C3 smoke bomb " + _sexp[_m2][0] + ": Evasion on the thrower", Status_Has(_me, STATUS_EVASION));
        Test_Eq("C3 smoke bomb " + _sexp[_m2][0] + ": Evasion turns", Status_Find(_me, STATUS_EVASION).turns, _sexp[_m2][1]);
        Test_Eq("C3 smoke bomb " + _sexp[_m2][0] + ": escape only on Perfect", _mr.escape, _sexp[_m2][0] == QTE_PERFECT);
        Test_Eq("C3 smoke bomb " + _sexp[_m2][0] + ": the enemy is not hurt", _mt.hp, 9);
    }
    var _mb = Throw_Resolve(33, Test_Hero(CLASS_KNIGHT), EnemyCreate(ENEMY_MINI_BOSS), QTE_PERFECT);
    Test_False("C3 smoke bomb: no escape from a boss", _mb.escape);
    var _en = Test_Hero(CLASS_KNIGHT);
    Throw_Resolve(33, _en, EnemyCreate(ENEMY_SLIME), QTE_OK);
    Test_True("C3 smoke bomb: Evasion dodges the next hit (the D80 rule)", Combat_TryDodge(EnemyCreate(ENEMY_SLIME), _en).dodged);
    Test_False("C3 throwing a potion is not a throw", Throw_Resolve(10, Test_Hero(CLASS_KNIGHT), EnemyCreate(ENEMY_SLIME), QTE_OK).ok);

    // ---- accessories (D92): the third slot ----
    var _ac = CharacterCreate_Player(CLASS_KNIGHT);
    Test_Eq("C3 accessory: a new character has an empty accessory slot", _ac.equip.accessory, 0);
    var _acc_ok = true;
    for (var _a = 40; _a <= 46; _a++) {
        var _ai = ItemDB_Get(_a);
        if (_ai.type != ITEM_ACCESSORY || _ai.equip_slot != "accessory" || _ai.max_stack != 1 || _ai.preferred_class != -1) _acc_ok = false;
    }
    Test_True("C3 accessory: ids 40..46 are accessories for every class", _acc_ok);
    var _atk0 = Combat_EffectiveStat(_ac, STAT_ATK);
    Test_False("C3 accessory: cannot equip what is not in the inventory", Equip_CanEquip(_ac, 40).ok);
    _ac.inventory = Inv_Add(_ac.inventory, 40, 1);
    Test_True("C3 accessory: Copper Ring can be equipped", Equip_CanEquip(_ac, 40).ok);
    Test_True("C3 accessory: equip", Equip_Item(_ac, 40));
    Test_Eq("C3 accessory: slot holds the ring", Equip_SlotGet(_ac, "accessory"), 40);
    Test_Eq("C3 accessory: Copper Ring is +1 ATK", Combat_EffectiveStat(_ac, STAT_ATK), _atk0 + 1);
    Test_True("C3 accessory: the menu marks it equipped", Menu_IsEquipped(_ac, 40));
    _ac.inventory = Inv_Add(_ac.inventory, 41, 1);
    Equip_Item(_ac, 41);
    Test_Eq("C3 accessory: one slot, the new ring replaces the old", Equip_SlotGet(_ac, "accessory"), 41);
    Test_Eq("C3 accessory: the old ATK bonus is gone", Combat_EffectiveStat(_ac, STAT_ATK), _atk0);
    Test_Eq("C3 accessory: one copy each", array_length(Inv_Add(Inv_Add([], 41, 1), 41, 1)), 1);
    Test_True("C3 accessory: the body slot is untouched", Equip_SlotGet(_ac, "body") == 0);
    // passives: Stone Charm takes 10% off a hit (10 -> 9), Spring Ring gives +1 MP on every 3rd turn
    var _st = CharacterCreate_Player(CLASS_KNIGHT);
    _st.inventory = Inv_Add(_st.inventory, 44, 1);
    Equip_Item(_st, 44);
    Test_True("C3 accessory: Stone Charm has the Hardened passive", Equip_HasPassive(_st, "hardened"));
    Test_Eq("C3 accessory: Hardened takes 1 off a hit of 10", Equip_PlayerIncomingDamageReduction(_st, 10), 1);
    var _sr = CharacterCreate_Player(CLASS_MAGE);
    _sr.inventory = Inv_Add(_sr.inventory, 45, 1);
    Equip_Item(_sr, 45);
    _sr.mp = 2;
    Equip_PassiveBattleReset(_sr);
    Equip_PassiveOnTurnStart(_sr); Equip_PassiveOnTurnStart(_sr);
    Test_Eq("C3 accessory: Spring Ring gives nothing on turns 1 and 2", _sr.mp, 2);
    Equip_PassiveOnTurnStart(_sr);
    Test_Eq("C3 accessory: Spring Ring gives +1 MP on turn 3", _sr.mp, 3);

    // ---- elites (D86) ----
    var _mods = Elite_Mods();
    Test_True("C3 elite: five modifiers in a fixed order", array_length(_mods) == 5 && _mods[0] == "armored" && _mods[1] == "venomous" && _mods[2] == "swift" && _mods[3] == "brutal" && _mods[4] == "regenerating");
    var _ea = Elite_Apply(EnemyCreate(ENEMY_SLIME), "armored");
    Test_True("C3 elite: Armored is +4 DEF (7 -> 11), tagged", _ea.stats.def == 11 && _ea.elite == "armored" && _ea.is_elite);
    var _es = Elite_Apply(EnemyCreate(ENEMY_SLIME), "swift");
    Test_Eq("C3 elite: Swift is +3 SPD (9 -> 12)", _es.stats.spd, 12);
    var _eb = Elite_Apply(EnemyCreate(ENEMY_SLIME), "brutal");
    Test_Eq("C3 elite: Brutal is +4 ATK (8 -> 12)", _eb.stats.atk, 12);
    var _ev = Elite_Apply(EnemyCreate(ENEMY_SLIME), "venomous");
    Test_True("C3 elite: Venomous leaves the stats alone", _ev.stats.atk == 8 && _ev.stats.def == 7 && _ev.stats.spd == 9);
    var _en0 = Elite_Apply(EnemyCreate(ENEMY_SLIME), "");
    Test_True("C3 elite: no modifier = a normal enemy", !_en0.is_elite && _en0.elite == "");
    Test_True("C3 elite: a name for every modifier", Elite_Name("armored") != "" && Elite_Name("regenerating") != "");
    // venom: 2 poison stacks on a hit that does damage; none on a normal enemy; none when the hit does 0
    var _vk = CharacterCreate_Player(CLASS_KNIGHT);
    Combat_ApplyDamage(_ev, _vk, { power: 6, stat_type: STAT_ATK }, 1, 1, { is_skill: false });
    Test_Eq("C3 elite: a Venomous hit poisons for 2 stacks", Status_Stacks(_vk, STATUS_POISON), 2);
    var _vk2 = CharacterCreate_Player(CLASS_KNIGHT);
    Combat_ApplyDamage(EnemyCreate(ENEMY_SLIME), _vk2, { power: 6, stat_type: STAT_ATK }, 1, 1, { is_skill: false });
    Test_Eq("C3 elite: a normal enemy does not poison", Status_Stacks(_vk2, STATUS_POISON), 0);
    var _vk3 = CharacterCreate_Player(CLASS_KNIGHT);
    Combat_ApplyDamage(_ev, _vk3, { power: 0, stat_type: STAT_ATK }, 1, 1, { is_skill: false });
    Test_Eq("C3 elite: no damage, no poison", Status_Stacks(_vk3, STATUS_POISON), 0);
    // regeneration: 10% of max HP, at least 2, up to the maximum
    Test_Eq("C3 elite: regeneration of a 9 HP enemy = 2", Elite_RegenAmount(9), 2);
    Test_Eq("C3 elite: regeneration of a 40 HP enemy = 4", Elite_RegenAmount(40), 4);
    var _er = Elite_Apply(EnemyCreate(ENEMY_SLIME), "regenerating");
    _er.hp = 3;
    Test_Eq("C3 elite: Regenerating heals 2 at its turn", Elite_Regen(_er), 2);
    Test_Eq("C3 elite: its HP is 5 now", _er.hp, 5);
    _er.hp = _er.max_hp;
    Test_Eq("C3 elite: nothing to heal at full HP", Elite_Regen(_er), 0);
    var _ea2 = Elite_Apply(EnemyCreate(ENEMY_SLIME), "armored");
    _ea2.hp = 3;
    Test_Eq("C3 elite: only Regenerating heals", Elite_Regen(_ea2), 0);

    // rewards: gold from every win, double from an elite plus a guaranteed card pick (the offer itself is C2's)
    _gs.run = Run_Create(808);
    var _rk = Test_Hero(CLASS_KNIGHT);
    var _picks0 = _rk.card_picks;
    var _rw = Battle_GrantRewards(_rk, EnemyCreate(ENEMY_SLIME));
    Test_True("C3 reward: a Slime (level 1) pays 9..15 gold", _rw.gold >= 9 && _rw.gold <= 15);
    Test_Eq("C3 reward: the gold went into the run", _gs.run.gold, _rw.gold);
    Test_False("C3 reward: a normal enemy gives no card pick", _rw.card_pick);
    Test_Eq("C3 reward: no pick owed", _rw.player.card_picks, _picks0);
    _gs.run.gold = 0;
    var _rk2 = Test_Hero(CLASS_KNIGHT);
    var _rw2 = Battle_GrantRewards(_rk2, Elite_Apply(EnemyCreate(ENEMY_SLIME), "brutal"));
    Test_True("C3 reward: an elite Slime pays 18..30 gold (double)", _rw2.gold >= 18 && _rw2.gold <= 30);
    Test_True("C3 reward: an elite gives a card pick", _rw2.card_pick);
    Test_Eq("C3 reward: the pick is owed by the character", _rw2.player.card_picks, _picks0 + 1);
    _gs.run.gold = 0;
    var _rk3 = Test_Hero(CLASS_KNIGHT);
    _rk3 = Card_Take(_rk3, "pas:coin_sense").ch;
    var _rw3 = Battle_GrantRewards(_rk3, EnemyCreate(ENEMY_MINI_BOSS));
    Test_True("C3 reward: the mini boss pays about 78 (58..98), +10% with Coin Sense", _rw3.gold >= 58 && _rw3.gold <= 116);

    // ---- per-run shuffles (D33): enemy pools, placement, elites, chests ----
    var _bad_pool = false;
    for (var _f = 1; _f <= 9; _f++) {
        var _pool = Shuffle_EnemyPool(_f);
        if (array_length(_pool) < 1) _bad_pool = true;
        for (var _pi = 0; _pi < array_length(_pool); _pi++) {
            if (_pool[_pi] == ENEMY_MINI_BOSS || _pool[_pi] == ENEMY_FINAL_BOSS || _pool[_pi] == ENEMY_STRANGER) _bad_pool = true;
        }
    }
    Test_False("C3 shuffle: every floor has a pool; no boss or Stranger is ever in one", _bad_pool);
    Test_Eq("C3 shuffle: floor 1 has only Slimes", array_length(Shuffle_EnemyPool(1)), 1);
    Test_True("C3 shuffle: floor 6 can have Ghost Swords and Mad Whisps", Card_ArrayHas(Shuffle_EnemyPool(6), ENEMY_GHOSTSWORD) && Card_ArrayHas(Shuffle_EnemyPool(6), ENEMY_MADWHISP));
    Test_False("C3 shuffle: floor 7 has no Slimes", Card_ArrayHas(Shuffle_EnemyPool(7), ENEMY_SLIME));
    Test_Eq("C3 shuffle: the cellar rooms between floors have no pool", array_length(Shuffle_EnemyPool(6.5)), 0);
    var _slots = [
        { pid: "e1", enemy_id: ENEMY_DIREWOLF, x: 48, y: 64, fixed: false },
        { pid: "e2", enemy_id: ENEMY_KILLER_PLANT, x: 96, y: 32, fixed: false },
        { pid: "e3", enemy_id: ENEMY_KILLER_PLANT, x: 144, y: 80, fixed: false },
        { pid: "b1", enemy_id: ENEMY_MINI_BOSS, x: 224, y: 32, fixed: true }
    ];
    var _plan_a = Shuffle_RoomPlan(111, "rm_floor4", _slots);
    var _plan_a2 = Shuffle_RoomPlan(111, "rm_floor4", _slots);
    var _plan_b = Shuffle_RoomPlan(222, "rm_floor4", _slots);
    Test_Eq("C3 shuffle: a plan has one entry per slot", array_length(_plan_a), 4);
    Test_Eq("C3 shuffle: the same seed gives the same layout", json_stringify(_plan_a), json_stringify(_plan_a2));
    Test_True("C3 shuffle: another seed gives another layout", json_stringify(_plan_a) != json_stringify(_plan_b));
    var _pl_ok = true; var _xs = 0; var _ys = 0;
    for (var _s5 = 0; _s5 < 3; _s5++) {
        var _pe = _plan_a[_s5];
        var _cfg = EnemyDB_Get(_pe.enemy_id);
        if (!Card_ArrayHas(Shuffle_EnemyPool(4), _pe.enemy_id)) _pl_ok = false;
        if (_pe.level < _cfg.species_min_level || _pe.level > _cfg.species_max_level) _pl_ok = false;
        _xs += _pe.x; _ys += _pe.y;
    }
    Test_True("C3 shuffle: every enemy comes from the floor pool, at a level its species allows", _pl_ok);
    Test_True("C3 shuffle: the same three spots are used, only the order changes", _xs == 48 + 96 + 144 && _ys == 64 + 32 + 80);
    Test_True("C3 shuffle: a fixed slot (the mini boss) keeps its enemy, its place and no modifier", _plan_a[3].enemy_id == ENEMY_MINI_BOSS && _plan_a[3].x == 224 && _plan_a[3].y == 32 && _plan_a[3].elite == "");
    var _same_plan = 0;
    for (var _sd = 1; _sd <= 12; _sd++) { if (json_stringify(Shuffle_RoomPlan(_sd, "rm_floor4", _slots)) == json_stringify(_plan_a)) _same_plan++; }
    Test_True("C3 shuffle: twelve seeds give mostly different layouts", _same_plan <= 2);
    var _any_elite = false;
    for (var _sd2 = 1; _sd2 <= 60 && !_any_elite; _sd2++) {
        var _pp = Shuffle_RoomPlan(_sd2, "rm_floor4", _slots);
        for (var _q = 0; _q < 3; _q++) { if (_pp[_q].elite != "" && Card_ArrayHas(Elite_Mods(), _pp[_q].elite)) _any_elite = true; }
    }
    Test_True("C3 shuffle: elites do show up in plans, with a real modifier", _any_elite);
    Test_Eq("C3 shuffle: the cellar between floors 6 and 7 is not shuffled", array_length(Shuffle_RoomPlan(5, "rm_floor6_5", _slots)), 0);

    // chest contents come from the seed and the chest, not from how many other things were rolled before
    var _own = Test_Hero(CLASS_KNIGHT);
    var _pid1 = "auto:rm_floor3:obj_chest_lv2:240:112#1";
    var _c1 = Shuffle_ChestLoot(900, "rm_floor3", _pid1, 2, "chest_basic", _own);
    RunRng_Float("loot"); RunRng_Float("loot"); RunRng_Float("loot");
    var _c2 = Shuffle_ChestLoot(900, "rm_floor3", _pid1, 2, "chest_basic", _own);
    Test_Eq("C3 chest: same seed + same chest = same contents, whatever else was rolled", json_stringify(_c1), json_stringify(_c2));
    var _diff = 0;
    for (var _sd3 = 901; _sd3 <= 912; _sd3++) { if (json_stringify(Shuffle_ChestLoot(_sd3, "rm_floor3", _pid1, 2, "chest_basic", _own)) != json_stringify(_c1)) _diff++; }
    Test_True("C3 chest: other seeds give other contents (at least 6 of 12)", _diff >= 6);
    var _more = 0;
    for (var _ch2 = 0; _ch2 < 12; _ch2++) { if (json_stringify(Shuffle_ChestLoot(900, "rm_floor3", "x" + string(_ch2), 2, "chest_basic", _own)) != json_stringify(_c1)) _more++; }
    Test_True("C3 chest: another chest in the same run has its own contents", _more >= 6);
    Test_Eq("C3 loot: floors 1-3 are band 1", Loot_FloorBand(3), 1);
    Test_Eq("C3 loot: floors 4-6 are band 2", Loot_FloorBand(4) * 10 + Loot_FloorBand(6), 22);
    Test_Eq("C3 loot: floors 7-9 are band 3", Loot_FloorBand(7) * 10 + Loot_FloorBand(9), 33);
    var _fx1 = Loot_FloorExtras(500, 2);
    var _fx2 = Loot_FloorExtras(500, 3);
    Test_Eq("C3 loot: a floor band adds one throwable and one accessory to the chests", array_length(_fx1), 2);
    Test_Eq("C3 loot: floors of one band share their extras", json_stringify(_fx1), json_stringify(_fx2));
    var _fx_ok = true;
    for (var _xi = 0; _xi < 2; _xi++) {
        var _xit = ItemDB_Get(_fx1[_xi].item_id);
        if (_xi == 0 && !Item_IsThrowable(_xit)) _fx_ok = false;
        if (_xi == 1 && _xit.type != ITEM_ACCESSORY) _fx_ok = false;
    }
    Test_True("C3 loot: the extras are a throwable then an accessory", _fx_ok);
    var _fxd = 0;
    for (var _sd4 = 501; _sd4 <= 520; _sd4++) { if (json_stringify(Loot_FloorExtras(_sd4, 2)) != json_stringify(_fx1)) _fxd++; }
    Test_True("C3 loot: the extras change with the seed", _fxd >= 8);

    // ---- the merchant's places and stock ----
    var _sp2 = Merchant_SpotFor(rm_floor2);
    var _sp5 = Merchant_SpotFor(rm_floor5);
    var _sp8 = Merchant_SpotFor(rm_floor8);
    Test_True("C3 merchant: after floors 2, 5 and 8, shop 0, 1, 2", is_struct(_sp2) && is_struct(_sp5) && is_struct(_sp8) && _sp2.shop == 0 && _sp5.shop == 1 && _sp8.shop == 2);
    Test_True("C3 merchant: other rooms have none", is_undefined(Merchant_SpotFor(rm_floor3)) && is_undefined(Merchant_SpotFor(rm_floor1)) && is_undefined(Merchant_SpotFor(rm_floor6_5)));
    Test_True("C3 merchant: spots sit on the 16 px grid", _sp2.x mod 16 == 0 && _sp2.y mod 16 == 0 && _sp5.x mod 16 == 0 && _sp8.y mod 16 == 0);

    // ---- the merchant's pulsing gold glow (D113): alpha 0.35..1.0, a 1.2 s cosine pulse starting at its brightest ----
    Test_True("D113 glow: at 0 ms it is at full strength", abs(Merchant_GlowAlpha(0) - 1.0) < 0.0001);
    Test_True("D113 glow: half a period later (600 ms) it is at its dimmest, 0.35", abs(Merchant_GlowAlpha(600) - 0.35) < 0.0001);
    Test_True("D113 glow: a quarter period (300 ms) is the middle, 0.675", abs(Merchant_GlowAlpha(300) - 0.675) < 0.0001);
    Test_True("D113 glow: it repeats every 1200 ms", abs(Merchant_GlowAlpha(300) - Merchant_GlowAlpha(300 + 1200 * 7)) < 0.0001);
    var _glow_ok = true;
    for (var _gm = 0; _gm < 3600; _gm += 37) { var _ga2 = Merchant_GlowAlpha(_gm); if (_ga2 < 0.35 - 0.0001 || _ga2 > 1.0 + 0.0001) _glow_ok = false; }
    Test_True("D113 glow: every alpha stays inside 0.35 to 1.0", _glow_ok);
    // the owner imported candidate A as "spr_merchant_idle_strip" (2026-10-16); the lookup takes either name
    Test_True("D113 glow: the merchant sprite is looked up by its imported name", Merchant_SpriteName() == "spr_merchant_idle" || Merchant_SpriteName() == "spr_merchant_idle_strip");
    var _msp = asset_get_index(Merchant_SpriteName());
    Test_True("D113 import: the merchant sprite exists with its 2 idle frames", _msp != -1 && sprite_get_number(_msp) == 2);
    var _icats = ["status", "skill", "throwable", "passive", "accessory", "misc", "skill_up"];
    var _iframes = [17, 15, 4, 8, 2, 1, 15];
    for (var _ic = 0; _ic < array_length(_icats); _ic++) {
        var _isp = Icon_StripSprite(_icats[_ic]);
        Test_True("D94 import: icon strip '" + _icats[_ic] + "' is found with " + string(_iframes[_ic]) + " frames of 16x16", _isp != -1 && sprite_get_number(_isp) == _iframes[_ic] && sprite_get_width(_isp) == 16 && sprite_get_height(_isp) == 16);
    }

    var _kz = Test_Hero(CLASS_KNIGHT);
    var _ssa = Shop_StockGenerate(4321, 0, _kz);
    var _ssb = Shop_StockGenerate(4321, 0, _kz);
    Test_Eq("C3 shop: the same seed and shop = the same stock", Test_EcoSig(_ssa), Test_EcoSig(_ssb));
    var _ss_diff = 0;
    for (var _sd5 = 4400; _sd5 < 4410; _sd5++) { if (Test_EcoSig(Shop_StockGenerate(_sd5, 0, _kz)) != Test_EcoSig(_ssa)) _ss_diff++; }
    Test_True("C3 shop: other seeds stock other things (9 of 10 differ)", _ss_diff >= 9);
    Test_True("C3 shop: the three shops of one run differ", Test_EcoSig(Shop_StockGenerate(4321, 1, _kz)) != Test_EcoSig(_ssa) && Test_EcoSig(Shop_StockGenerate(4321, 2, _kz)) != Test_EcoSig(Shop_StockGenerate(4321, 1, _kz)));
    Test_True("C3 shop: 8 to 10 rows", array_length(_ssa) >= 8 && array_length(_ssa) <= 10);
    var _hp_row = -1;
    for (var _hi = 0; _hi < array_length(_ssa); _hi++) { if (_ssa[_hi].kind == "item" && _ssa[_hi].id == 10) _hp_row = _hi; }
    Test_True("C3 shop: shop 0 always sells HP Potion Lv1, three of them", _hp_row >= 0 && _ssa[_hp_row].qty == 3);
    Test_True("C3 shop: shop 1 sells HP Potion Lv2 and shop 2 Lv3", Test_EcoFind(Shop_StockGenerate(4321, 1, _kz), "item", 14) >= 0 && Test_EcoFind(Shop_StockGenerate(4321, 2, _kz), "item", 15) >= 0);
    Test_Eq("C3 shop: two throwables", Test_EcoCountType(_ssa, "throw"), 2);
    Test_Eq("C3 shop: two pieces of gear", Test_EcoCountType(_ssa, "gear"), 2);
    Test_Eq("C3 shop: one accessory", Test_EcoCountType(_ssa, "accessory"), 1);
    var _ncards = 0;
    for (var _ci = 0; _ci < array_length(_ssa); _ci++) { if (_ssa[_ci].kind == "card") _ncards++; }
    Test_True("C3 shop: one or two cards", _ncards >= 1 && _ncards <= 2);
    var _price_ok = true; var _qty_ok = true; var _gear_ok = true; var _card_ok = true;
    for (var _ri = 0; _ri < array_length(_ssa); _ri++) {
        var _row = _ssa[_ri];
        if (_row.qty < 1) _qty_ok = false;
        if (_row.kind == "item") {
            if (_row.price != Shop_Price(_row.id)) _price_ok = false;
            var _gi = ItemDB_Get(_row.id);
            if (_gi.type == ITEM_WEAPON || _gi.type == ITEM_ARMOR) {
                if (!Loot_ItemClassAllowed(_gi, CLASS_KNIGHT) || _gi.value > 20 || Inv_Has(_kz.inventory, _gi.id, 1)) _gear_ok = false;
            }
        } else {
            var _cd = CardDB_Get(_row.id);
            if (!is_struct(_cd) || _row.price != Shop_CardPrice(_row.id) || !Card_Eligible(_kz, _cd) || _cd.kind == "fallback") _card_ok = false;
        }
    }
    Test_True("C3 shop: every price is the table price", _price_ok);
    Test_True("C3 shop: nothing is sold out at the start", _qty_ok);
    Test_True("C3 shop: shop 0 gear fits the class, is worth 20 or less and is not owned already", _gear_ok);
    Test_True("C3 shop: cards are real cards this character could take (no fallbacks)", _card_ok);
    var _mg = CharacterCreate_Player(CLASS_MAGE);
    var _mg_ok = true;
    var _mst = Shop_StockGenerate(4321, 1, _mg);
    for (var _mi = 0; _mi < array_length(_mst); _mi++) {
        if (_mst[_mi].kind != "item") continue;
        var _mgi = ItemDB_Get(_mst[_mi].id);
        if ((_mgi.type == ITEM_WEAPON || _mgi.type == ITEM_ARMOR) && !Loot_ItemClassAllowed(_mgi, CLASS_MAGE)) _mg_ok = false;
    }
    Test_True("C3 shop: a Mage is sold Mage gear only", _mg_ok);
    var _nst = Shop_StockGenerate(4321, 1, _nb);
    Test_Eq("C3 shop: Nobody is sold no gear (it cannot use any)", Test_EcoCountType(_nst, "gear"), 0);
    Test_True("C3 shop: Nobody gets more throwables instead", Test_EcoCountType(_nst, "throw") >= 4);
    var _skills_full = CharacterCreate_Player(CLASS_KNIGHT);
    _skills_full.skills = [SKILL_WOUND, SKILL_HILT_BASH, SKILL_MUSCLE_UP];
    var _no_skill_card = true;
    for (var _sd6 = 5000; _sd6 < 5030; _sd6++) {
        var _fst = Shop_StockGenerate(_sd6, 1, _skills_full);
        for (var _fi = 0; _fi < array_length(_fst); _fi++) { if (_fst[_fi].kind == "card" && CardDB_Get(_fst[_fi].id).kind == "skill") _no_skill_card = false; }
    }
    Test_True("C3 shop: with 3 skills held no skill card is sold (there is no swap screen in the shop)", _no_skill_card);

    // buying and selling
    var _brun = Run_Create(4321);
    _brun.gold = 100;
    var _bch = Test_Hero(CLASS_KNIGHT);
    var _stock = Shop_StockGenerate(4321, 0, _bch);
    var _hpr = Test_EcoFind(_stock, "item", 10);
    var _hp0 = Inv_Count(_bch.inventory, 10);
    var _b1 = Shop_Buy(_bch, _brun, _stock[_hpr]);
    Test_True("C3 buy: a potion for 12 gold", _b1.ok);
    Test_Eq("C3 buy: gold 100 -> 88", _brun.gold, 88);
    Test_Eq("C3 buy: the potion is in the inventory", Inv_Count(_b1.ch.inventory, 10), _hp0 + 1);
    Test_Eq("C3 buy: stock 3 -> 2", _stock[_hpr].qty, 2);
    _brun.gold = 5;
    var _b2 = Shop_Buy(_bch, _brun, _stock[_hpr]);
    Test_False("C3 buy: not enough gold", _b2.ok);
    Test_Eq("C3 buy: the reason is gold", _b2.reason, "gold");
    Test_Eq("C3 buy: nothing changed (gold)", _brun.gold, 5);
    Test_Eq("C3 buy: nothing changed (stock)", _stock[_hpr].qty, 2);
    _brun.gold = 100;
    _stock[_hpr].qty = 0;
    Test_Eq("C3 buy: sold out", Shop_Buy(_bch, _brun, _stock[_hpr]).reason, "sold_out");
    var _tr = -1;
    for (var _ti2 = 0; _ti2 < array_length(_stock); _ti2++) { if (_stock[_ti2].kind == "item" && Item_IsThrowable(ItemDB_Get(_stock[_ti2].id))) _tr = _ti2; }
    var _tch = variable_clone(_bch);
    _tch.inventory = Inv_Add(_tch.inventory, _stock[_tr].id, 5);
    Test_Eq("C3 buy: a throwable at the cap of 5 is refused", Shop_Buy(_tch, _brun, _stock[_tr]).reason, "full");
    Test_Eq("C3 buy: and costs nothing", _brun.gold, 100);
    var _gr = -1;
    for (var _gi2 = 0; _gi2 < array_length(_stock); _gi2++) { if (_stock[_gi2].kind == "item" && (ItemDB_Get(_stock[_gi2].id).type == ITEM_WEAPON || ItemDB_Get(_stock[_gi2].id).type == ITEM_ARMOR)) _gr = _gi2; }
    var _gch = variable_clone(_bch);
    _gch.inventory = Inv_Add(_gch.inventory, _stock[_gr].id, 1);
    Test_Eq("C3 buy: gear that is already owned is refused", Shop_Buy(_gch, _brun, _stock[_gr]).reason, "owned");
    var _cr = -1;
    for (var _cj = 0; _cj < array_length(_stock); _cj++) { if (_stock[_cj].kind == "card") _cr = _cj; }
    _brun.gold = 100;
    var _cch = variable_clone(_bch);
    var _cb = Shop_Buy(_cch, _brun, _stock[_cr]);
    Test_True("C3 buy: a card can be bought", _cb.ok);
    Test_Eq("C3 buy: it costs the card price", _brun.gold, 100 - Shop_CardPrice(_stock[_cr].id));
    var _card_after = CardDB_Get(_stock[_cr].id);
    var _taken = (_card_after.kind == "passive") ? Card_HasPassive(_cb.ch, _card_after.id) : ((_card_after.kind == "upgrade") ? Card_ArrayHas(_cb.ch.upgrades, _card_after.skill_id) : Card_ArrayHas(_cb.ch.skills, _card_after.skill_id));
    Test_True("C3 buy: the card is on the character", _taken);
    Test_Eq("C3 buy: and gone from the stock", _stock[_cr].qty, 0);
    var _fullskills = variable_clone(_skills_full);
    var _skill_row = { kind: "card", id: Card_SkillId(SKILL_REV_UP), qty: 1, price: 80 };
    _brun.gold = 200;
    Test_Eq("C3 buy: a skill card is refused when the 3 slots are full", Shop_Buy(_fullskills, _brun, _skill_row).reason, "slots");
    // sell: half the price; not equipped; not something you do not have
    var _sch = Test_Hero(CLASS_KNIGHT);
    _sch.inventory = Inv_Add(_sch.inventory, 2, 1);
    _brun.gold = 10;
    var _s6 = Shop_Sell(_sch, _brun, 2);
    Test_True("C3 sell: an Iron Sword is sold", _s6.ok);
    Test_Eq("C3 sell: for 13 gold", _brun.gold, 23);
    Test_False("C3 sell: it left the inventory", Inv_Has(_s6.ch.inventory, 2, 1));
    _sch.inventory = Inv_Add(_sch.inventory, 2, 1);
    Equip_Item(_sch, 2);
    Test_Eq("C3 sell: an equipped weapon cannot be sold", Shop_Sell(_sch, _brun, 2).reason, "equipped");
    Test_Eq("C3 sell: something you do not have cannot be sold", Shop_Sell(_sch, _brun, 3).reason, "none");
    var _p5 = variable_clone(_sch);
    var _pn = Inv_Count(_p5.inventory, 10);
    var _s7 = Shop_Sell(_p5, _brun, 10);
    Test_True("C3 sell: one potion for 6", _s7.ok && _brun.gold == 29 && Inv_Count(_s7.ch.inventory, 10) == _pn - 1);

    // the run keeps what was bought: the stock is made once and saved with the run
    _gs.run = Run_Create(6060);
    _gs.player_ch = Test_Hero(CLASS_KNIGHT);
    var _rs1 = Shop_RunStock(_gs.run, 0, _gs.player_ch);
    _rs1[0].qty = 1;
    var _rs2 = Shop_RunStock(_gs.run, 0, CharacterCreate_Player(CLASS_MAGE));
    Test_Eq("C3 run shop: the stock is made once, later visits see the same rows", Test_EcoSig(_rs1), Test_EcoSig(_rs2));
    Test_Eq("C3 run shop: what was bought stays bought", _rs2[0].qty, 1);
    var _back = json_parse(json_stringify(_gs.run.shop));
    Test_Eq("C3 run shop: survives a JSON round trip (the run save)", Test_EcoSig(variable_struct_get(_back, "s0")), Test_EcoSig(_rs1));
    var _raw = RunSave_Build();
    Test_True("C3 run shop: the run save carries it", variable_struct_exists(_raw, "shop") && variable_struct_exists(_raw.shop, "s0"));
    var _old_cp = _gs.checkpoint; var _old_persist = _gs.persist; var _old_flags = _gs.flags; var _old_sel = _gs.selected_class;
    _gs.run = Run_Create(1);
    RunSave_ApplyState(json_parse(json_stringify(_raw)));
    Test_Eq("C3 run shop: a loaded run has its shop back", Test_EcoSig(variable_struct_get(_gs.run.shop, "s0")), Test_EcoSig(_rs1));
    _gs.checkpoint = _old_cp; _gs.persist = _old_persist; _gs.flags = _old_flags; _gs.selected_class = _old_sel;

    // ---- text from the data (D100) ----
    var _fb = ItemDB_Get(30);
    var _fl = Item_NumberLines(_fb, _kn);
    Test_True("C3 text: the Firebomb shows its power 3 and its burn 4 x 2", array_length(_fl) >= 2 && _fl[0].value == "3" && _fl[1].value == "4 x 2");
    Test_Eq("C3 text: the Poison Pot shows its 4 stacks", Item_NumberLines(ItemDB_Get(31), _kn)[0].value, "4");
    Test_Eq("C3 text: Nobody sees 8 stacks (x2)", Item_NumberLines(ItemDB_Get(31), _nb)[0].value, "8");
    Test_True("C3 text: the sentence of every throwable has its numbers", string_pos("3", Item_Sentence(_fb)) > 0 && string_pos("4", Item_Sentence(ItemDB_Get(31))) > 0 && string_pos("2", Item_Sentence(ItemDB_Get(33))) > 0);
    Test_True("C3 text: an accessory has a sentence and a line", string_length(Item_Sentence(ItemDB_Get(44))) > 8 && array_length(Item_NumberLines(ItemDB_Get(44), _kn)) >= 1);
    Test_True("C3 text: a stat ring says +1", string_pos("1", Item_Sentence(ItemDB_Get(40))) > 0 && Item_NumberLines(ItemDB_Get(40), _kn)[0].value == "+1");
    Test_True("C3 text: a potion lists its numbers", Item_NumberLines(ItemDB_Get(10), _kn)[0].value == "5-10");
    var _row_it = ShopUi_ItemFor({ kind: "item", id: 30, qty: 2, price: 27 }, _kn, 100);
    Test_True("C3 text: a shop row shows the price and can be bought when it can be paid", _row_it.value == "27" && _row_it.can_buy && _row_it.enabled && string_length(_row_it.help) > 8 && array_length(_row_it.lines) >= 2);
    var _row_no = ShopUi_ItemFor({ kind: "item", id: 30, qty: 2, price: 27 }, _kn, 10);
    Test_True("C3 text: a row you cannot pay for can still be looked at but not bought", !_row_no.can_buy && _row_no.enabled && _row_no.dim);
    var _row_card = ShopUi_ItemFor({ kind: "card", id: "pas:coin_sense", qty: 1, price: 55 }, _kn, 100);
    Test_True("C3 text: a card row names the card and carries its numbers", _row_card.label == Card_Name(CardDB_Get("pas:coin_sense")) && array_length(_row_card.lines) >= 1);

    if (_had_run) _gs.run = _old_run; else variable_struct_remove(_gs, "run");
    Test_PassiveRuntimeChecks();
    Test_Hunt1Checks();
}

// D108 F4b: the passive runtime struct after Equip_PassiveRuntimeEnsure and after Equip_PassiveBattleReset (characterization: one constructor).
function Test_PassiveRuntimeFields(_tag, _rt) {
    Test_True(_tag + " is a struct", is_struct(_rt));
    Test_Eq(_tag + " has nine fields", array_length(variable_struct_get_names(_rt)), 9);
    Test_Eq(_tag + " battle_turn", _rt.battle_turn, 0);
    Test_Eq(_tag + " first_hit_done", _rt.first_hit_done, false);
    Test_Eq(_tag + " steady_strike_turn", _rt.steady_strike_turn, -1);
    Test_Eq(_tag + " aim_assist_turn", _rt.aim_assist_turn, -1);
    Test_Eq(_tag + " pinning_cooldown", _rt.pinning_cooldown, 0);
    Test_Eq(_tag + " first_impact_used", _rt.first_impact_used, false);
    Test_Eq(_tag + " brace_guard_ready", _rt.brace_guard_ready, false);
    Test_Eq(_tag + " brace_cooldown", _rt.brace_cooldown, 0);
    Test_Eq(_tag + " mirror_used", _rt.mirror_used, false);
}

// hunt1: three bugs from the read-only hunt. Expected values come from DECISIONS.md (D5, D80, D84), not from the code.
function Test_Hunt1Bc(_p, _e) {
    return {
        p: _p, e: _e, ai: EnemyAI_StateNew(),
        tl: Turn_New([Turn_Fighter(TL_PLAYER, 10), Turn_Fighter(TL_ENEMY, 10)]),
        tl_who: TL_PLAYER, tl_prev_who: TL_PLAYER, turn_log: [], turn: TURN_PLAYER, battle_over: false
    };
}

function Test_Hunt1Checks() {
    var _gs = GameState_Get();
    var _had_run = variable_struct_exists(_gs, "run");
    var _old_run = _had_run ? _gs.run : undefined;
    ItemDB_Init(); SkillDB_Init(); StatusDB_Init(); EnemyDB_Init(); Loot_Init(); CardDB_Init();

    // 1. a thief's stolen items come back when the thief dies, and the victory lines list drops and recovered items
    _gs.run = Run_Create(4242);
    _gs.run.drop_dry = 10;   // R1: the drop chance is 100% after enough dry fights
    var _kn = Test_Hero(CLASS_KNIGHT);
    var _thief = EnemyCreate(ENEMY_SLIME);
    _thief.stolen_items = [{ id: 31, qty: 1 }];   // as Skill_StealRecord stores them
    var _before = Inv_Count(_kn.inventory, 31);
    var _rw = Battle_GrantRewards(_kn, _thief);
    Test_True("hunt1 stolen item comes back into the inventory", Inv_Count(_rw.player.inventory, 31) >= _before + 1);
    var _got31 = false;
    var _all_item_id = true;
    for (var _i = 0; _i < array_length(_rw.loot); _i++) {
        if (!variable_struct_exists(_rw.loot[_i], "item_id")) _all_item_id = false;
        else if (_rw.loot[_i].item_id == 31 && _rw.loot[_i].qty >= 1) _got31 = true;
    }
    Test_True("hunt1 rewards.loot lists the recovered item under item_id", _got31);
    Test_True("hunt1 every rewards.loot entry uses the item_id key", _all_item_id && array_length(_rw.loot) >= 1);
    Test_Eq("hunt1 the thief's stolen list is emptied", array_length(_thief.stolen_items), 0);
    var _lines = Battle_BuildVictoryDialogueLines(_thief, _rw, _rw.player);
    var _has_loot_line = false;
    for (var _j = 0; _j < array_length(_lines); _j++) {
        if (is_struct(_lines[_j]) && string_pos("x", _lines[_j].text) > 0 && string_pos(string(ItemDB_Get(31).name), _lines[_j].text) > 0) _has_loot_line = true;
    }
    Test_True("hunt1 the victory lines name the recovered Poison Pot", _has_loot_line);

    // a normal drop (no thief) is listed too: the drop is rolled to 100% here
    _gs.run.drop_dry = 10;
    var _kn2 = Test_Hero(CLASS_KNIGHT);
    var _rw2 = Battle_GrantRewards(_kn2, EnemyCreate(ENEMY_SLIME));
    Test_True("hunt1 a normal drop appears in rewards.loot", array_length(_rw2.loot) >= 1 && variable_struct_exists(_rw2.loot[0], "item_id"));
    var _lines2 = Battle_BuildVictoryDialogueLines(EnemyCreate(ENEMY_SLIME), _rw2, _rw2.player);
    var _n_loot_lines = 0;
    for (var _k = 0; _k < array_length(_lines2); _k++) if (is_struct(_lines2[_k]) && string_pos(Loc_T("combat.msg.loot_prefix", "Loot: "), _lines2[_k].text) == 1) _n_loot_lines++;
    Test_True("hunt1 the victory message lists the drop (a Loot: line)", _n_loot_lines >= 1);

    // 2. Evasion put on by the player's own action survives that action's end-of-turn tick (D80), at any grade (D5)
    var _grades = [QTE_PERFECT, QTE_GOOD, QTE_OK, QTE_WEAK];
    for (var _g = 0; _g < 4; _g++) {
        var _pe = Test_Hero(CLASS_KNIGHT);
        var _ee = EnemyCreate(ENEMY_SLIME);
        Throw_Resolve(33, _pe, _ee, _grades[_g]);
        var _bc = Test_Hunt1Bc(_pe, _ee);
        Battle_PlayerFinalizeTurn(_bc, _pe, _ee);
        Test_True("hunt1 Smoke Bomb " + _grades[_g] + ": Evasion survives the end of the throw turn", Status_Has(_bc.p, STATUS_EVASION));
        var _dg = Combat_TryDodge(_bc.e, _bc.p);
        Test_True("hunt1 Smoke Bomb " + _grades[_g] + ": the next enemy attack is dodged", _dg.dodged);
        Test_False("hunt1 Smoke Bomb " + _grades[_g] + ": the dodge uses the Evasion up", Status_Has(_dg.defender, STATUS_EVASION));
    }
    for (var _g2 = 0; _g2 < 4; _g2++) {
        var _pa = Test_Hero(CLASS_ARCHER);
        _pa.mp = _pa.max_mp;
        var _ea = EnemyCreate(ENEMY_SLIME);
        var _sr = Skill_Use(_pa, _pa, SKILL_EVASION, Qte_GradeMult(_grades[_g2]));
        Test_True("hunt1 Archer Evasion " + _grades[_g2] + ": cast", _sr.ok && Status_Has(_pa, STATUS_EVASION));
        var _bca = Test_Hunt1Bc(_pa, _ea);
        Battle_PlayerFinalizeTurn(_bca, _pa, _ea);
        Test_True("hunt1 Archer Evasion " + _grades[_g2] + ": survives the end of the cast turn", Status_Has(_bca.p, STATUS_EVASION));
        var _dga = Combat_TryDodge(_bca.e, _bca.p);
        Test_True("hunt1 Archer Evasion " + _grades[_g2] + ": the next enemy attack is dodged", _dga.dodged);
        Test_False("hunt1 Archer Evasion " + _grades[_g2] + ": the dodge uses the Evasion up", Status_Has(_dga.defender, STATUS_EVASION));
    }
    // it still wears off: it is not forever (the skill gives 6 turns, so the 6th later tick removes it)
    var _pl = Test_Hero(CLASS_ARCHER);
    _pl.mp = _pl.max_mp;
    Skill_Use(_pl, _pl, SKILL_EVASION, 1);
    for (var _t = 0; _t < 6; _t++) _pl = Status_Tick(_pl);   // the first tick only clears the fresh flag
    Test_True("hunt1 Archer Evasion is still there after 5 counted turns", Status_Has(_pl, STATUS_EVASION));
    _pl = Status_Tick(_pl);
    Test_False("hunt1 Archer Evasion wears off after its 6 turns", Status_Has(_pl, STATUS_EVASION));

    // 3. D84: 5 of a throwable for a class, 8 only for Nobody; picking a class trims the stack
    var _nb = CharacterCreate_Player(CLASS_NOBODY);
    _nb.inventory = Inv_Add(_nb.inventory, 30, 8);
    _nb.inventory = Inv_Add(_nb.inventory, 33, 3);
    Test_Eq("hunt1 Nobody carries 8 firebombs", Inv_Count(_nb.inventory, 30), 8);
    var _classes = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];
    for (var _c = 0; _c < 3; _c++) {
        var _picked = Card_ClassCharacter(_nb, _classes[_c]);
        Test_Eq("hunt1 class " + string(_classes[_c]) + " keeps at most 5 firebombs", Inv_Count(_picked.inventory, 30), 5);
        Test_Eq("hunt1 class " + string(_classes[_c]) + " keeps the 3 smoke bombs it can hold", Inv_Count(_picked.inventory, 33), 3);
    }
    Test_Eq("hunt1 the old Nobody inventory is untouched by the pick", Inv_Count(_nb.inventory, 30), 8);

    if (_had_run) _gs.run = _old_run; else variable_struct_remove(_gs, "run");
}

function Test_PassiveRuntimeChecks() {
    var _c = { name: "dummy" };
    Test_PassiveRuntimeFields("F4b Ensure on a fresh character", Equip_PassiveRuntimeEnsure(_c));
    Test_True("F4b Ensure stores the struct on the character", variable_struct_exists(_c, "passive_runtime"));
    _c.passive_runtime.battle_turn = 4;
    _c.passive_runtime.mirror_used = true;
    Test_Eq("F4b Ensure keeps the existing struct", Equip_PassiveRuntimeEnsure(_c).battle_turn, 4);
    _c.passive_runtime = 7;
    Test_PassiveRuntimeFields("F4b Ensure replaces a non-struct", Equip_PassiveRuntimeEnsure(_c));
    Test_Eq("F4b Ensure on a non-struct gives an empty struct", array_length(variable_struct_get_names(Equip_PassiveRuntimeEnsure(undefined))), 0);

    _c.passive_runtime.battle_turn = 9;
    _c.passive_runtime.pinning_cooldown = 2;
    var _r = Equip_PassiveBattleReset(_c);
    Test_True("F4b BattleReset returns the same character", _r == _c);
    Test_PassiveRuntimeFields("F4b BattleReset", _c.passive_runtime);
    var _first = _c.passive_runtime;
    Equip_PassiveBattleReset(_c);
    Test_True("F4b BattleReset builds a new struct each time", _c.passive_runtime != _first);
    var _d = { name: "other" };
    Equip_PassiveRuntimeEnsure(_d);
    Equip_PassiveBattleReset(_c);
    _d.passive_runtime.battle_turn = 3;
    Test_Eq("F4b two characters never share a runtime struct", _c.passive_runtime.battle_turn, 0);
    Test_Eq("F4b BattleReset on a non-struct returns it", Equip_PassiveBattleReset(undefined), undefined);
}

// D111 (owner-approved balance, balance-report.md E1-1 .. E1-6). Expected values are the numbers of DECISIONS.md D111, not read back from the code.
function Test_D111_EnemyHpAt(_name, _enemy_id, _level, _mod, _want_plain, _want_elite) {
    var _gs = GameState_Get();
    var _lv0 = _gs.battle.enemy_level;
    _gs.battle.enemy_level = _level;
    var _plain = EnemyCreate(_enemy_id);
    var _elite = Elite_Apply(EnemyCreate(_enemy_id), _mod);
    _gs.battle.enemy_level = _lv0;
    Test_Eq(_name + " plain max HP", _plain.max_hp, _want_plain);
    Test_Eq(_name + " elite max HP", _elite.max_hp, _want_elite);
    Test_Eq(_name + " elite starts at full HP", _elite.hp, _want_elite);
}

function Test_D111_Gain(_name, _level, _atk, _def, _spd, _mag) {
    var _g = LevelUp_ClassGrowthGain(CLASS_NOBODY, _level);
    Test_Eq(_name + " ATK", _g.atk, _atk);
    Test_Eq(_name + " DEF", _g.def, _def);
    Test_Eq(_name + " SPD", _g.spd, _spd);
    Test_Eq(_name + " MAG", _g.mag, _mag);
}

function Test_Suite_BalanceD111() {
    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);
    EnemyDB_Init(); SkillDB_Init(); Loot_Init();

    // E1-1: the bosses' HP and DEF
    var _ph = EnemyDB_Get(ENEMY_MINI_BOSS);
    Test_Eq("D111 Palehorn base HP 25 -> 55", _ph.base_hp, 55);
    Test_Eq("D111 Palehorn DEF 16 -> 18", _ph.stats.def, 18);
    var _cb = EnemyDB_Get(ENEMY_FINAL_BOSS);
    Test_Eq("D111 Choirbeast base HP 34 -> 140", _cb.base_hp, 140);
    Test_Eq("D111 Choirbeast DEF 18 -> 24", _cb.stats.def, 24);
    Test_EnemyAt("D111 palehorn_8 (HP 55 + 7 x 6)", ENEMY_MINI_BOSS, 8, 18, 18, 12, 14, 97);
    Test_EnemyAt("D111 choirbeast_10 (HP 140 + 9 x 6)", ENEMY_FINAL_BOSS, 10, 21, 24, 14, 19, 194);

    // E1-2: an elite has ELITE_HP_MULT x the HP, rounded half up (Slime L1 9 -> 16, Killer Plant L5 34 -> 61, Palehorn L8 97 -> 175)
    Test_Eq("D111 ELITE_HP_MULT is 1.8", ELITE_HP_MULT, 1.8);
    Test_D111_EnemyHpAt("D111 elite Slime L1 (9 x 1.8 = 16.2)", ENEMY_SLIME, 1, "armored", 9, 16);
    Test_D111_EnemyHpAt("D111 elite Killer Plant L5 (34 x 1.8 = 61.2)", ENEMY_KILLER_PLANT, 5, "venomous", 34, 61);
    Test_D111_EnemyHpAt("D111 elite Dire Wolf L4 (27 x 1.8 = 48.6)", ENEMY_DIREWOLF, 4, "regenerating", 27, 49);
    var _en = Elite_Apply(EnemyCreate(ENEMY_SLIME), "");
    Test_Eq("D111 no modifier leaves the HP alone", _en.max_hp, 9);
    var _exp = Export_Build();
    Test_True("D111 the export carries elite_hp_mult 1.8", variable_struct_exists(_exp.constants.economy, "elite_hp_mult") && _exp.constants.economy.elite_hp_mult == 1.8);

    // E1-3: enemy basic power 3 -> 5, 5 -> 7, Choirbeast 9 -> 14 (Palehorn stays 7)
    Test_Eq("D111 basic power Slime 5", EnemyDB_Get(ENEMY_SLIME).basic_power, 5);
    Test_Eq("D111 basic power Spider 5", EnemyDB_Get(ENEMY_SPIDER).basic_power, 5);
    Test_Eq("D111 basic power Snake 5", EnemyDB_Get(ENEMY_SNAKE).basic_power, 5);
    Test_Eq("D111 basic power Dire Wolf 5", EnemyDB_Get(ENEMY_DIREWOLF).basic_power, 5);
    Test_Eq("D111 basic power Mad Whisp 7", EnemyDB_Get(ENEMY_MADWHISP).basic_power, 7);
    Test_Eq("D111 basic power Killer Plant 7", EnemyDB_Get(ENEMY_KILLER_PLANT).basic_power, 7);
    Test_Eq("D111 basic power Ghost Sword 7", EnemyDB_Get(ENEMY_GHOSTSWORD).basic_power, 7);
    Test_Eq("D111 basic power Stranger 7", EnemyDB_Get(ENEMY_STRANGER).basic_power, 7);
    Test_Eq("D111 basic power Palehorn stays 7", EnemyDB_Get(ENEMY_MINI_BOSS).basic_power, 7);
    Test_Eq("D111 basic power Choirbeast 14", EnemyDB_Get(ENEMY_FINAL_BOSS).basic_power, 14);

    // E1-4: the four telegraphed (wind-up) moves hit x2.0; Horizontal Slash (a player move) stays x1.5
    Test_Eq("D111 Vine Trap power_mult 2", SkillDB_Get(SKILL_VINE_TRAP).power_mult, 2);
    Test_Eq("D111 Cut power_mult 2", SkillDB_Get(SKILL_GHOST_CUT).power_mult, 2);
    Test_Eq("D111 Ramming power_mult 2", SkillDB_Get(SKILL_RAMMING).power_mult, 2);
    Test_Eq("D111 Pale Hymn power_mult 2", SkillDB_Get(SKILL_PALE_HYMN).power_mult, 2);
    Test_Eq("D111 Horizontal Slash (player) stays 1.5", SkillDB_Get(SKILL_HORIZ_SLASH).power_mult, 1.5);

    // E1-5: Knight base SPD 8 -> 10
    var _kn = CharacterCreate_Player(CLASS_KNIGHT);
    Test_Eq("D111 Knight SPD 10", _kn.stats.spd, 10);
    Test_Eq("D111 Knight SPD still 10 at level 2 (fixed growth has none)", LevelUp_ApplyLevel(_kn).stats.spd, 10);

    // E1-6: Nobody gets two fixed points a level (the old one plus the one two steps further on the ATK-DEF-SPD-MAG cycle), throwables x2
    Test_D111_Gain("D111 Nobody L2 gain", 2, 1, 0, 1, 0);
    Test_D111_Gain("D111 Nobody L3 gain", 3, 0, 1, 0, 1);
    Test_D111_Gain("D111 Nobody L4 gain", 4, 1, 0, 1, 0);
    Test_D111_Gain("D111 Nobody L5 gain", 5, 0, 1, 0, 1);
    Test_D111_Gain("D111 Nobody L6 gain", 6, 1, 0, 1, 0);
    Test_D111_Gain("D111 Nobody L7 gain", 7, 0, 1, 0, 1);
    Test_D111_Gain("D111 Nobody L8 gain", 8, 1, 0, 1, 0);
    Test_D111_Gain("D111 Nobody L9 gain", 9, 0, 1, 0, 1);
    Test_D111_Gain("D111 Nobody L10 gain", 10, 1, 0, 1, 0);
    var _nb = CharacterCreate_Player(CLASS_NOBODY);
    for (var _l = 2; _l <= 10; _l++) _nb = LevelUp_ApplyLevel(_nb);
    Test_True("D111 Nobody L10 stats ATK 22 DEF 12 SPD 14 MAG 7 (8+5+9, 8+4, 9+5, 3+4)", _nb.stats.atk == 22 && _nb.stats.def == 12 && _nb.stats.spd == 14 && _nb.stats.mag == 7);
    Test_Eq("D111 THROW_NOBODY_MULT is 2", THROW_NOBODY_MULT, 2);
    Test_Eq("D111 Nobody's throws are x2", Throw_Mult(CharacterCreate_Player(CLASS_NOBODY)), 2);
    Test_Eq("D111 the Knight's throws are x1", Throw_Mult(CharacterCreate_Player(CLASS_KNIGHT)), 1);
}

// R1 (D117-D125, owner grill 2026-10-15): fairer randomness. Expected values come from the decisions, not from the code:
// tier first then item (odds kept at today's effective values), chests never empty, crit marble bag, enemy-drop bad-luck
// protection, flee = SPD / (SPD + enemy SPD) + 0.25 per failed try, elites dealt per floor, run save version 2.
function Test_Suite_FairRng() {
    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);
    var _had_run = variable_struct_exists(_gs, "run");
    var _old_run = _had_run ? _gs.run : undefined;

    // ---- D117: the tier is rolled first (rarest first), then the item from that tier ----
    var _odds = Loot_TierOdds("chest", 1);
    Test_Eq("R1 D117: chest level-1 tier odds keep today's effective values (low 0.87)", _odds[0], 0.87);
    Test_Eq("R1 D117: chest level-1 mid 0.115", _odds[1], 0.115);
    Test_Eq("R1 D117: chest level-1 high 0.015", _odds[2], 0.015);
    var _sums_ok = true;
    var _tabs = ["chest", "barrel", "enemy"];
    for (var _t = 0; _t < 3; _t++) {
        for (var _lv = 1; _lv <= 3; _lv++) {
            var _o = Loot_TierOdds(_tabs[_t], _lv);
            if (abs(_o[0] + _o[1] + _o[2] - 1) > 0.0001) _sums_ok = false;
        }
    }
    Test_True("R1 D117: every table's tier odds add up to 1 at every level", _sums_ok);
    var _rng = Rng_New(31337, "r1tier");
    var _tc = [0, 0, 0, 0];
    for (var _i = 0; _i < 4000; _i++) _tc[Loot_RollTier(_rng, [0.5, 0.3, 0.2])]++;
    Test_True("R1 D117: odds 0.5/0.3/0.2 -> about 800 rare of 4000 (700..900)", _tc[3] >= 700 && _tc[3] <= 900);
    Test_True("R1 D117: odds 0.5/0.3/0.2 -> about 1200 mid of 4000 (1050..1350)", _tc[2] >= 1050 && _tc[2] <= 1350);
    var _always_hi = true;
    var _always_lo = true;
    for (var _i2 = 0; _i2 < 200; _i2++) {
        if (Loot_RollTier(_rng, [0, 0, 1]) != 3) _always_hi = false;
        if (Loot_RollTier(_rng, [1, 0, 0]) != 1) _always_lo = false;
    }
    Test_True("R1 D117: odds 0/0/1 always give the rare tier", _always_hi);
    Test_True("R1 D117: odds 1/0/0 always give the common tier", _always_lo);
    // many extra rare rows must not make the rare tier more likely (the old single table gives about 60% rare here)
    var _hero = Test_Hero(CLASS_KNIGHT);
    var _heavy = [];
    repeat (5) array_push(_heavy, { item_id: 15, weight: 1000, tier: 3, qty_min: 1, qty_max: 1 });
    var _rare_ids = [15, 18, 3, 6, 9, 22, 25];
    var _rare = 0;
    var _rng2 = Rng_New(4711, "r1heavy");
    for (var _i3 = 0; _i3 < 2000; _i3++) {
        var _it = Loot_RollFromTable("chest", 1, _hero, -1, [], _rng2, _heavy);
        if (is_struct(_it) && Card_ArrayHas(_rare_ids, _it.item_id)) _rare++;
    }
    Test_True("R1 D117: extra rare rows do not change the rare-tier odds (level 1: about 30 of 2000, at most 60)", _rare <= 60);

    // ---- D118: chests are never empty; gear rows always give 1 ----
    var _chest_rows = Loot_TableGet("chest");
    var _rows_ok = true;
    for (var _r = 0; _r < array_length(_chest_rows); _r++) {
        if (_chest_rows[_r].item_id <= 0 || _chest_rows[_r].qty_min < 1) _rows_ok = false;
    }
    Test_True("R1 D118: the chest table has no 'nothing' row and no 0-quantity row", _rows_ok);
    var _gear_ok = true;
    for (var _t2 = 0; _t2 < 3; _t2++) {
        var _rows = Loot_TableGet(_tabs[_t2]);
        for (var _r2 = 0; _r2 < array_length(_rows); _r2++) {
            if (_rows[_r2].item_id <= 0) continue;
            var _cfg = ItemDB_Get(_rows[_r2].item_id);
            if (is_struct(_cfg) && (_cfg.type == ITEM_WEAPON || _cfg.type == ITEM_ARMOR || _cfg.type == ITEM_ACCESSORY) && _rows[_r2].qty_min < 1) _gear_ok = false;
        }
    }
    Test_True("R1 D118: a gear row in any table always gives 1 (no hidden 0-quantity roll)", _gear_ok);
    var _empty = 0;
    var _classes = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];
    for (var _c = 0; _c < 3; _c++) {
        var _h = Test_Hero(_classes[_c]);
        for (var _sd = 1; _sd <= 60; _sd++) {
            for (var _lv2 = 1; _lv2 <= 3; _lv2++) {
                var _loot = Shuffle_ChestLoot(_sd, "rm_floor" + string(1 + (_sd mod 9)), "p" + string(_sd), _lv2, "chest_basic", _h);
                if (array_length(_loot) < 1 || _loot[0].qty < 1) _empty++;
            }
        }
    }
    Test_Eq("R1 D118: 540 chests (3 classes x 60 seeds x 3 levels) are never empty", _empty, 0);

    // ---- D119: crits come from a shuffled marble bag, refilled when a crit buff is applied ----
    var _bs = Crit_BagSize(0.25);
    Test_True("R1 D119: 25% = a bag of 4 with 1 crit", _bs.n == 4 && _bs.reds == 1);
    _bs = Crit_BagSize(0.5);
    Test_True("R1 D119: 50% = a bag of 2 with 1 crit", _bs.n == 2 && _bs.reds == 1);
    _bs = Crit_BagSize(0.3);
    Test_True("R1 D119: 30% = a bag of 10 with 3 crits", _bs.n == 10 && _bs.reds == 3);
    _bs = Crit_BagSize(0.35);
    Test_True("R1 D119: 35% = a bag of 20 with 7 crits", _bs.n == 20 && _bs.reds == 7);
    _bs = Crit_BagSize(1);
    Test_True("R1 D119: 100% = a bag of 1 crit", _bs.n == 1 && _bs.reds == 1);
    var _plain = CharacterCreate_Player(CLASS_KNIGHT);
    Test_False("R1 D119: no bonus, no crit", Combat_CritCheck(_plain, 0));
    Test_Eq("R1 D119: no bonus, no bag", Crit_BagLeft(_plain), 0);
    var _aim = Status_Add(CharacterCreate_Player(CLASS_ARCHER), STATUS_CRIT_UP, 9, 0);
    var _bonus = Status_GetSum(_aim, "crit_bonus");
    Test_Eq("R1 D119: a fresh buff starts with no bag drawn yet", Crit_BagLeft(_aim), 0);
    var _n4 = 0;
    for (var _k = 0; _k < 4; _k++) if (Combat_CritCheck(_aim, _bonus)) _n4++;
    Test_Eq("R1 D119: Take Aim crits exactly once in its first 4 hits", _n4, 1);
    var _n8 = 0;
    for (var _k2 = 0; _k2 < 4; _k2++) if (Combat_CritCheck(_aim, _bonus)) _n8++;
    Test_Eq("R1 D119: and exactly once in the next 4", _n8, 1);
    var _total = 0;
    var _dry = 0;
    var _worst = 0;
    for (var _k3 = 0; _k3 < 400; _k3++) {
        if (Combat_CritCheck(_aim, _bonus)) { _total++; _dry = 0; } else { _dry++; _worst = max(_worst, _dry); }
    }
    Test_Eq("R1 D119: 400 hits at 25% give exactly 100 crits", _total, 100);
    Test_True("R1 D119: never more than 6 hits in a row without a crit at 25%", _worst <= 6);
    var _aim2 = Status_Add(CharacterCreate_Player(CLASS_ARCHER), STATUS_CRIT_UP, 9, 0);
    Combat_CritCheck(_aim2, 25);
    Test_Eq("R1 D119: one hit drawn -> 3 marbles left", Crit_BagLeft(_aim2), 3);
    _aim2 = Status_Add(_aim2, STATUS_CRIT_UP, 9, 0);
    Test_Eq("R1 D119: applying the crit buff again empties the bag (a fresh one is filled on the next hit)", Crit_BagLeft(_aim2), 0);
    Combat_CritCheck(_aim2, 25);
    Combat_CritCheck(_aim2, 50);
    Test_Eq("R1 D119: a different chance fills a matching bag (50% -> 2, one drawn)", Crit_BagLeft(_aim2), 1);
    var _foe = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_CRIT_UP, 9, 0);
    var _fc = 0;
    for (var _k4 = 0; _k4 < 8; _k4++) if (Combat_CritCheck(_foe, 25)) _fc++;
    Test_Eq("R1 D119: enemies use the same bag (2 crits in 8 hits at 25%)", _fc, 2);

    // ---- D120: enemy drops: +10 points per won fight without an item, reset by a drop ----
    Test_Eq("R1 D120: the step is 0.10", LOOT_DRY_STEP, 0.1);
    Test_Eq("R1 D120: no dry fights -> the base chance", Loot_EnemyDropChance(0.2, 0), 0.2);
    Test_Eq("R1 D120: 3 dry fights -> 0.2 + 0.3", Loot_EnemyDropChance(0.2, 3), 0.5);
    Test_Eq("R1 D120: 8 dry fights -> certain", Loot_EnemyDropChance(0.2, 8), 1);
    Test_Eq("R1 D120: never above 1", Loot_EnemyDropChance(0.95, 1), 1);
    _gs.run = Run_Create(4242);
    Test_Eq("R1 D120: a new run starts with no dry fights", _gs.run.drop_dry, 0);
    var _streak = 0;
    var _worst2 = 0;
    var _counter_ok = true;
    var _drops = 0;
    for (var _f = 0; _f < 300; _f++) {
        var _d = Loot_RollEnemy({ id: ENEMY_SLIME, level: 1, loot_key: "enemy_basic" });
        if (array_length(_d) > 0) {
            _drops++;
            _streak = 0;
            if (_gs.run.drop_dry != 0) _counter_ok = false;
            if (_d[0].qty < 1) _counter_ok = false;
        } else {
            _streak++;
            _worst2 = max(_worst2, _streak);
            if (_gs.run.drop_dry != _streak) _counter_ok = false;
        }
    }
    Test_True("R1 D120: the dry counter counts fights without an item and resets on a drop", _counter_ok);
    Test_True("R1 D120: at a 20% base never more than 8 fights in a row without an item", _worst2 <= 8);
    Test_True("R1 D120: drops still happen often (at least 60 of 300)", _drops >= 60);

    // ---- D121: flee = SPD / (SPD + enemy SPD), +0.25 per failed try this fight ----
    Test_Eq("R1 D121: the retry step is 0.25", FLEE_FAIL_STEP, 0.25);
    Test_Eq("R1 D121: double speed -> 2/3", Battle_RunChance(20, 10), 0.666667);
    Test_Eq("R1 D121: equal speed, one failed try -> 0.75", Battle_RunChance(10, 10, 1), 0.75);
    Test_Eq("R1 D121: equal speed, two failed tries -> certain", Battle_RunChance(10, 10, 2), 1);
    Test_Eq("R1 D121: never above 1", Battle_RunChance(1, 40, 4), 1);

    // ---- D123: elites are dealt per floor: about 15% of the free slots, at least 1 from floor 2 on ----
    Test_Eq("R1 D123: floor 4, 3 enemies -> 1 elite", Shuffle_EliteCount(4, 3), 1);
    Test_Eq("R1 D123: floor 1, 3 enemies -> 0 elites", Shuffle_EliteCount(1, 3), 0);
    Test_Eq("R1 D123: floor 1, 7 enemies -> 1 elite", Shuffle_EliteCount(1, 7), 1);
    Test_Eq("R1 D123: floor 4, 10 enemies -> 2 elites (1.5 rounds up)", Shuffle_EliteCount(4, 10), 2);
    Test_Eq("R1 D123: floor 6, 20 enemies -> 3 elites", Shuffle_EliteCount(6, 20), 3);
    Test_Eq("R1 D123: floor 2, 1 enemy -> 1 elite", Shuffle_EliteCount(2, 1), 1);
    Test_Eq("R1 D123: no free enemies -> 0 elites", Shuffle_EliteCount(9, 0), 0);
    var _slots = [
        { pid: "e1", enemy_id: ENEMY_DIREWOLF, x: 48, y: 64, fixed: false },
        { pid: "e2", enemy_id: ENEMY_KILLER_PLANT, x: 96, y: 32, fixed: false },
        { pid: "e3", enemy_id: ENEMY_KILLER_PLANT, x: 144, y: 80, fixed: false },
        { pid: "b1", enemy_id: ENEMY_MINI_BOSS, x: 224, y: 32, fixed: true }
    ];
    var _each_one = true;
    var _which = [];
    for (var _sd2 = 1; _sd2 <= 50; _sd2++) {
        var _pl = Shuffle_RoomPlan(_sd2, "rm_floor4", _slots);
        var _ne = 0;
        for (var _q = 0; _q < 3; _q++) {
            if (_pl[_q].elite != "") {
                _ne++;
                if (!Card_ArrayHas(_which, _q)) array_push(_which, _q);
            }
        }
        if (_ne != 1 || _pl[3].elite != "") _each_one = false;
    }
    Test_True("R1 D123: 50 seeds of floor 4 (3 free slots): exactly 1 elite each, never the boss", _each_one);
    Test_True("R1 D123: which slot is the elite changes with the seed", array_length(_which) >= 2);
    var _ten = [];
    for (var _s = 0; _s < 10; _s++) array_push(_ten, { pid: "t" + string(_s), enemy_id: ENEMY_GHOSTSWORD, x: 16 * _s, y: 16, fixed: false });
    var _two_ok = true;
    for (var _sd3 = 1; _sd3 <= 20; _sd3++) {
        var _pl2 = Shuffle_RoomPlan(_sd3, "rm_floor6", _ten);
        var _ne2 = 0;
        for (var _q2 = 0; _q2 < 10; _q2++) if (_pl2[_q2].elite != "") _ne2++;
        if (_ne2 != 2) _two_ok = false;
    }
    Test_True("R1 D123: floor 6 with 10 free slots always has exactly 2 elites", _two_ok);

    // ---- D125: run save version 2 ----
    Test_Eq("R1 D125: the run save version is 2", RUN_SAVE_VERSION, 2);

    if (_had_run) _gs.run = _old_run; else variable_struct_remove(_gs, "run");
}

// R1b (D122, D124, owner grill 2026-10-15): the game pauses when the window loses focus; the smoothed odds are stated plainly.
function Test_Suite_FairUi() {
    var _gs = Test_FixBegin(DIFFICULTY_NORMAL);

    // ---- D122: losing focus opens the pause menu (only when nothing else owns the screen) ----
    Test_True("R1b D122: unfocused, walking around -> pause", Focus_ShouldPause(false, UI_NONE, false, false, false));
    Test_True("R1b D122: unfocused, in a battle -> pause", Focus_ShouldPause(false, UI_NONE, false, true, false));
    Test_False("R1b D122: focused -> no pause", Focus_ShouldPause(true, UI_NONE, false, false, false));
    Test_False("R1b D122: already paused -> nothing new", Focus_ShouldPause(false, UI_PAUSE, false, false, false));
    Test_False("R1b D122: on the title screen -> nothing", Focus_ShouldPause(false, UI_NONE, true, false, false));
    Test_False("R1b D122: during a room transition -> nothing", Focus_ShouldPause(false, UI_NONE, false, false, true));
    Test_False("R1b D122: in the shop -> nothing (it waits for input anyway)", Focus_ShouldPause(false, UI_SHOP, false, false, false));
    var _pm = PauseMenu_Items(false, true);
    Test_True("R1b D122: the pause menu in a battle keeps Resume, Help and Settings", _pm[0].enabled && _pm[1].enabled && _pm[2].enabled);
    Test_False("R1b D122: the pause menu in a battle disables Abandon run", _pm[3].enabled);
    Test_False("R1b D122: the pause menu in a battle disables Quit to title", _pm[4].enabled);
    var _pm2 = PauseMenu_Items(false);
    Test_True("R1b D122: outside a battle Abandon and Quit stay enabled", _pm2[3].enabled && _pm2[4].enabled);

    // ---- D124: the flee chance is shown on the RUN command ----
    var _k = CharacterCreate_Player(CLASS_KNIGHT);
    var _sl = EnemyCreate(ENEMY_SLIME);
    // Review 1: the shown percent never rounds up to a sure thing (floor, 99 at most) and says 100 only when the chance is exactly 1.
    // D124 says "a whole percent"; round() showed 100% for 0.9955 while the escape could still fail, so the two figures below are floored (spec refinement).
    Test_Eq("R1b D124: Knight (SPD 10) vs Slime (SPD 9): 10/19 = 52.6 -> 52%", Battle_RunPct(_k, _sl, 0), 52);
    Test_Eq("R1b D124: after one failed try: 77.6 -> 77%", Battle_RunPct(_k, _sl, 1), 77);
    var _fast = CharacterCreate_Player(CLASS_KNIGHT);
    var _slow = EnemyCreate(ENEMY_SLIME);
    _fast.stats.spd = 41;
    _slow.stats.spd = 14;
    Test_Eq("Review1: SPD 41 vs 14 after one failed try is 0.9955 -> 99%, not 100%", Battle_RunPct(_fast, _slow, 1), 99);
    _fast.stats.spd = 200;
    _slow.stats.spd = 1;
    Test_Eq("Review1: SPD 200 vs 1 is 0.995 -> 99%, not 100%", Battle_RunPct(_fast, _slow, 0), 99);
    _fast.stats.spd = 10;
    _slow.stats.spd = 10;
    Test_Eq("Review1: equal SPD after two failed tries is exactly 1 -> 100%", Battle_RunPct(_fast, _slow, 2), 100);
    Test_Eq("Review1: equal SPD, no failed try -> 50%", Battle_RunPct(_fast, _slow, 0), 50);
    Test_Eq("R1b D124: a boss cannot be fled (-1)", Battle_RunPct(_k, EnemyCreate(ENEMY_MINI_BOSS), 0), -1);
    var _cmd = Battle_CmdItems({ p: _k, e: _sl, run_fails: 0 });
    Test_Eq("R1b D124: the RUN row shows the chance", _cmd[4].value, "52%");
    var _cmd_b = Battle_CmdItems({ p: _k, e: EnemyCreate(ENEMY_FINAL_BOSS), run_fails: 0 });
    Test_Eq("R1b D124: against a boss the RUN row says no", _cmd_b[4].value, Loc_T("battle.action.run_no", "no"));
    Test_Eq("R1b D124: without a battle the RUN row has no number", Battle_CmdItems()[4].value, "");

    // ---- D124: Take Aim says how often it crits, from the bag size ----
    var _line = Status_Describe(STATUS_CRIT_UP).line;
    Test_True("R1b D124: Take Aim's status line reads '1 in every 4 hits is a critical.'", string_pos("1 in every 4 hits is a critical", _line) > 0);
}

// ---- D108 F2a: transitions, boot logo, cutscene holds and the credits roll run on a ms clock ----
// Plays one transition through the pure phase machine at a fixed step. Returns { steps: [steps spent in each phase], events: [{ ev, phase, timer, i }], total }.
function Test_TransitionRun(_type, _step_ms, _black_hold_ms = undefined) {
    var _tr = { type: _type, phase: 0, timer: 0, alpha: 0, progress: 0 };
    Transition_ApplyTimes(_tr, _type);
    if (!is_undefined(_black_hold_ms)) _tr.black_hold_ms = _black_hold_ms;
    var _out = { steps: [0, 0, 0, 0, 0], events: [], total: 0 };
    for (var _i = 0; _i < 2000; _i++) {
        var _ph = _tr.phase;
        var _ev = Transition_PhaseStep(_tr, _step_ms);
        _out.steps[_ph]++;
        _out.total++;
        if (_ev != TRANSITION_EVT_NONE) array_push(_out.events, { ev: _ev, phase: _tr.phase, timer: _tr.timer, i: _i });
        if (_ev == TRANSITION_EVT_DONE) break;
    }
    return _out;
}

function Test_TransitionSame(_name, _got, _want, _tol) {
    var _ok = true;
    for (var _i = 0; _i < array_length(_want); _i++) { if (abs(_got[_i] - _want[_i]) > _tol) _ok = false; }
    Test_True(_name + " (got " + string(_got) + " want " + string(_want) + ")", _ok);
}

function Test_Suite_Transition() {
    var _f60 = 1000 / 60;      // 16.667 ms, the old frame
    var _s60 = Presentation_StepMs(16667);
    var _s30 = Presentation_StepMs(33333);

    // the clock: microseconds from delta_time, a long frame cannot skip a whole fade
    Test_Eq("F2a a step of 16667 us == 16.667 ms", _s60, 16.667);
    Test_Eq("F2a a step of a 200 ms hitch is capped at 50 ms", Presentation_StepMs(200000), 50);
    Test_Eq("F2a a negative delta_time adds nothing", Presentation_StepMs(-5), 0);
    Test_Eq("F2a Transition_FramesToMs(12) == 200 ms", Transition_FramesToMs(12), 200);

    // 60 fps: the old frame counts (steps per phase), +-1
    var _r = Test_TransitionRun(TRANSITION_TYPE_ROOM, _s60);
    Test_TransitionSame("F2a ROOM at 60 fps: out 12, hold 2, in 14 frames", _r.steps, [12, 2, 14, 0, 0], 1);
    _r = Test_TransitionRun(TRANSITION_TYPE_ENCOUNTER, _s60);
    Test_TransitionSame("F2a ENCOUNTER at 60 fps: zoom 36, zoom hold 6, out 22, hold 10, in 24 frames", _r.steps, [36, 6, 22, 10, 24], 1);
    _r = Test_TransitionRun(TRANSITION_TYPE_FLASH, _s60);
    Test_TransitionSame("F2a FLASH at 60 fps: out 12, in 14 frames", _r.steps, [12, 14, 0, 0, 0], 1);
    _r = Test_TransitionRun(TRANSITION_TYPE_CUTSCENE, _s60);
    Test_TransitionSame("F2a CUTSCENE at 60 fps: out 20, hold 2, in 22 frames", _r.steps, [20, 2, 22, 0, 0], 1);

    // 30 fps: the same durations in ms, so half the steps
    _r = Test_TransitionRun(TRANSITION_TYPE_ROOM, _s30);
    Test_TransitionSame("F2a ROOM at 30 fps: 200 ms out, 33 ms hold, 233 ms in -> 6, 1, 7 steps", _r.steps, [6, 1, 7, 0, 0], 0);
    _r = Test_TransitionRun(TRANSITION_TYPE_ENCOUNTER, _s30);
    Test_TransitionSame("F2a ENCOUNTER at 30 fps -> 18, 3, 11, 5, 12 steps", _r.steps, [18, 3, 11, 5, 12], 0);
    _r = Test_TransitionRun(TRANSITION_TYPE_FLASH, _s30);
    Test_TransitionSame("F2a FLASH at 30 fps -> 6, 7 steps", _r.steps, [6, 7, 0, 0, 0], 0);
    _r = Test_TransitionRun(TRANSITION_TYPE_CUTSCENE, _s30);
    Test_TransitionSame("F2a CUTSCENE at 30 fps -> 10, 1, 11 steps", _r.steps, [10, 1, 11, 0, 0], 0);

    // events: the room change fires once, at the end of the fade-out, and the black hold starts after it
    _r = Test_TransitionRun(TRANSITION_TYPE_ROOM, _s60);
    Test_Eq("F2a ROOM fires ROOM_CHANGE then DONE", array_length(_r.events), 2);
    Test_Eq("F2a ROOM first event is ROOM_CHANGE", _r.events[0].ev, TRANSITION_EVT_ROOM_CHANGE);
    Test_Eq("F2a ROOM ROOM_CHANGE leaves the machine in the hold with timer 0", _r.events[0].phase == 1 && _r.events[0].timer == 0, true);
    Test_Eq("F2a ROOM last event is DONE", _r.events[1].ev, TRANSITION_EVT_DONE);
    _r = Test_TransitionRun(TRANSITION_TYPE_FLASH, _s60);
    Test_Eq("F2a FLASH fires FLASH_BLACK at the end of the fade-out", _r.events[0].ev, TRANSITION_EVT_FLASH_BLACK);
    _r = Test_TransitionRun(TRANSITION_TYPE_ENCOUNTER, _s60);
    Test_Eq("F2a ENCOUNTER changes the room at the end of its 3rd phase (fade-out)", _r.events[0].ev == TRANSITION_EVT_ROOM_CHANGE && _r.events[0].phase == 3, true);

    // the black hold needs at least one real step after the room change, even with a 0 ms hold and a long step
    _r = Test_TransitionRun(TRANSITION_TYPE_ROOM, _s60, 0);
    Test_True("F2a ROOM with a 0 ms hold still spends >= 1 step in the black hold", _r.steps[1] >= 1);
    _r = Test_TransitionRun(TRANSITION_TYPE_CUTSCENE, 50, 0);
    Test_True("F2a CUTSCENE with a 0 ms hold and 50 ms steps still spends >= 1 step in the black hold", _r.steps[1] >= 1);
    _r = Test_TransitionRun(TRANSITION_TYPE_ENCOUNTER, 50, 0);
    Test_True("F2a ENCOUNTER with a 0 ms hold and 50 ms steps still spends >= 1 step in the black hold", _r.steps[3] >= 1);

    // a hitch cannot skip a fade: one 200 ms frame advances the fade by at most 50 ms
    var _tr = { type: TRANSITION_TYPE_ROOM, phase: 0, timer: 0, alpha: 0, progress: 0 };
    Transition_ApplyTimes(_tr, TRANSITION_TYPE_ROOM);
    var _ev = Transition_PhaseStep(_tr, Presentation_StepMs(200000));
    Test_Eq("F2a a 200 ms hitch advances the fade-out by 50 ms", _tr.timer, 50);
    Test_Eq("F2a a 200 ms hitch does not finish the 200 ms fade-out", _ev == TRANSITION_EVT_NONE && _tr.phase == 0, true);
    Test_Eq("F2a the fade-out alpha after 50 of 200 ms is 0.25", _tr.alpha, 0.25);

    // alpha: black through the hold, fades back to 0 by the end
    _tr = { type: TRANSITION_TYPE_ROOM, phase: 1, timer: 0, alpha: 0, progress: 0 };
    Transition_ApplyTimes(_tr, TRANSITION_TYPE_ROOM);
    Transition_PhaseStep(_tr, _f60);
    Test_Eq("F2a ROOM black hold keeps alpha 1", _tr.alpha, 1);

    // boot logo, in ms (48 / 120 / 48 / 8 frames at 60 fps)
    Test_Eq("F2a boot logo fade-in 800 ms", BOOT_LOGO_FADE_IN_MS, 800);
    Test_Eq("F2a boot logo hold 2000 ms", BOOT_LOGO_HOLD_MS, 2000);
    Test_Eq("F2a boot logo fade-out 800 ms", BOOT_LOGO_FADE_OUT_MS, 800);
    Test_True("F2a boot logo black hold 8 frames == 133.33 ms", abs(BOOT_LOGO_BLACK_HOLD_MS - 8 * _f60) < 0.01);
    Test_Eq("F2a cutscene logo fade 300 ms (18 frames at 60 fps)", CUTSCENE_LOGO_FADE_MS, 300);

    // credits: one GUI pixel per 60 fps frame == 60 px per second
    var _px = 0;
    for (var _i = 0; _i < 600; _i++) _px = Credits_ScrollPx((_i + 1) * _s60);
    Test_True("F2a credits scroll 60 * 10 px after 10 s of 60 fps steps", abs(_px - 600) < 1);
    var _ms = 0;
    for (var _j = 0; _j < 150; _j++) _ms += _s30;
    Test_True("F2a credits scroll 60 * 5 px after 5 s of 30 fps steps", abs(Credits_ScrollPx(_ms) - 300) < 1);
    Test_Eq("F2a credits scroll at 0 ms is 0 px", Credits_ScrollPx(0), 0);
    var _lay = { total: 1000 };
    var _frames_old = Display_GuiH() + 1000 + round(Display_GuiH() * 0.5);
    Test_True("F2a credits total ms == the old frame count at 60 fps", abs(Credits_TotalMs(_lay) - _frames_old * _f60) < 0.01);
}

// D108 F1d-2: the credits roll and the dialogue text layout are built once per change, not once per call.
// The credits layout is keyed on the Ui_Metrics struct (a new one per Display layout and language) plus the language; the dialogue layout on that struct plus the
// states it reads (speaker or not, cutscene text only, half-height box). Expected counts: 0 more builds while nothing changes, exactly 1 after a change.
function Test_Suite_LayoutCache() {
    var _lang0 = Loc_GetLanguage();
    var _disp0 = variable_global_exists("display") ? global.display : undefined;
    var _own = !(is_struct(_disp0) && is_struct(_disp0.layout));
    var _layout0 = _own ? Display_CalcLayout(480, 432) : _disp0.layout;
    if (_own) global.display = { layout: _layout0, apply_count: 0 };
    var _d = global.display;
    var _f0 = draw_get_font();

    // a private copy of the UI state, so the dialogue fields the check sets never leak
    var _gs = GameState_Get();
    var _had_ui = variable_struct_exists(_gs, "ui");
    var _ui0 = _had_ui ? _gs.ui : undefined;
    var _ui = {};
    if (is_struct(_ui0)) {
        var _names = variable_struct_get_names(_ui0);
        for (var _n = 0; _n < array_length(_names); _n++) variable_struct_set(_ui, _names[_n], variable_struct_get(_ui0, _names[_n]));
    }
    _ui.mode = UI_DIALOGUE;
    _ui.speaker = "Hero";
    _ui.lines_raw = ["Hello there, traveller. The tunnel is long and the dark is patient, so rest while you can."];
    _ui.lines = [];
    _ui.index = 0;
    _ui.cutscene_text_only = false;
    _ui.dialogue_box_half = false;
    _gs.ui = _ui;

    // ---- credits: 300 Credits_Layout and 300 Credits_TotalMs calls with nothing changing build nothing more ----
    Loc_SetLanguage("en");
    Ui_Metrics();
    var _cl_en = Credits_Layout();
    var _cb0 = Credits_LayoutBuilds();
    var _lb0 = Credits_LinesBuilds();
    var _same = true;
    for (var _i = 0; _i < 300; _i++) {
        if (Credits_Layout() != _cl_en) _same = false;
        Credits_TotalMs();
    }
    Test_Eq("F1d2 300 Credits_Layout + 300 Credits_TotalMs calls build the layout 0 more times", Credits_LayoutBuilds() - _cb0, 0);
    Test_Eq("F1d2 300 Credits_Layout + 300 Credits_TotalMs calls build the lines 0 more times", Credits_LinesBuilds() - _lb0, 0);
    Test_True("F1d2 Credits_Layout returns the same struct while nothing changes", _same);
    var _ref = Credits_LayoutBuild();
    Test_Eq("F1d2 the cached en credits layout equals the uncached one", json_stringify(_cl_en), json_stringify(_ref));
    Test_Eq("F1d2 the credits layout has a row per roll entry", array_length(_cl_en.rows), array_length(Credits_Lines()));

    // en -> ko: one rebuild, then cached again
    _cb0 = Credits_LayoutBuilds();
    _lb0 = Credits_LinesBuilds();
    Loc_SetLanguage("ko");
    var _cl_ko = Credits_Layout();
    for (var _i2 = 0; _i2 < 300; _i2++) { Credits_Layout(); Credits_TotalMs(); }
    Test_Eq("F1d2 credits en to ko rebuild the layout exactly once", Credits_LayoutBuilds() - _cb0, 1);
    Test_Eq("F1d2 credits en to ko rebuild the lines exactly once", Credits_LinesBuilds() - _lb0, 1);
    Test_True("F1d2 the ko credits layout is a new struct", _cl_ko != _cl_en);
    Test_Eq("F1d2 the cached ko credits layout equals the uncached one", json_stringify(_cl_ko), json_stringify(Credits_LayoutBuild()));

    // ko -> en
    _cb0 = Credits_LayoutBuilds();
    Loc_SetLanguage("en");
    var _cl_en2 = Credits_Layout();
    for (var _i3 = 0; _i3 < 300; _i3++) { Credits_Layout(); Credits_TotalMs(); }
    Test_Eq("F1d2 credits ko to en rebuild the layout exactly once", Credits_LayoutBuilds() - _cb0, 1);
    Test_Eq("F1d2 back in en the credits layout equals the first en one", json_stringify(_cl_en2), json_stringify(_cl_en));

    // a Display relayout (a new layout struct, as Display_Relayout makes)
    _cb0 = Credits_LayoutBuilds();
    _d.layout = Display_CalcLayout(1280, 720);
    var _cl_big = Credits_Layout();
    for (var _i4 = 0; _i4 < 300; _i4++) { Credits_Layout(); Credits_TotalMs(); }
    Test_Eq("F1d2 a relayout rebuilds the credits layout exactly once", Credits_LayoutBuilds() - _cb0, 1);
    Test_Eq("F1d2 the relayout credits layout equals the uncached one", json_stringify(_cl_big), json_stringify(Credits_LayoutBuild()));
    Test_True("F1d2 the relayout credits layout has another column width", _cl_big.col_w != _cl_en.col_w);
    _d.layout = _layout0;
    Credits_Layout();

    // ---- dialogue: the layout of an open line ----
    Loc_SetLanguage("en");
    Ui_Metrics();
    var _tl = Dialogue_TextLayout("Hero");
    Dialogue_RebuildPagedLines();
    Dialogue_TypewriterPrepareCurrentLine();
    var _page = Dialogue_LineText(_ui.lines[_ui.index]);
    _ui.dialogue_visible_count = 5;
    var _db0 = Dialogue_TextLayoutBuilds();
    var _dsame = true;
    for (var _j = 0; _j < 300; _j++) {
        if (Dialogue_TextLayout("Hero") != _tl) _dsame = false;
        Dialogue_TypewriterPrepareCurrentLine();   // the Step and the Draw both do this every frame
        Dialogue_EnsurePagedLinesCurrent();
    }
    Test_Eq("F1d2 300 frames of dialogue prepare + layout build the text layout 0 more times", Dialogue_TextLayoutBuilds() - _db0, 0);
    Test_True("F1d2 Dialogue_TextLayout returns the same struct while nothing changes", _dsame);
    Test_Eq("F1d2 the typewriter is not reset by the layout checks", _ui.dialogue_visible_count, 5);
    Test_Eq("F1d2 the page text is unchanged by the layout checks", Dialogue_LineText(_ui.lines[_ui.index]), _page);
    Test_Eq("F1d2 the cached dialogue layout equals the uncached one", json_stringify(_tl), json_stringify(Dialogue_TextLayoutBuild("Hero")));
    Test_Eq("F1d2 the cached dialogue layout without a speaker equals the uncached one", json_stringify(Dialogue_TextLayout("")), json_stringify(Dialogue_TextLayoutBuild("")));
    Test_Eq("F1d2 the cached box rect equals the uncached layout's box", json_stringify(Dialogue_BoxRect()), json_stringify(Dialogue_BoxRectBuild()));

    // cutscene text only and the half-height box each give their own (equal-to-uncached) layout
    _ui.cutscene_text_only = true;
    Test_Eq("F1d2 the cutscene text-only layout equals the uncached one", json_stringify(Dialogue_TextLayout("Hero")), json_stringify(Dialogue_TextLayoutBuild("Hero")));
    Test_Eq("F1d2 the cutscene text-only layout without a speaker equals the uncached one", json_stringify(Dialogue_TextLayout("")), json_stringify(Dialogue_TextLayoutBuild("")));
    Test_True("F1d2 the cutscene text-only layout differs from the boxed one", json_stringify(Dialogue_TextLayout("Hero")) != json_stringify(_tl));
    _ui.cutscene_text_only = false;
    _ui.dialogue_box_half = true;
    Test_Eq("F1d2 the half-height box layout equals the uncached one", json_stringify(Dialogue_TextLayout("Hero")), json_stringify(Dialogue_TextLayoutBuild("Hero")));
    Test_Eq("F1d2 the half-height box rect equals the uncached one", json_stringify(Dialogue_BoxRect()), json_stringify(Dialogue_BoxRectBuild()));
    Test_True("F1d2 the half-height box is taller than the boxed one", Dialogue_BoxRect().h > _tl.box.h);
    _ui.dialogue_box_half = false;
    Test_Eq("F1d2 back to the boxed layout the cached one equals the first", json_stringify(Dialogue_TextLayout("Hero")), json_stringify(_tl));

    // en -> ko -> en
    Dialogue_TextLayout("Hero");
    _db0 = Dialogue_TextLayoutBuilds();
    Loc_SetLanguage("ko");
    var _tl_ko = Dialogue_TextLayout("Hero");
    for (var _j2 = 0; _j2 < 300; _j2++) { Dialogue_TextLayout("Hero"); Dialogue_BoxRect(); }
    Test_Eq("F1d2 dialogue en to ko rebuild the text layout exactly once", Dialogue_TextLayoutBuilds() - _db0, 1);
    Test_Eq("F1d2 the cached ko dialogue layout equals the uncached one", json_stringify(_tl_ko), json_stringify(Dialogue_TextLayoutBuild("Hero")));
    _db0 = Dialogue_TextLayoutBuilds();
    Loc_SetLanguage("en");
    var _tl_en2 = Dialogue_TextLayout("Hero");
    for (var _j3 = 0; _j3 < 300; _j3++) { Dialogue_TextLayout("Hero"); Dialogue_BoxRect(); }
    Test_Eq("F1d2 dialogue ko to en rebuild the text layout exactly once", Dialogue_TextLayoutBuilds() - _db0, 1);
    Test_Eq("F1d2 back in en the dialogue layout equals the first en one", json_stringify(_tl_en2), json_stringify(_tl));

    // a Display relayout
    _db0 = Dialogue_TextLayoutBuilds();
    _d.layout = Display_CalcLayout(1280, 720);
    var _tl_big = Dialogue_TextLayout("Hero");
    for (var _j4 = 0; _j4 < 300; _j4++) { Dialogue_TextLayout("Hero"); Dialogue_BoxRect(); }
    Test_Eq("F1d2 a relayout rebuilds the dialogue text layout exactly once", Dialogue_TextLayoutBuilds() - _db0, 1);
    Test_Eq("F1d2 the relayout dialogue layout equals the uncached one", json_stringify(_tl_big), json_stringify(Dialogue_TextLayoutBuild("Hero")));
    Test_True("F1d2 the relayout dialogue layout has another text width", _tl_big.text_w != _tl.text_w);
    Test_Eq("F1d2 the relayout box rect equals the uncached one", json_stringify(Dialogue_BoxRect()), json_stringify(Dialogue_BoxRectBuild()));
    _d.layout = _layout0;

    // [PERF] 1000 x Credits_Layout and 1000 x Dialogue_TextLayout (no assertion: the time depends on the PC)
    Ui_Metrics();
    var _t0 = get_timer();
    for (var _p0 = 0; _p0 < 1000; _p0++) Credits_Layout();
    var _t1 = get_timer();
    for (var _p1 = 0; _p1 < 1000; _p1++) Dialogue_TextLayout("Hero");
    var _t2 = get_timer();
    Test_Log("[PERF] 1000 x Credits_Layout: " + string(_t1 - _t0) + " us, 1000 x Dialogue_TextLayout: " + string(_t2 - _t1) + " us");

    if (_had_ui) _gs.ui = _ui0;
    else variable_struct_remove(_gs, "ui");
    draw_set_font(_f0);
    if (_own) global.display = _disp0;
    Loc_SetLanguage(_lang0);
}

// Bug hunt 2 (D33, D63, D66): the home spot of a map enemy is saved with its place (the enemy comes back to the spot it was dealt, not to the authored one).
function Test_Suite_Hunt2() {
    var _v = RoomState_SanitizeEnemyVars({ x: 112, y: 96, enemy_id: ENEMY_DIREWOLF, home_x: 128, home_y: 80, junk: 5 }, ENEMY_DIREWOLF);
    Test_True("hunt2 the saved enemy vars keep the home spot", variable_struct_exists(_v, "home_x") && variable_struct_exists(_v, "home_y"));
    Test_Eq("hunt2 the saved home x is the dealt spot", variable_struct_exists(_v, "home_x") ? _v.home_x : -1, 128);
    Test_Eq("hunt2 the saved home y is the dealt spot", variable_struct_exists(_v, "home_y") ? _v.home_y : -1, 80);
    Test_True("hunt2 unknown vars are still dropped", !variable_struct_exists(_v, "junk"));
    var _old = RoomState_SanitizeEnemyVars({ x: 112, y: 96, enemy_id: ENEMY_SLIME }, ENEMY_SLIME);
    Test_True("hunt2 an old save without a home keeps none (the enemy keeps its authored home)", !variable_struct_exists(_old, "home_x") && !variable_struct_exists(_old, "home_y"));
}

// G2 (D128): the title screen. The card text builder (class, floor, gold, optional time) and the living-background maths (breathing offset,
// dust, blink, fade-in) are pure functions: bounded, whole art pixels, deterministic. Expected values come from the packet's spec.
function Test_Suite_Title() {
    var _lang0 = Loc_GetLanguage();
    Loc_SetLanguage("en");

    // breathing: a sine over 3 s, 0..2 whole art pixels, 0 at rest
    Test_Eq("D128 breath: rest at t=0", Title_BreathOffset(0, false), 0);
    Test_Eq("D128 breath: a quarter period is one pixel", Title_BreathOffset(750, false), 1);
    Test_Eq("D128 breath: half a period (1.5 s) is the 2 px peak", Title_BreathOffset(1500, false), 2);
    Test_Eq("D128 breath: three quarters is one pixel", Title_BreathOffset(2250, false), 1);
    Test_Eq("D128 breath: the period is 3 s", Title_BreathOffset(3000 + 1500, false), 2);
    var _b_ok = true;
    var _b_max = 0;
    for (var _t = 0; _t < 9000; _t += 37) {
        var _b = Title_BreathOffset(_t, false);
        if (_b < 0 || _b > 2 || _b != floor(_b)) _b_ok = false;
        _b_max = max(_b_max, _b);
        if (Title_BreathOffset(_t, false) != _b) _b_ok = false;   // the same time gives the same answer
        if (Title_BreathOffset(_t, true) != 0) _b_ok = false;     // reduced motion: no movement
    }
    Test_True("D128 breath: always 0..2 whole pixels, deterministic, still when motion is off", _b_ok);
    Test_Eq("D128 breath: reaches the peak", _b_max, 2);

    // dust: a few dozen dots, inside the art, whole pixels, drifting up
    Test_Eq("D128 dust: a few dozen dots", Title_DustCount(), 32);
    var _d_ok = true;
    var _d_msg = "";
    var _cols = [false, false, false];
    var _sizes = [false, false, false];
    for (var _i = 0; _i < Title_DustCount(); _i++) {
        var _v = Title_DustSpeed(_i);
        if (_v < 2 || _v > 8 || _v != floor(_v)) { _d_ok = false; _d_msg = "speed " + string(_i); }
        var _d0 = Title_DustAt(_i, 0, false);
        var _d1 = Title_DustAt(_i, 1000, false);
        if (((_d0.y - _d1.y) + (TITLE_ART_H - 1)) mod (TITLE_ART_H - 1) != _v) { _d_ok = false; _d_msg = "drift " + string(_i); }   // one second: _v pixels up (wrapping)
        for (var _t2 = 0; _t2 < 60000; _t2 += 1733) {
            var _d = Title_DustAt(_i, _t2, false);
            if (_d.x < 0 || _d.x + _d.size > TITLE_ART_W || _d.y < 0 || _d.y + _d.size > TITLE_ART_H || _d.x != floor(_d.x) || _d.y != floor(_d.y)) { _d_ok = false; _d_msg = "bounds " + string(_i) + "@" + string(_t2); }
            var _dx = abs(_d.x - _d0.x);
            if (_dx > 2 && _dx < TITLE_ART_W - 3) { _d_ok = false; _d_msg = "sway " + string(_i); }
            var _again = Title_DustAt(_i, _t2, false);
            if (_again.x != _d.x || _again.y != _d.y || _again.size != _d.size || _again.col != _d.col) { _d_ok = false; _d_msg = "determinism " + string(_i); }
            var _still = Title_DustAt(_i, _t2, true);
            if (_still.x != _d0.x || _still.y != _d0.y) { _d_ok = false; _d_msg = "calm " + string(_i); }
        }
        if (_d0.col < 0 || _d0.col > 2) _d_ok = false; else _cols[_d0.col] = true;
        if (_d0.size < 1 || _d0.size > 2) _d_ok = false; else _sizes[_d0.size] = true;
    }
    Test_True("D128 dust: inside the art, whole pixels, deterministic, 2..8 px/s upward, still when motion is off " + _d_msg, _d_ok);
    Test_True("D128 dust: all three palette colours are used", _cols[0] && _cols[1] && _cols[2]);
    Test_True("D128 dust: dots are 1 or 2 pixels", _sizes[1] && _sizes[2]);

    // splash: the prompt blinks (600 ms on, 400 ms off), the art fades in over 1.2 s, the first 200 ms ignore a key
    Test_True("D128 blink: on at the start", Title_BlinkOn(0));
    Test_True("D128 blink: still on at 599 ms", Title_BlinkOn(599));
    Test_True("D128 blink: off at 600 ms", !Title_BlinkOn(600));
    Test_True("D128 blink: off at 999 ms", !Title_BlinkOn(999));
    Test_True("D128 blink: on again at 1000 ms", Title_BlinkOn(1000));
    Test_Eq("D128 fade-in: black at the start", Title_FadeIn(0), 0);
    Test_Eq("D128 fade-in: fully in after 1.2 s", Title_FadeIn(1200), 1);
    Test_True("D128 fade-in: half way is between", Title_FadeIn(600) > 0.2 && Title_FadeIn(600) < 0.8);
    Test_True("D128 fade-in: never goes back", Title_FadeIn(300) <= Title_FadeIn(600) && Title_FadeIn(600) <= Title_FadeIn(900));
    Test_True("D128 splash: a key in the first 200 ms is ignored", !Title_SplashAccepts(0) && !Title_SplashAccepts(199));
    Test_True("D128 splash: a key after 200 ms is taken", Title_SplashAccepts(200));
    Test_Eq("D128 splash prompt: keyboard", Title_SplashPrompt("keyboard"), "Press any key");
    Test_Eq("D128 splash prompt: controller", Title_SplashPrompt("gamepad"), "Press any button");

    // the Continue card text
    var _gold_l = Loc_T("tab.lbl.gold", "Gold");
    var _floor_l = Loc_T("tab.lbl.floor", "Floor");
    var _run = { run_version: RUN_SAVE_VERSION, seed: 5, gold: 137, floor: 4, statData: { selected_class: CLASS_ARCHER } };
    var _m = Title_CardModel({ status: "ok", run: _run });
    Test_Eq("D128 card: a good save shows the run", _m.kind, "run");
    var _t_ok = Title_CardText(_m);
    Test_Eq("D128 card: title is the class", _t_ok.title, "Archer");
    Test_Eq("D128 card: without a time, two rows (floor, gold)", array_length(_t_ok.rows), 2);
    Test_Eq("D128 card: floor row", json_stringify(_t_ok.rows[0]), json_stringify({ label: _floor_l, value: "4" }));
    Test_Eq("D128 card: gold row", json_stringify(_t_ok.rows[1]), json_stringify({ label: _gold_l, value: "137" }));
    Test_Eq("D128 card: no class in the save is Unknown", Title_CardText(Title_CardModel({ status: "ok", run: { gold: 1, floor: 1, statData: {} } })).title, Loc_T("class.name.unknown", "Unknown"));
    Test_Eq("D128 card: a sub-floor room (2.5) shows floor 2", Title_CardText(Title_CardModel({ status: "ok", run: { gold: 0, floor: 2.5, statData: { selected_class: CLASS_KNIGHT } } })).rows[0].value, "2");
    Test_Eq("D128 card: no gold in the save is 0", Title_CardText(Title_CardModel({ status: "ok", run: { floor: 1, statData: { selected_class: CLASS_KNIGHT } } })).rows[1].value, "0");
    Test_Eq("D128 card: no floor drops the floor row", array_length(Title_CardText(Title_CardModel({ status: "ok", run: { gold: 9, floor: 0, statData: { selected_class: CLASS_KNIGHT } } })).rows), 1);
    var _run_t = { gold: 1, floor: 3, play_ms: 3725000, statData: { selected_class: CLASS_MAGE } };
    var _tt = Title_CardText(Title_CardModel({ status: "ok", run: _run_t }));
    Test_Eq("D128 card: a tracked play time adds a third row", array_length(_tt.rows), 3);
    Test_Eq("D128 card: play time reads h:mm:ss", _tt.rows[2].value, "1:02:05");
    Test_Eq("D128 time: under an hour reads m:ss", Title_FormatTime(125000), "2:05");
    Test_Eq("D128 time: zero", Title_FormatTime(0), "0:00");
    Test_Eq("D128 card: no run, no card", Title_CardModel({ status: "missing", run: undefined }).kind, "none");
    var _bad = ["old", "newer", "corrupt"];
    for (var _k = 0; _k < 3; _k++) {
        var _mb = Title_CardModel({ status: _bad[_k], run: undefined });
        Test_Eq("D128 card: a " + _bad[_k] + " save says it cannot continue", _mb.kind, "cant");
        var _tb = Title_CardText(_mb);
        Test_Eq("D128 card: " + _bad[_k] + " shows the short line", _tb.title, "Can't continue");
        Test_Eq("D128 card: " + _bad[_k] + " has no rows", array_length(_tb.rows), 0);
    }
    Test_Eq("D128 card text: nothing for no card", Title_CardText(Title_CardModel({ status: "missing", run: undefined })).title, "");

    // where the card goes: beside the menu when it fits, else under it, else above it
    var _pl1 = Title_CardPlace({ x: 20, y: 100, w: 120, h: 100 }, 480, 432, 9, 140, 70);
    Test_Eq("D128 card place: beside the menu when it fits (x)", _pl1.x, 149);
    Test_Eq("D128 card place: beside the menu when it fits (y)", _pl1.y, 100);
    var _pl2 = Title_CardPlace({ x: 150, y: 100, w: 180, h: 150 }, 480, 432, 9, 140, 70);
    Test_Eq("D128 card place: too wide for the side goes under the menu (y)", _pl2.y, 259);
    Test_Eq("D128 card place: under the menu is centred on it (x)", _pl2.x, 170);
    var _pl3 = Title_CardPlace({ x: 150, y: 260, w: 180, h: 150 }, 480, 432, 9, 140, 70);
    Test_Eq("D128 card place: no room under the menu goes above it (y)", _pl3.y, 181);

    // reading the card from a file does not apply the run
    var _gs = GameState_Get();
    var _had_run = variable_struct_exists(_gs, "run");
    var _old_run = _had_run ? _gs.run : undefined;
    var _old_class = _gs.selected_class;
    _gs.run = Run_Create(777);
    _gs.run.gold = 11;
    var _f = "test_title_card.sav";
    Test_RawWrite(_f, json_stringify({ run_version: RUN_SAVE_VERSION, seed: 99, gold: 250, floor: 6, rng: {}, started_at: 0, statData: { selected_class: CLASS_MAGE } }));
    var _m_file = Title_CardLoad(_f);
    Test_Eq("D128 card: read from a file, the class", Title_CardText(_m_file).title, "Mage");
    Test_Eq("D128 card: read from a file, the gold", Title_CardText(_m_file).rows[1].value, "250");
    Test_Eq("D128 card: reading does not touch the live run's gold", _gs.run.gold, 11);
    Test_Eq("D128 card: reading does not touch the live run's seed", _gs.run.seed, 777);
    Test_Eq("D128 card: reading does not change the class", _gs.selected_class, _old_class);
    if (file_exists(_f)) file_delete(_f);
    Test_Eq("D128 card: a missing file is no card", Title_CardLoad("test_title_card_missing.sav").kind, "none");
    if (_had_run) _gs.run = _old_run; else variable_struct_remove(_gs, "run");

    // Korean: the card and the prompt use the Korean strings
    Loc_SetLanguage("ko");
    Test_Eq("D128 ko: the Continue card class is Korean", Title_CardText(Title_CardModel({ status: "ok", run: _run })).title, Loc_T("class.name.class_archer", "Archer"));
    Test_True("D128 ko: the prompt is not the English one", Title_SplashPrompt("keyboard") != "Press any key");
    Test_True("D128 ko: the cannot-continue line is not the English one", Title_CardText(Title_CardModel({ status: "corrupt", run: undefined })).title != "Can't continue");
    Loc_SetLanguage(_lang0);
}
