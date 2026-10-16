# Retro RPG UI / inventory / status design for a 160x144, 4-shade, turn-based GameMaker RPG

Researched 2026-10-13. Read-only: nothing in the game repo was changed.

Evidence labels: **[local]** read in this repo today. **[source]** read on the linked page (see Sources).
**[known]** my background knowledge, not re-checked today. **[inferred]** my reasoning, untested.
Verify [known]/[inferred] items before committing work to them. Search tools returned very little rigorous
UI analysis of the classic games, so the per-game notes are mostly [known]; I say where a source backs a point.

---

## 0. What the game has today (local findings)

- **Screen 160x144** (Game Boy), palette `#071821 #306850 #86C06C #E0F8CF`. Contrast ratios I computed from those four colours **[inferred, maths]**:
  darkest/lightest **15.9:1**, darkest/light 8.4:1, dark/lightest 5.7:1, dark/light 3.0:1, darkest/dark 2.8:1, **light/lightest only 1.9:1**.
  => text must be darkest-on-lightest or lightest-on-darkest (optionally dark-on-lightest); **never light-green on lightest or dark on darkest**. Icons need the 1-px darkest outline to read on a light-green field.
- **UI is drawn in Draw GUI with plain `draw_rectangle` boxes** (35 rectangle calls in `scr_menu.gml`, 7 in the battle HUD, 2 in the field HUD): **no 9-slice frame art, no window sprites** **[local]**.
- `scr_menu.gml` is ~2,780 lines; it already has **tabs, a top menu box and a bottom tooltip box** (`tooltip_h`, `menu.tooltip.*` localization keys: target, class restrictions) **[local]**.
- **Battle states**: message, menu, player attack, run, enemy act, skill menu, item menu, attack timing QTE, enemy-defence QTE **[local]**; actions Attack / Skill / Item / Run (Dragon Quest-style command list).
- **Status icons**: `Status_DrawIcons` draws 16x16 icon sprites, otherwise a **tiny text label at scale 0.45**; **no remaining-turns counter is drawn** (turns are tracked in `Status_Add`/tick but not shown) **[local]**. Of 14 statuses only poison/bleed/burn/stun have real icons; the rest borrow unrelated sprites (rock, torch, grass, skull, mp potion, a 48x48 effect frame for **Foresight**) **[local]**.
- **Skills have no description field** (28 skills; `icon_sprite: noone` on every one; no `desc` in `scr_db_skill.gml`) **[local]**. Foresight = `mp_cost 3`, self, status `HIT_UP`, `status_turns 3`, `always_hit` + `consume_on_attack` **[local]**: i.e. "your next attack cannot miss; lasts 3 turns or until you attack". Nothing in the UI says this.
- **Fonts**: `retro_gaming` (UI_FONT), plus `monogram` and `early_gameboy` (old variants) in `fonts\`; **localization is English + Korean**, with `NanumGothic-Regular.ttf` and `NotoSansCJKkr-Regular.otf` in datafiles as the Korean fonts (smooth vector fonts, not pixel fonts) **[local]**. UI text scales via `UI_TEXT_SCALE_BASE 2.0` and `UI_GetSpriteScale()` (GUI-space scaling), so on-screen text density is not simply "8 px per tile" **[local, not fully traced]**.
- **Input**: keyboard (WASD/arrows, Space confirm, Esc cancel, I/Tab menu) **and gamepad** (d-pad, left stick, face buttons) exist in `scr_input.gml`; **no touch code** (`virtual_key`, `device_mouse` not found) **[local]**. The project has an `options\` folder for per-platform builds including Android **[local]**, and the earlier `resolution-gamemaker.md` targets Windows + Android.

---

## 1. Recommendations in one list

1. **Always show duration on a status icon** (a 3x5-pixel digit in the icon's corner) and make the **last turn blink**. This is the biggest missing piece (section 3).
2. **Add a one-line `desc` to every skill, item and status**, written with a fixed template (verb first, numbers, duration, trigger), and show it in the existing bottom tooltip box when the cursor is on the entry. Add a keyword **glossary** page reachable from the battle menu (section 4).
3. **Use shape, not colour, to separate buffs from debuffs** (the palette has only 4 greens): arrow glyph up/down, frame shape, and position (buffs above the bar, debuffs below).
4. **Replace `draw_rectangle` boxes with one 9-slice window sprite** (24x24, 8-px margins) used by every panel; integer positions only (section 5).
5. **Switch the UI text to a real pixel font at its native size, anti-aliasing off**, with a pixel font that has Hangul: **Galmuri7/9/11 (OFL-1.1)** is the best fit I found (section 6).
6. **Keep menus shallow, remember the cursor per menu, and make Back unambiguous**; add an "Info" button (gamepad/keyboard) that does what hover does on PC (section 7).
7. **Touch (Android): design rows >= 16 base px tall and use tap-to-select, tap-again-to-confirm**; there is no hover on touch, so every description must be reachable by an explicit Info action.
8. **Stay with Draw GUI + a tiny widget layer** for now; evaluate GameMaker UI Layers / Flex Panels with a spike for the HUD only (section 8). Do not hand-edit `.yy`/room files (AGENTS Rule 4).

---

## 2. What the reference games teach (and what to steal)

| Game | What to look at | Lesson for a 160x144 game |
|---|---|---|
| **Dragon Quest (NES)** | The windowed command menu, born to fit an 8-button controller and to show every action at once for discoverability **[source: dragon-quest.org, Critical Video Game Studies via search]**. Cascading windows on the map screen; some players dislike the nesting **[source: RPGamer editorial via search]**. Attack/Spell/Item/Run list in one box, white-on-black framed windows, ">" cursor. | Your Attack/Skill/Item/Run box is already the right idea. Keep it **single-column, 4 rows, all visible**; put the *description* in a fixed second window, not another cascade. |
| **Final Fantasy 1-6** | FF1-3: command window + party HP list; FF4-6: ATB gauges, a command window per character that opens as that character becomes ready, party list with HP/MP numbers, hand cursor. Skill/magic menus show **MP cost on the same row** and a **one-line description in a bar at the top/bottom** **[known]**. | Show **MP cost on the row** and the description in a persistent bar. Status is shown as small text/face changes next to the HP row. A dev who studied FF7-9 and rejected old-style deep submenus as too slow for pacing is anecdotal support for shallow menus **[source, anecdote]**. |
| **Chrono Trigger** | Command window + a **description bar** that updates as you move the cursor (techs/items); "double/triple tech" names appear in the list only when available **[known]**. | A **cursor-synced description line** beats a separate "inspect" screen. Greyed-out/locked entries should say *why* (not enough MP, wrong class). Your tooltip already has class restriction text. |
| **EarthBound** | The famous **rolling HP meter** (HP counts down like an odometer, giving time to heal) and Goods/PSI/Equip windows. Navigation was criticised as tedious, esp. shopping needing item -> character -> dialogue for each purchase **[source: RPGamer review via search]**. | The odometer idea is a cheap, great "game feel" win for a turn-based game. Avoid chaining 3 confirmations for a repeated action. |
| **Pokemon Red/Blue (Game Boy, same 160x144)** | Everything snaps to the **20x18 grid of 8x8 tiles**; enemy info top-left, player info bottom-right, a full-width bottom box doubles as message box and action menu; the option window was widened by one tile so "FIGHT" fits **[source: TCRF via search; layout [known]]**. Move menu: move names in the bottom window with type/PP window above it **[source: TCRF]**. | The best direct template for your screen: **a bottom command/message box and two compact info boxes**, laid out on an 8-px grid. Design every box in whole tiles. |
| **Octopath Traveler** | Persistent **turn-order strip**; highlighting an enemy highlights it in the strip; shield points + weakness squares under each enemy; defending visibly moves you up the order **[source: Vulkk guide, GamerGuides via search]**. Hidden weaknesses show as "?" until learned **[source]**. | Players love seeing **when** threats act. For this game: show "enemy acts next / after you" and show enemy status icons with counters. Use "?" placeholders for unknown info instead of blank space. |
| **Sea of Stars** | Enemy special attacks show a **bar of locks with damage-type icons**; breaking locks weakens or cancels the move **[source: PlayStation Blog via search]**. Combat is turn-based with no time bars **[source]**. | A clear model for a **telegraphed enemy action indicator** over the enemy. You have QTEs (`ATTACK_TIMING`, `ENEMY_DEF_QTE`): reuse the same icon language to announce what the QTE is. |
| **Darkest Dungeon** | Status "tokens" and DoT icons; **durations shown in tooltips; hold Ctrl to open a glossary of every token; Escape menu has a "Token Glossary"** **[source: Steam threads, patch-note mirror via search; community posts, not official docs]**. Players say icons are great at a glance but some are opaque until hovered, and a glossary missing some icons caused confusion **[source: same threads]**. | The **keyword glossary** is exactly what "Foresight" needs. Cover **every** status (the DD complaint was incomplete glossaries). On gamepad/keyboard bind it to a button, not to hover. |
| **Shiren the Wanderer** | Inventory split into pages of 8; sorting costs no turn, equipping costs a turn; items grouped in a fixed category order (weapons, shields, armbands, projectiles, food, herbs, scrolls, staves, jars) **[source: Mystery Dungeon wiki via search]**. | Fixed-size inventory pages and a **stable category order** keep a tiny screen predictable; make "free actions" (sort/inspect) clearly free and "turn-costing" actions clearly costed. (I found nothing on Shiren's status-icon art or description layout.) |
| **Persona 5** (not asked, but sourced) | Colour-matched menu buttons to controller buttons; hovered item gets bigger and coloured **[source: Mechanics of Magic via search]**. | Cursor feedback should be unmistakable: with only 4 shades, use **invert (lightest-on-darkest) + a cursor glyph**, not colour. |

General lesson from sourced commentary: keep frequent actions shallow, keep the cursor predictable (leaving a submenu should not reset the list to the top), and make "back" distinct from "exit" **[source: Game Developer article on console RPG menus, via fetch]**.

---

## 3. Status icons with turn counters (design spec)

Design it so a player can read the state of the fight in one glance **without any tooltip** (tooltips supplement; critical info must not live only in a tooltip **[source: general tooltip guidance via search]**).

- **Counter**: a 3x5 px digit drawn in the icon's bottom-right (lightest digit with a darkest outline, or darkest on a lightest pill), values 1-9; `9+` shown as `9`. Tick the digit down at the same moment the rules tick `turns`. **Blink (2-frame, ~0.25 s) when 1 turn remains**; **pop (1 px shake) when it changes**. Consume-on-use statuses (Foresight "until you attack") show the digit **and** a small "!" or dot instead of turns when the counter is not the limiting rule **[inferred]**.
- **Buff vs debuff without colour**: every glyph carries a **tiny arrow in the top-right corner**, up = buff, down = debuff, none = neutral/state (e.g. Stun); frame shape also differs (square-cornered frame for buffs, round badge for debuffs) **[inferred]**. Your existing four debuff icons are already round badges; build buffs as square-cornered 16x16 so the families differ in silhouette.
- **Where**: buffs on the row above the HP bar, debuffs below, **max 4 per combatant, then a "+N"**; sorted newest-first or by importance **[inferred]**. At 160 px wide a 16-px icon is 10% of the screen width, so a combatant can realistically show 4 icons; if you need more, add an 8x8 compact variant for the HUD and use 16x16 only in menus (doubles art cost: decide with the owner).
- **Inspect**: pressing an "Info" button in battle opens a one-line inspect bar cycling through the active statuses of the highlighted combatant: `[icon] Name  N turns` / description. On touch: tap the icon.
- **Stacking/refresh rules** should be stated in the description when they surprise the player (code: `Status_Add` keeps the max of old/new turns **[local]**), e.g. "Reapplying refreshes the timer."
- **Consistent glossary words**: one term per concept everywhere (Guard, Evasion, Poison...). Statuses should be named like the icon: Foresight = an eye glyph, Take Aim = a crosshair, Rev Up = a flame/up arrow, Meditation = lotus/MP drop, Guard = shield.
- Art for the ~10 missing icons: see `icons-comfyui.md` (AI sketch, then hand-finish at 16x16).

---

## 4. Descriptions and tooltips that teach ("Foresight")

**Where to show them** (priority order): (1) the existing bottom **tooltip box** while the cursor is on a skill/item row (no input needed, works on keyboard and gamepad); (2) an **Info button** for statuses and keywords; (3) a **Glossary** page (menu + battle pause) listing every status with icon and rule text; (4) hover/long-press only as a convenience on desktop/touch **[inferred, supported by DD community posts and generic tooltip guidance]**.

**Template (fixed order, <= ~2 lines at the real font width):**
`<Effect on whom, with numbers>. <Duration/trigger>. <Cost/limit if not obvious>.`

Examples written against the actual data **[local]**:
- **Foresight** (3 MP): `Your next attack never misses. Lasts 3 turns or until you attack.`
- Poison: `Lose HP every turn. Ends after N turns.`
- Guard (status): `Take less damage for N turns.` (use the real number from the status config)
- A skillbook item: `Teaches Foresight to Mages.` (class restriction text already exists)

Rules: start with the verb the player cares about; **quantify** (percent, flat, turns); say **when it triggers** (turn start / on hit / on your next attack) and **what ends it**; underline or invert **keywords** that have glossary entries (Poison, Stun, Guard...) so the glossary teaches the system once; keep every line short. General guidance found: tooltips under ~15 words / ~150 characters, add a short delay, provide tap/long-press on touch, and do not put critical information only in a tooltip **[source: UXPin/Userlytics/uxcel via search]**.

**Fit check (needs measuring before writing copy)** **[inferred]**: with a ~6-px-wide Latin font about 24-26 characters fit in 160 px; with an 8-px Hangul font about 20 characters (or ~18 inside a framed box). So a description must fit **2-3 lines of ~18-24 characters** or scroll/page. Korean text is usually shorter than English, but pixel Hangul needs >= 8-px glyphs. Write the strings through `game_text.xlsx -> build_localization.py` (never hand-edit `localization.json`; run `lint_hardcoded_text.py`) per CLAUDE.md **[local]**. Add `desc_key` fields to `skill_db`/`status_db`/`item_db`.

---

## 5. Windows and frames: 9-slice at pixel scale

- **Look**: Game Boy RPGs use a 1-px darkest outline with a 1-px light inner line ("double border") and rounded or notched corners, on a flat lightest fill. One frame sprite, **24x24 px with 8-px margins** (corners 8x8, edges 8x8, centre 8x8) covers dialogue, menu, tooltip and info boxes; a second 16x16 variant (4-px margins) for small badges/pills; one **selection row** sprite (inverted, 1-px notch for the cursor) **[inferred]**.
- **GameMaker**: enable **Nine Slice** in the Sprite Editor (four guides; per-slice mode Stretch, Repeat, Mirror; must be switched on). Once on, the sprite scales as nine-slice in objects, sequences, asset layers and **`draw_sprite_ext()`** **[source: manual Nine Slice]**. It does **not** work with `draw_sprite_part()` or `draw_sprite_pos()` **[source]**. Runtime control via `sprite_nineslice_create`, `sprite_get_nineslice`, `sprite_set_nineslice` **[source]**. Official tutorial: [How to use 9-slice in GameMaker](https://gamemaker.io/en/blog/slick-interfaces-with-9-slice).
- Pixel-perfect rules **[inferred/known]**: use **Repeat** on edges (no stretching of pattern pixels); draw at **integer coordinates** and an **integer scale** (match the integer-scaled GUI rectangle described in `resolution-gamemaker.md`); make panel sizes multiples of 8 so the pattern never ends mid-tile; keep texture filtering off. Creating the sprite resource is an IDE action (AGENTS Rule 4: do not hand-edit `.yy`).
- Replace the 35+ `draw_rectangle` calls in `scr_menu.gml` through **one helper** (e.g. `UI_DrawWindow(x,y,w,h)`) so the look changes in one place.

---

## 6. Fonts at pixel scale

- **Rules** **[known]**: use a pixel font only at its native pixel height or integer multiples; **anti-aliasing off**; size the GameMaker font resource to the font's pixel em (e.g. 8 for an 8-px font) rather than a point size that "looks right"; never non-integer text scale (the game's `UI_STATUS_FALLBACK_TEXT_SCALE 0.45` for labels is exactly the kind of fractional scaling that smears text; replace labels with icons, or a native 5-px font). Bitmap fonts via `font_add_sprite_ext` are the crispest route in GameMaker **[known]**.
- **Korean is the constraint.** Candidates (all re-checked on their pages unless noted):

| Font | Pixel sizes | Hangul | Latin | Licence | Notes |
|---|---|---|---|---|---|
| **Galmuri** (quiple) | Galmuri7 = 8 px, Galmuri9 = 10 px, Galmuri11 = 12 px (+ Bold/Condensed), Galmuri14 = 15 px | **Yes** (Galmuri7 has 4,358 syllables; 9/11/14 have 2,355) | Yes (Latin-1 stated only in legal notes) | **OFL-1.1** | Best fit: real pixel font, 8 px option matches the 8x8 tile grid. **[source]** |
| **Fusion Pixel Font** (TakWolf) | 8, 10, 12 px; proportional and monospaced | Yes, a `ko` build using Galmuri glyphs ("patch-based") | Yes (`latin` build; 10/12 px from Ark Pixel) | **OFL-1.1** (build tools MIT) | Good Latin+CJK in one font; proportional recommended; Korean glyph quality "may not meet high expectations" per its README **[source]** |
| **Neo Dunggeunmo** (neodgm) | ~16 px grid **[known]** | Yes | Yes | **OFL-1.1** | Large for 160 px; fine for titles **[source for licence]** |
| **MaruMinya Hangul** | 12 px base | Yes | - | **OFL** (embedding in games OK per its page) | Squarish 12 px style **[source]** |
| **Monogram** (datagoblin) | 5 px wide fixed | No (Latin, Spanish, Russian, Portuguese, Greek...) | Yes | **CC0** | Already in `fonts\`; excellent for EN numerals/labels **[source]** |
| **m5x7** (Daniel Linssen) | 5x7 | No | Yes | **CC0** per its itch page (m6x11's terms differ/unclear: check) | **[source]** |
| **Press Start 2P** | 8 px | No | Yes | **OFL-1.1** (reserved font name) | Wide; ~20 chars/line at 160 px **[source for licence]** |
| **Silkscreen** | ~8 px | No | Yes (caps style) | **OFL-1.1** from Google Fonts (older standalone licence text differs) | Good for headings; poor for sentences **[source]** |

- **Recommendation**: **Galmuri7 (8 px) for body text and Galmuri9 (10 px) for headings**, covering EN and KO in one family; keep Monogram only if you want a tighter English-only numeric font (e.g. counters, damage numbers). Drop the smooth `NanumGothic`/`NotoSansCJKkr` fallbacks for in-game UI: scaled vector Hangul will blur at 160x144 **[inferred]**. Test **every** UI string at 1x on the integer-scaled game rectangle on the real Android target.
- Legibility: with the contrast numbers in section 0, use **lightest-on-darkest for windows over the map** and **darkest-on-lightest for paper-style info boxes**; add a 1-px darkest drop-shadow/outline for text over busy backgrounds; keep line spacing >= font height + 2.

---

## 7. Navigation: keyboard, gamepad, touch

- **Rules (sourced)**: leaving a submenu must **not** snap the cursor to the top entry; make **Back** (previous menu) and **Exit** (leave the whole menu) distinct buttons **[source: Game Developer, console RPG menus]**. Keep frequent actions shallow (potion in battle: Item -> pick -> confirm, 3 presses max) **[source]**.
- **Additional rules** **[known/inferred]**: cursor memory **per menu** (battle command cursor remembers Attack/Skill/Item between turns); wrap-around on lists; hold-to-repeat with ~0.25 s delay then ~0.08 s repeat; skipped when disabled but never silently, grey with a reason; page indicators for lists > rows; a consistent button map: **Confirm / Cancel / Info / Menu** (A / B / Y / Start on pad; Space / Esc / a new key such as Q or Tab-alternative / I on keyboard). Your current bindings have no Info action: add `menu_info`.
- **Gamepad**: already read in `scr_input.gml`; on-screen button hints in the tooltip bar (e.g. `A Use  B Back  Y Info`) change by device. Persona 5's button-coloured prompts are a good model **[source]**; here use glyph shapes (A/B/Y) in the 4-shade palette.
- **Touch (Android)**: no touch code exists **[local]**. Rules of thumb **[known + my arithmetic]**: Material guidance is a ~48 dp (~9 mm) minimum touch target; at 160 px base width on a 1080-px-wide phone the integer scale is 6, so a 16-px row = 96 device px, roughly 6 mm on a ~400 ppi phone, **below** the guideline; an 8-px row (3 mm) is unusable. Therefore: **list rows >= 16 base px** with **hit boxes taller than the visible row** (include the gap), **tap = select + show description, second tap (or a big on-screen A button) = confirm**, **drag/scroll or L/R arrows for pages**, an on-screen **Back** and **Info** button in a fixed corner, and `device_mouse_x_to_gui` hit-testing against the integer-scaled GUI rectangle (see `resolution-gamemaker.md` section 1.2). For free movement use GameMaker virtual keys/d-pad. Nothing on hover.
- **Accessibility minimums** **[inferred]**: never rely on colour alone (4-shade palette makes this mandatory), keep text >= 8 px, allow a "text speed" and "auto-advance off" option (you already have dialogue constants), and make all information obtainable without timing pressure outside the QTEs.

---

## 8. GameMaker approaches

| Approach | What it is | Fit here |
|---|---|---|
| **Draw GUI + own widgets** (current) | Immediate-mode drawing in `Draw_64`; full control; already working (2.7k lines in `scr_menu.gml`). | **Keep.** Extract a small helper layer: `UI_DrawWindow` (9-slice), `UI_List` (rows, cursor memory, paging, hit boxes), `UI_StatusRow` (icon + counter), `UI_TooltipBar`. Easy to unit-check with an assertion block, and it works the same on keyboard, pad and touch. |
| **9-slice sprites** | See section 5. | **Adopt now**; lowest risk, biggest visual win. |
| **UI Layers + Flex Panels** (2024.13+; project IDE is 2024.14.3) | A UI layer holds Flex Panels (sizing in px / % / auto, margin/padding) containing sprites, objects, text; drawn on top of the game, shown on the main display or in viewports; all UI layers live in one global UI Folder and appear in every room; show/hide with `layer_set_visible`; panel props at runtime via `layer_get_flexpanel_node` **[source: manual UI Layers + 2024.13 release post]**. The manual page I read **does not describe focus, button widgets, gamepad navigation or runtime resolution scaling** and says the canvas size preview "does not affect how UI layers appear in-game" **[source]**. | **Spike only, HUD only** (e.g. the battle status rows), after confirming how it composes with your integer-scaled `application_surface` pipeline. Keep menus on Draw GUI because you need custom focus/cursor logic. Room/layer files are IDE-owned (AGENTS Rule 4), so any UI-layer work is an IDE session, not a hand edit. **[inferred]** |
| Sequences / animation curves | For cursor bob, window open/close tweens, counter pop. | Small helper only; see the `game-feel` skill. |

Acceptance for any UI change in this repo is a **written checklist walked through in the IDE** (CLAUDE.md), not an automated test **[local]**.

---

## 9. Asset packs and licences (permissive only)

| Asset | Licence | Use |
|---|---|---|
| **Kenney "Pixel UI Pack"** | **CC0**, 750 files **[source: kenney.nl page]** | Panels/buttons/arrows as *reference* or to recolour to 4 shades; check tile size before relying on it (not stated on the page I read). |
| Kenney "UI Pack" | CC0 (430 assets per a third-party guide, **unverified**) | Not pixel-art-consistent at 16 px; reference only. |
| **Tiny RPG Mana Soul GUI** (OpenGameArt) | Listed **CC0**, 10 buttons with states **[source: listing via search]** | Recolour candidate. |
| **Super Gameboy Quest UI Pack** (Toadzilla) | Commercial use OK **with credit** ("Toadzilla" + link) **[source: itch listing]** | Closest style match (2-bit GB palette, inventory/HUD/quest elements, key + controller glyphs); credit line required. |
| NightByte "Gameboy Green Icons & UI Elements" (1400+ items), Aetherstring GB-style pixel UI | **Licence not stated** in what I saw **[source: itch listings]** | Do not use until the licence text is read. |
| game-icons.net | CC BY 3.0 **[known]** | Vector, not pixel; reference only. |
| Fonts | See section 6 (OFL-1.1 / CC0) | Keep each font's licence file with the project. |

Practical advice: a 24x24 frame, a 16x16 cursor/arrow set, a selection bar and ~10 UI glyphs is **less than one hour of pixel work** and matches your icons perfectly; use packs for ideas and recolour only CC0 ones. Keep a `docs/credits` file from day one.

---

## 10. Proposed 160x144 battle layout (starting point, all in 8-px tiles) **[inferred]**

```
 0         8        16       ...                         160
 +--------------------------------------------------------+  row 0
 |  ENEMY name          [buff icons]                     |  tiles 0-2: enemy info (HP bar, 2-4 status icons + counters)
 |  HP ====      [debuff icons]                           |
 |                     (enemy sprite 32x32 / 48x48)       |  rows 3-9: battlefield
 |                                         (player 16x16) |
 |  PLAYER  HP 20/24 MP 6/8   [status icons + counters]   |  rows 10-12: player info box (9-slice)
 +--------------------------------------------------------+
 | > Attack     [description / message bar, 2-3 lines]    |  rows 13-17: command box (left, 4 rows) + message/description box (right)
 |   Skill                                                |
 |   Item                                                 |
 |   Run         A OK  B Back  Y Info                     |
 +--------------------------------------------------------+
