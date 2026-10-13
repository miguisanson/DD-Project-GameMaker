# tools/automation

`run_tests.ps1` is the gate wrapper: headless Igor build plus game test runs.
Background and the proven commands: `.planning/research/automation-igor.md`.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\automation\run_tests.ps1 [-Mode fast|full|compile] [-Only runtests|smoke|bot|shots] [-NegativeControl]
```

| Mode | What runs |
|---|---|
| `compile` | Build only (about 15 s). Catches syntax errors, not unknown functions. |
| `fast` (default) | Build + `-runtests` (timeout 30 s). |
| `full` | `fast` + `-smoke` (60 s) + `-bot` (120 s) + `-shots` (60 s). |

`-Only <mode>` runs just that game mode after the build (e.g. `-Mode full -Only smoke`).

Exit code: 0 = `GATE PASS`, 1 = `GATE FAIL`, 2 = refused to start (a work dir is on C:, or Igor/git missing).

Output is only FAIL/ERROR lines (plus `build id` and the `build=` line), one timing line per step, and the final GATE line.
Full logs: `E:\Temp\dd-gate\logs\build.log` and `<mode>.log`.

## How it works
- Copies the working tree (`git ls-files -co --exclude-standard`, so uncommitted edits are tested) into a fresh `E:\Temp\dd-gate\src`. Nothing is built inside the repo.
- Work dirs `src, cache, tmp, out, save, logs` all live under `-WorkRoot` (default `E:\Temp\dd-gate`). If any resolves to C: the script exits 2 before touching anything. `cache` and `tmp` are kept between runs; the rest are emptied.
- Games run with `LOCALAPPDATA` pointed at `...\save`. A hash of `%LOCALAPPDATA%\DD_Project` is taken before and after; any change is a FAIL. (If the owner plays the real game during a run, that also trips it.)
- `-runtests` passes only with: a `[TEST-SUMMARY] pass=N fail=0 errors=0` line (N > 0), no `UNHANDLED` / `CRASH` / `[TEST] ERROR` line, `test_results.txt` somewhere under the save dir, exit code 0, no timeout, and no `DD-Project` process left from this run (anything left is killed and counted as FAIL).
- `-NegativeControl` adds `-testcontrol` to the game, which should add a deliberately failing test. The expected result is `GATE FAIL`; run it whenever this script changes (VER-04).

## Game modes (in `scripts/scr_debug/scr_debug.gml`, inert without a flag)
- `-runtests`: assertion suites (`scr_test.gml`).
- `-smoke`: boots, then rm_start (logo, then the menu) -> rm_floor1 -> rm_battle for a fixed number of frames each. Any runtime error is `[TEST] ERROR UNHANDLED` + `CRASH` (Igor alone does not catch unknown functions).
- `-bot`: Knight vs Slime. "perfect" variant confirms the menu, times the attack drop and answers the defence arrows from the battle controller's own data and must win; "fail" variant never presses in a QTE and must end (or only the no-error and HP-bounds checks apply). 2000-frame cap for the perfect variant.
- `-shots`: `screen_save` of rm_start, rm_floor1 and rm_battle at display scales 3, 4, 5 (9 PNGs, copied to `<WorkRoot>\shots`). The wrapper checks file exists, PNG size = reported window size, and not more than 97% one colour. `fit_screen` is not captured.
- Build id: `#macro BUILD_ID "dev"` in the repo; the wrapper stamps `<git short hash>-<yyyyMMdd>[-dirty]` into the scratch copy only. The game prints `[TEST-BUILD] <id>`, the wrapper checks it, and the title screen draws it bottom-right.

## Focus, fullscreen, and the owner's PC
- **Do not run the gate while the owner is gaming or typing.** A run opens real game windows for up to a few minutes.
- Tests never take focus and never use a focus or foreground API. Game windows start minimized and not activated (`SW_SHOWMINNOACTIVE` through a small `CreateProcess` call; falls back to `Start-Process -WindowStyle Minimized` if that fails).
- Tests always run windowed: with any test flag the game calls `window_set_fullscreen(false)` at boot (and every frame in smoke, bot and shots), ignoring a saved fullscreen setting.
- The runner ignores `keyboard_key_press` while its window is not in front, so `-bot` does not use the keyboard. It writes the game's own input state: `Input_Update()` ends with `Scenario_InputOverride()`, a no-op unless `-bot`. The menu, the attack timing and the defence arrows read that state like a real key press.
- `-shots` has not yet been verified with a minimized window: run it when the owner is not using the PC and check the PNGs are not blank. If `screen_save` is blank when minimized, that needs a decision then.

## Adding a game mode
Edit the `$GameModes` table at the top of the script: set `Impl = $true` on the row (flag, timeout and strictness are in the same row).
