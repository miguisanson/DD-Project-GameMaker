# Resume here (written 2026-10-17, end of session 5 - paused by the owner for a playtest; the next session runs on another account)

Start with `/continue_DD-Project-GameMaker`, then read THIS file, `BOARD.md`, `STATE.md` (header + "Learned"), `PLAYTEST-QUEUE.md` (section "Build 7f4d08e-20261016").
Spec = `research/DECISIONS.md` (D1-D173). Game code lands on branch `next` (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\next`); docs live on `v1.9` (this checkout).
**PAUSED by the owner 2026-10-17 while they playtest: no builds, gates or agents until they say resume.** The owner's next message will most likely be playtest notes.

## Where things stand
- **Playtest build (owner is playing it):** `E:\Games\DD-Project Playtest\7f4d08e-20261016\` = next @ 7f4d08e: all of round 3 (D140-D165) + 19 bug fixes. Full gate PASS.
  It does NOT have the boss background (imported after the build) nor anything listed below.
- **`next` @ a1d23bb** = the playtest build + improvement mode (all merged with a full gate PASS each):
  H13b text fit (layouts wrap/widen, never cut) + Codex run-history fix, progression fixes R-071..074, map/world fixes R-075..079,
  text shortening, QTE/audio/Korean fixes R-080..084 (alt-tab freezes QTEs, D122), and the owner's boss background import (D13, a1d23bb).
- Regression list (`REGRESSION.md`): first full run on c7e787d: 60 green / 0 red / 15 owner checks / 4 unmapped; R-021 negative control red as required.

## Not merged yet (stopped when the owner paused)
| Worktree | Branch | State | To do |
|---|---|---|---|
| `wt\review7` | fix-review7 | committed 427750d (checks) + 2edd152 (fixes) for the 4 P3s in `research/review-opus-session7.md`; gate NOT confirmed | run `-Mode fast`, `-Only smoke`, `-Only shots` with `-WorkRoot E:\Temp\dd-gate-review7`, review, merge into next (chain: its smoke steps if any end before the final hunt7map step), file `REGRESSION-ADD.md` rows (copy in the worktree root, R-085..088) as the next free R numbers on v1.9 |
| `wt\d168` | d168-names | only a started edit to scr_test.gml (TextFit_Known entries removed), uncommitted | re-dispatch D168: long names wrap to two lines on cards/panels, "The Pale Choirbeast" -> "Pale Choirbeast" (brief: remove the 7 name entries from TextFit_Known first so the fit checks go red, then fix the title layout; gate; merge) |
| (none) | - | CC0 audio search not started | D169/D172: find CC0-only battle (3-4) and boss (3) chiptune loops and 3 short refuse sounds; download into `art\audio_candidates\` (music\, refuse\) with `PICK.md` (title, author, URL, licence link, length, loop, recommendation) and IDE import steps; the owner listens, picks, imports; then wire mus_battle / mus_boss / ui_deny |

## Next, in order (after the owner's go)
1. Triage the owner's playtest notes (ISSUES.md, grill-me only for design/balance/save-format calls).
2. Land review7, D168, the audio picks; fix playtest findings.
3. Build the D173 ideas: IDEA-07 Weak points, IDEA-03 Trapped chests, IDEA-21 Boss finisher, IDEA-25 Death-screen tip; IDEA-12 Branching upgrades needs grill-me first (save format, amends D82). Numbers for 07/03/12 via an owner-approved balance proposal.
4. D171 (QTE grade capitals) is the owner's call after playing.
5. New playtest build (copy `E:\Temp\dd-gate\out` after a clean `-Mode fast` on a committed tree: exe, ttf, data, data.win, fonts, localization, options.ini) + PLAYTEST-QUEUE section.
6. Clean up merged worktrees under `E:\Github_Projects\DD-Project-GameMaker-wt\` (list in STATE WIP) once nothing in flight uses them.

## How tonight's merges were done (read STATE "Learned" too)
- Each packet in its own worktree off `next`; the integrator merges one at a time and runs `-Mode full` after each.
- When two branches append tests at the same spot, take next's file and re-apply the branch's own diff (its appended block + registration line);
  renumber scenario steps if the range is taken. Smoke step ranges in use: 750-769 H5, 790-799 H13a, 800-804 hunt5a, 820-829 D164, 840 hunt6run,
  850-869 H8a, 890-909 H12a, 920-929 H8b, 950-956 hunt6ui, 960-961 review6, 980-987 hunt7map (end of the chain). Pictures: 800-809 H13a (end), 830-839 D164, 870-889 H8a, 910-919 H12a, 930-939 H8b.
- Workbook merges: scratch helper logic = apply the branch's rows that differ from the merge base onto next's xlsx with openpyxl, rebuild localization.json, run the 4 lints (markup, hardcoded, terms, missing ko).
- Gate WorkRoot must be an absolute path containing "dd-gate"; never commit `Temp*` folders (agents mistyped the path twice).
