Input_PreStep();
var gs = GameState_Get();
// D108 F2b-1: the message hold and the shakes run on a ms clock. The shakes advance here, once a frame, before any early exit (they used to count down
// inside Draw, so a second read of the offset made them run twice as fast).
// D134: holding run plays the battle's own clocks (messages, effect animations, the freeze, the shakes, the feel effects, the death pop) at 2x. time_scale is 1
// whenever a QTE is up, and the QTE clocks (Qte_StepMs below, in scr_combat) never read it. real_ms is the unscaled step (the low-HP heartbeat keeps its own pace).
var real_ms = Presentation_StepMs(delta_time);
var time_scale = Battle_TimeScale(self);
var step_ms = real_ms * time_scale;
Fx_BattleShakesStep(enemy_inst, step_ms);
var lift_want = 0;   // I-111: a list that has no room under the feet lifts the enemy while it is open (Battle_MenusLayout works out how much)
if (battle_state == BSTATE_SKILL_MENU) lift_want = list_lift[0];
else if (battle_state == BSTATE_ITEM_MENU) lift_want = list_lift[1];
if (Battle_EnemyRegound(enemy_inst, enemy_inst.sprite_index, lift_want)) {   // the window changed or a list opened: the enemy stands on its line, and its effects follow it
    var enemy_c = FX_CenterOn(noone, enemy_inst);
    enemy_fx_x = enemy_c.x;
    enemy_fx_y = enemy_c.y;
}
lift_applied = lift_want;
if (gs.ui.mode == UI_MENU || Tutorial_IsOpen() || Tutorial_JustClosed()) exit;
Battle_FeelStep(self, step_ms, real_ms);   // D138 / D139: the feel clock, the death pop's clock, the low-HP heartbeat and the push-in (before any exit below)
if (battle_over && battle_state != BSTATE_MESSAGE) exit;

// helper input keys
var k_ok = Battle_ConfirmInput();   // D182: Confirm or a left click presses the QTE bars (the same path, so the grade is the same)

// The grade word runs on real time, also through a hit-stop.
if (qte_result_ms > 0) qte_result_ms = max(0, qte_result_ms - Qte_StepMs(delta_time));

// Hit-stop (D61, D138: every damaging hit): the battle logic waits; input and drawing carry on. The shakes, sparks and jolt start when it ends.
// A bar in its timing window never freezes (the freeze starts after a bar is resolved; this is the guard).
if (hitstop_ms > 0 && (qte_active || sq_active || def_active)) hitstop_ms = 0;
if (hitstop_ms > 0) {
    hitstop_ms -= Qte_StepMs(delta_time) * time_scale;   // D134: the freeze is battle time (a bar is never up here, so time_scale is 2 only while run is held)
    if (hitstop_ms > 0) exit;
    hitstop_ms = 0;
    Battle_QteImpactFeedback(self);
    exit;
}

// D138: the enemy has been killed: its death pop plays (freeze, white flash, burst), then the "has been slain" message and the end of the fight.
if (Battle_DeathPopStep(self)) exit;

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
    if (Combat_HoldActive(wait_timer)) {
        wait_timer = Combat_HoldStep(wait_timer, step_ms);
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
    Tutorial_Trigger("timeline");   // C4 (D45): the first time the strip and the menu are both up
    if (variable_struct_exists(e, "is_elite") && e.is_elite) Tutorial_Trigger("elite");   // C4 (D45): the first elite fight
    // D140: Esc on the root command menu opens the one menu (inside a list Esc stays Back; Tab / Start open it anywhere safe from the UI controller)
    if (Input_UIPressed("pause") && Menu_BattleAllowed(battle_state, Battle_QteBusy(self), battle_over)) {
        Menu_Open();
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
