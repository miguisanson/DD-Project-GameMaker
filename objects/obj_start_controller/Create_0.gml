// Title menu (D0 UI framework, scr_menu.gml Title_*): the stack is built on the first Step in state "main".
title_stk = undefined;
title_exit = undefined;      // { at }: New Game was chosen, the run starts when the title menu has faded
title_refresh = true;        // relabel the title items (language or save files may have changed)
title_new_slot = -1;         // D175: the save file New Game will use (committed by Title_NewGameGo)
title_new_wipe = false;      // D175: that file is emptied first (the overwrite picker asked)
title_hint_rect = { x: 0, y: 0, w: 0, h: 0 };   // D175: where the picker's key line was drawn last (-shots)
title_t0 = -100000;          // D128: when the picture started to fade in (a fresh launch sets it when the splash appears; every other visit shows it at once)
title_card = { kind: "none", status: "missing", class_name: "", floor: 0, gold: 0, time_ms: -1 };   // D128: the Continue card's model (Title_Build / Title_Refresh)
title_card_rect = { x: 0, y: 0, w: 0, h: 0 };     // where the card and the splash prompt were drawn last (the -shots checks read them)
title_prompt_rect = { x: 0, y: 0, w: 0, h: 0 };
cutscene_id = "";
cutscene_started = false;
cutscene_sequence = [];
cutscene_segment_index = -1;
cutscene_segment_hold_timer = 0;
cutscene_wait_transition = false;
cutscene_skip = false;   // D48: hold confirm ~1 s skips the cutscene
credits_t = 0;           // C5 (D105): milliseconds of the credits roll (state "credits"), D108 F2a
cutscene_transition_next_index = -1;
cutscene_transition_switched = false;
boot_logo_phase = 0;
boot_logo_timer = 0;
boot_logo_alpha = 0;
boot_logo_fade_in_ms = BOOT_LOGO_FADE_IN_MS;
boot_logo_hold_ms = BOOT_LOGO_HOLD_MS;
boot_logo_fade_out_ms = BOOT_LOGO_FADE_OUT_MS;
boot_logo_black_hold_ms = BOOT_LOGO_BLACK_HOLD_MS;
boot_logo_sprite = pale_rook_1;

cutscene_definitions = {};
cutscene_definitions.intro = [
    {
        sprite: black_screen,
        lines: [
            "This is not a world of magic and dragons.",
            "There were no monsters.",
            "Only monsters among men.",
            "This is a world of mud, borders and kings.",
            "...",
            "Or is it?",
            "...",
            "You were a mapmaker in a remote village, scraping by penny to penny.",
            "Word came that the crown was drafting men for the war.",
            "The pay would feed you for a year...",
            "It seemed worth it...",
            "You signed up."
        ],
        hold_ms: 0,
        transition_speed: "normal"
    },
    {
        sprite: very_first_cut_scene,
        lines: [
            "The plan was to ambush the enemy by a shortcut.",
            "You grew up in these woods. You knew every path.",
            "Then the scouts reported a tunnel near the mountain.",
            "You had never heard of a tunnel there. Not once.",
            "You took it for a joke...",
            "But it wasn't.",
            "The tunnel was real. None of your maps had room for it.",
            "The raid party went in, toward the enemy castle...",
            "You were only the navigator.",
            "The day before, there was only hillside.",
            "Your stomach knew it was a mistake.",
            "Before you could speak up.",
            "Stone cracks somewhere overhead...",
            "Dust sifts onto your shoulders..."
        ],
        hold_ms: 0,
        transition_speed: "normal"
    },
    {
        sprite: intro_scene,
        lines: [
            "But it was already too late.",
            "You fell."
        ],
        hold_ms: 0,
        transition_speed: "normal"
    }
];

cutscene_definitions.ending = [
    {
        sprite: ending_scene,
        lines: [
            "Air. Actual air...",
            "An exit...",
            "First, I need to know where I am."
        ],
        hold_ms: 0,
        transition_speed: "normal"
    },
    {
        sprite: third_to_last_scene,
        lines: [
            "Huh?",
            "...",
            "Is that... the raid party?",
            "They're all dead.",
            "...What happened out here?"
        ],
        hold_ms: 0,
        transition_speed: "normal"
    },
    {
        sprite: second_to_last_scene,
        lines: [
            "...",
            "Oh.",
            "...",
            "So much for lucky."
        ],
        hold_ms: 0,
        transition_speed: "normal"
    },
    {
        sprite: last_cut_scene,
        lines: [
            "There is no hope."
        ],
        hold_ms: 0,
        transition_speed: "slow"
    },
    {
        sprite: black_screen,
        lines: Story_ClosingLines(),   // C5 (D105): the closing text lives in scr_dialogue.gml (the credits roll follows it)
        hold_ms: 0,
        transition_speed: "normal"
    }
];

// C5 (D103): no more "GAME OVER.". The fade to black is all this holds; the death line and summary follow in RunFlow (scr_room_state).
cutscene_definitions.game_over = [
    {
        sprite: black_screen,
        lines: [],
        hold_ms: Transition_FramesToMs(2),
        transition_speed: "normal"
    }
];

var __localize_cutscene = function(_cutscene_id) {
    if (!variable_struct_exists(cutscene_definitions, _cutscene_id)) return;
    var seq = variable_struct_get(cutscene_definitions, _cutscene_id);
    if (!is_array(seq)) return;

    for (var si = 0; si < array_length(seq); si++) {
        var seg = seq[si];
        if (!is_struct(seg)) continue;
        if (!variable_struct_exists(seg, "lines") || !is_array(seg.lines)) continue;
        for (var li = 0; li < array_length(seg.lines); li++) {
            var fallback = string(seg.lines[li]);
            seg.lines[li] = Loc_T("cutscene." + _cutscene_id + "." + string(si) + "." + string(li), fallback);
        }
        seq[si] = seg;
    }
};

__localize_cutscene("intro");
__localize_cutscene("ending");
__localize_cutscene("game_over");

var gs = GameState_Get();
title_bg_sprite = noone;
title_bg_layer_id = -1;

if (room == rm_start) {
    gs.in_main_menu = true;
    if (!variable_struct_exists(gs, "startup_logo_seen")) gs.startup_logo_seen = false;
    if (!gs.startup_logo_seen) {
        gs.startup_logo_seen = true;
        state = "boot_logo";
        boot_logo_phase = 0;
        boot_logo_timer = 0;
        boot_logo_alpha = 0;
    } else {
        state = "main";
    }
    depth = 100000;
    title_bg_sprite = main_menu;
    title_bg_layer_id = layer_get_id("Background");
    if (title_bg_layer_id != -1) layer_set_visible(title_bg_layer_id, false);
} else if (room == rm_cutscene) {
    state = "cutscene";
} else {
    state = "main";
} // main, cutscene, settings
