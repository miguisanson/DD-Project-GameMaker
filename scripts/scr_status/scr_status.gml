function Status_ResolveIcon(_asset_name, _fallback_sprite) {
    var spr = asset_get_index(_asset_name);
    if (is_real(spr) && spr != -1) return spr;
    return _fallback_sprite;
}

function Status_SetIcon(_status_id, _icon_sprite, _icon_subimg = 0) {
    if (!variable_global_exists("status_db") || !ds_exists(global.status_db, ds_type_map)) return;
    if (!ds_map_exists(global.status_db, _status_id)) return;

    var s = global.status_db[? _status_id];
    if (!is_struct(s)) return;

    s.icon_sprite = _icon_sprite;

    var sub = max(0, round(_icon_subimg));
    if (is_real(_icon_sprite) && _icon_sprite != -1 && _icon_sprite != noone) {
        var max_sub = max(0, sprite_get_number(_icon_sprite) - 1);
        sub = clamp(sub, 0, max_sub);
    } else {
        sub = 0;
    }
    s.icon_subimg = sub;
}

function Status_LastFrame(_sprite) {
    if (!is_real(_sprite) || _sprite == -1 || _sprite == noone) return 0;
    return max(0, sprite_get_number(_sprite) - 1);
}

function Status_AssignCoreIcons() {
    if (!variable_global_exists("status_db") || !ds_exists(global.status_db, ds_type_map)) return;

    Status_SetIcon(STATUS_POISON, poison_status, 0);
    Status_SetIcon(STATUS_BLEED, bleed_status, 0);
    Status_SetIcon(STATUS_BURN, burn_status, 0);
    Status_SetIcon(STATUS_STUN, stun_status, 0);
}

function Status_AssignPlayerBuffIconsFromFX() {
    if (!variable_global_exists("status_db") || !ds_exists(global.status_db, ds_type_map)) return;

    var sp_guard = Status_ResolveIcon("muscle_up_effect", rock1);
    var sp_dmg_up = Status_ResolveIcon("rev_up_effect", torch_asset_moving);
    var sp_evasion = Status_ResolveIcon("evasion_up_effect", tall_grass_asset);
    var sp_crit_up = Status_ResolveIcon("take_aim_effect", skull_2_asset);
    var sp_hit_up = Status_ResolveIcon("foresight_effect_Sheet", Status_ResolveIcon("take_aim_effect", skull_2_asset));
    var sp_meditation = Status_ResolveIcon("meditation", mp_potion);

    Status_SetIcon(STATUS_GUARD, sp_guard, Status_LastFrame(sp_guard));
    Status_SetIcon(STATUS_DMG_UP, sp_dmg_up, Status_LastFrame(sp_dmg_up));
    Status_SetIcon(STATUS_EVASION, sp_evasion, Status_LastFrame(sp_evasion));
    Status_SetIcon(STATUS_CRIT_UP, sp_crit_up, Status_LastFrame(sp_crit_up));
    Status_SetIcon(STATUS_HIT_UP, sp_hit_up, 0);
    Status_SetIcon(STATUS_MEDITATION, sp_meditation, Status_LastFrame(sp_meditation));
}

function Status_SkillAppliesStatus(_skill, _status_id) {
    if (!is_struct(_skill)) return false;
    if (variable_struct_exists(_skill, "status") && _skill.status == _status_id) return true;
    if (variable_struct_exists(_skill, "status_list") && is_array(_skill.status_list)) {
        for (var i = 0; i < array_length(_skill.status_list); i++) {
            if (_skill.status_list[i] == _status_id) return true;
        }
    }
    return false;
}

function Status_FindIconFallbackFromSkillFX(_status_id) {
    if (!variable_global_exists("skill_db") || !ds_exists(global.skill_db, ds_type_map)) {
        SkillDB_Init();
    }
    if (!variable_global_exists("skill_db") || !ds_exists(global.skill_db, ds_type_map)) return noone;

    var keys = ds_map_keys_to_array(global.skill_db);
    for (var i = 0; i < array_length(keys); i++) {
        var sid = keys[i];
        var sk = global.skill_db[? sid];
        if (!Status_SkillAppliesStatus(sk, _status_id)) continue;
        if (is_struct(sk) && variable_struct_exists(sk, "fx_sprite") && sk.fx_sprite != noone) {
            return sk.fx_sprite;
        }
    }

    return noone;
}

function Status_AssignMissingIconsFromSkillFX() {
    if (!variable_global_exists("status_db") || !ds_exists(global.status_db, ds_type_map)) return;

    var keys = ds_map_keys_to_array(global.status_db);
    for (var i = 0; i < array_length(keys); i++) {
        var status_id = keys[i];
        var cfg = global.status_db[? status_id];
        if (!is_struct(cfg)) continue;

        var has_icon = (variable_struct_exists(cfg, "icon_sprite") && cfg.icon_sprite != noone);
        if (has_icon) continue;

        var spr = Status_FindIconFallbackFromSkillFX(status_id);
        if (spr == noone) continue;
        Status_SetIcon(status_id, spr, Status_LastFrame(spr));
    }
}

