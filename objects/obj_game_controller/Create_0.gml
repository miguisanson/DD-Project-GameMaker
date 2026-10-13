// Test harness hook (scr_test): does nothing unless the exe was started with -runtests.
Test_Boot();
// Scenario hook (scr_debug): does nothing unless started with -smoke / -bot / -shots.
Scenario_Boot();
// Create globals once (safe in any room)
GameState_Init();
SFX_EnsureManager();
