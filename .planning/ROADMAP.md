# Roadmap: DD-Project (GameMaker)

## Overview

Milestone v2.0 "Done right" now means: the same game, fixed, and turned into a replayable roguelike-style game (D25-D36). A run is about 45-60 minutes through the existing floors; you die, return to the entrance room, and try again with unlocks and a death gift. Everything decided ships in the release, then development stops (D28).

**The owner reads `BOARD.md`, not this file.** The eight phases below are internal bookkeeping for the agents (and for GSD commands). A board item can be a whole phase, part of one, or a quick task.

The order follows `research/plan-review.md`:
1. Start what is safe whatever the design says (harness, display, old bugs, safe saves, icon pipeline, UI basics).
2. At the same time, play throwaway sketches to settle feel and the run loop before locking anything.
3. Ask the owner only the questions for the thing about to be built (5-10 per topic), never 100 at once.
4. Put game data in JSON that the game and the simulator both read, and settle the profile/run save split before any combat-data or save code.
5. Build the combat core with the simulator available from the start, then runs and progression, then balance, screens and icons.
6. Last: web export, Korean, release-candidate playtest. Then stop.

Rules for every phase:
- Test first. Write the failing check, watch it fail for the right reason, then build. (AGENTS.md Rule 1)
- Each phase ends with `/gsd-verify-work`, a STATE.md update, a BOARD.md update, and the `REGRESSION.md` entries for the phase marked with a build id.
- Owner checks (L5) happen per feature in `PLAYTEST-QUEUE.md` (D12), not only at the end of a phase. (`.planning/config.json` has `human_verify_mode: "end-of-phase"`, which should be relaxed to match; flagged for the main session, not changed here.)
- Design details not in `research/DECISIONS.md` are asked with grill-me in a short topic (G1-G10 below) right before the item is built, one decision at a time, with a recommendation. Agents never guess them. A decision is "paper" until the owner has played it.
- Anything that needs a new or renamed IDE resource (object, sprite, room, script, font) is an owner task, listed per phase (AGENTS.md Rule 4).
- Check levels L1-L5 are defined in `REQUIREMENTS.md`. Two gates: the fast gate for every packet, the full gate for every playtest build.
- Improvement mode (`IMPROVE.md`) can start after Phase 1 is done. It is not a phase.
- Scope is closed (D28). If an idea is not in `DECISIONS.md`, it is not built. The cut order if time runs short is in `REQUIREMENTS.md`.

## Phases

- [ ] **Phase 1: Safe-now foundations** - test harness, old-bug repros and fixes, safe save writes, localization text fix
- [ ] **Phase 2: Display and UI kit** - one display manager, cutscene/dialogue-end screen bug, HTML5 canvas fit, 9-slice/font/shared module, icon pipeline
- [ ] **Phase 3: Sketches and run frame** - four throwaway sketches the owner plays; grills for the run frame and the save contract
- [ ] **Phase 4: Data and saves** - game data in JSON, profile/run save split, seeded streams, memory cleanup
- [ ] **Phase 5: Combat core** - formulas and simulator (5A), QTE (5B), turn-order bar (5C)
- [ ] **Phase 6: Runs and progression** - run loop, death, unlocks, story flags, shuffles, cards, gold, shop, Nobody class
- [ ] **Phase 7: Balance, screens, icons** - simulator pass with owner approval, styled screens, real icons
- [ ] **Phase 8: Release** - web export, Korean, release-candidate playtest, then development stops

**Lanes (what can run at the same time).** Phases 1, 2 and 3 start together after the owner's go. They share no files: Phase 1 is tooling and a few bug fixes, Phase 2 is display and UI plumbing, Phase 3 is sketches in a scratch copy plus questions. Phase 4 needs Phase 1 (tests) and the save contract from Phase 3. Phases 5 and 6 need Phase 4. Phase 7 needs 5 and 6. Phase 8 needs everything. Icon pipeline work (Phase 2) touches no game code and runs in the background.

