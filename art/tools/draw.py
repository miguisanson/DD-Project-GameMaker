"""Script-drawn 16x16 icons (hand-authored pixel shapes, exact palette). Primary art where SDXL fails.
Legend: # 071821  o 306850  g 86C06C  w E0F8CF  . transparent.
Badge glyphs are ASCII (<=10x10) placed on the round status badge. Item icons are drawn with primitives
in a 16x16 box and then get an automatic 1-px #071821 outline."""
import numpy as np
from PIL import Image, ImageDraw
import pp

COL = {"#": (7, 24, 33, 255), "o": (48, 104, 80, 255), "g": (134, 192, 108, 255),
       "w": (224, 248, 207, 255), "t": (0, 0, 0, 0)}


def ascii_to_rgba(rows):
    w = max(len(r) for r in rows)
    a = np.zeros((len(rows), w, 4), np.uint8)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in "#owg":
                a[y, x] = COL[ch]
    return a


# ---------------- status glyphs (drawn on the badge; keep inside ~10x10) ----------------
GLYPH = {
    "poison": ['......ww..', '.....wggg.', '.....gggg.', '..ww..gg..', '.wggg.....', '.gggg..w..', '.gggg.wgg.', '..gg..ggg.', '...gg.....', '..........'],
    "burn": ["....g.....", "....gg....", "...ggg.g..", "..gggwgg..", "..ggwwggg.", ".gggwwwggg", ".gggwwwggg", ".ggggwwgg.", "..gggggg..", "...gggg..."],
    "bleed": ["....w.....", "....g.....", "...ggg....", "..gwggg...", "..gwgggg..", ".gwggggg..", ".gggggggg.", ".gggggggg.", "..gggggg..", "...gggg..."],
    "stun": ["....w.....", "....w.....", ".w..g..w..", "..w.g.w...", "...wgw....", "wwgggggggw", "...wgw....", "..w.g.w...", ".w..g..w..", "....w....."],
    "steadfast": ["...gggg...", "...g..g...", "...gggg...", ".gggggggg.", "....gg....", "g...gg...g", "gg..gg..gg", ".gg.gg.gg.", "..gggggg..", "....gg...."],
    "break": ["wwwwwwwwww", "wggggg#ggg", "wgggg#gggg", "wggg##gggg", "wgggg#gggg", ".ggg#ggggg", ".gggg##gg.", "..ggg#gg..", "...gg#g...", "....g#...."],
    "guard": ["wwwwwwwwww", "wggggwgggw", "wggggwgggw", "wwwwwwwwww", "wggggwgggw", "wggggwgggw", ".wgggwggw.", "..wggwgw..", "...wwww...", "....ww...."],
    "rev_up": ['....ww....', '...wwww...', '..wwwwww..', '.ww.ww.ww.', '....gg....', '....ww....', '...wwww...', '..wwwwww..', '.ww.gg.ww.', '....gg....'],
    "evasion": ["..w....ww.", "..ww..www.", "..gwwwww..", "..ggg.....", "..ggg.....", "..gggggg..", "..ggggggg.", ".wgggggggg", "wwwwwwwwww", "wwwwwwwwww"],
    "take_aim": ["....w....", "....w....", "..wwwww..", ".w..w..w.", "wwwwgwwww", ".w..w..w.", "..wwwww..", "....w....", "....w...."],
    "foresight": ["...wwww...", ".wwwwwwww.", "wwwggggwww", "wwg####gww", "wwg####gww", "wwwggggwww", ".wwwwwwww.", "...wwww..."],
    "meditation": ["....w.....", "...www....", ".w.www.w..", "ww.www.ww.", "wwgwwwgww.", ".wggggggw.", "..gggggg..", "...gggg...", "..........", "w........w"],
    "solidify": ['wwwwwwwwww', 'wgggwggggw', 'wgggwggggw', 'wwwwwwwwww', 'wggwggggwg', 'wggwggggwg', 'wwwwwwwwww', 'wgggwggggw', 'wgggwggggw', 'wwwwwwwwww'],
    "bloodthirsty": ['gggggggggg', 'gggggggggg', '.ww....ww.', '.ww....ww.', '.ww..g.ww.', '..w.ggg.w.', '..w.ggg.w.', '...w.g.w..', '...w...w..', '....w.w...'],
    "blessing": ['..wwwwww..', '.w......w.', '..wwwwww..', '..........', '....ww....', '...wwww...', 'wwwwwwwwww', '...wwww...', '....ww....', '....ww....'],
    "sundered": ['wwwww.....', 'wgggw.www.', 'wgggw.wggw', 'wggw..wggw', 'wgg...wgw.', '.wg...wg..', '..w...w...', '...w....w.', '......w...', '........w.'],
    "curse": ["..wwwwww..", ".wwwwwwww.", "wwwwwwwwww", "ww##ww##ww", "ww##ww##ww", "wwwwwwwwww", ".wwwggww..", "..wwwwww..", "...w..w...", "..w....w.."],
}


