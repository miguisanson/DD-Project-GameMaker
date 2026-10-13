// scr_display: the display layer (DISP-02/03/08/09). See .planning/research/display-design.md.
// Part 1 (top, up to "the request state machine"): pure maths, side-effect free, tested by Test_Suite_Display (scr_test.gml).
// Part 2 (THE OWNER): global.display and Display_Init / Update / Request / Relayout / BindRoom / DrawFrame, the ONLY code that
// calls window_set_*, window_center, surface_resize, application_surface_*, display_set_gui_*, view_*port, view_visible,
// view_enabled, camera_set_view_size/border, gpu_set_texfilter (tools/display/lint_display_calls.py is the guard, step B3).
// Today these run from obj_game_controller (Create: Init + BindRoom), obj_ui_controller (Step: Update) and the top of every Draw GUI
// event (DrawFrame, once per frame). When obj_display gets events (Create, Begin Step, Draw GUI Begin) they move there unchanged.

// The UI grid target from D8: a 4x grid, 640 wide on a 160-wide world.
#macro DISPLAY_UI_TARGET_W 640
// The UI font's own pixel is this many window pixels at text scale 1.0 (retro_gaming; measured in the spike).
#macro DISPLAY_FONT_PX 2

// The integer UI scale u for a game rectangle _game_w pixels wide: the u whose grid width (_game_w / u) is closest to 640,
// compared as a ratio. u goes up from k to k+1 when _game_w / 640 reaches sqrt(k * (k + 1)), so windowed 3, 4, 5 -> 1,
// 1080p fullscreen (scale 7) -> 2, 1440p (scale 10) -> 3, 4K (scale 15) -> 4.
function Display_UiScaleFor(_game_w) {
    var _v = max(1, _game_w) / DISPLAY_UI_TARGET_W;
    var _u = 1;
    while (_v * _v >= _u * (_u + 1)) _u++;
    return _u;
}

// Layout for a window of _win_w x _win_h: the largest whole-number scale of the base picture that fits, centred.
// _fullscreen: fullscreen always takes the largest fit. _max_scale (> 0): a user cap that applies only when windowed.
// Returns { win_w, win_h, fullscreen, scale, game_x, game_y, game_w, game_h, ui_scale, gui_w, gui_h, gui_x, gui_y }.
//   game_*  the picture rectangle in window pixels (everything outside it is black)
//   ui_scale  window pixels per GUI unit (integer, see Display_UiScaleFor)
//   gui_w/h  the size to give display_set_gui_size (game size / ui_scale, rounded down)
//   gui_x/y  where GUI (0,0) sits in window pixels: the picture's top-left corner (game_x/y). When ui_scale does not divide
//            the picture, the 1-2 spare pixels are on the right/bottom, so a surface blit in GUI space is at exactly 0,0
function Display_CalcLayout(_win_w, _win_h, _base_w = DISPLAY_BASE_W, _base_h = DISPLAY_BASE_H, _fullscreen = false, _max_scale = 0) {
    var _ww = max(1, floor(real(_win_w)));
    var _wh = max(1, floor(real(_win_h)));
    var _bw = max(1, floor(real(_base_w)));
    var _bh = max(1, floor(real(_base_h)));
    var _s = max(1, floor(min(_ww / _bw, _wh / _bh)));
    if (!_fullscreen && _max_scale > 0) _s = max(1, min(_s, floor(_max_scale)));
    var _gw = _bw * _s;
    var _gh = _bh * _s;
    var _gx = floor((_ww - _gw) / 2);
    var _gy = floor((_wh - _gh) / 2);
    var _u = Display_UiScaleFor(_gw);
    var _guw = _gw div _u;
    var _guh = _gh div _u;
    return {
        win_w: _ww, win_h: _wh, fullscreen: _fullscreen,
        scale: _s, game_x: _gx, game_y: _gy, game_w: _gw, game_h: _gh,
        ui_scale: _u, gui_w: _guw, gui_h: _guh,
        gui_x: _gx,
        gui_y: _gy
    };
}

// The largest whole-number scale an area (a monitor or a window) allows; never below 1.
function Display_MaxScale(_area_w, _area_h, _base_w = DISPLAY_BASE_W, _base_h = DISPLAY_BASE_H) {
    return max(1, floor(min(max(1, _area_w) / max(1, _base_w), max(1, _area_h) / max(1, _base_h))));
}

// The windowed size the Settings scale row asks for.
function Display_WindowSizeForScale(_scale, _base_w = DISPLAY_BASE_W, _base_h = DISPLAY_BASE_H) {
    var _s = max(1, floor(_scale));
    return { w: _base_w * _s, h: _base_h * _s };
}

