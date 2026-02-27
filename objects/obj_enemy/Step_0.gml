if (defeated) exit;
if (Transition_IsActive()) {
    moving = false;
    move_timer = 0;
    move_dir = -1;
    exit;
}

var gs = GameState_Get();
var dialogue_active = false;
if (variable_struct_exists(gs, "ui") && is_struct(gs.ui)) {
    if ((variable_struct_exists(gs.ui, "mode") && gs.ui.mode == UI_DIALOGUE)
    || (variable_struct_exists(gs.ui, "lines") && is_array(gs.ui.lines) && array_length(gs.ui.lines) > 0)) {
        dialogue_active = true;
    }
}
if (dialogue_active) {
    moving = false;
    move_timer = 0;
    move_dir = -1;
    exit;
}

var pl = gs.player_inst;
if (!instance_exists(pl)) exit;

// grace window after running: enemies do not chase or engage
if (variable_instance_exists(pl, "battle_cooldown") && pl.battle_cooldown > 0) exit;

if (!is_struct(enemy_cfg) && enemy_id != -1) {
    Enemy_ApplyConfig(id);
}

var cfg = enemy_cfg;
if (!is_struct(cfg)) cfg = EnemyDB_Get(enemy_id);

EnemyAI_Update(id, cfg, pl);
