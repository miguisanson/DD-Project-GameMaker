function CharacterCreate_Player(_class_id) {
    var ch = {};
    ch.is_player = true;
    ch.class_id = _class_id;
    ch.class_cfg = DB_PlayerClass(_class_id);

    ch.level = 1;
    ch.exp = 0;
    ch.exp_next = Exp_NextLevel(ch.level);

    ch.stats = StatsCreateBase();
    // apply class bonus
    ch.stats.str  += ch.class_cfg.bonus.str;
    ch.stats.agi  += ch.class_cfg.bonus.agi;
    ch.stats.def  += ch.class_cfg.bonus.def;
    ch.stats.intt += ch.class_cfg.bonus.intt;
    ch.stats.luck += ch.class_cfg.bonus.luck;
    ch.stats = StatsClampAll(ch.stats);

    ch.hp = 9999; // temp; will clamp after compute
    ch.mp = 9999;

    ch = RecomputeResources(ch);

    // inventory/equip (later sections)
    ch.inventory = [];
    ch.equip = { weapon: 0, head: 0, body: 0, ring1: 0, ring2: 0 };
    ch.skills = Player_DefaultSkills(_class_id);
    ch.stat_points = 0;
    ch.status = [];
    ch.inventory = Inv_Add(ch.inventory, 10, 2);
    ch = Player_NormalizeProgression(ch, true);

    return ch;
}

function Player_DefaultSkills(_class_id) {
    return [];
}

function Difficulty_Normalize(_difficulty) {
    var d = round(GameSettings_ToReal(_difficulty, DIFFICULTY_NORMAL));
    return clamp(d, DIFFICULTY_EASY, DIFFICULTY_HARD);
}

function Difficulty_GetCurrent() {
    if (variable_global_exists("state") && is_struct(global.state) && variable_struct_exists(global.state, "difficulty")) {
        return Difficulty_Normalize(global.state.difficulty);
    }
    return DIFFICULTY_NORMAL;
}

function Difficulty_Label(_difficulty = -1) {
    var d = _difficulty;
    if (argument_count <= 0 || d == -1) d = Difficulty_GetCurrent();
    d = Difficulty_Normalize(d);
    switch (d) {
        case DIFFICULTY_EASY: return "Easy";
        case DIFFICULTY_HARD: return "Hard";
        default: return "Normal";
    }
}

function Difficulty_Profile(_difficulty = -1) {
    var d = _difficulty;
    if (argument_count <= 0 || d == -1) d = Difficulty_GetCurrent();
    d = Difficulty_Normalize(d);

    switch (d) {
        case DIFFICULTY_EASY:
            return {
                id: DIFFICULTY_EASY,
                player_stat_mult: 1.00,
                enemy_stat_mult: 1.00,
                player_hp_mult: 1.15,
                player_mp_mult: 1.05,
                enemy_hp_mult: 0.90,
                enemy_mp_mult: 0.95,
                player_damage_mult: 1.08,
                enemy_damage_mult: 0.90,
                enemy_status_chance_mult: 0.90,
                player_exp_mult: 1.20
            };
        case DIFFICULTY_HARD:
            return {
                id: DIFFICULTY_HARD,
                player_stat_mult: 1.00,
                enemy_stat_mult: 1.00,
                player_hp_mult: 0.92,
                player_mp_mult: 0.95,
                enemy_hp_mult: 1.12,
                enemy_mp_mult: 1.00,
                player_damage_mult: 0.94,
                enemy_damage_mult: 1.12,
                enemy_status_chance_mult: 1.08,
                player_exp_mult: 0.85
            };
        default:
            return {
                id: DIFFICULTY_NORMAL,
                player_stat_mult: 1.00,
                enemy_stat_mult: 1.00,
                player_hp_mult: 1.00,
                player_mp_mult: 1.00,
                enemy_hp_mult: 1.00,
                enemy_mp_mult: 1.00,
                player_damage_mult: 1.00,
                enemy_damage_mult: 1.00,
                enemy_status_chance_mult: 1.00,
                player_exp_mult: 1.00
            };
    }
}

function Difficulty_SetCurrent(_difficulty) {
    var gs = GameState_Get();
    gs.difficulty = Difficulty_Normalize(_difficulty);
    global.difficulty = gs.difficulty;
    return gs.difficulty;
}

