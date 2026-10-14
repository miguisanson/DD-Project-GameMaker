#macro RIGHT 0
#macro UP 1
#macro LEFT 2
#macro DOWN 3

#macro STAT_MIN 1
#macro STAT_MAX 60 // change to 99 if you want
#macro LEVEL_CAP 10 // final game cap
#macro LEVEL_CAP_TECHNICAL LEVEL_CAP
#macro LEVEL_EFFECTIVE_CAMPAIGN_CAP LEVEL_CAP

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

#macro STAT_STR  0
#macro STAT_AGI  1
#macro STAT_DEF  2
#macro STAT_INT  3
#macro STAT_LUCK 4

#macro ACTION_ATTACK 0
#macro ACTION_SKILL  1
#macro ACTION_ITEM   2
#macro ACTION_RUN    3

#macro ITEM_WEAPON     0
#macro ITEM_ARMOR      1
#macro ITEM_CONSUMABLE 2
#macro ITEM_KEY        3

#macro TGT_ENEMY       0
#macro TGT_SELF        1
#macro TGT_ALL_ENEMIES 2
#macro TGT_ALL_ALLIES  3
#macro TGT_ALL         4
// Relative target aliases for readability (especially enemy-authored skills).
#macro TGT_OPPONENT       TGT_ENEMY
#macro TGT_ALL_OPPONENTS  TGT_ALL_ENEMIES

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

#macro BATTLE_COOLDOWN_FRAMES 60
#macro MONSTER_SFX_GAIN 0.80

#macro ENEMY_IDLE   0
#macro ENEMY_ALERT  1

#macro ENEMY_SCAN_RADIUS_DEFAULT 32

#macro INTERACT_NONE       0
#macro INTERACT_CHEST      1
#macro INTERACT_DOOR       2
#macro INTERACT_SWITCH     3
#macro INTERACT_DIALOGUE   4
#macro INTERACT_CHECKPOINT 6

#macro UI_NONE     0
#macro UI_DIALOGUE 1
#macro UI_MENU 2
#macro UI_SAVE 3
#macro UI_PAUSE 4
#macro UI_CLASS_SELECT 5
#macro UI_BED 6
#macro UI_BAR_SCALE 3
#macro UI_FONT retro_gaming
#macro GRID_TILE_SIZE 16
#macro PLAYER_MOVE_SPEED_DEFAULT 1
#macro ENEMY_THINK_RATE_DEFAULT 15
#macro ENEMY_FORGET_DELAY_DEFAULT 30
#macro ENEMY_LEASH_MULT_DEFAULT 2
#macro ENEMY_WANDER_CHANCE_DEFAULT 4
#macro ENEMY_MOVE_SPEED_DEFAULT 1
#macro UI_OPENED_FRAME_NONE -1
#macro UI_POPUP_FADE_FRAMES 8
#macro UI_DIALOGUE_REOPEN_LOCK 1
#macro UI_DIALOGUE_CHARS_PER_SEC 60
#macro UI_DIALOGUE_ADVANCE_HOLD_SEC 0.75
#macro UI_DIALOGUE_STATE_REVEALING 0
#macro UI_DIALOGUE_STATE_HOLDING 1
#macro UI_DIALOGUE_STATE_READY 2
#macro UI_DIALOGUE_ARROW_FPS 2
#macro UI_DIALOGUE_ARROW_BOB_PX 2
#macro UI_HUD_HURT_FLASH_FRAMES 8
#macro UI_HUD_HURT_FLASH_ALPHA 0.70
#macro UI_STATUS_FALLBACK_TEXT_SCALE 0.45
#macro UI_TEXT_SCALE_BASE 2.00
#macro UI_TEXT_SCALE_MIN 1.00
#macro UI_TEXT_SCALE_MAX 4.00
#macro UI_DIALOGUE_BOX_MARGIN 8
#macro UI_DIALOGUE_BOX_HEIGHT 64
#macro UI_DIALOGUE_TEXT_PAD_X 8
#macro UI_DIALOGUE_TEXT_PAD_Y 8
#macro UI_DIALOGUE_TEXT_Y_WITH_SPEAKER 22
#macro UI_DIALOGUE_SPEAKER_Y 6
#macro UI_DIALOGUE_BOTTOM_PAD 10
#macro UI_CUTSCENE_DIALOGUE_TOP_RATIO 0.56
#macro UI_CUTSCENE_DIALOGUE_MIN_HEIGHT 44
#macro UI_CUTSCENE_TEXT_MARGIN_X 8
#macro UI_CUTSCENE_TEXT_SIDE_PAD_RATIO 0.08
#macro UI_CUTSCENE_TEXT_TOP_RATIO 0.70
#macro UI_CUTSCENE_TEXT_BOTTOM_PAD 8
#macro UI_CUTSCENE_TEXT_SHADOW_X 1
#macro UI_CUTSCENE_TEXT_SHADOW_Y 1
#macro UI_CUTSCENE_DIALOGUE_CHARS_PER_SEC 24
#macro UI_CUTSCENE_GAME_OVER_CHARS_PER_SEC 8
#macro UI_CUTSCENE_ADVANCE_BLOCK_FRAMES 2

