if (defeated) exit;
if (Transition_IsActive()) exit;
if (other.battle_cooldown > 0) exit;

if (!EnemyPersist_BeginEncounter(id, other)) exit;

if (!Transition_RequestEncounterBattle(rm_battle)) exit;

// Freeze both actors immediately once battle transition begins.
moving = false;
move_timer = 0;
move_dir = -1;
ai_state = ENEMY_IDLE;
forget_time = 0;

if (variable_instance_exists(other, "moving")) other.moving = false;
if (variable_instance_exists(other, "move_timer")) other.move_timer = 0;
if (variable_instance_exists(other, "move_dir")) other.move_dir = -1;

// monster encounter sound
SFX_PlayEnemySpawn(enemy_id);

// tell player to reposition after return
GameState_SetJustReturned(true);
