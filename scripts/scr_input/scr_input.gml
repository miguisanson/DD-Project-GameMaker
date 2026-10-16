function Input_PreStep() {
    Input_Update();
}

// D108 F1a: runs its body once (init_done, set at the end); about 14 input calls per Ui_ReadInput made it re-allocate the tables every frame.
// The D95 repair below needs no re-run: binds_applied only ever goes false -> true, and the repair is skipped from then on.
// A test can set init_done = false to force a re-run.
function Input_Init() {
    if (variable_global_exists("input") && is_struct(global.input) && variable_struct_exists(global.input, "init_done") && global.input.init_done) return;
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
        inp.bindings.confirm = [vk_space, ord("Z"), vk_enter];
        inp.bindings.cancel = [vk_escape, ord("X")];
        inp.bindings.tab_prev = [ord("Q")];
        inp.bindings.tab_next = [ord("E")];
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
    // D95: the same keys in every menu. Confirm = Space, Z, Enter (+ pad A); back = Esc, X (+ pad B); tabs = Q / E (+ pad shoulders).
    // Rewritten on every init so an older table in memory gets them too. Interact stays on Space. Once the settings have applied the
    // player's own keys (Binds_Apply, D49) the table is theirs and is left alone.
    if (!variable_struct_exists(inp, "binds_applied") || !inp.binds_applied) {
        inp.bindings.confirm = [vk_space, ord("Z"), vk_enter];
        inp.bindings.cancel = [vk_escape, ord("X")];
        inp.bindings.tab_prev = [ord("Q")];
        inp.bindings.tab_next = [ord("E")];
    }
    if (!variable_struct_exists(inp, "last_device")) inp.last_device = "keyboard";   // D92: what the prompts show
    if (!variable_struct_exists(inp.bindings, "pause")) inp.bindings.pause = [vk_escape];
    if (!variable_struct_exists(inp.bindings, "run")) inp.bindings.run = [vk_shift];
    if (!variable_struct_exists(inp.bindings, "debug_levelup")) inp.bindings.debug_levelup = [ord("L")];
    if (!variable_struct_exists(inp.bindings, "debug_all_items")) inp.bindings.debug_all_items = [ord("K")];
    if (!variable_struct_exists(inp.bindings, "debug_save")) inp.bindings.debug_save = [vk_f5];
    if (!variable_struct_exists(inp.bindings, "debug_load")) inp.bindings.debug_load = [vk_f9];
    if (!variable_struct_exists(inp.bindings, "debug_kill")) inp.bindings.debug_kill = [ord("J")];
    if (!variable_struct_exists(inp.bindings, "debug_enemy_damage_skill")) inp.bindings.debug_enemy_damage_skill = [ord("U")];
    if (!variable_struct_exists(inp.bindings, "debug_display_metrics")) inp.bindings.debug_display_metrics = [ord("O")];
    for (var sd = 0; sd < 10; sd++) {   // D152: the seed entry types digits (top row and number pad) and deletes with Backspace; fixed keys, not on the Controls page
        var seed_action = "seed_d" + string(sd);
        if (!variable_struct_exists(inp.bindings, seed_action)) variable_struct_set(inp.bindings, seed_action, [ord("0") + sd, vk_numpad0 + sd]);
    }
    if (!variable_struct_exists(inp.bindings, "seed_back")) inp.bindings.seed_back = [vk_backspace];
    for (var nl = 0; nl < 26; nl++) {   // D175: the profile name entry types letters (fixed keys, not on the Controls page); A-Z are also menu keys, so the entry reads these actions, not the menu ones
        var name_action = "name_" + chr(97 + nl);
        if (!variable_struct_exists(inp.bindings, name_action)) variable_struct_set(inp.bindings, name_action, [ord("A") + nl]);
    }
    if (!variable_struct_exists(inp.bindings, "name_space")) inp.bindings.name_space = [vk_space];
    if (!variable_struct_exists(inp.bindings, "name_ok")) inp.bindings.name_ok = [vk_enter];
    if (!variable_struct_exists(inp, "state")) {
        inp.state = {};
    }

    if (!variable_struct_exists(inp, "last_time")) {
        inp.last_time = -1;
    }
    if (!variable_struct_exists(inp, "last_step_time")) {
        inp.last_step_time = -1;
    }
    if (!variable_struct_exists(inp, "new_frame")) {
        inp.new_frame = true;
    }
    if (!variable_struct_exists(inp, "frame")) {
        inp.frame = 0;
    }
    if (!variable_struct_exists(inp, "move_order")) {
        inp.move_order = [];
    }
    inp.init_done = true;
    global.input_init_runs = (variable_global_exists("input_init_runs") ? global.input_init_runs : 0) + 1;   // read by Test_Suite_Input
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
        case vk_shift: return "Shift";
        case vk_control: return "Ctrl";
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

// Pad buttons per button action (the sticks and the d-pad are handled below). The shoulder buttons are the tabs (D95); run moved to the
// triggers so holding it does not flip tabs.
function Input_GamepadButtons(_action) {
    switch (_action) {
        case "interact":
        case "confirm": return [gp_face1];
        case "cancel": return [gp_face2];
        case "menu": return [gp_face3, gp_start];   // D140: Start opens the one menu too
        case "pause": return [gp_face4];
        case "tab_prev": return [gp_shoulderl];
        case "tab_next": return [gp_shoulderr];
        case "run": return [gp_shoulderlb, gp_shoulderrb];
    }
    return [];
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
    }
    var btns = Input_GamepadButtons(_action);
    for (var i = 0; i < array_length(btns); i++) {
        if (gamepad_button_check(_device, btns[i])) return true;
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
    }
    var btns = Input_GamepadButtons(_action);
    for (var i = 0; i < array_length(btns); i++) {
        if (gamepad_button_check_pressed(_device, btns[i])) return true;
    }
    return false;
}


// Called by the draw of every frame (Display_DrawFrame), after all the Step events: the next frame's first Input_Update recomputes.
function Input_FrameEnd() {
    Input_Init();
    global.input.new_frame = true;
}

