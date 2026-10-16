# DD-Project board
Updated after every step that lands. The full build list is `.planning/BUILD-PLAN.md`; the design spec is `.planning/research/DECISIONS.md` (D1-D125).
Build: SHIPPED v1.0 (2026-10-17)

## Now — SHIPPED: NO HOPE v1.0 (2026-10-17)
- **Upload:** `E:\Games\NO HOPE Release\NO-HOPE-v1.0-windows.zip` + paste `itch-page.md` + the 6 PNGs in `itch-screenshots\` (in order). Free / pay what you want.
- **Optional before uploading (GameMaker):** Game Options > Windows: display name "NO HOPE", company, description, icon. Remove the unused fonts NotoSansCJKkr / NanumGothic if you like (not in the zip anyway).
- **In v1.0:** all round-3 and round-4 notes, profiles + 3 save files + Save in the menu, stealth (cone, bushes break chases), rarity colours, gold outline on loot, mouse, VIG/MND level-up, Guard + MP, weak points, death tips, trapped chests, boss finisher, harder BREAK, slower SPD, less gold, even sound levels, credits screen. Every build passed the full gate.
- **Code:** merged to `main`, tagged `v1.0` on this PC only (nothing pushed). Development can resume any time: see `.planning/RESUME.md`.

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
