Input_PreStep();
var gs = GameState_Get();

if (!variable_instance_exists(id, "difficulty_options") || !is_array(difficulty_options) || array_length(difficulty_options) <= 0) {
    difficulty_options = [
        Loc_T("settings.difficulty.option.0", "Easy"),
        Loc_T("settings.difficulty.option.1", "Normal"),
        Loc_T("settings.difficulty.option.2", "Hard")
    ];
}
if (!variable_instance_exists(id, "difficulty_values") || !is_array(difficulty_values) || array_length(difficulty_values) != array_length(difficulty_options)) {
    difficulty_values = [DIFFICULTY_EASY, DIFFICULTY_NORMAL, DIFFICULTY_HARD];
}
if (!variable_instance_exists(id, "difficulty_index")) {
    difficulty_index = 1;
}
var difficulty_row_count = array_length(difficulty_options) + 1; // + Back row
difficulty_index = clamp(difficulty_index, 0, max(0, difficulty_row_count - 1));

if (gs.ui.mode == UI_SAVE) exit;
if (Transition_IsInputLocked() && state != "cutscene") return;

var k_up = Input_UIPressed("menu_up");
var k_down = Input_UIPressed("menu_down");
var k_left = Input_UIPressed("menu_left");
var k_right = Input_UIPressed("menu_right");
var k_ok = Input_UIConfirm();
var k_back = Input_UIBack();

if (state == "boot_logo") {
    if (Transition_IsActive()) return;

    switch (boot_logo_phase) {
        case 0: // fade in
            boot_logo_timer += 1;
            var in_t = clamp(boot_logo_timer / max(1, boot_logo_fade_in_frames), 0, 1);
            // smoothstep easing keeps the intro logo fade seamless and bell-curved
            boot_logo_alpha = in_t * in_t * (3 - (2 * in_t));
            if (boot_logo_timer >= max(1, boot_logo_fade_in_frames)) {
                boot_logo_phase = 1;
                boot_logo_timer = 0;
                boot_logo_alpha = 1;
            }
            break;

        case 1: // hold
            boot_logo_timer += 1;
            boot_logo_alpha = 1;
            if (boot_logo_timer >= max(0, boot_logo_hold_frames)) {
                boot_logo_phase = 2;
                boot_logo_timer = 0;
            }
            break;

        case 2: // fade out
            boot_logo_timer += 1;
            var out_t = clamp(boot_logo_timer / max(1, boot_logo_fade_out_frames), 0, 1);
            out_t = out_t * out_t * (3 - (2 * out_t));
            boot_logo_alpha = 1 - out_t;
            if (boot_logo_timer >= max(1, boot_logo_fade_out_frames)) {
                boot_logo_phase = 3;
                boot_logo_timer = 0;
                boot_logo_alpha = 0;
            }
            break;

        default: // black hold, then reveal title menu
            boot_logo_timer += 1;
            boot_logo_alpha = 0;
            if (boot_logo_timer >= max(0, boot_logo_black_hold_frames)) {
                state = "main";
                Transition_RequestBlackFlash(1, TRANSITION_CUTSCENE_FADE_IN_FRAMES);
            }
            break;
    }

    return;
}

if (state == "main") {
    var title_idx_new = 0;
    var title_idx_load = 1;
    var title_idx_settings = 2;
    var title_idx_exit = 3;

    load_available = Save_HasAnySlot();
    if (!load_available && main_index == title_idx_load) {
        main_index = (main_index + 1) mod array_length(main_options);
    }

    if (k_up) {
        var max_loop_up = array_length(main_options);
        repeat (max_loop_up) {
            main_index = (main_index + array_length(main_options) - 1) mod array_length(main_options);
            if (load_available || main_index != title_idx_load) break;
        }
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        var max_loop_down = array_length(main_options);
        repeat (max_loop_down) {
            main_index = (main_index + 1) mod array_length(main_options);
            if (load_available || main_index != title_idx_load) break;
        }
        SFX_PlayUI("ui_move");
    }

    if (k_ok) {
        var opt = main_index;
        if (opt == title_idx_load && !load_available) {
            main_index = (main_index + 1) mod array_length(main_options);
            SFX_PlayUI("ui_move");
            return;
        }

        SFX_PlayUI("ui_confirm");
        if (opt == title_idx_new) {
            UI_ModalRootBegin("title_difficulty");
            var current_difficulty = DIFFICULTY_NORMAL;
            if (variable_struct_exists(gs, "difficulty")) current_difficulty = Difficulty_Normalize(gs.difficulty);
            difficulty_index = 1;
            for (var di = 0; di < array_length(difficulty_values); di++) {
                if (difficulty_values[di] == current_difficulty) {
                    difficulty_index = di;
                    break;
                }
            }
            difficulty_opened_frame = Input_Frame();
            difficulty_closing = false;
            difficulty_close_frame = UI_OPENED_FRAME_NONE;
            difficulty_pending_action = "";
            state = "difficulty";
        } else if (opt == title_idx_load) {
            SaveMenu_Open("load", "main");
        } else if (opt == title_idx_settings) {
            SettingsPopup_Open("title");
            state = "settings";
        } else if (opt == title_idx_exit) {
            game_end();
        }
    }
    return;
}

