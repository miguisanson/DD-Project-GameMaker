## Build BUILDID (round 4, 2026-10-17)

Your round-3 notes (29) fixed, plus the new features you picked. Play from the title through a run or two and mark each item when it comes up.

**Build to play:** `E:\Games\DD-Project Playtest\BUILDID\DD-Project.exe` (build id bottom-right of the title) | **Branch:** `next` | **Items:** 30

**Before you play**
- Your old save becomes **Profile 1, save file 1** on first launch (the old files are only renamed `*.pre-profiles`, never deleted).
- Not in this build: the class-balance nudges (D186; the sim says Archer/Knight are easy, Nobody hard), the battle/boss music and the refuse sound (waiting for your picks in `art\audio_candidates\PICK.md`).
- Mouse: move it and a pixel cursor appears; keys hide it.
- Debug keys (testing only): P, then L = level up, K = all items, J = die now. Say so in your note if used.

**How to mark:** put an x in one box, write what you saw under the item. Then say "merge the good ones".

### Title, profiles, save files
#### R4-01 | Your old save carried over
- [ ] good [ ] bad [ ] change — Start the game: Continue should resume your last run, the bottom-left shows "Profile 1".
#### R4-02 | New Game, Load Game, 3 save files
- [ ] good [ ] bad [ ] change — New Game uses an empty save file; with all 3 used it asks which to overwrite. Load Game lists the 3 files (class, level, floor, time); Q deletes one after a Yes/No.
#### R4-03 | Profiles and name entry
- [ ] good [ ] bad [ ] change — Profile button (Q, bottom-left): make a new profile, type a name (keyboard or the letter grid). A new profile starts fresh: the intro plays again; in your old profile it does not.
#### R4-04 | Codex from the title
- [ ] good [ ] bad [ ] change — Codex button (E, bottom-left): Bestiary, Notes, Run History, Unlocks of the active profile.

### Map
#### R4-05 | No light flicker when walking or running (notes 1-2)
- [ ] good [ ] bad [ ] change — Walk and run on floors 1-2: the player keeps the same brightness.
#### R4-06 | Merchant in the dark (note 18)
- [ ] good [ ] bad [ ] change — The merchant darkens like everything else and stands outside the bright spots.
#### R4-07 | Enemy sight cone (notes 22, 29)
- [ ] good [ ] bad [ ] change — A very faint cone in front of each enemy shows what it sees (3 tiles, wolf/whisp 4, plus 1 tile all round). Trees, rocks, barrels, chests and grass block its view.
#### R4-08 | Escaping (note 29)
- [ ] good [ ] bad [ ] change — Get spotted, then run out of sight: the enemy goes to where it last saw you, looks ~3 s, shows "?", goes home, and ignores you for 2 s. Running is heard only within 2 tiles.
#### R4-09 | Hiding in bushes (note 22)
- [ ] good [ ] bad [ ] change — From floor 2, bush patches: walk in, stand still and you turn see-through and hidden (seen only from 1 tile).
#### R4-10 | Trapped chest (IDEA-03)
- [ ] good [ ] bad [ ] change — One chest per floor from floor 2 is trapped: "It's trapped!" then one timing bar. PERFECT = a bonus item; WEAK = lose 15% HP (never kills). You always get the chest's item.
#### R4-11 | Wolf lines play once (note 17)
- [ ] good [ ] bad [ ] change — After the floor-2 wolf, its lines never repeat in this profile.

### Battle
#### R4-12 | Enemy shadows and positions (notes 5, 23)
- [ ] good [ ] bad [ ] change — Every enemy stands on one ground line with a soft shadow; the Venomous Snake is no longer covered by its name plate or icons.
#### R4-13 | Last-turn status blink (note 8)
- [ ] good [ ] bad [ ] change — A status on its last turn blinks an outline around its icon (no solid box).
#### R4-14 | Attack preview readable (note 6)
- [ ] good [ ] bad [ ] change — On Attack, the box reads "Damage N" / "Perfect N" in full.
#### R4-15 | PERFECT / GOOD / OK / WEAK in capitals (note 9)
- [ ] good [ ] bad [ ] change — The timing words are all caps.
#### R4-16 | Guard is worth it (note 7)
- [ ] good [ ] bad [ ] change — Guard halves every hit until your next turn and gives back 25% of max MP (at least 2), shown as "+N MP".
#### R4-17 | Weak points (IDEA-07)
- [ ] good [ ] bad [ ] change — Each enemy takes one status better ("<Enemy> is weak to Burning!": +1 turn/stack) and resists another (half the chance). The Codex shows Weak/Resists once seen.
#### R4-18 | Boss finisher (IDEA-21)
- [ ] good [ ] bad [ ] change — The last hit on Palehorn / the Choirbeast: a longer freeze, a zoom punch and a held beat before the slain text (no shake if Screen shake is off).
#### R4-19 | Skill names fit in battle (notes 10, 28)
- [ ] good [ ] bad [ ] change — In the Skill list, long names (Horizontal Slash+, Poison Arrow+) wrap to two lines; the info box never covers the enemy.

### Level up (notes 14-16)
#### R4-20 | No stat jump before the screen
- [ ] good [ ] bad [ ] change — Killing the last enemy with a level-up: HP/MP/stats on the HUD stay the same until you confirm the level-up screen.
#### R4-21 | VIG and MND
- [ ] good [ ] bad [ ] change — Max HP comes from VIG and Max MP from MND (gains shrink at high values). Mage = glass cannon (most MP, least HP from level 3). HP per level stays within ~9% of before.
#### R4-22 | Gold growth rows, +1 on hover
- [ ] good [ ] bad [ ] change — Your class's growth stats are gold and show "12 > 13"; the row you hover shows its +1.

### Cards, items, menus
#### R4-23 | No Skip on the card pick (note 11)
- [ ] good [ ] bad [ ] change — Only the 3 cards; take one.
#### R4-24 | Card and skill names fit (notes 10, 28 + your note)
- [ ] good [ ] bad [ ] change — Every card, the Skills tab and the Controls page show names in full at every window size.
#### R4-25 | Rarity colours (note 19)
- [ ] good [ ] bad [ ] change — Item names: Common white, Rare gold, Epic gold that pulses — in chests, drops, steals, the bag and the shop; a small gem on Rare/Epic icons.
#### R4-26 | Gear headers (note 21)
- [ ] good [ ] bad [ ] change — "Equipped" / "Bag" are bright text with a line after them, clearly different from "No Armor" and from the selected row.
#### R4-27 | Reset to defaults asks (note 25)
- [ ] good [ ] bad [ ] change — Settings > Controls > Reset asks Yes/No; Yes shows "Keys are back to the defaults." and the changed rows flash.
#### R4-28 | Shop rows you can't carry (note 20)
- [ ] good [ ] bad [ ] change — Throwables at the cap or gear you own show dim with the reason; buying them never takes gold.
#### R4-29 | Mouse everywhere (note 12)
- [ ] good [ ] bad [ ] change — Menus, battle lists, cards, level-up, shop, title, settings sliders, dialogue (click advances), timing bars (click = press), right-click = Back. No click-to-move (D182).

### Death
#### R4-30 | Death screen tip and varied titles (note 26, IDEA-25, note 27)
- [ ] good [ ] bad [ ] change — The death scene adds a tip from what killed you; the summary title changes from death to death; every summary label is readable.

**Questions for you after playing**
1. Class balance: which class felt too easy / too hard? (The nudges come in the next build.)
2. Is the sight cone too faint, about right, or too strong?
3. VIG/MND numbers: does the Mage feel like a glass cannon?
