function DialogueDB_Init() {
    if (variable_global_exists("dialogue_db") && ds_exists(global.dialogue_db, ds_type_map)) return;
    global.dialogue_db = ds_map_create();

    global.dialogue_db[? NPC_OLD_MAN] = [
        "Welcome to the dungeon.",
        "Stay alert—monsters lurk nearby.",
        "Press Z to interact."
    ];

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.dialogue_db = global.dialogue_db;
    }
}

function DialogueDB_Get(_npc_id) {
    if (ds_exists(global.dialogue_db, ds_type_map) && ds_map_exists(global.dialogue_db, _npc_id)) {
        return global.dialogue_db[? _npc_id];
    }
    return ["..."];
}

function Dialogue_Start(_npc_id) {
    var gs = GameState_Get();
    gs.ui.lines = DialogueDB_Get(_npc_id);
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
}

function Dialogue_StartLines(_lines) {
    var gs = GameState_Get();
    gs.ui.lines = _lines;
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
}

function Dialogue_Advance() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;
    gs.ui.index += 1;
    if (gs.ui.index >= array_length(gs.ui.lines)) {
        gs.ui.mode = UI_NONE;
        gs.ui.lines = [];
        gs.ui.index = 0;
    }
}
