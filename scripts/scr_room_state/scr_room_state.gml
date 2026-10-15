function RoomState_Key(_room, _persist_id) {
    return room_get_name(_room) + ":" + _persist_id;
}

function RoomState_IsEnemyInstance(_inst) {
    if (!instance_exists(_inst)) return false;
    var obj = _inst.object_index;
    if (obj == obj_enemy) return true;
    return object_is_ancestor(obj, obj_enemy);
}

function RoomState_IsEnemyPersistData(_data) {
    if (!is_struct(_data)) return false;
    if (variable_struct_exists(_data, "enemy_id")) return true;
    if (variable_struct_exists(_data, "removed_reset_version")) return true;
    if (variable_struct_exists(_data, "vars") && is_struct(_data.vars) && variable_struct_exists(_data.vars, "enemy_id")) return true;
    return false;
}

function RoomState_SanitizeEnemyVars(_vars, _fallback_enemy_id = -1) {
    var out = {};
    if (is_struct(_vars)) {
        if (variable_struct_exists(_vars, "x")) out.x = _vars.x;
        if (variable_struct_exists(_vars, "y")) out.y = _vars.y;
        if (variable_struct_exists(_vars, "enemy_id")) out.enemy_id = _vars.enemy_id;
        if (variable_struct_exists(_vars, "enemy_uid")) out.enemy_uid = _vars.enemy_uid;
        if (variable_struct_exists(_vars, "enemy_level")) out.enemy_level = _vars.enemy_level;
        if (variable_struct_exists(_vars, "elite_mod")) out.elite_mod = _vars.elite_mod;   // C3 (D86)
        if (variable_struct_exists(_vars, "home_x")) out.home_x = _vars.home_x;   // D33, D63, D66: the dealt spot the enemy idles around and walks back to (an old save has none: the authored spot stays)
        if (variable_struct_exists(_vars, "home_y")) out.home_y = _vars.home_y;
    }
    if (!variable_struct_exists(out, "enemy_id") && _fallback_enemy_id != -1) {
        out.enemy_id = _fallback_enemy_id;
    }
    return out;
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
    var data = { removed: _removed, vars: {}, obj_name: object_get_name(_inst.object_index) };
    for (var i = 0; i < array_length(_vars); i++) {
        var v = _vars[i];
        if (variable_instance_exists(_inst, v)) {
            variable_struct_set(data.vars, v, variable_instance_get(_inst, v));
        }
    }
    if (RoomState_IsEnemyInstance(_inst) && variable_instance_exists(_inst, "enemy_id")) {
        data.enemy_id = _inst.enemy_id;
        data.vars = RoomState_SanitizeEnemyVars(data.vars, _inst.enemy_id);
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
        var run = Run_Get();   // C1: enemies defeated this run (run history, run save)
        if (is_struct(run) && run.active) run.kills += 1;
    }
    RoomState_Set(_room, _persist_id, data);
}

function RoomState_SetAlive(_room, _persist_id) {
    RoomState_Init();
    if (_persist_id == "") return;

    var data = RoomState_Get(_room, _persist_id);
    if (!is_struct(data)) {
        RoomState_Set(_room, _persist_id, { removed: false, vars: {} });
        return;
    }

    var vars_in = variable_struct_exists(data, "vars") ? data.vars : {};
    var enemy_id = -1;
    if (variable_struct_exists(data, "enemy_id")) enemy_id = data.enemy_id;
    else if (is_struct(vars_in) && variable_struct_exists(vars_in, "enemy_id")) enemy_id = vars_in.enemy_id;

    var alive = { removed: false, vars: vars_in };
    if (variable_struct_exists(data, "obj_name")) alive.obj_name = data.obj_name;

    var is_enemy = RoomState_IsEnemyPersistData(data);
    if (is_enemy) {
        alive.vars = RoomState_SanitizeEnemyVars(vars_in, enemy_id);
        if (enemy_id != -1) alive.enemy_id = enemy_id;
    } else if (!is_struct(alive.vars)) {
        alive.vars = {};
    }

    RoomState_Set(_room, _persist_id, alive);
}