function Input_Update() {
    Input_Init();
    if (variable_struct_exists(global.input, "frozen") && global.input.frozen) return;   // tests inject state (no clock race)
    // Once per FRAME: the first call after a frame's draw (Input_FrameEnd) recomputes, whatever current_time says (two frames can share one value, and one
    // frame can span two); the other calls of the same frame (every controller's Step) find the state ready. last_step_time = -1 forces a recompute (tests, taps).
    if (!global.input.new_frame && global.input.last_step_time != -1) return;
    global.input.new_frame = false;
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
    inp.last_device = Prompt_DeviceStep(inp.last_device, Prompt_KeyboardActivity(), Prompt_PadActivity(gp_device, pad_deadzone));   // D92
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

function Input_UIPressed(_action) {
    return Input_Pressed(_action);
}

function Input_UIConfirm() {
    return Input_UIPressed("confirm");
}

function Input_UIBack() {
    return Input_UIPressed("cancel");
}

// ---- hold-to-skip (D48, I-055, D146) ----------------------------------------------------------------------------------------------
// A tap of confirm only advances text. Holding it: after SKIP_HINT_MS (1.0 s) the "Hold to skip" prompt fades in, and at SKIP_HOLD_MS (2.0 s) the cutscene or camera pan
// is skipped (it still counts as seen). The count starts only on a fresh press (a key already held when the scene starts never skips). The count is ms
// (Presentation_StepMs per step, D108 F2b-2), so it takes the same time at any frame rate. Skip_Step is the pure core (tested by Test_Suite_CutSkip);
// st.hint is the prompt's fade in ms (0..SKIP_HINT_FADE_MS), Skip_HintAlpha turns it into 0..1.
function Skip_StateNew() {
    return { armed: false, held_ms: 0, hint: 0, fired: false };
}

function Skip_Step(_st, _allowed, _pressed, _held, _step_ms) {
    var _r = { armed: _st.armed, held_ms: _st.held_ms, hint: _st.hint, fired: false };
    if (!_allowed) {
        _r.armed = false;
        _r.held_ms = 0;
        _r.hint = 0;
        return _r;
    }
    if (_pressed) {
        _r.armed = true;
        _r.held_ms = 0;
    }
    if (_r.armed && _held) {
        _r.held_ms += _step_ms;
        if (_r.held_ms >= SKIP_HOLD_MS - SKIP_EDGE_SLACK_MS) {
            _r.fired = true;
            _r.armed = false;
            _r.held_ms = 0;
            _r.hint = 0;
            return _r;
        }
    } else {
        _r.armed = false;
        _r.held_ms = 0;
    }
    if (_r.held_ms >= SKIP_HINT_MS - SKIP_EDGE_SLACK_MS) _r.hint = min(SKIP_HINT_FADE_MS, _r.hint + _step_ms);
    else _r.hint = max(0, _r.hint - _step_ms);
    if (_r.hint <= SKIP_EDGE_SLACK_MS) _r.hint = 0;
    return _r;
}

// D146: how visible the "Hold to skip" prompt is, 0..1: it fades in over SKIP_HINT_FADE_MS once the hold passes SKIP_HINT_MS and out when the key is let go.
function Skip_HintAlpha(_st) {
    return clamp(_st.hint / SKIP_HINT_FADE_MS, 0, 1);
}

// The prompt's bar: empty at SKIP_HINT_MS of holding, full at SKIP_HOLD_MS.
function Skip_Fraction(_held_ms) {
    return clamp((_held_ms - SKIP_HINT_MS) / (SKIP_HOLD_MS - SKIP_HINT_MS), 0, 1);
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

function Skip_Tick(_step_ms) {
    Skip_Ensure();
    var _g = global.skip;
    _g.st = Skip_Step(_g.st, (Skip_Frame() - _g.claim) <= 1, Input_Pressed("confirm"), Input_Held("confirm"), _step_ms);
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

// D146: where the "Hold to skip" prompt sits: a shared-style frame in the top right corner, the text on top and the bar under it. { x, y, w, h, bar_x, bar_y, bar_w, bar_h, text_x, text_y }.
function Skip_HintRect() {
    var _mt = Ui_Metrics();   // also sets the UI font
    var _p = _mt.p;
    var _txt = Loc_T("ui.skip_hold", "Hold to Skip");
    var _tw = UI_TextWidth(_txt);
    var _w = _tw + 10 * _p;   // 2p frame + 2p air + 1p for the last glyph to breathe, each side
    var _h = _mt.line_h + 12 * _p;
    var _x = _mt.gw - _w - _mt.margin;
    var _y = _mt.margin;
    return { x: _x, y: _y, w: _w, h: _h, text_x: _x + 5 * _p, text_y: _y + 4 * _p, bar_x: _x + 5 * _p, bar_y: _y + 4 * _p + _mt.line_h + 2 * _p, bar_w: _tw, bar_h: 2 * _p, txt: _txt };
}

// The "Hold to skip" prompt, drawn last by obj_ui_controller: the shared frame and text style, the bar filling from 1 s to 2 s of holding (D146). Nothing while its alpha is 0.
function Skip_DrawHint() {
    if (!variable_global_exists("skip")) return;
    var _g = global.skip;
    var _fade = Skip_HintAlpha(_g.st);
    if (_fade <= 0) return;
    var _c = draw_get_color(), _a = draw_get_alpha(), _h = draw_get_halign(), _v = draw_get_valign();
    var _r = Skip_HintRect();
    var _p = Ui_Metrics().p;
    draw_set_alpha(_fade);
    Ui_DrawFrame(_r.x, _r.y, _r.w, _r.h, _fade, _p);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    Ui_Text(_r.text_x, _r.text_y, _r.txt, UI_C_TEXT);
    Ui_Box(_r.bar_x, _r.bar_y, _r.bar_x + _r.bar_w, _r.bar_y + _r.bar_h, UI_C_DARK);
    Ui_Box(_r.bar_x, _r.bar_y, _r.bar_x + round(_r.bar_w * Skip_Fraction(_g.st.held_ms)), _r.bar_y + _r.bar_h, UI_C_LIGHT);
    draw_set_color(_c);
    draw_set_alpha(_a);
    draw_set_halign(_h);
    draw_set_valign(_v);
}

// ============================================================================================================================
// C4 (D49): key rebinding model. The pure part (rows, defaults, assigning with swaps, normalising, the action table) has no input or
// draw calls and is tested by Test_Suite_Binds. A row is one thing the player rebinds; it feeds one or more input actions.
//   keys = { confirm: [..], back: [..], up: [..], down: [..], left: [..], right: [..], run: [..], tab_prev: [..], tab_next: [..], interact: [..] }
// The first key of a row is its main key (the one prompts show). The settings keep the table (settings_version 10); the gamepad is not
// rebindable and stays as Input_GamepadButtons says. ctx says where an action is used: "menu", "world", or "both" (directions);
// two rows conflict only when their places overlap, so Interact (world) and Confirm (menu) may share Space.
// ============================================================================================================================
#macro BINDS_MAX_KEYS 3

function Binds_RowDefs() {
    if (!variable_global_exists("binds_rows") || !is_array(global.binds_rows)) {
        global.binds_rows = [
            { id: "confirm",  actions: ["confirm"],             ctx: "menu",  label: "Confirm" },
            { id: "back",     actions: ["cancel"],              ctx: "menu",  label: "Back" },
            { id: "up",       actions: ["move_up", "menu_up"],       ctx: "both", label: "Up" },
            { id: "down",     actions: ["move_down", "menu_down"],   ctx: "both", label: "Down" },
            { id: "left",     actions: ["move_left", "menu_left"],   ctx: "both", label: "Left" },
            { id: "right",    actions: ["move_right", "menu_right"], ctx: "both", label: "Right" },
            { id: "run",      actions: ["run"],                 ctx: "world", label: "Run" },
            { id: "tab_prev", actions: ["tab_prev"],            ctx: "menu",  label: "Previous Tab" },
            { id: "tab_next", actions: ["tab_next"],            ctx: "menu",  label: "Next Tab" },
            { id: "interact", actions: ["interact"],            ctx: "world", label: "Interact" }
        ];
    }
    return global.binds_rows;
}

function Binds_RowIds() {
    var rows = Binds_RowDefs();
    var out = [];
    for (var i = 0; i < array_length(rows); i++) array_push(out, rows[i].id);
    return out;
}

function Binds_Row(_id) {
    var rows = Binds_RowDefs();
    for (var i = 0; i < array_length(rows); i++) if (rows[i].id == _id) return rows[i];
    return undefined;
}

function Binds_RowLabel(_id) {
    var r = Binds_Row(_id);
    if (!is_struct(r)) return string(_id);
    return Loc_T("controls.row." + _id, r.label);
}

function Binds_Defaults() {
    return {
        confirm: [vk_space, ord("Z"), vk_enter],
        back: [vk_escape, ord("X")],
        up: [ord("W"), vk_up],
        down: [ord("S"), vk_down],
        left: [ord("A"), vk_left],
        right: [ord("D"), vk_right],
        run: [vk_shift],
        tab_prev: [ord("Q")],
        tab_next: [ord("E")],
        interact: [vk_space]
    };
}

function Binds_Copy(_keys) {
    var out = {};
    var ids = Binds_RowIds();
    for (var i = 0; i < array_length(ids); i++) {
        var src = (is_struct(_keys) && variable_struct_exists(_keys, ids[i])) ? variable_struct_get(_keys, ids[i]) : [];
        var dst = [];
        if (is_array(src)) for (var k = 0; k < array_length(src); k++) array_push(dst, src[k]);
        variable_struct_set(out, ids[i], dst);
    }
    return out;
}

function Binds_KeyValid(_k) {
    return is_real(_k) && _k == floor(_k) && _k >= 8 && _k <= 255;
}

// Keys the player cannot give to an action: the ones other parts of the game own (Esc = pause and cancel-the-capture, Tab / I = the
// menu, P = the debug overlay, F1-F12 = the debug keys).
function Binds_Reserved(_k) {
    return _k == vk_escape || _k == vk_tab || _k == ord("I") || _k == ord("P") || (_k >= vk_f1 && _k <= vk_f12);
}

function Binds_Allowed(_k) {
    if (_k >= ord("A") && _k <= ord("Z")) return true;
    if (_k >= ord("0") && _k <= ord("9")) return true;
    return _k == vk_space || _k == vk_enter || _k == vk_up || _k == vk_down || _k == vk_left || _k == vk_right
        || _k == vk_shift || _k == vk_control || _k == vk_backspace || _k == vk_delete;
}

function Binds_CanCapture(_k) {
    return Binds_KeyValid(_k) && Binds_Allowed(_k) && !Binds_Reserved(_k);
}

function Binds_NormalizeRow(_raw, _default) {
    if (!is_array(_raw)) return _default;
    var out = [];
    for (var i = 0; i < array_length(_raw); i++) {
        if (array_length(out) >= BINDS_MAX_KEYS) break;
        var k = _raw[i];
        if (!Binds_KeyValid(k)) continue;
        if (array_contains(out, k)) continue;
        array_push(out, k);
    }
    if (array_length(out) == 0) return _default;
    return out;
}

// Anything (a file, an old struct, nothing) -> a complete, valid table. A row that is missing, the wrong type or empty gets its default.
function Binds_Normalize(_raw) {
    var out = Binds_Defaults();
    if (!is_struct(_raw)) return out;
    var ids = Binds_RowIds();
    for (var i = 0; i < array_length(ids); i++) {
        if (variable_struct_exists(_raw, ids[i])) {
            variable_struct_set(out, ids[i], Binds_NormalizeRow(variable_struct_get(_raw, ids[i]), variable_struct_get(out, ids[i])));
        }
    }
    return out;
}

function Binds_CtxOverlap(_a, _b) {
    return _a == "both" || _b == "both" || _a == _b;
}

// Every other row that is used in the same place and already holds _key.
function Binds_Conflicts(_keys, _row, _key) {
    var out = [];
    var me = Binds_Row(_row);
    var rows = Binds_RowDefs();
    for (var i = 0; i < array_length(rows); i++) {
        if (rows[i].id == _row) continue;
        if (is_struct(me) && !Binds_CtxOverlap(me.ctx, rows[i].ctx)) continue;
        if (variable_struct_exists(_keys, rows[i].id) && array_contains(variable_struct_get(_keys, rows[i].id), _key)) array_push(out, rows[i].id);
    }
    return out;
}

// The first of them, or "".
function Binds_Conflict(_keys, _row, _key) {
    var c = Binds_Conflicts(_keys, _row, _key);
    return (array_length(c) > 0) ? c[0] : "";
}

function Binds_IndexOf(_arr, _v) {
    for (var i = 0; i < array_length(_arr); i++) if (_arr[i] == _v) return i;
    return -1;
}

// Gives _key to a row as its main key. A key the row already has swaps places with its main key. A new key replaces the main key; if
// another row used in the same place already has it, that row takes the old main key in its place (a swap, nothing is left unbound).
// Returns { ok, reason ("", "unknown", "unusable", "reserved"), keys (a changed copy), swapped (the id of the first row that was swapped, or "") }.
function Binds_Assign(_keys, _row, _key) {
    var out = { ok: false, reason: "", keys: Binds_Copy(_keys), swapped: "" };
    if (!is_struct(Binds_Row(_row))) { out.reason = "unknown"; return out; }
    if (!Binds_KeyValid(_key) || !Binds_Allowed(_key)) { out.reason = "unusable"; return out; }
    if (Binds_Reserved(_key)) { out.reason = "reserved"; return out; }
    var cur = variable_struct_get(out.keys, _row);
    if (array_length(cur) == 0) cur = variable_struct_get(Binds_Defaults(), _row);
    var a0 = cur[0];
    var idx = Binds_IndexOf(cur, _key);
    if (idx == 0) { out.ok = true; variable_struct_set(out.keys, _row, cur); return out; }
    if (idx > 0) {
        cur[idx] = a0;
        cur[0] = _key;
        variable_struct_set(out.keys, _row, cur);
        out.ok = true;
        return out;
    }
    var others = Binds_Conflicts(out.keys, _row, _key);
    for (var o = 0; o < array_length(others); o++) {
        var oc = variable_struct_get(out.keys, others[o]);
        var oi = Binds_IndexOf(oc, _key);
        if (array_contains(oc, a0)) array_delete(oc, oi, 1); else oc[oi] = a0;
        if (out.swapped == "") out.swapped = others[o];
    }
    cur[0] = _key;
    variable_struct_set(out.keys, _row, cur);
    out.ok = true;
    return out;
}

// The input system's table: action name -> keys.
function Binds_ToActions(_keys) {
    var out = {};
    var rows = Binds_RowDefs();
    var keys = Binds_Normalize(_keys);
    for (var i = 0; i < array_length(rows); i++) {
        var src = variable_struct_get(keys, rows[i].id);
        for (var a = 0; a < array_length(rows[i].actions); a++) {
            var dst = [];
            for (var k = 0; k < array_length(src); k++) array_push(dst, src[k]);
            if (rows[i].id == "back" && !array_contains(dst, vk_escape)) array_push(dst, vk_escape);   // Hunt 6 UI (D140): Esc is reserved, so it is always Back whatever Back is rebound to
            variable_struct_set(out, rows[i].actions[a], dst);
        }
    }
    return out;
}

// Puts a key table into the live input system (boot, Apply, load). From here Input_Init leaves the table alone.
function Binds_Apply(_keys) {
    Input_Init();
    var acts = Binds_ToActions(_keys);
    var names = variable_struct_get_names(acts);
    for (var i = 0; i < array_length(names); i++) variable_struct_set(global.input.bindings, names[i], variable_struct_get(acts, names[i]));
    global.input.binds_applied = true;
    global.prompt_rev = (variable_global_exists("prompt_rev") ? global.prompt_rev : 0) + 1;   // D149: the glyph widths of laid-out text may have changed
}

function Binds_KeysText(_arr) {
    if (!is_array(_arr) || array_length(_arr) == 0) return "";
    var out = "";
    for (var i = 0; i < array_length(_arr); i++) out += ((i > 0) ? " / " : "") + Input_KeyLabel(_arr[i]);
    return out;
}

// ============================================================================================================================
// C4 (D92): button prompts. The device the player touched last decides the glyph; the labels come from the live key table, so a
// rebound key shows as the new key. Prompt_Info / Prompt_Text are pure reads; the drawing (code-drawn keycap and round buttons in the
// four palette colours) is below, next to the text layout that lets a sentence hold prompts: "Press {confirm} to go on".
// ============================================================================================================================

// Which device was used last, from this frame's activity (pure). Both in the same frame keeps what it was.
function Prompt_DeviceStep(_cur, _kb, _pad) {
    if (_kb && !_pad) return "keyboard";
    if (_pad && !_kb) return "gamepad";
    return _cur;
}

function Prompt_KeyboardActivity() {
    return keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_any);
}

function Prompt_PadActivity(_device, _deadzone) {
    if (_device < 0) return false;
    var btns = [gp_face1, gp_face2, gp_face3, gp_face4, gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb, gp_start, gp_select, gp_padu, gp_padd, gp_padl, gp_padr];
    for (var i = 0; i < array_length(btns); i++) if (gamepad_button_check_pressed(_device, btns[i])) return true;
    var axes = [gp_axislh, gp_axislv, gp_axisrh, gp_axisrv];
    for (var a = 0; a < array_length(axes); a++) if (abs(gamepad_axis_value(_device, axes[a])) >= max(0.6, _deadzone)) return true;
    return false;
}

function Prompt_Device() {
    Input_Init();
    return global.input.last_device;
}

// Row names (the rebinding page) and action names (the input system) both work.
function Prompt_ActionOfRow(_name) {
    switch (_name) {
        case "back": return "cancel";
        case "up": return "move_up";
        case "down": return "move_down";
        case "left": return "move_left";
        case "right": return "move_right";
        case "start": return "menu";
    }
    return _name;
}

function Prompt_PadLabel(_action) {
    switch (_action) {
        case "confirm":
        case "interact": return "A";
        case "cancel":
        case "back": return "B";
        case "menu": return "X";
        case "pause": return "Y";
        case "start": return "Start";
        case "tab_prev": return "LB";
        case "tab_next": return "RB";
        case "run": return "LT";
        case "up": case "down": case "left": case "right":
        case "move_up": case "move_down": case "move_left": case "move_right":
        case "menu_up": case "menu_down": case "menu_left": case "menu_right": return "D-Pad";
    }
    return string(_action);
}

// "up", "down", "left" or "right" for a move prompt (a row name, a move_ or a menu_ action), "" for every other action.
function Prompt_DirOf(_action) {
    switch (_action) {
        case "up": case "move_up": case "menu_up": return "up";
        case "down": case "move_down": case "menu_down": return "down";
        case "left": case "move_left": case "menu_left": return "left";
        case "right": case "move_right": case "menu_right": return "right";
    }
    return "";
}

function Prompt_ArrowKey(_dir) {
    switch (_dir) {
        case "up": return vk_up;
        case "down": return vk_down;
        case "left": return vk_left;
        case "right": return vk_right;
    }
    return -1;
}

// { kind: "key" | "pad", label, action, dir, dirs }: what to draw for an action on a device (the live one when _device is undefined).
// dir is "up" / "down" / "left" / "right" when the prompt is drawn as an arrow (D156): a pad's d-pad always, a keyboard's move prompt while an
// arrow key is bound to it (a rebound letter shows as that letter); dirs lists the d-pad arms to light (a run of arrows is one glyph).
function Prompt_Info(_action, _device = undefined) {
    var dev = is_undefined(_device) ? Prompt_Device() : _device;
    var dir = Prompt_DirOf(_action);
    if (dev == "gamepad") return { kind: "pad", label: Prompt_PadLabel(_action), action: _action, dir: dir, dirs: (dir == "") ? [] : [dir] };
    Input_Init();
    var act = Prompt_ActionOfRow(_action);
    var label = string(_action);
    var arrow = false;
    if (variable_struct_exists(global.input.bindings, act)) {
        var keys = variable_struct_get(global.input.bindings, act);
        if (is_struct(keys) && variable_struct_exists(keys, "keys")) keys = keys.keys;
        if (is_array(keys) && array_length(keys) > 0) {
            var code = keys[0];
            if (is_string(code)) code = Input_KeyCodeFromName(code);
            label = Input_KeyLabel(code);
            if (dir != "") {
                for (var k = 0; k < array_length(keys); k++) {
                    var kc = is_string(keys[k]) ? Input_KeyCodeFromName(keys[k]) : keys[k];
                    if (kc == Prompt_ArrowKey(dir)) arrow = true;
                }
            }
        }
    }
    return { kind: "key", label: label, action: _action, dir: arrow ? dir : "", dirs: arrow ? [dir] : [] };
}

function Prompt_Text(_action, _device = undefined) {
    return Prompt_Info(_action, _device).label;
}

// ============================================================================================================================
// H8b (D149, D156): the text markup. One parser (Markup_Parse), one layout (Prompt_RichLayout) and one drawer (Prompt_RichDraw / Markup_DrawLine)
// serve every place that shows sentences: the dialogue box, cards, tooltips, notes, tutorials, hints. The rules for writers are in docs/text-markup.md.
//   [t]Poison[/t]   a game term, in the palette's bright green (UI_C_TERM)
//   [a]BREAK[/a]    the one accent, merchant gold #E8C547 (UI_C_ACCENT): only BREAK and Perfect
//   [r1]..[/r1] [r2]..[/r2] [r3]..[/r3]   an item's name in its rarity colour (D178): Common white, Rare gold, Epic gold that pulses lighter. Written only by Item_NameMarked,
//                   never in the workbook
//   [k:confirm]     the button for an action, by the device used last: a key name (arrows for the move keys) or a pad glyph
//   {confirm}       the older spelling of [k:confirm], still read
// Tags do not nest. A tag that is not closed, nested, unknown or stray is dropped and its text stays; no bracket ever reaches the screen.
// Width and wrapping count the words and the real width of a glyph; the markup itself has no width.
// ============================================================================================================================

// The action names a prompt may name (in [k:..] or {..}).
function Prompt_IsAction(_name) {
    switch (_name) {
        case "confirm": case "back": case "cancel": case "up": case "down": case "left": case "right":
        case "interact": case "run": case "tab_prev": case "tab_next": case "menu": case "pause": case "start": return true;
    }
    return false;
}

// True for the three item tags (D178): the rarity of the item the name belongs to.
function Markup_IsItemTag(_name) {
    return _name == "r1" || _name == "r2" || _name == "r3";
}

// What the text between "[" and "]" is: "t" / "a" / "r1" / "r2" / "r3" (opening tags), "/t" / "/a" / "/r1".. (closing), "k:<action>" (a button), "?" (shaped like a
// tag but not one we know: dropped), "" (not a tag at all: plain text, e.g. "[ b ]").
function Markup_TagKind(_inner) {
    var n = string_length(_inner);
    if (n == 0) return "";
    var i = (string_char_at(_inner, 1) == "/") ? 2 : 1;
    var j = i;
    var digits_ok = (string_char_at(_inner, i) == "r");   // only the item tags have a digit in their name
    while (j <= n) {
        var c = ord(string_char_at(_inner, j));
        if ((c >= 97 && c <= 122) || (digits_ok && j > i && c >= 48 && c <= 57)) j++; else break;
    }
    if (j == i) return "";
    var nm = string_copy(_inner, i, j - i);
    var arg = "";
    if (j <= n) {
        if (i == 2 || string_char_at(_inner, j) != ":") return "";
        arg = string_copy(_inner, j + 1, n - j);
        if (arg == "") return "";
        for (var q = 1; q <= string_length(arg); q++) {
            var ac = ord(string_char_at(arg, q));
            if (!((ac >= 97 && ac <= 122) || ac == 95)) return "";
        }
    }
    if (i == 2) return (nm == "t" || nm == "a" || Markup_IsItemTag(nm)) ? "/" + nm : "?";
    if (arg != "") return (nm == "k" && Prompt_IsAction(arg)) ? "k:" + arg : "?";
    return (nm == "t" || nm == "a" || Markup_IsItemTag(nm)) ? nm : "?";
}

// The style a span of text gets from its opening tag: "term", "accent", or "r1" / "r2" / "r3" for an item's name.
function Markup_StyleOf(_kind) {
    if (_kind == "t") return "term";
    if (_kind == "a") return "accent";
    return _kind;
}

// True when the text holds anything shaped like a tag.
function Markup_HasTag(_s) {
    var rest = string(_s);
    while (true) {
        var o = string_pos("[", rest);
        if (o == 0) return false;
        rest = string_delete(rest, 1, o);
        var c = string_pos("]", rest);
        if (c > 1 && Markup_TagKind(string_copy(rest, 1, c - 1)) != "") return true;
    }
    return false;
}

// "Press [k:confirm] to go, [t]Poison[/t] hurts" -> [{ kind: "text", s: "Press ", st: "" }, { kind: "action", s: "confirm" }, { kind: "text", s: " to go, ", st: "" },
// { kind: "text", s: "Poison", st: "term" }, ...]. st is "", "term", "accent" or "r1" / "r2" / "r3" (an item's name, D178). _problems (an array, optional) collects a word for everything dropped.
function Markup_Parse(_text, _problems = undefined) {
    var out = [];
    var s = string(_text);
    var buf = "";
    while (string_length(s) > 0) {
        var ob = string_pos("[", s);
        var oc = string_pos("{", s);
        var o = (ob == 0) ? oc : ((oc == 0) ? ob : min(ob, oc));
        if (o == 0) { buf += s; break; }
        var rest = string_delete(s, 1, o);
        if (string_char_at(s, o) == "{") {   // the older {action} spelling; any other {name} stays text (it is filled in before the text gets here)
            var cb = string_pos("}", rest);
            var inb = (cb > 1) ? string_copy(rest, 1, cb - 1) : "";
            if (cb > 1 && Prompt_IsAction(inb)) {
                buf += string_copy(s, 1, o - 1);
                if (buf != "") array_push(out, { kind: "text", s: buf, st: "" });
                buf = "";
                array_push(out, { kind: "action", s: inb });
                s = string_delete(rest, 1, cb);
            } else {
                buf += string_copy(s, 1, o);
                s = rest;
            }
            continue;
        }
        var c = string_pos("]", rest);
        var kind = (c > 1) ? Markup_TagKind(string_copy(rest, 1, c - 1)) : "";
        if (kind == "") {   // a bracket that is not a tag
            buf += string_copy(s, 1, o);
            s = rest;
            continue;
        }
        buf += string_copy(s, 1, o - 1);
        var after = string_delete(rest, 1, c);
        if (kind == "t" || kind == "a" || Markup_IsItemTag(kind)) {
            var cp = string_pos("[/" + kind + "]", after);
            var body = (cp > 0) ? string_copy(after, 1, cp - 1) : "";
            if (cp > 0 && !Markup_HasTag(body)) {
                if (buf != "") array_push(out, { kind: "text", s: buf, st: "" });
                buf = "";
                if (body != "") array_push(out, { kind: "text", s: body, st: Markup_StyleOf(kind) });
                s = string_delete(after, 1, cp + 2 + string_length(kind));
                continue;
            }
            if (is_array(_problems)) array_push(_problems, (cp > 0) ? ("nested [" + kind + "]") : ("unclosed [" + kind + "]"));
        } else if (string_copy(kind, 1, 2) == "k:") {
            if (buf != "") array_push(out, { kind: "text", s: buf, st: "" });
            buf = "";
            array_push(out, { kind: "action", s: string_delete(kind, 1, 2) });
            s = after;
            continue;
        } else if (is_array(_problems)) {
            array_push(_problems, (kind == "?") ? ("unknown tag [" + string_copy(rest, 1, c - 1) + "]") : ("stray [" + kind + "]"));
        }
        s = after;   // the tag is dropped, the text around it stays
    }
    if (buf != "") array_push(out, { kind: "text", s: buf, st: "" });
    return out;
}

function Prompt_Tokens(_text) {
    return Markup_Parse(_text);
}

// What is wrong with a string's markup, one word each (empty when it is well formed). For the audit in the tests and tools/localization/lint_markup.py.
function Markup_Problems(_text) {
    var probs = [];
    Markup_Parse(_text, probs);
    return probs;
}

// True when the text holds markup or a prompt: that is, when it must go through the rich layout and drawer.
function Prompt_HasTokens(_text) {
    var s = string(_text);
    if (string_pos("[", s) == 0 && string_pos("{", s) == 0) return false;
    var toks = Markup_Parse(s);
    var plain = "";
    for (var i = 0; i < array_length(toks); i++) {
        if (toks[i].kind == "action" || toks[i].st != "") return true;
        plain += toks[i].s;
    }
    return plain != s;   // a tag was dropped
}

function Prompt_TokensHaveAction(_toks) {
    for (var i = 0; i < array_length(_toks); i++) if (_toks[i].kind == "action") return true;
    return false;
}

// The colour a styled span is drawn in: terms in the palette's bright green, the accent in merchant gold, an item's name in its rarity colour (D178: Common white,
// Rare gold, Epic gold that pulses), everything else in _base.
function Markup_Colour(_style, _base) {
    if (_style == "term") return UI_C_TERM;
    if (_style == "accent") return UI_C_ACCENT;
    if (_style == "r1") return Rarity_Color(1);
    if (_style == "r2") return Rarity_Color(2);
    if (_style == "r3") return Rarity_Color(3);
    return _base;
}

// Segments: the tokens with each button resolved for the device (the live one when _device is undefined): { kind: "text", s, st } or
// { kind: "glyph", s (the action), acts, info, st: "" }. On a pad a run of move prompts is one d-pad glyph whose dirs list every arm.
function Markup_Segments(_text, _device = undefined) {
    var dev = is_undefined(_device) ? Prompt_Device() : _device;
    var toks = Markup_Parse(_text);
    var out = [];
    for (var i = 0; i < array_length(toks); i++) {
        var tk = toks[i];
        if (tk.kind == "text") { array_push(out, { kind: "text", s: tk.s, st: tk.st }); continue; }
        var info = Prompt_Info(tk.s, dev);
        var last = (array_length(out) > 0) ? out[array_length(out) - 1] : undefined;
        if (dev == "gamepad" && info.dir != "" && is_struct(last) && last.kind == "glyph" && last.info.dir != "") {
            if (!array_contains(last.info.dirs, info.dir)) array_push(last.info.dirs, info.dir);
            array_push(last.acts, tk.s);
            continue;
        }
        array_push(out, { kind: "glyph", s: tk.s, acts: [tk.s], info: info, st: "" });
    }
    return out;
}

// The text with each button replaced by its label ("Press A."): for logs and for plain draws that cannot show glyphs.
function Markup_Strip(_text, _device = undefined) {
    var seg = Markup_Segments(_text, _device);
    var out = "";
    for (var i = 0; i < array_length(seg); i++) out += (seg[i].kind == "text") ? seg[i].s : seg[i].info.label;
    return out;
}

function Prompt_Plain(_text, _device = undefined) {
    return Markup_Strip(_text, _device);
}

// How many characters the player sees: the text without tags, a button counting one. The dialogue typewriter reveals this many.
function Markup_Length(_text) {
    var toks = Markup_Parse(_text);
    var n = 0;
    for (var i = 0; i < array_length(toks); i++) n += (toks[i].kind == "text") ? string_length(toks[i].s) : 1;
    return n;
}

function Markup_Serialise(_s, _style) {
    if (_style == "term") return "[t]" + _s + "[/t]";
    if (_style == "accent") return "[a]" + _s + "[/a]";
    if (Markup_IsItemTag(_style)) return "[" + _style + "]" + _s + "[/" + _style + "]";
    return _s;
}

// The first _n visible characters as markup (a cut span stays closed). A button is shown whole or not at all.
function Markup_Reveal(_text, _n) {
    var toks = Markup_Parse(_text);
    var out = "";
    var left = _n;
    for (var i = 0; i < array_length(toks) && left > 0; i++) {
        var tk = toks[i];
        if (tk.kind == "action") { out += "[k:" + tk.s + "]"; left -= 1; continue; }
        var len = string_length(tk.s);
        out += Markup_Serialise((left >= len) ? tk.s : string_copy(tk.s, 1, left), tk.st);
        left -= len;
    }
    return out;
}

// The pieces of one run of markup, ready to lay out: { kind: "word" | "glyph", s, st, info, acts, w, sp, nl }. sp: a space came before it;
// nl: how many hard line breaks came before it. Words are split at spaces and keep their style.
function Markup_Pieces(_text, _device = undefined) {
    var mt = Ui_Metrics();
    var dev = is_undefined(_device) ? Prompt_Device() : _device;
    // kept per text and device while the metrics (layout, language) and the key table stay the same: the same sentence is laid out several times a frame
    var rev = variable_global_exists("prompt_rev") ? global.prompt_rev : 0;
    var cache = variable_global_exists("markup_cache") ? global.markup_cache : undefined;
    if (!is_struct(cache) || cache.mt != mt || cache.rev != rev || cache.n > 96) {
        cache = { mt: mt, rev: rev, n: 0, map: {} };
        global.markup_cache = cache;
    }
    var key = dev + "|" + string(_text);
    if (variable_struct_exists(cache.map, key)) return variable_struct_get(cache.map, key);
    var out = Markup_PiecesBuild(_text, dev);
    variable_struct_set(cache.map, key, out);
    cache.n++;
    return out;
}

function Markup_PiecesBuild(_text, _device) {
    var seg = Markup_Segments(_text, _device);
    var out = [];
    var pending = false;
    var nl = 0;
    for (var t = 0; t < array_length(seg); t++) {
        var sg = seg[t];
        if (sg.kind == "glyph") {
            array_push(out, { kind: "glyph", s: sg.s, acts: sg.acts, st: "", info: sg.info, w: Prompt_GlyphW(sg.info), sp: pending, nl: nl });
            pending = false;
            nl = 0;
            continue;
        }
        var s = sg.s;
        var word = "";
        var n = string_length(s);
        if (n > 0 && (string_char_at(s, 1) == " " || string_char_at(s, 1) == "\n")) pending = (array_length(out) > 0) || pending;
        for (var i = 1; i <= n + 1; i++) {
            var ch = (i <= n) ? string_char_at(s, i) : " ";
            if (ch == " " || ch == "\n") {
                if (word != "") {
                    array_push(out, { kind: "word", s: word, st: sg.st, w: UI_TextWidth(word), sp: pending, nl: nl });
                    pending = false;
                    nl = 0;
                    word = "";
                }
                if (ch == "\n" && i <= n) { nl++; pending = false; }
                else if (i <= n) pending = true;
            } else {
                word += ch;
            }
        }
        if (n > 0 && string_char_at(s, n) != " " && string_char_at(s, n) != "\n") pending = false;
    }
    return out;
}

// A piece that follows with no space and no line break ("[k:confirm])", "[k:left][k:right]", "[k:confirm]을(를)") hangs on to the one before it: a line
// never breaks between them, the whole group moves down together.
function Markup_Attached(_pcs, _i) {
    return _i > 0 && !_pcs[_i].sp && _pcs[_i].nl == 0;
}

function Markup_GroupW(_pcs, _i) {
    var gw = _pcs[_i].w;
    for (var j = _i + 1; j < array_length(_pcs) && Markup_Attached(_pcs, j); j++) gw += _pcs[j].w;
    return gw;
}

function Prompt_SpaceW() {
    var mt = Ui_Metrics();
    return max(mt.p, UI_TextWidth("a a") - UI_TextWidth("aa"));
}

// The width of the text on one line: the words, a space between those that had one, a glyph at its own width. Tags cost nothing.
function Markup_Width(_text, _device = undefined) {
    var pcs = Markup_Pieces(_text, _device);
    var sw = Prompt_SpaceW();
    var wx = 0;
    for (var i = 0; i < array_length(pcs); i++) {
        if (wx > 0 && pcs[i].sp) wx += sw;
        wx += pcs[i].w;
    }
    return wx;
}

function Markup_PieceText(_pc) {
    if (_pc.kind == "glyph") {
        var out = "";
        for (var a = 0; a < array_length(_pc.acts); a++) out += "[k:" + _pc.acts[a] + "]";
        return out;
    }
    return Markup_Serialise(_pc.s, _pc.st);
}

// Wraps markup to lines no wider than _w: an array of markup strings (a tag never crosses a line; each word carries its own). A plain word longer
// than a line is cut (Dialogue_BreakWordToLines); a styled word or a glyph is kept whole.
function Markup_Wrap(_text, _w, _device = undefined) {
    var pcs = Markup_Pieces(_text, _device);
    var sw = Prompt_SpaceW();
    var lines = [];
    var cur = "";
    var cx = 0;
    for (var i = 0; i < array_length(pcs); i++) {
        var pc = pcs[i];
        for (var k = 0; k < pc.nl; k++) { array_push(lines, cur); cur = ""; cx = 0; }
        var gap = (cx > 0 && pc.sp) ? sw : 0;
        if (cx > 0 && !Markup_Attached(pcs, i) && cx + gap + Markup_GroupW(pcs, i) > _w) { array_push(lines, cur); cur = ""; cx = 0; gap = 0; }
        if (cx == 0 && !Markup_Attached(pcs, i) && pc.kind == "word" && pc.st == "" && pc.w > _w) {
            var chunks = Dialogue_BreakWordToLines(pc.s, _w);
            for (var c = 0; c < array_length(chunks) - 1; c++) array_push(lines, chunks[c]);
            cur = chunks[array_length(chunks) - 1];
            cx = UI_TextWidth(cur);
            continue;
        }
        cur += ((gap > 0) ? " " : "") + Markup_PieceText(pc);
        cx += gap + pc.w;
    }
    array_push(lines, cur);
    return lines;
}

// ---- drawing: the glyphs and sentences with markup (GUI grid, palette colours, whole multiples of one font pixel) ----
function Prompt_GlyphH() {
    var mt = Ui_Metrics();
    return max(5, round(mt.line_h / mt.p)) * mt.p;
}

// A direction prompt is drawn as an arrow (a keycap with an arrow, or the d-pad cross) when it has a dir and the glyph is tall enough for the 5 x 5 arrow.
function Prompt_ArrowOk(_info) {
    var mt = Ui_Metrics();
    return _info.dir != "" && Prompt_GlyphH() / mt.p >= 8;
}

function Prompt_GlyphW(_info) {
    var mt = Ui_Metrics();
    var h = Prompt_GlyphH();
    if (Prompt_ArrowOk(_info)) {   // square, and an odd number of font pixels across a keycap so the arrow sits in the middle
        var hc = h / mt.p;
        return ((_info.kind == "pad") ? hc : hc + ((hc mod 2 == 0) ? 1 : 0)) * mt.p;   // the arrow's mask is centred in the face either way
    }
    var tw = UI_TextWidth(_info.label);
    var w = (_info.kind == "pad") ? max(h, tw + 3 * mt.p) : max(h, tw + 4 * mt.p);
    return ceil(w / mt.p) * mt.p;
}

// Solid triangle masks for the arrow keycap (the same shape as the menu cursor), '.' clear.
function Prompt_ArrowMask(_dir) {
    switch (_dir) {
        case "up": return ["..#..", ".###.", "#####"];
        case "down": return ["#####", ".###.", "..#.."];
        case "left": return ["..#", ".##", "###", ".##", "..#"];
        case "right": return ["#..", "##.", "###", "##.", "#.."];
    }
    return [];
}

// The d-pad's plus sign (arms one font pixel thick, 5 x 5) inside the round button: the arms that count are dark, the others the light green.
function Prompt_DrawDpad(_x, _y, _hc, _dirs, _p) {
    var o = (_hc - 5) div 2;
    var cx = _x + (o + 2) * _p;
    var cy = _y + (o + 2) * _p;
    Ui_Box(cx, cy, cx + _p, cy + _p, UI_C_LIGHT);
    var lit_u = array_contains(_dirs, "up") ? UI_C_DARKEST : UI_C_LIGHT;
    var lit_d = array_contains(_dirs, "down") ? UI_C_DARKEST : UI_C_LIGHT;
    var lit_l = array_contains(_dirs, "left") ? UI_C_DARKEST : UI_C_LIGHT;
    var lit_r = array_contains(_dirs, "right") ? UI_C_DARKEST : UI_C_LIGHT;
    Ui_Box(cx, cy - 2 * _p, cx + _p, cy, lit_u);
    Ui_Box(cx, cy + _p, cx + _p, cy + 3 * _p, lit_d);
    Ui_Box(cx - 2 * _p, cy, cx, cy + _p, lit_l);
    Ui_Box(cx + _p, cy, cx + 3 * _p, cy + _p, lit_r);
}

// Draws one glyph with its top-left at (_x, _y), one text line tall. Keyboard: a keycap (light outline, dark face, a lower edge) with the key's name,
// or an arrow for a move key. Pad: a light round button (a pill for LB / RB) with the label cut out in dark; the d-pad is a plus sign with the arrows
// that count lit. Returns its width.
function Prompt_DrawGlyph(_x, _y, _info, _alpha = 1) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = Prompt_GlyphW(_info);
    var h = Prompt_GlyphH();
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var arrow = Prompt_ArrowOk(_info);
    if (_info.kind == "pad") {
        var hc = h / p;
        var wc = w / p;
        var rad = hc / 2;
        for (var r = 0; r < hc; r++) {
            var yc = r + 0.5 - rad;
            var inset = round(rad - sqrt(max(0, rad * rad - yc * yc)));
            Ui_Box(_x + inset * p, _y + r * p, _x + (wc - inset) * p, _y + (r + 1) * p, UI_C_LIGHTEST);
        }
        if (arrow) Prompt_DrawDpad(_x, _y, hc, _info.dirs, p);
        else Ui_Text(_x + w / 2, _y + (h - mt.line_h) div 2, _info.label, UI_C_DARKEST, fa_center);
    } else {
        Ui_Box(_x + p, _y, _x + w - p, _y + h, UI_C_LIGHTEST);
        Ui_Box(_x, _y + p, _x + w, _y + h - p, UI_C_LIGHTEST);
        Ui_Box(_x + p, _y + p, _x + w - p, _y + h - 2 * p, UI_C_DARK);
        Ui_Box(_x + p, _y + h - 2 * p, _x + w - p, _y + h - p, UI_C_LIGHT);   // the key's lower edge
        if (arrow) {
            var mk = Prompt_ArrowMask(_info.dir);
            var fc = h / p - 3;   // the face's rows
            Ui_DrawMask(_x + ((w / p - string_length(mk[0])) div 2) * p, _y + (1 + (fc - array_length(mk)) div 2) * p, mk, p, UI_C_LIGHTEST);
        } else {
            Ui_Text(_x + w / 2, _y + (h - 2 * p - mt.line_h) div 2 + p, _info.label, UI_C_LIGHTEST, fa_center);
        }
    }
    draw_set_alpha(a0);
    return w;
}

// Lays a sentence with markup out in a column _w wide. Returns { items, h, lines, line_w }: each item is a word (with its style st) or a glyph with its
// own x, y (line pitch = one text line + one font pixel) and line number.
function Prompt_RichLayout(_text, _w, _device = undefined) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var pitch = mt.line_h + p;
    var space_w = Prompt_SpaceW();
    var pcs = Markup_Pieces(_text, _device);
    var items = [];
    var line_w = [0];
    var cx = 0;
    var line = 0;
    for (var i = 0; i < array_length(pcs); i++) {
        var pc = pcs[i];
        for (var k = 0; k < pc.nl; k++) { line_w[line] = cx; line++; array_push(line_w, 0); cx = 0; }
        if (cx > 0 && pc.sp) cx += space_w;
        if (cx > 0 && !Markup_Attached(pcs, i) && cx + Markup_GroupW(pcs, i) > _w) { line_w[line] = cx; line++; array_push(line_w, 0); cx = 0; }
        if (pc.kind == "glyph") array_push(items, { kind: "glyph", info: pc.info, x: cx, y: line * pitch, line: line, w: pc.w });
        else array_push(items, { kind: "word", s: pc.s, st: pc.st, x: cx, y: line * pitch, line: line, w: pc.w });
        cx += pc.w;
    }
    line_w[line] = cx;
    return { items: items, h: (line + 1) * pitch - p, lines: line + 1, line_w: line_w };
}

