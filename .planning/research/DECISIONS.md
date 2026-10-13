# Owner decisions (grill-me, 2026-10-13)

Locked by the owner. Changing any of these needs a new grill-me.

| # | Topic | Decision |
|---|---|---|
| D1 | Scope (amended by D25, D28) | Same game (floors, story, classes) done right. All reported problems fixed. Combat core is open for rework (each rework decision gets its own grill-me). Porting parked. |
| D2 | Audience | Friends + portfolio, free release (itch.io-style). No store/legal work. |
| D3 | Platforms (amended by D38) | Windows + web now; Android later. Display/input architecture must not block Android (touch, aspect ratios) but Android is not tested this milestone. |
| D4 | QTE style (refined by D56-D61) | Mixed per skill type: timing ring/bar for some skills, Helldivers-style arrow sequences (↑←↓→ / WASD) for others. |
| D5 | QTE stakes | Graded result (e.g. Perfect/Good/OK/Bad scale effect). Failing scales power down but never a full miss. |
| D6 | Hit rolls | Skills always hit. (Superseded for the basic attack by D20: it never misses either.) |
| D7 | Defence QTE | Only on big/telegraphed enemy attacks (bosses, mini-bosses, heavy moves). Normal hits just happen. |
| D8 | UI resolution | World stays 160x144. UI/text crisper than world pixels (target a 4x / 640x576 grid). Open detail for Phase 2: 640x576 is not an integer fit at windowed scales 3 and 5, so the spike decides the exact UI grid rule (e.g. UI scale tied to window scale). |
| D9 | Korean | Keep. English first; Korean filled in a batch before release; a check flags missing translations. |
| D10 | Art style | Keep strict 4-colour GB green palette (#071821 #306850 #86C06C #E0F8CF) for new icons and UI. |
| D11 | Playtesting | Owner plays when free, in big sessions. Agents keep building and run improvement mode while away. |
| D12 | Unplayed cap (amended by D53: stop, don't bug-hunt) | ~8 unplayed features → loop switches to bug-hunt only (checks, simulator, tidy) until the owner plays. Each feature is its own revertable commit with its playtest steps listed. |
| D13 | Auto-balance | Improvement loop PROPOSES balance changes with simulator before/after numbers; owner approves in a batch. Never changes balance numbers on its own. |
| D14 | Difficulty feel (amended by D25/D27) | Classic JRPG grind on default difficulty: some floors expect leveling; potions/MP management across a floor matters. |
| D15 | Web target (SUPERSEDED by D52) | HTML5 export hosted on the owner's own site (live-miguisanson-dev → `/play/dd-project`, assets in `public/game-assets/dd-project/html5game/`, needs the account-namespace hook re-applied — see that repo's `games/dd-project/README.md`). Not GX.games: drop the Opera GX target (remove in the IDE, not by hand-editing). Deploying the site is that repo's job; this repo produces the export. |
| D16 | Old saves (see D36) | Clean break. Old saves are detected and rejected with a friendly message (no crash). New saves carry a schema version from now on. |
| D17 | Away mode | Owner starts a live session and leaves it running; no scheduled autopilot. Working branch is `v1.9` (cut from `v1.8` on 2026-10-13). Unattended work lands on a `next` branch, one commit per feature, each with automated checks + playtest steps. After the owner plays, good features merge to `v1.9`; bad ones are reverted. |
| D18 | Skill unlocks | Hades-style: at each chest (or level-up), pick 1 of 3 cards. Pool = the class's skills + upgrades to owned skills (e.g. "Ice Spear+", "Foresight+"). ~5 skills + 5-8 upgrades per class. Replaces random skill books. |
| D19 | Stun / turn order | Replace "extra actions on stun" with a visible turn-order bar (FFX/Octopath style). Stun delays the target on the bar. SPD decides how often you act. Bosses need stun resistance (detail in combat discuss). |
| D20 | Basic attack | Graded QTE, never 0 damage (e.g. Perfect 130 / Good 110 / OK 100 / Late 70 %). Free, always lands. Together with D5/D6: nothing the player does fully misses. |
| D21 | Damage over time | Strong but bounded: good vs tanky enemies, weak in quick fights. Fixed durations shown with a turn counter. Defence QTE can shorten a status, never lengthen it. |
| D22 | Stats | Trim to ATK, DEF, SPD, MAG + HP/MP. Every stat has a felt effect. Weapons add to skill damage too. (Replaces STR/AGI/DEF/INT/LUCK d20-modifier system.) |
| D23 | Economy | Add gold drops + a simple shop (merchant at safe spots between floors): potions and gear. Loot improves per floor. |
| D24 | Foresight | Friend's "bone" note = Foresight is confusing/not working as intended, and its icon looks like a bone. Icon should be an EYE (its animation is an eye blinking). Foresight must get a clear effect + tooltip in the combat rework. |

| D25 | Roguelike | Option A: runs on the existing handcrafted floors (research/roguelike-design.md). Same rooms and story; per-run variety from shuffles (D32). Not a node map, not procedural floors. "Classic JRPG grind" (D14) now means resource management and leveling *within* a run. |
| D26 | Death | Run ends, back to the camp (D31). Run cards, gold, items and levels are lost. Story moments (cutscenes, camera pans to an enemy, dialogue) play ONCE per save file and are remembered across runs, never repeated. Dying must be part of the lore (a short death line/framing, minimal writing). |
| D27 | Levels | Character level resets to 1 every run. Run power = levels + cards + gear earned during the run. |
| D28 | Scope limit | The game must finish soon. Do not add content beyond what is decided here. There is NO post-release: everything decided ships in the release, then development stops. Four classes total (Knight, Archer, Mage, Nobody). Priority = remove bugs + improve. |
| D29 | Must-haves | All of: card picks (D18), turn-order bar (D19), gold + shop (D23), new QTE types (D4). |
| D30 | Run length | A full winning run takes 45-60 minutes; all ~10 floors in one sitting. |
| D31 | Story arc / camp | Win once = ending + credits; the story is told on the first winning run. Runs after that are optional replay, no new story. Between runs you return to the dungeon entrance room (reuse an existing room, no new map); the death line and death gift happen there. |
| D32 | Carry-over | Unlocks only (no permanent stat power) + a small "death gift" each death leaves for the next run (Inscryption Deathcard idea; ties death to the lore). |
| D33 | Shuffles per run | Card offers + shop stock; which enemies appear where (per-floor pools); elite variants (data modifiers, better rewards); chest contents + loot (per-floor tables). Seeded per run (internal seed for reproducible tests; separate RNG streams per research/roguelike-cases.md). |
| D34 | Nobody | The Nobody becomes a 4th playable class (classless; own card pool). Today the player starts as Nobody and picks a class from a chest — the class chest flow changes accordingly (detail in the progression grill). |
| D35 | Difficulty modes | One difficulty only + a QTE assist option (wider windows) for accessibility. Easy/Normal/Hard are removed. |
| D36 | Save split | Two save parts, each versioned: profile (story seen, unlocks, death gift, settings) and run (seed, RNG stream counters, class, level, cards, gold, items, floor). Clean break from old saves (D16). |
| D37 | Releases | One release at the end. No public halfway "safety build". |
| D38 | Android / porting | Never. No Android, no porting — delete that idea everywhere. Web (HTML5 on miguisanson.dev) is the main way to play. |
| D39 | Windows download (amended by D52) | A Windows download (exe in a zip) is always offered alongside web, and becomes the only way to play if the web version can't meet D48. |
| D40 | Existing sounds | All 126 existing sounds/music are licensed for use (free, some paid for with the creators' permission). Keep them. Credits must list every sound/music creator — the owner supplies the names. |
| D41 | New sounds | Reuse existing sounds first (Retro/Minimalist/Modern sets etc.) for QTE grades, arrow presses, card pick, shop, stun, death, unlock; generate jsfxr-style 8-bit SFX only for what's missing. Owner approves by ear in playtest. |
| D42 | Music | Keep current music; no new tracks. Make sure each place (floors, battle, boss, shop, run end) uses a fitting existing track, with fades. |
| D43 | New art | Reuse and recolour first: Nobody skills reuse existing effect animations (retimed/flipped); merchant = an existing NPC sprite variant; elite marker = code-drawn outline/aura; cards = 9-slice frame. ComfyUI only for remaining gaps. |
| D44 | Icon cleanup | Agents run ComfyUI → downscale → force 4-colour palette → scripted outline fix, then show the owner a contact sheet; owner marks keep/redo; hand pixel fixes only for rejected ones. |
| D45 | Tutorial | Just-in-time prompts: first time each mechanic appears, a short pop-up (what to press, what it does). Once per save. Re-readable in a Help page from the pause menu. |
| D46 | Run saving | Auto-save (room change, after each fight, on quit). "Continue run" on launch. No reloading to undo a death. Beds stop being save points. |
| D47 | Beds | Beds become rest sites: once per run per bed, choose heal OR upgrade one owned skill (Slay the Spire campfire). |
| D48 | Skip scenes | Hold confirm ~1 s to skip a cutscene/camera pan (still counts as seen); tap advances text as now. |
| D49 | Settings | Volume, language, window size (existing) + QTE assist, key rebinding, text speed, screen shake on/off. |
| D50 | Web saves / support (SUPERSEDED by D52) | Saves stay in browser storage per site account (existing hook); the play page warns that clearing browser data erases progress. Supported: desktop Chrome, Firefox, Edge — a full run at steady speed, sound after first click, correct scaling in the site's player, keyboard + controller, save/resume. Phones unsupported (message shown). |
| D51 | Run logs | Each run writes a small local log (build id, seed, class, floor, cause of death, cards, gold, QTE grades). Windows: file in the save folder; web: "copy run log" button on the run-end screen. Playtesters send it; no auto-upload. |
| D52 | Platform: Windows only | No web/HTML5 build at all. The game ships as a Windows download: a zip with the .exe (GameMaker PackageZip via Igor, no installer), linked from the owner's site. Everything web-specific (HTML5 export, account-namespace hook, browser saves/warnings, browser test matrix, "copy run log" button) is dropped. The site's existing `/play/dd-project` page is that repo's business (swap it for a download link there). Controller + keyboard on Windows. |
| D53 | Tight mode (2026-10-14) | Target: finish in 1-2 weeks; keep token use low (short replies, no optional research, smallest agents that can do the job). At 8 unplayed features — or whenever the owner must check or decide something — STOP and wait (no bug-hunt filler). Supersedes the bug-hunt part of D12. |
| D54 | Batch size | Cap is 15 unplayed features (~3 playtest stops), not 8. Exception: a feature that changes combat feel (QTE, turn bar, cards) stops early so the owner plays it before more is built on top. Supersedes the number in D12/D53. |
| D55 | Skill action time (G0) | About 1 second total from press to next choice: animation at full speed, post-action pause cut from 1 s to ~0.3 s. |
| D56 | Basic attack QTE | The falling ring is removed. Basic attack = SLIDING BAR: a cursor sweeps a bar, press in the bright zone. Time-based (ms), not frame-counted. |
| D57 | Skill QTE | Every skill = Helldivers-style ARROW SEQUENCE (↑←↓→ / WASD / d-pad), FIXED per skill (memorized like spells); stronger skills have longer sequences; upgrades (e.g. Ice Spear+) may shorten/change it. |
| D58 | Arrow grading | Speed + mistakes: a time bar drains while typing; no mistakes in the fast zone = Perfect, slower = Good, wrong presses or timeout = OK/Weak (the skill still fires). A wrong press shakes the arrows and costs time. |
| D59 | Defence QTE | On big/telegraphed enemy attacks (D7): a SLIDING BAR block (same widget as attacking). Perfect blocks most damage and resists the status; Weak takes full. |
| D60 | Bar variety | Bar speed/zone is fixed per source so it is learnable: per weapon type for attacks (fast+wide for daggers/bows, slow+narrow for heavy), per heavy enemy attack for defence; upgrades/perks can widen the Perfect zone. |
| D61 | Grade effects | Starting numbers: Perfect 130 %, Good 110 %, OK 100 %, Weak 75 % (attacks and skills). Perfect may add a small extra where a skill has one (e.g. status chance). Tuned by playtest. |
| D62 | Testing scope | Run only the checks related to a change (`-Mode fast` + the one relevant `-Only` mode). `-Only shots` (resizes windows) only for screen/UI changes. Plain `-Mode full` once per merge to `next` and before a playtest stop — never while the owner is using the PC. |
| D63 | Enemy AI | Enemies idle until the player is within ~4 tiles with no wall between (line of sight), then path to the player with real pathfinding (mp_grid per room, enemies avoid each other). Touching starts the fight. Enemies have no facing sprites, so sight is all-around (no flipping). Visual cue: a "!" pops over the enemy with a short sound when it spots the player, and a faint dotted outline of its sight range shows when the player is near (4-colour). |
| D64 | Room arrival | The player appears ON the exit tile in the new room; the exit ignores the player until they step off it (no bounce-back, no re-trigger). |
| D65 | Map grid check | Owner unsure whether backgrounds sit on a 16 px grid: produce a grid-overlay screenshot per room and show the owner before changing room sizes/offsets. |

## Notes
- Three of the friend's bugs (skill books twice, mini boss moving, maybe poison) look already fixed in code since commit f39236b (2026-03-05) — the friend probably played an older build. From now on every build shows a build id, and every note records it.
- Battles are 1 player vs 1 enemy (verify in combat discuss) — the turn-order bar still matters via SPD.
