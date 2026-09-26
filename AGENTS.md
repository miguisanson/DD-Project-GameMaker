# Rules for any agent working on this repo

These apply to every agent — Claude Code, Codex, a local model, or a human.
<<<<<<< Updated upstream
DD-Project is an 8-bit turn-based RPG built in GameMaker
(`DD-Project.yyp`). There is no separate design doc or roadmap file yet —
`README.md` covers the localization workflow, and `.planning/STATE.md` (GSD
Core) is the working plan and session handoff.

---

## Rule 1 — The check comes first. Always.

> **Never write the check after the implementation.**

This project has no automated test runner (no GML unit-test framework, no
`tools/` runner, no headless build under `E:\GameMaker` or
`%APPDATA%\GameMakerStudio2\Cache\runtimes` — none is currently downloaded).
"The test" is whatever can actually be checked for the kind of change:

| Work | Check you write first |
|---|---|
| Pure logic in a `scr_*` script (math, stats, combat formulas, DB lookups) | A GML assertion block that calls the function with known inputs and compares against expected output, run from a debug entry point (e.g. a `Debug_*` command in `scr_debug`, or a temporary `Create` event call removed before commit) so it prints pass/fail to the output log on game start |
| Behavior only observable in the running game (movement, dialogue, room transitions, UI, save/load) | A written acceptance checklist — the exact steps to reproduce and the exact expected result — committed in the task notes or `.planning/STATE.md` *before* touching the code, then walked through in the running game by the owner |
| Localization tooling (`tools/localization/*.py`) | A small Python check (sample input → expected output) run with `python`, per the existing script's own CLI |

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
=======

**DD-Project** — an 8-bit turn-based game built in **GameMaker** (`DD-Project.yyp`),
with a PortMaster / Anbernic RG SP export target and an xlsx-driven localization
pipeline. Notes: [docs/PORTMASTER_RG_SP.md](docs/PORTMASTER_RG_SP.md).

---

## Rule 1 — Write the check first. Always.

GameMaker has no test runner here, so "the test" is whichever of these fits the
item — but it is still **written first, and watched failing first**:

1. Read the goal of the item.
2. Write the check from that goal.
3. **Run it and watch it fail** for the right reason. Show the output, or for an
   acceptance check-list, have the owner confirm the current behaviour is wrong.
4. Implement until it passes. Run the same check again.
5. Then the gate.

Never write the check afterwards to describe what you built, and never soften one
to make it pass. If you cannot state a check for the goal, the goal is
underspecified — stop and say so.

| Work | The check you write first |
|---|---|
| Localization strings, keys, a new language | A run of `tools/localization/build_localization.py`, which validates the workbook and fails on a bad schema or missing key |
| A tooling or pipeline script under `tools/` | A Python assertion or a `--report-json` output compared against an expected file |
| Game logic in `scripts/` or `objects/` | A written acceptance check-list in the item: exact inputs, exact expected on-screen result. The owner runs it in the IDE and confirms |
| A room or encounter | The check-list plus a screenshot of the intended state |
| A bug | The reproduction steps, written down and confirmed failing, before the fix |

**Choosing a real test runner for the GML side is an early roadmap item.** Until
it exists, do not claim a change is "tested" — say which check-list was run and
who confirmed it.

## Rule 2 — Run only the checks that matter

```bash
python3 tools/localization/build_localization.py \
  --xlsx datafiles/localization/game_text.xlsx \
  --json datafiles/localization/localization.json
```

That is the fast one. The GameMaker build and the acceptance check-lists happen
once, at the end.

## Rule 4 — The workbook is the source of truth for text

`datafiles/localization/game_text.xlsx` (sheet `strings`, columns `ref` / `en` /
`ko`) is canonical. `datafiles/localization/localization.json` is a **build
artifact** — generated, never hand-edited. Editing the JSON gets silently
overwritten on the next build and the change is lost.

What enforces it: `build_localization.py` regenerates the JSON from the workbook
every run, so any hand edit disappears the moment anyone builds.
>>>>>>> Stashed changes

## Rule 3 — Stay inside the item

Do the item you were given. Noticing adjacent work is good; doing it is not —
list it at the end. Read the files the item needs, not the whole repo.

<<<<<<< Updated upstream
## Rule 4 — The IDE owns resource identity

Never hand-edit `DD-Project.yyp`, any `*.yy` file, or `DD-Project.resource_order`
to create, rename, delete, or relink a resource (object, sprite, sound, room,
script, font). Those files encode GUIDs and cross-references the IDE
maintains; a hand edit that goes out of sync silently breaks the project and
often isn't caught until GameMaker fails to open it. `.gml` code files are
fair game for direct editing — Codex or any agent can edit `.gml` freely.
Resource creation/rename/deletion goes through the GameMaker IDE, and if a
`.yy`/`.yyp` entry must change to match (e.g. after the owner renames
something in the IDE), keep every reference to that resource — `.yyp`,
`.yy`, `resource_order`, and every `.gml` call site — consistent in the same
change. If you are not certain an edit keeps them consistent, stop and ask.

