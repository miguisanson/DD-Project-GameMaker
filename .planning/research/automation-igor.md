# Headless build / run / test automation with Igor

Date: 2026-10-13. Author: research subagent (Sonnet). Repo state tested: branch `v1.8` at `0b6e2f8`.
No file in the repo was edited except this report. All scratch work is on `E:\Temp` (listed at the end).

## 1. Verdict (plain)

**A headless compile WORKED.** Igor builds the project from the command line in about 9-13 seconds, with no
login or licence prompt. The built game also **ran**, its `show_debug_message` output was captured to a file, and
it was killed with no leftover processes. A GML test runner, a battle "bot", an unhandled-error catcher and
screenshots at several window sizes were all proven in a scratch copy.

Two honest limits:

- "Headless" means no IDE. The game still opens a real window on the desktop for a few seconds (DirectX 11).
  It is not invisible and needs a logged-in screen.
- Only the **VM** (non-YYC) **Release** build was tried. YYC (needs Visual Studio build tools) and `--debug` were not tried.

AGENTS.md is out of date on this point. It says no runtime exists under `%APPDATA%\GameMakerStudio2\Cache\runtimes`.
The runtime is under `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260` (it includes `bin\igor\windows\x64\Igor.exe`).

## 2. Verified results (exact commands and outputs)

### 2.1 Paths found

