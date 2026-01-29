function Equip_Item(_ch, _item_id) {
    var item = ItemDB_Get(_item_id);
    if (item.type != ITEM_WEAPON && item.type != ITEM_ARMOR) return false;
    if (item.equip_slot == "") return false;

    // Remove from inventory (1)
    _ch.inventory = Inv_Remove(_ch.inventory, _item_id, 1);

    // Swap existing
    var slot = item.equip_slot;
    var old = Equip_SlotGet(_ch, slot);
    Equip_SlotSet(_ch, slot, _item_id);

    if (old != 0) _ch.inventory = Inv_Add(_ch.inventory, old, 1);

    return true;
}

function Equip_SlotGet(_ch, _slot) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip")) return 0;
    if (is_struct(_ch.equip) && variable_struct_exists(_ch.equip, _slot)) {
        return variable_struct_get(_ch.equip, _slot);
    }
    return 0;
}

function Equip_SlotSet(_ch, _slot, _item_id) {
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip") || !is_struct(_ch.equip)) _ch.equip = {};
    variable_struct_set(_ch.equip, _slot, _item_id);
}

function Equip_GetStatBonus(_ch, _stat_id) {
    var total = 0;
    if (!is_struct(_ch) || !variable_struct_exists(_ch, "equip") || !is_struct(_ch.equip)) return 0;

    var keys = ["weapon", "head", "body", "ring1", "ring2"];
    for (var i = 0; i < array_length(keys); i++) {
        var item_id = Equip_SlotGet(_ch, keys[i]);
        if (item_id == 0) continue;

        var item = ItemDB_Get(item_id);
        if (is_struct(item) && variable_struct_exists(item, "bonus")) {
            var b = item.bonus;
            switch (_stat_id) {
                case STAT_STR:  if (variable_struct_exists(b, "str")) total += b.str; break;
                case STAT_AGI:  if (variable_struct_exists(b, "agi")) total += b.agi; break;
                case STAT_DEF:  if (variable_struct_exists(b, "def")) total += b.def; break;
                case STAT_INT:  if (variable_struct_exists(b, "intt")) total += b.intt; break;
                case STAT_LUCK: if (variable_struct_exists(b, "luck")) total += b.luck; break;
            }
        }
    }

    return total;
}
