#macro RIGHT 0
#macro UP 1
#macro LEFT 2
#macro DOWN 3

#macro STAT_MIN 1
#macro STAT_MAX 60 // change to 99 if you want
#macro LEVEL_CAP 10 // final game cap
#macro LEVEL_CAP_TECHNICAL LEVEL_CAP

#macro CLASS_ARCHER 0
#macro CLASS_KNIGHT 1
#macro CLASS_MAGE   2
#macro CLASS_NOBODY 3

#macro DIFFICULTY_EASY   0
#macro DIFFICULTY_NORMAL 1
#macro DIFFICULTY_HARD   2

#macro ENEMY_SLIME     0
#macro ENEMY_DIREWOLF  1
#macro ENEMY_GHOSTSWORD 2
#macro ENEMY_SPIDER 3
#macro ENEMY_MADWHISP 4
#macro ENEMY_SNAKE 5
#macro ENEMY_KILLER_PLANT 6
#macro ENEMY_STRANGER 7
#macro ENEMY_MINI_BOSS 8
#macro ENEMY_FINAL_BOSS 9

#macro TURN_PLAYER 0
#macro TURN_ENEMY  1

#macro BSTATE_MESSAGE       0
#macro BSTATE_MENU          1
#macro BSTATE_PLAYER_RUN    3
#macro BSTATE_ENEMY_ACT     4
#macro BSTATE_END_RUN       5
#macro BSTATE_SKILL_MENU    6
#macro BSTATE_ITEM_MENU     7
#macro BSTATE_ATTACK_TIMING 8
#macro BSTATE_ENEMY_DEFENCE 9
#macro BSTATE_SKILL_QTE     10

// D22: ATK DEF SPD MAG (+ HP/MP). Spec: .planning/research/combat-spec.md
#macro STAT_ATK 0
#macro STAT_DEF 1
#macro STAT_SPD 2
#macro STAT_MAG 3
#macro LEVEL_FREE_POINTS_PER_LEVEL 1   // D76
#macro STAT_VIG 4                      // D176: VIG gives Max HP, MND gives Max MP (soft-capped curves, Resource_MaxHpOfVig / Resource_MaxMpOfMnd); the free point may go to any of the six
#macro STAT_MND 5
#macro VIG_START 10                    // every class starts at VIG 10 = Max HP 10; MND starts by class (DB_PlayerClass stats.mnd)
#macro MND_BASE 10                     // MND 10 = Max MP 10
#macro LEGACY_HP_PER_POINT 3           // D143 (before D176): a free point on Max HP gave +3, on Max MP +2: an older save keeps them as hp_bonus / mp_bonus, Player_MigrateVigMnd turns them into VIG / MND points
#macro LEGACY_MP_PER_POINT 2
#macro PLAYER_BASE_HP 10
#macro PLAYER_BASE_MP 10
#macro COMBAT_UNARMED_POWER 2           // weapon power of a character with no weapon equipped
#macro COMBAT_POWER_SCALE 2           // spec section 4: weapon/skill power x this = formula power
#macro COMBAT_WEAPON_SKILL_SHARE 0.5  // D22: how much of the weapon's power adds to a player's skill power
#macro COMBAT_CRIT_MULT 2
#macro COMBAT_CRIT_CHANCE_MAX 0.5
#macro ROUND_HALF_UP_EPS 0.000001

#macro ITEM_WEAPON     0
#macro ITEM_ARMOR      1
#macro ITEM_CONSUMABLE 2
#macro ITEM_KEY        3
#macro ITEM_ACCESSORY  4   // C3 (D92): the third gear slot, "accessory" (ring / charm)

#macro TGT_ENEMY       0
#macro TGT_SELF        1
#macro TGT_ALL_ENEMIES 2
// Relative target aliases for readability (especially enemy-authored skills).
#macro TGT_OPPONENT       TGT_ENEMY

