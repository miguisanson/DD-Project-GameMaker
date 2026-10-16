# VIG / MND: old vs new Max HP and Max MP (D176, D177, D184)

Old = the silent per-level growth (Resource_MaxHp / Resource_MaxMp), the free point on the class's usual stat (Knight DEF, Archer ATK, Mage MAG, Nobody ATK).
New = Max HP from VIG, Max MP from MND, the free point on a stat other than VIG / MND. Percent = new against old.

Curves: HP = 10 + 3 per VIG point above 10 up to VIG 28, then 2 per point up to VIG 38, then 1. MP = 10 + 1 per MND point above 10 up to MND 44, then 1/2 up to 56, then 1/4 (floored).
Start: VIG 10 for every class; MND Knight 11, Archer 12, Mage 16, Nobody 11.

Growth on reaching a level (besides the ATK / DEF / SPD / MAG growth that did not change):

| Class | VIG | MND |
|---|---|---|
| Knight | +2, +2, +3 repeating (levels 2,3 / 4 / ...: +3 on levels 4, 7, 10) | +1 |
| Archer | +2 | +2 |
| Mage | +2 on even levels, +1 on odd | +3 |
| Nobody | +2 | +1, +2 on levels 5 and 9 |

## Knight

| Level | VIG | MND | HP old | HP new | HP % | MP old | MP new | MP % |
|---|---|---|---|---|---|---|---|---|
| 1 | 10 | 11 | 10 | 10 | +0% | 11 | 11 | +0% |
| 2 | 12 | 12 | 17 | 16 | -6% | 12 | 12 | +0% |
| 3 | 14 | 13 | 24 | 22 | -8% | 13 | 13 | +0% |
| 4 | 17 | 14 | 31 | 31 | +0% | 14 | 14 | +0% |
| 5 | 19 | 15 | 38 | 37 | -3% | 15 | 15 | +0% |
| 6 | 21 | 16 | 45 | 43 | -4% | 16 | 16 | +0% |
| 7 | 24 | 17 | 52 | 52 | +0% | 17 | 17 | +0% |
| 8 | 26 | 18 | 59 | 58 | -2% | 18 | 18 | +0% |
| 9 | 28 | 19 | 66 | 64 | -3% | 19 | 19 | +0% |
| 10 | 31 | 20 | 73 | 70 | -4% | 20 | 20 | +0% |

## Archer

| Level | VIG | MND | HP old | HP new | HP % | MP old | MP new | MP % |
|---|---|---|---|---|---|---|---|---|
| 1 | 10 | 12 | 10 | 10 | +0% | 12 | 12 | +0% |
| 2 | 12 | 14 | 16 | 16 | +0% | 14 | 14 | +0% |
| 3 | 14 | 16 | 22 | 22 | +0% | 16 | 16 | +0% |
| 4 | 16 | 18 | 28 | 28 | +0% | 18 | 18 | +0% |
| 5 | 18 | 20 | 34 | 34 | +0% | 20 | 20 | +0% |
| 6 | 20 | 22 | 40 | 40 | +0% | 22 | 22 | +0% |
| 7 | 22 | 24 | 46 | 46 | +0% | 24 | 24 | +0% |
| 8 | 24 | 26 | 52 | 52 | +0% | 26 | 26 | +0% |
| 9 | 26 | 28 | 58 | 58 | +0% | 28 | 28 | +0% |
| 10 | 28 | 30 | 64 | 64 | +0% | 30 | 30 | +0% |

## Mage

| Level | VIG | MND | HP old | HP new | HP % | MP old | MP new | MP % |
|---|---|---|---|---|---|---|---|---|
| 1 | 10 | 16 | 10 | 10 | +0% | 16 | 16 | +0% |
| 2 | 12 | 19 | 15 | 16 | +7% | 19 | 19 | +0% |
| 3 | 13 | 22 | 20 | 19 | -5% | 23 | 22 | -4% |
| 4 | 15 | 25 | 25 | 25 | +0% | 26 | 25 | -4% |
| 5 | 16 | 28 | 30 | 28 | -7% | 30 | 28 | -7% |
| 6 | 18 | 31 | 35 | 34 | -3% | 33 | 31 | -6% |
| 7 | 19 | 34 | 40 | 37 | -7% | 37 | 34 | -8% |
| 8 | 21 | 37 | 45 | 43 | -4% | 40 | 37 | -7% |
| 9 | 22 | 40 | 50 | 46 | -8% | 44 | 40 | -9% |
| 10 | 24 | 43 | 55 | 52 | -5% | 47 | 43 | -9% |

