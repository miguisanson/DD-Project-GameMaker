# Roadmap: DD-Project (GameMaker)

## Overview

Milestone v2.0 "Done right" takes the game from "abandoned, unbalanced, buggy" to a release a friend can play on Windows or in a browser. The order matters. First we make the checks real (Phase 1), because the last two projects ended "very buggy" when checks did not exercise the game (`research/lessons-from-past-projects.md` section 3). Then the screen (2), the old bugs (3), the combat core (4-6), progression (7), balance (8), UI (9), art (10), and the release (11).

Rules for every phase:
- Test first. Write the failing check, watch it fail for the right reason, then build. (AGENTS.md Rule 1)
- Each phase ends with `/gsd-verify-work`, a STATE.md update, and the `REGRESSION.md` entries for the phase marked with a build id.
- Design details that are not already in `research/DECISIONS.md` are asked with grill-me in `/gsd-discuss-phase`, one decision at a time, with a recommendation. Agents never guess them.
- Anything that needs a new or renamed IDE resource (object, sprite, room, script, font) is an owner task, listed per phase below (AGENTS.md Rule 4).
- The check levels L1-L5 are defined in `REQUIREMENTS.md`.
- Improvement mode (`IMPROVE.md`) can start after Phase 1 is done. It is not a phase.

## Phases

- [ ] **Phase 1: Verification ladder** - Igor compile, `-runtests`, scenario bot, screenshots, build id, negative control, process files
- [ ] **Phase 2: Display rebuild** - one display manager, cutscene/dialogue-end screen bug, HTML5 canvas fit
- [ ] **Phase 3: Playtest bug sweep** - repro every note first, fix what survives
- [ ] **Phase 4: Combat core A** - stats, formulas, no misses, damage over time, difficulty, data export, save schema
- [ ] **Phase 5: Combat core B** - turn-order bar and stun delay
- [ ] **Phase 6: QTE** - framework, ring/bar and arrow types, telegraphed defence, feel
- [ ] **Phase 7: Progression** - card picks, upgrades, gold, shop, loot, XP curve
- [ ] **Phase 8: Balance pass** - simulator, targets, proposals, owner approval
- [ ] **Phase 9: UI kit and screens** - 9-slice, pixel font, battle HUD, inventory, tooltips, card/shop/level-up screens
- [ ] **Phase 10: Icons and art** - ComfyUI pipeline, status/skill/item icons (can start early)
- [ ] **Phase 11: Web release, Korean, release candidate** - HTML5 via Igor, namespace hook, Korean batch, RC playtest

**Splits.** Phases 1 and 7 are the biggest. They stay as single phases here, but each lists its internal waves. If `/gsd-plan-phase` finds a phase too big for the packet-size cap (about 150 changed GML lines and about 3 files per packet, `lessons` 4.2), insert a decimal phase (for example 7.1 for gold, shop and loot) instead of renumbering. Phase 10 may start any time after Phase 1 (art touches no code); its import step waits for the owner in the IDE.

## Phase Details

### Phase 1: Verification ladder
**Goal**: The project can be built, tested, played by a bot and photographed from one command, and a failing check really turns the gate red. Everything else depends on this.
**Depends on**: Nothing (first phase). Needs the Igor path verified in `research/automation-igor.md`.
**Requirements**: VER-01 to VER-16
**Waves** (planned as 4 plans):
- 1A Compile wrapper: `tools/automation/run_tests.ps1`, scratch copy on E:, exit and `Error :` parsing, negative control, real-save protection, drive guard (VER-01, 03, 04, 06, 14, 15).
- 1B `Test_Boot` and suites: hook in `obj_game_controller/Create_0.gml`, `exception_unhandled_handler`, `Test_Eq`, then one pilot suite (`Test_Suite_Math`), then Combat, Status, Inventory, Data, Save (VER-02, 05, 11, 12, 13).
- 1C Scenario modes: `-smoke`, `-bot`, `-shots`, build id stamp (VER-07 to VER-10).
- 1D Process: apply `research/AGENTS-CHANGES.md` to AGENTS.md, create the `next` branch, add a `/improve_DD-Project-GameMaker` command, wire `REGRESSION.md` to test names (VER-13, VER-16).
**Success Criteria** (what must be TRUE):
  1. One command on a clean checkout prints PASS and exits 0 in about 40 s or less (L1 + L2, `automation-igor.md` section 3.6).
  2. The negative control (a deliberately failing test) turns the gate red; removing it turns it green (L2).
  3. Mutation proof: a syntax error in a script turns the compile step red (L1); a call to a function that does not exist turns the smoke step red (L3), because Igor alone returns 0 for that (`automation-igor.md` section 2.6).
  4. A bot battle runs through key presses, ends, and the state assertions pass (L3).
  5. After a full run, the files in `%LOCALAPPDATA%\DD_Project` are unchanged (L2).
  6. The title-screen screenshot shows the build id, and the same id is in the test summary (L4).
  7. AGENTS.md is under about 220 lines, matches `AGENTS-CHANGES.md`, and its gate section names the exact command; `ISSUES.md`, `REGRESSION.md` and `PLAYTEST-QUEUE.md` exist; branch `next` exists (review).
