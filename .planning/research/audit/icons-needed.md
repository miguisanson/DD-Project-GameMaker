# Icons needed

Date: 2026-10-13. Read-only audit. Sprite sizes and frame counts come from each sprite's `.yy`; colours and style from the PNGs. Nothing was run in the game.

## 1. House style the new icons must match

Checked on: `wooden_sword`, `iron_sword`, `hp_potion`, `mp_potion`, `poison_status`, `bleed_status`, `burn_status`, `stun_status`, `skill_book`, `leather_armor`, `bone_asset`, `chest_asset`, the 48x48 FX sheets, `main_menu`.

- **Size:** 16x16 px, 1 frame, transparent background. Every item and status icon is 16x16 (skill FX sheets are 48x48 and are animations, not icons). The UI code assumes 16 wide (`max(16 * scale, sprite width * scale)` in `scr_menu.gml:1400,1461` and `obj_battle_controller/Draw_64.gml:453,490`), so other sizes would break row alignment.
- **Palette (the whole game uses exactly these 4 colours plus transparent):**
  - `#071821` darkest, used as the 1-px outline and deepest shadow
  - `#306850` dark green, shadow / fill
  - `#86c06c` mid green, main fill
  - `#e0f8cf` pale, highlight / glyph
  - Some icons use only 3 of the 4 (`mp_potion`, `stun_status`, `leather_armor`). Never add a 5th colour. (Stray exceptions in the repo: `dialogue_arrow_down` is `#ffffff`, `spr_blue/red/yellow` are flat translucent fills; do not copy those.)
- **Outline:** 1 px `#071821` around the whole silhouette on item icons. No anti-aliasing, no dithering gradients, no soft shadow.
- **Lighting:** light from top-left; highlight `#e0f8cf` on the upper-left edge, `#306850` on the lower-right.
- **Item icons:** object fills most of the 16x16 box (about 12-14 px tall), slightly diagonal for tools/weapons (blade bottom-left to top-right), upright for potions/books.
- **Status icons (the 4 existing ones):** a **round badge that fills the whole 16x16** (about 68 transparent corner pixels), `#071821` ring, `#306850` disc, glyph in `#86c06c` with `#e0f8cf` highlights. All new status icons should be the same badge. Suggested buff/debuff split (design choice, not in code yet): debuffs keep the dark disc; buffs use the same round silhouette with a `#86c06c` disc and a `#071821` glyph, so the player can tell them apart without reading. `Status_IsNegative` (`scr_status.gml:535`) already gives the split.
- **Skill icons:** no existing convention. Recommended: 16x16, no badge, same outline and palette rules as item icons, so they sit comfortably next to item icons in the lists.
- **Naming:** AGENTS.md says follow the sibling assets. Status sprites are `<name>_status`; item sprites are plain names (`hp_potion`); skill art is `<name>_effect`. Suggested names below follow that. The IDE must create the sprites (AGENTS.md Rule 4); code then points `icon_sprite` at them.

## 2. Priority 1 - status icons (10 new)

The 4 core statuses (poison, bleed, burn, stun) already have real badge icons and are fine. Everything below is currently either drawn as a 0.54x text tag (HUD and enemy rows pass `noncore_text_fallback = true`, so these sprites are never drawn) or has no icon. Placeholder source: `scr_status.gml:34-55` (assignment) and `:118-267` (database).

