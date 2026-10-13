# Issues (the single triage table)

Every note from the friend, the owner, a review or a bug hunt becomes one row here. The verbatim words stay in `research/playtest-notes.md` (the inbox). Rules are from `research/lessons-from-past-projects.md` section 4.5 and `IMPROVE.md`.

## Rules

- **Never paraphrase on entry.** Rows from a person carry their words in quotes. Rows found by an audit or review say "audit:" and name the file.
- **Class:** BUG (something is wrong), FEEL (works but feels bad), BALANCE (numbers), FEATURE (something missing), QUESTION (needs an owner or reporter answer).
- **Severity:** P1 blocks play. P2 hurts. P3 is polish.
- **Build id:** the build the reporter played. `unknown` for the old notes. From now on every new row names the build id shown on the title screen.
- **BUG rows get a `REGRESSION.md` entry before the fix.** FEEL and BALANCE rows need the owner's number or target (ask with grill-me, one decision at a time, with a recommendation).
- **Closing:** a BUG closes only when the reporter's own repro passes on a new build (shown by the bot or screenshots; for feel, by the reporter). "Fixed" is a proposal until the owner confirms.
- **Freeze rule:** while any P1 BUG is open, no feature work starts.
- **Status values:** `open`, `needs-repro`, `confirmed`, `fixed-on-next` (waiting for the owner), `closed`, `superseded` (a decision made it obsolete), `question`.
- Triage the same day a note arrives. Open P1s are counted in the `STATE.md` header.

## Open P1s: 0 (none confirmed; nothing has a repro yet)

## Changes on 2026-10-14 (roguelike direction D25-D36, plan review)

Phases were renumbered (8 phases now, `ROADMAP.md`). Requirement ids named in the table below still point to `REQUIREMENTS.md`; the ones that changed meaning:

- **Difficulty (I-019):** D35 removes Easy/Normal/Hard, so STAT-09 is now "one difficulty". I-019 closes when the difficulty switch and the dead multipliers are deleted.
- **I-031 (level 8 vs level 10 at the boss):** superseded by D27/D30. Levels reset each run; the curve is built for one 45-60 minute run (PROG-08 replaced). Closes when PROG-08 passes in the simulator.
- **I-030, I-004, I-036:** now served by the per-floor tables (PROG-07), card picks (PROG-04) and the profile/run save split (SAVE-01, SAVE-02).
- **I-007 (mini boss):** its "stays removed" check now means stays removed within a run; a new run brings him back (RUN-03).
- **I-010 (cutscene-end screen bug):** still needed for the first viewing; cutscenes now play once per save (RUN-07/08).
- **New rows I-040 to I-046 below** record roguelike-related findings from the plan review.

## Table

Reporter notes (friend, before 2026-10-13):

| ID | Reporter words | Class | Sev | Build | Repro | Expected | Status |
|----|----------------|-------|-----|-------|-------|----------|--------|
| I-001 | "scale problem. screen bug" | BUG | P2 | unknown | needs-repro: bot + screenshots at supported sizes; see I-010, I-011 | picture is the right size and stable | needs-repro; REQ DISP-04..08, R-001, R-002 |
| I-002 | "foresight skills idk what it does" | FEEL | P2 | unknown | audit: tooltip says "Next attack cannot miss" for "3 turns"; real duration 9; a basic attack burns it and never rolls to hit; the buff is a tiny text tag; the cast animation plays on the enemy (`combat-bugs.md` section 2) | Foresight has a clear effect and tooltip (D24) | open; REQ STAT-10, UI-06; R-012 |
| I-003 | "(bone shud be foresight +)" | QUESTION | P3 | unknown | ask the friend: was "bone" an icon, the floor-8 bones prop, or a skill name? There is no bone item or skill (`combat-bugs.md` section 3) | D24 reads it as: Foresight's icon should be an eye | question; REQ ART-03 |
| I-004 | "skill books appear in books twice" | BUG | P2 | unknown | audit: not reproducible at HEAD; guards exist since `f39236b`; suspects: old build, a save with two entries, or the Skills tab (`combat-bugs.md` section 4) | one entry per book; no duplicate skill ids | needs-repro; REQ BUG-04, R-003; ends in Phase 6 (books removed) |
| I-005 | "ice spear animation is slow" | FEEL | P3 | unknown | audit: Ice Spear is at the speed cap, 1.15 s plus a fixed 1 s hold (`combat-bugs.md` section 5) | total skill time at the owner's target (to be set) | open; REQ BUG-05, R-013 |
| I-006 | "hilt bash animation slow" | FEEL | P3 | unknown | audit: 0.86 s plus 1 s hold; last two frames empty; grants 2 free actions so it feels longest | same as I-005 | open; REQ BUG-06, R-014 |
| I-007 | "mini boss moves around so he isnt blocking tje way" | BUG | P2 | unknown | audit: stationary at HEAD (`ai_stationary = true` since `f39236b`); likely an old build | mini boss stays at (224,32) | needs-repro; REQ BUG-07, R-007 |
| I-008 | "i dont take dmg while being poisoned" | BUG | P2 | unknown | audit: tick exists (2-3 HP after each player action) but is nearly silent; skipped on the killing blow and on a failed Run (`combat-bugs.md` section 1) | HP falls each tick and the player notices | needs-repro; REQ BUG-08, R-005 |
| I-009 | "incease the hit rate of skills specifically a tiny bit i missed 4 to 5 consecutive horizontal slashes l" | BALANCE | P2 | unknown | audit: hit chance 61.8-88.8%; a 4-5 miss streak is a 1-10% event per session (`combat-bugs.md` section 7) | skills do not miss (D6) | superseded by D6; closes when STAT-04 / R-006 pass |

