Input_PreStep();
var gs = GameState_Get();

if (gs.ui.mode == UI_SAVE) exit;
if (Transition_IsInputLocked()) return;

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
            Transition_RequestCutsceneById("intro");
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

if (state == "cutscene") {
    if (!cutscene_started) {
        cutscene_id = "";
        if (variable_struct_exists(gs, "pending_cutscene_id")) {
            cutscene_id = string(gs.pending_cutscene_id);
        }
        if (cutscene_id == "") cutscene_id = "intro";

        switch (cutscene_id) {
            case "intro":
                gs.ui.cutscene_active = true;
                gs.ui.cutscene_bg_sprite = intro_bg_sprite;
                gs.ui.dialogue_box_half = false;
                gs.ui.cutscene_text_only = true;
                Dialogue_Start(intro_dialogue_id);
                cutscene_started = true;
                break;
            case "ending":
                gs.ui.cutscene_active = true;
                gs.ui.cutscene_bg_sprite = ending_bg_sprite;
                gs.ui.dialogue_box_half = false;
                gs.ui.cutscene_text_only = true;
                Dialogue_Start(ending_dialogue_id);
                cutscene_started = true;
                break;
            default:
                Transition_RequestCutsceneFade(rm_start);
                break;
        }
        return;
    }

    if (gs.ui.mode != UI_DIALOGUE && array_length(gs.ui.lines) <= 0) {
        gs.ui.cutscene_active = false;
        gs.ui.cutscene_bg_sprite = noone;
        gs.ui.dialogue_box_half = false;
        gs.ui.cutscene_text_only = false;
        gs.pending_cutscene_id = "";

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
            default:
                Transition_RequestRoomFade(rm_start);
                break;
        }
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
