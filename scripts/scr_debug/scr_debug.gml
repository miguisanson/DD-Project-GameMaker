function Debug_Init() {
    if (!variable_global_exists("debug") || !is_struct(global.debug)) {
        global.debug = {};
    }
    if (!variable_struct_exists(global.debug, "enabled")) {
        global.debug.enabled = false;
    }
    if (!variable_struct_exists(global.debug, "last_command")) {
        global.debug.last_command = "";
    }
    if (!variable_struct_exists(global.debug, "last_command_frame")) {
        global.debug.last_command_frame = -1;
    }
    if (!variable_struct_exists(global.debug, "enemy_damage_skill_only")) {
        global.debug.enemy_damage_skill_only = false;
    }
    if (!variable_struct_exists(global.debug, "display_metrics")) {
        global.debug.display_metrics = false;
    }
}

function Debug_Record(_label) {
    Debug_Init();
    global.debug.last_command = string(_label);
    global.debug.last_command_frame = Input_Frame();
}

function Debug_Toggle() {
    Debug_Init();
    global.debug.enabled = !global.debug.enabled;
    if (!global.debug.enabled) {
        global.debug.enemy_damage_skill_only = false;
        global.debug.display_metrics = false;
    }
    Debug_Record("Toggle Debug: " + (global.debug.enabled ? "ON" : "OFF"));
}

function Debug_IsEnabled() {
    Debug_Init();
    return global.debug.enabled;
}

function Debug_EnemyForceDamageSkillOnly() {
    Debug_Init();
    return global.debug.enabled && global.debug.enemy_damage_skill_only;
}

function Debug_ToggleEnemyDamageSkillOnly() {
    Debug_Init();
    if (!global.debug.enabled) return;
    global.debug.enemy_damage_skill_only = !global.debug.enemy_damage_skill_only;
    Debug_Record("Enemy Damaging Skills Only: " + (global.debug.enemy_damage_skill_only ? "ON" : "OFF"));
}

function Debug_ToggleDisplayMetrics() {
    Debug_Init();
    if (!global.debug.enabled) return;
    global.debug.display_metrics = !global.debug.display_metrics;
    Debug_Record("Display Metrics Overlay: " + (global.debug.display_metrics ? "ON" : "OFF"));
}

function Debug_GiveAllItems() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    if (!variable_global_exists("item_db")) ItemDB_Init();

    var ch = gs.player_ch;
    var max_qty = 99;

    if (ds_exists(global.item_db, ds_type_map)) {
        var keylist = ds_map_keys_to_array(global.item_db);
        var count = array_length(keylist);
        for (var i = 0; i < count; i++) {
            var key = keylist[i];
            var item = ds_map_find_value(global.item_db, key);
            if (!is_struct(item) || !variable_struct_exists(item, "id")) continue;
            if (item.id <= 0) continue;

            var qty = 1;
            if (variable_struct_exists(item, "stackable") && item.stackable) {
                qty = max_qty;
                if (variable_struct_exists(item, "max_stack")) qty = min(item.max_stack, max_qty);
            }

            ch.inventory = Inv_Add(ch.inventory, item.id, qty);
        }
    } else if (is_struct(global.item_db)) {
        var keys = variable_struct_get_names(global.item_db);
        for (var j = 0; j < array_length(keys); j++) {
            var key2 = keys[j];
            var item2 = variable_struct_get(global.item_db, key2);
            if (!is_struct(item2) || !variable_struct_exists(item2, "id")) continue;
            if (item2.id <= 0) continue;

            var qty2 = 1;
            if (variable_struct_exists(item2, "stackable") && item2.stackable) {
                qty2 = max_qty;
                if (variable_struct_exists(item2, "max_stack")) qty2 = min(item2.max_stack, max_qty);
            }

            ch.inventory = Inv_Add(ch.inventory, item2.id, qty2);
        }
    }

    GameState_SetPlayer(ch);
    Debug_Record("Give All Items");
}


function Debug_LevelUp() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    var ch = Player_NormalizeProgression(gs.player_ch, false);

    if (Level_IsAtCap(ch.level)) {
        GameState_SetPlayer(ch);
        Debug_Record("Level Up (at cap)");
        return;
    }

    var exp_needed = max(1, ch.exp_next - ch.exp);
    ch = Player_AddExp(ch, exp_needed);
    GameState_SetPlayer(ch);
    Debug_Record("Level Up -> Lv " + string(ch.level));
}

function Debug_Save() {
    RunSave_WriteTo();
    Dialogue_Start("sys_save_ok");
    Debug_Record("Quick Save");
}

function Debug_Load() {
    if (Run_Continue().ok) {
        Dialogue_Start("sys_load_ok");
    } else {
        Dialogue_Start("sys_load_missing");
    }
    Debug_Record("Quick Load");
}

function Debug_KillPlayer() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;

    var ch = gs.player_ch;
    ch.hp = 0;
    GameState_SetPlayer(ch);

    // Mirror in-battle runtime struct too (if present), then invoke the standard death cutscene flow.
    if (room == rm_battle && instance_exists(obj_battle_controller)) {
        var bc = instance_find(obj_battle_controller, 0);
        if (instance_exists(bc) && variable_instance_exists(bc, "p") && is_struct(bc.p)) {
            bc.p.hp = 0;
        }
    }

    if (!Transition_IsActive()) {
        Run_OnPlayerDeath();
    }
    Debug_Record("Kill Player");
}

function Debug_Update() {
    Debug_Init();
    if (Input_Pressed("debug_toggle")) Debug_Toggle();
    if (!Debug_IsEnabled()) return;
    if (Input_Pressed("debug_enemy_damage_skill")) Debug_ToggleEnemyDamageSkillOnly();
    if (Input_Pressed("debug_display_metrics")) Debug_ToggleDisplayMetrics();
    if (Input_Pressed("debug_levelup")) Debug_LevelUp();
    if (Input_Pressed("debug_all_items")) Debug_GiveAllItems();
    if (Input_Pressed("debug_save")) Debug_Save();
    if (Input_Pressed("debug_load")) Debug_Load();
    if (Input_Pressed("debug_kill")) Debug_KillPlayer();
}


// ============================================================================
// Headless scenarios (VER-07 -smoke, VER-08 -bot, VER-09 -shots, VER-10 build id).
// Inert unless the exe is started with one of those flags. Contract: .planning/research/automation-igor.md 3.2-3.4.
//   Scenario_Boot()  called in obj_game_controller Create right after Test_Boot()
//   Scenario_Step()  called at the top of obj_game_controller Step
// Output contract (stdout): [TEST] PASS|FAIL ..., [TEST] ERROR UNHANDLED / [TEST] CRASH, [TEST-BUILD] <id>,
// [SHOT] file= w= h=, and a final [TEST-SUMMARY] pass= fail= errors= before game_end.
// ============================================================================
function Build_DrawId() {
    var _c = draw_get_color(), _a = draw_get_alpha(), _h = draw_get_halign(), _v = draw_get_valign();
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_set_alpha(0.7);
    UI_DrawText(Display_GuiW() - UI_TextWidth(BUILD_ID) - 4, Display_GuiH() - UI_TextHeight(BUILD_ID) - 2, BUILD_ID);
    draw_set_color(_c);
    draw_set_alpha(_a);
    draw_set_halign(_h);
    draw_set_valign(_v);
}

function Scenario_HasFlag(_flag) {
    for (var _i = 0; _i <= parameter_count(); _i++) {
        if (parameter_string(_i) == _flag) return true;
    }
    return false;
}

function Scenario_Check(_name, _ok, _detail = "") {
    if (_ok) {
        global.scn.pass++;
        show_debug_message("[TEST] PASS " + _name);
    } else {
        global.scn.fail++;
        show_debug_message("[TEST] FAIL " + _name + ((_detail != "") ? " " + _detail : ""));
    }
}

function Scenario_Boot() {
    if (variable_global_exists("scn_booted")) return;   // obj_game_controller exists in every room: boot once
    global.scn_booted = true;
    var _mode = "";
    if (Scenario_HasFlag("-smoke")) _mode = "smoke";
    else if (Scenario_HasFlag("-bot")) _mode = "bot";
    else if (Scenario_HasFlag("-shots")) _mode = "shots";
    else if (Scenario_HasFlag("-gridshots")) _mode = "gridshots";
    else if (Scenario_HasFlag("-exportdata")) _mode = "exportdata";
    if (_mode != "" || Scenario_HasFlag("-runtests")) {
        show_debug_message("[TEST-BUILD] " + BUILD_ID);
        // tests are always windowed whatever the saved setting says (Display_Init checks Display_TestRun); no focus / foreground calls anywhere
    }
    if (_mode == "") return;

    // Unhandled GML error: log it and end. game_end(n) inside the handler still gives exit code 0 (VER-05).
    exception_unhandled_handler(function(_ex) {
        show_debug_message("[TEST] ERROR UNHANDLED " + string(_ex.message));
        if (variable_struct_exists(_ex, "stacktrace") && is_array(_ex.stacktrace) && array_length(_ex.stacktrace) > 0) {
            show_debug_message("[TEST] ERROR at " + string(_ex.stacktrace[0]));
        }
        show_debug_message("[TEST] CRASH");
        game_end(2);
        return 0;
    });

    global.rng_inited = true;   // GameState_Init skips randomize()
    random_set_seed(12345);
    global.scn = { mode: _mode, f: 0, t: 0, step: 0, pass: 0, fail: 0, errors: 0, done: false, tap_action: "", last_tap: -100, v: 0, ri: 0, si: 0,
                   cap: (_mode == "bot") ? 22000 : ((_mode == "shots") ? 16000 : ((_mode == "gridshots") ? 8000 : 6000)), vstart: 0, hits: 0, tries: 0, attacking: false, qlog: [], qbase: 0, qhitstop: false, exp0: 0, shot: "", sk: 0, sk_start: 0, sk_fx: false, sk_fx_on_player: false, sk_fx_on_enemy: false, sk_fx_px: 0, sk_fx_limit: 0, sk_fx_min: 0, sk_cast: false, sk_flash: false, sk_mp0: 0, ski: 0, xi: 0, xwrong: 0, fxi: 0, di: 0, ap0: 0, fin_f: 0, cut_shot: false, fade_shot: false, dlg_seen: false, dlg_t: 0, mp: 0, mv: {}, holds: [], wd: undefined };
}

function Scenario_Finish() {
    var _s = global.scn;
    _s.done = true;
    show_debug_message("[TEST-FRAMES] " + _s.mode + " frames=" + string(_s.f) + " of " + string(_s.cap));
    show_debug_message("[TEST-SUMMARY] pass=" + string(_s.pass) + " fail=" + string(_s.fail) + " errors=" + string(_s.errors));
    game_end((_s.fail > 0 || _s.errors > 0) ? 1 : 0);
}

function Scenario_Next(_s, _step) {
    _s.step = _step;
    _s.t = 0;
}

// -bot input. The runner ignores keyboard_key_press while its window is not in front (measured), and tests never take focus,
// so the bot presses by writing the game's own input state: Input_Update ends with Scenario_InputOverride(), after which
// Input_Pressed / Input_UIConfirm (what every menu, QTE and the battle controller read) see the press.
// The press is visible from this step until the next Scenario_Step (global.scn.f changes), i.e. for exactly one game frame
// of the controllers that run before this one and for the rest of this frame for those that run after it.
function Scenario_Tap(_action) {
    global.scn.tap_action = _action;
    global.scn.last_tap = global.scn.f;
    if (variable_global_exists("input")) global.input.last_step_time = -1;   // make the next Input_Update recompute, with the press
}

// Holds an action (a movement key, "run", ...) for _frames game frames starting with this one: held every frame, pressed on the first.
// Several actions can be held at once. A held move key is also kept last in move_order, as the real keyboard path does
// (Input_MoveAction reads move_order). Holding an action again restarts its window.
function Scenario_Hold(_action, _frames) {
    var _s = global.scn;
    var _keep = [];
    for (var _i = 0; _i < array_length(_s.holds); _i++) {
        if (_s.holds[_i].a != _action) array_push(_keep, _s.holds[_i]);
    }
    array_push(_keep, { a: _action, s: _s.f, u: _s.f + _frames - 1 });
    _s.holds = _keep;
    if (variable_global_exists("input")) global.input.last_step_time = -1;   // make the next Input_Update recompute, with the press
}

function Scenario_Release() {
    global.scn.holds = [];
}

function Scenario_InputOverride() {
    if (!variable_global_exists("scn")) return;
    var _s = global.scn;
    if (_s.mode != "bot" && _s.mode != "smoke" && _s.mode != "shots" && _s.mode != "gridshots") return;   // shots taps through the dialogues of the display flow
    if (_s.tap_action != "" && _s.f == _s.last_tap) {
        variable_struct_set(global.input.state, _s.tap_action, { held: true, pressed: true });
    }
    for (var _i = 0; _i < array_length(_s.holds); _i++) {
        var _h = _s.holds[_i];
        if (_s.f > _h.u) continue;
        variable_struct_set(global.input.state, _h.a, { held: true, pressed: (_s.f == _h.s) });
        if (Input_IsMoveAction(_h.a)) {
            global.input.move_order = Input_ArrayRemove(global.input.move_order, _h.a);
            array_push(global.input.move_order, _h.a);
        }
    }
}

function Scenario_NewKnight(_class = CLASS_KNIGHT) {
    var _gs = GameState_Init();
    _gs.player_ch = CharacterCreate_Player(_class);
    _gs.in_main_menu = false;   // lets obj_game_controller spawn obj_player in a floor room
    return _gs;
}

function Scenario_GotoBattle(_persist_id, _enemy = ENEMY_SLIME) {
    GameState_SetBattleReturn(rm_floor1, 0, 0, 0);
    GameState_SetBattleEnemy(_persist_id, _enemy, 1);
    room_goto(rm_battle);
}

function Scenario_EnterBattle(_persist_id) {
    Scenario_NewKnight();
    Scenario_GotoBattle(_persist_id);
}

function Scenario_Step() {
    if (!variable_global_exists("scn")) return;
    var _s = global.scn;
    if (_s.done) return;
    _s.f++;
    _s.t++;
    var _gs = GameState_Get();
    if (is_struct(_gs) && variable_struct_exists(_gs, "settings") && is_struct(_gs.settings)) _gs.settings.window_mode = WINDOW_MODE_WINDOWED;
    if (_s.f > _s.cap) {
        Scenario_Check(_s.mode + "_within_" + string(_s.cap) + "_frames", false, "step=" + string(_s.step));
        Scenario_Finish();
        return;
    }
    switch (_s.mode) {
        case "smoke": Scenario_StepSmoke(_s); break;
        case "bot": Scenario_StepBot(_s); break;
        case "shots": Scenario_StepShots(_s); break;
        case "gridshots": Scenario_StepGridShots(_s); break;
        case "exportdata": Scenario_StepExportData(_s); break;
    }
}

