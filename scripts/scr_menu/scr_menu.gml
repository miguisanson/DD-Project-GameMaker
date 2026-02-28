function Menu_StatsCopy(_s) {
    return { str: _s.str, agi: _s.agi, def: _s.def, intt: _s.intt, luck: _s.luck };
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
            tabs: ["Inventory","Skills","Stats"],
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
    var w = display_get_gui_width();
    var h = display_get_gui_height();
    UI_SetFont();
    var line_h = string_height("A");
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
    switch (_stat_id) {
        case STAT_STR:  return "STR";
        case STAT_AGI:  return "AGI";
        case STAT_DEF:  return "DEF";
        case STAT_INT:  return "INT";
        case STAT_LUCK: return "LUCK";
    }
    return "N/A";
}

function Tooltip_TargetName(_target_id) {
    switch (_target_id) {
        case TGT_SELF: return "Self";
        case TGT_ENEMY: return "Opponent";
        case TGT_ALL_ENEMIES: return "All Opponents";
        case TGT_ALL_ALLIES: return "All Allies";
        case TGT_ALL: return "All";
    }
    return "Unknown";
}

function Tooltip_ClassListText(_class_list) {
    if (!is_array(_class_list) || array_length(_class_list) <= 0) return "All Classes";
    var txt = "";
    for (var i = 0; i < array_length(_class_list); i++) {
        if (i > 0) txt += "/";
        txt += Equip_ClassName(_class_list[i]);
    }
    return txt;
}

function Tooltip_StatusName(_status_id) {
    if (_status_id == -1) return "";
    var cfg = StatusDB_Get(_status_id);
    if (is_struct(cfg) && variable_struct_exists(cfg, "name")) return string(cfg.name);
    return "Status";
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
    txt = string_replace_all(txt, "->", " to ");
    txt = string_replace_all(txt, "1/turn", "once per turn");
    txt = string_replace_all(txt, "(cd", "(cooldown");
    txt = string_replace_all(txt, "cd ", "cooldown ");
    txt = string_replace_all(txt, "GOOD+:", "GOOD or PERFECT:");
    txt = string_replace_all(txt, "GOOD+", "GOOD or PERFECT");
    return txt;
}

function Tooltip_BuildStatLines(_stat_key, _stat_label, _cur, _base, _pending_pts, _selected_col) {
    var lines = [];
    array_push(lines, _stat_label + " (" + string(_cur) + ")");
    var delta = _cur - _base;
    if (delta > 0) {
        array_push(lines, "Pending bonus: +" + string(delta));
    } else {
        array_push(lines, "Pending bonus: +0");
    }

    switch (_stat_key) {
        case "str":
            array_push(lines, "Increases physical damage for weapon attacks.");
        break;
        case "agi":
            array_push(lines, "Improves turn order and evasion potential.");
        break;
        case "def":
            array_push(lines, "Reduces incoming damage through mitigation.");
        break;
        case "intt":
            array_push(lines, "Increases skill damage and magical output.");
        break;
        case "luck":
            array_push(lines, "Improves critical chance and random checks.");
        break;
        default:
            array_push(lines, "Affects combat performance.");
        break;
    }

    if (_selected_col == 1) {
        if (_pending_pts > 0) array_push(lines, "Press Confirm on + to spend 1 point.");
        else array_push(lines, "No points available to add.");
    } else {
        if (delta > 0) array_push(lines, "Press Confirm on - to refund 1 pending point.");
        else array_push(lines, "Nothing to refund on this stat.");
    }
    return lines;
}

function Tooltip_ItemBonusText(_item) {
    if (!is_struct(_item) || !variable_struct_exists(_item, "bonus") || !is_struct(_item.bonus)) return "";
    var b = _item.bonus;
    var parts = [];
    if (variable_struct_exists(b, "str") && b.str != 0) array_push(parts, "STR " + ((b.str > 0) ? "+" : "") + string(b.str));
    if (variable_struct_exists(b, "agi") && b.agi != 0) array_push(parts, "AGI " + ((b.agi > 0) ? "+" : "") + string(b.agi));
    if (variable_struct_exists(b, "def") && b.def != 0) array_push(parts, "DEF " + ((b.def > 0) ? "+" : "") + string(b.def));
    if (variable_struct_exists(b, "intt") && b.intt != 0) array_push(parts, "INT " + ((b.intt > 0) ? "+" : "") + string(b.intt));
    if (variable_struct_exists(b, "luck") && b.luck != 0) array_push(parts, "LUCK " + ((b.luck > 0) ? "+" : "") + string(b.luck));
    if (array_length(parts) <= 0) return "";
    var txt = parts[0];
    for (var i = 1; i < array_length(parts); i++) txt += ", " + parts[i];
    return txt;
}

function Tooltip_ItemTypeLine(_item) {
    if (!is_struct(_item) || !variable_struct_exists(_item, "type")) return "Unknown";
    if (Item_IsSkillbook(_item)) return "Skillbook";
    if (_item.type == ITEM_WEAPON || _item.type == ITEM_ARMOR) {
        var slot_name = variable_struct_exists(_item, "equip_slot") ? string(_item.equip_slot) : "";
        var type_name = (_item.type == ITEM_WEAPON) ? "Weapon" : "Armor";
        if (slot_name != "") return type_name + " (slot: " + slot_name + ")";
        return type_name;
    }
    if (_item.type == ITEM_CONSUMABLE) return "Consumable";
    if (_item.type == ITEM_KEY) return "Key Item";
    return "Unknown";
}

