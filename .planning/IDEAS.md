# Ideas for DD-Project

This is the ideas list from D161: the agent writes ideas here, the owner decides. Nothing here is built until the owner says yes (D28 still holds: fixes and polish only until then).
Answer by replying with the ids you want, e.g. "IDEA-07, IDEA-01, IDEA-22". Say "all Yes" to take every Yes pick, or "none".
Sizes: S = under a day of agent work, M = about a day or two, L = more. Risk notes: Save = changes a save format, Balance = needs the simulator and your approval (D13), Art/Sound = needs new files you import in the IDE, IDE = needs a resource you create in the IDE. "Art: none" means code-drawn or existing assets only.

Written 2026-10-16 on branch `next`. Grounded in the current code: 10 enemies, 14 player skills in 3 classes, statuses (poison, bleed, burn, stun, guard, evasion, crit up and more), 20 passives, 7 accessories, 4 throwables, notes, beds, the merchant, the Stranger, elites, echo.

## Run variety

| ID | Idea | Why it helps replay | Size | Touches | Risk | Pick? |
|---|---|---|---|---|---|---|
| IDEA-01 | At the start of a run, pick 1 of 3 starting trinkets (the existing rings and charms, chosen by the run seed). | Every run starts with a small different build hook. | S | Run_StartNew, the shared card-pick screen, scr_db_item accessories | Save: no (it is an inventory item). Balance: low. Art: none (accessory icons exist). | Yes: cheap, no art, big replay |
| IDEA-02 | Grudge: the enemy type that killed you last time shows up as the elite on its floor in your next run (it replaces one elite, adds none). | Death feels personal and each run begins with a known threat. | M | Elite_Apply, Shuffle_EliteCount, Run_MakeHistoryEntry (store the killer id), Codex history | Save: small, adds one field to run history in the profile. Balance: low. Art: none. Touches D123/D145 only in which enemy is elite. | Yes: ties death to the lore |
| IDEA-03 | Trapped chests: one chest per floor (chosen by seed) is trapped. Opening it runs one sliding-bar press. Perfect gives a bonus item, Weak costs a little HP or 1 poison. The chest still always gives its item (D118). | A risk-or-reward moment on the map, not only in fights. | M | obj_chest, scr_loot (Shuffle_ChestLoot), the sliding-bar widget in scr_combat | Save: no (resolved at once). Balance: yes, trap damage must never kill. Art: none (code-drawn flash). | Maybe: fun, but new map state |
| IDEA-04 | One sealed slot in each merchant's stock: a mystery item or card at a fixed low price, shown only when bought. | Shop visits get a small gamble. | S | Shop_StockGenerate, shop screen row for "???" | Save: no (stock comes from the seed). Balance: low. Art: none (reuse the "???" style from D148). | Maybe: small but cheap |
| IDEA-05 | Third bed choice: Brew. Turn 2 potions of one kind into 1 of the next level (HP Lv1 to Lv2 and so on). Still one use per bed. Amends D47. | Beds become a real decision and spare potions are never dead weight. | S | Bed_Choose, Bed_MenuItems in scr_levelup, item ids 10-18 | Save: no (bed flags exist). Balance: low. Art: none. | Maybe: nice choice, touches D47 |
| IDEA-06 | Four more accessories with a trade-off (for example +2 ATK, -1 DEF), sold by the merchant and found in tier-3 chests. | Gear choices that make you rethink your build. | S | scr_db_item (ids 47+), ItemDB_GetPassiveTemplate, Loot_Init tables, Shop_GearPick | Save: no. Balance: yes. Art: none (accessory icon kinds exist). New text in the xlsx and Korean. | Maybe: adds items, small effort |

## Combat depth

