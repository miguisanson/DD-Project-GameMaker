# Roguelike design research: making DD-Project "somewhat roguelike"

Researched 2026-10-14. Input: `research/DECISIONS.md` (D1-D24), `PROJECT.md`, `ROADMAP.md`, `codebase/STRUCTURE.md`, `codebase/ARCHITECTURE.md`, `research/audit/balance-data.md`. Nothing here changes a locked decision; the owner decides (section 7).

## 0. How to read this file

Evidence tags used on every claim that comes from outside the repo:

- **[READ]** I fetched the page and read its content. The fetch tool summarises pages with a small model, so treat these as faithful paraphrase, not quotes.
- **[SNIPPET]** Only a web-search result summary. Not verified against the page.
- **[BACKGROUND]** My own prior knowledge, not checked in this session.
- **[INFER]** My conclusion for this game, not a claim from a source.
- **[REPO]** Read from this repository.

**What I could not find or read (do not assume these are covered):**

- Darren Grey's roguelike design writing: several searches, no article found. His site `gamesofgrey.com` refused the connection. I only confirmed from his itch.io page (snippet) that he is a roguelike developer, writer and host of the Roguelike Radio podcast. The Game Developer piece that came up for "roguelikes" (`/design/_likes`) is by **Aaron Steed**, not Grey.
- Josh Ge (Cogmind) blog posts: only an interview mention and an index-less search. Not read.
- Amir Rao: no source found that mentions him. Nothing here attributes anything to him.
- Anthony Giovannetti's GDC 2019 "Metrics Driven Design and Balance" talk: the GDC Vault page is members-only. I read only the promo page and two other Giovannetti/Mega Crit sources. Talk content below is secondhand [SNIPPET].
- Into the Breach design postmortem (GDC 2019, Matthew Davis): only the talk listing and a Kotaku snippet. Its lessons below are [BACKGROUND].
- GMTK videos ("Roguelikes, Persistency and Progression", "How and Why Spelunky Makes its Own Levels"): transcript hosts returned 403. Not read.
- Roguelike Celebration talks: only event snippets, no talk content read.
- Derek Yu's Spelunky book (Boss Fight Books): not read; secondary coverage only.

## 1. Definitions and the spectrum

### 1.1 Berlin Interpretation (2008) [READ: RogueBasin]

Written at the International Roguelike Development Conference 2008; posted by Jeff Lait on 2008-09-16. It scores "how roguelike" a game is; missing a factor does not disqualify it. Canon games: ADOM, Angband, Linley's Dungeon Crawl, NetHack, Rogue.

- High-value factors: random environment generation; permadeath; turn-based; grid-based; non-modal; complexity (many ways to reach a goal); resource management; hack'n'slash (killing many monsters); exploration and discovery (items unidentified fresh each game).
- Low-value factors: single player character; monsters similar to the player; tactical challenge; ASCII display; dungeons (rooms and corridors); numbers shown.
- The page itself notes Darren Grey argues the list is outdated and too narrow.

DD-Project today scores partly: turn-based (yes), single character (yes), numbers shown (yes), resource management (potions/MP, yes), hack and slash (partly), grid-based overworld (16 px grid, yes). It has **no permadeath and no random generation**, the two things most people now mean by "roguelike".

### 1.2 Roguelike vs roguelite [READ: Wikipedia, Rogueliker]

- Traditional roguelike: turn-based, descends from Rogue (1980); death loses everything; the only carry-over is player knowledge.
- Roguelite (also "roguelike-like", "procedural death labyrinth"): keeps procedural generation and permadeath, relaxes the rest, and **lets some progress carry into later runs**. Progression handling is the most common dividing line [READ: Rogueliker].
- Rogue-lites usually have shorter runs with a defined victory condition, and persistent unlocks (characters, items, monsters added to the generation pool) [READ: Wikipedia]. Examples named: Spelunky (2008), Rogue Legacy (2012), FTL (2012).
- Roguelike deckbuilders (Dream Quest 2014, Slay the Spire 2017) resolve combat with cards [READ: Wikipedia]. This is the family D18 puts DD-Project into.
- Josh Bycer's book *Game Design Deep Dive: Roguelikes* has a chapter "The Roguelike Confusion" about exactly this argument [SNIPPET: publisher listing]. Not read.

### 1.3 The knobs between "no roguelike" and "full roguelike" [INFER, built from the games in section 4]

"Somewhat roguelike" is not one switch. Each game picks a setting on each knob:

| Knob | Settings, light to heavy |
|---|---|
| Death consequence | none (JRPG reload) / lose some resources and return to base (Loop Hero loses 70%) / lose the run, keep meta (Hades, Dead Cells) / lose everything (Shiren, classic) |
| Where variety comes from | fixed content / shuffled pools of fixed pieces (enemy lists, loot, offers) / handcrafted chunks assembled by rules (Spelunky, Dead Cells) / fully procedural |
| Run-to-run carry-over | nothing / player knowledge only / sideways unlocks (new cards, classes, modes) / permanent power (stat upgrades) |
| Difficulty ladder | one difficulty / selectable difficulty / unlocked-by-winning ladder (Ascension, Heat, Stakes, Cruciball) |
| Run length | one sitting of 15-60 min (typical) / multi-hour campaign |
| Story | none / fixed prologue / story that advances across runs (Hades) |

