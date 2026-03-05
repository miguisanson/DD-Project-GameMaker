function Combat_Initiative(_ch) {
    return RollD20() + StatMod(Combat_EffectiveStat(_ch, STAT_AGI));
}

function Combat_EffectiveStat(_ch, _stat_id) {
    return max(1, round(Stat_Get(_ch, _stat_id)));
}

function Combat_EffectiveDamageMult(_attacker) {
    var diff = Difficulty_Profile();
    if (variable_struct_exists(_attacker, "is_player") && _attacker.is_player) {
        return diff.player_damage_mult;
    }
    return diff.enemy_damage_mult;
}

function Combat_EffectiveEnemyStatusChanceMult() {
    var diff = Difficulty_Profile();
    return diff.enemy_status_chance_mult;
}

function Combat_AttackBonus(_attacker, _weapon) {
    // Minimal version: MOD(relevant) + weapon.acc
    var rel_mod = 0;
    switch (_weapon.stat_type) {
        case STAT_STR:  rel_mod = StatMod(Combat_EffectiveStat(_attacker, STAT_STR)); break;
        case STAT_AGI:  rel_mod = StatMod(Combat_EffectiveStat(_attacker, STAT_AGI)); break;
        case STAT_INT:  rel_mod = StatMod(Combat_EffectiveStat(_attacker, STAT_INT)); break;
        default:        rel_mod = 0; break;
    }
    return rel_mod + _weapon.acc;
}

function Combat_DodgeBonus(_defender) {
    return StatMod(Combat_EffectiveStat(_defender, STAT_AGI)) + Status_GetSum(_defender, "dodge_bonus");
}

function Combat_CritCheck(_attacker, _crit_bonus) {
    // Base 5% crit, bonus from LUCK and any explicit crit bonus (percent).
    var luck_mod = StatMod(Combat_EffectiveStat(_attacker, STAT_LUCK));
    if (luck_mod < 0) luck_mod = 0;
    var crit_chance = 0.05 + (luck_mod * 0.01) + (_crit_bonus * 0.01);
    crit_chance = clamp(crit_chance, 0.05, 0.50); // 5% to 50% max
    return (random(1) < crit_chance);
}

function Combat_Damage(_attacker, _defender, _weapon) {
    var rel_mod = 0;
    switch (_weapon.stat_type) {
        case STAT_STR: rel_mod = StatMod(Combat_EffectiveStat(_attacker, STAT_STR)); break;
        case STAT_AGI: rel_mod = StatMod(Combat_EffectiveStat(_attacker, STAT_AGI)); break;
        case STAT_INT: rel_mod = StatMod(Combat_EffectiveStat(_attacker, STAT_INT)); break;
        default: rel_mod = 0; break;
    }

    var raw = _weapon.power + rel_mod;

    // softened mitigation: use half of DEF mod (rounded down)
    var mitig = floor(StatMod(Combat_EffectiveStat(_defender, STAT_DEF)) / 2);

    var final = max(1, raw - mitig);
    return final;
}

function Combat_AttemptHit(_attacker, _defender, _acc_bonus) {
    var res = { hit: false, forced: false, attacker: _attacker, defender: _defender };

    if (Status_HasFlag(_defender, "force_dodge")) {
        res.hit = false;
        res.forced = true;
        res.defender = Status_ConsumeByField(_defender, "consume_on_defend");
        return res;
    }

    if (Status_HasFlag(_attacker, "always_hit")) {
        res.hit = true;
        res.forced = true;
        return res;
    }

    var hit_roll = RollD20() + _acc_bonus;
    var dodge_roll = RollD20() + Combat_DodgeBonus(_defender);
    res.hit = (hit_roll >= dodge_roll);
    return res;
}

function Combat_ApplyDamage(_attacker, _defender, _weapon, _crit_mult, _skill_mult) {
    var dmg = Combat_Damage(_attacker, _defender, _weapon);

    var dmg_mult = Status_GetMul(_attacker, "dmg_mult");
    if (dmg_mult != 1) dmg = floor(dmg * dmg_mult);

    if (argument_count >= 5) dmg = floor(dmg * _skill_mult);
    if (argument_count >= 4) dmg = floor(dmg * _crit_mult);

    var guard_mult = Status_GetMul(_defender, "guard_mult");
    if (guard_mult != 1) {
        dmg = floor(dmg * guard_mult);
        _defender = Status_ConsumeByField(_defender, "consume_on_hit");
    }

    var diff_mult = Combat_EffectiveDamageMult(_attacker);
    if (diff_mult != 1) dmg = floor(dmg * diff_mult);

    var dmg_ctx = {};
    if (argument_count >= 6 && is_struct(argument[5])) dmg_ctx = argument[5];
    if (!variable_struct_exists(dmg_ctx, "is_skill")) dmg_ctx.is_skill = false;

    // FUN-FIRST passives: let equipped armor mitigate incoming enemy damage.
    if (is_struct(_attacker) && is_struct(_defender)
    && variable_struct_exists(_attacker, "is_player") && !(_attacker.is_player)
    && variable_struct_exists(_defender, "is_player") && _defender.is_player) {
        dmg_ctx.from_enemy = true;
        dmg_ctx.hp_before = _defender.hp;
        dmg -= Equip_PlayerIncomingDamageReduction(_defender, dmg, dmg_ctx);
    }

    dmg = max(0, dmg);
    _defender.hp = max(0, _defender.hp - dmg);

    if (is_struct(_attacker) && is_struct(_defender)
    && variable_struct_exists(_attacker, "is_player") && !(_attacker.is_player)
    && variable_struct_exists(_defender, "is_player") && _defender.is_player) {
        _defender = Equip_PlayerAfterTakeDamage(_defender, dmg, dmg_ctx);
    }

    return { dmg: dmg, defender: _defender };
}

function FX_Spawn(_sprite, _x, _y, _frames, _speed) {
    if (_sprite == noone) return noone;
    var fx = instance_create_layer(_x, _y, "Instances", obj_fx);
    fx.sprite_index = _sprite;
    fx.image_xscale = SKILL_FX_SCALE;
    fx.image_yscale = SKILL_FX_SCALE;
    if (room == rm_battle) fx.visible = false;

    var spd = _speed;
    if (!is_real(spd) || spd <= 0) {
        spd = sprite_get_speed(_sprite);
        if (sprite_get_speed_type(_sprite) == SPR_SPEED_FPS) {
            var game_fps = game_get_speed(gamespeed_fps);
            if (game_fps <= 0) game_fps = 60;
            spd = spd / game_fps;
        }
    }
    if (spd <= 0) spd = 0.2;

    fx.image_index = 0;
    fx.image_speed = spd;
    fx.fx_prev_frame = 0;
    fx.fx_age = 0;
    return fx;
}

function FX_CenterOn(_sprite, _inst) {
    var cx = _inst.x;
    var cy = _inst.y;
    if (instance_exists(_inst)) {
        var ispr = _inst.sprite_index;
        if (ispr != noone) {
            var sx = abs(_inst.image_xscale);
            var sy = abs(_inst.image_yscale);
            var iw = sprite_get_width(ispr) * sx;
            var ih = sprite_get_height(ispr) * sy;
            var iox = sprite_get_xoffset(ispr) * sx;
            var ioy = sprite_get_yoffset(ispr) * sy;
            cx = _inst.x - iox + (iw * 0.5);
            cy = _inst.y - ioy + (ih * 0.5);
        }
    }
    if (_sprite == noone) return { x: cx, y: cy };
    var fx_scale = max(0.01, abs(SKILL_FX_SCALE));
    var w = sprite_get_width(_sprite);
    var h = sprite_get_height(_sprite);
    var ox = sprite_get_xoffset(_sprite);
    var oy = sprite_get_yoffset(_sprite);
    return {
        x: cx - ((w * 0.5 - ox) * fx_scale),
        y: cy - ((h * 0.5 - oy) * fx_scale)
    };
}

function Combat_Log(_text, _icon_sprite = noone, _icon_subimg = 0) {
    var entry = _text;
    if (is_struct(_text) && variable_struct_exists(_text, "text")) {
        entry = _text;
    } else {
        if (string(_text) == "") return;
        entry = {
            text: string(_text),
            icon_sprite: _icon_sprite,
            icon_subimg: _icon_subimg
        };
    }

    var bc = instance_find(obj_battle_controller, 0);
    if (!instance_exists(bc)) return;
    if (!variable_instance_exists(bc, "combat_log") || !is_array(bc.combat_log)) {
        bc.combat_log = [];
    }
    var log = bc.combat_log;
    array_push(log, entry);
    var maxv = COMBAT_LOG_MAX;
    while (array_length(log) > maxv) {
        array_delete(log, 0, 1);
    }
    bc.combat_log = log;
}

