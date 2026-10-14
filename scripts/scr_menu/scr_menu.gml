function Menu_StatsCopy(_s) {
    return { atk: _s.atk, def: _s.def, spd: _s.spd, mag: _s.mag };
}

function Menu_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "menu")) {
        gs.ui.menu = {
            open: false,
            closing: false,
            close_frame: UI_OPENED_FRAME_NONE,
            tab: 0,
            tabs: [
                Loc_T("menu.tab.inventory", "Inventory"),
                Loc_T("menu.tab.skills", "Skills"),
                Loc_T("menu.tab.stats", "Stats")
            ],
            header_focus: true,
            opened_frame: UI_OPENED_FRAME_NONE,
            inv_index: 0,
            inv_scroll: 0,
            inv_popup_open: false,
            inv_popup_mode: "",
            inv_popup_choice: 1,
            inv_popup_message: "",
            inv_popup_item_id: -1,
            inv_popup_block_frame: UI_OPENED_FRAME_NONE,
            inv_popup_open_frame: UI_OPENED_FRAME_NONE,
            inv_popup_closing: false,
            inv_popup_close_frame: UI_OPENED_FRAME_NONE,
            skill_index: 0,
            skill_scroll: 0,
            stats_focus: false,
            stats_row: 0,
            stats_col: 1,
            stats_index: 0,
            base_stats: undefined,
            pending_stats: undefined,
            pending_points: 0
        };
    } else {
        var m0 = gs.ui.menu;
        if (!variable_struct_exists(m0, "opened_frame")) m0.opened_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(m0, "inv_popup_open_frame")) m0.inv_popup_open_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(m0, "closing")) m0.closing = false;
        if (!variable_struct_exists(m0, "close_frame")) m0.close_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(m0, "inv_popup_closing")) m0.inv_popup_closing = false;
        if (!variable_struct_exists(m0, "inv_popup_close_frame")) m0.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
    }
}

function Menu_Open() {
    Menu_Ensure();
    var gs = GameState_Get();
    UI_ModalRootBegin("menu");
    SFX_PlayUI("ui_openclose");
    gs.ui.mode = UI_MENU;
    var m = gs.ui.menu;
    m.open = true;
    m.closing = false;
    m.close_frame = UI_OPENED_FRAME_NONE;
    m.header_focus = true;
    m.stats_focus = false;
    m.opened_frame = Input_Frame();
    // Reopen inventory from the top to avoid snap-to-old-selection behavior.
    m.inv_index = 0;
    m.inv_scroll = 0;
    m.inv_popup_open = false;
    m.inv_popup_closing = false;
    m.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
    m.inv_popup_open_frame = UI_OPENED_FRAME_NONE;
    m.inv_popup_mode = "";
    m.inv_popup_message = "";
    m.inv_popup_item_id = -1;
    m.inv_popup_choice = 1;
    m.inv_popup_block_frame = UI_OPENED_FRAME_NONE;
    gs.ui.menu = m;
    Menu_StatsSync();
}

function Menu_Close(_immediate = false) {
    Menu_Ensure();
    var gs = GameState_Get();
    var m = gs.ui.menu;
    if (_immediate) {
        UI_ModalRootEnd(false, true);
        Menu_StatsDiscard();
        gs.ui.menu.open = false;
        gs.ui.menu.closing = false;
        gs.ui.menu.close_frame = UI_OPENED_FRAME_NONE;
        gs.ui.mode = UI_NONE;
        SFX_PlayUI("ui_openclose");
        return;
    }
    if (!m.open || m.closing) return;
    UI_ModalRootEnd(false);
    Menu_StatsDiscard();
    m.closing = true;
    m.close_frame = Input_Frame();
    m.inv_popup_closing = false;
    m.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
    gs.ui.menu = m;
    SFX_PlayUI("ui_openclose");
}

function Menu_CloseFinalize() {
    Menu_Ensure();
    var gs = GameState_Get();
    var m = gs.ui.menu;
    m.open = false;
    m.closing = false;
    m.close_frame = UI_OPENED_FRAME_NONE;
    m.inv_popup_open = false;
    m.inv_popup_closing = false;
    m.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
    m.inv_popup_open_frame = UI_OPENED_FRAME_NONE;
    gs.ui.menu = m;
    gs.ui.mode = UI_NONE;
}

function Menu_InvPopupClose(_m, _immediate = false) {
    if (_immediate) {
        _m.inv_popup_open = false;
        _m.inv_popup_closing = false;
        _m.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
        _m.inv_popup_mode = "";
        _m.inv_popup_choice = 1;
        _m.inv_popup_message = "";
        _m.inv_popup_item_id = -1;
        _m.inv_popup_block_frame = UI_OPENED_FRAME_NONE;
        _m.inv_popup_open_frame = UI_OPENED_FRAME_NONE;
        return _m;
    }
    if (!_m.inv_popup_open || _m.inv_popup_closing) return _m;
    _m.inv_popup_closing = true;
    _m.inv_popup_close_frame = Input_Frame();
    _m.inv_popup_block_frame = Input_Frame() + 1;
    return _m;
}

function Menu_IsOpen() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) return false;
    return gs.ui.mode == UI_MENU;
}

function Menu_GetLayout() {
    var w = Display_GuiW();
    var h = Display_GuiH();
    UI_SetFont();
    var line_h = UI_TextHeight("A");
    var margin = round(min(w, h) * 0.05);
    var bx = margin;
    var by = margin;
    var bw = round(w - margin * 2);
    var bh = round(h - margin * 2);
    var header_h = round(max(line_h + 10, bh * 0.10));
    var pad = round(max(6, min(w, h) * 0.02));
    var row_h = round(max(line_h + 4, bh * 0.06));
    var content_y = by + header_h + pad;
    var tip_style = Tooltip_GetStyle("menu");
    var tip_gap = max(4, round(pad * 0.50));
    var list_top_inset = 18;
    var list_bottom_inset = 18;
    var inner_h = bh - pad * 2;
    var body_h = max(row_h * 2 + tip_style.min_h + tip_gap + list_top_inset + list_bottom_inset, inner_h - header_h);
    var tip_h_max = max(tip_style.min_h, body_h - (row_h * 2) - tip_gap);
    var tooltip_h = clamp(round(body_h * tip_style.height_ratio), tip_style.min_h, tip_h_max);
    var content_h = max(row_h * 2, body_h - tooltip_h - tip_gap);
    var main_h = header_h + pad + content_h + pad;
    var tooltip_y = by + main_h + tip_gap;
    var content_list_y = content_y + list_top_inset;
    var content_list_h = max(row_h, content_h - list_top_inset - list_bottom_inset);
    var rows_visible = max(1, floor(content_list_h / row_h));
    return {
        w:w, h:h, bx:bx, by:by, bw:bw, bh:bh,
        header_h:header_h, pad:pad, row_h:row_h,
        content_y:content_y, content_h:content_h, rows_visible:rows_visible,
        content_list_y:content_list_y, content_list_h:content_list_h,
        list_top_inset:list_top_inset, list_bottom_inset:list_bottom_inset,
        tooltip_h:tooltip_h, tooltip_gap:tip_gap, tooltip_y:tooltip_y, main_h:main_h
    };
}

function Menu_IsEquipped(_ch, _item_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip")) return false;
    var eq = _ch.equip;
    if (variable_struct_exists(eq, "weapon") && eq.weapon == _item_id) return true;
    if (variable_struct_exists(eq, "body") && eq.body == _item_id) return true;
    return false;
}

function Tooltip_StatShortName(_stat_id) {
    var short_name = Stat_ShortName(_stat_id);
    return (short_name != "") ? short_name : "N/A";
}

function Tooltip_TargetName(_target_id) {
    switch (_target_id) {
        case TGT_SELF: return Loc_T("menu.tooltip.target.self", "Self");
        case TGT_ENEMY: return Loc_T("menu.tooltip.target.enemy", "Opponent");
        case TGT_ALL_ENEMIES: return Loc_T("menu.tooltip.target.all_enemies", "All Opponents");
        case TGT_ALL_ALLIES: return Loc_T("menu.tooltip.target.all_allies", "All Allies");
        case TGT_ALL: return Loc_T("menu.tooltip.target.all", "All");
    }
    return Loc_T("menu.tooltip.target.unknown", "Unknown");
}

function Tooltip_ClassListText(_class_list) {
    if (!is_array(_class_list) || array_length(_class_list) <= 0) return Loc_T("menu.tooltip.class.all", "All Classes");
    var txt = "";
    for (var i = 0; i < array_length(_class_list); i++) {
        if (i > 0) txt += "/";
        txt += Equip_ClassName(_class_list[i]);
    }
    return txt;
}

function Tooltip_ClassOnlyText(_class_list) {
    if (!is_array(_class_list) || array_length(_class_list) <= 0) return "";
    var class_txt = Tooltip_ClassListText(_class_list);
    return Loc_T("menu.tooltip.class.only", "{classes} only", { classes: class_txt });
}

function Tooltip_StatusName(_status_id) {
    if (_status_id == -1) return "";
    var cfg = StatusDB_Get(_status_id);
    if (is_struct(cfg) && variable_struct_exists(cfg, "name")) return Status_LabelWithSign(cfg, _status_id);
    return Loc_T("menu.tooltip.status.default", "Status");
}

function Tooltip_StatusEffectLine(_status_id) {
    if (_status_id == -1) return "";
    var desc = Status_Description(_status_id);
    if (desc == "") return "";
    return Tooltip_StatusName(_status_id) + ": " + desc;
}

function Tooltip_AddWrappedLines(_out_lines, _text, _max_w) {
    var out_lines = is_array(_out_lines) ? _out_lines : [];
    var wrapped = Dialogue_WrapToLines(string(_text), max(1, _max_w));
    if (!is_array(wrapped) || array_length(wrapped) <= 0) {
        array_push(out_lines, string(_text));
        return out_lines;
    }
    for (var i = 0; i < array_length(wrapped); i++) {
        array_push(out_lines, wrapped[i]);
    }
    return out_lines;
}

function Tooltip_PassiveLineHuman(_line) {
    var txt = string(_line);
    txt = string_replace_all(txt, "->", Loc_T("menu.tooltip.passive.to", " to "));
    txt = string_replace_all(txt, "1/turn", Loc_T("menu.tooltip.passive.once_per_turn", "once per turn"));
    txt = string_replace_all(txt, "(cd", Loc_T("menu.tooltip.passive.cooldown_prefix", "(cooldown"));
    txt = string_replace_all(txt, "cd ", Loc_T("menu.tooltip.passive.cooldown", "cooldown "));
    txt = string_replace_all(txt, "GOOD+:", Loc_T("menu.tooltip.passive.good_plus_colon", "GOOD or PERFECT:"));
    txt = string_replace_all(txt, "GOOD+", Loc_T("menu.tooltip.passive.good_plus", "GOOD or PERFECT"));
    return txt;
}

function Tooltip_ContainsTextInsensitive(_haystack, _needle) {
    var hay = string_lower(string(_haystack));
    var needle = string_lower(string(_needle));
    if (needle == "") return false;
    return string_pos(needle, hay) > 0;
}

function Tooltip_EquippableNote(_item) {
    if (!is_struct(_item)) return "";

    if (variable_struct_exists(_item, "tooltip_note")) {
        var single = string(_item.tooltip_note);
        if (single != "") return single;
    }

    if (variable_struct_exists(_item, "tooltip_notes") && is_array(_item.tooltip_notes) && array_length(_item.tooltip_notes) > 0) {
        var joined = "";
        for (var ni = 0; ni < array_length(_item.tooltip_notes); ni++) {
            var note = string(_item.tooltip_notes[ni]);
            if (note == "") continue;
            if (joined != "") joined += "; ";
            joined += note;
        }
        if (joined != "") return joined;
    }

    if (variable_struct_exists(_item, "passive_desc") && is_array(_item.passive_desc) && array_length(_item.passive_desc) > 1) {
        return Tooltip_PassiveLineHuman(_item.passive_desc[1]);
    }
    if (variable_struct_exists(_item, "passive_desc") && is_array(_item.passive_desc) && array_length(_item.passive_desc) > 0) {
        return Tooltip_PassiveLineHuman(_item.passive_desc[0]);
    }
    return "";
}

function Tooltip_SkillDamageLine(_skill) {
    if (!is_struct(_skill)) return Loc_T("menu.tooltip.damage", "Damage");
    var parts = [
        Loc_T("menu.tooltip.damage.power", "Power {power}", {
            power: string(max(0, round(real(_skill.power))))
        })
    ];

    if (variable_struct_exists(_skill, "power_mult")) {
        var pm = real(_skill.power_mult);
        if (pm != 1) array_push(parts, "x" + string_format(pm, 1, 2));
    }
    if (variable_struct_exists(_skill, "hits") && _skill.hits > 1) {
        array_push(parts, Loc_T("menu.tooltip.damage.hits", "{hits} hits", {
            hits: string(round(real(_skill.hits)))
        }));
    }
    if (variable_struct_exists(_skill, "acc") && _skill.acc != 0) {
        var acc_txt = ((_skill.acc > 0) ? "+" : "") + string(_skill.acc);
        array_push(parts, Loc_T("menu.tooltip.damage.acc", "Acc {acc}", { acc: acc_txt }));
    }
    if (variable_struct_exists(_skill, "stat_type")) {
        array_push(parts, Loc_T("menu.tooltip.damage.stat", "Stat {stat}", {
            stat: Tooltip_StatShortName(_skill.stat_type)
        }));
    }

    var out = parts[0];
    for (var i = 1; i < array_length(parts); i++) out += " | " + parts[i];
    return out;
}

function Tooltip_SkillSingleStatusLine(_status_id, _turns, _chance) {
    if (_status_id == -1) return "";
    var chance = clamp(real(_chance), 0, 1);
    var line = Loc_T("menu.tooltip.status.line", "Status: {status} {chance}%", {
        status: Tooltip_StatusName(_status_id),
        chance: string(round(chance * 100))
    });
    var turns = max(0, round(real(_turns)));
    if (turns > 0) {
        line += Loc_T("menu.tooltip.status.turns_suffix", " | {turns} turns", {
            turns: string(turns)
        });
    }
    return line;
}

function Tooltip_SkillMultiStatusDetailLines(_skill, _max_entries = 2) {
    var lines = [];
    if (!is_struct(_skill)) return lines;
    if (!variable_struct_exists(_skill, "status_list") || !is_array(_skill.status_list)) return lines;

    var seen = [];
    var max_entries = max(1, round(real(_max_entries)));
    for (var i = 0; i < array_length(_skill.status_list); i++) {
        var sid = _skill.status_list[i];
        if (sid == -1) continue;

        var dup = false;
        for (var j = 0; j < array_length(seen); j++) {
            if (seen[j] == sid) { dup = true; break; }
        }
        if (dup) continue;
        array_push(seen, sid);

        var line = Tooltip_StatusEffectLine(sid);
        if (line != "") array_push(lines, line);
        if (array_length(lines) >= max_entries) break;
    }

    return lines;
}

function Tooltip_SkillMultiStatusLine(_skill, _max_entries = 3) {
    if (!is_struct(_skill)) return "";
    if (!variable_struct_exists(_skill, "status_list") || !is_array(_skill.status_list) || array_length(_skill.status_list) <= 0) return "";

    var base_turns = variable_struct_exists(_skill, "status_turns") ? max(1, round(real(_skill.status_turns))) : 1;
    var has_turn_list = variable_struct_exists(_skill, "status_turns_list") && is_array(_skill.status_turns_list);
    var shown = [];
    var total_statuses = 0;
    var max_entries = max(1, round(real(_max_entries)));

    for (var i = 0; i < array_length(_skill.status_list); i++) {
        var sid = _skill.status_list[i];
        if (sid == -1) continue;
        total_statuses += 1;
        if (array_length(shown) >= max_entries) continue;

        var turns = base_turns;
        if (has_turn_list && i < array_length(_skill.status_turns_list)) {
            turns = max(1, round(real(_skill.status_turns_list[i])));
        }

        var seg = Tooltip_StatusName(sid);
        if (turns > 0) {
            seg += Loc_T("menu.tooltip.status.turns_short", " {turns}t", {
                turns: string(turns)
            });
        }
        array_push(shown, seg);
    }

    if (array_length(shown) <= 0) return "";
    var line = Loc_T("menu.tooltip.statuses.prefix", "Statuses: {first}", {
        first: shown[0]
    });
    for (var j = 1; j < array_length(shown); j++) line += ", " + shown[j];
    if (total_statuses > array_length(shown)) {
        var remaining = total_statuses - array_length(shown);
        line += Loc_T("menu.tooltip.statuses.more", ", +{count} more", {
            count: string(remaining)
        });
    }

    var chance = variable_struct_exists(_skill, "status_chance") ? clamp(real(_skill.status_chance), 0, 1) : 1;
    if (chance < 1) line += " (" + string(round(chance * 100)) + "%)";
    return line;
}

function Tooltip_SkillEffectLines(_skill, _compact = false) {
    var lines = [];
    if (!is_struct(_skill)) return lines;

    var effect = variable_struct_exists(_skill, "effect") ? string(_skill.effect) : "";
    switch (effect) {
        case "damage":
            array_push(lines, Tooltip_SkillDamageLine(_skill));
            if (variable_struct_exists(_skill, "status") && _skill.status != -1) {
                var dmg_turns = variable_struct_exists(_skill, "status_turns") ? max(1, round(real(_skill.status_turns))) : 1;
                var dmg_chance = variable_struct_exists(_skill, "status_chance") ? clamp(real(_skill.status_chance), 0, 1) : 1;
                var dmg_status_line = Tooltip_SkillSingleStatusLine(_skill.status, dmg_turns, dmg_chance);
                if (dmg_status_line != "") array_push(lines, dmg_status_line);
                var dmg_status_desc = Tooltip_StatusEffectLine(_skill.status);
                if (dmg_status_desc != "") array_push(lines, dmg_status_desc);
            }
        break;

        case "status":
            if (variable_struct_exists(_skill, "status") && _skill.status != -1) {
                var turns = variable_struct_exists(_skill, "status_turns") ? max(1, round(real(_skill.status_turns))) : 1;
                var chance = variable_struct_exists(_skill, "status_chance") ? clamp(real(_skill.status_chance), 0, 1) : 1;
                var status_line = Tooltip_SkillSingleStatusLine(_skill.status, turns, chance);
                if (status_line != "") array_push(lines, status_line);
                var status_desc = Tooltip_StatusEffectLine(_skill.status);
                if (status_desc != "") array_push(lines, status_desc);
            } else {
                array_push(lines, Loc_T("menu.tooltip.effect.buff", "Effect: Buff"));
            }
        break;

        case "multi_status":
            var max_status_entries = _compact ? 3 : 4;
            var multi_line = Tooltip_SkillMultiStatusLine(_skill, max_status_entries);
            if (multi_line != "") array_push(lines, multi_line);
            else array_push(lines, Loc_T("menu.tooltip.effect.multi_status", "Effect: Multiple statuses"));
            var detail_max = _compact ? 1 : 2;
            var multi_details = Tooltip_SkillMultiStatusDetailLines(_skill, detail_max);
            for (var md = 0; md < array_length(multi_details); md++) {
                array_push(lines, multi_details[md]);
            }
        break;

        case "heal":
            array_push(lines, Loc_T("menu.tooltip.effect.restore_hp", "Effect: Restore HP"));
        break;

        case "steal_item":
            array_push(lines, Loc_T("menu.tooltip.effect.steal_item", "Effect: Steal one random item"));
        break;

        default:
            if (effect != "" && effect != "none") {
                array_push(lines, Loc_T("menu.tooltip.effect.named", "Effect: {effect}", { effect: effect }));
            }
        break;
    }

    return lines;
}

function Tooltip_BuildStatLines(_stat_key, _stat_label, _cur) {
    var lines = [];
    array_push(lines, _stat_label + " (" + string(_cur) + ")");

    switch (_stat_key) {
        case "atk":
            array_push(lines, Loc_T("menu.tooltip.stat.atk.desc", "Increases physical damage (basic attacks and ATK skills)."));
        break;
        case "def":
            array_push(lines, Loc_T("menu.tooltip.stat.def.desc", "Reduces all damage you take."));
        break;
        case "spd":
            array_push(lines, Loc_T("menu.tooltip.stat.spd.desc", "Decides who acts first."));
        break;
        case "mag":
            array_push(lines, Loc_T("menu.tooltip.stat.mag.desc", "Increases spell damage and max MP."));
        break;
        default:
            array_push(lines, Loc_T("menu.tooltip.stat.default.desc", "Affects combat performance."));
        break;
    }
    return lines;
}

function Tooltip_ItemBonusText(_item) {
    if (!is_struct(_item) || !variable_struct_exists(_item, "bonus") || !is_struct(_item.bonus)) return "";
    var b = _item.bonus;
    var parts = [];
    if (variable_struct_exists(b, "atk") && b.atk != 0) array_push(parts, "ATK " + ((b.atk > 0) ? "+" : "") + string(b.atk));
    if (variable_struct_exists(b, "def") && b.def != 0) array_push(parts, "DEF " + ((b.def > 0) ? "+" : "") + string(b.def));
    if (variable_struct_exists(b, "spd") && b.spd != 0) array_push(parts, "SPD " + ((b.spd > 0) ? "+" : "") + string(b.spd));
    if (variable_struct_exists(b, "mag") && b.mag != 0) array_push(parts, "MAG " + ((b.mag > 0) ? "+" : "") + string(b.mag));
    if (array_length(parts) <= 0) return "";
    var txt = parts[0];
    for (var i = 1; i < array_length(parts); i++) txt += ", " + parts[i];
    return txt;
}

