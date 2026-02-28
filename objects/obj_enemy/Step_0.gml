if (defeated) exit;
if (variable_instance_exists(id, "cine_lock_count") && cine_lock_count > 0) {
    moving = false;
    move_timer = 0;
    move_dir = -1;
    ai_state = ENEMY_IDLE;
    forget_time = 0;
    exit;
}
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

if (encounter_pending) {
    var pending_pl = encounter_player;
    if (!instance_exists(pending_pl)) pending_pl = pl;

    // Keep enemy from continuing to slide/chase while waiting for settle.
    moving = false;
    move_timer = 0;
    move_dir = -1;
    ai_state = ENEMY_IDLE;
    forget_time = 0;

    if (!instance_exists(pending_pl)) {
        encounter_pending = false;
        encounter_player = noone;
        exit;
    }

    // If player is still in post-battle cooldown, drop this pending request.
    if (variable_instance_exists(pending_pl, "battle_cooldown") && pending_pl.battle_cooldown > 0) {
        encounter_pending = false;
        encounter_player = noone;
        exit;
    }

    // Let player finish the step/tile align first, then trigger encounter.
    if (!Player_IsSettled(pending_pl)) exit;

    if (Enemy_AutoResolveEncounter(id, pending_pl)) {
        pending_pl.battle_cooldown = BATTLE_COOLDOWN_FRAMES;
        encounter_pending = false;
        encounter_player = noone;
        exit;
    }

    if (!EnemyPersist_BeginEncounter(id, pending_pl)) {
        encounter_pending = false;
        encounter_player = noone;
        exit;
    }

    if (!Transition_RequestEncounterBattle(rm_battle)) {
        encounter_pending = false;
        encounter_player = noone;
        exit;
    }

    // Start encounter only after settle; freezing now prevents retriggers.
    if (variable_instance_exists(pending_pl, "moving")) pending_pl.moving = false;
    if (variable_instance_exists(pending_pl, "move_timer")) pending_pl.move_timer = 0;
    if (variable_instance_exists(pending_pl, "move_dir")) pending_pl.move_dir = -1;

    // monster encounter sound
    SFX_PlayEnemySpawn(enemy_id);

    // tell player to reposition after return
    GameState_SetJustReturned(true);

    encounter_pending = false;
    encounter_player = noone;
    exit;
}

// grace window after running: enemies do not chase or engage
if (variable_instance_exists(pl, "battle_cooldown") && pl.battle_cooldown > 0) exit;

if (!is_struct(enemy_cfg) && enemy_id != -1) {
    Enemy_ApplyConfig(id);
}

var cfg = enemy_cfg;
if (!is_struct(cfg)) cfg = EnemyDB_Get(enemy_id);

EnemyAI_Update(id, cfg, pl);