| id (suggested sprite) | status (macro, db line) | meaning | size | suggested motif (round badge) | current placeholder (what the code assigns) | flag |
|---|---|---|---|---|---|---|
| `guard_status` | Guard (`STATUS_GUARD`, `scr_status.gml:162`) | blocks the next hit | 16x16 | buff badge: kite shield | `muscle_up_effect` last frame (48x48 anim, flexing head); db default `rock1` (world prop) | reuses skill FX |
| `rev_up_status` | Rev Up (`STATUS_DMG_UP`, `:173`) | next attack deals x2 | 16x16 | buff badge: flexed arm or fist with an up-arrow / "x2" tick | `rev_up_effect` last frame (48x48 flexed arm); db default `torch_asset_moving` (world prop) | reuses skill FX |
| `evasion_status` | Evasion (`STATUS_EVASION`, `:184`) | dodges next attack | 16x16 | buff badge: boot or feather with two speed lines | `evasion_up_effect` last frame (48x48 hand); db default `tall_grass_asset` | reuses skill FX |
| `take_aim_status` | Take Aim (`STATUS_CRIT_UP`, `:195`) | crit chance +25% | 16x16 | buff badge: crosshair with centre dot | `take_aim_effect` last frame (48x48 crosshair, origin 24,24); db default `skull_2_asset` | reuses skill FX |
| `foresight_status` | Foresight (`STATUS_HIT_UP`, `:205`) | next attack cannot miss | 16x16 | buff badge: open eye with small target tick | `foresight_effect_Sheet` frame 0 (48x48 closed eye, the first frame) | reuses skill FX, and frame 0 is the closed eye |
| `meditation_status` | Meditation (`STATUS_MEDITATION`, `:217`) | recover 2-4 MP per turn | 16x16 | buff badge: lotus / seated silhouette with a small drop or star | `meditation` last frame (48x48 figure); db default `mp_potion` | reuses skill FX, and item art |
| `solidify_status` | Solidify (`STATUS_SOLIDIFY`, `:226`) | dodges next attack (enemy skill) | 16x16 | buff badge: stone block / rock plate with facets | **`stun_status`** (the Stun badge) | reuses another status icon |
| `bloodthirsty_status` | Bloodthirsty (`STATUS_BLOODTHIRSTY`, `:237`) | until hit: take -35%, deal +6% | 16x16 | buff badge: fang with a blood drop | **`bleed_status`** (the Bleed badge) | reuses another status icon |
| `blessing_status` | Blessing (`STATUS_BLESSING`, `:249`) | next hit deals 20% less | 16x16 | buff badge: halo over a small cross/sparkle | **`burn_status`** (the Burn badge) | reuses another status icon |
| `sunder_status` | Sundered (`STATUS_SUNDER`, `:260`) | DEF -1 (applied by weapon passive Sunder Edge) | 16x16 | **debuff** badge: cracked shield / broken armor plate | **none** (`icon_sprite: noone`; no skill applies it, so the skill-FX fallback finds nothing); drawn as text "Sundered-" | none |

