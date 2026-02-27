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
    var sp_hit_up = Status_ResolveIcon("foresight_effect_Sheet", horned_skull_asset);
    var sp_meditation = Status_ResolveIcon("meditation", mp_potion);

    Status_SetIcon(STATUS_GUARD, sp_guard, Status_LastFrame(sp_guard));
    Status_SetIcon(STATUS_DMG_UP, sp_dmg_up, Status_LastFrame(sp_dmg_up));
    Status_SetIcon(STATUS_EVASION, sp_evasion, Status_LastFrame(sp_evasion));
    Status_SetIcon(STATUS_CRIT_UP, sp_crit_up, Status_LastFrame(sp_crit_up));
    Status_SetIcon(STATUS_HIT_UP, sp_hit_up, Status_LastFrame(sp_hit_up));
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

    global.status_db[? STATUS_POISON] = {
        id: STATUS_POISON,
        name: "Poison",
        icon_sprite: poison_status,
        icon_subimg: 0,
        stat_mods: { str:0, agi:0, def:0, intt:-1, luck:0 },
        tick: { hp_min:-3, hp_max:-2, mp_min:0, mp_max:0 },
        stackable: false,
        excludes: [STATUS_BLEED, STATUS_BURN]
    };

    global.status_db[? STATUS_BLEED] = {
        id: STATUS_BLEED,
        name: "Bleeding",
        icon_sprite: bleed_status,
        icon_subimg: 0,
        stat_mods: { str:0, agi:-2, def:0, intt:0, luck:0 },
        tick: { hp_min:-4, hp_max:-2, mp_min:0, mp_max:0 },
        stackable: false,
        excludes: [STATUS_POISON, STATUS_BURN]
    };

    global.status_db[? STATUS_BURN] = {
        id: STATUS_BURN,
        name: "Burning",
        icon_sprite: burn_status,
        icon_subimg: 0,
        stat_mods: { str:-1, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:-6, hp_max:-4, mp_min:0, mp_max:0 },
        stackable: false,
        excludes: [STATUS_BLEED, STATUS_POISON]
    };

    global.status_db[? STATUS_STUN] = {
        id: STATUS_STUN,
        name: "Stun",
        icon_sprite: stun_status,
        icon_subimg: 0,
        stat_mods: { str:0, agi:-2, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        skip_turn: true
    };

    global.status_db[? STATUS_GUARD] = {
        id: STATUS_GUARD,
        name: "Guard",
        icon_sprite: rock1,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        guard_mult: 0,
        consume_on_hit: true
    };

    global.status_db[? STATUS_DMG_UP] = {
        id: STATUS_DMG_UP,
        name: "Rev Up",
        icon_sprite: torch_asset_moving,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        dmg_mult: 2,
        consume_on_attack: true
    };

    global.status_db[? STATUS_EVASION] = {
        id: STATUS_EVASION,
        name: "Evasion",
        icon_sprite: tall_grass_asset,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        force_dodge: true,
        consume_on_defend: true
    };

    global.status_db[? STATUS_CRIT_UP] = {
        id: STATUS_CRIT_UP,
        name: "Take Aim",
        icon_sprite: skull_2_asset,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        crit_bonus: 25
    };

    global.status_db[? STATUS_HIT_UP] = {
        id: STATUS_HIT_UP,
        name: "Foresight",
        icon_sprite: horned_skull_asset,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        always_hit: true,
        consume_on_attack: true
    };

    global.status_db[? STATUS_MEDITATION] = {
        id: STATUS_MEDITATION,
        name: "Meditation",
        icon_sprite: mp_potion,
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:2, mp_max:4 },
        stackable: false
    };

    global.status_db[? STATUS_SOLIDIFY] = {
        id: STATUS_SOLIDIFY,
        name: "Solidify",
        icon_sprite: Status_ResolveIcon("stun_status", rock1),
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        force_dodge: true,
        consume_on_defend: true
    };

    global.status_db[? STATUS_BLOODTHIRSTY] = {
        id: STATUS_BLOODTHIRSTY,
        name: "Bloodthirsty",
        icon_sprite: Status_ResolveIcon("bleed_status", torch_asset_moving),
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
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
        stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 },
        tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 },
        stackable: false,
        guard_mult: 0.8,
        consume_on_hit: true
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
        return global.status_db[? _status_id];
    }
    return { id: -1, name: "Unknown", icon_sprite: noone, stat_mods: { str:0, agi:0, def:0, intt:0, luck:0 }, tick: { hp_min:0, hp_max:0, mp_min:0, mp_max:0 }, stackable: false };
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

function Status_Add(_ch, _status_id, _turns, _power) {
    if (!is_array(_ch.status)) _ch.status = [];
    var cfg = StatusDB_Get(_status_id);

    if (variable_struct_exists(cfg, "excludes")) {
        _ch = Status_RemoveList(_ch, cfg.excludes);
    }

    if (!cfg.stackable && Status_Has(_ch, _status_id)) {
        for (var i = 0; i < array_length(_ch.status); i++) {
            if (_ch.status[i].id == _status_id) {
                _ch.status[i].turns = max(_ch.status[i].turns, _turns);
                _ch.status[i].power = max(_ch.status[i].power, _power);
                return _ch;
            }
        }
    }

    array_push(_ch.status, { id: _status_id, turns: _turns, power: _power });
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
            case STAT_STR:  total += mods.str; break;
            case STAT_AGI:  total += mods.agi; break;
            case STAT_DEF:  total += mods.def; break;
            case STAT_INT:  total += mods.intt; break;
            case STAT_LUCK: total += mods.luck; break;
        }
    }

    return total;
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

