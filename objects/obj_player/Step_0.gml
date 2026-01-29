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

interact_key = Input_Pressed("interact");

if (!moving) {
    move_dir = -1;
    if (!interact_key) {
        var tx = x;
        var ty = y;
        if (up_key) { move_dir = UP; face = UP; ty = y - tile_size; }
        else if (down_key) { move_dir = DOWN; face = DOWN; ty = y + tile_size; }
        else if (left_key) { move_dir = LEFT; face = LEFT; tx = x - tile_size; }
        else if (right_key) { move_dir = RIGHT; face = RIGHT; tx = x + tile_size; }

        if (move_dir != -1) {
            if (!place_meeting(tx, ty, obj_wall) && !place_meeting(tx, ty, obj_interactable)) {
                moving = true;
            }
        }
    }

    if (moving) {
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

    if (moving) {
        move_timer -= 1;
        if (move_timer <= 0) {
            moving = false;
            move_timer = 0;
            image_index = 0;
            x = round(x / tile_size) * tile_size;
            y = round(y / tile_size) * tile_size;
        }
    }
}

if (!moving) {
    sprite_index = sprite[face];
    image_index = 0;
}

mask_index = sprite[DOWN];
