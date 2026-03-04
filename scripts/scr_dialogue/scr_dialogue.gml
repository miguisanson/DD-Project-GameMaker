function DialogueDB_Init() {
    if (variable_global_exists("dialogue_db") && ds_exists(global.dialogue_db, ds_type_map)) return;
    global.dialogue_db = ds_map_create();

    // defaults
    global.dialogue_db[? "default"] = ["..."];
	
	// in-game dialogues
	global.dialogue_db[? "first_encounter_slime"] = ["What...", "...the hell is that?"];
	global.dialogue_db[? "entering_second_floor"] = 
	["I don't understand.", 
	"How can such creatures exist?",
	"Some sort of mutated animals...",
	"...Monsters?"];

    // system
    global.dialogue_db[? "sys_save_ok"] = ["Game saved."];
    global.dialogue_db[? "sys_load_ok"] = ["Game loaded."];
    global.dialogue_db[? "sys_load_missing"] = ["No save found."];
    global.dialogue_db[? "sys_class_chest_prompt"] = 
						["How convenient...", 
						"Just what I need to get out of this place."];
    global.dialogue_db[? "sys_floor1_intro"] = 
						["*Thud* *Crash*",
						"Wha... What just happened?",
						"Where am I?", 
						"...", 
						"I knew it. there's something wrong about this place.",
						"I need to get back."];
    global.dialogue_db[? "after_class_chest_knight"] = [
        "Heavy... but it fits.",
        "Like it's been mine for years.",
        "This chest shouldn't know me."
    ];
    global.dialogue_db[? "after_class_chest_archer"] = [
        "Light. Balanced.",
        "No rust. No wear.",
        "Like it was waiting here."
    ];
    global.dialogue_db[? "after_class_chest_mage"] = [
        "Why does it feel cold...?",
        "...Did something just whisper?",
        "No. That's not possible.",
        "Stop calling to me."
    ];
    global.dialogue_db[? "after_skillbook_chest_knight"] = [
        "Diagrams... simple forms.",
        "I read it once.",
        "Somehow... my hands already know."
    ];
    global.dialogue_db[? "after_skillbook_chest_archer"] = [
        "Angles and breath marks.",
        "I follow the first step...",
        "Then my body finishes it. Odd."
    ];
    global.dialogue_db[? "after_skillbook_chest_mage"] = [
        "I can't read this...",
        "...The page is filled with symbols.",
        "A voice folds into my thoughts.",
        "And I understand. It shows me where to place my hands."
    ];
    global.dialogue_db[? "sys_floor2_dire_wolf_reaction"] = [
        "*Pant*... Whew.",
        "Now a bloody wolf?",
        "Where did they come from?",
        "...",
        "I won't get any answers this way.",
        "Let's keep going."
    ];
    global.dialogue_db[? "sys_first_level_up_reaction"] = [
        "...",
        "I'm feeling a bit dizzy.",
        "I think I'm going to vomit...",
        "Why does my body feel sore?",
        "...",
        "...and different."
    ];
    global.dialogue_db[? "sys_first_equippable_item_reaction"] = [
        "This might come in handy.",
        "...",
        "How come there are so many treasures here?",
        "As if...",
        "...someone placed them here intentionally.",
        "But why?",
        "Why go the extra steps if their intentions were to have us killed?",
        "It's not making sense, and it's creeping me out."
    ];

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


    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.dialogue_db = global.dialogue_db;
    }
}

function DialogueDB_Get(_dialogue_id) {
    if (!variable_global_exists("dialogue_db") || !ds_exists(global.dialogue_db, ds_type_map)) {
        DialogueDB_Init();
    }
    var did = string(_dialogue_id);
    if (!ds_map_exists(global.dialogue_db, did)) {
        did = "default";
    }
    var lines = global.dialogue_db[? did];
    var localized = [];
    if (is_array(lines)) {
        for (var i = 0; i < array_length(lines); i++) {
            var fallback = string(lines[i]);
            array_push(localized, Loc_T("dialogue." + did + "." + string(i), fallback));
        }
    }
    var vars = { interact: Input_Label("interact"), confirm: Input_Label("confirm"), cancel: Input_Label("cancel") };
    return Dialogue_FormatLines(localized, vars);
}

