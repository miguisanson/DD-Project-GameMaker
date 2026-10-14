# Icon art v2: visual references and conventions

Written 2026-10-14 for the D2 icon pass (v2). Owner feedback on v1: "they are okay but can be better, take inspiration from
other games instead of coming up with them." This file records which conventions other games and free packs use for each icon
family, and which of them the v2 icons borrow. It is **inspiration only**: no copyrighted pixels were copied. The only third-party
pixels used are CC0 (Kenney 1-Bit Pack, optional candidates; see `art/CREDITS-ART.md`).

**Evidence labels** (same scheme as `.planning/research/icons-comfyui.md`): **[source]** = read on a page during this pass (link at the
bottom). **[known]** = my own background knowledge of the games, **not re-checked today**; treat it as a lead, not a fact.
Honest limitation: web search and fetch returned almost no description of the *artwork* of most of these games (wiki pages show the
icon images but the text does not describe them), so most visual notes below are [known]. Where a [source] exists it is marked.

## 1. Shape language chosen for v2 (the rules every v2 icon follows)

| Rule | v2 choice | Why |
|---|---|---|
| Palette / grid | 4 colours `#071821 #306850 #86C06C #E0F8CF`, 16x16, binary alpha | D10 |
| Buff vs debuff | by **shape**, not colour (D78, `retro-ui.md` rec. 3): **debuffs = round badge**, **buffs = chamfered-square badge**; skills/items have no frame | The palette is four greens, so hue cannot carry meaning. FF7 Remake does it by hue (blue good, red bad, yellow mixed) **[source]**; Darkest Dungeon by arrow direction and hue (blue up arrows = buff, orange down arrows = debuff) **[source]**. We use frame shape as the always-readable channel. |
| Light | from the **top-left** everywhere: `#E0F8CF` rim on top-left edges, `#306850` shade on bottom-right | One light direction makes a set read as one set. Kenney-style 1-px edges + Game Boy era item icons do the same **[known]**. |
| Outline | 1 px `#071821` on the outside of every shape, and around every glyph inside a badge | v1 mixed glyphs with and without outline. |
| Glyph size | badge glyph body at most 9x9 (11x11 with outline); item bodies at most 14x14 (16x16 with outline) | Fits the round badge without touching the ring. |
| Skill icon = status icon | a skill that applies a status reuses that status's glyph language (Evasion = feather, Take Aim = crosshair, Foresight = eye, Meditation = lotus, Rev Up = up arrow) | Players learn one symbol per concept (Darkest Dungeon glossary lesson in `retro-ui.md`). |
| Foresight | an eye (D24) | D24 |

## 2. Conventions per icon family

"v2 uses" says what the shipped v2 candidate borrows. Colours in the games are given only to explain the symbol; the game palette is monochrome green.

### Status effects