function Tooltip_ItemTypeLine(_item) {
    if (!is_struct(_item) || !variable_struct_exists(_item, "type")) return Loc_T("menu.tooltip.item.type.unknown", "Unknown");
    if (_item.type == ITEM_WEAPON || _item.type == ITEM_ARMOR) {
        var slot_name = variable_struct_exists(_item, "equip_slot") ? string(_item.equip_slot) : "";
        var type_name = (_item.type == ITEM_WEAPON)
            ? Loc_T("menu.tooltip.item.type.weapon", "Weapon")
            : Loc_T("menu.tooltip.item.type.armor", "Armor");
        if (slot_name != "") {
            return Loc_T("menu.tooltip.item.type.with_slot", "{type} (slot: {slot})", {
                type: type_name,
                slot: slot_name
            });
        }
        return type_name;
    }
    if (_item.type == ITEM_CONSUMABLE) return Loc_T("menu.tooltip.item.type.consumable", "Consumable");
    if (_item.type == ITEM_KEY) return Loc_T("menu.tooltip.item.type.key", "Key Item");
    return Loc_T("menu.tooltip.item.type.unknown", "Unknown");
}

function Tooltip_BuildItemLines(_item) {
    var lines = [];
    if (!is_struct(_item) || !variable_struct_exists(_item, "id") || _item.id == 0) return lines;

    array_push(lines, string(_item.name));
    if (_item.type != ITEM_ARMOR) {
        array_push(lines, Tooltip_ItemTypeLine(_item));
    }

    if (_item.type == ITEM_WEAPON || _item.type == ITEM_ARMOR) {
        if (_item.type == ITEM_ARMOR) {
            var armor_line = Tooltip_ItemBonusText(_item);
            if (armor_line == "") {
                if (variable_struct_exists(_item, "stat_type")) {
                    armor_line = Tooltip_StatShortName(_item.stat_type);
                } else {
                    armor_line = Loc_T("menu.tooltip.item.type.armor", "Armor");
                }
            }
            array_push(lines, armor_line);

            var armor_note = Tooltip_EquippableNote(_item);
            if (armor_note != "") array_push(lines, armor_note);

            var armor_only = "";
            if (variable_struct_exists(_item, "preferred_class") && _item.preferred_class != -1) {
                armor_only = Loc_T("menu.tooltip.class.only", "{classes} only", {
                    classes: Equip_ClassName(_item.preferred_class)
                });
            } else if (variable_struct_exists(_item, "allowed_classes") && is_array(_item.allowed_classes)) {
                armor_only = Tooltip_ClassOnlyText(_item.allowed_classes);
            }
            if (armor_only != "") array_push(lines, armor_only);
            return lines;
        }

        var parts = [
            Loc_T("menu.tooltip.damage.power", "Power {power}", {
                power: string(max(0, round(real(_item.power))))
            })
        ];
        if (variable_struct_exists(_item, "acc") && _item.acc != 0) {
            var acc_txt = ((_item.acc > 0) ? "+" : "") + string(_item.acc);
            array_push(parts, Loc_T("menu.tooltip.damage.acc", "Acc {acc}", { acc: acc_txt }));
        }
        if (variable_struct_exists(_item, "stat_type")) {
            array_push(parts, Loc_T("menu.tooltip.damage.stat", "Stat {stat}", {
                stat: Tooltip_StatShortName(_item.stat_type)
            }));
        }
        var core = parts[0];
        for (var i = 1; i < array_length(parts); i++) core += " | " + parts[i];
        array_push(lines, core);

        var bonus_txt = Tooltip_ItemBonusText(_item);
        if (bonus_txt != "") {
            array_push(lines, Loc_T("menu.tooltip.item.bonus", "Bonus: {bonus}", { bonus: bonus_txt }));
        }

        var note_txt = Tooltip_EquippableNote(_item);
        if (note_txt != "") array_push(lines, note_txt);

        var class_txt = Loc_T("menu.tooltip.class.all", "All Classes");
        if (variable_struct_exists(_item, "preferred_class") && _item.preferred_class != -1) {
            class_txt = Equip_ClassName(_item.preferred_class);
        } else if (variable_struct_exists(_item, "allowed_classes") && is_array(_item.allowed_classes)) {
            class_txt = Tooltip_ClassListText(_item.allowed_classes);
        }
        if (class_txt != Loc_T("menu.tooltip.class.all", "All Classes")) {
            array_push(lines, Loc_T("menu.tooltip.class.only", "{classes} only", { classes: class_txt }));
        }
        return lines;
    }

    if (_item.type == ITEM_CONSUMABLE && variable_struct_exists(_item, "use") && is_struct(_item.use)) {
        var use = _item.use;
        var eff = variable_struct_exists(use, "effect") ? string(use.effect) : "none";
        switch (eff) {
            case "heal":
                var hmin = variable_struct_exists(use, "min") ? round(real(use.min)) : round(real(use.power));
                var hmax = variable_struct_exists(use, "max") ? round(real(use.max)) : hmin;
                var hline = Loc_T("menu.tooltip.item.heal_hp", "Heal HP {min}-{max}", {
                    min: string(hmin),
                    max: string(hmax)
                });
                if (variable_struct_exists(use, "scale") && real(use.scale) > 0) {
                    array_push(lines, hline);
                    array_push(lines, Loc_T("menu.tooltip.item.scale_with_level", "Amount scales with level."));
                } else {
                    array_push(lines, hline);
                }
            break;
            case "mp":
                var mmin = variable_struct_exists(use, "min") ? round(real(use.min)) : round(real(use.power));
                var mmax = variable_struct_exists(use, "max") ? round(real(use.max)) : mmin;
                var mline = Loc_T("menu.tooltip.item.restore_mp", "Restore MP {min}-{max}", {
                    min: string(mmin),
                    max: string(mmax)
                });
                if (variable_struct_exists(use, "scale") && real(use.scale) > 0) {
                    array_push(lines, mline);
                    array_push(lines, Loc_T("menu.tooltip.item.scale_with_level", "Amount scales with level."));
                } else {
                    array_push(lines, mline);
                }
            break;
            case "cure":
                array_push(lines, Loc_T("menu.tooltip.item.cure", "Cure: {status}", {
                    status: Tooltip_StatusName(use.status)
                }));
            break;
            default:
                array_push(lines, Loc_T("menu.tooltip.effect.named", "Effect: {effect}", { effect: eff }));
            break;
        }
    }

    return lines;
}

function Tooltip_BuildSkillLines(_skill) {
    var lines = [];
    if (!is_struct(_skill) || !variable_struct_exists(_skill, "id") || _skill.id == -1) return lines;

    array_push(lines, string(_skill.name));
    var mp_line = Loc_T("menu.tooltip.skill.mp", "MP {mp}", {
        mp: string(max(0, round(real(_skill.mp_cost))))
    });
    var tgt = variable_struct_exists(_skill, "target") ? _skill.target : TGT_ENEMY;
    mp_line += Loc_T("menu.tooltip.skill.target_suffix", " | Target: {target}", {
        target: Tooltip_TargetName(tgt)
    });
    array_push(lines, mp_line);

    var effect_lines = Tooltip_SkillEffectLines(_skill, false);
    for (var i = 0; i < array_length(effect_lines); i++) {
        array_push(lines, effect_lines[i]);
    }

    var class_list = variable_struct_exists(_skill, "class_list") && is_array(_skill.class_list) ? _skill.class_list : [];
    var class_only = Tooltip_ClassOnlyText(class_list);
    if (class_only != "") array_push(lines, class_only);

    return lines;
}

// DEV_NOTE (tooltip audit, 2026-03-01):
// Kept the shared tooltip pipeline in this file:
// Tooltip_BuildItemLines / Tooltip_BuildSkillLines + Tooltip_DrawBox.
// Reason: both Menu_Draw and obj_battle_controller/Draw_64.gml already reuse it cleanly.
// Changed only where useful: compact text scale, data-driven equippable Notes, skillbook de-duplication, and content-fit tooltip sizing.
function Tooltip_GetStyle(_context = "default") {
    var s = {
        pad: 4,
        text_scale: 0.90,
        line_gap: 1,
        frame_alpha_mult: 0.88,
        min_w: 12,
        min_h: 12,
        margin_px: 0,
        width_ratio: 0.36,
        height_ratio: 0.24
    };

    if (_context == "menu") {
        s.pad = 5;
        s.text_scale = 0.93;
        s.line_gap = 1;
        s.min_w = 62;
        s.min_h = 72;
        s.margin_px = 0;
        s.width_ratio = 1.00;
        s.height_ratio = 0.36;
    } else if (_context == "battle") {
        s.pad = 5;
        s.text_scale = 0.93;
        s.line_gap = 1;
        s.min_w = 72;
        s.min_h = 56;
        s.margin_px = 6;
        s.width_ratio = 1.00;
        s.height_ratio = 0.0; // battle tooltip uses fixed pixel height
    }

    // Optional runtime override hook for future balancing/UI tuning.
    if (variable_global_exists("tooltip_style") && is_struct(global.tooltip_style)) {
        var root = global.tooltip_style;
        var ov = undefined;
        if (variable_struct_exists(root, _context) && is_struct(variable_struct_get(root, _context))) {
            ov = variable_struct_get(root, _context);
        } else if (variable_struct_exists(root, "default") && is_struct(variable_struct_get(root, "default"))) {
            ov = variable_struct_get(root, "default");
        }
        if (is_struct(ov)) {
            if (variable_struct_exists(ov, "pad")) s.pad = max(1, round(real(ov.pad)));
            if (variable_struct_exists(ov, "text_scale")) s.text_scale = max(0.1, real(ov.text_scale));
            if (variable_struct_exists(ov, "line_gap")) s.line_gap = max(0, round(real(ov.line_gap)));
            if (variable_struct_exists(ov, "frame_alpha_mult")) s.frame_alpha_mult = clamp(real(ov.frame_alpha_mult), 0, 1);
            if (variable_struct_exists(ov, "min_w")) s.min_w = max(12, round(real(ov.min_w)));
            if (variable_struct_exists(ov, "min_h")) s.min_h = max(12, round(real(ov.min_h)));
            if (variable_struct_exists(ov, "margin_px")) s.margin_px = max(0, round(real(ov.margin_px)));
            if (variable_struct_exists(ov, "width_ratio")) s.width_ratio = clamp(real(ov.width_ratio), 0.1, 0.95);
            if (variable_struct_exists(ov, "height_ratio")) s.height_ratio = clamp(real(ov.height_ratio), 0, 0.95);
        }
    }
    return s;
}

function Tooltip_ClampRect(_x, _y, _w, _h, _margin = 0, _min_w = 12, _min_h = 12) {
    var gui_w = max(1, Display_GuiW());
    var gui_h = max(1, Display_GuiH());
    var rect_margin = max(0, round(real(_margin)));
    var rect_min_w = max(12, round(real(_min_w)));
    var rect_min_h = max(12, round(real(_min_h)));
    var rect_w = clamp(round(real(_w)), rect_min_w, max(rect_min_w, gui_w - rect_margin * 2));
    var rect_h = clamp(round(real(_h)), rect_min_h, max(rect_min_h, gui_h - rect_margin * 2));
    var rect_x = clamp(round(real(_x)), rect_margin, max(rect_margin, gui_w - rect_margin - rect_w));
    var rect_y = clamp(round(real(_y)), rect_margin, max(rect_margin, gui_h - rect_margin - rect_h));
    return { x: rect_x, y: rect_y, w: rect_w, h: rect_h };
}

function Tooltip_DrawBox(_x, _y, _w, _h, _lines, _alpha = 1, _style = undefined) {
    if (!is_array(_lines) || array_length(_lines) <= 0) return;
    var style = is_struct(_style) ? _style : Tooltip_GetStyle("default");
    var rect = Tooltip_ClampRect(_x, _y, _w, _h, style.margin_px, style.min_w, style.min_h);
    var pad = style.pad;
    var text_scale = style.text_scale;
    var line_h = max(5, floor(UI_TextHeight("A") * text_scale) + style.line_gap);
    var max_text_w = max(1, floor((rect.w - pad * 2) / text_scale));
    var wrapped = Tooltip_WrapLines(_lines, max_text_w);

    var a = clamp(real(_alpha), 0, 1);
    draw_set_alpha(a * style.frame_alpha_mult);
    draw_set_color(c_black);
    draw_rectangle(rect.x, rect.y, rect.x + rect.w, rect.y + rect.h, false);
    draw_set_alpha(a);
    draw_set_color(c_white);
    draw_rectangle(rect.x, rect.y, rect.x + rect.w, rect.y + rect.h, true);

    var draw_y = rect.y + pad;
    for (var j = 0; j < array_length(wrapped); j++) {
        UI_DrawTextTransformed(rect.x + pad, draw_y, wrapped[j], text_scale, text_scale, 0);
        draw_y += line_h;
        if (draw_y > rect.y + rect.h - pad) break;
    }
}

function Tooltip_WrapLines(_lines, _max_text_w) {
    var wrapped = [];
    if (!is_array(_lines)) return wrapped;
    var w = max(1, floor(real(_max_text_w)));
    for (var i = 0; i < array_length(_lines); i++) {
        var line_txt = string(_lines[i]);
        if (line_txt == "") {
            array_push(wrapped, "");
            continue;
        }
        wrapped = Tooltip_AddWrappedLines(wrapped, line_txt, w);
    }
    return wrapped;
}

function Tooltip_RequiredHeight(_lines, _box_w, _style = undefined) {
    var style = is_struct(_style) ? _style : Tooltip_GetStyle("default");
    var box_w = max(style.min_w, round(real(_box_w)));
    var pad = style.pad;
    var text_scale = style.text_scale;
    var line_h = max(5, floor(UI_TextHeight("A") * text_scale) + style.line_gap);
    var max_text_w = max(1, floor((box_w - pad * 2) / text_scale));
    var wrapped = Tooltip_WrapLines(_lines, max_text_w);
    var line_count = max(1, array_length(wrapped));
    return (pad * 2) + (line_count * line_h);
}

// Backward-compat wrappers (call sites can migrate to Tooltip_* progressively).
function Menu_StatShortName(_stat_id) { return Tooltip_StatShortName(_stat_id); }
function Menu_TargetName(_target_id) { return Tooltip_TargetName(_target_id); }
function Menu_ClassListText(_class_list) { return Tooltip_ClassListText(_class_list); }
function Menu_StatusName(_status_id) { return Tooltip_StatusName(_status_id); }
function Menu_AddWrappedLines(_out_lines, _text, _max_w) { return Tooltip_AddWrappedLines(_out_lines, _text, _max_w); }
function Menu_ItemBonusText(_item) { return Tooltip_ItemBonusText(_item); }
function Menu_BuildItemTooltipLines(_item) { return Tooltip_BuildItemLines(_item); }
function Menu_BuildSkillTooltipLines(_skill) { return Tooltip_BuildSkillLines(_skill); }
function Menu_DrawTooltipBox(_bx, _by, _bw, _bh, _lines, _menu_alpha) { Tooltip_DrawBox(_bx, _by, _bw, _bh, _lines, _menu_alpha); }

function Menu_InventoryDisplayItems(_inventory) {
    var source = is_array(_inventory) ? _inventory : [];
    var out = [];

    for (var i = 0; i < array_length(source); i++) {
        var inv = source[i];
        if (!is_struct(inv) || !variable_struct_exists(inv, "id")) continue;

        array_push(out, inv);
    }

    return out;
}

function Menu_ClampInventoryCursor(_m, _inventory) {
    var items = Menu_InventoryDisplayItems(_inventory);
    var inv_count = array_length(items);
    if (inv_count <= 0) {
        _m.inv_index = 0;
        _m.inv_scroll = 0;
        return _m;
    }

    _m.inv_index = clamp(_m.inv_index, 0, inv_count - 1);
    if (_m.inv_index < _m.inv_scroll) _m.inv_scroll = _m.inv_index;

    var visible_rows = Menu_GetLayout().rows_visible;
    if (_m.inv_index >= _m.inv_scroll + visible_rows) {
        _m.inv_scroll = _m.inv_index - visible_rows + 1;
    }

    _m.inv_scroll = clamp(_m.inv_scroll, 0, max(0, inv_count - visible_rows));
    return _m;
}

function Menu_UseInventoryItem(_m, _ch, _item_id) {
    var item = ItemDB_Get(_item_id);
    var out = { menu: _m, ch: _ch, changed: false };

    if (!is_struct(item) || item.id == 0) {
        out.menu = Menu_InvPopupOpenMessage(_m, Loc_T("item.msg.cant_use", "Can't use that."));
        return out;
    }

    if (item.type == ITEM_WEAPON || item.type == ITEM_ARMOR) {
        var slot_name = variable_struct_exists(item, "equip_slot") ? string(item.equip_slot) : "";
        if (slot_name != "" && Equip_SlotGet(_ch, slot_name) == item.id) {
            Equip_SlotSet(_ch, slot_name, 0);
            _ch = RecomputeResources(_ch);
            _m = Menu_ClampInventoryCursor(_m, _ch.inventory);
            out.menu = Menu_InvPopupOpenMessage(_m, Loc_T("menu.msg.unequipped", "Unequipped {item}.", { item: item.name }));
            out.ch = _ch;
            out.changed = true;
            return out;
        }

        var can = Equip_CanEquip(_ch, item);
        if (!can.ok) {
            out.menu = Menu_InvPopupOpenMessage(_m, can.msg);
            return out;
        }

        if (Equip_Item(_ch, item.id)) {
            _ch = RecomputeResources(_ch);
            _m = Menu_ClampInventoryCursor(_m, _ch.inventory);
            out.menu = Menu_InvPopupOpenMessage(_m, Loc_T("menu.msg.equipped", "Equipped {item}.", { item: item.name }));
            out.ch = _ch;
            out.changed = true;
            return out;
        }

        out.menu = Menu_InvPopupOpenMessage(_m, Loc_T("menu.msg.cant_equip", "Can't equip that."));
        return out;
    }

    if (Item_IsConsumable(item)) {
        var target = _ch;
        var use_result = Item_Use(item.id, _ch, target);

        if (use_result.ok) {
            _ch.inventory = Inv_Remove(_ch.inventory, item.id, 1);
            _ch = RecomputeResources(_ch);
            _m = Menu_ClampInventoryCursor(_m, _ch.inventory);
            out.menu = Menu_InvPopupOpenMessage(_m, use_result.msg);
            out.ch = _ch;
            out.changed = true;
            return out;
        }

        out.menu = Menu_InvPopupOpenMessage(_m, use_result.msg);
        return out;
    }

    out.menu = Menu_InvPopupOpenMessage(_m, Loc_T("item.msg.cant_use", "Can't use that."));
    return out;
}

function Menu_InvPopupOpenConfirm(_m, _item_id) {
    _m.inv_popup_open = true;
    _m.inv_popup_closing = false;
    _m.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
    _m.inv_popup_mode = "confirm";
    _m.inv_popup_choice = 1; // default to Cancel
    _m.inv_popup_message = Loc_T("menu.popup.learn_skill", "Learn a skill");
    _m.inv_popup_item_id = _item_id;
    _m.inv_popup_block_frame = Input_Frame() + 1;
    _m.inv_popup_open_frame = Input_Frame();
    return _m;
}

function Menu_InvPopupOpenMessage(_m, _msg) {
    _m.inv_popup_open = true;
    _m.inv_popup_closing = false;
    _m.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
    _m.inv_popup_mode = "message";
    _m.inv_popup_choice = 0;
    _m.inv_popup_message = _msg;
    _m.inv_popup_block_frame = Input_Frame() + 1;
    _m.inv_popup_open_frame = Input_Frame();
    return _m;
}

function Menu_StatsSync() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    var ch = gs.player_ch;
    Menu_Ensure();
    if (!variable_struct_exists(ch, "stat_points")) ch.stat_points = 0;
    ch.stats = StatsClampAll(ch.stats);
    gs.ui.menu.base_stats = Menu_StatsCopy(ch.stats);
    gs.ui.menu.pending_stats = Menu_StatsCopy(ch.stats);
    gs.ui.menu.pending_points = ch.stat_points;
}

function Menu_StatsDiscard() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "menu")) return;
    var m = gs.ui.menu;
    if (!is_struct(gs.player_ch)) return;
    var ch = gs.player_ch;
    if (variable_struct_exists(m, "base_stats") && is_struct(m.base_stats)) {
        m.pending_stats = Menu_StatsCopy(m.base_stats);
        m.pending_points = ch.stat_points;
    }
}

function Menu_StatsApply() {
    var gs = GameState_Get();
    var m = gs.ui.menu;
    if (!is_struct(gs.player_ch)) return;
    var ch = gs.player_ch;
    if (!is_struct(m.pending_stats)) return;
    ch.stats = StatsClampAll(Menu_StatsCopy(m.pending_stats));
    ch.stat_points = m.pending_points;
    ch = RecomputeResources(ch);
    GameState_SetPlayer(ch);
    Menu_StatsSync();
}