DD-Project is currently at the first setting of every knob. The cheap, high-value moves are on knobs 2, 3 and 4 (shuffled pools, sideways unlocks, difficulty ladder), not on level generation.

## 2. What the key sources say

| Source | Tag | Takeaway |
|---|---|---|
| Aaron Steed, "_likes", Game Developer, 2014-07-17. https://www.gamedeveloper.com/design/_likes | READ | Permadeath is fair when the player is warned before a fatal move; players then own their deaths. Rebirth (new body, new place) is why the genre keeps reinventing itself. Inclusive definitions beat strict ones. Turn-based roguelikes share a lot with board games. |
| Slay the Spire, Road to the IGF interview with Giovannetti, Game Developer. https://www.gamedeveloper.com/disciplines/road-to-the-igf-mega-crit-games-i-slay-the-spire-i- | READ | Deckbuilding + roguelike fit; map path choice was inspired by FTL and adds risk/reward "without a ton of complexity". Thousands of cards brainstormed, most cut. Single-player means strong combos are fine. Enemies built to challenge different strategies so no one strategy always wins. Replayability comes from many viable deck permutations, with quick restarts. |
| Slay the Spire, Wikipedia. https://en.wikipedia.org/wiki/Slay_the_Spire | READ | Pick 1 of 3 cards after fights; branching map with elites, campfires, shops, chests, events; relics; Ascension 0-20 unlocked by winning, each level a cumulative penalty; daily fixed-seed run. Early access: "Next Turn" preview replaced by **Intents** icons, later with exact numbers because playtesters found them more engaging; balance used metrics, Netrunner experts and streamers. |
| Giovannetti GDC 2019, "Metrics Driven Design and Balance". Promo: https://www.gamedeveloper.com/design/learn-i-slay-the-spire-i-s-metrics-driven-approach-to-game-balancing-at-gdc-2019 | READ promo only; content SNIPPET | Metrics early and through early access; keep feel and difficulty intact over a year of changes. Third-party summaries (unverified): every card should have a role, metrics can mislead if misread, community feedback and ascension shaped balance. |
| Hades, Wikipedia. https://en.wikipedia.org/wiki/Hades_(video_game) | READ | Rooms are pre-set layouts with random order/enemies; boons are always a choice of 3; death returns you to the House; permanent upgrades there; Pact of Punishment (Heat) is an opt-in difficulty ladder after the first win; about 10 hours of dialogue written as chained events; two-year early access; Supergiant chose the roguelike form because repeated runs suit branching narrative. |
| Kasavin on narrative, Game Developer. https://www.gamedeveloper.com/design/roguelikes-and-narrative-design-with-i-hades-i-creative-director-greg-kasavin | READ | Roguelike players keep knowledge across runs, so the protagonist should too. A boss that remembers past encounters. Build systems so a difficulty wall does not cut story-focused players off from the story. Include many small "dumb" touches because you cannot predict which will land. |
| GeekDad on Kasavin. https://geekdad.com/2019/10/narrative-and-early-access-supergiants-greg-kasavin-discusses-hades-development/ | READ | Characters react to run state (low HP, current area, which gods you already met). Some lines may not repeat for 20-30 loops. One-off story beats mixed with repeating content. Tone: humour that laughs "with you, not at you", a protagonist who tries again. |
| First Person Scholar, "There Is No Escape". https://www.firstpersonscholar.com/there-is-no-escape/ | READ | In Hades, death advances the plot; the character acknowledges each death; the loop itself carries the theme. Quote credited to Kasavin via Klepek 2020: if the player does not forget their deaths and learns from them, neither should the protagonist. |
| Dead Cells, "hybrid approach" (Game Developer / Deepnight). https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach- and https://deepnight.net/tutorial/the-level-design-of-dead-cells-a-hybrid-approach/ | READ | Six steps: (1) fix the world frame by hand, (2) build handmade room chunks per biome, (3) draw a concept graph per biome (entrance, exit, special rooms, length), (4) let the algorithm fill graph nodes from the chunk pool, (5) place monsters from combat-space length (1 per 5 tiles), (6) loot last. "Involve the algorithm in the most restrained way possible." Fully handmade was too slow for a small team; pure procedural gave good combat but incoherent levels. Pacing borrowed from Left 4 Dead's director: peaks and lulls. |
| Dead Cells postmortem, PocketGamer.biz. http://www.pocketgamer.biz/video-a-dead-cells-post-mortem-from-motion-twins-sebastian-bernard/ | READ | About half of development went to making the core loop fun; separate intended challenge from friction. Wikipedia adds: Early Access launched with the game 30-40% complete, and the lead designer estimated 40-50% of final features came from feedback [READ: Wikipedia Dead Cells]. |
| Dicey Dungeons, Road to the IGF. https://www.gamedeveloper.com/disciplines/road-to-the-igf-cavanagh-houston-dobbe-s-i-dicey-dungeons-i- and Wikipedia https://en.wikipedia.org/wiki/Dicey_Dungeons | READ | Started as a 7-Day Roguelike jam entry. Each character solves "how to add uncertainty each turn" differently. Design inverts RPG combat: "you get the RNG up front, and you decide how to make the best of it". **Random cards plus random dice together felt too chaotic**, so layouts were kept static. Balancing strategy against chaos is the hardest part. 1v1 turn-based fights; leveling adds HP and a die; winning unlocks characters and harder episodes. |
| Balatro interview, Rogueliker. https://rogueliker.com/balatro-interview/ and Wikipedia https://en.wikipedia.org/wiki/Balatro | READ | Solo developer, about 2.5 years. Began as a card game for friends, then became a roguelike after Luck Be a Landlord. Run = 8 antes of small blind, big blind, boss blind; a shop between rounds; jokers supply run-to-run variety; Stakes add difficulty after wins. "Possibly too much" randomness; the real meta-strategy is risk reduction. Balanced by feel with number tweaks; watches for cards that crowd out neighbours. Demo feedback shaped the game. |
| Spelunky level generation (Kazemi's analysis). https://tinysubversions.com/spelunkyGen/ | READ | 4x4 grid; a **solution path** is laid first so the exit is always reachable; remaining cells filled with random side rooms. Solvability is guaranteed by construction. |
| Spelunky, Yu's approach, via secondary coverage | SNIPPET | Hand-authored templates chosen by position on the solution path, with randomness inside them (e.g. 33% spike pit). Accept some visible repetition as the cost of scale. |
| Darkest Dungeon, Wikipedia + interview snippets. https://en.wikipedia.org/wiki/Darkest_Dungeon | READ (Wikipedia) | Hamlet (town) is the management layer between procedurally generated dungeon runs; heroes who die are lost for good; stress is the central mechanic; permadeath is paired with imperfect information and "meaningful choices with permanent consequences" (Bourassa, SNIPPET). Early Access complaints (instant heart attacks) led to optional toggles. |
| Rogue Legacy, Wikipedia. https://en.wikipedia.org/wiki/Rogue_Legacy | READ | Gold spent in the manor between lives permanently upgrades stats; heirs have random traits; New Game+ raises difficulty and has a soft cap on power. Reviewers split on frustration vs reward. Developers cut an XP system to streamline. |
| Inscryption, Wikipedia. https://en.wikipedia.org/wiki/Inscryption | READ | Three acts, each re-skinning the same card core. Losing turns your character into a "death card" that returns later; Act 3 uses checkpoints instead of run reset. Grew from a Ludum Dare jam entry. |
| Loop Hero, Wikipedia. https://en.wikipedia.org/wiki/Loop_Hero | READ | Expedition loop; death loses 70% of resources, the rest feeds a base-building meta layer; story advances through bosses, not through the moment-to-moment loop. |
| Peglin, Wikipedia. https://en.wikipedia.org/wiki/Peglin | READ | Jam prototype (48 h) to 400k early-access copies in a year; random map per run; relics; Cruciball difficulty ladder to level 20 after a win. |
| Backpack Hero, Wikipedia. https://en.wikipedia.org/wiki/Backpack_Hero | READ | Grid inventory is the core; hub town upgrades and unlocks characters; each character changes play drastically. Combat reviewed as bland, so the build layer carries the game. |
| Shiren the Wanderer, Wikipedia. https://en.wikipedia.org/wiki/Shiren_the_Wanderer | READ | Death returns you to start and loses everything; fixed floor count per dungeon; scenarios are kept short so the genre is not disturbed. Article does not explain how story and runs connect. |
| Compulsion loop, Game Developer. https://www.gamedeveloper.com/business/the-compulsion-loop-explained | READ | Core loop = main repeated activity. Compulsion loop = the design that makes the behaviour habitual (reward timing). Often used interchangeably. Warns about retention-driven timers and appointment mechanics. |
| Three time scales of loops (various practitioner pages) | SNIPPET | Micro (moment-to-moment), session (run: "is there a just-one-more hook?"), meta (long-term growth). Test for the micro loop: is the action fun with no goals, progression or rewards? |
| Meta-progression critiques (forum threads) | SNIPPET, opinion only | Strong permanent power blurs "was my run good?", makes wins feel hollow, and invites grinding (Rogue Legacy is the usual example). Hades' mirror upgrades are said to make it easy, with Heat as the intended counter. Sidegrades (Hades weapons) and difficulty-raising unlocks are preferred by these posters. |
| Slay the Spire card-reward "pity" | SNIPPET (Fandom and wiki.gg wiki, via search) | Rare chance has an offset starting at -5%, +1% for each common offered, capped at +40%, reset when a rare is offered. First floor of an act cannot offer a rare. Versions may differ. |
| Into the Breach | BACKGROUND | Enemy attacks are telegraphed on the board (near-perfect information), so every loss is the player's decision; the randomness is in the map and loadout, not in the fight. Subset spent four years and threw away several six-month chunks of work (Kotaku, SNIPPET). |

## 3. Distilled principles

Each principle ends with what it means for DD-Project.

1. **Three loops, built bottom-up.** Moment-to-moment (a fight with QTEs), run (floors 1 to the final boss), meta (what you carry to the next run). Dead Cells spent about half of development on making the micro loop fun [READ]. Everything else multiplies whatever the micro loop is worth. *Here:* the roadmap order (QTE and combat core in Phases 4-6, progression in 7) is already right. The run and meta layers should not ship before a fight feels fair (Core Value in `PROJECT.md`).

2. **A choice needs scarcity and an opportunity cost.** Pick-1-of-3 only matters if you cannot take everything. Slay the Spire rewards synergy and builds around it; most card ideas were cut [READ]. *Here:* D18 sets ~5 skills + 5-8 upgrades per class. A run has about 10 floors and several offers per floor, so a player will see nearly the whole pool in one run, and every run converges to "I own everything" [INFER]. Fix with a cap on equipped skills, mutually exclusive upgrade branches (A or B), and shared passive relics (StS relics, Balatro jokers [READ]).

3. **Randomness belongs in the options, not in the outcome.** Dicey Dungeons: RNG up front, player decides how to use it [READ]. Into the Breach: fights are telegraphed, randomness is in the setup [BACKGROUND]. Dicey also found that stacking two random sources felt chaotic [READ]. *Here:* D6 and D20 already remove misses, so combat variance is low. Put variance in what is offered (cards, shop, enemy mix, affixes) and keep fights readable. One random source per decision.

4. **Risk/reward route choices are cheap depth.** The Slay the Spire map came from FTL and adds depth "without a ton of complexity" [READ]. Elite fights vs rest sites vs shops is the whole trick (community guides, about the sequel [SNIPPET]). *Here:* the mini-bosses (Palehorn on floor 5) and the safe-spot merchants (D23) are already the nodes; the missing part is the choice of whether to take them.

5. **Run length: target minutes, not "floors".** Rogue-lites usually have shorter runs with a defined victory [READ]. I found no source giving a number, so the figure is my estimate [INFER]: 20-60 minutes is the usual range [BACKGROUND]. *Here:* a full clean pass is about 10 floors and about 751 total EXP of enemies [REPO, `balance-data.md` section 3], at most a few dozen fights; the real length depends on walking and cutscene time, which nobody has measured. Measure it with the Phase 1 bot before picking a target.

6. **Difficulty goes up by choice, after you win.** Slay the Spire Ascension (20 levels, cumulative, unlocked by winning), Balatro Stakes, Peglin Cruciball (20), Hades Pact of Punishment, Dead Cells Boss Cells [all READ]. This answers the main complaint about meta-progression (it makes the game trivial) because the player, not the game, raises the bar [SNIPPET, opinion]. *Here:* the existing Easy/Normal/Hard (`balance-data.md` section 1) stays as an assist setting; a post-win ladder is separate.

7. **Fail forward: a lost run must still pay.** Hades gives currency, dialogue and story on every death; Inscryption turns your death into a card; Loop Hero keeps 30% of resources; Rogue Legacy turns gold into manor upgrades [all READ]. Kasavin says checkpoint-style retries "kill the pacing" if you keep dying [SNIPPET]. *Here:* every run should end with at least one new thing seen or unlocked.

8. **Show the information the player needs to decide.** Slay the Spire replaced a vague preview with Intents icons, then added exact numbers because testers found them more engaging [READ]. *Here:* D7 (telegraphed defence only on big attacks) and D19 (turn-order bar) point the same way; show the enemy's next big move and the numbers on offered cards.

9. **No dominant build.** Enemies in Slay the Spire are built to challenge different strategies; Balatro's designer watches for items that crowd out neighbours [both READ]. Mega Crit used metrics servers for this [SNIPPET]. *Here:* Phase 8's simulator can compute the same numbers (pick rate, win rate per card) at no player cost. Write the offer system so every offer is logged.

10. **RNG fairness: seeds, bad-luck protection, solvability by construction.** Fixed-seed daily runs exist in Slay the Spire [READ]; its rare-card offset is a pity timer [SNIPPET]; Spelunky guarantees a path before decorating [READ]. Balatro's own author says it has "possibly too much" randomness [READ]. *Here:* one run seed, separate random streams for offers, loot and combat/QTE [INFER]. A seed also makes the test bot (Phase 1) able to replay any run exactly. Add bad-luck protection to the offer system (guarantee at least one offer that fits the owned build after N offers that do not).

11. **Story in a roguelike: let the loop be the story.** Hades: death advances plot, characters react to run state, lines may not repeat for 20-30 loops, and difficulty must not wall off the story [all READ]. Loop Hero advances story through bosses [READ]. Inscryption uses failure as content [READ]. *Here:* the linear story with cutscenes (`rm_cutscene`, dialogue triggers) survives if story flags persist across runs, cutscenes are skippable after first viewing, and boss/NPC lines react to the number of attempts.

12. **Meta-progression: unlock variety, not just power.** Compounding permanent power makes the game easier and invites grinding; sideways unlocks and difficulty ladders avoid that [READ: Rogueliker; SNIPPET: forum opinion]. Rogue Legacy added a soft cap to New Game+ power [READ]. *Here:* D14 already wants "classic JRPG grind". Keep the carry-over to new cards in the pool, new start kits, and harder modes.

13. **Scope: ship the loop, not the content.** Dicey Dungeons (7-day jam), Peglin (48-hour jam), Inscryption (Ludum Dare) and Balatro (solo) all began as a tiny loop that was already fun [READ]. Dead Cells hand-authored the frame and restrained the algorithm because the team was small [READ]. *Here:* build the run layer as a thin vertical slice (floors 1-2, one class) and let the owner play it before spreading it (D11, D12).

## 4. Reference games: loop and what transfers to a small 1v1 turn-based game

| Game | Loop in one line | What transfers | What does not |
|---|---|---|---|
| **Dicey Dungeons** (closest match) | 1v1 turn-based fights on a node map; roll dice, slot them into equipment; win to unlock harder episodes and characters | Same fight shape (one enemy, turn-based). Per-class "identity twist". Static layouts to avoid chaos. Episodes as a difficulty ladder. Light story via a game-show frame. | Dice economy. It is a combat-only game; no exploration. |
| **Slay the Spire** | Branching map; pick 1 of 3 cards after fights; relics; elites and campfires; Ascension | The pick-1-of-3 offer (D18), intents/telegraphs, risk/reward routing, Ascension, daily seed, pity offset, metric-driven balance. | Card-drawing deck cycle (D18 is skills, not a deck). Needs a big card pool. |
| **Hades** | Fixed biomes; random room order and rewards; boons are choices of 3; death returns to hub; Heat opt-in | Fixed biomes with shuffled content. Hub that carries story. Death as story. Opt-in difficulty. Early-access iteration. | Real-time action; dozens of boons; 10 hours of voiced dialogue. |
| **Darkest Dungeon** | Town management between dungeon runs; heroes can die permanently | A camp between runs where the meta layer lives; imperfect information; stress as a resource. | Party of four, roster management. |
| **Inscryption** | Same card core across acts; deaths become cards; checkpoints in Act 3 | Death as content; softer "checkpoint" death rules; a story that frames failure. | Meta-narrative/ARG scope. |
| **Loop Hero** | Auto-fight loop; place terrain cards; die and keep 30%; base-build | Soft death penalty as a middle path; story advanced by bosses only. | Auto-battle. |
| **Peglin** | Pachinko fights; orb deck; random map; Cruciball ladder | Tiny scope; relic synergies; ladder unlocked by winning. | Pachinko core. |
| **Monster Train** | Card battler with multi-floor train; clans; Covenant ranks | Only a thin Wikipedia entry was readable; I have no verified detail. Treat as unverified. | n/a |
| **Backpack Hero** | Tetris-like backpack; map nodes; hub upgrades | Grid inventory as the build layer (an inventory UI exists already, `audit/ui.md`). | Combat is the weak part, so not a model for the fight. |
| **Shiren the Wanderer** | Fixed-length randomly generated dungeons; death loses everything | The "wanderer" frame: short story scenarios that do not disturb the runs. Full item loss is the harshest end of the spectrum. | Procedural floors, item identification. |
| **Dead Cells** | Handmade chunks assembled by a per-biome graph; permanent unlocks via cells and blueprints | The "restrained algorithm" idea; permanent unlocks that add options (blueprints add items to the pool). | Real-time action; chunk authoring is large. |
| **Spelunky** | 4x4 room grid with a guaranteed solution path | Solvability by construction. | Platformer-specific. |
| **Rogue Legacy** | Each death passes to an heir; gold upgrades the manor | Fast restart; every death pays; cautionary tale about grind and the need for a power soft cap. | Platformer. |
| **Balatro** | 8 antes; shop between rounds; jokers; Stakes | Tiny scope; shop-driven build variety; ladder via Stakes. | Poker core. |

## 5. This game, as it is today [REPO]

- **Structure:** 9 handcrafted floors plus 6.5 and 9.5, walked on a 16 px grid in `rm_floor1..9`; touching an enemy starts a 1v1 fight in `rm_battle`; chests, barrels, NPCs, doors and switches; cutscenes in `rm_cutscene`. 3 classes. 10 enemy kinds total (Slime, Dire Wolf, Snake, Spider, Killer Plant, Ghost Sword, Mad Whisp, Stranger, plus Palehorn mini-boss and The Pale Choirbeast final boss) (`balance-data.md` section 3).
- **XP:** one clean pass gives about 751 EXP, level 8 at the final boss; level 10 (1095 EXP) needs grinding. Regular enemies respawn after every save (`Save_Write` calls `Enemy_ResetAll`). D14 keeps "some grind".
- **Resource ownership:** rooms, objects and sprites are IDE-owned (AGENTS.md Rule 4). Anything that needs a new room, enemy object or sprite costs owner time. Anything done in data and GML does not.
- **Already decided and relevant:** D18 cards, D19 turn-order bar, D20/D6 no misses, D23 gold and shop, D16 old saves rejected with a schema version from now on, D12 about 8 unplayed features then bug-hunt only, D1 "new floors, new story, new classes" out of scope.

**What that means for roguelike-ization [INFER]:**

- The cheapest variety is code-and-data variety: which enemies spawn at which spawn point, chest contents, offers, shop stock, enemy affixes, run modifiers, start kits. None needs a new room.
- The enemy roster is small (about 8 normal kinds). Shuffling them alone wears out in a few runs. Affixes (e.g. "armored", "swift", "venomous") multiply 8 kinds into dozens of fights using only data, with no new sprites. This is the same idea as Dead Cells' per-monster rules [READ] but much lighter.
- The card pool (D18) is small; see principle 2.
- Handcrafted floors are an asset, not a limit: Hades' biomes are fixed with shuffled content [READ]. The floors keep the story's pacing.
- The save schema is being designed in Phase 4 (SAVE-01 to 06). **Run state (this run's floor, cards, gold, seed) and meta state (unlocks, flags, best result) should be separate parts of the schema from day one**, even if the owner picks the lightest option. Splitting later means another save break (D16).

## 6. Options, light to heavy

### Option A: "Run mode" on the existing floors (recommended)

Same floors, same story, same classes. A new run starts at floor 1 and ends at the final boss or at death.

- **Shuffled each run (seeded):** enemy mix per spawn point from a floor pool; chest and barrel contents; the card offers (D18); shop stock (D23); optional elite affixes; one run modifier chosen at the start (optional).
- **Death:** the run is lost; you return to a camp and keep meta rewards (see Q2 in section 7).
- **Meta, light:** sideways unlocks (cards added to the pool, alternative start kits, relics), a post-win difficulty ladder (3-5 levels at first), story flags that persist, a best-run record. No permanent stat boosts, or only a tiny capped one.
- **A+ (add-on, still cheap):** at each stairway, a choice of what the next stretch gives (rest, shop, elite fight, mystery) before descending. This is a Slay-the-Spire map without the map.
- **Scope cost [INFER]:** the cards, gold and shop are already in Phase 7. The extra is a "run layer" of roughly one phase: run/meta split in the save, seeded random streams, run-end screen, camp, unlock list, affix and modifier tables, difficulty ladder, and a bot-driven run test. Most of it is GML and data, no new rooms. The camp can be an existing safe spot with an NPC; a dedicated room would be an owner IDE task.
- **Story:** survives. Cutscenes play on first view then become skippable; story-gate flags persist across runs; boss and NPC lines can react to attempts (Hades style). Extra text goes through `game_text.xlsx` and needs Korean (D9).
- **Risks:**
  - The route through the floors is memorised after two or three runs, so variety comes only from encounters and builds (principle 2 and the small enemy roster).
  - Walking the same 10 floors repeatedly can feel like padding unless runs are short, shortcuts exist or walking is trimmed.
  - D14 (grind and respawn farming) pulls against permadeath (Q3).
  - Several small roguelike features count against the D12 unplayed cap; each must be a separate revertable commit.

### Option B: Node map between fixed bosses (Slay the Spire / Dicey Dungeons shape)

Each floor becomes a short branching path of nodes: fight, elite (the mini-boss), shop, rest, chest/event, story beat; a boss at the end. Fights launch straight into `rm_battle` with the floor as backdrop.

- **Scope cost [INFER]:** a map screen and generator, a node/event system, a reworked save, enemy and encounter pools, and a rewrite of how rooms are used. Roughly two to three phases of work; some owner IDE work for the map room and objects.
- **Story:** fits well. Cutscenes and dialogue sit on pinned nodes. Dicey Dungeons carries a light story this way [READ].
- **Benefits:** the best replayability for effort in a 1v1 game; the combat rework gets the most exposure; menu-driven play is friendly to touch and web (D3).
- **Risks:** the handcrafted overworld the owner built is mostly unused, which sits badly with D1 ("same game done right"); exploration charm lost; the enemy roster needs to grow because nothing is discovered by walking; a bigger change than any current phase.
- **Variant B-lite:** keep walking the floors, but add a small route map only between floors (choose which of two paths to take). Cost is between A+ and B.

### Option C: Procedural floors from handcrafted chunks (Spelunky / Dead Cells shape)

Floors assembled at run time from authored room chunks following a per-floor graph.

- **Scope cost [INFER]:** very high. Each chunk is an IDE room or room-like data the owner must author; needs a generator, solvability guarantees, spawn rules, minimap, and chunk art per biome. Dead Cells needed a dedicated design process for this [READ]; Spelunky's generator is simple but depends on a large set of templates [READ/SNIPPET].
- **Story:** story rooms stay fixed set pieces; the connecting rooms become interchangeable.
- **Risks:** highest bug surface (the project has no automated tests yet and two past projects ended "very buggy", `lessons-from-past-projects.md`); out of scope under D1; does not help the combat-centric loop; contradicts the core value (fair fights first). **Not recommended.**

### Recommendation

Do **A**, starting with the thin slice: the seeded random streams and the run/meta save split first (they cost nothing now and a lot later), then the shuffled pools, then affixes, then the difficulty ladder. Evaluate **A+** after the owner has played A for a few runs. Keep **B** as a later milestone candidate if the owner finds the walking to be padding. Skip **C**.

Decisions that must be made **before Phase 4 closes** (save schema) and **before Phase 7's discuss**: Q1, Q2, Q3, Q11 below.

## 7. Decisions for the owner (ask with grill-me, one at a time)

Each has a recommendation. None of these is decided.

**Q1. How roguelike?**
- A. Run mode on existing floors (recommended).
- A+. A plus a choice screen at each stairway.
- B-lite. Walk the floors, route map between floors.
- B. Full node map.
- C. Procedural floors.
- Not at all. Keep the classic game, only add cards and shop.

**Q2. What happens when you die?**
- Full run reset, back to camp, keep meta rewards only (Hades/Dead Cells style) (recommended).
- Restart the current floor, lose some gold/items (Loop Hero style), with limited "death defiance" tokens (Hades has a death defiance token [READ]).
- Run ends only on a boss loss; ordinary death returns to the last stairway (Inscryption Act 3 checkpoint style).
- Player-chosen mode: Classic (save anywhere) vs Run (permadeath).

**Q3. Does the JRPG grind of D14 survive?** Today regular enemies respawn after each save, which makes farming possible. Options: (a) in Run mode enemies do not respawn within a run and XP is tuned so a clean run reaches the planned level (751 vs 1095 EXP gap today) (recommended); (b) respawns stay, runs get long and permadeath hurts more; (c) Classic mode keeps the farm, Run mode does not.

**Q4. Target run length?** 20 min / 40 min / 60 min / "whatever the floors take". Recommendation: measure a bot run first, then aim for 30-45 minutes. If it is much longer, cut walking (shortcuts, fewer rooms per floor) before cutting content.

**Q5. What carries over between runs?**
- Knowledge only.
- Sideways unlocks: more cards/relics in the pool, alternative start kits, extra modes (recommended).
- Small permanent power with a hard cap.
- Full permanent upgrades (Rogue Legacy style). Not recommended; invites grind.

**Q6. Post-win difficulty ladder?** None / 3 levels / 5 levels / 10-20 levels. Recommendation: 5 levels, each a named modifier (tougher elites, fewer potions, stronger boss moves), unlocked by winning, separate from Easy/Normal/Hard.

**Q7. What gets shuffled each run?** Pick from: enemy mix per spawn point; chest and barrel loot; card offers; shop stock; enemy affixes; start-of-run modifier; mini-boss choice from a pool. Recommendation: first five, plus affixes. The mini-boss pool needs new enemy objects and sprites (owner IDE work), so leave it out for now.

**Q8. Seeds?** Always keep an internal seed per run and show it on the run-end screen (lets the test bot and bug reports replay a run). Add a daily or shareable seed? Recommendation: internal seed only; no daily challenge for a friends-and-portfolio release.

**Q9. How is the story handled on repeat runs?** (a) cutscenes play fully every run; (b) first view only, skippable afterwards; (c) first view only, and add short reaction lines to deaths and boss retries (recommended); (d) story only in a separate Story mode. Cost of (c): new strings in `game_text.xlsx` and Korean.

**Q10. Where is the camp?** (a) reuse a floor-1 safe spot with an NPC (recommended, no new room); (b) a dedicated room (owner IDE task, better feel); (c) a menu screen only.

**Q11. How to keep card picks meaningful?** D18 gives about 5 skills and 5-8 upgrades per class, which a single run will nearly exhaust. Options: (a) cap equipped skills (for example 4) so each pick excludes another; (b) make upgrades branch (A or B, not both); (c) add class-neutral passive relics from chests and shop (data only, no animations); (d) all three (recommended); (e) leave as is and accept that runs converge. Needs the owner because it changes D18's pool numbers.

**Q12. Does the first release include any of this?** v2.0's Core Value is fair fights. Options: (a) v2.0 ships Phases 4-7 as planned and the run layer comes after the owner has played the new combat (recommended); (b) fold Option A into Phase 7 and delay the release; (c) leave the roguelike layer for a later milestone but make the save schema and RNG streams ready now (cheapest hedge).

## 8. Suggested next steps

1. Run a grill-me on Q1, Q2, Q3, Q11 (and Q12) before the Phase 4 save-schema work starts.
2. Ask the Phase 1 bot for a timed full-game pass (walking + cutscenes + fights) so Q4 has a real number.
3. In Phase 4, make the save schema carry separate `run` and `meta` blocks and make Phase 7's offer system use its own seeded random stream and log every offer.
4. Keep a short design note per feature so each roguelike feature is its own revertable commit with playtest steps (D12, D17).

## 9. Source list

Read (fetched page content, summarised by a small model):

- https://www.roguebasin.com/index.php/Berlin_Interpretation (fetched as http://www.roguebasin.com/index.php/Berlin_Interpretation)
- https://en.wikipedia.org/wiki/Roguelike (first 100,000 of about 175,000 characters)
- https://www.gamedeveloper.com/design/_likes
- https://rogueliker.com/roguelikes-vs-roguelites/
- https://rogueliker.com/balatro-interview/
- https://www.gamedeveloper.com/disciplines/road-to-the-igf-mega-crit-games-i-slay-the-spire-i-
- https://www.gamedeveloper.com/design/learn-i-slay-the-spire-i-s-metrics-driven-approach-to-game-balancing-at-gdc-2019 (promo only, no talk content)
- https://en.wikipedia.org/wiki/Slay_the_Spire
- https://en.wikipedia.org/wiki/Hades_(video_game) (first 100,000 of about 118,000 characters)
- https://www.gamedeveloper.com/design/roguelikes-and-narrative-design-with-i-hades-i-creative-director-greg-kasavin
- https://geekdad.com/2019/10/narrative-and-early-access-supergiants-greg-kasavin-discusses-hades-development/
- https://www.firstpersonscholar.com/there-is-no-escape/
- https://www.gamedeveloper.com/design/building-the-level-design-of-a-procedurally-generated-metroidvania-a-hybrid-approach-
- https://deepnight.net/tutorial/the-level-design-of-dead-cells-a-hybrid-approach/
- http://www.pocketgamer.biz/video-a-dead-cells-post-mortem-from-motion-twins-sebastian-bernard/
- https://en.wikipedia.org/wiki/Dead_Cells
- https://www.gamedeveloper.com/disciplines/road-to-the-igf-cavanagh-houston-dobbe-s-i-dicey-dungeons-i-
- https://en.wikipedia.org/wiki/Dicey_Dungeons
- https://en.wikipedia.org/wiki/Darkest_Dungeon
- https://en.wikipedia.org/wiki/Rogue_Legacy
- https://en.wikipedia.org/wiki/Inscryption
- https://en.wikipedia.org/wiki/Loop_Hero
- https://en.wikipedia.org/wiki/Peglin
- https://en.wikipedia.org/wiki/Backpack_Hero
- https://en.wikipedia.org/wiki/Shiren_the_Wanderer
- https://en.wikipedia.org/wiki/Balatro (first 100,000 of about 137,000 characters)
- https://tinysubversions.com/spelunkyGen/
- https://www.gamedeveloper.com/business/the-compulsion-loop-explained
- https://en.wikipedia.org/wiki/Monster_Train (readable text was too thin to use)

Search snippets only (not verified against the page):

- Slay the Spire GDC talk coverage: https://gdconf.com/news/learn-slay-spires-successful-metrics-driven-approach-game-balancing-gdc-2019 and https://www.gdcvault.com/browse/gdc-19/play/1025731 (members-only)
- Slay the Spire card rarity offset: https://slay-the-spire.fandom.com/wiki/Card_Rewards (402 on direct fetch) and https://slaythespire.wiki.gg/wiki/Card
- Into the Breach: https://gdcvault.com/play/1025772/-Into-the-Breach-Design and https://kotaku.com/the-creators-of-into-the-breach-came-very-close-to-givi-1833498295
- Hades early access and Pact of Punishment: https://www.pcgamer.com/uk/a-journey-through-early-access-helped-make-hades-a-masterpiece/ (body not delivered), https://kotaku.com/everything-you-need-to-know-about-hades-endgame-1845239105
- Darkest Dungeon interview snippets: https://heavymag.com.au/interview-darkest-dungeon-red-hook-studios/
- Josh Bycer, *Game Design Deep Dive: Roguelikes*: https://www.thevideogamelibrary.org/book/game-design-deep-dive-roguelikes
- Spelunky via secondary coverage: https://www.gamesradar.com/spelunky-retrospective, https://www.tinysubversions.com/spelunkyGen2/index.html
- Meta-progression critiques: forum threads on Lemmy and Steam (opinion only)
- Three-loop framing: practitioner pages from the search "core loop compulsion loop"
- Balatro and Luck Be a Landlord origin: https://www.pcgamer.com/i-dont-play-poker-at-all-says-solo-developer-who-made-the-poker-roguelike-i-cant-stop-playing/ and https://shacknews.com/article/139116/balatro-inspiration-luck-be-a-landlord-reddit-ama

Failed (403, connection refused or not found): gamesofgrey.com; amara.org GMTK transcripts; Slay the Spire wiki.gg card pages (404).
