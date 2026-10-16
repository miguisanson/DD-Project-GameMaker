// D70: the bump nudge is a 1 px display offset; take it back before any logic sees the position.
if (bump_applied) {
    x -= bump_dx;
    y -= bump_dy;
    bump_applied = false;
}
prompt_target = noone;
World_RegisterFx(id);   // the interact prompt is drawn by the world layer script: objects have no Draw event (no .yy edits)
MapFx_Step();           // D138 (G6): finish old effects, sparkle on a level gained
Player_TrackStill(id);   // D153: how long the player has stood still (hiding spots)

var gs = GameState_Get();
Player_EnsureSpriteSet();
if (!is_real(face)) face = DOWN;
if (face < 0 || face > 3) face = DOWN;

// The grace period after a Run / Continue runs down only while the player is free: not under a menu, a dialogue, a pop-up or a fade (bug hunt 7), or healing after an escape
// would leave the enemy on the player's tile free to start the fight again the moment the menu closes.
if (battle_cooldown > 0 && !UI_IsBlocking()) {
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

// D64: re-arm the exit the player arrived on once they are fully off it. Plain rectangle test on the 16 px footprint: a fresh player
// has no mask yet on its first frames, so place_meeting would say "not touching" and re-arm the exit at once.
if (exit_ignore != noone) {
    if (!instance_exists(exit_ignore)
        || x + tile_size <= exit_ignore.bbox_left || x > exit_ignore.bbox_right
        || y + tile_size <= exit_ignore.bbox_top || y > exit_ignore.bbox_bottom) {
        exit_ignore = noone;
    }
}
if (exit_ignore == noone) exit_leave = false;

// I-048: never rest between tiles (quick-load mid-step, aborted step, odd spawn).
if (!moving) Player_SnapIfOffGrid(id);

if (UI_IsBlocking()) {
    if (gs.ui.mode == UI_DIALOGUE || array_length(gs.ui.lines) > 0) {
        Player_EnsureDialogueSettle(id, PLAYER_DIALOGUE_SETTLE_FRAMES);
    }
    moving = false;
    move_timer = 0;
    move_dir = -1;
    image_index = 0;
    sprite_index = sprite[face];
    exit;
}

interact_key = Input_Pressed("interact");

// D69: a direction pressed while a step is running is remembered for a few frames: the next step starts at once.
var pressed_dir = -1;
if (Input_Pressed("move_up")) pressed_dir = UP;
else if (Input_Pressed("move_down")) pressed_dir = DOWN;
else if (Input_Pressed("move_left")) pressed_dir = LEFT;
else if (Input_Pressed("move_right")) pressed_dir = RIGHT;
if (moving && pressed_dir != -1) {
    buf_dir = pressed_dir;
    buf_age = 0;
} else if (buf_age < 99) {
    buf_age += 1;
}

if (!moving) {
    move_dir = -1;
    var want = -1;
    var from_buffer = false;
    if (!interact_key) {
        var act = Input_MoveAction();
        if (act == "move_up") want = UP;
        else if (act == "move_down") want = DOWN;
        else if (act == "move_left") want = LEFT;
        else if (act == "move_right") want = RIGHT;
        if (want == -1 && buf_dir != -1 && buf_age <= buffer_frames) {
            want = buf_dir;          // tapped during the last step
            from_buffer = true;
        } else if (want != -1 && want == buf_dir && buf_age <= buffer_frames) {
            from_buffer = true;      // pressed during the last step and still held
        }
    }

    // D127: the exit refused the player (no class yet) and the lines are read: one step away from the exit, through the code below
    // (a turn, then the tile check: never into a wall; no key needed, no turn delay)
    if (class_guard_to != -1) {
        var guard_dir = ClassGuard_PickDir(id, class_guard_to);
        class_guard_to = -1;
        if (guard_dir != -1) {
            want = guard_dir;
            from_buffer = true;
        }
    }

    if (want != -1) {
        buf_dir = -1;
        move_dir = want;
        // D142 (amends D64): on a room arrival the exit under the player opens to a press toward it (the way you walk out through it): the exit sees the move
        // direction in its collision event this very step and leaves at once. Any other direction walks normally and the exit re-arms after the step off it.
        if (exit_leave && exit_ignore != noone && instance_exists(exit_ignore) && exit_ignore.require_dir == want) {
            exit_ignore = noone;
            exit_leave = false;
        }
        if (face != want) {
            // D69: the turn is instant; walking starts only if the key is still held after turn_frames (a tap just turns)
            face = want;
            turn_timer = from_buffer ? 0 : turn_frames;
        } else if (turn_timer > 0) {
            turn_timer -= 1;
        }
        if (turn_timer <= 0) {
            var tx = x + ((want == RIGHT) - (want == LEFT)) * tile_size;
            var ty = y + ((want == DOWN) - (want == UP)) * tile_size;
            if (!place_meeting(tx, ty, obj_wall) && !Grid_PropBlocks(id, tx, ty)) {   // D179: tall grass is walkable
                moving = true;
            } else if (bump_dir != want) {
                // D70: soft sound and a tiny nudge, once per press (not once per frame)
                bump_dir = want;
                bump_count += 1;
                bump_timer = 3;
                bump_dx = (want == RIGHT) - (want == LEFT);
                bump_dy = (want == DOWN) - (want == UP);
                SFX_Play("blocked", 0.4);
            }
        }
    } else {
        turn_timer = 0;
        bump_dir = -1;   // key released: the next press may bump again
    }

    if (moving) {
        sprite_index = sprite[face];
        move_timer = tile_size;
        step_from_x = x;
        step_from_y = y;
        squash_start = MapFx_Now();   // D138 (G6): the squash starts with the step
        // D70: the run key doubles the speed; fixed for the whole step so the step always ends exactly on a tile
        step_speed = (Input_Held("run") && (tile_size mod run_speed) == 0) ? run_speed : walk_speed;
        image_speed = step_speed / max(1, walk_speed);   // I-063: running plays the same walk animation, faster (twice as fast at twice the speed), it never freezes
    }
}

if (moving) {
    switch (move_dir) {
        case UP:    y -= step_speed; break;
        case DOWN:  y += step_speed; break;
        case LEFT:  x -= step_speed; break;
        case RIGHT: x += step_speed; break;
    }

    if (place_meeting(x, y, obj_wall) || Grid_PropBlocks(id, x, y)) {
        moving = false;
        move_timer = 0;

        // I-048: an aborted step returns to the tile it started on, never rests between tiles.
        x = step_from_x;
        y = step_from_y;
        image_index = 0;
    }

    if (moving) {
        move_timer -= step_speed;
        if (move_timer <= 0) {
            moving = false;
            move_timer = 0;
            image_index = 0;
            x = Grid_Snap(x);
            y = Grid_Snap(y);
        }
    }
}

if (!moving) {
    sprite_index = sprite[face];
    image_index = 0;
    Notes_StepPlayer(id);   // D147: standing on a lore note picks it up (it never blocks)

    // D70: what the player faces, for the prompt (only when standing still and free)
    var facing_target = Interact_GetTarget(id);
    if (facing_target != noone && Player_PromptWorthy(facing_target)) prompt_target = facing_target;
}

mask_index = sprite[DOWN];

// D138 (G6): the step squash. The position and the mask stay exactly as they were (tile-snapped, D69); only the picture changes, and it is drawn by
// MapFx_DrawPlayerSquash in whole pixels while the plain sprite is off. Off with Screen shake off (D49).
squash_on = Settings_ShakeOn() && ((MapFx_Now() - squash_start) < FEEL_SQUASH_MS);
visible = !squash_on;
Player_ApplyHiddenLook(id);   // D153: see-through while hidden

// D70: apply the bump nudge last (taken back at the top of the next step)
if (bump_timer > 0) {
    bump_timer -= 1;
    x += bump_dx;
    y += bump_dy;
    bump_applied = true;
}
