// --------------------
// SAFETY: PLAYER MUST EXIST
// --------------------
var gs = GameState_Init();

// --------------------
// LOAD PLAYER & ENEMY
// --------------------
p = gs.player_ch;
p = Equip_PassiveBattleReset(p);
e = EnemyCreate(gs.battle.enemy_id);
e = Elite_Apply(e, Elite_BattleMod());   // C3 (D86): the map enemy's modifier (stats, name, tag)
EnemyPersist_RestoreStolen(e);           // hunt 6 (I-072): what it kept from an earlier escape is on it again
Codex_RecordMeeting(e.id, e.is_elite);   // D88: the bestiary lists the enemies met
throw_item = -1;                          // C3 (D84): the throwable whose bar is running, -1 = a plain attack
Card_OnBattleStart(p, e);   // C2: Opening Blow
var bg_room = gs.battle.enemy_room;
Battle_BgApply(room_exists(bg_room) ? Run_FloorOfRoomName(room_get_name(bg_room)) : 0, e.is_boss);   // H9 (D151): the backdrop by depth, a boss fight gets the arena

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
var cx = DISPLAY_BASE_W div 2;
var cy = (DISPLAY_BASE_H div 2) - 14;   // D99: a little above the middle, so the bottom panels, the lists and the log have room under it

enemy_inst = instance_create_layer(
    cx - sw div 2,
    cy - sh div 2,
    "Instances",
    obj_enemy_battle
);

if (e.sprite != noone) enemy_inst.sprite_index = e.sprite;
enemy_inst.visible = false;

var enemy_center = FX_CenterOn(noone, enemy_inst);
enemy_fx_x = enemy_center.x;
enemy_fx_y = enemy_center.y;
player_fx_x = cx - 48;
player_fx_y = cy + 24;

// --------------------
// TURN TIMELINE (D74, spec section 11): a gauge per fighter fills by SPD; the one that fills acts. The higher SPD is first, a tie goes to the player.
// The player acts twice before a slow enemy; nothing alternates and no skill grants extra actions.
// --------------------
tl = Turn_New([
    Turn_Fighter(TL_PLAYER, Combat_EffectiveStat(p, STAT_SPD)),
    Turn_Fighter(TL_ENEMY, Combat_EffectiveStat(e, STAT_SPD), e.is_boss)
]);
tl_who = Turn_Next(tl);                       // whose turn it is now (the first slot of the strip)
turn = (tl_who == TL_PLAYER) ? TURN_PLAYER : TURN_ENEMY;
tl_prev_who = tl_who;
turn_log = [tl_who];                          // every turn taken, in order (TL_PLAYER / TL_ENEMY): the bot checks the real flow against the timeline model
enemy_action_pending = (tl_who == TL_ENEMY);   // the enemy's turn has started but it has not acted yet (Foresight shows its plan on the current slot)
tl_slide_kind = 1;
tl_slide_start = current_time - 100000;       // D97: the strip slides TURN_SLIDE_MS when the order changes
pops = [];                                    // D92: floating damage numbers
break_start = current_time - 100000;          // the BREAK word and the meter flash
stagger_flash_start = current_time - 100000;
enemy_hp_shown = e.hp;                        // the HP bar glides to the real value (D97)
enemy_hp_clock = current_time;

// --------------------
// BATTLE STATE
// --------------------
battle_over  = false;
battle_state = BSTATE_MESSAGE;
wait_fx = noone;
wait_timer = COMBAT_ACTION_DELAY_MS;   // ms left on the message hold (D108 F2b-1)
combat_log = [];
skill_banner_active = false;
skill_banner_name = "";
enemy_actions_remaining = 0;
run_fails = 0;                   // R1 (D121): failed flee tries this battle
enemy_turn_used_skills = [];
player_turn_start_applied = false;
enemy_plan = undefined;          // Foresight (D79): { skill_id, announced }, the enemy's next action once decided
enemy_last_skill_id = -1;
ai = EnemyAI_StateNew();           // B4: the enemy's own turn counter, rule uses, the pending wind-up and the boss phase (combat-spec.md section 12)
phase_banner = "";               // B4: a boss phase change waiting to be announced at the enemy's next action
enemy_last_windup = -1;          // the skill the enemy last wound up (bot and tests read it)
qte_perfect_widen = 1;
def_perfect_widen = 1;

menu_index = 0;          // the command cursor: the menu owns it (ui_cmd.cursor), this mirrors it for the bot and the tests
skill_index = 0;         // the same for the skill and item lists
item_index = 0;
ui_cmd = undefined;      // D95 / D99: the command, skill and item menus are Ui_Menu objects (Battle_MenusBuild, Battle_MenusStep, Battle_DrawMenus)
ui_skill = undefined;
ui_item = undefined;
ui_sig = {};
hud = { clock: current_time, hp_shown: p.hp, mp_shown: p.mp, rects: {}, lag_hp: p.hp, lag_from: p.hp, lag_start: current_time };   // the player panel's glided bars, and the rectangles the last draw used
// each fight starts on Attack with the lists at their top (the cursors are remembered inside a fight, D95)
Ui_MemSet(Ui_MemGlobal(), "battle_cmd", 0);
Ui_MemSet(Ui_MemGlobal(), "battle_skill", 0);
Ui_MemSet(Ui_MemGlobal(), "battle_item", 0);
Battle_MenusBuild(self);

// The basic attack's sliding bar (D56). qte_ms is the bar's own clock in ms: negative in the lead-in, 0 when the cursor starts.
qte_active = false;
qte_params = Qte_BarParams("default");
qte_assist = 1;
qte_ms = 0;
qte_press_ms = QTE_NO_PRESS;
qte_result_text = "";
qte_result_key = "";
qte_result_mult = 1;
qte_result_ms = 0;
qte_word_x = 0;
qte_word_y = 0;
hitstop_ms = 0;
Battle_FeelInit(self);   // D138 / D139: the hit freeze, sparks, jolt, recoil, zoom punch, death pop, big-hit flash and low-HP warning

// A player skill's arrow sequence (D57, D58). sq_st is the pure state (Qte_SeqNew); sq_ms is the clock, negative in the lead-in.
sq_active = false;
sq_skill = -1;
sq_st = {};
sq_ms = 0;
sq_wrong_ms = 0;
sq_pop_ms = 0;
sq_pop_idx = -1;

// The defence bar against a big enemy attack (D59). def_ms is its clock: the telegraph, then the lead-in (both negative), then the sweep from 0.
def_active = false;
def_skill_id = -1;
def_params = Qte_BarParams("default");
def_assist = 1;
def_ms = 0;
def_press_ms = QTE_NO_PRESS;
def_ctx = {};

// --------------------
// MESSAGE SETUP
// --------------------
message_text = Loc_T("combat.msg.enemy_appeared", "{enemy} appeared!", { enemy: e.name });
Combat_Log(message_text);
if (e.is_elite) Combat_Log(Elite_Sentence(e.elite));   // C3 (D86): what the modifier does, in plain words

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
if (player_weapon.id == 0) player_weapon = { power:COMBAT_UNARMED_POWER, stat_type:STAT_ATK, acc:0, preferred_class:-1 };

// Enemy basic attacks use the formula power straight from the enemy data (spec section 4); a weapon item would go through the player's rule.
enemy_weapon = { power:e.basic_power, stat_type:STAT_ATK, acc:0, preferred_class:-1 };
if (e.weapon_id != 0) {
    enemy_weapon = Combat_BasicSource(ItemDB_Get(e.weapon_id));
}
