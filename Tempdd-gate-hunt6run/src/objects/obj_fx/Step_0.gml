if (sprite_index == noone) {
    instance_destroy();
    exit;
}

// D134: a battle effect animation plays at 2x while run is held (never while a QTE is up). The spawn's speed is kept as the base.
if (room == rm_battle) {
    if (!variable_instance_exists(id, "fx_base_speed")) fx_base_speed = image_speed;
    image_speed = fx_base_speed * Battle_TimeScale();
}

fx_age += 1;
if (image_number <= 1) {
    if (fx_age > 1) instance_destroy();
    exit;
}

var frame_now = floor(image_index);
if (frame_now < fx_prev_frame) {
    instance_destroy();
    exit;
}
fx_prev_frame = frame_now;
