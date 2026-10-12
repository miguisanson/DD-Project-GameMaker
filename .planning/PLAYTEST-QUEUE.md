# Playtest queue

What the owner needs to play, test or decide after the agents worked while the owner was away. Used by `IMPROVE.md`. It starts empty.

## How this file works

- Each feature or fix that the owner has to judge by playing gets **one entry**, written in the same commit that lands on branch `next`.
- Each entry has the exact steps, the expected result, the build id, and what to say afterwards.
- The **unplayed features** number in the `STATE.md` header is the count of entries still marked `unplayed`. At about 8, the agents stop building features and only hunt bugs (D12).
- When you play, mark each entry `good`, `bad` or `change` (and add a few words). Then say "merge the good ones". Good ones go from `next` to `v1.9` only on your word. Bad ones are reverted on `next` and become a row in `ISSUES.md`.
- The agents never write a verdict for you. A line saying `played` or `good` is written by you (or by the agent only because you said it in chat, with the date).

**Build to play:** (none yet) | **Branch:** `next` | **Unplayed:** 0 / 8

## Entry template (copy for each new entry)

```
### Q-001 | feature or fix name | commit abc1234 | build 2026-10-14-abc1234
- Status: unplayed   (you change it to: good / bad / change)
- Requirement / issue: (REQ id or I-id)
- Automated proof already run: (checks, R-ids, build id, screenshot names)
- Steps (about 2 minutes):
  1. ...
  2. ...
- Expected: ...
- Look out for: (what could be wrong that a bot cannot see: feel, speed, sound, readability)
- Your note: 
```

## Entries

(none yet)

## Questions for the owner

Design questions the agents could not answer from `DECISIONS.md` or the research. They stay parked until you answer. Do not answer in your head; say them in chat so they get written down.

(none yet)

## IDE tasks for the owner

Work that needs a new or changed resource (object, sprite, room, script, font). Agents cannot do these (AGENTS.md Rule 4). Each line: what, why, which requirement.

(none yet)

## Balance proposals (need your yes)

Numbers the agents think should change, with simulator before and after. Nothing here is applied until you approve it by id (D13).

| Proposal | What changes | Before | After | Why (simulator metric out of band) | Your answer |
|---|---|---|---|---|---|
| (none yet) | | | | | |
