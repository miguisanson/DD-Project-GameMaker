# DD-Project (GameMaker)

## What This Is

DD-Project is a short 8-bit dungeon RPG made in GameMaker 2024. You walk through 9 floors (plus 6.5 and 9.5) and fight turn-based battles (one enemy at a time; to be verified in the Phase 5 turn-order grill, DECISIONS Notes), and finish with a final boss ("The Pale Choirbeast"). There are 4 classes: Knight, Archer, Mage and the Nobody (D34; the Nobody is the classless character you start as today, and becomes a real class with its own card pool). Floors and rooms: `.planning/codebase/STRUCTURE.md`. Combat numbers: `.planning/research/audit/balance-data.md`.

The game was put down as unbalanced and unfinished. Milestone v2.0 "Done right" fixes it and, since 2026-10-14, makes it **replayable like a roguelike** (D25-D36): each run goes through the same handcrafted floors in about 45-60 minutes, with per-run shuffles (card offers, shop stock, which enemies appear where, elite variants, chest loot). You start at level 1 every run. If you die, you return to the dungeon entrance room, lose the run's cards, gold, items and levels, see a short death line, and get a small gift for the next run. Unlocks widen your choices but never add permanent stat power. Story scenes play once per save file and never repeat. The first win shows the ending and credits.

**Scope limit (D28):** the game must finish soon. Nothing is added beyond what is decided. There is **no post-release**: everything decided ships in the release, then development stops. Priority: remove bugs and improve.

## Core Value

A short 8-bit dungeon RPG you can replay: every run is a fair, satisfying 45-60 minute climb.

If a choice has to be made between a new feature and a fight that feels fair, the fight wins. If a choice has to be made between a new idea and finishing, finishing wins (D28).

## Audience and platforms

- **Audience:** the owner's friends and the owner's portfolio. Free release, itch.io style. No store or legal work. (D2)
- **Platforms:** Windows and web (HTML5). (D3)
- **Android:** not built, not tested. D3 says "later", but D28 says there is no post-release, so "later" never comes. Display and input should still avoid blocking it where that costs nothing. **Open question for the owner** (on `BOARD.md`).
- **Web hosting:** the owner's own site, repo `live-miguisanson-dev`, page `/play/dd-project`. This repo only produces the HTML5 export; deploying is that repo's job. Not GX.games; the Opera GX target is dropped (removed in the IDE, never by hand-editing). (D15)

## Requirements

### Validated

(None yet. v2.0 has not shipped.)

### Active

All v2.0 requirements are in `REQUIREMENTS.md` (159 requirements in categories VER, DISP, BUG, STAT, TURN, QTE, RUN, PROG, ROB, BAL, UI, ART, WEB, LOC, SAVE). Phases are in `ROADMAP.md` (8 phases). The owner's one-page view is `BOARD.md`.

### Out of Scope

- **Android testing and release.** (D28; D3 survives only where free)
- **Porting to other engines or consoles.** The porting branches are parked; `v1.8` already contains all of them (`STATE.md`). (D1)
- **GX.games / Opera GX.** (D15)
- **Old save compatibility.** Old saves are rejected with a friendly message. (D16)
- **New floors, new story, new content beyond the decisions.** The only new class is the Nobody, which already exists in the game. (D1, D28)
- **Easy / Normal / Hard.** One difficulty plus a QTE assist option (wider windows). (D35)
- **Permanent stat power between runs.** Unlocks and a death gift only. (D32)
- **A node map, procedural floors, a post-win difficulty ladder, daily or entered seeds.** Researched (`roguelike-design.md`), not decided, so not built. (D25, D28)
- **Store and legal work.** (D2)
- **Deploying the website.** That is the `live-miguisanson-dev` repo's job. (D15)
- **Full touch controls.** (D28)

## Context