function Battle_Message(_bc, _text, _next_state, _fx = noone) {
    _bc.message_text = _text;
    _bc.message_next_state = _next_state;
    _bc.battle_state = BSTATE_MESSAGE;
    _bc.wait_fx = _fx;
    _bc.wait_timer = COMBAT_ACTION_DELAY;
    Combat_Log(_text);
}

function Battle_LootAppendNormalized(_dest, _src) {
    var out = _dest;
    if (!is_array(out)) out = [];
    if (!is_array(_src)) return out;

    for (var i = 0; i < array_length(_src); i++) {
        var it = _src[i];
        if (!is_struct(it) || !variable_struct_exists(it, "id")) continue;
        var iid = round(real(it.id));
        var qty = variable_struct_exists(it, "qty") ? max(0, round(real(it.qty))) : 0;
        if (qty <= 0) continue;

        var merged = false;
        for (var j = 0; j < array_length(out); j++) {
            if (!is_struct(out[j]) || !variable_struct_exists(out[j], "id")) continue;
            if (out[j].id != iid) continue;
            var prev_qty = variable_struct_exists(out[j], "qty") ? max(0, round(real(out[j].qty))) : 0;
            out[j].qty = prev_qty + qty;
            merged = true;
            break;
        }

        if (!merged) array_push(out, { id: iid, qty: qty });
    }

    return out;
}

function Battle_GrantRewards(_p, _e) {
    var out = {
        player: _p,
        exp_gain: 0,
        levels_gained: 0,
        stat_points_gained: 0,
        auto_stat_id: -1,
        auto_stat_gained: 0,
        auto_stat_summary: "",
        loot: []
    };

    if (is_struct(_e)) {
        if (variable_struct_exists(_e, "exp")) {
            var exp_gain = max(0, round(real(_e.exp)));
            if (variable_struct_exists(_p, "level") && Level_IsAtCap(_p.level)) {
                exp_gain = 0;
            }
            if (exp_gain > 0) {
                var diff = Difficulty_Profile();
                var exp_mult = 1;
                if (is_struct(diff) && variable_struct_exists(diff, "player_exp_mult")) {
                    exp_mult = max(0, real(diff.player_exp_mult));
                }
                exp_gain = max(1, round(exp_gain * exp_mult));
                _p = Player_AddExp(_p, exp_gain);
                out.exp_gain = exp_gain;
                if (variable_struct_exists(_p, "last_levels_gained")) out.levels_gained = _p.last_levels_gained;
                if (variable_struct_exists(_p, "last_stat_points_gained")) out.stat_points_gained = _p.last_stat_points_gained;
                if (variable_struct_exists(_p, "last_auto_stat_id")) out.auto_stat_id = _p.last_auto_stat_id;
                if (variable_struct_exists(_p, "last_auto_stat_gained")) out.auto_stat_gained = _p.last_auto_stat_gained;
                out.auto_stat_summary = LevelUp_AutoGainSummary(_p);
            }
        }

        // shared loot system
        var loot = Loot_RollEnemy(_e);
        var recovered_loot = [];
        if (variable_struct_exists(_e, "stolen_items") && is_array(_e.stolen_items)) {
            recovered_loot = Battle_LootAppendNormalized([], _e.stolen_items);
            _e.stolen_items = [];
        }

        _p.inventory = Loot_Grant(_p.inventory, loot);
        _p.inventory = Loot_Grant(_p.inventory, recovered_loot);

        out.loot = [];
        out.loot = Battle_LootAppendNormalized(out.loot, loot);
        out.loot = Battle_LootAppendNormalized(out.loot, recovered_loot);
    }

    out.player = _p;
    return out;
}

function Battle_BuildVictoryDialogueLines(_enemy, _rewards, _player) {
    var enemy_name = Loc_T("enemy.name.unknown", "Enemy");
    if (is_struct(_enemy) && variable_struct_exists(_enemy, "name")) enemy_name = string(_enemy.name);

    var loot_gained = is_struct(_rewards) && variable_struct_exists(_rewards, "loot") && is_array(_rewards.loot) && array_length(_rewards.loot) > 0;
    var result = {
        exp_gain: (is_struct(_rewards) && variable_struct_exists(_rewards, "exp_gain")) ? max(0, round(real(_rewards.exp_gain))) : 0,
        levels_gained: (is_struct(_rewards) && variable_struct_exists(_rewards, "levels_gained")) ? max(0, round(real(_rewards.levels_gained))) : 0,
        stat_points_gained: (is_struct(_rewards) && variable_struct_exists(_rewards, "stat_points_gained")) ? max(0, round(real(_rewards.stat_points_gained))) : 0,
        auto_stat_summary: (is_struct(_rewards) && variable_struct_exists(_rewards, "auto_stat_summary")) ? string(_rewards.auto_stat_summary) : "",
        loot_gained: loot_gained,
        at_level_cap: (is_struct(_player) && variable_struct_exists(_player, "level")) ? Level_IsAtCap(_player.level) : false
    };

    Dialogue_NarrativeOnLevelUp(result.levels_gained);

    var lines = [Enemy_AutoResolveBuildMessage({ name: enemy_name }, result, Loc_T("combat.msg.victory_prefix", "You defeated "))];
    if (loot_gained) {
        var loot_entries = Loot_BuildMessageEntries(_rewards.loot, Loc_T("combat.msg.loot_prefix", "Loot: "));
        for (var i = 0; i < array_length(loot_entries); i++) {
            array_push(lines, loot_entries[i]);
        }
    }

    // One-time floor1 slime reaction.
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    var floor1_slime_key = "floor1_slime_kill_reaction_done";
    var floor1_slime_done = variable_struct_exists(gs.flags, floor1_slime_key) && variable_struct_get(gs.flags, floor1_slime_key);

    var killed_floor1_slime = false;
    var defeated_enemy_id = -1;
    var defeated_enemy_room = -1;
    if (is_struct(gs) && variable_struct_exists(gs, "battle") && is_struct(gs.battle)) {
        if (variable_struct_exists(gs.battle, "enemy_id")) defeated_enemy_id = gs.battle.enemy_id;
        if (variable_struct_exists(gs.battle, "enemy_room")) defeated_enemy_room = gs.battle.enemy_room;
        if (defeated_enemy_room == rm_floor1 && defeated_enemy_id == ENEMY_SLIME) {
            killed_floor1_slime = true;
        }
    }

    if (defeated_enemy_id >= 0) {
        Dialogue_NarrativeOnEnemyDefeated(defeated_enemy_id, defeated_enemy_room);
    }

    if (!floor1_slime_done && killed_floor1_slime) {
        array_push(lines, Loc_T("combat.msg.floor1_reaction.0", "How was that even alive?! I almost died."));
        array_push(lines, Loc_T("combat.msg.floor1_reaction.1", "God, I just need to get out of here."));
        variable_struct_set(gs.flags, floor1_slime_key, true);
    }

    if (defeated_enemy_id == ENEMY_FINAL_BOSS) {
        var final_reaction = DialogueDB_Get("sys_final_boss_defeated_reaction");
        if (is_array(final_reaction)) {
            for (var fr = 0; fr < array_length(final_reaction); fr++) {
                array_push(lines, final_reaction[fr]);
            }
        }
    }

    return lines;
}

function Player_OnDeath(_p) {
    var gs = GameState_Get();
    _p.hp = 0;
    _p = Equip_PassiveBattleCleanup(_p);
    _p = Status_ClearAll(_p);
    GameState_SetPlayer(_p);
    if (variable_struct_exists(gs, "pending_post_battle_dialogue_lines")) gs.pending_post_battle_dialogue_lines = [];
    gs.in_main_menu = false;
    GameState_SetJustReturned(false);
    Transition_RequestCutsceneById("game_over");
}

// --------------------
// BATTLE FLOW
// --------------------
function Battle_CheckEnd(_bc, _p, _e) {
    if (_e.hp <= 0) {
        _bc.battle_over = true;
        var rewards = Battle_GrantRewards(_p, _e);
        _p = rewards.player;
        _p = Equip_PassiveBattleCleanup(_p);
        _p = Status_ClearAll(_p);
        GameState_SetPlayer(_p);
        EnemyPersist_ResolveBattle(true);
        var gs = GameState_Get();
        gs.pending_post_battle_dialogue_lines = Battle_BuildVictoryDialogueLines(_e, rewards, _p);

        Battle_Message(_bc, Loc_T("combat.msg.enemy_slain", "{enemy} has been slain.", { enemy: _e.name }), BSTATE_END_RUN);
        return true;
    }

    if (_p.hp <= 0) {
        _bc.battle_over = true;
        Player_OnDeath(_p);
        return true;
    }

    return false;
}

