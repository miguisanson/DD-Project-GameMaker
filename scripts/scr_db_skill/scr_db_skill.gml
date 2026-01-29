function SkillDB_Init() {
    if (variable_global_exists("skill_db") && ds_exists(global.skill_db, ds_type_map)) return;
    global.skill_db = ds_map_create();

    global.skill_db[? SKILL_POWER_STRIKE] = {
        id: SKILL_POWER_STRIKE,
        name: "Power Strike",
        mp_cost: 2,
        power: 3,
        power_mult: 1,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: iron_sword,
        fx_sprite: iron_sword,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 1,
        class_list: []
    };

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
        icon_sprite: bandage,
        fx_sprite: bandage,
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
        icon_sprite: rock1,
        fx_sprite: rock1,
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
        icon_sprite: rock2,
        fx_sprite: rock2,
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
        icon_sprite: torch_asset_moving,
        fx_sprite: torch_asset_moving,
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
        icon_sprite: wooden_sword,
        fx_sprite: wooden_sword,
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
        icon_sprite: antidote,
        fx_sprite: antidote,
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
        icon_sprite: tall_grass_asset,
        fx_sprite: tall_grass_asset,
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
        icon_sprite: wooden_bow,
        fx_sprite: wooden_bow,
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
        icon_sprite: skull_2_asset,
        fx_sprite: skull_2_asset,
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
        icon_sprite: fire_stand_moving,
        fx_sprite: fire_stand_moving,
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
        icon_sprite: antidote,
        fx_sprite: antidote,
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
        icon_sprite: rock2,
        fx_sprite: rock2,
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
        icon_sprite: mp_potion,
        fx_sprite: mp_potion,
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
        icon_sprite: horned_skull_asset,
        fx_sprite: horned_skull_asset,
        fx_frames: 12,
        fx_speed: 0.2,
        hits: 0,
        class_list: [CLASS_MAGE]
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
    return { id: -1, name: "Unknown", mp_cost: 0, power: 0, power_mult: 1, stat_type: STAT_STR, acc: 0, target: TGT_ENEMY, effect: "damage", status: -1, status_turns: 0, status_chance: 0, icon_sprite: noone, fx_sprite: noone, fx_frames: 12, fx_speed: 0.2, hits: 1, class_list: [] };
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

function Skill_Use(_user, _target, _skill_id) {
    var s = SkillDB_Get(_skill_id);
    var result = { ok: true, hit: true, dmg: 0, crit: false, msg: "", fx_sprite: s.fx_sprite, fx_frames: s.fx_frames, fx_speed: s.fx_speed };

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

    // status-only skills
    if (s.effect == "status") {
        if (s.status != -1) {
            _target = Status_Add(_target, s.status, s.status_turns, 1);
            var cfg = StatusDB_Get(s.status);
            result.msg = cfg.name + " applied.";
        } else {
            result.msg = "Skill used.";
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
        var acc_bonus = s.acc + StatMod(Stat_Get(_user, s.stat_type));

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

        if (s.status != -1 && any_hit) {
            if (s.status_chance >= 1 || random(1) <= s.status_chance) {
                _target = Status_Add(_target, s.status, s.status_turns, 1);
                var cfg2 = StatusDB_Get(s.status);
                result.msg = cfg2.name + " applied.";
            }
        }
    }

    if (s.effect == "heal") {
        var amt = s.power + max(0, StatMod(Stat_Get(_user, s.stat_type)));
        _target.hp = clamp(_target.hp + amt, 0, _target.max_hp);
        result.dmg = -amt;
    }

    return result;
}
