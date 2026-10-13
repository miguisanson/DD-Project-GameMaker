# Display design (Phase 2, step A): spike answers, architecture, step-B plan

Spike run 2026-10-14 in a scratch copy (`E:\Temp\dd-disp-spike`, Igor VM build, `LOCALAPPDATA` redirected, 2560x1440 monitor at 100 percent). Code, scripts and
pictures: `display-spike/` (`spike_scratch_code.gml.txt`, `analyze_grabs.py.txt`, `ui_*.png`, `window_*.png`). Method: the game ran at 6 window sizes (480x432 to
2560x1440, incl. 1000x700), and a PowerShell `PrintWindow` grab of the REAL window plus `screen_save` PNGs were checked pixel by pixel (picture rectangle,
black bars, magenta outline on the window edge, cyan markers on GUI corners, 1x reference vs picture downsample). Fullscreen was never entered (rule).
Evidence is "measured" unless marked "not tested".

## 1. The six unverified points (resolution-gamemaker.md section 8)

1. **Post Draw / draw coordinates: full window, not the letterboxed rectangle (measured, Scaling = Keep Aspect and also -1).** At every size the magenta outline
   landed on all four window edges and the picture rectangle on `((W-160s)/2, (H-144s)/2)` exactly, black bars had 0 stray pixels, and the 1x-vs-downsample
   diff was 0 with 100 percent uniform s x s blocks (no blur). Same result when the blit runs in a Post Draw event or inside a Draw GUI event (see 3.2).
   Catch: with `option_windows_scale 0` (Keep Aspect) `screen_save` writes only the engine's aspect rectangle (1920x1080 window -> 1200x1080 PNG, bars cut off).
   With `option_windows_scale -1` the PNG is the whole window at every size (measured; I assume -1 is the IDE's full-scale choice, owner to confirm the label).
2. **`display_set_gui_maximise(sx, sy, ox, oy)` puts GUI corners exactly on the integer rectangle (measured)**, at sx = s (GUI 160x144), sx = ui_scale and sx = s/4
   (fractional, 640x576), all 6 sizes: marker bbox == rectangle (at 2560x1440 with ui_scale 3 the right edge is 1 px short = the spare pixel). Gotchas:
   (a) maximise REPLACES the GUI size: `display_get_gui_*` then returns window/scale (960x540 at 1080p, ui_scale 2), so UI code must read its own `gui_w/gui_h`;
   (b) `display_set_gui_size(window)` WITHOUT maximise is squeezed into the engine aspect rectangle (1920 -> 1200 px wide): never do that;
   (c) after `window_set_size` the GUI size follows (window/scale) but the OFFSET stays stale, so re-apply on every window-size change; the `gui_size` call is not needed.
   Fullscreen toggle: not tested (same re-apply rule applies).
3. **`application_get_position()` is NOT our rectangle (measured)**: with the surface drawn by hand it still returns the engine aspect rectangle (360,0,1560,1080 at 1080p;
   ours is 400,36,1520,1044). Unusable; compute the rectangle ourselves (`Display_CalcLayout`).
4. **DPI: runner is System-DPI-aware (awareness 1, 96 dpi here); `window_get_*` == real window == `PrintWindow` size == `GetClientRect` at all sizes (measured at 100 percent).**
   125, 150, 175 percent not tested (changing Windows scaling is a system setting). System-aware means no OS bitmap scaling on the primary monitor at any scale,
   so window_get_* stays physical pixels; a monitor with a different scale would be bitmap-scaled by Windows (L5 owner check, DISP-11).
5. **Korean at GUI 160x144 fails D8 (measured, `ui_korean_at_160x144_grid_3x.png`)**: Nanum at 5-6 pt (7-8 px) is a smudge, 8-9 pt (11-12 px) reads but only about 13 syllables fit a
   line, and a 3x nearest enlargement of an anti-aliased TTF is soft-blocky. Option A is out; use the finer grid in section 2.
6. **Android: not applicable (D52, Windows only).** Not tested.

Other measured facts the design rests on:
- `window_set_size` is synchronous for `window_get_*`; GUI size and `application_get_position` follow one frame later (t+1). During the first ~20 frames after boot they lag
  (GUI 240x216 and rect 0,0,480x432 seen for several frames at 1080p) -> run the layout once more about 30 frames after boot.
- Every room start the engine re-applies the ROOM's own view (port 480x432, borders 144/108 or 32/32). Code in `obj_game_controller` Create (runs in every room, before the first
  Draw) fixes it: the first drawn frame already had port 160x144 and surface 160x144, and the GUI scale survived room changes (apart from the boot lag above). The application surface was never resized after boot, in 5 room changes.
