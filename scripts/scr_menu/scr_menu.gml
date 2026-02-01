function Menu_StatsCopy(_s) {
    return { str: _s.str, agi: _s.agi, def: _s.def, intt: _s.intt, luck: _s.luck };
}

function Menu_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "menu")) {
        gs.ui.menu = {
            open: false,
            tab: 0,
            tabs: ["Inventory","Skills","Stats"],
            header_focus: true,
            repeat_dir: 0,
            repeat_next: 0,
            inv_index: 0,
            inv_scroll: 0,
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
    }
}

function Menu_Open() {
    Menu_Ensure();
    var gs = GameState_Get();
    gs.ui.mode = UI_MENU;
    gs.ui.menu.open = true;
    gs.ui.menu.header_focus = true;
    gs.ui.menu.stats_focus = false;
    gs.ui.menu.repeat_dir = 0;
    gs.ui.menu.repeat_next = 0;
    Menu_StatsSync();
}

function Menu_Close() {
    Menu_Ensure();
    var gs = GameState_Get();
    Menu_StatsDiscard();
    gs.ui.mode = UI_NONE;
    gs.ui.menu.open = false;
}

function Menu_IsOpen() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) return false;
    return gs.ui.mode == UI_MENU;
}

function Menu_GetLayout() {
    var w = display_get_gui_width();
    var h = display_get_gui_height();
    var margin = min(w, h) * 0.05;
    var bx = margin;
    var by = margin;
    var bw = w - margin * 2;
    var bh = h - margin * 2;
    var header_h = max(20, bh * 0.10);
    var pad = max(6, min(w, h) * 0.02);
    var row_h = max(16, bh * 0.06);
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

function Menu_StatsSync() {
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch)) return;
    var ch = gs.player_ch;
    Menu_Ensure();
    if (!variable_struct_exists(ch, "stat_points")) ch.stat_points = 0;
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
    ch.stats = Menu_StatsCopy(m.pending_stats);
    ch.stat_points = m.pending_points;
    ch = RecomputeResources(ch);
    GameState_SetPlayer(ch);
    Menu_StatsSync();
}

function Menu_NavRepeat(_dir, _pressed, _held) {
    var gs = GameState_Get();
    var m = gs.ui.menu;
    var frame = Input_Frame();

    if (_pressed) {
        m.repeat_dir = _dir;
        m.repeat_next = frame + MENU_REPEAT_DELAY;
        return true;
    }

    if (!_held) {
        if (m.repeat_dir == _dir) m.repeat_dir = 0;
        return false;
    }

    if (m.repeat_dir != _dir) return false;
    if (frame >= m.repeat_next) {
        m.repeat_next = frame + MENU_REPEAT_INTERVAL;
        return true;
    }
    return false;
}

function Menu_HandleInput() {
    var gs = GameState_Get();
    var m = gs.ui.menu;
    var ch = gs.player_ch;

    var k_up = Input_Pressed("menu_up");
    var k_down = Input_Pressed("menu_down");
    var h_up = Input_Held("menu_up");
    var h_down = Input_Held("menu_down");
    var nav_up = Menu_NavRepeat(-1, k_up, h_up);
    var nav_down = Menu_NavRepeat(1, k_down, h_down);
    var k_left = Input_Pressed("menu_left");
    var k_right = Input_Pressed("menu_right");
    var k_ok = Input_Pressed("confirm");
    var k_back = Input_Pressed("cancel");

    if (k_back) {
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
        }
        if (k_right) {
            m.tab = (m.tab + 1) mod array_length(m.tabs);
            if (m.tab == 2) Menu_StatsSync();
        }
        if (nav_down) {
            m.header_focus = false;
            if (m.tab == 2) {
                if (!is_struct(m.pending_stats)) Menu_StatsSync();
                m.stats_focus = true;
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
            if (nav_up) m.header_focus = true;
            return;
        }
        if (nav_up) {
            if (m.inv_index > 0) {
                m.inv_index -= 1;
            } else {
                m.header_focus = true;
                m.repeat_dir = 0;
                return;
            }
        }
        if (nav_down) {
            if (m.inv_index < count - 1) m.inv_index += 1;
        }

        if (m.inv_index < m.inv_scroll) m.inv_scroll = m.inv_index;
        if (m.inv_index >= m.inv_scroll + rows_visible) m.inv_scroll = m.inv_index - rows_visible + 1;
    }

    if (m.tab == 1) {
        var skills = is_array(ch.skills) ? ch.skills : [];
        var scount = array_length(skills);
        if (scount <= 0) {
            if (nav_up) m.header_focus = true;
            return;
        }
        if (nav_up) {
            if (m.skill_index > 0) {
                m.skill_index -= 1;
            } else {
                m.header_focus = true;
                m.repeat_dir = 0;
                return;
            }
        }
        if (nav_down) {
            if (m.skill_index < scount - 1) m.skill_index += 1;
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
            }
            return;
        }

        if (nav_up) {
            if (m.stats_row > 0) {
                m.stats_row -= 1;
            } else {
                m.stats_focus = false;
                m.header_focus = true;
                m.repeat_dir = 0;
                return;
            }
        }

        if (nav_down) {
            if (m.stats_row < row_count - 1) m.stats_row += 1;
        }

        if (m.stats_row < stat_count) {
            if (k_left)  m.stats_col = 0;
            if (k_right) m.stats_col = 1;
        } else {
            if (k_left || k_right) m.stats_col = 1 - m.stats_col;
        }

        if (k_ok) {
            if (m.stats_row < stat_count) {
                var key = stat_keys[m.stats_row];
                var base_v = variable_struct_get(m.base_stats, key);
                var cur_v = variable_struct_get(m.pending_stats, key);

                if (m.stats_col == 1 && m.pending_points > 0) {
                    variable_struct_set(m.pending_stats, key, cur_v + 1);
                    m.pending_points -= 1;
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

    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);

    draw_set_alpha(0.9);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(1);
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
                    draw_sprite(bandage, 0, bx + bw - pad - 16, yy + 2);
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

        var exp_label_1 = "Required EXP";
        var exp_value = string(ch.exp) + "/" + string(ch.exp_next);
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
            index: 0,
            repeat_dir: 0,
            repeat_next: 0,
            options: ["Resume","Exit to Main Menu"]
        };
    }
}

