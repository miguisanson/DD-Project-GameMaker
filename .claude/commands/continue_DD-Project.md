---
description: Start of any session in DD-Project — pick up where the project stands and keep building until done or blocked on the owner.
---

Continue building DD-Project on your own. Work through the open items one after
another until the work is done or you are blocked on something only the owner
can do.

## Ground rules (these override any skill's defaults)

1. Read `CLAUDE.md` and `AGENTS.md` first. AGENTS.md "The process: one owner
   per job" decides which skill does which job. Use every skill that owns a
   job. Do **not** use the ones it marks as not used.
2. `.planning/ROADMAP.md` is what to build and in what order; `.planning/STATE.md`
   is where the work stands. There is no roadmap document yet — building one is an early item for `/gsd-onboard`.
3. Keep Opus usage low. You write the checks and contracts, review, run the gate
   and commit. **Codex writes implementations** (`mcp__codex__codex` for one
   packet; `codex exec` in git worktrees for several at once). The **local model**
   (`mcp__ollama__ask_local`, qwen2.5-coder:7b) does mechanical text work for
   free — commit messages, docstrings, boilerplate, and summarising a long file
   before you read it. If Codex or Ollama is unavailable, follow the fallback
   ladder in AGENTS.md (Claude subagents on Sonnet/Haiku) instead of stopping. GSD stays on the `budget` profile. Keep
   replies to the owner short and in plain terms.

## Start of every session

1. **Onboarding check.** If `.planning/PROJECT.md` or `.planning/ROADMAP.md` is
   missing, GSD was installed but never onboarded: run `/gsd-onboard` (it maps
   the codebase with parallel agents, reads existing docs and asks the owner
   about goals), then continue below. Do not invent goals.
2. Run `/gsd-progress` (or `/gsd-resume-work` if a pause handoff exists).
3. Run `git status`, `git worktree list` and the gate from AGENTS.md
   (the localization build, then the owner's GameMaker build). If the gate is red, use `superpowers:systematic-debugging`
   before anything else. If worktrees are left over, land them or say why you can't.
4. Recover from a hard stop: if STATE.md names work in progress, or
   `git status`, WIP branches or worktrees show changes it doesn't mention,
   the last session ended abruptly. Work out what that work was, finish or
   discard it, and fix STATE.md before starting anything new. From here on,
   follow the AGENTS.md handoff rule (update STATE.md after every step that lands).

## The loop — repeat until done

Pick the next open item in ROADMAP order.

a. **Decide who decides.** If the item changes a contract, a locked check or
   type, a data model, or what the product is, run **grill-me** with the owner
   before planning. Never guess their answer. Otherwise `/gsd-discuss-phase`.
b. **Load the domain skills** the AGENTS.md table names for the item.
c. `/gsd-plan-phase`, then `/gsd-execute-phase`. Every task follows the fixed
   shape in AGENTS.md:
   1. `superpowers:test-driven-development`: the check, written and watched failing.
   2. Write the contract.
   3. Implementation to Codex in a worktree (`superpowers:using-git-worktrees`).
      Independent packets in parallel; pilot one before a batch.
   4. Run the targeted checks and the gate yourself.
   5. `superpowers:requesting-code-review`, then `superpowers:receiving-code-review`.
   6. `superpowers:verification-before-completion`.
   7. Commit the check and the implementation together, then
      `superpowers:finishing-a-development-branch` to clean up the worktree.
d. `/gsd-verify-work`, mark the item done, commit.
e. When a milestone is done: `/gsd-audit-milestone`, then `/gsd-complete-milestone`.

## When to stop and ask the owner

- Your context is getting full: `/gsd-pause-work`, commit, report in three lines.
- You need a design decision, credentials or API keys, a deploy, a git push,
  a history rewrite, or anything that deletes data: ask.
- **Never:** weaken, skip or delete a check to get green; commit secrets
  (`.env*`); force-push or `reset --hard`.
- **Never** hand-edit `datafiles/localization/localization.json`; it is generated
  from the workbook.
- **Never** claim GML changes are "tested" — say which acceptance check-list ran
  and who confirmed it. The owner runs the GameMaker build.
- **Never** ship machine-translated Korean without review.

## Keeping this command current

Edit this file when the owner asks, or when a session shows a step is wrong,
missing or obsolete. Rules for every agent belong in `AGENTS.md`; where the
work stands belongs in `.planning/STATE.md` — never here. Replace the step a
change supersedes instead of appending beside it, and commit it on its own
(`chore(continue): …`).

Start now with "Start of every session".
