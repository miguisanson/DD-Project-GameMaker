function DialogueDB_Init() {
    if (variable_global_exists("dialogue_db") && ds_exists(global.dialogue_db, ds_type_map)) return;
    global.dialogue_db = ds_map_create();

    // defaults
    global.dialogue_db[? "default"] = ["..."];
	
	// in-game dialogues
	global.dialogue_db[? "first_encounter_slime"] = ["What...", "...the hell is that?"];
	global.dialogue_db[? "first_encounter_mini_boss"] = [
	"...",
	"Oh, what the hell is that?",
	"Some sort of half-cow, half-man?",
	"This is insane...",
	"And he's blocking my only path forward.",
	"...",
	"Fuck."
	];
    global.dialogue_db[? "first_encounter_final_boss"] = [
        "...",
        "Another demon.",
        "This one seems different.",
        "As if it's looking for something...",
        "...",
        "...someone."
    ];
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
						"I knew it. There's something wrong about this place.",
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
    global.dialogue_db[? "sys_first_stranger_encounter_reaction"] = [
        "Get your hands off me...",
        "I can't believe such demons exist.",
        "Are these demons?",
        "I can only assume they are.",
        "...",
        "I have to move."
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
    global.dialogue_db[? "sys_final_boss_defeated_reaction"] = [
        "*Huff*... *Wheeze*... Fuck.",
        "...",
        "I did it.",
        "...",
        "Still...",
        "Nothing makes sense.",
        "Am I the only one experiencing this?",
        "Fuck. Who cares. The exit is here.",
        "I'll be able to regroup with the others and find a way home."
    ];
    global.dialogue_db[? "sys_floor9_5_exit_reaction"] = [
        "...",
        "(You start to see vivid colors.)",
        "(Black tendrils appear and disappear from your vision.)",
        "(You snap back to reality.)",
        "Huh?",
        "...",
        "My head...",
        "It's about to burst...",
        "(You clutch your head while walking toward the exit.)"
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
    var vars = { interact: Prompt_Text("interact"), confirm: Prompt_Text("confirm"), cancel: Prompt_Text("cancel") };   // D92: the last-used device's label
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

function Dialogue_SkillbookFirstReadMarkDone() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    variable_struct_set(gs.flags, Dialogue_SkillbookFirstReadDoneFlagKey(), true);
    variable_struct_set(gs.flags, Dialogue_SkillbookFirstReadPendingFlagKey(), false);
    Dialogue_SetSkillbookFirstReadUIActive(false);
    Dialogue_SetActiveAmbienceSfxKey("");
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
        case "first_stranger_encounter_reaction":
            return "sys_first_stranger_encounter_reaction";
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

function Dialogue_NarrativeOnStrangerEncounterResolved() {
    return Dialogue_NarrativeQueueOnce("first_stranger_encounter_reaction");
}

function Dialogue_NarrativeOnEnemyDefeated(_enemy_id, _enemy_room) {
    if (_enemy_id == ENEMY_STRANGER) {
        return Dialogue_NarrativeOnStrangerEncounterResolved();
    }
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
        "first_stranger_encounter_reaction",
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
    var mt = Ui_Metrics();
    var w = mt.gw;
    var h = mt.gh;
    // D101: the shared frame (1p light edge + 1p dark band + 2p of air on every side) round three lines of text
    var box_h = 8 * mt.p + 3 * mt.line_h;
    var bx = mt.margin;
    var by = h - box_h - mt.margin;
    var bw = w - mt.margin * 2;
    var bh = box_h;

    if (variable_struct_exists(gs.ui, "dialogue_box_half") && gs.ui.dialogue_box_half) {
        bx = 0;
        bw = w;
        var min_h = max(1, round(UI_CUTSCENE_DIALOGUE_MIN_HEIGHT * UI_GetVisualScale()));
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

// D108 F1d-2: how often the text layout is built (Dialogue_TextLayoutBuilds), so a check can see it run once per change.
function Dialogue_TextLayoutBuilds() {
    return variable_global_exists("dialogue_layout_builds") ? global.dialogue_layout_builds : 0;
}

function Dialogue_TextLayout(_speaker) {
    return Dialogue_TextLayoutBuild(_speaker);
}

// The uncached computation of Dialogue_TextLayout. Counted (Dialogue_TextLayoutBuilds).
function Dialogue_TextLayoutBuild(_speaker) {
    if (!variable_global_exists("dialogue_layout_builds")) global.dialogue_layout_builds = 0;
    global.dialogue_layout_builds++;
    UI_SetFont();
    var mt = Ui_Metrics();
    var line_h = max(8, UI_TextHeight("Ag"));
    var has_speaker = (string(_speaker) != "");
    var cutscene_text_only = Dialogue_IsCutsceneTextOnly();
    var ui_visual = UI_GetVisualScale();

    // The speaker's name sits on a tab above the frame (Ui_DrawNameTab), so the text starts at the same place with or without one.
    var box = Dialogue_BoxRect();
    var text_x = box.x + 4 * mt.p;
    var text_y = box.y + 4 * mt.p;
    var text_w = max(1, box.w - 14 * mt.p);   // 4p of frame and air on the left, 10p on the right: the blinking arrow lives there
    var speaker_x = box.x + 4 * mt.p;
    var speaker_y = box.y;
    var text_h = max(line_h, box.h - 8 * mt.p);

    if (cutscene_text_only) {
        var w = Display_GuiW();
        var h = Display_GuiH();
        var margin_ratio = clamp(UI_CUTSCENE_TEXT_SIDE_PAD_RATIO, 0, 0.45);
        var margin_x = max(max(0, round(UI_CUTSCENE_TEXT_MARGIN_X * ui_visual)), floor(w * margin_ratio));
        var region_top = floor(h * UI_CUTSCENE_TEXT_TOP_RATIO);
        var region_bottom = h - max(0, round(UI_CUTSCENE_TEXT_BOTTOM_PAD * ui_visual));
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
        if (chunk == "" || UI_TextWidth(test) <= max_w) {
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
                if (UI_TextWidth(word) <= max_w) {
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
                if (UI_TextWidth(candidate) <= max_w) {
                    line = candidate;
                } else {
                    array_push(out, line);
                    if (UI_TextWidth(word) <= max_w) {
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
    gs.ui.dialogue_chars_per_sec = max(1, chars_per_sec * Settings_TextSpeedMul(GameSettings_Ensure().text_speed));   // D0: the Text speed setting
    gs.ui.dialogue_hold_duration = max(1, round((Dialogue_IsCutsceneTextOnly() ? UI_DIALOGUE_ADVANCE_HOLD_SEC : UI_DIALOGUE_BOX_HOLD_SEC) * game_fps));   // D101: a boxed line is ready almost at once

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
    gs.ui.dialogue_open_ms = current_time;   // D97: the box slides in
    gs.ui.choice = undefined;
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
    gs.ui.dialogue_open_ms = current_time;   // D97: the box slides in
    gs.ui.choice = undefined;
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
    gs.ui.dialogue_open_ms = current_time;   // D97: the box slides in
    gs.ui.choice = undefined;
    gs.ui.opened_frame = Input_Frame();
    var open_block_frames = Dialogue_IsCutsceneTextOnly() ? max(0, UI_CUTSCENE_ADVANCE_BLOCK_FRAMES) : 0;
    gs.ui.dialogue_open_block_frame = gs.ui.opened_frame + open_block_frames;
    gs.ui.confirm_action = "confirm";
    Dialogue_RebuildPagedLines();
    Dialogue_ResetTypewriter();
    SFX_Play("dialogue_open");
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
        if (is_struct(Dialogue_Choice())) {   // D101: the last line is read, the choices open above the box
            gs.ui.index = max(0, array_length(gs.ui.lines) - 1);
            Dialogue_ChoiceOpen();
            return;
        }
        Dialogue_CloseNow();
    }
}

// Closes the dialogue that is open, as if its last line had just been confirmed (the end of Dialogue_Advance; also hold-to-skip, D48).
function Dialogue_CloseNow() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_DIALOGUE) return;
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
    gs.ui.choice = undefined;
    Dialogue_SetActiveAmbienceSfxKey("");
    if (Dialogue_IsSkillbookFirstReadUIActive()) {
        Dialogue_SkillbookFirstReadMarkDone();
    }
    if (!variable_struct_exists(gs.ui, "cutscene_active") || !gs.ui.cutscene_active) {
        gs.ui.cutscene_text_only = false;
    }
}


// ---- D101: the dialogue box. The shared frame with a speaker name tab, the typewriter text, a blinking arrow when a line is complete, and
// choices as a small menu of the shared kind above the box. Dialogue_Start* opens it; confirm completes the line, then moves on. ----
// _choices = the labels; _on_pick(index) runs after the box closes (Back picks the last choice when _allow_back).
function Dialogue_StartChoice(_speaker, _lines, _choices, _on_pick, _allow_back = false) {
    if (string(_speaker) != "") Dialogue_StartWithSpeaker(_speaker, _lines);
    else Dialogue_StartLines(_lines);
    GameState_Get().ui.choice = { labels: _choices, on_pick: _on_pick, menu: undefined, allow_back: _allow_back };
}

function Dialogue_Choice() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "choice")) return undefined;
    return is_struct(gs.ui.choice) ? gs.ui.choice : undefined;
}

function Dialogue_ChoiceIsOpen() {
    var ch = Dialogue_Choice();
    return is_struct(ch) && is_struct(ch.menu);
}

function Dialogue_ChoiceItems(_ch) {
    var items = [];
    for (var i = 0; i < array_length(_ch.labels); i++) array_push(items, { label: string(_ch.labels[i]), enabled: true });
    return items;
}

function Dialogue_ChoiceOpen() {
    var ch = Dialogue_Choice();
    if (!is_struct(ch)) return;
    var box = Dialogue_BoxRect();
    var mt = Ui_Metrics();
    var m = Ui_MenuNew("dialogue_choice", Dialogue_ChoiceItems(ch), {
        on_confirm: Dialogue_ChoicePick, on_back: ch.allow_back ? Dialogue_ChoiceBack : undefined,
        layout: { x_anchor: "right", y_bottom: box.y - mt.p * 2 }
    });
    Ui_MenuFixCursor(m, 0);   // a new question starts on its first answer (the shared memory is for the fixed menus)
    ch.menu = m;
    SFX_PlayUI("ui_openclose");
}

function Dialogue_ChoicePick(_m, _i) {
    var ch = Dialogue_Choice();
    var cb = is_struct(ch) ? ch.on_pick : undefined;
    Dialogue_CloseNow();
    if (is_callable(cb)) cb(_i);
}

function Dialogue_ChoiceBack(_m, _res) {
    Dialogue_ChoicePick(_m, array_length(_m.items) - 1);
}

// One frame of the open choice menu (obj_ui_controller Step calls it instead of Dialogue_Advance while it is up).
function Dialogue_ChoiceStep() {
    var ch = Dialogue_Choice();
    if (is_struct(ch) && is_struct(ch.menu)) Ui_MenuUpdate(ch.menu);
}

// A 5 x 3 arrow pointing down, cells _p x _p, top-left at (_x, _y).
function Dialogue_DrawArrowDown(_x, _y, _p, _col) {
    Ui_Box(_x, _y, _x + 5 * _p, _y + _p, _col);
    Ui_Box(_x + _p, _y + _p, _x + 4 * _p, _y + 2 * _p, _col);
    Ui_Box(_x + 2 * _p, _y + 2 * _p, _x + 3 * _p, _y + 3 * _p, _col);
}

function Dialogue_Draw() {
    var gs = GameState_Get();
    if (!(gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0)) return;
    UI_SetFont();
    var mt = Ui_Metrics();
    var p = mt.p;
    var box = Dialogue_BoxRect();
    var cutscene_text_only = Dialogue_IsCutsceneTextOnly();

    var line = "";
    var line_entry = "";
    var line_icon_sprite = noone;
    var line_icon_subimg = 0;
    if (array_length(gs.ui.lines) > 0 && gs.ui.index >= 0 && gs.ui.index < array_length(gs.ui.lines)) {
        line_entry = gs.ui.lines[gs.ui.index];
        line = Dialogue_LineText(line_entry);
        if (is_struct(line_entry) && variable_struct_exists(line_entry, "icon_sprite")) line_icon_sprite = line_entry.icon_sprite;
        if (is_struct(line_entry) && variable_struct_exists(line_entry, "icon_subimg")) line_icon_subimg = round(line_entry.icon_subimg);
    }
    var speaker = variable_struct_exists(gs.ui, "speaker") ? gs.ui.speaker : "";
    var layout = Dialogue_TextLayout(speaker);

    // D97: the framed box slides up into place in three pixel steps and fades in
    var open_t = variable_struct_exists(gs.ui, "dialogue_open_ms") ? Ui_AnimT(gs.ui.dialogue_open_ms, current_time) : 1;
    var rise = cutscene_text_only ? 0 : p * round((1 - open_t) * 3);

    if (!cutscene_text_only) {
        Ui_DrawFrame(box.x, box.y + rise, box.w, box.h, open_t, p);
        if (speaker != "") Ui_DrawNameTab(box.x, box.y + rise, speaker, open_t);
    }

    var icon_draw_w = 0;
    var icon_scale = max(1, floor(mt.line_h / 16));
    var icon_gap = 2 * p;
    if (line_icon_sprite != noone && line_icon_sprite != -1) {
        line_icon_subimg = clamp(line_icon_subimg, 0, max(0, sprite_get_number(line_icon_sprite) - 1));
        icon_draw_w = max(round(10 * icon_scale), round(sprite_get_width(line_icon_sprite) * icon_scale)) + icon_gap;
    }
    var text_x = layout.text_x + icon_draw_w;
    var text_y = layout.text_y + rise;

    Dialogue_TypewriterPrepareCurrentLine();
    var page_text = variable_struct_exists(gs.ui, "dialogue_full_text") ? gs.ui.dialogue_full_text : line;
    var visible_count = variable_struct_exists(gs.ui, "dialogue_visible_count") ? gs.ui.dialogue_visible_count : string_length(page_text);
    var visible_text = string_copy(page_text, 1, clamp(visible_count, 0, string_length(page_text)));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    if (cutscene_text_only) {   // over the cutscene's art: plain text with a 1 px shadow, as before
        if (speaker != "") {
            draw_set_color(c_black);
            UI_DrawText(layout.speaker_x + UI_CUTSCENE_TEXT_SHADOW_X, layout.speaker_y + UI_CUTSCENE_TEXT_SHADOW_Y, speaker + ":");
            draw_set_color(c_white);
            UI_DrawText(layout.speaker_x, layout.speaker_y, speaker + ":");
        }
        if (icon_draw_w > 0) draw_sprite_ext(line_icon_sprite, line_icon_subimg, layout.text_x, text_y + 1, icon_scale, icon_scale, 0, c_white, 1);
        draw_set_color(c_black);
        UI_DrawText(text_x + UI_CUTSCENE_TEXT_SHADOW_X, text_y + UI_CUTSCENE_TEXT_SHADOW_Y, visible_text);
        draw_set_color(c_white);
        UI_DrawText(text_x, text_y, visible_text);
    } else {
        var a0 = draw_get_alpha();
        draw_set_alpha(open_t);
        if (icon_draw_w > 0) draw_sprite_ext(line_icon_sprite, line_icon_subimg, layout.text_x, text_y + 1, icon_scale, icon_scale, 0, c_white, open_t);
        draw_set_color(UI_C_TEXT);
        UI_DrawText(text_x, text_y, visible_text);
        draw_set_alpha(a0);
    }

    // the blinking arrow: the line is complete and the player may go on (not while a choice is up)
    if (gs.ui.mode == UI_DIALOGUE && array_length(gs.ui.lines) > 0 && !Dialogue_ChoiceIsOpen()
    && variable_struct_exists(gs.ui, "dialogue_state") && gs.ui.dialogue_state == UI_DIALOGUE_STATE_READY) {
        var blink = (floor(gs.ui.icon_frame) mod 2);
        if (cutscene_text_only) {
            draw_set_color(c_white);
            Dialogue_DrawArrowDown(round(layout.box.x + layout.box.w - 6 * p), round(layout.box.y + layout.box.h - 4 * p + (blink ? 0 : p)), p, c_white);
        } else {
            Dialogue_DrawArrowDown(box.x + box.w - 10 * p, box.y + rise + box.h - 8 * p + (blink ? 0 : p), p, UI_C_LIGHTEST);
        }
    }

    var ch = Dialogue_Choice();
    if (is_struct(ch) && is_struct(ch.menu)) Ui_MenuDraw(ch.menu, Ui_MenuAlpha(ch.menu, current_time));
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ============================================================================
// C5 STORY (D102-D107, D40, D105): death lines, the wake line, the boss banner, lore notes, the closing text and the credits.
// Every player-facing string goes through Loc_T (keys in game_text.xlsx); the English text written here is the fallback and what
// Test_Suite_Story reads. Everything below is plain code in this script: no new objects, rooms or sprites.
// ============================================================================

// ---- death lines (D102-D104) ----
// The tunnel keeps pulling you back, and the lines get darker the more often it does. Tiers by death count: 1 = the first, 2 = the 2nd
// and 3rd, 3 = 4th-6th, 4 = 7th-10th, 5 = 11th on. Early on a killer-specific line can come up; from the 7th death on the tone is set.
// None of them may hint at what is outside (D104).
function DeathLine_Tier(_deaths) {
    if (_deaths <= 1) return 1;
    if (_deaths <= 3) return 2;
    if (_deaths <= 6) return 3;
    if (_deaths <= 10) return 4;
    return 5;
}

function DeathLine_Defs() {
    if (variable_global_exists("death_line_defs") && is_struct(global.death_line_defs)) return global.death_line_defs;
    global.death_line_defs = {
        tiers: [
            [   // 1st death: shock, still sure it is the end
                { key: "death.t1.0", text: "The dark takes you. Quietly." },
                { key: "death.t1.1", text: "So this is how it ends." },
                { key: "death.t1.2", text: "The floor gives way beneath you." }
            ],
            [   // 2nd-3rd: disbelief
                { key: "death.t2.0", text: "You were sure that was the end." },
                { key: "death.t2.1", text: "The tunnel is not finished with you." },
                { key: "death.t2.2", text: "Cold stone. A fall. Again." }
            ],
            [   // 4th-6th: it becomes a habit
                { key: "death.t3.0", text: "You know this fall by heart now." },
                { key: "death.t3.1", text: "How many times has it been?" },
                { key: "death.t3.2", text: "Dying is starting to feel like routine." }
            ],
            [   // 7th-10th: numb
                { key: "death.t4.0", text: "You stopped counting. The walls didn't." },
                { key: "death.t4.1", text: "{killer}. You don't even flinch anymore." },
                { key: "death.t4.2", text: "Nobody is coming. Nobody ever did." }
            ],
            [   // 11th on: the tunnel has become the safe place
                { key: "death.t5.0", text: "Even wanting to leave has gone quiet." },
                { key: "death.t5.1", text: "{killer}. Of course it was." },
                { key: "death.t5.2", text: "Down here, at least, you know what to expect." }
            ]
        ],
        killers: [
            { killer: "enemy_slime", key: "death.killer.enemy_slime", text: "A slime. You were beaten by a slime." },
            { killer: "enemy_direwolf", key: "death.killer.enemy_direwolf", text: "The wolf was faster than your fear." },
            { killer: "enemy_ghostsword", key: "death.killer.enemy_ghostsword", text: "A blade with no hand to hold it." },
            { killer: "enemy_spider", key: "death.killer.enemy_spider", text: "Eight eyes. The last thing you saw." },
            { killer: "enemy_madwhisp", key: "death.killer.enemy_madwhisp", text: "The glow led you here. It always does." },
            { killer: "enemy_snake", key: "death.killer.enemy_snake", text: "A hiss. Then nothing." },
            { killer: "enemy_killer_plant", key: "death.killer.enemy_killer_plant", text: "Even the plants here want you gone." },
            { killer: "enemy_stranger", key: "death.killer.enemy_stranger", text: "The stranger smiled the whole time." },
            { killer: "enemy_mini_boss", key: "death.killer.enemy_mini_boss", text: "{killer} did not even slow down." },
            { killer: "enemy_final_boss", key: "death.killer.enemy_final_boss", text: "The choir sings. You were its last note." },
            { killer: "status_poison", key: "death.killer.status_poison", text: "The poison finished what the fight began." },
            { killer: "status_burn", key: "death.killer.status_burn", text: "The fire was warm, at least." },
            { killer: "status_bleed", key: "death.killer.status_bleed", text: "You bled out, counting the drops." },
            { killer: "abandoned", key: "death.killer.abandoned", text: "You let go. The tunnel did not mind." }
        ]
    };
    return global.death_line_defs;
}

function DeathLine_All() {
    var defs = DeathLine_Defs();
    var out = [];
    for (var t = 0; t < array_length(defs.tiers); t++) {
        for (var i = 0; i < array_length(defs.tiers[t]); i++) array_push(out, defs.tiers[t][i]);
    }
    for (var k = 0; k < array_length(defs.killers); k++) array_push(out, defs.killers[k]);
    return out;
}

function DeathLine_KillerLine(_killer) {
    var defs = DeathLine_Defs();
    for (var k = 0; k < array_length(defs.killers); k++) {
        if (defs.killers[k].killer == _killer) return defs.killers[k];
    }
    return undefined;
}

// The lines that can play for this death count and killer. Tiers 1-3 start with the killer's own line when there is one;
// a "{killer}" line needs a killer to name (not for an abandoned run).
function DeathLine_Pool(_deaths, _killer) {
    var defs = DeathLine_Defs();
    var tier = DeathLine_Tier(_deaths);
    var out = [];
    if (tier <= 3) {
        var own = DeathLine_KillerLine(_killer);
        if (is_struct(own)) array_push(out, own);
    }
    var named = (_killer != "" && _killer != "abandoned");
    var gen = defs.tiers[tier - 1];
    for (var i = 0; i < array_length(gen); i++) {
        if (!named && string_pos("{killer}", gen[i].text) > 0) continue;
        array_push(out, gen[i]);
    }
    return out;
}

// One line for this death: { key, text (English), tier }. _salt rotates through the pool (the caller passes the run seed plus the death count).
function DeathLine_Pick(_deaths, _killer, _salt) {
    var pool = DeathLine_Pool(_deaths, _killer);
    var n = array_length(pool);
    var line = pool[(n > 0) ? (abs(floor(_salt)) mod n) : 0];
    return { key: line.key, text: line.text, tier: DeathLine_Tier(_deaths) };
}

// The line as the player reads it: the translation when there is one, {killer} filled with the name of what killed you.
function DeathLine_Format(_pick, _killer_name) {
    var nm = (_killer_name != "") ? _killer_name : Loc_T("death.killer.unknown_name", "Something");
    return Loc_T(_pick.key, _pick.text, { killer: nm });
}

// How long the line stays up: 2 s at least, 4 s at most, longer for longer lines (D103).
function DeathScene_Frames(_text, _fps) {
    return clamp(round(_fps * (1.4 + string_length(_text) * 0.05)), _fps * 2, _fps * 4);
}

// The wake line when the next run starts at the tunnel entrance (D102): one per tone, the last two tiers share one.
function WakeLine_Pick(_deaths) {
    var tier = min(DeathLine_Tier(_deaths), 4);
    switch (tier) {
        case 1: return { key: "wake.t1", text: "You wake where you first fell. Alive." };
        case 2: return { key: "wake.t2", text: "The same stone. The same cold. You wake again." };
        case 3: return { key: "wake.t3", text: "You wake at the entrance. It almost feels like home." };
    }
    return { key: "wake.t4", text: "You wake. You no longer ask why." };
}

// ---- who killed you (read when the death hook fires, D103) ----
// A poison / burn / bleed tick that takes the player's last HP calls this (scr_status); Death_KillerKey reads and clears it.
function Death_NoteDotKill(_status_id) {
    global.death_dot_kill = _status_id;
}

// "enemy_slime" ... for the enemy of the last battle, "status_poison" / "status_burn" / "status_bleed" for a tick that finished you,
// "abandoned" for giving up the run, "" when unknown. Reads and clears the status note.
function Death_KillerKey(_result = "died") {
    var dot = variable_global_exists("death_dot_kill") ? global.death_dot_kill : -1;
    global.death_dot_kill = -1;
    if (_result == "abandoned") return "abandoned";
    if (dot == STATUS_POISON) return "status_poison";
    if (dot == STATUS_BURN) return "status_burn";
    if (dot == STATUS_BLEED) return "status_bleed";
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "battle") && is_struct(gs.battle) && variable_struct_exists(gs.battle, "enemy_id") && gs.battle.enemy_id >= 0) {
        var k = Enemy_LocalizationKey(gs.battle.enemy_id);
        if (k != "unknown") return k;
    }
    return "";
}

// Everything the death scene needs, decided once when the run ends (the profile's death count already includes this death).
function Death_BuildContext(_result, _cause_name) {
    var deaths = max(1, Profile_Get().deaths);
    var run = Run_Get();
    var salt = (is_struct(run) ? run.seed : 0) + deaths;
    var killer = Death_KillerKey(_result);
    var pick = DeathLine_Pick(deaths, killer, salt);
    var text = DeathLine_Format(pick, _cause_name);
    return { deaths: deaths, killer: killer, pick: pick, text: text, frames: DeathScene_Frames(text, max(1, game_get_speed(gamespeed_fps))) };
}

// ---- the boss name banner (D106) ----
// A boss whose camera pan was already seen on an earlier run gets a ~1 s name banner instead of the pan.
function Banner_Frames(_fps) {
    return round(_fps * 1.0);
}

// 0 -> 1 -> 0 over _dur frames: a fifth of the time to fade in, a fifth to fade out, full in between.
function Banner_Alpha(_t, _dur) {
    if (_dur <= 0) return 0;
    var fade = max(1, round(_dur * 0.2));
    return clamp(min(_t / fade, (_dur - _t) / fade), 0, 1);
}

function Banner_Show(_text) {
    global.banner = { text: string(_text), t: 0, dur: Banner_Frames(max(1, game_get_speed(gamespeed_fps))) };
}

function Banner_Active() {
    return variable_global_exists("banner") && is_struct(global.banner) && global.banner.t < global.banner.dur;
}

function Banner_Step() {
    if (Banner_Active()) global.banner.t += 1;
}

// Drawn last-but-one by obj_ui_controller (Draw GUI): a framed name in the upper third, on the shared UI kit.
function Banner_Draw() {
    if (!Banner_Active()) return;
    var b = global.banner;
    var a = Banner_Alpha(b.t, b.dur);
    if (a <= 0) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var tw = UI_TextWidth(b.text);
    var w = tw + 16 * p;
    var h = mt.line_h + 8 * p;
    var bx = round((mt.gw - w) / 2);
    var by = round(mt.gh * 0.22);
    var a0 = draw_get_alpha();
    var c0 = draw_get_color();
    Ui_DrawFrame(bx, by, w, h, a, p);
    draw_set_alpha(a);
    Ui_Text(bx + 8 * p, by + 4 * p, b.text, UI_C_LIGHTEST);
    draw_set_alpha(a0);
    draw_set_color(c0);
}

// The boss a story trigger's camera pan points at ("" when it is not a boss pan): the display name for the banner.
function DialogueTrigger_BannerName(_tr) {
    if (!instance_exists(_tr)) return "";
    if (!variable_instance_exists(_tr, "camera_focus_enabled") || !_tr.camera_focus_enabled) return "";
    if (!variable_instance_exists(_tr, "camera_focus_object")) return "";
    var eid = -1;
    if (_tr.camera_focus_object == obj_mini_boss) eid = ENEMY_MINI_BOSS;
    else if (_tr.camera_focus_object == obj_final_boss) eid = ENEMY_FINAL_BOSS;
    if (eid < 0) return "";
    return string(EnemyDB_Get(eid).name);
}

// obj_dialogue_trigger Collision: the trigger was played on an earlier run (story_prev_seen), so show the banner once per visit to the room.
function DialogueTrigger_TryBanner(_tr) {
    if (!variable_instance_exists(_tr, "story_prev_seen") || !_tr.story_prev_seen) return false;
    if (variable_instance_exists(_tr, "banner_done") && _tr.banner_done) return false;
    var nm = DialogueTrigger_BannerName(_tr);
    if (nm == "") return false;
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "boss_defeated") && is_struct(gs.boss_defeated)) {   // beaten in this run: nothing to announce
        if (_tr.camera_focus_object == obj_mini_boss && gs.boss_defeated.mini_boss) return false;
        if (_tr.camera_focus_object == obj_final_boss && gs.boss_defeated.final_boss) return false;
    }
    if (UI_IsBlocking()) return false;
    _tr.banner_done = true;
    Banner_Show(nm);
    if (is_string(_tr.trigger_sfx_on_fire_key) && _tr.trigger_sfx_on_fire_key != "") SFX_Play(_tr.trigger_sfx_on_fire_key);
    return true;
}

// ---- lore notes (D107) ----
// Readable notes at fixed tiles in the existing floor rooms. Each is a plain obj_interactable made at room start (Notes_SpawnForRoom) and read
// through the interact path (Interact_Handle); no new object. 4 are always there, the rest show your own earlier marks after 3 / 6 / 10 deaths.
// A note you read is recorded in the profile (unlocks "note_<id>"): Note_Collected is the data function the Codex will list.
function Note_Defs() {
    var defs = [
        { id: "map_page", room: "rm_floor1", tx: 1, ty: 6, min_deaths: 0, title: "Torn survey page", lines: [
            "A page torn from a survey book. Your handwriting.",
            "\"No tunnel here. Not on any map I ever drew.\"",
            "The ink still looks wet. You don't remember writing it." ] },
        { id: "wall_breath", room: "rm_floor3", tx: 6, ty: 6, min_deaths: 0, title: "Wall scratches", lines: [
            "Scratched deep into the stone, slowly and carefully:",
            "\"It breathes. Hold still and you can feel it.\"",
            "\"Every step goes deeper. None of them go back.\"" ] },
        { id: "lost_others", room: "rm_floor6", tx: 3, ty: 15, min_deaths: 0, title: "Unfinished letter", lines: [
            "A letter that stops in the middle of a sentence.",
            "\"The others went ahead. Or I did. I can't tell anymore.\"",
            "\"I keep calling for them. Only the walls answer.\"" ] },
        { id: "carved_arrow", room: "rm_floor8", tx: 1, ty: 3, min_deaths: 0, title: "Carved arrow", lines: [
            "An arrow is carved here, pointing up.",
            "Someone crossed it out. Beneath it, one word:",
            "\"Don't.\"" ] },
        { id: "three_marks", room: "rm_floor2", tx: 8, ty: 6, min_deaths: 3, title: "Three marks", lines: [
            "Three short scratches in the stone.",
            "You made these. You don't remember making them." ] },
        { id: "mapmaker_scrap", room: "rm_floor4", tx: 2, ty: 8, min_deaths: 3, title: "Mapmaker's scrap", lines: [
            "A scrap of paper in your own hand:",
            "\"The fall was no accident. It wanted a mapmaker.\"",
            "\"Someone who would map it, and come back to map it again.\"" ] },
        { id: "six_marks", room: "rm_floor7", tx: 12, ty: 12, min_deaths: 6, title: "Six marks", lines: [
            "Six scratches in a row, tidy as a ledger.",
            "Beside them, in a shakier hand: \"Stop counting.\"",
            "\"It only counts you back.\"" ] },
        { id: "wall_of_marks", room: "rm_floor9", tx: 7, ty: 4, min_deaths: 10, title: "A wall of marks", lines: [
            "Ten scratches. Then more, far older than yours.",
            "Some are in other hands.",
            "You are not the first to wake down here." ] }
    ];
    for (var i = 0; i < array_length(defs); i++) {
        var d = defs[i];
        d.title = Loc_T("note." + d.id + ".title", d.title);
        for (var j = 0; j < array_length(d.lines); j++) d.lines[j] = Loc_T("note." + d.id + "." + string(j), d.lines[j]);
        defs[i] = d;
    }
    return defs;
}

function Note_Visible(_def, _deaths) {
    return _deaths >= _def.min_deaths;
}

// The notes that stand in _room_name for a player with _deaths deaths.
function Note_ForRoom(_room_name, _deaths) {
    var out = [];
    var defs = Note_Defs();
    for (var i = 0; i < array_length(defs); i++) {
        if (defs[i].room == _room_name && Note_Visible(defs[i], _deaths)) array_push(out, defs[i]);
    }
    return out;
}

function Note_UnlockKey(_id) {
    return "note_" + string(_id);
}

function Note_MarkCollected(_prof, _id) {
    Profile_Unlock(_prof, Note_UnlockKey(_id));
}

function Note_IsCollected(_prof, _id) {
    return Profile_IsUnlocked(_prof, Note_UnlockKey(_id));
}

// Codex data: every note read so far, in note order, each { id, title, lines, room, min_deaths }.
function Note_Collected(_prof) {
    var out = [];
    var defs = Note_Defs();
    for (var i = 0; i < array_length(defs); i++) {
        if (Note_IsCollected(_prof, defs[i].id)) array_push(out, defs[i]);
    }
    return out;
}

// Room start (obj_game_controller): stands up the notes this player can see here.
function Notes_SpawnForRoom() {
    if (room == rm_start || room == rm_battle || room == rm_cutscene) return 0;
    var list = Note_ForRoom(room_get_name(room), Profile_Get().deaths);
    var made = 0;
    for (var i = 0; i < array_length(list); i++) {
        var d = list[i];
        var inst = instance_create_layer(d.tx * GRID_TILE_SIZE, d.ty * GRID_TILE_SIZE, "Instances", obj_interactable);
        with (inst) {
            note_id = d.id;
            interact_kind = INTERACT_DIALOGUE;
            interact_name = d.title;
            sprite_index = spr_red;   // only its 16 x 16 mask is used (the note is drawn by Note_DrawWorldFx); like the graves it is not visible itself
            visible = false;
        }
        made++;
    }
    return made;
}

function Note_Find(_id) {
    var defs = Note_Defs();
    for (var i = 0; i < array_length(defs); i++) { if (defs[i].id == _id) return defs[i]; }
    return undefined;
}

// Interact_Handle: the player read a note. The text opens as a dialogue under the note's title; the note is recorded in the profile.
function Note_Read(_inst) {
    var d = Note_Find(_inst.note_id);
    if (!is_struct(d)) return false;
    var prof = Profile_Get();
    if (!Note_IsCollected(prof, d.id)) {
        Note_MarkCollected(prof, d.id);
        Profile_Flush();
    }
    Dialogue_StartWithSpeaker(d.title, d.lines);
    return true;
}

// World layer script (World_DrawFx): a small page on the note's tile. Pale while unread, dimmer once read. Four palette colours.
function Note_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    if (!instance_exists(obj_interactable)) return;
    var c0 = UI_C_DARKEST;
    var c1 = UI_C_DARK;
    var c2 = UI_C_LIGHT;
    var c3 = UI_C_LIGHTEST;
    var oc = draw_get_color();
    var oa = draw_get_alpha();
    draw_set_alpha(1);
    var prof = Profile_Get();
    with (obj_interactable) {
        if (!variable_instance_exists(id, "note_id")) continue;
        var read = Note_IsCollected(prof, note_id);
        var nx = floor(x);
        var ny = floor(y);
        draw_set_color(c0);
        draw_rectangle(nx + 3, ny + 2, nx + 12, ny + 13, false);
        draw_set_color(read ? c2 : c3);
        draw_rectangle(nx + 4, ny + 3, nx + 11, ny + 12, false);
        draw_set_color(c1);
        draw_rectangle(nx + 5, ny + 5, nx + 10, ny + 5, false);
        draw_rectangle(nx + 5, ny + 7, nx + 10, ny + 7, false);
        draw_rectangle(nx + 5, ny + 9, nx + 8, ny + 9, false);
    }
    draw_set_color(oc);
    draw_set_alpha(oa);
}

