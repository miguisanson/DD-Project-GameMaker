// Combat maths (D22, D77, D80). Spec: .planning/research/combat-spec.md. Everything in this block is a pure function of its inputs
// (plus the character structs) so the vectors in combat-vectors.json can pin it down.

// Spec section 1/8: initiative is SPD; the higher SPD acts first, a tie goes to the player (until the turn timeline, D74).
function Combat_Initiative(_ch) {
    return Combat_EffectiveStat(_ch, STAT_SPD);
}

function Combat_PlayerActsFirst(_spd_player, _spd_enemy) {
    return (_spd_player >= _spd_enemy);
}

function Combat_EffectiveStat(_ch, _stat_id) {
    var v = Stat_Get(_ch, _stat_id);
    var m = Status_StatMult(_ch, _stat_id);   // Burning: DEF x0.75 (spec section 10)
    if (m != 1) v = RoundHalfUp(v * m);
    return max(1, round(v));
}

// D35: the only difficulty knob left: the QTE assist multiplier on damage the player takes (1 = off).
function Combat_AssistMult(_defender) {
    if (is_struct(_defender) && variable_struct_exists(_defender, "is_player") && _defender.is_player) {
        return Difficulty_Profile().assist_damage_taken_mult;
    }
    return 1;
}

// Spec section 4. Power of an attack before the stat ratio:
function Combat_PowerBasic(_weapon_power) {
    return COMBAT_POWER_SCALE * _weapon_power;
}

function Combat_PowerSkill(_skill_power, _power_mult, _weapon_power) {
    return COMBAT_POWER_SCALE * (_skill_power + COMBAT_WEAPON_SKILL_SHARE * _weapon_power) * _power_mult;
}

function Combat_PowerEnemySkill(_skill_power, _power_mult) {
    return COMBAT_POWER_SCALE * _skill_power * _power_mult;
}

// Power of the equipped weapon (D22); no weapon counts as COMBAT_UNARMED_POWER.
function Combat_WeaponPower(_ch) {
    if (is_struct(_ch) && variable_struct_exists(_ch, "equip") && is_struct(_ch.equip) && variable_struct_exists(_ch.equip, "weapon") && _ch.equip.weapon != 0) {
        var w = ItemDB_Get(_ch.equip.weapon);
        if (is_struct(w) && variable_struct_exists(w, "power")) return w.power;
    }
    return COMBAT_UNARMED_POWER;
}

// A basic attack's damage source from a weapon item: { power (final formula power), stat_type }.
function Combat_BasicSource(_weapon) {
    return { power: Combat_PowerBasic(_weapon.power), stat_type: _weapon.stat_type, acc: 0 };
}

// The one damage formula (spec section 4). mult = every multiplier except the QTE grade; 0 means "blocked" (Guard).
// grade 1.00 -> round_half_up(raw), at least 1. Another grade is moved at least 1 away from that (D61: Perfect is visibly above OK), then at least 1.
function Combat_RatioDamage(_power, _atk, _def, _grade = 1, _mult = 1) {
    if (_power <= 0 || _mult == 0) return 0;
    var raw = _power * max(1, _atk) * _mult / (max(1, _atk) + max(1, _def));
    var ok = max(1, RoundHalfUp(raw));
    if (_grade == 1) return ok;
    var g = RoundHalfUp(raw * _grade);
    if (_grade > 1) g = max(g, ok + 1);
    else g = min(g, ok - 1);
    return max(1, g);
}

function Combat_AttackStat(_attacker, _src) {
    var stat_id = (variable_struct_exists(_src, "stat_type") && Stat_IsValid(_src.stat_type)) ? _src.stat_type : STAT_ATK;
    return Combat_EffectiveStat(_attacker, stat_id);
}

// Grade-OK damage of one hit with no statuses: what the hit is "worth" (the bot and tooltips use it).
function Combat_Damage(_attacker, _defender, _src) {
    return Combat_RatioDamage(_src.power, Combat_AttackStat(_attacker, _src), Combat_EffectiveStat(_defender, STAT_DEF), 1, 1);
}

function Combat_HealAmount(_power, _stat) {
    return _power + floor(_stat / 4);
}

// Spec section 4, crit rule: no base chance, no LUCK; only a crit_bonus (percent) from statuses/passives.
function Combat_CritChance(_crit_bonus) {
    return clamp(_crit_bonus / 100, 0, COMBAT_CRIT_CHANCE_MAX);
}

function Combat_CritCheck(_attacker, _crit_bonus) {
    var chance = Combat_CritChance(_crit_bonus);
    if (chance <= 0) return false;
    return RunRng_Chance("combat", chance);   // C1: run randomness comes from the run's combat stream
}

// D80: no dice. The only way an enemy action fails to land is Evasion on the PLAYER: the next damaging enemy action is fully dodged and Evasion is used up.
// An Evasion status on an enemy does nothing (the player never misses, D6).
function Combat_TryDodge(_attacker, _defender) {
    var res = { dodged: false, defender: _defender };
    if (is_struct(_defender) && variable_struct_exists(_defender, "is_player") && _defender.is_player && Status_HasFlag(_defender, "force_dodge")) {
        res.dodged = true;
        res.defender = Status_ConsumeByField(_defender, "consume_on_defend");
    }
    return res;
}

