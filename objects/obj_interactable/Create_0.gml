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

// chest config
chest_item_id = 0;
chest_qty = 1;

loot_item_id = 0;
loot_qty = 1;
loot_list = [];

switch_id = 0;

npc_id = NPC_OLD_MAN;
shop_id = SHOP_BASIC;

checkpoint_id = 0;

door_room = noone;
door_x = 0;
door_y = 0;

if (sprite_id != noone) {
    sprite_index = sprite_id;
}
