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
    Save_Write(0);
    Dialogue_Start("sys_save_ok");
    Debug_Record("Quick Save");
}

function Debug_Load() {
    if (Save_Read(0)) {
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
        Transition_RequestCutsceneById("game_over");
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
    UI_DrawText(display_get_gui_width() - UI_TextWidth(BUILD_ID) - 4, display_get_gui_height() - UI_TextHeight(BUILD_ID) - 2, BUILD_ID);
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
    if (_mode != "" || Scenario_HasFlag("-runtests")) {
        show_debug_message("[TEST-BUILD] " + BUILD_ID);
        window_set_fullscreen(false);   // tests are always windowed, whatever the saved setting says; no focus / foreground calls anywhere
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
                   cap: (_mode == "bot") ? 16000 : ((_mode == "shots") ? 6000 : 2500), vstart: 0, hits: 0, tries: 0, attacking: false, exp0: 0, shot: "", sk: 0, sk_start: 0, sk_fx: false, sk_fx_on_player: false, sk_fx_on_enemy: false, sk_fx_px: 0, sk_fx_limit: 0, sk_cast: false, sk_flash: false, sk_mp0: 0, ski: 0, fxi: 0, hold_action: "", hold_start: 0, hold_until: -1 };
}

function Scenario_Finish() {
    var _s = global.scn;
    _s.done = true;
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
// A held move key is also kept last in move_order, as the real keyboard path does (Input_MoveAction reads move_order).
function Scenario_Hold(_action, _frames) {
    var _s = global.scn;
    _s.hold_action = _action;
    _s.hold_start = _s.f;
    _s.hold_until = _s.f + _frames - 1;
    if (variable_global_exists("input")) global.input.last_step_time = -1;   // make the next Input_Update recompute, with the press
}

function Scenario_Release() {
    global.scn.hold_action = "";
    global.scn.hold_until = -1;
}

function Scenario_InputOverride() {
    if (!variable_global_exists("scn")) return;
    var _s = global.scn;
    if (_s.mode != "bot" && _s.mode != "smoke") return;
    if (_s.tap_action != "" && _s.f == _s.last_tap) {
        variable_struct_set(global.input.state, _s.tap_action, { held: true, pressed: true });
    }
    if (_s.hold_action != "" && _s.f <= _s.hold_until) {
        variable_struct_set(global.input.state, _s.hold_action, { held: true, pressed: (_s.f == _s.hold_start) });
        if (Input_IsMoveAction(_s.hold_action)) {
            global.input.move_order = Input_ArrayRemove(global.input.move_order, _s.hold_action);
            array_push(global.input.move_order, _s.hold_action);
        }
    }
}

function Scenario_NewKnight(_class = CLASS_KNIGHT) {
    var _gs = GameState_Init();
    _gs.player_ch = CharacterCreate_Player(_class);
    _gs.in_main_menu = false;   // lets obj_game_controller spawn obj_player in a floor room
    return _gs;
}

function Scenario_GotoBattle(_persist_id) {
    GameState_SetBattleReturn(rm_floor1, 0, 0, 0);
    GameState_SetBattleEnemy(_persist_id, ENEMY_SLIME, 1);
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
    if (window_get_fullscreen()) window_set_fullscreen(false);   // a saved fit_screen must not put a test run in fullscreen
    var _gs = GameState_Get();
    if (is_struct(_gs) && variable_struct_exists(_gs, "settings") && is_struct(_gs.settings)) _gs.settings.fit_screen = false;
    if (_s.f > _s.cap) {
        Scenario_Check(_s.mode + "_within_" + string(_s.cap) + "_frames", false, "step=" + string(_s.step));
        Scenario_Finish();
        return;
    }
    switch (_s.mode) {
        case "smoke": Scenario_StepSmoke(_s); break;
        case "bot": Scenario_StepBot(_s); break;
        case "shots": Scenario_StepShots(_s); break;
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
            if (_s.t == 90) {
                Scenario_Check("smoke_title_menu", obj_start_controller.state == "main");
                Scenario_NewKnight();
                room_goto(rm_floor1);
                Scenario_Next(_s, 1);
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
                Scenario_NewKnight();
                room_goto(rm_floor1);
                Scenario_Next(_s, 4);
            }
            break;
        case 4: case 5: case 6: case 7:
            Scenario_StepSmokeSnap(_s);
            break;
    }
}

function Scenario_Aligned(_inst) {
    return (instance_exists(_inst) && Grid_IsAligned(_inst.x) && Grid_IsAligned(_inst.y));
}

function Scenario_CanSaveSlot() {
    // Save_Write(0) writes the real quick-save slot: only inside the gate, which points LOCALAPPDATA at its scratch folder.
    return (string_pos("dd-gate", string_lower(environment_get_variable("LOCALAPPDATA"))) > 0);
}

// I-048 snap: the player and the enemies always rest on the 16 px grid, also after a quick-load taken mid-step and after a room restore.
function Scenario_StepSmokeSnap(_s) {
    switch (_s.step) {
        case 4:
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
                    Scenario_Next(_s, 6);
                    break;
                }
                _pl2.x += 6;   // F5 pressed mid-step stores this raw position
                _s.sn_saved_x = Grid_Snap(_pl2.x);
                _s.sn_saved_y = Grid_Snap(_pl2.y);
                Save_Write(0);
                var _ok = Save_Read(0);
                Scenario_Check("snap_quickload_started", _ok);
                Scenario_Next(_s, 5);
            }
            break;
        case 5:
            if (_s.t == 240) {
                var _pl3 = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
                Scenario_Check("snap_quickload_back_in_rm_floor1", room == rm_floor1 && _pl3 != noone);
                if (_pl3 != noone) {
                    Scenario_Check("snap_quickload_player_on_grid", Scenario_Aligned(_pl3), "x=" + string(_pl3.x) + " y=" + string(_pl3.y));
                    Scenario_Check("snap_quickload_player_on_saved_tile", _pl3.x == _s.sn_saved_x && _pl3.y == _s.sn_saved_y, "x=" + string(_pl3.x) + " y=" + string(_pl3.y) + " want " + string(_s.sn_saved_x) + "," + string(_s.sn_saved_y));
                }
                Scenario_Next(_s, 6);
            }
            break;
        case 6:   // enemy position stored mid-step, then restored on re-entering the room
            if (_s.t == 5 && instance_exists(obj_slime)) {
                var _sl3 = instance_find(obj_slime, 0);
                _sl3.x += 5; _sl3.y += 3;
                RoomState_OnRoomExit();
                room_goto(rm_floor2);
            }
            if (_s.t == 50) {
                room_goto(rm_floor1);
                Scenario_Next(_s, 7);
            }
            break;
        case 7:
            if (_s.t == 50) {
                var _sl4 = instance_exists(obj_slime) ? instance_find(obj_slime, 0) : noone;
                Scenario_Check("snap_enemy_restored_on_grid", _sl4 != noone && room == rm_floor1 && Scenario_Aligned(_sl4), (_sl4 != noone) ? ("x=" + string(_sl4.x) + " y=" + string(_sl4.y)) : "no slime");
                Scenario_Finish();
            }
            break;
    }
}

