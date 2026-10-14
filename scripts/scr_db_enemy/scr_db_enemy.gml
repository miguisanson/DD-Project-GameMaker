// ============================================================================================================
// Battle AI (packet B4, combat-spec.md section 12; D7 D68 D75 D79). Data first: every enemy record has `brain = { rules, weights, phases }`.
// A rule is `{ label, when: [cond, ...], act: "attack" | "skill", skill, chance, max_uses }`; the first rule that holds wins, else a weighted draw.
// ============================================================================================================
function AI_Cond(_c, _v = 0, _status = -1) {
    return { c: _c, v: _v, status: _status };
}

function AI_Rule(_label, _when, _act, _skill = -1, _chance = 1, _max_uses = -1) {
    return { label: _label, when: _when, act: _act, skill: _skill, chance: _chance, max_uses: _max_uses };
}

function AI_Weight(_act, _skill, _w) {
    return { act: _act, skill: _skill, w: _w };
}

// A boss phase: from `at` (own HP ratio) downwards, `spd_add` / `atk_add` are added to the stats and these lists replace the base ones.
function AI_Phase(_at, _spd_add, _atk_add, _banner, _banner_text, _rules, _weights) {
    return { at: _at, spd_add: _spd_add, atk_add: _atk_add, banner: _banner, banner_text: _banner_text, rules: _rules, weights: _weights };
}

function AI_Brain(_rules, _weights, _phases = []) {
    return { rules: _rules, weights: _weights, phases: _phases };
}

