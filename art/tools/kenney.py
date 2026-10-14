"""CC0 base: convert Kenney 1-Bit Pack tiles (white strokes on transparent, 16x16) into the game's 4-colour icons.
Source: art/sources/kenney-1bit/monochrome-transparent_packed.png  (kenney.nl/assets/1-bit-pack, CC0).
Rule: outer boundary of the tile shape -> #071821, holes -> #86C06C body with #E0F8CF rim light (top-left) and
#306850 shade (bottom-right); a tile drawn as a solid white blob keeps its body and gets the dark outline.
Deterministic; Pillow + numpy only."""
import os
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SHEET = os.path.join(os.path.dirname(HERE), "sources", "kenney-1bit", "monochrome-transparent_packed.png")
PAL = {"#": (7, 24, 33), "o": (48, 104, 80), "g": (134, 192, 108), "w": (224, 248, 207)}

# icon key -> list of (col, row) tiles in the packed sheet (16 px grid); first entry is the default pick
MAP = {
    "skill/wound": [(34, 6), (33, 6)], "skill/rev_up": [(24, 12)], "skill/horizontal_slash": [(25, 11)],
    "skill/power_strike": [(35, 8)], "skill/poison_arrow": [(41, 5), (42, 5)], "skill/evasion": [(29, 11)],
    "skill/double_shot": [(37, 5), (39, 5)], "skill/fireball": [(28, 11)], "skill/ice_spear": [(33, 3), (34, 2)],
    "throwable/firebomb": [(45, 9)], "throwable/poison_pot": [(42, 11), (45, 4)], "throwable/ice_flask": [(41, 11), (32, 13)],
    "passive/attack": [(33, 7), (34, 8)], "passive/defense": [(37, 3), (40, 4)], "passive/vitality": [(39, 10), (40, 10)],
    "passive/speed": [(24, 21), (24, 20)],
}


def tile(col, row):
    im = Image.open(SHEET).convert("RGBA")
    return np.asarray(im.crop((col * 16, row * 16, col * 16 + 16, row * 16 + 16)))[..., 3] > 0


def _nb(a, dy, dx):
    """a shifted so that out[y,x] = a[y+dy,x+dx] (False outside)."""
    p = np.pad(a, 1)
    return p[1 + dy:1 + dy + a.shape[0], 1 + dx:1 + dx + a.shape[1]]


def convert(col, row):
    white = tile(col, row)
    h, w = white.shape
    # outside = background connected to the border through non-white pixels
    outside = np.zeros_like(white)
    stack = [(y, x) for y in range(h) for x in range(w) if (y in (0, h - 1) or x in (0, w - 1)) and not white[y, x]]
    for p in stack:
        outside[p] = True
    while stack:
        y, x = stack.pop()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not white[ny, nx] and not outside[ny, nx]:
                outside[ny, nx] = True
                stack.append((ny, nx))
    shape = ~outside
    holes = shape & ~white
    solid = white.sum() > holes.sum()
    grid = np.full((h, w), ".", dtype="<U1")
    body = holes if not solid else white
    line = white if not solid else holes
    grid[body] = "g"
    grid[line] = "#"
    # outer boundary always dark (the tile may be a filled blob)
    bound = shape & (~_nb(shape, -1, 0) | ~_nb(shape, 1, 0) | ~_nb(shape, 0, -1) | ~_nb(shape, 0, 1))
    grid[bound] = "#"
    # shading on body pixels: rim light where up/left neighbour is dark, shade where down/right is dark
    g = grid == "g"
    lit = g & ((grid_is(grid, _nb, -1, 0)) | (grid_is(grid, _nb, 0, -1)))
    shd = g & ((grid_is(grid, _nb, 1, 0)) | (grid_is(grid, _nb, 0, 1))) & ~lit
    grid[lit] = "w"
    grid[shd] = "o"
    out = np.zeros((h, w, 4), np.uint8)
    for k, c in PAL.items():
        out[grid == k] = (*c, 255)
    return Image.fromarray(out, "RGBA")


def grid_is(grid, nb, dy, dx):
    return nb(grid == "#", dy, dx)


def candidates(key):
    return [convert(c, r) for c, r in MAP.get(key, [])]


if __name__ == "__main__":
    import sys
    for key in MAP:
        print(key, MAP[key])
