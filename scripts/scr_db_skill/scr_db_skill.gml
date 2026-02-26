function SkillDB_Init() {
    if (variable_global_exists("skill_db") && ds_exists(global.skill_db, ds_type_map)) return;
    global.skill_db = ds_map_create();

    // Warrior skills
    global.skill_db[? SKILL_WOUND] = {
        id: SKILL_WOUND,
        name: "Wound",
        mp_cost: 3,
        power: 2,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 2,
        status_chance: 0.75,
        icon_sprite: noone,
        fx_sprite: bleed_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [CLASS_KNIGHT, CLASS_ARCHER]
    };

    global.skill_db[? SKILL_HILT_BASH] = {
        id: SKILL_HILT_BASH,
        name: "Hilt Bash",
        mp_cost: 4,
        power: 2,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_STUN,
        status_turns: 1,
        status_chance: 0.6,
        icon_sprite: noone,
        fx_sprite: stun_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [CLASS_KNIGHT]
    };

    global.skill_db[? SKILL_MUSCLE_UP] = {
        id: SKILL_MUSCLE_UP,
        name: "Muscle Up",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_GUARD,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: muscle_up_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [CLASS_KNIGHT]
    };

    global.skill_db[? SKILL_REV_UP] = {
        id: SKILL_REV_UP,
        name: "Rev Up",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_DMG_UP,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: rev_up_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [CLASS_KNIGHT]
    };

    global.skill_db[? SKILL_HORIZ_SLASH] = {
        id: SKILL_HORIZ_SLASH,
        name: "Horizontal Slash",
        mp_cost: 5,
        power: 3,
        power_mult: 1.5,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: noone,
        fx_sprite: horizontal_slash_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [CLASS_KNIGHT]
    };

    // Archer skills
    global.skill_db[? SKILL_POISON_ARROW] = {
        id: SKILL_POISON_ARROW,
        name: "Poison Arrow",
        mp_cost: 4,
        power: 3,
        power_mult: 1,
        stat_type: STAT_AGI,
        acc: 1,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 2,
        status_chance: 0.75,
        icon_sprite: noone,
        fx_sprite: poison_shot_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [CLASS_ARCHER]
    };

    global.skill_db[? SKILL_EVASION] = {
        id: SKILL_EVASION,
        name: "Evasion",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_AGI,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_EVASION,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: evasion_up_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [CLASS_ARCHER]
    };

    global.skill_db[? SKILL_DOUBLE_SHOT] = {
        id: SKILL_DOUBLE_SHOT,
        name: "Double Shot",
        mp_cost: 5,
        power: 2,
        power_mult: 1,
        stat_type: STAT_AGI,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: noone,
        fx_sprite: double_shot_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 2,
        class_list: [CLASS_ARCHER]
    };

    global.skill_db[? SKILL_TAKE_AIM] = {
        id: SKILL_TAKE_AIM,
        name: "Take Aim",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_AGI,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_CRIT_UP,
        status_turns: 3,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: take_aim_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [CLASS_ARCHER]
    };

    // Mage skills
    global.skill_db[? SKILL_FIREBALL] = {
        id: SKILL_FIREBALL,
        name: "Fireball",
        mp_cost: 4,
        power: 4,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_BURN,
        status_turns: 2,
        status_chance: 0.6,
        icon_sprite: noone,
        fx_sprite: explosion_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [CLASS_MAGE]
    };

    global.skill_db[? SKILL_POISON_MIST] = {
        id: SKILL_POISON_MIST,
        name: "Poison Mist",
        mp_cost: 4,
        power: 2,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 2,
        status_chance: 0.75,
        icon_sprite: noone,
        fx_sprite: poison_mist_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [CLASS_MAGE]
    };

    global.skill_db[? SKILL_ICE_SPEAR] = {
        id: SKILL_ICE_SPEAR,
        name: "Ice Spear",
        mp_cost: 5,
        power: 3,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_STUN,
        status_turns: 1,
        status_chance: 0.6,
        icon_sprite: noone,
        fx_sprite: ice_spear_effect,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [CLASS_MAGE]
    };

    global.skill_db[? SKILL_MEDITATION] = {
        id: SKILL_MEDITATION,
        name: "Meditation",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_MEDITATION,
        status_turns: 3,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: meditation,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [CLASS_MAGE]
    };

    global.skill_db[? SKILL_FORESIGHT] = {
        id: SKILL_FORESIGHT,
        name: "Foresight",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_HIT_UP,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: foresight_effect_Sheet,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [CLASS_MAGE]
    };

    // Enemy abilities
    global.skill_db[? SKILL_POISON_FANGS] = {
        id: SKILL_POISON_FANGS,
        name: "Poison Fangs",
        mp_cost: 0,
        power: 2,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [],
        enemy_use_chance_min: 0.10,
        enemy_use_chance_max: 0.25
    };

    global.skill_db[? SKILL_SOLIDIFY] = {
        id: SKILL_SOLIDIFY,
        name: "Solidify",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_DEF,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_SOLIDIFY,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_use_chance_min: 0.10,
        enemy_use_chance_max: 0.25
    };

    global.skill_db[? SKILL_BITE] = {
        id: SKILL_BITE,
        name: "Bite",
        mp_cost: 0,
        power: 2,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [],
        enemy_use_chance_min: 0.25,
        enemy_use_chance_max: 0.30
    };

    global.skill_db[? SKILL_BLOODTHIRSTY] = {
        id: SKILL_BLOODTHIRSTY,
        name: "Bloodthirsty",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_BLOODTHIRSTY,
        status_turns: 3,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_use_chance_min: 0.20,
        enemy_use_chance_max: 0.30
    };

    global.skill_db[? SKILL_VINE_TRAP] = {
        id: SKILL_VINE_TRAP,
        name: "Vine Trap",
        mp_cost: 0,
        power: 2,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_STUN,
        status_turns: 1,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [],
        enemy_use_chance_min: 0.20,
        enemy_use_chance_max: 0.20
    };

    global.skill_db[? SKILL_SCORCHING_TOUCH] = {
        id: SKILL_SCORCHING_TOUCH,
        name: "Scorching Touch",
        mp_cost: 0,
        power: 3,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_BURN,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [],
        enemy_use_chance_min: 0.40,
        enemy_use_chance_max: 0.40
    };

    global.skill_db[? SKILL_GHOST_CUT] = {
        id: SKILL_GHOST_CUT,
        name: "Cut",
        mp_cost: 0,
        power: 3,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [],
        enemy_use_chance_min: 0.50,
        enemy_use_chance_max: 0.50
    };

    global.skill_db[? SKILL_STEAL] = {
        id: SKILL_STEAL,
        name: "Steal",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_AGI,
        acc: 0,
        target: TGT_ENEMY,
        effect: "steal_item",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_use_chance_min: 0.25,
        enemy_use_chance_max: 0.25,
        enemy_require_target_inventory: true
    };

    global.skill_db[? SKILL_RAMMING] = {
        id: SKILL_RAMMING,
        name: "Ramming",
        mp_cost: 0,
        power: 4,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 1,
        status_list: [STATUS_STUN, STATUS_BLEED],
        status_turns_list: [1, 2],
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [],
        enemy_use_chance_min: 0.40,
        enemy_use_chance_max: 0.40
    };

    global.skill_db[? SKILL_RAMPAGE] = {
        id: SKILL_RAMPAGE,
        name: "Rampage",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: -1,
        status_turns: 0,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        use_msg: "It goes berserk!",
        free_action: true,
        set_enemy_actions: 2,
        enemy_require_actions_below: 2,
        enemy_once_per_turn: true,
        enemy_use_chance_min: 0.20,
        enemy_use_chance_max: 0.30
    };

    global.skill_db[? SKILL_CURSE] = {
        id: SKILL_CURSE,
        name: "Curse",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_ENEMY,
        effect: "multi_status",
        status: -1,
        status_turns: 2,
        status_chance: 1,
        status_list: [STATUS_BURN, STATUS_POISON, STATUS_STUN, STATUS_BLEED],
        status_turns_list: [2, 2, 1, 2],
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_use_chance_min: 0.30,
        enemy_use_chance_max: 0.30
    };

    global.skill_db[? SKILL_BLESSING] = {
        id: SKILL_BLESSING,
        name: "Blessing",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_DEF,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_BLESSING,
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        free_action: true,
        enemy_use_chance_min: 0.30,
        enemy_use_chance_max: 0.30,
        enemy_hp_below_ratio: 0.8
    };

    global.skill_db[? SKILL_FINAL_FURY] = {
        id: SKILL_FINAL_FURY,
        name: "Fury",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: -1,
        status_turns: 0,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        free_action: true,
        set_enemy_actions: 2,
        enemy_passive_action_budget: true,
        enemy_hp_below_ratio: 0.5
    };

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.skill_db = global.skill_db;
    }
}

