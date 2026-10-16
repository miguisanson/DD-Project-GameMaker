# Plan review (adversarial), 2026-10-14

Reviewer brief: find what is wrong, missing or over-built in the v2.0 plan (`PROJECT.md`, `REQUIREMENTS.md`,
`ROADMAP.md`, `IMPROVE.md`, `REGRESSION.md`, `ISSUES.md`, `research/*`), in light of two new facts: the owner wants the
game "somewhat roguelike" (runs, replay), and finds GSD phases hard to track. Spot checks were run against the code at
`v1.9` (= `0b6e2f8` game code). "Verified" = I read or grepped the code. "Inferred" = my judgement.

---

## 1. Errors and contradictions

### 1a. Spot checks against the code

| Claim | Where | Result |
|---|---|---|
| `ch.hp = 9999; // temp` | BUG-27 | Verified `scr_player.gml:20` (and `ch.mp = 9999` on :21). |
| `randomize()` in gameplay | VER-12, I-033 | Verified `scr_player.gml:1530`, the only call. |
| Stun grants 2 free turns regardless of the roll | BUG-18 | Verified `scr_combat.gml:699-704`. |
| Failed Run does not tick statuses | BUG-20 | Verified `scr_combat.gml:779-804` (no `Status_Tick`). |
| `SAVE_SNAPSHOT_VERSION 2`, strict reject | SAVE-01, I-036 | Verified `scr_macros.gml:321`, `scr_save.gml:87`. |
| `player_stat_mult`/`enemy_stat_mult` never read | STAT-09 | Verified: only defined, `scr_player.gml:73-102`. |
| Window colour red | DISP-04 | Verified `options/main/options_main.yy:26` = 255. |
| `rm_floor6_5` 144 wide | DISP-10 | Verified (`Width 144`). |
| Mini boss at (224,32), stationary | BUG-07 | Verified (`rm_floor5.yy`, `obj_mini_boss/Create_0.gml:5`). |
| Macros `COMBAT_ACTION_DELAY 60`, `PLAYER_SKILL_FX_SPEED_MAX 1.30`, `ENEMY_ACTION_CHAIN_MAX 3` | Phase 3/5 | Verified `scr_macros.gml:207,212,250`. |
| 18 ds creates vs 6 destroys; ~21,100 GML lines | PROJECT.md:102 | Verified 18/6; 21,316 lines. |
| **"17 `display_get_gui_*` call sites"** | DISP-09, ROADMAP:64 | **Off by one.** The audit's own list (`audit/resolution.md:69`) enumerates 18 width/height pairs (36 calls in 11 files). A "replace all 17" check would leave one site. |
| **Settings version "6 or 7, audits disagree"** | DISP-14 | **Settled: it is 7** (`scr_save.gml:66` writes `settings_version: 7`). `audit/resolution.md:45` is stale. Close the open question. |
| "Game saved." hard-coded | LOC-03 | True at `obj_game_controller/Step_0.gml:70`, but a localised copy already exists as `sys_save_ok` (`scr_dialogue.gml:34`); the fix is a reuse, not a new key. |

The research is mostly accurate. The errors are in how the plan **schedules** the facts.

### 1b. Contradictions and wrong dependencies

1. **The simulator is needed in Phases 4, 5 and 7 but is only built in Phase 8.** STAT-08, STAT-09 and Phase 4
   success criterion 4 (`ROADMAP.md:119`) say "Check: L2 (simulator)". So do TURN-04 (Phase 5) and PROG-08 (Phase 7).
   BAL-02 (the simulator) is Phase 8 (`REQUIREMENTS.md:265`). Those phases cannot pass their own checks. Either
   build the simulator straight after BAL-01 (Phase 4) or move those checks to Phase 8.
2. **The basic-attack grade table is decided twice.** Phase 4 grill asks for "the basic-attack grade table"
   (`ROADMAP.md:105`). Phase 6 grill asks for "the grade names, the window sizes ... and the damage or effect scale"
   (`ROADMAP.md:156`). STAT-05 ("never 0 damage at any grade", Phase 4) tests grades that QTE-03 defines in Phase 6.
   Pick one owner of the grade table.
