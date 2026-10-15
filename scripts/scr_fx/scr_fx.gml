// ---- Shakes and flashes on a ms clock (D108 F2b-1) ----
// A shake keeps its own elapsed ms. Step advances it ONCE per frame (SpriteShake_Step / CameraShake_Step, from the battle controller's Step, with
// Presentation_StepMs(delta_time)); the *_Offset readers only look at the clock, so any number of draws in a frame (the debug HP text reads the
// enemy's offset a second time) cannot make a shake run faster. The look is the old 60 fps one: the offset flips sign every 2 frames (33.3 ms),
// the last frame is still, and a flash blinks every flash_rate ms counting down from its end.

// The shake's sign at an elapsed time: 1 or -1 (+ - - + + - - + ...), 0 once the last frame is reached or the shake is over.
function Fx_ShakeSign(_elapsed_ms, _total_ms) {
    if (_elapsed_ms + FX_EDGE_SLACK_MS >= _total_ms - FX_FRAME_MS) return 0;
    var n = floor((_elapsed_ms + FX_EDGE_SLACK_MS) / FX_FRAME_MS) + 1;   // 1 on the frame the shake started
    return ((n div 2) mod 2 == 0) ? 1 : -1;
}

// True while the flash is lit: blinks every rate ms counting down from the flash's end, lit first.
function Fx_FlashOn(_elapsed_ms, _flash_ms, _rate_ms) {
    var left = _flash_ms - _elapsed_ms;
    if (left <= FX_EDGE_SLACK_MS) return false;
    return (floor((left + FX_EDGE_SLACK_MS) / max(1, _rate_ms)) mod 2 == 0);
}

function Fx_ShakeXY(_dir, _mag, _sign) {
    var s = _sign * _mag;
    if (_dir == SHAKE_DIR_H) return { x: s, y: 0 };
    if (_dir == SHAKE_DIR_V) return { x: 0, y: s };
    return { x: s, y: s };
}

function SpriteShake_Start(_inst, _dir, _mag, _ms, _flash_ms, _flash_rate_ms) {
    if (!instance_exists(_inst)) return;
    _inst.shake_dir = _dir;
    _inst.shake_mag = _mag;
    _inst.shake_ms = _ms;
    _inst.shake_elapsed_ms = 0;
    _inst.flash_ms = _flash_ms;
    _inst.flash_rate_ms = _flash_rate_ms;
}

// Once per frame: moves the sprite's shake clock on by _step_ms.
function SpriteShake_Step(_inst, _step_ms) {
    if (!instance_exists(_inst) || !variable_instance_exists(_inst, "shake_elapsed_ms")) return;
    if (_inst.shake_elapsed_ms < _inst.shake_ms) _inst.shake_elapsed_ms += _step_ms;
}

// Where the sprite is nudged now and whether its flash is lit. Pure: it does not move the clock, so call it as often as needed.
function SpriteShake_Offset(_inst) {
    if (!instance_exists(_inst) || !variable_instance_exists(_inst, "shake_elapsed_ms")) return { x: 0, y: 0, flash: false };
    if (_inst.shake_elapsed_ms + FX_EDGE_SLACK_MS >= _inst.shake_ms) return { x: 0, y: 0, flash: false };
    var xy = Fx_ShakeXY(_inst.shake_dir, _inst.shake_mag, Fx_ShakeSign(_inst.shake_elapsed_ms, _inst.shake_ms));
    return { x: xy.x, y: xy.y, flash: Fx_FlashOn(_inst.shake_elapsed_ms, _inst.flash_ms, _inst.flash_rate_ms) };
}

function CameraShake_Start(_mag, _ms, _dir) {
    if (!Settings_ShakeOn()) return;   // D0: the Screen shake setting
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "cam_shake")) gs.cam_shake = { mag: 0, ms: 0, elapsed_ms: 0, dir: SHAKE_DIR_H };
    gs.cam_shake.mag = _mag;
    gs.cam_shake.ms = _ms;
    gs.cam_shake.elapsed_ms = 0;
    gs.cam_shake.dir = _dir;
}

// Once per frame: moves the camera shake clock on by _step_ms.
function CameraShake_Step(_step_ms) {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "cam_shake")) return;
    if (gs.cam_shake.elapsed_ms < gs.cam_shake.ms) gs.cam_shake.elapsed_ms += _step_ms;
}

// The camera nudge now. Pure, like SpriteShake_Offset.
function CameraShake_Offset() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "cam_shake")) return { x: 0, y: 0 };
    var cs = gs.cam_shake;
    if (cs.elapsed_ms + FX_EDGE_SLACK_MS >= cs.ms) return { x: 0, y: 0 };
    return Fx_ShakeXY(cs.dir, cs.mag, Fx_ShakeSign(cs.elapsed_ms, cs.ms));
}

// Both shakes of a battle frame, advanced once (the battle controller's Step calls this before anything can exit early).
function Fx_BattleShakesStep(_enemy_inst, _step_ms) {
    SpriteShake_Step(_enemy_inst, _step_ms);
    CameraShake_Step(_step_ms);
}

// The HUD hurt flash (the player panel shakes when hit or ticked): ms left on the flash. Hud_HurtFlashStep counts it down once per frame and
// snaps to 0 within FX_EDGE_SLACK_MS; Hud_HurtFlashSign is the panel's nudge direction (1 / -1, flipping every 2 frames of 60 fps, the old
// "hurt mod 4"), 0 when the flash is over.
function Hud_HurtFlashStep(_ms, _step_ms) {
    var left = _ms - _step_ms;
    return (left <= FX_EDGE_SLACK_MS) ? 0 : left;
}

function Hud_HurtFlashSign(_ms) {
    if (_ms <= 0) return 0;
    return ((floor((_ms + FX_EDGE_SLACK_MS) / (2 * FX_FRAME_MS)) mod 2) == 0) ? 1 : -1;
}

// ---- Icons (D94): the v2 strips (art/IMPORT-CHECKLIST.md) by category and frame ----
// Icon_Get(category, frame) gives { spr, sub }: the imported strip sprite "spr_icons_<category>" when it exists, else a sprite built once
// at run time from the generated pixel rows below (Icon_FallbackData). So every screen can draw the real icons before the import.
function Icon_StatusName(_status_id) {
    switch (_status_id) {
        case STATUS_POISON: return "poison";
        case STATUS_BURN: return "burn";
        case STATUS_BLEED: return "bleed";
        case STATUS_STUN: return "stun";
        case STATUS_GUARD: return "guard";
        case STATUS_BRACE: return "guard";
        case STATUS_DMG_UP: return "rev_up";
        case STATUS_EVASION: return "evasion";
        case STATUS_CRIT_UP: return "take_aim";
        case STATUS_HIT_UP: return "foresight";
        case STATUS_MEDITATION: return "meditation";
        case STATUS_SOLIDIFY: return "solidify";
        case STATUS_BLOODTHIRSTY: return "bloodthirsty";
        case STATUS_BLESSING: return "blessing";
        case STATUS_SUNDER: return "sundered";
    }
    return "";
}

function Icon_SkillName(_skill_id) {
    switch (_skill_id) {
        case SKILL_WOUND: return "wound";
        case SKILL_HILT_BASH: return "hilt_bash";
        case SKILL_MUSCLE_UP: return "muscle_up";
        case SKILL_REV_UP: return "rev_up";
        case SKILL_HORIZ_SLASH: return "horizontal_slash";
        case SKILL_POWER_STRIKE: return "power_strike";
        case SKILL_POISON_ARROW: return "poison_arrow";
        case SKILL_EVASION: return "evasion";
        case SKILL_DOUBLE_SHOT: return "double_shot";
        case SKILL_TAKE_AIM: return "take_aim";
        case SKILL_FIREBALL: return "fireball";
        case SKILL_POISON_MIST: return "poison_mist";
        case SKILL_ICE_SPEAR: return "ice_spear";
        case SKILL_MEDITATION: return "meditation";
        case SKILL_FORESIGHT: return "foresight";
    }
    return "";
}

// The frame of a named icon in a category (the position in art/strips_v2/<category>_strip.txt), or -1.
function Icon_Frame(_category, _name) {
    if (!is_string(_name) || _name == "" || !is_string(_category)) return -1;
    var idx = Icon_FrameIndex();
    if (!variable_struct_exists(idx, _category)) return -1;
    var by_name = variable_struct_get(idx, _category);
    return variable_struct_exists(by_name, _name) ? variable_struct_get(by_name, _name) : -1;
}

