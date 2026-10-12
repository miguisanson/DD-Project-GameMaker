# DD-Project (GameMaker)

## What This Is

DD-Project is a short 8-bit dungeon RPG made in GameMaker 2024. You walk through 9 floors (plus 6.5 and 9.5) and fight turn-based battles (one enemy at a time; to be verified in the Phase 5 discuss, DECISIONS Notes), and finish with a final boss ("The Pale Choirbeast"). There are 3 classes (Knight, Archer, Mage). Floors and rooms: `.planning/codebase/STRUCTURE.md`. Combat numbers: `.planning/research/audit/balance-data.md`.

The game was put down as unbalanced and unfinished. Milestone v2.0 "Done right" fixes it: same game (floors, story, classes), but with fair fights, a QTE that feels good, a screen that scales correctly, a readable UI, real icons, and a web build. (DECISIONS D1)

## Core Value

A short 8-bit dungeon RPG whose fights feel fair and satisfying.

If a choice has to be made between a new feature and a fight that feels fair, the fight wins.

## Audience and platforms

- **Audience:** the owner's friends and the owner's portfolio. Free release, itch.io style. No store or legal work. (D2)
- **Platforms now:** Windows and web (HTML5). (D3)
- **Android:** later. The display and input design must not block it (touch, odd aspect ratios), but nothing on Android is tested this milestone. (D3)
- **Web hosting:** the owner's own site, repo `live-miguisanson-dev`, page `/play/dd-project`. This repo only produces the HTML5 export; deploying is that repo's job. Not GX.games; the Opera GX target is dropped (removed in the IDE, never by hand-editing). (D15)

## Requirements

### Validated

(None yet. v2.0 has not shipped.)

### Active

All v2.0 requirements are in `REQUIREMENTS.md` (categories VER, DISP, BUG, STAT, TURN, QTE, PROG, BAL, UI, ART, WEB, LOC, SAVE). Phases are in `ROADMAP.md`.

### Out of Scope

- **Android testing and release this milestone.** Design must not block it, but it is not built or tested. (D3)
- **Porting to other engines or consoles.** The porting branches are parked; `v1.8` already contains all of them (`STATE.md`). (D1)
- **GX.games / Opera GX.** (D15)
- **Old save compatibility.** Old saves are rejected with a friendly message. (D16)
- **New floors, new story, new classes.** Same game, done right. (D1)
- **Store and legal work.** (D2)
- **Deploying the website.** That is the `live-miguisanson-dev` repo's job. (D15)
- **Full touch controls.** Only "touch-ready" design (one input layer, big hit areas). (D3, qte-design.md section 3)

## Context

- **State at start of v2.0:** branch `v1.8`, HEAD `0b6e2f8`. No automated tests exist (`.planning/codebase/TESTING.md`). A headless build now works with Igor (`research/automation-igor.md` section 1). The game's own code has about 21,100 lines of GML (`codebase/CONVENTIONS.md`).
- **Why it was abandoned (owner, 2026-10-13):** unbalanced, QTE never felt right, resolution and scaling bugs (including a screen bug when a cutscene or dialogue ends), inventory and UI look bad, buff and debuff icons are placeholders (`research/playtest-notes.md`).
- **Friend's playtest:** probably an old build. Three of the friend's bugs (skill books twice, mini boss moving, maybe poison) look fixed in code since commit `f39236b` (2026-03-05). From now on every build shows a build id and every note records it (`research/DECISIONS.md` Notes; `research/audit/combat-bugs.md` top).
- **Why two earlier projects ended "very buggy":** checks did not exercise the thing the player uses; features piled up unplayed; the reviewer read the builder's report instead of the evidence; "done" was a word, not proof (`research/lessons-from-past-projects.md` section 3). The v2.0 process (Phase 1 ladder, `IMPROVE.md`, `REGRESSION.md`) is built to prevent each of those.
- **Working split:** Opus main session = architect and reviewer. Sonnet subagents write code in git worktrees. Local model or Haiku does mechanical text. No Codex. (`E:\ClaudeCode\CLAUDE.md`, `AGENTS.md`)

## Constraints

