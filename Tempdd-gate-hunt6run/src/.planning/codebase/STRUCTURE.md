# Codebase Structure

**Analysis Date:** 2026-10-13

## Directory Layout

```
DD-Project-GameMaker/
├── DD-Project.yyp            # GameMaker project manifest (IDE-owned)
├── DD-Project.resource_order # IDE-owned, gitignored
├── AGENTS.md / CLAUDE.md     # Agent rules
├── README.md                 # Localization workflow
├── objects/                  # 62 obj_* folders: Create_0/Step_0/Draw_64/Collision_*.gml + .yy
├── scripts/                  # 28 scr_* folders: one .gml with many functions + .yy
├── rooms/                    # rm_start, rm_cutscene, rm_battle, rm_floor1..9 (+6_5, 9_5)
├── sprites/                  # 134 sprite folders (descriptive names, not prefixed)
├── sounds/                   # 126 sound folders (descriptive names)
├── fonts/retro_gaming/       # UI font asset
├── datafiles/                # Included files shipped with the game
│   ├── localization/         # game_text.xlsx, localization.json, reports, legacy xlsx
│   └── fonts/                # NotoSansCJKkr-Regular.otf (+ NanumGothic-Regular.ttf at datafiles root)
├── options/                  # Per-platform build options (windows, main, android, ...)
├── tools/localization/       # Python pipeline
└── .planning/                # GSD state (STATE.md, config.json, research/, codebase/)
```

## Directory Purposes

**`objects/`:**
- Purpose: behavior shells. Controllers: `obj_game_controller`, `obj_ui_controller`, `obj_sfx_manager`, `obj_start_controller`, `obj_battle_controller`. World: `obj_player`, `obj_enemy` and enemy variants (`obj_slime`, `obj_spider`, `obj_snake`, `obj_dire_wolf`, `obj_mini_boss`, `obj_final_boss`, ...), interactables (`obj_chest*`, `obj_barrel*`, `obj_door`, `obj_switch`, `obj_bed`, `obj_npc`, `obj_item_pickup`), `obj_room_transition`, `obj_room_spawn`, `obj_dialogue_trigger`, `obj_wall`, decor (`obj_tree_*`, `obj_rock*`, `obj_torch*`).
- Persistent objects: `obj_ui_controller`, `obj_sfx_manager` only (`persistent: true` in their `.yy`).
- Event file naming: `Create_0.gml`, `Step_0.gml`, `Draw_64.gml` (Draw GUI), `Collision_obj_player.gml`.

**`scripts/`:**
- `scr_macros` constants; `scr_player` (GameState, GameSettings, Difficulty, UI scale/modal helpers, dialogue-trigger cinematics, `CharacterCreate_Player`); `scr_combat` (combat math + `Battle_*`); `scr_enemy`; `scr_db_{item,enemy,skill,player_class}`; `scr_room_db`, `scr_room_state`, `scr_room_transition`; `scr_save`, `scr_save_menu`; `scr_input`; `scr_localization`; `scr_dialogue`; `scr_menu` (inventory/stats menu, tooltips, class select); `scr_interact`; `scr_inventory`; `scr_equip`; `scr_loot`; `scr_levelup`; `scr_stats`; `scr_status`; `scr_sfx`; `scr_fx`; `scr_math`; `scr_debug`.

**`rooms/`:** `rm_start` (menu), `rm_cutscene`, `rm_battle`, floors `rm_floor1`-`rm_floor9`, `rm_floor6_5`, `rm_floor9_5`. Each holds `obj_game_controller`; `rm_start`/`rm_cutscene` also `obj_start_controller`; `rm_battle` has `obj_battle_controller`.

**`datafiles/localization/`:** `game_text.xlsx` (source), `localization.json` (build artifact), `game_text.legacy.xlsx`, `migration_map.csv`, `*_report.json`.

## Key File Locations

**Entry Points:**
- `rooms/rm_start/rm_start.yy` (first room), `objects/obj_start_controller/Step_0.gml`, `objects/obj_game_controller/Step_0.gml`

