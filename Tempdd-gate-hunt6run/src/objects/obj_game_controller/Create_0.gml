// Test harness hook (scr_test): does nothing unless the exe was started with -runtests.
Test_Boot();
// Scenario hook (scr_debug): does nothing unless started with -smoke / -bot / -shots.
Scenario_Boot();
// Create globals once (safe in any room)
GameState_Init();
Display_Init();      // once per run: the display owner (scr_display); needs the settings GameState_Init loaded
Room_StampBump();    // every room start: layer scripts registered earlier belong to a room that is gone (I-056)
Display_BindRoom();  // every room start: the room's own view and camera replaced by the one design (scr_display)
SFX_EnsureManager();