// _src = { power (final formula power), stat_type }. _ctx: { grade_mult, is_skill }. Statuses: dmg_mult (attacker), guard_mult (defender, consumed on hit).
function Combat_ApplyDamage(_attacker, _defender, _src, _crit_mult = 1, _skill_mult = 1, _ctx = undefined) {
    var dmg_ctx = is_struct(_ctx) ? _ctx : {};
    var grade = variable_struct_exists(dmg_ctx, "grade_mult") ? dmg_ctx.grade_mult : 1;

    var mult = Status_GetMul(_attacker, "dmg_mult") * _crit_mult * _skill_mult;
    var guard_mult = Status_GetMul(_defender, "guard_mult");
    if (guard_mult != 1) {
        mult *= guard_mult;
        _defender = Status_ConsumeByField(_defender, "consume_on_hit");
    }
    mult *= Combat_AssistMult(_defender);
    mult *= Combat_BreakMult(_defender);   // spec section 11: a BROKEN enemy takes +50% until its next turn

    var dmg = Combat_RatioDamage(_src.power, Combat_AttackStat(_attacker, _src), Combat_EffectiveStat(_defender, STAT_DEF), grade, mult);

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

// I-052 / I-060: how big an effect animation is drawn, and how long it plays. Pure helpers (Test_Suite_Fx checks them for every player skill).
// Size is the VISIBLE part of the effect (the sprite's bounding box, tight round the pixels of every frame), not its canvas: the canvases are
// 48 px with 1-20 px of empty margin, so sizing the canvas drew an Ice Spear smaller than the slime it hit (I-060).
function FX_ContentSide(_sprite) {
    var w = sprite_get_bbox_right(_sprite) - sprite_get_bbox_left(_sprite) + 1;
    var h = sprite_get_bbox_bottom(_sprite) - sprite_get_bbox_top(_sprite) + 1;
    var side = max(w, h);
    if (side <= 0) side = max(sprite_get_width(_sprite), sprite_get_height(_sprite));
    return side;
}

// The wanted size of the visible effect for a target: FX_TARGET_FIT x the target's longest side, never smaller than the target itself
// (an effect is at least as big as what it hits), never more than FX_MAX_DRAW_PX world px (the screen is 160 x 144; the cap wins over a bigger target).
function FX_DrawnSide(_target_px) {
    var t = max(1, _target_px);
    return max(min(t, FX_MAX_DRAW_PX), min(t * FX_TARGET_FIT, FX_MAX_DRAW_PX));
}

// Scale that draws the effect's visible part at FX_DrawnSide(target).
function FX_ScaleFor(_sprite, _target_px) {
    var side = FX_ContentSide(_sprite);
    if (side <= 0) return 1;
    return FX_DrawnSide(_target_px) / side;
}

// World px of the longest side of an object's sprite (an enemy in battle), 0 when it has none.
function FX_TargetSize(_inst) {
    if (!instance_exists(_inst) || _inst.sprite_index == noone) return 0;
    return max(sprite_get_width(_inst.sprite_index) * abs(_inst.image_xscale), sprite_get_height(_inst.sprite_index) * abs(_inst.image_yscale));
}

// Sprite frames that pass per game frame at image_speed 1 (the sprite's own playback speed).
function FX_FramesPerStep(_sprite) {
    var game_fps = game_get_speed(gamespeed_fps);
    if (!is_real(game_fps) || game_fps <= 0) game_fps = 60;
    var spd = sprite_get_speed(_sprite);
    if (sprite_get_speed_type(_sprite) == SPR_SPEED_FPS) spd = spd / game_fps;
    return spd;
}

// Game frames an effect takes to play once through at this image_speed.
function FX_PlaybackFrames(_sprite, _image_speed) {
    var per_step = FX_FramesPerStep(_sprite) * _image_speed;
    if (per_step <= 0) return 9999;
    return ceil(sprite_get_number(_sprite) / per_step);
}

// _image_speed, raised if needed so the effect plays in no more than _max_frames game frames.
function FX_SpeedForMaxFrames(_sprite, _image_speed, _max_frames) {
    var per_step = FX_FramesPerStep(_sprite);
    if (_max_frames <= 0 || per_step <= 0) return _image_speed;
    return max(_image_speed, (sprite_get_number(_sprite) / (per_step * _max_frames)) * 1.001);
}

function FX_Spawn(_sprite, _x, _y, _frames, _speed, _scale = SKILL_FX_SCALE) {
    if (_sprite == noone) return noone;
    var fx = instance_create_layer(_x, _y, "Instances", obj_fx);
    fx.sprite_index = _sprite;
    fx.image_xscale = _scale;
    fx.image_yscale = _scale;
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

function FX_CenterOn(_sprite, _inst, _scale = SKILL_FX_SCALE) {
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
    var fx_scale = max(0.01, abs(_scale));
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

// Seconds -> game frames at the current room speed (frame-rate independent waits).
function Combat_SecToFrames(_seconds) {
    var game_fps = game_get_speed(gamespeed_fps);
    if (!is_real(game_fps) || game_fps <= 0) game_fps = 60;
    return max(1, round(_seconds * game_fps));
}

function Battle_Message(_bc, _text, _next_state, _fx = noone, _hold_frames = -1) {
    _bc.message_text = _text;
    _bc.message_next_state = _next_state;
    _bc.battle_state = BSTATE_MESSAGE;
    _bc.wait_fx = _fx;
    _bc.wait_timer = (_hold_frames >= 0) ? _hold_frames : Combat_SecToFrames(COMBAT_ACTION_HOLD_SEC);
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

    _p = Card_OnVictory(_p);   // C2: Field Medic, Second Wind, Scrounger
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
    Run_OnPlayerDeath();   // C1: ends the run in the profile, deletes the run save, then plays the death scene
}

// ---- The turn timeline, stun push-back, stagger and BREAK (spec section 11; D19 D74 D75 D79 D92) ----
// Pure: the numbers live in these functions so check_combat_vectors.py can pin them down. The battle owns one timeline (bc.tl) with two fighters,
// TL_PLAYER (listed first, so it wins ties) and TL_ENEMY.
#macro TURN_GAUGE_MAX 100          // a fighter acts when its gauge reaches this; one tick adds its SPD
#macro TURN_STEADFAST_TURNS 2      // after a stun the fighter is stun-immune for this many of its own turns
#macro TURN_PREVIEW_COUNT 5        // the strip shows the next 5 turns (D74)
#macro TURN_BOSS_PUSH 0.5          // a boss as the target of a stun is pushed back half as far (D75)
#macro TL_PLAYER 0
#macro TL_ENEMY 1
#macro BREAK_DAMAGE_MULT 1.5       // a BROKEN enemy takes +50% damage until its next turn
#macro STAGGER_PERFECT_MULT 1.5
#macro STAGGER_STUN_MULT 2

function Turn_Fighter(_id, _spd, _boss = false) {
    return { id: _id, spd: max(1, round(_spd)), gauge: 0, steadfast: 0, boss: _boss };
}

function Turn_New(_fighters) {
    return { fighters: _fighters };
}

function Turn_Find(_tl, _id) {
    for (var i = 0; i < array_length(_tl.fighters); i++) {
        if (_tl.fighters[i].id == _id) return _tl.fighters[i];
    }
    return undefined;
}

function Turn_Copy(_tl) {
    var out = [];
    for (var i = 0; i < array_length(_tl.fighters); i++) {
        var f = _tl.fighters[i];
        array_push(out, { id: f.id, spd: f.spd, gauge: f.gauge, steadfast: f.steadfast, boss: f.boss });
    }
    return { fighters: out };
}

function Turn_SetSpd(_tl, _id, _spd) {
    var f = Turn_Find(_tl, _id);
    if (is_struct(f)) f.spd = max(1, round(_spd));
}

// Who acts next. Nobody ready: tick (every gauge += SPD) until somebody is. The highest gauge acts, a tie goes to the first in the list (the player).
// The actor pays TURN_GAUGE_MAX (the overflow is kept) and its Steadfast counts down by one.
function Turn_Next(_tl) {
    var fs = _tl.fighters;
    var n = array_length(fs);
    var ready = false;
    for (var i = 0; i < n; i++) { if (fs[i].gauge >= TURN_GAUGE_MAX) ready = true; }
    if (!ready) {
        var ticks = 1000000;
        for (var j = 0; j < n; j++) {
            var need = max(1, (TURN_GAUGE_MAX - fs[j].gauge + fs[j].spd - 1) div fs[j].spd);
            ticks = min(ticks, need);
        }
        for (var k = 0; k < n; k++) fs[k].gauge += fs[k].spd * ticks;
    }
    var best = -1;
    for (var m = 0; m < n; m++) {
        if (fs[m].gauge >= TURN_GAUGE_MAX && (best < 0 || fs[m].gauge > fs[best].gauge)) best = m;
    }
    var actor = fs[best];
    actor.gauge -= TURN_GAUGE_MAX;
    actor.steadfast = max(0, actor.steadfast - 1);
    return actor.id;
}

// The next _n actors' ids, on a copy: nothing in the real timeline moves.
function Turn_Preview(_tl, _n = TURN_PREVIEW_COUNT) {
    var c = Turn_Copy(_tl);
    var out = [];
    for (var i = 0; i < _n; i++) array_push(out, Turn_Next(c));
    return out;
}

// A stun lands: the fighter is pushed back (a boss half as far) and becomes Steadfast. Returns false, changing nothing, while it is Steadfast.
function Turn_Stun(_tl, _id) {
    var f = Turn_Find(_tl, _id);
    if (!is_struct(f) || f.steadfast > 0) return false;
    f.gauge -= f.boss ? floor(TURN_GAUGE_MAX * TURN_BOSS_PUSH) : TURN_GAUGE_MAX;
    f.steadfast = TURN_STEADFAST_TURNS;
    return true;
}

// A plain push-back (BREAK): one full turn, bosses too.
function Turn_Push(_tl, _id, _amount = TURN_GAUGE_MAX) {
    var f = Turn_Find(_tl, _id);
    if (is_struct(f)) f.gauge -= _amount;
}

function Stagger_Gain(_power, _stun_skill, _perfect) {
    var v = _power * 0.5;
    if (_stun_skill) v *= STAGGER_STUN_MULT;
    if (_perfect) v *= STAGGER_PERFECT_MULT;
    return max(1, RoundHalfUp(v));
}

function Stagger_Max(_rank, _boss) {
    return (4 + 4 * max(1, _rank)) * (_boss ? 2 : 1);
}

// Adds to the enemy's meter. Returns true when this fills it: BREAK (meter back to 0, broken until its next turn). Nothing fills while broken.
function Stagger_Add(_ch, _amount) {
    if (!variable_struct_exists(_ch, "stagger_max") || _ch.stagger_max <= 0 || _ch.broken) return false;
    _ch.stagger = min(_ch.stagger_max, _ch.stagger + max(0, round(_amount)));
    if (_ch.stagger < _ch.stagger_max) return false;
    _ch.stagger = 0;
    _ch.broken = true;
    return true;
}

function Stagger_EndBreak(_ch) {
    if (variable_struct_exists(_ch, "broken")) _ch.broken = false;
}

// Spec section 4's mult: +50% while BROKEN.
function Combat_BreakMult(_ch) {
    return (is_struct(_ch) && variable_struct_exists(_ch, "broken") && _ch.broken) ? BREAK_DAMAGE_MULT : 1;
}

// A skill that stuns leaves a Stun status on its target; this turns it into the push-back at once and removes the marker.
// Returns "pushed", "steadfast" (resisted) or "none" (there was no marker).
function Battle_ConsumeStun(_tl, _ch, _id) {
    if (!is_struct(_ch) || !Status_Has(_ch, STATUS_STUN)) return "none";
    Status_Remove(_ch, STATUS_STUN);
    return Turn_Stun(_tl, _id) ? "pushed" : "steadfast";
}

// ---- Battle glue for the timeline (B3). These touch the battle controller _bc (fields set in its Create event). ----

// The player's or enemy's turn is over: SPD is read again (Bleeding slows), then the timeline picks who is next. Returns TL_PLAYER or TL_ENEMY.
function Battle_TurnAdvance(_bc) {
    Battle_PhaseSync(_bc);   // B4: a boss that crossed an HP threshold has its new SPD from this turn on
    Turn_SetSpd(_bc.tl, TL_PLAYER, Combat_EffectiveStat(_bc.p, STAT_SPD));
    Turn_SetSpd(_bc.tl, TL_ENEMY, Combat_EffectiveStat(_bc.e, STAT_SPD));
    _bc.tl_prev_who = _bc.tl_who;
    var who = Turn_Next(_bc.tl);
    _bc.tl_who = who;
    array_push(_bc.turn_log, who);
    _bc.tl_slide_start = current_time;   // D97: the strip slides for TURN_SLIDE_MS
    _bc.tl_slide_kind = 0;               // 0 = the row moves left one slot, 1 = it fades in place (a push-back reordered it)
    _bc.player_turn_start_applied = false;   // a fast player gets his start-of-turn effects again
    _bc.enemy_action_pending = (who == TL_ENEMY);
    if (who == TL_ENEMY) {
        Stagger_EndBreak(_bc.e);   // BROKEN lasts until the enemy's next turn starts
        _bc.turn = TURN_ENEMY;
    } else {
        _bc.turn = TURN_PLAYER;
    }
    return who;
}

// The Stun markers a skill left on either fighter become push-backs on the timeline (D75). Returns the text to add to the battle message.
function Battle_StunResolve(_bc) {
    var note = "";
    var re = Battle_ConsumeStun(_bc.tl, _bc.e, TL_ENEMY);
    if (re == "pushed") {
        note += " " + Loc_T("combat.msg.pushed_back", "{name} is pushed back!", { name: _bc.e.name });
        _bc.tl_slide_start = current_time;
        _bc.tl_slide_kind = 1;
    } else if (re == "steadfast") {
        note += " " + Loc_T("combat.msg.steadfast", "{name} is Steadfast!", { name: _bc.e.name });
    }
    var rp = Battle_ConsumeStun(_bc.tl, _bc.p, TL_PLAYER);
    if (rp == "pushed") {
        note += " " + Loc_T("combat.msg.pushed_back_you", "You are pushed back!");
        _bc.tl_slide_start = current_time;
        _bc.tl_slide_kind = 1;
    } else if (rp == "steadfast") {
        note += " " + Loc_T("combat.msg.steadfast_you", "You are Steadfast!");
    }
    return note;
}

// A landed player hit fills the enemy's stagger meter; a full meter is a BREAK (D75, D92). Returns the text to add to the battle message.
function Battle_StaggerHit(_bc, _power, _stun_skill, _perfect, _hits = 1) {
    var e = _bc.e;
    if (!is_struct(e) || e.hp <= 0) return "";
    var gain = Stagger_Gain(_power, _stun_skill, _perfect) * max(1, _hits);
    _bc.stagger_flash_start = current_time;
    if (!Stagger_Add(e, gain)) return "";
    Turn_Push(_bc.tl, TL_ENEMY);   // pushed back one turn
    _bc.tl_slide_start = current_time;
    _bc.tl_slide_kind = 1;
    _bc.break_start = current_time;
    var last_key = global.sfx_last_key;   // the BREAK sound is a second layer on top of the grade sound: the grade stays the "last key" the bot checks
    SFX_Play(Qte_GradeSfxKey(QTE_PERFECT));
    global.sfx_last_key = last_key;
    CameraShake_Start(QTE_SHAKE_PERFECT_MAG, QTE_SHAKE_PERFECT_FRAMES, SHAKE_DIR_H);
    var note = " " + Loc_T("combat.msg.break", "BREAK! {name} takes +50% damage!", { name: e.name });
    var cancelled = EnemyAI_Break(_bc.ai);   // B4 (D75): a BREAK during a wind-up cancels the big attack
    if (cancelled >= 0) {
        _bc.enemy_plan = undefined;          // the cached plan was that attack
        note += " " + Loc_T("combat.msg.windup_broken", "{enemy}'s {skill} is broken off!", { enemy: e.name, skill: SkillDB_Get(cancelled).name });
    }
    return note;
}

// For the strip (D74, D79, D99): the current actor first, then the next four. The Foresight preview (the enemy's next action, D79) rides on the
// enemy slot that holds that action: the current slot while it is the enemy's turn and it has not acted yet, else the first upcoming enemy slot.
// While the enemy is in the middle of an action nothing is shown (the action after it is not planned yet).
// slot = { who, current, foresight (the Battle_EnemyNextActionPreview struct, or undefined), windup (B4: the slot of the big attack that follows a wind-up) }
function Battle_TimelineSlots(_bc) {
    var out = [{ who: _bc.tl_who, current: true, foresight: undefined, windup: false }];
    var next = Turn_Preview(_bc.tl, TURN_PREVIEW_COUNT - 1);
    var wind = (_bc.ai.windup >= 0) && ((_bc.tl_who == TL_PLAYER) || _bc.enemy_action_pending);   // B4: the big attack that follows a wind-up is on the first enemy slot still to come
    var fore = undefined;
    var show_fore = (_bc.tl_who == TL_PLAYER) || _bc.enemy_action_pending;
    if (show_fore) {
        var pv = Battle_EnemyNextActionPreview(_bc);
        if (pv.visible) fore = pv;
    }
    if (_bc.tl_who == TL_ENEMY && is_struct(fore)) { out[0].foresight = fore; fore = undefined; }
    if (_bc.tl_who == TL_ENEMY && wind) { out[0].windup = true; wind = false; }
    for (var i = 0; i < array_length(next); i++) {
        var f = undefined;
        var wm = false;
        if (next[i] == TL_ENEMY && is_struct(fore)) { f = fore; fore = undefined; }
        if (next[i] == TL_ENEMY && wind) { wm = true; wind = false; }
        array_push(out, { who: next[i], current: false, foresight: f, windup: wm });
    }
    return out;
}

// ---- Floating numbers (D92): one per landed hit, size and colour by the QTE grade. Times are real ms (current_time), so a hit-stop does not freeze them. ----
#macro POP_MS 900
function Battle_PopAdd(_bc, _text, _on_player, _style, _scale) {
    var keep = [];
    for (var i = 0; i < array_length(_bc.pops); i++) {
        if (current_time - _bc.pops[i].start < POP_MS) array_push(keep, _bc.pops[i]);
    }
    array_push(keep, { text: _text, on_player: _on_player, style: _style, scale: _scale, start: current_time, n: array_length(keep) });
    _bc.pops = keep;
}

// A hit of the player on the enemy. style = the grade key (Perfect biggest and brightest, Weak small and dim).
function Battle_HitPop(_bc, _dmg, _key, _crit = false) {
    if (_dmg <= 0) return;
    var sc = 1;
    switch (_key) {
        case QTE_PERFECT: sc = 2.0; break;
        case QTE_GOOD:    sc = 1.5; break;
        case QTE_OK:      sc = 1.0; break;
        default:          sc = 0.75; break;
    }
    if (_crit) sc += 0.5;
    Battle_PopAdd(_bc, string(_dmg), false, _key, sc);
}

// A hit of the enemy on the player.
function Battle_PlayerHitPop(_bc, _dmg, _crit = false) {
    if (_dmg <= 0) return;
    Battle_PopAdd(_bc, string(_dmg), true, "hurt", _crit ? 1.75 : 1.25);
}

function Battle_HealPop(_bc, _amount) {
    if (_amount <= 0) return;
    Battle_PopAdd(_bc, "+" + string(_amount), true, "heal", 1.0);
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

        Battle_Message(_bc, Loc_T("combat.msg.enemy_slain", "{enemy} has been slain.", { enemy: _e.name }), BSTATE_END_RUN, noone, COMBAT_ACTION_DELAY);
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
    var gui_w = max(1, Display_GuiW());
    var gui_h = max(1, Display_GuiH());
    var tx = gui_w * 0.5;
    var ty = gui_h * 0.5;

    if (instance_exists(_bc.enemy_inst)) {
        var espr = _bc.enemy_inst.sprite_index;
        if (espr != noone) {
            // The camera is 1:1 with the picture, so a world point is (point - camera) * Display_WorldScale() GUI units from the picture's corner.
            var sx = Display_WorldScale();
            var sy = sx;
            var ex = (_bc.enemy_inst.x - sprite_get_xoffset(espr) - _bc.cam_base_x) * sx;
            var ey = (_bc.enemy_inst.y - sprite_get_yoffset(espr) - _bc.cam_base_y) * sy;
            var ew = sprite_get_width(espr) * abs(_bc.enemy_inst.image_xscale) * sx;
            var eh = sprite_get_height(espr) * abs(_bc.enemy_inst.image_yscale) * sy;
            tx = ex + (ew * 0.5);
            ty = ey + (eh * 0.5);
        }
    }

    return { x: round(tx), y: round(ty) };
}

// ---- QTE part 1: the sliding bar (D56, D60, D61). Everything from here to Qte_Result is pure and checked by Test_Suite_Qte. ----
// A cursor sweeps the bar once, left to right, in params.sweep_ms. The bright zone is centred at QTE_ZONE_CENTRE_PCT of the sweep and
// has three nested half widths in ms (Perfect inside Good inside OK). A press outside the OK zone, or no press before the cursor ends, is Weak.
// Nothing here misses: Weak is 0.75 x damage, never 0 (D5, D20).

// Starting numbers per weapon kind (D60: daggers and bows fast + wide, heavy slow + narrow, everything else medium). Tuned by playtest.
function Qte_BarParams(_kind) {
    switch (_kind) {
        case "bow":    return { sweep_ms: 850,  perfect_half_width: 60, good_half_width: 130, ok_half_width: 220 };
        case "dagger": return { sweep_ms: 750,  perfect_half_width: 55, good_half_width: 120, ok_half_width: 200 };
        case "staff":  return { sweep_ms: 1200, perfect_half_width: 55, good_half_width: 115, ok_half_width: 190 };
        case "heavy":  return { sweep_ms: 1500, perfect_half_width: 50, good_half_width: 100, ok_half_width: 170 };
    }
    return { sweep_ms: 1100, perfect_half_width: 60, good_half_width: 120, ok_half_width: 200 };   // "default" and "sword"
}

// Which row of Qte_BarParams a weapon uses (the weapon_kind field of its ItemDB entry).
function Qte_WeaponKind(_weapon) {
    if (is_struct(_weapon) && variable_struct_exists(_weapon, "weapon_kind")) return string(_weapon.weapon_kind);
    return "default";
}

// D35: the one accessibility setting, a multiplier that widens every zone. 1 until the settings screen stores one (GAP-09).
function Qte_AssistMult() {
    var gs = GameState_Get();
    if (is_struct(gs) && variable_struct_exists(gs, "settings") && is_struct(gs.settings) && variable_struct_exists(gs.settings, "qte_window_mult")) {
        return clamp(real(gs.settings.qte_window_mult), 1, 3);
    }
    return 1;
}

// Milliseconds one frame adds to the QTE clock, from delta_time (microseconds). Capped so a hitch cannot skip the bar (QTE-01, QTE-14).
function Qte_StepMs(_delta_us) {
    return clamp(_delta_us, 0, QTE_MAX_STEP_US) / 1000;
}

// Cursor position along the bar, 0..1, from elapsed ms (negative during the lead-in).
function Qte_CursorPos(_ms, _params) {
    return clamp(_ms / max(1, _params.sweep_ms), 0, 1);
}

function Qte_ZoneCentreMs(_params) {
    return _params.sweep_ms * QTE_ZONE_CENTRE_PCT / 100;
}

// The press time to judge. A press more than QTE_EARLY_BUFFER_MS before the sweep starts is dropped (it is the press that chose ATTACK, or mashing);
// one closer than that is kept and judged at 0. Returns QTE_NO_PRESS for a dropped press.
function Qte_BufferPress(_ms) {
    if (_ms < -QTE_EARLY_BUFFER_MS) return QTE_NO_PRESS;
    return max(0, _ms);
}

// Foresight (D79): the player's Perfect zones are x1.5 wider while he has a status with `perfect_widen`. 1 without one.
function Qte_PerfectWiden(_ch) {
    if (!is_struct(_ch)) return 1;
    return max(1, Status_GetMul(_ch, "perfect_widen")) * (1 + Card_PassiveSum(_ch, "perfect_widen"));   // Foresight (D79) x Steady Hands (C2)
}

// A Perfect half width after the widening (ms).
function Qte_WidenedHalfWidth(_half_width, _widen) {
    return _half_width * max(1, _widen);
}

// The bar's params with the Perfect zone widened (the Good and OK zones, the sweep and the centre stay as they are).
function Qte_WidenPerfect(_params, _widen) {
    var par = { sweep_ms: _params.sweep_ms, perfect_half_width: Qte_WidenedHalfWidth(_params.perfect_half_width, _widen), good_half_width: _params.good_half_width, ok_half_width: _params.ok_half_width };
    return par;
}

// Grade of a press at _press_ms (QTE_NO_PRESS = none). _assist widens every zone (>= 1).
function Qte_Grade(_press_ms, _params, _assist = 1) {
    if (_press_ms < 0 || _press_ms >= _params.sweep_ms) return QTE_WEAK;
    var widen = max(1, _assist);
    var d = abs(_press_ms - Qte_ZoneCentreMs(_params));
    if (d <= _params.perfect_half_width * widen) return QTE_PERFECT;
    if (d <= _params.good_half_width * widen) return QTE_GOOD;
    if (d <= _params.ok_half_width * widen) return QTE_OK;
    return QTE_WEAK;
}

// D61 starting numbers, tuned by playtest.
function Qte_GradeMult(_key) {
    switch (_key) {
        case QTE_PERFECT: return 1.30;
        case QTE_GOOD:    return 1.10;
        case QTE_OK:      return 1.00;
    }
    return 0.75;
}

function Qte_GradeRank(_key) {
    switch (_key) {
        case QTE_PERFECT: return 3;
        case QTE_GOOD:    return 2;
        case QTE_OK:      return 1;
    }
    return 0;
}

function Qte_GradeLabel(_key) {
    switch (_key) {
        case QTE_PERFECT: return Loc_T("battle.action.timing.perfect", QTE_PERFECT);
        case QTE_GOOD:    return Loc_T("battle.action.timing.good", QTE_GOOD);
        case QTE_OK:      return Loc_T("battle.action.timing.ok", QTE_OK);
    }
    return Loc_T("battle.action.timing.weak", QTE_WEAK);
}

// A distinct existing sound per grade (SFX_RegisterDefaults maps these keys to existing assets).
function Qte_GradeSfxKey(_key) {
    switch (_key) {
        case QTE_PERFECT: return "qte_perfect";
        case QTE_GOOD:    return "qte_good";
        case QTE_OK:      return "qte_ok";
    }
    return "qte_weak";
}

// The grade as the struct the equipment passives and the resolver pass around.
function Qte_Result(_key) {
    return { key: _key, label: Qte_GradeLabel(_key), mult: Qte_GradeMult(_key), hit: true };
}

// ---- QTE part 2: arrow sequences for player skills (D57, D58) and the defence bar (D59, D60, D21). Pure up to Battle_DefenceAdjustStatuses;
// checked by Test_Suite_QteArrows and Test_Suite_QteDefence. ----

// A whole-number amount after a grade multiplier: round half up, but a multiplier other than 1.00 always moves a base of 1 or more by at
// least 1 (so Perfect is visibly above OK and Weak below it at small numbers). _min_result is the floor: 1 for a player's hit (D20, a hit that
// was going to deal damage never drops to 0), 0 for damage let through a defence.
function Qte_ScaleAmount(_base, _mult, _min_result) {
    var b = round(real(_base));
    if (b < 1 || _mult == 1) return b;
    var r = floor(b * _mult + 0.5);
    if (_mult > 1) r = max(r, b + 1);
    else r = min(r, b - 1);
    return max(_min_result, r);
}

// The fixed arrow sequence of a player skill (D57): 3 arrows for the cheap skills (3 MP), 4 for the mid ones (4 MP), 5 for the strongest (5 MP).
// Learned like spells: the same every cast. An unknown skill gets a plain 3.
function Qte_SkillSequence(_skill_id) {
    return Card_TrimSequence(_skill_id, Qte_SkillSequenceBase(_skill_id));   // C2: a held upgrade can shorten it
}

function Qte_SkillSequenceBase(_skill_id) {
    switch (_skill_id) {
        case SKILL_WOUND:          return [DOWN, RIGHT, UP];
        case SKILL_MUSCLE_UP:      return [UP, DOWN, UP];
        case SKILL_REV_UP:         return [LEFT, UP, RIGHT];
        case SKILL_EVASION:        return [LEFT, DOWN, LEFT];
        case SKILL_TAKE_AIM:       return [RIGHT, UP, RIGHT];
        case SKILL_MEDITATION:     return [DOWN, DOWN, UP];
        case SKILL_FORESIGHT:      return [UP, LEFT, DOWN];
        case SKILL_HILT_BASH:      return [DOWN, LEFT, RIGHT, UP];
        case SKILL_POISON_ARROW:   return [RIGHT, RIGHT, DOWN, LEFT];
        case SKILL_POISON_MIST:    return [LEFT, DOWN, RIGHT, DOWN];
        case SKILL_FIREBALL:       return [UP, RIGHT, DOWN, LEFT];
        case SKILL_HORIZ_SLASH:    return [LEFT, RIGHT, LEFT, RIGHT, DOWN];
        case SKILL_DOUBLE_SHOT:    return [RIGHT, UP, RIGHT, DOWN, RIGHT];
        case SKILL_ICE_SPEAR:      return [UP, DOWN, LEFT, DOWN, UP];
    }
    return [UP, DOWN, LEFT];
}

// The time bar of a sequence _len arrows long. limit_ms = the bar drains over it; fast_ms = finish with no mistake within it for Perfect.
// _assist (D35) stretches both; the cost of a wrong press stays.
// _perfect_widen (Foresight, D79) stretches only the Perfect window (fast_ms), not the time bar.
function Qte_SeqParams(_len, _assist = 1, _perfect_widen = 1) {
    var widen = max(1, _assist);
    return {
        limit_ms: (QTE_SEQ_BASE_MS + QTE_SEQ_PER_ARROW_MS * _len) * widen,
        fast_ms: (QTE_SEQ_FAST_BASE_MS + QTE_SEQ_FAST_PER_ARROW_MS * _len) * widen * max(1, _perfect_widen),
        penalty_ms: QTE_SEQ_PENALTY_MS
    };
}

// The state of one arrow sequence. clock is real ms since the sequence started; a wrong press adds penalty_ms to what the bar has used.
// last = what the latest press did ("ok", "wrong", or "" for none / ignored); key is "" until done, then the grade.
function Qte_SeqNew(_seq, _assist = 1, _perfect_widen = 1) {
    var par = Qte_SeqParams(array_length(_seq), _assist, _perfect_widen);
    return {
        seq: _seq, len: array_length(_seq), idx: 0, clock: 0, mistakes: 0,
        limit_ms: par.limit_ms, fast_ms: par.fast_ms, penalty_ms: par.penalty_ms,
        done: false, key: "", timed_out: false, finish_ms: 0, last: ""
    };
}

// Milliseconds of the time bar used so far.
function Qte_SeqElapsed(_st) {
    return _st.clock + _st.mistakes * _st.penalty_ms;
}

// The time bar's fill, 1 (full) to 0 (empty).
function Qte_SeqLeft(_st) {
    return clamp((_st.limit_ms - Qte_SeqElapsed(_st)) / _st.limit_ms, 0, 1);
}

function Qte_SeqTimeOut(_st) {
    _st.done = true;
    _st.timed_out = true;
    _st.key = QTE_WEAK;
    _st.finish_ms = _st.limit_ms;
}

// Time passes to _ms (real ms since the start). Ends the sequence as Weak when the bar is empty.
function Qte_SeqTick(_st, _ms) {
    if (_st.done) return _st;
    _st.clock = max(_st.clock, _ms);
    _st.last = "";
    if (Qte_SeqElapsed(_st) >= _st.limit_ms) Qte_SeqTimeOut(_st);
    return _st;
}

// An arrow press at _ms. The right arrow advances; a wrong one does not and costs penalty_ms. Done after the last arrow:
// no mistakes and within fast_ms = Perfect, no mistakes and slower = Good, one mistake = OK, two or more = Weak. An empty bar = Weak.
function Qte_SeqPress(_st, _dir, _ms) {
    Qte_SeqTick(_st, _ms);
    if (_st.done) return _st;
    if (_dir == _st.seq[_st.idx]) {
        _st.idx++;
        _st.last = "ok";
        if (_st.idx >= _st.len) {
            _st.done = true;
            _st.finish_ms = Qte_SeqElapsed(_st);
            if (_st.mistakes == 0) _st.key = (_st.finish_ms <= _st.fast_ms) ? QTE_PERFECT : QTE_GOOD;
            else if (_st.mistakes == 1) _st.key = QTE_OK;
            else _st.key = QTE_WEAK;
        }
    } else {
        _st.mistakes++;
        _st.last = "wrong";
        if (Qte_SeqElapsed(_st) >= _st.limit_ms) Qte_SeqTimeOut(_st);
    }
    return _st;
}

// Replays scripted presses [{ t: ms, dir }] and returns the finished state (no press in time = timed out). The live battle calls
// Qte_SeqPress / Qte_SeqTick one frame at a time instead; this is the same grader for tests.
function Qte_SeqRun(_seq, _presses, _assist = 1, _perfect_widen = 1) {
    var st = Qte_SeqNew(_seq, _assist, _perfect_widen);
    for (var i = 0; i < array_length(_presses); i++) {
        if (st.done) break;
        Qte_SeqPress(st, _presses[i].dir, _presses[i].t);
    }
    if (!st.done) Qte_SeqTick(st, 1000000);
    return st;
}

// The arrows pressed this frame, in UP, DOWN, LEFT, RIGHT order (the move actions: WASD, arrow keys, d-pad, left stick).
function Battle_ArrowPresses() {
    var out = [];
    if (Input_UIPressed("move_up")) array_push(out, UP);
    if (Input_UIPressed("move_down")) array_push(out, DOWN);
    if (Input_UIPressed("move_left")) array_push(out, LEFT);
    if (Input_UIPressed("move_right")) array_push(out, RIGHT);
    return out;
}

// The defence bar of a big enemy attack (D60: fixed per attack so it can be learned; quick bites are fast, the mini boss's Ramming is slow and narrow).
// Same widget and same Qte_Grade as the attack bar. Tuned by playtest.
function Qte_DefenceParams(_skill_id) {
    switch (_skill_id) {
        case SKILL_POISON_FANGS:    return { sweep_ms: 900,  perfect_half_width: 55, good_half_width: 120, ok_half_width: 200 };
        case SKILL_BITE:            return { sweep_ms: 800,  perfect_half_width: 55, good_half_width: 115, ok_half_width: 190 };
        case SKILL_VINE_TRAP:       return { sweep_ms: 1300, perfect_half_width: 60, good_half_width: 125, ok_half_width: 200 };
        case SKILL_SCORCHING_TOUCH: return { sweep_ms: 1000, perfect_half_width: 55, good_half_width: 120, ok_half_width: 195 };
        case SKILL_GHOST_CUT:       return { sweep_ms: 750,  perfect_half_width: 50, good_half_width: 110, ok_half_width: 180 };
        case SKILL_RAMMING:         return { sweep_ms: 1500, perfect_half_width: 50, good_half_width: 100, ok_half_width: 170 };
        case SKILL_PALE_HYMN:       return { sweep_ms: 1400, perfect_half_width: 50, good_half_width: 105, ok_half_width: 175 };
    }
    return Qte_BarParams("default");
}

// Share of the hit that gets through (D59 starting numbers): Perfect blocks most of it, Weak none.
function Qte_DefenceMult(_key) {
    switch (_key) {
        case QTE_PERFECT: return 0.25;
        case QTE_GOOD:    return 0.50;
        case QTE_OK:      return 0.75;
    }
    return 1.00;
}

// Damage that gets through the defence. Round half up, and anything above Weak lets through at least 1 less than the full hit.
function Qte_DefenceDamage(_base, _key) {
    return Qte_ScaleAmount(_base, Qte_DefenceMult(_key), 0);
}

// Turns a status keeps after the defence (D21: it can only get shorter, never longer). Perfect resists it (0). Good halves it, OK takes a
// quarter off (round half up, never below 1 turn), Weak leaves it as the hit applied it.
function Qte_DefenceStatusTurns(_key, _turns) {
    if (_turns <= 0) return 0;
    var r = _turns;
    switch (_key) {
        case QTE_PERFECT: return 0;
        case QTE_GOOD:    r = floor(_turns * 0.5 + 0.5); break;
        case QTE_OK:      r = floor(_turns * 0.75 + 0.5); break;
    }
    return clamp(r, 1, _turns);
}

// Whether an enemy skill that just landed on the player gets the defence bar: a damaging skill flagged as a big attack (D7, D59).
// To make another enemy attack defendable, set uses_defensive_qte on its skill and add a row to Qte_DefenceParams.
function Battle_EnemySkillCanBeDefended(_skill, _res, _target) {
    if (!is_struct(_skill) || !is_struct(_res) || !is_struct(_target)) return false;
    if (!variable_struct_exists(_skill, "uses_defensive_qte") || !_skill.uses_defensive_qte) return false;
    if (!variable_struct_exists(_skill, "effect") || string(_skill.effect) != "damage") return false;
    if (!variable_struct_exists(_target, "is_player") || !_target.is_player) return false;
    if (!variable_struct_exists(_res, "ok") || !_res.ok) return false;
    if (!variable_struct_exists(_res, "hit") || !_res.hit) return false;
    if (!variable_struct_exists(_res, "dmg") || round(real(_res.dmg)) <= 0) return false;
    return true;
}

// The ids of the statuses a skill applies.
function Battle_SkillStatusIds(_skill) {
    var ids = [];
    if (!is_struct(_skill)) return ids;
    if (variable_struct_exists(_skill, "status")) {
        var sid = round(real(_skill.status));
        if (sid != -1) array_push(ids, sid);
    }
    if (variable_struct_exists(_skill, "status_list") && is_array(_skill.status_list)) {
        for (var i = 0; i < array_length(_skill.status_list); i++) {
            var sid_m = round(real(_skill.status_list[i]));
            if (sid_m != -1 && !array_contains(ids, sid_m)) array_push(ids, sid_m);
        }
    }
    return ids;
}

// Applies the defence grade to the statuses the hit put on the player (D21, D59). _status_ids: the skill's statuses; _before_snapshot:
// Battle_StatusSnapshot of the player before the skill. What the hit ADDED is cut and never what the player already had; nothing here can make
// a status longer or bigger. Poison: the added stacks go through Qte_DefenceStatusTurns. Others: the turns the hit left are cut the same way
// (never below the turns the player had before). Perfect puts the status back as it was (turns, stacks, burn power), or removes it.
// Returns { player, status_msg (what is still applied), resist_msg (what was resisted) }.
function Battle_DefenceAdjustStatuses(_p, _status_ids, _before_snapshot, _key) {
    var p = _p;
    var applied_names = [];
    var resisted_names = [];
    for (var i = 0; i < array_length(_status_ids); i++) {
        var sid = round(real(_status_ids[i]));
        var before = Battle_StatusSnapshotEntry(_before_snapshot, sid);
        var now = Status_Find(p, sid);
        if (!is_struct(now)) continue;
        var before_turns = is_struct(before) ? before.turns : 0;
        var before_stacks = is_struct(before) ? before.stacks : 0;
        var now_stacks = variable_struct_exists(now, "stacks") ? now.stacks : 1;
        var cfg = StatusDB_Get(sid);
        var is_poison = (variable_struct_exists(cfg, "dot_kind") && cfg.dot_kind == "poison");
        var added_stacks = max(0, now_stacks - before_stacks);
        var changed = (now.turns > before_turns) || (added_stacks > 0) || (!is_struct(before));
        if (!changed) continue;   // the hit added nothing to this status

        var name = (is_struct(cfg) && variable_struct_exists(cfg, "name")) ? string(cfg.name) : "";
        var kept_added = is_poison ? Qte_DefenceStatusTurns(_key, added_stacks) : Qte_DefenceStatusTurns(_key, now.turns);
        if (kept_added <= 0) {   // resisted: back to how it was
            if (is_struct(before)) {
                now.turns = before.turns;
                now.stacks = before.stacks;
                now.power = before.power;
            } else {
                p = Status_Remove(p, sid);
            }
            if (name != "" && !array_contains(resisted_names, name)) array_push(resisted_names, name);
            continue;
        }
        if (is_poison) {
            now.stacks = before_stacks + min(added_stacks, kept_added);
            now.turns = now.stacks;
        } else {
            now.turns = min(now.turns, max(before_turns, kept_added));   // a Bleeding stack the hit added stays; only the turns are cut
        }
        if (name != "" && !array_contains(applied_names, name)) array_push(applied_names, name);
    }

    var out = { player: p, status_msg: "", resist_msg: "" };
    if (array_length(applied_names) > 0) out.status_msg = Skill_BuildAppliedStatusMessage(applied_names);
    if (array_length(resisted_names) > 0) {
        var list = "";
        for (var n = 0; n < array_length(resisted_names); n++) list += ((n > 0) ? ", " : "") + resisted_names[n];
        out.resist_msg = Loc_T("combat.msg.defence.resisted", "Resisted {status}.", { status: list });
    }
    return out;
}

// The player's turn is over: his statuses tick (Poison, Burning, Bleeding, Foresight), then the timeline says who is next. A fast player is next
// again; nothing a skill does grants extra actions (D19: the old rule that a stun gave extra actions is gone, it was exploitable, S1).
function Battle_PlayerFinalizeTurn(_bc, _p, _e) {
    var p = Status_Tick(_p);
    var e = _e;
    if (Battle_CheckEnd(_bc, p, e)) return true;
    _bc.p = p;
    _bc.e = e;
    Battle_TurnAdvance(_bc);
    return false;
}

function Battle_AttackTimingBegin(_bc) {
    var p = _bc.p;

    // The bar is fixed per weapon so it can be learned (D60). The clock starts in the lead-in, so the press that chose ATTACK cannot count.
    _bc.qte_perfect_widen = Qte_PerfectWiden(p);   // Foresight (D79)
    _bc.qte_params = Qte_WidenPerfect(Qte_BarParams(Qte_WeaponKind(_bc.player_weapon)), _bc.qte_perfect_widen);
    _bc.qte_assist = Qte_AssistMult();
    _bc.qte_ms = -QTE_LEAD_IN_MS;
    _bc.qte_press_ms = QTE_NO_PRESS;
    _bc.qte_active = true;
    _bc.battle_state = BSTATE_ATTACK_TIMING;
}

// The enemy shake and the small camera shakes of a landed hit. After a Perfect's hit-stop Step_0 calls this again, so the freeze comes first.
function Battle_QteImpactFeedback(_bc) {
    if (_bc.last_dmg > 0 && instance_exists(_bc.enemy_inst)) {
        SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_FRAMES, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
    }
    if (_bc.qte_result_key == QTE_PERFECT) CameraShake_Start(QTE_SHAKE_PERFECT_MAG, QTE_SHAKE_PERFECT_FRAMES, SHAKE_DIR_H);
    if (_bc.qte_result_key == QTE_GOOD) CameraShake_Start(QTE_SHAKE_GOOD_MAG, QTE_SHAKE_GOOD_FRAMES, SHAKE_DIR_H);
}

// The player's basic attack always lands (D20): damage = base x the grade's multiplier, never 0.
function Battle_PlayerAttackResolveTimed(_bc, _timing) {
    var p = _bc.p;
    var e = _bc.e;

    // Equipment passives can forgive/upgrade the grade.
    var timing = Equip_ModifyTimedAttackResult(p, _timing);
    var timing_key = timing.key;

    _bc.qte_active = false;
    _bc.qte_result_text = timing.label;
    _bc.qte_result_key = timing_key;
    _bc.qte_result_mult = timing.mult;
    _bc.qte_result_ms = QTE_RESULT_MS;
    var word_pos = Battle_AttackTimingTarget(_bc);
    _bc.qte_word_x = word_pos.x;
    _bc.qte_word_y = word_pos.y;

    var player_class_id = -1;
    if (variable_struct_exists(p, "class_id")) player_class_id = p.class_id;
    SFX_PlayClassAttack(player_class_id);
    SFX_Play(Qte_GradeSfxKey(timing_key));

    var w = _bc.player_weapon;
    if (!is_struct(w) || !variable_struct_exists(w, "power")) {
        var wid = p.equip.weapon;
        w = ItemDB_Get(wid);
        if (w.id == 0) w = { power:COMBAT_UNARMED_POWER, stat_type:STAT_ATK, acc:0, preferred_class:-1 };
        _bc.player_weapon = w;
    }

    _bc.last_hit = true;
    var crit_bonus = Status_GetSum(p, "crit_bonus");
    _bc.last_crit = Combat_CritCheck(p, crit_bonus);
    var dmg_pack = Combat_ApplyDamage(p, e, Combat_BasicSource(w), (_bc.last_crit ? COMBAT_CRIT_MULT : 1), 1, { is_skill: false, grade_mult: timing.mult });
    e = dmg_pack.defender;
    var dealt = max(0, dmg_pack.dmg);

    // FUN-FIRST gear passives add bonus pressure after the grade.
    var bonus_dmg = Equip_PlayerBonusDamage(p, e, dealt, false, timing_key);
    if (bonus_dmg > 0) {
        var spend = min(bonus_dmg, e.hp);
        e.hp = max(0, e.hp - spend);
        dealt += spend;
    }

    _bc.last_dmg = dealt;
    Battle_HitPop(_bc, dealt, timing_key, _bc.last_crit);
    p = Equip_PlayerPerfectHitApply(p, timing_key);

    var side_fx = Equip_PassiveOnAttackResolved(p, e, timing_key, true, _bc.last_dmg);
    p = side_fx.attacker;
    e = side_fx.defender;
    var passive_msg = side_fx.msg;

    p = Status_ConsumeByField(p, "consume_on_attack");

    // D61 feedback: a Perfect freezes the picture for QTE_HITSTOP_PERFECT_MS first (also on a killing blow); the shakes follow it.
    if (timing_key == QTE_PERFECT) {
        _bc.hitstop_ms = QTE_HITSTOP_PERFECT_MS;
    } else {
        Battle_QteImpactFeedback(_bc);
    }

    if (Battle_CheckEnd(_bc, p, e)) return;

    // D75: every hit fills the stagger meter (a Perfect +50%); a full meter is a BREAK. A passive's stun (Pinning Shot) pushes the enemy back.
    var break_note = Battle_StaggerHit(_bc, Combat_BasicSource(w).power, false, timing_key == QTE_PERFECT);
    var stun_note = Battle_StunResolve(_bc);

    var msg;
    if (_bc.last_crit) {
        msg = Loc_T("combat.msg.player_crit", "Critical hit! {dmg} damage!", { dmg: _bc.last_dmg });
    } else {
        msg = Loc_T("combat.msg.player_hit", "You hit for {dmg} damage!", { dmg: _bc.last_dmg });
    }
    if (passive_msg != "") msg += " " + passive_msg;
    msg += stun_note + break_note;
    Battle_Message(_bc, msg, BSTATE_ENEMY_ACT);

    if (Battle_PlayerFinalizeTurn(_bc, p, e)) return;
}

// One Step of the bar. The clock is ms from delta_time; a press is stamped at the top of the Step that sees it (QTE-01).
function Battle_PlayerAttackTimingStep(_bc, _confirm_pressed) {
    if (!_bc.qte_active) {
        Battle_AttackTimingBegin(_bc);
        return;
    }

    _bc.qte_ms += Qte_StepMs(delta_time);

    if (_confirm_pressed) {
        var press_ms = Qte_BufferPress(_bc.qte_ms);
        if (press_ms != QTE_NO_PRESS) {   // one press per attack: the first kept press ends the bar
            _bc.qte_press_ms = press_ms;
            Battle_PlayerAttackResolveTimed(_bc, Qte_Result(Qte_Grade(press_ms, _bc.qte_params, _bc.qte_assist)));
            return;
        }
    }

    if (_bc.qte_ms >= _bc.qte_params.sweep_ms) {   // the cursor reached the end with no press
        Battle_PlayerAttackResolveTimed(_bc, Qte_Result(Qte_Grade(QTE_NO_PRESS, _bc.qte_params, _bc.qte_assist)));
    }
}

// Where a player skill's animation plays (BUG-21): self-targeted skills (the buffs) on the player, the rest on the enemy.
function Battle_SkillFxOnPlayer(_skill_id) {
    var sk = SkillDB_Get(_skill_id);
    return (is_struct(sk) && variable_struct_exists(sk, "target") && sk.target == TGT_SELF);
}

// Top-left spawn position that puts the middle of an fx sprite on the point (_px, _py).
function FX_CenterAtPoint(_sprite, _px, _py, _scale = SKILL_FX_SCALE) {
    if (_sprite == noone) return { x: _px, y: _py };
    var fx_scale = max(0.01, abs(_scale));
    return {
        x: _px - ((sprite_get_width(_sprite) * 0.5 - sprite_get_xoffset(_sprite)) * fx_scale),
        y: _py - ((sprite_get_height(_sprite) * 0.5 - sprite_get_yoffset(_sprite)) * fx_scale)
    };
}

// Spawns a player skill's animation on its target (BUG-21 anchor, I-052 size) and returns the fx instance.
function Battle_SkillFxSpawn(_bc, _skill_id, _sprite, _frames, _speed) {
    var tx = _bc.enemy_fx_x;
    var ty = _bc.enemy_fx_y;
    var target_px = FX_PLAYER_TARGET_PX;
    if (!Battle_SkillFxOnPlayer(_skill_id) && instance_exists(_bc.enemy_inst)) target_px = FX_TargetSize(_bc.enemy_inst);
    var scale = FX_ScaleFor(_sprite, target_px);
    if (Battle_SkillFxOnPlayer(_skill_id)) {
        var ppos = FX_CenterAtPoint(_sprite, _bc.player_fx_x, _bc.player_fx_y, scale);
        tx = ppos.x;
        ty = ppos.y;
    } else if (instance_exists(_bc.enemy_inst)) {
        var pos = FX_CenterOn(_sprite, _bc.enemy_inst, scale);
        tx = pos.x;
        ty = pos.y;
    }
    return FX_Spawn(_sprite, tx, ty, _frames, _speed, scale);
}

// A player skill is cast in two steps (D57, D58, D61): the arrow sequence, then the skill with the grade's multiplier.
// The MP is checked first, so a skill you cannot pay for never asks for arrows. Nothing is spent until the sequence ends.
function Battle_SkillQteBegin(_bc, _skill_id) {
    var p = _bc.p;

    var skill = SkillDB_Get(_skill_id);
    var cost = Equip_PlayerSkillMPCost(p, skill, skill.mp_cost);
    if (p.mp < cost) {
        Battle_Message(_bc, Loc_T("combat.msg.not_enough_mp", "Not enough MP."), BSTATE_SKILL_MENU);
        return;
    }

    _bc.sq_skill = _skill_id;
    _bc.sq_st = Qte_SeqNew(Qte_SkillSequence(_skill_id), Qte_AssistMult(), Qte_PerfectWiden(p));
    _bc.sq_ms = -QTE_SEQ_LEAD_IN_MS;   // the arrows are up and the clock waits; the press that chose the skill cannot count
    _bc.sq_wrong_ms = 0;
    _bc.sq_pop_ms = 0;
    _bc.sq_pop_idx = -1;
    _bc.sq_active = true;
    _bc.skill_banner_active = true;
    _bc.skill_banner_name = skill.name;
    _bc.battle_state = BSTATE_SKILL_QTE;
}

// One Step of the sequence. Presses are read like the attack bar's: stamped with the clock at the top of the Step that sees them.
// Two arrows in the same frame (a diagonal on the stick) count as the right one if it is among them, else as one mistake.
function Battle_SkillQteStep(_bc) {
    if (!_bc.sq_active) {
        _bc.battle_state = BSTATE_SKILL_MENU;
        return;
    }

    var dt = Qte_StepMs(delta_time);
    _bc.sq_ms += dt;
    _bc.sq_wrong_ms = max(0, _bc.sq_wrong_ms - dt);
    _bc.sq_pop_ms = max(0, _bc.sq_pop_ms - dt);
    if (_bc.sq_ms < 0) return;

    var st = _bc.sq_st;
    var presses = Battle_ArrowPresses();
    if (array_length(presses) > 0) {
        var want = st.seq[st.idx];
        Qte_SeqPress(st, array_contains(presses, want) ? want : presses[0], _bc.sq_ms);
        if (st.last == "ok") {
            SFX_PlayUI("ui_move");
            _bc.sq_pop_ms = QTE_SEQ_POP_MS;
            _bc.sq_pop_idx = st.idx - 1;
        } else if (st.last == "wrong") {
            SFX_PlayUI("ui_back");
            _bc.sq_wrong_ms = QTE_SEQ_SHAKE_MS;
        }
    } else {
        Qte_SeqTick(st, _bc.sq_ms);
    }

    if (st.done) {
        _bc.sq_active = false;
        Battle_PlayerSkill(_bc, _bc.sq_skill, Qte_Result(st.key));
    }
}

// The grade word's position: over the enemy, or over the player for a skill cast on yourself.
function Battle_QteWordPos(_bc, _on_player) {
    if (!_on_player) return Battle_AttackTimingTarget(_bc);
    var sx = Display_WorldScale();
    return { x: round((_bc.player_fx_x - _bc.cam_base_x) * sx), y: round((_bc.player_fx_y - _bc.cam_base_y) * sx) };
}

// D61 feedback for a cast skill: the grade word and sound, then (damaging skills only) the same freeze-on-Perfect and shakes as the basic attack.
function Battle_SkillGradeFeedback(_bc, _skill, _grade, _res) {
    var word_pos = Battle_QteWordPos(_bc, _skill.target == TGT_SELF);
    _bc.qte_result_text = _grade.label;
    _bc.qte_result_key = _grade.key;
    _bc.qte_result_mult = _grade.mult;
    _bc.qte_result_ms = QTE_RESULT_MS;
    _bc.qte_word_x = word_pos.x;
    _bc.qte_word_y = word_pos.y;
    SFX_Play(Qte_GradeSfxKey(_grade.key));

    _bc.last_dmg = max(0, _res.dmg);
    if (_res.dmg > 0) Battle_HitPop(_bc, _res.dmg, _grade.key, _res.crit);
    if (_res.dmg < 0) Battle_HealPop(_bc, -_res.dmg);
    if (_res.dmg > 0) {
        if (_grade.key == QTE_PERFECT) _bc.hitstop_ms = QTE_HITSTOP_PERFECT_MS;
        else Battle_QteImpactFeedback(_bc);
    }
}

// Casts the skill. _grade is the arrow sequence's result (Qte_Result); a damaging skill's hit is scaled by its multiplier and never misses (D6).
function Battle_PlayerSkill(_bc, _skill_id, _grade = undefined) {
    var p = _bc.p;
    var e = _bc.e;
    var grade = is_struct(_grade) ? _grade : Qte_Result(QTE_OK);

    var skill = SkillDB_Get(_skill_id);
    var target = (skill.target == TGT_SELF) ? p : e;
    var res = Skill_Use(p, target, _skill_id, grade.mult);
    if (res.ok) {
        _bc.skill_banner_active = true;
        _bc.skill_banner_name = skill.name;
        SFX_PlaySkill(_skill_id);
        Battle_SkillGradeFeedback(_bc, skill, grade, res);
    }

    var fx = noone;
    if (res.ok && res.fx_sprite != noone) {   // D6: a player skill always lands, so its animation always plays
        fx = Battle_SkillFxSpawn(_bc, _skill_id, res.fx_sprite, res.fx_frames, res.fx_speed);
    }

    if (!res.ok) {
        Battle_Message(_bc, res.msg, BSTATE_SKILL_MENU);
        _bc.p = p;
        _bc.e = e;
        return;
    }

    if (skill.target == TGT_SELF) p = target; else e = target;

    if (Battle_CheckEnd(_bc, p, e)) return;

    // D75: a damaging skill fills the stagger meter once per hit (stun skills x2, a Perfect +50%); a stun it lands is a push-back, never extra actions.
    var skill_note = "";
    if (skill.target != TGT_SELF && res.hit) {
        if (res.dmg > 0) {
            var hits_n = variable_struct_exists(skill, "hits") ? max(1, round(real(skill.hits))) : 1;
            var skill_power = Combat_PowerSkill(skill.power, skill.power_mult, Combat_WeaponPower(p));
            skill_note += Battle_StaggerHit(_bc, skill_power, Status_SkillAppliesStatus(skill, STATUS_STUN), grade.key == QTE_PERFECT, hits_n);
        }
        skill_note = Battle_StunResolve(_bc) + skill_note;
    }

    if (res.msg != "") {
        Battle_Message(_bc, res.msg + skill_note, BSTATE_ENEMY_ACT, fx);
    } else if (res.crit) {
        Battle_Message(_bc, Loc_T("combat.msg.skill_crit", "Critical skill! {dmg} damage!", { dmg: res.dmg }) + skill_note, BSTATE_ENEMY_ACT, fx);
    } else if (res.dmg > 0) {
        Battle_Message(_bc, Loc_T("combat.msg.skill_hit", "Skill hit for {dmg} damage!", { dmg: res.dmg }) + skill_note, BSTATE_ENEMY_ACT, fx);
    } else {
        Battle_Message(_bc, Loc_T("combat.msg.skill_used", "Skill used.") + skill_note, BSTATE_ENEMY_ACT, fx);
    }

    if (Battle_PlayerFinalizeTurn(_bc, p, e)) return;
}

function Battle_PlayerItem(_bc, _item_id) {
    var p = _bc.p;
    var e = _bc.e;

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
    if (Battle_PlayerFinalizeTurn(_bc, p, e)) return;
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

// Spec section 8: the one random roll left in a flee. Bosses are checked before this.
function Battle_RunChance(_spd_player, _spd_enemy) {
    return clamp(0.5 + 0.05 * (_spd_player - _spd_enemy), 0.10, 0.95);
}

function Battle_RunAttempt(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    var enemy_id = -1;
    if (is_struct(e) && variable_struct_exists(e, "id")) enemy_id = e.id;
    if (enemy_id == ENEMY_MINI_BOSS || enemy_id == ENEMY_FINAL_BOSS) {
        Battle_TurnAdvance(_bc);
        Battle_Message(_bc, Loc_T("combat.msg.player_cant_escape_this", "You can't run away from this."), BSTATE_ENEMY_ACT);
        return;
    }

    if (RunRng_Float("combat") < Battle_RunChance(Combat_EffectiveStat(p, STAT_SPD), Combat_EffectiveStat(e, STAT_SPD))) {
        EnemyPersist_ResolveBattle(false);
        if (enemy_id == ENEMY_STRANGER) {
            Dialogue_NarrativeOnStrangerEncounterResolved();
        }
        Battle_Message(_bc, Loc_T("combat.msg.player_ran", "You ran away!"), BSTATE_END_RUN, noone, COMBAT_ACTION_DELAY);
    } else {
        Battle_TurnAdvance(_bc);
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

// Actions the enemy takes in its next turn (1, or more with a passive-budget skill such as Rampage).
function Battle_EnemyActionBudget(_e) {
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
    return clamp(actions, 1, ENEMY_ACTION_CHAIN_MAX);
}

function Battle_EnemyInitActionBudget(_bc, _e) {
    if (!variable_instance_exists(_bc, "enemy_actions_remaining")) _bc.enemy_actions_remaining = 0;
    if (!variable_instance_exists(_bc, "enemy_turn_used_skills") || !is_array(_bc.enemy_turn_used_skills)) _bc.enemy_turn_used_skills = [];
    if (_bc.enemy_actions_remaining > 0) return;

    _bc.enemy_turn_used_skills = [];
    _bc.enemy_actions_remaining = Battle_EnemyActionBudget(_e);
}

// ---- Foresight (D79): the enemy's next action is decided ahead of time and kept in the battle (enemy_plan), so what it shows is what happens ----
// plan = { skill_id (-1 = the basic attack), kind ("attack" | "skill" | "windup"), rule (the label that chose it), announced }.
// The choice itself is EnemyAI_Choose (scr_db_enemy, combat-spec.md section 12): the enemy's rule list, then a weighted draw from the "combat" stream.
function Battle_EnemyPlanLeft(_bc) {
    return (_bc.enemy_actions_remaining > 0) ? _bc.enemy_actions_remaining : Battle_EnemyActionBudget(_bc.e);
}

function Battle_EnemyPlanChoose(_bc) {
    var used = (_bc.enemy_actions_remaining > 0) ? _bc.enemy_turn_used_skills : [];
    var ctx = EnemyAI_Ctx(_bc.ai, Battle_EnemyPlanLeft(_bc), used, Debug_EnemyForceDamageSkillOnly());
    var ch = EnemyAI_Choose(_bc.e, _bc.p, ctx, Run_Stream("combat"));
    return { skill_id: ch.skill_id, kind: ch.kind, rule: ch.rule, announced: false };
}

// A plan made a turn ago may no longer be allowed (an HP-gated skill, a wind-up that a BREAK cancelled): then the enemy chooses again.
function Battle_EnemyPlanValid(_bc, _plan) {
    if (!is_struct(_plan) || !variable_struct_exists(_plan, "skill_id")) return false;
    var pending = _bc.ai.windup;
    if (variable_struct_exists(_plan, "rule") && _plan.rule == "windup_attack" && pending != _plan.skill_id) return false;
    if (pending >= 0 && !(variable_struct_exists(_plan, "rule") && _plan.rule == "windup_attack")) return false;   // the big attack is due, whatever was planned before
    if (_plan.skill_id == -1) return true;
    var sk = SkillDB_Get(_plan.skill_id);
    if (!is_struct(sk) || sk.id == -1) return false;
    return Skill_CanUse(_bc.e, sk) && Skill_EnemyCanTrigger(sk, _bc.e, _bc.p, Battle_EnemyPlanLeft(_bc));
}

// A boss that crossed an HP threshold: new SPD / ATK at once (the strip shows it), the old plan is dropped, the banner waits for the enemy's next action.
function Battle_PhaseSync(_bc) {
    var r = EnemyAI_PhaseSync(_bc.ai, _bc.e);
    if (!r.changed) return false;
    _bc.enemy_plan = undefined;
    _bc.phase_banner = r.banner;
    Turn_SetSpd(_bc.tl, TL_ENEMY, Combat_EffectiveStat(_bc.e, STAT_SPD));
    return true;
}

function Battle_EnemyPlanGet(_bc) {
    Battle_PhaseSync(_bc);
    if (!variable_instance_exists(_bc, "enemy_plan") || !Battle_EnemyPlanValid(_bc, _bc.enemy_plan)) _bc.enemy_plan = Battle_EnemyPlanChoose(_bc);
    return _bc.enemy_plan;
}

// The enemy acts on its plan: returns the plan (skill_id, kind, rule) and clears it. The AI state learns what was done (rule uses, the wind-up).
function Battle_EnemyPlanTake(_bc) {
    var plan = Battle_EnemyPlanGet(_bc);
    _bc.enemy_plan = undefined;
    EnemyAI_Take(_bc.ai, plan);
    return plan;
}

// Pure: what Foresight shows for a plan. Nothing is given away while _visible is false.
function Battle_ActionPreviewOf(_plan, _visible, _stunned = false) {
    var out = { visible: false, kind: "none", skill_id: -1, name: "", big: false, text: "" };
    if (!_visible || !is_struct(_plan)) return out;
    out.visible = true;
    if (_stunned) {
        out.kind = "stunned";
        out.name = Loc_T("combat.foresee.stunned", "nothing, it is stunned");
    } else if (_plan.skill_id == -1) {
        out.kind = "attack";
        out.name = Loc_T("combat.foresee.attack", "a plain attack");
    } else {
        var sk = SkillDB_Get(_plan.skill_id);
        var winding = (variable_struct_exists(_plan, "kind") && _plan.kind == "windup");
        out.kind = winding ? "windup" : "skill";
        out.skill_id = _plan.skill_id;
        out.name = winding ? Loc_T("combat.foresee.windup", "winding up {skill}", { skill: string(sk.name) }) : string(sk.name);
        out.big = winding || (variable_struct_exists(sk, "uses_defensive_qte") && sk.uses_defensive_qte) || (variable_struct_exists(sk, "telegraphed") && sk.telegraphed);   // a big, telegraphed attack (D7)
    }
    out.text = Loc_T("combat.msg.foresee", "You foresee: {action}", { action: out.name });
    return out;
}

// For the turn bar / HUD (D79, D99): the enemy's next action while the player has Foresight; { visible: false } otherwise.
function Battle_EnemyNextActionPreview(_bc = noone) {
    var bc = _bc;
    if (bc == noone) bc = instance_find(obj_battle_controller, 0);
    if (!instance_exists(bc)) return Battle_ActionPreviewOf(undefined, false);
    if (!Status_HasFlag(bc.p, "reveals_action")) return Battle_ActionPreviewOf(undefined, false);
    return Battle_ActionPreviewOf(Battle_EnemyPlanGet(bc), true);
}

function Battle_StatusSnapshot(_ch) {
    var out = [];
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "status") || !is_array(_ch.status)) return out;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var st = _ch.status[i];
        if (!is_struct(st) || !variable_struct_exists(st, "id")) continue;
        var sid = round(real(st.id));
        var turns = variable_struct_exists(st, "turns") ? max(0, round(real(st.turns))) : 0;
        var stacks = variable_struct_exists(st, "stacks") ? max(1, round(real(st.stacks))) : 1;
        var st_power = variable_struct_exists(st, "power") ? st.power : 0;
        array_push(out, { id: sid, turns: turns, stacks: stacks, power: st_power });
    }
    return out;
}

// The snapshot entry of a status, or undefined.
function Battle_StatusSnapshotEntry(_snapshot, _status_id) {
    if (!is_array(_snapshot)) return undefined;
    var sid = round(real(_status_id));
    for (var i = 0; i < array_length(_snapshot); i++) {
        var st = _snapshot[i];
        if (is_struct(st) && variable_struct_exists(st, "id") && round(real(st.id)) == sid) return st;
    }
    return undefined;
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
    if (enemy_turn_finished) EnemyAI_EndTurn(_bc.ai);   // B4: the enemy's own turn number (every_nth rules)
    if (enemy_turn_finished) e = Status_Tick(e);        // the turn's tick, which includes this last action's bleeding
    else e = Status_ActionTick(e);                       // D78: Bleeding hurts after every action of a chain
    if (Battle_CheckEnd(_bc, p, e)) {
        _bc.p = p;
        _bc.e = e;
        out.ended = true;
        out.player = p;
        out.enemy = e;
        return out;
    }
    _bc.p = p;
    _bc.e = e;
    out.player = p;
    out.enemy = e;
    if (enemy_turn_finished) Battle_TurnAdvance(_bc);   // the timeline decides: the player, or the enemy again if it is much faster
    else {
        _bc.turn = TURN_ENEMY;
        _bc.enemy_action_pending = true;   // the next action of the same turn
    }
    return out;
}

// ---- The defence bar (D7, D59, D60, D21) ----
// A big enemy attack has already been rolled and applied by Skill_Use when this starts. The bar then decides how much of it stays: the player's HP
// is put back to what it was before the hit while the bar is up (the HUD must not show the damage you are trying to stop), and
// Battle_DefenceResolve takes the damage and the status turns that get through.

function Battle_DefenceClear(_bc) {
    _bc.def_active = false;
    _bc.def_skill_id = -1;
    _bc.def_ms = 0;
    _bc.def_press_ms = QTE_NO_PRESS;
    _bc.def_ctx = {};
}

// Telegraph ("!" and the attack's name, QTE_TELEGRAPH_MS), then the lead-in, then the bar sweeps. All on one clock that starts negative.
function Battle_DefenceStart(_bc, _skill, _res, _follow_state, _player_hp_before, _status_before_snapshot) {
    _bc.def_active = true;
    _bc.def_skill_id = _skill.id;
    _bc.def_perfect_widen = Qte_PerfectWiden(_bc.p);   // Foresight (D79)
    _bc.def_params = Qte_WidenPerfect(Qte_DefenceParams(_skill.id), _bc.def_perfect_widen);   // fixed per attack, so it can be learned (D60)
    _bc.def_assist = Qte_AssistMult();
    _bc.def_ms = -(QTE_TELEGRAPH_MS + QTE_LEAD_IN_MS);
    _bc.def_press_ms = QTE_NO_PRESS;
    _bc.def_ctx = {
        res: _res,
        follow_state: _follow_state,
        hp_before: max(0, round(real(_player_hp_before))),
        status_before: _status_before_snapshot,
        status_ids: Battle_SkillStatusIds(_skill)
    };
    if (instance_exists(_bc.enemy_inst)) {   // the enemy flashes as it winds up
        SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, QTE_TELEGRAPH_MS * 60 div 1000, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
    }
    _bc.battle_state = BSTATE_ENEMY_DEFENCE;
}

// One Step: the same bar rules as the basic attack. A press before the sweep (the telegraph, mashing) is dropped; no press at all is Weak.
function Battle_DefenceStep(_bc, _confirm_pressed) {
    if (!_bc.def_active) {
        _bc.battle_state = BSTATE_ENEMY_ACT;
        return;
    }

    _bc.def_ms += Qte_StepMs(delta_time);

    if (_confirm_pressed) {
        var press_ms = Qte_BufferPress(_bc.def_ms);
        if (press_ms != QTE_NO_PRESS) {
            _bc.def_press_ms = press_ms;
            Battle_DefenceResolve(_bc, Qte_Grade(press_ms, _bc.def_params, _bc.def_assist));
            return;
        }
    }

    if (_bc.def_ms >= _bc.def_params.sweep_ms) {
        Battle_DefenceResolve(_bc, Qte_Grade(QTE_NO_PRESS, _bc.def_params, _bc.def_assist));
    }
}

function Battle_DefenceResolve(_bc, _key) {
    if (!_bc.def_active) return;

    var p = _bc.p;
    var e = _bc.e;
    var ctx = _bc.def_ctx;
    _bc.def_active = false;

    var base_res = ctx.res;
    var base_dmg = max(0, round(real(base_res.dmg)));
    var final_dmg = Qte_DefenceDamage(base_dmg, _key);
    p.hp = clamp(ctx.hp_before - final_dmg, 0, p.max_hp);

    var status_pack = Battle_DefenceAdjustStatuses(p, ctx.status_ids, ctx.status_before, _key);
    p = status_pack.player;

    var summary;
    if (_key == QTE_WEAK) {
        summary = Loc_T("combat.msg.defence.weak", "Not blocked.");
    } else {
        summary = Loc_T("combat.msg.defence.summary", "{grade} block! Damage -{reduce}%.", { grade: Qte_GradeLabel(_key), reduce: round((1 - Qte_DefenceMult(_key)) * 100) });
    }
    if (status_pack.resist_msg != "") summary += " " + status_pack.resist_msg;

    var enemy_name = is_struct(e) && variable_struct_exists(e, "name") ? string(e.name) : Loc_T("enemy.name.unknown", "Enemy");
    var crit = variable_struct_exists(base_res, "crit") && base_res.crit;
    var final_msg = Battle_EnemySkillComposeMessage(enemy_name, { hit: true, crit: crit, dmg: base_dmg, msg: "" }, final_dmg, status_pack.status_msg, summary);

    // Grade word over the bar and its sound. A Perfect is a clean block: no shake. Anything that gets through shakes the picture as a hit does.
    var sx = Display_WorldScale();
    _bc.qte_result_text = Qte_GradeLabel(_key);
    _bc.qte_result_key = _key;
    _bc.qte_result_mult = Qte_DefenceMult(_key);
    _bc.qte_result_ms = QTE_RESULT_MS;
    _bc.qte_word_x = round(Display_GuiW() * 0.5);
    _bc.qte_word_y = Battle_QteAnchorY(_bc, round(QTE_BAR_H * sx));
    SFX_Play(Qte_GradeSfxKey(_key));

    _bc.last_hit = true;
    _bc.last_crit = crit;
    _bc.last_dmg = final_dmg;
    if (final_dmg > 0 && _key != QTE_PERFECT) {
        CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
    }
    if (final_dmg > 0) Battle_PlayerHitPop(_bc, final_dmg, crit);

    if (Battle_CheckEnd(_bc, p, e)) {
        _bc.p = p;
        _bc.e = e;
        Battle_DefenceClear(_bc);
        return;
    }
    _bc.p = p;
    final_msg += Battle_StunResolve(_bc);   // a defended Vine Trap that still stunned (Perfect resists it above)

    var turn_pack = Battle_EnemyFinalizeTurnState(_bc, p, e);
    if (turn_pack.ended) {
        Battle_DefenceClear(_bc);
        return;
    }

    var follow_state = variable_struct_exists(ctx, "follow_state") ? ctx.follow_state : BSTATE_MENU;
    Battle_Message(_bc, final_msg, follow_state);
    Battle_DefenceClear(_bc);
}

// ---- QTE drawing (GUI layer, GUI units from Display_GuiW/H through the caller's ui_visual) ----
// Only the four palette colours (QTE_COL_*): zones differ by brightness, the Perfect zone also by a pointer above the bar.
function Qte_FillRect(_x, _y, _w, _h, _col) {
    draw_set_color(_col);
    draw_rectangle(_x, _y, _x + _w - 1, _y + _h - 1, false);
}

// The sliding bar at (_x, _y), size _w x _h, with the cursor at _ms. _unit = one design pixel in GUI units (the outline thickness).
function Qte_DrawBar(_x, _y, _w, _h, _params, _assist, _ms, _unit, _alpha = 1) {
    var o = max(1, round(_unit));
    var a = clamp(_alpha, 0, 1);
    var sweep = max(1, _params.sweep_ms);
    var centre_x = _x + (_w * Qte_ZoneCentreMs(_params) / sweep);
    var widen = max(1, _assist);
    draw_set_alpha(a);

    Qte_FillRect(_x - o, _y - o, _w + 2 * o, _h + 2 * o, QTE_COL_LIGHTEST);   // frame
    Qte_FillRect(_x, _y, _w, _h, QTE_COL_DARK);                                 // track

    // zones, widest first; each is clipped to the track
    var halves = [_params.ok_half_width, _params.good_half_width, _params.perfect_half_width];
    var cols = [QTE_COL_LIGHT, QTE_COL_LIGHTEST, QTE_COL_LIGHTEST];
    for (var i = 0; i < 3; i++) {
        var hw = _w * halves[i] * widen / sweep;
        var zx0 = max(_x, round(centre_x - hw));
        var zx1 = min(_x + _w, round(centre_x + hw));
        if (zx1 > zx0) Qte_FillRect(zx0, _y, zx1 - zx0, _h, cols[i]);
    }
    // the Perfect zone: dark edges and a pointer above the bar
    var phw = _w * _params.perfect_half_width * widen / sweep;
    var px0 = round(centre_x - phw);
    var px1 = round(centre_x + phw);
    Qte_FillRect(px0, _y, o, _h, QTE_COL_DARKEST);
    Qte_FillRect(px1 - o, _y, o, _h, QTE_COL_DARKEST);
    var cx = round(centre_x);
    for (var t = 0; t < 3; t++) {   // a small downward triangle over the zone's centre
        Qte_FillRect(cx - (2 - t) * o, _y - o - (3 - t) * o, (2 - t) * 2 * o + o, o, QTE_COL_LIGHTEST);
    }

    // cursor: a light line with a dark outline, taller than the bar
    var cur_x = round(_x + Qte_CursorPos(_ms, _params) * _w);
    var ext = 2 * o;
    Qte_FillRect(cur_x - o - o, _y - ext - o, 3 * o + o, _h + 2 * ext + 2 * o, QTE_COL_DARKEST);
    Qte_FillRect(cur_x - o, _y - ext, 2 * o, _h + 2 * ext, QTE_COL_LIGHTEST);

    draw_set_alpha(1);
    draw_set_color(c_white);
}

// The grade word, centred on (_x, _y). Four colours only, so grades differ by size and motion too:
// PERFECT biggest and pops, GOOD big, OK plain, WEAK small, hollow (dark with a light outline) and sinks. _left_ms counts down from QTE_RESULT_MS.
function Qte_DrawGradeWord(_key, _text, _x, _y, _left_ms, _unit) {
    var elapsed = QTE_RESULT_MS - _left_ms;
    var scale = 1;
    var rise = 1;
    var fill = QTE_COL_LIGHTEST;
    var edge = QTE_COL_DARKEST;
    switch (_key) {
        case QTE_PERFECT: scale = 2.0; break;
        case QTE_GOOD:    scale = 1.5; fill = QTE_COL_LIGHT; break;
        case QTE_OK:      scale = 1.0; break;
        default:        scale = 0.75; rise = -1; fill = QTE_COL_DARK; edge = QTE_COL_LIGHT; break;
    }
    if (_key == QTE_PERFECT && elapsed < 120) scale *= 1 + 0.35 * (1 - elapsed / 120);   // pop, then settle
    var ease = 1 - sqr(1 - clamp(elapsed / 250, 0, 1));
    var yy = _y - rise * ease * 6 * _unit;
    var a = clamp(_left_ms / 150, 0, 1);

    var tw = UI_TextWidth(_text) * scale;
    var th = UI_TextHeight(_text) * scale;
    var tx = _x - tw * 0.5;
    var ty = yy - th * 0.5;
    var o = max(1, round(_unit));
    draw_set_alpha(a);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(edge);
    for (var ox = -1; ox <= 1; ox++) {
        for (var oy = -1; oy <= 1; oy++) {
            if (ox != 0 || oy != 0) UI_DrawTextTransformed(tx + ox * o, ty + oy * o, _text, scale, scale, 0);
        }
    }
    draw_set_color(fill);
    UI_DrawTextTransformed(tx, ty, _text, scale, scale, 0);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// Where the QTE widgets (the bar, the arrows) sit: centred, under the enemy and its status icons, kept on screen. Returns the top y in GUI units.
function Battle_QteAnchorY(_bc, _widget_h) {
    var sx = Display_WorldScale();
    var ay = round(Display_GuiH() * 0.72);
    if (instance_exists(_bc.enemy_inst) && _bc.enemy_inst.sprite_index != noone) {
        var spr = _bc.enemy_inst.sprite_index;
        var enemy_bottom = ((_bc.enemy_inst.y - sprite_get_yoffset(spr) - _bc.cam_base_y) * sx) + (sprite_get_height(spr) * abs(_bc.enemy_inst.image_yscale) * sx);
        ay = round(enemy_bottom + (22 * sx));
    }
    return min(ay, Display_GuiH() - _widget_h - round(16 * sx));
}

// One arrow, 9 x 9 design pixels (_unit GUI units each), top-left at (_x, _y), pointing _dir (RIGHT, UP, LEFT, DOWN macros): _fill inside, a 1-pixel _edge.
function Qte_DrawArrowGlyph(_x, _y, _dir, _unit, _fill, _edge) {
    var u = max(1, round(_unit));
    var up = [[4, 0, 1, 1], [3, 1, 3, 1], [2, 2, 5, 1], [1, 3, 7, 1], [0, 4, 9, 1], [3, 5, 3, 4]];   // the up arrow as [x, y, w, h]
    var n = array_length(up);
    var rects = array_create(n);
    for (var i = 0; i < n; i++) {
        var r = up[i];
        var rx = r[0], ry = r[1], rw = r[2], rh = r[3];
        switch (_dir) {
            case DOWN:  ry = 9 - ry - rh; break;
            case LEFT:  { var tx = rx; rx = ry; ry = tx; var tw = rw; rw = rh; rh = tw; } break;
            case RIGHT: { var tx2 = rx; rx = ry; ry = tx2; var tw2 = rw; rw = rh; rh = tw2; rx = 9 - rx - rw; } break;
        }
        rects[i] = [rx, ry, rw, rh];
    }
    for (var e = 0; e < n; e++) Qte_FillRect(_x + (rects[e][0] - 1) * u, _y + (rects[e][1] - 1) * u, (rects[e][2] + 2) * u, (rects[e][3] + 2) * u, _edge);
    for (var f = 0; f < n; f++) Qte_FillRect(_x + rects[f][0] * u, _y + rects[f][1] * u, rects[f][2] * u, rects[f][3] * u, _fill);
}

// Height of the arrow row and its time bar, in GUI units (for placing it).
function Qte_SequenceHeight(_unit) {
    return 21 * max(1, round(_unit));
}

// The arrow sequence of a skill and its time bar, centred on _cx, top at _top. Done arrows sink dark, the wanted one is lit in a bright box, the
// next ones wait. A wrong press shakes the row (_wrong_ms left) and a right one hops its arrow (_pop_ms left, _pop_idx). The time bar drains
// to the left; its brightest part is the Perfect window (finish with some of it left, no mistakes) and the tick marks where it ends. _unit = GUI units per design pixel.
function Qte_DrawSequence(_cx, _top, _st, _wrong_ms, _pop_ms, _pop_idx, _unit, _alpha = 1) {
    var u = max(1, round(_unit));
    var cell = 13 * u;
    var gap = 3 * u;
    var n = _st.len;
    var row_w = n * cell + (n - 1) * gap;
    var x0 = round(_cx - row_w * 0.5);
    var shake = 0;
    if (_wrong_ms > 0) shake = round(sin(_wrong_ms * 0.09) * 2 * (_wrong_ms / QTE_SEQ_SHAKE_MS)) * u;
    draw_set_alpha(clamp(_alpha, 0, 1));

    for (var i = 0; i < n; i++) {
        var bx = x0 + i * (cell + gap) + shake;
        var by = _top;
        var done = (i < _st.idx);
        var current = (i == _st.idx && !_st.done);
        var box_fill = QTE_COL_DARK;
        var arrow_fill = QTE_COL_LIGHT;
        var arrow_edge = QTE_COL_DARKEST;
        if (done) {
            arrow_fill = QTE_COL_DARKEST;
            arrow_edge = QTE_COL_DARK;
        } else if (current) {
            box_fill = QTE_COL_LIGHTEST;
            arrow_fill = QTE_COL_DARKEST;
            arrow_edge = QTE_COL_LIGHTEST;
        }
        if (i == _pop_idx && _pop_ms > 0) {   // the arrow just done hops, bright
            by -= round(3 * _pop_ms / QTE_SEQ_POP_MS) * u;
            box_fill = QTE_COL_LIGHT;
            arrow_fill = QTE_COL_DARKEST;
            arrow_edge = QTE_COL_LIGHT;
        }
        Qte_FillRect(bx - u, by - u, cell + 2 * u, cell + 2 * u, QTE_COL_DARKEST);   // frame
        Qte_FillRect(bx, by, cell, cell, box_fill);
        Qte_DrawArrowGlyph(bx + 2 * u, by + 2 * u, _st.seq[i], u, arrow_fill, arrow_edge);
    }

    // time bar
    var bar_y = _top + cell + 4 * u;
    var bar_h = 4 * u;
    var perfect_x = x0 + round(row_w * (1 - _st.fast_ms / _st.limit_ms));
    var fill_w = round(row_w * Qte_SeqLeft(_st));
    Qte_FillRect(x0 - u, bar_y - u, row_w + 2 * u, bar_h + 2 * u, QTE_COL_LIGHTEST);
    Qte_FillRect(x0, bar_y, row_w, bar_h, QTE_COL_DARK);
    Qte_FillRect(x0, bar_y, min(fill_w, perfect_x - x0), bar_h, QTE_COL_LIGHT);   // the slower part: finishing here is Good at best
    if (fill_w > perfect_x - x0) Qte_FillRect(perfect_x, bar_y, fill_w - (perfect_x - x0), bar_h, QTE_COL_LIGHTEST);   // the fast part: finish while any of it is left for Perfect
    Qte_FillRect(perfect_x - u, bar_y - 2 * u, u, bar_h + 4 * u, QTE_COL_DARKEST);   // where the Perfect window ends
    Qte_FillRect(perfect_x, bar_y - 2 * u, u, bar_h + 4 * u, QTE_COL_LIGHTEST);

    draw_set_alpha(1);
    draw_set_color(c_white);
}

// The "!" over a big enemy attack, centred on (_x, _y): pops in big and settles, then holds until the bar comes up. _elapsed_ms since the telegraph began.
function Qte_DrawTelegraph(_x, _y, _elapsed_ms, _unit) {
    var scale = 3;
    if (_elapsed_ms < 120) scale *= 1 + 0.5 * (1 - _elapsed_ms / 120);
    var o = max(1, round(_unit));
    var text = "!";
    var tw = UI_TextWidth(text) * scale;
    var th = UI_TextHeight(text) * scale;
    var tx = _x - tw * 0.5;
    var ty = _y - th * 0.5;
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(QTE_COL_DARKEST);
    for (var ox = -1; ox <= 1; ox++) {
        for (var oy = -1; oy <= 1; oy++) {
            if (ox != 0 || oy != 0) UI_DrawTextTransformed(tx + ox * o, ty + oy * o, text, scale, scale, 0);
        }
    }
    draw_set_color(QTE_COL_LIGHTEST);
    UI_DrawTextTransformed(tx, ty, text, scale, scale, 0);
    draw_set_color(c_white);
}

// The enemy spends its turn winding up a telegraphed move (D7, D59): no damage and no status. The line, the banner and the strip's "!" say what comes next turn.
function Battle_EnemyWindup(_bc, _skill_id) {
    var e = _bc.e;
    var sk = SkillDB_Get(_skill_id);
    var text = Skill_WindupText(sk, e.name);
    _bc.enemy_last_skill_id = -1;
    _bc.enemy_last_windup = _skill_id;
    _bc.skill_banner_active = true;
    _bc.skill_banner_name = text;
    SFX_PlayEnemySpecial(e.id);
    if (instance_exists(_bc.enemy_inst)) {
        SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, QTE_TELEGRAPH_MS * 60 div 1000, ENEMY_FLASH_FRAMES, ENEMY_FLASH_RATE);
    }
    _bc.enemy_actions_remaining = max(0, _bc.enemy_actions_remaining - 1);
    var follow_state = (_bc.enemy_actions_remaining > 0) ? BSTATE_ENEMY_ACT : BSTATE_MENU;
    var fin = Battle_EnemyFinalizeTurnState(_bc, _bc.p, e);
    if (fin.ended) return;
    Battle_Message(_bc, text, follow_state);
}

function Battle_EnemyAct(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    // B4: a boss that crossed an HP threshold announces its new phase before it acts (its stats changed with the HP, Battle_PhaseSync)
    Battle_PhaseSync(_bc);
    if (_bc.phase_banner != "") {
        var phase_text = _bc.phase_banner;
        _bc.phase_banner = "";
        _bc.skill_banner_active = true;
        _bc.skill_banner_name = phase_text;
        SFX_PlayEnemySpecial(e.id);
        CameraShake_Start(QTE_SHAKE_PERFECT_MAG, QTE_SHAKE_PERFECT_FRAMES, SHAKE_DIR_H);
        Battle_Message(_bc, phase_text, BSTATE_ENEMY_ACT);
        return;
    }

    Battle_EnemyInitActionBudget(_bc, e);

    var force_damage_skill_debug = Debug_EnemyForceDamageSkillOnly();
    var plan = Battle_EnemyPlanTake(_bc);       // what Foresight showed (D79), or a fresh choice when nothing was planned
    var skill_id = plan.skill_id;
    _bc.enemy_action_pending = false;           // it is acting now: the strip must not plan (or show) the action after this one
    if (plan.kind == "windup") {                // B4: a telegraphed move is announced first, used next turn
        Battle_EnemyWindup(_bc, skill_id);
        return;
    }
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

    _bc.enemy_last_skill_id = use_skill ? skill_id : -1;   // what it really did (tests compare it with the Foresight preview)

    if (use_skill) {
        if (res.ok) {
            var exists_used = false;
            for (var ui = 0; ui < array_length(_bc.enemy_turn_used_skills); ui++) {
                if (_bc.enemy_turn_used_skills[ui] == skill_id) { exists_used = true; break; }
            }
            if (!exists_used) array_push(_bc.enemy_turn_used_skills, skill_id);
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

        if (!enemy_targets_self && Battle_EnemySkillCanBeDefended(sk, res, p)) {
            Battle_DefenceStart(_bc, sk, res, follow_state, qte_hp_before, qte_status_before);
            p.hp = qte_hp_before;   // the HUD keeps the HP from before the hit while the bar is up; Battle_DefenceResolve takes what gets through
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
            Battle_PlayerHitPop(_bc, res.dmg, res.crit);
        }

        if (Battle_CheckEnd(_bc, p, e)) return;
        var enemy_stun_note = Battle_StunResolve(_bc);   // Vine Trap and the like: a push-back on the timeline (D75)
        var end_skill_pack = Battle_EnemyFinalizeTurnState(_bc, p, e);
        if (end_skill_pack.ended) return;
        p = end_skill_pack.player;
        e = end_skill_pack.enemy;

        var skill_msg = Battle_EnemySkillComposeMessage(e.name, res) + enemy_stun_note;
        Battle_Message(_bc, skill_msg, follow_state, fx2);
    } else {
        var ew = _bc.enemy_weapon;
        if (!is_struct(ew) || !variable_struct_exists(ew, "power")) {
            ew = { power: e.basic_power, stat_type:STAT_ATK, acc:0, preferred_class:-1 };
            _bc.enemy_weapon = ew;
        }

        // Enemy basic attack SFX (non-skill turn).
        SFX_PlayEnemySpecial(e.id);

        // D80: enemies never miss; the only way the hit fails is Evasion on the player.
        var hit_res_e = Combat_TryDodge(e, p);

        _bc.last_hit = !hit_res_e.dodged;
        _bc.last_dmg = 0;
        _bc.last_crit = false;
        p = hit_res_e.defender;

        if (_bc.last_hit) {
            var crit_bonus_e = Status_GetSum(e, "crit_bonus");
            _bc.last_crit = Combat_CritCheck(e, crit_bonus_e);
            var dmg_pack_e = Combat_ApplyDamage(e, p, ew, (_bc.last_crit ? COMBAT_CRIT_MULT : 1), 1, { is_skill: false });
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
        }

        if (_bc.last_hit && _bc.last_dmg > 0) {
            CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_FRAMES, PLAYER_SHAKE_DIR);
            Battle_PlayerHitPop(_bc, _bc.last_dmg, _bc.last_crit);
        }

        var end_attack_pack = Battle_EnemyFinalizeTurnState(_bc, p, e);
        if (end_attack_pack.ended) return;
        p = end_attack_pack.player;
        e = end_attack_pack.enemy;

        var basic_msg = Battle_EnemySkillComposeMessage(e.name, { hit: _bc.last_hit, crit: _bc.last_crit, dmg: _bc.last_dmg, msg: "" });
        Battle_Message(_bc, basic_msg, follow_state);
    }
}

// ---- Turn timeline strip, enemy header (name, HP, stagger), floating numbers and the BREAK word (D74 D75 D92 D97 D99) ----
// GUI layer, the four palette colours only (UI_C_*), the Ui_* kit of D0 (Ui_Metrics, Ui_Box, Ui_DrawFrame, Ui_Text, Ui_AnimT, Ui_Bob, Ui_Glide).
#macro TURN_SLIDE_MS 120

// Sizes of the strip in GUI units. Sprites are drawn at a whole multiple (k) of the window pixel so they stay crisp at every window size.
function Battle_TimelineMetrics(_bc = noone) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var sx = Display_WorldScale();
    var k = max(1, round(sx * 0.6));
    var icon = 16 * k;
    var slot = icon + 6 * p;
    var gap = 2 * p;
    var n = TURN_PREVIEW_COUNT;
    var w = n * slot + (n - 1) * gap;
    var caption_h = mt.line_h + p;
    // Centred, unless the player's HP / MP bars and numbers (top left, drawn by obj_ui_controller) reach into it: then it moves right of them.
    var x0 = round((mt.gw - w) * 0.5);
    if (_bc != noone && instance_exists(_bc)) {
        var vis = UI_GetVisualScale();
        var hud_right = max(6, round(8 * vis)) + sprite_get_width(hp_bar) * UI_BAR_SCALE * UI_GetSpriteScale() + max(4, round(6 * vis))
            + max(UI_TextWidth(string(_bc.p.hp) + " / " + string(_bc.p.max_hp)), UI_TextWidth(string(_bc.p.mp) + " / " + string(_bc.p.max_mp)));
        x0 = clamp(max(x0, round(hud_right + 3 * p)), 0, max(0, mt.gw - w - mt.margin));
    }
    return { p: p, k: k, icon: icon, slot: slot, gap: gap, w: w, x0: x0, y0: mt.margin, caption_h: caption_h, h: slot + 2 * p + caption_h, line_h: mt.line_h };
}

// 9 x 5 eye (Foresight, D24): a pupil in an almond. Cells are p x p.
function Battle_DrawEye(_x, _y, _p, _col) {
    var rows = [124, 186, 313, 186, 124];   // bit 8 = the left column of the 9 wide picture
    for (var r = 0; r < 5; r++) {
        for (var c = 0; c < 9; c++) {
            if (((rows[r] >> (8 - c)) & 1) == 1) Ui_Box(_x + c * _p, _y + r * _p, _x + (c + 1) * _p, _y + (r + 1) * _p, _col);
        }
    }
}

function Battle_TimelineSprite(_bc, _who) {
    if (_who == TL_ENEMY) return _bc.e.sprite;
    if (is_struct(_bc.p) && variable_struct_exists(_bc.p, "class_cfg") && is_struct(_bc.p.class_cfg) && variable_struct_exists(_bc.p.class_cfg, "sprites")) {
        var sp = _bc.p.class_cfg.sprites;
        if (is_struct(sp) && variable_struct_exists(sp, "down") && sp.down != noone && sp.down != -1) return sp.down;
    }
    return noone;
}

// One slot at (_x, _y). The player's portrait sits on mid green, the enemy's on the darkest, so the two read apart at a glance.
// 3 x 7 "!" (B4): the big attack that follows a wind-up. Cells are p x p.
function Battle_DrawBang(_x, _y, _p, _col) {
    var rows = [2, 2, 2, 2, 2, 0, 2];   // bit 2 = the left column of the 3 wide picture
    for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 3; c++) {
            if (((rows[r] >> (2 - c)) & 1) == 1) Ui_Box(_x + c * _p, _y + r * _p, _x + (c + 1) * _p, _y + (r + 1) * _p, _col);
        }
    }
}