function Battle_AttackTimingTarget(_bc) {
    var gui_w = max(1, display_get_gui_width());
    var gui_h = max(1, display_get_gui_height());
    var tx = gui_w * 0.5;
    var ty = gui_h * 0.5;

    if (instance_exists(_bc.enemy_inst)) {
        var cam = view_camera[0];
        var vx = _bc.cam_base_x;
        var vy = _bc.cam_base_y;
        var vw = max(1, camera_get_view_width(cam));
        var vh = max(1, camera_get_view_height(cam));
        var sx = gui_w / vw;
        var sy = gui_h / vh;

        var espr = _bc.enemy_inst.sprite_index;
        if (espr != noone) {
            var ex = (_bc.enemy_inst.x - sprite_get_xoffset(espr) - vx) * sx;
            var ey = (_bc.enemy_inst.y - sprite_get_yoffset(espr) - vy) * sy;
            var ew = sprite_get_width(espr) * abs(_bc.enemy_inst.image_xscale) * sx;
            var eh = sprite_get_height(espr) * abs(_bc.enemy_inst.image_yscale) * sy;
            tx = ex + (ew * 0.5);
            ty = ey + (eh * 0.5);
        }
    }

    return { x: round(tx), y: round(ty) };
}

function Battle_AttackTimingJudge(_delta) {
    var d = abs(_delta);
    if (d <= ATTACK_WINDOW_PERFECT) return { key: "PERFECT", label: Loc_T("battle.action.timing.perfect", "PERFECT"), mult: 1.00, hit: true };
    if (d <= ATTACK_WINDOW_GOOD)    return { key: "GOOD",    label: Loc_T("battle.action.timing.good", "GOOD"),       mult: 0.75, hit: true };
    if (d <= ATTACK_WINDOW_OKAY)    return { key: "OKAY",    label: Loc_T("battle.action.timing.okay", "OKAY"),       mult: 0.50, hit: true };
    if (d <= ATTACK_WINDOW_BAD)     return { key: "BAD",     label: Loc_T("battle.action.timing.bad", "BAD"),         mult: 0.25, hit: true };
    return { key: "MISS", label: Loc_T("battle.action.timing.miss", "MISS"), mult: 0.00, hit: false };
}

function Battle_PlayerStunSkip(_bc) {
    var p = _bc.p;
    var e = _bc.e;
    p = Status_Tick(p);
    if (Battle_CheckEnd(_bc, p, e)) return true;
    _bc.player_bonus_actions_remaining = 0;
    _bc.turn = TURN_ENEMY;
    _bc.p = p;
    _bc.e = e;
    Battle_Message(_bc, Loc_T("combat.msg.player_stunned", "You are stunned!"), BSTATE_ENEMY_ACT);
    return false;
}

function Battle_PlayerFinalizeTurn(_bc, _p, _e, _granted_extra_actions = 0) {
    var p = Status_Tick(_p);
    var e = _e;
    if (Battle_CheckEnd(_bc, p, e)) return true;

    var grant = max(0, round(real(_granted_extra_actions)));
    if (!variable_instance_exists(_bc, "player_bonus_actions_remaining")) _bc.player_bonus_actions_remaining = 0;

    if (grant > 0) {
        // The stun action itself is free, then grant extra player turns.
        _bc.player_bonus_actions_remaining = max(_bc.player_bonus_actions_remaining, grant);
        _bc.turn = TURN_PLAYER;
    } else if (_bc.player_bonus_actions_remaining > 0) {
        _bc.player_bonus_actions_remaining = max(0, _bc.player_bonus_actions_remaining - 1);
        _bc.turn = (_bc.player_bonus_actions_remaining > 0) ? TURN_PLAYER : TURN_ENEMY;
    } else {
        _bc.turn = TURN_ENEMY;
    }

    _bc.p = p;
    _bc.e = e;
    return false;
}

function Battle_AttackTimingBegin(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        if (Battle_PlayerStunSkip(_bc)) return;
        _bc.attack_timing_active = false;
        _bc.attack_timing_started = false;
        return;
    }

    var target = Battle_AttackTimingTarget(_bc);
    _bc.attack_timing_target_x = target.x;
    _bc.attack_timing_target_y = target.y;
    _bc.attack_timing_x = target.x;
    _bc.attack_timing_y = -ATTACK_TIMING_START_OFFSET;
    _bc.attack_timing_input_lock = max(0, ATTACK_TIMING_INPUT_LOCK_FRAMES);
    _bc.attack_timing_active = true;
    _bc.attack_timing_started = true;
    _bc.attack_timing_marker_alpha = 0;
    _bc.battle_state = BSTATE_ATTACK_TIMING;
}

function Battle_PlayerAttackResolveTimed(_bc, _timing) {
    var p = _bc.p;
    var e = _bc.e;
    var timing = _timing;
    if (!is_struct(timing)) timing = { key: "MISS", label: Loc_T("battle.action.timing.miss", "MISS"), mult: 0.00, hit: false };

    var timing_label = variable_struct_exists(timing, "label") ? string(timing.label) : Loc_T("battle.action.timing.miss", "MISS");
    var timing_key = variable_struct_exists(timing, "key") ? string(timing.key) : "MISS";
    var timing_mult = variable_struct_exists(timing, "mult") ? clamp(real(timing.mult), 0, 1) : 0;
    var timing_hit = variable_struct_exists(timing, "hit") && timing.hit;

    // Equipment passives can forgive/upgrade timing outcomes.
    timing = Equip_ModifyTimedAttackResult(p, timing);
    timing_label = variable_struct_exists(timing, "label") ? string(timing.label) : timing_label;
    timing_key = variable_struct_exists(timing, "key") ? string(timing.key) : timing_key;
    timing_mult = variable_struct_exists(timing, "mult") ? clamp(real(timing.mult), 0, 1) : timing_mult;
    timing_hit = variable_struct_exists(timing, "hit") && timing.hit;

    _bc.attack_timing_active = false;
    _bc.attack_timing_started = false;
    _bc.attack_timing_result_text = timing_label;
    _bc.attack_timing_result_key = timing_key;
    _bc.attack_timing_result_timer = ATTACK_TIMING_FEEDBACK_FRAMES;

    var player_class_id = -1;
    if (variable_struct_exists(p, "class_id")) player_class_id = p.class_id;
    SFX_PlayClassAttack(player_class_id);

    var w = _bc.player_weapon;
    if (!is_struct(w) || !variable_struct_exists(w, "power")) {
        var wid = p.equip.weapon;
        w = ItemDB_Get(wid);
        if (w.id == 0) w = { power:1, stat_type:STAT_STR, acc:0, preferred_class:-1 };
        _bc.player_weapon = w;
    }

    _bc.last_hit = timing_hit;
    _bc.last_dmg = 0;
    _bc.last_crit = false;

    if (timing_hit) {
        var crit_bonus = Status_GetSum(p, "crit_bonus");
        _bc.last_crit = Combat_CritCheck(p, 1 + crit_bonus);
        var dmg_pack = Combat_ApplyDamage(p, e, w, (_bc.last_crit ? 2 : 1), 1);

        var base_dmg = max(0, dmg_pack.dmg);
        var scaled_dmg = floor(base_dmg * timing_mult);
        if (base_dmg > 0 && scaled_dmg < 1) scaled_dmg = 1;
        scaled_dmg = clamp(scaled_dmg, 0, base_dmg);

        var refund = base_dmg - scaled_dmg;
        e = dmg_pack.defender;
        if (refund > 0) {
            e.hp = clamp(e.hp + refund, 0, e.max_hp);
        }

        // FUN-FIRST gear passives add bonus pressure after timing result.
        var bonus_dmg = Equip_PlayerBonusDamage(p, e, scaled_dmg, false, timing_key);
        if (bonus_dmg > 0) {
            var spend = min(bonus_dmg, e.hp);
            e.hp = max(0, e.hp - spend);
            scaled_dmg += spend;
        }

        _bc.last_dmg = scaled_dmg;
        p = Equip_PlayerPerfectHitApply(p, timing_key);
    }

    var side_fx = Equip_PassiveOnAttackResolved(p, e, timing_key, timing_hit, _bc.last_dmg);
    p = side_fx.attacker;
    e = side_fx.defender;
    var passive_msg = side_fx.msg;

    p = Status_ConsumeByField(p, "consume_on_attack");

    if (Battle_CheckEnd(_bc, p, e)) return;

    if (!timing_hit) {
        SFX_PlayMissOrBlocked(false, -1);
        var m0 = Loc_T("combat.msg.player_miss", "You missed!");
        if (passive_msg != "") m0 += " " + passive_msg;
        Battle_Message(_bc, m0, BSTATE_ENEMY_ACT);
    } else if (_bc.last_crit) {
        if (_bc.last_dmg > 0 && instance_exists(_bc.enemy_inst)) {
            SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
        }
        var m1 = Loc_T("combat.msg.player_crit", "Critical hit! {dmg} damage!", { dmg: _bc.last_dmg });
        if (passive_msg != "") m1 += " " + passive_msg;
        Battle_Message(_bc, m1, BSTATE_ENEMY_ACT);
    } else {
        if (_bc.last_dmg > 0 && instance_exists(_bc.enemy_inst)) {
            SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
        }
        var m2 = Loc_T("combat.msg.player_hit", "You hit for {dmg} damage!", { dmg: _bc.last_dmg });
        if (passive_msg != "") m2 += " " + passive_msg;
        Battle_Message(_bc, m2, BSTATE_ENEMY_ACT);
    }

    if (Battle_PlayerFinalizeTurn(_bc, p, e, 0)) return;
}