function RoomState_ApplyInstance(_inst) {
    if (!RoomState_EnsurePersistId(_inst)) {
        RoomState_Warn("[Persist] Missing persist_id on " + object_get_name(_inst.object_index) + " in " + room_get_name(room));
        return;
    }

    if (RoomState_IsEnemyInstance(_inst) && variable_instance_exists(_inst, "enemy_id")) {
        if (EnemyPersist_IsBossDefeated(_inst.enemy_id)) {
            instance_destroy(_inst);
            return;
        }
    }

    var data = RoomState_Get(room, _inst.persist_id);
    if (!is_struct(data)) return;
    if (variable_struct_exists(data, "obj_name")) {
        var obj_name = string(data.obj_name);
        if (obj_name != "" && obj_name != object_get_name(_inst.object_index)) {
            return;
        }
    }
    if (variable_struct_exists(data, "removed") && data.removed) {
        if (RoomState_IsEnemyInstance(_inst)) {
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
    if (RoomState_IsEnemyInstance(_inst)) {
        if (variable_instance_exists(_inst, "defeated")) _inst.defeated = false;
        if (variable_instance_exists(_inst, "encounter_pending")) _inst.encounter_pending = false;
        if (variable_instance_exists(_inst, "encounter_player")) _inst.encounter_player = noone;
        if (variable_instance_exists(_inst, "moving")) _inst.moving = false;
        if (variable_instance_exists(_inst, "enemy_id") && _inst.enemy_id != -1 && !EnemyPersist_IsBossEnemyId(_inst.enemy_id)) Enemy_ReapplyConfig(_inst);   // C3: a shuffled type has its own sprite and AI
        Enemy_SnapToGrid(_inst);   // I-048: a snapshot taken mid-step must not restore between tiles
        if (variable_instance_exists(_inst, "move_timer")) _inst.move_timer = 0;
        if (variable_instance_exists(_inst, "move_dir")) _inst.move_dir = -1;
        if (variable_instance_exists(_inst, "cine_lock_count")) _inst.cine_lock_count = 0;
        if (variable_instance_exists(_inst, "cine_lock_owner")) _inst.cine_lock_owner = noone;
    }
}

function RoomState_Save(_room) {
    RoomState_Init();
    if (_room != room) return;
    if (_room == rm_battle) return;

    // Enemy positions are the single source of truth for overworld battle return.
    with (obj_enemy) {
        RoomState_SaveInstance(id, ["x", "y", "enemy_id", "enemy_uid", "enemy_level", "elite_mod", "home_x", "home_y"], false);
    }
}

function RoomState_OnRoomExit() {
    RoomState_Init();
    if (room == rm_battle) return;
    global.room_exit_count = (variable_global_exists("room_exit_count") ? global.room_exit_count : 0) + 1;   // I-049: counted so a scenario can prove an exit fires once per entry
    RoomState_Save(room);
}

function EnemyPersist_BeginEncounter(_enemy_inst, _player_inst) {
    if (!instance_exists(_enemy_inst) || !instance_exists(_player_inst)) return false;
    if (!variable_instance_exists(_enemy_inst, "enemy_id")) return false;
    if (!RoomState_EnsurePersistId(_enemy_inst)) return false;

    RoomState_OnRoomExit();
    GameState_SetBattleReturn(room, _player_inst.x, _player_inst.y, -1);
    var lvl = variable_instance_exists(_enemy_inst, "enemy_level") ? _enemy_inst.enemy_level : 0;
    GameState_SetBattleEnemy(_enemy_inst.persist_id, _enemy_inst.enemy_id, lvl);
    GameState_Get().battle.enemy_elite = variable_instance_exists(_enemy_inst, "elite_mod") ? _enemy_inst.elite_mod : "";   // C3 (D86)
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

    Shuffle_ApplyRoom();   // C3 (D33): this run's enemy layout, for the enemies the room has no saved state for
    with (obj_enemy) RoomState_ApplyInstance(self);
    with (obj_interactable) RoomState_ApplyInstance(self);
    if (object_exists(obj_dialogue_trigger)) with (obj_dialogue_trigger) RoomState_ApplyInstance(self);
    if (object_exists(obj_item_pickup)) with (obj_item_pickup) RoomState_ApplyInstance(self);
}


// ============================================================================================================
// C1: the run (D25-D27, D31, D33, D46, D87, D88, D92, D102, D103).
//   gs.run = { active, seed, rng: { map, loot, shop, enemy, cards, combat }, gold, cards { pity, last, offers }, kills, started_at, echo_used }
// A run starts at level 1 in rm_floor1 (where you fell in), is saved on every room change and every few seconds, and ends in
// death, abandon or a win. Death deletes the run save: there is no reload to undo it (D46). The profile (scr_save) outlives runs.
// ============================================================================================================
function Run_StreamNames() {
    return ["map", "loot", "shop", "enemy", "cards", "combat"];
}

function Run_RngCreate(_seed) {
    var out = {};
    var names = Run_StreamNames();
    for (var i = 0; i < array_length(names); i++) variable_struct_set(out, names[i], Rng_New(_seed, names[i]));
    return out;
}

function Run_NewSeed() {
    return irandom_range(1, RNG_MOD - 2);
}

function Run_Create(_seed) {
    return {
        active: true,
        seed: _seed,
        rng: Run_RngCreate(_seed),
        gold: 0,                 // C3 (D23): enemies pay it, the merchant takes it; it is gone with the run
        shop: {},                // C3 (D85): the stock of each shop visited, { s0: [rows], ... }, so what was bought stays bought
        cards: Card_StateNew(),  // C2: the offer generator's pity counter and the last offer (scr_db_skill)
        kills: 0,
        drop_dry: 0,             // R1 (D120): won fights in a row where the enemy left no item
        gold_bag: [],            // D126: the gold offsets of the fights not paid yet (a shuffled bag of 5, refilled when empty); saved with the run
        find_bag: { p: 0, left: [] },   // D126: the Scrounger's marble bag; saved with the run
        started_at: date_current_datetime(),
        echo_used: { kind: "", id: -1 }
    };
}

function Run_Get() {
    var gs = GameState_Get();
    if (is_struct(gs) && variable_struct_exists(gs, "run") && is_struct(gs.run)) return gs.run;
    return undefined;
}

function Run_IsActive() {
    var run = Run_Get();
    return is_struct(run) && run.active;
}

// Streams used when no run is going (title screen, tests, scenarios): seeded once from the global generator.
function Run_FreeStream(_name) {
    if (!variable_global_exists("run_free") || !is_struct(global.run_free)) {
        global.run_free_seed = Run_NewSeed();
        global.run_free = Run_RngCreate(global.run_free_seed);
    }
    if (!variable_struct_exists(global.run_free, _name)) variable_struct_set(global.run_free, _name, Rng_New(global.run_free_seed, _name));
    return variable_struct_get(global.run_free, _name);
}

// The named stream of the active run (map, loot, shop, enemy, cards, combat).
function Run_Stream(_name) {
    var run = Run_Get();
    if (is_struct(run) && run.active && variable_struct_exists(run.rng, _name)) return variable_struct_get(run.rng, _name);
    return Run_FreeStream(_name);
}

// D126: where the bags that outlive a battle live: the run, or (title screen, tests) a free holder that is not saved.
function Run_BagHolder() {
    var run = Run_Get();
    if (is_struct(run)) return run;
    if (!variable_global_exists("run_free_bags") || !is_struct(global.run_free_bags)) global.run_free_bags = {};
    return global.run_free_bags;
}

function RunRng_Float(_name) { return Rng_Float(Run_Stream(_name)); }
function RunRng_Range(_name, _lo, _hi) { return Rng_Range(Run_Stream(_name), _lo, _hi); }
function RunRng_Chance(_name, _p) { return Rng_Chance(Run_Stream(_name), _p); }

// "rm_floor3" -> 3, "rm_floor6_5" -> 6.5, anything else (title, battle, cutscene) -> 0
function Run_FloorOfRoomName(_name) {
    var name = string(_name);
    if (string_pos("rm_floor", name) != 1) return 0;
    var rest = string_delete(name, 1, 8);
    var us = string_pos("_", rest);
    if (us > 0) return Save_ToReal(string_copy(rest, 1, us - 1), 0) + 0.5;
    return Save_ToReal(rest, 0);
}

// ---- echo (D87): one item or skill from the lost run, chosen 1 of 3 ----
function Run_EchoCandidates(_ch) {
    var out = [];
    if (!is_struct(_ch)) return out;
    if (variable_struct_exists(_ch, "skills") && is_array(_ch.skills)) {
        for (var s = 0; s < array_length(_ch.skills); s++) {
            if (!Run_EchoHas(out, "skill", _ch.skills[s])) array_push(out, { kind: "skill", id: _ch.skills[s] });
        }
    }
    if (variable_struct_exists(_ch, "inventory") && is_array(_ch.inventory)) {
        for (var i = 0; i < array_length(_ch.inventory); i++) {
            var e = _ch.inventory[i];
            if (is_struct(e) && variable_struct_exists(e, "id") && e.id > 0 && !Run_EchoHas(out, "item", e.id)) array_push(out, { kind: "item", id: e.id });
        }
    }
    if (variable_struct_exists(_ch, "equip") && is_struct(_ch.equip)) {
        var slots = variable_struct_get_names(_ch.equip);
        for (var q = 0; q < array_length(slots); q++) {
            var eid = variable_struct_get(_ch.equip, slots[q]);
            if (is_real(eid) && eid > 0 && !Run_EchoHas(out, "item", eid)) array_push(out, { kind: "item", id: eid });
        }
    }
    return out;
}

function Run_EchoHas(_list, _kind, _id) {
    for (var i = 0; i < array_length(_list); i++) {
        if (_list[i].kind == _kind && _list[i].id == _id) return true;
    }
    return false;
}

// Up to 3 of _list, drawn with _rng.
function Run_EchoDraw3(_list, _rng) {
    var order = Rng_Shuffle(_rng, _list);
    var out = [];
    for (var i = 0; i < min(3, array_length(order)); i++) array_push(out, order[i]);
    return out;
}

// Up to 3 distinct things the run had, drawn with _rng, no class filter (D87's draw at the death; since D130 the game draws after the class pick with
// Run_EchoOptionsFor, and this stays for its tests). A run with nothing offers the starting potion.
function Run_EchoOptions(_ch, _rng) {
    var cands = Run_EchoCandidates(_ch);
    if (array_length(cands) <= 0) return [{ kind: "item", id: 10 }];
    return Run_EchoDraw3(cands, _rng);
}

// ---- D130 (amends D87): the echo is offered right AFTER the class pick, filtered to what the new class can use ----
// A death leaves everything the lost run had in the profile (echo_pool). The class pick (ClassSelect_ApplyClass -> Run_EchoGrant) draws up to 3 of it that the
// class can use onto the character (echo_offer, saved with the run, so a quit before the answer loses nothing); Cards_NextOwed owes the pick ("echo"),
// CardsUi opens it, Run_EchoTake applies the answer and Run_EchoDone empties the pool. The first run has no echo (the pool is empty).
// A gear item fits when its class rules (preferred_class, allowed_classes) allow the class; a potion fits every class; a skill fits when its class list does.
function Run_EchoItemFits(_item_id, _class_id) {
    var it = ItemDB_Get(_item_id);
    if (!is_struct(it) || it.id == 0) return false;
    if (variable_struct_exists(it, "preferred_class") && it.preferred_class != -1 && it.preferred_class != _class_id) return false;
    if (variable_struct_exists(it, "allowed_classes") && is_array(it.allowed_classes) && array_length(it.allowed_classes) > 0 && !array_contains(it.allowed_classes, _class_id)) return false;
    return true;
}

function Run_EchoFilter(_pool, _class_id) {
    var out = [];
    if (!is_array(_pool)) return out;
    for (var i = 0; i < array_length(_pool); i++) {
        var e = _pool[i];
        var fits = false;
        if (e.kind == "skill") {
            var sk = SkillDB_GetBase(e.id);
            fits = (sk.id >= 0) && is_array(sk.class_list) && array_length(sk.class_list) > 0 && Skill_ClassAllowed(sk, _class_id);   // the same rule as Card_ClassCharacter
        } else if (e.kind == "item") {
            fits = Run_EchoItemFits(e.id, _class_id);
        }
        if (fits) array_push(out, e);
    }
    return out;
}

// Up to 3 distinct things of the pool that the class can use, shuffled with a stream made from the run's seed (it does not move any saved stream). [] = no pick.
function Run_EchoOptionsFor(_pool, _class_id, _seed) {
    var fit = Run_EchoFilter(_pool, _class_id);
    if (array_length(fit) <= 0) return [];
    return Run_EchoDraw3(fit, Rng_New(_seed, "echo"));
}

// The pool a death leaves: what the lost run had. A pool that no class pick has used yet (the run died before its class chest) is kept and joined.
// A run with nothing at all leaves the starting potion.
function Run_EchoPoolAfter(_old_pool, _ch) {
    var out = [];
    if (is_array(_old_pool)) {
        for (var i = 0; i < array_length(_old_pool); i++) {
            if (!Run_EchoHas(out, _old_pool[i].kind, _old_pool[i].id)) array_push(out, _old_pool[i]);
        }
    }
    var cands = Run_EchoCandidates(_ch);
    for (var j = 0; j < array_length(cands); j++) {
        if (!Run_EchoHas(out, cands[j].kind, cands[j].id)) array_push(out, cands[j]);
    }
    if (array_length(out) <= 0) out = [{ kind: "item", id: 10 }];
    return out;
}

// A changed copy of _ch (already the chosen class) that owes the echo pick drawn from _pool. An empty result owes nothing.
function Run_EchoGrantTo(_ch, _pool, _seed) {
    var ch = Card_EnsureFields(variable_clone(_ch));
    ch.echo_offer = Run_EchoOptionsFor(_pool, ch.class_id, _seed);
    return ch;
}

// The class pick (ClassSelect_ApplyClass): the character gets its echo offer from the profile's pool. When nothing in the pool fits the class there is no pick
// and the pool is dropped at once, without a word. When something does, the pool stays until the answer (Run_EchoDone).
function Run_EchoGrant(_ch) {
    var prof = Profile_Get();
    if (!is_struct(prof) || !variable_struct_exists(prof, "echo_pool") || array_length(prof.echo_pool) <= 0) return Card_EnsureFields(_ch);
    var seed = Run_IsActive() ? Run_Get().seed : 0;
    var ch = Run_EchoGrantTo(_ch, prof.echo_pool, seed);
    if (array_length(ch.echo_offer) <= 0) Run_EchoDone();
    return ch;
}

// The echo was answered (or nothing could be offered): nothing is pending any more.
function Run_EchoDone() {
    var prof = Profile_Get();
    if (is_struct(prof) && variable_struct_exists(prof, "echo_pool") && array_length(prof.echo_pool) > 0) {
        prof.echo_pool = [];
        Profile_Flush();
    }
}

// Takes option _index of the character's echo offer: an item goes in the inventory, a skill is learned; the offer is emptied. Returns the changed character.
function Run_EchoTake(_ch, _index) {
    var ch = Card_EnsureFields(_ch);
    if (_index >= 0 && _index < array_length(ch.echo_offer)) {
        var o = ch.echo_offer[_index];
        ch = Run_ApplyEcho(ch, o);
        if (Run_IsActive()) Run_Get().echo_used = { kind: o.kind, id: o.id };
    }
    ch.echo_offer = [];
    return ch;
}

function Run_ApplyEcho(_ch, _echo) {
    if (!is_struct(_echo) || !variable_struct_exists(_echo, "kind")) return _ch;
    if (_echo.kind == "item" && _echo.id > 0) _ch.inventory = Inv_Add(_ch.inventory, _echo.id, 1);
    else if (_echo.kind == "skill" && _echo.id >= 0) _ch = Player_LearnSkill(_ch, _echo.id);
    return _ch;
}

function Run_EchoLabel(_o) {
    if (!is_struct(_o)) return "";
    if (_o.kind == "skill") return Loc_T("runflow.echo.skill", "Skill: {name}", { name: SkillDB_Get(_o.id).name });
    return Loc_T("runflow.echo.item", "Item: {name}", { name: ItemDB_Get(_o.id).name });
}

// ---- history ----
function Run_MakeHistoryEntry(_run, _ch, _room_name, _result, _cause) {
    return {
        seed: _run.seed,
        class_id: is_struct(_ch) ? _ch.class_id : CLASS_NOBODY,
        level: is_struct(_ch) ? _ch.level : 1,
        floor: Run_FloorOfRoomName(_room_name),
        room: _room_name,
        result: _result,
        cause: _cause,
        kills: _run.kills,
        gold: _run.gold,
        at: date_current_datetime()
    };
}

// Name of the enemy that ended the run (the last battle), "" when none.
function Run_CauseText() {
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "battle") && is_struct(gs.battle) && variable_struct_exists(gs.battle, "enemy_id") && gs.battle.enemy_id >= 0) {
        var cfg = EnemyDB_Get(gs.battle.enemy_id);
        if (is_struct(cfg) && variable_struct_exists(cfg, "name")) return string(cfg.name);
    }
    return "";
}