// ---- -smoke: rm_start (logo, then menu) -> rm_floor1 -> rm_battle, a fixed number of frames each ----
function Scenario_StepSmoke(_s) {
    switch (_s.step) {
        case 0:
            if (_s.t == 30) {   // 30 frames of the real boot logo, then jump to the menu so its draw code runs too
                Scenario_Check("smoke_rm_start", room == rm_start && instance_exists(obj_start_controller));
                with (obj_start_controller) { if (state == "boot_logo") state = "main"; }
            }
            if (_s.t == 60) _s.ap0 = Display_ApplyCount();   // after the boot layout (frame 30): nothing below may re-lay-out the display (DISP-08)
            if (_s.t == 90) {
                Scenario_Check("smoke_title_menu", obj_start_controller.state == "main");
                Scenario_Next(_s, 30);   // D0: drive the title menu and the settings through the real input, then on to rm_floor1
            }
            break;
        case 1:
            if (_s.t == 60) {
                Scenario_Check("smoke_rm_floor1", room == rm_floor1 && instance_exists(obj_player));
                Scenario_EnterBattle("smoke_slime");
                Scenario_Next(_s, 2);
            }
            break;
        case 2:
            if (_s.t == 60) {
                Scenario_Check("smoke_rm_battle", room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_NewKnight();
                room_goto(rm_floor5);
                Scenario_Next(_s, 3);
            }
            break;
        case 3:
            // BUG-07: the mini boss in rm_floor5 must stay on its start tile (it is stationary; ai_stationary = true).
            if (_s.t == 30) {
                var _mb = instance_exists(obj_mini_boss) ? instance_find(obj_mini_boss, 0) : noone;
                Scenario_Check("smoke_rm_floor5_mini_boss", room == rm_floor5 && _mb != noone);
                if (_mb == noone) { Scenario_Finish(); break; }
                // The room's snake and wolf now really hunt the player (D63) and would start a battle inside these 180 frames;
                // this check is about the mini boss only, so the other enemies are taken out of the room first.
                with (obj_enemy) { if (id != _mb) instance_destroy(); }
                _s.mb_x = _mb.x;
                _s.mb_y = _mb.y;
                _s.mb_drift = 0;
                Scenario_Check("smoke_mini_boss_at_start_tile", _mb.x == _mb.xstart && _mb.y == _mb.ystart, "x=" + string(_mb.x) + " y=" + string(_mb.y) + " xstart=" + string(_mb.xstart) + " ystart=" + string(_mb.ystart));
            }
            if (_s.t > 30 && instance_exists(obj_mini_boss)) {
                var _mb2 = instance_find(obj_mini_boss, 0);
                _s.mb_drift = max(_s.mb_drift, abs(_mb2.x - _s.mb_x) + abs(_mb2.y - _s.mb_y));
            }
            if (_s.t == 210) {
                Scenario_Check("smoke_mini_boss_stationary_180_frames", room == rm_floor5 && _s.mb_drift == 0, "room=" + room_get_name(room) + " max_drift=" + string(_s.mb_drift));
                Scenario_Check("smoke_display_room_changes_no_relayout", Display_ApplyCount() == _s.ap0, "re-laid-out " + string(Display_ApplyCount() - _s.ap0) + " times over 4 room changes");
                Scenario_Next(_s, 4);
            }
            break;
        case 4:   // DISP-08: a steady stretch of 300 frames must not touch the display
            if (_s.t == 1) _s.ap0 = Display_ApplyCount();
            if (_s.t == 301) {
                Scenario_Check("smoke_display_steady_300_frames_no_relayout", Display_ApplyCount() == _s.ap0, "re-laid-out " + string(Display_ApplyCount() - _s.ap0) + " times");
                Transition_RequestRoomFade(rm_floor1);
                Scenario_Next(_s, 5);
            }
            break;
        case 5:   // DISP-08: a whole transition (fade out, room change, fade in, Transition_Finish) must not touch the display
            if (_s.t > 300) {
                Scenario_Check("smoke_display_transition_ends", false, "room=" + room_get_name(room) + " active=" + string(Transition_IsActive()));
                Scenario_Finish();
                break;
            }
            if (_s.t > 5 && room == rm_floor1 && !Transition_IsActive()) {
                Scenario_Check("smoke_display_transition_no_relayout", Display_ApplyCount() == _s.ap0, "re-laid-out " + string(Display_ApplyCount() - _s.ap0) + " times during one transition");
                Scenario_Next(_s, 6);   // already in rm_floor1 with the player (arrived by the transition above)
            }
            break;
        case 6: case 7: case 8: case 9:
            Scenario_StepSmokeSnap(_s);
            break;
        case 10: case 11: case 12: case 13: case 14: case 15: case 16: case 17:
            Scenario_StepSmokeSkip(_s);
            break;
        case 100: case 101: case 102: case 103: case 104: case 105: case 106: case 107: case 108: case 109: case 110: case 111: case 112:
            Scenario_StepSmokeRun(_s);   // C1: the run loop through the real flows
            break;
        case 30:
            Scenario_StepSmokeUi(_s);
            break;
        case 31:
            Scenario_StepSmokeUiStart(_s);
            break;
        case 32:
            Scenario_StepSmokePause(_s);
            break;
        case 33:
            Scenario_StepSmokeUiToFloor(_s);
            break;
    }
}

// D0 / D95: the title menu and the settings screen driven by Scenario_Tap / Scenario_Hold (the game's own input state), so the
// shared menu component is checked end to end: wrap-around, disabled items skipped, confirm opens a level, back goes up ONE level,
// the cursor is remembered, left/right changes a pending value and Back throws it away, holding scrolls after a delay.
// A fresh save area has no save, so Load Game is greyed: the title cursor visits New Game, Settings, Exit Game only.
function Scenario_StepSmokeUi(_s) {
    var _c = obj_start_controller;
    var _top = is_struct(_c.title_stk) ? Ui_StackTop(_c.title_stk) : undefined;
    var _sp = GameState_Get().ui.settings_popup;
    switch (_s.t) {
        case 1:
            Scenario_Check("ui_title_menu_is_on_the_framework", is_struct(_top) && _top.id == "title" && Ui_StackDepth(_c.title_stk) == 1);
            Scenario_Check("ui_title_starts_on_the_first_item", is_struct(_top) && _top.cursor == 0);
            Scenario_Tap("menu_up");
            break;
        case 4:
            Scenario_Check("ui_up_from_the_first_item_lands_on_the_last", _top.cursor == 3, "cursor=" + string(_top.cursor));
            Scenario_Tap("menu_down");
            break;
        case 10:
            Scenario_Check("ui_down_from_the_last_item_wraps_to_the_first", _top.cursor == 0, "cursor=" + string(_top.cursor));
            Scenario_Tap("menu_down");
            break;
        case 16:
            Scenario_Check("ui_cursor_skips_the_greyed_load_game", _top.cursor == 2, "cursor=" + string(_top.cursor));
            Scenario_Tap("confirm");
            break;
        case 22:
            Scenario_Check("ui_confirm_on_settings_opens_it", _c.state == "settings" && SettingsPopup_IsOpen("title"), "state=" + string(_c.state));
            Scenario_Check("ui_settings_starts_on_the_first_row", _sp.menu.cursor == 0);
            Scenario_Tap("menu_up");
            break;
        case 28:
            Scenario_Check("ui_settings_up_from_the_first_row_lands_on_the_last", _sp.menu.cursor == array_length(_sp.menu.items) - 1 && _sp.menu.items[_sp.menu.cursor].id == "apply", "cursor=" + string(_sp.menu.cursor));
            Scenario_Tap("menu_down");
            break;
        case 34:
            Scenario_Check("ui_settings_down_from_the_last_row_wraps_to_the_first", _sp.menu.cursor == 0, "cursor=" + string(_sp.menu.cursor));
            Scenario_Tap("menu_left");
            break;
        case 40:
            Scenario_Check("ui_settings_left_lowers_the_pending_volume", abs(_sp.pending.audio_ui - 0.95) < 0.001, "ui=" + string(_sp.pending.audio_ui));
            Scenario_Check("ui_settings_change_is_pending_not_applied", abs(GameSettings_Ensure().audio_ui - 1) < 0.001);
            Scenario_Tap("cancel");
            break;
        case 60:
            Scenario_Check("ui_back_leaves_settings_one_level", _c.state == "main" && !SettingsPopup_IsOpen("title"), "state=" + string(_c.state));
            Scenario_Check("ui_back_throws_the_pending_change_away", abs(GameSettings_Ensure().audio_ui - 1) < 0.001);
            Scenario_Check("ui_title_cursor_is_remembered", is_struct(_top) && _top.cursor == 2, "cursor=" + string(_top.cursor));
            Scenario_Tap("menu_down");
            break;
        case 66:
            Scenario_Tap("menu_down");
            break;
        case 72:
            Scenario_Check("ui_title_cursor_back_on_new_game", _top.cursor == 0, "cursor=" + string(_top.cursor));
            Scenario_Tap("confirm");
            break;
        case 80:
            Scenario_Check("ui_new_game_opens_the_difficulty_level", _c.state == "difficulty" && Ui_StackDepth(_c.title_stk) == 2, "state=" + string(_c.state));
            Scenario_Check("ui_difficulty_starts_on_normal", Ui_StackTop(_c.title_stk).cursor == 1);
            Scenario_Tap("cancel");
            break;
        case 100:
            Scenario_Check("ui_back_leaves_difficulty_one_level", _c.state == "main" && Ui_StackDepth(_c.title_stk) == 1, "state=" + string(_c.state) + " depth=" + string(Ui_StackDepth(_c.title_stk)));
            Scenario_Tap("cancel");
            break;
        case 106:
            Scenario_Check("ui_back_at_the_root_stays_on_the_title", _c.state == "main" && Ui_StackDepth(_c.title_stk) == 1);
            _s.ui_t0 = current_time;
            _s.ui_prev = _top.cursor;
            _s.ui_moves = 0;
            _s.ui_early = -1;
            Scenario_Hold("menu_down", 90);
            break;
        default:
            if (_s.t > 106 && _s.t < 230 && is_struct(_top) && _s.ui_t0 > 0) {
                if (_top.cursor != _s.ui_prev) { _s.ui_moves++; _s.ui_prev = _top.cursor; }
                var _el = current_time - _s.ui_t0;
                if (_s.ui_early < 0 && _el >= 250) _s.ui_early = _s.ui_moves;
                if (_s.ui_early >= 0 && _el >= 1000) {
                    Scenario_Check("ui_hold_waits_before_it_repeats", _s.ui_early <= 1, "moves in the first 250 ms: " + string(_s.ui_early));
                    Scenario_Check("ui_hold_then_scrolls_repeatedly", _s.ui_moves >= 4 && _s.ui_moves <= 40, "moves in 1 s: " + string(_s.ui_moves));
                    _s.ui_t0 = 0;
                    Scenario_Release();
                    Scenario_Next(_s, 31);
                }
            }
            if (_s.t >= 230 && _s.ui_t0 > 0) {
                Scenario_Check("ui_hold_scroll_measured", false, "no measurement");
                Scenario_Finish();
            }
            break;
    }
}

// New Game from the title: confirm, pick Easy in the difficulty panel, and the intro cutscene starts with that difficulty.
function Scenario_StepSmokeUiStart(_s) {
    var _c = obj_start_controller;
    switch (_s.t) {
        case 1:
            Ui_MenuFixCursor(Ui_StackTop(_c.title_stk), 0);   // the hold left the cursor anywhere
            Scenario_Tap("confirm");
            break;
        case 20:
            Scenario_Check("ui_new_game_shows_the_difficulty_panel", _c.state == "difficulty", "state=" + string(_c.state));
            Scenario_Tap("menu_up");
            break;
        case 26:
            Scenario_Tap("confirm");
            break;
        default:
            if (_s.t > 26 && room == rm_cutscene && obj_start_controller.cutscene_started && !Transition_IsActive() && GameState_Get().ui.mode == UI_DIALOGUE) {
                Scenario_Check("ui_difficulty_choice_starts_the_intro_with_it", Difficulty_GetCurrent() == DIFFICULTY_EASY, "difficulty=" + string(Difficulty_GetCurrent()));
                Scenario_Hold("confirm", 120);   // D48: hold to skip the intro, then through the rm_floor1 intro dialogue (next step)
                Scenario_Next(_s, 33);
            }
            if (_s.t > 600) {
                Scenario_Check("ui_difficulty_choice_starts_the_intro_with_it", false, "room=" + room_get_name(room));
                Scenario_Finish();
            }
            break;
    }
}

function Scenario_StepSmokeUiToFloor(_s) {
    var _gs = GameState_Get();
    if (_s.t > 900) {
        Scenario_Check("ui_new_game_reaches_rm_floor1", false, "room=" + room_get_name(room) + " mode=" + string(_gs.ui.mode));
        Scenario_Finish();
        return;
    }
    if (room == rm_floor1 && !Transition_IsActive()) {
        if (_gs.ui.mode == UI_DIALOGUE) {
            if ((_s.f - _s.last_tap) >= 8) Scenario_Tap("confirm");
        } else if (_s.t > 60 && array_length(_gs.ui.lines) <= 0 && variable_struct_exists(_gs, "pending_floor1_intro_dialogue") && !_gs.pending_floor1_intro_dialogue) {
            Scenario_Check("ui_new_game_reaches_rm_floor1", true);
            Scenario_Next(_s, 32);
        }
    }
}

// The other user of the settings screen: pause -> Settings -> Back (one level, back to the pause menu) -> Back (the game).
function Scenario_StepSmokePause(_s) {
    var _gs = GameState_Get();
    switch (_s.t) {
        case 1:
            room_goto(rm_start);   // leave rm_floor1 first: a room_goto to the room we are in would not spawn the player again
            break;
        case 30:
            Scenario_NewKnight();
            room_goto(rm_floor1);
            break;
        case 120:
            Scenario_Tap("pause");
            break;
        case 126:
            Scenario_Check("ui_pause_menu_opens", _gs.ui.mode == UI_PAUSE, "mode=" + string(_gs.ui.mode) + " room=" + room_get_name(room));
            Scenario_Tap("menu_down");
            break;
        case 132:
            Scenario_Tap("confirm");
            break;
        case 140:
            Scenario_Check("ui_pause_settings_opens", SettingsPopup_IsOpen("pause"));
            Scenario_Tap("cancel");
            break;
        case 165:
            Scenario_Check("ui_pause_settings_back_returns_to_the_pause_menu", !SettingsPopup_IsOpen("pause") && _gs.ui.mode == UI_PAUSE, "open=" + string(SettingsPopup_IsOpen("pause")) + " mode=" + string(_gs.ui.mode));
            Scenario_Tap("cancel");
            break;
        case 190:
            Scenario_Check("ui_pause_back_returns_to_the_game", _gs.ui.mode == UI_NONE, "mode=" + string(_gs.ui.mode));
            room_goto(rm_start);
            break;
        case 220:
            Scenario_NewKnight();   // the rest of the smoke run starts the way it always did: a new knight entering rm_floor1 from the title
            room_goto(rm_floor1);
            Scenario_Next(_s, 1);
            break;
    }
}

// D48 / I-055 hold-to-skip, through the real input path (Scenario_Tap / Scenario_Hold write the game's own input state).
// New Game -> intro cutscene: taps only advance text (the cutscene goes on); holding confirm ends the intro about a second later and the
// game arrives in rm_floor1 in the same state as after watching the whole intro (compared with a second, watched run).
function Scenario_IntroFingerprint() {
    var _gs = GameState_Get();
    var _hp = is_struct(_gs.player_ch) ? (string(_gs.player_ch.hp) + "/" + string(_gs.player_ch.max_hp)) : "none";
    return room_get_name(room) + " class=" + string(_gs.selected_class) + " menu=" + string(_gs.in_main_menu) + " defeated=" + string(ds_list_size(_gs.defeated_enemies))
        + " uid=" + string(_gs.uid_counter) + " reset=" + string(_gs.enemy_reset_version) + " mini=" + string(_gs.boss_defeated.mini_boss) + " final=" + string(_gs.boss_defeated.final_boss)
        + " room_states=" + string(variable_struct_names_count(_gs.room_states)) + " player=" + _hp + " player_obj=" + string(instance_exists(obj_player))
        + " intro_dialogue=" + string(_gs.ui.mode == UI_DIALOGUE) + " cutscene_active=" + string(variable_struct_exists(_gs.ui, "cutscene_active") && _gs.ui.cutscene_active);
}

function Scenario_StepSmokeSkip(_s) {
    var _gs = GameState_Get();
    var _sc = instance_exists(obj_start_controller) ? instance_find(obj_start_controller, 0) : noone;
    switch (_s.step) {
        case 10:   // a new game's intro cutscene, first run (skipped)
            if (_s.t == 1) {
                if (Transition_IsActive()) { _s.t = 0; break; }
                if (instance_exists(obj_dialogue_trigger)) with (obj_dialogue_trigger) instance_destroy();
                Dialogue_CloseNow();
                Scenario_NewKnight();
                Transition_RequestCutsceneById("intro");
            }
            if (_s.t > 1 && _s.t < 600 && room == rm_cutscene && _sc != noone && _sc.cutscene_started && !Transition_IsActive() && _gs.ui.mode == UI_DIALOGUE && _s.t > 40) {
                Scenario_Check("skip_intro_cutscene_running", true);
                _s.skp_taps = 0;
                Scenario_Next(_s, 11);
            }
            if (_s.t >= 600) { Scenario_Check("skip_intro_cutscene_running", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 11:   // taps (three presses, 20 frames apart) only advance text: the cutscene is still running 60 frames after the last
            if (_s.t == 10 || _s.t == 30 || _s.t == 50) Scenario_Tap("confirm");
            if (_s.t == 110) {
                Scenario_Check("skip_tap_does_not_skip_room", room == rm_cutscene, "room=" + room_get_name(room));
                Scenario_Check("skip_tap_does_not_skip_flag", _sc != noone && !_sc.cutscene_skip && _sc.cutscene_started);
                Scenario_Check("skip_tap_does_not_skip_no_exit_fade", !Transition_IsActive(), "a transition started");
                Scenario_Next(_s, 12);
            }
            break;
        case 12:   // hold confirm: the intro must end within about 1.2 s of the press (60 frames held + the flash/fade is the exit)
            if (_s.t == 1) {
                Scenario_Hold("confirm", 120);
                _s.skp_f0 = _s.f;
            }
            if (_s.t > 1 && Transition_IsActive() && _gs.transition_fx.type == TRANSITION_TYPE_CUTSCENE && _gs.transition_fx.target_room == rm_floor1) {
                var _d = _s.f - _s.skp_f0;
                Scenario_Check("skip_hold_ends_intro_within_1_2_s", _d <= 72, "frames=" + string(_d));
                Scenario_Check("skip_hold_not_before_1_s", _d >= SKIP_HOLD_FRAMES - 2, "frames=" + string(_d));
                Scenario_Release();
                Scenario_Next(_s, 13);
            }
            if (_s.t > 300) { Scenario_Check("skip_hold_ends_intro_within_1_2_s", false, "no exit fade after 300 frames"); Scenario_Finish(); }
            break;
        case 13:   // arrive in rm_floor1: its intro dialogue opens (the pending flag is the same one watching sets)
            if (room == rm_floor1 && !Transition_IsActive() && instance_exists(obj_player) && _gs.ui.mode == UI_DIALOGUE) {
                _s.skp_fp_skip = Scenario_IntroFingerprint();
                Scenario_Check("skip_hold_reaches_floor1_with_its_intro_dialogue", true);
                Scenario_Check("skip_hold_class_is_the_new_game_class", _gs.selected_class == CLASS_NOBODY, "class=" + string(_gs.selected_class));
                Scenario_Next(_s, 14);
            }
            if (_s.t > 600) { Scenario_Check("skip_hold_reaches_floor1_with_its_intro_dialogue", false, "room=" + room_get_name(room) + " mode=" + string(_gs.ui.mode)); Scenario_Finish(); }
            break;
        case 14:   // second run: watch the whole intro (confirm every line)
            if (_s.t == 1) {
                Dialogue_CloseNow();
                if (instance_exists(obj_dialogue_trigger)) with (obj_dialogue_trigger) instance_destroy();
                Scenario_NewKnight();
                Transition_RequestCutsceneById("intro");
            }
            if (_s.t > 2 && room == rm_cutscene && _sc != noone && _sc.cutscene_started && !Transition_IsActive() && _gs.ui.mode == UI_DIALOGUE) {
                if ((_s.f - _s.last_tap) >= 8) Scenario_Tap("confirm");
            }
            if (_s.t > 2 && Transition_IsActive() && _gs.transition_fx.type == TRANSITION_TYPE_CUTSCENE && _gs.transition_fx.target_room == rm_floor1) {
                Scenario_Next(_s, 15);
            }
            if (_s.t > 3000) { Scenario_Check("skip_watched_intro_ends", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 15:
            if (room == rm_floor1 && !Transition_IsActive() && instance_exists(obj_player) && _gs.ui.mode == UI_DIALOGUE) {
                var _fp = Scenario_IntroFingerprint();
                Scenario_Check("skip_state_equals_watched_state", _fp == _s.skp_fp_skip, "watched=[" + _fp + "] skipped=[" + _s.skp_fp_skip + "]");
                Scenario_Next(_s, 100);   // on to the run loop (C1)
            }
            if (_s.t > 600) { Scenario_Check("skip_watched_reaches_floor1", false, "room=" + room_get_name(room) + " mode=" + string(_gs.ui.mode)); Scenario_Finish(); }
            break;
    }
}

function Scenario_Aligned(_inst) {
    return (instance_exists(_inst) && Grid_IsAligned(_inst.x) && Grid_IsAligned(_inst.y));
}

function Scenario_CanSaveSlot() {
    // The run-loop scenario writes the real profile.sav / run.sav: only inside the gate, which points LOCALAPPDATA at its scratch folder.
    return (string_pos("dd-gate", string_lower(environment_get_variable("LOCALAPPDATA"))) > 0);
}

// I-048 snap: the player and the enemies always rest on the 16 px grid, also after a quick-load taken mid-step and after a room restore.
function Scenario_StepSmokeSnap(_s) {
    switch (_s.step) {
        case 6:
            if (_s.t == 60) {
                var _pl = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
                var _sl = instance_exists(obj_slime) ? instance_find(obj_slime, 0) : noone;
                Scenario_Check("snap_rm_floor1_player_and_slime", room == rm_floor1 && _pl != noone && _sl != noone);
                if (_pl == noone || _sl == noone) { Scenario_Finish(); break; }
                _s.sn_pl = _pl.id;
                _pl.x += 5; _pl.y += 3;   // as if caught between tiles
                _sl.cine_lock_count = 0;   // rm_floor1's cinematic trigger freezes this slime until it fires; free it for the check
                _sl.x += 3; _sl.y += 5;
            }
            if (_s.t == 64) {
                var _pl2 = instance_find(obj_player, 0);
                var _sl2 = instance_find(obj_slime, 0);
                Scenario_Check("snap_player_back_on_grid", Scenario_Aligned(_pl2), "x=" + string(_pl2.x) + " y=" + string(_pl2.y));
                Scenario_Check("snap_enemy_back_on_grid", Scenario_Aligned(_sl2), "x=" + string(_sl2.x) + " y=" + string(_sl2.y));
                if (!Scenario_CanSaveSlot()) {
                    show_debug_message("[TEST] SKIP snap_quickload (LOCALAPPDATA is not the gate scratch folder)");
                    Scenario_Next(_s, 8);
                    break;
                }
                _pl2.x += 6;   // F5 pressed mid-step stores this raw position
                _s.sn_saved_x = Grid_Snap(_pl2.x);
                _s.sn_saved_y = Grid_Snap(_pl2.y);
                RunSave_WriteTo();
                var _ok = Run_Continue().ok;
                Scenario_Check("snap_quickload_started", _ok);
                Scenario_Next(_s, 7);
            }
            break;
        case 7:
            if (_s.t == 240) {
                var _pl3 = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
                Scenario_Check("snap_quickload_back_in_rm_floor1", room == rm_floor1 && _pl3 != noone);
                if (_pl3 != noone) {
                    Scenario_Check("snap_quickload_player_on_grid", Scenario_Aligned(_pl3), "x=" + string(_pl3.x) + " y=" + string(_pl3.y));
                    Scenario_Check("snap_quickload_player_on_saved_tile", _pl3.x == _s.sn_saved_x && _pl3.y == _s.sn_saved_y, "x=" + string(_pl3.x) + " y=" + string(_pl3.y) + " want " + string(_s.sn_saved_x) + "," + string(_s.sn_saved_y));
                }
                Scenario_Next(_s, 8);
            }
            break;
        case 8:   // enemy position stored mid-step, then restored on re-entering the room
            if (_s.t == 5 && instance_exists(obj_slime)) {
                var _sl3 = instance_find(obj_slime, 0);
                _sl3.x += 5; _sl3.y += 3;
                RoomState_OnRoomExit();
                room_goto(rm_floor2);
            }
            if (_s.t == 50) {
                room_goto(rm_floor1);
                Scenario_Next(_s, 9);
            }
            break;
        case 9:
            if (_s.t == 50) {
                var _sl4 = instance_exists(obj_slime) ? instance_find(obj_slime, 0) : noone;
                Scenario_Check("snap_enemy_restored_on_grid", _sl4 != noone && room == rm_floor1 && Scenario_Aligned(_sl4), (_sl4 != noone) ? ("x=" + string(_sl4.x) + " y=" + string(_sl4.y)) : "no slime");
                Scenario_Next(_s, 10);   // on to the hold-to-skip checks (D48)
            }
            break;
    }
}

// ---- -bot: Knight vs Slime through simulated key presses (the real input path) ----
// v=0 "perfect": confirms the menu and presses the attack bar on its zone. Then v=3: one skill per class through the arrows and one defended
// big attack, all Perfect. Then v=2: every skill animation. v=1 "fail": confirms the menu but never presses the bar. Then v=4: the same
// skill casts and defence, all failed (Weak).
function Scenario_StepBot(_s) {
    if (_s.v == 5) {
        Scenario_StepMove(_s);
        return;
    }
    if (_s.v == 6) {
        Scenario_StepBotStatus(_s);
        return;
    }
    if (_s.v == 7) {
        if (_s.step >= 20) Scenario_StepBotAI(_s);   // B4 (steps 20..33): the battle AI
        else Scenario_StepBotTurns(_s);
        return;
    }
    if (_s.v == 2) {
        Scenario_StepBotSkill(_s);
        return;
    }
    if (_s.v >= 3) {
        Scenario_StepBotExtras(_s);
        return;
    }
    var _name = (_s.v == 0) ? "bot_perfect" : "bot_fail";
    switch (_s.step) {
        case 0:   // short pause in rm_start, then start the battle
            if (_s.t == 10) {
                _s.vstart = _s.f;
                _s.hits = 0;
                _s.qlog = [];
                _s.tries = 0;
                _s.attacking = false;
                Scenario_EnterBattle(_name);
                _s.exp0 = GameState_Get().player_ch.exp;
                Scenario_Next(_s, 1);
            }
            break;
        case 1:
            if (room != rm_battle || !instance_exists(obj_battle_controller)) {
                if (_s.t > 20) {
                    Scenario_Check(_name + "_in_battle", false, "room=" + room_get_name(room));
                    Scenario_Finish();
                }
                break;
            }
            var _bc = instance_find(obj_battle_controller, 0);
            if (_bc.battle_over) {
                Scenario_BotEvaluate(_s, _bc, _name);
                Scenario_Next(_s, 2);
            } else if (_s.f - _s.vstart > ((_s.v == 0) ? 2000 : 4000)) {
                var _hp = GameState_Get().player_ch;
                Scenario_Check(_name + "_ended", _s.v == 1, "no battle_over in " + string(_s.f - _s.vstart) + " frames");   // fail variant: report only
                Scenario_Check(_name + "_hp_in_bounds", _hp.hp >= 0 && _hp.hp <= _hp.max_hp, "hp=" + string(_hp.hp));
                show_debug_message("[BOT] " + _name + " did not end in time (state=" + string(_bc.battle_state) + ")");
                Scenario_Next(_s, 2);
            } else {
                Scenario_BotDrive(_s, _bc);
            }
            break;
        case 2:   // let the end-of-battle flow (return fade / game-over cutscene) run
            if (_s.t == 180) {
                if (_s.v == 0) Scenario_Check("bot_perfect_returns_to_floor", room == rm_floor1, "room=" + room_get_name(room));
                _s.xi = 0;
                _s.v = (_s.v == 0) ? 3 : 4;   // 0 perfect -> 3 skill casts + defence -> 2 every player skill, one battle each (_s.ski) -> 1 fail -> 4 skill casts + defence
                Scenario_Next(_s, 0);
            }
            break;
    }
}

// ---- QTE part 2 in the bot: one skill per class through the arrow input, and one defended big attack ----
// Run after the basic-attack battle of each variant (v=3 after "perfect", v=4 after "fail"). Everything is typed through Scenario_Tap, the same
// input path as a player's move_up/down/left/right and confirm. Perfect variant: right arrows at a steady pace, the defence bar pressed on its
// zone. Fail variant: two wrong arrows then the right ones (Weak, not a timeout) for the Knight and Mage, no arrow at all for the Archer
// (the bar runs out), and no press on the defence bar.
function Scenario_ArrowAction(_dir) {
    var _keys = ["move_right", "move_up", "move_left", "move_down"];   // RIGHT, UP, LEFT, DOWN macro order
    return _keys[_dir];
}

// The classes whose skill is cast: [class, skill]. The Nobody has no skills yet (D34).
function Scenario_ExtraSkill(_i) {
    var _rows = [[CLASS_KNIGHT, SKILL_HORIZ_SLASH], [CLASS_ARCHER, SKILL_POISON_ARROW], [CLASS_MAGE, SKILL_FIREBALL]];
    return _rows[_i];
}

// Types the open arrow sequence. _mode: "right" = the wanted arrow every 5 frames, "wrong2" = two wrong arrows first, "none" = nothing.
function Scenario_BotArrows(_s, _bc, _mode) {
    if (_mode == "none" || _bc.battle_state != BSTATE_SKILL_QTE || !_bc.sq_active || _bc.sq_ms < 0 || (_s.f - _s.last_tap) < 5) return;
    var _st = _bc.sq_st;
    if (_st.done) return;
    var _want = _st.seq[_st.idx];
    if (_mode == "wrong2" && _s.xwrong < 2) {
        _s.xwrong++;
        Scenario_Tap(Scenario_ArrowAction((_want + 1) mod 4));
    } else {
        Scenario_Tap(Scenario_ArrowAction(_want));
    }
}

// Presses confirm on the defence bar's zone centre (to within a frame and a half), once the sweep is under way.
function Scenario_BotDefend(_s, _bc) {
    if (_bc.battle_state != BSTATE_ENEMY_DEFENCE || !_bc.def_active || _bc.def_ms < 0 || (_s.f - _s.last_tap) < 4) return;
    if ((Qte_ZoneCentreMs(_bc.def_params) - _bc.def_ms) <= Qte_StepMs(delta_time) * 1.5) Scenario_Tap("confirm");
}

function Scenario_StepBotExtras(_s) {
    var _fail = (_s.v == 4);
    var _who = _fail ? "bot_fail" : "bot_perfect";
    if (_s.xi >= 4) {   // all four done: leave the debug switches and the Ramming status chance as they were
        global.debug.enabled = false;
        global.debug.enemy_damage_skill_only = false;
        SkillDB_Get(SKILL_RAMMING).status_chance = 0.60;
        if (_fail) Scenario_Finish();
        else { _s.v = 2; Scenario_Next(_s, 0); }   // on to the per-skill animation checks
        return;
    }
    var _is_defence = (_s.xi == 3);
    var _row = _is_defence ? [CLASS_KNIGHT, SKILL_RAMMING] : Scenario_ExtraSkill(_s.xi);
    var _sid = _row[1];
    var _skill = SkillDB_Get(_sid);
    var _name = _who + (_is_defence ? "_defence_" : "_arrows_") + string_lower(string_replace_all(_skill.name, " ", "_"));
    switch (_s.step) {
        case 0:
            if (_s.t == 10) {
                var _gs = Scenario_NewKnight(_row[0]);
                var _ch = _gs.player_ch;
                if (!_is_defence) {
                    _ch.skills = [_sid];   // the only skill in the menu
                    _ch.max_mp = 99;
                    _ch.mp = 99;
                    GameState_SetPlayer(_ch);
                    _s.sk_mp0 = _ch.mp;
                } else {
                    _ch.max_hp = 99;   // a big hit must not end the battle
                    _ch.hp = 99;
                    GameState_SetPlayer(_ch);
                    Debug_Init();
                    global.debug.enabled = true;   // an enemy that only uses damaging skills: the mini boss's Ramming, every turn
                    global.debug.enemy_damage_skill_only = true;
                    SkillDB_Get(SKILL_RAMMING).status_chance = 1;   // so the Bleeding is always applied and there is something to resist
                    _s.d_tries = 0;
                    _s.d_seen = false;
                }
                _s.vstart = _s.f;
                _s.sk = -1;
                _s.xwrong = 0;
                Scenario_GotoBattle(_name, _is_defence ? ENEMY_MINI_BOSS : ENEMY_SLIME);
                Scenario_Next(_s, 1);
            }
            break;
        case 1:
            if (room != rm_battle || !instance_exists(obj_battle_controller)) {
                if (_s.t > 20) {
                    Scenario_Check(_name + "_in_battle", false, "room=" + room_get_name(room));
                    Scenario_Finish();
                }
                break;
            }
            var _bc = instance_find(obj_battle_controller, 0);
            var _ready = (_s.f - _s.last_tap) >= 4;
            if (_s.f - _s.vstart > 1500) {
                Scenario_Check(_name + "_finished", false, "sk=" + string(_s.sk) + " state=" + string(_bc.battle_state));
                Scenario_Next(_s, 2);
                break;
            }
            if (!_is_defence) {
                var _mode = (!_fail) ? "right" : ((_s.xi == 1) ? "none" : "wrong2");
                if (_s.sk == -1) {   // a sturdy enemy, so the skill cannot kill it
                    _bc.e.max_hp = 99;
                    _bc.e.hp = 99;
                    _s.sk = 0;
                } else if (_s.sk == 0) {   // reach the skill menu and confirm the skill
                    if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER && _ready) {
                        Scenario_Tap((_bc.menu_index != 1) ? "menu_down" : "confirm");
                    } else if (_bc.battle_state == BSTATE_SKILL_MENU && _ready) {
                        _bc.e.status = [];
                        Scenario_Tap("confirm");
                        _s.sk = 1;
                    }
                } else if (_s.sk == 1) {   // the confirm was read: the arrows are up and nothing is spent yet
                    if (_bc.battle_state == BSTATE_SKILL_QTE) {
                        Scenario_Check(_name + "_arrows_shown_in_the_skills_fixed_order", string(_bc.sq_st.seq) == string(Qte_SkillSequence(_sid)));
                        Scenario_Check(_name + "_mp_not_spent_before_the_arrows_end", _bc.p.mp == _s.sk_mp0);
                        _s.sk = 2;
                    }
                } else if (_s.sk == 2) {
                    Scenario_BotArrows(_s, _bc, _mode);
                    if (_bc.battle_state != BSTATE_SKILL_QTE) {   // the sequence ended and the skill was cast (message state)
                        var _st = _bc.sq_st;
                        var _want_key = _fail ? QTE_WEAK : QTE_PERFECT;
                        var _want_mult = _fail ? 0.75 : 1.30;
                        var _dealt = 99 - _bc.e.hp;
                        // what the skill deals at grade OK, with and without a crit, from a fresh copy of the same enemy
                        // B1: the grade is part of the single damage rounding now (spec section 4), so the expectation is the formula at that grade.
                        var _w = { power: Combat_PowerSkill(_skill.power, _skill.power_mult, Combat_WeaponPower(_bc.p)), stat_type: _skill.stat_type, acc: _skill.acc };
                        var _b1 = Combat_ApplyDamage(_bc.p, EnemyCreate(ENEMY_SLIME), _w, 1, 1, { is_skill: true, grade_mult: 1 }).dmg;
                        var _min = Combat_ApplyDamage(_bc.p, EnemyCreate(ENEMY_SLIME), _w, 1, 1, { is_skill: true, grade_mult: _want_mult }).dmg;
                        show_debug_message("[BOT] " + _name + " grade=" + _st.key + " mult=" + string(_bc.qte_result_mult) + " arrows=" + string(_st.len) + " mistakes=" + string(_st.mistakes)
                            + " timed_out=" + string(_st.timed_out) + " finish_ms=" + string(_st.finish_ms) + "/" + string(_st.limit_ms) + " dealt=" + string(_dealt) + " base=" + string(_b1) + " expected_min=" + string(_min));
                        Scenario_Check(_name + "_grade_" + _want_key, _st.key == _want_key && _bc.qte_result_key == _want_key, "got " + _st.key);
                        Scenario_Check(_name + "_multiplier_" + string(_want_mult), abs(_bc.qte_result_mult - _want_mult) < 0.0001);
                        Scenario_Check(_name + "_all_arrows_" + (_mode == "none" ? "missed_timed_out" : "typed"), (_mode == "none") ? (_st.timed_out && _st.idx == 0) : (_st.idx == _st.len && !_st.timed_out));
                        Scenario_Check(_name + "_mistakes_" + string((_mode == "wrong2") ? 2 : 0), _st.mistakes == ((_mode == "wrong2") ? 2 : 0), "mistakes=" + string(_st.mistakes));
                        Scenario_Check(_name + "_damage_is_base_x_multiplier_or_more_and_never_0", _dealt >= _min && _dealt >= 1, "dealt=" + string(_dealt) + " min=" + string(_min));
                        Scenario_Check(_name + "_damage_taken_off_the_enemy_matches_the_log", _dealt == _bc.last_dmg, "dealt=" + string(_dealt) + " last_dmg=" + string(_bc.last_dmg));
                        Scenario_Check(_name + "_mp_spent_once", _s.sk_mp0 - _bc.p.mp == _skill.mp_cost, "mp0=" + string(_s.sk_mp0) + " mp=" + string(_bc.p.mp));
                        Scenario_Check(_name + "_grade_word_shown", _bc.qte_result_text == Qte_GradeLabel(_want_key) && _bc.qte_result_ms > 0);
                        Scenario_Check(_name + "_grade_sound_fired", global.sfx_last_key == Qte_GradeSfxKey(_want_key), "last=" + string(global.sfx_last_key));
                        Scenario_Check(_name + "_hitstop_on_perfect_only", (_bc.hitstop_ms > 0) == (_want_key == QTE_PERFECT), "hitstop=" + string(_bc.hitstop_ms));
                        Scenario_Next(_s, 2);
                    }
                }
            } else {
                if (_s.sk == -1) {
                    _s.sk = 0;
                } else if (_s.sk == 0) {   // hand the turn to the enemy until its bar comes up
                    if (_bc.battle_state == BSTATE_ENEMY_DEFENCE && _bc.def_active) {
                        _s.d_hp_before = _bc.def_ctx.hp_before;
                        _s.d_hp_shown = _bc.p.hp;
                        _s.d_base = _bc.def_ctx.res.dmg;
                        _s.d_bleed = Battle_StatusCurrentTurns(_bc.p, STATUS_BLEED);
                        _s.d_clock0 = _bc.def_ms;
                        _s.d_mp_ok = true;
                        _s.sk = 1;
                    } else if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER && _ready) {
                        _s.d_tries++;
                        _bc.turn = TURN_ENEMY;
                        _bc.battle_state = BSTATE_ENEMY_ACT;
                    }
                    if (_s.d_tries > 8) {
                        Scenario_Check(_name + "_big_attack_reached_the_bar", false, "tries=" + string(_s.d_tries));
                        Scenario_Next(_s, 2);
                    }
                } else if (_s.sk == 1) {
                    if (!_fail) Scenario_BotDefend(_s, _bc);
                    if (_bc.battle_state != BSTATE_ENEMY_DEFENCE) {   // the bar ended and the hit was settled
                        var _key = _bc.qte_result_key;
                        var _want_key2 = _fail ? QTE_WEAK : QTE_PERFECT;
                        var _hp_now = _bc.p.hp;
                        var _bleed_now = Battle_StatusCurrentTurns(_bc.p, STATUS_BLEED);
                        var _took = _s.d_hp_before - _hp_now;
                        show_debug_message("[BOT] " + _name + " grade=" + _key + " base_dmg=" + string(_s.d_base) + " took=" + string(_took)
                            + " expected=" + string(Qte_DefenceDamage(_s.d_base, _want_key2)) + " bleed_when_hit=" + string(_s.d_bleed) + " bleed_after=" + string(_bleed_now) + " telegraph_clock0=" + string(_s.d_clock0));
                        Scenario_Check(_name + "_telegraph_then_bar_clock", _s.d_clock0 <= -(QTE_TELEGRAPH_MS + QTE_LEAD_IN_MS) + 100, "clock0=" + string(_s.d_clock0));
                        Scenario_Check(_name + "_hp_not_lowered_while_the_bar_is_up", _s.d_hp_shown == _s.d_hp_before, "shown=" + string(_s.d_hp_shown) + " before=" + string(_s.d_hp_before));
                        Scenario_Check(_name + "_grade_" + _want_key2, _key == _want_key2, "got " + string(_key));
                        Scenario_Check(_name + "_damage_taken_matches_the_grade", _took == Qte_DefenceDamage(_s.d_base, _want_key2), "took=" + string(_took) + " base=" + string(_s.d_base));
                        Scenario_Check(_name + "_status_was_applied_by_the_hit", _s.d_bleed > 0, "bleed=" + string(_s.d_bleed));
                        Scenario_Check(_name + "_base_damage_is_4_or_more", _s.d_base >= 4, "base=" + string(_s.d_base));
                        Scenario_Check(_name + "_status_not_lengthened", _bleed_now <= _s.d_bleed, "after=" + string(_bleed_now) + " applied=" + string(_s.d_bleed));
                        if (_fail) Scenario_Check(_name + "_weak_leaves_the_status_as_applied", _bleed_now == _s.d_bleed, "after=" + string(_bleed_now) + " applied=" + string(_s.d_bleed));
                        else Scenario_Check(_name + "_perfect_resists_the_status", _bleed_now == 0, "after=" + string(_bleed_now));
                        Scenario_Check(_name + "_grade_word_shown", _bc.qte_result_text == Qte_GradeLabel(_want_key2) && _bc.qte_result_ms > 0);
                        Scenario_Check(_name + "_grade_sound_fired", global.sfx_last_key == Qte_GradeSfxKey(_want_key2), "last=" + string(global.sfx_last_key));
                        Scenario_Next(_s, 2);
                    }
                }
            }
            break;
        case 2:   // measured: the next one (the battle is simply abandoned)
            if (_s.t == 5) {
                _s.xi++;
                Scenario_Next(_s, 0);
            }
            break;
    }
}

// v=2: BUG-05/06 / D55 / BUG-21 / I-052, once for EVERY player skill with an animation (Skill_PlayerFxIds, in id order; _s.ski is the index).
// A character of the skill's class casts it through the menu keys. Measured: game frames from the frame the battle controller leaves the
// skill menu for BSTATE_MESSAGE (the confirm) to the frame the message state ends (battle_state is MENU or ENEMY_ACT again: the point where
// the next choice or the enemy's reply starts). The player has Foresight (always hits) so the animation plays and the enemy is sturdy so
// the skill cannot kill it. Each action must take no more than SCN_SKILL_ACTION_MAX_FRAMES (D55: about 1 s, 60 fps), play on the right
// side (BUG-21) and be drawn within the size rule (I-052).
#macro SCN_SKILL_ACTION_MAX_FRAMES 66
function Scenario_SkillName(_sid) {
    return "bot_skill_" + string_lower(string_replace_all(SkillDB_Get(_sid).name, " ", "_"));
}

function Scenario_StepBotSkill(_s) {
    var _ids = Skill_PlayerFxIds();
    var _sid = _ids[_s.ski];
    var _skill = SkillDB_Get(_sid);
    var _name = Scenario_SkillName(_sid);
    switch (_s.step) {
        case 0:
            if (_s.t == 10) {
                var _gs = Scenario_NewKnight(_skill.class_list[0]);
                var _ch = _gs.player_ch;
                _ch.skills = [_sid];   // the only skill in the menu
                _ch.max_mp = 99;
                _ch.mp = 99;
                if (_sid == SKILL_HILT_BASH) _ch = Status_Add(_ch, STATUS_POISON, 0, 0, 3);   // BUG-08: the tick after the skill must reach the log and the HUD
                GameState_SetPlayer(_ch);
                _s.vstart = _s.f;
                _s.sk = -1;
                _s.sk_fx = false;
                _s.sk_mp0 = _ch.mp;
                _s.xwrong = 0;
                Scenario_GotoBattle(_name);
                Scenario_Next(_s, 1);
            }
            break;
        case 1:
            if (room != rm_battle || !instance_exists(obj_battle_controller)) {
                if (_s.t > 20) {
                    Scenario_Check(_name + "_in_battle", false, "room=" + room_get_name(room));
                    Scenario_Finish();
                }
                break;
            }
            var _bc = instance_find(obj_battle_controller, 0);
            var _ready = (_s.f - _s.last_tap) >= 4;
            if (_s.f - _s.vstart > 900) {
                Scenario_Check(_name + "_action_measured", false, "sk=" + string(_s.sk) + " state=" + string(_bc.battle_state));
                Scenario_Next(_s, 2);
                break;
            }
            if (_s.sk == -1) {   // a sturdy enemy, so the skill cannot kill it (a kill skips the animation) whatever the dice say
                _bc.e.max_hp = 99;
                _bc.e.hp = 99;
                _s.sk = 0;
            } else if (_s.sk == 0) {   // reach the skill menu and confirm the skill (answer any enemy attack first)
                if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER && _ready) {
                    Scenario_Tap((_bc.menu_index != 1) ? "menu_down" : "confirm");
                } else if (_bc.battle_state == BSTATE_SKILL_MENU && _ready) {
                    _bc.e.status = [];   // an enemy that used Solidify or Evasion on its turn would turn Foresight into a miss and skip the animation
                    Scenario_Tap("confirm");
                    _s.sk = 1;
                } else {
                    Scenario_BotDefend(_s, _bc);
                }
            } else if (_s.sk == 1) {   // the confirm was read: the arrows are up, then (once they are typed) the controller is in the message state
                Scenario_BotArrows(_s, _bc, "right");
                if (_bc.battle_state == BSTATE_MESSAGE) {
                    _s.sk_start = _s.f;
                    _s.sk_cast = _bc.skill_banner_active && _bc.skill_banner_name == _skill.name;   // Skill_Use succeeded (Meditation gives MP back, so MP alone cannot show it)
                    _s.sk_fx = instance_exists(_bc.wait_fx);
                    _s.sk_fx_on_player = false;
                    _s.sk_fx_on_enemy = false;
                    _s.sk_fx_px = 0;
                    _s.sk_fx_limit = 0;
                    _s.sk_fx_min = 0;
                    if (_s.sk_fx) {   // BUG-21: where did the animation spawn, relative to the player and enemy anchor points?
                        var _fxi = _bc.wait_fx;
                        var _pp = FX_CenterAtPoint(_fxi.sprite_index, _bc.player_fx_x, _bc.player_fx_y, _fxi.image_xscale);
                        var _pe = FX_CenterOn(_fxi.sprite_index, _bc.enemy_inst, _fxi.image_xscale);
                        _s.sk_fx_on_player = point_distance(_fxi.x, _fxi.y, _pp.x, _pp.y) < 1;
                        _s.sk_fx_on_enemy = point_distance(_fxi.x, _fxi.y, _pe.x, _pe.y) < 1;
                        // I-052 / I-060: the drawn VISIBLE side (sprite bounding box x scale) against the target's (the enemy's sprite, or the player's 32 px reference)
                        var _target = Battle_SkillFxOnPlayer(_sid) ? FX_PLAYER_TARGET_PX : FX_TargetSize(_bc.enemy_inst);
                        _s.sk_fx_px = FX_ContentSide(_fxi.sprite_index) * abs(_fxi.image_xscale);
                        _s.sk_fx_limit = min(64, 1.5 * _target);
                        _s.sk_fx_min = min(64, _target);
                    }
                    _s.sk_flash = instance_exists(obj_ui_controller) && obj_ui_controller.hud_hurt_flash_timer > 0;   // the tick ran in this same frame
                    _s.sk = 2;
                }
            } else if (_s.sk == 2) {
                if (_bc.battle_state != BSTATE_MESSAGE) {
                    var _frames = _s.f - _s.sk_start;
                    show_debug_message("[BOT] " + _name + " action_frames=" + string(_frames) + " fx=" + string(_s.sk_fx) + " fx_px=" + string(_s.sk_fx_px) + " limit=" + string(_s.sk_fx_limit) + " next_state=" + string(_bc.battle_state) + " msg=" + string(_bc.message_text));
                    Scenario_Check(_name + "_skill_was_cast", _s.sk_cast, "mp=" + string(_bc.p.mp) + " mp0=" + string(_s.sk_mp0));
                    Scenario_Check(_name + "_fx_played", _s.sk_fx);
                    Scenario_Check(_name + "_fx_on_" + (Battle_SkillFxOnPlayer(_sid) ? "player" : "enemy"),
                        Battle_SkillFxOnPlayer(_sid) ? (_s.sk_fx_on_player && !_s.sk_fx_on_enemy) : (_s.sk_fx_on_enemy && !_s.sk_fx_on_player));
                    Scenario_Check(_name + "_fx_size_fits_target", _s.sk_fx && _s.sk_fx_px <= _s.sk_fx_limit + 0.01 && _s.sk_fx_px >= _s.sk_fx_min - 0.01, "drawn=" + string(_s.sk_fx_px) + " min=" + string(_s.sk_fx_min) + " max=" + string(_s.sk_fx_limit));
                    if (_sid == SKILL_HILT_BASH) {
                        var _logged = false;
                        for (var _li = 0; _li < array_length(_bc.combat_log); _li++) {
                            if (string_pos("Poison", _bc.combat_log[_li].text) > 0 && string_pos("hurts you", _bc.combat_log[_li].text) > 0) _logged = true;
                        }
                        Scenario_Check(_name + "_poison_tick_logged", _logged);
                        Scenario_Check(_name + "_poison_tick_flashes_hud", _s.sk_flash);
                    }
                    Scenario_Check(_name + "_action_le_" + string(SCN_SKILL_ACTION_MAX_FRAMES) + "_frames", _frames <= SCN_SKILL_ACTION_MAX_FRAMES, "frames=" + string(_frames));
                    Scenario_Next(_s, 2);
                }
            }
            break;
        case 2:   // measured: start the next skill (the battle is simply abandoned) or the fail variant
            if (_s.t == 5) {
                _s.ski++;
                if (_s.ski >= array_length(_ids)) _s.v = 6;   // skills -> statuses (v=6, B2) -> turn timeline (v=7, B3) -> movement and AI (v=5) -> fail (v=1)
                Scenario_Next(_s, 0);
            }
            break;
    }
}

// ---- v=6 (packet B2): the status rules through the real battle flow ----
// Battle A: a Mage against a Slime that stays stunned, 99 HP: Poison stacks tick down (3, 2, 1), Burning lowers DEF and ends after its 2 turns,
// Bleeding does not hurt on a stunned turn but does on each action. Battle B: the Mage casts Foresight against a Spider that only uses its big
// attack (Poison Fangs): the preview names it, the enemy really does it, the log says so, the Perfect zones are x1.5 for 3 turns and back to normal after.
// The Foresight preview on the turn strip (D79): the first slot that carries it, or undefined. Returns { idx, slot }.
function Scenario_BotForesightSlot(_bc) {
    var _slots = Battle_TimelineSlots(_bc);
    for (var _i = 0; _i < array_length(_slots); _i++) {
        if (is_struct(_slots[_i].foresight)) return { idx: _i, slot: _slots[_i], count: array_length(_slots) };
    }
    return undefined;
}

function Scenario_BotLogCount(_bc, _needle) {
    var _n = 0;
    for (var _i = 0; _i < array_length(_bc.combat_log); _i++) {
        if (string_pos(_needle, _bc.combat_log[_i].text) > 0) _n++;
    }
    return _n;
}

// One basic attack with no press (Weak is enough). _t.pa: 0 wait for the menu, 1 wait for the bar, 2 wait for the bar to end, 3 wait for the menu again.
// Returns true on the frame the player is back at the menu. Records what the bar looked like (_t.widen, _t.pw) and the HP before the action.
function Scenario_BotOneAttack(_s, _bc) {
    var _t = _s.stt;
    var _ready = (_s.f - _s.last_tap) >= 4;
    switch (_t.pa) {
        case 0:
            if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER && _ready) {
                if (_bc.menu_index != 0) {
                    Scenario_Tap("menu_up");   // the cursor is remembered: back to ATTACK
                } else {
                    _t.hp_before = _bc.p.hp;
                    Scenario_Tap("confirm");
                    _t.pa = 1;
                }
            }
            break;
        case 1:
            if (_bc.battle_state == BSTATE_ATTACK_TIMING) {
                _t.widen = _bc.qte_perfect_widen;
                _t.pw = _bc.qte_params.perfect_half_width;
                _t.pa = 2;
            }
            break;
        case 2:
            if (_bc.battle_state != BSTATE_ATTACK_TIMING) _t.pa = 3;
            break;
        case 3:
            if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER) {
                _t.pa = 0;
                show_debug_message("[BOT] bot_status k=" + string(_t.k) + " hp=" + string(_bc.p.hp) + "/" + string(_bc.p.max_hp) + " (before " + string(_t.hp_before) + ") status=" + json_stringify(_bc.p.status) + " enemy_hp=" + string(_bc.e.hp));
                return true;
            }
            break;
    }
    return false;
}

