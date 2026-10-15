function CharacterCreate_Player(_class_id) {
    var ch = {};
    ch.is_player = true;
    ch.class_id = _class_id;
    ch.class_cfg = DB_PlayerClass(_class_id);

    ch.level = 1;
    ch.exp = 0;
    ch.exp_next = Exp_NextLevel(ch.level);

    // Level-1 stats of the class (combat-spec.md section 2).
    ch.stats = StatsClampAll({ atk: ch.class_cfg.stats.atk, def: ch.class_cfg.stats.def, spd: ch.class_cfg.stats.spd, mag: ch.class_cfg.stats.mag });

    // RecomputeResources reads hp/mp, so they must exist first; a new character then starts full.
    ch.hp = 0;
    ch.mp = 0;

    ch = RecomputeResources(ch);
    ch.hp = ch.max_hp;
    ch.mp = ch.max_mp;

    // inventory/equip (later sections)
    ch.inventory = [];
    ch.equip = { weapon: 0, head: 0, body: 0, ring1: 0, ring2: 0, accessory: 0 };   // C3 (D92): accessory = ring or charm
    ch.skills = Player_DefaultSkills(_class_id);
    ch.stat_points = 0;
    ch.status = [];
    ch.inventory = Inv_Add(ch.inventory, 10, 2);
    ch = Card_EnsureFields(ch);   // C2: upgrades, passives, owed picks
    ch = Player_NormalizeProgression(ch, true);

    return ch;
}

function Player_DefaultSkills(_class_id) {
    return [];
}

function Difficulty_Normalize(_difficulty) {
    var d = round(GameSettings_ToReal(_difficulty, DIFFICULTY_NORMAL));
    return clamp(d, DIFFICULTY_EASY, DIFFICULTY_HARD);
}

function Difficulty_GetCurrent() {
    if (variable_global_exists("state") && is_struct(global.state) && variable_struct_exists(global.state, "difficulty")) {
        return Difficulty_Normalize(global.state.difficulty);
    }
    return DIFFICULTY_NORMAL;
}

// D35: ONE difficulty. Whatever difficulty id is saved (the id only survives for the title screen and the save format until the UI
// packets drop it), the profile is the same. The single knob is the QTE assist multiplier on damage the PLAYER takes (1 = off);
// the assist setting writes global.assist_damage_taken_mult (combat-spec.md section 5).
function Difficulty_Profile(_difficulty = -1) {
    var assist = 1;
    if (variable_global_exists("assist_damage_taken_mult")) assist = clamp(real(global.assist_damage_taken_mult), 0, 1);
    return {
        id: DIFFICULTY_NORMAL,
        assist_damage_taken_mult: assist,
        player_exp_mult: 1.00
    };
}

function Difficulty_SetCurrent(_difficulty) {
    var gs = GameState_Get();
    gs.difficulty = Difficulty_Normalize(_difficulty);
    return gs.difficulty;
}

function Player_EnsureSpriteSet() {
    if (!variable_instance_exists(id, "sprite") || !is_array(sprite) || array_length(sprite) < 4) {
        sprite = array_create(4, sprite_index);
    }

    if (sprite[RIGHT] == noone) sprite[RIGHT] = sprite_index;
    if (sprite[LEFT] == noone) sprite[LEFT] = sprite_index;
    if (sprite[UP] == noone) sprite[UP] = sprite_index;
    if (sprite[DOWN] == noone) sprite[DOWN] = sprite_index;
}

function Player_ApplyClassSprites(_class_id) {
    Player_EnsureSpriteSet();

    var cfg = DB_PlayerClass(_class_id);
    if (is_struct(cfg) && variable_struct_exists(cfg, "sprites")) {
        var s = cfg.sprites;
        if (is_struct(s)) {
            if (variable_struct_exists(s, "right") && s.right != noone) sprite[RIGHT] = s.right;
            if (variable_struct_exists(s, "left") && s.left != noone) sprite[LEFT] = s.left;
            if (variable_struct_exists(s, "up") && s.up != noone) sprite[UP] = s.up;
            if (variable_struct_exists(s, "down") && s.down != noone) sprite[DOWN] = s.down;
        }
    }
}


function Player_IsSettled(_pl) {
    if (!instance_exists(_pl)) return false;
    if (variable_instance_exists(_pl, "auto_resolve_recover_timer") && _pl.auto_resolve_recover_timer > 0) return false;
    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = _pl.tile_size;
    var gx = round(_pl.x / tile) * tile;
    var gy = round(_pl.y / tile) * tile;
    if (abs(_pl.x - gx) > 0.01 || abs(_pl.y - gy) > 0.01) return false;
    if (variable_instance_exists(_pl, "move_timer") && _pl.move_timer > 0) return false;
    return true;
}

function Player_CanAcceptMove(_pl) {
    if (!instance_exists(_pl)) return false;
    if (variable_instance_exists(_pl, "auto_resolve_recover_timer") && _pl.auto_resolve_recover_timer > 0) return false;
    if (variable_instance_exists(_pl, "moving") && _pl.moving) return false;
    if (variable_instance_exists(_pl, "move_timer") && _pl.move_timer > 0) return false;
    return true;
}

// I-048: the player never rests between tiles. Called each step when not mid-step (save/load, aborted step, odd spawn).
// Picks the nearest cell that is not a wall or an interactable. Returns true when it moved the player.
function Player_TileBlocked(_inst, _x, _y) {
    var _hit = false;
    with (_inst) _hit = place_meeting(_x, _y, obj_wall) || place_meeting(_x, _y, obj_interactable);
    return _hit;
}

function Player_SnapIfOffGrid(_pl) {
    if (!instance_exists(_pl)) return false;
    if (Grid_IsAligned(_pl.x) && Grid_IsAligned(_pl.y)) return false;
    var _p = Grid_FindFreeSnap(_pl, _pl.x, _pl.y, function(_inst, _x, _y) { return !Player_TileBlocked(_inst, _x, _y); });
    _pl.x = _p.x;
    _pl.y = _p.y;
    return true;
}

function Player_StartAutoResolveRecover(_pl, _recover_frames = ENEMY_AUTO_RESOLVE_RECOVER_FRAMES, _apply_battle_cooldown = true) {
    if (!instance_exists(_pl)) return;

    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = max(1, round(real(_pl.tile_size)));
    var gx = round(_pl.x / tile) * tile;
    var gy = round(_pl.y / tile) * tile;
    var frames = max(0, round(real(_recover_frames)));
    // I-048: never settle into a wall or a chest; take the nearest free cell instead.
    if (Player_TileBlocked(_pl, gx, gy)) {
        var _free_cell = Grid_FindFreeSnap(_pl, _pl.x, _pl.y, function(_inst, _x, _y) { return !Player_TileBlocked(_inst, _x, _y); });
        gx = _free_cell.x;
        gy = _free_cell.y;
    }

    if (variable_instance_exists(_pl, "moving")) _pl.moving = false;
    if (variable_instance_exists(_pl, "move_timer")) _pl.move_timer = 0;
    if (variable_instance_exists(_pl, "move_dir")) _pl.move_dir = -1;
    if (variable_instance_exists(_pl, "xspeed")) _pl.xspeed = 0;
    if (variable_instance_exists(_pl, "yspeed")) _pl.yspeed = 0;

    var needs_settle = (abs(_pl.x - gx) > 0.01 || abs(_pl.y - gy) > 0.01);
    if (!needs_settle || frames <= 0) {
        _pl.x = gx;
        _pl.y = gy;
        if (variable_instance_exists(_pl, "auto_resolve_recover_timer")) _pl.auto_resolve_recover_timer = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_total")) _pl.auto_resolve_recover_total = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_progress")) _pl.auto_resolve_recover_progress = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_x")) _pl.auto_resolve_recover_start_x = gx;
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_y")) _pl.auto_resolve_recover_start_y = gy;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_x")) _pl.auto_resolve_recover_target_x = gx;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_y")) _pl.auto_resolve_recover_target_y = gy;
    } else {
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_x")) _pl.auto_resolve_recover_start_x = _pl.x;
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_y")) _pl.auto_resolve_recover_start_y = _pl.y;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_x")) _pl.auto_resolve_recover_target_x = gx;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_y")) _pl.auto_resolve_recover_target_y = gy;
        if (variable_instance_exists(_pl, "auto_resolve_recover_total")) _pl.auto_resolve_recover_total = frames;
        if (variable_instance_exists(_pl, "auto_resolve_recover_progress")) _pl.auto_resolve_recover_progress = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_timer")) _pl.auto_resolve_recover_timer = frames;
    }

    if (_apply_battle_cooldown && variable_instance_exists(_pl, "battle_cooldown")) {
        _pl.battle_cooldown = max(_pl.battle_cooldown, BATTLE_COOLDOWN_FRAMES);
    }

    Player_ArmExitIgnore(_pl, gx, gy);   // D64
}