function StatusDB_Init() {
    if (variable_global_exists("status_db") && ds_exists(global.status_db, ds_type_map)) {
        Status_AssignCoreIcons();
        Status_AssignPlayerBuffIconsFromFX();
        Status_AssignMissingIconsFromSkillFX();
        if (variable_global_exists("state") && is_struct(global.state)) {
            global.state.status_db = global.status_db;
        }
        return;
    }
    global.status_db = ds_map_create();

    // D78 damage over time. All three coexist (no `excludes`). Numbers: combat-spec.md section 10.
    // dot_kind drives Status_Add (stacking), Status_Tick (damage and decay) and Status_Describe (text).
    global.status_db[? STATUS_POISON] = {
        id: STATUS_POISON,
        name: "Poison",
        icon_sprite: poison_status,
        icon_subimg: 0,
        stat_mods: { atk:0, def:0, spd:0, mag:-1 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        dot_kind: "poison",   // deals its stacks each turn, then loses one; reapply adds stacks
        max_stacks: 10
    };

    global.status_db[? STATUS_BLEED] = {
        id: STATUS_BLEED,
        name: "Bleeding",
        icon_sprite: bleed_status,
        icon_subimg: 0,
        stat_mods: { atk:0, def:0, spd:-2, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        dot_kind: "bleed",    // hurts only when the bleeder acts; reapply adds a stack and refreshes the turns
        max_stacks: 3,
        duration: 3,
        damage_per_stack: 2
    };

    global.status_db[? STATUS_BURN] = {
        id: STATUS_BURN,
        name: "Burning",
        icon_sprite: burn_status,
        icon_subimg: 0,
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        stat_mult: { atk:1, def:0.75, spd:1, mag:1 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        dot_kind: "burn",     // a fixed tick (power) for `duration` turns; reapply refreshes, never stacks
        max_stacks: 1,
        duration: 2,
        tick_per_mag: 0.3,
        tick_min: 2
    };

    global.status_db[? STATUS_STUN] = {
        id: STATUS_STUN,
        name: "Stun",
        icon_sprite: stun_status,
        icon_subimg: 0,
        stat_mods: { atk:0, def:0, spd:-2, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false
    };

    global.status_db[? STATUS_GUARD] = {
        id: STATUS_GUARD,
        name: "Guard",
        icon_sprite: rock1,
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        guard_mult: 0,
        consume_on_hit: true
    };

    global.status_db[? STATUS_DMG_UP] = {
        id: STATUS_DMG_UP,
        name: "Rev Up",
        icon_sprite: torch_asset_moving,
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        dmg_mult: 2,
        consume_on_attack: true
    };

    global.status_db[? STATUS_EVASION] = {
        id: STATUS_EVASION,
        name: "Evasion",
        // D80: the next damaging enemy action against the PLAYER is fully dodged (Combat_TryDodge); no effect on an enemy.
        icon_sprite: tall_grass_asset,
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        force_dodge: true,
        consume_on_defend: true
    };

    global.status_db[? STATUS_CRIT_UP] = {
        id: STATUS_CRIT_UP,
        name: "Take Aim",
        icon_sprite: skull_2_asset,
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        crit_bonus: 25
    };

    global.status_db[? STATUS_HIT_UP] = {
        id: STATUS_HIT_UP,
        name: "Foresight",
        // D79: for `duration` of the player's turns the enemy's next action is revealed and every Perfect zone of his QTEs is x1.5 wider.
        icon_sprite: Status_ResolveIcon("foresight_effect_Sheet", Status_ResolveIcon("take_aim_effect", skull_2_asset)),
        icon_subimg: 0,
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        duration: 3,
        no_tick_on_apply: true,   // the cast itself is not one of the 3 turns
        reveals_action: true,
        perfect_widen: 1.5
    };

    global.status_db[? STATUS_MEDITATION] = {
        id: STATUS_MEDITATION,
        name: "Meditation",
        icon_sprite: mp_potion,
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:2, mp_max:4 },
        stackable: false
    };

    global.status_db[? STATUS_SOLIDIFY] = {
        id: STATUS_SOLIDIFY,
        name: "Solidify",
        // D80: the Slime takes 75% less from the next hit (a guard_mult, consumed by that hit).
        icon_sprite: Status_ResolveIcon("stun_status", rock1),
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        guard_mult: 0.25,
        consume_on_hit: true
    };

    global.status_db[? STATUS_BLOODTHIRSTY] = {
        id: STATUS_BLOODTHIRSTY,
        name: "Bloodthirsty",
        icon_sprite: Status_ResolveIcon("bleed_status", torch_asset_moving),
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        guard_mult: 0.65,
        dmg_mult: 1.06,
        consume_on_hit: true
    };

    global.status_db[? STATUS_BLESSING] = {
        id: STATUS_BLESSING,
        name: "Blessing",
        icon_sprite: Status_ResolveIcon("burn_status", mp_potion),
        stat_mods: { atk:0, def:0, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        guard_mult: 0.8,
        consume_on_hit: true
    };

    global.status_db[? STATUS_SUNDER] = {
        id: STATUS_SUNDER,
        name: "Sundered",
        icon_sprite: noone,
        stat_mods: { atk:0, def:-1, spd:0, mag:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false
    };

    Status_AssignCoreIcons();
    Status_AssignPlayerBuffIconsFromFX();
    Status_AssignMissingIconsFromSkillFX();
    if (variable_global_exists("state") && is_struct(global.state)) {
        global.state.status_db = global.status_db;
    }
}

function StatusDB_Get(_status_id) {
    if (!variable_global_exists("status_db") || !ds_exists(global.status_db, ds_type_map)) {
        StatusDB_Init();
    }
    if (ds_map_exists(global.status_db, _status_id)) {
        return Status_LocalizeRuntime(global.status_db[? _status_id], _status_id);
    }
    return { id: -1, name: Loc_T("status.name.unknown", "Unknown"), icon_sprite: noone, stat_mods: { atk:0, def:0, spd:0, mag:0 }, tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 }, stackable: false };
}

function Status_LocalizationKey(_status_id) {
    switch (_status_id) {
        case STATUS_POISON: return "status_poison";
        case STATUS_BLEED: return "status_bleed";
        case STATUS_BURN: return "status_burn";
        case STATUS_STUN: return "status_stun";
        case STATUS_GUARD: return "status_guard";
        case STATUS_DMG_UP: return "status_dmg_up";
        case STATUS_EVASION: return "status_evasion";
        case STATUS_CRIT_UP: return "status_crit_up";
        case STATUS_HIT_UP: return "status_hit_up";
        case STATUS_MEDITATION: return "status_meditation";
        case STATUS_SOLIDIFY: return "status_solidify";
        case STATUS_BLOODTHIRSTY: return "status_bloodthirsty";
        case STATUS_BLESSING: return "status_blessing";
        case STATUS_SUNDER: return "status_sunder";
    }
    return "unknown";
}

function Status_LocalizeRuntime(_status, _status_id = -1) {
    if (!is_struct(_status)) return _status;

    var sid = _status_id;
    if (sid == -1 && variable_struct_exists(_status, "id")) sid = _status.id;
    var key_suffix = Status_LocalizationKey(sid);

    if (!variable_struct_exists(_status, "name_en")) _status.name_en = string(_status.name);
    _status.name = Loc_T("status.name." + key_suffix, string(_status.name_en));
    return _status;
}

// ---- D78 / D100: pure helpers for the damage-over-time numbers (combat-spec.md section 10; vectors in combat-vectors.json) ----
function Status_Cfg(_status_id, _field, _default) {
    var cfg = StatusDB_Get(_status_id);
    if (is_struct(cfg) && variable_struct_exists(cfg, _field)) return variable_struct_get(cfg, _field);
    return _default;
}

// Burning: HP per tick = max(2, round_half_up(0.3 * the caster's MAG)), fixed when it is applied.
function Status_BurnTick(_mag) {
    return max(Status_Cfg(STATUS_BURN, "tick_min", 2), RoundHalfUp(Status_Cfg(STATUS_BURN, "tick_per_mag", 0.3) * _mag));
}

// Effective DEF of a burning character: DEF x 0.75, round half up, at least 1.
function Status_BurnDef(_def) {
    var m = Status_Cfg(STATUS_BURN, "stat_mult", { def: 0.75 });
    return max(1, RoundHalfUp(_def * m.def));
}

// HP lost by a Poison of _n stacks left alone: n + (n-1) + ... + 1.
function Status_PoisonTotal(_n) {
    var n = clamp(round(_n), 1, Status_Cfg(STATUS_POISON, "max_stacks", 10));
    return (n * (n + 1)) div 2;
}

function Status_PoisonAdd(_existing, _added) {
    return min(Status_Cfg(STATUS_POISON, "max_stacks", 10), max(0, _existing) + max(0, _added));
}

// Bleeding: HP per action of the bleeder = 2 per stack.
function Status_BleedTick(_stacks) {
    return Status_Cfg(STATUS_BLEED, "damage_per_stack", 2) * clamp(round(_stacks), 1, Status_Cfg(STATUS_BLEED, "max_stacks", 3));
}

// The status entry of a character (the struct in ch.status), or undefined.
function Status_Find(_ch, _status_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "status") || !is_array(_ch.status)) return undefined;
    for (var i = 0; i < array_length(_ch.status); i++) {
        if (_ch.status[i].id == _status_id) return _ch.status[i];
    }
    return undefined;
}

function Status_Stacks(_ch, _status_id) {
    var s = Status_Find(_ch, _status_id);
    if (!is_struct(s)) return 0;
    return variable_struct_exists(s, "stacks") ? s.stacks : 1;
}

// HP a DoT entry takes on its owner's tick. _acted: the owner acted this turn (a stunned owner does not bleed).
function Status_DotDamage(_entry, _cfg, _acted = true) {
    if (!is_struct(_cfg) || !variable_struct_exists(_cfg, "dot_kind")) return 0;
    var stacks = variable_struct_exists(_entry, "stacks") ? _entry.stacks : 1;
    switch (_cfg.dot_kind) {
        case "poison": return stacks;
        case "burn":   return max(0, _entry.power);
        case "bleed":  return _acted ? Status_BleedTick(stacks) : 0;
    }
    return 0;
}

// ---- D100: the plain sentence and the exact numbers of a status, from the real game data. _data = the entry in ch.status (turns, stacks, power), or
// undefined for the status in general. No number is typed into the text: they come from the entry or from StatusDB. ----
function Status_ModsText(_cfg) {
    var out = "";
    if (!is_struct(_cfg)) return out;
    var ids = [STAT_ATK, STAT_DEF, STAT_SPD, STAT_MAG];
    if (variable_struct_exists(_cfg, "stat_mods")) {
        for (var i = 0; i < 4; i++) {
            var v = variable_struct_get(_cfg.stat_mods, Stat_Key(ids[i]));
            if (v != 0) out += " " + Stat_ShortName(ids[i]) + " " + ((v > 0) ? "+" : "") + string(v) + ".";
        }
    }
    if (variable_struct_exists(_cfg, "stat_mult")) {
        for (var j = 0; j < 4; j++) {
            var m = variable_struct_get(_cfg.stat_mult, Stat_Key(ids[j]));
            if (m != 1) out += " " + Stat_ShortName(ids[j]) + " " + ((m > 1) ? "+" : "") + string(round((m - 1) * 100)) + "%.";
        }
    }
    return out;
}

function Status_Describe(_status_id, _data = undefined) {
    var cfg = StatusDB_Get(_status_id);
    var has = is_struct(_data);
    var dur = Status_Cfg(_status_id, "duration", 0);
    var turns = (has && variable_struct_exists(_data, "turns")) ? _data.turns : dur;
    var stacks = (has && variable_struct_exists(_data, "stacks")) ? _data.stacks : 1;
    var entry_power = (has && variable_struct_exists(_data, "power")) ? _data.power : 0;
    var max_stacks = Status_Cfg(_status_id, "max_stacks", 1);
    var vars = { turns: turns, stacks: stacks, max: max_stacks, tick: 0, dur: dur, mods: Status_ModsText(cfg) };
    var line = "";
    var tick = 0;

    switch (_status_id) {
        case STATUS_POISON:
            if (has) {
                tick = Status_DotDamage(_data, cfg);
                vars.tick = tick;
                line = Loc_T("status.desc.poison.data", "Lose {tick} HP each turn, then 1 stack fades ({stacks} stacks, max {max}).{mods}", vars);
            } else {
                line = Loc_T("status.desc.poison", "Lose HP equal to its stacks each turn, then 1 stack fades. Stacks up to {max}.{mods}", vars);
            }
            break;
        case STATUS_BLEED:
            if (has) {
                tick = Status_DotDamage(_data, cfg, true);
                vars.tick = tick;
                line = Loc_T("status.desc.bleed.data", "Lose {tick} HP each time you act ({stacks} stacks, max {max}), for {turns} more turns.{mods}", vars);
            } else {
                vars.tick = Status_BleedTick(1);
                line = Loc_T("status.desc.bleed", "Lose {tick} HP per stack each time you act. Stacks up to {max}, lasts {dur} turns.{mods}", vars);
            }
            break;
        case STATUS_BURN:
            if (has) {
                tick = Status_DotDamage(_data, cfg);
                vars.tick = tick;
                line = Loc_T("status.desc.burn.data", "Lose {tick} HP each turn for {turns} more turns.{mods}", vars);
            } else {
                line = Loc_T("status.desc.burn", "Lose a fixed amount of HP (it grows with the caster's MAG) each turn for {dur} turns. Does not stack.{mods}", vars);
            }
            break;
        case STATUS_STUN:
            line = Loc_T("status.desc.status_stun", "Pushed back on the turn bar. Then Steadfast: cannot be stunned for 2 turns.");
            break;
        case STATUS_GUARD:
            line = Loc_T("status.desc.status_guard", "Blocks the next incoming hit.");
            break;
        case STATUS_DMG_UP:
            vars.mult = Status_Cfg(_status_id, "dmg_mult", 1);
            line = Loc_T("status.desc.status_dmg_up", "Next attack deals {mult} times the damage.", vars);
            break;
        case STATUS_EVASION:
            line = Loc_T("status.desc.status_evasion", "Dodges the next incoming attack.");
            break;
        case STATUS_CRIT_UP:
            vars.pct = Status_Cfg(_status_id, "crit_bonus", 0);
            line = Loc_T("status.desc.status_crit_up", "Critical chance +{pct}%.", vars);
            break;
        case STATUS_HIT_UP:
            vars.pct = round((Status_Cfg(_status_id, "perfect_widen", 1) - 1) * 100);
            line = Loc_T("status.desc.status_hit_up", "For {turns} turns: you see the enemy's next move and every Perfect zone is {pct}% wider.", vars);
            break;
        case STATUS_MEDITATION:
            var mt = Status_Cfg(_status_id, "tick", { mp_min: 0, mp_max: 0 });
            vars.lo = mt.mp_min;
            vars.hi = mt.mp_max;
            line = Loc_T("status.desc.status_meditation", "Recover {lo}-{hi} MP each turn.", vars);
            break;
        case STATUS_SOLIDIFY:
            vars.pct = round((1 - Status_Cfg(_status_id, "guard_mult", 1)) * 100);
            line = Loc_T("status.desc.status_solidify", "Takes {pct}% less damage from the next hit.", vars);
            break;
        case STATUS_BLOODTHIRSTY:
            vars.take = round((1 - Status_Cfg(_status_id, "guard_mult", 1)) * 100);
            vars.deal = round((Status_Cfg(_status_id, "dmg_mult", 1) - 1) * 100);
            line = Loc_T("status.desc.status_bloodthirsty", "Until hit: take {take}% less, deal {deal}% more damage.", vars);
            break;
        case STATUS_BLESSING:
            vars.pct = round((1 - Status_Cfg(_status_id, "guard_mult", 1)) * 100);
            line = Loc_T("status.desc.status_blessing", "Next incoming hit deals {pct}% less damage.", vars);
            break;
        case STATUS_SUNDER:
            line = Loc_T("status.desc.status_sunder", "Lose defence.{mods}", vars);
            break;
    }

    var shown_turns = turns;
    if (_status_id == STATUS_POISON) shown_turns = has ? stacks : 0;   // a poison lasts as many turns as it has stacks
    return {
        id: _status_id,
        name: (is_struct(cfg) && variable_struct_exists(cfg, "name")) ? string(cfg.name) : "",
        line: line,
        turns: shown_turns,
        stacks: has ? stacks : 0,
        max_stacks: max_stacks,
        tick: tick,
        power: entry_power,
        has_data: has
    };
}

// The line the existing tooltips use (Tooltip_StatusEffectLine): the status in general, numbers from the data.
function Status_Description(_status_id) {
    return Status_Describe(_status_id).line;
}

// HUD data (no drawing; the UI packet draws it): one row per status on a character. label: "x2" stacks and/or "3t" turns left.
function Status_DisplayList(_ch) {
    var out = [];
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "status") || !is_array(_ch.status)) return out;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var s = _ch.status[i];
        var cfg = StatusDB_Get(s.id);
        var d = Status_Describe(s.id, s);
        var label = "";
        if (d.max_stacks > 1) label += "x" + string(d.stacks);
        if (!(variable_struct_exists(cfg, "dot_kind") && cfg.dot_kind == "poison")) label += ((label != "") ? " " : "") + string(max(0, s.turns)) + "t";
        array_push(out, {
            id: s.id,
            name: d.name,
            turns: d.turns,
            stacks: d.stacks,
            tick: d.tick,
            label: label,
            line: d.line,
            negative: Status_IsNegative(s.id),
            icon_sprite: variable_struct_exists(cfg, "icon_sprite") ? cfg.icon_sprite : noone,
            icon_subimg: variable_struct_exists(cfg, "icon_subimg") ? cfg.icon_subimg : 0
        });
    }
    return out;
}

