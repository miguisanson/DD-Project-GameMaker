function SkillDB_Init() {
    if (variable_global_exists("skill_db") && ds_exists(global.skill_db, ds_type_map)) return;
    global.skill_db = ds_map_create();

    // Warrior skills
    global.skill_db[? SKILL_WOUND] = {
        id: SKILL_WOUND,
        name: "Wound",
        mp_cost: 3,
        power: 3,   // D186 (R3 balance): was 4
        power_mult: 1,
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 3,
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
        power: 4,
        power_mult: 1,
        stat_type: STAT_ATK,
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
        player_fx_speed_mult: 10,
        hits: 1,
        class_list: [CLASS_KNIGHT]
    };

    global.skill_db[? SKILL_MUSCLE_UP] = {
        id: SKILL_MUSCLE_UP,
        name: "Muscle Up",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_GUARD,
        status_turns: 6,
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
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_DMG_UP,
        status_turns: 6,
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
        power: 5,
        power_mult: 1.5,
        stat_type: STAT_ATK,
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
        power: 5,
        power_mult: 1,
        stat_type: STAT_ATK,
        acc: 1,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 3,
        status_stacks: 3,
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
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_EVASION,
        status_turns: 6,
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
        power: 4,
        power_mult: 1,
        stat_type: STAT_ATK,
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
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_CRIT_UP,
        status_turns: 9,
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
        power: 6,
        power_mult: 1,
        stat_type: STAT_MAG,
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
        power: 4,
        power_mult: 1,
        stat_type: STAT_MAG,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 4,
        status_stacks: 4,
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
        power: 5,
        power_mult: 1,
        stat_type: STAT_MAG,
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
        player_fx_speed_mult: 10,
        hits: 1,
        class_list: [CLASS_MAGE]
    };

    global.skill_db[? SKILL_MEDITATION] = {
        id: SKILL_MEDITATION,
        name: "Meditation",
        mp_cost: 3,
        power: 0,
        power_mult: 1,
        stat_type: STAT_MAG,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_MEDITATION,
        status_turns: 9,
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
        stat_type: STAT_MAG,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_HIT_UP,
        status_turns: 3,
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
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 2,
        status_stacks: 2,
        status_chance: 0.70,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_poison_fangs",
        sfx_candidates: ["Bite_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: false,   // D7 (I-066): a plain move just hits; only telegraphed heavy moves get the defence bar
        class_list: []
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
        sfx_key: "enemy_skill_solidify",
        sfx_candidates: ["Liquid _slosh", "Liquid_slosh"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_require_status_missing: STATUS_SOLIDIFY
    };

    global.skill_db[? SKILL_BITE] = {
        id: SKILL_BITE,
        name: "Bite",
        mp_cost: 0,
        power: 2,
        power_mult: 1,
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 3,
        status_chance: 0.75,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_bite",
        sfx_candidates: ["Bite_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: false,   // D7 (I-066): a plain move just hits; only telegraphed heavy moves get the defence bar
        class_list: []
    };

    global.skill_db[? SKILL_BLOODTHIRSTY] = {
        id: SKILL_BLOODTHIRSTY,
        name: "Bloodthirsty",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_BLOODTHIRSTY,
        status_turns: 4,
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
        enemy_require_status_missing: STATUS_BLOODTHIRSTY
    };

    global.skill_db[? SKILL_VINE_TRAP] = {
        id: SKILL_VINE_TRAP,
        name: "Vine Trap",
        mp_cost: 0,
        power: 2,
        power_mult: 2,
        stat_type: STAT_ATK,
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
        telegraphed: true,
        windup_msg: "{enemy} coils its vines!",
        class_list: []
    };

    global.skill_db[? SKILL_SCORCHING_TOUCH] = {
        id: SKILL_SCORCHING_TOUCH,
        name: "Scorching Touch",
        mp_cost: 0,
        power: 3,
        power_mult: 1,
        stat_type: STAT_MAG,
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
        uses_defensive_qte: false,   // D7 (I-066): a plain move just hits; only telegraphed heavy moves get the defence bar
        class_list: []
    };

    global.skill_db[? SKILL_GHOST_CUT] = {
        id: SKILL_GHOST_CUT,
        name: "Cut",
        mp_cost: 0,
        power: 3,
        power_mult: 2,
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 3,
        status_chance: 0.80,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_ghost_cut",
        sfx_candidates: ["Knife_stab"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
        telegraphed: true,
        windup_msg: "{enemy} raises its blade!",
        class_list: []
    };

    global.skill_db[? SKILL_STEAL] = {
        id: SKILL_STEAL,
        name: "Steal",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_SPD,
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
        enemy_require_target_inventory: true
    };

    global.skill_db[? SKILL_RAMMING] = {
        id: SKILL_RAMMING,
        name: "Ramming",
        mp_cost: 0,
        power: 4,
        power_mult: 2,
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0.60,
        status_list: [STATUS_BLEED],
        status_turns_list: [3],
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_ramming",
        sfx_candidates: ["Punch_crunchy_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
        telegraphed: true,
        windup_msg: "{enemy} lowers its horns!",
        class_list: []
    };

    global.skill_db[? SKILL_RAMPAGE] = {
        id: SKILL_RAMPAGE,
        name: "Rampage",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_ATK,
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
        enemy_hp_below_ratio: 0.80
    };

    global.skill_db[? SKILL_CURSE] = {
        id: SKILL_CURSE,
        name: "Curse",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_MAG,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "multi_status",
        status: -1,
        status_turns: 2,
        status_chance: 0.50,
        status_list: [STATUS_BURN, STATUS_POISON, STATUS_BLEED],
        status_turns_list: [2, 2, 3],
        status_stacks_list: [1, 2, 1],
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_curse",
        sfx_candidates: ["Laugh_evil_deep_3"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        enemy_hp_below_ratio: 0.70,
        enemy_once_per_turn: true
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
        status_turns: 4,
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
        enemy_hp_below_ratio: 0.8
    };

    global.skill_db[? SKILL_FINAL_FURY] = {
        id: SKILL_FINAL_FURY,
        name: "Fury",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_ATK,
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
        use_msg: "Fury erupts!",
        free_action: true,
        set_enemy_actions: 2,
        enemy_require_actions_below: 2,
        enemy_once_per_turn: true,
        enemy_hp_below_ratio: 0.45
    };

    // ---- packet B4 (combat-spec.md section 12): enemy moves for the rule lists. No use chances: the enemy's brain (scr_db_enemy) decides. ----
    global.skill_db[? SKILL_REGROW] = {
        id: SKILL_REGROW,
        name: "Regrow",
        mp_cost: 0,
        power: 5,
        power_mult: 1,
        stat_type: STAT_MAG,
        acc: 0,
        target: TGT_SELF,
        effect: "heal",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_regrow",
        sfx_candidates: ["Liquid_slosh"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        use_msg: "It regrows its wounds!"
    };

    global.skill_db[? SKILL_SNUFF] = {
        id: SKILL_SNUFF,
        name: "Snuff",
        mp_cost: 0,
        power: 0,
        power_mult: 1,
        stat_type: STAT_MAG,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "dispel",
        status: -1,
        status_turns: 0,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_snuff",
        sfx_candidates: ["Laugh_spooky_4"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [],
        use_msg: "Your buffs are snuffed out!"
    };

    global.skill_db[? SKILL_GORE] = {
        id: SKILL_GORE,
        name: "Gore",
        mp_cost: 0,
        power: 4,
        power_mult: 1,
        stat_type: STAT_ATK,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "damage",
        status: STATUS_BLEED,
        status_turns: 3,
        status_chance: 0.70,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_gore",
        sfx_candidates: ["Punch_crunchy_2"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: []
    };

    global.skill_db[? SKILL_PALE_HYMN] = {
        id: SKILL_PALE_HYMN,
        name: "Pale Hymn",
        mp_cost: 0,
        power: 5,
        power_mult: 2,
        stat_type: STAT_MAG,
        acc: 0,
        target: TGT_OPPONENT,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: noone,
        fx_sprite: noone,
        sfx_key: "enemy_skill_pale_hymn",
        sfx_candidates: ["Ghost_scream_3"],
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        uses_defensive_qte: true,
        telegraphed: true,
        windup_msg: "{enemy} draws a deep breath!",
        class_list: []
    };

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.skill_db = global.skill_db;
    }
}

// What the skill is for the player who holds it (C2: his upgrade, Barbed Arrows, Spellweave); anything else is the database entry.
function SkillDB_Get(_skill_id) {
    return Card_ApplyToSkill(SkillDB_GetBase(_skill_id), _skill_id);
}

// The database entry itself, localized (no card effects).
function SkillDB_GetBase(_skill_id) {
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
        stat_type: STAT_ATK,
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
        telegraphed: false,
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
        case SKILL_REGROW: return "skill_regrow";
        case SKILL_SNUFF: return "skill_snuff";
        case SKILL_GORE: return "skill_gore";
        case SKILL_PALE_HYMN: return "skill_pale_hymn";
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

// The line shown when an enemy winds up a telegraphed move (B4, D7): the skill's own text, or a plain one.
function Skill_WindupText(_skill, _enemy_name) {
    var key = Skill_LocalizationKey(_skill.id);
    var def = variable_struct_exists(_skill, "windup_msg") ? string(_skill.windup_msg) : "{enemy} is winding up {skill}!";
    return Loc_T("combat.msg.windup." + key, def, { enemy: string(_enemy_name), skill: string(_skill.name) });
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

// Turns a status gets when a skill applies it. The skill's own `status_turns` is already the real number (BUG-16: the tooltip shows it, an upgrade adds to it);
// a status with a fixed `duration` in StatusDB (Burning 2, Bleeding 3, Foresight 3) is a floor, so an upgrade's extra turns still count (Foresight+ = 5). Equipment can add turns to what the player puts on an enemy.
// A Poison has no turns (it has stacks, Skill_StatusStacks).
function Skill_AdjustStatusTurns(_user, _target, _status_id, _base_turns) {
    var turns = max(1, round(real(_base_turns)));
    if (_status_id == STATUS_STUN) return turns;

    var fixed = Status_Cfg(_status_id, "duration", 0);
    if (fixed > 0) turns = max(turns, fixed);

    var user_is_player = (is_struct(_user) && variable_struct_exists(_user, "is_player") && _user.is_player);
    var target_is_player = (is_struct(_target) && variable_struct_exists(_target, "is_player") && _target.is_player);
    if (user_is_player && !target_is_player && _status_id != STATUS_POISON) {
        turns += max(0, Equip_PlayerStatusTurnBonus(_user, _status_id));
        turns += Card_StatusTurnBonus(_user, _status_id);   // Cold Focus
    }
    if (user_is_player && target_is_player && _status_id == STATUS_GUARD) {
        turns += max(0, round(Card_PassiveSum(_user, "guard_turns")));   // Bulwark
    }

    return max(1, turns);
}

// Stacks a Poison or Bleeding hit adds (skill field status_stacks, default 1). Equipment "+1 status turn" adds 1 Poison stack when the player applies it.
function Skill_StatusStacks(_user, _target, _status_id, _base_stacks) {
    var stacks = max(1, round(real(_base_stacks)));
    var user_is_player = (is_struct(_user) && variable_struct_exists(_user, "is_player") && _user.is_player);
    var target_is_player = (is_struct(_target) && variable_struct_exists(_target, "is_player") && _target.is_player);
    if (_status_id == STATUS_POISON && user_is_player && !target_is_player) {
        stacks += max(0, Equip_PlayerStatusTurnBonus(_user, _status_id));
        stacks += max(0, round(Card_PassiveSum(_user, "poison_stacks")));   // Venom Coat
    }
    return stacks;
}

// Everything Status_Add needs for one status of a skill: { turns, stacks, power, weak }. power = Burning's HP per tick, from the caster's effective MAG.
// D173 (IDEA-07): an enemy that is weak to the status takes more turns or stacks (WeakPoint_Adjust, never past the D78 caps); weak = it added something.
function Skill_StatusApplyArgs(_user, _target, _status_id, _base_turns, _base_stacks = 1) {
    var tick_power = 1;
    if (_status_id == STATUS_BURN) tick_power = Status_BurnTick(Combat_EffectiveStat(_user, STAT_MAG));
    var wp = WeakPoint_Adjust(_target, _status_id, Skill_AdjustStatusTurns(_user, _target, _status_id, _base_turns), Skill_StatusStacks(_user, _target, _status_id, _base_stacks));
    return { turns: wp.turns, stacks: wp.stacks, power: tick_power, weak: wp.weak };
}

// The stacks the skill gives for its status at index _i of status_list (or its single status when _i < 0).
function Skill_BaseStacks(_s, _i = -1) {
    if (_i >= 0 && variable_struct_exists(_s, "status_stacks_list") && is_array(_s.status_stacks_list) && _i < array_length(_s.status_stacks_list)) {
        return max(1, round(real(_s.status_stacks_list[_i])));
    }
    if (_i < 0 && variable_struct_exists(_s, "status_stacks")) return max(1, round(real(_s.status_stacks)));
    return 1;
}

function Skill_BuildAppliedStatusMessage(_applied_status_names) {
    if (!is_array(_applied_status_names) || array_length(_applied_status_names) <= 0) return "";

    var prefix = Loc_T("combat.msg.applied_prefix", "Applied ");
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

// Image speed a skill's animation plays at. Player skills (D55) are also capped so they play in no more than PLAYER_SKILL_FX_MAX_FRAMES game frames.
function Skill_FxSpeed(_s, _user_is_player) {
    var player_vs_enemy_skill = _user_is_player && (!variable_struct_exists(_s, "target") || _s.target != TGT_SELF);
    var fx_speed_mult = SKILL_FX_SPEED_MULT;
    if (_user_is_player) {
        fx_speed_mult = player_vs_enemy_skill ? PLAYER_SKILL_FX_SPEED_MULT : PLAYER_SKILL_FX_SPEED_MULT_NON_ENEMY;
    }
    var fx_speed = _s.fx_speed * fx_speed_mult;
    if (player_vs_enemy_skill && variable_struct_exists(_s, "player_fx_speed_mult")) {
        var per_skill_fx_mult = max(0, real(_s.player_fx_speed_mult));
        if (per_skill_fx_mult > 0) {
            fx_speed = _s.fx_speed * per_skill_fx_mult;
        }
    }
    if (player_vs_enemy_skill) {
        fx_speed = clamp(fx_speed, 0.01, PLAYER_SKILL_FX_SPEED_MAX);
    }
    if (_user_is_player && _s.fx_sprite != noone) {
        fx_speed = FX_SpeedForMaxFrames(_s.fx_sprite, fx_speed, PLAYER_SKILL_FX_MAX_FRAMES);
    }
    return fx_speed;
}

// Skill ids a player can learn that have an animation, in id order (the ones the animation timing and size checks cover).
function Skill_PlayerFxIds() {
    SkillDB_Init();
    var ids = [];
    var keys = ds_map_keys_to_array(global.skill_db);
    array_sort(keys, true);
    for (var i = 0; i < array_length(keys); i++) {
        var s = global.skill_db[? keys[i]];
        if (!is_struct(s) || s.fx_sprite == noone) continue;
        if (!is_array(s.class_list) || array_length(s.class_list) == 0) continue;
        array_push(ids, keys[i]);
    }
    return ids;
}

// _grade_mult is the QTE grade's damage multiplier (D61). 1.00 = grade OK, which is what every player skill uses until the arrow QTE (D57) lands.
// D126: does the status of this skill land? One marble bag per skill per user (per status for Curse), shuffled with the run's combat stream.
// The bag refills when the chance changes (an upgrade adds 0.25). A chance of 1 needs no bag.
function Skill_StatusRoll(_user, _skill_id, _chance, _slot = "") {
    return Bag_Draw(_user, "status_" + string(_skill_id) + _slot, _chance, Run_Stream("combat"));
}

// D173 (IDEA-07): the same roll against _target, whose resistance halves the chance (WeakPoint_ResistChance). { landed, resisted }: resisted = it failed and the resistance was in play.
function Skill_StatusTry(_user, _target, _skill_id, _chance, _status_id, _slot = "") {
    var ch = WeakPoint_ResistChance(_target, _status_id, _chance);
    var landed = Skill_StatusRoll(_user, _skill_id, ch, _slot);
    return { landed: landed, resisted: (!landed && ch < _chance) };
}

// A status that a skill has no chance roll for (status-only skills, the rest of a list that already rolled): only a resisting target rolls, for the halved sure thing.
function Skill_StatusResistTry(_user, _target, _skill_id, _status_id, _slot) {
    var ch = WeakPoint_ResistChance(_target, _status_id, 1);
    if (ch >= 1) return { landed: true, resisted: false };
    var landed = Skill_StatusRoll(_user, _skill_id, ch, _slot);
    return { landed: landed, resisted: !landed };
}

// Puts what the weak point did on the skill's result: weak_status / resist_status (the Codex learns from them) and the log line (weak: once per fight, resisted: every time).
function Skill_NoteWeakPoint(_result, _target, _status_id, _weak, _resisted) {
    var line = "";
    if (_resisted) {
        _result.resist_status = _status_id;
        line = WeakPoint_ResistMsg(_target, _status_id);
    }
    if (_weak) {
        _result.weak_status = _status_id;
        line = WeakPoint_WeakMsg(_target, _status_id);
    }
    if (line != "") _result.wp_msg = (_result.wp_msg == "") ? line : (_result.wp_msg + " " + line);
}

// The weak point lines go at the end of the skill's log text.
function Skill_AppendWeakPoint(_result) {
    if (_result.wp_msg != "") _result.msg = (_result.msg == "") ? _result.wp_msg : (_result.msg + " " + _result.wp_msg);
    return _result;
}

// What a damaging skill hits with: { power (final formula power), stat_type, acc }. A player's weapon adds to the power (D22); power_mult is part of it.
// Skill_Use deals through it and the damage preview (Battle_SkillPreview, D135) reads the same struct.
function Skill_DamageSource(_user, _s) {
    var user_is_player = (variable_struct_exists(_user, "is_player") && _user.is_player);
    var formula_power = user_is_player ? Combat_PowerSkill(_s.power, _s.power_mult, Combat_WeaponPower(_user)) : Combat_PowerEnemySkill(_s.power, _s.power_mult);
    return { power: formula_power, stat_type: _s.stat_type, acc: _s.acc };
}

function Skill_Use(_user, _target, _skill_id, _grade_mult = 1) {
    var s = SkillDB_Get(_skill_id);
    var user_is_player = (variable_struct_exists(_user, "is_player") && _user.is_player);
    var fx_speed = Skill_FxSpeed(s, user_is_player);
    var result = {
        ok: true,
        hit: true,
        dmg: 0,
        crit: false,
        msg: "",
        fx_sprite: s.fx_sprite,
        fx_frames: s.fx_frames,
        fx_speed: fx_speed,
        free_action: (variable_struct_exists(s, "free_action") && s.free_action),
        extra_turns: variable_struct_exists(s, "extra_turns") ? max(0, round(real(s.extra_turns))) : 0,
        set_enemy_actions: variable_struct_exists(s, "set_enemy_actions") ? max(0, round(real(s.set_enemy_actions))) : 0,
        weak_status: -1,     // D173 (IDEA-07): the status the target is weak to when the weakness added something, else -1
        resist_status: -1,   // the status a resisting target shrugged off, else -1
        wp_msg: ""
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
        var try_1 = Skill_StatusResistTry(_user, _target, _skill_id, s.status, "_s");   // D173: only a resisting target rolls
        if (s.status != -1 && !try_1.landed) {
            Skill_NoteWeakPoint(result, _target, s.status, false, true);
        } else if (s.status != -1) {
            var st_args = Skill_StatusApplyArgs(_user, _target, s.status, status_turns_default, Skill_BaseStacks(s));
            var adj1 = Equip_PassiveAdjustIncomingStatus(_user, _target, s.status, st_args.turns);
            if (adj1.apply) {
                _target = Status_Add(_target, s.status, adj1.turns, st_args.power, st_args.stacks);
                var cfg = StatusDB_Get(s.status);
                if (is_struct(cfg) && variable_struct_exists(cfg, "name")) {
                    array_push(applied_status_names, cfg.name);
                    applied_any_status = true;
                }
                if (st_args.weak) Skill_NoteWeakPoint(result, _target, s.status, true, false);
            }
            if (adj1.reflect) {
                _user = Status_Add(_user, s.status, adj1.turns, st_args.power, st_args.stacks);
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
        return Skill_AppendWeakPoint(result);
    }

    if (s.effect == "multi_status") {
        // Curse (BUG-17): status_chance is rolled once PER status; the three DoTs coexist (D78); the message names only the ones that landed.
        var multi_chance = variable_struct_exists(s, "status_chance") ? real(s.status_chance) : 1;
        if (variable_struct_exists(s, "status_list") && is_array(s.status_list)) {
            var turns_list = variable_struct_exists(s, "status_turns_list") && is_array(s.status_turns_list) ? s.status_turns_list : [];
            for (var m = 0; m < array_length(s.status_list); m++) {
                var sid_m = s.status_list[m];
                if (sid_m == -1) continue;
                var try_m = Skill_StatusTry(_user, _target, _skill_id, multi_chance, sid_m, "_" + string(m));   // D126: one bag per status (D173: halved by a resistance)
                if (!try_m.landed) {
                    if (try_m.resisted) Skill_NoteWeakPoint(result, _target, sid_m, false, true);
                    continue;
                }
                var turns_m = status_turns_default;
                if (m < array_length(turns_list)) turns_m = max(1, round(real(turns_list[m])));
                var args_m = Skill_StatusApplyArgs(_user, _target, sid_m, turns_m, Skill_BaseStacks(s, m));
                var adjm = Equip_PassiveAdjustIncomingStatus(_user, _target, sid_m, args_m.turns);
                if (adjm.apply) {
                    _target = Status_Add(_target, sid_m, adjm.turns, args_m.power, args_m.stacks);
                    var cfg_m = StatusDB_Get(sid_m);
                    if (is_struct(cfg_m) && variable_struct_exists(cfg_m, "name")) {
                        array_push(applied_status_names, cfg_m.name);
                        applied_any_status = true;
                    }
                    if (args_m.weak) Skill_NoteWeakPoint(result, _target, sid_m, true, false);
                }
                if (adjm.reflect) _user = Status_Add(_user, sid_m, adjm.turns, args_m.power, args_m.stacks);
                if (adjm.msg != "" && result.msg == "") result.msg = adjm.msg;
            }
        }

        if (applied_any_status) {
            var msg_status2 = Skill_BuildAppliedStatusMessage(applied_status_names);
            if (result.msg != "" && msg_status2 != "") result.msg += " ";
            result.msg += msg_status2;
        } else if (result.msg == "") {
            result.msg = Loc_T("combat.msg.multi_status_none", "Nothing took hold.");
        }
        return Skill_AppendWeakPoint(result);
    }

    if (s.effect == "dispel") {
        // B4 (Snuff): every buff on the target goes (anything that is not negative); debuffs stay. No damage.
        var removed_names = [];
        if (variable_struct_exists(_target, "status") && is_array(_target.status)) {
            for (var di = array_length(_target.status) - 1; di >= 0; di--) {
                var dsid = _target.status[di].id;
                if (Status_IsNegative(dsid)) continue;
                array_push(removed_names, StatusDB_Get(dsid).name);
                array_delete(_target.status, di, 1);
            }
        }
        result.msg = variable_struct_exists(s, "use_msg") ? string(s.use_msg) : Loc_T("combat.msg.skill_used", "Skill used.");
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
            result.msg = Loc_T("combat.msg.stole_item", "Stole {item}.", { item: Item_NameMarked(stolen_id) });
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
        var weapon = Skill_DamageSource(_user, s);   // spec section 4: the formula power and the stat the hit uses

        for (var h = 0; h < hits; h++) {
            // D6/D80: nothing rolls to hit. A player skill always lands; an enemy skill lands unless the player's Evasion dodges it.
            var hit_res = { hit: true, defender: _target };
            if (!user_is_player) {
                var dodge_res = Combat_TryDodge(_user, _target);
                hit_res = { hit: !dodge_res.dodged, defender: dodge_res.defender };
                _target = hit_res.defender;
            }

            if (hit_res.hit) {
                var crit = Combat_CritCheck(_user, crit_bonus);
                var dmg_ctx_skill = { is_skill: true };
                if (user_is_player) dmg_ctx_skill.grade_mult = _grade_mult;
                var dmg_pack = Combat_ApplyDamage(_user, _target, weapon, (crit ? COMBAT_CRIT_MULT : 1), 1, dmg_ctx_skill);
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

        if (s.status != -1 && any_hit) {
            var try_h = Skill_StatusTry(_user, _target, _skill_id, status_chance, s.status);   // D173: halved by a resistance
            if (try_h.landed) {
                var args_h = Skill_StatusApplyArgs(_user, _target, s.status, status_turns_default, Skill_BaseStacks(s));
                var adjh = Equip_PassiveAdjustIncomingStatus(_user, _target, s.status, args_h.turns);
                if (adjh.apply) {
                    _target = Status_Add(_target, s.status, adjh.turns, args_h.power, args_h.stacks);
                    var cfg2 = StatusDB_Get(s.status);
                    if (is_struct(cfg2) && variable_struct_exists(cfg2, "name")) {
                        array_push(applied_status_names, cfg2.name);
                        applied_any_status = true;
                    }
                    if (args_h.weak) Skill_NoteWeakPoint(result, _target, s.status, true, false);
                }
                if (adjh.reflect) _user = Status_Add(_user, s.status, adjh.turns, args_h.power, args_h.stacks);
                if (adjh.msg != "" && result.msg == "") result.msg = adjh.msg;
            } else if (try_h.resisted) {
                Skill_NoteWeakPoint(result, _target, s.status, false, true);
            }
        }

        if (variable_struct_exists(s, "status_list") && is_array(s.status_list) && any_hit) {
            var turns_list_d = variable_struct_exists(s, "status_turns_list") && is_array(s.status_turns_list) ? s.status_turns_list : [];
            if (Skill_StatusRoll(_user, _skill_id, status_chance, "_list")) {
                for (var sd = 0; sd < array_length(s.status_list); sd++) {
                    var sid_d = s.status_list[sd];
                    if (sid_d == -1) continue;
                    var try_d = Skill_StatusResistTry(_user, _target, _skill_id, sid_d, "_listres" + string(sid_d));   // D173: the list rolled once; a resisting target rolls the halved rest
                    if (!try_d.landed) {
                        Skill_NoteWeakPoint(result, _target, sid_d, false, true);
                        continue;
                    }
                    var turns_d = status_turns_default;
                    if (sd < array_length(turns_list_d)) turns_d = max(1, round(real(turns_list_d[sd])));
                    var args_d = Skill_StatusApplyArgs(_user, _target, sid_d, turns_d, Skill_BaseStacks(s, sd));
                    var adjd = Equip_PassiveAdjustIncomingStatus(_user, _target, sid_d, args_d.turns);
                    if (adjd.apply) {
                        _target = Status_Add(_target, sid_d, adjd.turns, args_d.power, args_d.stacks);
                        var cfg_d = StatusDB_Get(sid_d);
                        if (is_struct(cfg_d) && variable_struct_exists(cfg_d, "name")) {
                            array_push(applied_status_names, cfg_d.name);
                            applied_any_status = true;
                        }
                        if (args_d.weak) Skill_NoteWeakPoint(result, _target, sid_d, true, false);
                    }
                    if (adjd.reflect) _user = Status_Add(_user, sid_d, adjd.turns, args_d.power, args_d.stacks);
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
        result = Skill_AppendWeakPoint(result);
    }

    if (s.effect == "heal") {
        var amt = Combat_HealAmount(s.power, Combat_EffectiveStat(_user, s.stat_type));
        _target.hp = clamp(_target.hp + amt, 0, _target.max_hp);
        result.dmg = -amt;
        if (variable_struct_exists(s, "use_msg")) result.msg = string(s.use_msg);
    }

    if (result.msg == "" && variable_struct_exists(s, "use_msg")) {
        result.msg = string(s.use_msg);
    }

    return result;
}


// ==========================================================================================================================
// C2: cards (D18, D34, D73, D76, D81-D83, D88, D100).
// A card is a struct { id, kind, stem, name_en, line_en, classes, params, skill_id, up }.
//   kind skill     id skill:<skill id>   learn a class skill (max CARD_MAX_SKILLS equipped, D82)
//   kind upgrade   id up:<skill id>      the skill's one upgrade; only offered for a skill you have; `up` holds the deltas
//   kind passive   id pas:<name>         shared (classes = []) or class-exclusive; `params` are the numbers the game reads
//   kind fallback  id fb:<name>          fills an offer when the pool ran dry; never part of a class pool
// Text is generated from this data (D100): the sentence has its numbers filled in, the number lines are label/value pairs.
// The player (a character struct) keeps: skills [ids], upgrades [skill ids], passives [card ids], card_picks (owed 1-of-3 picks),
// class_pick (owed class choice), class_chosen, skill_pending (a taken skill waiting for a slot, -1 = none), offer (the 3 ids on screen).
// ==========================================================================================================================
#macro CARD_PITY_OFFERS 2     // offers without an upgrade (while one was possible) before the next one must hold one
#macro CARD_MAX_SKILLS 3      // D82
#macro CARD_OFFER_SIZE 3      // D81

function Card_SkillId(_skill_id) { return "skill:" + string(_skill_id); }
function Card_UpgradeId(_skill_id) { return "up:" + string(_skill_id); }

function Card_ArrayHas(_arr, _v) {
    if (!is_array(_arr)) return false;
    for (var i = 0; i < array_length(_arr); i++) if (_arr[i] == _v) return true;
    return false;
}

function Card_ArrayWithout(_arr, _v) {
    var out = [];
    for (var i = 0; i < array_length(_arr); i++) if (_arr[i] != _v) array_push(out, _arr[i]);
    return out;
}

function CardDB_Add(_c) {
    array_push(global.card_list, _c);
    variable_struct_set(global.card_index, _c.id, array_length(global.card_list) - 1);
}

function CardDB_Make(_id, _kind, _stem, _name, _line, _classes, _params, _skill_id = -1, _up = {}) {
    return { id: _id, kind: _kind, stem: _stem, name_en: _name, line_en: _line, classes: _classes, params: _params, skill_id: _skill_id, up: _up };
}

// Builds the card list once: the 14 player skills (from the skill database), their 14 upgrades, the passives and the fallbacks.
function CardDB_Init() {
    if (variable_global_exists("card_list") && is_array(global.card_list) && array_length(global.card_list) > 0) return;
    SkillDB_Init();
    global.card_list = [];
    global.card_index = {};

    // skills, in id order; one upgrade each. Upgrade deltas: power, mp_cost, status_turns, status_stacks, status_chance (all added), seq_trim (arrows removed from the end).
    var ups = [
        [SKILL_WOUND,       { power: 2, status_chance: 0.25 }],                  // Wound+: power 4 > 6, bleed 75% > 100%
        [SKILL_HILT_BASH,   { power: 1, status_chance: 0.25 }],                  // Hilt Bash+: power 4 > 5, stun 60% > 85%
        [SKILL_MUSCLE_UP,   { mp_cost: -1, status_turns: 2 }],                   // Muscle Up+: 3 > 2 MP, guard 6 > 8 turns
        [SKILL_REV_UP,      { seq_trim: 1, status_turns: 2 }],                   // Rev Up+: 3 > 2 arrows, 6 > 8 turns
        [SKILL_HORIZ_SLASH, { power: 2, seq_trim: 1 }],                          // Horizontal Slash+: power 5 > 7, 5 > 4 arrows
        [SKILL_POISON_ARROW,{ status_stacks: 1, status_chance: 0.25 }],          // Poison Arrow+: 3 > 4 stacks, 75% > 100%
        [SKILL_EVASION,     { mp_cost: -1, status_turns: 3 }],                   // Evasion+: 3 > 2 MP, 6 > 9 turns
        [SKILL_DOUBLE_SHOT, { power: 1, seq_trim: 1 }],                          // Double Shot+: power 4 > 5 per shot, 5 > 4 arrows
        [SKILL_TAKE_AIM,    { mp_cost: -1, status_turns: 3 }],                   // Take Aim+: 3 > 2 MP, 9 > 12 turns
        [SKILL_FIREBALL,    { power: 2, status_chance: 0.25 }],                  // Fireball+: power 6 > 8, burn 60% > 85%
        [SKILL_POISON_MIST, { status_stacks: 1, seq_trim: 1 }],                  // Poison Mist+: 4 > 5 stacks, 4 > 3 arrows
        [SKILL_ICE_SPEAR,   { power: 2, seq_trim: 1 }],                          // Ice Spear+: power 5 > 7, 5 > 4 arrows
        [SKILL_MEDITATION,  { mp_cost: -1, status_turns: 3 }],                   // Meditation+: 3 > 2 MP, 9 > 12 turns
        [SKILL_FORESIGHT,   { status_turns: 2, seq_trim: 1 }]                    // Foresight+: 3 > 5 turns, 3 > 2 arrows
    ];
    for (var i = 0; i < array_length(ups); i++) {
        var sid = ups[i][0];
        var sk = global.skill_db[? sid];
        CardDB_Add(CardDB_Make(Card_SkillId(sid), "skill", "", "", "", sk.class_list, {}, sid));
    }
    for (var j = 0; j < array_length(ups); j++) {
        var sid2 = ups[j][0];
        var sk2 = global.skill_db[? sid2];
        CardDB_Add(CardDB_Make(Card_UpgradeId(sid2), "upgrade", "", "", "", sk2.class_list, {}, sid2, ups[j][1]));
    }

    // passives: [id, name, sentence ({n} = the main number), classes, main param, params]
    var K = [CLASS_KNIGHT]; var A = [CLASS_ARCHER]; var M = [CLASS_MAGE]; var N = [CLASS_NOBODY];
    var pas = [
        ["quick_feet",    "Quick Feet",    "Light on your feet: +{n} SPD for good.",                    [], "stat_spd",         { stat_spd: 1 }],
        ["venom_coat",    "Venom Coat",    "[t]Poison[/t] you inflict adds {n} extra stack.",                   [], "poison_stacks",    { poison_stacks: 1 }],
        ["field_medic",   "Field Medic",   "Restore {n} HP after each battle you win.",                 [], "heal_after_fight", { heal_after_fight: 3 }],
        ["steady_hands",  "Steady Hands",  "Perfect zones are {n}% wider.",                             [], "perfect_widen",    { perfect_widen: 0.10 }],
        ["coin_sense",    "Coin Sense",    "Find {n}% more gold.",                                      [], "gold_mult",        { gold_mult: 0.10 }],
        ["mana_spring",   "Mana Spring",   "Regain {n} MP at the start of each of your turns.",         [], "mp_gain",          { mp_gain: 1, every_n_turns: 1 }],
        ["potion_lore",   "Potion Lore",   "Potions work {n}% better.",                                 [], "item_power",       { item_power: 0.15 }],
        ["opening_blow",  "Opening Blow",  "Enemies start each battle with {n} stagger.",                [], "start_stagger",    { start_stagger: 1 }],
        ["k_iron_hide",   "Iron Hide",     "Thick armour sense: +{n} DEF for good.",                    K,  "stat_def",         { stat_def: 2 }],
        ["k_bulwark",     "Bulwark",       "Guard on yourself lasts {n} turns longer.",                 K,  "guard_turns",      { guard_turns: 3 }],
        ["k_heavy_hands", "Heavy Hands",   "A harder swing: +{n} ATK for good.",                        K,  "stat_atk",         { stat_atk: 2 }],
        ["a_fleet_foot",  "Fleet Foot",    "Quicker than the wind: +{n} SPD for good.",                 A,  "stat_spd",         { stat_spd: 2 }],
        ["a_barbed",      "Barbed Arrows", "Your damage skills hit for {n} more power.",                A,  "skill_power",      { skill_power: 1 }],
        ["a_second_wind", "Second Wind",   "Regain {n} MP after each battle you win.",                  A,  "mp_after_fight",   { mp_after_fight: 2 }],
        ["m_arcane_well", "Arcane Well",   "A deeper well: +{n} MAG for good.",                         M,  "stat_mag",         { stat_mag: 2 }],
        ["m_spellweave",  "Spellweave",    "Your skills cost {n} MP less (never below 1).",             M,  "mp_cost_less",     { mp_cost_less: 1 }],
        ["m_cold_focus",  "Cold Focus",    "Statuses you inflict last {n} turn longer.",                M,  "status_turn_bonus",{ status_turn_bonus: 1 }],
        ["n_tonic",       "Tonic Blend",   "Healing potions also restore {n} MP.",                      N,  "potion_mp",        { potion_mp: 2 }],
        ["n_apothecary",  "Apothecary",    "Potions work {n}% better.",                                 N,  "item_power",       { item_power: 0.30 }],
        ["n_scrounger",   "Scrounger",     "After each win, {n}% to find a potion.",    N,  "find_potion_pct",  { find_potion_pct: 0.30 }]
    ];
    for (var p = 0; p < array_length(pas); p++) {
        var row = pas[p];
        var c = CardDB_Make("pas:" + row[0], "passive", "card.pas." + row[0], row[1], row[2], row[3], row[5]);
        c.main = row[4];
        CardDB_Add(c);
    }

    // fallbacks: when an offer cannot be filled from the pool
    var fbs = [
        ["rest",  "Second Breath", "Restore {n}% of your HP and MP now.",       "heal_pct",  { heal_pct: 0.5 }],
        ["gold",  "Coin Purse",    "Take {n} gold.",                            "gold",      { gold: 8 }],   // D193: was 15
        ["focus", "Whetstone",     "Your main stat grows by {n} for good.",     "stat_main", { stat_main: 1 }]
    ];
    for (var f = 0; f < array_length(fbs); f++) {
        var frow = fbs[f];
        var fc = CardDB_Make("fb:" + frow[0], "fallback", "card.fb." + frow[0], frow[1], frow[2], [], frow[4]);
        fc.main = frow[3];
        CardDB_Add(fc);
    }
}

function CardDB_All() {
    CardDB_Init();
    return global.card_list;
}

function CardDB_Get(_id) {
    CardDB_Init();
    if (variable_struct_exists(global.card_index, _id)) return global.card_list[variable_struct_get(global.card_index, _id)];
    return undefined;
}

function Card_AllIds() {
    var out = [];
    var clist = CardDB_All();
    for (var i = 0; i < array_length(clist); i++) array_push(out, clist[i].id);
    return out;
}

function Card_FallbackIds() {
    var out = [];
    var clist = CardDB_All();
    for (var i = 0; i < array_length(clist); i++) if (clist[i].kind == "fallback") array_push(out, clist[i].id);
    return out;
}

function Card_ForClass(_c, _class_id) {
    return array_length(_c.classes) == 0 || Card_ArrayHas(_c.classes, _class_id);
}

// The cards a class can ever be offered (no fallbacks).
function Card_Pool(_class_id) {
    var out = [];
    var clist = CardDB_All();
    for (var i = 0; i < array_length(clist); i++) {
        if (clist[i].kind == "fallback") continue;
        if (Card_ForClass(clist[i], _class_id)) array_push(out, clist[i]);
    }
    return out;
}

function Card_PoolIds(_class_id) {
    var pool = Card_Pool(_class_id);
    var out = [];
    for (var i = 0; i < array_length(pool); i++) array_push(out, pool[i].id);
    return out;
}

function Card_PoolPassiveIds(_class_id) {
    var pool = Card_Pool(_class_id);
    var out = [];
    for (var i = 0; i < array_length(pool); i++) if (pool[i].kind == "passive") array_push(out, pool[i].id);
    return out;
}

// ---- character fields ----------------------------------------------------------------------------------------------------
function Card_EnsureFields(_ch) {
    if (!is_struct(_ch)) return _ch;
    if (!variable_struct_exists(_ch, "skills") || !is_array(_ch.skills)) _ch.skills = [];
    if (!variable_struct_exists(_ch, "upgrades") || !is_array(_ch.upgrades)) _ch.upgrades = [];
    if (!variable_struct_exists(_ch, "passives") || !is_array(_ch.passives)) _ch.passives = [];
    if (!variable_struct_exists(_ch, "card_picks") || !is_real(_ch.card_picks)) _ch.card_picks = 0;
    if (!variable_struct_exists(_ch, "class_pick")) _ch.class_pick = false;
    if (!variable_struct_exists(_ch, "class_chosen")) _ch.class_chosen = (variable_struct_exists(_ch, "class_id") && _ch.class_id != CLASS_NOBODY);   // a ready-made class counts as chosen; a run starts as Nobody (D73)
    if (!variable_struct_exists(_ch, "skill_pending") || !is_real(_ch.skill_pending)) _ch.skill_pending = -1;
    if (!variable_struct_exists(_ch, "offer") || !is_array(_ch.offer)) _ch.offer = [];
    if (!variable_struct_exists(_ch, "echo_offer") || !is_array(_ch.echo_offer)) _ch.echo_offer = [];   // D130: the echo pick waiting after the class pick
    return _ch;
}

// What the active card effects read from a character: the sum of one numeric param over its passives (0 for an enemy or no passive).
function Card_PassiveSum(_ch, _key) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "passives") || !is_array(_ch.passives) || array_length(_ch.passives) <= 0) return 0;
    var total = 0;
    for (var i = 0; i < array_length(_ch.passives); i++) {
        var c = CardDB_Get(_ch.passives[i]);
        if (is_struct(c) && variable_struct_exists(c.params, _key)) total += real(variable_struct_get(c.params, _key));
    }
    return total;
}

function Card_HasPassive(_ch, _card_id) {
    return is_struct(_ch) && variable_struct_exists(_ch, "passives") && Card_ArrayHas(_ch.passives, _card_id);
}

function Card_GoldMult(_ch) { return 1 + Card_PassiveSum(_ch, "gold_mult"); }

// The passives as equipment-style passives ({ id, params, item_id, item_name }), so Equip_PassiveOnTurnStart & co. read them (Mana Spring).
function Card_EquipPassives(_ch) {
    var out = [];
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "passives") || !is_array(_ch.passives)) return out;
    for (var i = 0; i < array_length(_ch.passives); i++) {
        var c = CardDB_Get(_ch.passives[i]);
        if (is_struct(c)) array_push(out, { id: c.id, params: c.params, item_id: 0, item_name: Card_Name(c) });
    }
    return out;
}

// After a fight is won (Battle_GrantRewards, Enemy_AutoResolveFinalize): Field Medic, Second Wind, Scrounger.
function Card_OnVictory(_ch) {
    if (!is_struct(_ch)) return _ch;
    var heal = round(Card_PassiveSum(_ch, "heal_after_fight"));
    if (heal > 0 && variable_struct_exists(_ch, "max_hp")) _ch.hp = clamp(_ch.hp + heal, 0, _ch.max_hp);
    var mp = round(Card_PassiveSum(_ch, "mp_after_fight"));
    if (mp > 0 && variable_struct_exists(_ch, "max_mp")) _ch.mp = clamp(_ch.mp + mp, 0, _ch.max_mp);
    var find = Card_PassiveSum(_ch, "find_potion_pct");
    if (find > 0 && variable_struct_exists(_ch, "inventory") && Bag_Draw(Run_BagHolder(), "find", find, Run_Stream("loot"))) _ch.inventory = Inv_Add(_ch.inventory, 10, 1);
    return _ch;
}

// At the start of a fight (obj_battle_controller Create): Opening Blow gives the enemy's stagger meter a head start.
function Card_OnBattleStart(_p, _e) {
    var n = round(Card_PassiveSum(_p, "start_stagger"));
    if (n > 0 && is_struct(_e)) Stagger_Add(_e, n);
    return _e;
}

function Card_StatusTurnBonus(_user, _status_id) {
    if (_status_id == STATUS_STUN) return 0;
    return max(0, round(Card_PassiveSum(_user, "status_turn_bonus")));
}

// ---- upgrades on skills ---------------------------------------------------------------------------------------------------
// A copy of the skill with the upgrade's deltas applied (the database entry is never touched). The name gets a "+".
function Skill_WithUpgrade(_skill, _card) {
    var s = variable_clone(_skill);
    if (!is_struct(_card) || !variable_struct_exists(_card, "up")) return s;
    var u = _card.up;
    if (variable_struct_exists(u, "power")) s.power = s.power + u.power;
    if (variable_struct_exists(u, "mp_cost")) s.mp_cost = max(0, s.mp_cost + u.mp_cost);
    if (variable_struct_exists(u, "status_turns")) s.status_turns = s.status_turns + u.status_turns;
    if (variable_struct_exists(u, "status_stacks")) s.status_stacks = (variable_struct_exists(s, "status_stacks") ? s.status_stacks : 1) + u.status_stacks;
    if (variable_struct_exists(u, "status_chance")) s.status_chance = min(1, s.status_chance + u.status_chance);
    s.name = string(s.name) + "+";
    return s;
}

function Card_SeqTrimOf(_skill_id) {
    var c = CardDB_Get(Card_UpgradeId(_skill_id));
    if (is_struct(c) && variable_struct_exists(c.up, "seq_trim")) return c.up.seq_trim;
    return 0;
}

// Arrows of a skill's sequence when the player holds the listed upgrades.
function Card_UpgradedSequenceLength(_skill_id, _upgrades) {
    var n = array_length(Qte_SkillSequenceBase(_skill_id));
    if (Card_ArrayHas(_upgrades, _skill_id)) n = max(1, n - Card_SeqTrimOf(_skill_id));
    return n;
}

// The player the card effects on skills read: the current character (battle copies hold the same skills and upgrades).
function Card_PlayerRef() {
    if (!variable_global_exists("state") || !is_struct(global.state)) return undefined;
    if (!variable_struct_exists(global.state, "player_ch") || !is_struct(global.state.player_ch)) return undefined;
    return global.state.player_ch;
}

// Called by Qte_SkillSequence: a held upgrade removes arrows from the end (the start stays learned).
function Card_TrimSequence(_skill_id, _seq) {
    var ch = Card_PlayerRef();
    if (!is_struct(ch) || !variable_struct_exists(ch, "upgrades") || !Card_ArrayHas(ch.skills, _skill_id) || !Card_ArrayHas(ch.upgrades, _skill_id)) return _seq;
    var keep = max(1, array_length(_seq) - Card_SeqTrimOf(_skill_id));
    var out = [];
    for (var i = 0; i < keep; i++) array_push(out, _seq[i]);
    return out;
}

// Called by SkillDB_Get: what the equipped skill really is for this player (its upgrade, Barbed Arrows). Anything else comes back untouched.
function Card_ApplyToSkill(_s, _skill_id) {
    var ch = Card_PlayerRef();
    if (!is_struct(ch) || !variable_struct_exists(ch, "skills") || !Card_ArrayHas(ch.skills, _skill_id)) return _s;
    var out = _s;
    if (variable_struct_exists(ch, "upgrades") && Card_ArrayHas(ch.upgrades, _skill_id)) out = Skill_WithUpgrade(out, CardDB_Get(Card_UpgradeId(_skill_id)));
    var bonus = round(Card_PassiveSum(ch, "skill_power"));
    if (bonus > 0 && variable_struct_exists(out, "effect") && out.effect == "damage") {
        if (out == _s) out = variable_clone(_s);
        out.power = out.power + bonus;
    }
    var less = round(Card_PassiveSum(ch, "mp_cost_less"));
    if (less > 0 && out.mp_cost > 0) {
        if (out == _s) out = variable_clone(_s);
        out.mp_cost = max(1, out.mp_cost - less);
    }
    return out;
}

// ---- text from the data (D100) --------------------------------------------------------------------------------------------
function Card_Name(_c) {
    if (!is_struct(_c)) return "";
    if (_c.kind == "skill") return SkillDB_GetBase(_c.skill_id).name;
    if (_c.kind == "upgrade") return SkillDB_GetBase(_c.skill_id).name + "+";
    return Loc_T(_c.stem + ".name", _c.name_en);
}

function Card_TypeTag(_c) {
    switch (_c.kind) {
        case "skill": return Loc_T("card.tag.skill", "Skill");
        case "upgrade": return Loc_T("card.tag.upgrade", "Upgrade");
        case "passive": return array_length(_c.classes) > 0 ? Loc_T("card.tag.class_passive", "Class Passive") : Loc_T("card.tag.passive", "Passive");
    }
    return Loc_T("card.tag.boon", "Boon");
}

// 0.10 -> "10", 3 -> "3": fractions below 1 are shown as percent.
function Card_FormatN(_v) {
    if (_v < 1 && _v > 0) return string(round(_v * 100));
    return string(round(_v));
}

function Card_StatusNameSafe(_status_id) {
    if (_status_id == -1) return "";
    var cfg = StatusDB_Get(_status_id);
    return (is_struct(cfg) && variable_struct_exists(cfg, "name")) ? string(cfg.name) : "";   // the plain name, without the +/- sign of the tooltips
}

function Card_SkillSentence(_s) {
    var pw = string(round(_s.power));
    var status = Card_StatusNameSafe(_s.status);
    if (_s.effect == "damage") {
        var hits = variable_struct_exists(_s, "hits") ? round(_s.hits) : 1;
        var txt = (hits > 1) ? Loc_T("card.skill.hits", "Hit {hits} times for {power} power each.", { hits: string(hits), power: pw })
                             : Loc_T("card.skill.hit", "Hit for {power} power.", { power: pw });
        if (status != "" && _s.status_chance > 0) txt += " " + Loc_T("card.skill.hit_status", "{chance}% {status}.", { chance: string(round(_s.status_chance * 100)), status: status });
        return txt;
    }
    if (_s.effect == "status" && status != "") return Loc_T("card.skill.buff", "Gain {status} for {turns} turns.", { status: status, turns: string(round(_s.status_turns)) });
    return Loc_T("card.skill.other", "A special technique.");
}

function Card_Sentence(_c) {
    if (!is_struct(_c)) return "";
    if (_c.kind == "skill") return Card_SkillSentence(SkillDB_GetBase(_c.skill_id));
    if (_c.kind == "upgrade") return Card_SkillSentence(Skill_WithUpgrade(SkillDB_GetBase(_c.skill_id), _c));
    return Loc_T(_c.stem + ".line", _c.line_en, { n: Card_FormatN(real(variable_struct_get(_c.params, _c.main))) });
}

// The arrows a skill or upgrade card shows ([] for the others): the base sequence, or the upgraded one.
function Card_Sequence(_c) {
    if (!is_struct(_c) || (_c.kind != "skill" && _c.kind != "upgrade")) return [];
    var base = Qte_SkillSequenceBase(_c.skill_id);
    if (_c.kind == "skill") return base;
    var keep = max(1, array_length(base) - Card_SeqTrimOf(_c.skill_id));
    var out = [];
    for (var i = 0; i < keep; i++) array_push(out, base[i]);
    return out;
}

function Card_NumLine(_label, _a, _b = undefined) {
    var v = string(_a);
    if (!is_undefined(_b)) v += " > " + string(_b);
    return { label: _label, value: v };
}

function Card_Pct(_v) { return string(round(_v * 100)) + "%"; }

// Number lines: a skill card lists what the skill is; an upgrade card lists only what changes (a > b); a passive lists its params.
function Card_Lines(_c) {
    var lines = [];
    if (!is_struct(_c)) return lines;
    if (_c.kind == "skill" || _c.kind == "upgrade") {
        var a = SkillDB_GetBase(_c.skill_id);
        var b = (_c.kind == "upgrade") ? Skill_WithUpgrade(a, _c) : undefined;
        var up = !is_undefined(b);
        var seq_a = array_length(Qte_SkillSequenceBase(_c.skill_id));
        var seq_b = array_length(Card_Sequence(_c));
        if (a.effect == "damage" && (!up || b.power != a.power)) array_push(lines, Card_NumLine(Loc_T("card.lbl.power", "Power"), round(a.power), up ? round(b.power) : undefined));
        if (!up || b.mp_cost != a.mp_cost) array_push(lines, Card_NumLine(Loc_T("card.lbl.mp", "MP"), round(a.mp_cost), up ? round(b.mp_cost) : undefined));
        if (up && seq_a != seq_b) array_push(lines, Card_NumLine(Loc_T("card.lbl.arrows", "Arrows"), seq_a, seq_b));   // a plain skill card draws its arrows instead
        if (a.status != -1) {
            if (up && a.effect == "damage" && b.status_chance != a.status_chance) array_push(lines, Card_NumLine(Loc_T("card.lbl.chance", "Chance"), Card_Pct(a.status_chance), Card_Pct(b.status_chance)));
            if (up && b.status_turns != a.status_turns) array_push(lines, Card_NumLine(Loc_T("card.lbl.turns", "Turns"), round(a.status_turns), round(b.status_turns)));
            var sta = variable_struct_exists(a, "status_stacks") ? round(a.status_stacks) : 0;
            if (up && sta > 0 && b.status_stacks != a.status_stacks) array_push(lines, Card_NumLine(Loc_T("card.lbl.stacks", "Stacks"), sta, round(b.status_stacks)));
            if (!up && a.effect != "damage") array_push(lines, Card_NumLine(Loc_T("card.lbl.turns", "Turns"), round(a.status_turns)));
        }
        return lines;
    }
    var keys = variable_struct_get_names(_c.params);
    array_sort(keys, true);
    for (var k = 0; k < array_length(keys); k++) {
        var val = real(variable_struct_get(_c.params, keys[k]));
        switch (keys[k]) {
            case "stat_atk": array_push(lines, Card_NumLine(Loc_T("card.lbl.atk", "ATK"), "+" + string(round(val)))); break;
            case "stat_def": array_push(lines, Card_NumLine(Loc_T("card.lbl.def", "DEF"), "+" + string(round(val)))); break;
            case "stat_spd": array_push(lines, Card_NumLine(Loc_T("card.lbl.spd", "SPD"), "+" + string(round(val)))); break;
            case "stat_mag": array_push(lines, Card_NumLine(Loc_T("card.lbl.mag", "MAG"), "+" + string(round(val)))); break;
            case "stat_main": array_push(lines, Card_NumLine(Loc_T("card.lbl.main_stat", "Main Stat"), "+" + string(round(val)))); break;
            case "poison_stacks": array_push(lines, Card_NumLine(Loc_T("card.lbl.poison_stacks", "Poison Stacks"), "+" + string(round(val)))); break;
            case "heal_after_fight": array_push(lines, Card_NumLine(Loc_T("card.lbl.after_fight", "After Battle"), Loc_T("card.val.hp", "+{n} HP", { n: string(round(val)) }))); break;
            case "mp_after_fight": array_push(lines, Card_NumLine(Loc_T("card.lbl.after_fight", "After Battle"), Loc_T("card.val.mp", "+{n} MP", { n: string(round(val)) }))); break;
            case "find_potion_pct": array_push(lines, Card_NumLine(Loc_T("card.lbl.potion_find", "Potion Find"), Card_Pct(val))); break;
            case "perfect_widen": array_push(lines, Card_NumLine(Loc_T("card.lbl.perfect", "Perfect Zone"), "+" + Card_Pct(val))); break;
            case "gold_mult": array_push(lines, Card_NumLine(Loc_T("card.lbl.gold", "Gold"), "+" + Card_Pct(val))); break;
            case "mp_gain": array_push(lines, Card_NumLine(Loc_T("card.lbl.each_turn", "Each Turn"), Loc_T("card.val.mp", "+{n} MP", { n: string(round(val)) }))); break;
            case "item_power": array_push(lines, Card_NumLine(Loc_T("card.lbl.potions", "Potions"), "+" + Card_Pct(val))); break;
            case "guard_turns": array_push(lines, Card_NumLine(Loc_T("card.lbl.guard", "Guard"), Loc_T("card.val.turns", "+{n} turns", { n: string(round(val)) }))); break;
            case "skill_power": array_push(lines, Card_NumLine(Loc_T("card.lbl.skill_power", "Skill Power"), "+" + string(round(val)))); break;
            case "mp_cost_less": array_push(lines, Card_NumLine(Loc_T("card.lbl.skill_mp", "Skill MP"), "-" + string(round(val)))); break;
            case "status_turn_bonus": array_push(lines, Card_NumLine(Loc_T("card.lbl.status_turns", "Status Turns"), "+" + string(round(val)))); break;
            case "start_stagger": array_push(lines, Card_NumLine(Loc_T("card.lbl.stagger", "Stagger"), "+" + string(round(val)))); break;
            case "potion_mp": array_push(lines, Card_NumLine(Loc_T("card.lbl.potion_mp", "Potion MP"), "+" + string(round(val)))); break;
            case "heal_pct": array_push(lines, Card_NumLine(Loc_T("card.lbl.restores", "Restores"), Loc_T("card.val.restores", "{pct} HP, MP", { pct: Card_Pct(val) }))); break;
            case "gold": array_push(lines, Card_NumLine(Loc_T("card.lbl.gold", "Gold"), "+" + string(round(val)))); break;
        }
    }
    return lines;
}

// ---- the offer (roguelike-cases.md 2.2) -----------------------------------------------------------------------------------
function Card_StateNew() {
    return { pity: 0, last: [], offers: 0 };
}

function Card_StateNormalize(_st) {
    var out = Card_StateNew();
    if (!is_struct(_st)) return out;
    if (variable_struct_exists(_st, "pity") && is_real(_st.pity)) out.pity = max(0, _st.pity);
    if (variable_struct_exists(_st, "offers") && is_real(_st.offers)) out.offers = max(0, _st.offers);
    if (variable_struct_exists(_st, "last") && is_array(_st.last)) for (var i = 0; i < array_length(_st.last); i++) array_push(out.last, _st.last[i]);
    return out;
}

// Can this card be offered to this character right now? (Fallbacks always can; they are only used to fill.)
function Card_Eligible(_ch, _c) {
    if (!is_struct(_c) || !is_struct(_ch)) return false;
    if (_c.kind == "fallback") return true;
    if (!Card_ForClass(_c, _ch.class_id)) return false;
    switch (_c.kind) {
        case "skill": return !Card_ArrayHas(_ch.skills, _c.skill_id);
        case "upgrade": return Card_ArrayHas(_ch.skills, _c.skill_id) && !Card_ArrayHas(_ch.upgrades, _c.skill_id);
        case "passive": return !Card_ArrayHas(_ch.passives, _c.id);
    }
    return false;
}

function Card_EligibleLists(_ch) {
    var out = { skill: [], upgrade: [], passive: [] };
    var clist = CardDB_All();
    for (var i = 0; i < array_length(clist); i++) {
        if (clist[i].kind == "fallback" || !Card_Eligible(_ch, clist[i])) continue;
        array_push(variable_struct_get(out, clist[i].kind), clist[i].id);
    }
    return out;
}

function Card_ListsWithout(_lists, _ids) {
    var out = { skill: [], upgrade: [], passive: [] };
    var kinds = ["skill", "upgrade", "passive"];
    for (var k = 0; k < 3; k++) {
        var src = variable_struct_get(_lists, kinds[k]);
        var dst = variable_struct_get(out, kinds[k]);
        for (var i = 0; i < array_length(src); i++) if (!Card_ArrayHas(_ids, src[i])) array_push(dst, src[i]);
    }
    return out;
}

function Card_ListsCount(_lists) {
    return array_length(_lists.skill) + array_length(_lists.upgrade) + array_length(_lists.passive);
}

// Weight of a kind in the draw: new skills while the slots are not full, upgrades once they are (roguelike-cases.md 2.2 step 4).
function Card_KindWeight(_kind, _owned) {
    var full = (_owned >= CARD_MAX_SKILLS);
    switch (_kind) {
        case "skill": return full ? 1 : 3;
        case "upgrade": return full ? 3 : 1;
        case "passive": return 2;
    }
    return 0;
}

function Card_PickedHasKind(_picked, _kind) {
    for (var i = 0; i < array_length(_picked); i++) if (CardDB_Get(_picked[i]).kind == _kind) return true;
    return false;
}

// Fills _picked up to CARD_OFFER_SIZE from _lists: draw a kind by weight, then a card of it (uniform). With every slot full, at most one new
// skill (each would need a swap).
function Card_FillPicks(_rng, _picked, _lists, _owned) {
    var kinds = ["skill", "upgrade", "passive"];
    while (array_length(_picked) < CARD_OFFER_SIZE) {
        var skill_blocked = (_owned >= CARD_MAX_SKILLS) && Card_PickedHasKind(_picked, "skill");
        var total = 0;
        for (var k = 0; k < 3; k++) {
            if (kinds[k] == "skill" && skill_blocked) continue;
            if (array_length(variable_struct_get(_lists, kinds[k])) > 0) total += Card_KindWeight(kinds[k], _owned);
        }
        if (total <= 0) break;
        var r = Rng_Float(_rng) * total;
        var acc = 0;
        var kind = "";
        for (var k2 = 0; k2 < 3; k2++) {
            if (kinds[k2] == "skill" && skill_blocked) continue;
            if (array_length(variable_struct_get(_lists, kinds[k2])) <= 0) continue;
            acc += Card_KindWeight(kinds[k2], _owned);
            kind = kinds[k2];
            if (r < acc) break;
        }
        var src = variable_struct_get(_lists, kind);
        var pid = src[Rng_Int(_rng, array_length(src))];
        array_push(_picked, pid);
        variable_struct_set(_lists, kind, Card_ArrayWithout(src, pid));
    }
    return _picked;
}

// 3 distinct cards for _ch from the class pool. _rng is the run's "cards" stream, _state the run's { pity, last, offers }.
// Rules: weighted by kind (new skill / upgrade / passive); a new skill is guaranteed while fewer than 2 are held (so a fresh class gets skills);
// with all slots full at most one new-skill card; the pity counter forces an upgrade after CARD_PITY_OFFERS offers without one (when one was
// possible); the previous offer's cards are not shown again while other cards exist; a dry pool is filled with fallbacks. Returns
// { cards, state, forced }. Pure apart from drawing from _rng.
function Card_OfferGenerate(_rng, _ch, _state) {
    var st = Card_StateNormalize(_state);
    var owned = array_length(_ch.skills);
    var elig = Card_EligibleLists(_ch);
    var could_upgrade = array_length(elig.upgrade) > 0;
    var lists = Card_ListsWithout(elig, st.last);
    if (Card_ListsCount(lists) < CARD_OFFER_SIZE) lists = Card_ListsWithout(elig, []);
    var picked = [];
    var forced = false;

    if (st.pity >= CARD_PITY_OFFERS && could_upgrade) {
        var pu = (array_length(lists.upgrade) > 0) ? lists.upgrade : elig.upgrade;
        var pid = pu[Rng_Int(_rng, array_length(pu))];
        array_push(picked, pid);
        forced = true;
        lists = Card_ListsWithout(lists, [pid]);
        elig = Card_ListsWithout(elig, [pid]);
    }
    if (owned < 2 && !Card_PickedHasKind(picked, "skill")) {
        var ps = (array_length(lists.skill) > 0) ? lists.skill : elig.skill;
        if (array_length(ps) > 0) {
            var sid = ps[Rng_Int(_rng, array_length(ps))];
            array_push(picked, sid);
            lists = Card_ListsWithout(lists, [sid]);
            elig = Card_ListsWithout(elig, [sid]);
        }
    }
    picked = Card_FillPicks(_rng, picked, lists, owned);
    if (array_length(picked) < CARD_OFFER_SIZE) picked = Card_FillPicks(_rng, picked, Card_ListsWithout(elig, picked), owned);
    if (array_length(picked) < CARD_OFFER_SIZE) {
        var fb = Rng_Shuffle(_rng, Card_FallbackIds());
        for (var f = 0; f < array_length(fb) && array_length(picked) < CARD_OFFER_SIZE; f++) if (!Card_ArrayHas(picked, fb[f])) array_push(picked, fb[f]);
    }
    picked = Rng_Shuffle(_rng, picked);

    var has_upgrade = Card_PickedHasKind(picked, "upgrade");
    var out_state = { pity: has_upgrade ? 0 : (could_upgrade ? st.pity + 1 : st.pity), last: picked, offers: st.offers + 1 };
    return { cards: picked, state: out_state, forced: forced };
}

// The offer for _ch drawn from the active run's "cards" stream (the free stream when no run is going); updates the run's pity/last state.
function Card_OfferFromRun(_ch) {
    var run = Run_Get();
    var st = (is_struct(run) && variable_struct_exists(run, "cards")) ? run.cards : Card_StateNew();
    var off = Card_OfferGenerate(Run_Stream("cards"), _ch, st);
    if (is_struct(run)) run.cards = off.state;
    return off;
}

// ---- taking a card -------------------------------------------------------------------------------------------------------
function Card_RecomputeKeep(_ch) {
    var mhp = _ch.max_hp;
    var mmp = _ch.max_mp;
    var hp = _ch.hp;
    var mp = _ch.mp;
    _ch = RecomputeResources(_ch);
    _ch.hp = clamp(hp + max(0, _ch.max_hp - mhp), 0, _ch.max_hp);
    _ch.mp = clamp(mp + max(0, _ch.max_mp - mmp), 0, _ch.max_mp);
    return _ch;
}

function Card_AddStat(_ch, _stat_id, _n) {
    var key = Stat_Key(_stat_id);
    if (key == "") return _ch;
    variable_struct_set(_ch.stats, key, StatClamp(variable_struct_get(_ch.stats, key) + _n));
    return _ch;
}

// The stat bonuses of the passives a character holds (also used to rebuild them when the class changes).
function Card_ApplyStatPassives(_ch) {
    _ch = Card_AddStat(_ch, STAT_ATK, round(Card_PassiveSum(_ch, "stat_atk")));
    _ch = Card_AddStat(_ch, STAT_DEF, round(Card_PassiveSum(_ch, "stat_def")));
    _ch = Card_AddStat(_ch, STAT_SPD, round(Card_PassiveSum(_ch, "stat_spd")));
    _ch = Card_AddStat(_ch, STAT_MAG, round(Card_PassiveSum(_ch, "stat_mag")));
    return _ch;
}

// Takes a card. Returns { ch (a changed copy), needs_replace, card, gold }. A skill with every slot full changes nothing yet: the caller
// asks which skill to replace and calls Card_ReplaceSkill. Gold (Coin Purse) is for the caller to add to the run.
function Card_Take(_ch, _card_id) {
    var ch = Card_EnsureFields(variable_clone(_ch));
    var c = CardDB_Get(_card_id);
    var out = { ch: ch, needs_replace: false, card: c, gold: 0 };
    if (!is_struct(c)) return out;
    switch (c.kind) {
        case "skill":
            if (array_length(ch.skills) >= CARD_MAX_SKILLS) out.needs_replace = true;
            else if (!Card_ArrayHas(ch.skills, c.skill_id)) {
                array_push(ch.skills, c.skill_id);
                Skill_Discover(c.skill_id);   // D148: the profile remembers every skill that was ever learned
            }
        break;
        case "upgrade":
            if (!Card_ArrayHas(ch.upgrades, c.skill_id)) array_push(ch.upgrades, c.skill_id);
        break;
        case "passive":
            if (!Card_ArrayHas(ch.passives, c.id)) {
                array_push(ch.passives, c.id);
                ch = Card_AddStat(ch, STAT_ATK, round(variable_struct_exists(c.params, "stat_atk") ? c.params.stat_atk : 0));
                ch = Card_AddStat(ch, STAT_DEF, round(variable_struct_exists(c.params, "stat_def") ? c.params.stat_def : 0));
                ch = Card_AddStat(ch, STAT_SPD, round(variable_struct_exists(c.params, "stat_spd") ? c.params.stat_spd : 0));
                ch = Card_AddStat(ch, STAT_MAG, round(variable_struct_exists(c.params, "stat_mag") ? c.params.stat_mag : 0));
                ch = Card_RecomputeKeep(ch);
            }
        break;
        case "fallback":
            if (variable_struct_exists(c.params, "heal_pct")) {
                ch.hp = clamp(ch.hp + floor(ch.max_hp * c.params.heal_pct), 0, ch.max_hp);
                ch.mp = clamp(ch.mp + floor(ch.max_mp * c.params.heal_pct), 0, ch.max_mp);
            }
            if (variable_struct_exists(c.params, "gold")) out.gold = round(c.params.gold);
            if (variable_struct_exists(c.params, "stat_main")) {
                ch = Card_AddStat(ch, DB_PlayerClass(ch.class_id).free_default, round(c.params.stat_main));
                ch = Card_RecomputeKeep(ch);
            }
        break;
    }
    out.ch = ch;
    return out;
}

// Puts _new_skill in the slot of _old_skill (D82). The old skill's upgrade goes with it. Returns the changed copy.
function Card_ReplaceSkill(_ch, _old_skill, _new_skill) {
    var ch = Card_EnsureFields(variable_clone(_ch));
    for (var i = 0; i < array_length(ch.skills); i++) {
        if (ch.skills[i] == _old_skill) { ch.skills[i] = _new_skill; break; }
    }
    ch.upgrades = Card_ArrayWithout(ch.upgrades, _old_skill);
    ch.skill_pending = -1;
    Skill_Discover(_new_skill);   // D148
    return ch;
}

// ---- classes (D34, D73, D83) ----------------------------------------------------------------------------------------------
// The class screen's rows. Nobody is locked until the profile has a win (D83, D88).
function Card_ClassChoices(_prof = undefined) {
    var prof = is_undefined(_prof) ? Profile_Get() : _prof;
    var ids = [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE, CLASS_NOBODY];
    var out = [];
    for (var i = 0; i < array_length(ids); i++) {
        var locked = (ids[i] == CLASS_NOBODY) && !Profile_IsUnlocked(prof, "nobody_class");
        array_push(out, { class_id: ids[i], locked: locked, hint: locked ? Loc_T("class.nobody.locked_hint", "Win a run to unlock this path.") : "" });
    }
    return out;
}

function Card_ClassSentence(_class_id) {
    switch (_class_id) {
        case CLASS_KNIGHT: return Loc_T("class.line.knight", "Guard of a keep that fell. Hits hard, slow to be hurt.");
        case CLASS_ARCHER: return Loc_T("class.line.archer", "A scout of the dark. Quick, with [t]Poison[/t] and double shots.");
        case CLASS_MAGE: return Loc_T("class.line.mage", "A scholar the dark read back. Frail; spells hit hard.");
        case CLASS_NOBODY: return Loc_T("class.line.nobody", "No name, no past, no skills. A blade and your pockets.");
    }
    return "";
}

// ---- skill memory on the class screen (D148) ----
// The player skills of a class, in id order (the skill cards' class lists; Rev Up belongs to both the Knight and the Archer). Nobody has none.
function Skill_IdsOfClass(_class_id) {
    var out = [];
    var clist = CardDB_All();
    for (var i = 0; i < array_length(clist); i++) {
        var c = clist[i];
        if (c.kind != "skill" || array_length(c.classes) <= 0 || !Card_ArrayHas(c.classes, _class_id)) continue;
        if (!Card_ArrayHas(out, c.skill_id)) array_push(out, c.skill_id);
    }
    return out;
}

// The skills of the class that _prof has had in some run.
function Skill_KnownOfClass(_prof, _class_id) {
    var ids = Skill_IdsOfClass(_class_id);
    var out = [];
    for (var i = 0; i < array_length(ids); i++) {
        if (Profile_SkillKnown(_prof, ids[i])) array_push(out, ids[i]);
    }
    return out;
}

// One row per skill of the class for the class screen: the name once discovered, "???" before.
function Class_SkillRows(_prof, _class_id) {
    var ids = Skill_IdsOfClass(_class_id);
    var out = [];
    for (var i = 0; i < array_length(ids); i++) {
        var known = Profile_SkillKnown(_prof, ids[i]);
        array_push(out, { id: ids[i], known: known, label: known ? SkillDB_GetBase(ids[i]).name : Loc_T("class.skill.unknown", "???") });
    }
    return out;
}

// A copy of _old as the new class: level, items and cards carried over, stats rebuilt from the class (its fixed growth per level, the spent free
// points back in the bank to place again), skills the new class cannot use dropped. Marks the class chosen and clears the owed choice.
function Card_ClassCharacter(_old, _class_id) {
    var ch = CharacterCreate_Player(_class_id);
    if (is_struct(_old)) {
        var lvl = variable_struct_exists(_old, "level") ? max(1, round(_old.level)) : 1;
        ch.level = lvl;
        if (variable_struct_exists(_old, "exp")) ch.exp = _old.exp;
        ch.levels_owed = LevelUp_Owed(_old);   // D177: a level won and not yet confirmed stays owed (the EXP is the carry-over after it)
        if (variable_struct_exists(_old, "inventory")) {
            ch.inventory = variable_clone(_old.inventory);
            // D84: a class carries 5 of a throwable, only Nobody 8; the extra units are dropped when the class is picked
            var cap = Throw_Cap(ch);
            var throw_ids = [];
            for (var ti = 0; ti < array_length(ch.inventory); ti++) {
                var tid = ch.inventory[ti].id;
                if (Item_IsThrowable(ItemDB_Get(tid)) && !array_contains(throw_ids, tid)) array_push(throw_ids, tid);
            }
            for (var tj = 0; tj < array_length(throw_ids); tj++) {
                var over = Inv_Count(ch.inventory, throw_ids[tj]) - cap;
                if (over > 0) ch.inventory = Inv_Remove(ch.inventory, throw_ids[tj], over);
            }
        }
        if (variable_struct_exists(_old, "equip")) ch.equip = variable_clone(_old.equip);
        if (variable_struct_exists(_old, "status")) ch.status = variable_clone(_old.status);
        var banked = variable_struct_exists(_old, "stat_points") ? _old.stat_points : 0;
        var spent = max(0, (lvl - 1) * LEVEL_FREE_POINTS_PER_LEVEL - banked);
        ch.stat_points = banked + spent;
        for (var l = 2; l <= lvl; l++) {
            var g = LevelUp_ClassGrowthGain(_class_id, l);
            ch.stats.atk = StatClamp(ch.stats.atk + g.atk);
            ch.stats.def = StatClamp(ch.stats.def + g.def);
            ch.stats.spd = StatClamp(ch.stats.spd + g.spd);
            ch.stats.mag = StatClamp(ch.stats.mag + g.mag);
            ch.stats.vig = StatClamp(ch.stats.vig + g.vig);   // D176
            ch.stats.mnd = StatClamp(ch.stats.mnd + g.mnd);
        }
        Card_EnsureFields(_old);
        var kept = [];
        var kept_up = [];
        for (var i = 0; i < array_length(_old.skills); i++) {
            var sk = SkillDB_GetBase(_old.skills[i]);
            if (array_length(kept) < CARD_MAX_SKILLS && Skill_ClassAllowed(sk, _class_id) && array_length(sk.class_list) > 0) {
                array_push(kept, _old.skills[i]);
                if (Card_ArrayHas(_old.upgrades, _old.skills[i])) array_push(kept_up, _old.skills[i]);
            }
        }
        ch.skills = kept;
        ch.upgrades = kept_up;
        ch.passives = variable_clone(_old.passives);
        ch.card_picks = _old.card_picks;
        ch.offer = variable_clone(_old.offer);
        ch = Card_ApplyStatPassives(ch);
        ch = RecomputeResources(ch);
        var hp0 = variable_struct_exists(_old, "hp") ? _old.hp : ch.max_hp;
        var mp0 = variable_struct_exists(_old, "mp") ? _old.mp : ch.max_mp;
        ch.hp = clamp(hp0, 1, ch.max_hp);
        ch.mp = clamp(mp0, 0, ch.max_mp);
        ch.exp_next = Exp_NextLevel(ch.level);
    }
    ch.class_chosen = true;
    ch.class_pick = false;
    return ch;
}
