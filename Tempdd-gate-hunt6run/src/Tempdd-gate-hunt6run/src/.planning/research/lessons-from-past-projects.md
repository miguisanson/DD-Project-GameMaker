# Lessons from rpg-gm and nwn-living-world (why both ended "very buggy")

Research only, written 2026-10-13. Sources: `E:\Github_Projects\rpg-gm` and `E:\Github_Projects\nwn-living-world`
(AGENTS.md, CLAUDE.md, `.claude/commands/`, `.claude/autopilot-*.md`, `scripts/autopilot*.mjs`,
`.planning/STATE.md`, `STATE-HISTORY.md`, `IMPROVEMENTS.md`, `.planning/improve/*`, `docs/DECISIONS.md`,
`docs/ROADMAP.md`, git log) and `E:\Github_Projects\AI-WORKFLOW.md`.

**Method and limits.** I read the control files whole and searched the large logs (STATE-HISTORY 512 KB,
IMPROVEMENTS 127 KB, nwn STATE 136 KB, 177 files in `nwn/.planning/improve/`) with grep, then read the hits in
context. Everything quoted below is from those files. I did not run either game. Where I infer a cause, it says
"inferred". The owner's verdicts are quoted from the repos: nwn `docs/DECISIONS.md` D265/D267 ("there are so many
bugs", "its too buggy") and `.planning/STATE.md` ("ITS SO BUGGY"); rpg-gm `docs/ROADMAP.md` M15/M19 and
`docs/VISION.md` section 0.

---

## 1. How the improvement mode / autopilot loop worked

### 1a. rpg-gm (the "reference" project in AI-WORKFLOW.md)

**Runner.** `scripts/autopilot.mjs` + `scripts/autopilot-lib.mjs`. It starts a headless `claude -p
--dangerously-skip-permissions` session on `/continue_rpg-gm`, and when that session ends starts another with a clean
context. Logs in `logs/autopilot/runner.log` and one `.jsonl` transcript per session.

**Who did what (verified in `autopilot-lib.mjs` `sessionPlan`).** Building sessions ran on `--model sonnet`.
**Every fifth session** (`REVIEW_EVERY = 5`) ran `autopilot-review-prompt.md` on **Opus**: builds nothing, reads
`git log $(cat .planning/LAST_REVIEW)..HEAD`, checks rules against the SRD, hunts hollow tests, fixes what it finds
test-first, writes "Review N" in STATE. So the "Opus reviewer + cheap implementers" setup meant: a Sonnet main session
orchestrating Sonnet subagents for four sessions, then one Opus pass over about 5-10 commits. Review 68 was the last.

**Phases / triggers (files in `.planning/`):**

| File | Meaning |
|---|---|
| `ROADMAP_DONE` | written by the build session when every `docs/ROADMAP.md` row is done or owner-queued; the runner then stops (`holdReason`) |
| `IMPROVE_GO` | the owner's green light: "when the roadmap is done, keep improving (VISION section 0 priorities). The owner is away 12+ hours." (2026-09-25) |
| `AUTOPILOT_STOP` | owner stop file; content now: "owner paused everything to run a game (2026-09-30)" |
| `AUTOPILOT_PAUSE` | the game writes its PID here while open, so the runner leaves the owner the Claude allowance |
| `AUTOPILOT_IDLE` | "a full audit found nothing worth doing": runner rests an hour; **3 empty full audits in a row = stop** (`IDLE_STOP_AT = 3`) |
| `LAST_REVIEW` | commit hash the last Opus review stopped at (now `58215c1`) |
| stuck logic | 3 sessions without a commit = back off an hour; 6 = stop (`STUCK_BACKOFF_AT/STUCK_STOP_AT`) |

**A round** (`autopilot-improve-prompt.md`): read `IMPROVEMENTS.md` (ranked backlog) -> if fewer than 5 items, run a
**full audit of every area** (Experience / Every system works via `SYSTEMS.md` / Rules vs SRD / Play via
`pnpm playthrough` + `pnpm smoke` / Code health / Screens / Content / Sound / AI DM / Tests) -> take the top 1-3 items
-> failing test, contract, delegate to a Sonnet subagent in a worktree, review, `pnpm gate`, commit test+code
together -> note in STATE (kept under about 120 lines, older notes moved to `STATE-HISTORY.md`).
Session budget: "land one to three roadmap packets" then end.

**What was verified, and how.** `pnpm gate` = check:test-first -> typecheck -> lint -> vitest (about 8,860 tests at
the end); `pnpm smoke` (real Electron window, real IPC); `pnpm playthrough` (about 5 minutes through Humblewood, added
around M15 as O-16); from X-7 (2026-09-29) an "experience report" (screenshots, sound timeline, wait times, flags) that
the Experience audit had to open and look at. The Opus review looked at rules vs SRD pages, hollow tests, design
drift, real defects, and whether each row met its "Done when".

