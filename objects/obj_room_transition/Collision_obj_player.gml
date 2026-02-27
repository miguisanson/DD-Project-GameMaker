if (transition_id == "") exit;

// Require intentional movement into the transition direction
if (require_move) {
    var requested_dir = -1;
    if (variable_instance_exists(other, "move_dir")) requested_dir = other.move_dir;

    // Accept directional intent even if the movement step is blocked this frame.
    // This allows re-triggering while still overlapping the transition tile.
    var has_intent = (requested_dir != -1);
    if (!has_intent && variable_instance_exists(other, "moving")) has_intent = other.moving;
    if (!has_intent) exit;

    if (require_dir != -1 && requested_dir != require_dir) exit;
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
