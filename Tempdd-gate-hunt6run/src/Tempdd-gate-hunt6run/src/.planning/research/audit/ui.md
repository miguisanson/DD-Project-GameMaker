# UI / menus / inventory audit

Date: 2026-10-13. Read-only audit of code and PNGs. Nothing was run. Everything below is from reading source, `.yy` files and sprite PNGs. Numbers marked (est.) are calculated from the layout code, not measured on screen.

## 0. How the UI is built (applies to every screen)

- Everything is drawn in the **Draw GUI** event (`Draw_64`), through `UI_*` helpers in `scripts/scr_player/scr_player.gml:735-1260`. Nothing is drawn in a plain Draw event.
- The GUI layer is set to exactly `160*S x 144*S` px (S = 3..5): `display_set_gui_size(port_w, port_h)` in `GameSettings_ApplyDisplay` (`scr_player.gml`, about line 1470). So at the default 3x the GUI is 480x432. Base art is 160x144 (`DISPLAY_BASE_W/H`, `scr_macros.gml:277-278`).
- Text: one font, `retro_gaming` (`UI_FONT`, `scr_macros.gml:138`), size 12, AntiAlias on (`fonts/retro_gaming/retro_gaming.yy`). Korean swaps to a runtime NanumGothic `font_add` at size 11 (`UI_SetFont`, `scr_player.gml:825`).
- Text scale is a float: `UI_GetTextScale` (`scr_player.gml:746`). Windowed: 1.2 at 3x, 1.6 at 4x, 2.0 at 5x. Fullscreen/fit: rounded to 0.5 steps (2.0 at 3x, 2.5 at 4x, 3.5 at 5x). Tooltips multiply that by a further 0.93; status text tags by 0.45.
- Sprite scale is an integer: `UI_GetSpriteScale` (`scr_player.gml:776`). It is **1 in every windowed size** and 2 in fit-screen at 3x. HP/MP bars use `UI_BAR_SCALE * that` = 3x.
- There is **no 9-slice sprite anywhere** (no `nineSlice` in any sprite `.yy`) and no shader. Every panel is `draw_rectangle` (filled black at alpha 0.85-0.9, then a 1-px white outline). Every selection highlight is a filled white rectangle with black text.
- Colours are pure `c_white` / `c_black`. The art palette is the 4-colour Game Boy green (see `icons-needed.md`), so the UI is the one off-palette element in the game.
- Navigation is keyboard + gamepad only (no mouse), through `Input_UIPressed/Confirm/Back` (`scr_input.gml:389-405`). **Hold-to-repeat is switched off** (`Input_UIRepeat` just returns `Input_Pressed`, `scr_input.gml:393`), so long lists need one key press per row.
- Open/close fade is shared: `UI_PopupAlpha` (8 frames). Modal dim is shared: `UI_DrawModalDim` (`scr_player.gml:1241`).

## 1. Screen map

