function Equip_ClassName(_class_id) {
    var cfg = DB_PlayerClass(_class_id);
    if (is_struct(cfg) && variable_struct_exists(cfg, "name")) return string(cfg.name);
    return "Unknown";
}

function Equip_CanEquip(_ch, _item_or_id) {
    var item = _item_or_id;
    if (!is_struct(item)) item = ItemDB_Get(_item_or_id);

    var out = { ok: false, msg: "Can't equip that.", item: item };

    if (!is_struct(_ch)) return out;
    if (!is_struct(item) || item.id == 0) return out;
    if (item.type != ITEM_WEAPON && item.type != ITEM_ARMOR) return out;
    if (!variable_struct_exists(item, "equip_slot") || item.equip_slot == "") return out;
    if (!variable_struct_exists(_ch, "class_id")) return out;

    if (!variable_struct_exists(_ch, "inventory") || !is_array(_ch.inventory) || !Inv_Has(_ch.inventory, item.id, 1)) {
        out.msg = "Item not in inventory.";
        return out;
    }

    var slot = string(item.equip_slot);
    if (Equip_SlotGet(_ch, slot) == item.id) {
        out.msg = "Already equipped.";
        return out;
    }

    if (variable_struct_exists(item, "preferred_class") && item.preferred_class != -1) {
        if (_ch.class_id != item.preferred_class) {
            out.msg = Equip_ClassName(item.preferred_class) + " only.";
            return out;
        }
    }

    if (variable_struct_exists(item, "allowed_classes") && is_array(item.allowed_classes)) {
        var allowed = false;
        for (var i = 0; i < array_length(item.allowed_classes); i++) {
            if (item.allowed_classes[i] == _ch.class_id) {
                allowed = true;
                break;
            }
        }

        if (!allowed) {
            var class_text = "";
            for (var j = 0; j < array_length(item.allowed_classes); j++) {
                if (j > 0) class_text += "/";
                class_text += Equip_ClassName(item.allowed_classes[j]);
            }
            if (class_text == "") class_text = "That";
            out.msg = class_text + " only.";
            return out;
        }
    }

    out.ok = true;
    out.msg = "Equipped " + string(item.name) + ".";
    return out;
}

function Equip_Item(_ch, _item_id) {
    var can = Equip_CanEquip(_ch, _item_id);
    if (!can.ok) return false;

    var item = can.item;
    // One slot at a time: assigning the new item automatically unequips the old one.
    var slot = item.equip_slot;
    Equip_SlotSet(_ch, slot, _item_id);

    return true;
}

function Equip_SlotGet(_ch, _slot) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip")) return 0;
    if (is_struct(_ch.equip) && variable_struct_exists(_ch.equip, _slot)) {
        return variable_struct_get(_ch.equip, _slot);
    }
    return 0;
}

function Equip_SlotSet(_ch, _slot, _item_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip") || !is_struct(_ch.equip)) _ch.equip = {};
    variable_struct_set(_ch.equip, _slot, _item_id);
}

function Equip_GetStatBonus(_ch, _stat_id) {
    var total = 0;
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip") || !is_struct(_ch.equip)) return 0;

    var keys = ["weapon", "head", "body", "ring1", "ring2"];
    for (var i = 0; i < array_length(keys); i++) {
        var item_id = Equip_SlotGet(_ch, keys[i]);
        if (item_id == 0) continue;

        var item = ItemDB_Get(item_id);
        if (is_struct(item) && variable_struct_exists(item, "bonus")) {
            var b = item.bonus;
            switch (_stat_id) {
                case STAT_STR:  if (variable_struct_exists(b, "str")) total += b.str; break;
                case STAT_AGI:  if (variable_struct_exists(b, "agi")) total += b.agi; break;
                case STAT_DEF:  if (variable_struct_exists(b, "def")) total += b.def; break;
                case STAT_INT:  if (variable_struct_exists(b, "intt")) total += b.intt; break;
                case STAT_LUCK: if (variable_struct_exists(b, "luck")) total += b.luck; break;
            }
        }
    }

    return total;
}

function Equip_GetEquippedItems(_ch) {
    var out = [];
    if (!is_struct(_ch)) return out;
    var slots = ["weapon", "body", "head", "ring1", "ring2"];
    for (var i = 0; i < array_length(slots); i++) {
        var iid = Equip_SlotGet(_ch, slots[i]);
        if (iid == 0) continue;
        var it = ItemDB_Get(iid);
        if (is_struct(it) && it.id != 0) array_push(out, it);
    }
    return out;
}