function Scenario_StepBotStatus(_s) {
    var _name = "bot_status";
    switch (_s.step) {
        case 0:   // battle A
        case 3:   // battle B
            if (_s.t == 10) {
                var _gs = Scenario_NewKnight(CLASS_MAGE);
                var _ch = _gs.player_ch;
                _ch.max_hp = 99;
                _ch.hp = 99;
                _ch.max_mp = 99;
                _ch.mp = 99;
                var _b_battle = (_s.step == 3);
                if (_b_battle) _ch.skills = [SKILL_FORESIGHT];
                GameState_SetPlayer(_ch);
                _s.stt = { pa: 0, k: 0, widen: 1, pw: 0, hp_before: 0, def0: 0, sk: 0, pv_id: -99, def_widen: 0, def_pw: 0, waited: false };
                _s.vstart = _s.f;
                _s.xwrong = 0;
                if (_b_battle) {
                    Debug_Init();
                    global.debug.enabled = true;   // an enemy that only uses its damaging skill: the Spider's Poison Fangs, every turn
                    global.debug.enemy_damage_skill_only = true;
                }
                Scenario_GotoBattle(_name + (_b_battle ? "_b" : "_a"), _b_battle ? ENEMY_SPIDER : ENEMY_SLIME);
                Scenario_Next(_s, _b_battle ? 4 : 1);
            }
            break;
        case 1:   // battle A
            if (room != rm_battle || !instance_exists(obj_battle_controller)) {
                if (_s.t > 20) { Scenario_Check(_name + "_a_in_battle", false, "room=" + room_get_name(room)); Scenario_Finish(); }
                break;
            }
            var _bc = instance_find(obj_battle_controller, 0);
            var _t = _s.stt;
            if (_s.f - _s.vstart > 4000) {
                Scenario_Check(_name + "_a_finished", false, "k=" + string(_t.k) + " state=" + string(_bc.battle_state) + " pa=" + string(_t.pa));
                Scenario_Next(_s, 2);
                break;
            }
            var _ready_a = (_s.f - _s.last_tap) >= 4;
            if (_t.k == 0) {   // set up: a sturdy enemy that never acts, 3 Poison stacks on the player
                if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER) {
                    _bc.e.max_hp = 999;
                    _bc.e.hp = 999;
                    _bc.p.max_hp = 99;   // the battle starts with the class's real HP, so raise it here
                    _bc.p.hp = 99;
                    Turn_Push(_bc.tl, TL_ENEMY, 100000);   // B3: the enemy is a very long way down the timeline, so it never acts (the player acts every turn)
                    _bc.p = Status_Add(_bc.p, STATUS_POISON, 0, 0, 3);
                    Scenario_Check(_name + "_poison_3_stacks_applied", Status_Stacks(_bc.p, STATUS_POISON) == 3);
                    _t.k = 1;
                }
            } else if (_t.k >= 1 && _t.k <= 3) {   // three actions: Poison costs 3, 2, 1 and loses a stack each time
                if (Scenario_BotOneAttack(_s, _bc)) {
                    var _loss = _t.hp_before - _bc.p.hp;
                    var _want_loss = 4 - _t.k;
                    Scenario_Check(_name + "_poison_tick_" + string(_t.k) + "_costs_" + string(_want_loss), _loss == _want_loss, "lost " + string(_loss));
                    Scenario_Check(_name + "_poison_stacks_after_action_" + string(_t.k) + "_is_" + string(3 - _t.k), Status_Stacks(_bc.p, STATUS_POISON) == 3 - _t.k, "stacks=" + string(Status_Stacks(_bc.p, STATUS_POISON)));
                    if (_t.k == 3) {
                        Scenario_Check(_name + "_poison_gone_at_0_stacks", !Status_Has(_bc.p, STATUS_POISON));
                        Scenario_Check(_name + "_poison_tick_logged", Scenario_BotLogCount(_bc, "Poison hurts you") >= 3);
                        _t.def0 = Combat_EffectiveStat(_bc.p, STAT_DEF);
                        _bc.p = Status_Add(_bc.p, STATUS_BURN, 2, 4);   // Burning: a fixed tick of 4 for 2 turns, DEF x0.75
                        Scenario_Check(_name + "_burn_lowers_def", Combat_EffectiveStat(_bc.p, STAT_DEF) == Status_BurnDef(_t.def0) && Combat_EffectiveStat(_bc.p, STAT_DEF) < _t.def0,
                            "def0=" + string(_t.def0) + " now=" + string(Combat_EffectiveStat(_bc.p, STAT_DEF)));
                        _bc.p = Status_Add(_bc.p, STATUS_BURN, 2, 4);
                        Scenario_Check(_name + "_burn_reapply_does_not_stack", array_length(_bc.p.status) == 1 && Battle_StatusCurrentTurns(_bc.p, STATUS_BURN) == 2);
                    }
                    _t.k++;
                }
            } else if (_t.k == 4 || _t.k == 5) {   // Burning: 4 HP per action for 2 turns, DEF back afterwards
                if (Scenario_BotOneAttack(_s, _bc)) {
                    var _bloss = _t.hp_before - _bc.p.hp;
                    Scenario_Check(_name + "_burn_tick_" + string(_t.k - 3) + "_costs_4", _bloss == 4, "lost " + string(_bloss));
                    if (_t.k == 4) Scenario_Check(_name + "_burn_1_turn_left", Battle_StatusCurrentTurns(_bc.p, STATUS_BURN) == 1, "turns=" + string(Battle_StatusCurrentTurns(_bc.p, STATUS_BURN)));
                    if (_t.k == 5) {
                        Scenario_Check(_name + "_burn_ends_after_2_turns", !Status_Has(_bc.p, STATUS_BURN));
                        Scenario_Check(_name + "_def_restored_after_burn", Combat_EffectiveStat(_bc.p, STAT_DEF) == _t.def0);
                        // Bleeding (2 stacks, 3 turns): 4 HP per action, ends after the 3rd turn (a stunned turn no longer exists, D75: stun is a push-back)
                        _bc.p = Status_Add(_bc.p, STATUS_BLEED, 3, 0, 2);
                        _t.hp_before = _bc.p.hp;
                    }
                    _t.k++;
                }
            } else if (_t.k >= 6 && _t.k <= 8) {   // three actions: Bleeding costs 2 x 2 stacks each, and ends after its 3rd turn
                if (Scenario_BotOneAttack(_s, _bc)) {
                    var _dloss = _t.hp_before - _bc.p.hp;
                    Scenario_Check(_name + "_bleed_action_" + string(_t.k - 5) + "_costs_4", _dloss == 4, "lost " + string(_dloss));
                    if (_t.k == 6) Scenario_Check(_name + "_bleed_2_turns_left", Battle_StatusCurrentTurns(_bc.p, STATUS_BLEED) == 2, "turns=" + string(Battle_StatusCurrentTurns(_bc.p, STATUS_BLEED)));
                    if (_t.k == 7) Scenario_Check(_name + "_bleed_1_turn_left", Battle_StatusCurrentTurns(_bc.p, STATUS_BLEED) == 1);
                    if (_t.k == 8) Scenario_Check(_name + "_bleed_ends_after_3_turns", !Status_Has(_bc.p, STATUS_BLEED));
                    _t.k++;
                }
            } else {
                Scenario_Next(_s, 2);
            }
            break;
        case 2:   // measured: battle B next (the battle is simply abandoned)
            if (_s.t == 5) Scenario_Next(_s, 3);
            break;
        case 4:   // battle B
            if (room != rm_battle || !instance_exists(obj_battle_controller)) {
                if (_s.t > 20) { Scenario_Check(_name + "_b_in_battle", false, "room=" + room_get_name(room)); Scenario_Finish(); }
                break;
            }
            var _bcb = instance_find(obj_battle_controller, 0);
            var _tb = _s.stt;
            if (_s.f - _s.vstart > 4500) {
                Scenario_Check(_name + "_b_finished", false, "k=" + string(_tb.k) + " state=" + string(_bcb.battle_state) + " sk=" + string(_tb.sk));
                global.debug.enabled = false;
                global.debug.enemy_damage_skill_only = false;
                _s.v = 7;
                Scenario_Next(_s, 0);
                break;
            }
            var _ready_b = (_s.f - _s.last_tap) >= 4;
            if (_tb.k == 0) {   // cast Foresight through the menu and the arrows
                if (_tb.sk == 0) {
                    if (_bcb.battle_state == BSTATE_MENU && _bcb.turn == TURN_PLAYER && _ready_b) {
                        _bcb.e.max_hp = 999;
                        _bcb.e.hp = 999;
                        _bcb.p.max_hp = 99;
                        _bcb.p.hp = 99;
                        _bcb.p.max_mp = 99;
                        _bcb.p.mp = 99;
                        Scenario_Tap((_bcb.menu_index != 1) ? "menu_down" : "confirm");
                    } else if (_bcb.battle_state == BSTATE_SKILL_MENU && _ready_b) {
                        Scenario_Tap("confirm");
                        _tb.sk = 1;
                    }
                } else if (_tb.sk == 1) {
                    Scenario_BotArrows(_s, _bcb, "right");
                    if (_bcb.battle_state == BSTATE_SKILL_QTE) _tb.sk = 2;
                } else if (_tb.sk == 2) {
                    Scenario_BotArrows(_s, _bcb, "right");
                    if (_bcb.battle_state != BSTATE_SKILL_QTE) {   // the sequence ended and Foresight was cast
                        var _pv = Battle_EnemyNextActionPreview(_bcb);
                        Scenario_Check(_name + "_foresight_cast_with_3_turns", Battle_StatusCurrentTurns(_bcb.p, STATUS_HIT_UP) == 3, "turns=" + string(Battle_StatusCurrentTurns(_bcb.p, STATUS_HIT_UP)));
                        Scenario_Check(_name + "_preview_visible_and_names_the_big_attack", _pv.visible && _pv.kind == "skill" && _pv.skill_id == SKILL_POISON_FANGS && _pv.big, "kind=" + _pv.kind + " id=" + string(_pv.skill_id));
                        var _fs = Scenario_BotForesightSlot(_bcb);   // the enemy acts next, so its own (current) slot holds the action
                        Scenario_Check(_name + "_foresight_shown_on_the_enemy_slot_of_the_strip", is_struct(_fs) && _fs.idx == 0 && _fs.slot.who == TL_ENEMY && _fs.slot.foresight.skill_id == SKILL_POISON_FANGS && _fs.slot.foresight.big, is_struct(_fs) ? string(_fs.idx) : "none");
                        Scenario_Check(_name + "_foresee_text_names_the_attack", string_pos("You foresee: " + SkillDB_Get(SKILL_POISON_FANGS).name, _pv.text) > 0, _pv.text);
                        Scenario_Check(_name + "_no_foresee_log_lines_any_more_the_strip_shows_it", Scenario_BotLogCount(_bcb, "You foresee:") == 0);
                        _tb.pv_id = _pv.skill_id;
                        _tb.k = 1;
                    }
                }
            } else if (_tb.k == 1) {   // the enemy acts; its defence bar is up for a while: Foresight widens it too
                if (_bcb.battle_state == BSTATE_ENEMY_DEFENCE && _bcb.def_active && _tb.def_widen == 0) {
                    _tb.def_widen = _bcb.def_perfect_widen;
                    _tb.def_pw = _bcb.def_params.perfect_half_width;
                }
                if (_bcb.battle_state == BSTATE_MENU && _bcb.turn == TURN_PLAYER) {
                    Scenario_Check(_name + "_enemy_did_what_foresight_showed", _bcb.enemy_last_skill_id == _tb.pv_id, "did=" + string(_bcb.enemy_last_skill_id) + " showed=" + string(_tb.pv_id));
                    Scenario_Check(_name + "_defence_bar_perfect_zone_x1.5", _tb.def_widen == 1.5 && abs(_tb.def_pw - Qte_DefenceParams(SKILL_POISON_FANGS).perfect_half_width * 1.5) < 0.001, "widen=" + string(_tb.def_widen) + " pw=" + string(_tb.def_pw));
                    var _fs2 = Scenario_BotForesightSlot(_bcb);   // the player's turn: the next enemy slot carries the enemy's next action
                    Scenario_Check(_name + "_strip_shows_the_next_enemy_action", is_struct(_fs2) && _fs2.idx >= 1 && _fs2.slot.who == TL_ENEMY && Battle_EnemyNextActionPreview(_bcb).visible, is_struct(_fs2) ? string(_fs2.idx) : "none");
                    Scenario_Check(_name + "_foresight_still_3_turns_after_the_cast_turn", Battle_StatusCurrentTurns(_bcb.p, STATUS_HIT_UP) == 3);
                    _tb.k = 2;
                }
            } else if (_tb.k >= 2 && _tb.k <= 5) {   // four actions: Foresight on for the first three (bar x1.5, turns 2, 1, gone), off for the fourth
                if (Scenario_BotOneAttack(_s, _bcb)) {
                    var _on = (_tb.k <= 4);
                    var _base_pw = Qte_BarParams(Qte_WeaponKind(_bcb.player_weapon)).perfect_half_width;
                    Scenario_Check(_name + "_attack_" + string(_tb.k - 1) + "_perfect_zone_" + (_on ? "x1.5" : "normal"), abs(_tb.pw - _base_pw * (_on ? 1.5 : 1)) < 0.001 && _tb.widen == (_on ? 1.5 : 1), "pw=" + string(_tb.pw) + " base=" + string(_base_pw));
                    if (_tb.k == 2) Scenario_Check(_name + "_foresight_2_turns_left", Battle_StatusCurrentTurns(_bcb.p, STATUS_HIT_UP) == 2);
                    if (_tb.k == 3) Scenario_Check(_name + "_foresight_1_turn_left", Battle_StatusCurrentTurns(_bcb.p, STATUS_HIT_UP) == 1);
                    if (_tb.k == 4) {
                        Scenario_Check(_name + "_foresight_over_after_3_turns", !Status_Has(_bcb.p, STATUS_HIT_UP));
                        Scenario_Check(_name + "_preview_hidden_again", !Battle_EnemyNextActionPreview(_bcb).visible);
                    }
                    if (_tb.k == 5) Scenario_Check(_name + "_strip_shows_nothing_after_foresight_ended", !is_struct(Scenario_BotForesightSlot(_bcb)));
                    _tb.k++;
                }
            } else {
                global.debug.enabled = false;
                global.debug.enemy_damage_skill_only = false;
                _s.v = 7;   // on to the turn timeline (B3), then movement and AI
                Scenario_Next(_s, 0);
            }
            break;
    }
}

// ---- v=7: the turn timeline, stun push-back, Steadfast, stagger and BREAK (B3: D19 D74 D75 D92) ----
// One player action through the real input path. _t.ac: 0 wait for the menu, 1 attack bar up, 2 skill menu, 3 wait for the arrows, 4 arrows.
// Returns true on the frame the action has just resolved (the battle is in its message state, the timeline already points at the next actor).
// _kind "attack" (the first menu row) or "skill" (the second row, its first skill, arrows typed right); _perfect presses the attack bar on its zone.
function Scenario_BotAct(_s, _bc, _kind, _perfect) {
    var _t = _s.stt;
    var _ready = (_s.f - _s.last_tap) >= 4;
    switch (_t.ac) {
        case 0:
            if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER && _ready) {
                var _want = (_kind == "attack") ? 0 : 1;
                if (_bc.menu_index != _want) {
                    Scenario_Tap((_bc.menu_index < _want) ? "menu_down" : "menu_up");
                } else {
                    Scenario_Tap("confirm");
                    _t.ac = (_kind == "attack") ? 1 : 2;
                }
            }
            break;
        case 1:
            if (_bc.battle_state == BSTATE_ATTACK_TIMING) {
                if (_perfect && _ready && _bc.qte_active && (Qte_ZoneCentreMs(_bc.qte_params) - _bc.qte_ms) <= Qte_StepMs(delta_time) * 1.5) Scenario_Tap("confirm");
            } else if (_bc.battle_state == BSTATE_MESSAGE) {
                _t.ac = 0;
                return true;
            }
            break;
        case 2:
            if (_bc.battle_state == BSTATE_SKILL_MENU && _ready) {
                Scenario_Tap("confirm");
                _t.ac = 3;
            }
            break;
        case 3:
            Scenario_BotArrows(_s, _bc, "right");
            if (_bc.battle_state == BSTATE_SKILL_QTE) _t.ac = 4;
            break;
        case 4:
            Scenario_BotArrows(_s, _bc, "right");
            if (_bc.battle_state != BSTATE_SKILL_QTE) {
                _t.ac = 0;
                return true;
            }
            break;
    }
    return false;
}

function Scenario_BotTurnString(_log, _n) {
    var _out = "";
    for (var _i = 0; _i < _n && _i < array_length(_log); _i++) _out += (_log[_i] == TL_PLAYER) ? "P" : "E";
    return _out;
}

function Scenario_BotPreviewString(_tl, _n) {
    var _pv = Turn_Preview(_tl, _n);
    return Scenario_BotTurnString(_pv, _n);
}

// The same battle as the game plays it, advanced by the model: SPD read again, then the next actor.
function Scenario_BotModelAdvance(_tl, _bc) {
    Turn_SetSpd(_tl, TL_PLAYER, Combat_EffectiveStat(_bc.p, STAT_SPD));
    Turn_SetSpd(_tl, TL_ENEMY, Combat_EffectiveStat(_bc.e, STAT_SPD));
    return Turn_Next(_tl);
}