function Status_Has(_ch, _status_id) {
    if (!is_array(_ch.status)) return false;
    for (var i = 0; i < array_length(_ch.status); i++) {
        if (_ch.status[i].id == _status_id) return true;
    }
    return false;
}

function Status_Remove(_ch, _status_id) {
    if (!is_array(_ch.status)) return _ch;
    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        if (_ch.status[i].id == _status_id) array_delete(_ch.status, i, 1);
    }
    return _ch;
}

function Status_RemoveList(_ch, _list) {
    if (!is_array(_ch.status)) return _ch;
    if (!is_array(_list)) return _ch;
    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var sid = _ch.status[i].id;
        for (var j = 0; j < array_length(_list); j++) {
            if (sid == _list[j]) {
                array_delete(_ch.status, i, 1);
                break;
            }
        }
    }
    return _ch;
}

function Status_ClearAll(_ch) {
    _ch.status = [];
    return _ch;
}

// _stacks: the stack count a Poison or Bleeding hit adds (default 1); ignored by the other statuses. A Poison has no turn limit: its `turns`
// mirror its stacks (ticks left), whatever _turns says. Burning and Bleeding use _turns; _power is Burning's HP per tick.
function Status_Add(_ch, _status_id, _turns, _power, _stacks = 1) {
    if (!is_array(_ch.status)) _ch.status = [];
    var cfg = StatusDB_Get(_status_id);

    // Stun is only a marker (D75): the battle turns it into a push-back on the turn timeline at once (Battle_ConsumeStun); Steadfast lives there too.

    var dot = variable_struct_exists(cfg, "dot_kind") ? cfg.dot_kind : "";
    var max_stacks = variable_struct_exists(cfg, "max_stacks") ? cfg.max_stacks : 1;
    var add_stacks = max(1, round(_stacks));
    var fresh = variable_struct_exists(cfg, "no_tick_on_apply") && cfg.no_tick_on_apply;

    var cur = Status_Find(_ch, _status_id);
    if (is_struct(cur)) {
        if (!variable_struct_exists(cur, "stacks")) cur.stacks = 1;
        switch (dot) {
            case "poison":   // reapply adds stacks
                cur.stacks = Status_PoisonAdd(cur.stacks, add_stacks);
                cur.turns = cur.stacks;
                break;
            case "bleed":    // reapply adds a stack and refreshes the turns
                cur.stacks = min(max_stacks, cur.stacks + add_stacks);
                cur.turns = max(cur.turns, _turns);
                break;
            case "burn":     // reapply refreshes: never stacks, the newer tick wins
                cur.turns = max(cur.turns, _turns);
                cur.power = _power;
                break;
            default:
                cur.turns = max(cur.turns, _turns);
                cur.power = max(cur.power, _power);
        }
        if (fresh) cur.fresh = true;
        return _ch;
    }

    var entry = { id: _status_id, turns: _turns, power: _power, stacks: 1 };
    if (dot == "poison") {
        entry.stacks = min(max_stacks, add_stacks);
        entry.turns = entry.stacks;
    } else if (dot == "bleed") {
        entry.stacks = min(max_stacks, add_stacks);
    }
    if (fresh) entry.fresh = true;
    array_push(_ch.status, entry);
    return _ch;
}

