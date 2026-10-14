---
gsd_state_version: '1.0'
milestone: v2.0
milestone_name: Done right (replayable roguelike)
status: planning
progress:
  total_phases: 8
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# STATE: DD-Project-GameMaker

**Owner: read `.planning/BOARD.md` first.** It is the only tracker you need. This file is for agents.

## Header (update on every step that lands)

| Field | Value |
|---|---|
| Build id | stamped per gate run (`<hash>-<date>`), shown bottom-right of the title screen |
| Working branch | `v1.9` (cut from `v1.8` 2026-10-13; game code identical to `0b6e2f8`, which the audits cite). Unattended work goes on `next` (`IMPROVE.md`). |
| Last stable build | `v1.9` @ its first commit (planning docs only) |
| Regressions since last stable build | 0 |
| Open P1s | 0 (none confirmed; see `ISSUES.md`) |
| WIP | BIG BUILD (D71) per .planning/BUILD-PLAN.md, packets A1..E2, on branch `next`. Playtest 1 done (QTE approved). |
| Unplayed features | no cap (D71); one big playtest at E2 |
| Regression list | never run (`REGRESSION.md`, 48 entries) |
| Drive C: free | 80 GB (after cleanup, 2026-10-14; rule is 80-90 GB or more) |

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-10-14)

**Core value:** A short 8-bit dungeon RPG you can replay: every run is a fair, satisfying 45-60 minute climb.
**Current focus:** Milestone v2.0 "Done right", now a roguelike-style game (D25-D36). No game code changed yet.

## Current Position

