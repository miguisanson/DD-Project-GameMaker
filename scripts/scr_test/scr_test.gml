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
    Test_RunSuite("Qte", Test_Suite_Qte);
    Test_RunSuite("QteArrows", Test_Suite_QteArrows);
    Test_RunSuite("QteDefence", Test_Suite_QteDefence);
    Test_RunSuite("Status", Test_Suite_Status);
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
    Test_RunSuite("Save", Test_Suite_Save); // last: Save_ApplySnapshot replaces global state
    Test_RunSuite("Mem", Test_Suite_Mem);
    Test_RunSuite("Input", Test_Suite_Input);
    Test_RunSuite("SfxInit", Test_Suite_SfxInit);
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
    Test_ClassAt("vec cls_knight_1", CLASS_KNIGHT, 1, 11, 12, 8, 3, 10, 11);
    Test_ClassAt("vec cls_knight_2", CLASS_KNIGHT, 2, 12, 14, 8, 3, 17, 12);
    Test_ClassAt("vec cls_knight_3", CLASS_KNIGHT, 3, 13, 16, 8, 3, 24, 13);
    Test_ClassAt("vec cls_knight_5", CLASS_KNIGHT, 5, 15, 20, 8, 3, 38, 15);
    Test_ClassAt("vec cls_knight_10", CLASS_KNIGHT, 10, 20, 30, 8, 3, 73, 20);
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
    Test_ClassAt("vec cls_nobody_2", CLASS_NOBODY, 2, 10, 8, 9, 3, 16, 12);
    Test_ClassAt("vec cls_nobody_3", CLASS_NOBODY, 3, 11, 9, 9, 3, 22, 13);
    Test_ClassAt("vec cls_nobody_5", CLASS_NOBODY, 5, 13, 9, 10, 4, 34, 16);
    Test_ClassAt("vec cls_nobody_10", CLASS_NOBODY, 10, 20, 10, 11, 5, 64, 21);
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
    Test_EnemyAt("vec en_palehorn_8", ENEMY_MINI_BOSS, 8, 18, 16, 12, 14, 67);
    Test_EnemyAt("vec en_choirbeast_10", ENEMY_FINAL_BOSS, 10, 21, 18, 14, 19, 88);
    Test_Eq("vec run_8_9", Battle_RunChance(8, 9), 0.45);
    Test_Eq("vec run_13_9", Battle_RunChance(13, 9), 0.7);
    Test_Eq("vec run_30_5", Battle_RunChance(30, 5), 0.95);
    Test_Eq("vec run_1_40", Battle_RunChance(1, 40), 0.1);
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
    Test_False("STAT-01 SPD decides who acts first (Knight 8 vs Slime 9)", Combat_PlayerActsFirst(Combat_EffectiveStat(_lo, STAT_SPD), Combat_EffectiveStat(EnemyCreate(ENEMY_SLIME), STAT_SPD)));
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
    Test_Eq("Level_ApplyFreePoint adds +1 to the chosen stat", _c2.stats.spd, 9);
    Test_Eq("Level_ApplyFreePoint spends the point", _c2.stat_points, 0);
    var _c3 = Level_ApplyFreePoint(_c2, STAT_SPD);
    Test_Eq("Level_ApplyFreePoint with no points left changes nothing", _c3.stats.spd, 9);
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
    Test_Eq("Tooltip_StatShortName(STAT_MAG) == MAG", Tooltip_StatShortName(STAT_MAG), "MAG");
    Test_Eq("Tooltip_StatShortName(STAT_SPD) == SPD", Tooltip_StatShortName(STAT_SPD), "SPD");
    Test_Eq("Tooltip_ItemBonusText(Platinum Armor) == DEF +3", Tooltip_ItemBonusText(ItemDB_Get(22)), "DEF +3");
    Test_Eq("Tooltip_ItemBonusText(Mithril Robe) == MAG +3", Tooltip_ItemBonusText(ItemDB_Get(25)), "MAG +3");
    Test_Eq("Tooltip_BuildStatLines gives a title and a description", array_length(Tooltip_BuildStatLines("spd", "SPD", 8)), 2);
    var _cp = Menu_StatsCopy(_k.stats);
    Test_Eq("Menu_StatsCopy copies the four stats", _cp.atk + _cp.def + _cp.spd + _cp.mag, 11 + 12 + 8 + 3);
    // Enemies carry the same four stats and a basic power by rank (spec section 6).
    var _sl = EnemyCreate(ENEMY_SLIME);
    Test_False("STAT-01 enemies have no luck/intt", variable_struct_exists(_sl.stats, "luck") || variable_struct_exists(_sl.stats, "intt"));
    Test_Eq("Enemy basic power: Slime (rank 1) = 3", _sl.basic_power, 3);
    Test_Eq("Enemy basic power: Mad Whisp (rank 2) = 5", EnemyCreate(ENEMY_MADWHISP).basic_power, 5);
    Test_Eq("Enemy basic power: Palehorn (rank 3) = 7", EnemyCreate(ENEMY_MINI_BOSS).basic_power, 7);
    Test_Eq("Enemy basic power: Pale Choirbeast (rank 4) = 9", EnemyCreate(ENEMY_FINAL_BOSS).basic_power, 9);
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
    global.difficulty = _gs.difficulty;
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

