# Big build plan (D71: build everything, then one big playtest)

Spec = `research/DECISIONS.md` (D1-D94). Work lands on branch `next`; at the end, one full gate + one playtest build.
Max 2-3 implementer agents at once, only on non-overlapping files. Every drawing change runs `-Only shots`
and the main session opens the PNGs before merging. Data stays in the GML DB scripts (`scr_db_*`); the
game exports JSON with `-exportdata` for the Python simulator (no Included File needed).

| # | Packet | Decisions / issues | Status |
|---|---|---|---|
| A1 | Draw-space bugs: sight ring + prompt drawn top-left, ring gone after battle; arrow outline; run animation; effects ≥ target size | I-056, I-058, I-059, I-060, I-063 | MERGED to next |
| A2 | Window modes (windowed sizes / borderless / exclusive), resize, rm_floor6_5 clamp, hold-to-skip intro & scenes | D91, D48, I-054, I-055, DISP-10/11 | MERGED to next |
| B1 | Stats ATK/DEF/SPD/MAG + HP/MP, ratio damage, level-up (class growth + 1 free point), `-exportdata` JSON | D22, D76, D77 | MERGED to next |
| B2 | Statuses (poison stacks, burn, bleed), no dice anywhere, Evasion/Solidify, Foresight | D78, D79, D80, D21 | MERGED to next |
| B3 | Turn timeline (next 5), stun push-back + Steadfast, stagger meter + BREAK, damage numbers | D74, D75, D92 | MERGED to next |
| B4 | Battle AI rule lists, telegraphed big attacks, boss phases | D68, D7 | MERGED to next (follow-ups I-065, I-066) |
| C1 | Run loop: run/profile save split, seeded RNG streams, death → entrance, echo gift, abandon run, auto-save + continue, story seen once, run history, unlocks | D25-D27, D30-D33, D36, D46, D87, D88, D92 | MERGED to next |
| C2 | Chests (class first, then cards), class pick (Nobody locked), cards 1-of-3 at chests + level-ups, upgrades, passives (shared + class), max 3 skills equipped | D73, D81, D82, D34, D83 | MERGED to next |
| C3 | Gold, merchant after floors 2/5/8, throwables (all classes, Nobody stronger), accessory slot, elites, per-run shuffles | D23, D33, D84, D85, D86, D92 | MERGED to next |
| C4 | Beds (heal or upgrade), tutorial prompts + Help page, settings (QTE assist, key rebinding, text speed, shake), device button prompts | D45, D47, D49, D92 | MERGED to next |
| D0 | Shared UI framework: one menu component (wrap-around, hold-to-scroll, same confirm/back, back = one level, remembered cursor, mouse hover/click/wheel), frames, fonts, motion, details panel with data-generated text; migrate the title menu first as the pilot | D95-D98, D100 | MERGED to next (title + settings on the framework) |
| D1 | (D1a + D1b both MERGED to next) Every screen on the framework: settings, credits, battle HUD (D99) + battle menus, Tab menu (Status/Skills/Items/Gear/Codex/Settings) + pause, class pick, card pick, shop, bed, level-up, run end, echo pick, dialogue box (D101), prompts; remove the old per-screen menu code | D89, D90, D96, D99, D101, I-061, I-062 | todo |
| D2 | Art: ComfyUI icons (status, skills, items, throwables, passives) + card frame, PNG strips + owner import checklist; code fallbacks until imported | D10, D43, D44, D94 | MERGED to next (script-drawn icons; SDXL base unusable at 16 px; owner import pending) |
| C5 | Story in runs: death scene (D103) + rotating death lines, wake at tunnel entrance, seen-once story with boss name banners (D106), lore notes in existing rooms incl. death-count notes (D107), credits text update (D105) | D102-D107, D26 | MERGED to next |
| D3 | Text: cards, passives, death lines, lore notes, merchant, tutorial, codex (EN + KO draft); credits list (sound creators from owner) | D93, D40, D105, D107 | MERGED to next (sound creators still from owner) |
| F1 | Full optimisation + consistency pass: frame-time probe in the bot (before/after), per-frame work and allocations, draw calls, room loads; dead/duplicated code, frame-counted timers → ms, global sprawl; consistent controls, wording, colours, sounds, naming | D108, ROB-01..03 | todo |
| E1 | Simulator on `-exportdata` JSON, target bands, balance proposals for the owner | D13, D14 | MERGED to next — proposals await owner (BOARD) |
| E2 | Full gate, regression list run, playtest build + one big PLAYTEST-QUEUE | D71 | todo |

