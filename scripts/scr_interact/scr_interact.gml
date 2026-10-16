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

    // D108 F1d-3: ask the faced tile once instead of testing every interactable in the room. The tile point is the one Interact_FacingDistance uses.
    // One hit (the usual case) is the answer; no hit means no target. Only when several interactables overlap the tile do we run the old loop, which
    // picks the first one in instance order, so the tie-break is exactly what it was.
    var INF = 1000000000;
    var best = noone;
    var best_dist = INF;
    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = _pl.tile_size;
    var tx = round(_pl.x / tile) * tile;
    var ty = round(_pl.y / tile) * tile;
    var resolved = true;
    switch (_pl.face) {
        case UP:    ty -= tile; break;
        case DOWN:  ty += tile; break;
        case LEFT:  tx -= tile; break;
        case RIGHT: tx += tile; break;
        default:    resolved = false; break;   // a face we cannot read: no target, like the old loop (every distance INF)
    }
    if (resolved) {
        var cx = tx + (tile * 0.5);
        var cy = ty + (tile * 0.5);
        var first = noone;
        with (_pl) {
            first = instance_position(cx, cy, obj_interactable);
        }
        if (first != noone) {
            static overlap = ds_list_create();
            ds_list_clear(overlap);
            var n_hit = 0;
            with (_pl) {
                n_hit = instance_position_list(cx, cy, obj_interactable, overlap, false);
            }
            if (n_hit <= 1) {
                with (first) {
                    best = self;   // the same kind of reference the old loop returned: Interact_Handle compares it with its own "self"
                }
                best_dist = tile;
            } else {
                with (obj_interactable) {
                    var d = Interact_FacingDistance(_pl, self);
                    if (d < best_dist) {
                        best_dist = d;
                        best = self;
                    }
                }
            }
            ds_list_clear(overlap);
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
        default: return 0.01; // Lv3 item (skill books are gone, D18)
    }
}

function GraveLoot_RollTierItem(_tier, _class_id = CLASS_NOBODY, _player = undefined) {
    var tier = clamp(round(real(_tier)), 1, 3);
    var entries = Loot_TableGet("chest");
    if (!is_array(entries) || array_length(entries) <= 0) return [];

    var class_id = round(real(_class_id));
    var player = Loot_PlayerStruct(_player);

    var candidates = [];
    var total_weight = 0;
    for (var i = 0; i < array_length(entries); i++) {
        var e = entries[i];
        if (!is_struct(e)) continue;
        if (!variable_struct_exists(e, "tier") || round(real(e.tier)) != tier) continue;
        if (!variable_struct_exists(e, "item_id")) continue;
        var item_id = round(real(e.item_id));
        if (item_id <= 0) continue;
        if (!Loot_ItemEligibleForPlayer(item_id, player, class_id, [])) continue;

        var w = variable_struct_exists(e, "weight") ? max(0, real(e.weight)) : 0;
        if (w <= 0) continue;

        array_push(candidates, e);
        total_weight += w;
    }

    if (array_length(candidates) <= 0 || total_weight <= 0) return [];

    var pick = candidates[0];
    var roll = RunRng_Float("loot") * total_weight;
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
    var qty = (minv == maxv) ? minv : RunRng_Range("loot", minv, maxv);
    qty = max(1, qty);

    return [{ item_id: pid, qty: qty }];
}

function GraveLoot_RollRewardForStage(_stage, _class_id) {
    var st = clamp(round(real(_stage)), 0, 4);
    var player = Loot_PlayerStruct();
    var class_id = round(real(_class_id));
    if (st <= 1) return GraveLoot_RollTierItem(2, class_id, player);
    if (st <= 3) return GraveLoot_RollTierItem(3, class_id, player);

    // The last stage gives another Lv3 item.
    return GraveLoot_RollTierItem(3, class_id, player);
}