function Status_ModStat(_ch, _stat_id) {
    var total = 0;
    if (!is_array(_ch.status)) return 0;

    for (var i = 0; i < array_length(_ch.status); i++) {
        var s = _ch.status[i];
        var cfg = StatusDB_Get(s.id);
        var mods = cfg.stat_mods;
        switch (_stat_id) {
            case STAT_ATK: total += mods.atk; break;
            case STAT_DEF: total += mods.def; break;
            case STAT_SPD: total += mods.spd; break;
            case STAT_MAG: total += mods.mag; break;
        }
    }

    return total;
}

// Multiplicative stat changes (Burning: DEF x0.75). 1 when there are none.
function Status_StatMult(_ch, _stat_id) {
    var mult = 1;
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "status") || !is_array(_ch.status)) return 1;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (!variable_struct_exists(cfg, "stat_mult")) continue;
        var sm = cfg.stat_mult;
        switch (_stat_id) {
            case STAT_ATK: mult *= sm.atk; break;
            case STAT_DEF: mult *= sm.def; break;
            case STAT_SPD: mult *= sm.spd; break;
            case STAT_MAG: mult *= sm.mag; break;
        }
    }
    return mult;
}

function Status_GetSum(_ch, _field) {
    var total = 0;
    if (!is_array(_ch.status)) return 0;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field)) {
            total += variable_struct_get(cfg, _field);
        }
    }
    return total;
}