3. **The D8 text-size rule is decided twice** (Phase 2 grill (a), `ROADMAP.md:75`; Phase 9 grill, `ROADMAP.md:237`).
4. **VER-14 ("the whole gate in about 40 s") cannot include the bot.** The harness design gives timeouts of 30 s
   (tests) + 60 s (smoke) + 120 s (bot), and 1500 bot frames took about 25 s (`automation-igor.md:203,255`). Split
   into a fast gate (compile + `-runtests` + smoke, under 40 s, every packet) and a full gate (bot + shots, per
   playtest build). Without that split, agents will skip the slow part and "green" will mean less than it says
   (lessons 2a: "`pnpm gate` does not run smoke").
5. **GSD's `human_verify_mode: "end-of-phase"`** (`.planning/config.json`) conflicts with D12's per-feature playtest
   entries. With phases of 17-27 requirements, end-of-phase owner checks are "build, batch, then test", which is
   lessons root cause 2 (`lessons-from-past-projects.md:255`).
6. **Phase 4 does not depend on Phase 3** (`ROADMAP.md:100`). The formula work needs Phase 1 only. Phase 3 also waits on
   a friend's answer (I-039) that may never come. As written, an unanswered message blocks combat work.
7. **Phase 6 does not depend on Phase 5** except QTE-08/09 (defence telegraph timing). QTE-01..07 (clock, judge,
   ring, arrows, basic attack) are independent and are the owner's top complaint ("QTE never felt right").
8. **Phase 10 "status icons can start early" is unsafe.** STAT-06 and STAT-10 may redefine or delete Evasion,
   Solidify, Bloodthirsty and Foresight (`PROJECT.md:152`). Draw the icons after the Phase 4 status list is fixed.
9. **The Phase 1 bot will break in Phase 6.** The bot times the confirm press from `Battle_AttackTimingTarget`
   (`automation-igor.md:201`), which Phase 6 replaces. No requirement covers keeping the bot working. BAL-03
   (calibrate the simulator against the bot) depends on it. Add: "the bot drives every new QTE type" to QTE-04/05.

### 1c. Untestable or vague requirements

- **STAT-06** ("rules ... are decided and tested") is a decision, not a requirement. **STAT-10** "clear effect" and
  **QTE-12** "feels good" are L5 only. Fine, but they cannot be closed by agents.
- **BAL-05** "no skill dominated or dominant outside the band": the band does not exist until Phase 8's grill.
- **BUG-12, BUG-13, BUG-15** are closed "by the category". They are traceability pointers, not requirements.
  17 of the 29 BUG rows say "Closed by X" (BUG-01, 02, 09, 10-15, 18, 19, 22, 23, 25, 26, 28, 29). Move them to
  `ISSUES.md` (they are already there). That makes about 137 real requirements, not 154.
- **UI-13** says "Lower priority" inside the requirement. **WEB-06** is a measurement. **STAT-01** says "a set amount"
  without saying who sets it.

### 1d. Missing requirements (in the audits, covered by nothing)

| Finding | Source | Why it matters |
|---|---|---|
| ~352 step-counted timers outside QTE/turns (fades, dialogue, hold, FX) | `codebase/CONCERNS.md:24-30` | Web builds drop frames more than Windows. Only QTE-14/TURN-07 cover timing. |
| Input buffering disabled; dead frames between arrows; wrong key fails at once; `Input_Update` returns early on the same ms | `audit/qte.md` 2.4; `scr_input.gml:242` | Feeds directly into "QTE never felt right". QTE-05 covers only part. |
| No hold-repeat anywhere | `audit/ui.md` P9 | UI-05 covers the inventory only. |
| Pause menu has no Save; saving only at beds | `audit/ui.md` P8 | A roguelike needs "save and quit" at any point. |
| Death reloads the latest save slot | `obj_start_controller/Step_0.gml:475-490` | This is the core of a roguelike; there is no requirement for it at all. |
| Saving respawns all regular enemies (`Save_Write` → `Enemy_ResetAll`) | `scr_save.gml:394` | Farming loop; only mentioned as a Phase 7 question. |
| Auto-resolved fights (0.35x EXP) | `balance-data.md` §3; `scr_enemy.gml:36-42` | The simulator (BAL-02) must model them or its XP numbers are wrong. |
| ds leaks, no CleanUp events; globals re-created every Step | `CONCERNS.md:32-51` | Only an improvement-mode sweep, no requirement. |

