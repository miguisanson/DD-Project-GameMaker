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
}

function Test_RunAll() {
    Test_Reset();
    Test_RunSuite("Math", Test_Suite_Math);
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
