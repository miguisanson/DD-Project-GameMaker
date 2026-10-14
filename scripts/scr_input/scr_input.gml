function Input_PreStep() {
    Input_Update();
}

function Input_Init() {
    if (!variable_global_exists("input") || !is_struct(global.input)) {
        global.input = {};
    }

    var inp = global.input;

    if (!variable_struct_exists(inp, "bindings")) {
        inp.bindings = {};

        inp.bindings.move_up = [ord("W"), vk_up];
        inp.bindings.move_down = [ord("S"), vk_down];
        inp.bindings.move_left = [ord("A"), vk_left];
        inp.bindings.move_right = [ord("D"), vk_right];

        inp.bindings.interact = [vk_space];
        inp.bindings.confirm = [vk_space];
        inp.bindings.cancel = [vk_escape];
        inp.bindings.pause = [vk_escape];
        inp.bindings.menu = [ord("I"), vk_tab];

        inp.bindings.menu_up = [ord("W"), vk_up];
        inp.bindings.debug_toggle = [ord("P")];

        inp.bindings.menu_down = [ord("S"), vk_down];
        inp.bindings.menu_left = [ord("A"), vk_left];
        inp.bindings.menu_right = [ord("D"), vk_right];

        inp.bindings.run = [vk_shift];   // D70: hold to run
        inp.bindings.debug_save = [vk_f5];
        inp.bindings.debug_load = [vk_f9];
        inp.bindings.debug_levelup = [ord("L")];
        inp.bindings.debug_all_items = [ord("K")];
        inp.bindings.debug_kill = [ord("J")];
        inp.bindings.debug_enemy_damage_skill = [ord("U")];
        inp.bindings.debug_display_metrics = [ord("O")];
    }

    inp.bindings.debug_toggle = [ord("P")];
    // UI confirm is intentionally space-only.
    inp.bindings.confirm = [vk_space];
    if (!variable_struct_exists(inp.bindings, "pause")) inp.bindings.pause = [vk_escape];
    if (!variable_struct_exists(inp.bindings, "run")) inp.bindings.run = [vk_shift];
    if (!variable_struct_exists(inp.bindings, "debug_levelup")) inp.bindings.debug_levelup = [ord("L")];
    if (!variable_struct_exists(inp.bindings, "debug_all_items")) inp.bindings.debug_all_items = [ord("K")];
    if (!variable_struct_exists(inp.bindings, "debug_save")) inp.bindings.debug_save = [vk_f5];
    if (!variable_struct_exists(inp.bindings, "debug_load")) inp.bindings.debug_load = [vk_f9];
    if (!variable_struct_exists(inp.bindings, "debug_kill")) inp.bindings.debug_kill = [ord("J")];
    if (!variable_struct_exists(inp.bindings, "debug_enemy_damage_skill")) inp.bindings.debug_enemy_damage_skill = [ord("U")];
    if (!variable_struct_exists(inp.bindings, "debug_display_metrics")) inp.bindings.debug_display_metrics = [ord("O")];
    if (!variable_struct_exists(inp, "state")) {
        inp.state = {};
    }

    if (!variable_struct_exists(inp, "last_time")) {
        inp.last_time = -1;
    }
    if (!variable_struct_exists(inp, "last_step_time")) {
        inp.last_step_time = -1;
    }
    if (!variable_struct_exists(inp, "frame")) {
        inp.frame = 0;
    }
    if (!variable_struct_exists(inp, "buffer")) {
        inp.buffer = {};
    }
    if (!variable_struct_exists(inp, "cooldown")) {
        inp.cooldown = {};
    }
    if (!variable_struct_exists(inp, "repeat_state")) {
        inp.repeat_state = {};
    }
    if (!variable_struct_exists(inp, "move_order")) {
        inp.move_order = [];
    }
}

