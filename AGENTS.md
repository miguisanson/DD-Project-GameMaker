# Rules for any agent working on this repo

These apply to every agent — Claude Code, a Claude subagent, a local model, or a human.
DD-Project is an 8-bit turn-based RPG built in GameMaker
(`DD-Project.yyp`). The game is Windows-only (D52: no web/HTML5 build, no Android).
`README.md` covers the localization workflow; `.planning/ROADMAP.md` is the plan
and `.planning/STATE.md` (GSD Core) is the session handoff.

---

## Rule 1 — The check comes first. Always.

> **Never write the check after the implementation.**

The project has a headless harness (Igor build plus `Test_Suite_*`; see "The
gate"). "The check" is whatever can actually be checked for the kind of change:

| Work | Check you write first |
|---|---|
| Pure logic in a `scr_*` script (math, stats, combat formulas, DB lookups, save) | A failing case in a committed `Test_Suite_*` (in `scr_test`), with expected values taken from the spec or the owner, not copied from the code's output. Run with `-runtests` through `tools/automation/run_tests.ps1`. No temporary Create-event calls. |
| Behaviour in the running game (movement, dialogue, room change, battle flow, save/load, UI) | A scripted scenario (`-bot` or `-smoke`) that reaches it through real key input and asserts state; for screens also `-shots`, then open the PNGs. |
| Feel and balance (QTE timing, animation speed, numbers) | The owner's number first (grill-me), a ms or frame measurement in the bot, then a short owner checklist in `.planning/PLAYTEST-QUEUE.md`. |
| Localization tooling (`tools/localization/*.py`) | A small Python check (sample input, expected output) run with `python`, per the script's own CLI. |

1. Read the goal — what the change should do and how success is observed.
2. Write the check from that goal, before any implementation.
3. **Run or state it and confirm it fails/flags for the right reason** — a
   wrong value or "not implemented," not a typo or missing import.
4. Implement until it passes. Re-run the same check.
5. Then the gate.

Do not weaken, skip, or quietly drop a check to call something done. If you
cannot state a concrete check for the goal, stop and say so — the goal is
underspecified.

## Rule 2 — Run only the check that matters

Run the one GML assertion block, checklist step, or Python script for the
thing you're changing while working. The full gate (below) once, at the end.

## Rule 3 — Stay inside the item

Do the item you were given. Noticing adjacent work is good; doing it is not —
list it at the end. Read the files the item needs, not the whole repo.

## Rule 4 — The IDE owns resource identity

Never hand-edit `DD-Project.yyp`, any `*.yy` file, or `DD-Project.resource_order`
to create, rename, delete, or relink a resource (object, sprite, sound, room,
script, font). Those files encode GUIDs and cross-references the IDE
maintains; a hand edit that goes out of sync silently breaks the project and
often isn't caught until GameMaker fails to open it. `.gml` code files are
fair game for direct editing — any agent can edit `.gml` freely.
Resource creation/rename/deletion goes through the GameMaker IDE, and if a
`.yy`/`.yyp` entry must change to match (e.g. after the owner renames
something in the IDE), keep every reference to that resource — `.yyp`,
`.yy`, `resource_order`, and every `.gml` call site — consistent in the same
change. If you are not certain an edit keeps them consistent, stop and ask.

## Rule 5 — Leave the repo ready for whoever comes next

Any session can end without warning. Keep `.planning/STATE.md` current as you go:

- **After every step that lands**, update its header and *Current Position*: what
  is done, what is in progress (branch or worktree), the exact next action, and
  anything learned that is not obvious from the code. Commit it with the work.
- **Before a long or risky step** (a delegated packet, a big refactor, a
  background run), write down what you are about to do and where the output goes.
- **Never leave work only in your context.** Half-finished code gets a WIP commit
  on a branch (not `v1.9`; unattended work goes on `next`) or a STATE.md note
  naming the files. List worktrees and background jobs by path.
- **If the session is ending**, run `/gsd-pause-work` (Claude) or write the same
  into STATE.md by hand.

The next agent starts with `/continue_DD-Project-GameMaker`, or reads this file,
`.planning/STATE.md` and `git status`.

---

## The gate

Run `tools/automation/run_tests.ps1` (Igor, runtime 2024.14.3.260; details in
`.planning/research/automation-igor.md`): `powershell -NoProfile -ExecutionPolicy Bypass -File tools/automation/run_tests.ps1 -Mode fast`.
`-Mode fast` (default) is build plus `-runtests`; `-Mode full` adds `-smoke`, `-bot` and `-shots` once each is marked implemented (today only `-runtests` runs). The negative control (`-NegativeControl`) must print GATE FAIL. The gate is:

1. The targeted check for the change (Rule 1) passes.
2. Igor compiles with exit 0 and no `Error :` lines (VM Release; `--cache` and
   `--temp` on E:; built from a scratch copy, never inside the repo).
3. `-runtests` (all `Test_Suite_*` pass) and, in full mode, `-smoke` (no runtime
   error) pass. Igor does not catch unknown functions or variables; the smoke run
   does. A missing result file, a hang or a leftover game process is a FAIL.
4. The negative control is still red. Run it whenever the wrapper changes.
5. UI or layout changes: `-shots`, then open the PNGs at every size.
6. The `REGRESSION.md` entries for the touched systems ran on this build id.
7. If localization tooling or keys changed: `python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json` runs clean, and `python tools/localization/lint_hardcoded_text.py` reports no new hardcoded strings.
8. Feel, audio, art and controller input: ask the owner for a specific L5 check.

Run only what the change touches (D62): `-Mode fast` plus the one relevant `-Only <mode>`; `-Only shots` only for screen/UI work; plain `-Mode full` once per merge to `next` and before a playtest stop, never while the owner is using the PC. A green compile alone is not enough. Automated runs set `LOCALAPPDATA` to a scratch folder and never touch `%LOCALAPPDATA%\DD_Project`.

## Improvement mode, regressions, issues

- `.planning/IMPROVE.md`: how unattended work runs (branch `next`, one commit per feature, 8 unplayed features then bug-hunt only, stop conditions). Start with `/improve_DD-Project-GameMaker` (created in Phase 1 wave 1D; until then, read IMPROVE.md).
- `.planning/REGRESSION.md`: every fixed bug adds an `R-###` entry before its fix merges. An entry with no run on the current build id is unchecked, not green.
- `.planning/ISSUES.md`: the one triage table. Verbatim notes stay in `.planning/research/playtest-notes.md`. A bug closes only when the reporter's repro passes.
- `.planning/BOARD.md`: the owner's board (Now, Next, Later, Done, Waiting on you), updated with `STATE.md` after every step that lands.
- `.planning/PLAYTEST-QUEUE.md`: what the owner must play. Nothing merges to `v1.9` before the owner plays it. Balance numbers change only through an owner-approved proposal.

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

### The process: one owner per job

Several installed skill sets overlap if used naively, so every job has
exactly one owner. When a skill's default disagrees with this file, this
file wins.

| Job | Owner | Not used for this job |
|---|---|---|
| Memory across sessions, the phase loop, context rot | **GSD Core** (local install, `balanced` model profile). `/gsd-progress` or `/gsd-resume-work` to start; per phase `/gsd-discuss-phase` → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-verify-work`; `/gsd-pause-work` to stop; `/gsd-complete-milestone` | Superpowers `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`; hand-written handoff files |
| Discipline inside a task: check first, debugging, proving it works, code review, worktrees, closing a branch | **Superpowers**: `test-driven-development` (applied per Rule 1's table, not literal unit tests), `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `finishing-a-development-branch` | GSD `/gsd-add-tests`, `/gsd-debug`, `/gsd-code-review`, `/gsd-audit-fix` |
| Stress-testing a design decision that is the owner's to make | **grill-me** (user-level skill, never committed here: it has no licence) | ad-hoc question batches |
| Writing implementation code | **Sonnet subagent** in a worktree, else the fallback ladder above | The main Opus session writing implementations |
| Mechanical text work | **Local model** (Ollama) | Opus |
| Domain craft: HUD/menus, game feel, saves, audio, art | User-level skills `game-ui-ux` (HUD/menu layout, anchors, resolution scaling, input focus — load for any screen or overlay work), `game-feel` (screen shake, hit-stop, tweened motion, squash & stretch — load when a hit, jump, pickup, or death should feel more responsive), `save-systems` (load for `scr_save`/`scr_save_menu` work: slot format, atomic writes, schema versioning), `audio-design` (load for `scr_sfx`/`scr_debug`-adjacent sound-bus work: mixing, ducking, SFX variation), `create-game-assets` (load when new sprites/tiles/UI art are being planned, not just placed) | Rules questions specific to this game's own systems win over generic game-design advice from a skill |

- **`.planning/STATE.md` is the single source of truth for where work
  stands right now.** The plan is `.planning/ROADMAP.md`.
- **The task shape inside `/gsd-execute-phase` is fixed:** (1) Claude writes
  the failing check per Rule 1 and confirms it fails for the right reason;
  (2) Claude writes the contract and hands implementation to a `sonnet`
  subagent in a worktree; (3) Claude runs the targeted check and the gate
  itself; (4) `requesting-code-review` on the diff; (5)
  `verification-before-completion`; (6) commit check and implementation
  together. Implementation goes to a `sonnet` subagent in a worktree; GSD's
  executor on the `balanced` profile is acceptable.
- **grill-me runs only on decisions that change a save format, a shipped
  balance number set (stat curves, difficulty profiles), or the game's
  design itself** — not routine bug fixes or content additions.

## Where things are

```
objects/    obj_* — behavior (Create/Step/etc. .gml per object, plus its .yy)
scripts/    scr_* — one folder per script asset, .gml holds one or more functions
rooms/      rm_*  — levels/screens, each a folder with a room.yyy-style layout
sprites/    art assets; not all prefixed (see naming note below)
sounds/     audio assets; not all prefixed
fonts/      font assets (e.g. retro_gaming)
datafiles/  runtime data, incl. datafiles/localization/ (game_text.xlsx, localization.json)
tools/      off-engine tooling; tools/localization/*.py for the loc pipeline
options/    GameMaker build options per platform; only Windows is built and shipped (D52)
```

## Naming conventions found

- Objects: `obj_` prefix (`obj_player`, `obj_final_boss`, `obj_chest_lv1`).
- Scripts: `scr_` prefix, one asset per logical module (`scr_combat`,
  `scr_save`, `scr_localization`); each `.gml` file holds many related
  `function`s, not one function per file.
- Rooms: `rm_` prefix (`rm_floor1`, `rm_battle`, `rm_cutscene`).
- Sprites and sounds: **not consistently prefixed** — named descriptively
  (`archer_down`, `Abstract1`, `barrel_asset`). Don't assume a `spr_`/`snd_`
  prefix when adding new ones; follow the sibling assets in the same folder.
- Constants/enums: `#macro` in `scr_macros`, `ALL_CAPS_WITH_UNDERSCORES`
  (`STAT_MIN`, `DIFFICULTY_HARD`, `BSTATE_PLAYER_ATTACK`).
- Debug/runtime-toggle functions: `Debug_*` in `scr_debug` (this is a
  runtime debug overlay, not a test framework — see the gate above).
- Test code: `Test_*` functions in `scr_test` (`scripts/scr_test/scr_test.gml`; `Test_Suite_<Name>`, `Test_Eq`, `Test_Boot`). `Debug_*` stays the runtime debug overlay.

## Traps

- **Igor is available but easy to misuse.** Always pass `--cache` and `--temp`
  on E:, build from a scratch copy, run with `LOCALAPPDATA` redirected, kill the
  game with `Stop-Process -Id` after a timeout, and never use Igor `Run` without
  an outer kill (`-t` does not stop the game). Never print
  `%APPDATA%\GameMakerStudio2\um.json` (tokens). Detect crashes from the log or
  result file: `game_end(n)` inside the unhandled-error handler returns exit 0.
- **`*.resource_order` and `*.old` files are gitignored** and regenerated by
  the IDE — never hand-author them, never worry about them being "missing"
  from a diff.
- **Localization has its own pipeline** — read `README.md` before touching
  anything under `datafiles/localization/` or `tools/localization/`.
  `localization.json` is a build artifact of `game_text.xlsx`; edit the
  workbook (or use the migrate/bootstrap scripts), never hand-edit the JSON.
- **`.claude/commands/` already holds GSD's own commands** (`gsd-*.md`) —
  this repo's own command lives alongside them as
  `continue_DD-Project-GameMaker.md`.