// DISP-08: should the display be re-laid-out? Only when there is no layout yet, or the window size or fullscreen flag
// really differs from the one the layout was made for. Never because a room, transition or cutscene changed.
function Display_NeedsRelayout(_layout, _win_w, _win_h, _fullscreen) {
    if (!is_struct(_layout)) return true;
    return _layout.win_w != max(1, floor(_win_w)) || _layout.win_h != max(1, floor(_win_h)) || _layout.fullscreen != _fullscreen;
}

// A world point to GUI coordinates (QTE targets, shake, HUD that follows a sprite). The camera is 1:1 with the base
// picture, so one world pixel is scale / ui_scale GUI units. Returns { x, y } (not rounded).
function Display_WorldToGui(_layout, _world_x, _world_y, _cam_x, _cam_y) {
    var _k = _layout.scale / _layout.ui_scale;
    return { x: (_world_x - _cam_x) * _k, y: (_world_y - _cam_y) * _k };
}

// The whole window as a rectangle in GUI units (it starts at negative x/y when there are bars). Fades, dims and anything
// that must cover the bars too draw this rectangle instead of 0,0,gui_w,gui_h. Returns { x, y, w, h } (not rounded).
function Display_WindowRectInGui(_layout) {
    var _u = _layout.ui_scale;
    return { x: -_layout.gui_x / _u, y: -_layout.gui_y / _u, w: _layout.win_w / _u, h: _layout.win_h / _u };
}

// ---- the request state machine (pure) ----------------------------------------------------------------------------
// Settings Apply, a boot, or a test asks for a fullscreen flag and a windowed size. Fullscreen and size changes land over several
// frames, so the request is a small machine stepped once per frame: DISPLAY_FS_WAIT frames after a fullscreen change, then the
// windowed size and a re-centre (only when the size really changes), then DISPLAY_SETTLE_FRAMES for the GUI to follow, then "done"
// (the caller lays out once). Anything that never lands gives up after DISPLAY_REQUEST_TIMEOUT frames and lays out what is there.
#macro DISPLAY_FS_WAIT 10
#macro DISPLAY_REQUEST_TIMEOUT 60
#macro DISPLAY_SETTLE_FRAMES 2
#macro DISPLAY_BOOT_RELAYOUT_FRAME 30

function Display_RequestNew(_fullscreen, _win_w, _win_h) {
    return { fullscreen: _fullscreen, w: _win_w, h: _win_h, phase: "start", wait: 0 };
}

// _obs: { fullscreen, win_w, win_h } as observed this frame. Returns { req (the next state), cmd }.
// cmd: { kind: "none" | "fullscreen" | "size", fullscreen, w, h, center }
function Display_RequestStep(_req, _obs) {
    var _r = { fullscreen: _req.fullscreen, w: _req.w, h: _req.h, phase: _req.phase, wait: _req.wait };
    var _cmd = { kind: "none", fullscreen: _r.fullscreen, w: 0, h: 0, center: false };
    var _size_ok = (_obs.win_w == _r.w && _obs.win_h == _r.h);
    switch (_r.phase) {
        case "start":
            if (_obs.fullscreen != _r.fullscreen) {
                _cmd.kind = "fullscreen";
                _r.phase = "fs";
                _r.wait = 0;
            } else if (!_r.fullscreen && !_size_ok) {
                _cmd.kind = "size";
                _cmd.w = _r.w;
                _cmd.h = _r.h;
                _cmd.center = true;
                _r.phase = "size";
                _r.wait = 0;
            } else {
                _r.phase = "done";
            }
            break;
        case "fs":
            _r.wait++;
            if (_r.wait >= DISPLAY_REQUEST_TIMEOUT) {
                _r.phase = "done";
            } else if (_obs.fullscreen == _r.fullscreen && _r.wait >= DISPLAY_FS_WAIT) {
                if (_r.fullscreen || _size_ok) {
                    _r.phase = "done";
                } else {
                    _cmd.kind = "size";
                    _cmd.w = _r.w;
                    _cmd.h = _r.h;
                    _cmd.center = true;
                    _r.phase = "size";
                    _r.wait = 0;
                }
            }
            break;
        case "size":
            _r.wait++;
            if (_size_ok) {
                _r.phase = "settle";
                _r.wait = 0;
            } else if (_r.wait >= DISPLAY_REQUEST_TIMEOUT) {
                _r.phase = "done";
            }
            break;
        case "settle":
            _r.wait++;
            if (_r.wait >= DISPLAY_SETTLE_FRAMES) _r.phase = "done";
            break;
    }
    return { req: _r, cmd: _cmd };
}

// ---- THE OWNER ---------------------------------------------------------------------------------------------------
function Display_TestRun() {
    return Scenario_HasFlag("-smoke") || Scenario_HasFlag("-bot") || Scenario_HasFlag("-shots") || Scenario_HasFlag("-runtests");
}