function Dialogue_EventConfigEnsure() {
    if (variable_global_exists("dialogue_event_cfg") && is_struct(global.dialogue_event_cfg)) {
        return global.dialogue_event_cfg;
    }

    var class_chest_ids = array_create(CLASS_NOBODY + 1, "");
    class_chest_ids[CLASS_KNIGHT] = "after_class_chest_knight";
    class_chest_ids[CLASS_ARCHER] = "after_class_chest_archer";
    class_chest_ids[CLASS_MAGE] = "after_class_chest_mage";

    var skillbook_first_ids = array_create(CLASS_NOBODY + 1, "");
    skillbook_first_ids[CLASS_KNIGHT] = "after_skillbook_chest_knight";
    skillbook_first_ids[CLASS_ARCHER] = "after_skillbook_chest_archer";
    skillbook_first_ids[CLASS_MAGE] = "after_skillbook_chest_mage";

    global.dialogue_event_cfg = {
        class_chest_ids: class_chest_ids,
        class_chest_ambience_keys: [
            "", // archer
            "", // knight
            SKILLBOOK_MANA_AMBIENCE_KEY_3, // mage
            ""  // nobody
        ],
        skillbook_first_ids: skillbook_first_ids,
        skillbook_done_flag: "skillbook_first_read_done",
        skillbook_pending_flag: "skillbook_first_read_pending",
        skillbook_ui_active_key: "skillbook_mana_dialogue_active",
        dialogue_ambience_key: "dialogue_active_ambience_key",
        skillbook_ambience_sfx_key: SKILLBOOK_MANA_AMBIENCE_KEY,
        skillbook_ambience_sfx_keys: [
            SKILLBOOK_MANA_AMBIENCE_KEY_1,
            SKILLBOOK_MANA_AMBIENCE_KEY_2,
            SKILLBOOK_MANA_AMBIENCE_KEY_3
        ]
    };
    return global.dialogue_event_cfg;
}

function Dialogue_ClassEventId(_event_key, _class_id) {
    var cfg = Dialogue_EventConfigEnsure();
    if (!variable_struct_exists(cfg, _event_key)) return "";
    var table = variable_struct_get(cfg, _event_key);
    if (!is_array(table)) return "";
    var idx = round(real(_class_id));
    if (idx < 0 || idx >= array_length(table)) return "";
    return string(table[idx]);
}

function Dialogue_ClassChestId(_class_id) {
    return Dialogue_ClassEventId("class_chest_ids", _class_id);
}

function Dialogue_SkillbookFirstReadId(_class_id) {
    return Dialogue_ClassEventId("skillbook_first_ids", _class_id);
}

function Dialogue_SkillbookFirstReadDoneFlagKey() {
    var cfg = Dialogue_EventConfigEnsure();
    return variable_struct_exists(cfg, "skillbook_done_flag") ? string(cfg.skillbook_done_flag) : "skillbook_first_read_done";
}

function Dialogue_SkillbookFirstReadPendingFlagKey() {
    var cfg = Dialogue_EventConfigEnsure();
    return variable_struct_exists(cfg, "skillbook_pending_flag") ? string(cfg.skillbook_pending_flag) : "skillbook_first_read_pending";
}

function Dialogue_SkillbookFirstReadUIActiveKey() {
    var cfg = Dialogue_EventConfigEnsure();
    return variable_struct_exists(cfg, "skillbook_ui_active_key") ? string(cfg.skillbook_ui_active_key) : "skillbook_mana_dialogue_active";
}

function Dialogue_SkillbookAmbienceSfxKey() {
    var cfg = Dialogue_EventConfigEnsure();
    return variable_struct_exists(cfg, "skillbook_ambience_sfx_key") ? string(cfg.skillbook_ambience_sfx_key) : SKILLBOOK_MANA_AMBIENCE_KEY;
}

function Dialogue_SkillbookAmbienceSfxKeys() {
    var cfg = Dialogue_EventConfigEnsure();
    if (variable_struct_exists(cfg, "skillbook_ambience_sfx_keys") && is_array(cfg.skillbook_ambience_sfx_keys) && array_length(cfg.skillbook_ambience_sfx_keys) > 0) {
        return cfg.skillbook_ambience_sfx_keys;
    }
    return [Dialogue_SkillbookAmbienceSfxKey()];
}

