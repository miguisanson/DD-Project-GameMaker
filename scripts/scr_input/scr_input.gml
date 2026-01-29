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

        inp.bindings.interact = [ord("Z"), vk_space];
        inp.bindings.confirm = [ord("Z"), vk_enter];
        inp.bindings.cancel = [ord("X"), vk_escape];
        inp.bindings.menu = [ord("I"), vk_tab];

        inp.bindings.menu_up = [ord("W"), vk_up];
        inp.bindings.menu_down = [ord("S"), vk_down];
        inp.bindings.menu_left = [ord("A"), vk_left];
        inp.bindings.menu_right = [ord("D"), vk_right];

        inp.bindings.debug_save = [vk_f5];
        inp.bindings.debug_load = [vk_f9];
    }

    if (!variable_struct_exists(inp, "state")) {
        inp.state = {};
    }

    if (!variable_struct_exists(inp, "last_time")) {
        inp.last_time = -1;
    }
}

function Input_Update() {
    Input_Init();

    var inp = global.input;
    inp.last_time = current_time;

    var names = variable_struct_get_names(inp.bindings);
    for (var i = 0; i < array_length(names); i++) {
        var action = names[i];
        var keys = variable_struct_get(inp.bindings, action);
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
    }
}

function Input_EnsureUpdated() {
    Input_Init();
    if (global.input.last_time == current_time) return;
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
