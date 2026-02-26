function RoomTransition_Init() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "transition")) {
        gs.transition = { pending: false, room: noone, spawn_id: "", face: -1 };
    }
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "debug_warns")) gs.ui.debug_warns = [];
}

function RoomTransition_Warn(_msg) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "debug_warns")) gs.ui.debug_warns = [];
    array_push(gs.ui.debug_warns, _msg);
    show_debug_message(_msg);
}

function RoomTransition_FindSpawn(_spawn_id) {
    if (!object_exists(obj_room_spawn)) return noone;
    if (!instance_exists(obj_room_spawn)) return noone;
    var n = instance_number(obj_room_spawn);
    var first = noone;
    for (var i = 0; i < n; i++) {
        var inst = instance_find(obj_room_spawn, i);
        if (first == noone) first = inst;
        if (_spawn_id != "" && inst.spawn_id == _spawn_id) return inst;
    }
    return (_spawn_id == "") ? first : noone;
}

function RoomTransition_Set(_room, _spawn_id, _face) {
    RoomTransition_Init();
    var gs = GameState_Get();
    gs.transition.pending = true;
    gs.transition.room = _room;
    gs.transition.spawn_id = _spawn_id;
    gs.transition.face = _face;
}

function RoomTransition_Clear() {
    RoomTransition_Init();
    var gs = GameState_Get();
    gs.transition.pending = false;
    gs.transition.room = noone;
    gs.transition.spawn_id = "";
    gs.transition.face = -1;
}

function RoomTransition_Apply() {
    RoomTransition_Init();
    var gs = GameState_Get();
    if (!gs.transition.pending) return;
    if (room == rm_battle) return;

    var pl = noone;
    if (instance_exists(obj_player)) pl = instance_find(obj_player, 0);

    var sid = gs.transition.spawn_id;
    var target = RoomTransition_FindSpawn(sid);

    if (pl == noone) {
        if (target != noone) {
            pl = instance_create_layer(target.x, target.y, "Instances", obj_player);
        } else {
            RoomTransition_Warn("[RoomTransition] Missing spawn '" + string(sid) + "' in " + room_get_name(room));
            pl = instance_create_layer(0, 0, "Instances", obj_player);
        }
    }

    if (target != noone) {
        pl.x = target.x;
        pl.y = target.y;
    } else {
        RoomTransition_Warn("[RoomTransition] Missing spawn '" + string(sid) + "' in " + room_get_name(room));
    }

    if (gs.transition.face != -1) {
        pl.face = gs.transition.face;
    } else if (target != noone && variable_instance_exists(target, "spawn_facing") && target.spawn_facing != -1) {
        pl.face = target.spawn_facing;
    }

    if (variable_instance_exists(pl, "moving")) pl.moving = false;
    if (variable_instance_exists(pl, "move_timer")) pl.move_timer = 0;
    if (variable_instance_exists(pl, "move_dir")) pl.move_dir = -1;

    RoomTransition_Clear();
}

function Transition_Init() {
    RoomTransition_Init();
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "transition_fx") || !is_struct(gs.transition_fx)) {
        gs.transition_fx = {
            active: false,
            type: TRANSITION_TYPE_NONE,
            phase: 0,
            timer: 0,
            alpha: 0,
            target_room: noone,
            target_spawn_id: "",
            target_face: -1,
            use_spawn: false,
            fade_out_frames: TRANSITION_ROOM_FADE_OUT_FRAMES,
            fade_in_frames: TRANSITION_ROOM_FADE_IN_FRAMES,
            encounter_zoom: 0,
            encounter_shake_x: 0,
            encounter_shake_y: 0,
            encounter_port_x: 0,
            encounter_port_y: 0,
            encounter_port_w: 0,
            encounter_port_h: 0,
            encounter_focus_x: 0,
            encounter_focus_y: 0,
            encounter_has_focus: false
        };
    }
}

function Transition_IsActive() {
    Transition_Init();
    var gs = GameState_Get();
    return gs.transition_fx.active;
}

function Transition_IsInputLocked() {
    return Transition_IsActive();
}

function Transition_CaptureEncounterViewport(_tr) {
    if (!view_enabled) return;
    _tr.encounter_port_x = view_xport[0];
    _tr.encounter_port_y = view_yport[0];
    _tr.encounter_port_w = max(1, view_wport[0]);
    _tr.encounter_port_h = max(1, view_hport[0]);
}