**If a phase is too big for the packet-size cap** (about 150 changed GML lines and about 3 files per packet, `lessons` 4.2), `/gsd-plan-phase` inserts a decimal phase (for example 6.1 for gold and shop) instead of renumbering.

## Phase Details

### Phase 1: Safe-now foundations
**Goal**: The project can be built, tested, played by a bot and photographed from one command, a failing check really turns the gate red, and the old bugs are either reproduced and fixed or shown not to happen. Saves are written safely.
**Depends on**: Nothing. Needs the Igor path verified in `research/automation-igor.md`. Does not wait for the friend's answer about the build (I-039).
**Requirements**: VER-01 to VER-16, BUG-03 to BUG-08, BUG-16, BUG-17, BUG-20, BUG-21, BUG-24, BUG-27, LOC-03, SAVE-04, SAVE-05
**Waves**:
- 1A Compile wrapper: `tools/automation/run_tests.ps1`, scratch copy on E:, exit and `Error :` parsing, negative control, real-save protection, drive guard (VER-01, 03, 04, 06, 14, 15).
- 1B `Test_Boot` and suites: hook in `obj_game_controller/Create_0.gml`, `exception_unhandled_handler`, `Test_Eq`, one pilot suite (`Test_Suite_Math`), then Combat, Status, Inventory, Data, Save (VER-02, 05, 11, 12, 13).
- 1C Scenario modes: `-smoke`, `-bot`, `-shots`, build id stamp (VER-07 to VER-10). Keep the bot thin: combat and QTE will change, so it reads the QTE's own data and is rewritten with the QTE (VER-08).
- 1D Process: apply `research/AGENTS-CHANGES.md` to AGENTS.md, create the `next` branch, add a `/improve_DD-Project-GameMaker` command, wire `REGRESSION.md` to test names (VER-13, VER-16).
- 1E Old bugs, in this order: repro each `[VERIFY FIRST]` item on the current build (BUG-04, 07, 08, 27, 24); fixes that survive the rebuilds (BUG-05/06 skill action time, BUG-08 poison tick feedback, BUG-21 self-buff on the player, LOC-03 including reuse of `sys_save_ok`); safe save writes (SAVE-04, SAVE-05). If a bug lives in a system Phase 5 rebuilds, write the repro and the regression entry now and fix it there.
**Success Criteria** (what must be TRUE):
  1. The fast gate on a clean checkout prints PASS and exits 0 in about 40 s (compile + `-runtests` + `-smoke`). The full gate adds `-bot` and `-shots` and finishes in a few minutes; its timeouts are 30 + 60 + 120 s (L1 + L2 + L3).
  2. The negative control (a deliberately failing test) turns the gate red; removing it turns it green (L2).
  3. Mutation proof: a syntax error turns the compile step red (L1); a call to a function that does not exist turns the smoke step red (L3).
  4. A bot battle runs through key presses, ends, and the state assertions pass (L3).
  5. After a full run, the files in `%LOCALAPPDATA%\DD_Project` are unchanged (L2).
  6. The title-screen screenshot shows the build id, and the same id is in the test summary (L4).
  7. AGENTS.md is under about 220 lines, matches `AGENTS-CHANGES.md`; `ISSUES.md`, `REGRESSION.md` and `PLAYTEST-QUEUE.md` exist; branch `next` exists (review).
  8. Every `[VERIFY FIRST]` item has a recorded outcome ("reproduced on build X" or "not reproducible on build X") and its ISSUES row is updated (L3).
  9. Skill action time for Ice Spear and Hilt Bash is at or below the owner's target (L3 then L5); a poison tick shows a log line, a sound and a flash (L3 + L4); the localization lint reports nothing new (L2).
  10. A save killed halfway leaves the old save intact; non-numeric save text does not throw (L2).
