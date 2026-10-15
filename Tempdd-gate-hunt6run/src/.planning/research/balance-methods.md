# Balance methods: how to balance this game properly and verifiably

Researched 2026-10-13. Web research plus a read of `scripts/scr_combat/scr_combat.gml` and `scr_math.gml` (no game code changed).

Confidence tags used below:
- **[verified]** I fetched the page and it says this.
- **[search-only]** Came from a search summary, not read in full. Treat as a lead.
- **[computed]** I calculated it myself with a short Python script (scratchpad, not in the repo). Re-run before relying on it.
- **[my synthesis]** Design judgement. Not a sourced fact.

---

## 0. Findings that matter most for this game

1. **The "4-5 missed slashes" is expected maths, not a bug.** `Combat_AttemptHit` rolls `d20 + acc_bonus >= d20 + dodge_bonus` (ties hit). With equal bonuses that is a 52.5% hit chance. A swing at 52.5% misses 4 times in a row 5% of the time at any given start, and a run of 4+ misses appears in 30 swings 57% of the time. [computed] Opposed d20 rolls also make the hit chance move only about 4-5 percentage points per point of bonus difference, so small stat changes are hard to feel and large ones swing a lot. [computed]
2. **The player never sees the hit chance and has no protection from streaks.** Both are things shipped games add on purpose (sections 2.2 to 2.4).
3. **Damage uses tiny integers with a subtractive rule:** `max(1, weapon.power + StatMod(stat) - floor(StatMod(DEF)/2))`, with `StatMod = floor((stat-10)/2)`. That is the style that works at 8-bit scale, but it is flat (no per-hit variance except crits) and `always_hit` / `force_dodge` statuses already exist, so guaranteed-hit skills are cheap to add. See section 1.
4. **The fix is a process, not a formula:** put every skill, enemy and floor into one CSV, simulate fights thousands of times in Python, and check the results against written target numbers. Section 6 gives the process.

---

## 1. Damage formulas and progression curves

### 1.1 Formula families

| Family | Shape | Good | Bad | Fit for small numbers / 8-bit |
|---|---|---|---|---|
| Subtractive | `ATK - DEF` (often with a minimum of 1) | Easy for players to read and for you to hand-check. Used by Fire Emblem and many older games. | DEF above ATK means zero damage, so stats must be kept in a narrow band. Forum designers report it makes the "playable" range narrow and grindy. | Best fit if you keep numbers small and set a floor. Your current formula is this family. |
| Ratio | `ATK / (ATK + DEF)`, or `2*ATK/(ATK+DEF)` | Smooth. Never reaches zero. Equal stats give a fixed fraction. | Needs a tuned constant. Hard to compute by eye with small integers; rounding hurts at low values. | Poor with tiny integers (rounding dominates). Fine if you keep floats and round once at the end. |
| Multiplicative / percent | `base * (1 - DEF%)` or buckets multiplied together (Diablo 3 style, Darkest Dungeon protection %) | Stacking never breaks the floor. Easy to cap (Darkest Dungeon caps PROT at 80%). | Buckets multiply into extreme swings; defence and resist amplify each other. | Good for buffs, debuffs and elements (+25% / -25%), because percentages work at any scale. |

Sources:
- Community comparison of the three families (a forum-based summary, **[search-only]**): https://rpgmaker.net/forums/topics/25546, https://rpgmaker.net/forums/topics/19829, https://omnimaga.org/other-calculator-discussion-and-news/(rpg)-what-damage-formulas-do-you-use
- Darkest Dungeon protection is a flat percentage reduction of direct damage, capped at 80%, and does not apply to bleed/blight damage-over-time **[verified]**: https://darkestdungeon.wiki.gg/wiki/Damage
- Darkest Dungeon II sums attacker and defender modifiers separately, then multiplies the two sums **[search-only]**: https://darkestdungeon.wiki.gg/wiki/Combat_Mechanics_(Darkest_Dungeon_II)
- RPG Maker's default style is `a.atk * 4 - b.def * 2` with 20% variance. That specific default was **not confirmed**, but the formula syntax and 20% variance are **[search-only]**: https://rpgmaker.net/forums/topics/12686

