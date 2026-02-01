Input_PreStep();
var gs = GameState_Get();
if (gs.ui.mode == UI_MENU || gs.ui.mode == UI_PAUSE) exit;
if (battle_over && battle_state != BSTATE_MESSAGE) exit;

// helper input keys
var k_up = Input_Pressed("menu_up");
var k_down = Input_Pressed("menu_down");
var k_ok = Input_Pressed("confirm");
var k_back = Input_Pressed("cancel");

// --------------------
// MESSAGE STATE
// --------------------
if (battle_state == BSTATE_MESSAGE) {
    if (k_ok) {
        if (message_next_state == BSTATE_END_RUN) {
            Battle_EndRun(self);
        } else if (message_next_state == BSTATE_ENEMY_ACT && turn != TURN_ENEMY) {
            battle_state = BSTATE_MENU;
        } else {
            battle_state = message_next_state;
        }
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

    if (k_down) menu_index = (menu_index + 1) mod menu_count;
    if (k_up)   menu_index = (menu_index + menu_count - 1) mod menu_count;

    if (k_ok) {
        var action = battle_actions[menu_index];
        if (action.state == BSTATE_SKILL_MENU) {
            if (array_length(Battle_GetSkillList(self)) <= 0) {
                Battle_Message(self, "No skills available.", BSTATE_MENU);
            } else {
                battle_state = action.state;
            }
        } else if (action.state == BSTATE_ITEM_MENU) {
            if (array_length(Battle_GetItemList(self)) <= 0) {
                Battle_Message(self, "No items available.", BSTATE_MENU);
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
        Battle_Message(self, "No skills available.", BSTATE_MENU);
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
        Battle_Message(self, "No items available.", BSTATE_MENU);
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
