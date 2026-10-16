---
gsd_state_version: '1.0'
milestone: v2.0
milestone_name: Done right (replayable roguelike)
status: planning
progress:
  total_phases: 8
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# STATE: DD-Project-GameMaker

**Owner: read `.planning/BOARD.md` first.** It is the only tracker you need. This file is for agents.

## Header (update on every step that lands)

| Field | Value |
|---|---|
| Build id | stamped per gate run (`<hash>-<date>`), shown bottom-right of the title screen |
| Working branch | `v1.9` (cut from `v1.8` 2026-10-13; game code identical to `0b6e2f8`, which the audits cite). Unattended work goes on `next` (`IMPROVE.md`). |
| Last stable build | `v1.9` @ its first commit (planning docs only) |
| Regressions since last stable build | 0 |
| Open P1s | 0 (none confirmed; see `ISSUES.md`) |
| WIP | RESUMED 2026-10-17 on the owner's round-3 playtest notes (29 items, I-077..I-105; decisions D174-D183). review7 merged into next (844d98b, R-085..088). Batch 1 in flight off next@844d98b (worktrees wt/light, wt/bvis, wt/cards, wt/menus; briefs E:\Temp\dd-briefs\*.md): OWNER CAP 2 AGENTS (2026-10-17, another game runs in parallel): light (notes 1,2,18) and bvis (5,23,8) PAUSED mid-implementation (check commit done, uncommitted edits in their worktrees; resume the same agents) and the VIG/MND balance-proposal agent paused (no output yet); running: cards = 11,10,28 (+D168, replaces wt/d168); menus = 9,21,25. Queued briefs: E:\Temp\dd-briefs\saves1.md, stealth.md, guard_small.md. DONE: cards merged into next b2b56ac, menus d4a2de4 (full gate PASS each), light 08bec7d, bvis (shots chain 803 -> 1010..1013 -> 1030..1033 end; 319 shots), saves1 = D175 data layer (full PASS), textfit2 4035787 (full gate: ONE shots check red = battle details panel covers the enemy at 800x720, integration of bvis ground line + textfit2 taller rows; fix packet fixdet brief E:\Temp\dd-briefsixdet.md is running; it also fixes the stealth pictures being covered by an owed level-up screen and the gold box overlapping the level-up title (R-109)). stealth merged (D179; cone tinted UI_C_DARK because LIGHTEST changed no pixels on pale floors; 339 shots). Smoke chain now 987 -> 1040..1045 (r3menus) -> 1000..1004 (r3light, end). Shots 309. Leftover for a later packet: Skills tab + battle skill list rows for Horizontal Slash / Poison Arrow still need two lines (4 TextFit_Known entries). QUEUE (2 agents at a time, start the next when one finishes): [running: saves2, guardsmall; fixdet merged befb819] next: rarity.md, mouse.md, levelup.md, audio.md (all briefs in E:\Temp\dd-briefs), then (brief written: Skills tab/battle list names, Controls label, header strip restyle), saves1, audio search (D169/D172), stealth, guardsmall, saves2 (title UI for D175), rarity (D178), mouse (D182), levelup (D176/D177/D184: resume the balance agent to SET numbers, then implement), then D185 ideas 07, 03, 21, 25 (IDEA-12 needs grill), then full gate + playtest build. Batch 2 (after batch 1 merges): D175 profiles+3 save files, D179 stealth, D178 rarity, D180 guard, D182 mouse, D177 level-up order+screen, small fixes (17 wolf flag flush, 26 death title, 20 shop dims full rows). D176 VIG/MND waits for an owner-approved balance proposal. |
| Unplayed features | 61 playtest entries (PLAYTEST-QUEUE, build dbc678a-20261015) |
| Regression list | never run (`REGRESSION.md`, 48 entries) |
| Drive C: free | 80 GB (after cleanup, 2026-10-14; rule is 80-90 GB or more) |

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-10-14)