**Owner / IDE tasks**: create one script asset `scr_test` in the IDE (about 1 minute) to hold `Test_*` code. Fallback with no owner action: put it in `scr_debug.gml` (`automation-igor.md` section 3.1). Confirm the Igor command once on the owner's machine while the IDE is open (untested together, `automation-igor.md` section 5).
**Domain skills**: none.
**grill-me needed?**: No. There are no owner-design decisions in this phase. Go straight to `/gsd-plan-phase 1`.
**Plans**: 4 plans

### Phase 2: Display rebuild
**Goal**: The picture is always the right size and never snaps, on every window size, in fullscreen, in the browser canvas, and when a cutscene or dialogue ends.
**Depends on**: Phase 1 (needs the screenshot matrix and the bot to repro the screen bug).
**Requirements**: DISP-01 to DISP-15 (and BUG-01, BUG-10, BUG-11, BUG-29)
**Order of work** (from `audit/resolution.md` section 4b):
1. **Spike first** (half a day, `research/resolution-gamemaker.md` section 8), answering these with a screenshot or a logged number: (1) Post Draw coordinates with the app surface off and Keep Aspect Ratio; (2) a GUI marker lands on the integer rectangle corners at several sizes and survives a fullscreen toggle; (3) `application_get_position()` with a manually drawn surface; (4) `window_get_width()` at 125/150 percent Windows scaling; (5) Korean text legibility at the chosen UI size; (6) Android window size at edge-to-edge (listed, not run: Android is out of scope this milestone). Add (7): can Igor build HTML5 at all.
2. **Measure** the current bug: the bot records window, display, GUI, port and camera values around a cutscene end and a dialogue end, with screenshots (settles hypotheses H1-H4).
3. **Cheap safe fixes**: keep the cutscene art until the exit fade is black (H2); window colour to black; stop calling `GameSettings_ApplyDisplay` from `Transition_Finish`; `window_center()` only when the size changed.
4. **One display manager** (`obj_display` + `scr_display`), view 0 as 160x144, app surface drawn in Post Draw at an integer scale, GUI via `Display_GuiW/H`.
5. Replace the 17 GUI-size call sites, remove the self-heal block from `obj_sfx_manager`, migrate settings.
6. HTML5 canvas fit check (first export may be by the owner in the IDE if Igor cannot do it).
**Success Criteria** (what must be TRUE):
  1. `Display_CalcLayout` returns the expected scale and offsets for every window size in `resolution-gamemaker.md` section 7.1 (L2).
  2. The screenshot matrix (all sizes in 7.1, windowed and fullscreen) passes the pixel checker: exact rectangle, black bars, no blur (L4). The checker is `tools/display/check_display.py`, run with `python -I` (`resolution-gamemaker.md` section 9.2).
  3. Bot run of "cutscene ends" and "dialogue ends" in floor 1, 5 and 9.5: before and after screenshots have the same geometry, the last cutscene image fades out, and the display-apply counter does not move during the transition (L3 + L4).
  4. Five quick fullscreen toggles end in a correct layout with no coloured bars (L3 + L4).
  5. In a browser the canvas fits at several browser sizes and stays sharp (L4).
  6. The owner walks the 4c checklist in `audit/resolution.md` once and signs off the cutscene-end and dialogue-end rows (L5).