// ---- closing text and credits (D105, D40) ----
// The last cutscene segment of the ending (after "There is no hope."). D105: "Thank you for playing..." and "by PaleRook" stay, the
// prototype / 2 months wording is gone. The credits roll follows it.
function Story_ClosingLines() {
    return [
        "Thank you for playing...",
        "We're glad you made it all the way to the end.",
        "We're looking to use what we learned from this game for our next title.",
        "Please support our next development :)",
        "by PaleRook",
        "..."
    ];
}

// TODO-OWNER: the owner has not sent the sound / music creator names yet (D40). Until then every sound carries this placeholder; when the names
// arrive, set the creator of each asset in Credits_SoundAssets below (the roll groups sounds by creator by itself).
#macro CREDITS_CREATOR_TBD "(owner to supply)"

// All 126 original sound and music assets, by asset name (TODO-OWNER: creator per asset), then the 30 new D116 takes with their creators.
function Credits_SoundAssets() {
    var names = [
        "Abstract1", "Abstract2", "African1", "African2", "African3", "African4", "Ambience_haunting",
        "Ambience_haunting_2", "Arrival", "barrel_break", "Bite_2", "bleed", "Blocked", "Body_falling_wood",
        "Bow_Attack_", "Bow_Impact_Hit_", "chest_open", "Coffee1", "Coffee2", "Crying_moaning_ambience",
        "Crying_moaning_ambience_2", "Crying_moaning_ambience_3", "dire_wolf_attack", "dire_wolf_spawn",
        "double_shot", "Dropping_keys", "evasion_up", "final_boss_spawn", "fireball", "Fireball_2", "foresight",
        "forest_bgm__for_everymap_with_trees", "Ghost_scream_3", "ghost_sword_attack", "ghost_sword_spawn",
        "GooeySlime___Sound_Effect", "Hiss", "horinzotal_slash", "horizontal_slash", "ice_spear", "kill_torch",
        "killer_plant_attack", "killer_plant_spawn", "Knife_stab", "Laugh_evil_deep_3", "Laugh_spooky_3",
        "Laugh_spooky_4", "Liquid_slosh", "mad_whisp_attack", "mad_whisp_spawn", "mage_attack", "meditation35",
        "Metal_resonance", "mini_boss_attack", "mini_boss_spawn", "Minimalist1", "Minimalist10", "Minimalist11",
        "Minimalist12", "Minimalist13", "Minimalist2", "Minimalist3", "Minimalist4", "Minimalist5", "Minimalist6",
        "Minimalist7", "Minimalist8", "Minimalist9", "miss_effect", "miss_effect2", "Modern1", "Modern10",
        "Modern11", "Modern12", "Modern13", "Modern14", "Modern15", "Modern16", "Modern2", "Modern3", "Modern4",
        "Modern5", "Modern6", "Modern7", "Modern8", "Modern9", "Monster_chatter", "Monster_chatter_2",
        "Monster_chatter_3", "Monster_chatter_4", "Monster_Roar_5", "Monster_Roar_9", "muscle_up", "overall_bgm",
        "Punch_1", "Punch_2", "Punch_3", "Punch_crunchy", "Punch_crunchy_2", "Retro1", "Retro10", "Retro11",
        "Retro12", "Retro2", "Retro3", "Retro4", "Retro5", "Retro6", "Retro7", "Retro8", "Retro9", "rev_up",
        "Slice_Whoosh_Sound_Effect", "Slime_Attack__Nr__1__Minecraft_Sound____Sound_Effect_for_editing",
        "snake_spaawn_and_attack", "spider_both_attack_and_spawn", "stun", "sword_attack", "sword_impact",
        "take_aim", "The_Twilight_of_Camelot", "waterspray", "Whip_2", "Wood_Block1", "Wood_Block2", "Wood_Block3"
    ];
    var out = [];
    for (var i = 0; i < array_length(names); i++) array_push(out, { asset: names[i], creator: CREDITS_CREATOR_TBD });   // TODO-OWNER
    var extra = Credits_NewSfxAssets();
    for (var j = 0; j < array_length(extra); j++) array_push(out, extra[j]);
    return out;
}