---

## 2. What the roguelike direction changes

A roguelike turns the unit of play from "one save file, played once" into "a run, played many times". Each item
below needs a new grill-me because it reverses a locked decision.

| Locked decision | What changes | Requirement IDs affected |
|---|---|---|
| **D1** "same game (floors, story, classes)"; Out of Scope "new floors, new story" (`PROJECT.md:64,95`) | Runs need variation. Rooms are IDE-owned (AGENTS.md Rule 4), so agents cannot generate rooms. Variation must come from code: encounter tables per spawn point, floor order or floor pool, card offers, events. The story is replayed every run, so it needs a skip. | New RUN-* group; DISP-06/07 (cutscene end, now frequent); new: skip cutscene/dialogue on repeat runs |
| **D14** classic JRPG grind; respawns | Grinding and a replayable run pull against each other. Runs are usually short, with no farming. Meta-progression (unlocks between runs) usually replaces the grind. | PROG-08 (XP curve), STAT-12 (level-up table: per run?), BAL-04 (bands such as "which floors expect extra levels"), I-031 |
| **D16** save model | Two stores: a **run save** (suspend; deleted or ended on death) and a **profile** (unlocks, settings, best runs). The round trip and schema work survive; their content changes. | SAVE-01, SAVE-02, SAVE-03, SAVE-07 reshaped; SAVE-04/05/06 survive; WEB-05 (browser storage for both); R-008, R-019 |
| **D18** card picks | Survives and becomes the core loop. The pool is too small for replay: about 10-13 cards per class (D18) means runs look alike. Frequency, rarity and rerolls become central design. | PROG-01..04, PROG-02 (pool size), UI-07 (shown often, must be fast), ART-04 (more icons) |
| **D23** gold and shop | Gold could last one run or carry over (meta currency). | PROG-05, PROG-06, PROG-07 |
| **D12** unplayed cap / playtest | One run is a sample of one. Judging a roguelike takes several runs per build, so playtest sessions get longer. | WEB-09, every L5 check |
| Difficulty Easy/Normal/Hard | May become run "heat" or ascension levels instead. | STAT-09, R-031 |
| Balance targets per fight | The unit becomes the run: run win rate, run length, variance between seeds, how strong each card pick is. The simulator must model card choice policies. | BAL-02, BAL-03, BAL-04, BAL-05, STAT-08 |
| Seeds | VER-12 becomes a player feature: a run seed shown next to the build id in every bug note. | VER-10, VER-12 |
| Repetition | Slow animations and QTE fatigue hurt much more on the 10th run. | BUG-05, BUG-06, QTE-15 |
| New screens | Run start, death/run summary, unlocks. | UI (new rows), LOC-04 |

**Not affected:** VER-* (except seed display), DISP-*, BUG-16..27, QTE-01..14, UI-01..06 and 10-14, ART-01..03 and
05..08, WEB-* except WEB-05, LOC-01..03. That is about half the plan, and it is the half to do now.

**Order change:** Phase 7 (Progression) cannot stay after Phases 4-6. Whether levels reset each run decides the
STAT-12 growth table and the D22 stat formulas. The run frame has to be settled **before** Phase 4's formula grill.

---

## 3. Ordering: prototype first, or start now?