- `screen_save` from a Step event == from Draw GUI End (0 differing pixels), so the existing `-shots` timing is fine with a manual blit.
- Camera follow keeps working with the room's own camera (borders reset to 79/71 in code): rm_floor1 camera y = 23 on the player. rm_floor6_5 (144 wide) shows camera x = -16, i.e. 16 px outside the room (DISP-10).
- **Gate side effect (measured, not a display bug): the game window is NOT minimized and takes the foreground.** Launched with SW_SHOWMINNOACTIVE, at 273 ms it was already the
  foreground window and `IsIconic` was false. `run_tests.ps1` starts the game the same way, so it most likely steals focus too (inferred, not run); `PrintWindow` grabs of the real window work. Needs an owner decision (section 5).
- Doc arithmetic fix: `resolution-gamemaker.md` 7.1 says 481x433 -> scale 2; the rule gives 3 (481/160 = 3.006). `Test_Suite_Display` pins 3.

## 2. UI grid rule for D8 (decided by the spike; owner may veto)

Candidates compared at windowed 3, 4, 5 and 1080p fullscreen (`ui_*.png`; R1 = today's look in a 640x576 grid, R2 = integer GUI scale, R3 = R2 plus Korean drawn at final pixels):
R1 is uneven at 3 and 5 (a comb of 1-unit lines shows doubled and missing columns, Korean stroke weights vary; GUI scale 0.75 and 1.25). R2 and R3 are clean everywhere.
At ui_scale 2 (1080p) R3's Korean is crisp, R2's is soft-blocky (a 2x enlargement).

**Rule: GUI unit = `ui_scale` window pixels, an integer. `ui_scale` = the integer that makes the grid width `game_w / ui_scale` closest to 640 (compared as a ratio).**
Windowed scale 3 / 4 / 5 -> grid 480x432 / 640x576 / 800x720 (ui_scale 1: a UI pixel is 1/3, 1/4, 1/5 of a world pixel); scale 6-9 -> ui_scale 2 (1080p fullscreen = scale 7 =
560x504); 10-13 -> 3 (1440p = 533x480, 1 spare px); 14-17 -> 4 (4K = 600x540). So D8's 640x576 is exact only at scale 4 (and 8, 12); the others are the nearest integer-exact
grids. Layout must use anchors and the layout's `gui_w/gui_h` (they differ per scale). Implemented as `Display_UiScaleFor` / `Display_CalcLayout.gui_*`.
Text (step B, owner look-check at L5): English pixel font = 2 px per font pixel at scale 1.0, so draw it at multiples of 0.5 in GUI units: window px per font pixel
`n = max(ui_scale, round(round(0.8 * scale) / ui_scale) * ui_scale)` (scale 3/4/5 -> 2/3/4, close to today's 2.4/3.2/4), text scale `n / (2 * ui_scale)`. Korean TTF: `font_add` at the
FINAL window-pixel size (about 0.75 x the English line height / 1.333 pt) and draw it at scale `1 / ui_scale`. Sprites/UI art: integer multiples only.

## 3. Architecture

### 3.1 One owner, applied only on change
`global.display` (struct) and `Display_*` in `scr_display.gml` are the only code allowed to call: `window_set_*`/`window_center`, `surface_resize`, `application_surface_*`,
`display_set_gui_*`, `view_enabled/visible/x/y/wport/hport`, `camera_set_view_size/border`, `gpu_set_texfilter`. A source guard (grep, gate step) enforces it. Camera POSITION/target writes (follow,
cinematic, shake) stay with gameplay code but go through whole pixels and never from Draw GUI (DISP-13).
- `Display_Init()` once (boot): `application_surface_draw_enable(false)`, `gpu_set_texfilter(false)`, `surface_resize(application_surface, 160, 144)` (never again), first layout.
- `Display_Update()` every frame (cheap): window size/fullscreen polled -> `Display_NeedsRelayout` -> `Display_Relayout()` = `Display_CalcLayout` + `display_set_gui_maximise(u,u,gui_x,gui_y)`
  + `apply_count++`. Also on frame 30, on focus regain, and from `Display_Request({scale|fullscreen})` (Settings Apply; a small state machine: fullscreen change, wait 10+ steps, then size, then relayout).
  Never from room change, transition end, cutscene end, save load or run start (DISP-08; `apply_count` proves it).
- `Display_BindRoom()` at every room start (from `obj_game_controller` Create): `view_enabled`, only view 0 visible, `camera_set_view_size(160,144)`, borders 79/71, port 0,0,160,144.
  Per-room fixes live in code, so no room `.yy` edit is needed. No surface, GUI or window call here.
- `Display_DrawFrame()` first thing in the GUI stage: `draw_clear(c_black)`; blend off; `draw_surface_ext(application_surface, 0, 0, scale/ui_scale, scale/ui_scale, ...)`; blend on.
  GUI origin = picture corner, so the blit is at exactly 0,0 (measured exact at 2560x1440 with the 1 px spare). Fades and dims draw `Display_WindowRectInGui` to cover the bars.
- Helpers (done, tested): `Display_CalcLayout`, `Display_UiScaleFor`, `Display_MaxScale`, `Display_WindowSizeForScale`, `Display_NeedsRelayout`, `Display_WorldToGui`, `Display_WindowRectInGui`.
  Step B adds `Display_GuiW/H()`.

### 3.2 Where it runs (no .yy edits)
`obj_display` in the repo has no events (`eventList` empty, `persistent` false) and is in no room, and Post Draw needs a new event, so step B hosts the calls elsewhere:
the blit works inside a Draw GUI event (measured, identical to Post Draw), as long as its object draws first (`depth = 1000000`, GUI draws by depth).
Preferred (owner, 2 minutes in the IDE): give `obj_display` events Create, Begin Step, Draw GUI and tick persistent; `obj_game_controller` creates it once (it exists in every room).
Fallback if that is not done: `obj_ui_controller` (persistent, has Step and Draw GUI) hosts them; NOT `obj_sfx_manager` (audio only, DISP-02). `obj_display`'s Create sets `persistent = true` anyway.

## 4. Old call sites to remove or redirect (line numbers at 055faa7)
- `GameSettings_ApplyDisplay` (`scr_player.gml:1384-1475`) and `Display_CalcLayoutLegacy` (`:1300`, renamed this step; the old `Display_CalcLayout` took 6 args and clashed): delete after step B.
- Callers of the display part: `obj_sfx_manager/Step_0.gml:66-160` (whole self-heal block incl. `:129` and `:150`; the audio parts stay), `obj_sfx_manager/Create_0.gml:70` (`GameSettings_ApplyAll` -> language+audio only),
  `scr_room_transition.gml:452` (`Transition_Finish`), `obj_start_controller/Step_0.gml:468` (intro end), `scr_save.gml:416` (load), `scr_player.gml:1488` (`GameSettings_Commit`) and `:1516` (`GameSettings_SetScale`) -> `Display_Request`,
  `scr_menu.gml:2325` (Apply, via Commit), `scr_debug.gml:492` (`-shots` -> `Display_Request`).
- Direct view/camera/port/surface/GUI writes: `scr_room_transition.gml:227-283` (encounter zoom stores and rewrites ports and camera size; replace by a draw-time zoom in `Display_DrawFrame` or a camera POSITION move),
  `obj_battle_controller/Draw_64.gml:29` (shake `camera_set_view_pos` inside Draw GUI -> a Step event, whole pixels), `scr_player.gml:403-728` (cinematic camera: positions only, keep, no size/port).
- World to GUI: `scr_combat.gml:406-440`, `obj_ui_controller/Draw_64.gml:39-50`, `obj_battle_controller/Draw_64.gml:23-45`, `obj_battle_controller/Create_0.gml:129-130` -> `Display_WorldToGui`.
- `display_get_gui_width/height`, 37 calls in 12 files (DISP-09 said 36 in 11; `scr_debug.gml:192` `Build_DrawId` is new): `scr_menu` 8, `scr_save_menu` 4, `scr_player` 4 (`UI_GetTextScale`, `UI_DrawModalDim`),
  `scr_dialogue` 4, `obj_sfx_manager/Draw_64` 4 (+2 in Step), `scr_room_transition` 2 (`Transition_DrawGUI` -> `Display_WindowRectInGui`), `scr_combat` 2, `obj_ui_controller` 2, `obj_start_controller` 2,
  `obj_battle_controller` 2, `scr_debug` 1 -> `Display_GuiW/H()`. `UI_GetTextScale/SpriteScale/PopupMetrics` ratio and `fit_screen` logic -> the section 2 integer rule.

## 5. Step B plan and checks
1. **B1 wiring (check first: counter).** Extend `Test_Suite_Display` for the request state machine (pure part); add `-smoke` asserts that `apply_count` does not change across room changes, a transition end, a cutscene end and a save load (DISP-08). Then add `Display_Init/Update/Request/BindRoom/DrawFrame`, host them, delete the section 4 callers.
2. **B2 shots rework (L3/L4).** `-shots` at windows 480x432, 640x576, 800x720, 1000x700, 1920x1080 via `Display_Request`; `[SHOT]` line gains appPos; `Test-Shots` checks PNG size == window size (needs Scaling -1) else appPos rectangle,
   picture rectangle from `Display_CalcLayout`, 0 non-black pixels outside it, 1x reference identical after nearest downsample. New captures: **right after a cutscene end** (intro to rm_floor1, at +1, +10, +40 frames after `Transition_Finish`)
   and **right after a dialogue end** (rm_floor1 intro dialogue, same offsets): geometry identical to the pre-event capture, `apply_count` unchanged, last cutscene image fades (H2). Open every PNG.
3. **B3 guards.** Python source guard (`tools/display/lint_display_calls.py`, run by the gate): owner-only calls outside `scr_display`/`obj_display`, and any `display_get_gui_*` outside `Display_GuiW/H`. Negative control: plant a call, see GATE FAIL.
4. **B4 UI.** Integer text rule, Korean at final pixels, `fit_screen` -> `fullscreen` (settings_version 8, DISP-14), `rm_floor6_5` clamp (DISP-10), H2 and H6 fixes. L5: owner looks at 3/4/5 and fullscreen.
5. **Owner decisions/IDE tasks:** (a) window colour black (`options_main`, 255 = red today); (b) Windows Scaling = the -1 choice (shots become whole-window, 1 minute); (c) add the three `obj_display` events (3.2);
   (d) DISP-11 needs "Allow window resize" ON and borderless handled (resize only works with borderless off); (e) the gate's launch does not stay minimized and steals focus: accept, or use a small off-screen window position; (f) D8 wording: grid is 480/640/800 wide at scale 3/4/5, not always 640.
6. **Not tested here, needs owner L5 or a quiet-PC run:** real fullscreen on/off x5, alt-tab, minimize/restore, monitor with another Windows scale, 125-175 percent DPI.