**Owner / IDE tasks**: create one script asset `scr_test` in the IDE (about 1 minute). Fallback with no owner action: put it in `scr_debug.gml` (`automation-igor.md` section 3.1). Confirm the Igor command once on the owner's machine while the IDE is open (untested together). One FEEL number: the target total action time for a skill (G0, one question). Trimming empty tail frames of `stun_effect`, `explosion_effect` or `bleed_effect` is a sprite edit, only if the owner wants it.
**Domain skills**: `save-systems` (atomic write), `game-feel` (hold time, tick feedback), `audio-design` (tick sound).
**grill-me needed?**: One question only (G0: target skill action time). Otherwise go straight to `/gsd-plan-phase 1`.
**Plans**: 5 waves

### Phase 2: Display and UI kit
**Goal**: The picture is always the right size and never snaps, on every window size, in fullscreen, in the browser canvas, and when a cutscene or dialogue ends. The shared UI pieces exist. The icon pipeline is ready.
**Depends on**: Phase 1 waves 1A-1C (needs the screenshot matrix and the bot to repro the screen bug). The UI kit part needs the D8 text rule (G1). The icon pipeline needs only Phase 1's checker.
**Requirements**: DISP-01 to DISP-15, UI-01, UI-02, UI-12, ART-01, ART-02, ART-07 (and the pointer bugs BUG-01, 10, 11, 29)
**Order of work** (from `audit/resolution.md` section 4b):
1. **Spike first** (`research/resolution-gamemaker.md` section 8): the six points with a screenshot or a logged number, plus (7) can Igor build HTML5 at all.
2. **Measure** the current screen bug: the bot records window, display, GUI, port and camera values around a cutscene end and a dialogue end, with screenshots (settles hypotheses H1-H4).
3. **Cheap safe fixes**: keep the cutscene art until the exit fade is black (H2); window colour to black; stop calling `GameSettings_ApplyDisplay` from `Transition_Finish`; `window_center()` only when the size changed.
4. **One display manager** (`obj_display` + `scr_display`), view 0 as 160x144, app surface drawn in Post Draw at an integer scale, GUI via `Display_GuiW/H`.
5. Replace all 18 GUI-size call pairs (36 calls, 11 files), remove the self-heal block from `obj_sfx_manager`, migrate settings (version 7 to 8, DISP-14).
6. G1 settled: build the 9-slice panel, the pixel font and the shared panel/row/button module (UI-01, 02, 12) on one screen.
7. Icon pipeline in the background: ComfyUI nodes, LoRA, 5-icon test, palette script, checker (ART-01, 02, 07). No icon list yet; the list waits for the status and card decisions.
**Success Criteria** (what must be TRUE):
  1. `Display_CalcLayout` returns the expected scale and offsets for every window size in `resolution-gamemaker.md` section 7.1 (L2).
  2. The screenshot matrix (all sizes, windowed and fullscreen) passes the pixel checker `tools/display/check_display.py`, run with `python -I`: exact rectangle, black bars, no blur (L4).
  3. Bot run of "cutscene ends" and "dialogue ends" in floor 1, 5 and 9.5: before and after screenshots have the same geometry, the last cutscene image fades out, and the display-apply counter does not move during the transition (L3 + L4).
  4. Five quick fullscreen toggles end in a correct layout with no coloured bars (L3 + L4).
  5. In a browser the canvas fits at several browser sizes and stays sharp (L4).
  6. A source guard finds no `display_get_gui_*` call outside `scr_display` (L2).
  7. The owner walks the 4c checklist in `audit/resolution.md` once and signs off the cutscene-end and dialogue-end rows (L5).
  8. One screen uses the shared panel and font in English and Korean (L4).