Order: A1+A2 → (B1 ∥ D0) → (B2 ∥ C1) → B3 → (B4 ∥ C2) → C3 → C4 → C5 → D1 (∥ D2 art) → D3 → F1 → E1 → E2.

Step-number ranges (C4: smoke 161-170, shots 160-169, bot v=9) (avoid scenario clashes): smoke C1 100-112, C5 113-121, C2 133-141; shots UI 80-89, B3 90-97, C2 120-128, B4 140-149, C3 150-159, C4 160-169, D1 170-199.

## F1 packets (from the read-only audit, 2026-10-15; evidence lines were at next aebc9db)

| # | Packet | Files | Risk | Status |
|---|---|---|---|---|
| R1 | Fairer randomness D117-D121, D123, D125 (+ sim) | scr_loot, scr_combat, scr_status, scr_save, sim.py | - | MERGED to next |
| R1b | Focus-loss pause D122 + odds text D124 | scr_menu, scr_combat, scr_status, obj_ui_controller, workbook | low | MERGED to next |
| FIX-diff | Title still offers Easy/Normal/Hard after New Game (D35 leftover) | scr_menu (title) | low | in flight |
| F1a | Input_Init + ItemDB passives re-run on every call -> run once | scr_input, scr_db_item | low | MERGED to next |
| F1b | Text scale / Ui_Metrics recomputed per call -> cache per layout+language | scr_player, scr_menu, scr_localization | med-low | todo |
| F3a | Notice popup -> Ui framework, then delete dead slot save menu (~600 lines) | scr_save_menu, scr_menu, obj_ui/obj_start/obj_game controllers, scr_save | med | todo |
| F1c | Menu draw re-measures rows / rebuilds tab icons every frame -> cache | scr_menu | low-med | todo |
| F3b | Unreachable-code sweep: 62 dead functions, ~20 unused macros, P audio-debug key in obj_sfx_manager | many (split audio/input vs rest) | low | MERGED to next (F3b-1, F3b-2; -445 lines) |
| F1d | Battle HUD per-frame duplicates, credits layout x2/frame, icon lookups, sight-ring math | scr_combat, scr_dialogue, scr_fx, scr_enemy | low-med | todo |
| F2a | Presentation clocks frames -> ms (transitions, boot logo, cutscene holds, credits) | scr_room_transition, obj_start_controller | med | MERGED to next |
| F2b | Battle message/shake + dialogue/typewriter/input-lock clocks -> ms | scr_combat, scr_fx, scr_dialogue, scr_menu, scr_input | med-high (feel) | MERGED to next |
| F4 | Palette literals -> UI_C_*, shared helpers, global sprawl, wording/sound consistency (F4d needs owner) | many | varies | after E2 |

Leave frame-counted: player grid step, enemy AI pacing, fx ages, cine pan (gameplay feel).

## Improvement-mode queue (after E2, evidence-based)

| # | Item | Source | Status |
|---|---|---|---|
| I1 (merged) | `lint_hardcoded_text.py` exits 1 on the `"{n}"` templates at scr_menu.gml ~858/882 (F1c): add `{n}` to its allow list or route through Loc_T | regression run | todo |
| I2 (merged; found R-022, fixed) | Automate regression gaps: R-007 (mini boss 60 s, fight within 4 tiles, stays removed), R-017 (dialogue end on floor 5 / 9.5), R-022 (status tick on a failed Run turn), R-028 (no cutscene background after Continue), R-036 (death from a status tick / in a transition) | regression run | todo |
| I3 (merged) | R-021 negative-control plants for a syntax error and an unknown function | regression run | todo |
| F2a / F4a | ms clocks for transitions/credits; palette literals | F1 audit | MERGED to next (after the playtest build) |
| I4 | Opus review 2 (fc886c7..8762d9b): no real bugs. Nits: run_tests.ps1 `$Plant` Position=0 steals positional `-Mode`; text-lint label reads the cumulative fail flag; unknownfn plant anchor -1 check. Possible: after a slow room load the black hold lasts 1 step instead of 2 (fade-in 1 frame earlier) — fix only if the owner sees a one-frame pop (Q-010) | Opus review 2 | nits: todo |

## Round 2 (owner grill 2026-10-16: D126-D138) — Sonnet packets, max 2 at once, Opus reviews + gates

