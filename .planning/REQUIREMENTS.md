# Requirements: DD-Project (GameMaker)

**Milestone:** v2.0 "Done right"
**Defined:** 2026-10-13
**Core Value:** A short 8-bit dungeon RPG whose fights feel fair and satisfying.

Decisions D1-D24 are in `.planning/research/DECISIONS.md` and are locked. Where a number is not given, the owner sets it in the phase's `/gsd-discuss-phase` (grill-me). No agent invents a player-facing number.

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

Rules: L5 alone is never enough for anything L1-L4 can see. A requirement may list two levels (for example "L3 + L5"); both must pass. `[VERIFY FIRST]` means research says the bug may already be fixed: write the repro, run it on the current build, and only then decide whether to fix.

## v2.0 Requirements

### VER - Verification harness (Phase 1)

- [ ] **VER-01**: `tools/automation/run_tests.ps1` builds the project with Igor from a scratch copy (VM Release, `--cache` and `--temp` on E:) and fails on a non-zero exit or any `Error :` line. *Check: L1.*
- [ ] **VER-02**: Starting the built game with `-runtests` runs every `Test_Suite_*`, prints `[TEST] PASS/FAIL` lines and a `[TEST-SUMMARY] pass= fail= errors=` line, writes `test_results.txt`, and exits with 0 only if nothing failed. *Check: L2.*
- [ ] **VER-03**: A missing result file, a missing summary line, a hang past the timeout, or a leftover game process counts as FAIL, never as a pass. *Check: L2.*
- [ ] **VER-04**: A negative control (a test that is meant to fail) makes the wrapper report red. It is run every time the wrapper script changes. *Check: L2.*
- [ ] **VER-05**: An unhandled GML error is caught by `exception_unhandled_handler`, logged as `UNHANDLED`/`CRASH`, and makes the wrapper fail. Crash detection reads the log, not the exit code, because `game_end(n)` inside the handler returns exit code 0 (`automation-igor.md` section 2.9). *Check: L2.*
- [ ] **VER-06**: Every automated run sets `LOCALAPPDATA` to a scratch folder. After a run, the files in `%LOCALAPPDATA%\DD_Project` are unchanged. *Check: L2.*
- [ ] **VER-07**: `-smoke` boots the real game and walks `rm_start`, a floor room and `rm_battle`, and fails on any runtime error. Needed because Igor does not catch unknown functions or variables. *Check: L3.*
- [ ] **VER-08**: `-bot` plays scripted battles through key presses (the same input path the player uses), with auto-perfect and auto-fail QTE variants, and asserts state (HP, flags, room, inventory), never just "no crash". *Check: L3.*
- [ ] **VER-09**: `-shots` saves screenshots (`screen_save`) of title, a floor, battle, and a menu at the window sizes the game supports, and automatic checks pass (file exists, size equals window size, not blank). Until Phase 2 the supported sizes are the three scales 3-5 (480x432, 640x576, 800x720); Phase 2 extends it to the full matrix. *Check: L4.*
- [ ] **VER-10**: A pre-build step stamps a build id (git short hash + date). The id is shown on the title screen or debug overlay, printed in `[TEST-SUMMARY]`, and used in every playtest note. *Check: L2 + L4.*
- [ ] **VER-11**: Data-integrity suite: no duplicate item or skill ids; every enemy references existing skills and loot; every loot-table id resolves; every localization key used exists; the list of placeholder status icons matches the known list. *Check: L2.*
- [ ] **VER-12**: Tests can seed the random number generator (`random_set_seed`) and the game does not call `randomize()` again in gameplay code (`codebase/CONCERNS.md`, Randomness). *Check: L2.*
- [ ] **VER-13**: Each automated `REGRESSION.md` entry maps to a named test; the wrapper prints which R-ids ran and which did not. An entry with no run on the current build counts as unchecked, not green. *Check: L2.*
- [ ] **VER-14**: One command runs the whole gate and prints only FAIL/ERROR lines, in about 40 seconds or less (target from `automation-igor.md` section 3.6). *Check: L2.*
- [ ] **VER-15**: The wrapper refuses to start if `--cache`, `--temp` or the output folder is on C:. *Check: L2.*
- [ ] **VER-16**: The `next` branch exists and the wrapper passes on it; `AGENTS.md` gate text matches `.planning/research/AGENTS-CHANGES.md`. *Check: L1 + review.*

### DISP - Display and resolution (Phase 2)