function Menu_NavPressed(_action) {
    return Input_UIPressed(_action);
}

function Menu_HandleInput() {
    var gs = GameState_Get();
    var m = gs.ui.menu;
    var ch = gs.player_ch;
    var frame = Input_Frame();

    if (variable_struct_exists(m, "closing") && m.closing) {
        if (frame - m.close_frame >= UI_POPUP_FADE_FRAMES) {
            Menu_CloseFinalize();
        } else {
            gs.ui.menu = m;
        }
        return;
    }

    var nav_up = Menu_NavPressed("menu_up");
    var nav_down = Menu_NavPressed("menu_down");
    var k_left = Input_UIPressed("menu_left");
    var k_right = Input_UIPressed("menu_right");
    var k_ok = Input_UIConfirm();
    var k_back = Input_UIBack();

    if (variable_struct_exists(m, "inv_popup_open") && m.inv_popup_open) {
        if (variable_struct_exists(m, "inv_popup_closing") && m.inv_popup_closing) {
            if (frame - m.inv_popup_close_frame >= UI_POPUP_FADE_FRAMES) {
                m = Menu_InvPopupClose(m, true);
            }
            gs.ui.menu = m;
            return;
        }
        if (m.inv_popup_block_frame != UI_OPENED_FRAME_NONE && frame <= m.inv_popup_block_frame) {
            gs.ui.menu = m;
            return;
        }

        if (m.inv_popup_mode == "confirm") {
            if (k_left || k_right) {
                m.inv_popup_choice = 1 - m.inv_popup_choice;
                SFX_PlayUI("ui_move");
            }

            if (k_back) {
                SFX_PlayUI("ui_back");
                m = Menu_InvPopupClose(m);
                gs.ui.menu = m;
                return;
            }

            if (k_ok) {
                SFX_PlayUI("ui_confirm");
                if (m.inv_popup_choice == 0) {
                    var use_result = Item_Use(m.inv_popup_item_id, ch, ch);
                    if (use_result.ok) {
                        ch.inventory = Inv_Remove(ch.inventory, m.inv_popup_item_id, 1);
                        ch = RecomputeResources(ch);
                        GameState_SetPlayer(ch);
                        m = Menu_ClampInventoryCursor(m, ch.inventory);

                    }
                    m = Menu_InvPopupOpenMessage(m, use_result.msg);
                } else {
                    m = Menu_InvPopupClose(m);
                }
            }

            gs.ui.menu = m;
            return;
        }

        if (m.inv_popup_mode == "message") {
            if (k_ok || k_back) {
                if (k_ok) SFX_PlayUI("ui_confirm"); else SFX_PlayUI("ui_back");
                m = Menu_InvPopupClose(m);
            }
            gs.ui.menu = m;
            return;
        }

        m = Menu_InvPopupClose(m);
        gs.ui.menu = m;
        return;
    }

    if (k_back) {
        SFX_PlayUI("ui_back");
        if (m.tab == 2 && m.stats_focus) {
            m.stats_focus = false;
            m.header_focus = true;
            return;
        }
        Menu_Close();
        return;
    }

    if (m.header_focus) {
        if (k_left) {
            m.tab = (m.tab + array_length(m.tabs) - 1) mod array_length(m.tabs);
            if (m.tab == 2) Menu_StatsSync();
            SFX_PlayUI("ui_move");
        }
        if (k_right) {
            m.tab = (m.tab + 1) mod array_length(m.tabs);
            if (m.tab == 2) Menu_StatsSync();
            SFX_PlayUI("ui_move");
        }
        if (nav_down) {
            var can_enter_tab = false;
            switch (m.tab) {
                case 0:
                    can_enter_tab = is_array(ch.inventory) && array_length(ch.inventory) > 0;
                    break;
                case 1:
                    can_enter_tab = is_array(ch.skills) && array_length(ch.skills) > 0;
                    break;
                case 2:
                    can_enter_tab = true;
                    break;
            }

            if (can_enter_tab) {
                m.header_focus = false;
                if (m.tab == 2) {
                    if (!is_struct(m.pending_stats)) Menu_StatsSync();
                    m.stats_focus = true;
                    m.stats_row = 0;
                }
                SFX_PlayUI("ui_move");
            }
        }
        return;
    }

    var layout = Menu_GetLayout();
    var rows_visible = layout.rows_visible;

    if (m.tab == 0) {
        var items = Menu_InventoryDisplayItems(ch.inventory);
        var count = array_length(items);
        if (count <= 0) {
            m.header_focus = true;
            m.inv_index = 0;
            m.inv_scroll = 0;
            if (nav_up) {
                SFX_PlayUI("ui_move");
            }
            return;
        }
        if (nav_up) {
            if (m.inv_index > 0) {
                m.inv_index -= 1;
                SFX_PlayUI("ui_move");
            } else {
                m.header_focus = true;
                SFX_PlayUI("ui_move");
                return;
            }
        }
        if (nav_down) {
            if (m.inv_index < count - 1) {
                m.inv_index += 1;
                SFX_PlayUI("ui_move");
            }
        }

        if (m.inv_index < m.inv_scroll) m.inv_scroll = m.inv_index;
        if (m.inv_index >= m.inv_scroll + rows_visible) m.inv_scroll = m.inv_index - rows_visible + 1;

        if (k_ok) {
            var selected_item_id = -1;
            if (m.inv_index >= 0 && m.inv_index < count && is_struct(items[m.inv_index]) && variable_struct_exists(items[m.inv_index], "id")) {
                selected_item_id = items[m.inv_index].id;
            }

            SFX_PlayUI("ui_confirm");
            if (selected_item_id != -1) {
                var use_out = Menu_UseInventoryItem(m, ch, selected_item_id);
                m = use_out.menu;
                ch = use_out.ch;
                if (use_out.changed) {
                    GameState_SetPlayer(ch);
                }
            } else {
                m = Menu_InvPopupOpenMessage(m, Loc_T("item.msg.cant_use", "Can't use that."));
            }
            gs.ui.menu = m;
            return;
        }
    }

    if (m.tab == 1) {
        var skills = is_array(ch.skills) ? ch.skills : [];
        var scount = array_length(skills);
        if (scount <= 0) {
            m.header_focus = true;
            m.skill_index = 0;
            m.skill_scroll = 0;
            if (nav_up) {
                SFX_PlayUI("ui_move");
            }
            return;
        }
        if (nav_up) {
            if (m.skill_index > 0) {
                m.skill_index -= 1;
                SFX_PlayUI("ui_move");
            } else {
                m.header_focus = true;
                SFX_PlayUI("ui_move");
                return;
            }
        }
        if (nav_down) {
            if (m.skill_index < scount - 1) {
                m.skill_index += 1;
                SFX_PlayUI("ui_move");
            }
        }

        if (m.skill_index < m.skill_scroll) m.skill_scroll = m.skill_index;
        if (m.skill_index >= m.skill_scroll + rows_visible) m.skill_scroll = m.skill_index - rows_visible + 1;
    }

    if (m.tab == 2) {
        // Read-only stats: navigate the rows like the skills list (no editing).
        if (!is_struct(m.pending_stats)) Menu_StatsSync();
        var stat_rows = 5;
        m.stats_row = clamp(m.stats_row, 0, stat_rows - 1);
        if (nav_up) {
            if (m.stats_row > 0) {
                m.stats_row -= 1;
                SFX_PlayUI("ui_move");
            } else {
                m.stats_focus = false;
                m.header_focus = true;
                SFX_PlayUI("ui_move");
                return;
            }
        }
        if (nav_down) {
            if (m.stats_row < stat_rows - 1) {
                m.stats_row += 1;
                SFX_PlayUI("ui_move");
            }
        }
    }
}


function Menu_Draw() {
    var gs = GameState_Get();
    var m = gs.ui.menu;
    var ch = gs.player_ch;

    UI_SetFont();

    var layout = Menu_GetLayout();
    var w = layout.w;
    var h = layout.h;
    var bx = layout.bx;
    var by = layout.by;
    var bw = layout.bw;
    var bh = layout.bh;
    var main_h = layout.main_h;
    var header_h = layout.header_h;
    var pad = layout.pad;
    var row_h = layout.row_h;
    var rows_visible = layout.rows_visible;
    var content_list_y = layout.content_list_y;
    var content_list_h = layout.content_list_h;
    var list_top_inset = layout.list_top_inset;
    var list_bottom_inset = layout.list_bottom_inset;
    var menu_tip_h = layout.tooltip_h;
    var menu_tip_y = layout.tooltip_y;
    var menu_closing = variable_struct_exists(m, "closing") && m.closing;
    var menu_close_frame = variable_struct_exists(m, "close_frame") ? m.close_frame : UI_OPENED_FRAME_NONE;
    var menu_alpha = UI_PopupAlpha(m.opened_frame, menu_closing, menu_close_frame, 1);
    var ui_visual = UI_GetVisualScale();
    var ui_sprite = UI_GetSpriteScale();
    var tooltip_lines = [];

    // Top main menu box (cropped to leave room for bottom tooltip box).
    draw_set_alpha(menu_alpha * 0.9);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + main_h, false);
    draw_set_alpha(menu_alpha);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + main_h, true);
    draw_set_alpha(menu_alpha);

    // tabs
    var tab_w = bw / array_length(m.tabs);
    for (var i = 0; i < array_length(m.tabs); i++) {
        var tx = bx + i * tab_w;
        var tab_active = (i == m.tab);
        var tab_hi = tab_active && m.header_focus;
        var tab_label = m.tabs[i];
        if (i == 0) tab_label = Loc_T("menu.tab.inventory", tab_label);
        else if (i == 1) tab_label = Loc_T("menu.tab.skills", tab_label);
        else if (i == 2) tab_label = Loc_T("menu.tab.stats", tab_label);
        if (tab_hi) {
            draw_set_color(c_white);
            draw_rectangle(tx, by, tx + tab_w, by + header_h, false);
            draw_set_color(c_black);
            draw_rectangle(tx, by, tx + tab_w, by + header_h, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        var tab_pad = max(4, round(6 * ui_visual));
        UI_DrawText(tx + tab_pad, by + tab_pad, tab_label);
    }

    var draw_arrow_sprite = dialogue_arrow_down;
    var draw_arrow_w = max(1, sprite_get_width(draw_arrow_sprite));
    var draw_arrow_h = max(1, sprite_get_height(draw_arrow_sprite));
    var draw_arrow_size = max(10, round(16 * ui_visual));
    var draw_arrow_scale = max(1, round(draw_arrow_size / max(draw_arrow_w, draw_arrow_h)));
    var draw_arrow_draw_w = draw_arrow_w * draw_arrow_scale;
    var draw_arrow_draw_h = draw_arrow_h * draw_arrow_scale;
    var draw_arrow_x = round(bx + bw * 0.5 - (draw_arrow_draw_w * 0.5));
    var draw_arrow_top_y = round(layout.content_y + max(0, floor((list_top_inset - draw_arrow_draw_h) * 0.5)));
    var draw_arrow_bottom_y = round(content_list_y + content_list_h + max(0, floor((list_bottom_inset - draw_arrow_draw_h) * 0.5)));

    // Inventory tab
    if (m.tab == 0) {
        var items = Menu_InventoryDisplayItems(ch.inventory);
        var count = array_length(items);
        var start = clamp(m.inv_scroll, 0, max(0, count - rows_visible));
        var endv = min(count, start + rows_visible);

        if (count == 0) {
            draw_set_color(c_white);
            UI_DrawText(bx + pad, content_list_y, Loc_T("menu.msg.no_items", "No items."));
        } else {
            for (var i2 = start; i2 < endv; i2++) {
                var row = i2 - start;
                var yy = content_list_y + row * row_h;

                var sel = (i2 == m.inv_index) && !m.header_focus;
                if (sel) {
                    draw_set_color(c_white);
                    draw_rectangle(bx + pad - 4, yy - 2, bx + bw - pad + 4, yy + row_h - 2, false);
                    draw_set_color(c_black);
                    draw_rectangle(bx + pad - 4, yy - 2, bx + bw - pad + 4, yy + row_h - 2, true);
                }

                var inv = items[i2];
                var item = ItemDB_Get(inv.id);
                var tx = bx + pad;
                if (item.sprite != noone) {
                    var icon_scale = ui_sprite;
                    draw_sprite_ext(item.sprite, 0, tx, yy + max(1, round(2 * ui_visual)), icon_scale, icon_scale, 0, c_white, 1);
                    tx += max(round(16 * icon_scale), round(sprite_get_width(item.sprite) * icon_scale));
                }
                var label = item.name;
                if (item.stackable) {
                    label += Loc_T("menu.label.stack_suffix", " x{qty}", { qty: string(inv.qty) });
                }
                draw_set_color(sel ? c_black : c_white);
                UI_DrawText(tx, yy, label);

                if (Menu_IsEquipped(ch, inv.id)) {
                    draw_set_color(sel ? c_black : c_white);
                    UI_DrawText(bx + bw - pad - UI_TextWidth(Loc_T("menu.label.equipped_short", "E")), yy, Loc_T("menu.label.equipped_short", "E"));
                }
            }
        }

        if (!m.header_focus && count > 0 && m.inv_index >= 0 && m.inv_index < count && is_struct(items[m.inv_index])) {
            var sel_inv = items[m.inv_index];
            var sel_item = ItemDB_Get(sel_inv.id);
            tooltip_lines = Tooltip_BuildItemLines(sel_item);
        }

        if (count > rows_visible) {
            draw_set_color(c_white);
            if (start > 0) {
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_top_y + draw_arrow_draw_h, draw_arrow_scale, -draw_arrow_scale, 0, c_white, menu_alpha);
            }
            if (endv < count) {
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_bottom_y, draw_arrow_scale, draw_arrow_scale, 0, c_white, menu_alpha);
            }
        }
    }

    // Skills tab
    if (m.tab == 1) {
        var skills = is_array(ch.skills) ? ch.skills : [];
        var scount = array_length(skills);
        var start2 = clamp(m.skill_scroll, 0, max(0, scount - rows_visible));
        var end2 = min(scount, start2 + rows_visible);

        if (scount == 0) {
            draw_set_color(c_white);
            UI_DrawText(bx + pad, content_list_y, Loc_T("menu.msg.no_skills", "No skills."));
        } else {
            for (var s = start2; s < end2; s++) {
                var row2 = s - start2;
                var y2 = content_list_y + row2 * row_h;

                var sel2 = (s == m.skill_index) && !m.header_focus;
                if (sel2) {
                    draw_set_color(c_white);
                    draw_rectangle(bx + pad - 4, y2 - 2, bx + bw - pad + 4, y2 + row_h - 2, false);
                    draw_set_color(c_black);
                    draw_rectangle(bx + pad - 4, y2 - 2, bx + bw - pad + 4, y2 + row_h - 2, true);
                }

                var sk = SkillDB_Get(skills[s]);
                var tx2 = bx + pad;
                if (sk.icon_sprite != noone) {
                    var icon_scale2 = ui_sprite;
                    draw_sprite_ext(sk.icon_sprite, 0, tx2, y2 + max(1, round(2 * ui_visual)), icon_scale2, icon_scale2, 0, c_white, 1);
                    tx2 += max(round(16 * icon_scale2), round(sprite_get_width(sk.icon_sprite) * icon_scale2));
                }
                draw_set_color(sel2 ? c_black : c_white);
                UI_DrawText(tx2, y2, sk.name);
            }
        }

        if (!m.header_focus && scount > 0 && m.skill_index >= 0 && m.skill_index < scount) {
            var sel_skill = SkillDB_Get(skills[m.skill_index]);
            tooltip_lines = Tooltip_BuildSkillLines(sel_skill);
        }

        if (scount > rows_visible) {
            draw_set_color(c_white);
            if (start2 > 0) {
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_top_y + draw_arrow_draw_h, draw_arrow_scale, -draw_arrow_scale, 0, c_white, menu_alpha);
            }
            if (end2 < scount) {
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_bottom_y, draw_arrow_scale, draw_arrow_scale, 0, c_white, menu_alpha);
            }
        }
    }

    // Stats tab (main layout)
    if (m.tab == 2) {
        if (!is_struct(m.pending_stats)) Menu_StatsSync();

        var stat_names = [
            Loc_T("status.name.stat.atk", "ATK"),
            Loc_T("status.name.stat.def", "DEF"),
            Loc_T("status.name.stat.spd", "SPD"),
            Loc_T("status.name.stat.mag", "MAG")
        ];
        var stat_keys = ["atk","def","spd","mag"];
        var stat_count = array_length(stat_keys);

        var left_x = bx + pad;
        var y0 = by + header_h + pad;

        var hp_bar_sprite = hp_bar;
        var mp_bar_sprite = mp_bar;
        var max_frame = min(10, sprite_get_number(hp_bar_sprite) - 1);
        if (max_frame < 0) max_frame = 0;

        var hp_ratio = (ch.max_hp > 0) ? clamp(ch.hp / ch.max_hp, 0, 1) : 0;
        var mp_ratio = (ch.max_mp > 0) ? clamp(ch.mp / ch.max_mp, 0, 1) : 0;
        var hp_frame = clamp(floor(hp_ratio * max_frame), 0, max_frame);
        var mp_frame = clamp(floor(mp_ratio * max_frame), 0, max_frame);

        var bar_scale = UI_BAR_SCALE * ui_sprite;
        var bar_w = sprite_get_width(hp_bar_sprite) * bar_scale;
        var hp_bar_h = sprite_get_height(hp_bar_sprite) * bar_scale;
        var mp_bar_h = sprite_get_height(mp_bar_sprite) * bar_scale;

        var level_capped = Level_IsAtCap(ch.level);
        var exp_label_1 = level_capped ? Loc_T("menu.stats.level_cap", "Level Cap") : Loc_T("menu.stats.required_exp", "Required EXP");
        var exp_value = level_capped ? Loc_T("menu.stats.max", "MAX") : (string(ch.exp) + "/" + string(ch.exp_next));
        var line_h = UI_TextHeight("A") + 2;

        // The HP / MP numbers sit to the right of their bars, so the left block is as wide as the bar plus the wider number
        // (before this the stat list started under "10 / 10" and the two overlapped).
        var stat_text_gap = max(4, round(6 * ui_visual));
        var hp_text = string(ch.hp) + " / " + string(ch.max_hp);
        var mp_text = string(ch.mp) + " / " + string(ch.max_mp);
        var bars_w = bar_w + stat_text_gap + max(UI_TextWidth(hp_text), UI_TextWidth(mp_text));
        var left_content_w = max(
            bars_w,
            UI_TextWidth(Loc_T("menu.stats.level", "Level: {level}", { level: string(ch.level) })),
            UI_TextWidth(exp_label_1),
            UI_TextWidth(exp_value)
        ) + pad * 2;
        var left_w = min(bw * 0.7, left_content_w);

        var right_x = bx + left_w + pad;
        var right_w = (bx + bw - pad) - right_x;

        draw_sprite_ext(hp_bar_sprite, hp_frame, left_x, y0, bar_scale, bar_scale, 0, c_white, menu_alpha);
        draw_sprite_ext(mp_bar_sprite, mp_frame, left_x, y0 + hp_bar_h + pad, bar_scale, bar_scale, 0, c_white, menu_alpha);

        draw_set_color(c_white);
        UI_DrawText(left_x + bar_w + stat_text_gap, y0, hp_text);
        UI_DrawText(left_x + bar_w + stat_text_gap, y0 + hp_bar_h + pad, mp_text);

        draw_set_color(c_white);
        var text_y = y0 + hp_bar_h + mp_bar_h + pad * 2;
        UI_DrawText(left_x, text_y, Loc_T("menu.stats.level", "Level: {level}", { level: string(ch.level) }));
        text_y += line_h;
        UI_DrawText(left_x, text_y, exp_label_1);
        text_y += line_h;
        UI_DrawText(left_x, text_y, exp_value);

        var row_h2 = row_h;
        var list_y = y0;
        var label_x = right_x;

        // Read-only stat list (growth is class-driven; no manual allocation).
        // Selectable for viewing, like the skills list.
        for (var i3 = 0; i3 < stat_count; i3++) {
            var row_y = list_y + i3 * row_h2;
            var val = variable_struct_get(m.pending_stats, stat_keys[i3]);
            var row_txt = stat_names[i3] + ": " + string(val);
            var row_sel = (m.stats_focus && m.stats_row == i3);
            if (row_sel) {
                var rtw = UI_TextWidth(row_txt);
                draw_set_color(c_white);
                draw_rectangle(label_x - 4, row_y - 2, label_x + rtw + 4, row_y + row_h2 - 2, false);
                draw_set_color(c_black);
                draw_rectangle(label_x - 4, row_y - 2, label_x + rtw + 4, row_y + row_h2 - 2, true);
            }
            draw_set_color(row_sel ? c_black : c_white);
            UI_DrawText(label_x, row_y, row_txt);

            if (row_sel) {
                tooltip_lines = Tooltip_BuildStatLines(stat_keys[i3], stat_names[i3], val);
            }
        }
    }

    if (!(variable_struct_exists(m, "inv_popup_open") && m.inv_popup_open) && array_length(tooltip_lines) > 0) {
        var tip_style = Tooltip_GetStyle("menu");
        var tip_w = bw;
        var tip_x = bx;
        var tip_y = menu_tip_y;
        var tip_margin = max(tip_style.margin_px, max(2, floor(pad * 0.5)));
        var tip_h_needed = Tooltip_RequiredHeight(tooltip_lines, tip_w, tip_style);
        var tip_bottom_limit = by + bh - tip_margin;
        var tip_h_max = max(tip_style.min_h, tip_bottom_limit - tip_y);
        var tip_h = clamp(max(menu_tip_h, tip_h_needed), tip_style.min_h, tip_h_max);
        var tip_rect = Tooltip_ClampRect(tip_x, tip_y, tip_w, tip_h, tip_margin, tip_style.min_w, tip_style.min_h);
        Tooltip_DrawBox(tip_rect.x, tip_rect.y, tip_rect.w, tip_rect.h, tooltip_lines, menu_alpha, tip_style);
    }

    if (variable_struct_exists(m, "inv_popup_open") && m.inv_popup_open) {
        var inv_closing = variable_struct_exists(m, "inv_popup_closing") && m.inv_popup_closing;
        var inv_close_frame = variable_struct_exists(m, "inv_popup_close_frame") ? m.inv_popup_close_frame : UI_OPENED_FRAME_NONE;
        var popup_alpha = UI_PopupAlpha(m.inv_popup_open_frame, inv_closing, inv_close_frame, 1);
        var popup_msg = Loc_T("menu.popup.learn_skill", "Learn a skill");
        if (m.inv_popup_mode == "message") popup_msg = string(m.inv_popup_message);

        var pm = UI_PopupMetrics();
        var popup_pad_x = pm.pad_x;
        var popup_pad_y = pm.pad_y;
        var popup_gap_y = pm.gap_y;
        var btn_pad_x = pm.btn_pad_x;
        var line_h_popup = pm.line_h;
        var btn_h = pm.btn_h;
        var msg_w = UI_TextWidth(popup_msg);
        var popup_w = 0;
        var popup_h = 0;
        var px1 = 0;
        var py1 = 0;
        var px2 = 0;
        var py2 = 0;

        if (m.inv_popup_mode == "confirm") {
            var yes_label = Loc_T("menu.common.confirm", "Confirm");
            var no_label = Loc_T("menu.common.cancel", "Cancel");
            var yes_w = UI_ButtonWidth(yes_label, btn_pad_x);
            var no_w = UI_ButtonWidth(no_label, btn_pad_x);
            var btn_gap_x = pm.btn_gap_x;
            var total_btn_w = yes_w + btn_gap_x + no_w;

            popup_w = max(pm.min_w, max(msg_w + popup_pad_x * 2, total_btn_w + popup_pad_x * 2));
            popup_h = popup_pad_y + line_h_popup + popup_gap_y + btn_h + popup_pad_y;
            px1 = bx + (bw - popup_w) * 0.5;
            py1 = by + (bh - popup_h) * 0.62;
            px2 = px1 + popup_w;
            py2 = py1 + popup_h;

            draw_set_alpha(popup_alpha * 0.85);
            draw_set_color(c_black);
            draw_rectangle(px1, py1, px2, py2, false);
            draw_set_alpha(popup_alpha);
            draw_set_color(c_white);
            draw_rectangle(px1, py1, px2, py2, true);

            var msg_x = px1 + (popup_w - msg_w) * 0.5;
            var msg_y = py1 + popup_pad_y;
            draw_set_alpha(popup_alpha);
            draw_set_color(c_white);
            UI_DrawText(msg_x, msg_y, popup_msg);

            var btn_y = msg_y + line_h_popup + popup_gap_y;
            var yes_x = px1 + (popup_w - total_btn_w) * 0.5;
            var no_x = yes_x + yes_w + btn_gap_x;
            UI_DrawButton(yes_x, btn_y, yes_w, btn_h, yes_label, (m.inv_popup_choice == 0), popup_alpha);
            UI_DrawButton(no_x, btn_y, no_w, btn_h, no_label, (m.inv_popup_choice == 1), popup_alpha);
        } else {
            var ok_label = Loc_T("common.ok", "OK");
            var ok_w = UI_ButtonWidth(ok_label, btn_pad_x);
            popup_w = max(pm.min_w, max(msg_w + popup_pad_x * 2, ok_w + popup_pad_x * 2));
            popup_h = popup_pad_y + line_h_popup + popup_gap_y + btn_h + popup_pad_y;
            px1 = bx + (bw - popup_w) * 0.5;
            py1 = by + (bh - popup_h) * 0.62;
            px2 = px1 + popup_w;
            py2 = py1 + popup_h;

            draw_set_alpha(popup_alpha * 0.85);
            draw_set_color(c_black);
            draw_rectangle(px1, py1, px2, py2, false);
            draw_set_alpha(popup_alpha);
            draw_set_color(c_white);
            draw_rectangle(px1, py1, px2, py2, true);

            var msg_x2 = px1 + (popup_w - msg_w) * 0.5;
            var msg_y2 = py1 + popup_pad_y;
            draw_set_alpha(popup_alpha);
            draw_set_color(c_white);
            UI_DrawText(msg_x2, msg_y2, popup_msg);

            var btn_y2 = msg_y2 + line_h_popup + popup_gap_y;
            var ok_x = px1 + (popup_w - ok_w) * 0.5;
            UI_DrawButton(ok_x, btn_y2, ok_w, btn_h, ok_label, true, popup_alpha);
        }
    }

    draw_set_alpha(1);
}

