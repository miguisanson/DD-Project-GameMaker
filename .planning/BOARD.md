# DD-Project board
Updated after every step that lands. The full build list is `.planning/BUILD-PLAN.md`; the design spec is `.planning/research/DECISIONS.md` (D1-D94).
Build: none in progress | Mode: BIG BUILD, then one big playtest (D71) | Release then stop (D28)

## Now
- Building everything in BUILD-PLAN.md (A1 → E2). No playtest stops until it is all done.

## Done
- Playtest 1 (build d312bfb): new QTEs approved (D72). 11 findings logged as I-054..I-064, all in the build plan.
- Test system: one command builds, runs ~800 checks, a bot fight, screenshots; runs on a hidden desktop (never touches your screen).
- On `next`: cutscene screen fix, sliding bar + arrow QTEs + defence bar, ~1 s skills, sized effects, poison feedback, crash-safe saves, enemy sight/pathfinding/personalities, movement polish.
- All design decisions made (D1-D94).

## Decisions waiting for you (from the balance simulator, `.planning/research/balance-report.md`)
1. **Runs are too easy and too short.** Simulated average player wins 90-100% (target 35-55%), a winning run takes ~20 min (target 45-60). Numbers alone can't make runs longer — there are only ~25 fights on the map. Options: (a) accept ~25-30 min runs, (b) more fights per floor (denser per-floor enemy pools, some respawn between floors), (c) both + harder numbers. My recommendation: (b) + the balance proposals.
2. **Approve the balance proposals?** Bosses tougher (Palehorn HP 25→55, Choirbeast 34→140), elites ×1.8 HP, enemy hits harder, Knight SPD 8→10, Nobody stronger throws. Before/after numbers in the report. Say "approve all", or pick.
3. **Guard command:** the battle menu got a Guard action = "next hit deals half". OK?
4. **Merchant:** pick placeholder / A / B / C (recommended) / D from the preview sheet.
5. **Icons:** v1 or v2 per icon (sheet v2), plus: critical = starburst or clover? Steadfast = anchor OK?

## Waiting on you (whenever convenient; close GameMaker afterwards)
- Final cleanup (optional, at the end): delete unused sprites `spr_attack_timing_target`, `spr_attack_timing_falling` in GameMaker.
- At the very end (before release): send the sound/music creator names for the credits.
- Icons: look at `art/contact_sheet.png` (on branch next) and mark keep/redo; then import the strips in GameMaker following `art/IMPORT-CHECKLIST.md` (~10 min). Optional: OK to download the Pixel Art XL LoRA (~170 MB, huggingface nerijs/pixel-art-xl) + 2 ComfyUI nodes for better AI icons? Today's icons are script-drawn.