// Draws a sentence with markup, top-left (_x, _y) or centred on _x + _w / 2 with _halign = fa_center. _col is the colour of plain text.
function Prompt_RichDraw(_x, _y, _text, _w, _col, _halign = fa_left, _alpha = 1) {
    var lay = Prompt_RichLayout(_text, _w);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    for (var i = 0; i < array_length(lay.items); i++) {
        var it = lay.items[i];
        var off = (_halign == fa_center) ? round((_w - lay.line_w[it.line]) / 2) : 0;
        if (it.kind == "glyph") Prompt_DrawGlyph(_x + off + it.x, _y + it.y, it.info, _alpha);
        else Ui_Text(_x + off + it.x, _y + it.y, it.s, Markup_Colour(it.st, _col));
    }
    draw_set_alpha(a0);
    return lay.h;
}

// One line of markup at (_x, _y), no wrapping (the dialogue box wraps first with Markup_Wrap). _flat (a colour) draws every word in that one colour and no
// glyphs: the shadow under cutscene text. Returns the width.
function Markup_DrawLine(_x, _y, _text, _col, _alpha = 1, _device = undefined, _flat = -1) {
    var pcs = Markup_Pieces(_text, _device);
    var sw = Prompt_SpaceW();
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var cx = 0;
    for (var i = 0; i < array_length(pcs); i++) {
        var pc = pcs[i];
        if (cx > 0 && pc.sp) cx += sw;
        if (pc.kind == "glyph") {
            if (_flat == -1) Prompt_DrawGlyph(_x + cx, _y, pc.info, _alpha);
        } else {
            Ui_Text(_x + cx, _y, pc.s, (_flat == -1) ? Markup_Colour(pc.st, _col) : _flat);
        }
        cx += pc.w;
    }
    draw_set_alpha(a0);
    return cx;
}

