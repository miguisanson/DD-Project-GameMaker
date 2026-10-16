# Text fits (D156, H13b)

Card and panel text never leaves its box and is never silently cut. One question is asked the same way everywhere: does this text, wrapped the way the draw
wraps it, fit this box? The answer comes from the draw's own functions (`Prompt_RichLayout` for a sentence with prompts or styled words, `string_width_ext` for a
plain block, `UI_TextWidth` for a line, the Ui_Metrics units for the boxes), so it is what the player sees.

## The checks

| Check | What it does |
|---|---|
| `UiFit_Check(text, w, h, wrap)` (scr_menu) | The helper. Returns `{ ok, w, h, lines }`: the widest line, the height, the number of lines. |
| `Test_Suite_TextFit` (scr_test) | Every workbook row of the known types through the helper at 480 x 432, 640 x 576 and 800 x 720, English and Korean: the Tab pages (Skills, Items, Gear, Status, Codex bestiary / notes / history / unlocks, System, Help), the battle command rows, skill and item rows with their number lines, the attack preview plate, every card at the pick's column width and the whole pick screen, every tutorial, the confirm questions and the credits roll. One assertion per type, size and language. |
| `UiFit_Enable` / the recorder (scripted runs) | `Ui_DrawFrame` remembers each frame drawn this frame (a full-screen dim starts a new layer). `Ui_Text`, `Ui_TextBlock` and the dialogue / death / credits text draws note any text that starts inside a frame and ends outside its inner edge (the border and the dark band, 2p) or leaves the screen. `Ui_FitText` notes every cut (the `..`). Each note is a fit failure `{ kind, panel, text, size, lang, have, need }` and a `[FIT]` line in the log. |
| `shots_textfit_<picture>_<lang>` (-shots) | After every picture: no panel drawn in the last two frames reported a fit failure. |

The build stamp (`Build_DrawId`) and the scrolling credits roll (top and bottom only) are exempt from the recorder; they are not panel text.

## How a layout gives way (in this order)

1. **Wrap** where there is room: tags, number-line labels wider than the column, the credits' long file names (`Credits_BreakLong`).
2. **Move the value**: a number line whose label and value do not fit side by side keeps the label on its row and puts the value right-aligned on the next
   (`Ui_DetailsLineStacked`, the cards did this already). Details panels and cards count the extra row in their height.
3. **Widen from the Ui_Metrics units**: a Tab page keeps its share unless a row's label or a number line asks for more; the other panel gives way
   (`TabMenu_Widths`; the list never takes more than two thirds). The battle command menu is half the right column unless a label needs more
   (`Battle_CmdPanelW`). The attack plate has 6p of air each side, 4p when only that fits, and four lines (label, number, label, number) when the gap is
   narrower than "Perfect 12" (`Battle_PreviewPlateLayout`).
4. **Tighten**: the card pick lowers its spacing (p instead of 2p between a card's blocks, 2p instead of 3p between the parts) and puts the hint beside the
   Skip box when the whole screen would not end above the bottom margin (`CardsUi_PickPlan`).
5. **Shrink**: not used. No panel draws below the D8 text rule.
6. **Ellipsis** (`Ui_FitText`): no decision allows it for a workbook row. It stays in `Ui_MenuDraw` rows, the details labels and the reader replies as the
   last resort, and every use is a recorded fit failure.

## Rows no layout fits (for the text side)

`TextFit_Known` in scr_test lists them; each entry must still fail somewhere, so the day the text is shortened the entry is deleted.

| Where | Row | What it needs |
|---|---|---|
| Skill lists (en) | Horizontal Slash | 326 units; the battle list has 238 at 800 x 720 (207 at 640 x 576), the Tab list 302 |
| Battle list (en) | Poison Arrow | 258 of 238 at 800 x 720 |
| Card names (en) | Meditation(+), Foresight+, Spellweave, Apothecary, Horizontal | one word of 10 to 11 letters is wider than a column at 640 x 576 / 800 x 720 (up to 232 of 196) |
| Card sentence (en) | Scrounger | 182 of 175 at 640 x 576 |
| Card pick (en, 800 x 720) | the upgrade cards (Poison Arrow+, Poison Mist+, Ice Spear+ and six more) | three columns of Skill / Upgrade text are 607 tall; the screen ends at 755 of 720 |
| Items tab (en and ko, 800 x 720) | throwables (Firebomb, Ice Flask, Smoke Bomb) | the sentence and the number lines are 20 to 64 units taller than the details panel |
| Bestiary (en, 800 x 720) | The Pale Choirbeast | the name asks the list for 502 of 764 units, which leaves the details panel too narrow for every other enemy |
| Run history (en and ko, 640 / 800) | "Foes beaten", "Damage taken", "{class} Lv 10" with "Gave up" | the list rows and the number lines ask for more than the body has |
