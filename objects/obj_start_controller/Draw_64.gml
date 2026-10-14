Display_DrawFrame();   // first Draw GUI of the frame draws the world
var w = Display_GuiW();
var h = Display_GuiH();
var gs = GameState_Get();
if (state == "boot_logo") {
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);

    var logo_spr = boot_logo_sprite;
    if (logo_spr == noone || logo_spr == -1) logo_spr = pale_rook_1;
    if (logo_spr != noone && logo_spr != -1 && boot_logo_alpha > 0) {
        var logo_scale = UI_GetSpriteScale(3);
        var lw = sprite_get_width(logo_spr) * logo_scale;
        var lh = sprite_get_height(logo_spr) * logo_scale;
        var lx = round((w - lw) * 0.5);
        var ly = round((h - lh) * 0.5);
        draw_set_color(c_white);
        draw_sprite_ext(logo_spr, 0, lx, ly, logo_scale, logo_scale, 0, c_white, clamp(boot_logo_alpha, 0, 1));
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
    exit;
}
if (state == "cutscene") exit;
if (state == "run_flow") {   // C1: run summary and echo pick after the death scene (placeholder screens)
    RunFlow_Draw();
    draw_set_alpha(1);
    Build_DrawId();
    exit;
}
var loading_into_game = Transition_IsActive()
&& variable_struct_exists(gs, "in_main_menu")
&& !gs.in_main_menu;

if (room == rm_start && title_bg_sprite != noone) {
    draw_sprite_stretched(title_bg_sprite, 0, 0, 0, w, h);
}

if ((state == "main" || state == "difficulty") && gs.ui.mode != UI_SAVE && !loading_into_game) {
    Title_Draw(id);   // scr_menu.gml: the menu stack on the UI framework
}

if (SettingsPopup_IsOpen("title") && !loading_into_game) {
    SettingsPopup_Draw();
}
draw_set_alpha(1);
Scenario_DrawUiKit();   // inert unless the -shots run asks for the kit picture
Build_DrawId();