// D116: the extra monster takes (CC0, OpenGameArt) the owner imports from art/sfx_new/. The names are known now, so the creators are too.
// rubberduck = "80 CC0 creature SFX" 1 and 2; Ogrebane = "Monster Sound Effects Pack"; Darsycho = "Monster snarls". Source of each file: art/sfx_new/README.md.
function Credits_NewSfxAssets() {
    var takes = [
        ["rubberduck", "slime_spawn_2"], ["rubberduck", "slime_attack_2"], ["rubberduck", "slime_attack_3"],
        ["rubberduck", "spider_spawn_2"], ["rubberduck", "spider_attack_2"], ["rubberduck", "spider_attack_3"],
        ["rubberduck", "snake_spawn_2"], ["rubberduck", "snake_attack_2"], ["rubberduck", "snake_attack_3"],
        ["rubberduck", "dire_wolf_spawn_2"], ["rubberduck", "dire_wolf_attack_2"], ["Darsycho", "dire_wolf_attack_3"],
        ["rubberduck", "killer_plant_spawn_2"], ["rubberduck", "killer_plant_attack_2"], ["rubberduck", "killer_plant_attack_3"],
        ["rubberduck", "mad_whisp_spawn_2"], ["rubberduck", "mad_whisp_attack_2"], ["rubberduck", "mad_whisp_attack_3"],
        ["rubberduck", "ghost_sword_spawn_2"], ["rubberduck", "ghost_sword_attack_2"], ["rubberduck", "ghost_sword_attack_3"],
        ["rubberduck", "stranger_spawn_2"], ["rubberduck", "stranger_attack_2"], ["rubberduck", "stranger_attack_3"],
        ["rubberduck", "mini_boss_spawn_2"], ["Ogrebane", "mini_boss_attack_2"], ["Ogrebane", "mini_boss_attack_3"],
        ["rubberduck", "final_boss_spawn_2"], ["rubberduck", "final_boss_attack_2"], ["Darsycho", "final_boss_attack_3"]
    ];
    var out = [];
    for (var i = 0; i < array_length(takes); i++) array_push(out, { asset: takes[i][1], creator: takes[i][0] });
    return out;
}

