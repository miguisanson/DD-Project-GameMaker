function RoomState_Key(_room, _persist_id) {
    return room_get_name(_room) + ":" + _persist_id;
}

function RoomState_Init() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "persist")) gs.persist = {};
    if (!variable_struct_exists(gs, "persist_applied")) gs.persist_applied = {};
    global.room_state_ready = true;
}

function RoomState_Warn(_msg) {
    if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
        var gs = GameState_Get();
        if (!variable_struct_exists(gs, "ui")) gs.ui = {};
        if (!variable_struct_exists(gs.ui, "debug_warns")) gs.ui.debug_warns = [];
        array_push(gs.ui.debug_warns, _msg);
        show_debug_message(_msg);
    }
}

function EnemyPersist_IsBossEnemyId(_enemy_id) {
    return (_enemy_id == ENEMY_MINI_BOSS || _enemy_id == ENEMY_FINAL_BOSS);
}

function EnemyPersist_EnsureBossFlags() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "boss_defeated") || !is_struct(gs.boss_defeated)) {
        gs.boss_defeated = { mini_boss: false, final_boss: false };
    }
    return gs.boss_defeated;
}

function EnemyPersist_SetBossDefeated(_enemy_id, _defeated = true) {
    var flags = EnemyPersist_EnsureBossFlags();
    if (_enemy_id == ENEMY_MINI_BOSS) flags.mini_boss = _defeated;
    if (_enemy_id == ENEMY_FINAL_BOSS) flags.final_boss = _defeated;
}

function EnemyPersist_IsBossDefeated(_enemy_id) {
    if (!EnemyPersist_IsBossEnemyId(_enemy_id)) return false;
    var flags = EnemyPersist_EnsureBossFlags();
    if (_enemy_id == ENEMY_MINI_BOSS) return (variable_struct_exists(flags, "mini_boss") && flags.mini_boss);
    if (_enemy_id == ENEMY_FINAL_BOSS) return (variable_struct_exists(flags, "final_boss") && flags.final_boss);
    return false;
}

function RoomState_EnsurePersistId(_inst) {
    if (!instance_exists(_inst)) return false;
    if (!variable_instance_exists(_inst, "persist_id")) return false;
    if (_inst.persist_id != "") return true;

    // Deterministic fallback for room-placed instances that forgot to set persist_id.
    var sx = _inst.x;
    var sy = _inst.y;
    if (variable_instance_exists(_inst, "xstart")) sx = _inst.xstart;
    if (variable_instance_exists(_inst, "ystart")) sy = _inst.ystart;

    var base = "auto:" + room_get_name(room) + ":" + object_get_name(_inst.object_index) + ":" + string(round(sx)) + ":" + string(round(sy));
    var duplicate_index = 1;
    var obj = _inst.object_index;
    var n = instance_number(obj);
    for (var i = 0; i < n; i++) {
        var other_inst = instance_find(obj, i);
        if (other_inst == _inst) continue;
        if (!variable_instance_exists(other_inst, "persist_id")) continue;
        var pid = other_inst.persist_id;
        if (pid == "") continue;
        if (string_pos(base + "#", pid) == 1) duplicate_index += 1;
    }

    _inst.persist_id = base + "#" + string(duplicate_index);
    return (_inst.persist_id != "");
}

function RoomState_Set(_room, _persist_id, _data) {
    RoomState_Init();
    if (_persist_id == "") return;
    var gs = GameState_Get();
    var key = RoomState_Key(_room, _persist_id);
    variable_struct_set(gs.persist, key, _data);
}

function RoomState_Get(_room, _persist_id) {
    RoomState_Init();
    if (_persist_id == "") return undefined;
    var gs = GameState_Get();
    var key = RoomState_Key(_room, _persist_id);
    if (!variable_struct_exists(gs.persist, key)) return undefined;
    return variable_struct_get(gs.persist, key);
}

function RoomState_ClearApplied(_room) {
    RoomState_Init();
    var gs = GameState_Get();
    var rname = room_get_name(_room);
    variable_struct_set(gs.persist_applied, rname, false);
}

function RoomState_SaveInstance(_inst, _vars, _removed) {
    RoomState_Init();
    if (!RoomState_EnsurePersistId(_inst)) {
        RoomState_Warn("[Persist] Missing persist_id on " + object_get_name(_inst.object_index) + " in " + room_get_name(room));
        return;
    }
    var data = { removed: _removed, vars: {} };
    for (var i = 0; i < array_length(_vars); i++) {
        var v = _vars[i];
        if (variable_instance_exists(_inst, v)) {
            variable_struct_set(data.vars, v, variable_instance_get(_inst, v));
        }
    }
    RoomState_Set(room, _inst.persist_id, data);
}

