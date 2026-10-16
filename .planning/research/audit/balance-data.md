# Combat balance data and formulas (audit)

Generated 2026-10-13 from `scripts/scr_db_*`, `scr_stats`, `scr_levelup`, `scr_combat`, `scr_status`, `scr_loot`, `scr_equip`, `scr_macros`, `scr_player` (Difficulty_Profile), `scr_enemy`, read-only. Line numbers are for the working tree at `v1.8` HEAD `0b6e2f8`.

Companion CSVs (same folder, `data/`): `skills.csv`, `enemies.csv`, `classes.csv`, `items.csv` (requested) plus `enemy_levels.csv`, `progression.csv`, `status.csv`, `difficulty.csv` (extras for simulation).

How to read the confidence tags: **[code]** = read directly from source; **[calc]** = exact arithmetic on code values (python, exhaustive d20 enumeration); **[model]** = Monte-Carlo re-implementation of the battle loop with stated assumptions (not run in the game); **[inferred]** = depends on a GameMaker behaviour I could not run here.

There is **no gold / currency / shop** anywhere in the code (`grep gold|coin|shop` finds nothing; item `value` is read only by `Equip_FindStarterWeaponId`, scr_equip.gml:508). The enemy 'gold' column therefore does not exist; rewards are EXP + one loot roll.

## 1. Constants and difficulty

Key macros (`scr_macros.gml`): `STAT_MIN 1` / `STAT_MAX 60` (L6-7; clamp in `StatClamp`, scr_math.gml:2), `LEVEL_CAP 10` (L8), `PLAYER_SKILL_HIT_BONUS 4` (L213), `PLAYER_HP_DEF_BONUS_FACTOR 0.25` (L248), `ENEMY_SKILL_USE_CHANCE_DEFAULT 0.35` (L249), `ENEMY_ACTION_CHAIN_MAX 3` (L250), `ENEMY_AUTO_RESOLVE_LEVEL_DELTA 3` (L251), `COMBAT_ACTION_DELAY 60` frames (L207), `SKILL_FX_SPEED_MULT 2.5` / `PLAYER_SKILL_FX_SPEED_MULT 6.0` / `..._NON_ENEMY 3.0` / `PLAYER_SKILL_FX_SPEED_MAX 1.3` (L209-212), attack-timing and defensive-QTE tuning (L218-247).

Game speed is 60 (`options/main/options_main.yy`: `option_game_speed:60`).

### Difficulty profile (`Difficulty_Profile`, scr_player.gml:64-113)

| difficulty | player HP | player MP | enemy HP | enemy MP | player dmg | enemy dmg | enemy status chance | player EXP |
|---|---|---|---|---|---|---|---|---|
| easy | 1.15 | 1.05 | 0.9 | 0.95 | 1.08 | 0.9 | 0.9 | 1.2 |
| normal | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 |
| hard | 0.92 | 0.95 | 1.12 | 1.0 | 0.94 | 1.12 | 1.08 | 0.85 |

- `player_stat_mult` and `enemy_stat_mult` exist in all three profiles but nothing reads them (grep over *.gml finds only the definitions). Dead.
- Where each is applied: player HP/MP `RecomputeResources` scr_stats.gml:42-46; enemy HP/MP `EnemyCreate` scr_enemy.gml:312-313; damage `Combat_ApplyDamage` scr_combat.gml:102-103 via `Combat_EffectiveDamageMult` scr_combat.gml:9-15; enemy status chance `Skill_Use` scr_db_skill.gml:1148-1150 (damage skills only); EXP `Battle_GrantRewards` scr_combat.gml:266-273 and `Enemy_AutoResolveFinalize` scr_enemy.gml:130-134.
- **Damage multipliers are applied with `floor()` on small integers, so they are mostly no-ops or flat -1/+0** [calc]: final = floor(dmg x mult).

| dmg | x0.90 (Easy enemy) | x0.94 (Hard player) | x1.08 (Easy player) | x1.12 (Hard enemy) |
|---|---|---|---|---|
| 1 | 0 | 0 | 1 | 1 |
| 2 | 1 | 1 | 2 | 2 |
| 3 | 2 | 2 | 3 | 3 |
| 4 | 3 | 3 | 4 | 4 |
| 5 | 4 | 4 | 5 | 5 |
| 6 | 5 | 5 | 6 | 6 |
| 7 | 6 | 6 | 7 | 7 |
| 8 | 7 | 7 | 8 | 8 |
| 9 | 8 | 8 | 9 | 10 |
| 10 | 9 | 9 | 10 | 11 |
| 12 | 10 | 11 | 12 | 13 |
| 13 | 11 | 12 | 14 | 14 |
| 16 | 14 | 15 | 17 | 17 |
| 17 | 15 | 15 | 18 | 19 |

Enemy hits in this game are 1-8 damage, so Hard's x1.12 enemy damage changes nothing below 9 damage, and Easy's x1.08 player damage changes nothing below 13. The real difficulty levers are the HP multipliers and the flat -1 on Hard player hits / Easy enemy hits.

## 2. Classes, stats, HP/MP, growth

Base stats are `{str:10, agi:10, def:10, intt:10, luck:10}` for every class (`StatsCreateBase`, scr_stats.gml:1-3) plus the class start bonus (`DB_PlayerClass`, scr_db_player_class.gml:1-27; applied in `CharacterCreate_Player`, scr_player.gml:1-34). Stat modifier is D&D style: `StatMod(s) = floor((s-10)/2)` (scr_math.gml:3).

Growth per level (`LevelUp_ClassGrowthGain`, scr_levelup.gml:52-74; stat points were removed, growth is automatic):
- Knight: STR +1 every level, DEF +1 on even levels.
- Archer: AGI +1 every level, LUCK +1 on even levels.
- Mage: INT +1 every level, LUCK +1 on even levels.
- Nobody: rotates 5 two-stat rows by `(lvl-2) mod 5`: STR+AGI, DEF+INT, INT+LUCK, STR+DEF, AGI+LUCK. Nobody has no skills and cannot learn skillbooks (`Item_SkillbookValidate`, scr_db_item.gml:824-827).

| class | hd | mp_gain | start bonus | HP/level (ceil(hd/2)+2) | weapon stat | skillbook pool (5 books) |
|---|---|---|---|---|---|---|
| Knight | 10 | 1 | STR+1 DEF+2 | 7 | STR | Wound, Hilt Bash, Muscle Up, Rev Up, Horizontal Slash |
| Archer | 8 | 2 | AGI+2 LUCK+1 | 6 | AGI | Wound, Poison Arrow, Evasion, Double Shot, Take Aim |
| Mage | 6 | 2 | INT+2 LUCK+1 | 5 | INT | Fireball, Poison Mist, Ice Spear, Meditation, Foresight |
| Nobody | 8 | 1 | none | 6 | - | none |

Resources (`RecomputeResources`, scr_stats.gml:22-52):
- `max_hp = base_hp(10) + (lvl-1) * (ceil(hd/2)+2) + max(0, floor(max(0, StatMod(DEF)) * 0.25))`, then x `player_hp_mult`, rounded. Uses raw `stats.def` only (no equipment). The DEF term is 0 until DEF 18 (mod 4).
- `max_mp = base_mp(10) + (lvl-1) * mp_gain + StatMod(INT) * (1 + floor((lvl-1)/4))`, then x `player_mp_mult`. Uses raw INT (robes do not add MP).
- Level-up only adds the *delta* of max HP/MP to current HP/MP (scr_levelup.gml:105-106), it is not a full heal. Full heal only at the bed/save menu (`Save_HealPlayerToFull`, scr_save.gml:406; called scr_save_menu.gml:352) or potions. There is no regeneration.

Stats shown STR/AGI/DEF/INT/LUCK then Normal-difficulty HP/MP (no equipment):

| lvl | Knight | Archer | Mage | EXP to next |
|---|---|---|---|---|
| 1 | 11/10/12/10/10  HP 10 MP 10 | 10/12/10/10/11  HP 10 MP 10 | 10/10/10/12/11  HP 10 MP 11 | 15 |
| 2 | 12/10/13/10/10  HP 17 MP 11 | 10/13/10/10/12  HP 16 MP 12 | 10/10/10/13/12  HP 15 MP 13 | 30 |
| 3 | 13/10/13/10/10  HP 24 MP 12 | 10/14/10/10/12  HP 22 MP 14 | 10/10/10/14/12  HP 20 MP 16 | 50 |
| 4 | 14/10/14/10/10  HP 31 MP 13 | 10/15/10/10/13  HP 28 MP 16 | 10/10/10/15/13  HP 25 MP 18 | 75 |
| 5 | 15/10/14/10/10  HP 38 MP 14 | 10/16/10/10/13  HP 34 MP 18 | 10/10/10/16/13  HP 30 MP 24 | 105 |
| 6 | 16/10/15/10/10  HP 45 MP 15 | 10/17/10/10/14  HP 40 MP 20 | 10/10/10/17/14  HP 35 MP 26 | 140 |
| 7 | 17/10/15/10/10  HP 52 MP 16 | 10/18/10/10/14  HP 46 MP 22 | 10/10/10/18/14  HP 40 MP 30 | 180 |
| 8 | 18/10/16/10/10  HP 59 MP 17 | 10/19/10/10/15  HP 52 MP 24 | 10/10/10/19/15  HP 45 MP 32 | 225 |
| 9 | 19/10/16/10/10  HP 66 MP 18 | 10/20/10/10/15  HP 58 MP 26 | 10/10/10/20/15  HP 50 MP 41 | 275 |
| 10 | 20/10/17/10/10  HP 73 MP 19 | 10/21/10/10/16  HP 64 MP 28 | 10/10/10/21/16  HP 55 MP 43 | - |