function Battle_PlayerAttackTimingStep(_bc, _confirm_pressed) {
    if (!_bc.attack_timing_started || !_bc.attack_timing_active) {
        Battle_AttackTimingBegin(_bc);
        return;
    }

    var target = Battle_AttackTimingTarget(_bc);
    _bc.attack_timing_target_x = target.x;
    _bc.attack_timing_target_y = target.y;
    _bc.attack_timing_x = target.x;
    _bc.attack_timing_marker_alpha = min(1, _bc.attack_timing_marker_alpha + 0.20);

    if (_bc.attack_timing_input_lock > 0) _bc.attack_timing_input_lock -= 1;
    _bc.attack_timing_y += Battle_AttackTimingSpeedForEnemy(_bc.e);

    if (_confirm_pressed && _bc.attack_timing_input_lock <= 0) {
        var d = abs(_bc.attack_timing_y - _bc.attack_timing_target_y);
        Battle_PlayerAttackResolveTimed(_bc, Battle_AttackTimingJudge(d));
        return;
    }

    var late_limit = _bc.attack_timing_target_y + ATTACK_WINDOW_BAD + ATTACK_TIMING_END_MARGIN;
    if (_bc.attack_timing_y >= late_limit) {
        Battle_PlayerAttackResolveTimed(_bc, { key: "MISS", label: Loc_T("battle.action.timing.miss", "MISS"), mult: 0.00, hit: false });
        return;
    }
}

function Battle_PlayerAttack(_bc) {
    Battle_PlayerAttackResolveTimed(_bc, { key: "PERFECT", label: Loc_T("battle.action.timing.perfect", "PERFECT"), mult: 1.00, hit: true });
}

function Battle_PlayerSkill(_bc, _skill_id) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        if (Battle_PlayerStunSkip(_bc)) return;
        return;
    }

    var skill = SkillDB_Get(_skill_id);
    var target = (skill.target == TGT_SELF) ? p : e;
    var res = Skill_Use(p, target, _skill_id);
    if (res.ok) {
        _bc.skill_banner_active = true;
        _bc.skill_banner_name = skill.name;
        SFX_PlaySkill(_skill_id);
    }

    var fx = noone;
    if (res.ok && res.fx_sprite != noone && (skill.effect != "damage" || res.hit)) {
        var tx = _bc.enemy_fx_x;
        var ty = _bc.enemy_fx_y;
        if (instance_exists(_bc.enemy_inst)) {
            var pos = FX_CenterOn(res.fx_sprite, _bc.enemy_inst);
            tx = pos.x;
            ty = pos.y;
        }
        fx = FX_Spawn(res.fx_sprite, tx, ty, res.fx_frames, res.fx_speed);
    }

    if (!res.ok) {
        Battle_Message(_bc, res.msg, BSTATE_SKILL_MENU);
        _bc.p = p;
        _bc.e = e;
        return;
    }

    if (skill.target == TGT_SELF) p = target; else e = target;

    if (Battle_CheckEnd(_bc, p, e)) return;

    var grant_extra_turns = 0;
    var skill_targets_opponent = (skill.target != TGT_SELF);
    if (res.ok && res.hit && skill_targets_opponent && Status_SkillAppliesStatus(skill, STATUS_STUN)) {
        // Player stun skills: action is free and grants two additional player turns.
        grant_extra_turns = 2;
    }

    if (res.msg != "") {
        Battle_Message(_bc, res.msg, BSTATE_ENEMY_ACT, fx);
    } else if (!res.hit) {
        SFX_PlayMissOrBlocked(false, -1);
        Battle_Message(_bc, Loc_T("combat.msg.skill_miss", "Skill missed!"), BSTATE_ENEMY_ACT, fx);
    } else if (res.crit) {
        Battle_Message(_bc, Loc_T("combat.msg.skill_crit", "Critical skill! {dmg} damage!", { dmg: res.dmg }), BSTATE_ENEMY_ACT, fx);
    } else if (res.dmg > 0) {
        if (instance_exists(_bc.enemy_inst)) {
            SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
        }
        Battle_Message(_bc, Loc_T("combat.msg.skill_hit", "Skill hit for {dmg} damage!", { dmg: res.dmg }), BSTATE_ENEMY_ACT, fx);
    } else {
        Battle_Message(_bc, Loc_T("combat.msg.skill_used", "Skill used."), BSTATE_ENEMY_ACT, fx);
    }

    if (Battle_PlayerFinalizeTurn(_bc, p, e, grant_extra_turns)) return;
}

function Battle_PlayerItem(_bc, _item_id) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        if (Battle_PlayerStunSkip(_bc)) return;
        return;
    }

    var item = ItemDB_Get(_item_id);
    var target = (item.use.target == TGT_SELF) ? p : e;
    var res = Item_Use(_item_id, p, target);
    var fx = noone;
    if (res.fx_sprite != noone) {
        fx = FX_Spawn(res.fx_sprite, _bc.player_fx_x, _bc.player_fx_y, res.fx_frames, res.fx_speed);
    }

    if (!res.ok) {
        Battle_Message(_bc, res.msg, BSTATE_ITEM_MENU);
        _bc.p = p;
        _bc.e = e;
        return;
    }

    if (item.use.target == TGT_SELF) p = target; else e = target;
    p.inventory = Inv_Remove(p.inventory, _item_id, 1);

    if (Battle_CheckEnd(_bc, p, e)) return;

    Battle_Message(_bc, res.msg, BSTATE_ENEMY_ACT, fx);
    if (Battle_PlayerFinalizeTurn(_bc, p, e, 0)) return;
}

function Battle_GetSkillList(_bc) {
    var p = _bc.p;
    if (is_array(p.skills)) return p.skills;
    return [];
}

function Battle_GetItemList(_bc) {
    var p = _bc.p;
    if (!is_array(p.inventory)) return [];

    var out = [];
    for (var i = 0; i < array_length(p.inventory); i++) {
        var inv = p.inventory[i];
        var item = ItemDB_Get(inv.id);
        if (item.type == ITEM_CONSUMABLE && variable_struct_exists(item, "usable_battle") && item.usable_battle) {
            array_push(out, inv);
        }
    }
    return out;
}

function Battle_RunAttempt(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    var enemy_id = -1;
    if (is_struct(e) && variable_struct_exists(e, "id")) enemy_id = e.id;
    if (enemy_id == ENEMY_MINI_BOSS || enemy_id == ENEMY_FINAL_BOSS) {
        _bc.turn = TURN_ENEMY;
        Battle_Message(_bc, Loc_T("combat.msg.player_cant_escape_this", "You can't run away from this."), BSTATE_ENEMY_ACT);
        return;
    }

    var pr = RollD20() + StatMod(Combat_EffectiveStat(p, STAT_AGI));
    var er = RollD20() + StatMod(Combat_EffectiveStat(e, STAT_AGI));

    if (pr >= er) {
        EnemyPersist_ResolveBattle(false);
        if (enemy_id == ENEMY_STRANGER) {
            Dialogue_NarrativeOnStrangerEncounterResolved();
        }
        Battle_Message(_bc, Loc_T("combat.msg.player_ran", "You ran away!"), BSTATE_END_RUN);
    } else {
        _bc.turn = TURN_ENEMY;
        Battle_Message(_bc, Loc_T("combat.msg.player_couldnt_escape", "Couldn't escape!"), BSTATE_ENEMY_ACT);
    }
}

function Battle_EndRun(_bc) {
    _bc.battle_over = true;
    _bc.p = Equip_PassiveBattleCleanup(_bc.p);
    _bc.p = Status_ClearAll(_bc.p);
    GameState_SetPlayer(_bc.p);

    var gs = GameState_Get();
    // mark return so player gets a short grace window
    GameState_SetJustReturned(true);
    Transition_RequestRoomFade(gs.battle.return_room);
}