**Scale.** 1,249 commits between 2026-09-15 and 2026-09-30 (300 on 09-19 alone); Review 68; 266 roadmap rows,
252 marked done (`.planning/STATE.md` frontmatter).

**GSD in practice.** STATE.md "Standing facts": "GSD's phase loop never ran here; AGENTS.md's hand-rolled pattern
(failing test -> contract -> delegate -> review -> gate -> commit) is what runs." So "GSD + multi-agent" meant
GSD's STATE/handoff files plus a hand-rolled loop.

### 1b. nwn-living-world ("Ashes of Neverwinter")

**No unattended runner in the end.** D38 (autopilot, 2026-10-01) was withdrawn by D68 / AGENTS.md "No autopilot"
(2026-10-07): "live sessions only, Opus leads, Sonnet workers build". The "improvement mode" here was a wave type run
inside live sessions:

- `.planning/batches/E-improve.md` (D116): "one Sonnet reviewer per area, fix clear bugs, escalate unclear ones to
  Opus, write findings to `.planning/improve/<date>.md`". The command file `improve_nwn-living-world.md` no longer
  exists in `.claude/commands/`.
- Rounds are numbered R1..R26 by hand in the file names (177 report files from 2026-10-07 to 2026-10-10). Each round was
  6-8 parallel Sonnet worktree workers, one per area (capture/stand-ins, delves, server ops, season/admin, Discord,
  economy/paths, NUI windows...), each told: read your area, compile, fix clear bugs, list unclear ones "For Opus".
- A recurring special round type: **"regressions review"** (r5, r8, r11, r12, r14, r17-d156, r20, r26): a reviewer
  reads `git diff <last reviewed>..HEAD` of the merged results of the previous round plus "mechanical sweeps"
  (function defined twice, name imported that no longer exists, event types written vs read).
- The main Opus session dispatched, then "Review each result briefly (the diff stat and the report; read code only
  where the report sounds wrong), merge" (`.claude/commands/continue_nwn-living-world.md`, loop step 2).
- Triggers were the owner's words and the usage meter, not files: stop at 90% weekly / 95% five-hour usage (D81,
  D104); workers: 2 -> 6 (D94) -> 10 (D112) -> 8 (D113 "it ran out of usage and crashed. keep it at 8 workers").

**What was verified, and how.** `nwnsc` compile of touched NWScript; Python unittest (`module/tests` 141 files,
`server/tests`, `service/tests`); `nss_lint`, `stub_grep`; and a **real in-game self-test**
(`lw_selftest.nss`, 50 steps at the end, "smoke 50/50") run on a booted dev server. Hard rule from D65/D103: "no new
tests and no test runs while building", "tests only when something breaks". Owner play-tests (ALPHA-TEST -> BETA-TEST
-> LIVE-TEST.md) found the rest.

**Scale.** 2,693 commits 2026-09-23..10-12 (668 on 10-07, 543 on 10-08, 545 on 10-09); decisions D1..D269 in about
12 days; `AGENTS.md` 75 KB; `STATE.md` 136 KB; `.planning/MODS.md` 96 KB.

