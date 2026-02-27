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

    dmg = max(0, dmg);
    _defender.hp = max(0, _defender.hp - dmg);

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

function Combat_Log(_text) {
    if (_text == "") return;
    var bc = instance_find(obj_battle_controller, 0);
    if (!instance_exists(bc)) return;
    if (!variable_instance_exists(bc, "combat_log") || !is_array(bc.combat_log)) {
        bc.combat_log = [];
    }
    var log = bc.combat_log;
    array_push(log, _text);
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

function Battle_GrantRewards(_p, _e) {
    var out = {
        player: _p,
        exp_gain: 0,
        levels_gained: 0,
        stat_points_gained: 0,
        loot: []
    };

    if (is_struct(_e)) {
        if (variable_struct_exists(_e, "exp")) {
            var exp_gain = max(0, round(real(_e.exp)));
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
            }
        }

        // shared loot system
        var loot = Loot_RollEnemy(_e);
        _p.inventory = Loot_Grant(_p.inventory, loot);
        out.loot = loot;
    }

    out.player = _p;
    return out;
}

function Player_OnDeath(_p) {
    var gs = GameState_Get();
    _p.hp = 0;
    GameState_SetPlayer(_p);
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
        GameState_SetPlayer(_p);
        EnemyPersist_ResolveBattle(true);

        if (rewards.exp_gain > 0) Combat_Log("EXP +" + string(rewards.exp_gain));
        if (rewards.levels_gained > 0) {
            Combat_Log("Level up x" + string(rewards.levels_gained)
                + " (+" + string(rewards.stat_points_gained) + " points)");
        }
        if (is_array(rewards.loot) && array_length(rewards.loot) > 0) Combat_Log("Loot found.");
        Battle_Message(_bc, _e.name + " has been slain.", BSTATE_END_RUN);
        return true;
    }

    if (_p.hp <= 0) {
        _bc.battle_over = true;
        Player_OnDeath(_p);
        return true;
    }

    return false;
}

function Battle_PlayerAttack(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        p = Status_Tick(p);
        if (Battle_CheckEnd(_bc, p, e)) return;
        Battle_Message(_bc, "You are stunned!", BSTATE_ENEMY_ACT);
        _bc.turn = TURN_ENEMY;
        _bc.p = p;
        _bc.e = e;
        return;
    }

    Combat_Log("Player attacked.");
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

    var hit_res = Combat_AttemptHit(p, e, Combat_AttackBonus(p, w));

    _bc.last_hit = hit_res.hit;
    _bc.last_dmg = 0;
    _bc.last_crit = false;
    e = hit_res.defender;

    if (_bc.last_hit) {
        var crit_bonus = Status_GetSum(p, "crit_bonus");
        _bc.last_crit = Combat_CritCheck(p, 1 + crit_bonus);
        var dmg_pack = Combat_ApplyDamage(p, e, w, (_bc.last_crit ? 2 : 1), 1);
        _bc.last_dmg = dmg_pack.dmg;
        e = dmg_pack.defender;
    }

    p = Status_ConsumeByField(p, "consume_on_attack");

    if (Battle_CheckEnd(_bc, p, e)) return;

    if (!_bc.last_hit) {
        SFX_PlayMissOrBlocked(false, -1);
        Battle_Message(_bc, "You missed!", BSTATE_ENEMY_ACT);
    } else if (_bc.last_crit) {
        if (_bc.last_dmg > 0 && instance_exists(_bc.enemy_inst)) {
            SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
        }
        Battle_Message(_bc, "Critical hit! " + string(_bc.last_dmg) + " dmg!", BSTATE_ENEMY_ACT);
    } else {
        if (_bc.last_dmg > 0 && instance_exists(_bc.enemy_inst)) {
            SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
        }
        Battle_Message(_bc, "You hit for " + string(_bc.last_dmg) + " dmg!", BSTATE_ENEMY_ACT);
    }

    p = Status_Tick(p);
    if (Battle_CheckEnd(_bc, p, e)) return;
    _bc.turn = TURN_ENEMY;
    _bc.p = p;
    _bc.e = e;
}