// ============================================================================================================================
// G8 (D136): controller rumble. A short vibration on a Perfect hit, a BREAK, a big hit taken and the player's death.
// The events are READ, never called from the combat code: Rumble_Step (obj_ui_controller's Step) takes a snapshot each step (the Perfect freeze,
// the enemy's broken flag, the fighter's HP, the defence bar) and Rumble_Detect turns two snapshots into an event. A heavy move is a telegraphed
// one: it goes through the defence bar, so "the bar was up last step and is gone now with HP lost" is the heavy hit landing.
// Only the pad the player used last (D92) buzzes, never with the keyboard or mouse as the last device, and never with the setting Off.
// It stops at once on pause, focus loss (D122), a room change and game end. The motors are only touched in Rumble_Send (gamepad_set_vibration).
// ============================================================================================================================

// event -> strength (0..1, the stronger motor), the two motors (left = low-frequency, right = high-frequency) and the time in ms. Unknown event: undefined.
function Rumble_Spec(_event) {
    switch (_event) {
        case "perfect": return { strength: 0.4, left: 0,   right: 0.4, ms: 80 };    // light tick
        case "break":   return { strength: 0.5, left: 0.5, right: 0.4, ms: 150 };   // medium
        case "big_hit": return { strength: 0.8, left: 0.8, right: 0.6, ms: 200 };   // medium-strong
        case "death":   return { strength: 1,   left: 1,   right: 0.8, ms: 400 };   // strong
    }
    return undefined;
}

