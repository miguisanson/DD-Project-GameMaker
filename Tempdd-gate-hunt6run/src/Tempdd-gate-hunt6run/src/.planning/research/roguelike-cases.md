# Roguelike case studies and implementation notes

Researched 2026-10-14 for the roguelite turn (D18 pick-1-of-3 cards, D19 turn-order bar, D23 gold and shop).
Companion to DECISIONS.md. Another agent covers general roguelike theory; this file is concrete cases and GameMaker implementation.

Confidence tags used below:
- **[V]** read from a source during this session (URL given).
- **[M]** from memory or inferred; not re-checked. Treat as a lead, not a fact.
- Wiki pages on fandom were blocked (HTTP 402), so Slay the Spire numbers come from slaythespire.wiki.gg. Several wiki pages are marked "under construction".

---

## 0. Answer in brief (what to take away)

1. The two best templates for this game are **Slay the Spire (map, gold, shop, card offer rules)** and **Dicey Dungeons (1v1, 6 floors, level-up reward picks, fights every floor)**. Balatro is the best model for a *readable difficulty curve* and a *small interest-style economy*.
2. Every successful pick-1-of-3 system hides a **bad-luck guard**: Slay the Spire's rising rare chance, its adaptive potion chance, Shattered Pixel Dungeon's "deck" loot, Brogue's "metered" potions/scrolls. None of them is pure dice. Copy one of these patterns; do not ship raw `choose()`.
3. For a seed that reproduces a run, **do not use `random_set_seed` as the run RNG**. Use your own small generator per stream (map, loot, shop, combat), derive each from the run seed, and keep a counter per stream so a save only stores integers. Because D15 ships an HTML5 build, the generator must avoid 64-bit and sign-dependent bit operations (see section 4).
4. Meta-progression that fits friends plus portfolio: **unlock-by-milestone that widens the pool (not raw power)**, a codex, an opt-in difficulty ladder (3 to 5 steps), seed entry. No grind currency.

---

## 1. Case studies

### 1.1 Slay the Spire (the reference)

| Item | Value | Tag / source |
|---|---|---|
| Acts / floors | 3 acts (plus a locked Act 4). 17 map floors per act counting the boss chest floor. Max 6 rooms per floor, 1 to 3 paths in and out | [V] https://slaythespire.wiki.gg/wiki/Map_Generation |
| Room mix (base) | Normal fight 53%, Unknown (event) 22%, Rest 12%, Elite 8%, Shop 5% | [V] same page |
| Fixed floors, Act 1 | Floor 1 is always easy fights, floor 9 is a treasure room, floor 15 is all rest sites (heal before the boss), floor 16 leads to the boss | [V] same page |
| Easy fight pool | First 3 normal fights in Act 1, first 2 in Acts 2 and 3, then the hard pool. Same fight cannot repeat in the next 2 fights | [V] https://slaythespire.wiki.gg/wiki/Monsters |
| Run length | About 50 to 90 minutes for a winning run (median around 90 in one forum report; "at most one hour" in a study) | [V] https://slaythespire.info/en/i-looked-into-the-time-required-for-a-single-run-broken-down-by-character/ (secondary) |
| Gold per fight | Normal 10 to 20, elite 25 to 35, boss 95 to 105 | [V] https://slaythespire.wiki.gg/wiki/Gold |
| Card reward rarity | Normal fight: 60% common, 37% uncommon, 3% rare. Elite: 50 / 40 / 10. Shop: 54 / 37 / 9. Boss: 100% rare | [V] https://slaythespire.wiki.gg/wiki/Card |
| Rare pity ("offset") | Rare chance starts at base minus 5 points. Each common rolled adds 1 point. A rare resets it. Only reward screens count, not shop cards | [V] same page |
| Cards per reward | 3 offered, pick 1 or skip | [M] |
| Card upgrades in rewards | Later acts roll upgraded cards (about 25% Act 2, 50% Act 3) | [M] |
| Potion drop chance | 40% at act start, minus 10 points after a drop, plus 10 after a miss (adaptive) | [V] https://slaythespire.wiki.gg/wiki/Potion (via search summary) |
| Potion rarity | 65 / 25 / 10 (common / uncommon / rare) | [V] same |
| Shop stock | 5 class cards (2 attack, 2 skill, 1 power), 2 colorless cards, 1 card removal, one card 50% off [V partial, via search summary]; relic and potion counts (about 3 each) [M] | [V partial] https://slaythespire.wiki.gg/wiki/Merchant |
| Shop prices | Common card 45 to 55, uncommon 68 to 83, rare 135 to 165. Potion 48 to 105 by rarity. Relic 143 to 158 (common/shop), 238 to 263 (uncommon), 285 to 315 (rare). Card removal 75, then +25 each time | [V] https://slaythespire.wiki.gg/wiki/Merchant |
| Ascension | 20 opt-in steps, each adds one pressure on top of the previous (A1 elites about +60%, A10 double boss, etc.) | [V] partial (elites, A10); the full list [M] |