// ==========================================================================================================================
// C2: the card screens, on the shared UI framework (D0, D95-D100): class choice (D73, D83), free stat point (D76), 1-of-3 card pick (D81),
// replace a skill (D82). What a character owes is kept on the character (Cards_NextOwed, scr_levelup), so a save, a reload or an interrupted
// screen loses nothing; CardsUi_Step (obj_ui_controller Step) opens the next owed screen when nothing else is on screen.
// global.cards_ui = { kind, stk, pick, opened_frame, opened_ms } while a screen is open, with gs.ui.mode = UI_CARDS. Class, stat and replace
// are Ui menus on a Ui stack (list + details panel); the pick is three cards side by side, drawn with the same frame and text kit.
// ==========================================================================================================================
#macro CARDS_UI_INPUT_DELAY_FRAMES 10   // keys are ignored this long after a screen opens (the press that opened it must not answer it)

function CardsUi_IsOpen() {
    return variable_global_exists("cards_ui") && is_struct(global.cards_ui);
}

function CardsUi_Kind() {
    return CardsUi_IsOpen() ? global.cards_ui.kind : "";
}

function CardsUi_Close() {
    var gs = GameState_Get();
    global.cards_ui = undefined;
    if (variable_struct_exists(gs, "ui") && gs.ui.mode == UI_CARDS) gs.ui.mode = UI_NONE;
}

// A room change or a battle closes whatever is open; what is owed stays owed and opens again.
function CardsUi_Interrupt() {
    if (CardsUi_IsOpen()) CardsUi_Close();
}

// A changed copy of the character becomes the player (the world object keeps pointing at the live one).
function CardsUi_Commit(_ch) {
    GameState_SetPlayer(_ch);
    if (instance_exists(obj_player)) obj_player.character = global.player_ch;
    GameState_SyncLegacy();
}

// Opens the next owed screen when nothing else is going on. Returns true when a screen is open this frame (the caller stops there).
function CardsUi_Step() {
    var gs = GameState_Get();
    if (CardsUi_IsOpen()) {
        CardsUi_HandleInput();
        return CardsUi_IsOpen();
    }
    if (!Run_IsActive()) return false;
    if (Transition_IsActive() || Transition_IsInputLocked()) return false;
    if (gs.ui.mode != UI_NONE || array_length(gs.ui.lines) > 0) return false;
    if (room == rm_battle || room == rm_start || room == rm_cutscene) return false;
    if (!is_struct(gs.player_ch)) return false;
    if (instance_exists(gs.player_inst) && !Player_IsSettled(gs.player_inst)) return false;
    var owed = Cards_NextOwed(gs.player_ch);
    if (owed == "") return false;
    CardsUi_Open(owed);
    return CardsUi_IsOpen();
}

function CardsUi_Open(_kind) {
    var gs = GameState_Get();
    var u = { kind: _kind, stk: Ui_StackNew(), pick: undefined, opened_frame: Input_Frame(), opened_ms: current_time };
    switch (_kind) {
        case "class": Ui_StackPush(u.stk, CardsUi_ClassMenu()); break;
        case "stat": Ui_StackPush(u.stk, CardsUi_StatMenu()); break;
        case "replace": Ui_StackPush(u.stk, CardsUi_ReplaceMenu()); break;
        case "cards": u.pick = CardsUi_PickNew(); break;
        default: return false;
    }
    global.cards_ui = u;
    gs.ui.mode = UI_CARDS;
    SFX_PlayUI("ui_openclose");
    if (_kind == "cards") Tutorial_Trigger("cards");   // D45
    return true;
}

function CardsUi_HandleInput() {
    var u = global.cards_ui;
    if (Input_Frame() - u.opened_frame < CARDS_UI_INPUT_DELAY_FRAMES) return;
    if (u.kind == "cards") {
        CardsUi_PickUpdate(u);
    } else {
        var top = Ui_StackTop(u.stk);
        if (is_struct(top)) Ui_MenuUpdate(top, u.stk);
    }
}

// Back does nothing on a screen that must be answered.
function CardsUi_NoBack(_m, _res) {
}