// Where the run ended (in a battle: the room the battle started from; a win: the last floor, the ending plays in a cutscene room).
function Run_EndRoomName(_result = "died") {
    var gs = GameState_Get();
    if (_result == "won") return "rm_floor9_5";
    if (room == rm_battle && variable_struct_exists(gs, "battle") && is_struct(gs.battle) && gs.battle.return_room != noone) return room_get_name(gs.battle.return_room);
    return room_get_name(room);
}

// Ends the run in the profile: history entry, death or win counter, story flags, the echo pool (not for a win), run save deleted.
// Returns the history entry. Works without an active run (scenarios): the entry then carries seed 0.
function Run_Finish(_result, _cause) {
    var gs = GameState_Get();
    var prof = Profile_Get();
    var run = Run_Get();
    if (!is_struct(run)) run = Run_Create(0);
    var ch = gs.player_ch;

    Story_CopyFlagsToProfile(prof, gs.flags);
    var entry = Run_MakeHistoryEntry(run, ch, Run_EndRoomName(_result), _result, _cause);
    Profile_RecordRun(prof, entry);
    prof.echo_pool = (_result == "won") ? [] : Run_EchoPoolAfter(prof.echo_pool, ch);   // D130: the pick comes after the next run's class pick
    Profile_Flush();

    RunSave_Delete();
    run.active = false;
    global.run_last = entry;
    return entry;
}