// D64: a player placed (arrival, battle return, Continue) standing on an exit tile: that exit ignores them until they step off it. _gx/_gy: the cell
// (default: the one the player is on). A point test on the cell centre uses the exit's mask only (a fresh player has no mask until its first Step).
function Player_ArmExitIgnore(_pl, _gx = undefined, _gy = undefined) {
    if (!instance_exists(_pl) || !variable_instance_exists(_pl, "exit_ignore")) return noone;
    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = max(1, round(real(_pl.tile_size)));
    var gx = is_undefined(_gx) ? round(_pl.x / tile) * tile : _gx;
    var gy = is_undefined(_gy) ? round(_pl.y / tile) * tile : _gy;
    var _exit_here = instance_position(gx + tile / 2, gy + tile / 2, obj_room_transition);
    if (_exit_here != noone) _pl.exit_ignore = _exit_here;
    return _exit_here;
}

function Player_EnsureDialogueSettle(_pl, _recover_frames = PLAYER_DIALOGUE_SETTLE_FRAMES) {
    if (!instance_exists(_pl)) return;
    if (variable_instance_exists(_pl, "auto_resolve_recover_timer") && _pl.auto_resolve_recover_timer > 0) return;

    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = max(1, round(real(_pl.tile_size)));
    var gx = round(_pl.x / tile) * tile;
    var gy = round(_pl.y / tile) * tile;
    if (abs(_pl.x - gx) <= 0.01 && abs(_pl.y - gy) <= 0.01) return;

    Player_StartAutoResolveRecover(_pl, _recover_frames, false);
}

function DialogueTrigger_IsDialogueActive() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) return false;
    var ui = gs.ui;
    if (variable_struct_exists(ui, "mode") && ui.mode == UI_DIALOGUE) return true;
    if (variable_struct_exists(ui, "lines") && is_array(ui.lines) && array_length(ui.lines) > 0) return true;
    return false;
}

function DialogueTrigger_GetPlayerInst() {
    var gs = GameState_Get();
    if (is_struct(gs) && variable_struct_exists(gs, "player_inst") && instance_exists(gs.player_inst)) {
        return gs.player_inst;
    }
    if (instance_exists(obj_player)) return instance_find(obj_player, 0);
    return noone;
}

function DialogueTrigger_EaseValue(_t, _ease = "smoothstep") {
    var t = clamp(real(_t), 0, 1);
    if (string(_ease) == "linear") return t;
    return t * t * (3 - (2 * t)); // smoothstep (bell-curve accel/decel)
}

function DialogueTrigger_GetTargetPoint(_inst) {
    if (!instance_exists(_inst)) return { ok: false, x: 0, y: 0 };

    var cx = _inst.x;
    var cy = _inst.y;
    if (variable_instance_exists(_inst, "bbox_left")
    && variable_instance_exists(_inst, "bbox_right")
    && variable_instance_exists(_inst, "bbox_top")
    && variable_instance_exists(_inst, "bbox_bottom")) {
        cx = (_inst.bbox_left + _inst.bbox_right) * 0.5;
        cy = (_inst.bbox_top + _inst.bbox_bottom) * 0.5;
    }

    return { ok: true, x: cx, y: cy };
}

function DialogueTrigger_CameraPosForPoint(_cam, _wx, _wy) {
    var vw = max(1, camera_get_view_width(_cam));
    var vh = max(1, camera_get_view_height(_cam));
    var max_x = max(0, room_width - vw);
    var max_y = max(0, room_height - vh);
    var cx = clamp(round(real(_wx) - (vw * 0.5)), 0, max_x);
    var cy = clamp(round(real(_wy) - (vh * 0.5)), 0, max_y);
    return { x: cx, y: cy };
}

function DialogueTrigger_ResolveTargetFromConfig(_tr, _prefix) {
    if (!instance_exists(_tr)) return noone;

    var pfx = string(_prefix);
    var direct_name = pfx + "_target";
    var tag_name = pfx + "_tag";
    var tag_var_name = pfx + "_tag_var";
    var obj_name = pfx + "_object";
    var radius_name = pfx + "_search_radius";

    var obj_idx = obj_enemy;
    if (variable_instance_exists(_tr, obj_name)) {
        var obj_val = variable_instance_get(_tr, obj_name);
        if (is_real(obj_val) && object_exists(obj_val)) obj_idx = obj_val;
    }

    if (variable_instance_exists(_tr, direct_name)) {
        var direct = variable_instance_get(_tr, direct_name);
        if (instance_exists(direct)) return direct;
    }

    var target_tag = "";
    if (variable_instance_exists(_tr, tag_name)) {
        target_tag = string(variable_instance_get(_tr, tag_name));
    }

    var target_tag_var = "cine_id";
    if (variable_instance_exists(_tr, tag_var_name)) {
        target_tag_var = string(variable_instance_get(_tr, tag_var_name));
    }

    if (target_tag != "" && object_exists(obj_idx) && instance_exists(obj_idx)) {
        var n = instance_number(obj_idx);
        for (var i = 0; i < n; i++) {
            var inst = instance_find(obj_idx, i);
            if (!instance_exists(inst)) continue;
            if (!variable_instance_exists(inst, target_tag_var)) continue;
            if (string(variable_instance_get(inst, target_tag_var)) == target_tag) return inst;
        }
    }

    var radius = DIALOGUE_TRIGGER_TARGET_SEARCH_RADIUS;
    if (variable_instance_exists(_tr, radius_name)) {
        radius = max(0, real(variable_instance_get(_tr, radius_name)));
    }

    if (!object_exists(obj_idx) || !instance_exists(obj_idx)) return noone;

    var best = noone;
    var best_dist = 1000000000;
    var n2 = instance_number(obj_idx);
    for (var j = 0; j < n2; j++) {
        var inst2 = instance_find(obj_idx, j);
        if (!instance_exists(inst2)) continue;

        var d = point_distance(_tr.x, _tr.y, inst2.x, inst2.y);
        if (radius > 0 && d > radius) continue;
        if (d < best_dist) {
            best_dist = d;
            best = inst2;
        }
    }

    return best;
}

