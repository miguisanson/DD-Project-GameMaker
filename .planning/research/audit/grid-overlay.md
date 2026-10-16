# Room grid overlay (D65) - does the art sit on a 16 px grid?

Made with `run_tests.ps1 -Mode fast -Only gridshots` (build b393a74-dirty, 2026-10-14). PNGs: `E:\Temp\dd-gate\gridshots\shot_grid_<room>.png`
(also re-creatable any time; nothing in the rooms was changed). Window scale 4, so one world pixel = 4 PNG pixels.
Legend: green = multiples of 16 from the room origin (0,0); violet = multiples of 16 from the camera's top-left corner (shown only when the
camera is off the room grid); red = room edge. Shots are the first view after entering the room (the camera follows the player at spawn),
so each shows only a 160x144 part of the room. rm_floor1 .. 9, 6_5, 9_5 (11 rooms); rm_start excluded.

| Room | Size | Multiple of 16? | Walls / floor edges vs the grid (shot opened = yes) |
|---|---|---|---|
| rm_floor1 | 321x175 | no (+1 wide, -1 high) | opened: floor edges and walls sit on the green lines; view y=23 is off-grid (violet) |
| rm_floor2 | 256x176 | yes (16x11) | not opened |
| rm_floor3 | 256x176 | yes (16x11) | not opened |
| rm_floor4 | 208x240 | yes (13x15) | opened: every floor tile, barrel, rock and chest fills exactly one cell |
| rm_floor5 | 304x160 | yes (19x10) | opened: tiles and props on-grid; cave-tree clusters at the right are free-form |
| rm_floor6 | 305x335 | no (+1, -1) | opened: floor, walls and props on-grid |
| rm_floor6_5 | 144x144 | yes (9x9) | opened: perfect; room edge (red) sits on cell border, camera x=-16 shows 16 px of black outside |
| rm_floor7 | 274x275 | no (+2, +3) | opened: floor left edge on-grid; floor top edge reads about 2 px off a line (shading above it makes this uncertain) |
| rm_floor8 | 336x175 | width yes (21), height -1 | opened: tile blocks on-grid; camera x=176 is a multiple of 16 |
| rm_floor9 | 321x176 | width +1, height yes | not opened |
| rm_floor9_5 | 514x207 | no (+2, -1) | opened: organic cave/tree edges, not tile based; only the lane's top/bottom are roughly on a line |

## Reading
- 5 of 11 rooms are exact multiples of 16 (floor2, 3, 4, 5, 6_5). The other 6 are 1 to 3 px off in one or both sizes. That looks like
  the room was sized from an image, not like a different tile size: where I opened them, the art itself still sits on the 16 px cells.
- Looks off or free-form: rm_floor9_5 (organic edges, size +2/-1), rm_floor7 (2 px at the floor top edge, uncertain), and the cave/tree
  clusters in rm_floor5. These are not grid bugs, just art that was never meant for the grid.
- Camera: the view origin is off the 16 grid in most rooms (y=23 in floor1, y=7 in floor2, x=15 in floor4, y=131 in floor7 ...). That only
  shifts where the lines fall on screen; it does not change the art.
- Not checked: the parts of each room outside the first view, and floor2, floor3, floor9 shots (not opened). Looking at the PNGs is the owner's call.
- Suggested next step for the owner: open shot_grid_rm_floor1 and shot_grid_rm_floor7; if they look right, only the odd room sizes
  (321x175, 305x335, 274x275, 514x207, ...) would be worth rounding, via the IDE.
