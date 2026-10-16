# Bug hunt, session 7: the map and the world (read-only, build 7f4d08e in DD-Project-GameMaker-wt/build)

Area: room lighting (Light_*), extra torches, sun spots, enemy map AI (sight, hearing, "?", hiding, no camping), notes, interactables, room transitions, merchant, Stranger, map effects, movement.
Method: code read and hand traces; I also parsed the room .yy files with a script (walls, interactables, exits, spawns) to check every extra torch cell, hiding cell, note tile, merchant spot and exit/spawn pair, and to flood-fill each room from its spawn. Nothing was built or run. Line numbers are from the build folder.
4 findings (1 x P2, 3 x P3). Not repeated: anything in bughunt-session5/6 files, review-opus-session6, ISSUES.md.

Checked and found sound (no finding): all 11 extra torch cells are wall cells with a free floor cell below them, none on an exit/spawn/chest; Light_Sources match the art fire stands and torches in every room; hiding cells, note tiles and the three merchant spots are free, reachable, and the merchant cell does not cut any room in two; every exit has its spawn and the spawn_id pairs match scr_room_db; extra torches get an auto persist id, so a torch put out stays out after a battle or a Continue; Light_RoomSources re-reads per room so no stale room; Vis_Scan is the standard shadowcast; Nav grid, reservations and prune are consistent; Shuffle_ApplyRoom is deterministic after an autosave and a Continue.

## 1. P2: the player's brightness pulses on every step in a dark room (the step squash is drawn after the darkness)

- **Where:** `scripts/scr_enemy/scr_enemy.gml:877-884` (World_DrawFx: Light_DrawPass first, MapFx_DrawWorldFx last), `scripts/scr_fx/scr_fx.gml:1035,1039-1048` (MapFx_DrawPlayerSquash draws the player's sprite at the end of the pass), `objects/obj_player/Step_0.gml:208-209` (`squash_on = Settings_ShakeOn() && age < FEEL_SQUASH_MS (120 ms)`, `visible = !squash_on`).
- **Repro:** default settings (Screen shake on), floor 3 or deeper (darkness 0.28, no torch near). Walk across the room. For the first 120 ms of each 267 ms tile step the plain sprite is switched off and the squashed copy is drawn on top of the darkness at full brightness; for the rest of the step the normal sprite is drawn under the darkness. The player flips bright, dim, bright, dim about 4 times a second while walking, and is almost always bright while running (a step is 133 ms). Standing still he is dim. Shake off: no flicker.
- **Violates:** D159/D164 and the light pass's own header ("a figure standing in the dark must look like it"). It is the same class as review-6 finding 4 (elites redrawn after the darkness), which was fixed for the elite but not for the player's squash.
- **Fix idea:** call MapFx_DrawPlayerSquash before Light_DrawPass in World_DrawFx (and keep the rest of MapFx_DrawWorldFx after it), so the squashed sprite is darkened like the plain one.

## 2. P3: the post-Run grace period drains while a menu, dialogue or fade is up, so healing after an escape restarts the fight

- **Where:** `objects/obj_player/Step_0.gml:17-19` (`battle_cooldown -= 1` runs before the `UI_IsBlocking()` exit at line 60), `objects/obj_enemy/Step_0.gml:44,53,127` (an enemy engages again as soon as `battle_cooldown <= 0`), `scripts/scr_combat/scr_combat.gml:1764-1765` (Run: SetJustReturned, then a 12 + 2 + 14 frame room fade), `objects/obj_player/Create_0.gml:10-17` (cooldown 60 set in Create). `objects/obj_game_controller/Step_0.gml:77,90` refills the cooldown during the fade for a Continue (D141) but there is nothing like it for a battle return.
- **Repro:** fight a slime, Run succeeds. The room fade-in (about 16 frames) already eats a quarter of the 60 frames. Press Tab, Items, drink a potion (takes a second or more). The cooldown is 0 when the menu closes; the slime is still on the player's tile (the fight began on contact and the return position is the contact position), so the next frame is a new encounter. Same with a dialogue (reading a note's chest line) after the escape.
- **Violates:** the intent of the grace window ("enemies do not chase or engage", obj_enemy Step line 126) and D67 (escape must be possible).
- **Fix idea:** decrement `battle_cooldown` only when the player is free (move the decrement below the `UI_IsBlocking()` / recover exits), and refill it to BATTLE_COOLDOWN_FRAMES when the transition ends, like `load_cooldown` does.

## 3. P3: the Stranger is exempt from the arrival clean-up, so on floors 7-9 he can still camp the doorway (D158)