function Dialogue_PickSkillbookAmbienceSfxKey() {
    return SKILLBOOK_MANA_AMBIENCE_KEY_1;
}

function Dialogue_ActiveAmbienceUIKey() {
    var cfg = Dialogue_EventConfigEnsure();
    return variable_struct_exists(cfg, "dialogue_ambience_key") ? string(cfg.dialogue_ambience_key) : "dialogue_active_ambience_key";
}

function Dialogue_SetActiveAmbienceSfxKey(_sfx_key = "") {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) gs.ui = {};
    variable_struct_set(gs.ui, Dialogue_ActiveAmbienceUIKey(), string(_sfx_key));
}

function Dialogue_GetActiveAmbienceSfxKey() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) return "";
    var key = Dialogue_ActiveAmbienceUIKey();
    if (!variable_struct_exists(gs.ui, key)) return "";
    return string(variable_struct_get(gs.ui, key));
}

function Dialogue_ClassChestAmbienceSfxKey(_class_id) {
    return Dialogue_ClassEventId("class_chest_ambience_keys", _class_id);
}

function Dialogue_SetSkillbookFirstReadUIActive(_active) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) gs.ui = {};
    variable_struct_set(gs.ui, Dialogue_SkillbookFirstReadUIActiveKey(), _active);
}

function Dialogue_IsSkillbookFirstReadUIActive() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) return false;
    var key = Dialogue_SkillbookFirstReadUIActiveKey();
    if (!variable_struct_exists(gs.ui, key)) return false;
    return variable_struct_get(gs.ui, key);
}

function Dialogue_TryStartClassChestReaction(_class_id) {
    var did = Dialogue_ClassChestId(_class_id);
    if (did == "") return false;
    Dialogue_Start(did);
    Dialogue_SetActiveAmbienceSfxKey(Dialogue_ClassChestAmbienceSfxKey(_class_id));
    return true;
}

function Dialogue_SkillbookFirstReadDone() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) return false;
    var key = Dialogue_SkillbookFirstReadDoneFlagKey();
    if (!variable_struct_exists(gs.flags, key)) return false;
    return variable_struct_get(gs.flags, key);
}

function Dialogue_SkillbookFirstReadPending() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) return false;
    var key = Dialogue_SkillbookFirstReadPendingFlagKey();
    if (!variable_struct_exists(gs.flags, key)) return false;
    return variable_struct_get(gs.flags, key);
}

function Dialogue_SkillbookFirstReadShouldTrigger(_class_id) {
    if (Dialogue_SkillbookFirstReadId(_class_id) == "") return false;
    if (Dialogue_SkillbookFirstReadDone()) return false;
    if (Dialogue_SkillbookFirstReadPending()) return false;
    return true;
}

function Dialogue_SkillbookFirstReadMarkDone() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    variable_struct_set(gs.flags, Dialogue_SkillbookFirstReadDoneFlagKey(), true);
    variable_struct_set(gs.flags, Dialogue_SkillbookFirstReadPendingFlagKey(), false);
    Dialogue_SetSkillbookFirstReadUIActive(false);
    Dialogue_SetActiveAmbienceSfxKey("");
}

function Dialogue_TryStartSkillbookFirstRead(_class_id) {
    if (!Dialogue_SkillbookFirstReadShouldTrigger(_class_id)) return false;
    var did = Dialogue_SkillbookFirstReadId(_class_id);
    if (did == "") return false;

    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    variable_struct_set(gs.flags, Dialogue_SkillbookFirstReadPendingFlagKey(), true);
    Dialogue_SetSkillbookFirstReadUIActive(true);

    Dialogue_Start(did);
    Dialogue_SetActiveAmbienceSfxKey(Dialogue_PickSkillbookAmbienceSfxKey());
    return true;
}

function Dialogue_NarrativeDoneFlagKey(_event_id) {
    return "narrative_event_done_" + string(_event_id);
}

function Dialogue_NarrativePendingFlagKey(_event_id) {
    return "narrative_event_pending_" + string(_event_id);
}

function Dialogue_NarrativeDialogueId(_event_id) {
    var eid = string(_event_id);
    switch (eid) {
        case "floor2_dire_wolf_reaction":
            return "sys_floor2_dire_wolf_reaction";
        case "first_level_up_reaction":
            return "sys_first_level_up_reaction";
        case "first_equippable_item_reaction":
            return "sys_first_equippable_item_reaction";
    }
    return "";
}