function PauseMenu_Open() {
    PauseMenu_Ensure();
    var gs = GameState_Get();
    gs.ui.mode = UI_PAUSE;
    var pm = gs.ui.pause_menu;
    pm.open = true;
    pm.index = 0;
    pm.repeat_dir = 0;
    pm.repeat_next = 0;
    gs.ui.pause_menu = pm;
}

function PauseMenu_Close() {
    PauseMenu_Ensure();
    var gs = GameState_Get();
    gs.ui.pause_menu.open = false;
    gs.ui.mode = UI_NONE;
}

function PauseMenu_ExitToMainMenu() {
    var gs = GameState_Get();
    PauseMenu_Close();
    gs.in_main_menu = true;
    gs.player_inst = noone;
    global.player_inst = noone;
    if (variable_struct_exists(gs, "ui")) {
        gs.ui.lines = [];
        gs.ui.index = 0;
        gs.ui.speaker = "";
        gs.ui.confirm_action = "";
        if (variable_struct_exists(gs.ui, "lock_actions")) gs.ui.lock_actions = 0;
    }
    if (room != rm_start) room_goto(rm_start);
}

function PauseMenu_IsOpen() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) return false;
    return gs.ui.mode == UI_PAUSE;
}

function PauseMenu_NavRepeat(_dir, _pressed, _held) {
    var gs = GameState_Get();
    var pm = gs.ui.pause_menu;
    var frame = Input_Frame();

    if (_pressed) {
        pm.repeat_dir = _dir;
        pm.repeat_next = frame + MENU_REPEAT_DELAY;
        gs.ui.pause_menu = pm;
        return true;
    }

    if (!_held) {
        if (pm.repeat_dir == _dir) pm.repeat_dir = 0;
        gs.ui.pause_menu = pm;
        return false;
    }

    if (pm.repeat_dir != _dir) return false;
    if (frame >= pm.repeat_next) {
        pm.repeat_next = frame + MENU_REPEAT_INTERVAL;
        gs.ui.pause_menu = pm;
        return true;
    }
    gs.ui.pause_menu = pm;
    return false;
}

function PauseMenu_HandleInput() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "pause_menu")) return;
    var pm = gs.ui.pause_menu;
    if (!pm.open) return;

    var k_up = Input_Pressed("menu_up");
    var k_down = Input_Pressed("menu_down");
    var h_up = Input_Held("menu_up");
    var h_down = Input_Held("menu_down");
    var nav_up = PauseMenu_NavRepeat(-1, k_up, h_up);
    var nav_down = PauseMenu_NavRepeat(1, k_down, h_down);
    var k_ok = Input_Pressed("confirm");
    var k_back = Input_Pressed("cancel");

    if (k_back) {
        PauseMenu_Close();
        return;
    }

    var count = array_length(pm.options);
    if (nav_up && pm.index > 0) pm.index -= 1;
    if (nav_down && pm.index < count - 1) pm.index += 1;

    if (k_ok) {
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

    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);

    draw_set_alpha(0.9);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(1);
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
}