// The credits roll as { kind, text }: "title", "head", "line", "names" (a paragraph) and "gap".
function Credits_Lines() {
    if (!variable_global_exists("credits_lines_builds")) global.credits_lines_builds = 0;
    global.credits_lines_builds++;
    var out = [];
    array_push(out, { kind: "title", text: Loc_T("credits.title", "NO HOPE") });
    array_push(out, { kind: "line", text: Loc_T("credits.game_by", "Game and art by PaleRook") });
    array_push(out, { kind: "gap", text: "" });
    array_push(out, { kind: "head", text: Loc_T("credits.fonts", "Fonts") });
    array_push(out, { kind: "line", text: Loc_T("credits.font_galmuri", "Galmuri by Lee Minseo (OFL-1.1)") });
    array_push(out, { kind: "line", text: Loc_T("credits.font_pixel", "Retro Gaming pixel font") });
    array_push(out, { kind: "gap", text: "" });
    array_push(out, { kind: "head", text: Loc_T("credits.tools", "Tools") });
    array_push(out, { kind: "line", text: Loc_T("credits.tool_gamemaker", "Made with GameMaker") });
    array_push(out, { kind: "gap", text: "" });
    array_push(out, { kind: "head", text: Loc_T("credits.sounds", "Sound and music") });
    var snd = Credits_SoundAssets();
    var creators = [];
    for (var i = 0; i < array_length(snd); i++) {
        var seen = false;
        for (var c = 0; c < array_length(creators); c++) { if (creators[c] == snd[i].creator) seen = true; }
        if (!seen) array_push(creators, snd[i].creator);
    }
    for (var g = 0; g < array_length(creators); g++) {
        var list = "";
        for (var s = 0; s < array_length(snd); s++) {
            if (snd[s].creator != creators[g]) continue;
            list += ((list == "") ? "" : ", ") + snd[s].asset;
        }
        array_push(out, { kind: "line", text: Loc_T("credits.creator", "creator: {name}", { name: creators[g] }) });
        array_push(out, { kind: "names", text: list });
        array_push(out, { kind: "gap", text: "" });
    }
    array_push(out, { kind: "gap", text: "" });
    array_push(out, { kind: "line", text: Loc_T("credits.thanks", "Thank you for playing.") });
    array_push(out, { kind: "line", text: Loc_T("credits.by", "by PaleRook") });
    return out;
}

// The roll without its spacing, as plain strings (what the tests search).
function Credits_PlainLines() {
    var out = [];
    var entries = Credits_Lines();
    for (var i = 0; i < array_length(entries); i++) { if (entries[i].kind != "gap") array_push(out, entries[i].text); }
    return out;
}

// D108 F1d-2: how often the roll's lines and its layout are built (a check reads them to see the roll is built once per change).
function Credits_LinesBuilds() {
    return variable_global_exists("credits_lines_builds") ? global.credits_lines_builds : 0;
}

function Credits_LayoutBuilds() {
    return variable_global_exists("credits_layout_builds") ? global.credits_layout_builds : 0;
}

// Lays the roll out for the current GUI size: y of every entry (from the top of the roll), its height, and the whole height.
function Credits_Layout() {
    return Credits_LayoutBuild();
}

// The uncached computation of Credits_Layout. Counted (Credits_LayoutBuilds).
function Credits_LayoutBuild() {
    if (!variable_global_exists("credits_layout_builds")) global.credits_layout_builds = 0;
    global.credits_layout_builds++;
    var mt = Ui_Metrics();
    var entries = Credits_Lines();
    var col_w = min(mt.gw - 2 * mt.margin, round(mt.gw * 0.7));
    var ypos = 0;
    var rows = [];
    for (var i = 0; i < array_length(entries); i++) {
        var e = entries[i];
        var h = mt.line_h;
        var pre = 0;
        if (e.kind == "gap") h = mt.line_h;
        else if (e.kind == "names") h = Ui_TextBlockH(e.text, col_w);
        else if (e.kind == "title") h = mt.line_h * 2;
        else if (e.kind == "head") pre = mt.line_h div 2;
        ypos += pre;
        array_push(rows, { kind: e.kind, text: e.text, y: ypos, h: h });
        ypos += h + mt.p * 2;
    }
    return { rows: rows, total: ypos, col_w: col_w };
}