function Battle_EnemyInitActionBudget(_bc, _e) {
    if (!variable_instance_exists(_bc, "enemy_actions_remaining")) _bc.enemy_actions_remaining = 0;
    if (!variable_instance_exists(_bc, "enemy_turn_used_skills") || !is_array(_bc.enemy_turn_used_skills)) _bc.enemy_turn_used_skills = [];
    if (_bc.enemy_actions_remaining > 0) return;

    _bc.enemy_turn_used_skills = [];

    var actions = 1;
    if (is_array(_e.skills) && array_length(_e.skills) > 0) {
        for (var i = 0; i < array_length(_e.skills); i++) {
            var sid = _e.skills[i];
            var sk = SkillDB_Get(sid);
            if (!is_struct(sk) || sk.id == -1) continue;
            if (!variable_struct_exists(sk, "enemy_passive_action_budget") || !sk.enemy_passive_action_budget) continue;
            if (!Skill_EnemyCanTrigger(sk, _e, _e)) continue;
            if (!variable_struct_exists(sk, "set_enemy_actions")) continue;
            actions = max(actions, max(1, round(real(sk.set_enemy_actions))));
        }
    }

    _bc.enemy_actions_remaining = clamp(actions, 1, ENEMY_ACTION_CHAIN_MAX);
}

function Battle_IsDamagingSkillForDebug(_sk) {
    if (!is_struct(_sk)) return false;
    if (!variable_struct_exists(_sk, "effect")) return false;
    return (string(_sk.effect) == "damage");
}

function Battle_EnemyChooseSkill(_e, _p, _actions_remaining = -1, _used_skills = [], _force_damage_only = false) {
    if (!is_array(_e.skills) || array_length(_e.skills) <= 0) return -1;

    var candidates = [];
    for (var i = 0; i < array_length(_e.skills); i++) {
        var sid = _e.skills[i];
        var sk = SkillDB_Get(sid);
        if (!is_struct(sk) || sk.id == -1) continue;
        if (variable_struct_exists(sk, "enemy_passive_action_budget") && sk.enemy_passive_action_budget) continue;
        if (_force_damage_only && !Battle_IsDamagingSkillForDebug(sk)) continue;
        if (variable_struct_exists(sk, "enemy_once_per_turn") && sk.enemy_once_per_turn) {
            var already_used = false;
            for (var us = 0; us < array_length(_used_skills); us++) {
                if (_used_skills[us] == sid) { already_used = true; break; }
            }
            if (already_used) continue;
        }
        if (!Skill_CanUse(_e, sk)) continue;
        if (!Skill_EnemyCanTrigger(sk, _e, _p, _actions_remaining)) continue;

        if (_force_damage_only) {
            array_push(candidates, sid);
            continue;
        }

        var chance = Skill_EnemyUseChance(sk);
        if (chance <= 0) continue;
        if (random(1) <= chance) array_push(candidates, sid);
    }

    if (array_length(candidates) <= 0) return -1;
    return candidates[irandom(array_length(candidates) - 1)];
}

function Battle_StatusSnapshot(_ch) {
    var out = [];
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "status") || !is_array(_ch.status)) return out;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var st = _ch.status[i];
        if (!is_struct(st) || !variable_struct_exists(st, "id")) continue;
        var sid = round(real(st.id));
        var turns = variable_struct_exists(st, "turns") ? max(0, round(real(st.turns))) : 0;
        array_push(out, { id: sid, turns: turns });
    }
    return out;
}

function Battle_StatusSnapshotTurns(_snapshot, _status_id) {
    if (!is_array(_snapshot)) return 0;
    var sid = round(real(_status_id));
    for (var i = 0; i < array_length(_snapshot); i++) {
        var st = _snapshot[i];
        if (!is_struct(st) || !variable_struct_exists(st, "id")) continue;
        if (round(real(st.id)) != sid) continue;
        return variable_struct_exists(st, "turns") ? max(0, round(real(st.turns))) : 0;
    }
    return 0;
}

function Battle_StatusCurrentTurns(_ch, _status_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "status") || !is_array(_ch.status)) return 0;
    var sid = round(real(_status_id));
    for (var i = 0; i < array_length(_ch.status); i++) {
        var st = _ch.status[i];
        if (!is_struct(st) || !variable_struct_exists(st, "id")) continue;
        if (round(real(st.id)) != sid) continue;
        return variable_struct_exists(st, "turns") ? max(0, round(real(st.turns))) : 0;
    }
    return 0;
}

function Battle_StatusSetTurns(_ch, _status_id, _turns) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "status") || !is_array(_ch.status)) return _ch;
    var sid = round(real(_status_id));
    var turns = max(0, round(real(_turns)));
    for (var i = 0; i < array_length(_ch.status); i++) {
        var st = _ch.status[i];
        if (!is_struct(st) || !variable_struct_exists(st, "id")) continue;
        if (round(real(st.id)) != sid) continue;
        st.turns = turns;
        _ch.status[i] = st;
        break;
    }
    return _ch;
}

function Battle_SkillStatusSpecs(_skill) {
    var specs = [];
    if (!is_struct(_skill)) return specs;

    var default_turns = variable_struct_exists(_skill, "status_turns") ? max(1, round(real(_skill.status_turns))) : 1;
    if (variable_struct_exists(_skill, "status")) {
        var sid = round(real(_skill.status));
        if (sid != -1) array_push(specs, { id: sid, base_turns: default_turns });
    }

    if (variable_struct_exists(_skill, "status_list") && is_array(_skill.status_list)) {
        var turns_list = (variable_struct_exists(_skill, "status_turns_list") && is_array(_skill.status_turns_list)) ? _skill.status_turns_list : [];
        for (var i = 0; i < array_length(_skill.status_list); i++) {
            var sid_m = round(real(_skill.status_list[i]));
            if (sid_m == -1) continue;

            var turns_m = default_turns;
            if (i < array_length(turns_list)) turns_m = max(1, round(real(turns_list[i])));

            var merged = false;
            for (var j = 0; j < array_length(specs); j++) {
                if (specs[j].id != sid_m) continue;
                specs[j].base_turns = max(specs[j].base_turns, turns_m);
                merged = true;
                break;
            }
            if (!merged) array_push(specs, { id: sid_m, base_turns: turns_m });
        }
    }

    return specs;
}

function Battle_DefQTEThreatRank(_enemy) {
    var rank = 1;
    if (is_struct(_enemy) && variable_struct_exists(_enemy, "threat_rank")) rank = max(1, round(real(_enemy.threat_rank)));
    if (is_struct(_enemy) && variable_struct_exists(_enemy, "id")) {
        var cfg = EnemyDB_Get(_enemy.id);
        if (is_struct(cfg) && variable_struct_exists(cfg, "threat_rank")) {
            rank = max(rank, max(1, round(real(cfg.threat_rank))));
        }
    }
    return rank;
}

function Battle_DefQTEPromptCountForEnemy(_enemy) {
    var rank = Battle_DefQTEThreatRank(_enemy);
    var is_boss = is_struct(_enemy) && variable_struct_exists(_enemy, "is_boss") && _enemy.is_boss;
    if (is_boss || rank >= 4) return irandom_range(3, 5);
    if (rank >= 3) return irandom_range(2, 4);
    if (rank >= 2) return irandom_range(1, 3);
    return 1;
}

function Battle_DefQTESpeedMultForEnemy(_enemy) {
    var rank = Battle_DefQTEThreatRank(_enemy);
    var extra_rank = max(0, rank - 1);
    var mult = DEF_QTE_SPEED_BASE_MULT + (extra_rank * DEF_QTE_SPEED_RANK_STEP);
    return clamp(mult, 1, DEF_QTE_SPEED_MULT_MAX);
}

function Battle_AttackTimingSpeedMultForEnemy(_enemy) {
    var rank = Battle_DefQTEThreatRank(_enemy);
    var extra_rank = max(0, rank - 1);
    var mult = ATTACK_TIMING_SPEED_BASE_MULT + (extra_rank * ATTACK_TIMING_SPEED_RANK_STEP);
    return clamp(mult, 1, ATTACK_TIMING_SPEED_MULT_MAX);
}

function Battle_AttackTimingSpeedForEnemy(_enemy) {
    return ATTACK_TIMING_SPEED * Battle_AttackTimingSpeedMultForEnemy(_enemy);
}

function Battle_DefQTERandomDir() {
    return choose(UP, DOWN, LEFT, RIGHT);
}

function Battle_DefQTEActionForDir(_dir) {
    switch (_dir) {
        case UP: return "move_up";
        case DOWN: return "move_down";
        case LEFT: return "move_left";
        case RIGHT: return "move_right";
    }
    return "move_up";
}

function Battle_DefQTEInputDir() {
    if (Input_UIPressed("move_up")) return UP;
    if (Input_UIPressed("move_down")) return DOWN;
    if (Input_UIPressed("move_left")) return LEFT;
    if (Input_UIPressed("move_right")) return RIGHT;
    return -1;
}

