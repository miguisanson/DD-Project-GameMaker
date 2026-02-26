if (defeated) exit;
if (Transition_IsActive()) exit;
if (other.battle_cooldown > 0) exit;

if (!EnemyPersist_BeginEncounter(id, other)) exit;

if (!Transition_RequestEncounterBattle(rm_battle)) exit;

// monster encounter sound
SFX_PlayEnemySpawn(enemy_id);

// tell player to reposition after return
GameState_SetJustReturned(true);