#macro STATUS_POISON     0
#macro STATUS_BLEED      1
#macro STATUS_BURN       2
#macro STATUS_STUN       3
#macro STATUS_GUARD      4
#macro STATUS_DMG_UP     5
#macro STATUS_EVASION    6
#macro STATUS_CRIT_UP    7
#macro STATUS_HIT_UP     8
#macro STATUS_MEDITATION 9
#macro STATUS_SOLIDIFY   10
#macro STATUS_BLOODTHIRSTY 11
#macro STATUS_BLESSING   12
#macro STATUS_SUNDER     13
#macro STATUS_BRACE      14   // D1a: the Guard command (D99, D180): every hit deals half until the player's next turn starts
#macro GUARD_MP_PCT      0.25 // D180: Guard gives back this share of max MP (rounded down)...
#macro GUARD_MP_MIN      2    // ...at least this many

#macro SKILL_POWER_STRIKE 0
#macro SKILL_WOUND        1
#macro SKILL_HILT_BASH    2
#macro SKILL_MUSCLE_UP    3
#macro SKILL_REV_UP       4
#macro SKILL_HORIZ_SLASH  5
#macro SKILL_POISON_ARROW 6
#macro SKILL_EVASION      7
#macro SKILL_DOUBLE_SHOT  8
#macro SKILL_TAKE_AIM     9
#macro SKILL_FIREBALL     10
#macro SKILL_POISON_MIST  11
#macro SKILL_ICE_SPEAR    12
#macro SKILL_MEDITATION   13
#macro SKILL_FORESIGHT    14
#macro SKILL_POISON_FANGS 15
#macro SKILL_SOLIDIFY     16
#macro SKILL_BITE         17
#macro SKILL_BLOODTHIRSTY 18
#macro SKILL_VINE_TRAP    19
#macro SKILL_SCORCHING_TOUCH 20
#macro SKILL_GHOST_CUT    21
#macro SKILL_STEAL        22
#macro SKILL_RAMMING      23
#macro SKILL_RAMPAGE      24
#macro SKILL_CURSE        25
#macro SKILL_BLESSING     26
#macro SKILL_FINAL_FURY   27
#macro SKILL_REGROW       28   // B4: enemy heal (Killer Plant)
#macro SKILL_SNUFF        29   // B4: enemy strips the player's buffs (Mad Whisp)
#macro SKILL_GORE         30   // B4: Palehorn phase 1+
#macro SKILL_PALE_HYMN    31   // B4: Pale Choirbeast heavy move

#macro BATTLE_COOLDOWN_FRAMES 60
#macro MONSTER_SFX_GAIN 0.80

#macro ENEMY_IDLE   0
#macro ENEMY_ALERT  1

#macro ENEMY_SCAN_RADIUS_DEFAULT 32

// H11 (D153, D158): smarter map AI, hiding spots, no spawn camping. Agent-chosen first numbers, for the owner to tune at the playtest.
#macro AI_HEAR_RUN_TILES 2         // an enemy hears the player RUN inside this straight-line distance (tiles, any direction, D179: 2, and not through walls: it needs a clear line or a way of at most 2 steps); walking is silent
#macro AI_SEARCH_FRAMES 180        // D179: an enemy that lost the player stands on the last cell it saw him on and looks round this long (3 s), then puts up one "?" and goes home
#macro AI_SEARCH_TURN_FRAMES 45    // ... turning a quarter round this often
#macro AI_IGNORE_FRAMES 120        // ... and then cannot notice the player for this long (2 s), unless he bumps into it (touching still starts a fight)
#macro AI_EXIT_CLEAR_TILES 3       // idle and patrol targets keep at least this far from every exit cell
#macro AI_ARRIVAL_CLEAR_TILES 3    // on a room arrival no enemy stands closer than this to the arrival tile
#macro AI_EXIT_RELOCATE_TILES 4    // an enemy found nearer than this to an exit on arrival is put back at its home, or at a spot at least this far from every exit
#macro AI_QUESTION_FRAMES 70       // how long the "?" of a given-up search stays over the enemy's head
#macro HIDE_SEEN_TILES 1           // a hidden player is only seen from this close (Chebyshev, tiles)
#macro HIDE_SETTLE_FRAMES 20       // the player must stand still this long on a hiding cell before it counts as hidden (walking across one does not)
#macro HIDE_PLAYER_ALPHA 0.5       // how see-through the hidden player is drawn

