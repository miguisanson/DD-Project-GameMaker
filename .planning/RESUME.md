# Resume here (written 2026-10-16, end of session 4 — owner moving to a new session because context is full)

Start with `/continue_DD-Project-GameMaker`, then read THIS file, `BOARD.md`, `BUILD-PLAN.md` (sections "Round 2" and "Round 3").
Spec = `research/DECISIONS.md` (D1-D158). Game code lands on branch `next` (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\next`);
docs live on `v1.9` (main checkout). Ask the owner "is it OK to run builds/tests now?" if they may be playing — while their game runs,
the gate prints "FAIL REAL SAVE FILES CHANGED" (their game writes %LOCALAPPDATA%\DD_Project); judge by [TEST-SUMMARY] then.

## Where things stand
- `next` @ f59c2b1 (or later merge commits) = everything through round 2 G1-G8 merged; fast gate 4260/0, smoke 719/0 at f59c2b1.
- Latest playtest build on disk: `E:\Games\DD-Project Playtest\943ce6d-20261015\` (round 2 G1-G4 + the owner's art/sound import).
  The owner played it and gave 41 notes -> grilled -> D140-D156 (+ D157/D158 at the end of the session).
- The owner did the IDE import (icons, merchant, card frame, 30 monster sounds, Game End event for save-on-close).

## In flight when the session paused (Sonnet subagents in worktrees; each was asked to commit WIP and stop)
Check each worktree: `git -C <wt> log --oneline -3` and `git -C <wt> status`. Finish (re-dispatch a Sonnet agent with the same brief
from BUILD-PLAN + DECISIONS), review, gate, merge — one at a time, re-gating after each merge.
| Worktree | Branch | Packet |
|---|---|---|
| `E:\Github_Projects\DD-Project-GameMaker-wt\g9` | g9-runstats | G9 run stats (D137) |
| `E:\Github_Projects\DD-Project-GameMaker-wt\h1` | h1-onemenu | H1 one menu for Esc/Tab + System tab + instant settings with keep/revert + menu/quit in battle (D140, D141) |
| `E:\Github_Projects\DD-Project-GameMaker-wt\h3` | h3-fixes | H3 review-4 fixes (enemy move deck, multi-hit preview, rumble Perfect flag, BREAK flag) + elites from floor 3 + press-back exits (D142, D145) |
| `E:\Github_Projects\DD-Project-GameMaker-wt\h9` | h9-backgrounds | H9 AI battle backgrounds, contact sheet, IMPORT.md (D151); Pixel Art XL LoRA download approved by the owner |

## Left to do (in order)
1. Land G9, H1, H3, H9 (above). H9 ends with an owner pick (art/battle_bg/contact_sheet.png) + IDE import (art/battle_bg/IMPORT.md).
2. Round 3 remaining (BUILD-PLAN "Round 3"): H2 shared Yes/No confirm pop-up (after H1); H4 level-up shows growth + HP/MP choice + balance;
   H5 skill memory + echo = discovered skills of the picked class + class select (greyed Nobody, sprite preview, ???);
   H6 cutscene skip (prompt after 1 s, skip at 2 s) + cutscene text in the dialogue box; H7 notes picked up, Notes list;
   H8 keyword highlights, status labels, device-aware prompts, XP bar, "Worn", Help stats page, full-HP bed/potion refusal sweep;
   H10 seed input; H11 smarter map AI + hiding spots + no spawn camping (D158); H14 lighting: darker rooms, fires/torches light up, vision cones as wall-occluded light (D157, D159);
   H12 writing overhaul (style guide + full rewrite; owner skims at the next playtest) + flavour choices;
   H13 elite outline follows the sprite, old death image reused, text-overflow sweep (card text spilled out, #35).
3. G10 one-style audit (every screen the same frame/highlight/fonts/spacing/motion/sounds; known: KO title menu overlaps the build id
   at 800x720; the taller skill details panel covers the enemy at 480x432) + G11 consistency pass (D133). Last, after round 3.
4. Opus deep review (every ~5-7 packets), clean full gate (owner not playing), new playtest build + PLAYTEST-QUEUE refresh.
5. Improvement mode after that (bug hunts, polish) until the owner says stop.
6. Owner, at the very end: sound/music creator names for the credits.

## Merge lessons (4 parallel packets)
- Conflicts land at the END of scr_test.gml (suites appended side by side), in Test_RunAll registrations, in the smoke/shots chains in
  scr_debug.gml (every packet hooks "the last step") and on `Shots =` in tools/automation/run_tests.ps1 (sum the added shots).
- After resolving: grep `^(<<<<<<<|=======|>>>>>>>)( |$)` in scripts/objects/tools and run a brace-balance check on scr_test.gml and
  scr_debug.gml BEFORE committing (a leftover marker / lost closing brace broke the build twice). When a hunk swallows the shared closing
  lines (`break; } }`), restore them from the branch's own file.
- Smoke chain order today: ... -> hunt-2 (250..268) -> class guard (320..339) -> title (270..275) -> rumble (360..365) -> echo (340..346)
  -> speed/preview (410..415) -> map juice (380..) -> end. Each new packet: chain onto the final step that calls Scenario_NoticeEnd.
- Workbook: take next's game_text.xlsx, apply the branch's rows that differ from the merge base (openpyxl), rebuild localization.json.
- Shots timeout is 480 s (195 shots); smoke ~5 min, bot ~5 min, full gate ~15-16 min.

## Notes from the paused packets
- **H1 (not started, worktree clean at f59c2b1):** the Tab menu hard-codes 6 tabs in `TabMenu_Data`, `TabMenu_Labels`, `Menu_Open`
  (`array_create(6)`) and `Menu_HandleInput` (`Ui_TabStep(.., 6, ..)`). `PauseMenu_*` is referenced from obj_ui_controller Step/Draw,
  obj_battle_controller Step/Draw, scr_dialogue, scr_player, scr_input (`Rumble_Step` reads UI_PAUSE), obj_sfx_manager Draw, and many
  smoke/shots scenarios. Settings = `SettingsPopup_*` / `SettingsMenu_Items` with a pending copy + Apply row. In battle Esc is also "Back"
  in the battle menus (decide the menu key there: e.g. Tab/Start opens the menu, Esc stays Back inside battle submenus, Esc on the root
  command menu opens the menu). The menu only opens when the player is settled, false in rm_battle. Quit-before-fight plan: snapshot
  `json_stringify(RunSave_Build())` in `EnemyPersist_BeginEncounter` (scr_room_state ~268) and write it atomically on quit; add a short
  battle cooldown after Continue so the overlapping enemy doesn't re-trigger at once. Smoke 470-489, shots 490-499.
- **H9 (art not generated, notes only at dbd8ed9):** the Pixel Art XL LoRA is ALREADY on disk:
  `E:\AI\ComfyUI\ComfyUI-Shared\models\loras\pixel-art-xl.safetensors` (170,543,052 bytes, sha256 matches HF). ComfyUI is not running;
  engine `E:\AI\ComfyUI\ComfyUI-Installs\ComfyUI`, python `...\standalone-env\python.exe`. `art/tools/gen_v2.py` has the
  checkpoint+LoRA+VAE workflow (no custom nodes) — change the latent to ~1280x1152. Keep everything on E: (C: had 81 GB free).
  Find the battle background draw site (obj_battle_controller / rm_battle). Delete art/battle_bg/WIP-NOTES.md once PICK.md exists.
- **G9 (nearly done, wip at b2a9bfc on top of checks 50335b7):** all 7 stats counted (grade points in scr_combat, `RunStats_*` at the
  end of scr_room_state), saved with the run, in history, on the summary (two columns when needed) and the Codex Runs page. Smoke
  440-447, shots 460-466. Left: `-Only bot`, re-run fast + smoke after the last Codex change, open shot_runstats_summary_800x720.png,
  then re-commit as `feat(run): ...`. On merge: its `Shots = 192` counts only its +5 -> next's count + 5. Smoke now uses ~21300 of the
  24000-frame cap — raise the cap/timeout when chaining more scenarios. "Fights won" = real battles; "Foes beaten" also counts auto-resolved.
- **H3 (not started, worktree clean at f59c2b1):** item 1 design — sign the enemy deck by phase + full weight list; rebuild only on a sign
  change or when empty; on draw skip unusable cards but keep them (scan from the end like array_pop); if only unusable remain, basic attack.
  Checks: block Bite for 5 picks -> its card stays and is the first pick after unblocking (~8 seeds); a custom 3:1 attack/Solidify brain with
  a 2-turn Solidify block uses Solidify exactly 10 of 40 turns, never twice per deck cycle (real Slime weights are 4:1). Assertion to change:
  Test_BagsMoves ~8204 "a fresh deck has exactly one of it in 4" -> "at least 1 in 4". Preview: Battle_HitPreview / Battle_PreviewLines
  (scr_combat ~3701/3735). Plan: Test_Suite_H3 after MapJuice; smoke 500-519.
- **Dispatch tip:** subagents cannot call update_plan / wrap_up (refused) — fine to ignore.
