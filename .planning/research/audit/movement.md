# Audit: movement, enemy AI, triggers, performance (branch v1.9, read-only)

Date 2026-10-14. Read only: no game files edited, game and Igor not launched. Room and sprite numbers below
came from parsing `rooms/*/*.yy` and `sprites/*/*.yy` with a throwaway Python script (scratchpad), not by running the game.
VERIFIED = the code (or the room/sprite data) proves it. SUSPECTED = plausible, needs a run or a log to confirm.

Key numbers: tile `GRID_TILE_SIZE` 16 (scr_macros.gml:139); view 160x144 shown at integer scale 3 to 5 (Display_CalcLayout,
scr_player.gml:1297); game speed 60 fps. Walls are invisible 16x16 `obj_wall` instances, non-solid objects, placed by hand
(`spr_blue`, bbox 0..15; 34 to 106 per room).

## 1. Player movement

Design: tile-stepped, four directions, no diagonals, one pixel per frame (`objects/obj_player/Step_0.gml`).

- VERIFIED: a step is 16 frames. A key press picks the last-pressed direction (`Input_MoveAction`, scr_input.gml:318), tests the
  whole target tile once (Step_0:61, `place_meeting(tx,ty,obj_wall)` and `obj_interactable`), then moves `x/y +-= 1` per frame
  (Step_0:75-80) and snaps at the end: `x = round(x/16)*16` (Step_0:100-101). Continuous hold chains tiles with no idle frame.
- VERIFIED: `move_speed` (obj_player/Create_0:40, `PLAYER_MOVE_SPEED_DEFAULT` 1) is never read by the player. Speed is hard-coded
  to 1 px (Step_0:75-80, 95). Changing the macro does nothing. A speed that does not divide 16 would also break the snap logic.
- VERIFIED misalignment source A, mid-step abort (Step_0:81-92): if `place_meeting` turns true mid-step the code undoes one pixel,
  sets `moving=false` and does NOT snap. The player is left at a non-multiple of 16. The next completed step rounds to the
  nearest tile, which can visibly jump up to 8 px. Cannot happen against hand-placed aligned walls (the up-front tile test catches
  them), so it needs a non-aligned or dynamic blocker; today only a moving/odd-sized `obj_interactable` could do it. SUSPECTED as a live cause.
- VERIFIED misalignment source B, save/load: `Save_*` stores raw `pl_inst.x/y` (scr_save.gml:276) and
  `obj_game_controller/Step_0.gml:55-56` writes them back unsnapped. F5 (`debug_save`, scr_input.gml:33) can be pressed mid-step,
  so a quick-save/load puts the player off-grid. The menu save path is probably safe because the UI blocks movement first.
- VERIFIED: `Player_EnsureDialogueSettle` and `Player_StartAutoResolveRecover` (scr_player.gml:169-221) lerp the player to the
  nearest grid cell after dialogue, auto-resolve and room arrival. They hide the problem but move the player up to 8 px,
  possibly into a wall tile (no wall check on the target).
- VERIFIED, safe: all room-placed instances are on the 16 grid (every `obj_wall`, `obj_room_spawn`, `obj_room_transition`,
  `obj_dialogue_trigger`, enemy, chest) except `obj_foreground_level_2` at (36,13). Battle return snaps
  (`GameState_SetBattleReturn`, scr_player.gml:1817-1822). Display is integer scaled and the camera is pinned to the player
  (`view_hborder` 79, `vborder` 71 set in `GameSettings_ApplyDisplay`), so there is no screen-space sub-pixel drift.
- VERIFIED, art mismatch risk: room sizes are not multiples of 16 (rm_floor1 321x175, rm_floor6 305x335, rm_floor7 274x275,
  rm_floor8 336x175, rm_floor9_5 514x207). Backgrounds are one painted sprite per room at (0,0), and the wall grid is placed
  by hand. If the painted tiles are not on a 16 grid at origin 0, the player will look misaligned against the art even
  though it is on the logic grid. SUSPECTED: needs a screenshot with the grid overlay (section 5, item 2).
- VERIFIED: spawn point and exit transition are the same tile in every room (e.g. rm_floor2 spawn (16,80) and
  `floor2_to_floor1` at (16,80), `require_dir=LEFT`). The player arrives standing on the exit and pressing back at once returns.
  Intended probably, but it is a bounce-loop trap and the player is also standing inside a trigger the moment the fade ends.
