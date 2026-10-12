# Improvement mode

A standing way of working, not a phase. It keeps building and keeps catching bugs while the owner is away, without letting unplayed work pile up. It is based on `research/lessons-from-past-projects.md` sections 4.2-4.7 and adjusted to the owner's decisions D11, D12, D13 and D17.

Plain version: the owner starts a session and leaves it running. The agents work on a separate branch called `next`, one small commit per feature. Every commit comes with automated proof and a list of steps the owner can play. When there are about 8 features the owner has not played yet, the agents stop adding features and only hunt bugs. Nothing reaches `v1.9` until the owner has played it and said yes.

**Starts only after Phase 1 is done** (the verification ladder works, the negative control is red, `REGRESSION.md` is green on the current build).

## What the owner decided (do not change without a new grill-me)

| Decision | Meaning here |
|---|---|
| D11 | The owner plays when free, in big sessions. Agents keep building and run improvement mode while away. |
| D12 | About 8 unplayed features and the loop switches to bug-hunt only (checks, simulator, tidy) until the owner plays. Each feature is its own revertable commit with its playtest steps. |
| D13 | The loop PROPOSES balance changes with simulator before and after numbers. The owner approves in a batch. It never changes a balance number on its own. |
| D17 | The owner starts a live session and leaves it running. No scheduled autopilot. Unattended work lands on `next`, one commit per feature, each with automated checks and playtest steps. After the owner plays, good features merge to `v1.9` and bad ones are reverted. |

## Differences from the old lessons (and why)

