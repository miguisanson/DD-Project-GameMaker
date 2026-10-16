# Sim check: what moved Nobody since 7f4d08e

Read-only: nothing edited or committed in any repo. Scratch is E:\Temp\dd-simcheck. The six worktrees I added are removed.

**Commands:** `git worktree add --detach E:\Temp\dd-simcheck\<n> <rev>` for 7f4d08e, b2b56ac, 98427fa, 0d703b0, 6d5c606, 755bed1. In each, `python -I <wt>/tools/balance/sim.py --runs 400|2000 --class all --profile average --seed 1 --json ...`, using the committed export. Isolation runs used the 755bed1 sim with `--data <old export>`, `--tweak constants.vigmnd=0`, and old export plus one new section. Class what-ifs used `--tweak "classes[Nobody].stats.def=9"` and similar. One scratch copy of sim.py had a changed card-pick rule.

Of 23 first-parent merges, only b2b56ac (Skip removal, sim.py), 0d703b0 (VIG/MND, export refresh) and 755bed1 (weak-point code) touched `tools/balance`. All the others give identical numbers. Current `next` (b898477) has no later balance change.

## Results (average profile, seed 1, 2000 runs; 400 runs agree within noise)
Win rate, with average floor reached in brackets (a win counts as 9.5).

| commit | Archer | Knight | Mage | Nobody |
|---|---|---|---|---|
| 7f4d08e (playtest build) | 99.1 (9.5) | 96.7 (9.3) | 92.0 (9.2) | 52.6 (7.1) |
| b2b56ac, Skip removed | 99.0 | 97.0 | **58.2** (8.1) | 52.6 |
| 0d703b0 export refreshed | 98.1 | 96.2 | 54.7 (7.8) | **40.1** (6.2) |
| 755bed1 HEAD | same | same | same | same |

A winning run takes 19.7 / 22.0 / 21.1 / 24.0 min (Archer / Knight / Mage / Nobody). The export was only refreshed in 0d703b0; at 7f4d08e and b2b56ac the sim ran on stale build e9685dc data. HEAD's export has no weak/resist data and sim.py does not model Guard D180, so HEAD's numbers include neither (checked by reading, not by a run).

## Why
1. **Nobody 52.6 to 40.1 is not VIG/MND.** With `constants.vigmnd=0` on the new export it is still 37.8% (400 runs). The cause is the `skills` section of the export. Poison Fangs, Bite and Scorching Touch lost their player defence bar. The game made them plain moves on Oct 14 (34bcac3, I-066, before 7f4d08e). The old export still had the bars, so the 48.5% baseline was too easy. The new 37-40% is the truer number for the build the owner played. Nobody relies most on the bar (lowest DEF). Chest loot and `no_tick_on_apply` changes did nothing.
2. **Mage 92 to 58 is mostly a sim artifact.** The old sim skipped 39% of Mage's offers because it valued them near 0. With no Skip it is forced to take them (Meditation, Foresight, Ice Spear, Poison Mist). If cards valued under 0.05 are not taken, Mage returns to 89.8%. Why those picks cost so much I did not trace. Treat Mage 55-58% as pessimistic.
3. VIG/MND is nearly neutral: Mage loses 1-3 points, Archer and Knight at most 1.

## Current balance
Archer 98% and Knight 96% are saturated. Mage is about 55% and Nobody about 40%. Both die mostly to the floor 5 mini-boss. Nobody's own target band is 15-30% (targets.json), so it is already above it.

## Suggestions (not applied; 400 runs, plus or minus 2.5 points)
- **Nobody up:** DEF 8 to 9 gives 43.5% (from 37.8%). Adding SPD 9 to 10 too gives 57.8%, which is too much. ATK 8 to 9 does nothing.
- **Archer down:** it is saturated, so levers are weak. ATK 9 to 8 gives 96.8%, SPD 13 to 12 gives 97.2%, and both give 97.5% (from 98.5%). SPD 13 to 11 gives 96.0%. A real narrowing needs harder enemy numbers overall, not Archer nerfs.
- **Mage:** do not tune on this sim. ATK 5 to 6 or DEF 7 to 8 does nothing. First fix the sim's forced-pick fallback, or judge Mage in the next playtest.
- Re-snapshot the export from the current build and add Guard D180 to the sim before trusting HEAD numbers.