// Combat formulas (combat-spec.md sections 1, 4, 5). Start values: Knight ATK11 DEF12 HP10; Slime ATK8 DEF7 HP9 basic power 3 (rank 1);
// Pale Choirbeast (final boss, L10) ATK21 DEF18 HP88; Mage MAG12 ATK5. A Test_Wpn power is the FINAL formula power (spec section 4).
// No dice anywhere (D80): the only avoidance is Evasion on the player. Expected values are worked out from the spec, not read from the code.
function Test_Suite_Combat() {
    var _k = Test_Hero(CLASS_KNIGHT);
    var _m = CharacterCreate_Player(CLASS_MAGE);
    var _slime = EnemyCreate(ENEMY_SLIME);
    var _boss = EnemyCreate(ENEMY_FINAL_BOSS);
    // Combat_Damage = the grade-OK ratio damage of one hit, no statuses: round_half_up(power x A / (A + D)), at least 1.
    Test_Eq("Combat_Damage knight(ATK11) power6 vs slime(DEF7) == 4", Combat_Damage(_k, _slime, Test_Wpn(6, STAT_ATK, 0)), 4);
    Test_Eq("Combat_Damage slime basic(power3,ATK8) vs knight(DEF12) == 1", Combat_Damage(_slime, _k, Test_Wpn(3, STAT_ATK, 0)), 1);
    Test_Eq("Combat_Damage never below 1 (power1 slime vs boss DEF18)", Combat_Damage(_slime, _boss, Test_Wpn(1, STAT_ATK, 0)), 1);
    Test_Eq("Combat_Damage uses the weapon stat: mage MAG12 power6 vs slime == 4", Combat_Damage(_m, _slime, Test_Wpn(6, STAT_MAG, 0)), 4);
    Test_Eq("Combat_Damage uses the weapon stat: mage ATK5 power6 vs slime == 3", Combat_Damage(_m, _slime, Test_Wpn(6, STAT_ATK, 0)), 3);
    Test_Eq("Combat_Damage a stronger ATK hits harder: boss ATK21 power9 vs knight DEF12 == 6", Combat_Damage(_boss, _k, Test_Wpn(9, STAT_ATK, 0)), 6);
    // Statuses change the effective stat: Poison MAG-1 (power20: MAG12 -> 13, MAG11 -> 12); Burning ATK-1.
    Test_Eq("Combat_Damage mage MAG12 power20 vs slime == 13", Combat_Damage(_m, _slime, Test_Wpn(20, STAT_MAG, 0)), 13);
    _m = Status_Add(_m, STATUS_POISON, 3, 0);
    Test_Eq("Combat_EffectiveStat mage poisoned MAG == 11", Combat_EffectiveStat(_m, STAT_MAG), 11);
    Test_Eq("Combat_Damage mage poisoned (MAG11) power20 vs slime == 12", Combat_Damage(_m, _slime, Test_Wpn(20, STAT_MAG, 0)), 12);
    var _burnt = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_BURN, 2, 0);
    Test_Eq("Combat_EffectiveStat knight burning ATK == 10", Combat_EffectiveStat(_burnt, STAT_ATK), 10);
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
    Test_Eq("boss max_hp (L10) == 88", _boss.max_hp, 88);
    Test_Eq("Combat_ApplyDamage crit x2: power12 vs boss(DEF18) == 9", Combat_ApplyDamage(_k, _boss, Test_Wpn(12, STAT_ATK, 0), 2).dmg, 9);
    Test_Eq("Combat_ApplyDamage boss hp 88 -> 79", _boss.hp, 79);
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

