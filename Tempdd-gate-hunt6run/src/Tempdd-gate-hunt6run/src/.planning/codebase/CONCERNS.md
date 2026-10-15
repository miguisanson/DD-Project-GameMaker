# Codebase Concerns

**Analysis Date:** 2026-10-13

## Tech Debt

**Giant multi-purpose scripts:**
- Issue: `scripts/scr_menu/scr_menu.gml` (2783 lines, 78 functions), `scripts/scr_player/scr_player.gml` (1877), `scripts/scr_combat/scr_combat.gml` (1582), `scripts/scr_db_skill/scr_db_skill.gml` (1214), `scripts/scr_sfx/scr_sfx.gml` (1096), `scripts/scr_dialogue/scr_dialogue.gml` (1086). Also `objects/obj_battle_controller/Draw_64.gml` (543) and `objects/obj_start_controller/Step_0.gml` (504, boot logo plus cutscene plus menu in one step).
- Impact: merge conflicts, hard review, subagent packets blow context.
- Fix approach: split by concern (menu: inventory / equip / settings / save; player: movement / cutscene camera) in the IDE; keep function names so call sites stay valid.

**Duplicated stat-type switch:**
- Files: `scripts/scr_combat/scr_combat.gml:22-31` (`Combat_AttackBonus`) and `:47-57` (`Combat_Damage`) repeat the same STR/AGI/INT to `StatMod(Combat_EffectiveStat(...))` switch.
- Fix: extract `Combat_RelevantMod(_attacker, _weapon)`; cover with an assertion test first.

**Duplicated FX/sprite-speed logic and fps conversion:** `game_get_speed(gamespeed_fps)` with a `max(1, ...)` or `<= 0 then 60` guard is copy-pasted in `scr_combat.gml:142,1143`, `scr_player.gml:449,537`, `scr_dialogue.gml:857,893`, `objects/obj_ui_controller/Step_0.gml:40`, `objects/obj_start_controller/Step_0.gml:377`, `objects/obj_grave/Create_0.gml:9`. Fix: one `Time_SecToFrames(_sec)` helper. `FX_Spawn` sits in `scr_combat.gml:130` though it is FX code (belongs in `scripts/scr_fx`).

**Mid-file pseudo-modules:** `scripts/scr_save/scr_save.gml` mixes ds_list helpers (`DSList_ToArray`, line 1), settings I/O, and snapshots; `Save_ToReal` has `real(_value)` on any string that will crash on non-numeric text (line 18).

**Temp/leftover assets:** `objects/obj_ghost_easter_egg_temp/` ("temp" in name, spawned from `scripts/scr_interact/scr_interact.gml:381`); `ch.hp = 9999; // temp` placeholder at `scripts/scr_player/scr_player.gml:20`.

**Dead / unused code (unverified, needs per-symbol grep):** `LEVEL_CAP_TECHNICAL` and `LEVEL_EFFECTIVE_CAMPAIGN_CAP` are aliases of `LEVEL_CAP` (`scr_macros.gml:9-11`); `STAT_MAX` (60, comment "change to 99") duplicates the literal `1, 60` in `StatClamp` (`scr_math.gml:2`) instead of using `STAT_MIN`/`STAT_MAX`.

## Frame-Rate-Dependent Logic

All timing is step-counted; there is no `delta_time` anywhere. Counters decrement by 1 per Step: `objects/obj_battle_controller/Step_0.gml:12,42`, `obj_player/Step_0.gml:11,95`, `obj_ghost_easter_egg_temp/Step_0.gml:1`, `obj_sfx_manager/Step_0.gml:216,290`, `obj_start_controller/Step_0.gml:35-68,364`, `obj_ui_controller/Step_0.gml:23`, `scripts/scr_combat/scr_combat.gml:1320-1379` (defence QTE), `scr_dialogue.gml:908`, `scr_fx.gml:31,41`, `scr_menu.gml:2255`, `scr_player.gml:648`. About 352 lines mention `_frames`/`_timer`.
- Impact: if room speed or a monitor/vsync drop changes, QTE windows, fades, hold-to-repeat and audio tails change length. The QTE (`Battle_DefQTE*`) and attack-timing judge (`Battle_AttackTimingJudge`, `scr_combat.gml:445`) are skill-based and must stay deterministic.
- Mitigation present: some values are authored in seconds then converted once with `game_get_speed` (`scr_player.gml:449`). Mixed approach, so inconsistent.
- Fix: keep fixed-step (acceptable for a 60 fps retro game) but express every duration as a `*_SEC` macro through one converter; verify `game_get_speed(gamespeed_fps)` is the fixed value at boot. `Battle_Message`/`wait_timer` hardcoded step counts should be audited.
- `scr_enemy.gml:498` does `move_timer -= step` with a float `step`, unlike the integer decrement elsewhere; check it is fps-scaled intentionally.

