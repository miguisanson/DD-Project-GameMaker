# Text markup (D149, D156)

Player-facing sentences can carry four kinds of markup inside the localized string (`game_text.xlsx`, both `en` and `ko`).
One parser (`Markup_Parse`), one layout (`Prompt_RichLayout`) and one drawer (`Prompt_RichDraw`, and `Markup_DrawLine` for the dialogue
box) in `scripts/scr_input/scr_input.gml` serve every place that shows sentences. Write the markup in the workbook, never in GML.

## The tags

| Markup | Shows | Use it for |
|---|---|---|
| `[t]Poison[/t]` | the word in the palette's bright green (`UI_C_TERM`, #86C06C) | game terms: status names (Poison, Burn, Bleed, Stun, Steadfast, Guard ...), stat names (ATK, DEF, SPD, MAG), HP, MP, stagger, the hit grades (Weak, OK, Good), Elite |
| `[a]BREAK[/a]` | the word in the one accent, merchant gold (`UI_C_ACCENT`, exactly #E8C547) | **only** rare or critical words: `BREAK` and `Perfect` |
| `[r1]..[/r1]` `[r2]..[/r2]` `[r3]..[/r3]` | an item's name in its rarity colour (D178): Common white, Rare gold #E8C547, Epic gold that pulses to a lighter gold (#F6E6A0) every ~600 ms | **only** an item's name, and only written by the game (`Item_NameMarked(id, qty)`), never in the workbook |
| `[k:confirm]` | the button for that action, drawn for the device used last | every mention of a button: "Press [k:confirm]", "[k:left][k:right] Choose" |

Button names for `[k:..]`: `confirm`, `back` (or `cancel`), `up`, `down`, `left`, `right`, `interact`, `run`, `tab_prev`, `tab_next`,
`menu`, `pause`, `start`.

* Keyboard (the last input was a key or the mouse): a keycap with the key's name (the player's own binding: "Space", "Esc", "Q"). The four
  move prompts are **arrow keycaps** while an arrow key is bound to that move (it is by default), so no text says "A/D" or "W/S".
* Pad (the last input was a pad): Xbox-style round buttons `A` (confirm, interact), `B` (back), `X` (menu), `Y` (pause), pills `LB` / `RB`
  (tabs), `LT` (run), `Start`; the move prompts are a **d-pad plus sign with the named arrows lit** (`[k:left][k:right]` is one d-pad with
  both side arms lit).
* The prompt follows the device live: switching device re-draws every open text, and the dialogue box lays its pages out again for the new
  glyph widths (it keeps its page, and the line starts typing again).
* The older `{confirm}` / `{left}` spelling is still read, but write `[k:confirm]`. `tools/localization/lint_markup.py` flags `{confirm}`.
* A word of key letters is never written as text ("Press Z", "A/D", "WASD", "Up / Down"): the lint and `Test_Suite_RichText` fail on it.
  The one place that names keys as text is the keyboard-only Controls page.

## Rules

1. Tags do not nest. `[t]a [a]b[/a][/t]` is wrong: the outer tag is dropped and the inner one stays. Put one tag around one span.
2. Close every tag. An unclosed `[t]` is dropped and its text stays plain.
3. A multi-word term is fine: `[t]Rev Up[/t]`. The colour follows each word, and the line may break inside it.
4. Variables go inside the tag when they are the term: `Gain [t]{status}[/t] for {turns} turns.`. An item's name is a plain `{item}`: the game marks it (see below): `Received {item} x{qty}.`
   The variable is filled in before the text is drawn.
5. Korean: put the tag around the word only and leave the particle outside: `[t]HP[/t]를`, `[k:confirm]을(를)`, `[a]브레이크[/a] 상태`.
   Count the same `[a]` spans and the same `[k:..]` buttons as the English (the check compares them). `[t]` spans may differ.
6. Do not mark a term in a title, a name, a menu row, a stat label, a number line or the battle log: those are drawn plain (see below); if
   markup reaches one, the brackets are removed and the words are shown plain.
