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

    return ch;
}

function Player_DefaultSkills(_class_id) {
    switch (_class_id) {
        case CLASS_ARCHER: return [SKILL_WOUND, SKILL_TAKE_AIM];
        case CLASS_KNIGHT: return [SKILL_HORIZ_SLASH, SKILL_MUSCLE_UP];
        case CLASS_MAGE:   return [SKILL_FIREBALL, SKILL_MEDITATION];
    }
    return [SKILL_WOUND];
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
    var tile = 16;
    if (variable_instance_exists(_pl, "tile_size")) tile = _pl.tile_size;
    var gx = round(_pl.x / tile) * tile;
    var gy = round(_pl.y / tile) * tile;
    if (abs(_pl.x - gx) > 0.01 || abs(_pl.y - gy) > 0.01) return false;
    if (variable_instance_exists(_pl, "move_timer") && _pl.move_timer > 0) return false;
    return true;
}

function Player_CanAcceptMove(_pl) {
    if (!instance_exists(_pl)) return false;
    if (variable_instance_exists(_pl, "moving") && _pl.moving) return false;
    if (variable_instance_exists(_pl, "move_timer") && _pl.move_timer > 0) return false;
    return true;
}


function UI_IsBlocking() {
    var gs = GameState_Get();
    if (gs.ui.mode != UI_NONE) return true;
    if (array_length(gs.ui.lines) > 0) return true;
    return false;
}

function UI_SetFont() {
    draw_set_font(UI_FONT);
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
        fullscreen: false
    };
}

function GameSettings_Normalize(_settings) {
    var out = GameSettings_Defaults();
    if (is_struct(_settings)) {
        if (variable_struct_exists(_settings, "audio_ui")) out.audio_ui = _settings.audio_ui;
        if (variable_struct_exists(_settings, "audio_sfx")) out.audio_sfx = _settings.audio_sfx;
        if (variable_struct_exists(_settings, "audio_bgm")) out.audio_bgm = _settings.audio_bgm;
        if (variable_struct_exists(_settings, "display_scale")) out.display_scale = _settings.display_scale;
        if (variable_struct_exists(_settings, "fullscreen")) out.fullscreen = _settings.fullscreen;
    }

    out.audio_ui = clamp(GameSettings_ToReal(out.audio_ui, VOL_UI_DEFAULT), 0, 1);
    out.audio_sfx = clamp(GameSettings_ToReal(out.audio_sfx, VOL_SFX_DEFAULT), 0, 1);
    out.audio_bgm = clamp(GameSettings_ToReal(out.audio_bgm, VOL_MUSIC_DEFAULT), 0, 1);
    out.display_scale = clamp(round(GameSettings_ToReal(out.display_scale, DISPLAY_SCALE_DEFAULT)), DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX);
    out.fullscreen = (GameSettings_ToReal(out.fullscreen, 0) != 0);
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

    var is_fullscreen = settings.fullscreen;
    settings.fullscreen = is_fullscreen;

    // This project does not use a manual application surface pipeline.
    application_surface_draw_enable(true);

    if (window_get_fullscreen() != is_fullscreen) {
        window_set_fullscreen(is_fullscreen);
    }

    // Use the runtime fullscreen state after toggling. If OS switching is delayed by a frame,
    // this prevents applying fullscreen viewport math to a windowed backbuffer (clipping).
    var actual_fullscreen = window_get_fullscreen();

    if (!actual_fullscreen) {
        var win_w = base_w * scale_fixed;
        var win_h = base_h * scale_fixed;
        if (window_get_width() != win_w || window_get_height() != win_h) {
            window_set_size(win_w, win_h);
            window_center();
        }
    }

    var target_w = 0;
    var target_h = 0;
    if (actual_fullscreen) {
        target_w = max(1, display_get_width());
        target_h = max(1, display_get_height());
    } else {
        target_w = max(1, window_get_width());
        target_h = max(1, window_get_height());
    }

    var used_scale = scale_fixed;
    if (actual_fullscreen) {
        // Fullscreen letterbox fit: always show whole scene, preserve aspect ratio.
        var fit_scale = min(target_w / base_w, target_h / base_h);
        if (fit_scale < 0.01) fit_scale = 0.01;

        // Keep integer scale when it exactly fits; otherwise use full-fit scale to maximize visibility.
        var fit_int = floor(fit_scale);
        if (fit_int >= 1 && abs(fit_scale - fit_int) < 0.0001) {
            used_scale = fit_int;
        } else {
            used_scale = fit_scale;
        }
    }

    var port_w = max(1, round(base_w * used_scale));
    var port_h = max(1, round(base_h * used_scale));
    if (port_w > target_w) port_w = target_w;
    if (port_h > target_h) port_h = target_h;
    var port_x = 0;
    var port_y = 0;
    port_x = floor((target_w - port_w) * 0.5);
    port_y = floor((target_h - port_h) * 0.5);

    if (view_enabled) {
        view_visible[0] = true;
        view_xport[0] = port_x;
        view_yport[0] = port_y;
        view_wport[0] = port_w;
        view_hport[0] = port_h;
        view_wview[0] = base_w;
        view_hview[0] = base_h;
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

function GameSettings_SetFullscreen(_enabled) {
    var settings = GameSettings_Ensure();
    settings.fullscreen = (_enabled == true) || (_enabled == 1);
    GameSettings_ApplyDisplay();
}

function GameSettings_ToggleFullscreen() {
    var settings = GameSettings_Ensure();
    GameSettings_SetFullscreen(!settings.fullscreen);
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
        gs.selected_class = CLASS_ARCHER;
    }

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
            enemy_room: noone,
            just_returned: false
        };
    }

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
        gs.ui = { mode: 0, lines: [], index: 0, speaker: "", just_opened: false, lock_actions: 0, confirm_action: "", icon_frame: 0 };
    }

    if (!variable_struct_exists(gs, "in_main_menu")) {
        gs.in_main_menu = false;
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
    var gs = GameState_Get();
    gs.player_ch = _ch;
    global.player_ch = _ch;
}

function GameState_SetPlayerInst(_inst) {
    var gs = GameState_Get();
    gs.player_inst = _inst;
    global.player_inst = _inst;
}

function GameState_SetBattleReturn(_room, _x, _y, _face) {
    var gs = GameState_Get();
    var tile = 16;
    _x = round(_x / tile) * tile;
    _y = round(_y / tile) * tile;
    gs.battle.return_room = _room;
    gs.battle.return_x = _x;
    gs.battle.return_y = _y;
    gs.battle.return_face = (argument_count >= 4) ? _face : -1;

    global.battle_return_room = _room;
    global.battle_return_x = _x;
    global.battle_return_y = _y;
    global.battle_return_face = gs.battle.return_face;
}

function GameState_SetBattleEnemy(_persist_id, _enemy_id) {
    var gs = GameState_Get();
    gs.battle.enemy_persist_id = _persist_id;
    gs.battle.enemy_id = _enemy_id;
    gs.battle.enemy_room = room;

    global.battle_enemy_persist_id = _persist_id;
    global.battle_enemy_id = _enemy_id;
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
    if (array_index_of(_ch.skills, _skill_id) == -1) {
        array_push(_ch.skills, _skill_id);
    }
    return _ch;
}