function DialogueTrigger_EnemyLockAcquire(_enemy, _owner = noone) {
    if (!instance_exists(_enemy)) return false;

    if (!variable_instance_exists(_enemy, "cine_lock_count")) _enemy.cine_lock_count = 0;
    if (!variable_instance_exists(_enemy, "cine_lock_owner")) _enemy.cine_lock_owner = noone;

    _enemy.cine_lock_count += 1;
    _enemy.cine_lock_owner = _owner;

    if (variable_instance_exists(_enemy, "moving")) _enemy.moving = false;
    if (variable_instance_exists(_enemy, "move_timer")) _enemy.move_timer = 0;
    if (variable_instance_exists(_enemy, "move_dir")) _enemy.move_dir = -1;
    if (variable_instance_exists(_enemy, "ai_state")) _enemy.ai_state = ENEMY_IDLE;
    if (variable_instance_exists(_enemy, "forget_time")) _enemy.forget_time = 0;

    return true;
}

function DialogueTrigger_EnemyLockRelease(_enemy, _owner = noone) {
    if (!instance_exists(_enemy)) return;
    if (!variable_instance_exists(_enemy, "cine_lock_count")) return;

    _enemy.cine_lock_count = max(0, _enemy.cine_lock_count - 1);
    if (_enemy.cine_lock_count <= 0) {
        _enemy.cine_lock_count = 0;
        if (variable_instance_exists(_enemy, "cine_lock_owner")) _enemy.cine_lock_owner = noone;
    }
}

function UI_CinematicInputLockPush(_owner = noone) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) gs.ui = {};
    var count = 0;
    if (variable_struct_exists(gs.ui, "cinematic_input_lock_count")) {
        count = max(0, round(real(gs.ui.cinematic_input_lock_count)));
    }
    gs.ui.cinematic_input_lock_count = count + 1;
}

function UI_CinematicInputLockPop(_owner = noone) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) return;
    var count = 0;
    if (variable_struct_exists(gs.ui, "cinematic_input_lock_count")) {
        count = max(0, round(real(gs.ui.cinematic_input_lock_count)));
    }
    gs.ui.cinematic_input_lock_count = max(0, count - 1);
}

function DialogueTrigger_CleanupCinematic(_tr, _release_enemy = true, _restore_follow = true) {
    if (!instance_exists(_tr)) return;

    if (_restore_follow && variable_instance_exists(_tr, "cine_follow_suspended") && _tr.cine_follow_suspended) {
        var cam_restore = -1;
        if (variable_instance_exists(_tr, "cine_cam_id")) cam_restore = _tr.cine_cam_id;
        if (!is_undefined(cam_restore) && cam_restore != -1) {
            var restore_obj = obj_player;
            if (variable_instance_exists(_tr, "camera_restore_target_object")) {
                var ro = _tr.camera_restore_target_object;
                if (is_real(ro) && object_exists(ro)) restore_obj = ro;
            }
            camera_set_view_target(cam_restore, restore_obj);
        }
        _tr.cine_follow_suspended = false;
    }

    if (_release_enemy && variable_instance_exists(_tr, "lock_enemy_acquired") && _tr.lock_enemy_acquired) {
        if (variable_instance_exists(_tr, "lock_enemy_runtime_target") && instance_exists(_tr.lock_enemy_runtime_target)) {
            DialogueTrigger_EnemyLockRelease(_tr.lock_enemy_runtime_target, _tr);
        }
        _tr.lock_enemy_acquired = false;
    }
    if (variable_instance_exists(_tr, "cine_input_lock_acquired") && _tr.cine_input_lock_acquired) {
        UI_CinematicInputLockPop(_tr);
        _tr.cine_input_lock_acquired = false;
    }

    if (variable_instance_exists(_tr, "cine_runtime_active")) _tr.cine_runtime_active = false;
    if (variable_instance_exists(_tr, "cine_phase")) _tr.cine_phase = "";
    if (variable_instance_exists(_tr, "cine_cam_id")) _tr.cine_cam_id = -1;
    if (variable_instance_exists(_tr, "cine_target_inst")) _tr.cine_target_inst = noone;
    if (variable_instance_exists(_tr, "cine_dialogue_started")) _tr.cine_dialogue_started = false;
    if (variable_instance_exists(_tr, "cine_wait_dialogue_end")) _tr.cine_wait_dialogue_end = false;
    if (variable_instance_exists(_tr, "cine_hold_frames")) _tr.cine_hold_frames = 0;
    if (variable_instance_exists(_tr, "lock_enemy_runtime_target")) _tr.lock_enemy_runtime_target = noone;

    if (variable_instance_exists(_tr, "destroy_pending_after_cinematic") && _tr.destroy_pending_after_cinematic) {
        with (_tr) instance_destroy();
    }
}

function DialogueTrigger_BeginFollowRestoreBlend(_tr) {
    if (!instance_exists(_tr)) return false;
    if (!variable_instance_exists(_tr, "cine_follow_suspended") || !_tr.cine_follow_suspended) return false;
    if (!variable_instance_exists(_tr, "cine_cam_id")) return false;

    var cam = _tr.cine_cam_id;
    if (is_undefined(cam) || cam == -1) return false;

    var restore_obj = obj_player;
    if (variable_instance_exists(_tr, "camera_restore_target_object")) {
        var ro = _tr.camera_restore_target_object;
        if (is_real(ro) && object_exists(ro)) restore_obj = ro;
    }

    var from_x = camera_get_view_x(cam);
    var from_y = camera_get_view_y(cam);
    // Turn follow back on, but keep controlling view position during blend.
    camera_set_view_target(cam, restore_obj);

    var game_fps = max(1, game_get_speed(gamespeed_fps));
    var blend_sec = DIALOGUE_TRIGGER_CAM_RESTORE_SEC;
    if (variable_instance_exists(_tr, "camera_restore_blend_sec")) {
        blend_sec = max(0.01, real(_tr.camera_restore_blend_sec));
    }

    _tr.cine_phase = "restore_blend";
    _tr.cine_step = 0;
    _tr.cine_frames = max(1, round(blend_sec * game_fps));
    _tr.cine_from_x = from_x;
    _tr.cine_from_y = from_y;
    _tr.cine_to_x = from_x;
    _tr.cine_to_y = from_y;
    _tr.cine_follow_suspended = false;
    return true;
}

// The camera pan is skipped: follow comes back and the camera is put on the player at once. The cinematic then waits for its dialogue to end
// (like a trigger with no pan), which releases the enemy lock and the input lock as usual. Not a cut for the dialogue itself.
function DialogueTrigger_SkipPan(_tr) {
    if (!instance_exists(_tr)) return;
    var cam = _tr.cine_cam_id;
    if (!is_undefined(cam) && cam != -1) {
        if (variable_instance_exists(_tr, "cine_follow_suspended") && _tr.cine_follow_suspended) {
            var restore_obj = obj_player;
            if (variable_instance_exists(_tr, "camera_restore_target_object")) {
                var ro = _tr.camera_restore_target_object;
                if (is_real(ro) && object_exists(ro)) restore_obj = ro;
            }
            camera_set_view_target(cam, restore_obj);
            _tr.cine_follow_suspended = false;
        }
        var pl = DialogueTrigger_GetPlayerInst();
        if (instance_exists(pl)) {
            var pt = DialogueTrigger_GetTargetPoint(pl);
            var pos = DialogueTrigger_CameraPosForPoint(cam, pt.x, pt.y);
            camera_set_view_pos(cam, pos.x, pos.y);
        }
    }
    _tr.cine_cam_id = -1;
    _tr.cine_target_inst = noone;
    _tr.cine_phase = "wait_dialogue_end";
    Skip_Reset();
}

function DialogueTrigger_ApplyBlackHandoff(_tr) {
    if (!instance_exists(_tr)) return;
    DialogueTrigger_CleanupCinematic(_tr, true, true);
}

