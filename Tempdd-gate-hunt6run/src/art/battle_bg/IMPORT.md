# Import the battle backgrounds in the IDE (D151)

Why: the IDE owns the `.yyp`/`.yy` files, so agents cannot create sprites. The code looks each sprite up by its exact name with
`asset_get_index(...)` (`Battle_BgSprite` in `scripts/scr_fx/scr_fx.gml`) and keeps today's background (`battle_screen`) until the sprite
exists, so the game runs before, during and after the import. You can import one, two or all four.

Pick the files first (`PICK.md`), then for each of the 4 sprites:

1. Asset Browser: right-click the **Sprites** folder, **Create > Sprite**. Rename it to the exact name in the table (case matters).
2. In the Sprite Editor press **Import** and choose the picked PNG (one image, one frame; the size must read **160 x 144**).
3. **Origin**: Top Left (0,0).
4. **Collision mask**: leave the default (the sprite is only drawn as a room background; do not assign it to an object).
5. Texture group: Default. Playback speed does not matter (1 frame). Save (Ctrl+S).

| Sprite name (exact) | Used when | File to import (replace `?` with your pick) |
|---|---|---|
| `spr_battle_bg_forest` | the fight is on floor 1, 2 or 3 (not a boss) | `art/battle_bg/candidates/A?.png` |
| `spr_battle_bg_caves`  | the fight is on floor 4, 5 or 6 (not a boss) | `art/battle_bg/candidates/B?.png` |
| `spr_battle_bg_ruins`  | the fight is on floor 7, 8 or 9 (not a boss) | `art/battle_bg/candidates/C?.png` |
| `spr_battle_bg_boss`   | any boss fight (the mini boss and the final boss), whatever the floor | `art/battle_bg/candidates/D?.png` |

Half floors count with the floor below (rm_floor6_5 is the caves, rm_floor9_5 the ruins). A battle with no known floor keeps the old background.

Check: start a run and fight an enemy on floor 1 (forest picture behind it), another on floor 4 or later, and a boss.
The picture must sit behind the enemy and the panels; the middle of the screen should stay dark.