- [ ] **DISP-01**: The six unverified points in `research/resolution-gamemaker.md` section 8 are each answered with evidence (a screenshot or a logged number) in a spike note before any rebuild. A seventh point is added: can Igor build HTML5. *Check: L4.*
- [ ] **DISP-02**: One persistent display manager (`obj_display` + `scr_display`) is the only code that calls window, view, camera, surface or GUI-size functions. `obj_sfx_manager` no longer owns display. *Check: L2 (source guard) + L4.*
- [ ] **DISP-03**: `Display_CalcLayout` is a pure function; for the window sizes in `resolution-gamemaker.md` section 7.1 it returns the expected scale and offsets (largest whole-number scale that fits, centred). *Check: L2.*
- [ ] **DISP-04**: At every size in the matrix the picture is exactly `160*s x 144*s`, centred; everything outside is pure black; downsampling the picture reproduces the 1x reference (no blur). The window colour is black, not red (`options_main.yy` is 255 today). *Check: L4.*
- [ ] **DISP-05**: Fullscreen on gives the largest whole-number scale that fits; fullscreen off returns to the chosen windowed scale; five fast toggles leave no stuck size or coloured bars. *Check: L3 + L4.*
- [ ] **DISP-06**: Cutscene end: the last image fades to black (it does not vanish first), the window does not re-centre, no zoom or shift, and the first floor frame is stable. *Check: L3 + L4, then L5.*
- [ ] **DISP-07**: Dialogue end in `rm_floor1`, `rm_floor5` and `rm_floor9_5`: the camera pans back, the player is in the same screen place as before the dialogue, no jump at fade-in. *Check: L3 + L4.*
- [ ] **DISP-08**: The display is re-applied only on boot, on Settings Apply, on a real window or display size change, and on focus regain. Never on transition end, cutscene end or save load. A counter in the scenario run proves it. *Check: L3.*
- [ ] **DISP-09**: UI and text are authored on a 640x576 grid (D8) through `Display_GuiW()` / `Display_GuiH()`. The 17 `display_get_gui_*` call sites listed in `audit/resolution.md` section 1d are replaced. *Check: L4.*
- [ ] **DISP-10**: `rm_floor6_5` (144 wide) and the floor view borders are fixed in the IDE by the owner, and no area outside the room is visible. *Check: L4.*
- [ ] **DISP-11**: HTML5 build: the canvas fits the browser window at several browser sizes with the correct aspect and a sharp picture (no blur), and the game stays correct after a browser resize and after fullscreen. *Check: L4 (browser screenshots).*
- [ ] **DISP-12**: Layout uses anchors and `Display_GuiW/H` only, so odd aspect ratios (tall 600x1000, ultrawide 3440x1440) show a correct picture with black bars. Android is not tested. *Check: L4.*
- [ ] **DISP-13**: Screen shake moves the camera from a Step event with whole-pixel offsets, not from Draw GUI. *Check: L3.*
- [ ] **DISP-14**: Settings migrate `fit_screen` to a clear `fullscreen` flag, with the settings version bumped. Read the current version first; the audits disagree (`audit/resolution.md` says 6, `codebase/INTEGRATIONS.md` says 7). *Check: L2.*
- [ ] **DISP-15**: Loading a save from the title right after the intro cutscene leaves no leftover cutscene background (`audit/resolution.md` H6). *Check: L3.*

### BUG - Playtest notes and found bugs

Each friend and owner note is one line. Source text is in `research/playtest-notes.md`. Findings come from `research/audit/combat-bugs.md` (letters A-K), `ui.md`, `qte.md`, `resolution.md`, `balance-data.md` and `codebase/CONCERNS.md`.

Rule for Phase 3: if the bug lives in a system that Phases 4-7 rebuild (poison and damage over time, stun, QTE, skill books), Phase 3 writes the repro and the regression entry and adds only fixes that survive the rebuild. The rebuild phase then has to make that entry pass. This avoids fixing a thing twice.