function Battle_DrawTimelineSlot(_bc, _x, _y, _m, _who, _current, _alpha, _eye, _windup = false) {
    var p = _m.p;
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    if (_current) Ui_Box(_x - p, _y - p, _x + _m.slot + p, _y + _m.slot + p, UI_C_LIGHTEST);
    Ui_DrawFrame(_x, _y, _m.slot, _m.slot, _alpha, p);
    Ui_Box(_x + 2 * p, _y + 2 * p, _x + _m.slot - 2 * p, _y + _m.slot - 2 * p, (_who == TL_PLAYER) ? UI_C_DARK : UI_C_DARKEST);
    var spr = Battle_TimelineSprite(_bc, _who);
    var cx = _x + _m.slot * 0.5;
    var cy = _y + _m.slot * 0.5;
    if (spr != noone && spr != -1) {
        var sw = max(1, sprite_get_width(spr));
        var sh = max(1, sprite_get_height(spr));
        var sc = min(_m.icon / sw, _m.icon / sh);
        var dx = round(cx - sw * sc * 0.5 + sprite_get_xoffset(spr) * sc);
        var dy = round(cy - sh * sc * 0.5 + sprite_get_yoffset(spr) * sc);
        draw_sprite_ext(spr, 0, dx, dy, sc, sc, 0, c_white, _alpha);
    } else {
        Ui_Text(cx, cy - _m.line_h * 0.5, (_who == TL_PLAYER) ? "P" : "E", UI_C_LIGHTEST, fa_center);
    }
    if (_eye) Battle_DrawEye(_x + _m.slot - 2 * p - 9 * p, _y + 2 * p, p, UI_C_LIGHTEST);
    if (_windup) {   // a light box with a dark "!" in the top left corner of the slot: this turn is the big attack
        Ui_Box(_x + 2 * p, _y + 2 * p, _x + 7 * p, _y + 11 * p, UI_C_LIGHTEST);
        Battle_DrawBang(_x + 3 * p, _y + 3 * p, p, UI_C_DARKEST);
    }
    draw_set_alpha(a0);
}