# ---------------- item icons (primitive drawing) ----------------
class Canvas:
    def __init__(s):
        s.im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        s.d = ImageDraw.Draw(s.im)

    def px(s, x, y, c): s.d.point((x, y), COL[c])
    def L(s, x0, y0, x1, y1, c, w=1): s.d.line((x0, y0, x1, y1), COL[c], width=w)
    def R(s, x0, y0, x1, y1, c): s.d.rectangle((x0, y0, x1, y1), COL[c])
    def C(s, cx, cy, r, c): s.d.ellipse((cx - r, cy - r, cx + r, cy + r), COL[c])
    def P(s, pts, c): s.d.polygon(pts, COL[c])

    def A(s, rows, ox=0, oy=0):
        a = ascii_to_rgba(rows)
        for y in range(a.shape[0]):
            for x in range(a.shape[1]):
                if a[y, x, 3]:
                    s.im.putpixel((x + ox, y + oy), tuple(int(v) for v in a[y, x]))


def sword(c, x0=3, y0=12, x1=12, y1=3):
    c.L(x0, y0, x1, y1, "g", 2)
    c.L(x0, y0 - 1, x1 - 1, y1, "w")
    c.L(x0 - 1, y0 - 3, x0 + 3, y0 + 1, "o")
    c.L(x0 - 1, y0 + 1, x0 - 3, y0 + 3, "o", 2)


def drop(c, cx, top, col="g", hi="w", h=5):
    c.P([(cx, top), (cx - 2, top + 3), (cx + 2, top + 3)], col)
    c.C(cx, top + h - 1, 2, col)
    c.px(cx - 1, top + h - 1, hi)


def shield(c, cx=7, top=2, col="g", rim="w"):
    c.P([(cx - 5, top), (cx + 5, top), (cx + 5, top + 6), (cx, top + 12), (cx - 5, top + 6)], rim)
    c.P([(cx - 4, top + 1), (cx + 4, top + 1), (cx + 4, top + 6), (cx, top + 10), (cx - 4, top + 6)], col)


def wing(c, x, y): c.A([".ww", "wwg", "wg.", "w.."], x, y)


ITEMS = {}


def item(name):
    def deco(f):
        ITEMS[name] = f
        return f
    return deco


@item("skill/wound")
def _(c): sword(c, 2, 11, 10, 3); drop(c, 12, 8, "w", "g", 5)
@item("skill/hilt_bash")
def _(c):
    c.R(6, 2, 9, 9, "g"); c.R(6, 2, 7, 9, "w"); c.R(3, 9, 12, 10, "o"); c.R(6, 11, 9, 13, "w")
    for p in ((13, 3), (2, 3)): c.px(p[0], p[1], "w")
    for p in ((13, 6), (2, 6)): c.px(p[0], p[1], "g")
@item("skill/muscle_up")
def _(c): shield(c, 5, 2); c.R(8, 7, 13, 13, "w"); c.L(9, 9, 13, 9, "o"); c.L(9, 11, 13, 11, "o"); c.R(8, 7, 8, 13, "g")
@item("skill/rev_up")
def _(c): c.A(["......ww......", ".....wwww.....", "....wwwwww....", "...wwwwwwww...", "..ww.wwww.ww..", ".....gggg.....", "......ww......", ".....wwww.....", "....wwwwww....", "...wwwwwwww...", "..ww.gggg.ww..", ".....gggg....."], 0, 2)
@item("skill/horizontal_slash")
def _(c):
    c.d.ellipse((0, 3, 15, 12), COL["w"]); c.d.ellipse((0, 6, 15, 15), COL["t"])
    c.d.ellipse((2, 5, 13, 12), COL["g"]); c.d.ellipse((2, 7, 13, 15), COL["t"])
    c.L(1, 13, 14, 13, "w")
@item("skill/power_strike")
def _(c):
    sword(c, 3, 13, 10, 6); c.L(10, 6, 12, 4, "w")
    for p in ((12, 1), (13, 3), (7, 2), (14, 6)): c.px(p[0], p[1], "w")