Owner notes (2026-10-13):

| ID | Reporter words | Class | Sev | Build | Repro | Expected | Status |
|----|----------------|-------|-----|-------|-------|----------|--------|
| I-010 | "Screen bug when a cutscene ends (also places with dialogue)." | BUG | P2 | unknown | audit hypotheses: H1 full display re-apply at the end of every transition; H2 cutscene art vanishes before the exit fade; H3 camera snap after pan-out (`resolution.md` section 3b). Not yet reproduced | no visible change when a cutscene or dialogue ends | needs-repro; REQ DISP-06..08, BUG-29, R-001, R-017 |
| I-011 | "Resolution/scaling problems in general." | BUG | P2 | unknown | audit: stacked scaling (port bigger than surface), variable GUI size, display owned by the audio manager (`resolution-gamemaker.md` 4.1) | one display manager, correct at every size | open; REQ DISP-02..12 |
| I-012 | "QTE never felt right." | FEEL | P2 | unknown | audit: tiny perfect window (about 1-2 frames), slow random-speed ring, no feedback, frame-rate bound (`audit/qte.md` section 4) | fair, readable, graded QTE (D4, D5, D7, D20) | open; REQ QTE-01..15, R-010 |
| I-013 | "Skills unbalanced against each other." | BALANCE | P2 | unknown | audit: stun skills triple actions; Wound beats Horizontal Slash; weapons ignored by skills (`balance-data.md` S1, S3, S5) | skills inside the approved bands | open; REQ BAL-05 |
| I-014 | "Buff/debuff icons reuse other skill icons as placeholders" | FEATURE | P2 | unknown | audit: 10 of 14 statuses have no real icon; 6 use frames of 48x48 FX sheets; 3 reuse other badges; Sunder has none; all drawn as 0.54x text tags (`icons-needed.md` section 2) | real 16x16 icons with turn counters | open; REQ ART-03, UI-04, R-011 |
| I-015 | "Inventory and the rest of the UI look bad." | FEATURE | P2 | unknown | audit: flat white/black rectangles, mixed pixel grids, one flat inventory list, no skill icons, no enemy HP on screen (`audit/ui.md` P1-P8) | one frame, one font, palette colours, clear screens | open; REQ UI-01..14 |