function DialogueTrigger_StartCinematic(_tr) {
    if (!instance_exists(_tr)) return;

    var release_on_fire = false;
    if (variable_instance_exists(_tr, "lock_enemy_release_on_fire")) {
        release_on_fire = _tr.lock_enemy_release_on_fire;
    }

    if (variable_instance_exists(_tr, "lock_enemy_enabled")
    && _tr.lock_enemy_enabled
    && variable_instance_exists(_tr, "lock_mode")
    && string(_tr.lock_mode) == "freeze"
    && variable_instance_exists(_tr, "lock_enemy_acquired")
    && _tr.lock_enemy_acquired
    && release_on_fire) {
        if (variable_instance_exists(_tr, "lock_enemy_runtime_target") && instance_exists(_tr.lock_enemy_runtime_target)) {
            DialogueTrigger_EnemyLockRelease(_tr.lock_enemy_runtime_target, _tr);
        }
        _tr.lock_enemy_acquired = false;
        _tr.lock_enemy_runtime_target = noone;
    }

    var keep_enemy_locked = false;
    if (variable_instance_exists(_tr, "lock_enemy_enabled")
    && _tr.lock_enemy_enabled
    && variable_instance_exists(_tr, "lock_mode")
    && string(_tr.lock_mode) == "freeze"
    && variable_instance_exists(_tr, "lock_enemy_acquired")
    && _tr.lock_enemy_acquired) {
        keep_enemy_locked = !release_on_fire;
    }

    if (!keep_enemy_locked
    && (!variable_instance_exists(_tr, "camera_focus_enabled") || !_tr.camera_focus_enabled)) {
        return;
    }

    if (!variable_instance_exists(_tr, "cine_input_lock_acquired") || !_tr.cine_input_lock_acquired) {
        UI_CinematicInputLockPush(_tr);
        _tr.cine_input_lock_acquired = true;
    }

    _tr.cine_runtime_active = true;
    _tr.cine_dialogue_started = DialogueTrigger_IsDialogueActive();
    _tr.cine_wait_dialogue_end = true;
    _tr.cine_target_inst = noone;
    _tr.cine_hold_frames = 0;

    if (!_tr.camera_focus_enabled || !view_enabled) {
        _tr.cine_phase = "wait_dialogue_end";
        return;
    }

    var cam = view_camera[0];
    if (is_undefined(cam) || cam == -1) {
        _tr.cine_phase = "wait_dialogue_end";
        return;
    }

    var target = DialogueTrigger_ResolveTargetFromConfig(_tr, "camera_focus");
    if (!instance_exists(target)) target = DialogueTrigger_GetPlayerInst();
    if (!instance_exists(target)) {
        _tr.cine_phase = "wait_dialogue_end";
        return;
    }

    var game_fps = max(1, game_get_speed(gamespeed_fps));
    var dur_in_frames = max(1, round(max(0.01, real(_tr.camera_focus_duration_in)) * game_fps));
    var hold_frames = -1;
    var hold_sec = real(_tr.camera_focus_hold);
    if (hold_sec >= 0) hold_frames = max(0, round(hold_sec * game_fps));

    var pt = DialogueTrigger_GetTargetPoint(target);
    var pos = DialogueTrigger_CameraPosForPoint(cam, pt.x, pt.y);

    _tr.cine_cam_id = cam;
    if (variable_instance_exists(_tr, "camera_suspend_follow") && _tr.camera_suspend_follow) {
        camera_set_view_target(cam, noone);
        _tr.cine_follow_suspended = true;
    }
    _tr.cine_phase = "pan_in";
    _tr.cine_step = 0;
    _tr.cine_frames = dur_in_frames;
    _tr.cine_hold_frames = hold_frames;
    _tr.cine_from_x = camera_get_view_x(cam);
    _tr.cine_from_y = camera_get_view_y(cam);
    _tr.cine_to_x = pos.x;
    _tr.cine_to_y = pos.y;
    _tr.cine_target_inst = target;
}

