// --------------------
// REGISTER PLAYER INSTANCE (CRITICAL)
// --------------------
var gs = GameState_Init();
GameState_SetPlayerInst(id);

// --------------------
// BATTLE COOLDOWN
// --------------------
battle_cooldown = 0;

if (gs.battle.just_returned) {
    x = gs.battle.return_x;
    y = gs.battle.return_y;
    GameState_SetJustReturned(false);

    battle_cooldown = BATTLE_COOLDOWN_FRAMES;
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

face = DOWN;

moving = false;
move_dir = -1;
move_timer = 0;
tile_size = 16;