function Dialogue_NarrativeAmbienceSfxKey(_event_id) {
    if (string(_event_id) == "first_level_up_reaction") {
        return Dialogue_PickSkillbookAmbienceSfxKey();
    }
    return "";
}

function Dialogue_NarrativeEnsureFlags() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    return gs.flags;
}

function Dialogue_NarrativeIsDone(_event_id) {
    var flags = Dialogue_NarrativeEnsureFlags();
    var key = Dialogue_NarrativeDoneFlagKey(_event_id);
    if (!variable_struct_exists(flags, key)) return false;
    return variable_struct_get(flags, key);
}

function Dialogue_NarrativeIsPending(_event_id) {
    var flags = Dialogue_NarrativeEnsureFlags();
    var key = Dialogue_NarrativePendingFlagKey(_event_id);
    if (!variable_struct_exists(flags, key)) return false;
    return variable_struct_get(flags, key);
}

function Dialogue_NarrativeSetPending(_event_id, _pending) {
    var flags = Dialogue_NarrativeEnsureFlags();
    variable_struct_set(flags, Dialogue_NarrativePendingFlagKey(_event_id), _pending);
}

function Dialogue_NarrativeMarkDone(_event_id) {
    var flags = Dialogue_NarrativeEnsureFlags();
    variable_struct_set(flags, Dialogue_NarrativeDoneFlagKey(_event_id), true);
    variable_struct_set(flags, Dialogue_NarrativePendingFlagKey(_event_id), false);
}

function Dialogue_NarrativeQueueOnce(_event_id) {
    if (Dialogue_NarrativeIsDone(_event_id)) return false;
    if (Dialogue_NarrativeIsPending(_event_id)) return false;
    Dialogue_NarrativeSetPending(_event_id, true);
    return true;
}

function Dialogue_NarrativeOnEnemyDefeated(_enemy_id, _enemy_room) {
    if (_enemy_id == ENEMY_DIREWOLF && _enemy_room == rm_floor2) {
        return Dialogue_NarrativeQueueOnce("floor2_dire_wolf_reaction");
    }
    return false;
}

function Dialogue_NarrativeOnLevelUp(_levels_gained) {
    var gained = max(0, round(real(_levels_gained)));
    if (gained <= 0) return false;
    return Dialogue_NarrativeQueueOnce("first_level_up_reaction");
}

function Dialogue_NarrativeOnLootGranted(_loot) {
    if (!is_array(_loot) || array_length(_loot) <= 0) return false;
    if (Dialogue_NarrativeIsDone("first_equippable_item_reaction")) return false;
    if (Dialogue_NarrativeIsPending("first_equippable_item_reaction")) return false;

    for (var i = 0; i < array_length(_loot); i++) {
        var it = _loot[i];
        if (!is_struct(it) || !variable_struct_exists(it, "item_id")) continue;
        var qty = variable_struct_exists(it, "qty") ? max(0, round(real(it.qty))) : 1;
        if (qty <= 0) continue;
        var item = ItemDB_Get(it.item_id);
        if (!is_struct(item) || !variable_struct_exists(item, "type")) continue;
        if (item.type == ITEM_WEAPON || item.type == ITEM_ARMOR) {
            return Dialogue_NarrativeQueueOnce("first_equippable_item_reaction");
        }
    }

    return false;
}

function Dialogue_NarrativeCanStartNow() {
    if (room == rm_battle) return false;
    if (Transition_IsActive()) return false;

    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) return false;
    if (gs.ui.mode != UI_NONE) return false;
    if (variable_struct_exists(gs.ui, "lines") && is_array(gs.ui.lines) && array_length(gs.ui.lines) > 0) return false;

    var pl = noone;
    if (variable_struct_exists(gs, "player_inst") && instance_exists(gs.player_inst)) pl = gs.player_inst;
    else if (instance_exists(obj_player)) pl = instance_find(obj_player, 0);
    if (!instance_exists(pl)) return false;
    if (!Player_IsSettled(pl)) return false;
    return true;
}