Friend's notes:
- [ ] **BUG-01**: "scale problem. screen bug". Closed by DISP-04 to DISP-08. *Check: L4 + L5.*
- [ ] **BUG-02**: "foresight skills idk what it does". Closed by STAT-10 (clear effect, tooltip) and UI-06. *Check: L2 + L5.*
- [ ] **BUG-03**: "bone shud be foresight +". Ask the friend one question: was "bone" an icon, the floor-8 bones prop, or a skill name? D24 reads it as the icon. Closed by ART-03 (Foresight icon is an eye). *Check: L4.* [QUESTION open]
- [ ] **BUG-04**: "skill books appear in books twice". [VERIFY FIRST] Audit could not reproduce it at HEAD (`combat-bugs.md` section 4). Check: adding book 114 twice leaves one entry; a pushed duplicate shows once; the Skills tab shows no duplicate; no duplicate ids in `skills`. Final fix is D18 (books removed, PROG-04). *Check: L2.*
- [ ] **BUG-05**: "ice spear animation is slow". Verified: Ice Spear is at the speed cap (1.3) and takes 1.15 s plus a fixed 1 s hold (`combat-bugs.md` section 5). Total skill action time is reduced to the owner's target. Target number: owner, Phase 3. *Check: L3 (frame count) + L5.*
- [ ] **BUG-06**: "hilt bash animation slow". Same as BUG-05 (0.86 s plus 1 s hold; last two frames empty). *Check: L3 + L5.*
- [ ] **BUG-07**: "mini boss moves around so he isnt blocking tje way". [VERIFY FIRST] At HEAD he is stationary (`ai_stationary = true`, `combat-bugs.md` section 6). Check: open `rm_floor5`, wait 60 s, his x,y stay (224,32); approach within 4 tiles and the fight starts; after the win he stays removed. *Check: L3.*
- [ ] **BUG-08**: "i dont take dmg while being poisoned". [VERIFY FIRST] The tick exists (2-3 HP after each player action, `combat-bugs.md` section 1) but is nearly silent. Phase 3: repro passes, and a tick shows a log line, a sound and a flash. Phase 4/5 re-tests it under the new damage-over-time rules (STAT-07). *Check: L3 + L5.*
- [ ] **BUG-09**: "incease the hit rate of skills specifically a tiny bit i missed 4 to 5 consecutive horizontal slashes". Closed by STAT-04 (skills never miss, D6). Until Phase 4 the measured hit chance is 61.8-88.8% (`combat-bugs.md` section 7). *Check: L2.*

Owner's notes (2026-10-13):
- [ ] **BUG-10**: "Screen bug when a cutscene ends (also places with dialogue)". Closed by DISP-06, DISP-07, DISP-08. *Check: L3 + L4 + L5.*
- [ ] **BUG-11**: "Resolution/scaling problems in general". Closed by DISP-03 to DISP-12. *Check: L4.*
- [ ] **BUG-12**: "QTE never felt right". Closed by the QTE category. *Check: L5.*
- [ ] **BUG-13**: "Skills unbalanced against each other". Closed by BAL-05. *Check: L2 + L5.*
- [ ] **BUG-14**: "Buff/debuff icons reuse other skill icons as placeholders". Closed by ART-03 and UI-04. *Check: L4.*
- [ ] **BUG-15**: "Inventory and the rest of the UI look bad". Closed by the UI category. *Check: L4 + L5.*

Found by the audits (each needs a repro or a failing check before a fix):
- [ ] **BUG-16**: Tooltips show base status turns, not the turns the game applies (Foresight "3 turns" is really 9; Wound "2" is 5; Guard "2" is 6; `combat-bugs.md` finding C). After STAT-07 (fixed durations) tooltip text is built from the same number the game uses. *Check: L2.*
- [ ] **BUG-17**: Curse (final boss) ignores its 50% chance and the hit roll, its three damage-over-time effects cancel each other, and the log says it applied all three (finding B). *Check: L2.*
- [ ] **BUG-18**: Stun skills grant 2 free actions even when the 60% stun roll fails (finding A). Removed by TURN-03. *Check: L2.*
- [ ] **BUG-19**: Weapon accuracy never affects a player roll (finding D). Replaced by D22 (weapons add to skill damage, STAT-03). *Check: L2.*
- [ ] **BUG-20**: A failed Run does not tick statuses (finding E). Re-tested under TURN-06. *Check: L3.*
- [ ] **BUG-21**: Self-buff animations play on the enemy, not the player (finding F). *Check: L4.*
- [ ] **BUG-22**: A guarded (0-damage) enemy hit still applies its status and skips the defence QTE (finding J). Fixed by the damage-over-time rules (STAT-07). *Check: L2.*
- [ ] **BUG-23**: Basic attacks pass `1 + crit_bonus` to the crit check while skills pass `crit_bonus` (finding K). Fixed by STAT-11. *Check: L2.*
- [ ] **BUG-24**: `SKILL_POWER_STRIKE` has a macro and a loc key but no `SkillDB` record (finding H). *Check: L2.*
- [ ] **BUG-25**: The HP bar drops before the defence QTE is played and part of it is refunded afterwards, so a good defence looks like a heal (`audit/qte.md` section 2.6, inferred). Closed by QTE-11. *Check: L3.*
- [ ] **BUG-26**: Debug keys (`P`, `F5`, `F9`, `L`, `K`, `J`, `U`, `O`) are bound unconditionally; confirm they are off in release builds (`codebase/CONCERNS.md`, Security). Closed by WEB-07. *Check: L2.*
- [ ] **BUG-27**: `ch.hp = 9999; // temp` at `scr_player.gml:20` (`CONCERNS.md`). [VERIFY FIRST] Find out whether it is live. *Check: L2.*
- [ ] **BUG-28**: Level-up message still talks about "stat points" while the Stats tab is read-only (`audit/ui.md` P8, not checked in play). Replaced by UI-09. *Check: L4.*
- [ ] **BUG-29**: The cutscene art disappears before the exit fade starts (`audit/resolution.md` H2). Part of DISP-06. *Check: L4.*