function Status_Tick(_ch) {
    if (!is_array(_ch.status)) return _ch;

    for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
        var s = _ch.status[i];
        var cfg = StatusDB_Get(s.id);
        var t = cfg.tick;

        var hp_min = 0;
        var hp_max = 0;
        var mp_min = 0;
        var mp_max = 0;
        if (is_struct(t)) {
            if (variable_struct_exists(t, "hp_min")) hp_min = t.hp_min;
            if (variable_struct_exists(t, "hp_max")) hp_max = t.hp_max;
            if (variable_struct_exists(t, "mp_min")) mp_min = t.mp_min;
            if (variable_struct_exists(t, "mp_max")) mp_max = t.mp_max;
        }

        if (hp_min != 0 || hp_max != 0) {
            var delta_hp = (hp_min == hp_max) ? hp_min : irandom_range(hp_min, hp_max);
            _ch.hp = clamp(_ch.hp + delta_hp, 0, _ch.max_hp);
        }

        if (mp_min != 0 || mp_max != 0) {
            var delta_mp = (mp_min == mp_max) ? mp_min : irandom_range(mp_min, mp_max);
            _ch.mp = clamp(_ch.mp + delta_mp, 0, _ch.max_mp);
        }

        s.turns -= 1;
        if (s.turns <= 0) {
            array_delete(_ch.status, i, 1);
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
            return true;
    }
    return false;
}

function Status_LabelWithSign(_cfg, _status_id) {
    var name_txt = "Status";
    if (is_struct(_cfg) && variable_struct_exists(_cfg, "name")) {
        name_txt = string(_cfg.name);
    }
    var suffix = Status_IsNegative(_status_id) ? " -" : " +";
    return name_txt + suffix;
}

function Status_DrawFallbackLabel(_cfg, _status_id, _x, _y) {
    var txt = Status_LabelWithSign(_cfg, _status_id);
    var text_scale = UI_STATUS_FALLBACK_TEXT_SCALE;

    draw_set_color(c_black);
    draw_text_transformed(_x + 1, _y + 1, txt, text_scale, text_scale, 0);
    draw_set_color(c_white);
    draw_text_transformed(_x, _y, txt, text_scale, text_scale, 0);

    return max(1, round(string_width(txt) * text_scale));
}

function Status_DrawIcons(_ch, _x, _y, _spacing, _rtl, _noncore_text_fallback) {
    if (!is_array(_ch.status)) return;

    var spacing = 10;
    if (argument_count >= 4) spacing = _spacing;
    var rtl = false;
    if (argument_count >= 5) rtl = _rtl;
    var noncore_text_fallback = false;
    if (argument_count >= 6) noncore_text_fallback = _noncore_text_fallback;

    var off = 0;
    if (rtl) {
        for (var i = array_length(_ch.status) - 1; i >= 0; i--) {
            var cfg = StatusDB_Get(_ch.status[i].id);
            var sid = _ch.status[i].id;
            var has_sprite = (variable_struct_exists(cfg, "icon_sprite") && cfg.icon_sprite != noone);
            var use_text_fallback = noncore_text_fallback && (!has_sprite || !Status_UsesCoreIconSprite(sid, cfg.icon_sprite));
            if (use_text_fallback) {
                var tag_w = Status_DrawFallbackLabel(cfg, sid, _x + off, _y);
                off += max(spacing, tag_w + 4);
            } else if (has_sprite) {
                var icon_sub = 0;
                if (variable_struct_exists(cfg, "icon_subimg")) icon_sub = round(cfg.icon_subimg);
                var icon_max = max(0, sprite_get_number(cfg.icon_sprite) - 1);
                icon_sub = clamp(icon_sub, 0, icon_max);
                draw_sprite(cfg.icon_sprite, icon_sub, _x + off, _y);
                off += spacing;
            }
        }
    } else {
        for (var i = 0; i < array_length(_ch.status); i++) {
            var cfg2 = StatusDB_Get(_ch.status[i].id);
            var sid2 = _ch.status[i].id;
            var has_sprite2 = (variable_struct_exists(cfg2, "icon_sprite") && cfg2.icon_sprite != noone);
            var use_text_fallback2 = noncore_text_fallback && (!has_sprite2 || !Status_UsesCoreIconSprite(sid2, cfg2.icon_sprite));
            if (use_text_fallback2) {
                var tag_w2 = Status_DrawFallbackLabel(cfg2, sid2, _x + off, _y);
                off += max(spacing, tag_w2 + 4);
            } else if (has_sprite2) {
                var icon_sub2 = 0;
                if (variable_struct_exists(cfg2, "icon_subimg")) icon_sub2 = round(cfg2.icon_subimg);
                var icon_max2 = max(0, sprite_get_number(cfg2.icon_sprite) - 1);
                icon_sub2 = clamp(icon_sub2, 0, icon_max2);
                draw_sprite(cfg2.icon_sprite, icon_sub2, _x + off, _y);
                off += spacing;
            }
        }
    }
}
