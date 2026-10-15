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
