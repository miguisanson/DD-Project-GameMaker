if (sprite_index == noone) {
    instance_destroy();
    exit;
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
