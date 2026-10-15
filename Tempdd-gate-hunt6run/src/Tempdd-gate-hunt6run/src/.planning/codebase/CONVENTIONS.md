# Coding Conventions

**Analysis Date:** 2026-10-13

Language: GML (GameMaker 2024). About 21,100 lines across `objects/*/*.gml` and `scripts/*/*.gml`. No linter or formatter config exists; the conventions below are observed, so follow them.

## Naming Patterns

**Files / assets:**
- Objects `obj_*`, scripts `scr_*`, rooms `rm_*`. Sprites and sounds are NOT prefixed; copy the sibling assets in the same folder.
- Each `scripts/scr_x/scr_x.gml` holds many related functions (e.g. `scripts/scr_menu/scr_menu.gml` has 78). Object events are `Create_0.gml`, `Step_0.gml`, `Draw_64.gml`.

**Functions:**
- `Module_Verb` PascalCase with underscore: `Combat_AttemptHit`, `Battle_PlayerAttack`, `Save_ReadSettingsConfig`, `Debug_Toggle`, `Input_Init`.
- Older small helpers are plain PascalCase: `RollD20`, `StatMod`, `StatClamp` (`scripts/scr_math/scr_math.gml`), `RecomputeResources` (`scripts/scr_stats/scr_stats.gml`). New code: use `Module_Verb`.
- Parameters prefixed `_` (`_attacker`, `_bc`). Optional parameters use defaults: `Combat_Log(_text, _icon_sprite = noone, _icon_subimg = 0)` (`scripts/scr_combat/scr_combat.gml:184`).

**Variables:** `snake_case` locals and instance vars; timers/counters end in `_timer`, `_frames`, `_step` (`move_timer`, `life_frames`, `cine_hold_frames`).

**Constants:** `#macro ALL_CAPS` in `scripts/scr_macros/scr_macros.gml` (`STAT_MIN`, `BSTATE_ATTACK_TIMING`, `DIFFICULTY_HARD`). Enum-like groups are numbered macros, not `enum`.

**Stat struct fields:** `str, agi, def, intt, luck` (note `intt`, not `int`; `scripts/scr_stats/scr_stats.gml:2`).

## Code Style

- 4-space indent, K&R braces, semicolons always. `if (cond) { ... }` with parens; single-line `if (x) stmt;` is common.
- `switch` with `case X: ...; break;` on one line when short.
- Comments are short `//` lines explaining intent or tuning ("softened mitigation: use half of DEF mod"). No JSDoc-style headers.
- Formatting/linting: none enforced.

## Defensive Pattern for Globals / Structs

Initialise lazily and idempotently, guarded by existence checks:
```gml
function Debug_Init() {
    if (!variable_global_exists("debug") || !is_struct(global.debug)) global.debug = {};
    if (!variable_struct_exists(global.debug, "enabled")) global.debug.enabled = false;
}
```
(`scripts/scr_debug/scr_debug.gml:1`, same shape in `scripts/scr_input/scr_input.gml:5`). Callers invoke `Xxx_Init()` at the top of each public function. Use `variable_struct_exists` before reading optional fields (150 `variable_global_exists`/struct-exists style checks across code).

## Error Handling

- Return a sentinel rather than throw: `return false`, `return undefined`, `return noone` (`Save_ReadSettingsConfig` returns `undefined` if file missing, `scripts/scr_save/scr_save.gml:~32`).
- Coerce untrusted data with `Save_ToReal(value, fallback)` (`scripts/scr_save/scr_save.gml:15`).
- Save snapshots are version-checked (`save_version` vs `SAVE_SNAPSHOT_VERSION`, `scr_save.gml:85-87`); settings use incremental `settings_version < N` migrations (`scr_save.gml:51-58`). Add a new `if (settings_version < N+1)` block and bump the `settings_version` literal (`scr_save.gml:66`).
- `try/catch/show_debug_message` appear about 81 times; use `show_debug_message` for diagnostics.

## Frame / Time Convention

Gameplay is counted in steps. Where seconds are specified, convert once: `round(sec * max(1, game_get_speed(gamespeed_fps)))` (`scripts/scr_player/scr_player.gml:449`, `scr_dialogue.gml:857`). Prefer this "seconds macro to frames" form for new timers (see `DIALOGUE_TRIGGER_CAM_RESTORE_SEC`). Never use `delta_time` (none present).

## Resource / Data Conventions

- Content databases are `global.*_db` structs built by `scripts/scr_db_*/*.gml` and `scr_room_db`. Add content there, not inline.
- Player-facing text goes through `scr_localization`; never hardcode (lint: `python tools/localization/lint_hardcoded_text.py`).
- Input goes through `scr_input` (`global.input.bindings`); only 1 direct `keyboard_check`/`gamepad_` call exists outside it, so keep it that way.
- `.yy/.yyp` are IDE-owned (AGENTS.md Rule 4).

## Module Design

- No barrel files. Functions are global by definition; cross-script calls are unqualified.
- Per-battle state lives on the `obj_battle_controller` instance and is passed as `_bc` into `Battle_*` functions; keep that pattern.

---

*Convention analysis: 2026-10-13*