**Prototype first (throwaway "spike" in a scratch copy, e.g. `E:\Temp\dd-spike-<name>`, never merged; the owner
plays 10 minutes, and the result is written down as a decision):**

| Spike | Question only play can answer | Blocks |
|---|---|---|
| S1 Run loop | Is "die → new run from floor 1 with fresh cards" fun with the existing 11 floors? How long should a run be? Hack: on death, wipe the character and go to `rm_floor1`; offer 3 random skills at each chest. | D1/D14/D16 re-grill, all of Phase 7, STAT-12 |
| S2 QTE feel | Ring vs bar, Perfect/Good window sizes in ms, arrow length, "too early" feedback. Hack the existing ring with a ms clock and 3 window presets the owner can switch with a key. | QTE-03, QTE-09, the grade table (1b item 2) |
| S3 Turn bar in 1 vs 1 | Does a visible CTB bar add anything when there is only one enemy? Is "stun delays" readable? A plain-rectangle bar over the current battle. | D19, TURN-01..05 |
| S4 Card pick | Pick 1 of 3 at every chest vs every level-up; does an upgrade feel like a reward? It can be part of S1. | PROG-01..03 |

Spikes follow the packet rules only loosely (no tests needed, nothing merges). They do follow the safety rules:
scratch copy, `LOCALAPPDATA` redirected, builds on E:.

**Safe to start now, whatever the design answers are:**
- **Phase 1 (test harness)**: everything except the bot's QTE driver; keep the bot thin, because combat will change.
- **Phase 2 (display rebuild)**: no design dependency. The D8 text rule is the only grill (decide it once here).
- **Phase 3 repros** (the `[VERIFY FIRST]` items), LOC-03, BUG-21, BUG-24, BUG-27.
- **SAVE-04/05** (atomic write, no throw on bad text): needed by any save model.
- **ART-01/02/07** (ComfyUI pipeline and checker), not the icon list itself.
- **UI kit** (UI-01, UI-02, UI-12: 9-slice, font, shared module) once D8 is settled. Not the screens.

**Not safe yet:** STAT-*, PROG-*, BAL-02..07, SAVE-01/02/03/07, ART-03/04, UI-03/05/07/08/09, TURN-*.

---

## 4. Simplification: one board the owner can read in 30 seconds

154 requirements and 11 phases are a fine **internal** checklist for agents. They are not a way for the owner to see
where things stand. Proposal:

- One file, `.planning/BOARD.md`, at most about 25 lines, plain words, four columns. Each item has one line saying
  what the owner will **see** when it is done, and the requirement IDs in brackets for agents.
- An item moves to Done only with a build id and the owner's "good" from `PLAYTEST-QUEUE.md` (or proof for
  non-player items).
- Agents update it in the same commit as STATE.md. GSD phases stay as an internal detail: one board item can be one
  GSD phase, a part of one, or a `/gsd-quick`. The owner never needs to know phase numbers.
- At most 2 items in Now. The board replaces the "Progress" table in ROADMAP.md for the owner.

What it would look like today:

```
# DD-Project board  (build: none yet | unplayed: 0/8 | open P1: 0)

## Now
1. The game can test itself: one command builds, runs tests, plays a bot fight,
   takes screenshots, shows a build id.            [VER-01..16]  you: make scr_test (1 min)
2. Decide what a "run" is: 6-8 questions, then a throwaway run-loop sketch
   you play for 10 minutes.                         [new RUN-*; re-grill D1, D14, D16]

## Next
3. Screen always the right size; no jump after cutscenes or dialogue.
                                                    [DISP-01..15, BUG-01/10/11/29]
4. Which of the friend's bugs are real on today's build; fix the ones that are.
                                                    [BUG-04..08, 21, 24, 27, LOC-03]
5. Feel sketches you play: new QTE timing, turn-order bar.
                                                    [spikes S2, S3 -> QTE, TURN]

## Later (order set after the sketches)
6. Fair combat numbers (4 stats, no misses, poison/burn with a turn counter)  [STAT, BUG-16..23]
7. QTE for real (ring/bar + arrows, graded, never a full miss)               [QTE]
8. Turn-order bar and stun delay                                             [TURN]
9. Runs: card picks, gold, shop, run save + profile                          [PROG, SAVE, RUN]
10. Balance with the simulator, you approve numbers                          [BAL]
11. Good-looking screens and real icons                                      [UI, ART]
12. Web link + Windows zip + Korean                                          [WEB, LOC]

## Done
- Audit, research, 24 decisions (2026-10-13)

## Waiting on you
- Make script asset scr_test in the IDE (1 min)
- Ask the friend which build they played (I-039)
```

