if (defeated) exit;
if (other.battle_cooldown > 0) exit;

// SAVE RETURN LOCATION (BATTLE SAFE)
GameState_Init();
if (variable_global_exists("room_state_ready") && global.room_state_ready) RoomState_Save(room);
GameState_SetBattleReturn(room, other.x, other.y);

// remember enemy instance + type
GameState_SetBattleEnemy(persist_id, enemy_id);

// tell player to reposition after return
GameState_SetJustReturned(true);

room_goto(rm_battle);
