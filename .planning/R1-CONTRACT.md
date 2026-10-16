# R1 contract — fairer randomness (D117-D125, owner grill 2026-10-15)

Checks (written first, by the main session): `Test_Suite_FairRng` at the end of `scripts/scr_test/scr_test.gml`,
the two `runsave: ... dry-fight counter` asserts in `Test_Suite_RunSave`, the regenerated `vec run_*` vectors
(`tools/balance/check_combat_vectors.py`, `.planning/research/combat-vectors.json`). Removed (function gone, replaced
by the D123 asserts): "C3 shuffle: about 15% of map enemies are elites (255..345 of 2000)", "C3 shuffle: the elite roll
of one enemy never changes", "C3 shuffle: which enemies are elites depends on the seed (...)".
Do not edit any of these checks. Balance numbers do not change except as stated here.

## R1a — game logic (scr_loot, scr_combat, scr_status, scr_save, scr_room_state, scr_macros as needed)

**D117 tier first, then item.** In `Loot_Init` add `global.loot_tier_odds` = per table, per container level 1..3,
`[low, mid, high]` (these keep today's effective odds; do not change them):
- chest: `[0.87, 0.115, 0.015]`, `[0.65, 0.285, 0.065]`, `[0.43, 0.38, 0.19]`
- barrel: `[0.95, 0.05, 0]`, `[0.85, 0.15, 0]`, `[0.74, 0.26, 0]`
- enemy: `[0.914, 0.084, 0.002]`, `[0.754, 0.236, 0.010]`, `[0.588, 0.376, 0.036]`
`Loot_TierOdds(_table_key, _level)` returns that array (level clamped 1..3; unknown table -> `[1, 0, 0]`).
`Loot_RollTier(_rng, _odds)` -> 1, 2 or 3, as a cascade from the rarest: draw; `< high` -> 3; else draw; `< mid / (1 - high)`
-> 2 (guard high >= 1); else 1. `Loot_RollFromTable` keeps its signature: build the eligible rows per tier (table rows +
`_extra`, same class / exclude / weight > 0 filters as today), roll the tier with `_rng` (or the run's loot stream when
`_rng` is undefined), and if that tier has no eligible rows step DOWN (3 -> 2 -> 1), then UP from the rolled tier; pick a
row within the tier by its `weight` alone (no tier multiplier). Quantity as today. Keep `global.loot_tier_weights`
defined (exported for the old simulator data) but nothing in the game rolls with it any more; export `tier_odds` next to
it in the `-exportdata` loot block (`scr_debug.gml` ~line 4025).

**D118 chests never empty.** Remove the chest table's `item_id:0` "Nothing found" row. Every weapon / armor / accessory
row in every table gets `qty_min: 1` (today 0..1 = nothing half the time). Barrels keep their "Nothing found" row.

**D119 crit marble bag.** `Crit_BagSize(_p)` -> `{ n, reds }`: the smallest n in 1..20 with n*p a whole number (within
1e-6), reds = n*p; if none, n = 20 and reds = round(20*p). `Combat_CritCheck(_attacker, _crit_bonus)` keeps its
signature: chance = `Combat_CritChance(bonus)`; chance <= 0 -> false and the bag is not touched. Otherwise the attacker
struct holds `crit_bag = { p, left: [bools] }`; when it is missing, empty, or its `p` differs from chance, fill it:
reds trues + (n - reds) falses, shuffled with `Rng_Shuffle(Run_Stream("combat"), ...)`. Pop one marble and return it.
`Crit_BagLeft(_f)` = marbles left (0 when there is no bag). `Status_Add` of a status whose config has `crit_bonus > 0`
removes the target's `crit_bag` (re-applying Take Aim starts a fresh bag). Same code path for enemies.

**D120 enemy-drop bad-luck protection.** Macro `LOOT_DRY_STEP 0.1`. `Loot_EnemyDropChance(_base, _dry)` =
`min(1, _base + LOOT_DRY_STEP * _dry)`. `Run_Create` gains `drop_dry: 0`. `Loot_RollEnemy`: when a run is active
use `Loot_EnemyDropChance(chance, run.drop_dry)`; afterwards an item -> `run.drop_dry = 0`, no item -> `+= 1`.
No active run -> today's behaviour, nothing counted. Check the auto-resolve path in `scr_enemy.gml` (~line 126,
`auto_resolve_loot_mult`) still works and say in your report whether it goes through `Loot_RollEnemy`.

**D121 flee.** Macro `FLEE_FAIL_STEP 0.25`. `Battle_RunChance(_spd_player, _spd_enemy, _fails = 0)` =
`min(1, P / (P + E) + FLEE_FAIL_STEP * _fails)` with P = max(1, player SPD), E = max(1, enemy SPD); no lower clamp.
`Battle_RunAttempt` passes the battle's failed-try count (a battle-controller variable starting at 0 each battle) and
adds 1 to it on a failed try. Bosses still cannot be fled.

**D123 elites per floor.** `Shuffle_EliteCount(_floor, _free)`: 0 when `_free <= 0`; else
`c = RoundHalfUp(ELITE_CHANCE * _free)`, `if (floor(_floor) >= 2) c = max(c, 1)`, return `min(c, _free)`.
In `Shuffle_RoomPlan`: shuffle the free slot indices with `Rng_New(_seed, "elite:" + room name)`, the first
`Shuffle_EliteCount(floor, free count)` become elites, each modifier still from `Rng_New(_seed, "mod:" + key)`.
Fixed slots are never elites. Delete `Shuffle_IsElite`. (One room per floor: rm_floorN.)

**D125 run save v2.** `RUN_SAVE_VERSION 2`. `RunSave_Build` writes `drop_dry`; `RunSave_ApplyState` restores it
(default 0). An older run file is already rejected as "old" by the existing check — keep that path.

## R1-sim — the Python simulator (tools/balance/sim.py, test_sim.py only)

Mirror D117-D121 and D123 in `sim.py`: tier-first loot using `loot.tier_odds` when the export has it (fall back to the old
`tier_weights` roll for old export files), chests with no "nothing", gear qty >= 1 (taken from the export), the crit bag
(fresh per buff application, same sizing rule), the enemy-drop dry counter, the flee formula if the sim flees, elites per
floor (same count rule) instead of a per-enemy 15% roll. `python tools/balance/test_sim.py` passes; add cases for each
rule. Then report before/after of `report.py` on the current export: win rate, run length, gold, items per run.

## R1b — screens and text (after R1a merges)

**D122 focus loss.** When the window loses focus (`window_has_focus()` false) while the game is running a room with a
player or a battle, and no other overlay owns input (ui mode NONE, or a battle), open the pause menu; in a battle the
pause menu disables Abandon run and Quit to title (enabled: false, with a help line saying why). The battle and every
`delta_time` clock already stop while `UI_PAUSE` is set. Music is lowered while unfocused and restored exactly on focus.
Pure helper `Focus_ShouldPause(_has_focus, _ui_mode, _in_main_menu, _in_battle, _in_transition)` with GML tests.

**D124 showing the odds.** Take Aim's status line reads "1 in every 4 hits is a critical." (from `Crit_BagSize`, so it
follows the data); the battle command "RUN" shows the current flee chance as a whole percent (e.g. "RUN 50%"), and
"can't" for bosses. New text goes through `game_text.xlsx` (EN + KO draft) -> `build_localization.py`; the hardcoded-text
lint stays clean. `-Only shots` for the battle menu; the main session opens the PNGs.
