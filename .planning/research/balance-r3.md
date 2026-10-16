# Balance round 3 (D186, D191, D192, D193): what changed and what the sim says

Branch `feat-r3balance` (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\balance`). Sim: `tools/balance/sim.py`, average profile, seed 1, 2000 runs per class, the committed export of the final build (`d9e8ae8`, the build with everything below).

## Win rate, average floor, minutes of a winning run (average QTE profile)

"Before" = the committed sim and export at b898477 (no Guard, weak points not in the export). Floor and minutes are from a 600-run pass of the same seed (a win counts as floor 9.5).

| Class | Win before | Win after | Avg floor before | after | Win-run minutes before | after |
|---|---|---|---|---|---|---|
| Archer | 98.1% | 77.6% | 9.45 | 8.21 | 19.7 | 21.7 |
| Knight | 96.2% | 77.5% | 9.32 | 8.29 | 22.0 | 23.5 |
| Mage | 54.7% | 69.0% | 7.83 | 7.88 | 21.1 | 22.0 |
| Nobody | 36.4% | 36.1% | 6.01 | 5.97 | 24.1 | 24.7 |

Archer, Knight and Mage are inside the owner's 60-85% band. **Nobody is not (36%)** and small nudges do not get it there: it has no skills, so everything that hardens fights (D191 BREAK, D193 gold) lands on it. See "Nobody" below.

How the number moved, step by step (400-run passes unless marked):

| Step | Archer | Knight | Mage | Nobody |
|---|---|---|---|---|
| HEAD, stale export, old sim (2000) | 98.1 | 96.2 | 54.7 | 36.4 |
| + current export (weak points on) | 98.2 | 94.8 | 51.2 | 38.5 |
| + Guard D180 + Meditation fix (sim only) | 98.5 | 95.2 | 81.0 | 37.0 |
| + first class nudges (D186 alone, 2000) | 95.0 | 85.9 | 80.2 | 64.5 |
| + D191 BREAK, D192 SPD, D193 gold, no class nudges | 85.2 | 91.2 | 69.0 | 17.0 |
| final: D191-D193 + retuned class nudges (2000) | 77.6 | 77.5 | 69.0 | 36.1 |

## Step 1: the sim tells the truth (R-118)

- (a) Weak points: the game already exports `weak` / `resist` per enemy and `sim.py` already played them; the committed export was simply from before D173. Re-exported and snapshotted (3 commits of the export, the last is the final build).
- (b) Guard (D180, `STATUS_BRACE` 14) is modelled: halves every hit until the player's next turn starts (not counted down by his own tick; ends at his next turn start once the enemy has acted; a fast player who guards and is up again first keeps it), gives back `max(2, floor(25% max MP))` capped at max MP. When the greedy player guards (never twice in a row, never when one more attack ends the fight): (1) the enemy winds up a telegraphed hit worth 25% of max HP or more; (2) a caster in a fight that is not easy cannot pay for its cheapest skill, has no MP potion, is above half HP, and the MP Guard gives would pay for it; (3) a hit that could kill him is coming, he has no potion, and half of it he survives.
- (c) The forced card pick: the pick itself was fine (best of the three, always one). The bug was the VALUATION of Meditation in `Policy.attack_options`: it was worth `3 MP x n turns x price`, ignoring max MP, so the Mage cast it at the start of every fight with a full bar (a wasted turn, +3 MP that did not fit) and the cards that offered it looked valuable. Now it is worth only the MP that fits under max MP (plus the room its own casts make). Mage 54.7% -> 81.0% from this alone; a Mage who took Meditation was winning 38-48% against 86-94% without it.

## Game numbers changed (every one)

| Where | Old | New | Why |
|---|---|---|---|
| Knight start SPD (`scr_db_player_class`) | 10 | 9 | D186: speed was the strongest lever on Knight/Archer win rate |
| Wound power (`scr_db_skill`, Knight and Archer) | 4 | 3 | D186: second Knight lever; Archer shares it (Wound+ becomes 3 > 5) |
| Archer start ATK / SPD | 9 / 13 | 8 / 12 | D186: Archer sat at 85% after D191-D193 and 98% before |
| Nobody start ATK / DEF / SPD | 8 / 8 / 9 | 10 / 9 / 12 | D186: lifts Nobody from 17% (D191-D193 alone) to 36% |
| Stagger meter, every enemy (`Stagger_Max`) | 8 / 12 normal, boss 32 / 40 | x1.5: 12 / 18, boss 48 / 60 | D191 |
| Multi-hit skill stagger fill (`Battle_StaggerHit`) | gain x hits | one hit's gain | D191 (Double Shot no longer fills twice) |
| Stun skill stagger multiplier (`STAGGER_STUN_MULT`) | 2 | 1.5 | D191 |
| Turn gauge speed (`TURN_SPD_BASE`) | SPD | 10 + SPD | D192 |
| Turns in a row (`TURN_MAX_IN_ROW`) | unlimited | 2 (the third goes to the other side) | D192 |
| Enemy gold (`GOLD_BASE`, `GOLD_PER_LEVEL`) | 10 + 2 x level | 3 + 0.5 x level | D193 |
| Coin Purse card gold | 15 | 8 | D193 |

Tried and left alone: Archer SPD growth on even levels only and Horizontal Slash power 4 (both in the first nudge set, taken back after D191-D193 made them unneeded); fists power 2 -> 5 (lifted Nobody to 61% but Archer to 94%: every class fights unarmed until it finds a weapon, so it is not a Nobody lever); Nobody throw multiplier / throw cap / passive values (no effect in the sim).

## Nobody

With D191-D193 and no class nudge it is 17%. What small nudges give: stats 10/9/12 -> 36%. Next steps if the owner wants it in the band, with the sim's answer (400 runs, on top of the final numbers): growth +1 ATK +1 SPD a level 47%; +1 ATK +1 DEF +1 SPD a level 53% (Nobody would reach ATK 33 at level 10, Knight 20); fists 5 together with the stats 61-69% (but Archer 94%). The honest fix is a starter skill or passive for Nobody (a new mechanic, outside this packet). Its deaths (a 400-run pass, 274 deaths): floor 3 elites 100, floor 4 elites 53, Palehorn 74.

## D191: BREAK frequency (player turns per BREAK against a normal enemy, average profile)

| Class | Before | After |
|---|---|---|
| Archer | 4.0 | 6.1 |
| Knight | 4.0 | 6.4 |
| Mage | (10.0, inflated by the Meditation bug) | 8.5 |
| Nobody | 4.7 | 7.6 |

(A BREAK per normal fight: 0.9 before, 0.55-0.71 after; fights are also longer.)

## D192: player turns per enemy turn (long-run ratio on the timeline, enemy SPD from the export: Slime 9, Dire Wolf 11)

| Class (level) | SPD before > after | vs Slime before > after | vs Dire Wolf before > after |
|---|---|---|---|
| Archer L1 | 13 > 12 | 1.44 > 1.16 | 1.18 > 1.05 |
| Archer L5 | 17 > 16 | 1.89 > 1.37 | 1.55 > 1.24 |
| Knight L1/L5 | 10 > 9 | 1.11 > 1.00 | 0.91 > 0.90 |
| Mage L1/L5 | 10 > 10 | 1.11 > 1.05 | 0.91 > 0.95 |
| Nobody L1 | 9 > 12 | 1.00 > 1.16 | 0.82 > 1.05 |
| Nobody L5 | 11 > 14 | 1.22 > 1.26 | 1.00 > 1.14 |

(The Nobody gets faster on purpose: D186 nudge, and its turns are worth less with no skills.)

## D193: gold at the merchants (sim, average profile, 60 runs per class; merchants are after floors 2, 5 and 8)

The first merchant is on floor 2, the second on floor 5, the third on floor 8; there is no floor-3 merchant. "Room 3" in the owner's words is most likely the second or third (before: 281 and 570 gold against stock of 430 and 510).

| Merchant | Gold carried before > after | Stock value (13-14 items) | Cheapest-first affordable before > after | Items the sim player buys before > after |
|---|---|---|---|---|
| Floor 2 | 41 > 13 | about 360 | 3.1 > 1.0 | 1.5 > 0.6 |
| Floor 5 | 281 > 82 | about 430 | 10.5 > 4.1 | 3.9 > 2.5 |
| Floor 8 | 570 > 125 | about 510 | 13.6 > 5.0 | 1.7 > 1.9 |

Median item price is 26-36 gold, so a typical run now carries gold for about 1-2 items at the first merchant and 2-4 cheap ones later; the whole shelf is out of reach (before the third merchant could buy all of it). If the owner wants it tighter: `GOLD_BASE` 3 -> 2 gives 10 / 71 / 106 gold. Gold sources in the game: enemy drops (`Gold_ForEnemy`), the Coin Purse card, and selling items; chests, barrels, graves and events hold no gold, so nothing else needed cutting.

## Checks

- `tools/balance/test_sim.py` 75 tests OK; `check_combat_vectors.py` OK 137 vectors; `sim.py --vectors` OK 144.
- New: `ExportCarriesWeakPoints`, `GuardCommand`, `GuardPolicy`, `ForcedPick` (python); `Test_Suite_R3Balance` (stats, Wound, fists, stagger, turns, gold) in `scr_test`.
- Gate on the final build: `-Mode fast`, `-Only smoke` and `-Only bot` each print GATE PASS (an earlier run of each printed GATE FAIL only for `REAL SAVE FILES CHANGED` while the owner was playing).
- Assertions changed because a number changed are listed in the packet report (63 names: class vectors, stagger / turn vectors, enemy meters, C3 gold, D111 / R1b / levelup-screen Knight SPD lines, 4 bot status-cost lines are unchanged in text but their battle now has a harmless enemy).