// ---- class choice -------------------------------------------------------------------------------------------------------------
function CardsUi_ClassMenu() {
    var choices = Card_ClassChoices();
    var items = [];
    for (var i = 0; i < array_length(choices); i++) {
        var cid = choices[i].class_id;
        var cfg = DB_PlayerClass(cid);
        var lines = [
            { label: Stat_ShortName(STAT_ATK), value: string(cfg.stats.atk) },
            { label: Stat_ShortName(STAT_DEF), value: string(cfg.stats.def) },
            { label: Stat_ShortName(STAT_SPD), value: string(cfg.stats.spd) },
            { label: Stat_ShortName(STAT_MAG), value: string(cfg.stats.mag) },
            { label: Loc_T("card.lbl.skills", "Skills"), value: (cid == CLASS_NOBODY) ? Loc_T("class.lbl.none", "None") : Loc_T("class.lbl.five", "5 to find") }
        ];
        array_push(items, {
            label: cfg.name, value: choices[i].locked ? Loc_T("class.nobody.locked", "Locked") : "",
            help: choices[i].locked ? choices[i].hint : Card_ClassSentence(cid), lines: lines, class_id: cid, locked: choices[i].locked
        });
    }
    var m = Ui_MenuNew("cards_class", items, {
        on_confirm: CardsUi_ClassConfirm, on_back: CardsUi_NoBack,
        layout: { title: Loc_T("class.select.title", "Select Class"), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

function CardsUi_ClassConfirm(_m, _i) {
    var it = _m.items[_i];
    if (it.locked) {
        SFX_PlayUI("ui_back");
        return;
    }
    var yes = { label: Loc_T("menu.common.yes", "Yes"), yes: true, class_id: it.class_id };
    var no = { label: Loc_T("menu.common.no", "No"), yes: false, class_id: it.class_id };
    var sure = Ui_MenuNew("cards_class_sure", [yes, no], {
        on_confirm: CardsUi_ClassSure, on_back: CardsUi_NoBack,
        layout: { title: Loc_T("class.select.become", "Become {cls}?", { cls: it.label }), anchor: "center", center: true }
    });
    Ui_MenuFixCursor(sure, 1);   // No first, for safety
    Ui_StackPush(global.cards_ui.stk, sure);
}

function CardsUi_ClassSure(_m, _i) {
    var it = _m.items[_i];
    if (!it.yes) {
        Ui_StackBack(global.cards_ui.stk);
        return;
    }
    var cid = it.class_id;
    CardsUi_Close();
    // the black flash covers the swap of the character, as it did with the old popup
    var queued = Transition_RequestBlackFlash(TRANSITION_CLASS_SELECT_FADE_OUT_FRAMES, TRANSITION_CLASS_SELECT_FADE_IN_FRAMES, cid);
    if (!queued) ClassSelect_ApplyClass(cid);
}

// Makes the chosen class the player (called mid-flash by the transition, or at once when no flash could start).
function ClassSelect_ApplyClass(_class_id) {
    var gs = GameState_Get();
    var ch = Card_ClassCharacter(gs.player_ch, _class_id);

    // FUN-FIRST: grant and auto-equip class starter weapon (no duplicates).
    ch = Equip_GrantStarterWeapon(ch, _class_id, true);
    var hp0 = ch.hp;
    var mp0 = ch.mp;
    ch = Player_NormalizeProgression(ch, true);
    ch.hp = clamp(hp0, 1, ch.max_hp);
    ch.mp = clamp(mp0, 0, ch.max_mp);

    GameState_SetSelectedClass(_class_id);
    GameState_SetPlayer(ch);

    if (instance_exists(obj_player)) {
        with (obj_player) {
            character = global.player_ch;
            Player_ApplyClassSprites(global.selected_class);
            sprite_index = sprite[face];
            image_index = 0;
            mask_index = sprite[DOWN];
        }
    }

    GameState_SyncLegacy();
    Dialogue_TryStartClassChestReaction(_class_id);
}

// ---- free stat point (D76) ------------------------------------------------------------------------------------------------------
function CardsUi_StatHelp(_stat_id) {
    switch (_stat_id) {
        case STAT_ATK: return Loc_T("menu.tooltip.stat.atk.desc", "Increases physical damage (basic attacks and ATK skills).");
        case STAT_DEF: return Loc_T("menu.tooltip.stat.def.desc", "Reduces all damage you take.");
        case STAT_SPD: return Loc_T("menu.tooltip.stat.spd.desc", "Decides who acts first.");
        case STAT_MAG: return Loc_T("menu.tooltip.stat.mag.desc", "Increases spell damage and max MP.");
    }
    return "";
}

function CardsUi_StatMenu() {
    var ch = GameState_Get().player_ch;
    var opts = Cards_StatOptions(ch);
    var items = [];
    for (var i = 0; i < array_length(opts); i++) {
        var o = opts[i];
        array_push(items, {
            label: o.label, value: string(o.from) + " > " + string(o.to), help: CardsUi_StatHelp(o.stat),
            lines: [ { label: Loc_T("cards.stat.now", "Now"), value: string(o.from) }, { label: Loc_T("cards.stat.after", "After"), value: string(o.to) } ],
            stat: o.stat
        });
    }
    var m = Ui_MenuNew("cards_stat", items, {
        on_confirm: CardsUi_StatConfirm, on_back: CardsUi_NoBack,
        layout: { title: Loc_T("cards.stat.title", "Level {lvl}: place 1 point", { lvl: string(ch.level) }), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, clamp(DB_PlayerClass(ch.class_id).free_default, 0, 3));   // the class's usual stat first
    return m;
}

function CardsUi_StatConfirm(_m, _i) {
    var gs = GameState_Get();
    CardsUi_Commit(Cards_PlaceStat(gs.player_ch, _m.items[_i].stat));
    CardsUi_Close();
}

// ---- replace a skill (D82) ------------------------------------------------------------------------------------------------------
function CardsUi_CompareLines(_old_id, _new_id) {
    var a = SkillDB_Get(_old_id);
    var b = SkillDB_GetBase(_new_id);
    var lines = [];
    if (a.effect == "damage" || b.effect == "damage") array_push(lines, Card_NumLine(Loc_T("card.lbl.power", "Power"), round(a.power), round(b.power)));
    array_push(lines, Card_NumLine(Loc_T("card.lbl.mp", "MP"), round(a.mp_cost), round(b.mp_cost)));
    array_push(lines, Card_NumLine(Loc_T("card.lbl.arrows", "Arrows"), array_length(Qte_SkillSequence(_old_id)), array_length(Qte_SkillSequenceBase(_new_id))));
    return lines;
}

function CardsUi_ReplaceMenu() {
    var ch = GameState_Get().player_ch;
    var new_id = ch.skill_pending;
    var items = [];
    for (var i = 0; i < array_length(ch.skills); i++) {
        var sk = SkillDB_Get(ch.skills[i]);
        array_push(items, { label: sk.name, value: Loc_T("card.mp_short", "{mp} MP", { mp: string(round(sk.mp_cost)) }), help: Loc_T("cards.replace.lose", "Gives up: {line}", { line: Card_SkillSentence(sk) }), lines: CardsUi_CompareLines(ch.skills[i], new_id), skill_id: ch.skills[i] });
    }
    array_push(items, { label: Loc_T("cards.replace.keep", "Keep my skills"), value: "", help: Loc_T("cards.replace.keep_help", "Go back to the cards and choose again."), lines: [], skill_id: -1 });
    var m = Ui_MenuNew("cards_replace", items, {
        on_confirm: CardsUi_ReplaceConfirm, on_back: CardsUi_ReplaceBack,
        layout: { title: Loc_T("cards.replace.title", "Learn {skill}: replace which?", { skill: SkillDB_GetBase(new_id).name }), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

function CardsUi_ReplaceConfirm(_m, _i) {
    var gs = GameState_Get();
    var ch = gs.player_ch;
    var old_id = _m.items[_i].skill_id;
    if (old_id < 0) {
        CardsUi_ReplaceBack(_m, "root");
        return;
    }
    var out = Card_ReplaceSkill(ch, old_id, ch.skill_pending);
    out = Cards_ConsumePick(out);
    CardsUi_Commit(out);
    CardsUi_Close();
}

// Keeping the skills puts the card back: the pick is still owed and the same offer comes up again.
function CardsUi_ReplaceBack(_m, _res) {
    var gs = GameState_Get();
    gs.player_ch.skill_pending = -1;
    CardsUi_Close();
}

// ---- the card pick (D81) --------------------------------------------------------------------------------------------------------
function CardsUi_PickNew() {
    var ch = GameState_Get().player_ch;
    if (!is_array(ch.offer) || array_length(ch.offer) != CARD_OFFER_SIZE) ch.offer = Card_OfferFromRun(ch).cards;
    return { ids: ch.offer, cursor: 0, last: 0, rects: [] };
}

function CardsUi_Take(_card_id) {
    var gs = GameState_Get();
    var r = Card_Take(gs.player_ch, _card_id);
    if (r.needs_replace) {
        // every slot is full: ask which skill goes; the pick stays owed until it is answered
        gs.player_ch.skill_pending = r.card.skill_id;
        CardsUi_Close();
        return;
    }
    var run = Run_Get();
    if (r.gold > 0 && is_struct(run)) run.gold += r.gold;
    CardsUi_Commit(Cards_ConsumePick(r.ch));
    CardsUi_Close();
}

function CardsUi_SkipPick() {
    var gs = GameState_Get();
    Card_SkipOffer();
    CardsUi_Commit(Cards_ConsumePick(gs.player_ch));
    CardsUi_Close();
}

function CardsUi_PickUpdate(_u) {
    var pk = _u.pick;
    var snap = Ui_ReadInput();
    var n = array_length(pk.ids);
    var dx = (snap.right_p ? 1 : 0) - (snap.left_p ? 1 : 0);
    var dy = (snap.down_p ? 1 : 0) - (snap.up_p ? 1 : 0);
    var hover = Ui_HoverIndex(pk.rects, snap.mx, snap.my);
    var cur = pk.cursor;
    if (snap.mouse_moved && hover >= 0) cur = hover;
    if (dx != 0 || dy != 0) cur = Cards_PickMove(cur, n, dx, dy, pk.last);
    if (cur != pk.cursor) {
        pk.cursor = cur;
        if (cur < n) pk.last = cur;
        SFX_PlayUI("ui_move");
    }
    var go = snap.confirm || (snap.click && hover == pk.cursor);
    if (go) {
        SFX_PlayUI("ui_confirm");
        if (pk.cursor < n) CardsUi_Take(pk.ids[pk.cursor]);
        else CardsUi_SkipPick();
    }
}

// ---- drawing -----------------------------------------------------------------------------------------------------------------
// The arrows of a skill or upgrade card, centred in a dark box, width _w. Returns the height used.
function CardsUi_DrawArrows(_x, _y, _w, _seq, _unit) {
    var n = array_length(_seq);
    if (n <= 0) return 0;
    var u = max(1, _unit);
    var cell = 11 * u;
    var h = 13 * u;
    var total = n * cell;
    Ui_Box(_x, _y, _x + _w, _y + h, UI_C_DARK);
    var x0 = _x + round((_w - total) / 2);
    for (var i = 0; i < n; i++) Qte_DrawArrowGlyph(x0 + i * cell + u, _y + 2 * u, _seq[i], u, UI_C_LIGHTEST, UI_C_DARKEST);
    return h;
}

// A number line whose label and value do not fit side by side: the value goes on the row below.
function CardsUi_LineStacked(_line, _iw, _mt) {
    return UI_TextWidth(_line.label) + 3 * _mt.p + UI_TextWidth(_line.value) > _iw;
}

function CardsUi_CardHeight(_c, _w, _mt) {
    var p = _mt.p;
    var iw = _w - 8 * p;
    var h = 8 * p;
    h += max(Ui_TextBlockH(Card_Name(_c), iw - 5 * p), _mt.line_h) + 2 * p;
    h += _mt.line_h + 3 * p;
    h += Ui_TextBlockH(Card_Sentence(_c), iw) + 2 * p;
    var seq = Card_Sequence(_c);
    if (array_length(seq) > 0) h += 13 * clamp(floor(iw / 60), 1, 3) + 2 * p;
    var lines = Card_Lines(_c);
    for (var i = 0; i < array_length(lines); i++) h += (CardsUi_LineStacked(lines[i], iw, _mt) ? 2 : 1) * (_mt.line_h + p);
    return h;
}

function CardsUi_DrawCard(_x, _y, _w, _h, _c, _sel, _a) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var iw = _w - 8 * p;
    if (_sel) {   // a bright halo outside the frame
        Ui_Box(_x + p, _y - p, _x + _w - p, _y, UI_C_LIGHT);
        Ui_Box(_x + p, _y + _h, _x + _w - p, _y + _h + p, UI_C_LIGHT);
        Ui_Box(_x - p, _y + p, _x, _y + _h - p, UI_C_LIGHT);
        Ui_Box(_x + _w, _y + p, _x + _w + p, _y + _h - p, UI_C_LIGHT);
    }
    Ui_DrawFrame(_x, _y, _w, _h, _a, p);
    var x0 = _x + 4 * p;
    var ty = _y + 4 * p;
    var name = Card_Name(_c);
    var nh = max(Ui_TextBlockH(name, iw - 5 * p), mt.line_h);
    if (_sel) {
        Ui_Box(_x + 3 * p, ty - p, _x + _w - 3 * p, ty + nh + p, UI_C_DARK);
        Ui_Arrow(x0 + Ui_Bob(current_time) * p, ty + (mt.line_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    }
    Ui_TextBlock(x0 + 5 * p, ty, name, iw - 5 * p, _sel ? UI_C_LIGHTEST : UI_C_LIGHT);
    ty += nh + 2 * p;
    Ui_Text(x0 + 5 * p, ty, Card_TypeTag(_c), UI_C_LIGHT);
    ty += mt.line_h + p;
    Ui_Box(_x + 3 * p, ty, _x + _w - 3 * p, ty + p, UI_C_DARK);
    ty += 2 * p;
    var sentence = Card_Sentence(_c);
    Ui_TextBlock(x0, ty, sentence, iw, UI_C_LIGHTEST);
    ty += Ui_TextBlockH(sentence, iw) + 2 * p;
    var seq = Card_Sequence(_c);
    if (array_length(seq) > 0) {
        var u = clamp(floor(iw / 60), 1, 3);
        ty += CardsUi_DrawArrows(x0, ty, iw, seq, u) + 2 * p;
    }
    var lines = Card_Lines(_c);
    for (var i = 0; i < array_length(lines); i++) {
        Ui_Text(x0, ty, lines[i].label, UI_C_LIGHT);
        if (CardsUi_LineStacked(lines[i], iw, mt)) ty += mt.line_h + p;
        Ui_Text(x0 + iw, ty, lines[i].value, UI_C_LIGHTEST, fa_right);
        ty += mt.line_h + p;
    }
}

function CardsUi_DrawPick(_u, _a) {
    var pk = _u.pick;
    var mt = Ui_Metrics();
    var p = mt.p;
    var n = array_length(pk.ids);
    var gap = 4 * p;
    var margin = mt.margin;
    var cw = floor((mt.gw - 2 * margin - (n - 1) * gap) / n);
    var cards = [];
    var ch_max = 0;
    for (var i = 0; i < n; i++) {
        var c = CardDB_Get(pk.ids[i]);
        array_push(cards, c);
        ch_max = max(ch_max, CardsUi_CardHeight(c, cw, mt));
    }
    var picks = GameState_Get().player_ch.card_picks;
    var title = Loc_T("cards.pick.title", "Choose a card");
    if (picks > 1) title += "  " + Loc_T("cards.pick.left", "({n} picks left)", { n: string(picks) });
    var skip_label = Loc_T("cards.pick.skip", "Skip: +{gold} gold", { gold: string(Card_SkipGold()) });
    var skip_w = UI_TextWidth(skip_label) + 24 * p;
    var skip_h = mt.row_h + 4 * p;
    var hint = Loc_T("cards.pick.hint", "{left}{right} Choose   {confirm} Take");
    var total = mt.line_h + 3 * p + ch_max + 3 * p + skip_h + 2 * p + mt.line_h;
    var y0 = max(margin, round((mt.gh - total) / 2));
    var slide = p * round((1 - _a) * 3);
    Ui_Text(mt.gw / 2, y0 - slide, title, UI_C_LIGHTEST, fa_center);
    var cy = y0 + mt.line_h + 3 * p - slide;
    var rects = [];
    for (var k = 0; k < n; k++) {
        var cx = margin + k * (cw + gap);
        CardsUi_DrawCard(cx, cy, cw, ch_max, cards[k], k == pk.cursor, _a);
        array_push(rects, { x: cx, y: cy, w: cw, h: ch_max });
    }
    var sx = round((mt.gw - skip_w) / 2);
    var sy = cy + ch_max + 3 * p;
    var skip_sel = (pk.cursor >= n);
    if (skip_sel) {
        Ui_Box(sx - p, sy - p, sx + skip_w + p, sy + skip_h + p, UI_C_LIGHT);
    }
    Ui_DrawFrame(sx, sy, skip_w, skip_h, _a, p);
    if (skip_sel) Ui_Arrow(sx + 5 * p + Ui_Bob(current_time) * p, sy + (skip_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    Ui_Text(sx + skip_w / 2, sy + (skip_h - mt.line_h) div 2, skip_label, skip_sel ? UI_C_LIGHTEST : UI_C_LIGHT, fa_center);
    array_push(rects, { x: sx, y: sy, w: skip_w, h: skip_h });
    pk.rects = rects;
    Prompt_RichDraw(round(mt.gw * 0.1), sy + skip_h + 2 * p, hint, round(mt.gw * 0.8), UI_C_LIGHT, fa_center, _a);
}

function CardsUi_Draw() {
    if (!CardsUi_IsOpen()) return;
    var u = global.cards_ui;
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.8 * a);
    if (u.kind == "cards") CardsUi_DrawPick(u, a);
    else Ui_StackDraw(u.stk, 0.5);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ==========================================================================================================================
// C4: the bed menu (D47), the tutorial pop-up and the Help page (D45), the Controls page of the settings (D49). All on the UI framework
// (Ui_Menu*, Ui_DrawFrame, Prompt_Rich*). The rules live in pure functions elsewhere: Bed_* (scr_levelup), Tutorial_* (scr_dialogue),
// Binds_* / Prompt_* (scr_input).
// ==========================================================================================================================

// ---- the bed: Rest / Upgrade a skill / Leave, once per run per bed -----------------------------------------------------------------
// global.bed_ui = { stk, opened_frame, opened_ms, key } while it is open, with gs.ui.mode = UI_BED. Back leaves without using the bed.
function BedUi_IsOpen() {
    return variable_global_exists("bed_ui") && is_struct(global.bed_ui);
}

function BedUi_Close() {
    var gs = GameState_Get();
    global.bed_ui = undefined;
    if (variable_struct_exists(gs, "ui") && gs.ui.mode == UI_BED) gs.ui.mode = UI_NONE;
}

// A room change closes it (the bed stays free).
function BedUi_Interrupt() {
    if (BedUi_IsOpen()) BedUi_Close();
}

// The player used the bed (interact). A bed already used this run says so; a free one opens the menu. Returns true when the menu opened.
function BedUi_Open(_inst) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "flags") || !is_struct(gs.flags)) gs.flags = {};
    var key = Bed_Key(room_get_name(room), _inst.x, _inst.y);
    if (!Bed_CanUse(gs.flags, key)) {
        Dialogue_StartLines([Loc_T("bed.used", "You have rested here already. The bed is still warm.")]);
        return false;
    }
    var u = { stk: Ui_StackNew(), opened_frame: Input_Frame(), opened_ms: current_time, key: key };
    Ui_StackPush(u.stk, BedUi_MainMenu());
    global.bed_ui = u;
    gs.ui.mode = UI_BED;
    SFX_PlayUI("ui_openclose");
    Tutorial_Trigger("bed");
    return true;
}

function BedUi_MainMenu() {
    var m = Ui_MenuNew("bed_main", Bed_MenuItems(GameState_Get().player_ch), {
        on_confirm: BedUi_MainConfirm, on_back: BedUi_OnBack,
        layout: { title: Loc_T("bed.title", "Bed"), anchor: "center", details: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

function BedUi_UpgradeMenu() {
    var m = Ui_MenuNew("bed_upgrade", Bed_UpgradeItems(GameState_Get().player_ch), {
        on_confirm: BedUi_UpgradeConfirm, on_back: BedUi_OnBack,
        layout: { title: Loc_T("bed.upgrade_title", "Upgrade which skill?"), anchor: "center", details: true, hides_below: true }
    });
    Ui_MenuFixCursor(m, 0);
    return m;
}

// Back on the first menu leaves; Ui_StackBack already took the second menu off.
function BedUi_OnBack(_m, _res) {
    if (_res == "root") BedUi_Close();
}

function BedUi_MainConfirm(_m, _i) {
    var rid = _m.items[_i].id;
    if (rid == "heal") BedUi_Choose("heal", -1);
    else if (rid == "upgrade") Ui_StackPush(global.bed_ui.stk, BedUi_UpgradeMenu());
    else BedUi_Close();
}

function BedUi_UpgradeConfirm(_m, _i) {
    var sid = _m.items[_i].skill_id;
    if (sid < 0) {
        Ui_StackBack(global.bed_ui.stk);
        return;
    }
    BedUi_Choose("upgrade", sid);
}

function BedUi_Choose(_choice, _skill_id) {
    var gs = GameState_Get();
    var r = Bed_Choose(gs.player_ch, gs.flags, global.bed_ui.key, _choice, _skill_id);
    BedUi_Close();
    if (!r.ok) return;
    CardsUi_Commit(r.ch);
    if (_choice == "heal") Dialogue_StartLines([Loc_T("bed.msg.heal", "You sleep a while. HP and MP are full again.")]);
    else Dialogue_StartLines([Loc_T("bed.msg.upgrade", "{skill} is better now.", { skill: SkillDB_Get(_skill_id).name })]);
}

// Called by obj_ui_controller Step while gs.ui.mode == UI_BED.
function BedUi_Handle() {
    var gs = GameState_Get();
    if (!BedUi_IsOpen()) {
        if (gs.ui.mode == UI_BED) gs.ui.mode = UI_NONE;
        return;
    }
    var u = global.bed_ui;
    if (Input_Frame() - u.opened_frame < CARDS_UI_INPUT_DELAY_FRAMES) return;
    var top = Ui_StackTop(u.stk);
    if (is_struct(top)) Ui_MenuUpdate(top, u.stk);
}

function BedUi_Draw() {
    if (!BedUi_IsOpen()) return;
    var u = global.bed_ui;
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.6 * a);
    Ui_StackDraw(u.stk, 0.5);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- the tutorial pop-up --------------------------------------------------------------------------------------------------------------
// global.tutorial_ui = { id, queue, opened_frame, opened_ms } (Tutorial_Trigger, scr_dialogue). It is drawn over everything the ui controller
// draws and, while it is up, nothing else gets input: the controller's Step calls Tutorial_Step first and the battle controller waits.
function Tutorial_Step() {
    if (!Tutorial_IsOpen()) return false;
    var t = global.tutorial_ui;
    if (Input_Frame() - t.opened_frame >= TUTORIAL_INPUT_DELAY_FRAMES) {
        if (Input_UIConfirm() || Input_UIBack() || mouse_check_button_pressed(mb_left)) {
            SFX_PlayUI("ui_confirm");
            Tutorial_Dismiss();
        }
    }
    return true;
}

// The box of a tutorial entry: { x, y, w, h, iw, body_h } centred on the GUI grid.
function Tutorial_Box(_e, _slide) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = min(mt.gw - 2 * mt.margin, round(mt.gw * 0.8));
    var iw = w - 8 * p;
    var body_h = Ui_TextBlockH(_e.body, iw);
    var h = 8 * p + (mt.line_h + 3 * p) + body_h + 3 * p + mt.line_h;
    return { x: round((mt.gw - w) / 2), y: max(mt.margin, round((mt.gh - h) / 2)) - _slide, w: w, h: h, iw: iw, body_h: body_h };
}

function Tutorial_Draw() {
    if (!Tutorial_IsOpen()) return;
    var t = global.tutorial_ui;
    var e = Tutorial_Get(t.id);
    if (!is_struct(e)) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var a = Ui_AnimT(t.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.55 * a);
    var slide = p * round((1 - a) * 3);
    var b = Tutorial_Box(e, slide);
    Ui_DrawFrame(b.x, b.y, b.w, b.h, a, p);
    draw_set_alpha(a);
    var x0 = b.x + 4 * p;
    var ty = b.y + 4 * p;
    Ui_Text(x0, ty, e.title, UI_C_LIGHTEST);
    Ui_Box(b.x + 3 * p, ty + mt.line_h + p, b.x + b.w - 3 * p, ty + mt.line_h + 2 * p, UI_C_DARK);
    ty += mt.line_h + 3 * p;
    Ui_TextBlock(x0, ty, e.body, b.iw, UI_C_LIGHT);
    ty += b.body_h + 3 * p;
    var more = array_length(t.queue);
    Prompt_RichDraw(x0, ty, Tutorial_Footer(), b.iw, UI_C_LIGHTEST, fa_left, a);
    if (more > 0) Ui_Text(x0 + b.iw, ty, Loc_T("tutorial.more", "+{n} more", { n: string(more) }), UI_C_LIGHT, fa_right);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- the Help page (pause menu): every tutorial, seen or not, in the framework's list with the details panel ----------------------------
// global.help_ui = { stk, opened_frame, opened_ms }.
function HelpUi_IsOpen() {
    return variable_global_exists("help_ui") && is_struct(global.help_ui);
}

function HelpUi_Open() {
    var u = { stk: Ui_StackNew(), opened_frame: Input_Frame(), opened_ms: current_time };
    var m = Ui_MenuNew("help", Tutorial_HelpItems(), {
        on_back: HelpUi_OnBack,
        layout: { title: Loc_T("help.title", "Help"), anchor: "center", details: true }
    });
    Ui_StackPush(u.stk, m);
    global.help_ui = u;
    SFX_PlayUI("ui_openclose");
}

function HelpUi_Close() {
    global.help_ui = undefined;
}

function HelpUi_OnBack(_m, _res) {
    HelpUi_Close();
}

function HelpUi_Handle() {
    if (!HelpUi_IsOpen()) return;
    var u = global.help_ui;
    if (Input_Frame() - u.opened_frame < 4) return;   // the press that opened it
    var top = Ui_StackTop(u.stk);
    if (is_struct(top)) Ui_MenuUpdate(top, u.stk);
}

function HelpUi_Draw() {
    if (!HelpUi_IsOpen()) return;
    var u = global.help_ui;
    var a = Ui_AnimT(u.opened_ms, current_time);
    UI_SetFont();
    draw_set_alpha(1);
    Ui_DimBackdrop(0.6 * a);
    Ui_StackDraw(u.stk, 0.5);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// ---- the Controls page of the settings (D49) ---------------------------------------------------------------------------------------------
// The rows are the rebindable actions; confirming one waits for a key (Esc or right click cancels). The page edits the settings' pending copy
// (sp.pending.keys); Apply on the settings list saves and applies, Back throws the change away, like every other row.
function Controls_RowHelp(_id) {
    if (_id == "reset") return Loc_T("controls.help.reset", "Puts every keyboard key back to how it was. The controller is never changed.");
    return Loc_T("controls.help.row", "Confirm, then press the new key. If another action already uses it, the two swap. Esc cancels.");
}

// The page's menu items for a key table. _capture_row is the row waiting for a key ("" = none); _msg_row / _msg replace that row's help.
function Controls_Items(_keys, _capture_row, _msg_row = "", _msg = "") {
    var items = [];
    var ids = Binds_RowIds();
    for (var i = 0; i < array_length(ids); i++) {
        var rid = ids[i];
        var waiting = (rid == _capture_row);
        array_push(items, {
            id: rid, label: Binds_RowLabel(rid), kind: "button", enabled: true, lines: [],
            value: waiting ? Loc_T("controls.press_key", "Press a key...") : Binds_KeysText(variable_struct_get(_keys, rid)),
            help: (rid == _msg_row && _msg != "") ? _msg : Controls_RowHelp(rid)
        });
    }
    array_push(items, {
        id: "reset", label: Loc_T("controls.reset", "Reset to defaults"), kind: "button", enabled: true, lines: [], value: "", help: Controls_RowHelp("reset")
    });
    return items;
}

// A key was pressed for a row: { ok, keys, message }. Pure: the caller stores the keys.
function Controls_Capture(_keys, _row, _key) {
    var r = Binds_Assign(_keys, _row, _key);
    var msg = "";
    if (!r.ok) {
        msg = (r.reason == "reserved") ? Loc_T("controls.reserved", "That key is reserved.") : Loc_T("controls.unusable", "That key cannot be used.");
    } else if (r.swapped != "") {
        msg = Loc_T("controls.swapped", "{other} had that key, so the two swapped.", { other: Binds_RowLabel(r.swapped) });
    } else {
        msg = Loc_T("controls.set", "Key changed. Apply saves it.");
    }
    return { ok: r.ok, keys: r.keys, message: msg };
}

// A keyboard press this frame as a bindable code, or -1. Left / right shift and control count as the plain ones.
function Controls_PollKey() {
    if (!keyboard_check_pressed(vk_anykey)) return -1;
    var k = keyboard_lastkey;
    if (k == vk_lshift || k == vk_rshift) k = vk_shift;
    if (k == vk_lcontrol || k == vk_rcontrol) k = vk_control;
    return k;
}

function ControlsPage_Open(_sp) {
    _sp.controls = { menu: undefined, capture: "", msg_row: "", msg: "", opened_frame: Input_Frame() };
    var c = _sp.controls;
    c.menu = Ui_MenuNew("controls", Controls_Items(_sp.pending.keys, ""), {
        on_confirm: ControlsPage_OnConfirm, on_back: ControlsPage_OnBack,
        layout: { title: Loc_T("controls.title", "Controls"), anchor: "center", details: true }
    });
}

function ControlsPage_Refresh(_sp) {
    var c = _sp.controls;
    if (!is_struct(c)) return;
    c.menu.items = Controls_Items(_sp.pending.keys, c.capture, c.msg_row, c.msg);
}

function ControlsPage_OnConfirm(_m, _i) {
    var sp = GameState_Get().ui.settings_popup;
    var c = sp.controls;
    var rid = _m.items[_i].id;
    if (rid == "reset") {
        sp.pending.keys = Binds_Defaults();
        sp.dirty = true;
        c.msg_row = "reset";
        c.msg = Loc_T("controls.reset_done", "Keys are back to the defaults. Apply saves them.");
        SettingsPopup_Refresh();
        ControlsPage_Refresh(sp);
        return;
    }
    c.capture = rid;
    c.opened_frame = Input_Frame();
    c.msg_row = rid;
    c.msg = Loc_T("controls.waiting", "Press the new key for {action}. Esc cancels.", { action: Binds_RowLabel(rid) });
    ControlsPage_Refresh(sp);
}

// Back leaves the Controls page for the settings list (the change stays pending).
function ControlsPage_OnBack(_m, _res) {
    var sp = GameState_Get().ui.settings_popup;
    sp.controls = undefined;
}

// A key for the row being captured (also the entry point the smoke run uses in place of a real key press).
function ControlsPage_OnKey(_sp, _key) {
    var c = _sp.controls;
    if (!is_struct(c) || c.capture == "") return false;
    if (_key == vk_escape) {
        c.capture = "";
        c.msg = "";
        c.msg_row = "";
        ControlsPage_Refresh(_sp);
        SFX_PlayUI("ui_back");
        return true;
    }
    var r = Controls_Capture(_sp.pending.keys, c.capture, _key);
    c.msg_row = c.capture;
    c.msg = r.message;
    if (r.ok) {
        _sp.pending.keys = r.keys;
        _sp.dirty = true;
        c.capture = "";
        SFX_PlayUI("ui_confirm");
        SettingsPopup_Refresh();
    } else {
        SFX_PlayUI("ui_back");
    }
    ControlsPage_Refresh(_sp);
    return true;
}

function ControlsPage_Handle(_sp) {
    var c = _sp.controls;
    if (c.capture != "") {
        if (Input_Frame() - c.opened_frame < 2) return;
        if (mouse_check_button_pressed(mb_right)) { ControlsPage_OnKey(_sp, vk_escape); return; }
        var k = Controls_PollKey();
        if (k >= 0) ControlsPage_OnKey(_sp, k);
        return;
    }
    Ui_MenuUpdate(c.menu);
}

// --------------------
// SETTINGS SCREEN (D0 pilot on the UI framework; opened from the title and from the pause menu)
// --------------------
// Rows work on a pending copy of the settings; Apply commits and saves, Back leaves without saving. The window rows keep D91's logic
// (Display_WindowedMaxScaleNow decides the largest windowed scale; scale only matters while windowed).
function Settings_TextSpeedMul(_idx) {
    switch (clamp(round(_idx), 0, SETTINGS_TEXT_SPEED_MAX)) {
        case 0: return 0.6;
        case 2: return 1.6;
    }
    return 1;
}

function Settings_ShakeOn() {
    return GameSettings_Ensure().screen_shake != 0;
}

// One change to the pending settings struct by row id. Returns true when something changed. The language row only flips the code;
// the caller applies the preview (Loc_SetLanguage).
function Settings_Adjust(_p, _id, _dir, _scale_max) {
    var d = (_dir < 0) ? -1 : 1;
    switch (_id) {
        case "vol_ui":
        case "vol_sfx":
        case "vol_bgm":
            var field = (_id == "vol_ui") ? "audio_ui" : ((_id == "vol_sfx") ? "audio_sfx" : "audio_bgm");
            var old = variable_struct_get(_p, field);
            var nv = clamp(round((old + d * SETTINGS_VOLUME_STEP) * 100) / 100, 0, 1);
            variable_struct_set(_p, field, nv);
            return nv != old;
        case "text_speed":
            var ts = clamp(_p.text_speed + d, 0, SETTINGS_TEXT_SPEED_MAX);
            var ts_changed = (ts != _p.text_speed);
            _p.text_speed = ts;
            return ts_changed;
        case "shake":
            _p.screen_shake = (_p.screen_shake != 0) ? 0 : 1;
            return true;
        case "qte_assist":
            _p.qte_assist = (_p.qte_assist != 0) ? 0 : 1;
            return true;
        case "window":
            _p.window_mode = (_p.window_mode + ((d > 0) ? 1 : WINDOW_MODE_COUNT - 1)) mod WINDOW_MODE_COUNT;
            return true;
        case "scale":
            if (_p.window_mode != WINDOW_MODE_WINDOWED) return false;
            var sc = clamp(_p.display_scale + d, min(DISPLAY_SCALE_MIN, _scale_max), _scale_max);
            var sc_changed = (sc != _p.display_scale);
            _p.display_scale = sc;
            return sc_changed;
        case "language":
            _p.language = (_p.language == "ko") ? "en" : "ko";
            return true;
    }
    return false;
}

function Settings_WindowModeText(_mode) {
    if (_mode == WINDOW_MODE_WINDOWED) return Loc_T("settings.value.window_windowed", "Windowed");
    if (_mode == WINDOW_MODE_BORDERLESS) return Loc_T("settings.value.window_borderless", "Borderless");
    return Loc_T("settings.value.window_exclusive", "Exclusive");
}

function Settings_TextSpeedText(_idx) {
    if (_idx <= 0) return Loc_T("settings.value.speed_slow", "Slow");
    if (_idx >= SETTINGS_TEXT_SPEED_MAX) return Loc_T("settings.value.speed_fast", "Fast");
    return Loc_T("settings.value.speed_normal", "Normal");
}

function Settings_Row(_id, _label, _kind, _value, _help) {
    return { id: _id, label: _label, kind: _kind, enabled: true, value: _value, amount: 0, help: _help, lines: [] };
}

function Settings_VolumeRow(_id, _label, _v, _help) {
    var r = Settings_Row(_id, _label, "slider", string(clamp(round(_v * 100), 0, 100)) + "%", _help);
    r.amount = _v;
    return r;
}

// The menu items for a pending settings struct: labels, values, slider fills, help sentences and number lines (D100: the numbers
// come from the real data, never typed in twice).
function SettingsMenu_Items(_p, _scale_max, _dirty = false) {
    var ts = clamp(_p.text_speed, 0, SETTINGS_TEXT_SPEED_MAX);
    var windowed = (_p.window_mode == WINDOW_MODE_WINDOWED);
    var items = [];
    array_push(items, Settings_VolumeRow("vol_ui", Loc_T("settings.row.ui", "UI"), _p.audio_ui,
        Loc_T("settings.help.vol_ui", "How loud menu clicks and other interface sounds are.")));
    array_push(items, Settings_VolumeRow("vol_sfx", Loc_T("settings.row.sfx", "SFX"), _p.audio_sfx,
        Loc_T("settings.help.vol_sfx", "How loud hits, footsteps and other game sounds are.")));
    array_push(items, Settings_VolumeRow("vol_bgm", Loc_T("settings.row.bgm", "BGM"), _p.audio_bgm,
        Loc_T("settings.help.vol_bgm", "How loud the music is.")));

    var r_ts = Settings_Row("text_speed", Loc_T("settings.row.text_speed", "Text speed"), "choice",
        Settings_TextSpeedText(ts), Loc_T("settings.help.text_speed", "How fast dialogue text appears."));
    r_ts.measure = [Settings_TextSpeedText(0), Settings_TextSpeedText(1), Settings_TextSpeedText(2)];
    array_push(r_ts.lines, { label: Loc_T("settings.line.cps", "Characters per second"), value: string(round(UI_DIALOGUE_CHARS_PER_SEC * Settings_TextSpeedMul(ts))) });
    array_push(items, r_ts);

    var r_sh = Settings_Row("shake", Loc_T("settings.row.shake", "Screen shake"), "choice",
        (_p.screen_shake != 0) ? Loc_T("settings.value.on", "On") : Loc_T("settings.value.off", "Off"),
        Loc_T("settings.help.shake", "Turns the screen shake on hits on or off."));
    r_sh.measure = [Loc_T("settings.value.on", "On"), Loc_T("settings.value.off", "Off")];
    array_push(items, r_sh);

    var r_qa = Settings_Row("qte_assist", Loc_T("settings.row.qte_assist", "QTE assist"), "choice",
        (_p.qte_assist != 0) ? Loc_T("settings.value.on", "On") : Loc_T("settings.value.off", "Off"),
        Loc_T("settings.help.qte_assist", "Wider bar zones and more time on arrow skills."));
    r_qa.measure = [Loc_T("settings.value.on", "On"), Loc_T("settings.value.off", "Off")];
    array_push(items, r_qa);

    var r_wm = Settings_Row("window", Loc_T("settings.row.window_mode", "Window"), "choice", Settings_WindowModeText(_p.window_mode),
        Loc_T("settings.help.window", "Windowed, borderless fullscreen, or exclusive fullscreen."));
    r_wm.measure = [Settings_WindowModeText(WINDOW_MODE_WINDOWED), Settings_WindowModeText(WINDOW_MODE_BORDERLESS), Settings_WindowModeText(WINDOW_MODE_EXCLUSIVE)];
    array_push(r_wm.lines, { label: Loc_T("settings.line.monitor", "Monitor"), value: string(Display_MonitorW()) + " x " + string(Display_MonitorH()) });
    array_push(items, r_wm);

    var r_sc = Settings_Row("scale", Loc_T("settings.row.scale", "Scale"), "choice",
        windowed ? (string(_p.display_scale) + "x") : Loc_T("settings.value.auto", "Auto"),
        Loc_T("settings.help.scale", "How many times the picture is enlarged in a window. Only used when windowed."));
    r_sc.enabled = windowed;
    r_sc.measure = [string(DISPLAY_SCALE_MAX) + "x", Loc_T("settings.value.auto", "Auto")];
    var wsz = Display_WindowSizeForScale(_p.display_scale);
    array_push(r_sc.lines, { label: Loc_T("settings.line.window_size", "Window size"), value: string(wsz.w) + " x " + string(wsz.h) });
    array_push(items, r_sc);

    var r_lg = Settings_Row("language", Loc_T("settings.row.language", "Language"), "choice", Loc_LanguageDisplayName(_p.language),
        Loc_T("settings.help.language", "Language of all text in the game."));
    r_lg.measure = [Loc_LanguageDisplayName("en"), Loc_LanguageDisplayName("ko")];
    array_push(items, r_lg);

    var r_ct = Settings_Row("controls", Loc_T("settings.row.controls", "Controls"), "button", "",
        Loc_T("settings.help.controls", "Change the keyboard keys. The controller stays as it is."));
    array_push(items, r_ct);

    var r_ap = Settings_Row("apply", Loc_T("settings.row.apply", "Apply"), "button",
        _dirty ? Loc_T("settings.value.pending", "Pending") : Loc_T("settings.value.saved", "Saved"),
        Loc_T("settings.help.apply", "Saves your changes and applies them now. Back leaves without saving."));
    r_ap.measure = [Loc_T("settings.value.pending", "Pending"), Loc_T("settings.value.saved", "Saved")];
    array_push(items, r_ap);
    return items;
}

function SettingsPopup_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "settings_popup")) {
        gs.ui.settings_popup = {
            open: false, owner: "", menu: undefined, pending: GameSettings_Copy(GameSettings_Ensure()),
            dirty: false, closing: false, closed_ms: -1, scale_max: DISPLAY_SCALE_MAX, controls: undefined
        };
    }
}

function SettingsPopup_IsOpen(_owner = "") {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open) return false;
    if (_owner != "" && string(sp.owner) != string(_owner)) return false;
    return true;
}

// Rebuilds the rows from the pending settings (after any change; the cursor stays where it is).
function SettingsPopup_Refresh() {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open || !is_struct(sp.menu)) return;
    sp.menu.items = SettingsMenu_Items(sp.pending, sp.scale_max, sp.dirty);
}

// 0..1 for the dim logic while the popup slides in or out (D97).
function SettingsPopup_Alpha() {
    var sp = GameState_Get().ui.settings_popup;
    return is_struct(sp.menu) ? Ui_MenuAlpha(sp.menu, current_time) : 0;
}

function SettingsPopup_Open(_owner = "") {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    sp.open = true;
    sp.owner = string(_owner);
    sp.controls = undefined;
    sp.dirty = false;
    sp.closing = false;
    sp.closed_ms = -1;
    sp.pending = GameSettings_Copy(GameSettings_Ensure());
    sp.scale_max = clamp(Display_WindowedMaxScaleNow(), 1, DISPLAY_SCALE_MAX);
    sp.menu = Ui_MenuNew("settings", SettingsMenu_Items(sp.pending, sp.scale_max), {
        on_confirm: SettingsMenu_OnConfirm, on_adjust: SettingsMenu_OnAdjust, on_back: SettingsMenu_OnBack,
        layout: { title: Loc_T("settings.title", "Settings"), anchor: "center", details: true, hides_below: true }
    });
    SFX_PlayUI("ui_openclose");
}

function SettingsPopup_Close(_immediate = false) {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open) return;
    if (_immediate) {
        SettingsPopup_CloseFinalize();
        return;
    }
    if (sp.closing) return;
    sp.closing = true;
    sp.closed_ms = current_time;
    if (is_struct(sp.menu)) Ui_MenuClose(sp.menu);
}

function SettingsPopup_CloseFinalize() {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (is_struct(sp.menu)) Ui_MemSet(Ui_MemGlobal(), sp.menu.id, sp.menu.cursor);
    sp.open = false;
    sp.owner = "";
    sp.closing = false;
    sp.closed_ms = -1;
    sp.dirty = false;
    sp.menu = undefined;
    sp.controls = undefined;
    sp.pending = GameSettings_Copy(GameSettings_Ensure());
}

// Applies one change to the pending copy and refreshes the rows; the language row previews at once.
function SettingsPopup_Change(_id, _dir) {
    var sp = GameState_Get().ui.settings_popup;
    var changed = Settings_Adjust(sp.pending, _id, _dir, sp.scale_max);
    if (changed) {
        sp.dirty = true;
        if (_id == "language") Loc_SetLanguage(sp.pending.language);
        SettingsPopup_Refresh();
        if (_id == "language") sp.menu.layout.title = Loc_T("settings.title", "Settings");
    }
    return changed;
}

function SettingsMenu_OnAdjust(_m, _i, _dir) {
    return SettingsPopup_Change(_m.items[_i].id, _dir);
}

// Confirm: Apply commits and saves; a choice row steps forward (so a toggle flips with the confirm key too).
function SettingsMenu_OnConfirm(_m, _i) {
    var rid = _m.items[_i].id;
    var sp = GameState_Get().ui.settings_popup;
    if (rid == "controls") {
        ControlsPage_Open(sp);
        return;
    }
    if (rid == "apply") {
        var committed = GameSettings_Commit(sp.pending, true);
        sp.pending = GameSettings_Copy(committed);
        sp.dirty = false;
        SettingsPopup_Refresh();
        return;
    }
    if (_m.items[_i].kind == "choice") SettingsPopup_Change(rid, 1);
}

// Back: leave without saving, restoring the saved language.
function SettingsMenu_OnBack(_m, _res) {
    var sp = GameState_Get().ui.settings_popup;
    sp.pending = GameSettings_Copy(GameSettings_Ensure());
    sp.dirty = false;
    sp.controls = undefined;
    Loc_SetLanguage(GameSettings_Ensure().language);
    SettingsPopup_Close(false);
}

function SettingsPopup_HandleInput() {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open) return;
    if (sp.closing) {
        if (current_time - sp.closed_ms >= UI_PANEL_MS) SettingsPopup_CloseFinalize();
        return;
    }
    if (is_struct(sp.controls)) {   // D49: the Controls page sits on top of the list
        ControlsPage_Handle(sp);
        return;
    }
    Ui_MenuUpdate(sp.menu);
}

function SettingsPopup_Draw(_draw_backdrop = true) {
    SettingsPopup_Ensure();
    var sp = GameState_Get().ui.settings_popup;
    if (!sp.open || !is_struct(sp.menu)) return;
    var a = Ui_MenuAlpha(sp.menu, current_time);
    if (_draw_backdrop) Ui_DimBackdrop(0.6 * a);
    if (is_struct(sp.controls)) Ui_MenuDraw(sp.controls.menu, a);
    else Ui_MenuDraw(sp.menu, a);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// --------------------
// TITLE MENU (D0 pilot on the UI framework)
// --------------------
// obj_start_controller keeps `state` ("main" | "difficulty" | "settings" | "boot_logo" | "cutscene") and holds the menu stack in
// title_stk: [title] or [title, difficulty]. Settings is the popup above.
function Title_MainItems(_can_load) {
    return [
        { id: "new", label: Loc_T("menu.main.option.0", "New Game"), kind: "button", enabled: true },
        { id: "load", label: Loc_T("menu.main.option.continue", "Continue"), kind: "button", enabled: _can_load },   // C1 (D46): Continue run
        { id: "settings", label: Loc_T("menu.main.option.2", "Settings"), kind: "button", enabled: true },
        { id: "exit", label: Loc_T("menu.main.option.3", "Exit Game"), kind: "button", enabled: true }
    ];
}

function Title_DifficultyItems() {
    return [
        { id: "easy", label: Loc_T("settings.difficulty.option.0", "Easy"), kind: "button", enabled: true },
        { id: "normal", label: Loc_T("settings.difficulty.option.1", "Normal"), kind: "button", enabled: true },
        { id: "hard", label: Loc_T("settings.difficulty.option.2", "Hard"), kind: "button", enabled: true },
        { id: "back", label: Loc_T("menu.common.back", "Back"), kind: "button", enabled: true }
    ];
}

function Title_DifficultyValue(_i) {
    var vals = [DIFFICULTY_EASY, DIFFICULTY_NORMAL, DIFFICULTY_HARD];
    return vals[clamp(_i, 0, 2)];
}

function Title_Build(_c) {
    _c.title_stk = Ui_StackNew();
    Ui_StackPush(_c.title_stk, Ui_MenuNew("title", Title_MainItems(RunSave_HasSave()), {
        owner: _c, on_confirm: Title_OnConfirm,
        layout: { anchor: "bottom", y_frac: 0.62, center: true }
    }));
    _c.title_refresh = false;
}

// Language or save files may have changed since the labels were made.
function Title_Refresh(_c) {
    var m = _c.title_stk.menus[0];
    m.items = Title_MainItems(RunSave_HasSave());
    Ui_MenuFixCursor(m, m.cursor);
    _c.title_refresh = false;
}

function Title_OpenDifficulty(_c) {
    var gs = GameState_Get();
    UI_ModalRootBegin("title_difficulty");
    var m = Ui_MenuNew("difficulty", Title_DifficultyItems(), {
        owner: _c, on_confirm: Title_OnConfirm, on_back: Title_OnBack,
        layout: { title: Loc_T("menu.difficulty.title", "Select Difficulty"), anchor: "center" }
    });
    var cur = DIFFICULTY_NORMAL;
    if (variable_struct_exists(gs, "difficulty")) cur = Difficulty_Normalize(gs.difficulty);
    for (var i = 0; i < 3; i++) if (Title_DifficultyValue(i) == cur) Ui_MenuFixCursor(m, i);
    Ui_StackPush(_c.title_stk, m);
    _c.state = "difficulty";
}

// The difficulty menu was left by Back (the stack already popped it).
function Title_OnBack(_m, _res) {
    if (_m.id != "difficulty") return;
    UI_ModalRootEnd(false);
    _m.owner.state = "main";
}

function Title_OnConfirm(_m, _i) {
    var c = _m.owner;
    var rid = _m.items[_i].id;
    if (_m.id == "difficulty") {
        if (rid == "back") {
            if (Ui_StackBack(c.title_stk) == "pop") Title_OnBack(_m, "pop");
            return;
        }
        // start: the panel fades out, then the intro cutscene is requested (the dim holds until the room changes)
        UI_ModalRootHold("title_room_change");
        c.title_exit = { value: Title_DifficultyValue(_i), at: current_time + UI_PANEL_MS };
        Ui_MenuClose(_m);
        return;
    }
    switch (rid) {
        case "new": Title_OpenDifficulty(c); break;
        case "load":   // C1 (D46): Continue run
            var cont = Run_Continue();
            if (!cont.ok) SaveMenu_OpenMessage(Run_ContinueFailText(cont.status), true);
            break;
        case "settings":
            SettingsPopup_Open("title");
            c.state = "settings";
            break;
        case "exit": game_end(); break;
    }
}

// One Step for the title in states main / difficulty / settings.
function Title_Step(_c) {
    var gs = GameState_Get();
    if (!is_struct(_c.title_stk)) Title_Build(_c);
    if (!variable_instance_exists(_c, "legacy_notice_checked")) {   // C1 (D16): once per launch, say why old saves are not loaded / that the profile file was not usable
        _c.legacy_notice_checked = true;
        var notice_text = Profile_NoticeText();
        var notice_prof = Profile_Get();
        if (notice_text == "" && Save_LegacyFilesExist() && !notice_prof.legacy_notice_seen) {
            notice_prof.legacy_notice_seen = true;
            Profile_Flush();
            notice_text = Save_LegacyNotice();
        }
        if (notice_text != "") {
            SaveMenu_OpenMessage(notice_text, true);
            return;
        }
    }
    if (is_struct(_c.title_exit)) {
        if (current_time >= _c.title_exit.at) {
            var v = _c.title_exit.value;
            _c.title_exit = undefined;
            Difficulty_SetCurrent(v);
            gs.in_main_menu = false;
            Run_BeginNewGame();   // C1: the intro plays once per profile, later runs start at once
        }
        return;
    }
    if (_c.state == "settings") {
        SettingsPopup_HandleInput();
        if (!SettingsPopup_IsOpen("title")) {
            _c.state = "main";
            _c.title_refresh = true;
        }
        return;
    }
    if (_c.title_refresh) Title_Refresh(_c);
    Ui_MenuUpdate(Ui_StackTop(_c.title_stk), _c.title_stk);
}

function Title_Draw(_c) {
    if (!is_struct(_c.title_stk) || _c.state == "settings") return;
    Ui_StackDraw(_c.title_stk);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

// For the shared modal dim (UI_GetModalVisualAlpha) while the difficulty panel is up.
function Title_ModalAlpha(_c) {
    if (!is_struct(_c.title_stk)) return 1;
    var top = Ui_StackTop(_c.title_stk);
    return is_struct(top) ? Ui_MenuAlpha(top, current_time) : 1;
}

// --------------------
// PAUSE MENU (inventory-style popup)
// --------------------
#macro PAUSE_ABANDON_INDEX 4   // Resume, Settings, Help, Exit to Main Menu, Abandon Run

function PauseMenu_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "pause_menu")) {
        gs.ui.pause_menu = {
            open: false,
            closing: false,
            close_frame: UI_OPENED_FRAME_NONE,
            pending_exit_main_menu: false,
            pending_abandon: false,
            abandon_armed: false,
            index: 0,
            options: [
                Loc_T("pause.option.resume", "Resume"),
                Loc_T("pause.option.settings", "Settings"),
                Loc_T("pause.option.help", "Help"),
                Loc_T("pause.option.exit_main", "Exit to Main Menu"),
                Loc_T("pause.option.abandon", "Abandon Run")
            ],
            opened_frame: UI_OPENED_FRAME_NONE
        };
    } else {
        var pm0 = gs.ui.pause_menu;
        if (!variable_struct_exists(pm0, "opened_frame")) pm0.opened_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(pm0, "closing")) pm0.closing = false;
        if (!variable_struct_exists(pm0, "close_frame")) pm0.close_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(pm0, "pending_exit_main_menu")) pm0.pending_exit_main_menu = false;
        if (!variable_struct_exists(pm0, "pending_abandon")) pm0.pending_abandon = false;
        if (!variable_struct_exists(pm0, "abandon_armed")) pm0.abandon_armed = false;
    }
}

function PauseMenu_Open() {
    PauseMenu_Ensure();
    var gs = GameState_Get();
    UI_ModalRootBegin("pause");
    SFX_PlayUI("ui_openclose");
    gs.ui.mode = UI_PAUSE;
    var pm = gs.ui.pause_menu;
    pm.open = true;
    pm.closing = false;
    pm.close_frame = UI_OPENED_FRAME_NONE;
    pm.pending_exit_main_menu = false;
    pm.pending_abandon = false;
    pm.abandon_armed = false;
    pm.options[PAUSE_ABANDON_INDEX] = Loc_T("pause.option.abandon", "Abandon Run");
    pm.index = 0;
    pm.opened_frame = Input_Frame();
    gs.ui.pause_menu = pm;
}

function PauseMenu_Close(_immediate = false) {
    PauseMenu_Ensure();
    var gs = GameState_Get();
    var pm = gs.ui.pause_menu;
    if (_immediate) {
        UI_ModalRootEnd(false, true);
        SFX_PlayUI("ui_openclose");
        pm.open = false;
        pm.closing = false;
        pm.close_frame = UI_OPENED_FRAME_NONE;
        pm.pending_exit_main_menu = false;
        pm.opened_frame = UI_OPENED_FRAME_NONE;
        gs.ui.pause_menu = pm;
        gs.ui.mode = UI_NONE;
        return;
    }
    if (!pm.open || pm.closing) return;
    UI_ModalRootEnd(false);
    SFX_PlayUI("ui_openclose");
    pm.closing = true;
    pm.close_frame = Input_Frame();
    gs.ui.pause_menu = pm;
}

function PauseMenu_ExitToMainMenu() {
    PauseMenu_Ensure();
    var gs = GameState_Get();
    var pm = gs.ui.pause_menu;
    pm.pending_exit_main_menu = true;
    gs.ui.pause_menu = pm;
    PauseMenu_Close(false);
}

function PauseMenu_CloseFinalize() {
    PauseMenu_Ensure();
    var gs = GameState_Get();
    var pm = gs.ui.pause_menu;
    var do_exit = pm.pending_exit_main_menu;
    var do_abandon = pm.pending_abandon;

    pm.open = false;
    pm.closing = false;
    pm.close_frame = UI_OPENED_FRAME_NONE;
    pm.pending_exit_main_menu = false;
    pm.pending_abandon = false;
    pm.opened_frame = UI_OPENED_FRAME_NONE;
    gs.ui.pause_menu = pm;
    if (gs.ui.mode == UI_PAUSE) gs.ui.mode = UI_NONE;

    if (do_abandon) {
        Run_Abandon();   // C1 (D92): counts as a death, keeps the echo; the death scene and the echo pick follow
        return;
    }

    if (do_exit) {
        Run_AutoSave();   // C1 (D46): leaving to the title keeps the run; Continue picks it up
        gs.in_main_menu = true;
        gs.player_inst = noone;
        global.player_inst = noone;
        if (variable_struct_exists(gs, "ui")) {
            gs.ui.lines = [];
            gs.ui.index = 0;
            gs.ui.speaker = "";
            gs.ui.confirm_action = "";
        }
        if (room != rm_start) {
            RoomState_OnRoomExit();
            Transition_RequestLoadingRoomFade(rm_start);
        }
    }
}

function PauseMenu_IsOpen() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) return false;
    return gs.ui.mode == UI_PAUSE;
}

function PauseMenu_NavPressed(_action) {
    return Input_UIPressed(_action);
}

function PauseMenu_HandleInput() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "pause_menu")) return;
    var pm = gs.ui.pause_menu;
    if (!pm.open) return;
    var frame = Input_Frame();

    if (SettingsPopup_IsOpen("pause")) {
        SettingsPopup_HandleInput();
        return;
    }
    if (HelpUi_IsOpen()) {   // D45: the Help page
        HelpUi_Handle();
        return;
    }

    if (pm.closing) {
        if (frame - pm.close_frame >= UI_POPUP_FADE_FRAMES) {
            PauseMenu_CloseFinalize();
        } else {
            gs.ui.pause_menu = pm;
        }
        return;
    }

    var nav_up = PauseMenu_NavPressed("menu_up");
    var nav_down = PauseMenu_NavPressed("menu_down");
    var k_ok = Input_UIConfirm();
    var k_back = Input_UIBack();

    if (k_back) {
        SFX_PlayUI("ui_back");
        PauseMenu_Close();
        return;
    }

    var count = array_length(pm.options);
    var prev_idx = pm.index;
    if (nav_up && pm.index > 0) pm.index -= 1;
    if (nav_down && pm.index < count - 1) pm.index += 1;
    if (pm.index != prev_idx) {
        SFX_PlayUI("ui_move");
        pm.abandon_armed = false;
        pm.options[PAUSE_ABANDON_INDEX] = Loc_T("pause.option.abandon", "Abandon Run");
    }

    if (k_ok) {
        SFX_PlayUI("ui_confirm");
        if (pm.index == 0) {
            PauseMenu_Close();
            return;
        } else if (pm.index == 1) {
            SettingsPopup_Open("pause");
            gs.ui.pause_menu = pm;
            return;
        } else if (pm.index == 2) {
            HelpUi_Open();
            gs.ui.pause_menu = pm;
            return;
        } else if (pm.index == 3) {
            PauseMenu_ExitToMainMenu();
            return;
        } else if (pm.index == PAUSE_ABANDON_INDEX) {
            // two presses: the first asks, the second abandons the run
            if (!pm.abandon_armed) {
                pm.abandon_armed = true;
                pm.options[PAUSE_ABANDON_INDEX] = Loc_T("pause.option.abandon_confirm", "Sure? Confirm again");
            } else {
                pm.pending_abandon = true;
                gs.ui.pause_menu = pm;
                PauseMenu_Close();
                return;
            }
        }
    }

    gs.ui.pause_menu = pm;
}