function Player_EnsureSpriteSet() {
    if (!variable_instance_exists(id, "sprite") || !is_array(sprite) || array_length(sprite) < 4) {
        sprite = array_create(4, sprite_index);
    }

    if (sprite[RIGHT] == noone) sprite[RIGHT] = sprite_index;
    if (sprite[LEFT] == noone) sprite[LEFT] = sprite_index;
    if (sprite[UP] == noone) sprite[UP] = sprite_index;
    if (sprite[DOWN] == noone) sprite[DOWN] = sprite_index;
}

function Player_ApplyClassSprites(_class_id) {
    Player_EnsureSpriteSet();

    var cfg = DB_PlayerClass(_class_id);
    if (is_struct(cfg) && variable_struct_exists(cfg, "sprites")) {
        var s = cfg.sprites;
        if (is_struct(s)) {
            if (variable_struct_exists(s, "right") && s.right != noone) sprite[RIGHT] = s.right;
            if (variable_struct_exists(s, "left") && s.left != noone) sprite[LEFT] = s.left;
            if (variable_struct_exists(s, "up") && s.up != noone) sprite[UP] = s.up;
            if (variable_struct_exists(s, "down") && s.down != noone) sprite[DOWN] = s.down;
        }
    }
}


function Player_IsSettled(_pl) {
    if (!instance_exists(_pl)) return false;
    if (variable_instance_exists(_pl, "auto_resolve_recover_timer") && _pl.auto_resolve_recover_timer > 0) return false;
    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = _pl.tile_size;
    var gx = round(_pl.x / tile) * tile;
    var gy = round(_pl.y / tile) * tile;
    if (abs(_pl.x - gx) > 0.01 || abs(_pl.y - gy) > 0.01) return false;
    if (variable_instance_exists(_pl, "move_timer") && _pl.move_timer > 0) return false;
    return true;
}

function Player_CanAcceptMove(_pl) {
    if (!instance_exists(_pl)) return false;
    if (variable_instance_exists(_pl, "auto_resolve_recover_timer") && _pl.auto_resolve_recover_timer > 0) return false;
    if (variable_instance_exists(_pl, "moving") && _pl.moving) return false;
    if (variable_instance_exists(_pl, "move_timer") && _pl.move_timer > 0) return false;
    return true;
}

function Player_StartAutoResolveRecover(_pl, _recover_frames = ENEMY_AUTO_RESOLVE_RECOVER_FRAMES, _apply_battle_cooldown = true) {
    if (!instance_exists(_pl)) return;

    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = max(1, round(real(_pl.tile_size)));
    var gx = round(_pl.x / tile) * tile;
    var gy = round(_pl.y / tile) * tile;
    var frames = max(0, round(real(_recover_frames)));

    if (variable_instance_exists(_pl, "moving")) _pl.moving = false;
    if (variable_instance_exists(_pl, "move_timer")) _pl.move_timer = 0;
    if (variable_instance_exists(_pl, "move_dir")) _pl.move_dir = -1;
    if (variable_instance_exists(_pl, "xspeed")) _pl.xspeed = 0;
    if (variable_instance_exists(_pl, "yspeed")) _pl.yspeed = 0;

    var needs_settle = (abs(_pl.x - gx) > 0.01 || abs(_pl.y - gy) > 0.01);
    if (!needs_settle || frames <= 0) {
        _pl.x = gx;
        _pl.y = gy;
        if (variable_instance_exists(_pl, "auto_resolve_recover_timer")) _pl.auto_resolve_recover_timer = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_total")) _pl.auto_resolve_recover_total = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_progress")) _pl.auto_resolve_recover_progress = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_x")) _pl.auto_resolve_recover_start_x = gx;
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_y")) _pl.auto_resolve_recover_start_y = gy;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_x")) _pl.auto_resolve_recover_target_x = gx;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_y")) _pl.auto_resolve_recover_target_y = gy;
    } else {
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_x")) _pl.auto_resolve_recover_start_x = _pl.x;
        if (variable_instance_exists(_pl, "auto_resolve_recover_start_y")) _pl.auto_resolve_recover_start_y = _pl.y;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_x")) _pl.auto_resolve_recover_target_x = gx;
        if (variable_instance_exists(_pl, "auto_resolve_recover_target_y")) _pl.auto_resolve_recover_target_y = gy;
        if (variable_instance_exists(_pl, "auto_resolve_recover_total")) _pl.auto_resolve_recover_total = frames;
        if (variable_instance_exists(_pl, "auto_resolve_recover_progress")) _pl.auto_resolve_recover_progress = 0;
        if (variable_instance_exists(_pl, "auto_resolve_recover_timer")) _pl.auto_resolve_recover_timer = frames;
    }

    if (_apply_battle_cooldown && variable_instance_exists(_pl, "battle_cooldown")) {
        _pl.battle_cooldown = max(_pl.battle_cooldown, BATTLE_COOLDOWN_FRAMES);
    }
}