| # | Packet | Decisions | Main files | Status |
|---|---|---|---|---|
| G1 | Marble bag everywhere: status chances, enemy move deck, fixed heal/tick amounts, gold bag, Scrounger | D126 | scr_db_skill, scr_db_enemy, scr_db_item, scr_status, scr_loot, scr_save | MERGED to next |
| G2 | Main menu refresh: splash, living background, Continue card; menu keeps the shared framed style | D128 | scr_menu (Title_*), obj_start_controller, workbook | MERGED to next |
| G3 | Battle game feel: death pop, hit sparks + per-hit freeze, heavier player hurt + HP lag bar, hit jolt + enemy recoil, crit/BREAK zoom punch, subtle low-HP heartbeat | D138, D139 | scr_combat, scr_fx, obj_battle_controller | MERGED to next |
| G4 | Class chest guard | D127 | obj_room_transition / scr_interact, workbook | MERGED to next |
| G5 | Echo after class pick, filtered | D130 | scr_room_state, scr_menu (cards/echo) | MERGED to next |
| G6 | Map juice: chest burst, item rise, level-up sparkle, gold tick, step squash | D138 | scr_interact, obj_player, scr_fx, HUD | MERGED to next |
| G7 | Battle speed-up hold + damage preview | D134, D135 | scr_combat | MERGED to next |
| G8 | Controller rumble + setting; save-on-close code + IDE step | D136, D132 | scr_input, settings, obj_game_controller | MERGED to next (Perfect detection fixed at merge for the D138 per-hit freeze) |
| G9 | Run stats at run end + history | D137 | scr_room_state, run-end screen | in flight |
| G10 | One UI style audit: every screen uses the shared frame/highlight/cursor/fonts/colours/spacing/motion/sounds; fix any screen that differs (incl. G2/G3/G6 additions) | D129 | Ui_* framework + every screen | todo (after G2) |
| G11 | Consistency pass: Title Case, one word per meaning, one sound per action, one dim | D133 | workbook, scr_menu, scr_combat | todo (last) |
| — | D131: no milestone unlocks (docs only) | D131 | — | done (decision) |

## Round 3 (owner playtest of 943ce6d, 2026-10-16: D140-D156) — Sonnet packets, max 4 at once

| # | Packet | Decisions | Main files | Status |
|---|---|---|---|---|
| H1 | One menu (Esc = Tab, System tab, one Settings, instant apply + "Keep this?" revert) + menu in battle with quit-before-fight | D140, D141 | scr_menu (TabMenu/Pause/Settings), obj_ui_controller, run save | todo |
| H2 | Shared Yes/No confirm pop-up for every important action | D156 | scr_menu (Ui framework) | todo (after H1) |
| H3 | Review-4 fixes (enemy deck keeps cards, multi-hit preview, rumble Perfect flag, BREAK flag) + elites from floor 3 + press toward the exit leaves | D142, D145, review 4 | scr_db_enemy, scr_combat, scr_input, obj_battle_controller, scr_loot, obj_room_transition | todo |
| H4 | Level-up shows class growth; free point may go to Max HP/MP; balance re-check | D143 | scr_levelup, level-up screen, sim | todo |
| H5 | Skill memory; echo = discovered skills of the picked class; class select (Nobody greyed, sprite preview, ??? skills) | D144, D148 | scr_room_state, profile, class screen | todo |
| H6 | Cutscene skip (prompt after 1 s, skip at 2 s) + cutscene text in the shared dialogue box | D146, D156 | scr_input skip, scr_dialogue, obj_start_controller | todo |
| H7 | Notes picked up, read from a Notes list | D147 | note object code, scr_interact, codex | todo |
| H8 | Text & prompts: keyword highlights, status labels, device-aware prompts (arrows, controller glyphs), fewer battle hints, XP bar style, "Worn" header, Help stats page, full-HP bed/potion refusal sweep | D149, D150, D156 | Prompt_Rich*, HUD, scr_input prompts, help | todo |
| H9 | AI battle backgrounds (4) + contact sheet + IDE import checklist | D151 | art/, tools (ComfyUI) | todo |
| H10 | Seed input on New Game | D152 | title New Game flow | todo |
| H11 | Smarter map AI + hiding spots | D153 | scr_enemy, room data | todo |
| H12 | Writing overhaul (style guide + full rewrite) + small flavour choices | D154, D155 | workbook, scr_dialogue | todo |
| H13 | Elite outline follows the sprite; old death image reused; card/panel text overflow sweep with an automated "text fits" check | D156 | scr_loot fx, death scene, Ui text | todo |
| G10/G11 | One-style audit + consistency pass (last, after H1-H13) | D129, D133 | all screens | todo |