#macro SHAKE_DIR_H 0
#macro SHAKE_DIR_V 1
#macro SHAKE_DIR_D 2

#macro ENEMY_SHAKE_MAG 0.3
#macro ENEMY_SHAKE_FRAMES 12
#macro ENEMY_FLASH_FRAMES 12
#macro ENEMY_FLASH_RATE 3
#macro ENEMY_SHAKE_DIR SHAKE_DIR_H

#macro PLAYER_SHAKE_MAG 0.3
#macro PLAYER_SHAKE_FRAMES 12
#macro PLAYER_SHAKE_DIR SHAKE_DIR_V

#macro ACTION_BUFFER_FRAMES 6
#macro ACTION_COOLDOWN_FRAMES 4

#macro SPR_SPEED_FPS 0
#macro SPR_SPEED_FRAMES 1

#macro UI_NAV_REPEAT_DELAY 4
#macro UI_NAV_REPEAT_RATE 2
#macro MENU_REPEAT_DELAY 4
#macro MENU_REPEAT_INTERVAL 2
#macro SETTINGS_HOLD_REPEAT_DELAY 10
#macro SETTINGS_HOLD_REPEAT_INTERVAL 5
#macro COMBAT_ACTION_DELAY 60   // long hold: battle intro, kill and run-away messages
#macro COMBAT_ACTION_HOLD_SEC 0.3   // D55: hold after a player or enemy action, in seconds (use Combat_SecToFrames)
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
#macro QTE_ZONE_CENTRE_PCT 70      // the bright zone's centre, in percent of the sweep
#macro QTE_LEAD_IN_MS 250          // the bar is up and the cursor is parked at 0 before the sweep starts
#macro QTE_EARLY_BUFFER_MS 80      // a press this close before the sweep starts is kept (judged at 0); earlier ones are dropped
#macro QTE_MAX_STEP_US 50000       // one frame never adds more than 50 ms to the clock, so a hitch cannot skip the bar
#macro QTE_RESULT_MS 700           // how long the grade word stays up
#macro QTE_HITSTOP_PERFECT_MS 60   // D61 feedback: freeze on a Perfect hit
#macro QTE_SHAKE_PERFECT_MAG 0.8   // camera shake (world px), subtle: PLAYER_SHAKE_MAG is 0.3
#macro QTE_SHAKE_PERFECT_FRAMES 10
#macro QTE_SHAKE_GOOD_MAG 0.4
#macro QTE_SHAKE_GOOD_FRAMES 8
#macro QTE_BAR_W 96                // bar size in base units (the picture is 160 x 144)
#macro QTE_BAR_H 8
#macro QTE_COL_DARKEST $211807     // the four palette colours (D10) as GameMaker BGR: #071821 #306850 #86C06C #E0F8CF
#macro QTE_COL_DARK $506830
#macro QTE_COL_LIGHT $6CC086
#macro QTE_COL_LIGHTEST $CFF8E0
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
#macro PLAYER_HP_DEF_BONUS_FACTOR 0.25
#macro ENEMY_SKILL_USE_CHANCE_DEFAULT 0.35
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
// D48 hold-to-skip: frames of holding confirm (1.0 s at 60 fps) and how long the "hold to skip" hint stays after a press.
#macro SKIP_HOLD_FRAMES 60
#macro SKIP_HINT_FRAMES 150
#macro SETTINGS_VOLUME_STEP 0.05
#macro SETTINGS_MENU_ROW_COUNT 8
#macro AUDIO_DEBUG_TOOLS 0

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
// Frames the "Yes" option is greyed out / locked after the class confirm prompt
// appears (~2s at 60fps), so the player can't accidentally accept the wrong class.
#macro CLASS_SELECT_CONFIRM_ACCEPT_DELAY 120
#macro TRANSITION_CUTSCENE_SEGMENT_FADE_OUT_FRAMES 14
#macro TRANSITION_CUTSCENE_SEGMENT_FADE_IN_FRAMES 16
#macro TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_OUT_FRAMES 44
#macro TRANSITION_CUTSCENE_SEGMENT_SLOW_FADE_IN_FRAMES 52
#macro TRANSITION_LOADING_FADE_OUT_FRAMES 28
#macro TRANSITION_LOADING_BLACK_HOLD_FRAMES 18
#macro TRANSITION_LOADING_FADE_IN_FRAMES 32
#macro CUTSCENE_LAST_SCENE_HOLD_FRAMES 90

#macro SAVE_SNAPSHOT_VERSION 2

// Build id (VER-10). tools/automation/run_tests.ps1 rewrites this line in its scratch copy only.
#macro BUILD_ID "dev"