### STAT - Stats, formulas, damage over time, difficulty (Phase 4)

- [ ] **STAT-01**: Stats are ATK, DEF, SPD, MAG plus HP and MP (D22). Changing each stat by a set amount changes a measurable outcome: ATK changes physical damage, DEF changes damage taken, SPD changes how often a side acts (TURN-02), MAG changes magic damage and MP. No dead stats (compare `balance-data.md` S8: LUCK, DEF, AGI, INT were near-dead). *Check: L2.*
- [ ] **STAT-02**: All damage and stat formulas are pure functions with tests whose expected values come from the owner's written formula spec, not copied from the code's output. *Check: L2.*
- [ ] **STAT-03**: Weapons add to skill damage as well as basic attacks (D22). Today skills ignore weapons (`balance-data.md` S5). *Check: L2.*
- [ ] **STAT-04**: Skills always hit (D6). A test casts every skill many times with fixed seeds against every enemy and sees zero misses. *Check: L2.*
- [ ] **STAT-05**: A basic attack never deals 0 damage at any grade (D20). *Check: L2.*
- [ ] **STAT-06**: Rules for enemy attacks on the player (can they miss or be dodged) and for the statuses built around misses (Evasion, Solidify, Bloodthirsty) are decided and tested. Solidify, which today makes player skills auto-miss, must not break D6. *Check: L2.*
- [ ] **STAT-07**: Damage over time (D21): fixed durations shown with a turn counter; the total damage is bounded; a defence QTE can shorten a status and never lengthen it; the tooltip number equals the applied number. *Check: L2.*
- [ ] **STAT-08**: Damage over time is strong against tanky enemies and weak in quick fights. The target band (share of total damage by fight length) is set by the owner; the simulator checks it. *Check: L2 (simulator).*
- [ ] **STAT-09**: A difficulty profile that matters. Today Easy and Hard barely change anything: damage multipliers are floored on small integers, and `player_stat_mult` / `enemy_stat_mult` are never read (`balance-data.md` S7). Easy, Normal and Hard give win-rate gaps inside the band the owner approves (starting proposal: Easy +10-15 points, Hard -15-20 points, from `balance-methods.md` section 6.2). Dead multipliers are used or deleted. *Check: L2 (simulator).*
- [ ] **STAT-10**: Foresight has a clear effect that is not "next skill cannot miss" (void under D6), and its tooltip states the effect, the duration and when it ends (D24). The effect is decided in the Phase 4 discuss. *Check: L2 + L5.*
- [ ] **STAT-11**: Crit has a new source now that LUCK is removed, and basic attacks and skills use the same crit rule. *Check: L2.*
- [ ] **STAT-12**: Level-up gains (HP, MP, stats per class) follow the owner-approved table. *Check: L2.*
- [ ] **STAT-13**: The game can export its own balance data (BAL-01) with the new stats. *Check: L2.*

### TURN - Turn order (Phase 5)

- [ ] **TURN-01**: A turn-order bar is visible in battle and shows who acts next and after (D19). *Check: L4.*
- [ ] **TURN-02**: SPD decides how often each side acts: over a long simulated fight, the action counts match the SPD ratio within a stated tolerance. *Check: L2.*
- [ ] **TURN-03**: Stun delays the target on the bar by an owner-set amount. No stun grants extra actions. The old `grant_extra_turns` is gone. *Check: L2.*
- [ ] **TURN-04**: Bosses and mini-bosses resist stun by an owner-set rule, so a stun-first combo cannot win the game (today the model says the Mage combo beats the final boss 93% of the time at L10, `balance-data.md` S1). *Check: L2 (simulator).*
- [ ] **TURN-05**: Enemy extra actions (Rampage, Fury, Blessing are "FREE action" today) are redefined on the bar. *Check: L2.*
- [ ] **TURN-06**: Status turn counters and damage-over-time ticks advance at one defined moment of the affected unit's turn, and the counters on screen match the rules. A failed Run also advances them as the rules say. *Check: L3.*
- [ ] **TURN-07**: Turn order does not depend on frame rate. *Check: L2.*

### QTE - Timing and input (Phase 6)

