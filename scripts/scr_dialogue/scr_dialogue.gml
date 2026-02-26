function DialogueDB_Init() {
    if (variable_global_exists("dialogue_db") && ds_exists(global.dialogue_db, ds_type_map)) return;
    global.dialogue_db = ds_map_create();

    // defaults
    global.dialogue_db[? "default"] = ["..."];

    // system
    global.dialogue_db[? "sys_save_ok"] = ["Game saved."];
    global.dialogue_db[? "sys_load_ok"] = ["Game loaded."];
    global.dialogue_db[? "sys_load_missing"] = ["No save found."];
    global.dialogue_db[? "sys_intro_cutscene"] = [
        "You ventured deep in a tunnel heading towards a neighboring enemy castle... The plan was to ambush using this shortcut",
        "You are just a porter for this raid party",
        "You knew this was a mistake",
        "You are from here, this place never existed before...",
        "You just knew the ground ground was weak and unsupported",
        "But it was already too late to speak up",
        "You fell down."
    ];
    global.dialogue_db[? "sys_floor1_intro"] = ["Where am I?... I knew it there's something wrong with this place."];

    // interactables
    global.dialogue_db[? "tree"] = ["A sturdy tree."];
    global.dialogue_db[? "tree_stump"] = ["A cut tree stump."];
    global.dialogue_db[? "tall_grass"] = ["It rustles in the wind."];
    global.dialogue_db[? "rock"] = ["Just a rock."];
    global.dialogue_db[? "skull"] = ["A cracked skull."];
    global.dialogue_db[? "horned_skull"] = ["It stares back at you."];
    global.dialogue_db[? "bone"] = ["A pile of old bones."];
    global.dialogue_db[? "dung_pile"] = ["Better not touch that."];

    global.dialogue_db[? "barrel_break"] = ["You smash the barrel."];
    global.dialogue_db[? "barrel_broken"] = ["It's broken."];

    global.dialogue_db[? "chest_open"] = ["You open the chest."];
    global.dialogue_db[? "chest_empty"] = ["It's empty."];
    global.dialogue_db[? "loot_received"] = ["Received {item} x{qty}."];

    global.dialogue_db[? "loot_empty"] = ["Nothing was found."];

    global.dialogue_db[? "fire_stand_extinguish"] = ["You extinguish the flame."];
    global.dialogue_db[? "fire_stand_off"] = ["The flame is out."];

    global.dialogue_db[? "torch_extinguish"] = ["You extinguish the torch."];
    global.dialogue_db[? "torch_off"] = ["The torch is cold."];

    global.dialogue_db[? NPC_OLD_MAN] = [
        "Welcome to the dungeon.",
        "Stay alert—monsters lurk nearby.",
        "Press {interact} to interact."
    ];

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.dialogue_db = global.dialogue_db;
    }
}

function DialogueDB_Get(_npc_id) {
    if (!variable_global_exists("dialogue_db") || !ds_exists(global.dialogue_db, ds_type_map)) {
        DialogueDB_Init();
    }
    if (!ds_map_exists(global.dialogue_db, _npc_id)) {
        _npc_id = "default";
    }
    var lines = global.dialogue_db[? _npc_id];
    var vars = { interact: Input_Label("interact"), confirm: Input_Label("confirm"), cancel: Input_Label("cancel") };
    return Dialogue_FormatLines(lines, vars);
}


function Dialogue_EnsureUI() {
    if (!instance_exists(obj_ui_controller)) {
        if (!layer_exists("Instances")) {
            layer_create(0, "Instances");
        }
        instance_create_layer(0, 0, "Instances", obj_ui_controller);
    }
}

function Dialogue_ResetTypewriter() {
    var gs = GameState_Get();
    gs.ui.dialogue_tw_line_index = -1;
    gs.ui.dialogue_full_text = "";
    gs.ui.dialogue_visible_count = 0;
    gs.ui.dialogue_reveal_accum = 0;
    gs.ui.dialogue_state = UI_DIALOGUE_STATE_REVEALING;
    gs.ui.dialogue_hold_frames = 0;
}

