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
    // Note: target uses relative aliases:
    // - TGT_OPPONENT means "whoever the skill user's opponent is"
    // - TGT_SELF means the enemy buffs itself
    global.skill_db[? SKILL_POISON_FANGS] = {
        id: SKILL_POISON_FANGS,
        name: "Poison Fangs",
        mp_cost: 0,
        power: 2,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 2,
        status_chance: 0.70,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_poison_fangs",
        sfx_candidates: ["Bite_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
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
        status_turns: 1,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_solidify",
        sfx_candidates: ["Liquid _slosh", "Liquid_slosh"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_require_status_missing: STATUS_SOLIDIFY,
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
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 2,
        status_chance: 0.75,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_bite",
        sfx_candidates: ["Bite_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
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
        status_turns: 2,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_bloodthirsty",
        sfx_candidates: ["Monster_Roar_5"],
        sfx_gain: MONSTER_SFX_GAIN * 0.80,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_require_status_missing: STATUS_BLOODTHIRSTY,
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
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_STUN,
        status_turns: 1,
        status_chance: 0.65,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_vine_trap",
        sfx_candidates: ["Whip_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
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
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_BURN,
        status_turns: 2,
        status_chance: 0.70,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_scorching_touch",
        sfx_candidates: ["Fireball_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
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
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 2,
        status_chance: 0.80,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_ghost_cut",
        sfx_candidates: ["Knife_stab"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
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
        target: TGT_OPPONENT,
        effect: "steal_item",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_steal",
        sfx_candidates: ["Dropping_keys"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_use_chance_min: 0.10,
        enemy_use_chance_max: 0.20,
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
        target: TGT_OPPONENT,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0.60,
        status_list: [STATUS_STUN, STATUS_BLEED],
        status_turns_list: [1, 2],
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_ramming",
        sfx_candidates: ["Punch_crunchy_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
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
        sfx_key: "enemy_skill_rampage",
        sfx_candidates: ["Monster_Roar_9"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        use_msg: "It goes berserk!",
        free_action: true,
        set_enemy_actions: 2,
        enemy_require_actions_below: 2,
        enemy_once_per_turn: true,
        enemy_hp_below_ratio: 0.80,
        enemy_use_chance_min: 0.18,
        enemy_use_chance_max: 0.24
    };

    global.skill_db[? SKILL_CURSE] = {
        id: SKILL_CURSE,
        name: "Curse",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "multi_status",
        status: -1,
        status_turns: 1,
        status_chance: 0.50,
        status_list: [STATUS_BURN, STATUS_POISON, STATUS_STUN, STATUS_BLEED],
        status_turns_list: [1, 1, 1, 1],
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_curse",
        sfx_candidates: ["Laugh_evil_deep_3"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_hp_below_ratio: 0.70,
        enemy_once_per_turn: true,
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
        sfx_key: "enemy_skill_blessing",
        sfx_candidates: ["Laugh_spooky_4"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        free_action: true,
        enemy_require_status_missing: STATUS_BLESSING,
        enemy_once_per_turn: true,
        enemy_use_chance_min: 0.25,
        enemy_use_chance_max: 0.25,
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
        sfx_key: "enemy_skill_final_fury",
        sfx_candidates: ["Ghost_scream_3"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        free_action: true,
        set_enemy_actions: 2,
        enemy_passive_action_budget: true,
        enemy_hp_below_ratio: 0.45
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
        return Skill_LocalizeRuntime(global.skill_db[? _skill_id], _skill_id);
    }
    return {
        id: -1,
        name: Loc_T("skill.name.unknown", "Unknown"),
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
        sfx_key: "skill_generic",
        sfx_candidates: [],
        uses_defensive_qte: false,
        enemy_use_chance_min: ENEMY_SKILL_USE_CHANCE_DEFAULT,
        enemy_use_chance_max: ENEMY_SKILL_USE_CHANCE_DEFAULT,
        free_action: false,
        extra_turns: 0,
        set_enemy_actions: 0
    };
}

function Skill_LocalizationKey(_skill_id) {
    switch (_skill_id) {
        case SKILL_POWER_STRIKE: return "skill_power_strike";
        case SKILL_WOUND: return "skill_wound";
        case SKILL_HILT_BASH: return "skill_hilt_bash";
        case SKILL_MUSCLE_UP: return "skill_muscle_up";
        case SKILL_REV_UP: return "skill_rev_up";
        case SKILL_HORIZ_SLASH: return "skill_horiz_slash";
        case SKILL_POISON_ARROW: return "skill_poison_arrow";
        case SKILL_EVASION: return "skill_evasion";
        case SKILL_DOUBLE_SHOT: return "skill_double_shot";
        case SKILL_TAKE_AIM: return "skill_take_aim";
        case SKILL_FIREBALL: return "skill_fireball";
        case SKILL_POISON_MIST: return "skill_poison_mist";
        case SKILL_ICE_SPEAR: return "skill_ice_spear";
        case SKILL_MEDITATION: return "skill_meditation";
        case SKILL_FORESIGHT: return "skill_foresight";
        case SKILL_POISON_FANGS: return "skill_poison_fangs";
        case SKILL_SOLIDIFY: return "skill_solidify";
        case SKILL_BITE: return "skill_bite";
        case SKILL_BLOODTHIRSTY: return "skill_bloodthirsty";
        case SKILL_VINE_TRAP: return "skill_vine_trap";
        case SKILL_SCORCHING_TOUCH: return "skill_scorching_touch";
        case SKILL_GHOST_CUT: return "skill_ghost_cut";
        case SKILL_STEAL: return "skill_steal";
        case SKILL_RAMMING: return "skill_ramming";
        case SKILL_RAMPAGE: return "skill_rampage";
        case SKILL_CURSE: return "skill_curse";
        case SKILL_BLESSING: return "skill_blessing";
        case SKILL_FINAL_FURY: return "skill_final_fury";
    }
    return "unknown";
}

function Skill_LocalizeRuntime(_skill, _skill_id = -1) {
    if (!is_struct(_skill)) return _skill;

    var sid = _skill_id;
    if (sid == -1 && variable_struct_exists(_skill, "id")) sid = _skill.id;
    var key_suffix = Skill_LocalizationKey(sid);

    if (!variable_struct_exists(_skill, "name_en")) _skill.name_en = string(_skill.name);
    _skill.name = Loc_T("skill.name." + key_suffix, string(_skill.name_en));

    if (variable_struct_exists(_skill, "use_msg")) {
        if (!variable_struct_exists(_skill, "use_msg_en")) _skill.use_msg_en = string(_skill.use_msg);
        _skill.use_msg = Loc_T("combat.msg.skill.use." + key_suffix, string(_skill.use_msg_en));
    }

    return _skill;
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
    var user_is_player = (variable_struct_exists(_ch, "is_player") && _ch.is_player);
    if (user_is_player && _ch.mp < _skill.mp_cost) return false;
    if (user_is_player) {
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

function Skill_StealProtectedCount(_target, _item_id) {
    if (!is_struct(_target) || !variable_struct_exists(_target, "equip") || !is_struct(_target.equip)) return 0;

    var protected_qty = 0;
    var slots = ["weapon", "head", "body", "ring1", "ring2"];
    for (var i = 0; i < array_length(slots); i++) {
        var slot = slots[i];
        if (!variable_struct_exists(_target.equip, slot)) continue;
        var equipped_id = round(real(variable_struct_get(_target.equip, slot)));
        if (equipped_id == _item_id) protected_qty += 1;
    }
    return protected_qty;
}

function Skill_StealRecord(_user, _item_id, _qty = 1) {
    if (!is_struct(_user)) return _user;
    var qty = max(1, round(real(_qty)));

    if (!variable_struct_exists(_user, "stolen_items") || !is_array(_user.stolen_items)) {
        _user.stolen_items = [];
    }

    var list = _user.stolen_items;
    var merged = false;
    for (var i = 0; i < array_length(list); i++) {
        if (!is_struct(list[i]) || !variable_struct_exists(list[i], "id")) continue;
        if (list[i].id != _item_id) continue;
        var prev_qty = variable_struct_exists(list[i], "qty") ? max(0, round(real(list[i].qty))) : 0;
        list[i].qty = prev_qty + qty;
        merged = true;
        break;
    }

    if (!merged) array_push(list, { id: _item_id, qty: qty });
    _user.stolen_items = list;
    return _user;
}

function Skill_AdjustStatusTurns(_user, _target, _status_id, _base_turns) {
    var turns = max(1, round(real(_base_turns)));
    if (_status_id == STATUS_STUN) return turns;

    var user_is_player = (is_struct(_user) && variable_struct_exists(_user, "is_player") && _user.is_player);
    var target_is_player = (is_struct(_target) && variable_struct_exists(_target, "is_player") && _target.is_player);

    // FUN-FIRST: statuses linger longer, with player-applied effects lasting longest.
    var mult = 2.0;
    if (user_is_player) mult = 3.0;
    if (!user_is_player && target_is_player) mult = 2.0;
    turns = max(2, round(turns * mult));

    if (user_is_player && !target_is_player) {
        turns += max(0, Equip_PlayerStatusTurnBonus(_user, _status_id));
    }
    return max(1, turns);
}

function Skill_BuildAppliedStatusMessage(_applied_status_names) {
    if (!is_array(_applied_status_names) || array_length(_applied_status_names) <= 0) return "";

    var prefix = Loc_T("combat.msg.applied_prefix", "Applied ");
    if (prefix == "") prefix = "Applied ";
    var last = string_char_at(prefix, string_length(prefix));
    if (last != " " && last != "\t" && last != "\n") prefix += " ";

    var sep = Loc_T("combat.msg.list_separator", ", ");
    if (sep == "" || sep == ",") sep = ", ";

    var out = prefix;
    for (var i = 0; i < array_length(_applied_status_names); i++) {
        if (i > 0) out += sep;
        out += _applied_status_names[i];
    }

    var dot = Loc_T("combat.msg.sentence_dot", ".");
    if (dot == "") dot = ".";
    out += dot;
    return out;
}

function Skill_Use(_user, _target, _skill_id) {
    var s = SkillDB_Get(_skill_id);
    var user_is_player = (variable_struct_exists(_user, "is_player") && _user.is_player);
    var fx_speed_mult = user_is_player ? PLAYER_SKILL_FX_SPEED_MULT : SKILL_FX_SPEED_MULT;
    var result = {
        ok: true,
        hit: true,
        dmg: 0,
        crit: false,
        msg: "",
        fx_sprite: s.fx_sprite,
        fx_frames: s.fx_frames,
        fx_speed: s.fx_speed * fx_speed_mult,
        free_action: (variable_struct_exists(s, "free_action") && s.free_action),
        extra_turns: variable_struct_exists(s, "extra_turns") ? max(0, round(real(s.extra_turns))) : 0,
        set_enemy_actions: variable_struct_exists(s, "set_enemy_actions") ? max(0, round(real(s.set_enemy_actions))) : 0
    };

    var final_mp_cost = s.mp_cost;
    if (user_is_player) {
        final_mp_cost = Equip_PlayerSkillMPCost(_user, s, s.mp_cost);
    }

    if (user_is_player && _user.mp < final_mp_cost) {
        result.ok = false;
        result.msg = Loc_T("combat.msg.not_enough_mp", "Not enough MP.");
        return result;
    }

    if (user_is_player) {
        if (variable_struct_exists(_user, "class_id") && !Skill_ClassAllowed(s, _user.class_id)) {
            result.ok = false;
            result.msg = Loc_T("item.msg.cant_use", "Can't use that.");
            return result;
        }
    }

    if (user_is_player) _user.mp -= final_mp_cost;
    if (user_is_player) _user = Equip_PassiveOnSkillUsed(_user, s);

    var status_turns_default = variable_struct_exists(s, "status_turns") ? max(1, round(real(s.status_turns))) : 1;
    var applied_status_names = [];
    var applied_any_status = false;

    // status-only skills
    if (s.effect == "status") {
        if (s.status != -1) {
            var st_turns = Skill_AdjustStatusTurns(_user, _target, s.status, status_turns_default);
            var adj1 = Equip_PassiveAdjustIncomingStatus(_user, _target, s.status, st_turns);
            if (adj1.apply) {
                _target = Status_Add(_target, s.status, adj1.turns, 1);
                var cfg = StatusDB_Get(s.status);
                if (is_struct(cfg) && variable_struct_exists(cfg, "name")) {
                    array_push(applied_status_names, cfg.name);
                    applied_any_status = true;
                }
            }
            if (adj1.reflect) {
                _user = Status_Add(_user, s.status, adj1.turns, 1);
            }
            if (adj1.msg != "") {
                result.msg = adj1.msg;
            }
        } else {
            if (variable_struct_exists(s, "use_msg")) result.msg = string(s.use_msg);
            else result.msg = Loc_T("combat.msg.skill_used", "Skill used.");
        }

        if (applied_any_status) {
            var msg_status = Skill_BuildAppliedStatusMessage(applied_status_names);
            if (result.msg != "" && msg_status != "") result.msg += " ";
            result.msg += msg_status;
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
                turns_m = Skill_AdjustStatusTurns(_user, _target, sid_m, turns_m);
                var adjm = Equip_PassiveAdjustIncomingStatus(_user, _target, sid_m, turns_m);
                if (adjm.apply) {
                    _target = Status_Add(_target, sid_m, adjm.turns, 1);
                    var cfg_m = StatusDB_Get(sid_m);
                    if (is_struct(cfg_m) && variable_struct_exists(cfg_m, "name")) {
                        array_push(applied_status_names, cfg_m.name);
                        applied_any_status = true;
                    }
                }
                if (adjm.reflect) _user = Status_Add(_user, sid_m, adjm.turns, 1);
                if (adjm.msg != "" && result.msg == "") result.msg = adjm.msg;
            }
        }
        
        if (applied_any_status) {
            var msg_status2 = Skill_BuildAppliedStatusMessage(applied_status_names);
            if (result.msg != "" && msg_status2 != "") result.msg += " ";
            result.msg += msg_status2;
        } else if (result.msg == "") {
            if (variable_struct_exists(s, "use_msg")) result.msg = string(s.use_msg);
            else result.msg = Loc_T("combat.msg.skill_used", "Skill used.");
        }
        return result;
    }

    if (s.effect == "steal_item") {
        if (!variable_struct_exists(_target, "inventory") || !is_array(_target.inventory) || array_length(_target.inventory) <= 0) {
            result.msg = Loc_T("combat.msg.nothing_to_steal", "Nothing to steal.");
            return result;
        }

        var id_totals = [];
        for (var i = 0; i < array_length(_target.inventory); i++) {
            var inv_entry = _target.inventory[i];
            if (!is_struct(inv_entry) || !variable_struct_exists(inv_entry, "id")) continue;

            var iid = round(real(inv_entry.id));
            var iqty = variable_struct_exists(inv_entry, "qty") ? max(0, round(real(inv_entry.qty))) : 0;
            if (iqty <= 0) continue;

            var found = false;
            for (var t = 0; t < array_length(id_totals); t++) {
                if (id_totals[t].id == iid) {
                    id_totals[t].qty += iqty;
                    found = true;
                    break;
                }
            }
            if (!found) array_push(id_totals, { id: iid, qty: iqty });
        }

        var candidates = [];
        var total_stealable = 0;
        for (var c = 0; c < array_length(id_totals); c++) {
            var total_qty = max(0, round(real(id_totals[c].qty)));
            if (total_qty <= 0) continue;
            var protected_qty = Skill_StealProtectedCount(_target, id_totals[c].id);
            var stealable_qty = max(0, total_qty - protected_qty);
            if (stealable_qty <= 0) continue;

            array_push(candidates, { id: id_totals[c].id, qty: stealable_qty });
            total_stealable += stealable_qty;
        }

        if (array_length(candidates) <= 0 || total_stealable <= 0) {
            result.msg = Loc_T("combat.msg.nothing_to_steal", "Nothing to steal.");
            return result;
        }

        var roll = irandom(total_stealable - 1);
        var stolen_id = candidates[0].id;
        for (var r = 0; r < array_length(candidates); r++) {
            if (roll < candidates[r].qty) {
                stolen_id = candidates[r].id;
                break;
            }
            roll -= candidates[r].qty;
        }

        var stolen_item = ItemDB_Get(stolen_id);
        _target.inventory = Inv_Remove(_target.inventory, stolen_id, 1);
        _user = Skill_StealRecord(_user, stolen_id, 1);
        if (is_struct(stolen_item) && variable_struct_exists(stolen_item, "name")) {
            result.msg = Loc_T("combat.msg.stole_item", "Stole {item}.", { item: string(stolen_item.name) });
        } else {
            result.msg = Loc_T("combat.msg.stole_an_item", "Stole an item.");
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
                var dmg_pack = Combat_ApplyDamage(_user, _target, weapon, (crit ? 2 : 1), s.power_mult, { is_skill: true });
                _target = dmg_pack.defender;
                if (user_is_player && dmg_pack.dmg > 0) {
                    // FUN-FIRST passives can amplify player skill damage.
                    var bonus_skill_dmg = Equip_PlayerBonusDamage(_user, _target, dmg_pack.dmg, true, "");
                    if (bonus_skill_dmg > 0) {
                        var bonus_spend = min(bonus_skill_dmg, _target.hp);
                        _target.hp = max(0, _target.hp - bonus_spend);
                        dmg_pack.dmg += bonus_spend;
                    }
                }

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
                var turns_hit = Skill_AdjustStatusTurns(_user, _target, s.status, status_turns_default);
                var adjh = Equip_PassiveAdjustIncomingStatus(_user, _target, s.status, turns_hit);
                if (adjh.apply) {
                    _target = Status_Add(_target, s.status, adjh.turns, 1);
                    var cfg2 = StatusDB_Get(s.status);
                    if (is_struct(cfg2) && variable_struct_exists(cfg2, "name")) {
                        array_push(applied_status_names, cfg2.name);
                        applied_any_status = true;
                    }
                }
                if (adjh.reflect) _user = Status_Add(_user, s.status, adjh.turns, 1);
                if (adjh.msg != "" && result.msg == "") result.msg = adjh.msg;
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
                    turns_d = Skill_AdjustStatusTurns(_user, _target, sid_d, turns_d);
                    var adjd = Equip_PassiveAdjustIncomingStatus(_user, _target, sid_d, turns_d);
                    if (adjd.apply) {
                        _target = Status_Add(_target, sid_d, adjd.turns, 1);
                        var cfg_d = StatusDB_Get(sid_d);
                        if (is_struct(cfg_d) && variable_struct_exists(cfg_d, "name")) {
                            array_push(applied_status_names, cfg_d.name);
                            applied_any_status = true;
                        }
                    }
                    if (adjd.reflect) _user = Status_Add(_user, sid_d, adjd.turns, 1);
                    if (adjd.msg != "" && result.msg == "") result.msg = adjd.msg;
                }
            }
        }

        if (applied_any_status) {
            var msg_status3 = Skill_BuildAppliedStatusMessage(applied_status_names);
            if (result.msg != "" && msg_status3 != "") result.msg += " ";
            result.msg += msg_status3;
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