// D55 / I-052: every player skill animation plays in at most 0.75 s (45 game frames at 60 fps; with the 0.3 s hold that is under the 66-frame
// action limit) and is drawn no bigger than 1.5 x its target's longest side and 64 world px (the screen is 160 x 144), whatever enemy it hits.
// Limits are the owner's numbers written out here, not read from the macros.
function Test_Suite_Fx() {
    var _ids = Skill_PlayerFxIds();
    Test_Eq("Fx: 14 player skills have an animation", array_length(_ids), 14);
    var _targets = [32, 48, 64];   // slime-sized enemies, the mini boss, the final boss; 32 is also the player's reference size
    for (var _i = 0; _i < array_length(_ids); _i++) {
        var _s = SkillDB_Get(_ids[_i]);
        var _frames = FX_PlaybackFrames(_s.fx_sprite, Skill_FxSpeed(_s, true));
        Test_True("D55 " + _s.name + " animation <= 45 frames (got " + string(_frames) + ")", _frames <= 45);
        var _side = max(sprite_get_width(_s.fx_sprite), sprite_get_height(_s.fx_sprite));
        for (var _t = 0; _t < array_length(_targets); _t++) {
            var _drawn = _side * FX_ScaleFor(_s.fx_sprite, _targets[_t]);
            Test_True("I-052 " + _s.name + " vs " + string(_targets[_t]) + " px target: drawn " + string(_drawn) + " px <= 1.5 x target and <= 64",
                _drawn <= _targets[_t] * 1.5 + 0.01 && _drawn <= 64.01);
            Test_True("I-052 " + _s.name + " vs " + string(_targets[_t]) + " px target: drawn " + string(_drawn) + " px >= 32 (still readable)", _drawn >= 32);
        }
    }
    Test_Eq("D55 hold after an action is 18 frames", Combat_SecToFrames(COMBAT_ACTION_HOLD_SEC), 18);
    // The pure helpers themselves: a 48 px sprite at 8 fps, 12 frames... uses the real sprites: ice_spear_effect has 12 frames at 8 fps.
    Test_Eq("Fx: ice spear at image_speed 1 plays 12 frames in 90 game frames", FX_PlaybackFrames(ice_spear_effect, 1), 90);
    Test_Eq("Fx: ice spear at image_speed 2 plays in 45 game frames", FX_PlaybackFrames(ice_spear_effect, 2), 45);
    Test_True("Fx: SpeedForMaxFrames never slows an effect down", FX_SpeedForMaxFrames(ice_spear_effect, 5, 42) == 5);
    Test_True("Fx: SpeedForMaxFrames raises a slow effect to fit", FX_PlaybackFrames(ice_spear_effect, FX_SpeedForMaxFrames(ice_spear_effect, 0.1, 42)) <= 42);
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
    var _big = [SKILL_POISON_FANGS, SKILL_BITE, SKILL_VINE_TRAP, SKILL_SCORCHING_TOUCH, SKILL_GHOST_CUT, SKILL_RAMMING];
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
    var _bit = Qte_DefenceParams(SKILL_BITE);
    Test_True("QteDefence Ramming (mini boss) sweeps slower than every other big attack", _ram.sweep_ms > Qte_DefenceParams(SKILL_VINE_TRAP).sweep_ms && _ram.sweep_ms > _cut.sweep_ms && _ram.sweep_ms > _bit.sweep_ms);
    Test_True("QteDefence Ramming's perfect zone is the narrowest on the bar", _ram.perfect_half_width / _ram.sweep_ms < _cut.perfect_half_width / _cut.sweep_ms && _ram.perfect_half_width / _ram.sweep_ms < _bit.perfect_half_width / _bit.sweep_ms);
    Test_True("QteDefence Ghost Cut sweeps faster than the attack default", _cut.sweep_ms < _def.sweep_ms);
    Test_Eq("QteDefence an attack with no row uses the default bar", Qte_DefenceParams(SKILL_SOLIDIFY).sweep_ms, _def.sweep_ms);
    // only damaging enemy hits on the player that are flagged big get the bar
    var _spider = EnemyCreate(ENEMY_SPIDER);
    var _player = CharacterCreate_Player(CLASS_KNIGHT);
    var _fangs = SkillDB_Get(SKILL_POISON_FANGS);
    Test_True("QteDefence a landed Poison Fangs is defended", Battle_EnemySkillCanBeDefended(_fangs, { ok: true, hit: true, dmg: 3 }, _player));
    Test_False("QteDefence a Poison Fangs that missed is not", Battle_EnemySkillCanBeDefended(_fangs, { ok: true, hit: false, dmg: 0 }, _player));
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

    // the same rule on a real character: Poison applied for 4 turns by the hit
    var _specs = [STATUS_POISON];
    for (var _g2 = 0; _g2 < 4; _g2++) {
        var _p = CharacterCreate_Player(CLASS_KNIGHT);
        var _before = Battle_StatusSnapshot(_p);
        _p = Status_Add(_p, STATUS_POISON, 4, 1);
        var _pack = Battle_DefenceAdjustStatuses(_p, _specs, _before, _keys[_g2]);
        var _after = Battle_StatusCurrentTurns(_pack.player, STATUS_POISON);
        var _want_t = [0, 2, 3, 4][_g2];
        Test_Eq("QteDefence " + _keys[_g2] + ": a 4-turn Poison ends at " + string(_want_t), _after, _want_t);
        if (_g2 == 0) Test_False("QteDefence Perfect: the character is not poisoned at all", Status_Has(_pack.player, STATUS_POISON));
        if (_g2 == 0) Test_True("QteDefence Perfect: the message names what was resisted", string_pos(StatusDB_Get(STATUS_POISON).name, _pack.resist_msg) > 0);
    }
    // a status the player already had keeps its old turns: Perfect puts it back, nothing makes it longer than the hit left it
    var _p2 = CharacterCreate_Player(CLASS_KNIGHT);
    _p2 = Status_Add(_p2, STATUS_POISON, 3, 1);
    var _before2 = Battle_StatusSnapshot(_p2);
    _p2 = Status_Add(_p2, STATUS_POISON, 5, 1);   // the hit refreshed it to 5
    var _pack2 = Battle_DefenceAdjustStatuses(_p2, _specs, _before2, "PERFECT");
    Test_Eq("QteDefence Perfect puts a refreshed Poison back to the 3 turns it had", Battle_StatusCurrentTurns(_pack2.player, STATUS_POISON), 3);
    var _p3 = CharacterCreate_Player(CLASS_KNIGHT);
    _p3 = Status_Add(_p3, STATUS_POISON, 3, 1);
    var _before3 = Battle_StatusSnapshot(_p3);
    _p3 = Status_Add(_p3, STATUS_POISON, 5, 1);
    var _pack3 = Battle_DefenceAdjustStatuses(_p3, _specs, _before3, "WEAK");
    Test_Eq("QteDefence Weak leaves a refreshed Poison at the 5 the hit gave it", Battle_StatusCurrentTurns(_pack3.player, STATUS_POISON), 5);
    // a status the hit did not touch is not touched here
    var _p4 = CharacterCreate_Player(CLASS_KNIGHT);
    _p4 = Status_Add(_p4, STATUS_POISON, 3, 1);
    var _before4 = Battle_StatusSnapshot(_p4);
    var _pack4 = Battle_DefenceAdjustStatuses(_p4, _specs, _before4, "OK");
    Test_Eq("QteDefence a status the hit did not change is left alone", Battle_StatusCurrentTurns(_pack4.player, STATUS_POISON), 3);
}