function GraveLoot_TryRollReward(_class_id) {
    var stage_before = GraveLoot_GetStage();
    var chance = GraveLoot_StageChance(stage_before);
    if (RunRng_Float("loot") > chance) {
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



// Bound to the shop's index by Interact_Handle (method).
function Interact_MerchantOpen() {
    ShopUi_Open(shop);
    GameState_SyncLegacy();
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

    // C3 (D85): the merchant (an obj_npc placed by Merchant_EnsureInRoom) opens the shop instead of a dialogue
    // D154: the first time, he asks his question first (a box, 2 replies); the shop opens when his answer is read
    if (variable_instance_exists(_inst, "merchant") && _inst.merchant) {
        Choice_Run("merchant", method({ shop: _inst.shop_index }, Interact_MerchantOpen));
        GameState_SyncLegacy();
        return;
    }

    // Class chest and skill chest (D73, fixes I-057): the first one opened in a run gives the class choice, every later one a 1-of-3 card
    // pick. The choice or pick is owed by the character and opens as a screen (CardsUi_Step) once the chest's line is read.
    if ((variable_instance_exists(_inst, "class_select_chest") && _inst.class_select_chest) || (variable_instance_exists(_inst, "card_chest") && _inst.card_chest)) {
        if (!_inst.swapped) {
            if (variable_instance_exists(_inst, "swap_sprite") && _inst.swap_sprite != noone) {
                _inst.sprite_index = _inst.swap_sprite;
            }
            _inst.swapped = true;
            RoomState_SaveInstance(_inst, ["swapped","sprite_index"], false);
            SFX_Play("chest_open");
            MapFx_OpenedAt(_inst, [], true);   // D138 (G6): the burst and a small card rising out
            if (is_struct(gs.player_ch)) GameState_SetPlayer(Cards_ChestOpened(gs.player_ch));
            if (instance_exists(obj_player)) obj_player.character = gs.player_ch;
            Dialogue_StartWithSpeaker(name, DialogueDB_Get("chest_open"));
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
        if (grave_line == "") grave_line = Loc_T("interact.grave.default", "An old grave rests here.");
        var grave_dialogue_lines = [grave_line];

        var class_id = CLASS_NOBODY;
        if (is_struct(gs.player_ch) && variable_struct_exists(gs.player_ch, "class_id")) {
            class_id = gs.player_ch.class_id;
        }

        Grave_MarkSearched(_inst);   // D195 (R-133): the gold outline goes out with the first search, and stays out (room state)
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
                    var gain_lines = Loot_ReceivedLines(ritem.id, rqty);   // D178: the name in its rarity colour
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
                if (key != "") {
                    if (Run_IsActive() && RoomState_EnsurePersistId(_inst)) loot = Shuffle_ChestLoot(Run_Get().seed, room_get_name(room), _inst.persist_id, lvl, key, gs.player_ch);   // C3 (D33): contents come from the seed and this chest
                    else loot = Loot_RollContainer(lvl, key);
                }
                if (is_chest && Trap_IsTrapped(_inst)) {   // R3 ideas2 (D173, IDEA-03): the one trapped chest of the floor
                    Trap_Opened(_inst, name, loot, gs);   // the item goes into the bag at once (D118); the bar decides the bonus and the cost
                    GameState_SyncLegacy();
                    return;
                }
                MapFx_OpenedAt(_inst, loot, false);   // D138 (G6): the burst, and the first thing found rises out (display only: the rewards below are unchanged)
                if (is_array(loot) && array_length(loot) > 0) {
                    gs.player_ch.inventory = Loot_Grant(gs.player_ch.inventory, loot);

                    var loot_lines = [];
                    for (var i = 0; i < array_length(loot); i++) {
                        var it = loot[i];
                        var qty = it.qty;
                        var lines = Loot_ReceivedLines(it.item_id, qty);   // D178: the name in its rarity colour
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
                BedUi_Open(_inst);   // D46 / D47: a rest site, once per run per bed (heal, or upgrade one skill)
            }
        } break;
    }

    GameState_SyncLegacy();
}

// ============================================================================
// R3 ideas2 (D173, D185; IDEA-03): trapped chests. From floor 2 on, exactly one loot chest of each floor is trapped, picked from the run's seed and the floor's chests (the same seed
// gives the same chest; the pick is a pure function of the seed and the chests' ids, so a Continue picks it again; opened chests stay in the draw so opening one never moves the
// trap). Opening it rattles, says "It's trapped!", then runs ONE press of the sliding bar of a sword attack (D60: the grades mean what they mean in a fight) over the paused map.
// Perfect: the chest's item and a bonus Common consumable. Good / OK: the item. Weak: the item and the loss of 15% of Max HP (rounded up) that never takes the last HP.
// The chest always gives its item (D118): it goes into the bag when the chest opens; the bar only decides the bonus and the cost.
// The agent's numbers (D185), all here: TRAP_FIRST_FLOOR 2, TRAP_HURT_PCT 15, the "default" bar (1100 ms sweep, zones 60 / 120 / 200), TRAP_RATTLE_MS 300, one bonus: a Common potion or cure.
// ============================================================================
#macro TRAP_FIRST_FLOOR 2        // the first floor with a trapped chest
#macro TRAP_HURT_PCT 15          // a Weak press costs this share of Max HP, rounded up, and never the last HP
#macro TRAP_BAR_KIND "default"   // the sliding bar of a sword attack
#macro TRAP_RATTLE_MS 300        // the rattle's camera shake (the Screen shake setting turns it off)

// The id of the trapped chest of a floor ("" when the floor has none): _pids are the persist ids of the floor's loot chests, opened or not.
function Trap_PickPid(_seed, _room_name, _pids) {
    if (Run_FloorOfRoomName(_room_name) < TRAP_FIRST_FLOOR) return "";
    var n = array_length(_pids);
    if (n <= 0) return "";
    var sorted = array_create(n, "");
    for (var i = 0; i < n; i++) sorted[i] = string(_pids[i]);
    array_sort(sorted, true);   // the order the chests were found in must not matter
    return sorted[Rng_Int(Rng_New(_seed, "trap_room_" + string(_room_name)), n)];
}

// The persist ids of this room's loot chests (barrels, the skill chest and the class chest are not loot chests), sorted. Opened chests are in it too.
function Trap_ChestPids() {
    var out = [];
    with (obj_chest) {
        if (!variable_instance_exists(id, "is_container") || !is_container) continue;
        if (!RoomState_EnsurePersistId(id)) continue;
        array_push(out, string(persist_id));
    }
    array_sort(out, true);
    return out;
}

// Is this chest the trapped one? _seed and _room_name default to the run's seed and the current room (the tests give their own).
function Trap_IsTrapped(_inst, _seed = undefined, _room_name = undefined) {
    if (!instance_exists(_inst)) return false;
    if (!(_inst.object_index == obj_chest || object_is_ancestor(_inst.object_index, obj_chest))) return false;
    if (!variable_instance_exists(_inst, "is_container") || !_inst.is_container) return false;
    if (is_undefined(_seed)) {
        if (!Run_IsActive()) return false;
        _seed = Run_Get().seed;
    }
    if (is_undefined(_room_name)) _room_name = room_get_name(room);
    if (!RoomState_EnsurePersistId(_inst)) return false;
    return Trap_PickPid(_seed, _room_name, Trap_ChestPids()) == string(_inst.persist_id);
}

// HP a Weak press takes: 15% of Max HP rounded up (integer arithmetic: no float error at 20 or 100), never more than leaves 1 HP, never negative.
function Trap_Loss(_hp, _max_hp) {
    var want = (max(0, _max_hp) * TRAP_HURT_PCT + 99) div 100;
    return max(0, min(want, _hp - 1));
}

// What a grade does: { bonus, hurt }.
function Trap_Outcome(_key) {
    return { bonus: (_key == QTE_PERFECT), hurt: (_key == QTE_WEAK) };
}

// The bonus of a Perfect: one Common (tier 1) consumable, from the seed, this room and this chest. [{ item_id, qty }]
function Trap_BonusLoot(_seed, _room_name, _pid) {
    var pool = [10, 11, 12, 13];   // HP Potion, MP Potion, Antidote, Bandage: the tier 1 consumables of the chest table
    var rng = Rng_New(_seed, "trap_bonus_" + string(_room_name) + "_" + string(_pid));
    return [{ item_id: Rng_Pick(rng, pool), qty: 1 }];
}

// A grade applied to a character (a changed copy): Perfect adds the bonus, Weak takes the HP. { ch, lost, bonus }
function Trap_Apply(_ch, _key, _bonus) {
    var ch = variable_clone(_ch);
    var o = Trap_Outcome(_key);
    var res = { ch: ch, lost: 0, bonus: [] };
    if (o.bonus && is_array(_bonus) && array_length(_bonus) > 0) {
        ch.inventory = Loot_Grant(ch.inventory, _bonus);
        res.bonus = _bonus;
    }
    if (o.hurt) {
        res.lost = Trap_Loss(ch.hp, ch.max_hp);
        ch.hp -= res.lost;
    }
    return res;
}

function Trap_BarParams() {
    return Qte_BarParams(TRAP_BAR_KIND);
}

// The grade of a press at _press_ms (QTE_NO_PRESS = none): the combat bar's own grading.
function Trap_Grade(_press_ms, _assist = 1) {
    return Qte_Result(Qte_Grade(_press_ms, Trap_BarParams(), _assist)).key;
}

// ---- the screen: global.trap_ui = { ctx, phase ("wait" for the chest's line to be read, "bar", "done"), ms (the bar's clock, -QTE_LEAD_IN_MS first), params, assist, key, press_ms, opened_ms } ----
function TrapUi_IsOpen() {
    return variable_global_exists("trap_ui") && is_struct(global.trap_ui);
}

function TrapUi_New(_ctx) {
    return { ctx: _ctx, phase: "wait", ms: -QTE_LEAD_IN_MS, params: Trap_BarParams(), assist: Qte_AssistMult(), key: "", press_ms: QTE_NO_PRESS, opened_ms: current_time };
}

// _ctx = { name, lines (what the chest gave, said after the result), loot, bonus ([{ item_id, qty }] of a Perfect), pid, inst }
function TrapUi_Open(_ctx) {
    global.trap_ui = TrapUi_New(_ctx);
}

// The bar's clock is the QTE clock: a window out of front adds nothing (D122) and a hitch never skips the bar.
function TrapUi_StepMs(_delta_us) {
    return Qte_StepMs(_delta_us);
}

// The whole model of one frame. _free: nothing else owns the screen (the chest's line has been read). Returns the grade key on the frame it is decided, else "".
// One press, one result: the first press the sweep keeps ends it (a press more than 80 ms before the sweep starts is the one that closed the line and is dropped).
function TrapUi_Update(_u, _step_ms, _pressed, _free) {
    if (_u.phase == "wait") {
        if (_free) {
            _u.phase = "bar";
            _u.opened_ms = current_time;
        }
        return "";
    }
    if (_u.phase != "bar") return "";
    _u.ms += _step_ms;
    if (_pressed) {
        var pm = Qte_BufferPress(_u.ms);
        if (pm != QTE_NO_PRESS) {
            _u.press_ms = pm;
            _u.key = Trap_Grade(pm, _u.assist);
            _u.phase = "done";
            return _u.key;
        }
    }
    if (_u.ms >= _u.params.sweep_ms) {   // the cursor reached the end with no press
        _u.key = Trap_Grade(QTE_NO_PRESS, _u.assist);
        _u.phase = "done";
        return _u.key;
    }
    return "";
}

// The chest was opened and it is the trapped one: rattle, the item into the bag at once, the line "It's trapped!"; the bar follows when the line is read.
function Trap_Opened(_inst, _name, _loot, _gs) {
    var lines = [];
    if (is_array(_loot) && array_length(_loot) > 0) {
        _gs.player_ch.inventory = Loot_Grant(_gs.player_ch.inventory, _loot);
        for (var i = 0; i < array_length(_loot); i++) {
            var rl = Loot_ReceivedLines(_loot[i].item_id, _loot[i].qty);   // D178: the name in its rarity colour
            for (var j = 0; j < array_length(rl); j++) array_push(lines, rl[j]);
        }
    } else {
        lines = DialogueDB_Get("loot_empty");
    }
    var pid = variable_instance_exists(_inst, "persist_id") ? string(_inst.persist_id) : "";
    var seed = Run_IsActive() ? Run_Get().seed : 0;
    SFX_Play("metal_resonance");   // the rattle
    CameraShake_Start(QTE_SHAKE_PERFECT_MAG, TRAP_RATTLE_MS, SHAKE_DIR_H);
    MapFx_OpenedAt(_inst, _loot, false);   // D138: the chest's burst and the item rising out are at the opening, as for any chest (the item is already in the bag)
    TrapUi_Open({ name: _name, lines: lines, loot: _loot, bonus: Trap_BonusLoot(seed, room_get_name(room), pid), pid: pid, inst: _inst });
    Dialogue_StartWithSpeaker(_name, [Loc_T("trap.line.trapped", "It's trapped!")]);
}

// The result: the grade's sound, the bonus or the cost, then the dialogue says what happened and what the chest gave. global.trap_result keeps the last one for the scripts.
function TrapUi_Finish(_u, _key) {
    var gs = GameState_Get();
    var ctx = _u.ctx;
    global.trap_ui = undefined;
    if (gs.ui.mode == UI_TRAP) gs.ui.mode = UI_NONE;
    var r = Trap_Apply(gs.player_ch, _key, ctx.bonus);
    gs.player_ch.inventory = r.ch.inventory;   // in place, like every chest reward: the character struct the player object holds stays the same one
    gs.player_ch.hp = r.ch.hp;
    global.trap_result = { key: _key, lost: r.lost, bonus: r.bonus, pid: ctx.pid };
    SFX_Play(Qte_GradeSfxKey(_key));
    if (r.lost > 0) CameraShake_Start(QTE_SHAKE_PERFECT_MAG, QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
    var lines = [];
    switch (_key) {
        case QTE_PERFECT: array_push(lines, Loc_T("trap.result.perfect", "Perfect! You disarm the trap and find a bonus item.")); break;
        case QTE_WEAK:
            if (r.lost > 0) array_push(lines, Loc_T("trap.result.weak", "The trap snaps! You lose {hp} HP.", { hp: r.lost }));
            else array_push(lines, Loc_T("trap.result.weak_none", "The trap snaps, but you barely feel it."));
            break;
        default: array_push(lines, Loc_T("trap.result.fine", "The trap clicks harmlessly.")); break;
    }
    if (is_array(ctx.lines)) for (var i = 0; i < array_length(ctx.lines); i++) array_push(lines, ctx.lines[i]);
    for (var b = 0; b < array_length(r.bonus); b++) {
        var bl = Loot_ReceivedLines(r.bonus[b].item_id, r.bonus[b].qty);
        for (var j = 0; j < array_length(bl); j++) array_push(lines, bl[j]);
    }
    Dialogue_StartWithSpeaker(ctx.name, lines);
}

// The live step (obj_ui_controller): true when the screen takes this frame. It waits behind the chest's line, then pauses the map (UI_TRAP) and runs the bar.
function TrapUi_Step() {
    if (!TrapUi_IsOpen()) return false;
    var u = global.trap_ui;
    var gs = GameState_Get();
    if (u.phase == "wait") {
        if (gs.ui.mode != UI_NONE || array_length(gs.ui.lines) > 0 || Transition_IsActive()) return false;
        TrapUi_Update(u, 0, false, true);
        gs.ui.mode = UI_TRAP;
        SFX_PlayUI("ui_openclose");
        Tutorial_Trigger("trap");   // the first trapped chest of a profile: the clock waits behind the pop-up (this controller exits for it before it gets here)
        return true;
    }
    if (u.phase != "bar") {
        global.trap_ui = undefined;
        if (gs.ui.mode == UI_TRAP) gs.ui.mode = UI_NONE;
        return false;
    }
    var key = TrapUi_Update(u, TrapUi_StepMs(delta_time), Battle_ConfirmInput(), true);
    if (key != "") TrapUi_Finish(u, key);
    return true;
}

// A room change, a forced close of every screen: the bar ends with no cost and no bonus (the chest's item was given when it opened; the chest stays open).
function TrapUi_Interrupt() {
    if (!TrapUi_IsOpen()) return;
    global.trap_ui = undefined;
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "ui") && gs.ui.mode == UI_TRAP) gs.ui.mode = UI_NONE;
}

// Where the bar's plate sits: { x, y, w, h, ... } in GUI units, centred, in the upper part of the picture (the dialogue box is at the bottom, the chest is near the middle).
function TrapUi_Box() {
    var mt = Ui_Metrics();
    var p = mt.p;
    var sx = Display_WorldScale();
    var bar_w = round(QTE_BAR_W * sx);
    var bar_h = round(QTE_BAR_H * sx);
    var w = min(mt.gw - 2 * mt.margin, max(round(mt.gw * 0.8), bar_w + 10 * p));
    var h = 4 * p + mt.line_h + 3 * p + (bar_h + 14 * sx) + 4 * p;
    return { x: round((mt.gw - w) / 2), y: max(mt.margin, round(mt.gh * 0.22)), w: w, h: h, bar_w: bar_w, bar_h: bar_h, sx: sx, p: p, line_h: mt.line_h };
}

function TrapUi_Draw() {
    if (!TrapUi_IsOpen()) return;
    var u = global.trap_ui;
    if (u.phase != "bar") return;   // while the chest's line is read the dialogue owns the screen
    var b = TrapUi_Box();
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(UI_DIM_POPUP * 0.5 * a);
    Ui_DrawFrame(b.x, b.y, b.w, b.h, a, b.p);
    draw_set_alpha(a);
    var x0 = b.x + 4 * b.p;
    var ty = b.y + 4 * b.p;
    Prompt_RichDraw(x0, ty, Loc_T("trap.bar.prompt", "Disarm it! [k:confirm]"), b.w - 8 * b.p, UI_C_LIGHTEST, fa_left, a);
    ty += b.line_h + 3 * b.p;
    var bar_x = round(b.x + (b.w - b.bar_w) / 2);
    var bar_y = ty + round(8 * b.sx);   // room above the bar for the Perfect zone's pointer
    Qte_DrawBar(bar_x, bar_y, b.bar_w, b.bar_h, u.params, u.assist, u.ms, b.sx, min(a, clamp((u.ms + QTE_LEAD_IN_MS) / 100, 0, 1)));
    draw_set_alpha(1);
    draw_set_color(c_white);
}