// D179 (R-098): sight is a cone. Agent-chosen first numbers, for the owner to tune at the playtest.
#macro AI_CONE_COLOUR UI_C_DARK    // the faint sight cone is a shade of this palette colour. The brief said UI_C_LIGHTEST, but every floor is that colour already: measured, a lightest tint changes no pixel there (the cone was invisible)
#macro AI_CONE_ALPHA_NEAR 0.10     // the faint sight cone drawn in front of an enemy: the tint of the cells nearest to it (alpha of AI_CONE_COLOUR) ...
#macro AI_CONE_ALPHA_MID 0.08      // ... the middle ...
#macro AI_CONE_ALPHA_FAR 0.06      // ... and the edge, softer
#macro AI_CONE_CHASE_MULT 1.4      // a chasing enemy's cone is a little stronger (still faint: 0.14 at most)
#macro AI_TURN_MIN_FRAMES 120      // an idle enemy turns to a new random direction every 2 to 4 seconds
#macro AI_TURN_MAX_FRAMES 240

#macro INTERACT_NONE       0
#macro INTERACT_DOOR       2
#macro INTERACT_SWITCH     3
#macro INTERACT_DIALOGUE   4
#macro INTERACT_CHECKPOINT 6

#macro UI_NONE     0
#macro UI_DIALOGUE 1
#macro UI_MENU 2
#macro UI_NOTICE 3   // F3a (D96): the notice pop-up (Notice_*) is up; it blocks the title and the world until it is gone
#macro UI_SAVE UI_NOTICE   // the old slot menu's name: obj_sfx_manager's debug overlay still reads it (that file is another packet's)
#macro UI_CLASS_SELECT 5
#macro UI_BED 6
#macro UI_CARDS 7   // C2: class choice, stat point, card pick, replace-a-skill screens (CardsUi_*)
#macro UI_SHOP 8    // C3 (D85): the merchant's shop (ShopUi_*)
#macro UI_TRAP 9    // R3 ideas2 (D173, IDEA-03): the trapped chest's sliding bar over the paused map (TrapUi_*)
#macro UI_FONT retro_gaming
#macro GRID_TILE_SIZE 16
#macro PLAYER_MOVE_SPEED_DEFAULT 1
#macro ENEMY_THINK_RATE_DEFAULT 15
#macro ENEMY_FORGET_DELAY_DEFAULT 30
#macro ENEMY_LEASH_MULT_DEFAULT 2
#macro ENEMY_WANDER_CHANCE_DEFAULT 4
#macro ENEMY_MOVE_SPEED_DEFAULT 1
#macro UI_OPENED_FRAME_NONE -1
#macro UI_DIALOGUE_REOPEN_LOCK_MS (1000 / 60)   // D108 F2b-2: ms, was 1 frame. After a close the world ignores the closing press for one UI step (Dialogue_LockStep)
#macro UI_DIALOGUE_CHARS_PER_SEC 60
#macro UI_DIALOGUE_ADVANCE_HOLD_SEC 0.75   // cutscene text only
#macro UI_DIALOGUE_BOX_HOLD_SEC 0.15       // D101: a boxed line is ready for the next confirm this soon after it is complete
#macro UI_DIALOGUE_STATE_REVEALING 0
#macro UI_DIALOGUE_STATE_HOLDING 1
#macro UI_DIALOGUE_STATE_READY 2
#macro UI_DIALOGUE_ARROW_FPS 2
#macro UI_HUD_HURT_FLASH_MS (8000 / 60)   // the HUD panel shake when the player is hurt: 8 frames at 60 fps (D108 F2b-1: ms)
#macro UI_TEXT_SCALE_BASE 2.00
#macro UI_TEXT_SCALE_MIN 1.00
#macro UI_TEXT_SCALE_MAX 4.00
#macro UI_CUTSCENE_DIALOGUE_TOP_RATIO 0.56
#macro UI_CUTSCENE_DIALOGUE_MIN_HEIGHT 44
#macro UI_CUTSCENE_TEXT_MARGIN_X 8
#macro UI_CUTSCENE_TEXT_SIDE_PAD_RATIO 0.08
#macro UI_CUTSCENE_TEXT_TOP_RATIO 0.70
#macro UI_CUTSCENE_TEXT_BOTTOM_PAD 8
#macro UI_CUTSCENE_TEXT_SHADOW_X 1
#macro UI_CUTSCENE_TEXT_SHADOW_Y 1
#macro UI_CUTSCENE_DIALOGUE_CHARS_PER_SEC 24
#macro UI_CUTSCENE_ADVANCE_BLOCK_MS (3000 / 60)   // D108 F2b-2: ms, was 2 frames (frame <= open + 2: the open frame and 2 after = 50 ms). A text-only cutscene line ignores Advance this long