- **Where:** `scripts/scr_enemy/scr_enemy.gml:1653` (`if (... is_boss || enemy_id == ENEMY_STRANGER) continue;` in Enemy_ArrivalFix). The comment above it (line 1642) says only "bosses and story enemies (cine_id)"; the Stranger instances in rm_floor7/8/9 have no creation code and no `cine_id`.
- **Repro:** floor 8, walk up to the Stranger (home 6,3, sight 5, chase 0.9, so you can outwalk him), leave through (2,1) with him a few tiles behind. RoomState_OnRoomExit saves him where he stood. Come back through the same exit: every other enemy within 4 tiles of an exit or 3 of the arrival tile is put back; the Stranger is not. He stands 1-4 tiles from the arrival tile, sees you at once, "!" and chases. Same in rm_floor7 and rm_floor9.
- **Violates:** D158 ("on room arrival no enemy may stand within ~3 tiles of the arrival tile"; "an enemy that chased the player to an exit is placed back"). D158 has no exception for him.
- **Fix idea:** drop `|| enemy_id == ENEMY_STRANGER` from Enemy_ArrivalFix (Shuffle may keep him fixed; his place is only moved on a clash with an exit).

## 4. P3: the arrival clean-up is not part of the saved state, so Continue brings the camper back

- **Where:** `scripts/scr_room_transition/scr_room_transition.gml:89` (Enemy_ArrivalFix moves live enemies and their home), `objects/obj_game_controller/Step_0.gml:36` (Run_AutoSave right after, writing `gs.persist` as it was at the last room exit), `scripts/scr_menu/scr_menu.gml:822-834` (Menu_QuitToTitle writes the run first and only then calls RoomState_OnRoomExit). Nothing calls RoomState_Save after the fix, and Continue starts no transition with a spawn, so the fix never runs again.
- **Repro:** chase an enemy to an exit, leave, come back (it is moved away), Esc > Quit to title > Continue. The room loads with the enemy record from the last exit: back beside the doorway and the player on or next to the arrival tile.
- **Violates:** D158 together with D132/D46 (a Continue should show the same room).
- **Fix idea:** call `RoomState_Save(room)` at the end of Enemy_ArrivalFix when it moved anything (and in Menu_QuitToTitle before Run_AutoSave, not after).

## 5. P3: a torch, chest or barrel that was used is saved with a raw `sprite_index` number; the number changes when sprites are added, so a Continue across builds shows the wrong picture

- **Where:** `scripts/scr_interact/scr_interact.gml:310,426` (RoomState_SaveInstance(_inst, ["swapped","sprite_index"], ...)), restored by `scripts/scr_room_state/scr_room_state.gml:255` (`variable_instance_set(_inst, n, ...)`) and written into run.sav (`levelData: gs.persist`, scr_save.gml:909).
- **Repro:** the sprites in the .yyp are alphabetical (DD-Project.yyp: ... spr_battle_bg_*, spr_blue, spr_merchant_idle_strip, spr_red, spr_yellow, status_strip, stranger_*, torch_asset_moving, torch_asset_off ...). Put out a torch on floor 6, Quit to title. Build a version that adds a sprite sorting before "torch" (the planned spr_battle_bg_boss, for example) and Continue from the same save folder (the owner does this between builds): the extinguished torch is drawn with whatever sprite now has the old number. `swapped` is true so the light is off, only the picture is wrong. The same for every sprite that sorts after the new name.
- **Violates:** D16 / the save-systems rule "never serialise engine asset ids"; D132 (Continue shows what you left).
- **Fix idea:** do not save `sprite_index`; in RoomState_ApplyInstance, when `swapped` is true and the instance has a `swap_sprite`, set `sprite_index = swap_sprite`. Keep reading the old key and ignore it.

## Minor notes (not counted)

- Extra torches in rm_floor1 (10,2), rm_floor3 (5,2), rm_floor7 (8,1) and (10,10) are nearer than the 4 tiles that the comment on `Light_ExtraTorches` promises (rm_floor7 (10,10) is 2 tiles from the art torch at (8,10)); cosmetic.
- Menu_QuitToTitle (scr_menu.gml:822-834) saves before RoomState_OnRoomExit, so enemy positions are never in the quit-to-title save of a room's first visit (they are re-dealt from the seed, which is fine).
- A direction tapped in the last frames of a step and then a Tab that opens the menu on the settled frame leaves `buf_dir` fresh (the buffer ages only outside UI), so closing the menu can walk one unasked tile. Needs a tap and a menu key in the same step; very rare.