function Transition_ApplyEncounterViewport(_tr) {
    if (!view_enabled) return;
    var scale = 1 + max(0, _tr.encounter_zoom);
    var out_w = max(1, round(_tr.encounter_port_w * scale));
    var out_h = max(1, round(_tr.encounter_port_h * scale));
    var anchor_x = _tr.encounter_port_x + (_tr.encounter_port_w * 0.5);
    var anchor_y = _tr.encounter_port_y + (_tr.encounter_port_h * 0.5);

    if (_tr.encounter_has_focus) {
        var cam = view_camera[0];
        if (!is_undefined(cam) && cam != -1) {
            var cam_x = camera_get_view_x(cam);
            var cam_y = camera_get_view_y(cam);
            var cam_w = max(1, camera_get_view_width(cam));
            var cam_h = max(1, camera_get_view_height(cam));
            var nx = clamp((_tr.encounter_focus_x - cam_x) / cam_w, 0, 1);
            var ny = clamp((_tr.encounter_focus_y - cam_y) / cam_h, 0, 1);
            anchor_x = _tr.encounter_port_x + (_tr.encounter_port_w * nx);
            anchor_y = _tr.encounter_port_y + (_tr.encounter_port_h * ny);
        }
    }

    var out_x = round(anchor_x - ((anchor_x - _tr.encounter_port_x) * scale) + _tr.encounter_shake_x);
    var out_y = round(anchor_y - ((anchor_y - _tr.encounter_port_y) * scale) + _tr.encounter_shake_y);

    view_xport[0] = out_x;
    view_yport[0] = out_y;
    view_wport[0] = out_w;
    view_hport[0] = out_h;
}

function Transition_RestoreEncounterViewport(_tr) {
    if (!view_enabled) return;
    if (_tr.encounter_port_w <= 0 || _tr.encounter_port_h <= 0) return;
    view_xport[0] = _tr.encounter_port_x;
    view_yport[0] = _tr.encounter_port_y;
    view_wport[0] = _tr.encounter_port_w;
    view_hport[0] = _tr.encounter_port_h;
}

function Transition_Begin(_type, _room, _spawn_id, _face, _use_spawn, _enc_focus_x = undefined, _enc_focus_y = undefined) {
    Transition_Init();
    var gs = GameState_Get();
    var tr = gs.transition_fx;
    if (tr.active) return false;

    tr.active = true;
    tr.type = _type;
    tr.phase = 0;
    tr.timer = 0;
    tr.alpha = 0;
    tr.target_room = _room;
    tr.target_spawn_id = _spawn_id;
    tr.target_face = _face;
    tr.use_spawn = _use_spawn;
    tr.encounter_focus_x = 0;
    tr.encounter_focus_y = 0;
    tr.encounter_has_focus = false;

    if (_type == TRANSITION_TYPE_CUTSCENE) {
        tr.fade_out_frames = max(1, TRANSITION_CUTSCENE_FADE_OUT_FRAMES);
        tr.fade_in_frames = max(1, TRANSITION_CUTSCENE_FADE_IN_FRAMES);
    } else if (_type == TRANSITION_TYPE_ENCOUNTER) {
        tr.fade_out_frames = max(1, TRANSITION_ENCOUNTER_FADE_OUT_FRAMES);
        tr.fade_in_frames = max(1, TRANSITION_ENCOUNTER_FADE_IN_FRAMES);
        tr.encounter_zoom = 0;
        tr.encounter_shake_x = 0;
        tr.encounter_shake_y = 0;
        tr.encounter_has_focus = is_real(_enc_focus_x) && is_real(_enc_focus_y);
        if (tr.encounter_has_focus) {
            tr.encounter_focus_x = _enc_focus_x;
            tr.encounter_focus_y = _enc_focus_y;
        }
        Transition_CaptureEncounterViewport(tr);
    } else {
        tr.fade_out_frames = max(1, TRANSITION_ROOM_FADE_OUT_FRAMES);
        tr.fade_in_frames = max(1, TRANSITION_ROOM_FADE_IN_FRAMES);
    }

    if (_use_spawn && _room != noone) {
        RoomTransition_Set(_room, _spawn_id, _face);
    }

    return true;
}

function Transition_RequestRoomFade(_room, _spawn_id = "", _face = -1, _use_spawn = false) {
    return Transition_Begin(TRANSITION_TYPE_ROOM, _room, _spawn_id, _face, _use_spawn);
}

function Transition_RequestEncounterBattle(_room = rm_battle, _focus_x = undefined, _focus_y = undefined) {
    return Transition_Begin(TRANSITION_TYPE_ENCOUNTER, _room, "", -1, false, _focus_x, _focus_y);
}

function Transition_RequestCutsceneFade(_room, _spawn_id = "", _face = -1, _use_spawn = false) {
    return Transition_Begin(TRANSITION_TYPE_CUTSCENE, _room, _spawn_id, _face, _use_spawn);
}

function Transition_RequestCutsceneById(_cutscene_id) {
    var gs = GameState_Get();
    gs.pending_cutscene_id = string(_cutscene_id);
    return Transition_RequestCutsceneFade(rm_cutscene);
}

function Transition_RequestCutsceneIn() {
    var ok = Transition_Begin(TRANSITION_TYPE_CUTSCENE, noone, "", -1, false);
    if (!ok) return false;

    var gs = GameState_Get();
    var tr = gs.transition_fx;
    tr.phase = 2; // intro fade-in only
    tr.timer = 0;
    tr.alpha = 1;
    return true;
}