**Owner / IDE tasks**: create `obj_display` and `scr_display`; set every room's view 0 port to 160x144; fix `rm_floor6_5` (only 144 wide) and the floor view borders; set `option_window_colour` to black. Removing the Opera GX target waits for Phase 11.
**Domain skills**: `game-ui-ux` (resolution scaling, safe areas, anchors).
**grill-me needed?**: Small. Three decisions only: (a) how text is drawn on the 640x576 grid given the windowed scales 3-5 (tension 2 in PROJECT.md); (b) fullscreen at integer scale only (research recommends it) or fit-to-window; (c) result of the Korean legibility spike.
**Plans**: TBD

### Phase 3: Playtest bug sweep
**Goal**: Every note from the friend and owner is either reproduced and fixed, or shown not to happen on the current build. No bug is fixed twice.
**Depends on**: Phase 1 (repro needs the bot), Phase 2 for screen items.
**Requirements**: BUG-04, BUG-05, BUG-06, BUG-07, BUG-08, BUG-21, BUG-24, BUG-27, LOC-03
**Rule**: if a bug lives in a system Phases 4-7 rebuild (damage over time, stun, QTE, skill books), write the repro and the `REGRESSION.md` entry now, and add only fixes that survive the rebuild. The rebuild phase must make that entry pass.
**Work**:
- Ask the friend which build they played, and the "bone" question (ISSUES I-003, I-039). Do not change code for items the friend saw on an old build until the repro runs on the current build.
- Repro each `[VERIFY FIRST]` note with the harness: skill books twice (BUG-04), mini boss moves (BUG-07), poison damage (BUG-08), `hp = 9999` placeholder (BUG-27), `SKILL_POWER_STRIKE` (BUG-24).
- Fixes that survive: shorter skill action time (the fixed 60-frame hold `COMBAT_ACTION_DELAY`, the FX speed cap `PLAYER_SKILL_FX_SPEED_MAX 1.3`, empty tail frames; `audit/combat-bugs.md` section 5); poison tick feedback (a log line, a sound, a flash; the hook is `Combat_Log`); self-buff animation on the player (finding F); hard-coded English into localization (LOC-03).
**Success Criteria** (what must be TRUE):
  1. Every `[VERIFY FIRST]` item has a recorded outcome ("reproduced on build X" or "not reproducible on build X") with the scenario that shows it (L3), and its ISSUES row is updated.
  2. Total time from skill start to the next state is at or below the owner's target for Ice Spear and Hilt Bash, measured in frames by the bot (L3), then confirmed by the owner (L5).
  3. A poison tick shows a log line, plays a sound and flashes the HP bar (L3 + L4).
  4. Self-buff effects play on the player (L4).
  5. The localization lint reports no new hard-coded English and the three known strings are gone (L2).
**Owner / IDE tasks**: trimming empty tail frames of `stun_effect`, `explosion_effect` or `bleed_effect` is a sprite edit in the IDE (owner), only if the owner wants it.
**Domain skills**: `game-feel` (hold time, tick feedback), `audio-design` (tick sound).
**grill-me needed?**: Small. One question: the target total action time for a skill (a FEEL number, `lessons` 4.5). No other design.
**Plans**: TBD

