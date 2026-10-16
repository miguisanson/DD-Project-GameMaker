# Review: game code merged tonight (8bfb38c..0f58531, branch `next`)

Reviewer: Opus, read-only. Scope: `scripts` + `objects`, excluding the scr_test/scr_debug harness, which was read only to check what tests assert.
Line numbers are from `E:\Github_Projects\DD-Project-GameMaker-wt\next` at 0f58531. Every finding below was confirmed by reading the code; none was run.

Checked with no finding: the profile v1 -> v2 migration (fields kept, a v1 `.bak` is accepted, an older build sees v2 as "newer" and locks it), the atomic writes, Run_Finish skill memory, how choices are stored (`unlocks.choice_<id>` = 1/2 survives JSON), the chained boxes (Dialogue_OnClose, ChoicePick closes before the callback, the open-frame lock), the Stranger loot record (carry, restore, give back, removed on a win), the Brace / Take Aim / Muscle Up ticks (no other caller of those statuses), and the menu that is read-only in a fight (no other tab changes anything). For the extra torches: no duplicates on re-entry, every cell is a wall cell, an "Instances" layer exists in every room that gets one, and a put-out torch persists through its auto persist_id because RoomState_Apply runs in Step, after the Create that places it. Also checked: the HUD frame bracket around `chip_rects`, the markup parser loops (they end), and the class sprites for every class.

---

## 1. P2: The "kept" newer or damaged run.sav is overwritten one frame into the new run; the tests check too early to notice

- **Where:** `scripts/scr_room_state/scr_room_state.gml:793` (Run_StartNew -> RunSave_DeleteUnlessKept) and `:838-841`. The overwrite happens at `objects/obj_game_controller/Step_0.gml:36` (Run_AutoSave on every room change) -> `scripts/scr_save/scr_save.gml:854-857` (RunSave_WriteTo) -> `scripts/scr_save/scr_save.gml:70-97` (Save_WriteFileAtomic).
- **Repro:** Put a run.sav with `run_version` 99, or a damaged one, in the save folder. On the title, choose New Game and pick a difficulty. The file is skipped by RunSave_DeleteUnlessKept. The new run then enters rm_floor1, the player spawns, and Step_0:36 calls Run_AutoSave -> Save_WriteFileAtomic. That function validates the old file with RunSave_IsCurrentRaw, which fails for a newer or damaged file, so it makes **no `.bak`**, then `file_delete(_path)` and renames the new save over it. The newer-build run is gone for good about one frame after it was "kept".
- **Violates:** R-137 / the packet's claim "New Game keeps a kept run file", and the rule written in its own comment (`:833-835`, from D16): "nothing is deleted that this build cannot read; the player may switch between builds on one save folder".
- **Test asserts less than its name:** smoke step 840 (`scripts/scr_debug/scr_debug.gml:13358-13359`, `hunt6run_a_new_run_keeps_a_newer_version_run_file`) checks on the first frame `Run_IsActive()` is true, before the room change and its autosave. `Test_Suite_Hunt6Run` "keep" (`scr_test.gml:13158-13166`) only calls Run_AbandonSaved. Both would pass with the bug in place.
- **Fix:** Before the new run's first write, move a newer or damaged run.sav aside, e.g. to `run.sav.kept` with a file_copy as Save_QuarantineFile does. Make the smoke check wait until after the first room-entry autosave.

## 2. P3: Migrating a v1 profile throws away the skills the last run had, so the first playtest after the update shows all "???" and no echo