function SkillDB_Get(_skill_id) {
    if (!variable_global_exists("skill_db") || !ds_exists(global.skill_db, ds_type_map)) {
        SkillDB_Init();
    }
    if (ds_map_exists(global.skill_db, _skill_id)) {
        return global.skill_db[? _skill_id];
    }
    return {
        id: -1,
        name: "Unknown",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        status_list: [],
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: [],
        enemy_use_chance_min: ENEMY_SKILL_USE_CHANCE_DEFAULT,
        enemy_use_chance_max: ENEMY_SKILL_USE_CHANCE_DEFAULT,
        free_action: false,
        extra_turns: 0,
        set_enemy_actions: 0
    };
}

function Skill_ClassAllowed(_skill, _class_id) {
    if (!variable_struct_exists(_skill, "class_list")) return true;
    if (!is_array(_skill.class_list) || array_length(_skill.class_list) == 0) return true;
    for (var i = 0; i < array_length(_skill.class_list); i++) {
        if (_skill.class_list[i] == _class_id) return true;
    }
    return false;
}

function Skill_CanUse(_ch, _skill) {
    if (_ch.mp < _skill.mp_cost) return false;
    if (variable_struct_exists(_ch, "is_player") && _ch.is_player) {
        if (variable_struct_exists(_ch, "class_id") && !Skill_ClassAllowed(_skill, _ch.class_id)) return false;
    }
    return true;
}