function Status_GetMul(_ch, _field) {
    var mult = 1;
    if (!is_array(_ch.status)) return 1;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field)) {
            mult *= variable_struct_get(cfg, _field);
        }
    }
    return mult;
}

function Status_HasFlag(_ch, _field) {
    if (!is_array(_ch.status)) return false;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field) && variable_struct_get(cfg, _field)) return true;
    }
    return false;
}

function Status_ConsumeByField(_ch, _field) {
    if (!is_array(_ch.status)) return _ch;
    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var cfg = StatusDB_Get(_ch.status[i].id);
        if (variable_struct_exists(cfg, _field) && variable_struct_get(cfg, _field)) {
            array_delete(_ch.status, i, 1);
        }
    }
    return _ch;
}

// BUG-08: what the player sees and hears when a damage-over-time status ticks on them. Pure: no instances, no sound.
function Status_TickFeedbackInfo(_status_id, _hp_lost) {
    var cfg = StatusDB_Get(_status_id);
    var status_name = (is_struct(cfg) && variable_struct_exists(cfg, "name")) ? string(cfg.name) : "Status";
    return {
        line: Loc_T("combat.msg.status_tick", "{status} hurts you for {dmg}.", { status: status_name, dmg: _hp_lost }),
        sfx: "skill_bleed",   // existing bleed sound; no new assets
        flash_frames: UI_HUD_HURT_FLASH_FRAMES * 2
    };
}