## Global-Variable Sprawl

86 distinct `global.*` names. Heavy: `global.item_db` (57 uses), `dialogue_db` (48), `debug` (48), `skill_db` (44), `state` (42), `status_db` (31), `room_db` (25), `sfx_db` (24).
- Audio alone owns about 30 globals (`bgm_*`, `sfx_*`, `skillbook_mana_ambience_*` with 21+17+15 uses, `audio_debug_*`) in `scripts/scr_sfx/scr_sfx.gml` and `objects/obj_sfx_manager/Step_0.gml`. `obj_sfx_manager/Step_0.gml:1-4` re-creates missing globals every Step with `variable_global_exists`.
- Hazard: no single owner/initialiser; init order bugs surface as undefined variable crashes. 150 `variable_global_exists`/struct-exists guards are a symptom.
- Fix: group into structs (`global.audio = {bgm:{}, sfx:{}, debug:{}}`) initialised once from the boot controller; keep DB globals read-only after init.
- `global.state` (42 uses) is the central mutable game state; changes to its shape also affect saves (`scripts/scr_save/scr_save.gml`).

## Fragile Areas

**Save data (`scripts/scr_save/scr_save.gml`, `scr_save_menu.gml`):**
- Snapshot load rejects any version other than `SAVE_SNAPSHOT_VERSION` (`scr_save.gml:85-87`) so there is no migration path; a bump orphans all player saves. Settings do migrate (`settings_version` 7, `:51-66`).
- No atomic write seen (single `buffer_save`/file write); crash during save may corrupt. Use `save-systems` skill before touching.
- `real(string)` in `Save_ToReal` (line 18) throws on bad input.

**Battle state machine:** `BSTATE_*` macros (0-9) driven across `obj_battle_controller/Step_0.gml` and `Battle_*` in `scr_combat.gml` with state held as loose instance fields (`attack_timing_result_timer`, `wait_timer`, `enemy_def_qte_timer`). Transition bugs are manual-test only.

**Hardcoded room and instance coupling:** 28 `room_goto`/`== rm_*` references; `FX_Spawn` hardcodes layer `"Instances"` and `room == rm_battle` (`scr_combat.gml:131-135`); camera/cinematics keyed by string phases (`cine_phase = "restore_blend"`, `scr_player.gml:~455`). Typos in strings fail silently.

**Manual ds structures:** `ds_list_create`/`ds_map_create` 18 vs `*_destroy` 6; likely leaks (no `CleanUp` events exist under `objects/`). Audit and prefer arrays/structs.

**Randomness:** `randomize()` called in a gameplay script (`scr_player.gml:1530`) rather than once at boot; makes seeded tests/replays impossible.

## Hardcoded Numbers

Combat tuning inline: crit `0.05`, `0.01`, `0.50` (`scr_combat.gml:42-44`); `mitig = floor(DEF mod / 2)`; HP/MP growth (`scr_stats.gml:14-19`); `0.30` logo timing (`obj_start_controller/Step_0.gml:377`); `0.2` fallback sprite speed and `60` fps fallback (`scr_combat.gml:144-150`). Move to `scr_macros.gml` (many tuning values already live there, e.g. `PLAYER_HP_DEF_BONUS_FACTOR`, `SKILL_FX_SCALE`), or to the `Difficulty_Profile()` struct. Balance changes need grill-me per AGENTS.md.

## Security / Shipping Considerations

- Debug keys (`P`, `F5`, `F9`, `L`, `K`, `J`, `U`, `O`) are bound in `scripts/scr_input/scr_input.gml` and processed via `Debug_Update()` (`obj_game_controller/Step_0.gml:2`). `Debug_Toggle` gates features on `global.debug.enabled`, but `P` itself is bound unconditionally; confirm it is stripped or gated in release builds (e.g. `GM_build_type`).
- `settings_config.json` and saves are plain JSON in the local sandbox; trivially editable. Acceptable for single-player.

## Missing Test Coverage

No automated tests at all (see `TESTING.md`). Highest-risk, highest-value pure targets: `Combat_Damage`, `Combat_AttackBonus`, `StatMod`, `RecomputeResources`, save migration, DB referential integrity (`scr_db_*`, `scr_loot`). Priority: High for combat and save; Medium for DB integrity.

## Tooling Gap

AGENTS.md says no headless build exists, but `Igor.exe` is present under `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\` (not yet run). Verifying it would enable a real compile gate. Priority: High.

---

*Concerns audit: 2026-10-13*