// The strip across the top: the current actor first (ringed, gently bobbing), then the next four. When the order changes it slides for
// TURN_SLIDE_MS: after a turn the row moves left one slot and the new last one fades in; after a push-back (stun, BREAK) the row fades in place.
// With Foresight, the first upcoming enemy slot wears an eye and the caption under it names the action (a big attack gets "!").
function Battle_DrawTimeline(_bc) {
    var m = Battle_TimelineMetrics(_bc);
    var p = m.p;
    var t = Ui_AnimT(_bc.tl_slide_start, current_time, TURN_SLIDE_MS);
    var pitch = m.slot + m.gap;
    var slots = Battle_TimelineSlots(_bc);
    var shift_mode = (_bc.tl_slide_kind == 0);
    var shift = shift_mode ? round((1 - t) * pitch) : 0;
    var fore_x = -1;
    var fore = undefined;
    var n = array_length(slots);

    if (shift_mode && t < 1) {   // the actor that just went leaves to the left
        Battle_DrawTimelineSlot(_bc, m.x0 - pitch + shift, m.y0 + p, m, _bc.tl_prev_who, false, 1 - t, false);
    }
    for (var i = 0; i < n; i++) {
        var s = slots[i];
        var xx = m.x0 + i * pitch + shift;
        var yy = m.y0 + (s.current ? Ui_Bob(current_time, p) : p);
        var al = 1;
        if (shift_mode && i == n - 1) al = t;
        if (!shift_mode) al = 0.4 + 0.6 * t;
        Battle_DrawTimelineSlot(_bc, xx, yy, m, s.who, s.current, al, is_struct(s.foresight), s.windup);
        if (is_struct(s.foresight)) { fore = s.foresight; fore_x = xx + m.slot * 0.5; }
    }
    if (is_struct(fore)) {
        var label = fore.name + (fore.big ? " !" : "");
        var tw = UI_TextWidth(label) + 9 * p + 2 * p;
        var tx = clamp(fore_x - tw * 0.5, p, Display_GuiW() - tw - p);
        var ty = m.y0 + m.slot + 3 * p;
        Ui_Box(tx - p, ty - p div 2, tx + tw + p, ty + m.line_h + p div 2, UI_C_DARKEST);
        Battle_DrawEye(tx, ty + (m.line_h - 5 * p) * 0.5, p, UI_C_LIGHTEST);
        Ui_Text(tx + 9 * p + 2 * p, ty, label, UI_C_LIGHTEST);
    }
}

