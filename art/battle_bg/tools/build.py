"""H9 (D151): raw renders -> quantised candidates (art/battle_bg/candidates/<band>_<n>.png, 160x144) and the contact sheet.
Usage: python build.py <rawdir>    Bands: forest (A, floors 1-3), caves (B, 4-6), ruins (C, 7-9), boss (D, boss arena).
The sheet shows each candidate at 3x with the enemy zone (48x48 box at the middle) and the HUD band (bottom panels) outlined in
magenta for review only; the candidate files themselves have no outlines."""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import quantise as Q

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# (raw band, letter, description, raw file numbers). Boss redo (owner feedback 2026-10-16): D4..D9 = boss_3..boss_8, several sheet rows.
# The first boss try (D1-D3, boss_0..2, top-down arena) is dropped from the sheet and from candidates/ (still in git history).
BANDS = [("forest", "A", "floors 1-3 forest tunnel", [0, 1, 2]), ("caves", "B", "floors 4-6 caves", [0, 1, 2]),
         ("ruins", "C", "floors 7-9 ruins", [0, 1, 2]),
         ("boss", "D", "boss: tunnel exit", [3, 4, 5, 7]), ("boss", "D", "boss: tunnel exit", [8, 9, 10, 11]),
         ("boss", "D", "boss: tunnel exit", [12])]
# D4..D9 = boss_3..boss_8, D10..D13 = boss_9..boss_12 (second prompt, boss2). D7 (boss_6) is discarded: white border from the render.
N, K = 4, 3                    # sheet columns, sheet zoom
HUD_TOP = 84                   # the panels start about here (game pixels, battle layout BattleHud_Zones); review outline only


def main(rawdir):
    cdir = os.path.join(ROOT, "candidates")
    os.makedirs(cdir, exist_ok=True)
    pad, head = 6, 18
    cw, ch = Q.W * K, Q.H * K
    sheet = Image.new("RGB", (pad + N * (cw + pad), pad + len(BANDS) * (ch + head + pad)), (0x20, 0x20, 0x20))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for r, (band, letter, desc, ks) in enumerate(BANDS):
        for c, k in enumerate(ks):
            raw = os.path.join(rawdir, ("boss" if band == "boss" else band) + f"_{k}.png")
            if not os.path.exists(raw):
                continue
            im, idx = Q.quantise(Image.open(raw))
            im.save(os.path.join(cdir, f"{letter}{k + 1}.png"))
            assert set(np.unique(idx)) <= {0, 1, 2, 3} and im.size == (Q.W, Q.H)
            big = im.resize((cw, ch), Image.NEAREST)
            bd = ImageDraw.Draw(big)
            bd.rectangle([(80 - 24) * K, (58 - 24) * K, (80 + 24) * K, (58 + 24) * K], outline=(255, 0, 255))
            bd.rectangle([0, HUD_TOP * K, cw - 1, ch - 1], outline=(255, 0, 255))
            x, y = pad + c * (cw + pad), pad + r * (ch + head + pad) + head
            sheet.paste(big, (x, y))
            d.text((x, y - 14), f"{letter}{k + 1}   {desc}", fill=(255, 255, 255), font=font)
    sheet.save(os.path.join(ROOT, "contact_sheet.png"))
    print("sheet", sheet.size)


if __name__ == "__main__":
    main(sys.argv[1])