**Packet D1a (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\d1a`, branch `d1a-battle-ui`, built by a Sonnet subagent, not merged):** battle HUD and dialogue box on the D0 framework (D89, D92, D95-D101). Battle: turn strip on a plate (`Battle_DrawTimeline`), enemy plate with name / HP (glides, bright trail) / stagger and status chips beside it (a big enemy gets the plate beside it), player panel bottom-left (name, Lv, HP, MP striped, chips, hurt shake), command menu bottom-right (Attack / Skill / Item / Guard / Run), skill and item lists with icon, MP or quantity, and the details panel above the list (sentence + numbers from the data via `Battle_SkillDetails` / `Battle_ItemDetails`, arrows to press), a one-entry log plate (`LOG_TOAST_MS`) above the bottom panels, banner only during the bars. Zones are pure (`BattleHud_Zones`); menus are `Ui_Menu` objects owned by the controller (`Battle_MenusBuild/Step`, `Battle_DrawMenus`). Framework additions in `Ui_MenuDraw` (all optional layout / item fields: `x_anchor`, `panel_w`, `y_bottom`, `max_h`, `details_pos`, `details_cols`, `rows_max`, item `icon` / `seq` / `dim`; `m.rect`, `m.det_rect`) and `Ui_FitText`. Icons: `Icon_Get(category, frame)` in `scr_fx` = the imported `spr_icons_<category>` or a sprite built at run time from the generated rows (`art/tools/gen_icon_fallback.py`; when a strip is imported drop that category from the script and re-run). Guard: new status `STATUS_BRACE` (next hit deals half, `Battle_GuardApply`; the 50% is an agent-chosen number for the owner to judge). Dialogue: `Dialogue_Draw` (frame, `Ui_DrawNameTab`, typewriter, blinking arrow, hold 0.15 s for boxed lines), `Dialogue_StartChoice(speaker, lines, labels, on_pick, allow_back)`. I-066 fixed (only telegraphed moves get the bar, `Qte_DefenceParams` rows of the plain moves removed). I-065 is NOT a game bug: max HP / MP are derived from class and level at every battle start, so the old test lines `_ch.max_hp = 99` before a battle were ignored; scenarios now set `global.scn.boost` (`Scenario_BoostBattle`); bot `v=10` plays a levelled Knight through a real fight. I-067 fixed by the log plate. The enemy sits 14 world px above the middle (Create_0). C5's `carved_arrow` note moved from rm_floor8 (2,3) to (1,3): it stood in the only corridor to the exit (2,1); smoke now checks every door of a note's room stays reachable. Removed: the old battle draw code, the HUD block of `obj_ui_controller`, `Status_DrawIcons` and friends, the "battle" tooltip style, the old dialogue box macros. Checked: `Test_Suite_BattleUi`, smoke 171-176, bot v=10, shots 185-189 (15 pictures `shot_battleui_*`). Text: EN fallbacks plus EN + KO rows (workbook re-added by a script; the 3 old KO command labels mended). Next: review, merge, re-run the gate.

**Packet C5 (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\c5`, branch `c5-story`, built by a Sonnet subagent, not merged):** story. Death scene (D103): `RunFlow` phases death (one line by death-count tier 1 / 2-3 / 4-6 / 7-10 / 11+ and killer, 2-4 s, hold to skip) -> summary and echo pick on the D0 framework -> wake line at the entrance (`pending_wake_line`). 29 death lines + 4 wake lines, EN + KO draft (`DeathLine_*`, `WakeLine_Pick`, `Death_*` in scr_dialogue.gml; `Run_OnPlayerDeath` builds `global.death_ctx`; one line in `Status_ApplyHpTick` notes a poison/burn/bleed kill). Boss name banner (D106, `Banner_*`, `DialogueTrigger_TryBanner`). 8 lore notes (D107, `Note_*`; plain `obj_interactable` made by `Notes_SpawnForRoom`, drawn by `Note_DrawWorldFx`, read in `Interact_Handle`; recorded as profile unlock `note_<id>`; `Note_Collected(prof)` is the Codex data function). Closing text + credits roll (D105; `Story_ClosingLines`, `Credits_*`, state "credits" in obj_start_controller); sound creators are `CREDITS_CREATOR_TBD` (TODO-OWNER). Checked: `Test_Suite_Story`, smoke steps 113-122 + edited 102/104/110/111, 9 story shots. Localization rows are re-added by a script (workbook + `build_localization.py`).
**Packet C2 (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\c2`, branch `c2-cards`, built by a main-session agent, not merged):** cards (D18, D34, D73, D76, D81-D83, D88, D93, D100). Data and generator in `scr_db_skill` (`CardDB_*`, `Card_*`: 14 skill cards, 14 upgrades, 19 passives, 3 fallbacks; `Card_OfferGenerate` pure, weighted by kind, quota, pity after 2 offers without an upgrade, decline memory, same seed = same offers from the run's `cards` stream; the pity state is `run.cards`, saved in the run save). What the character owes lives on the character (`card_picks`, `class_pick`, `class_chosen`, `skill_pending`, `offer`, plus `upgrades`, `passives`): `Cards_NextOwed` in `scr_levelup` (class, replace, stat, cards). During a run `Level_AutoPlaceEnabled()` is false (the player places the point); tests and tools still auto-place. Screens (`CardsUi_*` in `scr_menu`, mode `UI_CARDS`): class pick (Ui menu + details, Nobody row shows "Locked" and its hint, "are you sure"), stat point, replace-a-skill, and the 3-card pick (custom draw with the Ui kit and `Qte_DrawArrowGlyph`); opened by `CardsUi_Step` from `obj_ui_controller` Step. Class chest and skill chest (`obj_chest_skillbook` now sets `card_chest`): first one = class choice, later ones = a pick (I-057, R-070). Skill books are removed (items 101-114, `Item_IsSkillbook`, loot lists, grave stage 4 now gives a Lv3 item); the first-read dialogue code is dormant, not deleted. Effects: upgrades through `SkillDB_Get` (copy; name gets +) and `Qte_SkillSequence` (now a wrapper over `Qte_SkillSequenceBase`); passives through `Equip_GetPassives` (Mana Spring), `Qte_PerfectWiden`, `Skill_StatusStacks`, `Skill_AdjustStatusTurns`, `Item_ComputeAmount`, `Item_Use`, `Card_OnVictory` (one line each in `Battle_GrantRewards` and `Enemy_AutoResolveFinalize`). Not wired yet: Coin Sense (+10% gold) needs the shop packet to call `Card_GoldMult`; the "start a fight with 1 stagger" passive waits for B3's stagger; throwables do not exist yet (Potion Lore and Apothecary act on potions now). Checked: `Test_Suite_Cards` (140 assertions, run 3x), smoke steps 133-141 (class screen, skill chest pick, level-up stat point then pick, Skip gold, 4th skill replace, Nobody locked then open after a win; smoke cap 9000 frames, wrapper smoke timeout 220 s), `-shots` 86 (8 new `shot_ui_cards_*`). Text: EN fallbacks plus EN+KO rows in the workbook (102+ rows, KO is a draft). Next: review, merge, re-run the gate.

**Packet C1 (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\c1`, branch `c1-run`, built by a main-session agent, not merged):** run loop. `Rng_*` Park-Miller streams in `scr_math` (map, loot, shop, enemy, cards, combat; state saved as two integers per stream; golden values from a separate Python script). `profile.sav` (story seen, unlocks, echo, history) and `run.sav` (seed, stream states, player, room state, position), each versioned, atomic (.bak), old `savedata*.sav` recognised and never touched (title message once). `Profile_*`, `Story_*`, `Unlock_*`, `RunSave_*` in `scr_save`; `Run_*` and `RunFlow_*` (summary, echo pick, new run) in `scr_room_state`. Hooks: `Player_OnDeath` (scr_combat, 1 line), `obj_start_controller` (Continue row, intro once, `run_flow` state), `obj_game_controller` (autosave on room change and every 10 s), pause menu Abandon Run (2 presses), bed = one line (rest site is C4), dialogue triggers and the ending play once per profile. Not converted (B1/B2 own them): `random()` in scr_combat, scr_db_skill, scr_status, scr_equip, scr_db_item (combat stream `combat` is ready). New text keys use English fallbacks; add them to `game_text.xlsx`. Checked: `-runtests` (Rng, Profile, RunSave, RunLoop suites), `-smoke` (run loop scenario), `-bot`. Next: review, merge, re-run the gate.

