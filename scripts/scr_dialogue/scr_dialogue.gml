function DialogueDB_Init() {
    if (variable_global_exists("dialogue_db") && ds_exists(global.dialogue_db, ds_type_map)) return;
    global.dialogue_db = ds_map_create();

    // defaults
    global.dialogue_db[? "default"] = ["..."];

    // system
    global.dialogue_db[? "sys_save_ok"] = ["Game saved."];
    global.dialogue_db[? "sys_load_ok"] = ["Game loaded."];
    global.dialogue_db[? "sys_load_missing"] = ["No save found."];

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

    global.dialogue_db[? "loot_empty"] = ["It's empty."];

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

function Dialogue_Start(_npc_id) {
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = "";
    gs.ui.lines = DialogueDB_Get(_npc_id);
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    gs.ui.just_opened = true;
    gs.ui.confirm_action = "confirm";
}

function Dialogue_StartLines(_lines) {
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = "";
    gs.ui.lines = _lines;
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    gs.ui.just_opened = true;
    gs.ui.confirm_action = "confirm";
}

function Dialogue_FormatLines(_lines, _vars) {
    if (!is_array(_lines)) return [];
    if (!is_struct(_vars)) return _lines;

    var keys = variable_struct_get_names(_vars);
    var out = array_create(array_length(_lines));
    for (var i = 0; i < array_length(_lines); i++) {
        var s = _lines[i];
        for (var k = 0; k < array_length(keys); k++) {
            var key = keys[k];
            s = string_replace_all(s, "{" + key + "}", string(variable_struct_get(_vars, key)));
        }
        out[i] = s;
    }
    return out;
}

function DialogueDB_GetFormatted(_npc_id, _vars) {
    var lines = DialogueDB_Get(_npc_id);
    return Dialogue_FormatLines(lines, _vars);
}

function Dialogue_StartWithSpeaker(_speaker, _lines) {
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = _speaker;
    gs.ui.lines = _lines;
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    gs.ui.just_opened = true;
    gs.ui.confirm_action = "confirm";
}

function Dialogue_StartLinesWithSpeaker(_speaker, _lines) {
    Dialogue_StartWithSpeaker(_speaker, _lines);
}

function Dialogue_Advance() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;
    gs.ui.just_opened = false;
    gs.ui.index += 1;
    if (gs.ui.index >= array_length(gs.ui.lines)) {
        gs.ui.mode = UI_NONE;
        gs.ui.lines = [];
        gs.ui.index = 0;
        gs.ui.speaker = "";
        gs.ui.confirm_action = "";
        if (variable_struct_exists(gs.ui, "lock_actions")) gs.ui.lock_actions = 2;
    }
}
