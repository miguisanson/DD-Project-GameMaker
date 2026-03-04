Input_PreStep();
var gs = GameState_Get();
if (gs.ui.mode == UI_MENU || gs.ui.mode == UI_PAUSE) exit;
if (battle_over && battle_state != BSTATE_MESSAGE) exit;

// helper input keys
var k_up = Input_UIPressed("menu_up");
var k_down = Input_UIPressed("menu_down");
var k_ok = Input_UIConfirm();
var k_back = Input_UIBack();

if (attack_timing_result_timer > 0) attack_timing_result_timer -= 1;

if (!variable_instance_exists(id, "loc_revision")) loc_revision = -1;
var loc_rev = Loc_GetRevision();
if (loc_revision != loc_rev) {
    if (is_array(battle_actions) && array_length(battle_actions) >= 4) {
        battle_actions[0].label = Loc_T("battle.action.attack", "ATTACK");
        battle_actions[1].label = Loc_T("battle.action.skill", "SKILL");
        battle_actions[2].label = Loc_T("battle.action.item", "ITEM");
        battle_actions[3].label = Loc_T("battle.action.run", "RUN");
    }
    loc_revision = loc_rev;
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
// PLAYER MENU
// --------------------
if (battle_state == BSTATE_MENU) {
    if (turn != TURN_PLAYER) {
        battle_state = BSTATE_ENEMY_ACT;
        exit;
    }

    // If player is stunned, skip player turn immediately (no menu interaction).
    if (!Status_CanAct(p)) {
        Battle_PlayerStunSkip(self);
        exit;
    }

    if (k_down) menu_index = (menu_index + 1) mod menu_count;
    if (k_up)   menu_index = (menu_index + menu_count - 1) mod menu_count;

    if (k_ok) {
        var action = battle_actions[menu_index];
        if (action.state == BSTATE_ATTACK_TIMING) {
            Battle_AttackTimingBegin(self);
        } else if (action.state == BSTATE_SKILL_MENU) {
            if (array_length(Battle_GetSkillList(self)) <= 0) {
                Battle_Message(self, Loc_T("battle.menu.no_skills", "No skills available."), BSTATE_MENU);
            } else {
                battle_state = action.state;
            }
        } else if (action.state == BSTATE_ITEM_MENU) {
            if (array_length(Battle_GetItemList(self)) <= 0) {
                Battle_Message(self, Loc_T("battle.menu.no_items", "No items available."), BSTATE_MENU);
            } else {
                battle_state = action.state;
            }
        } else {
            battle_state = action.state;
        }
    }

    exit;
}

// --------------------
// SKILL MENU
// --------------------
if (battle_state == BSTATE_SKILL_MENU) {
    var skills = Battle_GetSkillList(self);
    if (array_length(skills) <= 0) {
        Battle_Message(self, Loc_T("battle.menu.no_skills", "No skills available."), BSTATE_MENU);
        exit;
    }

    var skill_count = array_length(skills);
    var skill_menu_count = skill_count + 1; // +1 for Back
    if (skill_index >= skill_menu_count) skill_index = 0;

    if (k_down) skill_index = (skill_index + 1) mod skill_menu_count;
    if (k_up)   skill_index = (skill_index + skill_menu_count - 1) mod skill_menu_count;

    if (k_back) {
        battle_state = BSTATE_MENU;
        exit;
    }

    if (k_ok) {
        if (skill_index == skill_count) {
            battle_state = BSTATE_MENU;
        } else {
            Battle_PlayerSkill(self, skills[skill_index]);
        }
    }

    exit;
}

// --------------------
// ITEM MENU
// --------------------
if (battle_state == BSTATE_ITEM_MENU) {
    var items = Battle_GetItemList(self);
    if (array_length(items) <= 0) {
        Battle_Message(self, Loc_T("battle.menu.no_items", "No items available."), BSTATE_MENU);
        exit;
    }

    var item_count = array_length(items);
    var item_menu_count = item_count + 1; // +1 for Back
    if (item_index >= item_menu_count) item_index = 0;

    if (k_down) item_index = (item_index + 1) mod item_menu_count;
    if (k_up)   item_index = (item_index + item_menu_count - 1) mod item_menu_count;

    if (k_back) {
        battle_state = BSTATE_MENU;
        exit;
    }

    if (k_ok) {
        if (item_index == item_count) {
            battle_state = BSTATE_MENU;
        } else {
            Battle_PlayerItem(self, items[item_index].id);
        }
    }

    exit;
}

// --------------------
// PLAYER ATTACK TIMING
// --------------------
if (battle_state == BSTATE_ATTACK_TIMING) {
    Battle_PlayerAttackTimingStep(self, k_ok);
    exit;
}

if (battle_state == BSTATE_ENEMY_DEF_QTE) {
    Battle_DefQTEStep(self);
    exit;
}

// --------------------
// PLAYER ATTACK
// --------------------
if (battle_state == BSTATE_PLAYER_ATTACK) {
    Battle_PlayerAttack(self);
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