## 3. XP / level curve and XP supply

`Exp_NextLevel` (scr_levelup.gml:166-183): L1->2 15, L2->3 30, L3->4 50, L4->5 75, L5->6 105, L6->7 140, L7->8 180, L8->9 225, L9->10 275 (cumulative to L10 = 1095). Level cap 10: EXP is zeroed at cap (scr_levelup.gml:197-201, 215-218).

EXP gain per kill = `round(enemy.exp * clamp(1 + (enemy_level - base_level)*0.10, 0.70, 1.40))` (EnemyCreate scr_enemy.gml:322-323), then x `player_exp_mult`, min 1 (scr_combat.gml:266-273). Auto-resolved fights (non-boss, threat_rank 1, `can_auto_resolve`, player level >= enemy level + 3, scr_enemy.gml:36-42) give only 0.35x EXP (`auto_resolve_exp_mult`) and 0.70-0.90x loot chance.

Enemy level per spawn = clamp(zone_level + irandom_range(-1,1) + offset, species_min, species_max) (`Enemy_ResolveLevel`, scr_enemy.gml:18-34); zone = floor number (`Enemy_ZoneLevelForRoom`, scr_enemy.gml:1-16; rm_floor6_5 = 6, rm_floor9_5 = 10); bosses are fixed at base level.

**XP supply if every placed enemy is killed once** [calc] (enemies per room counted from the `.yy` instance lists; regular enemies respawn after every save, `Save_Write` -> `Enemy_ResetAll`, scr_save.gml:392-394, so the numbers below are a floor, not a ceiling):

| floor | enemies placed | EXP this floor | cumulative | level after clearing (+EXP into next) | level on entering |
|---|---|---|---|---|---|
| 1 | Slime | 8 | 8 | L1 (+8) | L1 |
| 2 | Dire Wolf, Slime | 22 | 30 | L2 (+15) | L1 |
| 3 | Snake, Spider | 20 | 50 | L3 (+4) | L2 |
| 4 | Dire Wolf, Killer Plant | 57 | 106 | L4 (+11) | L3 |
| 5 | Dire Wolf, Palehorn, Snake | 103 | 210 | L5 (+39) | L4 |
| 6 | Ghost Sword, Mad Whisp, Slime | 149 | 358 | L6 (+83) | L5 |
| 7 | Ghost Sword, Mad Whisp, Spider, Stranger | 136 | 494 | L7 (+79) | L6 |
| 8 | Mad Whisp, Stranger | 89 | 583 | L7 (+168) | L7 |
| 9 | Stranger | 58 | 641 | L8 (+46) | L7 |
| 9.5 | The Pale Choirbeast | 110 | 751 | L8 (+156) | L8 |

Total supply incl. both bosses is about 751 EXP; level 10 needs 1095. **A single clean pass tops out at level 8** (156/225 into level 9) and the final boss (L10) is met at level 8. Level 10 is only reachable by grinding respawns. Floors 3 (20 EXP) and 9 (58 EXP) barely move the bar; floors 5-7 supply 103-149 each.

## 4. Skills

27 skill records exist (`SkillDB_Init`, scr_db_skill.gml:1-668); `SKILL_POWER_STRIKE` (id 0) is a macro + localization key but has **no DB record** (falls through to the 'Unknown' stub in `SkillDB_Get`, L670-705). Player skills are learned only from skillbooks (`Player_DefaultSkills` returns `[]`, scr_player.gml:37-39).

There is **no element / damage-type field** anywhere (no fire/ice resistances, no weaknesses); the statuses Burn/Poison/Bleed/Stun are the only 'elements'. There is also no stored hit-chance: hit chance is computed per roll (formula in section 7; ready-made values in `skills.csv` columns `p_hit_*`). Damage formula inputs are only `power`, `power_mult`, `hits`, `stat_type`, `acc`: the equipped weapon's power is NOT used for skills (scr_db_skill.gml:1120). Player skills get `+PLAYER_SKILL_HIT_BONUS (4)` on top of `acc + StatMod(stat)` (scr_db_skill.gml:1112-1113). Enemy skills do not.

**Player skills** (turns column = base -> what the game really applies [code: `Skill_AdjustStatusTurns`, scr_db_skill.gml:854-888]; the tooltip prints the base number, scr_menu.gml:337-351):

| id | name | class | MP | effect | stat | power | x | hits | acc used (incl +4) | status | chance | turns base->real | fx sprite | image_speed | fx length [inferred] |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Wound | Knight/Archer | 3 | damage | STR | 4 | 1 | 1 | 4 | Bleeding | 75% | 2 -> 5 | bleed_effect (12f native) | 1.2 | 1.25 s |
| 2 | Hilt Bash | Knight | 4 | damage | STR | 4 | 1 | 1 | 4 | Stun | 60% | 1 -> 1 | stun_effect (9f native) | 1.3 | 0.86 s |
| 3 | Muscle Up | Knight | 3 | status | STR | 0 | 1 | 0 | - | Guard | 100% | 2 -> 6 | muscle_up_effect (7f native) | 0.6 | 1.46 s |
| 4 | Rev Up | Knight | 3 | status | STR | 0 | 1 | 0 | - | Rev Up | 100% | 2 -> 6 | rev_up_effect (10f native) | 0.6 | 2.08 s |
| 5 | Horizontal Slash | Knight | 5 | damage | STR | 5 | 1.5 | 1 | 4 | - | - | - | horizontal_slash_effect (5f native) | 1.2 | 0.52 s |
| 6 | Poison Arrow | Archer | 4 | damage | AGI | 5 | 1 | 1 | 5 | Poison | 75% | 2 -> 5 | poison_shot_effect (12f native) | 1.2 | 1.25 s |
| 7 | Evasion | Archer | 3 | status | AGI | 0 | 1 | 0 | - | Evasion | 100% | 2 -> 6 | evasion_up_effect (9f native) | 0.6 | 1.88 s |
| 8 | Double Shot | Archer | 5 | damage | AGI | 4 | 1 | 2 | 4 | - | - | - | double_shot_effect (7f native) | 1.2 | 0.73 s |
| 9 | Take Aim | Archer | 3 | status | AGI | 0 | 1 | 0 | - | Take Aim | 100% | 3 -> 9 | take_aim_effect (12f native) | 0.6 | 2.5 s |
| 10 | Fireball | Mage | 4 | damage | INT | 6 | 1 | 1 | 4 | Burning | 60% | 2 -> 5 | explosion_effect (9f native) | 1.2 | 0.94 s |
| 11 | Poison Mist | Mage | 4 | damage | INT | 4 | 1 | 1 | 4 | Poison | 75% | 2 -> 5 | poison_mist_effect (8f native) | 1.2 | 0.83 s |
| 12 | Ice Spear | Mage | 5 | damage | INT | 5 | 1 | 1 | 4 | Stun | 60% | 1 -> 1 | ice_spear_effect (12f native) | 1.3 | 1.15 s |
| 13 | Meditation | Mage | 3 | status | INT | 0 | 1 | 0 | - | Meditation | 100% | 3 -> 9 | meditation (11f native) | 0.6 | 2.29 s |
| 14 | Foresight | Mage | 3 | status | INT | 0 | 1 | 0 | - | Foresight | 100% | 3 -> 9 | foresight_effect_Sheet (10f native) | 0.6 | 2.08 s |

Notes: `fx length` = native_frames / (image_speed * 8 fps native / 60) assuming GameMaker's `image_speed` is a multiplier of the sprite's native 8 fps (all 14 player-skill fx sprites are 48x48, 8 fps, `playbackSpeedType` 0). Relative ordering holds regardless of that assumption. Self-buff skills run at image_speed 0.6 (0.2 x 3.0, scr_db_skill.gml:918-921), enemy-targeted at 1.2 (0.2 x 6.0) clamped to 1.3 (L928-930); Hilt Bash and Ice Spear have `player_fx_speed_mult: 6.5` = 1.3 = the cap.

**Enemy skills** (all `mp_cost 0`; enemy MP is never checked: `Skill_CanUse` only checks MP for players, scr_db_skill.gml:769-776):