// ---- starting ----
// A new run: level 1, a new seed, nothing carried (the echo waits in the profile for the class pick, D130), in rm_floor1 where you fell in (D102).
// _intro_dialogue: the fall line of the first ever run (it belongs to the intro cutscene; later runs do not repeat it).
function Run_StartNew(_intro_dialogue = false, _seed = undefined) {
    var gs = GameState_Get();
    var prof = Profile_Get();
    var seed = is_undefined(_seed) ? Run_NewSeed() : _seed;

    if (ds_exists(gs.defeated_enemies, ds_type_list)) ds_list_clear(gs.defeated_enemies);
    gs.room_states = {};
    gs.persist = {};
    gs.persist_applied = {};
    gs.uid_counter = 1;
    gs.enemy_reset_version = 0;
    gs.boss_defeated = { mini_boss: false, final_boss: false };
    gs.pending_post_battle_dialogue_lines = [];

    gs.flags = {};
    variable_struct_set(gs.flags, Dialogue_SkillbookFirstReadDoneFlagKey(), false);
    variable_struct_set(gs.flags, Dialogue_SkillbookFirstReadPendingFlagKey(), false);
    Story_CopyProfileToFlags(prof, gs.flags);

    gs.run = Run_Create(seed);

    GameState_SetSelectedClass(CLASS_NOBODY);
    var ch = CharacterCreate_Player(CLASS_NOBODY);
    prof.runs_started += 1;
    Profile_Flush();
    RunSave_Delete();

    gs.player_ch = ch;
    GameState_SetPlayer(gs.player_ch);

    gs.in_main_menu = false;
    gs.pending_floor1_intro_dialogue = _intro_dialogue;
    GameSettings_ApplyAll();
    Transition_RequestCutsceneFade(rm_floor1, "start", -1, true);
}

