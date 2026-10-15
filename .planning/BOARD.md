# DD-Project board
Updated after every step that lands. The full build list is `.planning/BUILD-PLAN.md`; the design spec is `.planning/research/DECISIONS.md` (D1-D125).
Build: **PLAYTEST NOW** — build fc886c7-20261015 | Mode: BIG BUILD, then one big playtest (D71) | Release then stop (D28)

## Now — PLAYTEST NOW
- Play: `E:\Games\DD-Project Playtestc886c7-20261015\DD-Project.exe` (fresh start: your old saves are in `old-saves-2026-10-15`).
- Checklist: `.planning/PLAYTEST-QUEUE.md` — 57 entries in play order (~60-90 min). Mark good / bad / change, then say "merge the good ones".
- Everything decided is built; full gate PASS on this build (3337 unit checks, smoke, bot fight, 172 screenshots).
- While you play, the agents keep going on safe clean-up (improvement mode) on branch `next`; nothing changes this build.

## Done
- Overnight 2026-10-15/16: fairer randomness (D117-D125), alt-tab pause, flee % and crit odds shown, difficulty list removed, New Game asks twice when a run is saved, optimisation pass (menus ~22x, items ~20x, battle HUD ~2.6x faster), ~1,400 lines of dead code removed, an extra Opus review (1 real bug fixed).
- Playtest 1 (build d312bfb): new QTEs approved (D72). 11 findings logged as I-054..I-064, all in the build plan.
- Test system: one command builds, runs ~800 checks, a bot fight, screenshots; runs on a hidden desktop (never touches your screen).
- On `next`: cutscene screen fix, sliding bar + arrow QTEs + defence bar, ~1 s skills, sized effects, poison feedback, crash-safe saves, enemy sight/pathfinding/personalities, movement polish.
- All design decisions made (D1-D94).

## Decisions made 2026-10-15
- Fairer randomness (D117-D125): loot picks the rarity tier first; chests never empty; crits use a marble bag; enemy drops get bad-luck protection; flee uses SPD ratio + retry boost; alt-tab opens pause; elites spread evenly per floor; tooltips state the odds. Old saves moved to E:\Games\DD-Project Playtest\old-saves-2026-10-15 (fresh start).
- Monster sounds: pitch/volume variation + free CC0 creature packs approved (D116).
- Balance proposals approved (D111); runs ~25-30 min accepted (D112); merchant = A with a gold glow outline, no tint (D113); icons v2 + redo weakest (D114); white text for names (D115).

## Waiting on you (whenever convenient; close GameMaker afterwards)
- Final cleanup (optional, at the end): delete unused sprites `spr_attack_timing_target`, `spr_attack_timing_falling` in GameMaker.
- At the very end (before release): send the sound/music creator names for the credits.
- Icons: look at `art/contact_sheet.png` (on branch next) and mark keep/redo; then import the strips in GameMaker following `art/IMPORT-CHECKLIST.md` (~10 min). Optional: OK to download the Pixel Art XL LoRA (~170 MB, huggingface nerijs/pixel-art-xl) + 2 ComfyUI nodes for better AI icons? Today's icons are script-drawn.
