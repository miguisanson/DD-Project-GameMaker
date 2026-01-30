if (target_room == noone) exit;
if (!Player_IsSettled(other)) exit;

if (variable_global_exists("room_state_ready") && global.room_state_ready) RoomState_Save(room);
var face_dir = target_facing;
if (face_dir == -1 && variable_instance_exists(other, "face")) face_dir = other.face;
RoomTransition_Set(target_room, target_spawn_id, face_dir);
room_goto(target_room);