- The old rule was "owner plays after every 10 merged packets or each calendar day" (`lessons` 4.5, 4.7 #5). D12 replaces it with the 8-feature cap. The old research warns that a lump of unplayed features cannot be debugged (`lessons` root cause 2), so the cap counts features, not packets, and a feature must be revertable on its own.
- The old rule said "no self-audits as an input" (`lessons` 4.7). The owner asked for continuous bug catching, so a bounded bug hunt is allowed, but every finding needs evidence (see below). "Could be better" is still not an input.
- The old rule said "no unattended runs that change game behaviour" (`lessons` 4.7 round limits). D17 allows a live session left running, because everything lands on `next` and nothing merges without the owner. The safety is the branch, the per-feature revert, and the stop conditions.

## Inputs (in this order)

1. **ISSUES inbox**: rows in `ISSUES.md` with status `open` or `confirmed` (the friend's and owner's words, verbatim). Highest severity first.
2. **Failing regression checks**: any `REGRESSION.md` entry that fails on the current build.
3. **Compile or runtime errors** from the gate (`tools/automation/run_tests.ps1`).
4. **Simulator out-of-band numbers** (after Phase 8 exists): these become balance PROPOSALS only (see "Balance" below). They are never applied.
5. **Bug-hunt findings with evidence** (bounded, see below).

Not inputs: ideas for improvement with no evidence; new design; polish that nobody asked for. If the top of the queue is polish with no owner quote and no failing check, the correct result is "nothing to do" (`lessons` 4.7 #7).

Features that come from the roadmap (the GSD phase loop) also land on `next` under these rules and count toward the unplayed total. Improvement mode never invents player-facing design. A question the research and DECISIONS cannot answer becomes a `QUESTION` row in `ISSUES.md` and a line under "Questions for the owner" in `PLAYTEST-QUEUE.md`, and the loop continues with other work.

## The cast and the limits

- **Reviewer and integrator: the Opus main session.** It runs the checks itself, mutates the code to see them go red, and opens the screenshots. It is never the builder of the thing it reviews. (`lessons` 4.4)
- **Implementers: Sonnet subagents**, each in its own git worktree at `E:\Github_Projects\DD-Project-GameMaker-wt\<short>`. **At most 2 at the same time**, and only if their file sets do not overlap and neither touches shared globals, `scr_debug`/`scr_test`, or `scr_save`. (`lessons` 4.3)
- **Mechanical text: local model (Ollama) or a Haiku subagent.**
- **Read-only research or audit agents** may run in parallel freely.
- **One integrator** merges one packet at a time into `next`, then rebuilds and re-verifies (see "After every merge").
- **WIP cap: 3** open packets (specified, in flight, or waiting for review). At the cap, stop dispatching.
- **Cut the parallelism to 1** if a merge needs manual conflict resolution, a regression is found in the packet merged just before, or the compile is red after a merge.
- **Packet size**: one behaviour per packet; about 150 changed GML lines and about 3 files at most. A packet that needs "and" is split. (`lessons` 4.2)
- **Resource creation** (new object, sprite, room, script, font) is an owner IDE task. The loop does not hand-edit `.yyp`, `.yy` or `resource_order` (AGENTS.md Rule 4). Work that needs a new resource goes to the "IDE tasks for the owner" list in `PLAYTEST-QUEUE.md` and the loop moves on.
- **Siblings rule**: a fix for one instance of a repeated pattern must search for the other instances and fix them all or list each as its own row. (`lessons` 4.2)

## The loop

Run these steps, then check the stop conditions. One feature or fix per pass.

0. **Preflight.** Read `STATE.md` and the queue. Confirm: the gate is green on `next`; the negative control is red; the unplayed count is below 8 (else bug-hunt only); no stop file `.planning/IMPROVE_STOP`; usage is below 80% of the window and week. If not, stop and report in 5 lines.
1. **Pick.** The top input from the list above. If it is a design question, park it and pick the next.
2. **Check first.** Write the repro or the failing check (an `R-###` entry for a bug; 1-3 entries for a feature's Done-when). Run it. It must fail for the right reason (a wrong value, not a typo).
3. **Delegate.** Write the contract and hand the implementation to a Sonnet subagent in a worktree. Pilot first when the work is repetitive.
4. **Review** (the Opus session, in this order, evidence pasted into the commit message):
   1. Run the checks yourself on the candidate (compile, `-runtests`, scenario if relevant). A report that says "green" is not evidence.
   2. Check the Done-when clause by clause with a pointer (file and line, log line, screenshot name). A clause not met means not done. Split it into a new row now.
   3. Could the new check fail? Revert the fix or flip the key line and see it go red. Expected values must come from the spec or the owner, not from the code's own output.
   4. List removed or changed assertions by name and justify each (rpg-gm lost neighbour tests this way).
   5. Open every changed visual, at all matrix sizes. Read the text, look for placeholder icons, overlaps and the screen after a cutscene or dialogue.
   6. The scenario must reach the feature through the real input path, not by calling the function.
   7. Sibling sweep: grep other uses of the changed pattern; run the `REGRESSION.md` entries for the two nearest systems.
   8. Diff hygiene: no stray debug hooks, no hand-edited `.yy`, no hard-coded English (run the localization lint), nothing outside the packet's file list.
   9. Fix small findings in the same session; send bigger ones back as new rows.
5. **Merge** to `next` as one commit: code, checks, the `REGRESSION.md` entries, and the playtest entry together.
6. **After every merge** (not once after several): rebuild and re-run the gate on the merged tree, plus the entries for the touched systems. If red, revert at once and log it.
7. **Record.** Add the entry to `PLAYTEST-QUEUE.md` (exact steps, expected result, build id). Update `STATE.md` (header counters, WIP, next action) and `ISSUES.md`.
8. **Stop check** (below), then loop.

## Feature, fix and the unplayed count

- A **feature** is any commit whose result the owner has to play to judge (new screen, new move, feel change, balance change). It adds 1 to "unplayed features" in the `STATE.md` header.
- A **fix** with an automated regression check that fully proves it adds 0. A fix whose proof is "looks right" or "feels right" counts as 1.
- At **8**, switch to bug-hunt only: checks, simulator runs, tidy-ups, screenshots. No new feature work until the owner has played.
- When the owner plays, they mark each entry in `PLAYTEST-QUEUE.md` as `good`, `bad` or `change`. Good ones merge to `v1.9` (only on the owner's word, as a separate merge). Bad ones are reverted on `next` and get an `ISSUES.md` row. The unplayed count goes back to 0 for what was played.

## Bug hunt (bounded, evidence only)

The owner asked for continuous bug catching. This is how, without the old "an audit is never empty" trap (`lessons` 2g).

**Passes.** One bug-hunt pass per loop cycle when features are capped, otherwise one pass after every 3 merged commits. **At most 5 findings are filed per pass** (this number is a proposal; the owner may change it). An empty pass is a correct result. **Three empty passes in a row: stop and wait for the owner** (the old idle-stop rule, `lessons` 1a).

**Methods:**
1. **Scripted scenarios and bot runs**: the fixed-seed matrix (3 classes x a few enemies x 3 difficulties, 2000-frame cap each, about 60 frames per second so keep it small; `automation-igor.md` section 3.4). Assert no runtime error, the battle ends, HP stays within [0, max].
2. **Screenshot matrix review**: Opus opens the `-shots` images at every supported size for title, floor, battle, menus, cutscene end and dialogue end.
3. **Static sweeps for known bug classes** found in this codebase:
   - frame-rate-dependent timers (about 352 step-counted lines, `codebase/CONCERNS.md`);
   - `ds_*` leaks (18 creates against 6 destroys, no CleanUp events, CONCERNS);
   - global state not reset on room change;
   - hard-coded English (run `lint_hardcoded_text.py`);
   - the sibling sweep for any bug fixed since the last pass.

**Evidence rule.** Every finding must carry evidence: a failing check, a log line, or a screenshot path. A finding is a row in `ISSUES.md` with the evidence in the repro column. No evidence, no row. "Could be better" is not a finding. Findings from a pass are filed; they are fixed in later cycles as normal rows, not in the same pass.

## Balance (D13)

When the simulator (Phase 8 onward) shows a number outside its band, the loop writes a **proposal** in the "Balance proposals" section of `PLAYTEST-QUEUE.md`: what, why, before and after simulator numbers. It does not edit balance data files. The owner approves in a batch, and only then does a commit apply the approved ids. A commit that changes balance data without an approved id fails review.

## Stop conditions

Stop dispatching, report in 5 lines, and wait for the owner when any of these is true (`lessons` 4.7, adjusted):

1. The gate is red at the start of a cycle, or the negative control no longer fails.
2. A review or playtest finds a regression from the previous wave in **two waves in a row**, or 3 in any 6. Switch to stabilization: only the regression list and repairs until a full wave is clean.
3. The same bug class shows up a second time. Fix the class, add a guard, ask the owner before continuing.
4. Any "done" is later found not done (a Done-when clause unmet, a check that cannot fail). Freeze and re-review the last 10 done rows before new work.
5. **The unplayed count reaches 8** (D12). Switch to bug-hunt only, not a full stop; if the bug hunt has three empty passes, stop.
6. WIP cap exceeded, or a merge needed manual conflict resolution.
7. The top of the queue is polish with no evidence.
8. Usage above 80% of the window or week. Do not start a wave you cannot finish and verify.
9. An agent proposes a rule or process change. Only the owner changes process, and never in the middle of a wave.
10. `.planning/IMPROVE_STOP` exists, or the owner types stop.

Round limits: at most 3 consecutive waves on one theme; at most 1 wave per owner play session unless the inbox still has P1 or P2 bugs.

## Practical notes

- Automated runs open a real game window for a few seconds and take focus (`automation-igor.md` section 5). Leave the PC logged in. Do not start the bot matrix while the owner is gaming or recording.
- Builds go on E:. Check `df -h /c` first; C: was 71 GB free on 2026-10-13, below the 80-90 GB rule.
- Never use Igor `Run` without an outer kill (`-t` does not stop the game). Never print `um.json`. Crash detection reads the log, not the exit code (`automation-igor.md` section 4).
- Commit before ending any session. A background subagent dies with the session, so write what it was doing into `STATE.md` first (`lessons` 2g).

## How to start improvement mode (what the owner types)

1. Open a session in `E:\Github_Projects\DD-Project-GameMaker`. Check that `STATE.md` shows Phase 1 done and the gate green.
2. Type: `/improve_DD-Project-GameMaker`. (This command is created in Phase 1, wave 1D. Until it exists, type: `Run improvement mode as described in .planning/IMPROVE.md.`)
3. Leave the session open and the PC awake and logged in.
4. To stop: type `stop`, or create an empty file `.planning/IMPROVE_STOP`.
5. When you come back: open `.planning/PLAYTEST-QUEUE.md`, play the build with the id shown at the top, mark each entry `good`, `bad` or `change`, answer the "Questions for the owner", and say `merge the good ones` when you want them on `v1.9`.

---
*Created: 2026-10-13*
