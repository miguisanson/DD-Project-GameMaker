# G10 - one UI style audit (D129, D133)

Method: the shots run at 480 x 432 and 800 x 720 (286 pictures, build 88be979) was opened picture by picture; the draw code was grepped for hand-made panels
(`draw_rectangle`), colours outside the palette macros (`c_*`, `make_colour`), literal paddings, a second cursor and direct `audio_play_sound`.

What already holds (checked, no change needed):

- **Frame:** every panel, pop-up, banner, dialogue box, name tab, card and skip box goes through `Ui_DrawFrame`. No screen draws its own panel with `draw_rectangle`.
- **Cursor:** one style (dark band + the `>` marker from `Ui_MenuDraw`, the card pick and the shop use the same rows). The seed digits and the dialogue "more" arrow are controls, not cursors.
- **Text:** all text goes through `Ui_Text` / `Ui_TextBlock` / `Prompt_RichDraw` (one font, one scale rule). Remaining `c_white` calls are draw-state resets or neutral sprite tints.
- **UI sounds:** every UI sound is `SFX_PlayUI` (`ui_move`, `ui_confirm`, `ui_back`, `ui_openclose`). No `audio_play_sound` in any screen (only in `scr_sfx` and the debug sound manager).
- **Palette:** QTE bars, battle HUD, world marks use the `UI_C_*` macros.

## Deviations found

| # | Screen | What differs from the shared style | Fix / status |
|---|---|---|---|
| 1 | Title (menu at the Korean 800 x 720 size), run summary | Build id: a 22-character stamp in white at 70 percent alpha with hard-coded 4 / 2 pixel padding. It overlapped the Korean title menu at 800 x 720 and the footer line of the Korean run summary at 480 x 432. | **Fixed.** Short id (`88be979*`, the star = uncommitted files; the full id stays in the `[TEST-BUILD]` line), palette white with the dark one-pixel shadow of the splash prompt, one `Ui_Metrics` margin from the corner. Check: `shots_title_build_id_clear_of_the_menu / card / prompt`. |
| 2 | Battle skill and item lists | The details panel (grows up from the list) covered the enemy at 480 x 432 and at 800 x 720. | **Fixed.** New `layout.det_floor_y` (the battle sets it to just under the enemy): the list and panel give way - two rows, then the arrow strip is left out of the details, then one row. Check: `shots_battleui_menus_leave_the_enemy_clear_*` (all battle pictures, using the new `Battle_EnemyRect`). |
| 3 | Pop-ups and pages | Five dim strengths for the backdrop (0.5, 0.55, 0.6, 0.8, 0.9). D133 asks for one. | **Fixed.** Two named strengths: `UI_DIM_POPUP` (0.6: pop-ups, the menu stack, bed, notice, tutorial, confirm, seed entry, settings pop-up, the Keep this box) and `UI_DIM_SCREEN` (0.8: Tab menu, card pick, shop). |
| 4 | Dialogue over a cutscene picture | Text and shadow in `c_white` / `c_black`, outside the palette macros. | **Fixed.** `UI_C_TEXT` and `UI_C_DARKEST` (white is unchanged; the shadow goes from black to the palette's darkest). |
| 5 | Run summary | Appeared at once; every other panel fades in and slides down three pixel steps. | **Fixed.** Uses `Ui_AnimT` over `UI_PANEL_MS` (frames converted to ms). |
| 6 | Run end: death picture | Its own 30-frame fade (picture and line). | Left: a deliberate scene fade, not a panel; no owner decision against it. |
| 7 | Refused buy / refused item / locked row | No "refuse" sound: a refusal plays `ui_confirm`, then the message. D133 lists a "denied" sound. | Left: needs a sound chosen by ear (owner L5 check) and a new key in `scr_sfx`. One line to add once the sound is picked. |
| 8 | Every framed screen | The frame inset is the literal `4 * p` (77 places in `scr_menu`, `scr_combat`, `scr_dialogue`, `scr_room_state`, `scr_input`); `Ui_Metrics` has `pad` and `margin` but no `inset`. | Left: a pure rename with no visible change, about 77 edits across ten screens, and every picture would have to be compared again. Worth doing as its own packet. |
| 9 | Battle: foresight eye plate, highlighted status chip outline | Hand-made one-pixel plates with `Ui_Box` instead of `Ui_DrawFrame`. | Left: small HUD marks, palette-correct, no band by design. |
| 10 | Battle: QTE bar, arrows | Own outline (`Qte_FillRect`). | Left: a game element, not a panel; palette-correct. |
| 11 | Hint lines | Position differs: Tab menu footer bottom left, battle list hint right above the details, card pick and notice centred. | Left: needs the owner (D156 chose the wording, not the place). |
| 12 | Boot logo, room fades | `c_black` background / fade. | Left: the engine's black, not UI. |
| 13 | Debug sound manager overlay | Own translucent rectangle, `c_black` / `c_white`. | Left: debug only, never in a player-facing screen. |

13 deviations: 5 fixed, 8 left (reasons above).

## Known issues from the packet

1. Korean title menu over the build id at 800 x 720: row 1.
2. Skill details panel over the enemy at 480 x 432 (and at 800 x 720): row 2.