function Battle_PlayerSkill(_bc, _skill_id) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        p = Status_Tick(p);
        if (Battle_CheckEnd(_bc, p, e)) return;
        Battle_Message(_bc, "You are stunned!", BSTATE_ENEMY_ACT);
        _bc.turn = TURN_ENEMY;
        _bc.p = p;
        _bc.e = e;
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

    if (res.msg != "") {
        Battle_Message(_bc, res.msg, BSTATE_ENEMY_ACT, fx);
    } else if (!res.hit) {
        SFX_PlayMissOrBlocked(false, -1);
        Battle_Message(_bc, "Skill missed!", BSTATE_ENEMY_ACT, fx);
    } else if (res.crit) {
        Battle_Message(_bc, "Critical skill! " + string(res.dmg) + " dmg!", BSTATE_ENEMY_ACT, fx);
    } else if (res.dmg > 0) {
        if (instance_exists(_bc.enemy_inst)) {
            SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
        }
        Battle_Message(_bc, "Skill hit for " + string(res.dmg) + " dmg!", BSTATE_ENEMY_ACT, fx);
    } else {
        Battle_Message(_bc, "Skill used.", BSTATE_ENEMY_ACT, fx);
    }

    p = Status_Tick(p);
    if (Battle_CheckEnd(_bc, p, e)) return;
    _bc.turn = TURN_ENEMY;
    _bc.p = p;
    _bc.e = e;
}

function Battle_PlayerItem(_bc, _item_id) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        p = Status_Tick(p);
        if (Battle_CheckEnd(_bc, p, e)) return;
        Battle_Message(_bc, "You are stunned!", BSTATE_ENEMY_ACT);
        _bc.turn = TURN_ENEMY;
        _bc.p = p;
        _bc.e = e;
        return;
    }

    var item = ItemDB_Get(_item_id);
    var target = (item.use.target == TGT_SELF) ? p : e;
    var res = Item_Use(_item_id, p, target);
    if (res.ok) {
        Combat_Log("Player used " + item.name);
    }

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
    p = Status_Tick(p);
    if (Battle_CheckEnd(_bc, p, e)) return;
    _bc.turn = TURN_ENEMY;
    _bc.p = p;
    _bc.e = e;
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

    var pr = RollD20() + StatMod(Combat_EffectiveStat(p, STAT_AGI));
    var er = RollD20() + StatMod(Combat_EffectiveStat(e, STAT_AGI));

    if (pr >= er) {
        EnemyPersist_ResolveBattle(false);
        Battle_Message(_bc, "You ran away!", BSTATE_END_RUN);
    } else {
        _bc.turn = TURN_ENEMY;
        Battle_Message(_bc, "Couldn't escape!", BSTATE_ENEMY_ACT);
    }
}