- **The IDE owns resource identity.** Never hand-edit `DD-Project.yyp`, any `*.yy`, or `DD-Project.resource_order` to add, rename, delete or relink a resource. New objects, sprites, rooms, fonts and scripts are created by the owner in the GameMaker IDE. `.gml` files are fair game. (AGENTS.md Rule 4)
- **Four-colour palette only:** `#071821 #306850 #86C06C #E0F8CF`, plus transparent. No fifth colour. (D10; `research/audit/icons-needed.md` section 1)
- **Two grids:** the world is 160x144 pixels. UI and text are authored on a 640x576 grid (4x). (D8)
- **Korean is kept, English first.** Korean is filled in one batch before release and a check flags missing translations. All player-facing text goes through `datafiles/localization/game_text.xlsx`; never hand-edit `localization.json`. (D9; `CLAUDE.md`)
- **Drive C: must keep 80-90 GB free.** It was 71 GB on 2026-10-13, already below the rule (`research/automation-igor.md` section 5). Builds, caches, temp files, ComfyUI output and screenshots go on E:. Igor must always be run with `--cache` and `--temp` on E:.
- **Real saves are never touched by automation.** The game's save area is `%LOCALAPPDATA%\DD_Project`. Every automated run sets `LOCALAPPDATA` to a scratch folder (`automation-igor.md` section 2.8).
- **Never print `%APPDATA%\GameMakerStudio2\um.json`.** It holds live tokens (`automation-igor.md` section 2.1).
- **Test first.** The failing check comes before the implementation. Never weaken a check to get green. (AGENTS.md Rule 1; global `CLAUDE.md`)
- **Design decisions are the owner's.** Agents ask with grill-me, one decision at a time, with a recommendation. They do not "take the recommended option" for player-facing design while the owner is away. (`lessons-from-past-projects.md` 4.5)
- **Tooling limits (verified):** only the Windows VM Release build was proven with Igor; YYC, `--debug`, HTML5 and Android were not tried (`automation-igor.md` section 5). Igor catches syntax errors but not unknown functions (section 2.6).

## Key Decisions

The full, locked list is `.planning/research/DECISIONS.md` (D1-D24, grill-me 2026-10-13). Changing one needs a new grill-me. Summary:

| Decision | Topic | Outcome |
|----------|-------|---------|
| D1 | Same game done right; combat core open for rework; porting parked | Locked |
| D2 | Friends + portfolio, free release | Locked |
| D3 | Windows + web now, Android later (not blocked) | Locked |
| D4, D5 | QTE mixed per skill (ring/bar and arrow sequences); graded results, never a full miss | Locked |
| D6, D20 | Skills always hit; basic attack is a graded QTE, never 0 damage | Locked (see tension 1) |
| D7 | Defence QTE only on big or telegraphed enemy attacks | Locked |
| D8 | World 160x144, UI/text on 640x576 grid | Locked (see tension 2) |
| D9 | Korean kept, English first, batch before release, missing-translation check | Locked |
| D10 | Strict 4-colour palette for new icons and UI | Locked |
| D11, D12, D17 | Owner plays in big sessions; ~8 unplayed features then bug-hunt only; live session, work on `next` | Locked; see `IMPROVE.md` |
| D13 | Auto-balance PROPOSES, owner approves in a batch | Locked |
| D14 | Classic JRPG grind on default difficulty | Locked |
| D15 | Web target: own site, HTML5, account-namespace hook, drop Opera GX | Locked |
| D16 | Clean break for old saves; schema version from now on | Locked |
| D18 | Hades-style card picks (1 of 3) replace random skill books | Locked |
| D19 | Turn-order bar; stun delays; bosses need stun resistance | Locked |
| D21 | Damage over time: strong but bounded, fixed durations, QTE can only shorten | Locked |
| D22 | Stats trimmed to ATK, DEF, SPD, MAG + HP/MP | Locked |
| D23 | Gold drops and a simple shop; loot improves per floor | Locked |
| D24 | Foresight gets a clear effect and tooltip; icon is an eye | Locked (see tension 3) |

### Tensions between locked decisions and the research (to settle in the matching phase, not now)

1. **D6 vs D20.** D6 says "basic attack may still miss". D20 says "nothing the player does fully misses". D20 is later and explicit, so this plan follows D20. The same for the friend's "increase the hit rate of skills" note: D6 removes skill misses, so that note is closed by STAT-04.
2. **D8 (640x576 UI grid) vs the pixel-font advice.** `research/retro-ui.md` section 6 and `research/resolution-gamemaker.md` section 6.3 assumed text at native 8-px size on a 160x144 grid (option A). D8 picks the 4x grid (option C), where those sources say to use integer multiples of sprites and hi-res text. At the game's windowed scales 3-5 the 640x576 grid maps to 0.75x-1.25x, which is not an integer. Phase 2 and Phase 9 must settle how text is drawn (grill-me).
3. **D24 vs D6.** Foresight's current effect is "next skill cannot miss" (`audit/combat-bugs.md` section 2). If skills always hit, that effect is void. Phase 4 must give Foresight a new effect. Same for the enemy-side statuses Solidify and Evasion, which exist to cause misses (`audit/balance-data.md` S13).
4. **D18 vs `audit/icons-needed.md`.** That audit asked for 3 new skill-book icons. Skill books are replaced by cards, so those are dropped from the art list.
5. **D22 vs `audit/icons-needed.md`.** The optional stat icons were for STR/AGI/DEF/INT/LUCK. They become ATK/DEF/SPD/MAG. Also LUCK (the only crit source for Archer/Mage per `balance-data.md` S8) disappears, so crit needs a new home in Phase 4.
6. **D21 vs current code.** Today the defensive QTE can lengthen a status from 2 to 8 ticks (`audit/combat-bugs.md` section 1). D21 says it may only shorten.

---
*Last updated: 2026-10-13 after Phase 0 (audit, research, direction) and the grill-me session*