function DialogueTrigger_UpdateCinematic(_tr) {
    if (!instance_exists(_tr)) return;

    if (variable_instance_exists(_tr, "lock_enemy_enabled")
    && _tr.lock_enemy_enabled
    && variable_instance_exists(_tr, "lock_mode")
    && string(_tr.lock_mode) == "freeze"
    && variable_instance_exists(_tr, "trigger_enabled")
    && _tr.trigger_enabled) {
        var prevent_until_trigger = true;
        if (variable_instance_exists(_tr, "lock_enemy_prevent_until_trigger")) {
            prevent_until_trigger = _tr.lock_enemy_prevent_until_trigger;
        }
        var fired_once = false;
        if (variable_instance_exists(_tr, "trigger_fired_once") && _tr.trigger_fired_once) fired_once = true;
        if (variable_instance_exists(_tr, "trigger_once") && _tr.trigger_once && variable_instance_exists(_tr, "triggered") && _tr.triggered) {
            fired_once = true;
        }

        if ((!prevent_until_trigger || !fired_once) && !_tr.lock_enemy_acquired) {
            var lock_target = noone;
            if (variable_instance_exists(_tr, "lock_enemy_runtime_target") && instance_exists(_tr.lock_enemy_runtime_target)) {
                lock_target = _tr.lock_enemy_runtime_target;
            } else {
                lock_target = DialogueTrigger_ResolveTargetFromConfig(_tr, "lock_enemy");
                _tr.lock_enemy_runtime_target = lock_target;
            }

            if (instance_exists(lock_target)) {
                _tr.lock_enemy_acquired = DialogueTrigger_EnemyLockAcquire(lock_target, _tr);
            }
        }
    }

    if (!variable_instance_exists(_tr, "cine_runtime_active") || !_tr.cine_runtime_active) return;

    var dialogue_active = DialogueTrigger_IsDialogueActive();
    if (!_tr.cine_dialogue_started && dialogue_active) _tr.cine_dialogue_started = true;

    var cam_ok = (variable_instance_exists(_tr, "cine_cam_id") && !is_undefined(_tr.cine_cam_id) && _tr.cine_cam_id != -1);
    if (!cam_ok || !view_enabled || _tr.cine_phase == "wait_dialogue_end") {
        if (_tr.cine_dialogue_started && !dialogue_active) {
            DialogueTrigger_CleanupCinematic(_tr, true);
        }
        return;
    }

    var cam = _tr.cine_cam_id;

    // D48 / I-055: holding confirm for about a second ends the camera pan (it counts as seen; a tap only advances text).
    if (_tr.cine_phase == "pan_in" || _tr.cine_phase == "hold" || _tr.cine_phase == "pan_out") {
        Skip_Claim();
        if (Skip_Consume()) {
            DialogueTrigger_SkipPan(_tr);
            return;
        }
    }

    var ease_name = DIALOGUE_TRIGGER_EASE_DEFAULT;
    if (variable_instance_exists(_tr, "camera_ease")) ease_name = string(_tr.camera_ease);

    if (_tr.cine_phase == "pan_in") {
        var focus_inst = _tr.cine_target_inst;
        if (!instance_exists(focus_inst)) focus_inst = DialogueTrigger_GetPlayerInst();
        if (instance_exists(focus_inst)) {
            var p_focus = DialogueTrigger_GetTargetPoint(focus_inst);
            var cam_focus = DialogueTrigger_CameraPosForPoint(cam, p_focus.x, p_focus.y);
            _tr.cine_to_x = cam_focus.x;
            _tr.cine_to_y = cam_focus.y;
            _tr.cine_target_inst = focus_inst;
        }

        _tr.cine_step += 1;
        var t_in = clamp(_tr.cine_step / max(1, _tr.cine_frames), 0, 1);
        var e_in = DialogueTrigger_EaseValue(t_in, ease_name);
        var nx = lerp(_tr.cine_from_x, _tr.cine_to_x, e_in);
        var ny = lerp(_tr.cine_from_y, _tr.cine_to_y, e_in);
        camera_set_view_pos(cam, nx, ny);

        if (_tr.cine_step >= _tr.cine_frames) {
            _tr.cine_phase = "hold";
            _tr.cine_step = 0;
        }
        return;
    }

    if (_tr.cine_phase == "hold") {
        var hold_focus = _tr.cine_target_inst;
        if (!instance_exists(hold_focus)) hold_focus = DialogueTrigger_GetPlayerInst();
        if (instance_exists(hold_focus)) {
            var p_hold = DialogueTrigger_GetTargetPoint(hold_focus);
            var cam_hold = DialogueTrigger_CameraPosForPoint(cam, p_hold.x, p_hold.y);
            camera_set_view_pos(cam, cam_hold.x, cam_hold.y);
            _tr.cine_target_inst = hold_focus;
        }

        if (_tr.cine_hold_frames > 0) _tr.cine_hold_frames -= 1;
        var hold_done = (_tr.cine_hold_frames == 0 || _tr.cine_hold_frames == -1);
        var dialogue_done = (_tr.cine_dialogue_started && !dialogue_active);

        if (hold_done && dialogue_done) {
            var pl = DialogueTrigger_GetPlayerInst();
            var pout = DialogueTrigger_GetTargetPoint(pl);
            var cam_out = DialogueTrigger_CameraPosForPoint(cam, pout.x, pout.y);
            var cam_curr_x = camera_get_view_x(cam);
            var cam_curr_y = camera_get_view_y(cam);

            var fps_out = max(1, game_get_speed(gamespeed_fps));
            _tr.cine_phase = "pan_out";
            _tr.cine_step = 0;
            _tr.cine_frames = max(1, round(max(0.01, real(_tr.camera_focus_duration_out)) * fps_out));
            _tr.cine_from_x = cam_curr_x;
            _tr.cine_from_y = cam_curr_y;
            _tr.cine_to_x = cam_out.x;
            _tr.cine_to_y = cam_out.y;
        }
        return;
    }

    if (_tr.cine_phase == "pan_out") {
        _tr.cine_step += 1;
        var t_out = clamp(_tr.cine_step / max(1, _tr.cine_frames), 0, 1);
        var e_out = DialogueTrigger_EaseValue(t_out, ease_name);
        var ox = lerp(_tr.cine_from_x, _tr.cine_to_x, e_out);
        var oy = lerp(_tr.cine_from_y, _tr.cine_to_y, e_out);
        camera_set_view_pos(cam, ox, oy);

        if (_tr.cine_step >= _tr.cine_frames) {
            var use_black_handoff = true;
            if (variable_instance_exists(_tr, "camera_handoff_use_black")) {
                use_black_handoff = _tr.camera_handoff_use_black;
            }

            if (use_black_handoff) {
                var flash_out = TRANSITION_FLASH_FADE_OUT_FRAMES;
                var flash_in = TRANSITION_FLASH_FADE_IN_FRAMES;
                if (variable_instance_exists(_tr, "camera_handoff_fade_out_frames")) {
                    flash_out = max(1, round(real(_tr.camera_handoff_fade_out_frames)));
                }
                if (variable_instance_exists(_tr, "camera_handoff_fade_in_frames")) {
                    flash_in = max(1, round(real(_tr.camera_handoff_fade_in_frames)));
                }

                if (Transition_RequestBlackFlash(flash_out, flash_in, -1, "dialogue_trigger_handoff", _tr)) {
                    _tr.cine_phase = "handoff_wait";
                    return;
                }
            }

            if (!DialogueTrigger_BeginFollowRestoreBlend(_tr)) {
                DialogueTrigger_CleanupCinematic(_tr, true);
            }
        }
        return;
    }

    if (_tr.cine_phase == "handoff_wait") {
        // Safety fallback: if flash couldn't complete for any reason, still restore cleanly.
        if (!Transition_IsActive()) {
            DialogueTrigger_CleanupCinematic(_tr, true, true);
        }
        return;
    }

    if (_tr.cine_phase == "restore_blend") {
        // Sample the engine's follow result and blend from cinematic->follow each step.
        var follow_x = camera_get_view_x(cam);
        var follow_y = camera_get_view_y(cam);
        _tr.cine_step += 1;
        var t_rb = clamp(_tr.cine_step / max(1, _tr.cine_frames), 0, 1);
        var e_rb = DialogueTrigger_EaseValue(t_rb, ease_name);
        var rx = lerp(_tr.cine_from_x, follow_x, e_rb);
        var ry = lerp(_tr.cine_from_y, follow_y, e_rb);
        camera_set_view_pos(cam, rx, ry);

        if (_tr.cine_step >= _tr.cine_frames) {
            // Follow is already active; stop manual override cleanly.
            DialogueTrigger_CleanupCinematic(_tr, true, false);
        }
    }
}


function UI_IsBlocking() {
    if (Transition_IsInputLocked()) return true;
    if (Tutorial_IsOpen() || Tutorial_JustClosed()) return true;   // D45: a tutorial pop-up stops the world until it is dismissed
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !is_struct(gs.ui)) return false;
    if (variable_struct_exists(gs.ui, "mode") && gs.ui.mode != UI_NONE) return true;
    if (variable_struct_exists(gs.ui, "lines") && is_array(gs.ui.lines) && array_length(gs.ui.lines) > 0) return true;
    if (variable_struct_exists(gs.ui, "dialogue_lock") && gs.ui.dialogue_lock > 0) return true;
    if (variable_struct_exists(gs.ui, "cinematic_input_lock_count") && gs.ui.cinematic_input_lock_count > 0) return true;
    return false;
}

function UI_GetTextScale() {
    // Integer UI-grid rule (display-design.md section 2): the pixel font lands on whole window pixels.
    // n = window pixels per font pixel, a multiple of the GUI unit (ui_scale); the text scale follows from the font's own pixel (DISPLAY_FONT_PX).
    var _l = Display_Layout();
    var _u = _l.ui_scale;
    var _n = max(_u, round(round(0.8 * _l.scale) / _u) * _u);
    return clamp(_n / (DISPLAY_FONT_PX * _u), UI_TEXT_SCALE_MIN, UI_TEXT_SCALE_MAX);
}

function UI_GetVisualScale() {
    var base = max(0.0001, UI_TEXT_SCALE_BASE);
    return max(0.5, UI_GetTextScale() / base);
}

function UI_GetSpriteScale(_base = 1) {
    var mul = max(0.0001, real(_base));
    var step = max(1, ceil(UI_GetVisualScale()));
    return max(1, round(mul * step));
}

// The scale text is DRAWN at. English: the integer rule above. Korean (D98): Galmuri is added at its final window-pixel size
// (a whole multiple of its native 9 or 11 px, UI_KoFont), so it is drawn at 1 texel = 1 window pixel = 1 / ui_scale GUI units.
// Cached per (layout struct, language): Display_Relayout makes a new layout struct and Loc_SetLanguage changes the language string, so either rebuilds it.
function UI_GetFontScale() {
    var _l = Display_Layout();
    var _lang = Loc_GetLanguage();
    var _c = variable_global_exists("ui_fs_cache") ? global.ui_fs_cache : undefined;
    if (is_struct(_c) && _c.layout == _l && _c.lang == _lang) return _c.scale;
    var _s = UI_FontScaleBuild();
    global.ui_fs_cache = { layout: _l, lang: _lang, scale: _s };
    return _s;
}

