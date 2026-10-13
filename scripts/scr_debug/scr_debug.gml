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
                   cap: (_mode == "bot") ? 16000 : ((_mode == "shots") ? 16000 : 3500), vstart: 0, hits: 0, tries: 0, attacking: false, exp0: 0, shot: "", sk: 0, sk_start: 0, sk_fx: false, sk_fx_on_player: false, sk_fx_on_enemy: false, sk_fx_px: 0, sk_fx_limit: 0, sk_cast: false, sk_flash: false, sk_mp0: 0, ski: 0, fxi: 0, di: 0, ap0: 0, fin_f: 0, cut_shot: false, fade_shot: false, dlg_seen: false, dlg_t: 0 };
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

function Scenario_InputOverride() {
    if (!variable_global_exists("scn")) return;
    var _s = global.scn;
    if ((_s.mode != "bot" && _s.mode != "shots") || _s.tap_action == "" || _s.f != _s.last_tap) return;   // shots taps through the dialogues of the display flow
    variable_struct_set(global.input.state, _s.tap_action, { held: true, pressed: true });
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
            if (_s.t == 60) _s.ap0 = Display_ApplyCount();   // after the boot layout (frame 30): nothing below may re-lay-out the display (DISP-08)
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

// ---- -shots: screen_save of rm_start / rm_floor1 / rm_battle at display scales 3, 4, 5, then the screen after a cutscene end,
// a dialogue end and a room transition at several window sizes (I-051, DISP-04/06/07/08), then one picture per skill animation ----
// fit_screen is not captured: it needs a real fullscreen switch, which is not safe in an unattended run.

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
    GameSettings_Ensure().fit_screen = false;
    Display_Request({ fullscreen: false, window_w: _w, window_h: _h });
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
function Scenario_ShotLayout(_file, _flags = "") {
    var _w = window_get_width(), _h = window_get_height();
    var _l = Display_CalcLayout(_w, _h);
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
                Scenario_Next(_s, 10);
            }
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
                _fx.image_index = sprite_get_number(_skill.fx_sprite) div 2;
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
