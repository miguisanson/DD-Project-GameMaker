# Review: game code merged since the playtest build (7f4d08e..b9285c0), session 7

Reviewer: Opus, read-only. Scope: `git diff 7f4d08e b9285c0 -- scripts objects` minus scr_test/scr_debug (those were read only to check what the tests really assert). Packets: H13b text-fit, fix-hunt7prog, fix-hunt7map, textfit-shorten, fix-hunt7feel.

**Result: no P1 or P2.** I checked these and found them sound:
- QTE freeze: `Qte_StepMs` reads `global.focus_prev`, and `Focus_Edge` refreshes that every step from obj_ui_controller. A pending pause stays pending while the bar is frozen and clears when focus comes back, so the bar resumes and nothing softlocks. Everything that still reads `current_time` is presentation only.
- Level-up: `CardsUi_StatConfirm` closes the prompt and `Cards_NextOwed` reopens it while `stat_points > 0`. Each prompt places one point, so there is no loop.
- Loot fallback: `Loot_RollFromTable` steps the tier down, then up, then returns `undefined`. It cannot loop. An empty chest shows the `loot_empty` dialogue, and an empty enemy drop counts as a dry fight. The Nobody filter uses the same rules as `Equip_CanEquip` (preferred_class and allowed_classes).
- Saves: a new save writes `sprite_name`. An old numeric `sprite_index` loads through the `swap_sprite` fallback. `RoomState_ApplyInstance` skips both keys in its generic copy. `Enemy_ArrivalFix` runs after `RoomState_Apply` in the controller Step, so it does not save a room before the room has been restored.
- Layout: `TabMenu_Widths` caps the list at 2/3 of the body, so `det_w` is never negative. Text blocks clamp their width to at least 1. `Prompt_RichLayout` and `Dialogue_BreakWordToLines` always finish, even at negative widths. `Ui_MenuLabelRoom` matches the `label_x` math in `Ui_MenuDraw`.

## Findings

### 1. [P3] The g7 plate check now compares the plate text with itself, so it can no longer catch a cut or stacked plate
- **Where:** scripts/scr_combat/scr_combat.gml:4106 (`_bc.hud.preview_text = pl.plate;`), checked at scripts/scr_debug/scr_debug.gml:9846-9847 (`g7_the_plate_says_damage_and_perfect_from_the_preview`).
- **Repro:** Give the plate a gap so narrow that `Battle_PreviewPlateLayout` cuts the lines ("Dam..") or stacks them into 4 lines, then run the smoke step 411. The check still passes. `preview_text` holds the raw `Battle_PreviewPlateLines` output, and `_want` is built by the same function.
- **Expected:** The comment on line 4086 says the field "remembers what it drew for the tests". Before H13b it held the fitted lines, so a cut failed this check. The smoke runs record fit failures but do not assert them; only `-shots` does.
- **Fix:** Store `pl.lines` (what was drawn) in `preview_text`, keep `pl.plate` in a separate field, and have the check also require `!pl.stacked` and no `..`.

### 2. [P3] A failing focus scenario now leaves the window "unfocused" and freezes every later QTE in the same run
- **Where:** scripts/scr_debug/scr_debug.gml:8648 with the timeout branch at 8674-8678 (v==0), and 9317 with the restore at 9340, which only happens when `Menu_IsOpen()`.
- **Repro:** In smoke step 251 (v==0), call `Focus_Step(false)` and let the pause menu fail to open within 60 frames. The step records the failure and moves on without `Focus_Step(true)`. Scripted runs never poll `window_has_focus()` (obj_ui_controller/Step_0.gml:8), and nothing in scr_debug resets `global.focus_prev`. Every later bar, arrow sequence and defence QTE in that run then gets `Qte_StepMs == 0` and times out.
- **Expected:** One red check should stay one red check. Before hunt7feel, `focus_prev == false` had no effect on QTEs; now it masks the real failure under a cascade of unrelated timeouts.
- **Fix:** Set `global.focus_prev = true` in `Scenario_ClearUi` (or `Scenario_Next`), or restore focus in those failure branches.

### 3. [P3] A new-format save whose sprite name no longer resolves shows an opened chest or torch in its unswapped look
- **Where:** scripts/scr_room_state/scr_room_state.gml:227-233 (the `sprite_name` branch returns before the `swapped`/`swap_sprite` fallback).
- **Repro:** Save a run with an opened chest (record: `{swapped: true, sprite_name: "spr_chest_open"}`). In a later build, rename that sprite, then load. `asset_get_index` returns -1, the function returns, and the chest stays `swapped` but draws its closed sprite.
- **Expected:** The function's own comment says every saved picture came from `swap_sprite`, and the old-save path already prefers `swap_sprite`. The new path should be at least as robust as the old one, especially since the reason for this change is "asset ids shift between builds".
- **Fix:** When the name does not resolve, fall through to the `swapped && swap_sprite` branch instead of returning.

### 4. [P3] Run History picks its column count once, when the page opens, so a window resize leaves it stale
- **Where:** scripts/scr_menu/scr_menu.gml:980 (`cols: Codex_HistoryCols(hrows)`), used by `TabCodex_Open`. `Codex_HistoryCols` (line 481) measures against `TabMenu_Zones` at that moment.
- **Repro:** Open Tab > Codex > Run History in a large window (one column fits). Drag the window smaller or press Alt+Enter while the page is open. `TabMenu_FitMenu` re-fits the widths every frame, but `details_cols` stays 1. In Korean at 480x432, the one-column page is taller than the body and the number lines run past the panel. Switching tabs rebuilds the page and hides the bug, so the repro must keep the page open.
- **Expected:** The cf17ae3 claim is "the Codex run history fits at every size". The TextFit suite only checks a freshly built page at each size.
- **Fix:** Recompute `Codex_HistoryCols` in the draw or fit path when `Ui_Metrics()` changes (for example, cache it on `m.data` keyed by the metrics struct).