**Recommendation [my synthesis]:** keep the subtractive core for basic attacks (matches your code and 8-bit feel), but make three changes: (a) add a damage range (for example +/-15%, Pokémon uses 85-100%) so a "miss" streak is not replaced by a "same number every time" feel; (b) express skills as a *multiplier on weapon damage* (x1.0, x1.5, x2.0), not as separate hand-written numbers; (c) use percentage buckets only for buffs, debuffs and elements, with a cap per bucket.

### 1.2 How the classics do it

- **Pokémon (Gen 3+ style, Smogon):** `((((Level*2/5)+2) * BasePower * Atk/Def)/50 + 2) * modifiers`, with a random factor of 85-100% and integer rounding after each step **[verified]**: https://www.smogon.com/dp/articles/damage_formula . This is a ratio formula where level *and* attack/defence ratio both scale damage. The official open calculator is the readable reference (section 5).
- **Dragon Quest I (NES) [search-only, a fan walkthrough]:** attack minus half of defence, then a random multiplier of 25-50%; about a 1/32 chance of a critical hit that ignores defence for 50-100% of attack; if defence is at least the monster's attack, damage is only 0 to about one sixth of the monster's attack. The same guide notes spells use fixed random ranges instead. Source: https://gamercorner.net/dw/walkthrough/game-systems . A disassembly exists for checking: https://github.com/nmikstas/dragon-warrior-disassembly (the README does not document the formula; you would read `source_files`). **I could not confirm any later Dragon Quest formula; do not quote one.**
- **Final Fantasy VI [search-only]:** level feeds into both physical and magic damage, Strength is doubled and added to attack, stat bonus caps at 128, and spell damage depends on spell power, level and magic. Group-cast spells do half damage. I did not get the full formula. https://finalfantasy.fandom.com/wiki/Final_Fantasy_VI_stats
- **Octopath Traveler [search-only]:** the power curve comes from a *system*, not just stats: enemies have shield points and weakness icons; hitting a weakness removes shield; breaking an enemy skips its turn and cuts its defence; Boost Points spend to add hits or power. The related mobile game documents six buff/debuff groups that multiply, with a per-bucket 30% cap and a separate per-hit damage cap (a community wiki, flagged unverified by its own authors). https://vulkk.com/2023/02/24/how-combat-works-in-octopath-traveler-2-beginners-guide/ , https://meowdb.com/db/octopath-traveler-cotc/the-ultimate-guide-to-buffs-and-debuffs
- **Darkest Dungeon [verified]:** damage is a min-max range per class/weapon tier, rolled uniformly, then modified; criticals do 1.5x the *maximum* of the range; hit chance is `skill ACC + hidden 5 - target DODGE`; displayed 95%+ is a guaranteed hit; there is always at least a 5% chance. https://darkestdungeon.wiki.gg/wiki/Damage

**Takeaway [my synthesis]:** these games differ in formula but share one habit: the *formula stays simple* and the *content tables* (monsters, skills) carry the tuning. Do the same here.

### 1.3 Level / XP curves

- Three common shapes: linear (`+constant per level`), exponential (`threshold_n = threshold_{n-1} * k`), and "linear increments" (the *increase* between levels grows by a fixed step). The Game Developer article prefers the third as a compromise, warns exponential is hard to tune (too low gives a flat curve, too high makes late levels unreachable), and says to **check time between levels, not just XP numbers** **[verified]**: https://www.gamedeveloper.com/design/quantitative-design---how-to-define-xp-thresholds-
- A power form `threshold = x * level^y` is common; one forum example uses x=1000, y=1.5 **[search-only]**. A worked comparison of linear, logarithmic, quadratic and exponential curves with the geometric-series closed form is at https://davideaversa.it/blog/gamedesign-math-rpg-level-based-progression/ **[search-only]**.
- Pokémon names its level scaling right inside the damage formula (`Level*2/5 + 2`), so player and enemy power both grow with level **[verified]**, Smogon link above.

**Recommendation for ~10 floors [my synthesis]:** do not use an XP curve as the balance mechanism. Make power *per floor* the unit: the player's expected stats at the start of floor N come from a small table (CSV) built from gear + level, and each floor's enemies are set against that row. Then verify with the simulator. An XP curve is just the delivery system for the table.

---

## 2. Hit chance and perceived fairness

### 2.1 What players actually perceive

