function SkillDB_Init() {
    if (variable_global_exists("skill_db") && ds_exists(global.skill_db, ds_type_map)) return;
    global.skill_db = ds_map_create();

    global.skill_db[? SKILL_POWER_STRIKE] = {
        id: SKILL_POWER_STRIKE,
        name: "Power Strike",
        mp_cost: 2,
        power: 3,
        stat_type: STAT_STR,
        acc: 0,
        target: TGT_ENEMY,
        effect: "damage",
        status: -1,
        status_turns: 0,
        status_chance: 0,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2
    };

    global.skill_db[? SKILL_FOCUS] = {
        id: SKILL_FOCUS,
        name: "Focus",
        mp_cost: 3,
        power: 0,
        stat_type: STAT_INT,
        acc: 0,
        target: TGT_SELF,
        effect: "status",
        status: STATUS_REGEN,
        status_turns: 3,
        status_chance: 1,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2
    };

    global.skill_db[? SKILL_FIRE] = {
        id: SKILL_FIRE,
        name: "Fire",
        mp_cost: 4,
        power: 4,
        stat_type: STAT_INT,
        acc: 1,
        target: TGT_ENEMY,
        effect: "damage",
        status: STATUS_POISON,
        status_turns: 2,
        status_chance: 0.25,
        icon_sprite: noone,
        fx_sprite: noone,
        fx_frames: 12,
        fx_speed: 0.2
    };

    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.skill_db = global.skill_db;
    }
}

function SkillDB_Get(_skill_id) {
    if (ds_exists(global.skill_db, ds_type_map) && ds_map_exists(global.skill_db, _skill_id)) {
        return global.skill_db[? _skill_id];
    }
    return { id: -1, name: "Unknown", mp_cost: 0, power: 0, stat_type: STAT_STR, acc: 0, target: TGT_ENEMY, effect: "damage", status: -1, status_turns: 0, status_chance: 0, icon_sprite: noone, fx_sprite: noone, fx_frames: 12, fx_speed: 0.2 };
}

function Skill_CanUse(_ch, _skill) {
    return _ch.mp >= _skill.mp_cost;
}

function Skill_Use(_user, _target, _skill_id) {
    var s = SkillDB_Get(_skill_id);
    var result = { ok: true, hit: true, dmg: 0, crit: false, msg: "", fx_sprite: s.fx_sprite, fx_frames: s.fx_frames, fx_speed: s.fx_speed };

    if (!Skill_CanUse(_user, s)) {
        result.ok = false;
        result.msg = "Not enough MP.";
        return result;
    }

    _user.mp -= s.mp_cost;

    if (s.effect == "damage") {
        var hit_roll = RollD20() + StatMod(Stat_Get(_user, s.stat_type)) + s.acc;
        var dodge_roll = RollD20() + Combat_DodgeBonus(_target);

        result.hit = (hit_roll >= dodge_roll);
        if (result.hit) {
            var weapon = { power: s.power, stat_type: s.stat_type, acc: s.acc };
            result.dmg = Combat_Damage(_user, _target, weapon);
            result.crit = Combat_CritCheck(_user, 0);
            if (result.crit) result.dmg *= 2;
            _target.hp = max(0, _target.hp - result.dmg);
        }
    }

    if (s.effect == "heal") {
        var amt = s.power + max(0, StatMod(Stat_Get(_user, s.stat_type)));
        _target.hp = clamp(_target.hp + amt, 0, _target.max_hp);
        result.dmg = -amt;
    }

    if (s.status != -1) {
        if (s.status_chance >= 1 || random(1) <= s.status_chance) {
            _target = Status_Add(_target, s.status, s.status_turns, 1);
            if (result.msg == "") result.msg = "Status applied.";
        }
    }

    return result;
}
