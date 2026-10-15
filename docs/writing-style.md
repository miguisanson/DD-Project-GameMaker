# Writing style guide (D155)

For the writer agent that rewrites ALL player-facing text of DD-Project (the owner skims the result at the next playtest).
Read this first, then `.planning/research/DECISIONS.md` (D34, D47-D48, D87, D102-D104, D147-D149, D154-D155) and `.planning/research/ko-glossary.md`.

The game is an 8-bit dungeon roguelike. You wake at the bottom of a tunnel that was not there yesterday, you are a mapmaker and not a fighter,
you do not know where you are, and every time you die you wake where you fell. That is the whole voice: **short, concrete, a little dry, never explained.**

## 1. Where the text lives, and what not to touch

- Every line goes through `datafiles/localization/game_text.xlsx` (sheet `strings`: `ref`, `en`, `ko`). Edit it with `openpyxl`, then
  `python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json`,
  then `python tools/localization/lint_hardcoded_text.py` and `python tools/localization/check_missing_ko.py`. Never hand-edit `localization.json`.
- GML keeps an English fallback next to each key (`Loc_T("key", "fallback")`, or a keyed table such as `Note_Defs`, `Choice_Raw`). When you change a row,
  change its fallback to the same words in the same commit (a test that reads the fallback must still agree with the sheet).