- **Sid Meier, GDC 2010 "The Psychology of Game Design" [search-only]:** playtesters complained about losing at 3:1 odds in their favour but did not complain about winning at 3:1 against them; a loss at "20 vs 10" upset players more than a loss at "2:1" even though the maths is identical. His team concluded the system "cannot just be math-based" and changed the game so outcomes felt right. Sources: https://gameinformer.com/b/news/archive/2010/03/12/sid-meier-gamers-arent-logical , https://www.museumofplay.org/blog/gdc-2010-game-psychology-101/ , quote check **[verified]** at https://forums.civfanatics.com/threads/gdc-wrapup-of-sid-meiers-keynote.357409 ("The player feels like the computer rolled that random number just to be difficult.")
- **XCOM's "95% miss":** a 95% shot still misses 1 in 20, and players remember misses more than hits **[search-only, forum-based]**. Community analysis of the game's config shows hidden *aim assist* bonuses on shots above 50% (capped at 95%) that favour the player and are partly difficulty-dependent; these are community reports, not official, **[search-only]**. Sources: https://steamcommunity.com/app/268500/discussions/0/2944746708998250511 , https://www.nexusmods.com/xcom2/mods/212 . A designer essay confirms XCOM 2 secretly boosts hit chances on lower difficulties and recommends at least disclosing that such modifiers exist **[verified]**: https://section214.com/page/2/ ("How Random Number Generators Shape Player Trust in Game Design", 2026-07-28).
- The same essay gives the key stat: a 20% crit chance has about an 11% chance of ten attacks in a row without a crit, and players read that as a broken system **[verified]**.

### 2.2 Streak maths for your hit chances [computed]

Probability of seeing *at least one* run of 4+ misses in a row:

| Hit chance | Run of 4 misses at a given swing | In 30 swings | In 100 swings |
|---|---|---|---|
| 52.5% (equal bonuses, current rule) | 5.1% | 57% | 95% |
| 60% | 2.6% | 37% | 80% |
| 75% | 0.4% | 8% | 25% |
| 85% | 0.05% | 1.2% | 4% |
| 90% | 0.01% | 0.2% | 0.9% |

So the owner's friend's 4-5 consecutive misses is the normal outcome at a ~50% rate and uncommon above ~80%.

Opposed d20 hit chance by (attacker bonus - target dodge) [computed]: -4 -> 34%, -2 -> 43%, 0 -> 52.5%, +2 -> 62%, +4 -> 70%, +6 -> 77%.

### 2.3 Techniques that fix streaks

| Technique | How it works | Evidence | Fit |
|---|---|---|---|
| **Pseudo-random distribution (PRD)** | Chance on the Nth attempt since the last success is `C*N`, with C chosen so the long-run average equals the nominal chance. Streaks become short and bounded. | Dota 2 / Warcraft 3 critical strikes. Dota wiki: https://dota2.fandom.com/wiki/Pseudo-random_distribution (402 on fetch; description via search **[search-only]**). Dotabuff claims a chain of three procs is about 1 in 200 under pure chance but about 1 in 10,000 under PRD **[search-only]**: https://www.dotabuff.com/blog/2016-01-03-pseudorandom-mechanics--and-how-to-use-them-to-your-advantage . Liquipedia gives C = 8.47% for a 25% proc, which my script matches **[computed]**. | Best general fix for crits and skill procs. |
| **Streak breaker / hidden accuracy bonus** | After N misses, raise (or force) the next hit. | Darkest Dungeon has a hidden +4 ACC per consecutive miss after the first **[verified]**: https://darkestdungeon.wiki.gg/wiki/Damage . City of Heroes' "Streak Breaker" forces a hit after a long miss streak; shorter allowed streak at higher hit chance **[search-only]**: https://tvtropes.org/pmwiki/pmwiki.php/Main/BadLuckMitigationMechanic | Simple to write in GML (one counter). Apply it to the player *and* the enemy so it is not a cheat. |
| **Fire Emblem 2RN "true hit"** | Roll two numbers, average them. Chances above 50% become higher than displayed, below 50% lower. | Fire Emblem Wiki table **[verified]**: displayed 20 -> 8.2 actual, 50 -> 50.5, 80 -> 92.2, 100 -> 100. (My own check of the mean-of-two-rolls rule gives 80 -> 92.2, 90 -> 98.1, 30 -> 18.3 **[computed]**, matching the wiki.) Used from The Binding Blade through Awakening and again in Three Houses; Fates, Shadows of Valentia and Engage use a hybrid (1RN below 50%, a curved formula above). https://fireemblemwiki.org/wiki/True_hit . A designer note calls it "a simplification to the point of lying" but says it makes attacks feel consistent: https://diplograph.net/notes/games/randomness/lie-about-probability **[verified]** | Good if you show hit % in the UI. It makes good odds feel reliable and bad odds feel hopeless. |
| **Fire Emblem "Grandmaster"/damage-scaled mode** | Every attack hits, damage is scaled by the displayed hit chance. | Lex Talionis engine docs **[verified]**: https://lt-maker.readthedocs.io/en/latest/source/editors/database-editors/Difficulty-Modes-Editor.html | Shows you can offer this as a *difficulty mode*. |
| **Pity timer / guarantee** | Force the rare outcome after N failures. | Section214: PRD suits frequent low-stakes procs; pity timers suit rare rewards; disclose hidden modifiers **[verified]**. | Use for item drops, not for attacks. |
| **Skip hit rolls entirely** | Replace miss chance with a resource. | Hard West uses a luck attribute that each shot's hit chance depletes, instead of a roll **[search-only]**: https://en.wikipedia.org/wiki/Hard_West | Possible but a larger redesign. |

