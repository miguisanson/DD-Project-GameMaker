# Playtest queue

What the owner needs to play, test or decide after the agents worked while the owner was away. Used by `IMPROVE.md`.


## Build 8d176ba-20261017 (round 4, 2026-10-17)

Your round-3 notes (29) fixed, plus the new features you picked. Play from the title through a run or two and mark each item when it comes up.

**Build to play:** `E:\Games\DD-Project Playtest\8d176ba-20261017\DD-Project.exe` (build id bottom-right of the title) | **Branch:** `next` | **Items:** 30

**Before you play**
- Your old save becomes **Profile 1, save file 1** on first launch (the old files are only renamed `*.pre-profiles`, never deleted).
- Not in this build: the sound loudness fix (in progress), the class-balance nudges (D186; the sim says Archer/Knight are easy, Nobody hard), the battle/boss music and the refuse sound (waiting for your picks in `art\audio_candidates\PICK.md`).
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

## Build 7f4d08e-20261016 (round 3, 2026-10-17)

This is the checklist for everything built since build 943ce6d (decisions D140-D165, plus the earlier G5-G9 items you have not played yet). Play ONE normal run from the title to the boss and do each item when it comes up. Items are in play order. For each item tick one box: good, bad or change, and write a few words if you like. If you never reach an item, leave the boxes empty.

**Build to play:** `E:\Games\DD-Project Playtest\7f4d08e-20261016\DD-Project.exe` (the short build id is bottom-right of the title) | **Branch:** `next` | **Items:** 58, all unplayed

**Known in this build:** a few long texts can still be cut short or crowd a panel (a note title, the attack preview plate, the Codex run history at 800x720). The fix (H13b "text fits") is done and lands in the next build. The boss fight keeps the old plain background until you import `spr_battle_bg_boss` (D13).

**Before you play**
- Keep GameMaker closed. If the game says an old run was dropped, that is expected.
- The battle backgrounds for forest (floors 1-3), caves (4-6) and ruins (7-9) are imported. The boss arena background is NOT imported yet (D13 waits for your IDE import), so the boss fight still shows the plain background.
- The refuse sound is a stand-in: it plays the same sound as Back.
- Debug keys (testing only): press P once, then L = one level up, K = all items, J = die now. If you use them, say so in your note.

**Keys (new)**
- Esc or Tab (pad: X, Y or Start) opens ONE menu, on the map and in a battle. Q and E switch tabs. Back: X or Esc (pad: B or Y).
- Walk: W A S D or arrows. Run: hold Shift. Talk, open, confirm: Space, Z or Enter.

**How to mark an item:** put an x in one box. Write what you saw under "Your note". Afterwards say "merge the good ones"; good ones go to `v1.9`, bad ones are reverted and become issues.

### Title and Settings

### R3-01 | Build stamp and title words
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: start the game and look at the title. Read the small build id bottom-right.
- You should see: a short id (7 characters, a star after it only if the build has uncommitted files), clear of the menu. The rows read New Game, Continue, Settings, Quit Game (not "Exit").
- Your note:

### R3-02 | Settings change at once
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: Settings. Change UI, SFX and BGM volume. Look for an Apply row. Go Back and open Settings again.
- You should see: the volume changes as you press the key, there is no Apply row, and the values are still there when you return.
- Your note:

### R3-03 | "Keep this?" for window mode and size
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: Settings. Change Window mode or Scale. A "Keep this?" box counts down from 10. First do nothing and wait. Then change it again and choose Keep. Once, double-click Keep with the mouse.
- You should see: doing nothing (or Back) puts the old window back after 10 seconds; Keep makes it stay; a double click counts as one click and does not press anything underneath.
- Your note:

### R3-04 | Key rebinding, now with the pad
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: Settings, Controls. Pick Run, confirm, and when it says "Press a key" press Esc. Do it again and press a new key. With a pad: start it again and press B (or any pad button).
- You should see: Esc and the pad both cancel and leave the old key. A new key is saved at once.
- Your note:

### R3-05 | Prompts show arrows and follow your device
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: look at the hint lines in any menu (for example the seed screen, the next item).
- You should see: arrow key pictures for moving (no "A/D" or "W/S" text), and key pictures with your real key names for confirm and back. Buttons are never written as plain letters.
- Your note:

### R3-06 | Controller prompts (skip if you have no pad)
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: touch a pad button, then look at a menu hint or a tutorial pop-up. Touch a keyboard key and look again.
- You should see: a pad picture with the d-pad arrows lit, A / B / X / Y, LB / RB, and it switches by itself when you change device. Open text re-draws without losing its place.
- Your note:

### New Game, seed and intro

### R3-07 | Seed choice on New Game
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: title, New Game.
- You should see: "Choose a Seed" with Random Seed (first row) and Enter Seed. Random Seed starts a run straight away.
- Your note:

### R3-08 | Enter a seed
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: New Game, Enter Seed. Up and Down change a digit, Left and Right move, Q deletes. Try to start with 0. Then type 12345 and start. Later: Esc, Status tab.
- You should see: up to 9 digits, "Enter a seed above zero." for 0 (with the refuse sound), a clear hint line. In the Status tab the Seed reads 12345.
- Your note:

### R3-09 | Hold to skip the cutscene
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: in the intro cutscene tap Space a few times, then HOLD Space.
- You should see: taps only move the text on. After about 1 second of holding a "Hold to skip" box appears with a filling bar; at about 2 seconds the cutscene ends. Letting go early cancels it.
- Your note:

### R3-10 | Cutscene text box and wording
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: read the intro as it plays (start another new game if you skipped it).
- You should see: the cutscene words in the same box as normal dialogue, in the game's palette (not plain white on black), short lines, no overflow. Mark lines you dislike in the note.
- Your note:

### The class chest and the class pick

### R3-11 | Wake-up choice
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: on floor 1, after the first lines, you may be asked how you wake up. Pick an answer. After your first death, wake up again.
- You should see: two short answers (like "Sit up." / "Lie still."), a different next line for each, and next time a line that remembers what you chose. Nothing changes HP, items or stats.
- Your note:

### R3-12 | The class chest cannot be skipped
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: do NOT open the first class chest. Walk to the room's exit.
- You should see: two short lines from the hero about the chest (reworded by the writer), then you step back one tile. This repeats until you open it.
- Your note:

### R3-13 | Class screen
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: open the class chest. Look at each class: Knight, Archer, Mage, Nobody.
- You should see: Nobody greyed and locked; a small animated picture of each class's character; a lore-and-playstyle description that fits the panel (five lines); skills shown as "???" until you have found them in some run.
- Your note:

### R3-14 | Yes/No pop-up for the class pick
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: choose a class.
- You should see: a centred box "Become ...?" with Yes and No, the cursor on No. Esc or Back means No. Yes picks the class once.
- Your note:

### R3-15 | Chest and map juice
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: open a chest, pick up gold, and walk around.
- You should see: a small burst from the chest lid, the item's icon rising and fading, the gold number counting up, a tiny squash with each step. With Screen shake Off the squash and bounce stop.
- Your note:

### First floors: light, notes, choices

### R3-16 | Rooms are darker, but lighter than last time
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: on floor 1 look at the whole room, then walk next to the walls.
- You should see: a slightly dark room that you can still read easily (lighter than the last build), with fire and torch light as soft round pools that flicker a little. Floor, chests and enemies stay clear.
- Your note:

### R3-17 | Enemies give off NO light
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: stand near an enemy, in front of it and behind a wall.
- You should see: no light cone, no light spill and no dotted ring around the enemy. The enemy is just a sprite. (It still sees you by the same rules.)
- Your note:

### R3-18 | Notes are picked up by walking on them
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: on floor 1 find the note on the floor (a torn page) and walk onto it. Then walk through the spot again.
- You should see: no text box. A "Note found" message, the page rises and fades, and it is gone from the map. A note never blocks you or an enemy, and it does not come back, even in a later run.
- Your note:

### R3-19 | Codex Notes reader and the note's question
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: Esc, Codex tab, Notes. The page says "Notes found 1/8". Open your note and read it to the end. Pick one of the two answers. Close and open it again.
- You should see: a scrolling reader. At the end of the first reading a question ("Whose hand is this?") with two answers. Afterwards the note shows its lines plus one new line for your answer, and no question.
- Your note:

### R3-20 | Merchant choice
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: talk to the merchant the first time. Pick an answer. Talk again later.
- You should see: a flat, dry merchant with two short answers ("A way out." / "Something to buy."), a different reply for each, and a different greeting next visit. The shop works as before, with "Sold Out" in Title Case.
- Your note:

### Map AI: hearing, searching, hiding