function Player_EnsureDialogueSettle(_pl, _recover_frames = PLAYER_DIALOGUE_SETTLE_FRAMES) {
    if (!instance_exists(_pl)) return;
    if (variable_instance_exists(_pl, "auto_resolve_recover_timer") && _pl.auto_resolve_recover_timer > 0) return;

    var tile = GRID_TILE_SIZE;
    if (variable_instance_exists(_pl, "tile_size")) tile = max(1, round(real(_pl.tile_size)));
    var gx = round(_pl.x / tile) * tile;
    var gy = round(_pl.y / tile) * tile;
    if (abs(_pl.x - gx) <= 0.01 && abs(_pl.y - gy) <= 0.01) return;

    Player_StartAutoResolveRecover(_pl, _recover_frames, false);
}


function UI_IsBlocking() {
    if (Transition_IsInputLocked()) return true;
    var gs = GameState_Get();
    if (gs.ui.mode != UI_NONE) return true;
    if (array_length(gs.ui.lines) > 0) return true;
    return false;
}

function UI_SetFont() {
    draw_set_font(UI_FONT);
}

function UI_PopupFadeAlpha(_opened_frame, _target_alpha = 1, _fade_frames = UI_POPUP_FADE_FRAMES) {
    var target = clamp(real(_target_alpha), 0, 1);
    var frames = max(1, round(real(_fade_frames)));
    if (!is_real(_opened_frame) || _opened_frame < 0) return target;
    var age = max(0, Input_Frame() - _opened_frame);
    return target * clamp(age / frames, 0, 1);
}

function UI_PopupAlpha(_opened_frame, _closing = false, _close_frame = UI_OPENED_FRAME_NONE, _target_alpha = 1, _fade_frames = UI_POPUP_FADE_FRAMES) {
    var a = UI_PopupFadeAlpha(_opened_frame, _target_alpha, _fade_frames);
    if (_closing) {
        var frames = max(1, round(real(_fade_frames)));
        var cf = is_real(_close_frame) ? _close_frame : Input_Frame();
        var t = clamp((Input_Frame() - cf) / frames, 0, 1);
        a *= (1 - t);
    }
    return clamp(a, 0, 1);
}

function UI_ModalRootEnsure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "modal_root")) {
        gs.ui.modal_root = {
            active: false,
            owner: "",
            opened_frame: UI_OPENED_FRAME_NONE,
            closing: false,
            close_frame: UI_OPENED_FRAME_NONE,
            hold_until_transition: false
        };
    }
    return gs.ui.modal_root;
}

function UI_ModalRootBegin(_owner = "") {
    var gs = GameState_Get();
    var root = UI_ModalRootEnsure();
    if (!root.active) {
        root.active = true;
        root.opened_frame = Input_Frame();
    }
    root.owner = string(_owner);
    root.closing = false;
    root.close_frame = UI_OPENED_FRAME_NONE;
    root.hold_until_transition = false;
    gs.ui.modal_root = root;
}

function UI_ModalRootTransfer(_owner = "") {
    var gs = GameState_Get();
    var root = UI_ModalRootEnsure();
    if (!root.active) {
        UI_ModalRootBegin(_owner);
        return;
    }
    root.owner = string(_owner);
    root.closing = false;
    root.close_frame = UI_OPENED_FRAME_NONE;
    root.hold_until_transition = false;
    gs.ui.modal_root = root;
}

function UI_ModalRootEnd(_hold_until_transition = false, _immediate = false) {
    var gs = GameState_Get();
    var root = UI_ModalRootEnsure();
    if (!root.active) return;

    if (_immediate) {
        root.active = false;
        root.owner = "";
        root.opened_frame = UI_OPENED_FRAME_NONE;
        root.closing = false;
        root.close_frame = UI_OPENED_FRAME_NONE;
        root.hold_until_transition = false;
        gs.ui.modal_root = root;
        return;
    }

    if (_hold_until_transition) {
        root.closing = false;
        root.close_frame = UI_OPENED_FRAME_NONE;
        root.hold_until_transition = true;
        gs.ui.modal_root = root;
        return;
    }

    if (root.closing) return;
    root.closing = true;
    root.close_frame = Input_Frame();
    root.hold_until_transition = false;
    gs.ui.modal_root = root;
}

