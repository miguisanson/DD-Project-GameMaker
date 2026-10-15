# Combat spec (packet B1: STAT-01..06, 11, 12; D20 D22 D27 D35 D61 D76 D77 D80; packet B2: section 10, D21 D24 D59 D78 D79; packet B3: section 11, D19 D74 D75 D92)

Written BEFORE the code. Numbers are starting values for the simulator (BAL-02), not final balance; the FORMULAS are fixed and
`combat-vectors.json` holds the expected outputs (derived from this text by `tools/balance/check_combat_vectors.py`, not from game output).
Test_Suite_Stats / Test_Suite_Combat in `scr_test.gml` hard-code the same cases (ids `vec <id>`); the checker fails if one is missing.

## 1. Stats
`ATK DEF SPD MAG` + `HP MP` (STR/AGI/INT/LUCK removed). Ids: `STAT_ATK 0, STAT_DEF 1, STAT_SPD 2, STAT_MAG 3`. Range 1..60.
Effective stat = max(1, base + equipment bonus + status mod). Equipment/status structs use keys `atk def spd mag`.
- ATK: physical damage (basic attacks with swords/bows, ATK skills). MAG: spell damage and max MP. DEF: damage taken (all sources).
- SPD: turn order (the timeline, section 11): a fighter with twice the SPD acts twice as often. Run: section 8.
- Status mods (rename only): Poison MAG-1, Bleeding SPD-2, Stun SPD-2, Sundered DEF-1. Burning has no flat mod any more: it takes DEF x0.75 (section 10).

## 2. Classes (level 1) and fixed growth per level (D76)
| class | ATK | DEF | SPD | MAG | hd | mp_gain | fixed growth each level 2..10 | free point default (auto) |
|---|---|---|---|---|---|---|---|---|
| Knight | 11 | 12 | 10 | 3 | 10 | 1 | ATK+1, DEF+1 | DEF |
| Archer | 9 | 8 | 13 | 4 | 8 | 2 | SPD+1, ATK+1 | ATK |
| Mage | 5 | 7 | 10 | 12 | 6 | 2 | MAG+2 | MAG |
| Nobody | 8 | 8 | 9 | 3 | 8 | 1 | two stats per level (D111): the one of the cycle ATK, DEF, SPD, MAG by (level-2) mod 4, and the one two steps further on it | ATK |