Found by audits and reviews (no person's words):

| ID | Finding | Class | Sev | Build | Repro / evidence | Expected | Status |
|----|---------|-------|-----|-------|------------------|----------|--------|
| I-016 | audit: skill tooltips show base status turns, not applied turns (Foresight "3" is 9, Wound "2" is 5, Guard "2" is 6) | BUG | P2 | HEAD `0b6e2f8` | `combat-bugs.md` C; `balance-data.md` S11; `scr_menu.gml:337-351` vs `scr_db_skill.gml:854-888` | tooltip number equals applied number | open; REQ BUG-16, R-015 |
| I-017 | audit: Curse ignores its 50% chance and the hit roll; its three damage-over-time effects cancel each other; log says all three applied | BUG | P3 | HEAD `0b6e2f8` | `combat-bugs.md` B; `balance-data.md` S12 | effect matches the log and the stated chance | open; REQ BUG-17, R-016 |
| I-018 | audit: window colour is red (`options_main.yy:26` is 255) and the fade covers only the picture, not the window | BUG | P3 | HEAD `0b6e2f8` | `resolution.md` H4 (suspected); confirm with fullscreen at 3x on 1080p | pure black bars | needs-repro; R-018 |
| I-019 | audit: difficulty multipliers are floored on small integers (Easy turns 1-damage hits into 0, Hard player hits lose a flat 1); `player_stat_mult` and `enemy_stat_mult` are never read | BUG | P2 | HEAD `0b6e2f8` | `balance-data.md` section 1, S7 | difficulty changes outcomes by approved amounts | open; REQ STAT-09, R-031 |
| I-020 | audit: stun skills give 2 free actions on any hit, even when the 60% stun roll fails | BUG | P2 | HEAD `0b6e2f8` | `combat-bugs.md` A; `scr_combat.gml:699-704` | no extra actions from stun (D19) | open; REQ BUG-18, R-030; replaced in Phase 5 |
| I-021 | audit: weapon accuracy is shown on weapons but never affects a player roll | BUG | P3 | HEAD `0b6e2f8` | `combat-bugs.md` D | weapons add to skill damage (D22) | superseded by D22; REQ STAT-03 |
| I-022 | audit: a failed Run does not tick statuses | BUG | P3 | HEAD `0b6e2f8` | `combat-bugs.md` E; `scr_combat.gml:779-804` | statuses advance by the turn rules | open; R-022; revisit in Phase 5 |
| I-023 | audit: self-buff animations play on the enemy | BUG | P3 | HEAD `0b6e2f8` | `combat-bugs.md` F; `scr_combat.gml:676-686` | buff effect on the player | open; REQ BUG-21, R-024 |
| I-024 | audit: a guarded (0-damage) enemy hit still applies its status and skips the defence QTE | BUG | P3 | HEAD `0b6e2f8` | `combat-bugs.md` J | defined by the damage-over-time rules (D21) | open; REQ BUG-22 |
| I-025 | audit: basic attacks pass `1 + crit_bonus` to the crit check, skills pass `crit_bonus` | BUG | P3 | HEAD `0b6e2f8` | `combat-bugs.md` K | one crit rule | open; REQ BUG-23 |
| I-026 | audit: `SKILL_POWER_STRIKE` (id 0) has a macro and a loc key but no `SkillDB` record | BUG | P3 | HEAD `0b6e2f8` | `combat-bugs.md` H | no orphan ids | open; REQ BUG-24, R-004 |
| I-027 | audit: the HP bar drops before the defence QTE is played; part is refunded after, so a good defence looks like a heal | BUG | P2 | HEAD `0b6e2f8` | `audit/qte.md` section 2.6 (inferred from code, needs a play check) | HP changes after the defence resolves | needs-repro; R-025 |
| I-028 | audit: hard-coded English outside localization: "Game saved." (`obj_game_controller/Step_0.gml:70`), the level-up text (`scr_enemy.gml:84`), `Equip_CanEquip` messages | BUG | P3 | HEAD `0b6e2f8` | `audit/ui.md` P10 | all text through `game_text.xlsx` | open; REQ LOC-03, R-026 |
| I-029 | audit: level-up message mentions "stat points" while the Stats tab is read-only | BUG | P3 | HEAD `0b6e2f8` | `audit/ui.md` P8 (not checked in play) | no stale text | needs-repro; replaced by UI-09 |
| I-030 | audit: loot tier weights clamp the enemy level to 3, so floors 3 and 9 drop the same quality; no gold or shop | BALANCE | P2 | HEAD `0b6e2f8` | `balance-data.md` S14 | loot improves per floor (D23) | open; REQ PROG-05..07 |
| I-031 | audit: one clean pass reaches about level 8; the final boss is level 10 | BALANCE | P2 | HEAD `0b6e2f8` | `balance-data.md` section 3 [calc] | final boss met at a sensible level (D14) | open; REQ PROG-08 |
| I-032 | audit: floor 2 Dire Wolf (win 6-15% with average timing) and floor 5 Palehorn (0-23% at level 4-5) are walls for most play styles | BALANCE | P2 | HEAD `0b6e2f8` | `balance-data.md` S9 [model only, never run in the game] | within the approved win-rate bands | open; REQ BAL-04, BAL-05 |
| I-033 | audit: `randomize()` is called inside a gameplay script, so seeded tests are impossible | BUG | P3 | HEAD `0b6e2f8` | `codebase/CONCERNS.md` Randomness; `scr_player.gml:1530` | randomize once at boot; tests can seed | open; REQ VER-12 |
| I-034 | audit: debug keys (`P`, `F5`, `F9`, `L`, `K`, `J`, `U`, `O`) are bound unconditionally | BUG | P2 | HEAD `0b6e2f8` | `codebase/CONCERNS.md` Security | off in release exports | open; REQ BUG-26, REL-06 |
| I-035 | audit: `ch.hp = 9999; // temp` at `scr_player.gml:20` | QUESTION | P3 | HEAD `0b6e2f8` | `codebase/CONCERNS.md`; find out whether it runs | no cheat value in play | question; REQ BUG-27 |
| I-036 | audit: old snapshot versions are rejected with no migration and no friendly message; the save write is not atomic; `Save_ToReal` throws on non-numeric text | BUG | P2 | HEAD `0b6e2f8` | `codebase/CONCERNS.md` Fragile Areas; `scr_save.gml:85-87` | D16: friendly rejection; safe write | open; REQ SAVE-02, SAVE-04, SAVE-05 |
| I-037 | audit: `rm_floor6_5` is only 144 px wide, narrower than the view | BUG | P3 | HEAD `0b6e2f8` | `resolution.md` section 4b step 9 | no area outside the room visible | open; REQ DISP-10 |
| I-038 | audit: slime Solidify makes the next player skill auto-miss; this breaks "skills always hit" | BALANCE | P3 | HEAD `0b6e2f8` | `balance-data.md` S13; `combat-bugs.md` section 7 | rule redefined in Phase 5 (G5) | superseded by D6; REQ STAT-06 |
| I-039 | The friend probably played an old build. Which build or APK did they play? | QUESTION | P2 | unknown | `combat-bugs.md` top note | answer recorded before any code change for I-004, I-007, I-008. If no answer comes, the repros run on the current build and that is the answer (plan review 1b item 6) | question |
| I-040 | plan review: death reloads the latest save slot (`obj_start_controller/Step_0.gml`, case `game_over`) | FEATURE | P2 | HEAD `0b6e2f8` | `plan-review.md` 1d | death ends the run and returns to the entrance room (D26, D31) | open; REQ RUN-02, RUN-16, R-036 |
| I-041 | plan review: saving respawns every regular enemy (`Save_Write` calls `Enemy_ResetAll`, `scr_save.gml:394`), a farming loop | BALANCE | P3 | HEAD `0b6e2f8` | `plan-review.md` 1d | the owner decides respawns inside a run (G2); a test proves it | open; REQ RUN-15 |
| I-042 | plan review: about 352 step-counted timers; a frame hitch changes outcomes | BUG | P3 | HEAD `0b6e2f8` | `codebase/CONCERNS.md` lines 24-30 | gameplay timers run on a clock | open; REQ ROB-01 |
| I-043 | plan review: input buffering disabled, dead frames between arrows, wrong key fails at once, `Input_Update` returns early on the same ms, no hold-repeat in lists | FEEL | P2 | HEAD `0b6e2f8` | `audit/qte.md` 2.4; `audit/ui.md` P9; `scr_input.gml:242` | forgiving, consistent input | open; REQ ROB-02, QTE-05, UI-10 |
| I-044 | plan review: 18 `ds_*` creates against 6 destroys, no CleanUp events, globals re-created every Step. Repeated runs in one session would make this grow | BUG | P3 | HEAD `0b6e2f8` | `codebase/CONCERNS.md` lines 32-51 | no growth over 20 runs | open; REQ ROB-03 |
| I-045 | plan review: the pause menu has no Save; saving only at beds. A 45-60 minute run needs a chosen way to stop and resume | FEATURE | P3 | HEAD `0b6e2f8` | `audit/ui.md` P8 | G2 decides; RUN-14 proves it | question; REQ RUN-14 |
| I-046 | plan review: D3 "Android later" conflicts with D28 "no post-release" | QUESTION | P3 | n/a | `DECISIONS.md` | owner confirmed 2026-10-14: Android never built (D38) | closed |
| I-047 | owner 2026-10-14: "enemies get stuck" | BUG | P2 | unknown | needs repro (audit/movement.md) | enemies path around walls and never get stuck | open |
| I-048 | owner 2026-10-14: "player is not aligned" | BUG | P2 | unknown | needs repro (audit/movement.md) | player snaps cleanly to the tile grid | open |
| I-049 | owner 2026-10-14: "the trigger interactables like when moving room to room or scene, i want to see" | BUG/FEATURE | P2 | unknown | needs repro (audit/movement.md) | room/scene triggers fire reliably and can be shown in a debug view | open |
| I-050 | owner 2026-10-14: "make sure the game is optimized and pathfinding is really good" | FEEL | P2 | unknown | profile (audit/movement.md) | steady frame rate; good pathfinding | open |

---
*Created: 2026-10-13. Updated 2026-10-14. Next free id: I-051.*
