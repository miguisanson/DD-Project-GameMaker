// --------------------
// ID / BATTLE
// --------------------
var gs = GameState_Init();

if (!variable_instance_exists(id, "persist_id")) persist_id = "";

if (!variable_instance_exists(id, "enemy_uid")) {
    enemy_uid = GameState_NextUID();
} else if (enemy_uid == noone) {
    enemy_uid = GameState_NextUID();
}

enemy_id = -1;     // set in child
defeated = false;
enemy_cfg = undefined;

// --------------------
// DEFAULT TUNING (CHILD CAN OVERRIDE)
// --------------------
scan_radius   = ENEMY_SCAN_RADIUS_DEFAULT;
think_rate    = 15;   // decision delay (frames)
forget_delay  = 30;   // memory duration
leash_mult    = 2;
wander_chance = 4;    // idle wander chance (0 = never wander)

leash_radius  = 0;

// --------------------
// AI STATE
// --------------------
ai_state    = ENEMY_IDLE;
forget_time = 0;

// spawn/home
home_x = x;
home_y = y;

// --------------------
// GRID MOVEMENT
// --------------------
tile_size  = 16;
move_speed = 1;
moving     = false;
move_dir   = -1;
move_timer = 0;

// --------------------
// THINK DESYNC
// --------------------
think_delay = irandom(think_rate);

// --------------------
// VISUAL
// --------------------
image_speed = 0.15;

// --------------------
// FINALIZE LEASH
// --------------------
leash_radius = scan_radius * leash_mult;