Nobody is balanced-low (28 stat points against 34; since D111 its growth is two points a level, like the other classes' two); D83 gives it items and passives instead of skills.
Each level also gives ONE free point: `ch.stat_points += 1`; `Level_ApplyFreePoint(ch, stat)` spends one (needs stat_points > 0, stat in
ATK/DEF/SPD/MAG, +1 clamped to 60) and returns ch. Until the level-up UI exists the level-up places it on the
class default at once (`Level_AutoPlaceEnabled()`, `global.levelup_auto_place`, default true); the UI packet sets it false and calls
`Level_ApplyFreePoint` from the player's choice.

## 3. Resources
`max_hp = 10 + (L-1) * (ceil(hd/2) + 2)`  (Knight 7/level, Archer 6, Mage 5, Nobody 6; no stat adds HP).
`max_mp = 10 + (L-1) * mp_gain + floor(MAG / 2)`  (raw MAG, equipment not included). One difficulty only: no HP/MP multipliers.

## 4. Damage (D77, D22, D61)
```
power   = 2 * weapon.power                                  basic attack of the player (no weapon equipped counts as weapon.power 2, "fists")
        = 2 * (skill.power + 0.5 * weapon.power) * power_mult   skill of the player (D22: the weapon adds to skills)
        = 2 * skill.power * power_mult                      enemy skill
        = enemy.basic_power                                 enemy basic attack (data field: rank 1/2/3/4 = 3/5/7/9)
A = effective stat of the attack: weapon.stat_type (ATK, or MAG for staves) for basic attacks, skill.stat_type for skills (MAG for spells)
D = effective DEF of the defender
mult = product of: attacker dmg_mult (Rev Up 2, Bloodthirsty 1.06), crit (2 on a crit), defender guard_mult
       (Guard 0, Blessing 0.8, Bloodthirsty 0.65, Solidify 0.25), assist_damage_taken_mult (1; D35 hook)
raw  = power * A * mult / (A + D)
ok   = max(1, round_half_up(raw))             round_half_up(x) = floor(x + 0.5 + 0.000001)
damage = 0 when power <= 0 or mult == 0 (Guard blocks, nothing else may);
       = ok at grade 1.00;
       = max(1, round_half_up(raw * grade)) otherwise, but never within 1 of ok on the wrong side: grade > 1 gives >= ok + 1,
         grade < 1 gives <= ok - 1 (D61 "Perfect is visibly above OK"), then max(1, .)   [D61 grades: Perfect 1.30 Good 1.10 OK 1.00 Weak 0.75]
```
Armor/equipment passives (`Equip_PlayerIncomingDamageReduction`, `Equip_PlayerBonusDamage`) still apply after this, as flat amounts.
Multi-hit skills run the formula once per hit. DoT tick numbers: section 10.
**No dice (D80):** nothing rolls to hit. Enemies never miss, the player never misses. Evasion (a status on the player) fully dodges the next
damaging enemy action: damage 0, `hit=false` (no defence bar), status consumed. Solidify (Slime) is `guard_mult 0.25`, consumed by the next hit.
Foresight's old `always_hit` flag is gone; Foresight is redesigned in section 10 (D79).
**Crit (LUCK removed):** no base chance. `crit_chance = clamp(crit_bonus / 100, 0, 0.5)` where `crit_bonus` sums statuses/passives (Take Aim = 25).
Basic attacks and skills use the same rule (no more +1 on basic attacks). Crit damage x2 (it is in `mult`).
**Heal skills** (none in use): `power + floor(A / 4)`.

## 5. Difficulty (D35)
`Difficulty_Profile()` returns ONE profile whatever the saved difficulty id is: `assist_damage_taken_mult 1.0` (hook, QTE assist may lower it later),
`player_exp_mult 1`. The HP/MP/damage/status-chance multipliers, `player_stat_mult`, `enemy_stat_mult` and the floored small-integer maths are gone.
`DIFFICULTY_*` macros and `Difficulty_SetCurrent` stay only so the title screen and save format keep working until the UI packets drop them.

## 6. Enemies (converted, relative strength kept)
Mapping: ATK = old STR, DEF = old DEF, SPD = old AGI, MAG = old INT, LUCK dropped. The new stat scale equals the old one (player level 1 is 5..13 as before),
so every enemy keeps its place relative to the player. HP no longer has a DEF term, so `base_hp += max(0, floor((DEF-10)/2))` (old DEF bonus folded in):
Ghost Sword 14 -> 15, Stranger 16 -> 18, Palehorn 22 -> 25, Pale Choirbeast 30 -> 34 (all other `base_hp` unchanged).
`enemy max_hp = base_hp + (L-1) * (ceil(hd/2) + 1)`; `max_mp = base_mp + (L-1) * mp_gain` (no enemy uses MP). `basic_power` by threat rank 1/2/3/4 = 3/5/7/9; D111 (E1-3) raised it to 5/7/7/14 (rank 1 enemies 5, rank 2 enemies 7, Palehorn 7, Choirbeast 14).
| enemy | ATK | DEF | SPD | MAG | base_hp | rank |
|---|---|---|---|---|---|---|
| Slime | 8 | 7 | 9 | 5 | 9 | 1 |
| Spider | 8 | 7 | 10 | 5 | 10 | 1 |
| Snake | 9 | 7 | 10 | 5 | 10 | 1 |
| Mad Whisp | 10 | 9 | 12 | 13 | 12 | 2 |
| Killer Plant | 12 | 11 | 9 | 10 | 14 | 2 |
| Dire Wolf | 11 | 9 | 11 | 6 | 12 | 1 |
| Ghost Sword | 14 | 12 | 12 | 10 | 15 | 2 |
| Stranger | 16 | 14 | 13 | 15 | 18 | 2 |
| Palehorn (mini boss) | 18 | 18 | 12 | 14 | 55 | 3 |
| The Pale Choirbeast (final boss) | 21 | 24 | 14 | 19 | 140 | 4 |
Enemy skill `stat_type` follows the same rename (STR -> ATK, INT -> MAG, AGI -> SPD). Skill/weapon `acc` fields stay in the data, unused.

## 7. Levels and XP (D27, D30)
Level resets to 1 every run; cap 10. EXP needed to leave level L (L = 1..9): 12, 24, 40, 58, 80, 105, 135, 170, 210 (cumulative to L9 624, to L10 834).
EXP per kill is unchanged (`enemy.exp` x level factor). One clean pass of the ten floors supplies about 750 EXP (balance-data.md section 3), so:
**Target: level 9 when the final boss starts (8 at the very least, 10 only after optional/elite fights); level 4-5 at the mini boss (floor 5); level 7 on entering floor 7.**
This is the number to check in the run simulator; a full winning run is 25-30 minutes (D112, which supersedes 45-60).

## 8. Run and initiative
Run (flee) succeeds with `clamp(0.5 + 0.05 * (SPD_player - SPD_enemy), 0.10, 0.95)` (one `random(1)`; bosses still cannot be fled). The first actor is whoever the timeline (section 11) picks first, which is the higher SPD; a tie goes to the player (`Combat_PlayerActsFirst` states the same rule).

## 9. Data export (`-exportdata`)
`DD-Project.exe -game data.win -exportdata` writes `export_data.json` (classes, enemies, skills, items, statuses, level table, constants) to the save area
and exits; the gate wrapper (`-Only exportdata`) copies it to `<WorkRoot>\export`. The simulator reads that file plus `combat-vectors.json`.

## 10. Statuses (packet B2: D21, D24, D59, D78, D79)
Player and enemy use the same rules. **All three damage-over-time statuses coexist** (the old `excludes` rule is gone). A status entry is
`{ id, turns, power, stacks }`; `Status_Add(ch, id, turns, power, stacks = 1)`. Fixed durations are data on the status (`StatusDB_Get(id)`), not
multiplied per skill any more, so a skill tooltip shows the real number (BUG-16). The defence bar (D59/D21) can only shorten or reduce, never lengthen.
When a status ticks: `Status_Tick(ch, acted = true)` runs once per TURN of its owner: the player after each of his own actions (a stunned turn counts, `acted = false`),
an enemy after its last action of the turn. `Status_ActionTick(ch)` is the per-ACTION part (bleed only); an enemy with a chain of actions bleeds after every action.

| status | applies | tick | duration / stacks | other effect |
|---|---|---|---|---|
| Poison | `stacks` per hit (skill field `status_stacks`, default 1; Poison Arrow 3, Poison Mist 4, Poison Fangs 2, Curse 2) | HP -= stacks, then stacks -= 1 (the entry is removed at 0). Total from n stacks = n(n+1)/2 | no turn limit; max 10 stacks; reapply ADDS stacks (clamped to 10); `turns` mirrors `stacks` (ticks left) | MAG -1 |
| Burning | refreshes | HP -= `power` = `burn_tick(caster MAG)` (below), fixed at the moment it is applied | 2 turns; no stacking; reapply refreshes turns to 2 and power to the newer value | DEF x0.75 while it burns |
| Bleeding | +1 stack per hit (`status_stacks`) | only when the bleeder ACTS: HP -= 2 x stacks (once per action, `Status_ActionTick`); a stunned turn does not hurt | 3 turns (counted per turn, acting or not); max 3 stacks; reapply adds a stack and refreshes the turns to 3 | SPD -2 |
| Foresight | self buff (Mage) | none | exactly 3 of the player's turns: it is not ticked on the turn it is cast (`no_tick_on_apply`) | reveals the enemy's next action (below) and widens every Perfect zone of the player's QTEs x1.5 |

```
burn_tick(MAG)   = max(2, round_half_up(0.3 * MAG))           MAG = the caster's effective MAG when the hit lands
burning_def(DEF) = max(1, round_half_up(DEF * 0.75))          effective DEF while Burning (Combat_EffectiveStat)
poison_total(n)  = n * (n + 1) / 2                            HP lost by n stacks left alone; n clamped to 1..10
bleed_tick(s)    = 2 * s                                      HP per action of the bleeder with s stacks (1..3)
```
Examples: Mage L1 (MAG 12) Fireball burns 4 x 2 turns; MAG 39 (L10) burns 12 x 2. A Slime (DEF 7) burning has DEF 5. Poison Arrow 3 stacks = 3+2+1 = 6 HP; a second
Arrow on the 2nd tick adds 3: 2+3 = 5 stacks -> 5+4+3+2+1 = 15. Bleeding with 3 stacks hits for 6 per action. Starting numbers, tuned by BAL-02.
Equipment `status_turn_bonus` (+1 status turn): +1 to burn/bleed turns, +1 poison stack when the player applies it.

**Defence bar and statuses (D21, D59):** the grade acts on what the hit ADDED, never on what the player already had. Poison: added stacks go through
`Qte_DefenceStatusTurns(grade, added)` (Perfect 0 = resisted, Good halves, OK takes a quarter off, Weak all; never below 1 unless resisted). Burn and Bleed: the turns
are shortened by the same function; Perfect puts the status (stacks, power, turns) back to how it was before the hit. Nothing here can lengthen a status.

**Curse (final boss):** `status_chance` (0.50) is rolled once PER status (Burning, Poison 2 stacks, Bleeding). The log names only the statuses that really landed;
if none did, it says the curse fails. Curse has no defence bar.

**Foresight (D79, D24):** `Battle_EnemyNextActionPreview()` returns `{ visible, kind ("skill" | "attack" | "stunned"), skill_id, name, big, text }` and is `visible` only
while the player has a status with `reveals_action` (Foresight). The enemy's action is decided once, ahead of time, and stored in the battle (`enemy_plan`); the enemy then does
exactly that, unless it is no longer allowed (an HP-gated skill, no MP) in which case it chooses again. Until the turn bar (D74/D99) shows it, the log gets one line
"You foresee: <action>" per enemy action (at the start of each player turn while Foresight lasts, and at once when it is cast). Perfect zones: the attack bar and the defence bar get
`perfect_half_width x 1.5` (`Qte_WidenPerfect`); an arrow sequence gets `fast_ms x 1.5` (`Qte_SeqNew(seq, assist, perfect_widen)`). The `always_hit` flag and the
"consumed by the next attack" rule are gone.

**HUD data (pure, no drawing):** `Status_DisplayList(ch)` -> `[{ id, name, turns, stacks, tick, label, negative, icon_sprite, icon_subimg }]` (one row per status; `label`
is "x3" for stacks, "2t" otherwise); `Status_Describe(id, data = undefined)` -> `{ id, name, line, turns, stacks, tick, ... }` where `line` is the plain sentence with the real numbers (D100).


## 11. Turn timeline, stun push-back, stagger and BREAK (packet B3: D19 D74 D75 D79 D92)
Replaces the old "higher SPD acts first, then alternate" flow and the old rule "a stun gives the player extra actions" (S1 exploit). Nothing in a battle
alternates any more: `Turn_Next` says who acts.

**Gauge.** Each fighter has an integer gauge, start 0. `TURN_GAUGE_MAX = 100`. One tick adds the fighter's effective SPD (`max(1, SPD)`, read again before every turn,
so Bleeding SPD-2 slows it) to its gauge. `Turn_Next`: if nobody's gauge is >= 100, tick until somebody's is. Then the fighter with the HIGHEST gauge acts; equal gauges go to the
player (the first fighter in the list). The actor's gauge loses 100 (the overflow is kept), so a fighter with 2x SPD acts about 2x as often and one with 3x SPD about 3x.
`Turn_Preview(n = 5)` runs the same on a copy and returns the next n actors' ids; it changes nothing, and it is exactly what the next n `Turn_Next` calls will return
unless something (a stun, a BREAK, an SPD change) happens in between.
```
ticks_needed(f) = ceil((100 - gauge) / SPD)        advance every gauge by SPD x min over fighters of max(1, ticks_needed)
first actor (both gauges 0): the higher SPD; a tie -> the player
```
Examples: Archer 13 vs Slime 9: P E P E P P E P E P P E ...; 20 vs 10: P P E P P E; 10 vs 10: P E P E.

