function Combat_Initiative(_ch) {
    return RollD20() + StatMod(Stat_Get(_ch, STAT_AGI));
}

function Combat_AttackBonus(_attacker, _weapon) {
    // Minimal version: MOD(relevant) + weapon.acc
    var rel_mod = 0;
    switch (_weapon.stat_type) {
        case STAT_STR:  rel_mod = StatMod(Stat_Get(_attacker, STAT_STR)); break;
        case STAT_AGI:  rel_mod = StatMod(Stat_Get(_attacker, STAT_AGI)); break;
        case STAT_INT:  rel_mod = StatMod(Stat_Get(_attacker, STAT_INT)); break;
        default:        rel_mod = 0; break;
    }
    return rel_mod + _weapon.acc;
}

function Combat_DodgeBonus(_defender) {
    return StatMod(Stat_Get(_defender, STAT_AGI)) + Status_GetSum(_defender, "dodge_bonus");
}

function Combat_CritCheck(_attacker, _crit_bonus) {
    // Base 5% crit, bonus from LUCK and any explicit crit bonus (percent).
    var luck_mod = StatMod(Stat_Get(_attacker, STAT_LUCK));
    if (luck_mod < 0) luck_mod = 0;
    var crit_chance = 0.05 + (luck_mod * 0.01) + (_crit_bonus * 0.01);
    crit_chance = clamp(crit_chance, 0.05, 0.50); // 5% to 50% max
    return (random(1) < crit_chance);
}

function Combat_Damage(_attacker, _defender, _weapon) {
    var rel_mod = 0;
    switch (_weapon.stat_type) {
        case STAT_STR: rel_mod = StatMod(Stat_Get(_attacker, STAT_STR)); break;
        case STAT_AGI: rel_mod = StatMod(Stat_Get(_attacker, STAT_AGI)); break;
        case STAT_INT: rel_mod = StatMod(Stat_Get(_attacker, STAT_INT)); break;
        default: rel_mod = 0; break;
    }

    var raw = _weapon.power + rel_mod;

    // softened mitigation: use half of DEF mod (rounded down)
    var mitig = floor(StatMod(Stat_Get(_defender, STAT_DEF)) / 2);

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

    dmg = max(0, dmg);
    _defender.hp = max(0, _defender.hp - dmg);

    return { dmg: dmg, defender: _defender };
}

function FX_Spawn(_sprite, _x, _y, _frames, _speed) {
    if (_sprite == noone) return noone;
    var fx = instance_create_layer(_x, _y, "Instances", obj_fx);
    fx.sprite_index = _sprite;
    fx.life = _frames;
    fx.image_speed = _speed;
    return fx;
}

function Battle_GrantRewards(_p, _e) {
    if (is_struct(_e)) {
        if (variable_struct_exists(_e, "exp")) _p = Player_AddExp(_p, _e.exp);

        // shared loot system
        var loot = Loot_RollEnemy(_e);
        _p.inventory = Loot_Grant(_p.inventory, loot);
    }

    return _p;
}

function Player_OnDeath(_p) {
    var gs = GameState_Get();
    _p.hp = _p.max_hp;
    _p.mp = _p.max_mp;
    GameState_SetPlayer(_p);

    GameState_SetBattleReturn(gs.checkpoint.room, gs.checkpoint.x, gs.checkpoint.y);
    GameState_SetJustReturned(true);
    room_goto(gs.checkpoint.room);
}

// --------------------
// BATTLE FLOW
// --------------------
function Battle_CheckEnd(_bc, _p, _e) {
    if (_e.hp <= 0) {
        _bc.battle_over = true;
        _p = Battle_GrantRewards(_p, _e);
        GameState_SetPlayer(_p);

        var gs = GameState_Get();
        if (variable_struct_exists(gs, "battle") && gs.battle.enemy_persist_id != "") {
            RoomState_SetRemoved(gs.battle.enemy_room, gs.battle.enemy_persist_id);
        }

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

function Battle_Message(_bc, _text, _next_state) {
    _bc.message_text = _text;
    _bc.message_next_state = _next_state;
    _bc.battle_state = BSTATE_MESSAGE;
}

function Battle_PlayerAttack(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        p = Status_Tick(p);
        Battle_Message(_bc, "You are stunned!", BSTATE_ENEMY_ACT);
        _bc.turn = TURN_ENEMY;
        _bc.p = p;
        _bc.e = e;
        return;
    }

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
    _bc.turn = TURN_ENEMY;
    _bc.p = p;
    _bc.e = e;
}

function Battle_PlayerSkill(_bc, _skill_id) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        p = Status_Tick(p);
        Battle_Message(_bc, "You are stunned!", BSTATE_ENEMY_ACT);
        _bc.turn = TURN_ENEMY;
        _bc.p = p;
        _bc.e = e;
        return;
    }

    var skill = SkillDB_Get(_skill_id);
    var target = (skill.target == TGT_SELF) ? p : e;
    var res = Skill_Use(p, target, _skill_id);

    if (res.fx_sprite != noone) {
        var tx = _bc.enemy_fx_x;
        var ty = _bc.enemy_fx_y;
        if (skill.target == TGT_SELF) {
            tx = _bc.player_fx_x;
            ty = _bc.player_fx_y;
        }
        FX_Spawn(res.fx_sprite, tx, ty, res.fx_frames, res.fx_speed);
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
        Battle_Message(_bc, res.msg, BSTATE_ENEMY_ACT);
    } else if (!res.hit) {
        Battle_Message(_bc, "Skill missed!", BSTATE_ENEMY_ACT);
    } else if (res.crit) {
        Battle_Message(_bc, "Critical skill! " + string(res.dmg) + " dmg!", BSTATE_ENEMY_ACT);
    } else if (res.dmg > 0) {
        if (instance_exists(_bc.enemy_inst)) {
            SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
        }
        Battle_Message(_bc, "Skill hit for " + string(res.dmg) + " dmg!", BSTATE_ENEMY_ACT);
    } else {
        Battle_Message(_bc, "Skill used.", BSTATE_ENEMY_ACT);
    }

    p = Status_Tick(p);
    _bc.turn = TURN_ENEMY;
    _bc.p = p;
    _bc.e = e;
}

