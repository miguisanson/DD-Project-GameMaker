Input_PreStep();
var gs = GameState_Get();
if (gs.ui.mode == UI_MENU || gs.ui.mode == UI_PAUSE) exit;
if (battle_over && battle_state != BSTATE_MESSAGE) exit;

// helper input keys
var k_ok = Input_UIConfirm();

// The grade word runs on real time, also through a hit-stop.
if (qte_result_ms > 0) qte_result_ms = max(0, qte_result_ms - Qte_StepMs(delta_time));

// Hit-stop (D61, Perfect): the battle logic waits; input and drawing carry on. The shakes start when it ends.
if (hitstop_ms > 0) {
    hitstop_ms -= Qte_StepMs(delta_time);
    if (hitstop_ms > 0) exit;
    hitstop_ms = 0;
    Battle_QteImpactFeedback(self);
    exit;
}

// D97: the command panel slides in each time the player's turn comes round (not when coming back from a list: Battle_ListBack does that)
if (!variable_instance_exists(id, "hud_prev_state")) hud_prev_state = battle_state;
if (battle_state != hud_prev_state) {
    if (battle_state == BSTATE_MENU && hud_prev_state != BSTATE_SKILL_MENU && hud_prev_state != BSTATE_ITEM_MENU && is_struct(ui_cmd)) ui_cmd.opened_ms = current_time;
    hud_prev_state = battle_state;
}

if (turn == TURN_PLAYER) {
    if (!player_turn_start_applied) {
        p = Equip_PlayerTurnStartApply(p);
        player_turn_start_applied = true;
    }
} else {
    player_turn_start_applied = false;
}

// --------------------
// MESSAGE STATE
// --------------------
if (battle_state == BSTATE_MESSAGE) {
    if (wait_fx != noone && !instance_exists(wait_fx)) wait_fx = noone;
    if (wait_fx != noone) exit;
    if (wait_timer > 0) {
        wait_timer -= 1;
        exit;
    }
    skill_banner_active = false;
    skill_banner_name = "";
    if (message_next_state == BSTATE_END_RUN) {
        Battle_EndRun(self);
    } else if (message_next_state == BSTATE_ENEMY_ACT && turn != TURN_ENEMY) {
        battle_state = BSTATE_MENU;
    } else {
        battle_state = message_next_state;
    }
    exit;
}

// --------------------
// PLAYER MENUS (D95, D99): the command menu, then the skill or item list. Battle_MenusStep reads the shared input and calls back.
// --------------------
if (battle_state == BSTATE_MENU) {
    if (turn != TURN_PLAYER) {
        battle_state = BSTATE_ENEMY_ACT;
        exit;
    }
    Battle_MenusStep(self);
    exit;
}

if (battle_state == BSTATE_SKILL_MENU || battle_state == BSTATE_ITEM_MENU) {
    Battle_MenusStep(self);
    exit;
}

// --------------------
// PLAYER ATTACK: THE SLIDING BAR
// --------------------
if (battle_state == BSTATE_ATTACK_TIMING) {
    Battle_PlayerAttackTimingStep(self, k_ok);
    exit;
}

// --------------------
// PLAYER SKILL: THE ARROW SEQUENCE
// --------------------
if (battle_state == BSTATE_SKILL_QTE) {
    Battle_SkillQteStep(self);
    exit;
}

// --------------------
// BIG ENEMY ATTACK: THE DEFENCE BAR
// --------------------
if (battle_state == BSTATE_ENEMY_DEFENCE) {
    Battle_DefenceStep(self, k_ok);
    exit;
}

// --------------------
// RUN ATTEMPT
// --------------------
if (battle_state == BSTATE_PLAYER_RUN) {
    Battle_RunAttempt(self);
    exit;
}

// --------------------
// END RUN
// --------------------
if (battle_state == BSTATE_END_RUN) {
    Battle_EndRun(self);
    exit;
}

// --------------------
// ENEMY TURN
// --------------------
if (battle_state == BSTATE_ENEMY_ACT) {
    if (turn != TURN_ENEMY) {
        battle_state = BSTATE_MENU;
        exit;
    }

    Battle_EnemyAct(self);
    exit;
}