function Dialogue_NarrativeTryStartPending() {
    if (!Dialogue_NarrativeCanStartNow()) return false;

    var order = [
        "floor2_dire_wolf_reaction",
        "first_level_up_reaction",
        "first_equippable_item_reaction"
    ];

    for (var i = 0; i < array_length(order); i++) {
        var event_id = order[i];
        if (!Dialogue_NarrativeIsPending(event_id)) continue;

        var did = Dialogue_NarrativeDialogueId(event_id);
        if (did == "") {
            Dialogue_NarrativeMarkDone(event_id);
            continue;
        }

        var lines = DialogueDB_Get(did);
        if (!is_array(lines) || array_length(lines) <= 0) {
            Dialogue_NarrativeMarkDone(event_id);
            continue;
        }

        Dialogue_StartLines(lines);
        var ambience_key = Dialogue_NarrativeAmbienceSfxKey(event_id);
        if (ambience_key != "") {
            Dialogue_SetActiveAmbienceSfxKey(ambience_key);
        }
        Dialogue_NarrativeMarkDone(event_id);
        return true;
    }

    return false;
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

function Dialogue_IsCutsceneTextOnly() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) return false;
    if (!variable_struct_exists(gs.ui, "cutscene_text_only")) return false;
    return gs.ui.cutscene_text_only;
}

function Dialogue_CopyLineEntryWithText(_line_entry, _text) {
    if (is_struct(_line_entry)) {
        var out = {};
        var names = variable_struct_get_names(_line_entry);
        for (var i = 0; i < array_length(names); i++) {
            var nm = names[i];
            variable_struct_set(out, nm, variable_struct_get(_line_entry, nm));
        }
        variable_struct_set(out, "text", _text);
        return out;
    }
    return _text;
}

function Dialogue_BoxRect() {
    var gs = GameState_Get();
    var w = display_get_gui_width();
    var h = display_get_gui_height();

    var margin = UI_DIALOGUE_BOX_MARGIN;
    var bx = margin;
    var by = h - UI_DIALOGUE_BOX_HEIGHT - margin;
    var bw = w - margin * 2;
    var bh = UI_DIALOGUE_BOX_HEIGHT;

    if (variable_struct_exists(gs.ui, "dialogue_box_half") && gs.ui.dialogue_box_half) {
        bx = 0;
        bw = w;
        var min_h = max(1, UI_CUTSCENE_DIALOGUE_MIN_HEIGHT);
        by = floor(h * UI_CUTSCENE_DIALOGUE_TOP_RATIO);
        by = clamp(by, 0, max(0, h - min_h));
        bh = h - by;
    }

    return {
        x: bx,
        y: by,
        w: bw,
        h: bh
    };
}

function Dialogue_TextLayout(_speaker) {
    UI_SetFont();
    var line_h = max(8, string_height("Ag"));
    var has_speaker = (string(_speaker) != "");
    var cutscene_text_only = Dialogue_IsCutsceneTextOnly();

    var box = Dialogue_BoxRect();
    var text_x = box.x + UI_DIALOGUE_TEXT_PAD_X;
    var text_y = box.y + (has_speaker ? UI_DIALOGUE_TEXT_Y_WITH_SPEAKER : UI_DIALOGUE_TEXT_PAD_Y);
    var text_w = max(1, box.w - (UI_DIALOGUE_TEXT_PAD_X * 2));
    var speaker_x = box.x + UI_DIALOGUE_TEXT_PAD_X;
    var speaker_y = box.y + UI_DIALOGUE_SPEAKER_Y;
    var text_h = max(line_h, box.h - (text_y - box.y) - UI_DIALOGUE_BOTTOM_PAD);

    if (cutscene_text_only) {
        var w = display_get_gui_width();
        var h = display_get_gui_height();
        var margin_ratio = clamp(UI_CUTSCENE_TEXT_SIDE_PAD_RATIO, 0, 0.45);
        var margin_x = max(max(0, UI_CUTSCENE_TEXT_MARGIN_X), floor(w * margin_ratio));
        var region_top = floor(h * UI_CUTSCENE_TEXT_TOP_RATIO);
        var region_bottom = h - max(0, UI_CUTSCENE_TEXT_BOTTOM_PAD);
        if (region_bottom <= region_top) {
            region_bottom = min(h, region_top + line_h);
        }

        box = {
            x: margin_x,
            y: region_top,
            w: max(1, w - margin_x * 2),
            h: max(1, region_bottom - region_top)
        };

        speaker_x = box.x;
        speaker_y = box.y;
        text_x = box.x;
        text_w = box.w;
        if (has_speaker) {
            text_y = box.y + line_h + 2;
        } else {
            text_y = box.y;
        }
        text_h = max(line_h, box.h - (text_y - box.y));
    }

    var max_lines = max(1, floor(text_h / line_h));

    return {
        box: box,
        text_x: text_x,
        text_y: text_y,
        text_w: text_w,
        speaker_x: speaker_x,
        speaker_y: speaker_y,
        line_h: line_h,
        max_lines: max_lines,
        has_speaker: has_speaker,
        cutscene_text_only: cutscene_text_only
    };
}