function Tooltip_BuildItemLines(_item) {
    var lines = [];
    if (!is_struct(_item) || !variable_struct_exists(_item, "id") || _item.id == 0) return lines;

    array_push(lines, string(_item.name));
    if (!Item_IsSkillbook(_item)) {
        array_push(lines, Tooltip_ItemTypeLine(_item));
    }

    if (_item.type == ITEM_WEAPON || _item.type == ITEM_ARMOR) {
        var parts = ["Power " + string(max(0, round(real(_item.power))))];
        if (variable_struct_exists(_item, "acc") && _item.acc != 0) {
            array_push(parts, "Acc " + ((_item.acc > 0) ? "+" : "") + string(_item.acc));
        }
        if (variable_struct_exists(_item, "stat_type")) {
            array_push(parts, "Stat " + Tooltip_StatShortName(_item.stat_type));
        }
        var core = parts[0];
        for (var i = 1; i < array_length(parts); i++) core += " | " + parts[i];
        array_push(lines, core);
        if (variable_struct_exists(_item, "equip_slot") && string(_item.equip_slot) == "weapon") {
            if (variable_struct_exists(_item, "stat_type")) {
                array_push(lines, "Built around " + Tooltip_StatShortName(_item.stat_type) + " scaling.");
            }
        }

        var bonus_txt = Tooltip_ItemBonusText(_item);
        if (bonus_txt != "") array_push(lines, "Bonus: " + bonus_txt);

        if (variable_struct_exists(_item, "passive_desc") && is_array(_item.passive_desc) && array_length(_item.passive_desc) > 0) {
            var passive_line = "Trait: " + string(_item.passive_desc[0]);
            if (array_length(_item.passive_desc) > 1) {
                passive_line += " - " + Tooltip_PassiveLineHuman(_item.passive_desc[1]);
            }
            array_push(lines, passive_line);
            for (var pidx = 2; pidx < array_length(_item.passive_desc); pidx++) {
                array_push(lines, Tooltip_PassiveLineHuman(_item.passive_desc[pidx]));
            }
        }

        var class_txt = "All Classes";
        if (variable_struct_exists(_item, "preferred_class") && _item.preferred_class != -1) {
            class_txt = Equip_ClassName(_item.preferred_class);
        } else if (variable_struct_exists(_item, "allowed_classes") && is_array(_item.allowed_classes)) {
            class_txt = Tooltip_ClassListText(_item.allowed_classes);
        }
        if (class_txt != "All Classes") array_push(lines, "Class: " + class_txt);
        return lines;
    }

    if (_item.type == ITEM_CONSUMABLE && variable_struct_exists(_item, "use") && is_struct(_item.use)) {
        var use = _item.use;
        var eff = variable_struct_exists(use, "effect") ? string(use.effect) : "none";
        switch (eff) {
            case "heal":
                var hmin = variable_struct_exists(use, "min") ? round(real(use.min)) : round(real(use.power));
                var hmax = variable_struct_exists(use, "max") ? round(real(use.max)) : hmin;
                var hline = "Heal HP " + string(hmin) + "-" + string(hmax);
                if (variable_struct_exists(use, "scale") && real(use.scale) > 0) {
                    array_push(lines, hline);
                    array_push(lines, "Amount scales with level.");
                } else {
                    array_push(lines, hline);
                }
            break;
            case "mp":
                var mmin = variable_struct_exists(use, "min") ? round(real(use.min)) : round(real(use.power));
                var mmax = variable_struct_exists(use, "max") ? round(real(use.max)) : mmin;
                var mline = "Restore MP " + string(mmin) + "-" + string(mmax);
                if (variable_struct_exists(use, "scale") && real(use.scale) > 0) {
                    array_push(lines, mline);
                    array_push(lines, "Amount scales with level.");
                } else {
                    array_push(lines, mline);
                }
            break;
            case "cure":
                array_push(lines, "Cure: " + Tooltip_StatusName(use.status));
            break;
            case "learn_skill":
                var skill = SkillDB_Get(use.skill_id);
                if (is_struct(skill) && skill.id != -1) {
                    array_push(lines, "Teaches: " + string(skill.name));
                    var mp_cost = variable_struct_exists(skill, "mp_cost") ? max(0, round(real(skill.mp_cost))) : 0;
                    var target_txt = variable_struct_exists(skill, "target") ? Tooltip_TargetName(skill.target) : "Unknown";
                    array_push(lines, "MP " + string(mp_cost) + " | Target: " + target_txt);
                    if (variable_struct_exists(skill, "effect")) {
                        var skill_eff = string(skill.effect);
                        if (skill_eff == "damage") {
                            var eff_line = "Effect: Damage";
                            if (variable_struct_exists(skill, "hits") && skill.hits > 1) {
                                eff_line += " (" + string(round(real(skill.hits))) + " hits)";
                            }
                            if (variable_struct_exists(skill, "status") && skill.status != -1) {
                                eff_line += ", may inflict " + Tooltip_StatusName(skill.status);
                            }
                            array_push(lines, eff_line);
                        } else if (skill_eff == "status") {
                            if (variable_struct_exists(skill, "status") && skill.status != -1) {
                                var turns = variable_struct_exists(skill, "status_turns") ? max(1, round(real(skill.status_turns))) : 1;
                                array_push(lines, "Effect: Apply " + Tooltip_StatusName(skill.status) + " (" + string(turns) + " turns)");
                            } else {
                                array_push(lines, "Effect: Apply a buff");
                            }
                        } else if (skill_eff == "heal") {
                            array_push(lines, "Effect: Restore HP");
                        } else if (skill_eff == "multi_status") {
                            array_push(lines, "Effect: Apply multiple statuses");
                        } else if (skill_eff == "steal_item") {
                            array_push(lines, "Effect: Steal one random item");
                        }
                    }
                    var sb_classes = Tooltip_ClassListText(skill.class_list);
                    if (sb_classes != "All Classes") array_push(lines, "Class: " + sb_classes);
                } else {
                    array_push(lines, "Teaches: Unknown skill");
                }
            break;
            default:
                array_push(lines, "Effect: " + eff);
            break;
        }
    }

    return lines;
}