#macro SHAKE_DIR_H 0
#macro SHAKE_DIR_V 1
#macro FX_FRAME_MS (1000 / 60)       // the 60 fps frame the shake rhythm was designed in
#macro FX_EDGE_SLACK_MS 1            // a ms boundary counts as reached when within this, so 12 steps of 16.667 ms still make 200 ms

#macro ENEMY_SHAKE_MAG 0.3
#macro ENEMY_SHAKE_MS 200         // D108 F2b-1: the shakes and flashes run on a ms clock; these were 12 / 12 frames and a 3 frame rate at 60 fps
#macro ENEMY_FLASH_MS 200
#macro ENEMY_FLASH_RATE_MS 50
#macro ENEMY_SHAKE_DIR SHAKE_DIR_H

#macro PLAYER_SHAKE_MAG 0.3
#macro PLAYER_SHAKE_MS 200
#macro PLAYER_SHAKE_DIR SHAKE_DIR_V

#macro SPR_SPEED_FPS 0

#macro COMBAT_ACTION_DELAY_MS 1000   // long hold: battle intro, kill and run-away messages (D108 F2b-1: ms, was 60 frames)
#macro COMBAT_ACTION_HOLD_SEC 0.3   // D55: hold after a player or enemy action, in seconds (Combat_ActionHoldMs gives it in ms)
#macro COMBAT_HOLD_FOREVER_MS (9999000 / 60)   // a scenario parks a battle on its message with wait_timer = this (it was 9999 frames)
#macro COMBAT_HOLD_SLACK_MS 1    // a message hold is spent when it is within this of 0, so 60 steps of 16.667 ms still make 1000 ms
#macro COMBAT_LOG_MAX 30
#macro SKILL_FX_SPEED_MULT 2.50
#macro PLAYER_SKILL_FX_SPEED_MULT 6.00
#macro PLAYER_SKILL_FX_SPEED_MULT_NON_ENEMY 3.00
#macro PLAYER_SKILL_FX_SPEED_MAX 2.00   // D55: Ice Spear and Hilt Bash must finish in about 0.75 s
#macro PLAYER_SKILL_FX_MAX_FRAMES 42   // D55: a player skill's animation plays through in at most this many game frames (0.7 s); the 0.3 s hold follows
#macro SKILL_FX_SCALE 2   // old fixed draw scale; battle animations now use FX_ScaleFor (I-052)
#macro FX_TARGET_FIT 1.5   // I-052: an effect is drawn at most this many times the target sprite's longest side
#macro FX_MAX_DRAW_PX 64   // I-052: and never more than this many world px on its longest side (the screen is 160 x 144)
#macro FX_PLAYER_TARGET_PX 32   // the player has no battle sprite; its effects are sized as for a 32 px target
// QTE part 1 (D56, D60, D61): the basic attack's sliding bar. All times are ms, counted from delta_time (QTE-01).
#macro QTE_PERFECT "PERFECT"   // grade keys (equipment passives, the bot and the tests compare them)
#macro QTE_GOOD "GOOD"
#macro QTE_OK "OK"
#macro QTE_WEAK "WEAK"
#macro QTE_NO_PRESS -1             // a press time below 0 means "no press" (Weak)
#macro TUTORIAL_KEY_PREFIX "tutorial:"   // C4 (D45): the profile key of a seen pop-up is this + its id (profile.story_seen)
#macro QTE_ASSIST_ZONE_MULT 1.5    // D35 QTE assist: the bar and defence zones are this much wider
#macro QTE_ASSIST_TIME_MULT 1.3    // D35 QTE assist: the arrow sequences get this much more time
#macro QTE_ZONE_CENTRE_PCT 70      // the bright zone's centre, in percent of the sweep
#macro QTE_LEAD_IN_MS 250          // the bar is up and the cursor is parked at 0 before the sweep starts
#macro QTE_EARLY_BUFFER_MS 80      // a press this close before the sweep starts is kept (judged at 0); earlier ones are dropped
#macro QTE_MAX_STEP_US 50000       // one frame never adds more than 50 ms to the clock, so a hitch cannot skip the bar
#macro QTE_RESULT_MS 700           // how long the grade word stays up
#macro QTE_HITSTOP_PERFECT_MS 60   // D61 feedback: freeze on a Perfect hit
#macro QTE_SHAKE_PERFECT_MAG 0.8   // camera shake (world px), subtle: PLAYER_SHAKE_MAG is 0.3
#macro QTE_SHAKE_PERFECT_MS (10000 / 60)
#macro QTE_SHAKE_GOOD_MAG 0.4
#macro QTE_SHAKE_GOOD_MS (8000 / 60)
#macro QTE_BAR_W 96                // bar size in base units (the picture is 160 x 144)
#macro QTE_BAR_H 8
#macro QTE_COL_DARKEST UI_C_DARKEST     // the four palette colours (D10, D108): the QTE bar uses the same UI_C_* macros as every other screen (defined in scr_menu)
#macro QTE_COL_DARK UI_C_DARK
#macro QTE_COL_LIGHT UI_C_LIGHT
#macro QTE_COL_LIGHTEST UI_C_LIGHTEST
#macro UI_C_MERCHANT_GOLD $47C5E8     // the merchant's gold glow, #E8C547 as GameMaker BGR: the one owner-approved colour outside the four palette colours (D113)
// QTE part 2 (D57-D59): the arrow sequence for a player skill and the defence bar. All times are ms from delta_time.
#macro QTE_SEQ_LEAD_IN_MS 300      // the arrows are up and the bar is full before the clock starts; presses in it are dropped
#macro QTE_SEQ_PENALTY_MS 250      // a wrong arrow takes this much off the time bar
#macro QTE_SEQ_BASE_MS 1000        // time bar = this + QTE_SEQ_PER_ARROW_MS per arrow
#macro QTE_SEQ_PER_ARROW_MS 800
#macro QTE_SEQ_FAST_BASE_MS 150    // Perfect (no mistakes) needs the sequence done within this + QTE_SEQ_FAST_PER_ARROW_MS per arrow
#macro QTE_SEQ_FAST_PER_ARROW_MS 450
#macro QTE_SEQ_SHAKE_MS 250        // how long the arrows shake after a wrong press
#macro QTE_SEQ_POP_MS 140          // how long a completed arrow hops
#macro QTE_TELEGRAPH_MS 400        // the "!" and the attack's name before the defence bar starts
#macro ENEMY_ACTION_CHAIN_MAX 3
#macro ENEMY_AUTO_RESOLVE_LEVEL_DELTA 3
#macro ENEMY_AUTO_RESOLVE_EXP_MULT_DEFAULT 0.35
#macro ENEMY_AUTO_RESOLVE_LOOT_MULT_DEFAULT 0.85
#macro ENEMY_AUTO_RESOLVE_RECOVER_FRAMES 6
#macro PLAYER_POST_TRANSITION_RECOVER_FRAMES 3
#macro PLAYER_DIALOGUE_SETTLE_FRAMES 4
#macro DIALOGUE_TRIGGER_TARGET_SEARCH_RADIUS 96
#macro DIALOGUE_TRIGGER_CAM_IN_SEC 0.45
#macro DIALOGUE_TRIGGER_CAM_HOLD_SEC -1
#macro DIALOGUE_TRIGGER_CAM_OUT_SEC 0.40
#macro DIALOGUE_TRIGGER_CAM_RESTORE_SEC 0.20
#macro DIALOGUE_TRIGGER_EASE_DEFAULT "smoothstep"