function Scenario_StepBotTurns(_s) {
    var _name = "bot_turns";
    switch (_s.step) {
        case 0:   // battle A: an Archer (SPD 13) against a Slime made very slow
        case 3:   // battle B: a Knight with Hilt Bash (stun, then BREAK)
            if (_s.t == 10) {
                var _b_battle = (_s.step == 3);
                var _gs = Scenario_NewKnight(_b_battle ? CLASS_KNIGHT : CLASS_ARCHER);
                var _ch = _gs.player_ch;
                _ch.max_hp = 99;
                _ch.hp = 99;
                _ch.max_mp = 99;
                _ch.mp = 99;
                if (_b_battle) _ch.skills = [SKILL_HILT_BASH];
                GameState_SetPlayer(_ch);
                if (_b_battle) SkillDB_Get(SKILL_HILT_BASH).status_chance = 1;   // the stun always lands, so there is something to check
                _s.stt = { ac: 0, k: 0, n: 0, base: undefined, pv: "", len0: 0, snap: false, st0: 0, grade: "", brk: false, enemy_seen: false };
                _s.vstart = _s.f;
                _s.xwrong = 0;
                Scenario_GotoBattle(_name + (_b_battle ? "_b" : "_a"), ENEMY_SLIME);
                Scenario_Next(_s, _b_battle ? 4 : 1);
            }
            break;
        case 1:   // battle A
            if (room != rm_battle || !instance_exists(obj_battle_controller)) {
                if (_s.t > 20) { Scenario_Check(_name + "_a_in_battle", false, "room=" + room_get_name(room)); Scenario_Finish(); }
                break;
            }
            var _bc = instance_find(obj_battle_controller, 0);
            var _t = _s.stt;
            if (_s.f - _s.vstart > 3500) {
                Scenario_Check(_name + "_a_finished", false, "k=" + string(_t.k) + " state=" + string(_bc.battle_state));
                Scenario_Next(_s, 2);
                break;
            }
            if (_t.k == 0) {
                if (_bc.battle_state == BSTATE_MENU && _bc.turn == TURN_PLAYER) {   // the Archer (13) is first against the Slime (9)
                    _t.base = Turn_New([Turn_Fighter(TL_PLAYER, Combat_EffectiveStat(_bc.p, STAT_SPD)), Turn_Fighter(TL_ENEMY, Combat_EffectiveStat(_bc.e, STAT_SPD))]);   // how the battle began ...
                    Turn_Next(_t.base);
                    _bc.e.max_hp = 999;
                    _bc.e.hp = 999;
                    _bc.e.stats.spd = 4;
                    _bc.e.skills = [];   // basic attacks only: no skill can change its SPD or its guard
                    _bc.e.stagger_max = 999;   // and no BREAK push-back: this battle is about SPD alone
                    Scenario_Check(_name + "_a_archer_acts_first_against_the_slime", _bc.turn_log[0] == TL_PLAYER);
                    _t.k = 1;
                }
            } else if (_t.k <= 10) {   // ten attacks without pressing (Weak is enough)
                if (Scenario_BotAct(_s, _bc, "attack", false)) _t.k++;
            } else {
                var _n = array_length(_bc.turn_log);
                var _want = "P";
                for (var _i = 1; _i < _n; _i++) {
                    Turn_SetSpd(_t.base, TL_PLAYER, Combat_EffectiveStat(_bc.p, STAT_SPD));
                    Turn_SetSpd(_t.base, TL_ENEMY, 4);   // ... and the Slime slowed to 4 from its first turn on
                    _want += (Turn_Next(_t.base) == TL_PLAYER) ? "P" : "E";
                }
                var _got = Scenario_BotTurnString(_bc.turn_log, _n);
                var _ne = string_count("E", _got);
                Scenario_Check(_name + "_a_real_turns_follow_the_timeline_model", _got == _want, "got " + _got + " want " + _want + " spd p=" + string(Combat_EffectiveStat(_bc.p, STAT_SPD)) + " e=" + string(Combat_EffectiveStat(_bc.e, STAT_SPD)) + " e.status=" + json_stringify(_bc.e.status) + " p.status=" + json_stringify(_bc.p.status));
                Scenario_Check(_name + "_a_fast_player_acts_twice_before_a_slow_enemy", string_pos("PP", _got) > 0, _got);
                Scenario_Check(_name + "_a_player_acts_at_least_twice_as_often_as_the_slow_enemy", (_n - _ne) >= 2 * _ne && _ne >= 1, _got);
                Scenario_Check(_name + "_a_strip_preview_is_the_next_five_turns", Scenario_BotPreviewString(_bc.tl, 5) == Scenario_BotPreviewString(Turn_Copy(_bc.tl), 5) && array_length(Battle_TimelineSlots(_bc)) == 5);
                Scenario_Check(_name + "_a_no_extra_action_counter_left", !variable_instance_exists(_bc, "player_bonus_actions_remaining"));
                Scenario_Next(_s, 2);
            }
            break;
        case 2:   // measured: battle B next (the battle is simply abandoned)
            if (_s.t == 5) Scenario_Next(_s, 3);
            break;
        case 4:   // battle B
            if (room != rm_battle || !instance_exists(obj_battle_controller)) {
                if (_s.t > 20) { Scenario_Check(_name + "_b_in_battle", false, "room=" + room_get_name(room)); Scenario_Finish(); }
                break;
            }
            var _bcb = instance_find(obj_battle_controller, 0);
            var _tb = _s.stt;
            if (_s.f - _s.vstart > 7000) {
                Scenario_Check(_name + "_b_finished", false, "k=" + string(_tb.k) + " state=" + string(_bcb.battle_state));
                SkillDB_Get(SKILL_HILT_BASH).status_chance = 0.6;
                Scenario_Next(_s, 20);   // on to the battle AI (B4), then movement and AI (v=5)
                break;
            }
            if (_tb.k == 0) {   // set up: a sturdy Slime whose BREAK meter is out of the way for now
                if (_bcb.battle_state == BSTATE_MENU && _bcb.turn == TURN_PLAYER) {
                    _bcb.e.max_hp = 999;
                    _bcb.e.hp = 999;
                    _bcb.e.stagger_max = 999;
                    _tb.base = Turn_Copy(_bcb.tl);
                    _tb.k = 1;
                }
            } else if (_tb.k == 1) {   // Hilt Bash (stun, chance 1)
                if (Scenario_BotAct(_s, _bcb, "skill", true)) {
                    Turn_SetSpd(_tb.base, TL_PLAYER, Combat_EffectiveStat(_bcb.p, STAT_SPD));   // what the timeline would be without the stun: SPD read again, the player's turn used up
                    Turn_SetSpd(_tb.base, TL_ENEMY, Combat_EffectiveStat(_bcb.e, STAT_SPD));
                    var _plain_next = Turn_Next(_tb.base);
                    var _en = Turn_Find(_bcb.tl, TL_ENEMY);
                    Scenario_Check(_name + "_b_stun_makes_the_enemy_steadfast_for_2_turns", _en.steadfast == TURN_STEADFAST_TURNS, "steadfast=" + string(_en.steadfast));
                    Scenario_Check(_name + "_b_stun_marker_consumed", !Status_Has(_bcb.e, STATUS_STUN));
                    Scenario_Check(_name + "_b_pushed_back_message_logged", Scenario_BotLogCount(_bcb, "pushed back") >= 1);
                    var _seq_plain = ((_plain_next == TL_PLAYER) ? "P" : "E") + Scenario_BotPreviewString(_tb.base, 5);   // the turns from here on, without the stun ...
                    var _seq_stun = ((_bcb.tl_who == TL_PLAYER) ? "P" : "E") + Scenario_BotPreviewString(_bcb.tl, 5);   // ... and with it
                    Scenario_Check(_name + "_b_the_enemy_turn_is_pushed_later_on_the_strip", string_pos("E", _seq_stun) > string_pos("E", _seq_plain) && _seq_plain != _seq_stun, "plain " + _seq_plain + " stunned " + _seq_stun);
                    var _lead = 0;
                    var _pv1 = Turn_Preview(_bcb.tl, 6);
                    while (_lead < array_length(_pv1) && _pv1[_lead] == TL_PLAYER) _lead++;
                    Scenario_Check(_name + "_b_no_extra_player_actions_after_a_stun", _lead <= 2, "player turns in a row after the stun: " + string(_lead));
                    Scenario_Check(_name + "_b_no_extra_action_counter_left", !variable_instance_exists(_bcb, "player_bonus_actions_remaining"));
                    _tb.k = 2;
                    _tb.snap = false;
                }
            } else if (_tb.k == 2) {   // a second Hilt Bash while the Slime is Steadfast: resisted, nothing moves
                if (_tb.ac == 0 && !_tb.snap && _bcb.battle_state == BSTATE_MENU && _bcb.turn == TURN_PLAYER) {
                    _tb.base = Turn_Copy(_bcb.tl);
                    Turn_SetSpd(_tb.base, TL_PLAYER, Combat_EffectiveStat(_bcb.p, STAT_SPD));
                    Turn_SetSpd(_tb.base, TL_ENEMY, Combat_EffectiveStat(_bcb.e, STAT_SPD));
                    _tb.st0 = Turn_Find(_bcb.tl, TL_ENEMY).steadfast;
                    _tb.snap = true;
                }
                if (Scenario_BotAct(_s, _bcb, "skill", true)) {
                    Turn_Next(_tb.base);
                    Scenario_Check(_name + "_b_second_stun_is_resisted_by_steadfast", Scenario_BotLogCount(_bcb, "Steadfast") >= 1 && _tb.st0 >= 1);
                    Scenario_Check(_name + "_b_resisted_stun_moves_nothing", Scenario_BotPreviewString(_bcb.tl, 6) == Scenario_BotPreviewString(_tb.base, 6), Scenario_BotPreviewString(_bcb.tl, 6) + " vs " + Scenario_BotPreviewString(_tb.base, 6));
                    _tb.pv = Scenario_BotPreviewString(_bcb.tl, 6);
                    _tb.len0 = array_length(_bcb.turn_log);
                    _tb.k = 3;
                }
            } else if (_tb.k == 3) {   // play on with plain attacks: the real turns must be exactly what the strip promised
                if (Scenario_BotAct(_s, _bcb, "attack", false)) {
                    if (array_length(_bcb.turn_log) >= _tb.len0 + 6) {
                        var _real = "";
                        for (var _ri = 0; _ri < 6; _ri++) _real += (_bcb.turn_log[_tb.len0 + _ri] == TL_PLAYER) ? "P" : "E";
                        Scenario_Check(_name + "_b_real_turns_are_the_strip_preview", _real == _tb.pv, "real " + _real + " strip " + _tb.pv);
                        _tb.k = 4;
                        _tb.snap = false;
                        _tb.n = 0;
                    }
                }
            } else if (_tb.k == 4) {   // BREAK: Perfect attacks until the meter fills (8 for a Slime)
                if (_tb.ac == 0 && !_tb.snap && _bcb.battle_state == BSTATE_MENU && _bcb.turn == TURN_PLAYER) {
                    if (_tb.n == 0) {   // the Slime is made slow so that the player acts again before it does
                        _bcb.e.stats.spd = 3;
                        _bcb.e.stagger_max = 8;
                        _bcb.e.stagger = 0;
                    }
                    _tb.base = Turn_Copy(_bcb.tl);
                    Turn_SetSpd(_tb.base, TL_PLAYER, Combat_EffectiveStat(_bcb.p, STAT_SPD));
                    Turn_SetSpd(_tb.base, TL_ENEMY, Combat_EffectiveStat(_bcb.e, STAT_SPD));
                    _tb.st0 = _bcb.e.stagger;
                    _tb.snap = true;
                }
                if (Scenario_BotAct(_s, _bcb, "attack", true)) {
                    _tb.n++;
                    _tb.snap = false;
                    var _gk = _bcb.qte_result_key;
                    var _gain = Stagger_Gain(Combat_BasicSource(_bcb.player_weapon).power, false, _gk == QTE_PERFECT);
                    if (!_bcb.e.broken) {
                        Scenario_Check(_name + "_b_stagger_meter_fills_by_the_formula_" + string(_tb.n), _bcb.e.stagger == _tb.st0 + _gain, "grade " + _gk + " gain " + string(_gain) + " " + string(_tb.st0) + " -> " + string(_bcb.e.stagger));
                    } else {
                        Scenario_Check(_name + "_b_full_meter_is_a_break", _tb.st0 + _gain >= 8 && _bcb.e.stagger == 0, "grade " + _gk + " " + string(_tb.st0) + " + " + string(_gain));
                        Scenario_Check(_name + "_b_break_message_logged", Scenario_BotLogCount(_bcb, "BREAK") >= 1);
                        Turn_Next(_tb.base);
                        Turn_Push(_tb.base, TL_ENEMY);
                        Scenario_Check(_name + "_b_break_pushes_the_enemy_back_one_turn", Scenario_BotPreviewString(_bcb.tl, 6) == Scenario_BotPreviewString(_tb.base, 6), Scenario_BotPreviewString(_bcb.tl, 6) + " vs " + Scenario_BotPreviewString(_tb.base, 6));
                        Scenario_Check(_name + "_b_break_pop_started", (current_time - _bcb.break_start) < 1000);
                        _tb.k = 5;
                    }
                    if (_tb.n > 8 && _tb.k == 4) { Scenario_Check(_name + "_b_break_reached", false, "meter " + string(_bcb.e.stagger)); _tb.k = 7; }
                }
            } else if (_tb.k == 5) {   // while BROKEN the next hit does +50%; a plain Weak hit, from a fresh Slime copy for the expected number
                if (_tb.ac == 0 && _bcb.battle_state == BSTATE_MENU && _bcb.turn == TURN_PLAYER) {
                    if (_bcb.e.broken) {
                        _bcb.e.status = [];   // no Solidify guard in the way
                        _tb.pv = "armed";
                    } else {
                        Scenario_Check(_name + "_b_player_acted_again_before_the_enemy", false, "the break was already over: the enemy acted first");
                        _tb.k = 7;
                    }
                }
                if (_tb.pv == "armed" && Scenario_BotAct(_s, _bcb, "attack", false)) {
                    var _src = Combat_BasicSource(_bcb.player_weapon);
                    var _plain = EnemyCreate(ENEMY_SLIME);
                    var _broken = EnemyCreate(ENEMY_SLIME);
                    _broken.broken = true;
                    var _w_plain = Combat_ApplyDamage(_bcb.p, _plain, _src, 1, 1, { is_skill: false, grade_mult: 0.75 }).dmg;
                    var _w_broken = Combat_ApplyDamage(_bcb.p, _broken, _src, 1, 1, { is_skill: false, grade_mult: 0.75 }).dmg;
                    Scenario_Check(_name + "_b_break_hit_does_more_than_a_plain_one", _w_broken > _w_plain, "plain " + string(_w_plain) + " broken " + string(_w_broken));
                    Scenario_Check(_name + "_b_broken_enemy_takes_the_plus_50_percent", _bcb.last_dmg == _w_broken, "dealt " + string(_bcb.last_dmg) + " want " + string(_w_broken));
                    _tb.k = 6;
                }
            } else if (_tb.k == 6) {   // BROKEN ends when the enemy's next turn starts
                if (_bcb.tl_who == TL_ENEMY) {
                    Scenario_Check(_name + "_b_break_ends_when_the_enemy_turn_starts", !_bcb.e.broken);
                    _tb.k = 7;
                } else {
                    Scenario_BotAct(_s, _bcb, "attack", false);
                }
            } else {
                SkillDB_Get(SKILL_HILT_BASH).status_chance = 0.6;
                Scenario_Next(_s, 20);   // on to the battle AI (B4), then movement and AI (v=5)
            }
            break;
    }
}

// ---- B4: the battle AI through the real battle flow (bot v=7, steps 20..33; combat-spec.md section 12) ----
// A: Killer Plant at 30% HP heals once (rule low_hp_heal), then the 3rd turn is a wind-up (strip "!"), the 4th the big attack through the defence bar (Perfect).
// B: the same wind-up cancelled by a BREAK: the enemy does a plain attack instead and the bar never comes.
// C: Mad Whisp vs a buffed player Snuffs the buff; unbuffed it does not.
// D: Palehorn crosses 60% and 30%, then the Pale Choirbeast starts at 20%: banners, +SPD/+ATK in the stats and on the timeline, no double action.
function Scenario_BotAIBegin(_s, _name, _enemy, _step_next) {
    Scenario_NewKnight(CLASS_KNIGHT);
    _s.stt = { ac: 0, k: 0, n: 0, hp0: 0, def_seen: false, len0: 0, max_actions: 0, base_hp: 0, dmg_base: 0, took: 0, last: "" };
    _s.vstart = _s.f;
    Scenario_GotoBattle(_name, _enemy);
    Scenario_Next(_s, _step_next);
}

// The battle controller once the battle is up, else noone (and a failed check plus Finish if it never comes).
function Scenario_BotAIController(_s, _name) {
    if (room != rm_battle || !instance_exists(obj_battle_controller)) {
        if (_s.t > 40) { Scenario_Check(_name + "_in_battle", false, "room=" + room_get_name(room) + " k=" + string(_s.stt.k) + " last: " + _s.stt.last); Scenario_Finish(); }
        return noone;
    }
    var _bc = instance_find(obj_battle_controller, 0);
    _s.stt.last = "p.hp=" + string(_bc.p.hp) + "/" + string(_bc.p.max_hp) + " e.hp=" + string(_bc.e.hp) + "/" + string(_bc.e.max_hp) + " state=" + string(_bc.battle_state) + " turns=" + string(_bc.ai.turns) + " over=" + string(_bc.battle_over);
    return _bc;
}

// A sturdy enemy at the given HP share, with its BREAK meter out of the way, and a player nothing can kill (the battle copy: a Knight is rebuilt at 10 HP when the battle starts).
function Scenario_BotAISturdy(_bc, _hp_ratio) {
    _bc.p.max_hp = 9999;
    _bc.p.hp = 9999;
    _bc.e.max_hp = 1000;
    _bc.e.hp = round(1000 * _hp_ratio);
    _bc.enemy_hp_shown = _bc.e.hp;
    _bc.e.stagger_max = 99999;
}

// The slot of the strip that carries the wind-up "!" (or undefined).
function Scenario_BotWindupSlot(_bc) {
    var _slots = Battle_TimelineSlots(_bc);
    for (var _i = 0; _i < array_length(_slots); _i++) {
        if (_slots[_i].windup) return _slots[_i];
    }
    return undefined;
}

function Scenario_BotLogIndex(_bc, _needle) {
    for (var _i = 0; _i < array_length(_bc.combat_log); _i++) {
        if (string_pos(_needle, _bc.combat_log[_i].text) > 0) return _i;
    }
    return -1;
}

function Scenario_BotLogTail(_bc, _n) {
    var _out = "";
    for (var _i = max(0, array_length(_bc.combat_log) - _n); _i < array_length(_bc.combat_log); _i++) _out += "[" + _bc.combat_log[_i].text + "] ";
    return _out;
}

function Scenario_BotTurnsSince(_bc, _from) {
    var _out = "";
    for (var _i = _from; _i < array_length(_bc.turn_log); _i++) _out += (_bc.turn_log[_i] == TL_PLAYER) ? "P" : "E";
    return _out;
}

function Scenario_StepBotAI(_s) {
    switch (_s.step) {
        case 20:   // A: Killer Plant
        case 23:   // B: Killer Plant, BREAK
        case 26:   // C: Mad Whisp
        case 29:   // D1: Palehorn
        case 32:   // D2: Pale Choirbeast
            if (_s.t == 10) {
                var _names = { s20: "bot_ai_plant", s23: "bot_ai_break", s26: "bot_ai_whisp", s29: "bot_ai_palehorn", s32: "bot_ai_choirbeast" };
                var _enemies = { s20: ENEMY_KILLER_PLANT, s23: ENEMY_KILLER_PLANT, s26: ENEMY_MADWHISP, s29: ENEMY_MINI_BOSS, s32: ENEMY_FINAL_BOSS };
                var _key = "s" + string(_s.step);
                Scenario_BotAIBegin(_s, variable_struct_get(_names, _key), variable_struct_get(_enemies, _key), _s.step + 1);
            }
            break;
        case 22: case 25: case 28: case 31:   // measured: the next battle (the battle is simply abandoned)
            if (_s.t == 5) Scenario_Next(_s, _s.step + 1);
            break;

        case 21:   // A
            var _bcA = Scenario_BotAIController(_s, "bot_ai_plant");
            if (_bcA == noone) break;
            var _a = _s.stt;
            if (_s.f - _s.vstart > 3500) {
                Scenario_Check("bot_ai_plant_finished", false, "k=" + string(_a.k) + " turns=" + string(_bcA.ai.turns) + " state=" + string(_bcA.battle_state));
                Scenario_Next(_s, 22);
                break;
            }
            var _a_menu = (_bcA.battle_state == BSTATE_MENU && _bcA.turn == TURN_PLAYER);
            if (_a.k == 0) {   // 30 / 100 HP, the BREAK meter out of the way
                Scenario_BotAISturdy(_bcA, 0.30);
                _a.k = 1;
            } else if (_a.k == 1) {   // the first enemy turn: the heal
                if (_bcA.ai.turns >= 1 && _a_menu) {
                    var _heal_ok = (_bcA.enemy_last_skill_id == SKILL_REGROW);
                    Scenario_Check("bot_ai_plant_low_hp_enemy_heals_first", _heal_ok, "last skill " + string(_bcA.enemy_last_skill_id) + " rule uses " + json_stringify(_bcA.ai.uses));
                    Scenario_Check("bot_ai_plant_heal_raised_its_hp", _bcA.e.hp > 300, "hp=" + string(_bcA.e.hp));
                    Scenario_Check("bot_ai_plant_heal_logged", Scenario_BotLogCount(_bcA, "regrows") == 1);
                    Scenario_Check("bot_ai_plant_heal_rule_counted_once", variable_struct_exists(_bcA.ai.uses, "low_hp_heal") && variable_struct_get(_bcA.ai.uses, "low_hp_heal") == 1);
                    _bcA.e.hp = 200;   // still below 40%: the heal rule is spent, it must not heal again
                    _bcA.enemy_hp_shown = 200;
                    _a.k = 2;
                } else if (_a.ac != 0 || _a_menu) {
                    Scenario_BotAct(_s, _bcA, "attack", false);
                }
            } else if (_a.k == 2) {   // turn 2 is a plain attack; remember the player's HP before turn 3
                if (_bcA.ai.turns == 2 && _a_menu && _a.ac == 0) {
                    _a.hp0 = _bcA.p.hp;
                    _a.k = 3;
                } else if (_a.ac != 0 || _a_menu) {
                    Scenario_BotAct(_s, _bcA, "attack", false);
                }
            } else if (_a.k == 3) {   // turn 3: the wind-up
                if (_bcA.ai.turns >= 3 && _a_menu && _a.ac == 0) {
                    var _mark = Scenario_BotWindupSlot(_bcA);
                    Scenario_Check("bot_ai_plant_third_turn_is_a_windup_of_vine_trap", _bcA.ai.windup == SKILL_VINE_TRAP && _bcA.enemy_last_windup == SKILL_VINE_TRAP, "windup=" + string(_bcA.ai.windup));
                    Scenario_Check("bot_ai_plant_windup_does_no_damage", _bcA.p.hp == _a.hp0, "hp " + string(_a.hp0) + " -> " + string(_bcA.p.hp));
                    Scenario_Check("bot_ai_plant_windup_line_logged", Scenario_BotLogCount(_bcA, "coils its vines") == 1);
                    Scenario_Check("bot_ai_plant_windup_mark_on_an_enemy_slot_of_the_strip", is_struct(_mark) && _mark.who == TL_ENEMY);
                    Scenario_Check("bot_ai_plant_no_second_heal", Scenario_BotLogCount(_bcA, "regrows") == 1);
                    Scenario_Check("bot_ai_plant_windup_used_no_skill", _bcA.enemy_last_skill_id == -1);
                    _a.k = 4;
                } else if (_a.ac != 0 || _a_menu) {
                    Scenario_BotAct(_s, _bcA, "attack", false);
                }
            } else if (_a.k == 4) {   // turn 4: the big attack through the defence bar
                if (_bcA.battle_state == BSTATE_ENEMY_DEFENCE && _bcA.def_active) {
                    _a.base_hp = _bcA.def_ctx.hp_before;
                    _a.dmg_base = _bcA.def_ctx.res.dmg;
                    Scenario_Check("bot_ai_plant_big_attack_is_vine_trap_on_the_bar", _bcA.def_skill_id == SKILL_VINE_TRAP, "skill " + string(_bcA.def_skill_id));
                    _a.k = 5;
                } else if (_a.ac != 0 || _a_menu) {
                    Scenario_BotAct(_s, _bcA, "attack", false);
                }
            } else if (_a.k == 5) {   // defend on the Perfect zone
                Scenario_BotDefend(_s, _bcA);
                if (_bcA.battle_state != BSTATE_ENEMY_DEFENCE) {
                    Scenario_Check("bot_ai_plant_big_attack_defended_perfect", _bcA.qte_result_key == QTE_PERFECT, "grade " + string(_bcA.qte_result_key));
                    Scenario_Check("bot_ai_plant_defended_damage_follows_the_grade", (_a.base_hp - _bcA.p.hp) == Qte_DefenceDamage(_a.dmg_base, QTE_PERFECT), "took " + string(_a.base_hp - _bcA.p.hp) + " of " + string(_a.dmg_base));
                    Scenario_Check("bot_ai_plant_windup_is_over_after_the_big_attack", _bcA.ai.windup == -1);
                    Scenario_Next(_s, 22);
                }
            }
            break;

        case 24:   // B
            var _bcB = Scenario_BotAIController(_s, "bot_ai_break");
            if (_bcB == noone) break;
            var _b = _s.stt;
            if (_s.f - _s.vstart > 3000) {
                Scenario_Check("bot_ai_break_finished", false, "k=" + string(_b.k) + " turns=" + string(_bcB.ai.turns) + " state=" + string(_bcB.battle_state));
                Scenario_Next(_s, 25);
                break;
            }
            var _b_menu = (_bcB.battle_state == BSTATE_MENU && _bcB.turn == TURN_PLAYER);
            if (_bcB.battle_state == BSTATE_ENEMY_DEFENCE) _b.def_seen = true;
            if (_b.k == 0) {   // the next enemy turn is its 3rd: a wind-up of Vine Trap
                Scenario_BotAISturdy(_bcB, 1);
                _bcB.ai.turns = 2;
                _b.k = 1;
            } else if (_b.k == 1) {
                if (_bcB.ai.windup == SKILL_VINE_TRAP && _b_menu && _b.ac == 0) {   // the wind-up is up: one hit away from a BREAK
                    _bcB.e.stagger_max = 6;
                    _bcB.e.stagger = 5;
                    Scenario_Check("bot_ai_break_windup_pending_before_the_hit", true);
                    _b.k = 2;
                } else if (_b.ac != 0 || _b_menu) {
                    Scenario_BotAct(_s, _bcB, "attack", false);
                }
            } else if (_b.k == 2) {   // the hit that breaks it
                if (Scenario_BotAct(_s, _bcB, "attack", false)) {
                    Scenario_Check("bot_ai_break_enemy_is_broken", _bcB.e.broken);
                    Scenario_Check("bot_ai_break_cancels_the_windup", _bcB.ai.windup == -1, "windup=" + string(_bcB.ai.windup));
                    Scenario_Check("bot_ai_break_cancel_logged", Scenario_BotLogCount(_bcB, "broken off") == 1);
                    Scenario_Check("bot_ai_break_message_logged", Scenario_BotLogCount(_bcB, "BREAK") >= 1);
                    Scenario_Check("bot_ai_break_cached_plan_dropped", is_undefined(_bcB.enemy_plan));
                    Scenario_Check("bot_ai_break_no_windup_mark_left_on_the_strip", !is_struct(Scenario_BotWindupSlot(_bcB)));
                    _bcB.e.stagger_max = 99999;
                    _b.k = 3;
                }
            } else if (_b.k == 3) {   // play on until its 4th turn is done: a plain attack, never the big one
                if (_bcB.ai.turns >= 4 && _b_menu && _b.ac == 0) {
                    Scenario_Check("bot_ai_break_enemy_turn_4_is_a_plain_attack", _bcB.enemy_last_skill_id == -1, "skill " + string(_bcB.enemy_last_skill_id));
                    Scenario_Check("bot_ai_break_the_defence_bar_never_came", !_b.def_seen);
                    Scenario_Check("bot_ai_break_no_wind_up_pending_afterwards", _bcB.ai.windup == -1);
                    Scenario_Next(_s, 25);
                } else if (_b.ac != 0 || _b_menu) {
                    Scenario_BotAct(_s, _bcB, "attack", false);
                }
            }
            break;

        case 27:   // C
            var _bcC = Scenario_BotAIController(_s, "bot_ai_whisp");
            if (_bcC == noone) break;
            var _c = _s.stt;
            if (_s.f - _s.vstart > 2500) {
                Scenario_Check("bot_ai_whisp_finished", false, "k=" + string(_c.k) + " turns=" + string(_bcC.ai.turns));
                Scenario_Next(_s, 28);
                break;
            }
            var _c_menu = (_bcC.battle_state == BSTATE_MENU && _bcC.turn == TURN_PLAYER);
            if (_c.k == 0) {   // the player is buffed before the Whisp acts
                Scenario_BotAISturdy(_bcC, 1);
                Status_Add(_bcC.p, STATUS_CRIT_UP, 3, 0);
                _c.k = 1;
            } else if (_c.k == 1) {
                if (_bcC.ai.turns >= 1 && _c_menu && _c.ac == 0) {
                    Scenario_Check("bot_ai_whisp_snuffs_a_buffed_player", _bcC.enemy_last_skill_id == SKILL_SNUFF, "skill " + string(_bcC.enemy_last_skill_id));
                    Scenario_Check("bot_ai_whisp_buff_is_gone", !Status_Has(_bcC.p, STATUS_CRIT_UP));
                    Scenario_Check("bot_ai_whisp_snuff_logged", Scenario_BotLogCount(_bcC, "snuffed") == 1);
                    Scenario_Check("bot_ai_whisp_snuff_rule_counted", variable_struct_exists(_bcC.ai.uses, "snuff_buffs") && variable_struct_get(_bcC.ai.uses, "snuff_buffs") == 1);
                    _c.n = _bcC.ai.turns;
                    _c.k = 2;
                } else if (_c.ac != 0 || _c_menu) {
                    Scenario_BotAct(_s, _bcC, "attack", false);
                }
            } else if (_c.k == 2) {   // unbuffed: no Snuff on the next turn
                if (_bcC.ai.turns > _c.n && _c_menu && _c.ac == 0) {
                    Scenario_Check("bot_ai_whisp_unbuffed_player_is_left_alone", _bcC.enemy_last_skill_id != SKILL_SNUFF, "skill " + string(_bcC.enemy_last_skill_id));
                    Scenario_Next(_s, 28);
                } else if (_c.ac != 0 || _c_menu) {
                    Scenario_BotAct(_s, _bcC, "attack", false);
                }
            }
            break;

        case 30:   // D1: Palehorn, 55% then 20%
            var _bcD = Scenario_BotAIController(_s, "bot_ai_palehorn");
            if (_bcD == noone) break;
            var _d = _s.stt;
            if (_s.f - _s.vstart > 4500) {
                Scenario_Check("bot_ai_palehorn_finished", false, "k=" + string(_d.k) + " phase=" + string(_bcD.ai.phase) + " turns=" + string(_bcD.ai.turns));
                Scenario_Next(_s, 31);
                break;
            }
            var _d_menu = (_bcD.battle_state == BSTATE_MENU && _bcD.turn == TURN_PLAYER);
            if (_d.k == 0) {
                Scenario_BotAISturdy(_bcD, 0.55);
                _d.base_hp = EnemyDB_Get(ENEMY_MINI_BOSS).stats.spd;
                _d.dmg_base = EnemyDB_Get(ENEMY_MINI_BOSS).stats.atk;
                _d.k = 1;
            } else if (_d.k == 1) {   // at its first action: phase 1
                if (_bcD.ai.phase == 1 && Scenario_BotLogCount(_bcD, "paws the ground") >= 1) {
                    Scenario_Check("bot_ai_palehorn_phase_1_banner_logged", Scenario_BotLogCount(_bcD, "paws the ground") == 1);
                    Scenario_Check("bot_ai_palehorn_phase_1_spd_plus_2_in_the_stats", _bcD.e.stats.spd == _d.base_hp + 2, "spd " + string(_bcD.e.stats.spd));
                    Scenario_Check("bot_ai_palehorn_phase_1_spd_plus_2_on_the_timeline", Turn_Find(_bcD.tl, TL_ENEMY).spd == _d.base_hp + 2, "tl spd " + string(Turn_Find(_bcD.tl, TL_ENEMY).spd));
                    Scenario_Check("bot_ai_palehorn_phase_1_atk_unchanged", _bcD.e.stats.atk == _d.dmg_base);
                    Scenario_Check("bot_ai_palehorn_phase_1_banner_shown_as_the_skill_banner", _bcD.skill_banner_active && string_pos("paws the ground", _bcD.skill_banner_name) > 0);
                    _d.k = 2;
                }
            } else if (_d.k == 2) {   // the player acts once, then Palehorn is dropped to 20%
                if (_d_menu && _d.ac == 0) {
                    _bcD.e.hp = 200;
                    _bcD.enemy_hp_shown = 200;
                    _d.k = 3;
                }
            } else if (_d.k == 3) {
                if (_bcD.ai.phase == 2 && Scenario_BotLogCount(_bcD, "blind rage") >= 1) {
                    Scenario_Check("bot_ai_palehorn_phase_2_banner_logged", Scenario_BotLogCount(_bcD, "blind rage") == 1);
                    Scenario_Check("bot_ai_palehorn_phase_2_spd_plus_4_in_all", _bcD.e.stats.spd == _d.base_hp + 4, "spd " + string(_bcD.e.stats.spd));
                    Scenario_Check("bot_ai_palehorn_phase_2_atk_plus_3_enrage", _bcD.e.stats.atk == _d.dmg_base + 3, "atk " + string(_bcD.e.stats.atk));
                    Scenario_Check("bot_ai_palehorn_phase_2_timeline_spd", Turn_Find(_bcD.tl, TL_ENEMY).spd == _d.base_hp + 4);
                    _d.len0 = array_length(_bcD.turn_log);
                    _d.k = 4;
                } else if (_d_menu || _d.ac != 0) {
                    Scenario_BotAct(_s, _bcD, "attack", false);
                }
            } else if (_d.k == 4) {   // SPD 16 against the Knight's 8: the enemy acts twice in a row on the real timeline
                if (array_length(_bcD.turn_log) >= _d.len0 + 5) {
                    var _seq = Scenario_BotTurnsSince(_bcD, _d.len0);
                    Scenario_Check("bot_ai_palehorn_phase_2_real_turns_show_the_faster_enemy", string_pos("EE", _seq) > 0, "turns " + _seq);
                    Scenario_Next(_s, 31);
                } else if (_d_menu || _d.ac != 0) {
                    Scenario_BotAct(_s, _bcD, "attack", false);
                }
            }
            break;

        case 33:   // D2: the Pale Choirbeast starts at 20%
            var _bcE = Scenario_BotAIController(_s, "bot_ai_choirbeast");
            if (_bcE == noone) break;
            var _e = _s.stt;
            if (_s.f - _s.vstart > 4500) {
                Scenario_Check("bot_ai_choirbeast_finished", false, "k=" + string(_e.k) + " phase=" + string(_bcE.ai.phase) + " turns=" + string(_bcE.ai.turns));
                _s.v = 5;   // movement and AI
                Scenario_Next(_s, 0);
                break;
            }
            var _e_menu = (_bcE.battle_state == BSTATE_MENU && _bcE.turn == TURN_PLAYER);
            _e.max_actions = max(_e.max_actions, _bcE.enemy_actions_remaining);
            if (_e.k == 0) {
                Scenario_BotAISturdy(_bcE, 0.20);
                _e.base_hp = EnemyDB_Get(ENEMY_FINAL_BOSS).stats.spd;
                _e.dmg_base = EnemyDB_Get(ENEMY_FINAL_BOSS).stats.atk;
                _e.k = 1;
            } else if (_e.k == 1) {
                if (_bcE.ai.phase == 2 && Scenario_BotLogCount(_bcE, "howls in fury") >= 1) {
                    Scenario_Check("bot_ai_choirbeast_skips_to_phase_2", true);
                    Scenario_Check("bot_ai_choirbeast_both_spd_bonuses", _bcE.e.stats.spd == _e.base_hp + 5, "spd " + string(_bcE.e.stats.spd));
                    Scenario_Check("bot_ai_choirbeast_enrage_atk_plus_3", _bcE.e.stats.atk == _e.dmg_base + 3, "atk " + string(_bcE.e.stats.atk));
                    Scenario_Check("bot_ai_choirbeast_phase_banner_logged", Scenario_BotLogCount(_bcE, "howls in fury") == 1);
                    Scenario_Check("bot_ai_choirbeast_fury_is_speed_not_a_double_action", Battle_EnemyActionBudget(_bcE.e) == 1);
                    _e.k = 2;
                }
            } else if (_e.k == 2) {   // its 2nd turn is the Pale Hymn wind-up (phase 2: every 2nd), its 3rd the big attack on the bar
                if (_bcE.ai.turns >= 3 && _e_menu && _e.ac == 0) {
                    var _i_wind = Scenario_BotLogIndex(_bcE, "draws a deep breath");
                    var _i_bar = Scenario_BotLogIndex(_bcE, "Not blocked");   // the bot never presses: the bar ends as Weak
                    Scenario_Check("bot_ai_choirbeast_hymn_windup_logged", _i_wind >= 0, "log " + Scenario_BotLogTail(_bcE, 12));
                    Scenario_Check("bot_ai_choirbeast_big_attack_came_after_the_windup_through_the_bar", _i_bar > _i_wind && _i_wind >= 0, "wind " + string(_i_wind) + " bar " + string(_i_bar));
                    Scenario_Check("bot_ai_choirbeast_never_more_than_one_action_per_turn", _e.max_actions <= 1, "max " + string(_e.max_actions));
                    _s.v = 5;   // on to movement and AI
                    Scenario_Next(_s, 0);
                } else if (_e_menu || _e.ac != 0) {
                    Scenario_BotAct(_s, _bcE, "attack", false);
                }
            }
            break;
    }
}