function Tooltip_BuildSkillLines(_skill) {
    var lines = [];
    if (!is_struct(_skill) || !variable_struct_exists(_skill, "id") || _skill.id == -1) return lines;

    array_push(lines, string(_skill.name));
    var mp_line = "MP " + string(max(0, round(real(_skill.mp_cost))));
    var tgt = variable_struct_exists(_skill, "target") ? _skill.target : TGT_ENEMY;
    mp_line += " | Target: " + Tooltip_TargetName(tgt);
    array_push(lines, mp_line);

    var class_list = variable_struct_exists(_skill, "class_list") && is_array(_skill.class_list) ? _skill.class_list : [];
    var class_txt = Tooltip_ClassListText(class_list);
    if (class_txt != "All Classes") array_push(lines, "Class: " + class_txt);

    if (_skill.effect == "damage") {
        var dmg_parts = ["Damage: Power " + string(max(0, round(real(_skill.power))))];
        var pm = variable_struct_exists(_skill, "power_mult") ? real(_skill.power_mult) : 1;
        if (pm != 1) array_push(dmg_parts, "x" + string_format(pm, 1, 2));
        if (variable_struct_exists(_skill, "hits") && _skill.hits > 1) array_push(dmg_parts, "Hits " + string(round(real(_skill.hits))));
        if (variable_struct_exists(_skill, "acc") && _skill.acc != 0) array_push(dmg_parts, "Acc " + ((_skill.acc > 0) ? "+" : "") + string(_skill.acc));
        if (variable_struct_exists(_skill, "stat_type")) array_push(dmg_parts, "Stat " + Tooltip_StatShortName(_skill.stat_type));
        var dmg_line = dmg_parts[0];
        for (var i = 1; i < array_length(dmg_parts); i++) dmg_line += " | " + dmg_parts[i];
        array_push(lines, dmg_line);
    } else if (_skill.effect == "heal") {
        array_push(lines, "Effect: Restore HP");
    } else if (_skill.effect == "status") {
        array_push(lines, "Effect: Apply status");
    } else if (_skill.effect == "multi_status") {
        array_push(lines, "Effect: Apply multiple statuses");
    } else if (_skill.effect == "steal_item") {
        array_push(lines, "Effect: Steal one random item");
    } else {
        array_push(lines, "Effect: " + string(_skill.effect));
    }

    if (variable_struct_exists(_skill, "status") && _skill.status != -1) {
        var turns = variable_struct_exists(_skill, "status_turns") ? max(1, round(real(_skill.status_turns))) : 1;
        var chance = variable_struct_exists(_skill, "status_chance") ? clamp(real(_skill.status_chance), 0, 1) : 1;
        array_push(lines, "Applies: " + Tooltip_StatusName(_skill.status) + " (" + string(round(chance * 100)) + "%, " + string(turns) + " turns)");
    }

    if (variable_struct_exists(_skill, "status_list") && is_array(_skill.status_list) && array_length(_skill.status_list) > 0) {
        for (var sidx = 0; sidx < array_length(_skill.status_list); sidx++) {
            var sid = _skill.status_list[sidx];
            if (sid == -1) continue;
            var turns2 = variable_struct_exists(_skill, "status_turns") ? max(1, round(real(_skill.status_turns))) : 1;
            if (variable_struct_exists(_skill, "status_turns_list") && is_array(_skill.status_turns_list) && sidx < array_length(_skill.status_turns_list)) {
                turns2 = max(1, round(real(_skill.status_turns_list[sidx])));
            }
            array_push(lines, "Applies: " + Tooltip_StatusName(sid) + " (" + string(turns2) + " turns)");
        }
    }

    return lines;
}

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
        s.text_scale = 1.00;
        s.line_gap = 1;
        s.min_w = 62;
        s.min_h = 72;
        s.margin_px = 0;
        s.width_ratio = 1.00;
        s.height_ratio = 0.36;
    } else if (_context == "battle") {
        s.pad = 5;
        s.text_scale = 1.00;
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
    var gui_w = max(1, display_get_gui_width());
    var gui_h = max(1, display_get_gui_height());
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
    var line_h = max(5, floor(string_height("A") * text_scale) + style.line_gap);
    var max_text_w = max(1, floor((rect.w - pad * 2) / text_scale));
    var wrapped = [];
    for (var i = 0; i < array_length(_lines); i++) {
        var line_txt = string(_lines[i]);
        if (line_txt == "") {
            array_push(wrapped, "");
            continue;
        }
        wrapped = Tooltip_AddWrappedLines(wrapped, line_txt, max_text_w);
    }

    var max_lines = max(1, floor((rect.h - pad * 2) / line_h));
    if (array_length(wrapped) > max_lines) {
        array_resize(wrapped, max_lines);
    }

    var a = clamp(real(_alpha), 0, 1);
    draw_set_alpha(a * style.frame_alpha_mult);
    draw_set_color(c_black);
    draw_rectangle(rect.x, rect.y, rect.x + rect.w, rect.y + rect.h, false);
    draw_set_alpha(a);
    draw_set_color(c_white);
    draw_rectangle(rect.x, rect.y, rect.x + rect.w, rect.y + rect.h, true);

    var draw_y = rect.y + pad;
    for (var j = 0; j < array_length(wrapped); j++) {
        draw_text_transformed(rect.x + pad, draw_y, wrapped[j], text_scale, text_scale, 0);
        draw_y += line_h;
        if (draw_y > rect.y + rect.h - pad) break;
    }
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

function Menu_ClampInventoryCursor(_m, _inventory) {
    var inv_count = is_array(_inventory) ? array_length(_inventory) : 0;
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
        out.menu = Menu_InvPopupOpenMessage(_m, "Can't use that.");
        return out;
    }

    if (Item_IsSkillbook(item)) {
        out.menu = Menu_InvPopupOpenConfirm(_m, item.id);
        return out;
    }

    if (item.type == ITEM_WEAPON || item.type == ITEM_ARMOR) {
        var slot_name = variable_struct_exists(item, "equip_slot") ? string(item.equip_slot) : "";
        if (slot_name != "" && Equip_SlotGet(_ch, slot_name) == item.id) {
            Equip_SlotSet(_ch, slot_name, 0);
            _ch = RecomputeResources(_ch);
            _m = Menu_ClampInventoryCursor(_m, _ch.inventory);
            out.menu = Menu_InvPopupOpenMessage(_m, "Unequipped " + item.name + ".");
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
            out.menu = Menu_InvPopupOpenMessage(_m, "Equipped " + item.name + ".");
            out.ch = _ch;
            out.changed = true;
            return out;
        }

        out.menu = Menu_InvPopupOpenMessage(_m, "Can't equip that.");
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

    out.menu = Menu_InvPopupOpenMessage(_m, "Can't use that.");
    return out;
}

function Menu_InvPopupOpenConfirm(_m, _item_id) {
    _m.inv_popup_open = true;
    _m.inv_popup_closing = false;
    _m.inv_popup_close_frame = UI_OPENED_FRAME_NONE;
    _m.inv_popup_mode = "confirm";
    _m.inv_popup_choice = 1; // default to Cancel
    _m.inv_popup_message = "Learn a skill";
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

                        if (variable_struct_exists(use_result, "skillbook_first_read_dialogue") && use_result.skillbook_first_read_dialogue) {
                            m = Menu_InvPopupClose(m, true);
                            gs.ui.menu = m;
                            Menu_Close(true);
                            Dialogue_TryStartSkillbookFirstRead(ch.class_id);
                            return;
                        }
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
                }
                SFX_PlayUI("ui_move");
            }
        }
        return;
    }

    var layout = Menu_GetLayout();
    var rows_visible = layout.rows_visible;

    if (m.tab == 0) {
        var items = is_array(ch.inventory) ? ch.inventory : [];
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
                m = Menu_InvPopupOpenMessage(m, "Can't use that.");
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
        if (!is_struct(m.pending_stats)) Menu_StatsSync();
        var stat_keys = ["str","agi","def","intt","luck"];
        var stat_count = array_length(stat_keys);
        var pending_total = 0;
        for (var pidx = 0; pidx < stat_count; pidx++) {
            var base_v = variable_struct_get(m.base_stats, stat_keys[pidx]);
            var cur_v = variable_struct_get(m.pending_stats, stat_keys[pidx]);
            if (cur_v > base_v) pending_total += (cur_v - base_v);
        }
        var show_actions = (pending_total > 0);
        var action_row = stat_count;
        var row_count = stat_count + (show_actions ? 1 : 0); // action row

        // If Confirm/Cancel row just became unavailable, snap selection back to nearest stat row.
        if (!show_actions && m.stats_row >= action_row) {
            m.stats_row = max(0, stat_count - 1);
            m.stats_col = 1;
        }
        m.stats_row = clamp(m.stats_row, 0, max(0, row_count - 1));
        m.stats_col = clamp(m.stats_col, 0, 1);

        if (!m.stats_focus) {
            if (k_ok || nav_down || nav_up) {
                m.stats_focus = true;
                m.stats_row = 0;
                m.stats_col = 1;
                if (k_ok) SFX_PlayUI("ui_confirm");
                else SFX_PlayUI("ui_move");
            }
            return;
        }

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
            if (m.stats_row < row_count - 1) {
                m.stats_row += 1;
                SFX_PlayUI("ui_move");
            }
        }

        if (m.stats_row < stat_count) {
            if (k_left && m.stats_col != 0) {
                m.stats_col = 0;
                SFX_PlayUI("ui_move");
            }
            if (k_right && m.stats_col != 1) {
                m.stats_col = 1;
                SFX_PlayUI("ui_move");
            }
        } else {
            if (k_left || k_right) {
                m.stats_col = 1 - m.stats_col;
                SFX_PlayUI("ui_move");
            }
        }

        if (k_ok) {
            SFX_PlayUI("ui_confirm");
            if (m.stats_row < stat_count) {
                var key = stat_keys[m.stats_row];
                var base_v = variable_struct_get(m.base_stats, key);
                var cur_v = variable_struct_get(m.pending_stats, key);

                if (m.stats_col == 1 && m.pending_points > 0) {
                    if (cur_v < STAT_MAX) {
                        variable_struct_set(m.pending_stats, key, cur_v + 1);
                        m.pending_points -= 1;
                    }
                }
                if (m.stats_col == 0 && cur_v > base_v) {
                    variable_struct_set(m.pending_stats, key, cur_v - 1);
                    m.pending_points += 1;
                }
            } else if (show_actions) {
                if (m.stats_col == 0) {
                    Menu_StatsApply();
                } else {
                    Menu_StatsDiscard();
                }
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
        if (tab_hi) {
            draw_set_color(c_white);
            draw_rectangle(tx, by, tx + tab_w, by + header_h, false);
            draw_set_color(c_black);
            draw_rectangle(tx, by, tx + tab_w, by + header_h, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        draw_text(tx + 6, by + 6, m.tabs[i]);
    }

    var draw_arrow_sprite = dialogue_arrow_down;
    var draw_arrow_w = max(1, sprite_get_width(draw_arrow_sprite));
    var draw_arrow_h = max(1, sprite_get_height(draw_arrow_sprite));
    var draw_arrow_scale_x = 16 / draw_arrow_w;
    var draw_arrow_scale_y = 16 / draw_arrow_h;
    var draw_arrow_size = 16;
    var draw_arrow_x = round(bx + bw * 0.5 - (draw_arrow_size * 0.5));
    var draw_arrow_top_y = round(layout.content_y + max(0, floor((list_top_inset - draw_arrow_size) * 0.5)));
    var draw_arrow_bottom_y = round(content_list_y + content_list_h + max(0, floor((list_bottom_inset - draw_arrow_size) * 0.5)));

    // Inventory tab
    if (m.tab == 0) {
        var items = is_array(ch.inventory) ? ch.inventory : [];
        var count = array_length(items);
        var start = clamp(m.inv_scroll, 0, max(0, count - rows_visible));
        var endv = min(count, start + rows_visible);

        if (count == 0) {
            draw_set_color(c_white);
            draw_text(bx + pad, content_list_y, "No items.");
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
                    draw_sprite(item.sprite, 0, tx, yy + 2);
                    tx += 16;
                }
                var label = item.name;
                if (item.stackable) label += " x" + string(inv.qty);
                draw_set_color(sel ? c_black : c_white);
                draw_text(tx, yy, label);

                if (Menu_IsEquipped(ch, inv.id)) {
                    draw_set_color(sel ? c_black : c_white);
                    draw_text(bx + bw - pad - string_width("E"), yy, "E");
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
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_top_y + draw_arrow_size, draw_arrow_scale_x, -draw_arrow_scale_y, 0, c_white, menu_alpha);
            }
            if (endv < count) {
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_bottom_y, draw_arrow_scale_x, draw_arrow_scale_y, 0, c_white, menu_alpha);
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
            draw_text(bx + pad, content_list_y, "No skills.");
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
                    draw_sprite(sk.icon_sprite, 0, tx2, y2 + 2);
                    tx2 += 16;
                }
                draw_set_color(sel2 ? c_black : c_white);
                draw_text(tx2, y2, sk.name);
            }
        }

        if (!m.header_focus && scount > 0 && m.skill_index >= 0 && m.skill_index < scount) {
            var sel_skill = SkillDB_Get(skills[m.skill_index]);
            tooltip_lines = Tooltip_BuildSkillLines(sel_skill);
        }

        if (scount > rows_visible) {
            draw_set_color(c_white);
            if (start2 > 0) {
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_top_y + draw_arrow_size, draw_arrow_scale_x, -draw_arrow_scale_y, 0, c_white, menu_alpha);
            }
            if (end2 < scount) {
                draw_sprite_ext(draw_arrow_sprite, 0, draw_arrow_x, draw_arrow_bottom_y, draw_arrow_scale_x, draw_arrow_scale_y, 0, c_white, menu_alpha);
            }
        }
    }

    // Stats tab (main layout)
    if (m.tab == 2) {
        if (!is_struct(m.pending_stats)) Menu_StatsSync();

        var stat_names = ["STR","AGI","DEF","INT","LUCK"];
        var stat_keys = ["str","agi","def","intt","luck"];
        var stat_count = array_length(stat_keys);

        var pending_total = 0;
        for (var pidx = 0; pidx < stat_count; pidx++) {
            var base_v = variable_struct_get(m.base_stats, stat_keys[pidx]);
            var cur_v = variable_struct_get(m.pending_stats, stat_keys[pidx]);
            if (cur_v > base_v) pending_total += (cur_v - base_v);
        }

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

        var bar_scale = UI_BAR_SCALE;
        var bar_w = sprite_get_width(hp_bar_sprite) * bar_scale;
        var hp_bar_h = sprite_get_height(hp_bar_sprite) * bar_scale;
        var mp_bar_h = sprite_get_height(mp_bar_sprite) * bar_scale;

        var level_capped = Level_IsAtCap(ch.level);
        var exp_label_1 = level_capped ? "Level Cap" : "Required EXP";
        var exp_value = level_capped ? "MAX" : (string(ch.exp) + "/" + string(ch.exp_next));
        var line_h = string_height("A") + 2;

        var left_content_w = max(
            bar_w,
            string_width("Level: " + string(ch.level)),
            string_width(exp_label_1),
            string_width(exp_value),
            string_width("Available Points: " + string(m.pending_points))
        ) + pad * 2;
        var left_w = min(bw * 0.55, left_content_w);

        var right_x = bx + left_w + pad;
        var right_w = (bx + bw - pad) - right_x;

        draw_sprite_ext(hp_bar_sprite, hp_frame, left_x, y0, bar_scale, bar_scale, 0, c_white, menu_alpha);
        draw_sprite_ext(mp_bar_sprite, mp_frame, left_x, y0 + hp_bar_h + pad, bar_scale, bar_scale, 0, c_white, menu_alpha);

        draw_set_color(c_white);
        var hp_text = string(ch.hp) + " / " + string(ch.max_hp);
        var mp_text = string(ch.mp) + " / " + string(ch.max_mp);
        draw_text(left_x + bar_w + 6, y0, hp_text);
        draw_text(left_x + bar_w + 6, y0 + hp_bar_h + pad, mp_text);

        draw_set_color(c_white);
        var text_y = y0 + hp_bar_h + mp_bar_h + pad * 2;
        draw_text(left_x, text_y, "Level: " + string(ch.level));
        text_y += line_h;
        draw_text(left_x, text_y, exp_label_1);
        text_y += line_h;
        draw_text(left_x, text_y, exp_value);
        text_y += line_h;
        draw_text(left_x, text_y, "Available Points: " + string(m.pending_points));

        var row_h2 = row_h;
        var list_y = y0;
        var label_x = right_x;
        var btn_w = max(12, row_h2 * 0.6);
        var btn_h = row_h2 - 4;
        var preview_w = max(btn_w, string_width("+99"));
        var preview_x = right_x + right_w - preview_w;
        var plus_x = preview_x - btn_w - pad;
        var minus_x = plus_x - btn_w - pad;

        for (var i3 = 0; i3 < stat_count; i3++) {
            var row_y = list_y + i3 * row_h2;
            var val = variable_struct_get(m.pending_stats, stat_keys[i3]);
            var base_v = variable_struct_get(m.base_stats, stat_keys[i3]);
            var preview = val - base_v;

                var sel_minus = (m.stats_focus && m.stats_row == i3 && m.stats_col == 0);
                var sel_plus = (m.stats_focus && m.stats_row == i3 && m.stats_col == 1);
                var stat_selected = (m.stats_focus && m.stats_row == i3);

            draw_set_color(c_white);
            draw_text(label_x, row_y, stat_names[i3] + ": " + string(val));

            if (sel_minus) {
                draw_set_color(c_white);
                draw_rectangle(minus_x - 2, row_y - 2, minus_x + btn_w + 2, row_y + btn_h + 2, false);
                draw_set_color(c_black);
                draw_rectangle(minus_x - 2, row_y - 2, minus_x + btn_w + 2, row_y + btn_h + 2, true);
            }
            if (sel_plus) {
                draw_set_color(c_white);
                draw_rectangle(plus_x - 2, row_y - 2, plus_x + btn_w + 2, row_y + btn_h + 2, false);
                draw_set_color(c_black);
                draw_rectangle(plus_x - 2, row_y - 2, plus_x + btn_w + 2, row_y + btn_h + 2, true);
            }

            var minus_tx = minus_x + (btn_w - string_width("-")) * 0.5;
            var plus_tx = plus_x + (btn_w - string_width("+")) * 0.5;

            draw_set_color(sel_minus ? c_black : c_white);
            draw_text(minus_tx, row_y, "-");
            draw_set_color(sel_plus ? c_black : c_white);
            draw_text(plus_tx, row_y, "+");

                if (preview > 0) {
                    draw_set_color(c_white);
                    draw_text(preview_x, row_y, "+" + string(preview));
                }

                if (stat_selected) {
                    tooltip_lines = Tooltip_BuildStatLines(stat_keys[i3], stat_names[i3], val, base_v, m.pending_points, m.stats_col);
                }
        }

        var action_row = stat_count;
        var action_y = list_y + stat_count * row_h2 + pad;
        var show_actions = (pending_total > 0);
        var confirm_text = "Confirm";
        var cancel_text = "Cancel";
        var confirm_w = string_width(confirm_text);
        var cancel_w = string_width(cancel_text);
        var action_h = string_height(confirm_text) + 4;
        var btn_pad = 6;

        var confirm_x = right_x;
        var cancel_x = confirm_x + confirm_w + btn_pad * 2 + pad;

        if (show_actions) {
        if (m.stats_focus && m.stats_row == action_row && m.stats_col == 0) {
                draw_set_color(c_white);
                draw_rectangle(confirm_x - btn_pad, action_y - 2, confirm_x + confirm_w + btn_pad, action_y + action_h, false);
                draw_set_color(c_black);
                draw_rectangle(confirm_x - btn_pad, action_y - 2, confirm_x + confirm_w + btn_pad, action_y + action_h, true);
            }
            draw_set_color((m.stats_focus && m.stats_row == action_row && m.stats_col == 0) ? c_black : c_white);
            draw_text(confirm_x, action_y, confirm_text);
    
            if (m.stats_focus && m.stats_row == action_row && m.stats_col == 1) {
                draw_set_color(c_white);
                draw_rectangle(cancel_x - btn_pad, action_y - 2, cancel_x + cancel_w + btn_pad, action_y + action_h, false);
                draw_set_color(c_black);
                draw_rectangle(cancel_x - btn_pad, action_y - 2, cancel_x + cancel_w + btn_pad, action_y + action_h, true);
            }
            draw_set_color((m.stats_focus && m.stats_row == action_row && m.stats_col == 1) ? c_black : c_white);
            draw_text(cancel_x, action_y, cancel_text);
            }
    }

    if (!(variable_struct_exists(m, "inv_popup_open") && m.inv_popup_open) && array_length(tooltip_lines) > 0) {
        var tip_style = Tooltip_GetStyle("menu");
        var tip_w = bw;
        var tip_h = menu_tip_h;
        var tip_x = bx;
        var tip_y = menu_tip_y;
        var tip_margin = max(tip_style.margin_px, max(2, floor(pad * 0.5)));
        var tip_rect = Tooltip_ClampRect(tip_x, tip_y, tip_w, tip_h, tip_margin, tip_style.min_w, tip_style.min_h);
        Tooltip_DrawBox(tip_rect.x, tip_rect.y, tip_rect.w, tip_rect.h, tooltip_lines, menu_alpha, tip_style);
    }

    if (variable_struct_exists(m, "inv_popup_open") && m.inv_popup_open) {
        var inv_closing = variable_struct_exists(m, "inv_popup_closing") && m.inv_popup_closing;
        var inv_close_frame = variable_struct_exists(m, "inv_popup_close_frame") ? m.inv_popup_close_frame : UI_OPENED_FRAME_NONE;
        var popup_alpha = UI_PopupAlpha(m.inv_popup_open_frame, inv_closing, inv_close_frame, 1);
        var popup_msg = "Learn a skill";
        if (m.inv_popup_mode == "message") popup_msg = string(m.inv_popup_message);

        var popup_pad_x = 12;
        var popup_pad_y = 8;
        var popup_gap_y = 8;
        var btn_pad_x = 8;
        var line_h_popup = string_height("A");
        var btn_h = line_h_popup + 4;
        var msg_w = string_width(popup_msg);
        var popup_w = 0;
        var popup_h = 0;
        var px1 = 0;
        var py1 = 0;
        var px2 = 0;
        var py2 = 0;

        if (m.inv_popup_mode == "confirm") {
            var yes_label = "Confirm";
            var no_label = "Cancel";
            var yes_w = string_width(yes_label) + btn_pad_x * 2;
            var no_w = string_width(no_label) + btn_pad_x * 2;
            var btn_gap_x = 14;
            var total_btn_w = yes_w + btn_gap_x + no_w;

            popup_w = max(180, max(msg_w + popup_pad_x * 2, total_btn_w + popup_pad_x * 2));
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
            draw_set_alpha(popup_alpha);

            var msg_x = px1 + (popup_w - msg_w) * 0.5;
            var msg_y = py1 + popup_pad_y;
            draw_set_color(c_white);
            draw_text(msg_x, msg_y, popup_msg);

            var btn_y = msg_y + line_h_popup + popup_gap_y;
            var yes_x = px1 + (popup_w - total_btn_w) * 0.5;
            var no_x = yes_x + yes_w + btn_gap_x;

            if (m.inv_popup_choice == 0) {
                draw_set_color(c_white);
                draw_rectangle(yes_x, btn_y, yes_x + yes_w, btn_y + btn_h, false);
                draw_set_color(c_black);
                draw_rectangle(yes_x, btn_y, yes_x + yes_w, btn_y + btn_h, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(yes_x + (yes_w - string_width(yes_label)) * 0.5, btn_y + 2, yes_label);

            if (m.inv_popup_choice == 1) {
                draw_set_color(c_white);
                draw_rectangle(no_x, btn_y, no_x + no_w, btn_y + btn_h, false);
                draw_set_color(c_black);
                draw_rectangle(no_x, btn_y, no_x + no_w, btn_y + btn_h, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(no_x + (no_w - string_width(no_label)) * 0.5, btn_y + 2, no_label);
        } else {
            var ok_label = "OK";
            var ok_w = string_width(ok_label) + btn_pad_x * 2;
            popup_w = max(180, max(msg_w + popup_pad_x * 2, ok_w + popup_pad_x * 2));
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
            draw_set_alpha(popup_alpha);

            var msg_x2 = px1 + (popup_w - msg_w) * 0.5;
            var msg_y2 = py1 + popup_pad_y;
            draw_set_color(c_white);
            draw_text(msg_x2, msg_y2, popup_msg);

            var btn_y2 = msg_y2 + line_h_popup + popup_gap_y;
            var ok_x = px1 + (popup_w - ok_w) * 0.5;
            draw_set_color(c_white);
            draw_rectangle(ok_x, btn_y2, ok_x + ok_w, btn_y2 + btn_h, false);
            draw_set_color(c_black);
            draw_rectangle(ok_x, btn_y2, ok_x + ok_w, btn_y2 + btn_h, true);
            draw_set_color(c_black);
            draw_text(ok_x + (ok_w - string_width(ok_label)) * 0.5, btn_y2 + 2, ok_label);
        }
    }

    draw_set_alpha(1);
}

function ClassSelect_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "class_select")) {
        gs.ui.class_select = {
            open: false,
            closing: false,
            close_frame: UI_OPENED_FRAME_NONE,
            index: 0,
            choices: ["Warrior", "Archer", "Mage"],
            choice_ids: [CLASS_KNIGHT, CLASS_ARCHER, CLASS_MAGE],
            allow_cancel: true,
            open_block_frame: UI_OPENED_FRAME_NONE,
            opened_frame: UI_OPENED_FRAME_NONE,
            pending_apply_class: -1
        };
    } else {
        var cs0 = gs.ui.class_select;
        if (!variable_struct_exists(cs0, "opened_frame")) cs0.opened_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(cs0, "closing")) cs0.closing = false;
        if (!variable_struct_exists(cs0, "close_frame")) cs0.close_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(cs0, "pending_apply_class")) cs0.pending_apply_class = -1;
    }
}