#macro VOL_MASTER_DEFAULT 1.0
#macro VOL_UI_DEFAULT 1.0
#macro VOL_SFX_DEFAULT 1.0
#macro VOL_MUSIC_DEFAULT 0.60
#macro SKILLBOOK_MANA_AMBIENCE_KEY "skillbook_mana_ambience_3"
#macro SKILLBOOK_MANA_AMBIENCE_KEY_1 "skillbook_mana_ambience_1"
#macro SKILLBOOK_MANA_AMBIENCE_KEY_2 "skillbook_mana_ambience_2"
#macro SKILLBOOK_MANA_AMBIENCE_KEY_3 "skillbook_mana_ambience_3"
#macro SKILLBOOK_MANA_AMBIENCE_BASE_GAIN 1.0
#macro SKILLBOOK_MANA_AMBIENCE_FADE_IN_FRAMES 60
#macro SKILLBOOK_MANA_AMBIENCE_FADE_OUT_FRAMES 72
#macro SKILLBOOK_MANA_AMBIENCE_POST_MIN_FRAMES 120
#macro SKILLBOOK_MANA_AMBIENCE_POST_MAX_FRAMES 180
#macro DISPLAY_BASE_W 160
#macro DISPLAY_BASE_H 144
#macro DISPLAY_SCALE_MIN 3
#macro DISPLAY_SCALE_MAX 16
#macro DISPLAY_SCALE_DEFAULT 3
// D91 window modes (settings_version 8): the Settings "Window mode" row and the window_mode field. First launch = borderless.
#macro WINDOW_MODE_WINDOWED 0
#macro WINDOW_MODE_BORDERLESS 1
#macro WINDOW_MODE_EXCLUSIVE 2
#macro WINDOW_MODE_COUNT 3
// Room left on the monitor's height for a windowed window's title bar, border and the taskbar (Display_WindowedMaxScale).
#macro DISPLAY_WINDOW_MARGIN_H 80
// D48 / D146 hold-to-skip, in ms: tapping confirm only advances text; holding the same key shows the "Hold to skip" prompt after SKIP_HINT_MS, fading in over SKIP_HINT_FADE_MS
// (and out again when the key is let go), and skips at SKIP_HOLD_MS. The bar fills from SKIP_HINT_MS to SKIP_HOLD_MS. One rule for every Skip_* user.
#macro SKIP_HOLD_MS 2000
#macro SKIP_HINT_MS 1000
#macro SKIP_HINT_FADE_MS 200
#macro SKIP_EDGE_SLACK_MS 0.1   // a hold within this of an edge counts as there: 60 steps of 33.333 ms make 1999.98
#macro BANNER_DURATION_MS 1000   // D106 boss name banner (D108 F2b-2: ms, was Banner_Frames(fps) = 1 s)
#macro SETTINGS_VOLUME_STEP 0.05

