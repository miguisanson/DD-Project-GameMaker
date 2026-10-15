# Text markup (D149, D156)

Player-facing sentences can carry three kinds of markup inside the localized string (`game_text.xlsx`, both `en` and `ko`).
One parser (`Markup_Parse`), one layout (`Prompt_RichLayout`) and one drawer (`Prompt_RichDraw`, and `Markup_DrawLine` for the dialogue
box) in `scripts/scr_input/scr_input.gml` serve every place that shows sentences. Write the markup in the workbook, never in GML.

## The tags

| Markup | Shows | Use it for |
|---|---|---|
| `[t]Poison[/t]` | the word in the palette's bright green (`UI_C_TERM`, #86C06C) | game terms: status names (Poison, Burn, Bleed, Stun, Steadfast, Guard ...), stat names (ATK, DEF, SPD, MAG), HP, MP, stagger, the hit grades (Weak, OK, Good), Elite |
| `[a]BREAK[/a]` | the word in the one accent, merchant gold (`UI_C_ACCENT`, exactly #E8C547) | **only** rare or critical words: `BREAK`, `Perfect`, and a newly received item (`[a]{item}[/a]`) |
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
4. Variables go inside the tag when they are the term or the item: `Gain [t]{status}[/t] for {turns} turns.`, `Received [a]{item}[/a] x{qty}.`
   The variable is filled in before the text is drawn.
5. Korean: put the tag around the word only and leave the particle outside: `[t]HP[/t]를`, `[k:confirm]을(를)`, `[a]브레이크[/a] 상태`.
   Count the same `[a]` spans and the same `[k:..]` buttons as the English (the check compares them). `[t]` spans may differ.
6. Do not mark a term in a title, a name, a menu row, a stat label, a number line or the battle log: those are drawn plain (see below); if
   markup reaches one, the brackets are removed and the words are shown plain.
7. Use the accent sparingly. If a sentence has more than one gold word it stops being an accent. Terms are the everyday highlight.
8. Do not put a button inside a tag: `[t][k:confirm][/t]` is nested.
9. A tag that looks like a tag but is not one we know (`[x]`, `[k:dance]`) is dropped from the screen. Nothing with brackets ever shows, and the
   lint names it.

## Where it is drawn, and where it is not

Drawn with the markup: the dialogue box (and the cutscene text that uses it), card text (name, sentence, hint line), tooltips and detail
panels (item, skill, status, stat sentences), tutorial pop-ups and the Help page, the notes in the Codex, the hint footers, the death and
wake lines, the summary footer.

Drawn plain (any tags are stripped, glyphs become their label): menu row labels, titles and name tabs, number lines (label / value),
the battle log and pop numbers, the HUD. If you need a highlighted term in one of these, change the draw path to `Ui_TextBlock` first.

## Width, wrapping, typing

* The markup has no width. A word is measured as plain text; a button is measured at its real glyph width (a keycap or a pad button).
* Lines break at spaces and before any glyph. A tag never crosses a line: each word carries its own colour.
* The dialogue typewriter counts what the player sees (a button is one character); `Markup_Reveal` cuts a span and keeps it closed.
* Hard line breaks: `\n` in the string.

## Checking

* `Test_Suite_RichText` (scr_test): the parser, the device glyphs, the arrows, the accent colour, the battle prompt line, and an audit of
  every string in both languages (well-formed markup, `[a]` only on BREAK / Perfect / `{item}`, same accents and buttons in en and ko, no key
  letters in English).
* `python tools/localization/lint_markup.py` (the same audit, runnable while writing; `--selftest` for the tool itself).
* After editing the workbook: `python tools/localization/build_localization.py --xlsx datafiles/localization/game_text.xlsx --json datafiles/localization/localization.json`.

## Battle prompts (D156)

One prompt line per state, for the current action. The skill and item lists show `[k:confirm] Choose`; Back is Esc / B everywhere and is not
repeated; the command menu and the bars show none (a bar is taught by its first-time pop-up). `Battle_HintLabels(state)` lists what a state
draws.