function Scenario_BotDrive(_s, _bc) {
    var _ready = (_s.f - _s.last_tap) >= 4;
    var _perfect = (_s.v == 0);
    if (_bc.battle_state != BSTATE_ATTACK_TIMING && _bc.hitstop_ms > 0) _s.qhitstop = true;   // the freeze after a Perfect
    if (_s.attacking && _bc.battle_state != BSTATE_ATTACK_TIMING) {   // the swing resolved: log what the bar did (QTE part 1)
        _s.attacking = false;
        _s.tries++;
        _s.hits++;   // a basic attack always lands (D20)
        array_push(_s.qlog, {
            key: _bc.qte_result_key, press_ms: _bc.qte_press_ms, mult: _bc.qte_result_mult, dmg: _bc.last_dmg, crit: _bc.last_crit,
            base: _s.qbase, params: _bc.qte_params, assist: _bc.qte_assist, sfx: global.sfx_last_key, word: _bc.qte_result_text,
            hitstop: _s.qhitstop
        });
    }
    switch (_bc.battle_state) {
        case BSTATE_MENU:
            if (_bc.turn == TURN_PLAYER && _ready) Scenario_Tap("confirm");   // menu_index 0 = ATTACK
            break;
        case BSTATE_ATTACK_TIMING:
            if (_bc.qte_active && !_s.attacking) {   // a new swing
                _s.attacking = true;
                _s.qhitstop = false;
            }
            if (_bc.qte_active) _s.qbase = Combat_Damage(_bc.p, _bc.e, Combat_BasicSource(_bc.player_weapon));
            // The press is read by the controller in this frame or the next, so it is judged one or two frames of the clock later:
            // press when the zone centre is within 1.5 frames, which lands it within a frame and a half of the centre.
            if (_perfect && _ready && _bc.qte_active && (Qte_ZoneCentreMs(_bc.qte_params) - _bc.qte_ms) <= Qte_StepMs(delta_time) * 1.5) {
                Scenario_Tap("confirm");
            }
            break;
        case BSTATE_ENEMY_DEFENCE:
            if (_perfect) Scenario_BotDefend(_s, _bc);
            break;
    }
}

function Scenario_BotEvaluate(_s, _bc, _name) {
    // Battle_CheckEnd does not copy the final hits back into _bc.p/_bc.e, so read the player from game state.
    var _pl = GameState_Get().player_ch;
    var _frames = _s.f - _s.vstart;
    show_debug_message("[BOT] " + _name + " frames=" + string(_frames) + " hp=" + string(_pl.hp) + "/" + string(_pl.max_hp)
        + " swings=" + string(_s.tries) + " non_miss=" + string(_s.hits));
    Scenario_Check(_name + "_ended", true);
    Scenario_Check(_name + "_hp_in_bounds", _pl.hp >= 0 && _pl.hp <= _pl.max_hp, "hp=" + string(_pl.hp) + " max=" + string(_pl.max_hp));

    // QTE part 1: what the bar did on every swing. The bot recomputes the grade and the damage from its own pure-function inputs.
    var _want_key = (_s.v == 0) ? "PERFECT" : "WEAK";
    var _want_mult = (_s.v == 0) ? 1.30 : 0.75;
    var _n = array_length(_s.qlog);
    var _all_key = (_n > 0), _all_fn = (_n > 0), _all_mult = (_n > 0), _all_dmg = (_n > 0), _all_snd = (_n > 0), _all_word = (_n > 0), _all_hs = (_n > 0), _all_press = (_n > 0);
    var _detail = "";
    for (var _i = 0; _i < _n; _i++) {
        var _q = _s.qlog[_i];
        var _centre = Qte_ZoneCentreMs(_q.params);
        var _crit_mult = _q.crit ? 2 : 1;
        var _exp = max(1, floor(floor(_q.base * _crit_mult) * Qte_GradeMult(_q.key)));
        show_debug_message("[BOT] " + _name + " swing " + string(_i) + " grade=" + _q.key + " press_ms=" + string(_q.press_ms) + " centre_ms=" + string(_centre)
            + " off_ms=" + string(abs(_q.press_ms - _centre)) + " sweep_ms=" + string(_q.params.sweep_ms) + " mult=" + string(_q.mult)
            + " base=" + string(_q.base) + " crit=" + string(_q.crit) + " dmg=" + string(_q.dmg) + " expected_min=" + string(_exp) + " sfx=" + string(_q.sfx) + " hitstop=" + string(_q.hitstop));
        if (_q.key != _want_key) { _all_key = false; _detail += " swing" + string(_i) + "=" + _q.key; }
        if (Qte_Grade(_q.press_ms, _q.params, _q.assist) != _q.key) _all_fn = false;   // the grade is the pure function of the press
        if (abs(_q.mult - _want_mult) > 0.0001) _all_mult = false;
        if (_q.dmg < _exp || _q.dmg < 1) _all_dmg = false;   // base x grade multiplier at least (gear bonuses only add)
        if (_q.sfx != Qte_GradeSfxKey(_q.key)) _all_snd = false;
        if (_q.word != Qte_GradeLabel(_q.key)) _all_word = false;
        if (_q.hitstop != (_q.key == "PERFECT")) _all_hs = false;   // hit-stop on Perfect only
        if (_s.v == 0 && abs(_q.press_ms - _centre) > _q.params.perfect_half_width) _all_press = false;
        if (_s.v == 1 && _q.press_ms != QTE_NO_PRESS) _all_press = false;   // the fail variant never presses
    }
    Scenario_Check(_name + "_qte_swings_ge_1", _n >= 1, "swings=" + string(_n));
    Scenario_Check(_name + "_qte_every_grade_" + _want_key, _all_key, _detail);
    Scenario_Check(_name + "_qte_grade_matches_pure_function", _all_fn);
    Scenario_Check(_name + "_qte_multiplier_" + string(_want_mult), _all_mult);
    Scenario_Check(_name + "_qte_damage_at_least_base_x_multiplier_and_never_0", _all_dmg);
    Scenario_Check(_name + "_qte_grade_sound_fired", _all_snd);
    Scenario_Check(_name + "_qte_grade_word_shown", _all_word);
    Scenario_Check(_name + "_qte_hitstop_on_perfect_only", _all_hs);
    Scenario_Check(_name + (_s.v == 0 ? "_qte_press_inside_perfect_zone" : "_qte_never_pressed"), _all_press);
    if (_s.v == 0) {
        Scenario_Check("bot_perfect_player_won", _pl.hp > 0, "hp=" + string(_pl.hp));
        // _bc.e is the enemy before the killing blow; the blow's damage must account for all of its hp.
        Scenario_Check("bot_perfect_enemy_hp_zero", _bc.e.hp - _bc.last_dmg <= 0, "enemy_hp_before=" + string(_bc.e.hp) + " last_dmg=" + string(_bc.last_dmg));
        Scenario_Check("bot_perfect_exp_gained", _pl.exp > _s.exp0 || _pl.level > 1, "exp=" + string(_pl.exp));
    } else {
        // D20: a player who never presses still deals 75% damage every swing, so the fight is won, not lost (the old fail variant lost because every swing missed).
        Scenario_Check("bot_fail_weak_hits_still_win", _bc.e.hp - _bc.last_dmg <= 0 && _pl.hp > 0, "enemy_hp_before=" + string(_bc.e.hp) + " last_dmg=" + string(_bc.last_dmg) + " hp=" + string(_pl.hp));
    }
}

// ---- -shots: screen_save of rm_start / rm_floor1 / rm_battle at display scales 3, 4, 5, then the screen after a cutscene end,
// a dialogue end and a room transition at several window sizes (I-051, DISP-04/06/07/08), then one picture per skill animation ----
// Borderless and exclusive fullscreen are not captured: they need a real fullscreen switch, which is not safe in an unattended run (D91: tests are always windowed).

// The window sizes of the display flow. [w, h]
function Scenario_DispSize(_i) {
    var _sizes = [[480, 432], [1000, 700], [1920, 1080]];
    return _sizes[clamp(_i, 0, array_length(_sizes) - 1)];
}

function Scenario_DispSizeCount() {
    return 3;
}

// Put the window at a size and let the display owner lay it out (windowed, any size: DISP-11).
function Scenario_SetWindow(_w, _h) {
    GameSettings_Ensure().window_mode = WINDOW_MODE_WINDOWED;
    Display_Request({ mode: WINDOW_MODE_WINDOWED, window_w: _w, window_h: _h });
}

function Scenario_SetWindowScale(_scale) {
    var _sz = Display_WindowSizeForScale(_scale);
    Scenario_SetWindow(_sz.w, _sz.h);
}

// One picture plus the layout the game predicts for the window it is in. The wrapper (Test-Shots) reads the extra keys:
//   gx gy gw gh = Display_CalcLayout's picture rectangle, app = application_get_position() (screen_save writes the whole window,
//   or only that rectangle when the Windows Scaling option is "keep aspect"), applies = display re-layout count (DISP-08),
//   edge=1 the four edges of the rectangle must carry picture (not for fades or cutscene art), fade=1 a fade was on screen,
//   art=1 the picture must not be all black (H2: the last cutscene image fades out, it does not vanish first).
function Scenario_ShotLayout(_file, _flags = "", _crop = undefined) {
    var _w = window_get_width(), _h = window_get_height();
    var _l = Display_CalcLayout(_w, _h);
    if (is_struct(_crop)) {   // a room smaller than the view (DISP-10): the predicted picture is only the part inside the room, so anything outside it is garbage
        _l.game_x += _crop.dx * _l.scale;
        _l.game_y += _crop.dy * _l.scale;
        _l.game_w = _crop.sw * _l.scale;
        _l.game_h = _crop.sh * _l.scale;
    }
    var _ap = application_get_position();
    var _fade = Transition_IsActive() && GameState_Get().transition_fx.alpha > 0.001;
    screen_save(_file);
    show_debug_message("[SHOT] file=" + _file + " w=" + string(_w) + " h=" + string(_h) + " scale=" + string(_l.scale)
        + " gx=" + string(_l.game_x) + " gy=" + string(_l.game_y) + " gw=" + string(_l.game_w) + " gh=" + string(_l.game_h)
        + " app=" + string(_ap[0]) + "," + string(_ap[1]) + "," + string(_ap[2]) + "," + string(_ap[3])
        + " applies=" + string(Display_ApplyCount()) + (_fade ? " fade=1" : "") + ((_flags != "") ? " " + _flags : ""));
}

function Scenario_StepShots(_s) {
    var _rooms = [rm_start, rm_floor1, rm_battle];
    var _scales = [3, 4, 5];
    switch (_s.step) {
        case 0:   // enter room _s.ri and settle
            if (_s.ri >= array_length(_rooms)) {
                _s.fxi = 0;
                _s.di = 0;
                Scenario_Next(_s, 20);   // I-051: the screen after a cutscene end, a dialogue end and a room change
                break;
            }
            if (_s.t == 1) {
                if (_s.ri == 1) { Scenario_NewKnight(); room_goto(rm_floor1); }
                if (_s.ri == 2) Scenario_EnterBattle("shots_slime");
                if (_s.ri == 0) { with (obj_start_controller) { if (state == "boot_logo") state = "main"; } }   // skip the logo; the menu is the shot
            }
            if (_s.t >= 40) {
                Scenario_Check("shots_in_" + room_get_name(_rooms[_s.ri]), room == _rooms[_s.ri]);
                _s.si = 0;
                Scenario_Next(_s, 1);
            }
            break;
        case 1:   // apply the display scale and wait for the window and camera to settle
            if (_s.t == 1) Scenario_SetWindowScale(_scales[_s.si]);
            if (_s.t >= 30) Scenario_Next(_s, 2);
            break;
        case 2:
            var _w = window_get_width(), _h = window_get_height();
            _s.shot = "shot_" + room_get_name(room) + "_" + string(_w) + "x" + string(_h) + ".png";
            Scenario_ShotLayout(_s.shot, (room == rm_floor1) ? "edge=1" : "");
            Scenario_Next(_s, 3);
            break;
        case 3:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                _s.si++;
                if (_s.si >= array_length(_scales)) { _s.ri++; Scenario_Next(_s, 0); } else Scenario_Next(_s, 1);
            }
            break;
        case 10:
        case 11:
        case 12:
            Scenario_StepShotsFx(_s);
            break;
        case 50: case 51: case 52: case 53: case 54: case 55: case 56: case 57: case 58:
            Scenario_StepShotsWindow(_s);
            break;
        case 60: case 61: case 62: case 63: case 64: case 65: case 66: case 67: case 68:
            Scenario_StepShotsWorld(_s);
            break;
        case 80: case 81: case 82: case 83: case 84: case 85: case 86: case 87: case 88: case 89:
            Scenario_StepShotsUi(_s);
            break;
        case 90: case 91: case 92: case 93: case 94: case 95: case 96: case 97:
            Scenario_StepShotsTurns(_s);
            break;
        case 140: case 141: case 142: case 143: case 144: case 145: case 146: case 147: case 148: case 149:
            Scenario_StepShotsAI(_s);
            break;
        default:
            Scenario_StepShotsDisp(_s);
            break;
    }
}

// I-051 / DISP-04, 06, 07, 08. Per window size, one continuous run through the real input path:
// new game -> intro cutscene (every line confirmed) -> exit fade -> rm_floor1 -> its intro dialogue (confirmed) -> plain room fade.
// Pictures: before the cutscene's last line ends, in the middle of the exit fade (the art must still show), +1/+10/+40 frames after the
// cutscene's last Transition_Finish, before the dialogue ends, +1/+10/+40 frames after it, +1/+10 after the room fade.
// Counter: the display must not be re-laid-out by any of it.
function Scenario_StepShotsDisp(_s) {
    var _gs = GameState_Get();
    var _sz = Scenario_DispSize(_s.di);
    var _tag = string(_sz[0]) + "x" + string(_sz[1]);
    var _tapnow = ((_s.f - _s.last_tap) >= 8);
    switch (_s.step) {
        case 20:   // window size, settle, then a fresh game into the intro cutscene
            if (_s.t == 1) {
                Scenario_SetWindow(_sz[0], _sz[1]);
                Scenario_NewKnight();
                _s.cut_shot = false;
                _s.fade_shot = false;
                _s.dlg_seen = false;
                _s.dlg_t = 0;
            }
            if (_s.t == 45) {
                Scenario_Check("shots_disp_window_" + _tag, window_get_width() == _sz[0] && window_get_height() == _sz[1], "window=" + string(window_get_width()) + "x" + string(window_get_height()));
                _s.ap0 = Display_ApplyCount();
                Transition_RequestCutsceneById("intro");
                Scenario_Next(_s, 21);
            }
            break;
        case 21:   // in the cutscene: confirm every line
            if (_s.t > 3000) {
                Scenario_Check("shots_disp_cutscene_ends_" + _tag, false, "still in " + room_get_name(room) + " after 3000 frames");
                Scenario_Finish();
                break;
            }
            if (room == rm_cutscene && instance_exists(obj_start_controller) && obj_start_controller.cutscene_started) {
                var _sc = obj_start_controller;
                var _last = (_sc.cutscene_segment_index == array_length(_sc.cutscene_sequence) - 1);
                var _in_dlg = (_gs.ui.mode == UI_DIALOGUE && array_length(_gs.ui.lines) > 0);
                if (_last && _in_dlg && !_s.cut_shot && _gs.ui.index >= array_length(_gs.ui.lines) - 1 && !Transition_IsActive()) {
                    _s.dlg_t++;
                    if (_s.dlg_t >= 20) {   // the last line has been on screen for 20 frames
                        Scenario_ShotLayout("shot_disp_cut_before_" + _tag + ".png");
                        _s.cut_shot = true;
                        _s.dlg_t = 0;
                    }
                } else if (_tapnow) {
                    Scenario_Tap("confirm");
                }
                if (_s.cut_shot && _tapnow) Scenario_Tap("confirm");
            }
            if (Transition_IsActive() && _gs.transition_fx.type == TRANSITION_TYPE_CUTSCENE && _gs.transition_fx.target_room == rm_floor1) {
                Scenario_Check("shots_disp_last_line_pictured_" + _tag, _s.cut_shot);
                Scenario_Next(_s, 22);
            }
            break;
        case 22:   // the exit fade: the last cutscene picture must still be there while it darkens (H2)
            if (_s.t > 600) {
                Scenario_Check("shots_disp_floor1_reached_" + _tag, false, "room=" + room_get_name(room));
                Scenario_Finish();
                break;
            }
            if (!_s.fade_shot && Transition_IsActive() && _gs.transition_fx.phase == 0 && _gs.transition_fx.timer >= 8 && room == rm_cutscene) {
                Scenario_ShotLayout("shot_disp_cut_fade_" + _tag + ".png", "art=1");
                _s.fade_shot = true;
            }
            if (room == rm_floor1 && !Transition_IsActive()) {
                Scenario_Check("shots_disp_cut_fade_pictured_" + _tag, _s.fade_shot);
                _s.fin_f = _s.f;
                Scenario_Next(_s, 23);
            }
            break;
        case 23: {   // +1 / +10 / +40 frames after the cutscene exit's Transition_Finish
            var _d = _s.f - _s.fin_f;
            if (_d == 1 || _d == 10 || _d == 40) Scenario_ShotLayout("shot_disp_cut_end_p" + string(_d) + "_" + _tag + ".png", "edge=1");
            if (_d >= 40) {
                Scenario_Check("shots_disp_in_floor1_" + _tag, room == rm_floor1);
                Scenario_Next(_s, 24);
            }
        } break;
        case 24:   // rm_floor1's intro dialogue: let it be on screen, then confirm through it
            if (_s.t > 1500) {
                Scenario_Check("shots_disp_dialogue_ends_" + _tag, false, "mode=" + string(_gs.ui.mode));
                Scenario_Finish();
                break;
            }
            if (_gs.ui.mode == UI_DIALOGUE || array_length(_gs.ui.lines) > 0) {
                _s.dlg_seen = true;
                _s.dlg_t++;
                if (_s.dlg_t == 30) Scenario_ShotLayout("shot_disp_dlg_before_" + _tag + ".png");
                if (_s.dlg_t > 30 && _tapnow) Scenario_Tap("confirm");
            } else if (_s.dlg_seen) {
                _s.fin_f = _s.f;
                Scenario_Next(_s, 25);
            } else if (_s.t > 300) {
                Scenario_Check("shots_disp_dialogue_seen_" + _tag, false, "no dialogue opened in rm_floor1");
                Scenario_Finish();
            }
            break;
        case 25: {   // +1 / +10 / +40 frames after the dialogue closed
            var _d2 = _s.f - _s.fin_f;
            if (_d2 == 1 || _d2 == 10 || _d2 == 40) Scenario_ShotLayout("shot_disp_dlg_end_p" + string(_d2) + "_" + _tag + ".png", "edge=1");
            if (_d2 >= 40) Scenario_Next(_s, 26);
        } break;
        case 26:   // a plain room fade
            if (_s.t == 1) Transition_RequestRoomFade(rm_floor2);
            if (_s.t > 600) {
                Scenario_Check("shots_disp_room_fade_" + _tag, false, "room=" + room_get_name(room));
                Scenario_Finish();
                break;
            }
            if (_s.t > 5 && room == rm_floor2 && !Transition_IsActive()) {
                _s.fin_f = _s.f;
                Scenario_Next(_s, 27);
            }
            break;
        case 27: {   // +1 / +10 after the room fade, then the counter
            var _d3 = _s.f - _s.fin_f;
            if (_d3 == 1 || _d3 == 10) Scenario_ShotLayout("shot_disp_room_end_p" + string(_d3) + "_" + _tag + ".png", "edge=1");
            if (_d3 >= 10) {
                Scenario_Check("shots_disp_no_relayout_" + _tag, Display_ApplyCount() == _s.ap0, "re-laid-out " + string(Display_ApplyCount() - _s.ap0) + " times during cutscene end, dialogue end and room fade");
                _s.di++;
                if (_s.di >= Scenario_DispSizeCount()) Scenario_Next(_s, 28); else Scenario_Next(_s, 20);
            }
        } break;
        case 28:   // the encounter zoom (a draw-time zoom of the picture, nothing resized) at the last window size, then the battle room
            if (_s.t == 1) {
                _s.fade_shot = false;
                GameState_SetBattleReturn(room, 0, 0, 0);
                GameState_SetBattleEnemy("disp_zoom_slime", ENEMY_SLIME, 1);
                Transition_RequestEncounterBattle(rm_battle, 80, 72);
            }
            if (_s.t > 600) {
                Scenario_Check("shots_disp_encounter_ends", false, "room=" + room_get_name(room));
                Scenario_Finish();
                break;
            }
            if (!_s.fade_shot && Transition_IsActive() && _gs.transition_fx.type == TRANSITION_TYPE_ENCOUNTER && _gs.transition_fx.phase == 1 && _gs.transition_fx.timer >= 3) {
                Scenario_Check("shots_disp_encounter_zoom_active", global.display.zoom > 1.2, "zoom=" + string(global.display.zoom));
                Scenario_ShotLayout("shot_disp_encounter_zoom.png", "edge=1");
                _s.fade_shot = true;
            }
            if (room == rm_battle && !Transition_IsActive()) {
                Scenario_Check("shots_disp_encounter_zoom_cleared", global.display.zoom == 1, "zoom=" + string(global.display.zoom));
                Scenario_Check("shots_disp_encounter_zoom_pictured", _s.fade_shot);
                _s.fin_f = _s.f;
                Scenario_Next(_s, 29);
            }
            break;
        case 29:
            if (_s.f - _s.fin_f == 10) {
                Scenario_ShotLayout("shot_disp_encounter_battle.png", "edge=1");
                Scenario_Check("shots_disp_encounter_no_relayout", Display_ApplyCount() == _s.ap0, "re-laid-out " + string(Display_ApplyCount() - _s.ap0) + " times");
                Scenario_Next(_s, 30);
            }
            break;
        case 30:   // QTE part 1: the sliding bar mid-sweep, at display scale 3 (480 x 432)
        case 31:
        case 32:
        case 33:
        case 34:
        case 35:
        case 36:
        case 37:
        case 38:
        case 39:
        case 40:
        case 41:
        case 42:
            Scenario_StepShotsQte(_s);
            break;
    }
}

// QTE part 1 (D56): the bar with the cursor on its way to the zone (shot_qte_bar.png), then the Perfect word over the enemy (shot_qte_perfect.png).
function Scenario_StepShotsQte(_s) {
    switch (_s.step) {
        case 30:
            if (_s.t == 1) {
                Scenario_NewKnight();
                Scenario_SetWindowScale(3);
                Scenario_GotoBattle("shots_qte_bar");
            }
            if (_s.t >= 25) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_qte_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); return; }
                var _bc = instance_find(obj_battle_controller, 0);
                Battle_AttackTimingBegin(_bc);
                _bc.qte_ms = 520;   // 47% of the Wooden Sword's 1100 ms sweep: the cursor is approaching the zone at 70%
                Scenario_Next(_s, 31);
            }
            break;
        case 31:
            if (_s.t >= 2) {
                var _bc = instance_find(obj_battle_controller, 0);
                Scenario_Check("shots_qte_bar_mid_sweep", _bc.battle_state == BSTATE_ATTACK_TIMING && _bc.qte_active && _bc.qte_ms > 520 && _bc.qte_ms < _bc.qte_params.sweep_ms, "state=" + string(_bc.battle_state) + " ms=" + string(_bc.qte_ms));
                _s.shot = "shot_qte_bar.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 32);
            }
            break;
        case 32:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                var _bc = instance_find(obj_battle_controller, 0);
                Battle_PlayerAttackResolveTimed(_bc, Qte_Result(QTE_PERFECT));
                Scenario_Next(_s, 33);
            }
            break;
        case 33:
            if (_s.t >= 12) {   // the freeze (60 ms) is over and the word is in its pop
                _s.shot = "shot_qte_perfect.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 34);
            }
            break;
        case 34:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                Scenario_Next(_s, 35);
            }
            break;
        case 35:   // QTE part 2: a Mage's Fireball sequence (4 arrows) after one right and one wrong press, at display scale 3
            if (_s.t == 1) {
                var _gs = Scenario_NewKnight(CLASS_MAGE);
                Scenario_SetWindowScale(3);
                Scenario_GotoBattle("shots_qte_arrows");
            }
            if (_s.t >= 25) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_qte_arrows_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); return; }
                var _bc = instance_find(obj_battle_controller, 0);
                Battle_SkillQteBegin(_bc, SKILL_FIREBALL);
                Scenario_Check("shots_qte_arrows_started", _bc.battle_state == BSTATE_SKILL_QTE && _bc.sq_active);
                var _st = _bc.sq_st;
                _bc.sq_ms = 1000;
                Qte_SeqPress(_st, _st.seq[0], 600);    // right: the first arrow is done
                Qte_SeqPress(_st, DOWN, 900);          // wrong: the second wanted is RIGHT, so it shakes and the bar loses 250 ms
                Qte_SeqTick(_st, 1000);
                _bc.sq_pop_ms = 0;
                _bc.sq_wrong_ms = 0;
                Scenario_Next(_s, 36);
            }
            break;
        case 36:
            if (_s.t >= 3) {
                var _bc = instance_find(obj_battle_controller, 0);
                Scenario_Check("shots_qte_arrows_mid_entry", _bc.battle_state == BSTATE_SKILL_QTE && _bc.sq_st.idx == 1 && _bc.sq_st.mistakes == 1 && !_bc.sq_st.done, "idx=" + string(_bc.sq_st.idx));
                _s.shot = "shot_qte_arrows.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 37);
            }
            break;
        case 37:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                Scenario_Next(_s, 38);
            }
            break;
        case 38:   // the telegraph of the mini boss's Ramming, then its defence bar, at display scale 3
            if (_s.t == 1) {
                Scenario_NewKnight();
                Scenario_SetWindowScale(3);
                Scenario_GotoBattle("shots_qte_defence", ENEMY_MINI_BOSS);
            }
            if (_s.t >= 25) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_qte_defence_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); return; }
                var _bc = instance_find(obj_battle_controller, 0);
                var _sk = SkillDB_Get(SKILL_RAMMING);
                _bc.skill_banner_active = true;
                _bc.skill_banner_name = _sk.name;
                Battle_DefenceStart(_bc, _sk, { ok: true, hit: true, dmg: 8, crit: false, msg: "" }, BSTATE_MENU, _bc.p.hp, Battle_StatusSnapshot(_bc.p));
                _bc.wait_timer = 9999;
                _bc.def_ms = -QTE_LEAD_IN_MS - 300;   // 100 ms into the telegraph
                Scenario_Next(_s, 39);
            }
            break;
        case 39:
            if (_s.t >= 2) {
                var _bc = instance_find(obj_battle_controller, 0);
                Scenario_Check("shots_qte_telegraph_up", _bc.battle_state == BSTATE_ENEMY_DEFENCE && _bc.def_active && _bc.def_ms < -QTE_LEAD_IN_MS, "ms=" + string(_bc.def_ms));
                _s.shot = "shot_qte_telegraph.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 40);
            }
            break;
        case 40:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                var _bc = instance_find(obj_battle_controller, 0);
                _bc.def_ms = 880;   // 59% of Ramming's 1500 ms sweep: the cursor is on its way to the zone at 70%
                Scenario_Next(_s, 41);
            }
            break;
        case 41:
            if (_s.t >= 2) {
                var _bc = instance_find(obj_battle_controller, 0);
                Scenario_Check("shots_qte_defence_bar_mid_sweep", _bc.battle_state == BSTATE_ENEMY_DEFENCE && _bc.def_active && _bc.def_ms > 880 && _bc.def_ms < _bc.def_params.sweep_ms, "ms=" + string(_bc.def_ms));
                _s.shot = "shot_qte_defence.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 42);
            }
            break;
        case 42:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                _s.si = 0;
                Scenario_Next(_s, 90);   // B3 pictures (turn strip, stagger, BREAK, Foresight), then on to the D91 / DISP-10 / D48 ones
            }
            break;
    }
}