| Screen | Drawn by (file:line) | Anchoring | Font / text | Sprites used | 9-slice? | Input focus | Scaling |
|---|---|---|---|---|---|---|---|
| Battle HUD (HP/MP bars + player status row) | `obj_ui_controller/Draw_64.gml:12-74` | top-left, `margin = max(6, 8*visual)`; follows camera shake | `UI_DrawText` for "hp / max" next to bar | `hp_bar`, `mp_bar` (31x9, 11 frames), status icons | no, flat | none (display only) | bars int x3; text float |
| Battle log (the only battle message area) | `obj_battle_controller/Draw_64.gml:115-185` | top-right, right-aligned, 6 lines, `w*0.45` wrap | plain white text, **no backing panel** over a flat dark background | optional item icon per line | no | none | float text; icon x1 |
| Enemy status icons | `Draw_64.gml:187-198` | under enemy sprite, converted from world coords | text tags (see P1) | status sprites | no | none | mixed |
| Battle command menu (ATTACK / SKILL / ITEM / RUN) | `Draw_64.gml:381-422` | bottom-right box sized to the longest label | `>` pointer + label, **black text on a white box** | none | no | up/down wraps, confirm, back (`Step_0.gml:72-76`) | float |
| Battle skill select | `Draw_64.gml:424-459` | bottom, full width, 4 visible rows, scrolls with no indicator | "Name (3MP)" | `sk.icon_sprite` (always `noone`, so no icon) | no | up/down wraps, "Back" row at the end | float |
| Battle item select | `Draw_64.gml:461-496` | same box | "Name xN" | `item.sprite` at x1 | no | same | float |
| Battle tooltip (skill/item) | `Draw_64.gml:498-543`; box in `Tooltip_DrawBox` (`scr_menu.gml:799`) | above the list, left-aligned, 3-px gap | text scale x0.93 | none | no | follows list cursor | float x0.93 |
| Attack-timing QTE | `Draw_64.gml:218-257` | at `attack_timing_target_x/y` | feedback text with 1-px black shadow | `spr_attack_timing_target`, `spr_attack_timing_falling` (16x16) | no | action buttons | `ATTACK_TIMING_SPRITE_SCALE * ui_sprite` |
| Defensive QTE arrow + bar | `Draw_64.gml:306-366`; `Battle_DrawDirectionArrow` (`scr_combat.gml:1406`) | below enemy sprite, clamped between HUD and menu | none | arrow is **4 `draw_line` calls** (1-px vector lines); bar is rectangles | no | direction keys | float |
| Skill banner | `Draw_64.gml:270-304` | full-width black strip above enemy | one centred line | none | no | none | float |
| Dialogue box | `obj_ui_controller/Draw_64.gml:123-232`; rect/layout `Dialogue_BoxRect`, `Dialogue_TextLayout` (`scr_dialogue.gml:577-660`) | bottom, margin 8*visual, height >= 64*visual or 3 lines | typewriter text, speaker "Name:" line | `dialogue_arrow_down` (blinking cue, **pure white, 1 colour**), optional line icon | no | confirm advances | float |
| Cutscene text | same block, `cutscene_text_only` branch | lower 30% of screen, drop shadow +1,+1 | white on black art | scene sprites via `draw_sprite_stretched` | no | confirm | float |
| Main menu (title) | `obj_start_controller/Draw_64.gml:58-94` | list at 62% of height, x 30%-70% of width | white text; selected row = white bar + black text | title art `main_menu` (palette-correct) | no | up/down, confirm | float |
| Difficulty popup | `obj_start_controller/Draw_64.gml:96-170` | centred, 62% x 44% | same | none | no | up/down | float |
| Pause menu (Resume / Settings / Exit to Main Menu) | `PauseMenu_Draw` `scr_menu.gml:2711` | centred, 35% x 24% | same | none | no | up/down, back closes | float |
| Settings popup (UI/SFX/BGM %, Scale, Fullscreen, Language, Apply, Back) | `SettingsPopup_Draw` `scr_menu.gml:2357-2538` | centred, content-sized | values as text ("70%"), right-aligned | none, **no slider graphics** | no | up/down, left/right changes | float |
| Character menu ("Menu_Draw": Inventory / Skills / Stats tabs, opened with the menu key) | `scr_menu.gml:1296-1676`; layout `Menu_GetLayout` `:148` | margin 5% of min(w,h), full-screen box, header 10%, tooltip box at bottom | tab titles, rows, tooltip x0.93 | item/skill icon x1, `hp_bar`/`mp_bar` x3 on Stats tab, `dialogue_arrow_down` reused as scroll arrow | no | left/right tabs, down enters list, back leaves (`Menu_HandleInput` `:1041`) | float; rows computed from layout |
| Inventory tab | `scr_menu.gml:1371-1432` | rows of `row_h`, about 6 visible (est.) | "Name xN", "E" at right for equipped | `item.sprite` x1 | no | up/down, confirm = use / equip / unequip | float |
| Equipment | **no screen.** Equip/unequip is a toggle on the inventory row (`Menu_UseInventoryItem` `:908`), result shown as a popup message. Equipped state is a single letter "E". | | | | | | |
| Skills tab | `scr_menu.gml:1433-1483` | same list layout | name only (no MP, no target) | `sk.icon_sprite` (always `noone`) | no | up/down, no action | float |
| Status screen = Stats tab | `scr_menu.gml:1484-1590` | HP/MP bars left, 5 stat rows right | "Level", "Required EXP", "STR: n" | `hp_bar`, `mp_bar` | no | rows selectable only to show a tooltip | float |
| Inventory popups (learn skill / messages) | `scr_menu.gml:1591-1670`; `UI_DrawButton` `scr_player.gml:905` | centred at 62% height | Confirm / Cancel buttons | none | no | left/right, confirm, back | float |
| Class select (+ "Are you sure?") | `ClassSelect_Draw` `scr_menu.gml:1952-2088` | centred, 60% x 50% | class names only | none (no class art or stats) | no | up/down, 120-frame confirm lock | float |
| Save / load menu (3 slots, Delete) | `SaveMenu_Draw` `scr_save_menu.gml:578-812` | centred, 70% x 60% | "Slot 1  Knight Lv5  room_name" | none | no | up/down, left/right to reach Delete | float, but **hard-coded 6/8/14 px paddings** |
| Bed menu (Rest / Back) | `BedMenu_Draw` `scr_save_menu.gml:134-199` | centred, 28% x 18% | 2 rows | none | no | up/down | float |
| Level-up | **no screen.** One line in the combat log: "Level up xN! (+n stat points, auto ...)" built in `scr_enemy.gml:84-94` (hard-coded English, not localized) | | | | | | |
| Shop / currency | **does not exist** (no gold, shop or merchant anywhere in code) | | | | | | |
| Transition fade | `Transition_DrawGUI` `scr_room_transition.gml:623` | full-screen black alpha | | | | | |
| Debug overlay | `obj_sfx_manager/Draw_64.gml` | dev only | | | | | |