function Equip_GetPassives(_ch) {
    var out = [];
    var equipped = Equip_GetEquippedItems(_ch);
    for (var i = 0; i < array_length(equipped); i++) {
        var it = equipped[i];
        if (!variable_struct_exists(it, "passive_id")) continue;
        var pid = string(it.passive_id);
        if (pid == "") continue;
        var pparams = {};
        if (variable_struct_exists(it, "passive_params") && is_struct(it.passive_params)) pparams = it.passive_params;
        array_push(out, { id: pid, params: pparams, item_id: it.id, item_name: it.name });
    }
    return out;
}

function Equip_GetPassiveList(_ch) {
    return Equip_GetPassives(_ch);
}

function Equip_HasPassive(_ch, _passive_id) {
    var pid = string(_passive_id);
    if (pid == "") return false;
    var list = Equip_GetPassives(_ch);
    for (var i = 0; i < array_length(list); i++) {
        if (list[i].id == pid) return true;
    }
    return false;
}

function Equip_GetPassiveParam(_ch, _passive_id, _key, _default = 0) {
    var pid = string(_passive_id);
    if (pid == "") return _default;
    var list = Equip_GetPassives(_ch);
    for (var i = 0; i < array_length(list); i++) {
        if (list[i].id != pid) continue;
        return Equip_PassiveValue(list[i], _key, _default);
    }
    return _default;
}

function Equip_PassiveValue(_passive, _field, _fallback = 0) {
    if (!is_struct(_passive) || !variable_struct_exists(_passive, "params")) return _fallback;
    var p = _passive.params;
    if (!is_struct(p) || !variable_struct_exists(p, _field)) return _fallback;
    return real(variable_struct_get(p, _field));
}

function Equip_TargetHasAnyStatus(_ch) {
    return is_struct(_ch) && variable_struct_exists(_ch, "status") && is_array(_ch.status) && array_length(_ch.status) > 0;
}

function Equip_PassiveRuntimeEnsure(_ch) {
    if (!is_struct(_ch)) return {};
    if (!variable_struct_exists(_ch, "passive_runtime") || !is_struct(_ch.passive_runtime)) {
        _ch.passive_runtime = {
            battle_turn: 0,
            first_hit_done: false,
            steady_strike_turn: -1,
            aim_assist_turn: -1,
            pinning_cooldown: 0,
            first_impact_used: false,
            brace_guard_ready: false,
            brace_cooldown: 0,
            mirror_used: false
        };
    }
    return _ch.passive_runtime;
}

function Equip_PassiveBattleReset(_ch) {
    if (!is_struct(_ch)) return _ch;
    _ch.passive_runtime = {
        battle_turn: 0,
        first_hit_done: false,
        steady_strike_turn: -1,
        aim_assist_turn: -1,
        pinning_cooldown: 0,
        first_impact_used: false,
        brace_guard_ready: false,
        brace_cooldown: 0,
        mirror_used: false
    };
    return _ch;
}

function Equip_PassiveBattleCleanup(_ch) {
    if (!is_struct(_ch)) return _ch;
    if (variable_struct_exists(_ch, "passive_runtime")) {
        variable_struct_remove(_ch, "passive_runtime");
    }
    return _ch;
}

function Equip_PassiveOnTurnStart(_ch) {
    if (!is_struct(_ch)) return _ch;
    var rt = Equip_PassiveRuntimeEnsure(_ch);
    rt.battle_turn += 1;
    if (rt.pinning_cooldown > 0) rt.pinning_cooldown -= 1;
    if (rt.brace_cooldown > 0) rt.brace_cooldown -= 1;

    var gain = 0;
    var passives = Equip_GetPassives(_ch);
    for (var i = 0; i < array_length(passives); i++) {
        var p = passives[i];
        var mp_gain = max(0, round(Equip_PassiveValue(p, "mp_gain", 0)));
        var every_n = max(0, round(Equip_PassiveValue(p, "every_n_turns", 0)));
        if (mp_gain > 0 && every_n > 0) {
            if ((rt.battle_turn mod every_n) == 0) gain += mp_gain;
        }
    }

    if (gain > 0 && variable_struct_exists(_ch, "mp") && variable_struct_exists(_ch, "max_mp")) {
        _ch.mp = clamp(_ch.mp + gain, 0, _ch.max_mp);
    }
    return _ch;
}

function Equip_PassiveOnSkillUsed(_ch, _skill) {
    if (!is_struct(_ch)) return _ch;
    // Reserved hook for future passive interactions on skill-use.
    return _ch;
}

