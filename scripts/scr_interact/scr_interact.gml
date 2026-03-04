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

function GraveLoot_ProgressFlagKey() {
    return "grave_loot_progress_stage";
}

function GraveLoot_GetStage() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    var key = GraveLoot_ProgressFlagKey();
    if (!variable_struct_exists(gs.flags, key)) variable_struct_set(gs.flags, key, 0);
    return clamp(round(real(variable_struct_get(gs.flags, key))), 0, 4);
}

function GraveLoot_SetStage(_stage) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    variable_struct_set(gs.flags, GraveLoot_ProgressFlagKey(), clamp(round(real(_stage)), 0, 4));
}

function GraveLoot_StageChance(_stage) {
    var st = clamp(round(real(_stage)), 0, 4);
    switch (st) {
        case 0: return 0.50; // Lv2 item
        case 1: return 0.25; // Lv2 item
        case 2: return 0.10; // Lv3 item
        case 3: return 0.05; // Lv3 item
        default: return 0.01; // Skillbook
    }
}

function GraveLoot_RollTierItem(_tier) {
    var tier = clamp(round(real(_tier)), 1, 3);
    var entries = Loot_TableGet("chest");
    if (!is_array(entries) || array_length(entries) <= 0) return [];

    var candidates = [];
    var total_weight = 0;
    for (var i = 0; i < array_length(entries); i++) {
        var e = entries[i];
        if (!is_struct(e)) continue;
        if (!variable_struct_exists(e, "tier") || round(real(e.tier)) != tier) continue;
        if (!variable_struct_exists(e, "item_id")) continue;
        var item_id = round(real(e.item_id));
        if (item_id <= 0) continue;

        var w = variable_struct_exists(e, "weight") ? max(0, real(e.weight)) : 0;
        if (w <= 0) continue;

        array_push(candidates, e);
        total_weight += w;
    }

    if (array_length(candidates) <= 0 || total_weight <= 0) return [];

    var pick = candidates[0];
    var roll = random(total_weight);
    var acc = 0;
    for (var j = 0; j < array_length(candidates); j++) {
        var c = candidates[j];
        var cw = variable_struct_exists(c, "weight") ? max(0, real(c.weight)) : 0;
        acc += cw;
        if (roll <= acc) {
            pick = c;
            break;
        }
    }

    var pid = round(real(pick.item_id));
    if (pid <= 0) return [];

    var minv = 1;
    var maxv = 1;
    if (variable_struct_exists(pick, "qty_min")) minv = pick.qty_min;
    else if (variable_struct_exists(pick, "min_qty")) minv = pick.min_qty;
    else if (variable_struct_exists(pick, "min")) minv = pick.min;

    if (variable_struct_exists(pick, "qty_max")) maxv = pick.qty_max;
    else if (variable_struct_exists(pick, "max_qty")) maxv = pick.max_qty;
    else if (variable_struct_exists(pick, "max")) maxv = pick.max;

    minv = max(1, round(real(minv)));
    maxv = max(minv, round(real(maxv)));
    var qty = (minv == maxv) ? minv : irandom_range(minv, maxv);
    qty = max(1, qty);

    return [{ item_id: pid, qty: qty }];
}

function GraveLoot_RollRewardForStage(_stage, _class_id) {
    var st = clamp(round(real(_stage)), 0, 4);
    if (st <= 1) return GraveLoot_RollTierItem(2);
    if (st <= 3) return GraveLoot_RollTierItem(3);

    var class_id = round(real(_class_id));
    if (class_id != CLASS_NOBODY) {
        var sb = Loot_RollSkillbook(class_id);
        if (is_struct(sb) && variable_struct_exists(sb, "item_id")) return [sb];
    }

    // Nobody class (or no valid skillbook): fallback to another Lv3 item.
    return GraveLoot_RollTierItem(3);
}

