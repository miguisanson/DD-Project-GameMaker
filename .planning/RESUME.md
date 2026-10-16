# Resume here (2026-10-17 night, shipping NO HOPE v1.0)

The owner finished their LAST playtest and said: do all the fixes and ship; keep going after a usage-limit reset. No new features unless the owner reopens development.
Start with `/continue_DD-Project-GameMaker`, then this file and `.planning/STATE.md` (WIP line). Decisions: `research/DECISIONS.md` up to D195. Agent cap: 2 at a time (memory).
Game code is on branch `next` (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\next`); docs on `v1.9` (this checkout). Packet briefs: `E:\Temp\dd-briefs\*.md` (common.md = rules for every packet).

## In flight
| Worktree | Branch | Brief | State |
|---|---|---|---|
| wt\polish | fix-r4polish | polish.md | battle toast never covers the enemy; level-up legend wording |
| wt\lootglow | feat-r4lootglow | lootglow.md | D195 gold outline on containers that still hold loot |
A full gate on next (with final2 + release merged) was started; re-run if its result is unknown.

## Then, in order
1. Merge polish and lootglow into next one at a time (conflicts are always: suite registration lines -> keep both; appended test/scenario functions -> keep both, close the first function; shots/smoke chains -> make the previous end go to the new start; run_tests.ps1 Shots count = sum; workbook -> `python E:\Temp\dd-merge\wbmerge.py <branch>` then rebuild localization + lints). Fast gate after each.
2. Full gate (`run_tests.ps1 -Mode full -WorkRoot 'E:\Temp\dd-gate-next'`) on a clean committed tree with the owner OFF the PC (REAL SAVE FILES CHANGED = the owner is playing; not a code failure).
3. Release: from the `next` worktree run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/release/make_release.ps1` (it gates, refuses a dirty tree, builds `E:\Games\NO HOPE Release\NO-HOPE-v1.0-windows\` + `.zip`). Retake the itch screenshots from that clean build's shots (tools/release/screenshots, 640x576) and commit. Check the zip: unzip to E:\Temp, run `NO HOPE.exe -runtests` once, look at the title (v1.0, Credits).
4. Merge `next` -> `v1.9` -> `main` locally, tag `v1.0`. Do NOT push (owner did not ask).
5. Tidy (owner: delete only regenerable bloat, keep all branches/history): E:\Temp\dd-gate*, E:\Temp\dd-* scratch, E:\Temp\dd-briefs (after copying any useful report into .planning/research), old playtest builds in E:\Games\DD-Project Playtest except the newest, merged worktrees (keep `next`). Update STATE/BOARD to "Shipped v1.0" with a short "how to resume development" (open the project in GameMaker, branch next/main, the gate command, the briefs pattern).
6. Tell the owner: where the zip and itch-page.md are, the owner IDE steps (Game Options display name "NO HOPE", company/description/icon; optional removal of the unused Noto/Nanum fonts), and that nothing was pushed.