### Phase 4: Combat core A
**Goal**: The numbers underneath the fights are simple, fair and testable: four stats, no misses, damage over time that is strong but bounded, a difficulty that matters, a clean save format, and the game can export its own data.
**Depends on**: Phase 1 (tests), Phase 3 (known bugs settled).
**Requirements**: STAT-01 to STAT-13, BAL-01, SAVE-01 to SAVE-06 (and BUG-02, BUG-09, BUG-16, BUG-17, BUG-19, BUG-22, BUG-23)
**Design-heavy.** `/gsd-discuss-phase 4` must run grill-me on these open details (all listed in the research; the owner decides each):
- The exact formulas for ATK, DEF, SPD, MAG replacing the d20 modifier system, and what DEF does (today it saves 1 point at level 10, `balance-data.md` S8).
- How weapons add to skill damage (D22).
- The basic-attack grade table. D20 gives an example (Perfect 130, Good 110, OK 100, Late 70 percent); the final names and numbers are the owner's.
- Whether enemy attacks can miss or be dodged, and what Evasion, Solidify and Bloodthirsty become when skills always hit (tension 3).
- Foresight's new effect (D24) and its tooltip words.
- Where crit comes from now that LUCK is gone.
- Damage over time: fixed duration per source and the tick size and cap (today Wound bleed 75%, Fireball burn 60%, Poison 75%, each 2 base turns that become 5; `balance-data.md` section 4), how effects stack or exclude each other, how Guard interacts, what Curse becomes, and how much a defence QTE may shorten.
- The difficulty levers (HP, damage, status chance, EXP) and the Easy and Hard offsets (`balance-data.md` section 1).
- Level-up gains per class.
- The export format and the wording of the friendly old-save message.
- Verify the "one player vs one enemy" assumption (DECISIONS Notes) before Phase 5.
**Order inside the phase**: write the owner-approved formula spec, then tests from the spec (red), then refactor (use the testable seams suggested in `codebase/TESTING.md`, for example `Combat_RelevantMod`, `Combat_CritChance`), then the data export, then the save schema bump with the old-save fixture.
**Success Criteria** (what must be TRUE):
  1. All formula tests pass with expected values taken from the approved spec; a mutation (changing one constant) turns at least one red (L2).
  2. 10,000 seeded casts of every skill against every enemy show zero misses; every basic-attack grade deals at least 1 damage (L2).
  3. Every damage-over-time source has a fixed duration; with any defence-QTE result the duration is not longer than the base; the tooltip number equals the applied number (L2).
  4. Simulated Easy, Normal and Hard fights differ in win rate by the amounts the owner approved (L2).
  5. The export file exists after `-export`, and a read-back test shows the numbers equal the in-game values (L2).
  6. An old-format save fixture is rejected with the friendly message and no crash; a new save round-trips exactly (L2 + L3).
  7. Foresight's tooltip, as built from data, states its effect, duration and end rule, and the owner confirms it reads clearly (L2 + L5).
**Owner / IDE tasks**: none expected. A new script asset for the combat spec helpers is optional.
**Domain skills**: `save-systems` (schema version, atomic write, rejection of old saves).
**grill-me needed?**: Yes, for the details above.
**Plans**: TBD (expect 3-4; if the plan checker finds it too big, split off the save and export work as Phase 4.1)

### Phase 5: Combat core B
**Goal**: The player can see who acts next. Speed matters. Stun delays a target. Bosses cannot be stun-locked.
**Depends on**: Phase 4 (SPD, damage-over-time timing).
**Requirements**: TURN-01 to TURN-07 (and BUG-18, BUG-20)
**Design-heavy.** `/gsd-discuss-phase 5` must run grill-me on these open details (D19 says "detail in combat discuss"):
- How SPD turns into turn frequency (a gauge or a fixed order) and how many future turns the bar shows; ties.
- How far a stun pushes a target back.
- Stun resistance for bosses and mini-bosses: immune, a percentage, or diminishing returns. The model says stun-first combos win the final boss 93% of the time at level 10 today (`balance-data.md` S1), so this rule decides whether the combo survives.
- What the enemy "free actions" (Rampage, Fury, Blessing; `ENEMY_ACTION_CHAIN_MAX 3`) become on the bar.
- When damage-over-time ticks and status counters advance, and what a failed Run does.
- Whether the player can see the enemy's next move.
- Confirm one-versus-one, or whether the bar must handle more units.
**Success Criteria** (what must be TRUE):
  1. A long simulated fight with SPD ratio 2:1 shows about 2:1 actions within the stated tolerance (L2).
  2. After a stun hit the target's next slot moves back by the approved amount, and no extra actions are granted (L2).
  3. Repeated stuns on a boss follow the approved resistance rule (L2, then the Phase 8 simulator).
  4. The turn-order bar is on screen in battle at the supported sizes and matches the internal order frame by frame in a bot run (L3 + L4).
  5. Status counters on screen equal the rule-based counters after every action (L3).
**Owner / IDE tasks**: none expected (plain shapes for the bar; styled in Phase 9).
**Domain skills**: `game-ui-ux` (the bar), `game-feel` (stun delay feedback).
**grill-me needed?**: Yes, for the details above.
**Plans**: TBD