- Note: the sprite masks are `sprite[DOWN]` (bbox 2..13 for knight/archer, 0..15 for mage). That is fine for collision, but
  class-dependent hit-boxes mean trigger overlap begins 2 px later for knight/archer.

## 2. Enemy overworld AI

Files: `objects/obj_enemy/Step_0.gml`, `scripts/scr_enemy/scr_enemy.gml:358-508` (`EnemyAI_Update`), tuning in
`scr_db_enemy.gml` (`ai:` structs) and macros `ENEMY_*` (scr_macros.gml:118-145).

How it works: square-box detection, then greedy single-axis chase, one 16 px step per decision, `think_rate` frames between decisions.
No pathfinding anywhere (grep for `mp_grid`, `mp_potential`, `path_` finds nothing).

Why enemies get stuck, in order of certainty:

1. VERIFIED, greedy axis with no fallback (scr_enemy.gml:460-474): the enemy picks the axis with the larger |dx| or |dy| and tries
   only that direction. If a wall, rock, tree, grave or chest blocks it, `EnemyAI_CanStep` fails, nothing moves, and the same
   decision repeats every `think_rate` frames forever. Any obstacle between enemy and player on the dominant axis freezes the chase.
   Ties (|dx| == |dy|) always pick vertical.
2. VERIFIED, detection ignores walls (scr_enemy.gml:415): a square box of `scan_radius` px (32 to 88). The enemy goes ALERT through
   walls, then walks into them (cause 1). `forget_time` then keeps it ALERT for 15 to 80 more frames.
3. VERIFIED, leash does nothing useful (scr_enemy.gml:397-402): beyond `leash_radius` it only flips state to IDLE. IDLE wander is
   unbiased `choose(UP,DOWN,LEFT,RIGHT)` (line 446). Enemies never walk home, so they drift away from their post. `home_x/home_y` is stored (Create_0:37-38) and never used for movement.
4. VERIFIED, the blocker test is one pixel, not one tile (`EnemyAI_CanStep`, scr_enemy.gml:380-386; wander at 449, chase at 470).
   For enemy sprites whose bbox is smaller than 16 px the 1 px test passes while the move itself will hit the wall 1 to 3 px
   later. Bboxes (from sprite .yy): stranger (1,1,14,15), killer_plant and mad_whisp (1,0,14,15), snake (1,1,15,15),
   spider top margin 3, slime/ghost_sword top margin 2, dire_wolf 1. Mid-move block (line 492-502) sets `moving=false` and the enemy is left off-grid. Enemies never snap to the grid at the end of a step (the player does, enemies do not).
5. VERIFIED, off-grid enemies from the save path: `RoomState_Save` stores enemy `x`,`y` whenever the room is left or a
   battle begins (scr_room_state.gml:246-251, called from `EnemyPersist_BeginEncounter` and the room-transition
   collision). `RoomState_ApplyInstance` writes them back raw and zeroes `moving` (scr_room_state.gml:228, 233-240). An enemy caught
   mid-step is restored mid-tile and stays off-grid for the rest of the room. For a full-width bbox (final_boss, mini_boss,
   slime x) a 1 px offset overlaps the neighbouring wall column, so ALL four directions fail the 1 px test and the enemy is permanently wedged.
   (SUSPECTED for fractional speeds 1.1/1.15/1.2/1.3: the last step is clamped so errors are ~1e-15, probably harmless.)
6. VERIFIED, no enemy-enemy or enemy-door awareness: `EnemyAI_CanStep` tests only `obj_wall`, `obj_interactable` and
   `obj_room_transition`. Enemies stack on one tile, and a chasing group collapses into one sprite.
7. VERIFIED, frozen by design: `cine_lock_count > 0` makes Step_0 exit immediately (Step_0:2-9). The three cinematic triggers
   (rm_floor1, rm_floor5, rm_floor9_5) lock their enemy until the trigger fires. `DialogueTrigger_CleanupCinematic` releases it
   only when `cine_dialogue_started && !dialogue_active` (scr_player.gml:~600). If `DialogueDB_Get(id)` returns nothing the
   dialogue never starts and the enemy plus the player input lock stay frozen. SUSPECTED, needs a missing-id test.
