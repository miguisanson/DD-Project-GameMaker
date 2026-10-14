"""v2 item/skill icon redraws (16x16, free silhouettes, 1-px #071821 outline, light from top-left).
Bodies are drawn with `g` and optional w/o/# details; shade=True runs a rim/shade pass (g next to dark/empty on the top-left
becomes w, on the bottom-right becomes o) so every icon shares one light direction and outline weight."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image
import pp
import draw
from draw import Canvas, COL

ITEMS2 = {}


def item(name, shade=True):
    def deco(f):
        ITEMS2[name] = (f, shade)
        return f
    return deco


def shade_pass(a):
    out = a.copy()
    h, w = a.shape[:2]
    dark = (a[..., 3] == 0) | ((a[..., :3] == np.array(COL["#"][:3])).all(-1))
    isg = (a[..., :3] == np.array(COL["g"][:3])).all(-1) & (a[..., 3] > 0)
    P = np.pad(dark, 1, constant_values=True)
    up, dn, lf, rt = P[:-2, 1:-1], P[2:, 1:-1], P[1:-1, :-2], P[1:-1, 2:]
    lit = isg & (up | lf)
    shd = isg & (dn | rt) & ~lit
    out[lit, :3] = COL["w"][:3]
    out[shd, :3] = COL["o"][:3]
    return out


def sword(c, x0, y0, x1, y1):
    c.L(x0, y0, x1, y1, "g", 2)
    c.L(x0 - 1, y0 - 3, x0 + 3, y0 + 1, "o")
    c.L(x0 - 1, y0 + 1, x0 - 3, y0 + 3, "o", 2)


def arrow_up(c, cx, top, h=6, w=3, col="w", shaft=1):
    for i in range(w + 1):
        c.L(cx - i, top + i, cx + i, top + i, col)
    c.R(cx - shaft, top + w + 1, cx + shaft, top + h, col)


# ------------------------------- skills -------------------------------
@item("skill/wound")
def _(c):
    sword(c, 3, 10, 9, 4)
    c.P([(12, 7), (10, 10), (13, 10)], "w"); c.C(11, 11, 2, "w"); c.px(10, 11, "g")


@item("skill/hilt_bash", shade=True)
def _(c):
    # v2b (D114): sword turned pommel-first, a pommel ball with impact sparks
    c.L(7, 8, 13, 2, "g", 2)
    c.L(3, 8, 9, 12, "o", 2)
    c.L(6, 9, 4, 11, "g", 2)
    c.C(3, 12, 2, "w"); c.px(2, 11, "w"); c.px(4, 13, "o")
    for p in ((0, 9), (0, 15), (1, 6), (6, 15), (0, 12), (5, 14)):
        c.px(p[0], p[1], "w")


@item("skill/muscle_up", shade=True)
def _(c):
    # v2b (D114): raised clenched fist (knuckles, thumb across) + up arrow
    c.A(["..........w..", ".........www.", "........wwwww", ".........w...", ".wwwwww..w...", "wgwgwgwo.w...", "wgogogoo.....",
         "wggggggo.....", "wwwwwggo.....", "wgggggoo.....", "wgggggoo.....", ".ogggoo......", "..oooo......."])


@item("skill/rev_up")
def _(c):
    arrow_up(c, 6, 0, 12, 5, "g", 2)
    c.px(0, 8, "w"); c.px(1, 10, "w"); c.px(12, 8, "w"); c.px(11, 10, "w")
    c.L(1, 13, 3, 13, "g"); c.L(9, 13, 11, 13, "g")


@item("skill/horizontal_slash")
def _(c):
    c.d.ellipse((0, 3, 13, 12), COL["w"]); c.d.ellipse((0, 6, 13, 15), COL["t"])
    c.d.ellipse((2, 5, 11, 12), COL["g"]); c.d.ellipse((2, 7, 11, 15), COL["t"])
    c.px(1, 6, "w"); c.px(12, 6, "w")
    c.L(1, 13, 12, 13, "g")


@item("skill/power_strike")
def _(c):
    sword(c, 3, 10, 9, 4)
    c.L(9, 4, 11, 2, "w")
    for (x, y) in ((11, 0), (13, 2), (7, 1), (13, 5), (12, 6)):
        c.px(x, y, "w")


@item("skill/poison_arrow")
def _(c):
    c.L(2, 12, 9, 5, "w"); c.P([(12, 2), (6, 3), (11, 8)], "g"); c.L(2, 12, 2, 9, "g"); c.L(2, 12, 5, 12, "g")
    c.L(3, 11, 3, 8, "o"); c.L(3, 11, 6, 11, "o")
    c.P([(12, 8), (10, 11), (13, 11)], "g"); c.C(11, 12, 2, "g"); c.px(11, 11, "w")


@item("skill/evasion", shade=False)
def _(c):
    # feather + speed lines (same glyph language as the status badge)
    c.P([(1, 13), (3, 7), (8, 2), (13, 1), (12, 6), (7, 11)], "g")
    c.L(2, 12, 11, 3, "o"); c.L(3, 8, 8, 3, "w"); c.L(8, 3, 12, 2, "w")
    for (x, y) in ((6, 9), (9, 7), (11, 5), (5, 6), (8, 4)): c.px(x, y, "t")
    c.L(0, 4, 3, 4, "w"); c.L(0, 7, 2, 7, "w"); c.L(0, 10, 3, 10, "w")
    c.px(12, 13, "o")


@item("skill/double_shot")
def _(c):
    c.L(1, 10, 8, 3, "w"); c.P([(11, 0), (6, 1), (10, 5)], "g")
    c.L(1, 10, 1, 7, "g"); c.L(1, 10, 4, 10, "g")
    c.L(3, 13, 10, 6, "w"); c.P([(13, 3), (8, 4), (12, 8)], "g")
    c.L(3, 13, 3, 10, "g"); c.L(3, 13, 6, 13, "g")


@item("skill/take_aim", shade=False)
def _(c):
    c.C(7, 7, 5, "w"); c.C(7, 7, 3, "o")
    c.L(7, 1, 7, 3, "w"); c.L(7, 11, 7, 13, "w"); c.L(1, 7, 3, 7, "w"); c.L(11, 7, 13, 7, "w")
    c.C(7, 7, 1, "g"); c.px(7, 7, "w")


@item("skill/fireball")
def _(c):
    c.P([(7, 5), (0, 3), (6, 8)], "g"); c.P([(6, 8), (0, 9), (7, 11)], "g"); c.P([(7, 10), (3, 14), (9, 12)], "g")
    c.C(9, 8, 4, "g"); c.C(8, 7, 2, "w")
    c.px(7, 4, "w"); c.px(1, 6, "w")


@item("skill/poison_mist", shade=False)
def _(c):
    c.A(["....ggg.......", "...ggggg.gg...", "..gggggggggg..", ".gggggggggggg.", "gggggggggggggg", "gggggggggggggg", ".gggggggggggg.", "..oooooooooo.."], 0, 1)
    for (x, y) in ((5, 4), (8, 4)): c.R(x, y, x + 1, y + 1, "#")
    c.R(6, 7, 7, 7, "#"); c.px(4, 6, "o"); c.px(9, 6, "o")
    for (x, y) in ((3, 3), (4, 2), (11, 3), (5, 1)): c.px(x, y, "w")
    for x, y in ((3, 10), (7, 11), (11, 10)):
        c.px(x, y, "g"); c.px(x, y + 1, "w")


@item("skill/ice_spear")
def _(c):
    c.L(1, 12, 9, 5, "g", 3); c.P([(13, 0), (8, 2), (11, 6)], "w"); c.L(1, 12, 8, 6, "w")
    c.L(2, 10, 4, 12, "o"); c.px(12, 9, "w"); c.px(5, 2, "w"); c.px(13, 11, "w"); c.px(3, 1, "w")


@item("skill/meditation", shade=False)
def _(c):
    c.A(["....w....", "...www...", "w.wwwww.w", "ww.www.ww", "wwgwwwgww", ".wggggggo", "..gggggo.", "...ooo..."], 2, 4)
    c.px(7, 2, "w"); c.px(7, 1, "w"); c.px(3, 3, "g"); c.px(11, 3, "g")


@item("skill/foresight", shade=False)
def _(c):
    c.A([".....www.....", "..wwwwwwwww..", ".wwwgggggwww.", "wwwgg###ggwww", "wwwgg#w#ggwww", ".wwwgggggwww.", "..wwwwwwwww..", ".....www....."], 0, 4)
    c.px(7, 1, "w"); c.px(7, 2, "w"); c.px(3, 2, "w"); c.px(11, 2, "w")
    c.px(7, 13, "w"); c.px(3, 12, "w"); c.px(11, 12, "w")


# ------------------------------ throwables ------------------------------
@item("throwable/firebomb", shade=False)
def _(c):
    c.C(7, 8, 5, "o"); c.d.arc((2, 3, 12, 13), 180, 280, COL["g"]); c.C(5, 6, 1, "w"); c.px(4, 7, "g"); c.px(5, 5, "g")
    c.R(6, 2, 8, 3, "g"); c.px(6, 2, "w")
    c.L(9, 2, 10, 1, "w")
    c.P([(10, 0), (12, 0), (12, 2), (10, 3), (9, 2)], "w"); c.px(11, 1, "g"); c.px(11, 0, "g")
    c.px(9, 11, "o"); c.px(10, 9, "o")


@item("throwable/poison_pot", shade=False)
def _(c):
    # v2b (D114): round jug with a cork, a skull on the belly, a drip at the lip
    c.A(["...oooooo....", "..wwwwwwwo...", "...gggggo..w.", "..wggggggo.w.", ".wgggggggggw.", "wgggwwwggggo.", "wggwwwwwggoo.",
         "wggw#w#wgooo.", "wgggwwwggooo.", "wggggwgwgooo.", ".wgggggggooo.", "..ooooooooo.."])


@item("throwable/ice_flask", shade=False)
def _(c):
    c.R(6, 1, 9, 2, "o"); c.px(6, 1, "w")
    c.A(["..ww..", "..wg..", "..wg..", ".wwgg."], 5, 3)
    c.A(["wwwwwwww", "wgwggggg", "wggwgwgg", "wgwgggwg", "wggggggg", ".wggggoo", "..oooo.."], 4, 7)


@item("throwable/smoke_bomb", shade=False)
def _(c):
    c.C(7, 10, 3, "o"); c.px(6, 9, "g"); c.px(5, 8, "w")
    c.R(6, 6, 8, 7, "g")
    c.C(4, 4, 2, "w"); c.C(8, 3, 3, "w"); c.C(12, 5, 2, "w"); c.R(3, 5, 12, 6, "w")
    c.C(7, 2, 1, "g"); c.px(9, 4, "g"); c.px(12, 6, "g"); c.px(5, 5, "g")


# ------------------------------- passives -------------------------------
@item("passive/attack")
def _(c):
    sword(c, 3, 11, 9, 5)
    c.L(11, 7, 11, 11, "w"); c.L(9, 9, 13, 9, "w")


@item("passive/defense", shade=False)
def _(c):
    draw.shield(c, 7, 2, "g", "w")
    c.L(7, 4, 7, 8, "#"); c.L(5, 6, 9, 6, "#")
    for y in range(3, 9): c.px(10, y, "o")
    c.px(8, 10, "o"); c.px(7, 11, "o")


@item("passive/vitality")
def _(c):
    c.A([".ggg...ggg.", "ggggg.ggggg", "ggggggggggg", "ggggggggggg", "ggggggggggg", ".ggggggggg.", "..ggggggg..", "...ggggg...", "....ggg...."], 1, 3)


@item("passive/magic", shade=False)
def _(c):
    c.P([(6, 0), (8, 4), (12, 6), (8, 8), (6, 12), (4, 8), (0, 6), (4, 4)], "w")
    c.P([(6, 3), (7, 5), (9, 6), (7, 7), (6, 9), (5, 7), (3, 6), (5, 5)], "g")
    c.px(6, 6, "w"); c.px(12, 1, "w"); c.px(1, 11, "w")


@item("passive/speed", shade=False)
def _(c):
    for ox in (0, 5):
        c.A(["ww......", ".www....", "..www...", "...www..", "..www...", ".www....", "ww......"], 1 + ox, 3)
    c.L(0, 12, 6, 12, "g"); c.L(2, 13, 9, 13, "g"); c.L(0, 1, 5, 1, "g")


@item("passive/critical", shade=False)
def _(c):
    pts = []
    for i in range(16):
        ang = i * np.pi / 8
        r = 6.5 if i % 2 == 0 else 3.2
        pts.append((6.5 + r * np.cos(ang), 6.5 + r * np.sin(ang)))
    c.P(pts, "w")
    c.C(6, 6, 2, "g"); c.px(6, 6, "#")
    for (x, y) in ((4, 4), (5, 3)): c.px(x, y, "w")
    c.px(9, 9, "g"); c.px(10, 8, "g")


@item("passive/greed", shade=False)
def _(c):
    c.A([".gg.ggg..", "..ggggg..", ".wggggggo", "gwgwwwgggo", "ggwggggggo", "ggwwwwgggo", "gggggwgggo", "ggwwwwggo.", ".gggggggo.", "..ooooo..."], 2, 3)
    c.A(["www"], 5, 3)


@item("passive/recovery", shade=False)
def _(c):
    c.P([(1, 13), (1, 5), (8, 1), (13, 2), (13, 9), (6, 13)], "g")
    c.L(2, 12, 11, 3, "o"); c.L(1, 7, 3, 7, "w"); c.L(3, 4, 7, 2, "w")
    c.L(11, 9, 11, 13, "w"); c.L(9, 11, 13, 11, "w")


# ----------------------------- accessory / misc -----------------------------
@item("accessory/ring", shade=False)
def _(c):
    c.d.ellipse((1, 5, 12, 13), COL["g"]); c.d.ellipse((3, 7, 10, 11), COL["t"])
    c.d.arc((1, 5, 12, 13), 180, 270, COL["w"])
    c.P([(6, 0), (9, 2), (6, 5), (3, 2)], "w"); c.px(5, 2, "g"); c.px(6, 1, "w"); c.px(7, 3, "g"); c.px(6, 3, "g")
    c.px(11, 11, "o"); c.px(10, 12, "o")


@item("accessory/charm")
def _(c):
    c.L(2, 0, 6, 4, "w"); c.L(11, 0, 7, 4, "w")
    c.P([(7, 4), (12, 8), (7, 13), (2, 8)], "g"); c.P([(7, 6), (10, 8), (7, 11), (4, 8)], "o"); c.px(7, 8, "w"); c.px(6, 7, "w")


@item("misc/gold_coin", shade=False)
def _(c):
    c.C(7, 7, 6, "g"); c.d.arc((1, 1, 13, 13), 180, 290, COL["w"]); c.d.arc((1, 1, 13, 13), 15, 100, COL["o"])
    c.C(7, 7, 3, "o"); c.R(7, 4, 7, 10, "w"); c.R(6, 5, 8, 5, "w"); c.R(6, 9, 8, 9, "w")


def render(name):
    f, sh = ITEMS2[name]
    c = Canvas()
    f(c)
    a = np.array(c.im)
    a[..., 3] = np.where(a[..., 3] > 0, 255, 0)
    ys, xs = np.where(a[..., 3] > 0)
    tight = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    out = pp.add_outline(tight, 16)
    if sh:
        out = shade_pass(out)
    return Image.fromarray(pp.snap_palette(out), "RGBA")


if __name__ == "__main__":
    names = list(ITEMS2)
    Z = 6
    sheet = Image.new("RGBA", (6 * 16 * Z + 6 * 6, ((len(names) + 5) // 6) * (16 * Z + 6)), (46, 74, 58, 255))
    for i, n in enumerate(names):
        im = render(n).resize((16 * Z, 16 * Z), Image.NEAREST)
        sheet.alpha_composite(im, ((i % 6) * (16 * Z + 6), (i // 6) * (16 * Z + 6)))
    sheet.save(sys.argv[1])
    print(names)