### Phase 6: QTE framework and types
**Goal**: Timing and arrow inputs feel fair, readable and good, and the grade always matters but never zeroes the player.
**Depends on**: Phase 4 (grade scaling rules), Phase 5 (enemy wind-up and turn flow).
**Requirements**: QTE-01 to QTE-15 (and BUG-12, BUG-25)
**Design-heavy.** `/gsd-discuss-phase 6` must run grill-me on these open details:
- The grade names, the window sizes in milliseconds and the damage or effect scale of each grade. Reference values from research, not decisions: Perfect about 40 ms and Good about 100 ms either side, wind-up 500-700 ms for attacks and 600-900 ms for defence, hit-stop 50-100 ms (`qte-design.md` section 5). Frame size is 16.7 ms at 60 fps, so a window under about 50 ms total is luck.
- Which skills get a ring or bar and which get an arrow sequence, and the sequence length (research warns about fatigue with 3-5 prompts in ordinary fights).
- Which enemy moves count as "big" or telegraphed (D7), what the defence input is, and exactly what it gives (damage cut, status shortened).
- How early presses are treated, and whether to show "too early" or "too late".
- Which assist options ship (window multiplier, auto-success with a smaller bonus, QTE off, input offset or a calibration screen).
- Feedback strength per grade, and the sound plan.
**Success Criteria** (what must be TRUE):
  1. `Qte_Judge` boundary tests pass at the exact edge of every window, early, late, with the assist multiplier and with an offset (L2).
  2. The bot hits Perfect, Good and Late on purpose through the key path and the grades match (L3).
  3. The same press time gives the same grade at normal speed and with a simulated 100 ms hitch (L2).
  4. A normal enemy hit never opens a defence QTE; a flagged big move does, with a visible telegraph (L2 + L3).
  5. The HP bar does not drop before the defence resolves (L3).
  6. Screenshots of each grade show the word, colour and effect; the result word appears within 100 ms of the press (L3 + L4).
  7. The owner plays one fight with each QTE type and answers a short checklist; "feels fair" is the gate for Phase 8 tuning (L5).
**Owner / IDE tasks**: sprites for the QTE arrow and the ring or bar (made by script or hand, imported by the owner); sound assets if new ones are wanted.
**Domain skills**: `game-feel`, `audio-design`, `game-ui-ux`.
**grill-me needed?**: Yes, for the details above.
**Plans**: TBD

### Phase 7: Progression
**Goal**: The player grows by choosing cards, earns gold, buys things, finds better loot on deeper floors, and reaches the final boss at a sensible level.
**Depends on**: Phases 4-6 (skills, stats, QTE types exist), Phase 2 (stable screen for new screens).
**Requirements**: PROG-01 to PROG-09, SAVE-07
**Waves**: 7A cards and upgrades (PROG-01 to 04); 7B gold, shop, loot and XP (PROG-05 to 08); 7C plain screens and save round trip (PROG-09, SAVE-07). If too big, 7B becomes Phase 7.1.
**Design-heavy.** `/gsd-discuss-phase 7` must run grill-me on these open details:
- Card offer rules: how often an offer happens (each chest, each level-up, both), whether a card can be offered twice, rarity, reroll, skip, what happens when the pool is empty.
- The upgrade list per class (5-8 each, D18), what each does, whether upgrades stack, and how an upgrade is shown.
- What a chest contains now that books are gone (a card, gold, gear).
- Gold per enemy and per chest, prices and stock, whether the player can sell, and where the merchants stand (safe spots between floors, D23). Safe spots need IDE work.
- Loot tiers per floor (today tier weights clamp the enemy level to 3, so floors 3 and 9 drop the same quality; `balance-data.md` S14) and potion tiers.
- The XP curve and the level the owner wants at the final boss. Today one clean pass reaches about level 8 and the boss is level 10, and regular enemies respawn after every save (`balance-data.md` section 3). D14 says some grind is intended; how much is the owner's call.
- Whether farming respawns gives full or reduced reward.
**Success Criteria** (what must be TRUE):
  1. Offer tests with fixed seeds: three distinct cards, no owned skill again, upgrades only for owned skills, pool counts match D18 (L2).
  2. Picking a card in a bot run changes the character as described, saves and loads correctly (L3).
  3. Buying fails with too little gold and succeeds with enough; gold, inventory and the save agree (L3).
  4. Sampling 10,000 drops shows floor 9 tiers better than floor 3 (L2).
  5. No skill-book item exists in loot, chest or grave tables (L2).
  6. A seeded simulation of a normal full clear reaches the level the owner approved at the final boss (L2, finished in Phase 8).
  7. The owner picks cards and uses the shop in one sitting and writes down what felt wrong (L5).
**Owner / IDE tasks**: merchant object and its placement in rooms; any card or shop UI objects; sprites. All through the IDE.
**Domain skills**: `save-systems`, `game-ui-ux`.
**grill-me needed?**: Yes, for the details above.
**Plans**: TBD

