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
    SFX_PlayUI("ui_openclose");
    gs.ui.mode = UI_MENU;
    gs.ui.menu.open = true;
    gs.ui.menu.closing = false;
    gs.ui.menu.close_frame = UI_OPENED_FRAME_NONE;
    gs.ui.menu.header_focus = true;
    gs.ui.menu.stats_focus = false;
    gs.ui.menu.opened_frame = Input_Frame();
    Menu_StatsSync();
}

function Menu_Close(_immediate = false) {
    Menu_Ensure();
    var gs = GameState_Get();
    var m = gs.ui.menu;
    if (_immediate) {
        Menu_StatsDiscard();
        gs.ui.menu.open = false;
        gs.ui.menu.closing = false;
        gs.ui.menu.close_frame = UI_OPENED_FRAME_NONE;
        gs.ui.mode = UI_NONE;
        SFX_PlayUI("ui_openclose");
        return;
    }
    if (!m.open || m.closing) return;
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
    var margin = min(w, h) * 0.05;
    var bx = margin;
    var by = margin;
    var bw = w - margin * 2;
    var bh = h - margin * 2;
    var header_h = max(line_h + 10, bh * 0.10);
    var pad = max(6, min(w, h) * 0.02);
    var row_h = max(line_h + 4, bh * 0.06);
    var content_y = by + header_h + pad;
    var content_h = bh - header_h - pad * 2;
    var rows_visible = max(4, floor(content_h / row_h));
    return { w:w, h:h, bx:bx, by:by, bw:bw, bh:bh, header_h:header_h, pad:pad, row_h:row_h, content_y:content_y, content_h:content_h, rows_visible:rows_visible };
}

function Menu_IsEquipped(_ch, _item_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip")) return false;
    var eq = _ch.equip;
    if (variable_struct_exists(eq, "weapon") && eq.weapon == _item_id) return true;
    if (variable_struct_exists(eq, "body") && eq.body == _item_id) return true;
    return false;
}

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
            m.header_focus = false;
            if (m.tab == 2) {
                if (!is_struct(m.pending_stats)) Menu_StatsSync();
                m.stats_focus = true;
            }
            SFX_PlayUI("ui_move");
        }
        return;
    }

    var layout = Menu_GetLayout();
    var rows_visible = layout.rows_visible;

    if (m.tab == 0) {
        var items = is_array(ch.inventory) ? ch.inventory : [];
        var count = array_length(items);
        if (count <= 0) {
            if (nav_up) {
                m.header_focus = true;
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
            if (nav_up) {
                m.header_focus = true;
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
        var row_count = stat_count + ((pending_total > 0) ? 1 : 0); // action row

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
            } else if (pending_total > 0) {
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
    var header_h = layout.header_h;
    var pad = layout.pad;
    var row_h = layout.row_h;
    var rows_visible = layout.rows_visible;
    var menu_closing = variable_struct_exists(m, "closing") && m.closing;
    var menu_close_frame = variable_struct_exists(m, "close_frame") ? m.close_frame : UI_OPENED_FRAME_NONE;
    var menu_alpha = UI_PopupAlpha(m.opened_frame, menu_closing, menu_close_frame, 1);

    draw_set_alpha(menu_alpha * 0.6);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);

    draw_set_alpha(menu_alpha * 0.9);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(menu_alpha);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);

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

    // Inventory tab
    if (m.tab == 0) {
        var items = is_array(ch.inventory) ? ch.inventory : [];
        var count = array_length(items);
        var start = clamp(m.inv_scroll, 0, max(0, count - rows_visible));
        var endv = min(count, start + rows_visible);

        if (count == 0) {
            draw_set_color(c_white);
            draw_text(bx + pad, by + header_h + pad, "No items.");
        } else {
            for (var i2 = start; i2 < endv; i2++) {
                var row = i2 - start;
                var yy = layout.content_y + row * row_h;

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
    }

    // Skills tab
    if (m.tab == 1) {
        var skills = is_array(ch.skills) ? ch.skills : [];
        var scount = array_length(skills);
        var start2 = clamp(m.skill_scroll, 0, max(0, scount - rows_visible));
        var end2 = min(scount, start2 + rows_visible);

        if (scount == 0) {
            draw_set_color(c_white);
            draw_text(bx + pad, by + header_h + pad, "No skills.");
        } else {
            for (var s = start2; s < end2; s++) {
                var row2 = s - start2;
                var y2 = layout.content_y + row2 * row_h;

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

        var exp_label_1 = (ch.level >= LEVEL_EFFECTIVE_CAMPAIGN_CAP) ? "Post-Campaign EXP" : "Required EXP";
        var exp_value = string(ch.exp) + "/" + string(ch.exp_next);
        var cap_label = "Campaign Target Lv " + string(LEVEL_EFFECTIVE_CAMPAIGN_CAP);
        var line_h = string_height("A") + 2;

        var left_content_w = max(
            bar_w,
            string_width("Level: " + string(ch.level)),
            string_width(cap_label),
            string_width(exp_label_1),
            string_width(exp_value),
            string_width("Available Points: " + string(m.pending_points))
        ) + pad * 2;
        var left_w = min(bw * 0.55, left_content_w);

        var right_x = bx + left_w + pad;
        var right_w = (bx + bw - pad) - right_x;

        draw_sprite_ext(hp_bar_sprite, hp_frame, left_x, y0, bar_scale, bar_scale, 0, c_white, 1);
        draw_sprite_ext(mp_bar_sprite, mp_frame, left_x, y0 + hp_bar_h + pad, bar_scale, bar_scale, 0, c_white, 1);

        draw_set_color(c_white);
        var hp_text = string(ch.hp) + " / " + string(ch.max_hp);
        var mp_text = string(ch.mp) + " / " + string(ch.max_mp);
        draw_text(left_x + bar_w + 6, y0, hp_text);
        draw_text(left_x + bar_w + 6, y0 + hp_bar_h + pad, mp_text);

        draw_set_color(c_white);
        var text_y = y0 + hp_bar_h + mp_bar_h + pad * 2;
        draw_text(left_x, text_y, "Level: " + string(ch.level));
        text_y += line_h;
        draw_text(left_x, text_y, cap_label);
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
        ClassSelect_ApplyClass(apply_class_id);
        Transition_RequestBlackFlash(TRANSITION_CLASS_SELECT_FADE_OUT_FRAMES, TRANSITION_CLASS_SELECT_FADE_IN_FRAMES);
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

    ch = RecomputeResources(ch);
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
            options: ["Resume","Exit to Main Menu"],
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
            Transition_RequestRoomFade(rm_start);
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

    draw_set_alpha(popup_alpha * 0.6);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);

    draw_set_alpha(popup_alpha * 0.9);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(popup_alpha);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);

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
