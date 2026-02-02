if (transition_id == "") exit;

// Require intentional movement into the transition direction
if (require_move) {
    if (!other.moving) exit;
    if (require_dir != -1 && other.move_dir != require_dir) exit;
}

var entry = RoomDB_Get(transition_id);
if (!is_struct(entry)) exit;

if (variable_global_exists("room_state_ready") && global.room_state_ready) RoomState_Save(room);

var face_dir = -1;
if (variable_struct_exists(entry, "face")) face_dir = entry.face;
if (face_dir == -1 && variable_instance_exists(other, "face")) face_dir = other.face;

RoomTransition_Set(entry.target_room, entry.target_spawn_id, face_dir);
room_goto(entry.target_room);