function Input_KeyCodeFromName(_name) {
    var n = string_upper(_name);
    if (string_length(n) == 1) return ord(n);
    switch (n) {
        case "SPACE":
        case "SPACEBAR": return vk_space;
        case "ENTER":
        case "RETURN": return vk_enter;
        case "ESC":
        case "ESCAPE": return vk_escape;
        case "TAB": return vk_tab;
        case "BACKSPACE": return vk_backspace;
        case "DELETE": return vk_delete;
        case "UP": return vk_up;
        case "DOWN": return vk_down;
        case "LEFT": return vk_left;
        case "RIGHT": return vk_right;
        case "F1": return vk_f1;
        case "F2": return vk_f2;
        case "F3": return vk_f3;
        case "F4": return vk_f4;
        case "F5": return vk_f5;
        case "F6": return vk_f6;
        case "F7": return vk_f7;
        case "F8": return vk_f8;
        case "F9": return vk_f9;
        case "F10": return vk_f10;
        case "F11": return vk_f11;
        case "F12": return vk_f12;
    }
    return -1;
}

function Input_KeyLabel(_key) {
    if (is_string(_key)) return _key;
    switch (_key) {
        case vk_space: return "Space";
        case vk_enter: return "Enter";
        case vk_escape: return "Esc";
        case vk_tab: return "Tab";
        case vk_backspace: return "Backspace";
        case vk_delete: return "Delete";
        case vk_up: return "Up";
        case vk_down: return "Down";
        case vk_left: return "Left";
        case vk_right: return "Right";
        case vk_f1: return "F1";
        case vk_f2: return "F2";
        case vk_f3: return "F3";
        case vk_f4: return "F4";
        case vk_f5: return "F5";
        case vk_f6: return "F6";
        case vk_f7: return "F7";
        case vk_f8: return "F8";
        case vk_f9: return "F9";
        case vk_f10: return "F10";
        case vk_f11: return "F11";
        case vk_f12: return "F12";
    }
    if (_key >= ord("A") && _key <= ord("Z")) return chr(_key);
    if (_key >= ord("0") && _key <= ord("9")) return chr(_key);
    if (_key == ord(" ")) return "Space";
    return "Key" + string(_key);
}

function Input_Label(_action) {
    Input_EnsureUpdated();
    if (!variable_struct_exists(global.input.bindings, _action)) return _action;
    var keys = variable_struct_get(global.input.bindings, _action);
    if (!is_array(keys) || array_length(keys) == 0) return _action;
    var labels = [];
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var code = key;
        if (is_string(code)) code = Input_KeyCodeFromName(code);
        var label = Input_KeyLabel(code);
        var dup = false;
        for (var j = 0; j < array_length(labels); j++) {
            if (labels[j] == label) { dup = true; break; }
        }
        if (!dup && label != "") array_push(labels, label);
    }
    var out = labels[0];
    for (var k = 1; k < array_length(labels); k++) out += " / " + labels[k];
    return out;
}

function Input_IsDebugAction(_action) {
    if (!is_string(_action)) return false;
    return (string_length(_action) >= 6 && string_copy(_action, 1, 6) == "debug_");
}

function Input_GamepadDevice() {
    for (var d = 0; d < 4; d++) {
        if (gamepad_is_connected(d)) return d;
    }
    return -1;
}

function Input_GamepadAxisHeld(_device, _axis, _dir, _deadzone) {
    var v = gamepad_axis_value(_device, _axis);
    if (_dir > 0) return v >= _deadzone;
    return v <= -_deadzone;
}

function Input_GamepadActionHeld(_device, _action, _deadzone) {
    switch (_action) {
        case "move_up":
        case "menu_up":
            return gamepad_button_check(_device, gp_padu) || Input_GamepadAxisHeld(_device, gp_axislv, -1, _deadzone);
        case "move_down":
        case "menu_down":
            return gamepad_button_check(_device, gp_padd) || Input_GamepadAxisHeld(_device, gp_axislv, 1, _deadzone);
        case "move_left":
        case "menu_left":
            return gamepad_button_check(_device, gp_padl) || Input_GamepadAxisHeld(_device, gp_axislh, -1, _deadzone);
        case "move_right":
        case "menu_right":
            return gamepad_button_check(_device, gp_padr) || Input_GamepadAxisHeld(_device, gp_axislh, 1, _deadzone);
        case "interact":
        case "confirm":
            return gamepad_button_check(_device, gp_face1);
        case "cancel":
            return gamepad_button_check(_device, gp_face2);
        case "run":
            return gamepad_button_check(_device, gp_shoulderl) || gamepad_button_check(_device, gp_shoulderr);
        case "menu":
            return gamepad_button_check(_device, gp_face3);
        case "pause":
            return gamepad_button_check(_device, gp_face4);
    }
    return false;
}