- **Where:** `scripts/scr_save/scr_save.gml:523-528` (skill memory read only from v2 files) and `scripts/scr_room_state/scr_room_state.gml:667-683` (Run_EchoGrant -> Run_EchoDone empties `echo_pool` at the first class pick).
- **Repro:** Use the owner's existing v1 profile after a death. Its `echo_pool` holds `{kind:"skill", id}` entries, which are skills a run really had. Load it in this build: `skills_known` is `{}`. At the class pick, Run_EchoSkillOptions finds nothing, so there is no echo, and Run_EchoDone deletes the pool. The class screen shows "???" for those skills.
- **Violates:** D148 ("???" until discovered **in any run**) and D144 (the echo offers discovered skills). Those skills were discovered in a run, and the only record of that is dropped.
- **Fix:** In Profile_Normalize, when the file is v1, seed `p.skills_known` from the `echo_pool` / `echo_offer` / `echo` entries with `kind == "skill"`, using Profile_SkillLearn.

## 3. P3: Quit or close in a fight after the enemy falls or after a successful Run saves nothing, so the run falls back to the older autosave

- **Where:** `scripts/scr_room_state/scr_room_state.gml:307` (ResolveBattle clears the snapshot the moment the fight is decided). This is called from `scripts/scr_combat/scr_combat.gml:824` (the win, before the "slain" message and the death pop) and `:1751` (the escape, before "You ran away!"). It is read by `scr_room_state.gml:915-925` (Run_SaveOnClose) and `scripts/scr_menu/scr_menu.gml:808-813` (Menu_QuitToTitle).
- **Repro:** Open a chest less than 10 s before touching an enemy (the autosave tick does not run in rm_battle). Win the fight. While "X has been slain." is on screen, press Esc -> Quit to title, or close the window. The snapshot is already undefined, so WriteSnapshot returns false and nothing is written. Continue loads the room-entry autosave: the chest is closed again and the win is undone.
- **Violates:** the purpose of hunt6combat / D132 + D141 ("so a chest or a card taken since the last autosave is kept"). The ResolveBattle clear from hunt 5a reopens the gap for the last 1-2 s of every fight.
- **Fix:** Clear the snapshot in Battle_EndRun (when rm_battle is left), not in EnemyPersist_ResolveBattle. Keep the clear in Run_OnPlayerDeath.

## 4. P3: Elites are drawn again at full brightness over the room's darkness

- **Where:** `scripts/scr_loot/scr_loot.gml:820` (Elite_DrawWorldFx redraws the sprite), called after Light_DrawPass at `scripts/scr_enemy/scr_enemy.gml:879-882`.
- **Repro:** Find an elite on floor 3+ in a plain dark room (alpha 0.28), away from torches. Normal enemies and the player are dimmed. The elite sprite is drawn on top again with no darkness, and above the player sprite when they overlap.
- **Violates:** D159/D164 and the light pass's own rule (`scr_fx.gml` header: "a figure standing in the dark must look like it"). Elites look lit in pitch-dark corners.
- **Fix:** Draw only the rim and outline in Elite_DrawWorldFx (no sprite redraw), or draw the elite fx before Light_DrawPass.

## 5. P3: A status chip's full sentence can only be reached with the mouse

- **Where:** `scripts/scr_combat/scr_combat.gml:2806-2820` (Battle_ChipFocus). The only focus is the mouse position or a scenario's `hud.chip_focus`. The Status tab (`scr_menu.gml:109-112`) lists the player's statuses only.
- **Repro:** Play a fight on keyboard or gamepad. Poison the enemy. There is no way to highlight the enemy's "PSN 3" chip, so its full sentence (what it does, turns left) is never shown.
- **Violates:** D150 "full sentence when highlighted (Status tab / **enemy plate**)". For a non-mouse player the enemy plate's sentence cannot be reached.
- **Fix:** Let the command menu's details panel, or a held key, step a focus through the enemy chips (set `hud.chip_focus`). At least show the enemy's statuses in the details of the Attack row.

---

Not raised (by design, or pre-existing and outside tonight's diff): a choice answered in one run applies to every later run (D154: "remembered"); `Run_EchoTake` -> Player_LearnSkill does not check CARD_MAX_SKILLS (a fresh class holds 0 skills at the pick, so at most 1); Save_ReadJsonFile falling back to `.bak` when the main file is newer only matters right after the first v2 write, because the second flush replaces the `.bak`.