// category -> (icon name -> frame), built once from the strip ids (D108 F1d-1: was a linear scan per call). The first position wins, as the scan did.
function Icon_FrameIndex() {
    if (variable_global_exists("icon_frame_index")) return global.icon_frame_index;
    var d = Icon_FallbackData();
    var out = {};
    var cats = variable_struct_get_names(d);
    for (var c = 0; c < array_length(cats); c++) {
        var ids = variable_struct_get(d, cats[c]).ids;
        var by_name = {};
        for (var i = 0; i < array_length(ids); i++) if (!variable_struct_exists(by_name, ids[i])) variable_struct_set(by_name, ids[i], i);
        variable_struct_set(out, cats[c], by_name);
    }
    global.icon_frame_index = out;
    return out;
}

function Icon_StatusFrame(_status_id) { return Icon_Frame("status", Icon_StatusName(_status_id)); }
function Icon_SkillFrame(_skill_id) { return Icon_Frame("skill", Icon_SkillName(_skill_id)); }

// 16 strings of 16 characters for one icon ('.' clear, '0'..'3' darkest..lightest), or [] when there is none.
function Icon_Rows(_category, _frame) {
    var d = Icon_FallbackData();
    if (!variable_struct_exists(d, _category)) return [];
    var rows = variable_struct_get(d, _category).rows;
    if (_frame < 0 || _frame >= array_length(rows)) return [];
    return rows[_frame];
}

function Icon_PaletteColour(_ch) {
    switch (_ch) {
        case "0": return UI_C_DARKEST;
        case "1": return UI_C_DARK;
        case "2": return UI_C_LIGHT;
    }
    return UI_C_LIGHTEST;
}

// The imported strip sprite "spr_icons_<category>", or -1 while it is not imported yet (D94). Looked up once per category for the run (the
// asset table of a running game does not change; the owner imports the strips in the IDE, then the game is started again). Lookups are counted for the tests.
function Icon_StripSprite(_category) {
    if (!variable_global_exists("icon_strip_sprites")) global.icon_strip_sprites = {};
    if (variable_struct_exists(global.icon_strip_sprites, _category)) return variable_struct_get(global.icon_strip_sprites, _category);
    if (!variable_global_exists("icon_lookups")) global.icon_lookups = 0;
    global.icon_lookups++;
    var spr = asset_get_index("spr_icons_" + _category);
    if (spr == -1) spr = asset_get_index(_category + "_strip");   // the owner's import named the strips after their files (status_strip, ...)
    variable_struct_set(global.icon_strip_sprites, _category, spr);
    return spr;
}

// The sprite and subimage to draw for an icon: the imported strip, else one sprite per icon made from its rows (kept for the run).
// Returns undefined when the category or frame does not exist. The answer is kept per category and frame (D108 F1d-1): one shared struct, read only.
function Icon_Get(_category, _frame) {
    if (_frame < 0) return undefined;
    if (!variable_global_exists("icon_pics")) global.icon_pics = {};
    var pics = variable_struct_get(global.icon_pics, _category);
    if (is_array(pics) && _frame < array_length(pics) && is_struct(pics[_frame])) return pics[_frame];
    var made = Icon_GetBuild(_category, _frame);
    if (is_struct(made)) {
        if (!is_array(pics)) {
            pics = [];
            variable_struct_set(global.icon_pics, _category, pics);
        }
        if (array_length(pics) <= _frame) array_resize(pics, _frame + 1);
        pics[_frame] = made;
    }
    return made;
}

function Icon_GetBuild(_category, _frame) {
    var spr = Icon_StripSprite(_category);
    if (is_real(spr) && spr != -1 && sprite_exists(spr)) return { spr: spr, sub: _frame };
    if (!variable_global_exists("icon_cache")) global.icon_cache = {};
    var key = _category + ":" + string(_frame);
    if (variable_struct_exists(global.icon_cache, key)) return variable_struct_get(global.icon_cache, key);
    var rows = Icon_Rows(_category, _frame);
    if (array_length(rows) != 16) return undefined;
    var a_before = draw_get_alpha();   // the caller may be mid fade: bake at full alpha, then give the state back
    var c_before = draw_get_color();
    draw_set_alpha(1);
    var surf = surface_create(16, 16);
    surface_set_target(surf);
    draw_clear_alpha(c_black, 0);
    for (var y0 = 0; y0 < 16; y0++) {
        var x0 = 0;
        while (x0 < 16) {
            var ch = string_char_at(rows[y0], x0 + 1);
            var x1 = x0 + 1;
            while (x1 < 16 && string_char_at(rows[y0], x1 + 1) == ch) x1++;
            if (ch != ".") {
                draw_set_color(Icon_PaletteColour(ch));
                draw_rectangle(x0, y0, x1 - 1, y0, false);
            }
            x0 = x1;
        }
    }
    surface_reset_target();
    var made = sprite_create_from_surface(surf, 0, 0, 16, 16, false, false, 0, 0);
    surface_free(surf);
    draw_set_alpha(a_before);
    draw_set_color(c_before);
    var out = { spr: made, sub: 0 };
    variable_struct_set(global.icon_cache, key, out);
    return out;
}

// Draws the icon with its top-left at (_x, _y), _scale GUI units per icon pixel. Returns false when there is no such icon.
function Icon_Draw(_category, _frame, _x, _y, _scale, _alpha = 1) {
    var ic = Icon_Get(_category, _frame);
    if (!is_struct(ic)) return false;
    draw_sprite_ext(ic.spr, ic.sub, _x, _y, _scale, _scale, 0, c_white, _alpha);
    return true;
}