### R3-21 | Enemies hear you run
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: stay out of an enemy's sight, about 4 tiles away, even behind a wall. First walk, then run (hold Shift).
- You should see: walking is silent. Running makes the enemy turn and come to where you were.
- Your note:

### R3-22 | The "?" search
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: get seen, run, break the line of sight, and hide behind a wall or door.
- You should see: the enemy goes to the last spot it saw you, then a few tiles the way you fled, then gives up with one "?" and goes home. Not a stream of question marks.
- Your note:

### R3-23 | Hiding spots (floors 2-7)
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: on floors 2 to 7 stand still on a dark grass patch or foliage by a wall (1-2 spots per room, floor 2 has two). Wait about a third of a second. Let an enemy walk past.
- You should see: you turn see-through; an enemy only notices you from 1 tile away. Walking across the spot does not hide you.
- Your note:

### R3-24 | No camping at exits
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: lead an enemy to a door, leave the room and come back. Also look at where enemies are when you arrive in a new room.
- You should see: no enemy waiting at the door or within about 3 tiles of the arrival tile; the enemy that chased you is back at its home or far from the door. Pressing TOWARD the door you arrived by leaves at once.
- Your note:

### Fights

### R3-25 | Battle backgrounds
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: fight on floors 1-3, 4-6 and 7-9.
- You should see: forest tunnel (floors 1-3), caves (4-6), ruins (7-9), all in the 4 game colours, with the enemy and the menu easy to read in front. Are they too busy?
- Your note:

### R3-26 | Damage preview
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: in a battle put the cursor on Attack, then on a damaging skill.
- You should see: a small plate "Damage n / Perfect m" for Attack, and Damage and Perfect lines in the skill details (per hit, like "7 x2" for two hits). The numbers match what you really deal.
- Your note:

### R3-27 | Battle prompt line and status labels
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: look at the hints in a battle. Get a status on you or the enemy (poison, bleed, a buff). Move the cursor onto its icon.
- You should see: ONE hint line instead of many labels. A short label under each status icon (like "PSN 3"); highlighting an icon shows the full sentence. Terms are in bright green, BREAK and Perfect in gold.
- Your note:

### R3-28 | Timing grade words
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: hit with several timing bars and read the grade.
- You should see: the grades now read Perfect / Good / Weak (not all capitals). Do you prefer capitals?
- Your note:

### R3-29 | Hold run for double speed
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: in a battle hold Shift (pad LT) during messages and the enemy turn, and during a timing bar.
- You should see: messages and animations at double speed with a "x2" mark top-right; the timing bars never speed up.
- Your note:

### R3-30 | The battle menu is read-only in a fight
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: in a battle press Esc (opens at the root command menu) or Tab. Open the Items and Gear tabs. Try to use or change something.
- You should see: the menu opens (not during a timing bar); Items and Gear are read-only and say "In a battle, use Item in the battle menu." Use the ITEM command in the battle menu to drink a potion.
- Your note:

### R3-31 | Brace, Take Aim and Muscle Up last as written
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: use Brace and let the enemy miss or not attack. Use Take Aim and Muscle Up and count turns.
- You should see: Brace lasts until the enemy's next hit, or two enemy turns if nothing hits. Take Aim lasts 9 turns and Muscle Up 6, matching their text.
- Your note:

### R3-32 | Elites from floor 3
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: look for an elite enemy on floors 1-2, then on floor 3 and deeper. Stand in a dark spot.
- You should see: no elites on floors 1-2; from floor 3 at least one per floor. Its outline follows the sprite's shape and stays dark in a dark room (it is not bright over the darkness).
- Your note:

### R3-33 | The Stranger and his loot
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: meet the Stranger and pick an answer. Flee once, come back and beat him another time.
- You should see: a friendly-but-wrong Stranger with two short answers, a different reply for each, and a changed line if you meet him again. Items he took are returned when you beat him later, even if you fled the first time.
- Your note:

### R3-34 | Level-up shows your class growth
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: gain a level.
- You should see: a sparkle round you, a line like "Knight growth: ATK +1, DEF +1", and a free point you can put into a stat or into Max HP (+3) or Max MP (+2). The victory text does not list the automatic gains any more.
- Your note:

### R3-35 | EXP bar
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: look at the HUD and the Status tab after a fight.
- You should see: an EXP bar that looks different from the HP and MP bars and fills as you win. The word is "EXP", not "XP".
- Your note:

### R3-36 | Rumble (skip if you have no pad)
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: with a pad, land a Perfect, break an enemy, take a big hit. Then switch Rumble off in Settings.
- You should see: a short rumble on Perfect, BREAK, big hits and death; none once it is off.
- Your note:

### The one menu and the System tab

### R3-37 | One menu for Esc and Tab
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: on the map press Esc, close it, press Tab. Use Q and E for tabs. Press the menu key while you are walking.
- You should see: the same menu both times with seven tabs: Status, Skills, Items, Gear, Codex, Settings, System. Pressing the key mid-step still opens it as soon as you stand on the tile. No separate pause menu any more.
- Your note:

### R3-38 | System tab: Help, Abandon, Quit
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: open System. Open Help and find "Stats & terms". Open Abandon run and Quit to title but answer No.
- You should see: Help is a page on the tab; Stats & terms explains Power, ATK, DEF and the other words. Abandon and Quit each open a Yes/No box with the cursor on No.
- Your note:

### R3-39 | Status tab and Gear tab words
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: open Status, then Gear.
- You should see: Status shows the seed, EXP and status chips with labels. Gear says "Equipped" (not "Worn") and uses Equip / Unequip. All labels in Title Case.
- Your note:

### R3-40 | Refusals: full bed and full potion
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: at full HP use a bed, and try a healing potion. Try something you cannot buy.
- You should see: the bed and the potion say why not and are not used up; each refusal makes the refuse sound (currently the Back sound).
- Your note:

### R3-41 | Yes/No pop-up everywhere
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: sell a piece of gear, swap a skill for a new one, and pick the echo (next run).
- You should see: the same centred Yes/No box each time, cursor on No, the question names the item or skill.
- Your note:

### R3-42 | Quit during a fight
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: in a fight open the menu, System, Quit to title, Yes. Then Continue. Another time close the game window (the X) in a fight, then start and Continue.
- You should see: Continue puts you back just BEFORE the fight: the enemy is on the map, HP, MP, items and gold as they were. After closing the window, the same.
- Your note:

### Death, summary and the next run

### R3-43 | Death line and picture
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: die (J in debug is fine).
- You should see: the old game-over picture behind a new death line, in the 4 colours, text readable. Does the line fit how you died?
- Your note:

### R3-44 | Run summary with stats and seed
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: read the summary. Then Esc, Codex, Runs.
- You should see: the summary slides in like other panels and lists Perfect %, crits, damage dealt and taken, battles won, run time and the seed. The Codex Runs page shows the same for past runs.
- Your note:

### R3-45 | Continue card and New Game over a saved run
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: quit to title with a run going. Look at the Continue card. Then choose New Game.
- You should see: the card shows class, floor, time played and gold. New Game asks "Start a new game? The saved run will be abandoned." in a Yes/No box with No highlighted.
- Your note:

### R3-46 | Skill memory and the echo
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: in the next run pick a class you used before. Look at its skills on the class screen, then the echo pick.
- You should see: skills you found in earlier runs now show their names (others still "???"). After the class pick the echo offers up to 3 skills of THAT class that you found before, never items. Nothing found for the class: no echo.
- Your note:

### R3-47 | Death and wake lines
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: die a second and third time (J in debug is fine) and read the wake-up lines each time.
- You should see: a different wake line each time that fits how many times you died, dry and short, with the odd bit of swearing allowed (D163). Mark lines you dislike.
- Your note (lines I dislike):

### Later floors

### R3-48 | Daylight on floors 2 and 4, and sun spots
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: walk through floor 2 and floor 4. Also look at floors 5 and 9.
- You should see: floors 2 and 4 are bright, like open sky. Sun spots (soft round patches of daylight that do not flicker) sit in the clearing on floor 2 (two) and floor 4 (one), at the foot of the tree on floor 5, and in the east half of floor 9.
- Your note:

### R3-49 | New wall torches on floors 1, 3, 5, 6, 7 and 9
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: visit these floors and look along the top wall. Floors 2, 4 and 8 get no new torches.
- You should see: new wall torches with a flickering light pool: floor 1 two, floor 3 two, floor 5 two, floor 6 one, floor 7 two, floor 9 one. They are on the north wall, not in front of a door or chest. Too many, too few, or in odd places?
- Your note:

### R3-50 | Dark floors are still playable
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: on the deepest floors you reach, look for chests, exits and enemies far from any light.
- You should see: you can still find your way; darkness never hides a chest, an exit or an enemy completely. Say if any room is too dark.
- Your note:

### R3-51 | More notes on deeper floors
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: after a few deaths look for notes on later floors (more appear as you die more) and read them in the Codex.
- You should see: short, odd notes that fit the story; the Notes page counts up to 8.
- Your note:

### The new text and word changes

### R3-52 | Skim the rewritten story text
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: as you play, read dialogue, cutscene lines, wake and death lines, the Stranger and the merchant, notes and graves. A few hero lines swear (allowed, D163).
- You should see: short, dry, a little scared lines in the hero's voice. Write down any line you dislike (where it was and what it says) in the note.
- Your note (lines I dislike):

### R3-53 | Skim classes, items, tutorials and help
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: read the class descriptions, item and skill text, tutorial pop-ups and the Help page.
- You should see: class lines as lore plus playstyle; item lines clear; tutorials that name buttons with pictures and game terms in bright green; no text running outside its box at a small (3x) or big (5x) window.
- Your note (lines I dislike):

### R3-54 | One word per meaning
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: notice words in menus and fights.
- You should see: "enemy" (not foe or monster), "battle" (not fight), EXP, Equip / Equipped, Quit, Bag, Evasion, Sold Out, and Title Case for menu labels. Anything that still feels inconsistent?
- Your note:

### R3-55 | One style and the same dimming
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: open several screens in a row: the menu, a shop, a pop-up, a card pick, the summary.
- You should see: the same frame, cursor, sounds and motion on all of them, and only two dimming levels behind them (a pop-up lighter, a full screen darker). The skill details in a fight do not cover the enemy.
- Your note:

### R3-56 | Korean (optional)
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: switch the language to Korean and skim the title, a dialogue, a class and a pop-up.
- You should see: Korean in every one of them (including the 55 new dialogue lines), fitting their boxes.
- Your note:

### The boss

### R3-57 | Boss fight background
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: reach the boss.
- You should see: the plain background for now (the D13 picture comes after you import it in the IDE). Everything else in the battle works the same as in normal fights.
- Your note:

### R3-58 | Boss lines and ending text
- Status: unplayed   [ ] good  [ ] bad  [ ] change
- Do: read the boss intro and, if you win, the ending.
- You should see: short rewritten lines that fit the world; the hero's reaction after the boss. Mark any line you dislike.
- Your note:

### Questions for you

1. Battle menu read-only in a fight: is it OK that Items and Gear only show, and you use ITEM in the battle menu? (yes / no / change)
2. The Stranger's loot rule: his items come back if you beat him later, even after you fled. OK? (yes / no / change)
3. The class-chest lines (D127) were reworded by the writer. OK, or change them? (yes / no / which line)
4. Timing grades: keep "Perfect / Good / Weak", or go back to capitals? (keep / capitals)
5. Do you want a real refuse sound instead of the Back sound? (yes, pick one / no, keep)

## Older builds (superseded)

Everything below this heading belongs to older builds (playtest 2, build 63deaae and before). It is kept for reference; its entries are not needed for the round-3 build.

**This is playtest 2:** everything built since playtest 1 (build d312bfb), played in ONE big session of about 60-90 minutes (D71). Playtest 1 is finished: the owner approved the new fights (D72) and its nine entries were replaced by this list (the old text is in git, commit 5ca29fa).

## How this file works

- Each feature or fix that the owner has to judge by playing gets **one entry**, written in the same commit that lands on branch `next`.
- Each entry has the exact steps, the expected result, the build id, and what to say afterwards.
- The **Unplayed** number in the header is the count of entries still marked `unplayed`. There is no cap (D71): the agents build everything that is decided, then you play once.
- When you play, mark each entry `good`, `bad` or `change` (and add a few words). Then say "merge the good ones". Good ones go from `next` to `v1.9` only on your word. Bad ones are reverted on `next` and become a row in `ISSUES.md`.
- The agents never write a verdict for you. A line saying `played` or `good` is written by you (or by the agent only because you said it in chat, with the date).
- The entries are in **play order**: they follow one natural run, from the first launch to the ending. You do not need to stop the game to write notes; mark them afterwards.

**Build to play:** `E:\Games\DD-Project Playtest\63deaae-20261015\DD-Project.exe` (the build id is shown bottom-right of the title screen) | **Branch:** `next` | **Unplayed:** 62

**Before you play:**
- Your old saves were moved to `E:\Games\DD-Project Playtest\old-saves-2026-10-15`, so the game starts fresh: no run, no story seen, no hints seen yet. Your old *settings* were kept (Windowed, scale 5, volumes UI 50 / SFX 50 / BGM 80), so the first start will probably be a window, not full screen. That is expected (Q-001).
- Keep GameMaker closed.
- Not imported into GameMaker yet (so expect the stand-ins): the new icons are small shapes drawn by the game, the merchant looks like the Nobody character (with the gold glow), and the 30 extra monster sounds are missing (the monsters still vary a little in pitch and volume).
- Plan: play one normal run from the start and do each entry when it comes up. Mark "not reached" for anything you never see.

**Keys**
- Walk: W A S D or the arrow keys. Run: hold Shift.
- Talk, open, use a bed: Space (also Z or Enter). Confirm in menus: Space, Z or Enter. Back: X or Esc.
- Tab menu: I or Tab. Pause menu: Esc (it opens when you stand still). Switch menu tabs: Q and E.
- Controller (if you have one): A confirm, B back, X Tab menu, Y pause, shoulder buttons switch tabs, triggers run.
- Time savers (testing only, may be removed before release): press P once to switch debug on, then L = one level up, K = all items, J = die now. If you use K or L, say so in your note, because it changes the balance.

## Entry template (copy for each new entry)

```
### Q-001 | feature or fix name | commit abc1234 | build 63deaae-20261015
- Status: unplayed   (you change it to: good / bad / change)
- Requirement / issue: (REQ id, D-number or I-id)
- Automated proof already run: (checks, R-ids, build id, screenshot names)
- Steps (about 2 minutes):
  1. ...
  2. ...
- Expected: ...
- Look out for: (what could be wrong that a bot cannot see: feel, speed, sound, readability)
- Your note: 
```

## Entries

Automated proof for everything below: the full gate passed on `next` at e1a322d (795 s, about 800 checks, bot fights, screenshots). Entries marked "(new tonight)" were merged or built after that gate (random-loot fairness is on `next` at 89dba56; the alt-tab pause and the odds text were still being built when this list was written). The main session fills in their final commit and proof.

## Stage 1: First launch (about 8 minutes)

### Q-001 | Window mode and build id at first launch | commit 26a9523 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D91, I-054
- Automated proof already run: Test_Suite_Display, smoke window-mode steps (tests force Windowed, so the real default was never seen on screen).
- Steps (about 1 minute):
  1. Start `DD-Project.exe`.
  2. Is it full screen without borders, or a window?
  3. Read the small build id at the bottom-right of the title. Does it match the folder name?
  4. Check the title list: New Game, Continue (greyed out, no run yet), Settings, Exit Game.
- Expected: a brand-new install opens in borderless full screen. Because your old settings were kept you will most likely get a 5x window instead; that is fine. Title picture sharp, music playing, no flash or jump.
- Look out for: the window changing size or flickering while it starts; build id too faint to read.
- Your note:

### Q-002 | Settings: volume, window mode, window size, language | commit 26a9523 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D91, D49, D95, I-062
- Automated proof already run: Test_Suite_UI (204 checks), smoke drives Settings through the real keys, window-size screenshots.
- Steps (about 3 minutes):
  1. Title, Settings. Up/Down moves (W/S or arrows), Left/Right changes a value (A/D).
  2. Change UI, SFX and BGM volume and listen to each.
  3. Window: try Windowed, Borderless and Exclusive. In Windowed change Scale (3x, 4x, 5x).
  4. Go to Apply (bottom row) and confirm. Leave with Back and open Settings again.
- Expected: Apply changes the window at once and says Saved. Back without Apply keeps the old settings. Scale is greyed out unless Windowed. The picture is never stretched or blurry.
- Look out for: text hard to read at some size; flicker when switching modes; is Apply easy to find; do volume changes feel right?
- Your note:

### Q-003 | QTE assist, text speed, screen shake | commit c819526 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D49, D35
- Automated proof already run: Test_Suite_Assist, smoke assist steps (bar zones x1.5, arrow time x1.3).
- Steps (about 2 minutes, then check again during fights):
  1. In Settings set Text speed to Slow, then Fast (watch the next dialogue).
  2. Set Screen shake Off and Apply (notice that Perfect hits no longer shake the screen).
  3. Set QTE assist On, fight a few battles, then try it Off.