Code that must follow (not part of this audit's output): set the flag to `false` in the two `Status_DrawIcons` calls (`obj_ui_controller/Draw_64.gml:73`, `obj_battle_controller/Draw_64.gml:196`) once the 10 icons exist, and simplify `Status_AssignPlayerBuffIconsFromFX` / `Status_AssignMissingIconsFromSkillFX` (`scr_status.gml:40-104`), which exist only to paper over the missing icons.

Existing, OK (no work): `poison_status` (bubbling green blob), `bleed_status` (drop), `burn_status` (flame), `stun_status` (starburst). All 16x16, 1 frame, 4 colours except stun (3).

## 3. Priority 2 - skill icons (14 player skills, `icon_sprite` is `noone` for all)

All 27 skills in `scr_db_skill.gml` have `icon_sprite: noone`. The menus already reserve the icon slot (`scr_menu.gml:1458`, `Draw_64.gml:452`) so nothing needs layout work, only the sprites and an assignment. Skill icons are shown in the character menu Skills tab and the battle skill list. "FX sheet" means the 48x48 animation each skill already has (so there is art to draw from, but it is a different size and animated).

| id (suggested sprite) | skill (macro) | class | MP | size | suggested motif | existing nearby art (not an icon) |
|---|---|---|---|---|---|---|
| `wound_skill` | Wound (`SKILL_WOUND`) | Knight, Archer | 3 | 16x16 | short blade with a blood drop | `bleed_effect` 12 frames |
| `hilt_bash_skill` | Hilt Bash (`SKILL_HILT_BASH`) | Knight | 4 | 16x16 | sword pommel with a small impact star | `stun_effect` 9 frames |
| `muscle_up_skill` | Muscle Up (`SKILL_MUSCLE_UP`) | Knight | 3 | 16x16 | shield + clenched fist (it grants Guard) | `muscle_up_effect` 7 frames |
| `rev_up_skill` | Rev Up (`SKILL_REV_UP`) | Knight | 3 | 16x16 | flexed arm with a "x2" or up-arrow | `rev_up_effect` 10 frames |
| `horizontal_slash_skill` | Horizontal Slash (`SKILL_HORIZ_SLASH`) | Knight | 5 | 16x16 | wide horizontal crescent cut | `horizontal_slash_effect` 5 frames |
| `poison_arrow_skill` | Poison Arrow (`SKILL_POISON_ARROW`) | Archer | 4 | 16x16 | arrow with a dripping green tip | `poison_shot_effect` 12 frames |
| `evasion_skill` | Evasion (`SKILL_EVASION`) | Archer | 3 | 16x16 | boot / feather with speed lines | `evasion_up_effect` 9 frames |
| `double_shot_skill` | Double Shot (`SKILL_DOUBLE_SHOT`) | Archer | 5 | 16x16 | two parallel arrows | `double_shot_effect` 7 frames |
| `take_aim_skill` | Take Aim (`SKILL_TAKE_AIM`) | Archer | 3 | 16x16 | crosshair | `take_aim_effect` 12 frames |
| `fireball_skill` | Fireball (`SKILL_FIREBALL`) | Mage | 4 | 16x16 | round fireball with a tail | `explosion_effect` 9 frames |
| `poison_mist_skill` | Poison Mist (`SKILL_POISON_MIST`) | Mage | 4 | 16x16 | cloud with bubbles | `poison_mist_effect` 8 frames |
| `ice_spear_skill` | Ice Spear (`SKILL_ICE_SPEAR`) | Mage | 5 | 16x16 | diagonal icicle spear | `ice_spear_effect` 12 frames |
| `meditation_skill` | Meditation (`SKILL_MEDITATION`) | Mage | 3 | 16x16 | seated figure / lotus with star | `meditation` 11 frames |
| `foresight_skill` | Foresight (`SKILL_FORESIGHT`) | Mage | 3 | 16x16 | open eye | `foresight_effect_Sheet` 10 frames |

Playtest note (friend, `.planning/research/playtest-notes.md`): "foresight skills idk what it does (bone shud be foresight +)". The skill tooltip is not clear about the effect; an eye icon helps, and the text in `Status_Description(STATUS_HIT_UP)` ("Next attack cannot miss.") should be checked against what the tooltip shows. Not changed here.

Optional, lowest priority (enemy skills never appear in a player menu or log with an icon today; only worth doing if a bestiary/enemy-skill banner is added): `poison_fangs`, `solidify`, `bite`, `bloodthirsty`, `vine_trap`, `scorching_touch`, `ghost_cut` ("Cut"), `steal`, `ramming`, `rampage`, `curse`, `blessing`, `final_fury` ("Fury"). All 16x16. Two of them can reuse the status badge art above (Solidify, Bloodthirsty, Blessing).

## 4. Priority 3 - item icons (7 new; 20 of 36 items share 3 sprites today)

Item sprites are set in `scr_db_item.gml` (`sprite:` field). Already unique and fine: 3 swords, 3 bows, 3 staffs, 3 armors (`leather/iron/platinum_armor`), 3 robes (`cloth/silk/mithril_robe`), `antidote`, `bandage`. Those 20 need nothing.

| id (suggested sprite) | item | meaning | size | suggested motif | current placeholder | flag |
|---|---|---|---|---|---|---|
| `hp_potion_2` | HP Potion Lv2 (id 14) | heal 10-20 | 16x16 | same red-style bottle shape, larger flask, stopper highlight | `hp_potion` | same as Lv1 |
| `hp_potion_3` | HP Potion Lv3 (id 15) | heal 20-35 | 16x16 | large flask with sparkle / cross | `hp_potion` | same as Lv1 |
| `mp_potion_2` | MP Potion Lv2 (id 17) | restore 8-14 MP | 16x16 | as above with a star/droplet | `mp_potion` | same as Lv1 |
| `mp_potion_3` | MP Potion Lv3 (id 18) | restore 12-20 MP | 16x16 | large flask with sparkle | `mp_potion` | same as Lv1 |
| `skill_book_knight` | Skillbooks for Knight skills (ids 102-105) | learn a skill | 16x16 | existing open-book silhouette with a sword emblem | `skill_book` (open white book) | 14 books share 1 icon |
| `skill_book_archer` | Skillbooks for Archer skills (ids 106-109) | learn a skill | 16x16 | same book with a bow/arrow emblem | `skill_book` | same |
| `skill_book_mage` | Skillbooks for Mage skills (ids 110-114) | learn a skill | 16x16 | same book with a star/flame emblem | `skill_book` | same |

Notes: `skill_book` stays as the icon for Wound (id 101), which is shared by Knight and Archer. Potions Lv1 keep their current art. Alternative to 3 class books: draw the skill's own icon (section 3) as an 8x8 emblem on the book at runtime, which makes 14 distinct books with no extra art. That is a code decision for the owner.

## 5. Priority 4 - UI pieces that do not exist yet (needed for the redo in `ui.md` P2/P3)

| id (suggested sprite) | purpose | size | motif | current placeholder |
|---|---|---|---|---|
| `ui_panel_9slice` | panel background and border for every menu/popup (9-slice enabled in the IDE) | 24x24 with 8-px corners (or 16x16 with 5-px corners) | `#071821` outer line, `#306850` inner line, `#e0f8cf` single-pixel highlight corner, fill `#071821` | flat `draw_rectangle` black alpha 0.85-0.9 + 1-px white outline |
| `ui_select_bar` | selected-row highlight (9-slice, horizontal) | 16x12 | `#86c06c` bar with `#e0f8cf` top line, text `#071821` | white filled rectangle, black text |
| `ui_cursor` | list pointer (replaces the ">" character and the white bar) | 8x8 or 16x16 | right-pointing triangle / small hand | `">"` text in battle only |
| `ui_scroll_up`, `ui_scroll_down` | list scroll cues | 8x8 each | small triangle, palette colours, optional 2-frame blink | `dialogue_arrow_down` (pure white, 1 colour) flipped by code |
| `ui_equipped_mark` | marks equipped gear in the inventory | 8x8 | tick or small "E" badge | the letter "E" in text |
| `ui_qte_arrow` | defensive QTE direction prompt (rotated by code to 4 directions) | 16x16, optionally 2 frames (idle / hit) | chunky pixel arrow | 4 `draw_line` calls (`scr_combat.gml:1406`) |
| `class_knight_icon`, `class_archer_icon`, `class_mage_icon` | class select and status screen header | 16x16 each | sword / bow / staff-star | none (class select is text only) |
| `stat_str`, `stat_agi`, `stat_def`, `stat_int`, `stat_luck` | stat rows in the Stats tab (optional) | 8x8 each | fist / boot / shield / book-star / clover | text labels only |
| `dialogue_arrow_down` (recolour, not new) | dialogue continue cue | 16x16 | same triangle in `#e0f8cf` with `#071821` outline | currently pure `#ffffff`, one colour |
| `battle_screen` (recolour, not new) | battle background | 160x144 | palette-correct backdrop | flat `#0a2533`, outside the palette |

## 6. Counts

- Status icons: 10 new (4 existing are fine).
- Player skill icons: 14 new (+13 optional enemy skill icons).
- Item icons: 7 new.
- UI pieces: about 14 new sprites (stat icons are optional), plus 2 recolours.
- Total required for the owner's stated problem (statuses + skills + item variants): **31** 16x16 sprites; with UI pieces about 45.

## 7. Reference: where every icon-like sprite is used today

| Sprite(s) | Size / frames | Used by |
|---|---|---|
| `poison_status`, `bleed_status`, `burn_status`, `stun_status` | 16x16 / 1 | status db core icons (`scr_status.gml:34-37,118-160`), HUD and enemy rows |
| `rock1`, `torch_asset_moving` (16x16 / 3 frames), `tall_grass_asset`, `skull_2_asset`, `mp_potion` | 16x16 | placeholder defaults for Guard, Rev Up, Evasion, Take Aim, Meditation (overwritten at init by FX frames; world props that are also placed in rooms) |
| `muscle_up_effect` (7 fr), `rev_up_effect` (10), `evasion_up_effect` (9), `take_aim_effect` (12, origin 24,24), `foresight_effect_Sheet` (10), `meditation` (11) | 48x48 | skill FX in battle and the status-icon placeholders |
| `wooden/iron/platinum_sword`, `_bow`, `wooden/ruby/diamond_staff`, `leather/iron/platinum_armor`, `cloth/silk/mithril_robe`, `hp_potion`, `mp_potion`, `antidote`, `bandage`, `skill_book` | 16x16 / 1 | item db `sprite:`; inventory rows, battle item list, loot log lines (`scr_loot.gml:432`) |
| `hp_bar`, `mp_bar` | 31x9 / 11 | battle HUD, Stats tab (fill frame = ratio, 10 steps) |
| `dialogue_arrow_down` | 16x16 / 1 | dialogue continue cue, character menu scroll arrows |
| `spr_attack_timing_target`, `spr_attack_timing_falling` | 16x16 / 1 | attack-timing QTE |
| `leather_suit`, `iron_suit`, `platinum_suit` | 16x16 / 1 | **no references found** |