- [ ] **QTE-01**: QTE time is kept in milliseconds with a clock that caps long frames; a press is timestamped at the top of the Step that sees it; all windows are written in ms. A pure `Qte_Judge(press_ms, target_ms, table, mult, offset)` returns the grade. *Check: L2.*
- [ ] **QTE-02**: One input function (`Input_QtePressed`) serves keyboard and gamepad, with a large-hit-area tap path designed in (touch not tested; D3). *Check: L3 (keyboard through the real input path) + L5 (gamepad).*
- [ ] **QTE-03**: Results are graded (D5, D20). The grade table (names, windows, damage or effect scale) is the owner's; failing scales power down and never fully misses. *Check: L2.*
- [ ] **QTE-04**: A ring or bar timing type works (D4). The bot can hit Perfect, Good and Late on purpose and the grade matches. *Check: L3.*
- [ ] **QTE-05**: An arrow-sequence type works with arrows and WASD (D4). Wrong, late or missing inputs reduce the grade; they do not zero the skill. *Check: L3.*
- [ ] **QTE-06**: Each skill declares its QTE type and parameters in data. A data test fails if a skill has none. *Check: L2.*
- [ ] **QTE-07**: The basic attack is a free, always-landing graded QTE (D20). *Check: L3.*
- [ ] **QTE-08**: Only moves flagged big or telegraphed (bosses, mini-bosses, heavy moves) open a defence QTE (D7). Normal hits never do. *Check: L2 + L3.*
- [ ] **QTE-09**: A telegraph is visible before the strike for a wind-up the owner sets (starting idea in `qte-design.md` section 5: 600-900 ms, to be calibrated by playtest). Same move, same timing, every time; the old random per-swing speed is gone. *Check: L2 + L5.*
- [ ] **QTE-10**: A defence QTE only reduces damage and shortens statuses (D21). *Check: L2.*
- [ ] **QTE-11**: The HP bar does not drop before the defence QTE resolves. *Check: L3.*
- [ ] **QTE-12**: Feedback: each grade has its own colour, word, sound, hit-stop and shake (game-feel). The result word shows in 100 ms or less after the press (starting value, `qte-design.md` section 5). *Check: L3 + L5.*
- [ ] **QTE-13**: Assist options are stored in settings: window multiplier, auto-success with a smaller bonus, QTE off, and an input offset in ms (set from `qte-design.md` section 3; which of them ship is the owner's choice). *Check: L2 + L5.*
- [ ] **QTE-14**: A slow frame does not change the grade for the same press time (judged by the clock, not by Step count). *Check: L2.*
- [ ] **QTE-15**: Ordinary fights ask for at most one timed input per player action and none on normal enemy hits. Long arrow sequences are limited to skills the owner names (fatigue guard, `qte-design.md` principle 6). *Check: L2.*

### PROG - Progression (Phase 7)

- [ ] **PROG-01**: At each chest or level-up, the player sees 3 different cards and picks 1 (D18). The offer logic is seeded and testable: no duplicates in one offer, never offers an owned skill again, offers an upgrade only for an owned skill. *Check: L2 + L3.*
- [ ] **PROG-02**: Each class has about 5 skills and 5-8 upgrades in the pool (D18). A data test counts them. *Check: L2.*
- [ ] **PROG-03**: An upgrade changes the owned skill (for example "Ice Spear+") and the skill's description shows it. *Check: L2.*
- [ ] **PROG-04**: Random skill books are gone from loot, chests and graves; old book items are removed from the item data. *Check: L2.*
- [ ] **PROG-05**: Enemies and chests drop gold (D23). Gold is saved. *Check: L2 + L3.*
- [ ] **PROG-06**: A merchant at safe spots between floors sells potions and gear (D23). Buying fails with too little gold, succeeds with enough, and updates inventory and gold. The safe spots need IDE work by the owner. *Check: L3.*
- [ ] **PROG-07**: Loot quality improves per floor (D23). Today tier weights use the enemy level clamped to 3, so floor 3 and floor 9 drop the same quality (`balance-data.md` S14). A sampling test shows floor 9 tiers beat floor 3. *Check: L2.*
- [ ] **PROG-08**: The XP curve lets the final boss be met at a sensible level. Today one clean pass reaches about level 8 and the boss is level 10 (`balance-data.md` section 3). The target level and how much grinding is expected (D14) are the owner's. *Check: L2 (simulator).*
- [ ] **PROG-09**: Card-pick, shop and level-up screens work with keyboard and gamepad in a plain form in this phase; they are restyled in Phase 9. *Check: L3.*

### BAL - Balance simulator (Phase 4 export, Phase 8 pass)

- [ ] **BAL-01**: The game exports its own skills, enemies, classes, items, loot, statuses, difficulty profiles and progression to CSV or JSON with a flag. This export is the only source of numbers for the simulator, so there is one source of truth. *Check: L2.*
- [ ] **BAL-02**: A Python Monte Carlo simulator reads only that export and runs thousands of fights, per floor and difficulty, with three scripted player policies (basic attack only, greedy best skill, good play) and two QTE skill levels (average and skilled; `balance-methods.md` section 6.3, `balance-data.md` S6). *Check: L2.*
- [ ] **BAL-03**: The simulator is calibrated against the real game: a seeded bot run of N fights lands inside a stated tolerance of the simulator's result for the same fights. *Check: L3.*
- [ ] **BAL-04**: Target bands live in a `targets.csv` and the check fails when a metric leaves its band. The first bands are a proposal (`balance-methods.md` section 6.2: normal fight 3-5 turns, mini-boss 6-10, boss 10-16; HP lost per normal fight 10-25%; floor drains 60-80% of HP and MP; skill usage between 5% and 60%, none at 0%), adjusted to D14 (grind) and approved by the owner. *Check: L2.*
- [ ] **BAL-05**: Skills are balanced against each other: no skill is dominated or dominant outside the band (known problems: Hilt Bash and Ice Spear dominate, Horizontal Slash is dominated by Wound; `balance-data.md` S1, S3). *Check: L2 + L5.*
- [ ] **BAL-06**: Balance changes are proposals with before and after simulator numbers, kept in the "Balance proposals" section of `PLAYTEST-QUEUE.md`. No balance data file changes without an approved proposal id (D13). *Check: review + L5.*
- [ ] **BAL-07**: The simulator runs in the gate whenever balance data changes. *Check: L2.*

### UI - Screens (Phase 9)

- [ ] **UI-01**: One 9-slice panel sprite and one `UI_DrawPanel` are used by every screen. All UI colours are from the four-colour palette (no pure white or black). *Check: L4.*
- [ ] **UI-02**: A pixel font with Korean glyphs (candidate: Galmuri, OFL-1.1; `retro-ui.md` section 6), drawn without anti-aliasing. Every UI string is checked in English and Korean. Final text size rule is settled with D8. *Check: L4.*
- [ ] **UI-03**: Battle HUD shows the enemy name and HP bar, the player's level, HP and MP, a message panel, and status icons with turn counters that blink on the last turn (max 4 per combatant, then "+N"; `retro-ui.md` section 3). *Check: L4.*
- [ ] **UI-04**: Every status is drawn as an icon, never as a small text tag (the `noncore_text_fallback` flag is off) and shows its turns left. *Check: L3 + L4.*
- [ ] **UI-05**: Inventory and equipment screen: categories, an equipped section, a stat comparison before equipping, a use/equip/drop choice, gear the class cannot use is marked, held keys scroll. *Check: L3 + L4.*
- [ ] **UI-06**: Every skill, item and status has a one-line description key, shown in a tooltip, with an Info button and a glossary page (`retro-ui.md` section 4). A data test fails if one is missing. *Check: L2 + L4.*
- [ ] **UI-07**: Card-pick screen is styled and readable. *Check: L4.*
- [ ] **UI-08**: Shop screen is styled and readable. *Check: L4.*
- [ ] **UI-09**: Level-up screen shows what changed, with no stale text. *Check: L4.*
- [ ] **UI-10**: Every screen can be used with keyboard or controller only; the cursor is remembered per menu; Back is always the same. *Check: L3 + L5.*
- [ ] **UI-11**: Skills the player cannot afford are greyed out in battle; battle lists show scroll cues; the tooltip is never hidden for lack of room (`audit/ui.md` P5, P6). *Check: L4.*
- [ ] **UI-12**: One shared module for panel, list row and button replaces the duplicated hand-placed layout code (`audit/ui.md` P7). *Check: L2 (source guard) + L4.*
- [ ] **UI-13**: Class select shows class art, starting stats and a skill preview; settings volumes are bars, not text (`audit/ui.md` P8). Lower priority. *Check: L4.*
- [ ] **UI-14**: Rows are at least 16 base pixels tall and hit areas are big enough for a tap later (touch-ready; `retro-ui.md` section 7). *Check: L4.*

### ART - Icons and art (Phase 10)

- [ ] **ART-01**: The ComfyUI pipeline is reproducible: SDXL base plus the Pixel Art XL LoRA, a fixed prompt skeleton, a prompt CSV, saved seeds, a scripted palette step to the four colours, output under `E:\AI\ComfyUI\ComfyUI-Shared\output\dd_icons\` (`research/icons-comfyui.md` sections 0-1). First step is a 5-icon test: regenerate 5 existing icons and compare side by side. *Check: L4.*
- [ ] **ART-02**: No FLUX.1 [dev]-based pixel LoRA is used (non-commercial licence, `icons-comfyui.md` section 1). A model/LoRA/licence note is kept with each icon batch. *Check: review.*
- [ ] **ART-03**: 10 new 16x16 status icons exist as round badges: guard, rev_up, evasion, take_aim, foresight (an EYE), meditation, solidify, bloodthirsty, blessing, sunder (`audit/icons-needed.md` section 2). Buffs and debuffs differ by shape, not only colour (`retro-ui.md` section 3). *Check: L2 (palette and size script) + L4.*
- [ ] **ART-04**: Player skill icons, 16x16, one per skill in the final pool (14 today in `audit/icons-needed.md` section 3; the count changes with D18) and a rule for how an upgrade ("+") looks. *Check: L2 + L4.*
- [ ] **ART-05**: Item icons: HP Potion Lv2/Lv3 and MP Potion Lv2/Lv3 (4 icons, `icons-needed.md` section 4). The 3 skill-book icons in that list are dropped (D18). *Check: L2 + L4.*
- [ ] **ART-06**: UI pieces: 9-slice panel, select bar, cursor, scroll arrows, equipped mark, a pixel QTE arrow (replaces 4 `draw_line` calls), three class icons, four stat icons (ATK, DEF, SPD, MAG), turn-order bar pieces, a recoloured dialogue arrow (now pure `#ffffff`) and battle background (now `#0a2533`, outside the palette) (`icons-needed.md` section 5, updated for D22). These are mostly geometric, so they are made by script or by hand at the start of Phase 9, not with ComfyUI; the class and stat icons may use the Phase 10 pipeline. *Check: L2 + L4.*
- [ ] **ART-07**: Every icon is hand-cleaned at 16x16 (expect to redraw most; `icons-comfyui.md` section 8). A checker script confirms each file is 16x16 with only the four colours plus transparent. *Check: L2.*
- [ ] **ART-08**: The owner imports sprites through the IDE. After that, code points `icon_sprite` at them and the placeholder helper functions (`Status_AssignPlayerBuffIconsFromFX`, `Status_AssignMissingIconsFromSkillFX`) are removed. *Check: L1 + L4.*

### WEB - Release builds (Phase 11)

- [ ] **WEB-01**: The HTML5 export builds from the wrapper using Igor, with no IDE. This is unverified today (only Windows was tried); the spike is in Phase 2. *Check: L1.*
- [ ] **WEB-02**: The Opera GX target is removed in the IDE by the owner (D15). *Check: L1.*
- [ ] **WEB-03**: After each export, a script re-applies the account-namespace hook in `DD-Project.js` where `_V9._U54=_Q54()` is assigned: append `(window.__MIGUISANSON_GAME_INSTANCE__||"guest")+"."` to the prefix (`live-miguisanson-dev/games/dd-project/README.md`). A check confirms the string is present in the output. The exported `index.html` is not copied. *Check: L2.*
- [ ] **WEB-04**: The hand-off to `live-miguisanson-dev` is a zip of `html5game/` plus a short note with the exact steps from that README. This repo does not deploy. *Check: L1 + review.*
- [ ] **WEB-05**: In a browser, the game starts, takes keyboard input, plays sound after the first interaction, and a save and load round trip works. `screen_save` does not work on HTML5, so browser screenshots are taken from outside the game. *Check: L3 (browser) + L4.*
- [ ] **WEB-06**: Download size and first-load time are measured and reported (the Windows `data.win` was 78 MB, `automation-igor.md` section 2.4). The owner decides if it is acceptable. *Check: measurement.*
- [ ] **WEB-07**: Debug keys and debug overlays are off in release exports. *Check: L2.*
- [ ] **WEB-08**: A Windows zip for friends is built with Igor `PackageZip` (`automation-igor.md` section 2.4). *Check: L1.*
- [ ] **WEB-09**: A release-candidate playtest by the owner (and a friend, if possible) on a named build id has no open P1. *Check: L5.*

### LOC - Localization (Phase 3 text fixes, Phase 11 batch)

- [ ] **LOC-01**: The Korean batch is filled before release through the existing pipeline (`tools/localization/`). English stays first. *Check: L2.*
- [ ] **LOC-02**: A missing-translation check lists every key with an empty Korean value. It is informational until release and blocking at release (D9). *Check: L2.*
- [ ] **LOC-03**: The hard-coded English found by the audits goes through localization: "Game saved." (`obj_game_controller/Step_0.gml:70`), the level-up text (`scr_enemy.gml:84`), the `Equip_CanEquip` messages (`audit/ui.md` P10). `lint_hardcoded_text.py` reports nothing new. *Check: L2.*
- [ ] **LOC-04**: Every new player-facing string in new features (cards, shop, QTE words, tooltips, glossary) is added through `game_text.xlsx` and the build script. *Check: L2.*
- [ ] **LOC-05**: Korean text is readable in the chosen pixel font and fits its box on every new screen. *Check: L4.*

### SAVE - Save format (Phase 4, extended in 7)

- [ ] **SAVE-01**: Saves carry a schema version (D16). It already exists as `SAVE_SNAPSHOT_VERSION 2` and is bumped at the D22 stat change and whenever a later phase adds saved fields (`codebase/INTEGRATIONS.md`). *Check: L2.*
- [ ] **SAVE-02**: An old-format save is detected and rejected with a friendly on-screen message, no crash, and no overwrite of the old file. The old-format fixture is made by running `v1.8` in the scratch save area, never by copying the owner's real save. *Check: L2 + L3.*
- [ ] **SAVE-03**: Save then load gives an identical state (HP, MP, level, inventory, flags, room, statuses). *Check: L2.*
- [ ] **SAVE-04**: Saving writes to a temporary file and then replaces the old one, so a crash cannot leave a half-written save; a corrupt file is handled without a crash (`codebase/CONCERNS.md`, Fragile Areas). Use the `save-systems` skill. *Check: L2.*
- [ ] **SAVE-05**: `Save_ToReal` does not throw on non-numeric text. *Check: L2.*
- [ ] **SAVE-06**: Settings from older versions migrate and keep working (volumes, scale, language). *Check: L2.*
- [ ] **SAVE-07**: New data from Phases 5-7 (turn state, gold, cards, upgrades) round-trips. *Check: L2.*

## Later (not in v2.0)

- Android build, touch controls testing, safe-area handling (D3).
- Bestiary and enemy-skill icons (the 13 optional enemy icons in `audit/icons-needed.md` section 3).
- A calibration screen for input latency if the owner wants it (`qte-design.md` section 3).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Android testing and release | D3: later; design must not block it |
| Porting to other engines or platforms | D1: parked |
| GX.games / Opera GX | D15: own site instead |
| Old save compatibility | D16: clean break |
| New floors, story or classes | D1: same game done right |
| Store and legal work | D2: free release |
| Deploying the website | D15: other repo's job |

## Traceability

Each requirement maps to one primary phase. Where a later phase repeats or re-tests it, the roadmap says so.

| Requirement | Phase | Status |
|-------------|-------|--------|
| VER-01 to VER-16 | Phase 1 | Pending |
| DISP-01 to DISP-15 | Phase 2 | Pending |
| BUG-01, BUG-10, BUG-11, BUG-29 | Phase 2 | Pending |
| BUG-04, BUG-05, BUG-06, BUG-07, BUG-08, BUG-21, BUG-24, BUG-27 | Phase 3 | Pending |
| LOC-03 | Phase 3 | Pending |
| BUG-02, BUG-09, BUG-16, BUG-17, BUG-19, BUG-22, BUG-23 | Phase 4 | Pending |
| STAT-01 to STAT-13 | Phase 4 | Pending |
| BAL-01 | Phase 4 | Pending |
| SAVE-01 to SAVE-06 | Phase 4 | Pending |
| BUG-18, BUG-20, TURN-01 to TURN-07 | Phase 5 | Pending |
| BUG-12, BUG-25, QTE-01 to QTE-15 | Phase 6 | Pending |
| PROG-01 to PROG-09, SAVE-07 | Phase 7 | Pending |
| BUG-13, BAL-02 to BAL-07 | Phase 8 | Pending |
| BUG-15, BUG-28, UI-01 to UI-14, ART-06, LOC-05 | Phase 9 | Pending |
| BUG-03, BUG-14, ART-01 to ART-05, ART-07, ART-08 | Phase 10 | Pending |
| BUG-26, WEB-01 to WEB-09, LOC-01, LOC-02, LOC-04 | Phase 11 | Pending |

**Coverage:**
- Requirement groups: 13 categories, 16 VER + 15 DISP + 29 BUG + 13 STAT + 7 TURN + 15 QTE + 9 PROG + 7 BAL + 14 UI + 8 ART + 9 WEB + 5 LOC + 7 SAVE = 154 requirements
- Mapped to phases: 154
- Unmapped: 0

---
*Requirements defined: 2026-10-13*
*Last updated: 2026-10-13 after the planning set was written*
