# DD-Project board
Updated after every step that lands. The full build list is `.planning/BUILD-PLAN.md`; the design spec is `.planning/research/DECISIONS.md` (D1-D125).
Build: fixing round-3 playtest notes on `next` (next playtest build after batch 2) | Release then stop (D28)

## Now — FIXING YOUR ROUND-3 NOTES (29 items)
- Your notes are logged (ISSUES I-077..I-105) and your answers are locked as D174-D183 (profiles + 3 save files, VIG/MND, gold growth rows, rarity colours, stealth package + faint cone, Guard + MP, stagger unchanged, Skip removed, ALL CAPS grades, mouse cursor without click-to-move).
- Batch 1 building now: lighting flicker + merchant light, enemy shadows + snake position + buff blink, card Skip removal + card text fit, caps grades + Gear headers + reset pop-up.
- Batch 2 next: profiles/save files, stealth, rarity, Guard, mouse, level-up screen, wolf dialogue, death titles.
- Nothing waiting on you: I set the VIG/MND and idea numbers (D184/D185, Mage = glass cannon); you judge them in the playtest. After the fixes I go straight on to the ideas (weak points, trapped chests, boss finisher, death tip); branching upgrades waits for a quick Q&A. Music/refuse-sound candidates will be in artudio_candidates with PICK.md.
- Running 2 agents at a time (your cap); roughly 10-14 h for the fixes, then the ideas.
- Already fixed on `next` (in the next build): the "Damag.."/"Perfec.." plate, the run summary labels.

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
- DONE 2026-10-17: boss background imported (on `next`; it shows from the next playtest build on).
- **Pick ideas** for after the playtest: `.planning/IDEAS.md` (25 ideas, my top 5 at the end). Reply with the ids you want.
- **5 quick questions** at the end of the playtest checklist (battle menu read-only in fights, the Stranger loot rule, the reworded chest lines, QTE grade capitals, a real refuse sound).
- **Names that do not fit their cards/panels at big window sizes** (your call): Horizontal Slash, Poison Arrow, Meditation+, Apothecary (cards at 640x576/800x720), The Pale Choirbeast (bestiary). Options: shorter names (e.g. "Pale Choirbeast" without "The" fits), or the card shows the name on two lines. Say which.
- **Battle and boss music** (D42): the game has no battle or boss track yet (a bug hunt found it). Do you have tracks, or should I suggest free CC0 ones for you to pick and import? (Like the monster sounds, D116.)
- Final cleanup (optional, at the end): delete unused sprites `spr_attack_timing_target`, `spr_attack_timing_falling` in GameMaker.
- At the very end (before release): send the sound/music creator names for the credits.
- DONE 2026-10-16: icons, merchant, card frame, 30 monster sounds imported; Game End event added (save on close). Optional: OK to download the Pixel Art XL LoRA (~170 MB, huggingface nerijs/pixel-art-xl) + 2 ComfyUI nodes for better AI icons? Today's icons are script-drawn.
