var gs = GameState_Get();
if (gs.ui.mode == UI_DIALOGUE || gs.ui.mode == UI_MENU || array_length(gs.ui.lines) > 0) {
    moving = false;
    move_timer = 0;
    image_index = 0;
    sprite_index = sprite[face];
    exit;
}

if (battle_cooldown > 0) {
    battle_cooldown -= 1;
}

interact_key = Input_Pressed("interact");

if (Input_Pressed("debug_levelup")) {
    var ch = gs.player_ch;
    var before_level = ch.level;
    ch.exp += ch.exp_next;
    ch = LevelUp_FromExp(ch);
    if (!variable_struct_exists(ch, "stat_points")) ch.stat_points = 0;
    if (ch.level > before_level) ch.stat_points += (ch.level - before_level);
    GameState_SetPlayer(ch);
}

if (!moving) {
    move_dir = -1;
    if (!interact_key) {
        var act = Input_MoveAction();
        var tx = x;
        var ty = y;
        if (act == "move_up") { move_dir = UP; face = UP; ty = y - tile_size; }
        else if (act == "move_down") { move_dir = DOWN; face = DOWN; ty = y + tile_size; }
        else if (act == "move_left") { move_dir = LEFT; face = LEFT; tx = x - tile_size; }
        else if (act == "move_right") { move_dir = RIGHT; face = RIGHT; tx = x + tile_size; }

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