**Owner / IDE tasks**: create `obj_display` and `scr_display`; set every room's view 0 port to 160x144; fix `rm_floor6_5` (only 144 wide) and the floor view borders; set `option_window_colour` to black; import the 9-slice sprite and add the pixel font; set the 9-slice flag. Removing the Opera GX target waits for Phase 8.
**Domain skills**: `game-ui-ux`, `create-game-assets`.
**grill-me needed?**: G1 (3 decisions): how text is drawn on the 640x576 grid at windowed scales 3-5; fullscreen at integer scale only or fit-to-window; the result of the Korean legibility spike. **Decided here once and not asked again in Phase 7.**
**Plans**: TBD

### Phase 3: Sketches and run frame
**Goal**: The things only play can answer are answered, and the run frame is written down before any code depends on it. No game code is changed in the real repo.
**Depends on**: Nothing. Runs alongside Phases 1 and 2. A sketch is a **throwaway**: built by a Sonnet subagent in a scratch copy (`E:\Temp\dd-spike-<name>`), `LOCALAPPDATA` redirected, builds on E:, never merged, deleted afterwards. No tests required. The owner plays each for about 10 minutes and the answer is written into `DECISIONS.md` as the next decision numbers.
**Requirements**: none closes here. These produce decisions that unblock RUN, PROG, QTE, TURN, SAVE.
**The four sketches** (plan review section 3):
- **P1 Run loop.** Hack: on death, wipe the character and go to the entrance room; level 1 each run; 3 random skills offered at each chest; two or three floors. Questions: is "die, return, try again" fun on these floors? How long is a run? Does walking feel like padding? Can the enemy kind at a spawn point be swapped by code alone (RUN-12)?
- **P2 QTE feel.** Hack the existing ring with a millisecond clock and three window presets the owner switches by key; add a simple arrow sequence. Questions: ring or bar; Perfect and Good window sizes in ms; arrow count; "too early" feedback; wind-up length for a defence telegraph.
- **P3 Turn bar in 1 vs 1.** Plain rectangles over the current battle. Questions: does the bar add anything with one enemy? Is "stun delays" readable? (D29 lists the bar as a must-have, so the default is to build it; this decides how.)
- **P4 Card-pick cadence.** Part of P1: pick 1 of 3 at every chest, at every level-up, or both. Does an upgrade feel like a reward? How fast must the screen be?
**Grill topics in this phase** (right after the sketches):
- **G2 Run frame details** (8-10 decisions): which existing room is the entrance; unlock list and triggers (short, D28); what the death gift is; the death line set and how one is chosen; class pick at run start and whether all four classes are open from the first run; do enemies respawn inside a run (RUN-15); where saving is possible and whether pause-menu "save and quit" exists (RUN-14); what later wins show (RUN-09); how many card picks per run.
- **G3 Save contract** (5-6 decisions): the exact field lists of the profile and run parts (D36), when each is written, the schema version rules, the friendly old-save message. **Must finish before Phase 4 starts** (the save split is decided before combat data and save work).
**Success Criteria** (what must be TRUE):
  1. Each sketch is played by the owner and its answer is written into `DECISIONS.md` (D37 onward) with the date and the sketch build id (L5).
  2. G2 and G3 are written down; `REQUIREMENTS.md` RUN, PROG and SAVE rows tagged `[GRILL: G2/G3]` are updated with the answers (review).
  3. The sketches' code is deleted, or kept only in the scratch folder; nothing is merged (review).
**Owner / IDE tasks**: play the sketches (about 10 minutes each). A sketch may need one IDE step in its scratch copy only.
**Domain skills**: `game-feel` (P2), `save-systems` (G3).
**grill-me needed?**: Yes: G2 and G3, after the sketches.
**Plans**: TBD