| ID | Idea | Why it helps replay | Size | Touches | Risk | Pick? |
|---|---|---|---|---|---|---|
| IDEA-07 | Weak points: each enemy takes one status a bit better (+1 turn or +1 stack, never past the D78 caps) and resists another. Examples: Killer Plant burns longer, Snake shrugs off poison, Ghost Sword does not bleed. A hit message and the Codex tell you. | The right skill or throwable changes per floor, so builds matter. | M | scr_db_enemy (two fields), Skill_StatusApplyArgs, Codex entry text | Save: optional (a "weakness seen" flag in the profile). Balance: yes, run the simulator. Art: none. | Yes: no art, makes picks matter |
| IDEA-08 | Status reactions: Fireball on a poisoned foe pops all poison at once (stacks x 2 damage, poison ends). Ice Spear on a burning foe ends the burn and adds stagger. Bounded like D21. | Skills from different classes combine, so every card changes the plan. | M | scr_status, Skill_Use, Combat_Log text, Battle_StaggerHit | Save: no. Balance: high, needs the simulator. Art: none (existing hit sparks). | Maybe: strong but balance-heavy |
| IDEA-09 | Counter-strike: a Perfect block on a big enemy attack (D59) grants a free OK-grade basic hit with no extra bar. | Defence becomes something to chase, not only to survive. | M | Battle_DefenceStart / defence flow, Combat_ApplyDamage in scr_combat | Save: no. Balance: yes, bosses take more damage. Art: none. Keeps the D55 pace (no extra waiting). | Maybe: fun, but boss re-balance |
| IDEA-10 | Two more elite modifiers: Vampiric (heals when it hits you) and Thorned (hitting it costs you 1 HP). | Elites stay surprising after a few runs. | S | Elite_Mods, Elite_Apply, Elite_Sentence, Loc strings | Save: no (the modifier is a string). Balance: low-medium. Art: none (the pulsing outline is shared). Same seed gives different elites than older builds. | Yes: very cheap variety |
| IDEA-11 | Two Nobody-only passives for throwables: Bomb Belt (carry 4 more of each) and Steady Throw (wider Perfect zone on throws). D83 says the Nobody needs more item variety. | The challenge class gets more build choices. | S | CardDB_Init passive rows, Battle_ThrowBegin, item max_stack | Save: no. Balance: low. Art: none (passive icons are code-drawn per D43/D114 unless you want new ones). | Yes: fills a gap in D83 |
| IDEA-12 | Branching upgrades: each skill gets a second Plus so you choose between two (for example Ice Spear+ more damage, or Ice Spear+ shorter arrows). Amends D82 and answers PROJECT tension 8. | One run no longer shows the whole pool, so runs differ more. | M | CardDB_Init (14 more rows), Bed_Upgrade, card UI text, Card_Take | Save: yes, the run save needs a version bump (new card ids), same friendly drop as D125. Balance: yes. Art: none. New text plus Korean. | Maybe: strong, but save bump |
| IDEA-13 | Guard with a bar: the Guard command (D99) becomes one sliding-bar press. Perfect gives the stronger brace (next hit -65% instead of -50%). Amends D99. | Even the "boring" command has a skill edge. | M | Battle guard handler, STATUS_BRACE values, the sliding-bar widget | Save: no. Balance: low. Art: none. Adds time to a turn against D55. | No: slows the fight pace |

## World and story

| ID | Idea | Why it helps replay | Size | Touches | Risk | Pick? |
|---|---|---|---|---|---|---|
| IDEA-14 | The merchant and the Stranger remember: a few extra greeting lines for each, picked by death count (the same 3/6/10 tiers as the notes) and by what you carry. Builds on D154. | Familiar faces change over time, which rewards repeat runs. | S | scr_dialogue, merchant spots in scr_loot, Stranger encounter text | Save: no (death count is in the profile). Balance: none. Art: none. New text, English and Korean draft (D93). | Yes: story from text only |
| IDEA-15 | Last-fall note: in the room where your last run ended, a note on the map reads "You fell here as the Mage. [short cause line]." It is made from run history and appears again after each new death. Gentle amend of D147 (this note is regenerated each run). | You see your own history in the world, and the tunnel feels like it keeps you. | M | Note_Defs / notes_live in scr_dialogue, Run_MakeHistoryEntry data, one free tile per room | Save: no (history already holds room, class, floor, cause). Balance: none. Art: none (note glyph exists). Needs a safe tile per room. | Yes: lore from data you have |
| IDEA-16 | Examine props: skulls, bones, graves, the horned skull and dung piles give one dry line when you press interact. | The map feels alive on repeat visits. | S | obj_skull_1/2, obj_bone, obj_grave, obj_horned_skull, obj_dung_pile, the D70 interact prompt | Save: no. Balance: none. Art: none. IDE: some props may not use obj_interactable yet (needs a parent change in the IDE). | Maybe: needs IDE check first |
| IDEA-17 | Codex lore lines: each enemy entry gains 2 extra lines that unlock after 3 and 8 kills of that species. | Gives a reason to meet every enemy again. | S | Codex_BestiaryRows in scr_menu, profile kill counts, Loc strings | Save: small, one kill-count map in the profile. Balance: none. Art: none (text only; the bestiary icons stay cut). | Maybe: pairs well with IDEA-07 |
| IDEA-18 | The tunnel darkens with deaths: the room darkness from D159 gets a little deeper at 3/6/10 deaths (capped, always readable). Amends D159's fixed darkness. | The world visibly reacts to your deaths. | S | The lighting pass, death tier from DeathLine_Tier | Save: no. Balance: none. Art: none. Must stay readable (accessibility). | Maybe: moody, but test readability |
| IDEA-19 | A flavour line for each of the 7 rings and charms ("Copper Ring: initials worn smooth. Not yours."), shown in the details panel under the numbers. | Items add to the mystery of the earlier mapmakers. | S | scr_db_item accessory rows, Loc strings, details panel (D100) | Save: no. Balance: none. Art: none. | Maybe: tiny, only text |