## Nobody

| Level | VIG | MND | HP old | HP new | HP % | MP old | MP new | MP % |
|---|---|---|---|---|---|---|---|---|
| 1 | 10 | 11 | 10 | 10 | +0% | 11 | 11 | +0% |
| 2 | 12 | 12 | 16 | 16 | +0% | 12 | 12 | +0% |
| 3 | 14 | 13 | 22 | 22 | +0% | 14 | 13 | -7% |
| 4 | 16 | 14 | 28 | 28 | +0% | 15 | 14 | -7% |
| 5 | 18 | 16 | 34 | 34 | +0% | 16 | 16 | +0% |
| 6 | 20 | 17 | 40 | 40 | +0% | 17 | 17 | +0% |
| 7 | 22 | 18 | 46 | 46 | +0% | 19 | 18 | -5% |
| 8 | 24 | 19 | 52 | 52 | +0% | 20 | 19 | -5% |
| 9 | 26 | 21 | 58 | 58 | +0% | 21 | 21 | +0% |
| 10 | 28 | 22 | 64 | 64 | +0% | 22 | 22 | +0% |

## Every free point into VIG (or MND): is it easy mode?

One free point a level (levels 2..10) all on VIG; compared with the same class with the points elsewhere, and with the OLD 'free point = +3 Max HP' (Max HP +3 each).

| Class | HP at 10, points elsewhere | HP at 10, all on VIG | gain | gain in the old system (+3 a point) | MP at 10, all on MND | MP gain |
|---|---|---|---|---|---|---|
| Knight | 70 | 86 | +16 (+23%) | +27 | 29 | +9 |
| Archer | 64 | 82 | +18 (+28%) | +27 | 39 | +9 |
| Mage | 52 | 74 | +22 (+42%) | +27 | 48 | +5 |
| Nobody | 64 | 82 | +18 (+28%) | +27 | 31 | +9 |


## Run difficulty: tools/balance/sim.py, old numbers vs new

600 whole runs per class and skill profile, same seed (1), the committed export; "old" = `--tweak constants.vigmnd=0` (silent HP/MP growth, free point may buy Max HP +3 / Max MP +2),
"new" = `--tweak constants.vigmnd=1` (VIG / MND curves above, free point may go to VIG / MND). Win rate of the run (reaching and beating the final boss); the rest of a run is a death.

| Class | Profile | Win old | Win new | Death old | Death new |
|---|---|---|---|---|---|
| Archer | novice | 98.0% | 97.7% | 2.0% | 2.3% |
| Archer | average | 98.5% | 98.5% | 1.5% | 1.5% |
| Archer | expert | 99.3% | 99.3% | 0.7% | 0.7% |
| Knight | novice | 90.3% | 92.3% | 9.7% | 7.7% |
| Knight | average | 96.7% | 97.2% | 3.3% | 2.8% |
| Knight | expert | 98.2% | 98.7% | 1.8% | 1.3% |
| Mage | novice | 51.2% | 49.3% | 48.8% | 50.7% |
| Mage | average | 60.3% | 60.5% | 39.7% | 39.5% |
| Mage | expert | 60.0% | 62.3% | 40.0% | 37.7% |
| Nobody | novice | 32.0% | 32.0% | 68.0% | 68.0% |
| Nobody | average | 48.5% | 48.5% | 51.5% | 51.5% |
| Nobody | expert | 71.5% | 71.5% | 28.5% | 28.5% |

Read: every cell moves by 2.3 points or less (the 95% interval of a cell is about +-4 points), so run difficulty is unchanged. The Knight is a little easier (the free point on VIG buys a real
3 HP early); the Mage a little harder at novice level (it has the least HP and no longer gets MP from MAG); Nobody and Archer do not move (the simulator never prefers VIG / MND to the class stat for them).