function Input_GamepadActionPressed(_device, _action, _prev_held, _deadzone) {
    switch (_action) {
        case "move_up":
        case "menu_up":
            return gamepad_button_check_pressed(_device, gp_padu) || (Input_GamepadAxisHeld(_device, gp_axislv, -1, _deadzone) && !_prev_held);
        case "move_down":
        case "menu_down":
            return gamepad_button_check_pressed(_device, gp_padd) || (Input_GamepadAxisHeld(_device, gp_axislv, 1, _deadzone) && !_prev_held);
        case "move_left":
        case "menu_left":
            return gamepad_button_check_pressed(_device, gp_padl) || (Input_GamepadAxisHeld(_device, gp_axislh, -1, _deadzone) && !_prev_held);
        case "move_right":
        case "menu_right":
            return gamepad_button_check_pressed(_device, gp_padr) || (Input_GamepadAxisHeld(_device, gp_axislh, 1, _deadzone) && !_prev_held);
        case "interact":
        case "confirm":
            return gamepad_button_check_pressed(_device, gp_face1);
        case "cancel":
            return gamepad_button_check_pressed(_device, gp_face2);
        case "menu":
            return gamepad_button_check_pressed(_device, gp_face3);
        case "pause":
            return gamepad_button_check_pressed(_device, gp_face4);
    }
    return false;
}


function Input_Update() {
    Input_Init();
    if (global.input.last_step_time == current_time) return;
    global.input.last_step_time = current_time;

    var inp = global.input;
    inp.last_time = current_time;
    inp.frame += 1;
    var gp_device = Input_GamepadDevice();
    var pad_deadzone = 0.35;
    if (variable_struct_exists(inp, "pad_deadzone")) {
        pad_deadzone = clamp(real(inp.pad_deadzone), 0.1, 0.95);
    } else {
        inp.pad_deadzone = pad_deadzone;
    }

    // ROB-03: binding names are cached (rebuilt only when the number of bindings changes) and each action keeps one
    // {held, pressed} struct that is rewritten in place, so a frame allocates nothing here.
    var bind_count = variable_struct_names_count(inp.bindings);
    if (!variable_struct_exists(inp, "names_cache") || inp.names_cache_count != bind_count) {
        inp.names_cache = variable_struct_get_names(inp.bindings);
        inp.names_cache_count = bind_count;
    }
    var names = inp.names_cache;
    for (var i = 0; i < array_length(names); i++) {
        var action = names[i];
        var bind = variable_struct_get(inp.bindings, action);
        var keys = bind;
        if (is_struct(bind) && variable_struct_exists(bind, "keys")) keys = bind.keys;
        var held = false;
        var pressed = false;

        if (is_array(keys)) {
            for (var k = 0; k < array_length(keys); k++) {
                var key = keys[k];
                var key_code = key;
                if (is_string(key_code)) key_code = Input_KeyCodeFromName(key_code);
                if (key_code != -1) {
                    if (keyboard_check(key_code)) held = true;
                    if (keyboard_check_pressed(key_code)) pressed = true;
                }
            }
        }

        var prev = false;
        var st = undefined;
        if (variable_struct_exists(inp.state, action)) {
            st = variable_struct_get(inp.state, action);
            if (is_struct(st) && variable_struct_exists(st, "held")) prev = st.held;
        }

        if (gp_device != -1 && !Input_IsDebugAction(action)) {
            var gp_held = Input_GamepadActionHeld(gp_device, action, pad_deadzone);
            var gp_pressed = Input_GamepadActionPressed(gp_device, action, prev, pad_deadzone);
            held = held || gp_held;
            pressed = pressed || gp_pressed;
        }

        if (is_struct(st) && variable_struct_exists(st, "held") && variable_struct_exists(st, "pressed")) {
            st.held = held;
            st.pressed = pressed;
        } else {
            variable_struct_set(inp.state, action, { held: held, pressed: pressed });
        }

        if (Input_IsMoveAction(action)) {
            var order = inp.move_order;
            if (pressed) {
                order = Input_ArrayRemove(order, action);
                array_push(order, action);
            } else if (!held && prev) {
                order = Input_ArrayRemove(order, action);
            }
            inp.move_order = order;
        }
    }
    Scenario_InputOverride();   // scr_debug: no-op unless run with -bot
}