function Equip_PassiveAdjustIncomingStatus(_source, _target, _status_id, _turns) {
    var out = { apply: true, turns: _turns, reflect: false, msg: "" };
    if (!is_struct(_target) || !variable_struct_exists(_target, "is_player") || !_target.is_player) return out;
    if (is_struct(_source) && variable_struct_exists(_source, "is_player") && _source.is_player) return out;

    var rt = Equip_PassiveRuntimeEnsure(_target);
    if (Equip_HasPassive(_target, "mirror_stitch") && !rt.mirror_used) {
        if (!Equip_GetPassiveParam(_target, "mirror_stitch", "reflect_first_status_once_per_battle", 1)) return out;
        rt.mirror_used = true;
        out.apply = false;
        out.reflect = true;
        out.msg = "Mirror Stitch repelled a status!";
        if (variable_struct_exists(_target, "mp")) {
            var mp_cost = max(0, round(Equip_GetPassiveParam(_target, "mirror_stitch", "mp_cost_on_trigger", 1)));
            _target.mp = max(0, _target.mp - mp_cost);
        }
    }

    return out;
}

function Equip_ModifyTimedAttackResult(_ch, _timing) {
    var t = _timing;
    if (!is_struct(t)) return t;

    var key = variable_struct_exists(t, "key") ? string_upper(string(t.key)) : "MISS";
    var mult = variable_struct_exists(t, "mult") ? real(t.mult) : 0;
    var rt = Equip_PassiveRuntimeEnsure(_ch);

    if (Equip_HasPassive(_ch, "steady_strike") && rt.steady_strike_turn != rt.battle_turn) {
        var can_once = Equip_GetPassiveParam(_ch, "steady_strike", "once_per_turn", 1);
        if (can_once) {
            if (key == "MISS") {
                key = "BAD";
                mult = 0.25;
                rt.steady_strike_turn = rt.battle_turn;
            } else if (key == "BAD") {
                key = "OKAY";
                mult = 0.50;
                rt.steady_strike_turn = rt.battle_turn;
            }
        }
    }

    if (Equip_HasPassive(_ch, "aim_assist") && rt.aim_assist_turn != rt.battle_turn) {
        var can_promote = Equip_GetPassiveParam(_ch, "aim_assist", "upgrade_good_to_perfect_once_per_turn", 1);
        if (can_promote && key == "GOOD") {
            key = "PERFECT";
            mult = 1.00;
            rt.aim_assist_turn = rt.battle_turn;
        }
    }

    switch (key) {
        case "PERFECT": return { key: "PERFECT", label: "PERFECT", mult: clamp(mult, 0, 1), hit: true };
        case "GOOD":    return { key: "GOOD",    label: "GOOD",    mult: clamp(mult, 0, 1), hit: true };
        case "OKAY":    return { key: "OKAY",    label: "OKAY",    mult: clamp(mult, 0, 1), hit: true };
        case "BAD":     return { key: "BAD",     label: "BAD",     mult: clamp(mult, 0, 1), hit: true };
    }
    return { key: "MISS", label: "MISS", mult: 0.00, hit: false };
}

function Equip_PlayerBonusDamage(_attacker, _defender, _base_damage, _is_skill = false, _timing_key = "") {
    var base = max(0, round(real(_base_damage)));
    if (base <= 0) return 0;

    var rt = Equip_PassiveRuntimeEnsure(_attacker);
    var def_ratio = 1;
    if (is_struct(_defender) && variable_struct_exists(_defender, "max_hp") && _defender.max_hp > 0 && variable_struct_exists(_defender, "hp")) {
        def_ratio = clamp(_defender.hp / _defender.max_hp, 0, 1);
    }

    var mult = 1;

    if (Equip_HasPassive(_attacker, "sunder_edge")) {
        if (!rt.first_hit_done) {
            var def_down = max(0, round(Equip_GetPassiveParam(_attacker, "sunder_edge", "first_hit_def_down", 1)));
            var turns = max(1, round(Equip_GetPassiveParam(_attacker, "sunder_edge", "turns", 2)));
            if (def_down > 0) _defender = Status_Add(_defender, STATUS_SUNDER, turns, def_down);
            rt.first_hit_done = true;
        }
    }

    if (Equip_HasPassive(_attacker, "executioner")) {
        var hp_ratio = Equip_GetPassiveParam(_attacker, "executioner", "hp_ratio", 0.35);
        if (def_ratio <= hp_ratio) {
            mult *= max(1, Equip_GetPassiveParam(_attacker, "executioner", "mult", 1.35));
        }
    }

    if (Equip_HasPassive(_attacker, "predator")) {
        var require_status = Equip_GetPassiveParam(_attacker, "predator", "requires_target_statused", 1);
        if (!require_status || Equip_TargetHasAnyStatus(_defender)) {
            mult *= max(1, Equip_GetPassiveParam(_attacker, "predator", "mult", 1.30));
        }
    }

    if (_is_skill && Equip_HasPassive(_attacker, "ember_lens")) {
        mult *= max(1, Equip_GetPassiveParam(_attacker, "ember_lens", "skill_mult", 1.15));
    }

    if (_is_skill && Equip_HasPassive(_attacker, "silk_flow")) {
        mult *= max(1, Equip_GetPassiveParam(_attacker, "silk_flow", "skill_mult", 1.10));
    }

    if (_is_skill && Equip_HasPassive(_attacker, "arcane_surge")) {
        mult *= max(1, Equip_GetPassiveParam(_attacker, "arcane_surge", "skill_mult", 1.25));
    }

    var total = max(0, floor(base * mult));
    return max(0, total - base);
}

