<!-- refreshed: 2026-10-13 -->
# Architecture

**Analysis Date:** 2026-10-13

## System Overview

```text
┌──────────────────────────────────────────────────────────────────┐
│                           Rooms                                   │
│  rm_start      rm_cutscene     rm_floor1..9(.5)      rm_battle    │
│  (menu/boot)   (story text)    (overworld)           (combat)     │
├──────────────┬──────────────┬─────────────────┬──────────────────┤
│obj_start_    │obj_start_    │obj_player,      │obj_battle_       │
│controller    │controller    │obj_enemy, props │controller        │
│  + obj_game_controller in EVERY room (per-frame orchestration)    │
└──────┬───────┴──────┬───────┴────────┬────────┴─────────┬────────┘
       ▼              ▼                ▼                  ▼
┌──────────────────────────────────────────────────────────────────┐
│ Persistent: obj_ui_controller (HUD, modal, Transition_Update)     │
│             obj_sfx_manager (audio)                               │
└──────────────────────────────────────────────────────────────────┘
       ▼
┌──────────────────────────────────────────────────────────────────┐
│ Global state: global.state (GameState_Get), global.input,         │
│ global.loc, global.item_db / enemy_db / room_db, global.debug     │
│ `scripts/scr_player/scr_player.gml`, `scr_input`, `scr_localization`│
└──────────────────────────────────────────────────────────────────┘
       ▼
  savedata{0-2}.sav, settings_config.json, datafiles/localization/localization.json
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `obj_game_controller` | Per-room orchestrator: Create calls `GameState_Init()` + `SFX_EnsureManager()`; Step ensures UI controller, detects room change, applies room persistence/spawn, pending dialogues | `objects/obj_game_controller/Create_0.gml`, `Step_0.gml:1-94` |
| `obj_ui_controller` (persistent) | HUD/overlays, runs `Transition_Update()`, `UI_UpdateModalDimState()`, opens class-select/menus | `objects/obj_ui_controller/Step_0.gml`, `Draw_64.gml` |
| `obj_sfx_manager` (persistent) | Audio bus/volume/ambience ticking | `objects/obj_sfx_manager/Step_0.gml`, `scripts/scr_sfx/scr_sfx.gml` |
| `obj_start_controller` | Boot logo, main menu, difficulty, settings, cutscene sequencer (used in `rm_start` and `rm_cutscene`) | `objects/obj_start_controller/Create_0.gml`, `Step_0.gml` (504 lines) |
| `obj_battle_controller` | Battle state machine host (`battle_state`, `turn`, `p`, `e`) in `rm_battle` | `objects/obj_battle_controller/Create_0.gml`, `Step_0.gml`, `Draw_64.gml` |
| `GameState_*` | Single source of truth struct `global.state` | `scripts/scr_player/scr_player.gml:1519-1862` |
| Transition system | Fade/zoom/flash room changes, only caller of `room_goto` (plus load fallback) | `scripts/scr_room_transition/scr_room_transition.gml` |
| RoomState | Per-room persistence of enemies/chests/triggers/pickups across room hops | `scripts/scr_room_state/scr_room_state.gml` |
| Combat rules | Damage, hit, initiative, battle step functions | `scripts/scr_combat/scr_combat.gml` |
| Input | Action-based keyboard + gamepad abstraction | `scripts/scr_input/scr_input.gml` |
| Save | JSON slots + settings file | `scripts/scr_save/scr_save.gml`, UI in `scripts/scr_save_menu/scr_save_menu.gml` |
| Localization | Key lookup `Loc_T` over JSON | `scripts/scr_localization/scr_localization.gml` |

## Pattern Overview

**Overall:** Controller-object + global-struct game. Behavior lives in function libraries (`scripts/scr_*`), objects are thin event shells that call them.

**Key Characteristics:**
- One global struct `global.state` (alias via `GameState_Get()`) holds all mutable game state; `GameState_Init()` is idempotent and safe to call from anywhere (`scripts/scr_player/scr_player.gml:1519`, `:1729`).
- Rooms share a controller convention: every room contains `obj_game_controller` (verified in `rooms/rm_start`, `rm_battle`, `rm_cutscene`, `rm_floor1`); persistent objects are created lazily by it.
- Data tables ("DBs") are lazy-initialised globals with `*_Get(id)` accessors that fall back to a default struct.
- Time-based sequencing is done with explicit state fields and frame/second timers (Transition `phase`/`timer`, `battle_state`, `cutscene_segment_index`), never coroutines.

## Layers

**Rooms/Objects (behavior shells):**
- Location: `objects/*/*.gml`, `rooms/rm_*/`
- Depends on: scripts layer. Used by: GameMaker runtime.

**Scripts (logic libraries):**
- Location: `scripts/scr_*/scr_*.gml` (many functions per file, prefix-namespaced: `Save_`, `Loc_`, `Input_`, `Battle_`, `Combat_`, `RoomState_`, `Transition_`, `UI_`, `Dialogue_`, `Menu_`, `SFX_`, `Debug_`).
- Depends on: `scr_macros` constants and `global.*` state.

**Data ("DB"):**
- Location: `scripts/scr_db_item`, `scr_db_enemy`, `scr_db_skill`, `scr_db_player_class`, `scr_room_db`, `DialogueDB_*` in `scr_dialogue`.
- Pattern: `*DB_Init()` builds ds_map or struct; `*DB_Get(id)` localizes names at read time via `*_LocalizeRuntime` (e.g. `Enemy_LocalizeRuntime`, `scripts/scr_db_enemy/scr_db_enemy.gml:335`).

**Constants:**
- Location: `scripts/scr_macros/scr_macros.gml` - all `#macro` (BSTATE_*, STATUS_*, SKILL_*, UI_*, TRANSITION_*, DISPLAY_*, tuning numbers).