function Battle_EnemySkillCanUseDefQTE(_skill, _res, _target) {
    if (!is_struct(_skill) || !is_struct(_res) || !is_struct(_target)) return false;
    if (!variable_struct_exists(_skill, "uses_defensive_qte") || !_skill.uses_defensive_qte) return false;
    if (!variable_struct_exists(_skill, "effect") || string(_skill.effect) != "damage") return false;
    if (!variable_struct_exists(_target, "is_player") || !_target.is_player) return false;
    if (!variable_struct_exists(_res, "ok") || !_res.ok) return false;
    if (!variable_struct_exists(_res, "hit") || !_res.hit) return false;
    if (!variable_struct_exists(_res, "dmg") || round(real(_res.dmg)) <= 0) return false;
    return true;
}

function Battle_EnemySkillComposeMessage(_enemy_name, _res, _dmg_override = -1, _status_msg = "", _extra_msg = "") {
    var enemy_name = string(_enemy_name);
    var res = is_struct(_res) ? _res : { hit: true, crit: false, dmg: 0, msg: "" };

    var hit = variable_struct_exists(res, "hit") ? res.hit : false;
    var crit = variable_struct_exists(res, "crit") ? res.crit : false;
    var dmg_raw = variable_struct_exists(res, "dmg") ? max(0, round(real(res.dmg))) : 0;
    var dmg = (argument_count >= 3 && _dmg_override >= 0) ? max(0, round(real(_dmg_override))) : dmg_raw;
    var base_tail = variable_struct_exists(res, "msg") ? string(res.msg) : "";
    var has_dmg_context = ((argument_count >= 3 && _dmg_override >= 0) || dmg_raw > 0);

    var msg = "";
    if (!hit) {
        msg = Loc_T("combat.msg.enemy_miss", "{enemy} missed!", { enemy: enemy_name });
    } else if (has_dmg_context) {
        if (crit) msg = Loc_T("combat.msg.enemy_crit", "{enemy} crit! {dmg} damage!", { enemy: enemy_name, dmg: dmg });
        else msg = Loc_T("combat.msg.enemy_hit", "{enemy} hits for {dmg} damage!", { enemy: enemy_name, dmg: dmg });
    } else if (base_tail != "") {
        msg = Loc_T("combat.msg.enemy_skill_message", "{enemy}: {msg}", { enemy: enemy_name, msg: base_tail });
    } else {
        msg = Loc_T("combat.msg.skill_used", "Skill used.");
    }

    if (string(_status_msg) != "") {
        msg += " " + string(_status_msg);
    } else if (hit && has_dmg_context && base_tail != "") {
        msg += " " + base_tail;
    }

    if (string(_extra_msg) != "") {
        msg += " " + string(_extra_msg);
    }

    return msg;
}

function Battle_EnemyFinalizeTurnState(_bc, _p, _e) {
    var out = { ended: false, player: _p, enemy: _e };
    var p = _p;
    var e = _e;

    var enemy_turn_finished = (_bc.enemy_actions_remaining <= 0);
    if (enemy_turn_finished) {
        e = Status_Tick(e);
        if (Battle_CheckEnd(_bc, p, e)) {
            _bc.p = p;
            _bc.e = e;
            out.ended = true;
            out.player = p;
            out.enemy = e;
            return out;
        }
        _bc.turn = TURN_PLAYER;
    } else {
        _bc.turn = TURN_ENEMY;
    }

    _bc.p = p;
    _bc.e = e;
    out.player = p;
    out.enemy = e;
    return out;
}

function Battle_DefQTEClear(_bc) {
    _bc.enemy_def_qte_active = false;
    _bc.enemy_def_qte_prompts = [];
    _bc.enemy_def_qte_total = 0;
    _bc.enemy_def_qte_index = 0;
    _bc.enemy_def_qte_success = 0;
    _bc.enemy_def_qte_failure = 0;
    _bc.enemy_def_qte_phase = 0;
    _bc.enemy_def_qte_timer = 0;
    _bc.enemy_def_qte_draw_alpha = 0;
    _bc.enemy_def_qte_draw_scale = 1;
    _bc.enemy_def_qte_feedback_ok = false;
    _bc.enemy_def_qte_feedback_timed_out = false;
    _bc.enemy_def_qte_feedback_dir = -1;
    _bc.enemy_def_qte_input_dir = -1;
    _bc.enemy_def_qte_ctx = {};
}

function Battle_DefQTEBeginPrompt(_bc) {
    if (!_bc.enemy_def_qte_active) return;
    if (_bc.enemy_def_qte_index >= _bc.enemy_def_qte_total) return;

    _bc.enemy_def_qte_phase = 0;
    _bc.enemy_def_qte_timer = max(1, _bc.enemy_def_qte_fade_in_frames);
    _bc.enemy_def_qte_draw_alpha = 0;
    _bc.enemy_def_qte_draw_scale = 1;
    _bc.enemy_def_qte_feedback_ok = false;
    _bc.enemy_def_qte_feedback_timed_out = false;
    _bc.enemy_def_qte_feedback_dir = -1;
    _bc.enemy_def_qte_input_dir = -1;

    SFX_PlayUI("ui_move");
}

function Battle_DefQTEStart(_bc, _enemy, _skill, _res, _follow_state, _player_hp_before, _status_before_snapshot) {
    var total = max(1, Battle_DefQTEPromptCountForEnemy(_enemy));
    var prompts = [];
    for (var i = 0; i < total; i++) {
        array_push(prompts, Battle_DefQTERandomDir());
    }

    var qte_frame_rate = game_get_speed(gamespeed_fps);
    if (!is_real(qte_frame_rate) || qte_frame_rate <= 0) qte_frame_rate = 60;
    qte_frame_rate = max(1, round(qte_frame_rate));
    var qte_speed_mult = Battle_DefQTESpeedMultForEnemy(_enemy);
    _bc.enemy_def_qte_fade_in_frames = max(1, round((qte_frame_rate * DEF_QTE_PROMPT_FADE_IN_SEC) / qte_speed_mult));
    _bc.enemy_def_qte_response_frames = max(1, round((qte_frame_rate * DEF_QTE_PROMPT_RESPONSE_SEC) / qte_speed_mult));
    _bc.enemy_def_qte_feedback_frames = max(1, round((qte_frame_rate * DEF_QTE_PROMPT_FEEDBACK_SEC) / qte_speed_mult));
    _bc.enemy_def_qte_transition_frames = max(1, round((qte_frame_rate * DEF_QTE_PROMPT_TRANSITION_SEC) / qte_speed_mult));

    _bc.enemy_def_qte_active = true;
    _bc.enemy_def_qte_prompts = prompts;
    _bc.enemy_def_qte_total = total;
    _bc.enemy_def_qte_index = 0;
    _bc.enemy_def_qte_success = 0;
    _bc.enemy_def_qte_failure = 0;
    _bc.enemy_def_qte_ctx = {
        skill: _skill,
        res: _res,
        follow_state: _follow_state,
        hp_before: max(0, round(real(_player_hp_before))),
        status_before: _status_before_snapshot,
        status_specs: Battle_SkillStatusSpecs(_skill)
    };

    Battle_DefQTEBeginPrompt(_bc);
    _bc.battle_state = BSTATE_ENEMY_DEF_QTE;
    return true;
}

function Battle_DefQTEAdjustPlayerStatuses(_p, _status_specs, _before_snapshot, _success_ratio) {
    var out = { player: _p, status_msg: "", blocked_stun: false };
    var p = _p;
    if (!is_array(_status_specs) || array_length(_status_specs) <= 0) {
        out.player = p;
        return out;
    }

    var ratio = clamp(real(_success_ratio), 0, 1);
    var duration_mult = DEF_QTE_STATUS_MIN_MULT + ((DEF_QTE_STATUS_MAX_MULT - DEF_QTE_STATUS_MIN_MULT) * (1 - ratio));
    var status_names = [];
    var blocked_stun = false;

    for (var i = 0; i < array_length(_status_specs); i++) {
        var spec = _status_specs[i];
        if (!is_struct(spec) || !variable_struct_exists(spec, "id")) continue;

        var sid = round(real(spec.id));
        var before_turns = Battle_StatusSnapshotTurns(_before_snapshot, sid);
        var current_turns = Battle_StatusCurrentTurns(p, sid);
        if (current_turns <= before_turns) continue;

        if (sid == STATUS_STUN && ratio >= DEF_QTE_STATUS_STUN_BLOCK_RATIO) {
            if (before_turns > 0) {
                p = Battle_StatusSetTurns(p, sid, before_turns);
            } else {
                p = Status_Remove(p, sid);
            }
            blocked_stun = true;
            continue;
        }

        var base_turns = variable_struct_exists(spec, "base_turns") ? max(1, round(real(spec.base_turns))) : 1;
        var scaled_turns = max(1, round(base_turns * duration_mult));
        if (before_turns > 0) scaled_turns = max(before_turns, scaled_turns);
        p = Battle_StatusSetTurns(p, sid, scaled_turns);

        var final_turns = Battle_StatusCurrentTurns(p, sid);
        if (final_turns > before_turns) {
            var cfg = StatusDB_Get(sid);
            if (is_struct(cfg) && variable_struct_exists(cfg, "name")) {
                var name = string(cfg.name);
                var dup = false;
                for (var n = 0; n < array_length(status_names); n++) {
                    if (status_names[n] == name) { dup = true; break; }
                }
                if (!dup) array_push(status_names, name);
            }
        }
    }

    var status_msg = "";
    if (array_length(status_names) > 0) status_msg = Skill_BuildAppliedStatusMessage(status_names);

    out.player = p;
    out.status_msg = status_msg;
    out.blocked_stun = blocked_stun;
    return out;
}