// ---- ICON FALLBACK BEGIN (generated by art/tools/gen_icon_fallback.py; do not edit by hand) ----
// Frames per category are in the order of art/strips_v2/<category>_strip.txt (art/IMPORT-CHECKLIST.md).
function Icon_FallbackData() {
    if (variable_global_exists("icon_fb_data")) return global.icon_fb_data;
    var d = {};
    d.status = {
        ids: ["poison", "burn", "bleed", "stun", "steadfast", "break", "guard", "rev_up", "evasion", "take_aim", "foresight", "meditation", "solidify", "bloodthirsty", "blessing", "sundered", "curse"],
        rows: [
            ["......0000......", "....00222200....", "..002000100000..", "..020030103300..", ".02203200032010.", ".02002220000010.", "0220322220301110", "0210222222001110", "0210222222101110", "0220022211001110", ".02100111001110.", ".01110000011110.", "..011111111110..", "..001111111100..", "....00111100....", "......0000......"],
            ["......0000......", "....00222200....", "..002200022100..", "..022102001110..", ".02210022000110.", ".02100222020110.", "0221022222201110", "0210023322200110", "0210233332220110", "0220233332220110", ".02022333220010.", ".01002222200110.", "..010000000110..", "..001111111100..", "....00111100....", "......0000......"],
            ["......0000......", "....00222200....", "..002200022100..", "..022103011110..", ".02210030011110.", ".02110333011110.", "0221003330011110", "0210033332001110", "0210333333201110", "0220333332201110", ".02003332200110.", ".01100222001110.", "..011000001110..", "..001111111100..", "....00111100....", "......0000......"],
            ["......0000......", "....00222200....", "..000021122100..", "..003001000110..", ".00333000300110.", ".00030003330110.", "0220000003001110", "0210030000011110", "0210333000011110", "0200030003001110", ".00300003330110.", ".00001103230110.", "..011110000010..", "..001111111100..", "....00111100....", "......0000......"],
            ["..000000000000..", ".02222222222220.", "0211100000111110", "0211103330111110", "0211103020111110", "0210003330001110", "0210333332201110", "0200000320000110", "0203000320020110", "0203300320220110", "0200332322200110", "0210033322001110", "0211000000011110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["......0000......", "....00222200....", "..000000000100..", "..033333330000..", ".00322220223010.", ".00322202223010.", "0203220222230110", "0203222022230110", "0200322022300110", "0220032023001110", ".02100303001110.", ".01110000011110.", "..011100011110..", "..001111111100..", "....00111100....", "......0000......"],
            ["..000000000000..", ".02222222222220.", "0200000000000110", "0203333333330110", "0203223222110110", "0203223222110110", "0203333333330110", "0203223222110110", "0200323221100110", "0210033221001110", "0211003310011110", "0211100100111110", "0211110001111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0211110001111110", "0211100300111110", "0211003330011110", "0210033333001110", "0210333332201110", "0210003222001110", "0211103222011110", "0211103222011110", "0211102211011110", "0211101110011110", "0211100000111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0211111100000110", "0211110003330110", "0211000333320110", "0210033333200110", "0200333332001110", "0203333320011110", "0200233200111110", "0210020001111110", "0200200011111110", "0200000111111110", "0200011111111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0211110001111110", "0211000300011110", "0210033333001110", "0210330303301110", "0200300300300110", "0203333233330110", "0200300300300110", "0210330303301110", "0210033333001110", "0211000300011110", "0211110001111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0211110001111110", "0200010301000110", "0203000000030110", "0200033333000110", "0200332223300110", "0203320321330110", "0200332223300110", "0210033333001110", "0211000000011110", "0211111111111110", "0211111111111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0211110001111110", "0211100300111110", "0210003330001110", "0200303330300110", "0203303330330110", "0203323332330110", "0200322222210110", "0210022222100110", "0211001110001110", "0211100000111110", "0211111111111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0211111111111110", "0211000000011110", "0210033333001110", "0200323232100110", "0203333333210110", "0200322222100110", "0210032221001110", "0211003210011110", "0211100100111110", "0211110001111110", "0211111111111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0200000000000110", "0203333333330110", "0203222222210110", "0200332023300110", "0210332023301110", "0210031013001110", "0211030003011110", "0211000003001110", "0211111033301110", "0211111002001110", "0211111100011110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["..000000000000..", ".02222222222220.", "0211100000111110", "0211003330011110", "0211030003011110", "0200003330000110", "0203300000330110", "0203330003330110", "0203333033330110", "0200333033300110", "0210033033001110", "0211003030011110", "0211100000111110", "0211111111111110", ".01111111111110.", "..000000000000.."],
            ["......0000......", "....00222200....", "..000021100000..", "..033000003300..", ".00333333333010.", ".00322232223010.", "0203222302230110", "0203223002230110", "0200323002300110", "0220033003001110", ".02100303001110.", ".01110000011110.", "..011111111110..", "..001111111100..", "....00111100....", "......0000......"],
            ["......0000......", "....00222200....", "..000000000000..", "..003333333000..", ".00333333333010.", ".00330030033010.", "0203300300330110", "0203333333330110", "0200333233300110", "0220033333001110", ".02103030301110.", ".01100000001110.", "..011111111110..", "..001111111100..", "....00111100....", "......0000......"]
        ]
    };
    d.skill = {
        ids: ["wound", "hilt_bash", "muscle_up", "rev_up", "horizontal_slash", "power_strike", "poison_arrow", "evasion", "double_shot", "take_aim", "fireball", "poison_mist", "ice_spear", "meditation", "foresight"],
        rows: [
            ["................", "................", "........000.....", ".......00300....", "......003230....", "..0000032100000.", "..0100321000030.", "..00132100003300", "..00311000033330", ".001211000333330", "0011100100323330", "0111000000333330", "00100....0033300", ".000......00000.", "................", "................"],
            ["............000.", "...........00300", "..........003230", ".........0032100", ".000....0032100.", ".030...0032100..", ".000000032100...", "000001032100....", "03001132100.....", "00033322100.....", "0033333111000...", "0333333001110...", "0033313000100...", "000333300000....", "030000030.......", "000...000......."],
            ["..........000...", ".........00300..", "........0033300.", "........0333330.", ".00000000030000.", "003333330030....", "032323231030....", "032121211000....", "0322222210......", "0333332210......", "0322222110......", "0322222110......", "0012221100......", ".00111100.......", "..000000........", "................"],
            ["......000.......", ".....00300......", "....0032300.....", "...003222300....", "..00322222300...", ".0032222222300..", ".0311222221130..", ".0000322210000..", "000.0322210.000.", "030.0322210.030.", "000003222100000.", ".0300322210030..", ".0000322210000..", ".0000311110000..", ".0333000003330..", ".00000...00000.."],
            ["................", "....00000000....", "..000333333000..", ".00333333333300.", "0033332222333300", "0333221111223330", "0332210000322330", "0303100..0031030", "000300....003000", "..000......000..", "................", ".00000000000000.", ".03333333333330.", ".00000000000000.", "................", "................"],
            ["...........000..", ".......000.030..", ".......030.00000", ".......000003030", "........00030000", ".......003300000", "......0032100030", "..00000321000300", "..010032100.000.", "..00132100......", "..0031100.......", ".00121100.......", "001110010.......", "011100000.......", "00100...........", ".000............"],
            ["...........000..", ".....000000030..", ".....033333310..", ".....003222210..", "......00322100..", "......0031210...", "..000003003100..", ".0010030000330..", ".0310300.003100.", ".03130000032230.", ".03111100323210.", ".03111000322210.", ".000000.0322210.", "........0031100.", ".........00000..", "................"],
            [".............000", "........00000020", ".......002233320", "0000000023321220", "0333300230212200", "000000232212020.", "000002022122220.", "033323221202200.", "00003221222200..", "0002221022200...", "033331222200....", "00021222200.....", ".021220000..000.", ".020000.....010.", ".000........000.", "................"],
            ["..........000...", ".....00000030...", ".....03333310...", ".....0032221000.", "......003210030.", ".....0031223310.", "....00300322210.", "000003000032100.", "03003000030310..", "03030000300030..", "0330000300.000..", "031330300.......", "00030300........", "..033000........", "..031330........", "..000000........"],
            ["......000.......", "....0003000.....", "...003333300....", "..00333333300...", ".0033311133300..", ".0333111113330..", "003311121113300.", "033311232113330.", "003311121113300.", ".0333111113330..", ".0033311133300..", "..00333333300...", "...003333300....", "....0003000.....", "......000.......", "................"],
            ["................", "000.............", "030000.000000...", "003330003333000.", ".00313333332330.", ".030032333332100", ".000003333332230", "0000003333332210", "0333332233322210", "0000031222222100", "....00032222110.", "....00321111000.", "...0031100000...", "...030000.......", "...000..........", "................"],
            ["................", "....00000.......", "...0023200000...", "..002322202200..", ".00232222222300.", "0022220020022200", "0222220020022220", "0222212222122220", "0022222002222200", ".00111111111100.", "..000000000000..", "...020.000.020..", "...030.020.030..", "...000.030.000..", ".......000......", "................"],
            [".............000", "...000.....00030", "...0300000003330", "...0003003333300", ".....0000033330.", ".......00303330.", "......003233300.", ".....003232130..", "...00032321000..", "..0033232100000.", ".0032331100.030.", "0031321000..0000", "03231100.....030", "0032110......000", ".003000.........", "..000..........."],
            ["................", ".......000......", ".......030......", "...000.030.000..", "...0200000.020..", "...0000300.000..", "..00003330000...", "..03033333030...", "..03303330330...", "..03323332330...", "..00322222210...", "...0022222100...", "....00111000....", ".....00000......", "................", "................"],
            [".......000......", "...000.030.000..", "...030.030.030..", "...0000000.000..", "..00003330000...", ".0033333333300..", "003332222233300.", "033322000223330.", "033322030223330.", "003332222233300.", ".0033333333300..", "..000033300000..", "...0300000.030..", "...000.030.000..", ".......000......", "................"]
        ]
    };
    d.throwable = {
        ids: ["firebomb", "poison_pot", "ice_flask", "smoke_bomb"],
        rows: [
            [".........00000..", ".........03230..", ".....000003230..", "....0032233330..", "...00222213000..", "..00211111100...", ".0021211111100..", ".0213331111110..", ".0212311111110..", ".0211111111110..", ".0111111111110..", ".0111111111110..", ".0011111111100..", "..00111111100...", "...001111100....", "....0000000....."],
            ["................", "....00000000....", "...0011111100...", "...033333331000.", "...002222210030.", "..0032222221030.", ".00322222222230.", ".03222333222210.", ".03223333322110.", ".03223030321110.", ".03222333221110.", ".03222232321110.", ".00322222221110.", "..0011111111100.", "...00000000000..", "................"],
            [".....000000.....", ".....031110.....", ".....011110.....", ".....003300.....", "......0320......", ".....003200.....", "...0003322000...", "...0333333330...", "...0323222220...", "...0322323220...", "...0323222320...", "...0322222220...", "...0032222110...", "....001111000...", ".....000000.....", "................"],
            [".....00000......", "....0033300.....", ".00003233300....", "00333222333000..", "033333233333300.", "033333332333330.", "033323333333330.", "003333333332330.", ".00002220033300.", "..003111100000..", "..011211110.....", "..011111110.....", "..011111110.....", "..001111100.....", "...0011100......", "....00000......."]
        ]
    };
    d.passive = {
        ids: ["attack", "defense", "vitality", "magic", "speed", "critical", "greed", "recovery"],
        rows: [
            ["................", "................", "........000.....", ".......00300....", "......00323000..", "..000003210030..", "..01003210003000", "..00132100333330", "..00311000003000", ".00121100..030..", "001110010..000..", "011100000.......", "00100...........", ".000............", "................", "................"],
            [".0000000000000..", ".0333333333330..", ".0322222221230..", ".0322220221230..", ".0322220221230..", ".0322000001230..", ".0322220221230..", ".0322220221230..", ".0032222222300..", "..00322212300...", "...003212300....", "....0332330.....", "....0033300.....", ".....00300......", "......000.......", "................"],
            ["..00000..0000...", ".01111100111100.", ".01113111133110.", "0113333333333110", "0113333333333110", "0113333333333110", "0112333333332110", ".012233333322110", ".01123333322110.", "..0112233222110.", "..011122222110..", "...0111222110...", "....01111110....", ".....011110.....", "......0110......", ".......00......."],
            ["......000.......", "......030...000.", ".....00300..030.", ".....03330..000.", "....0032300.....", "..00033233000...", "000333222333000.", "033322232223330.", "000333222333000.", "..00033233000...", "....0032300.....", ".000.03330......", ".030.00300......", ".000..030.......", "......000.......", "................"],
            [".00000000.......", ".02222220.......", ".0000000000.....", "..03300033000...", "..003330033300..", "...003330033300.", "....00333003330.", "...003330033300.", "..003330033300..", "..03300033000...", "..0000.0000.....", ".000000000......", ".022222220000...", ".000222222220...", "...0000000000...", "................"],
            ["......000.......", ".000..030..000..", ".0300003000030..", ".0033033303300..", "..03333333330...", "..00332223300...", "0000322222300000", "0333322022333330", "0000322222300000", "..00332223320...", "..03333333230...", ".0033033303300..", ".0300003000030..", ".000..030..000..", "......030.......", "......000......."],
            ["................", "................", "...00000000.....", "...02233320.....", "...0022222000...", "..003222222100..", "..023233322210..", "..022322222210..", "..022333322210..", "..022222322210..", "..022333322100..", "..00222222210...", "...0011111000...", "....0000000.....", "................", "................"],
            [".......000......", ".....0002000000.", "...000332222220.", "..0033222221220.", "000322222212220.", "022222222122220.", "022222221222220.", "033322212222220.", "022222122222220.", "022221222223220.", "022212222223000.", "022122222333330.", "021222222003000.", "0222222000030...", "00000000..000...", "................"]
        ]
    };
    d.accessory = {
        ids: ["ring", "charm"],
        rows: [
            ["......000.......", ".....00300......", "...000333000....", "...033233330....", "...003322300....", "....00333000....", "...0033322200...", "..003222222200..", ".00322000022200.", ".032200..002220.", ".03200....00220.", ".022200..002220.", ".00222000022100.", "..002222222100..", "...0022222200...", "....00000000...."],
            [".000......000...", ".0300....0030...", ".00300..00300...", "..0030000300....", "...00300300.....", "....003300......", "....0032300.....", "..00032123000...", ".0033231123300..", ".0321113111230..", ".0032111112100..", "..00321112100...", "...003212100....", "....0032100.....", ".....00300......", "......000......."]
        ]
    };
    d.misc = {
        ids: ["gold_coin"],
        rows: [
            ["....0000000.....", "...003333300....", "..00322222200...", ".0032222222200..", "003222131222200.", "032221333122220.", "032211131112220.", "032211131112220.", "022211131112220.", "022221333122210.", "002222131222100.", ".0022222222100..", "..00222222100...", "...002111100....", "....0000000.....", "................"]
        ]
    };
    global.icon_fb_data = d;
    return d;
}
// ---- ICON FALLBACK END ----

// ---- Battle feel (D138, D139): pure curves for the hit freeze, sparks, jolt, recoil, zoom punch, death pop, HP lag bar, edge flash and the low-HP warning ----
// Everything here is a function of elapsed ms (and the Screen shake setting passed in as _shake_on), so the tests drive it without a battle. The battle controller
// keeps one "feel clock" (feel_ms, it stands still in a hit freeze) and the start time of each effect; scr_combat reads these through Battle_Feel*.
#macro FEEL_FREEZE_NORMAL_MS 40         // D138: a hit freezes the picture 40 ms (OK / Good / Weak) ...
#macro FEEL_FREEZE_PERFECT_MS 80        // ... 80 ms on a Perfect ...
#macro FEEL_FREEZE_HEAVY_MS 120         // ... 120 ms on a crit or a BREAK
#macro FEEL_DEATH_FREEZE_MS 120         // the killing blow: freeze + white flash, then the burst
#macro FEEL_DEATH_BURST_MS 500
#macro FEEL_DEATH_BURST_BOSS_MS 900
#macro FEEL_GRAVITY 260                 // particle gravity, world px per second squared
#macro FEEL_JOLT_MS 80                  // D139: the view pushes in 2-3 px and eases back
#macro FEEL_RECOIL_MS 150               // the enemy squashes and springs back
#macro FEEL_PUNCH_MS 150                // crit / BREAK zoom punch
#macro FEEL_PUNCH_PX 4                  // px a side of the 160 px picture = 8/160 = 5% zoom
#macro FEEL_LAG_MS 400                  // the HP lag bar drains this long
#macro FEEL_EDGE_MS 150                 // the dark screen-edge flash of a big hit taken
#macro FEEL_EDGE_ALPHA 0.9             // the battle backdrop is almost UI_C_DARKEST already, so the edge bands need a high alpha to read at all
#macro FEEL_SPARK_MS 240
#macro FEEL_BIG_SHAKE_MAG 1.4           // a big hit taken shakes the picture harder than a Perfect (QTE_SHAKE_PERFECT_MAG is 0.8)
#macro FEEL_BIG_SHAKE_MS 260
#macro FEEL_LOWHP_PCT 0.25              // D139: the warning is on at or under this share of max HP (the HUD's own "low" mark)
#macro FEEL_BEAT_MS 1200                // one lub-dub per 1.2 s
#macro FEEL_BEAT_GAP_MS 220             // the "dub" follows the "lub" after this
#macro FEEL_BEAT_VOL 0.2                // of the SFX volume: well under the music, the owner does not want a loud heartbeat
#macro FEEL_PULSE_MS 2400               // the edge pulse swells once per two beats
#macro FEEL_PULSE_ALPHA 0.45            // still faint on screen: the bands are only a few levels darker than the backdrop

function Feel_Ease(_u) {
    return 1 - sqr(1 - clamp(_u, 0, 1));
}

function Feel_EaseInOut(_u) {
    var u = clamp(_u, 0, 1);
    return u * u * (3 - 2 * u);
}

// 0..1 shape over _ms: 0 at the start, up to 1 at 30% of the time (eased out), eased back to 0 at the end; 0 before the start and from the end on.
function Feel_Pulse(_elapsed_ms, _ms) {
    if (_elapsed_ms <= 0 || _elapsed_ms >= _ms) return 0;
    var u = _elapsed_ms / _ms;
    if (u < 0.3) return Feel_Ease(u / 0.3);
    return 1 - Feel_EaseInOut((u - 0.3) / 0.7);
}

// How long a damaging player hit freezes the picture (D138).
function Feel_FreezeMs(_key, _crit, _break) {
    if (_crit || _break) return FEEL_FREEZE_HEAVY_MS;
    if (_key == QTE_PERFECT) return FEEL_FREEZE_PERFECT_MS;
    return FEEL_FREEZE_NORMAL_MS;
}

// px the view pushes in on each side for a hit (D139: 2-3 px).
function Feel_JoltPx(_key, _crit) {
    return (_crit || _key == QTE_PERFECT) ? 3 : 2;
}

// The picture's push-in, px a side: the hit's jolt (_jolt_px over FEEL_JOLT_MS) or the crit / BREAK punch (FEEL_PUNCH_PX over FEEL_PUNCH_MS), the larger one.
// The elapsed times are ms since each began (a huge negative number when it never did). 0 with the Screen shake setting off.
function Feel_InsetPx(_hit_elapsed_ms, _jolt_px, _punch_elapsed_ms, _punch_on, _shake_on) {
    if (!_shake_on) return 0;
    var j = round(_jolt_px * Feel_Pulse(_hit_elapsed_ms, FEEL_JOLT_MS));
    var p = _punch_on ? round(FEEL_PUNCH_PX * Feel_Pulse(_punch_elapsed_ms, FEEL_PUNCH_MS)) : 0;
    return max(j, p);
}

// The part of the 160 x 144 picture a push-in of _inset px a side shows, centred on (_cx, _cy) in view pixels: the same arithmetic as Display_DrawFrame's zoom
// branch (whole pixels, never outside the picture). kx / ky = how much each axis is magnified; zoom = the value to give Display_SetZoom.
function Feel_ZoomRegion(_inset, _cx, _cy) {
    if (_inset <= 0) return { sx: 0, sy: 0, sw: DISPLAY_BASE_W, sh: DISPLAY_BASE_H, kx: 1, ky: 1, zoom: 1 };
    var zoom = DISPLAY_BASE_W / max(1, DISPLAY_BASE_W - 2 * _inset);
    var sw = max(1, round(DISPLAY_BASE_W / zoom));
    var sh = max(1, round(DISPLAY_BASE_H / zoom));
    var sx = clamp(round(_cx - sw * 0.5), 0, DISPLAY_BASE_W - sw);
    var sy = clamp(round(_cy - sh * 0.5), 0, DISPLAY_BASE_H - sh);
    return { sx: sx, sy: sy, sw: sw, sh: sh, kx: DISPLAY_BASE_W / sw, ky: DISPLAY_BASE_H / sh, zoom: zoom };
}

// The enemy's squash: x wider and y shorter right after a hit (up to 12%), then a spring back past 1 (a little tall and narrow) and rest. 1 x 1 at both ends.
function Feel_RecoilScale(_elapsed_ms, _shake_on) {
    if (!_shake_on || _elapsed_ms <= 0 || _elapsed_ms >= FEEL_RECOIL_MS) return { x: 1, y: 1 };
    var u = _elapsed_ms / FEEL_RECOIL_MS;
    var s;
    if (u < 0.3) {
        s = Feel_Ease(u / 0.3);
    } else {
        var v = (u - 0.3) / 0.7;
        s = cos(v * pi * 1.5) * (1 - v);
    }
    return { x: 1 + 0.12 * s, y: 1 - 0.12 * s };
}

// The trailing HP bar: it stays near the old value for a moment and then drains to the real HP, reaching it at FEEL_LAG_MS. A rise is not lagged.
function Feel_LagShown(_from, _to, _elapsed_ms) {
    if (_from <= _to || _elapsed_ms >= FEEL_LAG_MS) return _to;
    var u = clamp(_elapsed_ms / FEEL_LAG_MS, 0, 1);
    return _to + (_from - _to) * (1 - u * u);
}

// One draw frame of the player's HP trail: a drop starts the lag from where the bar was, a rise glides up. _hud holds hp_shown, lag_hp, lag_from, lag_start.
function Feel_LagStep(_hud, _hp, _now, _dt) {
    if (!variable_struct_exists(_hud, "lag_hp")) {
        _hud.lag_hp = _hp;
        _hud.lag_from = _hp;
        _hud.lag_start = _now;
    }
    if (_hp < _hud.lag_hp) {
        _hud.lag_from = max(_hud.hp_shown, _hp);
        _hud.lag_start = _now;
    }
    _hud.lag_hp = _hp;
    if (_hp >= _hud.hp_shown) {
        _hud.hp_shown = Ui_Glide(_hud.hp_shown, _hp, _dt, 140);
    } else {
        _hud.hp_shown = Feel_LagShown(_hud.lag_from, _hp, _now - _hud.lag_start);
    }
    return _hud.hp_shown;
}

// D138: a big hit taken is a telegraphed / heavy move, or damage of a quarter of max HP or more.
function Feel_IsBigHit(_dmg, _max_hp, _heavy) {
    return _dmg > 0 && (_heavy || (_max_hp > 0 && _dmg * 4 >= _max_hp));
}

// The dark screen-edge flash: strongest at once, gone at FEEL_EDGE_MS.
function Feel_EdgeAlpha(_elapsed_ms) {
    if (_elapsed_ms < 0 || _elapsed_ms >= FEEL_EDGE_MS) return 0;
    return FEEL_EDGE_ALPHA * (1 - _elapsed_ms / FEEL_EDGE_MS);
}

// The player's HP panel jolts when the enemy hits (D139): px up, 2 (3 on a big hit) over FEEL_JOLT_MS; 0 with the Screen shake setting off.
function Feel_PanelJoltPx(_elapsed_ms, _big, _shake_on) {
    if (!_shake_on) return 0;
    return round((_big ? 3 : 2) * Feel_Pulse(_elapsed_ms, FEEL_JOLT_MS));
}

// ---- the low-HP warning (D139) ----
function Feel_LowHpActive(_hp, _max_hp) {
    return _max_hp > 0 && _hp > 0 && (_hp / _max_hp) <= FEEL_LOWHP_PCT;
}

// Thumps heard by _ms into the warning: a "lub" at the start of each cycle and a "dub" FEEL_BEAT_GAP_MS later, one cycle per FEEL_BEAT_MS. The first is at once.
function Feel_BeatCount(_ms) {
    if (_ms < 0) return 0;
    var cyc = floor(_ms / FEEL_BEAT_MS);
    var ph = _ms - cyc * FEEL_BEAT_MS;
    return 2 * cyc + 1 + ((ph >= FEEL_BEAT_GAP_MS) ? 1 : 0);
}

// The thump's volume (0..1 of the SFX volume, which SFX_Play applies on top): quiet, the "dub" softer.
function Feel_BeatVol(_second) {
    return FEEL_BEAT_VOL * (_second ? 0.7 : 1);
}

// The faint dark pulse at the screen edges: one slow swell per FEEL_PULSE_MS, 0 when the warning is off.
function Feel_PulseAlpha(_ms, _active) {
    if (!_active) return 0;
    return FEEL_PULSE_ALPHA * (0.5 - 0.5 * cos(2 * pi * _ms / FEEL_PULSE_MS));
}

// Plays a sound without becoming "the last sound" the bot and the tests read (global.sfx_last_key / handle).
function Feel_PlayKeep(_key, _vol, _pitch) {
    var k = variable_global_exists("sfx_last_key") ? global.sfx_last_key : "";
    var h = variable_global_exists("sfx_last_handle") ? global.sfx_last_handle : -1;
    SFX_Play(_key, _vol, _pitch);
    global.sfx_last_key = k;
    global.sfx_last_handle = h;
}

// ---- the enemy death pop (D138) ----
function Feel_DeathTotalMs(_boss) {
    return FEEL_DEATH_FREEZE_MS + (_boss ? FEEL_DEATH_BURST_BOSS_MS : FEEL_DEATH_BURST_MS);
}

// 0 = freeze + white flash, 1 = burst, 2 = over.
function Feel_DeathPhase(_t_ms, _boss) {
    if (_t_ms < FEEL_DEATH_FREEZE_MS) return 0;
    if (_t_ms < Feel_DeathTotalMs(_boss)) return 1;
    return 2;
}

// The sprite is drawn only before the burst begins.
function Feel_SpriteVisible(_t_ms) {
    return _t_ms < FEEL_DEATH_FREEZE_MS;
}

// A particle's opacity _t_ms into the burst: solid for 40%, then fading to 0 at _burst_ms.
function Feel_ParticleAlpha(_t_ms, _burst_ms) {
    var u = _t_ms / max(1, _burst_ms);
    if (u <= 0.4) return 1;
    return clamp(1 - (u - 0.4) / 0.6, 0, 1);
}

// Where a particle is _t_ms into the burst (world px): its cell plus its velocity (px per second) and gravity.
function Feel_ParticlePos(_p, _t_ms) {
    var ts = _t_ms / 1000;
    return { x: _p.x + _p.vx * ts, y: _p.y + _p.vy * ts + 0.5 * FEEL_GRAVITY * ts * ts };
}

// A deterministic 0..1 from an index and a salt (no random stream is touched: tests and shots see the same burst).
function Feel_Hash01(_i, _salt) {
    var v = sin(_i * 12.9898 + _salt * 78.233) * 43758.5453;
    return v - floor(v);
}

// The palette colour (UI_C_*) nearest a sprite pixel by brightness.
function Feel_PaletteOf(_col) {
    var lum = 0.299 * colour_get_red(_col) + 0.587 * colour_get_green(_col) + 0.114 * colour_get_blue(_col);
    if (lum < 56) return UI_C_DARKEST;
    if (lum < 112) return UI_C_DARK;
    if (lum < 190) return UI_C_LIGHT;
    return UI_C_LIGHTEST;
}

// The pixel squares an enemy sprite bursts into: a grid over its bounds, one square per opaque cell, in the palette colour of the sprite's pixel there (or a
// brightness pattern when the sprite cannot be read). _wx, _wy = the sprite's top-left in world px. Returns [{ x, y (cell centre), vx, vy, col, size }].
function Feel_DeathParticles(_spr, _img, _wx, _wy, _xs, _ys, _boss) {
    var out = [];
    if (_spr == noone || !sprite_exists(_spr)) return out;
    var sw = sprite_get_width(_spr);
    var sh = sprite_get_height(_spr);
    var cell = max(2, ceil(max(sw, sh) / (_boss ? 14 : 10)));
    var surf = -1;
    try {
        surf = surface_create(sw, sh);
        if (surface_exists(surf)) {
            surface_set_target(surf);
            draw_clear_alpha(c_black, 0);
            draw_sprite(_spr, _img, sprite_get_xoffset(_spr), sprite_get_yoffset(_spr));
            surface_reset_target();
        }
    } catch (_e) {
        surf = -1;
    }
    var have = (surf != -1 && surface_exists(surf));
    var cols = ceil(sw / cell);
    var rows = ceil(sh / cell);
    var n = 0;
    for (var cy = 0; cy < rows; cy++) {
        for (var cx = 0; cx < cols; cx++) {
            var px = min(sw - 1, cx * cell + cell div 2);
            var py = min(sh - 1, cy * cell + cell div 2);
            var col = UI_C_LIGHT;
            if (have) {
                var raw = surface_getpixel_ext(surf, px, py);
                if (((raw >> 24) & 255) < 128) continue;   // clear: not part of the silhouette
                col = Feel_PaletteOf(raw & $FFFFFF);
            } else {
                col = (((cx + cy) mod 3) == 0) ? UI_C_LIGHTEST : ((((cx + cy) mod 3) == 1) ? UI_C_LIGHT : UI_C_DARK);
            }
            var dx = ((cx + 0.5) / cols) * 2 - 1;      // -1 (left) .. 1 (right)
            var dy = ((cy + 0.5) / rows) * 2 - 1;      // -1 (top) .. 1 (bottom)
            var h1 = Feel_Hash01(n, 1);
            var h2 = Feel_Hash01(n, 2);
            array_push(out, {
                x: _wx + (cx * cell + cell * 0.5) * _xs,
                y: _wy + (cy * cell + cell * 0.5) * _ys,
                vx: dx * (_boss ? 56 : 46) + (h1 - 0.5) * 24,
                vy: -(24 + h2 * (_boss ? 64 : 52)) + dy * 26,
                col: col,
                size: cell * 0.5 * (_xs + _ys)
            });
            n++;
        }
    }
    if (have) surface_free(surf);
    return out;
}

// ---- hit sparks (D138): pixel squares thrown out from the impact point ----
function Feel_SparkCount(_key, _crit, _break) {
    if (_break) return 18;
    if (_crit) return 14;
    if (_key == QTE_PERFECT) return 11;
    if (_key == QTE_GOOD) return 7;
    return 6;
}

// World px per spark square.
function Feel_SparkSize(_key, _crit, _break) {
    if (_break) return 3;
    if (_crit || _key == QTE_PERFECT) return 2;
    return 1;
}

// The sparks of a hit: each a direction, a reach (world px) and a colour.
function Feel_Sparks(_cx, _cy, _key, _crit, _break) {
    var n = Feel_SparkCount(_key, _crit, _break);
    var size = Feel_SparkSize(_key, _crit, _break);
    var big = (_crit || _break || _key == QTE_PERFECT);
    var out = [];
    for (var i = 0; i < n; i++) {
        array_push(out, {
            a: (i / n) * 2 * pi + Feel_Hash01(i, 3) * 0.6,
            r: (big ? 16 : 11) + Feel_Hash01(i, 4) * (big ? 12 : 7),
            size: size,
            col: ((i mod 2) == 0) ? UI_C_LIGHTEST : UI_C_LIGHT
        });
    }
    return out;
}

// A spark's place _elapsed_ms after the hit (world px): it flies out and slows (eased), and is gone at FEEL_SPARK_MS. It blinks off for its last quarter.
function Feel_SparkPos(_s, _cx, _cy, _elapsed_ms) {
    var u = clamp(_elapsed_ms / FEEL_SPARK_MS, 0, 1);
    var e = 1 - power(1 - u, 3);   // flies out fast, then slows
    var alive = (_elapsed_ms < FEEL_SPARK_MS) && (u < 0.75 || (floor(_elapsed_ms / 30) mod 2 == 0));
    return { x: _cx + cos(_s.a) * _s.r * e, y: _cy + sin(_s.a) * _s.r * e, alive: alive };
}

// The dark screen edges (UI_C_DARKEST): three bands in from the edge, 3 / 4 / 6 world px wide, 100% / 60% / 30% of _alpha. A faint vignette, no distortion.
function Feel_DrawEdge(_gw, _gh, _unit, _alpha) {
    var a0 = draw_get_alpha();
    var c0 = draw_get_colour();
    draw_set_colour(UI_C_DARKEST);
    var widths = [3, 4, 6];
    var mults = [1, 0.6, 0.3];
    var d0 = 0;
    for (var i = 0; i < 3; i++) {
        var d1 = d0 + round(widths[i] * _unit);
        draw_set_alpha(_alpha * mults[i]);
        draw_rectangle(d0, d0, _gw - 1 - d0, d1 - 1, false);                       // top
        draw_rectangle(d0, _gh - d1, _gw - 1 - d0, _gh - 1 - d0, false);           // bottom
        draw_rectangle(d0, d1, d1 - 1, _gh - 1 - d1, false);                       // left
        draw_rectangle(_gw - d1, d1, _gw - 1 - d0, _gh - 1 - d1, false);           // right
        d0 = d1;
    }
    draw_set_alpha(a0);
    draw_set_colour(c0);
}

// ---- Map juice (D138, map part): chest burst, the item that rises out, the level-up sparkle, the gold counter that ticks up, the step squash ----
// Pure curves first (a function of ms and the Screen shake setting), then a small effect list (global.map_fx) the world layer script draws (MapFx_DrawWorldFx,
// World_DrawFx in scr_enemy). Everything is code-drawn in the four palette colours; the sounds are existing ones played through Feel_PlayKeep. D49: with Screen
// shake off the squash and the gold bounce are off (the chest burst, the rising item, the sparkle and the count-up are not motion of the picture).
#macro FEEL_BURST_MS 320                // the chest burst
#macro FEEL_RISE_MS 600                 // the item rises and fades over this
#macro FEEL_RISE_PX 12                  // ... this far
#macro FEEL_GOLD_TICK_MS 400            // the HUD gold counts up over this
#macro FEEL_SQUASH_MS 120               // the step squash eases back over this
#macro FEEL_SQUASH_X 1.08               // wider ...
#macro FEEL_SQUASH_Y 0.92               // ... and shorter at the start of a step
#macro FEEL_SPARKLE_MS 500              // the level-up ring
#macro FEEL_SPARKLE_N 10
#macro FEEL_SPARKLE_R0 5                // world px from the player's centre: the ring starts here ...
#macro FEEL_SPARKLE_R1 18               // ... and ends here

// ---- the chest burst ----
// A fan of palette pixels thrown up from the lid at (_cx, _cy): each { x, y, vx, vy, col, size } for Feel_ParticlePos (world px, px per second, gravity FEEL_GRAVITY).
function Feel_ChestBurst(_cx, _cy) {
    var n = 12;
    var out = [];
    var cols = [UI_C_LIGHTEST, UI_C_LIGHT, UI_C_DARK, UI_C_LIGHT];   // drawn with a dark shadow pixel (MapFx_DrawWorldFx), so they read on a light floor and a dark one
    for (var i = 0; i < n; i++) {
        var u = (i + 0.5) / n;                          // 0..1 across the lid
        var h1 = Feel_Hash01(i, 11);
        var h2 = Feel_Hash01(i, 12);
        array_push(out, {
            x: _cx + (u - 0.5) * 8,
            y: _cy,
            vx: (u - 0.5) * 84 + (h1 - 0.5) * 12,       // about -44 .. 44 px per second
            vy: -(40 + h2 * 40),                         // -40 .. -80: about 12 px up at the top of the arc
            col: cols[i mod 4],
            size: ((i mod 4) == 3) ? 1 : 2
        });
    }
    return out;
}

function Feel_BurstAlive(_t_ms) {
    return _t_ms >= 0 && _t_ms < FEEL_BURST_MS;
}

// Solid for the first 40%, then fading to 0 at FEEL_BURST_MS (the same shape as the death pop).
function Feel_BurstAlpha(_t_ms) {
    if (_t_ms >= FEEL_BURST_MS) return 0;
    return Feel_ParticleAlpha(max(0, _t_ms), FEEL_BURST_MS);
}

// ---- the item that rises out ----
// Whole pixels up from the chest, eased out: 0 at the start, FEEL_RISE_PX at FEEL_RISE_MS.
function Feel_RiseY(_t_ms) {
    if (_t_ms <= 0) return 0;
    return round(FEEL_RISE_PX * Feel_Ease(_t_ms / FEEL_RISE_MS));
}

// Opacity: solid for the first 35%, then a straight fade to 0 at FEEL_RISE_MS.
function Feel_RiseAlpha(_t_ms) {
    var u = _t_ms / FEEL_RISE_MS;
    if (u <= 0.35) return 1;
    return clamp(1 - (u - 0.35) / 0.65, 0, 1);
}

// What a loot entry (or "card") rises as: "item" (an { item_id }), "gold" (a { gold }), "card" (the string "card"), "" for anything else.
function MapFx_RiseKind(_what) {
    if (is_string(_what)) return (_what == "card") ? "card" : "";
    if (!is_struct(_what)) return "";
    if (variable_struct_exists(_what, "gold")) return "gold";
    if (variable_struct_exists(_what, "item_id")) return "item";
    return "";
}

// ---- the gold counter ----
// The number shown _t_ms after a gain from _from to _to: counts up, eased out, whole numbers, reaches _to at FEEL_GOLD_TICK_MS and never passes it.
// Gold that goes down (a purchase) is shown at once.
function Feel_GoldShown(_from, _to, _t_ms) {
    if (_to <= _from || _t_ms >= FEEL_GOLD_TICK_MS) return _to;
    if (_t_ms <= 0) return _from;
    return clamp(_from + floor((_to - _from) * Feel_Ease(_t_ms / FEEL_GOLD_TICK_MS)), _from, _to);
}

function Feel_GoldNew(_gold) {
    return { shown: _gold, from: _gold, to: _gold, start: 0 };
}

// One frame of the display: _st = the counter's state, _gold = the real gold, _now = ms. A new real value starts a count from what is shown now. Returns the number to draw.
function Feel_GoldStep(_st, _gold, _now) {
    if (_gold != _st.to) {
        if (_gold < _st.to) {
            _st.shown = _gold;
            _st.from = _gold;
        } else {
            _st.from = _st.shown;
        }
        _st.to = _gold;
        _st.start = _now;
    }
    _st.shown = Feel_GoldShown(_st.from, _st.to, _now - _st.start);
    return _st.shown;
}

// 1 px lift at the start of a count and again as the number lands, 80 ms each. 0 with Screen shake off (D49).
function Feel_GoldBounce(_t_ms, _shake_on) {
    if (!_shake_on) return 0;
    if (_t_ms >= 0 && _t_ms < 80) return 1;
    if (_t_ms >= FEEL_GOLD_TICK_MS && _t_ms < FEEL_GOLD_TICK_MS + 80) return 1;
    return 0;
}

// The HUD's gold display, one for the game (kept across rooms, so the number does not restart from the real value at every room change).
function Feel_GoldState() {
    if (!variable_global_exists("gold_disp") || !is_struct(global.gold_disp)) global.gold_disp = Feel_GoldNew(Gold_Get());
    return global.gold_disp;
}

// ---- the step squash ----
// x wider and y shorter at the start of a tile step (FEEL_SQUASH_X / FEEL_SQUASH_Y), easing back to 1 x 1 at FEEL_SQUASH_MS. 1 x 1 with Screen shake off (D49).
function Feel_SquashScale(_t_ms, _shake_on) {
    if (!_shake_on || _t_ms >= FEEL_SQUASH_MS) return { x: 1, y: 1 };
    var e = 1 - Feel_Ease(max(0, _t_ms) / FEEL_SQUASH_MS);   // 1 at the start, 0 at the end
    return { x: 1 + (FEEL_SQUASH_X - 1) * e, y: 1 - (1 - FEEL_SQUASH_Y) * e };
}

// The same in whole pixels for a _size px sprite whose top-left sits on the tile: { w, h, dx, dy } = the drawn width and height and where its top-left goes relative to the
// tile. The feet stay on the tile's bottom edge (dy + h = _size) and the sprite stays centred on the tile (at most 1 px out sideways). Pixel-safe: no half pixels.
function Feel_SquashBox(_t_ms, _shake_on, _size) {
    var sc = Feel_SquashScale(_t_ms, _shake_on);
    var w = round(_size * sc.x);
    var h = round(_size * sc.y);
    return { w: w, h: h, dx: floor((_size - w) / 2), dy: _size - h };
}

// ---- the level-up sparkle ----
// A ring of FEEL_SPARKLE_N sparkles: each an angle, a size (1 or 2 px) and a palette colour.
function Feel_SparkleRing() {
    var out = [];
    for (var i = 0; i < FEEL_SPARKLE_N; i++) {
        array_push(out, { a: (i / FEEL_SPARKLE_N) * 2 * pi + Feel_Hash01(i, 21) * 0.2, size: ((i mod 2) == 0) ? 2 : 1, col: ((i mod 2) == 0) ? UI_C_LIGHTEST : UI_C_LIGHT });
    }
    return out;
}

// A sparkle round the centre (_cx, _cy) _t_ms after the level-up (world px): the ring grows from FEEL_SPARKLE_R0 to FEEL_SPARKLE_R1 (eased out) and turns a little.
// Gone at FEEL_SPARKLE_MS; it blinks off for its last quarter.
function Feel_SparklePos(_s, _cx, _cy, _t_ms) {
    var u = clamp(_t_ms / FEEL_SPARKLE_MS, 0, 1);
    var r = FEEL_SPARKLE_R0 + (FEEL_SPARKLE_R1 - FEEL_SPARKLE_R0) * Feel_Ease(u);
    var a = _s.a + u * 0.7;
    var alive = (_t_ms >= 0) && (_t_ms < FEEL_SPARKLE_MS) && (u < 0.75 || (floor(_t_ms / 30) mod 2 == 0));
    return { x: _cx + cos(a) * r, y: _cy + sin(a) * r, alive: alive };
}

// ---- the effect list ----
// The clock of the effects: ms. Normally the game clock; the picture scenario freezes it (global.mapfx_clock >= 0) so a picture shows an exact age.
function MapFx_Now() {
    if (variable_global_exists("mapfx_clock") && global.mapfx_clock >= 0) return global.mapfx_clock;
    return current_time;
}

function MapFx_List() {
    if (!variable_global_exists("map_fx") || !is_array(global.map_fx)) global.map_fx = [];
    return global.map_fx;
}

function MapFx_Clear() {
    global.map_fx = [];
}

// How many effects of a kind ("burst", "rise", "sparkle"; "" = all) are in the list.
function MapFx_Count(_kind) {
    var l = MapFx_List();
    if (_kind == "") return array_length(l);
    var n = 0;
    for (var i = 0; i < array_length(l); i++) if (l[i].kind == _kind) n++;
    return n;
}

// The start time (ms) of the first effect of a kind, or -1.
function MapFx_Start(_kind) {
    var l = MapFx_List();
    for (var i = 0; i < array_length(l); i++) if (l[i].kind == _kind) return l[i].start;
    return -1;
}

function MapFx_Life(_kind) {
    switch (_kind) {
        case "burst": return FEEL_BURST_MS;
        case "rise": return FEEL_RISE_MS;
        case "sparkle": return FEEL_SPARKLE_MS;
    }
    return 0;
}

// Removes the effects that are over at _now.
function MapFx_Prune(_now) {
    var l = MapFx_List();
    for (var i = array_length(l) - 1; i >= 0; i--) {
        if (_now - l[i].start >= MapFx_Life(l[i].kind)) array_delete(l, i, 1);
    }
}

// A chest or barrel opened: the lid is at (_cx, _top). The burst always; the first thing it gives (an entry of _loot, or "card" when _card) rises out of it.
// The existing chime for the rising item plays from MapFx_Step a moment after the chest's own sound (Feel_PlayKeep: it does not become "the last sound").
function MapFx_Opened(_cx, _top, _loot, _card, _now = MapFx_Now()) {
    var l = MapFx_List();
    array_push(l, { kind: "burst", start: _now, room: room, x: _cx, y: _top, parts: Feel_ChestBurst(_cx, _top) });
    var what = undefined;
    if (_card) what = "card";
    else if (is_array(_loot) && array_length(_loot) > 0) what = _loot[0];
    if (MapFx_RiseKind(what) != "") {
        array_push(l, { kind: "rise", start: _now, room: room, x: _cx, y: _top, what: what, chime: false });
    }
}

// A level-up: a ring of sparkles round the player (the player's place is read when it is drawn, so the ring follows him).
function MapFx_Sparkle(_now = MapFx_Now()) {
    array_push(MapFx_List(), { kind: "sparkle", start: _now, room: room, ring: Feel_SparkleRing(), chime: false });
}

// The sounds that are due: the rising item's chime 140 ms after the chest's sound, the level-up chime at once (an existing UI sound, higher). Once each.
function MapFx_Sounds(_now) {
    var l = MapFx_List();
    for (var i = 0; i < array_length(l); i++) {
        var e = l[i];
        if ((e.kind != "rise" && e.kind != "sparkle") || e.chime) continue;
        if (e.kind == "rise" && _now - e.start >= 140) {
            e.chime = true;
            Feel_PlayKeep("ui_confirm", 0.5, 1.3);
        } else if (e.kind == "sparkle") {
            e.chime = true;
            Feel_PlayKeep("ui_confirm", 0.6, 1.5);
        }
    }
}

// Whether a level gain should sparkle. _key identifies the run (and character) the level belongs to: a different key (a load, a new run) or a lower level only
// remembers the new level. Returns { fire, seen, key }.
function MapFx_LevelGate(_seen_key, _seen_level, _key, _level) {
    if (_key != _seen_key) return { fire: false, seen: _level, key: _key };
    return { fire: (_level > _seen_level), seen: _level, key: _key };
}

// Run every frame from the player's Step: drops finished effects and watches the character's level. A level gained on the map (an auto-resolved fight) or in a battle
// (seen when the player is back) sparkles once.
function MapFx_Step() {
    MapFx_Prune(MapFx_Now());
    MapFx_Sounds(MapFx_Now());
    var gs = GameState_Get();
    if (!is_struct(gs.player_ch) || !variable_struct_exists(gs.player_ch, "level")) return;
    var run = Run_Get();
    var key = (is_struct(run) && run.active) ? (string(run.seed) + ":" + string(run.started_at)) : "none";
    var seen_key = variable_global_exists("mapfx_level_key") ? global.mapfx_level_key : "";
    var seen_level = variable_global_exists("mapfx_level_seen") ? global.mapfx_level_seen : gs.player_ch.level;
    var g = MapFx_LevelGate(seen_key, seen_level, key, gs.player_ch.level);
    if (g.fire && (Transition_IsActive() || room == rm_battle)) return;   // not under a fade: the next frame tries again
    global.mapfx_level_key = g.key;
    global.mapfx_level_seen = g.seen;
    if (g.fire) MapFx_Sparkle();
}

// ---- drawing (World_DrawFx, the world pass) ----
function Feel_DrawCardGlyph(_x, _y, _alpha) {
    var a0 = draw_get_alpha();
    var c0 = draw_get_colour();
    draw_set_alpha(_alpha);
    draw_set_colour(UI_C_DARKEST);
    draw_rectangle(_x + 3, _y + 1, _x + 12, _y + 14, false);        // 10 x 14 card with a dark edge
    draw_set_colour(UI_C_LIGHTEST);
    draw_rectangle(_x + 4, _y + 2, _x + 11, _y + 13, false);
    draw_set_colour(UI_C_LIGHT);
    draw_rectangle(_x + 6, _y + 4, _x + 9, _y + 7, false);          // a small emblem
    draw_set_colour(UI_C_DARK);
    draw_rectangle(_x + 6, _y + 9, _x + 9, _y + 9, false);
    draw_rectangle(_x + 6, _y + 11, _x + 9, _y + 11, false);
    draw_set_alpha(a0);
    draw_set_colour(c0);
}

// The 16 x 16 picture of what rises, top-left at (_x, _y): an item's icon, the coin, or the card glyph.
function MapFx_DrawWhat(_what, _x, _y, _alpha) {
    switch (MapFx_RiseKind(_what)) {
        case "item":
            var item = ItemDB_Get(_what.item_id);
            if (is_struct(item)) Item_DrawIcon(item, _x, _y, 16, _alpha);
            break;
        case "gold":
            Icon_Draw("misc", Icon_Frame("misc", "gold_coin"), _x, _y, 1, _alpha);
            break;
        case "card":
            Feel_DrawCardGlyph(_x, _y, _alpha);
            break;
    }
}

function MapFx_DrawWorldFx() {
    if (!Fx_IsWorldPass()) return;
    var now = MapFx_Now();
    var l = MapFx_List();
    var a0 = draw_get_alpha();
    var c0 = draw_get_colour();
    for (var i = 0; i < array_length(l); i++) {
        var e = l[i];
        if (e.room != room) continue;
        var t = now - e.start;
        if (t < 0) continue;
        switch (e.kind) {
            case "burst":
                if (!Feel_BurstAlive(t)) break;
                draw_set_alpha(Feel_BurstAlpha(t));
                for (var k = 0; k < array_length(e.parts); k++) {
                    var p = e.parts[k];
                    var q = Feel_ParticlePos(p, t);
                    var px = floor(q.x);
                    var py = floor(q.y);
                    draw_set_colour(UI_C_DARKEST);
                    draw_rectangle(px + 1, py + 1, px + p.size, py + p.size, false);   // a one pixel shadow down and right
                    draw_set_colour(p.col);
                    draw_rectangle(px, py, px + p.size - 1, py + p.size - 1, false);
                }
                break;
            case "rise":
                if (t >= FEEL_RISE_MS) break;
                MapFx_DrawWhat(e.what, e.x - 8, e.y - 8 - Feel_RiseY(t), Feel_RiseAlpha(t));
                break;
            case "sparkle":
                if (t >= FEEL_SPARKLE_MS || !instance_exists(obj_player)) break;
                var pl = instance_find(obj_player, 0);
                var cx = round(pl.x) + 8;
                var cy = round(pl.y) + 8;
                for (var m = 0; m < array_length(e.ring); m++) {
                    var s = e.ring[m];
                    var sp = Feel_SparklePos(s, cx, cy, t);
                    if (!sp.alive) continue;
                    draw_set_alpha(1);
                    draw_set_colour(UI_C_DARKEST);
                    var sx = floor(sp.x);
                    var sy = floor(sp.y);
                    draw_rectangle(sx - 1, sy - 1, sx + s.size, sy + s.size, false);   // a dark edge so it reads on a light floor
                    draw_set_colour(s.col);
                    draw_rectangle(sx, sy, sx + s.size - 1, sy + s.size - 1, false);
                }
                break;
        }
    }
    draw_set_alpha(a0);
    draw_set_colour(c0);
    MapFx_DrawPlayerSquash();
}

// The player while a step's squash is on: the sprite is drawn here (Player's own draw is off for those frames, see obj_player Step) in whole pixels, feet on the tile.
function MapFx_DrawPlayerSquash() {
    if (!instance_exists(obj_player)) return;
    var pl = instance_find(obj_player, 0);
    if (!variable_instance_exists(pl, "squash_on") || !pl.squash_on) return;
    var box = Feel_SquashBox(MapFx_Now() - pl.squash_start, Settings_ShakeOn(), 16);
    var spr = pl.sprite_index;
    if (!sprite_exists(spr)) return;
    draw_sprite_ext(spr, pl.image_index, round(pl.x) + box.dx, round(pl.y) + box.dy, box.w / sprite_get_width(spr), box.h / sprite_get_height(spr), 0, pl.image_blend, pl.image_alpha);
}

// A chest, barrel or card chest (an obj_interactable) was just opened: the lid is the top middle of the instance.
function MapFx_OpenedAt(_inst, _loot, _card) {
    if (!instance_exists(_inst)) return;
    MapFx_Opened(floor((_inst.bbox_left + _inst.bbox_right) / 2), _inst.bbox_top + 2, _loot, _card);
}
