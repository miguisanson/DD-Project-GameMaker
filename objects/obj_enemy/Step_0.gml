if (defeated) exit;

var gs = GameState_Get();
var pl = gs.player_inst;
if (!instance_exists(pl)) exit;

if (!is_struct(enemy_cfg) && enemy_id != -1) {
    Enemy_ApplyConfig(id);
}

var cfg = enemy_cfg;
if (!is_struct(cfg)) cfg = EnemyDB_Get(enemy_id);

EnemyAI_Update(id, cfg, pl);