// B3 pictures at display scale 3 (open them: the strip, the meter, the numbers, BREAK!, Foresight on the strip).
function Scenario_StepShotsTurns(_s) {
    switch (_s.step) {
        case 90:   // a Knight against a Spider: strip across the top, stagger half full, Perfect / Good numbers over the enemy and a hurt number on the player
            if (_s.t == 1) {
                Scenario_NewKnight();
                Scenario_SetWindowScale(3);
                Scenario_GotoBattle("shots_turns_strip", ENEMY_SPIDER);
            }
            if (_s.t >= 25) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_turns_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); return; }
                var _bc = instance_find(obj_battle_controller, 0);
                _bc.wait_timer = 9999;   // stay on the intro message while the picture is taken
                _bc.e.hp = 7;
                _bc.enemy_hp_shown = 7;
                _bc.e.stagger = 5;
                _bc.pops = [];
                Battle_HitPop(_bc, 12, QTE_PERFECT, false);
                Battle_HitPop(_bc, 5, QTE_GOOD, false);
                Battle_PlayerHitPop(_bc, 3, false);
                Scenario_Check("shots_turns_strip_has_5_slots", array_length(Battle_TimelineSlots(_bc)) == TURN_PREVIEW_COUNT);
                Scenario_Next(_s, 91);
            }
            break;
        case 91:
            if (_s.t >= 10) {
                _s.shot = "shot_turns_strip.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 92);
            }
            break;
        case 92:   // the BREAK moment: the pop, the pulsing full meter and the strip faded after the push-back
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                var _bc = instance_find(obj_battle_controller, 0);
                _bc.pops = [];
                var _note = Battle_StaggerHit(_bc, 20, false, true);
                Scenario_Check("shots_turns_break_triggered", _bc.e.broken && string_pos("BREAK", _note) > 0, _note);
                Battle_HitPop(_bc, 18, QTE_PERFECT, true);
                Scenario_Next(_s, 93);
            }
            break;
        case 93:
            if (_s.t >= 9) {
                _s.shot = "shot_turns_break.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 94);
            }
            break;
        case 94:   // a Mage with Foresight against a Spider that only uses Poison Fangs: the eye and the action name on the enemy's slot
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                Scenario_NewKnight(CLASS_MAGE);
                Debug_Init();
                global.debug.enabled = true;
                global.debug.enemy_damage_skill_only = true;
                Scenario_GotoBattle("shots_turns_foresight", ENEMY_SPIDER);
                Scenario_Next(_s, 95);
            }
            break;
        case 95:
            if (_s.t >= 25) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_turns_foresight_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); return; }
                var _bc = instance_find(obj_battle_controller, 0);
                _bc.wait_timer = 9999;
                _bc.p = Status_Add(_bc.p, STATUS_HIT_UP, 3, 0);
                var _slots = Battle_TimelineSlots(_bc);
                var _fs = Scenario_BotForesightSlot(_bc);
                Scenario_Check("shots_turns_foresight_on_the_enemy_slot", is_struct(_fs) && _fs.slot.who == TL_ENEMY && _fs.slot.foresight.skill_id == SKILL_POISON_FANGS, is_struct(_fs) ? string(_fs.idx) : "none");
                global.debug.enabled = false;
                global.debug.enemy_damage_skill_only = false;
                Scenario_Next(_s, 96);
            }
            break;
        case 96:
            if (_s.t >= 8) {
                _s.shot = "shot_turns_foresight.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 97);
            }
            break;
        case 97:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                _s.si = 0;
                Scenario_Next(_s, 140);   // B4 pictures (140..148), then D91 / DISP-10 / D48 pictures and the skill animations
            }
            break;
    }
}

// B4 pictures (steps 140..148): Palehorn has just lowered its horns (banner, log line and the "!" on the strip), Foresight shows the wind-up two actions ahead,
// and a phase banner. All three are set up on a real battle controller; the pictures are of the real draw code.
function Scenario_StepShotsAI(_s) {
    switch (_s.step) {
        case 140:   // the wind-up has just happened: the player's turn, the banner over the enemy, the "!" on the enemy's slot
            if (_s.t == 1) {
                Scenario_NewKnight();
                Scenario_SetWindowScale(3);
                Scenario_GotoBattle("shots_ai_windup", ENEMY_MINI_BOSS);
            }
            if (_s.t >= 25) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_ai_windup_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); return; }
                var _bc = instance_find(obj_battle_controller, 0);
                _bc.ai.turns = 2;
                EnemyAI_Take(_bc.ai, EnemyAI_Choose(_bc.e, _bc.p, EnemyAI_Ctx(_bc.ai), Run_Stream("combat")));   // its 3rd turn: Ramming is telegraphed
                EnemyAI_EndTurn(_bc.ai);
                Scenario_Check("shots_ai_windup_is_ramming", _bc.ai.windup == SKILL_RAMMING, "windup=" + string(_bc.ai.windup));
                var _text = Skill_WindupText(SkillDB_Get(SKILL_RAMMING), _bc.e.name);
                _bc.tl_who = TL_PLAYER;
                _bc.turn = TURN_PLAYER;
                _bc.enemy_action_pending = false;
                _bc.message_text = _text;
                _bc.message_next_state = BSTATE_MENU;
                _bc.battle_state = BSTATE_MESSAGE;
                _bc.wait_timer = 9999;
                _bc.skill_banner_active = true;
                _bc.skill_banner_name = _text;
                _bc.combat_log = [];   // the log (top right) is checked by the bot; two wrapped rows of it would sit on the enemy name in this picture
                Scenario_Check("shots_ai_windup_text_names_the_enemy", string_pos("Palehorn", _text) > 0 && string_pos("horns", _text) > 0, _text);
                Scenario_Check("shots_ai_windup_mark_on_the_strip", is_struct(Scenario_BotWindupSlot(_bc)));
                Scenario_Next(_s, 141);
            }
            break;
        case 141:
            if (_s.t >= 10) {
                _s.shot = "shot_ai_windup.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 142);
            }
            break;
        case 142:   // Foresight: a Mage sees the wind-up before it happens
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                Scenario_NewKnight(CLASS_MAGE);
                Scenario_GotoBattle("shots_ai_foresight", ENEMY_MINI_BOSS);
                Scenario_Next(_s, 143);
            }
            break;
        case 143:
            if (_s.t >= 25) {
                var _inb2 = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_ai_foresight_in_battle", _inb2, "room=" + room_get_name(room));
                if (!_inb2) { Scenario_Finish(); return; }
                var _bc2 = instance_find(obj_battle_controller, 0);
                _bc2.wait_timer = 9999;
                _bc2.ai.turns = 2;   // its next turn is the 3rd
                _bc2.p = Status_Add(_bc2.p, STATUS_HIT_UP, 3, 0);
                var _fs = Scenario_BotForesightSlot(_bc2);
                Scenario_Check("shots_ai_foresight_shows_the_windup", is_struct(_fs) && _fs.slot.foresight.kind == "windup" && _fs.slot.foresight.skill_id == SKILL_RAMMING && _fs.slot.foresight.big, is_struct(_fs) ? _fs.slot.foresight.kind : "none");
                Scenario_Next(_s, 144);
            }
            break;
        case 144:
            if (_s.t >= 8) {
                _s.shot = "shot_ai_foresight.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 145);
            }
            break;
        case 145:   // a phase banner: Palehorn at 40% HP
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                Scenario_NewKnight();
                Scenario_GotoBattle("shots_ai_phase", ENEMY_MINI_BOSS);
                Scenario_Next(_s, 146);
            }
            break;
        case 146:
            if (_s.t >= 25) {
                var _inb3 = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_ai_phase_in_battle", _inb3, "room=" + room_get_name(room));
                if (!_inb3) { Scenario_Finish(); return; }
                var _bc3 = instance_find(obj_battle_controller, 0);
                _bc3.e.hp = floor(_bc3.e.max_hp * 0.4);
                _bc3.enemy_hp_shown = _bc3.e.hp;
                _bc3.e.stagger = 12;
                Battle_PhaseSync(_bc3);
                Scenario_Check("shots_ai_phase_reached_1", _bc3.ai.phase == 1 && _bc3.phase_banner != "", "phase=" + string(_bc3.ai.phase));
                var _banner = _bc3.phase_banner;
                _bc3.phase_banner = "";
                _bc3.skill_banner_active = true;
                _bc3.skill_banner_name = _banner;
                Battle_Message(_bc3, _banner, BSTATE_ENEMY_ACT);
                _bc3.combat_log = [];
                _bc3.wait_timer = 9999;
                Scenario_Next(_s, 147);
            }
            break;
        case 147:
            if (_s.t >= 10) {
                _s.shot = "shot_ai_phase.png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Next(_s, 148);
            }
            break;
        case 148:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                _s.si = 0;
                Scenario_Next(_s, 50);   // D91 / DISP-10 / D48 pictures, then the skill animations
            }
            break;
    }
}

// DISP-10: rm_floor6_5 (144 wide, the view is 160) at two windowed sizes: the room is centred and nothing outside it shows (the wrapper counts
// non-black pixels outside the predicted room rectangle). D91: the Settings popup with the Window row. D48: the hold-to-skip hint mid-hold.
function Scenario_StepShotsWindow(_s) {
    var _gs = GameState_Get();
    var _scales = [3, 5];
    switch (_s.step) {
        case 50:   // rm_floor6_5 at scale _scales[_s.si]
            if (_s.t == 1) {
                Scenario_NewKnight();
                Scenario_SetWindowScale(_scales[_s.si]);
                room_goto(rm_floor6_5);
            }
            if (_s.t >= 45) {
                Scenario_Check("shots_in_rm_floor6_5", room == rm_floor6_5, "room=" + room_get_name(room));
                var _cam = view_camera[0];
                var _crop = Display_RoomCrop(room_width, room_height, camera_get_view_x(_cam), camera_get_view_y(_cam), DISPLAY_BASE_W, DISPLAY_BASE_H);
                Scenario_Check("shots_floor6_5_narrow_room_is_cropped_and_centred", _crop.active && _crop.sw == 144 && _crop.dx == 8, "sw=" + string(_crop.sw) + " dx=" + string(_crop.dx) + " cam_x=" + string(camera_get_view_x(_cam)));
                _s.shot = "shot_rm_floor6_5_" + string(window_get_width()) + "x" + string(window_get_height()) + ".png";
                Scenario_ShotLayout(_s.shot, "edge=1", _crop);
                Scenario_Next(_s, 51);
            }
            break;
        case 51:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                _s.si++;
                if (_s.si >= array_length(_scales)) { _s.si = 0; Scenario_Next(_s, 52); } else Scenario_Next(_s, 50);
            }
            break;
        case 52:   // the Settings popup from the title menu, Window row selected, Borderless shown
            if (_s.t == 1) {
                Scenario_SetWindowScale(3);
                room_goto(rm_start);
            }
            if (_s.t == 45) {
                if (!instance_exists(obj_start_controller)) { Scenario_Check("shots_settings_in_rm_start", false, "no start controller"); Scenario_Finish(); break; }
                with (obj_start_controller) { state = "settings"; }
                SettingsPopup_Open("title");
                var _sp = GameState_Get().ui.settings_popup;
                _sp.pending.window_mode = WINDOW_MODE_BORDERLESS;
                SettingsPopup_Refresh();
                Ui_MenuFixCursor(_sp.menu, 6);   // the Window row
            }
            if (_s.t == 90) {
                _s.shot = "shot_settings_window_" + string(window_get_width()) + "x" + string(window_get_height()) + ".png";
                Scenario_ShotLayout(_s.shot, "edge=1");
                Scenario_Next(_s, 53);
            }
            break;
        case 53:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                SettingsPopup_Close(true);
                Scenario_Next(_s, 80);
            }
            break;
        case 54:   // the intro cutscene, confirm held for about half the skip time
            if (_s.t == 1) {
                Scenario_NewKnight();
                Transition_RequestCutsceneById("intro");
            }
            if (_s.t > 40 && room == rm_cutscene && instance_exists(obj_start_controller) && obj_start_controller.cutscene_started && !Transition_IsActive() && _gs.ui.mode == UI_DIALOGUE) {
                Scenario_Hold("confirm", 200);
                _s.skp_f0 = _s.f;
                Scenario_Next(_s, 55);
            }
            if (_s.t > 600) { Scenario_Check("shots_skip_hint_cutscene_running", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 55:
            if (_s.f - _s.skp_f0 == SKIP_HOLD_FRAMES div 2) {
                Scenario_Check("shots_skip_hint_is_filling", global.skip.st.hint > 0 && global.skip.st.held_frames >= 20 && global.skip.st.held_frames < SKIP_HOLD_FRAMES, "held=" + string(global.skip.st.held_frames));
                _s.shot = "shot_skip_hint_" + string(window_get_width()) + "x" + string(window_get_height()) + ".png";
                Scenario_ShotLayout(_s.shot);
                Scenario_Release();
                Scenario_Next(_s, 56);
            }
            break;
        case 56:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                Skip_Reset();
                Dialogue_CloseNow();
                Cutscene_ClearUiState();
                room_goto(rm_floor1);
                Scenario_Next(_s, 10);
            }
            break;
    }
}

// D0: the shared UI framework on screen at window scale 3 (480 x 432, the GUI grid is the same size): the title menu, the difficulty
// panel, the settings screen with its details panel (volume row, then the text speed row with its number line), Korean, and the
// component kit (tabs header, speaker tab, details panel). Everything is reached through real input. Files shot_ui_<name>_<w>x<h>.png.
function Scenario_ShotUi(_s, _name) {
    _s.shot = "shot_ui_" + _name + "_" + string(window_get_width()) + "x" + string(window_get_height()) + ".png";
    Scenario_ShotLayout(_s.shot);
}

function Scenario_StepShotsUi(_s) {
    var _c = instance_exists(obj_start_controller) ? instance_find(obj_start_controller, 0) : noone;
    var _sp = GameState_Get().ui.settings_popup;
    switch (_s.step) {
        case 80:   // the title menu
            if (_s.t == 1) { Scenario_SetWindowScale(3); room_goto(rm_start); }
            if (_s.t == 90) {
                Scenario_Check("shots_ui_title_state", _c != noone && _c.state == "main", "state=" + ((_c != noone) ? string(_c.state) : "no controller"));
                Scenario_ShotUi(_s, "title");
                Scenario_Next(_s, 81);
            }
            break;
        case 81:   // New Game -> the difficulty panel
            if (_s.t == 3) { Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot)); Scenario_Tap("confirm"); }
            if (_s.t == 40) {
                Scenario_Check("shots_ui_difficulty_state", _c.state == "difficulty", "state=" + string(_c.state));
                Scenario_ShotUi(_s, "difficulty");
                Scenario_Next(_s, 82);
            }
            break;
        case 82:   // Back -> down to Settings -> confirm
            if (_s.t == 3) { Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot)); Scenario_Tap("cancel"); }
            if (_s.t == 10) { RunSave_Delete(); _c.title_refresh = true; }   // C1: an earlier shot started a run; with no run save Continue is greyed and Down lands on Settings
            if (_s.t == 30) Scenario_Tap("menu_down");
            if (_s.t == 36) Scenario_Tap("confirm");
            if (_s.t == 60) Ui_MenuFixCursor(_sp.menu, 0);   // an earlier shot left the remembered cursor on the Window row
            if (_s.t == 80) {
                Scenario_Check("shots_ui_settings_state", _c.state == "settings" && SettingsPopup_IsOpen("title"), "state=" + string(_c.state));
                Scenario_ShotUi(_s, "settings");
                Scenario_Next(_s, 83);
            }
            break;
        case 83:   // text speed row: the details panel with its number line
            if (_s.t == 3) Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
            if (_s.t == 4 || _s.t == 10 || _s.t == 16) Scenario_Tap("menu_down");
            if (_s.t == 60) {
                Scenario_Check("shots_ui_settings_on_text_speed", _sp.menu.items[_sp.menu.cursor].id == "text_speed", "row=" + string(_sp.menu.items[_sp.menu.cursor].id));
                Scenario_ShotUi(_s, "settings_details");
                Scenario_Next(_s, 84);
            }
            break;
        case 84:   // language row, right: Korean
            if (_s.t == 3) Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
            if (_s.t == 4 || _s.t == 10 || _s.t == 16 || _s.t == 22 || _s.t == 28) Scenario_Tap("menu_down");
            if (_s.t == 34) Scenario_Tap("menu_right");
            if (_s.t == 90) {
                Scenario_Check("shots_ui_settings_is_korean", Loc_GetLanguage() == "ko" && _sp.menu.items[_sp.menu.cursor].id == "language", "lang=" + Loc_GetLanguage());
                Scenario_ShotUi(_s, "settings_ko");
                Scenario_Next(_s, 85);
            }
            break;
        case 85:   // Back restores English and leaves the settings
            if (_s.t == 3) Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
            if (_s.t == 4) Scenario_Tap("cancel");
            if (_s.t == 50) {
                Scenario_Check("shots_ui_back_restores_english", Loc_GetLanguage() == "en" && _c.state == "main", "lang=" + Loc_GetLanguage() + " state=" + string(_c.state));
                global.scn.uikit = true;
                Scenario_Next(_s, 86);
            }
            break;
        case 86:   // the component kit
            if (_s.t == 15) {
                Scenario_ShotUi(_s, "kit");
                Scenario_Next(_s, 87);
            }
            break;
        case 87:
            if (_s.t == 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                global.scn.uikit = false;
                Scenario_Next(_s, 88);
            }
            break;
        case 88:   // the Tab menu's Stats tab in rm_floor1 (B1 saw the ATK label overlap the HP numbers)
            if (_s.t == 1) { Scenario_NewKnight(); room_goto(rm_floor1); }
            if (_s.t == 90) {
                Menu_Open();
                GameState_Get().ui.menu.tab = 2;
            }
            if (_s.t == 130) {
                Scenario_ShotUi(_s, "stats_tab");
                Scenario_Next(_s, 89);
            }
            break;
        case 89:
            if (_s.t == 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                Menu_Close(true);
                Scenario_Next(_s, 54);   // on to the intro cutscene / skip hint shots
            }
            break;
    }
}

// The kit gallery for the kit shot (drawn over the title by obj_start_controller's Draw GUI while global.scn.uikit is set).
function Scenario_DrawUiKit() {
    if (!variable_global_exists("scn") || !is_struct(global.scn) || !variable_struct_exists(global.scn, "uikit") || !global.scn.uikit) return;
    var _mt = Ui_Metrics();
    var _p = _mt.p;
    Ui_Box(0, 0, _mt.gw, _mt.gh, UI_C_DARKEST);
    var _x = _mt.margin;
    var _w = _mt.gw - 2 * _mt.margin;
    var _y = _mt.margin;
    _y += Ui_DrawTabs(_x, _y, _w, ["Items", "Skills", "Status"], 1) + 2 * _p;
    var _sent = "Hits one enemy for fire damage and may burn it.";
    var _lines = [{ label: "Damage", value: "12" }, { label: "MP cost", value: "4" }];
    var _dh = Ui_DetailsHeight(_w, _sent, _lines);
    Ui_DrawDetails(_x, _y, _w, _dh, _sent, _lines);
    _y += _dh + 10 * _p;
    var _bh = 3 * _mt.row_h + 8 * _p;
    Ui_DrawFrame(_x, _y, _w, _bh, 1, _p);
    Ui_DrawNameTab(_x, _y, "Mira");
    Ui_Text(_x + 4 * _p, _y + 4 * _p, "The tab and the box share one border.", UI_C_LIGHTEST);
    Ui_Text(_x + 4 * _p, _y + 4 * _p + _mt.row_h, "Light, lighter, dark, darkest: four colours.", UI_C_LIGHT);
    Ui_Arrow(_x + _w - 8 * _p, _y + _bh - 8 * _p, 1, _p, UI_C_LIGHTEST);
}

// I-052: one screenshot per player skill animation, in rm_battle at display scale 3 (480 x 432), file shot_fx_<skill>.png.
// Each skill is spawned through Battle_SkillFxSpawn (the same placement, scale and speed the battle uses) and frozen on its middle frame.
function Scenario_StepShotsFx(_s) {
    var _ids = Skill_PlayerFxIds();
    if (_s.fxi >= array_length(_ids)) {
        Scenario_Next(_s, 60);   // A1: the world-space marks (sight ring, "!", interact arrow)
        return;
    }
    var _sid = _ids[_s.fxi];
    var _skill = SkillDB_Get(_sid);
    var _slug = string_lower(string_replace_all(_skill.name, " ", "_"));
    switch (_s.step) {
        case 10:   // a character of the skill's class, into a battle at display scale 3
            if (_s.t == 1) {
                var _gs = Scenario_NewKnight(_skill.class_list[0]);
                Scenario_SetWindowScale(3);
                Scenario_GotoBattle("shots_fx_" + _slug);
            }
            if (_s.t >= 25) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_fx_" + _slug + "_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); return; }
                var _bc = instance_find(obj_battle_controller, 0);
                _bc.wait_timer = 9999;   // stay on the intro message while the picture is taken
                _bc.skill_banner_active = true;
                _bc.skill_banner_name = _skill.name;
                var _fx = Battle_SkillFxSpawn(_bc, _sid, _skill.fx_sprite, _skill.fx_frames, Skill_FxSpeed(_skill, true));
                _bc.wait_fx = noone;
                _fx.image_index = (sprite_get_number(_skill.fx_sprite) * 3) div 4;   // late in the animation, where most effects are at their biggest (Ice Spear: 43 px wide at frame 9 of 12, 22 px at frame 6)
                _fx.image_speed = 0;
                _fx.fx_prev_frame = floor(_fx.image_index);
                Scenario_Next(_s, 11);
            }
            break;
        case 11:   // let the frozen frame be drawn, then save it
            if (_s.t >= 3) {
                _s.shot = "shot_fx_" + _slug + ".png";
                Scenario_ShotLayout(_s.shot, "fx_scale=" + string(instance_exists(obj_fx) ? obj_fx.image_xscale : -1));
                Scenario_Next(_s, 12);
            }
            break;
        case 12:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                with (obj_fx) instance_destroy();
                _s.fxi++;
                Scenario_Next(_s, 10);
            }
            break;
    }
}


// ============================================================================
// v=3 movement and enemy AI (I-047, I-048, D63, D66, D67, D69, D70). Runs in rm_floor1 with the real objects; the stage is built by
// creating a dire wolf (or ghost), rocks (block movement, not sight), walls (block both) and extra enemies. Cells are 16 px.
// Open stage: rows 9 and 10 (and row 8 from column 14) between columns 14 and 20 are free; the slime stands at (15,9), the player at (19,9).
// Each part checks the OUTCOME (position, state), so it also runs, and fails, against the old greedy AI.
// ============================================================================
function Scenario_PlaceEnemy(_e, _cx, _cy) {
    _e.x = _cx * GRID_TILE_SIZE;
    _e.y = _cy * GRID_TILE_SIZE;
    _e.home_x = _e.x;
    _e.home_y = _e.y;
    _e.moving = false;
    _e.move_timer = 0;
    _e.move_dir = -1;
    _e.cine_lock_count = 0;   // the cinematic trigger in rm_floor1 freezes the slime until it fires
    _e.ai_state = ENEMY_IDLE;
    _e.forget_time = 0;
    if (variable_instance_exists(_e, "ai_mode")) {
        _e.ai_mode = "idle";
        _e.home_cx = _cx;
        _e.home_cy = _cy;
        _e.react_timer = 0;
        _e.spot_cooldown = 0;
        _e.stuck_frames = 0;
        _e.stuck_max = 0;
    }
}

function Scenario_PlacePlayer(_cx, _cy) {
    var _pl = instance_find(obj_player, 0);
    _pl.x = _cx * GRID_TILE_SIZE;
    _pl.y = _cy * GRID_TILE_SIZE;
    _pl.moving = false;
    _pl.move_timer = 0;
    return _pl;
}

// The abandoned battles before this suite leave a post-battle dialogue queued; it would pop up in the next room and freeze the
// player and every enemy. Drop it (and any open dialogue) before a movement part starts.
function Scenario_ClearUi() {
    var _gs = GameState_Get();
    _gs.pending_post_battle_dialogue_lines = [];
    if (_gs.ui.mode != UI_NONE || array_length(_gs.ui.lines) > 0) UI_InterruptCloseAll(false);
}

function Scenario_Block(_obj, _cx, _cy) {
    return instance_create_layer(_cx * GRID_TILE_SIZE, _cy * GRID_TILE_SIZE, "Instances", _obj);
}

function Scenario_StepMove(_s) {
    if (_s.mp >= 6) {
        Scenario_StepMovePlayer(_s);
        return;
    }
    var _mv = _s.mv;
    switch (_s.step) {
        case 0:   // fresh room for the next part (first let any battle fade that an encounter already started finish)
            if (_s.t < 30 || Transition_IsActive()) break;
            Scenario_ClearUi();
            _s.mv = { sl: noone, other: noone, reached: false, spotted: false, run: 0, run_max: 0, mind: 9999, frames: 0, phase: 0, t0: 0 };
            Scenario_NewKnight();
            room_goto(rm_floor2);   // via another room: the controller only spawns the player on a room change
            Scenario_Next(_s, 1);
            break;
        case 1:
            if (_s.t < 20) break;
            room_goto(rm_floor1);
            Scenario_Next(_s, 2);
            break;
        case 2:   // build the stage
            if (_s.t < 45) break;
            if (!instance_exists(obj_player)) {
                Scenario_Check("move_stage_" + string(_s.mp), false, "room=" + room_get_name(room));
                Scenario_MoveNext(_s);
                break;
            }
            with (obj_enemy) instance_destroy();   // the room's own slime is not part of the stage
            _mv.sl = instance_create_layer(15 * GRID_TILE_SIZE, 9 * GRID_TILE_SIZE, "Instances", (_s.mp == 4) ? obj_ghost_sword : obj_dire_wolf);
            Scenario_PlaceEnemy(_mv.sl, 15, 9);
            Scenario_PlacePlayer(19, 9);
            switch (_s.mp) {
                case 0:   // A: a rock on the straight line, sight is clear
                    Scenario_Block(obj_rock1, 17, 9);
                    Scenario_Block(obj_rock1, 17, 8);
                    break;
                case 1:   // B: a wall across the whole corridor, sight is blocked
                    Scenario_Block(obj_wall, 17, 8);
                    Scenario_Block(obj_wall, 17, 9);
                    Scenario_Block(obj_wall, 17, 10);
                    break;
                case 2:   // C: rocks across the whole corridor: seen but unreachable
                    Scenario_Block(obj_rock1, 17, 8);
                    Scenario_Block(obj_rock1, 17, 9);
                    Scenario_Block(obj_rock1, 17, 10);
                    break;
                case 3:   // D: a one-tile gap at (17,9) in a rock line, a wolf on each side of the approach: both want the same cells
                    Scenario_Block(obj_rock1, 17, 8);
                    Scenario_Block(obj_rock1, 17, 10);
                    Scenario_PlaceEnemy(_mv.sl, 16, 8);
                    _mv.other = instance_create_layer(16 * GRID_TILE_SIZE, 10 * GRID_TILE_SIZE, "Instances", obj_dire_wolf);
                    Scenario_PlaceEnemy(_mv.other, 16, 10);
                    break;
                case 4:   // E: a ghost behind a wall: sees through it and flies over it
                    Scenario_Block(obj_wall, 17, 8);
                    Scenario_Block(obj_wall, 17, 9);
                    Scenario_Block(obj_wall, 17, 10);
                    break;
                case 5:   // F: lose sight, search the last seen spot, walk home
                    break;
            }
            Scenario_Next(_s, 3);
            break;
        case 3:   // run the part and judge it
            Scenario_StepMovePart(_s, _mv);
            break;
    }
}

function Scenario_StepMovePart(_s, _mv) {
    var _sl = _mv.sl;
    var _pl = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
    _mv.frames++;
    if (!instance_exists(_sl) || _pl == noone) {
        Scenario_Check("move_part_" + string(_s.mp) + "_alive", false, "room=" + room_get_name(room));
        Scenario_MoveNext(_s);
        return;
    }
    var _near = point_distance(_sl.x, _sl.y, _pl.x, _pl.y) <= 20;
    if (_sl.ai_state == ENEMY_ALERT) _mv.spotted = true;
    if (_sl.ai_state == ENEMY_ALERT && !_sl.moving) _mv.run++; else _mv.run = 0;
    _mv.run_max = max(_mv.run_max, _mv.run);
    switch (_s.mp) {
        case 0:   // A: reaches the player around the rock
            if (_near || _mv.frames >= 520) {
                Scenario_Check("move_A_spots_player", _mv.spotted);
                Scenario_Check("move_A_reaches_player_around_rock_in_520_frames", _near, "frames=" + string(_mv.frames) + " at " + string(_sl.x) + "," + string(_sl.y));
                Scenario_Check("move_A_never_stuck_over_60_frames", _mv.run_max <= 60, "max_run=" + string(_mv.run_max));
                Scenario_Check("move_fx_layer_script_draws_the_alert", variable_global_exists("nav_fx_calls") && global.nav_fx_calls > 20, "calls=" + string(variable_global_exists("nav_fx_calls") ? global.nav_fx_calls : -1));
                Scenario_MoveNext(_s);
            }
            break;
        case 1:   // B: a wall hides the player: the enemy stays calm
            if (_mv.spotted || _mv.frames >= 150) {
                Scenario_Check("move_B_wall_blocks_sight_150_frames", !_mv.spotted, "frames=" + string(_mv.frames));
                Scenario_MoveNext(_s);
            }
            break;
        case 2:   // C: sealed with rocks: sees but cannot pass; it must not cross and must stay on the grid
            if (_sl.x > 17 * GRID_TILE_SIZE - 8) _mv.reached = true;
            if (_mv.frames >= 360) {
                Scenario_Check("move_C_sealed_rocks_not_crossed", !_mv.reached, "x=" + string(_sl.x));
                Scenario_Check("move_C_sealed_enemy_on_grid", Scenario_Aligned(_sl) || _sl.moving, "x=" + string(_sl.x) + " y=" + string(_sl.y));
                Scenario_MoveNext(_s);
            }
            break;
        case 3:   // D: two enemies, one goal: never on the same tile
            if (instance_exists(_mv.other)) _mv.mind = min(_mv.mind, point_distance(_sl.x, _sl.y, _mv.other.x, _mv.other.y));
            var _near2 = instance_exists(_mv.other) && point_distance(_mv.other.x, _mv.other.y, _pl.x, _pl.y) <= 20;
            if ((_near || _near2) && _mv.t0 == 0) _mv.t0 = _mv.frames;   // keep watching a little after the first one arrives
            if ((_mv.t0 > 0 && _mv.frames - _mv.t0 >= 40) || _mv.frames >= 520) {
                Scenario_Check("move_D_one_of_two_reaches_player", _mv.t0 > 0, "frames=" + string(_mv.frames));
                Scenario_Check("move_D_enemies_never_share_a_tile", _mv.mind >= GRID_TILE_SIZE - 0.5, "min_distance=" + string(_mv.mind));
                Scenario_MoveNext(_s);
            }
            break;
        case 4:   // E: the ghost passes the wall
            if (_near || _mv.frames >= 420) {
                Scenario_Check("move_E_ghost_passes_wall_to_player_in_420_frames", _near, "frames=" + string(_mv.frames) + " at " + string(_sl.x) + "," + string(_sl.y));
                Scenario_MoveNext(_s);
            }
            break;
        case 5:   // F: out of sight -> last seen spot -> home
            if (_mv.phase == 0) {
                if (_mv.spotted && _mv.frames >= 30) {
                    _pl.x = 3 * GRID_TILE_SIZE;   // gone, far out of sight
                    _pl.y = 6 * GRID_TILE_SIZE;
                    _mv.phase = 1;
                    _mv.mind = 9999;
                    _mv.t0 = _mv.frames;
                } else if (_mv.frames >= 120) {
                    Scenario_Check("move_F_spots_player", false);
                    Scenario_MoveNext(_s);
                }
            } else {
                _mv.mind = min(_mv.mind, point_distance(_sl.x, _sl.y, 19 * GRID_TILE_SIZE, 9 * GRID_TILE_SIZE));
                var _home = (_sl.x == 15 * GRID_TILE_SIZE && _sl.y == 9 * GRID_TILE_SIZE && !_sl.moving && _sl.ai_state == ENEMY_IDLE && _mv.frames - _mv.t0 > 60);
                if (_home || _mv.frames - _mv.t0 >= 900) {
                    Scenario_Check("move_F_visits_last_seen_spot", _mv.mind <= GRID_TILE_SIZE, "closest=" + string(_mv.mind));
                    Scenario_Check("move_F_returns_home_in_900_frames", _home, "at " + string(_sl.x) + "," + string(_sl.y) + " state=" + string(_sl.ai_state));
                    Scenario_MoveNext(_s);
                }
            }
            break;
    }
}