function Battle_TimelineBottom() {
    var m = Battle_TimelineMetrics();
    return m.y0 + m.h;
}

// Where the header block sits: { cx, x1, y1, bw, h }. Also used to keep the BREAK word clear of it.
function Battle_EnemyHeaderRect(_bc) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var sx = Display_WorldScale();
    var out = { cx: Display_GuiW() * 0.5, x1: 0, y1: round(Display_GuiH() * 0.3), bw: round(36 * sx), h: 0 };
    if (!instance_exists(_bc.enemy_inst) || _bc.enemy_inst.sprite_index == noone) return out;
    var inst = _bc.enemy_inst;
    var spr = inst.sprite_index;
    out.cx = ((inst.x - sprite_get_xoffset(spr) - _bc.cam_base_x) + sprite_get_width(spr) * abs(inst.image_xscale) * 0.5) * sx;
    var top = (inst.y - sprite_get_yoffset(spr) + sprite_get_bbox_top(spr) * abs(inst.image_yscale) - _bc.cam_base_y) * sx;
    out.bw = clamp(round(sprite_get_width(spr) * abs(inst.image_xscale) * sx), round(36 * sx), mt.gw - 4 * mt.margin);
    out.h = mt.line_h + p + 4 * p + p + 3 * p + 2 * p;
    out.x1 = round(out.cx - out.bw * 0.5);
    out.y1 = round(max(Battle_TimelineBottom() + p, top - out.h - 2 * p));
    return out;
}