| id | name | user | effect | stat | power | hits | acc | status | chance | turns (enemy->player, before QTE) | def QTE | use chance | conditions |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 15 | Poison Fangs | Spider | damage | STR | 2 | 1 | 0 | Poison | 70% | 4 | yes | 0.1-0.25 | - |
| 16 | Solidify | Slime | status | DEF | 0 | 0 | 0 | Solidify | 100% | 2 | no | 0.1-0.25 | only if no Solidify |
| 17 | Bite | Snake | damage | STR | 2 | 1 | 0 | Bleeding | 75% | 4 | yes | 0.25-0.3 | - |
| 18 | Bloodthirsty | Dire Wolf | status | STR | 0 | 0 | 0 | Bloodthirsty | 100% | 4 | no | 0.2-0.3 | only if no Bloodthirsty |
| 19 | Vine Trap | Killer Plant | damage | STR | 2 | 1 | 0 | Stun | 65% | 1 | yes | 0.2-0.2 | - |
| 20 | Scorching Touch | Mad Whisp | damage | INT | 3 | 1 | 0 | Burning | 70% | 4 | yes | 0.4-0.4 | - |
| 21 | Cut | Ghost Sword | damage | STR | 3 | 1 | 0 | Bleeding | 80% | 4 | yes | 0.5-0.5 | - |
| 22 | Steal | Stranger | steal_item | AGI | 0 | 0 | 0 | - | - | - | no | 0.1-0.2 | needs player items |
| 23 | Ramming | Palehorn | damage | STR | 4 | 1 | 0 | Bleeding | 60% | 4 | yes | 0.4-0.4 | - |
| 24 | Rampage | Palehorn | status | STR | 0 | 0 | 0 | - | - | - | no | 0.18-0.24 | HP<=0.8; once/turn; actions<2; FREE action; sets actions=2 |
| 25 | Curse | The Pale Choirbeast | multi_status | INT | 0 | 0 | 0 | Burning/Poison/Bleeding | 50% | 2/2/2 | no | 0.3-0.3 | HP<=0.7; once/turn |
| 26 | Blessing | The Pale Choirbeast | status | DEF | 0 | 0 | 0 | Blessing | 100% | 4 | no | 0.25-0.25 | HP<=0.8; once/turn; only if no Blessing; FREE action |
| 27 | Fury | The Pale Choirbeast | status | STR | 0 | 0 | 0 | - | - | - | no | 0.35-0.35 | HP<=0.45; once/turn; actions<2; FREE action; sets actions=2 |

Enemy skill selection (`Battle_EnemyChooseSkill`, scr_combat.gml:847-879): each eligible skill independently passes with probability `random_range(min,max)` (`Skill_EnemyUseChance`, scr_db_skill.gml:803-814); one passing skill is picked uniformly; an enemy cannot use a skill on the action right after a skill (`enemy_last_action_used_skill`, scr_combat.gml:1449). So realistic skill frequency is below the listed chance.

### Status effects (`StatusDB_Init`, scr_status.gml:118-267)

| id | name | tick | stat mods | flags | multipliers | applying it removes |
|---|---|---|---|---|---|---|
| 0 | Poison | HP -3..-2  | INT-1 | - | - | Bleeding/Burning |
| 1 | Bleeding | HP -4..-2  | AGI-2 | - | - | Poison/Burning |
| 2 | Burning | HP -6..-4  | STR-1 | - | - | Bleeding/Poison |
| 3 | Stun | - | AGI-2 | skip_turn | - | - |
| 4 | Guard | - | - | consume_on_hit | {guard_mult: 0} | - |
| 5 | Rev Up | - | - | consume_on_attack | {dmg_mult: 2} | - |
| 6 | Evasion | - | - | force_dodge/consume_on_defend | - | - |
| 7 | Take Aim | - | - | - | {crit_bonus: 25} | - |
| 8 | Foresight | - | - | always_hit/consume_on_attack | - | - |
| 9 | Meditation | MP +2..4 | - | - | - | - |
| 10 | Solidify | - | - | force_dodge/consume_on_defend | - | - |
| 11 | Bloodthirsty | - | - | consume_on_hit | {guard_mult: 0.65, dmg_mult: 1.06} | - |
| 12 | Blessing | - | - | consume_on_hit | {guard_mult: 0.8} | - |
| 13 | Sundered | - | DEF-1 | - | - | - |

Adding a status (`Status_Add`, scr_status.gml:375-405): DoTs remove each other (Poison/Bleed/Burn mutually exclusive); non-stackable re-apply takes `max(old_turns, new_turns)`; the player can never be stunned while `stun_immune_turns > 0` and any landed stun is capped at 1 turn (L382-387); after a stun-skip the player gets `stun_immune_turns = 2` (scr_combat.gml:460).
Tick (`Status_Tick`, scr_status.gml:471-517): for each status apply HP/MP delta `irandom_range(min,max)` then `turns -= 1`; remove at 0. **Ticks happen per owner action, not per round**: the player ticks once at the end of each of his own actions (`Battle_PlayerFinalizeTurn`, scr_combat.gml:470-492, so free/bonus actions tick too), an enemy ticks once when its whole turn ends (`Battle_EnemyFinalizeTurnState`, scr_combat.gml:1074-1100) or when it is stunned (scr_combat.gml:1434-1442). Not ticked: a failed Run (scr_combat.gml:779-804), a killing blow (CheckEnd runs first), a skill refused for MP.

Player-applied durations in effect (`Skill_AdjustStatusTurns`): DoTs `clamp(max(3, round(base*3)), 3, 5)` -> base 2 becomes **5 ticks** (+1 with Ember Lens / Silk Flow before the clamp); stun stays at base (1); every other status `max(2, round(base*3))` -> Guard/Rev Up/Evasion 2->**6**, Take Aim/Foresight/Meditation 3->**9**. Enemy-applied: DoTs `clamp(max(2, round(base*2)), 2, 5)`, others `max(2, base*2)`; then, **for enemy damage skills with a defensive QTE, the duration on the player is overwritten** with `max(1, round(base_turns * (1 + 3*(1 - success_ratio))))` (never lower than the current value, scr_combat.gml:1172-1230): all prompts hit -> 2 ticks, none -> 8 ticks; stun is removed entirely if every prompt succeeds (`DEF_QTE_STATUS_STUN_BLOCK_RATIO 1.0`).

## 5. Enemies

Enemy record fields: `stats {str,agi,def,intt,luck}`, `base_hp`, `hd`, `base_mp`, `mp_gain`, `exp`, `threat_rank`, `loot_key`, `skills`, `ai`. Enemy stats do **not** scale with level; only HP, MP and EXP do (`EnemyCreate`, scr_enemy.gml:269-330). `weapon_id` is 0 for all, so the basic attack is the hard-coded `{power:2, STR, acc:0}` (obj_battle_controller/Create_0.gml:151-154). HP: `base_hp + (lvl-1)*(ceil(hd/2)+1) + max(0, StatMod(DEF))`, x `enemy_hp_mult` (scr_enemy.gml:306-313). Enemy MP/INT is dead except where an enemy skill uses INT as its damage stat (Scorching Touch): no enemy skill costs MP.

| enemy | floors | levels per floor | STR/AGI/DEF/INT/LUCK | base HP | EXP | rank | skills | def QTE prompts | auto-resolve | loot key chance(L1/L2/L3+) |
|---|---|---|---|---|---|---|---|---|---|---|
| Slime | F1,F2,F6 | F1:1 F2:1 F6:1 | 8/9/7/5/7 | 9 (hd 7, +5/lvl) | 8 | 1 | Solidify | 1 | true | enemy_basic 0.2/0.3/0.4 |
| Spider | F3,F7 | F3:2/3 F7:3 | 8/10/7/5/7 | 10 (hd 7, +5/lvl) | 8 | 1 | Poison Fangs | 1 | true | enemy_basic 0.2/0.3/0.4 |
| Snake | F3,F5 | F3:2/3/4 F5:4 | 9/10/7/5/7 | 10 (hd 7, +5/lvl) | 10 | 1 | Bite | 1 | true | enemy_basic 0.2/0.3/0.4 |
| Mad Whisp | F6,F7,F8 | F6:5/6/7 F7:6/7 F8:7 | 10/12/9/13/10 | 12 (hd 6, +4/lvl) | 28 | 2 | Scorching Touch | 1-3 | false | enemy_mid 0.3/0.45/0.6 |
| Killer Plant | F4 | F4:4/5 | 12/9/11/10/8 | 14 (hd 8, +5/lvl) | 20 | 2 | Vine Trap | 1-3 | false | enemy_mid 0.3/0.45/0.6 |
| Dire Wolf | F2,F4,F5 | F2:3 F4:3/4/5 F5:4/5 | 11/11/9/6/8 | 12 (hd 7, +5/lvl) | 14 | 1 | Bloodthirsty | 1 | true | enemy_mid 0.3/0.45/0.6 |
| Ghost Sword | F6,F7 | F6:6/7 F7:6/7/8 | 14/12/12/10/11 | 14 (hd 8, +5/lvl) | 38 | 2 | Cut | 1-3 | false | enemy_mid 0.3/0.45/0.6 |
| Stranger | F7,F8,F9 | F7:7/8 F8:7/8/9 F9:8/9 | 16/13/14/15/12 | 16 (hd 8, +5/lvl) | 50 | 2 | Steal | 1-3 | false | enemy_elite 0.55/0.75/0.95 |
| Palehorn | F5 | F5:8 | 18/12/16/14/12 | 22 (hd 10, +6/lvl) | 75 | 3 | Ramming/Rampage | 3-5 | false | enemy_boss 1/1/1 |
| The Pale Choirbeast | F9_5 | F10:10 | 21/14/18/19/14 | 30 (hd 10, +6/lvl) | 110 | 4 | Curse/Blessing/Fury | 3-5 | false | enemy_boss 1/1/1 |