Warning to remember [search-only]: players can exploit streak breakers by deliberately low-value attacks until the guaranteed hit; one designer suggests reserving them for less critical mechanics. Use a *bounded* approach (PRD or a small bonus) and keep the counter hidden.

PRD constants for common targets [computed, my script]:

| Nominal chance | C | Longest possible miss streak |
|---|---|---|
| 5% | 0.38% | 263 |
| 10% | 1.47% | 67 |
| 20% | 5.57% | 17 |
| 25% | 8.47% | 11 |
| 30% | 11.89% | 8 |
| 40% | 20.15% | 4 |
| 50% | 30.21% | 3 |
| 70% | 57.14% | 1 |
| 80% | 75.00% | 1 |

### 2.4 Accuracy vs evasion, and whether skills should miss at all

- **Opposed rolls (what you have) are the hardest to read.** The hit chance cannot be shown with one number and moves in small steps. Darkest Dungeon's `ACC - DODGE` with a floor of 5% and a guaranteed-hit threshold at 95% is a more readable model **[verified]**.
- **My recommendation [my synthesis]:** (1) basic weapon attacks keep a miss chance, shown to the player as a % in the battle UI (computed from the opposed-roll tables above, or switched to `base - dodge`); (2) **most skills should not miss at all** (or have a 90-95% floor), because the player already paid MP and a QTE for them, and a miss feels like paying twice; (3) offensive status effects (poison, stun) get their own *separate* application chance, shown on the skill description, so the damage is reliable and the extra is the gamble; (4) `always_hit` already exists as a status flag, so a "guaranteed" skill type costs nothing to add.
- Note that your game has a QTE on attacks. If the QTE already measures skill, a hit roll on top of it double-penalises the player. Decide as an owner rule: **QTE success changes damage or effect, not whether the attack lands.** (This is a design decision for the owner, not a sourced fact.)
- The playtester asked for a "tiny" skill hit-rate increase. The maths says a tiny bonus will not remove the problem (each +1 bonus is about +4.5 points); a streak breaker or a switch to guaranteed hits will.

---

## 3. Skill balancing methods

### 3.1 The core idea: a cost curve

Game Balance (Schreiber & Romero, CRC Press 2021) has chapters titled *Transitive Mechanics and Cost Curves*, *Progression in PvE Games*, *Intransitive Mechanics and Payoff Matrices*, probability, luck and skill, analytics, and spreadsheet technique throughout (Excel and Google Sheets) **[chapter titles verified via the British Library catalogue entry; chapter contents not read]**: https://eld.bl.uk/catalog/020203409 , publisher: https://www.routledge.com/9781498799577 . The standard technique is: pick a common currency (here, "damage-equivalent"), give each ability a *cost* and a *benefit* in it, and fit a curve so everything sits near the line. Anything far above the line is overpowered, anything far below is useless. **[my synthesis of the standard method]**

### 3.2 Efficiency tables to build (one row per skill, in the CSV)

