"""Build the v2 icon set. Usage: python -I build_v2.py <rawdir_with_SDXL_1024_pngs>
Writes (v1 files are never touched):
  art/icons_v2/<category>/<id>.png        final 16x16 per icon (+ skill_up with the '+' corner badge)
  art/candidates_v2/<category>/<id>_<src>.png   every alternative (SDXL+LoRA through pp2, CC0 Kenney base, redraw)
  art/strips_v2/<category>_strip.png/.txt + manifest.json     same ids and order as art/strips (v1)
  art/contact_sheet_v2.png                v1 final | v2 final | v2 alternatives, labelled, 4x
Every output is checked: 16x16, binary alpha, exactly the 4 palette colours."""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import numpy as np
from PIL import Image, ImageDraw, ImageFont

import draw
import items_v2
import kenney
import pp
import pp2
import redraw_v2
from icons_manifest import CATS

ART = os.path.dirname(HERE)
RAW = sys.argv[1] if len(sys.argv) > 1 else None
PALSET = {tuple(c) for c in pp.PAL_LIST}

# Which source is the v2 final for each icon: 'redraw' (default), 'kenney<N>' or 'ai<N>'. Chosen by eye on the sheet.
PICK = {}
try:
    from picks_v2 import PICK  # noqa: F811
except ImportError:
    pass


def check(im, where):
    a = np.array(im.convert("RGBA"))
    assert im.size == (16, 16), (where, im.size)
    op = a[..., 3] > 0
    assert set(np.unique(a[..., 3])) <= {0, 255}, (where, "alpha not binary")
    assert {tuple(c) for c in a[op][:, :3]} <= PALSET, (where, "off-palette colour")
    assert (a[~op] == 0).all(), (where, "transparent px not zeroed")


def save(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)


def alternatives(cat, iid):
    """ordered dict src -> Image"""
    key = f"{cat}/{iid}"
    out = {}
    out["redraw"] = redraw_v2.render_badge(iid) if cat == "status" else items_v2.render(key)
    if cat != "status":
        for n, im in enumerate(kenney.candidates(key)[:2]):
            out[f"kenney{n}"] = im
    if RAW:
        for k in range(4):
            p = f"{RAW}/{cat}_{iid}_{k}.png"
            if not os.path.exists(p):
                continue
            if cat == "status":
                g = pp2.make_glyph(p, 9)
                if g is None:
                    continue
                out[f"ai{k}"] = redraw_v2.badge(iid, g, outline=False)
            else:
                im = pp2.make_item(p)
                if im is not None:
                    out[f"ai{k}"] = im
    return out


def load_v1(cat, iid):
    return Image.open(f"{ART}/icons/{cat}/{iid}.png").convert("RGBA")


def main():
    v1 = json.load(open(f"{ART}/strips/manifest.json"))
    order = {}
    for name, d in v1.items():
        order[name.replace("spr_icons_", "")] = d["ids"]
    finals, alts, srcs = {}, {}, {}
    for cat in ("status", "skill", "throwable", "passive", "accessory", "misc"):
        for iid in order[cat]:
            a = alternatives(cat, iid)
            src = PICK.get(f"{cat}/{iid}", "redraw")
            assert src in a, (cat, iid, src, list(a))
            for s, im in a.items():
                check(im, f"{cat}/{iid}/{s}")
                save(im, f"{ART}/candidates_v2/{cat}/{iid}_{s}.png")
            finals[(cat, iid)] = a[src]
            alts[(cat, iid)] = a
            srcs[(cat, iid)] = src
            save(a[src], f"{ART}/icons_v2/{cat}/{iid}.png")
    order["skill_up"] = list(order["skill"])
    for iid in order["skill"]:
        im = draw.upgrade_variant(finals[("skill", iid)])
        check(im, f"skill_up/{iid}")
        finals[("skill_up", iid)] = im
        save(im, f"{ART}/icons_v2/skill_up/{iid}.png")
    manifest = {}
    for cat, ids in order.items():
        strip = Image.new("RGBA", (16 * len(ids), 16), (0, 0, 0, 0))
        for n, iid in enumerate(ids):
            strip.paste(finals[(cat, iid)], (16 * n, 0))
        save(strip, f"{ART}/strips_v2/{cat}_strip.png")
        with open(f"{ART}/strips_v2/{cat}_strip.txt", "w", newline="\n") as f:
            f.write(f"# sprite: spr_icons_{cat}   frames: {len(ids)}   16x16 each, left to right = subimage 0..{len(ids) - 1}   (v2)\n")
            for n, iid in enumerate(ids):
                f.write(f"{n}\t{iid}\n")
        manifest[f"spr_icons_{cat}"] = {"strip": f"strips_v2/{cat}_strip.png", "frames": len(ids), "ids": ids}
    with open(f"{ART}/strips_v2/manifest.json", "w", newline="\n") as f:
        json.dump(manifest, f, indent=1)
    with open(f"{ART}/strips_v2/SOURCES.txt", "w", newline="\n") as f:
        f.write("# v2 final source per icon: redraw = hand-drawn reference-informed pixels (art/tools/redraw_v2.py, items_v2.py);\n"
                "# kenney = CC0 Kenney 1-Bit Pack tile recoloured to the palette; ai = SDXL + Pixel Art XL through art/tools/pp2.py\n")
        for (cat, iid), s in srcs.items():
            f.write(f"{cat}/{iid}\t{s}\n")
    contact_sheet(order, finals, alts, srcs)
    print({c: len(v) for c, v in order.items()})


