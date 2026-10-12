---
description: Start of any session in DD-Project-GameMaker — pick up where the project stands and keep building until done or blocked on the owner.
---

Continue building DD-Project-GameMaker on your own. Work through the open
items one after another until the work is done or you are blocked on
something only the owner can do.

## Ground rules (these override any skill's defaults)

1. Read `CLAUDE.md` and `AGENTS.md` first. AGENTS.md "The process: one owner
   per job" decides which skill does which job. Use every skill that owns a
   job. Do **not** use the ones it marks as not used.
2. `.planning/STATE.md` is where the work stands and the closest thing this
   repo has to a roadmap — there is no separate `docs/ROADMAP.md`. Keep it
   current; it is the only handoff between sessions.
3. Keep Opus usage low. You write the checks and contracts, review, run the
   gate and commit. **Codex writes implementations** (`mcp__codex__codex`
   for one packet; `codex exec` in git worktrees for several at once). The
   **local Ollama model** (`mcp__ollama__ask_local`) does mechanical text
   work. If Codex or the local model is unavailable, follow the fallback
   ladder in AGENTS.md (Claude subagents on Sonnet/Haiku) instead of
   stopping. GSD stays on the `balanced` profile. Keep replies to the owner
   short.

## Start of every session

1. **Onboarding check.** If `.planning/PROJECT.md` or `.planning/STATE.md`
   is missing, GSD was installed but never onboarded: run `/gsd-onboard`
   (it maps the codebase with parallel agents, reads existing docs and asks
   the owner about goals), then continue below. Do not invent goals.
2. Run `/gsd-progress` (or `/gsd-resume-work` if a pause handoff exists).
3. Run `git status`, `git worktree list`. There is no automated gate command
   (AGENTS.md "The gate") — confirm you know what the targeted check and
   the IDE-open verification look like for whatever is in progress. If
   worktrees are left over, land them or say why you can't.
4. Recover from a hard stop: if STATE.md names work in progress, or
   `git status`, WIP branches or worktrees show changes it doesn't mention,
   the last session ended abruptly. Work out what that work was, finish or
   discard it, and fix STATE.md before starting anything new. From here on,
   follow AGENTS.md Rule 5 (update STATE.md after every step that lands).

## The loop — repeat until done

Pick the next open item from `.planning/STATE.md`.

a. **Decide who decides.** If the item changes a save format, a shipped
   balance number set, or the game's design itself, run **grill-me** with
   the owner before planning. Never guess their answer. Otherwise
   `/gsd-discuss-phase`.
b. **Load the domain skills** the AGENTS.md table names for the item
   (`game-ui-ux`, `game-feel`, `save-systems`, `audio-design`,
   `create-game-assets`).
c. `/gsd-plan-phase`, then `/gsd-execute-phase`. Every task follows the
   fixed shape in AGENTS.md:
   1. `superpowers:test-driven-development`, applied per AGENTS.md Rule 1's
      table: write the check (GML assertion block, acceptance checklist, or
      Python check) and confirm it fails/flags for the right reason.
   2. Write the contract.
   3. Implementation to Codex in a worktree (`superpowers:using-git-worktrees`).
      Independent packets in parallel; pilot one before a batch. Codex edits
      `.gml` freely but never creates/renames/deletes a resource or hand-edits
      `.yyp`/`.yy`/`.resource_order` (AGENTS.md Rule 4).
   4. Run the targeted check yourself, then the gate: the check passes, and
      the project opens and runs in the GameMaker IDE without errors
      (ask the owner to confirm, or watch the output log if remote-
      controlling the IDE).
   5. `superpowers:requesting-code-review`, then
      `superpowers:receiving-code-review`.
   6. `superpowers:verification-before-completion`.
   7. Commit the check and implementation together, then
      `superpowers:finishing-a-development-branch` to clean up the worktree.
d. `/gsd-verify-work`, mark the item done, commit.
e. When a milestone is done: `/gsd-audit-milestone`, then
   `/gsd-complete-milestone`.

## When to stop and ask the owner

- Your context is getting full: `/gsd-pause-work`, commit, report in three
  lines.
- You need a design decision, credentials or API keys, a deploy, a git push,
  a history rewrite, or anything that deletes data: ask.
- You need the project actually opened and run in the GameMaker IDE and
  can't do it yourself: ask the owner to confirm it opens clean.
- **Never:** weaken, skip, or quietly drop a check to call something done;
  hand-edit `DD-Project.yyp`/`*.yy`/`DD-Project.resource_order` to add,
  rename, or delete a resource; hand-edit `datafiles/localization/localization.json`
  instead of rebuilding it from the workbook; force-push or `reset --hard`.

## Keeping this command current

Edit this file when the owner asks, or when a session shows a step is wrong,
missing, or obsolete (e.g. Igor becomes available locally and the gate
should run it). Rules for every agent belong in `AGENTS.md`; where the work
stands belongs in `.planning/STATE.md` — never here. Replace the step a
change supersedes instead of appending beside it, and commit it on its own
(`chore(continue): …`).

Start now with "Start of every session".
