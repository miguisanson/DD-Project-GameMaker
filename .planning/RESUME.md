# NO HOPE v1.0 — shipped 2026-10-17

The owner ended development after the round-4 playtest. The release is built; nothing is pushed.

## Where things are
- **Release:** `E:\Games\NO HOPE Release\`
  - `NO-HOPE-v1.0-windows.zip` (63.4 MB, sha256 C6719F157989198BE51C51DE5234D670BF72DE8AFD2E9F0C019A34824A77C837), and the same files unzipped in `NO-HOPE-v1.0-windows\`
  - `itch-page.md` (paste into itch.io) and `itch-screenshots\1-6.png` (640x576, upload in order)
  - The release exe passed all 8042 unit tests from the zip (scratch save folder).
- **Code:** branch `main` = v1.9 = next, tagged `v1.0` (local only). `next` keeps its worktree at `E:\Github_Projects\DD-Project-GameMaker-wt\next`. All 114 branches kept.
- **Last playtest build:** `E:\Games\DD-Project Playtest\8d176ba-20261017` (older builds deleted; the owner's old save backups kept).
- **Owner IDE steps (optional, before uploading):** Game Options > Windows: display name "NO HOPE" (code already sets the window caption), company/description/icon; optionally remove the unused included fonts NotoSansCJKkr-Regular.otf and NanumGothic-Regular.ttf (~18 MB; the release script already leaves them out of the zip).
- **Not done (owner's choice):** no battle/boss music (D194); IDEA-12 branching upgrades (needs a grill-me); Nobody stays the hard class (sim ~36% win; a starter skill would fix it — new mechanic).

## How to pick development back up
1. Open `DD-Project.yyp` in GameMaker from `E:\Github_Projects\DD-Project-GameMaker` (branch `v1.9`, or check out `main` / tag `v1.0`). Game code changes go on `next` (worktree above), merged to `v1.9` after a playtest.
2. Start a Claude session with `/continue_DD-Project-GameMaker`; read `AGENTS.md`, `.planning/STATE.md`, this file, `research/DECISIONS.md` (D1-D195).
3. The gate: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/automation/run_tests.ps1 -Mode fast` (add `-Mode full` before a playtest, never while playing: it watches the real save folder).
4. Work pattern that shipped v1.0: one brief per packet (examples in `research/packet-briefs-r4/`, rules in `common.md`), a Sonnet agent per packet in its own worktree, the integrator merges one at a time (helpers in `research/merge-helpers/`, e.g. `wbmerge.py` for the text workbook) and runs the gate after each.
5. A new release: `tools/release/make_release.ps1` (clean tree; gates, builds, zips into `E:\Games\NO HOPE Release`).
