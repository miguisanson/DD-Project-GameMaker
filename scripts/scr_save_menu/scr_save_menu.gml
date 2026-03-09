function SaveMenu_Log(_msg) {
    if (variable_global_exists("debug") && is_struct(global.debug) && global.debug.enabled) {
        show_debug_message("[SaveMenu] " + _msg);
    }
}

function BedMenu_Open() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    var opened_with_confirm = (
        Input_Held("confirm") || Input_Held("interact") ||
        Input_Pressed("confirm") || Input_Pressed("interact")
    );

    UI_ModalRootBegin("bed");
    SFX_PlayUI("ui_openclose");
    gs.ui.mode = UI_BED;
    gs.ui.bed_menu = {
        open: true,
        closing: false,
        close_frame: UI_OPENED_FRAME_NONE,
        opened_frame: Input_Frame(),
        require_release: opened_with_confirm,
        index: 0,
        options: [
            Loc_T("bed.option.rest", "Rest"),
            Loc_T("bed.option.back", "Back")
        ],
        pending_action: ""
    };
}

function BedMenu_Close(_immediate = false, _pending_action = "") {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "bed_menu")) return;
    var bm = gs.ui.bed_menu;
    if (_immediate) {
        UI_ModalRootEnd(false, true);
        bm.open = false;
        bm.closing = false;
        bm.close_frame = UI_OPENED_FRAME_NONE;
        bm.pending_action = "";
        gs.ui.bed_menu = bm;
        gs.ui.mode = UI_NONE;
        SFX_PlayUI("ui_openclose");
        return;
    }
    if (!bm.open || bm.closing) return;
    if (string(_pending_action) == "") {
        UI_ModalRootEnd(false);
    }
    bm.closing = true;
    bm.close_frame = Input_Frame();
    bm.pending_action = string(_pending_action);
    gs.ui.bed_menu = bm;
    SFX_PlayUI("ui_openclose");
}

function BedMenu_Handle() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "bed_menu")) return;
    var bm = gs.ui.bed_menu;
    if (!bm.open) return;

    var frame = Input_Frame();
    if (bm.closing) {
        if (frame - bm.close_frame >= UI_POPUP_FADE_FRAMES) {
            var pending_action = string(bm.pending_action);
            bm.open = false;
            bm.closing = false;
            bm.close_frame = UI_OPENED_FRAME_NONE;
            bm.pending_action = "";
            gs.ui.bed_menu = bm;

            if (pending_action == "open_save") {
                SaveMenu_Open("save", "bed");
            } else {
                gs.ui.mode = UI_NONE;
            }
        } else {
            gs.ui.bed_menu = bm;
        }
        return;
    }

    if (variable_struct_exists(bm, "require_release") && bm.require_release) {
        var confirm_active = (
            Input_Held("confirm") || Input_Held("interact") ||
            Input_Pressed("confirm") || Input_Pressed("interact")
        );
        if (confirm_active) {
            gs.ui.bed_menu = bm;
            return;
        }
        bm.require_release = false;
        gs.ui.bed_menu = bm;
        return;
    }

    if (frame <= bm.opened_frame) {
        gs.ui.bed_menu = bm;
        return;
    }

    var k_up = Input_UIPressed("menu_up");
    var k_down = Input_UIPressed("menu_down");
    var k_ok = Input_UIConfirm();
    var k_back = Input_UIBack();

    if (k_up || k_down) {
        bm.index = 1 - bm.index;
        SFX_PlayUI("ui_move");
    }

    if (k_back) {
        SFX_PlayUI("ui_back");
        BedMenu_Close(false);
        return;
    }

    if (k_ok) {
        SFX_PlayUI("ui_confirm");
        if (bm.index == 0) {
            BedMenu_Close(false, "open_save");
            return;
        }
        BedMenu_Close(false);
        return;
    }

    gs.ui.bed_menu = bm;
}

function BedMenu_Draw() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "bed_menu")) return;
    var bm = gs.ui.bed_menu;
    if (!bm.open) return;

    UI_SetFont();

    var w = display_get_gui_width();
    var h = display_get_gui_height();
    var line_h = UI_TextHeight("A");
    var inner_pad = max(6, round(line_h * 0.30));
    var row_h = max(18, line_h + inner_pad * 2);
    var popup_alpha = UI_PopupAlpha(bm.opened_frame, bm.closing, bm.close_frame, 1);

    var max_w = 0;
    for (var i = 0; i < array_length(bm.options); i++) {
        var opt_text = bm.options[i];
        if (i == 0) opt_text = Loc_T("bed.option.rest", opt_text);
        else if (i == 1) opt_text = Loc_T("bed.option.back", opt_text);
        max_w = max(max_w, UI_TextWidth(opt_text));
    }

    var need_w = max_w + inner_pad * 6;
    var need_h = inner_pad * 2 + row_h * array_length(bm.options);
    var bw = min(w - 24, max(w * 0.28, need_w));
    var bh = min(h - 24, max(h * 0.18, need_h));
    var bx = (w - bw) * 0.5;
    var by = (h - bh) * 0.5;

    draw_set_alpha(popup_alpha * 0.9);
    draw_set_color(c_black);
    draw_rectangle(bx, by, bx + bw, by + bh, false);
    draw_set_alpha(popup_alpha);
    draw_set_color(c_white);
    draw_rectangle(bx, by, bx + bw, by + bh, true);
    draw_set_alpha(popup_alpha);

    var start_y = by + inner_pad;
    var text_x = bx + inner_pad * 2;
    var text_max_w = max(24, bw - inner_pad * 4);
    for (var j = 0; j < array_length(bm.options); j++) {
        var yy = start_y + j * row_h;
        var selected = (j == bm.index);
        if (selected) {
            draw_set_color(c_white);
            draw_rectangle(bx + inner_pad, yy - 2, bx + bw - inner_pad, yy + row_h - 2, false);
            draw_set_color(c_black);
            draw_rectangle(bx + inner_pad, yy - 2, bx + bw - inner_pad, yy + row_h - 2, true);
        }
        draw_set_color(selected ? c_black : c_white);
        var bed_label = bm.options[j];
        if (j == 0) bed_label = Loc_T("bed.option.rest", bed_label);
        else if (j == 1) bed_label = Loc_T("bed.option.back", bed_label);
        if (UI_TextWidth(bed_label) > text_max_w) {
            while (string_length(bed_label) > 0 && UI_TextWidth(bed_label + "...") > text_max_w) {
                bed_label = string_delete(bed_label, string_length(bed_label), 1);
            }
            bed_label += "...";
        }
        UI_DrawText(text_x, yy, bed_label);
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
}

function SaveMenu_BuildSlotInfoCache() {
    var out = array_create(3);
    for (var i = 0; i < 3; i++) {
        out[i] = Save_SlotInfo(i + 1);
    }
    return out;
}

function SaveMenu_Open(_mode, _context) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    var opened_with_confirm = (
        Input_Held("confirm") || Input_Held("interact") ||
        Input_Pressed("confirm") || Input_Pressed("interact")
    );
    if (string(_context) == "bed") UI_ModalRootTransfer("save");
    else UI_ModalRootBegin("save");
    SFX_PlayUI("ui_openclose");
    gs.ui.mode = UI_SAVE;
    gs.ui.save_menu = {
        open: true,
        closing: false,
        close_frame: UI_OPENED_FRAME_NONE,
        mode: _mode, // "load" or "save"
        hide_slots: false,
        context: _context, // "main" or "bed"
        slot: 0,
        col: 0,
        confirm: false,
        confirm_choice: 0,
        confirm_mode: "delete", // delete | load | overwrite | save | saved | message
        message: "",
        close_after_message: false,
        slot_info_cache: SaveMenu_BuildSlotInfoCache(),
        opened_frame: Input_Frame(),
        confirm_opened_frame: UI_OPENED_FRAME_NONE,
        confirm_closing: false,
        confirm_close_frame: UI_OPENED_FRAME_NONE,
        pending_action: "",
        pending_slot: 0,
        require_release: opened_with_confirm
    };

}