### Phase 4: Data and saves
**Goal**: All game numbers live in JSON that the game and the simulator both read, the save is split into profile and run, randomness is seeded per run, and repeated runs do not leak memory.
**Depends on**: Phase 1 (tests), Phase 3 (G3 save contract, P1 answers).
**Requirements**: BAL-01, SAVE-01, SAVE-02, SAVE-03, SAVE-06, SAVE-08, ROB-03, VER-12 (the stream generator and golden test of RUN-11 start here)
**Order of work**: JSON schema and loader first (skills, enemies, classes, items, loot, statuses, level tables, unlock list; names and descriptions stay loc keys); validation in the data suite (VER-11). Then the save split with the old-save fixture and the friendly rejection. Then the seeded stream generator (no 64-bit or sign-dependent bit operations) with its golden test on Windows. Then the `ds_*` create/destroy sweep and a 20-run memory loop.
**Success Criteria** (what must be TRUE):
  1. Changing a number in the JSON changes the number in the game, and the data-integrity suite fails on a broken reference (L2).
  2. The Python tools read the same files (a read-back test) (L2).
  3. An old-format save fixture is rejected with the friendly message and no crash; a new run save round-trips exactly (L2 + L3).
  4. A corrupt run file leaves the profile intact and the reverse does not crash (L2).
  5. The golden-sequence test passes on Windows (the web run is in Phase 8) (L2).
  6. A bot loop of 20 runs shows no growth in live ds structures (L3).
**Owner / IDE tasks**: none expected.
**Domain skills**: `save-systems`.
**grill-me needed?**: No new design (G3 already settled the contract). The JSON field names are an agent detail.
**Plans**: TBD (expect 3; if too big, the stream and memory work becomes Phase 4.1)

### Phase 5: Combat core
**Goal**: The numbers underneath fights are simple, fair and testable; the QTE feels good; the player can see who acts next. The simulator exists from the first step, so every later check can use it.
**Depends on**: Phase 4 (data, streams), Phase 3 (sketch results P2, P3). 5B does not depend on 5C; 5B may start before 5C.
**Requirements**: STAT-01 to STAT-12, STAT-14, BAL-02, BAL-07; QTE-01 to QTE-15, ROB-02 (QTE part); TURN-01 to TURN-07
**Order of work** (the grade table is decided once, by QTE-03):
- **G4 QTE grills first** (5-7 decisions): the grade table (names, ms windows, damage or effect scale; reference values in `qte-design.md` section 5 are not decisions), which skills use a ring or bar and which an arrow sequence, sequence length, which enemy moves are big (D7), the defence input and what it gives, early-press treatment, the size of the wider-window assist (D35).
- **G5 Combat numbers** (8-10 decisions): formulas for ATK, DEF, SPD, MAG and what DEF does; how weapons add to skill damage; whether enemy attacks can miss and what Evasion, Solidify and Bloodthirsty become; Foresight's new effect (D24) and its tooltip words; where crit comes from; damage-over-time durations, tick size, caps, stacking and Guard; what Curse becomes; level-up gains per class for a 45-60 minute run; whether auto-resolved fights stay (STAT-14).
- **5A Formulas and simulator.** Write the formula spec and its JSON test vectors; the GML tests and the Python simulator both pass them (STAT-02). Then build the formulas, one difficulty (STAT-09), no misses, damage over time, Foresight. The simulator (BAL-02) reads the JSON data and plays whole runs; it is in the fast gate when data changes (BAL-07).
- **5B QTE.** Clock and `Qte_Judge`, ring/bar type, arrow type, basic attack, defence telegraph, feedback, the wider-window option. The bot is rewritten to drive both types. Input buffering and no dead frames (ROB-02).
- **G6 Turn order grill** (after P3, 5-6 decisions): how SPD becomes turn frequency, how far stun pushes, boss stun resistance, what enemy free actions become, when ticks and counters advance, whether the next enemy move is visible, confirm 1 vs 1.
- **5C Turn-order bar.** Plain shapes first (styled in Phase 7).
**Success Criteria** (what must be TRUE):
  1. All formula tests pass with expected values from the approved spec; one constant mutation turns at least one red (L2).
  2. 10,000 seeded casts of every skill against every enemy show zero misses; every basic-attack grade deals at least 1 damage (L2).
  3. Every damage-over-time source has a fixed duration; with any defence-QTE result it is not longer than base; the tooltip number equals the applied number (L2).
  4. The simulator passes the same test vectors as the GML code and reports a full-run win rate (L2).
  5. `Qte_Judge` boundary tests pass at the exact edge of every window; the same press time gives the same grade at normal speed and with a simulated 100 ms hitch (L2).
  6. The bot hits Perfect, Good and Late on purpose in both QTE types and the grades match (L3).
  7. A normal enemy hit never opens a defence QTE; a flagged big move does, with a visible telegraph; the HP bar does not drop before the defence resolves (L2 + L3).
  8. SPD 2:1 gives about 2:1 actions; a stun moves the target back by the approved amount and grants no extra actions; boss stun follows the resistance rule in the simulator (L2).
  9. The turn-order bar matches the internal order frame by frame in a bot run at the supported sizes (L3 + L4).
  10. The owner plays one fight with each QTE type and the bar and answers a short checklist; "feels fair" is the gate for Phase 7 tuning (L5).