function Transition_Finish() {
    Transition_Init();
    var gs = GameState_Get();
    var tr = gs.transition_fx;
    if (tr.type == TRANSITION_TYPE_ENCOUNTER) {
        Transition_RestoreEncounterViewport(tr);
    }
    tr.active = false;
    tr.type = TRANSITION_TYPE_NONE;
    tr.phase = 0;
    tr.timer = 0;
    tr.alpha = 0;
    tr.target_room = noone;
    tr.target_spawn_id = "";
    tr.target_face = -1;
    tr.use_spawn = false;
    tr.encounter_zoom = 0;
    tr.encounter_shake_x = 0;
    tr.encounter_shake_y = 0;
    tr.encounter_focus_x = 0;
    tr.encounter_focus_y = 0;
    tr.encounter_has_focus = false;
}

function Transition_Update() {
    Transition_Init();
    var gs = GameState_Get();
    var tr = gs.transition_fx;

    if (!tr.active) return;

    switch (tr.type) {
        case TRANSITION_TYPE_ROOM: {
            if (tr.phase == 0) {
                tr.timer += 1;
                tr.alpha = clamp(tr.timer / tr.fade_out_frames, 0, 1);
                if (tr.timer >= tr.fade_out_frames) {
                    tr.alpha = 1;
                    tr.phase = 1;
                    tr.timer = 0;
                    room_goto(tr.target_room);
                }
            } else {
                tr.timer += 1;
                tr.alpha = 1 - clamp(tr.timer / tr.fade_in_frames, 0, 1);
                if (tr.timer >= tr.fade_in_frames) {
                    Transition_Finish();
                }
            }
        } break;

        case TRANSITION_TYPE_ENCOUNTER: {
            if (tr.phase == 0) {
                tr.timer += 1;
                var p = clamp(tr.timer / max(1, TRANSITION_ENCOUNTER_ZOOM_FRAMES), 0, 1);
                tr.encounter_zoom = lerp(0, TRANSITION_ENCOUNTER_ZOOM_MAX, p);
                var shake_mag = max(0, round(TRANSITION_ENCOUNTER_SHAKE_PX * (1 - (p * 0.5))));
                tr.encounter_shake_x = irandom_range(-shake_mag, shake_mag);
                tr.encounter_shake_y = irandom_range(-shake_mag, shake_mag);
                Transition_ApplyEncounterViewport(tr);
                tr.alpha = 0;

                if (tr.timer >= max(1, TRANSITION_ENCOUNTER_ZOOM_FRAMES)) {
                    Transition_RestoreEncounterViewport(tr);
                    tr.encounter_zoom = 0;
                    tr.encounter_shake_x = 0;
                    tr.encounter_shake_y = 0;
                    tr.phase = 1;
                    tr.timer = 0;
                }
            } else if (tr.phase == 1) {
                tr.timer += 1;
                tr.alpha = clamp(tr.timer / tr.fade_out_frames, 0, 1);
                if (tr.timer >= tr.fade_out_frames) {
                    tr.alpha = 1;
                    tr.phase = 2;
                    tr.timer = 0;
                    room_goto(tr.target_room);
                }
            } else if (tr.phase == 2) {
                tr.timer += 1;
                tr.alpha = 1;
                if (tr.timer >= max(0, TRANSITION_ENCOUNTER_BLACK_HOLD_FRAMES)) {
                    tr.phase = 3;
                    tr.timer = 0;
                }
            } else {
                tr.timer += 1;
                tr.alpha = 1 - clamp(tr.timer / tr.fade_in_frames, 0, 1);
                if (tr.timer >= tr.fade_in_frames) {
                    Transition_Finish();
                }
            }
        } break;

        case TRANSITION_TYPE_CUTSCENE: {
            if (tr.phase == 2) {
                tr.timer += 1;
                tr.alpha = 1 - clamp(tr.timer / tr.fade_in_frames, 0, 1);
                if (tr.timer >= tr.fade_in_frames) {
                    Transition_Finish();
                }
                break;
            }

            if (tr.phase == 0) {
                tr.timer += 1;
                tr.alpha = clamp(tr.timer / tr.fade_out_frames, 0, 1);
                if (tr.timer >= tr.fade_out_frames) {
                    tr.alpha = 1;
                    tr.phase = 1;
                    tr.timer = 0;
                    room_goto(tr.target_room);
                }
            } else {
                tr.timer += 1;
                tr.alpha = 1 - clamp(tr.timer / tr.fade_in_frames, 0, 1);
                if (tr.timer >= tr.fade_in_frames) {
                    Transition_Finish();
                }
            }
        } break;
    }
}

function Transition_DrawGUI() {
    Transition_Init();
    var gs = GameState_Get();
    var tr = gs.transition_fx;

    var w = display_get_gui_width();
    var h = display_get_gui_height();

    if (tr.alpha > 0) {
        draw_set_alpha(clamp(tr.alpha, 0, 1));
        draw_set_color(c_black);
        draw_rectangle(0, 0, w, h, false);
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
}