function SaveMenu_OpenMessage(_message, _close_after = true) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    UI_ModalRootTransfer("save_message");
    gs.ui.mode = UI_SAVE;
    gs.ui.save_menu = {
        open: true,
        closing: false,
        close_frame: UI_OPENED_FRAME_NONE,
        mode: "load",
        hide_slots: true,
        context: "main",
        slot: 0,
        col: 0,
        confirm: true,
        confirm_choice: 0,
        confirm_mode: "message",
        message: string(_message),
        close_after_message: _close_after,
        slot_info_cache: SaveMenu_BuildSlotInfoCache(),
        opened_frame: Input_Frame(),
        confirm_opened_frame: Input_Frame(),
        confirm_closing: false,
        confirm_close_frame: UI_OPENED_FRAME_NONE,
        pending_action: "",
        pending_slot: 0,
        require_release: false
    };
}

function SaveMenu_Close(_immediate = false, _pending_action = "", _pending_slot = 0) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "save_menu")) return;
    var sm = gs.ui.save_menu;
    if (_immediate) {
        UI_ModalRootEnd(false, true);
        sm.open = false;
        sm.closing = false;
        sm.close_frame = UI_OPENED_FRAME_NONE;
        sm.pending_action = "";
        sm.pending_slot = 0;
        sm.confirm = false;
        sm.confirm_closing = false;
        sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
        gs.ui.save_menu = sm;
        SFX_PlayUI("ui_openclose");
        gs.ui.mode = UI_NONE;
        return;
    }
    if (!sm.open || sm.closing) return;
    if (string(_pending_action) == "load_slot"
    && variable_struct_exists(sm, "context")
    && string(sm.context) == "main") {
        UI_ModalRootHold("gameplay_load");
    }
    if (string(_pending_action) == "") {
        UI_ModalRootEnd(false);
    }
    sm.closing = true;
    sm.close_frame = Input_Frame();
    sm.pending_action = _pending_action;
    sm.pending_slot = _pending_slot;
    sm.confirm = false;
    sm.confirm_closing = false;
    sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
    gs.ui.save_menu = sm;
    SFX_PlayUI("ui_openclose");
}

