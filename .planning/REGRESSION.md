# Regression list

A growing list of things that must stay true. Format and rules are from `research/lessons-from-past-projects.md` section 4.6.

## Rules

- **Every fixed bug adds an entry before its fix merges.** The failing check is the entry. Every new feature adds 1-3 entries for its Done-when.
- Entries are never deleted. An obsolete check is replaced, with the reason written in the Notes column.
- **Per packet:** run the entries tagged with the systems the packet touches, plus their neighbours.
- **Per playtest build:** run all automated entries and walk the manual ones (target 15 minutes at most; if it grows, automate more).
- A review must list which R-ids ran on the merged build, with the build id. **An entry with no run on the current build counts as unchecked, not green.**
- `STATE.md` keeps one number: regressions found by review or playtest since the last stable build. Two in a row stops improvement mode (`IMPROVE.md`).
- Status `PENDING` means the feature or fix is not built yet. The entry is written now so the check exists before the code. It starts counting when its phase lands.

## Check type key

Levels L1-L5 are in `REQUIREMENTS.md`. "Test" names are placeholders until Phase 1 creates the suites; the wrapper must map each automated entry to a real test name (VER-13).

## Entries

| ID | Description (reporter's words where there are any) | Tags | How checked | Status | Added | Last run |
|----|------|------|------|------|------|------|
| R-001 | "Screen bug when a cutscene ends (also places with dialogue)": the intro and ending cutscenes leave a correct view, camera and GUI scale; the last image fades to black and does not vanish first | UI-scale, dialogue/cutscene | L3 + L4: bot plays cutscene end; before and after screenshots have the same geometry; display-apply counter does not move during the transition. L5 owner walks `audit/resolution.md` 4c rows | ACTIVE (fix in Phase 2) | 2026-10-13 | never |
| R-002 | "scale problem. screen bug" / "Resolution/scaling problems in general": HUD and picture correct at 3 resolutions, windowed and fullscreen | UI-scale | L4: `-shots` at each supported size; after Phase 2, every row of `resolution-gamemaker.md` 7.1; pixel checker | ACTIVE | 2026-10-13 | never |
| R-003 | "skill books appear in books twice": no duplicate item ids, no duplicate skill ids, adding book 114 twice leaves one, a pushed duplicate shows once, the Skills tab shows no duplicate | inventory/skills | L2: `Test_Suite_Inventory` and `Test_Suite_Data` | ACTIVE (after Phase 6: also no duplicate card ids in an offer) | 2026-10-13 | never |
| R-004 | Every enemy references existing skills and loot; every loot table id resolves; every `ENEMY_*` creates an enemy | inventory/skills, battle | L2: `Test_Suite_Data` | ACTIVE | 2026-10-13 | never |
| R-005 | "i dont take dmg while being poisoned": with Poison added to a full-HP player, HP falls 2-3 after each player action for the full duration, with a log line, sound and flash | battle, status-effects | L3: bot, Normal difficulty, 4 actions. A failed Run behaves as the rules say | ACTIVE (rules re-tested after Phase 5) | 2026-10-13 | never |
| R-006 | "incease the hit rate of skills ... i missed 4 to 5 consecutive horizontal slashes": until Phase 4 every skill hit chance is inside the documented 61.8-88.8% range (`combat-bugs.md` section 7). After Phase 4 (D6): zero skill misses over many seeded casts | battle | L2: `Test_Suite_Combat` | ACTIVE, replaced by "zero misses" in Phase 5 | 2026-10-13 | never |
| R-007 | "mini boss moves around so he isnt blocking tje way": in `rm_floor5` the mini boss stays at (224,32) for 60 s, the fight starts within 4 tiles, and after the win he stays removed for the rest of the run (a new run brings him back) | battle, world | L3: bot | ACTIVE | 2026-10-13 | never |
| R-008 | Save and load round trip keeps HP, MP, level, inventory, flags, room, statuses, and after Phase 4 also cards, gold, seed and stream counters (run part) and story flags, unlocks and settings (profile part); settings from older versions migrate | save/load | L2: `Test_Suite_Save`, scratch save folder only | ACTIVE | 2026-10-13 | never |
| R-009 | Localization builds and lints clean: `build_localization.py` runs, `lint_hardcoded_text.py` reports no new hard-coded English | localization | L2: Python commands from `README.md` | ACTIVE | 2026-10-13 | never |
| R-010 | "QTE never felt right": QTE windows in the code equal the documented values (ms table); same press time gives the same grade at any frame rate | QTE | L2: `Test_Suite_Qte` (starts as a check of the current windows, replaced in Phase 6) | PENDING (replaced in Phase 5) | 2026-10-13 | never |
| R-011 | "Buff/debuff icons reuse other skill icons as placeholders": every status icon is a non-placeholder sprite, or is on the known-placeholder list (10 today) | UI, status-effects | L2: `Test_Suite_Data`; L4 battle screenshot with all statuses | ACTIVE (list shrinks to 0 in Phase 7) | 2026-10-13 | never |
| R-012 | "foresight skills idk what it does": the Foresight tooltip states its effect, duration and end rule, and matches the behaviour | skills, UI | L2: tooltip text built from data; L5 owner | PENDING (Phase 5) | 2026-10-13 | never |
| R-013 | "ice spear animation is slow": total time from Ice Spear start to the next state is at or below the owner's target | battle, game-feel | L3: bot frame count; L5 owner | PENDING (target set in Phase 1) | 2026-10-13 | never |
| R-014 | "hilt bash animation slow": same check for Hilt Bash | battle, game-feel | L3 + L5 | PENDING (Phase 1) | 2026-10-13 | never |
| R-015 | Skill tooltips show the number of turns the game really applies | skills, UI | L2 | ACTIVE (found by audit C, fixed in Phase 5) | 2026-10-13 | never |
| R-016 | Curse applies what its log says, at its stated chance | battle, status-effects | L2 | ACTIVE (audit B, fixed in Phase 5) | 2026-10-13 | never |
| R-017 | Dialogue end in `rm_floor1`, `rm_floor5`, `rm_floor9_5`: player in the same screen place before and after, no camera jump at fade-in | dialogue/cutscene, UI-scale | L3 + L4 | ACTIVE (fix in Phase 2) | 2026-10-13 | never |
| R-018 | No red or coloured window border; bars are pure black in fullscreen and during fades | UI-scale | L4: pixel checker on `-shots` | ACTIVE | 2026-10-13 | never |
| R-019 | Old-format save is rejected with a friendly message and no crash; the old file is not overwritten | save/load | L2 + L3 | PENDING (Phase 4, D16; now covers profile and run parts) | 2026-10-13 | never |
| R-020 | Automated runs never touch the real save area: files in `%LOCALAPPDATA%\DD_Project` are unchanged | save/load, harness | L2: wrapper compares timestamps and hashes before and after | PENDING (Phase 1) | 2026-10-13 | never |
| R-021 | The gate's negative control stays red; a syntax error turns compile red; an unknown function turns smoke red | harness | L1 + L2 + L3: run whenever the wrapper changes | PENDING (Phase 1) | 2026-10-13 | never |
| R-022 | Statuses tick at the defined moment on every action that consumes a turn, including a failed Run | battle, status-effects | L3 | ACTIVE (audit E; rules change in Phase 5C) | 2026-10-13 | never |
| R-023 | A basic attack never deals 0 damage at any grade (D20) | battle, QTE | L2 | PENDING (Phase 5) | 2026-10-13 | never |
| R-024 | Self-buff animations play on the player, not on the enemy | battle, UI | L4: screenshot | ACTIVE (audit F, fixed in Phase 1) | 2026-10-13 | never |
| R-025 | The HP bar does not drop before a defence QTE resolves | battle, QTE | L3 | ACTIVE (audit, inferred; fixed in Phase 5B) | 2026-10-13 | never |
| R-026 | No new hard-coded English: "Game saved.", the level-up text and the `Equip_CanEquip` messages go through localization | localization | L2: lint | ACTIVE (fixed in Phase 1) | 2026-10-13 | never |
| R-027 | Scenario reaches battle through key events (the real input path), not by calling functions directly | harness, battle | L3: review of the bot code plus a run | PENDING (Phase 1) | 2026-10-13 | never |
| R-028 | Loading a save from the title right after the intro cutscene leaves no leftover cutscene background | dialogue/cutscene, save/load | L3 + L4 | ACTIVE | 2026-10-13 | never |
| R-029 | Fixed-seed bot matrix (3 classes x several enemies x 3 difficulties) finishes every battle with no runtime error and HP inside [0, max] | battle, harness | L3 | PENDING (Phase 1) | 2026-10-13 | never |
| R-030 | A stun hit grants no extra actions; boss stun follows the resistance rule | battle, turn order | L2 | PENDING (Phase 5C) | 2026-10-13 | never |
| R-031 | There is exactly one difficulty: no Easy/Normal/Hard switch in settings, saves or code; the dead `player_stat_mult` / `enemy_stat_mult` are gone; the QTE assist (wider windows) is the only accessibility option | balance, difficulty | L2: source guard + settings test | REPLACED 2026-10-14 (was: Easy, Normal, Hard win rates inside bands; D35). PENDING (Phase 5A) | 2026-10-13 | never |
| R-032 | Foresight icon is an eye, and all 10 new status icons are 16x16 with only the four palette colours | UI, art | L2: art checker; L4 | PENDING (Phase 7) | 2026-10-13 | never |
| R-033 | Display layout is not re-applied on transition end, cutscene end or save load | UI-scale | L3: apply counter | PENDING (Phase 2) | 2026-10-13 | never |
| R-034 | The build id is visible on the title screen and printed in the test summary | harness | L2 + L4 | PENDING (Phase 1) | 2026-10-13 | never |
| R-035 | Release build has debug keys off; the release zip holds exactly the exe, data.win, licences and credits (D52) | release | L2 | PENDING (Phase 8; REL-02, REL-06) | 2026-10-13 | never |
| R-036 | Death returns to the entrance room with run state cleared (cards, gold, items, level 1, statuses, enemies) and the profile kept; it does not reload a save slot. Dying in a battle, a status tick, the shop, a dialogue or a transition all end the same way | run, save/load | L3: bot kills the player in each state, then compares state with a fresh run | PENDING (Phase 6; D26, D31) | 2026-10-14 | never |
| R-037 | Story moment never repeats after death: cutscenes, camera pans to an enemy and story dialogue play once per save file, survive save/load and a new run, and skipping leaves the world identical (flags, items, doors, camera) | run, dialogue/cutscene, save/load | L3 + L4: bot plays run 1, dies, plays run 2; no cutscene or pan starts; before/after state equal | PENDING (Phase 6; D26) | 2026-10-14 | never |
| R-038 | Run seed reproduces the same shuffles: same seed gives the same card offers, shop stock, enemy pools, elite rolls and chest loot; saving and reloading at an offer shows the same cards; golden sequence (seed 12345, first 100 per stream) matches on Windows | run, save/load, RNG | L2 | PENDING (Phase 4 generator, Phase 6 shuffles) | 2026-10-14 | never |
| R-039 | Cosmetic randomness (shake, particles) never changes the run: two runs with the same seed give the same offers even if effects differ | run, RNG | L2: run with effects on and off | PENDING (Phase 4) | 2026-10-14 | never |
| R-040 | Run/profile split: a corrupt or missing run file never damages the profile; death clears only the run part; unlocks, story flags and the death gift survive; old-format saves are rejected with the friendly message | save/load, run | L2 + L3 | PENDING (Phase 4; D36, D16) | 2026-10-14 | never |
| R-041 | Death gift: each death leaves exactly one gift, the next run starts with it, the following death replaces it; no unlock changes a base stat | run, progression | L2 | PENDING (Phase 6; D32) | 2026-10-14 | never |
| R-042 | A new run starts clean: running 20 runs in a row shows no growth in live ds structures and no state leaking from the last run (inventory, flags, timers, enemy states) | run, memory | L3: bot loop with a ds count | PENDING (Phase 4 and 6; ROB-03, RUN-03) | 2026-10-14 | never |
| R-043 | Card offers: three distinct entries, no owned skill again, upgrades only for owned skills, never fewer than 3 usable entries, pool counts for all four classes (Knight, Archer, Mage, Nobody) | progression | L2 | PENDING (Phase 6; D18, D34) | 2026-10-14 | never |
| R-044 | Gold belongs to the run: saved with the run, spent in the shop (too little fails), lost on death | progression, save/load | L3 | PENDING (Phase 6; D23, D26) | 2026-10-14 | never |
| R-045 | First win shows the ending and credits once; later wins show the run-end screen and do not repeat the story | run, dialogue/cutscene | L3 + L4 | PENDING (Phase 6; D31) | 2026-10-14 | never |
| R-046 | The bot drives every QTE type (ring/bar and arrows) from the QTE's own data and the grades match what was pressed | harness, QTE | L3 | PENDING (Phase 5B) | 2026-10-14 | never |
| R-047 | The simulator and the GML formulas both pass the same JSON test vectors | balance, harness | L2 | PENDING (Phase 5A) | 2026-10-14 | never |
| R-048 | A frame-throttled bot run (simulated frame hitches) gives the same fight and fade outcomes as a normal run | harness | L3 | PENDING (Phase 8; ROB-01) | 2026-10-14 | never |

## Manual walk (L5), run on each playtest build

Keep this short. Add a line when an automated entry cannot be built.

1. Cutscene end and dialogue end in floors 1, 5 and 9.5: no flash, no jump. (R-001, R-017)
2. Fullscreen on, off, on: correct layout each time. (R-002, R-018)
3. One fight with each QTE type: it feels fair. (R-010)
4. Poison tick is noticeable. (R-005)
5. Play two runs in a row: die in run 1, see the death line and gift in the entrance room, start run 2. No cutscene, pan or story dialogue repeats; the card offers differ from run 1 unless the seed is the same. (R-036, R-037, R-038, R-041)
6. A winning run ends with the ending and credits once. (R-045)

---
*Created: 2026-10-13. Updated 2026-10-14 (roguelike entries R-036 to R-048; phase numbers follow the 8-phase roadmap). Last run of any entry: never.*
