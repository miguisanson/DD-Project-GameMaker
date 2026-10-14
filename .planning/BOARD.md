# DD-Project board
Updated after every step that lands. The full build list is `.planning/BUILD-PLAN.md`; the design spec is `.planning/research/DECISIONS.md` (D1-D94).
Build: PAUSED (owner playing) — 3 packets parked, see .planning/RESUME.md | Mode: BIG BUILD, then one big playtest (D71) | Release then stop (D28)

## Now
- Building everything in BUILD-PLAN.md (A1 → E2). No playtest stops until it is all done.

## Done
- Playtest 1 (build d312bfb): new QTEs approved (D72). 11 findings logged as I-054..I-064, all in the build plan.
- Test system: one command builds, runs ~800 checks, a bot fight, screenshots; runs on a hidden desktop (never touches your screen).
- On `next`: cutscene screen fix, sliding bar + arrow QTEs + defence bar, ~1 s skills, sized effects, poison feedback, crash-safe saves, enemy sight/pathfinding/personalities, movement polish.
- All design decisions made (D1-D94).

## Decisions made 2026-10-15
- Monster sounds: pitch/volume variation + free CC0 creature packs approved (D116).
- Balance proposals approved (D111); runs ~25-30 min accepted (D112); merchant = A with a gold glow outline, no tint (D113); icons v2 + redo weakest (D114); white text for names (D115).

## Waiting on you (whenever convenient; close GameMaker afterwards)
- Final cleanup (optional, at the end): delete unused sprites `spr_attack_timing_target`, `spr_attack_timing_falling` in GameMaker.
- At the very end (before release): send the sound/music creator names for the credits.
- Icons: look at `art/contact_sheet.png` (on branch next) and mark keep/redo; then import the strips in GameMaker following `art/IMPORT-CHECKLIST.md` (~10 min). Optional: OK to download the Pixel Art XL LoRA (~170 MB, huggingface nerijs/pixel-art-xl) + 2 ComfyUI nodes for better AI icons? Today's icons are script-drawn.