function Battle_DefQTEFinalize(_bc) {
    if (!_bc.enemy_def_qte_active) return;

    var p = _bc.p;
    var e = _bc.e;
    var ctx = is_struct(_bc.enemy_def_qte_ctx) ? _bc.enemy_def_qte_ctx : {};

    var total = max(1, _bc.enemy_def_qte_total);
    var success = clamp(_bc.enemy_def_qte_success, 0, total);
    var ratio = success / total;

    var base_res = variable_struct_exists(ctx, "res") && is_struct(ctx.res) ? ctx.res : { hit: true, crit: false, dmg: 0, msg: "" };
    var base_dmg = variable_struct_exists(base_res, "dmg") ? max(0, round(real(base_res.dmg))) : 0;
    var dmg_mult = clamp(1 - (DEF_QTE_DAMAGE_REDUCTION_MAX * ratio), 0, 1);
    var final_dmg = max(0, floor(base_dmg * dmg_mult));

    var hp_before = variable_struct_exists(ctx, "hp_before") ? max(0, round(real(ctx.hp_before))) : p.hp;
    if (is_struct(p) && variable_struct_exists(p, "max_hp")) hp_before = clamp(hp_before, 0, p.max_hp);
    if (is_struct(p) && variable_struct_exists(p, "max_hp")) p.hp = clamp(hp_before - final_dmg, 0, p.max_hp);
    else p.hp = max(0, hp_before - final_dmg);

    var status_before = variable_struct_exists(ctx, "status_before") ? ctx.status_before : [];
    var status_specs = variable_struct_exists(ctx, "status_specs") ? ctx.status_specs : [];
    var status_pack = Battle_DefQTEAdjustPlayerStatuses(p, status_specs, status_before, ratio);
    p = status_pack.player;

    var status_msg = status_pack.status_msg;
    if (status_pack.blocked_stun) {
        var block_msg = Loc_T("combat.msg.def_qte.stun_blocked", "Stun blocked.");
        if (status_msg != "") status_msg += " " + block_msg;
        else status_msg = block_msg;
    }

    var reduce_pct = round((1 - dmg_mult) * 100);
    var qte_summary = Loc_T(
        "combat.msg.def_qte.summary",
        "Guarded {ok}/{total}. Damage -{reduce}%.",
        { ok: success, total: total, reduce: reduce_pct }
    );

    var enemy_name = is_struct(e) && variable_struct_exists(e, "name") ? string(e.name) : Loc_T("enemy.name.unknown", "Enemy");
    var msg_res = base_res;
    msg_res.msg = ""; // Rebuilt after mitigation.
    var final_msg = Battle_EnemySkillComposeMessage(enemy_name, msg_res, final_dmg, status_msg, qte_summary);

    _bc.last_hit = true;
    _bc.last_crit = variable_struct_exists(base_res, "crit") && base_res.crit;
    _bc.last_dmg = final_dmg;

    if (final_dmg > 0) {
        CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
    }

    if (Battle_CheckEnd(_bc, p, e)) {
        _bc.p = p;
        _bc.e = e;
        Battle_DefQTEClear(_bc);
        return;
    }

    var turn_pack = Battle_EnemyFinalizeTurnState(_bc, p, e);
    if (turn_pack.ended) {
        Battle_DefQTEClear(_bc);
        return;
    }

    var follow_state = BSTATE_MENU;
    if (variable_struct_exists(ctx, "follow_state")) follow_state = ctx.follow_state;
    Battle_Message(_bc, final_msg, follow_state);
    Battle_DefQTEClear(_bc);
}

function Battle_DefQTEStep(_bc) {
    if (!_bc.enemy_def_qte_active) {
        _bc.battle_state = BSTATE_ENEMY_ACT;
        return;
    }

    if (!is_array(_bc.enemy_def_qte_prompts) || _bc.enemy_def_qte_index >= array_length(_bc.enemy_def_qte_prompts)) {
        Battle_DefQTEFinalize(_bc);
        return;
    }

    var current_dir = _bc.enemy_def_qte_prompts[_bc.enemy_def_qte_index];
    _bc.enemy_def_qte_feedback_dir = current_dir;

    switch (_bc.enemy_def_qte_phase) {
        case 0: { // fade in
            _bc.enemy_def_qte_timer -= 1;
            var fade_frames = max(1, _bc.enemy_def_qte_fade_in_frames);
            var elapsed = fade_frames - max(0, _bc.enemy_def_qte_timer);
            _bc.enemy_def_qte_draw_alpha = clamp(elapsed / fade_frames, 0, 1);
            _bc.enemy_def_qte_draw_scale = 1;
            if (_bc.enemy_def_qte_timer <= 0) {
                _bc.enemy_def_qte_phase = 1;
                _bc.enemy_def_qte_timer = max(1, _bc.enemy_def_qte_response_frames);
                _bc.enemy_def_qte_draw_alpha = 1;
            }
            return;
        }

        case 1: { // input window
            _bc.enemy_def_qte_draw_alpha = 1;
            _bc.enemy_def_qte_draw_scale = 1;

            var input_dir = Battle_DefQTEInputDir();
            if (input_dir != -1) {
                _bc.enemy_def_qte_input_dir = input_dir;
                _bc.enemy_def_qte_feedback_ok = (input_dir == current_dir);
                _bc.enemy_def_qte_feedback_timed_out = false;
                if (_bc.enemy_def_qte_feedback_ok) {
                    _bc.enemy_def_qte_success += 1;
                    SFX_PlayUI("ui_confirm");
                } else {
                    _bc.enemy_def_qte_failure += 1;
                    SFX_PlayUI("ui_back");
                }
                _bc.enemy_def_qte_phase = 2;
                _bc.enemy_def_qte_timer = max(1, _bc.enemy_def_qte_feedback_frames);
                return;
            }

            _bc.enemy_def_qte_timer -= 1;
            if (_bc.enemy_def_qte_timer <= 0) {
                _bc.enemy_def_qte_failure += 1;
                _bc.enemy_def_qte_input_dir = -1;
                _bc.enemy_def_qte_feedback_ok = false;
                _bc.enemy_def_qte_feedback_timed_out = true;
                _bc.enemy_def_qte_phase = 2;
                _bc.enemy_def_qte_timer = max(1, _bc.enemy_def_qte_feedback_frames);
                SFX_PlayUI("ui_back");
            }
            return;
        }

        case 2: { // feedback hold
            _bc.enemy_def_qte_draw_alpha = 1;
            _bc.enemy_def_qte_draw_scale = _bc.enemy_def_qte_feedback_ok ? 1.25 : 0.95;
            _bc.enemy_def_qte_timer -= 1;
            if (_bc.enemy_def_qte_timer <= 0) {
                _bc.enemy_def_qte_phase = 3;
                _bc.enemy_def_qte_timer = max(1, _bc.enemy_def_qte_transition_frames);
            }
            return;
        }

        case 3: { // fade out and advance
            _bc.enemy_def_qte_timer -= 1;
            var trans_frames = max(1, _bc.enemy_def_qte_transition_frames);
            _bc.enemy_def_qte_draw_alpha = clamp(max(0, _bc.enemy_def_qte_timer) / trans_frames, 0, 1);
            _bc.enemy_def_qte_draw_scale = 1;
            if (_bc.enemy_def_qte_timer <= 0) {
                _bc.enemy_def_qte_index += 1;
                if (_bc.enemy_def_qte_index >= _bc.enemy_def_qte_total) {
                    Battle_DefQTEFinalize(_bc);
                } else {
                    Battle_DefQTEBeginPrompt(_bc);
                }
            }
            return;
        }
    }
}

function Battle_DirectionVector(_dir) {
    switch (_dir) {
        case UP: return { x: 0, y: -1 };
        case DOWN: return { x: 0, y: 1 };
        case LEFT: return { x: -1, y: 0 };
        case RIGHT: return { x: 1, y: 0 };
    }
    return { x: 0, y: -1 };
}

