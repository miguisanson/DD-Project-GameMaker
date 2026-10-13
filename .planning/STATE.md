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
| WIP | 1E old bugs, landing on branch `next`: p1e-battle (worktree ../DD-Project-GameMaker-wt/p1ea: action time D55, poison feedback, self-buff anim) + p1e-save (worktree ../DD-Project-GameMaker-wt/p1eb: atomic save, 9999 temp, mini boss check, LOC-03). Then: QTE + turn-bar sketch on top, then first playtest stop. |
| Unplayed features | 0 / 15 |
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

## Learned, not obvious from code

- **Display step B (worktree ../DD-Project-GameMaker-wt/dispb, branch `disp-b`, 2026-10-14, not merged):** `scr_display.gml` is now the only owner of window / surface / GUI / view / camera size (`tools/display/lint_display_calls.py` guards it in the gate). It runs from `obj_game_controller` Create (`Display_Init`, `Display_BindRoom`), `obj_ui_controller` Step (`Display_Update`) and the top of every Draw GUI event (`Display_DrawFrame`, once per frame); when `obj_display` gets events (IDE) move those three calls there. The display is re-laid-out only on boot, frame 30, Settings Apply and a real window change (`global.display.apply_count`; smoke and shots assert it stays flat over room changes, a transition, a cutscene end, a dialogue end). `GameSettings_ApplyDisplay`, `Display_CalcLayoutLegacy`, the `obj_sfx_manager` self-heal and the `Transition_Finish` re-apply are gone. H2 fixed: the cutscene picture stays until the exit fade is black (`Cutscene_ClearUiState`). Text scale is now the integer rule (1.0 / 1.5 / 2.0 at 3x / 4x / 5x, was 1.2 / 1.6 / 2.0): owner look-check at L5, Korean not yet at final pixels. NOT done (step B4): `fit_screen` -> `fullscreen` (settings_version 8), `rm_floor6_5` clamp, DISP-13 shake out of Draw GUI, fullscreen shots. Real fullscreen was never entered in any run.
- **An open GameMaker IDE overwrites .gml files with its stale in-memory copy** (2026-10-14: it reverted scr_test.gml to the placeholder on close). The owner keeps the IDE closed while agents work; before merging, check `git status` is clean.

- **fx-fix packet (worktree ../DD-Project-GameMaker-wt/fx, branch `fx-fix`, 2026-10-14):** every player skill animation now plays in at most `PLAYER_SKILL_FX_MAX_FRAMES` (42) game frames and is drawn by `FX_ScaleFor` at most `FX_TARGET_FIT` (1.5) x its target and `FX_MAX_DRAW_PX` (64). An effect's `image_speed` is a multiple of the sprite's own 8 fps, so a 10-frame buff at the old 0.6 took 125 frames. The bot casts all 14 skills (about 105 s; its wrapper timeout is 300 s) and `-shots` saves `shot_fx_<skill>.png` (23 shots, timeout 120 s). New regression entries R-049 to R-055.
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