// D108 F2a: the roll scrolls 60 GUI pixels per second (it was one pixel per 60 fps frame), whatever the frame rate.
#macro CREDITS_PX_PER_SEC 60

// GUI pixels the roll has scrolled after _ms milliseconds.
function Credits_ScrollPx(_ms) {
    return _ms * CREDITS_PX_PER_SEC / 1000;
}

// Milliseconds the roll takes (a screen of lead-in, the roll, a screen of lead-out).
function Credits_TotalMs(_layout = undefined) {
    var l = is_struct(_layout) ? _layout : Credits_Layout();
    var px = Display_GuiH() + l.total + round(Display_GuiH() * 0.5);
    return px * 1000 / CREDITS_PX_PER_SEC;
}

function Credits_Draw(_ms) {
    var mt = Ui_Metrics();
    var p = mt.p;
    Ui_Box(0, 0, mt.gw, mt.gh, UI_C_DARKEST);
    var l = Credits_Layout();
    var top = mt.gh - round(Credits_ScrollPx(_ms));   // 60 GUI pixels per second
    var cx = round(mt.gw / 2);
    for (var i = 0; i < array_length(l.rows); i++) {
        var r = l.rows[i];
        var ry = top + r.y;
        if (ry > mt.gh || ry + r.h < 0) continue;
        switch (r.kind) {
            case "title": Ui_Text(cx, ry, r.text, UI_C_LIGHTEST, fa_center); break;
            case "head": Ui_Text(cx, ry, r.text, UI_C_LIGHTEST, fa_center); break;
            case "line": Ui_Text(cx, ry, r.text, UI_C_LIGHT, fa_center); break;
            case "names": {
                var s = max(0.0001, UI_GetFontScale());
                draw_set_halign(fa_center);
                draw_set_valign(fa_top);
                draw_set_color(UI_C_TEXT);
                draw_text_ext_transformed(cx, round(ry), r.text, -1, max(1, round(l.col_w / s)), s, s, 0);
                draw_set_halign(fa_left);
            } break;
        }
    }
}