function UI_UpdateModalDimState() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) gs.ui = {};
    if (!variable_struct_exists(gs.ui, "modal_dim_alpha")) gs.ui.modal_dim_alpha = 0;

    var root = UI_ModalRootEnsure();
    var alpha = 0;

    if (root.active) {
        if (root.hold_until_transition) {
            alpha = 0.6;
            if (Transition_IsActive()) {
                root.active = false;
                root.owner = "";
                root.opened_frame = UI_OPENED_FRAME_NONE;
                root.closing = false;
                root.close_frame = UI_OPENED_FRAME_NONE;
                root.hold_until_transition = false;
                alpha = 0;
            }
        } else if (root.closing) {
            alpha = UI_PopupAlpha(root.opened_frame, true, root.close_frame, 1) * 0.6;
            if (Input_Frame() - root.close_frame >= UI_POPUP_FADE_FRAMES) {
                root.active = false;
                root.owner = "";
                root.opened_frame = UI_OPENED_FRAME_NONE;
                root.closing = false;
                root.close_frame = UI_OPENED_FRAME_NONE;
                root.hold_until_transition = false;
                alpha = 0;
            }
        } else {
            alpha = UI_PopupAlpha(root.opened_frame, false, UI_OPENED_FRAME_NONE, 1) * 0.6;
        }
    }

    gs.ui.modal_root = root;
    gs.ui.modal_dim_alpha = alpha;
    return alpha;
}

function UI_DrawModalDim() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "ui")) return;
    var alpha = 0;
    if (variable_struct_exists(gs.ui, "modal_dim_alpha")) alpha = real(gs.ui.modal_dim_alpha);
    if (alpha <= 0) return;

    var w = display_get_gui_width();
    var h = display_get_gui_height();
    draw_set_alpha(alpha);
    draw_set_color(c_black);
    draw_rectangle(0, 0, w, h, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function Action_CanAct(_pl) {
    if (UI_IsBlocking()) return false;
    return Player_CanAcceptMove(_pl);
}

function Action_KeyPressed(_pl, _action) {
    if (!Action_CanAct(_pl)) return false;
    return Input_Pressed(_action);
}

function Action_Request(_pl, _action) {
    var gs = GameState_Get();

    // UI open means input is blocked.
    if (gs.ui.mode != UI_NONE || array_length(gs.ui.lines) > 0) {
        return false;
    }

    // Only allow discrete press when the player can act.
    if (!Player_CanAcceptMove(_pl)) {
        return false;
    }

    return Input_Pressed(_action);
}

function GameSettings_ToReal(_value, _fallback) {
    if (is_real(_value)) return _value;
    if (is_string(_value)) return real(_value);
    if (_value == true) return 1;
    if (_value == false) return 0;
    return _fallback;
}

function GameSettings_Defaults() {
    return {
        audio_ui: VOL_UI_DEFAULT,
        audio_sfx: VOL_SFX_DEFAULT,
        audio_bgm: VOL_MUSIC_DEFAULT,
        display_scale: DISPLAY_SCALE_DEFAULT,
        fit_screen: true
    };
}

function GameSettings_Normalize(_settings) {
    var out = GameSettings_Defaults();
    if (is_struct(_settings)) {
        if (variable_struct_exists(_settings, "audio_ui")) out.audio_ui = _settings.audio_ui;
        if (variable_struct_exists(_settings, "audio_sfx")) out.audio_sfx = _settings.audio_sfx;
        if (variable_struct_exists(_settings, "audio_bgm")) out.audio_bgm = _settings.audio_bgm;
        if (variable_struct_exists(_settings, "display_scale")) out.display_scale = _settings.display_scale;
        if (variable_struct_exists(_settings, "fit_screen")) out.fit_screen = _settings.fit_screen;
    }

    out.audio_ui = clamp(GameSettings_ToReal(out.audio_ui, VOL_UI_DEFAULT), 0, 1);
    out.audio_sfx = clamp(GameSettings_ToReal(out.audio_sfx, VOL_SFX_DEFAULT), 0, 1);
    out.audio_bgm = clamp(GameSettings_ToReal(out.audio_bgm, VOL_MUSIC_DEFAULT), 0, 1);
    out.display_scale = clamp(round(GameSettings_ToReal(out.display_scale, DISPLAY_SCALE_DEFAULT)), DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
    out.fit_screen = (GameSettings_ToReal(out.fit_screen, 1) != 0);
    if (DISPLAY_FORCE_FIT_SCREEN != 0) out.fit_screen = true;
    return out;
}

function GameSettings_Copy(_settings) {
    return GameSettings_Normalize(_settings);
}

function GameSettings_Ensure() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "settings") || !is_struct(gs.settings)) {
        gs.settings = GameSettings_Defaults();
    }
    gs.settings = GameSettings_Normalize(gs.settings);
    return gs.settings;
}

