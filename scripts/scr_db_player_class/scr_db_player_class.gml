// Classes (combat-spec.md section 2). `stats` are the level-1 values (D176: with VIG and MND, which make Max HP and Max MP); fixed growth per level is LevelUp_ClassGrowthGain (scr_levelup).
// `hd` and `mp_gain` are the pre-D176 silent per-level growth: only Resource_MaxHp / Resource_MaxMp (the reference the new numbers are compared with) read them.
// D186 (R3 balance, tools/balance/sim.py): Knight SPD 10->9 (and Wound costs 4 MP, scr_db_skill); Archer ATK 9->8 SPD 13->11 (and SPD growth only on even levels, scr_levelup); Nobody ATK 8->9 DEF 8->9 SPD 9->11.
// `free_default` is where the level's free point goes until the level-up UI lets the player choose (D76).
function DB_PlayerClass(_class_id) {
    switch (_class_id) {
        case CLASS_KNIGHT:
            return { name:Loc_T("class.name.class_knight", "Knight"), hd:10, mp_gain:1, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_DEF,
                     stats:{ atk:11, def:12, spd:9, mag:3, vig:VIG_START, mnd:11 },
                     sprites:{ right:knight_right, left:knight_left, up:knight_up, down:knight_down } };

        case CLASS_ARCHER:
            return { name:Loc_T("class.name.class_archer", "Archer"), hd:8, mp_gain:2, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_ATK,
                     stats:{ atk:8, def:8, spd:11, mag:4, vig:VIG_START, mnd:12 },
                     sprites:{ right:archer_right, left:archer_left, up:archer_up, down:archer_down } };

        case CLASS_MAGE:
            return { name:Loc_T("class.name.class_mage", "Mage"), hd:6, mp_gain:2, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_MAG,
                     stats:{ atk:5, def:7, spd:10, mag:12, vig:VIG_START, mnd:16 },
                     sprites:{ right:mage_right, left:mage_left, up:mage_up, down:mage_down } };

        case CLASS_NOBODY:
            return { name:Loc_T("class.name.class_nobody", "Nobody"), hd:8, mp_gain:1, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: STAT_ATK,
                     stats:{ atk:9, def:9, spd:11, mag:3, vig:VIG_START, mnd:11 },
                     sprites:{ right:nobody_right, left:nobody_left, up:nobody_up, down:nobody_down } };
    }

    return { name:Loc_T("class.name.unknown", "Unknown"), hd:6, mp_gain:0, base_hp:PLAYER_BASE_HP, base_mp:PLAYER_BASE_MP, free_default: -1,
             stats:{ atk:10, def:10, spd:10, mag:10, vig:VIG_START, mnd:MND_BASE },
             sprites:{ right:noone, left:noone, up:noone, down:noone } };
}