function Dialogue_LineText(_line_entry) {
    if (is_struct(_line_entry) && variable_struct_exists(_line_entry, "text")) {
        return string(_line_entry.text);
    }
    return string(_line_entry);
}

function Dialogue_TypewriterPrepareCurrentLine() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;
    if (!is_array(gs.ui.lines) || array_length(gs.ui.lines) <= 0) return;
    if (gs.ui.index < 0 || gs.ui.index >= array_length(gs.ui.lines)) return;

    var game_fps = max(1, game_get_speed(gamespeed_fps));
    gs.ui.dialogue_chars_per_sec = max(1, UI_DIALOGUE_CHARS_PER_SEC);
    gs.ui.dialogue_hold_duration = max(1, round(UI_DIALOGUE_ADVANCE_HOLD_SEC * game_fps));

    var line_text = Dialogue_LineText(gs.ui.lines[gs.ui.index]);
    var line_changed = (!variable_struct_exists(gs.ui, "dialogue_tw_line_index") || gs.ui.dialogue_tw_line_index != gs.ui.index
        || !variable_struct_exists(gs.ui, "dialogue_full_text") || gs.ui.dialogue_full_text != line_text);
    if (line_changed) {
        gs.ui.dialogue_full_text = line_text;
        gs.ui.dialogue_visible_count = 0;
        gs.ui.dialogue_reveal_accum = 0;
        gs.ui.dialogue_state = UI_DIALOGUE_STATE_REVEALING;
        gs.ui.dialogue_hold_frames = gs.ui.dialogue_hold_duration;
        gs.ui.dialogue_tw_line_index = gs.ui.index;
    }

    var max_len = string_length(gs.ui.dialogue_full_text);
    gs.ui.dialogue_visible_count = clamp(gs.ui.dialogue_visible_count, 0, max_len);
}

function Dialogue_TypewriterStep() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;

    Dialogue_TypewriterPrepareCurrentLine();

    var full_text = gs.ui.dialogue_full_text;
    var full_len = string_length(full_text);
    var game_fps = max(1, game_get_speed(gamespeed_fps));

    if (gs.ui.dialogue_state == UI_DIALOGUE_STATE_REVEALING) {
        gs.ui.dialogue_reveal_accum += (gs.ui.dialogue_chars_per_sec / game_fps);
        while (gs.ui.dialogue_reveal_accum >= 1 && gs.ui.dialogue_visible_count < full_len) {
            gs.ui.dialogue_visible_count += 1;
            gs.ui.dialogue_reveal_accum -= 1;
        }
        if (gs.ui.dialogue_visible_count >= full_len) {
            gs.ui.dialogue_visible_count = full_len;
            gs.ui.dialogue_reveal_accum = 0;
            gs.ui.dialogue_state = UI_DIALOGUE_STATE_HOLDING;
            gs.ui.dialogue_hold_frames = gs.ui.dialogue_hold_duration;
        }
    } else if (gs.ui.dialogue_state == UI_DIALOGUE_STATE_HOLDING) {
        gs.ui.dialogue_hold_frames -= 1;
        if (gs.ui.dialogue_hold_frames <= 0) {
            gs.ui.dialogue_hold_frames = 0;
            gs.ui.dialogue_state = UI_DIALOGUE_STATE_READY;
        }
    }
}

function Dialogue_TypewriterRevealInstant() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;
    Dialogue_TypewriterPrepareCurrentLine();
    var full_len = string_length(gs.ui.dialogue_full_text);
    gs.ui.dialogue_visible_count = full_len;
    gs.ui.dialogue_reveal_accum = 0;
    gs.ui.dialogue_state = UI_DIALOGUE_STATE_HOLDING;
    gs.ui.dialogue_hold_frames = gs.ui.dialogue_hold_duration;
}

function Dialogue_Start(_npc_id) {
    if (PauseMenu_IsOpen()) PauseMenu_Close();
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = "";
    gs.ui.lines = DialogueDB_Get(_npc_id);
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    gs.ui.opened_frame = Input_Frame();
    gs.ui.dialogue_open_block_frame = gs.ui.opened_frame;
    gs.ui.confirm_action = "confirm";
    Dialogue_ResetTypewriter();
    SFX_Play("dialogue_open");
}