function Equip_PlayerIncomingDamageReduction(_defender, _incoming_damage, _ctx = undefined) {
    var dmg = max(0, round(real(_incoming_damage)));
    if (dmg <= 0) return 0;

    var rt = Equip_PassiveRuntimeEnsure(_defender);
    var ctx = is_struct(_ctx) ? _ctx : {};
    var is_skill = (variable_struct_exists(ctx, "is_skill") && ctx.is_skill);

    var final_dmg = dmg;

    if (rt.brace_guard_ready && final_dmg > 0) {
        var guard_mult = clamp(Equip_GetPassiveParam(_defender, "brace", "guard_mult_next_hit", 0.60), 0.10, 1);
        final_dmg = floor(final_dmg * guard_mult);
        rt.brace_guard_ready = false;
        rt.brace_cooldown = max(rt.brace_cooldown, round(Equip_GetPassiveParam(_defender, "brace", "cooldown_turns", 2)));
    }

    if (Equip_HasPassive(_defender, "first_impact") && final_dmg > 0) {
        var first_once = Equip_GetPassiveParam(_defender, "first_impact", "once_per_battle", 1);
        if (!first_once || !rt.first_impact_used) {
            final_dmg -= round(Equip_GetPassiveParam(_defender, "first_impact", "flat_reduction_first_hit", 3));
            rt.first_impact_used = true;
        }
    }

    if (Equip_HasPassive(_defender, "debt_plate")) {
        var big_hit_threshold = max(1, round(Equip_GetPassiveParam(_defender, "debt_plate", "big_hit_threshold", 6)));
        if (final_dmg >= big_hit_threshold) {
            var big_red = clamp(Equip_GetPassiveParam(_defender, "debt_plate", "big_hit_reduction", 0.30), 0, 0.9);
            final_dmg = floor(final_dmg * (1 - big_red));
        }
    }

    if (!is_skill && final_dmg > 0) {
        if (Equip_HasPassive(_defender, "thin_veil")) final_dmg += max(0, round(Equip_GetPassiveParam(_defender, "thin_veil", "physical_vuln_flat", 1)));
    }

    var pdefs = Equip_GetPassives(_defender);
    for (var pidx = 0; pidx < array_length(pdefs); pidx++) {
        var red = clamp(Equip_PassiveValue(pdefs[pidx], "damage_reduction", 0), 0, 0.9);
        if (red > 0) {
            final_dmg = floor(final_dmg * (1 - red));
        }
    }

    final_dmg = max(0, round(final_dmg));
    return (dmg - final_dmg);
}

function Equip_PlayerAfterTakeDamage(_defender, _damage_taken, _ctx = undefined) {
    if (!is_struct(_defender)) return _defender;
    if (_damage_taken <= 0) return _defender;
    var rt = Equip_PassiveRuntimeEnsure(_defender);
    if (Equip_HasPassive(_defender, "brace")
    && Equip_GetPassiveParam(_defender, "brace", "triggers_on_take_damage", 1)
    && !rt.brace_guard_ready && rt.brace_cooldown <= 0) {
        rt.brace_guard_ready = true;
    }
    return _defender;
}

function Equip_PlayerTurnStartApply(_ch) {
    return Equip_PassiveOnTurnStart(_ch);
}

function Equip_PlayerPerfectHitApply(_ch, _timing_key) {
    if (!is_struct(_ch)) return _ch;
    if (string_upper(string(_timing_key)) != "PERFECT") return _ch;
    if (!variable_struct_exists(_ch, "max_mp") || !variable_struct_exists(_ch, "mp")) return _ch;

    if (Equip_HasPassive(_ch, "arcane_surge")) {
        var gain = max(0, round(Equip_GetPassiveParam(_ch, "arcane_surge", "perfect_mp", 1)));
        if (gain > 0) _ch.mp = clamp(_ch.mp + gain, 0, _ch.max_mp);
    }
    return _ch;
}