HP / EXP / mods by level (Normal; Easy x0.9, Hard x1.12 on HP) - from `enemy_levels.csv`:

| enemy | level | HP normal | HP easy | HP hard | EXP | STR/AGI/DEF mod |
|---|---|---|---|---|---|---|
| Slime | 1 | 9 | 8 | 10 | 8 | -1/-1/-2 |
| Spider | 2 | 15 | 14 | 17 | 8 | -1/0/-2 |
| Spider | 3 | 20 | 18 | 22 | 9 | -1/0/-2 |
| Snake | 2 | 15 | 14 | 17 | 10 | -1/0/-2 |
| Snake | 3 | 20 | 18 | 22 | 11 | -1/0/-2 |
| Snake | 4 | 25 | 22 | 28 | 12 | -1/0/-2 |
| Mad Whisp | 5 | 28 | 25 | 31 | 28 | 0/1/-1 |
| Mad Whisp | 6 | 32 | 29 | 36 | 31 | 0/1/-1 |
| Mad Whisp | 7 | 36 | 32 | 40 | 34 | 0/1/-1 |
| Killer Plant | 4 | 29 | 26 | 32 | 20 | 1/-1/0 |
| Killer Plant | 5 | 34 | 31 | 38 | 22 | 1/-1/0 |
| Killer Plant | 6 | 39 | 35 | 44 | 24 | 1/-1/0 |
| Dire Wolf | 3 | 22 | 20 | 25 | 14 | 0/0/-1 |
| Dire Wolf | 4 | 27 | 24 | 30 | 15 | 0/0/-1 |
| Dire Wolf | 5 | 32 | 29 | 36 | 17 | 0/0/-1 |
| Ghost Sword | 6 | 40 | 36 | 45 | 38 | 2/1/1 |
| Ghost Sword | 7 | 45 | 40 | 50 | 42 | 2/1/1 |
| Ghost Sword | 8 | 50 | 45 | 56 | 46 | 2/1/1 |
| Stranger | 7 | 48 | 43 | 54 | 50 | 3/1/2 |
| Stranger | 8 | 53 | 48 | 59 | 55 | 3/1/2 |
| Stranger | 9 | 58 | 52 | 65 | 60 | 3/1/2 |
| Palehorn | 8 | 67 | 60 | 75 | 75 | 4/1/3 |
| Palehorn | 9 | 73 | 66 | 82 | 82 | 4/1/3 |
| The Pale Choirbeast | 10 | 88 | 79 | 99 | 110 | 5/2/4 |

Enemy basic-attack hit chance vs player and damage: `Combat_AttackBonus` = StatMod(STR) (weapon acc 0), dodge = StatMod(player AGI); damage `max(1, 2 + StatMod(STR) - floor(StatMod(player DEF)/2))`. Knight/Archer/Mage have AGI mod 0 / +1..+5 / 0, so enemy hit chance on a Knight rises from 48% (slime) to 74% (final boss) [calc].

Enemy action economy: one action per turn; `Rampage` (Palehorn, HP<=80%, 18-24%) and `Fury` (final boss, HP<=45%, 35%) are free actions that set the action budget to 2 (so two more damaging actions that turn); `Blessing` (final boss, HP<=80%) is free; boss statuses `Bloodthirsty` x0.65 incoming / x1.06 outgoing until hit, `Blessing` x0.8 incoming until hit (`guard_mult`, consumed by the next hit).

Defensive QTE on enemy damage skills (`uses_defensive_qte`): prompt count by threat rank 1 -> 1, 2 -> 1-3, 3 -> 2-4, boss/rank 4 -> 3-5 (scr_combat.gml:978-985); each success reduces that skill's damage up to 50% total (`DEF_QTE_DAMAGE_REDUCTION_MAX`, L1245); response window `2.0 s / (1.15 + 0.08*(rank-1))` per prompt, capped at x1.45 (L987-992, L1147-1150). Enemy **basic attacks have no QTE**.

## 6. Items, equipment, loot

37 items (`ItemDB_Init`, scr_db_item.gml:1-703). All weapon/armor `bonus` structs are zero except armor DEF/INT; weapon `acc` is displayed in tooltips but **never enters a player hit roll** (basic attacks bypass `Combat_AttemptHit`; skills use skill.acc). Stats via equipment reach combat through `Equip_GetStatBonus` (scr_equip.gml:88-111) into `Stat_Get`.

Weapons:

| id | name | class | stat | power | acc | passive | chest loot | enemy loot |
|---|---|---|---|---|---|---|---|---|
| 1 | Wooden Sword | Knight | STR | 3 | 0 | MISS->BAD, BAD->OKAY (1/turn) | w8/tier1/qty0-1 |  |
| 2 | Iron Sword | Knight | STR | 6 | 0 | 1st hit: -1 DEF for 2 turns | w7/tier2/qty0-1 | w4/tier2/qty0-1 |
| 3 | Platinum Sword | Knight | STR | 9 | 1 (dead) | +35% damage vs <35% HP | w5/tier3/qty0-1 | w2/tier3/qty0-1 |
| 4 | Wooden Bow | Archer | AGI | 3 | 1 (dead) | GOOD->PERFECT (1/turn) | w8/tier1/qty0-1 |  |
| 5 | Iron Bow | Archer | AGI | 6 | 1 (dead) | GOOD+: may Stun (cd 3 turns) | w7/tier2/qty0-1 | w4/tier2/qty0-1 |
| 6 | Platinum Bow | Archer | AGI | 9 | 2 (dead) | +30% damage vs statused foes | w5/tier3/qty0-1 | w2/tier3/qty0-1 |
| 7 | Wooden Staff | Mage | INT | 3 | 0 | +1 MP every 2 turns | w8/tier1/qty0-1 |  |
| 8 | Ruby Staff | Mage | INT | 6 | 0 | +15% skill damage, +1 status turn | w6/tier2/qty0-1 |  |
| 9 | Diamond Staff | Mage | INT | 9 | 1 (dead) | +25% skill damage, PERFECT +1 MP | w4/tier3/qty0-1 |  |

Armor (body slot only is ever dropped; `head`, `ring1`, `ring2` slots exist in code but no item uses them):

| id | name | classes | stat bonus | passive | chest loot |
|---|---|---|---|---|---|
| 20 | Leather Armor | Knight/Archer | DEF+1 | 1st hit -3 damage (each battle) | w6/tier1/qty0-1 |
| 21 | Iron Armor | Knight/Archer | DEF+2 | After hit: next hit -40% (cd2) | w6/tier2/qty0-1 |
| 22 | Platinum Armor | Knight/Archer | DEF+3 | Big hits reduced by 30% | w4/tier3/qty0-1 |
| 23 | Cloth Robe | Mage | INT+1 | +1 MP/2 turns, take +1 phys damage | w6/tier1/qty0-1 |
| 24 | Silk Robe | Mage | INT+2 | +10% skill damage, +1 status turn | w6/tier2/qty0-1 |
| 25 | Mithril Robe | Mage | INT+3 | Reflect 1st status (cost 1 MP) | w4/tier3/qty0-1 |

Consumables (`Item_ComputeAmount`, scr_db_item.gml:853-869; healing is the only HP source besides the bed; no skill heals although `effect:"heal"` is implemented, scr_db_skill.gml:1202-1207):

| id | name | effect | amount | chest | barrel | enemy |
|---|---|---|---|---|---|---|
| 10 | HP Potion Lv1 | heal | 5-10 + floor((lvl-1)*1.0) | w32/tier1/qty1-3 | w30/tier1/qty1-2 | w30/tier1/qty1-2 |
| 14 | HP Potion Lv2 | heal | 10-20 + floor((lvl-1)*0.8) | w20/tier2/qty1-4 | w12/tier2/qty1-3 | w10/tier2/qty1-2 |
| 15 | HP Potion Lv3 | heal | 20-35 + floor((lvl-1)*1.2) | w14/tier3/qty1-5 |  |  |
| 11 | MP Potion Lv1 | mp | 4-8 + floor((lvl-1)*0.4) | w28/tier1/qty1-3 | w26/tier1/qty1-2 | w22/tier1/qty1-2 |
| 17 | MP Potion Lv2 | mp | 8-14 + floor((lvl-1)*0.7) | w18/tier2/qty1-4 | w10/tier2/qty1-3 | w8/tier2/qty1-2 |
| 18 | MP Potion Lv3 | mp | 12-20 + floor((lvl-1)*1.0) | w12/tier3/qty1-5 |  |  |
| 12 | Antidote | cure | cures Poison | w20/tier1/qty1-2 | w20/tier1/qty1-2 | w12/tier1/qty1-1 |
| 13 | Bandage | cure | cures Bleeding | w20/tier1/qty1-2 | w20/tier1/qty1-2 | w12/tier1/qty1-1 |