**Packet A1 (worktree `E:\Github_Projects\DD-Project-GameMaker-wt1`, branch `a1-draw`, implemented by the main session, not committed-merged):** world marks fixed (I-056, I-058, I-059, I-060, I-063; R-061 to R-065). Cause of the top-left marks: a layer script is called once per engine draw PASS (8 passes incl. the 3 Draw GUI ones), so `Nav_DrawWorldFx` / `Player_DrawWorldFx` also painted in GUI units; fixed with `Fx_IsWorldPass()`. Also: one `World_DrawFx` layer script registered once per room start (`World_RegisterFx`, `Room_StampBump` in `obj_game_controller` Create); effects sized by `FX_ContentSide` (sprite bbox). `-shots` now has 67 [SHOT] lines (`shot_world_*` pairs checked by Test-Shots A-versus-B diff). Next: review, merge to `next`, re-run the gate.

**Phase:** 0 (audit, research, direction) is complete. Planning was **revised 2026-10-14 for the roguelike direction** (D25-D36 added, plan review applied). Phases 1-3 have not started.
**Status:** The planning set is rewritten: 157 requirements (159 before D52), 8 phases, `BOARD.md` added. No game code has been changed.
**Last activity:** 2026-10-14 (later): D52 applied (Windows only, no web/HTML5 build; D15 and D50 superseded, D39 amended): WEB became REL, 157 requirements. Earlier the same day: PROJECT, REQUIREMENTS, ROADMAP, BOARD (new), ISSUES, REGRESSION, IMPROVE, STATE and research/SUMMARY updated.