=======
>>>>>>> Stashed changes
## Rule 5 — Leave the repo ready for whoever comes next

Any session can end without warning (usage limit, crash, the owner switching
agents), so an agent never waits until the end to write things down. Keep
`.planning/STATE.md` current as you go:

<<<<<<< Updated upstream
- **After every step that lands** (a check written, an implementation
  passing, a review done, a commit), update STATE.md's *Current Position*:
  what is done, what is in progress and on which branch or worktree, the
  exact next action, and anything learned that is not obvious from the code.
  Commit it with the work, or on its own if nothing else changed.
- **Before a long or risky step** (a delegated packet, a big refactor, a run
  in the background), write down first what you are about to do and where
  the output will go, so a session that dies halfway through can be picked
  up.
- **Never leave work only in your context.** Half-finished code gets a WIP
  commit on a branch (not `v1.8`, the current working branch) or a note in
  STATE.md naming the files it touched. Worktrees and background jobs are
  listed by path.
- **If you know the session is ending**, run `/gsd-pause-work` (Claude) or
  write the same thing by hand into STATE.md (any other agent).

The next agent starts with `/continue_DD-Project-GameMaker`, or, outside
Claude, by reading this file and `.planning/STATE.md` and running
`git status`.
=======
- **After every step that lands** (a check written, an implementation passing,
  a review done, a commit), update STATE.md's *Current Position*: what is
  done, what is in progress and on which branch or worktree, the exact next
  action, and anything learned that is not obvious from the code. Commit it
  with the work, or on its own if nothing else changed.
- **Before a long or risky step** (a delegated packet, a big refactor, a run
  in the background), write down first what you are about to do and where the
  output will go, so a session that dies halfway through can be picked up.
- **Never leave work only in your context.** Half-finished code gets a WIP
  commit on a branch (not the main branch) or a note in STATE.md naming the
  files it touched. Worktrees and background jobs are listed by path.
- **If you know the session is ending**, run `/gsd-pause-work` (Claude) or
  write the same thing by hand into STATE.md (any other agent).

The next agent starts with `/continue_DD-Project`, or, outside Claude, by reading
this file and `.planning/STATE.md` and running `git status`.
>>>>>>> Stashed changes

---

## The gate

<<<<<<< Updated upstream
No headless/CLI build (Igor) is available on this machine — no runtime is
cached under `%APPDATA%\GameMakerStudio2\Cache\runtimes`, only the IDE
itself at `E:\GameMaker`. The gate is:

1. The targeted check for the change (Rule 1) passes.
2. **The project opens and runs in the GameMaker IDE without errors** —
   verified by the owner (or, if remote-controlling the IDE, by watching the
   output log for compile/runtime errors on launch). Report this as a
   specific ask, not an assumption.
3. If `tools/localization/*.py` was touched: `python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json` runs clean, and `python tools/localization/lint_hardcoded_text.py` reports no new hardcoded strings.

If Igor becomes available locally later (a runtime gets cached), prefer it
for a real headless compile check and update this section.
=======
Nothing merges that has not passed all three:

```bash
# 1. Localization workbook validates and the runtime JSON rebuilds
python3 tools/localization/build_localization.py \
  --xlsx datafiles/localization/game_text.xlsx \
  --json datafiles/localization/localization.json
```

2. **The project compiles in the GameMaker IDE** — the owner runs it, because
   GameMaker has no headless build on this machine.
3. **The item's acceptance check-list passes**, confirmed by the owner.

Steps 2 and 3 are the owner's; ask for them, do not claim them.

## Where things are

| | |
|---|---|
| `DD-Project.yyp` | The GameMaker project. Open this. |
| `objects/` (65) | Game objects and their events. |
| `scripts/` (28) | GML scripts. |
| `rooms/` (14) | Rooms. |
| `sprites/` (134), `sounds/` (126) | Art and audio. |
| `datafiles/localization/game_text.xlsx` | **Canonical** game text. |
| `tools/localization/` | The workbook → JSON pipeline and the legacy migrator. |
| `docs/PORTMASTER_RG_SP.md` | Fixed-resolution and handheld export notes. |

## Traps