@item("skill/poison_arrow")
def _(c): c.L(2, 13, 11, 4, "w"); c.P([(13, 2), (8, 3), (12, 7)], "g"); c.L(2, 13, 4, 13, "g"); c.L(2, 13, 2, 11, "g"); drop(c, 12, 9, "g", "w", 5)
@item("skill/evasion")
def _(c): c.A(["...ggg", "...ggg", "...ggg", "...ggggg", "..gggggggg", ".wgggggggg", "wwwwwwwwww"], 3, 5); wing(c, 1, 2); c.L(0, 13, 3, 13, "g")
@item("skill/double_shot")
def _(c): c.L(1, 12, 12, 1, "w"); c.L(4, 14, 14, 4, "w"); c.P([(14, 0), (9, 1), (13, 5)], "g"); c.P([(15, 3), (14, 8), (10, 4)], "g")
@item("skill/take_aim")
def _(c):
    c.C(7, 7, 5, "w"); c.C(7, 7, 3, "o"); c.px(7, 7, "g")
    c.L(7, 0, 7, 3, "w"); c.L(7, 11, 7, 14, "w"); c.L(0, 7, 3, 7, "w"); c.L(11, 7, 14, 7, "w")
@item("skill/fireball")
def _(c):
    c.P([(7, 5), (1, 4), (6, 8)], "g"); c.P([(6, 8), (0, 9), (7, 11)], "g"); c.P([(7, 10), (3, 14), (9, 12)], "g")
    c.C(10, 8, 5, "g"); c.C(9, 7, 2, "w"); c.px(12, 11, "o"); c.px(13, 9, "o")
@item("skill/poison_mist")
def _(c):
    c.C(5, 8, 3, "g"); c.C(9, 6, 4, "g"); c.C(11, 9, 3, "g"); c.R(4, 9, 11, 11, "g")
    for p in ((8, 4), (5, 6), (3, 13), (7, 13), (11, 13), (5, 14)): c.px(p[0], p[1], "w")
    for p in ((6, 8), (10, 7), (9, 10)): c.px(p[0], p[1], "o")
    c.L(4, 11, 11, 11, "o")
@item("skill/ice_spear")
def _(c):
    c.L(2, 13, 11, 4, "g", 3); c.P([(14, 1), (9, 3), (12, 6)], "w"); c.L(2, 13, 10, 5, "w"); c.L(3, 11, 5, 13, "o")
    c.px(12, 10, "w"); c.px(5, 3, "w")
@item("skill/meditation")
def _(c): c.A(["....w....", "...www...", "w.wwwww.w", "ww.www.ww", "wwgwwwgww", ".wggggggw.", "..gggggg..", "...gggg..."], 2, 4); c.px(7, 2, "w"); c.px(7, 1, "w")
@item("skill/foresight")
def _(c): c.A([".....wwwww.....", "..wwwwwwwwwww..", ".wwwwgggggwwww.", "wwwwgg###ggwwww", "wwwwgg###ggwwww", ".wwwwgggggwwww.", "..wwwwwwwwwww..", ".....wwwww....."], 0, 4)
@item("throwable/firebomb")
def _(c):
    c.C(7, 9, 5, "g"); c.C(6, 8, 3, "w"); c.R(6, 2, 8, 4, "o"); c.L(9, 2, 11, 0, "w")
    c.px(12, 0, "w"); c.px(11, 1, "g"); c.px(7, 11, "o"); c.px(9, 11, "o"); c.px(10, 9, "o")
@item("throwable/poison_pot")
def _(c):
    c.A(["..gggggg..", ".wggggggg.", "wgggggggg.", "ggg#gg#ggo", "ggg#gg#ggo", "gggg##gggo", "gggggggggo", ".gggggggo.", "..ooooo..."], 2, 5)
    c.R(5, 3, 10, 4, "o"); c.px(7, 1, "g"); c.px(8, 2, "g")