// Pure: last step's snapshot and this step's -> "" or the strongest event. A snapshot is { hitstop, broken, hp, max_hp, def }.
// Big hit = HP lost >= 25% of max HP in one step, or any HP lost when the defence bar of a heavy move just ended.
function Rumble_Detect(_prev, _cur) {
    if (!is_struct(_prev) || !is_struct(_cur)) return "";
    if (_cur.hp <= 0 && _prev.hp > 0) return "death";
    var lost = _prev.hp - _cur.hp;
    if (lost > 0 && (lost >= 0.25 * _cur.max_hp || (_prev.def && !_cur.def))) return "big_hit";
    if (_cur.broken && !_prev.broken) return "break";
    if (_cur.hitstop && !_prev.hitstop) return "perfect";
    return "";
}

function Rumble_New() {
    return { left: 0, right: 0, ms: 0, strength: 0, pad: -1, sent_l: 0, sent_r: 0, sent_pad: -1, snap: undefined, room: -1, focused: true };
}

// Starts an event when the setting is On, the last device is the pad, a pad is there (_pad >= 0) and the event is known. A weaker event never cuts a
// stronger one that is still running; an equal or stronger one replaces it. Returns whether it started.
function Rumble_Fire(_st, _event, _on, _device, _pad) {
    if (!_on || _device != "gamepad" || _pad < 0) return false;
    var sp = Rumble_Spec(_event);
    if (is_undefined(sp)) return false;
    if (_st.ms > 0 && sp.strength < _st.strength) return false;
    _st.left = sp.left;
    _st.right = sp.right;
    _st.ms = sp.ms;
    _st.strength = sp.strength;
    _st.pad = _pad;
    return true;
}