// The uncached computation of UI_GetFontScale. Counted (UI_FontScaleBuilds) so a check can see how often it runs.
function UI_FontScaleBuild() {
    if (!variable_global_exists("ui_fs_builds")) global.ui_fs_builds = 0;
    global.ui_fs_builds++;
    if (Loc_GetLanguage() == "ko" && UI_KoFont() != -1) return 1 / Display_Layout().ui_scale;
    return UI_GetTextScale();
}

function UI_FontScaleBuilds() {
    return variable_global_exists("ui_fs_builds") ? global.ui_fs_builds : 0;
}

function UI_TextWidth(_txt) {
    var s = UI_GetFontScale();
    return max(0, round(string_width(string(_txt)) * s));
}

function UI_TextHeight(_txt = "A") {
    var s = UI_GetFontScale();
    return max(1, round(string_height(string(_txt)) * s));
}

function UI_DrawText(_x, _y, _txt) {
    var s = UI_GetFontScale();
    draw_text_transformed(real(_x), real(_y), string(_txt), s, s, 0);
}

function UI_DrawTextTransformed(_x, _y, _txt, _xscale, _yscale, _angle) {
    var s = UI_GetFontScale();
    draw_text_transformed(real(_x), real(_y), string(_txt), real(_xscale) * s, real(_yscale) * s, real(_angle));
}

// The Korean UI font (D98): Galmuri9 or Galmuri11 (SIL OFL, Included Files at fonts/galmuri) added at the whole multiple of its
// native size that matches the English line height in window pixels. One font per size is cached. -1 when the file is missing.
function UI_KoFont() {
    var l = Display_Layout();
    var sig = l.scale * 100 + l.ui_scale;
    if (variable_global_exists("ui_ko_sig") && global.ui_ko_sig == sig) return global.ui_ko_cur;   // same layout as the last call
    if (!variable_global_exists("ui_ko_fonts") || !is_struct(global.ui_ko_fonts)) global.ui_ko_fonts = {};
    if (!variable_global_exists("ui_en_line_px")) {
        var f0 = draw_get_font();
        draw_set_font(UI_FONT);
        global.ui_en_line_px = string_height("A");   // the English font's line height at text scale 1.0, in window pixels
        draw_set_font(f0);
    }
    var target = global.ui_en_line_px * UI_GetTextScale() * l.ui_scale;
    var ch = Ui_KoFontChoice(target);
    var key = "g" + string(ch.face) + "x" + string(ch.k);
    var f = -1;
    if (variable_struct_exists(global.ui_ko_fonts, key)) {
        f = variable_struct_get(global.ui_ko_fonts, key);
    } else {
        var path = "fonts/galmuri/Galmuri" + string(ch.face) + ".ttf";
        if (file_exists(path)) {
            var t0 = current_time;
            f = font_add(path, ch.px * 0.75, false, false, 32, 55203);   // points = pixels * 0.75
            show_debug_message("[UI] Galmuri" + string(ch.face) + " x" + string(ch.k) + " (" + string(ch.px) + " px) font " + string(f) + " added in " + string(current_time - t0) + " ms");
        } else {
            show_debug_message("[UI] Korean font file missing: " + path);
        }
        variable_struct_set(global.ui_ko_fonts, key, f);   // a miss is cached too: no retry every frame
    }
    global.ui_ko_sig = sig;
    global.ui_ko_cur = f;
    return f;
}

function UI_SetFont() {
    var font_to_use = UI_FONT;
    if (Loc_GetLanguage() == "ko") {
        var fk = UI_KoFont();
        if (fk != -1) font_to_use = fk;
    }
    draw_set_font(font_to_use);
}

// _fade_dim is kept for the callers: the modal dim it used to fade out is gone (every screen draws its own backdrop).
function UI_InterruptCloseAll(_fade_dim = true) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};

    // Immediately hide all modal/popups to avoid stale mode locks during transitions.
    if (is_struct(TabMenu_Get())) {   // D1b: the Tab menu and the pause menu are framework screens held in globals
        TabSettings_Discard();
        global.tab_ui = undefined;
    }
    if (is_struct(PauseMenu_Get())) global.pause_ui = undefined;

    Notice_Interrupt();

    CardsUi_Interrupt();   // C2: what is owed opens again afterwards
    BedUi_Interrupt();     // C4: the bed stays free
    ShopUi_Interrupt();    // C3

    if (variable_struct_exists(gs.ui, "settings_popup") && is_struct(gs.ui.settings_popup)) {
        var sp = gs.ui.settings_popup;
        sp.open = false;
        sp.owner = "";
        sp.closing = false;
        sp.closed_ms = -1;
        sp.dirty = false;
        sp.menu = undefined;
        gs.ui.settings_popup = sp;
    }

    if (gs.ui.mode != UI_DIALOGUE) {
        gs.ui.mode = UI_NONE;
    }
}

function Action_CanAct(_pl) {
    if (UI_IsBlocking()) return false;
    return Player_CanAcceptMove(_pl);
}

function Action_Request(_pl, _action) {
    var gs = GameState_Get();

    // UI open means input is blocked.
    if (gs.ui.mode != UI_NONE || array_length(gs.ui.lines) > 0) {
        return false;
    }

    // Only allow discrete press when the player can act.
    if (!Player_CanAcceptMove(_pl)) {
        return false;
    }

    return Input_Pressed(_action);
}

function GameSettings_ToReal(_value, _fallback) {
    if (is_real(_value)) return _value;
    if (is_string(_value)) return real(_value);
    if (_value == true) return 1;
    if (_value == false) return 0;
    return _fallback;
}

function GameSettings_NormalizeLanguage(_lang) {
    var code = string_lower(string(_lang));
    if (code == "ko") return "ko";
    return "en";
}

function GameSettings_Defaults() {
    return {
        audio_ui: VOL_UI_DEFAULT,
        audio_sfx: VOL_SFX_DEFAULT,
        audio_bgm: VOL_MUSIC_DEFAULT,
        display_scale: DISPLAY_SCALE_DEFAULT,
        window_mode: WINDOW_MODE_BORDERLESS,   // D91: first launch is borderless fullscreen (settings_version 8 replaced fit_screen)
        language: "en",
        text_speed: 1,    // settings_version 9 (D0): 0 slow, 1 normal, 2 fast (Settings_TextSpeedMul)
        screen_shake: 1,  // 1 on, 0 off
        qte_assist: 0,    // 1 on: zones x1.5 and arrow time x1.3 (D35, Qte_AssistMult / Qte_AssistTimeMultNow)
        keys: Binds_Defaults()   // settings_version 10 (D49): the keyboard keys per rebindable action (scr_input, Binds_*)
    };
}