function Scenario_MoveNext(_s) {
    with (obj_enemy) instance_destroy();   // no late encounter may leak into the next part
    _s.mp++;
    Scenario_Next(_s, 0);
    if (_s.mp >= 6) _s.mv = { phase: 0 };   // the player parts keep their own phases
}


// ---- parts 6+: the player (I-049 exit guard, D64 arrival, D69 / D70 movement) through held keys ----
function Scenario_ExitCount() {
    return variable_global_exists("room_exit_count") ? global.room_exit_count : 0;
}

function Scenario_StepMovePlayer(_s) {
    switch (_s.mp) {
        case 6: Scenario_StepMoveExit(_s); break;
        case 7: Scenario_StepMovePlayerFeel(_s); break;
        default: _s.v = 1; Scenario_Next(_s, 0); break;   // done: on to the fail variant
    }
}

// G: rm_floor2 left exit -> rm_floor1 arrival ON the exit tile (D64).
// Exit fires once per entry (I-049); arriving on the exit tile does not fire it until the player steps off and comes back.
function Scenario_StepMoveExit(_s) {
    var _mv = _s.mv;
    var _pl = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
    switch (_mv.phase) {
        case 0:
            if (_s.t < 30 || Transition_IsActive()) break;
            Scenario_ClearUi();
            _s.mv = { phase: 1, f0: _s.f, c0: 0, c1: 0, frames: 0 };
            Scenario_NewKnight();
            room_goto(rm_floor2);
            break;
        case 1:   // walk left onto the exit tile of rm_floor2
            if (_s.f - _mv.f0 < 50 || _pl == noone) break;
            with (obj_enemy) instance_destroy();
            with (obj_dialogue_trigger) instance_destroy();   // rm_floor2 has a cinematic trigger on the cells next to this exit
            Scenario_PlacePlayer(2, 5);
            _mv.c0 = Scenario_ExitCount();
            Scenario_Hold("move_left", 60);
            _mv.phase = 2;
            _mv.f0 = _s.f;
            break;
        case 2:   // wait for the arrival in rm_floor1
            if (room == rm_floor1 && _pl != noone && !Transition_IsActive() && _s.f - _mv.f0 > 20) {
                _mv.c1 = Scenario_ExitCount();
                Scenario_Check("exit_G1_fires_once_per_entry", _mv.c1 - _mv.c0 == 1, "exit snapshots=" + string(_mv.c1 - _mv.c0));
                Scenario_Check("exit_G2_arrives_on_the_exit_tile", _pl.x == 18 * GRID_TILE_SIZE && _pl.y == 3 * GRID_TILE_SIZE, "at " + string(_pl.x) + "," + string(_pl.y));
                with (obj_enemy) instance_destroy();
                Scenario_Hold("move_right", 45);   // pressing toward the exit while standing on it
                _mv.phase = 3;
                _mv.f0 = _s.f;
            } else if (_s.f - _mv.f0 > 400) {
                Scenario_Check("exit_G1_arrival_in_rm_floor1", false, "room=" + room_get_name(room));
                Scenario_MoveNext6(_s);
            }
            break;
        case 3:   // still in rm_floor1: the exit ignores the player standing on it
            if (_s.f - _mv.f0 >= 50) {
                Scenario_Check("exit_G3_standing_on_the_exit_does_not_fire", room == rm_floor1 && Scenario_ExitCount() == _mv.c1 && !Transition_IsActive(), "room=" + room_get_name(room) + " fires=" + string(Scenario_ExitCount() - _mv.c1));
                Scenario_Hold("move_left", 15);   // step off: the player reads last frame's input, so 15 held frames = exactly one 16 px tile
                _mv.phase = 4;
                _mv.f0 = _s.f;
            }
            break;
        case 4:
            if (_s.f - _mv.f0 >= 24) {
                Scenario_Check("exit_G4_stepped_off_the_exit_tile", _pl != noone && _pl.x == 17 * GRID_TILE_SIZE && _pl.y == 3 * GRID_TILE_SIZE, "at " + ((_pl != noone) ? (string(_pl.x) + "," + string(_pl.y)) : "no player"));
                Scenario_Hold("move_right", 30);   // and back on
                _mv.phase = 5;
                _mv.f0 = _s.f;
            }
            break;
        case 5:
            if (room == rm_floor2 || _s.f - _mv.f0 > 300) {
                Scenario_Check("exit_G5_fires_again_after_stepping_off", room == rm_floor2 && Scenario_ExitCount() - _mv.c1 == 1, "room=" + room_get_name(room) + " fires=" + string(Scenario_ExitCount() - _mv.c1));
                Scenario_MoveNext6(_s);
            }
            break;
    }
}

function Scenario_MoveNext6(_s) {
    with (obj_enemy) instance_destroy();
    _s.mp++;
    _s.mv = { phase: 0 };
    Scenario_Next(_s, 0);
}

// H: the player's own feel (D69, D70) in an open row of rm_floor1 (row 9, columns 8..20 are free). Held keys through the real input path.
// Reminder of the pipeline: the player reads last frame's input state, so Scenario_Hold(a, n) acts on the player for n + 1 frames.
function Scenario_StepMovePlayerFeel(_s) {
    var _mv = _s.mv;
    var _pl = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
    _mv.n = variable_struct_exists(_mv, "n") ? _mv.n + 1 : 0;   // frames since this phase began
    switch (_mv.phase) {
        case 0:
            if (_s.t < 30 || Transition_IsActive()) break;
            Scenario_ClearUi();
            _s.mv = { phase: 1, n: 0 };
            Scenario_NewKnight();
            room_goto(rm_floor2);
            break;
        case 1:
            if (_mv.n == 20) { room_goto(rm_floor1); _mv.phase = 2; _mv.n = 0; }
            break;
        case 2:   // stage: no enemies, the player at (16,9) facing down, a chest and a rock placed later
            if (_mv.n < 45) break;
            if (_pl == noone) { Scenario_Check("feel_stage", false, "room=" + room_get_name(room)); Scenario_MoveNext6(_s); break; }
            with (obj_enemy) instance_destroy();
            with (obj_dialogue_trigger) instance_destroy();
            Scenario_PlacePlayer(16, 9);
            _pl.face = DOWN;
            _mv.x0 = _pl.x;
            _mv.y0 = _pl.y;
            _mv.phase = 3;
            _mv.n = 0;
            break;
        case 3:   // H1: a short tap turns the player on the spot and does not move it
            if (_mv.n == 2) Scenario_Hold("move_right", 3);
            if (_mv.n == 20) {
                Scenario_Check("feel_H1_tap_turns_to_face_right", _pl.face == RIGHT, "face=" + string(_pl.face));
                Scenario_Check("feel_H1_tap_does_not_move", _pl.x == _mv.x0 && _pl.y == _mv.y0 && !_pl.moving, "at " + string(_pl.x) + "," + string(_pl.y));
                _mv.phase = 4;
                _mv.n = 0;
            }
            break;
        case 4:   // H2: a held direction walks tile to tile and rests on the grid between steps; releasing mid-step finishes the tile
            if (_mv.n == 2) { Scenario_Hold("move_right", 40); _mv.x1 = _pl.x; _mv.bad = 0; }
            if (_mv.n > 2 && !_pl.moving && !Grid_IsAligned(_pl.x)) _mv.bad++;
            if (_mv.n == 70) {
                Scenario_Check("feel_H2_held_direction_walks_three_tiles", _pl.x == _mv.x1 + 48 && !_pl.moving, "dx=" + string(_pl.x - _mv.x1));
                Scenario_Check("feel_H2_never_rests_between_tiles", _mv.bad == 0, "frames=" + string(_mv.bad));
                _mv.phase = 5;
                _mv.n = 0;
            }
            break;
        case 5:   // H3: pressing up near the end of a step (right is let go) turns the corner at once
            if (_mv.n == 2) {
                Scenario_PlacePlayer(13, 9);   // the step to column 14 is free and so is the cell above it; above columns 9..13 is a wall
                _pl.face = RIGHT;
                _mv.x1 = 13 * GRID_TILE_SIZE;
                _mv.y1 = 9 * GRID_TILE_SIZE;
                _mv.up_at = -1;
            }
            if (_mv.n == 6) Scenario_Hold("move_right", 6);   // starts the step to column 10
            if (_mv.n == 15) Scenario_Hold("move_up", 3);     // tapped while the step is still running
            if (_mv.n > 6 && _mv.up_at < 0 && _pl.y < _mv.y1) _mv.up_at = _mv.n;
            if (_mv.n == 50) {
                Scenario_Check("feel_H3_buffered_turn_goes_up_after_the_step", _pl.x == _mv.x1 + 16 && _pl.y == _mv.y1 - 16 && !_pl.moving, "at " + string(_pl.x) + "," + string(_pl.y));
                // the right step began on frame 7 and ends on frame 22; the buffered turn must not wait for a turn delay
                Scenario_Check("feel_H3_corner_has_no_idle_gap", _mv.up_at > 0 && _mv.up_at <= 26, "up started at frame " + string(_mv.up_at));
                _mv.phase = 6;
                _mv.n = 0;
            }
            break;
        case 6:   // H4: pressing into a rock plays the bump once per press, not once per frame
            if (_mv.n == 2) {
                Scenario_PlacePlayer(12, 9);
                _pl.face = RIGHT;
                Scenario_Block(obj_rock1, 13, 9);
                _mv.b0 = variable_instance_exists(_pl, "bump_count") ? _pl.bump_count : -1;
            }
            if (_mv.n == 10) Scenario_Hold("move_right", 40);
            if (_mv.n == 70) {
                var _b1 = variable_instance_exists(_pl, "bump_count") ? _pl.bump_count : -1;
                Scenario_Check("feel_H4_one_bump_for_one_long_press", _b1 - _mv.b0 == 1, "bumps=" + string(_b1 - _mv.b0));
                Scenario_Check("feel_H4_bump_does_not_move_the_player", _pl.x == 12 * GRID_TILE_SIZE && !_pl.moving, "x=" + string(_pl.x));
                Scenario_Hold("move_right", 10);
            }
            if (_mv.n == 100) {
                var _b2 = variable_instance_exists(_pl, "bump_count") ? _pl.bump_count : -1;
                Scenario_Check("feel_H4_second_press_bumps_again", _b2 - _mv.b0 == 2, "bumps=" + string(_b2 - _mv.b0));
                _mv.phase = 7;
                _mv.n = 0;
            }
            break;
        case 7:   // H5: the run key covers the ground faster
            // I-063: and plays the same walk animation faster: per step it must get as far through the frames as a walking step does
            if (_mv.n == 2) { _mv.wmax = 0; _mv.wspd = 0; _mv.rmax = 0; _mv.rspd = 0; }
            if (_mv.n >= 3 && _mv.n <= 38 && _pl.moving) { _mv.wmax = max(_mv.wmax, _pl.image_index); _mv.wspd = max(_mv.wspd, _pl.image_speed); }
            if (_mv.n >= 46 && _mv.n <= 88 && _pl.moving) { _mv.rmax = max(_mv.rmax, _pl.image_index); _mv.rspd = max(_mv.rspd, _pl.image_speed); }
            if (_mv.n == 2) { Scenario_PlacePlayer(9, 9); _pl.face = RIGHT; _mv.x1 = _pl.x; Scenario_Hold("move_right", 23); }
            if (_mv.n == 40) {
                _mv.walk = _pl.x - _mv.x1;
                Scenario_PlacePlayer(9, 9);
                _pl.face = RIGHT;
                _mv.x1 = _pl.x;
            }
            if (_mv.n == 45) { Scenario_Hold("move_right", 23); Scenario_Hold("run", 23); }
            if (_mv.n == 90) {
                _mv.runx = _pl.x - _mv.x1;
                Scenario_Check("feel_H5_walk_is_one_pixel_a_frame", _mv.walk == 32, "walked=" + string(_mv.walk));
                Scenario_Check("feel_H5_run_covers_more_ground_in_the_same_frames", _mv.runx >= 48, "ran=" + string(_mv.runx) + " walked=" + string(_mv.walk));
                Scenario_Check("feel_H5_run_rests_on_the_grid", Grid_IsAligned(_pl.x) && !_pl.moving, "x=" + string(_pl.x));
                Scenario_Check("feel_I063_run_animation_speed_is_double_the_walk", abs(_mv.rspd - 2 * _mv.wspd) < 0.01 && _mv.wspd > 0, "walk=" + string(_mv.wspd) + " run=" + string(_mv.rspd));
                Scenario_Check("feel_I063_run_step_gets_as_far_through_the_frames_as_a_walk_step", _mv.wmax > 1.5 && _mv.rmax >= 0.9 * _mv.wmax, "walk_max_frame=" + string(_mv.wmax) + " run_max_frame=" + string(_mv.rmax));
                _mv.phase = 8;
                _mv.n = 0;
            }
            break;
        case 8:   // H6: facing a chest shows the interact prompt; facing away hides it
            if (_mv.n == 2) {
                Scenario_PlacePlayer(15, 10);
                _pl.face = RIGHT;
                _mv.chest = Scenario_Block(obj_chest_lv1, 16, 10);
            }
            if (_mv.n == 8) {
                var _t1 = variable_instance_exists(_pl, "prompt_target") ? _pl.prompt_target : noone;
                Scenario_Check("feel_H6_prompt_shows_when_facing_a_chest", instance_exists(_t1) && _t1.id == _mv.chest.id, "target=" + string(_t1));   // Interact_GetTarget hands back "self" (a struct), compare ids
                Scenario_Hold("move_left", 3);   // turn away
            }
            if (_mv.n == 20) {
                var _t2 = variable_instance_exists(_pl, "prompt_target") ? _pl.prompt_target : noone;
                Scenario_Check("feel_H6_prompt_hides_when_facing_away", !instance_exists(_t2), "target=" + string(_t2));
                Scenario_MoveNext6(_s);
            }
            break;
    }
}


// ---- -gridshots (D65): every floor room once, 16 px grid drawn over the world, one PNG each (shot_grid_<room>.png) ----
// Window at display scale 4. The grid is drawn by a layer script (world coordinates, so it sits exactly on the room's pixels):
//   green  (#86C06C, 50%) = lines at multiples of 16 from the ROOM origin (0,0)
//   violet (50%)          = lines at multiples of 16 from the CAMERA view's top-left corner (only when that corner is off the room grid)
//   red    (50%)          = the room's own edges (x=0, x=room_width, y=0, y=room_height)
// No room, object or sprite is changed. Floor rooms have no HUD; the intro dialogue / room fade is confirmed or waited out before the shot.
function Scenario_GridRooms() {
    return [rm_floor1, rm_floor2, rm_floor3, rm_floor4, rm_floor5, rm_floor6, rm_floor6_5, rm_floor7, rm_floor8, rm_floor9, rm_floor9_5];
}

function Scenario_GridOverlay() {
    if (!Fx_IsWorldPass()) return;
    var _cam = view_camera[0];
    var _vx = camera_get_view_x(_cam), _vy = camera_get_view_y(_cam), _vw = camera_get_view_width(_cam), _vh = camera_get_view_height(_cam);
    var _c0 = draw_get_colour(), _a0 = draw_get_alpha();
    draw_set_alpha(0.5);
    var _ox = ((_vx mod 16) + 16) mod 16, _oy = ((_vy mod 16) + 16) mod 16;
    if (_ox != 0 || _oy != 0) {   // camera grid, under the room grid
        draw_set_colour(make_colour_rgb(208, 108, 192));
        for (var _x = _vx; _x <= _vx + _vw; _x += 16) draw_rectangle(_x, _vy, _x, _vy + _vh, false);
        for (var _y = _vy; _y <= _vy + _vh; _y += 16) draw_rectangle(_vx, _y, _vx + _vw, _y, false);
    }
    draw_set_colour(make_colour_rgb($86, $C0, $6C));
    for (var _x2 = _vx - _ox; _x2 <= _vx + _vw; _x2 += 16) draw_rectangle(_x2, _vy, _x2, _vy + _vh, false);
    for (var _y2 = _vy - _oy; _y2 <= _vy + _vh; _y2 += 16) draw_rectangle(_vx, _y2, _vx + _vw, _y2, false);
    draw_set_colour(make_colour_rgb(224, 48, 48));
    draw_rectangle(0, 0, room_width - 1, room_height - 1, true);
    draw_set_colour(_c0);
    draw_set_alpha(_a0);
}

function Scenario_StepGridShots(_s) {
    var _rooms = Scenario_GridRooms();
    var _gs = GameState_Get();
    var _tapnow = ((_s.f - _s.last_tap) >= 8);
    switch (_s.step) {
        case 0:   // enter room _s.ri
            if (_s.ri >= array_length(_rooms)) { Scenario_Finish(); break; }
            if (_s.t == 1) {
                if (_s.ri == 0) Scenario_SetWindowScale(4);
                Scenario_NewKnight();
                room_goto(_rooms[_s.ri]);
            }
            if (_s.t >= 40) {
                Scenario_Check("gridshots_in_" + room_get_name(_rooms[_s.ri]), room == _rooms[_s.ri]);
                Scenario_Next(_s, 1);
            }
            break;
        case 1: {   // overlay layer, then clear the dialogue / fade
            if (_s.t == 1) {
                var _l = layer_create(-100000, "grid_overlay");
                var _el = layer_sprite_create(_l, 0, 0, archer_down);   // an invisible element: the layer is only drawn (and its script run) when it holds one
                layer_sprite_alpha(_el, 0);
                layer_script_end(_l, Scenario_GridOverlay);
                with (obj_enemy) instance_destroy();   // enemies near the spawn would start a battle before the shot (rm_floor5); the room asset is untouched
            }
            var _talk = (_gs.ui.mode == UI_DIALOGUE || array_length(_gs.ui.lines) > 0);
            if (_talk && _tapnow) Scenario_Tap("confirm");
            if (_s.t >= 30 && !_talk && !Transition_IsActive()) { _s.dlg_t = 0; Scenario_Next(_s, 2); }
            else if (_s.t > 900) {
                Scenario_Check("gridshots_clear_" + room_get_name(room), false, "dialogue or fade still up");
                Scenario_Next(_s, 2);
            }
        } break;
        case 2:   // let the last confirm settle, then the picture
            if (_s.t >= 10) {
                var _cam = view_camera[0];
                Scenario_Check("gridshots_still_in_" + room_get_name(_rooms[_s.ri]), room == _rooms[_s.ri], "room=" + room_get_name(room));
                _s.shot = "shot_grid_" + room_get_name(room) + ".png";
                Scenario_ShotLayout(_s.shot);
                show_debug_message("[GRID] room=" + room_get_name(room) + " size=" + string(room_width) + "x" + string(room_height)
                    + " cam=" + string(camera_get_view_x(_cam)) + "," + string(camera_get_view_y(_cam)) + "," + string(camera_get_view_width(_cam)) + "," + string(camera_get_view_height(_cam)));
                Scenario_Next(_s, 3);
            }
            break;
        case 3:
            if (_s.t >= 3) {
                Scenario_Check("gridshots_saved_" + _s.shot, file_exists(_s.shot));
                _s.ri++;
                Scenario_Next(_s, 0);
            }
            break;
    }
}

// ---- -exportdata (B1): the game's own data as JSON for the balance simulator (BAL-01, BAL-02). Pure data, no instances. ----
// A copy of a struct/array with every asset reference (any key containing "sprite") and method left out; keys sorted so the file diffs cleanly.
function Export_Clean(_v, _depth = 0) {
    if (_depth > 8) return undefined;
    if (is_struct(_v)) {
        var out = {};
        var keys = variable_struct_get_names(_v);
        array_sort(keys, true);
        for (var i = 0; i < array_length(keys); i++) {
            var k = keys[i];
            if (string_pos("sprite", k) > 0) continue;
            var val = variable_struct_get(_v, k);
            if (is_undefined(val) || is_method(val)) continue;
            variable_struct_set(out, k, Export_Clean(val, _depth + 1));
        }
        return out;
    }
    if (is_array(_v)) {
        var arr = [];
        for (var j = 0; j < array_length(_v); j++) array_push(arr, Export_Clean(_v[j], _depth + 1));
        return arr;
    }
    return _v;
}

// Records of an id-keyed ds_map as an array sorted by id; _get turns an id into the record (the game's own getter, so names are the runtime ones).
function Export_MapRecords(_map, _get) {
    var ids = ds_map_keys_to_array(_map);
    array_sort(ids, true);
    var out = [];
    for (var i = 0; i < array_length(ids); i++) array_push(out, Export_Clean(_get(ids[i])));
    return out;
}

function Export_Build() {
    GameState_Get();
    ItemDB_Init(); SkillDB_Init(); StatusDB_Init(); EnemyDB_Init(); Loot_Init();
    var data = { version: 1, build: BUILD_ID, spec: ".planning/research/combat-spec.md" };
    data.constants = {
        stat_ids: { atk: STAT_ATK, def: STAT_DEF, spd: STAT_SPD, mag: STAT_MAG },
        stat_min: STAT_MIN, stat_max: STAT_MAX, level_cap: LEVEL_CAP_TECHNICAL,
        power_scale: COMBAT_POWER_SCALE, weapon_skill_share: COMBAT_WEAPON_SKILL_SHARE, unarmed_power: COMBAT_UNARMED_POWER,
        crit_mult: COMBAT_CRIT_MULT, crit_chance_max: COMBAT_CRIT_CHANCE_MAX, free_points_per_level: LEVEL_FREE_POINTS_PER_LEVEL,
        player_base_hp: PLAYER_BASE_HP, player_base_mp: PLAYER_BASE_MP,
        grades: { perfect: Qte_GradeMult(QTE_PERFECT), good: Qte_GradeMult(QTE_GOOD), ok: Qte_GradeMult(QTE_OK), weak: Qte_GradeMult(QTE_WEAK) },
        assist_damage_taken_mult: Difficulty_Profile().assist_damage_taken_mult
    };
    // Level table: EXP to leave each level, and every class's stats/HP/MP by level as the game itself builds them (fixed growth + the auto-placed free point).
    data.levels = [];
    for (var lv = 1; lv <= LEVEL_CAP_TECHNICAL; lv++) array_push(data.levels, { level: lv, exp_next: Exp_NextLevel(lv) });
    data.classes = [];
    var class_ids = [CLASS_ARCHER, CLASS_KNIGHT, CLASS_MAGE, CLASS_NOBODY];   // ascending id
    for (var ci = 0; ci < array_length(class_ids); ci++) {
        var cfg = Export_Clean(DB_PlayerClass(class_ids[ci]));
        cfg.id = class_ids[ci];
        cfg.growth_per_level = [];
        cfg.by_level = [];
        var ch = CharacterCreate_Player(class_ids[ci]);
        for (var lv2 = 1; lv2 <= LEVEL_CAP_TECHNICAL; lv2++) {
            if (lv2 > 1) {
                array_push(cfg.growth_per_level, { level: lv2, gain: LevelUp_ClassGrowthGain(class_ids[ci], lv2) });
                ch = LevelUp_ApplyLevel(ch);
            }
            array_push(cfg.by_level, { level: lv2, atk: ch.stats.atk, def: ch.stats.def, spd: ch.stats.spd, mag: ch.stats.mag, hp: ch.max_hp, mp: ch.max_mp });
        }
        array_push(data.classes, cfg);
    }
    data.enemies = Export_MapRecords(global.enemy_db, EnemyDB_Get);
    data.skills = Export_MapRecords(global.skill_db, SkillDB_Get);
    for (var si = 0; si < array_length(data.skills); si++) {
        var seq = Qte_SkillSequence(data.skills[si].id);
        data.skills[si].sequence_length = is_array(seq) ? array_length(seq) : 0;
    }
    data.items = Export_MapRecords(global.item_db, ItemDB_Get);
    data.statuses = Export_MapRecords(global.status_db, StatusDB_Get);
    data.loot = { tables: {}, configs: {}, tier_weights: Export_Clean(global.loot_tier_weights) };
    var tk = ds_map_keys_to_array(global.loot_tables);
    for (var ti = 0; ti < array_length(tk); ti++) variable_struct_set(data.loot.tables, string(tk[ti]), Export_Clean(global.loot_tables[? tk[ti]]));
    var ck = ds_map_keys_to_array(global.loot_configs);
    for (var cj = 0; cj < array_length(ck); cj++) variable_struct_set(data.loot.configs, string(ck[cj]), Export_Clean(global.loot_configs[? ck[cj]]));
    return data;
}

// Writes export_data.json to the save area (the working directory, like test_results.txt). Returns the JSON text.
function Export_WriteFile(_data) {
    var text = json_stringify(_data, true);
    var f = file_text_open_write("export_data.json");
    if (f != -1) {
        file_text_write_string(f, text);
        file_text_close(f);
    }
    return text;
}

// True when every record in the array has a distinct numeric id.
function Export_IdsUnique(_records) {
    var seen = {};
    for (var i = 0; i < array_length(_records); i++) {
        var key = string(_records[i].id);
        if (variable_struct_exists(seen, key)) return false;
        variable_struct_set(seen, key, true);
    }
    return array_length(_records) > 0;
}

function Scenario_StepExportData(_s) {
    if (_s.t < 5) return;
    var text = Export_WriteFile(Export_Build());
    Scenario_Check("exportdata_file_exists", file_exists("export_data.json"));
    var back = Test_RawRead("export_data.json");
    Scenario_Check("exportdata_file_matches_the_text_written", (string_length(string_replace_all(back, "\r", "")) == string_length(text)) && (string_length(text) > 1000), "file=" + string(string_length(back)) + " text=" + string(string_length(text)) + " bytes=" + string(string_byte_length(text)));
    var parsed = undefined;
    try { parsed = json_parse(back); } catch (_e) { parsed = undefined; }
    Scenario_Check("exportdata_parses", is_struct(parsed));
    if (is_struct(parsed)) {
        Scenario_Check("exportdata_classes_4_unique", array_length(parsed.classes) == 4 && Export_IdsUnique(parsed.classes));
        Scenario_Check("exportdata_enemies_10_unique", array_length(parsed.enemies) == 10 && Export_IdsUnique(parsed.enemies));
        Scenario_Check("exportdata_skills_27_unique", array_length(parsed.skills) == 27 && Export_IdsUnique(parsed.skills));
        Scenario_Check("exportdata_items_37_unique", array_length(parsed.items) == 37 && Export_IdsUnique(parsed.items));
        Scenario_Check("exportdata_statuses_14_unique", array_length(parsed.statuses) == 14 && Export_IdsUnique(parsed.statuses));
        Scenario_Check("exportdata_level_table_10_rows", array_length(parsed.levels) == LEVEL_CAP_TECHNICAL && parsed.levels[0].exp_next == 12);
        Scenario_Check("exportdata_class_table_matches_the_game", parsed.classes[0].by_level[LEVEL_CAP_TECHNICAL - 1].hp > 0);
    }
    Scenario_Finish();
}

// ============================================================================
// A1 (I-056, I-058, I-059): the world-space marks (the sight ring, the "!" and the interact arrow) must land on the picture where
// the thing they belong to is, never at its top-left corner, and must come back after a battle. Two passes in rm_floor1 with a
// slime and a chest near the player:  pass 0 = first visit at display scale 3,  pass 1 = back from a battle at scale 4.
// Each pass saves picture A (marks on) and picture B (slime hidden and "defeated", player turned away from the chest: no marks).
// Test-Shots (run_tests.ps1) diffs A and B: every differing pixel must lie on a place the game says the marks belong (the slime,
// the ring annulus, the "!", the arrow, the player), the 24x24 corner of the picture must not differ at all, the ring probes (dots
// computed from Display_WorldToGui) must differ, and the arrow outline probes must be the outline colour #071821.
// ============================================================================
function Scenario_WorldWin(_wx, _wy) {   // a world point as a window pixel (what screen_save writes), via Display_WorldToGui
    var _l = Display_CalcLayout(window_get_width(), window_get_height());
    var _cam = view_camera[0];
    var _g = Display_WorldToGui(_l, _wx, _wy, camera_get_view_x(_cam), camera_get_view_y(_cam));
    return { x: _l.game_x + _g.x * _l.ui_scale, y: _l.game_y + _g.y * _l.ui_scale, s: _l.scale };
}

function Scenario_WorldInView(_wx, _wy, _m = 2) {
    var _cam = view_camera[0];
    var _vx = camera_get_view_x(_cam), _vy = camera_get_view_y(_cam);
    return (_wx >= _vx + _m && _wx < _vx + DISPLAY_BASE_W - _m && _wy >= _vy + _m && _wy < _vy + DISPLAY_BASE_H - _m);
}