- **Never hand-edit `localization.json`.** It is regenerated from the workbook.
- The README's tool commands use Windows `^` line continuations. On the Mac use
  `\` instead, or put the command on one line.
- The xlsx has a **legacy schema** still supported by the tooling. New work uses
  the minimal `ref` / `en` / `ko` columns; check which one a sheet is in before
  editing it.
- GameMaker rewrites `.yy` files wholesale when it saves. Do not hand-edit them
  while the IDE is open, and expect noisy diffs.
- The Korean autofill pass uses OpenAI and is a **draft only** — every generated
  string needs review before it ships.
>>>>>>> Stashed changes

## How the team splits work

| Agent | Does | Does not |
|---|---|---|
<<<<<<< Updated upstream
| **Claude** | Architecture, contracts, writing the failing check, reviewing and merging, anything touching save data or licensing | Grind through bulk mechanical work |
| **Codex** | Makes a written failing check pass; implements a script or object behavior against a stated contract; works in its own git worktree | Change a check to match its code; widen scope; create/rename resources outside the IDE |
| **Local model** (Ollama, `mcp__ollama__ask_local`) | Mechanical work: dialogue/string drafts, commit messages, summarizing long files | Design, multi-file reasoning, anything unverified |

The failing check is the handoff: a precise, as-machine-checkable-as-possible
spec. Every delegated result is reviewed and gated before it merges.

### When an agent is unavailable — the fallback ladder

Best is all three. If one is out — Codex at its usage limit or erroring,
Ollama not running — the work moves down the ladder instead of stopping:

1. **Codex unavailable:** implementation goes to a **Claude subagent on a
   cheaper model** (`Agent` with `model: "sonnet"`) in the same worktree,
   with the same brief Codex would get. Independent packets run in parallel.
   The main Claude session keeps to checks, contracts, review and the gate.
2. **Local model unavailable:** its mechanical work goes to a Claude
   subagent on `haiku` (or `sonnet` when it needs judgement).
3. **Both unavailable:** Claude subagents do both, cheapest model that can.
4. **Only the main session:** it implements inline, in the smallest
   packets.

Every rung keeps the same shape: failing check first, review, gate, commit
check and implementation together. Return to Codex as soon as it is back.
Note in `.planning/STATE.md` which rung a packet used.

- **Pilot before a batch.** Repetitive delegated work (e.g. a batch of enemy
  stat tweaks) goes out as one item first; the rest follow only after that
  one is reviewed.
- **Escalate, don't retry.** If a packet fails twice, or passing it would
  mean editing a `.yyp`/`.yy` file directly, or changing a locked contract,
  it comes back to Claude.

### The process: one owner per job

Several installed skill sets overlap if used naively, so every job has
exactly one owner. When a skill's default disagrees with this file, this
file wins.
=======
| **Claude** | Architecture, types and contracts, writing the failing check, reviewing and merging, anything touching security, data or licensing | Grind through bulk mechanical work |
| **Codex** | Makes a written failing check pass; implements a module or screen against a stated contract; works in its own git worktree | Change a check to match its code; widen scope |
| **Local model** (Ollama, `mcp__ollama__ask_local`, qwen2.5-coder:7b) | Free mechanical work: boilerplate, summaries of long text, commit messages, docstrings | Design, multi-file reasoning, anything unverified |

All three run on both machines — the MacBook (M3, 16 GB) and the Windows PC both
serve qwen2.5-coder:7b through Ollama. The failing check is the handoff: a precise,
checkable spec. Every delegated result is reviewed and gated before it merges.

### When an agent is unavailable — the fallback ladder

If one is out — Codex at its usage limit or erroring, Ollama not running — the
work moves down the ladder instead of stopping:

1. **Codex unavailable:** implementation goes to a **Claude subagent on a
   cheaper model** (`Agent` with `model: "sonnet"`) in the same worktree, with
   the same brief Codex would get. Independent packets run in parallel.
   The main Claude session keeps to checks, contracts, review and the gate.
2. **Local model unavailable** (Ollama not running, or the model not pulled):
   its mechanical work goes to a Claude subagent on `haiku` (or `sonnet` when it
   needs judgement). Start it with `open -a Ollama` before falling back.
3. **Both unavailable:** Claude subagents do both, cheapest model that can.
4. **Only the main session:** it implements inline, in the smallest packets.

Every rung keeps the same shape: failing check first, review, gate, commit the
check and the implementation together. Return to Codex as soon as it is back.
Note in `.planning/STATE.md` which rung a packet used.

- **Pilot before a batch.** Repetitive delegated work goes out as one item
  first; the rest follow only after that one is reviewed.
- **Escalate, don't retry.** If a packet fails twice, or passing it would
  change a locked type, contract or check, it comes back to Claude.

### Parallel Codex packets

```bash
git worktree add -b <branch> /Users/miguelsanson/Projects/DD-Project-wt/<short> HEAD
codex exec -C "/Users/miguelsanson/Projects/DD-Project-wt/<short>" -s workspace-write \
  --add-dir "/Users/miguelsanson/Projects/DD-Project/.git" --skip-git-repo-check \
  -o <short>.out.md - < <short>.prompt.md