// A run saved on disk that the player walks away from by starting a new game: it counts as abandoned (no echo).
function Run_AbandonSaved(_path = undefined) {
    var l = RunSave_LoadFrom(_path);
    if (l.status == "ok") {
        var prof = Profile_Get();
        var raw = l.run;
        var pl = raw.statData.player;
        var entry = {
            seed: raw.seed,
            class_id: (is_struct(pl) && variable_struct_exists(pl, "class_id")) ? pl.class_id : CLASS_NOBODY,
            level: (is_struct(pl) && variable_struct_exists(pl, "level")) ? pl.level : 1,
            floor: variable_struct_exists(raw, "floor") ? raw.floor : 0,
            room: variable_struct_exists(raw.statData, "save_room_name") ? raw.statData.save_room_name : "",
            result: "abandoned",
            cause: "abandoned",
            kills: variable_struct_exists(raw, "kills") ? raw.kills : 0,
            gold: variable_struct_exists(raw, "gold") ? raw.gold : 0,
            at: date_current_datetime()
        };
        Profile_RecordRun(prof, entry);
        Profile_Flush();
    }
    // An old-format file is cleared too (review 1): left behind, Continue kept showing the old-slot notice after a new game.
    // A newer-version or damaged file is left where it is.
    if (l.status == "ok" || l.status == "missing" || l.status == "old") RunSave_Delete(_path);
}

