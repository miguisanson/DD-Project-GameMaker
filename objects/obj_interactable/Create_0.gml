if (!variable_instance_exists(id, "persist_id")) persist_id = "";
state_uid = -1;
if (state_uid == -1) state_uid = GameState_NextUID();

interact_kind = INTERACT_NONE;
sprite_id = noone;

// display / dialogue config
interact_name = "";
dialogue_id = "";
dialogue_id_after = "";

// swap-state config
swap_on_interact = false;
swap_sprite = noone;
swapped = false;
is_container = false;
class_select_chest = false;

container_level = 1;
loot_table_key = "";


switch_id = 0;

dialogue_profile_id = DIALOGUE_PROFILE_GENERIC;

checkpoint_id = 0;

door_room = noone;
door_x = 0;
door_y = 0;

if (sprite_id != noone) {
    sprite_index = sprite_id;
}