| Family | Convention in other games | v2 uses |
|---|---|---|
| **Poison** | Green or purple droplet, usually with bubbles or a skull; "toxic" green is near universal. Slay the Spire's poison is the only debuff that has both intensity and duration, which is why it is drawn as a counter-friendly single symbol **[source for the mechanic, icon art not described by the page]**. Pokemon uses a purple "PSN" badge on the HP box **[known]**. | Droplet + two rising bubbles. |
| **Burn** | Flame (teardrop with inner flame); orange/red. Pokemon "BRN" is an orange badge **[known]**. | Teardrop flame with a lighter inner flame. |
| **Bleed** | Red drop, "hovering shows turns left" in Darkest Dungeon **[source]**; in DD the bleed token is a red drop and poison/blight a green-yellow one **[known]**. | A pointed drop (lighter body than poison's) so the two drops differ by silhouette: poison has bubbles, bleed has none. |
| **Stun** | Darkest Dungeon: **yellow crescent with diamonds above the character's head**, one turn, then a 50% stun resistance **[source]**. Shiren: **yellow birds circling the head** for confusion, "Z"s for sleep **[source]**. Cartoon "dizzy stars" circling the head is the genre default **[known]**. | Three small four-point stars arranged in an orbit. |
| **Break / stagger** | Octopath Traveler: each enemy has a shield-point number and weakness icons; hitting the weakness lowers it, at 0 the enemy is **Broken**, loses its turn and takes bonus damage; unknown weaknesses show "?" **[source]**. So break = a shield that cracks. | Shield with a lightning crack and a chipped corner. |
| **Sundered** (defence loss) | Same idea as break, but permanent-ish: a damaged armour piece. Many RPGs show "Defence Down" as shield/armour plus a down arrow **[known]**. | Cracked breastplate with a gap. |
| **Curse** | Skull, often with a hex/dark aura; Slay the Spire has a Hex debuff **[source: name only]**. | Skull. |
| **Guard / defence up** | Shield. Darkest Dungeon draws buffs as blue double up arrows under the target **[source]**; Pokemon shows "stat rose" with up chevrons **[known]**. | Kite shield with a cross, in the buff (square) badge. |
| **Attack up (Rev Up)** | Sword or fist plus an up arrow; red up chevrons in Pokemon **[known]**. | Bold up arrow (skill) in the buff badge. |
| **Evasion** | Winged boot or feather/wind lines; FF "Haste" is a clock/hourglass or boots **[known]**. | Feather (reads at 9x9 where a boot did not in v1). |
| **Speed** (passive) | Double chevron ">>" with speed lines (fast-forward symbol) **[known]**. | Same, with three speed lines. |
| **Crit / aim** | Crosshair or bullseye for accuracy; starburst/jagged explosion for critical hit (also used by many card games for "crit") **[known]**. | Take Aim = crosshair; Critical passive = jagged starburst (v1 used a clover, which means *luck*; the clover stays as the v1 option). |
| **Foresight / eye** | Eye with iris and pupil; FF "Libra/Scan" and Zelda "Lens of Truth" are eyes **[known]**. D24 requires an eye. | Almond eye, iris, dark pupil with a highlight, sparkle marks above. |
| **Meditation / MP** | Lotus flower or a meditating figure; MP is usually a star or a blue gem **[known]**. | Three-petal lotus with a small sparkle. |
| **Solidify** | Stone block / gem; "Stone" in FF is a grey statue **[known]**. | Bevelled stone block with a crack line. |
| **Bloodthirsty** | Vampire fangs, sometimes with a blood drop **[known]**. | Two fangs and a falling drop. |
| **Blessing** | Halo, angel wings, sparkle; FF7R colours beneficial effects blue **[source]**. | Halo above a pair of wings. |
| **Steadfast** | Anchor, rock, or a castle tower (rook); "unmoving" **[known]**. | Anchor (D-docs do not define Steadfast; the anchor is the v1 choice kept). A rook is a Kenney CC0 alternative. |

### Skills (weapon / magic)

| Family | Convention | v2 uses |
|---|---|---|
| **Sword skills** | Diagonal blade from bottom-left to top-right, crossguard, short grip; Kenney 1-Bit, Zelda: Link's Awakening and FF1-6 weapon icons all use this diagonal at 16x16 **[known]** (Kenney confirmed by sheet inspection). | Diagonal blade with rim light on the upper edge. Wound adds a blood drop, Power Strike adds impact marks, Hilt Bash shows hilt plus impact burst. |
| **Arrow / bow** | Diagonal arrow with feather vanes at the tail; two arrows for multi-shot; Kenney has bow and arrow tiles **[known]**. | Arrow with a drop (Poison Arrow), two parallel arrows (Double Shot). |
| **Magic** | Fireball = round orb with a flame tail; ice = pale crystal shard or icicle; cloud = lumpy cloud with face/skull for poison gas **[known]**. | Orb with tail, crystal spear, face-less cloud with dark eyes plus drips. |
| **Slash** | Wide crescent arc with tapered ends (Kenney 1-Bit tiles 24-26,11 are slash marks) **[known]**. | Arc with a speed line. |
| **Power-up skills** | Fist or flexed arm plus an up arrow **[known]**. | Fist plus up arrow (Muscle Up). |

### Items

| Family | Convention | v2 uses |
|---|---|---|
| **Bombs** | Round dark body, short neck, fuse with a spark: Zelda and Bomberman **[known]**. Smoke = bomb under a puff cloud. | Dark `#306850` body with light highlight arc, `#86C06C` neck, `#E0F8CF` spark/flame. |
| **Potions / flasks** | Bottle with cork, glass highlight on the left, liquid fill (FF1-6, Zelda) **[known]**. | Ice flask: corked flask with snowflake-pattern fill. Poison pot: pot/flask with a skull mark. |
| **Ring** | Band seen 3/4 with a gem on top (Dragon Quest, FF accessory icons) **[known]**. | Band + diamond gem. |
| **Charm / amulet** | Pendant on a chain: V-shaped chain over a gem **[known]**. | Diamond gem on a V chain. |
| **Coin** | Disc with a highlight arc and an embossed mark; Kenney has `$` and `c` glyph tiles **[known]**. | Disc with rim light and a slot mark. |
| **Heart / health** | Heart with a highlight in the top-left lobe (Zelda hearts) **[known]**. | Heart; Kenney heart tile is an alternative. |
| **Shield** | Heater or kite shape with a rim and a boss or cross **[known]**. | Heater shield with a cross. |

## 3. Third-party assets

| Source | Licence | Use | Status |
|---|---|---|---|
| **Kenney 1-Bit Pack v1.2**, kenney.nl/assets/1-bit-pack, 16x16 monochrome tiles | **CC0** (page and `License.txt`: free for personal, educational and commercial use, credit optional) **[source]** | Optional bases: tile -> palette via `art/tools/kenney.py`; shown as "kenney" alternatives on the contact sheet. The packed monochrome sheet and its `License.txt` are stored in `art/sources/kenney-1bit/`. | Downloaded 2026-10-14 (657 KB zip) from the link behind the page's download button. Used only where listed in `art/strips_v2/SOURCES.txt`. |
| **0x72 DungeonTileset II v1.7**, 0x72.itch.io/dungeontileset-ii | CC0 assets (page says "Creative Commons Zero v1.0 Universal"; "credit not necessary") **[source]** | Not used. | The download is an itch.io "name your own price" checkout step, which this pass cannot complete without a browser click-through, and the page does not list flasks, coins or status icons (mostly characters, tiles and weapons). Skipped; Kenney covered the same ground. |
| **game-icons.net** (CC BY 3.0, needs "Icons made by {author}. Available on https://game-icons.net") **[source]** | CC BY 3.0 | Not used. | No silhouette was imported, so nothing to credit. If one is added later, record it in `art/CREDITS-ART.md`. |
| **Shovel Knight Treasure Trove** art pack | Creative Commons 4.0 (reported by a search result, not verified on the official page) | Not used. | Mentioned only because it is a legal way to inspect how a limited-palette game draws small relic icons. |

## 4. How v2 was made (reproducible)

1. `art/tools/prompts_v2.py`: prompt per icon built from section 2, skeleton `pixel art, game icon, <convention>, single object, centered, plain background, bold outline, high contrast`, two phrasings per icon.
2. `art/tools/gen_v2.py`: ComfyUI at 127.0.0.1:8188, SDXL base + `pixel-art-xl.safetensors` (weight 1.0, trigger words "pixel art") + `sdxl_vae_fp16_fix`, 1024x1024, dpmpp_2m karras, 24 steps, CFG 6.5, 2 images per prompt = 4 candidates per icon. Seeds derive from the icon id.
3. `art/tools/pp2.py`: subject mask -> fit into 16x16 (box average through 4x) -> silhouette boundary = `#071821` outline -> 3-tone body by luminance rank -> 3x3 mode filter -> exact palette snap. Status glyphs are fitted to 9x9 and placed into the round or square badge frame.
4. `art/tools/redraw_v2.py` and `art/tools/items_v2.py`: hand-drawn pixels (ASCII bodies and line primitives), automatic outline and top-left rim/shade pass.
5. `art/tools/kenney.py`: CC0 tile -> palette.
6. `art/tools/build_v2.py`: assembles `art/icons_v2/`, `art/strips_v2/`, `art/candidates_v2/` and `art/contact_sheet_v2.png`. The v2 final for each icon is chosen in `art/tools/picks_v2.py` (default: the redraw).

AI note: SDXL base and Pixel Art XL are CreativeML OpenRAIL(-M) (commercial use allowed, see `icons-comfyui.md` section 7). Steam asks for AI-content disclosure; every shipped v2 icon's source is listed in `art/strips_v2/SOURCES.txt`.

## Sources read in this pass

- [Kenney 1-Bit Pack](https://kenney.nl/assets/1-bit-pack) (CC0, 16x16 tiles)
- [0x72 DungeonTileset II](https://0x72.itch.io/dungeontileset-ii) (CC0 assets)
- [game-icons.net about page](https://game-icons.net/about.html) (CC BY 3.0, attribution wording)
- [Darkest Dungeon wiki: status effects](https://darkestdungeon.wiki.gg/wiki/Status_effects) and [Bleed](https://darkestdungeon.wiki.gg/wiki/Bleed) (bleed = red drop, stun = yellow crescent and diamonds, buff = blue up arrows, debuff = orange down arrows, via search summaries)
- [Slay the Spire wiki: Debuffs](https://slaythespire.wiki.gg/wiki/Debuffs) (icon names only, no description of the art)
- [Octopath Traveler battle guides](https://vulkk.com/2023/02/24/how-combat-works-in-octopath-traveler-2-beginners-guide/) (shield points, weakness icons, "?" for unknown)
- [Mystery Dungeon Wiki: Shiren 1 DS statuses](https://mysterydungeonwiki.com/wiki/Shiren_1_DS:List_of_States) (sleep Zs, confusion birds)
- [Final Fantasy Wiki: FF VII Remake status colour code](https://finalfantasy.fandom.com/wiki/Reflect_(VII_Remake_status)) (blue beneficial, red negative, yellow mixed)
- Search results that returned no usable icon-art description: Pokemon status badges, Final Fantasy Tactics item icons, Dragon Quest status icons, Zelda: Link's Awakening item icons, Shovel Knight relic icons. Everything about those games above is therefore [known], not verified.
