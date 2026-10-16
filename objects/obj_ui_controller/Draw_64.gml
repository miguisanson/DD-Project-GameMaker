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

if (gs.ui.mode == UI_MENU) {
    if (room != rm_battle) Menu_Draw();   // D140: in a fight the battle controller draws it, after its own HUD
    MouseCursor_Draw();   // D182: the mouse cursor, over the menu
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
ShopUi_Draw();    // C3 (D85): the merchant's shop
Hud_DrawGold();   // C3 (D23): the run's gold, in the world and in battle

Dialogue_Draw();   // D101: the framed box with the speaker tab, the typewriter text, the arrow and any choices

Notice_Draw();   // F3a: the notice pop-up (D96), over the screens above and under the banner, the tutorial and the fade

if (gs.ui.mode == UI_BED) {
    BedMenu_Draw();
}

if (room != rm_start) Confirm_Draw();   // D156: the shared Yes / No pop-up over the class, echo, skill and shop screens (the title draws its own; the menu draws its own)

Banner_Draw();   // C5 (D106): boss name banner

if (room != rm_battle) Tutorial_Draw();   // C4 (D45): the first-time pop-up, over everything but the fade (in a battle the battle controller draws it, later)

Transition_DrawGUI();

Skip_DrawHint();   // D48 / D146: the "Hold to skip" prompt after 1 s of holding (nothing on a tap or when no skippable scene is running)

MouseCursor_Draw();   // D182: the mouse cursor, on top of everything above (the fade, the pop-ups, the tutorial); the battle controller draws it again after its own HUD
