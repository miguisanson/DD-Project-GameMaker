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
step_from_x = x;
step_from_y = y;
exit_ignore = noone;   // D64: the exit tile the player arrived on; it does not fire until the player has stepped off it (armed at the end of this event after a battle return)
// D69 / D70: turn on a tap, buffered corner, run, bump, interact prompt
walk_speed = (16 mod max(1, move_speed) == 0) ? move_speed : 1;   // pixels per frame; must divide the 16 px tile
run_speed = 2;
step_speed = walk_speed;
turn_frames = 6;       // a direction held for this long after turning starts the walk; a shorter tap only turns
turn_timer = 0;
buffer_frames = 10;    // a direction pressed during a step is remembered this many frames for the next step
buf_dir = -1;
buf_age = 99;
bump_dir = -1;         // direction already bumped for this press
bump_count = 0;
bump_timer = 0;
bump_dx = 0;
bump_dy = 0;
bump_applied = false;
prompt_target = noone; // interactable the player faces right now (drives the prompt)
auto_resolve_recover_timer = 0;
auto_resolve_recover_total = 0;
auto_resolve_recover_progress = 0;
auto_resolve_recover_start_x = x;
auto_resolve_recover_start_y = y;
auto_resolve_recover_target_x = x;
auto_resolve_recover_target_y = y;

// D64: put back (battle return, Continue / load) on an exit tile: that exit ignores the player until they step off it. (A room change arms it in RoomTransition_Apply.)
if (just_returned) Player_ArmExitIgnore(id);