function ClassSelect_IsOpen() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) return false;
    return gs.ui.mode == UI_CLASS_SELECT;
}

function ClassSelect_Open(_allow_cancel = true) {
    ClassSelect_Ensure();
    var gs = GameState_Get();
    if (Transition_IsInputLocked()) return false;
    if (gs.ui.mode != UI_NONE) return false;

    var cs = gs.ui.class_select;
    cs.open = true;
    cs.closing = false;
    cs.close_frame = UI_OPENED_FRAME_NONE;
    cs.pending_apply_class = -1;
    cs.index = 0;
    cs.allow_cancel = _allow_cancel;
    cs.open_block_frame = Input_Frame() + 1;
    cs.opened_frame = Input_Frame();
    gs.ui.class_select = cs;
    gs.ui.mode = UI_CLASS_SELECT;
    SFX_PlayUI("ui_openclose");
    return true;
}

function ClassSelect_Close(_play_sfx = true, _immediate = false) {
    ClassSelect_Ensure();
    var gs = GameState_Get();
    var cs = gs.ui.class_select;
    if (_immediate) {
        cs.open = false;
        cs.closing = false;
        cs.close_frame = UI_OPENED_FRAME_NONE;
        cs.pending_apply_class = -1;
        cs.open_block_frame = UI_OPENED_FRAME_NONE;
        cs.opened_frame = UI_OPENED_FRAME_NONE;
        gs.ui.class_select = cs;
        if (gs.ui.mode == UI_CLASS_SELECT) gs.ui.mode = UI_NONE;
        if (_play_sfx) SFX_PlayUI("ui_openclose");
        return;
    }
    if (!cs.open || cs.closing) return;
    cs.closing = true;
    cs.close_frame = Input_Frame();
    cs.open_block_frame = Input_Frame() + 1;
    gs.ui.class_select = cs;
    if (_play_sfx) SFX_PlayUI("ui_openclose");
}