8. VERIFIED, flee loop: the enemy Step event triggers an encounter whenever the enemy overlaps the player and `battle_cooldown <= 0`
   (Step_0:50-53). After a flee the player returns to the same tile (snapped `return_x/y`) and the enemy was saved where it stood.
   After 60 frames (`BATTLE_COOLDOWN_FRAMES`, scr_macros.gml:115) they overlap again and re-engage. No push-away exists (grep of `return_x`/`battle_cooldown` finds none). SUSPECTED as playtest-visible; the check in 5 settles it.
9. `ai_stationary` (only `obj_mini_boss`, Create_0:5) skips all movement but still starts the encounter when the player is inside
   the square `scan_radius` (Step_0:40-47), through walls. That is a trigger-radius, not contact, rule.

Per-step cost (see section 4): each enemy builds a context struct every Step (`EnemyAI_BuildContext`, line 361), runs about
8 `variable_instance_exists` checks, one `place_meeting` vs `obj_player`, and while moving 3 `place_meeting` calls per pixel.
Under 10 enemies per room this is microseconds. It is not a frame-time problem. It is a correctness problem.

## 3. Triggers

### Room transitions (`obj_room_transition`, Collision_obj_player.gml)
- Detection: collision event with `obj_player`, 16x16 `spr_red` mask, so it fires on the FIRST overlapping pixel (the player is
  1 px into the tile). `require_dir` and `require_move` gate on `other.move_dir`/`other.moving` (lines 8-19).
  Cannot be missed by speed: the player moves 1 px/frame and overlaps for 16+ frames. VERIFIED.
- VERIFIED double-fire: there is no `if (Transition_IsActive()) exit;` at the top (compare `obj_enemy/Collision_obj_player.gml:2`).
  After the fade starts, `UI_IsBlocking()` freezes the player inside the tile, so the collision fires EVERY frame of the
  12 frame fade. Each call runs `RoomState_OnRoomExit()` (loops all enemies, rebuilds persist structs, Collision:30) and
  `Transition_RequestRoomFade` returns false (Transition_Begin guard, scr_room_transition.gml:303). For the ending/cutscene
  branch `Transition_RequestCutsceneById` overwrites `gs.pending_cutscene_id` each frame (scr_room_transition.gml:398-402). Harmless today, wasteful, and a hazard if a second transition tile is overlapped at the same time.
- VERIFIED: the exit snapshot is taken at first overlap, mid-step, so enemy positions saved are not tile-aligned (see 2.5).
- Arrival (`RoomTransition_Apply`, scr_room_transition.gml:49-89): player placed on the spawn, then `Player_StartAutoResolveRecover(...,3)`.
  Works, but if an obj_room_spawn is ever off-grid, the 3 frame lerp pulls the player to the nearest tile with no wall check.
- Room db coverage is complete for current rooms (`RoomDB_Init`, scr_room_db.gml:1-47); a missing spawn only logs a warning
  (`RoomTransition_Warn`) and drops the player at (0,0) in the worst case (scr_room_transition.gml:66).

### Dialogue / cinematic triggers (`obj_dialogue_trigger`)
- Detection: collision event sets `pending_trigger` (Collision:1-10). Step waits for the player to finish the tile
  (`pending_wait_for_settle`), the cooldown, and `!UI_IsBlocking()`, then starts dialogue and optional camera pan
  (Step_0:1-54, `DialogueTrigger_StartCinematic` scr_player.gml:471). Size comes from instance scale: 1x2, 4x1, 1x6 tiles.
- VERIFIED: it cannot be skipped at walking speed. It can fire a few frames after the first overlapping pixel (waits for the end
  of the step), by which time the player is fully inside the trigger rect. That is the intended behaviour.
- VERIFIED: trigger is invisible (`visible = false`, Create_0:68), so the owner cannot see it. This is the "I want to see" request.
- VERIFIED gate: it ignores overlap while the UI or a transition is blocking (Collision:5). Because the collision repeats each
  frame this self-heals once the fade ends. Fine.
- SUSPECTED soft-lock: `cine_wait_dialogue_end` (scr_player.gml:~517) only clears when a dialogue was seen to start
  and then end. A trigger with an unknown `dialogue_id` or empty lines holds `cinematic_input_lock_count` forever (UI_IsBlocking, scr_player.gml:742).
- `trigger_once` state is saved per persist id (Step_0:111) and re-applied on room load, so re-entry does not re-fire. Good.