function Battle_PlayerItem(_bc, _item_id) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(p)) {
        p = Status_Tick(p);
        Battle_Message(_bc, "You are stunned!", BSTATE_ENEMY_ACT);
        _bc.turn = TURN_ENEMY;
        _bc.p = p;
        _bc.e = e;
        return;
    }

    var item = ItemDB_Get(_item_id);
    var target = (item.use.target == TGT_SELF) ? p : e;
    var res = Item_Use(_item_id, p, target);

    if (res.fx_sprite != noone) {
        FX_Spawn(res.fx_sprite, _bc.player_fx_x, _bc.player_fx_y, res.fx_frames, res.fx_speed);
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

    Battle_Message(_bc, res.msg, BSTATE_ENEMY_ACT);
    p = Status_Tick(p);
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

    var pr = RollD20() + StatMod(Stat_Get(p, STAT_AGI));
    var er = RollD20() + StatMod(Stat_Get(e, STAT_AGI));

    if (pr >= er) {
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
    room_goto(gs.battle.return_room);
}

function Battle_EnemyAct(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    if (!Status_CanAct(e)) {
        e = Status_Tick(e);
        Battle_Message(_bc, e.name + " is stunned!", BSTATE_MENU);
        _bc.turn = TURN_PLAYER;
        _bc.p = p;
        _bc.e = e;
        return;
    }

    var use_skill = false;
    var skill_id = -1;
    var sk = undefined;
    if (is_array(e.skills) && array_length(e.skills) > 0) {
        skill_id = e.skills[irandom(array_length(e.skills) - 1)];
        sk = SkillDB_Get(skill_id);
        if (Skill_CanUse(e, sk) && random(1) < 0.35) use_skill = true;
    }

    if (use_skill) {
        if (!is_struct(sk)) sk = SkillDB_Get(skill_id);
        var res = Skill_Use(e, p, skill_id);
        if (res.fx_sprite != noone) {
            var tx2 = _bc.enemy_fx_x;
            var ty2 = _bc.enemy_fx_y;
            if (sk.target == TGT_SELF) {
                tx2 = _bc.enemy_fx_x;
                ty2 = _bc.enemy_fx_y;
            } else {
                tx2 = _bc.player_fx_x;
                ty2 = _bc.player_fx_y;
            }
            FX_Spawn(res.fx_sprite, tx2, ty2, res.fx_frames, res.fx_speed);
        }
        if (Battle_CheckEnd(_bc, p, e)) return;

        if (res.msg != "") {
            Battle_Message(_bc, e.name + ": " + res.msg, BSTATE_MENU);
        } else if (!res.hit) {
            Battle_Message(_bc, e.name + " missed!", BSTATE_MENU);
        } else if (res.crit) {
            if (res.dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " crit! " + string(res.dmg) + " dmg!", BSTATE_MENU);
        } else {
            if (res.dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " hits for " + string(res.dmg) + " dmg!", BSTATE_MENU);
        }
    } else {
        var ew = _bc.enemy_weapon;
        if (!is_struct(ew) || !variable_struct_exists(ew, "power")) {
            ew = { power:2, stat_type:STAT_STR, acc:0, preferred_class:-1 };
            _bc.enemy_weapon = ew;
        }

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

        if (!_bc.last_hit) {
            Battle_Message(_bc, e.name + " missed!", BSTATE_MENU);
        } else if (_bc.last_crit) {
            if (_bc.last_dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " crit! " + string(_bc.last_dmg) + " dmg!", BSTATE_MENU);
        } else {
            if (_bc.last_dmg > 0) CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_Message(_bc, e.name + " hits for " + string(_bc.last_dmg) + " dmg!", BSTATE_MENU);
        }
    }

    e = Status_Tick(e);
    _bc.turn = TURN_PLAYER;
    _bc.p = p;
    _bc.e = e;
}