function SaveMenu_Handle() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui") || !variable_struct_exists(gs.ui, "save_menu")) return;
    var sm = gs.ui.save_menu;
    if (!sm.open) return;
    var hide_slots = variable_struct_exists(sm, "hide_slots") && sm.hide_slots;

    var frame = Input_Frame();
    if (variable_struct_exists(sm, "closing") && sm.closing) {
        if (frame - sm.close_frame >= UI_POPUP_FADE_FRAMES) {
            var pending_action = variable_struct_exists(sm, "pending_action") ? string(sm.pending_action) : "";
            var pending_slot = variable_struct_exists(sm, "pending_slot") ? round(real(sm.pending_slot)) : 0;

            sm.open = false;
            sm.closing = false;
            sm.close_frame = UI_OPENED_FRAME_NONE;
            sm.pending_action = "";
            sm.pending_slot = 0;
            gs.ui.save_menu = sm;
            gs.ui.mode = UI_NONE;

            if (pending_action == "load_slot") {
                if (pending_slot >= 1 && pending_slot <= 3 && Save_Read(pending_slot)) {
                    if (variable_struct_exists(sm, "context") && string(sm.context) == "main") {
                        UI_ModalRootHold("gameplay_load");
                    } else {
                        UI_ModalRootEnd(true);
                    }
                    SFX_Play("load_confirm");
                    gs.save_slot = pending_slot;
                } else {
                    UI_ModalRootEnd(false);
                    SFX_PlayUI("ui_back");
                }
            } else if (pending_action == "save_and_reload_slot") {
                if (pending_slot >= 1 && pending_slot <= 3) {
                    if (variable_struct_exists(sm, "context") && string(sm.context) == "bed") {
                        Save_HealPlayerToFull();
                    }
                    Save_Write(pending_slot);
                    SFX_Play("save_confirm");
                    gs.save_slot = pending_slot;
                    if (Save_Read(pending_slot)) {
                        UI_ModalRootEnd(true);
                        gs.pending_save_success_popup = true;
                    } else {
                        UI_ModalRootEnd(false);
                    }
                } else {
                    UI_ModalRootEnd(false);
                }
            } else if (pending_action == "show_no_saves_message") {
                SaveMenu_OpenMessage(Loc_T("save.msg.no_saved_games_found", "No saved games found."), true);
            }
        } else {
            gs.ui.save_menu = sm;
        }
        return;
    }

    if (variable_struct_exists(sm, "require_release") && sm.require_release) {
        var confirm_active = (
            Input_Held("confirm") || Input_Held("interact") ||
            Input_Pressed("confirm") || Input_Pressed("interact")
        );
        if (confirm_active) {
            gs.ui.save_menu = sm;
            return;
        }
        sm.require_release = false;
        gs.ui.save_menu = sm;
        return;
    }

    if (variable_struct_exists(sm, "opened_frame")) {
        if (frame <= sm.opened_frame) {
            gs.ui.save_menu = sm;
            return;
        }
    }

    var k_up = Input_UIPressed("menu_up");
    var k_down = Input_UIPressed("menu_down");
    var k_left = Input_UIPressed("menu_left");
    var k_right = Input_UIPressed("menu_right");
    var k_ok = Input_UIConfirm();
    var k_back = Input_UIBack();

    if (sm.confirm) {
        if (variable_struct_exists(sm, "confirm_closing") && sm.confirm_closing) {
            if (frame - sm.confirm_close_frame >= UI_POPUP_FADE_FRAMES) {
                sm.confirm = false;
                sm.confirm_closing = false;
                sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
                sm.confirm_opened_frame = UI_OPENED_FRAME_NONE;
                if (sm.confirm_mode == "message" && variable_struct_exists(sm, "close_after_message") && sm.close_after_message) {
                    gs.ui.save_menu = sm;
                    SaveMenu_Close(false);
                    return;
                }
            }
            gs.ui.save_menu = sm;
            return;
        }
        if (sm.confirm_mode == "saved" || sm.confirm_mode == "message") {
            if (k_ok || k_back) {
                SFX_PlayUI("ui_confirm");
                sm.confirm_closing = true;
                sm.confirm_close_frame = Input_Frame();
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
            sm.confirm_closing = true;
            sm.confirm_close_frame = Input_Frame();
            gs.ui.save_menu = sm;
            return;
        }
        if (k_ok) {
            SFX_PlayUI("ui_confirm");
            if (sm.confirm_choice == 0) {
                if (sm.confirm_mode == "delete") {
                    SaveMenu_Log("delete slot " + string(sm.slot + 1));
                    Save_Delete(sm.slot + 1);
                    if (variable_struct_exists(sm, "slot_info_cache") && is_array(sm.slot_info_cache) && sm.slot >= 0 && sm.slot < array_length(sm.slot_info_cache)) {
                        sm.slot_info_cache[sm.slot] = Save_SlotInfo(sm.slot + 1);
                    }
                    SFX_Play("delete_confirm");
                    if (sm.mode == "load" && !Save_HasAnySlot()) {
                        gs.ui.save_menu = sm;
                        SaveMenu_Close(false, "show_no_saves_message", 0);
                        return;
                    }
                } else if (sm.confirm_mode == "load") {
                    var load_slot = sm.slot + 1;
                    SaveMenu_Log("load confirmed slot " + string(load_slot));
                    gs.ui.save_menu = sm;
                    SaveMenu_Close(false, "load_slot", load_slot);
                    return;
                } else if (sm.confirm_mode == "overwrite") {
                    var overwrite_slot = sm.slot + 1;
                    SaveMenu_Log("overwrite confirmed slot " + string(overwrite_slot));
                    gs.ui.save_menu = sm;
                    SaveMenu_Close(false, "save_and_reload_slot", overwrite_slot);
                    return;
                } else if (sm.confirm_mode == "save") {
                    var save_slot = sm.slot + 1;
                    SaveMenu_Log("save confirmed slot " + string(save_slot));
                    gs.ui.save_menu = sm;
                    SaveMenu_Close(false, "save_and_reload_slot", save_slot);
                    return;
                }
            }
            sm.confirm_closing = true;
            sm.confirm_close_frame = Input_Frame();
        }
        gs.ui.save_menu = sm;
        return;
    }

    if (hide_slots) {
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
        SaveMenu_Close(false);
        return;
    }

    if (k_ok) {
        if (sm.slot == 3) {
            SFX_PlayUI("ui_back");
            SaveMenu_Close(false);
            return;
        }
        var slot = sm.slot + 1;
        if (sm.mode == "load") {
            if (sm.col == 0) {
                var load_info = Save_SlotInfo(slot);
                if (load_info.exists) {
                    SFX_PlayUI("ui_confirm");
                    sm.confirm = true;
                    sm.confirm_closing = false;
                    sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
                    sm.confirm_mode = "load";
                    sm.confirm_choice = 1; // default to Cancel
                    sm.close_after_message = false;
                    sm.confirm_opened_frame = Input_Frame();
                    SaveMenu_Log("load confirm open slot " + string(slot));
                } else {
                    SFX_PlayUI("ui_back");
                    sm.confirm = true;
                    sm.confirm_closing = false;
                    sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
                    sm.confirm_mode = "message";
                    sm.confirm_choice = 0;
                    sm.message = Loc_T("save.msg.no_game_saves", "No game saves.");
                    sm.close_after_message = true;
                    sm.confirm_opened_frame = Input_Frame();
                    return;
                }
            } else {
                SFX_PlayUI("ui_confirm");
                sm.confirm = true;
                sm.confirm_closing = false;
                sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
                sm.confirm_mode = "delete";
                sm.confirm_choice = 1; // default to Cancel
                sm.close_after_message = false;
                sm.confirm_opened_frame = Input_Frame();
                SaveMenu_Log("delete confirm open slot " + string(slot));
            }
        } else {
            var info = Save_SlotInfo(slot);
            if (info.exists) {
                SFX_PlayUI("ui_confirm");
                sm.confirm = true;
                sm.confirm_closing = false;
                sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
                sm.confirm_mode = "overwrite";
                sm.confirm_choice = 1; // default to Cancel
                sm.close_after_message = false;
                sm.confirm_opened_frame = Input_Frame();
                SaveMenu_Log("overwrite confirm open slot " + string(slot));
            } else {
                SFX_PlayUI("ui_confirm");
                sm.confirm = true;
                sm.confirm_closing = false;
                sm.confirm_close_frame = UI_OPENED_FRAME_NONE;
                sm.confirm_mode = "save";
                sm.confirm_choice = 1; // default Cancel
                sm.close_after_message = false;
                sm.confirm_opened_frame = Input_Frame();
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
    var line_h = UI_TextHeight("A");
    var title_pad_x = max(12, round(line_h * 0.30));
    var title_pad_y = max(10, round(line_h * 0.25));
    var section_gap = max(8, round(line_h * 0.25));
    var pad = 6;
    var side_margin = max(12, title_pad_x);
    var slot_text_left_pad = side_margin + 2;
    var popup_alpha = UI_PopupAlpha(sm.opened_frame, sm.closing, sm.close_frame, 1);
    var hide_slots = variable_struct_exists(sm, "hide_slots") && sm.hide_slots;

    var title = (sm.mode == "load")
        ? Loc_T("save.title.load", "Load Game")
        : Loc_T("save.title.save", "Save Game");

    var slot_labels = array_create(3, "");
    var longest_slot_w = 0;
    for (var li = 0; li < 3; li++) {
        var info_l = undefined;
        if (variable_struct_exists(sm, "slot_info_cache") && is_array(sm.slot_info_cache) && li < array_length(sm.slot_info_cache)) {
            info_l = sm.slot_info_cache[li];
        } else {
            info_l = Save_SlotInfo(li + 1);
        }
        var label_l = Loc_T("save.slot.prefix", "Slot ") + string(li + 1);
        if (info_l.exists) {
            label_l += "  " + info_l.class_name + " " + Loc_T("save.level.short", "Lv") + string(info_l.level) + "  " + info_l.room;
        }
        slot_labels[li] = label_l;
        longest_slot_w = max(longest_slot_w, UI_TextWidth(label_l));
    }

    var delete_label = Loc_T("save.delete", "Delete");
    var delete_pad_x = 8;
    var delete_text_w = UI_TextWidth(delete_label);
    var delete_btn_w = delete_text_w + delete_pad_x * 2;
    var slot_delete_gap = 6;

    var min_content_w = slot_text_left_pad + longest_slot_w + side_margin;
    if (sm.mode == "load") min_content_w += slot_delete_gap + delete_btn_w + side_margin;

    var row_h = max(22, line_h + 8);
    var rows_block_h = hide_slots ? 0 : (row_h * 3 + section_gap + line_h);
    var need_h = title_pad_y + line_h + section_gap + rows_block_h + title_pad_y;
    var bw = min(max(w * 0.7, min_content_w + 20), w - 24);
    var bh = min(h - 24, max(h * 0.6, need_h));
    var bx = (w - bw) * 0.5;
    var by = (h - bh) * 0.5;

    if (!hide_slots) {
        draw_set_alpha(popup_alpha * 0.9);
        draw_set_color(c_black);
        draw_rectangle(bx, by, bx + bw, by + bh, false);
        draw_set_alpha(popup_alpha);
        draw_set_color(c_white);
        draw_rectangle(bx, by, bx + bw, by + bh, true);
        draw_set_alpha(popup_alpha);

        draw_set_color(c_white);
        UI_DrawText(bx + title_pad_x, by + title_pad_y, title);
    }

    var row_y = by + title_pad_y + line_h + section_gap;
    var delete_right = bx + bw - side_margin;
    var delete_left = delete_right - delete_btn_w;
    var delete_text_x = delete_left + delete_pad_x;
    var slot_select_right = (sm.mode == "load") ? (delete_left - slot_delete_gap) : (bx + bw - side_margin);
    slot_select_right = max(bx + 40, slot_select_right);
    var slot_text_x = bx + slot_text_left_pad;
    var slot_text_max_w = max(24, slot_select_right - slot_text_x - 4);
    if (!hide_slots) {
        for (var i = 0; i < 3; i++) {
            var yy = row_y + i * row_h;
            var label = slot_labels[i];
            var draw_label = label;
            if (UI_TextWidth(draw_label) > slot_text_max_w) {
                while (string_length(draw_label) > 0 && UI_TextWidth(draw_label + "...") > slot_text_max_w) {
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
            UI_DrawText(slot_text_x, yy, draw_label);

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
                UI_DrawText(delete_text_x, yy, delete_label);
            }
        }
    }

    // Back label
    var back_x = bx + title_pad_x;
    var back_y = by + bh - (title_pad_y + line_h);
    if (!hide_slots) {
        if (sm.slot == 3 && !sm.confirm) {
            var back_label = Loc_T("save.back", "Back");
            var bwid = UI_TextWidth(back_label);
            draw_set_color(c_white);
            draw_rectangle(back_x - 4, back_y - 2, back_x + bwid + 4, back_y + line_h + 2, false);
            draw_set_color(c_black);
            draw_rectangle(back_x - 4, back_y - 2, back_x + bwid + 4, back_y + line_h + 2, true);
            draw_set_color(c_black);
        } else {
            draw_set_color(c_white);
        }
        UI_DrawText(back_x, back_y, Loc_T("save.back", "Back"));
    } else {
        draw_set_color(c_white);
    }

    if (sm.confirm) {
        var confirm_fade_frame = sm.opened_frame;
        if (variable_struct_exists(sm, "confirm_opened_frame") && sm.confirm_opened_frame != UI_OPENED_FRAME_NONE) {
            confirm_fade_frame = sm.confirm_opened_frame;
        }
        var confirm_alpha = UI_PopupAlpha(
            confirm_fade_frame,
            variable_struct_exists(sm, "confirm_closing") && sm.confirm_closing,
            variable_struct_exists(sm, "confirm_close_frame") ? sm.confirm_close_frame : UI_OPENED_FRAME_NONE,
            1
        );
        var cx = bx + bw * 0.5;
        var cy = by + bh * 0.7;
        var msg = "";
        if (sm.confirm_mode == "delete") msg = Loc_T("save.confirm.delete", "Delete slot?");
        else if (sm.confirm_mode == "load") msg = Loc_T("save.confirm.load", "Load save?");
        else if (sm.confirm_mode == "overwrite") msg = Loc_T("save.confirm.overwrite", "Overwrite save?");
        else if (sm.confirm_mode == "save") msg = Loc_T("save.confirm.save", "Save to slot?");
        else msg = sm.message;

        var popup_pad_x = 12;
        var popup_pad_y = 8;
        var popup_gap_y = 8;
        var btn_pad_x = 8;
        var btn_h = line_h + 4;
        var msg_w = UI_TextWidth(msg);

        var buttons_w = 0;
        if (sm.confirm_mode != "saved" && sm.confirm_mode != "message") {
            buttons_w = (UI_TextWidth(Loc_T("common.ok", "OK")) + btn_pad_x * 2) + 14 + (UI_TextWidth(Loc_T("common.cancel", "Cancel")) + btn_pad_x * 2);
        } else {
            buttons_w = UI_TextWidth(Loc_T("common.ok", "OK")) + btn_pad_x * 2;
        }

        var popup_w = max(160, max(msg_w + popup_pad_x * 2, buttons_w + popup_pad_x * 2));
        var popup_h = popup_pad_y + line_h + popup_gap_y + btn_h + popup_pad_y;
        var px1 = cx - popup_w * 0.5;
        var py1 = cy - popup_h * 0.5;
        var px2 = px1 + popup_w;
        var py2 = py1 + popup_h;

        draw_set_alpha(confirm_alpha * 0.9);
        draw_set_color(c_black);
        draw_rectangle(px1, py1, px2, py2, false);
        draw_set_alpha(confirm_alpha);
        draw_set_color(c_white);
        draw_rectangle(px1, py1, px2, py2, true);
        draw_set_alpha(confirm_alpha);
        draw_set_color(c_white);

        var msg_x = px1 + (popup_w - msg_w) * 0.5;
        var msg_y = py1 + popup_pad_y;
        UI_DrawText(msg_x, msg_y, msg);
        var btn_y = msg_y + line_h + popup_gap_y;

        if (sm.confirm_mode != "saved" && sm.confirm_mode != "message") {
            var yes_label = Loc_T("common.ok", "OK");
            var no_label = Loc_T("common.cancel", "Cancel");
            var yes_w = UI_TextWidth(yes_label) + btn_pad_x * 2;
            var no_w = UI_TextWidth(no_label) + btn_pad_x * 2;
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
            UI_DrawText(yesx + (yes_w - UI_TextWidth(yes_label)) * 0.5, btn_y + 2, yes_label);

            if (sm.confirm_choice == 1) {
                draw_set_color(c_white);
                draw_rectangle(nox, btn_y, nox + no_w, btn_y + btn_h, false);
                draw_set_color(c_black);
                draw_rectangle(nox, btn_y, nox + no_w, btn_y + btn_h, true);
                draw_set_color(c_black);
            } else {
                draw_set_color(c_white);
            }
            UI_DrawText(nox + (no_w - UI_TextWidth(no_label)) * 0.5, btn_y + 2, no_label);
        } else {
            var ok_label = Loc_T("common.ok", "OK");
            var ok_w = UI_TextWidth(ok_label) + btn_pad_x * 2;
            var ok_x = px1 + (popup_w - ok_w) * 0.5;
            draw_set_color(c_white);
            draw_rectangle(ok_x, btn_y, ok_x + ok_w, btn_y + btn_h, false);
            draw_set_color(c_black);
            draw_rectangle(ok_x, btn_y, ok_x + ok_w, btn_y + btn_h, true);
            draw_set_color(c_black);
            UI_DrawText(ok_x + (ok_w - UI_TextWidth(ok_label)) * 0.5, btn_y + 2, ok_label);
        }
    }
    draw_set_alpha(1);
}