// Boot, once. Takes the display over from the engine's defaults: no automatic application-surface draw (Display_DrawFrame does it,
// integer scale, centred, black bars), nearest-neighbour textures, a black window colour, a 160x144 surface that is never resized again.
function Display_Init() {
    if (variable_global_exists("display") && is_struct(global.display)) return;
    global.display = {
        layout: undefined, apply_count: 0, frame: 0, drawn_frame: -1, boot_relayout_done: false, req: undefined, req_cmds: 0,
        had_focus: window_has_focus(), want_fullscreen: false, want_scale: DISPLAY_SCALE_DEFAULT,
        zoom: 1, zoom_cx: 0, zoom_cy: 0
    };
    application_surface_draw_enable(false);
    gpu_set_texfilter(false);
    surface_resize(application_surface, DISPLAY_BASE_W, DISPLAY_BASE_H);
    window_set_colour(c_black);
    Display_Relayout();   // a layout exists from the first frame; the request below corrects the window
    var _st = GameSettings_Ensure();
    Display_Request({ fullscreen: _st.fit_screen && !Display_TestRun(), scale: _st.display_scale });
}

// Ask for a window state. Any of: fullscreen (bool), scale (the Settings scale row, 3..5), window_w + window_h (tests, DISP-11).
// A request that is already satisfied does nothing (no window call, no re-layout). A newer request replaces an unfinished one.
function Display_Request(_o) {
    Display_Init();
    var _d = global.display;
    if (variable_struct_exists(_o, "fullscreen")) _d.want_fullscreen = _o.fullscreen;
    if (variable_struct_exists(_o, "scale")) _d.want_scale = _o.scale;
    var _w, _h;
    if (variable_struct_exists(_o, "window_w") && variable_struct_exists(_o, "window_h")) {
        _w = _o.window_w;
        _h = _o.window_h;
    } else {
        var _fit = Display_MaxScale(display_get_width(), display_get_height());   // a window never asks for more than the monitor holds
        var _sz = Display_WindowSizeForScale(min(_d.want_scale, _fit));
        _w = _sz.w;
        _h = _sz.h;
    }
    _d.req = Display_RequestNew(_d.want_fullscreen, _w, _h);
    _d.req_cmds = 0;
}

// Tests run windowed whatever the saved setting says.
function Display_ForceWindowed() {
    if (window_get_fullscreen()) Display_Request({ fullscreen: false });
}

// Called once per frame. Cheap: three window reads and a compare. Applies only on a real change (DISP-08).
function Display_Update() {
    Display_Init();
    var _d = global.display;
    _d.frame++;
    var _ww = window_get_width(), _wh = window_get_height(), _fs = window_get_fullscreen();
    if (is_struct(_d.req)) {
        var _st = Display_RequestStep(_d.req, { fullscreen: _fs, win_w: _ww, win_h: _wh });
        _d.req = _st.req;
        if (_st.cmd.kind != "none") _d.req_cmds++;
        if (_st.cmd.kind == "fullscreen") {
            window_set_fullscreen(_st.cmd.fullscreen);
        } else if (_st.cmd.kind == "size") {
            window_set_size(_st.cmd.w, _st.cmd.h);
            if (_st.cmd.center) window_center();
        }
        if (_d.req.phase == "done") {
            _d.req = undefined;
            // A request the window already satisfied (no command was needed) changes nothing: no re-layout (DISP-08).
            if (_d.req_cmds > 0 || Display_NeedsRelayout(_d.layout, window_get_width(), window_get_height(), window_get_fullscreen())) Display_Relayout();
        }
        return;
    }
    var _focus = window_has_focus();
    var _regained = (_focus && !_d.had_focus && _d.frame > DISPLAY_BOOT_RELAYOUT_FRAME * 2);
    _d.had_focus = _focus;
    var _need = Display_NeedsRelayout(_d.layout, _ww, _wh, _fs) || _regained;
    if (!_d.boot_relayout_done && _d.frame >= DISPLAY_BOOT_RELAYOUT_FRAME) {
        _d.boot_relayout_done = true;   // the first ~20 frames after boot lag behind the window (measured), so lay out once more
        _need = true;
    }
    if (_need) Display_Relayout();
}