function PauseMenu_Draw() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "pause_menu")) return;
    var pm = gs.ui.pause_menu;
    if (!pm.open) return;

    if (SettingsPopup_IsOpen("pause")) {
        SettingsPopup_Draw(false);
        draw_set_alpha(1);
        return;
    }
    if (HelpUi_IsOpen()) {
        HelpUi_Draw();
        return;
    }

    UI_SetFont();

    var layout = Menu_GetLayout();
    var w = layout.w;
    var h = layout.h;
    var pad = layout.pad;
    var line_h = UI_TextHeight("A");
    var inner_pad = max(6, round(line_h * 0.30), round(pad * 0.6));
    var row_h = max(18, line_h + inner_pad * 2);

    var option_labels = [
        Loc_T("pause.option.resume", "Resume"),
        Loc_T("pause.option.settings", "Settings"),
        Loc_T("pause.option.help", "Help"),
        Loc_T("pause.option.exit_main", "Exit to Main Menu")
    ];
    var max_w = 0;
    for (var i = 0; i < array_length(pm.options); i++) {
        var lbl = (i < array_length(option_labels)) ? option_labels[i] : pm.options[i];
        max_w = max(max_w, UI_TextWidth(lbl));
    }
    var need_w = max_w + inner_pad * 4;
    var need_h = (row_h * array_length(pm.options)) + inner_pad * 2;
    var bw = min(w - 24, max(w * 0.35, need_w));
    var bh = min(h - 24, max(h * 0.24, need_h));
    var bx = (w - bw) * 0.5;
    var by = (h - bh) * 0.5;
    var popup_alpha = UI_PopupAlpha(pm.opened_frame, pm.closing, pm.close_frame, 1);

    draw_set_alpha(popup_alpha * 0.9);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(popup_alpha);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);
    draw_set_alpha(popup_alpha);

    var options = pm.options;
    var start_y = by + inner_pad;
    var text_x = bx + inner_pad;
    var text_max_w = max(24, bw - inner_pad * 2);
    for (var i = 0; i < array_length(options); i++) {
        var yy = start_y + i * row_h;
        var sel = (i == pm.index);
        var label = (i < array_length(option_labels)) ? option_labels[i] : options[i];
        if (UI_TextWidth(label) > text_max_w) {
            while (string_length(label) > 0 && UI_TextWidth(label + "...") > text_max_w) {
                label = string_delete(label, string_length(label), 1);
            }
            label += "...";
        }
        if (sel) {
            draw_set_color(c_white);
            draw_rectangle(bx + inner_pad - 4, yy - 2, bx + bw - inner_pad + 4, yy + row_h - 2, false);
            draw_set_color(c_black);
            draw_rectangle(bx + inner_pad - 4, yy - 2, bx + bw - inner_pad + 4, yy + row_h - 2, true);
        }
        draw_set_color(sel ? c_black : c_white);
        UI_DrawText(text_x, yy, label);
    }
    draw_set_alpha(1);
}