// Status rules (balance-data.md section 4 "Status effects"; combat-bugs.md section 1; R-005, R-022).
function Test_Suite_Status() {
    var _p = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL); // 10 HP, 10 MP at L1
    Test_Eq("player starts at full HP (10)", _p.hp, _p.max_hp);
    // R-005: a poisoned PLAYER loses 2-3 HP per tick (the friend saw none).
    _p = Status_Add(_p, STATUS_POISON, 3, 0);
    Test_True("Status_Has Poison after Status_Add", Status_Has(_p, STATUS_POISON));
    Test_True("Status_CanAct while poisoned", Status_CanAct(_p));
    var _hp0 = _p.hp;
    _p = Status_Tick(_p);
    Test_True("R-005 player poison tick costs 2-3 HP", (_hp0 - _p.hp) >= 2 && (_hp0 - _p.hp) <= 3);
    Test_Eq("poison turns 3 -> 2 after one tick", _p.status[0].turns, 2);
    _p = Status_Tick(_p);
    _p = Status_Tick(_p);
    Test_True("R-005 three ticks cost 6-9 HP in total", (_hp0 - _p.hp) >= 6 && (_hp0 - _p.hp) <= 9);
    Test_False("poison is removed when its turns reach 0", Status_Has(_p, STATUS_POISON));
    // BUG-08: a poison tick on the player must be seen and heard (log line, sound, HUD flash), not just change the HP number.
    var _fp = Status_Add(Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL), STATUS_POISON, 3, 0);
    var _fhp = _fp.hp;
    global.status_tick_last = undefined;
    _fp = Status_Tick(_fp);
    var _fb = variable_global_exists("status_tick_last") ? global.status_tick_last : undefined;
    Test_True("BUG-08 player poison tick raises feedback", is_struct(_fb));
    Test_True("BUG-08 tick log line names Poison and the HP lost", is_struct(_fb) && string_pos("Poison", _fb.line) > 0 && string_pos(string(_fhp - _fp.hp), _fb.line) > 0);
    Test_True("BUG-08 tick plays a sound", is_struct(_fb) && _fb.sfx != "");
    Test_True("BUG-08 tick flashes the HP bar", is_struct(_fb) && _fb.flash_frames > 0);
    global.status_tick_last = undefined;
    var _fe = Status_Tick(Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_POISON, 2, 0));
    Test_True("BUG-08 an enemy poison tick raises no player feedback", !(variable_global_exists("status_tick_last") && is_struct(global.status_tick_last)));
    global.status_tick_last = undefined;
    var _fm = Status_Tick(Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_MEDITATION, 2, 0));
    Test_True("BUG-08 a healing tick (Meditation) raises no damage feedback", !(variable_global_exists("status_tick_last") && is_struct(global.status_tick_last)));
    // HP and MP clamp to [0, max].
    var _low = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL);
    _low.hp = 1;
    _low = Status_Tick(Status_Add(_low, STATUS_BURN, 2, 0));
    Test_Eq("burn tick clamps HP at 0", _low.hp, 0);
    var _med = Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_MEDITATION, 3, 0);
    _med.mp = _med.max_mp - 1;
    _med = Status_Tick(_med);
    Test_Eq("meditation tick clamps MP at max", _med.mp, _med.max_mp);
    _med.mp = 0;
    _med = Status_Tick(_med);
    Test_True("meditation tick restores 2-4 MP", _med.mp >= 2 && _med.mp <= 4);
    // Non-stackable re-apply refreshes to the longer duration; DoTs exclude each other.
    var _r = CharacterCreate_Player(CLASS_KNIGHT);
    _r = Status_Add(_r, STATUS_POISON, 2, 0);
    _r = Status_Add(_r, STATUS_POISON, 4, 0);
    _r = Status_Add(_r, STATUS_POISON, 1, 0);
    Test_Eq("non-stackable status keeps one entry", array_length(_r.status), 1);
    Test_Eq("non-stackable refresh keeps the longest duration (4)", _r.status[0].turns, 4);
    _r = Status_Add(_r, STATUS_BURN, 2, 0);
    Test_True("applying Burn removes Poison", Status_Has(_r, STATUS_BURN) && !Status_Has(_r, STATUS_POISON));
    _r = Status_Add(_r, STATUS_BLEED, 2, 0);
    Test_True("applying Bleeding removes Burn", Status_Has(_r, STATUS_BLEED) && !Status_Has(_r, STATUS_BURN));
    // Stat mods (renamed, same size): Poison MAG-1, Bleeding SPD-2, Burning ATK-1, Stun SPD-2, Sundered DEF-1.
    Test_Eq("Poison gives MAG-1", Status_ModStat(Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_POISON, 2, 0), STAT_MAG), -1);
    Test_Eq("Bleeding gives SPD-2", Status_ModStat(_r, STAT_SPD), -2);
    Test_Eq("Burning gives ATK-1", Status_ModStat(Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_BURN, 2, 0), STAT_ATK), -1);
    // Stun: skip_turn; the player's stun is capped at 1 turn and ignored during the 2-turn immunity window.
    var _s = CharacterCreate_Player(CLASS_KNIGHT);
    Test_True("Status_CanAct on a clean character", Status_CanAct(_s));
    _s = Status_Add(_s, STATUS_STUN, 3, 0);
    Test_False("Status_CanAct false while stunned", Status_CanAct(_s));
    Test_Eq("player stun capped to 1 turn", _s.status[0].turns, 1);
    _s = Status_Tick(_s);
    Test_True("stun expires after its tick, player can act", !Status_Has(_s, STATUS_STUN) && Status_CanAct(_s));
    var _imm = CharacterCreate_Player(CLASS_KNIGHT);
    _imm.stun_immune_turns = 2;
    _imm = Status_Add(_imm, STATUS_STUN, 1, 0);
    Test_False("stun ignored while stun_immune_turns > 0", Status_Has(_imm, STATUS_STUN));
    _imm = Status_Tick(_imm);
    Test_Eq("stun_immune_turns decays by 1 per tick", _imm.stun_immune_turns, 1);
    var _foe = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_STUN, 3, 0);
    Test_Eq("enemy stun is not capped (3)", _foe.status[0].turns, 3);
    Test_True("Guard does not stop the owner acting", Status_CanAct(Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_GUARD, 2, 0)));
}