- Expected: dialogue types visibly slower or faster. Shake Off means no shake. Assist On gives wider bar zones (about 50%) and more time on arrow skills (about 30%).
- Look out for: is the difference between text speeds clear? Does Assist On feel like help or like cheating? Does it still feel too hard with Assist On?
- Your note:

### Q-004 | Key rebinding | commit c819526 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D49, D95
- Automated proof already run: Test_Suite_Binds, smoke Controls-page flow.
- Steps (about 2 minutes):
  1. Settings, Controls. Pick Run, confirm, press a new key (for example R).
  2. Pick another action and press a key that is already used. Try Esc while it waits for a key.
  3. Reset to defaults, then change one key again and Apply. Test it in the world later.
- Expected: the row shows "Press a key...". A key already in use swaps the two actions and says so. Esc cancels. Reset puts all keys back. Apply saves. The controller is not changeable.
- Look out for: any key you cannot undo; words that confuse; the new key not working in the world or in menus.
- Your note:

### Q-005 | Button prompts follow the keyboard or the controller | commit c819526 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D92. Needs a controller; skip it (mark "not reached") if you have none.
- Automated proof already run: Test_Suite_Prompt (labels per device), shots of the prompts.
- Steps (about 2 minutes):
  1. Connect a controller and press any controller button on the title.
  2. Open a hint (a tutorial pop-up, a card pick, the prompt over a chest). Note the button letters.
  3. Press a keyboard key and look again.
- Expected: prompts show the device you touched last: A / B / X / Y on the controller, key names on the keyboard. Both work at any time.
- Look out for: a wrong or missing button picture; a delay before the prompt changes.
- Your note:

### Q-006 | Menu controls feel (same in every menu) | commit 642e7bd | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D95, D96, D97, I-061, I-062
- Automated proof already run: Test_Suite_UI, shots of every menu.
- Steps (about 2 minutes, on the title and Settings; you will use it again in Stage 9):
  1. Press Up on the first row (jumps to the last), Down on the last (jumps to the first).
  2. Hold Down: slow at first, then faster.
  3. Mouse: hover moves the cursor, left click confirms, right click goes back, wheel scrolls.
  4. Back goes up one level only. Reopen a menu: the cursor is where you left it.
- Expected: the same keys and behaviour everywhere. Panels slide and fade in about a tenth of a second, with soft clicks.
- Look out for: scrolling too fast or too slow; any menu that behaves differently; sounds too loud or harsh.
- Your note:

## Stage 2: Start of a run and moving around (about 8 minutes)

### Q-007 | New Game, intro cutscene and skipping | commit 4d312bf | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D48, D35, I-051, I-055
- Automated proof already run: smoke display steps (0 re-layouts over room changes, cutscene end, dialogue end), shots at 480x432 / 1000x700 / 1920x1080.
- Steps (about 3 minutes):
  1. Title, New Game. The run starts at once (no difficulty list any more, D35). Later, with a run saved: the title cursor starts on Continue, and New Game asks "Sure? Confirm again" before it throws the saved run away.
  2. Watch the intro for about 10 seconds, then HOLD Space (or Z or Enter) for about 1 second to skip it. (The intro plays only once, so you only get one try.)
  3. Read the first dialogue (tap to advance). Walk into the first room.
- Expected: holding about 1 second skips the intro and counts it as seen. The picture never jumps, shrinks, shifts or flashes when the cutscene or the dialogue ends.
- Look out for: is it clear you must hold to skip? Any screen glitch at the end of the cutscene? Is the "confirm again" on New Game clear enough when you have a run saved?
- Your note:

### Q-008 | Walking, turning, running, bumping | commit bcedf32 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D69, D70, I-048, I-063
- Automated proof already run: movement bot (grid snapping), Test_Suite_Nav, shots.
- Steps (about 2 minutes):
  1. Tap a direction once (you turn without stepping). Hold it to walk. Turn at a corner without stopping.
  2. Hold Shift while walking to run.
  3. Walk into a wall or tree. Stop and look: are you exactly on a tile?
- Expected: snappy and always on the grid. Running is faster and the walk animation speeds up (it does not freeze). Bumping gives a soft sound and a tiny nudge.
- Look out for: getting stuck mid-tile or on corners; run speed too fast or slow; any room where the map looks off the grid (tell me which room).
- Your note:

### Q-009 | Interact hints and the marks over enemies | commit cb984f0 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D70, I-056, I-058, I-059
- Automated proof already run: shot pairs (marks on and off) diffed for stray pixels, corner probe.
- Steps (about 2 minutes):
  1. Face a barrel, a chest, a bed or a door. A small arrow or prompt shows.
  2. Walk near an enemy: a faint dotted ring shows around it.
  3. Start a fight and win (or run away). Look at the ring and the screen corners after.
- Expected: the arrow has a dark outline and is readable on every floor colour. The ring is round the enemy and comes back after a fight. Nothing is drawn in the top-left corner of the screen.
- Look out for: the arrow blending into the floor; odd marks in a corner; the ring missing after a battle.
- Your note:

### Q-010 | Doors and room arrival | commit 946a689 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D64, I-049
- Automated proof already run: smoke door steps (every door reachable, one exit per entry).
- Steps (about 1 minute):
  1. Go through a door, walk off it, go back through. Do this 3 or 4 times.
  2. Notice the fade and where you stand on arrival.
- Expected: you arrive on the door tile of the new room, you do not bounce back, and the door works again once you step off and return. The fade is smooth and the picture steady.
- Look out for: bouncing, a door that triggers twice, a pause or jump during the fade.
- Your note:

### Q-011 | Enemies: sight, "!", chase, searching, personalities | commit bcedf32 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D63, D66, D67, I-047, I-050
- Automated proof already run: Test_Suite_Nav, bot parts A-F (path around walls, no overlap, sight blocked by walls, search then go home).
- Steps (about 4 minutes, on floors 1-3):
  1. Approach an enemy from behind a wall (it should not notice you), then step into its view: a "!" pops with a sound.
  2. Run away (hold Shift). It follows around walls, a little slower than you.
  3. Break the line of sight: it checks the last spot, then walks home.
  4. Watch enemies that have not seen you: slimes wander slowly, wolves patrol, plants stay put, ghosts drift.
  5. Let one touch you: the fight starts with its cry.
- Expected: as above. Wolves keep up with you. Enemies never stack on top of each other or get stuck.
- Look out for: is sight range fair (3-5 tiles)? Chase speeds fair? Any enemy stuck or jittering?
- Your note:

## Stage 3: Chests (about 5 minutes)

### Q-012 | The first class or skill chest gives the class choice | commit ebfcaed | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D73, D34, D83, I-057
- Automated proof already run: Test_Suite_Cards (140 checks), smoke steps 133-141, card shots.
- Steps (about 2 minutes):
  1. On floor 1 open the first chest you can reach that is a class chest or a skill chest (Space while facing it).
  2. On the class screen look at Knight, Archer, Mage and Nobody (Nobody shows Locked). Read the details on the right.
  3. Pick a class and confirm "Become ...?".
- Expected: whichever of the two chests you open first gives the class choice; the other one later gives a card pick (Q-013). Nobody is locked. You never see "nothing is there".
- Look out for: confusing words; the details panel missing numbers; the screen feeling slow or abrupt.
- Your note:

### Q-013 | Later skill chests: pick 1 of 3 cards | commit ebfcaed | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D81, D82, D18
- Automated proof already run: Test_Suite_Cards (offers, upgrades, passives, max 3 skills), card shots.
- Steps (about 3 minutes; skill chests are on floors 1, 4, 5, 7 and 9):
  1. Open a skill chest. You get 3 cards: new skill, upgrade ("+") or passive. Left/Right moves, Confirm takes.
  2. Try Skip once (it gives a little gold).
  3. When you already have 3 skills and take a 4th skill, it asks which one to replace.
- Expected: each card has an icon, one plain sentence and exact numbers. Maximum 3 skills at once. The first time, a "Cards" pop-up explains it.
- Look out for: are the choices readable and different from each other? Offers repeating too much? Wording?
- Your note:

### Q-014 | Item chests and barrels: chests are never empty (new tonight) | commit 89dba56 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D118, D117
- Automated proof already run: Test_Suite_FairRng (no empty chest result, tier odds), merged with the logic in 89dba56; the full gate after this merge is still to run (main session fills in).
- Steps (about 2 minutes):
  1. Open every chest you meet (item chests are on floors 3, 4, 6, 7 and 9) and a few barrels.
  2. Note what you get and on which floor.
