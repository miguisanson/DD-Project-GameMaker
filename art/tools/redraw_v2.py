"""v2 hand redraws (reference-informed, see art/REFERENCES.md). Exact palette: # 071821  o 306850  g 86C06C  w E0F8CF.
Shape language (D78 / retro-ui.md: shape, not colour):
  * debuffs = ROUND badge, buffs = CHAMFERED-SQUARE badge, items/skills = free silhouettes with no frame.
  * Light from the top-left everywhere: w rim/highlight on top-left edges, o shade bottom-right.
  * 1-px #071821 outline on every shape (also around badge glyphs), glyph bodies drawn <= 9x9."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image, ImageDraw
import pp

COL = {"#": (7, 24, 33, 255), "o": (48, 104, 80, 255), "g": (134, 192, 108, 255), "w": (224, 248, 207, 255)}

DEBUFFS = {"poison", "burn", "bleed", "stun", "break", "sundered", "curse"}
BUFFS = {"steadfast", "guard", "rev_up", "evasion", "take_aim", "foresight", "meditation", "solidify", "bloodthirsty", "blessing"}


def rgba(rows):
    w = max(len(r) for r in rows)
    a = np.zeros((len(rows), w, 4), np.uint8)
    for y, r in enumerate(rows):
        assert len(r) == w, (len(r), w, r)
        for x, ch in enumerate(r):
            if ch in COL:
                a[y, x] = COL[ch]
    return a


# ---------- frames ----------
def round_frame():
    im = np.zeros((16, 16, 4), np.uint8)
    for y in range(16):
        for x in range(16):
            d = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5
            if d <= 7.9:
                im[y, x] = COL["o"]
            if 6.9 < d <= 7.9:
                im[y, x] = COL["#"]
    # rim light on the top-left arc of the ring's inner edge
    for y in range(16):
        for x in range(16):
            d = ((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5
            if 5.6 < d <= 6.9 and (x + y) < 13:
                im[y, x] = COL["g"]
    return im


def square_frame():
    shape = np.ones((16, 16), bool)
    for (x, y) in ((0, 0), (1, 0), (0, 1), (15, 0), (14, 0), (15, 1), (0, 15), (1, 15), (0, 14), (15, 15), (14, 15), (15, 14)):
        shape[y, x] = False
    p = np.pad(shape, 1)
    edge = shape & ~(p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:])
    im = np.zeros((16, 16, 4), np.uint8)
    im[shape] = COL["o"]
    im[edge] = COL["#"]
    # rim light along the inner top-left edges
    for i in range(2, 14):
        im[1, i] = COL["g"] if shape[1, i] and not edge[1, i] else im[1, i]
        im[i, 1] = COL["g"] if shape[i, 1] and not edge[i, 1] else im[i, 1]
    return im


def outline_glyph(g):
    """Add a 1-px # outline (8-neighbour) around an RGBA glyph; returns a larger array (h+2, w+2)."""
    h, w = g.shape[:2]
    big = np.zeros((h + 2, w + 2, 4), np.uint8)
    big[1:-1, 1:-1] = g
    a = big[..., 3] > 0
    p = np.pad(a, 1)
    ring = np.zeros_like(a)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            ring |= p[1 + dy:1 + dy + a.shape[0], 1 + dx:1 + dx + a.shape[1]]
    ring &= ~a
    big[ring] = COL["#"]
    return big


def badge(gid, glyph, outline=True):
    """Compose frame + outlined glyph (RGBA array, body only)."""
    base = round_frame() if gid in DEBUFFS else square_frame()
    g = outline_glyph(glyph) if outline else glyph
    gh, gw = g.shape[:2]
    oy, ox = (16 - gh) // 2, (16 - gw) // 2
    sl = base[oy:oy + gh, ox:ox + gw]
    m = g[..., 3] > 0
    sl[m] = g[m]
    return Image.fromarray(pp.snap_palette(base), "RGBA")


