if (battle_over) exit;

// helper input keys
var k_up = keyboard_check_pressed(ord("W"));
var k_down = keyboard_check_pressed(ord("S"));
var k_ok = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter);
var k_back = keyboard_check_pressed(ord("X")) || keyboard_check_pressed(vk_escape);

// --------------------
// MESSAGE STATE
// --------------------
if (battle_state == BSTATE_MESSAGE) {
    if (k_ok) {
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

    if (k_down) skill_index = (skill_index + 1) mod array_length(skills);
    if (k_up)   skill_index = (skill_index + array_length(skills) - 1) mod array_length(skills);

    if (k_back) {
        battle_state = BSTATE_MENU;
        exit;
    }

    if (k_ok) {
        Battle_PlayerSkill(self, skills[skill_index]);
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

    if (k_down) item_index = (item_index + 1) mod array_length(items);
    if (k_up)   item_index = (item_index + array_length(items) - 1) mod array_length(items);

    if (k_back) {
        battle_state = BSTATE_MENU;
        exit;
    }

    if (k_ok) {
        Battle_PlayerItem(self, items[item_index].id);
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