function GraveLoot_TryRollReward(_class_id) {
    var stage_before = GraveLoot_GetStage();
    var chance = GraveLoot_StageChance(stage_before);
    if (random(1) > chance) {
        return {
            awarded: false,
            loot: [],
            stage_before: stage_before,
            stage_after: stage_before,
            chance: chance
        };
    }

    var loot = GraveLoot_RollRewardForStage(stage_before, _class_id);
    if (!is_array(loot) || array_length(loot) <= 0) {
        return {
            awarded: false,
            loot: [],
            stage_before: stage_before,
            stage_after: stage_before,
            chance: chance
        };
    }

    var stage_after = stage_before;
    if (stage_after < 4) stage_after += 1;
    GraveLoot_SetStage(stage_after);

    return {
        awarded: true,
        loot: loot,
        stage_before: stage_before,
        stage_after: stage_after,
        chance: chance
    };
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
    var interact_key = "interact.name." + string_lower(object_get_name(_inst.object_index));
    name = Loc_T(interact_key, name);

    var has_dialogue_id = false;
    var base_id = "default";
    if (variable_instance_exists(_inst, "dialogue_id")) {
        var did = _inst.dialogue_id;
        if (did != -1 && did != "") {
            base_id = did;
            has_dialogue_id = true;
        }
    }
    if (!has_dialogue_id && _inst.interact_kind == INTERACT_DIALOGUE && variable_instance_exists(_inst, "dialogue_profile_id")) {
        base_id = _inst.dialogue_profile_id;
        has_dialogue_id = true;
    }

    var after_id = "";
    if (variable_instance_exists(_inst, "dialogue_id_after")) {
        var aid = _inst.dialogue_id_after;
        if (aid != -1 && aid != "") {
            after_id = aid;
        }
    }

    // Special chest that opens class-select popup (used in rm_floor1).
    if (variable_instance_exists(_inst, "class_select_chest") && _inst.class_select_chest) {
        if (variable_instance_exists(_inst, "swap_on_interact") && _inst.swap_on_interact && !_inst.swapped) {
            if (variable_instance_exists(_inst, "swap_sprite") && _inst.swap_sprite != noone) {
                _inst.sprite_index = _inst.swap_sprite;
            }
            _inst.swapped = true;
            RoomState_SaveInstance(_inst, ["swapped","sprite_index"], false);
            SFX_Play("chest_open");
        }

        var current_class = CLASS_NOBODY;
        if (is_struct(gs.player_ch) && variable_struct_exists(gs.player_ch, "class_id")) {
            current_class = gs.player_ch.class_id;
        }

        if (current_class == CLASS_NOBODY) {
            Dialogue_StartWithSpeaker(name, DialogueDB_Get("sys_class_chest_prompt"));
            gs.pending_class_select_open = true;
            gs.pending_class_select_block_frame = Input_Frame() + 1;
        } else {
            Dialogue_StartWithSpeaker(name, DialogueDB_Get("chest_empty"));
        }

        GameState_SyncLegacy();
        return;
    }

    // Grave interaction: random text + optional ghost easter egg spawn.
    if (variable_instance_exists(_inst, "grave_interactable") && _inst.grave_interactable) {
        var grave_line = Loc_T("interact.grave.default", "An old grave rests here.");
        if (variable_instance_exists(_inst, "grave_lines") && is_array(_inst.grave_lines) && array_length(_inst.grave_lines) > 0) {
            var grave_pick = _inst.grave_lines[irandom(array_length(_inst.grave_lines) - 1)];
            if (is_struct(grave_pick)) {
                var line_key = variable_struct_exists(grave_pick, "key") ? string(grave_pick.key) : "";
                var line_fallback = variable_struct_exists(grave_pick, "text") ? string(grave_pick.text) : "";
                if (line_key != "") {
                    grave_line = Loc_T(line_key, line_fallback);
                    // Guard against corrupted localization rows that return key-like text.
                    if (grave_line == line_key || string_pos(".grave.line.obj_grave.", grave_line) > 0) {
                        grave_line = line_fallback;
                    }
                } else if (line_fallback != "") {
                    grave_line = line_fallback;
                }
            } else {
                grave_line = string(grave_pick);
            }
        }
        if (grave_line == "") grave_line = "An old grave rests here.";
        var grave_dialogue_lines = [grave_line];

        var class_id = CLASS_NOBODY;
        if (is_struct(gs.player_ch) && variable_struct_exists(gs.player_ch, "class_id")) {
            class_id = gs.player_ch.class_id;
        }

        var grave_reward = GraveLoot_TryRollReward(class_id);
        if (is_struct(grave_reward) && variable_struct_exists(grave_reward, "awarded") && grave_reward.awarded) {
            var reward_loot = variable_struct_exists(grave_reward, "loot") ? grave_reward.loot : [];
            if (is_array(reward_loot) && array_length(reward_loot) > 0 && is_struct(gs.player_ch) && variable_struct_exists(gs.player_ch, "inventory")) {
                gs.player_ch.inventory = Loot_Grant(gs.player_ch.inventory, reward_loot);

                for (var li = 0; li < array_length(reward_loot); li++) {
                    var rit = reward_loot[li];
                    if (!is_struct(rit) || !variable_struct_exists(rit, "item_id")) continue;
                    var rqty = variable_struct_exists(rit, "qty") ? max(1, round(real(rit.qty))) : 1;
                    var ritem = ItemDB_Get(rit.item_id);
                    if (!is_struct(ritem)) continue;
                    var gain_lines = DialogueDB_GetFormatted("loot_received", { item: ritem.name, qty: rqty });
                    for (var gi = 0; gi < array_length(gain_lines); gi++) {
                        array_push(grave_dialogue_lines, gain_lines[gi]);
                    }
                }
            }
        }

        Dialogue_StartWithSpeaker(name, grave_dialogue_lines);

        var ghost_chance = 0.15;
        if (variable_instance_exists(_inst, "ghost_spawn_chance")) {
            ghost_chance = clamp(real(_inst.ghost_spawn_chance), 0, 1);
        }

        if (random(1) < ghost_chance) {
            var marker = noone;
            var marker_id = "";
            if (variable_instance_exists(_inst, "ghost_marker_id")) {
                marker_id = string(_inst.ghost_marker_id);
            }

            if (marker_id != "") {
                var marker_count = instance_number(obj_marker);
                for (var marker_i = 0; marker_i < marker_count; marker_i++) {
                    var marker_inst = instance_find(obj_marker, marker_i);
                    if (instance_exists(marker_inst) && variable_instance_exists(marker_inst, "marker_id")) {
                        if (string(marker_inst.marker_id) == marker_id) {
                            marker = marker_inst;
                            break;
                        }
                    }
                }
            }

            if (marker == noone) {
                marker = instance_nearest(_inst.x, _inst.y, obj_marker);
            }

            if (marker != noone) {
                var layer_name = layer_get_name(_inst.layer);
                if (layer_name == "") layer_name = "Instances";
                var ghost = instance_create_layer(marker.x, marker.y, layer_name, obj_ghost_easter_egg_temp);
                if (variable_instance_exists(_inst, "ghost_duration_frames")) {
                    ghost.life_frames = max(1, round(real(_inst.ghost_duration_frames)));
                }
            }
        }

        GameState_SyncLegacy();
        return;
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
                Transition_RequestRoomFade(_inst.door_room);
            }
        } break;

        case INTERACT_CHECKPOINT: {
            GameState_SetCheckpoint(room, _inst.x, _inst.y);
            if (variable_instance_exists(_inst, "is_bed") && _inst.is_bed) {
                BedMenu_Open();
            }
        } break;
    }

    GameState_SyncLegacy();
}
