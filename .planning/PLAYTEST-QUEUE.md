# Playtest queue

What the owner needs to play, test or decide after the agents worked while the owner was away. Used by `IMPROVE.md`. It starts empty.

## How this file works

- Each feature or fix that the owner has to judge by playing gets **one entry**, written in the same commit that lands on branch `next`.
- Each entry has the exact steps, the expected result, the build id, and what to say afterwards.
- The **unplayed features** number in the `STATE.md` header is the count of entries still marked `unplayed`. At 15 (or right after a combat-feel feature) the agents stop and wait (D53/D54).
- When you play, mark each entry `good`, `bad` or `change` (and add a few words). Then say "merge the good ones". Good ones go from `next` to `v1.9` only on your word. Bad ones are reverted on `next` and become a row in `ISSUES.md`.
- The agents never write a verdict for you. A line saying `played` or `good` is written by you (or by the agent only because you said it in chat, with the date).

**Build to play:** `E:\Games\DD-Project Playtest\bcedf32-20261014\DD-Project.exe` (build id shown bottom-right of the title screen) | **Branch:** `next` | **Unplayed:** 9 / 15

**Before you play:** your real saves are backed up in `E:\Games\DD-Project Playtest\save-backup-2026-10-14`. Keep GameMaker closed. About 30-40 minutes in total. Write notes in chat or under each entry.

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

### Q-001 | Screen never breaks after cutscenes/dialogue | build bcedf32-20261014
- Status: unplayed
- Issue: I-051 (DISP), H1/H2
- Automated proof: smoke display steps (0 re-layouts over room changes, transitions, cutscene end, dialogue end), shots at 480x432 / 1000x700 / 1920x1080.
- Steps: start a New Game, watch the intro cutscene to the end, talk to anyone, walk through 3-4 doors, change the window size in Settings, do it again.
- Expected: the picture never jumps, shrinks, offsets or flashes; the last cutscene image stays until the fade is black.
- Look out for: anything odd at your usual window size; text size (now 1.0/1.5/2.0x at window scale 3/4/5 — readable?).
- Your note:

### Q-002 | Sliding bar for the basic attack | build bcedf32-20261014
- Status: unplayed
- Decision: D56, D60, D61, D20
- Automated proof: Test_Suite_Qte, bot perfect/fail variants, shot_qte_bar.png.
- Steps: fight 5+ battles using Attack; try pressing early, late, on the bright core, and not at all.
- Expected: a cursor sweeps the bar; grade word (PERFECT/GOOD/OK/WEAK) with its own sound; Perfect has a tiny freeze + shake; you never fully miss.
- Look out for: is the sweep speed right (sword 1.1 s)? Perfect zone too tight/loose? Does it feel better than the ring?
- Your note:

### Q-003 | Arrow sequences for skills | build bcedf32-20261014
- Status: unplayed
- Decision: D57, D58, D61
- Automated proof: Test_Suite_Qte arrow grader, bot casts per class, shot_qte_arrows.png.
- Steps: use every skill you have a few times (Wound DRU, Hilt Bash DLRU, Horizontal Slash LRLRD, Fireball URDL, Ice Spear UDLDU...). Make a mistake on purpose once.
- Expected: arrows show, a time bar drains; wrong press shakes and costs time; the skill always fires; grade word + sound.
- Look out for: time limits (3.4/4.2/5.0 s for 3/4/5 arrows) and the Perfect cut-off; are sequences memorable?
- Your note:

### Q-004 | Defence bar on big enemy attacks | build bcedf32-20261014
- Status: unplayed
- Decision: D7, D59, D21
- Automated proof: bot defended Ramming, shot_qte_telegraph.png, shot_qte_defence.png.
- Steps: fight a Snake (Bite), Spider (Poison Fangs) or the floor-5 mini boss (Ramming).
- Expected: "!" + attack name, then a sliding bar to block. Perfect takes 25% damage and resists the status; Weak takes full. A status never lasts longer than normal.
- Look out for: is the warning long enough (0.4 s)? Is blocking satisfying?
- Your note:

### Q-005 | Skills are fast (~1 s) and effects sized right | build bcedf32-20261014
- Status: unplayed
- Decision: D55; issues BUG-05/06, I-052
- Automated proof: bot measures every skill ≤66 frames; shot_fx_* per skill.
- Steps: cast Ice Spear, Hilt Bash, Foresight and a buff.
- Expected: about 1 second from press to your next choice; the Foresight eye is small, beside the enemy; buff animations play on you.
- Look out for: anything that now feels too rushed.
- Your note:

### Q-006 | Poison you can feel | build bcedf32-20261014
- Status: unplayed
- Issue: BUG-08
- Steps: get poisoned (Spider) and take a few turns.
- Expected: each tick shows a log line, a sound and an HP-bar flash.
- Your note:

### Q-007 | Enemies: sight, "!", pathfinding, personalities | build bcedf32-20261014
- Status: unplayed
- Decision: D63, D66, D67; issues I-047, I-050
- Automated proof: Test_Suite_Nav, bot parts A-F (path around walls, no overlap, sight blocked by walls, search then go home).
- Steps: on floors 1-3 approach enemies from behind walls and in the open; run away after being spotted.
- Expected: "!" pops when they see you, a faint dotted range when you're near; they walk around walls, don't get stuck, don't stack; slower than you (wolves match you); they search, then go home.
- Look out for: sight range (3-5 tiles) and speeds feel fair? Any enemy still stuck?
- Your note:

### Q-008 | Player movement polish + run + bump + prompt | build bcedf32-20261014
- Status: unplayed
- Decision: D69, D70; issue I-048
- Steps: tap a direction (turns only), hold to walk, turn at corners, hold Shift (or a shoulder button) to run, walk into a wall, face a chest/NPC/bed/door.
- Expected: snappy and always on the grid; run is faster; soft bump; a small prompt over interactables.
- Look out for: does movement feel better? Do maps still look misaligned anywhere? (Tell me which room.)
- Your note:

### Q-009 | Doors and saves | build bcedf32-20261014
- Status: unplayed
- Decision: D64; issues SAVE-04, BUG-27, LOC-03
- Steps: go through doors back and forth; save at a bed, quit, load.
- Expected: you arrive on the door tile and don't bounce back; saving/loading works ("Game saved." message); nothing crashes.
- Your note:
