# Testing Patterns

**Analysis Date:** 2026-10-13

## Test Framework

**Runner:** None. No GML test framework, no test files, no CI. `grep` for `assert` finds nothing; the only "Test" symbol is `SFX_DebugPlayTest` (`scripts/scr_sfx/scr_sfx.gml:687`), an audio debug probe, not a test.

**Headless build candidate (UNVERIFIED):** `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\Igor.exe` exists (directory listing shows `Igor.exe`, `Igor.dll`). This contradicts AGENTS.md, which says no runtime is cached. Not executed. Next step: run it with `--help`, then try a `Windows Run`/`Windows Package` against `DD-Project.yyp` to confirm a compile check. If it works, update the gate in `AGENTS.md`.

**Run commands today:**
```bash
python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json
python tools/localization/lint_hardcoded_text.py
python tools/localization/verify_localization_equivalence.py
```
Everything else is manual: open the project in the GameMaker IDE and watch the output log.

## Test File Organization

None. Recommended: a script asset `scr_tests` (created in the IDE, Rule 4) containing `Test_RunAll()` that prints `PASS`/`FAIL` lines through `show_debug_message`, invoked from a `Debug_*` command wired through `scripts/scr_debug/scr_debug.gml` / `Debug_Update()` (`objects/obj_game_controller/Step_0.gml:2`). With Igor, a launch flag or macro could call it at game start and exit.

## Existing Debug Hooks (manual testing aids)

Key bindings in `scripts/scr_input/scr_input.gml`: `P` toggle debug, `F5` save, `F9` load, `L` level up, `K` give all items, `J` kill player, `U` enemy damage-skill-only, `O` display metrics. Implemented in `scripts/scr_debug/scr_debug.gml` (`Debug_Save`, `Debug_LevelUp`, `Debug_GiveAllItems`, `Debug_KillPlayer`).

## What Is Pure Enough for GML Assertions

Pure (no instances, no room, no globals beyond constants); test first:
- `scripts/scr_math/scr_math.gml`: `StatMod` (floor((s-10)/2), watch negatives), `StatClamp` (1..60). `RollD20` is random; seed or test range only.
- `scripts/scr_stats/scr_stats.gml`: `StatsCreateBase`, `StatsClampAll`, `HPGainPerLevel`, `ResourceStatWeight`.
- `scripts/scr_levelup/scr_levelup.gml`: `Level_IsAtCap`, level clamping (lines 1-12).
- `scripts/scr_save/scr_save.gml`: `Save_ToReal`, `DSList_ToArray`/`Array_ToDSList` round trip, settings migration (`settings_version` 0 to 7) by feeding structs; `GameSettings_Normalize`.
- `scripts/scr_combat/scr_combat.gml`: `Combat_Damage` (47), `Combat_AttackBonus` (22), `Battle_AttackTimingJudge` (445), `Battle_DefQTE*` threat/speed multipliers (966-1010). These take plain structs (`{stat_type, power, acc}`) plus characters with `.stats`; `Combat_EffectiveStat` reads status effects, so build a fake character struct with empty status.
- `scripts/scr_db_item`, `scr_db_skill`, `scr_db_enemy`, `scr_loot` (`global.loot_tables`): data-integrity checks (every enemy references existing skills/loot; every skill id has fx and sfx keys; localization keys exist).

Needs an instance or room (acceptance checklist instead): `scripts/scr_player/scr_player.gml` movement/cutscenes, `scr_menu`, `scr_dialogue`, `scr_room_transition`, `obj_battle_controller/Draw_64.gml`, QTE timing, `scr_sfx` playback.

Randomness: `Combat_CritCheck` uses `random(1)` (`scr_combat.gml:44`); use `random_set_seed(n)` in tests, or extract a `Combat_CritChance` pure function first (not present; currently chance and roll are fused).

## Assertion Block Pattern (to adopt, per AGENTS.md Rule 1)

```gml
function Test_Assert(_name, _got, _want) {
    show_debug_message((_got == _want ? "PASS " : "FAIL ") + _name + " got=" + string(_got) + " want=" + string(_want));
}
Test_Assert("StatMod(10)", StatMod(10), 0);
Test_Assert("StatMod(9)",  StatMod(9), -1);
Test_Assert("StatClamp hi", StatClamp(99), 60);
```

## Coverage

None enforced or measured. Zero automated coverage of combat math, save migration, or loot tables.

## Test Types

- Unit: none. E2E: none. Integration: manual in IDE.
- Localization tooling: Python scripts only; `verify_localization_equivalence.py` is the closest thing to a regression test.

---

*Testing analysis: 2026-10-13*