// Inventory rules (balance-data.md section 6; combat-bugs.md section 4; R-003 skill books appear twice).
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
    // One-copy rule: weapons, armor and skill books are never duplicated.
    Test_Eq("weapon (Iron Sword 2) added twice -> 1 copy", array_length(Inv_Add(Inv_Add([], 2, 1), 2, 1)), 1);
    Test_Eq("weapon qty 3 in one call -> 1 copy", array_length(Inv_Add([], 2, 3)), 1);
    Test_Eq("armor (Leather Armor 20) added twice -> 1 copy", array_length(Inv_Add(Inv_Add([], 20, 1), 20, 1)), 1);
    var _book = Inv_Add(Inv_Add([], 114, 1), 114, 1);
    Test_Eq("R-003 skill book 114 added twice -> listed once", array_length(Inv_GetItems(_book)), 1);
    Test_Eq("R-003 skill book 114 qty stays 1", _book[0].qty, 1);
    // A book for a skill the player already knows is refused.
    var _gs = GameState_Get();
    _gs.player_ch.skills = [SKILL_WOUND];
    Test_Eq("book for an already-known skill is not added", array_length(Inv_Add([], 101, 1)), 0);
    _gs.player_ch.skills = [];
    // R-003: a duplicate that got in (old save) must still show once in the listing.
    var _dup = [{ id: 114, qty: 1 }, { id: 114, qty: 1 }];
    Test_Eq("R-003 Menu_InventoryDisplayItems shows a pushed duplicate book once", array_length(Menu_InventoryDisplayItems(_dup)), 1);
}