// Title screen, New Game after the difficulty pick: the intro cutscene plays once per profile (D26); later runs start at once.
function Run_BeginNewGame() {
    if (RunSave_HasSave()) Run_AbandonSaved();
    if (Story_Seen(Story_CutsceneKey("intro"))) {
        Run_StartNew(false);
        return true;
    }
    return Transition_RequestCutsceneById("intro");
}

// Title screen, Continue: loads run.sav and enters the saved room. Returns { ok, status }.
function Run_Continue() {
    var l = RunSave_LoadFrom();
    if (l.status != "ok") return { ok: false, status: l.status };
    var info = RunSave_ApplyState(l.run);
    Save_BeginLoadTransition(info.room_id);
    return { ok: true, status: "ok" };
}

function Run_ContinueFailText(_status) {
    switch (_status) {
        case "newer": return Loc_T("run.continue.newer", "This run was saved by a newer version of the game and cannot be loaded.");
        case "old": return Save_LegacyNotice();
        case "corrupt": return Loc_T("run.continue.corrupt", "The run save is damaged and cannot be loaded.");
    }
    return Loc_T("run.continue.missing", "There is no run to continue.");
}

// ---- autosave (D46): every room change, after each fight (the return to the room is a room change), and every few seconds ----
function Run_AutosaveAllowed() {
    if (!Run_IsActive()) return false;
    if (room == rm_start || room == rm_battle || room == rm_cutscene) return false;
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "in_main_menu") && gs.in_main_menu) return false;
    if (variable_struct_exists(gs, "load_spawn_pending") && gs.load_spawn_pending) return false;
    if (!is_struct(gs.player_ch) || gs.player_ch.hp <= 0) return false;
    if (!instance_exists(obj_player)) return false;
    return true;
}