// The one place the window size becomes a layout: CalcLayout, then the GUI scale and origin. Counted (DISP-08).
function Display_Relayout() {
    var _d = global.display;
    var _l = Display_CalcLayout(window_get_width(), window_get_height(), DISPLAY_BASE_W, DISPLAY_BASE_H, window_get_fullscreen(), 0);
    _d.layout = _l;
    display_set_gui_maximise();       // reset any earlier scale and offset
    display_set_gui_size(-1, -1);
    display_set_gui_size(_l.gui_w, _l.gui_h);
    display_set_gui_maximise(_l.ui_scale, _l.ui_scale, _l.gui_x, _l.gui_y);
    _d.apply_count++;
    show_debug_message("[DISPLAY] relayout #" + string(_d.apply_count) + " window=" + string(_l.win_w) + "x" + string(_l.win_h) + " fullscreen=" + string(_l.fullscreen)
        + " scale=" + string(_l.scale) + " game=" + string(_l.game_x) + "," + string(_l.game_y) + "," + string(_l.game_w) + "x" + string(_l.game_h)
        + " ui_scale=" + string(_l.ui_scale) + " gui=" + string(_l.gui_w) + "x" + string(_l.gui_h));
}

function Display_ApplyCount() {
    return (variable_global_exists("display") && is_struct(global.display)) ? global.display.apply_count : 0;
}

function Display_Layout() {
    if (variable_global_exists("display") && is_struct(global.display) && is_struct(global.display.layout)) return global.display.layout;
    return Display_CalcLayout(window_get_width(), window_get_height());   // before Display_Init (tests that draw without a controller)
}

// UI code reads its own grid, never display_get_gui_*: display_set_gui_maximise makes the engine report window / scale instead.
function Display_GuiW() {
    return Display_Layout().gui_w;
}

function Display_GuiH() {
    return Display_Layout().gui_h;
}

// GUI units per world pixel (QTE targets, shake offsets, HUD that follows a sprite).
function Display_WorldScale() {
    var _l = Display_Layout();
    return _l.scale / _l.ui_scale;
}

// Every room start (obj_game_controller Create): the engine has just applied the ROOM's own view (port 480x432, borders 144/108 or 32/32).
// Put view 0 back to the one design: 160x144 camera 1:1 with the 160x144 surface, only view 0 visible. Camera follow stays with the room.
// No surface, GUI or window call here.
function Display_BindRoom() {
    view_enabled = true;
    for (var _i = 1; _i < 8; _i++) view_visible[_i] = false;
    view_visible[0] = true;
    var _cam = view_camera[0];
    if (!is_undefined(_cam) && _cam != -1) {
        camera_set_view_size(_cam, DISPLAY_BASE_W, DISPLAY_BASE_H);
        camera_set_view_border(_cam, floor(DISPLAY_BASE_W * 0.5) - 1, floor(DISPLAY_BASE_H * 0.5) - 1);
    }
    view_xport[0] = 0;
    view_yport[0] = 0;
    view_wport[0] = DISPLAY_BASE_W;
    view_hport[0] = DISPLAY_BASE_H;
}

// Draw-time zoom of the world (the encounter transition): _zoom >= 1 magnifies the part of the picture centred on _cx, _cy
// (view-local world pixels). Nothing resizes: the camera and surface stay 160x144. Display_ClearZoom() ends it.
function Display_SetZoom(_zoom, _cx, _cy) {
    Display_Init();
    var _d = global.display;
    _d.zoom = max(1, _zoom);
    _d.zoom_cx = _cx;
    _d.zoom_cy = _cy;
}

function Display_ClearZoom() {
    if (variable_global_exists("display") && is_struct(global.display)) global.display.zoom = 1;
}

// The first thing in the GUI stage of a frame: black everywhere, then the world at the integer scale, centred (GUI origin = the
// picture's corner, so the blit is at 0,0). Called from the top of every Draw GUI event; only the first call of a frame draws, so it
// does not matter which object draws first. Fades and dims draw Display_WindowRectInGui to cover the bars too.
function Display_DrawFrame() {
    if (!variable_global_exists("display") || !is_struct(global.display)) return;
    var _d = global.display;
    if (_d.drawn_frame == _d.frame) return;
    _d.drawn_frame = _d.frame;
    var _l = _d.layout;
    if (!is_struct(_l) || !surface_exists(application_surface)) return;
    draw_clear(c_black);
    var _k = _l.scale / _l.ui_scale;
    gpu_set_blendenable(false);
    if (_d.zoom > 1.0001) {
        var _sw = max(1, round(DISPLAY_BASE_W / _d.zoom));
        var _sh = max(1, round(DISPLAY_BASE_H / _d.zoom));
        var _sx = clamp(round(_d.zoom_cx - _sw * 0.5), 0, DISPLAY_BASE_W - _sw);
        var _sy = clamp(round(_d.zoom_cy - _sh * 0.5), 0, DISPLAY_BASE_H - _sh);
        draw_surface_part_ext(application_surface, _sx, _sy, _sw, _sh, 0, 0, _k * DISPLAY_BASE_W / _sw, _k * DISPLAY_BASE_H / _sh, c_white, 1);
    } else {
        draw_surface_ext(application_surface, 0, 0, _k, _k, 0, c_white, 1);
    }
    gpu_set_blendenable(true);
}