### Interactables (`obj_interactable` and children: chests, barrels, graves, beds, doors)
- Detection (scr_interact.gml:17-50): the facing tile centre is tested with `position_meeting(cx,cy,inst)` after rounding the
  player to the grid. This is a good design: deterministic and grid based. It requires `Player_CanAcceptMove` (not mid-step), so a press during a step is ignored (no buffering, `Input_ActionBuffer` is a stub, scr_input.gml:356).
- VERIFIED: every interactable runs `Interact_Handle(self)` every Step (objects/obj_interactable/Step_0.gml:1), including a
  `GameState_Get`, `Action_CanAct`, `UI_IsBlocking` chain. `Interact_GetTarget` is cached once per input frame, so the scan is O(n) once, not O(n^2). Cheap (rm_floor6_5 has 15 graves).
- Invisible blockers: `obj_grave` and `obj_tall_grass` have `visible=false` and still block the player and enemies as interactables.
  The player collides with things the owner cannot see.

## 4. Performance

Honest read: at 160x144, a few instances and no surfaces, nothing here should threaten 60 fps. The items below are real
waste, ranked by how much work they do per frame. Measure before spending time (section 5, item 8).

1. VERIFIED, `obj_sfx_manager/Step_0.gml` does debug-style bookkeeping every frame, in ALL rooms: 15 `variable_global_exists`
   re-creations (lines 1-15, the CONCERNS.md item), `audio_group_is_loaded`, then a display self-check every frame
   (lines 92-160): `display_get_width/height`, `window_get_width/height`, camera getters, `GameSettings_Ensure`, a fresh
   `Display_CalcLayout` struct, six `view_*` compares. Also `variable_struct_get_names(global.bgm_mix_handles)` allocates an
   array every frame (line 173), and the P key is polled raw (line 25), the same key as the game's `debug_toggle`
   (scr_input.gml:27, 42). Pressing P toggles BOTH debug modes at once.
2. SUSPECTED and possibly the worst: the self-check marks the view "bad" when `cam_x < 0 || cam_x > room_width - cam_w`
   (Step_0:118-120). `rm_floor6_5` is 144x144, narrower than the 160 px view. If the camera ever sits at a negative x,
   `view_bad` is true every frame, so `GameSettings_ApplyDisplay` runs every frame. That function calls `window_center()`,
   `window_set_showborder`, `application_surface_draw_enable`, `display_set_gui_maximise` and `camera_set_view_pos`
   (scr_player.gml:1381-1472). That would cost frame time and fight window dragging. Check by counting calls (item 7 below).
3. VERIFIED, `Input_Update` (scr_input.gml:240-304) each frame: `variable_struct_get_names(inp.bindings)` (array of ~30 names),
   one `{held, pressed}` struct per action (line 290, ~30 per frame), plus optional gamepad polling. About 2000 small structs per second of GC churn. Also the guard is
   `last_step_time == current_time` (ms), so two game steps in one millisecond skip an input update (SUSPECTED, uncapped speeds only).
4. VERIFIED: `EnemyAI_BuildContext` allocates one struct per enemy per step (scr_enemy.gml:361). the enemy Step event uses
   `variable_struct_exists` chains for the dialogue-active test every frame (Step_0:14-20).
5. VERIFIED: `RoomState_OnRoomExit` runs once per frame for the whole fade (see 3, double-fire), each time looping all enemies.
6. VERIFIED: no `with(all)`, no per-step `ds_*_create`, no surfaces, no `instance_find` loops in the overworld hot path
   (`instance_find` appears only in Draw_64 of the UI controller and one-shot code). `ds_map_create` leaks noted in CONCERNS.md
   are boot-time only (obj_sfx_manager/Create_0:60-63, scr_dialogue.gml:3).
7. `obj_wall` (up to 106 per room) has no events and is invisible, so it costs nothing per frame except in `place_meeting`
   queries. Each moving enemy does 3 queries per pixel; the player does 2 per pixel. Unmeasured.
8. Frame budget unknown: no profiler data exists. Section 5 item 8 gives the cheap way to get it.

## 5. Recommended fixes, ranked by impact (impact on the owner's three complaints first)

Each item: change, check (Rule 1: written first), size. S = under 60 changed GML lines, M = 60 to 150, L = split into packets.

1. Enemy navigation: replace greedy chase with grid A* plus enemy-enemy avoidance. Size L (3 packets). See design below.
   Check: `Test_Suite_Nav` (pure, no room needed, `mp_grid_*` works headless). Cases from ASCII maps: path around a wall block
   exists; no path returns empty; two enemies given the same goal never choose the same next cell (reservation table);
   a one-tile corridor with an enemy in it yields a path that waits or routes around. Then a scenario (item 9).