function Battle_EndRun(_bc) {
    _bc.battle_over = true;
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

function Battle_EnemyChooseSkill(_e, _p, _actions_remaining = -1, _used_skills = []) {
    if (!is_array(_e.skills) || array_length(_e.skills) <= 0) return -1;

    var candidates = [];
    for (var i = 0; i < array_length(_e.skills); i++) {
        var sid = _e.skills[i];
        var sk = SkillDB_Get(sid);
        if (!is_struct(sk) || sk.id == -1) continue;
        if (variable_struct_exists(sk, "enemy_passive_action_budget") && sk.enemy_passive_action_budget) continue;
        if (variable_struct_exists(sk, "enemy_once_per_turn") && sk.enemy_once_per_turn) {
            var already_used = false;
            for (var us = 0; us < array_length(_used_skills); us++) {
                if (_used_skills[us] == sid) { already_used = true; break; }
            }
            if (already_used) continue;
        }
        if (!Skill_CanUse(_e, sk)) continue;
        if (!Skill_EnemyCanTrigger(sk, _e, _p, _actions_remaining)) continue;

        var chance = Skill_EnemyUseChance(sk);
        if (chance <= 0) continue;
        if (random(1) <= chance) array_push(candidates, sid);
    }

    if (array_length(candidates) <= 0) return -1;
    return candidates[irandom(array_length(candidates) - 1)];
}

function Battle_EnemyAct(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(e)) {
        e = Status_Tick(e);
        if (Battle_CheckEnd(_bc, p, e)) return;
        Battle_Message(_bc, e.name + " is stunned!", BSTATE_MENU);
        _bc.enemy_actions_remaining = 0;
        _bc.turn = TURN_PLAYER;
        _bc.p = p;
        _bc.e = e;
        return;
    }

    Battle_EnemyInitActionBudget(_bc, e);

    var skill_id = Battle_EnemyChooseSkill(e, p, _bc.enemy_actions_remaining, _bc.enemy_turn_used_skills);
    var use_skill = (skill_id != -1);
    var sk = use_skill ? SkillDB_Get(skill_id) : undefined;
    var consumes_turn = true;
    var free_action = false;
    var set_actions = 0;
    var extra_turns = 0;
    var follow_state = BSTATE_MENU;
    var res = undefined;

    if (use_skill) {
        if (!is_struct(sk)) sk = SkillDB_Get(skill_id);
        var enemy_targets_self = (variable_struct_exists(sk, "target") && sk.target == TGT_SELF);
        var enemy_skill_target = enemy_targets_self ? e : p;
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
            _bc.skill_banner_active = true;
            _bc.skill_banner_name = sk.name;
            SFX_PlayEnemySpecial(e.id);
            SFX_PlaySkill(skill_id);
        }
        var fx2 = noone;
        // Enemy actions intentionally skip skill VFX; only player skills spawn battle FX.
        if (Battle_CheckEnd(_bc, p, e)) return;

        if (consumes_turn) _bc.enemy_actions_remaining = max(0, _bc.enemy_actions_remaining - 1);
        if (set_actions > 0) _bc.enemy_actions_remaining = max(_bc.enemy_actions_remaining, set_actions);
        if (extra_turns > 0) _bc.enemy_actions_remaining += extra_turns;
        _bc.enemy_actions_remaining = clamp(_bc.enemy_actions_remaining, 0, ENEMY_ACTION_CHAIN_MAX);
        follow_state = (_bc.enemy_actions_remaining > 0) ? BSTATE_ENEMY_ACT : BSTATE_MENU;

        if (res.msg != "") {
            Battle_Message(_bc, e.name + ": " + res.msg, follow_state, fx2);
        } else if (!res.hit) {
            var miss_class_id = -1;
            if (variable_struct_exists(p, "class_id")) miss_class_id = p.class_id;
            SFX_PlayMissOrBlocked(true, miss_class_id);
            Battle_Message(_bc, e.name + " missed!", follow_state, fx2);
        } else if (res.crit) {
            if (res.dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " crit! " + string(res.dmg) + " dmg!", follow_state, fx2);
        } else {
            if (res.dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " hits for " + string(res.dmg) + " dmg!", follow_state, fx2);
        }
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
            var dmg_pack_e = Combat_ApplyDamage(e, p, ew, (_bc.last_crit ? 2 : 1), 1);
            _bc.last_dmg = dmg_pack_e.dmg;
            p = dmg_pack_e.defender;
        }

        e = Status_ConsumeByField(e, "consume_on_attack");

        if (Battle_CheckEnd(_bc, p, e)) return;
        _bc.enemy_actions_remaining = max(0, _bc.enemy_actions_remaining - 1);
        follow_state = (_bc.enemy_actions_remaining > 0) ? BSTATE_ENEMY_ACT : BSTATE_MENU;

        if (!_bc.last_hit) {
            var miss_class_id2 = -1;
            if (variable_struct_exists(p, "class_id")) miss_class_id2 = p.class_id;
            SFX_PlayMissOrBlocked(true, miss_class_id2);
            Battle_Message(_bc, e.name + " missed!", follow_state);
        } else if (_bc.last_crit) {
            if (_bc.last_dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " crit! " + string(_bc.last_dmg) + " dmg!", follow_state);
        } else {
            if (_bc.last_dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " hits for " + string(_bc.last_dmg) + " dmg!", follow_state);
        }
    }

    var enemy_turn_finished = (_bc.enemy_actions_remaining <= 0);
    if (enemy_turn_finished) {
        e = Status_Tick(e);
        if (Battle_CheckEnd(_bc, p, e)) return;
        _bc.turn = TURN_PLAYER;
    } else {
        _bc.turn = TURN_ENEMY;
    }
    _bc.p = p;
    _bc.e = e;
}
