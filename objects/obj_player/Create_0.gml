// --------------------
// REGISTER PLAYER INSTANCE (CRITICAL)
// --------------------
var gs = GameState_Init();
GameState_SetPlayerInst(id);

// --------------------
// BATTLE COOLDOWN
// --------------------
battle_cooldown = 0;
var just_returned = gs.battle.just_returned;

if (just_returned) {
    x = gs.battle.return_x;
    y = gs.battle.return_y;
    GameState_SetJustReturned(false);

    battle_cooldown = BATTLE_COOLDOWN_FRAMES;
    if (variable_struct_exists(gs.battle, "return_face") && gs.battle.return_face != -1) {
        face = gs.battle.return_face;
    } else {
        face = DOWN;
    }
}

// --------------------
// SAFETY INIT
// --------------------
// --------------------
// LOAD CHARACTER DATA
// --------------------
character = gs.player_ch;
Player_ApplyClassSprites(character.class_id);

// --------------------
// MOVEMENT SETUP
// --------------------
xspeed = 0;
yspeed = 0;
move_speed = PLAYER_MOVE_SPEED_DEFAULT;

if (!just_returned) {
    face = DOWN;
}

moving = false;
move_dir = -1;
move_timer = 0;
tile_size = GRID_TILE_SIZE;
auto_resolve_recover_timer = 0;
auto_resolve_recover_total = 0;
auto_resolve_recover_progress = 0;
auto_resolve_recover_start_x = x;
auto_resolve_recover_start_y = y;
auto_resolve_recover_target_x = x;
auto_resolve_recover_target_y = y;
