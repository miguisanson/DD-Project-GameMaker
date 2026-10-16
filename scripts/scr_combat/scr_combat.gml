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

// R1 (D119): a crit chance is a bag of marbles: n marbles, n * chance of them red, drawn without putting back until the bag is empty.
// The smallest bag (up to 20) that holds the chance exactly; otherwise 20 marbles with round(20 * chance) red.
// (<= on purpose: GML compares reals with an epsilon, so "< 0.000001" is false for a difference of 0.)
function Crit_BagSize(_p) {
    for (var n = 1; n <= 20; n++) {
        var reds = n * _p;
        if (abs(reds - round(reds)) <= 0.000001) return { n: n, reds: round(reds) };
    }
    return { n: 20, reds: round(20 * _p) };
}

// D126: the marble bag as a reusable helper. A bag is { p, left } stored on the holder (a fighter, or the run) under "<key>_bag":
// `left` holds the marbles not drawn yet (true = the chance came up). It is drawn from the given stream without putting back and refilled
// (shuffled with that stream) when it runs dry or when the chance changed. A chance of 1 or 0 needs no bag and draws no random number.
function Bag_Field(_key) {
    return string(_key) + "_bag";
}

// Marbles left in the holder's bag for this key (0 when it has none).
function Bag_Left(_holder, _key) {
    var f = Bag_Field(_key);
    if (is_struct(_holder) && variable_struct_exists(_holder, f)) {
        var b = variable_struct_get(_holder, f);
        if (is_struct(b) && is_array(b.left)) return array_length(b.left);
    }
    return 0;
}

// Throws the bag away (a fresh one is filled on the next draw).
function Bag_Clear(_holder, _key) {
    var f = Bag_Field(_key);
    if (is_struct(_holder) && variable_struct_exists(_holder, f)) variable_struct_remove(_holder, f);
}

// One draw from the bag (_holder, _key) for the chance _p, shuffled with _rng when it has to be filled.
function Bag_Draw(_holder, _key, _p, _rng) {
    if (_p >= 0.999999) { Bag_Clear(_holder, _key); return true; }
    if (_p <= 0) { Bag_Clear(_holder, _key); return false; }
    var f = Bag_Field(_key);
    var b = variable_struct_exists(_holder, f) ? variable_struct_get(_holder, f) : undefined;
    if (!is_struct(b) || !is_array(b.left) || array_length(b.left) <= 0 || abs(b.p - _p) > 0.000001) {
        var size = Crit_BagSize(_p);
        var marbles = [];
        for (var i = 0; i < size.n; i++) array_push(marbles, i < size.reds);
        b = { p: _p, left: Rng_Shuffle(_rng, marbles) };
        variable_struct_set(_holder, f, b);
    }
    return array_pop(b.left);
}

// Marbles left in the fighter's crit bag (0 when it has none).
function Crit_BagLeft(_f) {
    return Bag_Left(_f, "crit");
}