function Rumble_Stop(_st) {
    _st.left = 0;
    _st.right = 0;
    _st.ms = 0;
    _st.strength = 0;
}

// Counts the time down by _step_ms (Presentation_StepMs); at 0 the motors go back to 0.
function Rumble_Tick(_st, _step_ms) {
    if (_st.ms <= 0) { Rumble_Stop(_st); return; }
    _st.ms -= _step_ms;
    if (_st.ms <= 0) Rumble_Stop(_st);
}

// The reasons to stop at once (pure): the window lost focus, the pause menu is open, the room changed.
function Rumble_Blocked(_focused, _paused, _room_now, _room_prev) {
    return !_focused || _paused || _room_now != _room_prev;
}

function Rumble_Update(_st, _step_ms, _blocked) {
    if (_blocked) Rumble_Stop(_st);
    else Rumble_Tick(_st, _step_ms);
}

// ---- the live side ----
function Rumble_Get() {
    if (!variable_global_exists("rumble") || !is_struct(global.rumble)) global.rumble = Rumble_New();
    return global.rumble;
}

// The pad that buzzes: the first connected one (what Input_Update reads), and only while the pad is the last device used.
function Rumble_ActivePad() {
    if (Prompt_Device() != "gamepad") return -1;
    return Input_GamepadDevice();
}