function Dialogue_BreakWordToLines(_word, _max_w) {
    var out = [];
    var max_w = max(1, _max_w);
    var word = string(_word);
    var len = string_length(word);
    if (len <= 0) {
        array_push(out, "");
        return out;
    }

    var chunk = "";
    for (var i = 1; i <= len; i++) {
        var ch = string_char_at(word, i);
        var test = chunk + ch;
        if (chunk == "" || string_width(test) <= max_w) {
            chunk = test;
        } else {
            array_push(out, chunk);
            chunk = ch;
        }
    }
    if (chunk != "") array_push(out, chunk);
    if (array_length(out) <= 0) array_push(out, word);
    return out;
}

function Dialogue_WrapToLines(_text, _max_w) {
    var src = string_replace_all(string(_text), "\r", "");
    var max_w = max(1, _max_w);
    var paragraphs = string_split(src, "\n");
    var out = [];

    if (!is_array(paragraphs) || array_length(paragraphs) <= 0) {
        array_push(out, src);
        return out;
    }

    for (var p = 0; p < array_length(paragraphs); p++) {
        var para = string(paragraphs[p]);

        if (para == "") {
            array_push(out, "");
            continue;
        }

        var words = string_split(para, " ");
        var line = "";

        for (var w = 0; w < array_length(words); w++) {
            var word = string(words[w]);
            if (word == "") continue;

            if (line == "") {
                if (string_width(word) <= max_w) {
                    line = word;
                } else {
                    var split_head = Dialogue_BreakWordToLines(word, max_w);
                    for (var sh = 0; sh < array_length(split_head) - 1; sh++) {
                        array_push(out, split_head[sh]);
                    }
                    line = split_head[array_length(split_head) - 1];
                }
            } else {
                var candidate = line + " " + word;
                if (string_width(candidate) <= max_w) {
                    line = candidate;
                } else {
                    array_push(out, line);
                    if (string_width(word) <= max_w) {
                        line = word;
                    } else {
                        var split_tail = Dialogue_BreakWordToLines(word, max_w);
                        for (var st = 0; st < array_length(split_tail) - 1; st++) {
                            array_push(out, split_tail[st]);
                        }
                        line = split_tail[array_length(split_tail) - 1];
                    }
                }
            }
        }

        if (line != "") array_push(out, line);
    }

    if (array_length(out) <= 0) array_push(out, "");
    return out;
}

function Dialogue_PaginateLineEntry(_line_entry, _max_w, _max_lines) {
    var page_line_limit = max(1, _max_lines);
    var wrapped = Dialogue_WrapToLines(Dialogue_LineText(_line_entry), _max_w);
    var pages = [];

    if (!is_array(wrapped) || array_length(wrapped) <= 0) {
        array_push(pages, Dialogue_CopyLineEntryWithText(_line_entry, ""));
        return pages;
    }

    var idx = 0;
    while (idx < array_length(wrapped)) {
        var page_text = "";
        var lines_added = 0;
        while (idx < array_length(wrapped) && lines_added < page_line_limit) {
            var wrapped_line = wrapped[idx];
            if (lines_added == 0) page_text = wrapped_line;
            else page_text += "\n" + wrapped_line;
            lines_added += 1;
            idx += 1;
        }
        array_push(pages, Dialogue_CopyLineEntryWithText(_line_entry, page_text));
    }

    if (array_length(pages) <= 0) array_push(pages, Dialogue_CopyLineEntryWithText(_line_entry, ""));
    return pages;
}

