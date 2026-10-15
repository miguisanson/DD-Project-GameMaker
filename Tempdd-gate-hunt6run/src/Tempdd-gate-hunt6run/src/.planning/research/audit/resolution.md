# Audit: resolution / scaling / screen bugs

Read-only audit, 2026-10-13, branch v1.8 (HEAD 0b6e2f8). No game file was edited. Nothing here was run: no headless build exists, so every claim is tagged
**VERIFIED** (the code or data on disk proves it) or **SUSPECTED** (depends on GameMaker runtime behaviour that must be checked in the IDE).
All paths are relative to the repo root. `scr_player.gml` means `scripts/scr_player/scr_player.gml` (it is also the display module, despite the name).

Reports to explain: friend "scale problem. screen bug"; owner "screen bug when a cutscene ends (also places with dialogue)" and "resolution/scaling problems in general" (`.planning/research/playtest-notes.md`).

---

## 1. Inventory: every place that touches display / view / camera / surface / GUI

### 1a. The display owner (one function, called from five places)

`GameSettings_ApplyDisplay()` - `scripts/scr_player/scr_player.gml:1381-1472`. It does all of this in one go:

| Line | What | Note |
|---|---|---|
| 1391 | `application_surface_draw_enable(true)` | engine auto-draws the surface; the game never draws it itself |
| 1393 | `gpu_set_texfilter(false)` once | global nearest-neighbour |
| 1397-1401 | `view_enabled = true; view_visible[0]=true; view_visible[1..7]=false` | forces view 0 on at runtime |
| 1402-1403 | `view_hborder[0]/view_vborder[0] = base/2 - 1` (79 / 71) | overrides the room's 144/108 borders (see 2c) |
| 1406-1408 | `window_set_showborder(false)` (Windows) | redundant, `option_windows_borderless` is already true |
| 1410-1411 | `display_get_width/height()` | |
| 1414-1416 | `window_set_fullscreen(fit_screen)` | "fit_screen" is really the fullscreen flag |
| 1418-1426 | fullscreen-flag-on but not yet fullscreen: `window_set_size(disp)`, `window_set_position(0,0)` | |
| 1427-1434 | windowed: `window_set_size(base*scale)`, then `window_center()` **unconditionally** | `window_center()` runs on every call |
| 1436-1437 | `window_get_width/height()` read **immediately** after the fullscreen change | see H1c |
| 1443 | `Display_CalcLayout(...)` | port rect, `scr_player.gml:1297-1327` |
| 1449-1452 | `view_xport/yport/wport/hport[0] = layout` (e.g. 480x432 at 3x) | |
| 1454-1460 | `camera_set_view_size(cam, 160, 144)`; clamp `camera_set_view_pos` into the room | |
| 1462-1466 | `surface_resize(application_surface, 160, 144)` | surface is base-size, port is scaled-size |
| 1470-1471 | `display_set_gui_size(port_w, port_h)` then `display_set_gui_maximise(1, 1, port_x, port_y)` | GUI = port-sized, shifted by the port origin |

Callers of `GameSettings_ApplyDisplay`:
- `GameSettings_ApplyAll()` `scr_player.gml:1474-1479`, called from `objects/obj_sfx_manager/Create_0.gml:70`, `objects/obj_start_controller/Step_0.gml:468` (end of intro cutscene), `scripts/scr_save/scr_save.gml:357` (load), and `GameSettings_Commit` `scr_player.gml:1485` (Settings > Apply).
- `GameSettings_SetScale` `scr_player.gml:1513`.
- **`Transition_Finish()` `scripts/scr_room_transition/scr_room_transition.gml:452`** - end of *every* transition of every type.
- **`objects/obj_sfx_manager/Step_0.gml:149-150`** - the "self-heal" poll, every frame (see 2d). This is an audio manager that owns the display. Wrong home.

### 1b. Layout maths