// ==========================================================================================================================
// UI FRAMEWORK (D0: D95 menu controls, D96 one shared component, D97 motion, D98 fonts, D100 details panel, D101 name tab)
// One menu = a struct { id, items[], cursor, on_confirm, on_back, on_adjust, layout }. The pure model (cursor, hold-to-scroll,
// stack, remembered cursor, hover, scroll window, motion curves) has no draw or input calls and is tested by Test_Suite_UI.
// The drawing kit sits on the GUI grid (Display_GuiW/H) and uses only the four palette colours (D10). Time is milliseconds
// (current_time), never frames. A screen builds a menu, pushes it on a stack, calls Ui_MenuUpdate in Step and Ui_StackDraw in
// Draw GUI. Screens that exist today: Title_* and SettingsPopup_* below. The rest of D96 moves over one screen at a time.
// ==========================================================================================================================
#macro UI_C_DARKEST $211807      // #071821 (GameMaker colours are BGR)
#macro UI_C_DARK $506830         // #306850
#macro UI_C_LIGHT $6CC086        // #86C06C
#macro UI_C_LIGHTEST $CFF8E0     // #E0F8CF
#macro UI_REPEAT_DELAY_MS 300    // D95: hold this long before the list starts to scroll
#macro UI_REPEAT_START_MS 140    // the first repeat gap; each next one is 20 percent shorter ...
#macro UI_REPEAT_MIN_MS 45       // ... down to this
#macro UI_PANEL_MS 120           // D97: panels slide and fade in this long
#macro SETTINGS_TEXT_SPEED_MAX 2

// ---- pure model ------------------------------------------------------------------------------------------------------------
// Next enabled index from _cur in direction _dir (+1/-1). _enabled is one bool per item. Wraps (D95) unless _wrap is false.
// Nothing enabled (or no move possible without wrapping): the cursor stays.
function Ui_CursorMove(_cur, _dir, _enabled, _wrap = true) {
    var n = array_length(_enabled);
    if (n <= 0) return 0;
    var cur = clamp(_cur, 0, n - 1);
    if (_dir == 0) return cur;
    var dir = (_dir < 0) ? -1 : 1;
    var idx = cur;
    repeat (n) {
        idx += dir;
        if (idx < 0 || idx >= n) {
            if (!_wrap) return cur;
            idx = (idx + n) mod n;
        }
        if (_enabled[idx]) return idx;
    }
    return cur;
}

function Ui_ItemEnabled(_it) {
    return !variable_struct_exists(_it, "enabled") || _it.enabled;
}

function Ui_ItemsEnabled(_items) {
    var out = array_create(array_length(_items), true);
    for (var i = 0; i < array_length(_items); i++) out[i] = Ui_ItemEnabled(_items[i]);
    return out;
}

// Hold-to-scroll (D95): one step on the press, none for UI_REPEAT_DELAY_MS, then repeats that get shorter. Returns 1 when it fires.
// _dir is -1/0/+1 (what is held), _pressed is a fresh press this frame. Call once per frame per axis.
function Ui_RepeatNew() {
    return { dir: 0, next: 0, interval: UI_REPEAT_START_MS };
}

function Ui_RepeatStep(_st, _dir, _pressed, _now) {
    if (_dir == 0) {
        _st.dir = 0;
        return 0;
    }
    if (_dir != _st.dir || _pressed) {
        _st.dir = _dir;
        _st.next = _now + UI_REPEAT_DELAY_MS;
        _st.interval = UI_REPEAT_START_MS;
        return 1;
    }
    if (_now >= _st.next) {
        _st.interval = max(UI_REPEAT_MIN_MS, _st.interval * 0.8);
        _st.next = _now + _st.interval;
        return 1;
    }
    return 0;
}

// Remembered cursor per menu id (D95).
function Ui_MemNew() {
    return {};
}

function Ui_MemSet(_mem, _id, _idx) {
    variable_struct_set(_mem, string(_id), _idx);
}

function Ui_MemGet(_mem, _id, _count) {
    if (_count <= 0 || !variable_struct_exists(_mem, string(_id))) return 0;
    return clamp(variable_struct_get(_mem, string(_id)), 0, _count - 1);
}

function Ui_MemGlobal() {
    if (!variable_global_exists("ui_mem") || !is_struct(global.ui_mem)) global.ui_mem = Ui_MemNew();
    return global.ui_mem;
}

// Which rectangle {x, y, w, h} holds the point: the top and left edges are inside, the bottom and right edges are not, so stacked
// rows have no gaps and no overlaps. A disabled row (per _enabled) is not hovered. -1 = none.
function Ui_HoverIndex(_rects, _mx, _my, _enabled = undefined) {
    for (var i = 0; i < array_length(_rects); i++) {
        var r = _rects[i];
        if (_mx >= r.x && _mx < r.x + r.w && _my >= r.y && _my < r.y + r.h) {
            if (is_array(_enabled) && i < array_length(_enabled) && !_enabled[i]) return -1;
            return i;
        }
    }
    return -1;
}

// First visible row of a list longer than its panel: keep the cursor inside the window, moving it as little as possible.
function Ui_ScrollTop(_cur, _top, _visible, _count) {
    if (_count <= _visible) return 0;
    var top = clamp(_top, 0, _count - _visible);
    if (_cur < top) top = _cur;
    if (_cur >= top + _visible) top = _cur - _visible + 1;
    return clamp(top, 0, _count - _visible);
}

function Ui_TabStep(_active, _count, _dir) {
    if (_count <= 0) return 0;
    if (_dir == 0) return clamp(_active, 0, _count - 1);
    return (_active + ((_dir < 0) ? -1 : 1) + _count) mod _count;
}

// Motion (D97). Time based. Ui_AnimT: 0..1 over _dur ms, easing out. Ui_Glide: a value that eases toward its target (frame-rate
// independent) and snaps on arrival. Ui_Bob: 0 or _amp whole UI pixels, a gentle two-state bob about every 0.4 s.
function Ui_AnimT(_start, _now, _dur = UI_PANEL_MS) {
    var t = clamp((_now - _start) / max(1, _dur), 0, 1);
    return 1 - (1 - t) * (1 - t);
}

function Ui_Glide(_cur, _target, _dt, _tau = 55) {
    var d = _target - _cur;
    if (abs(d) < 0.5) return _target;
    var v = _cur + d * (1 - exp(-max(0, _dt) / _tau));
    if (abs(_target - v) < 0.5) return _target;
    return v;
}

function Ui_Bob(_now, _amp = 1) {
    return floor(((sin(_now * pi * 2 / 800) + 1) * 0.5) * _amp + 0.5);
}

// The Korean pixel font (D98). Galmuri9 / Galmuri11 are drawn crisp only at whole multiples of their native 9 / 11 px.
// Returns { face (9 or 11), k (multiple), px (face * k) }: the multiple closest to _target_px (window pixels of line height).
function Ui_KoFontChoice(_target_px) {
    var best = undefined;
    var faces = [9, 11];
    for (var i = 0; i < 2; i++) {
        var k = max(1, round(_target_px / faces[i]));
        var px = faces[i] * k;
        var err = abs(px - _target_px);
        if (is_undefined(best) || err < best.err - 0.0001) best = { face: faces[i], k: k, px: px, err: err };
    }
    return best;
}

// ---- input snapshot: everything a menu reads in one frame ---------------------------------------------------------------------
function Ui_SnapNew() {
    return {
        up: false, down: false, left: false, right: false,
        up_p: false, down_p: false, left_p: false, right_p: false,
        confirm: false, back: false, tab: 0,
        wheel: 0, mx: -1, my: -1, mouse_moved: false, click: false, rclick: false
    };
}

// From the game's own input actions, so the keyboard, the pad and the bot all drive menus the same way. Confirm / back are
// Input_UIConfirm / Input_UIBack (today Space / Esc and pad A / B: see the report on D95's Z, Enter, X).
function Ui_ReadInput() {
    var s = Ui_SnapNew();
    s.up_p = Input_Pressed("menu_up");
    s.down_p = Input_Pressed("menu_down");
    s.left_p = Input_Pressed("menu_left");
    s.right_p = Input_Pressed("menu_right");
    s.up = s.up_p || Input_Held("menu_up");
    s.down = s.down_p || Input_Held("menu_down");
    s.left = s.left_p || Input_Held("menu_left");
    s.right = s.right_p || Input_Held("menu_right");
    s.confirm = Input_UIConfirm();
    s.back = Input_UIBack();
    s.tab = (Input_Pressed("tab_next") ? 1 : 0) - (Input_Pressed("tab_prev") ? 1 : 0);   // bound by the screens that have tabs
    var lay = Display_Layout();   // the mouse in GUI units from our own layout (window pixels minus the picture's corner, over the integer UI scale)
    s.mx = (window_mouse_get_x() - lay.gui_x) / lay.ui_scale;
    s.my = (window_mouse_get_y() - lay.gui_y) / lay.ui_scale;
    if (!variable_global_exists("ui_mouse") || !is_struct(global.ui_mouse)) global.ui_mouse = { x: s.mx, y: s.my };
    s.mouse_moved = (s.mx != global.ui_mouse.x || s.my != global.ui_mouse.y);
    global.ui_mouse.x = s.mx;
    global.ui_mouse.y = s.my;
    s.click = mouse_check_button_pressed(mb_left);
    s.rclick = mouse_check_button_pressed(mb_right);
    s.wheel = mouse_wheel_up() ? 1 : (mouse_wheel_down() ? -1 : 0);
    return s;
}

// ---- menus and the stack ----------------------------------------------------------------------------------------------------
// _opts may set on_confirm(menu, index), on_adjust(menu, index, dir) -> changed, on_back(menu, "pop"|"root"), owner, data and layout
// fields: title, anchor ("center" | "bottom"), y_frac, center (centre the labels), details (D100 panel under the list), hides_below.
function Ui_MenuNew(_id, _items, _opts) {
    var m = {
        id: _id, items: _items, cursor: 0, top: 0, rects: [],
        rep_v: Ui_RepeatNew(), rep_h: Ui_RepeatNew(),
        on_confirm: undefined, on_back: undefined, on_adjust: undefined,
        owner: noone, data: {},
        layout: { title: "", anchor: "center", y_frac: 0.5, center: false, details: false, hides_below: false },
        opened_ms: current_time, closed_ms: -1, cur_y: -1, last_draw_ms: current_time
    };
    if (is_struct(_opts)) {
        var names = variable_struct_get_names(_opts);
        for (var i = 0; i < array_length(names); i++) {
            if (names[i] == "layout") {
                var lnames = variable_struct_get_names(_opts.layout);
                for (var j = 0; j < array_length(lnames); j++) variable_struct_set(m.layout, lnames[j], variable_struct_get(_opts.layout, lnames[j]));
            } else {
                variable_struct_set(m, names[i], variable_struct_get(_opts, names[i]));
            }
        }
    }
    Ui_MenuFixCursor(m, Ui_MemGet(Ui_MemGlobal(), _id, array_length(_items)));
    return m;
}

// Puts the cursor on _want, or the next enabled item when that one is disabled.
function Ui_MenuFixCursor(_m, _want) {
    var en = Ui_ItemsEnabled(_m.items);
    var n = array_length(en);
    if (n <= 0) { _m.cursor = 0; return; }
    _want = clamp(_want, 0, n - 1);
    _m.cursor = en[_want] ? _want : Ui_CursorMove(_want, 1, en);
}

function Ui_MenuClose(_m) {
    if (_m.closed_ms < 0) _m.closed_ms = current_time;
}

// 0..1 for the panel's slide and fade: in while opening, out once closed.
function Ui_MenuAlpha(_m, _now) {
    if (_m.closed_ms >= 0) return 1 - Ui_AnimT(_m.closed_ms, _now);
    return Ui_AnimT(_m.opened_ms, _now);
}

// One frame of one menu from a snapshot. Moves the cursor and reports what happened; the caller plays sounds and calls back.
// { moved, confirm (an enabled item), back, adjust (-1/0/+1 for left/right), index (cursor after the step) }
function Ui_MenuStep(_m, _snap, _now) {
    var ev = { moved: false, confirm: false, back: false, adjust: 0, index: _m.cursor };
    var en = Ui_ItemsEnabled(_m.items);
    var n = array_length(en);
    if (n > 0) {
        _m.cursor = clamp(_m.cursor, 0, n - 1);
        var dv = (_snap.down ? 1 : 0) - (_snap.up ? 1 : 0);
        if (Ui_RepeatStep(_m.rep_v, dv, _snap.up_p || _snap.down_p, _now) > 0) {
            var c = Ui_CursorMove(_m.cursor, dv, en);
            if (c != _m.cursor) { _m.cursor = c; ev.moved = true; }
        }
        if (_snap.wheel != 0) {
            var cw = Ui_CursorMove(_m.cursor, (_snap.wheel > 0) ? -1 : 1, en, false);   // wheel up = the item above; the ends do not wrap
            if (cw != _m.cursor) { _m.cursor = cw; ev.moved = true; }
        }
        var hover = Ui_HoverIndex(_m.rects, _snap.mx, _snap.my, en);
        if (_snap.mouse_moved && hover >= 0 && hover != _m.cursor) { _m.cursor = hover; ev.moved = true; }
        if (_snap.click && hover >= 0) {
            if (hover != _m.cursor) { _m.cursor = hover; ev.moved = true; }
            ev.confirm = true;
        }
        if (_snap.confirm && en[_m.cursor]) ev.confirm = true;
        var dh = (_snap.right ? 1 : 0) - (_snap.left ? 1 : 0);
        if (Ui_RepeatStep(_m.rep_h, dh, _snap.left_p || _snap.right_p, _now) > 0) ev.adjust = dh;
    }
    if (_snap.back || _snap.rclick) ev.back = true;
    ev.index = _m.cursor;
    return ev;
}