@item("throwable/ice_flask")
def _(c): c.A(["...gg...", "...gg...", "..gwwg..", ".gwwwwg.", "gwwgggwg", "gwgggggg", "gggggggg", ".gggggg.", "..gggg.."], 3, 4); c.R(6, 2, 9, 3, "o"); c.px(7, 9, "w"); c.px(9, 10, "w")
@item("throwable/smoke_bomb")
def _(c): c.C(7, 11, 3, "g"); c.R(6, 6, 8, 7, "o"); c.C(5, 4, 2, "w"); c.C(8, 3, 3, "w"); c.C(11, 5, 2, "w"); c.px(7, 11, "w")
@item("passive/attack")
def _(c): sword(c, 2, 12, 10, 4); c.L(12, 8, 12, 10, "w"); c.L(11, 9, 13, 9, "w")
@item("passive/defense")
def _(c): shield(c, 7, 2); c.L(7, 4, 7, 8, "w"); c.L(5, 6, 9, 6, "w")
@item("passive/vitality")
def _(c): c.A([".gg...gg.", "gwggg.ggg", "gwgggggggg", "ggggggggg", "ggggggggg", ".ggggggg.", "..ggggg..", "...ggg...", "....g...."], 2, 3)
@item("passive/magic")
def _(c): c.L(7, 1, 7, 13, "w"); c.L(1, 7, 13, 7, "w"); c.L(3, 3, 11, 11, "g"); c.L(11, 3, 3, 11, "g"); c.C(7, 7, 2, "w"); c.px(7, 7, "g")
@item("passive/speed")
def _(c): c.A(["..ww......", "...www....", "....www...", ".....www..", "....www...", "...www....", "..ww......"], 1, 3); c.A(["..ww......", "...www....", "....www...", ".....www..", "....www...", "...www....", "..ww......"], 6, 3); c.L(1, 12, 5, 12, "g"); c.L(2, 14, 8, 14, "g")
@item("passive/critical")
def _(c):
    for (x, y) in ((4, 4), (10, 4), (4, 10), (10, 10)): c.C(x, y, 2, "g")
    c.R(4, 4, 10, 10, "g"); c.px(4, 4, "w"); c.px(10, 4, "w"); c.px(4, 10, "w"); c.L(7, 7, 7, 14, "o")
@item("passive/greed")
def _(c): c.A([".ggg.ggg.", "..ggggg..", ".ggggggg.", "gggwwwggg", "gggwggggg", "gggwwwggg", "gggggwggg", ".ggwwwgg.", "..ggggg.."], 2, 3)
@item("passive/recovery")
def _(c): c.P([(2, 12), (2, 5), (9, 2), (13, 3), (12, 10), (5, 13)], "g"); c.L(3, 12, 11, 4, "w"); c.px(11, 11, "w"); c.px(12, 12, "w")
@item("accessory/ring")
def _(c):
    c.d.ellipse((1, 6, 14, 14), COL["g"]); c.d.ellipse((4, 8, 11, 12), COL["t"]); c.P([(7, 0), (10, 3), (7, 6), (4, 3)], "w"); c.px(6, 2, "g"); c.px(4, 9, "w"); c.px(11, 12, "o")
@item("accessory/charm")
def _(c): c.L(4, 1, 7, 5, "w"); c.L(11, 1, 8, 5, "w"); c.C(7, 9, 4, "g"); c.C(6, 8, 2, "w"); c.px(8, 10, "o"); c.px(7, 9, "g")
@item("misc/gold_coin")
def _(c): c.C(7, 7, 6, "g"); c.C(6, 6, 3, "w"); c.R(7, 4, 7, 10, "o"); c.L(11, 11, 11, 5, "o"); c.px(5, 4, "w")


def render_item(name):
    c = Canvas()
    ITEMS[name](c)
    a = np.array(c.im)
    a[..., 3] = np.where(a[..., 3] > 0, 255, 0)
    ys, xs = np.where(a[..., 3] > 0)
    tight = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return Image.fromarray(pp.snap_palette(pp.add_outline(tight, 16)), "RGBA")


def render_badge(gid):
    return pp.make_badge(glyph_rgba=ascii_to_rgba(GLYPH[gid]))


def upgrade_variant(img):
    """'+' corner badge overlay, top-right 5x5: dark box with a light plus."""
    a = np.array(img)
    a[0:5, 11:16] = COL["#"]
    for (x, y) in ((13, 1), (13, 2), (13, 3), (12, 2), (14, 2)):
        a[y, x] = COL["w"]
    return Image.fromarray(a, "RGBA")


def card_frame():
    """24x32 9-slice-able card frame (slice 8/8/8/8): double border, transparent inside."""
    a = np.zeros((32, 24, 4), np.uint8)
    ring = {0: "#", 1: "g", 2: "w", 3: "o", 4: "#"}
    for y in range(32):
        for x in range(24):
            e = min(x, 23 - x, y, 31 - y)
            if e in ring:
                a[y, x] = COL[ring[e]]
    for (x, y) in ((0, 0), (23, 0), (0, 31), (23, 31)):
        a[y, x] = 0
    return Image.fromarray(a, "RGBA")
