# DD-Project board
Phases are internal bookkeeping; this board is what matters. Updated after every step that lands.
Build: none yet | Unplayed: 0/15 | Open P1: 0 | Updated: 2026-10-14 | Release then stop (D28)

## Now (after your go)
2. Four throwaway sketches you play ~10 min each: the run loop first, then QTE timing, turn bar, card picks. [no code kept; RUN, QTE, TURN, PROG]

## Next
3. Old bugs: check which are real on today's build, fix the real ones, make saving crash-safe. [BUG-03..08, 16, 17, 20, 21, 24, 27, LOC-03, SAVE-04/05]
4. Screen always the right size, no jump after cutscenes or dialogue; shared UI pieces; icon tool ready. [DISP-01..15, UI-01/02/12, ART-01/02/07]
5. Game numbers move into data files; save splits into "profile" and "run"; random shuffles get a seed. [BAL-01, SAVE-01..03/06/08, RUN-11, ROB-03]

## Later (order is firm, details asked right before each)
6. Fair fights: 4 stats, no misses, poison/burn with a turn counter, one difficulty, a simulator to check numbers. [STAT, BAL-02]
7. QTE for real: ring/bar and arrow types, graded, never a full miss. Then the turn-order bar. [QTE, TURN, ROB-02]
8. The run: class pick (4 classes), die and return to the entrance, death line and gift, unlocks, stories never repeat, shuffles, cards, gold, shop, ending and credits. [RUN, PROG, SAVE-07]
9. You approve balance numbers; every screen styled; every icon real; sounds, tutorial, run logs. [BAL-03..07, UI, ART, GAP-01..10]
10. Windows zip (built with Igor PackageZip, linked from your site) + credits + Korean + release-candidate playtest, then development stops. Windows only, no web version (D52). [REL, LOC, ROB-01]

## Done
- The game tests itself: one command builds, runs 140 checks, plays a bot fight, takes screenshots, stamps a build id (2026-10-14).
- Audit, research, 36 decisions (D1-D36), plan review, plan rewritten for the roguelike (2026-10-14)
- D52 applied: Windows only, no web version (2026-10-14)

## Waiting on you
- Ask the friend which build they played. ("Bone" is answered: Foresight's icon looks like a bone; it should be an eye — D24.) [I-039]
- Soon (item 4): in the IDE create `obj_display` and `scr_display`, set every room's view 0 to 160x144, widen `rm_floor6_5`, set the window colour to black. [DISP-02, 04, 10]
- Send the creator names for the sounds/music you got (for the credits). [GAP-05]
- Item 2: play the sketches when I say they are ready (~10 min each).
