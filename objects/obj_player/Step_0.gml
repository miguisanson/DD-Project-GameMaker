var gs = GameState_Get();
if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
    moving = false;
    move_timer = 0;
    image_index = 0;
    sprite_index = sprite[face];
    exit;
}

if (battle_cooldown > 0) {
    battle_cooldown -= 1;
}

right_key = Input_Held("move_right");
left_key  = Input_Held("move_left");
up_key    = Input_Held("move_up");
down_key  = Input_Held("move_down");

interact_key = Action_KeyPressed(id, "interact");

if (!moving) {
    if (!interact_key) {
        if (up_key) { move_dir = UP; moving = true; }
        else if (down_key) { move_dir = DOWN; moving = true; }
        else if (left_key) { move_dir = LEFT; moving = true; }
        else if (right_key) { move_dir = RIGHT; moving = true; }
    }

    if (moving) {
        face = move_dir;
        sprite_index = sprite[face];
        move_timer = tile_size;
    }
}

if (moving) {
    switch (move_dir) {
        case UP:    y -= 1; break;
        case DOWN:  y += 1; break;
        case LEFT:  x -= 1; break;
        case RIGHT: x += 1; break;
    }

    if (place_meeting(x, y, obj_wall) || place_meeting(x, y, obj_interactable)) {
        moving = false;
        move_timer = 0;

        switch (move_dir) {
            case UP:    y += 1; break;
            case DOWN:  y -= 1; break;
            case LEFT:  x += 1; break;
            case RIGHT: x -= 1; break;
        }
        image_index = 0;
    }

    move_timer -= 1;
    if (move_timer <= 0) {
        moving = false;
        move_timer = 0;
        image_index = 0;
    }
}

if (!moving) {
    sprite_index = sprite[face];
    image_index = 0;
}

mask_index = sprite[DOWN];