function EnemyDB_Init() {
    if (variable_global_exists("enemy_db") && ds_exists(global.enemy_db, ds_type_map)) {
        return;
    }

    global.enemy_db = ds_map_create();

    global.enemy_db[? ENEMY_SLIME] = {
        id: ENEMY_SLIME,
        name: "Slime",
        level: 1,
        stats: { atk: 8, def: 7, spd: 9, mag: 5 },
        base_hp: 9,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: slime_profile,
        sprite_world: slime_moving,
        exp: 8,
        species_min_level: 1,
        species_max_level: 1,
        species_level_offset: 0,
        threat_rank: 1,
        basic_power: 5,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.90,
        loot_key: "enemy_basic",
        ai: { scan_radius: 32, think_rate: 20, forget_delay: 15, leash_mult: 3, wander_chance: 4, move_speed: 1 },
        skills: [SKILL_SOLIDIFY],
        brain: AI_Brain(
            [ AI_Rule("solidify_when_hurt", [AI_Cond("hp_below", 0.5), AI_Cond("self_missing_status", 0, STATUS_SOLIDIFY)], "skill", SKILL_SOLIDIFY) ],
            [ AI_Weight("attack", -1, 4), AI_Weight("skill", SKILL_SOLIDIFY, 1) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_SPIDER] = {
        id: ENEMY_SPIDER,
        name: "Spider",
        level: 2,
        stats: { atk: 8, def: 7, spd: 10, mag: 5 },
        base_hp: 10,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: spider_profile,
        sprite_world: spider_moving,
        exp: 8,
        species_min_level: 2,
        species_max_level: 3,
        species_level_offset: 0,
        threat_rank: 1,
        basic_power: 5,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.90,
        loot_key: "enemy_basic",
        ai: { scan_radius: 32, think_rate: 14, forget_delay: 30, leash_mult: 3, wander_chance: 3, move_speed: 1.1 },
        skills: [SKILL_POISON_FANGS],
        brain: AI_Brain(
            [ AI_Rule("no_stacking_past_4", [AI_Cond("player_status_at_least", 4, STATUS_POISON)], "attack"),
              AI_Rule("open_with_poison", [AI_Cond("player_missing_status", 0, STATUS_POISON)], "skill", SKILL_POISON_FANGS, 0.6) ],
            [ AI_Weight("attack", -1, 3), AI_Weight("skill", SKILL_POISON_FANGS, 1) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_SNAKE] = {
        id: ENEMY_SNAKE,
        name: "Snake",
        level: 2,
        stats: { atk: 9, def: 7, spd: 10, mag: 5 },
        base_hp: 10,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: snake_profile,
        sprite_world: snake_moving,
        exp: 10,
        species_min_level: 2,
        species_max_level: 4,
        species_level_offset: 0,
        threat_rank: 1,
        basic_power: 5,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.90,
        loot_key: "enemy_basic",
        ai: { scan_radius: 36, think_rate: 14, forget_delay: 30, leash_mult: 3, wander_chance: 3, move_speed: 1.1 },
        skills: [SKILL_BITE],
        brain: AI_Brain(
            [ AI_Rule("no_stacking_past_3", [AI_Cond("player_status_at_least", 3, STATUS_BLEED)], "attack"),
              AI_Rule("open_with_bite", [AI_Cond("player_missing_status", 0, STATUS_BLEED)], "skill", SKILL_BITE, 0.5) ],
            [ AI_Weight("attack", -1, 2), AI_Weight("skill", SKILL_BITE, 1) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_MADWHISP] = {
        id: ENEMY_MADWHISP,
        name: "Mad Whisp",
        level: 5,
        stats: { atk: 10, def: 9, spd: 12, mag: 13 },
        base_hp: 12,
        base_mp: 8,
        hd: 6,
        mp_gain: 2,
        weapon_id: 0,
        sprite: mad_whisp_profile,
        sprite_world: mad_whisp_moving,
        exp: 28,
        species_min_level: 5,
        species_max_level: 7,
        species_level_offset: 0,
        threat_rank: 2,
        basic_power: 7,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.75,
        loot_key: "enemy_mid",
        ai: { scan_radius: 80, think_rate: 10, forget_delay: 75, leash_mult: 5, wander_chance: 1, move_speed: 1.3 },
        skills: [SKILL_SCORCHING_TOUCH, SKILL_SNUFF],
        brain: AI_Brain(
            [ AI_Rule("snuff_buffs", [AI_Cond("player_buffed")], "skill", SKILL_SNUFF) ],
            [ AI_Weight("attack", -1, 3), AI_Weight("skill", SKILL_SCORCHING_TOUCH, 2) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_KILLER_PLANT] = {
        id: ENEMY_KILLER_PLANT,
        name: "Killer Plant",
        level: 4,
        stats: { atk: 12, def: 11, spd: 9, mag: 10 },
        base_hp: 14,
        base_mp: 6,
        hd: 8,
        mp_gain: 1,
        weapon_id: 0,
        sprite: killer_plant_profile,
        sprite_world: killer_plant_moving,
        exp: 20,
        species_min_level: 4,
        species_max_level: 6,
        species_level_offset: 0,
        threat_rank: 2,
        basic_power: 7,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.75,
        loot_key: "enemy_mid",
        ai: { scan_radius: 44, think_rate: 12, forget_delay: 45, leash_mult: 3, wander_chance: 2, move_speed: 1 },
        skills: [SKILL_VINE_TRAP, SKILL_REGROW],
        brain: AI_Brain(
            [ AI_Rule("low_hp_heal", [AI_Cond("hp_below", 0.4)], "skill", SKILL_REGROW, 1, 1),
              AI_Rule("vine_every_3rd", [AI_Cond("every_nth", 3)], "skill", SKILL_VINE_TRAP) ],
            [ AI_Weight("attack", -1, 1) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_DIREWOLF] = {
        id: ENEMY_DIREWOLF,
        name: "Dire Wolf",
        level: 3,
        stats: { atk: 11, def: 9, spd: 11, mag: 6 },
        base_hp: 12,
        base_mp: 0,
        hd: 7,
        mp_gain: 0,
        weapon_id: 0,
        sprite: dire_wolf_profile,
        sprite_world: dire_wolf_moving,
        exp: 14,
        species_min_level: 3,
        species_max_level: 5,
        species_level_offset: 0,
        threat_rank: 1,
        basic_power: 5,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.85,
        loot_key: "enemy_mid",
        ai: { scan_radius: 64, think_rate: 8, forget_delay: 45, leash_mult: 4, wander_chance: 2, move_speed: 1.2 },
        skills: [SKILL_BLOODTHIRSTY],
        brain: AI_Brain(
            [ AI_Rule("howl_first", [AI_Cond("self_missing_status", 0, STATUS_BLOODTHIRSTY)], "skill", SKILL_BLOODTHIRSTY, 0.5) ],
            [ AI_Weight("attack", -1, 1) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_GHOSTSWORD] = {
        id: ENEMY_GHOSTSWORD,
        name: "Ghost Sword",
        level: 6,
        stats: { atk: 14, def: 12, spd: 12, mag: 10 },
        base_hp: 15,
        base_mp: 4,
        hd: 8,
        mp_gain: 1,
        weapon_id: 0,
        sprite: ghost_sword_profile,
        sprite_world: ghost_sword_moving,
        exp: 38,
        species_min_level: 6,
        species_max_level: 8,
        species_level_offset: 0,
        threat_rank: 2,
        basic_power: 7,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.70,
        loot_key: "enemy_mid",
        ai: { scan_radius: 40, think_rate: 1, forget_delay: 60, leash_mult: 4, wander_chance: 0, move_speed: 3 },
        skills: [SKILL_GHOST_CUT],
        brain: AI_Brain(
            [ AI_Rule("cut_every_3rd", [AI_Cond("every_nth", 3)], "skill", SKILL_GHOST_CUT) ],
            [ AI_Weight("attack", -1, 1) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_STRANGER] = {
        id: ENEMY_STRANGER,
        name: "Stranger",
        level: 7,
        stats: { atk: 16, def: 14, spd: 13, mag: 15 },
        base_hp: 18,
        base_mp: 8,
        hd: 8,
        mp_gain: 2,
        weapon_id: 0,
        sprite: stranger_profile,
        sprite_world: stranger_moving,
        exp: 50,
        species_min_level: 7,
        species_max_level: 9,
        species_level_offset: 0,
        threat_rank: 2,
        basic_power: 7,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.65,
        loot_key: "enemy_elite",
        ai: { scan_radius: 88, think_rate: 8, forget_delay: 80, leash_mult: 5, wander_chance: 1, move_speed: 1.3 },
        skills: [SKILL_STEAL],
        brain: AI_Brain(
            [ AI_Rule("grab_when_hurt", [AI_Cond("hp_below", 0.5)], "skill", SKILL_STEAL, 1, 1) ],
            [ AI_Weight("attack", -1, 5), AI_Weight("skill", SKILL_STEAL, 1) ]),
        traits: [],
        is_boss: false
    };

    global.enemy_db[? ENEMY_MINI_BOSS] = {
        id: ENEMY_MINI_BOSS,
        name: "Palehorn",
        level: 8,
        stats: { atk: 18, def: 18, spd: 12, mag: 14 },
        base_hp: 55,
        base_mp: 8,
        hd: 10,
        mp_gain: 2,
        weapon_id: 0,
        sprite: mini_boss_profile,
        sprite_world: mini_boss_moving,
        exp: 75,
        species_min_level: 8,
        species_max_level: 9,
        species_level_offset: 0,
        threat_rank: 3,
        basic_power: 7,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 1.00,
        loot_key: "enemy_boss",
        ai: { scan_radius: 64, think_rate: 8, forget_delay: 60, leash_mult: 4, wander_chance: 0, move_speed: 1.15 },
        skills: [SKILL_RAMMING, SKILL_GORE],
        brain: AI_Brain(
            [ AI_Rule("ram_every_3rd", [AI_Cond("every_nth", 3)], "skill", SKILL_RAMMING) ],
            [ AI_Weight("attack", -1, 1) ],
            [ AI_Phase(0.6, 2, 0, "mini_boss.1", "{enemy} paws the ground, snorting!",
                  [ AI_Rule("ram_every_3rd", [AI_Cond("every_nth", 3)], "skill", SKILL_RAMMING) ],
                  [ AI_Weight("attack", -1, 2), AI_Weight("skill", SKILL_GORE, 1) ]),
              AI_Phase(0.3, 2, 3, "mini_boss.2", "{enemy} bellows in a blind rage!",
                  [ AI_Rule("ram_every_2nd", [AI_Cond("every_nth", 2)], "skill", SKILL_RAMMING) ],
                  [ AI_Weight("attack", -1, 1), AI_Weight("skill", SKILL_GORE, 2) ]) ]),
        traits: [],
        is_boss: true
    };

    global.enemy_db[? ENEMY_FINAL_BOSS] = {
        id: ENEMY_FINAL_BOSS,
        name: "The Pale Choirbeast",
        level: 10,
        stats: { atk: 21, def: 24, spd: 14, mag: 19 },
        base_hp: 140,
        base_mp: 12,
        hd: 10,
        mp_gain: 3,
        weapon_id: 0,
        sprite: final_boss_profile,
        sprite_world: final_boss_moving,
        exp: 110,
        species_min_level: 10,
        species_max_level: 10,
        species_level_offset: 0,
        threat_rank: 4,
        basic_power: 14,
        can_auto_resolve: false,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 1.00,
        loot_key: "enemy_boss",
        ai: { scan_radius: 0, think_rate: 30, forget_delay: 0, leash_mult: 1, wander_chance: 0, move_speed: 1 },
        skills: [SKILL_CURSE, SKILL_BLESSING, SKILL_PALE_HYMN],
        brain: AI_Brain(
            [ AI_Rule("hymn_every_4th", [AI_Cond("every_nth", 4)], "skill", SKILL_PALE_HYMN) ],
            [ AI_Weight("attack", -1, 3), AI_Weight("skill", SKILL_CURSE, 1) ],
            [ AI_Phase(0.6, 2, 0, "final_boss.1", "{enemy} sings a second voice!",
                  [ AI_Rule("bless_when_bare", [AI_Cond("self_missing_status", 0, STATUS_BLESSING)], "skill", SKILL_BLESSING, 0.5),
                    AI_Rule("hymn_every_3rd", [AI_Cond("every_nth", 3)], "skill", SKILL_PALE_HYMN) ],
                  [ AI_Weight("attack", -1, 2), AI_Weight("skill", SKILL_CURSE, 1) ]),
              AI_Phase(0.3, 3, 3, "final_boss.2", "{enemy} howls in fury!",
                  [ AI_Rule("hymn_every_2nd", [AI_Cond("every_nth", 2)], "skill", SKILL_PALE_HYMN) ],
                  [ AI_Weight("attack", -1, 2), AI_Weight("skill", SKILL_CURSE, 1) ]) ]),
        traits: [],
        is_boss: true
    };

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.enemy_db = global.enemy_db;
    }
}

// ---- the decision (pure: the enemy, the player, a context and a random stream in; a choice out) ----
function EnemyAI_KnownCond(_c) {
    switch (_c) {
        case "always": case "hp_below": case "hp_above": case "player_hp_below": case "player_buffed":
        case "player_has_status": case "player_missing_status": case "player_status_at_least":
        case "self_has_status": case "self_missing_status": case "every_nth":
            return true;
    }
    return false;
}

function EnemyAI_HpRatio(_ch) {
    return (_ch.max_hp > 0) ? (_ch.hp / _ch.max_hp) : 1;
}

function EnemyAI_CondHolds(_cond, _e, _p, _ctx) {
    var eps = 0.000001;
    switch (_cond.c) {
        case "always": return true;
        case "hp_below": return EnemyAI_HpRatio(_e) <= _cond.v + eps;
        case "hp_above": return EnemyAI_HpRatio(_e) >= _cond.v - eps;
        case "player_hp_below": return EnemyAI_HpRatio(_p) <= _cond.v + eps;
        case "player_buffed":
            if (is_array(_p.status)) {
                for (var i = 0; i < array_length(_p.status); i++) {
                    if (!Status_IsNegative(_p.status[i].id)) return true;
                }
            }
            return false;
        case "player_has_status": return Status_Has(_p, _cond.status);
        case "player_missing_status": return !Status_Has(_p, _cond.status);
        case "player_status_at_least": return Status_Stacks(_p, _cond.status) >= _cond.v;
        case "self_has_status": return Status_Has(_e, _cond.status);
        case "self_missing_status": return !Status_Has(_e, _cond.status);
        case "every_nth": return (_cond.v >= 2) && ((_ctx.turn mod _cond.v) == 0);
    }
    return false;
}

// The rules and weights in force: phase 0 = the base lists, phase n = the lists of phase n (they replace the base completely).
function EnemyAI_Lists(_brain, _phase) {
    if (_phase >= 1 && _phase <= array_length(_brain.phases)) {
        var ph = _brain.phases[_phase - 1];
        return { rules: ph.rules, weights: ph.weights };
    }
    return { rules: _brain.rules, weights: _brain.weights };
}

// Can the enemy do this now? The basic attack always; a skill when it has it and the skill's own gates (HP ratio, status missing, inventory, once per turn) pass.
function EnemyAI_Usable(_e, _p, _ctx, _act, _skill) {
    if (_act == "attack") return true;
    if (_act != "skill") return false;
    if (!is_array(_e.skills) || !array_contains(_e.skills, _skill)) return false;
    var sk = SkillDB_Get(_skill);
    if (!is_struct(sk) || sk.id == -1) return false;
    if (variable_struct_exists(sk, "enemy_passive_action_budget") && sk.enemy_passive_action_budget) return false;
    if (variable_struct_exists(sk, "enemy_once_per_turn") && sk.enemy_once_per_turn && array_contains(_ctx.used_turn, _skill)) return false;
    if (!Skill_CanUse(_e, sk)) return false;
    return Skill_EnemyCanTrigger(sk, _e, _p, _ctx.actions_left);
}

// kind "windup" when the chosen skill is a telegraphed heavy move (unless the debug damage-only switch is on).
function EnemyAI_Result(_skill, _rule, _force = false) {
    var kind = "attack";
    if (_skill >= 0) {
        kind = "skill";
        var sk = SkillDB_Get(_skill);
        if (!_force && is_struct(sk) && variable_struct_exists(sk, "telegraphed") && sk.telegraphed) kind = "windup";
    }
    return { kind: kind, skill_id: _skill, rule: _rule };
}

function EnemyAI_Choose(_e, _p, _ctx, _rng) {
    // 1. the wind-up has been paid: the big attack comes, nothing is drawn
    if (_ctx.windup >= 0) return { kind: "skill", skill_id: _ctx.windup, rule: "windup_attack" };

    // debug switch: one usable damaging skill of the lists in force, no wind-up
    if (_ctx.force_damage_only) {
        var dmg = [];
        if (is_array(_e.skills) && variable_struct_exists(_e, "brain") && is_struct(_e.brain)) {
            var fl = EnemyAI_Lists(_e.brain, _ctx.phase);
            var named = [];
            for (var fr = 0; fr < array_length(fl.rules); fr++) { if (fl.rules[fr].act == "skill") array_push(named, fl.rules[fr].skill); }
            for (var fw = 0; fw < array_length(fl.weights); fw++) { if (fl.weights[fw].act == "skill") array_push(named, fl.weights[fw].skill); }
            for (var i = 0; i < array_length(_e.skills); i++) {
                var dsk = SkillDB_Get(_e.skills[i]);
                if (is_struct(dsk) && dsk.id != -1 && string(dsk.effect) == "damage" && array_contains(named, _e.skills[i]) && EnemyAI_Usable(_e, _p, _ctx, "skill", _e.skills[i])) array_push(dmg, _e.skills[i]);
            }
        }
        if (array_length(dmg) <= 0) return { kind: "attack", skill_id: -1, rule: "default" };
        return EnemyAI_Result(dmg[Rng_Int(_rng, array_length(dmg))], "default", true);
    }

    if (!variable_struct_exists(_e, "brain") || !is_struct(_e.brain)) return { kind: "attack", skill_id: -1, rule: "default" };
    var lists = EnemyAI_Lists(_e.brain, _ctx.phase);

    // 3. the rules, in order
    for (var r = 0; r < array_length(lists.rules); r++) {
        var rule = lists.rules[r];
        var holds = true;
        for (var c = 0; c < array_length(rule.when); c++) {
            if (!EnemyAI_CondHolds(rule.when[c], _e, _p, _ctx)) { holds = false; break; }
        }
        if (!holds) continue;
        if (rule.max_uses >= 0) {
            var used = variable_struct_exists(_ctx.uses, rule.label) ? variable_struct_get(_ctx.uses, rule.label) : 0;
            if (used >= rule.max_uses) continue;
        }
        if (!EnemyAI_Usable(_e, _p, _ctx, rule.act, rule.skill)) continue;
        if (rule.chance < 1 && Rng_Float(_rng) >= rule.chance) continue;
        return EnemyAI_Result((rule.act == "skill") ? rule.skill : -1, rule.label);
    }

    // 4. the weighted default
    var total = 0;
    for (var w = 0; w < array_length(lists.weights); w++) {
        var wt = lists.weights[w];
        if (wt.w > 0 && EnemyAI_Usable(_e, _p, _ctx, wt.act, wt.skill)) total += wt.w;
    }
    if (total <= 0) return { kind: "attack", skill_id: -1, rule: "default" };
    var roll = Rng_Float(_rng) * total;
    for (var w2 = 0; w2 < array_length(lists.weights); w2++) {
        var wt2 = lists.weights[w2];
        if (wt2.w <= 0 || !EnemyAI_Usable(_e, _p, _ctx, wt2.act, wt2.skill)) continue;
        if (roll < wt2.w) return EnemyAI_Result((wt2.act == "skill") ? wt2.skill : -1, "default");
        roll -= wt2.w;
    }
    return { kind: "attack", skill_id: -1, rule: "default" };
}

// ---- the battle AI state (kept on the battle controller as `ai`): own turn counter, rule uses, the pending wind-up, the boss phase ----
function EnemyAI_StateNew() {
    return { turns: 0, phase: 0, uses: {}, windup: -1 };
}

function EnemyAI_Ctx(_st, _actions_left = 1, _used_turn = [], _force = false) {
    return { turn: _st.turns + 1, phase: _st.phase, uses: _st.uses, windup: _st.windup, used_turn: _used_turn, actions_left: _actions_left, force_damage_only: _force };
}

// The enemy does what EnemyAI_Choose said: a rule use is counted (max_uses), a wind-up is remembered, the big attack that follows it ends it.
function EnemyAI_Take(_st, _choice) {
    if (_choice.rule != "default" && _choice.rule != "windup_attack") {
        var n = variable_struct_exists(_st.uses, _choice.rule) ? variable_struct_get(_st.uses, _choice.rule) : 0;
        variable_struct_set(_st.uses, _choice.rule, n + 1);
    }
    if (_choice.kind == "windup") _st.windup = _choice.skill_id;
    else if (_choice.rule == "windup_attack") _st.windup = -1;
}

function EnemyAI_EndTurn(_st) {
    _st.turns += 1;
}

// A BREAK during a wind-up cancels the big attack (D75). Returns the cancelled skill id, or -1 when nothing was winding up.
function EnemyAI_Break(_st) {
    var w = _st.windup;
    _st.windup = -1;
    return w;
}

// How many phases the HP ratio has reached (phases are ordered by falling `at`).
function EnemyAI_PhaseFor(_brain, _ratio) {
    var n = 0;
    for (var i = 0; i < array_length(_brain.phases); i++) {
        if (_brain.phases[i].at + 0.000001 >= _ratio) n = i + 1;
    }
    return n;
}

// Moves the phase forward (never back): every phase reached adds its SPD / ATK to the enemy stats. Returns { changed, phase, banner }.
function EnemyAI_PhaseSync(_st, _e) {
    var out = { changed: false, phase: _st.phase, banner: "" };
    if (!variable_struct_exists(_e, "brain") || !is_struct(_e.brain)) return out;
    var target = EnemyAI_PhaseFor(_e.brain, EnemyAI_HpRatio(_e));
    if (target <= _st.phase) return out;
    var last = undefined;
    for (var k = _st.phase + 1; k <= target; k++) {
        var ph = _e.brain.phases[k - 1];
        _e.stats.spd = _e.stats.spd + ph.spd_add;
        _e.stats.atk = _e.stats.atk + ph.atk_add;
        last = ph;
    }
    _st.phase = target;
    out.changed = true;
    out.phase = target;
    out.banner = Loc_T("combat.msg.phase." + last.banner, last.banner_text, { enemy: _e.name });
    return out;
}

function EnemyDB_Get(_enemy_id) {
    if (!variable_global_exists("enemy_db") || !ds_exists(global.enemy_db, ds_type_map)) {
        EnemyDB_Init();
    }
    if (ds_map_exists(global.enemy_db, _enemy_id)) {
        return Enemy_LocalizeRuntime(global.enemy_db[? _enemy_id], _enemy_id);
    }

    return {
        id: -1,
        name: Loc_T("enemy.name.unknown", "Unknown"),
        level: 1,
        stats: { atk: 10, def: 10, spd: 10, mag: 10 },
        base_hp: 10,
        base_mp: 0,
        hd: 6,
        mp_gain: 0,
        weapon_id: 0,
        sprite: slime_profile,
        sprite_world: noone,
        exp: 1,
        species_min_level: 1,
        species_max_level: LEVEL_CAP_TECHNICAL,
        species_level_offset: 0,
        threat_rank: 1,
        basic_power: 3,
        can_auto_resolve: true,
        auto_resolve_exp_mult: 0.35,
        auto_resolve_loot_mult: 0.85,
        loot_key: "enemy_basic",
        ai: { scan_radius: ENEMY_SCAN_RADIUS_DEFAULT, think_rate: 15, forget_delay: 30, leash_mult: 2, wander_chance: 4, move_speed: 1 },
        skills: [],
        brain: AI_Brain([], [ AI_Weight("attack", -1, 1) ]),
        traits: [],
        is_boss: false
    };
}

function Enemy_LocalizationKey(_enemy_id) {
    switch (_enemy_id) {
        case ENEMY_SLIME: return "enemy_slime";
        case ENEMY_DIREWOLF: return "enemy_direwolf";
        case ENEMY_GHOSTSWORD: return "enemy_ghostsword";
        case ENEMY_SPIDER: return "enemy_spider";
        case ENEMY_MADWHISP: return "enemy_madwhisp";
        case ENEMY_SNAKE: return "enemy_snake";
        case ENEMY_KILLER_PLANT: return "enemy_killer_plant";
        case ENEMY_STRANGER: return "enemy_stranger";
        case ENEMY_MINI_BOSS: return "enemy_mini_boss";
        case ENEMY_FINAL_BOSS: return "enemy_final_boss";
    }
    return "unknown";
}

function Enemy_LocalizeRuntime(_enemy, _enemy_id = -1) {
    if (!is_struct(_enemy)) return _enemy;

    var eid = _enemy_id;
    if (eid == -1 && variable_struct_exists(_enemy, "id")) eid = _enemy.id;
    var key_suffix = Enemy_LocalizationKey(eid);

    if (!variable_struct_exists(_enemy, "name_en")) _enemy.name_en = string(_enemy.name);
    _enemy.name = Loc_T("enemy.name." + key_suffix, string(_enemy.name_en));
    return _enemy;
}

function DB_Enemy(_enemy_id) {
    return EnemyDB_Get(_enemy_id);
}