function Run_AutoSave() {
    if (!Run_AutosaveAllowed()) return false;
    var gs = GameState_Get();
    var ok = false;
    try {
        if (Story_CopyFlagsToProfile(Profile_Get(), gs.flags)) Profile_Flush();
        ok = RunSave_WriteTo();
    } catch (_e) {
        show_debug_message("[RUN] autosave failed: " + string(_e.message));
    }
    global.run_last_autosave = current_time;
    return ok;
}

// Called every frame by obj_game_controller; saves at most every 10 s while the player stands still in a quiet moment.
function Run_AutosaveTick() {
    if (!Run_IsActive()) return;
    if (!variable_global_exists("run_last_autosave")) global.run_last_autosave = current_time;
    if (current_time - global.run_last_autosave < 10000) return;
    if (Transition_IsActive()) return;
    var gs = GameState_Get();
    if (gs.ui.mode != UI_NONE) return;
    var pl = instance_exists(obj_player) ? instance_find(obj_player, 0) : noone;
    if (!instance_exists(pl) || !Player_IsSettled(pl)) return;
    Run_AutoSave();
}

// D132: the window is closing (obj_game_controller's Game End event calls this). Saves the run the way an autosave would (never in a
// battle, a cutscene, a transition or on the title). The test harness and scripted runs end the game on purpose, so they never save here;
// _ignore_harness lets the tests reach the rest of the rule.
function Run_SaveOnClose(_ignore_harness = false) {
    if (!_ignore_harness && (Test_HasFlag("-runtests") || (variable_global_exists("scn") && is_struct(global.scn)))) return false;
    if (Transition_IsActive()) return false;
    return Run_AutoSave();
}

// ---- death, abandon, win ----
// The death hook (Player_OnDeath, Debug_KillPlayer): ends the run in the profile, then the death scene plays (C5 replaces the placeholder),
// then RunFlow shows the summary and starts the next run (the echo pick comes later, after that run's class pick: D130).
function Run_OnPlayerDeath(_cause = undefined, _result = "died") {
    var cause = is_undefined(_cause) ? Run_CauseText() : _cause;
    var killer = (_result == "abandoned") ? "" : cause;   // the enemy's name for the "{killer}" slot of a death line
    Run_Finish(_result, cause);
    global.death_ctx = Death_BuildContext(_result, killer);   // C5 (D103): the line, chosen by death count and killer, before the screen goes dark
    SFX_Play("body_falling_wood");                            // the fall, as the screen fades to black
    return Transition_RequestCutsceneById("game_over");
}

// Pause menu > Abandon run (D92): a death that keeps the echo.
function Run_Abandon() {
    if (!Run_IsActive()) return false;
    Run_OnPlayerDeath("abandoned", "abandoned");
    return true;
}

// The win: final boss defeated, ending cutscene shown (once per profile, D26), credits; wins + 1, the first win unlocks the Nobody class.
function Run_OnWin() {
    Story_Mark(Story_CutsceneKey("ending"));
    Run_Finish("won", "");
}

