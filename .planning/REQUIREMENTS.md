# Requirements: DD-Project (GameMaker)

**Milestone:** v2.0 "Done right" (now a replayable, roguelike-style game)
**Defined:** 2026-10-13. **Revised:** 2026-10-14 for the roguelike direction (D25-D36) and the plan review (`research/plan-review.md`).
**Core Value:** A short 8-bit dungeon RPG you can replay: every run is a fair, satisfying 45-60 minute climb.

Decisions D1-D36 are in `.planning/research/DECISIONS.md` and are locked. D28 is the scope limit: **nothing is added beyond what is decided, and there is no post-release.** Where a number is not given, the owner sets it in a short grill-me right before that item is built (`ROADMAP.md`). No agent invents a player-facing number.

The owner reads `BOARD.md`. This file is the agents' checklist.

## How to read a requirement

Each line is: **ID**: what must be true. *Check: level.* A requirement is done only when its check passed on a named build id (see `REGRESSION.md`).

Check levels (from `research/lessons-from-past-projects.md` section 4.1):

| Level | Check | Catches |
|---|---|---|
| L1 | Igor compile (exit 0, no `Error :` lines) | syntax errors, missing references. Not unknown functions. |
| L2 | Headless test suite (`Test_Suite_*` via `-runtests`, plus Python checks) | wrong formulas, duplicate ids, missing loc keys, save round trip |
| L3 | Scripted scenario run through the real input path (bot) | broken flow, ticks that do not tick, room changes, save/load |
| L4 | Screenshots at the size matrix, opened and read by the reviewer | scaling, overlaps, placeholder icons, the screen after a cutscene |
| L5 | Owner or friend plays a checklist (15 minutes at most, written first) | feel: timing, speed, balance, "does it make sense" |

Rules: L5 alone is never enough for anything L1-L4 can see. A requirement may list two levels (for example "L3 + L5"); both must pass. `[VERIFY FIRST]` means research says the bug may already be fixed: write the repro, run it on the current build, and only then decide whether to fix. `[GRILL: Gn]` means the owner decides the open details in grill-me topic Gn just before building (list in `ROADMAP.md`).

**Gate speed (plan review 1b item 4).** There are two gates. The *fast gate* (compile + `-runtests` + `-smoke`) runs for every packet and targets about 40 s. The *full gate* (fast gate + `-bot` + `-shots`) runs on every playtest build and may take a few minutes. "Green" in a review names which gate ran.

## v2.0 Requirements

### VER - Verification harness (Phase 1)

- [ ] **VER-01**: `tools/automation/run_tests.ps1` builds the project with Igor from a scratch copy (VM Release, `--cache` and `--temp` on E:) and fails on a non-zero exit or any `Error :` line. *Check: L1.*
- [ ] **VER-02**: Starting the built game with `-runtests` runs every `Test_Suite_*`, prints `[TEST] PASS/FAIL` lines and a `[TEST-SUMMARY] pass= fail= errors=` line, writes `test_results.txt`, and exits with 0 only if nothing failed. *Check: L2.*
- [ ] **VER-03**: A missing result file, a missing summary line, a hang past the timeout, or a leftover game process counts as FAIL, never as a pass. *Check: L2.*
- [ ] **VER-04**: A negative control (a test that is meant to fail) makes the wrapper report red. It is run every time the wrapper script changes. *Check: L2.*
- [ ] **VER-05**: An unhandled GML error is caught by `exception_unhandled_handler`, logged as `UNHANDLED`/`CRASH`, and makes the wrapper fail. Crash detection reads the log, not the exit code, because `game_end(n)` inside the handler returns exit code 0 (`automation-igor.md` section 2.9). *Check: L2.*
- [ ] **VER-06**: Every automated run sets `LOCALAPPDATA` to a scratch folder. After a run, the files in `%LOCALAPPDATA%\DD_Project` are unchanged. *Check: L2.*
- [ ] **VER-07**: `-smoke` boots the real game and walks `rm_start`, a floor room and `rm_battle`, and fails on any runtime error. Needed because Igor does not catch unknown functions or variables. *Check: L3.*
- [ ] **VER-08**: `-bot` plays scripted battles through key presses (the same input path the player uses), with auto-perfect and auto-fail variants, and asserts state (HP, flags, room, inventory), never just "no crash". The bot must keep working when the QTE is rebuilt: it drives every QTE type (ring/bar and arrows) from the QTE's own data, not from `Battle_AttackTimingTarget` (plan review 1b item 9). From Phase 6 it can also play a short seeded run: start, fight, die, return to the entrance. *Check: L3.*
- [ ] **VER-09**: `-shots` saves screenshots (`screen_save`) of title, a floor, battle, and a menu at the window sizes the game supports, and automatic checks pass (file exists, size equals window size, not blank). Until Phase 2 the supported sizes are the three scales 3-5 (480x432, 640x576, 800x720); Phase 2 extends it to the full matrix. *Check: L4.*
- [ ] **VER-10**: A pre-build step stamps a build id (git short hash + date). The id is shown on the title screen or debug overlay, printed in `[TEST-SUMMARY]`, and used in every playtest note. From Phase 6 the run seed is shown next to it (debug overlay and run-end screen) so a bug note can name the exact run. *Check: L2 + L4.*
- [ ] **VER-11**: Data-integrity suite over the JSON data (BAL-01): no duplicate item, skill or card ids; every enemy references existing skills and loot; every loot, shop and encounter table id resolves; every upgrade card's base skill exists; every localization key used exists; the list of placeholder status icons matches the known list. *Check: L2.*
- [ ] **VER-12**: Tests can seed the random number generator, and gameplay code never calls `randomize()` again (the only call is `scr_player.gml:1530`; `codebase/CONCERNS.md`, Randomness). The run's own seeded streams are RUN-11. *Check: L2.*
- [ ] **VER-13**: Each automated `REGRESSION.md` entry maps to a named test; the wrapper prints which R-ids ran and which did not. An entry with no run on the current build counts as unchecked, not green. *Check: L2.*
- [ ] **VER-14**: One command runs the fast gate and prints only FAIL/ERROR lines in about 40 seconds. A second command runs the full gate (adds bot and shots; the timeouts alone are 30 + 60 + 120 s, `automation-igor.md` section 3.6) and is run on every playtest build. Reviews say which gate ran. *Check: L2.*
- [ ] **VER-15**: The wrapper refuses to start if `--cache`, `--temp` or the output folder is on C:. *Check: L2.*
- [ ] **VER-16**: The `next` branch exists and the wrapper passes on it; `AGENTS.md` gate text matches `.planning/research/AGENTS-CHANGES.md`. *Check: L1 + review.*

### DISP - Display and resolution (Phase 2)