if (state == "difficulty") {
    if (difficulty_closing) {
        if (Input_Frame() - difficulty_close_frame >= UI_POPUP_FADE_FRAMES) {
            var da = string(difficulty_pending_action);
            difficulty_closing = false;
            difficulty_close_frame = UI_OPENED_FRAME_NONE;
            if (da == "start_intro") {
                Difficulty_SetCurrent(difficulty_pending_value);
                gs.in_main_menu = false;
                Transition_RequestCutsceneById("intro");
            } else {
                state = "main";
            }
        }
        return;
    }

    var diff_rows = array_length(difficulty_options) + 1; // options + Back
    if (k_up) {
        difficulty_index = (difficulty_index + diff_rows - 1) mod diff_rows;
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        difficulty_index = (difficulty_index + 1) mod diff_rows;
        SFX_PlayUI("ui_move");
    }

    if (k_back) {
        SFX_PlayUI("ui_back");
        UI_ModalRootEnd(false);
        difficulty_closing = true;
        difficulty_close_frame = Input_Frame();
        difficulty_pending_action = "to_main";
        return;
    }

    if (k_ok) {
        SFX_PlayUI("ui_confirm");
        if (difficulty_index >= 0 && difficulty_index < array_length(difficulty_values)) {
            UI_ModalRootHold("title_room_change");
            difficulty_pending_value = difficulty_values[difficulty_index];
            difficulty_closing = true;
            difficulty_close_frame = Input_Frame();
            difficulty_pending_action = "start_intro";
        } else {
            UI_ModalRootEnd(false);
            difficulty_closing = true;
            difficulty_close_frame = Input_Frame();
            difficulty_pending_action = "to_main";
        }
    }
    return;
}

