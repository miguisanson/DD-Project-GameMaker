# H4 balance check (D143): free point may go to Max HP +3 or Max MP +2

No balance number in the game was changed. The simulator (`tools/balance/sim.py`) now lets the free point of each level go to Max HP (+3) or Max MP (+2)
instead of the class stat, and these are the win rates before and after.

## How the simulator picks (kept simple)

At every level-up the class stat point (already counted in the class table) competes with Max HP and Max MP, valued like a card pick:

- class stat: how many HP-equivalents per fight the stat saves (the simulator's expected-fight value) times the fights left;
- Max MP: the same expected-fight value, plus 2 MP x 0.9 for now and for every bed still to come;
- Max HP: 3 HP now and at every bed still to come (the fight model does not see max HP, so this is only the refill value).

The highest value wins, the class stat on a tie. Typical run (20 seeds): Max HP chosen about 5 times in 8 level-ups, Max MP about once, the class stat for the rest.

What-if knobs (no game change): `--tweak constants.free_point_choices=0` plays the old way (always the class stat), `constants.free_point_hp_gain` /
`constants.free_point_mp_gain` change the amounts. The `=0` run of the knight reproduces the before number exactly (86.2%).

## Win rates (2000 runs, profile average, same export of build 5d1aa03)

| Class  | Before | After | Change |
|--------|-------:|------:|-------:|
| Knight | 86.2%  | 86.4% | +0.2   |
| Archer | 89.3%  | 89.2% | -0.1   |
| Mage   | 79.8%  | 82.0% | +2.2   |
| Nobody | 21.9%  | 24.3% | +2.4   |

Commands: `python tools/balance/sim.py --runs 2000 --class <knight|archer|mage|nobody> --profile average --data <export_data.json from run_tests.ps1 -Only exportdata>`.

## Proposal

None. No class moved more than 3 points (largest: Nobody +2.4, Mage +2.2), so there is no number to change. Nobody stays far below the other classes
(21.9% before, 24.3% after); that gap exists without this change and is not part of H4.

Caveat for the owner: the simulator values Max HP only through refills (it cannot see the "survive one more hit" value), so the real effect of Max HP may be
larger than shown. A playtest of a few level-ups with Max HP is the check that matters.
