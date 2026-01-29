function Flag_Get(_key) {
    var gs = GameState_Get();
    if (variable_struct_exists(gs.flags, _key)) return variable_struct_get(gs.flags, _key);
    return false;
}

function Flag_Set(_key, _value) {
    var gs = GameState_Get();
    variable_struct_set(gs.flags, _key, _value);
}

function Flag_Toggle(_key) {
    var v = Flag_Get(_key);
    Flag_Set(_key, !v);
}

function Interact_PlayerFacing(_pl, _inst) {
    var tile = 16;
    if (variable_instance_exists(_pl, "tile_size")) tile = _pl.tile_size;

    var tx = _pl.x;
    var ty = _pl.y;

    switch (_pl.face) {
        case UP:    ty -= tile; break;
        case DOWN:  ty += tile; break;
        case LEFT:  tx -= tile; break;
        case RIGHT: tx += tile; break;
    }

    return (_inst.x == tx && _inst.y == ty);
}

function Interact_Handle(_inst) {
    var gs = GameState_Get();
    var pl = gs.player_inst;
    if (!instance_exists(pl)) return;
    if (!keyboard_check_pressed(ord("Z"))) return;
    if (!Interact_PlayerFacing(pl, _inst)) return;

    var name = "";
    if (variable_instance_exists(_inst, "interact_name")) name = _inst.interact_name;
    if (name == "") name = object_get_name(_inst.object_index);

    // swap-state interaction
    if (variable_instance_exists(_inst, "swap_on_interact") && _inst.swap_on_interact) {
        if (!_inst.swapped) {
            if (variable_instance_exists(_inst, "swap_sprite") && _inst.swap_sprite != noone) {
                _inst.sprite_index = _inst.swap_sprite;
            }
            _inst.swapped = true;

            // chest reward (optional)
            if (variable_instance_exists(_inst, "chest_item_id") && _inst.chest_item_id > 0) {
                var qty = max(1, _inst.chest_qty);
                gs.player_ch.inventory = Inv_Add(gs.player_ch.inventory, _inst.chest_item_id, qty);
                var item = ItemDB_Get(_inst.chest_item_id);
                var item_name = item.name;
                Dialogue_StartWithSpeaker(name, ["Received " + item_name + " x" + string(qty)]);
            } else {
                Dialogue_StartWithSpeaker(name, ["..."]);
            }
        } else {
            Dialogue_StartWithSpeaker(name, ["It's empty."]);
        }

        GameState_SyncLegacy();
        return;
    }

    // dialogue by id or lines
    if (variable_instance_exists(_inst, "dialogue_lines") && is_array(_inst.dialogue_lines) && array_length(_inst.dialogue_lines) > 0) {
        Dialogue_StartWithSpeaker(name, _inst.dialogue_lines);
    } else if (variable_instance_exists(_inst, "dialogue_id") && _inst.dialogue_id != -1) {
        var lines = DialogueDB_Get(_inst.dialogue_id);
        Dialogue_StartWithSpeaker(name, lines);
    } else {
        Dialogue_StartWithSpeaker(name, ["..."]);
    }

    // other interact types (door/shop/checkpoint) keep compatibility
    switch (_inst.interact_kind) {
        case INTERACT_DOOR: {
            if (_inst.door_room != noone) {
                if (variable_global_exists("room_state_ready") && global.room_state_ready) RoomState_Save(room);
                GameState_SetBattleReturn(_inst.door_room, _inst.door_x, _inst.door_y);
                GameState_SetJustReturned(true);
                room_goto(_inst.door_room);
            }
        } break;

        case INTERACT_SHOP: {
            Shop_Open(_inst.shop_id);
        } break;

        case INTERACT_CHECKPOINT: {
            GameState_SetCheckpoint(room, _inst.x, _inst.y);
        } break;
    }

    GameState_SyncLegacy();
}

