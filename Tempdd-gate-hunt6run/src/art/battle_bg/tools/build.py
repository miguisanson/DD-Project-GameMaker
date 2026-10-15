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
BANDS = [("forest", "A", "floors 1-3 forest tunnel"), ("caves", "B", "floors 4-6 caves"),
         ("ruins", "C", "floors 7-9 ruins"), ("boss", "D", "boss arena")]
N, K = 3, 3                    # candidates per band, sheet zoom
HUD_TOP = 84                   # the panels start about here (game pixels, battle layout BattleHud_Zones); review outline only


def main(rawdir):
    cdir = os.path.join(ROOT, "candidates")
    os.makedirs(cdir, exist_ok=True)
    pad, head = 6, 18
    cw, ch = Q.W * K, Q.H * K
    sheet = Image.new("RGB", (pad + N * (cw + pad), pad + len(BANDS) * (ch + head + pad)), (0x20, 0x20, 0x20))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    for r, (band, letter, desc) in enumerate(BANDS):
        for k in range(N):
            raw = os.path.join(rawdir, f"{band}_{k}.png")
            if not os.path.exists(raw):
                continue
            im, idx = Q.quantise(Image.open(raw))
            im.save(os.path.join(cdir, f"{letter}{k + 1}.png"))
            assert set(np.unique(idx)) <= {0, 1, 2, 3} and im.size == (Q.W, Q.H)
            big = im.resize((cw, ch), Image.NEAREST)
            bd = ImageDraw.Draw(big)
            bd.rectangle([(80 - 24) * K, (58 - 24) * K, (80 + 24) * K, (58 + 24) * K], outline=(255, 0, 255))
            bd.rectangle([0, HUD_TOP * K, cw - 1, ch - 1], outline=(255, 0, 255))
            x, y = pad + k * (cw + pad), pad + r * (ch + head + pad) + head
            sheet.paste(big, (x, y))
            d.text((x, y - 14), f"{letter}{k + 1}   {desc}", fill=(255, 255, 255), font=font)
    sheet.save(os.path.join(ROOT, "contact_sheet.png"))
    print("sheet", sheet.size)


if __name__ == "__main__":
    main(sys.argv[1])
