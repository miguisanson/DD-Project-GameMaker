# Resume here (written 2026-10-15, owner paused development to play a game; updated 2026-10-15 session 2, paused again)

Start with `/continue_DD-Project-GameMaker`, then read this file, `BOARD.md`, `BUILD-PLAN.md`.
Spec = `research/DECISIONS.md` (D1-D115). Work lands on branch `next`; docs live on `v1.9`.
Never run tests/Igor/ComfyUI while the owner is using the PC — ask "is it OK to run now?" first.

## Status 2026-10-15 session 3: packets 1-3 below are DONE and merged to next. In flight: sfx-variety (item 4), d1b-menus.

## (historical) Paused packets

### 1. D1a — battle HUD + battle menus + dialogue (wt `../DD-Project-GameMaker-wt/d1a`, branch `d1a-battle-ui` @ 573511e = WIP + next merged in, clean)
Code done (see earlier notes: HUD/menus/dialogue on the framework, Guard, I-065/066/067, C4 merged). Session 2 full gate
(-WorkRoot E:\Temp\dd-gate-d1a): build OK, runtests OK, **bot OK (finishes now)**, shots OK (136), smoke FAIL 2 checks, FLAKY:
`dialogue_choice_down_moves_the_cursor` + `dialogue_choice_reports_the_pick pick=0` (scr_debug.gml ~6777, step 176).
**Root-cause evidence** (temp log in Ui_MenuStep, removed again): in failing runs ONE Scenario_Tap("menu_down") reads as
pressed on TWO consecutive frames (scn.f 8698 and 8699), so the 2-item choice menu wraps 0→1→0. Passing runs see it once.
Hypothesis (not yet proven): `Input_Update` (scr_input.gml ~263) skips recomputing when `last_step_time == current_time`;
when two frames share one current_time value the stale `pressed=true` survives a frame. Same thing would double-move
a real key press now and then. Next: prove it (log current_time + global.input.frame at the two presses), then fix by
deduping on a per-frame counter instead of current_time, with a Test_Suite check that two Input_Update calls in two
frames with the same current_time do not keep `pressed`. Then smoke ×3, full gate, -NegativeControl, merge into next.

### 2. Balance apply (wt `../DD-Project-GameMaker-wt/bal`, branch `bal-apply` @ d47014e WIP)
The Sonnet agent changed everything below (numbers, scr_test asserts, vectors, export, targets, report, report_after.py)
but was STOPPED before its gates (owner pause). Commit d47014e is NOT reviewed and NOT gated. Next: review the diff
against D111 exactly (expected values from DECISIONS.md, not the code), check the red-then-green claim by reverting one
number, then run the gates below. Original brief:
Apply exactly D111 (owner approved E1 proposals 1-6 in `research/balance-report.md`; NOT E1-7/E1-8): Palehorn HP 25→55
DEF 16→18; Choirbeast HP 34→140 DEF 18→24; ELITE_HP_MULT 1.8 (hook in Elite_Apply); enemy basic_power 3→5 / 5→7 /
Choirbeast 9→14; heavy-move power_mult 1.5→2.0 (Vine Trap, Cut, Ramming, Pale Hymn); Knight base SPD 8→10; Nobody 2nd
fixed stat point per level + THROW_NOBODY_MULT 2.0. D112: targets.json run length 25-30 min. Tests first (data
asserts red → green), update check_combat_vectors.py + vectors + scr_test "vec" lines, re-export (`-Only exportdata`),
refresh tools/balance/export_data.json, re-run sim, regenerate balance-report.md with "After D111". Gates
(-WorkRoot E:\Temp\dd-gate-bal): fast ×3, smoke, bot, -NegativeControl. Bot: change strategy/caps only, never assertion meaning.
Only one implementer at a time while packets share scr_test (AGENTS.md); art-final waits for this one.

### 3. Art final (wt `../DD-Project-GameMaker-wt/artf`, branch `art-final` @ e9685dc, nothing changed yet)
D113: merchant = candidate A (art/merchant/), NO gold tint; pulsing gold glow outline. obj_npc has no Draw event →
add `Merchant_DrawWorldFx` in scr_loot.gml called from `World_DrawFx` (scr_enemy.gml) like the elite outline; pure
`Merchant_GlowAlpha(ms)` with a failing test first (Test_Suite_Economy); sprite via asset_get_index("spr_merchant_idle"),
fallback untinted nobody_down; 2-frame idle at 2 fps. Put A into art/merchant/spr_merchant_idle/, one combined owner
import list (icons v2 strips + merchant A). D114: use icon set v2; redo bloodthirsty, hilt_bash, muscle_up, poison_pot,
solidify by script; rebuild art/strips_v2 + contact_sheet_v2.png. Gates (-WorkRoot E:\Temp\dd-gate-artf): fast, shots
(open shot_merchant_world.png), -NegativeControl.

### 4. NEW (owner idea 2026-10-15): monster sound variation — small packet, after D1a/bal/art (load `audio-design`)
Today each monster has ONE sound per event (scr_sfx.gml ~296-319, `enemy_spawn_*` / `enemy_special_*`); only the
stranger and final boss rotate takes (`SFX_RegisterVariantNoRepeat`). SFX_Play already takes `_pitch`/`_vol`.
Step A (code only, no new assets, no owner action): every enemy_* sound gets a small random pitch (about ±6 %) and
volume (about ±10 %) per play, and no-repeat rotation where 2+ takes exist. Check first: a Test_Suite_Audio case that
N plays of one enemy key give pitches inside the band and not all equal (inject the RNG stream). Owner L5: listen.
Step B (APPROVED by owner 2026-10-15, D116; download into E:\Temp, never into the repo until trimmed): 1-2 extra takes per monster from CC0 packs —
rubberduck "80 CC0 creature SFX" 1 and 2 (opengameart.org/content/80-cc0-creature-sfx, .../80-cc0-creture-sfx-2,
8 slime sounds), Ogrebane "Monster Sound Effects Pack" (opengameart.org/content/monster-sound-effects-pack),
Darsycho "Monster snarls" (opengameart.org/content/monster-snarls). No CC0 spider pack found: use hiss/bug takes.
Check each licence page before use; agent trims + normalises to the existing loudness, owner imports in the IDE
(new sound resources), credits list gets the names (D105).

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