## 2. Problems, ranked by visual / usability impact

### P1. Buffs and debuffs mostly show as tiny text, not icons (the owner's complaint, confirmed and worse than reported)
- `Status_DrawIcons` is called with `_noncore_text_fallback = true` in both places (`obj_ui_controller/Draw_64.gml:73`, `obj_battle_controller/Draw_64.gml:196`). `Status_UsesCoreIconSprite` (`scr_status.gml:524`) only accepts the 4 original badges. **The other 10 statuses never draw their sprite.** They draw a text tag like "Guard+" or "Sundered-" at `UI_STATUS_FALLBACK_TEXT_SCALE` 0.45 times the text scale, about 0.54x at 3x windowed (est.), with a 1-px black shadow (`scr_status.gml:556`). That is roughly 6-7 px text, hard to read.
- Even if the sprite were drawn, the placeholders are wrong. Six buffs point at the last frame of a 48x48 skill animation sheet. Three statuses borrow another status's badge (Solidify = Stun, Bloodthirsty = Bleed, Blessing = Burn). Sunder has no icon at all. Full table in `icons-needed.md`.
- No turns-remaining number and no status description is shown anywhere in battle. `Status_Description` (`scr_status.gml:319`) is only used inside skill tooltips.
- Fix size: 10 new 16x16 icons, switch the flag to `false`, add a turn counter. Small and high impact.

### P2. Mixed pixel grids: text, icons, bars and world all use different scales
- World = S px per art pixel (3x). HP/MP bars = 3x. **Icons = 1x** (16 GUI px, about 5 world pixels wide at S=3; `UI_GetSpriteScale` is 1 for every windowed size). Text = 1.2x to 2.0x float. Tooltip text = 0.93 times that. A 1-px panel outline is one third of a world pixel.
- Result: icons look tiny next to text and bars; the pixel font is resampled at non-integer sizes (uneven stroke widths); panel borders look like a thin vector line over chunky pixel art. This is the main reason the whole UI reads as "wrong" next to the art.
- Icons get relatively smaller as the window gets bigger (still 16 px at 3x, 4x and 5x windowed).
- Fix direction: one integer "UI pixel" equal to S; draw sprites, borders and a bitmap font at multiples of it. Or draw all UI at 160x144 into a surface and upscale. Either touches every screen, so do it once, centrally.

### P3. Off-palette, flat panels
- Pure white/black rectangles on art that uses only `#071821 #306850 #86c06c #e0f8cf`. No panel art, no corner pieces, no 9-slice, no shadow, no cursor sprite (selection is a `>` character in battle and a white bar elsewhere).
- Two inverted looks: battle menus are white boxes with black text (`Draw_64.gml:401-404`); every other panel is a black box with white text. The battle command box does not match the inventory.
- `dialogue_arrow_down` is pure `#ffffff`. The battle background `battle_screen` is a flat `#0a2533` fill (also not in the palette).
- Fix: one shared `UI_DrawPanel()` plus one 9-slice sprite in palette colours, used from all screens above. Then switch text from `c_white`/`c_black` to palette colours.

### P4. Inventory is a single flat list with no context
- Inventory branch of `Menu_Draw` (`scr_menu.gml:1371`): one column, all item types mixed (weapons for all three classes, potions, skillbooks). No categories, no sorting, no "equipped" section. The player sees gear their class cannot equip with nothing marking it.
- Equipped = a single letter "E" at the far right (`:1409`). No equipment panel, no slots view, no stat comparison before equipping.
- About 6 visible rows at 3x (est., from `Menu_GetLayout`), 36 item types exist, and holding a key does not scroll. The scroll cue is the small white triangle `dialogue_arrow_down` reused.
- Potion tiers share one sprite each (`hp_potion`, `mp_potion`); all 14 skillbooks share `skill_book`; the list shows runs of identical icons.
- Confirm on a potion uses it at once (no target or confirm step); confirm on gear toggles equip with a popup "Equipped X." There is no use / equip / drop action menu.
- Playtest note says skillbooks "appear twice"; `Menu_InventoryDisplayItems` (`:863`) now dedupes them in the menu. Not checked in play.

