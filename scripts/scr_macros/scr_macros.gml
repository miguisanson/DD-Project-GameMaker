#macro RIGHT 0
#macro UP 1
#macro LEFT 2
#macro DOWN 3

#macro STAT_MIN 1
#macro STAT_MAX 60 // change to 99 if you want

#macro CLASS_ARCHER 0
#macro CLASS_KNIGHT 1
#macro CLASS_MAGE   2

#macro ENEMY_SLIME     0
#macro ENEMY_DIREWOLF  1
#macro ENEMY_GHOSTSWORD 2
#macro ENEMY_SPIDER 3
#macro ENEMY_MADWHISP 4

#macro TURN_PLAYER 0
#macro TURN_ENEMY  1

#macro BSTATE_MESSAGE       0
#macro BSTATE_MENU          1
#macro BSTATE_PLAYER_ATTACK 2
#macro BSTATE_PLAYER_RUN    3
#macro BSTATE_ENEMY_ACT     4
#macro BSTATE_END_RUN       5
#macro BSTATE_SKILL_MENU    6
#macro BSTATE_ITEM_MENU     7

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

#macro BATTLE_COOLDOWN_FRAMES 60

#macro ENEMY_IDLE   0
#macro ENEMY_ALERT  1

#macro ENEMY_SCAN_RADIUS_DEFAULT 32

#macro INTERACT_NONE       0
#macro INTERACT_CHEST      1
#macro INTERACT_DOOR       2
#macro INTERACT_SWITCH     3
#macro INTERACT_NPC        4
#macro INTERACT_CHECKPOINT 6

#macro NPC_OLD_MAN 0

#macro UI_NONE     0
#macro UI_DIALOGUE 1
#macro UI_MENU 2
#macro UI_SAVE 3
#macro UI_PAUSE 4
#macro UI_BAR_SCALE 3
#macro VFX_SPEED_MULT 1.0

#macro SHAKE_DIR_H 0
#macro SHAKE_DIR_V 1
#macro SHAKE_DIR_D 2

#macro ENEMY_SHAKE_MAG 0.3 // Enemy sprite shake magnitude (higher = wider shake)
#macro ENEMY_SHAKE_FRAMES 12 // Enemy shake duration in frames
#macro ENEMY_FLASH_FRAMES 12 // Enemy flash/blink duration in frames
#macro ENEMY_FLASH_RATE 3 // Enemy flash toggle rate (lower = faster blink)
#macro ENEMY_SHAKE_DIR SHAKE_DIR_H // Enemy shake direction (H/V/D)

#macro PLAYER_SHAKE_MAG 0.3
#macro PLAYER_SHAKE_FRAMES 12
#macro PLAYER_SHAKE_DIR SHAKE_DIR_V

#macro ACTION_BUFFER_FRAMES 6
#macro ACTION_COOLDOWN_FRAMES 4

#macro SPR_SPEED_FPS 0
#macro SPR_SPEED_FRAMES 1

#macro MENU_REPEAT_DELAY 12
#macro MENU_REPEAT_INTERVAL 4
#macro COMBAT_ACTION_DELAY 60
#macro COMBAT_LOG_MAX 30
