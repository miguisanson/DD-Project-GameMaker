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
    Test_RunSuite("Combat", Test_Suite_Combat);
    Test_RunSuite("Status", Test_Suite_Status);
    Test_RunSuite("Inventory", Test_Suite_Inventory);
    Test_RunSuite("Data", Test_Suite_Data);
    Test_RunSuite("Save", Test_Suite_Save); // last: Save_ApplySnapshot replaces global state
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

// Pure stat/level functions. Expected values come from the documented rules
// (.planning/research/audit/balance-data.md sections 2-3, audit/data/progression.csv), not from running the code.
function Test_Suite_Math() {
    // StatMod = floor((stat - 10) / 2), D&D style.
    Test_Eq("StatMod(10)==0", StatMod(10), 0);
    Test_Eq("StatMod(12)==1", StatMod(12), 1);
    Test_Eq("StatMod(9)==-1", StatMod(9), -1);
    Test_Eq("StatMod(20)==5", StatMod(20), 5);
    // StatClamp keeps stats in 1..60.
    Test_Eq("StatClamp(0)==1", StatClamp(0), 1);
    Test_Eq("StatClamp(99)==60", StatClamp(99), 60);
    // HP per level = ceil(hd/2)+2: Knight hd10 -> 7, Archer hd8 -> 6, Mage hd6 -> 5.
    Test_Eq("HPGainPerLevel(10)==7", HPGainPerLevel(10), 7);
    Test_Eq("HPGainPerLevel(8)==6", HPGainPerLevel(8), 6);
    Test_Eq("HPGainPerLevel(6)==5", HPGainPerLevel(6), 5);
    // EXP curve: 15,30,50,75,105,140,180,225,275 (L1..L9), 0 at the cap; cumulative to L10 = 1095.
    Test_Eq("Exp_NextLevel(1)==15", Exp_NextLevel(1), 15);
    Test_Eq("Exp_NextLevel(9)==275", Exp_NextLevel(9), 275);
    Test_Eq("Exp_NextLevel(10)==0", Exp_NextLevel(10), 0);
    var _cum = 0;
    for (var _l = 1; _l < 10; _l++) _cum += Exp_NextLevel(_l);
    Test_Eq("EXP cumulative L1..L10==1095", _cum, 1095);
    // Level cap is 10; MP stat weight = 1 + floor((lvl-1)/4).
    Test_True("Level_IsAtCap(10)", Level_IsAtCap(10));
    Test_Eq("ResourceStatWeight(5)==2", ResourceStatWeight(5), 2);
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
function Test_Hero(_class, _diff) {
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

// Combat formulas (balance-data.md section 7). Start stats (class bonus on base 10): Knight STR11 DEF12, Archer AGI12,
// Mage INT12; Slime STR8 AGI9 DEF7 HP9; Pale Choirbeast (final boss, L10) STR21 DEF18 HP88.
// No dice: Combat_AttemptHit is only asserted for the deterministic force_dodge / always_hit branches.
// R-031 will remove difficulty; the Hard/Easy rows then go away (D35).
function Test_Suite_Combat() {
    var _k = Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL);
    var _a = CharacterCreate_Player(CLASS_ARCHER);
    var _m = CharacterCreate_Player(CLASS_MAGE);
    var _slime = EnemyCreate(ENEMY_SLIME);
    var _boss = EnemyCreate(ENEMY_FINAL_BOSS);
    // Damage = max(1, power + StatMod(atk stat) - floor(StatMod(def DEF)/2)); low DEF gives bonus damage.
    Test_Eq("Combat_Damage knight(STR11) pow3 vs slime(DEF7) == 4", Combat_Damage(_k, _slime, Test_Wpn(3, STAT_STR, 0)), 4);
    Test_Eq("Combat_Damage slime basic(pow2,STR8) vs knight(DEF12) == 1", Combat_Damage(_slime, _k, Test_Wpn(2, STAT_STR, 0)), 1);
    Test_Eq("Combat_Damage never below 1 (pow1 slime vs boss DEF18)", Combat_Damage(_slime, _boss, Test_Wpn(1, STAT_STR, 0)), 1);
    Test_Eq("Combat_Damage uses weapon stat: mage INT12 pow5 vs slime == 7", Combat_Damage(_m, _slime, Test_Wpn(5, STAT_INT, 0)), 7);
    Test_Eq("Combat_Damage uses weapon stat: mage STR10 pow5 vs slime == 6", Combat_Damage(_m, _slime, Test_Wpn(5, STAT_STR, 0)), 6);
    // Attack bonus = StatMod(weapon stat) + weapon.acc; statuses change stats (Poison INT-1).
    Test_Eq("Combat_AttackBonus knight STR11 acc2 == 2", Combat_AttackBonus(_k, Test_Wpn(0, STAT_STR, 2)), 2);
    Test_Eq("Combat_AttackBonus archer AGI12 acc1 == 2", Combat_AttackBonus(_a, Test_Wpn(0, STAT_AGI, 1)), 2);
    Test_Eq("Combat_AttackBonus mage INT12 acc0 == 1", Combat_AttackBonus(_m, Test_Wpn(0, STAT_INT, 0)), 1);
    _m = Status_Add(_m, STATUS_POISON, 3, 0);
    Test_Eq("Combat_AttackBonus mage poisoned (INT-1) == 0", Combat_AttackBonus(_m, Test_Wpn(0, STAT_INT, 0)), 0);
    // Dodge bonus = StatMod(AGI) (+ dodge_bonus from statuses, which no status defines).
    Test_Eq("Combat_DodgeBonus knight AGI10 == 0", Combat_DodgeBonus(_k), 0);
    Test_Eq("Combat_DodgeBonus archer AGI12 == 1", Combat_DodgeBonus(_a), 1);
    Test_Eq("Combat_DodgeBonus slime AGI9 == -1", Combat_DodgeBonus(_slime), -1);
    _a = Status_Add(_a, STATUS_BLEED, 3, 0);
    Test_Eq("Combat_DodgeBonus archer bleeding (AGI-2) == 0", Combat_DodgeBonus(_a), 0);
    // Hit rules: force_dodge (Evasion, Solidify) is consumed and beats always_hit (Foresight); Foresight alone always hits.
    var _evader = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_EVASION, 3, 0);
    var _r = Combat_AttemptHit(_k, _evader, 0);
    Test_False("Combat_AttemptHit Evasion defender -> miss", _r.hit);
    Test_False("Combat_AttemptHit Evasion is consumed", Status_Has(_evader, STATUS_EVASION));
    var _solid = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_SOLIDIFY, 2, 0);
    Test_False("Combat_AttemptHit Solidify defender -> miss", Combat_AttemptHit(_k, _solid, 0).hit);
    var _seer = Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_HIT_UP, 9, 0);
    Test_True("Combat_AttemptHit Foresight attacker always hits", Combat_AttemptHit(_seer, EnemyCreate(ENEMY_SLIME), -99).hit);
    var _both = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_EVASION, 3, 0);
    Test_False("Combat_AttemptHit Evasion beats Foresight", Combat_AttemptHit(_seer, _both, 0).hit);
    // ApplyDamage order: dmg_mult, skill_mult, crit, guard_mult, difficulty; result clamps HP at 0.
    Test_Eq("slime max_hp (L1) == 9", _slime.max_hp, 9);
    Test_Eq("Combat_ApplyDamage knight pow3 vs slime dealt 4", Test_Hit(_k, _slime, Test_Wpn(3, STAT_STR, 0)).dmg, 4);
    Test_Eq("Combat_ApplyDamage slime hp 9 -> 5", _slime.hp, 5);
    var _rev = Status_Add(CharacterCreate_Player(CLASS_KNIGHT), STATUS_DMG_UP, 6, 0);
    Test_Eq("Combat_ApplyDamage Rev Up doubles 4 -> 8", Test_Hit(_rev, EnemyCreate(ENEMY_SLIME), Test_Wpn(3, STAT_STR, 0)).dmg, 8);
    var _guarded = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_GUARD, 6, 0);
    Test_Eq("Combat_ApplyDamage Guard blocks the hit (0)", Test_Hit(_k, _guarded, Test_Wpn(3, STAT_STR, 0)).dmg, 0);
    Test_Eq("Combat_ApplyDamage Guard leaves HP untouched", _guarded.hp, _guarded.max_hp);
    Test_False("Combat_ApplyDamage Guard is consumed by the hit", Status_Has(_guarded, STATUS_GUARD));
    var _blessed = Status_Add(EnemyCreate(ENEMY_SLIME), STATUS_BLESSING, 4, 0);
    Test_Eq("Combat_ApplyDamage Blessing x0.8: 4 -> 3", Test_Hit(_k, _blessed, Test_Wpn(3, STAT_STR, 0)).dmg, 3);
    Test_Eq("boss max_hp (L10) == 88", _boss.max_hp, 88);
    Test_Eq("Combat_ApplyDamage skill x1.5 then crit x2: 4 -> 6 -> 12", Combat_ApplyDamage(_k, _boss, Test_Wpn(6, STAT_STR, 0), 2, 1.5).dmg, 12);
    Test_Eq("Combat_ApplyDamage boss hp 88 -> 76", _boss.hp, 76);
    var _tiny = EnemyCreate(ENEMY_SLIME);
    Test_Hit(_k, _tiny, Test_Wpn(100, STAT_STR, 0));
    Test_Eq("Combat_ApplyDamage HP clamps at 0, never negative", _tiny.hp, 0);
    // Difficulty (Difficulty_Profile), floored: player dmg Hard x0.94 / Easy x1.08; enemy dmg Hard x1.12 / Easy x0.9.
    var _pw = Test_Wpn(3, STAT_STR, 0);
    var _ew = Test_Wpn(4, STAT_STR, 0);
    Test_Hero(CLASS_KNIGHT, DIFFICULTY_HARD);
    Test_Eq("Hard: player dmg floor(4*0.94) == 3", Test_Hit(CharacterCreate_Player(CLASS_KNIGHT), EnemyCreate(ENEMY_SLIME), _pw).dmg, 3);
    Test_Eq("Hard: enemy dmg floor(9*1.12) == 10", Test_Hit(EnemyCreate(ENEMY_FINAL_BOSS), CharacterCreate_Player(CLASS_KNIGHT), _ew).dmg, 10);
    Test_Hero(CLASS_KNIGHT, DIFFICULTY_EASY);
    Test_Eq("Easy: player dmg floor(4*1.08) == 4", Test_Hit(CharacterCreate_Player(CLASS_KNIGHT), EnemyCreate(ENEMY_SLIME), _pw).dmg, 4);
    Test_Eq("Easy: enemy dmg floor(9*0.9) == 8", Test_Hit(EnemyCreate(ENEMY_FINAL_BOSS), CharacterCreate_Player(CLASS_KNIGHT), _ew).dmg, 8);
    Test_Hero(CLASS_KNIGHT, DIFFICULTY_NORMAL);
    Test_Eq("Normal: enemy dmg == 9", Test_Hit(EnemyCreate(ENEMY_FINAL_BOSS), CharacterCreate_Player(CLASS_KNIGHT), _ew).dmg, 9);
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
    // Stat mods: Poison INT-1, Bleeding AGI-2.
    Test_Eq("Poison gives INT-1", Status_ModStat(Status_Add(CharacterCreate_Player(CLASS_MAGE), STATUS_POISON, 2, 0), STAT_INT), -1);
    Test_Eq("Bleeding gives AGI-2", Status_ModStat(_r, STAT_AGI), -2);
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
    Test_Eq("R-003 Inv_GetItems lists a pushed duplicate book once", array_length(Inv_GetItems(_dup)), 1);
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
