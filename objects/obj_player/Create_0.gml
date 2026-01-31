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
move_speed = 1;

if (!just_returned) {
    face = DOWN;
}

moving = false;
move_dir = -1;
move_timer = 0;
tile_size = 16;
if (just_returned) {
    x = round(x / tile_size) * tile_size;
    y = round(y / tile_size) * tile_size;
}

