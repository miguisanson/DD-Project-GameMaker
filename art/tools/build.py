"""Build all D2 art outputs. Usage: python build.py <rawdir>   (run from anywhere; writes into ../ = art/)
 - art/icons/<category>/<id>.png        final 16x16 (script-drawn; see README in IMPORT-CHECKLIST)
 - art/icons/skill_up/<id>.png          skill icon + '+' upgrade corner badge
 - art/candidates/<category>/<id>_aiK.png   SDXL candidates after the pipeline (post-processed, 16x16)
 - art/strips/<category>_strip.png + .txt   one-row strips, 16 px per frame, order in the .txt
 - art/contact_sheet.png                4x, labelled, for keep/redo marking (D44)
"""
import json
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pp
import draw
from icons_manifest import CATS

ART = os.path.dirname(HERE)
RAW = sys.argv[1] if len(sys.argv) > 1 else None
PALSET = {tuple(c) for c in pp.PAL_LIST}


def save(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)


def check(im, where):
    a = np.array(im.convert("RGBA"))
    assert im.size in ((16, 16), (24, 32)), (where, im.size)
    op = a[..., 3] > 0
    assert set(np.unique(a[..., 3])) <= {0, 255}, (where, "alpha not binary")
    cols = {tuple(c) for c in a[op][:, :3]}
    assert cols <= PALSET, (where, cols - PALSET)
    assert (a[~op] == 0).all(), (where, "transparent px not zeroed")


def main():
    order = {}      # category -> [ids]
    finals = {}     # (cat, id) -> Image
    for cat, (kind, items) in CATS.items():
        order[cat] = [i for i, _ in items]
        for iid, _ in items:
            key = f"{cat}/{iid}"
            im = draw.render_badge(iid) if cat == "status" else draw.render_item(key)
            check(im, key)
            finals[(cat, iid)] = im
            save(im, f"{ART}/icons/{cat}/{iid}.png")
    # upgrade variants for skills
    order["skill_up"] = list(order["skill"])
    for iid in order["skill"]:
        im = draw.upgrade_variant(finals[("skill", iid)])
        check(im, f"skill_up/{iid}")
        finals[("skill_up", iid)] = im
        save(im, f"{ART}/icons/skill_up/{iid}.png")
    # card frame (single sprite, not a strip)
    cf = draw.card_frame()
    check(cf, "ui/card_frame")
    save(cf, f"{ART}/icons/ui/card_frame.png")

    # SDXL candidates through the real pipeline
    cands = {}
    if RAW:
        for cat, (kind, items) in CATS.items():
            for iid, _ in items:
                for k in range(3):
                    p = f"{RAW}/{cat}_{iid}_{k}.png"
                    if not os.path.exists(p):
                        continue
                    im = pp.make_badge(p) if cat == "status" else pp.make_item(p)
                    if im is None:
                        continue
                    check(im, f"cand {cat}/{iid}/{k}")
                    cands.setdefault((cat, iid), []).append(im)
                    save(im, f"{ART}/candidates/{cat}/{iid}_ai{k}.png")

    # strips + order files
    manifest = {}
    for cat, ids in order.items():
        strip = Image.new("RGBA", (16 * len(ids), 16), (0, 0, 0, 0))
        for n, iid in enumerate(ids):
            strip.paste(finals[(cat, iid)], (16 * n, 0))
        save(strip, f"{ART}/strips/{cat}_strip.png")
        with open(f"{ART}/strips/{cat}_strip.txt", "w", newline="\n") as f:
            f.write(f"# sprite: spr_icons_{cat}   frames: {len(ids)}   16x16 each, left to right = subimage 0..{len(ids) - 1}\n")
            for n, iid in enumerate(ids):
                f.write(f"{n}\t{iid}\n")
        manifest[f"spr_icons_{cat}"] = {"strip": f"strips/{cat}_strip.png", "frames": len(ids), "ids": ids}
    with open(f"{ART}/strips/manifest.json", "w", newline="\n") as f:
        json.dump(manifest, f, indent=1)

    contact_sheet(order, finals, cands)
    from checklist import write_checklist
    write_checklist(order, ART)
    print({c: len(v) for c, v in order.items()}, "candidates:", sum(len(v) for v in cands.values()))


def contact_sheet(order, finals, cands):
    Z = 4
    font = ImageFont.load_default(size=11)
    big = ImageFont.load_default(size=14)
    BG = (46, 74, 58)
    rowh, colw = 16 * Z + 10, 16 * Z * 4 + 150
    rows = []
    for cat in ("status", "skill", "throwable", "passive", "accessory", "misc"):
        rows.append(("H", cat))
        for iid in order[cat]:
            rows.append(("I", cat, iid))
    ncol = 3
    per = -(-len(rows) // ncol)
    W, H = colw * ncol + 20, per * rowh + 50
    sheet = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(sheet)
    d.text((10, 8), "D2 icon contact sheet: FINAL (script-drawn) then SDXL candidates a/b/c. Mark each: KEEP / REDO.  Palette-checked 16x16, shown 4x.", fill=(224, 248, 207), font=big)
    checker = Image.new("RGBA", (16 * Z, 16 * Z), (0, 0, 0, 0))
    cd = ImageDraw.Draw(checker)
    for y in range(0, 16 * Z, 8):
        for x in range(0, 16 * Z, 8):
            cd.rectangle((x, y, x + 7, y + 7), fill=(100, 124, 100, 255) if (x // 8 + y // 8) % 2 else (116, 140, 116, 255))

    def put(im, x, y):
        cell = checker.copy()
        z = im.resize((16 * Z, 16 * Z), Image.NEAREST)
        cell.alpha_composite(z)
        sheet.paste(cell.convert("RGB"), (x, y))

    for n, r in enumerate(rows):
        col, row = divmod(n, per)
        x0, y0 = 10 + col * colw, 40 + row * rowh
        if r[0] == "H":
            d.text((x0, y0 + 20), r[1].upper(), fill=(224, 248, 207), font=big)
            continue
        _, cat, iid = r
        d.text((x0, y0 + 4), iid, fill=(224, 248, 207), font=font)
        d.text((x0, y0 + 20), "[ ] keep  [ ] redo", fill=(134, 192, 108), font=font)
        put(finals[(cat, iid)], x0 + 120, y0)
        for k, im in enumerate(cands.get((cat, iid), [])[:3]):
            put(im, x0 + 120 + (k + 1) * (16 * Z + 4) + 8, y0)
    sheet.save(f"{ART}/contact_sheet.png")


if __name__ == "__main__":
    main()
