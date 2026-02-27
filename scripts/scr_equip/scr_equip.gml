function Equip_ClassName(_class_id) {
    var cfg = DB_PlayerClass(_class_id);
    if (is_struct(cfg) && variable_struct_exists(cfg, "name")) return string(cfg.name);
    return "Unknown";
}

function Equip_CanEquip(_ch, _item_or_id) {
    var item = _item_or_id;
    if (!is_struct(item)) item = ItemDB_Get(_item_or_id);

    var out = { ok: false, msg: "Can't equip that.", item: item };

    if (!is_struct(_ch)) return out;
    if (!is_struct(item) || item.id == 0) return out;
    if (item.type != ITEM_WEAPON && item.type != ITEM_ARMOR) return out;
    if (!variable_struct_exists(item, "equip_slot") || item.equip_slot == "") return out;
    if (!variable_struct_exists(_ch, "class_id")) return out;

    if (!variable_struct_exists(_ch, "inventory") || !is_array(_ch.inventory) || !Inv_Has(_ch.inventory, item.id, 1)) {
        out.msg = "Item not in inventory.";
        return out;
    }

    var slot = string(item.equip_slot);
    if (Equip_SlotGet(_ch, slot) == item.id) {
        out.msg = "Already equipped.";
        return out;
    }

    if (variable_struct_exists(item, "preferred_class") && item.preferred_class != -1) {
        if (_ch.class_id != item.preferred_class) {
            out.msg = Equip_ClassName(item.preferred_class) + " only.";
            return out;
        }
    }

    if (variable_struct_exists(item, "allowed_classes") && is_array(item.allowed_classes)) {
        var allowed = false;
        for (var i = 0; i < array_length(item.allowed_classes); i++) {
            if (item.allowed_classes[i] == _ch.class_id) {
                allowed = true;
                break;
            }
        }

        if (!allowed) {
            var class_text = "";
            for (var j = 0; j < array_length(item.allowed_classes); j++) {
                if (j > 0) class_text += "/";
                class_text += Equip_ClassName(item.allowed_classes[j]);
            }
            if (class_text == "") class_text = "That";
            out.msg = class_text + " only.";
            return out;
        }
    }

    out.ok = true;
    out.msg = "Equipped " + string(item.name) + ".";
    return out;
}

function Equip_Item(_ch, _item_id) {
    var can = Equip_CanEquip(_ch, _item_id);
    if (!can.ok) return false;

    var item = can.item;
    // One slot at a time: assigning the new item automatically unequips the old one.
    var slot = item.equip_slot;
    Equip_SlotSet(_ch, slot, _item_id);

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
