main_index = 0;
main_options = [
    Loc_T("menu.main.option.0", "New Game"),
    Loc_T("menu.main.option.1", "Load Game"),
    Loc_T("menu.main.option.2", "Settings"),
    Loc_T("menu.main.option.3", "Exit Game")
];
main_option_keys = ["menu.main.option.0", "menu.main.option.1", "menu.main.option.2", "menu.main.option.3"];
difficulty_options = [
    Loc_T("settings.difficulty.option.0", "Easy"),
    Loc_T("settings.difficulty.option.1", "Normal"),
    Loc_T("settings.difficulty.option.2", "Hard")
];
difficulty_option_keys = ["settings.difficulty.option.0", "settings.difficulty.option.1", "settings.difficulty.option.2"];
difficulty_values = [DIFFICULTY_EASY, DIFFICULTY_NORMAL, DIFFICULTY_HARD];
difficulty_index = 1;
difficulty_closing = false;
difficulty_close_frame = UI_OPENED_FRAME_NONE;
difficulty_pending_action = "";
difficulty_pending_value = DIFFICULTY_NORMAL;

difficulty_opened_frame = UI_OPENED_FRAME_NONE;
cutscene_id = "";
cutscene_started = false;
cutscene_sequence = [];
cutscene_segment_index = -1;
cutscene_segment_hold_timer = 0;
cutscene_wait_transition = false;
cutscene_transition_next_index = -1;
cutscene_transition_switched = false;
boot_logo_phase = 0;
boot_logo_timer = 0;
boot_logo_alpha = 0;
boot_logo_fade_in_frames = 36;
boot_logo_hold_frames = 180;
boot_logo_fade_out_frames = 36;
boot_logo_black_hold_frames = 8;
boot_logo_sprite = pale_rook_1;

cutscene_definitions = {};
cutscene_definitions.intro = [
    {
        sprite: black_screen,
        lines: [
            "This is not a world of fantasy, magic, and dragons.",
            "There were no monsters.",
            "Only monsters among men.",
            "This is a world of grit-medieval kingdoms and warring countries.",
            "...",
            "Or is it?",
            "...",
            "You are a mapmaker in a remote village, scraping by penny to penny.",
            "There were rumors of conscription for the war between two kingdoms.",
            "The reward was enough to set you up for a year..",
            "It was worth it...",
            "You signed up."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: true
    },
    {
        sprite: very_first_cut_scene,
        lines: [
            "The plan was to ambush the enemy using a shortcut.",
            "Good thing you knew the forest as you grew up here.",
            "Then the scouts reported a tunnel near the mountain.",
            "You'd never heard of such a tunnel in all your life.",
            "You couldn't help thinking it was a joke...",
            "But it wasn't.",
            "There really was a tunnel. You could hardly believe it.",
            "The group ventured deep into the tunnel, heading toward the enemy castle...",
            "You're just the navigator for this raid party.",
            "And this place never existed before...",
            "You knew it was a mistake. You could feel it.",
            "Before you could speak up.",
            "You hear cracking...",
            "Small tremors..."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: true
    },
    {
        sprite: intro_scene,
        lines: [
            "But it was already too late.",
            "You fell."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: true
    }
];

cutscene_definitions.ending = [
    {
        sprite: ending_scene,
        lines: [
            "Thank the Almighty...",
            "An exit...",
            "I need to find out where I am."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: true
    },
    {
        sprite: third_to_last_scene,
        lines: [
            "Huh?",
            "...",
            "Isn't this the raid party?",
            "They're all dead.",
            "... What on earth..."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: true
    },
    {
        sprite: second_to_last_scene,
        lines: [
            "...",
            "Oh.",
            "...",
            "I wasn't so lucky after all."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: true
    },
    {
        sprite: last_cut_scene,
        lines: [
            "There is no hope."
        ],
        hold_frames: 0,
        transition_speed: "slow",
        text_only: true,
        chars_per_sec: 12
    },
    {
        sprite: black_screen,
        lines: [
            "Thank you for playing...",
            "This was around 2 months of development, and I'm glad you were able to get through our prototype story.",
            "We're looking to use what we learned from this game for our next title.",
            "Please support our next development :)",
            "by PaleRook",
            "..."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: false
    }
];

cutscene_definitions.game_over = [
    {
        sprite_name: "GAME_OVER",
        lines: [
            "GAME OVER."
        ],
        hold_frames: 0,
        transition_speed: "normal",
        text_only: true,
        chars_per_sec: UI_CUTSCENE_GAME_OVER_CHARS_PER_SEC
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
load_available = Save_HasAnySlot();
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