### Phase 8: Balance pass
**Goal**: Skills, enemies, floors and difficulty are balanced against written targets by a simulator that reads the game's own data, and the owner approves every number change.
**Depends on**: Phases 4-7 (all systems that affect fights exist).
**Requirements**: BAL-02 to BAL-07 (and BUG-13)
**Work**: build the Python simulator from the export (policies: basic only, greedy, good play; QTE skill: average and skilled); calibrate it against bot runs; write `targets.csv`; find out-of-band results; write proposals with before and after numbers; the owner approves a batch; apply approved changes; re-run.
**Design-heavy.** `/gsd-discuss-phase 8` must run grill-me on these open details:
- The target bands. Start from the proposal in `balance-methods.md` section 6.2 (normal fight 3-5 turns, mini-boss 6-10, boss 10-16, HP lost per normal fight 10-25%, a floor drains 60-80% of HP and MP, skill usage 5-60%) and adjust to D14 (grind): which floors expect extra levels, and how much potion and MP management should matter.
- Win-rate targets for normal fights, mini-bosses and bosses on Normal, and the gaps for Easy and Hard.
- How the skill-efficiency table should look (cost curve), and which skills may be strong in which situations.
- How average and skilled QTE play are weighted.
**Success Criteria** (what must be TRUE):
  1. The simulator reads only the export; deleting its own constants file changes nothing (L2).
  2. A seeded bot run of N fights is within the stated tolerance of the simulator's result for the same fights (L3).
  3. Every metric in `targets.csv` is inside its band, or has an owner-approved exception written in the file (L2).
  4. No skill is used 0% or dominates beyond the band in the best-policy simulation (L2).
  5. Every number change since the last stable build points to an approved proposal id (review).
  6. The owner plays floors 1-5 on Normal and answers a short form: floor reached, where they died, per fight "too easy / right / too hard" (L5). Where the simulator and the owner disagree by more than about 10 points of win rate or 2 turns of fight length, trust the owner and look for a missing rule (`balance-methods.md` section 6.5).
**Owner / IDE tasks**: none.
**Domain skills**: none.
**grill-me needed?**: Yes, for the target bands and approvals.
**Plans**: TBD

### Phase 9: UI kit and screens
**Goal**: Every screen uses one frame, one font and the four-colour palette, shows what the player needs to know, and works with keyboard or controller.
**Depends on**: Phase 2 (display and 640x576 grid), Phases 5 and 7 (the bar, card, shop and level-up screens exist in plain form), Phase 4 (final stat names).
**Requirements**: UI-01 to UI-14, ART-06, LOC-05 (and BUG-15, BUG-28)
**Order** (from `audit/ui.md` section 4 and `retro-ui.md` section 11): a short spike of the 9-slice panel and the font swap on one screen; the shared panel, row and button module; battle HUD; status icon counters; inventory and equipment; tooltips, `desc` keys and glossary; card, shop and level-up screens; class select and settings; focus navigation pass.
**Success Criteria** (what must be TRUE):
  1. Screenshots of every screen at the matrix sizes use only palette colours and the shared panel (L4; the pixel-colour check from the art checker can run on them).
  2. English and Korean screenshots of every screen show text that fits and is readable (L4).
  3. The battle HUD shows the enemy name and HP, the player's level, HP and MP, a message panel, and status icons with counters (L4).
  4. A bot walks every screen with keyboard keys only and reaches every action (L3); the owner repeats it on a controller (L5).
  5. A data test fails if any skill, item or status lacks a description key (L2).
  6. Source guard: no screen draws its own hand-placed panel any more (L2).
**Owner / IDE tasks**: import the 9-slice and UI sprites; add the pixel font resource; set the 9-slice flag on the panel sprite in the IDE (AGENTS.md Rule 4).
**Domain skills**: `game-ui-ux`, `create-game-assets` (frame, cursor, arrows).
**grill-me needed?**: Yes, for details not in DECISIONS: the final text size rule on the 640x576 grid (D8); battle layout (research gives a starting layout, `retro-ui.md` section 10); inventory design; status icon limits (max 4 plus "+N") and whether to add 8x8 compact icons (`retro-ui.md` section 11 question); what the pause menu holds; touch hit-size rules.
**Plans**: TBD

