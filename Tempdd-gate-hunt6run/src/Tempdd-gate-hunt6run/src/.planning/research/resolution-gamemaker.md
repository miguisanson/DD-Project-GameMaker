# Resolution, scaling and display handling in GameMaker 2024 (pixel-art, Windows + Android)

Researched 2026-10-13. Target: GameMaker 2024.14 (runtime 2024.14.x), 8-bit turn-based RPG,
base resolution 160x144 (`DISPLAY_BASE_W/H` in `scripts/scr_macros/scr_macros.gml`).

Evidence labels used below:
- **[manual]** read in the official GameMaker manual (via the manual's GitHub source or manual.gamemaker.io).
- **[blog]** official YoYo blog or tutorial.
- **[community]** forum, itch.io, third-party blog (e.g. bugnet.io, low authority).
- **[inferred]** my reasoning from the above or from reading this repo. NOT tested.
- **[UNVERIFIED]** could not confirm from any source; needs the spike in section 8 before you rely on it.

---

## 1. The canonical setup (what every good pixel-art GameMaker project does)

### 1.1 The vocabulary (get this straight first - most bugs come from mixing these up)

| Thing | What it is | Unit |
|---|---|---|
| Room | The world | room pixels |
| Camera (view) | A rectangle of the room that is drawn | room pixels |
| Viewport (`view_xport/yport/wport/hport`) | Where that camera image lands **on the application surface** (not on the window) | application-surface pixels |
| `application_surface` | The off-screen canvas all Draw events render into | its own pixels |
| Display buffer / back buffer | The actual window contents | window pixels |
| GUI layer (Draw GUI events, UI layers) | Drawn straight onto the display buffer on top of everything, with its own coordinate size | "GUI pixels", mapped to the window |
| Window | The OS window (or fullscreen surface) | window pixels |

Draw order **[manual]** (Surfaces page): Pre-Draw (app surface created if missing, render target set) -> for each visible
viewport Draw Begin / Draw / Draw End (target reset at Draw End) -> **Post Draw** (app surface drawn to display buffer
by default) -> Draw GUI Begin / Draw GUI / Draw GUI End. The application surface is created the first time a Draw event
runs in each new room, so nothing exists before that; you may still resize it from Create or any other event and the value
applies when it is created.

### 1.2 The recipe

1. **Pick ONE base resolution and never change it at runtime.** Every room, the camera, the viewport and the application
   surface use exactly that size (here 160x144). Scaling to the window is a *presentation* step done once, in one place,
   and is never baked into camera or viewport sizes. [blog: "the first room / viewport size sets the scale for the whole
   game, keep every room and view the same size"]
2. **Application surface = base resolution.** `surface_resize(application_surface, BASE_W, BASE_H)` once at startup (and only
   again if the base resolution itself changes). The manual's own example does `surface_resize(application_surface, cam_w * scale, cam_h * scale)`
   - for crisp pixel art you want scale 1 (render at base res, upscale with nearest-neighbour), not the 4x supersample
   in that example. [manual: application_surface page]
   - `surface_resize` on the app surface is **not applied until the start of the next draw frame**; `surface_get_width`
     in the same step still returns the old value. It destroys and recreates the surface under the same handle. [manual: surface_resize]
3. **Viewport = same size as the camera = same size as the application surface** (160x144 at port (0,0)).
   The camera image then maps 1:1 onto the app surface. Do **not** make `view_wport/hport` the scaled window rectangle
   (that is the classic "wrong scale" bug - it makes GameMaker's own scaling and yours stack). [inferred from manual: a viewport
   is "the screen area where the view is drawn", scaled in either direction if sizes differ; Room Properties page says non-(0,0)
   viewport positions "can give strange results"]
4. **Turn off linear filtering everywhere.**
   - Game Options > each platform > Graphics > **Interpolate colours between pixels = OFF**. The manual's "Blank Pixel Game"
     template ships with it OFF "because pixels in the final render are not smoothed and everything appears crisp". [manual: Starting a New Project]
   - `gpu_set_texfilter(false)` at startup (default is false). [manual]
5. **Present with integer scaling + letterbox/pillarbox, done by you in Post Draw.**
   - `application_surface_draw_enable(false)` in the manager's Create. [manual]
   - Compute `scale = max(1, floor(min(win_w / BASE_W, win_h / BASE_H)))`, `draw_w = BASE_W * scale`, `ox = (win_w - draw_w) div 2`, same for y.
   - In **Post Draw**: clear the whole display buffer to black (`draw_clear(c_black)`), then
     ```gml
     gpu_set_blendenable(false);
     draw_surface_ext(application_surface, ox, oy, scale, scale, 0, c_white, 1);
     gpu_set_blendenable(true);
     ```
     The blend-off is required: GameMaker auto-draws the app surface without alpha blending, and when you take over you
     "need to handle this yourself" or you get alpha artefacts. [manual: application_surface_draw_enable]
   - Alternative that needs zero code: Game Options > Scaling = **Keep Aspect Ratio** gives black bars but also fractional (non-integer)
     scale, which is why pixel-art projects take over drawing. The manual and the YoYo scaling tutorial both describe Keep Aspect
     Ratio as the simple, least-flexible option. [manual: Set Window State note; blog: scaling-the-game-camera]
   - Warning **[manual]**: `application_surface_enable(false)` (as opposed to `application_surface_draw_enable(false)`)
     "switches off all aspect ratio correction" from Game Options and can crash with Filters & Effects. Use `draw_enable(false)`, not `enable(false)`.
6. **Author the GUI at a fixed GUI resolution** and map it into the same integer-scaled rectangle:
   - `display_set_gui_size(GUI_W, GUI_H)` - "the GUI layer is stretched to fit the size of the game window no matter the
     resolution" and "this function will override the GUI scale and offset set by display_set_gui_maximise". [manual]
     So its default behaviour is *window-filling stretch* (non-integer, no letterbox) - not what you want alone.
   - To put the GUI exactly over the integer-scaled game rectangle, follow the YoYo blog pattern: call `display_set_gui_size`
     first, then `display_set_gui_maximise(sx, sy, ox, oy)` where `sx = draw_w / GUI_W`, `sy = draw_h / GUI_H`, `ox/oy` = the
     rectangle origin in window pixels. (Blog example: `var app = application_get_position(); var w = (app[2]-app[0])/320; ...
     display_set_gui_maximize(w, h, app[0], app[1]);`) [blog: gui-layer-secrets]
     Compute the rectangle yourself instead of `application_get_position()` once you draw the surface manually
     ([UNVERIFIED] whether `application_get_position()` reflects a manually drawn surface).
   - The manual's own wording of the scale argument is confusing ("0.5 doubles the resolution"); the blog example is the practical
     semantics (scale = window pixels per GUI pixel). [inferred] Verify in the spike.
   - Draw UI that must sit in the pillarbox/letterbox (touch buttons, border art) with **negative or over-range GUI coordinates**
     - the blog explicitly shows drawing at x = -64 to use the bar area. [blog: gui-layer-secrets]
   - Mouse/touch in GUI space: use `device_mouse_x_to_gui(n)` / `device_mouse_y_to_gui(n)`, never raw `mouse_x/mouse_y`. [community/manual API]
7. **Camera positions are integers.** Round/floor the camera x/y in one place (End Step) before the draw. Sub-pixel camera
   positions with a nearest-neighbour upscale shimmer/jitter. Smooth sub-pixel scrolling is possible (YAL's technique: view surface
   one pixel larger, camera at floor(x), draw surface offset by frac(x)) but is optional and costs parallax/UI complexity.
   [community: yal.cc smooth pixel-perfect camera + github.com/YAL-GameMaker/pixel-perfect-smooth-camera]
8. **Window management.**
   - Fullscreen toggle: `window_enable_borderless_fullscreen(true)` **before** `window_set_fullscreen(true)` (Windows/macOS only;
     no effect once already fullscreen). [manual]
   - After toggling fullscreen<->windowed, `window_set_size` must be called **at least 10 steps later** (alarm) "otherwise it may
     not work correctly". [manual: window_set_fullscreen, window_set_size]
   - Game Options (Windows): Allow window resize is off by default and only works if Borderless is off; Scaling option is bypassed if
     the application surface is disabled. [manual: Windows game options]
   - There is **no "window resized" event** in GameMaker's Other events list [manual: Other Events page - lists Game Start/End,
     Room Start/End, Views, Outside Room only]. Poll `window_get_width/height` (and `display_get_width/height`) in a Begin Step
     and re-layout when they change. (A `window_has_focus()` poll catches alt-tab restore.)
   - `window_set_min_width/height`, `window_set_max_*` can stop users making the window smaller than 1x base. [manual]
9. **Surfaces other than the app surface are volatile.** They can be destroyed on alt-tab, screensaver, minimise, Android
   focus loss - "always have some type of fail-safe code, usually `surface_exists`". The app surface is the exception
   ("the only thing you cannot do with the application surface is free it"). Any transition / capture / post-effect surface
   must be `surface_exists`-checked and rebuilt every frame it is used. [manual: Surfaces rules, surface_exists]
10. **Cameras are resources.** `camera_create_view` results persist from room to room if kept in a global; stored in an instance
    variable they leak when the room changes. Never `camera_destroy` a camera assigned to a visible view unless you assign a
    new one in the same step. [manual: camera_create_view, camera_destroy] Create ONE camera, keep it in a global, re-bind it
    with `view_set_camera(0, global.cam)` at every Room Start.

### 1.3 "Keep aspect ratio" vs custom pipeline - decision

Use the **custom pipeline** (draw_enable(false) + Post Draw + gui_maximise). Keep the Game Options Scaling at "Keep Aspect
Ratio" as the fallback so a failure degrades to letterboxed rather than stretched. [inferred + manual]

[UNVERIFIED crux, must be proved in the spike]: when `application_surface_draw_enable(false)` and Scaling=Keep Aspect Ratio
are both set, are Post Draw coordinates the full window back buffer, or the already-letterboxed sub-rectangle? Most community
pipelines assume full window; confirm by drawing a magenta border at (0,0)-(window_get_width, window_get_height) and saving a screenshot.

---

## 2. High-DPI / Windows specifics

- Found **no authoritative GameMaker statement** on per-monitor DPI awareness of the Windows runner. [UNVERIFIED]
  Community report (itch.io post/6008317, via search summary): GameMaker games follow the Windows display scale, so the window
  appears larger at 125%/150%; workarounds are exe Compatibility > "Override high DPI scaling", an app manifest, or
  compensating in code (needs an extension to read the scale factor). The GameMaker 2024.14.0 release notes mention DPI work
  only for the IDE. [community + release notes]
- Practical rule: treat `window_get_width/height()` and `display_get_width/height()` as the truth, never compute from a
  remembered "scale"; derive integer scale from them every time; verify by comparing the saved screenshot's pixel size with
  `window_get_width/height()` at 100/125/150/175 percent Windows scaling. If they differ, add a DPI compensation step.
- Windows `Borderless` option + `window_set_showborder(false)` (current project) avoids frame-size mismatch between PCs, which is a
  sound choice. In fullscreen prefer borderless-fullscreen (alt-tab stays fast and does not trigger a display mode change). [inferred]
- Do not rely on `window_set_size` on Android/iOS; on mobile the window is the screen. [inferred, UNVERIFIED]

## 3. Android specifics

- **Aspect ratios are wide and varied** (16:9 up to roughly 21:9, tablets about 4:3 to 16:10, foldables near 1:1). A 160x144
  (about 10:9) field on a 20:9 phone at 2400x1080 gives integer scale 7 (1120x1008) with about 640 px of black each side. That is
  correct; fill it with intentional border art and touch controls rather than stretching. [inferred; arithmetic checked]
- **Orientation.** `options_android.yy` currently has portrait AND portrait-flipped AND both landscapes enabled. For this game
  lock to landscape (+flipped) in Game Options (`os_set_orientation_lock(true,false)` is also available [manual]). Rotation
  mid-play changes window size -> forces a re-layout and is a prime glitch source.
- **Edge-to-edge:** "Enable Edge to Edge Display" exists only for API <= 34 and is **always enabled on API 35+**; "Display Layout"
  controls the cutout mode (current project: `LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT`, edge-to-edge false). [manual: Android Game Options]
  Because edge-to-edge is forced on modern devices, never assume the window excludes system bars: keep important UI inside a margin.
- **Safe area:** I found **no built-in GML safe-area/insets function** in the manual searches (only third-party Marketplace
  extensions "Notch - Mobile" (2020-21) and "iOS safe area"). [UNVERIFIED that none exists in 2024.14] Practical approach:
  the integer-scaled play field is centred and rarely collides with cutouts in landscape; keep touch controls inset by a fixed
  margin (about 5 percent of the shorter side), or read insets with a small native extension if a device test shows overlap.
- **Interpolate colours between pixels is ON for Android** in this project (`option_android_interpolate_pixels: true`) and OFF
  for Windows. That alone makes the Android build blurry. Turn it OFF. [observed in repo]
- Android Game Options > Scaling offers only "keep aspect with padding" vs "stretch to fill". [manual] Keep "aspect".
- Surfaces are destroyed when the app loses focus on Android (explicit in the manual) - the `surface_exists` rule matters double here.
- `display_get_dpi_x/y` exist for density-aware sizing on mobile (iOS/Mac values may be wrong). [manual] Use only for touch-target
  size (physical thumb size), not for game scale.

---

## 4. Known pitfalls that cause glitches on room change / cutscene end / dialogue close

Each row: cause -> symptom -> rule. [manual] unless marked.

| # | Pitfall | Symptom | Rule |
|---|---|---|---|
| 1 | Per-room view settings differ (Enable Viewports off in some rooms, viewport 0 not visible, different camera/viewport sizes). `view_enabled` false => "the whole room is drawn to the screen scaled to the window size". | Wrong scale in one room; fixes itself in another. | One persistent manager re-asserts `view_enabled=true`, `view_visible[0]=true`, `view_visible[1..7]=false`, camera size = base, port = base at **every Room Start**. Do not trust room-editor settings alone. |
| 2 | Camera recreated per room / camera stored on an instance. | Leaks; stale camera id after room change; one-frame wrong view. | One global camera, bound each Room Start. Never destroy the camera bound to a visible view. |
| 3 | `surface_resize(application_surface, ...)` called mid-game (e.g. "heal" logic after a transition ends). Takes effect next frame; surface is recreated (content lost). | One-frame flash / wrong scale right when a cutscene or dialogue ends. | Resize the app surface exactly once at boot. After that only change Post Draw scale numbers, which are free. |
| 4 | `view_wport/hport` or camera size changed for an effect (zoom-in on encounter, cutscene framing) and restored later. | Anything that fails to restore leaves a stale port/camera. | Effects never touch viewport/camera *size*. Use draw-time scale, a camera *position* move, or a UI overlay. If a zoom is wanted, do it by drawing the app surface scaled in Post Draw. |
| 5 | `display_set_gui_size` called anywhere outside the manager, or in a different order than `display_set_gui_maximise`. The manual says gui_size **overrides** gui_maximise's scale/offset. | GUI jumps to full-window stretch or loses its offset after some screen. A YoYo-forum-style report says the GUI is not auto-resized on window change - you must re-apply. [community] | One function `Display_ApplyGui()` is the only caller: size, then maximise, in that order. Re-assert it from the manager when layout changes. |
| 6 | Layout re-applied from a polling "self-heal" in an unrelated object (here: `obj_sfx_manager/Step_0.gml`) that re-runs a full apply after every room change and transition end. | Order-dependent timing; double applies; glitch exactly at transition end. | Layout is computed from window size only, applied only when window size / mode changes, never on room or transition events. Idempotent and cheap. |
| 7 | `window_set_fullscreen` and `window_set_size` called in the same frame. | Wrong size after toggle. | State machine with a 10+ step wait. |
| 8 | Volatile surfaces (transition capture, blur, shake) used without `surface_exists`. | Black/garbage frame after alt-tab, screensaver, fullscreen toggle, Android resume. | Check every use, rebuild lazily. |
| 9 | Sub-pixel camera (camera follow with lerp, shake with float offsets) plus nearest-neighbour upscale. | Shimmering tile seams, jitter. | Round camera x/y in End Step; shake in whole pixels. |
| 10 | Application surface created at a different size than the first room's views imply (blog: surface size comes from the bounding box of active views in the **first room**; default GUI size follows it). | Entire game scaled wrong from launch. | Explicitly `surface_resize` at boot, explicit `display_set_gui_size`; do not let defaults decide. [blog: gui-layer-secrets] |
| 11 | Clear Display Buffer / Clear Viewport Background off while bars or transparent areas exist. Room Properties page: Clear Display Buffer is "always" needed with automatic aspect ratio correction or odd effects show in the letterbox. | Garbage in the bars after a transition or toggle. | `draw_clear(c_black)` first thing in Post Draw every frame. |
| 12 | Third-party code (e.g. a camera asset) that calls `display_set_gui_size` behind your back. There is no `display_get_gui_size`, so it cannot be restored. [community] | GUI wrong after the asset runs. | Re-apply from the single owner after any such call (or avoid such assets). |
| 13 | Room speed / VSync mismatch is not a scaling bug but looks like one (tearing during window moves). | n/a | Keep VSync on (default); 2024.14.2 notes mention a Windows vsync-apply fix. [release notes] |

### 4.1 What this repo does today (from reading code; [inferred], not run)

- `GameSettings_ApplyDisplay()` (`scripts/scr_player/scr_player.gml` about lines 1381-1472) does everything in one function and is
  invoked from a Step event in `obj_sfx_manager/Step_0.gml` (lines 66-155) on room change, transition end, window/display size
  change, and a "self-heal" check. A sound-effects manager owning display state is a design smell.
- It sets `view_wport/hport` to the **scaled** rectangle (`base * scale`) but resizes `application_surface` to **base** size, and
  uses automatic app-surface drawing. Port size != surface size => GameMaker's own scaling is stacked on top of the viewport scaling.
  This is the most likely "wrong scale" root cause. [inferred]
- It calls `display_set_gui_size(port_w, port_h)` then `display_set_gui_maximise(1, 1, port_x, port_y)`. So the GUI size is
  *variable* (e.g. 480x432 at 3x, 800x720 at 5x). All UI code uses `display_get_gui_width()/height()` and compensates
  (e.g. `ref_scale` logic near scr_player.gml:759) instead of authoring at one fixed size. [observed]
- It calls `window_set_fullscreen()` and then `window_set_size()` / `window_center()` in the same call (violates the 10-step rule).
- Transition code (`scr_room_transition.gml` lines about 227-275) stores and rewrites `view_wport[0]` and reads/writes camera
  state for the encounter effect; if any path misses the restore, the viewport stays wrong until the self-heal polls fix it,
  with a one-frame surface resize - matching the "glitch when a cutscene ends" report. Cutscene camera focus in `scr_player.gml`
  (lines about 519-605) also manipulates the camera.
- `options_android.yy`: interpolate pixels ON, portrait orientations ON. `options_windows.yy`: interpolate OFF, borderless ON,
  resize window OFF, `option_windows_scale: 0` (meaning not confirmed - check in the IDE). [observed]

---

## 5. Well-known references and what to reuse

| Resource | URL | Reuse / caveat |
|---|---|---|
| Pixelated Pope - "GameMaker Cameras & Resolution 2026" (4-part video series, from the author of the older "Resolution and Aspect Ratio Management" series; paid, min $2; includes the finished camera controller) | https://pixelatedpope.itch.io/cameras2026 | Best single teaching resource for exactly this problem (draw into a fixed frame, no bilinear filtering, pixel-perfect scaling with dynamic aspect). Buy it / read the final controller code; I could not access the code. Older free blog series by the same author could not be located from search - treat as unfound. |
| GameMaker manual - Surfaces / application_surface / surface_resize / application_surface_draw_enable / application_surface_enable | https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Surfaces/surface_resize.htm (siblings under the same folder) ; source: https://github.com/YoYoGames/GameMaker-Manual | Authoritative for event order, timing (next frame), alpha-blend caveat, scaling bypass. |
| GameMaker manual - display_set_gui_size / display_set_gui_maximise | https://github.com/YoYoGames/GameMaker-Manual/tree/develop/Manual/contents/GameMaker_Language/GML_Reference/Cameras_And_Display | gui_size overrides gui_maximise; -1 resets. |
| GameMaker manual - window_set_fullscreen, window_set_size, window_enable_borderless_fullscreen, window_set_min/max_*, screen_save | same folder, `The_Game_Window/` | 10-step rule, borderless call order, screen_save in Draw GUI End. |
| GameMaker manual - Windows / Android Game Options | .../Manual/contents/Settings/Game_Options/Windows.htm and Android.htm | Edge-to-edge, cutout layout, scaling options, Allow window resize. |
| YoYo blog - "Gui Layer Secrets" | https://gamemaker.io/en/blog/gui-layer-secrets | The canonical explanation of the GUI layer, fixed size, maximise with scale/offset, drawing into the bars with negative coordinates. Written for 2.1.5; semantics still match the 2024 manual. |
| YoYo tutorial - "The basics of scaling the game camera" | https://gamemaker.io/en/tutorials/the-basics-of-scaling-the-game-camera | Official, but oriented to filtered/hi-res games (app surface = display size). Use for the per-room camera setup and "loop all rooms at startup" idea; ignore the display-size surface for pixel art. |
| YAL - "Smooth pixel-perfect camera" | https://yal.cc/gamemaker-smooth-pixel-perfect-camera/ and https://github.com/YAL-GameMaker/pixel-perfect-smooth-camera | Reuse only if sub-pixel smooth scrolling is wanted; otherwise round the camera. |
| STANNcam (MIT, v2.4.3, last push Jan 2025) | https://github.com/jack27121/STANNcam | Camera + resolution manager that avoids GameMaker viewports, independent game/GUI resolution, windowed/borderless/fullscreen. Good *reference* for structure; adopting it would replace the view system and conflicts with the existing cutscene camera code. Recommendation: read it, do not adopt. |
| Marketplace: "Pixel Perfect Scaling Script" (2.3) | https://marketplace.gamemaker.io/assets/6594/pixel-perfect-scaling-script | Small script; derives scale from `window_get_width()/scale`; fine reference, old. |
| Marketplace: Simple Pixel Perfect Camera (2022), Koyan Camera (2021), Rezol (itch.io, Nov 2025, paid), Advanced Resolution Manager (itch.io, free/open) | https://marketplace.gamemaker.io/assets/11058/simple-pixel-perfect-camera ; https://harpwood.itch.io/advanced-resolution-manager | Low-confidence; unmaintained or unverified claims. Not recommended. |
| bugnet.io GameMaker fix articles | https://bugnet.io/blog/fix-gamemaker-camera-view-zoom-incorrect-pixel-perfect (and siblings) | Generic troubleshooting, no clear authorship; the steps match the manual but one example claims integer scaling while its code stretches fractionally. Use as a checklist only. |
| GameMaker 2024.14 release notes | https://releases.gamemaker.io/release-notes/2024/14_0 , .../14_2 , .../14_4 | Search them for "application surface", "fullscreen", "camera" before blaming your code; I could only confirm a DPI (IDE) note and a Windows vsync fix. Not exhaustively read. |

---

## 6. Recommended architecture

### 6.1 One persistent `obj_display` (the only owner)

Created once in the boot/first room, `persistent = true`, never placed in any other room. It is the **only** code allowed to call:
`surface_resize(application_surface, ...)`, `application_surface_draw_enable`, `display_set_gui_size`, `display_set_gui_maximise`,
`window_set_*`, `view_set_camera`, `view_wport/hport/xport/yport` writes, `camera_set_view_size`, `gpu_set_texfilter`.
Add a lint grep to the gate: those calls may appear only in `scr_display.gml` / `obj_display`.

State it owns:

- Constants (macros): `DISP_BASE_W=160`, `DISP_BASE_H=144`, `GUI_W`, `GUI_H` (see 6.3), `DISP_MIN_SCALE=1`.
- `global.cam` (the one camera) and `global.display` struct: `{ win_w, win_h, scale, ox, oy, draw_w, draw_h, fullscreen, pending, generation }`.
- Settings: `fullscreen`, `max_scale` (user cap, optional), loaded from the existing settings struct. The settings menu only *requests* changes:
  `Display_Request({fullscreen: true})`.

Events:

- **Create**: `application_surface_enable(true)`; `application_surface_draw_enable(false)`; `gpu_set_texfilter(false)`;
  `surface_resize(application_surface, BASE_W, BASE_H)`; create `global.cam`; `Display_Relayout()`.
- **Room Start** (fires for persistent instances each room): `Display_BindView()`:
  ```gml
  view_enabled = true;
  view_visible[0] = true;  for (var i = 1; i < 8; i++) view_visible[i] = false;
  view_set_camera(0, global.cam);
  camera_set_view_size(global.cam, DISP_BASE_W, DISP_BASE_H);
  view_xport[0] = 0; view_yport[0] = 0; view_wport[0] = DISP_BASE_W; view_hport[0] = DISP_BASE_H;
  ```
  Nothing else - no surface resize, no GUI call, no window call.
- **Begin Step**: if a window-mode change is pending, advance its state machine (fullscreen toggle -> wait >= 10 steps -> `window_set_size`
  if windowed -> wait 2 -> relayout). Then poll `window_get_width/height`; if different from `global.display.win_w/h`, call `Display_Relayout()`.
  Also relayout when `window_has_focus()` goes false->true (alt-tab return).
- **End Step**: camera positions are rounded (`camera_set_view_pos(cam, round(cx), round(cy))`), via one helper `Camera_Set(x, y)`
  that all gameplay/cutscene code calls instead of touching the camera directly.
- **Post Draw**: `draw_clear(c_black)`; `gpu_set_blendenable(false)`; `draw_surface_ext(application_surface, d.ox, d.oy, d.scale, d.scale, 0, c_white, 1)`; `gpu_set_blendenable(true)`.
- **Draw GUI Begin**: `Display_ApplyGui()` only if `generation` changed since last applied (cheap), else nothing.

`Display_Relayout()` (pure function of window size): `scale = max(1, floor(min(win_w / BASE_W, win_h / BASE_H)))`, honour optional
`max_scale`; `draw_w = BASE_W * scale`; `ox = (win_w - draw_w) div 2`; store; bump `generation`; call `Display_ApplyGui()` which does,
in this order: `display_set_gui_size(GUI_W, GUI_H)` then `display_set_gui_maximise(draw_w / GUI_W, draw_h / GUI_H, ox, oy)`.

Separate the pure math into `Display_CalcLayout` (already exists, nearly right) so the acceptance test can call it with fake sizes.
Cap/limit logic ("fit_screen min(fixed_scale, max)") becomes a user preference `max_scale` only; fullscreen always uses the largest integer scale.

### 6.2 Per-room requirements (checklist, enforced by the manager and a debug assert)

- Room size is a multiple of the tile size; room is at least 160x144; if smaller, centre it by camera clamp (do not shrink the camera).
- Enable Viewports ON, Viewport 0 visible ON, viewport 0 port = 160x144 at (0,0), camera 160x144; viewports 1-7 off. (Manager re-asserts, but keep the room editor honest so the IDE preview matches.)
- Clear Display Buffer ON; Clear Viewport Background ON if the background layer has any transparency.
- No instance in a room calls any function in the owner-only list. No room edits the camera size.
- Camera follow/limits/cutscene focus all go through `Camera_Set` / `Camera_Follow` helpers that clamp to the room and round to integers.
- Transitions and cutscenes draw only in Draw GUI (screen-space, fixed GUI coordinates), or in Post Draw via the manager (e.g. `Display_SetEffect(...)`); they never create viewports, resize the camera or app surface.
- Any surface used (wipes, battle flash, captures) is `surface_exists`-checked on every use and rebuilt lazily.

### 6.3 GUI authored at a fixed resolution - owner decision needed (grill-me)

The GUI must be a fixed `GUI_W x GUI_H`; all UI code stops using the window and reads only `GUI_W/GUI_H` (not
`display_get_gui_width()`, which is acceptable as a synonym once it is always fixed). Choices:

- **A. GUI = base (160x144).** UI shares the world's pixel grid. Most authentic 8-bit look, simplest maths: each GUI pixel = `scale` window pixels exactly.
  Cost: text and menus must be tiny pixel fonts; Korean (the game has `ko` localization) is hard to read at 8x8 or 12x12 on a 160-wide screen.
- **B. GUI = base x 2 (320x288).** Crisper UI text, still integer-friendly when the game scale is even; at odd game scale (3, 5, 7) the GUI scale is x.5 and
  pixel fonts blur or shimmer. Not recommended unless the fonts are vector/hi-res.
- **C. GUI = base x 4 (640x576).** Hi-res UI text (good for Korean), GUI scale = game_scale/4: fractional below 4x, so draw UI sprites at integer multiples only and
  use filtered fonts. Closest to what the code already does at scale 3-5.

My recommendation: **A for everything that is pixel art (HUD, menus, dialogue box), with the Korean font checked for legibility first** (spike: render 3 Korean dialogue lines at 8x8 and 12x12 in a 160x144 GUI). If Korean fails, choose C and accept hi-res text. Do not mix: pick one GUI size and keep it constant on all platforms.

Layout rules for any choice: anchor to edges (left/right/top/bottom/centre), never to absolute window pixels; derive positions from `GUI_W/GUI_H` only; touch
controls and letterbox art use over-range coordinates (negative or > GUI_W), with a safe margin on Android.

### 6.4 Android specifics in the architecture

- Landscape-locked build; the same `Display_Relayout()` handles any window size, so a 20:9 phone gives big side bars. Put the touch controls in the bars (GUI over-range coordinates) with an inset margin.
- `window_set_*` calls are skipped when `os_type == os_android` (wrapped in `Display_Request`).
- Interpolate colours OFF in Android options; Scaling = keep aspect; edge-to-edge assumed ON.
- On app resume the manager forces `Display_Relayout()` and rebuilds all volatile surfaces.

---

## 7. Resolution acceptance test matrix

Pass criteria, for **every** row (geometry is exact because scaling is integer):

1. Game rectangle is exactly `160*s x 144*s`, centred (`ox = (W - 160*s) div 2`), `s = floor(min(W/160, H/144))`, `s >= 1`.
2. Everything outside that rectangle is pure black (or the intentional border art) - no stray pixels, no stretched bars.
3. Downsampling the game rectangle by `s` (nearest) reproduces the 1x reference capture of the application surface byte-for-byte (no blur, no non-integer scale).
4. GUI anchors: magenta corner markers drawn at GUI (0,0), (GUI_W-1,0), (0,GUI_H-1), (GUI_W-1,GUI_H-1) land on the corners of the game rectangle.
5. After every event in the "state change" list (below), the capture is identical in geometry to the capture before it (no drift, no flash, no leftover state).
6. `view_wport/hport == 160x144`, camera size == 160x144, `surface_get_width/height(application_surface) == 160x144`, `display_get_gui_width/height == GUI_W/H`.

### 7.1 Window sizes and aspect ratios (Windows)

| Case | Window size | Aspect | Expected s | Bars |
|---|---|---|---|---|
| min | 160x144 | 10:9 | 1 | none |
| 2x exact | 320x288 | 10:9 | 2 | none |
| 3x exact | 480x432 | 10:9 | 3 | none |
| 720p | 1280x720 | 16:9 | 5 | pillarbox (480 px) |
| 1080p | 1920x1080 | 16:9 | 7 | pillarbox |
| 1440p | 2560x1440 | 16:9 | 10 | pillarbox |
| 4K | 3840x2160 | 16:9 | 15 | pillarbox |
| ultrawide | 3440x1440 | 21:9 | 10 | big pillarbox |
| 16:10 | 1920x1200 | 16:10 | 8 | pillarbox (small letterbox) |
| 4:3 | 1024x768 | 4:3 | 5 | pillarbox + letterbox |
| tall/portrait window | 600x1000 | 3:5 | 3 | large letterbox |
| awkward | 481x433 (and 319x287) | - | 2 (floor) and 1 | extra 1 px gutters, no distortion |
| off-by-one | 1919x1079 | - | 7 (floor) | no exception |

### 7.2 Mode and state transitions (each must end in a passing row above)

- Windowed -> borderless fullscreen -> windowed (x5 repeats); fullscreen on a secondary monitor with a different resolution; fullscreen toggle during dialogue; during a battle; during a transition.
- Window dragged between two monitors with different Windows scaling.
- Windows display scaling at 100, 125, 150, 175 percent (compare screenshot pixel size to `window_get_width/height`; section 2).
- Alt-tab out and back (windowed and fullscreen); minimise/restore; Win+L lock/unlock (screensaver-equivalent); resize by dragging (if "Allow window resize" is enabled).
- Room changes: every room pair transition (overworld <-> town <-> dungeon <-> battle <-> menu <-> start), including room load from a save.
- Cutscene start and **cutscene end**; dialogue open and **dialogue close** (the reported bug); battle start/end; screen shake end; fade in/out end; pause/unpause; settings menu change of fullscreen/scale; language switch (EN <-> KO).
- Saved-settings load at boot with a stale value (e.g. scale larger than the screen allows).

### 7.3 Android

| Case | Device / emulator | Check |
|---|---|---|
| 16:9 phone | 1920x1080, 1080x2400 (20:9), 2400x1080 | landscape locked, s = 7 on 1080 height, bars, touch controls in bars |
| 21:9 / foldable | cover screen (~25:9) and inner screen (~1:1 to 5:4) | inner: s limited by width; no overlap |
| Tablet 16:10 and 4:3 | 1920x1200, 2048x1536 | scale, centring |
| Cutout/notch device | any Pixel with cutout; emulator "Pixel with cutout" overlay | no UI or controls under the cutout |
| API 34 and API 35+ | two emulators | edge-to-edge behaviour identical |
| Rotation | rotate landscape <-> landscape-flipped | relayout, no black frame |
| Background/foreground | home button, 30 s, return | volatile surfaces rebuilt, no wrong scale |
| Gesture/3-button nav | both | controls not under nav bar |
| Blur check | any | zoom a screenshot: pixel edges hard (interpolate OFF) |

Emulate shapes without devices using `adb shell wm size 1080x2400` and `adb shell wm density <n>` (and `wm size reset`), then
`adb exec-out screencap -p > shot.png`. [general Android knowledge, not from GameMaker docs; verify on your adb version]

---

## 8. Spike to run first (half a day, throw-away project or a debug room)

Prove these before rebuilding, because they are [UNVERIFIED]:

1. With `application_surface_draw_enable(false)` and Game Options Scaling = Keep Aspect Ratio (Windows and Android): are Post Draw
   coordinates full-window or letterboxed? Draw a 1 px magenta rectangle around `(0,0,window_get_width(),window_get_height())` and screen_save.
2. `display_set_gui_size(160,144)` + `display_set_gui_maximise(s, s, ox, oy)` puts a GUI marker exactly on the integer rectangle corners
   at several window sizes, and survives fullscreen toggle without re-calling (or find the minimal re-apply set).
3. Whether `application_get_position()` is usable when the surface is drawn manually.
4. Whether `window_get_width()` equals actual back-buffer pixels at 125/150 percent Windows scaling.
5. Korean text legibility at GUI = 160x144 (decides 6.3 A vs C).
6. Whether an Android phone reports a window size equal to the screen with edge-to-edge forced.

---

## 9. Automating the check (screenshots + invariants + diff)

Principle: because scaling is integer, **assert geometry from pixels**, not eyeball. Two layers: (a) a layout report the game writes itself,
(b) a pixel check on a screenshot.

### 9.1 In-game debug harness (no headless build needed)

- Gate it behind a macro `DISPLAY_TEST` or a command-line flag (`parameter_string(i) == "-displaytest"` [manual: parameter_count/parameter_string; index 1 is the first argument]), so shipping builds never run it.
- A `obj_display_test` (or a debug room `rm_display_test`) runs a scripted list of cases:
  `{ name, win_w, win_h, fullscreen, scene, after_event }`.
  For each case: `Display_Request(...)`; wait (>= 10 steps after any fullscreen change, +2 frames after relayout); put the game into the scene
  (overworld, dialogue open, dialogue closed, cutscene end, battle start/end, menu, transition mid-frame); wait 2 frames; then in
  **Draw GUI End** (the only event the manual says is consistent for screenshots) call
  `screen_save(working_directory + "shots\\" + name + ".png")`
  [manual: screen_save is designed for Draw GUI End; saves the final render, or the whole display/window if the app surface is disabled; saves into the game's working directory (on Windows `%LOCALAPPDATA%\<GameName>\`); does not work on HTML5].
- Same frame, write `shots\<name>.json` with `window_get_width/height`, `display_get_width/height`, `global.display` (scale, ox, oy), `surface_get_width/height(application_surface)`,
  `display_get_gui_width/height`, `view_wport/hport[0]`, camera x/y/w/h, `view_enabled`, `view_visible[0..7]`, `os_type`, `fps_real`. A debug overlay
  draws the magenta GUI corner markers and a grid at base resolution.
- Also save a 1x reference with `surface_save(application_surface, "shots\\" + name + "_1x.png")` in Post Draw for the downsample check.
- Run order includes a baseline case, then the state-change cases, then the **same baseline again**; the final capture must equal the first (detects drift/leaks/flash).
- Windows: automate with a PowerShell script that launches the exported exe (or the IDE-run output) with the flag, waits for the process to exit
  (`game_end()` after the last case), then runs the checker. The CLAUDE.md note says no headless build exists; running the exe/IDE is the owner step, the checker is fully scriptable.
- Alt-tab / minimise cases can be driven from PowerShell with user32 `ShowWindow`/`SetForegroundWindow` between captures, or listed as manual rows.
- Android: build the debug flag into a debug APK; pull results with `adb pull` of the app's files dir (or `adb exec-out screencap` for the real compositor output, which also catches system-bar and cutout overlap that `screen_save` cannot).

### 9.2 Checker (Python, `tools/display/check_display.py`, run with `python -I`)

Inputs: PNG + JSON per case. Using Pillow + numpy:

1. **Size match:** PNG dimensions == JSON `window_w/h` (catches DPI scaling mismatch).
2. **Bounding box:** find the non-black bounding box (ignore markers); assert `== (ox, oy, ox + 160*s, oy + 144*s)` from `Display_CalcLayout` recomputed independently in Python.
3. **Bars black:** all pixels outside the rectangle are exactly (0,0,0) (or equal to the border art golden).
4. **Integer scale / no blur:** crop the rectangle, downsample with nearest by `s`, compare to the `_1x.png` reference: must be identical. Also assert the crop contains only colours that exist in the 1x image (no interpolated colours).
5. **GUI corners:** magenta marker pixels at the four rectangle corners, 1 GUI pixel (= s window pixels) in size.
6. **Invariants vs baseline:** JSON equality for the numeric fields that must never change (surface size 160x144, port 160x144, camera size 160x144, GUI size).
7. **Golden diff (optional):** per (scene, size) golden PNG; compare with zero tolerance for the 1x reference, small tolerance (<= 0.1 percent differing pixels) for full-window captures if text AA is involved. Keep goldens only for stable scenes (title screen, a menu, a still overworld frame with `random_set_seed`).
8. Emit a markdown table: case, pass/fail, first failed check, diff image (red overlay) for failures.

### 9.3 Where it fits in the gate

AGENTS.md Rule 1's table for display changes: (1) pure-math unit asserts for `Display_CalcLayout` over the 7.1 table run in a GML assertion block from a debug entry point; (2) the matrix run produces
`shots\` + `report.md`; (3) the owner (or a remote-controlled IDE session) runs the flagged build once per release and confirms `report.md` is all pass; (4) the Android rows are run on two emulators and one real phone before a release.

---

## 10. Summary of recommendations

1. Rebuild the display layer around a single persistent `obj_display`; remove display work from `obj_sfx_manager` and from transition/cutscene code.
2. App surface, viewport and camera are all 160x144 and never change. Scaling happens only in Post Draw (integer, centred, black bars) with `application_surface_draw_enable(false)`.
3. GUI is a fixed size (decide 160x144 vs 640x576 after the Korean-text spike), mapped by `display_set_gui_size` then `display_set_gui_maximise` called from exactly one function.
4. Interpolation OFF on all platforms (Android is currently ON), Android landscape-locked, edge-to-edge assumed.
5. Fullscreen/window changes go through a request state machine with the 10-step wait; no resize or effect code touches viewport/camera/surface size.
6. Verify the six spike items, then build the debug harness + Python checker and make the 7.1/7.2 matrix the acceptance gate.

## Sources

- GameMaker manual (GitHub source): https://github.com/YoYoGames/GameMaker-Manual (pages: Surfaces, application_surface, application_surface_draw_enable, application_surface_enable, surface_resize, surface_exists, display_set_gui_size, display_set_gui_maximise, window_set_fullscreen, window_set_size, window_enable_borderless_fullscreen, view_enabled, view_camera, camera_create_view, camera_destroy, screen_save, parameter_string, Windows/Android Game Options, Room Properties, Other Events, Starting A New Project)
- GameMaker manual surface_resize: https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Drawing/Surfaces/surface_resize.htm
- YoYo blog, Gui Layer Secrets: https://gamemaker.io/en/blog/gui-layer-secrets
- YoYo tutorial, The basics of scaling the game camera: https://gamemaker.io/en/tutorials/the-basics-of-scaling-the-game-camera
- Pixelated Pope, GameMaker Cameras & Resolution 2026: https://pixelatedpope.itch.io/cameras2026
- YAL, Smooth pixel-perfect camera: https://yal.cc/gamemaker-smooth-pixel-perfect-camera/ ; code: https://github.com/YAL-GameMaker/pixel-perfect-smooth-camera
- STANNcam: https://github.com/jack27121/STANNcam
- GameMaker release notes: https://releases.gamemaker.io/release-notes/2024/14_0 , https://releases.gamemaker.io/release-notes/2024/14_2
- Community (low authority, used as hints only): https://itch.io/post/774515/view-in-topic (GUI not following window), https://itch.io/post/6008317 (DPI scaling workarounds), https://itch.io/t/4629575/full-screen-also-scaling-down-my-other-ui-elements, https://bugnet.io/blog/fix-gamemaker-camera-view-zoom-incorrect-pixel-perfect , https://bugnet.io/blog/fix-gamemaker-room-transition-flicker-black-frame , https://bugnet.io/blog/how-to-fix-gamemaker-gui-layer-not-matching-application-surface , https://marketplace.gamemaker.io/assets/9034/notch-mobile
- Repo files read: `scripts/scr_player/scr_player.gml` (GameSettings_ApplyDisplay, Display_CalcLayout), `objects/obj_sfx_manager/Step_0.gml`, `scripts/scr_room_transition/scr_room_transition.gml` (grep), `scripts/scr_macros/scr_macros.gml`, `options/android/options_android.yy`, `options/windows/options_windows.yy`
