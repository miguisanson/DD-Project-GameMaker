// Classes (combat-spec.md section 2). `stats` are the level-1 values; fixed growth per level is LevelUp_ClassGrowthGain (scr_levelup).
// `free_default` is where the level's free point goes until the level-up UI lets the player choose (D76).
function DB_PlayerClass(_class_id) {
    switch (_class_id) {
        case CLASS_KNIGHT:
            return { name:Loc_T("class.name.class_knight", "Knight"), hd:10, mp_gain:1, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_DEF,
                     stats:{ atk:11, def:12, spd:8, mag:3 },
                     sprites:{ right:knight_right, left:knight_left, up:knight_up, down:knight_down } };

        case CLASS_ARCHER:
            return { name:Loc_T("class.name.class_archer", "Archer"), hd:8, mp_gain:2, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_ATK,
                     stats:{ atk:9, def:8, spd:13, mag:4 },
                     sprites:{ right:archer_right, left:archer_left, up:archer_up, down:archer_down } };

        case CLASS_MAGE:
            return { name:Loc_T("class.name.class_mage", "Mage"), hd:6, mp_gain:2, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_MAG,
                     stats:{ atk:5, def:7, spd:10, mag:12 },
                     sprites:{ right:mage_right, left:mage_left, up:mage_up, down:mage_down } };

        case CLASS_NOBODY:
            return { name:Loc_T("class.name.class_nobody", "Nobody"), hd:8, mp_gain:1, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_ATK,
                     stats:{ atk:8, def:8, spd:9, mag:3 },
                     sprites:{ right:nobody_right, left:nobody_left, up:nobody_up, down:nobody_down } };
    }

    return { name:Loc_T("class.name.unknown", "Unknown"), hd:6, mp_gain:0, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: -1,
             stats:{ atk:10, def:10, spd:10, mag:10 },
             sprites:{ right:noone, left:noone, up:noone, down:noone } };
}
