Display_DrawFrame();   // first Draw GUI of the frame draws the world (moves to obj_display's Draw GUI Begin)
var gs = GameState_Get();
var w = Display_GuiW();
var h = Display_GuiH();

UI_SetFont();
var ui_visual = UI_GetVisualScale();
var ui_sprite = UI_GetSpriteScale();
var margin = max(6, round(8 * ui_visual));

draw_set_alpha(1);

// The battle's HUD (HP, MP, statuses, strip, log, menus) is drawn by obj_battle_controller (D99).

var skip_shared_modal_dim = false;
if (room == rm_start && instance_exists(obj_start_controller)) {
    var start_ctrl = instance_find(obj_start_controller, 0);
    if (instance_exists(start_ctrl)
    && variable_instance_exists(start_ctrl, "state")
    && string(start_ctrl.state) == "difficulty") {
        skip_shared_modal_dim = true;
    }
}
if (!skip_shared_modal_dim) UI_DrawModalDim();

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

    var logo_sprite = variable_struct_exists(gs.ui, "cutscene_logo_sprite") ? gs.ui.cutscene_logo_sprite : noone;
    var logo_alpha = variable_struct_exists(gs.ui, "cutscene_logo_alpha") ? clamp(real(gs.ui.cutscene_logo_alpha), 0, 1) : 0;
    if (logo_sprite != noone && logo_sprite != -1 && logo_alpha > 0) {
        var logo_scale = UI_GetSpriteScale(3);
        var lw = sprite_get_width(logo_sprite) * logo_scale;
        var lh = sprite_get_height(logo_sprite) * logo_scale;
        var lx = round((w - lw) * 0.5);
        var ly = round((h - lh) * 0.5);
        draw_set_color(c_white);
        draw_sprite_ext(logo_sprite, 0, lx, ly, logo_scale, logo_scale, 0, c_white, logo_alpha);
        draw_set_alpha(1);
    }
}

CardsUi_Draw();   // C2: class choice, stat point, card pick, replace a skill

Dialogue_Draw();   // D101: the framed box with the speaker tab, the typewriter text, the arrow and any choices

if (gs.ui.mode == UI_SAVE) {
    SaveMenu_Draw();
}

if (gs.ui.mode == UI_BED) {
    BedMenu_Draw();
}

Banner_Draw();   // C5 (D106): boss name banner

Transition_DrawGUI();

Skip_DrawHint();   // D48: the "hold to skip" fill after a press (nothing when no skippable scene is running)