// ---- -bot: Knight vs Slime through simulated key presses (the real input path) ----
// v=0 "perfect": confirms the menu, times the attack drop and answers the defence arrows from the battle controller's own data.
// v=1 "fail": confirms the menu but never presses during a QTE.
function Scenario_StepBot(_s) {
    if (_s.v >= 2) {
        Scenario_StepBotSkill(_s);
        return;
    }
    var _name = (_s.v == 0) ? "bot_perfect" : "bot_fail";
    switch (_s.step) {
        case 0:   // short pause in rm_start, then start the battle
            if (_s.t == 10) {
                _s.vstart = _s.f;
                _s.hits = 0;
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
                if (_s.v == 1) {   // the fail variant runs last: its lost battle leaves a game-over transition behind
                    Scenario_Finish();
                } else {
                    _s.v = 2;   // 0 perfect -> 2 every player skill, one battle each (_s.ski) -> 1 fail
                    Scenario_Next(_s, 0);
                }
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
                _ch = Status_Add(_ch, STATUS_HIT_UP, 9, 0);
                if (_sid == SKILL_HILT_BASH) _ch = Status_Add(_ch, STATUS_POISON, 3, 0);   // BUG-08: the tick after the skill must reach the log and the HUD
                GameState_SetPlayer(_ch);
                _s.vstart = _s.f;
                _s.sk = -1;
                _s.sk_fx = false;
                _s.sk_mp0 = _ch.mp;
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
                } else if (_bc.battle_state == BSTATE_ENEMY_DEF_QTE && _ready && _bc.enemy_def_qte_active && _bc.enemy_def_qte_phase == 1
                    && _bc.enemy_def_qte_index < array_length(_bc.enemy_def_qte_prompts)) {
                    var _keys = ["move_right", "move_up", "move_left", "move_down"];
                    Scenario_Tap(_keys[_bc.enemy_def_qte_prompts[_bc.enemy_def_qte_index]]);
                }
            } else if (_s.sk == 1) {   // the confirm was read: the controller is in the message state
                if (_bc.battle_state == BSTATE_MESSAGE) {
                    _s.sk_start = _s.f;
                    _s.sk_cast = _bc.skill_banner_active && _bc.skill_banner_name == _skill.name;   // Skill_Use succeeded (Meditation gives MP back, so MP alone cannot show it)
                    _s.sk_fx = instance_exists(_bc.wait_fx);
                    _s.sk_fx_on_player = false;
                    _s.sk_fx_on_enemy = false;
                    _s.sk_fx_px = 0;
                    _s.sk_fx_limit = 0;
                    if (_s.sk_fx) {   // BUG-21: where did the animation spawn, relative to the player and enemy anchor points?
                        var _fxi = _bc.wait_fx;
                        var _pp = FX_CenterAtPoint(_fxi.sprite_index, _bc.player_fx_x, _bc.player_fx_y, _fxi.image_xscale);
                        var _pe = FX_CenterOn(_fxi.sprite_index, _bc.enemy_inst, _fxi.image_xscale);
                        _s.sk_fx_on_player = point_distance(_fxi.x, _fxi.y, _pp.x, _pp.y) < 1;
                        _s.sk_fx_on_enemy = point_distance(_fxi.x, _fxi.y, _pe.x, _pe.y) < 1;
                        // I-052: longest drawn side against the target's (the enemy's sprite, or the player's 32 px reference)
                        var _target = Battle_SkillFxOnPlayer(_sid) ? FX_PLAYER_TARGET_PX : FX_TargetSize(_bc.enemy_inst);
                        _s.sk_fx_px = max(sprite_get_width(_fxi.sprite_index), sprite_get_height(_fxi.sprite_index)) * abs(_fxi.image_xscale);
                        _s.sk_fx_limit = min(64, 1.5 * _target);
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
                    Scenario_Check(_name + "_fx_size_fits_target", _s.sk_fx && _s.sk_fx_px <= _s.sk_fx_limit + 0.01, "drawn=" + string(_s.sk_fx_px) + " limit=" + string(_s.sk_fx_limit));
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
                if (_s.ski >= array_length(_ids)) _s.v = 1;
                Scenario_Next(_s, 0);
            }
            break;
    }
}

function Scenario_BotDrive(_s, _bc) {
    var _ready = (_s.f - _s.last_tap) >= 4;
    var _perfect = (_s.v == 0);
    if (_s.attacking && _bc.battle_state != BSTATE_ATTACK_TIMING) {   // the swing resolved: tally its judgement
        _s.attacking = false;
        _s.tries++;
        if (_bc.attack_timing_result_key != "MISS") _s.hits++;
    }
    switch (_bc.battle_state) {
        case BSTATE_MENU:
            if (_bc.turn == TURN_PLAYER && _ready) Scenario_Tap("confirm");   // menu_index 0 = ATTACK
            break;
        case BSTATE_ATTACK_TIMING:
            if (_bc.attack_timing_active) _s.attacking = true;
            // The drop moves attack_timing_speed per step and the press is read one step later: confirm when one step is left.
            if (_perfect && _ready && _bc.attack_timing_active && _bc.attack_timing_input_lock <= 0
                && (_bc.attack_timing_target_y - _bc.attack_timing_y) <= _bc.attack_timing_speed * 1.5) {
                Scenario_Tap("confirm");
            }
            break;
        case BSTATE_ENEMY_DEF_QTE:
            if (_perfect && _ready && _bc.enemy_def_qte_active && _bc.enemy_def_qte_phase == 1
                && _bc.enemy_def_qte_index < array_length(_bc.enemy_def_qte_prompts)) {
                var _keys = ["move_right", "move_up", "move_left", "move_down"];   // RIGHT, UP, LEFT, DOWN macro order
                Scenario_Tap(_keys[_bc.enemy_def_qte_prompts[_bc.enemy_def_qte_index]]);
            }
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
    if (_s.v == 0) {
        Scenario_Check("bot_perfect_player_won", _pl.hp > 0, "hp=" + string(_pl.hp));
        // _bc.e is the enemy before the killing blow; the blow's damage must account for all of its hp.
        Scenario_Check("bot_perfect_enemy_hp_zero", _bc.e.hp - _bc.last_dmg <= 0, "enemy_hp_before=" + string(_bc.e.hp) + " last_dmg=" + string(_bc.last_dmg));
        Scenario_Check("bot_perfect_exp_gained", _pl.exp > _s.exp0 || _pl.level > 1, "exp=" + string(_pl.exp));
    } else {
        Scenario_Check("bot_fail_player_lost", _pl.hp == 0, "hp=" + string(_pl.hp));
    }
}

// ---- -shots: screen_save of rm_start / rm_floor1 / rm_battle at display scales 3, 4, 5 ----
// fit_screen is not captured: it needs a real fullscreen switch, which is not safe in an unattended run.
function Scenario_StepShots(_s) {
    var _rooms = [rm_start, rm_floor1, rm_battle];
    var _scales = [3, 4, 5];
    switch (_s.step) {
        case 0:   // enter room _s.ri and settle
            if (_s.ri >= array_length(_rooms)) {
                _s.fxi = 0;
                Scenario_Next(_s, 10);   // I-052: one picture per skill animation
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
            if (_s.t == 1) {
                var _st = GameSettings_Ensure();
                _st.display_scale = _scales[_s.si];
                _st.fit_screen = false;
                GameSettings_ApplyDisplay();
            }
            if (_s.t >= 30) Scenario_Next(_s, 2);
            break;
        case 2:
            var _w = window_get_width(), _h = window_get_height();
            _s.shot = "shot_" + room_get_name(room) + "_" + string(_w) + "x" + string(_h) + ".png";
            screen_save(_s.shot);
            show_debug_message("[SHOT] file=" + _s.shot + " w=" + string(_w) + " h=" + string(_h) + " scale=" + string(_scales[_s.si]));
            Scenario_Next(_s, 3);
            break;
        case 3:
            if (_s.t >= 3) {
                Scenario_Check("shots_saved_" + _s.shot, file_exists(_s.shot));
                _s.si++;
                if (_s.si >= array_length(_scales)) { _s.ri++; Scenario_Next(_s, 0); } else Scenario_Next(_s, 1);
            }
            break;
        default:
            Scenario_StepShotsFx(_s);
            break;
    }
}

// I-052: one screenshot per player skill animation, in rm_battle at display scale 3 (480 x 432), file shot_fx_<skill>.png.
// Each skill is spawned through Battle_SkillFxSpawn (the same placement, scale and speed the battle uses) and frozen on its middle frame.
function Scenario_StepShotsFx(_s) {
    var _ids = Skill_PlayerFxIds();
    if (_s.fxi >= array_length(_ids)) {
        Scenario_Finish();
        return;
    }
    var _sid = _ids[_s.fxi];
    var _skill = SkillDB_Get(_sid);
    var _slug = string_lower(string_replace_all(_skill.name, " ", "_"));
    switch (_s.step) {
        case 10:   // a character of the skill's class, into a battle at display scale 3
            if (_s.t == 1) {
                var _gs = Scenario_NewKnight(_skill.class_list[0]);
                var _st = GameSettings_Ensure();
                _st.display_scale = 3;
                _st.fit_screen = false;
                GameSettings_ApplyDisplay();
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
                _fx.image_index = sprite_get_number(_skill.fx_sprite) div 2;
                _fx.image_speed = 0;
                _fx.fx_prev_frame = floor(_fx.image_index);
                Scenario_Next(_s, 11);
            }
            break;
        case 11:   // let the frozen frame be drawn, then save it
            if (_s.t >= 3) {
                _s.shot = "shot_fx_" + _slug + ".png";
                screen_save(_s.shot);
                show_debug_message("[SHOT] file=" + _s.shot + " w=" + string(window_get_width()) + " h=" + string(window_get_height()) + " scale=3 fx_scale=" + string(instance_exists(obj_fx) ? obj_fx.image_xscale : -1));
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