**Configuration:**
- `scripts/scr_macros/scr_macros.gml` (all tunables), `options/main/options_main.yy`, `options/windows/options_windows.yy`, `.planning/config.json`

**Core Logic:**
- State: `scripts/scr_player/scr_player.gml:1519` (`GameState_Init`)
- Battle: `scripts/scr_combat/scr_combat.gml`, `objects/obj_battle_controller/Step_0.gml`
- Transitions: `scripts/scr_room_transition/scr_room_transition.gml`
- Persistence: `scripts/scr_room_state/scr_room_state.gml`, `scripts/scr_save/scr_save.gml`
- Data: `scripts/scr_db_*/scr_db_*.gml`, `scripts/scr_room_db/scr_room_db.gml`
- Input: `scripts/scr_input/scr_input.gml`
- Localization: `scripts/scr_localization/scr_localization.gml`, `tools/localization/build_localization.py`

**Testing:**
- None. Debug overlay `scripts/scr_debug/scr_debug.gml`; Python tools are self-contained.

## Naming Conventions

**Files:**
- GML script asset `scripts/scr_<area>/scr_<area>.gml` (folder name == file name == asset name).
- Objects `objects/obj_<name>/<Event>_<n>.gml`.
- Rooms `rooms/rm_<name>/rm_<name>.yy`.

**Functions:** `PascalCase` with area prefix and underscore: `Save_Write`, `Battle_EndRun`, `RoomState_Apply`, `Input_Pressed`, `Loc_T`, `UI_DrawButton`, `Debug_Toggle`. DB: `ItemDB_Get`, `DB_Enemy`.
**Parameters:** `_leading_underscore` with defaults, e.g. `_slot`, `_delete_legacy = true`.
**Variables:** `snake_case` (`battle_state`, `return_room`); structs fields `snake_case`; stat keys `str, agi, def, intt, luck`.
**Macros:** `ALL_CAPS_WITH_UNDERSCORES` in `scr_macros` (`BSTATE_*`, `STATUS_*`, `UI_*`).
**Localization keys:** dotted lowercase, e.g. `battle.menu.no_skills`, `menu.main.option.0`, `enemy.name.enemy_slime`.
**Sprites/sounds:** descriptive, unprefixed; follow siblings.

## Where to Add New Code

**New feature logic:** add functions to the matching `scripts/scr_<area>/scr_<area>.gml`; wire from the object event.
**New constant/tunable:** `scripts/scr_macros/scr_macros.gml`.
**New enemy:** `ENEMY_*` macro in `scr_macros`, entry in `EnemyDB_Init` (`scr_db_enemy.gml`), case in `Enemy_LocalizationKey`, strings in `game_text.xlsx`; object/sprites created in the IDE (never by hand-editing `.yy`).
**New item/skill:** entry in `ItemDB_Init` / `SkillDB_Init`, plus `SKILL_*` macro for skills.
**New battle state:** `BSTATE_*` macro, branch in `objects/obj_battle_controller/Step_0.gml`, drawing in `Draw_64.gml`, step function `Battle_*` in `scr_combat.gml`.
**New room link:** `RoomDB_Init` entry (`scr_room_db.gml`) and spawn marker `obj_room_spawn` in the room (via IDE).
**New room:** create in IDE; must contain `obj_game_controller`.
**New persisted flag:** add under `gs.flags`; it is saved automatically in `Save_BuildSnapshot`. A new top-level `gs` field must be added to `Save_BuildSnapshot`/`Save_ApplySnapshot` and `SAVE_SNAPSHOT_VERSION` considered.
**New UI text:** `Loc_T("key","English")` + row in `game_text.xlsx`, rebuild JSON.
**New input action:** binding in `Input_Init`, gamepad case in `Input_GamepadActionHeld/Pressed`.

## Special Directories

**`.planning/`:** GSD working state; `STATE.md` is the session handoff. Committed.
**`datafiles/localization/localization.json`:** generated; do not hand-edit.
**`tools/localization/__pycache__`:** generated; ignore.
**`*.resource_order`, `*.old`:** gitignored, IDE-regenerated.

---

*Structure analysis: 2026-10-13*
