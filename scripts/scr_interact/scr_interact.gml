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

    switch (_inst.interact_kind) {
        case INTERACT_CHEST: {
            var key = "chest_" + string(_inst.chest_id);
            if (Flag_Get(key)) {
                Dialogue_StartLines(["It's empty."]); 
                break;
            }

            var qty = max(1, _inst.chest_qty);
            gs.player_ch.inventory = Inv_Add(gs.player_ch.inventory, _inst.chest_item_id, qty);
            Flag_Set(key, true);
            Dialogue_StartLines(["You got " + string(qty) + " item(s)."]);
        } break;

        case INTERACT_DOOR: {
            if (_inst.door_room != noone) {
                RoomState_Save(room);
                GameState_SetBattleReturn(_inst.door_room, _inst.door_x, _inst.door_y);
                GameState_SetJustReturned(true);
                room_goto(_inst.door_room);
            }
        } break;

        case INTERACT_SWITCH: {
            var skey = "switch_" + string(_inst.switch_id);
            Flag_Toggle(skey);
            Dialogue_StartLines(["Switch toggled."]);
        } break;

        case INTERACT_NPC: {
            Dialogue_Start(_inst.npc_id);
        } break;

        case INTERACT_SHOP: {
            Shop_Open(_inst.shop_id);
        } break;

        case INTERACT_CHECKPOINT: {
            GameState_SetCheckpoint(room, _inst.x, _inst.y);
            Dialogue_StartLines(["Checkpoint set."]);
        } break;
    }

    GameState_SyncLegacy();
}
