// --------------------
// SAFETY: PLAYER MUST EXIST
// --------------------
var gs = GameState_Init();

// --------------------
// LOAD PLAYER & ENEMY
// --------------------
p = gs.player_ch;
e = EnemyCreate(gs.battle.enemy_id);

// --------------------
// CREATE ENEMY VISUAL (CENTERED)
// --------------------
var sw = 16;
var sh = 16;
if (e.sprite != noone) {
    sw = sprite_get_width(e.sprite);
    sh = sprite_get_height(e.sprite);
}

// fixed battle resolution (GB-style)
var cx = 160 div 2;
var cy = 144 div 2;

enemy_inst = instance_create_layer(
    cx - sw div 2,
    cy - sh div 2,
    "Instances",
    obj_enemy_battle
);

if (e.sprite != noone) enemy_inst.sprite_index = e.sprite;
enemy_inst.visible = false;

enemy_fx_x = enemy_inst.x;
enemy_fx_y = enemy_inst.y;
player_fx_x = cx - 48;
player_fx_y = cy + 24;

// --------------------
// INITIATIVE (REROLL TIES)
// --------------------
var playeri;
var enemyi;

do {
    playeri = Combat_Initiative(p);
    enemyi  = Combat_Initiative(e);
} until (playeri != enemyi);

if (playeri > enemyi) {
    turn = TURN_PLAYER;
} else {
    turn = TURN_ENEMY;
}

// --------------------
// BATTLE STATE
// --------------------
battle_over  = false;
battle_state = BSTATE_MESSAGE;
wait_fx = noone;
wait_timer = COMBAT_ACTION_DELAY;
combat_log = [];
skill_banner_active = false;
skill_banner_name = "";

menu_index = 0;
battle_actions = [
    { label: "FIGHT", state: BSTATE_PLAYER_ATTACK },
    { label: "SKILL", state: BSTATE_SKILL_MENU },
    { label: "ITEM",  state: BSTATE_ITEM_MENU },
    { label: "RUN",   state: BSTATE_PLAYER_RUN }
];
menu_count = array_length(battle_actions);
skill_index = 0;
item_index = 0;

// --------------------
// MESSAGE SETUP
// --------------------
message_text = e.name + " appeared!";
Combat_Log(message_text);

// camera shake base
cam_base_x = camera_get_view_x(view_camera[0]);
cam_base_y = camera_get_view_y(view_camera[0]);

if (turn == TURN_PLAYER) {
    message_next_state = BSTATE_MENU;
} else {
    message_next_state = BSTATE_ENEMY_ACT;
}

// --------------------
// LAST ACTION CACHE (OPTIONAL)
// --------------------
last_hit  = false;
last_dmg  = 0;
last_crit = false;

// --------------------
// CACHE WEAPONS
// --------------------
player_weapon = ItemDB_Get(p.equip.weapon);
if (player_weapon.id == 0) player_weapon = { power:1, stat_type:STAT_STR, acc:0, preferred_class:-1 };

enemy_weapon = { power:2, stat_type:STAT_STR, acc:0, preferred_class:-1 };
if (e.weapon_id != 0) {
    enemy_weapon = ItemDB_Get(e.weapon_id);
}
