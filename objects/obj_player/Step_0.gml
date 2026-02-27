var gs = GameState_Get();
Player_EnsureSpriteSet();
if (!is_real(face)) face = DOWN;
if (face < 0 || face > 3) face = DOWN;

if (battle_cooldown > 0) {
    battle_cooldown -= 1;
}

if (auto_resolve_recover_timer > 0) {
    auto_resolve_recover_timer -= 1;
    auto_resolve_recover_progress += 1;
    var recover_total = max(1, auto_resolve_recover_total);
    var recover_t = clamp(auto_resolve_recover_progress / recover_total, 0, 1);
    // Smoothstep easing prevents visible jerk at start/end.
    var recover_e = recover_t * recover_t * (3 - (2 * recover_t));
    x = lerp(auto_resolve_recover_start_x, auto_resolve_recover_target_x, recover_e);
    y = lerp(auto_resolve_recover_start_y, auto_resolve_recover_target_y, recover_e);

    moving = false;
    move_timer = 0;
    move_dir = -1;
    if (auto_resolve_recover_timer <= 0) {
        x = auto_resolve_recover_target_x;
        y = auto_resolve_recover_target_y;
        auto_resolve_recover_total = 0;
        auto_resolve_recover_progress = 0;
    }
    sprite_index = sprite[face];
    image_index = 0;
    mask_index = sprite[DOWN];
    exit;
}

if (UI_IsBlocking()) {
    moving = false;
    move_timer = 0;
    image_index = 0;
    sprite_index = sprite[face];
    exit;
}

interact_key = Input_Pressed("interact");

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