function Input_ArrayRemove(_arr, _val) {
    for (var i = array_length(_arr) - 1; i >= 0; i--) {
        if (_arr[i] == _val) array_delete(_arr, i, 1);
    }
    return _arr;
}

function Input_IsMoveAction(_action) {
    return _action == "move_up" || _action == "move_down" || _action == "move_left" || _action == "move_right";
}

function Input_MoveAction() {
    Input_EnsureUpdated();
    var order = global.input.move_order;
    while (array_length(order) > 0) {
        var act = order[array_length(order) - 1];
        if (Input_Held(act)) return act;
        array_delete(order, array_length(order) - 1, 1);
    }
    global.input.move_order = order;
    return "";
}

function Input_EnsureUpdated() {
    Input_Update();
}

function Input_StateGet(_action, _field) {
    Input_EnsureUpdated();
    if (!variable_struct_exists(global.input.state, _action)) return false;
    var st = variable_struct_get(global.input.state, _action);
    if (!is_struct(st)) return false;
    if (!variable_struct_exists(st, _field)) return false;
    return variable_struct_get(st, _field);
}

function Input_Held(_action) {
    return Input_StateGet(_action, "held");
}

function Input_Pressed(_action) {
    return Input_StateGet(_action, "pressed");
}

function Input_Frame() {
    Input_EnsureUpdated();
    return global.input.frame;
}

function Input_ActionBuffer(_action) {
    // Input buffering disabled globally.
}

function Input_ActionBuffered(_action, _max_age) {
    // Input buffering disabled globally.
    return false;
}

function Input_ActionConsume(_action) {
    // Input buffering disabled globally.
}

// Buffering disabled: always returns no action.
function Input_BufferedLatest(_actions, _max_age) {
    // Input buffering disabled globally.
    return "";
}

function Input_ActionCooldownReady(_action) {
    // Input cooldown disabled globally.
    return true;
}

function Input_ActionSetCooldown(_action, _frames) {
    // Input cooldown disabled globally.
}

// Repeat behavior disabled: this is now discrete press only.
function Input_ActionRepeat(_action, _initial_delay, _repeat_delay) {
    // Hold-repeat disabled globally.
    return Input_Pressed(_action);
}

function Input_UIPressed(_action) {
    return Input_Pressed(_action);
}

function Input_UIRepeat(_action, _initial_delay = UI_NAV_REPEAT_DELAY, _repeat_delay = UI_NAV_REPEAT_RATE) {
    // UI repeat disabled: discrete presses only.
    return Input_Pressed(_action);
}

function Input_UIConfirm() {
    return Input_UIPressed("confirm");
}

function Input_UIBack() {
    return Input_UIPressed("cancel");
}

function Input_MoveX() {
    return (Input_Held("move_right") ? 1 : 0) - (Input_Held("move_left") ? 1 : 0);
}

function Input_MoveY() {
    return (Input_Held("move_down") ? 1 : 0) - (Input_Held("move_up") ? 1 : 0);
}

function Input_Bind(_action, _keys) {
    Input_Init();
    if (!is_array(_keys)) _keys = [_keys];
    variable_struct_set(global.input.bindings, _action, _keys);
}

// ---- hold-to-skip (D48, I-055) ----------------------------------------------------------------------------------------------------
// Holding confirm for SKIP_HOLD_FRAMES (1.0 s) skips a cutscene or a camera pan and it still counts as seen; a tap only advances text.
// The count starts only on a fresh press (a key already held when the scene starts never skips), and a small "hold to skip" fill
// shows for SKIP_HINT_FRAMES after the first press. Skip_Step is the pure core (tested by Test_Suite_Skip); Skip_Update steps the live one.
function Skip_StateNew() {
    return { armed: false, held_frames: 0, hint: 0, fired: false };
}