**Core value:** A short 8-bit dungeon RPG you can replay: every run is a fair, satisfying 45-60 minute climb.
**Current focus:** Milestone v2.0 "Done right", now a roguelike-style game (D25-D36). No game code changed yet.

## Current Position

**Phase:** 0 (audit, research, direction) is complete. Planning was **revised 2026-10-14 for the roguelike direction** (D25-D36 added, plan review applied). Phases 1-3 have not started.
**Status:** The planning set is rewritten: 157 requirements (159 before D52), 8 phases, `BOARD.md` added. No game code has been changed.
**Last activity:** 2026-10-14 (later): D52 applied (Windows only, no web/HTML5 build; D15 and D50 superseded, D39 amended): WEB became REL, 157 requirements. Earlier the same day: PROJECT, REQUIREMENTS, ROADMAP, BOARD (new), ISSUES, REGRESSION, IMPROVE, STATE and research/SUMMARY updated.

**Next action:** After the owner's go, start the "safe to start now" items together (they share no files):
1. Phase 1: the compile wrapper and its negative control, then the test suites, bot and screenshots; then the old-bug repros and safe save writes. Also apply `research/AGENTS-CHANGES.md` to AGENTS.md (wave 1D). Go straight to `/gsd-plan-phase 1`.
2. Phase 3 sketches P1 (run loop) first, in a scratch copy `E:\Temp\dd-spike-<name>` (throwaway, never merged; `LOCALAPPDATA` redirected; builds on E:). The owner plays each for about 10 minutes.
3. Phase 2 display spike and measurements (needs Phase 1 waves 1A-1C for the screenshot bot).
Do not start Phase 4 until the G3 save contract is written. Do not start any combat or card code before its grill-me topic (`ROADMAP.md`, "Grill-me topics").

**Owner tasks waiting:** create script asset `scr_test` in the IDE (1 minute; fallback `scr_debug.gml`); send sound/music creator names for the credits; ask the friend which build they played (I-039); later, the Phase 2 IDE tasks listed on `BOARD.md`. Open question: D3 (Android later) vs D28 (no post-release) (I-046).

**Progress:** [░░░░░░░░░░] 0% (0 of 8 phases)

## Planning set (read in this order)

1. `BOARD.md`: the owner's one-page tracker (Now / Next / Later / Done / Waiting on you).
2. `research/DECISIONS.md`: owner decisions, locked (D1-D52; D52 = Windows only, 2026-10-14).
3. `PROJECT.md`, `REQUIREMENTS.md` (157 requirements, check levels L1-L5, two gates), `ROADMAP.md` (8 phases, grill topics G0-G10).
4. `IMPROVE.md`, `REGRESSION.md`, `ISSUES.md`, `PLAYTEST-QUEUE.md`: the improvement-mode process.
5. `research/SUMMARY.md`: index of every research and audit file, including `roguelike-design.md`, `roguelike-cases.md` and `plan-review.md`. `research/AGENTS-CHANGES.md`: proposed AGENTS.md text.

## Numbers to review (agent-chosen starting values; owner approves after playing)

- QTE bar (sweep / perfect / good / ok half-widths, ms): sword 1100/60/120/200, bow 850/60/130/220, staff 1200/55/115/190 (dagger 750, heavy 1500 unused). Grades 1.30/1.10/1.00/0.75; round-half-up, min change 1.
- Arrows: 3 (3.4 s, Perfect <=1.5 s) Wound DRU, Muscle Up UDU, Rev Up LUR, Evasion LDL, Take Aim RUR, Meditation DDU, Foresight ULD; 4 (4.2 s, <=1.95 s) Hilt Bash DLRU, Poison Arrow RRDL, Poison Mist LDRD, Fireball URDL; 5 (5.0 s, <=2.4 s) Horizontal Slash LRLRD, Double Shot RURDR, Ice Spear UDLDU. Wrong press -250 ms.
- Defence: 400 ms telegraph; damage taken 25/50/75/100 %; status kept 0/half/3-4/full. Bite 800/55, Ghost Cut 750/50, Poison Fangs 900/55, Scorching Touch 1000/55, Vine Trap 1300/60, Ramming 1500/50.
- Map AI: sight 3-5 tiles; chase speed slime .7, spider/snake/whisp/ghost .85, plant .8, stranger .9, wolf 1.0; search 90 frames. Player: turn 6 frames, buffer 10, run 2 px/frame (Shift / shoulders).
- Text scale 1.0/1.5/2.0 at window scale 3/4/5.

