# STATE — DD-Project-GameMaker

## Current Position (2026-10-13)

**Phase:** 0 — Audit, research and direction (no game code changes yet).
Owner wants building to start after their usage reset (~2026-10-14 afternoon).

**In progress (this session, Opus orchestrating):**
- GSD onboarding: codebase map → `.planning/codebase/` (4 gsd-codebase-mapper agents).
- Audits → `.planning/research/audit/*.md` (sonnet agents, read-only).
- Web research → `.planning/research/*.md` (sonnet agents).
- Then: grill-me with owner on direction → PROJECT.md / REQUIREMENTS.md / ROADMAP.md.

**Owner's goals (raw, 2026-10-13):** game was abandoned as unbalanced, QTE unsatisfying,
resolution/scaling bugs (incl. screen bug when a cutscene/dialogue ends), inventory and
UI visually poor, buff/debuff icons are placeholder copies of skill icons (wants ComfyUI-made
icons). Wants: careful GSD + grill-me process, Sonnet workers + Opus reviewer, and a
repeatable "improvement mode" that keeps catching bugs. Fix this game; porting is parked.
Friend's playtest notes: `.planning/research/playtest-notes.md`.

**Learned, not obvious from code:**
- Igor (headless build CLI) now EXISTS: `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\Igor.exe`.
  AGENTS.md "Traps"/"The gate" still say it doesn't — being verified in `research/automation-igor.md`;
  update AGENTS.md once proven.
- `v1.8` contains every commit of 1.5_Porting / 1.6_Dangerous-Porting / v1.7 (they are 0 ahead).
  `main` is behind v1.8 except two merge commits.

**Next action:** wait for agents, review their reports, then grill-me.