function ClassSelect_CloseFinalize() {
    var gs = GameState_Get();
    var cs = gs.ui.class_select;
    var apply_class_id = cs.pending_apply_class;

    cs.open = false;
    cs.closing = false;
    cs.close_frame = UI_OPENED_FRAME_NONE;
    cs.pending_apply_class = -1;
    cs.open_block_frame = UI_OPENED_FRAME_NONE;
    cs.opened_frame = UI_OPENED_FRAME_NONE;
    gs.ui.class_select = cs;
    if (gs.ui.mode == UI_CLASS_SELECT) gs.ui.mode = UI_NONE;

    if (is_real(apply_class_id) && apply_class_id >= 0) {
        var queued = Transition_RequestBlackFlash(
            TRANSITION_CLASS_SELECT_FADE_OUT_FRAMES,
            TRANSITION_CLASS_SELECT_FADE_IN_FRAMES,
            apply_class_id
        );
        if (!queued) {
            // Fallback when another transition is already active.
            ClassSelect_ApplyClass(apply_class_id);
        }
    }
}

function ClassSelect_ApplyClass(_class_id) {
    var gs = GameState_Get();
    var old = gs.player_ch;
    var ch = CharacterCreate_Player(_class_id);

    if (is_struct(old)) {
        if (variable_struct_exists(old, "level")) ch.level = old.level;
        if (variable_struct_exists(old, "exp")) ch.exp = old.exp;
        if (variable_struct_exists(old, "exp_next")) ch.exp_next = old.exp_next;
        if (variable_struct_exists(old, "inventory")) ch.inventory = old.inventory;
        if (variable_struct_exists(old, "equip")) ch.equip = old.equip;
        if (variable_struct_exists(old, "stat_points")) ch.stat_points = old.stat_points;
        if (variable_struct_exists(old, "status")) ch.status = old.status;
    }

    // FUN-FIRST: grant and auto-equip class starter weapon (no duplicates).
    ch = Equip_GrantStarterWeapon(ch, _class_id, true);

    ch = Player_NormalizeProgression(ch, true);
    if (is_struct(old)) {
        if (variable_struct_exists(old, "hp")) ch.hp = clamp(old.hp, 0, ch.max_hp);
        if (variable_struct_exists(old, "mp")) ch.mp = clamp(old.mp, 0, ch.max_mp);
    }

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

function ClassSelect_HandleInput() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_CLASS_SELECT) return;
    ClassSelect_Ensure();

    var cs = gs.ui.class_select;
    if (!cs.open) {
        gs.ui.mode = UI_NONE;
        return;
    }

    var frame = Input_Frame();
    if (variable_struct_exists(cs, "closing") && cs.closing) {
        if (frame - cs.close_frame >= UI_POPUP_FADE_FRAMES) {
            ClassSelect_CloseFinalize();
        } else {
            gs.ui.class_select = cs;
        }
        return;
    }
    if (cs.open_block_frame != UI_OPENED_FRAME_NONE && frame <= cs.open_block_frame) {
        gs.ui.class_select = cs;
        return;
    }

    var k_up = Input_UIPressed("menu_up");
    var k_down = Input_UIPressed("menu_down");
    var k_ok = Input_UIConfirm();
    var k_back = Input_UIBack();

    var choice_count = array_length(cs.choices);
    var total = choice_count + (cs.allow_cancel ? 1 : 0);
    if (total <= 0) {
        ClassSelect_Close(false);
        return;
    }

    if (k_up) {
        cs.index = (cs.index + total - 1) mod total;
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        cs.index = (cs.index + 1) mod total;
        SFX_PlayUI("ui_move");
    }

    if (cs.allow_cancel && k_back) {
        SFX_PlayUI("ui_back");
        gs.ui.class_select = cs;
        ClassSelect_Close(false);
        return;
    }

    if (k_ok) {
        SFX_PlayUI("ui_confirm");
        if (cs.allow_cancel && cs.index >= choice_count) {
            gs.ui.class_select = cs;
            ClassSelect_Close(false);
            return;
        }

        if (cs.index >= 0 && cs.index < choice_count && cs.index < array_length(cs.choice_ids)) {
            var class_id = cs.choice_ids[cs.index];
            cs.pending_apply_class = class_id;
            gs.ui.class_select = cs;
            ClassSelect_Close(false);
            return;
        }
    }

    gs.ui.class_select = cs;
}

