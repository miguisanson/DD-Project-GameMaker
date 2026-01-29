function DB_PlayerClass(_class_id) {
    switch (_class_id) {
        case CLASS_KNIGHT:
            return { name:"Knight", hd:10, mp_gain:1, base_hp:10, base_mp:10,
                     bonus:{ str:1, agi:0, def:2, intt:0, luck:0 },
                     sprites:{ right:knight_right, left:knight_left, up:knight_up, down:knight_down } };

        case CLASS_ARCHER:
            return { name:"Archer", hd:8, mp_gain:2, base_hp:10, base_mp:10,
                     bonus:{ str:0, agi:2, def:0, intt:0, luck:1 },
                     sprites:{ right:archer_right, left:archer_left, up:archer_up, down:archer_down } };

        case CLASS_MAGE:
            return { name:"Mage", hd:6, mp_gain:3, base_hp:10, base_mp:10,
                     bonus:{ str:0, agi:0, def:0, intt:2, luck:1 },
                     sprites:{ right:mage_right, left:mage_left, up:mage_up, down:mage_down } };
    }

    return { name:"Unknown", hd:6, mp_gain:0, base_hp:10, base_mp:10,
             bonus:{ str:0, agi:0, def:0, intt:0, luck:0 },
             sprites:{ right:noone, left:noone, up:noone, down:noone } };
}