// Name, HP and stagger meter above the enemy (D99). The stagger bar flashes when a hit lands and pulses while the enemy is BROKEN.
function Battle_DrawEnemyHeader(_bc, _alpha) {
    if (!instance_exists(_bc.enemy_inst) || _bc.enemy_inst.sprite_index == noone) return;
    var e = _bc.e;
    var mt = Ui_Metrics();
    var p = mt.p;
    var hdr = Battle_EnemyHeaderRect(_bc);
    var cx = hdr.cx;
    var bw = hdr.bw;
    var x1 = hdr.x1;
    var y1 = hdr.y1;
    var hp_h = 4 * p;
    var sg_h = 3 * p;
    var name_h = mt.line_h;
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);

    Ui_Text(cx, y1, e.name, UI_C_LIGHTEST, fa_center);
    var hy = y1 + name_h + p;
    _bc.enemy_hp_shown = Ui_Glide(_bc.enemy_hp_shown, e.hp, current_time - _bc.enemy_hp_clock, 120);
    _bc.enemy_hp_clock = current_time;
    var hp_ratio = (e.max_hp > 0) ? clamp(_bc.enemy_hp_shown / e.max_hp, 0, 1) : 0;
    Ui_Box(x1, hy, x1 + bw, hy + hp_h, UI_C_LIGHTEST);
    Ui_Box(x1 + p, hy + p, x1 + bw - p, hy + hp_h - p, UI_C_DARKEST);
    Ui_Box(x1 + p, hy + p, x1 + p + round((bw - 2 * p) * hp_ratio), hy + hp_h - p, UI_C_LIGHT);

    var sy = hy + hp_h + p;
    var broken = (variable_struct_exists(e, "broken") && e.broken);
    var smax = variable_struct_exists(e, "stagger_max") ? e.stagger_max : 0;
    if (smax > 0) {
        var flash = (current_time - _bc.stagger_flash_start) < 120;
        var since_break = current_time - _bc.break_start;
        Ui_Box(x1, sy, x1 + bw, sy + sg_h, UI_C_LIGHTEST);
        Ui_Box(x1 + p, sy + p div 2, x1 + bw - p, sy + sg_h - p div 2, UI_C_DARKEST);
        var inner_w = bw - 2 * p;
        if (broken) {   // full and pulsing until the enemy's next turn
            var pulse = (floor(current_time / 120) mod 2 == 0) ? UI_C_LIGHTEST : UI_C_DARK;
            Ui_Box(x1 + p, sy + p div 2, x1 + p + inner_w, sy + sg_h - p div 2, pulse);
        } else {
            var fill_col = (flash || since_break < 400) ? UI_C_LIGHT : UI_C_LIGHTEST;
            Ui_Box(x1 + p, sy + p div 2, x1 + p + round(inner_w * clamp(e.stagger / smax, 0, 1)), sy + sg_h - p div 2, fill_col);
        }
    }
    draw_set_alpha(a0);
}