Skillbooks: ids 101-114, one per skill, `stackable:false`, `max_stack:1`, unique per player (`Inv_Add` refuses a second copy, scr_inventory.gml:20-38). They never appear in the chest/barrel/enemy tables; only `obj_chest_skillbook` (rooms: rm_floor1, 4, 5, 7, 9 = 5 chests) and the graves in rm_floor6_5 (15 graves, 1% skillbook at stage 4, `GraveLoot_StageChance`, scr_interact.gml:98-106) roll them (`Loot_RollSkillbook`, scr_loot.gml:261-281: uniform over class books the player does not own).

Loot rolls: containers/enemies roll `random(1) > chance` then one weighted pick; weight x `Loot_TierMult` where the table row `tier` (1-3) is scaled by container/enemy level clamped to 1-3 (`global.loot_tier_weights`, scr_loot.gml:6-10: level 1 {low 1.0, mid .25, high .05}, level 2 {.7,.6,.2}, level 3 {.4,.7,.5}). Every enemy of level >= 3 therefore uses the level-3 row, i.e. from floor 3 on enemy drops skew to mid/high-tier gear. Enemy loot configs: `enemy_basic` [.2,.3,.4], `enemy_mid` [.3,.45,.6], `enemy_elite` [.55,.75,.95], `enemy_boss` [1,1,1] with 2 items (scr_loot.gml:73-79). Equipment drops exclude items the player owns or cannot equip.

## 7. Exact formulas (file:line)

All dice are `RollD20() = irandom_range(1,20)` (scr_math.gml:1).

**Hit / miss / evasion** - `Combat_AttemptHit` (scr_combat.gml:65-85):
1. If defender has a `force_dodge` status (Evasion, Solidify): miss, status consumed (L68-73). This beats Foresight.
2. Else if attacker has `always_hit` (Foresight): hit (L75-79).
3. Else `hit = (d20 + acc_bonus) >= (d20 + StatMod(defender AGI) + Status_GetSum(defender,'dodge_bonus'))` (L81-83; ties go to the attacker; `dodge_bonus` is defined by no status, so always 0).
- `acc_bonus` for players' skills = `skill.acc + StatMod(STR|AGI|INT) + 4` (scr_db_skill.gml:1112-1113). For enemy skills = `skill.acc + StatMod(stat)` (no +4). For enemy basic attacks = `StatMod(STR)` (scr_combat.gml:22-32, L1542). `Combat_EffectiveStat` includes equipment and status mods (scr_combat.gml:5-7, `Stat_Get` scr_stats.gml:54-68).
- **The player's basic Attack never calls `Combat_AttemptHit`.** Hit/miss for the basic attack is decided only by the timing minigame (`Battle_AttackTimingJudge`, scr_combat.gml:445-452).
- Exact P(hit) with k = StatMod(defender AGI) - acc_bonus: `P = 1 - (19+k)(20+k)/800` for -18 <= k <= 0, `(20-k)(21-k)/800` for k >= 1; neutral (k=0) = 52.5% [calc].

**Damage** - `Combat_Damage` + `Combat_ApplyDamage` (scr_combat.gml:47-63, 87-128):
`raw = power + StatMod(attack stat)`; `mitig = floor(StatMod(defender DEF)/2)` (**negative for DEF<10: low-DEF enemies take bonus damage**; Slime DEF 7 -> +1); `base = max(1, raw - mitig)`; then in order: x attacker `dmg_mult` (Rev Up x2, Bloodthirsty x1.06) `floor`, x `power_mult` `floor`, x crit (2) `floor`, x defender `guard_mult` `floor` (Guard x0, Blessing x0.8, Bloodthirsty x0.65; consumed on hit), x difficulty `floor`, minus armor-passive reduction (player defending only), `max(0, .)`.
- Basic attack (player): power = weapon power, stat = weapon stat; then `scaled = max(1, floor(dmg * timing_mult))` with PERFECT 1.0 / GOOD 0.75 / OKAY 0.5 / BAD 0.25 / MISS 0 (scr_combat.gml:561-587; judged by `Battle_AttackTimingJudge`, L445-452). Windows in logical px from the target: PERFECT +/-2, GOOD +/-4, OKAY +/-7, BAD +/-10 (scr_macros.gml:233-235); the marker falls `2.8 * rank_mult(1.0-1.35) * random(0.8-1.3)` px/frame (L218-224, scr_combat.gml:494-519), i.e. the whole non-miss band is 20 px = about 4-9 frames, the PERFECT band 4 px = 0.85-1.8 frames [calc].
- Skill: `weapon = {power: skill.power, stat: skill.stat, acc: skill.acc}`; skill damage never adds the weapon's power (scr_db_skill.gml:1120-1122). Equipment passives add `+floor(base*mult)-base` afterwards (`Equip_PlayerBonusDamage`, scr_equip.gml:311-360: Executioner x1.35 under 35% HP, Predator x1.30 vs any status, Ember Lens x1.15 / Silk Flow x1.10 / Arcane Surge x1.25 on skills).
- Enemy basic attack: power 2 + STR mod; enemy skills use `skill.power + StatMod(skill.stat)`; then through the defensive QTE if the skill has one: `final = floor(dmg * (1 - 0.5 * successes/prompts))` (scr_combat.gml:1241-1251).

**Critical hit** - `Combat_CritCheck` (scr_combat.gml:38-45): `chance = clamp(0.05 + max(0,StatMod(LUCK))*0.01 + crit_bonus*0.01, 0.05, 0.50)`; Take Aim contributes `crit_bonus 25`. Damage x2 (floored). Quirk: the basic attacks pass `1 + crit_bonus` (L563, L1551), skills pass `crit_bonus` (scr_db_skill.gml:1111,1121), so basic attacks have +1% crit.

**Status application** - damage skills: `if (status != -1 && any_hit) { if (chance >= 1 || random(1) <= chance*[enemy: x difficulty mult]) apply }` (scr_db_skill.gml:1147-1167; list form L1169-1191). Status-only skills always apply (L972-1001). **`multi_status` (Curse) ignores `status_chance` and the hit roll entirely** (L1003-1035) and, because DoTs exclude each other (`Status_Add`), the sequence Burn->Poison->Bleed leaves only Bleed on the target while the log prints all three names.
Stun skills grant the player two extra actions **whenever the skill hits, whether or not the 60% stun roll succeeded** (`grant_extra_turns = 2`, scr_combat.gml:699-704; consumed by `Battle_PlayerFinalizeTurn` L475-490).

**Healing**: potions `irandom_range(min,max) + floor((level-1)*scale)` clamped to max (scr_db_item.gml:853-891). Meditation: +2..4 MP per tick. Skill heal: unused.

**XP / level**: section 3. **Difficulty**: section 1. **Run**: `d20 + AGI mod` vs enemy's; ties succeed; mini/final boss cannot be fled (scr_combat.gml:779-804). **Initiative**: `d20 + AGI mod`, ties rerolled, decides only who moves first (obj_battle_controller/Create_0.gml:47-60).

**RNG usage and seeding**
- `randomize()` once per session in `GameState_Init` (scr_player.gml:1530); no fixed seed, no seed stored in saves, so reloading a save rerolls every fight and chest.
- `irandom_range(1,20)`: initiative, hit/dodge (two d20 per attempt), run. `random(1)`: crit, status chance, enemy skill candidacy (`random(1) <= chance`), loot chance/weights, grave chance, ghost easter egg, Pinning Shot. `random_range`: enemy skill use chance (scr_db_skill.gml:813), attack-timing speed variation (scr_combat.gml:516). `irandom`: DoT/Meditation tick amount (scr_status.gml:499,506), steal pick (scr_db_skill.gml:1081), enemy skill pick (scr_combat.gml:878), enemy level roll +/-1 (scr_enemy.gml:28), QTE prompt count (scr_combat.gml:981-984), potion amount. `choose`: QTE arrow direction (scr_combat.gml:1006), enemy wander direction.

## 8. Computed results used for Part C

### 8a. Direct and DoT value of each player skill [calc]