function GameSettings_Normalize(_settings) {
    var out = GameSettings_Defaults();
    if (is_struct(_settings)) {
        if (variable_struct_exists(_settings, "audio_ui")) out.audio_ui = _settings.audio_ui;
        if (variable_struct_exists(_settings, "audio_sfx")) out.audio_sfx = _settings.audio_sfx;
        if (variable_struct_exists(_settings, "audio_bgm")) out.audio_bgm = _settings.audio_bgm;
        if (variable_struct_exists(_settings, "display_scale")) out.display_scale = _settings.display_scale;
        if (variable_struct_exists(_settings, "window_mode")) out.window_mode = _settings.window_mode;
        else if (variable_struct_exists(_settings, "fit_screen")) out.window_mode = Display_ModeFromLegacy(GameSettings_ToReal(_settings.fit_screen, 0) != 0);   // an old struct
        if (variable_struct_exists(_settings, "language")) out.language = _settings.language;
        if (variable_struct_exists(_settings, "text_speed")) out.text_speed = _settings.text_speed;
        if (variable_struct_exists(_settings, "screen_shake")) out.screen_shake = _settings.screen_shake;
        if (variable_struct_exists(_settings, "qte_assist")) out.qte_assist = _settings.qte_assist;
        if (variable_struct_exists(_settings, "keys")) out.keys = _settings.keys;
    }

    out.audio_ui = clamp(GameSettings_ToReal(out.audio_ui, VOL_UI_DEFAULT), 0, 1);
    out.audio_sfx = clamp(GameSettings_ToReal(out.audio_sfx, VOL_SFX_DEFAULT), 0, 1);
    out.audio_bgm = clamp(GameSettings_ToReal(out.audio_bgm, VOL_MUSIC_DEFAULT), 0, 1);
    out.display_scale = clamp(round(GameSettings_ToReal(out.display_scale, DISPLAY_SCALE_DEFAULT)), DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
    out.window_mode = Display_NormalizeMode(out.window_mode);
    out.language = GameSettings_NormalizeLanguage(out.language);
    out.text_speed = clamp(round(GameSettings_ToReal(out.text_speed, 1)), 0, SETTINGS_TEXT_SPEED_MAX);
    out.screen_shake = (GameSettings_ToReal(out.screen_shake, 1) != 0) ? 1 : 0;
    out.qte_assist = (GameSettings_ToReal(out.qte_assist, 0) != 0) ? 1 : 0;
    out.keys = Binds_Normalize(out.keys);
    return out;
}

function GameSettings_Copy(_settings) {
    return GameSettings_Normalize(_settings);
}

function GameSettings_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "settings") || !is_struct(gs.settings)) {
        gs.settings = GameSettings_Defaults();
    }
    gs.settings = GameSettings_Normalize(gs.settings);
    return gs.settings;
}

function GameSettings_ApplyAudio() {
    var settings = GameSettings_Ensure();
    Audio_SetUIVolume(settings.audio_ui);
    Audio_SetSFXVolume(settings.audio_sfx);
    Audio_SetMusicVolume(settings.audio_bgm);
}

function GameSettings_ApplyAll() {
    var settings = GameSettings_Ensure();
    Loc_SetLanguage(settings.language);
    GameSettings_ApplyAudio();
    Binds_Apply(settings.keys);   // D49: the player's keys
}

// Settings > Apply: the only caller that asks the display for something (boot does the same from Display_Init).
function GameSettings_ApplyDisplayRequest() {
    var settings = GameSettings_Ensure();
    Display_Request({ mode: settings.window_mode, scale: settings.display_scale });
}

function GameSettings_Commit(_settings, _save_config = false) {
    var gs = GameState_Get();
    gs.settings = GameSettings_Normalize(_settings);
    GameState_SyncLegacy();
    GameSettings_ApplyAll();
    GameSettings_ApplyDisplayRequest();
    if (_save_config) {
        Save_WriteSettingsConfig(gs.settings);
    }
    return gs.settings;
}

// --------------------
// GAME STATE
// --------------------
function GameState_Init() {
    if (!variable_global_exists("state") || !is_struct(global.state)) {
        global.state = {};
    }

    var gs = global.state;

    Input_Init();
    Loc_Init();

    if (!variable_global_exists("rng_inited") || !global.rng_inited) {
        randomize();
        global.rng_inited = true;
    }

    if (!variable_struct_exists(gs, "selected_class")) {
        gs.selected_class = CLASS_NOBODY;
    }

    if (!variable_struct_exists(gs, "difficulty")) {
        gs.difficulty = DIFFICULTY_NORMAL;
    }
    gs.difficulty = Difficulty_Normalize(gs.difficulty);

    if (!variable_struct_exists(gs, "defeated_enemies")) {
        gs.defeated_enemies = ds_list_create();
    }

    if (!variable_struct_exists(gs, "uid_counter")) {
        gs.uid_counter = 1;
    }

    if (!variable_struct_exists(gs, "item_db")) {
        ItemDB_Init();
        gs.item_db = global.item_db;
    }

    if (!variable_struct_exists(gs, "player_ch")) {
        gs.player_ch = CharacterCreate_Player(gs.selected_class);
    }
    if (is_struct(gs.player_ch)) {
        if (!variable_struct_exists(gs.player_ch, "class_id")) gs.player_ch.class_id = gs.selected_class;
        gs.player_ch = Player_NormalizeProgression(gs.player_ch, true);
        gs.selected_class = gs.player_ch.class_id;
    }

    if (!variable_struct_exists(gs, "enemy_db")) {
        EnemyDB_Init();
        gs.enemy_db = global.enemy_db;
    }

    if (!variable_struct_exists(gs, "skill_db")) {
        SkillDB_Init();
        gs.skill_db = global.skill_db;
    }

    if (!variable_struct_exists(gs, "status_db")) {
        StatusDB_Init();
        gs.status_db = global.status_db;
    }

    if (!variable_struct_exists(gs, "dialogue_db")) {
        DialogueDB_Init();
        gs.dialogue_db = global.dialogue_db;
    }

    if (!variable_struct_exists(gs, "enemy_reset_version")) {
        gs.enemy_reset_version = 0;
    }

    if (!variable_struct_exists(gs, "boss_defeated") || !is_struct(gs.boss_defeated)) {
        gs.boss_defeated = { mini_boss: false, final_boss: false };
    }

    if (!variable_struct_exists(gs, "loot_tables")) {
        Loot_Init();
        gs.loot_tables = global.loot_tables;
        gs.loot_configs = global.loot_configs;
        gs.loot_tier_weights = global.loot_tier_weights;
    }


    if (!variable_struct_exists(gs, "battle")) {
        gs.battle = {
            return_room: noone,
            return_x: 0,
            return_y: 0,
            enemy_persist_id: "",
            enemy_id: -1,
            enemy_level: 0,
            enemy_room: noone,
            just_returned: false
        };
    }
    if (!variable_struct_exists(gs.battle, "enemy_level")) gs.battle.enemy_level = 0;

    if (!variable_struct_exists(gs, "player_inst")) {
        gs.player_inst = noone;
    }

    if (!variable_struct_exists(gs, "flags")) {
        gs.flags = {};
    }
    var skillbook_done_key = Dialogue_SkillbookFirstReadDoneFlagKey();
    var skillbook_pending_key = Dialogue_SkillbookFirstReadPendingFlagKey();
    if (!variable_struct_exists(gs.flags, skillbook_done_key)) variable_struct_set(gs.flags, skillbook_done_key, false);
    if (!variable_struct_exists(gs.flags, skillbook_pending_key)) variable_struct_set(gs.flags, skillbook_pending_key, false);
    if (variable_struct_get(gs.flags, skillbook_pending_key)) variable_struct_set(gs.flags, skillbook_pending_key, false);

    if (!variable_struct_exists(gs, "save_slot")) {
        gs.save_slot = 0;
    }

    if (!variable_struct_exists(gs, "skip_room_save")) {
        gs.skip_room_save = false;
    }

    if (!variable_struct_exists(gs, "checkpoint")) {
        gs.checkpoint = { room: rm_floor2, x: 32, y: 128 };
    }

    if (!variable_struct_exists(gs, "settings") || !is_struct(gs.settings)) {
        gs.settings = GameSettings_Defaults();
    }
    if (!variable_struct_exists(gs, "settings_boot_loaded") || !gs.settings_boot_loaded) {
        var boot_settings = Save_LoadLatestSettings();
        if (is_struct(boot_settings)) gs.settings = boot_settings;
        gs.settings_boot_loaded = true;
    }
    gs.settings = GameSettings_Normalize(gs.settings);
    Loc_SetLanguage(gs.settings.language);

    if (!variable_struct_exists(gs, "ui")) {
        gs.ui = {
            mode: 0,
            lines: [],
            lines_raw: [],
            index: 0,
            speaker: "",
            cutscene_text_only: false,
            confirm_action: "",
            icon_frame: 0,
            opened_frame: UI_OPENED_FRAME_NONE,
            dialogue_lock: 0,
            dialogue_require_release: false,
            dialogue_full_text: "",
            dialogue_visible_count: 0,
            dialogue_reveal_accum: 0,
            dialogue_chars_per_sec: UI_DIALOGUE_CHARS_PER_SEC,
            dialogue_state: UI_DIALOGUE_STATE_REVEALING,
            dialogue_hold_ms: 0,
            dialogue_hold_duration_ms: 0,
            dialogue_tw_line_index: -1,
            dialogue_open_lock: undefined,
            cinematic_input_lock_count: 0
        };
    }
    if (!variable_struct_exists(gs.ui, "opened_frame")) gs.ui.opened_frame = UI_OPENED_FRAME_NONE;
    if (!variable_struct_exists(gs.ui, "dialogue_lock")) gs.ui.dialogue_lock = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_require_release")) gs.ui.dialogue_require_release = false;
    if (!variable_struct_exists(gs.ui, "dialogue_full_text")) gs.ui.dialogue_full_text = "";
    if (!variable_struct_exists(gs.ui, "dialogue_visible_count")) gs.ui.dialogue_visible_count = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_reveal_accum")) gs.ui.dialogue_reveal_accum = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_chars_per_sec")) gs.ui.dialogue_chars_per_sec = UI_DIALOGUE_CHARS_PER_SEC;
    if (!variable_struct_exists(gs.ui, "dialogue_state")) gs.ui.dialogue_state = UI_DIALOGUE_STATE_REVEALING;
    if (!variable_struct_exists(gs.ui, "dialogue_hold_ms")) gs.ui.dialogue_hold_ms = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_hold_duration_ms")) gs.ui.dialogue_hold_duration_ms = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_tw_line_index")) gs.ui.dialogue_tw_line_index = -1;
    if (!variable_struct_exists(gs.ui, "dialogue_open_lock")) gs.ui.dialogue_open_lock = undefined;
    if (!variable_struct_exists(gs.ui, "cinematic_input_lock_count")) gs.ui.cinematic_input_lock_count = 0;
    gs.ui.cinematic_input_lock_count = max(0, round(real(gs.ui.cinematic_input_lock_count)));
    if (!variable_struct_exists(gs.ui, "lines_raw") || !is_array(gs.ui.lines_raw)) gs.ui.lines_raw = [];
    if (!variable_struct_exists(gs.ui, "cutscene_text_only")) gs.ui.cutscene_text_only = false;
    var skillbook_ui_key = Dialogue_SkillbookFirstReadUIActiveKey();
    if (!variable_struct_exists(gs.ui, skillbook_ui_key)) variable_struct_set(gs.ui, skillbook_ui_key, false);
    var dialogue_ambience_key = Dialogue_ActiveAmbienceUIKey();
    if (!variable_struct_exists(gs.ui, dialogue_ambience_key)) variable_struct_set(gs.ui, dialogue_ambience_key, "");

    if (!variable_struct_exists(gs, "in_main_menu")) {
        gs.in_main_menu = false;
    }

    if (!variable_struct_exists(gs, "pending_cutscene_id")) {
        gs.pending_cutscene_id = "";
    }
    if (!variable_struct_exists(gs, "pending_post_battle_dialogue_lines") || !is_array(gs.pending_post_battle_dialogue_lines)) {
        gs.pending_post_battle_dialogue_lines = [];
    }

    if (!variable_struct_exists(gs, "transition")) {
        gs.transition = { pending: false, room: noone, spawn_id: "", face: -1 };
    }

    if (!variable_struct_exists(gs, "room_states")) {
        gs.room_states = {};
    }

    RoomDB_Init();

    if (!variable_struct_exists(gs, "last_room")) {
        gs.last_room = room;
    }

    RoomState_Init();

    GameState_SyncLegacy();

    return gs;
}