**Owner / IDE tasks**: sprites for the QTE arrow and ring or bar (made by script or hand, imported by the owner); sound assets if new ones are wanted.
**Domain skills**: `game-feel`, `audio-design`, `game-ui-ux`.
**grill-me needed?**: Yes: G4, G5, G6 (each right before its part).
**Plans**: TBD (three waves, expect 6-8 plans)

### Phase 6: Runs and progression
**Goal**: A full run works end to end: pick a class, climb the floors with card picks, gold and a shop, die and return to the entrance with a death line and a gift, or win and see the ending and credits. Cutscenes and dialogue never repeat.
**Depends on**: Phase 4 (streams, save split, JSON), Phase 5 (skills, stats, QTE exist), Phase 2 (stable screen).
**Requirements**: RUN-01 to RUN-16, PROG-01 to PROG-10, SAVE-07, UI-15 (plain), PROG-09
**Waves**:
- 6A Run frame: run start, level reset, death to the entrance, clean-state reset, story-seen flags and safe skipping, death line, death gift, unlocks (RUN-01 to 08, RUN-16).
- 6B Shuffles and cards: seeded enemy pools per floor, chest and loot tables, elite variants, card offers and upgrades, the Nobody class pool, class pick (RUN-11 to 13, PROG-01 to 04, PROG-10).
- 6C Gold, shop, loot per floor, level curve, save-and-resume, ending and credits, plain screens (PROG-05 to 09, RUN-09, 10, 14, 15, SAVE-07, UI-15).
**G7 Cards, shop and loot grill** (8-10 decisions, right before 6B): offer rules (how often, skip, whether a card can repeat, an equipped-skill cap, exclusive upgrade branches, a bad-luck guard); the upgrade list per class (including the Nobody pool); what a chest holds now that books are gone; gold per enemy and chest, prices, merchant spots (IDE work); loot tiers per floor; the level wanted at the final boss.
**Success Criteria** (what must be TRUE):
  1. A seeded bot plays start, fight, chest, card pick, death, entrance, new run; run state is clean and the profile is kept (L3).
  2. No cutscene, camera pan or story dialogue repeats on the second run; skipping leaves the world identical (L3 + L4).
  3. Offer tests with fixed seeds: three distinct cards, no owned skill again, upgrades only for owned skills, pool counts match D18 for four classes (L2).
  4. The same seed gives the same shuffles; saving and reloading at an offer shows the same cards (L2 + L3).
  5. Buying fails with too little gold and succeeds with enough; gold, inventory and the save agree; gold is gone after death (L3).
  6. Sampling 10,000 drops shows floor 9 tiers better than floor 3; no skill book in any table (L2).
  7. A seeded simulation of a normal full run reaches the final boss at the level the owner approved (L2).
  8. Death in battle, shop, dialogue or transition always ends in the entrance room (L3).
  9. The bot measures run length; the owner plays one full run in one sitting and writes down what felt wrong (L3 + L5).