function Equip_PlayerSkillMPCost(_ch, _skill, _base_cost) {
    return max(0, round(real(_base_cost)));
}

function Equip_PlayerStatusTurnBonus(_ch, _status_id) {
    if (_status_id == STATUS_STUN) return 0;
    var bonus = 0;
    if (Equip_HasPassive(_ch, "ember_lens")) bonus += max(0, round(Equip_GetPassiveParam(_ch, "ember_lens", "status_turn_bonus", 1)));
    if (Equip_HasPassive(_ch, "silk_flow")) bonus += max(0, round(Equip_GetPassiveParam(_ch, "silk_flow", "status_turn_bonus", 1)));
    return bonus;
}

function Equip_PassiveOnAttackResolved(_attacker, _defender, _timing_key, _timing_hit, _damage_done) {
    var out = { attacker: _attacker, defender: _defender, msg: "" };
    if (!is_struct(_attacker) || !variable_struct_exists(_attacker, "is_player") || !_attacker.is_player) return out;
    var rt = Equip_PassiveRuntimeEnsure(_attacker);

    if (_timing_hit && _damage_done > 0 && Equip_HasPassive(_attacker, "pinning_shot")) {
        var key = string_upper(string(_timing_key));
        var req_gp = Equip_GetPassiveParam(_attacker, "pinning_shot", "requires_good_or_perfect", 1);
        var timing_ok = (!req_gp || key == "GOOD" || key == "PERFECT");
        if (timing_ok && rt.pinning_cooldown <= 0) {
            var chance = clamp(Equip_GetPassiveParam(_attacker, "pinning_shot", "stun_chance", 0.15), 0, 1);
            if (random(1) <= chance) {
                var stun_turns = max(1, round(Equip_GetPassiveParam(_attacker, "pinning_shot", "stun_turns", 1)));
                _defender = Status_Add(_defender, STATUS_STUN, stun_turns, 1);
                rt.pinning_cooldown = max(1, round(Equip_GetPassiveParam(_attacker, "pinning_shot", "cooldown_turns", 3)));
                out.msg = "Pinning Shot stunned the enemy!";
            }
        }
    }

    out.attacker = _attacker;
    out.defender = _defender;
    return out;
}

function Equip_FindStarterWeaponId(_class_id) {
    if (_class_id == CLASS_NOBODY) return 0;

    ItemDB_Init();
    var db = global.item_db;
    if (variable_global_exists("state") && is_struct(global.state) && variable_struct_exists(global.state, "item_db")) {
        db = global.state.item_db;
    }
    if (!ds_exists(db, ds_type_map)) return 0;

    var keys = ds_map_keys_to_array(db);
    var best_id = 0;
    var best_score = 1000000;

    for (var i = 0; i < array_length(keys); i++) {
        var iid = keys[i];
        var it = db[? iid];
        if (!is_struct(it)) continue;
        if (!variable_struct_exists(it, "type") || it.type != ITEM_WEAPON) continue;

        var allowed = true;
        if (variable_struct_exists(it, "preferred_class") && it.preferred_class != -1 && it.preferred_class != _class_id) allowed = false;
        if (allowed && variable_struct_exists(it, "allowed_classes") && is_array(it.allowed_classes)) {
            var ok = false;
            for (var j = 0; j < array_length(it.allowed_classes); j++) {
                if (it.allowed_classes[j] == _class_id) { ok = true; break; }
            }
            allowed = ok;
        }
        if (!allowed) continue;

        var pwr = variable_struct_exists(it, "power") ? round(real(it.power)) : 0;
        var val = variable_struct_exists(it, "value") ? round(real(it.value)) : 0;
        var item_score = (pwr * 100) + val;
        if (item_score < best_score) {
            best_score = item_score;
            best_id = it.id;
        }
    }
    return best_id;
}

function Equip_GrantStarterWeapon(_ch, _class_id, _auto_equip = true) {
    if (!is_struct(_ch)) return _ch;
    if (_class_id == CLASS_NOBODY) return _ch;
    if (!variable_struct_exists(_ch, "inventory") || !is_array(_ch.inventory)) _ch.inventory = [];

    var sid = Equip_FindStarterWeaponId(_class_id);
    if (sid <= 0) return _ch;

    if (!Inv_Has(_ch.inventory, sid, 1)) {
        _ch.inventory = Inv_Add(_ch.inventory, sid, 1);
    }

    if (_auto_equip) {
        var can = Equip_CanEquip(_ch, sid);
        if (can.ok) Equip_Item(_ch, sid);
    }

    return _ch;
}