function Ui_StackNew() {
    return { menus: [], leaving: undefined };
}

function Ui_StackPush(_stk, _menu) {
    _menu.opened_ms = current_time;
    array_push(_stk.menus, _menu);
    return _menu;
}

function Ui_StackDepth(_stk) {
    return array_length(_stk.menus);
}

function Ui_StackTop(_stk) {
    return (array_length(_stk.menus) > 0) ? _stk.menus[array_length(_stk.menus) - 1] : undefined;
}

// Back always goes up ONE level (D95): "pop" when a child was removed, "root" when the root is all that is left.
function Ui_StackBack(_stk) {
    if (array_length(_stk.menus) <= 1) return "root";
    var m = array_pop(_stk.menus);
    Ui_MemSet(Ui_MemGlobal(), m.id, m.cursor);
    m.closed_ms = current_time;
    _stk.leaving = m;
    return "pop";
}

// Step + sounds + callbacks for the top menu of a stack (or a lone menu when _stk is undefined). Returns the event.
function Ui_MenuUpdate(_m, _stk = undefined) {
    var ev = Ui_MenuStep(_m, Ui_ReadInput(), current_time);
    if (ev.moved) {
        SFX_PlayUI("ui_move");
        Ui_MemSet(Ui_MemGlobal(), _m.id, _m.cursor);
    }
    var it = (array_length(_m.items) > 0) ? _m.items[clamp(_m.cursor, 0, array_length(_m.items) - 1)] : undefined;
    if (ev.adjust != 0 && is_struct(it) && Ui_ItemEnabled(it) && is_callable(_m.on_adjust)) {
        if (_m.on_adjust(_m, _m.cursor, ev.adjust)) SFX_PlayUI("ui_move");
    }
    if (ev.confirm && is_struct(it) && variable_struct_exists(it, "kind") && it.kind == "slider") ev.confirm = false;   // a slider moves with left/right only
    if (ev.confirm) {
        SFX_PlayUI("ui_confirm");
        if (is_callable(_m.on_confirm)) _m.on_confirm(_m, ev.index);
    } else if (ev.back) {
        if (is_struct(_stk)) {
            var res = Ui_StackBack(_stk);
            if (res == "pop" || is_callable(_m.on_back)) SFX_PlayUI("ui_back");
            if (is_callable(_m.on_back)) _m.on_back(_m, res);
        } else {
            SFX_PlayUI("ui_back");
            if (is_callable(_m.on_back)) _m.on_back(_m, "root");
        }
    }
    return ev;
}

// ---- drawing kit (GUI grid, 4 colours) --------------------------------------------------------------------------------------
// One font pixel in GUI units (2 at window scale 3, 3 at scale 4, 4 at scale 5 ...): borders, gaps and arrows are whole multiples of it,
// so every edge lands on whole window pixels at every size.
function Ui_Px() {
    return max(1, round(UI_GetTextScale() * DISPLAY_FONT_PX));
}

function Ui_Metrics() {
    UI_SetFont();
    var p = Ui_Px();
    var lh = UI_TextHeight("A");
    return { p: p, line_h: lh, row_h: lh + 2 * p, pad: 2 * p, margin: 3 * p, gw: Display_GuiW(), gh: Display_GuiH() };
}

// Filled box, _x2/_y2 exclusive.
function Ui_Box(_x1, _y1, _x2, _y2, _col) {
    if (_x2 <= _x1 || _y2 <= _y1) return;
    draw_set_color(_col);
    draw_rectangle(_x1, _y1, _x2 - 1, _y2 - 1, false);
}

function Ui_Text(_x, _y, _txt, _col, _halign = fa_left) {
    draw_set_halign(_halign);
    draw_set_valign(fa_top);
    draw_set_color(_col);
    UI_DrawText(round(_x), round(_y), _txt);
    draw_set_halign(fa_left);
}

// 3p wide, 5p tall pointing right (+1) or left (-1); (_x, _y) is the top-left.
function Ui_Arrow(_x, _y, _dir, _p, _col) {
    for (var i = 0; i < 3; i++) {
        var cx = (_dir > 0) ? (_x + i * _p) : (_x + (2 - i) * _p);
        Ui_Box(cx, _y + i * _p, cx + _p, _y + (5 - i) * _p, _col);
    }
}

// The frame (D89, D96): a 1p light outline with notched corners, a 1p dark band, a dark-green fill. Border + band = 2p on every side.
function Ui_DrawFrame(_x, _y, _w, _h, _alpha = 1, _p = -1) {
    if (_p < 0) _p = Ui_Px();
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var p = _p;
    Ui_Box(_x + p, _y, _x + _w - p, _y + p, UI_C_LIGHTEST);
    Ui_Box(_x + p, _y + _h - p, _x + _w - p, _y + _h, UI_C_LIGHTEST);
    Ui_Box(_x, _y + p, _x + p, _y + _h - p, UI_C_LIGHTEST);
    Ui_Box(_x + _w - p, _y + p, _x + _w, _y + _h - p, UI_C_LIGHTEST);
    Ui_Box(_x + p, _y + p, _x + _w - p, _y + 2 * p, UI_C_DARK);
    Ui_Box(_x + p, _y + _h - 2 * p, _x + _w - p, _y + _h - p, UI_C_DARK);
    Ui_Box(_x + p, _y + 2 * p, _x + 2 * p, _y + _h - 2 * p, UI_C_DARK);
    Ui_Box(_x + _w - 2 * p, _y + 2 * p, _x + _w - p, _y + _h - 2 * p, UI_C_DARK);
    Ui_Box(_x + 2 * p, _y + 2 * p, _x + _w - 2 * p, _y + _h - 2 * p, UI_C_DARKEST);
    draw_set_alpha(a0);
}

// D101 speaker tab: a small box that sits on the top-left of a dialogue frame and opens into it (no bottom edge). (_x, _y) = the
// frame's top-left; the tab stands above it. Returns its { x, y, w, h }.
function Ui_DrawNameTab(_x, _y, _name, _alpha = 1) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var w = UI_TextWidth(_name) + 2 * (2 * p + p);
    var h = mt.line_h + 2 * p + 2 * p;
    var tx = _x + 2 * p;
    var ty = _y - h + 2 * p;   // the lower 2p overlap the frame's own border and band
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    Ui_Box(tx + p, ty, tx + w - p, ty + p, UI_C_LIGHTEST);
    Ui_Box(tx, ty + p, tx + p, ty + h, UI_C_LIGHTEST);
    Ui_Box(tx + w - p, ty + p, tx + w, ty + h, UI_C_LIGHTEST);
    Ui_Box(tx + p, ty + p, tx + w - p, ty + 2 * p, UI_C_DARK);
    Ui_Box(tx + p, ty + 2 * p, tx + 2 * p, ty + h, UI_C_DARK);
    Ui_Box(tx + w - 2 * p, ty + 2 * p, tx + w - p, ty + h, UI_C_DARK);
    Ui_Box(tx + 2 * p, ty + 2 * p, tx + w - 2 * p, ty + h, UI_C_DARKEST);
    draw_set_alpha(_alpha);
    Ui_Text(tx + 3 * p, ty + 2 * p + p, _name, UI_C_LIGHTEST);
    draw_set_alpha(a0);
    return { x: tx, y: ty, w: w, h: h };
}

// Tabs header (Q / E, or the shoulder buttons with a pad): labels left to right, the active one filled. Returns its height.
function Ui_DrawTabs(_x, _y, _w, _labels, _active, _alpha = 1) {
    var mt = Ui_Metrics();
    var p = mt.p;
    var info_l = Prompt_Info("tab_prev");   // D92: Q / E, or LB / RB with a pad in hand
    var info_r = Prompt_Info("tab_next");
    var th = mt.line_h + 2 * p;
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var tx = _x;
    tx += Prompt_DrawGlyph(tx, _y + (th - Prompt_GlyphH()) div 2, info_l, _alpha) + 2 * p;
    for (var i = 0; i < array_length(_labels); i++) {
        var lw = UI_TextWidth(_labels[i]) + 4 * p;
        var on = (i == _active);
        Ui_Box(tx, _y, tx + lw, _y + th, on ? UI_C_LIGHTEST : UI_C_DARK);
        Ui_Text(tx + 2 * p, _y + p, _labels[i], on ? UI_C_DARKEST : UI_C_LIGHT);
        tx += lw + p;
    }
    var rw = Prompt_GlyphW(info_r);
    tx = max(tx + p, _x + _w - rw);
    Prompt_DrawGlyph(tx, _y + (th - Prompt_GlyphH()) div 2, info_r, _alpha);
    draw_set_alpha(a0);
    return th;
}

// Height of wrapped text _w GUI units wide.
function Ui_TextBlockH(_txt, _w) {
    if (Prompt_HasTokens(_txt)) return Prompt_RichLayout(string(_txt), _w).h;   // a sentence with {confirm}-style prompts (D92)
    var s = max(0.0001, UI_GetFontScale());
    return round(string_height_ext(string(_txt), -1, max(1, round(_w / s))) * s);
}

function Ui_TextBlock(_x, _y, _txt, _w, _col) {
    if (Prompt_HasTokens(_txt)) { Prompt_RichDraw(_x, _y, string(_txt), _w, _col); return; }
    var s = max(0.0001, UI_GetFontScale());
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(_col);
    draw_text_ext_transformed(round(_x), round(_y), string(_txt), -1, max(1, round(_w / s)), s, s, 0);
}

// D100 details panel: one plain sentence, then number lines [{ label, value }] (generated from the real game data by the caller).
function Ui_DetailsHeight(_w, _sentence, _lines) {
    var mt = Ui_Metrics();
    var inner = _w - 2 * (4 * mt.p);
    var h = 2 * (2 * mt.p + mt.pad) + Ui_TextBlockH(_sentence, inner);
    if (array_length(_lines) > 0) h += mt.p * 2 + array_length(_lines) * (mt.line_h + mt.p);
    return h;
}

function Ui_DrawDetails(_x, _y, _w, _h, _sentence, _lines, _alpha = 1) {
    var mt = Ui_Metrics();
    var p = mt.p;
    Ui_DrawFrame(_x, _y, _w, _h, _alpha, p);
    var a0 = draw_get_alpha();
    draw_set_alpha(_alpha);
    var x0 = _x + 4 * p;
    var x1 = _x + _w - 4 * p;
    var ty0 = _y + 4 * p;
    Ui_TextBlock(x0, ty0, _sentence, x1 - x0, UI_C_LIGHTEST);
    ty0 += Ui_TextBlockH(_sentence, x1 - x0);
    if (array_length(_lines) > 0) {
        ty0 += p;
        Ui_Box(x0, ty0, x1, ty0 + p, UI_C_DARK);
        ty0 += p;
        for (var i = 0; i < array_length(_lines); i++) {
            Ui_Text(x0, ty0, _lines[i].label, UI_C_LIGHT);
            Ui_Text(x1, ty0, _lines[i].value, UI_C_LIGHTEST, fa_right);
            ty0 += mt.line_h + p;
        }
    }
    draw_set_alpha(a0);
}

// Draws one menu: frame, optional title, rows (label left, value / slider right), the gliding highlight with a bobbing marker, and
// the details panel of the highlighted item when layout.details is set. _alpha 0..1 fades and slides the panel (D97).
// Stores each row's rectangle in m.rects for the mouse. Needs UI_SetFont-compatible state; sets and restores the draw state.
function Ui_MenuDraw(_m, _alpha = 1) {
    if (_alpha <= 0) return;
    var mt = Ui_Metrics();
    var p = mt.p;
    var L = _m.layout;
    var n = array_length(_m.items);
    var now = current_time;
    var a0 = draw_get_alpha();
    var c0 = draw_get_color();
    var bar_w = 14 * p;

    // widths
    var label_w = 0;
    var val_w = 0;
    for (var i = 0; i < n; i++) {
        var it = _m.items[i];
        label_w = max(label_w, UI_TextWidth(it.label));
        var kind = variable_struct_exists(it, "kind") ? it.kind : "button";
        var vw = 0;
        if (kind == "slider") {
            vw = bar_w + 2 * p + UI_TextWidth("100%");
        } else if (variable_struct_exists(it, "value") && it.value != "") {
            var texts = variable_struct_exists(it, "measure") ? it.measure : [it.value];
            for (var t = 0; t < array_length(texts); t++) vw = max(vw, UI_TextWidth(texts[t]));
            if (kind == "choice") vw += 10 * p;
        }
        val_w = max(val_w, vw);
    }
    var title_w = (L.title != "") ? UI_TextWidth(L.title) : 0;
    var inner_w = max(5 * p + label_w + ((val_w > 0) ? 4 * p + val_w : 0), title_w);
    var chrome_x = 2 * (4 * p);
    var panel_w = min(inner_w + chrome_x, mt.gw - 2 * mt.margin);
    if (L.details) panel_w = min(max(panel_w, round(mt.gw * 0.78)), mt.gw - 2 * mt.margin);
    var header_h = (L.title != "") ? (mt.line_h + 3 * p) : 0;
    var chrome_y = 2 * (4 * p) + header_h;

    // the details panel's height is the tallest sentence, so the list does not jump between items
    var det_h = 0;
    if (L.details) {
        for (var d = 0; d < n; d++) {
            var di = _m.items[d];
            if (variable_struct_exists(di, "help")) det_h = max(det_h, Ui_DetailsHeight(panel_w, di.help, variable_struct_exists(di, "lines") ? di.lines : []));
        }
    }
    var avail_h = mt.gh - 2 * mt.margin - ((det_h > 0) ? det_h + mt.margin : 0);
    var rows_vis = clamp(floor((avail_h - chrome_y) / mt.row_h), 1, max(1, n));
    var panel_h = chrome_y + rows_vis * mt.row_h;
    var total_h = panel_h + ((det_h > 0) ? mt.margin + det_h : 0);
    var px = round((mt.gw - panel_w) / 2);
    var py;
    if (L.anchor == "bottom") py = clamp(round(mt.gh * L.y_frac), mt.margin, max(mt.margin, mt.gh - mt.margin - total_h));
    else py = max(mt.margin, round((mt.gh - total_h) / 2));
    var slide = p * round((1 - _alpha) * 3);   // slides down into place in three pixel steps
    py += -slide;

    _m.top = Ui_ScrollTop(_m.cursor, _m.top, rows_vis, n);
    Ui_DrawFrame(px, py, panel_w, panel_h, _alpha, p);
    draw_set_alpha(_alpha);

    var x0 = px + 4 * p;
    var x1 = px + panel_w - 4 * p;
    var ty0 = py + 4 * p;
    if (L.title != "") {
        Ui_Text(x0, ty0, L.title, UI_C_LIGHT);
        Ui_Box(px + 3 * p, ty0 + mt.line_h + p, px + panel_w - 3 * p, ty0 + mt.line_h + 2 * p, UI_C_DARK);
        ty0 += header_h;
    }
    var rows_y0 = ty0;

    // rectangles for the mouse (rows outside the window can't be hit)
    var rects = array_create(n);
    for (var r = 0; r < n; r++) {
        var vis = (r >= _m.top && r < _m.top + rows_vis);
        rects[r] = { x: px + 2 * p, y: rows_y0 + (r - _m.top) * mt.row_h, w: vis ? (panel_w - 4 * p) : 0, h: vis ? mt.row_h : 0 };
    }
    _m.rects = rects;

    // gliding highlight band
    var target_y = rows_y0 + (_m.cursor - _m.top) * mt.row_h;
    if (_m.cur_y < 0) _m.cur_y = target_y;
    _m.cur_y = Ui_Glide(_m.cur_y, target_y, now - _m.last_draw_ms);
    _m.last_draw_ms = now;
    var band_y = round(_m.cur_y);
    if (n > 0) Ui_Box(px + 2 * p + p, band_y, px + panel_w - 2 * p - p, band_y + mt.row_h, UI_C_DARK);

    for (var k = _m.top; k < min(n, _m.top + rows_vis); k++) {
        var row = _m.items[k];
        var ry = rows_y0 + (k - _m.top) * mt.row_h;
        var ty = ry + (mt.row_h - mt.line_h) div 2;
        var sel = (k == _m.cursor);
        var en = Ui_ItemEnabled(row);
        var kd = variable_struct_exists(row, "kind") ? row.kind : "button";
        var col = !en ? UI_C_DARK : (sel ? UI_C_LIGHTEST : UI_C_LIGHT);
        var label_x = x0 + 5 * p;
        if (L.center) Ui_Text((x0 + x1) / 2, ty, row.label, col, fa_center);
        else Ui_Text(label_x, ty, row.label, col);
        var vx = x1;
        if (kd == "choice" && variable_struct_exists(row, "value")) {
            if (sel && en) {
                Ui_Arrow(x1 - 3 * p, ry + (mt.row_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
            }
            vx = x1 - 5 * p;
            Ui_Text(vx, ty, row.value, col, fa_right);
            if (sel && en) {
                Ui_Arrow(vx - UI_TextWidth(row.value) - 5 * p, ry + (mt.row_h - 5 * p) div 2, -1, p, UI_C_LIGHTEST);
            }
        } else if (kd == "slider") {
            Ui_Text(x1, ty, row.value, col, fa_right);
            var bx = x1 - UI_TextWidth("100%") - 2 * p - bar_w;
            var by = ry + (mt.row_h - 2 * p) div 2;
            Ui_Box(bx, by, bx + bar_w, by + 2 * p, sel ? UI_C_DARKEST : UI_C_DARK);
            var fill = floor(clamp(row.amount, 0, 1) * (bar_w / p) + 0.5) * p;
            Ui_Box(bx, by, bx + fill, by + 2 * p, sel ? UI_C_LIGHTEST : UI_C_LIGHT);
        } else if (variable_struct_exists(row, "value") && row.value != "") {
            Ui_Text(x1, ty, row.value, col, fa_right);
        }
    }
    // marker: follows the glide, bobs one pixel
    if (n > 0) {
        Ui_Arrow(x0 + Ui_Bob(now) * p, band_y + (mt.row_h - 5 * p) div 2, 1, p, UI_C_LIGHTEST);
    }
    // a scroll hint when the list is longer than its window
    if (n > rows_vis) {
        if (_m.top > 0) Ui_Box(px + panel_w - 4 * p, rows_y0 - p, px + panel_w - 3 * p, rows_y0, UI_C_LIGHT);
        if (_m.top + rows_vis < n) Ui_Box(px + panel_w - 4 * p, rows_y0 + rows_vis * mt.row_h, px + panel_w - 3 * p, rows_y0 + rows_vis * mt.row_h + p, UI_C_LIGHT);
    }

    if (det_h > 0 && n > 0) {
        var cur = _m.items[_m.cursor];
        if (variable_struct_exists(cur, "help")) {
            Ui_DrawDetails(px, py + panel_h + mt.margin, panel_w, det_h, cur.help, variable_struct_exists(cur, "lines") ? cur.lines : [], _alpha);
        }
    }
    draw_set_alpha(a0);
    draw_set_color(c0);
}

// Draws a stack bottom to top from the last menu that hides what is below it, plus a menu that is on its way out. Each menu above
// the first dims what is under it. Menus alpha-fade with Ui_MenuAlpha.
function Ui_StackDraw(_stk, _dim_alpha = 0.6) {
    var n = array_length(_stk.menus);
    var from = 0;
    for (var i = 0; i < n; i++) if (_stk.menus[i].layout.hides_below) from = i;
    var now = current_time;
    if (is_struct(_stk.leaving) && Ui_MenuAlpha(_stk.leaving, now) <= 0) _stk.leaving = undefined;
    var gw = Display_GuiW();
    var gh = Display_GuiH();
    for (var j = from; j < n; j++) {
        var m = _stk.menus[j];
        var a = Ui_MenuAlpha(m, now);
        if (j > from) Ui_DimBackdrop(_dim_alpha * a);
        Ui_MenuDraw(m, a);
    }
    if (is_struct(_stk.leaving)) {
        var lv = _stk.leaving;
        var la = Ui_MenuAlpha(lv, now);
        if (n > 0) Ui_DimBackdrop(_dim_alpha * la);
        Ui_MenuDraw(lv, la);
    }
}

function Ui_DimBackdrop(_a) {
    if (_a <= 0) return;
    var a0 = draw_get_alpha();
    draw_set_alpha(_a);
    Ui_Box(0, 0, Display_GuiW(), Display_GuiH(), UI_C_DARKEST);
    draw_set_alpha(a0);
}