## Data Flow

### Game state flow (rooms)

1. Boot: first room `rm_start` (`DD-Project.yyp:415`) runs `obj_game_controller` Create then `obj_start_controller` (logo -> main menu: New Game / Load / Settings / Exit; `objects/obj_start_controller/Create_0.gml:1-9`).
2. New Game: difficulty prompt -> `GameSettings_ApplyAll()` -> `Transition_RequestCutsceneFade(rm_floor1, "start", -1, true)` (`objects/obj_start_controller/Step_0.gml:468-469`). Intro text lives in `cutscene_definitions.intro` (`Create_0.gml:~46`); cutscenes run in `rm_cutscene` selected by `Transition_RequestCutsceneById` which sets the id then fades to `rm_cutscene` (`scr_room_transition.gml:398-402`).
3. Overworld `rm_floor1..9`: `obj_player` moves on a 16px grid (`GRID_TILE_SIZE`), `obj_room_transition` collisions call `RoomDB_Get(...)` links (`scripts/scr_room_db/scr_room_db.gml`) and `Transition_RequestRoomFade(room, spawn_id, face, true)`.
4. Room change: `Transition_Update` (run by persistent `obj_ui_controller`) fades out, calls `RoomState_OnRoomExit()` via `Transition_PreRoomChange`, `room_goto` (`scr_room_transition.gml:472, 537, 603`), fades in. In new room `obj_game_controller.Step` sees `gs.last_room != room`, runs `RoomState_Apply(room)` and `RoomTransition_Apply()` (spawns player at spawn id) (`Step_0.gml:8-33`).
5. Encounter: `obj_enemy` Collision with player sets `encounter_pending` (`objects/obj_enemy/Collision_obj_player.gml`), then `EnemyPersist_BeginEncounter` (`scr_room_state.gml:260`) stores return room/xy via `GameState_SetBattleReturn` and enemy via `GameState_SetBattleEnemy`, then `Transition_RequestEncounterBattle()` -> `rm_battle`. Low-level enemies can auto-resolve (`ENEMY_AUTO_RESOLVE_*` macros, `Player_StartAutoResolveRecover`).
6. Battle end: win -> `EnemyPersist_ResolveBattle(true)` marks enemy removed, queues `pending_post_battle_dialogue_lines`, `BSTATE_END_RUN` -> `Battle_EndRun` -> `Transition_RequestRoomFade(gs.battle.return_room)` (`scr_combat.gml:806-816`). Death -> `Player_OnDeath` -> `Transition_RequestCutsceneById("game_over")` (`scr_combat.gml:366-376`). Ending: `EndingExitSequence_*` (`scr_room_transition.gml:91-166`).

### Battle state machine (`obj_battle_controller`)

States are macros in `scripts/scr_macros/scr_macros.gml`: `BSTATE_MESSAGE 0, MENU 1, PLAYER_ATTACK 2, PLAYER_RUN 3, ENEMY_ACT 4, END_RUN 5, SKILL_MENU 6, ITEM_MENU 7, ATTACK_TIMING 8, ENEMY_DEF_QTE 9`. Turn side: `TURN_PLAYER 0 / TURN_ENEMY 1`.