function Rumble_Dispatch(_event) {
    return Rumble_Fire(Rumble_Get(), _event, Settings_RumbleOn(), Prompt_Device(), Rumble_ActivePad());
}

// The only call that reaches the motors. Sends when the wanted values differ from the last ones sent (and zeroes a pad it is no longer using).
function Rumble_Send(_st) {
    if (_st.sent_pad >= 0 && _st.sent_pad != _st.pad && (_st.sent_l != 0 || _st.sent_r != 0)) {
        if (gamepad_is_connected(_st.sent_pad)) gamepad_set_vibration(_st.sent_pad, 0, 0);
        _st.sent_l = 0;
        _st.sent_r = 0;
    }
    if (_st.pad < 0) return;
    if (_st.left == _st.sent_l && _st.right == _st.sent_r) { _st.sent_pad = _st.pad; return; }
    if (gamepad_is_connected(_st.pad)) gamepad_set_vibration(_st.pad, _st.left, _st.right);
    _st.sent_l = _st.left;
    _st.sent_r = _st.right;
    _st.sent_pad = _st.pad;
}

// Stop and send the zero now (game end, focus loss).
function Rumble_StopNow() {
    var st = Rumble_Get();
    Rumble_Stop(st);
    Rumble_Send(st);
}

// Called by Focus_Step with window_has_focus(): losing focus stops the motors at once, in the same step.
function Rumble_FocusStep(_has_focus) {
    var st = Rumble_Get();
    st.focused = _has_focus;
    if (!_has_focus) Rumble_StopNow();
}