#macro TRANSITION_TYPE_NONE 0
#macro TRANSITION_TYPE_ROOM 1
#macro TRANSITION_TYPE_ENCOUNTER 2
#macro TRANSITION_TYPE_CUTSCENE 3
#macro TRANSITION_TYPE_FLASH 4
#macro TRANSITION_ROOM_FADE_OUT_FRAMES 12
#macro TRANSITION_ROOM_BLACK_HOLD_FRAMES 2
#macro TRANSITION_ROOM_FADE_IN_FRAMES 14
#macro TRANSITION_ENCOUNTER_ZOOM_FRAMES 36
#macro TRANSITION_ENCOUNTER_ZOOM_HOLD_FRAMES 6
#macro TRANSITION_ENCOUNTER_ZOOM_MAX 0.42
#macro TRANSITION_ENCOUNTER_SHAKE_PX 3
#macro TRANSITION_ENCOUNTER_FADE_OUT_FRAMES 22
#macro TRANSITION_ENCOUNTER_BLACK_HOLD_FRAMES 10
#macro TRANSITION_ENCOUNTER_FADE_IN_FRAMES 24
#macro TRANSITION_CUTSCENE_FADE_OUT_FRAMES 20
#macro TRANSITION_CUTSCENE_BLACK_HOLD_FRAMES 2
#macro TRANSITION_CUTSCENE_FADE_IN_FRAMES 22
#macro TRANSITION_FLASH_FADE_OUT_FRAMES 12
#macro TRANSITION_FLASH_FADE_IN_FRAMES 14
#macro TRANSITION_CLASS_SELECT_FADE_OUT_FRAMES 22
#macro TRANSITION_CLASS_SELECT_FADE_IN_FRAMES 24
#macro TRANSITION_CUTSCENE_SEGMENT_FADE_OUT_FRAMES 14
#macro TRANSITION_CUTSCENE_SEGMENT_FADE_IN_FRAMES 16
#macro TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_OUT_FRAMES 44
#macro TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_IN_FRAMES 52
#macro TRANSITION_LOADING_FADE_OUT_FRAMES 28
#macro TRANSITION_LOADING_BLACK_HOLD_FRAMES 18
#macro TRANSITION_LOADING_FADE_IN_FRAMES 32
// D108 (F2a): presentation timers run on a ms clock (Presentation_StepMs from delta_time). The *_FRAMES values above are 60 fps frame counts, kept as the
// design numbers and as the unit of Transition_RequestBlackFlash's arguments; Transition_FramesToMs turns one into milliseconds (12 frames = 200 ms).
#macro TRANSITION_FRAME_MS (1000 / 60)
#macro PRESENTATION_MAX_STEP_US 50000   // one frame never adds more than 50 ms to a presentation clock, so a hitch cannot skip a whole fade
#macro TRANSITION_DONE_SLACK_MS 1       // a phase ends when it is within this of its length, so 12 frames of 16.6 ms still make a 200 ms fade
#macro TRANSITION_EVT_NONE 0
#macro TRANSITION_EVT_ROOM_CHANGE 1     // the fade-out is black: leave the room now (the black hold starts with the next step, in the new room)
#macro TRANSITION_EVT_FLASH_BLACK 2     // a black flash is fully black: do its swap now
#macro TRANSITION_EVT_DONE 3            // the fade-in is over: the transition is finished
#macro TRANSITION_KIND_ZOOM 0           // phase kinds (Transition_PhaseKind)
#macro TRANSITION_KIND_ZOOM_HOLD 1
#macro TRANSITION_KIND_OUT 2
#macro TRANSITION_KIND_HOLD 3
#macro TRANSITION_KIND_IN 4
// Boot logo (obj_start_controller), 48 / 120 / 48 / 8 frames at 60 fps, and the cutscene logo fade (18 frames).
#macro BOOT_LOGO_FADE_IN_MS (48000 / 60)
#macro BOOT_LOGO_HOLD_MS (120000 / 60)
#macro BOOT_LOGO_FADE_OUT_MS (48000 / 60)
#macro BOOT_LOGO_BLACK_HOLD_MS (8000 / 60)
#macro CUTSCENE_LOGO_FADE_MS 300

#macro SAVE_SNAPSHOT_VERSION 2

// Build id (VER-10). tools/automation/run_tests.ps1 rewrites this line in its scratch copy only.
#macro BUILD_ID "dev"