function ClassSelect_Draw() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_CLASS_SELECT) return;
    ClassSelect_Ensure();
    var cs = gs.ui.class_select;
    if (!cs.open) return;

    var w = display_get_gui_width();
    var h = display_get_gui_height();

    UI_SetFont();
    var line_h = string_height("A");
    var row_gap = max(18, line_h + 4);
    var pad_x = 6;
    var pad_y = 4;

    var bw = w * 0.6;
    var bh = h * 0.5;
    var bx = (w - bw) * 0.5;
    var by = (h - bh) * 0.5;
    var popup_alpha = UI_PopupAlpha(cs.opened_frame, cs.closing, cs.close_frame, 1);

    draw_set_alpha(popup_alpha * 0.85);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(popup_alpha);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);
    draw_set_alpha(popup_alpha);

    draw_set_color(c_white);
    draw_text(bx + 12, by + 12, "Select Class");

    var cy = by + 40;
    for (var j = 0; j < array_length(cs.choices); j++) {
        var yy = cy + j * row_gap;
        var selected = (j == cs.index);
        if (selected) {
            draw_set_color(c_white);
            draw_rectangle(bx + 10 - pad_x, yy - pad_y, bx + bw - 10 + pad_x, yy + line_h + pad_y, false);
            draw_set_color(c_black);
            draw_rectangle(bx + 10 - pad_x, yy - pad_y, bx + bw - 10 + pad_x, yy + line_h + pad_y, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        draw_text(bx + 18, yy, cs.choices[j]);
    }

    if (cs.allow_cancel) {
        var back_y = by + bh - (line_h + 4);
        var back_selected = (cs.index == array_length(cs.choices));
        if (back_selected) {
            draw_set_color(c_white);
            draw_rectangle(bx + 10 - pad_x, back_y - pad_y, bx + bw - 10 + pad_x, back_y + line_h + pad_y, false);
            draw_set_color(c_black);
            draw_rectangle(bx + 10 - pad_x, back_y - pad_y, bx + bw - 10 + pad_x, back_y + line_h + pad_y, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        draw_text(bx + 18, back_y, "Back");
    }
    draw_set_alpha(1);
}

function SettingsPopup_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "settings_popup")) {
        gs.ui.settings_popup = {
            open: false,
            owner: "",
            index: 0,
            volume_step: SETTINGS_VOLUME_STEP,
            dirty: false,
            pending: GameSettings_Copy(GameSettings_Ensure()),
            opened_frame: UI_OPENED_FRAME_NONE,
            closing: false,
            close_frame: UI_OPENED_FRAME_NONE,
            lr_hold_dir: 0,
            lr_hold_frames: 0
        };
    } else {
        var sp0 = gs.ui.settings_popup;
        if (!variable_struct_exists(sp0, "owner")) sp0.owner = "";
        if (!variable_struct_exists(sp0, "index")) sp0.index = 0;
        if (!variable_struct_exists(sp0, "volume_step")) sp0.volume_step = SETTINGS_VOLUME_STEP;
        if (!variable_struct_exists(sp0, "dirty")) sp0.dirty = false;
        if (!variable_struct_exists(sp0, "pending") || !is_struct(sp0.pending)) sp0.pending = GameSettings_Copy(GameSettings_Ensure());
        if (!variable_struct_exists(sp0, "opened_frame")) sp0.opened_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(sp0, "closing")) sp0.closing = false;
        if (!variable_struct_exists(sp0, "close_frame")) sp0.close_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(sp0, "lr_hold_dir")) sp0.lr_hold_dir = 0;
        if (!variable_struct_exists(sp0, "lr_hold_frames")) sp0.lr_hold_frames = 0;
    }
}

