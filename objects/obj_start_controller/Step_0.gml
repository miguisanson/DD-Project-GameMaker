Input_PreStep();
var gs = GameState_Get();

if (!variable_instance_exists(id, "difficulty_options") || !is_array(difficulty_options) || array_length(difficulty_options) <= 0) {
    difficulty_options = ["Easy", "Normal", "Hard"];
}
if (!variable_instance_exists(id, "difficulty_values") || !is_array(difficulty_values) || array_length(difficulty_values) != array_length(difficulty_options)) {
    difficulty_values = [DIFFICULTY_EASY, DIFFICULTY_NORMAL, DIFFICULTY_HARD];
}
if (!variable_instance_exists(id, "difficulty_index")) {
    difficulty_index = 1;
}
difficulty_index = clamp(difficulty_index, 0, max(0, array_length(difficulty_values) - 1));

if (gs.ui.mode == UI_SAVE) exit;
if (Transition_IsInputLocked() && state != "cutscene") return;

var k_up = Input_UIPressed("menu_up");
var k_down = Input_UIPressed("menu_down");
var k_left = Input_UIPressed("menu_left");
var k_right = Input_UIPressed("menu_right");
var k_ok = Input_UIConfirm();
var k_back = Input_UIBack();

if (state == "main") {
    load_available = Save_HasAnySlot();
    if (!load_available && main_options[main_index] == "Load Game") {
        main_index = (main_index + 1) mod array_length(main_options);
    }

    if (k_up) {
        var max_loop_up = array_length(main_options);
        repeat (max_loop_up) {
            main_index = (main_index + array_length(main_options) - 1) mod array_length(main_options);
            if (load_available || main_options[main_index] != "Load Game") break;
        }
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        var max_loop_down = array_length(main_options);
        repeat (max_loop_down) {
            main_index = (main_index + 1) mod array_length(main_options);
            if (load_available || main_options[main_index] != "Load Game") break;
        }
        SFX_PlayUI("ui_move");
    }

    if (k_ok) {
        var opt = main_options[main_index];
        if (opt == "Load Game" && !load_available) {
            main_index = (main_index + 1) mod array_length(main_options);
            SFX_PlayUI("ui_move");
            return;
        }

        SFX_PlayUI("ui_confirm");
        if (opt == "New Game") {
            var current_difficulty = DIFFICULTY_NORMAL;
            if (variable_struct_exists(gs, "difficulty")) current_difficulty = Difficulty_Normalize(gs.difficulty);
            difficulty_index = 1;
            for (var di = 0; di < array_length(difficulty_values); di++) {
                if (difficulty_values[di] == current_difficulty) {
                    difficulty_index = di;
                    break;
                }
            }
            state = "difficulty";
        } else if (opt == "Load Game") {
            SaveMenu_Open("load", "main");
        } else if (opt == "Settings") {
            settings_index = 0;
            settings_dirty = false;
            settings_pending = GameSettings_Copy(GameSettings_Ensure());
            state = "settings";
        } else if (opt == "Exit Game") {
            game_end();
        }
    }
    return;
}

if (state == "difficulty") {
    if (k_up) {
        difficulty_index = (difficulty_index + array_length(difficulty_options) - 1) mod array_length(difficulty_options);
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        difficulty_index = (difficulty_index + 1) mod array_length(difficulty_options);
        SFX_PlayUI("ui_move");
    }

    if (k_back) {
        SFX_PlayUI("ui_back");
        state = "main";
        return;
    }

    if (k_ok) {
        SFX_PlayUI("ui_confirm");
        if (difficulty_index >= 0 && difficulty_index < array_length(difficulty_values)) {
            Difficulty_SetCurrent(difficulty_values[difficulty_index]);
        } else {
            Difficulty_SetCurrent(DIFFICULTY_NORMAL);
        }
        Transition_RequestCutsceneById("intro");
    }
    return;
}

if (state == "cutscene") {
    // Prevent cutscene re-initialization while exiting rm_cutscene to another room.
    // Keep processing only for internal cutscene segment flash transitions.
    if (Transition_IsInputLocked() && !cutscene_wait_transition) return;

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
    var settings_rows = SETTINGS_MENU_ROW_COUNT; // UI, SFX, BGM, Scale, Apply, Back

    if (k_up) {
        settings_index = (settings_index + settings_rows - 1) mod settings_rows;
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        settings_index = (settings_index + 1) mod settings_rows;
        SFX_PlayUI("ui_move");
    }

    if (settings_index == 5) {
        if (k_back || k_ok) {
            if (k_back) SFX_PlayUI("ui_back"); else SFX_PlayUI("ui_confirm");
            settings_pending = GameSettings_Copy(GameSettings_Ensure());
            settings_dirty = false;
            state = "main";
        }
        return;
    }

    if (k_back) {
        SFX_PlayUI("ui_back");
        settings_pending = GameSettings_Copy(GameSettings_Ensure());
        settings_dirty = false;
        state = "main";
        return;
    }

    var changed = false;
    var did_confirm = false;
    var pending = GameSettings_Copy(settings_pending);

    switch (settings_index) {
        case 0: // UI
            if (k_left) {
                pending.audio_ui = clamp(pending.audio_ui - settings_volume_step, 0, 1);
                changed = true;
            }
            if (k_right) {
                pending.audio_ui = clamp(pending.audio_ui + settings_volume_step, 0, 1);
                changed = true;
            }
            break;
        case 1: // SFX
            if (k_left) {
                pending.audio_sfx = clamp(pending.audio_sfx - settings_volume_step, 0, 1);
                changed = true;
            }
            if (k_right) {
                pending.audio_sfx = clamp(pending.audio_sfx + settings_volume_step, 0, 1);
                changed = true;
            }
            break;
        case 2: // BGM
            if (k_left) {
                pending.audio_bgm = clamp(pending.audio_bgm - settings_volume_step, 0, 1);
                changed = true;
            }
            if (k_right) {
                pending.audio_bgm = clamp(pending.audio_bgm + settings_volume_step, 0, 1);
                changed = true;
            }
            break;
        case 3: // Scale
            if (k_left) {
                pending.display_scale = clamp(pending.display_scale - 1, DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
                changed = true;
            }
            if (k_right) {
                pending.display_scale = clamp(pending.display_scale + 1, DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
                changed = true;
            }
            break;
        case 4:
            if (k_ok) {
                var committed = GameSettings_Commit(pending, true);
                settings_pending = GameSettings_Copy(committed);
                settings_dirty = false;
                SFX_PlayUI("ui_confirm");
                return;
            }
            break;
    }

    if (changed) {
        settings_pending = GameSettings_Copy(pending);
        settings_dirty = true;
        if (did_confirm) SFX_PlayUI("ui_confirm");
        else SFX_PlayUI("ui_move");
    }
    return;
}