- [ ] **DISP-01**: The six unverified points in `research/resolution-gamemaker.md` section 8 are each answered with evidence (a screenshot or a logged number) in a spike note before any rebuild. A seventh point is added: can Igor build HTML5. *Check: L4.*
- [ ] **DISP-02**: One persistent display manager (`obj_display` + `scr_display`) is the only code that calls window, view, camera, surface or GUI-size functions. `obj_sfx_manager` no longer owns display. *Check: L2 (source guard) + L4.*
- [ ] **DISP-03**: `Display_CalcLayout` is a pure function; for the window sizes in `resolution-gamemaker.md` section 7.1 it returns the expected scale and offsets (largest whole-number scale that fits, centred). *Check: L2.*
- [ ] **DISP-04**: At every size in the matrix the picture is exactly `160*s x 144*s`, centred; everything outside is pure black; downsampling the picture reproduces the 1x reference (no blur). The window colour is black, not red (`options_main.yy` is 255 today). *Check: L4.*
- [ ] **DISP-05**: Fullscreen on gives the largest whole-number scale that fits; fullscreen off returns to the chosen windowed scale; five fast toggles leave no stuck size or coloured bars. *Check: L3 + L4.*
- [ ] **DISP-06**: Cutscene end: the last image fades to black (it does not vanish first), the window does not re-centre, no zoom or shift, and the first floor frame is stable. Story moments play once per save (RUN-07), so this must be right the first time a player sees it. *Check: L3 + L4, then L5.*
- [ ] **DISP-07**: Dialogue end in `rm_floor1`, `rm_floor5` and `rm_floor9_5`: the camera pans back, the player is in the same screen place as before the dialogue, no jump at fade-in. *Check: L3 + L4.*
- [ ] **DISP-08**: The display is re-applied only on boot, on Settings Apply, on a real window or display size change, and on focus regain. Never on transition end, cutscene end, save load or run start. A counter in the scenario run proves it. *Check: L3.*
- [ ] **DISP-09**: UI and text are authored on a 640x576 grid (D8) through `Display_GuiW()` / `Display_GuiH()`. All 18 `display_get_gui_width/height` call pairs (36 calls in 11 files; the audit's own list in `audit/resolution.md` section 1d, whose "17" is an undercount) are replaced; a source guard fails if any remains. *Check: L2 (source guard) + L4.*
- [ ] **DISP-10**: `rm_floor6_5` (144 wide) and the floor view borders are fixed in the IDE by the owner, and no area outside the room is visible. *Check: L4.*
- [ ] **DISP-11**: HTML5 build: the canvas fits the browser window at several browser sizes with the correct aspect and a sharp picture (no blur), and the game stays correct after a browser resize and after fullscreen. *Check: L4 (browser screenshots).*
- [ ] **DISP-12**: Layout uses anchors and `Display_GuiW/H` only, so odd aspect ratios (tall 600x1000, ultrawide 3440x1440) show a correct picture with black bars. No Android work is done (D28). Cut first if time runs short. *Check: L4.*
- [ ] **DISP-13**: Screen shake moves the camera from a Step event with whole-pixel offsets, not from Draw GUI. *Check: L3.*
- [ ] **DISP-14**: Settings migrate `fit_screen` to a clear `fullscreen` flag. The current `settings_version` is 7 (`scr_save.gml:66`; the "6" in `audit/resolution.md` is stale), so this bumps it to 8. Settings live in the profile save (SAVE-01). *Check: L2.*
- [ ] **DISP-15**: Loading a save from the title right after the intro cutscene leaves no leftover cutscene background (`audit/resolution.md` H6). *Check: L3.*

### BUG - Playtest notes and found bugs (Phase 1 repros; rebuilds close the rest)

Each friend and owner note is one line in `ISSUES.md` (verbatim text in `research/playtest-notes.md`). Findings come from `research/audit/combat-bugs.md` (letters A-K), `ui.md`, `qte.md`, `resolution.md`, `balance-data.md` and `codebase/CONCERNS.md`.

**Pointer rows moved out (plan review 1c).** 17 BUG rows only said "closed by category X". They are not requirements. They now live in `ISSUES.md` (every one already has a row) and in the closed-by map under Traceability. 12 real BUG requirements stay.

Rule: if the bug lives in a system that later phases rebuild (damage over time, stun, QTE, skill books), Phase 1 writes the repro and the regression entry and adds only fixes that survive the rebuild. The rebuild phase then has to make that entry pass. Phase 1 does not wait for the friend's answer about the build (I-039): if no answer comes, the repros run on the current build and that is the answer.

- [ ] **BUG-03**: "bone shud be foresight +". One question to the friend: was "bone" an icon, the floor-8 bones prop, or a skill name? D24 reads it as the icon. Closed by ART-03 (Foresight icon is an eye). *Check: L4.* [QUESTION open]
- [ ] **BUG-04**: "skill books appear in books twice". [VERIFY FIRST] Audit could not reproduce it at HEAD (`combat-bugs.md` section 4). Check: adding book 114 twice leaves one entry; a pushed duplicate shows once; the Skills tab shows no duplicate; no duplicate ids in `skills`. The final fix is D18 (books removed, PROG-04). *Check: L2.*
- [ ] **BUG-05**: "ice spear animation is slow". Verified: Ice Spear is at the speed cap (1.3) and takes 1.15 s plus a fixed 1 s hold (`combat-bugs.md` section 5). Total skill action time is reduced to the owner's target. This matters more now: players see every skill many times per run. Target number: owner, Phase 1. *Check: L3 (frame count) + L5.*
- [ ] **BUG-06**: "hilt bash animation slow". Same as BUG-05 (0.86 s plus 1 s hold; last two frames empty). *Check: L3 + L5.*
- [ ] **BUG-07**: "mini boss moves around so he isnt blocking tje way". [VERIFY FIRST] At HEAD he is stationary (`ai_stationary = true`, `combat-bugs.md` section 6). Check: open `rm_floor5`, wait 60 s, his x,y stay (224,32); approach within 4 tiles and the fight starts; after the win he stays removed (within a run). *Check: L3.*
- [ ] **BUG-08**: "i dont take dmg while being poisoned". [VERIFY FIRST] The tick exists (2-3 HP after each player action, `combat-bugs.md` section 1) but is nearly silent. Phase 1: repro passes, and a tick shows a log line, a sound and a flash. Phase 5 re-tests it under the new damage-over-time rules (STAT-07). *Check: L3 + L5.*
- [ ] **BUG-16**: Tooltips show base status turns, not the turns the game applies (Foresight "3 turns" is really 9; Wound "2" is 5; Guard "2" is 6; `combat-bugs.md` finding C). After STAT-07 (fixed durations) tooltip text is built from the same number the game uses. *Check: L2.*
- [ ] **BUG-17**: Curse (final boss) ignores its 50% chance and the hit roll, its three damage-over-time effects cancel each other, and the log says it applied all three (finding B). *Check: L2.*
- [ ] **BUG-20**: A failed Run does not tick statuses (finding E). Re-tested under TURN-06. *Check: L3.*
- [ ] **BUG-21**: Self-buff animations play on the enemy, not the player (finding F). *Check: L4.*
- [ ] **BUG-24**: `SKILL_POWER_STRIKE` has a macro and a loc key but no `SkillDB` record (finding H). *Check: L2.*
- [ ] **BUG-27**: `ch.hp = 9999; // temp` at `scr_player.gml:20` (and `ch.mp = 9999` on line 21; `CONCERNS.md`). [VERIFY FIRST] Find out whether it is live. *Check: L2.*

### STAT - Stats, formulas, damage over time (Phase 5, wave 5A)

- [ ] **STAT-01**: Stats are ATK, DEF, SPD, MAG plus HP and MP (D22). Changing each stat by an amount the owner sets in the formula grill changes a measurable outcome: ATK changes physical damage, DEF changes damage taken, SPD changes how often a side acts (TURN-02), MAG changes magic damage and MP. No dead stats (compare `balance-data.md` S8: LUCK, DEF, AGI, INT were near-dead). *Check: L2.* [GRILL: G5]
- [ ] **STAT-02**: All damage and stat formulas are pure functions with tests whose expected values come from the owner's written formula spec, not copied from the code's output. The spec also yields a JSON file of test vectors that both the GML tests and the Python simulator (BAL-02) must pass, so the two cannot drift apart. *Check: L2.*
- [ ] **STAT-03**: Weapons add to skill damage as well as basic attacks (D22). Today skills ignore weapons (`balance-data.md` S5). *Check: L2.* [GRILL: G5]
- [ ] **STAT-04**: Skills always hit (D6). A test casts every skill many times with fixed seeds against every enemy and sees zero misses. Closes the friend's "increase the hit rate" note (I-009). *Check: L2.*
- [ ] **STAT-05**: A basic attack never deals 0 damage at any grade (D20). The grade table is owned by QTE-03 (decided once, in grill G4); this test reads whatever table QTE-03 sets, so the two cannot disagree. *Check: L2.*
- [ ] **STAT-06**: Whether enemy attacks on the player can miss or be dodged, and what Evasion, Solidify and Bloodthirsty become, is written in the formula spec and tested. Solidify, which today makes player skills auto-miss, must not break D6. Decided before the status icons are drawn (ART-03). *Check: L2.* [GRILL: G5]
- [ ] **STAT-07**: Damage over time (D21): fixed durations shown with a turn counter; the total damage is bounded; a defence QTE can shorten a status and never lengthen it; the tooltip number equals the applied number. A guarded (0-damage) hit applies no status unless the spec says so (audit finding J). *Check: L2.*
- [ ] **STAT-08**: Damage over time is strong against tanky enemies and weak in quick fights. The target band (share of total damage by fight length) is set by the owner; the simulator checks it. *Check: L2 (simulator, available from Phase 5A).*
- [ ] **STAT-09**: **REPLACED (D35).** One difficulty only. Easy/Normal/Hard are removed from settings, saves and code; the dead multipliers `player_stat_mult` / `enemy_stat_mult` and the floored small-integer difficulty maths are deleted. Wider QTE windows are the only accessibility option (QTE-13). A source guard finds no difficulty switch left. *Check: L2.* (Old text: win-rate gaps for three difficulties.)
- [ ] **STAT-10**: Foresight has a clear effect that is not "next skill cannot miss" (void under D6), and its tooltip states the effect, the duration and when it ends (D24). The effect is decided in G5. *Check: L2 + L5.* [GRILL: G5]
- [ ] **STAT-11**: Crit has a new source now that LUCK is removed, and basic attacks and skills use the same crit rule (audit finding K). *Check: L2.* [GRILL: G5]
- [ ] **STAT-12**: **CHANGED (D27).** Level resets to 1 every run. Level-up gains (HP, MP, stats per class, four classes) follow the owner-approved table, and the table is built for a run of 45-60 minutes (D30), not for a one-pass-to-level-10 curve. *Check: L2.*
- [ ] **STAT-13**: **RETIRED.** "The game exports its own balance data" is replaced by BAL-01 (the data already lives in JSON that the simulator reads, so there is no export step).
- [ ] **STAT-14**: Auto-resolved fights (weak enemies resolved at 0.35x EXP, `scr_enemy.gml:36-42`): the owner decides in G5 whether they still exist in the run. Whatever is decided is in the data, tested, and modelled by the simulator, so its XP numbers are right. *Check: L2.* [GRILL: G5]

### TURN - Turn order (Phase 5, wave 5C)

- [ ] **TURN-01**: A turn-order bar is visible in battle and shows who acts next and after (D19, must-have D29). Prototype P3 first shows whether the bar reads well in 1 vs 1; the default is to build it. *Check: L4.*
- [ ] **TURN-02**: SPD decides how often each side acts: over a long simulated fight, the action counts match the SPD ratio within a stated tolerance. *Check: L2.*
- [ ] **TURN-03**: Stun delays the target on the bar by an owner-set amount. No stun grants extra actions. The old `grant_extra_turns` is gone (closes audit finding A, BUG-18). *Check: L2.*
- [ ] **TURN-04**: Bosses and mini-bosses resist stun by an owner-set rule, so a stun-first combo cannot win the game (today the model says the Mage combo beats the final boss 93% of the time, `balance-data.md` S1). *Check: L2 (simulator).*
- [ ] **TURN-05**: Enemy extra actions (Rampage, Fury, Blessing are "FREE action" today) are redefined on the bar. *Check: L2.*
- [ ] **TURN-06**: Status turn counters and damage-over-time ticks advance at one defined moment of the affected unit's turn, and the counters on screen match the rules. A failed Run also advances them as the rules say. *Check: L3.*
- [ ] **TURN-07**: Turn order does not depend on frame rate. *Check: L2.*

### QTE - Timing and input (Phase 5, wave 5B)

QTE-01 to QTE-07 do not depend on the turn bar and can be built before it. Only the defence telegraph (QTE-08/09) needs the enemy turn flow.

- [ ] **QTE-01**: QTE time is kept in milliseconds with a clock that caps long frames; a press is timestamped at the top of the Step that sees it; all windows are written in ms. A pure `Qte_Judge(press_ms, target_ms, table, mult, offset)` returns the grade. *Check: L2.*
- [ ] **QTE-02**: One input function (`Input_QtePressed`) serves keyboard and gamepad. Touch is not built or tested. *Check: L3 (keyboard through the real input path) + L5 (gamepad).*
- [ ] **QTE-03**: Results are graded (D5, D20). **This requirement owns the grade table** (names, windows in ms, damage or effect scale), decided once in G4 after prototype P2. Failing scales power down and never fully misses. *Check: L2.* [GRILL: G4]
- [ ] **QTE-04**: A ring or bar timing type works (D4, must-have D29). The bot hits Perfect, Good and Late on purpose and the grade matches. *Check: L3.*
- [ ] **QTE-05**: An arrow-sequence type works with arrows and WASD (D4). Wrong, late or missing inputs reduce the grade; they do not zero the skill. A wrong key does not end the sequence at once, and there are no dead frames between arrows (ROB-02). The bot drives this type too. *Check: L3.*
- [ ] **QTE-06**: Each skill declares its QTE type and parameters in the JSON data (BAL-01). A data test fails if a skill has none. *Check: L2.*
- [ ] **QTE-07**: The basic attack is a free, always-landing graded QTE (D20). *Check: L3.*
- [ ] **QTE-08**: Only moves flagged big or telegraphed (bosses, mini-bosses, heavy moves) open a defence QTE (D7). Normal hits never do. *Check: L2 + L3.*
- [ ] **QTE-09**: A telegraph is visible before the strike for a wind-up the owner sets (starting idea in `qte-design.md` section 5: 600-900 ms, to be calibrated by prototype P2). Same move, same timing, every time; the old random per-swing speed is gone. *Check: L2 + L5.*
- [ ] **QTE-10**: A defence QTE only reduces damage and shortens statuses (D21). *Check: L2.*
- [ ] **QTE-11**: The HP bar does not drop before the defence QTE resolves (closes audit `qte.md` 2.6, old BUG-25). *Check: L3.*
- [ ] **QTE-12**: Feedback: each grade has its own colour, word, sound, hit-stop and shake (game-feel). The result word shows in 100 ms or less after the press (starting value, `qte-design.md` section 5). "Feels good" itself is an L5 judgement by the owner; agents cannot close it. *Check: L3 + L5.*
- [ ] **QTE-13**: **NARROWED (D35, D28).** One accessibility option is stored in settings: wider QTE windows (a multiplier the owner picks). Auto-success, QTE-off and the input-offset/calibration options are not built. *Check: L2 + L5.*
- [ ] **QTE-14**: A slow frame does not change the grade for the same press time (judged by the clock, not by Step count). *Check: L2.*
- [ ] **QTE-15**: Ordinary fights ask for at most one timed input per player action and none on normal enemy hits. Long arrow sequences are limited to skills the owner names (fatigue guard, `qte-design.md` principle 6). Runs repeat fights many times, so this matters more now. *Check: L2.*

### RUN - The run loop (decisions in Phase 3, built in Phase 6; new, D25-D36)

Source: `research/roguelike-design.md` option A and `research/roguelike-cases.md`. The floors, rooms and story stay as they are; variety comes from data and seeded shuffles (D25, D33).

- [ ] **RUN-01**: A run starts at floor 1 with a level 1 character (D27) and fresh run state, and ends by death or by beating the final boss. Between runs the player is in the dungeon entrance room (D31). *Check: L3.*
- [ ] **RUN-02**: **Death ends the run (D26).** The player returns to the dungeon entrance room, reusing an existing room (which one: G2). Run cards, gold, items and levels are lost; the profile is kept. This replaces today's behaviour of reloading the latest save slot (`obj_start_controller/Step_0.gml`, case `game_over`). *Check: L3.*
- [ ] **RUN-03**: A new run starts clean: every run global (inventory, statuses, enemy states, room flags, gold, cards, timers) is reset, and no object, list or map from the last run survives. Two runs with the same seed give the same floor-1 state. *Check: L2 + L3.*
- [ ] **RUN-04**: A short death line or framing is shown on death, so dying is part of the lore (D26). It goes through localization (English and Korean), comes from a small fixed set in data, and the selection rule is simple (G2). Minimal writing (D28). *Check: L2 + L4.* [GRILL: G2]
- [ ] **RUN-05**: Each death leaves one small "death gift" for the next run (D32). It is stored in the profile, applied at the next run start, and replaced by the next death. What the gift is: G2. *Check: L2 + L3.* [GRILL: G2]
- [ ] **RUN-06**: Unlocks only, no permanent stat power (D32). A data list of unlocks with their triggers; an unlock persists in the profile; a test proves that no unlock changes a base stat. The list stays short (D28). *Check: L2.* [GRILL: G2]
- [ ] **RUN-07**: Story-seen flags: cutscenes, camera pans to an enemy and story dialogue play once per save file and are remembered across runs, never repeated after death (D26). Flags live in the profile and survive save, load and a new run. *Check: L2 + L3.*
- [ ] **RUN-08**: Skipping a story moment that was already seen leaves the world exactly as playing it would (flags set, items given, doors changed, camera and player in place). No screen jump (DISP-06/07). *Check: L3 + L4.*
- [ ] **RUN-09**: Beating the final boss shows the ending and credits the first time (D31). Later wins go to the run-end screen and do not repeat the story (inferred from D26 + D31; confirm in G2). There are no credits in the code today, so they are drawn text in an existing room (no new room). *Check: L3 + L4.* [GRILL: G2]
- [ ] **RUN-10**: Run length (D30): a bot run through a full game measures walking, cutscene and fight time, and the owner-played winning run lands in 45-60 minutes with all ~10 floors in one sitting. If it is longer, cut walking before content. *Check: L3 (measure) + L5.*
- [ ] **RUN-11**: Seeded randomness (D33). One run seed. Separate counter-based streams per purpose (card offers, shop stock, enemy placement, elite variants, chest/loot, combat/QTE); cosmetic effects use plain `random()` and never touch them. The run save stores the seed and one counter per stream, not generator state. The generator uses no 64-bit or sign-dependent bit operations (HTML5 hazard, `roguelike-cases.md` section 4.2). A golden-sequence test (seed 12345, first 100 outputs per stream) passes on Windows and on the web export. Saving and reloading at an offer shows the same cards. *Check: L2 + L3 (+ browser run in Phase 8).*
- [ ] **RUN-12**: Per-run shuffles (D33), all from data tables and the streams above: card offers and shop stock; which enemies appear at which spawn point (per-floor pools); chest contents and loot (per-floor tables). Rooms are not changed. Spawning a different kind at an existing spawn point may need an owner IDE step (decided by prototype P1). *Check: L2.*
- [ ] **RUN-13**: Elite variants (D33): an enemy can spawn as an elite through data modifiers (for example armored, swift) with a better reward. No new sprites or objects. Chance and modifier list are in data. *Check: L2.*
- [ ] **RUN-14**: A run can be saved and resumed. Where saving is possible (beds only as today, or a pause-menu "save and quit" at any safe moment) is decided in G2; whichever is chosen, resume continues with the same seed and counters. *Check: L3.* [GRILL: G2]
- [ ] **RUN-15**: Enemy respawn inside a run is a decision, not an accident: today `Save_Write` calls `Enemy_ResetAll` (`scr_save.gml:394`), which respawns every regular enemy on each save and allows farming. G2 decides; a test proves the chosen rule. *Check: L2.* [GRILL: G2]
- [ ] **RUN-16**: Death never softlocks. Dying in a battle, during a status tick, in the shop, in a dialogue or during a transition always ends in the entrance room with run state cleared and profile kept. The bot kills the player in each of those states. *Check: L3.*

### PROG - Progression inside a run (Phase 6)

- [ ] **PROG-01**: At each chest or level-up, the player sees 3 different cards and picks 1 (D18, must-have D29). The offer is a pure function of the run state and the offer stream (RUN-11): no duplicates in one offer, never offers an owned skill again, offers an upgrade only for an owned skill, and never fewer than 3 usable entries. Extra rules (skip, equipped-skill cap, exclusive upgrade branches, bad-luck guard) are decided in G7. *Check: L2 + L3.* [GRILL: G7]
- [ ] **PROG-02**: Four classes (Knight, Archer, Mage, Nobody; D34). Each has about 5 skills and 5-8 upgrades in its pool (D18). A data test counts them. *Check: L2.*
- [ ] **PROG-03**: An upgrade changes the owned skill (for example "Ice Spear+") and the skill's description shows it. *Check: L2.*
- [ ] **PROG-04**: Random skill books are gone from loot, chests and graves; old book items are removed from the item data. *Check: L2.*
- [ ] **PROG-05**: Enemies and chests drop gold (D23, must-have D29). Gold belongs to the run: it is saved with the run and lost on death (D26). *Check: L2 + L3.*
- [ ] **PROG-06**: A merchant at safe spots between floors sells potions and gear (D23). Stock comes from the shop stream (RUN-11). Buying fails with too little gold, succeeds with enough, and updates inventory and gold. The safe spots need IDE work by the owner. *Check: L3.*
- [ ] **PROG-07**: Loot quality improves per floor (D23) through per-floor loot tables in data. Today tier weights use the enemy level clamped to 3, so floor 3 and floor 9 drop the same quality (`balance-data.md` S14). A sampling test shows floor 9 tiers beat floor 3. *Check: L2.*
- [ ] **PROG-08**: **REPLACED (D27, D30).** The level curve is built for one run: the level at the final boss is whatever the owner approves, reached by playing the floors once, without grinding, inside 45-60 minutes. The old "reach level 10 in one pass" and the "classic grind with respawns" are gone (D14 now means resource management inside a run). *Check: L2 (simulator).*
- [ ] **PROG-09**: Card-pick, shop and level-up screens work with keyboard and gamepad in a plain form in Phase 6; they are restyled in Phase 7. *Check: L3.*
- [ ] **PROG-10**: The Nobody is the 4th playable class (D34) with its own start kit and card pool. The player picks a class at run start. The old flow (start as Nobody, pick a class from a chest) is replaced; whether every class is available from the first run or some unlock is decided in G2/G7. *Check: L2 + L3.* [GRILL: G7]

### ROB - Robustness (new from the plan review; Phases 4, 5, 8)

Only the audit items that still matter for a game where one session plays many runs and the web build drops frames more than Windows.

- [ ] **ROB-01**: About 352 step-counted timers exist outside the QTE and turn code (fades, dialogue typing, skill hold, effects; `codebase/CONCERNS.md`). The ones that change gameplay feel or flow run on a clock, not on Step counts, and a frame-throttled bot run gives the same outcomes. The rest are listed and left. *Check: L3.* (Phase 8, with the web test.)
- [ ] **ROB-02**: Input is forgiving and consistent: one early press is buffered for the next prompt; no dead frames between arrows; a wrong key does not fail the sequence at once; `Input_Update` no longer returns early on the same millisecond (`scr_input.gml:242`); held keys repeat in every list (`audit/ui.md` P9). *Check: L3.* (Phases 5 and 7.)
- [ ] **ROB-03**: Memory does not grow over repeated runs. Every `ds_*` create has a destroy path (18 creates against 6 destroys today; add CleanUp events or destroy at room/run end), and globals are not re-created every Step. A bot loop of 20 runs shows no growth in live ds structures. *Check: L2 + L3.* (Phase 4.)

### BAL - Data, simulator, balance

- [ ] **BAL-01**: **REWRITTEN (data shared, no export step).** Gameplay data lives in JSON files under `datafiles/`: skills, upgrade cards, enemies, elite modifiers, classes, items, loot, shop and encounter tables, statuses, level tables, unlock list. The game loads them with `json_parse`; the Python simulator and the localization/lint tools read the same files, so the game and the simulator cannot drift. Names and descriptions are localization keys, not JSON text. Data is validated at load and fails loudly in debug. *Check: L2.* (Phase 4.)
- [ ] **BAL-02**: **MOVED EARLIER (to Phase 5A).** A Python Monte Carlo simulator reads only the JSON data and the formula test vectors (STAT-02). It runs thousands of fights and whole runs, with three scripted policies (basic attack only, greedy best skill, good play), two QTE skill levels (average and skilled; `balance-methods.md` section 6.3), card-choice policies, and auto-resolved fights if they stay (STAT-14). It is needed by STAT-08, TURN-04, PROG-08 and BAL-04. *Check: L2.*
- [ ] **BAL-03**: The simulator is calibrated against the real game: a seeded bot run of N fights lands inside a stated tolerance of the simulator's result for the same fights. *Check: L3.* (Phase 7.)
- [ ] **BAL-04**: Target bands live in a `targets.csv` and the check fails when a metric leaves its band. Metrics are per fight and, new, per run: run win rate, run length, variance between seeds, pick rate and win rate per card, runs with no viable build. First bands are a proposal (`balance-methods.md` section 6.2: normal fight 3-5 turns, mini-boss 6-10, boss 10-16; HP lost per normal fight 10-25%; skill usage between 5% and 60%, none at 0%), approved by the owner in G8. *Check: L2.* (Phase 7.)
- [ ] **BAL-05**: Skills and cards are balanced against each other, inside the BAL-04 band: no skill is dominated or dominant (known problems: Hilt Bash and Ice Spear dominate, Horizontal Slash is dominated by Wound; `balance-data.md` S1, S3). Not checked until the band exists. *Check: L2 + L5.* (Phase 7.)
- [ ] **BAL-06**: Balance changes are proposals with before and after simulator numbers, kept in the "Balance proposals" section of `PLAYTEST-QUEUE.md`. No balance data file changes without an approved proposal id (D13). *Check: review + L5.*
- [ ] **BAL-07**: The simulator runs in the fast gate whenever balance data changes. *Check: L2.*

### UI - Screens (basics in Phase 2, screens in Phase 7)

The text-size rule on the 640x576 grid (D8) is decided once, in Phase 2 (grill G1), and not again in Phase 7.

- [ ] **UI-01**: One 9-slice panel sprite and one `UI_DrawPanel` are used by every screen. All UI colours are from the four-colour palette (no pure white or black). *Check: L4.*
- [ ] **UI-02**: A pixel font with Korean glyphs (candidate: Galmuri, OFL-1.1; `retro-ui.md` section 6), drawn without anti-aliasing. Every UI string is checked in English and Korean. The text-size rule is the one set in G1. *Check: L4.*
- [ ] **UI-03**: Battle HUD shows the enemy name and HP bar, the player's level, HP and MP, a message panel, and status icons with turn counters that blink on the last turn (max 4 per combatant, then "+N"; `retro-ui.md` section 3). *Check: L4.*
- [ ] **UI-04**: Every status is drawn as an icon, never as a small text tag (the `noncore_text_fallback` flag is off) and shows its turns left. *Check: L3 + L4.*
- [ ] **UI-05**: Inventory and equipment screen: categories, an equipped section, a stat comparison before equipping, a use/equip/drop choice, gear the class cannot use is marked. *Check: L3 + L4.*
- [ ] **UI-06**: Every skill, card, item and status has a one-line description key, shown in a tooltip, with an Info button and a glossary page (`retro-ui.md` section 4). A data test fails if one is missing. Card text uses the same numbers the game applies. *Check: L2 + L4.*
- [ ] **UI-07**: Card-pick screen is styled and readable, and fast: it is shown many times per run, so a pick takes at most two key presses. *Check: L4 + L5.*
- [ ] **UI-08**: Shop screen is styled and readable. *Check: L4.*
- [ ] **UI-09**: Level-up screen shows what changed, with no stale "stat points" text (old BUG-28). *Check: L4.*
- [ ] **UI-10**: Every screen can be used with keyboard or controller only; the cursor is remembered per menu; Back is always the same; held keys repeat in every list. *Check: L3 + L5.*
- [ ] **UI-11**: Skills the player cannot afford are greyed out in battle; battle lists show scroll cues; the tooltip is never hidden for lack of room (`audit/ui.md` P5, P6). *Check: L4.*
- [ ] **UI-12**: One shared module for panel, list row and button replaces the duplicated hand-placed layout code (`audit/ui.md` P7). *Check: L2 (source guard) + L4.*
- [ ] **UI-13**: Class select shows class art, starting stats and a skill preview for the four classes; settings volumes are bars, not text (`audit/ui.md` P8). Cut-first item (see cut order in `ROADMAP.md`). *Check: L4.*
- [ ] **UI-14**: Rows are at least 16 base pixels tall so a later touch version would be possible (`retro-ui.md` section 7). Only done where it costs nothing; no touch work (D28). *Check: L4.*
- [ ] **UI-15**: Run screens (new): run start with class pick, the run-end screen (death line, floor reached, class, level, small seed, new unlock or death gift), and the credits. Plain in Phase 6, styled in Phase 7. *Check: L3 + L4.*

### ART - Icons and art (pipeline in Phase 2, icons in Phase 7)

- [ ] **ART-01**: The ComfyUI pipeline is reproducible: SDXL base plus the Pixel Art XL LoRA, a fixed prompt skeleton, a prompt CSV, saved seeds, a scripted palette step to the four colours, output under `E:\AI\ComfyUI\ComfyUI-Shared\output\dd_icons\` (`research/icons-comfyui.md` sections 0-1). First step is a 5-icon test: regenerate 5 existing icons and compare side by side. *Check: L4.*
- [ ] **ART-02**: No FLUX.1 [dev]-based pixel LoRA is used (non-commercial licence, `icons-comfyui.md` section 1). A model/LoRA/licence note is kept with each icon batch. *Check: review.*
- [ ] **ART-03**: 10 new 16x16 status icons exist as round badges: guard, rev_up, evasion, take_aim, foresight (an EYE), meditation, solidify, bloodthirsty, blessing, sunder (`audit/icons-needed.md` section 2). Buffs and debuffs differ by shape, not only colour (`retro-ui.md` section 3). They are drawn only after the status list is fixed by STAT-06 and STAT-10 (Evasion, Solidify, Bloodthirsty and Foresight may change or go). *Check: L2 (palette and size script) + L4.*
- [ ] **ART-04**: Player skill icons, 16x16, one per skill in the final pool (about 20: four classes of about 5; 14 exist today in `audit/icons-needed.md` section 3) and one rule for how an upgrade ("+") looks, so upgrades need no new icon. *Check: L2 + L4.*
- [ ] **ART-05**: Item icons: HP Potion Lv2/Lv3 and MP Potion Lv2/Lv3 (4 icons, `icons-needed.md` section 4). The 3 skill-book icons in that list are dropped (D18). *Check: L2 + L4.*
- [ ] **ART-06**: UI pieces: 9-slice panel, select bar, cursor, scroll arrows, equipped mark, a pixel QTE arrow (replaces 4 `draw_line` calls), four class icons (Knight, Archer, Mage, Nobody), four stat icons (ATK, DEF, SPD, MAG), turn-order bar pieces, a recoloured dialogue arrow (now pure `#ffffff`) and battle background (now `#0a2533`, outside the palette) (`icons-needed.md` section 5, updated for D22 and D34). Mostly geometric, so made by script or by hand at the start of the UI work, not with ComfyUI. *Check: L2 + L4.*
- [ ] **ART-07**: Every icon is hand-cleaned at 16x16 (expect to redraw most; `icons-comfyui.md` section 8). A checker script confirms each file is 16x16 with only the four colours plus transparent. *Check: L2.*
- [ ] **ART-08**: The owner imports sprites through the IDE. After that, code points `icon_sprite` at them and the placeholder helper functions (`Status_AssignPlayerBuffIconsFromFX`, `Status_AssignMissingIconsFromSkillFX`) are removed. *Check: L1 + L4.*

### WEB - Release builds (Phase 8)

- [ ] **WEB-01**: The HTML5 export builds from the wrapper using Igor, with no IDE. This is unverified today (only Windows was tried); the spike is in Phase 2. *Check: L1.*
- [ ] **WEB-02**: The Opera GX target is removed in the IDE by the owner (D15). *Check: L1.*
- [ ] **WEB-03**: After each export, a script re-applies the account-namespace hook in `DD-Project.js` where `_V9._U54=_Q54()` is assigned: append `(window.__MIGUISANSON_GAME_INSTANCE__||"guest")+"."` to the prefix (`live-miguisanson-dev/games/dd-project/README.md`). A check confirms the string is present in the output. The exported `index.html` is not copied. *Check: L2.*
- [ ] **WEB-04**: The hand-off to `live-miguisanson-dev` is a zip of `html5game/` plus a short note with the exact steps from that README. This repo does not deploy. *Check: L1 + review.*
- [ ] **WEB-05**: In a browser, the game starts, takes keyboard input, plays sound after the first interaction, and a save and load round trip works for both save parts (profile and run), including a page reload in the middle of a run. `screen_save` does not work on HTML5, so browser screenshots are taken from outside the game. The RUN-11 golden-sequence test passes in the browser. *Check: L3 (browser) + L4.*
- [ ] **WEB-06**: Download size and first-load time are measured and reported (the Windows `data.win` was 78 MB, `automation-igor.md` section 2.4). The owner decides if it is acceptable. *Check: measurement.*
- [ ] **WEB-07**: Debug keys and debug overlays are off in release exports (closes old BUG-26). *Check: L2.*
- [ ] **WEB-08**: A Windows zip for friends is built with Igor `PackageZip` (`automation-igor.md` section 2.4). *Check: L1.*
- [ ] **WEB-09**: A release-candidate playtest by the owner (and a friend, if possible) on a named build id has no open P1. One run is a sample of one, so it covers a full winning run to the credits plus at least two other runs including a death. *Check: L5.*

### LOC - Localization (text fixes in Phase 1, batch in Phase 8)

- [ ] **LOC-01**: The Korean batch is filled before release through the existing pipeline (`tools/localization/`). English stays first. *Check: L2.*
- [ ] **LOC-02**: A missing-translation check lists every key with an empty Korean value. It is informational until release and blocking at release (D9). *Check: L2.*
- [ ] **LOC-03**: The hard-coded English found by the audits goes through localization: "Game saved." (`obj_game_controller/Step_0.gml:70`; reuse the existing key `sys_save_ok`, `scr_dialogue.gml:34`, no new key), the level-up text (`scr_enemy.gml:84`), the `Equip_CanEquip` messages (`audit/ui.md` P10). `lint_hardcoded_text.py` reports nothing new. *Check: L2.*
- [ ] **LOC-04**: Every new player-facing string in new features (cards, shop, QTE words, tooltips, glossary, death lines, unlock names, run-end screen, credits) is added through `game_text.xlsx` and the build script. *Check: L2.*
- [ ] **LOC-05**: Korean text is readable in the chosen pixel font and fits its box on every new screen. *Check: L4.*

### SAVE - Save format (Phase 4; two parts, D36)

Two save parts, each with its own schema version. The field lists are fixed in grill G3 (Phase 3), before any combat-data or save code is written.

- [ ] **SAVE-01**: **RESHAPED (D36).** The **profile** part holds story-seen flags, unlocks, the death gift and settings. The **run** part holds the seed, RNG stream counters, class, level, cards, gold, items and floor. Each has a schema version (the existing `SAVE_SNAPSHOT_VERSION 2`, `scr_macros.gml:321`, is the starting point and is bumped for the new shape). *Check: L2.* [GRILL: G3]
- [ ] **SAVE-02**: An old-format save (v1.8 and earlier) is detected and rejected with a friendly on-screen message, no crash, and no overwrite of the old file (D16). The old-format fixture is made by running `v1.8` in the scratch save area, never by copying the owner's real save. *Check: L2 + L3.*
- [ ] **SAVE-03**: Saving then loading the run gives an identical state (HP, MP, level, inventory, flags, room, statuses, cards, gold, seed and counters). *Check: L2.*
- [ ] **SAVE-04**: Saving writes to a temporary file and then replaces the old one, for both parts, so a crash cannot leave a half-written save; a corrupt file is handled without a crash (`codebase/CONCERNS.md`, Fragile Areas). Use the `save-systems` skill. Safe to build now. *Check: L2.*
- [ ] **SAVE-05**: `Save_ToReal` does not throw on non-numeric text. Safe to build now. *Check: L2.*
- [ ] **SAVE-06**: Settings from older versions migrate and keep working (volumes, scale, language). The removed difficulty setting is dropped cleanly. See DISP-14 (version 7 to 8). *Check: L2.*
- [ ] **SAVE-07**: **RESHAPED.** New run data from Phases 5-6 (turn state, gold, cards, upgrades, stream counters, shop stock bought, chests opened) round-trips in the run part. *Check: L2.*
- [ ] **SAVE-08**: A corrupt or missing run file never damages the profile, and a corrupt profile never crashes the game. Death clears only the run part. The profile is written when a story flag is set, a death happens or an unlock is earned. *Check: L2.*

### GAP - Found 2026-10-14 after the plan rework (grill each right before building it)

- [ ] **GAP-01**: Every new feedback moment (QTE grades, arrow presses, card pick, shop buy, turn-bar stun, death, unlock) has a sound: existing sounds reused first, jsfxr-style SFX only for gaps (D41); levels on the existing buses (`audio-design`). Each place uses a fitting existing music track with fades (D42). No feature ships silent. *Check: L3 (sound id fired per event, logged) + L5.*
- [ ] **GAP-02**: New sprite work outside icons is listed and sized before Phase 6: Nobody skill animations, merchant sprite, an elite marker that reads in 4 colours (outline/aura/badge), card frame art. Reuse/recolour first, ComfyUI only for gaps (D43). *Check: L4 screenshot of each in game.*
- [ ] **GAP-03**: Just-in-time prompts teach the turn bar, each QTE type, card picks, the shop and beds (one prompt per mechanic, first time only, stored in the profile); a Help page in the pause menu repeats them (D45). *Check: L3 (prompt shows once, never on run 2) + L5.*
- [ ] **GAP-04**: Every run writes a small local run log (build id, seed, class, floor reached, cause of death, cards taken, gold spent, QTE grade counts). Windows: file in the save folder; web: "copy run log" button on the run-end screen; no upload (D51). The simulator reads it. *Check: L2 (log schema) + L3 (bot run produces a log).*

- [ ] **GAP-05**: Credits screen lists every sound/music creator supplied by the owner (D40), plus fonts/tools/licences used (Galmuri OFL, MIT libraries). *Check: L4 screenshot + list matches `datafiles/credits` source.*
- [ ] **GAP-06**: Auto-save on room change, after each fight and on quit; "Continue run" on launch; no reload after death (D46). *Check: L3 (bot quits mid-run, relaunch resumes same room/HP; death deletes the run save).*
- [ ] **GAP-07**: Beds are rest sites: once per run per bed, choose heal OR upgrade one owned skill (D47). *Check: L3 + L5.*
- [ ] **GAP-08**: Hold confirm ~1 s skips a cutscene/camera pan and marks it seen; a tap only advances text (D48). *Check: L3.*
- [ ] **GAP-09**: Settings: QTE assist, key rebinding (keyboard; works in the browser), text speed, screen shake on/off, plus existing volume/language/window size (D49). Saved in the profile. *Check: L2 + L3.*
- [ ] **GAP-10**: Web: play page warns that clearing browser data erases saves; phones get an "unsupported" message; full run passes on desktop Chrome, Firefox and Edge (D50). If any of these can't be met, the Windows download becomes the only offering (D39). *Check: L5 per browser + WEB rows.*

## Cut order (D28)

The must-haves are card picks, the turn-order bar, gold and shop, and the new QTE types (D29). If time runs short, cut in this order and tell the owner: UI-13, UI-14, DISP-12, ART-04's upgrade-look polish, RUN-13 (elite variants), then ask. Nothing else is cut without the owner.

## Not built, ever (D28: no post-release)

There is no "later". These were listed as later before; they are now simply out:
- Android, porting, phone browsers, touch controls (D38, D50).
- Bestiary and enemy-skill icons (the 13 optional enemy icons in `audit/icons-needed.md` section 3).
- QTE calibration screen, auto-success and QTE-off options (QTE-13 is narrowed).
- A post-win difficulty ladder, daily or entered seeds, run modifiers, a node map or procedural floors (`roguelike-design.md` options A+, B, C). Not decided, so not built.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Android / porting | Never (D38) |
| Porting to other engines or platforms | Never (D38) |
| GX.games / Opera GX | D15: own site instead |
| Old save compatibility | D16: clean break |
| New floors, new story, new content beyond the decisions | D1, D28. The only new class is the Nobody (D34, already in the game) |
| Easy/Normal/Hard | D35: one difficulty plus a QTE assist |
| Permanent stat power between runs | D32: unlocks and a death gift only |
| Store and legal work | D2: free release |
| Deploying the website | D15: other repo's job |

## Replaced or changed by D25-D36 and the plan review

| Old requirement | What happened | Why |
|---|---|---|
| STAT-09 (Easy/Normal/Hard gaps) | REPLACED: one difficulty | D35 |
| STAT-12 (level-up table) | CHANGED: resets each run | D27 |
| STAT-13 (export balance data) | RETIRED, merged into BAL-01 | data is shared JSON |
| PROG-08 (XP curve to level 10 in one pass, grind) | REPLACED: curve for one 45-60 min run | D14 amended, D27, D30 |
| PROG-01..07 | CHANGED: seeded, per-run, four classes, gold lost on death | D26, D33, D34 |
| BAL-01 (CSV/JSON export) | REWRITTEN: data lives in shared JSON | plan review + D13 |
| BAL-02 (simulator in Phase 8) | MOVED to Phase 5A | plan review 1b item 1 |
| BAL-04 (bands per fight) | CHANGED: bands per run too | D25 |
| QTE-13 (four assist options) | NARROWED to the window multiplier | D35, D28 |
| SAVE-01..07 (one save) | RESHAPED to profile + run; SAVE-08 added | D36 |
| BUG-01, 02, 09-15, 18, 19, 22, 23, 25, 26, 28, 29 | Moved out as pointer rows (see map below) | plan review 1c |
| Death reloads the latest save slot | REPLACED by RUN-02 | D26 |
| "Classic JRPG grind" / respawn farming | REPLACED by resource management inside a run (RUN-15 decides respawns) | D14 amended by D25 |
| VER-14 (whole gate in ~40 s) | SPLIT into fast and full gate | plan review 1b item 4 |

## Traceability

Each requirement maps to one primary phase (`ROADMAP.md`). Where a later phase repeats or re-tests it, the roadmap says so.

| Requirement | Phase | Status |
|-------------|-------|--------|
| VER-01 to VER-16 | Phase 1 | Pending |
| BUG-03 to BUG-08, BUG-16, BUG-17, BUG-20, BUG-21, BUG-24, BUG-27 (repros and fixes that survive; rebuilds finish BUG-04, 08, 16, 17, 20) | Phase 1 | Pending |
| LOC-03, SAVE-04, SAVE-05 | Phase 1 | Pending |
| DISP-01 to DISP-15 | Phase 2 | Pending |
| UI-01, UI-02, UI-12, ART-01, ART-02, ART-07 (pipeline and checker) | Phase 2 | Pending |
| Prototypes P1-P4 and grills G2, G3 (decisions only, no requirement closes) | Phase 3 | Pending |
| BAL-01, SAVE-01, SAVE-02, SAVE-03, SAVE-06, SAVE-08, ROB-03, VER-12 (streams: RUN-11 starts) | Phase 4 | Pending |
| STAT-01 to STAT-12, STAT-14, BAL-02, BAL-07 | Phase 5 (5A) | Pending |
| QTE-01 to QTE-15, ROB-02 (QTE part) | Phase 5 (5B) | Pending |
| TURN-01 to TURN-07 | Phase 5 (5C) | Pending |
| RUN-01 to RUN-16, PROG-01 to PROG-10, SAVE-07, UI-15 (plain), PROG-09 | Phase 6 | Pending |
| BAL-03 to BAL-06, UI-03 to UI-11, UI-13 to UI-15 (styled), ART-03 to ART-06, ART-08, LOC-05, ROB-02 (UI part) | Phase 7 | Pending |
| WEB-01 to WEB-09, LOC-01, LOC-02, LOC-04, ROB-01 | Phase 8 | Pending |

**Closed-by map for the 17 pointer rows moved out** (not requirements; each still has its `ISSUES.md` row):

| Old row | Closed by |
|---|---|
| BUG-01, BUG-10, BUG-11, BUG-29 | DISP-04 to DISP-08, DISP-03 to DISP-12 |
| BUG-02 | STAT-10, UI-06 |
| BUG-09 | STAT-04 |
| BUG-12 | the QTE category |
| BUG-13 | BAL-05 |
| BUG-14 | ART-03, UI-04 |
| BUG-15 | the UI category |
| BUG-18 | TURN-03 |
| BUG-19 | STAT-03 |
| BUG-22 | STAT-07 |
| BUG-23 | STAT-11 |
| BUG-25 | QTE-11 |
| BUG-26 | WEB-07 |
| BUG-28 | UI-09 |

**Coverage**
- Before this revision: 154 requirements (16 VER + 15 DISP + 29 BUG + 13 STAT + 7 TURN + 15 QTE + 9 PROG + 7 BAL + 14 UI + 8 ART + 9 WEB + 5 LOC + 7 SAVE), of which 17 were pointer rows, so about 137 real.
- After this revision: **159** requirements = 16 VER + 15 DISP + 12 BUG + 13 STAT + 7 TURN + 15 QTE + 16 RUN + 10 PROG + 3 ROB + 7 BAL + 15 UI + 8 ART + 9 WEB + 5 LOC + 8 SAVE. (154 - 17 pointer rows - 1 retired STAT-13 + 23 new: RUN 16, ROB 3, SAVE-08, PROG-10, UI-15, STAT-14.) Eight requirements marked REPLACED, CHANGED, REWRITTEN, MOVED, RESHAPED or NARROWED keep their IDs.
- Mapped to phases: 159. Unmapped: 0.

---
*Requirements defined: 2026-10-13*
*Last updated: 2026-10-14 for D25-D36 (roguelike) and the plan review*
