var gs = GameState_Get();
var w = display_get_gui_width();
var h = display_get_gui_height();
var margin = 8;

UI_SetFont();

draw_set_alpha(1);

// HUD (battle only)
var ch = gs.player_ch;
if (room == rm_battle && instance_exists(obj_battle_controller)) {
    var bc = instance_find(obj_battle_controller, 0);
    if (instance_exists(bc) && is_struct(bc.p)) ch = bc.p;
}

if (room == rm_battle && is_struct(ch)) {
    var hp_bar_sprite = hp_bar;
    var mp_bar_sprite = mp_bar;
    var max_frame = min(10, sprite_get_number(hp_bar_sprite) - 1);
    if (max_frame < 0) max_frame = 0;

    var hp_ratio = 0;
    if (ch.max_hp > 0) hp_ratio = clamp(ch.hp / ch.max_hp, 0, 1);
    var hp_frame = clamp(floor(hp_ratio * max_frame), 0, max_frame);

    var mp_ratio = 0;
    if (ch.max_mp > 0) mp_ratio = clamp(ch.mp / ch.max_mp, 0, 1);
    var mp_frame = clamp(floor(mp_ratio * max_frame), 0, max_frame);

    var scale = UI_BAR_SCALE;
    var bar_w = sprite_get_width(hp_bar_sprite) * scale;
    var bar_h = sprite_get_height(hp_bar_sprite) * scale;

    var cam = view_camera[0];
    var sx = w / camera_get_view_width(cam);
    var sy = h / camera_get_view_height(cam);
    var cam_off = CameraShake_Offset();
    var gui_off_x = cam_off.x * sx;
    var gui_off_y = cam_off.y * sy;

    var bar_x = margin + gui_off_x;
    var bar_y = margin + gui_off_y;
    draw_sprite_ext(hp_bar_sprite, hp_frame, bar_x, bar_y, scale, scale, 0, c_white, 1);
    draw_sprite_ext(mp_bar_sprite, mp_frame, bar_x, bar_y + bar_h + 4, scale, scale, 0, c_white, 1);
    if (variable_instance_exists(id, "hud_hurt_flash_timer") && hud_hurt_flash_timer > 0) {
        var flash_t = clamp(hud_hurt_flash_timer / max(1, UI_HUD_HURT_FLASH_FRAMES), 0, 1);
        var flash_a = UI_HUD_HURT_FLASH_ALPHA * flash_t;
        gpu_set_blendmode(bm_add);
        draw_sprite_ext(hp_bar_sprite, hp_frame, bar_x, bar_y, scale, scale, 0, c_white, flash_a);
        draw_sprite_ext(mp_bar_sprite, mp_frame, bar_x, bar_y + bar_h + 4, scale, scale, 0, c_white, flash_a);
        gpu_set_blendmode(bm_normal);
    }

    draw_set_color(c_white);
    var hp_text = string(ch.hp) + " / " + string(ch.max_hp);
    var mp_text = string(ch.mp) + " / " + string(ch.max_mp);
    draw_text(bar_x + bar_w + 6, bar_y, hp_text);
    draw_text(bar_x + bar_w + 6, bar_y + bar_h + 4, mp_text);

    // Player status icons below MP bar
    var icon_y = bar_y + (bar_h * 2) + 10;
    Status_DrawIcons(ch, bar_x, icon_y, 12, false);

}

UI_DrawModalDim();

if (gs.ui.mode == UI_PAUSE) {
    PauseMenu_Draw();
    exit;
}

if (gs.ui.mode == UI_MENU) {
    Menu_Draw();
    exit;
}

var cutscene_active = variable_struct_exists(gs.ui, "cutscene_active") && gs.ui.cutscene_active;
if (cutscene_active) {
    var bg_sprite = variable_struct_exists(gs.ui, "cutscene_bg_sprite") ? gs.ui.cutscene_bg_sprite : noone;
    if (bg_sprite != noone) {
        draw_sprite_stretched(bg_sprite, 0, 0, 0, w, h);
    }
}

if (gs.ui.mode == UI_CLASS_SELECT) {
    ClassSelect_Draw();
}

