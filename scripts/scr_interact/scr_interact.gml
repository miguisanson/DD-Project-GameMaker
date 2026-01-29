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
    var margin = 2;

    switch (_pl.face) {
        case UP: {
            var dy = _pl.bbox_top - _inst.bbox_bottom;
            return (dy >= -margin && dy <= tile + margin) && (_pl.bbox_right > _inst.bbox_left) && (_pl.bbox_left < _inst.bbox_right);
        }
        case DOWN: {
            var dy2 = _inst.bbox_top - _pl.bbox_bottom;
            return (dy2 >= -margin && dy2 <= tile + margin) && (_pl.bbox_right > _inst.bbox_left) && (_pl.bbox_left < _inst.bbox_right);
        }
        case LEFT: {
            var dx = _pl.bbox_left - _inst.bbox_right;
            return (dx >= -margin && dx <= tile + margin) && (_pl.bbox_bottom > _inst.bbox_top) && (_pl.bbox_top < _inst.bbox_bottom);
        }
        case RIGHT: {
            var dx2 = _inst.bbox_left - _pl.bbox_right;
            return (dx2 >= -margin && dx2 <= tile + margin) && (_pl.bbox_bottom > _inst.bbox_top) && (_pl.bbox_top < _inst.bbox_bottom);
        }
    }

    return false;
}



function Interact_Handle(_inst) {
    var gs = GameState_Get();
    var pl = gs.player_inst;
    if (!instance_exists(pl)) return;
    if (!Action_CanAct(pl)) {
        Action_Request(pl, "interact");
        return;
    }
    if (!Interact_PlayerFacing(pl, _inst)) return;
    if (!Action_Request(pl, "interact")) return;

    var name = "";
    if (variable_instance_exists(_inst, "interact_name")) name = _inst.interact_name;
    if (name == "") name = object_get_name(_inst.object_index);

    var has_dialogue_id = false;
    var base_id = "default";
    if (variable_instance_exists(_inst, "dialogue_id")) {
        var did = _inst.dialogue_id;
        if (did != -1 && did != "") {
            base_id = did;
            has_dialogue_id = true;
        }
    }
    if (!has_dialogue_id && _inst.interact_kind == INTERACT_NPC && variable_instance_exists(_inst, "npc_id")) {
        base_id = _inst.npc_id;
        has_dialogue_id = true;
    }

    var after_id = "";
    if (variable_instance_exists(_inst, "dialogue_id_after")) {
        var aid = _inst.dialogue_id_after;
        if (aid != -1 && aid != "") {
            after_id = aid;
        }
    }

    // swap-state interaction
    if (variable_instance_exists(_inst, "swap_on_interact") && _inst.swap_on_interact) {
        if (!_inst.swapped) {
            if (variable_instance_exists(_inst, "swap_sprite") && _inst.swap_sprite != noone) {
                _inst.sprite_index = _inst.swap_sprite;
            }
            _inst.swapped = true;

            // loot reward (optional, per-instance)
            var loot_lines = [];
            var gave_loot = false;

            if (variable_instance_exists(_inst, "loot_list") && is_array(_inst.loot_list) && array_length(_inst.loot_list) > 0) {
                for (var i = 0; i < array_length(_inst.loot_list); i++) {
                    var li = _inst.loot_list[i];
                    if (!is_struct(li) || !variable_struct_exists(li, "item_id")) continue;
                    var id = li.item_id;
                    var qty = 1;
                    if (variable_struct_exists(li, "qty")) qty = li.qty;
                    qty = max(1, qty);

                    gs.player_ch.inventory = Inv_Add(gs.player_ch.inventory, id, qty);
                    var item = ItemDB_Get(id);
                    var item_name = item.name;
                    var lines = DialogueDB_GetFormatted("loot_received", { item: item_name, qty: qty });
                    for (var j = 0; j < array_length(lines); j++) array_push(loot_lines, lines[j]);
                    gave_loot = true;
                }
            } else {
                var id2 = 0;
                var qty2 = 1;
                if (variable_instance_exists(_inst, "loot_item_id")) id2 = _inst.loot_item_id;
                if (variable_instance_exists(_inst, "loot_qty")) qty2 = _inst.loot_qty;
                if (id2 <= 0 && variable_instance_exists(_inst, "chest_item_id")) id2 = _inst.chest_item_id;
                if (variable_instance_exists(_inst, "chest_qty")) qty2 = _inst.chest_qty;

                if (id2 > 0) {
                    qty2 = max(1, qty2);
                    gs.player_ch.inventory = Inv_Add(gs.player_ch.inventory, id2, qty2);
                    var item2 = ItemDB_Get(id2);
                    var item_name2 = item2.name;
                    var lines2 = DialogueDB_GetFormatted("loot_received", { item: item_name2, qty: qty2 });
                    for (var k = 0; k < array_length(lines2); k++) array_push(loot_lines, lines2[k]);
                    gave_loot = true;
                }
            }

            if (gave_loot) {
                Dialogue_StartWithSpeaker(name, loot_lines);
            } else {
                Dialogue_StartWithSpeaker(name, DialogueDB_Get(base_id));
            }
        } else {
            var use_id = (after_id != "") ? after_id : base_id;
            Dialogue_StartWithSpeaker(name, DialogueDB_Get(use_id));
        }

        GameState_SyncLegacy();
        return;
    }

    Dialogue_StartWithSpeaker(name, DialogueDB_Get(base_id));

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