| Thing | Path |
|---|---|
| Igor | `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\Igor.exe` |
| Runtime path | `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260` |
| User/licence folder | `%APPDATA%\GameMakerStudio2\qalp2122_3623108` (contains `licence.plist`, `local_settings.json`, `devices.json`) |
| Real save area (DO NOT TOUCH) | `%LOCALAPPDATA%\DD_Project` (holds the owner's `savedata0.sav`, `savedata1.sav`, `settings_config.json`) |

Warning: `%APPDATA%\GameMakerStudio2\um.json` contains live access/refresh tokens. Never print it, and the harness does not need it.
(I printed it once by accident while looking for the user folder. Nothing was copied or sent anywhere.)

### 2.2 Igor command line (from `Igor.exe` with a bad option, which prints usage)

Form: `Igor [OPTIONS]+ WORKER COMMAND`. The worker is lowercase `windows`. Commands for windows: `Run`, `PackageZip`,
`PackageNsis`, `PackageZipArm64`, `PackageNsisArm64`, `Clean`, `CleanCode`, `CleanGraphics`, `CleanAudio`, `Stop`, `Package`.
Useful options: `--project`, `--user`, `--runtimePath`, `--runtime=VM|YYC`, `--cache`, `--temp`, `--of` (output .win name),
`--tf` (target file, the zip), `-j` (cores), `--debug`, `-q`, `-v`, `--nobuild` (run a prebuilt version), `-t` (timeout), `--config`.
The manual page (manual.gamemaker.io ... Command_Line.htm) returned 403 to the fetch tool, so the Igor usage text above is the source.

### 2.3 Scratch copy

```
mkdir -p /e/Temp/dd-igor-test /e/Temp/dd-igor-cache /e/Temp/dd-igor-tmp /e/Temp/dd-igor-out
cd /e/Github_Projects/DD-Project-GameMaker && git archive v1.8 | tar -x -C /e/Temp/dd-igor-test
```

Result: 67 MB, 1339 tracked files. Igor wrote nothing into the project folder (only my deliberate edits showed up), so building
in place is probably safe too, but the copy costs about a second and removes the risk. Keep the copy.

### 2.4 Build that works (exit 0, about 9 s warm, 12.8 s cold)

```
IGOR="C:/ProgramData/GameMakerStudio2/Cache/runtimes/runtime-2024.14.3.260/bin/igor/windows/x64/Igor.exe"
USERF="$APPDATA/GameMakerStudio2/qalp2122_3623108"
RT="C:/ProgramData/GameMakerStudio2/Cache/runtimes/runtime-2024.14.3.260"
"$IGOR" -j=4 --project="E:/Temp/dd-igor-test/DD-Project.yyp" --user="$USERF" --runtimePath="$RT" --runtime=VM \
  --cache="E:/Temp/dd-igor-cache" --temp="E:/Temp/dd-igor-tmp" \
  --of="E:/Temp/dd-igor-out/DD-Project.win" --tf="E:/Temp/dd-igor-out/DD-Project.zip" -- windows PackageZip
```

Output ends with: `Stats : GMA : sp=133,au=81,bk=0,pt=0,sc=1318,sh=0,fo=1,tl=0,ob=65,ro=14,da=9,ex=0,ma=6 ...`, `Igor complete.`,
exit code 0. Produced in `dd-igor-out`: `DD-Project.exe` (7.9 MB), `data.win` (78 MB), `DD-Project.zip` (77 MB), `options.ini`, `fonts\`, `localization\`.
Log markers: "Compile Scripts...finished.", "Compile Objects...finished.", "Release build". No licence, login or sign-in message.

### 2.5 What failed first

The first attempt used `--of=...\DD-Project.zip` and no `--tf`. The compile succeeded (it wrote `data.win` and the exe) but the
packaging step died: `System.ArgumentException: The value cannot be an empty string. (Parameter 'destFileName') at Igor.WindowsBuilder.PackageZip()`,
exit 1. Fix: pass `--tf=<zip path>` as above. If you only want the exe and `data.win`, the build output is already usable after that error,
but treat exit 1 as a failure and use the fixed command.

### 2.6 Does the compile gate catch mistakes? (negative controls, in the scratch copy only)

| Mistake injected | Igor exit | Output |
|---|---|---|
| Syntax error appended to `scr_math.gml` (`function zz_broken( { var x = ; }`) | **1** | `Error : gml_GlobalScript_scr_math(3) : variable name expected` (plus 5 more lines, with script name and line) |
| Call to a function that does not exist (`no_such_function_xyz(1)`) | **0** | Nothing. GameMaker only fails this at runtime. |

So the compile gate catches syntax errors, but not unknown functions or variables. Those need a run. That is why the harness
below also has a smoke run and an error catcher.

### 2.7 Running the built game and capturing output

Three ways were tested.

1. **`Igor ... -- windows Run`** (builds and launches). It streams the game's `show_debug_message` output to stdout
   (for example `[SFX MAP] ui_confirm -> ...`). It does not stop on its own: `-t=20` did NOT end the game after 20 s.
   Wrapped in `timeout 40`, it was killed cleanly (exit 124, the log says Runner exited with status 143, no leftover processes).
   Killing only a bash subshell left `Igor.exe` and `Runner.exe` orphaned (I stopped them by name). Not recommended.
2. **Launching the built exe directly** (recommended):
   ```
   Start-Process -FilePath E:\Temp\dd-igor-out\DD-Project.exe -ArgumentList '-game','data.win','-runtests' `
     -WorkingDirectory E:\Temp\dd-igor-out -PassThru -RedirectStandardOutput <log> -WindowStyle Minimized
   ```
   Stdout capture works and includes `show_debug_message` lines (70 lines in a 12 s run). The runner's `-debugoutput <file>` option only
   captured the runner's own startup lines, not `show_debug_message`, so use stdout redirect.
3. Killed with `Stop-Process -Id <pid> -Force` after a timeout. `Get-Process DD-Project` afterwards showed nothing left over.

PowerShell 5.1 gotchas found: `Process.Kill($true)` does not exist (use `Stop-Process -Id`). `$p.ExitCode` comes back empty unless you touch
`$null = $p.Handle` right after `Start-Process -PassThru` and then call `$p.WaitForExit()`.

### 2.8 Protecting the owner's real saves (verified)

The save area is `%LOCALAPPDATA%\DD_Project`. Setting the `LOCALAPPDATA` environment variable to `E:\Temp\dd-fake-local` for the child
process moves it: GML printed `game_save_id = E:\Temp\dd-fake-local\DD_Project\` and files landed there. The real folder's timestamps
did not change (newest still 2026-06-17). Every automated run must set `LOCALAPPDATA` this way. The game's own `savedata*.sav` format
(`scr_save`) is untouched by the harness.

### 2.9 Proof-of-concept results (scratch copy; code in section 3.5)

| Capability | Result |
|---|---|
| Command-line args reach GML | `parameter_string(0..3)` printed exe path, `-game`, `data.win`, `-runtests`. Works. |
| Environment variables reach GML | `environment_get_variable("DD_TEST")` returned `1`. Works. |
| Assertions on real project functions + results file | `StatMod`, `StatClamp`, `HPGainPerLevel` checked; `test_results.txt` written to the save area; 4 pass, 1 deliberate fail, correct summary. |
| Exit code | `game_end(1)` gave process exit code **1** (and 0 for pass). Works in normal code. |
| Unhandled GML error | `exception_unhandled_handler` caught `global variable name 'this_does_not_exist_xyz' ... not set before reading it`, wrote `bot_result.txt` and logged it, with no blocking error dialog. **But `game_end(2)` inside the handler gave exit code 0**, so errors must be detected from the log line / result file, not the exit code. |
| Bot drives a battle | `GameState_SetBattleEnemy("poc_enemy", ENEMY_SLIME, 1)` + `room_goto(rm_battle)`, then `keyboard_key_press(vk_space)` / `keyboard_key_release` on alternate frames. The real battle code ran for 1500 frames (about 25 s): turns alternated, player HP fell 10 to 6, no runtime error. The bot did not win because the attack needs a timing mini-game (`Battle_AttackTimingTarget`); a smarter bot is future work. |
| Screenshots at several sizes | `screen_save` after `GameSettings_ApplyDisplay()` produced PNGs of exactly 480x432, 640x576, 800x720 (the three sizes matched `window_get_width/height`). A viewed 800x720 image showed the boot logo fading in. `display_scale` is clamped to 3..5 by the game, so I asked for 2/4/6 and got 3/4/5. |

Cleanup after every test: no `DD-Project`, `Igor` or `Runner` process remained (checked with `Get-Process`).

## 3. Harness design (not implemented in the repo)

### 3.1 Principle

Keep all new GML in existing `.gml` files so no `.yy`/`.yyp` edit is needed (AGENTS.md Rule 4). `scr_debug.gml` already exists and holds
`Debug_*` helpers: add `Test_*` functions to it (or ask the owner to create a `scr_test` script once in the IDE and put them there). One
three-line hook goes at the very top of `objects/obj_game_controller/Create_0.gml` (it exists in `rm_start`, which is the first room).
The hook does nothing unless the exe was started with a test flag, so normal play is unaffected.

### 3.2 Command-line contract

| Flag (after `-game data.win`) | Mode |
|---|---|
| `-runtests` | Run assertion suites, write results, `game_end(fail>0 ? 1 : 0)` |
| `-smoke` | Boot the real game, walk through rooms for N frames, fail on any runtime error |
| `-bot` | Scripted battle run(s) (see 3.4) |
| `-shots` | Take screenshots at the sizes in 3.4 |
| `-seed=<n>` | Optional fixed random seed so a failure is reproducible |

Hook (top of `obj_game_controller/Create_0.gml`):

```gml
Test_Boot();   // returns immediately unless a -runtests/-smoke/-bot/-shots flag is present
```

`Test_Boot()` lives in `scr_debug.gml`. It scans `parameter_string(i)`, installs `exception_unhandled_handler`, and for `-runtests` runs
everything immediately in the Create event (no rooms needed, so it finishes in under a second after load, measured 0.58 s whole process).
The other modes set `global.test_mode` and are driven from `obj_game_controller/Step_0.gml` by `Test_Step()` (one more line).

### 3.3 Suite runner (pure functions)

Output contract, identical on stdout and in the file `test_results.txt` in the save area:

```
[TEST] PASS StatMod(15)==2
[TEST] FAIL Combat_Damage knight vs slime got=7 want=8
[TEST-SUMMARY] pass=212 fail=1 errors=0
```

Helper style (GML 2.3 closures work, proven in the PoC):

```gml
function Test_Eq(_name, _got, _want) {
    var ok = (_got == _want);
    array_push(global.test.lines, (ok ? "[TEST] PASS " : "[TEST] FAIL ") + _name + (ok ? "" : " got=" + string(_got) + " want=" + string(_want)));
    if (ok) global.test.pass++; else global.test.fail++;
}
```

Suites and what they need (all names exist in the repo today):

- **Math/stats**: `StatMod`, `StatClamp`, `HPGainPerLevel`, `Exp_NextLevel`, `RecomputeResources`. No state needed.
- **Combat formulas**: `Combat_Damage`, `Combat_AttackBonus`, `Combat_DodgeBonus`, `Combat_ApplyDamage`. They read `Stat_Get`,
  `Status_*` and `Difficulty_Profile()`, so build fixtures with `CharacterCreate_Player(CLASS_KNIGHT)` and `EnemyCreate(ENEMY_SLIME)`
  and set difficulty explicitly (`DIFFICULTY_NORMAL`) at the start of each case. Randomness: call `random_set_seed(n)` before each
  case (`GameState_Init` calls `randomize()` once, guarded by `global.rng_inited`, so set `global.rng_inited = true` first or reseed after it).
  Prefer assertions that do not depend on dice (damage with fixed inputs, `Combat_AttemptHit` with `always_hit` / `force_dodge` statuses, crit chance clamps).
- **Status ticks**: `Status_Add` / `Status_Tick` / `Status_Has` / `Status_CanAct`: turns decrement, expired status is removed, HP/MP clamp to
  `[0, max]`, non-stackable status refreshes, the player stun immunity/cap-to-1 rule.
- **Inventory listing**: `Inv_Add` / `Inv_Remove` / `Inv_Has` / `Inv_GetItems`: stack splitting at `max_stack`, one-copy rule for weapons/armor/skillbooks, removal from the end, empty-stack deletion.
- **Data sanity** (cheap, catches content typos): every `ItemDB_Get`, `StatusDB_Get`, enemy id and skill id referenced by loot tables
  resolves; loot table keys exist; each `ENEMY_*` macro produces an enemy via `EnemyCreate`.
- **Save round trip**: `Save_BuildSnapshot` → `Save_ApplySnapshot` on a fixture, in the redirected save area only.

Each suite is a function `Test_Suite_<Name>()` returning nothing and appending to `global.test`. A `try { ... } catch (e) { errors++ }` around each
suite stops one broken suite from hiding the rest.

### 3.4 Smoke, bot and screenshot modes

- **Smoke (`-smoke`)**: `Test_Boot` installs the unhandled-error handler (proven). The mode walks `rm_start` → a floor room → `rm_battle`
  by direct `room_goto` for a fixed number of frames per room, then writes `[TEST-SUMMARY]` and exits. Any runtime error produces
  `[TEST] ERROR <message>` and a `CRASH` line in the result file. Exit-code caveat from 2.9: do not rely on the exit code for crashes; the wrapper
  script must grep for `ERROR`/`CRASH`.
- **Battle bot (`-bot`)**: proven to enter `rm_battle` with a chosen class/enemy and to drive the menu through `keyboard_key_press(vk_space)` /
  `keyboard_key_release` (no change to `scr_input`, which polls `keyboard_check`). To finish battles it needs to: press confirm on ATTACK, then
  time the confirm press from `Battle_AttackTimingTarget(obj_battle_controller)`, use skills/items by moving the menu with `vk_down`, and stop
  when `obj_battle_controller.battle_over` is true. Run matrix: 3 classes x a handful of enemies x 3 difficulties with fixed seeds, 2000-frame
  cap each, asserting no error, the battle ends, and HP stays within `[0, max_hp]`. Real time is about 60 fps (1500 frames took about 25 s), so
  keep the matrix small. Untested ideas to go faster: `game_set_speed(...)` higher than 60, `draw_enable_drawevent(false)`.
- **Screenshots (`-shots`)**: loop `settings.display_scale` over 3, 4, 5 and fullscreen-fit (`fit_screen`), call
  `GameSettings_ApplyDisplay()`, wait about 30 frames, `screen_save("<room>_<w>x<h>.png")`, in `rm_start`, one floor room, `rm_battle`, and with the
  menu/inventory open. The wrapper moves the PNGs from the save area into `E:\Temp\dd-shots\` and a human (or `Read` on the image) looks at them.
  Automated checks that need no eyes: file exists, dimensions equal the window size, and a non-black pixel ratio above a threshold (catches a
  blank screen). To test sizes outside 3..5 the harness would have to call `window_set_size` plus `Display_CalcLayout` directly (not tried).
  Note the boot logo fades in for several seconds, so screenshots of `rm_start` need a frame count above 400 or a `room_goto` first.

### 3.5 PoC code that was run (scratch copy only; reproduces the results in 2.9)

`Create_0.gml` head, trimmed:

```gml
var _tests = false;
for (var _i = 0; _i <= parameter_count(); _i++) if (parameter_string(_i) == "-runtests") _tests = true;
if (_tests) {
    var _pass = 0, _fail = 0, _out = [];
    var _check = function(_n, _g, _w) { return { n: _n, ok: (_g == _w), g: _g, w: _w }; };
    var _res = [ _check("StatMod(10)==0", StatMod(10), 0), _check("StatMod(15)==2", StatMod(15), 2),
                 _check("StatClamp(99)==60", StatClamp(99), 60), _check("HPGainPerLevel(8)==6", HPGainPerLevel(8), 6),
                 _check("deliberate failure", 1, 2) ];
    for (var _k = 0; _k < array_length(_res); _k++) { var _r = _res[_k];
        if (_r.ok) _pass++; else _fail++;
        array_push(_out, (_r.ok ? "PASS " : "FAIL ") + _r.n + " got=" + string(_r.g) + " want=" + string(_r.w)); }
    var _f = file_text_open_write("test_results.txt");
    for (var _k = 0; _k < array_length(_out); _k++) file_text_write_string(_f, _out[_k] + "\n");
    file_text_write_string(_f, "SUMMARY pass=" + string(_pass) + " fail=" + string(_fail) + "\n"); file_text_close(_f);
    show_debug_message("[TESTS] pass=" + string(_pass) + " fail=" + string(_fail));
    game_end(_fail > 0 ? 1 : 0);
}
```

`Step_0.gml` bot head, trimmed (frame counter `global.poc_f`, set at first Step; handler installed once):

```gml
exception_unhandled_handler(function(_ex) { show_debug_message("[BOT] UNHANDLED " + string(_ex.message)); game_end(2); });
// frame 30:
var _gs = GameState_Init(); _gs.player_ch = CharacterCreate_Player(CLASS_KNIGHT);
GameState_SetBattleEnemy("poc_enemy", ENEMY_SLIME, 1); room_goto(rm_battle);
// every later frame while in rm_battle:
if (global.poc_f mod 2 == 0) keyboard_key_press(vk_space); else keyboard_key_release(vk_space);
```

The full PoC files are in `E:\Temp\poc_head.gml`, `E:\Temp\poc_step.gml`, `E:\Temp\poc_bot.gml` (scratch; delete freely).

### 3.6 Wrapper script (to be written, not written yet): `tools/automation/run_tests.ps1`

Steps an agent runs (one command, target under 40 s end to end):

1. Sync the repo working tree to `E:\Temp\dd-igor-test` (`git archive HEAD | tar -x`, or `robocopy` excluding `.git`) so build output never lands in the repo.
2. Run the Igor PackageZip command from 2.4. Exit non-zero, or any line starting `Error :` in the output, means FAIL (print those lines).
3. Set `LOCALAPPDATA=E:\Temp\dd-save` (and delete its `DD_Project` folder first) so real saves are never touched.
4. For each mode: `Start-Process DD-Project.exe -game data.win -runtests ...` with stdout redirected to a log, `$null = $p.Handle`, wait with a timeout
   (tests 30 s, smoke 60 s, bot 120 s), `Stop-Process -Id` on timeout (timeout = FAIL), confirm no `DD-Project` process remains.
5. Parse: PASS only if the log has `[TEST-SUMMARY]` with `fail=0 errors=0`, has no `[TEST] ERROR` / `UNHANDLED` / `CRASH` line, and (for `-runtests`) exit code 0.
   Print every `[TEST] FAIL` and `ERROR` line, nothing else, so the output stays short for the agent.
6. Never print `um.json`. Never write to `%LOCALAPPDATA%\DD_Project`.

Rule 1 fit: a failing check is a new `Test_Suite_*` case that fails for the right reason (wrong value, not a compile error); then the implementation
makes it pass. This replaces the "temporary Create event call removed before commit" row in AGENTS.md with a permanent, committed suite.

## 4. Proposed new gate wording (for AGENTS.md; replaces "The gate" and the first "Traps" bullet)

> ## The gate
>
> A headless build and test run is available through Igor (runtime `2024.14.3.260`, `C:\ProgramData\GameMakerStudio2\Cache\runtimes`).
> Run `tools/automation/run_tests.ps1` (see `.planning/research/automation-igor.md`). The gate is:
>
> 1. The targeted check for the change (Rule 1) passes. For pure logic this is a `Test_Suite_*` case in `scr_debug.gml`, run by `-runtests`.
> 2. **Igor compiles the project with exit code 0 and no `Error :` lines** (VM Release build, output and cache on `E:`, from a scratch copy, never from inside the repo).
> 3. The built game runs `-runtests` (all pass) and `-smoke` (no runtime error) with `LOCALAPPDATA` redirected so real saves are untouched.
> 4. UI or layout changes: run `-shots` and look at the PNGs for the sizes in the research note, or state plainly that this was not checked.
> 5. If `tools/localization/*.py` was touched: `python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json` runs clean, and `python tools/localization/lint_hardcoded_text.py` reports no new hardcoded strings.
> 6. The owner still opens the project in the GameMaker IDE for anything that cannot be observed in the automated runs (feel, audio, art, controller input). Report this as a specific ask.
>
> Igor catches syntax errors but **not** unknown functions or variables; those are caught only by the smoke/bot runs. Treat a green compile alone as not enough.

Replacement for the Traps bullet:

> - **Igor is available but easy to misuse.** Always pass `--cache` and `--temp` on E:, build from a scratch copy, run with `LOCALAPPDATA` redirected,
>   kill the game with `Stop-Process -Id` after a timeout, and never use Igor `Run` without an outer kill (`-t` does not stop the game). Never print
>   `%APPDATA%\GameMakerStudio2\um.json` (it holds tokens). Crash detection uses the log/result file, because `game_end(n)` inside `exception_unhandled_handler` returns exit code 0.

## 5. Open items and risks

- The harness code (section 3) is a design plus proven PoC, not committed. The first packet should be: `Test_Boot` + `Test_Suite_Math` with a failing
  case, hooked from `obj_game_controller/Create_0.gml`, plus the PowerShell wrapper (pilot one suite before writing the rest, per AGENTS.md).
- Build is Release only; `--debug` and YYC (needs Visual Studio build tools) untested. Android/HTML5 targets not tested.
- C: free space was 70 GB at the end of testing, below the 80-90 GB rule in the global CLAUDE.md. Igor and the game wrote only small files on C:
  (`%TEMP%` is on E:; a few small `GameMaker.*` temp files and the Igor user-folder timestamps). Everything large was on E:
  (cache 74 MB, output 466 MB, scratch copy 65 MB). Do not run these commands with `--cache`/`--temp` left at defaults.
- The GameMaker IDE (owner's process) was running during all tests with no interference. Igor shares the runtime and user folder with it, so a
  future automated run while the owner is mid-build in the IDE is untested.
- Runs steal screen time and focus for a few seconds each; avoid running the bot matrix while the owner is gaming or recording.
- `game_end(code)` exit code works in ordinary code but returned 0 inside the unhandled-exception handler; verified, documented above.

## 6. Scratch artifacts (all on E:, all safe to delete)

`E:\Temp\dd-igor-test` (project copy with PoC edits in `obj_game_controller`), `dd-igor-cache`, `dd-igor-tmp`, `dd-igor-out` (exe, data.win, zip),
`dd-fake-local` (redirected save area with PoC results and PNGs), build and run logs `E:\Temp\dd-igor-*.log`, `dd-poc*-*.log`, PoC sources `E:\Temp\poc_*.gml`,
backups `gc_create.bak`, `gc_step.bak`, `scr_math.bak`.