// Floating numbers (D92). Pop in (+35% for 100 ms), rise ~14 design pixels, fade in the last 200 ms. Perfect largest, Weak smallest and dimmest.
function Battle_DrawPops(_bc) {
    var sx = Display_WorldScale();
    var o = max(1, round(sx / 2));
    var a0 = draw_get_alpha();
    var ex = Display_GuiW() * 0.5;
    var ey = Display_GuiH() * 0.4;
    if (instance_exists(_bc.enemy_inst) && _bc.enemy_inst.sprite_index != noone) {
        var inst = _bc.enemy_inst;
        var spr = inst.sprite_index;
        ex = ((inst.x - sprite_get_xoffset(spr) - _bc.cam_base_x) + sprite_get_width(spr) * abs(inst.image_xscale) * 0.5) * sx;
        ey = ((inst.y - sprite_get_yoffset(spr) - _bc.cam_base_y) + sprite_get_height(spr) * abs(inst.image_yscale) * 0.5) * sx;
    }
    var px = (_bc.player_fx_x - _bc.cam_base_x) * sx;
    var py = (_bc.player_fx_y - _bc.cam_base_y) * sx;

    for (var i = 0; i < array_length(_bc.pops); i++) {
        var pp = _bc.pops[i];
        var el = current_time - pp.start;
        if (el < 0 || el >= POP_MS) continue;
        var fill = UI_C_LIGHTEST;
        var edge = UI_C_DARKEST;
        switch (pp.style) {
            case QTE_GOOD: fill = UI_C_LIGHT; break;
            case QTE_WEAK: fill = UI_C_DARK; edge = UI_C_LIGHT; break;
            case "heal":   fill = UI_C_LIGHT; break;
        }
        var sc = pp.scale * ((el < 100) ? (1 + 0.35 * (1 - el / 100)) : 1);
        var rise = (1 - sqr(1 - clamp(el / 500, 0, 1))) * 14 * sx;
        var bx = pp.on_player ? px : ex;
        var by = pp.on_player ? (py - 6 * sx) : ey;
        var jitter = ((pp.n mod 2 == 1) ? 1 : -1) * 14 * sx * ceil(pp.n / 2);   // the first is centred, the next ones step aside so they stay readable
        var tw = UI_TextWidth(pp.text) * sc;
        var th = UI_TextHeight(pp.text) * sc;
        var tx = bx + jitter - tw * 0.5;
        var ty = by - rise - th * 0.5;
        draw_set_alpha(clamp((POP_MS - el) / 200, 0, 1));
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(edge);
        for (var ox = -1; ox <= 1; ox++) {
            for (var oy = -1; oy <= 1; oy++) {
                if (ox != 0 || oy != 0) UI_DrawTextTransformed(tx + ox * o, ty + oy * o, pp.text, sc, sc, 0);
            }
        }
        draw_set_color(fill);
        UI_DrawTextTransformed(tx, ty, pp.text, sc, sc, 0);
    }

    // The BREAK word over the enemy: pops in big, blinks, rises, fades (D92).
    var bel = current_time - _bc.break_start;
    if (bel >= 0 && bel < 1000) {
        var txt = Loc_T("battle.hud.break", "BREAK!");
        var bsc = 2.0 * ((bel < 150) ? (1 + 0.6 * (1 - bel / 150)) : 1);
        var hdr = Battle_EnemyHeaderRect(_bc);
        var mt = Ui_Metrics();
        var brise = (1 - sqr(1 - clamp(bel / 600, 0, 1))) * 10 * sx;
        var bw2 = UI_TextWidth(txt) * bsc;
        var bh2 = UI_TextHeight(txt) * bsc;
        var bx2 = ex - bw2 * 0.5;
        var by2 = max(Battle_TimelineBottom() + mt.p, hdr.y1 - bh2 - 2 * mt.p) - brise;
        var bfill = (bel < 500 && (floor(bel / 90) mod 2 == 1)) ? UI_C_LIGHT : UI_C_LIGHTEST;
        draw_set_alpha(clamp((1000 - bel) / 250, 0, 1));
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(UI_C_DARKEST);
        for (var bx3 = -1; bx3 <= 1; bx3++) {
            for (var by3 = -1; by3 <= 1; by3++) {
                if (bx3 != 0 || by3 != 0) UI_DrawTextTransformed(bx2 + bx3 * o * 2, by2 + by3 * o * 2, txt, bsc, bsc, 0);
            }
        }
        draw_set_color(bfill);
        UI_DrawTextTransformed(bx2, by2, txt, bsc, bsc, 0);
    }
    draw_set_alpha(a0);
    draw_set_color(c_white);
}