- Expected: a chest always gives an item, never "Nothing found" and never a zero amount. Barrels may be empty. Plain items come most often, rarer ones less often, and later floors give better things.
- Look out for: any empty chest (tell me the floor); the same junk every time; gear that never fits your class.
- Your note:

## Stage 4: Battle (about 20 minutes, spread over the run)

### Q-015 | Battle screen and command menu | commit 505bd3b | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D99, D89, D96, I-066, I-067
- Automated proof already run: battle HUD shots, bot fight with a levelled Knight, smoke battle steps.
- Steps (about 3 minutes):
  1. Touch an enemy to start a fight.
  2. Look at the screen: turn strip across the top, enemy name with HP bar, stagger meter and status icons, your HP and MP bottom-left, commands bottom-right (Attack, Skill, Item, Guard, Run), a short log.
  3. Open the Skill and Item lists and move the cursor: a details panel shows numbers, MP cost and the arrows.
  4. Use Guard once.
- Expected: everything readable and not overlapping. Confirm picks, Back goes back. The details text matches what really happens. Guard lowers the damage you take; check that its description says so.
- Look out for: text too small; something hidden behind a panel; a menu that feels slow.
- Your note:

### Q-016 | Sliding bar for the basic attack | commit 90b59e4 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D56, D60, D61, D20. Approved in playtest 1 (D72); only check that nothing got worse.
- Automated proof already run: Test_Suite_Qte, bot Perfect and fail variants, shot_qte_bar.png.
- Steps (about 2 minutes):
  1. In 4 or 5 fights use Attack and press early, late, on the bright core, and not at all.
- Expected: the cursor sweeps the bar. A grade word (PERFECT / GOOD / OK / WEAK) with its own sound. You never fully miss. Perfect has a tiny freeze and shake.
- Look out for: sweep speed and zone size still right? Does the pop-up for the bar show once?
- Your note:

### Q-017 | Arrow sequences for skills | commit 5129de8 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D57, D58, D61. Approved in playtest 1 (D72); quick check only.
- Automated proof already run: Test_Suite_Qte arrow grader, bot casts per class, shot_qte_arrows.png.
- Steps (about 2 minutes):
  1. Use each skill you own a few times. Make one wrong press on purpose.
- Expected: arrows with a draining time bar. A wrong press shakes the arrows and costs time. The skill always fires. Grade word and sound.
- Look out for: time limits (3.4 / 4.2 / 5.0 seconds for 3 / 4 / 5 arrows); are the sequences easy to remember?
- Your note:

### Q-018 | Defence bar on big enemy attacks | commit 3eefcc9 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D59, D7, D68, I-066
- Automated proof already run: bot defended Ramming, shot_qte_telegraph.png, shot_qte_defence.png, Test_Suite_EnemyAI.
- Steps (about 3 minutes):
  1. Fight a Snake (Bite), a Spider (Poison Fangs) or the floor-5 mini boss (Ramming).
  2. Watch for a "!" with the attack name one turn before. Then press on the bright zone of the defence bar.
  3. Also notice that normal enemy hits have no bar.
- Expected: a Perfect block takes 25% damage and resists the status; a Weak one takes full damage. A status never lasts longer than normal.
- Look out for: is the warning clear and long enough (0.4 s)? Is blocking satisfying?
- Your note:

### Q-019 | Turn timeline (speed decides who acts) | commit 9dfeac7 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D74, D19
- Automated proof already run: Test_Suite_Turns, bot turn scenarios, timeline shots.
- Steps (about 2 minutes):
  1. In a few fights watch the strip at the top (the next 5 turns).
  2. Fight something fast (a wolf) and something slow (a plant or slime).
  3. Use a stun skill (for example Hilt Bash) and watch the enemy icon move back.
- Expected: faster fighters appear more often and can act twice before a slow one. Stun pushes the target back about one turn. The first time, a "Turn order" pop-up explains it.
- Look out for: can you tell who acts next at a glance? Does the strip flicker or jump?
- Your note:

### Q-020 | Stagger meter, BREAK and Steadfast | commit 9dfeac7 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D75
- Automated proof already run: Test_Suite_Turns (stagger, BREAK, Steadfast), B3 shots.
- Steps (about 3 minutes):
  1. Hit one enemy with Perfect attacks and stun skills and watch its stagger meter fill.
  2. When it is full you see BREAK!: the enemy is pushed back and takes +50% damage until its next turn.
  3. Stun the same enemy again soon after: it shows Steadfast and cannot be stunned for 2 of its turns.
- Expected: as above. Bosses have bigger meters and are pushed only half as far. A "Stagger and BREAK" pop-up shows the first time.
- Look out for: is BREAK obvious and rewarding? Is Steadfast understandable?
- Your note:

### Q-021 | Statuses: poison, burn, bleed (with turn counters) | commit 17a7aa9 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D78, D21, BUG-08
- Automated proof already run: Test_Suite_StatusRules, bot battles A and B, status shots.
- Steps (about 3 minutes):
  1. Get poisoned (Spider, Snake) and/or poison an enemy (Poison Arrow, Poison Mist). Add Fireball for burn and Wound for bleed if you have them.
  2. Watch the icons under the names and the numbers on them. Take a few turns.
- Expected: poison hurts for its stack count each turn, then drops by 1 (maximum 10). Burn is a big hit for 2 turns and cuts DEF by 25%. Bleed hurts only when the bleeder acts, stacks to 3 and lasts 3 turns. Each tick on you gives a log line, a sound and an HP-bar flash. The icon number matches what happens.
- Look out for: can you feel poison working? Icons readable (they are code-drawn shapes until imported)?
- Your note:

### Q-022 | Foresight, Evasion and Solidify | commit e9685dc | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D79, D80, D24, I-002, I-052
- Automated proof already run: Test_Suite_StatusRules, fix-foresight tests (Foresight+ gets its extra turns), shot_fx_* per skill.
- Steps (about 3 minutes; mark "not reached" if you never get these skills):
  1. Cast Foresight (Mage). Look at the eye effect and at the strip.
  2. Cast Evasion (Archer) and let the enemy attack once.
  3. Fight a slime that uses Solidify.
- Expected: Foresight lasts 3 turns, shows the enemy's next action on the strip (hidden big attacks too) and makes every Perfect zone 50% wider. The eye is small and beside the enemy. Enemies never miss by luck; Evasion dodges the next attack fully; Solidify makes the slime take 75% less from the next hit.
- Look out for: is Foresight easy to understand now? Eye size OK? Does the icon look like an eye (the drawn stand-in)?
- Your note:

### Q-023 | Damage numbers, skill speed and effect sizes | commit d0ddcbf | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D55, D92, I-052, I-060, BUG-05, BUG-06, BUG-21
- Automated proof already run: bot measures every skill at most 66 frames, shot_fx_* per skill, Test_Suite_Fx.
- Steps (about 2 minutes, during any fights):
  1. Watch the numbers that pop up when something is hit.
  2. Cast Ice Spear, Hilt Bash and a buff.
- Expected: numbers differ by grade and show "BREAK!" on a break. About 1 second from pressing to your next choice. Effects are at least as big as the target; buffs play on you, not on the enemy.
- Look out for: anything too rushed; numbers hard to read; an effect too big or too small.
- Your note:

### Q-024 | Enemy battle behaviour (rule lists, wind-ups) | commit 3eefcc9 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D68, D7
- Automated proof already run: Test_Suite_EnemyAI, bot_ai_* fights, B4 shots.
- Steps (about 3 minutes):
  1. Fight at least four different kinds of enemy and watch what each one does.
  2. When an enemy announces a big attack, break it (fill its stagger meter that turn) if you can.
- Expected: enemies behave differently (heal when low, weaken you when you are buffed, a big attack every few turns). A BREAK during the wind-up cancels the attack.
- Look out for: moves that feel random or unfair; an enemy that repeats one move; wind-ups you cannot read.
- Your note:

## Stage 5: Fairer randomness (about 6 minutes, new tonight)

### Q-025 | Critical hits with Take Aim (new tonight) | commit 89dba56, 1f5b7fd | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D119, D124. Needs the Archer; mark "not reached" otherwise.
- Automated proof already run: Test_Suite_FairRng (bag sizing, never more than 6 misses in a row at 25%), merged in 89dba56. The status line comes from the same bag size (Test_Suite_FairUi).
- Steps (about 3 minutes):
  1. As the Archer read Take Aim in the skill list or Skills tab.
  2. Cast it (3 MP, lasts 9 turns), then make 8 or more hits.
  3. Count the critical hits. Cast it again and count again.
- Expected: the text says "1 in every 4 hits is a critical." After each cast exactly 1 hit in every 4 is a critical, in a mixed order. No long runs without one, and not two in a row all the time.
- Look out for: is a critical clearly visible and audible? Is the tooltip clear?
- Your note:

### Q-026 | Fleeing: chance shown and rising (new tonight) | commit 89dba56, 1f5b7fd, d716e76 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D121, D124
- Automated proof already run: Test_Suite_FairRng (flee formula values, +25 points per failed try), merged in 89dba56. The RUN percentage is checked in Test_Suite_FairUi and shot_fairui_run_* (e.g. Knight vs Slime: RUN 52%).
- Steps (about 3 minutes):
  1. In a normal fight read the Run entry in the command menu. It shows a percentage.
  2. Try Run until it fails once, then look at the percentage again.
  3. In a boss fight look at Run.
- Expected: the percentage is your speed divided by (your speed plus the enemy's), rounded down (it only shows 100% when escape is certain). Each failed try in the same fight adds 25 points. It starts fresh in the next fight. Bosses show that you can't flee.
- Look out for: does the shown number match what happens? Does a failed try cost too much? Is the number easy to read?
- Your note:

### Q-027 | Enemy item drops never dry for long (new tonight) | commit 89dba56 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D120
- Automated proof already run: Test_Suite_FairRng and Test_Suite_RunSave (the dry-fight counter is saved and restored), merged in 89dba56.
- Steps (about 1 minute of attention, during the whole run):
  1. After every fight note whether an item dropped (gold always drops).
- Expected: each fight without an item adds 10 points to the next drop chance, and a drop resets it. You should never go about 10 fights in a row without an item, and usually far fewer.
- Look out for: long dry spells; a flood of drops that makes items feel cheap.
- Your note:

## Stage 6: Level-up (about 3 minutes)

### Q-028 | Level-up: fixed growth, 1 free point, then a card | commit 20f6333 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D76, D81, D22, D27
- Automated proof already run: Test_Suite_Stats, Test_Suite_Cards, smoke level-up steps.
- Steps (about 3 minutes):
  1. Win fights until you level up. A "Level N: place 1 point" screen shows each stat with Now and After. Pick one.
  2. Then a 1-of-3 card pick follows.
  3. Open the Status tab and check the numbers grew.
- Expected: your class grows by itself (Knight ATK and DEF, Archer SPD and ATK, Mage MAG) plus the point you place. The Nobody gets a second fixed point. About 10-12 card picks over a whole run. An enemy 3 or more levels below you may be beaten automatically ("You overpower...").
- Look out for: is the pace of levels good? Too many screens in a row? Do the stat numbers mean something you can feel?
- Your note:

## Stage 7: Gold, merchant, throwables, gear, elites (about 10 minutes)

### Q-029 | Gold counter and gold drops | commit 2b16016 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D23
- Automated proof already run: Test_Suite_Economy (about 240 checks), economy shots.
- Steps (about 1 minute of attention):
  1. Find the coin and number at the top-left, in the world and in battle.
  2. Win a few fights, including an elite or the mini boss if you meet one.
- Expected: gold goes up after every fight, more for elites and bosses. The counter never overlaps anything.
- Look out for: amounts too small or too big; counter hard to see.
- Your note:

### Q-030 | Merchant and shop (floors 2, 5 and 8) | commit 9b89e54 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D85, D113, D115, D23
- Automated proof already run: Test_Suite_Economy (shop buy and sell), merchant shots, smoke steps 142-146.
- Steps (about 4 minutes):
  1. On floors 2, 5 and 8 find the merchant (in an alcove near the stairs). It has a pulsing gold glow outline.
  2. Talk to it (Space). Buy something, sell something, and try to buy with too little gold.
  3. Leave and come back in the same run. Next run, look at the stock again.
- Expected: potions, throwables, gear and 1-2 cards for sale; details panel with numbers; names in white. Stock stays the same within a run and changes with every new run. The merchant says different lines.
- Look out for: does the glow make you notice it without looking silly? (The sprite is the Nobody stand-in until you import it.) Prices fair? Shop easy to use?
- Your note:

### Q-031 | Throwables | commit 2b16016 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D84
- Automated proof already run: Test_Suite_Economy (throw damage, Nobody x2), bot throw scenarios.
- Steps (about 2 minutes):
  1. Buy or find a throwable (firebomb, poison pot, ice flask, smoke bomb).
  2. In a fight open Item and throw it. Use the sliding bar.
- Expected: throwing costs your turn, uses the bar for its grade, and the item is used up. You carry at most 5 of a kind (8 for the Nobody, who also throws twice as hard). A "Throwables" pop-up shows the first time.
- Look out for: are throwables worth their price? Is the animation clear?
- Your note:

### Q-032 | Accessory slot and gear comparison | commit 2b16016 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D92, D90
- Automated proof already run: Test_Suite_Economy, Tab menu shots (shot_tabmenu_gear*).
- Steps (about 2 minutes):
  1. Find a ring or charm (shop or chest).
  2. Tab menu, Gear tab. Move over each item.
  3. Equip it.
- Expected: three slots (weapon, armor, accessory). Highlighting an item shows before and after numbers. The accessory gives a small bonus.
- Look out for: confusing before / after numbers; names hard to read.
- Your note:

### Q-033 | Elites: outline, one modifier, better rewards (D123 new tonight) | commit 2b16016, 89dba56 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D86, D123
- Automated proof already run: Test_Suite_Economy (elite stats and modifiers); the per-floor count rule is checked in Test_Suite_FairRng (89dba56).
- Steps (about 3 minutes):
  1. On each floor from 2 on look for an enemy with a pulsing light outline.
  2. Fight it: its name plate shows ELITE and one modifier (Armored, Venomous, Swift, Brutal or Regenerating).
  3. Win and look at the reward.
- Expected: about 1 enemy in 7 is an elite, at least one on every floor from floor 2, spread over the floors (not all in one room). Elites give more gold and a guaranteed card pick. An "Elites" pop-up shows the first time.
- Look out for: is the outline easy to spot? Are elites too hard for what they give? Floors with none, or with too many?
- Note: the simulator says this rule gives about 6 elites a run (the old random roll gave about 3); sim win rates drop 3-6 points (Knight 94 -> 88%). If runs feel too hard, the easy fix is to drop "at least one per floor" (back to about 3 a run).
- Your note:

## Stage 8: Beds and hints (about 4 minutes)

### Q-034 | Beds: heal or upgrade a skill | commit c819526 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D47, D46, I-064
- Automated proof already run: Test_Suite_Bed, smoke steps 161-168.
- Steps (about 2 minutes; beds are on floors 1, 3, 6 and 9):
  1. Face a bed and press Space. Choose Rest, or Upgrade (pick a skill).
  2. Use the same bed again.
- Expected: Rest restores all HP and MP; Upgrade improves one skill you own. Each bed works once per run; the second time it says you rested here already. The bed does not save the game any more (the game saves by itself).
- Look out for: is the choice clear? Should a bed also do something else?
- Your note:

### Q-035 | Tutorial pop-ups and the Help page | commit c819526 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D45
- Automated proof already run: Test_Suite_Tutorial, smoke pop-up steps, shots.
- Steps (about 2 minutes, as they appear; 11 in all: turn order, sliding bar, arrow skills, defence, stagger, cards, shop, throwables, bed, elite, statuses):
  1. Read each pop-up the first time it shows and press Confirm.
  2. Later press Esc, Help: open one you already saw and one you have not.
- Expected: each pop-up is short, shows the right key or button for your device, appears once only, and the press that opened it does not close it. Help lists all 11.
- Look out for: a pop-up at a bad moment (in the middle of a bar or arrows); too wordy; a hint you wish existed.
- Your note:

## Stage 9: Tab menu, Codex and pause (about 8 minutes)

### Q-036 | Tab menu: tabs and details panel | commit e1a322d | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D90, D100, D95, D115, I-061
- Automated proof already run: Test_Suite_UI, shot_tabmenu_* for every tab.
- Steps (about 2 minutes):
  1. Press I or Tab (controller X). Switch tabs with Q and E: Status, Skills, Items, Gear, Codex, Settings. Keep pressing past the end.
  2. In each tab move the list and read the right-hand panel.
  3. Back leaves one level at a time.
- Expected: tabs wrap around; each tab remembers its cursor; the right panel shows one plain sentence and the numbers. Names are white.
- Look out for: numbers overlapping on the Status tab; too much text; a tab that feels empty.
- Your note:

### Q-037 | Items and Skills tabs | commit e1a322d | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D90, D100
- Automated proof already run: Test_Suite_UI (rows come from the real data), tab shots.
- Steps (about 2 minutes):
  1. Items tab: use a potion outside battle.
  2. Skills tab: highlight each skill.
- Expected: the potion works and the list updates. Each skill shows its arrow sequence, MP cost and numbers; the numbers match what you saw in battle.
- Look out for: a tooltip number that disagrees with the game (that is a bug, tell me which); hard-to-use lists.
- Your note:

### Q-038 | Codex: bestiary, notes, runs, unlocks | commit e1a322d | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D88, D107
- Automated proof already run: Test_Suite_UI (Codex rows), Codex shots.
- Steps (about 2 minutes; check again after your first death):
  1. Tab menu, Codex tab. Open Bestiary, Notes, Runs and Unlocks.
  2. Go back one level each time.
- Expected: the Bestiary lists enemies you have met, Notes the lore notes you read, Runs your past runs (class, floor, cause of death), Unlocks what you have earned. Back from a page goes to the Codex list.
- Look out for: pages that are empty or confusing; text cut off.
- Your note:

### Q-039 | Pause menu | commit e1a322d | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D96, D92
- Automated proof already run: smoke pause steps, Test_Suite_UI.
- Steps (about 2 minutes):
  1. Stand still in the world and press Esc (controller Y).
  2. Look at the list: Resume, Help, Settings, Abandon run, Quit to title. Open Settings from here and come back.
  3. Press Esc again to resume.
- Expected: the game is frozen while paused. The help line under each choice explains it. Settings opened here work like the title Settings.
- Look out for: Esc pausing when you wanted Back; the menu being slow to open.
- Your note:

### Q-040 | Alt-tab opens the pause menu (new tonight) | commit 1f5b7fd, d716e76 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D122
- Automated proof already run: Test_Suite_FairUi + smoke fairui_* (bar frozen while paused, Abandon/Quit greyed in a fight, resuming while still unfocused does not re-open the pause); shot_fairui_pause_*.
- Steps (about 3 minutes):
  1. In the world Alt-Tab to another window for a few seconds and come back.
  2. In a fight, start a sliding bar or an arrow skill, then Alt-Tab away for 5 seconds and come back.
  3. Press Resume.
- Expected: the pause menu is open when you return. The music is quieter while you are away. The bar or arrows carry on exactly where they stopped (no lost time). In a fight, Abandon run and Quit to title are greyed out with a reason.
- Look out for: the game still moving while away; music not coming back; losing a turn or a bar.
- Your note:

## Stage 10: Death, the summary and the echo (about 6 minutes)

### Q-041 | Death scene and the rotating lore line | commit 39c0f9b | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D103, D102, D104
- Automated proof already run: Test_Suite_Story (line choice per death count and killer), death-scene shots.
- Steps (about 3 minutes):
  1. Lose a fight (or press P, then J for a quick test).
  2. Watch the fade, the falling sound and the line. Hold Confirm to skip it.
  3. Die again later: the line should be different.
- Expected: a fade to black, a falling and cracking sound, one line for 2-4 seconds. Lines get darker as deaths pile up and sometimes name what killed you. They never hint at what is outside.
- Look out for: tone right? Too long or too short? Skipping works?
- Your note:

### Q-042 | Run summary and the echo pick | commit 4d312bf | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D87, D103
- Automated proof already run: Test_Suite_RunLoop, smoke run-loop steps.
- Steps (about 2 minutes):
  1. After the death line read the summary (floor, class, cause, cards).
  2. Pick 1 of 3 items or cards from what you had in the lost run.
- Expected: the summary is clear. The echo is explained in a short line, and what you pick is waiting for you in the next run.
- Look out for: what if you had almost nothing to pick; wording of "echo".
- Your note:

### Q-043 | Waking at the tunnel entrance, a fresh run | commit 4d312bf | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D102, D26, D27, D33
- Automated proof already run: Test_Suite_RunLoop, Test_Suite_Rng (same seed gives the same shuffles).
- Steps (about 2 minutes):
  1. After the echo you wake at the entrance (floor 1) with a short line.
  2. Check your level, gold and items. Look at what chests and enemies are on the floors this time.
- Expected: level 1, no gold, only the echo item. The line fits how many times you have died. The content is shuffled (different enemies, chests, shop stock), not a copy of the last run.
- Look out for: dying and restarting feeling slow; the new run feeling too much like the last one.
- Your note:

### Q-044 | Abandon run | commit 4d312bf | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D92
- Automated proof already run: smoke abandon steps (two-step confirm).
- Steps (about 1 minute):
  1. Esc, Abandon run. The row changes to "Sure? Confirm again". Move the cursor away and see it reset.
  2. Choose it again and confirm.
- Expected: it needs a second confirm. The run ends like a death (summary, echo), with a line that fits abandoning.
- Look out for: easy to trigger by accident?
- Your note:

## Stage 11: Quit and Continue (about 3 minutes)

### Q-045 | Quit to title, Continue, auto-save | commit 4d312bf | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D46, D36, D125
- Automated proof already run: Test_Suite_RunSave, Test_Suite_Profile, smoke continue steps.
- Steps (about 3 minutes):
  1. Mid-run (after a room change and a fight) press Esc, Quit to title.
  2. On the title Continue is now usable. Choose it.
  3. Do it again, but this time close the game window instead of using the menu, then start it and Continue.
- Expected: you are back in the same room with the same HP, gold, items and cards. Enemies you beat stay beaten. You cannot undo a death by quitting.
- Look out for: losing progress; a long pause; a message that confuses.
- Your note:

## Stage 12: Story and lore (about 4 minutes)

### Q-046 | Story is told only once | commit 4d312bf | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D26, D106
- Automated proof already run: smoke story-once steps, Test_Suite_Profile.
- Steps (about 2 minutes, on your second run):
  1. Start a new run after dying. Walk through the first floors.
- Expected: the intro, the camera pans and the one-time dialogue you saw in run 1 do not play again. Ordinary talking to people still works.
- Look out for: a story scene that repeats; one you missed the first time and now cannot see.
- Your note:

### Q-047 | Boss name banner on later runs | commit 39c0f9b | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D106
- Automated proof already run: Test_Suite_Story (banner timing), banner shot.
- Steps (about 1 minute; only possible once you have seen a boss's camera pan in an earlier run):
  1. In a later run walk up to the floor-5 mini boss or the final boss.
- Expected: no camera pan; instead the boss's name shows for about 1 second.
- Look out for: banner too short or too long; hard to read.
- Your note:

### Q-048 | Lore notes | commit 39c0f9b | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D107
- Automated proof already run: Test_Suite_Story (note placement and death-count gates), note shots.
- Steps (about 2 minutes):
  1. Read notes when you see them: always there on floors 1, 3, 6 and 8. More show up after 3 deaths (floors 2 and 4), 6 deaths (floor 7) and 10 deaths (floor 9).
  2. Check them in the Codex Notes page.
- Expected: you read a note by facing it and pressing Space. Read notes are listed in the Codex. The death-count notes are your own earlier marks.
- Look out for: a note you could not find or read; text too long for the box; tone.
- Your note:

## Stage 13: Winning (about 6 minutes, only if you get there)

### Q-049 | Final boss and the ending | commit 39c0f9b | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D104, D31
- Automated proof already run: Test_Suite_Story (ending text), ending smoke steps.
- Steps (about 3 minutes):
  1. Beat the final boss on floor 10.
  2. Read the ending text.
- Expected: you escape the tunnel, then it turns out the outside is not safe either. It plays in full only the first time you win.
- Look out for: does it make sense? Is it paced well? Any typo?
- Your note:

### Q-050 | Closing credits | commit 39c0f9b | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D105, D109, D40
- Automated proof already run: Test_Suite_Story (credits lines), credits shot.
- Steps (about 2 minutes):
  1. Watch the credits roll after the ending.
- Expected: "Game and art by PaleRook", fonts, tools and sounds, then "Thank you for playing." and "by PaleRook". The sound creators still say "(owner to supply)" until you send the names; the three monster-sound authors are already named.
- Look out for: roll speed; text cut off at the edges; can you skip it? Does it return to the title?
- Your note:

### Q-051 | The Nobody class after the first win | commit ebfcaed | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D83, D88
- Automated proof already run: Test_Suite_Cards (Nobody locked until a win, passives), Test_Suite_Economy.
- Steps (about 5 minutes, only after a win):
  1. Start a new run and open the class chest.
  2. Pick the Nobody and play the first floors with its basic attack, passives and throwables.
- Expected: the Nobody is now selectable, has no skills, throws items twice as hard and carries 8 of each.
- Look out for: does the Nobody feel like a fair challenge, not an impossible one?
- Your note:

## Stage 14: How the whole game feels (about 5 minutes of thinking, no extra play)

### Q-052 | Run length and difficulty | commit 1c8dd66 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D111, D112, D14
- Automated proof already run: simulator report "After D111" (targets inside their bands).
- Steps:
  1. Note how long your best run took, how many deaths you had, and on which floors.
- Expected: a winning run takes about 25-30 minutes. Deaths come from mistakes, not from bad luck.
- Look out for: floors that feel like walls; floors that are too easy; times when you had to grind; potions and MP mattering.
- Your note:

### Q-053 | Floor-5 mini boss (Palehorn) | commit 1c8dd66 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D111, D68, D75
- Automated proof already run: bot boss fights, Test_Suite_EnemyAI (two phases).
- Steps (about 3 minutes):
  1. Fight the mini boss on floor 5. Watch for its phase change and its wind-ups.
- Expected: a longer fight with two phases. The big attack is announced and can be blocked or cancelled with a BREAK.
- Look out for: too long, too short, too hard; boring in the first phase?
- Your note:

### Q-054 | Final boss (Pale Choirbeast) | commit 1c8dd66 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D111, D68
- Automated proof already run: bot boss fights, Test_Suite_EnemyAI (phases).
- Steps (about 3 minutes, only if you get there):
  1. Fight the final boss on floor 10.
- Expected: the hardest fight of the run, with phases and readable wind-ups. It feels earned but beatable with good play.
- Look out for: a wall; a fight you win without trying; a phase that is unreadable.
- Your note:

### Q-055 | Do the classes feel different? | commit 1c8dd66 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D22, D76, D111
- Automated proof already run: simulator report (win rate per class).
- Steps:
  1. Try at least two classes over your runs (Knight, Archer, Mage).
- Expected: each class plays differently (Knight tough, Archer fast with crits, Mage with strong spells and MP use). None feels clearly worse.
- Look out for: a class you would never pick again; a skill that is useless.
- Your note:

## Stage 15: Monster sounds (about 3 minutes, during any fights)

### Q-056 | Monster sound variety | commit 0762b1a | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D116
- Automated proof already run: Test_Suite_Audio (pitch within 6%, volume within 10%, no repeat of the same take twice in a row).
- Steps:
  1. Listen to the same kind of enemy over several fights: its cry when the fight starts and its attack sounds.
  2. Listen especially to the killer plant when a fight starts.
- Expected: every cry sounds slightly different each time (pitch and volume). If the 30 new takes are imported, the same take does not play twice in a row. The killer plant's cry is very quiet in the original sound.
- Look out for: any monster that sounds the same every time; any sound too loud, harsh or too quiet; which of the new sounds you like or dislike (this is by ear, nobody checked it).
- Your note:

## Stage 16: Korean (about 3 minutes)

### Q-057 | Korean language quick look | commit 578c1c3 | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D9, D98, D93
- Automated proof already run: missing-Korean check in the gate, Korean shots of every screen.
- Steps (about 3 minutes, at the end):
  1. Settings, Language: Korean, Apply.
  2. Look at the title, a fight, the Tab menu, a card pick and a shop. Then switch back to English.
- Expected: the Korean pixel font is crisp, nothing is cut off or overflowing, and no English leftovers. The text is a first draft written by the agents, for you to review.
- Look out for: words that sound unnatural; text too long for its box; mixed English and Korean.
- Your note:

### Q-058 | Odds and ends from the regression list | commit next | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: R-011, R-017, R-028, R-032 (no automated check covers these parts)
- Automated proof already run: REGRESSION.md run on 63deaae-20261015 (34 PASS, 0 FAIL); these are the parts only a person can judge.
- Steps (as they come up, no extra play):
  1. Look at the status icons in a fight (poison, burn, bleed, buffs): any that look like a placeholder?
  2. Is the Foresight icon clearly an eye?
  3. On floor 5 and in the room after floor 9, when a dialogue ends, does the picture stay steady?
  4. After Quit to title and Continue: is any old cutscene picture left on screen?
- Expected: real icons, an eye, no jump at dialogue end, no leftover picture.
- Look out for: anything odd for a frame or two.
- Your note:

### Q-059 | Fixed tonight: a failed Run now counts as a turn | commit 946741a | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: R-022 (found by a new automated check after the first build)
- Automated proof already run: smoke regr_r022_* (failed Run and a boss "can't run" both tick poison: HP -3, stacks 3 -> 2, logged).
- Steps (only if it comes up): while poisoned, try RUN and fail.
- Expected: the poison still hurts that turn, like after any other action.
- Look out for: nothing else should change about running away.
- Your note:

### Q-060 | Timing should feel exactly as before (timers now run on real time) | commit f2a/f2b merges on next | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: D108 (optimisation: frame-counted timers -> milliseconds)
- Automated proof already run: Test_Suite_Transition, Test_Suite_BattleClock, Test_Suite_UiClock (same durations at 60 fps, same in ms at 30 fps, hitches capped); smoke, bot and screenshots.
- Steps (no extra play; notice as you go): boot logo, room fades, the encounter zoom, the intro holds, hits and screen shakes in battle, message pauses after an action, dialogue text speed, the boss name banner, "hold to skip" (about 1 s), the credits scroll.
- Expected: nothing feels faster, slower or jumpier than before. After a pop-up or a screen opens, the key you pressed does not also act on what is behind it.
- Look out for: any fade or shake that looks cut short; a key press that "leaks" through a pop-up.
- Your note:

### Q-061 | Fixed tonight: stolen items come back, loot is listed, a weak Smoke Bomb still dodges | commit dbc678a | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: I-072 (bug hunt), D80, D84, D5
- Automated proof already run: 12 new checks (red before the fix): Stranger's stolen item returned on his death; victory text lists drops ("Loot: ..."); Smoke Bomb at every grade, and the Archer's Evasion, still dodge the next attack; throwables trimmed to 5 when the Nobody picks a class.
- Steps (as they come up): win a fight that drops an item and read the victory text; if the Stranger steals something, beat him; throw a Smoke Bomb badly (miss the bar) and let the enemy attack.
- Expected: "Loot: ..." shows after a win with a drop; the stolen item comes back; the attack after any Smoke Bomb is dodged. Note: the Archer's Evasion now lasts the full 6 turns its card says (it was 5 in practice).
- Look out for: anything missing from the victory text.
- Your note:

### Q-062 | Fixed: enemies wait while menus are open; they remember their spot; exits after a fight | commit 63deaae | build 63deaae-20261015
- Status: unplayed
- Requirement / issue: I-073..I-076 (bug hunt 2), D122, D33, D64
- Automated proof already run: smoke steps 250-268 (red before the fix).
- Steps (as they come up): with an enemy chasing you, open the Tab menu or Alt-Tab for a few seconds; leave a room and come back; win a fight that started right where you entered a room, then press a direction.
- Expected: enemies stand still while any menu or pop-up is open; after coming back they stay where they were and do not walk across the room; you are not bounced back through the door you came in.
- Look out for: an enemy that "slides" after closing a menu.
- Your note:

## Questions for the owner

Design questions the agents could not answer from `DECISIONS.md` or the research. They stay parked until you answer. Do not answer in your head; say them in chat so they get written down.

(Answered 2026-10-16 -> D126-D138: echo after class pick (D130), keep everything open (D131), save-on-close via an IDE event (D132).)

1. **Echo gift and classes (D87).** Every run starts as the Nobody and you pick a class later, but the echo (1 item or skill from your lost run) is chosen before that. A skill your new class cannot use is silently lost. Options: (a) only offer items + skills of the class you had, and warn if you pick a different class; (b) let you choose the echo after the class pick; (c) echo offers items only. Recommendation: (b). (I-069)
2. **Milestone unlocks (D88) are not built.** D88 says extra cards / passives / throwables join the pool at milestones (e.g. reaching floor 5, beating bosses). Today everything is in the pool from the first run; only the Nobody class and the death-count notes are locked. Build it (and which milestones unlock what), or keep everything open? Recommendation: keep everything open (simpler, and runs are short), and change D88 accordingly. (I-070)
3. **Closing the window (Alt-F4 / X) does not save (D46).** Quit to title saves; autosave runs every ~10 s and on room changes, so at most ~10 s is lost. A real save-on-close needs a "Game End" event added to obj_game_controller in GameMaker (an IDE task, ~1 minute). Want it? (I-071)

## IDE tasks for the owner

Work that needs a new or changed resource (object, sprite, room, script, font). Agents cannot do these (AGENTS.md Rule 4). Each line: what, why, which requirement.

(none yet)

## Balance proposals (need your yes)

Numbers the agents think should change, with simulator before and after. Nothing here is applied until you approve it by id (D13).

| Proposal | What changes | Before | After | Why (simulator metric out of band) | Your answer |
|---|---|---|---|---|---|
| (none yet) | | | | | |