# ---------- status glyph bodies (<= 9x9) ----------
G2 = {
    "poison": ['...w...ww', '..wg...wg', '..ggg....', '.wgggg.w.', '.gggggg..', '.ggggggo.', '..gggoo..', '...ooo...', '.........'],
    "burn": ["....g....", "....gg...", "...ggg.g.", "..gggggg.", "..gwwggg.", ".gwwwwggg", ".gwwwwggg", ".ggwwwgg.", "..ggggg.."],
    "bleed": ['....w....', '....w....', '...www...', '...www...', '..wwwwg..', '.wwwwwwg.', '.wwwwwgg.', '..wwwgg..', '...ggg...'],
    "stun": [".w.......", "www...w..", ".w...www.", "......w..", "..w......", ".www.....", "..w...w..", "w....www.", ".....wgw."],
    "steadfast": ["...www...", "...w.g...", "...www...", ".wwwwwgg.", "....wg...", "w...wg..g", "ww..wg.gg", ".wwgwggg.", "..wwwgg.."],
    "break": ['wwwwwww..', 'wgggg#ggw', 'wggg#gggw', 'wgg#ggggw', 'wggg#gggw', '.wgg#ggw.', '..wg#gw..', '...w#w...', '....#....'],
    "guard": ["wwwwwwwww", "wggwgggoo", "wggwgggoo", "wwwwwwwww", "wggwgggoo", ".wgwggoo.", "..wwggo..", "...wwo...", "....o...."],
    "rev_up": ["....w....", "...www...", "..wwwww..", ".wwwwwgg.", "...wggg..", "...wggg..", "...wggg..", "...ggoo..", "...ooo..."],
    "evasion": ["......www", "....wwwwg", "..wwwwwg.", ".wwwwwg..", "wwwwwg...", ".gwwg....", "..g#.....", ".g#......", "#........"],
    "take_aim": ['....w....', '..wwwww..', '.ww.w.ww.', '.w..w..w.', 'wwwwgwwww', '.w..w..w.', '.ww.w.ww.', '..wwwww..', '....w....'],
    "foresight": ["....w....", "w.......w", "..wwwww..", ".wwgggww.", "wwg#wgoww", ".wwgggww.", "..wwwww..", ".........", "........."],
    "meditation": ["....w....", "...www...", ".w.www.w.", "ww.www.ww", "wwgwwwgww", ".wggggggo", "..gggggo.", "...ooo...", "........."],
    "solidify": ['wwwwwwwww', 'wgggggggo', 'wgggg#ggo', 'wggg#gggo', 'wgggg#ggo', 'wggg#gggo', 'wgggggggo', 'wgggggggo', 'ooooooooo'],
    "bloodthirsty": ['ggggggggg', 'gwwgggwwg', '.wwgggww.', '.ww...ww.', '..w.w.w..', '....w....', '...www...', '...www...', '....w....'],
    "blessing": ['...www...', '..w...w..', '...www...', 'ww.....ww', 'www...www', 'wwww.wwww', '.www.www.', '..ww.ww..', '...w.w...'],
    "sundered": ["ww.....ww", "wwwwwwwww", "wgggwgggw", "wgggw.ggw", "wggw..ggw", ".wgw..gw.", "..ww..w..", "...w.w...", "........."],
    "curse": [".wwwwwww.", "wwwwwwwww", "ww##w##ww", "ww##w##ww", "wwwwwwwww", ".wwwgwww.", "..wwwww..", "..w.w.w..", "........."],
}
IDS_STATUS = ["poison", "burn", "bleed", "stun", "steadfast", "break", "guard", "rev_up", "evasion", "take_aim", "foresight",
              "meditation", "solidify", "bloodthirsty", "blessing", "sundered", "curse"]


def render_badge(gid):
    return badge(gid, rgba(G2[gid]))


if __name__ == "__main__":
    import sys
    out = Image.new("RGBA", (16 * 6 * 6, 16 * 6 * 3 + 4), (46, 74, 58, 255))
    for i, gid in enumerate(IDS_STATUS):
        im = render_badge(gid).resize((96, 96), Image.NEAREST)
        out.alpha_composite(im, ((i % 6) * 96, (i // 6) * 98))
    out.save(sys.argv[1])