| Column | Meaning |
|---|---|
| `mp_cost` | MP spent |
| `expected_dmg` | `hit_chance * (1 + crit_chance*(crit_mult-1)) * avg_damage`, against a reference target on each floor |
| `dmg_per_mp` | `expected_dmg / mp_cost` (undefined for 0-MP basic attack) |
| `dmg_per_turn` | `expected_dmg`, plus the DoT/utility value converted to damage |
| `extra_turns` | turns the skill costs (setup, channel, recovery) |
| `status_value` | expected extra damage from poison, stun, buff, debuff (section 3.3) |
| `role` | single-target burst, AoE, sustained, control, support |
| `unlock_floor` | when the player can first use it |

Rules of thumb [my synthesis]:
- A skill that costs MP must beat the free basic attack by a margin that covers the MP's opportunity cost. If 1 MP is worth about X damage (set by how much MP the player has per fight), then `skill_damage - basic_damage >= X * mp_cost`. The Pointclair itch.io balancer compares "burst output, sustained output, and output per resource" and notes the highest damage number is not the strongest ability **[search-only]**: https://pointclair.itch.io/ability-cooldown-resource-efficiency-balancer
- Every skill needs a *situation* where it is clearly the best pick: a weakness, a number of enemies, a boss-only window, a low-MP pool, or a setup turn. If two skills share a role, one must be cheaper-and-weaker or costlier-and-stronger on the line, not both strictly better and cheaper.
- Compare skills **across the same level of the game** (same floor), never in isolation.

### 3.3 Status effects: poison, buffs, debuffs

- Poison/DoT: convert to expected damage by `dmg_per_tick * expected_remaining_ticks`. It is only worth its MP if the fight lasts longer than the poison's duration, so **poison value depends on the fight-length target** (section 6). If normal fights are 3-5 turns, a 5-turn poison is mostly wasted on normal enemies and strong on bosses. That is a legitimate role split, but it needs to be stated.
- Make DoT a percentage of max HP for bosses or use flat numbers capped per tick; flat poison dwarfs a small number pool and % poison trivialises bosses. Darkest Dungeon deliberately makes protection not apply to bleed/blight so DoT keeps value against armour **[verified]** Darkest Dungeon wiki link in section 1.2.
- The friend reported "I don't take dmg while being poisoned." That is a bug candidate (poison on the player not ticking or being absorbed); check it before any poison balancing.
- Stacking rules to write down once and enforce in code: the same effect refreshes duration, does not stack strength; different sources stack up to a cap; buff and debuff buckets multiply with a per-bucket cap. Octopath's mobile game uses a per-bucket 30% cap plus a per-hit damage cap (unverified community wiki) **[search-only]**, and Darkest Dungeon caps PROT at 80% **[verified]**. In a small-number game, +/-20-25% steps and a +/-50% cap are plenty. [my synthesis]
- Darkest Dungeon subtracts a monster's stun resist from the skill's stun chance and applies only if the attack hits; chances are additive, so more than 100% is needed to beat 100% resistance **[search-only, forum-sourced]**. A subtractive "status chance minus resist" rule is simple and fits your style.

### 3.4 Role differentiation checklist

Write one line per skill: *"Use this when ___, instead of ___, because ___."* If you cannot finish the sentence, the skill has no use case yet. Review the list for two failures: a skill that is never the answer (delete or buff), and a skill that is always the answer (nerf or raise cost).

---

## 4. Verifiable balancing

### 4.1 Method [my synthesis, supported by the sources]

1. **One source of truth:** `balance/*.csv` (skills, enemies, floors, player stats per floor, difficulty profiles, status effects). The game and the simulator read the same data.
2. **A Python simulator** that implements the *same* rules as `scr_combat.gml` (hit, dodge, crit, damage, status ticks, difficulty multipliers) and plays full battles with simple scripted policies (for example "basic attack only", "best skill by dmg/MP", "always buff first"). Run 10,000 battles per matchup with a fixed seed so results are reproducible.
3. **Report** win rate with a confidence interval, mean and spread of turns-to-kill, damage taken, and MP used.
4. **A regression test:** a small file of target ranges (section 6) run in CI or before each commit; the build "fails" if a changed number pushes a metric outside its band. This is the same idea as a unit test, applied to numbers.
5. **A parity test** so the simulator cannot silently drift from the game: add a GML debug run that fights a fixed set of seeded battles and prints results, then compare with Python. AGENTS.md Rule 1 says a GML assertion block from a debug entry point counts as the check here.