function Combat_CritCheck(_attacker, _crit_bonus) {
    var chance = Combat_CritChance(_crit_bonus);
    if (chance <= 0) return false;
    return Bag_Draw(_attacker, "crit", chance, Run_Stream("combat"));   // C1: run randomness comes from the run's combat stream
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

// Every multiplier of one hit except the QTE grade (spec section 4): the attacker's damage statuses, the crit and skill multipliers, the defender's guard
// statuses, the assist setting and the BREAK bonus. Pure: it only reads (a guard status is consumed by Combat_ApplyDamage, not here).
function Combat_HitMult(_attacker, _defender, _crit_mult = 1, _skill_mult = 1) {
    var mult = Status_GetMul(_attacker, "dmg_mult") * _crit_mult * _skill_mult;
    mult *= Status_GetMul(_defender, "guard_mult");
    mult *= Combat_AssistMult(_defender);
    mult *= Combat_BreakMult(_defender);   // spec section 11: a BROKEN enemy takes +50% until its next turn
    return mult;
}

// The damage one hit does, with nothing changed (D135: the damage preview reads this; Combat_ApplyDamage deals exactly this number).
function Combat_HitDamage(_attacker, _defender, _src, _crit_mult = 1, _skill_mult = 1, _grade = 1) {
    return Combat_RatioDamage(_src.power, Combat_AttackStat(_attacker, _src), Combat_EffectiveStat(_defender, STAT_DEF), _grade, Combat_HitMult(_attacker, _defender, _crit_mult, _skill_mult));
}

// _src = { power (final formula power), stat_type }. _ctx: { grade_mult, is_skill }. Statuses: dmg_mult (attacker), guard_mult (defender, consumed on hit).
function Combat_ApplyDamage(_attacker, _defender, _src, _crit_mult = 1, _skill_mult = 1, _ctx = undefined) {
    var dmg_ctx = is_struct(_ctx) ? _ctx : {};
    var grade = variable_struct_exists(dmg_ctx, "grade_mult") ? dmg_ctx.grade_mult : 1;

    var dmg = Combat_HitDamage(_attacker, _defender, _src, _crit_mult, _skill_mult, grade);
    if (Status_GetMul(_defender, "guard_mult") != 1) _defender = Status_ConsumeByField(_defender, "consume_on_hit");

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

    // C3 (D86): a Venomous elite poisons what it hurts
    if (dmg > 0 && is_struct(_attacker) && is_struct(_defender) && variable_struct_exists(_attacker, "elite") && _attacker.elite == "venomous"
    && variable_struct_exists(_defender, "is_player") && _defender.is_player) {
        _defender = Status_Add(_defender, STATUS_POISON, 1, 1, ELITE_VENOM_STACKS);
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
    if (!variable_struct_exists(entry, "at")) entry.at = current_time;   // the HUD shows an entry for a few seconds (Battle_DrawLog)

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

// D108 F2b-1: a message hold is a ms countdown (wait_timer), counted down once per step by Presentation_StepMs(delta_time), so it lasts the same
// time at any frame rate. The hold is spent when within COMBAT_HOLD_SLACK_MS of 0.
function Combat_ActionHoldMs() {
    return COMBAT_ACTION_HOLD_SEC * 1000;   // D55: the pause after a player or enemy action (0.3 s)
}

function Combat_HoldActive(_timer_ms) {
    return _timer_ms > COMBAT_HOLD_SLACK_MS;
}

function Combat_HoldStep(_timer_ms, _step_ms) {
    return max(0, _timer_ms - _step_ms);
}

function Battle_Message(_bc, _text, _next_state, _fx = noone, _hold_ms = -1) {
    _bc.message_text = _text;
    _bc.message_next_state = _next_state;
    _bc.battle_state = BSTATE_MESSAGE;
    _bc.wait_fx = _fx;
    _bc.wait_timer = (_hold_ms >= 0) ? _hold_ms : Combat_ActionHoldMs();
    Combat_Log(_text);
}

function Battle_LootAppendNormalized(_dest, _src) {
    var out = _dest;
    if (!is_array(out)) out = [];
    if (!is_array(_src)) return out;

    for (var i = 0; i < array_length(_src); i++) {
        var it = _src[i];
        // a drop is { item_id, qty }; a stolen item is recorded as { id, qty } (Skill_StealRecord). Both are accepted; the result is always { item_id, qty }.
        if (!is_struct(it)) continue;
        var key = variable_struct_exists(it, "item_id") ? "item_id" : (variable_struct_exists(it, "id") ? "id" : "");
        if (key == "") continue;
        var iid = round(real(variable_struct_get(it, key)));
        var qty = variable_struct_exists(it, "qty") ? max(0, round(real(it.qty))) : 0;
        if (qty <= 0) continue;

        var merged = false;
        for (var j = 0; j < array_length(out); j++) {
            if (!is_struct(out[j]) || !variable_struct_exists(out[j], "item_id")) continue;
            if (out[j].item_id != iid) continue;
            var prev_qty = variable_struct_exists(out[j], "qty") ? max(0, round(real(out[j].qty))) : 0;
            out[j].qty = prev_qty + qty;
            merged = true;
            break;
        }

        if (!merged) array_push(out, { item_id: iid, qty: qty });
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
        loot: [],
        gold: 0,           // C3 (D23)
        card_pick: false   // C3 (D86): an elite always leaves a card pick
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

        // C3: gold from every win (Coin Sense and the Lucky Charm in Gold_Scale); an elite also owes a card pick (D86)
        out.gold = Gold_ForEnemy(Run_Stream("loot"), _e, _p);
        Gold_Add(Run_Get(), out.gold);
        if (variable_struct_exists(_e, "is_elite") && _e.is_elite) {
            _p = Elite_GrantPick(_p);
            out.card_pick = true;
        }
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
        gold_gain: (is_struct(_rewards) && variable_struct_exists(_rewards, "gold")) ? max(0, round(real(_rewards.gold))) : 0,   // C3
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
        array_push(lines, Loc_T("combat.msg.floor1_reaction.0", "That thing was alive. And I nearly wasn't."));
        array_push(lines, Loc_T("combat.msg.floor1_reaction.1", "Okay. Okay. I just need to get out of here."));
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
        var regen = Elite_Regen(_bc.e);   // C3 (D86): a Regenerating elite heals as its turn starts
        if (regen > 0) Battle_PopAdd(_bc, "+" + string(regen), false, "heal", 1);
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

// The sound layered on the grade sound when a hit BREAKs. (_perfect: the grade sound already is the Perfect sample.)
// The strongest grade sound (qte_perfect) is the layer, unless the grade sound already is that sample: then the layer is the heavy hit under it, so two different
// samples start together and never the same one twice (that was +6 dB on the commonest BREAK, and no distinct cue).
function Battle_BreakSfxKey(_perfect) {
    return _perfect ? Qte_GradeSfxKey(QTE_GOOD) : Qte_GradeSfxKey(QTE_PERFECT);
}

// A landed player hit fills the enemy's stagger meter; a full meter is a BREAK (D75, D92). Returns the text to add to the battle message.
function Battle_StaggerHit(_bc, _power, _stun_skill, _perfect, _hits = 1) {
    var e = _bc.e;
    if (!is_struct(e) || e.hp <= 0) return "";
    var gain = Stagger_Gain(_power, _stun_skill, _perfect) * max(1, _hits);
    _bc.stagger_flash_start = current_time;
    Tutorial_Trigger("stagger");   // D45: the first time the meter fills
    if (!Stagger_Add(e, gain)) return "";
    _bc.rumble_break = true;       // H3: the controller rumble must not miss a BREAK that ends again before it looks (a fast enemy acts right after the push-back)
    Turn_Push(_bc.tl, TL_ENEMY);   // pushed back one turn
    _bc.tl_slide_start = current_time;
    _bc.tl_slide_kind = 1;
    _bc.break_start = current_time;
    var last_key = global.sfx_last_key;   // the BREAK sound is a second layer on top of the grade sound: the grade stays the "last key" the bot checks
    SFX_Play(Battle_BreakSfxKey(_perfect), _perfect ? 0.8 : 1, _perfect ? 0.8 : 1);
    global.sfx_last_key = last_key;
    CameraShake_Start(QTE_SHAKE_PERFECT_MAG, QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
    if (_bc.hitstop_ms > 0) {   // D138 / D139: the hit's freeze is still to come: a BREAK freezes 120 ms and punches the zoom in (Battle_HitFeel)
        _bc.hitstop_ms = max(_bc.hitstop_ms, FEEL_FREEZE_HEAVY_MS);
        _bc.feel_contact = true;
        _bc.feel_break = true;
    }
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
        if (!_bc.battle_over) RunStats_FightWon();   // G9 (D137)
        _bc.battle_over = true;
        var rewards = Battle_GrantRewards(_p, _e);
        _p = rewards.player;
        _p = Equip_PassiveBattleCleanup(_p);
        _p = Status_ClearAll(_p);
        GameState_SetPlayer(_p);
        EnemyPersist_ResolveBattle(true);
        var gs = GameState_Get();
        gs.pending_post_battle_dialogue_lines = Battle_BuildVictoryDialogueLines(_e, rewards, _p);

        var slain_text = Loc_T("combat.msg.enemy_slain", "{enemy} has been slain.", { enemy: _e.name });
        if (!Battle_DeathPopBegin(_bc, _e, slain_text)) {   // D138: the enemy bursts first, then the message (no picture to burst: the message at once)
            Battle_Message(_bc, slain_text, BSTATE_END_RUN, noone, COMBAT_ACTION_DELAY_MS);
        }
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

// D35: the one accessibility setting (Settings > QTE assist). On, every zone of the sliding bar and the defence bar is x1.5 wider, and the
// arrow sequences get x1.3 the time (the time bar and the Perfect window; a wrong press still costs the same). Pure by the flag; the live
// readers below take the flag from the settings. qte_window_mult is the older hook (1 to 3) and still multiplies the zones when set.
function Qte_AssistZoneMult(_on) {
    return _on ? QTE_ASSIST_ZONE_MULT : 1;
}

function Qte_AssistTimeMult(_on) {
    return _on ? QTE_ASSIST_TIME_MULT : 1;
}

function Qte_AssistOn() {
    var gs = GameState_Get();
    return is_struct(gs) && variable_struct_exists(gs, "settings") && is_struct(gs.settings) && variable_struct_exists(gs.settings, "qte_assist") && (gs.settings.qte_assist != 0);
}

function Qte_AssistMult() {
    var gs = GameState_Get();
    var m = Qte_AssistZoneMult(Qte_AssistOn());
    if (is_struct(gs) && variable_struct_exists(gs, "settings") && is_struct(gs.settings) && variable_struct_exists(gs.settings, "qte_window_mult")) {
        m *= clamp(real(gs.settings.qte_window_mult), 1, 3);
    }
    return m;
}

function Qte_AssistTimeMultNow() {
    return Qte_AssistTimeMult(Qte_AssistOn());
}

// Milliseconds one frame adds to the QTE clock, from delta_time (microseconds). Capped so a hitch cannot skip the bar (QTE-01, QTE-14).
// D122 (bug hunt 7): while the window is not in front (global.focus_prev, kept by Focus_Step) it adds nothing, so a bar, the arrows, the defence bar with its
// telegraph, the grade word and the hit freeze all stop and carry on exactly where they were.
function Qte_StepMs(_delta_us) {
    if (variable_global_exists("focus_prev") && !global.focus_prev) return 0;
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
        case SKILL_VINE_TRAP:       return { sweep_ms: 1300, perfect_half_width: 60, good_half_width: 125, ok_half_width: 200 };
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

// Whether an enemy skill that just landed on the player gets the defence bar: a damaging, telegraphed heavy move (D7, D59). Plain moves just hit (I-066).
// To make another enemy attack defendable, set uses_defensive_qte and telegraphed on its skill and add a row to Qte_DefenceParams.
function Battle_EnemySkillCanBeDefended(_skill, _res, _target) {
    if (!is_struct(_skill) || !is_struct(_res) || !is_struct(_target)) return false;
    if (!variable_struct_exists(_skill, "uses_defensive_qte") || !_skill.uses_defensive_qte) return false;
    if (!variable_struct_exists(_skill, "telegraphed") || !_skill.telegraphed) return false;
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
    Tutorial_Trigger("bar");   // D45: the clock waits behind the pop-up (the battle controller does not step)
}

// The enemy shake, the small camera shakes, the sparks, the jolt and the recoil of a landed hit. After the hit's freeze (every damaging hit, Battle_HitFreeze) Step_0 calls this, so the freeze comes first.
function Battle_QteImpactFeedback(_bc) {
    if (_bc.last_dmg > 0 && instance_exists(_bc.enemy_inst) && !Battle_DeathPopActive(_bc)) {
        SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, ENEMY_SHAKE_MS, ENEMY_FLASH_MS, ENEMY_FLASH_RATE_MS);
    }
    if (_bc.qte_result_key == QTE_PERFECT) CameraShake_Start(QTE_SHAKE_PERFECT_MAG, QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
    if (_bc.qte_result_key == QTE_GOOD) CameraShake_Start(QTE_SHAKE_GOOD_MAG, QTE_SHAKE_GOOD_MS, SHAKE_DIR_H);
    Battle_HitFeel(_bc);   // D138 / D139: sparks, jolt, recoil, zoom punch
}

// The weapon the basic attack swings: the one the battle started with, or what the player has equipped now (nothing = bare hands).
function Battle_PlayerWeapon(_bc) {
    var w = _bc.player_weapon;
    if (!is_struct(w) || !variable_struct_exists(w, "power")) {
        w = ItemDB_Get(_bc.p.equip.weapon);
        if (w.id == 0) w = { power:COMBAT_UNARMED_POWER, stat_type:STAT_ATK, acc:0, preferred_class:-1 };
        _bc.player_weapon = w;
    }
    return w;
}

// One hit of the player's basic attack (D20): the damage at the grade's multiplier, then the gear passives' bonus pressure. Changes the defender and
// returns { dealt, defender }. The one place the number is made: the attack resolves through it, the preview (Battle_AttackPreview) mirrors it.
function Battle_PlayerAttackHit(_p, _e, _w, _crit, _grade_mult, _timing_key) {
    var dmg_pack = Combat_ApplyDamage(_p, _e, Combat_BasicSource(_w), (_crit ? COMBAT_CRIT_MULT : 1), 1, { is_skill: false, grade_mult: _grade_mult });
    var e = dmg_pack.defender;
    var dealt = max(0, dmg_pack.dmg);

    // FUN-FIRST gear passives add bonus pressure after the grade.
    var bonus_dmg = Equip_PlayerBonusDamage(_p, e, dealt, false, _timing_key);
    if (bonus_dmg > 0) {
        var spend = min(bonus_dmg, e.hp);
        e.hp = max(0, e.hp - spend);
        dealt += spend;
    }
    return { dealt: dealt, defender: e };
}

// The player's basic attack always lands (D20): damage = base x the grade's multiplier, never 0.
function Battle_PlayerAttackResolveTimed(_bc, _timing) {
    if (_bc.throw_item > 0) {   // C3 (D84): this bar was started by a throw, not an attack
        Battle_ThrowResolve(_bc, _timing);
        return;
    }
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

    var w = Battle_PlayerWeapon(_bc);

    _bc.last_hit = true;
    var crit_bonus = Status_GetSum(p, "crit_bonus");
    _bc.last_crit = Combat_CritCheck(p, crit_bonus);
    var hit = Battle_PlayerAttackHit(p, e, w, _bc.last_crit, timing.mult, timing_key);
    e = hit.defender;
    var dealt = hit.dealt;

    _bc.last_dmg = dealt;
    RunStats_Qte(timing_key); RunStats_Dealt(dealt, _bc.last_crit);   // G9 (D137)
    Battle_HitPop(_bc, dealt, timing_key, _bc.last_crit);
    p = Equip_PlayerPerfectHitApply(p, timing_key);

    var side_fx = Equip_PassiveOnAttackResolved(p, e, timing_key, true, _bc.last_dmg);
    p = side_fx.attacker;
    e = side_fx.defender;
    var passive_msg = side_fx.msg;

    p = Status_ConsumeByField(p, "consume_on_attack");

    // D61 / D138 feedback: every damaging hit freezes the picture first (also on a killing blow); the shakes, sparks and jolt follow it.
    Battle_HitFreeze(_bc, timing_key, _bc.last_crit);

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
    _bc.sq_st = Qte_SeqNew(Qte_SkillSequence(_skill_id), Qte_AssistTimeMultNow(), Qte_PerfectWiden(p));   // D35: assist = more time
    _bc.sq_ms = -QTE_SEQ_LEAD_IN_MS;   // the arrows are up and the clock waits; the press that chose the skill cannot count
    _bc.sq_wrong_ms = 0;
    _bc.sq_pop_ms = 0;
    _bc.sq_pop_idx = -1;
    _bc.sq_active = true;
    _bc.skill_banner_active = true;
    _bc.skill_banner_name = skill.name;
    _bc.battle_state = BSTATE_SKILL_QTE;
    Tutorial_Trigger("arrows");   // D45
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
            SFX_PlayUI("ui_deny");
            _bc.sq_wrong_ms = QTE_SEQ_SHAKE_MS;
        }
    } else {
        Qte_SeqTick(st, _bc.sq_ms);
    }

    if (st.done) {
        _bc.sq_active = false;
        RunStats_Qte(st.key);   // G9 (D137)
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
    _bc.last_crit = (_res.dmg > 0) && variable_struct_exists(_res, "crit") && _res.crit;
    RunStats_Dealt(_bc.last_dmg, _bc.last_crit);   // G9 (D137)
    if (_res.dmg > 0) Battle_HitPop(_bc, _res.dmg, _grade.key, _res.crit);
    if (_res.dmg < 0) Battle_HealPop(_bc, -_res.dmg);
    if (_res.dmg > 0) Battle_HitFreeze(_bc, _grade.key, _bc.last_crit);
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
    if (Item_IsThrowable(item)) {   // C3 (D84): a throwable uses the sliding bar first
        Battle_ThrowBegin(_bc, _item_id);
        return;
    }
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

// C3 (D84): a throw. The Items menu picks a throwable, the sliding bar runs (the default bar, widened by Foresight like every bar), the press sets the
// grade, Throw_Resolve (scr_db_item) does the maths, the item is used up and the throw costs the turn. A Perfect smoke bomb ends the fight like a run.
function Battle_ThrowBegin(_bc, _item_id) {
    _bc.throw_item = _item_id;
    _bc.qte_perfect_widen = Qte_PerfectWiden(_bc.p);
    _bc.qte_params = Qte_WidenPerfect(Qte_BarParams("default"), _bc.qte_perfect_widen);
    _bc.qte_assist = Qte_AssistMult();
    _bc.qte_ms = -QTE_LEAD_IN_MS;
    _bc.qte_press_ms = QTE_NO_PRESS;
    _bc.qte_active = true;
    _bc.battle_state = BSTATE_ATTACK_TIMING;
    Tutorial_Trigger("throwables");   // C4 (D45)
}

function Battle_ThrowResolve(_bc, _timing) {
    var p = _bc.p;
    var e = _bc.e;
    var iid = _bc.throw_item;
    _bc.throw_item = -1;
    _bc.qte_active = false;
    _bc.qte_result_text = _timing.label;
    _bc.qte_result_key = _timing.key;
    _bc.qte_result_mult = _timing.mult;
    _bc.qte_result_ms = QTE_RESULT_MS;
    var word_pos = Battle_AttackTimingTarget(_bc);
    _bc.qte_word_x = word_pos.x;
    _bc.qte_word_y = word_pos.y;
    SFX_Play(Qte_GradeSfxKey(_timing.key));

    var res = Throw_Resolve(iid, p, e, _timing.key);
    p.inventory = Inv_Remove(p.inventory, iid, 1);
    _bc.last_hit = true;
    _bc.last_dmg = res.dmg;
    _bc.last_crit = false;
    RunStats_Qte(_timing.key); RunStats_Dealt(res.dmg, false);   // G9 (D137)
    Battle_HitPop(_bc, res.dmg, _timing.key);
    Battle_HitFreeze(_bc, _timing.key, false);

    if (Battle_CheckEnd(_bc, p, e)) return;

    var note = "";
    if (res.dmg > 0) note += Battle_StaggerHit(_bc, COMBAT_POWER_SCALE * ItemDB_Get(iid).use.power, res.stun, _timing.key == QTE_PERFECT);
    note += Battle_StunResolve(_bc);
    if (res.escape) {
        Battle_EscapeResolve(e);
        _bc.p = p;
        _bc.e = e;
        Battle_Message(_bc, res.msg, BSTATE_END_RUN, noone, COMBAT_ACTION_DELAY_MS);
        return;
    }
    Battle_Message(_bc, res.msg + note, BSTATE_ENEMY_ACT);
    if (Battle_PlayerFinalizeTurn(_bc, p, e)) return;
}

function Battle_GetSkillList(_bc) {
    var p = _bc.p;
    if (is_array(p.skills)) return p.skills;
    return [];
}

function Battle_GetItemList(_bc) {
    return Battle_ItemList(_bc.p);
}

// Spec section 8: the one random roll left in a flee. Bosses are checked before this.
#macro FLEE_FAIL_STEP 0.25
// R1 (D121): SPD / (SPD + enemy SPD), +0.25 for every failed try this battle (certain after enough tries).
function Battle_RunChance(_spd_player, _spd_enemy, _fails = 0) {
    var sp = max(1, _spd_player);
    var se = max(1, _spd_enemy);
    return min(1, sp / (sp + se) + FLEE_FAIL_STEP * _fails);
}

// R1b (D124): the flee chance as a whole percent for the RUN row; -1 against a boss (the same rule Battle_RunAttempt uses).
function Battle_RunPct(_p, _e, _fails) {
    if (is_struct(_e) && variable_struct_exists(_e, "id") && (_e.id == ENEMY_MINI_BOSS || _e.id == ENEMY_FINAL_BOSS)) return -1;
    var chance = Battle_RunChance(Combat_EffectiveStat(_p, STAT_SPD), Combat_EffectiveStat(_e, STAT_SPD), _fails);
    if (chance >= 1) return 100;   // review 1: 100 only for a sure thing; 0.9955 must not read "100%" while the escape can still fail
    return min(99, floor(chance * 100));
}

function Battle_RunAttempt(_bc) {
    var p = _bc.p;
    var e = _bc.e;

    var enemy_id = -1;
    if (is_struct(e) && variable_struct_exists(e, "id")) enemy_id = e.id;
    if (enemy_id == ENEMY_MINI_BOSS || enemy_id == ENEMY_FINAL_BOSS) {
        // R-022: a refused Run is still a spent turn, so the statuses tick like after any action (Battle_PlayerFinalizeTurn also advances the timeline).
        Battle_Message(_bc, Loc_T("combat.msg.player_cant_escape_this", "You can't run away from this."), BSTATE_ENEMY_ACT);
        Battle_PlayerFinalizeTurn(_bc, p, e);
        return;
    }

    if (RunRng_Float("combat") < Battle_RunChance(Combat_EffectiveStat(p, STAT_SPD), Combat_EffectiveStat(e, STAT_SPD), _bc.run_fails)) {
        Battle_EscapeResolve(e);
        Battle_Message(_bc, Loc_T("combat.msg.player_ran", "You ran away!"), BSTATE_END_RUN, noone, COMBAT_ACTION_DELAY_MS);
    } else {
        // R-022: a failed Run is a spent turn: message, then the same finaliser as Guard (Status_Tick, death/victory check, timeline advance).
        // A successful Run (above) ends the battle and clears every status in Battle_EndRun, so it does not tick.
        _bc.run_fails += 1;
        Battle_Message(_bc, Loc_T("combat.msg.player_couldnt_escape", "Couldn't escape!"), BSTATE_ENEMY_ACT);
        Battle_PlayerFinalizeTurn(_bc, p, e);
    }
}

// The player got away (Run, or a Perfect Smoke Bomb): the enemy stays on the map alive and keeps what it stole (hunt 6, I-072), and the Stranger's
// first-meeting line is queued the same way for both ways out.
function Battle_EscapeResolve(_e) {
    var stolen = (is_struct(_e) && variable_struct_exists(_e, "stolen_items") && is_array(_e.stolen_items)) ? _e.stolen_items : [];
    EnemyPersist_ResolveBattle(false, stolen);
    if (is_struct(_e) && variable_struct_exists(_e, "id") && _e.id == ENEMY_STRANGER) Dialogue_NarrativeOnStrangerEncounterResolved();
}

function Battle_EndRun(_bc) {
    _bc.battle_over = true;
    Display_ClearZoom();   // D139: no push-in is left over into the next room
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
    if (enemy_turn_finished) p = Status_TickEnemyTurn(p);   // hunt 6: Guard's Brace counts the enemy's turns, whether or not it hit
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
        SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, QTE_TELEGRAPH_MS, ENEMY_FLASH_MS, ENEMY_FLASH_RATE_MS);
    }
    _bc.battle_state = BSTATE_ENEMY_DEFENCE;
    Tutorial_Trigger("defence");   // D45
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
    RunStats_Qte(_key); RunStats_Taken(final_dmg);   // G9 (D137)
    if (final_dmg > 0 && _key != QTE_PERFECT) {
        CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_MS, PLAYER_SHAKE_DIR);
    }
    if (final_dmg > 0) {
        Battle_PlayerHitPop(_bc, final_dmg, crit);
        Battle_PlayerHurtFeel(_bc, final_dmg, p.max_hp, _key != QTE_PERFECT);   // a telegraphed move that gets through is a big hit
    }

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

// The left edge of a word _w wide centred on _cx, held inside the screen (_gw wide) with _margin to spare on each side. Pure.
function Qte_GradeWordLeft(_cx, _w, _gw, _margin) {
    var left = _cx - _w * 0.5;
    return clamp(left, _margin, max(_margin, _gw - _margin - _w));
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
    var tx = Qte_GradeWordLeft(_x, tw, Display_GuiW(), 4 * max(1, round(_unit)));   // R3 note 9: an enemy near a screen edge does not push the word off it
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

// Where the QTE widgets (the bar, the arrows) sit: centred, just under the enemy, kept above the bottom panels (D99). Returns the top y in GUI units.
function Battle_QteAnchorY(_bc, _widget_h) {
    var sx = Display_WorldScale();
    var z = Battle_Zones();
    var ay = round(Display_GuiH() * 0.72);
    if (instance_exists(_bc.enemy_inst) && _bc.enemy_inst.sprite_index != noone) {
        var spr = _bc.enemy_inst.sprite_index;
        var enemy_bottom = ((_bc.enemy_inst.y - sprite_get_yoffset(spr) - _bc.cam_base_y) * sx) + (sprite_get_height(spr) * abs(_bc.enemy_inst.image_yscale) * sx);
        ay = round(enemy_bottom + (8 * sx));
    }
    return min(ay, z.band_top - _widget_h - z.m);
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
        SpriteShake_Start(_bc.enemy_inst, ENEMY_SHAKE_DIR, ENEMY_SHAKE_MAG, QTE_TELEGRAPH_MS, ENEMY_FLASH_MS, ENEMY_FLASH_RATE_MS);
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
        CameraShake_Start(QTE_SHAKE_PERFECT_MAG, QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
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
            CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_MS, PLAYER_SHAKE_DIR);
            Battle_PlayerHitPop(_bc, res.dmg, res.crit);
            Battle_PlayerHurtFeel(_bc, res.dmg, p.max_hp, false);
            RunStats_Taken(res.dmg);   // G9 (D137)
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
            CameraShake_Start(PLAYER_SHAKE_MAG, PLAYER_SHAKE_MS, PLAYER_SHAKE_DIR);
            Battle_PlayerHitPop(_bc, _bc.last_dmg, _bc.last_crit);
            Battle_PlayerHurtFeel(_bc, _bc.last_dmg, p.max_hp, false);
            RunStats_Taken(_bc.last_dmg);   // G9 (D137)
        }

        var end_attack_pack = Battle_EnemyFinalizeTurnState(_bc, p, e);
        if (end_attack_pack.ended) return;
        p = end_attack_pack.player;
        e = end_attack_pack.enemy;

        var basic_msg = Battle_EnemySkillComposeMessage(e.name, { hit: _bc.last_hit, crit: _bc.last_crit, dmg: _bc.last_dmg, msg: "" });
        Battle_Message(_bc, basic_msg, follow_state);
    }
}

// ---- The battle HUD (D74 D75 D92 D97 D99 D100): turn strip, enemy header, player panel, log, banner and the command / skill / item menus ----
// GUI layer, the four palette colours only (UI_C_*), built on the Ui_* kit of D0 (Ui_Metrics, Ui_Box, Ui_DrawFrame, Ui_Text, Ui_Menu*, Ui_AnimT, Ui_Bob, Ui_Glide).
// Every size is a whole multiple of Ui_Px (one font pixel), so every edge lands on whole window pixels at every window size.
#macro TURN_SLIDE_MS 120
#macro LOG_TOAST_MS 2200

// One icon pixel in GUI units for chips and strip portraits: a whole multiple of the window pixel, so the 16 x 16 art stays crisp.
function Battle_IconK() {
    return max(1, round(Display_WorldScale() * 0.6));
}

// The screen in zones (pure; Test_Suite_BattleUi checks that nothing overlaps at every size). _tl_bottom = the turn strip's bottom edge,
// _icon = a status chip's icon edge. player = the HP / MP / status panel (bottom left); right = the column of the command menu and lists
// (bottom right, bottom edge list_bottom); msg = where the log toast and the skill banner's plate may sit (above both bottom panels).
// _lab_h (D150): the height of the label row under the chips (0 = none); the panel grows by it and one gap.
function BattleHud_Zones(_gw, _gh, _p, _lh, _tl_bottom, _icon, _lab_h = 0) {
    var m = 3 * _p;
    var row = _lh + 2 * _p;
    var pl_w = round(_gw * 0.40);
    var pl_h = 8 * _p + 3 * _lh + 6 * _p + _icon + ((_lab_h > 0) ? _lab_h + _p : 0);
    var cmd_h = 8 * _p + 5 * row;
    var band_h = max(pl_h, cmd_h);
    var band_top = _gh - m - band_h;
    var msg_h = 8 * _p + 2 * _lh + _p;
    var rx = m + pl_w + m;
    return {
        m: m, row: row, band_h: band_h, band_top: band_top, cmd_h: cmd_h,
        player: { x: m, y: band_top, w: pl_w, h: band_h },
        right: { x: rx, w: _gw - rx - m },
        list_bottom: _gh - m,
        msg: { x: m, y: band_top - 2 * _p - msg_h, w: _gw - 2 * m, h: msg_h }
    };
}

function Battle_Zones() {
    var mt = Ui_Metrics();
    return BattleHud_Zones(mt.gw, mt.gh, mt.p, mt.line_h, Battle_TimelineBottom(), 16 * Battle_IconK(), Battle_ChipLabelH());
}

// ---- 3 x 5 digits and a plus sign for the chips (retro-ui.md section 3). Every cell is _p x _p. ----
function Battle_GlyphRows(_ch) {
    switch (string_upper(_ch)) {
        case "0": return [7, 5, 5, 5, 7];
        case "1": return [2, 6, 2, 2, 7];
        case "2": return [7, 1, 7, 4, 7];
        case "3": return [7, 1, 7, 1, 7];
        case "4": return [5, 5, 7, 1, 1];
        case "5": return [7, 4, 7, 1, 7];
        case "6": return [7, 4, 7, 5, 7];
        case "7": return [7, 1, 1, 2, 2];
        case "8": return [7, 5, 7, 5, 7];
        case "9": return [7, 5, 7, 1, 7];
        case "+": return [0, 2, 7, 2, 0];
        // D150: the letters of the short status names, in the same 3 x 5 cells
        case "A": return [2, 5, 7, 5, 5];
        case "B": return [6, 5, 6, 5, 6];
        case "C": return [3, 4, 4, 4, 3];
        case "D": return [6, 5, 5, 5, 6];
        case "E": return [7, 4, 6, 4, 7];
        case "F": return [7, 4, 6, 4, 4];
        case "G": return [3, 4, 5, 5, 3];
        case "H": return [5, 5, 7, 5, 5];
        case "I": return [7, 2, 2, 2, 7];
        case "J": return [1, 1, 1, 5, 2];
        case "K": return [5, 5, 6, 5, 5];
        case "L": return [4, 4, 4, 4, 7];
        case "M": return [5, 7, 7, 5, 5];
        case "N": return [6, 5, 5, 5, 5];
        case "O": return [2, 5, 5, 5, 2];
        case "P": return [6, 5, 6, 4, 4];
        case "Q": return [2, 5, 5, 3, 1];
        case "R": return [6, 5, 6, 5, 5];
        case "S": return [3, 4, 2, 1, 6];
        case "T": return [7, 2, 2, 2, 2];
        case "U": return [5, 5, 5, 5, 7];
        case "V": return [5, 5, 5, 5, 2];
        case "W": return [5, 5, 7, 7, 5];
        case "X": return [5, 5, 2, 5, 5];
        case "Y": return [5, 5, 2, 2, 2];
        case "Z": return [7, 1, 2, 4, 7];
    }
    return [0, 0, 0, 0, 0];
}

function Battle_DigitsWidth(_text, _p) {
    var n = string_length(_text);
    return (n <= 0) ? 0 : (n * 3 + (n - 1)) * _p;
}

function Battle_DrawDigits(_x, _y, _text, _p, _col) {
    for (var i = 1; i <= string_length(_text); i++) {
        var rows = Battle_GlyphRows(string_char_at(_text, i));
        var gx = _x + (i - 1) * 4 * _p;
        for (var r = 0; r < 5; r++) {
            for (var c = 0; c < 3; c++) {
                if (((rows[r] >> (2 - c)) & 1) == 1) Ui_Box(gx + c * _p, _y + r * _p, gx + (c + 1) * _p, _y + (r + 1) * _p, _col);
            }
        }
    }
}

// ---- status chips (D99): what a fighter is under, with the number the player needs ----
// { id, frame (the strip frame of art/strips_v2/status), text (turns left, or a poison's stacks), corner (the stacks of a bleed), negative, name, line, last (1 turn left),
//   label ("PSN 3"), lab_name / lab_count (its two parts, D150), full (the highlighted sentence with the turns left) }
function Battle_StatusChips(_ch) {
    var out = [];
    var list = Status_DisplayList(_ch);
    for (var i = 0; i < array_length(list); i++) {
        var d = list[i];
        var cfg = StatusDB_Get(d.id);
        var dot = variable_struct_exists(cfg, "dot_kind") ? cfg.dot_kind : "";
        array_push(out, {
            id: d.id, frame: Icon_StatusFrame(d.id),
            text: (d.turns > 0) ? string(d.turns) : "",
            corner: (dot == "bleed" && d.stacks > 1) ? string(d.stacks) : "",
            negative: d.negative, name: d.name, line: d.line, last: (d.turns == 1 && dot != "poison"),
            label: d.short + ((d.count != "") ? " " + d.count : ""), lab_name: d.short, lab_count: d.count, full: d.full
        });
    }
    return out;
}

// Chips for the HUD: the real statuses, then Steadfast (turns left) and BREAK, which live on the turn timeline and the stagger meter.
function Battle_FighterChips(_bc, _who) {
    var fr = Battle_HudFrame();
    if (is_struct(fr)) {   // inside a Draw GUI frame: built once per fighter
        if (!is_array(fr.chips[_who])) fr.chips[_who] = Battle_FighterChipsBuild(_bc, _who);
        return fr.chips[_who];
    }
    return Battle_FighterChipsBuild(_bc, _who);
}

function Battle_FighterChipsBuild(_bc, _who) {
    if (_who == TL_PLAYER) Battle_HudBuilds().chips_player++; else Battle_HudBuilds().chips_enemy++;
    var ch = (_who == TL_PLAYER) ? _bc.p : _bc.e;
    var chips = Battle_StatusChips(ch);
    var f = Turn_Find(_bc.tl, _who);
    if (is_struct(f) && f.steadfast > 0) {
        var sf_name = Loc_T("battle.chip.steadfast.short", "Steady");
        array_push(chips, { id: -2, frame: Icon_Frame("status", "steadfast"), text: string(f.steadfast), corner: "", negative: false, last: (f.steadfast == 1),
                            name: Loc_T("battle.chip.steadfast", "Steadfast"), line: Loc_T("battle.chip.steadfast.line", "Cannot be stunned."),
                            label: sf_name + " " + string(f.steadfast), lab_name: sf_name, lab_count: string(f.steadfast),
                            full: Loc_T("battle.chip.steadfast.line", "Cannot be stunned.") });
    }
    if (_who == TL_ENEMY && variable_struct_exists(ch, "broken") && ch.broken) {
        var bk_name = Loc_T("battle.chip.break.short", "BREAK");
        array_push(chips, { id: -3, frame: Icon_Frame("status", "break"), text: "", corner: "", negative: true, last: false,
                            name: Loc_T("battle.hud.break", "BREAK!"), line: Loc_T("battle.chip.break.line", "Takes +50% damage until its next turn."),
                            label: bk_name, lab_name: bk_name, lab_count: "", full: Loc_T("battle.chip.break.line", "Takes +50% damage until its next turn.") });
    }
    var k = Battle_IconK();
    for (var ci = 0; ci < array_length(chips); ci++) chips[ci].lw = Battle_ChipLabelW(chips[ci].lab_name, chips[ci].lab_count, k);   // D150: how wide each label is, for the row
    return chips;
}

// D150: the label under a chip is the short name and its count in 3 x 5 glyphs of _q window pixels (4 cells a character, the space included).
// A name that is not plain letters (Korean) is drawn in the UI font, then a gap, then the count in glyphs.
function Battle_LabelIsMini(_name) {
    for (var i = 1; i <= string_length(_name); i++) {
        var o = ord(string_upper(string_char_at(_name, i)));
        if (!((o >= 65 && o <= 90) || (o >= 48 && o <= 57) || o == 32)) return false;
    }
    return true;
}

function Battle_ChipLabelW(_name, _count, _q) {
    if (Battle_LabelIsMini(_name)) return Battle_DigitsWidth(_name + ((_count != "") ? " " + _count : ""), _q);
    return UI_TextWidth(_name) + ((_count != "") ? 4 * _q + Battle_DigitsWidth(_count, _q) : 0);
}

// The height of the label row: 5 glyph rows in English, a text line in Korean.
function Battle_ChipLabelH() {
    return (Loc_GetLanguage() == "ko") ? Ui_Metrics().line_h : 5 * Battle_IconK();
}

// The width each chip's cell must hold: its label and two glyph cells of air, so neighbouring labels never run together.
function Battle_ChipLws(_chips) {
    var out = [];
    var pad = 2 * Battle_IconK();
    for (var i = 0; i < array_length(_chips); i++) array_push(out, variable_struct_exists(_chips[i], "lw") ? _chips[i].lw + pad : 0);
    return out;
}

// Width of a row of chips, and how many fit in _max_w (the rest become one plus-count chip). _lws (D150): the width of each label; a chip's cell is
// the wider of the chip and its label. cells: the width of each cell.
function Battle_ChipMetrics(_n, _ic, _p, _max_w, _lws = undefined) {
    var c = _ic + 2 * _p;
    var cells = array_create(max(0, _n), c);
    if (is_array(_lws)) {
        for (var i = 0; i < _n && i < array_length(_lws); i++) cells[i] = max(c, _lws[i]);
    }
    var total = 0;
    for (var t = 0; t < _n; t++) total += cells[t] + ((t > 0) ? _p : 0);
    var shown = max(0, _n);
    if (total > _max_w && _n > 0) {   // leave room for the plus chip; R3 (R-093): a chip that does not fit is counted in the plus chip, never drawn cut
        shown = 0;
        var run = 0;
        for (var j = 0; j < _n; j++) {
            var nw = run + ((j > 0) ? _p : 0) + cells[j];
            if (nw + _p + c > _max_w) break;
            run = nw;
            shown++;
        }
    }
    var w = 0;
    for (var s = 0; s < shown; s++) w += cells[s] + ((s > 0) ? _p : 0);
    var more = max(0, _n) - shown;
    if (more > 0) w += ((shown > 0) ? _p : 0) + c;
    return { c: c, shown: shown, more: more, w: w, cells: cells };
}

// D150: where each chip and its label were drawn this frame (for the tip and the tests): { who, idx, x, y, w, h, chip }.
function Battle_ChipRectAdd(_who, _idx, _x, _y, _w, _h, _chip) {
    var fr = Battle_HudFrame();
    if (!is_struct(fr)) return;
    array_push(fr.chip_rects, { who: _who, idx: _idx, x: _x, y: _y, w: _w, h: _h, chip: _chip });
}

// The label, centred on _cx: the glyph name and count (white-green for a debuff, mid green for a buff); blinks light while 1 turn is left.
function Battle_DrawChipLabel(_cx, _y, _ch, _q, _lab_h) {
    var w = _ch.lw;
    var lx = round(_cx - w * 0.5);
    var gy = _y + (_lab_h - 5 * _q) div 2;
    var col = Battle_ChipBlink(_ch.last, _ch.negative, current_time).label_col;   // R3 (note 8): the last turn toggles the text colour, no filled box
    if (Battle_LabelIsMini(_ch.lab_name)) {
        Battle_DrawDigits(lx, gy, string_upper(_ch.lab_name) + ((_ch.lab_count != "") ? " " + _ch.lab_count : ""), _q, col);
    } else {
        Ui_Text(lx, _y + (_lab_h - Ui_Metrics().line_h) div 2, _ch.lab_name, col);
        if (_ch.lab_count != "") Battle_DrawDigits(lx + UI_TextWidth(_ch.lab_name) + 4 * _q, gy, _ch.lab_count, _q, col);
    }
}

// Draws the row; returns its width. _align: fa_left (x = left edge), fa_center, fa_right (x = right edge). D150: each chip has its label under it
// (short name and count, which replace the number badge); _who (TL_PLAYER / TL_ENEMY) tags the rectangles kept for the tip.
function Battle_DrawChips(_chips, _x, _y, _ic, _p, _max_w, _alpha, _align = fa_left, _who = -1) {
    var n = array_length(_chips);
    if (n <= 0) return 0;
    var cm = Battle_ChipMetrics(n, _ic, _p, _max_w, Battle_ChipLws(_chips));
    var x0 = _x;
    if (_align == fa_center) x0 = _x - cm.w * 0.5;
    else if (_align == fa_right) x0 = _x - cm.w;
    x0 = round(x0);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var k = _ic div 16;
    var lab_h = Battle_ChipLabelH();
    var cell_x = x0;
    for (var i = 0; i < cm.shown; i++) {
        var ch = _chips[i];
        var cell = cm.cells[i];
        var cx = cell_x + (cell - cm.c) div 2;
        Ui_Box(cx, _y, cx + cm.c, _y + cm.c, ch.negative ? UI_C_LIGHT : UI_C_DARK);
        Ui_Box(cx + _p, _y + _p, cx + cm.c - _p, _y + cm.c - _p, UI_C_DARKEST);
        if (Battle_ChipBlink(ch.last, ch.negative, current_time).outline) {   // R3 (note 8): the last turn, a 1p lightest outline round the icon cell, on / off every 250 ms
            Ui_Box(cx - _p, _y - _p, cx + cm.c + _p, _y, UI_C_LIGHTEST);
            Ui_Box(cx - _p, _y + cm.c, cx + cm.c + _p, _y + cm.c + _p, UI_C_LIGHTEST);
            Ui_Box(cx - _p, _y, cx, _y + cm.c, UI_C_LIGHTEST);
            Ui_Box(cx + cm.c, _y, cx + cm.c + _p, _y + cm.c, UI_C_LIGHTEST);
        }
        if (ch.frame >= 0) Icon_Draw("status", ch.frame, cx + _p, _y + _p, k, _alpha);
        else Ui_Text(cx + cm.c * 0.5, _y + (cm.c - UI_TextHeight("A")) * 0.5, string_upper(string_copy(ch.name, 1, 1)), UI_C_LIGHTEST, fa_center);
        if (variable_struct_exists(ch, "lab_name") && ch.lab_name != "") Battle_DrawChipLabel(cell_x + cell * 0.5, _y + cm.c + _p, ch, k, lab_h);
        Battle_ChipRectAdd(_who, i, cell_x, _y, cell, cm.c + _p + lab_h, ch);
        cell_x += cell + _p;
    }
    if (cm.more > 0) {
        Ui_Box(cell_x, _y, cell_x + cm.c, _y + cm.c, UI_C_DARK);
        Ui_Box(cell_x + _p, _y + _p, cell_x + cm.c - _p, _y + cm.c - _p, UI_C_DARKEST);
        var mt2 = "+" + string(cm.more);
        Battle_DrawDigits(cell_x + (cm.c - Battle_DigitsWidth(mt2, _p)) div 2, _y + (cm.c - 5 * _p) div 2, mt2, _p, UI_C_LIGHTEST);
    }
    draw_set_alpha(a0);
    return cm.w;
}

// D150: the chip under the mouse (or the one a scenario asks for with hud.chip_focus = { who, idx }) gets its full sentence in a small plate.
function Battle_ChipFocus(_bc) {
    var fr = Battle_HudFrame();
    if (!is_struct(fr)) return undefined;
    var rs = fr.chip_rects;
    if (variable_struct_exists(_bc.hud, "chip_focus") && is_struct(_bc.hud.chip_focus)) {
        var f = _bc.hud.chip_focus;
        for (var i = 0; i < array_length(rs); i++) if (rs[i].who == f.who && rs[i].idx == f.idx) return rs[i];
        return undefined;
    }
    var mp = Ui_MousePos();
    for (var j = 0; j < array_length(rs); j++) {
        if (mp.x >= rs[j].x && mp.x < rs[j].x + rs[j].w && mp.y >= rs[j].y && mp.y < rs[j].y + rs[j].h) return rs[j];
    }
    return undefined;
}

function Battle_DrawChipTip(_bc) {
    _bc.hud.rects.chip_tip = undefined;
    if (_bc.battle_state == BSTATE_ATTACK_TIMING || _bc.battle_state == BSTATE_SKILL_QTE || _bc.battle_state == BSTATE_ENEMY_DEFENCE) return;
    if (GameState_Get().ui.mode == UI_MENU) return;
    var fr = Battle_ChipFocus(_bc);
    if (!is_struct(fr)) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var chip = fr.chip;
    var inner = min(mt.gw - 2 * mt.margin, round(mt.gw * 0.7)) - 8 * p;
    var body = Battle_LogWrap(string(chip.full), inner);
    var w = UI_TextWidth(chip.name);
    for (var i = 0; i < array_length(body); i++) w = max(w, UI_TextWidth(body[i]));
    w += 8 * p;
    var h = 8 * p + mt.line_h * (1 + array_length(body)) + p * array_length(body);
    var tx = clamp(round(fr.x + fr.w * 0.5 - w * 0.5), mt.margin, mt.gw - mt.margin - w);
    var ty = fr.y + fr.h + 2 * p;
    if (ty + h > mt.gh - mt.margin) ty = fr.y - h - 2 * p;
    ty = max(mt.margin, ty);
    var a0 = draw_get_alpha();
    draw_set_alpha(1);
    var o = p;   // the highlighted chip: a bright outline around its cell
    Ui_Box(fr.x - o, fr.y - o, fr.x + fr.w + o, fr.y, UI_C_LIGHTEST);
    Ui_Box(fr.x - o, fr.y + fr.h, fr.x + fr.w + o, fr.y + fr.h + o, UI_C_LIGHTEST);
    Ui_Box(fr.x - o, fr.y, fr.x, fr.y + fr.h, UI_C_LIGHTEST);
    Ui_Box(fr.x + fr.w, fr.y, fr.x + fr.w + o, fr.y + fr.h, UI_C_LIGHTEST);
    Ui_DrawFrame(tx, ty, w, h, 1, p);
    Ui_Text(tx + 4 * p, ty + 4 * p, chip.name, UI_C_LIGHTEST);
    for (var j = 0; j < array_length(body); j++) Ui_Text(tx + 4 * p, ty + 4 * p + (j + 1) * (mt.line_h + p), body[j], UI_C_LIGHT);
    draw_set_alpha(a0);
    _bc.hud.rects.chip_tip = { x: tx, y: ty, w: w, h: h };
}

// ---- details (D100): one plain sentence and the exact numbers, generated from the real data ----
// _pv (D135): the skill damage preview against the current enemy (Battle_SkillPreview), or undefined (no enemy, or a skill that deals no damage).
function Battle_SkillDetails(_skill, _cost = -1, _pv = undefined) {
    var lines = [];
    var sentence = Card_SkillSentence(_skill);
    if (_skill.effect == "damage") {
        var pv_lines = Battle_PreviewLines(_pv);   // D135: what the hit does now, first (the two numbers share a row of the two-column panel)
        for (var pli = 0; pli < array_length(pv_lines); pli++) array_push(lines, pv_lines[pli]);
        array_push(lines, { label: Loc_T("card.lbl.power", "Power"), value: string(round(_skill.power)) });
        if (variable_struct_exists(_skill, "hits") && _skill.hits > 1) array_push(lines, { label: Loc_T("battle.det.hits", "Hits"), value: string(round(_skill.hits)) });
    }
    array_push(lines, { label: Loc_T("card.lbl.mp", "MP"), value: string((_cost >= 0) ? _cost : round(_skill.mp_cost)) });
    if (_skill.status != -1) {
        var poison = (_skill.status == STATUS_POISON);
        if (poison && variable_struct_exists(_skill, "status_stacks")) array_push(lines, { label: Loc_T("card.lbl.stacks", "Stacks"), value: string(round(_skill.status_stacks)) });
        else array_push(lines, { label: Loc_T("card.lbl.turns", "Turns"), value: string(round(_skill.status_turns)) });
        if (_skill.effect == "damage" && _skill.status_chance < 1) array_push(lines, { label: Loc_T("card.lbl.chance", "Chance"), value: string(round(_skill.status_chance * 100)) + "%" });
    }
    return { sentence: sentence, lines: lines };
}

function Battle_ItemDetails(_item, _user) {
    if (Item_IsThrowable(_item)) return { sentence: Item_Sentence(_item), lines: Item_NumberLines(_item, _user) };   // C3 (D84): written next to the item data
    var lines = [];
    var sentence = Loc_T("battle.item.other", "A useful item.");
    if (_item.type == ITEM_CONSUMABLE && variable_struct_exists(_item, "use") && is_struct(_item.use)) {
        var use = _item.use;
        switch (use.effect) {
            case "heal":
                sentence = Loc_T("battle.item.heal", "Restores your HP.");
                array_push(lines, { label: Loc_T("battle.det.hp", "HP"), value: string(Item_ComputeAmount(_user, use)) });   // D126: one exact number
                break;
            case "mp":
                sentence = Loc_T("battle.item.mp", "Restores your MP.");
                array_push(lines, { label: Loc_T("battle.det.mp", "MP"), value: string(Item_ComputeAmount(_user, use)) });
                break;
            case "cure":
                sentence = Loc_T("battle.item.cure", "Cures {status}.", { status: Card_StatusNameSafe(use.status) });
                break;
        }
    }
    return { sentence: sentence, lines: lines };
}

// ---- the lists (D99): one row per skill / item, as Ui_Menu items ----
// _e (D135): the current enemy; with it a damaging skill's details show the expected damage against it at OK and at Perfect.
function Battle_SkillRows(_p, _e = undefined) {
    var out = [];
    var ids = is_array(_p.skills) ? _p.skills : [];
    for (var i = 0; i < array_length(ids); i++) {
        var sk = SkillDB_Get(ids[i]);
        var cost = Equip_PlayerSkillMPCost(_p, sk, sk.mp_cost);
        var det = Battle_SkillDetails(sk, cost, is_struct(_e) ? Battle_SkillPreview(_p, _e, ids[i]) : undefined);
        var fr = Icon_SkillFrame(ids[i]);
        array_push(out, {
            label: sk.name, value: Loc_T("battle.menu.mp", "{mp} MP", { mp: string(cost) }), skill_id: ids[i], cost: cost, seq: Qte_SkillSequence(ids[i]),
            dim: (_p.mp < cost), help: det.sentence, lines: det.lines, icon: (fr >= 0) ? { cat: "skill", frame: fr } : undefined, enabled: true
        });
    }
    return out;
}

// The battle's consumables, as inventory entries { id, qty } (one place for the rule; the menu and the bot read it).
function Battle_ItemList(_p) {
    var out = [];
    if (!is_array(_p.inventory)) return out;
    for (var i = 0; i < array_length(_p.inventory); i++) {
        var inv = _p.inventory[i];
        var item = ItemDB_Get(inv.id);
        if (item.type == ITEM_CONSUMABLE && variable_struct_exists(item, "usable_battle") && item.usable_battle) array_push(out, inv);
    }
    return out;
}

function Battle_ItemRows(_p) {
    var out = [];
    var list = Battle_ItemList(_p);
    for (var i = 0; i < array_length(list); i++) {
        var item = ItemDB_Get(list[i].id);
        var det = Battle_ItemDetails(item, _p);
        array_push(out, {
            label: item.name, value: "x" + string(list[i].qty), item_id: list[i].id, qty: list[i].qty, help: det.sentence, lines: det.lines,
            icon_item: item, enabled: true
        });
    }
    return out;
}

// ---- the Guard command (D99): the turn is spent, the next hit deals half ----
function Battle_GuardApply(_p) {
    return Status_Add(_p, STATUS_BRACE, Status_Cfg(STATUS_BRACE, "duration", 2), 0);
}

function Battle_PlayerGuard(_bc) {
    var p = Battle_GuardApply(_bc.p);
    SFX_PlaySkill(SKILL_MUSCLE_UP);
    Battle_Message(_bc, Loc_T("combat.msg.guard", "You brace yourself."), BSTATE_ENEMY_ACT);
    Battle_PlayerFinalizeTurn(_bc, p, _bc.e);
}

// ---- the menus: Ui_Menu objects the controller owns; the cursor and the open animation live there ----
// R1b (D124): with the battle (_bc) the RUN row shows the flee chance now, e.g. "53%", or "no" against a boss.
function Battle_CmdItems(_bc = undefined) {
    var run_val = "";
    if (!is_undefined(_bc) && variable_instance_exists(_bc, "p") && variable_instance_exists(_bc, "e")) {   // the battle controller (an instance) or a struct that looks like it
        var pct = Battle_RunPct(_bc.p, _bc.e, variable_instance_exists(_bc, "run_fails") ? _bc.run_fails : 0);
        run_val = (pct < 0) ? Loc_T("battle.action.run_no", "No") : string(pct) + "%";
    }
    return [
        { id: "attack", label: Loc_T("battle.action.attack", "Attack"), enabled: true },
        { id: "skill", label: Loc_T("battle.action.skill", "Skill"), enabled: true },
        { id: "item", label: Loc_T("battle.action.item", "Item"), enabled: true },
        { id: "guard", label: Loc_T("battle.action.guard", "Guard"), enabled: true },
        { id: "run", label: Loc_T("battle.action.run", "Run"), value: run_val, enabled: true }
    ];
}

function Battle_CmdConfirm(_m, _i) {
    var bc = _m.owner;
    switch (_m.items[_i].id) {
        case "attack": Battle_AttackTimingBegin(bc); break;
        case "skill":
            if (array_length(Battle_GetSkillList(bc)) <= 0) Battle_Message(bc, Loc_T("battle.menu.no_skills", "No skills available."), BSTATE_MENU);
            else Battle_OpenList(bc, BSTATE_SKILL_MENU);
            break;
        case "item":
            if (array_length(Battle_GetItemList(bc)) <= 0) Battle_Message(bc, Loc_T("battle.menu.no_items", "No items available."), BSTATE_MENU);
            else Battle_OpenList(bc, BSTATE_ITEM_MENU);
            break;
        case "guard": Battle_PlayerGuard(bc); break;
        case "run": bc.battle_state = BSTATE_PLAYER_RUN; break;
    }
}

// D133: a row that cannot be used answers with the refusal sound: a skill the player cannot pay for (the row is dimmed), Skill or Item with nothing in the list.
function Battle_MenuRefuse(_m, _i) {
    if (_i < 0 || _i >= array_length(_m.items)) return false;
    var it = _m.items[_i];
    if (variable_struct_exists(it, "dim") && it.dim) return true;
    if (variable_struct_exists(it, "id")) {
        if (it.id == "skill") return array_length(Battle_GetSkillList(_m.owner)) <= 0;
        if (it.id == "item") return array_length(Battle_GetItemList(_m.owner)) <= 0;
    }
    return false;
}

function Battle_SkillConfirm(_m, _i) {
    Battle_SkillQteBegin(_m.owner, _m.items[_i].skill_id);
}

function Battle_ItemConfirm(_m, _i) {
    Battle_PlayerItem(_m.owner, _m.items[_i].item_id);
}

function Battle_ListBack(_m, _res) {
    var bc = _m.owner;
    bc.battle_state = BSTATE_MENU;
    if (is_struct(bc.ui_cmd)) { bc.ui_cmd.opened_ms = current_time; bc.ui_cmd.lock_ms = current_time; }
}

// Builds (or rebuilds) the three menus. The lists keep their cursor through Ui_MemGlobal (D95).
function Battle_MenusBuild(_bc) {
    var z = Battle_Zones();
    _bc.ui_cmd = Ui_MenuNew("battle_cmd", Battle_CmdItems(_bc), {
        owner: _bc, on_confirm: Battle_CmdConfirm, refuse: Battle_MenuRefuse,
        layout: { x_anchor: "right", panel_w: round(z.right.w * 0.5), y_bottom: z.list_bottom }
    });
    _bc.ui_skill = Ui_MenuNew("battle_skill", Battle_SkillRows(_bc.p, _bc.e), {
        owner: _bc, on_confirm: Battle_SkillConfirm, refuse: Battle_MenuRefuse, on_back: Battle_ListBack,
        layout: { x_anchor: "right", panel_w: z.right.w, y_bottom: z.list_bottom, details: true, details_pos: "above", details_cols: 2, rows_max: 3 }
    });
    _bc.ui_item = Ui_MenuNew("battle_item", Battle_ItemRows(_bc.p), {
        owner: _bc, on_confirm: Battle_ItemConfirm, on_back: Battle_ListBack,
        layout: { x_anchor: "right", panel_w: z.right.w, y_bottom: z.list_bottom, details: true, details_pos: "above", details_cols: 2, rows_max: 3 }
    });
    _bc.ui_sig = { mp: _bc.p.mp, items: Battle_ItemSig(_bc.p), rev: Loc_GetRevision(), run: Battle_RunPct(_bc.p, _bc.e, _bc.run_fails), pv: Battle_SkillPreviewSig(_bc.p, _bc.e) };
}

// H13b (D156): the panel width the command menu needs so that no label is cut: the widest label (RUN with its chance, worst case "100%"), the marker column
// and the inset. The menu is half the right column unless that is too little. Pure.
function Battle_CmdNeed(_mt) {
    var rows = Battle_CmdItems();
    var w = 0;
    for (var i = 0; i < array_length(rows); i++) {
        w = max(w, UI_TextWidth(rows[i].label) + ((rows[i].id == "run") ? UI_TextWidth("100%") + 3 * _mt.p : 0));
    }
    return w + 13 * _mt.p;
}

function Battle_CmdPanelW(_z, _mt) {
    return min(max(round(_z.right.w * 0.5), Battle_CmdNeed(_mt)), _z.right.w);
}

// The menus' place follows the window (the zones change with the size): set every frame before a menu is stepped or drawn.
function Battle_MenusLayout(_bc) {
    var z = Battle_Zones();
    _bc.ui_cmd.layout.panel_w = Battle_CmdPanelW(z, Ui_Metrics());
    _bc.ui_cmd.layout.y_bottom = z.list_bottom;
    _bc.ui_skill.layout.panel_w = z.right.w;
    _bc.ui_skill.layout.y_bottom = z.list_bottom;
    _bc.ui_item.layout.panel_w = z.right.w;
    _bc.ui_item.layout.y_bottom = z.list_bottom;
    // G10 (D129): the details panel stands above the list and grows upward; it stops just under the enemy (the list and the panel give way, Ui_MenuDraw)
    var er = Battle_EnemyRect(_bc);
    var floor_y = (er.w > 0 && er.h > 0) ? er.y + er.h + Ui_Px() : -1;
    _bc.ui_skill.layout.det_floor_y = floor_y;
    _bc.ui_item.layout.det_floor_y = floor_y;
}

function Battle_ItemSig(_p) {
    var s = "";
    var list = Battle_ItemList(_p);
    for (var i = 0; i < array_length(list); i++) s += string(list[i].id) + ":" + string(list[i].qty) + ",";
    return s;
}

// Opens a list: fresh rows (MP and quantities moved on), the open animation restarts, the cursor comes back from memory.
function Battle_OpenList(_bc, _state) {
    _bc.battle_state = _state;
    var m = (_state == BSTATE_SKILL_MENU) ? _bc.ui_skill : _bc.ui_item;
    m.items = (_state == BSTATE_SKILL_MENU) ? Battle_SkillRows(_bc.p, _bc.e) : Battle_ItemRows(_bc.p);
    m.opened_ms = current_time;
    m.lock_ms = current_time;   // C4: the press that opened the list must not answer it
    m.closed_ms = -1;
    Ui_MenuFixCursor(m, Ui_MemGet(Ui_MemGlobal(), m.id, array_length(m.items)));
    m.rep_v = Ui_RepeatNew();
}

// One frame of whichever menu is up. Keeps the rows in step with the fight (MP spent, items used, language changed).
function Battle_MenusStep(_bc) {
    if (!is_struct(_bc.ui_cmd)) Battle_MenusBuild(_bc);
    var sig = { mp: _bc.p.mp, items: Battle_ItemSig(_bc.p), rev: Loc_GetRevision(), run: Battle_RunPct(_bc.p, _bc.e, _bc.run_fails), pv: Battle_SkillPreviewSig(_bc.p, _bc.e) };   // the RUN chance moves with SPD and failed tries; the damage preview with the enemy
    if (sig.mp != _bc.ui_sig.mp || sig.items != _bc.ui_sig.items || sig.rev != _bc.ui_sig.rev || sig.run != _bc.ui_sig.run || sig.pv != _bc.ui_sig.pv) {
        var c1 = _bc.ui_cmd.cursor, c2 = _bc.ui_skill.cursor, c3 = _bc.ui_item.cursor;
        var t1 = _bc.ui_cmd.opened_ms, t2 = _bc.ui_skill.opened_ms, t3 = _bc.ui_item.opened_ms;
        var l1 = _bc.ui_cmd.lock_ms, l2 = _bc.ui_skill.lock_ms, l3 = _bc.ui_item.lock_ms;   // C4's confirm / back guard must not restart: a press just after a rebuild would be lost
        Battle_MenusBuild(_bc);
        _bc.ui_cmd.lock_ms = l1;
        _bc.ui_skill.lock_ms = l2;
        _bc.ui_item.lock_ms = l3;
        Ui_MenuFixCursor(_bc.ui_cmd, c1);
        Ui_MenuFixCursor(_bc.ui_skill, c2);
        Ui_MenuFixCursor(_bc.ui_item, c3);
        _bc.ui_cmd.opened_ms = t1;
        _bc.ui_skill.opened_ms = t2;
        _bc.ui_item.opened_ms = t3;
    }
    Battle_MenusLayout(_bc);
    switch (_bc.battle_state) {
        case BSTATE_MENU:
            Ui_MenuUpdate(_bc.ui_cmd);
            _bc.menu_index = _bc.ui_cmd.cursor;   // the bot and the tests read the command cursor here
            break;
        case BSTATE_SKILL_MENU:
            if (array_length(_bc.ui_skill.items) <= 0) { Battle_Message(_bc, Loc_T("battle.menu.no_skills", "No skills available."), BSTATE_MENU); break; }
            _bc.skill_index = _bc.ui_skill.cursor;
            Ui_MenuUpdate(_bc.ui_skill);
            if (_bc.battle_state == BSTATE_SKILL_MENU) _bc.skill_index = _bc.ui_skill.cursor;
            break;
        case BSTATE_ITEM_MENU:
            if (array_length(_bc.ui_item.items) <= 0) { Battle_Message(_bc, Loc_T("battle.menu.no_items", "No items available."), BSTATE_MENU); break; }
            Ui_MenuUpdate(_bc.ui_item);
            if (_bc.battle_state == BSTATE_ITEM_MENU) _bc.item_index = _bc.ui_item.cursor;
            break;
    }
}

// D156: the hint labels a battle state draws, each { action, text } (the text has its [k:action] button). One prompt line, for the action that is
// current: the skill and item lists say what the confirm button does (Back is Esc / B everywhere, so it is not repeated); the command menu and the
// bars draw none (a bar is taught by its first-time pop-up). Before D156 the lists drew two labels (Choose, Back).
function Battle_HintLabels(_state) {
    if (_state == BSTATE_SKILL_MENU || _state == BSTATE_ITEM_MENU) return [{ action: "confirm", text: Loc_T("battle.hint.list", "[k:confirm] Choose") }];
    return [];
}

// The prompt line of a list (C4's glyphs: the keyboard key or the pad button of the device in use), right-aligned just above the details panel.
function Battle_DrawListHint(_m, _state) {
    if (_m.det_rect.w <= 0) return;
    var hints = Battle_HintLabels(_state);
    if (array_length(hints) == 0) return;
    var mt = Ui_Metrics();
    var txt = hints[0].text;
    var lay = Prompt_RichLayout(txt, _m.det_rect.w);
    Prompt_RichDraw(_m.det_rect.x + _m.det_rect.w - lay.line_w[0] - mt.p, _m.det_rect.y - lay.h - mt.p, txt, _m.det_rect.w, UI_C_LIGHT, fa_left, Ui_MenuAlpha(_m, current_time));
}

function Battle_DrawMenus(_bc) {
    if (!is_struct(_bc.ui_cmd)) return;
    var now = current_time;
    switch (_bc.battle_state) {
        case BSTATE_MENU:
            if (_bc.turn == TURN_PLAYER) {
                var cmd_a = Ui_MenuAlpha(_bc.ui_cmd, now);
                Ui_MenuDraw(_bc.ui_cmd, cmd_a);
                if (cmd_a > 0) Battle_DrawAttackPreview(_bc, cmd_a);   // D135: the damage against this enemy, while the cursor is on ATTACK
            }
            break;
        case BSTATE_SKILL_MENU: Ui_MenuDraw(_bc.ui_skill, Ui_MenuAlpha(_bc.ui_skill, now)); Battle_DrawListHint(_bc.ui_skill, BSTATE_SKILL_MENU); break;
        case BSTATE_ITEM_MENU: Ui_MenuDraw(_bc.ui_item, Ui_MenuAlpha(_bc.ui_item, now)); Battle_DrawListHint(_bc.ui_item, BSTATE_ITEM_MENU); break;
    }
}

// ---- per-frame HUD data (D108 F1d-1) ----
// How many times the battle HUD data was really built (the tests assert one build per Draw GUI frame). Counted in the builders below.
function Battle_HudBuilds() {
    if (!variable_global_exists("battle_hud_builds")) global.battle_hud_builds = { metrics: 0, header: 0, chips_player: 0, chips_enemy: 0 };
    return global.battle_hud_builds;
}

function Battle_HudBuildsReset() {
    global.battle_hud_builds = { metrics: 0, header: 0, chips_player: 0, chips_enemy: 0 };
}

// One Draw GUI frame of the battle controller is bracketed by Battle_HudFrameBegin / Battle_HudFrameEnd (obj_battle_controller Draw_64). Inside the
// bracket the timeline metrics, the enemy header rect and each fighter's chips are built on first use and shared by every later caller of that
// frame: nothing they read (HP, statuses, layout, the enemy's place) changes while one Draw GUI event runs. Outside a bracket (Step code, the
// scenarios, the tests) every call builds from the live data, as before.
function Battle_HudFrameBegin(_bc) {
    global.battle_hud_frame = { bc: _bc, tm: undefined, hdr: undefined, chips: [undefined, undefined], chip_rects: [] };   // chips[TL_PLAYER], chips[TL_ENEMY]; chip_rects: D150
}

function Battle_HudFrameEnd() {
    global.battle_hud_frame = undefined;
}

function Battle_HudFrame() {
    return variable_global_exists("battle_hud_frame") ? global.battle_hud_frame : undefined;
}

// ---- the turn strip (D74): a plate with the current actor first (ringed, gently bobbing), then the next four ----
// Sizes of the strip in GUI units. Sprites are drawn at a whole multiple (k) of the window pixel so they stay crisp at every window size.
function Battle_TimelineMetrics(_bc = noone) {
    var fr = Battle_HudFrame();
    if (is_struct(fr)) {   // inside a Draw GUI frame: built once, for the frame's battle controller
        if (!is_struct(fr.tm)) fr.tm = Battle_TimelineMetricsBuild(fr.bc);
        return fr.tm;
    }
    return Battle_TimelineMetricsBuild(_bc);
}

function Battle_TimelineMetricsBuild(_bc) {
    Battle_HudBuilds().metrics++;
    var mt = Ui_Metrics();
    var p = mt.p;
    var k = Battle_IconK();
    var icon = 16 * k;
    var slot = icon + 4 * p;
    var gap = p;
    var n = TURN_PREVIEW_COUNT;
    var w = n * slot + (n - 1) * gap + 8 * p;
    var plate_h = slot + 8 * p;
    var caption_h = mt.line_h + p;
    var fore = (is_struct(_bc) || (_bc != noone && instance_exists(_bc))) && Status_Has(_bc.p, STATUS_HIT_UP);   // the Foresight caption needs a line under the plate
    return { p: p, k: k, icon: icon, slot: slot, gap: gap, w: w, x0: round((mt.gw - w) * 0.5), y0: mt.margin, plate_h: plate_h, caption_h: caption_h,
             h: plate_h + (fore ? p + caption_h : 0), line_h: mt.line_h };
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

// 3 x 7 "!" (B4): the big attack that follows a wind-up. Cells are p x p.
function Battle_DrawBang(_x, _y, _p, _col) {
    var rows = [2, 2, 2, 2, 2, 0, 2];   // bit 2 = the left column of the 3 wide picture
    for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 3; c++) {
            if (((rows[r] >> (2 - c)) & 1) == 1) Ui_Box(_x + c * _p, _y + r * _p, _x + (c + 1) * _p, _y + (r + 1) * _p, _col);
        }
    }
}

// One slot at (_x, _y): a 1p border (lightest on the current actor), the player's portrait on mid green and the enemy's on the darkest, so the two read apart.
function Battle_DrawTimelineSlot(_bc, _x, _y, _m, _who, _current, _alpha, _eye, _windup = false) {
    var p = _m.p;
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Ui_Box(_x, _y, _x + _m.slot, _y + _m.slot, _current ? UI_C_LIGHTEST : UI_C_DARK);
    Ui_Box(_x + p, _y + p, _x + _m.slot - p, _y + _m.slot - p, (_who == TL_PLAYER) ? UI_C_DARK : UI_C_DARKEST);
    if (_current) Ui_Box(_x + p, _y + p, _x + _m.slot - p, _y + 2 * p, UI_C_LIGHT);
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

// When the order changes it slides for TURN_SLIDE_MS: after a turn the row moves left one slot and the new last one fades in; after a push-back
// (stun, BREAK) the row fades in place. With Foresight, the first upcoming enemy slot wears an eye and the caption under the plate names the action.
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
    var base = m.x0 + 4 * p;
    var sy = m.y0 + 4 * p;

    Ui_DrawFrame(m.x0, m.y0, m.w, m.plate_h, 1, p);
    if (shift_mode && t < 1) {   // the actor that just went fades out as the row moves
        Battle_DrawTimelineSlot(_bc, base - pitch + shift, sy, m, _bc.tl_prev_who, false, (1 - t) * 0.6, false);
    }
    for (var i = 0; i < n; i++) {
        var s = slots[i];
        var xx = base + i * pitch + shift;
        var yy = sy + (s.current ? -Ui_Bob(current_time, p) + p : p);
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
        var ty = m.y0 + m.plate_h + p + p;
        Ui_Box(tx - 2 * p, ty - p, tx + tw + 2 * p, ty + m.line_h + p, UI_C_LIGHTEST);
        Ui_Box(tx - p, ty, tx + tw + p, ty + m.line_h, UI_C_DARKEST);
        Battle_DrawEye(tx, ty + (m.line_h - 5 * p) * 0.5, p, UI_C_LIGHTEST);
        Ui_Text(tx + 9 * p + 2 * p, ty, label, UI_C_LIGHTEST);
    }
}

function Battle_TimelineBottom() {
    var m = Battle_TimelineMetrics(instance_exists(obj_battle_controller) ? instance_find(obj_battle_controller, 0) : noone);
    return m.y0 + m.h;
}

// ---- the skill banner: a plate under the strip with the name of the move (or the wind-up / phase line) while it is up ----
function Battle_BannerRect(_bc) {
    if (!_bc.skill_banner_active || _bc.skill_banner_name == "") return undefined;
    // while a message is up the log plate says the same thing: the banner is for the bars (the move's name stays on screen while you answer it)
    if (_bc.battle_state != BSTATE_ENEMY_DEFENCE && _bc.battle_state != BSTATE_SKILL_QTE && _bc.battle_state != BSTATE_ATTACK_TIMING) return undefined;
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = min(UI_TextWidth(_bc.skill_banner_name) + 12 * p, mt.gw - 2 * mt.margin);
    var h = mt.line_h + 8 * p;
    return { x: round((mt.gw - w) * 0.5), y: Battle_TimelineBottom() + p, w: w, h: h };
}

function Battle_DrawBanner(_bc, _alpha) {
    var r = Battle_BannerRect(_bc);
    if (!is_struct(r)) return;
    var p = Ui_Px();
    Ui_DrawFrame(r.x, r.y, r.w, r.h, _alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Ui_Text(r.x + r.w * 0.5, r.y + 4 * p, _bc.skill_banner_name, UI_C_LIGHTEST, fa_center);
    draw_set_alpha(a0);
}

// ---- the enemy header (D99, D75): a plate above the enemy with its name, HP bar and stagger meter; its status chips sit on top of it ----
// Where the block sits: { cx, x1, y1 (plate top), bw (plate width), h (plate height), chips_x, chips_y, chips_align }. The status chips sit beside
// the plate (right of it, or left when there is no room), so the block is no taller than the plate. Also keeps the BREAK word clear of it.
function Battle_EnemyHeaderRect(_bc) {
    var fr = Battle_HudFrame();
    if (is_struct(fr)) {   // inside a Draw GUI frame: built once
        if (!is_struct(fr.hdr)) fr.hdr = Battle_EnemyHeaderRectBuild(_bc);
        return fr.hdr;
    }
    return Battle_EnemyHeaderRectBuild(_bc);
}

// G10 (D129): where the enemy's visible pixels stand on the GUI grid { x, y, w, h } (the sprite's bounding box at rest, before the feel push-in).
// A menu panel must not cover it. A zero rect when there is no enemy.
function Battle_EnemyRect(_bc) {
    if (!instance_exists(_bc.enemy_inst) || _bc.enemy_inst.sprite_index == noone) return { x: 0, y: 0, w: 0, h: 0 };
    var inst = _bc.enemy_inst;
    var spr = inst.sprite_index;
    var sx = Display_WorldScale();
    var xs = abs(inst.image_xscale);
    var ys = abs(inst.image_yscale);
    var x0 = (inst.x - sprite_get_xoffset(spr) * xs + sprite_get_bbox_left(spr) * xs - _bc.cam_base_x) * sx;
    var x1 = (inst.x - sprite_get_xoffset(spr) * xs + (sprite_get_bbox_right(spr) + 1) * xs - _bc.cam_base_x) * sx;
    var y0 = (inst.y - sprite_get_yoffset(spr) * ys + sprite_get_bbox_top(spr) * ys - _bc.cam_base_y) * sx;
    var y1 = (inst.y - sprite_get_yoffset(spr) * ys + (sprite_get_bbox_bottom(spr) + 1) * ys - _bc.cam_base_y) * sx;
    return { x: round(x0), y: round(y0), w: round(x1 - x0), h: round(y1 - y0) };
}

// R3 (owner note 23): the ground every enemy stands on, in world pixels. Every battle enemy's opaque bottom (its feet) sits on this one line, whatever the size of
// its picture (the 32 x 32 enemies and the 48 and 64 high bosses): the biggest boss still clears the turn strip at every window size, and the shadow
// under the feet is drawn on this line.
#macro BATTLE_GROUND_Y 80

// Where the enemy instance goes in the battle room (its top left corner, origin 0): centred across the picture, the opaque bottom on BATTLE_GROUND_Y.
function Battle_EnemyPlace(_spr) {
    var cx = DISPLAY_BASE_W div 2;
    if (_spr == noone) return { x: cx - 8, y: BATTLE_GROUND_Y - 16 };
    var feet = sprite_get_bbox_bottom(_spr) + 1 - sprite_get_yoffset(_spr);
    return { x: cx - sprite_get_width(_spr) div 2, y: BATTLE_GROUND_Y - feet };
}

// R3 (owner note 5): the soft shadow under an enemy, two nested ellipses in the darkest colour. Pure: the sprite drawn with its origin at (_exs, _eys),
// stretched by (_scx, _scy) GUI units per sprite pixel (push-in and recoil included), _ws = GUI units per world pixel. The outer ellipse is 70% of
// the opaque width and a quarter of that high (as high as the squash of the draw leaves it), centred under the opaque bottom a world pixel below it;
// the inner one is 60% of the outer. { x, y, w, h (outer bounds), ix, iy, iw, ih (inner bounds), cx, cy (the centre) }.
function Battle_EnemyShadowGeom(_spr, _exs, _eys, _scx, _scy, _ws) {
    if (_spr == noone || _spr == -1) return { x: 0, y: 0, w: 0, h: 0, ix: 0, iy: 0, iw: 0, ih: 0, cx: 0, cy: 0 };
    var xo = sprite_get_xoffset(_spr);
    var yo = sprite_get_yoffset(_spr);
    var left = _exs + (sprite_get_bbox_left(_spr) - xo) * _scx;
    var rgt = _exs + (sprite_get_bbox_right(_spr) + 1 - xo) * _scx;
    var bottom = _eys + (sprite_get_bbox_bottom(_spr) + 1 - yo) * _scy;
    var w = abs(rgt - left) * 0.7;
    var squash = (_scx != 0) ? abs(_scy / _scx) : 1;
    var h = max(2, w * 0.25 * squash);
    var cx = (left + rgt) * 0.5;
    var cy = bottom + _ws;
    var iw = w * 0.6;
    var ih = max(2, h * 0.6);
    return { x: round(cx - w * 0.5), y: round(cy - h * 0.5), w: round(w), h: round(h),
             ix: round(cx - iw * 0.5), iy: round(cy - ih * 0.5), iw: round(iw), ih: round(ih), cx: cx, cy: cy };
}

// The shadow of the enemy standing at rest (before the feel push-in and recoil), on the GUI grid. A zero rect when there is no enemy.
function Battle_EnemyShadowRect(_bc) {
    if (!instance_exists(_bc.enemy_inst) || _bc.enemy_inst.sprite_index == noone) return { x: 0, y: 0, w: 0, h: 0, ix: 0, iy: 0, iw: 0, ih: 0, cx: 0, cy: 0 };
    var inst = _bc.enemy_inst;
    var ws = Display_WorldScale();
    return Battle_EnemyShadowGeom(inst.sprite_index, (inst.x - _bc.cam_base_x) * ws, (inst.y - _bc.cam_base_y) * ws,
                                  abs(inst.image_xscale) * ws, abs(inst.image_yscale) * ws, ws);
}

// How strong the two ellipses are: 0.25 and 0.4, times the enemy's own fade.
function Battle_EnemyShadowAlpha(_fade) {
    var f = clamp(_fade, 0, 1);
    return { outer: 0.25 * f, inner: 0.4 * f };
}

// Draws the shadow under the sprite just before the sprite is drawn (the feet cover its upper half).
function Battle_DrawEnemyShadow(_spr, _exs, _eys, _scx, _scy, _ws, _fade) {
    var a = Battle_EnemyShadowAlpha(_fade);
    if (a.outer <= 0 || _spr == noone) return;
    var g = Battle_EnemyShadowGeom(_spr, _exs, _eys, _scx, _scy, _ws);
    if (g.w <= 0) return;
    var a0 = draw_get_alpha();
    var c0 = draw_get_color();
    draw_set_color(UI_C_DARKEST);
    draw_set_alpha(a.outer);
    draw_ellipse(g.x, g.y, g.x + g.w, g.y + g.h, false);
    draw_set_alpha(a.inner);
    draw_ellipse(g.ix, g.iy, g.ix + g.iw, g.iy + g.ih, false);
    draw_set_alpha(a0);
    draw_set_color(c0);
}

// R3 (owner note 8): a chip on its last turn blinks by an outline round its icon cell (on / off every 250 ms) and its label toggling lightest / light;
// never a filled box. { outline (draw the ring now), box (always false), label_col }.
function Battle_ChipBlink(_last, _negative, _ms) {
    var lit = _last && (floor(_ms / 250) mod 2 == 0);
    var col = _negative ? UI_C_LIGHTEST : UI_C_LIGHT;
    if (_last) col = lit ? UI_C_LIGHTEST : UI_C_LIGHT;
    return { outline: lit, box: false, label_col: col };
}

// How a row of _n chips fits a room _room wide: { cm (Battle_ChipMetrics), score (-1 when even the plus chip does not fit, else how many chips show) }.
function Battle_ChipFit(_n, _ic, _p, _room, _lws) {
    var cm = Battle_ChipMetrics(_n, _ic, _p, max(0, _room), _lws);
    return { cm: cm, score: (cm.w <= _room) ? cm.shown : -1 };
}

function Battle_EnemyHeaderRectBuild(_bc) {
    Battle_HudBuilds().header++;
    var mt = Ui_Metrics();
    var p = mt.p;
    var sx = Display_WorldScale();
    var out = { cx: Display_GuiW() * 0.5, x1: 0, y1: round(Display_GuiH() * 0.3), bw: round(36 * sx), h: 0, chips_x: 0, chips_y: 0, chips_align: fa_left, chips_max: mt.gw - 4 * mt.margin,
                chips_shown: 0, chips_more: 0, chips_rect: { x: 0, y: 0, w: 0, h: 0 }, side: "above", name_lines: [] };
    if (!instance_exists(_bc.enemy_inst) || _bc.enemy_inst.sprite_index == noone) return out;
    var inst = _bc.enemy_inst;
    var spr = inst.sprite_index;
    var er = Battle_EnemyRect(_bc);   // the opaque pixels: nothing of the header may stand on them (R3, R-092)
    out.cx = ((inst.x - sprite_get_xoffset(spr) - _bc.cam_base_x) + sprite_get_width(spr) * abs(inst.image_xscale) * 0.5) * sx;
    var spr_w = sprite_get_width(spr) * abs(inst.image_xscale) * sx;
    var name_w = UI_TextWidth(Battle_EnemyName(_bc.e)) + 10 * p;
    out.bw = clamp(max(name_w, round(spr_w * 0.9), 30 * p), 30 * p, mt.gw - 4 * mt.margin);
    out.h = 8 * p + mt.line_h + p + 4 * p + p + 3 * p;
    if (variable_struct_exists(_bc, "e") && is_struct(_bc.e) && variable_struct_exists(_bc.e, "is_elite") && _bc.e.is_elite) out.h += mt.line_h + p;   // C3 (D86): room for the ELITE tag
    out.name_lines = [Battle_EnemyName(_bc.e)];
    var ban = Battle_BannerRect(_bc);
    var floor_y = Battle_TimelineBottom() + p + (is_struct(ban) ? ban.h + p : 0);
    var limit = Battle_Zones().band_top;   // nothing of the header goes down into the player's panel
    var ech = Battle_FighterChips(_bc, TL_ENEMY);
    var n = array_length(ech);
    var ic = 16 * Battle_IconK();
    var lws = Battle_ChipLws(ech);
    var chip_h = ic + 2 * p + p + Battle_ChipLabelH();   // the icon cell, a gap and the label row
    var gap = 2 * p;

    // Over the head when the plate (and the row of chips beside it) fits between the strip and the sprite; else beside the sprite, on the side with more room.
    var block_h = (n > 0) ? max(out.h, p + chip_h) : out.h;
    var y_above = er.y - gap - block_h;
    var cands = [];   // where the chips may go: { x (left edge, or right edge for fa_right), y, room, align }
    if (y_above >= floor_y) {
        out.side = "above";
        out.y1 = y_above;
        out.x1 = clamp(round(out.cx - out.bw * 0.5), mt.margin, mt.gw - mt.margin - out.bw);
        var ry = out.y1 + p;
        array_push(cands, { x: out.x1 + out.bw + p, y: ry, room: mt.gw - mt.margin - (out.x1 + out.bw + p), align: fa_left });
        array_push(cands, { x: out.x1 - p, y: ry, room: (out.x1 - p) - mt.margin, align: fa_right });
        var sy = max(ry, er.y + p);   // beside the sprite, below the plate
        array_push(cands, { x: er.x + er.w + gap, y: sy, room: mt.gw - mt.margin - (er.x + er.w + gap), align: fa_left });
        array_push(cands, { x: er.x - gap, y: sy, room: (er.x - gap) - mt.margin, align: fa_right });
    } else {
        var gs_ = p;   // beside the sprite every pixel counts: one font pixel to the sprite and to the screen edge
        var room_l = er.x - gs_ - gs_;
        var room_r = mt.gw - gs_ - (er.x + er.w + gs_);
        var on_right = (room_r >= room_l);
        var side_room = on_right ? room_r : room_l;
        var text_w = UI_TextWidth(Battle_EnemyName(_bc.e)) + 6 * p;   // the name's lines keep 3p to each frame edge (Ui_DrawNameTab's padding)
        out.bw = clamp(max(text_w, round(spr_w * 0.5), 30 * p), 30 * p, max(30 * p, side_room));
        if (text_w > out.bw) {   // a long name goes on two lines (at its spaces) rather than past the room the sprite leaves
            out.name_lines = Battle_LogWrap(Battle_EnemyName(_bc.e), out.bw - 6 * p);
            out.h += (array_length(out.name_lines) - 1) * mt.line_h;
        }
        var total_h = out.h + ((n > 0) ? gap + chip_h + p : 0);
        out.y1 = max(floor_y, min(er.y, limit - total_h));   // level with the sprite's head, higher if the chips under the plate would reach the panel
        out.x1 = on_right ? (er.x + er.w + gs_) : (er.x - gs_ - out.bw);
        var cy2 = out.y1 + out.h + gap;   // under the plate, on the same side
        array_push(cands, { x: on_right ? (er.x + er.w + gs_) : (er.x - gs_), y: cy2, room: side_room, align: on_right ? fa_left : fa_right });
        array_push(cands, { x: on_right ? (er.x - gs_) : (er.x + er.w + gs_), y: out.y1 + p, room: on_right ? room_l : room_r, align: on_right ? fa_right : fa_left });   // the other side of the sprite
    }

    if (n > 0 && array_length(cands) > 0) {
        var best = 0;
        var best_score = -2;
        for (var i = 0; i < array_length(cands); i++) {
            var fit = Battle_ChipFit(n, ic, p, cands[i].room, lws);
            if (cands[i].y + chip_h + p > limit) fit.score = -1;   // the row would reach the player's panel
            if (fit.score > best_score) { best_score = fit.score; best = i; }
        }
        var cd = cands[best];
        var cm = Battle_ChipMetrics(n, ic, p, max(0, cd.room), lws);
        out.chips_x = cd.x;
        out.chips_y = cd.y;
        out.chips_align = cd.align;
        out.chips_max = max(0, cd.room);
        out.chips_shown = cm.shown;
        out.chips_more = cm.more;
        var x0 = (cd.align == fa_right) ? (cd.x - cm.w) : cd.x;
        out.chips_rect = { x: x0 - p, y: cd.y - p, w: cm.w + 2 * p, h: chip_h + 2 * p };   // the ring of a blinking chip included
    }
    return out;
}

// A bar: a 1p border, a dark inside, the fill in _col up to _ratio. _shown (the glided value) leaves a bright trail behind a falling bar (or a
// bright lead on a rising one). _stripe draws every other column dark (the MP bar), so the two bars differ without a colour of their own.
function Battle_DrawBar(_x, _y, _w, _h, _p, _ratio, _shown, _col, _trail, _stripe = false, _segments = false) {
    Ui_Box(_x, _y, _x + _w, _y + _h, UI_C_DARK);
    Ui_Box(_x + _p, _y + _p, _x + _w - _p, _y + _h - _p, UI_C_DARKEST);
    var iw = _w - 2 * _p;
    var cur = round(iw * clamp(_ratio, 0, 1) / _p) * _p;
    var shown = round(iw * clamp(_shown, 0, 1) / _p) * _p;
    var lo = min(cur, shown);
    var hi = max(cur, shown);
    if (hi > lo) Ui_Box(_x + _p + lo, _y + _p, _x + _p + hi, _y + _h - _p, _trail);
    if (lo > 0) Ui_Box(_x + _p, _y + _p, _x + _p + lo, _y + _h - _p, _col);
    if (_stripe && lo > 0) {
        for (var cx = 2 * _p; cx < lo; cx += 3 * _p) Ui_Box(_x + _p + cx, _y + _p, _x + _p + min(lo, cx + _p), _y + _h - _p, UI_C_DARK);
    }
    if (_segments && lo > 0) {   // D156 (the XP bar): 3p of fill, a 1p dark gap, over and over
        for (var sx = 3 * _p; sx < lo; sx += 4 * _p) Ui_Box(_x + _p + sx, _y + _p, _x + _p + min(lo, sx + _p), _y + _h - _p, UI_C_DARKEST);
    }
}

// The enemy's name in the language of this moment (the battle struct keeps the name it was made with), the elite modifier in front.
function Battle_EnemyName(_e) {
    var base = EnemyDB_Get(_e.id).name;
    if (variable_struct_exists(_e, "is_elite") && _e.is_elite) return Elite_Name(_e.elite) + " " + base;
    return base;
}

// Name, HP and stagger meter above the enemy. The stagger bar flashes when a hit lands and pulses while the enemy is BROKEN; chips above the plate.
function Battle_DrawEnemyHeader(_bc, _alpha) {
    if (!instance_exists(_bc.enemy_inst) || _bc.enemy_inst.sprite_index == noone) return;
    var e = _bc.e;
    var mt = Ui_Metrics();
    var p = mt.p;
    var hdr = Battle_EnemyHeaderRect(_bc);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Ui_DrawFrame(hdr.x1, hdr.y1, hdr.bw, hdr.h, _alpha, p);
    var x0 = hdr.x1 + 4 * p;
    var bw = hdr.bw - 8 * p;
    var yy = hdr.y1 + 4 * p;
    if (variable_struct_exists(e, "is_elite") && e.is_elite) {   // C3 (D86): the tag above the name, pulsing like the outline on the map
        var pulse_col = (floor(current_time / 250) mod 2 == 0) ? UI_C_LIGHTEST : UI_C_LIGHT;
        Ui_Text(hdr.x1 + hdr.bw * 0.5, yy, Loc_T("elite.tag", "Elite"), pulse_col, fa_center);
        yy += mt.line_h + p;
    }
    for (var nl = 0; nl < array_length(hdr.name_lines); nl++) {   // one line, or two when the plate stands beside a sprite with little room
        Ui_Text(hdr.x1 + hdr.bw * 0.5, yy, hdr.name_lines[nl], UI_C_LIGHTEST, fa_center);
        yy += mt.line_h + ((nl == array_length(hdr.name_lines) - 1) ? p : 0);
    }
    _bc.enemy_hp_shown = Ui_Glide(_bc.enemy_hp_shown, e.hp, current_time - _bc.enemy_hp_clock, 120);
    _bc.enemy_hp_clock = current_time;
    var hp_ratio = (e.max_hp > 0) ? clamp(e.hp / e.max_hp, 0, 1) : 0;
    var hp_shown = (e.max_hp > 0) ? clamp(_bc.enemy_hp_shown / e.max_hp, 0, 1) : 0;
    Battle_DrawBar(x0, yy, bw, 4 * p, p, hp_ratio, hp_shown, UI_C_LIGHT, UI_C_LIGHTEST);
    yy += 4 * p + p;
    var broken = (variable_struct_exists(e, "broken") && e.broken);
    var smax = variable_struct_exists(e, "stagger_max") ? e.stagger_max : 0;
    if (smax > 0) {
        var flash = (current_time - _bc.stagger_flash_start) < 120;
        var since_break = current_time - _bc.break_start;
        Ui_Box(x0, yy, x0 + bw, yy + 3 * p, UI_C_DARK);
        Ui_Box(x0 + p, yy + p, x0 + bw - p, yy + 2 * p, UI_C_DARKEST);
        var inner_w = bw - 2 * p;
        if (broken) {   // full and pulsing until the enemy's next turn
            var pulse = (floor(current_time / 120) mod 2 == 0) ? UI_C_LIGHTEST : UI_C_LIGHT;
            Ui_Box(x0 + p, yy + p, x0 + p + inner_w, yy + 2 * p, pulse);
        } else {
            var fill_col = (flash || since_break < 400) ? UI_C_LIGHTEST : UI_C_LIGHT;
            Ui_Box(x0 + p, yy + p, x0 + p + round(inner_w * clamp(e.stagger / smax, 0, 1) / p) * p, yy + 2 * p, fill_col);
        }
    }
    var chips = Battle_FighterChips(_bc, TL_ENEMY);
    if (array_length(chips) > 0) {
        Battle_DrawChips(chips, hdr.chips_x, hdr.chips_y, 16 * Battle_IconK(), p, hdr.chips_max, _alpha, hdr.chips_align, TL_ENEMY);
    }
    draw_set_alpha(a0);
}

// ---- the player's panel (D99): name and level, HP and MP bars with their numbers, the statuses ----
function Battle_DrawPlayerPanel(_bc, _z, _alpha) {
    var ch = _bc.p;
    var mt = Ui_Metrics();
    var p = mt.p;
    var lh = mt.line_h;
    var hud = _bc.hud;
    var now = current_time;
    var dt = now - hud.clock;
    hud.clock = now;
    Feel_LagStep(hud, ch.hp, now, dt);   // D138: the bar drops at once, the lighter trail drains over ~400 ms
    hud.mp_shown = Ui_Glide(hud.mp_shown, ch.mp, dt, 140);
    var hurt = instance_exists(obj_ui_controller) ? obj_ui_controller.hud_hurt_flash_ms : 0;   // set by a hit or a poison / burn tick (ms left)
    var shake = Hud_HurtFlashSign(hurt) * p;   // the panel nudges one way then the other every 2 frames at 60 fps (the old "mod 4")

    var r = _z.player;
    var rx = r.x + shake;
    var ry = r.y - Feel_PanelJoltPx(_bc.feel_ms - _bc.feel_pjolt_start, _bc.feel_pjolt_big, Settings_ShakeOn()) * Display_WorldScale();   // D139: an enemy hit jolts this panel up
    var lab_h = Battle_ChipLabelH();
    var ex = (r.h - (8 * p + 3 * lh + 6 * p + 16 * Battle_IconK() + lab_h + p)) div 3;   // the panel is as tall as the command menu: the spare height goes between the rows
    ex = max(0, ex);
    Ui_DrawFrame(rx, ry, r.w, r.h, _alpha, p);
    var x0 = rx + 4 * p;
    var x1 = rx + r.w - 4 * p;
    var yy = ry + 4 * p;
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var nm = (is_struct(ch.class_cfg) && variable_struct_exists(ch.class_cfg, "name")) ? ch.class_cfg.name : "";
    Ui_Text(x0, yy, nm, UI_C_LIGHTEST);
    Ui_Text(x1, yy, Loc_T("battle.hud.level", "Lv {n}", { n: string(ch.level) }), UI_C_LIGHT, fa_right);
    yy += lh + p + ex;

    var lab_w = max(UI_TextWidth(Loc_T("battle.hud.hp", "HP")), UI_TextWidth(Loc_T("battle.hud.mp", "MP")));
    var val_w = max(UI_TextWidth(string(ch.max_hp) + "/" + string(ch.max_hp)), UI_TextWidth(string(ch.max_mp) + "/" + string(ch.max_mp)));
    var bx = x0 + lab_w + 2 * p;
    var bw = x1 - val_w - 2 * p - bx;
    var bar_h = max(3 * p, (lh div (2 * p)) * 2 * p);
    var by = yy + (lh - bar_h) div 2;

    var hp_ratio = (ch.max_hp > 0) ? ch.hp / ch.max_hp : 0;
    var low = (hp_ratio <= 0.25 && ch.hp > 0);
    var hp_col = (hurt > 0 || (low && floor(now / 300) mod 2 == 0)) ? UI_C_LIGHTEST : UI_C_LIGHT;
    Ui_Text(x0, yy, Loc_T("battle.hud.hp", "HP"), UI_C_LIGHT);
    Battle_DrawBar(bx, by, bw, bar_h, p, hp_ratio, (ch.max_hp > 0) ? hud.hp_shown / ch.max_hp : 0, hp_col, UI_C_LIGHTEST);
    Ui_Text(x1, yy, string(ch.hp) + "/" + string(ch.max_hp), low ? UI_C_LIGHTEST : UI_C_LIGHT, fa_right);
    yy += lh + p + ex;

    var mp_ratio = (ch.max_mp > 0) ? ch.mp / ch.max_mp : 0;
    Ui_Text(x0, yy, Loc_T("battle.hud.mp", "MP"), UI_C_LIGHT);
    Battle_DrawBar(bx, yy + (lh - bar_h) div 2, bw, bar_h, p, mp_ratio, (ch.max_mp > 0) ? hud.mp_shown / ch.max_mp : 0, UI_C_LIGHT, UI_C_LIGHTEST, true);
    Ui_Text(x1, yy, string(ch.mp) + "/" + string(ch.max_mp), UI_C_LIGHT, fa_right);
    yy += lh + 2 * p + ex;

    var chips = Battle_FighterChips(_bc, TL_PLAYER);
    var ic = 16 * Battle_IconK();
    var slot_n = clamp(floor((x1 - x0 + p) / (ic + 3 * p)), 1, 4);   // a tray of status slots: the empty ones are drawn as dark outlines
    var used_w = (array_length(chips) > 0) ? Battle_ChipMetrics(array_length(chips), ic, p, x1 - x0, Battle_ChipLws(chips)).w + p : 0;
    for (var sl = array_length(chips); sl < slot_n; sl++) {
        var sx0 = x0 + used_w + (sl - array_length(chips)) * (ic + 3 * p);
        if (sx0 + ic + 2 * p > x1) break;
        Ui_Box(sx0, yy, sx0 + ic + 2 * p, yy + ic + 2 * p, UI_C_DARK);
        Ui_Box(sx0 + p, yy + p, sx0 + ic + p, yy + ic + p, UI_C_DARKEST);
    }
    Battle_DrawChips(chips, x0, yy, ic, p, x1 - x0, _alpha, fa_left, TL_PLAYER);
    draw_set_alpha(a0);
}

// ---- the log (I-067): the latest lines of the combat log as a small plate above the bottom panels, gone after a few seconds ----
function Battle_LogWrap(_text, _w) {
    return Dialogue_WrapToLines(_text, _w);
}

// The lines to show: the newest entry if it is still fresh, at most its last 2 lines. Returns { lines, age (ms of the entry) }.
function Battle_LogLines(_log, _w, _now) {
    var pool = [];
    var age = 100000;
    for (var i = array_length(_log) - 1; i >= 0; i--) {
        var en = _log[i];
        if (!is_struct(en) || !variable_struct_exists(en, "at")) continue;
        age = _now - en.at;
        if (age > LOG_TOAST_MS) break;
        var wrapped = Battle_LogWrap(string(en.text), _w);
        for (var w = max(0, array_length(wrapped) - 2); w < array_length(wrapped); w++) array_push(pool, wrapped[w]);
        break;
    }
    return { lines: pool, age: age };
}

function Battle_DrawLog(_bc, _z) {
    if (!is_array(_bc.combat_log) || array_length(_bc.combat_log) <= 0) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var inner = _z.msg.w - 8 * p;
    var res = Battle_LogLines(_bc.combat_log, inner, current_time);
    var n = array_length(res.lines);
    if (n <= 0) return;
    var alpha = clamp((LOG_TOAST_MS - res.age) / 400, 0, 1) * clamp(res.age / 60 + 0.4, 0, 1);
    var tw = 0;
    for (var i = 0; i < n; i++) tw = max(tw, UI_TextWidth(res.lines[i]));
    var w = min(tw + 8 * p, _z.msg.w);
    var h = 8 * p + n * mt.line_h + (n - 1) * p;
    var lx = round(_z.msg.x + (_z.msg.w - w) * 0.5);
    var ly = _z.msg.y + _z.msg.h - h;
    Ui_DrawFrame(lx, ly, w, h, alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(alpha);
    for (var j = 0; j < n; j++) Ui_Text(lx + w * 0.5, ly + 4 * p + j * (mt.line_h + p), res.lines[j], UI_C_LIGHTEST, fa_center);
    draw_set_alpha(a0);
    _bc.hud.rects.log = { x: lx, y: ly, w: w, h: h };
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
        var mt = Ui_Metrics();
        var brise = (1 - sqr(1 - clamp(bel / 600, 0, 1))) * 10 * sx;
        var bw2 = UI_TextWidth(txt) * bsc;
        var bh2 = UI_TextHeight(txt) * bsc;
        var bx2 = ex - bw2 * 0.5;
        var sph = (instance_exists(_bc.enemy_inst) && _bc.enemy_inst.sprite_index != noone) ? sprite_get_height(_bc.enemy_inst.sprite_index) * abs(_bc.enemy_inst.image_yscale) * sx : 24 * sx;
        var by2 = max(Battle_TimelineBottom() + mt.p, ey - sph * 0.3 - bh2 * 0.5) - brise;   // over the enemy's upper body, clear of the plate and the strip
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

// ---- Battle feel (D138, D139): hit freeze + sparks + jolt + recoil + zoom punch, the death pop, the heavier hurt, the low-HP warning ----
// The curves are pure (scr_fx: Feel_*); this is the wiring to the battle controller. The controller keeps a "feel clock" (feel_ms, in ms, it stands still in a
// hit freeze) and the start time of each effect on it. D49: the Screen shake setting off turns off the shakes, the jolt, the recoil and the zoom punch only.
function Battle_FeelInit(_bc) {
    _bc.feel_ms = 0;                    // the feel clock (ms): stands still in a hit freeze
    _bc.feel_hit_start = -100000;       // when the last hit's jolt and recoil began (feel clock)
    _bc.feel_hit_px = 2;                // that jolt's size, px
    _bc.feel_punch_start = -100000;     // the crit / BREAK zoom punch
    _bc.feel_punch_on = false;
    _bc.feel_break = false;             // a BREAK landed with this hit (its freeze and zoom)
    _bc.feel_contact = false;           // the freeze is long enough to show the contact flash
    _bc.rumble_perfect = false;         // H3: a Perfect hit landed (one-shot: the controller rumble takes it, Rumble_SnapshotOf)
    _bc.rumble_break = false;           // H3: a BREAK landed (one-shot, the same: it is raised and cleared inside one step when the enemy acts right after)
    _bc.feel_edge_start = -100000;      // the dark screen-edge flash of a big hit taken
    _bc.feel_pjolt_start = -100000;     // the HP panel's jolt
    _bc.feel_pjolt_big = false;
    _bc.feel_inset = 0;                 // the picture's push-in this frame, px a side
    _bc.feel_zr = Feel_ZoomRegion(0, 0, 0);
    _bc.feel_zoom_on = false;
    _bc.sparks = undefined;             // { start, cx, cy, items } of the last damaging hit
    _bc.death_pop = undefined;          // the enemy's death pop (Battle_DeathPopBegin)
    _bc.lowhp_ms = 0;                   // how long the low-HP warning has run
    _bc.lowhp_on = false;
    _bc.beat_n = 0;                     // thumps played so far in this warning
}

// A damaging player hit freezes the picture (40 ms OK / Good, 80 Perfect, 120 crit / BREAK); the impact feedback (shakes, sparks, jolt, recoil) comes when the
// freeze ends (Step_0 calls Battle_QteImpactFeedback). Never while a bar is in its timing window; a hit that deals nothing has its feedback at once.
function Battle_HitFreeze(_bc, _key, _crit) {
    if (_bc.last_dmg <= 0 || _bc.qte_active || _bc.sq_active || _bc.def_active) {
        Battle_QteImpactFeedback(_bc);
        return;
    }
    var ms = Feel_FreezeMs(_key, _crit, _bc.feel_break);
    _bc.hitstop_ms = max(_bc.hitstop_ms, ms);
    _bc.feel_contact = (ms >= FEEL_FREEZE_PERFECT_MS);
    _bc.rumble_perfect = (_key == QTE_PERFECT);   // H3: the grade says Perfect, not the length of the freeze (a crit and a BREAK freeze 120 ms too)
}

// The sparks, the jolt, the recoil and (crit / BREAK) the zoom punch of a damaging hit, started on the feel clock.
function Battle_HitFeel(_bc) {
    var brk = _bc.feel_break;
    _bc.feel_break = false;
    if (_bc.last_dmg <= 0) return;
    var key = _bc.qte_result_key;
    var crit = _bc.last_crit;
    _bc.sparks = { start: _bc.feel_ms, cx: _bc.enemy_fx_x, cy: _bc.enemy_fx_y, items: Feel_Sparks(_bc.enemy_fx_x, _bc.enemy_fx_y, key, crit, brk) };
    _bc.feel_hit_start = _bc.feel_ms;
    _bc.feel_hit_px = Feel_JoltPx(key, crit);
    if (crit || brk) {
        _bc.feel_punch_start = _bc.feel_ms;
        _bc.feel_punch_on = true;
    }
}

// The picture's push-in now, px a side (the hit's jolt or the zoom punch; 0 with the Screen shake setting off).
function Battle_FeelInset(_bc) {
    return Feel_InsetPx(_bc.feel_ms - _bc.feel_hit_start, _bc.feel_hit_px, _bc.feel_ms - _bc.feel_punch_start, _bc.feel_punch_on, Settings_ShakeOn());
}

// Once per Step: the feel clock, the death pop's clock, the low-HP heartbeat, and the push-in handed to the display.
// _step_ms is battle time (2x while run is held, D134); _real_ms (default: the same) is the unscaled step, which the low-HP warning keeps.
function Battle_FeelStep(_bc, _step_ms, _real_ms = undefined) {
    if (is_undefined(_real_ms)) _real_ms = _step_ms;
    var frozen = (_bc.hitstop_ms > 0);
    if (!frozen) _bc.feel_ms += _step_ms;
    Battle_DeathPopAdvance(_bc, _step_ms);   // the pop's own freeze is part of it (not stopped by a hit freeze)

    var low = !_bc.battle_over && Feel_LowHpActive(_bc.p.hp, _bc.p.max_hp);
    if (low) {
        if (!frozen) _bc.lowhp_ms += _real_ms;
        var due = Feel_BeatCount(_bc.lowhp_ms);
        while (_bc.beat_n < due) {
            _bc.beat_n++;
            var second = ((_bc.beat_n mod 2) == 0);
            Feel_PlayKeep("qte_weak", Feel_BeatVol(second), second ? 0.62 : 0.5);   // the dull knock, low and quiet; SFX_Play applies the SFX volume
        }
    } else {
        _bc.lowhp_ms = 0;
        _bc.beat_n = 0;
    }
    _bc.lowhp_on = low;

    var inset = Battle_FeelInset(_bc);
    _bc.feel_inset = inset;
    var cx = round(_bc.enemy_fx_x - _bc.cam_base_x);
    var cy = round(_bc.enemy_fx_y - _bc.cam_base_y);
    _bc.feel_zr = Feel_ZoomRegion(inset, cx, cy);
    if (inset > 0) {
        Display_SetZoom(_bc.feel_zr.zoom, cx, cy);
        _bc.feel_zoom_on = true;
    } else if (_bc.feel_zoom_on) {
        Display_ClearZoom();
        _bc.feel_zoom_on = false;
    }
}

// The enemy hit the player (D138, D139): the HP panel jolts; a big hit (a telegraphed move, or a quarter of max HP) also shakes the picture harder than a Perfect
// and flashes the screen edges dark. The HP lag bar needs nothing here: it follows every drop in Battle_DrawPlayerPanel.
function Battle_PlayerHurtFeel(_bc, _dmg, _max_hp, _heavy) {
    if (_dmg <= 0) return;
    var big = Feel_IsBigHit(_dmg, _max_hp, _heavy);
    _bc.feel_pjolt_start = _bc.feel_ms;
    _bc.feel_pjolt_big = big;
    if (big) {
        _bc.feel_edge_start = _bc.feel_ms;
        CameraShake_Start(FEEL_BIG_SHAKE_MAG, FEEL_BIG_SHAKE_MS, SHAKE_DIR_V);
    }
}

// ---- the enemy death pop (D138) ----
// The killing blow: the enemy freezes and flashes light (FEEL_DEATH_FREEZE_MS), bursts into pixel squares that scatter, fall and fade, and only THEN does the
// "has been slain" message come (Battle_DeathPopStep posts it). Returns false when there is no enemy picture to burst (the caller posts the message at once).
function Battle_DeathPopBegin(_bc, _e, _text) {
    if (!instance_exists(_bc.enemy_inst) || _bc.enemy_inst.sprite_index == noone) return false;
    var inst = _bc.enemy_inst;
    var spr = inst.sprite_index;
    var boss = variable_struct_exists(_e, "is_boss") && _e.is_boss;
    var xs = abs(inst.image_xscale);
    var ys = abs(inst.image_yscale);
    _bc.death_pop = {
        active: true, t_ms: 0, boss: boss, text: _text, total_ms: Feel_DeathTotalMs(boss), burst_done: false,
        parts: Feel_DeathParticles(spr, inst.image_index, inst.x - sprite_get_xoffset(spr) * xs, inst.y - sprite_get_yoffset(spr) * ys, xs, ys, boss)
    };
    _bc.battle_state = BSTATE_MESSAGE;       // the controller waits here until the pop is over (Step_0 exits through Battle_DeathPopStep)
    _bc.message_next_state = BSTATE_END_RUN;
    _bc.wait_fx = noone;
    _bc.wait_timer = 0;
    return true;
}

function Battle_DeathPopActive(_bc) {
    return is_struct(_bc.death_pop) && _bc.death_pop.active;
}

// The pop's clock (real ms). The sound and the shake of the burst start when the freeze is over.
function Battle_DeathPopAdvance(_bc, _ms) {
    var dp = _bc.death_pop;
    if (!is_struct(dp) || !dp.active) return;
    dp.t_ms += _ms;
    if (!dp.burst_done && dp.t_ms >= FEEL_DEATH_FREEZE_MS) {
        dp.burst_done = true;
        Feel_PlayKeep("barrel_break", 1, dp.boss ? 0.6 : 0.85);
        if (dp.boss) Feel_PlayKeep("qte_perfect", 1, 0.55);
        CameraShake_Start(dp.boss ? FEEL_BIG_SHAKE_MAG : QTE_SHAKE_PERFECT_MAG, dp.boss ? 320 : QTE_SHAKE_PERFECT_MS, SHAKE_DIR_H);
    }
}

// True while the pop is playing (the controller does nothing else); when it has run its time it posts the slain message and the battle ends on it as before.
function Battle_DeathPopStep(_bc) {
    var dp = _bc.death_pop;
    if (!is_struct(dp) || !dp.active) return false;
    if (dp.t_ms >= dp.total_ms) {
        dp.active = false;
        Battle_Message(_bc, dp.text, BSTATE_END_RUN, noone, COMBAT_ACTION_DELAY_MS);
    }
    return true;
}

// ---- drawing the feel (Draw_64) ----
// A view-local world point (x - the camera's x) to GUI units, through the push-in's region and magnification.
function Battle_FeelGuiX(_zr, _wx_view, _unit) {
    return (_wx_view - _zr.sx) * _zr.kx * _unit;
}

function Battle_FeelGuiY(_zr, _wy_view, _unit) {
    return (_wy_view - _zr.sy) * _zr.ky * _unit;
}

// Whole-pixel squares in GUI units (_size_world world px each, magnified like the picture).
function Battle_FeelSquare(_zr, _wx_view, _wy_view, _size_world, _unit, _col, _alpha, _outline = false) {
    var sz = max(1, round(_size_world * _unit * _zr.kx));
    var x0 = floor(Battle_FeelGuiX(_zr, _wx_view, _unit) - sz * 0.5);
    var y0 = floor(Battle_FeelGuiY(_zr, _wy_view, _unit) - sz * 0.5);
    draw_set_alpha(_alpha);
    if (_outline) {   // a dark rim so the light square reads on the light enemy as well as on the dark backdrop
        var ow = max(1, round(_unit * 0.5));
        draw_set_colour(UI_C_DARKEST);
        draw_rectangle(x0 - ow, y0 - ow, x0 + sz - 1 + ow, y0 + sz - 1 + ow, false);
    }
    draw_set_colour(_col);
    draw_rectangle(x0, y0, x0 + sz - 1, y0 + sz - 1, false);
}

// The hit sparks and the death burst, over the enemy and the skill animations.
function Battle_DrawFeelFx(_bc, _vx, _vy, _unit) {
    var zr = _bc.feel_zr;
    var a0 = draw_get_alpha();
    var c0 = draw_get_colour();
    var sp = _bc.sparks;
    if (is_struct(sp)) {
        var el = _bc.feel_ms - sp.start;
        if (el >= 0 && el < FEEL_SPARK_MS) {
            for (var i = 0; i < array_length(sp.items); i++) {
                var it = sp.items[i];
                var pos = Feel_SparkPos(it, sp.cx, sp.cy, el);
                if (pos.alive) Battle_FeelSquare(zr, pos.x - _vx, pos.y - _vy, it.size, _unit, it.col, 1, true);
            }
        }
    }
    var dp = _bc.death_pop;
    if (is_struct(dp) && dp.t_ms >= FEEL_DEATH_FREEZE_MS) {
        var burst_ms = dp.total_ms - FEEL_DEATH_FREEZE_MS;
        var bt = dp.t_ms - FEEL_DEATH_FREEZE_MS;
        if (bt < burst_ms) {
            var alpha = Feel_ParticleAlpha(bt, burst_ms);
            var shrink = 1 - 0.5 * clamp(bt / burst_ms, 0, 1);
            for (var j = 0; j < array_length(dp.parts); j++) {
                var pt = dp.parts[j];
                var pp = Feel_ParticlePos(pt, bt);
                Battle_FeelSquare(zr, pp.x - _vx, pp.y - _vy, pt.size * shrink, _unit, pt.col, alpha);
            }
        }
    }
    draw_set_alpha(a0);
    draw_set_colour(c0);
}

// The dark screen edges: the flash of a big hit taken, and the slow faint pulse of the low-HP warning. Under the HUD.
function Battle_DrawFeelEdges(_bc, _unit) {
    var flash = Feel_EdgeAlpha(_bc.feel_ms - _bc.feel_edge_start);
    var pulse = Feel_PulseAlpha(_bc.lowhp_ms, _bc.lowhp_on);
    if (flash > 0.001) Feel_DrawEdge(Display_GuiW(), Display_GuiH(), _unit, flash);
    if (pulse > 0.001) Feel_DrawEdge(Display_GuiW(), Display_GuiH(), _unit, pulse);
}

// ============================================================================
// D134 (battle speed-up) and D135 (damage preview).
// ============================================================================
#macro BATTLE_SPEEDUP_MULT 2   // D134: holding run plays the battle's own clocks (never a QTE) at this speed

// True while a QTE is up: the sliding bar (also a throw's), the arrow sequence, the defence bar and the telegraph before it. Reads a battle controller or a struct shaped like one.
function Battle_QteBusy(_bc) {
    if (_bc.qte_active || _bc.sq_active || _bc.def_active) return true;
    var st = _bc.battle_state;
    return (st == BSTATE_ATTACK_TIMING || st == BSTATE_SKILL_QTE || st == BSTATE_ENEMY_DEFENCE);
}

// D134: the battle time scale from its two inputs. 2 only while run is held and no QTE is up, 1 otherwise.
function Battle_TimeScaleOf(_run_held, _qte_busy) {
    return (_run_held && !_qte_busy) ? BATTLE_SPEEDUP_MULT : 1;
}

// The one time-scale factor of a battle (the controller Step, the effect animations). Every NON-QTE ms clock of the battle runs on Battle_StepMs / this;
// the QTE clocks read Qte_StepMs and never see it. _bc defaults to the battle controller (1 when there is none).
function Battle_TimeScale(_bc = undefined) {
    if (is_undefined(_bc)) {
        if (!instance_exists(obj_battle_controller)) return 1;
        _bc = instance_find(obj_battle_controller, 0);
    }
    return Battle_TimeScaleOf(Input_Held("run"), Battle_QteBusy(_bc));
}

// Milliseconds one frame adds to a battle (non-QTE) clock: the presentation step times the time scale.
function Battle_StepMs(_delta_us, _bc = undefined) {
    return Presentation_StepMs(_delta_us) * Battle_TimeScale(_bc);
}

// D135: the damage of ONE player hit at a grade multiplier, from the same pieces the hit is dealt with (Combat_HitDamage, then the gear passives' bonus
// pressure, which reads the enemy HP after the hit), changing nothing. A crit is luck and is not shown. _src is { power, stat_type } of the attack or skill.
function Battle_HitPreview(_p, _e, _src, _is_skill, _grade_mult) {
    var base = Combat_HitDamage(_p, _e, _src, 1, 1, _grade_mult);
    if (base <= 0) return 0;
    var left = max(0, _e.hp - base);
    var after = { hp: left, max_hp: _e.max_hp, status: _e.status };   // what the bonus passives look at: the enemy once the hit has landed
    var bonus = Equip_PlayerBonusDamage(_p, after, base, _is_skill, "", true);
    return base + min(bonus, left);
}

// The damage of each hit of a skill with several hits, in order, as Skill_Use deals them: one after the other on copies of the fighters, so what a hit
// changes (a guard status is used up, the enemy's HP falls, a gear passive's state) is there for the next one. A crit is luck and is not shown.
function Battle_HitsPreview(_p, _e, _src, _is_skill, _grade_mult, _hits) {
    var out = [];
    var p = variable_clone(_p);
    var e = variable_clone(_e);
    for (var h = 0; h < _hits; h++) {
        var pack = Combat_ApplyDamage(p, e, _src, 1, 1, { is_skill: _is_skill, grade_mult: _grade_mult });
        e = pack.defender;
        var dmg = pack.dmg;
        if (dmg > 0) {
            var bonus = Equip_PlayerBonusDamage(p, e, dmg, _is_skill, "");
            var spend = min(bonus, e.hp);
            e.hp = max(0, e.hp - spend);
            dmg += spend;
        }
        array_push(out, dmg);
    }
    return out;
}

// { ok, perfect, hits, ok_hits, perfect_hits }: the first hit at the grade OK and at Perfect (the D61 multipliers), how many hits it has and the damage of every hit.
function Battle_PreviewOf(_p, _e, _src, _is_skill, _hits) {
    var ok = Qte_GradeMult(QTE_OK);
    var pf = Qte_GradeMult(QTE_PERFECT);
    if (_hits <= 1) {
        var a = Battle_HitPreview(_p, _e, _src, _is_skill, ok);
        var b = Battle_HitPreview(_p, _e, _src, _is_skill, pf);
        return { ok: a, perfect: b, hits: 1, ok_hits: [a], perfect_hits: [b] };
    }
    var oh = Battle_HitsPreview(_p, _e, _src, _is_skill, ok, _hits);
    var ph = Battle_HitsPreview(_p, _e, _src, _is_skill, pf, _hits);
    return { ok: oh[0], perfect: ph[0], hits: _hits, ok_hits: oh, perfect_hits: ph };
}

// The basic attack with this weapon (an ItemDB weapon entry or the bare-hands struct, as Battle_PlayerWeapon gives).
function Battle_AttackPreview(_p, _e, _weapon) {
    return Battle_PreviewOf(_p, _e, Combat_BasicSource(_weapon), false, 1);
}

// A damaging skill; undefined for a skill that deals no damage (a buff, a status-only skill, a steal) and for one aimed at yourself.
function Battle_SkillPreview(_p, _e, _skill_id) {
    var s = SkillDB_Get(_skill_id);
    if (!is_struct(s) || s.id == -1 || s.effect != "damage") return undefined;
    if (variable_struct_exists(s, "target") && s.target == TGT_SELF) return undefined;
    var hits = variable_struct_exists(s, "hits") ? max(1, round(real(s.hits))) : 1;
    return Battle_PreviewOf(_p, _e, Skill_DamageSource(_p, s), true, hits);
}

// "7" for one hit, "7 x2" for a skill that hits twice (per-hit damage x hits).
function Battle_PreviewValue(_n, _hits) {
    return (_hits > 1) ? Loc_T("battle.preview.hits", "{n} x{hits}", { n: string(_n), hits: string(_hits) }) : string(_n);
}

// The hits of a preview as text: "7 x2" when every hit is the same, else each hit on its own: "1+4" (a guard that the first hit uses up).
function Battle_PreviewHitsText(_list) {
    var same = true;
    for (var i = 1; i < array_length(_list); i++) { if (_list[i] != _list[0]) same = false; }
    if (same) return Battle_PreviewValue(_list[0], array_length(_list));
    var t = "";
    for (var j = 0; j < array_length(_list); j++) t += ((j > 0) ? "+" : "") + string(_list[j]);
    return t;
}

// The two number lines a skill details panel gets (D100: the same numbers the hit deals). [] without a preview.
function Battle_PreviewLines(_pv) {
    if (!is_struct(_pv)) return [];
    return [
        { label: Loc_T("battle.det.damage", "Damage"), value: Battle_PreviewHitsText(_pv.ok_hits) },
        { label: Loc_T("battle.det.perfect", "Perfect"), value: Battle_PreviewHitsText(_pv.perfect_hits) }
    ];
}

// The line pair of the small plate beside the command menu while the cursor is on ATTACK: "Damage 4" over "Perfect 5".
function Battle_PreviewPlateLines(_pv) {
    return [
        Loc_T("battle.preview.damage", "Damage {n}", { n: Battle_PreviewHitsText(_pv.ok_hits) }),
        Loc_T("battle.preview.perfect", "Perfect {n}", { n: Battle_PreviewHitsText(_pv.perfect_hits) })
    ];
}

// A signature of every skill preview: the skill rows are rebuilt when it changes (the enemy broke, was hurt, took a status...).
function Battle_SkillPreviewSig(_p, _e) {
    var sig = "";
    var ids = is_array(_p.skills) ? _p.skills : [];
    for (var i = 0; i < array_length(ids); i++) {
        var pv = Battle_SkillPreview(_p, _e, ids[i]);
        sig += is_struct(pv) ? (Battle_PreviewHitsText(pv.ok_hits) + "/" + Battle_PreviewHitsText(pv.perfect_hits)) : "-";
        sig += ",";
    }
    return sig;
}

// The "x2" marker of D134: a small plate in the top right corner, clear of the turn strip in the middle. Pure.
function BattleHud_SpeedRect(_gw, _gh, _p, _lh, _text_w) {
    var m = 3 * _p;
    var w = _text_w + 12 * _p;
    return { x: _gw - m - w, y: m, w: w, h: _lh + 8 * _p };
}

// H13b (D156): the plate for the preview _pv beside the command menu _cmd (top aligned with it, clear of the player panel), in the zones _z:
// { r, lines, plate, stacked, text_w, fit_w, pad, ok }. It is two lines ("Damage 4" over "Perfect 5") with 6p of air each side when that fits the gap; with
// 4p of air when only that fits; else four lines (the label, then its number, twice), which needs half the width. r is the plate's rectangle, lines what is
// drawn, plate the two plain lines (what the checks compare), fit_w the width a line may take, ok whether every line fits it whole. Pure.
function Battle_PreviewPlateLayout(_cmd, _z, _mt, _pv) {
    var p = _mt.p;
    var lh = _mt.line_h;
    var plate = Battle_PreviewPlateLines(_pv);
    var avail = _cmd.x - _z.m - (_z.player.x + _z.player.w + _z.m);
    var tw = max(UI_TextWidth(plate[0]), UI_TextWidth(plate[1]));
    var lines = plate;
    var pad = 12 * p;
    var h = 2 * lh + 9 * p;
    var stacked = false;
    if (tw + pad > avail) pad = 8 * p;
    if (tw + pad > avail) {
        stacked = true;
        lines = [Loc_T("battle.det.damage", "Damage"), Battle_PreviewHitsText(_pv.ok_hits), Loc_T("battle.det.perfect", "Perfect"), Battle_PreviewHitsText(_pv.perfect_hits)];
        tw = 0;
        for (var i = 0; i < 4; i++) tw = max(tw, UI_TextWidth(lines[i]));
        h = 4 * lh + 11 * p;
    }
    var w = min(tw + pad, max(avail, 12 * p));
    var fit_w = w - pad;
    var shown = [];
    for (var j = 0; j < array_length(lines); j++) array_push(shown, Ui_FitText(lines[j], fit_w));
    return { r: { x: _cmd.x - _z.m - w, y: _cmd.y, w: w, h: h }, lines: shown, plate: plate, stacked: stacked, text_w: tw, fit_w: fit_w, pad: pad, ok: (tw <= fit_w) };
}

// D135: with the cursor on ATTACK in the command menu, a plate beside it shows the damage against the current enemy at OK and at Perfect.
// Remembers what it drew for the tests and the shots: hud.rects.preview, hud.preview_text (the lines AS DRAWN, fitted and stacked as laid out, so a cut or a stacked
// plate shows), hud.preview_plate (the two plain lines) and hud.preview_stacked; all stay empty on any other row.
function Battle_DrawAttackPreview(_bc, _alpha) {
    _bc.hud.rects.preview = undefined;
    _bc.hud.preview_text = [];
    _bc.hud.preview_plate = [];
    _bc.hud.preview_stacked = false;
    var m = _bc.ui_cmd;
    if (array_length(m.items) <= 0 || m.items[m.cursor].id != "attack" || m.rect.w <= 0) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var z = Battle_Zones();
    var pl = Battle_PreviewPlateLayout(m.rect, z, mt, Battle_AttackPreview(_bc.p, _bc.e, Battle_PlayerWeapon(_bc)));
    var r = pl.r;
    Ui_DrawFrame(r.x, r.y, r.w, r.h, _alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    for (var i = 0; i < array_length(pl.lines); i++) {
        var accent = pl.stacked ? (i mod 2 == 1) : (i == 0);   // the number (stacked) or the first line (two lines) is the bright one
        Ui_Text(r.x + pl.pad div 2, r.y + 4 * p + i * (mt.line_h + p), pl.lines[i], accent ? UI_C_LIGHTEST : UI_C_LIGHT);
    }
    draw_set_alpha(a0);
    _bc.hud.rects.preview = r;
    _bc.hud.preview_text = pl.lines;
    _bc.hud.preview_plate = pl.plate;
    _bc.hud.preview_stacked = pl.stacked;
}

// D134: "x2" in the top right corner while the battle runs at double speed.
function Battle_DrawSpeedMark(_bc) {
    _bc.hud.rects.speed = undefined;
    if (Battle_TimeScale(_bc) <= 1) return;
    var mt = Ui_Metrics();
    var txt = Loc_T("battle.speed.mark", "x2");
    var r = BattleHud_SpeedRect(mt.gw, mt.gh, mt.p, mt.line_h, UI_TextWidth(txt));
    Ui_DrawFrame(r.x, r.y, r.w, r.h, 1, mt.p);
    Ui_Text(r.x + r.w * 0.5, r.y + 4 * mt.p, txt, UI_C_LIGHTEST, fa_center);
    _bc.hud.rects.speed = r;
}
