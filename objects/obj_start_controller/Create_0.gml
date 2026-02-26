main_index = 0;
main_options = ["New Game", "Load Game", "Settings", "Exit Game"];

settings_index = 0;
settings_volume_step = SETTINGS_VOLUME_STEP;
settings_dirty = false;
cutscene_id = "";
cutscene_started = false;
cutscene_sequence = [];
cutscene_segment_index = -1;
cutscene_segment_hold_timer = 0;
cutscene_wait_transition = false;
cutscene_transition_next_index = -1;
cutscene_transition_switched = false;

cutscene_definitions = {};
cutscene_definitions.intro = [
    {
        sprite: very_first_cut_scene,
        lines: [
            "You ventured deep in a tunnel heading towards a neighboring enemy castle...",
            "The plan was to ambush the enemy using this shortcut.",
            "You are just a porter for this raid party...",
            "You knew this was a mistake...",
            "You were from this area's village. However, this place never existed before...",
            "You just knew the ground was weak and unsupported...",
            "Cracking.. Small Tremors..."
        ],
        hold_frames: 0,
        transition_speed: "normal"
    },
    {
        sprite: intro_scene,
        lines: [
            "But it was already too late to speak up.",
            "You fell down."
        ],
        hold_frames: 0,
        transition_speed: "normal"
    }
];

cutscene_definitions.ending = [
    {
        sprite: ending_scene,
        lines: [
            "Thank the almighty...",
            "An exit...",
            "I need to find out where I am."
        ],
        hold_frames: 0,
        transition_speed: "normal"
    },
    {
        sprite: third_to_last_scene,
        lines: [
            "Huh?",
            "...",
            "Isn't this the raid party?",
            "They are all dead.",
            "... What on earth..."
        ],
        hold_frames: 0,
        transition_speed: "normal"
    },
    {
        sprite: second_to_last_scene,
        lines: [
            "...",
            "oh",
            "...",
            "I wasn't so lucky after all"
        ],
        hold_frames: 0,
        transition_speed: "normal"
    },
    {
        sprite: last_cut_scene,
        lines: [],
        hold_frames: CUTSCENE_LAST_SCENE_HOLD_FRAMES,
        transition_speed: "slow"
    },
    {
        sprite: black_screen,
        lines: [
            "Thank you for playing.",
            "Please support our next development :)"
        ],
        hold_frames: 0,
        transition_speed: "normal"
    }
];

var gs = GameState_Get();
settings_pending = GameSettings_Copy(GameSettings_Ensure());
load_available = Save_HasAnySlot();

if (room == rm_start) {
    gs.in_main_menu = true;
    state = "main";
} else if (room == rm_cutscene) {
    state = "cutscene";
} else {
    state = "main";
} // main, cutscene, settings