function SettingsPopup_IsOpen(_owner = "") {
    SettingsPopup_Ensure();
    var gs = GameState_Get();
    var sp = gs.ui.settings_popup;
    if (!sp.open) return false;
    if (_owner != "" && string(sp.owner) != string(_owner)) return false;
    return true;
}

function SettingsPopup_Open(_owner = "") {
    SettingsPopup_Ensure();
    var gs = GameState_Get();
    var sp = gs.ui.settings_popup;
    sp.open = true;
    sp.owner = string(_owner);
    sp.index = 0;
    sp.volume_step = SETTINGS_VOLUME_STEP;
    sp.dirty = false;
    sp.pending = GameSettings_Copy(GameSettings_Ensure());
    sp.opened_frame = Input_Frame();
    sp.closing = false;
    sp.close_frame = UI_OPENED_FRAME_NONE;
    sp.lr_hold_dir = 0;
    sp.lr_hold_frames = 0;
    gs.ui.settings_popup = sp;
    SFX_PlayUI("ui_openclose");
}

function SettingsPopup_Close(_immediate = false) {
    SettingsPopup_Ensure();
    var gs = GameState_Get();
    var sp = gs.ui.settings_popup;
    if (!sp.open) return;
    if (_immediate) {
        sp.open = false;
        sp.owner = "";
        sp.closing = false;
        sp.close_frame = UI_OPENED_FRAME_NONE;
        sp.opened_frame = UI_OPENED_FRAME_NONE;
        sp.dirty = false;
        sp.pending = GameSettings_Copy(GameSettings_Ensure());
        sp.lr_hold_dir = 0;
        sp.lr_hold_frames = 0;
        gs.ui.settings_popup = sp;
        SFX_PlayUI("ui_openclose");
        return;
    }
    if (sp.closing) return;
    sp.closing = true;
    sp.close_frame = Input_Frame();
    gs.ui.settings_popup = sp;
    SFX_PlayUI("ui_openclose");
}

function SettingsPopup_CloseFinalize() {
    SettingsPopup_Ensure();
    var gs = GameState_Get();
    var sp = gs.ui.settings_popup;
    sp.open = false;
    sp.owner = "";
    sp.closing = false;
    sp.close_frame = UI_OPENED_FRAME_NONE;
    sp.opened_frame = UI_OPENED_FRAME_NONE;
    sp.dirty = false;
    sp.pending = GameSettings_Copy(GameSettings_Ensure());
    sp.lr_hold_dir = 0;
    sp.lr_hold_frames = 0;
    gs.ui.settings_popup = sp;
}