**Owner / IDE tasks**: merchant object and placement in rooms; the entrance room's markers if needed; any card or shop UI objects; sprites. All through the IDE. Possibly a spawn-marker change for enemy pools (decided by P1).
**Domain skills**: `save-systems`, `game-ui-ux`.
**grill-me needed?**: Yes: G7 (G2 and G3 were done in Phase 3).
**Plans**: TBD (expect 6-9 plans; split 6C as Phase 6.1 if needed)

### Phase 7: Balance, screens, icons
**Goal**: Skills, enemies, floors and whole runs are balanced against written targets, and the owner approves every number change. Every screen looks like one game. No placeholder icon remains.
**Depends on**: Phases 5 and 6. The three lanes below do not depend on each other and can run at the same time.
**Requirements**: BAL-03 to BAL-06; UI-03 to UI-11, UI-13 to UI-15 (styled), ART-03 to ART-06, ART-08, LOC-05, ROB-02 (UI part)
**Lane 7A Balance.** Calibrate the simulator against bot runs; write `targets.csv` (per fight and per run); find out-of-band results; write proposals with before and after numbers; the owner approves a batch; apply; re-run. **G8** (5-6 decisions): the target bands (start from `balance-methods.md` section 6.2), run win rate and run length targets, the skill-efficiency curve, QTE skill weighting.
**Lane 7B Screens.** Order: shared module in use everywhere; battle HUD and status counters; inventory and equipment; tooltips, description keys, glossary; card, shop, level-up, class pick, run-end and credits screens; settings; focus navigation pass. **G9** (5-6 decisions, not the text size rule, which is G1): battle layout, inventory design, status icon limits (max 4 plus "+N"), what the pause menu holds.
**Lane 7C Icons.** Draw the 10 status icons first (the Foresight icon is an eye, D24), then potions, then skill icons for all four classes (upgrades reuse the base icon with the "+" rule). The owner imports; code points `icon_sprite` at them; flip the text-fallback flag; delete the placeholder helpers. **G10** (3 decisions): icon size stays 16x16 or not; buff versus debuff shape rule; who does the hand finishing.
**Success Criteria** (what must be TRUE):
  1. The simulator is within the stated tolerance of a seeded bot run (L3).
  2. Every metric in `targets.csv` is inside its band, or has an owner-approved exception in the file; no skill is used 0% or dominates beyond the band (L2).
  3. Every number change since the last stable build points to an approved proposal id (review).
  4. Screenshots of every screen at the matrix sizes use only palette colours and the shared panel; English and Korean text fits (L4).
  5. A bot walks every screen with keyboard keys only; the owner repeats it on a controller (L3 + L5).
  6. The checker reports every new icon as 16x16, four colours plus transparent only; a battle screenshot with all statuses shows real icons and no text tags; the Foresight icon is an eye (L2 + L4).
  7. After import, `Status_Assign*FromFX` helpers are gone and the build, tests and smoke still pass (L1 + L2 + L3).
  8. The owner plays several runs on Normal (there is only one difficulty) and answers a short form: floor reached, where they died, per fight "too easy / right / too hard". Where the simulator and the owner disagree by more than about 10 points of win rate or 2 turns of fight length, trust the owner and look for a missing rule (L5).
**Owner / IDE tasks**: import every sprite and UI piece; set sprite properties; hand-finish icons if the owner prefers to draw (about 3-6 hours of attended work for about 40 icons, `icons-comfyui.md` section 8).
**Domain skills**: `game-ui-ux`, `create-game-assets`.
**grill-me needed?**: Yes: G8, G9, G10.
**Plans**: TBD

