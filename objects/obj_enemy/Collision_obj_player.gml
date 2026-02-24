if (defeated) exit;
if (other.battle_cooldown > 0) exit;

if (!EnemyPersist_BeginEncounter(id, other)) exit;

// monster encounter sound
SFX_PlayEnemySpawn(enemy_id);

// tell player to reposition after return
GameState_SetJustReturned(true);

room_goto(rm_battle);
