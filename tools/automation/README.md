# tools/automation

`run_tests.ps1` is the gate wrapper: headless Igor build plus game test runs.
Background and the proven commands: `.planning/research/automation-igor.md`.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools\automation\run_tests.ps1 [-Mode fast|full|compile] [-NegativeControl]
```

| Mode | What runs |
|---|---|
| `compile` | Build only (about 15 s). Catches syntax errors, not unknown functions. |
| `fast` (default) | Build + `-runtests` (timeout 30 s). |
| `full` | `fast` + `-smoke` (60 s) + `-bot` (120 s) + `-shots` (60 s). Modes not yet implemented print `SKIP <mode> (not implemented)`. |

Exit code: 0 = `GATE PASS`, 1 = `GATE FAIL`, 2 = refused to start (a work dir is on C:, or Igor/git missing).

Output is only FAIL/ERROR/SKIP lines, one timing line per step, and the final GATE line.
Full logs: `E:\Temp\dd-gate\logs\build.log` and `<mode>.log`.

## How it works
- Copies the working tree (`git ls-files -co --exclude-standard`, so uncommitted edits are tested) into a fresh `E:\Temp\dd-gate\src`. Nothing is built inside the repo.
- Work dirs `src, cache, tmp, out, save, logs` all live under `-WorkRoot` (default `E:\Temp\dd-gate`). If any resolves to C: the script exits 2 before touching anything. `cache` and `tmp` are kept between runs; the rest are emptied.
- Games run with `LOCALAPPDATA` pointed at `...\save`. A hash of `%LOCALAPPDATA%\DD_Project` is taken before and after; any change is a FAIL. (If the owner plays the real game during a run, that also trips it.)
- `-runtests` passes only with: a `[TEST-SUMMARY] pass=N fail=0 errors=0` line (N > 0), no `UNHANDLED` / `CRASH` / `[TEST] ERROR` line, `test_results.txt` somewhere under the save dir, exit code 0, no timeout, and no `DD-Project` process left from this run (anything left is killed and counted as FAIL).
- `-NegativeControl` adds `-testcontrol` to the game, which should add a deliberately failing test. The expected result is `GATE FAIL`; run it whenever this script changes (VER-04).

## Adding a game mode
Edit the `$GameModes` table at the top of the script: set `Impl = $true` on the row (flag, timeout and strictness are in the same row).