function Dialogue_StartLines(_lines) {
    if (PauseMenu_IsOpen()) PauseMenu_Close();
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = "";
    gs.ui.lines = _lines;
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    gs.ui.opened_frame = Input_Frame();
    gs.ui.dialogue_open_block_frame = gs.ui.opened_frame;
    gs.ui.confirm_action = "confirm";
    Dialogue_ResetTypewriter();
    SFX_Play("dialogue_open");
}

function Dialogue_FormatLines(_lines, _vars) {
    if (!is_array(_lines)) return [];
    if (!is_struct(_vars)) return _lines;

    var keys = variable_struct_get_names(_vars);
    var out = array_create(array_length(_lines));
    for (var i = 0; i < array_length(_lines); i++) {
        var line = _lines[i];
        if (is_struct(line)) {
            var copy = {};
            var names = variable_struct_get_names(line);
            for (var n = 0; n < array_length(names); n++) {
                var nm = names[n];
                variable_struct_set(copy, nm, variable_struct_get(line, nm));
            }
            var t = "";
            if (variable_struct_exists(copy, "text")) t = string(copy.text);
            for (var k0 = 0; k0 < array_length(keys); k0++) {
                var key0 = keys[k0];
                t = string_replace_all(t, "{" + key0 + "}", string(variable_struct_get(_vars, key0)));
            }
            variable_struct_set(copy, "text", t);
            out[i] = copy;
        } else {
            var s = string(line);
            for (var k = 0; k < array_length(keys); k++) {
                var key = keys[k];
                s = string_replace_all(s, "{" + key + "}", string(variable_struct_get(_vars, key)));
            }
            out[i] = s;
        }
    }
    return out;
}

function DialogueDB_GetFormatted(_npc_id, _vars) {
    var lines = DialogueDB_Get(_npc_id);
    return Dialogue_FormatLines(lines, _vars);
}

function Dialogue_StartWithSpeaker(_speaker, _lines) {
    if (PauseMenu_IsOpen()) PauseMenu_Close();
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = _speaker;
    gs.ui.lines = _lines;
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    gs.ui.opened_frame = Input_Frame();
    gs.ui.dialogue_open_block_frame = gs.ui.opened_frame;
    gs.ui.confirm_action = "confirm";
    Dialogue_ResetTypewriter();
    SFX_Play("dialogue_open");
}

function Dialogue_StartLinesWithSpeaker(_speaker, _lines) {
    Dialogue_StartWithSpeaker(_speaker, _lines);
}

function Dialogue_Advance() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;

    var frame = Input_Frame();
    if (variable_struct_exists(gs.ui, "dialogue_open_block_frame") && frame <= gs.ui.dialogue_open_block_frame) return;

    Dialogue_TypewriterPrepareCurrentLine();
    if (gs.ui.dialogue_state == UI_DIALOGUE_STATE_REVEALING) {
        SFX_Play("dialogue_advance");
        Dialogue_TypewriterRevealInstant();
        return;
    }
    if (gs.ui.dialogue_state == UI_DIALOGUE_STATE_HOLDING) {
        return;
    }

    gs.ui.opened_frame = UI_OPENED_FRAME_NONE;
    gs.ui.index += 1;
    Dialogue_ResetTypewriter();

    if (gs.ui.index < array_length(gs.ui.lines)) {
        SFX_Play("dialogue_advance");
        Dialogue_TypewriterPrepareCurrentLine();
        return;
    }

    if (gs.ui.index >= array_length(gs.ui.lines)) {
        SFX_Play("dialogue_close");
        gs.ui.mode = UI_NONE;
        gs.ui.lines = [];
        gs.ui.index = 0;
        gs.ui.speaker = "";
        gs.ui.confirm_action = "";
        gs.ui.dialogue_open_block_frame = UI_OPENED_FRAME_NONE;
        gs.ui.dialogue_lock = UI_DIALOGUE_REOPEN_LOCK;
        gs.ui.dialogue_require_release = true;
    }
}