**Next action:** After the owner's go, start the "safe to start now" items together (they share no files):
1. Phase 1: the compile wrapper and its negative control, then the test suites, bot and screenshots; then the old-bug repros and safe save writes. Also apply `research/AGENTS-CHANGES.md` to AGENTS.md (wave 1D). Go straight to `/gsd-plan-phase 1`.
2. Phase 3 sketches P1 (run loop) first, in a scratch copy `E:\Temp\dd-spike-<name>` (throwaway, never merged; `LOCALAPPDATA` redirected; builds on E:). The owner plays each for about 10 minutes.
3. Phase 2 display spike and measurements (needs Phase 1 waves 1A-1C for the screenshot bot).
Do not start Phase 4 until the G3 save contract is written. Do not start any combat or card code before its grill-me topic (`ROADMAP.md`, "Grill-me topics").

**Owner tasks waiting:** create script asset `scr_test` in the IDE (1 minute; fallback `scr_debug.gml`); send sound/music creator names for the credits; ask the friend which build they played (I-039); later, the Phase 2 IDE tasks listed on `BOARD.md`. Open question: D3 (Android later) vs D28 (no post-release) (I-046).

**Progress:** [░░░░░░░░░░] 0% (0 of 8 phases)

## Planning set (read in this order)

1. `BOARD.md`: the owner's one-page tracker (Now / Next / Later / Done / Waiting on you).
2. `research/DECISIONS.md`: owner decisions, locked (D1-D52; D52 = Windows only, 2026-10-14).
3. `PROJECT.md`, `REQUIREMENTS.md` (157 requirements, check levels L1-L5, two gates), `ROADMAP.md` (8 phases, grill topics G0-G10).
4. `IMPROVE.md`, `REGRESSION.md`, `ISSUES.md`, `PLAYTEST-QUEUE.md`: the improvement-mode process.
5. `research/SUMMARY.md`: index of every research and audit file, including `roguelike-design.md`, `roguelike-cases.md` and `plan-review.md`. `research/AGENTS-CHANGES.md`: proposed AGENTS.md text.

## Numbers to review (agent-chosen starting values; owner approves after playing)

- QTE bar (sweep / perfect / good / ok half-widths, ms): sword 1100/60/120/200, bow 850/60/130/220, staff 1200/55/115/190 (dagger 750, heavy 1500 unused). Grades 1.30/1.10/1.00/0.75; round-half-up, min change 1.
- Arrows: 3 (3.4 s, Perfect <=1.5 s) Wound DRU, Muscle Up UDU, Rev Up LUR, Evasion LDL, Take Aim RUR, Meditation DDU, Foresight ULD; 4 (4.2 s, <=1.95 s) Hilt Bash DLRU, Poison Arrow RRDL, Poison Mist LDRD, Fireball URDL; 5 (5.0 s, <=2.4 s) Horizontal Slash LRLRD, Double Shot RURDR, Ice Spear UDLDU. Wrong press -250 ms.
- Defence: 400 ms telegraph; damage taken 25/50/75/100 %; status kept 0/half/3-4/full. Bite 800/55, Ghost Cut 750/50, Poison Fangs 900/55, Scorching Touch 1000/55, Vine Trap 1300/60, Ramming 1500/50.
- Map AI: sight 3-5 tiles; chase speed slime .7, spider/snake/whisp/ghost .85, plant .8, stranger .9, wolf 1.0; search 90 frames. Player: turn 6 frames, buffer 10, run 2 px/frame (Shift / shoulders).
- Text scale 1.0/1.5/2.0 at window scale 3/4/5.

## Learned, not obvious from code

- **Test runs still take focus**: the game window becomes foreground ~273 ms after a minimized launch (display spike). Never run window modes while the owner uses the PC until fixed (I-053).
- **Owner IDE tasks for the next stop**: add Create/Begin Step/Draw GUI events to obj_display (then move display logic from obj_ui_controller); options: window colour black, Windows scaling -1, allow window resize (DISP-11).

- **An open GameMaker IDE overwrites .gml files with its stale in-memory copy** (2026-10-14: it reverted scr_test.gml to the placeholder on close). The owner keeps the IDE closed while agents work; before merging, check `git status` is clean.

