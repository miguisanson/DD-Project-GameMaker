# Resume here (written 2026-10-16, end of overnight session 4)

Start with `/continue_DD-Project-GameMaker`, then read this file and `BOARD.md`.
Spec = `research/DECISIONS.md` (D1-D125). Code lands on branch `next` (worktree `E:\Github_Projects\DD-Project-GameMaker-wt\next`); docs on `v1.9`.

## Where things stand
- **PLAYTEST NOW.** Build `63deaae-20261015` (= `next` @ 63deaae; supersedes all earlier build folders) passed the FULL gate and is in
  `E:\Games\DD-Project Playtest\63deaae-20261015\`. Owner's old saves: `E:\Games\DD-Project Playtest\old-saves-2026-10-15`.
- Owner checklist: `.planning/PLAYTEST-QUEUE.md` (61 entries + 3 questions at the end: echo vs class, D88 unlocks, save on window close). After the owner plays: merge the good ones from `next` to `v1.9`,
  revert/fix the bad ones.
- Merged overnight (all on next): R1 + R1-sim (D117-D121, D123, D125), R1b (D122, D124), fix-diff (D35 difficulty list gone),
  fix-review1 (Opus review: New Game guard, honest RUN %, edge-triggered focus pause, old run files), F1a, F1b, F1c, F1d-1, F1d-3,
  F3a, F3b-1, F3b-2, then F2a, F4a, F1d-2, F4b, I1-I3 (regression checks + gate), fix-runtick (R-022), two Opus review passes
  (see BUILD-PLAN "F1 packets" and "Improvement-mode queue").

## Left to do
1. Owner playtest (above).
2. Improvement mode on `next`: all F1 packets done except the audio-manager restructure (skipped: needs by-ear checks);
   F4d wording/sound consistency needs owner decisions (list in BUILD-PLAN).
3. Owner IDE import (~15 min): `art/IMPORT-CHECKLIST.md` + `art/sfx_new/IMPORT.md`.
4. Sound/music creator names for the credits (very last).

## Notes
- D123 as chosen gives ~6 elites/run (sim: win rate -3..6 points). In PLAYTEST-QUEUE Q-033; fallback = drop "at least one per floor".
- Process tonight: Sonnet subagents wrote every implementation in worktrees, committing their failing check first; Opus reviewed,
  ran the gates, merged, plus one Opus deep-review pass after ~7 packets (found the New Game bug).
- `run_tests.ps1` needs an exact `Shots =` count (now 172): every packet that adds shots must update it.
