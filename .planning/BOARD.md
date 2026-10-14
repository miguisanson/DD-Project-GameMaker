# DD-Project board
Updated after every step that lands. The full build list is `.planning/BUILD-PLAN.md`; the design spec is `.planning/research/DECISIONS.md` (D1-D94).
Build: none in progress | Mode: BIG BUILD, then one big playtest (D71) | Release then stop (D28)

## Now
- Building everything in BUILD-PLAN.md (A1 → E2). No playtest stops until it is all done.

## Done
- Playtest 1 (build d312bfb): new QTEs approved (D72). 11 findings logged as I-054..I-064, all in the build plan.
- Test system: one command builds, runs ~800 checks, a bot fight, screenshots; runs on a hidden desktop (never touches your screen).
- On `next`: cutscene screen fix, sliding bar + arrow QTEs + defence bar, ~1 s skills, sized effects, poison feedback, crash-safe saves, enemy sight/pathfinding/personalities, movement polish.
- All design decisions made (D1-D94).

## Waiting on you (whenever convenient; close GameMaker afterwards)
- In GameMaker: Game Options > Windows: tick "Allow window resize"; set scaling to "full scale"; widen `rm_floor6_5` to at least 160 px; delete unused sprites `spr_attack_timing_target`, `spr_attack_timing_falling`.
- Send the creator names for the sounds/music (credits).
- Ask the friend which build they played (I-039).
- Later: import the generated icon strips (a checklist will be on this board).