function RoomState_SetRemoved(_room, _persist_id, _obj_type = noone, _enemy_id = -1) {
    RoomState_Init();
    if (_persist_id == "") return;
    var gs = GameState_Get();
    var data = { removed: true, vars: {} };
    if (_obj_type == obj_enemy) {
        data.removed_reset_version = gs.enemy_reset_version;
        if (_enemy_id != -1) data.enemy_id = _enemy_id;
    }
    RoomState_Set(_room, _persist_id, data);
}

function RoomState_SetAlive(_room, _persist_id) {
    RoomState_Init();
    if (_persist_id == "") return;

    var data = RoomState_Get(_room, _persist_id);
    if (!is_struct(data)) data = { removed: false, vars: {} };
    data.removed = false;
    if (!variable_struct_exists(data, "vars")) data.vars = {};
    RoomState_Set(_room, _persist_id, data);
}

function RoomState_ApplyInstance(_inst) {
    if (!RoomState_EnsurePersistId(_inst)) {
        RoomState_Warn("[Persist] Missing persist_id on " + object_get_name(_inst.object_index) + " in " + room_get_name(room));
        return;
    }

    if (_inst.object_index == obj_enemy && variable_instance_exists(_inst, "enemy_id")) {
        if (EnemyPersist_IsBossDefeated(_inst.enemy_id)) {
            instance_destroy(_inst);
            return;
        }
    }

    var data = RoomState_Get(room, _inst.persist_id);
    if (!is_struct(data)) return;
    if (variable_struct_exists(data, "removed") && data.removed) {
        if (_inst.object_index == obj_enemy) {
            var gs = GameState_Get();
            var rv = 0;
            if (variable_struct_exists(data, "removed_reset_version")) rv = data.removed_reset_version;
            if (rv < gs.enemy_reset_version) {
                return; // allow respawn after reset
            }
        }
        instance_destroy(_inst);
        return;
    }
    if (variable_struct_exists(data, "vars")) {
        var names = variable_struct_get_names(data.vars);
        for (var i = 0; i < array_length(names); i++) {
            var n = names[i];
            variable_instance_set(_inst, n, variable_struct_get(data.vars, n));
        }
    }
}

function RoomState_Save(_room) {
    RoomState_Init();
    if (_room != room) return;
    if (_room == rm_battle) return;

    // Enemy positions are the single source of truth for overworld battle return.
    with (obj_enemy) {
        RoomState_SaveInstance(id, ["x", "y", "enemy_id", "enemy_uid"], false);
    }
}

function RoomState_OnRoomExit() {
    RoomState_Init();
    if (room == rm_battle) return;
    RoomState_Save(room);
}

function EnemyPersist_BeginEncounter(_enemy_inst, _player_inst) {
    if (!instance_exists(_enemy_inst) || !instance_exists(_player_inst)) return false;
    if (!variable_instance_exists(_enemy_inst, "enemy_id")) return false;
    if (!RoomState_EnsurePersistId(_enemy_inst)) return false;

    RoomState_OnRoomExit();
    GameState_SetBattleReturn(room, _player_inst.x, _player_inst.y, -1);
    GameState_SetBattleEnemy(_enemy_inst.persist_id, _enemy_inst.enemy_id);
    return true;
}

function EnemyPersist_ResolveBattle(_defeated) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "battle")) return;
    if (gs.battle.enemy_persist_id == "") return;

    if (_defeated) {
        if (EnemyPersist_IsBossEnemyId(gs.battle.enemy_id)) {
            EnemyPersist_SetBossDefeated(gs.battle.enemy_id, true);
        }
        RoomState_SetRemoved(gs.battle.enemy_room, gs.battle.enemy_persist_id, obj_enemy, gs.battle.enemy_id);
    } else {
        RoomState_SetAlive(gs.battle.enemy_room, gs.battle.enemy_persist_id);
    }
}

function RoomState_Apply(_room) {
    if (_room == rm_battle) return;
    RoomState_Init();
    var gs = GameState_Get();
    var rname = room_get_name(_room);
    if (variable_struct_exists(gs.persist_applied, rname) && variable_struct_get(gs.persist_applied, rname) == true) return;
    variable_struct_set(gs.persist_applied, rname, true);

    with (obj_enemy) RoomState_ApplyInstance(self);
    with (obj_interactable) RoomState_ApplyInstance(self);
    if (object_exists(obj_dialogue_trigger)) with (obj_dialogue_trigger) RoomState_ApplyInstance(self);
    if (object_exists(obj_item_pickup)) with (obj_item_pickup) RoomState_ApplyInstance(self);
}

function Enemy_ResetAll() {
    var gs = GameState_Get();
    gs.enemy_reset_version += 1;
}