Also cut the requirement list itself: drop the 17 pointer rows (1c), mark the roguelike-affected rows (section 2) as
`ON HOLD: run design`, and merge requirements that are one check (e.g. DISP-04/05/12 share one screenshot matrix).

---

## 5. Is more planning smarter? An honest answer for this project

**What planning has already done well.** The audits found real, checkable facts: stun free turns, dead difficulty
multipliers, tooltip turn mismatch, the XP shortfall, the display ownership mess. That is planning at its best:
cheap facts from code that no amount of play would have pinned down so precisely.

**What planning can still answer (do it):**
- Tooling and architecture: harness, display manager, save store split (run vs profile), data export format.
- IDE constraints: which roguelike variation is possible without new rooms (encounter tables, floor order, events).
- Dependencies: which decision blocks which work (section 3).
- The **frame** of the run: length, what persists, what death does, fixed or shuffled floors, story on repeat. These
  are owner values, not feel, and everything else hangs on them.

**What only a prototype or playtest can answer (do not plan it on paper):** QTE window sizes and arrow lengths; animation
speed; whether a 1 vs 1 turn bar is worth it; how often card picks feel good; run length that feels right; every
balance band; whether Foresight's new effect is clear. The research itself says so: QTE wind-up "to be calibrated by
playtest" (QTE-09), "trust the owner" over the simulator (`balance-methods.md` 6.5).

**The evidence on over-planning.**
- rpg-gm was "done" at least three times and reset by the owner after playing: M12, M14 ("paper dolls deleted
  forever"), M15, M16/17, M19 (`lessons-from-past-projects.md:150-154`). 266 roadmap rows were built from picks the
  owner first reacted to in play.
- nwn flipped process five times in 12 days (`lessons` 2g). Changing process is costly; do it once, now, on purpose.
- **This project already shows it.** 24 decisions were locked on 2026-10-13. One day later the roguelike idea reopens
  D1, D14 and D16 and reshapes D18 and D23 (section 2). Those decisions were made on paper with no play.

**Is ~100 grill-me decisions up front wise? No.** Counting the grill lists in ROADMAP.md (Phases 2-10) gives about 50
topics, and most topics hold several decisions. Made now, most would be on paper, and many would assume the old
non-run structure. Expect a large share to be reversed after the first play. Each reversal costs rework and re-grills,
and it teaches the owner that "locked" does not mean locked.

**Recommendation.**
1. **One short planning step now**: grill the run frame only (about 6-8 decisions: run length, what carries over,
   death, floor variation within the IDE limits, story on repeat, levels per run, meta-progression yes/no). Label
   them "paper" decisions.
2. **Prototype the run loop (S1)** and the QTE (S2) while Phase 1 and Phase 2 are built. They need no design answers.
3. **Grill per topic, just in time**: right before an item moves to Now, and after its spike for anything about feel.
   Keep each grill to about 5-10 decisions. A decision becomes "played" only after the owner has played it.
4. Keep the lessons rules that work (test first, the check ladder, a reviewer who runs the checks, the regression
   list, the 8-feature cap). Replace the 11-phase view with the board. Do not add more planning documents.

Bottom line: more planning of the **frame** is smart, and it is small. More planning of **feel and numbers** is not;
build a throwaway sketch and play it instead.
