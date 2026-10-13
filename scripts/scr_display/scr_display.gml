// scr_display: the display layer's pure maths (DISP-02/03/08/09). See .planning/research/display-design.md.
// Everything in this file is side-effect free: no window, view, camera, surface or GUI call. Step B adds the one
// owner that applies these results. Tested by Test_Suite_Display (scr_test.gml).

// The UI grid target from D8: a 4x grid, 640 wide on a 160-wide world.
#macro DISPLAY_UI_TARGET_W 640

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