if (state == "cutscene") {
    // Allow first cutscene segment to initialize under the entry fade so the
    // first image reveals with fade-in (instead of popping after fade ends).
    // Still block processing while transitioning out of rm_cutscene.
    var allow_entry_bootstrap = false;
    if (!cutscene_started && Transition_IsInputLocked() && variable_struct_exists(gs, "transition_fx") && is_struct(gs.transition_fx)) {
        var tr_boot = gs.transition_fx;
        if (tr_boot.active && tr_boot.type == TRANSITION_TYPE_CUTSCENE && tr_boot.target_room == room) {
            allow_entry_bootstrap = true;
        }
    }
    if (Transition_IsInputLocked() && !cutscene_wait_transition && !allow_entry_bootstrap) return;

    if (!cutscene_started) {
        cutscene_id = "";
        if (variable_struct_exists(gs, "pending_cutscene_id")) {
            cutscene_id = string(gs.pending_cutscene_id);
        }
        if (cutscene_id == "") cutscene_id = "intro";
        cutscene_sequence = [];
        if (variable_struct_exists(cutscene_definitions, cutscene_id)) {
            var seq = variable_struct_get(cutscene_definitions, cutscene_id);
            if (is_array(seq)) cutscene_sequence = seq;
        }

        if (is_array(cutscene_sequence)) {
            for (var segi = 0; segi < array_length(cutscene_sequence); segi++) {
                var seg_loc = cutscene_sequence[segi];
                if (!is_struct(seg_loc)) continue;
                if (!variable_struct_exists(seg_loc, "lines") || !is_array(seg_loc.lines)) continue;
                for (var li_loc = 0; li_loc < array_length(seg_loc.lines); li_loc++) {
                    var fallback_loc = string(seg_loc.lines[li_loc]);
                    seg_loc.lines[li_loc] = Loc_T("cutscene." + cutscene_id + "." + string(segi) + "." + string(li_loc), fallback_loc);
                }
                cutscene_sequence[segi] = seg_loc;
            }
        }

        if (!is_array(cutscene_sequence) || array_length(cutscene_sequence) <= 0) {
            Transition_RequestCutsceneFade(rm_start);
            return;
        }

        cutscene_started = true;
        cutscene_segment_index = 0;
        cutscene_segment_hold_timer = 0;
        cutscene_wait_transition = false;
        cutscene_transition_next_index = -1;
        cutscene_transition_switched = false;

        gs.ui.cutscene_active = true;
        gs.ui.dialogue_box_half = false;
        gs.ui.cutscene_logo_sprite = noone;
        gs.ui.cutscene_logo_alpha = 0;

        var seg0 = cutscene_sequence[cutscene_segment_index];
        var seg0_text_only = true;
        if (variable_struct_exists(seg0, "text_only")) seg0_text_only = seg0.text_only;
        gs.ui.cutscene_text_only = seg0_text_only;
        if (variable_struct_exists(seg0, "chars_per_sec")) gs.ui.cutscene_chars_per_sec = real(seg0.chars_per_sec);
        else gs.ui.cutscene_chars_per_sec = -1;
        var seg0_sprite = noone;
        if (variable_struct_exists(seg0, "sprite")) seg0_sprite = seg0.sprite;
        if ((is_undefined(seg0_sprite) || seg0_sprite == noone || seg0_sprite == -1) && variable_struct_exists(seg0, "sprite_name")) {
            seg0_sprite = asset_get_index(string(seg0.sprite_name));
        }
        if (is_undefined(seg0_sprite) || seg0_sprite == -1 || seg0_sprite == noone) seg0_sprite = black_screen;
        gs.ui.cutscene_bg_sprite = seg0_sprite;
        var seg0_lines = variable_struct_exists(seg0, "lines") ? seg0.lines : [];
        if (is_array(seg0_lines) && array_length(seg0_lines) > 0) {
            Dialogue_StartLines(seg0_lines);
        } else {
            gs.ui.mode = UI_NONE;
            gs.ui.lines = [];
            gs.ui.lines_raw = [];
            gs.ui.index = 0;
            gs.ui.speaker = "";
            cutscene_segment_hold_timer = max(0, variable_struct_exists(seg0, "hold_frames") ? seg0.hold_frames : 0);
        }
        return;
    }

    if (cutscene_wait_transition) {
        if (Transition_IsActive()) {
            if (!cutscene_transition_switched
            && variable_struct_exists(gs, "transition_fx")
            && is_struct(gs.transition_fx)
            && gs.transition_fx.type == TRANSITION_TYPE_FLASH
            && gs.transition_fx.alpha >= 0.999) {
                cutscene_segment_index = cutscene_transition_next_index;
                cutscene_segment_hold_timer = 0;
                var seg_sw = cutscene_sequence[cutscene_segment_index];
                var seg_sw_text_only = true;
                if (variable_struct_exists(seg_sw, "text_only")) seg_sw_text_only = seg_sw.text_only;
                gs.ui.cutscene_text_only = seg_sw_text_only;
                if (variable_struct_exists(seg_sw, "chars_per_sec")) gs.ui.cutscene_chars_per_sec = real(seg_sw.chars_per_sec);
                else gs.ui.cutscene_chars_per_sec = -1;
                var seg_sw_sprite = noone;
                if (variable_struct_exists(seg_sw, "sprite")) seg_sw_sprite = seg_sw.sprite;
                if ((is_undefined(seg_sw_sprite) || seg_sw_sprite == noone || seg_sw_sprite == -1) && variable_struct_exists(seg_sw, "sprite_name")) {
                    seg_sw_sprite = asset_get_index(string(seg_sw.sprite_name));
                }
                if (is_undefined(seg_sw_sprite) || seg_sw_sprite == -1 || seg_sw_sprite == noone) seg_sw_sprite = black_screen;
                gs.ui.cutscene_bg_sprite = seg_sw_sprite;

                var seg_sw_lines = variable_struct_exists(seg_sw, "lines") ? seg_sw.lines : [];
                if (is_array(seg_sw_lines) && array_length(seg_sw_lines) > 0) {
                    Dialogue_StartLines(seg_sw_lines);
                } else {
                    gs.ui.mode = UI_NONE;
                    gs.ui.lines = [];
                    gs.ui.lines_raw = [];
                    gs.ui.index = 0;
                    gs.ui.speaker = "";
                    cutscene_segment_hold_timer = max(0, variable_struct_exists(seg_sw, "hold_frames") ? seg_sw.hold_frames : 0);
                }

                cutscene_transition_switched = true;
            }
            return;
        }

        if (!cutscene_transition_switched && cutscene_transition_next_index >= 0 && cutscene_transition_next_index < array_length(cutscene_sequence)) {
            cutscene_segment_index = cutscene_transition_next_index;
            cutscene_segment_hold_timer = 0;
            var seg_fallback = cutscene_sequence[cutscene_segment_index];
            var seg_fallback_text_only = true;
            if (variable_struct_exists(seg_fallback, "text_only")) seg_fallback_text_only = seg_fallback.text_only;
            gs.ui.cutscene_text_only = seg_fallback_text_only;
            if (variable_struct_exists(seg_fallback, "chars_per_sec")) gs.ui.cutscene_chars_per_sec = real(seg_fallback.chars_per_sec);
            else gs.ui.cutscene_chars_per_sec = -1;
            var seg_fallback_sprite = noone;
            if (variable_struct_exists(seg_fallback, "sprite")) seg_fallback_sprite = seg_fallback.sprite;
            if ((is_undefined(seg_fallback_sprite) || seg_fallback_sprite == noone || seg_fallback_sprite == -1) && variable_struct_exists(seg_fallback, "sprite_name")) {
                seg_fallback_sprite = asset_get_index(string(seg_fallback.sprite_name));
            }
            if (is_undefined(seg_fallback_sprite) || seg_fallback_sprite == -1 || seg_fallback_sprite == noone) seg_fallback_sprite = black_screen;
            gs.ui.cutscene_bg_sprite = seg_fallback_sprite;

            var seg_fallback_lines = variable_struct_exists(seg_fallback, "lines") ? seg_fallback.lines : [];
            if (is_array(seg_fallback_lines) && array_length(seg_fallback_lines) > 0) {
                Dialogue_StartLines(seg_fallback_lines);
            } else {
                gs.ui.mode = UI_NONE;
                gs.ui.lines = [];
                gs.ui.lines_raw = [];
                gs.ui.index = 0;
                gs.ui.speaker = "";
                cutscene_segment_hold_timer = max(0, variable_struct_exists(seg_fallback, "hold_frames") ? seg_fallback.hold_frames : 0);
            }
        }

        cutscene_wait_transition = false;
        cutscene_transition_next_index = -1;
        cutscene_transition_switched = false;
        return;
    }

    var seg_cur = cutscene_sequence[cutscene_segment_index];
    var seg_cur_lines = variable_struct_exists(seg_cur, "lines") ? seg_cur.lines : [];
    var segment_done = false;

    if (is_array(seg_cur_lines) && array_length(seg_cur_lines) > 0) {
        segment_done = (gs.ui.mode != UI_DIALOGUE && array_length(gs.ui.lines) <= 0);
    } else {
        if (cutscene_segment_hold_timer > 0) cutscene_segment_hold_timer -= 1;
        segment_done = (cutscene_segment_hold_timer <= 0);
    }

    if (!variable_struct_exists(gs.ui, "cutscene_logo_sprite")) gs.ui.cutscene_logo_sprite = noone;
    if (!variable_struct_exists(gs.ui, "cutscene_logo_alpha")) gs.ui.cutscene_logo_alpha = 0;
    var logo_target = 0;
    var logo_sprite = noone;
    if (string(cutscene_id) == "ending" && cutscene_segment_index == 4) {
        logo_sprite = pale_rook_1;
        var logo_line_idx = variable_struct_exists(gs.ui, "index") ? max(0, round(real(gs.ui.index))) : 0;
        if (logo_line_idx >= 3) logo_target = 1;
    }
    var logo_step = 1 / max(1, round(max(1, game_get_speed(gamespeed_fps)) * 0.30));
    if (gs.ui.cutscene_logo_alpha < logo_target) {
        gs.ui.cutscene_logo_alpha = min(logo_target, gs.ui.cutscene_logo_alpha + logo_step);
    } else {
        gs.ui.cutscene_logo_alpha = max(logo_target, gs.ui.cutscene_logo_alpha - logo_step);
    }
    if (gs.ui.cutscene_logo_alpha > 0.001 || logo_target > 0) gs.ui.cutscene_logo_sprite = logo_sprite;
    else gs.ui.cutscene_logo_sprite = noone;

    if (!segment_done) return;

    var next_index = cutscene_segment_index + 1;
    if (next_index < array_length(cutscene_sequence)) {
        var seg_next = cutscene_sequence[next_index];
        var use_slow_segment_fade = false;
        if (variable_struct_exists(seg_cur, "transition_speed") && string(seg_cur.transition_speed) == "slow") use_slow_segment_fade = true;
        if (variable_struct_exists(seg_next, "transition_speed") && string(seg_next.transition_speed) == "slow") use_slow_segment_fade = true;

        var segment_fade_out = use_slow_segment_fade ? TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_OUT_FRAMES : TRANSITION_CUTSCENE_SEGMENT_FADE_OUT_FRAMES;
        var segment_fade_in = use_slow_segment_fade ? TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_IN_FRAMES : TRANSITION_CUTSCENE_SEGMENT_FADE_IN_FRAMES;
        var flash_ok = Transition_RequestBlackFlash(segment_fade_out, segment_fade_in);

        if (flash_ok) {
            cutscene_wait_transition = true;
            cutscene_transition_next_index = next_index;
            cutscene_transition_switched = false;
            return;
        }

        cutscene_segment_index = next_index;
        cutscene_segment_hold_timer = 0;
        var seg_next_text_only = true;
        if (variable_struct_exists(seg_next, "text_only")) seg_next_text_only = seg_next.text_only;
        gs.ui.cutscene_text_only = seg_next_text_only;
        if (variable_struct_exists(seg_next, "chars_per_sec")) gs.ui.cutscene_chars_per_sec = real(seg_next.chars_per_sec);
        else gs.ui.cutscene_chars_per_sec = -1;
        var seg_next_sprite = noone;
        if (variable_struct_exists(seg_next, "sprite")) seg_next_sprite = seg_next.sprite;
        if ((is_undefined(seg_next_sprite) || seg_next_sprite == noone || seg_next_sprite == -1) && variable_struct_exists(seg_next, "sprite_name")) {
            seg_next_sprite = asset_get_index(string(seg_next.sprite_name));
        }
        if (is_undefined(seg_next_sprite) || seg_next_sprite == -1 || seg_next_sprite == noone) seg_next_sprite = black_screen;
        gs.ui.cutscene_bg_sprite = seg_next_sprite;
        var seg_next_lines = variable_struct_exists(seg_next, "lines") ? seg_next.lines : [];
        if (is_array(seg_next_lines) && array_length(seg_next_lines) > 0) {
            Dialogue_StartLines(seg_next_lines);
        } else {
            gs.ui.mode = UI_NONE;
            gs.ui.lines = [];
            gs.ui.lines_raw = [];
            gs.ui.index = 0;
            gs.ui.speaker = "";
            cutscene_segment_hold_timer = max(0, variable_struct_exists(seg_next, "hold_frames") ? seg_next.hold_frames : 0);
        }
        return;
    }

    gs.ui.cutscene_active = false;
    gs.ui.cutscene_bg_sprite = noone;
    gs.ui.dialogue_box_half = false;
    gs.ui.cutscene_text_only = false;
    gs.ui.cutscene_chars_per_sec = -1;
    gs.ui.cutscene_logo_sprite = noone;
    gs.ui.cutscene_logo_alpha = 0;
    gs.pending_cutscene_id = "";

    cutscene_started = false;
    cutscene_sequence = [];
    cutscene_segment_index = -1;
    cutscene_segment_hold_timer = 0;
    cutscene_wait_transition = false;
    cutscene_transition_next_index = -1;
    cutscene_transition_switched = false;

    switch (cutscene_id) {
        case "intro":
            // reset core state for new game
            if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_clear(gs.defeated_enemies);
            gs.room_states = {};
            gs.persist = {};
            gs.persist_applied = {};
            gs.uid_counter = 1;
            gs.enemy_reset_version = 0;
            gs.boss_defeated = { mini_boss: false, final_boss: false };

            GameState_SetSelectedClass(CLASS_NOBODY);
            gs.player_ch = CharacterCreate_Player(CLASS_NOBODY);
            GameState_SetPlayer(gs.player_ch);

            gs.in_main_menu = false;
            gs.pending_floor1_intro_dialogue = true;
            GameSettings_ApplyAll();
            Transition_RequestCutsceneFade(rm_floor1, "start", -1, true);
            break;
        case "ending":
            gs.in_main_menu = true;
            Transition_RequestCutsceneFade(rm_start);
            break;
        case "game_over":
            gs.in_main_menu = false;
            var load_slot = 0;
            if (variable_struct_exists(gs, "save_slot")) {
                var preferred_slot = round(real(gs.save_slot));
                if (preferred_slot >= 1 && preferred_slot <= 3 && Save_HasSlot(preferred_slot)) {
                    load_slot = preferred_slot;
                }
            }
            if (load_slot <= 0) load_slot = Save_FindLatestSlot();

            if (load_slot > 0 && Save_Read(load_slot)) {
                // Save_Read handles transition to the loaded room.
            } else {
                gs.in_main_menu = true;
                Transition_RequestCutsceneFade(rm_start);
            }
            break;
        default:
            Transition_RequestRoomFade(rm_start);
            break;
    }
    return;
}

if (state == "settings") {
    SettingsPopup_HandleInput();
    if (!SettingsPopup_IsOpen("title")) state = "main";
    return;
}
