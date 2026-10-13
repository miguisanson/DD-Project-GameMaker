# Owner decisions (grill-me, 2026-10-13)

Locked by the owner. Changing any of these needs a new grill-me.

| # | Topic | Decision |
|---|---|---|
| D1 | Scope (amended by D25, D28) | Same game (floors, story, classes) done right. All reported problems fixed. Combat core is open for rework (each rework decision gets its own grill-me). Porting parked. |
| D2 | Audience | Friends + portfolio, free release (itch.io-style). No store/legal work. |
| D3 | Platforms | Windows + web now; Android later. Display/input architecture must not block Android (touch, aspect ratios) but Android is not tested this milestone. |
| D4 | QTE style | Mixed per skill type: timing ring/bar for some skills, Helldivers-style arrow sequences (↑←↓→ / WASD) for others. |
| D5 | QTE stakes | Graded result (e.g. Perfect/Good/OK/Bad scale effect). Failing scales power down but never a full miss. |
| D6 | Hit rolls | Skills always hit. (Superseded for the basic attack by D20: it never misses either.) |
| D7 | Defence QTE | Only on big/telegraphed enemy attacks (bosses, mini-bosses, heavy moves). Normal hits just happen. |
| D8 | UI resolution | World stays 160x144. UI/text crisper than world pixels (target a 4x / 640x576 grid). Open detail for Phase 2: 640x576 is not an integer fit at windowed scales 3 and 5, so the spike decides the exact UI grid rule (e.g. UI scale tied to window scale). |
| D9 | Korean | Keep. English first; Korean filled in a batch before release; a check flags missing translations. |
| D10 | Art style | Keep strict 4-colour GB green palette (#071821 #306850 #86C06C #E0F8CF) for new icons and UI. |
| D11 | Playtesting | Owner plays when free, in big sessions. Agents keep building and run improvement mode while away. |
| D12 | Unplayed cap | ~8 unplayed features → loop switches to bug-hunt only (checks, simulator, tidy) until the owner plays. Each feature is its own revertable commit with its playtest steps listed. |
| D13 | Auto-balance | Improvement loop PROPOSES balance changes with simulator before/after numbers; owner approves in a batch. Never changes balance numbers on its own. |
| D14 | Difficulty feel (amended by D25/D27) | Classic JRPG grind on default difficulty: some floors expect leveling; potions/MP management across a floor matters. |
| D15 | Web target | HTML5 export hosted on the owner's own site (live-miguisanson-dev → `/play/dd-project`, assets in `public/game-assets/dd-project/html5game/`, needs the account-namespace hook re-applied — see that repo's `games/dd-project/README.md`). Not GX.games: drop the Opera GX target (remove in the IDE, not by hand-editing). Deploying the site is that repo's job; this repo produces the export. |
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

## Notes
- Three of the friend's bugs (skill books twice, mini boss moving, maybe poison) look already fixed in code since commit f39236b (2026-03-05) — the friend probably played an older build. From now on every build shows a build id, and every note records it.
- Battles are 1 player vs 1 enemy (verify in combat discuss) — the turn-order bar still matters via SPD.