- **State at start of v2.0:** branch `v1.8`, HEAD `0b6e2f8`. No automated tests exist (`.planning/codebase/TESTING.md`). A headless build works with Igor (`research/automation-igor.md` section 1). The game's own code has about 21,300 GML lines (plan review count; `codebase/CONVENTIONS.md` says about 21,100).
- **Why it was abandoned (owner, 2026-10-13):** unbalanced, QTE never felt right, resolution and scaling bugs (including a screen bug when a cutscene or dialogue ends), inventory and UI look bad, buff and debuff icons are placeholders (`research/playtest-notes.md`).
- **Why the roguelike turn (owner, 2026-10-14):** "turn this somewhat into a roguelike for replayability"; four classes including the Nobody, "try not to add too much anymore"; "there is nothing after release, build everything, I will stop development after release". The owner also finds GSD phases annoying to track, hence `BOARD.md`.
- **Friend's playtest:** probably an old build. Three of the friend's bugs (skill books twice, mini boss moving, maybe poison) look fixed in code since commit `f39236b` (2026-03-05). From now on every build shows a build id and every note records it (`research/DECISIONS.md` Notes; `research/audit/combat-bugs.md` top).
- **Why two earlier projects ended "very buggy":** checks did not exercise the thing the player uses; features piled up unplayed; the reviewer read the builder's report instead of the evidence; "done" was a word, not proof (`research/lessons-from-past-projects.md` section 3). The v2.0 process (Phase 1 ladder, `IMPROVE.md`, `REGRESSION.md`) is built to prevent each of those.
- **Why we do not plan everything on paper:** the same lessons file shows the owner reset "finished" projects after playing them, and 24 decisions made on 2026-10-13 were partly reopened a day later by the roguelike idea. So feel and numbers are settled by throwaway sketches the owner plays and by short grill-me topics right before building (`research/plan-review.md` section 5; `ROADMAP.md`). A decision is "paper" until it has been played.
- **Working split:** Opus main session = architect and reviewer. Sonnet subagents write code in git worktrees. Local model or Haiku does mechanical text. No Codex. (`E:\ClaudeCode\CLAUDE.md`, `AGENTS.md`)

## Constraints

- **The IDE owns resource identity.** Never hand-edit `DD-Project.yyp`, any `*.yy`, or `DD-Project.resource_order` to add, rename, delete or relink a resource. New objects, sprites, rooms, fonts and scripts are created by the owner in the GameMaker IDE. `.gml` files are fair game. (AGENTS.md Rule 4)
- **Four-colour palette only:** `#071821 #306850 #86C06C #E0F8CF`, plus transparent. No fifth colour. (D10; `research/audit/icons-needed.md` section 1)
- **Two grids:** the world is 160x144 pixels. UI and text are authored on a 640x576 grid (4x). (D8)
- **Korean is kept, English first.** Korean is filled in one batch before release and a check flags missing translations. All player-facing text goes through `datafiles/localization/game_text.xlsx`; never hand-edit `localization.json`. New text (death lines, unlock names, credits) is kept minimal (D28). (D9; `CLAUDE.md`)
- **Game data is JSON under `datafiles/`,** read by the game and by the Python simulator. Names and descriptions are localization keys, not JSON text. (BAL-01)
- **Randomness is seeded per run** through the game's own streams, not the built-in global generator, and must give the same numbers on Windows and the web export. (RUN-11)
- **Drive C: must keep 80-90 GB free.** It was 71 GB on 2026-10-13 and about 80-82 GB after a cleanup on 2026-10-14 (rule still not fully met). Builds, caches, temp files, ComfyUI output and screenshots go on E:. Igor must always be run with `--cache` and `--temp` on E:.
- **Real saves are never touched by automation.** The game's save area is `%LOCALAPPDATA%\DD_Project`. Every automated run sets `LOCALAPPDATA` to a scratch folder (`automation-igor.md` section 2.8).
- **Never print `%APPDATA%\GameMakerStudio2\um.json`.** It holds live tokens (`automation-igor.md` section 2.1).
- **Test first.** The failing check comes before the implementation. Never weaken a check to get green. (AGENTS.md Rule 1; global `CLAUDE.md`)
- **Design decisions are the owner's.** Agents ask with grill-me, one decision at a time, with a recommendation. They do not "take the recommended option" for player-facing design while the owner is away. (`lessons-from-past-projects.md` 4.5)
- **Tooling limits (verified):** only the Windows VM Release build was proven with Igor; YYC, `--debug`, HTML5 and Android were not tried (`automation-igor.md` section 5). Igor catches syntax errors but not unknown functions (section 2.6).

## Key Decisions

The full, locked list is `.planning/research/DECISIONS.md` (D1-D36: D1-D24 grill-me 2026-10-13, D25-D36 grill-me 2026-10-14). Changing one needs a new grill-me. Summary:

| Decision | Topic | Outcome |
|----------|-------|---------|
| D1 | Same game done right; combat core open for rework; porting parked | Locked (amended by D25, D28) |
| D2 | Friends + portfolio, free release | Locked |
| D3 | Windows + web now, Android later (not blocked) | Locked; open question vs D28 |
| D4, D5 | QTE mixed per skill (ring/bar and arrow sequences); graded results, never a full miss | Locked |
| D6, D20 | Skills always hit; basic attack is a graded QTE, never 0 damage | Locked (see tension 1) |
| D7 | Defence QTE only on big or telegraphed enemy attacks | Locked |
| D8 | World 160x144, UI/text on 640x576 grid | Locked (see tension 2) |
| D9 | Korean kept, English first, batch before release, missing-translation check | Locked |
| D10 | Strict 4-colour palette for new icons and UI | Locked |
| D11, D12, D17 | Owner plays in big sessions; ~8 unplayed features then bug-hunt only; live session, work on `next` | Locked; see `IMPROVE.md` |
| D13 | Auto-balance PROPOSES, owner approves in a batch | Locked |
| D14 | Grind feel: now resource management and leveling inside one run | Locked, amended by D25/D27 |
| D15 | Web target: own site, HTML5, account-namespace hook, drop Opera GX | Locked |
| D16 | Clean break for old saves; schema version from now on | Locked (see D36) |
| D18 | Hades-style card picks (1 of 3) replace random skill books | Locked |
| D19 | Turn-order bar; stun delays; bosses need stun resistance | Locked |
| D21 | Damage over time: strong but bounded, fixed durations, QTE can only shorten | Locked |
| D22 | Stats trimmed to ATK, DEF, SPD, MAG + HP/MP | Locked |
| D23 | Gold drops and a simple shop; loot improves per floor | Locked |
| D24 | Foresight gets a clear effect and tooltip; icon is an eye | Locked (see tension 3) |
| D25 | Roguelike on the existing handcrafted floors (option A); not a node map, not procedural | Locked |
| D26 | Death ends the run; story moments play once per save; a death line frames dying | Locked |
| D27 | Level resets to 1 every run | Locked |
| D28 | Scope limit: nothing beyond the decisions; no post-release; four classes; bugs + improve first | Locked |
| D29 | Must-haves: card picks, turn-order bar, gold + shop, new QTE types | Locked |
| D30 | A full winning run takes 45-60 minutes | Locked |
| D31 | First win = ending + credits; between runs you return to the entrance room | Locked |
| D32 | Carry-over: unlocks only plus a small death gift | Locked |
| D33 | Per-run shuffles: offers, shop, enemy pools, elites, chests/loot; seeded streams | Locked |
| D34 | Nobody is the 4th class with its own card pool | Locked |
| D35 | One difficulty plus a QTE assist (wider windows) | Locked |
| D36 | Two save parts: profile and run, each versioned | Locked |

### Tensions between locked decisions and the research (to settle in the matching phase, not now)

1. **D6 vs D20.** D6 says "basic attack may still miss". D20 says "nothing the player does fully misses". D20 is later and explicit, so this plan follows D20. The same for the friend's "increase the hit rate of skills" note: D6 removes skill misses, so that note is closed by STAT-04.
2. **D8 (640x576 UI grid) vs the pixel-font advice.** `research/retro-ui.md` section 6 and `research/resolution-gamemaker.md` section 6.3 assumed text at native 8-px size on a 160x144 grid (option A). D8 picks the 4x grid (option C), where those sources say to use integer multiples of sprites and hi-res text. At the game's windowed scales 3-5 the 640x576 grid maps to 0.75x-1.25x, which is not an integer. **Settled once, in Phase 2 (grill G1).**
3. **D24 vs D6.** Foresight's current effect is "next skill cannot miss" (`audit/combat-bugs.md` section 2). If skills always hit, that effect is void. Phase 5 (G5) must give Foresight a new effect. Same for the enemy-side statuses Solidify and Evasion, which exist to cause misses (`audit/balance-data.md` S13).
4. **D18 vs `audit/icons-needed.md`.** That audit asked for 3 new skill-book icons. Skill books are replaced by cards, so those are dropped from the art list.
5. **D22 vs `audit/icons-needed.md`.** The optional stat icons were for STR/AGI/DEF/INT/LUCK. They become ATK/DEF/SPD/MAG. Also LUCK (the only crit source for Archer/Mage per `balance-data.md` S8) disappears, so crit needs a new home (G5).
6. **D21 vs current code.** Today the defensive QTE can lengthen a status from 2 to 8 ticks (`audit/combat-bugs.md` section 1). D21 says it may only shorten.
7. **D3 vs D28 (new).** "Android later" versus "no post-release". This plan treats Android as never built; the owner confirms on `BOARD.md`.
8. **D18 pool size vs replay (new).** About 5 skills + 5-8 upgrades per class means one run sees almost the whole pool, so runs may look alike. D18 and D28 fix the pool size; what keeps picks meaningful (an equipped-skill cap, exclusive upgrade branches, a bad-luck guard, skip) is a rules question for grill G7, not extra content.
9. **D14 grind vs a replayable run (resolved by D25/D27).** Leveling and potion/MP management now live inside one run. Whether enemies respawn inside a run is decided in G2 (RUN-15).

---
*Last updated: 2026-10-14 for the roguelike direction (D25-D36) and the plan review*