Rules of thumb you can derive from the numbers [derived]:
- A normal fight pays about 15 gold; a common card costs about 3.3 fights of income, a relic about 10 fights, card removal about 5 fights. That price-to-income ratio is the thing to copy, not the absolute numbers.
- Without elites, an Act 1 run earns roughly 150 gold before the first shop. One shop visit buys about 1 good thing, not everything. This scarcity is why the shop feels like a decision.

Dead-run guards in StS: rare offset, first floor of each act cannot give a rare [V], the fixed rest floor before every boss [V], skip button on every card reward [M], adaptive potion chance [V], card removal in every shop [V], easy-fight pool at the start of each act [V].

**Fits a 1v1 QTE battle game:** map shape and pools (high), gold and shop ratios (high), rarity offset (medium: your class pools are small, see section 2), potions (high, matches D14 potion/MP management), ascension ladder (high).

### 1.2 Dicey Dungeons (closest structural match: 1v1)

- 1v1 combat; the game is a series of "episodes" (runs) of about 6 floors ending in a boss. Maps are connected nodes: enemy, shop, chest, apple (heal), anvil (upgrade), trading post. You may skip fights. [V] https://indie-hive.com/dicey-dungeons/ and https://punishedbacklog.com/dicey-dungeons-review/ (secondary reviews; floor count varies by source, 5 or 6).
- You level up every 2 to 3 fights; level up fully heals, raises max HP, and "occasionally" gives a new die, a new equipment piece or an upgrade. [V] same reviews.
- Episodes add house rules (curses, limits) as optional variety. [V] same.
- Take: a **level-up reward pick** every 2 to 3 fights is exactly your D18 "chest or level-up" and gives roughly 8 to 12 picks in a 25-fight run [derived].
- Fits: very high. Per-class runs, short runs, rule-twist "episodes" are a cheap source of replay (see section 3).

### 1.3 Balatro (difficulty curve and economy)

Base chip requirement per ante (white stake) [V] https://balatrowiki.org/w/Blinds_and_Antes:

| Ante | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Base | 300 | 800 | 2,000 | 5,000 | 11,000 | 20,000 | 35,000 | 50,000 |
| Growth vs previous | - | x2.7 | x2.5 | x2.5 | x2.2 | x1.8 | x1.75 | x1.4 |

- 3 blinds per ante: small 1x, big 1.5x, boss 2x. Rewards $3 / $4 / $5 (showdown $8). You may skip small or big for a tag. [V] same page.
- Interest $1 per $5 held at round end, capped at $5 (cap $25 held), raised by vouchers. [V] https://games.gg/balatro/guides/balatro-economy-guide/ and others.
- Take: requirement per stage is a **number the player can read**; the growth curve decelerates so the last stages are not absurd. Gold interest rewards saving, which makes shop spending a real trade (spend now vs compound). Reroll price rises per use (about $5 base) [M].
- Fits: medium. You do not need interest, but a visible "enemy power per floor" table that you tune in one place (and that the simulator reads, D13) is the lesson.

### 1.4 Monster Train

- 3 bosses; "Covenant" difficulty ladder after first clear (reports say 20 or 25 levels, sources conflict). [V partial] https://bossrush.net/2023/03/game-review-race-through-rings-of-hell-in-monster-train/ and https://gamingtrend.com/feature/reviews/all-aboard-next-stop-hell-monster-train-review
- Post-battle rewards: choice between cards (one from main clan, one from supporting clan), plus upgrades, duplicate/discard, artifacts, events. [V partial] same.
- Each level splits into 2 tracks; a boss every 3 levels. [V partial] same.
- Fits: low to medium. The two-clan card offer (one from "main pool", one from "side pool") is a neat variety guard you can copy: slot 1 always from the class pool, slot 2 always an upgrade of something owned (section 2).

### 1.5 Peglin

- 3 acts, a boss at each act end, node map you can preview; nodes: fights, elite, shop, treasure (guaranteed relic), mystery events, healing, blacksmith (upgrade orbs). Gold from fights buys orbs or upgrades. Harder modes unlock after clears. [V partial] https://siliconera.com/review-peglin-is-perfect-in-pint-sized-doses/ and https://www.ludo.guide/guide/peglin/main-walkthrough/map-navigation-pathing
- Offer counts per fight not verified here.
- Fits: medium (blacksmith as the "upgrade" sink for owned skills, matches your upgrade cards).

### 1.6 Loop Hero