function Skill_EnemyCanTrigger(_skill, _user, _target, _actions_remaining = -1) {
    if (variable_struct_exists(_skill, "enemy_hp_below_ratio")) {
        var hp_below = clamp(real(_skill.enemy_hp_below_ratio), 0, 1);
        var ur = (_user.max_hp > 0) ? (_user.hp / _user.max_hp) : 1;
        if (ur > hp_below) return false;
    }
    if (variable_struct_exists(_skill, "enemy_hp_above_ratio")) {
        var hp_above = clamp(real(_skill.enemy_hp_above_ratio), 0, 1);
        var ur2 = (_user.max_hp > 0) ? (_user.hp / _user.max_hp) : 1;
        if (ur2 < hp_above) return false;
    }
    if (variable_struct_exists(_skill, "enemy_require_target_inventory") && _skill.enemy_require_target_inventory) {
        if (!variable_struct_exists(_target, "inventory") || !is_array(_target.inventory) || array_length(_target.inventory) <= 0) return false;
    }
    if (variable_struct_exists(_skill, "enemy_require_status_missing")) {
        var sid = round(real(_skill.enemy_require_status_missing));
        if (sid != -1 && Status_Has(_user, sid)) return false;
    }
    if (_actions_remaining >= 0 && variable_struct_exists(_skill, "enemy_require_actions_below")) {
        var lim = max(0, round(real(_skill.enemy_require_actions_below)));
        if (_actions_remaining >= lim) return false;
    }
    return true;
}

function Skill_EnemyUseChance(_skill) {
    var cmin = ENEMY_SKILL_USE_CHANCE_DEFAULT;
    var cmax = ENEMY_SKILL_USE_CHANCE_DEFAULT;
    if (variable_struct_exists(_skill, "enemy_use_chance_min")) cmin = real(_skill.enemy_use_chance_min);
    if (variable_struct_exists(_skill, "enemy_use_chance_max")) cmax = real(_skill.enemy_use_chance_max);
    if (cmax < cmin) {
        var tmp = cmin;
        cmin = cmax;
        cmax = tmp;
    }
    return clamp(random_range(cmin, cmax), 0, 1);
}