function GameSettings_ApplyAudio() {
    var settings = GameSettings_Ensure();
    Audio_SetUIVolume(settings.audio_ui);
    Audio_SetSFXVolume(settings.audio_sfx);
    Audio_SetMusicVolume(settings.audio_bgm);
}

function GameSettings_ApplyDisplay() {
    var settings = GameSettings_Ensure();
    var base_w = DISPLAY_BASE_W;
    var base_h = DISPLAY_BASE_H;

    var scale_fixed = clamp(round(GameSettings_ToReal(settings.display_scale, DISPLAY_SCALE_DEFAULT)), DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
    settings.display_scale = scale_fixed;
    var fit_screen = settings.fit_screen;

    // This project does not use a manual application surface pipeline.
    application_surface_draw_enable(true);
    if (!variable_global_exists("display_texfilter_init") || !global.display_texfilter_init) {
        gpu_set_texfilter(false);
        global.display_texfilter_init = true;
    }

    var port_x = 0;
    var port_y = 0;
    var port_w = base_w;
    var port_h = base_h;

    if (fit_screen) {
        var disp_w = max(1, display_get_width());
        var disp_h = max(1, display_get_height());

        if (window_get_width() != disp_w || window_get_height() != disp_h) {
            window_set_size(disp_w, disp_h);
        }
        if (window_get_x() != 0 || window_get_y() != 0) {
            window_set_position(0, 0);
        }

        var fit_scale = min(disp_w / base_w, disp_h / base_h);
        var scale_i = max(1, floor(fit_scale));
        port_w = base_w * scale_i;
        port_h = base_h * scale_i;
        port_x = floor((disp_w - port_w) * 0.5);
        port_y = floor((disp_h - port_h) * 0.5);
    } else {
        var win_w = base_w * scale_fixed;
        var win_h = base_h * scale_fixed;
        if (window_get_width() != win_w || window_get_height() != win_h) {
            window_set_size(win_w, win_h);
            window_center();
        }

        var target_w = max(1, window_get_width());
        var target_h = max(1, window_get_height());
        var used_scale = scale_fixed;

        port_w = max(1, round(base_w * used_scale));
        port_h = max(1, round(base_h * used_scale));
        if (port_w > target_w) port_w = target_w;
        if (port_h > target_h) port_h = target_h;
        port_x = floor((target_w - port_w) * 0.5);
        port_y = floor((target_h - port_h) * 0.5);
    }

    if (view_enabled) {
        view_visible[0] = true;
        view_xport[0] = port_x;
        view_yport[0] = port_y;
        view_wport[0] = port_w;
        view_hport[0] = port_h;
    }

    var cam = view_camera[0];
    if (!is_undefined(cam) && cam != -1) {
        camera_set_view_size(cam, base_w, base_h);
    }
}

function GameSettings_ApplyAll() {
    GameSettings_ApplyAudio();
    GameSettings_ApplyDisplay();
}

function GameSettings_Commit(_settings, _save_config = false) {
    var gs = GameState_Get();
    gs.settings = GameSettings_Normalize(_settings);
    GameState_SyncLegacy();
    GameSettings_ApplyAll();
    if (_save_config) {
        Save_WriteSettingsConfig(gs.settings);
    }
    return gs.settings;
}

function GameSettings_SetUIVolume(_v) {
    var settings = GameSettings_Ensure();
    settings.audio_ui = clamp(GameSettings_ToReal(_v, settings.audio_ui), 0, 1);
    GameSettings_ApplyAudio();
}

function GameSettings_SetSFXVolume(_v) {
    var settings = GameSettings_Ensure();
    settings.audio_sfx = clamp(GameSettings_ToReal(_v, settings.audio_sfx), 0, 1);
    GameSettings_ApplyAudio();
}

function GameSettings_SetBGMVolume(_v) {
    var settings = GameSettings_Ensure();
    settings.audio_bgm = clamp(GameSettings_ToReal(_v, settings.audio_bgm), 0, 1);
    GameSettings_ApplyAudio();
}

function GameSettings_SetScale(_scale) {
    var settings = GameSettings_Ensure();
    settings.display_scale = clamp(round(GameSettings_ToReal(_scale, settings.display_scale)), DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
    GameSettings_ApplyDisplay();
}

// --------------------
// GAME STATE
// --------------------
function GameState_Init() {
    if (!variable_global_exists("state") || !is_struct(global.state)) {
        global.state = {};
    }

    var gs = global.state;

    Input_Init();

    if (!variable_global_exists("rng_inited") || !global.rng_inited) {
        randomize();
        global.rng_inited = true;
    }

    if (!variable_struct_exists(gs, "selected_class")) {
        gs.selected_class = CLASS_NOBODY;
    }

    if (!variable_struct_exists(gs, "difficulty")) {
        gs.difficulty = DIFFICULTY_NORMAL;
    }
    gs.difficulty = Difficulty_Normalize(gs.difficulty);

    if (!variable_struct_exists(gs, "defeated_enemies")) {
        gs.defeated_enemies = ds_list_create();
    }

    if (!variable_struct_exists(gs, "uid_counter")) {
        gs.uid_counter = 1;
    }

    if (!variable_struct_exists(gs, "item_db")) {
        ItemDB_Init();
        gs.item_db = global.item_db;
    }

    if (!variable_struct_exists(gs, "player_ch")) {
        gs.player_ch = CharacterCreate_Player(gs.selected_class);
    }
    if (is_struct(gs.player_ch)) {
        if (!variable_struct_exists(gs.player_ch, "class_id")) gs.player_ch.class_id = gs.selected_class;
        gs.player_ch = Player_NormalizeProgression(gs.player_ch, true);
        gs.selected_class = gs.player_ch.class_id;
    }

    if (!variable_struct_exists(gs, "enemy_db")) {
        EnemyDB_Init();
        gs.enemy_db = global.enemy_db;
    }

    if (!variable_struct_exists(gs, "skill_db")) {
        SkillDB_Init();
        gs.skill_db = global.skill_db;
    }

    if (!variable_struct_exists(gs, "status_db")) {
        StatusDB_Init();
        gs.status_db = global.status_db;
    }

    if (!variable_struct_exists(gs, "dialogue_db")) {
        DialogueDB_Init();
        gs.dialogue_db = global.dialogue_db;
    }

    if (!variable_struct_exists(gs, "enemy_reset_version")) {
        gs.enemy_reset_version = 0;
    }

    if (!variable_struct_exists(gs, "boss_defeated") || !is_struct(gs.boss_defeated)) {
        gs.boss_defeated = { mini_boss: false, final_boss: false };
    }

    if (!variable_struct_exists(gs, "loot_tables")) {
        Loot_Init();
        gs.loot_tables = global.loot_tables;
        gs.loot_configs = global.loot_configs;
        gs.loot_tier_weights = global.loot_tier_weights;
    }


    if (!variable_struct_exists(gs, "battle")) {
        gs.battle = {
            return_room: noone,
            return_x: 0,
            return_y: 0,
            enemy_persist_id: "",
            enemy_id: -1,
            enemy_level: 0,
            enemy_room: noone,
            just_returned: false
        };
    }
    if (!variable_struct_exists(gs.battle, "enemy_level")) gs.battle.enemy_level = 0;

    if (!variable_struct_exists(gs, "player_inst")) {
        gs.player_inst = noone;
    }

    if (!variable_struct_exists(gs, "flags")) {
        gs.flags = {};
    }

    if (!variable_struct_exists(gs, "save_slot")) {
        gs.save_slot = 0;
    }

    if (!variable_struct_exists(gs, "skip_room_save")) {
        gs.skip_room_save = false;
    }

    if (!variable_struct_exists(gs, "checkpoint")) {
        gs.checkpoint = { room: rm_floor2, x: 32, y: 128 };
    }

    if (!variable_struct_exists(gs, "settings") || !is_struct(gs.settings)) {
        gs.settings = GameSettings_Defaults();
    }
    if (!variable_struct_exists(gs, "settings_boot_loaded") || !gs.settings_boot_loaded) {
        var boot_settings = Save_LoadLatestSettings();
        if (is_struct(boot_settings)) gs.settings = boot_settings;
        gs.settings_boot_loaded = true;
    }
    gs.settings = GameSettings_Normalize(gs.settings);

    if (!variable_struct_exists(gs, "ui")) {
        gs.ui = {
            mode: 0,
            lines: [],
            lines_raw: [],
            index: 0,
            speaker: "",
            cutscene_text_only: false,
            confirm_action: "",
            icon_frame: 0,
            opened_frame: UI_OPENED_FRAME_NONE,
            dialogue_lock: 0,
            dialogue_require_release: false,
            dialogue_full_text: "",
            dialogue_visible_count: 0,
            dialogue_reveal_accum: 0,
            dialogue_chars_per_sec: UI_DIALOGUE_CHARS_PER_SEC,
            dialogue_state: UI_DIALOGUE_STATE_REVEALING,
            dialogue_hold_frames: 0,
            dialogue_hold_duration: 0,
            dialogue_tw_line_index: -1,
            dialogue_open_block_frame: UI_OPENED_FRAME_NONE
        };
    }
    if (!variable_struct_exists(gs.ui, "opened_frame")) gs.ui.opened_frame = UI_OPENED_FRAME_NONE;
    if (!variable_struct_exists(gs.ui, "dialogue_lock")) gs.ui.dialogue_lock = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_require_release")) gs.ui.dialogue_require_release = false;
    if (!variable_struct_exists(gs.ui, "dialogue_full_text")) gs.ui.dialogue_full_text = "";
    if (!variable_struct_exists(gs.ui, "dialogue_visible_count")) gs.ui.dialogue_visible_count = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_reveal_accum")) gs.ui.dialogue_reveal_accum = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_chars_per_sec")) gs.ui.dialogue_chars_per_sec = UI_DIALOGUE_CHARS_PER_SEC;
    if (!variable_struct_exists(gs.ui, "dialogue_state")) gs.ui.dialogue_state = UI_DIALOGUE_STATE_REVEALING;
    if (!variable_struct_exists(gs.ui, "dialogue_hold_frames")) gs.ui.dialogue_hold_frames = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_hold_duration")) gs.ui.dialogue_hold_duration = 0;
    if (!variable_struct_exists(gs.ui, "dialogue_tw_line_index")) gs.ui.dialogue_tw_line_index = -1;
    if (!variable_struct_exists(gs.ui, "dialogue_open_block_frame")) gs.ui.dialogue_open_block_frame = UI_OPENED_FRAME_NONE;
    if (!variable_struct_exists(gs.ui, "lines_raw") || !is_array(gs.ui.lines_raw)) gs.ui.lines_raw = [];
    if (!variable_struct_exists(gs.ui, "cutscene_text_only")) gs.ui.cutscene_text_only = false;

    if (!variable_struct_exists(gs, "in_main_menu")) {
        gs.in_main_menu = false;
    }

    if (!variable_struct_exists(gs, "pending_cutscene_id")) {
        gs.pending_cutscene_id = "";
    }
    if (!variable_struct_exists(gs, "pending_post_battle_dialogue_lines") || !is_array(gs.pending_post_battle_dialogue_lines)) {
        gs.pending_post_battle_dialogue_lines = [];
    }

    if (!variable_struct_exists(gs, "transition")) {
        gs.transition = { pending: false, room: noone, spawn_id: "", face: -1 };
    }

    if (!variable_struct_exists(gs, "room_states")) {
        gs.room_states = {};
    }

    RoomDB_Init();

    if (!variable_struct_exists(gs, "last_room")) {
        gs.last_room = room;
    }

    RoomState_Init();

    GameState_SyncLegacy();

    return gs;
}

