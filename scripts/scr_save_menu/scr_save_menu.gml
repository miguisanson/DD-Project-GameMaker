function SaveMenu_Log(_msg) {
    if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
        show_debug_message("[SaveMenu] " + _msg);
    }
}

function SaveMenu_Open(_mode, _context) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    SFX_PlayUI("ui_openclose");
    gs.ui.mode = UI_SAVE;
    gs.ui.save_menu = {
        open: true,
        mode: _mode, // "load" or "save"
        context: _context, // "main" or "bed"
        slot: 0,
        col: 0,
        confirm: false,
        confirm_choice: 0,
        confirm_mode: "delete", // delete | overwrite | save | saved
        message: "",
        just_opened: true
    };

}

function SaveMenu_Close() {
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "ui") && variable_struct_exists(gs.ui, "save_menu")) {
        gs.ui.save_menu.open = false;
    }
    SFX_PlayUI("ui_openclose");
    gs.ui.mode = UI_NONE;
}

function SaveMenu_Handle() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "save_menu")) return;
    var sm = gs.ui.save_menu;
    if (!sm.open) return;

    if (variable_struct_exists(sm, "just_opened") && sm.just_opened) {
        sm.just_opened = false;
        gs.ui.save_menu = sm;
        return;
    }

    var k_up = Input_UIRepeat("menu_up");
    var k_down = Input_UIRepeat("menu_down");
    var k_left = Input_UIRepeat("menu_left");
    var k_right = Input_UIRepeat("menu_right");
    var k_ok = Input_UIConfirm();
    var k_back = Input_UIBack();

    if (sm.confirm) {
        if (sm.confirm_mode == "saved") {
            if (k_ok || k_back) {
                SFX_PlayUI("ui_confirm");
                sm.confirm = false;
                SaveMenu_Close();
            }
            gs.ui.save_menu = sm;
            return;
        }

        if (k_left || k_right) {
            sm.confirm_choice = 1 - sm.confirm_choice;
            SFX_PlayUI("ui_move");
        }
        if (k_back) {
            SFX_PlayUI("ui_back");
            sm.confirm = false;
            gs.ui.save_menu = sm;
            return;
        }
        if (k_ok) {
            SFX_PlayUI("ui_confirm");
            if (sm.confirm_choice == 0) {
                if (sm.confirm_mode == "delete") {
                    SaveMenu_Log("delete slot " + string(sm.slot + 1));
                    Save_Delete(sm.slot + 1);
                    SFX_Play("delete_confirm");
                } else if (sm.confirm_mode == "overwrite") {
                    SaveMenu_Log("overwrite confirmed slot " + string(sm.slot + 1));
                    Save_Write(sm.slot + 1);
                    SFX_Play("save_confirm");
                    gs.save_slot = sm.slot + 1;
                    if (sm.context == "bed") Enemy_ResetAll();
                    sm.message = "Game saved.";
                    sm.confirm_mode = "saved";
                    sm.confirm_choice = 0;
                    gs.ui.save_menu = sm;
                    return;
                } else if (sm.confirm_mode == "save") {
                    SaveMenu_Log("save confirmed slot " + string(sm.slot + 1));
                    Save_Write(sm.slot + 1);
                    SFX_Play("save_confirm");
                    gs.save_slot = sm.slot + 1;
                    if (sm.context == "bed") Enemy_ResetAll();
                    sm.message = "Game saved.";
                    sm.confirm_mode = "saved";
                    sm.confirm_choice = 0;
                    gs.ui.save_menu = sm;
                    return;
                }
            }
            sm.confirm = false;
        }
        gs.ui.save_menu = sm;
        return;
    }

    var prev_slot = sm.slot;
    var prev_col = sm.col;
    if (k_up) sm.slot = (sm.slot + 4 - 1) mod 4;
    if (k_down) sm.slot = (sm.slot + 1) mod 4;

    if (sm.mode == "load" && sm.slot < 3) {
        if (k_left) sm.col = max(0, sm.col - 1);
        if (k_right) sm.col = min(1, sm.col + 1);
    } else {
        sm.col = 0;
    }
    if (sm.slot != prev_slot || sm.col != prev_col) SFX_PlayUI("ui_move");

    if (k_back) {
        SFX_PlayUI("ui_back");
        SaveMenu_Close();
        return;
    }

    if (k_ok) {
        if (sm.slot == 3) {
            SFX_PlayUI("ui_back");
            SaveMenu_Close();
            return;
        }
        var slot = sm.slot + 1;
        if (sm.mode == "load") {
            if (sm.col == 0) {
                if (Save_Read(slot)) {
                    SFX_Play("load_confirm");
                    gs.save_slot = slot;
                    SaveMenu_Close();
                }
            } else {
                SFX_PlayUI("ui_confirm");
                sm.confirm = true;
                sm.confirm_mode = "delete";
                sm.confirm_choice = 1; // default to Cancel
                SaveMenu_Log("delete confirm open slot " + string(slot));
            }
        } else {
            var info = Save_SlotInfo(slot);
            if (info.exists) {
                SFX_PlayUI("ui_confirm");
                sm.confirm = true;
                sm.confirm_mode = "overwrite";
                sm.confirm_choice = 1; // default to Cancel
                SaveMenu_Log("overwrite confirm open slot " + string(slot));
            } else {
                SFX_PlayUI("ui_confirm");
                sm.confirm = true;
                sm.confirm_mode = "save";
                sm.confirm_choice = 1; // default Cancel
                SaveMenu_Log("save confirm open slot " + string(slot));
            }
        }
    }

    gs.ui.save_menu = sm;
}