// Data integrity over the GML databases (VER-11; R-003, R-004). ds_map_add silently drops a repeated key, so a
// duplicate id shows up as a wrong record count; counts come from balance-data.md (37 items, 27 skills, 14 statuses, 10 enemies).
function Test_Suite_Data() {
    GameState_Get();
    ItemDB_Init(); SkillDB_Init(); StatusDB_Init(); EnemyDB_Init(); Loot_Init();
    Test_Eq("item count == 37 (no lost duplicate ids)", ds_map_size(global.item_db), 37);
    Test_Eq("skill count == 27", ds_map_size(global.skill_db), 27);
    Test_Eq("status count == 14", ds_map_size(global.status_db), 14);
    Test_Eq("enemy count == 10", ds_map_size(global.enemy_db), 10);
    var _bad = 0; var _names = {}; var _dupnames = 0; var _book_skills = {}; var _dupbooks = 0; var _books = 0;
    var _key = ds_map_find_first(global.item_db);
    while (!is_undefined(_key)) {
        var _it = ItemDB_Get(_key);
        if (_it.id != _key) _bad++;
        if (variable_struct_exists(_names, string(_it.name))) _dupnames++;
        variable_struct_set(_names, string(_it.name), true);
        if (_it.use.status != -1 && StatusDB_Get(_it.use.status).id != _it.use.status) _bad++;
        if (Item_IsSkillbook(_it)) {
            _books++;
            if (SkillDB_Get(_it.use.skill_id).id != _it.use.skill_id) _bad++;
            if (variable_struct_exists(_book_skills, string(_it.use.skill_id))) _dupbooks++;
            variable_struct_set(_book_skills, string(_it.use.skill_id), true);
        }
        _key = ds_map_find_next(global.item_db, _key);
    }
    Test_Eq("every item id matches its record; item statuses and book skills resolve", _bad, 0);
    Test_Eq("R-003 no two items share a display name", _dupnames, 0);
    Test_Eq("14 skill books exist", _books, 14);
    Test_Eq("R-003 no two skill books teach the same skill", _dupbooks, 0);
    var _classes = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE];
    for (var _c = 0; _c < 3; _c++) {
        var _list = Loot_SkillbookList(_classes[_c]);
        var _seen = {}; var _dups = 0;
        for (var _i = 0; _i < array_length(_list); _i++) {
            if (variable_struct_exists(_seen, string(_list[_i]))) _dups++;
            variable_struct_set(_seen, string(_list[_i]), true);
        }
        Test_Eq("R-003 class " + string(_classes[_c]) + " skill book pool has 5 distinct books", array_length(_list) - _dups, 5);
    }
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
}