def contact_sheet(order, finals, alts, srcs):
    Z = 4
    font = ImageFont.load_default(size=11)
    big = ImageFont.load_default(size=14)
    BG = (46, 74, 58)
    cell = 16 * Z
    labw = 118
    nalt = 7
    colw = labw + cell * 2 + 22 + nalt * (cell + 3) + 14
    rows = []
    for cat in ("status", "skill", "throwable", "passive", "accessory", "misc"):
        rows.append(("H", cat))
        for iid in order[cat]:
            rows.append(("I", cat, iid))
    ncol = 2
    per = -(-len(rows) // ncol)
    rowh = cell + 8
    W, H = colw * ncol + 20, per * rowh + 56
    sheet = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(sheet)
    d.text((10, 8), "D2 icon art v2 - per icon: v1 FINAL | v2 FINAL (highlighted) | v2 alternatives: redraw / Kenney CC0 base / SDXL+LoRA a-d.  "
                    "Tell the agent v1 or v2 (or an alternative) per icon.  16x16 shown 4x.", fill=(224, 248, 207), font=big)
    d.text((10, 28), "Shape language: debuffs = round badge, buffs = chamfered-square badge, skills/items = frameless silhouette. Light from top-left.",
           fill=(134, 192, 108), font=font)
    checker = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    cd = ImageDraw.Draw(checker)
    for y in range(0, cell, 8):
        for x in range(0, cell, 8):
            cd.rectangle((x, y, x + 7, y + 7), fill=(100, 124, 100, 255) if (x // 8 + y // 8) % 2 else (116, 140, 116, 255))

    for col in range(ncol):
        hx = 10 + col * colw + labw
        d.text((hx, 44 - 4), "v1", fill=(224, 248, 207), font=font)
        d.text((hx + cell + 8, 44 - 4), "v2 FINAL", fill=(224, 248, 207), font=font)
        for k, s in enumerate(["redraw", "kenney", "kenney2", "ai-a", "ai-b", "ai-c", "ai-d"]):
            d.text((hx + 2 * cell + 30 + k * (cell + 3), 44 - 4), s, fill=(134, 192, 108), font=font)

    def put(im, x, y, hl=False):
        c = checker.copy()
        c.alpha_composite(im.resize((cell, cell), Image.NEAREST))
        sheet.paste(c.convert("RGB"), (x, y))
        if hl:
            d.rectangle((x - 2, y - 2, x + cell + 1, y + cell + 1), outline=(224, 248, 207), width=2)

    for n, r in enumerate(rows):
        col, row = divmod(n, per)
        x0, y0 = 10 + col * colw, 50 + row * rowh
        if r[0] == "H":
            d.text((x0, y0 + 20), r[1].upper(), fill=(224, 248, 207), font=big)
            continue
        _, cat, iid = r
        d.text((x0, y0 + 4), iid, fill=(224, 248, 207), font=font)
        d.text((x0, y0 + 20), f"v2 = {srcs[(cat, iid)]}", fill=(134, 192, 108), font=font)
        put(load_v1(cat, iid), x0 + labw, y0)
        put(finals[(cat, iid)], x0 + labw + cell + 8, y0, hl=True)
        ax = x0 + labw + 2 * cell + 30
        a = alts[(cat, iid)]
        for k, s in enumerate(["redraw"] + [f"kenney{i}" for i in range(2)] + [f"ai{i}" for i in range(4)]):
            if s in a:
                put(a[s], ax + k * (cell + 3), y0)
    sheet.save(f"{ART}/contact_sheet_v2.png")


if __name__ == "__main__":
    main()
