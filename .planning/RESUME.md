# Resume here (written 2026-10-15, owner paused development to play a game)

Start with `/continue_DD-Project-GameMaker`, then read this file, `BOARD.md`, `BUILD-PLAN.md`.
Spec = `research/DECISIONS.md` (D1-D115). Work lands on branch `next`; docs live on `v1.9`.
Never run tests/Igor/ComfyUI while the owner is using the PC — ask "is it OK to run now?" first.

## Paused packets (worktrees exist; re-brief a Sonnet agent with the text below)

### 1. D1a — battle HUD + battle menus + dialogue (wt `../DD-Project-GameMaker-wt/d1a`, branch `d1a-battle-ui` @ e30ba6c WIP)
Done: battle HUD/menus/dialogue on the UI framework (D99, D101), Guard command (next hit −50%, STATUS_BRACE),
I-065 (test artifact, fixed in scenarios), I-066 (only telegraphed heavy moves use the defence bar), I-067 (log plate),
floor-8 note moved, C4 merged in (tutorial hooks inside the battle HUD, glyph hints), C4's 60 ms confirm guard now
survives menu rebuilds. REMAINING: run the full gate with `-WorkRoot E:\Temp\dd-gate-d1a` (bot never finished after
the guard fix; confirm `Shots = 136` in run_tests.ps1 matches the produced count), `-NegativeControl` must be GATE FAIL,
open a battle PNG with a tutorial pop-up; `git merge next`; commit; then the main session merges into `next`.

### 2. Balance apply (wt `../DD-Project-GameMaker-wt/bal`, branch `bal-apply` @ e9685dc, nothing changed yet)
Apply exactly D111 (owner approved E1 proposals 1-6 in `research/balance-report.md`; NOT E1-7/E1-8): Palehorn HP 25→55
DEF 16→18; Choirbeast HP 34→140 DEF 18→24; ELITE_HP_MULT 1.8 (hook in Elite_Apply); enemy basic_power 3→5 / 5→7 /
Choirbeast 9→14; heavy-move power_mult 1.5→2.0 (Vine Trap, Cut, Ramming, Pale Hymn); Knight base SPD 8→10; Nobody 2nd
fixed stat point per level + THROW_NOBODY_MULT 2.0. D112: targets.json run length 25-30 min. Tests first (data
asserts red → green), update check_combat_vectors.py + vectors + scr_test "vec" lines, re-export (`-Only exportdata`),
refresh tools/balance/export_data.json, re-run sim, regenerate balance-report.md with "After D111". Gates
(-WorkRoot E:\Temp\dd-gate-bal): fast ×3, smoke, bot, -NegativeControl. Bot: change strategy/caps only, never assertion meaning.

### 3. Art final (wt `../DD-Project-GameMaker-wt/artf`, branch `art-final` @ e9685dc, nothing changed yet)
D113: merchant = candidate A (art/merchant/), NO gold tint; pulsing gold glow outline. obj_npc has no Draw event →
add `Merchant_DrawWorldFx` in scr_loot.gml called from `World_DrawFx` (scr_enemy.gml) like the elite outline; pure
`Merchant_GlowAlpha(ms)` with a failing test first (Test_Suite_Economy); sprite via asset_get_index("spr_merchant_idle"),
fallback untinted nobody_down; 2-frame idle at 2 fps. Put A into art/merchant/spr_merchant_idle/, one combined owner
import list (icons v2 strips + merchant A). D114: use icon set v2; redo bloodthirsty, hilt_bash, muscle_up, poison_pot,
solidify by script; rebuild art/strips_v2 + contact_sheet_v2.png. Gates (-WorkRoot E:\Temp\dd-gate-artf): fast, shots
(open shot_merchant_world.png), -NegativeControl.

## Still to build after those (BUILD-PLAN.md)
- D1b: Tab menu (Status/Skills/Items/Gear/Codex/Settings, D90) + pause + inventory/gear incl. accessory + codex (notes,
  bestiary, run history) + any remaining screens on the framework; WHITE text for item names and list text (D115).
- D3: text pass (Korean consistency, merchant lines, codex text), lint clean.
- F1: optimisation + consistency pass (D108).
- E2: full gate + regression list + playtest build copied to E:\Games\DD-Project Playtest\<build id> + one big
  PLAYTEST-QUEUE; owner imports icon strips + merchant in GameMaker (combined checklist); sound/music credit names last.

## Merge lessons (keep doing)
Give each packet its own scenario step range (see BUILD-PLAN.md); agents `git merge next` before reporting; workbook
conflicts: take next's game_text.xlsx and re-add the branch's rows with openpyxl, then rebuild localization.json;
open PNGs for every drawing change before merging.