### Phase 10: Icons and art
**Goal**: Every status, skill, item and upgrade has a real 16x16 four-colour icon, and no placeholder is drawn anywhere.
**Depends on**: Phase 1 (checker script). Pipeline work and the status icons can run alongside Phases 4-9 because they touch no code. Skill and upgrade icons wait for the Phase 7 pool. Import and code changes wait for the owner in the IDE.
**Requirements**: ART-01 to ART-05, ART-07, ART-08 (and BUG-03, BUG-14)
**Work**: install the ComfyUI nodes on E: and download the Pixel Art XL LoRA (`icons-comfyui.md` section 9); run the 5-icon regression test (old versus new side by side); generate; downscale and map to the palette with a script; hand-clean each icon at 16x16; run the checker; the owner imports; code points `icon_sprite` at the new sprites; flip the text-fallback flag; delete the placeholder helpers.
**Order of icons**: the 10 status icons first (the Foresight icon is an eye, D24), then potions, then skill and upgrade icons.
**Success Criteria** (what must be TRUE):
  1. The 5-icon test is shown to the owner next to the old art and the owner picks "AI sketch then hand-finish" or "raise to 32x32" (L5).
  2. The checker reports every new icon as 16x16, four colours plus transparent only (L2).
  3. The 10 status icons exist; screenshots of a battle with all statuses show real icons and no text tags (L4).
  4. Foresight's icon is an eye; buffs and debuffs differ by shape (L4).
  5. After import, `Status_Assign*FromFX` helpers are gone and the build, tests and smoke still pass (L1 + L2 + L3).
**Owner / IDE tasks**: import every sprite; set sprite properties; hand-finish if the owner prefers to draw. Expect to redraw most 16x16 icons (`icons-comfyui.md` section 8, about 3-6 hours of attended work for about 40 icons).
**Domain skills**: `create-game-assets`.
**grill-me needed?**: Small. Icon size stays 16x16 or not; buff versus debuff shape rule; who does the hand finishing; 8x8 compact variant (`retro-ui.md` section 11).
**Plans**: TBD

### Phase 11: Web release, Korean, release candidate
**Goal**: A friend can open a web link or a Windows zip, play the whole game in English or Korean, and nothing in the owner's last playtest blocks them.
**Depends on**: Phases 2-10.
**Requirements**: WEB-01 to WEB-09, LOC-01, LOC-02, LOC-04 (and BUG-26)
**Work**: HTML5 export through Igor (from the Phase 2 spike result); the namespace patch script; the hand-off zip and note for `live-miguisanson-dev`; remove the Opera GX target in the IDE; Korean batch and the missing-translation check; strip debug keys in release; Windows zip; size and load-time numbers; release-candidate playtest.
**Success Criteria** (what must be TRUE):
  1. One command produces the HTML5 export and the patch check finds the namespace string in `DD-Project.js` (L1 + L2).
  2. In a browser: start, keyboard input, sound after first click, save and load round trip (L3 + L4).
  3. The missing-translation check lists zero Korean gaps (L2); Korean screenshots of every screen fit (L4).
  4. Release builds have debug keys off (L2).
  5. The owner (and a friend if possible) plays a named release-candidate build to the end, and no P1 is open in `ISSUES.md` (L5).
**Owner / IDE tasks**: remove the Opera GX target; confirm the project opens clean; run the HTML5 export in the IDE if Igor cannot.
**Domain skills**: `save-systems` (browser storage), `audio-design` (browser audio start).
**grill-me needed?**: No design decisions. The owner decides if the download size is acceptable and reviews the Korean batch.
**Plans**: TBD

## Progress

**Execution order:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, with 10 running alongside 4-9 where it touches no code. Improvement mode (`IMPROVE.md`) can run between owner sessions once Phase 1 is done.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Verification ladder | 0/4 | Not started | - |
| 2. Display rebuild | 0/TBD | Not started | - |
| 3. Playtest bug sweep | 0/TBD | Not started | - |
| 4. Combat core A | 0/TBD | Not started | - |
| 5. Combat core B | 0/TBD | Not started | - |
| 6. QTE | 0/TBD | Not started | - |
| 7. Progression | 0/TBD | Not started | - |
| 8. Balance pass | 0/TBD | Not started | - |
| 9. UI kit and screens | 0/TBD | Not started | - |
| 10. Icons and art | 0/TBD | Not started | - |
| 11. Web, Korean, RC | 0/TBD | Not started | - |

---
*Roadmap created: 2026-10-13*