Expected simulation effort: the Game Developer 2003 article ran about 10,000 trials (2,000 showed "unacceptable variance") and used sensitivity charts to see which input moved the outcome most; that is still the right size **[verified]**: https://www.gamedeveloper.com/design/applying-risk-analysis-to-play-balance-rpgs . For win-rate estimates, 10,000 runs give about +/-1 percentage point at 95% confidence. [computed from binomial standard error; my synthesis]

### 4.2 Metrics that are worth tracking

- **Turns-to-kill (TTK)** and **turns-to-die (TTD)** are "the foundation of combat balance" and easier to evaluate in a spreadsheet than a running game **[verified]**: https://www.abratabia.com/game-design/game-balance.php . The same page gives playtest bands: 10-20% death rate per section is a good target for action games, above 50% is too hard unless optional, near 0% too easy; and 45-55% win rate is balanced for competitive modes **[verified]**. (Those bands are for other genres; use them as a sanity check, not a target.)
- **Attrition:** HP and MP lost per fight, and how much a floor drains before the player reaches rest or heal.
- **Variance:** the spread of outcomes, not only the mean. A "balanced" average with a fat tail is exactly the "4-5 misses in a row" complaint.
- **Skill usage in the simulator:** which skill the best policy picks and how often. Any skill used under ~5% or over ~60% needs review.

### 4.3 Tools and articles

- Ian Schreiber, Game Balance Concepts (free online course, 2010): https://gamebalanceconcepts.wordpress.com/ **[verified exists; the full post list was not read]** (I read only Level 10, which covers economic systems, an Excel tutorial, and refers to earlier weeks on pseudorandomness and shuffling). Free earlier course: *Game Design Concepts* (2009) syllabus PDF: https://www.inventoridigiochi.it/wp-content/uploads/2020/07/Game_Design_Concepts.pdf **[search-only]**. Free RIT/edX course "Video Game Design and Balance" taught by Schreiber (2017 run; check whether it is open now) **[search-only]**: https://courses.edx.org/courses/course-v1:RITx+GAME102x+1T2017/9017d9b6425e4e419d1da1a77309292c
- GDC 2016 "A Course About Game Balance" (Schreiber): abstract only; the Vault is members-only so I could not read the slides **[search-only]**: https://gdcvault.com/play/1023349/A-Course-About-Game
- *Game Balance*, Schreiber & Romero (2021): https://www.routledge.com/9781498799577 (see section 3.1).
- Game Developer, "Applying risk analysis to play balance RPGs" (2003): the base-case / constants / variables / equations method with Monte Carlo and Excel Goal Seek and Solver **[verified]**, link in 4.1.
- Game Developer, "The art of game balance: evolution" (2024, Breno Azevedo, part 1 of 3): https://www.gamedeveloper.com/design/the-art-of-game-balance-evolution **[search-only; not read]**.
- A 2025 paper comparing Lanchester's laws with Monte Carlo for RPG duels found Monte Carlo more stable **[search-only]**: https://ph.pollub.pl/index.php/jcsi/article/download/8353/5300/39336
- Python combat simulators I found are small or old: CombatWiz (win rate, mean rounds, mean HP lost; Python 2-era) https://pypi.org/project/CombatWiz/ and ama-xiv-combat-sim (NumPy, full damage distributions for FFXIV) https://pypi.org/project/ama-xiv-combat-sim **[search-only]**. **I did not find a ready-made, maintained Python RPG balance simulator.** Writing your own (about 200 lines for these rules) is the realistic route.
- Spreadsheet-only guide with TTK/TTD examples: https://www.abratabia.com/game-design/game-balance.php **[verified]**. Winterwolves blog on row/column sum checks for classes: https://www.winterwolves.net/blog/tag/game-balancing/ **[search-only]**.

---

## 5. GitHub references (readable formulas and data)