// Applies it in a battle: log line, sound, longer HUD bar flash. Always records the last event in global.status_tick_last (tests read it).
function Status_TickFeedback(_status_id, _hp_lost) {
    var info = Status_TickFeedbackInfo(_status_id, _hp_lost);
    global.status_tick_last = info;
    if (room != rm_battle || !instance_exists(obj_battle_controller)) return info;
    Combat_Log(info.line);
    SFX_Play(info.sfx);
    if (instance_exists(obj_ui_controller)) {
        with (obj_ui_controller) hud_hurt_flash_timer = max(hud_hurt_flash_timer, info.flash_frames);
    }
    return info;
}

// Enemy side of the tick feedback: a log line in the battle (the player's version also plays a sound and flashes the HUD).
function Status_TickFeedbackEnemy(_status_id, _hp_lost, _enemy_name) {
    var cfg = StatusDB_Get(_status_id);
    var status_name = (is_struct(cfg) && variable_struct_exists(cfg, "name")) ? string(cfg.name) : "Status";
    var info = { line: Loc_T("combat.msg.status_tick_enemy", "{status} hurts {enemy} for {dmg}.", { status: status_name, enemy: _enemy_name, dmg: _hp_lost }) };
    global.status_tick_last_enemy = info;
    if (room == rm_battle && instance_exists(obj_battle_controller)) Combat_Log(info.line);
    return info;
}