function GameState_Get() {
    if (!variable_global_exists("state") || !is_struct(global.state)) {
        return GameState_Init();
    }

    return global.state;
}

function GameState_NextUID() {
    var gs = GameState_Get();
    if (!variable_struct_exists(gs, "uid_counter")) gs.uid_counter = 1;
    var uid = gs.uid_counter;
    gs.uid_counter += 1;
    return uid;
}

function GameState_SyncLegacy() {
    var gs = global.state;

    Input_Init();

    global.selected_class = gs.selected_class;
    global.difficulty = gs.difficulty;
    global.defeated_enemies = gs.defeated_enemies;
    global.player_ch = gs.player_ch;

    if (variable_struct_exists(gs, "item_db")) {
        global.item_db = gs.item_db;
    }

    if (variable_struct_exists(gs, "enemy_db")) {
        global.enemy_db = gs.enemy_db;
    }

    if (variable_struct_exists(gs, "skill_db")) {
        global.skill_db = gs.skill_db;
    }

    if (variable_struct_exists(gs, "status_db")) {
        global.status_db = gs.status_db;
    }

    if (variable_struct_exists(gs, "dialogue_db")) {
        global.dialogue_db = gs.dialogue_db;
    }


    if (variable_struct_exists(gs, "battle")) {
        global.battle_return_room = gs.battle.return_room;
        global.battle_return_x = gs.battle.return_x;
        global.battle_return_y = gs.battle.return_y;
        global.battle_enemy_persist_id = gs.battle.enemy_persist_id;
        global.battle_enemy_id = gs.battle.enemy_id;
        global.battle_enemy_level = gs.battle.enemy_level;
        global.battle_enemy_room = gs.battle.enemy_room;
        global.just_returned_from_battle = gs.battle.just_returned;
    }

    if (variable_struct_exists(gs, "uid_counter")) {
        global.uid_counter = gs.uid_counter;
    }

    if (variable_struct_exists(gs, "settings")) {
        global.settings = gs.settings;
    }

    global.player_inst = gs.player_inst;
}