7. Use the accent sparingly. If a sentence has more than one gold word it stops being an accent. Terms are the everyday highlight.
8. Do not put a button inside a tag: `[t][k:confirm][/t]` is nested.
9. A tag that looks like a tag but is not one we know (`[x]`, `[k:dance]`) is dropped from the screen. Nothing with brackets ever shows, and the
   lint names it.

## Item names and rarity (D178)

Every item has a rarity from one explicit table (`Item_Rarity(id)` in `scripts/scr_db_item/scr_db_item.gml`): 1 Common, 2 Rare, 3 Epic. A loot-table item has the highest
loot tier it appears at; an item in no loot table goes by its price (under 18 Common, 18 to 39 Rare, 40 and up Epic).

* A sentence that names an item gets the name from `Item_NameMarked(id)` (`"[r2]Iron Sword[/r2]"`, with a count `Item_NameMarked(id, 3)` -> `"[r2]Iron Sword[/r2] x3"`) and
  puts it in the workbook string as the ordinary `{item}` (or `{name}`) variable. **Never write `[r1]` / `[r2]` / `[r3]` in the workbook, and never put `[a]` round an item**:
  `tools/localization/lint_markup.py` and `Test_Suite_Rarity` fail on both. Korean: the particle stays outside the variable (`{item}을(를)`), as before.
* Every message that names an item uses it: the received line of a chest, barrel and grave (`Loot_ReceivedLines`), the battle and auto-resolve drop (`Loot_BuildMessageEntries`),
  Stole, Equipped, Unequipped, Replaces, the throw line, Bought, Sold, the sell question and the echo question.
* In a list (bag, Gear, Items, shop, the battle item list) a row that carries `icon_item` draws its name in the rarity colour (`Ui_RowLabelColor`); a dim row (cannot use, empty,
  too expensive) stays the light green and a disabled row the dark green, whatever the rarity. The value column keeps the row colour.
* An item's icon (`Item_DrawIcon`, the dialogue's drop icon) gets a 3 x 3 gem on its top-right corner: Rare a gold plus, Epic the same with a pale second frame every 300 ms.
  Common has none. The gem stays on a dim row.
* The plain draws (`Ui_Text`) show a marked name without its tags; the lines that must keep the colour (the battle log toast, the shop plate, the Tab menu toast) draw with
  `Ui_LineDraw`.

## Where it is drawn, and where it is not

Drawn with the markup: the dialogue box (and the cutscene text that uses it), card text (name, sentence, hint line), tooltips and detail
panels (item, skill, status, stat sentences), tutorial pop-ups and the Help page, the notes in the Codex, the hint footers, the death and
wake lines, the summary footer.

Drawn plain (any tags are stripped, glyphs become their label): menu row labels, titles and name tabs, number lines (label / value),
the battle pop numbers, the HUD (the battle log toast keeps item names in their colour, see above). If you need a highlighted term in one of these, change the draw path to `Ui_TextBlock` first.

## Width, wrapping, typing

* The markup has no width. A word is measured as plain text; a button is measured at its real glyph width (a keycap or a pad button).
* Lines break at spaces and before any glyph. A tag never crosses a line: each word carries its own colour.
* The dialogue typewriter counts what the player sees (a button is one character); `Markup_Reveal` cuts a span and keeps it closed.
* Hard line breaks: `\n` in the string.

## Checking

* `Test_Suite_RichText` (scr_test): the parser, the device glyphs, the arrows, the accent colour, the battle prompt line, and an audit of
  every string in both languages (well-formed markup, `[a]` only on BREAK / Perfect, same accents and buttons in en and ko, no key
  letters in English).
* `python tools/localization/lint_markup.py` (the same audit, runnable while writing; `--selftest` for the tool itself).
* After editing the workbook: `python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json`.

## Battle prompts (D156)

One prompt line per state, for the current action. The skill and item lists show `[k:confirm] Choose`; Back is Esc / B everywhere and is not
repeated; the command menu and the bars show none (a bar is taught by its first-time pop-up). `Battle_HintLabels(state)` lists what a state
draws.