// HP lost by one status entry on _ch (its DoT table or its legacy hp tick); clamps HP and reports it to the player/enemy feedback.
function Status_ApplyHpTick(_ch, _entry, _cfg, _acted) {
    var delta_hp = 0;
    if (variable_struct_exists(_cfg, "dot_kind")) {
        delta_hp = -Status_DotDamage(_entry, _cfg, _acted);
    } else if (is_struct(_cfg.tick)) {
        var hp_min = variable_struct_exists(_cfg.tick, "hp_min") ? _cfg.tick.hp_min : 0;
        var hp_max = variable_struct_exists(_cfg.tick, "hp_max") ? _cfg.tick.hp_max : 0;
        var hp_low = min(hp_min, hp_max);
        var hp_high = max(hp_min, hp_max);
        if (hp_low != 0 || hp_high != 0) delta_hp = (hp_low == hp_high) ? hp_low : irandom_range(hp_low, hp_high);
    }
    if (delta_hp == 0) return _ch;
    var hp_before = _ch.hp;
    _ch.hp = clamp(_ch.hp + delta_hp, 0, _ch.max_hp);
    if (_ch.hp < hp_before) {
        if (variable_struct_exists(_ch, "is_player") && _ch.is_player) {
            Status_TickFeedback(_entry.id, hp_before - _ch.hp);
            if (_ch.hp <= 0) Death_NoteDotKill(_entry.id);   // C5 (D103): the death line can say what finished you
        }
        else Status_TickFeedbackEnemy(_entry.id, hp_before - _ch.hp, variable_struct_exists(_ch, "name") ? string(_ch.name) : "");
    }
    return _ch;
}

// The per-ACTION part of a tick (D78): Bleeding hurts each time its owner acts. Used between the actions of an enemy turn that has several;
// Status_Tick already includes it for the last (or only) action.
function Status_ActionTick(_ch) {
    if (!is_array(_ch.status)) return _ch;
    for (var i = 0; i < array_length(_ch.status); i++) {
        var s = _ch.status[i];
        var cfg = StatusDB_Get(s.id);
        if (variable_struct_exists(cfg, "dot_kind") && cfg.dot_kind == "bleed") _ch = Status_ApplyHpTick(_ch, s, cfg, true);
    }
    return _ch;
}

// Once per TURN of the owner. _acted = the owner took an action this turn (false for a stunned turn: a bleeder does not bleed then).
// Poison: HP -= stacks, then stacks -= 1. Burning: HP -= power, turns -= 1. Bleeding: HP -= 2 x stacks if it acted, turns -= 1. A status applied this
// turn with `no_tick_on_apply` (Foresight) skips its first decay.
function Status_Tick(_ch, _acted = true) {
    if (!is_array(_ch.status)) return _ch;

    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var s = _ch.status[i];
        if (variable_struct_exists(s, "fresh") && s.fresh) {
            s.fresh = false;
            continue;
        }
        var cfg = StatusDB_Get(s.id);

        _ch = Status_ApplyHpTick(_ch, s, cfg, _acted);

        var t = cfg.tick;
        var mp_min = 0;
        var mp_max = 0;
        if (is_struct(t)) {
            if (variable_struct_exists(t, "mp_min")) mp_min = t.mp_min;
            if (variable_struct_exists(t, "mp_max")) mp_max = t.mp_max;
        }
        var mp_low = min(mp_min, mp_max);
        var mp_high = max(mp_min, mp_max);
        if (mp_low != 0 || mp_high != 0) {
            var delta_mp = (mp_low == mp_high) ? mp_low : irandom_range(mp_low, mp_high);
            _ch.mp = clamp(_ch.mp + delta_mp, 0, _ch.max_mp);
        }

        if (variable_struct_exists(cfg, "dot_kind") && cfg.dot_kind == "poison") {
            s.stacks = (variable_struct_exists(s, "stacks") ? s.stacks : 1) - 1;
            s.turns = s.stacks;
            if (s.stacks <= 0) array_delete(_ch.status, i, 1);
        } else {
            s.turns -= 1;
            if (s.turns <= 0) array_delete(_ch.status, i, 1);
        }
    }

    return _ch;
}

function Status_CanAct(_ch) {
    if (Status_HasFlag(_ch, "skip_turn")) return false;
    return true;
}