### Phase 8: Release
**Goal**: A friend can open a web link or a Windows zip, play the whole game in English or Korean, and nothing in the owner's last playtest blocks them. Then development stops (D28).
**Depends on**: Phases 1-7.
**Requirements**: WEB-01 to WEB-09, LOC-01, LOC-02, LOC-04, ROB-01 (and the old pointer bug BUG-26)
**Work**: HTML5 export through Igor (from the Phase 2 spike result); the namespace patch script; the hand-off zip and note for `live-miguisanson-dev`; remove the Opera GX target in the IDE; the golden-sequence test and a mid-run reload in the browser; the time-based timer conversion and a frame-throttled bot run (ROB-01); Korean batch and the missing-translation check; strip debug keys in release; Windows zip; size and load-time numbers; release-candidate playtest.
**Success Criteria** (what must be TRUE):
  1. One command produces the HTML5 export and the patch check finds the namespace string in `DD-Project.js` (L1 + L2).
  2. In a browser: start, keyboard input, sound after first click, a save and load round trip for both parts, a page reload mid-run, and the seed golden test (L3 + L4).
  3. The missing-translation check lists zero Korean gaps (L2); Korean screenshots of every screen fit (L4).
  4. Release builds have debug keys off (L2).
  5. The owner (and a friend if possible) plays a named release-candidate build: one full winning run to the credits and at least two other runs including a death, and no P1 is open in `ISSUES.md` (L5).
**Owner / IDE tasks**: remove the Opera GX target; confirm the project opens clean; run the HTML5 export in the IDE if Igor cannot.
**Domain skills**: `save-systems` (browser storage), `audio-design` (browser audio start).
**grill-me needed?**: No design decisions. The owner decides if the download size is acceptable and reviews the Korean batch.
**Plans**: TBD

## Grill-me topics (one place)

Each topic is 3-10 decisions, asked right before the item is built, each with a recommendation. "After sketch" means the sketch is played first.

| Topic | When | About |
|---|---|---|
| G0 | Phase 1 | target total skill action time (one number) |
| G1 | Phase 2 | text on the 640x576 grid, fullscreen rule, Korean legibility |
| G2 | Phase 3, after P1/P4 | run frame details (entrance room, unlocks, death gift, death line, class pick, respawns, saving, later wins, pick count) |
| G3 | Phase 3, before Phase 4 | the profile and run save contract |
| G4 | Phase 5, after P2 | QTE grade table, types, big moves, defence, assist size |
| G5 | Phase 5 | stat formulas, weapons, enemy misses, Foresight, crit, damage over time, level-ups, auto-resolve |
| G6 | Phase 5, after P3 | turn order, stun, boss resistance, enemy extra actions |
| G7 | Phase 6 | card offer rules, upgrades, chest contents, gold and prices, loot, level at final boss |
| G8 | Phase 7 | balance target bands and approvals |
| G9 | Phase 7 | battle layout, inventory, status icon limits, pause menu |
| G10 | Phase 7 | icon size, buff/debuff shape, hand finishing |

## Progress

**Execution order:** Phases 1, 2 and 3 start together after the owner's go. Then 4, then 5 and 6 (6 starts when 5A is done), then 7, then 8. Improvement mode (`IMPROVE.md`) can run between owner sessions once Phase 1 is done.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Safe-now foundations | 0/5 | Not started | - |
| 2. Display and UI kit | 0/TBD | Not started | - |
| 3. Sketches and run frame | 0/TBD | Not started | - |
| 4. Data and saves | 0/TBD | Not started | - |
| 5. Combat core | 0/TBD | Not started | - |
| 6. Runs and progression | 0/TBD | Not started | - |
| 7. Balance, screens, icons | 0/TBD | Not started | - |
| 8. Release | 0/TBD | Not started | - |

---
*Roadmap created: 2026-10-13. Restructured to 8 phases: 2026-10-14 (roguelike direction, plan review).*
