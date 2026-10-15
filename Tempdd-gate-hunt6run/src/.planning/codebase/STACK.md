# Technology Stack

**Analysis Date:** 2026-10-13

## Languages

**Primary:**
- GML (GameMaker Language), GameMaker 2024 - all game logic. ~17.4k lines in `scripts/*/*.gml` (28 script assets), ~3.7k lines in `objects/*/*.gml` event files. Largest: `scripts/scr_menu/scr_menu.gml` (2783), `scripts/scr_player/scr_player.gml` (1877), `scripts/scr_combat/scr_combat.gml` (1582).

**Secondary:**
- Python 3 (stdlib + `openpyxl`, optional `openai`, `deep_translator`) - off-engine localization tooling in `tools/localization/*.py`.

## Runtime

**Environment:**
- GameMaker IDE `2024.14.3.217` (`DD-Project.yyp` MetaData.IDEVersion, line 85); active runtime named `2024.14.3.260` but not cached locally (AGENTS.md "Traps"). IDE installed at `E:\GameMaker`.
- Target: Windows desktop (`options/windows/options_windows.yy`: borderless, no vsync, texture page 2048x2048). Per-platform option folders also exist for android, html5, ios, linux, mac, operagx, ps4, ps5, reddit, switch, tvos, xboxseriesxs under `options/`.
- Game speed 60 fps (`options/main/options_main.yy` `option_game_speed`). Legacy compat flags are ON (`option_legacy_json_parsing`, `option_legacy_number_conversion`, `option_legacy_other_behaviour`, `option_legacy_primitive_drawing`).

**Package Manager:**
- None for the game. Python tools have no requirements file (`openpyxl` must be installed manually).
- Lockfile: not applicable.

## Frameworks

**Core:**
- GameMaker built-ins only (rooms, objects, structs, ds_map/ds_list, buffers, `json_parse`/`json_stringify`, gamepad API, audio API). No third-party GML libraries or extensions.

**Testing:**
- None. No unit-test framework or headless runner (AGENTS.md Rule 1). Runtime debug overlay in `scripts/scr_debug/scr_debug.gml` (`Debug_*`, toggle bound to `P`).

**Build/Dev:**
- GameMaker IDE only. No Igor/CLI build available (AGENTS.md "The gate").
- Python localization pipeline: `tools/localization/build_localization.py`, `bootstrap_catalog.py`, `migrate_legacy_sheet.py`, `lint_hardcoded_text.py`, `verify_localization_equivalence.py`, `autofill_korean_google.py`.

## Key Dependencies

**Critical:**
- `openpyxl` - reads/writes `datafiles/localization/game_text.xlsx` (`tools/localization/build_localization.py:15`).

**Infrastructure:**
- `openai` (optional, lazy import at `tools/localization/build_localization.py:315`) - `--autofill-ko` draft translations; model from `LOCALIZATION_MODEL` env, default `gpt-4.1-mini`.
- `deep_translator.GoogleTranslator` (`tools/localization/autofill_korean_google.py:15`) - alternate Korean autofill.

## Configuration

**Environment:**
- Game: no env vars. Player settings persisted at runtime to `settings_config.json` (`scripts/scr_save/scr_save.gml:24-81`) in the GameMaker working/save directory.
- Tooling: `LOCALIZATION_MODEL` env var; an OpenAI key would be required for `--autofill-ko` (never commit).

**Build:**
- `DD-Project.yyp` (resource manifest; IDE-owned), `DD-Project.resource_order` (gitignored, IDE-regenerated), `options/<platform>/options_*.yy`.
- Single audio group `audiogroup_default`, single texture group `Default` (`DD-Project.yyp:4-6, 431-433`).
- Fixed base resolution in macros: `DISPLAY_BASE_W 160`, `DISPLAY_BASE_H 144` (Game Boy), scale 3-5 (`scripts/scr_macros/scr_macros.gml`).
- 14 rooms; start room is first in `RoomOrderNodes` = `rm_start` (`DD-Project.yyp:414-415`).
- Assets: 126 sound folders in `sounds/`, 134 sprite folders in `sprites/`, font `fonts/retro_gaming` (UI font macro `UI_FONT`), runtime data fonts `datafiles/fonts/NotoSansCJKkr-Regular.otf` and `datafiles/NanumGothic-Regular.ttf` (Korean glyphs).

## Platform Requirements

**Development:**
- Windows 11, GameMaker IDE at `E:\GameMaker`, Python 3 + `openpyxl` for localization only.
- Never hand-edit `.yyp`/`.yy`/`.resource_order` (AGENTS.md Rule 4); `.gml` files are safe to edit directly.

**Production:**
- Windows desktop executable via IDE export. No installer/CI/store integration configured (`option_windows_enable_steam: false`).

---

*Stack analysis: 2026-10-13*