## Learned, not obvious from code

- **Overnight merges 2026-10-16/17**: when branches append tests at the same place, git interleaves functions; resolve by taking next's file and re-applying the branch's own diff (the appended block from its diff hunk line number, plus the registration line). Renumber a branch's scenario steps when its range is taken (H8a 810->850, H8b 850->920). Chain each new smoke packet BEFORE the final death/summary steps (a run on the map must exist). Timing checks must use frames or the game's own clocks, not wall-clock ms (parallel gates drop fps). A gate WorkRoot must contain "dd-gate" and be an absolute Windows path (a relative one created a cache folder inside the repo). A fresh WorkRoot needs >300 s for its first build (audio conversion): reuse a warm one for builds. In Git Bash heredocs a backslash pair reaches python as one backslash: write python fixes that contain Windows paths to a file.

- **Merging 4 parallel packets** (2026-10-16): conflicts land at the END of scr_test.gml (suites appended side by side), in Test_RunAll, in the smoke/shots chains in scr_debug.gml (each packet hooks the "last step") and on `Shots =` in run_tests.ps1 (sum the added shots). After resolving: grep for leftover `^(<<<<<<<|=======|>>>>>>>)` lines and run a brace-balance check on scr_test.gml BEFORE committing (a missed marker broke the build once). Workbook: take next's xlsx, apply the branch's rows that differ from the merge base with openpyxl, rebuild localization.json.

- **Owner import 2026-10-16** (d866147): GameMaker named the sprites after their files (status_strip ... skill_up_strip, spr_merchant_idle_strip, card_frame); the code accepts both names (Icon_StripSprite, Merchant_SpriteName). card_frame is unused (frames are code-drawn). The owner opens the `next` worktree in GameMaker; pause merges into next while it is open.

- **D123 as chosen doubles elites** (R1-sim, 2026-10-15): per-floor elites with "at least 1 from floor 2" = ~6.3 elites/run vs ~2.8 with the old 15% roll; sim win rate average profile Knight 94->88, Archer 96->92, Mage 87->84, Nobody 26->25; gold/run +7-10%. Kept as the owner chose; flagged in PLAYTEST-QUEUE balance entry. Fallback if too hard: drop the minimum of 1.

- **Test runs still take focus**: the game window becomes foreground ~273 ms after a minimized launch (display spike). Never run window modes while the owner uses the PC until fixed (I-053).
- **Owner IDE tasks for the next stop**: add Create/Begin Step/Draw GUI events to obj_display (then move display logic from obj_ui_controller); options: window colour black, Windows scaling -1, allow window resize (DISP-11).

- **An open GameMaker IDE overwrites .gml files with its stale in-memory copy** (2026-10-14: it reverted scr_test.gml to the placeholder on close). The owner keeps the IDE closed while agents work; before merging, check `git status` is clean.