function Skill_Use(_user, _target, _skill_id) {
    var s = SkillDB_Get(_skill_id);
    var result = {
        ok: true,
        hit: true,
        dmg: 0,
        crit: false,
        msg: "",
        fx_sprite: s.fx_sprite,
        fx_frames: s.fx_frames,
        fx_speed: s.fx_speed * SKILL_FX_SPEED_MULT,
        free_action: (variable_struct_exists(s, "free_action") && s.free_action),
        extra_turns: variable_struct_exists(s, "extra_turns") ? max(0, round(real(s.extra_turns))) : 0,
        set_enemy_actions: variable_struct_exists(s, "set_enemy_actions") ? max(0, round(real(s.set_enemy_actions))) : 0
    };

    if (_user.mp < s.mp_cost) {
        result.ok = false;
        result.msg = "Not enough MP.";
        return result;
    }

    if (variable_struct_exists(_user, "is_player") && _user.is_player) {
        if (variable_struct_exists(_user, "class_id") && !Skill_ClassAllowed(s, _user.class_id)) {
            result.ok = false;
            result.msg = "Can't use that.";
            return result;
        }
    }

    _user.mp -= s.mp_cost;

    var status_turns_default = variable_struct_exists(s, "status_turns") ? max(1, round(real(s.status_turns))) : 1;
    var applied_status_names = [];
    var applied_any_status = false;

    // status-only skills
    if (s.effect == "status") {
        if (s.status != -1) {
            _target = Status_Add(_target, s.status, status_turns_default, 1);
            var cfg = StatusDB_Get(s.status);
            if (is_struct(cfg) && variable_struct_exists(cfg, "name")) {
                array_push(applied_status_names, cfg.name);
                applied_any_status = true;
            }
        } else {
            if (variable_struct_exists(s, "use_msg")) result.msg = string(s.use_msg);
            else result.msg = "Skill used.";
        }

        if (applied_any_status) {
            var msg_status = "Applied ";
            for (var si = 0; si < array_length(applied_status_names); si++) {
                if (si > 0) msg_status += ", ";
                msg_status += applied_status_names[si];
            }
            result.msg = msg_status + ".";
        }
        return result;
    }

    if (s.effect == "multi_status") {
        if (variable_struct_exists(s, "status_list") && is_array(s.status_list)) {
            var turns_list = variable_struct_exists(s, "status_turns_list") && is_array(s.status_turns_list) ? s.status_turns_list : [];
            for (var m = 0; m < array_length(s.status_list); m++) {
                var sid_m = s.status_list[m];
                if (sid_m == -1) continue;
                var turns_m = status_turns_default;
                if (m < array_length(turns_list)) turns_m = max(1, round(real(turns_list[m])));
                _target = Status_Add(_target, sid_m, turns_m, 1);
                var cfg_m = StatusDB_Get(sid_m);
                if (is_struct(cfg_m) && variable_struct_exists(cfg_m, "name")) {
                    array_push(applied_status_names, cfg_m.name);
                    applied_any_status = true;
                }
            }
        }

        if (applied_any_status) {
            var msg_status2 = "Applied ";
            for (var sm = 0; sm < array_length(applied_status_names); sm++) {
                if (sm > 0) msg_status2 += ", ";
                msg_status2 += applied_status_names[sm];
            }
            result.msg = msg_status2 + ".";
        } else if (variable_struct_exists(s, "use_msg")) {
            result.msg = string(s.use_msg);
        } else {
            result.msg = "Skill used.";
        }
        return result;
    }

    if (s.effect == "steal_item") {
        if (!variable_struct_exists(_target, "inventory") || !is_array(_target.inventory) || array_length(_target.inventory) <= 0) {
            result.msg = "Nothing to steal.";
            return result;
        }

        var pick = irandom(array_length(_target.inventory) - 1);
        var inv = _target.inventory[pick];
        if (!is_struct(inv) || !variable_struct_exists(inv, "id")) {
            result.msg = "Nothing to steal.";
            return result;
        }
        var stolen_item = ItemDB_Get(inv.id);
        _target.inventory = Inv_Remove(_target.inventory, inv.id, 1);
        if (is_struct(stolen_item) && variable_struct_exists(stolen_item, "name")) {
            result.msg = "Stole " + string(stolen_item.name) + ".";
        } else {
            result.msg = "Stole an item.";
        }
        return result;
    }

    // damage/heal skills
    if (s.effect == "damage") {
        var hits = 1;
        if (variable_struct_exists(s, "hits")) hits = max(1, s.hits);

        var any_hit = false;
        var any_crit = false;
        var total_dmg = 0;

        var crit_bonus = Status_GetSum(_user, "crit_bonus");
        var acc_bonus = s.acc + StatMod(Combat_EffectiveStat(_user, s.stat_type));

        for (var h = 0; h < hits; h++) {
            var hit_res = Combat_AttemptHit(_user, _target, acc_bonus);
            _target = hit_res.defender;

            if (hit_res.hit) {
                var weapon = { power: s.power, stat_type: s.stat_type, acc: s.acc };
                var crit = Combat_CritCheck(_user, crit_bonus);
                var dmg_pack = Combat_ApplyDamage(_user, _target, weapon, (crit ? 2 : 1), s.power_mult);
                _target = dmg_pack.defender;

                any_hit = true;
                if (crit) any_crit = true;
                total_dmg += dmg_pack.dmg;
            }
        }

        result.hit = any_hit;
        result.crit = any_crit;
        result.dmg = total_dmg;

        // consume attack-based buffs after the action
        _user = Status_ConsumeByField(_user, "consume_on_attack");

        var status_chance = variable_struct_exists(s, "status_chance") ? real(s.status_chance) : 1;
        if (!variable_struct_exists(_user, "is_player") || !_user.is_player) {
            status_chance = clamp(status_chance * Combat_EffectiveEnemyStatusChanceMult(), 0, 1);
        }

        if (s.status != -1 && any_hit) {
            if (status_chance >= 1 || random(1) <= status_chance) {
                _target = Status_Add(_target, s.status, status_turns_default, 1);
                var cfg2 = StatusDB_Get(s.status);
                if (is_struct(cfg2) && variable_struct_exists(cfg2, "name")) {
                    array_push(applied_status_names, cfg2.name);
                    applied_any_status = true;
                }
            }
        }

        if (variable_struct_exists(s, "status_list") && is_array(s.status_list) && any_hit) {
            var turns_list_d = variable_struct_exists(s, "status_turns_list") && is_array(s.status_turns_list) ? s.status_turns_list : [];
            if (status_chance >= 1 || random(1) <= status_chance) {
                for (var sd = 0; sd < array_length(s.status_list); sd++) {
                    var sid_d = s.status_list[sd];
                    if (sid_d == -1) continue;
                    var turns_d = status_turns_default;
                    if (sd < array_length(turns_list_d)) turns_d = max(1, round(real(turns_list_d[sd])));
                    _target = Status_Add(_target, sid_d, turns_d, 1);
                    var cfg_d = StatusDB_Get(sid_d);
                    if (is_struct(cfg_d) && variable_struct_exists(cfg_d, "name")) {
                        array_push(applied_status_names, cfg_d.name);
                        applied_any_status = true;
                    }
                }
            }
        }

        if (applied_any_status) {
            var msg_status3 = "Applied ";
            for (var sj = 0; sj < array_length(applied_status_names); sj++) {
                if (sj > 0) msg_status3 += ", ";
                msg_status3 += applied_status_names[sj];
            }
            result.msg = msg_status3 + ".";
        } else if (variable_struct_exists(s, "use_msg")) {
            result.msg = string(s.use_msg);
        }
    }

    if (s.effect == "heal") {
        var amt = s.power + max(0, StatMod(Combat_EffectiveStat(_user, s.stat_type)));
        _target.hp = clamp(_target.hp + amt, 0, _target.max_hp);
        result.dmg = -amt;
        if (variable_struct_exists(s, "use_msg")) result.msg = string(s.use_msg);
    }

    if (result.msg == "" && variable_struct_exists(s, "use_msg")) {
        result.msg = string(s.use_msg);
    }

    return result;
}