// ---- after the fall to black: the death line (D103), the run summary, then a new run at the tunnel entrance ----
// Phases: "death" (one line, 2-4 s, hold confirm to skip, D48) -> "summary" -> "start". (D130: the echo is not offered here any more; it waits in the
// profile until the next run's class pick.)
function RunFlow_Begin() {
    var entry = (variable_global_exists("run_last") && is_struct(global.run_last)) ? global.run_last : Run_MakeHistoryEntry(Run_Create(0), undefined, "rm_floor1", "died", "");
    var ctx = (variable_global_exists("death_ctx") && is_struct(global.death_ctx)) ? global.death_ctx : Death_BuildContext(entry.result, entry.cause);
    global.death_ctx = undefined;
    global.run_flow = { phase: "death", entry: entry, t: 0, ctx: ctx };
    Skip_Reset();
    Cutscene_ClearUiState();
}

function RunFlow_Active() {
    return variable_global_exists("run_flow") && is_struct(global.run_flow) && global.run_flow.phase != "off";
}

function RunFlow_Step() {
    if (!RunFlow_Active()) return;
    var f = global.run_flow;
    f.t += 1;
    if (Transition_IsActive()) return;
    var ok = Input_UIConfirm();
    if (f.phase == "death") {
        Skip_Claim();
        if (f.t == 1) SFX_Play("metal_resonance");   // the crack
        if (f.t >= f.ctx.frames || Skip_Consume()) {
            Skip_Reset();
            f.phase = "summary";
            f.t = 0;
        }
    } else if (f.phase == "summary") {
        if (ok && f.t > 15) {
            SFX_PlayUI("ui_confirm");
            f.phase = "start";
            f.t = 0;
        }
    } else if (f.phase == "start") {
        f.phase = "starting";
        GameState_Get().pending_wake_line = true;   // the short wake line when the entrance room is up (obj_game_controller)
        Run_StartNew(false);
    }
}

function RunFlow_CauseLine(_entry) {
    if (_entry.result == "abandoned") return Loc_T("runflow.cause.abandoned", "You gave up the run.");
    if (_entry.cause != "") return Loc_T("runflow.cause.enemy", "Felled by: {name}", { name: _entry.cause });
    return Loc_T("runflow.cause.unknown", "Something in the dark took you.");
}

function RunFlow_Draw() {
    if (!RunFlow_Active()) return;
    var f = global.run_flow;
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = mt.gw;
    var h = mt.gh;
    draw_set_alpha(1);
    Ui_Box(0, 0, w, h, UI_C_DARKEST);
    if (f.phase == "death") {
        // the line fades in, holds, fades out; centred on the screen
        var fade = 30;
        var a = clamp(min(f.t / fade, (f.ctx.frames - f.t) / fade), 0, 1);
        var col_w = min(w - 2 * mt.margin, round(w * 0.6));
        var th = Ui_TextBlockH(f.ctx.text, col_w);
        var s = max(0.0001, UI_GetFontScale());
        draw_set_alpha(a);
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        draw_set_color(UI_C_TEXT);
        draw_text_ext_transformed(round(w / 2), round((h - th) / 2), f.ctx.text, -1, max(1, round(col_w / s)), s, s, 0);
        draw_set_halign(fa_left);
        draw_set_alpha(1);
    } else if (f.phase == "summary") {
        var title = Loc_T("runflow.title", "The tunnel keeps you.");
        var cls = DB_PlayerClass(f.entry.class_id).name;
        var rows = [
            { label: Loc_T("runflow.sum.floor", "Floor reached"), value: string(f.entry.floor) },
            { label: Loc_T("runflow.sum.class", "Class"), value: string(cls) },
            { label: Loc_T("runflow.sum.level", "Level"), value: string(f.entry.level) },
            { label: Loc_T("runflow.sum.kills", "Foes beaten"), value: string(f.entry.kills) },
            { label: Loc_T("runflow.sum.falls", "Falls so far"), value: string(Profile_Get().deaths) }
        ];
        var sentence = RunFlow_CauseLine(f.entry);
        var footer = Loc_T("runflow.continue", "Press confirm to go on");
        var pw = min(w - 2 * mt.margin, round(w * 0.62));
        var dh = Ui_DetailsHeight(pw, sentence, rows);
        var total = mt.line_h + 3 * p + dh + 3 * p + mt.line_h;
        var y0 = max(mt.margin, round((h - total) / 2));
        var px = round((w - pw) / 2);
        Ui_Text(w / 2, y0, title, UI_C_LIGHTEST, fa_center);
        Ui_DrawDetails(px, y0 + mt.line_h + 3 * p, pw, dh, sentence, rows);
        Ui_Text(w / 2, y0 + mt.line_h + 3 * p + dh + 3 * p, footer, UI_C_LIGHT, fa_center);
    }
    draw_set_alpha(1);
}