```
Notes: command list on the left (about 7 tiles wide), description/message to the right (about 13 tiles); Skill menu replaces the message box with a 2-column list while the description line stays at the bottom; MP cost right-aligned on each row; the active combatant is marked with the cursor glyph; one "next to act" marker on whichever side acts after the player.

---

## 11. Suggested order of work (for the planner)

1. Decide with the owner: **icon size stays 16x16?**, **Korean pixel font priority?**, **Android touch in scope for the first release?**, **one 16x16 icon set or add 8x8 compact?** (these change the specs above).
2. Spike: 9-slice window sprite + `UI_DrawWindow`, and a font swap to Galmuri at native size on one screen; compare 1x screenshots (test on Windows and an Android build).
3. Add the status counter (digit + last-turn blink) using existing icons; then add the 10 missing icons.
4. Add `desc_key` to skills/statuses/items, show in the tooltip bar, then the glossary page and `menu_info` binding.
5. Touch pass (hit boxes, tap-select/tap-confirm), then evaluate UI Layers for the HUD.

---

## Sources
- [Dragon Quest command menu (Dragon Quest Wiki)](https://dragon-quest.org/wiki/Command_menu)
- [RPGamer, EarthBound review (navigation friction)](https://archive.rpgamer.com/games/other/snes/eb/reviews/ebrdrev2.html)
- [Game Developer: on menus in console RPGs](https://www.gamedeveloper.com/design/koa-reckoning---on-menus-in-console-rpgs)
- [TCRF: Pokemon Red/Blue version differences (battle menu layout)](https://new.tcrf.net/Pok%C3%A9mon_Red_and_Blue/Version_Differences)
- [Octopath Traveler II combat guide (Vulkk)](https://vulkk.com/2023/02/24/how-combat-works-in-octopath-traveler-2-beginners-guide/) and [Octopath battle system (GamerGuides)](https://gamerguides.com/octopath/guide/the-basics/game-mechanics/battle-system)
- [PlayStation Blog: Sea of Stars combat](https://blog.playstation.com/?p=366730)
- [Darkest Dungeon II token glossary thread (Steam)](https://steamcommunity.com/app/1940340/discussions/0/3838801285234272157) and [Darkest Dungeon changelog mirror](https://steamcommunity.com/sharedfiles/filedetails/changelog/2600273722?p=4)
- [Persona 5 visual design (Mechanics of Magic)](https://mechanicsofmagic.com/2022/04/23/visual-design-of-games-persona-5/)
- [Shiren Moonlight Village inventory (Mystery Dungeon Wiki)](https://mysterydungeonwiki.com/wiki/Moonlight_Village_SP:Inventory)
- [UXPin: tooltip best practices](https://www.uxpin.com/studio/?p=49509) and [itch.io thread on status-effect explanations](https://itch.io/post/7265001)
- [Game Boy tile maps (Pan Docs)](https://gbdev.io/pandocs/Tile_Maps)
- [GameMaker manual: Nine Slice](https://manual.gamemaker.io/lts/en/The_Asset_Editors/Sprite_Properties/Nine_Slices.htm) and [Nine Slice functions](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Asset_Management/Sprites/Nine_Slice_Functions.htm)
- [GameMaker blog: How to use 9-slice](https://gamemaker.io/en/blog/slick-interfaces-with-9-slice)
- [GameMaker manual: UI Layers](https://manual.gamemaker.io/lts/en/The_Asset_Editors/Room_Properties/UI_Layers.htm) and [2024.13 release: UI Layers, Prefab Library, SVG](https://gamemaker.io/en/blog/release-2024-13)
- [Galmuri pixel font (OFL-1.1)](https://github.com/quiple/galmuri)
- [Fusion Pixel Font (OFL-1.1)](https://github.com/TakWolf/fusion-pixel-font)
- [Neo Dunggeunmo (OFL)](https://github.com/neodgm/neodgm-webfont) and [MaruMinya Hangul](https://www.freekoreanfont.com/maruminya-hangul-download/)
- [Monogram (CC0)](https://datagoblin.itch.io/monogram), [m5x7](https://managore.itch.io/m5x7), [Press Start 2P](https://fontlibrary.org/en/font/press-start-2p), [Silkscreen (Google Fonts repo)](https://github.com/googlefonts/silkscreen)
- [Kenney Pixel UI Pack (CC0)](https://kenney.nl/assets/pixel-ui-pack)
- [Tiny RPG Mana Soul GUI (OpenGameArt)](https://opengameart.org/content/tiny-rpg-mana-soul-gui) and [Super Gameboy Quest UI (Toadzilla)](https://toadzillart.itch.io/ui-pack)
