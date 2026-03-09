// --------------------
// ID / BATTLE
// --------------------
var gs = GameState_Init();

if (!variable_instance_exists(id, "persist_id")) persist_id = "";
RoomState_EnsurePersistId(id);

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
think_rate    = ENEMY_THINK_RATE_DEFAULT;   // decision delay (frames)
forget_delay  = ENEMY_FORGET_DELAY_DEFAULT; // memory duration
leash_mult    = ENEMY_LEASH_MULT_DEFAULT;
wander_chance = ENEMY_WANDER_CHANCE_DEFAULT; // idle wander chance (0 = never wander)

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
tile_size  = GRID_TILE_SIZE;
move_speed = ENEMY_MOVE_SPEED_DEFAULT;
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
// ENCOUNTER DEFER/SETTLE
// --------------------
encounter_pending = false;
encounter_player = noone;

// --------------------
// FINALIZE LEASH
// --------------------
leash_radius = scan_radius * leash_mult;