// ==========================================================================================================================
// C4 (D45): just-in-time tutorial prompts. The first time a mechanic shows up a short pop-up says what to press and what it does; it is
// remembered in the profile (a story_seen key, TUTORIAL_KEY_PREFIX plus the id, so once per profile, across runs) and every one can be re-read on the Help page
// in the pause menu. Eleven of them: the turn strip, the sliding bar, arrow skills, the defence bar, stagger / BREAK, the card pick, the shop,
// throwables, beds, elites, statuses. Text is {action} tokens (Prompt_*, scr_input) so the glyphs follow the last-used device and the player's keys.
// The game calls Tutorial_Trigger with the mechanic id at the moment the mechanic appears; the pop-up (Tutorial_* UI in scr_menu) blocks the world and
// the battle until it is dismissed. global.tutorial_off silences it (the scripted test runs).
// Hooks in: timeline and elite (battle menu), bar, arrows, defence (the QTE begin functions), throwables (Battle_ThrowBegin), shop (ShopUi_Open), stagger (Battle_StaggerHit), status
// (Status_Add in battle), cards (CardsUi_Open), bed (BedUi_Open).
// ==========================================================================================================================
#macro TUTORIAL_INPUT_DELAY_FRAMES 12   // keys are ignored this long after a pop-up opens (the press that caused it must not close it)