function SettingsPopup_HandleInput() {
    SettingsPopup_Ensure();
    var gs = GameState_Get();
    var sp = gs.ui.settings_popup;
    if (!sp.open) return;

    if (sp.closing) {
        if (Input_Frame() - sp.close_frame >= UI_POPUP_FADE_FRAMES) {
            SettingsPopup_CloseFinalize();
        } else {
            gs.ui.settings_popup = sp;
        }
        return;
    }

    var k_up = Input_UIPressed("menu_up");
    var k_down = Input_UIPressed("menu_down");
    var k_left = Input_UIPressed("menu_left");
    var k_right = Input_UIPressed("menu_right");
    var h_left = Input_Held("menu_left");
    var h_right = Input_Held("menu_right");
    var k_ok = Input_UIConfirm();
    var k_back = Input_UIBack();

    var settings_rows = SETTINGS_MENU_ROW_COUNT;
    if (k_up) {
        sp.index = (sp.index + settings_rows - 1) mod settings_rows;
        SFX_PlayUI("ui_move");
    }
    if (k_down) {
        sp.index = (sp.index + 1) mod settings_rows;
        SFX_PlayUI("ui_move");
    }

    if (sp.index == 5 && k_left) {
        sp.index = 4;
        SFX_PlayUI("ui_move");
    }

    if (k_back) {
        sp.pending = GameSettings_Copy(GameSettings_Ensure());
        sp.dirty = false;
        gs.ui.settings_popup = sp;
        SettingsPopup_Close(false);
        return;
    }

    var pending = GameSettings_Copy(sp.pending);
    var changed = false;
    var step = sp.volume_step;
    var can_hold_adjust = (sp.index >= 0 && sp.index <= 3);

    // Local hold-repeat for slider/scale rows only.
    var hold_dir = 0;
    if (h_right && !h_left) hold_dir = 1;
    if (h_left && !h_right) hold_dir = -1;
    if (!can_hold_adjust) hold_dir = 0;

    if (hold_dir != sp.lr_hold_dir) {
        sp.lr_hold_dir = hold_dir;
        sp.lr_hold_frames = 0;
    } else if (hold_dir != 0) {
        sp.lr_hold_frames += 1;
    } else {
        sp.lr_hold_frames = 0;
    }

    var k_left_step = k_left;
    var k_right_step = k_right;
    if (can_hold_adjust && hold_dir != 0) {
        var repeat_fire = (sp.lr_hold_frames >= SETTINGS_HOLD_REPEAT_DELAY)
            && (((sp.lr_hold_frames - SETTINGS_HOLD_REPEAT_DELAY) mod max(1, SETTINGS_HOLD_REPEAT_INTERVAL)) == 0);
        if (hold_dir < 0) k_left_step = (k_left_step || repeat_fire);
        if (hold_dir > 0) k_right_step = (k_right_step || repeat_fire);
    }

    switch (sp.index) {
        case 0:
            if (k_left_step) {
                pending.audio_ui = clamp(pending.audio_ui - step, 0, 1);
                changed = true;
            }
            if (k_right_step) {
                pending.audio_ui = clamp(pending.audio_ui + step, 0, 1);
                changed = true;
            }
            break;
        case 1:
            if (k_left_step) {
                pending.audio_sfx = clamp(pending.audio_sfx - step, 0, 1);
                changed = true;
            }
            if (k_right_step) {
                pending.audio_sfx = clamp(pending.audio_sfx + step, 0, 1);
                changed = true;
            }
            break;
        case 2:
            if (k_left_step) {
                pending.audio_bgm = clamp(pending.audio_bgm - step, 0, 1);
                changed = true;
            }
            if (k_right_step) {
                pending.audio_bgm = clamp(pending.audio_bgm + step, 0, 1);
                changed = true;
            }
            break;
        case 3:
            if (k_left_step) {
                pending.display_scale = clamp(pending.display_scale - 1, DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
                changed = true;
            }
            if (k_right_step) {
                pending.display_scale = clamp(pending.display_scale + 1, DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
                changed = true;
            }
            break;
        case 4:
            if (k_ok) {
                var committed = GameSettings_Commit(pending, true);
                sp.pending = GameSettings_Copy(committed);
                sp.dirty = false;
                gs.ui.settings_popup = sp;
                SFX_PlayUI("ui_confirm");
                return;
            }
            break;
        case 5:
            if (k_ok) {
                sp.pending = GameSettings_Copy(GameSettings_Ensure());
                sp.dirty = false;
                gs.ui.settings_popup = sp;
                SFX_PlayUI("ui_confirm");
                SettingsPopup_Close(false);
                return;
            }
            break;
    }

    if (changed) {
        sp.pending = GameSettings_Copy(pending);
        sp.dirty = true;
        gs.ui.settings_popup = sp;
        SFX_PlayUI("ui_move");
        return;
    }

    gs.ui.settings_popup = sp;
}

function SettingsPopup_Draw(_draw_backdrop = true) {
    SettingsPopup_Ensure();
    var gs = GameState_Get();
    var sp = gs.ui.settings_popup;
    if (!sp.open) return;

    var w = display_get_gui_width();
    var h = display_get_gui_height();
    UI_SetFont();
    var line_h = string_height("A");
    var popup_alpha = UI_PopupAlpha(sp.opened_frame, sp.closing, sp.close_frame, 1);
    var sw = w * 0.72;
    var sh = h * 0.72;
    var sx = (w - sw) * 0.5;
    var sy = (h - sh) * 0.5;
    var settings = GameSettings_Copy(sp.pending);

    if (_draw_backdrop) {
        draw_set_alpha(popup_alpha * 0.6);
        draw_set_color(c_black);
        draw_rectangle(0, 0, w, h, false);
    }

    draw_set_alpha(popup_alpha * 0.9);
    draw_set_color(c_black);
    draw_rectangle(sx, sy, sx + sw, sy + sh, false);
    draw_set_alpha(popup_alpha);
    draw_set_color(c_white);
    draw_rectangle(sx, sy, sx + sw, sy + sh, true);
    draw_set_alpha(popup_alpha);
    draw_text(sx + 12, sy + 12, "Settings");

    var row_gap_s = max(18, line_h + 6);
    var audio_header_y = sy + 32;
    var rows_y0 = audio_header_y + row_gap_s;
    var display_header_y = rows_y0 + row_gap_s * 3 + 2;
    var display_rows_y0 = display_header_y + row_gap_s;

    var row_y = [];
    row_y[0] = rows_y0;
    row_y[1] = rows_y0 + row_gap_s;
    row_y[2] = rows_y0 + row_gap_s * 2;
    row_y[3] = display_rows_y0;
    row_y[4] = display_rows_y0 + row_gap_s + 2;
    row_y[5] = display_rows_y0 + row_gap_s * 2 + 2;

    draw_set_color(c_white);
    draw_text(sx + 12, audio_header_y, "Audio");
    draw_text(sx + 12, display_header_y, "Display");

    for (var r = 0; r < SETTINGS_MENU_ROW_COUNT; r++) {
        var yy = row_y[r];
        var selected_row = (sp.index == r);
        var label = "";
        var value = "";

        switch (r) {
            case 0:
                label = "UI";
                value = string(clamp(round(settings.audio_ui * 100), 0, 100)) + "%";
                break;
            case 1:
                label = "SFX";
                value = string(clamp(round(settings.audio_sfx * 100), 0, 100)) + "%";
                break;
            case 2:
                label = "BGM";
                value = string(clamp(round(settings.audio_bgm * 100), 0, 100)) + "%";
                break;
            case 3:
                label = "Scale";
                value = string(settings.display_scale) + "x";
                break;
            case 4:
                label = "Apply";
                value = sp.dirty ? "Pending" : "Saved";
                break;
            case 5:
                label = "Back";
                break;
        }

        if (selected_row) {
            if (r == 4 || r == 5) {
                var row_x = sx + 16;
                var row_w = string_width(label) + 8;
                draw_set_color(c_white);
                draw_rectangle(row_x - 4, yy - 3, row_x + row_w, yy + line_h + 5, false);
                draw_set_color(c_black);
                draw_rectangle(row_x - 4, yy - 3, row_x + row_w, yy + line_h + 5, true);
            } else {
                draw_set_color(c_white);
                draw_rectangle(sx + 8, yy - 3, sx + sw - 8, yy + line_h + 5, false);
                draw_set_color(c_black);
                draw_rectangle(sx + 8, yy - 3, sx + sw - 8, yy + line_h + 5, true);
            }
        }

        draw_set_color(selected_row ? c_black : c_white);
        draw_text(sx + 16, yy, label);
        if (value != "") {
            if (r == 4) draw_set_color(c_white);
            else draw_set_color(selected_row ? c_black : c_white);
            draw_set_halign(fa_right);
            draw_text(sx + sw - 16, yy, value);
            draw_set_halign(fa_left);
        }
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
}

// --------------------
// PAUSE MENU (inventory-style popup)
// --------------------
function PauseMenu_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "pause_menu")) {
        gs.ui.pause_menu = {
            open: false,
            closing: false,
            close_frame: UI_OPENED_FRAME_NONE,
            pending_exit_main_menu: false,
            index: 0,
            options: ["Resume","Settings","Exit to Main Menu"],
            opened_frame: UI_OPENED_FRAME_NONE
        };
    } else {
        var pm0 = gs.ui.pause_menu;
        if (!variable_struct_exists(pm0, "opened_frame")) pm0.opened_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(pm0, "closing")) pm0.closing = false;
        if (!variable_struct_exists(pm0, "close_frame")) pm0.close_frame = UI_OPENED_FRAME_NONE;
        if (!variable_struct_exists(pm0, "pending_exit_main_menu")) pm0.pending_exit_main_menu = false;
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

    pm.open = false;
    pm.closing = false;
    pm.close_frame = UI_OPENED_FRAME_NONE;
    pm.pending_exit_main_menu = false;
    pm.opened_frame = UI_OPENED_FRAME_NONE;
    gs.ui.pause_menu = pm;
    if (gs.ui.mode == UI_PAUSE) gs.ui.mode = UI_NONE;

    if (do_exit) {
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
    if (pm.index != prev_idx) SFX_PlayUI("ui_move");

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
            PauseMenu_ExitToMainMenu();
            return;
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

    UI_SetFont();

    var layout = Menu_GetLayout();
    var w = layout.w;
    var h = layout.h;
    var pad = layout.pad;
    var line_h = string_height("A");
    var inner_pad = max(4, pad * 0.6);
    var row_h = max(16, line_h + inner_pad * 2);

    var max_w = 0;
    for (var i = 0; i < array_length(pm.options); i++) {
        max_w = max(max_w, string_width(pm.options[i]));
    }
    var bw = max_w + inner_pad * 4;
    var bh = (row_h * array_length(pm.options)) + inner_pad * 2;
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
    for (var i = 0; i < array_length(options); i++) {
        var yy = start_y + i * row_h;
        var sel = (i == pm.index);
        if (sel) {
            draw_set_color(c_white);
            draw_rectangle(bx + inner_pad - 4, yy - 2, bx + bw - inner_pad + 4, yy + row_h - 2, false);
            draw_set_color(c_black);
            draw_rectangle(bx + inner_pad - 4, yy - 2, bx + bw - inner_pad + 4, yy + row_h - 2, true);
        }
        draw_set_color(sel ? c_black : c_white);
        draw_text(bx + inner_pad, yy, options[i]);
    }
    draw_set_alpha(1);
}