`Display_CalcLayout` `scr_player.gml:1297-1327`: integer scale only. `used_scale = fixed_scale`; if the fullscreen flag is on, `min(fixed_scale, max_integer_scale)`; port is centred in the window.
Macros `scripts/scr_macros/scr_macros.gml:277-282`: `DISPLAY_BASE_W 160`, `DISPLAY_BASE_H 144`, `DISPLAY_SCALE_MIN 3`, `MAX 5`, `DEFAULT 3`, `DISPLAY_FORCE_FIT_SCREEN 0`.
Settings defaults `scr_player.gml:1329-1338` (`display_scale 3, fit_screen false`), normalised `1340-1359`; persisted by `scripts/scr_save/scr_save.gml:30-80` (`settings_version 6`, line 58 forces `fit_screen=false` for any config older than v6).
Menu rows: `scripts/scr_menu/scr_menu.gml:2301-2313` (Scale 3..5, Fullscreen toggle), `2325` (Apply -> `GameSettings_Commit`), `2392` / `2475-2490` (labels).

### 1c. Camera / view writers outside ApplyDisplay

| File:line | What |
|---|---|
| `scr_player.gml:263-271` `DialogueTrigger_CameraPosForPoint` | world point -> camera pos, clamped to room |
| `scr_player.gml:388-428` `DialogueTrigger_CleanupCinematic` | `camera_set_view_target(cam, obj_player)` restore (400) |
| `scr_player.gml:430-464` `..._BeginFollowRestoreBlend` | `camera_set_view_target` (447), blend setup |
| `scr_player.gml:471-560` `..._StartCinematic` | `view_camera[0]` (524), `camera_set_view_target(cam, noone)` (548) |
| `scr_player.gml:562-732` `..._UpdateCinematic` | `camera_set_view_pos` every frame in pan_in (629), hold (644), pan_out (677), restore_blend (725) |
| `scripts/scr_room_transition/scr_room_transition.gml:219-286` | encounter zoom: capture/apply/restore `view_*port`, `camera_set_view_size/pos` on a cached camera id |
| `objects/obj_battle_controller/Create_0.gml:129-130` | `cam_base_x/y = camera_get_view_x/y(view_camera[0])` |
| `objects/obj_battle_controller/Draw_64.gml:23-45` | `camera_set_view_pos` (29) **inside a Draw GUI event** for shake; reads `view_*port` |
| `scripts/scr_combat/scr_combat.gml:406-440` | world->GUI conversion via `view_xport/wport` and camera size (QTE target) |
| `objects/obj_ui_controller/Draw_64.gml:39-50` | HUD shake offset via `view_wport / camera size` |
| `objects/obj_sfx_manager/Step_0.gml:100-147` | reads view/camera/gui state, triggers ApplyDisplay |
| `objects/obj_sfx_manager/Draw_64.gml:149-190` | debug "display metrics" overlay (P to enable debug, then O) - prints window, display, gui, viewport, camera, `application_surface` size |

No `camera_create`, `room_set_view`, `view_camera[n] =` or `display_reset` anywhere. No `draw_surface` of the application surface, no Post Draw / Draw GUI Begin/End events (only `Draw_64` Draw GUI events exist: obj_ui_controller, obj_battle_controller, obj_start_controller, obj_sfx_manager).

### 1d. Everything that reads GUI size (all assume "GUI = the game rectangle")

`display_get_gui_width/height` at: `objects/obj_ui_controller/Draw_64.gml:2-3`, `objects/obj_battle_controller/Draw_64.gml:6-7`, `objects/obj_start_controller/Draw_64.gml:1-2`, `objects/obj_sfx_manager/Draw_64.gml:8-9,154-155`, `objects/obj_sfx_manager/Step_0.gml:141-142`, `scripts/scr_combat/scr_combat.gml:407-408`, `scripts/scr_dialogue/scr_dialogue.gml:580-581,633-634`, `scripts/scr_menu/scr_menu.gml:149-150,787-788,1959-1960,2363-2364`, `scripts/scr_save_menu/scr_save_menu.gml:142-143,586-587`, `scripts/scr_player/scr_player.gml:747-748` (`UI_GetTextScale`), `1248-1249` (`UI_DrawModalDim`), `scripts/scr_room_transition/scr_room_transition.gml:628-629` (`Transition_DrawGUI`, the black fade). 17 sites.

### 1e. Build options (read only)

