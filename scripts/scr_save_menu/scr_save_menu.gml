function SaveMenu_Log(_msg) {
    if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
        show_debug_message("[SaveMenu] " + _msg);
    }
}

function SaveMenu_Open(_mode, _context) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    gs.ui.mode = UI_SAVE;
    gs.ui.save_menu = {
        open: true,
        mode: _mode, // "load" or "save"
        context: _context, // "main" or "bed"
        slot: 0,
        col: 0,
        confirm: false,
        confirm_choice: 0,
        confirm_mode: "delete", // delete | overwrite | saved | bed_prompt
        message: ""
    };

    if (_context == "bed" && _mode == "save") {
        SaveMenu_Log("bed prompt open");
        gs.ui.save_menu.confirm = true;
        gs.ui.save_menu.confirm_mode = "bed_prompt";
        gs.ui.save_menu.confirm_choice = 1; // default Cancel
        gs.ui.save_menu.message = "Save Game?";
    }
}

function SaveMenu_Close() {
    var gs = GameState_Get();
    if (variable_struct_exists(gs, "ui") && variable_struct_exists(gs.ui, "save_menu")) {
        gs.ui.save_menu.open = false;
    }
    gs.ui.mode = UI_NONE;
}

function SaveMenu_Handle() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "save_menu")) return;
    var sm = gs.ui.save_menu;
    if (!sm.open) return;

    var k_up = Input_Pressed("menu_up");
    var k_down = Input_Pressed("menu_down");
    var k_left = Input_Pressed("menu_left");
    var k_right = Input_Pressed("menu_right");
    var k_ok = Input_Pressed("confirm");
    var k_back = Input_Pressed("cancel");

    if (sm.confirm) {
        if (sm.confirm_mode == "saved") {
            if (k_ok || k_back) {
                sm.confirm = false;
                SaveMenu_Close();
            }
            gs.ui.save_menu = sm;
            return;
        }

        if (sm.confirm_mode == "bed_prompt") {
            if (k_left || k_right) sm.confirm_choice = 1 - sm.confirm_choice;
            if (k_back) { SaveMenu_Close(); return; }
            if (k_ok) {
                if (sm.confirm_choice == 0) {
                    SaveMenu_Log("bed prompt confirm -> slot select");
                    sm.confirm = false;
                } else {
                    SaveMenu_Log("bed prompt cancel");
                    SaveMenu_Close();
                    return;
                }
            }
            gs.ui.save_menu = sm;
            return;
        }

        if (k_left || k_right) sm.confirm_choice = 1 - sm.confirm_choice;
        if (k_back) { sm.confirm = false; gs.ui.save_menu = sm; return; }
        if (k_ok) {
            if (sm.confirm_choice == 0) {
                if (sm.confirm_mode == "delete") {
                    SaveMenu_Log("delete slot " + string(sm.slot + 1));
                Save_Delete(sm.slot + 1);
                } else if (sm.confirm_mode == "overwrite") {
                    SaveMenu_Log("overwrite confirmed slot " + string(sm.slot + 1));
                    Save_Write(sm.slot + 1);
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

    if (k_up) sm.slot = (sm.slot + 4 - 1) mod 4;
    if (k_down) sm.slot = (sm.slot + 1) mod 4;

    if (sm.mode == "load" && sm.slot < 3) {
        if (k_left) sm.col = max(0, sm.col - 1);
        if (k_right) sm.col = min(1, sm.col + 1);
    } else {
        sm.col = 0;
    }

    if (k_back) {
        SaveMenu_Close();
        return;
    }

    if (k_ok) {
        if (sm.slot == 3) {
            SaveMenu_Close();
            return;
        }
        var slot = sm.slot + 1;
        if (sm.mode == "load") {
            if (sm.col == 0) {
                if (Save_Read(slot)) {
                    gs.save_slot = slot;
                    SaveMenu_Close();
                }
            } else {
                sm.confirm = true;
                sm.confirm_mode = "delete";
                sm.confirm_choice = 1; // default to Cancel
                SaveMenu_Log("delete confirm open slot " + string(slot));
            }
        } else {
            var info = Save_SlotInfo(slot);
            if (info.exists) {
                sm.confirm = true;
                sm.confirm_mode = "overwrite";
                sm.confirm_choice = 1; // default to Cancel
                SaveMenu_Log("overwrite confirm open slot " + string(slot));
            } else {
                SaveMenu_Log("save slot " + string(slot));
                Save_Write(slot);
                gs.save_slot = slot;
                if (sm.context == "bed") Enemy_ResetAll();
                sm.confirm = true;
                sm.confirm_mode = "saved";
                sm.message = "Game saved.";
                sm.confirm_choice = 0;
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

    var w = display_get_gui_width();
    var h = display_get_gui_height();
    var line_h = string_height("A");
    var bw = w * 0.7;
    var bh = h * 0.6;
    var bx = (w - bw) * 0.5;
    var by = (h - bh) * 0.5;
    var pad = 6;

    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);

    var title = (sm.mode == "load") ? "Load Game" : "Save Game";
    draw_set_color(c_white);
    draw_text(bx + 12, by + 10, title);

    var row_y = by + 36;
    for (var i = 0; i < 3; i++) {
        var info = Save_SlotInfo(i + 1);
        var yy = row_y + i * 22;
        var label = "Slot " + string(i + 1);
        if (info.exists) {
            label += "  " + info.class_name + " Lv" + string(info.level) + "  " + info.room;
        }

        if (i == sm.slot && sm.col == 0 && !sm.confirm) {
            draw_set_color(c_white);
            draw_rectangle(bx + 8 - pad, yy - 4, bx + bw - 90 + pad, yy + line_h + 4, false);
            draw_set_color(c_black);
            draw_rectangle(bx + 8 - pad, yy - 4, bx + bw - 90 + pad, yy + line_h + 4, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        draw_text(bx + 14, yy, label);

        if (sm.mode == "load") {
            var delx = bx + bw - 70;
            if (i == sm.slot && sm.col == 1 && !sm.confirm) {
                draw_set_color(c_white);
                draw_rectangle(delx - 8, yy - 4, delx + 52, yy + line_h + 4, false);
                draw_set_color(c_black);
                draw_rectangle(delx - 8, yy - 4, delx + 52, yy + line_h + 4, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(delx, yy, "Delete");
        }
    }

    // Back label
    var back_x = bx + 12;
    var back_y = by + bh - 18;
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
        draw_set_alpha(0.85);
        draw_set_color(c_black);
        draw_rectangle(cx - 80, cy - 22, cx + 80, cy + 22, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(cx - 80, cy - 22, cx + 80, cy + 22, true);
        draw_set_color(c_white);

        var msg = "";
        if (sm.confirm_mode == "delete") msg = "Delete slot?";
        else if (sm.confirm_mode == "overwrite") msg = "Overwrite save?";
        else if (sm.confirm_mode == "bed_prompt") msg = "Save Game?";
        else msg = sm.message;
        draw_text(cx - 70, cy - 12, msg);

        if (sm.confirm_mode != "saved") {
            var yesx = cx - 40;
            var nox = cx + 10;
            if (sm.confirm_choice == 0) {
                draw_set_color(c_white);
                draw_rectangle(yesx - 8, cy + 2, yesx + 34, cy + line_h + 4, false);
                draw_set_color(c_black);
                draw_rectangle(yesx - 8, cy + 2, yesx + 34, cy + line_h + 4, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(yesx, cy + 4, "OK");

            if (sm.confirm_choice == 1) {
                draw_set_color(c_white);
                draw_rectangle(nox - 8, cy + 2, nox + 46, cy + line_h + 4, false);
                draw_set_color(c_black);
                draw_rectangle(nox - 8, cy + 2, nox + 46, cy + line_h + 4, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            draw_text(nox, cy + 4, "Cancel");
        } else {
            draw_set_color(c_white);
            draw_text(cx - 20, cy + 4, "OK");
        }
    }
}
