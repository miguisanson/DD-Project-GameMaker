# Playtest notes

## Friend's playtest (before 2026-10-13, verbatim)
- scale problem. screen bug
- foresight skills idk what it does (bone shud be foresight +)
- skill books appear in books twice
- ice spear animation is slow
- hilt bash animation slow
- mini boss moves around so he isnt blocking tje way
- i dont take dmg while being poisoned
- incease the hit rate of skills specifically a tiny bit i missed 4 to 5 consecutive horizontal slashes l

## Owner (2026-10-13)
- Screen bug when a cutscene ends (also places with dialogue).
- Resolution/scaling problems in general.
- QTE never felt right.
- Skills unbalanced against each other.
- Buff/debuff icons reuse other skill icons as placeholders — wants real icons (ComfyUI).
- Inventory and the rest of the UI look bad.

## Owner playtest round 3 (build 7f4d08e-20261016, notes 2026-10-17, 8 screenshots in chat)
1. the walking animation is glitching with the lights and the dark. basically the player sprite keeps flashing light and dark when moving
2. and then it stays bright when running. check how animations are affected by light and fix it
3. what happened to loading games? what if i want multiple runs add another line which is load game, so its seperate from "continue"
4. pressing new game should do the whole cutscene again but its only once for that run.. (or how is save filing work? why do i still ahve some data from my last playtest when i press new game)
5. I like the background but maybe have like a circular shadow on the bottom of every enemy.. its fine that they are like floating like that but just make it look visually less awkward
6. also when hovering over the Attack button i cant even read Damage.. or the Perfect.. it just trails off with ..
7. is guard as an action balanced and viable?
8. the flashing of the buff (example screenshot its solid 1 from the slime) should be a bit different the way it flashes is hard to see.. maybe have an outline of it
9. can you keep the ALL caps on PERFECT, GOOD, and so on.. thats the only exception with the consistencyt
10. horizontal slash slightly cant fit in the card skill
11. also "skip: +5 Gold" is actually pretty bad and unbalanced. its not worth doing. maybe just remove it. its better to be able to just choose the 3 cards
12. can you allow mouse control. sadly i cant see the cursor ingame. maybe make one (in the same artstyle), and allow it visually for me
13. with a mouse, should we do a point a click as another movement option or would that complciate things?
14. there was a small bug, when the player leveled up. his hp/mp and stats were visible just right after the monster was slain. i think visually it would be awkward to see all of your max health go up before even going into the level up screen
15. can you also make it distinct what knight growth means? like have it like in elden ring another color for the stats that is about move up.. then dont have every stat have the > arrow key right away. allow it to have it whenver its hovered over AND in this example knight is atk and def so those stats should have the 12 > 13 or something (ask me questions or grill me if you need more clarification)
16. also the Max HP and Max MP... i realize to keep things consistent can we make it like a stat with of course the correct math logic (look at how soulslike games do it, specifically elden ring vigor and mind or something)
17. after killing the wolf on the second room it still did the dialogue (which is counted as an already seen cutscene i believe, so make sure this is updated if the player already saw this within this save file)
18. the merchant is also not affected by the light effects, fix that
19. also not all items (like ex. when defeating an enemy, they dont have the diff color highlight when seeing an importance like the green lighter accent or the gold color text.. make sure things are consistent do a grill me first before doing something wrong here. or in other words, why some items gold and the other items lighter green. when being picked up or when killing a monster and getting the drop
20. make sure when buying past the carry limit not to actually allow the player to spend the money (like he spends and gets nothing and loses the gold) just double check this if its okay. then dont mind this i actually havent tested it it was just more of a check
21. in the gear screen, can you make the text Equipped and Bag distinct from the no armor or no Accessory, or the items. they kinda blend in together cause they are the same color and format.. think of something and update this
22. enemies can detect me through some objects.. also what happened to being able to hide through bushes.. maybe start introducing places to hide at room 2 onwards
23. the snake sprite is kinda on the wrong position in the battle screen and it kinda gets covered by its nameplate and buffs.. can you adjust the sprite for this one
24. which stat affects the stagger? why can i stagger a lot or is it already balanced?
25. the reset to defaults in the settings screen for controls. its hard to tell if it was applied. make a confirmation pop up as well and make sure its obvious it changed things
26. is the death screen text, changes also every time i die. so it shouldnt say the same thing over and over
27. enemies beat.. perfect ra.. some words here dont fit so can you make sure i can read all of them if ever, so fix this
28. spellweaver class card doesnt fully fit also and texts spill out from the frame. make sure all skill cards dont have this problem
29. enemies have a huge detection range... maybe shorten their vision. and they seem to still find me at my last location.. so its actually impossible right now to get away from an enemy as simple as a slime right now without going to the next room.. how should we change this (grill me)
"lets focus fixing these first"

## Owner playtest round 4 (build 8d176ba-20261017, 2026-10-17)
1. (screenshot: typing a profile name, the DEBUG OVERLAY opened) "shift + P still does this, please delete this debug overlay"
2. (screenshot: battle Skill list shows only "Double Shot" under a big details panel) "choosing between skills i cant tell if there are multiple skills i have or i can cycle through them can you make it a bit more obvious during the skill screen in battle"
3. (screenshot: Dire Wolf chip label "THIRST 3" in green) "I also liked the buffs text before just make it plain white. not green"
4. (screenshot: level-up screen, growth rows fully gold) "just color gold the right most number or the "new number" not the whole row" (same shot: mouse over DEF shows DEF's "+1" and DEF details while the highlight bar stays on SPD)
5. "also make it so that when you enter bushes its super forgiving and monsater stop chasing you and and immeditely does a ? and start patroling after a few seconds (make him stand a bit then move) so that hiding actually matters too"
6. (screenshot: the Pale Choirbeast fight) "this is the last can you move the choir beast a bit down actually. could you move ALL monsters sprites lower they feel like they are floating somewhat maybe line their feet all the way to the top of the 3 windows on the bottom the line on top"
7. "last can you make a save in the system menu. i just realized my playtest didnt even auto save or save my game.. or would that not happen if i finish the game in one run through and through. anyway this is MY last comment. do all the fixes and lets ship already. i just finished my LAST playtest"
