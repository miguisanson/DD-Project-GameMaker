# Proposed AGENTS.md changes

For the main session to apply in Phase 1, wave 1D. Not applied yet. AGENTS.md is 212 lines today. After all changes below it should be about 217 lines (target: under about 220).

**When to apply:** apply sections 1-5 only after waves 1A-1C of Phase 1 pass (the wrapper builds, `-runtests` and `-smoke` run, the negative control is red). Until then the old gate stays, so the rules never describe a tool that does not exist yet. Sections 6-8 (Rule 5, fallback ladder, small fixes) can go in at the same time as they only shorten text.

Sources: `research/automation-igor.md` section 4 (gate and trap text), `research/lessons-from-past-projects.md` sections 4.3, 4.4, 4.8 (parallelism, reviewer, size).

---

## 1. Rule 1 intro and table (replaces AGENTS.md lines 15-24)

Replace from "This project has no automated test runner" down to the end of the table with:

```markdown
The project has a headless harness (Igor build plus `Test_Suite_*`; see "The
gate"). "The check" is whatever can actually be checked for the kind of change:

| Work | Check you write first |
|---|---|
| Pure logic in a `scr_*` script (math, stats, combat formulas, DB lookups, save) | A failing case in a committed `Test_Suite_*` (in `scr_test`), with expected values taken from the spec or the owner, not copied from the code's output. Run with `-runtests` through `tools/automation/run_tests.ps1`. No temporary Create-event calls. |
| Behaviour in the running game (movement, dialogue, room change, battle flow, save/load, UI) | A scripted scenario (`-bot` or `-smoke`) that reaches it through real key input and asserts state; for screens also `-shots`, then open the PNGs. |
| Feel and balance (QTE timing, animation speed, numbers) | The owner's number first (grill-me), a ms or frame measurement in the bot, then a short owner checklist in `.planning/PLAYTEST-QUEUE.md`. |
| Localization tooling (`tools/localization/*.py`) | A small Python check (sample input, expected output) run with `python`, per the script's own CLI. |
```

---

## 2. The gate (replaces the whole section "## The gate", lines 89-103)

```markdown
## The gate

Run `tools/automation/run_tests.ps1` (Igor, runtime 2024.14.3.260; exact command
and details in `.planning/research/automation-igor.md`). It prints only FAIL and
ERROR lines. The gate is:

1. The targeted check for the change (Rule 1) passes.
2. Igor compiles with exit 0 and no `Error :` lines (VM Release; `--cache` and
   `--temp` on E:; built from a scratch copy, never inside the repo).
3. `-runtests` (all `Test_Suite_*` pass) and `-smoke` (no runtime error) pass.
   Igor does not catch unknown functions or variables; the smoke run does. A
   missing result file, a hang or a leftover game process is a FAIL.
4. The negative control is still red. Run it whenever the wrapper changes.
5. UI or layout changes: `-shots`, then open the PNGs at every size.
6. The `REGRESSION.md` entries for the touched systems ran on this build id.
7. If localization tooling or keys changed: `python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json` runs clean, and `python tools/localization/lint_hardcoded_text.py` reports no new hardcoded strings.
8. Feel, audio, art and controller input: ask the owner for a specific L5 check.

A green compile alone is not enough. Automated runs set `LOCALAPPDATA` to a
scratch folder and never touch `%LOCALAPPDATA%\DD_Project`.
```

---

## 3. Traps: the Igor bullet (replaces the first bullet under "## Traps", lines 198-202)

```markdown
- **Igor is available but easy to misuse.** Always pass `--cache` and `--temp`
  on E:, build from a scratch copy, run with `LOCALAPPDATA` redirected, kill the
  game with `Stop-Process -Id` after a timeout, and never use Igor `Run` without
  an outer kill (`-t` does not stop the game). Never print
  `%APPDATA%\GameMakerStudio2\um.json` (tokens). Detect crashes from the log or
  result file: `game_end(n)` inside the unhandled-error handler returns exit 0.
```

---

## 4. How the team splits work (replaces lines 105-114)

```markdown
## How the team splits work

| Agent | Does | Does not |
|---|---|---|
| **Claude** (Opus main session) | Architecture, contracts, the failing check, **reviewing every packet**, integrating, anything touching save data or licensing | Grind bulk work; review its own implementation |
| **Sonnet subagent** (`Agent`, `model: "sonnet"`) | Makes a written failing check pass; implements against a stated contract; works in its own git worktree | Change a check to match its code; widen scope; create/rename resources outside the IDE |
| **Local model** (Ollama, `mcp__ollama__ask_local`) | Mechanical work: string drafts, commit messages, summarizing long files | Design, multi-file reasoning, anything unverified |

- **At most 2 implementer subagents at once**, each in its own worktree under
  `E:\Github_Projects\DD-Project-GameMaker-wt\<short>`, and only if their files do
  not overlap and neither touches shared globals, `scr_test`/`scr_debug` or
  `scr_save`. Read-only research agents are not capped. **One integrator** merges
  one packet at a time and **re-runs the gate after every merge**. WIP cap 3. Drop
  to 1 implementer after a manual merge conflict, a regression or a red compile.
- **Reviewer rules** (never the builder; assume the report is wrong): run the
  checks yourself; mutate the code and see the new check go red; take expected
  values from the spec; list removed or changed assertion names; open every
  changed screenshot; reach the feature through real input; grep siblings; no
  stray debug hooks, no hand-edited `.yy`. Fix small findings in the same session.
- The failing check is the handoff. Every delegated result is reviewed and gated
  before it merges. Packets are one behaviour, about 150 changed GML lines and
  about 3 files at most.
```

---

## 5. New short section (insert after "## The gate", before "## How the team splits work")

```markdown
## Improvement mode, regressions, issues

- `.planning/IMPROVE.md`: how unattended work runs (branch `next`, one commit per feature, 8 unplayed features then bug-hunt only, stop conditions). Start with `/improve_DD-Project-GameMaker`.
- `.planning/REGRESSION.md`: every fixed bug adds an `R-###` entry before its fix merges. An entry with no run on the current build id is unchecked, not green.
- `.planning/ISSUES.md`: the one triage table. Verbatim notes stay in `.planning/research/playtest-notes.md`. A bug closes only when the reporter's repro passes.
- `.planning/PLAYTEST-QUEUE.md`: what the owner must play. Nothing merges to `v1.8` before the owner plays it. Balance numbers change only through an owner-approved proposal.
```

---

## 6. Rule 5 shortened (replaces lines 61-85; saves 8 lines)

```markdown
## Rule 5 — Leave the repo ready for whoever comes next

Any session can end without warning. Keep `.planning/STATE.md` current as you go:

- **After every step that lands**, update its header and *Current Position*: what
  is done, what is in progress (branch or worktree), the exact next action, and
  anything learned that is not obvious from the code. Commit it with the work.
- **Before a long or risky step** (a delegated packet, a big refactor, a
  background run), write down what you are about to do and where the output goes.
- **Never leave work only in your context.** Half-finished code gets a WIP commit
  on a branch (not `v1.8`; unattended work goes on `next`) or a STATE.md note
  naming the files. List worktrees and background jobs by path.
- **If the session is ending**, run `/gsd-pause-work` (Claude) or write the same
  into STATE.md by hand.

The next agent starts with `/continue_DD-Project-GameMaker`, or reads this file,
`.planning/STATE.md` and `git status`.
```

---

## 7. Fallback ladder shortened (replaces lines 116-135; saves 9 lines)

```markdown
### When a helper is unavailable

Ollama down: its mechanical work goes to a `haiku` subagent (or `sonnet` if it
needs judgement). Subagents unavailable: the main session implements inline, in
the smallest packets. Every rung keeps the same shape: failing check first,
review, gate, commit check and implementation together. Note in STATE.md which
rung a packet used.

- **Pilot before a batch.** Repetitive delegated work goes out as one item first;
  the rest follow after that one is reviewed.
- **Escalate, don't retry.** A packet that fails twice, needs a direct
  `.yyp`/`.yy` edit, or would change a locked contract comes back to the main session.
```

---

## 8. Small fixes (one or two lines each)

- Top of file, lines 4-7: replace "There is no separate design doc or roadmap file yet — `README.md` covers the localization workflow, and `.planning/STATE.md` (GSD Core) is the working plan and session handoff." with "`README.md` covers the localization workflow; `.planning/ROADMAP.md` is the plan and `.planning/STATE.md` (GSD Core) is the session handoff."
- "The process" bullet "`.planning/STATE.md` is the single source of truth ... There is no `docs/ROADMAP.md`" (lines 152-154): replace the second sentence with "The plan is `.planning/ROADMAP.md`."
- "Naming conventions": add one line: "Test code: `Test_*` functions in `scr_test` (`Test_Suite_<Name>`, `Test_Eq`, `Test_Boot`). `Debug_*` stays the runtime debug overlay."
- `CLAUDE.md` (not AGENTS.md) has the same stale sentences ("There is no separate design doc or roadmap file", "No automated test runner exists", "No headless build (Igor) is available"). Replace them with pointers to the gate and `ROADMAP.md`.

---

## Line count check

Rule 1: 10 lines out, 10 in (0). Gate: 15 out, 19 in (+4). Team split: 10 out, 18 in (+8). Traps bullet: 5 out, 6 in (+1). New section: +7 (with blank line). Naming line: +1. Rule 5: -8. Fallback ladder: -9. Total: 212 + 4 + 8 + 1 + 7 + 1 - 8 - 9 = 216 lines.