// A field of a battle controller instance or of a struct shaped like one.
function Rumble_Has(_o, _key) {
    return is_struct(_o) ? variable_struct_exists(_o, _key) : variable_instance_exists(_o, _key);
}

// Reads a one-shot flag of the battle controller (or a struct shaped like one) and clears it: the controller rumble takes each Perfect / BREAK once.
function Rumble_Take(_bc, _key) {
    if (!Rumble_Has(_bc, _key)) return false;
    var v = is_struct(_bc) ? variable_struct_get(_bc, _key) : variable_instance_get(_bc, _key);
    if (is_struct(_bc)) variable_struct_set(_bc, _key, false); else variable_instance_set(_bc, _key, false);
    return bool(v);
}

// What the detector looks at, from a fighter and (in a fight) its battle controller (or a struct shaped like one). undefined when there is no fighter.
// hitstop = a Perfect hit landed since the last look; broken = the enemy is BROKEN, or a BREAK landed since the last look. The two landings are one-shot
// flags the combat code raises (rumble_perfect, rumble_break) and this takes: the length of the freeze does not tell a Perfect from a crit or a BREAK, and a
// BREAK can start and end between two looks.
function Rumble_SnapshotOf(_ch, _bc) {
    var hit = false;
    var broken = false;
    var def = false;
    if (is_struct(_bc) || instance_exists(_bc)) {
        if (Rumble_Has(_bc, "p") && is_struct(_bc.p)) _ch = _bc.p;
        hit = Rumble_Take(_bc, "rumble_perfect");
        if (Rumble_Has(_bc, "def_active")) def = _bc.def_active;
        if (Rumble_Has(_bc, "e") && is_struct(_bc.e) && variable_struct_exists(_bc.e, "broken")) broken = _bc.e.broken;
        if (Rumble_Take(_bc, "rumble_break")) broken = true;
    }
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "hp") || !variable_struct_exists(_ch, "max_hp")) return undefined;
    return { hitstop: hit, broken: broken, hp: _ch.hp, max_hp: _ch.max_hp, def: def };
}

// What the detector looks at now: the battle controller when in a fight, else the player on the map.
function Rumble_Snapshot() {
    var bc = noone;
    if (room == rm_battle && instance_exists(obj_battle_controller)) bc = instance_find(obj_battle_controller, 0);
    return Rumble_SnapshotOf(GameState_Get().player_ch, bc);
}

// One step of the live rumble (obj_ui_controller's Step, before any early exit). Events found while a stop reason holds are dropped.
function Rumble_Step(_step_ms) {
    var st = Rumble_Get();
    var gs = GameState_Get();
    var paused = (variable_struct_exists(gs, "ui") && gs.ui.mode == UI_MENU);   // D140: the one menu is the pause
    var room_prev = (st.room == -1) ? room : st.room;   // the very first step is not a room change
    st.room = room;
    if (room_prev != room) st.snap = undefined;   // a new room is a new fight: nothing to compare with yet
    var blocked = Rumble_Blocked(st.focused, paused, room, room_prev) || !Settings_RumbleOn() || Prompt_Device() != "gamepad";
    var cur = Rumble_Snapshot();
    var ev = Rumble_Detect(st.snap, cur);
    st.snap = cur;
    Rumble_Update(st, _step_ms, blocked);
    if (ev != "" && !blocked) Rumble_Dispatch(ev);
    Rumble_Send(st);
}