| Repo | URL | What to look at | Checked |
|---|---|---|---|
| smogon/damage-calc | https://github.com/smogon/damage-calc | `calc/src/mechanics/` for the damage formula per generation; `calc/data/` for the data tables. MIT licence. Best example of "formula in code, data in tables, tests for both". | Page read [verified]; mechanics file contents not read. |
| pret/pokered | https://github.com/pret/pokered | Disassembly of Pokémon Red/Blue; `engine/battle/core.asm` (includes `engine/battle/` files such as `trainer_ai.asm`, `experience.asm`, `effects.asm`), `data/` for move and stat tables. Shows how an 8-bit game stored and computed everything with small integers. | Folder listing [verified]; formula locations in the files not read. |
| nmikstas/dragon-warrior-disassembly | https://github.com/nmikstas/dragon-warrior-disassembly | Full commented disassembly of Dragon Warrior (NES); read `source_files` for the damage routine and monster tables. The closest match to "8-bit, small numbers". | Exists and is complete [verified]; formula not located. |
| FireEmblemUniverse/fireemblem8u | https://github.com/FireEmblemUniverse/fireemblem8u | Decompilation of Fire Emblem: The Sacred Stones (needs your own ROM to build); look in `src` for the hit/RNG code (true hit). | Exists [verified]; RNG location not confirmed. |
| Lex Talionis (lt-maker) | docs: https://lt-maker.readthedocs.io/ (source hosted on GitLab per community guides; I did not confirm the repo URL) | Python Fire Emblem engine with an editable RNG method (Classic, True Hit, True Hit+, Grandmaster, Lucky), growth methods and difficulty modes. Good model for "difficulty mode changes the dice, not just the numbers". | Docs page [verified]; repo URL [unverified]. |
| wesnoth/wesnoth | https://github.com/wesnoth/wesnoth | Open-source turn-based strategy game, GPL v2+. Unit stats are data files in `data/`; combat resolves hit chance per strike from terrain defence. A good example of a data-driven balance with a very mature community. | Repo [verified]; unit-data and combat file paths not confirmed. |
| kuryart/godot-jrpg | https://github.com/kuryart/godot-jrpg | MIT, early-stage JRPG framework (Godot) with configurable formulas for damage, hit, crit, a database for skills/status, and a stated plan to separate logic from UI so battles can run as simulations. Small (about 90 commits). | Page read [verified]; the actual formulas not shown. |
| Pokémon Showdown simulator | https://github.com/smogon/pokemon-showdown | The battle simulator that damage-calc keeps its data in sync with; a full headless battle engine, useful as an example of separating rules from UI. | Named in damage-calc README; repo itself not opened. |

Honest note: no repo I found is a small 8-bit-scale RPG with a CSV of skills and a Monte Carlo script. The closest fit to your needs is smogon/damage-calc plus the Dragon Warrior disassembly for the 8-bit scale.

---

## 6. Recommended balancing process for this game

All numbers below are **proposed targets [my synthesis]** for the owner to adjust; none come from a source.

### 6.1 Step 0: facts first (no balancing yet)

1. Extract the current numbers into CSVs from `scr_db_skill.gml`, `scr_db_enemy*` and the player stat code: for each skill (MP, power, accuracy bonus, status, duration), each enemy (HP, stats, skills, floor), each floor (enemy list), and each difficulty profile (`player_damage_mult`, `enemy_damage_mult`, `enemy_status_chance_mult`).
2. Check the poison bug ("I don't take dmg while being poisoned") before using poison in any model.
3. Decide the open questions with the owner (use grill-me): do skills miss? does the QTE change damage or hit chance? is there a hit-% display?

### 6.2 Step 1: choose target numbers (proposal)

| Metric | Target |
|---|---|
| Normal fight length (TTK, player using a reasonable mix of attack + skill) | 3-5 turns |
| Mini-boss | 6-10 turns |
| Floor boss / final boss | 10-16 turns |
| Player HP lost in a normal fight | 10-25% of max HP |
| Player MP spent in a normal fight | 15-30% of max MP |
| A floor (several fights, no rest) | drains about 60-80% of HP and MP, so resting/healing matters but is not forced every fight |
| Win rate per normal fight, normal difficulty, average play | 97%+ (death should come from a streak of bad choices across a floor, not one fight) |
| Win rate per mini-boss / boss, normal, first attempt | 70-85% for a mini-boss, 55-75% for a boss |
| Easy / Hard | Easy: +10-15 points win rate; Hard: -15-20 points, same fight lengths. Change enemy stats and damage multipliers only; never change hit rules by difficulty without telling the player. |
| Longest miss streak the player will see | 3 (PRD or a streak breaker) |
| Skill usage in the simulator (best policy) | each skill used 5-60% of the time; no skill at 0% |