- Create: loads `gs.player_ch`, `EnemyCreate(gs.battle.enemy_id)`, spawns `obj_enemy_battle` centered in 160x144, rerolls initiative until unequal (`Create_0.gml:1-60`).
- Step dispatch is a flat chain of `if (battle_state == X) { ...; exit; }` (`Step_0.gml:38-213`):
  - `MESSAGE`: waits `COMBAT_ACTION_DELAY` frames then moves to `message_next_state` (`Battle_Message`, `scr_combat.gml:211`).
  - `MENU` -> picks action -> `ATTACK_TIMING` (timed swing minigame, `Battle_PlayerAttackTimingStep`), `SKILL_MENU`, `ITEM_MENU`, `PLAYER_RUN` (`Battle_RunAttempt`, d20 + AGI vs enemy; bosses cannot be fled).
  - `ENEMY_ACT` -> `Battle_EnemyAct` (`scr_combat.gml:1430`) -> optionally `ENEMY_DEF_QTE` (directional-arrow defense QTE, `Battle_DefQTEStep` `:1304`) -> back to `MESSAGE`/`MENU`.
  - `Battle_CheckEnd` (`:381`) sets `battle_over` and routes to `BSTATE_END_RUN`.
- Always route text through `Battle_Message(_bc, text, next_state)`; never set `battle_state` to a text-showing state directly.
- Drawing is in `objects/obj_battle_controller/Draw_64.gml` (GUI layer, 543 lines).

### Save / Load

1. Save: `Save_Write(slot)` calls `Enemy_ResetAll()`, then `Save_BuildSnapshot()` (`scr_save.gml:235-283`) -> `{save_version, statData{class, difficulty, player, flags, checkpoint, defeated, boss_defeated, save_room_name, save_x/y/face, ...}, levelData = persist minus enemies}` -> `json_stringify` -> `buffer_save` to `savedata<slot-1>.sav`.
2. Load: `Save_Read(slot)` -> `Save_TryLoadSnapshot` (validates `save_version == SAVE_SNAPSHOT_VERSION`, deletes stale files) -> `Save_ApplySnapshot` (`:285`) restores state, sets `load_spawn_*`, then `Transition_RequestLoadingRoomFade(room_id)`; `obj_game_controller` applies the one-shot spawn override (`Step_0.gml:50-67`). UI: `scripts/scr_save_menu/scr_save_menu.gml` (bed/save menu, 3 slots).
3. Settings: `GameSettings_Ensure/Normalize/Commit` (`scr_player.gml:1283-1517`) persisted by `Save_WriteSettingsConfig`.

### Input

- `Input_PreStep()` is called at top of both `obj_game_controller` and `obj_ui_controller` Step; `Input_Update` is guarded by `current_time` so it runs once per frame (`scr_input.gml:240-245`).
- Actions are string names bound in `Input_Init` (`:5-48`): `move_*`, `menu_*`, `interact`, `confirm` (space only), `cancel`/`pause` (Esc), `menu` (I/Tab), `debug_*`. Gamepad mapping hard-coded per action (`Input_GamepadActionHeld/Pressed`, `:185-238`): d-pad/left stick, face1 confirm, face2 cancel, face3 menu, face4 pause; debug actions ignore the pad.
- Query with `Input_Pressed("x")`, `Input_Held`, `Input_UIPressed`, `Input_UIRepeat`, buffering via `Input_ActionBuffered/Consume`, cooldown via `Input_ActionCooldownReady`.

### Localization

- Source: `datafiles/localization/game_text.xlsx` (sheet `strings`, columns `ref,en,ko`) -> `tools/localization/build_localization.py` -> `datafiles/localization/localization.json` (`{default_lang, languages, strings}`).
- Runtime: `Loc_Init()` tries `localization/localization.json`, `datafiles/localization/localization.json`, `localization.json` (`scr_localization.gml:68-96`). `Loc_T(key, fallback, vars)` (`:180`) with `{name}` templating via `Loc_FormatTemplate`; fallback chain selected language -> English -> provided fallback. Language persisted in `settings_config.json`; `Loc_SetLanguage` called from `GameSettings_ApplyAll`.
- DB names are keyed by `enemy.name.<suffix>` etc. through `*_LocalizationKey` functions.

### Display / camera / GUI