function GameState_Get() {
    if (!variable_global_exists("state") || !is_struct(global.state)) {
        return GameState_Init();
    }

    return global.state;
}

function GameState_NextUID() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "uid_counter")) gs.uid_counter = 1;
    var uid = gs.uid_counter;
    gs.uid_counter += 1;
    return uid;
}

function GameState_SyncLegacy() {
    var gs = global.state;

    Input_Init();

    if (variable_struct_exists(gs, "item_db")) {
        global.item_db = gs.item_db;
    }

    if (variable_struct_exists(gs, "enemy_db")) {
        global.enemy_db = gs.enemy_db;
    }

    if (variable_struct_exists(gs, "skill_db")) {
        global.skill_db = gs.skill_db;
    }

    if (variable_struct_exists(gs, "status_db")) {
        global.status_db = gs.status_db;
    }

    if (variable_struct_exists(gs, "dialogue_db")) {
        global.dialogue_db = gs.dialogue_db;
    }
}

function GameState_SetSelectedClass(_class_id) {
    var gs = GameState_Get();
    gs.selected_class = _class_id;
}

function GameState_SetPlayer(_ch) {
    if (is_struct(_ch)) _ch = Player_NormalizeProgression(_ch, true);
    var gs = GameState_Get();
    gs.player_ch = _ch;
}

function GameState_SetPlayerInst(_inst) {
    var gs = GameState_Get();
    gs.player_inst = _inst;
}

function GameState_SetBattleReturn(_room, _x, _y, _face, _snap_to_grid = true) {
    var gs = GameState_Get();
    if (_snap_to_grid) {
        var tile = GRID_TILE_SIZE;
        _x = round(_x / tile) * tile;
        _y = round(_y / tile) * tile;
    }
    gs.battle.return_room = _room;
    gs.battle.return_x = _x;
    gs.battle.return_y = _y;
    gs.battle.return_face = (argument_count >= 4) ? _face : -1;
}

function GameState_SetBattleEnemy(_persist_id, _enemy_id, _enemy_level = 0) {
    var gs = GameState_Get();
    gs.battle.enemy_persist_id = _persist_id;
    gs.battle.enemy_id = _enemy_id;
    gs.battle.enemy_level = max(0, round(_enemy_level));
    gs.battle.enemy_room = room;
    gs.battle.enemy_elite = "";   // C3 (D86): EnemyPersist_BeginEncounter sets the map enemy's modifier after this

    // Entering battle should not leave any lingering modal/dim state behind.
    UI_InterruptCloseAll(true);
}

function GameState_SetJustReturned(_flag) {
    var gs = GameState_Get();
    gs.battle.just_returned = _flag;
}

function GameState_SetCheckpoint(_room, _x, _y) {
    var gs = GameState_Get();
    gs.checkpoint.room = _room;
    gs.checkpoint.x = _x;
    gs.checkpoint.y = _y;
}

function Player_LearnSkill(_ch, _skill_id) {
    if (!is_array(_ch.skills)) _ch.skills = [];
    var exists = false;
    for (var i = 0; i < array_length(_ch.skills); i++) {
        if (_ch.skills[i] == _skill_id) {
            exists = true;
            break;
        }
    }
    if (!exists) {
        array_push(_ch.skills, _skill_id);
    }
    return _ch;
}
