// Test harness hook (scr_test): does nothing unless the exe was started with -runtests.
Test_Boot();
// Create globals once (safe in any room)
GameState_Init();
SFX_EnsureManager();
