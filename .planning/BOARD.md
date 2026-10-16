# DD-Project board
Updated after every step that lands. The full build list is `.planning/BUILD-PLAN.md`; the design spec is `.planning/research/DECISIONS.md` (D1-D125).
Build: READY - playtest build 7f4d08e-20261016 (all of round 3: D140-D165); agents keep improving on `next` | Release then stop (D28)

## Now — PLAYTEST NOW
- Play: `E:\Games\DD-Project Playtestf4d08e-20261016\DD-Project.exe` (your saves carry over; old builds 943ce6d and earlier can be deleted).
- Checklist: `.planning/PLAYTEST-QUEUE.md`, section "Build 7f4d08e-20261016" — 58 items in play order + 5 questions at the end. Mark good / bad / change, then say "merge the good ones".
- In this build: one Esc/Tab menu, Yes/No pop-up, seed entry, class screen + skill memory + echo, hold-to-skip, notes + Codex reader + note question, flavour choices, lighting (lighter, daylight rooms, sun spots, more torches, enemies give no light), smarter map AI, level-up choice, status labels + XP bar + Help, device-aware prompts, the full text rewrite + one word per meaning, the UI style pass, 3 battle backgrounds, and 19 bug fixes from tonight's hunts and review. Full gate PASS on every merge (unit, smoke, bot fight, 286 screenshots).
- Known: a few long texts can still crowd a panel (fixed on `next`, lands in the next build). The boss keeps the old background until you import D13 (below).
- While you play, the agents keep going on `next` (improvement mode: text-fit fixes, bug hunts, the ideas list); nothing changes this build.

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
- **Import the boss background** (5 min, GameMaker, project in `E:\Github_Projects\DD-Project-GameMaker-wt
ext`): Sprites → Create → Sprite, name `spr_battle_bg_boss`, Import `artattle_bg\candidates\D13.png` (160 x 144), Origin Top Left, Ctrl+S, close GameMaker, tell me "imported".
- **Pick ideas** for after the playtest: `.planning/IDEAS.md` (25 ideas, my top 5 at the end). Reply with the ids you want.
- **5 quick questions** at the end of the playtest checklist (battle menu read-only in fights, the Stranger loot rule, the reworded chest lines, QTE grade capitals, a real refuse sound).
- Final cleanup (optional, at the end): delete unused sprites `spr_attack_timing_target`, `spr_attack_timing_falling` in GameMaker.
- At the very end (before release): send the sound/music creator names for the credits.
- DONE 2026-10-16: icons, merchant, card frame, 30 monster sounds imported; Game End event added (save on close). Optional: OK to download the Pixel Art XL LoRA (~170 MB, huggingface nerijs/pixel-art-xl) + 2 ComfyUI nodes for better AI icons? Today's icons are script-drawn.
