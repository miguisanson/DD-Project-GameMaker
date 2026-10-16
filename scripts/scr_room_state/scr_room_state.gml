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
            if (v == "sprite_index") {
                // bug hunt 7: a sprite is saved by its NAME, never by its number (the number shifts when a sprite is added between builds, save-systems: no engine asset ids)
                var spr = variable_instance_get(_inst, v);
                if ((is_numeric(spr) || is_handle(spr)) && sprite_exists(spr)) variable_struct_set(data.vars, "sprite_name", sprite_get_name(spr));
                continue;
            }
            variable_struct_set(data.vars, v, variable_instance_get(_inst, v));
        }
    }
    if (RoomState_IsEnemyInstance(_inst) && variable_instance_exists(_inst, "enemy_id")) {
        data.enemy_id = _inst.enemy_id;
        data.vars = RoomState_SanitizeEnemyVars(data.vars, _inst.enemy_id);
    }
    data = RoomState_CarryStolen(room, _inst.persist_id, data);   // hunt 6: what the Stranger took stays on him
    RoomState_Set(room, _inst.persist_id, data);
}

// Hunt 6 (I-072): an item the Stranger stole is not lost when the player gets away. It stays on him, in his room-state record as `stolen_items`
// ([{ id, qty }], saved with the run); the next fight starts with it on him again (EnemyPersist_RestoreStolen) and beating him gives it back.
// A record that is rebuilt (the room is left, the enemy is set alive) copies the field from the old one; a removed (beaten) record has none.
function RoomState_CarryStolen(_room, _persist_id, _data) {
    var old = RoomState_Get(_room, _persist_id);
    if (!is_struct(old) || !is_struct(_data)) return _data;
    if (variable_struct_exists(_data, "removed") && _data.removed) return _data;
    if (variable_struct_exists(old, "stolen_items") && is_array(old.stolen_items) && array_length(old.stolen_items) > 0) _data.stolen_items = old.stolen_items;
    return _data;
}

function RoomState_CopyStolen(_list) {
    var out = [];
    if (!is_array(_list)) return out;
    for (var i = 0; i < array_length(_list); i++) {
        if (is_struct(_list[i]) && variable_struct_exists(_list[i], "id") && variable_struct_exists(_list[i], "qty")) array_push(out, { id: _list[i].id, qty: _list[i].qty });
    }
    return out;
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

    alive = RoomState_CarryStolen(_room, _persist_id, alive);
    RoomState_Set(_room, _persist_id, alive);
}

// The picture of a saved instance (bug hunt 7). A save holds the sprite's NAME (`sprite_name`, resolved with asset_get_index); an older save holds the raw `sprite_index` number,
// which may point at another sprite after a build that added one. Every instance that saves a picture got it by swapping to its own swap_sprite, so a swapped instance with a swap
// sprite takes that; otherwise the old number is used only when it is a real sprite. Nothing in the save is trusted to be a sprite: a name or number that is not one changes nothing.
function RoomState_ApplySprite(_inst, _vars) {
    if (!is_struct(_vars)) return;
    var named = variable_struct_exists(_vars, "sprite_name");
    if (named) {
        var nm = _vars.sprite_name;
        var spr = is_string(nm) ? asset_get_index(nm) : -1;
        if (spr != -1 && sprite_exists(spr)) {
            _inst.sprite_index = spr;
            return;
        }
        // R-087: a name that no longer resolves (a renamed sprite) falls through to the swap sprite, as an old save does; the old number is not trusted beside a name
    }
    var old = (!named && variable_struct_exists(_vars, "sprite_index")) ? _vars.sprite_index : undefined;
    if (!named && is_undefined(old)) return;
    var swapped = variable_instance_exists(_inst, "swapped") && _inst.swapped;
    if (swapped && variable_instance_exists(_inst, "swap_sprite") && _inst.swap_sprite != noone && sprite_exists(_inst.swap_sprite)) {
        _inst.sprite_index = _inst.swap_sprite;
    } else if ((is_numeric(old) || is_handle(old)) && sprite_exists(old)) {
        _inst.sprite_index = old;
    }
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
            if (n == "sprite_name" || n == "sprite_index") continue;   // pictures are restored below
            variable_instance_set(_inst, n, variable_struct_get(data.vars, n));
        }
        RoomState_ApplySprite(_inst, data.vars);
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
    EnemyPersist_SnapshotRun();   // D141: Quit to title in the fight comes back to this moment
    return true;
}