function Dialogue_RebuildPagedLines() {
    var gs = GameState_Get();
    if (!is_array(gs.ui.lines_raw)) {
        if (is_array(gs.ui.lines)) gs.ui.lines_raw = gs.ui.lines;
        else gs.ui.lines_raw = [];
    }

    var speaker = variable_struct_exists(gs.ui, "speaker") ? string(gs.ui.speaker) : "";
    var layout = Dialogue_TextLayout(speaker);

    var paged = [];
    for (var i = 0; i < array_length(gs.ui.lines_raw); i++) {
        var line_entry = gs.ui.lines_raw[i];
        var pages = Dialogue_PaginateLineEntry(line_entry, layout.text_w, layout.max_lines);
        for (var p = 0; p < array_length(pages); p++) {
            array_push(paged, pages[p]);
        }
    }

    if (array_length(paged) <= 0) {
        array_push(paged, "");
    }

    gs.ui.lines = paged;
    gs.ui.dialogue_layout_text_w = layout.text_w;
    gs.ui.dialogue_layout_max_lines = layout.max_lines;
    gs.ui.dialogue_layout_has_speaker = layout.has_speaker;
    gs.ui.dialogue_layout_box_y = layout.box.y;
    gs.ui.dialogue_layout_box_h = layout.box.h;
}

function Dialogue_EnsurePagedLinesCurrent() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;

    var speaker = variable_struct_exists(gs.ui, "speaker") ? string(gs.ui.speaker) : "";
    var layout = Dialogue_TextLayout(speaker);
    var needs_rebuild = false;

    if (!is_array(gs.ui.lines_raw)) needs_rebuild = true;
    if (!is_array(gs.ui.lines)) needs_rebuild = true;
    if (!variable_struct_exists(gs.ui, "dialogue_layout_text_w") || gs.ui.dialogue_layout_text_w != layout.text_w) needs_rebuild = true;
    if (!variable_struct_exists(gs.ui, "dialogue_layout_max_lines") || gs.ui.dialogue_layout_max_lines != layout.max_lines) needs_rebuild = true;
    if (!variable_struct_exists(gs.ui, "dialogue_layout_has_speaker") || gs.ui.dialogue_layout_has_speaker != layout.has_speaker) needs_rebuild = true;
    if (!variable_struct_exists(gs.ui, "dialogue_layout_box_y") || gs.ui.dialogue_layout_box_y != layout.box.y) needs_rebuild = true;
    if (!variable_struct_exists(gs.ui, "dialogue_layout_box_h") || gs.ui.dialogue_layout_box_h != layout.box.h) needs_rebuild = true;

    if (needs_rebuild) {
        var prev_index = gs.ui.index;
        Dialogue_RebuildPagedLines();
        if (array_length(gs.ui.lines) <= 0) gs.ui.index = 0;
        else gs.ui.index = clamp(prev_index, 0, array_length(gs.ui.lines) - 1);
        Dialogue_ResetTypewriter();
    }
}

function Dialogue_TypewriterPrepareCurrentLine() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;
    Dialogue_EnsurePagedLinesCurrent();
    if (!is_array(gs.ui.lines) || array_length(gs.ui.lines) <= 0) return;
    if (gs.ui.index < 0 || gs.ui.index >= array_length(gs.ui.lines)) return;

    var game_fps = max(1, game_get_speed(gamespeed_fps));
    var chars_per_sec = UI_DIALOGUE_CHARS_PER_SEC;
    if (Dialogue_IsCutsceneTextOnly()) {
        chars_per_sec = UI_CUTSCENE_DIALOGUE_CHARS_PER_SEC;
        if (variable_struct_exists(gs.ui, "cutscene_chars_per_sec")) {
            var cutscene_cps = real(gs.ui.cutscene_chars_per_sec);
            if (cutscene_cps > 0) chars_per_sec = cutscene_cps;
        }
    }
    gs.ui.dialogue_chars_per_sec = max(1, chars_per_sec);
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