- **Igor works.** The headless build CLI exists at `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\Igor.exe`. A compile took about 9-13 s; the built game ran and its output was captured (`research/automation-igor.md`). AGENTS.md "Traps" and "The gate" still say it does not exist; they are updated in Phase 1 (wave 1D).
- **Igor catches syntax errors but not unknown functions** (exit 0). Only a run catches those (`automation-igor.md` section 2.6). `game_end(n)` inside the unhandled-error handler returns exit code 0, so detect crashes from the log.
- **`v1.8` contains every commit of `1.5_Porting`, `1.6_Dangerous-Porting` and `v1.7`**. `main` is behind `v1.8` except two merge commits.
- **Drive C:** 71 GB free on 2026-10-13, about 80 GB after cleanup on 2026-10-14. Igor and the game wrote only small files on C:. Always pass `--cache` and `--temp` on E:.
- **The friend probably played an old build.** Skill books twice, the moving mini boss and the missing poison damage look fixed since `f39236b` (2026-03-05) (`audit/combat-bugs.md`). Ask which build; if no answer comes, the repros on the current build are the answer.
- **Real saves live in `%LOCALAPPDATA%\DD_Project`.** Automation must redirect `LOCALAPPDATA`. Never print `%APPDATA%\GameMakerStudio2\um.json` (live tokens).
- **Code facts checked on 2026-10-14** (plan review): `settings_version` is 7; there are 18 GUI-size call pairs (not 17); `randomize()` is called once, in `scr_player.gml:1530`; death reloads the latest save slot (`obj_start_controller/Step_0.gml`, case `game_over`); `Save_Write` respawns enemies (`scr_save.gml:394`); there are no credits in the code.
- **Roguelike research:** option A (existing floors, shuffled content) was chosen (D25). Seeds use the game's own counter-based streams, not `random_set_seed`, and avoid 64-bit/sign-dependent bit operations (kept simple on purpose; `roguelike-cases.md` section 4). No mature GML card/run library exists; the run manager is written here, borrowing ideas only from MIT/CC0 sources (GPL/AGPL code is read, never copied).
- **Tensions between decisions and research** are listed in `PROJECT.md` under Key Decisions (D6 vs D20; D8 vs pixel-font advice; D24 vs D6; D18 and D22 vs the icon list; D21 vs current QTE; D3 vs D28; D18 pool size vs replay).
- **GSD config:** `.planning/config.json` has `human_verify_mode: "end-of-phase"`, which sits badly with D12 (owner checks per feature). Not changed here; the main session should relax it.

## Accumulated Context

### Decisions

Locked in `research/DECISIONS.md` (D1-D36). Summary table in `PROJECT.md`. Process decisions made in this plan, for the owner to confirm: the 8-phase order; prototype first for feel and the run loop; grill-me per topic just before building (G0-G10), not up front; `BOARD.md` as the owner's tracker; two gates (fast and full); data in JSON shared with the simulator; the simulator comes with the combat core; `next` branch for unattended work; the bug-hunt cap of 5 findings per pass (`IMPROVE.md`); the cut order in `REQUIREMENTS.md`.

### Pending Todos

- Ask the friend which build they played (I-039). "Bone" is answered by D24: Foresight's icon should be an eye.
- Run Phases 1, 2 and 3 in parallel after the owner's go.
- G1 (D8 text rule) is decided once, in Phase 2.
- G3 (save contract) must finish before Phase 4.

### Blockers / Concerns

- Igor and the IDE running together is untested (`automation-igor.md` section 5).
- Several balance findings are model results, never run in the game (`balance-data.md` tags [model]).
- Card pools of about 5 skills + 5-8 upgrades per class may make runs look alike (PROJECT.md tension 8); G7 decides the rules that keep picks meaningful.

## Deferred Items

None are deferred to "later" any more: D28 says there is no post-release. Items that used to be deferred are listed under "Not built, ever" in `REQUIREMENTS.md` (Android, bestiary and enemy-skill icons, QTE calibration screen, post-win ladder, daily seeds, node map).

## Session Continuity

Last session: 2026-10-14
Stopped at: planning set rewritten for the roguelike direction; waiting for the owner's go.
Resume file: None. Start with `/continue_DD-Project-GameMaker`, then read `BOARD.md`.