```

The prompt starts with: read `AGENTS.md`; the check is the spec, **do not modify
it**; stop and explain if something looks wrong; touch only the named files.
**Codex's sandbox cannot spawn processes** — it cannot run the checks. Always run
them yourself before landing a packet. Remove the worktree after landing.

### The process: one owner per job

Several installed skill sets overlap if used naively, so every job has exactly
one owner. When a skill's default disagrees with this file, this file wins.
>>>>>>> Stashed changes

| Job | Owner | Not used for this job |
|---|---|---|
| Memory across sessions, the phase loop, context rot | **GSD Core** (local install, `budget` model profile). `/gsd-progress` or `/gsd-resume-work` to start; per phase `/gsd-discuss-phase` → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-verify-work`; `/gsd-pause-work` to stop; `/gsd-complete-milestone` | Superpowers `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`; hand-written handoff files |
<<<<<<< Updated upstream
| Discipline inside a task: check first, debugging, proving it works, code review, worktrees, closing a branch | **Superpowers**: `test-driven-development` (applied per Rule 1's table, not literal unit tests), `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `finishing-a-development-branch` | GSD `/gsd-add-tests`, `/gsd-debug`, `/gsd-code-review`, `/gsd-audit-fix` |
| Stress-testing a design decision that is the owner's to make | **grill-me** (user-level skill, never committed here: it has no licence) | ad-hoc question batches |
| Writing implementation code | **Codex**, with Superpowers installed in Codex too; when Codex is unavailable, the fallback ladder above | Claude subagents writing implementations while Codex is available, including GSD's executor |
| Mechanical text work | **Local model** (Ollama) | Opus |
| Domain craft: HUD/menus, game feel, saves, audio, art | User-level skills `game-ui-ux` (HUD/menu layout, anchors, resolution scaling, input focus — load for any screen or overlay work), `game-feel` (screen shake, hit-stop, tweened motion, squash & stretch — load when a hit, jump, pickup, or death should feel more responsive), `save-systems` (load for `scr_save`/`scr_save_menu` work: slot format, atomic writes, schema versioning), `audio-design` (load for `scr_sfx`/`scr_debug`-adjacent sound-bus work: mixing, ducking, SFX variation), `create-game-assets` (load when new sprites/tiles/UI art are being planned, not just placed) | Rules questions specific to this game's own systems win over generic game-design advice from a skill |

- **`.planning/STATE.md` is the single source of truth for where work
  stands right now.** There is no `docs/ROADMAP.md` in this repo; if the
  owner starts one, update this row.
- **The task shape inside `/gsd-execute-phase` is fixed:** (1) Claude writes
  the failing check per Rule 1 and confirms it fails for the right reason;
  (2) Claude writes the contract and hands implementation to Codex in a
  worktree; (3) Claude runs the targeted check and the gate itself; (4)
  `requesting-code-review` on the diff; (5) `verification-before-completion`;
  (6) commit check and implementation together. If GSD's executor starts
  writing the implementation in a Claude subagent while Codex is available,
  stop and route the task to Codex.
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
options/    per-platform GameMaker build options (android, etc.)
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

## Traps

- **No CLI/headless build is available.** `E:\GameMaker` is the IDE
  install, not a runtime cache; `%APPDATA%\GameMakerStudio2\Cache\runtimes`
  is currently empty even though `runtime.json` names an active runtime
  version (`2024.14.3.260`) — it isn't downloaded locally. Don't assume
  Igor exists; check the runtimes cache again before relying on it.
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
=======
| Discipline inside a task: check first, debugging, proving it works, code review, worktrees, closing a branch | **Superpowers**: `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `finishing-a-development-branch` | GSD `/gsd-add-tests`, `/gsd-debug`, `/gsd-code-review`, `/gsd-audit-fix` |
| Stress-testing a design decision that is the owner's to make | **grill-me** (user-level skill, never committed: it has no licence) | ad-hoc question batches |
| Writing implementation code | **Codex**, else the fallback ladder above | Claude subagents writing implementations while Codex is available, including GSD's executor |
| Mechanical text work | **Local model** (Ollama, `mcp__ollama__ask_local`); a `haiku` subagent only if Ollama is down | Opus |
| Domain craft: HUD and menus, game feel, saves, audio, art | **Game-dev skills**: `game-ui-ux`, `game-feel`, `save-systems`, `audio-design`, `create-game-assets` | guessing at feel or layout |

**The task shape inside `/gsd-execute-phase` is fixed:** (1) Claude writes the
failing check and watches it fail for the right reason; (2) Claude writes the
contract and hands implementation to Codex in a worktree; (3) Claude runs the
targeted checks and the gate itself; (4) `requesting-code-review` on the diff;
(5) `verification-before-completion`; (6) commit the check and the implementation
together. If GSD's executor starts writing the implementation in a Claude
subagent while Codex is available, stop and route the task to Codex.
>>>>>>> Stashed changes
