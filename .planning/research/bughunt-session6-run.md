# Bug hunt, session 6: run loop and persistence (read-only, `next` @ ab91434)

Area: scr_room_state (run, echo, stats, snapshot, plans, seed), scr_save (run save, profile, migration, atomic writes), title / Continue / New Game, death -> summary -> next run, save on close, notes, seed entry.
Method: code read and hand traces; nothing built or run. 3 findings (2 x P2, 1 x P3). Not repeated: the items in bughunt-session5.md and ISSUES.md (stale `encounter_snapshot`, dead D130 echo functions, I-071).

## 1. P2: more than half of the random seeds cannot be typed back in (D152)

- **Where:** `scr_room_state.gml:330` `Run_NewSeed()` draws `irandom_range(1, RNG_MOD - 2)` (up to 2,147,483,645, 10 digits). `scr_room_state.gml:338` `SEED_DIGITS_MAX 9` and `SeedParse` (line 345) keep only the first 9 digits. The seed is shown in full in the Status tab (`Seed_Label`, line 414) and the run summary row (line 955).
- **Repro:** New Game > Random seed. About 53% of draws are above 999,999,999 (e.g. 1,234,567,890). The Status tab shows `Seed: 1234567890`. After the run, New Game > Enter seed: the cells stop at 9 digits, so the most the player can type is 123456789, a different run (different enemy plan, chest loot, shop stock, cards). Nothing says the seed is too long.
- **Violates:** D152 ("seed shows in the Status tab and the run summary"; "Same seed, same run" is the entry screen's own help line). The tests only pin `Seed_IsValid(RNG_MOD - 2)` and 9-digit parsing, never that a drawn seed can be entered.
- **Fix idea:** make `Run_NewSeed` draw `1 .. 999,999,999` (matches the entry), keep `Seed_IsValid` as is. Add a check: 1000 draws all satisfy `SeedParse(string(n)) == n`.

## 2. P2: the Continue card never shows the time played (D128)

- **Where:** `scr_menu.gml:3362` `Title_CardModel` reads `r.play_ms` at the top level of the run save. `RunSave_Build` (`scr_save.gml:843`) writes the time inside `stats` (`stats.play_ms`, D137) and has no top-level `play_ms`. The comment on line 3362 ("the run save has no play-time field yet") is out of date.
- **Repro:** play 20 minutes, Quit to title. The card shows Floor and Gold only (`time_ms` is always -1, so the Time row at line 3386 is dropped). The test at `scr_test.gml:7926` passes only because it feeds a made-up `{ play_ms: 3725000 }` save that the game never writes.
- **Violates:** D128 ("a Continue card (class, floor, time played, gold)").
- **Fix idea:** `time_ms = (is_struct(r.stats) && variable_struct_exists(r.stats, "play_ms")) ? Save_ToReal(r.stats.play_ms, -1) : -1`; change the test fixture to the real shape (`stats: { play_ms: ... }`), and add one check that builds a real `RunSave_Build()` and passes it to `Title_CardModel`.

## 3. P3: New Game deletes a newer-version or damaged run.sav that Run_AbandonSaved deliberately keeps

- **Where:** `Run_AbandonSaved` (`scr_room_state.gml:780-791`) only deletes the file for status ok / missing / old and says "A newer-version or damaged file is left where it is" (test `scr_test.gml:3984` pins it). But `Run_StartNew` then calls `RunSave_Delete()` unconditionally (`scr_room_state.gml:749`), which removes run.sav, run.sav.bak and run.sav.tmp.
- **Repro:** put a run.sav with `run_version: 3` (or a damaged one) in the save folder. Title shows "Can't continue". New Game > confirm > seed: the file is gone after the run starts. No `.corrupt` copy is made for a damaged run.sav either (profile.sav gets one, `Save_QuarantineFile`).
- **Why it matters:** the owner switches between builds on the same save folder (`DD_Project`), so a run saved by another build is plausible. D16: nothing is ever deleted.
- **Related, smaller:** `RUN_SAVE_VERSION 2` rejects a v1 run.sav as "old" (shown with the old-slot notice), although v2 only added `drop_dry` and the loader already defaults every later field, so a v1 run could load as is.
- **Fix idea:** in `Run_StartNew` delete only when `RunSave_LoadFrom().status` is ok / missing / old, else quarantine to `run.sav.corrupt` first (reuse `Save_QuarantineFile`); optionally accept `run_version` 1 and 2 in `RunSave_IsCurrentRaw`.

## Checked and found sound (no finding)

- Atomic write (`Save_WriteFileAtomic`: tmp, re-read, .bak only from a good file, delete then rename) and the .bak read fallback; truncated / garbage / newer / old files for profile and run save.
- Profile v1 -> v2 (`Profile_Normalize`: skill memory starts empty, old echo/echo_offer becomes the pool and is emptied at the class pick), counters and history cap.
- Death, abandon, win: profile first, then run.sav deleted; autosave and close-save are refused when the run is inactive, in rm_start / rm_battle / rm_cutscene, during a transition or while a load spawn is pending; the player is re-snapped on load (`Player_SnapIfOffGrid`). Game End event is registered in obj_game_controller.yy.
- Run-to-run leakage: flags, persist, bosses, uid counter, pending lines, notes, stats, bags and RNG streams are rebuilt in `Run_StartNew`; story flags go through the profile; the level-up sparkle is keyed per run.
- Same seed, same plan: enemy layout, elites, chest loot and shop stock come from `Rng_New(seed, label)` per room / chest, not from a shared stream; all enemies of a room are saved together before a fight or auto-resolve so a Continue does not re-deal with fewer slots.
- Files written: only relative names (save area); `export_data.json` is scenario-only.
- D147 notes: collected in the profile, flushed at pickup, rebuilt from the profile at each room start. D154 (dialogue choices) is not on `next` (branch h12a-choices), so not checked.
