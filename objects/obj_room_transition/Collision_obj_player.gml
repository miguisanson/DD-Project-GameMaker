if (transition_id == "") exit;

// Require intentional movement into the transition direction
if (require_move) {
    if (!other.moving) exit;
    if (require_dir != -1 && other.move_dir != require_dir) exit;
}

var entry = RoomDB_Get(transition_id);
if (!is_struct(entry)) exit;

RoomState_OnRoomExit();

if (variable_struct_exists(entry, "cutscene_id")) {
    var cutscene_id = string(entry.cutscene_id);
    if (cutscene_id != "") {
        Transition_RequestCutsceneById(cutscene_id);
        exit;
    }
}

var face_dir = -1;
if (variable_struct_exists(entry, "face")) face_dir = entry.face;
if (face_dir == -1 && variable_instance_exists(other, "face")) face_dir = other.face;

Transition_RequestRoomFade(entry.target_room, entry.target_spawn_id, face_dir, true);