// -exportdata (B1, spec section 9): the data the simulator reads. Built in memory here (the real file is written and re-read by `-Only exportdata`).
function Test_Suite_Export() {
    var _d = Export_Build();
    var _back = json_parse(json_stringify(_d));
    Test_True("Export: the data survives a JSON round trip", is_struct(_back) && _back.version == 1);
    Test_Eq("Export: 4 classes", array_length(_back.classes), 4);
    Test_Eq("Export: 10 enemies", array_length(_back.enemies), 10);
    Test_Eq("Export: 27 skills", array_length(_back.skills), 27);
    Test_Eq("Export: 37 items", array_length(_back.items), 37);
    Test_Eq("Export: 14 statuses", array_length(_back.statuses), 14);
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
    Test_Eq("Export: the final boss exports its basic power (9)", _back.enemies[9].basic_power, 9);
    Test_False("Export: no asset references leak into the data", string_pos("sprite", json_stringify(_back.enemies)) > 0);
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
    _p = Status_Add(_p, STATUS_POISON, 3, 0);
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
    Test_True("R-008 round trip keeps Poison with 3 turns", Status_Has(_r, STATUS_POISON) && _r.status[0].turns == 3);
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

// D48 / I-055: hold-to-skip. Skip_Step is the pure core: a fresh press arms it, holding confirm for SKIP_HOLD_FRAMES fires it, a tap never does.
function Test_Suite_Skip() {
    var _st = Skip_StateNew();
    var _r = Skip_Step(_st, true, true, true);   // first frame: pressed and held
    Test_Eq("D48 first press: not fired", _r.fired, false);
    Test_Eq("D48 first press: shows the hint", _r.hint > 0, true);
    Test_Eq("D48 first press: progress started", _r.held_frames, 1);
    _st = _r;
    for (var _i = 2; _i < SKIP_HOLD_FRAMES; _i++) {
        _st = Skip_Step(_st, true, false, true);
        if (_st.fired) break;
    }
    Test_Eq("D48 held for one frame less than the hold time: not fired", _st.fired, false);
    _st = Skip_Step(_st, true, false, true);
    Test_Eq("D48 held for the whole hold time: fires", _st.fired, true);
    Test_Eq("D48 firing resets the hold", _st.held_frames, 0);

    // A tap (a few frames, then released) never skips and the count restarts on the next press.
    _st = Skip_StateNew();
    _st = Skip_Step(_st, true, true, true);
    _st = Skip_Step(_st, true, false, true);
    _st = Skip_Step(_st, true, false, true);
    _st = Skip_Step(_st, true, false, false);   // released
    Test_Eq("D48 tap: not fired", _st.fired, false);
    Test_Eq("D48 tap: hold count back to 0", _st.held_frames, 0);
    Test_Eq("D48 tap: hint stays on screen for a while", _st.hint > 0, true);
    var _fired = false;
    for (var _i = 0; _i < SKIP_HOLD_FRAMES * 3; _i++) {   // many taps, one every 10 frames
        _st = Skip_Step(_st, true, (_i mod 10) == 0, (_i mod 10) < 3);
        if (_st.fired) _fired = true;
    }
    Test_Eq("D48 repeated taps never skip", _fired, false);

    // A key already held when the scene starts (no new press) never skips.
    _st = Skip_StateNew();
    _fired = false;
    for (var _i = 0; _i < SKIP_HOLD_FRAMES * 2; _i++) {
        _st = Skip_Step(_st, true, false, true);
        if (_st.fired) _fired = true;
    }
    Test_Eq("D48 a key held from before the scene does not skip", _fired, false);

    // Not allowed (no skippable scene): everything resets.
    _st = Skip_Step(Skip_StateNew(), true, true, true);
    _st = Skip_Step(_st, false, false, true);
    Test_Eq("D48 leaving the scene resets the count", _st.held_frames, 0);
    Test_Eq("D48 leaving the scene hides the hint", _st.hint, 0);

    // The hint fades after SKIP_HINT_FRAMES without a press.
    _st = Skip_Step(Skip_StateNew(), true, true, true);
    _st = Skip_Step(_st, true, false, false);
    for (var _i = 0; _i < SKIP_HINT_FRAMES + 2; _i++) _st = Skip_Step(_st, true, false, false);
    Test_Eq("D48 the hint goes away", _st.hint, 0);
    Test_Eq("D48 progress fraction", Skip_Fraction(SKIP_HOLD_FRAMES div 2), 0.5);
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
    Test_Eq("DISP-14 written settings_version", _raw.settings_version, 8);
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
    Loot_BuildSkillbookLists();
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
}