## Feel and polish

| ID | Idea | Why it helps replay | Size | Touches | Risk | Pick? |
|---|---|---|---|---|---|---|
| IDEA-20 | Ambience layer: a very quiet "haunting" ambience under the music from floor 6 on, a touch louder at higher death tiers. Reuses Ambience_haunting and Crying_moaning_ambience. | Deeper floors and later runs feel more uneasy. | S | scr_sfx bus and ducking, D42 music rules | Save: no. Balance: none. Sound: none new (existing files). The owner decides by ear. | Maybe: needs your ears |
| IDEA-21 | Boss finisher: the last hit on Palehorn and the Choirbeast gets a longer freeze, a zoom punch and a held beat before the slain text. Extends D138/D139. | Boss wins feel like an event. | S | Battle_CheckEnd, the existing freeze and zoom helpers in scr_fx | Save: no. Balance: none. Art: none. Honours the screen-shake setting. | Yes: cheap, big payoff |
| IDEA-22 | Retry this seed: the run summary offers "Try this seed again" next to the normal flow. Uses the seed entry from D152. | You can practise a run you nearly won, and share a seed with a friend. | S | RunFlow_Step / RunFlow_Draw, Run_StartNew(seed), Seed_Label | Save: no. Balance: none. Art: none. The class and echo screens still happen. | Yes: easy replay, uses D152 |
| IDEA-23 | Palette options: DMG green stays default; add a grey and a warm one in Settings. Amends D10 (strict palette). | A fun cosmetic reason to come back. | M | A palette-swap shader, Settings, every draw call that uses colours | Save: small (a setting). IDE: needs a shader resource created by the owner. Art: none, but the whole screen changes. | No: breaks D10, needs a shader |
| IDEA-24 | Enemies breathe faster the lower their HP is (a slow squash in battle). Extends D139's HP-state feedback. | HP state is readable at a glance without a number. | S | Enemy draw in obj_enemy_battle / battle draw code | Save: no. Balance: none. Art: none. Off with the screen-shake setting. | Maybe: subtle but nice |
| IDEA-25 | Death-screen tip: the death scene adds one plain tip based on the killer ("Poison killed you: Antidote cures it." / "Pale Hymn: BREAK it before it lands."), written from real game data (D100). | New players learn from each death, so the next run goes better. | S | DeathLine_Defs / DeathLine_KillerLine in scr_dialogue, Death_BuildContext | Save: no. Balance: none. Art: none. New text plus Korean. | Yes: teaches without a tutorial |

## Left out on purpose

Run modifiers, daily seeds, a node map, procedural floors, a post-win difficulty ladder (REQUIREMENTS "Not built, ever"), new floors or classes (D28), permanent power (D32), a Perfect streak (D139), a death tally on the ending (D104), dice or misses (D6, D80), and new sounds or footsteps (no footstep files exist; D41 says reuse first).

## Top 5 picks, in recommended order

1. **IDEA-07 Weak points.** The biggest depth gain for no art: skills and throwables suddenly matter per enemy.
2. **IDEA-01 Starting trinket.** Small, safe, and each run begins differently.
3. **IDEA-02 Grudge.** Makes dying matter in the next run and fits the lore (D102).
4. **IDEA-15 Last-fall note.** Cheap story from data the game already stores.
5. **IDEA-22 Retry this seed.** One button that makes replay easier, with no save or balance risk.

Close behind: IDEA-10 (elite modifiers), IDEA-21 (boss finisher), IDEA-25 (death tips), IDEA-14 (faces remember).