function Dialogue_Start(_dialogue_id) {
    if (PauseMenu_IsOpen()) PauseMenu_Close();
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = "";
    gs.ui.lines_raw = DialogueDB_Get(_dialogue_id);
    gs.ui.lines = [];
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    Dialogue_SetActiveAmbienceSfxKey("");
    if (!variable_struct_exists(gs.ui, "cutscene_active") || !gs.ui.cutscene_active) {
        gs.ui.cutscene_text_only = false;
    }
    gs.ui.opened_frame = Input_Frame();
    var open_block_frames = Dialogue_IsCutsceneTextOnly() ? max(0, UI_CUTSCENE_ADVANCE_BLOCK_FRAMES) : 0;
    gs.ui.dialogue_open_block_frame = gs.ui.opened_frame + open_block_frames;
    gs.ui.confirm_action = "confirm";
    Dialogue_RebuildPagedLines();
    Dialogue_ResetTypewriter();
    SFX_Play("dialogue_open");
}

function Dialogue_StartLines(_lines) {
    if (PauseMenu_IsOpen()) PauseMenu_Close();
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = "";
    gs.ui.lines_raw = is_array(_lines) ? _lines : [];
    gs.ui.lines = [];
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    Dialogue_SetActiveAmbienceSfxKey("");
    if (!variable_struct_exists(gs.ui, "cutscene_active") || !gs.ui.cutscene_active) {
        gs.ui.cutscene_text_only = false;
    }
    gs.ui.opened_frame = Input_Frame();
    var open_block_frames = Dialogue_IsCutsceneTextOnly() ? max(0, UI_CUTSCENE_ADVANCE_BLOCK_FRAMES) : 0;
    gs.ui.dialogue_open_block_frame = gs.ui.opened_frame + open_block_frames;
    gs.ui.confirm_action = "confirm";
    Dialogue_RebuildPagedLines();
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

function DialogueDB_GetFormatted(_dialogue_id, _vars) {
    var lines = DialogueDB_Get(_dialogue_id);
    return Dialogue_FormatLines(lines, _vars);
}

function Dialogue_StartWithSpeaker(_speaker, _lines) {
    if (PauseMenu_IsOpen()) PauseMenu_Close();
    Dialogue_EnsureUI();
    var gs = GameState_Get();
    gs.ui.speaker = _speaker;
    gs.ui.lines_raw = is_array(_lines) ? _lines : [];
    gs.ui.lines = [];
    gs.ui.index = 0;
    gs.ui.mode = UI_DIALOGUE;
    Dialogue_SetActiveAmbienceSfxKey("");
    if (!variable_struct_exists(gs.ui, "cutscene_active") || !gs.ui.cutscene_active) {
        gs.ui.cutscene_text_only = false;
    }
    gs.ui.opened_frame = Input_Frame();
    var open_block_frames = Dialogue_IsCutsceneTextOnly() ? max(0, UI_CUTSCENE_ADVANCE_BLOCK_FRAMES) : 0;
    gs.ui.dialogue_open_block_frame = gs.ui.opened_frame + open_block_frames;
    gs.ui.confirm_action = "confirm";
    Dialogue_RebuildPagedLines();
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
    if (Dialogue_IsCutsceneTextOnly()) {
        gs.ui.dialogue_open_block_frame = Input_Frame() + max(0, UI_CUTSCENE_ADVANCE_BLOCK_FRAMES);
    }

    if (gs.ui.index < array_length(gs.ui.lines)) {
        SFX_Play("dialogue_advance");
        Dialogue_TypewriterPrepareCurrentLine();
        return;
    }

    if (gs.ui.index >= array_length(gs.ui.lines)) {
        SFX_Play("dialogue_close");
        gs.ui.mode = UI_NONE;
        gs.ui.lines = [];
        gs.ui.lines_raw = [];
        gs.ui.index = 0;
        gs.ui.speaker = "";
        gs.ui.confirm_action = "";
        gs.ui.dialogue_open_block_frame = UI_OPENED_FRAME_NONE;
        gs.ui.dialogue_lock = UI_DIALOGUE_REOPEN_LOCK;
        gs.ui.dialogue_require_release = true;
        Dialogue_SetActiveAmbienceSfxKey("");
        if (Dialogue_IsSkillbookFirstReadUIActive()) {
            Dialogue_SkillbookFirstReadMarkDone();
        }
        if (!variable_struct_exists(gs.ui, "cutscene_active") || !gs.ui.cutscene_active) {
            gs.ui.cutscene_text_only = false;
        }
    }
}