- English text is plain ASCII (straight quotes, `...`, no em dash, no curly quotes): the pixel font and the GML sources are ASCII. Korean is written in the sheet only.
- Keep every `{placeholder}` exactly as it is (`{n}`, `{power}`, `{turns}`, `{item}`, `{killer}`, `{confirm}`...). Numbers in rules text come from the game data (D100), never typed in.
- Names of classes, skills, enemies and items follow the glossary and stay one word for one thing (D133). Do not rename a thing in flavour text.
- Do not add or remove rows' keys, and do not change a number, a cost, a condition or a rule. You rewrite words, not mechanics.
- Known gap: these `DialogueDB_Init` entries have no row in the sheet yet, so they exist only as English fallbacks in GML and Korean players read English: `first_encounter_mini_boss`,
  `first_encounter_final_boss`, `sys_floor2_dire_wolf_reaction`, `sys_first_stranger_encounter_reaction`, `sys_first_level_up_reaction`, `sys_first_equippable_item_reaction`,
  `sys_final_boss_defeated_reaction`, `sys_floor9_5_exit_reaction`. Give each one `dialogue.<id>.<n>` rows (en + ko) as part of the rewrite (the key is `dialogue.` + id + `.` + the line's index from 0).
- Spoilers (D104): the outside world is as ruined as the tunnel and the raid party is dead. Death and wake lines may lean toward it, never say it.

## 2. The box: how much fits (measured on the real Dialogue box)

Measured from the game at windowed scale 3 (480 x 432) and scale 5 (800 x 720); scale 4 lies between. The box is the shared frame, 3 text lines, a name tab above it.

| Window | Box | Text area | Line height | English (retro_gaming) | Korean (Hangul) |
|---|---|---|---|---|---|
| 480 x 432 | 468 x 76 px | 440 px wide, 3 lines | 20 px (KO 23) | about 10 px a character: ~43 per line, 33 if all capitals | 18 px a syllable: 24 per line |
| 800 x 720 | 776 x 152 px | 720 px wide, 3 lines | 40 px (KO 47) | about 20 px a character: ~35 per line, 27 if all capitals | 36 px a syllable: 20 per line |

The larger window is the tight one (the font grows faster than the screen). Write for it:

- **One dialogue entry (one tap) is at most 100 characters of English and 55 Korean syllables; aim for 70 and 40.** The 3 lines of one page hold about that much.
  An entry that wraps past 3 lines is cut into pages automatically (word wrap), but each page is another tap: do not let that happen to a line you wrote.
- **Short lines are the style.** The longest dialogue entry in the game today is 63 characters. Most good ones are under 40: "Heavy... but it fits." / "Stop calling to me."
- One thought per entry. Split a long thought across entries; give the second a reason to exist (a turn, a doubt, a silence "...").
- Speaker name (the tab): one word, the longest today is "Merchant"; a note's title is its tab and stays under 17 characters ("Torn survey page").
- Choice replies (the two lines above the box, D154): at most 18 characters of English, 9 Korean syllables, each its own full sentence-fragment ("A way out.", "Back off.").
- Other panels (details panel, tutorial pop-up, list rows) have their own widths; the `-shots` run asserts that text fits the rectangle, so a too-long line fails the gate. Write short first, then check the picture.

## 3. Voice

**The hero (Nobody, D34).** First person, spoken, casual. Confused on waking: asks questions, does not get answers, starts sentences and drops them with `...`.
A mapmaker: notices walls, distances, handwriting, whether a map could hold this place. Scared, practical, sarcastic when scared. Never lectures the player about the story.
Swearing exists in three old lines (the English fallbacks of `first_encounter_mini_boss` and `sys_final_boss_defeated_reaction`); do not add more, and prefer a silence ("...") where a curse would go. Flag the old ones for the owner rather than deleting them.

**The narrator.** Second person, present tense, for the world: notes, graves, death lines, wake lines, objects ("It stares back at you."). Past tense only in the intro cutscene
("You were a mapmaker in a remote village."). Asides to the player go in parentheses, present tense: "(You clutch your head while walking toward the exit.)"

**The Stranger.** Friendly in a way that is wrong. Knows more than he says. Answers a question with a smaller question or half an answer. Short, even sentences. He smiles;
his words never threaten. He speaks as if he remembers earlier runs ("There you are.").

**The merchant.** Tired, flat, transactional, a little funny. Sells hope by the pound. Dark one-liners with no explanation of where he sleeps or who he was.
Repeats himself on purpose ("I'll be here. I'm always here."). Korean: casual and flat, 반말.

**The authors of notes.** Earlier mapmakers: the hero's own hand, and other hands. Terse, unfinished, scratched or inked. At most 3 lines, each under 60 characters.
Each note has ONE concrete object (a torn page, a wall, a letter, a carved arrow) and ONE wrong detail (the ink is wet; the arrow is crossed out; the marks are in your hand).
Quotes are straight `"..."`. Nobody in a note explains the tunnel.

**Enemies** do not speak. They have names, attack verbs and one sensory line at most. **The system** (menus, save messages, errors) is plain and polite and has no character.

## 4. Show, do not tell

- Replace a feeling word with the thing that causes it. "You are afraid" -> "Your hand finds the wall and stays there."
- Prefer one hard detail to three soft ones. Cold stone, damp, the breathing wall, wet ink, dripping, a choir far off, iron and old leaves.
- Verbs over adjectives. Cut "very", "really", "somehow", "suddenly", "seems to" (one "seems" per scene, for the tunnel).
- No explaining the joke or the dread: stop one beat early. "The fire was warm, at least." needs nothing after it.
- Recurring images are allowed and wanted, used sparingly: counting marks, handwriting you do not remember, the tunnel wanting a mapmaker, the choir, "nobody is coming", cold against warm.
- Do not describe what the screen shows (the player sees the HP bar, the chest, the door).

## 5. Per kind of text

**Class descriptions (D148).** Lore first, then how it plays. No "to find", no "you can". Two short sentences, about 100 characters in all.
Name the style of fighting in words a new player can use ("hits hard, slow to be hurt"), not stats.

**Items and skills (D100, D149).** Line 1 = the effect in plain words with the real numbers (placeholders), at most about 80 characters, the key term in `[t]..[/t]` after H8b.
Line 2 (optional) = flavour, at most about 50 characters, no numbers, never repeating line 1. A potion's flavour says who it belonged to; a skill's flavour says how it feels.
Names stay as in the glossary.

**Tutorials (D45).** Plain, short, imperative. Maximum two sentences, about 140 characters. Start with the action or the button, then what it does. No lore, no jokes, no "remember".
Title is two words at most. Use the button markup, never a typed key name.

**Dialogue and reactions.** The hero reacts to ONE thing per box and moves on. Do not summarise what the player just did. A reaction line may ask a question and leave it hanging.

**Wake and death lines (D102-D103).** One line each, 2-4 s on screen. They darken as deaths pile up: curious, then tired, then fond of the place, then empty. A killer line is dry and about
the killer, not the player ("A slime. You were beaten by a slime."). No score talk, no "game over".

**Lore notes (D107).** See the voice sheet. A note read after 3 / 6 / 10 deaths may speak in the hero's own hand about the hero.

**Small choices (D154).** A question of two short lines, two replies, a reply line, a later line that remembers. The reply never gives a reward or an order; it changes a mood.
`choice.*` rows are the model (merchant, Stranger, torn survey page, wake).

**UI, battle and shop messages.** Title Case for menu items, one word per meaning (D133), polite; the combat log is short and factual ("You hit for {dmg} damage!").

## 6. Humour

- Dry, deadpan, understated. A joke is a fact said plainly. One joke at most in a scene, and it goes in the merchant's or the death line's mouth, not the tutorial's.
- Never at the player's expense during a loss they just suffered more than once; the tunnel teases, the writer does not.
- No fourth wall (the credits are the one place the studio speaks), no pop-culture, no puns, no exclamation marks outside combat.
- If you are unsure it is funny, make it plainer.

## 7. Korean

- Follow `.planning/research/ko-glossary.md`: register per kind of text (UI polite 합니다; narration plain 한다; the hero casual 해/야; the merchant flat 반말; labels as nouns), the term table, particles written both ways after a placeholder: 이(가), 을(를), (으)로.
- Translate the meaning and the tone, not the words. Korean may be shorter; it must never be longer than the budget in section 2 (24 / 20 syllables a line, 55 per entry).
- No English left in a line except the allowed Latin tokens (HP, MP, ATK...). Keep the names from the glossary.
- Do not machine-translate a line you are unsure of: write your best natural line and list the `ref` in the report as "ko: needs review". The sheet has no note column, so the list lives in the packet report.

## 8. Markup in the text

Today a line can carry `{name}` placeholders (values and, in tutorials, `{confirm}` `{up}` `{down}` `{left}` `{right}` for the last-used device's button).
After H8b (the packet that adds D149 highlights) three tags are available. Use these exact forms, nowhere else:

| Form | Use | Example |
|---|---|---|
| `[t]term[/t]` | a game term in the brightest palette green: Poison, Stagger, a skill or status name when it is being explained | `Applies [t]Poison[/t] for {turns} turns.` |
| `[a]accent[/a]` | the single accent colour (merchant gold) for a RARE or critical word: BREAK, Perfect, a newly received item | `Perfect: [a]BREAK[/a] the enemy.` |
| `[k:action]` | a button glyph for an input action: `[k:confirm]`, `[k:cancel]`, `[k:up]` ... | `Press [k:confirm] on the bright zone.` |

Rules: never nest tags; at most 2 tagged words in one sentence, 1 accent per screen; tags do not count toward the character budget of section 2 (the visible word does); never tag in notes, wake or death lines.
Until H8b lands, write plain text and the existing `{confirm}` style; do not type the tags into rows before then.

## 9. Before and after (current text)

| Kind | Before | After | Why |
|---|---|---|---|
| Wake line (`wake.t1`) | You wake where you first fell. Alive. | Cold stone under your cheek. You are where you fell. Alive, at least. | A concrete sense first, then the dry turn. 69 characters: two lines at the tight size. |
| Death line (`death.t3.2`) | Dying is starting to feel like routine. | You know which way the ceiling will be before you open your eyes. | Shows the routine instead of naming it. 65 characters. |
| Class line (`class.line.mage`) | A scholar who heard the dark. Frail, but great magic and mana. | You read by one cold lamp until the dark read back. Frail, but your spells hit hard and drink mana. | Lore, then play. 99 characters; "frail / hits hard / drinks mana" are the words the player can use. |
| Tutorial (`tutorial.bar.body`) | A cursor slides along the bar. Press {confirm} when it is over the bright zone. The closer to the middle, the harder you hit. | Press [k:confirm] when the cursor is on the bright zone. The closer to the middle, the harder the hit. | Action first; the sliding is on the screen already. 102 characters, under the 140 tutorial budget. |
| Item (`item.sent.30`) | Throw it for {power} power of damage; it burns for {turns} turns. Costs your turn. | Deals {power} damage and sets the enemy burning for {turns} turns. Uses your turn. (Flavour: The flask is still warm.) | Effect line plain and complete; flavour in its own line, no numbers. |
| Passive (`item.passive.desc.3`) | +35% damage to foes below 35% HP | [t]Executioner[/t]: +35% damage to foes under 35% HP. (Flavour: You learn where the seam is.) | One-line effect first, then the flavour. |
| Reaction (`sys_first_equippable_item_reaction`, last line) | It's not making sense, and it's creeping me out. | Chests every few steps. A sword that fits my hand. Somebody wants me armed. | Names the evidence instead of the feeling. 75 characters: split it into three entries of about 25 for a slower read. |
| Floor 1 reaction (`combat.msg.floor1_reaction.0`) | How was that even alive?! I nearly died. | That thing was alive. And I nearly wasn't. | Cuts the "?!", keeps the voice. |
| Merchant (keep as it is) | You came a long way down. Brave. Or lost. | (unchanged) | A model line: flat, a little funny, tells you who he thinks you are. |
| Note (keep as it is) | Beside them, in a shakier hand: "Stop counting." | (unchanged) | A model: one object, one wrong detail, no explanation. |

## 10. Checklist before you hand text back

1. Every entry is within the section 2 budget in English and Korean.
2. No spoiler, no new swearing, no mechanics changed, every placeholder intact, ASCII only in English.
3. Each line says one thing and stops one beat early. Read each aloud once; cut the first word that does no work.
4. Rows built, `lint_hardcoded_text.py` clean, `check_missing_ko.py` clean, the GML fallbacks match the sheet.
5. A list of Korean rows that need a native check, and of old lines you left because they were already good.