2. Debug overlay "show triggers, paths, grid" (the owner's "I want to see"). Size M. Do this FIRST, because it makes 1, 3 and 4
   verifiable by eye. See design below. Check: overlay toggles on a key and
   draws counts per category into the existing text block, so `Scenario_Check("overlay_draws_N_transitions", ...)` can assert it in `-shots`; plus owner checklist.
3. Enemy grid discipline. Size S. (a) Snap to grid at the end of every enemy step (copy the player's `round(x/16)*16`);
   (b) in `RoomState_ApplyInstance` snap `x,y` for enemies; (c) make `EnemyAI_CanStep` test one full tile (16 px) rather than 1 px.
   Check: unit test `Enemy_SnapToGrid(0.4, 15.6)` returns (0,16); scenario places an enemy at (3,5) in rm_floor1 and asserts it is
   on the grid after `think_rate` frames and is not wedged.
4. Player grid discipline. Size S. After a mid-step abort (Step_0:81-92) and after `load_spawn_x/y` (Step_0:55-56) snap
   to the grid; make `Player_StartAutoResolveRecover` refuse a target tile that overlaps `obj_wall`. Delete the dead `move_speed`
   or make the step use it with a divisor-of-16 guard (`assert 16 mod speed == 0`).
   Check: bot scenario holds right for 200 frames and asserts `x mod 16 == 0` whenever `moving == false`
   (needs the scenario to push the move key into `move_order`, a small `Scenario_Hold(action, frames)` helper, since
   `Scenario_Tap` only writes `held/pressed` and `Input_MoveAction` reads `move_order`, scr_input.gml:318-327).
5. Transition and trigger robustness. Size S. Add `if (Transition_IsActive()) exit;` at the top of
   `obj_room_transition/Collision_obj_player.gml`; move `RoomState_OnRoomExit()` after a successful `Transition_Begin`. Give
   `DialogueTrigger_*` a watchdog: if a cinematic has not progressed in N seconds, clean up and log. Check: scenario walks into
   the floor1 to floor2 exit and asserts `RoomState_OnRoomExit` ran exactly once (counter) and the room changed.
6. Enemy leash and flee loop. Size S. IDLE with distance to home > 0 walks home (via item 1 paths); after a flee push the enemy
   (or the player) one tile apart before cooldown ends. Check: scenario flees from the slime, waits 120 frames, asserts room is still the overworld.
7. Perf hygiene. Size S to M. Move the 15 global defaults and the display self-check from `obj_sfx_manager/Step_0` into one-time
   init plus an event-driven check (window resize, room start). Rebind the audio debug key away from P. Cache the binding names and reuse the
   per-action state structs in `Input_Update`. Check: call-counter globals: `global.dbg_applydisplay_calls` incremented in
   `GameSettings_ApplyDisplay`; a `-shots` run in rm_floor6_5 for 120 frames asserts the counter is under 3.
8. Profile first. Size S. In the overlay (item 2) show `delta_time` average, `instance_count`, `instance_number(obj_enemy)` and
   `Scenario`-style counters. Owner checklist: open rm_floor6 (106 walls, 5 enemies) and report the number.
9. Scripted scenario for the whole loop. Size M. A new `Scenario_StepMove` run under the bot runner (`-Only` ValidateSet in
   `tools/automation/run_tests.ps1:13` also needs the new name): walks floor1 start to exit, fires the slime trigger,
   asserts enemy chase reaches the player around an obstacle, takes the transition once, arrives on grid in floor2. Needs `Scenario_Hold`.

### Pathfinding approach (item 1), suited to a 160x144 tile game
- One `mp_grid` per room, cell 16x16, size `ceil(room_width/16)` by `ceil(room_height/16)`. rm_floor1 is 21x11 and rm_floor6 is 20x21, so
  at most a few hundred cells: a full A* costs microseconds.
- Build once per room AFTER `RoomState_Apply` (objects removed by persistence are gone by then). The hook is in
  `obj_game_controller/Step_0.gml` right where `RoomState_Apply(room)` runs (lines 9-16). Mark `obj_wall`, `obj_interactable`,
  `obj_room_transition` (enemies must not park on exits) via `mp_grid_add_instances(grid, obj, false)`. Rebuild when an
  interactable is destroyed (barrel broken) via a single `Nav_Dirty()` call.
- Replace the chase block (scr_enemy.gml:456-475) with: every `think_rate` frames, if ALERT and the player cell changed or the
  enemy was blocked, compute `mp_grid_path` from the enemy cell to the player cell; take only the first waypoint; convert to
  a direction; keep the existing 16 px tile step and ADD a snap at the end. Behaviour stays tile-stepped, the AI just chooses well.
- Detection by path length instead of a square: alert when `path_length <= scan_radius * 1.5` (or a `collision_line` check against `obj_wall`
  for cheap line of sight). That removes chasing through walls and the "alert then stuck" cases.
- Enemy-enemy avoidance: keep `global.nav.reserved` (map cell -> enemy id) of each enemy's current and target cell. Before a path
  query, temporarily `mp_grid_add_cell` the reserved cells of OTHER enemies, run the query, then `mp_grid_clear_cell`. If the next cell
  is reserved at move time, wait one think tick (never push). At most 2 repaths per frame, staggered by the existing `think_delay`.
- Wander picks only a free neighbour cell (`mp_grid_get_cell`), never a random direction that then fails. Leash and flee: IDLE and
  distance > 0 paths home.
- Stuck watchdog (belt and braces, also for the debug view): if an enemy has had `moving=false` while ALERT for more than 60 frames,
  repath once, then snap to the nearest free cell and log `[NAV] stuck enemy_uid=... room=...`.
- Player stays as it is (tile-stepped); only add the snap fixes in item 4.

### Debug overlay (item 2): where and what
- Where: `obj_sfx_manager/Draw_64.gml` already draws the debug text when `global.debug.enabled` (line 1-3). Convert world to GUI
  coordinates there (`(wx - camera_get_view_x(cam)) * display_get_gui_width() / camera_get_view_width(cam)`), so NO new object event
  is needed. A new Draw event would require an IDE `.yy` edit, which AGENTS.md Rule 4 forbids for agents.
- Toggle: new binding `debug_overlay` (suggest F3; free: used keys are P, F5, F9, L, K, J, U, O) added next to the others in
  `scr_input.gml:33-39, 46-52`, handled in `Debug_Update` (scr_debug.gml:164-176) and stored as `global.debug.show_overlay`, off by default and cleared by `Debug_Toggle` like `display_metrics`.
- Draw list (colour, label):
  - Player: current grid cell outline, and `x mod 16 / y mod 16` text that turns red when non-zero while `moving == false`
    (this makes "not aligned" visible immediately), facing-tile marker (the interact probe point from `Interact_FacingDistance`, scr_interact.gml:23-50).
  - `obj_room_transition`: red rect, label `transition_id` plus an arrow for `require_dir`.
  - `obj_room_spawn`: green cross plus `spawn_id`.
  - `obj_dialogue_trigger`: yellow rect (scaled size via `bbox_*`), label `dialogue_id`, `triggered` and cooldown, dim when consumed.
  - `obj_interactable`: blue rect, bright when it is the current `Interact_GetTarget`.
  - `obj_wall`: faint grey (toggle sub-layer); nav grid blocked cells.
  - Enemies: scan square (`scan_radius`), leash circle, `ai_state` text, `move_dir` arrow, `x mod 16` red when off-grid, the planned path polyline
    (`inst.dbg_path`), reserved cells, and a "STUCK" tag from the watchdog.
  - Corner text block: `fps_real`, `instance_number(obj_enemy)`, nav repaths per second, `GameSettings_ApplyDisplay` call count.

## Suggested order of work
1. Overlay (2) and profile counters (8): safe, no behaviour change, makes the rest checkable.
2. Grid discipline (3, 4) and the transition guard (5): small, high chance of fixing "not aligned" and some "stuck".
3. Navigation (1) with the pure unit tests first, then the scenario (9).
4. Perf hygiene (7) once the counters show where the time goes.

Open owner questions (grill-me material, not guesses): should an enemy touching the player always start a fight (flee loop, 2.8)?
Should arriving in a room put the player ON the exit tile or one tile in front of it (1)? Is the painted background meant to sit on a 16 px grid (1)?

## Not verified (needs a run, deliberately not done)
Real fps and frame time; whether `view_bad` loops in rm_floor6_5; whether enemies actually wedge after a battle return; whether
art aligns to the logic grid; whether the flee loop reproduces. Each has a counter or screenshot check named above.