// _stolen: on an escape, what the enemy took from the player ([{ id, qty }], the battle copy's stolen_items). It stays on the map enemy (undefined keeps
// what the record already holds); a win removes the record, and Battle_GrantRewards gives the loot back.
function EnemyPersist_ResolveBattle(_defeated, _stolen = undefined) {
    global.encounter_resolved = true;   // review 6: the fight is over (won or fled). The snapshot is NOT cleared yet: Quit or close during "X has been slain." / "You ran away!" and the fade back must still
                                        // save the run (D132, D141); the map's room-entry autosave clears it (EnemyPersist_AfterMapSave), a run's end or start does too
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
        if (is_array(_stolen)) {
            var rec = RoomState_Get(gs.battle.enemy_room, gs.battle.enemy_persist_id);
            if (is_struct(rec)) {
                if (array_length(_stolen) > 0) rec.stolen_items = RoomState_CopyStolen(_stolen);
                else if (variable_struct_exists(rec, "stolen_items")) variable_struct_remove(rec, "stolen_items");
            }
        }
    }
}

// A fight with an enemy that kept the player's things from an earlier escape: they are on the battle copy again (Create of the battle controller).
function EnemyPersist_RestoreStolen(_e) {
    var gs = GameState_Get();
    if (!is_struct(_e) || !variable_struct_exists(gs, "battle") || gs.battle.enemy_persist_id == "") return;
    var rec = RoomState_Get(gs.battle.enemy_room, gs.battle.enemy_persist_id);
    if (!is_struct(rec) || !variable_struct_exists(rec, "stolen_items")) return;
    var held = RoomState_CopyStolen(rec.stolen_items);
    if (array_length(held) > 0) _e.stolen_items = held;
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

// A random seed is always one the seed entry can take back (1 .. SEED_ENTRY_MAX, at most 9 digits): the Status tab and the summary show it, and "same seed, same run" must hold when it is typed.
function Run_NewSeed() {
    return irandom_range(1, SEED_ENTRY_MAX);
}

// ---- seed input (D152) ----
// New Game offers a random seed (the default) or one the player types. A typed seed is up to 9 digits (so it stays a positive 32-bit whole number
// well under RNG_MOD); the entry is a string of digits plus a cursor, not a padded number: "000123" is the seed 123. Seeds run 1 .. RNG_MOD - 2 (the
// range a typed seed may be in; Run_NewSeed draws 1 .. SEED_ENTRY_MAX, all of which can be typed), so an empty or all-zero entry cannot be confirmed. Pure functions: the title screen only calls them.
#macro SEED_DIGITS_MAX 9
#macro SEED_ENTRY_MAX 999999999   // nine nines: the largest seed the entry takes, and the largest a random draw gives

function Seed_IsValid(_n) {
    return is_real(_n) && _n >= 1 && _n <= RNG_MOD - 2 && _n == floor(_n);
}

// The digits of a string as a whole number: anything that is not a digit is skipped, leading zeros fall away, only the first 9 digits count.
function SeedParse(_str) {
    var s = string(_str);
    var v = 0;
    var n = 0;
    for (var i = 1; i <= string_length(s) && n < SEED_DIGITS_MAX; i++) {
        var o = ord(string_char_at(s, i));
        if (o < 48 || o > 57) continue;
        v = v * 10 + (o - 48);
        n++;
    }
    return v;
}

// { digits: [0..9, ...] (at most 9), cur }. cur is the slot the cursor is on: 0 .. the number of digits (the blank slot after them), at most 8.
function SeedEntry_New() {
    return { digits: [], cur: 0 };
}

function SeedEntry_CursorMax(_e) {
    return min(array_length(_e.digits), SEED_DIGITS_MAX - 1);
}

function SeedEntry_Text(_e) {
    var s = "";
    for (var i = 0; i < array_length(_e.digits); i++) s += string(_e.digits[i]);
    return s;
}

function SeedEntry_Value(_e) {
    return SeedParse(SeedEntry_Text(_e));
}

function SeedEntry_CanConfirm(_e) {
    return Seed_IsValid(SeedEntry_Value(_e));
}

// Left / right: the cursor moves one slot and stops at both ends.
function SeedEntry_Move(_e, _dir) {
    _e.cur = clamp(_e.cur + sign(_dir), 0, SeedEntry_CursorMax(_e));
}

// Up (+1) / down (-1): the digit under the cursor goes round 0-9 (9 up is 0, 0 down is 9). The blank slot counts as a 0, so up makes a 1 and down a 9.
function SeedEntry_Cycle(_e, _dir) {
    var d = (_e.cur < array_length(_e.digits)) ? _e.digits[_e.cur] : 0;
    d = (d + sign(_dir) + 10) mod 10;
    if (_e.cur < array_length(_e.digits)) _e.digits[_e.cur] = d;
    else array_push(_e.digits, d);
}

// A digit key: goes in at the cursor (over the digit there, or into the blank slot) and the cursor steps on; a full entry changes its last digit.
function SeedEntry_Type(_e, _d) {
    if (_d < 0 || _d > 9) return;
    if (_e.cur < array_length(_e.digits)) _e.digits[_e.cur] = _d;
    else if (array_length(_e.digits) < SEED_DIGITS_MAX) array_push(_e.digits, _d);
    _e.cur = min(_e.cur + 1, SeedEntry_CursorMax(_e));
}

// Backspace: removes the digit the cursor is on; on the blank slot after the last digit it removes the digit before (the cursor steps back onto the blank slot).
function SeedEntry_Backspace(_e) {
    if (_e.cur < array_length(_e.digits)) {
        array_delete(_e.digits, _e.cur, 1);
    } else if (_e.cur > 0) {
        array_delete(_e.digits, _e.cur - 1, 1);
        _e.cur -= 1;
    }
    _e.cur = min(_e.cur, SeedEntry_CursorMax(_e));
}

// "Seed: 12345", the Status tab's line and anywhere else the seed is told in one piece.
function Seed_Label(_seed) {
    return Loc_T("tab.lbl.seed_small", "Seed: {n}", { n: string(_seed) });
}

// The seed the next run takes: the one the caller gives, else the one picked on the title (once), else a new random one.
function Run_ResolveSeed(_seed = undefined) {
    if (!is_undefined(_seed)) return _seed;
    if (variable_global_exists("run_next_seed") && !is_undefined(global.run_next_seed)) {
        var s = global.run_next_seed;
        global.run_next_seed = undefined;
        return s;
    }
    return Run_NewSeed();
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
        stats: RunStats_New(),   // G9 (D137): Perfect %, crits, damage, fights won, play time; saved with the run and copied into the history entry
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
// SUPERSEDED by D144 (see Run_EchoSkillOptions below): the game no longer calls Run_EchoFilter, Run_EchoOptionsFor, Run_EchoPoolAfter or Run_EchoGrantTo. They stay,
// with their D130 checks, until a cleanup removes the item-pool echo for good.
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

// ---- D144 (amends D130/D87): the echo is up to 3 SKILLS OF THE PICKED CLASS that the profile has discovered in any earlier run (skill memory, D148) ----
// No items. Nothing discovered for the class: no echo screen at all and the run goes on. The three are drawn with a stream made from the run's seed, so the
// same run offers the same three. A skill the character already holds is not offered again. [{ kind: "skill", id }]
function Run_EchoSkillOptions(_prof, _class_id, _seed, _owned = []) {
    var known = Skill_KnownOfClass(_prof, _class_id);
    var pool = [];
    for (var i = 0; i < array_length(known); i++) {
        if (!array_contains(_owned, known[i])) array_push(pool, { kind: "skill", id: known[i] });
    }
    if (array_length(pool) <= 0) return [];
    return Run_EchoDraw3(pool, Rng_New(_seed, "echo"));
}

// The class pick (ClassSelect_ApplyClass): the character gets its echo offer from the skill memory of the profile. When the class has no discovered skill there
// is no pick. The item pool of older builds (echo_pool) is no longer used: it is read, never offered, and emptied here so it does not linger.
function Run_EchoGrant(_ch) {
    var ch = Card_EnsureFields(variable_clone(_ch));
    var seed = Run_IsActive() ? Run_Get().seed : 0;
    ch.echo_offer = Run_EchoSkillOptions(Profile_Get(), ch.class_id, seed, ch.skills);
    if (array_length(ch.echo_offer) <= 0) Run_EchoDone();
    return ch;
}

// The echo was answered (or nothing could be offered): the old item pool, if an older profile still holds one, is emptied.
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
        stats: variable_clone(RunStats_Of(_run)),   // G9 (D137): a copy, the run struct goes on to be reused or dropped
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

// Ends the run in the profile: history entry, death or win counter, story flags, the skills the run ended with (skill memory, D148), run save deleted.
// Returns the history entry. Works without an active run (scenarios): the entry then carries seed 0.
function Run_Finish(_result, _cause) {
    var gs = GameState_Get();
    var prof = Profile_Get();
    var run = Run_Get();
    if (!is_struct(run)) run = Run_Create(0);
    var ch = gs.player_ch;

    Story_CopyFlagsToProfile(prof, gs.flags);
    var entry = Run_MakeHistoryEntry(run, ch, Run_EndRoomName(_result), _result, _cause);
    EnemyPersist_ClearSnapshot();   // review 6: a run that ends (a win included) leaves no snapshot behind
    Profile_RecordRun(prof, entry);
    if (is_struct(ch)) Skills_DiscoverAll(variable_struct_exists(ch, "skills") ? ch.skills : [], prof);   // D148: whatever the run ended with is remembered (a run saved before skill memory existed)
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
    var seed = Run_ResolveSeed(_seed);   // D152: the seed picked on the title, else a random one

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
    EnemyPersist_ClearSnapshot();   // review 6: no snapshot of an earlier run's fight

    GameState_SetSelectedClass(CLASS_NOBODY);
    var ch = CharacterCreate_Player(CLASS_NOBODY);
    prof.runs_started += 1;
    Profile_Flush();
    RunSave_DeleteUnlessKept(undefined, undefined, true);   // review 6: a kept (newer or damaged) run.sav is moved aside before this run can save over it

    gs.player_ch = ch;
    GameState_SetPlayer(gs.player_ch);

    gs.in_main_menu = false;
    gs.pending_floor1_intro_dialogue = _intro_dialogue;
    GameSettings_ApplyAll();
    Transition_RequestCutsceneFade(rm_floor1, "start", -1, true);
}

// The history entry of a saved run the player walks away from (abandoned, no echo). A save from before D137 has no stats: its entry has none either ("-").
function Run_HistoryEntryFromSave(_raw) {
    var pl = _raw.statData.player;
    var entry = {
        seed: _raw.seed,
        class_id: (is_struct(pl) && variable_struct_exists(pl, "class_id")) ? pl.class_id : CLASS_NOBODY,
        level: (is_struct(pl) && variable_struct_exists(pl, "level")) ? pl.level : 1,
        floor: variable_struct_exists(_raw, "floor") ? _raw.floor : 0,
        room: variable_struct_exists(_raw.statData, "save_room_name") ? _raw.statData.save_room_name : "",
        result: "abandoned",
        cause: "abandoned",
        kills: variable_struct_exists(_raw, "kills") ? _raw.kills : 0,
        gold: variable_struct_exists(_raw, "gold") ? _raw.gold : 0,
        at: date_current_datetime()
    };
    if (variable_struct_exists(_raw, "stats") && is_struct(_raw.stats)) entry.stats = RunStats_Normalize(_raw.stats);
    return entry;
}

// A run saved on disk that the player walks away from by starting a new game: it counts as abandoned (no echo).
function Run_AbandonSaved(_path = undefined) {
    var l = RunSave_LoadFrom(_path);
    if (l.status == "ok") {
        var prof = Profile_Get();
        var entry = Run_HistoryEntryFromSave(l.run);
        Profile_RecordRun(prof, entry);
        Profile_Flush();
    }
    RunSave_DeleteUnlessKept(_path, l.status);
}

// Starting a new run clears the run file, except a newer-version or damaged one: that is not deleted (D16: nothing is deleted that this build cannot read;
// the player may switch between builds on one save folder). An old-format file is cleared too (review 1): left behind, Continue kept showing the old-slot notice after a new game.
// _status: the status of the file when the caller has just read it.
// _move_aside: true from Run_StartNew. The kept file is then moved to "run.kept-<unix time>.sav" (RunSave_KeepAside) so the new run, whose first autosave comes a frame after the room
// change, saves to run.sav as usual without replacing it (review 6, finding 1). Run_AbandonSaved leaves it where it is: the run that follows moves it.
function RunSave_DeleteUnlessKept(_path = undefined, _status = undefined, _move_aside = false) {
    var st = is_undefined(_status) ? RunSave_LoadFrom(_path).status : _status;
    if (st == "ok" || st == "missing" || st == "old") RunSave_Delete(_path);
    else if (_move_aside) RunSave_KeepAside(_path);
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
    EnemyPersist_AfterMapSave();   // review 6: back on the map after a decided fight, the snapshot is spent
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
// cutscene, a transition or on the title). In a fight there is no save of the fight (D141): it writes the moment just before the encounter, the
// same file Quit to title writes, so a chest or a card taken since the last autosave is kept. That holds after the fight is decided too (the
// "slain" / "ran away" message and the fade back, review 6: the snapshot lives until the map has saved), and a fade does not stop it. The test harness and scripted runs end the game on
// purpose, so they never save here; _ignore_harness lets the tests reach the rest of the rule, _in_room and _path let them stand in for the
// battle room and a scratch file.
function Run_SaveOnClose(_ignore_harness = false, _in_room = room, _path = undefined) {
    if (!_ignore_harness && (Test_HasFlag("-runtests") || (variable_global_exists("scn") && is_struct(global.scn)))) return false;
    if (_in_room == rm_battle) {   // review 6: before the transition guard. The snapshot is complete text, so the fades into and out of the fight do not matter to it, and the fade back to the map is still "before the map is back"
        if (!Run_IsActive()) return false;
        var gs = GameState_Get();
        if (!is_struct(gs.player_ch) || gs.player_ch.hp <= 0) return false;   // a dead player's run is over (the death flow ends it)
        return EnemyPersist_WriteSnapshot(_path);   // no snapshot (a fight that did not start from the map): the last autosave stays the run
    }
    if (Transition_IsActive()) return false;
    return Run_AutoSave();
}

// ---- death, abandon, win ----
// The death hook (Player_OnDeath, Debug_KillPlayer): ends the run in the profile, then the death scene plays (C5 replaces the placeholder),
// then RunFlow shows the summary and starts the next run (the echo pick comes later, after that run's class pick: D130).
function Run_OnPlayerDeath(_cause = undefined, _result = "died") {
    EnemyPersist_ClearSnapshot();   // hunt 5a: the fight is lost (or the run abandoned): no snapshot of it may be written later
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
    RunFlow_DeathImage();   // H13a (D156): the picture is made now (once per session), not in the middle of the first Draw
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
    if (_entry.result == "abandoned") return Loc_T("runflow.cause.abandoned", "You abandoned the run.");
    if (_entry.cause != "") return Loc_T("runflow.cause.enemy", "Felled by: {name}", { name: _entry.cause });
    return Loc_T("runflow.cause.unknown", "Something in the dark took you.");
}

// The rows of the run summary: the five of old, since D137 the six run stats ("-" for an entry without them), and since D152 the seed.
function RunFlow_SummaryRows(_entry) {
    var rows = [
        { label: Loc_T("runflow.sum.floor", "Floor Reached"), value: string(_entry.floor) },
        { label: Loc_T("runflow.sum.class", "Class"), value: string(DB_PlayerClass(_entry.class_id).name) },
        { label: Loc_T("runflow.sum.level", "Level"), value: string(_entry.level) },
        { label: Loc_T("runflow.sum.kills", "Enemies Beaten"), value: string(_entry.kills) },
        { label: Loc_T("runflow.sum.falls", "Falls So Far"), value: string(Profile_Get().deaths) }
    ];
    var st = RunStats_Lines(_entry);
    for (var i = 0; i < array_length(st); i++) array_push(rows, st[i]);
    array_push(rows, { label: Loc_T("tab.lbl.seed", "Seed"), value: string(variable_struct_exists(_entry, "seed") ? _entry.seed : 0) });   // D152: the seed the run was played on
    return rows;
}

// ---- H13a (D156): the old death picture behind the death line ----
// The picture the game showed at GAME_OVER before the roguelike death scene (the sprite GAME_OVER, 160 x 144, a fly on a green eye: cutscene art, found by name). It was drawn
// with hundreds of shades of green; the death scene redraws it once in the four palette colours (nearest colour of each pixel) as a runtime sprite, so no resource changes.
function RunFlow_DeathImageName() {
    return "GAME_OVER";
}

// The palette colour (BGR) nearest to an RGB colour, by squared distance.
function DeathImage_NearestColor(_r, _g, _b) {
    var pal = [UI_C_DARKEST, UI_C_DARK, UI_C_LIGHT, UI_C_LIGHTEST];
    var best = pal[0];
    var best_d = -1;
    for (var i = 0; i < array_length(pal); i++) {
        var dr = color_get_red(pal[i]) - _r;
        var dg = color_get_green(pal[i]) - _g;
        var db = color_get_blue(pal[i]) - _b;
        var d = dr * dr + dg * dg + db * db;
        if (best_d < 0 || d < best_d) { best_d = d; best = pal[i]; }
    }
    return best;
}

// The death picture in the four palette colours: made on first use and kept (a runtime sprite); -1 when GAME_OVER is not in the project.
function RunFlow_DeathImage() {
    if (variable_global_exists("death_img") && sprite_exists(global.death_img)) return global.death_img;
    var name = RunFlow_DeathImageName();
    var src = asset_get_index(name);
    if (src == -1 || asset_get_type(name) != asset_sprite) return -1;
    var w = sprite_get_width(src);
    var h = sprite_get_height(src);
    var surf = surface_create(w, h);
    surface_set_target(surf);
    draw_clear_alpha(c_black, 0);
    draw_sprite(src, 0, 0, 0);
    surface_reset_target();
    var n = w * h * 4;
    var buf = buffer_create(n, buffer_fixed, 1);
    buffer_get_surface(buf, surf, 0);
    var seen = ds_map_create();   // the picture has a few hundred shades: each is matched once
    for (var i = 0; i < n; i += 4) {
        if (buffer_peek(buf, i + 3, buffer_u8) == 0) continue;
        var r = buffer_peek(buf, i, buffer_u8);
        var g = buffer_peek(buf, i + 1, buffer_u8);
        var b = buffer_peek(buf, i + 2, buffer_u8);
        var key = r * 65536 + g * 256 + b;
        var c = seen[? key];
        if (is_undefined(c)) {
            c = DeathImage_NearestColor(r, g, b);
            seen[? key] = c;
        }
        buffer_poke(buf, i, buffer_u8, color_get_red(c));
        buffer_poke(buf, i + 1, buffer_u8, color_get_green(c));
        buffer_poke(buf, i + 2, buffer_u8, color_get_blue(c));
    }
    ds_map_destroy(seen);
    buffer_set_surface(buf, surf, 0);
    var spr = sprite_create_from_surface(surf, 0, 0, w, h, false, false, 0, 0);
    buffer_delete(buf);
    surface_free(surf);
    global.death_img = spr;
    return spr;
}

// Where the death scene puts its picture and its line, in GUI units: the picture (a whole-number scale when it can, never more than 70% of the height) over the text block, the two together
// centred; the picture is left out when it would not fit. Pure: sizes in, rects out. _col_w / _text_h = the text block the line needs.
function RunFlow_DeathLayout(_gw, _gh, _margin, _col_w, _text_h, _img_w, _img_h) {
    var gap = _margin;
    var out = { show: false, img_x: 0, img_y: 0, img_w: 0, img_h: 0, scale: 0, text_x: round((_gw - _col_w) / 2), text_y: 0, text_w: _col_w, text_h: _text_h };
    var k = 0;
    if (_img_w > 0 && _img_h > 0) {
        var max_h = min(_gh - 2 * _margin - gap - _text_h, floor(_gh * 0.7));
        var max_w = _gw - 2 * _margin;
        k = min(max_w / _img_w, max_h / _img_h);
        if (k >= 1) k = floor(k);
    }
    if (k * _img_h >= 8) {
        out.show = true;
        out.scale = k;
        out.img_w = round(_img_w * k);
        out.img_h = round(_img_h * k);
        var y0 = max(0, round((_gh - (out.img_h + gap + _text_h)) / 2));
        out.img_x = round((_gw - out.img_w) / 2);
        out.img_y = y0;
        out.text_y = y0 + out.img_h + gap;
    } else {
        out.text_y = round((_gh - _text_h) / 2);
    }
    return out;
}

// The layout for the window as it is now and a death line.
function RunFlow_DeathLayoutNow(_text) {
    var mt = Ui_Metrics();
    var col_w = min(mt.gw - 2 * mt.margin, round(mt.gw * 0.6));
    var pic = RunFlow_DeathImage();
    var iw = sprite_exists(pic) ? sprite_get_width(pic) : 0;
    var ih = sprite_exists(pic) ? sprite_get_height(pic) : 0;
    return RunFlow_DeathLayout(mt.gw, mt.gh, mt.margin, col_w, Ui_TextBlockH(_text, col_w), iw, ih);
}

// How many frames the death picture has been drawn (a check reads it).
function RunFlow_DeathPicDraws() {
    return variable_global_exists("run_flow_pic_draws") ? global.run_flow_pic_draws : 0;
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
        // the picture and the line fade in, hold, fade out; the picture (D156: the old GAME_OVER art, in the palette) above the line, the two centred on the screen
        var fade = 30;
        var a = clamp(min(f.t / fade, (f.ctx.frames - f.t) / fade), 0, 1);
        var lay = RunFlow_DeathLayoutNow(f.ctx.text);
        var s = max(0.0001, UI_GetFontScale());
        if (lay.show) {
            draw_sprite_ext(RunFlow_DeathImage(), 0, lay.img_x, lay.img_y, lay.scale, lay.scale, 0, c_white, a);
            global.run_flow_pic_draws = RunFlow_DeathPicDraws() + 1;
        }
        draw_set_alpha(a);
        if (Prompt_HasTokens(f.ctx.text)) {   // D149: terms and buttons in the line (laid out in the text column under the death picture, H13a)
            Prompt_RichDraw(round((w - lay.text_w) / 2), lay.text_y, f.ctx.text, lay.text_w, UI_C_TEXT, fa_center, a);
        } else {
            if (UiFit_On()) UiFit_BlockDrawn(round((w - lay.text_w) / 2), lay.text_y, f.ctx.text, lay.text_w);   // H13b (D156)
            draw_set_halign(fa_center);
            draw_set_valign(fa_top);
            draw_set_color(UI_C_TEXT);
            draw_text_ext_transformed(round(w / 2), lay.text_y, f.ctx.text, -1, max(1, round(lay.text_w / s)), s, s, 0);
            draw_set_halign(fa_left);
        }
        draw_set_alpha(1);
    } else if (f.phase == "summary") {
        var title = Loc_T("runflow.title", "The tunnel keeps you.");
        var rows = RunFlow_SummaryRows(f.entry);
        var sentence = RunFlow_CauseLine(f.entry);
        var footer = Loc_T("runflow.continue", "Press [k:confirm] to continue");
        var pw = min(w - 2 * mt.margin, round(w * 0.62));
        var cols = 1;
        var dh = Ui_DetailsHeight(pw, sentence, rows);
        var total = mt.line_h + 3 * p + dh + 3 * p + mt.line_h;
        if (total > h - 2 * mt.margin) {   // G9 (D137): the eleven rows do not fit one under the other on a small window: two columns, a wider panel
            cols = 2;
            pw = min(w - 2 * mt.margin, round(w * 0.9));
            dh = Ui_DetailsHeight(pw, sentence, rows, cols);
            total = mt.line_h + 3 * p + dh + 3 * p + mt.line_h;
        }
        var sa = Ui_AnimT(0, Transition_FramesToMs(f.t));   // G10 (D129): the shared open motion: fades in and slides down in three pixel steps, like every panel
        var y0 = max(mt.margin, round((h - total) / 2)) - p * round((1 - sa) * 3);
        var px = round((w - pw) / 2);
        draw_set_alpha(sa);
        Ui_Text(w / 2, y0, title, UI_C_LIGHTEST, fa_center);
        Ui_DrawDetails(px, y0 + mt.line_h + 3 * p, pw, dh, sentence, rows, sa, cols);
        Prompt_RichDraw(round(w * 0.1), y0 + mt.line_h + 3 * p + dh + 3 * p, footer, round(w * 0.8), UI_C_LIGHT, fa_center, sa);   // D156: the button of the device in use
    }
    draw_set_alpha(1);
}


// ============================================================================================================
// G9 (D137): run stats. run.stats = { qte_total, qte_perfect, crits, dmg_dealt, dmg_taken, fights_won, play_ms }.
// Counted by one-line hooks in scr_combat (RunStats_Qte where a QTE is graded, RunStats_Dealt / RunStats_Taken where a hit lands, RunStats_FightWon in
// Battle_CheckEnd) and by RunStats_Tick (obj_game_controller, every step). Saved with the run (RunSave_Build / RunSave_ApplyState, no version bump: a
// save without them reads zeros), copied into the history entry (Run_MakeHistoryEntry) and shown on the run summary and the Codex run history.
// An entry with no stats (a run from before D137) shows "-". Nothing here counts without an active run.
// ============================================================================================================
function RunStats_New() {
    return { qte_total: 0, qte_perfect: 0, crits: 0, dmg_dealt: 0, dmg_taken: 0, fights_won: 0, play_ms: 0 };
}

function RunStats_Names() {
    return ["qte_total", "qte_perfect", "crits", "dmg_dealt", "dmg_taken", "fights_won", "play_ms"];
}

// A stats struct from anything a save or a history file may hold: every field a whole number >= 0, a missing or broken one 0.
function RunStats_Normalize(_raw) {
    var out = RunStats_New();
    if (!is_struct(_raw)) return out;
    var names = RunStats_Names();
    for (var i = 0; i < array_length(names); i++) {
        if (!variable_struct_exists(_raw, names[i])) continue;
        variable_struct_set(out, names[i], max(0, floor(Save_ToReal(variable_struct_get(_raw, names[i]), 0))));
    }
    return out;
}

// The stats a run holds (made on the spot for a run struct that has none), undefined without a run.
function RunStats_Of(_run) {
    if (!is_struct(_run)) return undefined;
    if (!variable_struct_exists(_run, "stats") || !is_struct(_run.stats)) _run.stats = RunStats_New();
    return _run.stats;
}

// The run a hook counts into: the one given, else the active run of the game; undefined when there is none or it is over.
function RunStats_Target(_run = undefined) {
    var run = is_struct(_run) ? _run : Run_Get();
    if (!is_struct(run) || !run.active) return undefined;
    return RunStats_Of(run);
}

// A QTE was graded (attack bar, arrow skill, defence bar, throw): a Weak counts too.
function RunStats_Qte(_key, _run = undefined) {
    var st = RunStats_Target(_run);
    if (!is_struct(st)) return;
    st.qte_total += 1;
    if (_key == QTE_PERFECT) st.qte_perfect += 1;
}

// The player's hit landed for _dmg (a crit adds one to the crits landed).
function RunStats_Dealt(_dmg, _crit = false, _run = undefined) {
    var st = RunStats_Target(_run);
    if (!is_struct(st) || _dmg <= 0) return;
    st.dmg_dealt += _dmg;
    if (_crit) st.crits += 1;
}

// A hit took _dmg off the player.
function RunStats_Taken(_dmg, _run = undefined) {
    var st = RunStats_Target(_run);
    if (!is_struct(st) || _dmg <= 0) return;
    st.dmg_taken += _dmg;
}

function RunStats_FightWon(_run = undefined) {
    var st = RunStats_Target(_run);
    if (!is_struct(st)) return;
    st.fights_won += 1;
}

// Run time counts while the window is in front, the menu (Esc / Tab, H1: the one menu) is not open and the title screen is not up.
function RunStats_Counting(_has_focus, _ui_mode, _in_main_menu) {
    return _has_focus && !_in_main_menu && _ui_mode != UI_MENU;
}

function RunStats_AdvanceMs(_run, _ms, _counting) {
    var st = RunStats_Target(_run);
    if (!is_struct(st) || !_counting || _ms <= 0) return;
    st.play_ms += _ms;
}

// Every step (obj_game_controller). The window's focus is the one Focus_Step keeps (global.focus_prev; scripted runs never lose it).
function RunStats_Tick(_step_ms) {
    var run = Run_Get();
    if (!is_struct(run) || !run.active) return;
    var gs = GameState_Get();
    var focused = !variable_global_exists("focus_prev") || global.focus_prev;
    var in_menu = variable_struct_exists(gs, "in_main_menu") && gs.in_main_menu;
    RunStats_AdvanceMs(run, _step_ms, RunStats_Counting(focused, gs.ui.mode, in_menu));
}

// Perfect grades as a whole percent of all graded QTEs (the nearest); -1 when there was no QTE.
function RunStats_PerfectPct(_st) {
    if (!is_struct(_st) || _st.qte_total <= 0) return -1;
    return floor((200 * _st.qte_perfect + _st.qte_total) / (2 * _st.qte_total));
}

function RunStats_PerfectText(_st) {
    var pct = RunStats_PerfectPct(_st);
    return (pct < 0) ? "-" : (string(pct) + "%");
}

// m:ss, h:mm:ss from an hour.
function RunStats_TimeText(_ms) {
    var secs = floor(max(0, _ms) / 1000);
    var h = secs div 3600;
    var m = (secs mod 3600) div 60;
    var s = secs mod 60;
    var ss = ((s < 10) ? "0" : "") + string(s);
    if (h > 0) return string(h) + ":" + ((m < 10) ? "0" : "") + string(m) + ":" + ss;
    return string(m) + ":" + ss;
}

// A history entry's stats struct, undefined for an entry from before D137.
function RunStats_FromEntry(_entry) {
    if (!is_struct(_entry) || !variable_struct_exists(_entry, "stats") || !is_struct(_entry.stats)) return undefined;
    return RunStats_Normalize(_entry.stats);
}

// The six lines for the run summary and the Codex run history: { label, value }; "-" for an entry without stats.
function RunStats_Lines(_entry) {
    var st = RunStats_FromEntry(_entry);
    var has = is_struct(st);
    return [
        { label: Loc_T("stat.perfect", "Perfect Rate"), value: has ? RunStats_PerfectText(st) : "-" },
        { label: Loc_T("stat.crits", "Crits Landed"), value: has ? string(st.crits) : "-" },
        { label: Loc_T("stat.dmg_dealt", "Damage Dealt"), value: has ? string(st.dmg_dealt) : "-" },
        { label: Loc_T("stat.dmg_taken", "Damage Taken"), value: has ? string(st.dmg_taken) : "-" },
        { label: Loc_T("stat.fights_won", "Battles Won"), value: has ? string(st.fights_won) : "-" },
        { label: Loc_T("stat.time", "Run Time"), value: has ? RunStats_TimeText(st.play_ms) : "-" }
    ];
}

// D141: the run as it was just before a fight, kept as text (so nothing the fight does to the live structs can reach it). Taken by
// EnemyPersist_BeginEncounter once the room state is saved; Quit to title in the fight writes it as the run save (no state of the fight is ever saved).
function EnemyPersist_SnapshotRun() {
    global.encounter_resolved = false;
    global.encounter_snapshot = json_stringify(RunSave_Build());
    return is_string(global.encounter_snapshot);
}

// The snapshot belongs to one fight: forgotten when that fight ends (hunt 5a), so a later fight that did not begin on the map cannot write it.
function EnemyPersist_ClearSnapshot() {
    global.encounter_snapshot = undefined;
    global.encounter_resolved = false;
}

// The map has saved the run after a fight that was decided (Run_AutoSave, the room-entry save when the map is back): the outcome is in run.sav now, so the pre-fight snapshot has done its job (hunt 5a:
// it belongs to one fight, a later fight that did not begin on the map must not write it). A snapshot of a fight still going (not decided) is left alone.
function EnemyPersist_AfterMapSave() {
    if (variable_global_exists("encounter_resolved") && global.encounter_resolved) EnemyPersist_ClearSnapshot();
}

function EnemyPersist_HasSnapshot() {
    return variable_global_exists("encounter_snapshot") && is_string(global.encounter_snapshot);
}

// Writes the snapshot as the run save the way every run save is written (a temp file, verified, the old one kept as .bak). false when there is none.
function EnemyPersist_WriteSnapshot(_path = undefined) {
    if (!EnemyPersist_HasSnapshot()) return false;
    var path = is_undefined(_path) ? RunSave_Path() : _path;
    var ok = Save_WriteFileAtomic(path, global.encounter_snapshot, RunSave_IsCurrentRaw);
    if (ok) EnemyPersist_ClearSnapshot();   // hunt 5a: spent; a second quit must not write it again
    return ok;
}
