function SpriteShake_Start(_inst, _dir, _mag, _frames, _flash_frames, _flash_rate) {
    if (!instance_exists(_inst)) return;
    _inst.shake_dir = _dir;
    _inst.shake_mag = _mag;
    _inst.shake_timer = _frames;
    _inst.flash_timer = _flash_frames;
    _inst.flash_rate = _flash_rate;
    if (!variable_instance_exists(_inst, "shake_phase")) _inst.shake_phase = 0;
}

function SpriteShake_Offset(_inst) {
    if (!instance_exists(_inst) || !variable_instance_exists(_inst, "shake_timer") || _inst.shake_timer <= 0) return { x: 0, y: 0, flash: false };

    _inst.shake_phase += 1;
    var dir = _inst.shake_dir;
    var mag = _inst.shake_mag;

    var sx = 0;
    var sy = 0;
    var s = (( _inst.shake_phase div 2 ) mod 2 == 0) ? 1 : -1;

    if (dir == SHAKE_DIR_H) {
        sx = s * mag;
    } else if (dir == SHAKE_DIR_V) {
        sy = s * mag;
    } else {
        sx = s * mag;
        sy = s * mag;
    }

    _inst.shake_timer -= 1;
    if (_inst.shake_timer <= 0) {
        _inst.shake_timer = 0;
        sx = 0;
        sy = 0;
    }

    var flash = false;
    if (variable_instance_exists(_inst, "flash_timer") && _inst.flash_timer > 0) {
        if ((_inst.flash_timer div max(1, _inst.flash_rate)) mod 2 == 0) flash = true;
        _inst.flash_timer -= 1;
        if (_inst.flash_timer < 0) _inst.flash_timer = 0;
    }

    return { x: sx, y: sy, flash: flash };
}

function CameraShake_Start(_mag, _frames, _dir) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "cam_shake")) gs.cam_shake = { mag: 0, timer: 0, dir: SHAKE_DIR_H, phase: 0 };
    gs.cam_shake.mag = _mag;
    gs.cam_shake.timer = _frames;
    gs.cam_shake.dir = _dir;
    gs.cam_shake.phase = 0;
}

function CameraShake_Offset() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "cam_shake")) return { x: 0, y: 0 };
    if (gs.cam_shake.timer <= 0) return { x: 0, y: 0 };

    gs.cam_shake.phase += 1;
    var s = (( gs.cam_shake.phase div 2 ) mod 2 == 0) ? 1 : -1;
    var mag = gs.cam_shake.mag;
    var dir = gs.cam_shake.dir;

    var ox = 0;
    var oy = 0;
    if (dir == SHAKE_DIR_H) {
        ox = s * mag;
    } else if (dir == SHAKE_DIR_V) {
        oy = s * mag;
    } else {
        ox = s * mag;
        oy = s * mag;
    }

    gs.cam_shake.timer -= 1;
    if (gs.cam_shake.timer <= 0) {
        gs.cam_shake.timer = 0;
        ox = 0;
        oy = 0;
    }

    return { x: ox, y: oy };
}