function Battle_DrawDirectionArrow(_x, _y, _dir, _size, _alpha = 1, _color = c_white) {
    var size = max(4, round(real(_size)));
    var pos_x = round(real(_x));
    var pos_y = round(real(_y));
    var vec = Battle_DirectionVector(_dir);
    var perp = { x: -vec.y, y: vec.x };

    var tip_x = pos_x + vec.x * size;
    var tip_y = pos_y + vec.y * size;
    var base_x = pos_x - vec.x * round(size * 0.7);
    var base_y = pos_y - vec.y * round(size * 0.7);
    var wing = max(3, round(size * 0.65));
    var half = max(2, round(size * 0.25));

    draw_set_alpha(clamp(real(_alpha), 0, 1));
    draw_set_color(_color);
    draw_line(base_x, base_y, tip_x, tip_y);
    draw_line(base_x + perp.x * half, base_y + perp.y * half, base_x - perp.x * half, base_y - perp.y * half);
    draw_line(tip_x, tip_y, tip_x - vec.x * wing + perp.x * wing, tip_y - vec.y * wing + perp.y * wing);
    draw_line(tip_x, tip_y, tip_x - vec.x * wing - perp.x * wing, tip_y - vec.y * wing - perp.y * wing);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function Battle_EnemyAct(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(e)) {
        e = Status_Tick(e);
        if (Battle_CheckEnd(_bc, p, e)) return;
        Battle_Message(_bc, Loc_T("combat.msg.enemy_stunned", "{enemy} is stunned!", { enemy: e.name }), BSTATE_MENU);
        _bc.enemy_actions_remaining = 0;
        _bc.turn = TURN_PLAYER;
        _bc.p = p;
        _bc.e = e;
        return;
    }

    Battle_EnemyInitActionBudget(_bc, e);

    if (!variable_instance_exists(_bc, "enemy_last_action_used_skill")) _bc.enemy_last_action_used_skill = false;
    var force_damage_skill_debug = Debug_EnemyForceDamageSkillOnly();
    var can_use_skill = force_damage_skill_debug ? true : !_bc.enemy_last_action_used_skill;
    var skill_id = can_use_skill ? Battle_EnemyChooseSkill(e, p, _bc.enemy_actions_remaining, _bc.enemy_turn_used_skills, force_damage_skill_debug) : -1;
    var use_skill = (skill_id != -1);
    var sk = use_skill ? SkillDB_Get(skill_id) : undefined;

    if (force_damage_skill_debug && use_skill && is_struct(sk) && variable_struct_exists(sk, "mp_cost")) {
        var forced_mp = max(0, round(real(sk.mp_cost)));
        if (variable_struct_exists(e, "mp")) e.mp = max(e.mp, forced_mp);
    }
    var consumes_turn = true;
    var free_action = false;
    var set_actions = 0;
    var extra_turns = 0;
    var follow_state = BSTATE_MENU;
    var res = undefined;
    var enemy_targets_self = false;
    var qte_hp_before = -1;
    var qte_status_before = [];

    if (use_skill) {
        if (!is_struct(sk)) sk = SkillDB_Get(skill_id);
        enemy_targets_self = (variable_struct_exists(sk, "target") && sk.target == TGT_SELF);
        var enemy_skill_target = enemy_targets_self ? e : p;
        qte_hp_before = enemy_targets_self ? -1 : p.hp;
        qte_status_before = enemy_targets_self ? [] : Battle_StatusSnapshot(p);
        res = Skill_Use(e, enemy_skill_target, skill_id);
        if (enemy_targets_self) e = enemy_skill_target; else p = enemy_skill_target;
        if (!res.ok) {
            use_skill = false;
        } else {
            free_action = variable_struct_exists(res, "free_action") && res.free_action;
            set_actions = variable_struct_exists(res, "set_enemy_actions") ? max(0, round(real(res.set_enemy_actions))) : 0;
            extra_turns = variable_struct_exists(res, "extra_turns") ? max(0, round(real(res.extra_turns))) : 0;
            consumes_turn = !free_action;
        }
    }

    if (use_skill) {
        if (res.ok) {
            var exists_used = false;
            for (var ui = 0; ui < array_length(_bc.enemy_turn_used_skills); ui++) {
                if (_bc.enemy_turn_used_skills[ui] == skill_id) { exists_used = true; break; }
            }
            if (!exists_used) array_push(_bc.enemy_turn_used_skills, skill_id);
            _bc.enemy_last_action_used_skill = true;
            _bc.skill_banner_active = true;
            _bc.skill_banner_name = sk.name;
            var skill_sfx_h = SFX_PlaySkill(skill_id);
            if (skill_sfx_h == -1) SFX_PlayEnemySpecial(e.id);
        }
        var fx2 = noone;
        // Enemy actions intentionally skip skill VFX; only player skills spawn battle FX.

        if (consumes_turn) _bc.enemy_actions_remaining = max(0, _bc.enemy_actions_remaining - 1);
        if (set_actions > 0) _bc.enemy_actions_remaining = max(_bc.enemy_actions_remaining, set_actions);
        if (extra_turns > 0) _bc.enemy_actions_remaining += extra_turns;
        _bc.enemy_actions_remaining = clamp(_bc.enemy_actions_remaining, 0, ENEMY_ACTION_CHAIN_MAX);
        follow_state = (_bc.enemy_actions_remaining > 0) ? BSTATE_ENEMY_ACT : BSTATE_MENU;

        if (!enemy_targets_self && Battle_EnemySkillCanUseDefQTE(sk, res, p)) {
            Battle_DefQTEStart(_bc, e, sk, res, follow_state, qte_hp_before, qte_status_before);
            _bc.p = p;
            _bc.e = e;
            return;
        }

        if (!res.hit) {
            var miss_class_id = -1;
            if (variable_struct_exists(p, "class_id")) miss_class_id = p.class_id;
            SFX_PlayMissOrBlocked(true, miss_class_id);
        }
        if (res.hit && res.dmg > 0) {
            CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
        }

        if (Battle_CheckEnd(_bc, p, e)) return;
        var end_skill_pack = Battle_EnemyFinalizeTurnState(_bc, p, e);
        if (end_skill_pack.ended) return;
        p = end_skill_pack.player;
        e = end_skill_pack.enemy;

        var skill_msg = Battle_EnemySkillComposeMessage(e.name, res);
        Battle_Message(_bc, skill_msg, follow_state, fx2);
    } else {
        var ew = _bc.enemy_weapon;
        if (!is_struct(ew) || !variable_struct_exists(ew, "power")) {
            ew = { power:2, stat_type:STAT_STR, acc:0, preferred_class:-1 };
            _bc.enemy_weapon = ew;
        }

        // Enemy basic attack SFX (non-skill turn).
        SFX_PlayEnemySpecial(e.id);

        var hit_res_e = Combat_AttemptHit(e, p, Combat_AttackBonus(e, ew));

        _bc.last_hit = hit_res_e.hit;
        _bc.last_dmg = 0;
        _bc.last_crit = false;
        p = hit_res_e.defender;

        if (_bc.last_hit) {
            var crit_bonus_e = Status_GetSum(e, "crit_bonus");
            _bc.last_crit = Combat_CritCheck(e, 1 + crit_bonus_e);
            var dmg_pack_e = Combat_ApplyDamage(e, p, ew, (_bc.last_crit ? 2 : 1), 1, { is_skill: false });
            _bc.last_dmg = dmg_pack_e.dmg;
            p = dmg_pack_e.defender;
        }

        e = Status_ConsumeByField(e, "consume_on_attack");
        _bc.enemy_last_action_used_skill = false;

        if (Battle_CheckEnd(_bc, p, e)) return;
        _bc.enemy_actions_remaining = max(0, _bc.enemy_actions_remaining - 1);
        follow_state = (_bc.enemy_actions_remaining > 0) ? BSTATE_ENEMY_ACT : BSTATE_MENU;

        if (!_bc.last_hit) {
            var miss_class_id2 = -1;
            if (variable_struct_exists(p, "class_id")) miss_class_id2 = p.class_id;
            SFX_PlayMissOrBlocked(true, miss_class_id2);
        }

        if (_bc.last_hit && _bc.last_dmg > 0) {
            CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
        }

        var end_attack_pack = Battle_EnemyFinalizeTurnState(_bc, p, e);
        if (end_attack_pack.ended) return;
        p = end_attack_pack.player;
        e = end_attack_pack.enemy;

        var basic_msg = Battle_EnemySkillComposeMessage(e.name, { hit: _bc.last_hit, crit: _bc.last_crit, dmg: _bc.last_dmg, msg: "" });
        Battle_Message(_bc, basic_msg, follow_state);
    }
}
