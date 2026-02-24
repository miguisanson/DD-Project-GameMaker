if (instance_number(obj_sfx_manager) > 1) {
    instance_destroy();
    exit;
}

var _settings = GameSettings_Ensure();
if (!variable_global_exists("vol_master")) global.vol_master = VOL_MASTER_DEFAULT;
if (!variable_global_exists("vol_ui")) global.vol_ui = VOL_UI_DEFAULT;
if (!variable_global_exists("vol_sfx")) global.vol_sfx = VOL_SFX_DEFAULT;
if (!variable_global_exists("vol_music")) global.vol_music = VOL_MUSIC_DEFAULT;
global.vol_ui = _settings.audio_ui;
global.vol_sfx = _settings.audio_sfx;
global.vol_music = _settings.audio_bgm;

global.bgm_current_sound = noone;
global.bgm_current_handle = -1;
global.bgm_current_key = "";
global.bgm_pending_stop_handle = -1;
global.bgm_pending_stop_frames = 0;
global.sfx_last_key = "";
global.sfx_last_handle = -1;
global.sfx_active = [];
global.audio_debug_enabled = false;
global.audio_debug_test_key = "ui_confirm";
global.audio_debug_last_key = global.audio_debug_test_key;
global.audio_debug_last_channel = -1;
global.audio_debug_last_status = "Audio debug OFF";
global.audio_debug_last_ok = false;
global.audio_debug_last_asset = noone;
global.audio_debug_last_asset_name = "";
global.audio_debug_last_reason = "";
global.audio_debug_direct_handle = -1;
global.audio_debug_direct_playing = false;
global.audio_debug_group_loaded = false;
global.audio_group_load_requested = false;
global.audio_debug_missing_count = 0;
global.audio_debug_total_count = 0;
global.audio_debug_map_report = [];
last_room_id = room;

if (variable_global_exists("sfx_db") && ds_exists(global.sfx_db, ds_type_map)) {
    ds_map_destroy(global.sfx_db);
}
if (variable_global_exists("bgm_db") && ds_exists(global.bgm_db, ds_type_map)) {
    ds_map_destroy(global.bgm_db);
}
if (variable_global_exists("sfx_gain_db") && ds_exists(global.sfx_gain_db, ds_type_map)) {
    ds_map_destroy(global.sfx_gain_db);
}
if (variable_global_exists("bgm_gain_db") && ds_exists(global.bgm_gain_db, ds_type_map)) {
    ds_map_destroy(global.bgm_gain_db);
}
global.sfx_db = ds_map_create();
global.bgm_db = ds_map_create();
global.sfx_gain_db = ds_map_create();
global.bgm_gain_db = ds_map_create();
SFX_RegisterDefaults();
BGM_RegisterDefaults();
var _audit = SFX_DebugAuditRequired(true);
global.audio_debug_missing_count = _audit.missing;
global.audio_debug_total_count = _audit.total;
SFX_ClampVolumes();
GameSettings_ApplyAll();

if (!audio_group_is_loaded(audiogroup_default)) {
    audio_group_load(audiogroup_default);
    global.audio_group_load_requested = true;
}
global.audio_debug_group_loaded = audio_group_is_loaded(audiogroup_default);
audio_resume_all();
BGM_ApplyForRoom(room);
