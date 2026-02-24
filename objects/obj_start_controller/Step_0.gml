Input_PreStep();
var gs = GameState_Get();

if (gs.ui.mode == UI_SAVE) exit;

var k_up = Input_UIRepeat("menu_up");
var k_down = Input_UIRepeat("menu_down");
var k_left = Input_UIPressed("menu_left");
var k_right = Input_UIPressed("menu_right");
var k_ok = Input_UIPressed("confirm");
var k_back = Input_UIPressed("cancel");

if (state == "main") {
    if (k_up) {
        main_index = (main_index + array_length(main_options) - 1) mod array_length(main_options);
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        main_index = (main_index + 1) mod array_length(main_options);
        SFX_PlayUI("ui_move");
    }

    if (k_ok) {
        SFX_PlayUI("ui_confirm");
        var opt = main_options[main_index];
        if (opt == "New Game") {
            state = "class";
        } else if (opt == "Load Game") {
            SaveMenu_Open("load", "main");
        } else if (opt == "Settings") {
            settings_index = 0;
            settings_col = 2;
            state = "settings";
        } else if (opt == "Exit Game") {
            game_end();
        }
    }
    return;
}

if (state == "class") {
    var total = array_length(choices) + 1; // +1 for Back
    if (k_up) {
        class_index = (class_index + total - 1) mod total;
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        class_index = (class_index + 1) mod total;
        SFX_PlayUI("ui_move");
    }

    if (k_back) {
        SFX_PlayUI("ui_back");
        state = "main";
        return;
    }

    if (k_ok) {
        SFX_PlayUI("ui_confirm");
        if (class_index == array_length(choices)) {
            state = "main";
            return;
        }
        var class_id = choice_ids[class_index];
        GameState_SetSelectedClass(class_id);

        // reset core state for new game
        if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_clear(gs.defeated_enemies);
        gs.room_states = {};
        gs.persist = {};
        gs.persist_applied = {};
        gs.uid_counter = 1;
        gs.enemy_reset_version = 0;
        gs.boss_defeated = { mini_boss: false, final_boss: false };

        gs.player_ch = CharacterCreate_Player(class_id);
        GameState_SetPlayer(gs.player_ch);

        gs.in_main_menu = false;
        RoomTransition_Set(rm_floor1, "start", -1);
        room_goto(rm_floor1);
    }
    return;
}

if (state == "settings") {
    var settings_rows = 6; // UI, SFX, BGM, Scale, Fullscreen, Back
    if (k_up) {
        settings_index = (settings_index + settings_rows - 1) mod settings_rows;
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        settings_index = (settings_index + 1) mod settings_rows;
        SFX_PlayUI("ui_move");
    }

    if (settings_index >= 5) settings_col = 1;
    else if (settings_col == 1) settings_col = 2;

    if (settings_index == 5) {
        if (k_back || k_ok) {
            if (k_back) SFX_PlayUI("ui_back"); else SFX_PlayUI("ui_confirm");
            state = "main";
        }
        return;
    }

    if (k_back) {
        SFX_PlayUI("ui_back");
        state = "main";
        return;
    }

    var changed = false;
    var did_confirm = false;
    var settings = GameSettings_Ensure();

    switch (settings_index) {
        case 0: // UI
            if (k_left) {
                GameSettings_SetUIVolume(settings.audio_ui - settings_volume_step);
                settings_col = 0;
                changed = true;
            }
            if (k_right) {
                GameSettings_SetUIVolume(settings.audio_ui + settings_volume_step);
                settings_col = 2;
                changed = true;
            }
            if (k_ok) {
                if (settings_col == 0) GameSettings_SetUIVolume(settings.audio_ui - settings_volume_step);
                else GameSettings_SetUIVolume(settings.audio_ui + settings_volume_step);
                changed = true;
                did_confirm = true;
            }
            break;
        case 1: // SFX
            if (k_left) {
                GameSettings_SetSFXVolume(settings.audio_sfx - settings_volume_step);
                settings_col = 0;
                changed = true;
            }
            if (k_right) {
                GameSettings_SetSFXVolume(settings.audio_sfx + settings_volume_step);
                settings_col = 2;
                changed = true;
            }
            if (k_ok) {
                if (settings_col == 0) GameSettings_SetSFXVolume(settings.audio_sfx - settings_volume_step);
                else GameSettings_SetSFXVolume(settings.audio_sfx + settings_volume_step);
                changed = true;
                did_confirm = true;
            }
            break;
        case 2: // BGM
            if (k_left) {
                GameSettings_SetBGMVolume(settings.audio_bgm - settings_volume_step);
                settings_col = 0;
                changed = true;
            }
            if (k_right) {
                GameSettings_SetBGMVolume(settings.audio_bgm + settings_volume_step);
                settings_col = 2;
                changed = true;
            }
            if (k_ok) {
                if (settings_col == 0) GameSettings_SetBGMVolume(settings.audio_bgm - settings_volume_step);
                else GameSettings_SetBGMVolume(settings.audio_bgm + settings_volume_step);
                changed = true;
                did_confirm = true;
            }
            break;
        case 3: // Scale
            if (k_left) {
                GameSettings_SetScale(settings.display_scale - 1);
                settings_col = 0;
                changed = true;
            }
            if (k_right) {
                GameSettings_SetScale(settings.display_scale + 1);
                settings_col = 2;
                changed = true;
            }
            if (k_ok) {
                if (settings_col == 0) GameSettings_SetScale(settings.display_scale - 1);
                else GameSettings_SetScale(settings.display_scale + 1);
                changed = true;
                did_confirm = true;
            }
            break;
        case 4: // Fullscreen
            if (k_left || k_right || k_ok) {
                GameSettings_ToggleFullscreen();
                settings_col = 1;
                changed = true;
                did_confirm = k_ok;
            }
            break;
    }

    if (changed) {
        if (did_confirm) SFX_PlayUI("ui_confirm");
        else SFX_PlayUI("ui_move");
    }
    return;
}
