// The bed is a rest site now (D47): BedUi_* in scr_menu. obj_ui_controller still calls these two names for gs.ui.mode == UI_BED.
function BedMenu_Handle() {
    BedUi_Handle();
}

function BedMenu_Draw() {
    BedUi_Draw();
}

