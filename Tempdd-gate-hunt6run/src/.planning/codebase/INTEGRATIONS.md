# External Integrations

**Analysis Date:** 2026-10-13

## APIs & External Services

**Runtime game:**
- None. No HTTP calls (`http_*`), no Steam, no analytics, no online services in `scripts/` or `objects/`. Steam is disabled (`options/windows/options_windows.yy` `option_windows_enable_steam: false`).

**Build-time tooling (developer machine only):**
- OpenAI API - optional draft Korean translation
  - SDK/Client: `openai` Python package, lazy import `tools/localization/build_localization.py:315`
  - Trigger: `build_localization.py --autofill-ko --model gpt-4.1-mini`
  - Auth: standard OpenAI credential env var (not stored in repo); model override `LOCALIZATION_MODEL`
- Google Translate (unofficial) - alternate Korean autofill
  - SDK/Client: `deep_translator.GoogleTranslator`, `tools/localization/autofill_korean_google.py:15`
  - Auth: none

## Data Storage

**Databases:**
- None. "DB" in this codebase means in-memory GML tables built at runtime:
  - Items: `ItemDB_Init()` fills `global.item_db` ds_map (`scripts/scr_db_item/scr_db_item.gml:1`)
  - Enemies: `EnemyDB_Init()` fills `global.enemy_db` ds_map (`scripts/scr_db_enemy/scr_db_enemy.gml:1`)
  - Skills: `SkillDB_Init()` (`scripts/scr_db_skill/scr_db_skill.gml:1`)
  - Player classes: `DB_PlayerClass()` switch returning struct (`scripts/scr_db_player_class/scr_db_player_class.gml:1`)
  - Room links: `RoomDB_Init()` fills `global.room_db` struct (`scripts/scr_room_db/scr_room_db.gml:1`)
  - Dialogue: `DialogueDB_Init()` (`scripts/scr_dialogue/scr_dialogue.gml:1`)

**File Storage (GameMaker sandbox/working directory, via `buffer_save`/`buffer_load`):**
- Save slots: `savedata0.sav` .. `savedata2.sav` (slot 1-3), JSON text, written by `Save_Write` (`scripts/scr_save/scr_save.gml:392`), path from `Save_Path` (`:386`). `SAVE_SNAPSHOT_VERSION 2` macro (`scripts/scr_macros/scr_macros.gml` last line); older/invalid files are deleted on read (`Save_TryLoadSnapshot`, `:92-117`).
- Settings: `settings_config.json`, `settings_version: 7` (`Save_WriteSettingsConfig`, `:63`) with volumes, `display_scale`, `fit_screen`, `language`; older versions migrated in `Save_ReadSettingsConfig` (`:28`).
- Included files (read-only data): `datafiles/localization/localization.json` (build artifact), fonts in `datafiles/fonts/`.

**Caching:**
- None.

## Authentication & Identity

**Auth Provider:**
- None (single-player offline game).

## Monitoring & Observability

**Error Tracking:**
- None.

**Logs:**
- `show_debug_message` gated behind `global.debug.enabled` (e.g. `SaveMenu_Log` in `scripts/scr_save_menu/scr_save_menu.gml:1-5`); `RoomState_Warn` (`scripts/scr_room_state/scr_room_state.gml:42`), `RoomTransition_Warn` (`scripts/scr_room_transition/scr_room_transition.gml:10`), `SFX_DebugWarnOnce` (`scripts/scr_sfx/scr_sfx.gml:610`).
- Runtime debug overlay and hotkeys: `scripts/scr_debug/scr_debug.gml` (P toggle, F5 save, F9 load, L level up, K all items, J kill, U enemy damage-skill only, O display metrics; bindings in `scripts/scr_input/scr_input.gml:25-34`).

## CI/CD & Deployment

**Hosting:**
- None configured.

**CI Pipeline:**
- None. Gate is manual IDE run plus the localization commands in `AGENTS.md`.

## Environment Configuration

**Required env vars:**
- None for the game. Optional `LOCALIZATION_MODEL` for tooling.

**Secrets location:**
- None in repo. `.claude/`, `.planning/` hold agent config only.

## Webhooks & Callbacks

**Incoming:** None.
**Outgoing:** None.

## Hardware / OS Integrations

- Gamepad: first connected of 4 devices via `gamepad_*` API (`Input_GamepadDevice`, `scripts/scr_input/scr_input.gml:172`).
- Window/display: `window_set_*`, `display_set_gui_*` in `GameSettings_ApplyDisplay` (`scripts/scr_player/scr_player.gml:1381`).
- Audio: GameMaker audio API wrapped by `scripts/scr_sfx/scr_sfx.gml` (key-based SFX/BGM registry, per-key gain maps, UI/SFX/music buses).

---

*Integration audit: 2026-10-13*