- Run ends by retreat or death; resources kept: 100% on return to camp, about 60% on retreat from elsewhere, 30% on death. [V partial, one source disagrees on the retreat figure] https://twinfinite.net/guides/loop-hero-return-to-camp-how/ and https://www.gfinityesports.com/misc/loop-hero-death-what-happens-when-you-die/
- Camp buildings are the meta layer, funded by those resources.
- Take: **dying still pays something**. That is the cheapest "no dead run" device (you keep gold-to-unlocks, codex entries, etc.).
- Fits: the death-pays idea (high); the loop itself (none).

### 1.7 Inscryption (Act 1)

- 4 regions each ending in a boss, path map, nodes: fight, 3-card pick-1, campfire (upgrade a card's HP or attack, with a chance to destroy it), sacrifice altar (merge sigils), items, trader. 2 lives outside bosses, boss fights are single life. Dying makes a **Deathcard** from your deck that helps later runs. [V partial] https://primagames.com/gaming/inscryption-map-symbols-act-1-guide
- Take: a campfire that upgrades owned stuff with a risk; a death that leaves a gift for the next run.
- Fits: medium (death gift is a good meta idea; sacrificing mechanics no).

### 1.8 Darkest Dungeon (attrition resource)

- Stress 0 to 200; at 100 a hero becomes Afflicted or Virtuous; reaching 200 causes a heart attack (drops to Death's Door; a second kills). Quests come in short / medium / long, hallways and rooms, longer quests give more loot and XP. [V partial] https://darkestdungeon.wiki.gg/wiki/Hopeless and Steam threads in the search results.
- Take: a **second attrition bar besides HP and MP** is what makes "should I push on" interesting. For your game D14 (potions/MP management) already provides this; do not add a third bar.
- Quest length choice (short/medium/long) is a good optional-length idea for your 10 floors (e.g. "3 / 6 / 10 floor run", section 3).
- Fits: low (as a system), medium (as a length choice).

### 1.9 Ring of Pain, Card Crawl / Cardinal Chains, Shiren

- **Ring of Pain:** encounters, items and enemies are all cards arranged in a ring; two are visible, each item type holds one slot; run progress and a "sliver" carry over. [V partial] https://www.thesixthaxis.com/2020/10/15/ring-of-pain-review/ . Floors per ring and bosses not verified. Fits: low.
- **Card Crawl / Cardinal Chains:** single-deck puzzle-style runs; I could not verify numbers [M]. Fits: low.
- **Shiren the Wanderer:** dying loses equipment and gold and returns you to level 1; leaving a dungeon keeps items but resets level to 1. [V] https://mysterydungeonwiki.com/wiki/Shiren_5_DS:Defeat and https://mysterydungeonwiki.com/wiki/Shiren_5_DS:Adventure . Take: it is the harsh end of the spectrum; for friends, copy Loop Hero's gentler rule instead.

### 1.10 Hades (offer rules)

Verified:
- Boons come in Common, Rare, Epic, Heroic (Heroic only through upgrades like exchange/Pom), with Duo and Legendary as separate tiers. A god offer shows 3 or more boons; you pick one and lose the rest. Duo boons need a boon from each of two specific gods and are never guaranteed even then. [V] https://hades2.wiki.fextralife.com/Boon and https://primagames.com/tips/hades-what-are-duo-boons-how-get-duo-boons (mixed Hades 1 and 2 sources)
- A datamine post for the original Hades lists base rarity chances Rare 0.10, Epic 0.05 (plus a 0.12 value that might be the Duo chance); one wiki gives Hermes boons different values. **Low confidence**: sources mix Hades 1 and 2. [V partial] https://steamcommunity.com/app/1145360/discussions/0/2784864483548407451/
- Keepsakes can steer which boon appears next. Empty core slots flood later offers with new core boons (player guide advice). [V partial] https://rogueranker.com/hades-2-boons/

From memory [M], needs a datamine check before relying on it:
- Offers prefer **different slots** (attack, special, dash, cast, call) when possible, and prerequisites for Duos are filled first. I found no sourced rarity "pity timer" in Hades; its guard against bad runs is the "God Mode" damage-reduction ramp after deaths (+2% per death, capped at 80%) [M], and Poms and exchanges that raise the level of boons you already own.
- Take: **slot-based offers** and **"prerequisite unlocks the strong card"** both transfer well to skills plus upgrades: an upgrade card can only appear when its base skill is owned, and a "mastery" card appears only when two related skills are owned.

---

## 2. Reward and offer design (1 of 3)

### 2.1 What the cases actually do

| Technique | Who | What it solves |
|---|---|---|
| Weighted rarity with a rising rare offset | Slay the Spire [V] | long droughts of rares |
| Adaptive percent (+10 on miss, -10 on hit) | StS potions [V] | potion droughts and floods |
| Deck-style loot: probabilities decrement as items are picked, reset when all hit 0 | Shattered Pixel Dungeon [V] https://github.com/00-Evan/shattered-pixel-dungeon (`items/Generator.java`: "some item types use a deck-based system, where the probs decrement as items are picked until they are all 0, and then they reset") | duplicates and long droughts, evens out category mix |
| Guaranteed quota per floor set, chance = needed / floors left | SPD upgrade scrolls (3 per 5-floor set), strength potions (2 per set), via `Dungeon.souNeeded()` [V] same repo, `Dungeon.java` | guarantees the power curve without fixed placement |
| "Metered" item frequency: base frequency rises every level and drops when the item generates | Brogue CE [V] https://github.com/tmewett/BrogueCE (`Items.c`, `rogue.meteredItems[...].frequency += incrementFrequency`) | guaranteed enchant scroll / life potion cadence |
| Two RNG streams: substantive (gameplay) and cosmetic (effects) | Brogue CE [V] `Math.c`, `RogueMain.c` (`RNG_SUBSTANTIVE` / `RNG_COSMETIC`) | seeds reproduce even if effects change |
| Per-level seed derived from run seed | Brogue CE `levels[i].levelSeed`, SPD `Dungeon.seedForDepth` with `Random.pushGenerator` / `popGenerator` [V] | revisiting or skipping a level never desyncs the rest |
| Two-pool offer (main clan + side clan) | Monster Train [V partial] | variety |
| Skip on every reward | StS [M], Balatro skip tags [V] | player can refuse a bad offer |
| Plain random unique picks from a list | Slay the Web (`getCardRewards`: draw random cards, reject duplicates by name) [V] https://github.com/oskarrough/slaytheweb `src/game/cards.js` | the simplest possible baseline, and what *not* to stop at |

### 2.2 Recommended generator for D18 (derived, not copied)

Your pool per class is small (about 5 skills + 5 to 8 upgrades = 10 to 13 entries). With a pool that small, rarity tiers and rare offsets add little; **composition rules** matter more.

Per offer of 3 slots, drawn from the `loot` RNG stream:
1. Build the candidate list: unowned class skills, upgrades whose base skill you own and that are not yet taken, plus 1 or 2 fallback cards (heal, gold, max HP) so the list never has fewer than 3 entries.
2. **Slot A:** a new skill if any unowned remain (weights: skills you have fewest of in an element/role get more weight). **Slot B:** an upgrade of an owned skill if any exists. **Slot C:** weighted random from the rest. This is the Monster Train two-pool idea with a guaranteed mix.
3. Never show the same entry twice in one offer. Do not show an entry you declined in the previous offer more than once (a "decline memory" of one offer). Prerequisites decide eligibility (Hades Duo idea).
4. **Ratio of new skill vs upgrade:** weight new skills heavily while the player owns fewer than 3 skills, upgrades heavily afterwards. This mirrors Hades where empty slots flood offers. Suggested starting weights: new skill 3 / upgrade 1 while owned < 3, then 1 / 3.
5. **Pity:** keep one counter, `offers_since_upgrade_of_main_skill`; after 2 offers with no upgrade of a skill the player has used 3 or more times, force one. That is the Brogue "metered" idea reduced to a counter.
6. **Quota guarantee (SPD style):** the run guarantees N power picks per floor group. With 10 floors, give a pick at fixed milestones (for example floors 1, 2, 4, 6, 8, 10 plus level-ups) and let random chests add extras. Chance of a chest pick = picks still owed / chests left.
7. **Rarity:** if you keep rarity at all, use it for *effect strength* of upgrades (+1 / +2 tier) with the StS offset trick: chance starts low, rises each offer that has none, resets on a hit.
8. **Skip button:** always allow skip for a small gold payout (a value near one fight of gold). It removes the "nothing I want" frustration.

### 2.3 Avoiding dead runs (checklist)

- Guaranteed heal source before every boss (StS fixed rest floor [V]) and a guaranteed potion trickle (adaptive potion chance [V] or Brogue-style meter [V]).
- Never let an offer contain only unusable entries: the fallback cards in 2.2 step 1.
- Shop always stocks one heal potion and one removal/respec-type service (StS removal [V]).
- Death or giving up still pays something (Loop Hero [V partial], Inscryption Deathcard [V partial]).
- Early fights use an "easy pool" (StS [V]) and floor 1 never has anything cruel.
- Optional "God Mode" style assist after repeated deaths (Hades [M]). Cheap for a friends audience, off by default in the ladder.
- Make the simulator (D13) measure "runs that cannot win" with seeds: if a seeded run has no viable build by floor N, the generator needs a stronger guard.

---

## 3. Meta-progression without grind

Patterns seen in the cases:

| Pattern | Cases | Verdict for this game |
|---|---|---|
| Opt-in difficulty ladder, each step adds one pressure, all steps cumulative | StS Ascension (20) [V partial], Monster Train Covenant [V partial], Peglin harder modes [V partial], Balatro stakes [M], Hades Heat [M] | **Yes.** Build 3 to 5 steps. It is the cheapest long-term replay and costs only data (modifiers on enemy stats, gold, shop prices) |
| Unlocks that widen the pool, not power (new cards, classes, starting options) | StS unlocks, Balatro unlocks by in-game goals [M] | **Yes.** Unlock extra class skills and upgrade cards by milestones such as "clear a run with class X". Every unlock adds choices, not stats |
| Spend-currency meta upgrades (Hades Mirror, Loop Hero camp) | Hades [M], Loop Hero [V partial] | **Careful.** Powerful but is grind and needs balance work. If used, keep it tiny (a few starting options, not +damage) |
| Codex / bestiary with discovered entries | StS, Slay-The-Robot has a sample codex [V] https://github.com/DesirePathGames/Slay-The-Robot | **Yes.** Costs little and is good portfolio material; also helps the translation check (D9) because it lists every string |
| Death leaves something (gift, partial payout) | Inscryption Deathcard [V partial], Loop Hero 30% [V partial] | **Yes**, in a small form (codex progress, unlock progress counters) |
| Run modifiers / episodes with special rules | Dicey Dungeons [V], Balatro challenge decks [M] | **Later.** Good low-cost extra; same mechanism as the ladder |
| Seeds: enter a seed, or a daily seed | SPD: daily seed offset above user-enterable range [V] `Dungeon.java` | **Yes** as it is nearly free once streams exist (section 4) and gives friends something to compare |
| Run length choice (short / medium / long) | Darkest Dungeon [V partial] | **Maybe.** 3, 6 or 10 floors would help portfolio demos and Android later |
| Achievements | most | **Yes** as the unlock trigger, not as a separate system |

Recommended first set: ladder (4 steps) + milestone unlocks + codex + seed entry. Park Hades-style currency and episodes.

---

## 4. Implementation in GameMaker

### 4.1 What GameMaker's RNG can and cannot do

- Built-in RNG is one global generator (WELL512 per the author of the PRNG extension). `random_set_seed` sets it; `random_get_seed` returns the *last seed set*, not the current state, so you cannot save and restore the position in the sequence. [V] https://yal.cc/gamemaker-custom-prngs/
- Calling `random_set_seed` before each roll skews results badly (the article's test: some values about 3x too often, others never). [V] same.
- The manual says a fixed seed is consistent per platform but "results may vary between platforms". [V] https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Maths_And_Numbers/Number_Functions/random_set_seed.htm (quoted via search summary)
- Any unrelated random call (a particle, a screen-shake offset) shifts the global sequence and breaks reproducibility. [V] yal.cc article. Existing code in this repo has 25 `irandom`/`choose` style calls and one `randomize()` (`scripts/scr_player/scr_player.gml:1530`), so a seed-reproducible run needs those call sites reviewed.
- **HTML5 hazard [M, inference, not found in any source]:** HTML5 numbers are doubles and bitwise operators there truncate to 32-bit signed ints, so a 64-bit xorshift or any `>>` on a value with the sign bit set can differ from Windows. The GameMaker manual itself says only that HTML5 reals are doubles. Test, do not assume.

### 4.2 Recommended design: counter-based streams

Goal: one run seed reproduces the whole run on Windows and web, and a save file stores only a few integers.

1. `run_seed` is one integer (display it as a short code).
2. Each stream gets a seed derived from the run seed and a label: `derive(run_seed, "map", floor)`, `derive(run_seed, "offer", offer_index)`, `derive(run_seed, "shop", shop_index)`, `derive(run_seed, "enemy", floor)`. Because the stream is *recreated from (label, counter)*, skipping, retrying or loading never desyncs another stream. This is exactly what SPD (`seedForDepth`) and Brogue (`levelSeed`) do. [V]
3. Combat/QTE stays on its own stream and is mostly player-driven anyway. Cosmetic randomness (shake, particles, idle animation) keeps using plain `random()`; it never touches the run streams (Brogue's cosmetic stream idea [V]).
4. For `derive`, use a hash that is deterministic on every platform. `md5_string_utf8` / `sha1_string_utf8` exist in GML; take a few hex characters and convert them manually (design [M], needs a cross-platform test).
5. Generator choice, in order of safety on HTML5:
   - **MINSTD / Park-Miller (state = state * 48271 mod 2147483647).** Uses no bit operations; the product stays below 2^53, so it is exact in doubles and in 64-bit ints. [inference] Quality is fine for card offers and map choices.
   - **GMXorWow** (XorWow / XorShift32 / XorShift128). MIT. Its README says it uses only 32-bit unsigned operations "to generate pseudorandom numbers consistently across all exports given the same starting seed", accepts string seeds, and has seeded `array_shuffle`, `choose`, `irandom_range`. [V] https://github.com/dicksonlaw583/GMXorWow
   - Avoid the 64-bit xorshift for the run RNG because of HTML5 [M].
6. Add a **golden-sequence test**: seed 12345, first 100 outputs of each stream compared with a stored list. Run it on the Windows build and on the HTML5 export; a mismatch means do not ship seeds. This fits the AGENTS.md Rule 1 style GML assertion block, and the Python simulator (D13) can re-implement MINSTD in three lines to produce the same golden list.

### 4.3 Libraries and examples (URLs, licence, what to reuse)

| Name | URL | Licence | Reuse |
|---|---|---|---|
| GMXorWow | https://github.com/dicksonlaw583/GMXorWow | MIT [V] | Independent seeded generators (XorWow, XorShift32/128), string seeds, seeded shuffle/choose/range, `toArray` / `toStruct` for saving state. Check HTML5 with the golden test |
| YAL-GameMaker/prng (YellowAfterlife) | https://github.com/YAL-GameMaker/prng , blog https://yal.cc/gamemaker-custom-prngs/ , docs https://yal.cc/docs/gm/prng | Custom licence: the repo's LICENSE says "legal code pending", with a Commercial definition (pay-what-you-want with no minimum is not commercial); itch.io page is paid ($6.95+) [V] | Read the article for the trade-offs (struct vs global speed, saving state, WELL512 replica). Do not copy code without reading the licence. Its 32-bit xorshift macro: `state ^= (state << 13) & $FFFFFFFF; state ^= state >> 17; state ^= (state << 5) & $FFFFFFFF` [V] |
| Mersenne Twister Random Engine (Marketplace asset 9646) | https://marketplace.gamemaker.io/assets/9646/mersenne-twister-random-engine | Marketplace licence, last update 2021 [V partial] | Not needed |
| GMRoomLoader v3.1.1 | https://github.com/GlebTsereteli/GMRoomLoader , docs https://glebtsereteli.github.io/GMRoomLoader/ | MIT, 135 stars, pushed 2026-08 [V] | Loads the contents of any room into the current room at runtime, with tags (`tag_get_asset_ids("DungeonChunk", asset_room)`), mirror/flip, and a payload to clean up. Use for "stamp pools" of encounter layouts. Targets GameMaker LTS 2026; **check the project's GameMaker version first** |
| GMRoomLoader Spelunky tutorial | https://github.com/GlebTsereteli/GMRoomLoader-Spelunky-Tutorial | CC0 [V] | A worked example of assembling a seeded path of handcrafted rooms |
| SNAP (JujuAdams) | https://github.com/JujuAdams/SNAP | MIT [V] | JSON/other format to struct and array, useful to load data-driven definitions; also `snap_string` for debugging structs. The repo already uses `json_parse` in `scripts/scr_save/scr_save.gml`, so SNAP is optional |
| Lexicon (tabularelf) | https://github.com/tabularelf/lexicon | MIT [V] | Localization system for GameMaker; compare with the xlsx to json pipeline before deciding to keep the current one (D9) |
| GM-Testing-Library | https://github.com/DAndrewBox/GM-Testing-Library | MIT [V] | Simple test framework for GML, a candidate for the "GML assertion block" in AGENTS.md |

**Finding:** I searched GitHub for GML roguelike deckbuilders and seeded-RNG libraries. There is **no mature, permissively licensed GML card system or run manager** to adopt. Small hits exist (`bakkerjoeri/cantrip` card roguelite from 7DRL 2019, language shown as Yacc, no licence; `LeguillonPatrick/game-programming-portfolio` MIT, procedural-generation systems; `alexcwarren/arkham-horror` MIT, Arkham Horror card game; `Zayzoon-15/Kaos-Kards`, licence unclear), and I did not read their code in depth. Plan to write the run manager yourself and borrow *ideas* from the engine-agnostic projects in section 5.

### 4.4 Run state vs persistent profile (save split)

Two separate files so a corrupt run never destroys unlocks (this ties into D16 clean break and the `save-systems` skill):

```
profile.json   (long-lived)                  run.json   (deleted on run end)
  schema_version                               schema_version
  unlocked_skill_ids / upgrade_ids             run_seed, ladder_level, class
  codex_seen: enemies, skills, items           floor_index, node_index
  best_floor, runs_started, runs_won           player: hp, mp, level, stats
  ladder_unlocked per class                    owned_skills[{id, upgrade_level}]
  settings (language, volume, scale)           gold, inventory
  last_build_id                                stream counters {map, offer, shop, enemy}
                                               offers_since_upgrade, potion_chance, rare_offset
                                               floor_flags (chests opened, shop stock bought)
```

- Because streams are derived from (seed, label, counter) (4.2), the run file stores **counters, not generator states**. A save-then-reload at an offer screen shows the same three cards (also stops save-scumming for better offers, a point the yal.cc article raises [V]).
- Existing `scr_save` already writes JSON through `buffer_save`; add `schema_version` and reject older ones with a friendly message (D16).
- Write to a temp file then rename, as the `save-systems` skill describes. On HTML5 the file system is a browser sandbox, so test that the save survives a reload [M].
- Save at node entry (before the offer is generated) so a crash cannot produce a different offer.

### 4.5 Procedural room selection from handcrafted room pools

Current repo: whole-floor rooms `rm_floor1` ... `rm_floor9_5`, `rm_battle`, `rm_start`. Resources are IDE-owned (AGENTS.md Rule 4), so new rooms must be created in the IDE by the owner or a remote session, not by hand-editing `.yy`.

Options, from lowest cost:
1. **Floor variants.** Keep each floor as a room, add 2 to 3 handcrafted variants per floor (`rm_floor3_a/b/c`) and pick with the `map` stream; tag them so a script can list them with `tag_get_asset_ids("floor3", asset_room)`. No library required.
2. **Node map over fights.** Keep rooms for story and bosses; build the between-fights map (StS style) as data, and use `rm_battle` for fights with an encounter definition. This matches D1 (same game, floors and story) and the 1v1 combat design.
3. **Stamp encounters or props with GMRoomLoader** [V] if you want layout variety inside a floor. Heavier; only if exploration rooms matter.

Selection rules worth copying (StS [V]): easy pool for the first fights of a floor group; no repeat within the last 2 picks; fixed floors for rest and boss; weights per node type.

### 4.6 Data-driven card / skill definitions

- Current state: `scr_db_skill` builds a `ds_map` of structs in code (`id, name, mp_cost, power, stat_type, status, ..., class_list`), `scr_loot` holds item tables in code.
- Recommended: move **gameplay numbers** (power, mp_cost, tags, class_list, rarity/weight, prerequisites, upgrade chain `base_id -> [plus1, plus2]`) into a JSON file under `datafiles/`, loaded with `json_parse` (already used in `scr_save`). Keep **names and descriptions as localization keys**, not in the JSON (project rule: strings go through `game_text.xlsx`). Keep **sprite references as strings** resolved with `asset_get_index` at load.
- Why JSON and not code: the Python simulator (D13) and the localization/lint tools can read the same file, so the simulator and the game cannot drift apart. This is the main benefit.
- Struct shape for an upgrade card, sketched:
  ```
  { id:"ice_spear_plus", kind:"upgrade", base:"ice_spear", tier:1,
    requires:["ice_spear"], weight:3, effects:{power_add:2, mp_cost_add:0}, tags:["ice"] }
  ```
- Reference designs: Slay-The-Robot generates card JSON payloads, packs of cards queried by class, and an action/validator/interceptor split so tooltips and real effects share one code path [V] https://github.com/DesirePathGames/Slay-The-Robot (MIT, Godot; read for structure, not to copy code). That "tooltip uses the same calculation as the action" rule is directly the answer to D24 (Foresight must show what it does).
- Schema check: at load, validate that every `requires` / `base` id exists and every card has a localization key; fail loud in debug.

---

## 5. Open-source turn-based roguelikes to read

| Project | URL | Licence | What to look at |
|---|---|---|---|
| Shattered Pixel Dungeon | https://github.com/00-Evan/shattered-pixel-dungeon | GPL-3.0 [V] | `items/Generator.java` (deck-based loot and category probs), `Dungeon.java` (`LimitedDrops`, `posNeeded`/`souNeeded` quota logic, `seedForDepth`, daily seed, `pushGenerator`/`popGenerator`). Read for ideas only; GPL means do not copy code into this project |
| Brogue CE | https://github.com/tmewett/BrogueCE | AGPL-3.0 [V] | `Items.c` metered item frequency, `Math.c` two RNG streams, `RogueMain.c` per-level seeds, `SeedCatalog.c`. Ideas only |
| Slay the Web | https://github.com/oskarrough/slaytheweb | AGPL-3.0 [V] | Small StS clone in JS: `src/content/cards/*.js` (one file per card), `src/game/dungeon.js`, `rooms.js`, `actions.js`. Its reward code (`getCardRewards`) is plain random unique picks, a useful baseline to beat. Ideas only |
| Slay-The-Robot | https://github.com/DesirePathGames/Slay-The-Robot | MIT [V] | Data-driven card/artifact/shop/event framework (JSON, content packs, validators, interceptors, codex). Best structural reference |
| End of Eden | https://github.com/BigJk/end_of_eden | MIT [V] | StS-like in a console, Lua scripted content, mod-friendly; shows cards/artifacts/enemies as scripts plus data |
| Cantrip (AGomnes) | https://github.com/AGomnes/Cantrip | MIT, C#/Godot [V] | "Rules language" for cards, abilities, statuses, relics and enemies as short scripts with their own tests; a model for testing card interactions |
| Worlds Upon The Wind | https://github.com/max99x/wutw-public | CC0, GDScript [V] | A shipped roguelite deckbuilder released into the public domain; usable as a full reference |
| Slay the Spire Map in Unity | https://github.com/silverua/slay-the-spire-map-in-unity | MIT, C# [V] | StS-style map path generation, node randomization, cross-path elimination, map save. Port the algorithm to GML if you build a node map |
| Dungeon Crawl Stone Soup | https://github.com/crawl/crawl | GPL-style (repo reports NOASSERTION) [V] | `crawl-ref/source/dat/` monster and item data tables for scaling numbers. Ideas only |
| ModTheSpire | https://github.com/kiooeht/ModTheSpire | MIT [V] | Not game data, but shows how the StS modding community exposes card/relic definitions; the StS game code itself is not open and must not be copied |
| rot.js | https://github.com/ondras/rot.js | BSD-3-Clause [V] | Seeded RNG (`RNG.setSeed`, `getState`/`setState`, `getWeightedValue`), reference for a weighted-choice helper |
| Pixel Dungeon (original) | https://github.com/watabou/pixel-dungeon | GPL-3.0 [V] | The ancestor of SPD, simpler to read |

Licence rule for this repo: it is a free release for friends and portfolio (D2), but GPL/AGPL code cannot be pasted in without changing the licence of the whole project. **Read GPL/AGPL projects for ideas; copy only from MIT/CC0 ones** (GMXorWow, GMRoomLoader, SNAP, Slay-The-Robot patterns, the Unity map algorithm with credit).

---

## 6. Concrete recommendations for this project

1. **Run shape (proposal, [derived] from StS and Dicey Dungeons):** about 10 floors, 2 to 3 fights per floor (about 25 fights), 1 mini-boss every ~3 floors, final boss at floor 10, 1 rest/shop stop between floors. Target 30 to 45 minutes. Pick moments: level-up every 2 to 3 fights plus chests, giving about 8 to 12 card picks per run. Needs a grill-me before committing (it is the owner's call).
2. **Economy ratio:** price in multiples of average fight gold *g*: small potion 2 to 3 g, big potion 5 to 6 g, skill upgrade removal/respec 5 g (+1 g each use), gear tier 8 to 10 g, one shop visit affordable about 1 or 2 items. Elite fights pay about 2x, bosses about 6 to 7x (StS ratios [V]). Put the table in a single data file that the simulator reads (D13).
3. **Offer generator:** slot rules from 2.2, a quota guarantee, a skip for gold, and one pity counter. Build it as a pure function `Offer_Generate(stream, run_state, pools)` so it can be unit-tested and run in the simulator thousands of times (measure: fraction of offers with at least 1 upgrade, fraction of runs with no usable build).
4. **Streams:** counter-based derived streams (4.2), MINSTD or GMXorWow, golden-sequence test on Windows and HTML5 before D15 ships.
5. **Meta:** ladder of 3 to 5 steps, milestone unlocks that widen pools, codex, seed entry. No spend currency this milestone.
6. **Build order that fits D12 (about 8 unplayed features cap):** (a) RNG streams + golden test + run/profile save split, (b) data-driven skill/upgrade JSON, (c) offer generator + simulator report, (d) gold + shop, (e) node map or floor variants, (f) ladder + unlocks + codex. Each its own revertable commit with playtest steps.

## 7. Open questions for the owner (do not guess)

- How many fights per floor and how long should a run be? (changes picks per run, shop count, ladder tuning)
- Should death keep anything (Loop Hero / Inscryption style) or is a lost run simply lost?
- Is a node map (StS style) wanted, or do floors stay linear with a shop between them?
- Are seeds a player-visible feature (share a seed with a friend) or only a developer tool for the simulator?

## 8. Not found or not verified

- Slay the Spire card-reward count (3), upgrade chance by act, and card reward gold amounts per act: from memory only.
- Hades 1 offer rules (slot variety, prerequisite priority, any rarity pity) and exact base rarity chances: only a low-quality datamine mention found.
- Monster Train, Peglin, Ring of Pain, Card Crawl: no per-run reward counts or prices found; use only as shape references.
- Balatro shop prices and reroll formula: not found, only reward money and interest.
- HTML5 behaviour of bitwise operators and `random_set_seed` determinism in GameMaker: no source found; must be tested on the actual export.
- No GML card system, run manager or PCG implementation found on GitHub.