// The extra [SHOT] keys for picture A. Window pixels throughout. A probe is the middle of one world pixel.
function Scenario_WorldFlags(_w, _fileB) {
    var _sl = _w.sl, _ch = _w.chest, _pl = instance_find(obj_player, 0);
    var _t = GRID_TILE_SIZE;
    var _cx = _sl.x + _t / 2, _cy = _sl.y + _t / 2;
    var _r = _sl.prof.sight * _t;
    var _n = max(12, round(2 * pi * _r / 6));
    var _cn = Scenario_WorldWin(_cx, _cy);
    var _sc = _cn.s;
    var _rp = "";
    for (var _k = 0; _k < _n; _k += max(1, _n div 24)) {   // about 24 dots round the ring, those on the picture
        var _ang = (_k / _n) * 2 * pi;
        var _dx = floor(_cx + cos(_ang) * _r), _dy = floor(_cy + sin(_ang) * _r);
        if (!Scenario_WorldInView(_dx, _dy, 3)) continue;
        var _p = Scenario_WorldWin(_dx + 0.5, _dy + 0.5);
        _rp += ((_rp == "") ? "" : ";") + string(round(_p.x)) + "," + string(round(_p.y));
    }
    // "!" (alert_pop is held on): same numbers as Nav_DrawWorldFx
    var _bx = floor(_cx), _by = floor(_sl.y) - 11;
    var _b0 = Scenario_WorldWin(_bx - 3, _by - 1);
    var _bp1 = Scenario_WorldWin(_bx - 2 + 0.5, _by + 3.5), _bp2 = Scenario_WorldWin(_bx + 2 + 0.5, _by + 3.5);   // the dark outline either side of the bar
    var _boxes = string(round(_b0.x)) + "," + string(round(_b0.y)) + "," + string(7 * _sc) + "," + string(13 * _sc);
    // the slime itself
    var _s0 = Scenario_WorldWin(_sl.bbox_left - 3, _sl.bbox_top - 3);
    _boxes += ";" + string(round(_s0.x)) + "," + string(round(_s0.y)) + "," + string((_sl.bbox_right - _sl.bbox_left + 7) * _sc) + "," + string((_sl.bbox_bottom - _sl.bbox_top + 7) * _sc);
    // the player (B turns it round)
    var _p0 = Scenario_WorldWin(_pl.bbox_left - 3, _pl.bbox_top - 3);
    _boxes += ";" + string(round(_p0.x)) + "," + string(round(_p0.y)) + "," + string((_pl.bbox_right - _pl.bbox_left + 7) * _sc) + "," + string((_pl.bbox_bottom - _pl.bbox_top + 7) * _sc);
    // the arrow over the chest: both bob heights
    var _ax = floor((_ch.bbox_left + _ch.bbox_right) / 2), _at = floor(_ch.bbox_top);
    var _a0 = Scenario_WorldWin(_ax - 4, _at - 13);
    _boxes += ";" + string(round(_a0.x)) + "," + string(round(_a0.y)) + "," + string(9 * _sc) + "," + string(10 * _sc);
    // arrow outline probes, one group of 7 per bob height (the arrow bobs with the wall clock; the picture shows one of the two): see Player_DrawWorldFx
    var _ap = "";
    var _offs = [[-2, -1], [2, -1], [-3, 0], [3, 0], [-2, 1], [2, 1], [0, 3]];
    for (var _bb = 0; _bb < 2; _bb++) {
        var _y0 = _at - 7 - _bb;
        for (var _o = 0; _o < array_length(_offs); _o++) {
            var _q = Scenario_WorldWin(_ax + _offs[_o][0] + 0.5, _y0 + _offs[_o][1] + 0.5);
            _ap += ((_ap == "") ? "" : ";") + string(round(_q.x)) + "," + string(round(_q.y));
        }
    }
    var _cc = Scenario_WorldWin(camera_get_view_x(view_camera[0]), camera_get_view_y(view_camera[0]));
    return "pair=" + _fileB + " corner=24 cornerxy=" + string(round(_cc.x)) + "," + string(round(_cc.y))
        + " ringc=" + string(round(_cn.x)) + "," + string(round(_cn.y)) + "," + string(_r * _sc) + "," + string(2.5 * _sc)
        + " rp=" + _rp + " bp=" + string(round(_bp1.x)) + "," + string(round(_bp1.y)) + ";" + string(round(_bp2.x)) + "," + string(round(_bp2.y))
        + " ap=" + _ap
        + " boxes=" + _boxes;
}

function Scenario_WorldStage(_w) {
    with (obj_enemy) instance_destroy();
    _w.sl = instance_create_layer(1 * GRID_TILE_SIZE, 7 * GRID_TILE_SIZE, "Instances", obj_slime);   // in the open lit part of the room, over light and dark floor (frozen, so its sight does not matter)
    Scenario_PlaceEnemy(_w.sl, 1, 7);
    EnemyAI_Init(_w.sl);   // freeze it before its first update (that update may be late after a battle, and would pick a wander step): no wandering, no spotting, "!" held on
    _w.sl.idle_timer = 1000000;
    _w.sl.spot_cooldown = 1000000;
    _w.sl.alert_pop = 1000000;
    _w.chest = Scenario_Block(obj_chest_lv1, 5, 7);   // right of the player and clear of the room's light shaft (it dims what is under it)
    var _pl = Scenario_PlacePlayer(4, 7);
    _pl.face = RIGHT;
    _w.calls0 = variable_global_exists("nav_fx_calls") ? global.nav_fx_calls : 0;
}

function Scenario_StepShotsWorld(_s) {
    var _gs = GameState_Get();
    if (!is_struct(_s.wd)) _s.wd = { pass: 0, sl: noone, chest: noone, calls0: 0, shot: "" };
    var _w = _s.wd;
    var _tapnow = ((_s.f - _s.last_tap) >= 8);
    switch (_s.step) {
        case 60:   // pass 0: a fresh knight into rm_floor1
            if (_s.t == 1) {
                Scenario_NewKnight();
                Scenario_SetWindowScale(3);
                room_goto(rm_floor1);
            }
            var _talk = (_gs.ui.mode == UI_DIALOGUE || array_length(_gs.ui.lines) > 0);
            if (_talk && _tapnow) Scenario_Tap("confirm");
            if (_s.t >= 45 && !_talk && !Transition_IsActive()) Scenario_Next(_s, 61);
            else if (_s.t > 900) { Scenario_Check("shots_world_floor1_ready", false, "dialogue or fade still up"); Scenario_Finish(); }
            break;
        case 61:   // build the stage (the slime frozen, "!" held on)
            if (_s.t == 1) {
                Scenario_Check("shots_world_in_floor1_" + string(_w.pass), room == rm_floor1 && instance_exists(obj_player), "room=" + room_get_name(room));
                Scenario_WorldStage(_w);
                if (_w.pass == 1) Scenario_SetWindowScale(4);
            }
            if (_s.t == 6) {
                with (all) image_speed = 0;   // nothing animates between picture A and B (torches, the slime), so any difference is a mark
            }
            if (_s.t >= 50) {
                // the marks are drawn: this room's layer scripts have been running since the stage was built
                var _calls = variable_global_exists("nav_fx_calls") ? global.nav_fx_calls - _w.calls0 : 0;
                Scenario_Check("shots_world_ring_script_runs_pass_" + string(_w.pass), _calls >= 5, "calls=" + string(_calls));
                Scenario_Next(_s, 62);
            }
            break;
        case 62:   // picture A
            _w.shot = "shot_world_" + string(_w.pass) + "_a.png";
            var _pl = instance_find(obj_player, 0);
            Scenario_Check("shots_world_prompt_target_pass_" + string(_w.pass), instance_exists(_pl.prompt_target) && _pl.prompt_target.id == _w.chest.id);
            Scenario_Check("shots_world_alert_still_on_pass_" + string(_w.pass), _w.sl.alert_pop > 0 && _w.sl.x == 1 * GRID_TILE_SIZE && _w.sl.y == 7 * GRID_TILE_SIZE, "pop=" + string(_w.sl.alert_pop) + " at " + string(_w.sl.x) + "," + string(_w.sl.y) + " mode=" + string(_w.sl.ai_mode));
            Scenario_ShotLayout(_w.shot, Scenario_WorldFlags(_w, "shot_world_" + string(_w.pass) + "_b.png"));
            Scenario_Next(_s, 63);
            break;
        case 63:   // turn the marks off: slime hidden and defeated, the player faces away from the chest
            if (_s.t >= 4) {
                Scenario_Check("shots_world_saved_" + _w.shot, file_exists(_w.shot));
                _w.sl.defeated = true;
                _w.sl.visible = false;
                instance_find(obj_player, 0).face = LEFT;
                Scenario_Next(_s, 64);
            }
            break;
        case 64:   // picture B
            if (_s.t >= 8) {
                _w.shot = "shot_world_" + string(_w.pass) + "_b.png";
                Scenario_ShotLayout(_w.shot);
                Scenario_Next(_s, 65);
            }
            break;
        case 65:
            if (_s.t >= 4) {
                Scenario_Check("shots_world_saved_" + _w.shot, file_exists(_w.shot));
                if (_w.pass >= 1) { Scenario_Finish(); break; }
                Scenario_Next(_s, 66);
            }
            break;
        case 66:   // into a battle ...
            if (_s.t == 1) Scenario_GotoBattle("shots_world");
            if (_s.t >= 30) {
                var _inb = (room == rm_battle && instance_exists(obj_battle_controller));
                Scenario_Check("shots_world_in_battle", _inb, "room=" + room_get_name(room));
                if (!_inb) { Scenario_Finish(); break; }
                instance_find(obj_battle_controller, 0).battle_state = BSTATE_END_RUN;   // the end of a won battle and of a successful run: Battle_EndRun
                Scenario_Next(_s, 67);
            }
            break;
        case 67:   // ... and back (the real return path: room fade to the battle's return room)
            if (room == rm_floor1 && _s.t >= 20 && !Transition_IsActive()) {
                _w.pass = 1;
                Scenario_ClearUi();
                Scenario_Next(_s, 68);
            } else if (_s.t > 900) { Scenario_Check("shots_world_back_from_battle", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 68:
            if (_s.t >= 10) Scenario_Next(_s, 61);
            break;
    }
}

// ---- C1 run loop through the real flows (D25, D26, D36, D46, D87, D88, D92). Writes profile.sav / run.sav: only inside the gate's scratch folder. ----
// New run (known seed) -> story trigger fires and is remembered -> death -> death scene -> run summary -> echo pick -> new run at level 1 with
// another seed, death count +1, echo applied, the same trigger not replayed -> room change autosaves -> "relaunch" (state wiped, profile reloaded
// from disk) -> title Continue restores room, HP, position, seed and the loot stream -> pause menu Abandon run -> echo pick -> new run ->
// the win: the ending plays once, wins + 1, the first win unlocks the Nobody class; a second win skips the ending.
function Scenario_ItemCount(_ch, _id) {
    var _n = 0;
    for (var _i = 0; _i < array_length(_ch.inventory); _i++) {
        if (_ch.inventory[_i].id == _id) _n += _ch.inventory[_i].qty;
    }
    return _n;
}

function Scenario_FloorReady(_room) {
    return room == _room && instance_exists(obj_player) && !Transition_IsActive();
}

// Taps confirm every 8 frames while a cutscene line is on screen (the death scene's text).
function Scenario_TapCutscene(_s) {
    var _gs = GameState_Get();
    if (room == rm_cutscene && _gs.ui.mode == UI_DIALOGUE && !Transition_IsActive() && (_s.f - _s.last_tap) >= 8) Scenario_Tap("confirm");
}

function Scenario_EchoMatches(_ch, _o, _items_before) {
    if (_o.kind == "item") return Scenario_ItemCount(_ch, _o.id) == _items_before + 1;
    for (var _i = 0; _i < array_length(_ch.skills); _i++) { if (_ch.skills[_i] == _o.id) return true; }
    return false;
}

function Scenario_StepSmokeRun(_s) {
    var _gs = GameState_Get();
    var _sc = instance_exists(obj_start_controller) ? instance_find(obj_start_controller, 0) : noone;
    if (!variable_struct_exists(_s, "rl")) _s.rl = {};
    var _rl = _s.rl;
    switch (_s.step) {
        case 100:   // run 1: clean profile, known seed, started the way the title starts a run
            if (_s.t == 1) {
                if (!Scenario_CanSaveSlot()) {
                    show_debug_message("[TEST] SKIP runloop (LOCALAPPDATA is not the gate scratch folder)");
                    Scenario_Finish();
                    break;
                }
                if (Transition_IsActive()) { _s.t = 0; break; }
                Dialogue_CloseNow();
                Scenario_ClearUi();
                Profile_ResetForTest();
                RunSave_Delete();
                Run_StartNew(false, 1111);
            }
            if (_s.t > 5 && Scenario_FloorReady(rm_floor1)) {
                var _ch0 = _gs.player_ch;
                Scenario_Check("run_new_run_is_active_with_its_seed", Run_IsActive() && _gs.run.seed == 1111, "seed=" + string(_gs.run.seed));
                Scenario_Check("run_new_run_starts_at_level_1_as_nobody", _ch0.level == 1 && _ch0.class_id == CLASS_NOBODY && _ch0.hp == _ch0.max_hp, "level=" + string(_ch0.level));
                Scenario_Check("run_profile_counts_the_started_run", Profile_Get().runs_started == 1, "runs_started=" + string(Profile_Get().runs_started));
                Scenario_Check("run_room_change_autosaved_the_run", RunSave_HasSave() && RunSave_LoadFrom().status == "ok");
                Scenario_Next(_s, 101);
            }
            if (_s.t > 600) { Scenario_Check("run_new_run_reaches_rm_floor1", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 101:   // a story trigger fires on first contact and is remembered in the profile
            if (_s.t == 1) {
                var _trg = instance_exists(obj_dialogue_trigger) ? instance_find(obj_dialogue_trigger, 0) : noone;
                Scenario_Check("run_floor1_has_a_story_trigger", _trg != noone);
                if (_trg == noone) { Scenario_Finish(); break; }
                _rl.trg = _trg.id;
                Scenario_ClearUi();
                var _pl = instance_find(obj_player, 0);
                _pl.x = _trg.x;
                _pl.y = _trg.y;
                _pl.moving = false;
                _pl.move_timer = 0;
            }
            if (_s.t > 2 && instance_exists(_rl.trg) && _rl.trg.triggered) {
                _rl.story_key = _rl.trg.story_key;
                Scenario_Check("story_trigger_fired_and_has_a_key", _rl.story_key != "", "key=" + _rl.story_key);
                Scenario_Check("story_trigger_is_marked_seen_in_the_profile", Story_Seen(_rl.story_key));
                Scenario_Check("story_trigger_dialogue_played_on_first_contact", _gs.ui.mode == UI_DIALOGUE || array_length(_gs.ui.lines) > 0);
                Scenario_Next(_s, 102);
            }
            if (_s.t > 240) { Scenario_Check("story_trigger_fires", false, "triggered=" + string(instance_exists(_rl.trg) ? _rl.trg.triggered : "gone")); Scenario_Finish(); }
            break;
        case 102:   // die (the same hook the battle end calls); the death scene plays
            if (_s.t == 1) {
                Dialogue_CloseNow();
                Scenario_ClearUi();
                var _chd = _gs.player_ch;
                _chd.level = 5;
                _chd.inventory = Inv_Add(_chd.inventory, 11, 1);
                GameState_SetPlayer(_chd);
                _gs.run.kills = 4;
                Player_OnDeath(_gs.player_ch);
            }
            if (_s.t > 3) Scenario_TapCutscene(_s);
            if (_s.t > 3 && _sc != noone && _sc.state == "run_flow") {
                var _pf = Profile_Get();
                Scenario_Check("death_profile_counts_one_death", _pf.deaths == 1, "deaths=" + string(_pf.deaths));
                Scenario_Check("death_history_entry_has_the_run", array_length(_pf.history) == 1 && _pf.history[0].result == "died" && _pf.history[0].seed == 1111 && _pf.history[0].level == 5 && _pf.history[0].floor == 1 && _pf.history[0].kills == 4);
                Scenario_Check("death_run_save_is_deleted_no_reload", !RunSave_HasSave());
                Scenario_Check("death_run_is_over", !Run_IsActive());
                Scenario_Check("death_flow_starts_with_the_summary", global.run_flow.phase == "summary");
                var _okopts = array_length(_pf.echo_offer) == 2;   // the run had two things: potion (10) and MP potion (11)
                for (var _i = 0; _i < array_length(_pf.echo_offer); _i++) {
                    if (_pf.echo_offer[_i].kind != "item" || (_pf.echo_offer[_i].id != 10 && _pf.echo_offer[_i].id != 11)) _okopts = false;
                }
                Scenario_Check("death_echo_offer_is_1_of_what_the_run_had", _okopts, "offer=" + json_stringify(_pf.echo_offer));
                Scenario_Next(_s, 103);
            }
            if (_s.t > 1200) { Scenario_Check("death_reaches_the_run_summary", false, "room=" + room_get_name(room) + " state=" + (_sc != noone ? string(_sc.state) : "none")); Scenario_Finish(); }
            break;
        case 103:   // summary -> echo pick: down once, confirm
            if (_s.t == 20) Scenario_Tap("confirm");
            if (_s.t == 40) {
                Scenario_Check("death_confirm_moves_on_to_the_echo_pick", global.run_flow.phase == "echo", "phase=" + string(global.run_flow.phase));
                Scenario_Tap("menu_down");
            }
            if (_s.t == 60) {
                Scenario_Check("death_echo_cursor_moved_down", global.run_flow.index == 1, "index=" + string(global.run_flow.index));
                _rl.pick = global.run_flow.options[global.run_flow.index];
                _rl.items_before = Scenario_ItemCount(CharacterCreate_Player(CLASS_NOBODY), _rl.pick.kind == "item" ? _rl.pick.id : -1);
                Scenario_Tap("confirm");
            }
            if (_s.t > 62 && Transition_IsActive()) Scenario_Next(_s, 104);
            if (_s.t > 300) { Scenario_Check("death_echo_pick_starts_the_next_run", false, "phase=" + string(global.run_flow.phase)); Scenario_Finish(); }
            break;
        case 104:   // run 2: level 1, another seed, the echo, the trigger not replayed
            if (_s.t > 5 && Scenario_FloorReady(rm_floor1)) {
                var _ch2 = _gs.player_ch;
                var _pf2 = Profile_Get();
                _rl.seed2 = _gs.run.seed;
                Scenario_Check("newrun_has_another_seed", Run_IsActive() && _gs.run.seed != 1111, "seed=" + string(_gs.run.seed));
                Scenario_Check("newrun_starts_at_level_1_again", _ch2.level == 1 && _ch2.class_id == CLASS_NOBODY && _ch2.hp == _ch2.max_hp, "level=" + string(_ch2.level));
                Scenario_Check("newrun_death_count_stays_1", _pf2.deaths == 1, "deaths=" + string(_pf2.deaths));
                Scenario_Check("newrun_counts_2_started_runs", _pf2.runs_started == 2, "runs_started=" + string(_pf2.runs_started));
                Scenario_Check("newrun_echo_is_consumed", _pf2.echo.kind == "" && array_length(_pf2.echo_offer) == 0);
                Scenario_Check("newrun_echo_is_applied", Scenario_EchoMatches(_ch2, _rl.pick, _rl.items_before) && _gs.run.echo_used.kind == _rl.pick.kind && _gs.run.echo_used.id == _rl.pick.id, "pick=" + json_stringify(_rl.pick));
                Scenario_Check("newrun_does_not_replay_the_fall_dialogue", !_gs.pending_floor1_intro_dialogue);
                Scenario_Check("newrun_carries_no_gold_or_kills", _gs.run.gold == 0 && _gs.run.kills == 0);
                Scenario_Check("newrun_autosaved_with_the_new_seed", RunSave_HasSave() && RunSave_LoadFrom().run.seed == _rl.seed2);
                var _trg2 = instance_find(obj_dialogue_trigger, 0);
                _rl.trg = _trg2.id;
                Scenario_ClearUi();
                var _pl2 = instance_find(obj_player, 0);
                _pl2.x = _trg2.x;
                _pl2.y = _trg2.y;
                _pl2.moving = false;
                _pl2.move_timer = 0;
                Scenario_Next(_s, 105);
            }
            if (_s.t > 600) { Scenario_Check("newrun_reaches_rm_floor1", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 105:   // standing on the trigger of run 1: nothing plays (seen once per profile)
            if (_s.t == 60) {
                Scenario_Check("story_trigger_is_done_in_the_new_run", instance_exists(_rl.trg) && _rl.trg.triggered);
                Scenario_Check("story_trigger_does_not_replay", _gs.ui.mode == UI_NONE && array_length(_gs.ui.lines) == 0, "mode=" + string(_gs.ui.mode));
                Scenario_Next(_s, 106);
            }
            break;
        case 106:   // a quiet room change to rm_floor2 with 3 HP, loot stream advanced; the run is saved on arrival and again
            if (_s.t == 1) {
                var _ch3 = _gs.player_ch;
                _ch3.hp = 3;
                GameState_SetPlayer(_ch3);
                room_goto(rm_floor2);
            }
            if (_s.t > 5 && Scenario_FloorReady(rm_floor2) && _s.t > 40) {
                Scenario_Check("quit_arrived_in_rm_floor2_with_3_hp", _gs.player_ch.hp == 3, "hp=" + string(_gs.player_ch.hp));
                var _pl3 = instance_find(obj_player, 0);
                _rl.px = _pl3.x;
                _rl.py = _pl3.y;
                repeat (3) RunRng_Float("loot");
                _rl.loot_calls = Run_Stream("loot").calls;
                _rl.next_loot = Rng_Next(Rng_Load(Rng_Save(Run_Stream("loot"))));
                Scenario_Check("quit_autosave_writes_the_run", Run_AutoSave() && RunSave_HasSave());
                Scenario_Check("quit_save_holds_the_room_and_hp", RunSave_LoadFrom().run.statData.save_room_name == "rm_floor2" && RunSave_LoadFrom().run.statData.player.hp == 3);
                // "quit": the live state goes away, the profile is dropped from memory (it is read from disk again), back to the title
                variable_struct_remove(_gs, "run");
                _gs.player_ch = CharacterCreate_Player(CLASS_KNIGHT);
                _gs.flags = {};
                _gs.persist = {};
                global.profile = undefined;
                _gs.in_main_menu = true;
                room_goto(rm_start);
                Scenario_Next(_s, 107);
            }
            if (_s.t > 600) { Scenario_Check("quit_reaches_rm_floor2", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 107:   // relaunch: the title's Continue row
            if (_s.t > 40 && room == rm_start && _sc != noone && _sc.state == "main" && is_struct(_sc.title_stk) && !Transition_IsActive() && _gs.ui.mode == UI_NONE) {
                Scenario_Check("continue_row_is_on_when_a_run_save_exists", _sc.title_stk.menus[0].items[1].enabled);
                Scenario_Check("continue_no_run_in_memory_before", !Run_IsActive());
                Ui_MenuFixCursor(_sc.title_stk.menus[0], 1);   // the Continue row
                Scenario_Tap("confirm");
                Scenario_Next(_s, 108);
            }
            if (_s.t > 600) { Scenario_Check("continue_reaches_the_title_menu", false, "room=" + room_get_name(room) + " state=" + (_sc != noone ? string(_sc.state) : "none")); Scenario_Finish(); }
            break;
        case 108:   // Continue restores the room, HP, position, seed and the loot stream
            if (_s.t > 5 && Scenario_FloorReady(rm_floor2) && _s.t > 30) {
                var _pl4 = instance_find(obj_player, 0);
                Scenario_Check("continue_restores_the_room", room == rm_floor2);
                Scenario_Check("continue_restores_hp", _gs.player_ch.hp == 3, "hp=" + string(_gs.player_ch.hp));
                Scenario_Check("continue_restores_the_position", _pl4.x == _rl.px && _pl4.y == _rl.py, "x=" + string(_pl4.x) + " y=" + string(_pl4.y) + " want " + string(_rl.px) + "," + string(_rl.py));
                Scenario_Check("continue_restores_the_seed", Run_IsActive() && _gs.run.seed == _rl.seed2, "seed=" + string(_gs.run.seed));
                Scenario_Check("continue_restores_the_loot_stream_counter", Run_Stream("loot").calls == _rl.loot_calls, "calls=" + string(Run_Stream("loot").calls) + " want " + string(_rl.loot_calls));
                Scenario_Check("continue_loot_stream_goes_on_where_it_stopped", Rng_Next(Rng_Load(Rng_Save(Run_Stream("loot")))) == _rl.next_loot);
                Scenario_Check("continue_reads_the_profile_from_disk", Profile_Get().deaths == 1 && Story_Seen(_rl.story_key), "deaths=" + string(Profile_Get().deaths));
                Scenario_Check("continue_class_is_the_runs_not_the_wiped_state", _gs.player_ch.class_id == CLASS_NOBODY && _gs.selected_class == CLASS_NOBODY);
                Scenario_Next(_s, 109);
            }
            if (_s.t > 600) { Scenario_Check("continue_enters_the_saved_room", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
        case 109:   // pause menu > Abandon run: down x3, confirm twice
            if (_s.t == 1) {
                Scenario_ClearUi();
                PauseMenu_Open();
            }
            if (_s.t == 12 || _s.t == 24 || _s.t == 36) Scenario_Tap("menu_down");
            if (_s.t == 48) {
                Scenario_Check("abandon_cursor_is_on_the_abandon_row", _gs.ui.pause_menu.index == 3, "index=" + string(_gs.ui.pause_menu.index));
                Scenario_Tap("confirm");
            }
            if (_s.t == 60) {
                Scenario_Check("abandon_asks_before_it_acts", _gs.ui.pause_menu.abandon_armed && Run_IsActive());
                Scenario_Tap("confirm");
            }
            if (_s.t > 62) Scenario_TapCutscene(_s);
            if (_s.t > 62 && _sc != noone && _sc.state == "run_flow") {
                var _pf3 = Profile_Get();
                Scenario_Check("abandon_counts_as_a_death", _pf3.deaths == 2, "deaths=" + string(_pf3.deaths));
                Scenario_Check("abandon_history_says_abandoned", array_length(_pf3.history) == 2 && _pf3.history[1].result == "abandoned" && _pf3.history[1].floor == 2, "history=" + json_stringify(_pf3.history));
                Scenario_Check("abandon_keeps_the_echo_offer", array_length(_pf3.echo_offer) >= 1);
                Scenario_Check("abandon_deletes_the_run_save", !RunSave_HasSave() && !Run_IsActive());
                Scenario_Next(_s, 110);
            }
            if (_s.t > 1200) { Scenario_Check("abandon_reaches_the_run_summary", false, "room=" + room_get_name(room) + " state=" + (_sc != noone ? string(_sc.state) : "none") + " mode=" + string(_gs.ui.mode)); Scenario_Finish(); }
            break;
        case 110:   // summary + pick (first option) -> run 3
            if (_s.t == 20) Scenario_Tap("confirm");
            if (_s.t == 40) Scenario_Tap("confirm");
            if (_s.t > 5 && Scenario_FloorReady(rm_floor1) && _s.t > 60) {
                Scenario_Check("abandon_next_run_starts_at_level_1", _gs.player_ch.level == 1 && Run_IsActive() && Profile_Get().runs_started == 3, "runs_started=" + string(Profile_Get().runs_started));
                Scenario_Next(_s, 111);
            }
            if (_s.t > 600) { Scenario_Check("abandon_next_run_reaches_rm_floor1", false, "room=" + room_get_name(room) + " phase=" + string(global.run_flow.phase)); Scenario_Finish(); }
            break;
        case 111:   // the first win: the ending plays (skipped by holding confirm), wins + 1, the Nobody class unlocks
            if (_s.t == 1) {
                Scenario_ClearUi();
                _rl.held = false;
                Scenario_Check("win_nobody_class_is_locked_before", !Profile_IsUnlocked(Profile_Get(), "nobody_class"));
                Transition_RequestCutsceneById("ending");
            }
            if (_s.t > 2 && room == rm_cutscene && _sc != noone && _sc.cutscene_started && !Transition_IsActive() && _gs.ui.mode == UI_DIALOGUE && !_rl.held) {
                _rl.held = true;
                Scenario_Hold("confirm", 120);
            }
            if (_s.t > 2 && room == rm_start && !Transition_IsActive()) {
                Scenario_Release();
                var _pf4 = Profile_Get();
                Scenario_Check("win_ending_cutscene_played_once", _rl.held && Story_Seen(Story_CutsceneKey("ending")));
                Scenario_Check("win_counts_one_win", _pf4.wins == 1 && _pf4.deaths == 2, "wins=" + string(_pf4.wins) + " deaths=" + string(_pf4.deaths));
                Scenario_Check("win_first_win_unlocks_the_nobody_class", Profile_IsUnlocked(_pf4, "nobody_class"));
                Scenario_Check("win_history_says_won", _pf4.history[array_length(_pf4.history) - 1].result == "won");
                Scenario_Check("win_ends_the_run_and_deletes_its_save", !Run_IsActive() && !RunSave_HasSave());
                _rl.saw_cutscene = false;
                Scenario_Next(_s, 112);
            }
            if (_s.t > 1500) { Scenario_Check("win_ending_returns_to_the_title", false, "room=" + room_get_name(room) + " held=" + string(_rl.held)); Scenario_Finish(); }
            break;
        case 112:   // a second win: the ending is not shown again, the win still counts
            if (_s.t == 1) {
                _gs.in_main_menu = false;
                Run_StartNew(false, 2222);
            }
            if (_s.t > 5 && _s.t < 400 && Scenario_FloorReady(rm_floor1) && !variable_struct_exists(_rl, "second")) {
                _rl.second = true;
                Scenario_ClearUi();
                Transition_RequestCutsceneById("ending");
            }
            if (room == rm_cutscene) _rl.saw_cutscene = true;
            if (variable_struct_exists(_rl, "second") && _s.t > 10 && room == rm_start && !Transition_IsActive()) {
                var _pf5 = Profile_Get();
                Scenario_Check("win2_ending_is_not_shown_again", !_rl.saw_cutscene);
                Scenario_Check("win2_counts_the_second_win", _pf5.wins == 2, "wins=" + string(_pf5.wins));
                Scenario_Check("win2_nobody_class_stays_unlocked", Profile_IsUnlocked(_pf5, "nobody_class"));
                Scenario_Finish();
            }
            if (_s.t > 900) { Scenario_Check("win2_returns_to_the_title", false, "room=" + room_get_name(room)); Scenario_Finish(); }
            break;
    }
}