**End.** 2026-10-12 about 18:00 "INSTALLED ... FRESH WORLD ... everything merged today up to ..." (one install of a
day's merges: D252-D264, P1-P9, three new custom classes, group bosses, the Wish, difficulty change). About 18:40
"SERVER OFF (owner): 'ITS SO BUGGY'". Same evening D265-D267: Ashes archived (tag `ashes-archive-2026-10-12`),
project "closed for now" at 22:00.

---

## 2. What went wrong (evidence)

### 2a. Things marked done that were not (rpg-gm)

- **T-11 cited a smoke test that was failing and nobody ran it.** STATE-HISTORY "Review 2": "T-11 was marked done
  citing that smoke, and four sessions passed without it being run, because `pnpm gate` does not run smoke."
- **`pnpm smoke` could not fail from M2 until Review 51 (about 11 days into the project).** Commit `544c75e` (Review 51): "a failed smoke fails the command -
  Electron drops process.exitCode, so SMOKE FAILED has exited 0 since M2". STATE-HISTORY: "treat old 'smoke passed'
  claims as 'the log said PASSED' only".
- **T-18 closed short of its Done-when** (`217d6d7`, Review 56): "a trait cannot be written unless it has numbers"
  became an INERT allow-list; 60 Humblewood blocks still had INERT traits including the finale boss's. "The two empty
  audits read that list as honest debt."
- **BS-3 and BS-7 marked done with their own Done-when items unbuilt.** ROADMAP BS-7: "BS-3 was marked done with two of
  its own Done-when items unbuilt - the Ready action, which does not exist in the engine at all, and the separate Cast
  button". Then BS-9 (Review 68): "BS-7 was marked done with three of its own row's items narrowed without leave".
- **BS-5 "all five battle maps cleaned"**: Review 67 opened two by eye: "soft ghosts where Susan's-hut markers were, and
  a blurred smear where the bandit-camp legend was; ... open every map by eye before adding it to DONE."
- **0AAG fixed one of five maps** ("0AAG's own test comment says 'every one of the five does', but only Susan's hut was
  fixed", 0AAH, Review 61).
- **The playthrough lied about saves** (`dc9aef5`): "a playthrough that never ran its save/Continue checkpoint no longer
  reports the save as restored".

### 2b. Tests that could not fail, or were deleted (rpg-gm)

- `b1d6eba` (Review 42): "H-11's only green test could not fail ... reverting `settleLevelUps` left it green with all
  20 seeds at level 1."
- `6dcdb99` (Review 46): "the two trait tests could not fail for the bug they guard"; same review: "a fight whose
  last foe was a Troll never ended" (`dad0dba`).
- `497bf5f` (Review 24): the Cleave reach test "could not fail on 'within 5 feet of the first'".
- Review 67 (STATE-HISTORY): the attack-odds view test "compared the view with its own formula and could not fail";
  the hit percent shown to the player was wrong for Poisoned heroes, Help, Hidden, Prone foes.
- **Collateral test deletion by cheap sessions.** `f8d891f` (Review 47): "Z-7 had deleted four Stage tests unrelated
  to dolls (B-1 blast preview and cast-click, V-3 token cue) - restored". Watch note: "a doll-deletion style sweep deletes
  neighbours - diff the test *names* removed". `4a04cd3` (Review 67): about ten rider tests "went with CombatDock's grid
  in BS-3 part 3" (restored in `4a04cd3`).
- `autopilot-review-prompt.md` itself says why: "the tests only prove the code agrees with whoever wrote them."
- Raw NUL bytes in `campaignWalker.ts` made git treat the file as binary, "the file no review could read" (Review 42).

### 2c. Green tests, unusable game (rpg-gm; owner playtests)

- ROADMAP M15: the owner opened "Playable v1" and found "controls squashed together, buttons too big, words that do not
  show properly, the party cards ... broken, a Map that is too small". O-17: "The owner, 2026-09-25: 'nothing is
  pressable'. Measured in the real app: every button on the Story page ... was covered by `SPAN.hp-text`." Also fixed by
  hand that day: "every file-loaded sound was silent (chunk-relative asset URLs), the opening was never narrated, long lines
  timed out in Kokoro". At that time there were thousands of passing tests and a "passing" smoke.
- X-7 row (ROADMAP M18): "Nine improvement audits in a row passed or came back empty while the owner, in minutes of
  play, heard choppy voices, a cluster of bell-like fight sounds and loud, wrong ambience - the audits check rules and
  code, never what a player sees and hears."
- M19: the owner, 2026-09-29: "I'm very unhappy with the battle screen - the maps, the icons are lacking ... what is
  wrong with the enemy icons, they look so weird". Root cause found afterwards: the book's start markers were printed into
  the map and the game drew its own token on top, so the demon was on the board twice.
- Direction resets by the owner after playing: M12 (2026-09-20 "the owner played it"), M14 (09-24 "the owner's reset"
  in `docs/VISION.md` section 0: paper dolls "deleted forever", Library/campaign picker removed, one voice engine, one AI),
  M15 (09-25), M16/M17 (09-26), M19 (09-29). The roadmap was "done" at least three times. Cause (inferred): the owner
  "delegated every decision" (STATE.md: "take the recommended option, record it where the design lives, carry on"), so the
  agents built 266 rows of their own picks and the owner reacted only when playing.

### 2d. Regression chains from the improvement rounds themselves (nwn)

Static reviews found real bugs, but each round's merges introduced the next round's bugs:

- **R5 regressions** (`improve/2026-10-08-r5-regressions.md`): "`ask_ollama()` raised NameError without a model list ...
  The news rewrite's merge (b8172a3) dropped `ollama_models()` ... Every existing test replaces `ask_ollama` whole,
  so nothing noticed." Chronicle, weekly legends and every `!ask` answer were broken. Also three "once per login" flags that
  were saved with the character and therefore "once per character".
- **R8** (`...r8-regressions.md`): "A purge of the oldest event rows sent every cursor back to 0" (introduced by R7's own
  "leftover item 7"): "the world sim would count every old kill, gate and death again"; `!close` made unreliable by an
  early return skipping a `SetCampaignInt`; a stale `lw_jailed` flag "spared a Wanted player from the guards for ever".
  The "!open credited to the DM, goals met" news bug R5 fixed for one command prefix was still wrong for `admin`/`Discord`
  prefixes.
- **R11** (`...r11-regressions.md`): the R8 fix for muted `!ask` compared the raw line, not the lower-cased one ("!ASK"
  still worked); `unmute Ald` / `unban Ald` "removed nothing but said OK" because R9's change stored whole names.
- **R14**: "An event the DM starts was held up to 3 hours before #world-news" - a side effect of R13's news-volume change;
  "LIVE-TEST step 12 tells the owner to start one and see it announced; he would have waited up to 3 hours and called it broken."
- **R17**: "A brand-new world waited 2.5 hours of play for its first world event" (D156 changed intervals but left the first
  event at the old value); R14/R17/R21 each also fixed stale player-facing docs after a rule change.
- **R19, the worst case** (`457da4cd`): a performance round added type filters to every area walk with "5 new static
  tests, module suite 762 OK". Commit message of the revert: "with them the server froze about a minute after start and
  the self-test never began (smoke ...)". The static tests were green; the game was dead. Only the real boot caught it.
- **Opus review of the first play-test fixes** (`improve/2026-10-07-opus-review.md`): "Subrace bonus locks the character
  out ... after choosing almost any subrace the character fails ELC and is refused at the next login" - fixed, but the verdict
  says "that is fixed but can only be proven in game". Also: the subrace and background perks were removed by the first death
  (`pc_respawn` strips all effects).
- **Round 1 review** (`...review-1.md`): `GetAbilityModifier(ABILITY_STRENGTH)` with no object argument read the module
  instead of the captive; stand-in wounds were double counted so "every server restart pushed each stand-in further down to
  the 25% floor"; a delayed command owned by a logged-out player is silently dropped.
- Class of bug repeated across rounds, fixed per instance: per-login locals saved on the character (R5 x3, then
  `nss_lint` got a rule); news `by=` prefixes (R5, R8); mute/ban name matching (R9, R11); stale docs after a numbers change
  (R14, R17, R21).

### 2e. "Tests" that did not touch the game (nwn)

- `module/tests/test_r11_regressions.py` (header: "source-text checks on the real scripts"):
  `self.assertIn("GetIsDMPossessed(oVictim)", body)` and an ordering check on character positions in the source. A change
  that keeps the words but breaks the logic stays green. Many R-round "tests" are this style (29 of 177 improve reports
  say the thing was not tried in game; the R12 report ends: "Not tried in the game.").
- `.planning/STATE.md` on 2026-10-12 has more than 20 blocks reading "BUILT ... NOT merged, NOT deployed, untested in
  game" (Echo Knight fix, Join my party, Wish, hand-made characters, ranged AI, group bosses, hotbar fill, three custom
  classes, Grapple/disarm, jump/climb ...). They were then installed together.
- AGENTS.md top banner: tests "only when something breaks" and "(Paused until the one test pass, phase 12, D65, D76)",
  while its Rule 1 two screens below says "The test (or check) comes first. Always." Phase 12 was never the "one test pass":
  building continued through D269.
- R26 (`a86d8b4e`, 2026-10-09) was the last regressions sweep ("no code bug found"). **765 commits followed** (three
  custom classes, group-boss engine, Wish, hand-made characters, D252-D264) with only area reviews, no regressions
  sweep and no in-game test, then the all-at-once install.

### 2f. Owner play found the basics (nwn)

- `improve/2026-10-08-playtest3-start.md`: new characters were dropped into the wrong area ("a new character has no area
  until its client has finished loading (2 to 143 s) ... a JumpToLocation sent before the character is in an area is
  dropped"), the intro movie delayed the client, black portraits ("Where the black ones come from is not proven").
- 2026-10-10 play-test fixes: "important NPCs glow, start next to the first person, warning before the Watch fights"
  (`3de25235`); D252 "no enemies within 60 m of start spots" (players spawned next to enemies).
- STATE 2026-10-12 PORTRAITS RULE: "the 18:00 install shipped lw_portraits.hak as DDS ... and friends could not see
  portraits; the owner saw them only through his local TGAs."
- First campaign night: "SoU chapter 1 bug seen: Ayala was never created by the opening cutscene".
- `.planning/ALERTS.md`: ten critical `vault_tamper` alerts open on the owner's own test characters; the alert system
  cried wolf on the owner's own test activity and nobody cleared it.
- `.planning/OWNER-CHECKS.md`: 62 owner-check rows, 0 ticked boxes; the human-only checks piled up unread.

### 2g. Process churn, over-parallelism, state drift

- **Process flipped five times in 12 days** (nwn `docs/DECISIONS.md`): D37 "End product, no shortcuts" (10-01) ->
  D51 fast track (10-04) -> D58/D59 "Cheap process ... no Opus reviews, no endless improvement mode" (10-06) -> D65 "no new
  tests and no test runs while building" -> D91 "Rough first ... quality drops are accepted and fixed afterwards" ->
  D103 "tests only when something breaks ... no GSD batch machinery". `continue_nwn-living-world.md`: "Cheap and working beats
  careful and thorough". Yet D116 (10-07) built an improvement mode anyway, one day after D59 removed it. GSD config:
  `plan_check: false, verifier: false, code_review: false`.
- **Too many parallel workers.** D112: 10 workers; D113: "14 workers hit the 5-hour limit and cut 13 tasks off mid-way
  (their work is saved on `wip/*` branches)". TFN-patch lane: "one worker at a time: several features patch the same TFN
  files (lesson from phase 4's merge conflict)". Merge losses show in R5 (dropped `ollama_models()`) and in the sweep
  list "function defined twice, name imported that no longer exists".
- **Weekly usage as the driver.** STATE: "Weekly usage 92-93% at the stop" on the day of the mega-install. The
  last day's rule: "finish EVERYTHING before the weekly reset, then ONE install + FRESH WORLD".
- **State files too large to be state.** nwn `STATE.md` 136 KB with frontmatter still saying `completed_phases: 4`,
  `percent: 0`, `last_activity: 2026-10-07` while the body describes 10-12. rpg-gm kept STATE small (rule: under about
  120 lines) but moved 512 KB into `STATE-HISTORY.md`, and the frontmatter's 252/266 counted roadmap rows ("recount,
  never copy forward").
- **Unattended-run mechanics lost work.** `autopilot-prompt.md` rule 1b: "Four of twelve sessions on 2026-09-29 ended
  'waiting for the gate' with their work uncommitted, and the orphaned run raced the next session." A background subagent
  "dies with the session (BS-7's did, 2026-09-29, leaving its worktree half-written)". STATE standing fact: "A second runner
  once committed mid-session." Codex routing returned 400 on every call for days (`gpt-5.6-sol` unsupported) yet the
  autopilot prompt still said to try Codex first.
- **Audits invent work.** `autopilot-improve-prompt.md`: "An audit is never empty while the experience report has an
  unfiled flag or a screenshot shows something you would not ship"; the idle stop (3 empty audits) never fired. In nwn,
  26 numbered rounds, each also generating new "follow-up" and "For Opus" files, which means every round added surface
  to review.

---

## 3. Root causes, ranked

1. **The checks did not exercise the thing the player uses.** Unit tests, source-text greps, compile checks and a
   self-reported "smoke" were green while buttons were covered, sounds silent, the server froze on boot, characters were
   refused at login. Verification was "does the code agree with itself", not "does the build behave". (rpg-gm O-17, X-7;
   nwn R19, R5 NameError, Opus-review ELC.)
2. **Build-then-batch-then-test: changes accumulated untested, then went live in one lump.** nwn deliberately
   (D65, D103) and rpg-gm structurally (unattended sessions landing 1-3 packets and moving on). A single install of 20+
   unplayed features cannot be debugged: the cause of any bug is any of 20 changes.
3. **The reviewer reviewed the report, not the evidence, and the model that reviewed was the model that built.**
   rpg-gm: Sonnet main + Sonnet subagents, Opus only every fifth session and only a skim of the most recent commits.
   nwn: Opus "reviews briefly (diff stat and the report)". "Done" meant the builder's claim. The bugs the reviews did find
   (hollow tests, ✅ without Done-when, deleted neighbour tests) were exactly the ones a skim does not find.
4. **"Done" was a status word, not evidence, and nothing forced regressions to be re-checked.** ✅ rows with unbuilt
   clauses, tests that could not fail, a smoke that exited 0 on failure. No growing regression list; fixes landed at one site
   of a repeated pattern.
5. **Self-generated work with no stop rule.** Audits "never empty", 26 review rounds, new features landing during
   "bug fixing" and "improvement" (nwn Beta -> Live kept gaining features: classes, Wish, group bosses). Each round
   added code and therefore regressions; the loop's output was its own next input.
6. **Too much parallelism and too many agents merging into one tree**, with only text-level conflict detection
   (6-14 workers in nwn; parallel packets in rpg-gm). Silent merge loss and cross-system interactions appeared in the
   regression rounds.
7. **Owner decisions were delegated away, then re-imposed after play.** rpg-gm: "take the recommended option";
   owner resets M12/M14/M15/M19 each deleted or redid large parts. nwn: ten rounds of Discord/Zeus/economy tooling the owner
   had not asked to be live before the basic game was playable.
8. **Rules lived in oversized, self-contradicting documents that changed daily** (75 KB AGENTS.md with banners that
   override its own Rule 1; 136 KB STATE.md; five process flips). An agent cannot follow rules it cannot hold.
9. **Budget pressure shaped decisions** (usage meters at 90-95%; "cheapest tokens", "rough first"). The owner's requests
   for speed were honoured literally at the cost of verification.

Not a cause (do not over-correct): test-first itself worked where it ran (rpg-gm engine rules: most Review fixes were
test-first and stayed fixed); the in-game self-test and the playthrough/experience report were the most valuable
checks either project had.

---

## 4. Rules for the new GameMaker setup (DD-Project-GameMaker)

Context: no unit-test runner; `.yy`/`.yyp`/`.resource_order` are IDE-owned (AGENTS.md Rule 4); Igor.exe **exists** at
`C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.14.3.260\bin\igor\windows\x64\Igor.exe` (listing
verified 2026-10-13; **not executed**; AGENTS.md still says no runtime is cached and should be corrected once a
build works); the project already has an owner/friend inbox (`.planning/research/playtest-notes.md`) and debug hooks
(`scr_debug`).

### 4.0 First, prove the verification ladder (before any improvement mode)

Step 0 (one packet, main session or one Sonnet, owner-visible): get Igor to **compile and run headless and return a
result**. Record the exact working command line in AGENTS.md "The gate" (do not guess flags; test them). Deliver:
1. `Igor` compile of the whole project: pass/fail + log file path.
2. `Test_RunAll()` (new script, created in the IDE per Rule 4) that runs when the game is started with a test flag or a
   dedicated startup room, writes `PASS`/`FAIL name` lines to a file in `working_directory`, then calls `game_end()`.
   The wrapper script greps for `FAIL`, for GML runtime error text, and for a missing result file (a missing file is a
   FAIL, not a pass: rpg-gm's exit-code-0 smoke bug).
3. One **negative control** per gate: a deliberately failing test that must make the gate go red (rpg-gm used
   `SMOKE_HIT_CONTROL=1`). Run it whenever the gate script changes.
If Igor cannot run, the fallback is the IDE with the output log, and the owner is told plainly that the gate is weaker.

### 4.1 The verification ladder (what "done" means per change type)

| Level | Check | Catches | Required for |
|---|---|---|---|
| L1 | Igor compile | syntax, missing script/asset references, wrong arg counts | every packet |
| L2 | `Test_RunAll` headless (pure logic + data integrity + save round-trip) | wrong formulas, duplicate/missing ids (skill books "twice"), localization keys missing, save migration | any change to `scr_*` logic, `scr_db_*`, `scr_save`, localization |
| L3 | **Scripted scenario run** via an input shim: boot -> new game -> move -> talk -> enter battle -> auto-perfect and auto-fail the QTE -> win/lose -> save -> load -> state compared. Assert on state (HP, flags, room, inventory), never just "no crash" | broken flow, status effects not ticking (poison no damage), room transitions, save/load | any change touching objects, rooms, battle, dialogue, cutscene |
| L4 | **Screenshots at the resolution matrix** (1280x720, 1920x1080, 2560x1440, plus the window/fullscreen variants the project supports), saved by the scenario via `screen_save`; the reviewer opens them | the "screen bug", scaling, overlapping UI, placeholder icons | any UI/Draw GUI/camera/view change |
| L5 | Owner/friend checklist in the running game (<= 15 min, written before the work) | feel: QTE timing, animation speed, balance, "does it make sense" | feel/balance items only; never the only check for a logic change |

Rules: a packet's Done-when names the level it needs. L5 alone is never enough for anything L1-L4 can see.
"Cannot be tested" is a reason to make a testable seam (extract a pure function, e.g. `Combat_CritChance` from
`Combat_CritCheck`, as `.planning/codebase/TESTING.md` already suggests), not to skip.
Put a **build id** (git short hash + date, generated by a pre-build script) on the title screen/debug overlay so every
playtest note can say which build it was.

### 4.2 Packet size

- **One behaviour per packet**: one bug, or one small feature slice, with one Done-when that fits in 3 lines and one
  check. If the Done-when needs "and", split it.
- **Size cap**: at most about 150 changed GML lines and at most about 3 files/resources; no packet both creates IDE
  resources (Rule 4) and changes logic - resource creation is its own owner/IDE-driven packet that lands first.
- **Test-first applies to the check**: write the L1-L4 check, watch it fail for the right reason (show the output),
  then implement. For feel items write the L5 checklist first.
- **Nothing is "built, not installed"**: a packet is either merged-and-proven or it is not started. No "BUILT, NOT merged,
  untested" blocks in STATE (the nwn pattern). A session may not end with unmerged packets except one clearly named WIP.
- **A fix that lands one instance of a repeated pattern must grep for the siblings** and either fix all or list each
  remaining site as its own row (rpg-gm 0AAG->0AAH, nwn R5->R8->R11).

### 4.3 How many in parallel

- **Default: one implementer at a time.** Maximum **two** concurrent implementer subagents (Sonnet, own worktree under
  `E:\Github_Projects\DD-Project-GameMaker-wt\<short>`), and only if their file sets (including the same object's event
  files, `.yy` files, `.resource_order`) do not overlap and neither touches shared globals/`scr_debug`/`scr_save`. Read-only
  research or audit agents may run in parallel freely (they change nothing).
- **One integrator** (the main session) merges one packet at a time, rebuilds, runs L1-L2 (and L3/L4 if relevant) on the
  merged tree **after each merge**, not once after several. Merge order is sequential.
- **WIP cap**: at most 3 open packets (specified + in flight + awaiting review). If the cap is hit, stop dispatching.
- Cut the number if any of these happen: a merge needs manual conflict resolution, a regression is found in the packet that
  merged just before, or Igor compile is red after a merge. This is the evidence-based version of D113 (14 -> 8 workers after
  a crash) taken further: 6-14 workers produced the R5/R8 merge-loss class of bug.
- Worktrees: GameMaker projects hold GUIDs and `.yyp` lists; two worktrees that each add a resource produce a conflicting
  `.yyp`/`.resource_order`. That is why resource creation is single-threaded and owner/IDE only.

### 4.4 What the reviewer must actually check

Reviewer = a different model/context from the builder, with the brief: "assume the report is wrong". Opus (or a fresh
Sonnet with an adversarial brief) reviews **every** packet before merge; there is no "every fifth session". Required, in
order, with the evidence pasted into the commit/STATE entry:

1. **Run the checks yourself** on the merged candidate (Igor compile, `Test_RunAll`, scenario if applicable) and read the
   raw output. A report saying "green" is not evidence.
2. **Done-when, clause by clause**, each with a pointer (file:line, log line, screenshot name). Any clause not met means
   the row is not done; split the unmet clause into a new row *now*. No "narrowed", no ✅ with caveats.
3. **Could the new check fail?** Revert the fix (or flip the key line) and see the check go red; for assertion blocks
   confirm the expected values come from the spec/owner, not copied from the code's output (the rpg-gm "compared the view
   with its own formula" trap).
4. **Diff the check names, not just files**: list removed/changed assertions and justify each (Z-7, BS-3 deleted neighbours).
5. **Open every changed visual**: view the L4 screenshots (the Read tool shows images) at all sizes. Read the text, check
   placeholder icons, overlaps, scaling, the screen after a cutscene/dialogue ends.
6. **Real input path**: the scenario must reach the feature through the same input the player uses (key/gamepad events
   through the input layer), not by calling the function directly (rpg-gm O-17 "nothing is pressable").
7. **Sibling sweep and neighbours**: grep for other uses of the changed function/pattern; name the two nearest systems
   (GML typical: `with` loops over `all`, global state reset on room change, ds_* leaks, alarms/time sources surviving a
   room change, Draw GUI vs view scale, surfaces lost on resize, struct version fields in `scr_save`) and run their
   regression entries (4.6).
8. **Diff hygiene**: no stray debug hooks, no hand-edited `.yy`, no hardcoded English text (run the localization lint), no
   changes outside the packet's file list.
9. The reviewer **fixes small findings in the same session** (as rpg-gm's Opus did, one commit per finding) and
   sends anything bigger back as a new row. Findings are never just filed.

### 4.5 How owner (and friend) playtest feedback enters the loop

- **One inbox**: `.planning/research/playtest-notes.md`, verbatim, dated, with the reporter's name and **build id**. Never
  paraphrase on entry. Voice notes/screenshots go in a sibling folder.
- **Triage the same day** by the main session into rows in a single `ISSUES` table (or STATE section), each with: id,
  reporter's words, class (BUG / FEEL / BALANCE / FEATURE / QUESTION), severity (P1 blocks play, P2 hurts, P3 polish),
  repro steps or "needs repro", expected result in one sentence. BUG rows get a **regression entry (4.6) written before the
  fix**; FEEL and BALANCE rows need the owner's number or target ("QTE window 0.2s", "hit rate +5%") - ask with grill-me,
  one decision at a time with a recommendation; never guess.
- **Close only by the reporter's own repro**: a BUG is closed when the steps from the report pass on the new build, shown by
  the scenario (L3/L4) or, for feel, by the reporter. The owner confirms or reopens in the inbox. "Fixed" is a proposal.
- **Playtest-freeze rule**: while any P1 BUG is open, no feature rows start. After each owner/friend session, the next wave
  contains only that session's BUGs, highest severity first, at most 7 rows per wave.
- **Cadence**: the owner (or a friend) plays a fresh build **after every 10 merged packets or every calendar day of work,
  whichever comes first**; the build id and the list of what changed since the last played build go in the message. If the
  owner cannot play, the loop does not advance to new features; it only runs the regression list.
- **Design decisions are the owner's** (what the game is, balance targets, UI direction). Agents may not "take the
  recommended option" for player-facing design while the owner is away; they park the question and continue with
  non-design work. (rpg-gm's delegation of everything produced the M14 reset.)
- Seed the inbox now with the existing notes (friend: scale/screen bug, skill books appearing twice, slow ice-spear and
  hilt-bash animations, mini boss moves aside, no damage while poisoned, skill hit rate; owner: screen bug when a cutscene
  ends, scaling, QTE, skill balance, placeholder buff icons, inventory/UI look).

### 4.6 The growing regression checklist

File: `.planning/REGRESSION.md` (human list) plus the automated part in `Test_RunAll` / the scenario scripts.
Each entry: `R-###`, one-line description in the reporter's words, system tags (battle, QTE, UI-scale, dialogue/cutscene,
save/load, inventory/skills, localization, audio, status-effects), how it is checked (test name or manual steps),
date added, **last run: build id + result**.

- **Every fixed bug adds an entry before its fix merges** (the failing check is the entry). Every new feature adds 1-3
  entries for its Done-when. Entries are never deleted; a check that becomes obsolete is replaced, with the reason.
- **Per packet**: run the entries tagged with the systems the packet touches plus their neighbours. **Per playtest build**:
  run all automated entries and walk the manual entries (target <= 15 minutes; if it grows past that, automate more).
- The review (4.4) must list which R-entries were run on the merged build, and the date/build id; an entry with no run for
  the current build counts as unchecked, not green.
- Starter entries (from the notes already in the repo): scene transition and cutscene end leave a correct view/camera and
  GUI scale; 3 resolutions x windowed/fullscreen show a correct HUD; no duplicate item/skill ids; every enemy references
  existing skills/loot; a poisoned character loses HP on each tick; every skill hit chance within the documented range;
  a mini boss that "blocks the way" stays put; save/load round trip including settings migration; localization lint clean;
  QTE timing windows match the documented values; every status icon asset is non-placeholder (or listed as known).
- **Count what happens**: STATE keeps one line "regressions found by review/playtest since last stable build: N". N >= 2 in a
  row triggers a stop (4.7).

### 4.7 Stop conditions for the improvement loop

Improvement mode starts only when: the verification ladder works (4.0), the regression list is green on the current build,
and the owner has played it and said what to improve. Its input is **only**: (a) the playtest inbox, (b) failing regression
checks, (c) compile/runtime errors from the gate. **Self-audits for "things that could be better" are not an input**
(remove the rpg-gm "audit is never empty" rule; an empty queue is a correct result, not a failure).

Stop the loop (stop dispatching, report in 5 lines, wait for the owner) when any of these is true:
1. The gate is red at session start, or a negative control no longer fails.
2. A review/playtest finds a regression introduced by the previous wave in **two waves in a row** (or 3 in any 6).
   Switch to stabilization: only the regression list and repairs until a full wave is clean.
3. The same bug *class* shows up a second time (4.2 sibling rule). Fix the class, add the guard, and ask the owner before
   continuing.
4. Any "done" is later found not done (a Done-when clause unmet, a hollow test). Freeze, then re-review the last 10 done
   rows before new work.
5. More than 10 merged packets (or one calendar day) since the last owner-played build.
6. WIP cap exceeded, or a merge needed manual conflict resolution.
7. The top of the queue is polish with no evidence (no owner/friend quote, no failing check).
8. Usage meter above 80% of the window or week: do not start a wave you cannot finish and verify (nwn lost 13 tasks at 14
   workers; the mega-install happened at 92-93%).
9. A rule or process change is proposed by an agent. Only the owner changes process, and process is not changed
   mid-wave (nwn flipped five times in 12 days).

Round limits: at most 3 consecutive improvement waves on one theme; at most 1 wave per owner play session unless the
inbox still has P1/P2 BUGs; no unattended overnight runs that change game behaviour (a runner may do read-only audits and
run the regression list; it may not merge). If an unattended runner is ever used: foreground-only commands, commit before
ending, one runner per checkout (rpg-gm rule 1b lessons).

### 4.8 Document and state hygiene

- AGENTS.md <= about 200 lines, no banners that override its own rules; one section "The gate" that states the exact
  commands and the negative control. STATE.md <= about 120 lines with a mandatory header: build id, last stable build,
  regression count, open P1s, WIP list, next action. Frontmatter is generated or deleted, never hand-copied forward.
- One roadmap file (rows with Done-when, a level from 4.1, and a regression-entry id). Rows are ✅ only per 4.4.
- Keep from the old projects: test-first for pure logic, one commit per finding, `check-test-first`-style guard on commits
  (here: a commit that changes `scr_*` logic must touch `Test_RunAll` or name its L5 checklist), the playthrough +
  experience-report idea (screenshots and a timeline that a reviewer must open), `STATE-HISTORY.md` for moved notes, the
  in-game self-test that runs on boot (nwn `lw_selftest`, 50/50) - the closest thing either project had to a real check.
- Drop: source-text assertion tests as the main check, "tests only when something breaks", batch-then-test, count-based
  audit rounds, ✅ with caveats, delegating player-facing design to the agent, 6+ parallel workers.

---

## 5. Short version for the main session

1. Make the gate real first (Igor compile + headless `Test_RunAll` + scenario + screenshots), with a negative control.
2. One behaviour per packet, one or two implementers, merge one at a time, re-verify after every merge.
3. Review the evidence (run it, mutate it, open the screenshots), not the report; builder never reviews itself.
4. Owner/friend notes go verbatim into one inbox with a build id; every bug becomes a regression entry before it is fixed;
   closed only by the reporter's repro.
5. The improvement loop is fed only by the inbox, failing checks and compile errors; it stops on repeated regressions,
   repeated bug classes, a false "done", a stale playtest, or WIP overflow.