- **Igor works.** The headless build CLI exists at `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\Igor.exe`. A compile took about 9-13 s; the built game ran and its output was captured (`research/automation-igor.md`). AGENTS.md "Traps" and "The gate" still say it does not exist; they are updated in Phase 1 (wave 1D).
- **Igor catches syntax errors but not unknown functions** (exit 0). Only a run catches those (`automation-igor.md` section 2.6). `game_end(n)` inside the unhandled-error handler returns exit code 0, so detect crashes from the log.
- **`v1.8` contains every commit of `1.5_Porting`, `1.6_Dangerous-Porting` and `v1.7`**. `main` is behind `v1.8` except two merge commits.
- **Drive C:** 71 GB free on 2026-10-13, about 80 GB after cleanup on 2026-10-14. Igor and the game wrote only small files on C:. Always pass `--cache` and `--temp` on E:.
- **The friend probably played an old build.** Skill books twice, the moving mini boss and the missing poison damage look fixed since `f39236b` (2026-03-05) (`audit/combat-bugs.md`). Ask which build; if no answer comes, the repros on the current build are the answer.
- **Real saves live in `%LOCALAPPDATA%\DD_Project`.** Automation must redirect `LOCALAPPDATA`. Never print `%APPDATA%\GameMakerStudio2\um.json` (live tokens).
- **Code facts checked on 2026-10-14** (plan review): `settings_version` is 7; there are 18 GUI-size call pairs (not 17); `randomize()` is called once, in `scr_player.gml:1530`; death reloads the latest save slot (`obj_start_controller/Step_0.gml`, case `game_over`); `Save_Write` respawns enemies (`scr_save.gml:394`); there are no credits in the code.
- **Roguelike research:** option A (existing floors, shuffled content) was chosen (D25). Seeds use the game's own counter-based streams, not `random_set_seed`, and avoid 64-bit/sign-dependent bit operations (kept simple on purpose; `roguelike-cases.md` section 4). No mature GML card/run library exists; the run manager is written here, borrowing ideas only from MIT/CC0 sources (GPL/AGPL code is read, never copied).
- **Tensions between decisions and research** are listed in `PROJECT.md` under Key Decisions (D6 vs D20; D8 vs pixel-font advice; D24 vs D6; D18 and D22 vs the icon list; D21 vs current QTE; D3 vs D28; D18 pool size vs replay).
- **GSD config:** `.planning/config.json` has `human_verify_mode: "end-of-phase"`, which sits badly with D12 (owner checks per feature). Not changed here; the main session should relax it.

## Accumulated Context

### Decisions

Locked in `research/DECISIONS.md` (D1-D36). Summary table in `PROJECT.md`. Process decisions made in this plan, for the owner to confirm: the 8-phase order; prototype first for feel and the run loop; grill-me per topic just before building (G0-G10), not up front; `BOARD.md` as the owner's tracker; two gates (fast and full); data in JSON shared with the simulator; the simulator comes with the combat core; `next` branch for unattended work; the bug-hunt cap of 5 findings per pass (`IMPROVE.md`); the cut order in `REQUIREMENTS.md`.

### Pending Todos

- Ask the friend which build they played (I-039). "Bone" is answered by D24: Foresight's icon should be an eye.
- Run Phases 1, 2 and 3 in parallel after the owner's go.
- G1 (D8 text rule) is decided once, in Phase 2.
- G3 (save contract) must finish before Phase 4.

### Blockers / Concerns

- Igor and the IDE running together is untested (`automation-igor.md` section 5).
- Several balance findings are model results, never run in the game (`balance-data.md` tags [model]).
- Card pools of about 5 skills + 5-8 upgrades per class may make runs look alike (PROJECT.md tension 8); G7 decides the rules that keep picks meaningful.

## Deferred Items

None are deferred to "later" any more: D28 says there is no post-release. Items that used to be deferred are listed under "Not built, ever" in `REQUIREMENTS.md` (Android, bestiary and enemy-skill icons, QTE calibration screen, post-win ladder, daily seeds, node map).

## Session Continuity

Last session: 2026-10-14
Stopped at: planning set rewritten for the roguelike direction; waiting for the owner's go.
Resume file: None. Start with `/continue_DD-Project-GameMaker`, then read `BOARD.md`.