| File | Setting |
|---|---|
| `options/windows/options_windows.yy:5,6,24,26,29` | `allow_fullscreen_switching false` (no F11 / Alt+Enter), `borderless true`, `resize_window false`, `scale 0`, `start_fullscreen false`, `interpolate_pixels false` (line 20) |
| `options/main/options_main.yy:26` | `option_window_colour 255` = **red** (GM colours are BGR; 255 is `c_red`). This is the colour of anything outside the drawn area. SUSPECTED visible as red bars in fullscreen / odd-aspect windows; confirm in IDE |
| `options/android/options_android.yy:46,51-54,66` | `interpolate_pixels true` (contradicts the code's nearest filter), landscape **and** portrait both on, `scale 0` |
| `options/html5`, `ios`, `linux` | `scale 0`; linux `allow_fullscreen true` (set in 8a23294) |

### 1f. Room data (read only), all 14 rooms

All rooms: `enableViews true`, `inheritViewSettings false`, `clearDisplayBuffer true`. View 0: `visible true`, 160x144 camera, port 480x432.

| Room | Room size | View 0 follows | Borders (h/v) |
|---|---|---|---|
| rm_start, rm_cutscene, rm_battle | 160x144 | nobody | 32 / 32 (IDE default) |
| rm_floor1 | 321x175 | obj_player | 144 / 108 |
| rm_floor2, 3 | 256x176 | obj_player | 144 / 108 |
| rm_floor4 | 208x240 | obj_player | 144 / 108 |
| rm_floor5 | 304x160 | obj_player | 144 / 108 |
| rm_floor6 | 305x335 | obj_player | 144 / 108 |
| **rm_floor6_5** | **144x144** | obj_player | 144 / 108 |
| rm_floor7 | 274x275 | obj_player | 144 / 108 |
| rm_floor8 | 336x175 | obj_player | 144 / 108 |
| rm_floor9 | 321x176 | obj_player | 144 / 108 |
| rm_floor9_5 | 514x207 | obj_player | 144 / 108 |

(view 1..7 are IDE defaults 1366x768, invisible.) Room dimensions are not multiples of 16 (321, 175, 305, 335, 275...).

---

## 2. The scaling model actually in use

### 2a. Intended model (what the code is trying to be)
- Base 160x144 (Game Boy), integer scale 3..5. Windowed: window = 160*s x 144*s, borderless, centred. "Fullscreen" (called `fit_screen`): `window_set_fullscreen(true)`, then the same integer-scaled box centred in the monitor.
- Camera 160x144, view port = base*s, app surface shrunk back to 160x144, GUI set to port size and offset to the port origin. UI is drawn in "port pixels" (e.g. 480x432 at 3x), so UI art is not 8-bit-grid based but resolution-scaled.

### 2b. Where the model is inconsistent
1. **"Fullscreen" does not fill the screen.** `Display_CalcLayout` line 1306-1308 caps at `min(display_scale, max_integer_scale)`. With the default Scale 3x on a 1080p monitor the picture is 480x432 inside 1920x1080 (VERIFIED by the maths). Only the Scale row changes it, max 5x = 800x720; a 1440p/4K monitor never gets bigger than that. The row labelled Fullscreen and the row labelled Scale fight each other.
2. **Three different sizes for one picture.** Port 480x432 (`view_wport`, 1449-1452) vs application surface 160x144 (1464) vs window. How GM draws a 160x144 surface for a 480x432 port, and where the engine's own `option_windows_scale 0` stretch puts the surface, is not defined anywhere in the code (SUSPECTED, runtime-dependent). If the engine stretches the surface "keep aspect" to the whole window while the GUI is placed by `display_set_gui_maximise(1,1,port_x,port_y)`, the world and the UI disagree in fullscreen (world at ~7.5x, UI at 3x). Needs the P then O overlay in fullscreen to confirm (compare "viewport" with the visible picture).
3. **`display_set_gui_maximise(1, 1, port_x, port_y)` semantics** (1471) are not what the comment says ("centered integer-scaled viewport") unless GM treats scale 1 as 1:1. SUSPECTED; the history shows the call was swapped four times (`-1,-1` -> `1,1,x,y`) and never settled.
4. **Text is scaled by a ratio, not an integer.** `UI_GetTextScale` `scr_player.gml:746-769`: at 3x windowed `dyn = 480/800 = 0.6`, so scale = 2.0 * 0.6 = **1.2**; 4x -> 1.6; 5x -> 2.0. A pixel font drawn at 1.2x / 1.6x has uneven pixels. Only fullscreen rounds to 0.5 steps (766). `UI_GetSpriteScale` (776-795) then uses `ceil`, so icons jump in integer steps while text moves in fractions: UI proportions change between 3x/4x/5x.
5. **Reference scale flips with the fullscreen flag** (759): `ref_scale = fit ? 3 : 5`. The same GUI width produces a different UI scale depending on the fullscreen flag.
6. **Rooms disagree on view settings.** rm_start / rm_cutscene / rm_battle have 32/32 borders and no follow; the 11 floors have 144/108 borders (larger than half the 160x144 view) and follow obj_player. ApplyDisplay rewrites the *runtime* border values to 79/71 only after the first Step of the new room (see 2d), so frame 0 of every floor uses the bad borders.
7. **Camera shake vs clamp.** The battle room is exactly view-sized (160x144). Shake offsets push the camera outside `[0, room-view]`; the self-heal (2d) treats that as corrupt (`Step_0.gml:119-125`) and calls ApplyDisplay, which clamps (1457-1459) - a tug of war with `obj_battle_controller/Draw_64.gml:29`. SUSPECTED: the world shake in battle is partly or fully cancelled. UI shake (offset computed in GUI space) is unaffected.
8. **Rooms smaller than the view.** rm_floor6_5 is 144 wide, the view is 160. `max(0, room_width - 160)` = 0 clamps to x=0 (`scr_player.gml:266,1457`, `Step_0.gml:121`), so 16px outside the room is visible (the layer background / window colour). SUSPECTED; walk into rm_floor6_5 and look.
9. **World-to-GUI conversions** (`scr_combat.gml:406-440`, `obj_ui_controller/Draw_64.gml:39-50`, `obj_battle_controller/Draw_64.gml:23-45`) assume the world is drawn exactly in the port rectangle. That is only true if inconsistency #2 resolves in the favour of the port; any other outcome puts the QTE target and HUD shake out of place.
10. **Android / handhelds.** `fit_screen` defaults false (`scr_player.gml:1335`), so on a phone 2400x1080 `Display_CalcLayout` yields a 480x432 box (3x) in the middle of the screen. Window sizing calls are no-ops on Android; `interpolate_pixels true` blurs it; both orientations are enabled. (The PortMaster env-var path and docs added in 8a23294 were removed in a39e192.)
11. **The only display owner is the audio manager.** `obj_sfx_manager` (persistent, created by `obj_game_controller/Create_0.gml:3` via `SFX_EnsureManager`, `scr_sfx.gml:169`) runs all room-change and window-change handling in its `Step_0.gml`. It exists only if an `obj_game_controller` was ever created; all 14 rooms place one, but display handling is coupled to audio code and the boot order.

### 2c. What was tried (git history, 2026-03-05..08, 2026-05-16)
- `cbd14af` fixed gui scaling: per-object world->GUI scale maths in obj_battle_controller / obj_ui_controller / scr_combat.
- `a484f8e` fixed scaling issues: per-screen layout tweaks in scr_menu / scr_save_menu / obj_start_controller.
- `eb90939` tried fixing: Windows `borderless true`, `resize_window false`; default `fit_screen` true -> false; settings migration v6.
- `8a82eb5` "finally solved full screen": `window_set_fullscreen(fit_screen)`, `view_visible[1..7]=false`, border override 79/71, **added the per-frame self-heal in obj_sfx_manager**.
- `aea0e29` fixed full screen: `UI_GetTextScale` fullscreen branch, `UI_GetSpriteScale`.
- `0b31cdb` (2026-05-16): fullscreen aspect preserved; `display_set_gui_maximise(-1,-1)` + `display_set_gui_size(port)`.
- `8a23294` "cleaner": introduced `Display_CalcLayout` (integer only), added layout comparison to the self-heal, `display_set_gui_maximise(1,1,port_x,port_y)`; PortMaster env vars (removed again in a39e192).

Pattern: every fix was a patch in a different layer (UI maths, window options, per-frame repair) and the repair loop grew; no step ever removed the root ambiguity (#2, #3 above).

### 2d. The self-heal poll (obj_sfx_manager/Step_0.gml:66-160), every frame
Triggers `GameSettings_ApplyDisplay()` when any of: room changed (77-85); a transition just ended (87-90); display or window size changed (92-98); or, outside transitions, any of: `view_wport/hport <= 0`, any of views 1-7 visible, camera size != 160x144, camera outside `[0, room-view]`, or the port / gui size differs from `Display_CalcLayout` (101-147). Any mismatch means a full re-apply including `window_center()` and `surface_resize` in the same frame.

---

## 3. Cutscene-end and dialogue-end screen bug

### 3a. What happens, step by step

**Cutscene end** (`objects/obj_start_controller/Step_0.gml`, rm_cutscene):
1. Last segment finishes. Lines 434-441 clear `cutscene_active`, `cutscene_bg_sprite`, `dialogue_box_half`, `cutscene_text_only`, logo, `pending_cutscene_id`.
2. Lines 451-496 pick the exit by `cutscene_id`: intro -> `GameSettings_ApplyAll()` (468) then `Transition_RequestCutsceneFade(rm_floor1, "start", -1, true)` (469); ending -> `rm_start` (473); game_over -> `Save_Read` or `rm_start` (486-490); default -> `Transition_RequestRoomFade(rm_start)` (494).
3. `Transition_Begin` (`scr_room_transition.gml:300`) -> `Transition_Update` (called from `obj_ui_controller/Step_0.gml:3`): CUTSCENE type, fade out 20 frames, `room_goto` (603), 2 frames hold, then fade in 22 frames, then `Transition_Finish()` (616).
4. On the new room: `obj_sfx_manager` sees `room != last_room_id` (77) -> ApplyDisplay; `obj_game_controller/Step_0.gml:10-33` runs `RoomTransition_Apply` and spawns the player; the room's camera follows obj_player.
5. `Transition_Finish()` (417-453) clears state and calls `GameSettings_ApplyDisplay()` (452) **while the screen is fading back in**.

**Dialogue end** (floor1 / floor5 / floor9_5 intro triggers, `rooms/*/InstanceCreationCode_*.gml`, `camera_handoff_use_black = true`):
1. `Dialogue_Advance` (`scr_dialogue.gml:1050-1100`) closes the box: `mode = UI_NONE`, lines cleared, `dialogue_lock` set.
2. `DialogueTrigger_UpdateCinematic` (`scr_player.gml:562-732`): hold -> `pan_out` (camera pans back, 629..677) -> `Transition_RequestBlackFlash` (695, FLASH type, 12 out / 14 in frames, owner = trigger).
3. At full black, `Transition_Update` FLASH phase 0 (`scr_room_transition.gml:564-568`) calls `DialogueTrigger_ApplyBlackHandoff` -> `DialogueTrigger_CleanupCinematic` -> `camera_set_view_target(cam, obj_player)` (400), input lock popped, state reset.
4. FLASH fade-in 14 frames, then `Transition_Finish()` -> `GameSettings_ApplyDisplay()` (452).

Common to both: **a transition ends with `Transition_Finish()`, which re-applies window, view, camera, surface and GUI while the picture is becoming visible again.** Every cutscene segment change is also a FLASH transition (`obj_start_controller/Step_0.gml:397`), so this runs between every cutscene page too.

### 3b. Ranked hypotheses

**H1 - SUSPECTED, most likely: the full display re-apply at the end of every transition causes a visible snap.**
Evidence:
- `scr_room_transition.gml:452` calls `GameSettings_ApplyDisplay()` unconditionally, for FLASH / CUTSCENE / ROOM / ENCOUNTER alike. This is the one thing common to "cutscene ends" and "places with dialogue" (dialogue flash handoff, floor1 intro, post-battle dialogue).
- Inside, VERIFIED to run every time: `window_center()` in windowed mode (`scr_player.gml:1433`, unconditional since 0b31cdb), `window_set_showborder(false)` (1407), `surface_resize` check (1462-1466), `display_set_gui_size` + `display_set_gui_maximise` (1470-1471), `camera_set_view_size` + clamped `camera_set_view_pos` (1456-1459).
- If the runtime has changed any of those between room load and the end of the fade (it re-sizes the application surface to the view ports on room start; SUSPECTED), the re-apply shrinks/moves them back on a visible frame = a one-frame zoom/shift.
- The three sub-causes below make that snap worse.
  - **H1a (VERIFIED order, SUSPECTED effect):** in the intro path `GameSettings_ApplyAll()` runs at `Step_0.gml:468` while the last cutscene image is still on screen (fade has not started). Window re-centre, surface and GUI changes land on a visible frame.
  - **H1b (SUSPECTED):** camera clamp in ApplyDisplay (1457-1459) and the self-heal (`Step_0.gml:119-125`) fight the engine follow camera in rooms smaller than the view (rm_floor6_5, 144 wide) and the cinematic pan_out end position.
  - **H1c (VERIFIED order, SUSPECTED effect):** `window_set_fullscreen()` (1415) is followed in the same call by `window_get_width/height()` (1436-1437). Fullscreen changes apply asynchronously in GameMaker, so the layout is computed against the old window size and corrected one or more frames later by the self-heal (`Step_0.gml:96-98`). Visible when toggling Fullscreen and when a transition ends right after.

**H2 - VERIFIED order, SUSPECTED visual: the cutscene art disappears before the exit fade starts.**
`Step_0.gml:434-435` clears `cutscene_active` and the background sprite; `obj_ui_controller/Draw_64.gml:98-103` only draws the sprite while `cutscene_active`. The exit `Transition_Begin` starts with `alpha = 0` and ramps up over 20 frames (`scr_room_transition.gml:597`), so for the whole fade-out the player sees the empty rm_cutscene room (black_screen background layer, `rooms/rm_cutscene/rm_cutscene.yy`) instead of the last image fading to black. The same happens to the logo on the ending cutscene (`Draw_64.gml:105-116`, `logo_alpha` reset at 440). Result: a hard cut, then a "fade" black on black. Very likely what "screen bug at cutscene end" looks like even if H1 is invisible on the owner's machine.

**H3 - SUSPECTED: the pan_out -> flash handoff leaves the camera on a different position than the engine follow, so a snap shows at fade-in.**
`DialogueTrigger_UpdateCinematic` positions the camera with `camera_set_view_pos` in pan_in/hold/pan_out (629, 644, 677) while follow is suspended (`camera_set_view_target(cam, noone)`, 548). On cleanup, follow is re-enabled during full black (400), so the first visible frame is the engine's follow position; ApplyDisplay then re-clamps it at Finish (H1). The restore-blend path (`DialogueTrigger_BeginFollowRestoreBlend`, 430-464, 716-731) is reached only if `Transition_RequestBlackFlash` fails (e.g. a transition is already active) and its comment says it "samples the engine's follow result", but `camera_get_view_x` right after `camera_set_view_pos` in the same Step returns the value just written, not a follow result; the blend converges on itself and snaps on cleanup. Low frequency (fallback path), but real.

**H4 - SUSPECTED: red / mismatched border (window colour) around the picture in fullscreen and during transitions.**
`options/main/options_main.yy:26` is 255 (red, BGR). `Transition_DrawGUI` (`scr_room_transition.gml:623-639`) only fills `0,0,gui_w,gui_h`, which is the port rectangle, not the window, so a "black" fade leaves the outside area at the window colour. In fullscreen with a small port (2b #1) this is a large coloured frame. Confirm by looking at fullscreen at 3x on a 1080p monitor.

**H5 - SUSPECTED, low: stale camera id after encounter.**
`Transition_CaptureEncounterViewport` (`scr_room_transition.gml:219-242`) caches the overworld camera id and position; the ENCOUNTER branch restores before `room_goto` (531) but leaves `encounter_cam_valid = true`, so `Transition_Finish` calls `Transition_RestoreEncounterViewport` again (421-423, 279-285) in rm_battle against an id from the previous room. If the runtime reuses the camera id, rm_battle's camera is moved to the overworld position for the fade-in; ApplyDisplay at 452 re-clamps it right after. Not the reported bug, but it is a second writer.

**H6 - SUSPECTED, low: leftover cutscene UI flags on interrupted exits.**
`dialogue_box_half` is cleared in exactly one place (`Step_0.gml:436`) and set nowhere in `.gml` (cutscene definitions in `Create_0.gml` presumably), `cutscene_text_only` stays true while `cutscene_active` is true (`scr_dialogue.gml:937-938,959-960,1021-1022,1082-1083`). Leaving rm_cutscene by any path other than the end block (Save_Read mid-cutscene, `Transition_Finish()` forced in `scr_save.gml:351,371`) would keep `cutscene_active` and `gs.ui.cutscene_*` true; `obj_ui_controller/Draw_64.gml:98-117` would then keep drawing the stretched cutscene background over the next room. Check by loading a save from the title right after the intro.

### 3c. Not the cause (checked)
Persistent flags: `obj_ui_controller` and `obj_sfx_manager` are persistent, `obj_game_controller`, `obj_player`, `obj_dialogue_trigger`, `obj_battle_controller`, `obj_start_controller` are not. No code touches `application_surface_draw_enable(false)`, `surface_set_target`, or `draw_surface` - there is no surface leak. The only `draw_clear*`/`gpu_set_scissor` calls: none exist.

---

## 4. Recommended architecture

### 4a. One owner, one rule set
- **Owner:** a new persistent `obj_display` (created once in rm_start, next to the controllers; created via the IDE per AGENTS.md rule 4). `GameSettings_ApplyDisplay`, `Display_CalcLayout` and the self-heal move out of `scr_player` and `obj_sfx_manager` into a new `scr_display` script. `obj_sfx_manager` goes back to audio only.
- **Base resolution:** 160x144, integer scale only. Windowed scales 3-5 (cap to what fits the monitor). Fullscreen = the largest integer scale that fits (`floor(min(winW/160, winH/144))`); drop the dependence on the Scale row. Rename the flag `fit_screen` -> `fullscreen` in the save config.
- **Rendering path:** view 0 in every room is camera 160x144, **port = 0,0,160,144** (port == camera, no in-engine scaling). `application_surface` stays 160x144. `application_surface_draw_enable(false)`; `obj_display` Post Draw event draws the surface with `draw_surface_stretched` (or `draw_surface_ext`) at `scale` integer, centred, after `draw_clear(c_black)`. Also set `option_window_colour` to black (0) in the IDE as a safety net.
- **GUI layer:** `display_set_gui_size(window_w, window_h)` (GUI = window pixels, 1:1, no `display_set_gui_maximise`). All UI draws inside a "game rect" `{x, y, w=160*s, h=144*s}`: in `obj_display` Draw GUI Begin do `matrix_set(matrix_world, matrix_build(x, y, 0, 0,0,0, 1,1,1))` and reset in Draw GUI End. Replace the 17 `display_get_gui_width/height` sites (1d) with `Display_GuiW()` / `Display_GuiH()` returning the rect size so existing layout code is untouched. `Transition_DrawGUI` and `UI_DrawModalDim` use the **window** size (undo the matrix or use absolute coords) so fades and dims cover the borders too.
- **Text/sprite UI scale:** `UI_GetTextScale` = `UI_TEXT_SCALE_BASE * (s / 5)` rounded to 0.5 or to integer steps; no dependency on the fullscreen flag. Pixel font must land on whole pixels.
- **Apply rules (kill the loop):** `Display_Apply()` runs only on (1) boot, (2) Settings > Apply, (3) window/display size change polled in `obj_display` Step, (4) focus regained. **Never** from `Transition_Finish`, cutscene end, save load or a per-frame comparison. `window_center()` only when the window size actually changed. After `window_set_fullscreen()` wait for the window size to change (poll in Step) before computing the layout.
- **Camera rules:** rooms are authored with a 160x144 view, `hborder = 72 / vborder = 64` (or 0 if you want hard centring) and a room size >= 160x144 (fix rm_floor6_5). Runtime never rewrites borders or clamps cameras; shake uses `camera_set_view_pos` offsets in the owning object's Step (not Draw GUI) and is clamped in that code, not by the display system. Encounter zoom caches `view_camera[0]` at capture and drops the cache in the same step as `room_goto`.
- **Cutscene rule:** the cutscene end block keeps `cutscene_active` true until the exit transition is black (clear it in the transition callback, or pass `fade-to-black` as a FLASH with the owner callback). The GUI draw uses a snapshot sprite so the last page fades out.

### 4b. Migration steps (each is a small packet; check first per AGENTS.md rule 1)
1. **Measure (no code change):** build the checklist in 4c, record P then O overlay values (window, display, gui, viewport, camera, `application_surface`) in windowed 3x/5x and fullscreen. This settles H1/H4 and the `surface vs port` and `display_set_gui_maximise` questions (2b #2, #3).
2. **Cheap safe fixes first** (independent of the rewrite): (a) H2 - delay `cutscene_active=false` until the exit transition is at full black; (b) set `option_window_colour` to 0; (c) remove `Transition_Finish -> GameSettings_ApplyDisplay` and fix by only re-applying on a size change; (d) skip `window_center()` unless the size changed. Re-run the checklist.
3. Create `scr_display` + `obj_display` (IDE), port `Display_CalcLayout` with the new "largest fitting integer" fullscreen rule and a unit assertion block (known window sizes -> expected scale/offset; run from a `Debug_*` entry, per Rule 1 table).
4. Switch rooms to port 160x144 (IDE, owner), app surface draw off, add the Post Draw blit and the GUI matrix offset. Keep old code behind the same function names until the checklist passes.
5. Replace the 17 `display_get_gui_*` sites with `Display_GuiW/H()`; make `Transition_DrawGUI` and `UI_DrawModalDim` cover the window.
6. Rewrite `UI_GetTextScale` / `UI_GetSpriteScale` on integer scale; drop the `fit_screen` reference-scale branch.
7. Remove the self-heal block from `obj_sfx_manager/Step_0.gml:100-147` and the display code from `scr_player.gml`; set `settings_version 7` and migrate `fit_screen` -> `fullscreen`.
8. Platform pass: Android (`interpolate_pixels false`, landscape only, `fullscreen` default true so the integer-fit rule applies), Linux/handheld defaults.
9. Fix rm_floor6_5 (144 wide) and normalise floor view borders in the IDE.

### 4c. Acceptance checklist (owner walks through; each box = "looks right, no flicker, no stray colour")
Use P then O for the overlay where a number is asked.

Window sizes (windowed)
- [ ] Settings Scale 3x: window 480x432, picture fills it, no border colour visible, overlay shows gui = window.
- [ ] Scale 4x and 5x: same; 5x fits on the monitor (or is capped automatically).
- [ ] Text looks identical in sharpness at 3x, 4x, 5x (no uneven pixel widths).

Fullscreen
- [ ] Toggle Fullscreen on at 3x scale: picture grows to the largest whole-number size that fits (e.g. 1080p -> 7x = 1120x1008), centred, black bars only.
- [ ] Toggle off: returns to the chosen windowed scale, centred, with no one-frame wrong size.
- [ ] Toggle on/off five times quickly: no stuck size, no red/coloured bars.
- [ ] Alt-tab out and back while fullscreen, and while windowed: picture and UI unchanged, window not moved.
- [ ] Change the monitor resolution / move the window to another monitor: picture re-fits within one second, no stuck layout.

Each room type
- [ ] rm_start (title menu, settings popup, difficulty popup): UI fills the game rectangle, fade covers the whole window.
- [ ] rm_cutscene: image fills the rectangle, text readable, page changes fade smoothly.
- [ ] A floor room (rm_floor1, rm_floor6, rm_floor9_5): camera follows the player, no snap on room entry, no lerp at room edges.
- [ ] rm_floor6_5 (144x144): no area outside the room visible.
- [ ] rm_battle: HUD bars, log and menu aligned; shake moves the world visibly; QTE target sits on the enemy.

Transitions and the reported bugs
- [ ] Cutscene end (intro -> rm_floor1): last image fades to black (does not disappear first), no resize / re-centre / zoom jump, first floor frame is stable.
- [ ] Ending cutscene -> title: logo fades with the picture, title appears without a snap.
- [ ] Dialogue end in rm_floor1 (intro slime), rm_floor5 (mini-boss), rm_floor9_5 (final boss): pan back, black flash, player in the same screen place as before the dialogue, no jump at fade-in.
- [ ] Plain NPC / sign dialogue with no camera move: box appears and closes without any screen change.
- [ ] Post-battle dialogue: no jump when it opens or closes.
- [ ] Battle: enter from overworld (zoom + shake), return to overworld: both rooms centred correctly.
- [ ] Load a save from the title during and right after the intro: no leftover cutscene background.
- [ ] Game over cutscene -> reload: same checks.

Platforms (when applicable)
- [ ] Android landscape phone: picture is the largest integer fit, sharp (no blur), no portrait rotation.
- [ ] Linux / handheld at 640x480: scale 3x, centred, black bars.
