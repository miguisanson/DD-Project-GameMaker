function Inv_Add(_inv, _item_id, _qty) {
    var item = ItemDB_Get(_item_id);
    if (_qty <= 0) return _inv;

    if (item.stackable) {
        for (var i = 0; i < array_length(_inv); i++) {
            if (_inv[i].id == _item_id && _inv[i].qty < item.max_stack) {
                var space = item.max_stack - _inv[i].qty;
                var add_now = min(space, _qty);
                _inv[i].qty += add_now;
                _qty -= add_now;
                if (_qty <= 0) return _inv;
            }
        }
        while (_qty > 0) {
            var add_stack = min(item.max_stack, _qty);
            array_push(_inv, { id: _item_id, qty: add_stack });
            _qty -= add_stack;
        }
    } else {
        var unique_once = Item_IsSkillbook(item) || item.type == ITEM_WEAPON || item.type == ITEM_ARMOR;
        if (unique_once) {
            if (Inv_Has(_inv, _item_id, 1)) return _inv;

            if (Item_IsSkillbook(item) && variable_struct_exists(item, "use") && is_struct(item.use) && variable_struct_exists(item.use, "skill_id")) {
                var sid = item.use.skill_id;
                var gs = GameState_Get();
                if (is_struct(gs.player_ch) && variable_struct_exists(gs.player_ch, "skills") && is_array(gs.player_ch.skills)) {
                    for (var si = 0; si < array_length(gs.player_ch.skills); si++) {
                        if (gs.player_ch.skills[si] == sid) return _inv;
                    }
                }
            }

            _qty = min(1, _qty);
        }
        for (var k = 0; k < _qty; k++) array_push(_inv, { id: _item_id, qty: 1 });
    }

    return _inv;
}

function Inv_Remove(_inv, _item_id, _qty) {
    if (_qty <= 0) return _inv;

    for (var i = array_length(_inv) - 1; i >= 0; i--) {
        if (_inv[i].id == _item_id) {
            var take = min(_inv[i].qty, _qty);
            _inv[i].qty -= take;
            _qty -= take;

            if (_inv[i].qty <= 0) array_delete(_inv, i, 1);
            if (_qty <= 0) break;
        }
    }
    return _inv;
}

function Inv_Has(_inv, _item_id, _qty) {
    var total = 0;
    for (var i = 0; i < array_length(_inv); i++) {
        if (_inv[i].id == _item_id) total += _inv[i].qty;
    }
    return total >= _qty;
}

function Inv_GetItems(_inv) {
    return _inv;
}