function GameState_SetSelectedClass(_class_id) {
    var gs = GameState_Get();
    gs.selected_class = _class_id;
    global.selected_class = _class_id;
}

function GameState_SetPlayer(_ch) {
    if (is_struct(_ch)) _ch = Player_NormalizeProgression(_ch, true);
    var gs = GameState_Get();
    gs.player_ch = _ch;
    global.player_ch = _ch;
}

function GameState_SetPlayerInst(_inst) {
    var gs = GameState_Get();
    gs.player_inst = _inst;
    global.player_inst = _inst;
}

function GameState_SetBattleReturn(_room, _x, _y, _face, _snap_to_grid = true) {
    var gs = GameState_Get();
    if (_snap_to_grid) {
        var tile = GRID_TILE_SIZE;
        _x = round(_x / tile) * tile;
        _y = round(_y / tile) * tile;
    }
    gs.battle.return_room = _room;
    gs.battle.return_x = _x;
    gs.battle.return_y = _y;
    gs.battle.return_face = (argument_count >= 4) ? _face : -1;

    global.battle_return_room = _room;
    global.battle_return_x = _x;
    global.battle_return_y = _y;
    global.battle_return_face = gs.battle.return_face;
}

function GameState_SetBattleEnemy(_persist_id, _enemy_id, _enemy_level = 0) {
    var gs = GameState_Get();
    gs.battle.enemy_persist_id = _persist_id;
    gs.battle.enemy_id = _enemy_id;
    gs.battle.enemy_level = max(0, round(_enemy_level));
    gs.battle.enemy_room = room;

    global.battle_enemy_persist_id = _persist_id;
    global.battle_enemy_id = _enemy_id;
    global.battle_enemy_level = gs.battle.enemy_level;
    global.battle_enemy_room = room;

    if (Menu_IsOpen()) Menu_Close();
    if (PauseMenu_IsOpen()) PauseMenu_Close();
}

function GameState_SetJustReturned(_flag) {
    var gs = GameState_Get();
    gs.battle.just_returned = _flag;
    global.just_returned_from_battle = _flag;
}

function GameState_SetCheckpoint(_room, _x, _y) {
    var gs = GameState_Get();
    gs.checkpoint.room = _room;
    gs.checkpoint.x = _x;
    gs.checkpoint.y = _y;
}

function Player_LearnSkill(_ch, _skill_id) {
    if (!is_array(_ch.skills)) _ch.skills = [];
    var exists = false;
    for (var i = 0; i < array_length(_ch.skills); i++) {
        if (_ch.skills[i] == _skill_id) {
            exists = true;
            break;
        }
    }
    if (!exists) {
        array_push(_ch.skills, _skill_id);
    }
    return _ch;
}