Reference enemy: Ghost Sword (DEF 12 -> mitig 1, AGI 12 -> dodge +1), Normal difficulty, no armor, weapon tier by level (L1 tier 1 power 3, L5 tier 2 power 6, L9 tier 3 power 9). `EV` = expected direct damage per cast including P(hit) and crits; `DoT EV` = P(hit) x status chance x 5 ticks x average tick (poison 2.5, bleed 3, burn 5), uncapped by enemy HP and only paid if the fight lasts that long (first tick lands after the enemy's next turn). Basic attack shown at PERFECT / x0.36 ('average' timing) / x0.66 ('skilled' timing); those two timing distributions are my assumptions (see 8b), not measurements.

Knight slots: Wound (3 MP) / Hilt Bash (4) / Horizontal Slash (5). Archer: Wound / Poison Arrow (4) / Double Shot (5). Mage: Fireball (4) / Poison Mist (4) / Ice Spear (5).

|  | basic atk P/avg/skilled | slot 1 EV | slot 2 EV | slot 3 EV |
|---|---|---|---|---|
| Knight L1 | 3 / 1.1 / 2.0 | 2.8 +7.4 DoT (P0.66) | 2.8 (P0.66) | 4.9 (P0.66) |
| Knight L5 | 8 / 2.9 / 5.3 | 4.6 +8.3 DoT (P0.74) | 4.6 (P0.74) | 7.7 (P0.74) |
| Knight L9 | 13 / 4.7 / 8.6 | 6.8 +9.1 DoT (P0.81) | 6.8 (P0.81) | 11.0 (P0.81) |
| Archer L1 | 4 / 1.4 / 2.6 | 2.8 +7.4 DoT (P0.66) | 4.6 +6.9 DoT (P0.74) | 7.3 (P0.70) |
| Archer L5 | 9 / 3.2 / 5.9 | 2.8 +7.4 DoT (P0.66) | 6.8 +7.5 DoT (P0.81) | 11.5 (P0.77) |
| Archer L9 | 14 / 5.0 / 9.2 | 2.8 +7.4 DoT (P0.66) | 9.2 +8.1 DoT (P0.86) | 16.1 (P0.83) |
| Mage L1 | 4 / 1.4 / 2.6 | 5.1 +10.5 DoT (P0.70) | 3.7 +6.6 DoT (P0.70) | 4.4 (P0.70) |
| Mage L5 | 9 / 3.2 / 5.9 | 7.4 +11.6 DoT (P0.77) | 5.7 +7.2 DoT (P0.77) | 6.6 (P0.77) |
| Mage L9 | 14 / 5.0 / 9.2 | 9.8 +12.5 DoT (P0.83) | 8.0 +7.8 DoT (P0.83) | 8.9 (P0.83) |

Reading: (1) the single-hit direct skills (Hilt Bash, Horizontal Slash, Ice Spear, Fireball/Poison Arrow/Wound's hit) are below a PERFECT basic attack once a tier-2/3 weapon is equipped (the exception is Double Shot, two rolls: 16.1 vs 14 at L9); they only win against an average-timing player. (2) The DoT riders are worth 1.3-2x the hit's direct damage for Fireball (10.5/11.6/12.5 vs 5.1/7.4/9.8) and 2-3x for Wound (7.4-9.1 vs 2.8-6.8), cost 3-4 MP, and ignore DEF and accuracy after application.

### 8b. Monte-Carlo fight model [model]

Re-implementation of the player/enemy turn loop in python (scr_combat.gml Battle_*, scr_db_skill.gml Skill_Use, scr_status.gml tick/exclusion, enemy skill selection and defensive QTE rules, difficulty floors). Not run in GameMaker. Assumptions: player at the level it would have after clearing all previous floors (section 3); weapon tier 1 on floors 1-3, 2 on 4-6, 3 on 7+ (optimistic: tier 2/3 weapons are rare drops); no armor, no potions, starts every fight at full HP and MP; N books owned = number of skillbook chests passed (random subset of the class's 5); enemy at its most likely level for the floor; defensive-QTE prompt success 55%; Steal never fires (assumes empty inventory). Policies: **avg** = basic attacks only, timing outcomes PERFECT 10% / GOOD 15% / OKAY 20% / BAD 20% / MISS 35% (mean multiplier 0.36); **skilled** = same but 35/25/20/10/10 (mean 0.66); **skills** = open with the class DoT then the class damage skill while MP lasts, else basic attack with the *average* timing; 4000-6000 fights per cell.

Win rate per single fight, shown as `avg-timing basic / skilled-timing basic / skills policy` with mean HP lost under the skills policy:

| floor | enemy | Knight | Archer | Mage |
|---|---|---|---|---|
| F1 | Slime L1 (HP 9) | L1 HP10: 82% / 100% / 89%  (skills: 35% HP lost) | L1 HP10: 87% / 100% / 92%  (skills: 29% HP lost) | L1 HP10: 83% / 100% / 89%  (skills: 36% HP lost) |
| F2 | Dire Wolf L3 (HP 22) | L1 HP10: 6% / 54% / 26%  (skills: 87% HP lost) | L1 HP10: 15% / 74% / 36%  (skills: 80% HP lost) | L1 HP10: 11% / 66% / 35%  (skills: 80% HP lost) |
| F2 | Slime L1 (HP 9) | L1 HP10: 83% / 100% / 89%  (skills: 36% HP lost) | L1 HP10: 87% / 100% / 91%  (skills: 30% HP lost) | L1 HP10: 84% / 100% / 88%  (skills: 37% HP lost) |
| F3 | Snake L2 (HP 15) | L2 HP17: 58% / 94% / 71%  (skills: 49% HP lost) | L2 HP16: 58% / 93% / 72%  (skills: 47% HP lost) | L2 HP15: 53% / 91% / 70%  (skills: 50% HP lost) |
| F3 | Spider L3 (HP 20) | L2 HP17: 59% / 94% / 73%  (skills: 51% HP lost) | L2 HP16: 62% / 94% / 74%  (skills: 49% HP lost) | L2 HP15: 56% / 93% / 72%  (skills: 52% HP lost) |
| F4 | Dire Wolf L3 (HP 22) | L3 HP24: 82% / 100% / 89%  (skills: 38% HP lost) | L3 HP22: 84% / 100% / 93%  (skills: 28% HP lost) | L3 HP20: 73% / 100% / 91%  (skills: 33% HP lost) |
| F4 | Killer Plant L4 (HP 29) | L3 HP24: 28% / 88% / 58%  (skills: 71% HP lost) | L3 HP22: 47% / 95% / 72%  (skills: 58% HP lost) | L3 HP20: 28% / 84% / 75%  (skills: 56% HP lost) |
| F5 | Dire Wolf L5 (HP 32) | L4 HP31: 85% / 100% / 94%  (skills: 15% HP lost) | L4 HP28: 83% / 100% / 96%  (skills: 19% HP lost) | L4 HP25: 78% / 100% / 96%  (skills: 26% HP lost) |
| F5 | Palehorn L8 (HP 67) | L4 HP31: 0% / 1% / 1%  (skills: 100% HP lost) | L4 HP28: 0% / 0% / 0%  (skills: 100% HP lost) | L4 HP25: 0% / 0% / 3%  (skills: 99% HP lost) |
| F5 | Snake L4 (HP 25) | L4 HP31: 76% / 99% / 91%  (skills: 24% HP lost) | L4 HP28: 78% / 99% / 96%  (skills: 13% HP lost) | L4 HP25: 70% / 98% / 95%  (skills: 20% HP lost) |
| F6 | Ghost Sword L6 (HP 40) | L5 HP38: 19% / 79% / 57%  (skills: 73% HP lost) | L5 HP34: 21% / 76% / 72%  (skills: 56% HP lost) | L5 HP30: 7% / 54% / 72%  (skills: 66% HP lost) |
| F6 | Mad Whisp L5 (HP 28) | L5 HP38: 53% / 94% / 82%  (skills: 40% HP lost) | L5 HP34: 58% / 95% / 92%  (skills: 23% HP lost) | L5 HP30: 40% / 87% / 89%  (skills: 36% HP lost) |
| F6 | Slime L1 (HP 9) | L5 HP38: 96% / 100% / 99%  (skills: 3% HP lost) | L5 HP34: 96% / 100% / 100%  (skills: 1% HP lost) | L5 HP30: 96% / 100% / 100%  (skills: 3% HP lost) |
| F7 | Ghost Sword L6 (HP 40) | L6 HP45: 43% / 95% / 84%  (skills: 48% HP lost) | L6 HP40: 43% / 94% / 91%  (skills: 35% HP lost) | L6 HP35: 24% / 82% / 93%  (skills: 49% HP lost) |
| F7 | Mad Whisp L7 (HP 36) | L6 HP45: 65% / 97% / 92%  (skills: 27% HP lost) | L6 HP40: 64% / 97% / 97%  (skills: 16% HP lost) | L6 HP35: 45% / 92% / 95%  (skills: 33% HP lost) |
| F7 | Spider L3 (HP 20) | L6 HP45: 93% / 100% / 100%  (skills: 4% HP lost) | L6 HP40: 93% / 100% / 100%  (skills: 2% HP lost) | L6 HP35: 91% / 100% / 100%  (skills: 5% HP lost) |
| F7 | Stranger L7 (HP 48) | L6 HP45: 43% / 98% / 77%  (skills: 64% HP lost) | L6 HP40: 32% / 92% / 76%  (skills: 57% HP lost) | L6 HP35: 12% / 71% / 88%  (skills: 58% HP lost) |
| F8 | Mad Whisp L7 (HP 36) | L7 HP52: 70% / 99% / 95%  (skills: 21% HP lost) | L7 HP46: 74% / 99% / 100%  (skills: 10% HP lost) | L7 HP40: 54% / 95% / 99%  (skills: 27% HP lost) |
| F8 | Stranger L7 (HP 48) | L7 HP52: 51% / 99% / 84%  (skills: 53% HP lost) | L7 HP46: 63% / 99% / 95%  (skills: 33% HP lost) | L7 HP40: 25% / 87% / 96%  (skills: 48% HP lost) |
| F9 | Stranger L9 (HP 58) | L7 HP52: 39% / 97% / 77%  (skills: 61% HP lost) | L7 HP46: 52% / 98% / 88%  (skills: 45% HP lost) | L7 HP40: 14% / 78% / 98%  (skills: 48% HP lost) |
| F9.5 | The Pale Choirbeast L10 (HP 88) | L8 HP59: 0% / 24% / 9%  (skills: 98% HP lost) | L8 HP52: 1% / 25% / 10%  (skills: 98% HP lost) | L8 HP45: 0% / 4% / 10%  (skills: 99% HP lost) |

Bosses by player level, all 5 books owned and a tier-3 weapon (win %, **combo** = stun skill first then spend the two free actions on DoT/damage skills; Archer has no stun skill so combo = skills):

| boss | class | level | basic avg | basic skilled | skills | combo | player HP |
|---|---|---|---|---|---|---|---|
| Palehorn | Knight | L4 | 0% | 8% | 3% | 6% | 31 |
| Palehorn | Knight | L5 | 1% | 16% | 5% | 11% | 38 |
| Palehorn | Knight | L6 | 2% | 38% | 17% | 33% | 45 |
| Palehorn | Knight | L7 | 4% | 51% | 30% | 35% | 52 |
| Palehorn | Knight | L8 | 11% | 71% | 55% | 62% | 59 |
| Palehorn | Knight | L9 | 14% | 81% | 53% | 64% | 66 |
| Palehorn | Knight | L10 | 22% | 89% | 67% | 83% | 73 |
| Palehorn | Archer | L4 | 0% | 7% | 2% | 2% | 28 |
| Palehorn | Archer | L5 | 1% | 23% | 15% | 15% | 34 |
| Palehorn | Archer | L6 | 2% | 34% | 18% | 19% | 40 |
| Palehorn | Archer | L7 | 9% | 60% | 48% | 47% | 46 |
| Palehorn | Archer | L8 | 12% | 70% | 65% | 64% | 52 |
| Palehorn | Archer | L9 | 27% | 86% | 88% | 89% | 58 |
| Palehorn | Archer | L10 | 31% | 91% | 96% | 95% | 64 |
| Palehorn | Mage | L4 | 0% | 3% | 9% | 25% | 25 |
| Palehorn | Mage | L5 | 0% | 6% | 23% | 54% | 30 |
| Palehorn | Mage | L6 | 0% | 12% | 35% | 62% | 35 |
| Palehorn | Mage | L7 | 1% | 25% | 56% | 85% | 40 |
| Palehorn | Mage | L8 | 3% | 33% | 68% | 89% | 45 |
| Palehorn | Mage | L9 | 5% | 50% | 81% | 99% | 50 |
| Palehorn | Mage | L10 | 7% | 59% | 87% | 99% | 55 |
| Choirbeast | Knight | L4 | 0% | 0% | 0% | 0% | 31 |
| Choirbeast | Knight | L5 | 0% | 0% | 0% | 0% | 38 |
| Choirbeast | Knight | L6 | 0% | 4% | 1% | 3% | 45 |
| Choirbeast | Knight | L7 | 0% | 9% | 3% | 4% | 52 |
| Choirbeast | Knight | L8 | 0% | 25% | 10% | 16% | 59 |
| Choirbeast | Knight | L9 | 1% | 38% | 9% | 18% | 66 |
| Choirbeast | Knight | L10 | 4% | 66% | 29% | 48% | 73 |
| Choirbeast | Archer | L4 | 0% | 0% | 0% | 0% | 28 |
| Choirbeast | Archer | L5 | 0% | 1% | 0% | 0% | 34 |
| Choirbeast | Archer | L6 | 0% | 3% | 0% | 1% | 40 |
| Choirbeast | Archer | L7 | 0% | 15% | 6% | 4% | 46 |
| Choirbeast | Archer | L8 | 0% | 23% | 9% | 9% | 52 |
| Choirbeast | Archer | L9 | 3% | 53% | 30% | 30% | 58 |
| Choirbeast | Archer | L10 | 6% | 67% | 52% | 51% | 64 |
| Choirbeast | Mage | L4 | 0% | 0% | 0% | 1% | 25 |
| Choirbeast | Mage | L5 | 0% | 0% | 0% | 10% | 30 |
| Choirbeast | Mage | L6 | 0% | 1% | 2% | 12% | 35 |
| Choirbeast | Mage | L7 | 0% | 2% | 5% | 40% | 40 |
| Choirbeast | Mage | L8 | 0% | 3% | 10% | 51% | 45 |
| Choirbeast | Mage | L9 | 0% | 14% | 27% | 87% | 50 |
| Choirbeast | Mage | L10 | 0% | 20% | 36% | 93% | 55 |

Difficulty sensitivity (Knight, **all five books owned**, skills policy; win % and mean HP lost / max HP; Palehorn row uses the combo policy; this is why the F2 row shows 83% on Normal instead of the 26% in the table above, which averages over random single books) [model]:

| matchup | Easy | Normal | Hard |
|---|---|---|---|
| F2 Dire Wolf L3 vs Knight L1 | 95%  3/12 | 83%  5/10 | 67%  6/9 |
| F4 Killer Plant L4 vs Knight L3 | 97%  6/28 | 90%  11/24 | 66%  15/22 |
| F6 Mad Whisp L5 vs Knight L5 | 99%  4/44 | 94%  8/38 | 88%  11/35 |
| F7 Stranger L7 vs Knight L6 | 94%  18/52 | 76%  29/45 | 48%  35/41 |
| F5 Palehorn L8 vs Knight L7 (combo) | 66%  39/60 | 36%  44/52 | 18%  46/48 |


## 9. Balance smells (Part C)

Numbers are [calc] unless tagged [model]. Ordered by impact.

**S1. Stun skills give 3 actions per enemy action, and the 'stun landed' roll does not matter.** `grant_extra_turns = 2` fires on any hit by a stun-carrying skill (scr_combat.gml:699-704). Hilt Bash (4 MP) and Ice Spear (5 MP) therefore convert one action into three on a hit (66-89% of the time), and the 60% stun additionally skips the enemy's next action. [model] Mage with the stun-first 'combo' policy beats Palehorn 85% at L7 (skills-only 56%, skilled basic attacks 25%) and the final boss 93% at L10 (36% / 20%). Knight combo reaches 83% on Palehorn at L10, Archer (no stun skill) 95% on Palehorn but only 51% on the boss. Mage is the dominant class once it owns Ice Spear + Fireball.

**S2. DoT damage dwarfs direct damage on both sides.** Player: a 5-tick burn averages 25 damage (60% chance, Fireball 4 MP), bleed 15 (75%, Wound 3 MP), poison 12.5 (75%); enemies have 9-32 HP on floors 1-5 (section 5), so one Fireball burn alone kills most of them if the fight lasts 5 more enemy turns. DoTs ignore DEF and accuracy once applied. Enemy side: direct hits are 1-7 damage, but a rank-1 enemy has exactly one QTE prompt, which makes the status duration a coin flip between 2 ticks and **8 ticks** (formula in section 4; rank 2-3 scale 2-8 with the prompts hit): Snake Bite bleed = 6 or 24 HP against a level-2 player with 15-17 HP; Mad Whisp (1-3 prompts) burn = 10 to 40 HP against 30-38 HP. The most dangerous thing on floors 3-6 is a failed QTE prompt, not the enemy's attack. [model] F3 Snake: Knight L2 wins 58% with average timing basic attacks, 94% with skilled timing. F2 Dire Wolf vs the L1 character (average timing): Knight with no skill 7% win, owning only Wound 84%, only Horizontal Slash 32%, only Hilt Bash (not cast by that policy) 7%; Mage with no skill 11%, only Fireball 76%. One DoT book is worth more than any amount of level on floors 1-4.

**S3. Horizontal Slash is dominated by Wound.** Slash (5 MP, power 5 x1.5, no status): EV 4.9 (L1) / 7.7 (L5) / 11.0 (L9) vs Ghost Sword; Wound (3 MP, power 4): direct 2.8 / 4.7 / 6.8 plus bleed 7.4 / 8.3 / 9.1 -> total 10.2 / 13.0 / 15.8, i.e. more total damage for 40% less MP at every level, and a PERFECT basic attack with a tier-2 weapon (8 at L5) equals the Slash's direct EV. Its real hit chance is 66-89% (table below), so it is also the skill most exposed to the miss complaint.

**S4. Self-buffs are tempo-negative except Take Aim and Meditation.** Rev Up (3 MP, x2 on the next attack, consumed): spends an action to double one later action = break-even on damage, minus 3 MP. Muscle Up (Guard x0 on the next hit, 3 MP): saves one enemy hit worth 1-7 HP (section 5) and still lets the hit's status through (a blocked hit still counts as `any_hit`, scr_db_skill.gml:1137-1152, and a 0-damage hit skips the QTE so DoT durations are not shortened). Evasion (3 MP): avoids one hit and its status. Foresight (3 MP): +11 to +34 points of hit chance for one skill (66-89% -> 100%), but a basic attack consumes it for nothing (scr_combat.gml:594), Solidify/Evasion on the target override it, and the status lasts 9 actions but is consumed by the first attack. Take Aim (3 MP, +25 crit for 9 actions, not consumed): crit 30-33% for the whole fight = about +25% damage on every hit; Meditation (3 MP): 9 ticks x 3 MP = about 27 MP back (capped by max MP) for 3 MP and one action.

**S5. Skill damage ignores weapon and gear.** Skills use their own `power` (4-6) so skill direct damage scales only with the class stat (+1 per level), while a tier-3 weapon adds +9 to a basic attack. At L9 a PERFECT basic attack does 13-15 per hit vs 5-13 per hit for the class skills. Weapon `acc` (+1/+2 on tier-3), item `value`, and every weapon `bonus` field are inert for players. Robes give INT (skill damage/accuracy) but not MP.

**S6. The basic attack is a QTE with an extremely narrow band, so average damage is far below 'power'.** PERFECT band 4 px, whole non-miss band 20 px, marker speed 2.2-4.7 px/frame (section 7). If an average player lands PERFECT/GOOD/OKAY/BAD/MISS at 10/15/20/20/35% (my assumption), the mean multiplier is 0.36; a skilled player 0.66. [model] F1 Slime vs L1 Knight: win 82% (avg) vs 100% (skilled); F2 Dire Wolf vs an L1 character: 6% / 54% (skills policy 26%). Skills need no timing, so they are strictly more reliable than the basic attack for anyone below skilled timing, which is why skills 'feel' mandatory.

**S7. Difficulty settings barely matter and are partly inverted by `floor()`** (section 1). Easy: enemy damage -1 per hit (a Slime or Snake bite of 1 becomes 0), player damage +0 below 13; Hard: enemy damage +0 below 9, player damage -1 per hit (a 4-damage hit loses 25%, a 1-damage hit becomes 0), plus 12% enemy HP and 8% player HP. [model] F4 Killer Plant vs Knight L3: win 97% / 90% / 66% (Easy/Normal/Hard) but mean damage taken 6 / 11 / 15; `player_stat_mult`/`enemy_stat_mult` are unused.

**S8. Dead or near-dead stats.** LUCK: +1% crit per 2 points over 10 (needs mod >= 1), cap +3% by L10; Archer/Mage only. DEF: mitigation is `floor(mod/2)` and enemy hits are 1-7, so Knight L10 DEF 17 (mod 3) saves 1 point, Platinum Armor (+3) saves at most 2; the HP bonus from DEF is 0 until DEF 18. INT on Knight/Archer, STR on Archer/Mage (except Wound), AGI on Knight/Mage (stays 10, dodge mod 0 for the whole game while enemy hit chance rises 48% -> 74%): no effect. Enemy INT/MP/mp_gain/LUCK: nothing reads them (no enemy skill costs MP; luck only crits).

**S9. Floor/boss difficulty spikes** [model, section 3 levels]. F2: Dire Wolf (L3, 22 HP, always level 3 because of its min level) vs the L1 character the player has after floor 1 (8 of 15 EXP): win 6-15% with average timing, 26-36% with skills, 54-74% skilled, and it deals 1.0 EV/turn against 10 HP. F4: Killer Plant (L4, 29 HP, vine trap stun 65%): Knight L3 28% / 88% / 58%. F5: **Palehorn (L8, 67 HP, DEF 16, ramming 7 dmg + bleed, 3-5 QTE prompts, cannot be fled) vs player L4-5: 0-23%** in every policy except the Mage stun combo (25% at L4, 54% at L5); at L7 (needs floors 6-7 cleared) it is 25-60% with skilled timing; the XP path puts the player at L4-5 when he arrives. F6: Ghost Sword (L6, 40 HP, bleed 80% on a 50% skill) vs Knight L5: 19% / 79% / 57%. F7-9 Stranger (L7-9, 48-58 HP): 12-63% with average timing. Final boss (L10, 88 HP, STR 21, Fury double action under 45%), no potions: at the expected level 8 it is 0-25% for every policy except the Mage combo (51%); at L10 Knight 66% (skilled basic) / Archer 51% / Mage 93% (combo). F9 (58 EXP) and F3 (20 EXP) are pacing dead spots; one pass reaches L8 only, so the cap-10 stats never matter unless the player grinds respawns.

**S10. Skill availability is uneven.** 5 skillbook chests (F1, 4, 5, 7, 9) for 5 books per class, random draws: at the F5 boss a character owns only 3 of 5 books, so a Mage owns both Fireball and Ice Spear only 30% of the time (exactly one 60%, neither 10%) when Palehorn arrives. Foresight and Meditation are two of the Mage's five books and are the weakest two (S4).

**S11. Tooltips misstate the numbers.** Skill tooltips print `status_turns` (Wound 'Bleeding 2 turns', Fireball 'Burning 2 turns', Meditation/Foresight/Take Aim '3 turns', Guard 2) but the game applies 5 / 5 / 9 / 9 / 9 / 6 (section 4). Poison's tooltip omits its INT -1. Stun skills' tooltips do not mention the two free actions. Foresight says 'Next attack cannot miss' but basic attacks cannot miss by dice at all and still consume it.

**S12. Curse (final boss) is weaker than it reads.** 'Burn/Poison/Bleed 50%' becomes: always lands (no chance roll), but only Bleed survives (DoT exclusion), 2 ticks (no QTE for multi_status). Net 2 x 3 = about 6 HP.

**S13. Slime `Solidify` (F1, F2, F6)** is `force_dodge` (consumed only by a hit roll): it auto-misses the next *skill* and is not consumed or respected by basic attacks. A slime fight therefore has an extra skill-miss chance of roughly 15% per turn, on top of the normal 26-34% miss rate.

**S14. Loot/economy.** No gold or shop, so potions are the only sink for consumable drops; HP Potion Lv1 heals 5-10 (+1/level), a Lv3 potion 20-35 (+1.2/level) against 10-73 max HP. Because loot tier weights use the enemy level clamped to 3, drops from F3 onward are the same quality at F3 and F9. Enemy loot cannot contain skillbooks.

### Horizontal Slash exact hit chance (for the 'missed 4-5 in a row' note) [calc]

| Knight lvl | STR | STR mod | acc used | Slime (AGI mod -1) | Spider (0) | Dire Wolf (0) | Mad Whisp (+1) | Ghost Sword (+1) | Stranger (+1) | Palehorn (+1) | Choirbeast (+2) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 11 | 0 | 4 | 73.8% | 70.0% | 70.0% | 66.0% | 66.0% | 66.0% | 66.0% | 61.8% |
| 2 | 12 | 1 | 5 | 77.2% | 73.8% | 73.8% | 70.0% | 70.0% | 70.0% | 70.0% | 66.0% |
| 3 | 13 | 1 | 5 | 77.2% | 73.8% | 73.8% | 70.0% | 70.0% | 70.0% | 70.0% | 66.0% |
| 4 | 14 | 2 | 6 | 80.5% | 77.2% | 77.2% | 73.8% | 73.8% | 73.8% | 73.8% | 70.0% |
| 5 | 15 | 2 | 6 | 80.5% | 77.2% | 77.2% | 73.8% | 73.8% | 73.8% | 73.8% | 70.0% |
| 6 | 16 | 3 | 7 | 83.5% | 80.5% | 80.5% | 77.2% | 77.2% | 77.2% | 77.2% | 73.8% |
| 7 | 17 | 3 | 7 | 83.5% | 80.5% | 80.5% | 77.2% | 77.2% | 77.2% | 77.2% | 73.8% |
| 8 | 18 | 4 | 8 | 86.2% | 83.5% | 83.5% | 80.5% | 80.5% | 80.5% | 80.5% | 77.2% |
| 9 | 19 | 4 | 8 | 86.2% | 83.5% | 83.5% | 80.5% | 80.5% | 80.5% | 80.5% | 77.2% |
| 10 | 20 | 5 | 9 | 88.8% | 86.2% | 86.2% | 83.5% | 83.5% | 83.5% | 83.5% | 80.5% |

Miss chance is 11-38% (typical 20-34%). P(at least one run of >=4 misses in N casts) with a per-cast miss q [calc]: q=0.25: 5% (N=20), 10% (N=40), 21% (N=80); q=0.30: 10% / 20% / 36%; q=0.35: 16% / 32% / 55%. P(run >= 5): q=0.25: 1.2% / 2.6% / 5.5%. A given streak of exactly 4 in a row has probability q^4 = 0.4-1.5%.

What raising `PLAYER_SKILL_HIT_BONUS` would do [calc], Horizontal Slash vs an enemy with AGI mod 0 / +1: bonus 4 (now): L1 70% / 66%, L5 77% / 74%, L9 84% / 81%; bonus 6: 77% / 74%, 84% / 81%, 89% / 86%; bonus 8: 84% / 81%, 89% / 86%, 93% / 91%. Each +2 is worth about +6 points at low level and +4-5 at high level.