- Fixed internal resolution 160x144 (`DISPLAY_BASE_W/H`), integer window scale 3-5 or fullscreen. `GameSettings_ApplyDisplay()` (`scr_player.gml:1381-1472`) enables view 0, sets camera size to base, resizes `application_surface` to base, disables texture filtering, computes the letterboxed port via `Display_CalcLayout` (`:1297`) and aligns Draw GUI with `display_set_gui_size(port_w, port_h)` + `display_set_gui_maximise`. It is re-run after every transition (`Transition_Finish`, `scr_room_transition.gml:~452`) and on settings change.
- GUI drawing uses `display_get_gui_width/height()` and `UI_GetTextScale()/UI_GetVisualScale()` (`scr_player.gml:746-800`). All HUD/menus draw in `Draw_64` (Draw GUI) events.
- Camera follows player via view target; cinematic dialogue-trigger camera moves use `camera_set_view_pos` with saved/restored follow target (`DialogueTrigger_*`, `scr_player.gml:223-735`). Encounter zoom captures/restores the viewport (`Transition_*EncounterViewport`, `scr_room_transition.gml:219-286`).

**State Management:**
- `global.state` struct fields: `selected_class, difficulty, player_ch, player_inst, flags, checkpoint, defeated_enemies (ds_list), persist, persist_applied, battle{enemy_id,enemy_persist_id,enemy_room,return_room,...}, ui{mode,lines,...}, transition_fx, boss_defeated, last_room, save_slot, pending_*`. UI modes: `UI_NONE/DIALOGUE/MENU/SAVE/PAUSE/CLASS_SELECT/BED`.
- Other globals: `global.input`, `global.loc`, `global.item_db`, `global.enemy_db`, `global.room_db`, `global.sfx_db`, `global.debug`, `global.room_state_ready`, `global.skipRoomSave`.

## Key Abstractions

**Character struct:** `CharacterCreate_Player(class_id)` (`scr_player.gml:1`), `EnemyCreate` (`scripts/scr_enemy/scr_enemy.gml`); both carry `hp, max_hp, mp, stats, statuses, skills, level`. Combat helpers take these structs, not instances.
**Persist ID:** `RoomState_EnsurePersistId(inst)` gives world objects a stable key `RoomState_Key(room, persist_id)` (`scr_room_state.gml:1, 78`).
**Modal root:** `UI_ModalRootBegin/End` (`scr_player.gml:923-1014`) coordinate exclusive overlays; `UI_IsBlocking()` (`:735`) gates player input.

## Entry Points

**`rm_start`:** first room; `obj_start_controller` Create/Step/Draw_64.
**`obj_game_controller` Create:** runs `GameState_Init()` -> `Input_Init()`, `Loc_Init()`, DB init in every room.

## Architectural Constraints

- **Threading:** single-threaded GameMaker event loop at 60 fps.
- **Global state:** `global.state` and the globals listed above; no encapsulation, any script mutates freely.
- **Resource identity:** IDE-owned `.yyp`/`.yy`; new objects/rooms/scripts must be created in the IDE (AGENTS.md Rule 4).
- **Rooms must contain `obj_game_controller`** or no per-frame orchestration, transitions or persistence happens (UI controller is created from it, `Step_0.gml:2-4`).
- **`rm_battle` and `rm_cutscene` are excluded from room persistence and player spawning** (`Step_0.gml:21`, `scr_room_state.gml:254-258, 287-288`).
- **Circular imports:** not applicable (GML scripts are global); function-level coupling is high between `scr_player`, `scr_menu`, `scr_room_transition`, `scr_dialogue`.

## Anti-Patterns

### Direct `room_goto`
**What happens:** only `Transition_Update` and a save-load fallback call `room_goto`.
**Why it's wrong:** skipping it loses `RoomState_OnRoomExit` snapshot and display reset.
**Do this instead:** `Transition_RequestRoomFade(...)` / `Transition_RequestEncounterBattle()` (`scr_room_transition.gml:359-381`).

### Hardcoded player-facing English
**What happens:** a few strings are literal (e.g. `SaveMenu_OpenMessage("Game saved.", true)` in `objects/obj_game_controller/Step_0.gml:~71`; intro cutscene lines in `obj_start_controller/Create_0.gml`).
**Do this instead:** `Loc_T("key", "English fallback")` and run `tools/localization/lint_hardcoded_text.py`.

### Hand-editing `localization.json`
**Do this instead:** edit `game_text.xlsx` and rebuild with `build_localization.py`.

## Error Handling

**Strategy:** defensive checks, no exceptions. `variable_struct_exists` guards on nearly every state field; DB getters return default structs; save loader returns `undefined`/`false` and deletes invalid files; transitions self-heal (`Transition_Finish()` then retry, `scr_save.gml:376-380`).

## Cross-Cutting Concerns

**Logging:** `show_debug_message` behind `global.debug.enabled`.
**Validation:** `*_Normalize` functions (`GameSettings_Normalize`, `Difficulty_Normalize`, `Player_NormalizeProgression`) clamp loaded data.
**Authentication:** none.

---

*Architecture analysis: 2026-10-13*
