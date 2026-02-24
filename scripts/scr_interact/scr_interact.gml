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
    var INF = 1000000000;
    return (Interact_FacingDistance(_pl, _inst) < INF);
}


function Interact_FacingDistance(_pl, _inst) {
    var INF = 1000000000;
    if (!instance_exists(_pl)) return INF;
    if (!variable_instance_exists(_pl, "face")) return INF;
    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = _pl.tile_size;
    var px = round(_pl.x / tile) * tile;
    var py = round(_pl.y / tile) * tile;
    var tx = px;
    var ty = py;

    switch (_pl.face) {
        case UP:    ty -= tile; break;
        case DOWN:  ty += tile; break;
        case LEFT:  tx -= tile; break;
        case RIGHT: tx += tile; break;
        default:    return INF;
    }

    var hit = false;
    var cx = tx + (tile * 0.5);
    var cy = ty + (tile * 0.5);
    with (_pl) {
        hit = position_meeting(cx, cy, _inst);
    }

    return hit ? tile : INF;
}

function Interact_GetTarget(_pl) {
    if (!instance_exists(_pl)) return noone;
    if (!variable_instance_exists(_pl, "face")) return noone;

    var gs = GameState_Get();
    var frame = Input_Frame();
    if (!variable_struct_exists(gs, "interact_cache_frame")) gs.interact_cache_frame = -1;
    if (!variable_struct_exists(gs, "interact_cache_target")) gs.interact_cache_target = noone;
    if (gs.interact_cache_frame == frame) {
        var cached = gs.interact_cache_target;
        if (cached == noone || instance_exists(cached)) return cached;
    }

    var INF = 1000000000;
    var best = noone;
    var best_dist = INF;
    with (obj_interactable) {
        var d = Interact_FacingDistance(_pl, self);
        if (d < best_dist) {
            best_dist = d;
            best = self;
        }
    }
    gs.interact_cache_frame = frame;
    gs.interact_cache_target = best;
    return best;
}



function Interact_Handle(_inst) {
    var gs = GameState_Get();
    var pl = gs.player_inst;
    if (!instance_exists(pl)) return;
    if (!variable_instance_exists(pl, "face")) return;
    if (!Action_CanAct(pl)) {
        Action_Request(pl, "interact");
        return;
    }
    var target = Interact_GetTarget(pl);
    if (target != _inst) return;
    if (!Interact_PlayerFacing(pl, _inst)) return;
    if (variable_struct_exists(gs.ui, "dialogue_require_release") && gs.ui.dialogue_require_release && Input_Held("interact")) return;
    if (variable_struct_exists(gs.ui, "dialogue_lock") && gs.ui.dialogue_lock > 0) return;
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
        var is_container = (variable_instance_exists(_inst, "is_container") && _inst.is_container);
        if (!_inst.swapped) {
            if (variable_instance_exists(_inst, "swap_sprite") && _inst.swap_sprite != noone) {
                _inst.sprite_index = _inst.swap_sprite;
            }
            _inst.swapped = true;
            RoomState_SaveInstance(_inst, ["swapped","sprite_index"], false);

            // World interaction SFX
            var is_barrel = (_inst.object_index == obj_barrel) || object_is_ancestor(_inst.object_index, obj_barrel);
            var is_chest = (_inst.object_index == obj_chest) || object_is_ancestor(_inst.object_index, obj_chest);
            var is_torch_like = (_inst.object_index == obj_torch) || (_inst.object_index == obj_fire_stand);
            if (is_barrel) {
                SFX_Play("barrel_break");
            } else if (is_chest) {
                SFX_Play("chest_open");
            } else if (is_torch_like) {
                SFX_Play("kill_torch");
            }

            if (is_container) {
                // shared loot system (container)
                var lvl = 1;
                if (variable_instance_exists(_inst, "container_level")) lvl = _inst.container_level;
                var key = "";
                if (variable_instance_exists(_inst, "loot_table_key")) key = _inst.loot_table_key;
                if (key == "") {
                    if (_inst.object_index == obj_chest) key = "chest_basic";
                    if (_inst.object_index == obj_barrel) key = "barrel_basic";
                }

                var loot = [];
                if (key != "") loot = Loot_RollContainer(lvl, key);
                if (is_array(loot) && array_length(loot) > 0) {
                    gs.player_ch.inventory = Loot_Grant(gs.player_ch.inventory, loot);

                    var loot_lines = [];
                    for (var i = 0; i < array_length(loot); i++) {
                        var it = loot[i];
                        var qty = it.qty;
                        var item = ItemDB_Get(it.item_id);
                        var lines = DialogueDB_GetFormatted("loot_received", { item: item.name, qty: qty });
                        for (var j = 0; j < array_length(lines); j++) array_push(loot_lines, lines[j]);
                    }
                    Dialogue_StartWithSpeaker(name, loot_lines);
                } else {
                    Dialogue_StartWithSpeaker(name, DialogueDB_Get("loot_empty"));
                }
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

    var skip_dialogue = false;
    if (_inst.interact_kind == INTERACT_CHECKPOINT && variable_instance_exists(_inst, "is_bed") && _inst.is_bed) skip_dialogue = true;

    if (!skip_dialogue) {
        Dialogue_StartWithSpeaker(name, DialogueDB_Get(base_id));
    }

    // other interact types (door/checkpoint)
    switch (_inst.interact_kind) {
        case INTERACT_DOOR: {
            if (_inst.door_room != noone) {
                RoomState_OnRoomExit();
                GameState_SetBattleReturn(_inst.door_room, _inst.door_x, _inst.door_y, -1);
                GameState_SetJustReturned(true);
                room_goto(_inst.door_room);
            }
        } break;

        case INTERACT_CHECKPOINT: {
            GameState_SetCheckpoint(room, _inst.x, _inst.y);
            if (variable_instance_exists(_inst, "is_bed") && _inst.is_bed) {
                SaveMenu_Open("save", "bed");
            }
        } break;
    }

    GameState_SyncLegacy();
}