function SaveMenu_Draw() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "save_menu")) return;
    var sm = gs.ui.save_menu;
    if (!sm.open) return;

    UI_SetFont();

    var w = display_get_gui_width();
    var h = display_get_gui_height();
    var line_h = string_height("A");
    var pad = 6;
    var side_margin = 12;
    var slot_text_left_pad = 14;

    var title = (sm.mode == "load") ? "Load Game" : "Save Game";

    var slot_labels = array_create(3, "");
    var longest_slot_w = 0;
    for (var li = 0; li < 3; li++) {
        var info_l = Save_SlotInfo(li + 1);
        var label_l = "Slot " + string(li + 1);
        if (info_l.exists) {
            label_l += "  " + info_l.class_name + " Lv" + string(info_l.level) + "  " + info_l.room;
        }
        slot_labels[li] = label_l;
        longest_slot_w = max(longest_slot_w, string_width(label_l));
    }

    var delete_label = "Delete";
    var delete_pad_x = 8;
    var delete_text_w = string_width(delete_label);
    var delete_btn_w = delete_text_w + delete_pad_x * 2;
    var slot_delete_gap = 6;

    var min_content_w = slot_text_left_pad + longest_slot_w + side_margin;
    if (sm.mode == "load") min_content_w += slot_delete_gap + delete_btn_w + side_margin;

    var bw = min(max(w * 0.7, min_content_w + 20), w - 24);
    var bh = h * 0.6;
    var bx = (w - bw) * 0.5;
    var by = (h - bh) * 0.5;

    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);

    draw_set_color(c_white);
    draw_text(bx + 12, by + 10, title);

    var row_h = max(22, line_h + 8);
    var row_y = by + 36;
    var delete_right = bx + bw - side_margin;
    var delete_left = delete_right - delete_btn_w;
    var delete_text_x = delete_left + delete_pad_x;
    var slot_select_right = (sm.mode == "load") ? (delete_left - slot_delete_gap) : (bx + bw - side_margin);
    slot_select_right = max(bx + 40, slot_select_right);
    var slot_text_x = bx + slot_text_left_pad;
    var slot_text_max_w = max(24, slot_select_right - slot_text_x - 4);
    for (var i = 0; i < 3; i++) {
        var yy = row_y + i * row_h;
        var label = slot_labels[i];
        var draw_label = label;
        if (string_width(draw_label) > slot_text_max_w) {
            while (string_length(draw_label) > 0 && string_width(draw_label + "...") > slot_text_max_w) {
                draw_label = string_delete(draw_label, string_length(draw_label), 1);
            }
            draw_label += "...";
        }

        if (i == sm.slot && sm.col == 0 && !sm.confirm) {
            draw_set_color(c_white);
            draw_rectangle(bx + 8 - pad, yy - 4, slot_select_right + pad, yy + line_h + 4, false);
            draw_set_color(c_black);
            draw_rectangle(bx + 8 - pad, yy - 4, slot_select_right + pad, yy + line_h + 4, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        draw_text(slot_text_x, yy, draw_label);

        if (sm.mode == "load") {
            if (i == sm.slot && sm.col == 1 && !sm.confirm) {
                draw_set_color(c_white);
                draw_rectangle(delete_left, yy - 4, delete_right, yy + line_h + 4, false);
                draw_set_color(c_black);
                draw_rectangle(delete_left, yy - 4, delete_right, yy + line_h + 4, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(delete_text_x, yy, delete_label);
        }
    }

    // Back label
    var back_x = bx + 12;
    var back_y = by + bh - (line_h + 4);
    if (sm.slot == 3 && !sm.confirm) {
        var bwid = string_width("Back");
        draw_set_color(c_white);
        draw_rectangle(back_x - 4, back_y - 2, back_x + bwid + 4, back_y + line_h + 2, false);
        draw_set_color(c_black);
        draw_rectangle(back_x - 4, back_y - 2, back_x + bwid + 4, back_y + line_h + 2, true);
        draw_set_color(c_black);
    } else {
        draw_set_color(c_white);
    }
    draw_text(back_x, back_y, "Back");

    if (sm.confirm) {
        var cx = bx + bw * 0.5;
        var cy = by + bh * 0.7;
        var msg = "";
        if (sm.confirm_mode == "delete") msg = "Delete slot?";
        else if (sm.confirm_mode == "overwrite") msg = "Overwrite save?";
        else if (sm.confirm_mode == "save") msg = "Save to slot?";
        else msg = sm.message;

        var popup_pad_x = 12;
        var popup_pad_y = 8;
        var popup_gap_y = 8;
        var btn_pad_x = 8;
        var btn_h = line_h + 4;
        var msg_w = string_width(msg);

        var buttons_w = 0;
        if (sm.confirm_mode != "saved") {
            buttons_w = (string_width("OK") + btn_pad_x * 2) + 14 + (string_width("Cancel") + btn_pad_x * 2);
        } else {
            buttons_w = string_width("OK") + btn_pad_x * 2;
        }

        var popup_w = max(160, max(msg_w + popup_pad_x * 2, buttons_w + popup_pad_x * 2));
        var popup_h = popup_pad_y + line_h + popup_gap_y + btn_h + popup_pad_y;
        var px1 = cx - popup_w * 0.5;
        var py1 = cy - popup_h * 0.5;
        var px2 = px1 + popup_w;
        var py2 = py1 + popup_h;

        draw_set_alpha(0.85);
        draw_set_color(c_black);
        draw_rectangle(px1, py1, px2, py2, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(px1, py1, px2, py2, true);
        draw_set_color(c_white);

        var msg_x = px1 + (popup_w - msg_w) * 0.5;
        var msg_y = py1 + popup_pad_y;
        draw_text(msg_x, msg_y, msg);
        var btn_y = msg_y + line_h + popup_gap_y;

        if (sm.confirm_mode != "saved") {
            var yes_label = "OK";
            var no_label = "Cancel";
            var yes_w = string_width(yes_label) + btn_pad_x * 2;
            var no_w = string_width(no_label) + btn_pad_x * 2;
            var btn_gap_x = 14;
            var total_btn_w = yes_w + btn_gap_x + no_w;
            var yesx = px1 + (popup_w - total_btn_w) * 0.5;
            var nox = yesx + yes_w + btn_gap_x;
            if (sm.confirm_choice == 0) {
                draw_set_color(c_white);
                draw_rectangle(yesx, btn_y, yesx + yes_w, btn_y + btn_h, false);
                draw_set_color(c_black);
                draw_rectangle(yesx, btn_y, yesx + yes_w, btn_y + btn_h, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(yesx + (yes_w - string_width(yes_label)) * 0.5, btn_y + 2, yes_label);

            if (sm.confirm_choice == 1) {
                draw_set_color(c_white);
                draw_rectangle(nox, btn_y, nox + no_w, btn_y + btn_h, false);
                draw_set_color(c_black);
                draw_rectangle(nox, btn_y, nox + no_w, btn_y + btn_h, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(nox + (no_w - string_width(no_label)) * 0.5, btn_y + 2, no_label);
        } else {
            var ok_label = "OK";
            var ok_w = string_width(ok_label) + btn_pad_x * 2;
            var ok_x = px1 + (popup_w - ok_w) * 0.5;
            draw_set_color(c_white);
            draw_rectangle(ok_x, btn_y, ok_x + ok_w, btn_y + btn_h, false);
            draw_set_color(c_black);
            draw_rectangle(ok_x, btn_y, ok_x + ok_w, btn_y + btn_h, true);
            draw_set_color(c_black);
            draw_text(ok_x + (ok_w - string_width(ok_label)) * 0.5, btn_y + 2, ok_label);
        }
    }
}
