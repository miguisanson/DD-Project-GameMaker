# Resume here (written 2026-10-15, end of session 3 — owner moved to a new session)

Start with `/continue_DD-Project-GameMaker`, then read this file, `BOARD.md`, `BUILD-PLAN.md`.
Spec = `research/DECISIONS.md` (D1-D116). Work lands on branch `next`; docs live on `v1.9`.
Ask the owner "is it OK to run builds/tests now?" before running anything if they may be gaming.

## Where things stand
- **All feature packets are merged into `next`** (head e1a322d): A1, A2, B1-B4, C1-C5, D0, D1a, D1b, D2 (+v2 icons,
  art-final), D3 text pass, E1 simulator, bal-apply (D111/D112), sfx-variety (D116), fix-foresight.
- No worktrees left. Main checkout on `v1.9`. Nothing running.
- **The last merge (d1b-menus → next, e1a322d) has NOT had a full gate run yet** (stopped when the owner paused).
  d1b's own branch passed full gate + negative control before merging and already contained the D3 text pass.
  FIRST STEP: run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/automation/run_tests.ps1 -Mode full
  -WorkRoot E:\Temp\dd-gate-next` on `next` (≈12-15 min) and open a few `shot_tabmenu_*` PNGs.

## Left to do (in order)
1. **Full gate on next** (above). Fix anything red.
2. **F1 optimisation + consistency pass (D108)** — one Sonnet packet in a worktree from `next`: frame-time probe in the
   bot (before/after), per-frame work/allocations, draw calls, room load time; dead/duplicated code (incl. the dead
   `SaveMenu_*` slot code in scr_save_menu.gml — convert its remaining notice popup to the framework), remaining
   frame-counted timers → ms, global sprawl; consistent controls/wording/colours/sounds/naming. Every check stays green;
   no balance numbers change (D13).
3. **E2 playtest build**: full gate + REGRESSION.md run; copy `E:\Temp\dd-gate-next\out\` (exe, data.win, options.ini,
   fonts, localization, ttf) to `E:\Games\DD-Project Playtest\<build id>\`; back up the owner's saves
   (`%LOCALAPPDATA%\DD_Project`) beside it; write ONE big `.planning/PLAYTEST-QUEUE.md` covering everything built since
   playtest 1 (runs/death/echo, chests/cards/level-up, turn timeline/stagger/BREAK, statuses, enemy AI/boss phases,
   merchant/shop/gold/throwables/elites, beds/tutorial/settings/controls/prompts, Tab menu/codex/pause, death scene/lore/
   credits, window modes, balance feel, monster sounds) + BOARD "PLAYTEST NOW".
4. **Owner IDE import (one session, ~15 min)** — combined list: `art/IMPORT-CHECKLIST.md` (icon strips v2 + merchant A +
   card frame) and `art/sfx_new/IMPORT.md` (30 CC0 monster takes). Code already falls back until imported (D94).
5. Sound/music creator names from the owner for the credits (very last, D40/D105).

## Notes / known follow-ups
- Merge lessons: one scenario step range per packet (BUILD-PLAN.md); agents `git merge next` before reporting;
  workbook conflicts: take next's game_text.xlsx, re-add rows with openpyxl, rebuild localization.json; ko-check is in
  the fast gate; open PNGs for drawing changes before merging.
- `killer_plant_spawn` original sound is extremely quiet (-46 dB RMS) — owner may want to look at it.
- New CC0 monster takes were chosen by pack/length/brightness, not by ear — owner auditions at playtest.