Each target is a band in a `targets.csv`, and the Python check fails if a metric falls outside its band.

### 6.3 Step 2: build the model

- Python simulator (section 4.1) with three scripted player policies: *basic attack only*, *greedy best dmg-per-turn skill*, *good play (buffs/poison when worthwhile)*.
- Output tables: per floor and difficulty, the metrics above, plus a skill-efficiency table.
- Keep the player policy "average" rather than perfect; Schreiber's course and the 2003 article both stress modelling realistic play (the 2003 article's example was players finding a trick the model had not expected) **[verified for the 2003 article]**.

### 6.4 Step 3: fix structure before numbers

In this order: (1) hit rules (section 2: PRD or streak breaker, guaranteed-hit skills, shown %), (2) damage range, (3) status stacking rules, (4) then per-skill numbers from the cost curve, (5) then enemy and floor numbers to hit the targets.

### 6.5 Step 4: owner playtests feed back

- Give the owner a short form per session: floor reached, where they died, and for each fight "too easy / right / too hard", plus one free-text line. Turn those into the same metrics as the simulator (deaths per floor, fight length, MP left at the end of a floor).
- Where the simulation and the owner disagree by more than ~10 points on win rate or ~2 turns on fight length, trust the owner and look for a missing rule in the simulator (for example, QTE failing, or players not using a skill).
- Perception comes from the Section214 and Sid Meier material: players remember vivid failures, so playtest notes about "unfair" misses should be checked for *streaks* (log the hit/miss sequence), not just averages **[verified, sources in 2.1]**.
- Add an optional debug log in-game: one line per attack (attacker, target, roll, hit/miss, damage, status) written to a file, so a bad session can be replayed through the simulator.

### 6.6 Step 5: lock it in

- Commit the CSVs, the simulator, `targets.csv` and the last run's report together.
- Run the simulator before every balance-touching commit. A change is accepted only if the targets still pass.
- Keep the changelog of numbers in `.planning/STATE.md` (per the repo rule that it is the single source of truth).

---

## 7. Open questions for the owner (to resolve with grill-me, not guess)

1. Should skills be able to miss at all? Recommendation: no, with statuses holding the gamble. [my synthesis]
2. Does QTE success change damage, hit chance, or the status application chance?
3. Show a hit % in the UI (2RN-style true hit or plain `base - dodge`), or keep it hidden?
4. Is a hidden bad-luck protection acceptable, or should it be disclosed (Section214 recommends at least disclosing that modifiers exist)?
5. Is a "no randomness" (damage-scaled) mode wanted as a difficulty option (as in the Lex Talionis Grandmaster mode)?
6. Target fight lengths: confirm 3-5 turns for a normal fight, and the boss lengths above.

---

## 8. Source index

Verified (read the page): https://fireemblemwiki.org/wiki/True_hit , https://www.smogon.com/dp/articles/damage_formula , https://darkestdungeon.wiki.gg/wiki/Damage , https://diplograph.net/notes/games/randomness/lie-about-probability , https://section214.com/page/2/ , https://www.gamedeveloper.com/design/quantitative-design---how-to-define-xp-thresholds- , https://www.gamedeveloper.com/design/applying-risk-analysis-to-play-balance-rpgs , https://www.abratabia.com/game-design/game-balance.php , https://lt-maker.readthedocs.io/en/latest/source/editors/database-editors/Difficulty-Modes-Editor.html , https://forums.civfanatics.com/threads/gdc-wrapup-of-sid-meiers-keynote.357409 , https://gamebalanceconcepts.wordpress.com/ , https://github.com/smogon/damage-calc , https://github.com/pret/pokered , https://github.com/nmikstas/dragon-warrior-disassembly , https://github.com/FireEmblemUniverse/fireemblem8u , https://github.com/wesnoth/wesnoth , https://github.com/kuryart/godot-jrpg .

Search-only (not read in full): the other links named above. Blocked on fetch (403/402): bulbapedia, liquipedia, dota2.fandom, dotabuff, gamedev.stackexchange.

Not found: an authoritative Dragon Quest series damage formula; Final Fantasy VI's complete formula; the exact Game Balance (Schreiber & Romero) chapter text; any maintained Python RPG balance simulator.