function Skip_Step(_st, _allowed, _pressed, _held) {
    var _r = { armed: _st.armed, held_frames: _st.held_frames, hint: _st.hint, fired: false };
    if (!_allowed) {
        _r.armed = false;
        _r.held_frames = 0;
        _r.hint = 0;
        return _r;
    }
    if (_pressed) {
        _r.armed = true;
        _r.held_frames = 0;
        _r.hint = SKIP_HINT_FRAMES;
    } else if (_r.hint > 0) {
        _r.hint--;
    }
    if (_r.armed && _held) {
        _r.held_frames++;
        if (_r.held_frames >= SKIP_HOLD_FRAMES) {
            _r.fired = true;
            _r.armed = false;
            _r.held_frames = 0;
            _r.hint = 0;
        }
    } else {
        _r.armed = false;
        _r.held_frames = 0;
    }
    return _r;
}

function Skip_Fraction(_held_frames) {
    return clamp(_held_frames / SKIP_HOLD_FRAMES, 0, 1);
}

// A skippable scene (a cutscene, a camera pan) calls Skip_Claim every frame it runs and asks Skip_Consume whether the hold completed;
// obj_ui_controller calls Skip_Tick once per frame (after Display_Update), which steps the hold only while a scene claimed it
// this frame or the one before. Nothing claimed = the count and the hint reset.
function Skip_Ensure() {
    if (!variable_global_exists("skip")) global.skip = { st: Skip_StateNew(), claim: -100, latched: false };
}

function Skip_Frame() {
    return (variable_global_exists("display") && is_struct(global.display)) ? global.display.frame : 0;
}

function Skip_Claim() {
    Skip_Ensure();
    global.skip.claim = Skip_Frame();
}

function Skip_Tick() {
    Skip_Ensure();
    var _g = global.skip;
    _g.st = Skip_Step(_g.st, (Skip_Frame() - _g.claim) <= 1, Input_Pressed("confirm"), Input_Held("confirm"));
    if (_g.st.fired) _g.latched = true;
}

// True once per completed hold.
function Skip_Consume() {
    Skip_Ensure();
    var _g = global.skip;
    if (!_g.latched) return false;
    _g.latched = false;
    return true;
}

function Skip_Reset() {
    Skip_Ensure();
    global.skip.st = Skip_StateNew();
    global.skip.latched = false;
    global.skip.claim = -100;
}

// The "hold to skip" hint: top right, a line of text over a fill that grows while confirm is held. Drawn last by obj_ui_controller.
function Skip_DrawHint() {
    if (!variable_global_exists("skip")) return;
    var _g = global.skip;
    if (_g.st.hint <= 0) return;
    var _c = draw_get_color(), _a = draw_get_alpha(), _h = draw_get_halign(), _v = draw_get_valign();
    UI_SetFont();
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    var _txt = Loc_T("ui.skip_hold", "Hold to skip");
    var _tw = UI_TextWidth(_txt);
    var _th = UI_TextHeight(_txt);
    var _pad = max(3, round(_th * 0.25));
    var _bar_h = max(2, round(_th * 0.2));
    var _w = _tw + _pad * 2;
    var _hh = _th + _bar_h + _pad * 3;
    var _x = Display_GuiW() - _w - max(4, _pad);
    var _y = max(4, _pad);
    var _fade = clamp(_g.st.hint / 20, 0, 1);
    draw_set_alpha(0.65 * _fade);
    draw_set_color(c_black);
    draw_rectangle(_x, _y, _x + _w, _y + _hh, false);
    draw_set_alpha(_fade);
    draw_set_color(c_white);
    UI_DrawText(_x + _pad, _y + _pad, _txt);
    var _by = _y + _pad * 2 + _th;
    draw_set_alpha(0.35 * _fade);
    draw_rectangle(_x + _pad, _by, _x + _pad + _tw, _by + _bar_h, false);
    draw_set_alpha(_fade);
    draw_rectangle(_x + _pad, _by, _x + _pad + round(_tw * Skip_Fraction(_g.st.held_frames)), _by + _bar_h, false);
    draw_set_color(_c);
    draw_set_alpha(_a);
    draw_set_halign(_h);
    draw_set_valign(_v);
}