// Dialogue box
if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
    var box = Dialogue_BoxRect();
    var bx = box.x;
    var by = box.y;
    var bw = box.w;
    var bh = box.h;
    var cutscene_text_only = Dialogue_IsCutsceneTextOnly();

    if (!cutscene_text_only) {
        draw_set_alpha(0.85);
        draw_set_color(c_black);
        draw_rectangle(bx, by, bx + bw, by + bh, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_rectangle(bx, by, bx + bw, by + bh, true);
    }

    var line = "";
    var line_entry = "";
    var line_icon_sprite = noone;
    var line_icon_subimg = 0;
    if (array_length(gs.ui.lines) > 0) {
        if (gs.ui.index >= 0 && gs.ui.index < array_length(gs.ui.lines)) {
            line_entry = gs.ui.lines[gs.ui.index];
            line = Dialogue_LineText(line_entry);
            if (is_struct(line_entry) && variable_struct_exists(line_entry, "icon_sprite")) {
                line_icon_sprite = line_entry.icon_sprite;
            }
            if (is_struct(line_entry) && variable_struct_exists(line_entry, "icon_subimg")) {
                line_icon_subimg = round(line_entry.icon_subimg);
            }
        }
    }

    var speaker = "";
    if (variable_struct_exists(gs.ui, "speaker")) speaker = gs.ui.speaker;
    var layout = Dialogue_TextLayout(speaker);
    var icon_draw_w = 0;
    if (line_icon_sprite != noone && line_icon_sprite != -1) {
        var icon_max_sub = max(0, sprite_get_number(line_icon_sprite) - 1);
        line_icon_subimg = clamp(line_icon_subimg, 0, icon_max_sub);
        icon_draw_w = max(10, sprite_get_width(line_icon_sprite)) + 4;
    }
    var text_x = layout.text_x + icon_draw_w;
    var text_y = layout.text_y;

    draw_set_color(c_white);
    if (speaker != "") {
        if (cutscene_text_only) {
            draw_set_color(c_black);
            draw_text(layout.speaker_x + UI_CUTSCENE_TEXT_SHADOW_X, layout.speaker_y + UI_CUTSCENE_TEXT_SHADOW_Y, speaker + ":");
            draw_set_color(c_white);
        }
        draw_text(layout.speaker_x, layout.speaker_y, speaker + ":");
        Dialogue_TypewriterPrepareCurrentLine();
        var page_text0 = variable_struct_exists(gs.ui, "dialogue_full_text") ? gs.ui.dialogue_full_text : line;
        var visible_count0 = variable_struct_exists(gs.ui, "dialogue_visible_count") ? gs.ui.dialogue_visible_count : string_length(page_text0);
        visible_count0 = clamp(visible_count0, 0, string_length(page_text0));
        var visible_text0 = string_copy(page_text0, 1, visible_count0);
        if (icon_draw_w > 0) draw_sprite(line_icon_sprite, line_icon_subimg, layout.text_x, text_y + 1);
        if (cutscene_text_only) {
            draw_set_color(c_black);
            draw_text(text_x + UI_CUTSCENE_TEXT_SHADOW_X, text_y + UI_CUTSCENE_TEXT_SHADOW_Y, visible_text0);
            draw_set_color(c_white);
        }
        draw_text(text_x, text_y, visible_text0);
    } else {
        Dialogue_TypewriterPrepareCurrentLine();
        var page_text = variable_struct_exists(gs.ui, "dialogue_full_text") ? gs.ui.dialogue_full_text : line;
        var visible_count = variable_struct_exists(gs.ui, "dialogue_visible_count") ? gs.ui.dialogue_visible_count : string_length(page_text);
        visible_count = clamp(visible_count, 0, string_length(page_text));
        var visible_text = string_copy(page_text, 1, visible_count);
        if (icon_draw_w > 0) draw_sprite(line_icon_sprite, line_icon_subimg, layout.text_x, text_y + 1);
        if (cutscene_text_only) {
            draw_set_color(c_black);
            draw_text(text_x + UI_CUTSCENE_TEXT_SHADOW_X, text_y + UI_CUTSCENE_TEXT_SHADOW_Y, visible_text);
            draw_set_color(c_white);
        }
        draw_text(text_x, text_y, visible_text);
    }
    if (gs.ui.mode == UI_DIALOGUE && array_length(gs.ui.lines) > 0
    && variable_struct_exists(gs.ui, "dialogue_state") && gs.ui.dialogue_state == UI_DIALOGUE_STATE_READY) {
        var icon = dialogue_arrow_down;
        if (icon != -1) {
            var line_h = max(8, string_height("Ag"));
            var cue_w = max(6, round(line_h * 0.8));
            var cue_h = max(4, round(line_h * 0.4));
            var blink = (floor(gs.ui.icon_frame) mod 2);
            var bob = blink ? 0 : UI_DIALOGUE_ARROW_BOB_PX;

            var iw = max(1, sprite_get_width(icon));
            var ih = max(1, sprite_get_height(icon));
            var scale_x = cue_w / iw;
            var scale_y = cue_h / ih;
            var cue_pad = cutscene_text_only ? 2 : 8;
            var cue_right = cutscene_text_only ? (layout.box.x + layout.box.w) : (bx + bw);
            var cue_bottom = cutscene_text_only ? (layout.box.y + layout.box.h) : (by + bh);
            var dx = round(cue_right - cue_w - cue_pad);
            var dy = round(cue_bottom - cue_h - cue_pad + bob);
            draw_sprite_ext(icon, 0, dx, dy, scale_x, scale_y, 0, c_white, 1);
        }
    }

}



if (gs.ui.mode == UI_SAVE) {
    SaveMenu_Draw();
}

if (gs.ui.mode == UI_BED) {
    BedMenu_Draw();
}

Transition_DrawGUI();
