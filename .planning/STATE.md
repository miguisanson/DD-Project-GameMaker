---
gsd_state_version: '1.0'
milestone: v2.0
milestone_name: Done right
status: planning
progress:
  total_phases: 11
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# STATE: DD-Project-GameMaker

## Header (update on every step that lands)

| Field | Value |
|---|---|
| Build id | none yet (Phase 1 adds the build id stamp) |
| Working branch | `v1.9` (cut from `v1.8` 2026-10-13; game code identical to `0b6e2f8`, which the audits cite). Unattended work goes on `next` (`IMPROVE.md`). |
| Last stable build | `v1.9` @ its first commit (planning docs only) |
| Regressions since last stable build | 0 |
| Open P1s | 0 (none confirmed; see `ISSUES.md`) |
| WIP | none |
| Unplayed features | 0 / 8 |
| Regression list | never run (`REGRESSION.md`) |

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-10-13)

**Core value:** A short 8-bit dungeon RPG whose fights feel fair and satisfying.
**Current focus:** Milestone v2.0 "Done right", Phase 1 (Verification ladder).

## Current Position

**Phase:** 0 (audit, research, direction) is complete. Phase 1 has not started.
**Status:** The planning set is written. No game code has been changed.
**Last activity:** 2026-10-13: planning set written (PROJECT, REQUIREMENTS, ROADMAP, IMPROVE, REGRESSION, ISSUES, PLAYTEST-QUEUE, research/SUMMARY, research/AGENTS-CHANGES).

**Next action:** Phase 1, after the owner's usage reset (about 2026-10-14). Phase 1 has no owner-design decisions, so go straight to `/gsd-plan-phase 1` (or `/gsd-discuss-phase 1` if you want to talk it through first). First step of the plan: the compile wrapper and its negative control. The main session also applies `research/AGENTS-CHANGES.md` to AGENTS.md (wave 1D).

**Owner task waiting for Phase 1:** create one script asset `scr_test` in the IDE (about 1 minute). Fallback if the owner is away: put the tests in `scr_debug.gml`.

**Progress:** [░░░░░░░░░░] 0% (0 of 11 phases)

## Planning set (read in this order)

1. `research/DECISIONS.md`: owner decisions D1-D24, locked.
2. `PROJECT.md`, `REQUIREMENTS.md` (154 requirements, check levels L1-L5), `ROADMAP.md` (11 phases).
3. `IMPROVE.md`, `REGRESSION.md`, `ISSUES.md`, `PLAYTEST-QUEUE.md`: the improvement-mode process.
4. `research/SUMMARY.md`: index of every research and audit file. `research/AGENTS-CHANGES.md`: proposed AGENTS.md text.

## Learned, not obvious from code

- **Igor works.** The headless build CLI exists at `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\Igor.exe`. A compile took about 9-13 s; the built game ran and its output was captured (`research/automation-igor.md`). AGENTS.md "Traps" and "The gate" still say it does not exist; they are updated in Phase 1 (wave 1D).
- **Igor catches syntax errors but not unknown functions** (exit 0). Only a run catches those (`automation-igor.md` section 2.6). `game_end(n)` inside the unhandled-error handler returns exit code 0, so detect crashes from the log.
- **`v1.8` contains every commit of `1.5_Porting`, `1.6_Dangerous-Porting` and `v1.7`** (they are 0 ahead). `main` is behind `v1.8` except two merge commits.
- **C: was 71 GB free on 2026-10-13**, below the 80-90 GB rule. Igor and the game wrote only small files on C:; everything large went to E:. Always pass `--cache` and `--temp` on E:.
- **The friend probably played an old build.** Skill books twice, the moving mini boss and the missing poison damage look fixed since `f39236b` (2026-03-05) (`audit/combat-bugs.md`). Ask which build before changing code (ISSUES I-039).
- **Real saves live in `%LOCALAPPDATA%\DD_Project`.** Automation must redirect `LOCALAPPDATA`. Never print `%APPDATA%\GameMakerStudio2\um.json` (live tokens).
- **Planning files** are all committed and pushed on `v1.8` and `v1.9` (owner asked 2026-10-13).
- **Tensions between decisions and research** are listed in `PROJECT.md` under Key Decisions (D6 vs D20; D8 vs pixel-font advice; D24 vs D6; D18 and D22 vs the icon list; D21 vs current QTE).

## Accumulated Context

### Decisions

Locked in `research/DECISIONS.md` (D1-D24). Summary table in `PROJECT.md`. Process decisions made in this plan, for the owner to confirm: Phase order as listed; `next` branch for unattended work; the bug-hunt cap of 5 findings per pass (`IMPROVE.md`); ART-06 geometric UI pieces move to Phase 9.

### Pending Todos

- Ask the friend which build they played (I-039). "Bone" is answered: Foresight is confusing and its icon looks like a bone; it should be an eye (D24).
- Run Phase 1.
- Settle the D8 text-size rule (Phase 2 and Phase 9 grill-me).

### Blockers / Concerns

- The owner's usage allowance resets about 2026-10-14. Do not start building before then.
- Igor and the IDE running together is untested (`automation-igor.md` section 5).
- HTML5 and Android builds through Igor are untested; the Phase 2 spike checks HTML5.
- Several balance findings are model results, never run in the game (`balance-data.md` tags [model]).

## Deferred Items

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| Platform | Android build and tests | Later (D3) | 2026-10-13 | after v2.0 |
| Content | Enemy-skill icons, bestiary | Later | 2026-10-13 | after v2.0 |
| Option | QTE calibration screen | Owner decides in Phase 6 | 2026-10-13 | v2.0 or later |

## Session Continuity

Last session: 2026-10-13
Stopped at: planning set written; waiting for the owner's usage reset.
Resume file: None. Start with `/continue_DD-Project-GameMaker`.