function Tutorial_Ids() {
    return ["timeline", "bar", "arrows", "defence", "stagger", "cards", "shop", "throwables", "bed", "elite", "status"];
}

// { id, title, body } in the current language, or undefined. English is the fallback of Loc_T; the workbook holds EN and KO.
function Tutorial_Get(_id) {
    switch (_id) {
        case "timeline":
            return { id: _id, title: Loc_T("tutorial.timeline.title", "Turn order"),
                body: Loc_T("tutorial.timeline.body", "The strip at the top shows who acts next. Faster fighters act more often, and some skills push an enemy back a turn.") };
        case "bar":
            return { id: _id, title: Loc_T("tutorial.bar.title", "The sliding bar"),
                body: Loc_T("tutorial.bar.body", "A cursor slides along the bar. Press {confirm} when it is over the bright zone. The closer to the middle, the harder you hit.") };
        case "arrows":
            return { id: _id, title: Loc_T("tutorial.arrows.title", "Arrow skills"),
                body: Loc_T("tutorial.arrows.body", "Skills show a row of arrows. Press {up}{down}{left}{right} in that order before the time bar runs out. A wrong press costs time.") };
        case "defence":
            return { id: _id, title: Loc_T("tutorial.defence.title", "Defending"),
                body: Loc_T("tutorial.defence.body", "When an enemy winds up a big attack, a bar appears. Press {confirm} on the bright zone to take less damage and shake off its effects.") };
        case "stagger":
            return { id: _id, title: Loc_T("tutorial.stagger.title", "Stagger and BREAK"),
                body: Loc_T("tutorial.stagger.body", "Good hits fill the enemy's stagger meter. When it is full the enemy is BROKEN: it loses a turn and takes +50% damage.") };
        case "cards":
            return { id: _id, title: Loc_T("tutorial.cards.title", "Cards"),
                body: Loc_T("tutorial.cards.body", "Level-ups and skill chests offer 3 cards: a new skill, an upgrade or a passive. Take one, or skip for a little gold.") };
        case "shop":
            return { id: _id, title: Loc_T("tutorial.shop.title", "The shop"),
                body: Loc_T("tutorial.shop.body", "The merchant sells potions and gear. Gold is kept for the whole run, and the stock changes with every run.") };
        case "throwables":
            return { id: _id, title: Loc_T("tutorial.throwables.title", "Throwables"),
                body: Loc_T("tutorial.throwables.body", "Throwable items hurt an enemy straight from the item menu. Each one is used up when thrown, so save them for hard fights.") };
        case "bed":
            return { id: _id, title: Loc_T("tutorial.bed.title", "Beds"),
                body: Loc_T("tutorial.bed.body", "Each bed can be used once per run. Rest to restore all your HP and MP, or use it to upgrade one of your skills.") };
        case "elite":
            return { id: _id, title: Loc_T("tutorial.elite.title", "Elites"),
                body: Loc_T("tutorial.elite.body", "Marked enemies are Elites. They are tougher than normal ones, but their rewards are better.") };
        case "status":
            return { id: _id, title: Loc_T("tutorial.status.title", "Statuses"),
                body: Loc_T("tutorial.status.body", "Poison, Burning, Bleeding and Stun last a few turns. The icons under a name show which ones a fighter has.") };
    }
    return undefined;
}

function Tutorial_Footer() {
    return Loc_T("tutorial.footer", "{confirm} Continue");
}

function Tutorial_Seen(_id) {
    return Story_Seen(TUTORIAL_KEY_PREFIX + string(_id));
}

function Tutorial_Enabled() {
    return !(variable_global_exists("tutorial_off") && global.tutorial_off);
}

function Tutorial_IsOpen() {
    return variable_global_exists("tutorial_ui") && is_struct(global.tutorial_ui);
}

function Tutorial_CurrentId() {
    return Tutorial_IsOpen() ? global.tutorial_ui.id : "";
}

function Tutorial_QueueLength() {
    return Tutorial_IsOpen() ? array_length(global.tutorial_ui.queue) : 0;
}

// The mechanic _id just appeared. Opens its pop-up the first time ever (this profile), queues it behind one that is open. Returns true when
// it was new. Marks it seen at once, so a session that ends with the pop-up up does not show it again.
function Tutorial_Trigger(_id) {
    if (!Tutorial_Enabled()) return false;
    if (!is_struct(Tutorial_Get(_id))) return false;
    if (Tutorial_Seen(_id)) return false;
    Story_Mark(TUTORIAL_KEY_PREFIX + string(_id));
    if (Tutorial_IsOpen()) {
        array_push(global.tutorial_ui.queue, _id);
        return true;
    }
    global.tutorial_ui = { id: _id, queue: [], opened_frame: Input_Frame(), opened_ms: current_time };
    SFX_PlayUI("ui_openclose");
    return true;
}

// True during the frame a pop-up was dismissed in and the next one: the press that closed it must not also answer whatever is behind it (the
// battle menu, an interact in the world). A controller that steps before the ui controller sees the press one frame late (the scripted runs
// show it: a simulated key stays visible to it for the next frame too), so the guard covers two frames (about 33 ms).
function Tutorial_JustClosed() {
    return variable_global_exists("tutorial_closed_frame") && (Input_Frame() - global.tutorial_closed_frame) <= 1;
}

// Closes the pop-up that is up; the next queued one takes its place.
function Tutorial_Dismiss() {
    if (!Tutorial_IsOpen()) return;
    global.tutorial_closed_frame = Input_Frame();
    var t = global.tutorial_ui;
    if (array_length(t.queue) > 0) {
        t.id = t.queue[0];
        array_delete(t.queue, 0, 1);
        t.opened_frame = Input_Frame();
        t.opened_ms = current_time;
        return;
    }
    global.tutorial_ui = undefined;
}

// The Help page's rows: every tutorial in order, seen or not (Ui framework items; the details panel shows the text).
function Tutorial_HelpItems() {
    var ids = Tutorial_Ids();
    var out = [];
    for (var i = 0; i < array_length(ids); i++) {
        var e = Tutorial_Get(ids[i]);
        array_push(out, { id: ids[i], label: e.title, value: "", kind: "button", enabled: true, help: e.body, lines: [] });
    }
    return out;
}