**Stun (D75).** A stun that lands on a fighter (a skill's `status_chance` roll, the Stun status, Hilt Bash, Ice Spear, Vine Trap) is not a lost turn any more:
`gauge -= 100` (a boss as the TARGET: `gauge -= 50`, "half as far"), and the fighter becomes **Steadfast** for 2 of its own turns: a stun that lands while `steadfast > 0` does
nothing. `steadfast` goes down by 1 each time the fighter is picked by `Turn_Next` (its turn starts). Pushing back never gives anybody an extra action. A stun that hits
a fighter whose turn is far off simply pushes it further back.

**Stagger (D75, D92).** Only the enemy has a meter. Every damaging hit of the player adds
```
stagger_gain(power, stun_skill, perfect) = max(1, round_half_up(power x 0.5 x (2 if the skill stuns) x (1.5 if the grade is Perfect)))
   power = the hit's formula power (section 4, before the grade); a multi-hit skill adds it once per hit
stagger_max(rank, boss) = (4 + 4 x rank) x (2 if boss)       rank = threat rank 1..4 (basic_power 3/5/7/9)
```
Slime/Spider/Snake/Wolf 8, Mad Whisp/Killer Plant/Ghost Sword/Stranger 12, Palehorn (rank 3, boss) 32, Pale Choirbeast (rank 4, boss) 40.
When `stagger >= stagger_max` the enemy is **BROKEN**: the meter resets to 0, its gauge loses 100 (pushed back one turn, bosses too), and until its next turn starts it
takes **+50% damage** (`mult x 1.5` in section 4's product). While broken the meter does not fill. The enemy's next turn clears BROKEN. A hit that causes the BREAK is not
itself boosted. Examples: a Wooden Sword basic hit (power 6) adds 3 (OK) or 5 (Perfect: 4.5 -> 5); Hilt Bash (power 11, stuns) adds 11, or 17 on a Perfect (16.5 -> 17).

**HUD data (pure):** `Battle_TimelineSlots(bc)` -> up to 5 `{ who (0 player, 1 enemy), current (the first), foresight (the Foresight preview, only on the first enemy slot while Foresight lasts) }`.
Animation: when the order changes the strip slides for 120 ms (D97).


## 12. Battle AI, telegraphed big attacks, boss phases (packet B4: D7 D59 D68 D75 D79 D80)
Replaces "every skill rolls its own use chance, then the basic attack" (`Battle_EnemyChooseSkill`, `enemy_use_chance_*`) and the boss "double action" skills
(Rampage, Fury). Readable and learnable (D68): a short priority list per enemy, with a weighted default so it is never fully predictable.

**Brain (data).** Every enemy record has `brain = { rules, weights, phases }`, copied to the battle enemy (`e.brain`).
```
rule   = { label, when: [cond, ...], act: "attack" | "skill", skill, chance (default 1), max_uses (default -1 = no limit) }
cond   = { c, v, status }      all conds of a rule must hold
weight = { act: "attack" | "skill", skill, w }
phase  = { at, spd_add, atk_add, banner (localization key suffix), banner_text (English), rules, weights }     bosses only
```
Conditions (`c`): `always`; `hp_below v` (own HP / max <= v); `hp_above v` (>= v); `player_hp_below v`; `player_buffed` (the player has any status that is not
negative: `Status_IsNegative`); `player_has_status` / `player_missing_status` (`status`); `player_status_at_least` (`status`, `v` = stacks; a status
without stacks counts 1); `self_has_status` / `self_missing_status`; `every_nth v` (this is the enemy's own turn number T and `T mod v == 0`; v >= 2).

**`EnemyAI_Choose(e, p, ctx, rng)`** is pure (no globals except the databases) and returns `{ kind: "attack" | "skill" | "windup", skill_id (-1 = basic attack), rule (label) }`.
`ctx = { turn (1-based own turn number), phase, uses (label -> times used), windup (-1 or a skill id), used_turn (skills used this turn), actions_left,
force_damage_only }`; `rng` is a stream from `Rng_New` (the game passes the "combat" stream), so a seed gives the same choices.
1. `ctx.windup >= 0`: the wind-up is paid, the big attack comes: `{ skill, windup, rule "windup_attack" }`. No random number is drawn.
2. Lists = the rules and weights of phase `ctx.phase` (0 = the base lists; phase n replaces them completely).
3. Rules in order: the first rule whose conds all hold, whose action is usable and whose `uses < max_uses` wins; if `chance < 1` one `Rng_Float` is drawn and the rule fires
   only when it is below `chance` (otherwise the next rule is tried).
4. Else one `Rng_Float` picks from the weights that are usable, in proportion to `w`. Nothing usable = the basic attack.
5. A skill is usable when the enemy has it in `e.skills` (a rule naming a skill the enemy does not have is skipped, so `e.skills = []` means basic attacks only),
   `Skill_CanUse`, `Skill_EnemyCanTrigger` (the skill's own gates: HP ratio, status missing, inventory, actions left) and not `enemy_once_per_turn` already used this turn.
6. If the chosen skill has `telegraphed` the result is `kind "windup"` instead (same `skill_id`), unless step 1 produced it or `force_damage_only` (debug) is on.
`force_damage_only` picks, with `Rng_Int`, one usable damaging skill (basic attack if none).

**Telegraph (D7, D59).** A skill with `telegraphed: true` is a heavy move: it is announced for one turn, then it is used with the defence bar. It also has
`uses_defensive_qte` and a row in `Qte_DefenceParams`. Starting value: heavy moves have `power_mult 2.0` (D111, E1-4; it was 1.5).
- The wind-up turn: the enemy does no damage and no status. `ai.windup = skill`, the log/banner says `windup_msg` ("Palehorn lowers its horns!"), the enemy's slots on the turn strip
  wear a "!" mark while the wind-up is pending. The enemy's turn counter still advances.
- The next enemy turn is the big attack (step 1), through the defence bar; `ai.windup` becomes -1.
- **BREAK during the wind-up cancels it** (D75): `EnemyAI_Break(st)` clears `windup` and returns the cancelled skill; the cached plan is dropped, the log says
  "{enemy}'s {skill} is broken off!". The BREAK push-back and +50% damage still apply. A stun does not cancel it.
- Foresight (D79): the preview shows the wind-up turn ("winding up X") two actions ahead and then the big attack itself, both marked big.

**Own turn counter.** `ai.turns` counts finished enemy turns (a free action does not end the turn; a wind-up does). `ctx.turn = ai.turns + 1`.

**Phases (bosses).** `EnemyAI_PhaseFor(brain, hp_ratio)` = how many phases have `at >= hp_ratio` (phases are ordered by falling `at`). `EnemyAI_PhaseSync(st, e)` moves
`st.phase` forward only (healing never goes back), applies `spd_add` / `atk_add` to `e.stats` for every phase reached (so a hit that skips a phase still gets both), drops the cached plan,
and returns `{ changed, phase, banner }` (the banner of the last phase reached). The game calls it when the timeline advances and when a plan is made; the banner
is shown as a battle message at the start of the enemy's next action. SPD is read again every turn (section 11), so a phase's extra SPD is simply more turns.
No boss has a double action any more: Rampage and Fury stay in the skill table (ids are stable) but no enemy has them; Curse and Blessing stay as in B2.

**New skills** (starting numbers): Regrow 28 (heal self, power 5, MAG: +5 + floor(MAG/4)); Snuff 29 (removes every non-negative status of the player); Gore 30 (ATK power 4, Bleeding 70%,
3 turns, no bar); Pale Hymn 31 (MAG power 5 x2.0, telegraphed, defence bar). Telegraphed: Vine Trap, Cut, Ramming, Pale Hymn (all at `power_mult 2.0` since D111; Pale Hymn is MAG power 5 x2.0).

**Rule lists** (turn T = the enemy's own turn; "windup X" = X is telegraphed):
| enemy | rules (in order) | default weights |
|---|---|---|
| Slime | `solidify_when_hurt`: hp <= 50% and no Solidify -> Solidify | attack 4, Solidify 1 |
| Spider | `no_stacking_past_4`: player Poison >= 4 stacks -> attack; `open_with_poison`: player not poisoned, 60% -> Poison Fangs | attack 3, Poison Fangs 1 |
| Snake | `no_stacking_past_3`: player Bleeding >= 3 -> attack; `open_with_bite`: player not bleeding, 50% -> Bite | attack 2, Bite 1 |
| Dire Wolf | `howl_first`: no Bloodthirsty, 50% -> Bloodthirsty | attack 1 |
| Mad Whisp | `snuff_buffs`: player buffed -> Snuff | attack 3, Scorching Touch 2 |
| Killer Plant | `low_hp_heal`: hp <= 40%, once per battle -> Regrow; `vine_every_3rd`: every 3rd turn -> windup Vine Trap | attack 1 |
| Ghost Sword | `cut_every_3rd`: every 3rd turn -> windup Cut | attack 1 |
| Stranger | `grab_when_hurt`: hp <= 50%, once -> Steal | attack 5, Steal 1 |
| Palehorn | `ram_every_3rd`: every 3rd turn -> windup Ramming | attack 1 |
| Palehorn phase 1 (<= 60%: SPD +2) | `ram_every_3rd` | attack 2, Gore 1 |
| Palehorn phase 2 (<= 30%: SPD +2, ATK +3) | `ram_every_2nd`: every 2nd turn -> windup Ramming | attack 1, Gore 2 |
| Pale Choirbeast | `hymn_every_4th`: every 4th turn -> windup Pale Hymn | attack 3, Curse 1 (Curse keeps its own gate: HP <= 70%) |
| Choirbeast phase 1 (<= 60%: SPD +2) | `bless_when_bare`: no Blessing, 50% -> Blessing (free action); `hymn_every_3rd` | attack 2, Curse 1 |
| Choirbeast phase 2 (<= 30%: SPD +3, ATK +3) | `hymn_every_2nd` | attack 2, Curse 1 |
Banners (English draft, Korean in the workbook): Palehorn 1 "Palehorn paws the ground, snorting!", 2 "Palehorn bellows in a blind rage!"; Choirbeast 1 "The Pale Choirbeast sings a second voice!",
2 "The Pale Choirbeast howls in fury!". Wind-up lines: Vine Trap "{enemy} coils its vines!", Cut "{enemy} raises its blade!", Ramming "{enemy} lowers its horns!", Pale Hymn "{enemy} draws a deep breath!".
No enemy heals, defends or flees beyond these (no such skills exist; "flee" is not built).