function Status_UsesCoreIconSprite(_status_id, _icon_sprite) {
    if (_icon_sprite == noone || _icon_sprite == -1) return false;
    switch (_status_id) {
        case STATUS_POISON: return (_icon_sprite == poison_status);
        case STATUS_BLEED:  return (_icon_sprite == bleed_status);
        case STATUS_BURN:   return (_icon_sprite == burn_status);
        case STATUS_STUN:   return (_icon_sprite == stun_status);
    }
    return false;
}

function Status_IsNegative(_status_id) {
    switch (_status_id) {
        case STATUS_POISON:
        case STATUS_BLEED:
        case STATUS_BURN:
        case STATUS_STUN:
        case STATUS_SUNDER:
            return true;
    }
    return false;
}

function Status_LabelWithSign(_cfg, _status_id) {
    var name_txt = Loc_T("status.name.default", "Status");
    if (is_struct(_cfg) && variable_struct_exists(_cfg, "name")) {
        name_txt = string(_cfg.name);
    }
    var suffix = Status_IsNegative(_status_id) ? "-" : "+";
    return name_txt + suffix;
}

function Status_DrawFallbackLabel(_cfg, _status_id, _x, _y) {
    var txt = Status_LabelWithSign(_cfg, _status_id);
    var text_scale = UI_STATUS_FALLBACK_TEXT_SCALE;

    draw_set_color(c_black);
    UI_DrawTextTransformed(_x + 1, _y + 1, txt, text_scale, text_scale, 0);
    draw_set_color(c_white);
    UI_DrawTextTransformed(_x, _y, txt, text_scale, text_scale, 0);

    return max(1, round(UI_TextWidth(txt) * text_scale));
}

function Status_DrawIcons(_ch, _x, _y, _spacing = 10, _rtl = false, _noncore_text_fallback = false) {
    if (!is_array(_ch.status)) return;

    var spacing = 10;
    if (argument_count >= 4) spacing = _spacing;
    var rtl = false;
    if (argument_count >= 5) rtl = _rtl;
    var noncore_text_fallback = false;
    if (argument_count >= 6) noncore_text_fallback = _noncore_text_fallback;
    var icon_scale = UI_GetSpriteScale();
    var spacing_px = max(1, round(real(spacing) * icon_scale));
    var icon_gap = max(2, round(4 * icon_scale));

    var off = 0;
    if (rtl) {
        for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
            var cfg = StatusDB_Get(_ch.status[i].id);
            var sid = _ch.status[i].id;
            var has_sprite = (variable_struct_exists(cfg, "icon_sprite") && cfg.icon_sprite != noone);
            var use_text_fallback = (!has_sprite) || (noncore_text_fallback && !Status_UsesCoreIconSprite(sid, cfg.icon_sprite));
            if (use_text_fallback) {
                var tag_w = Status_DrawFallbackLabel(cfg, sid, _x + off, _y);
                off += max(spacing_px, tag_w + icon_gap);
            } else if (has_sprite) {
                var icon_sub = 0;
                if (variable_struct_exists(cfg, "icon_subimg")) icon_sub = round(cfg.icon_subimg);
                var icon_max = max(0, sprite_get_number(cfg.icon_sprite) - 1);
                icon_sub = clamp(icon_sub, 0, icon_max);
                draw_sprite_ext(cfg.icon_sprite, icon_sub, _x + off, _y, icon_scale, icon_scale, 0, c_white, 1);
                var icon_w = round(sprite_get_width(cfg.icon_sprite) * icon_scale);
                off += max(spacing_px, icon_w + icon_gap);
            }
        }
    } else {
        for (var i = 0; i < array_length(_ch.status); i++) {
            var cfg2 = StatusDB_Get(_ch.status[i].id);
            var sid2 = _ch.status[i].id;
            var has_sprite2 = (variable_struct_exists(cfg2, "icon_sprite") && cfg2.icon_sprite != noone);
            var use_text_fallback2 = (!has_sprite2) || (noncore_text_fallback && !Status_UsesCoreIconSprite(sid2, cfg2.icon_sprite));
            if (use_text_fallback2) {
                var tag_w2 = Status_DrawFallbackLabel(cfg2, sid2, _x + off, _y);
                off += max(spacing_px, tag_w2 + icon_gap);
            } else if (has_sprite2) {
                var icon_sub2 = 0;
                if (variable_struct_exists(cfg2, "icon_subimg")) icon_sub2 = round(cfg2.icon_subimg);
                var icon_max2 = max(0, sprite_get_number(cfg2.icon_sprite) - 1);
                icon_sub2 = clamp(icon_sub2, 0, icon_max2);
                draw_sprite_ext(cfg2.icon_sprite, icon_sub2, _x + off, _y, icon_scale, icon_scale, 0, c_white, 1);
                var icon_w2 = round(sprite_get_width(cfg2.icon_sprite) * icon_scale);
                off += max(spacing_px, icon_w2 + icon_gap);
            }
        }
    }
}