### P5. Skills have no icons at all
- Every skill in `SkillDB` (27 entries, 14 of them player skills) has `icon_sprite: noone` (`scr_db_skill.gml`). The row code reserves an icon slot (`scr_menu.gml:1458`, `Draw_64.gml:452`) but nothing ever fills it. Skill menus are text only. The skill FX sheets (48x48 animations) are what the status code borrowed as "icons".
- Skill rows in the character menu show the name only: no MP cost, no target. Battle rows show MP, but unaffordable skills are not greyed (no affordability check in the draw code, `Draw_64.gml:442-458`).

### P6. Battle screen layout
- No message box. All messages are right-aligned lines at the top-right (`Draw_64.gml:115`), over a flat colour, no panel, 6 lines max.
- The enemy has no name, no HP bar and no HP number on screen (HP is only in the debug overlay). The player HUD shows HP/MP only: no level, name or EXP.
- Battle lists (skill/item) show 4 rows and wrap, with no scroll arrows; the character-menu list has arrows, the battle list does not.
- The tooltip is hidden when there is no room above the list (`Draw_64.gml:528-535`).
- The command menu is a narrow white box in the bottom-right corner; skill and item lists replace it with a full-width white box.

### P7. Duplicate, hard-coded layout code
- Each popup rebuilds its own box and buttons: pause, bed, class select, save, settings, difficulty, inventory popup. Only the character menu, class select and inventory popups use `UI_DrawButton`. The save menu draws its own buttons with fixed 8/14 px paddings (`scr_save_menu.gml`, confirm block, line 738) that do not scale.
- Constants like `pad_x = 6`, `pad_y = 4`, `list_top_inset = 18`, `tip_gap = 3` are scattered; each screen picks its own percentages (28%, 35%, 60%, 62%, 70%).
- A shared panel + list-row + button module would remove most of this and make a restyle a single change. This is the architecture step for any UI redo.

### P8. Missing screens / information
- Level-up: just a log line in hard-coded English, and it still mentions "stat points" although the Stats tab is read-only ("growth is class-driven", `scr_menu.gml:1554`). Probably stale text (not checked in play).
- The Stats tab has no class name, no equipment bonuses, no passives and no active statuses.
- Pause menu has Resume / Settings / Exit only (no Save, no Inventory shortcut). Saving happens only at beds.
- Class select shows names only: no class art, no starting stats, no skill preview, for a choice the player cannot easily undo.
- Settings: volumes are text ("70%"), no slider or bar.

### P9. Input
- No hold-repeat anywhere (`scr_input.gml:385-396`), no mouse, no page jump in lists. Keyboard and gamepad both work through the same bindings.
- Focus model is consistent (header focus, list focus, popup block-frame). Not a priority; do not rewrite it.

### P10. Smaller items
- The QTE arrow is 4 `draw_line` calls (`scr_combat.gml:1422-1425`): thin, vector, off-style. Needs a pixel arrow sprite.
- The Korean runtime font is 11 px NanumGothic (`scr_player.gml:836`), unrelated to the pixel look when Korean is on.
- `spr_blue`, `spr_red`, `spr_yellow` are flat translucent fills (wall and grave markers), not UI. `leather_suit`, `iron_suit`, `platinum_suit` are sprites with no reference in code.
- Hard-coded English outside localization: "Game saved." (`obj_game_controller/Step_0.gml:70`), level-up text (`scr_enemy.gml:84`), `Equip_CanEquip` messages (`scr_equip.gml`). `lint_hardcoded_text.py` should flag them.

## 3. What is fine (keep)
- Layout is computed from GUI size, so it holds across window scales. Modal dim, fade and focus handling are consistent. Do not throw this away.
- Tooltip text assembly (`Tooltip_Build*`) is shared between the character menu and battle, and localized.
- Title art, item art and skill FX art are palette-consistent. The weak parts are the frames and the icon coverage, not the art direction.

## 4. Suggested order of work (for planning, not done)
1. Status icons (10 new + draw them + turn counter): P1. Smallest and most visible.
2. Skill icons (14 player skills) and potion/skillbook variants: P5, P4.
3. One shared `UI_Panel` / 9-slice + palette colours + integer UI pixel: P2, P3, P7. Then move screens onto it one at a time (battle menus, then character menu, then popups).
4. Inventory rework: categories, equipped section, compare, hold-repeat: P4, P9.
5. Battle HUD: log panel, enemy name/HP, scroll cues, grey out unaffordable skills: P6.
6. Level-up and status screens: P8.

Each item needs a written acceptance checklist first (AGENTS.md Rule 1, "UI" row). New sprites must be created in the GameMaker IDE (Rule 4); code that sets `icon_sprite` afterwards is plain `.gml`.
