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
        inp.bindings.menu = [ord("I"), vk_tab];

        inp.bindings.menu_up = [ord("W"), vk_up];
        inp.bindings.menu_down = [ord("S"), vk_down];
        inp.bindings.menu_left = [ord("A"), vk_left];
        inp.bindings.menu_right = [ord("D"), vk_right];

        inp.bindings.debug_save = [vk_f5];
        inp.bindings.debug_load = [vk_f9];
        inp.bindings.debug_levelup = [ord("L")];
    }

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


function Input_Update() {
    Input_Init();
    if (global.input.last_step_time == current_time) return;
    global.input.last_step_time = current_time;

    var inp = global.input;
    inp.last_time = current_time;
    inp.frame += 1;

    var names = variable_struct_get_names(inp.bindings);
    for (var i = 0; i < array_length(names); i++) {
        var action = names[i];
        var bind = variable_struct_get(inp.bindings, action);
        var keys = bind;
        if (is_struct(bind) && variable_struct_exists(bind, "keys")) keys = bind.keys;
        var held = false;

        if (is_array(keys)) {
            for (var k = 0; k < array_length(keys); k++) {
                var key = keys[k];
                if (key != -1 && keyboard_check(key)) {
                    held = true;
                    break;
                }
            }
        }

        var prev = false;
        if (variable_struct_exists(inp.state, action)) {
            var st = variable_struct_get(inp.state, action);
            if (is_struct(st) && variable_struct_exists(st, "held")) prev = st.held;
        }

        var pressed = held && !prev;
        variable_struct_set(inp.state, action, { held: held, pressed: pressed });

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
    Input_EnsureUpdated();
    variable_struct_set(global.input.buffer, _action, global.input.frame);
}

function Input_ActionBuffered(_action, _max_age) {
    Input_EnsureUpdated();
    if (!variable_struct_exists(global.input.buffer, _action)) return false;
    var t = variable_struct_get(global.input.buffer, _action);
    if (global.input.frame - t > _max_age) {
        variable_struct_remove(global.input.buffer, _action);
        return false;
    }
    return true;
}

function Input_ActionConsume(_action) {
    Input_EnsureUpdated();
    if (variable_struct_exists(global.input.buffer, _action)) {
        variable_struct_remove(global.input.buffer, _action);
    }
}

function Input_ActionCooldownReady(_action) {
    Input_EnsureUpdated();
    if (!variable_struct_exists(global.input.cooldown, _action)) return true;
    var t = variable_struct_get(global.input.cooldown, _action);
    return global.input.frame >= t;
}

function Input_ActionSetCooldown(_action, _frames) {
    Input_EnsureUpdated();
    variable_struct_set(global.input.cooldown, _action, global.input.frame + _frames);
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
