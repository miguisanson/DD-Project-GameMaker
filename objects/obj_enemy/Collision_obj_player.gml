if (defeated) exit;
if (Transition_IsActive()) exit;
if (other.battle_cooldown > 0) exit;

if (!EnemyPersist_BeginEncounter(id, other)) exit;

var focus_x = bbox_left + ((bbox_right - bbox_left) * 0.5);
var focus_y = bbox_top + ((bbox_bottom - bbox_top) * 0.5);
if (!Transition_RequestEncounterBattle(rm_battle, focus_x, focus_y)) exit;

// monster encounter sound
SFX_PlayEnemySpawn(enemy_id);

// tell player to reposition after return
GameState_SetJustReturned(true);
