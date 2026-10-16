"""H9 (D151): raw 1280x1152 SDXL image -> 160x144 4-colour battle background (exactly #071821 #306850 #86C06C #E0F8CF, no alpha).
Steps: luminance -> 8x8 box average -> contrast stretch -> darken the enemy zone in the middle (so the enemy sprite, drawn in the
same palette, reads) -> percentile thresholds -> 4x4 ordered dither on the two inner edges only -> 3x3 mode filter against speckle.
Deterministic. Usage: python quantise.py <raw.png> <out.png>   (or import quantise(img) -> PIL image)"""
import sys
import numpy as np
from PIL import Image

PAL = np.array([(0x07, 0x18, 0x21), (0x30, 0x68, 0x50), (0x86, 0xC0, 0x6C), (0xE0, 0xF8, 0xCF)], np.uint8)
W, H = 160, 144
BAYER = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) + 0.5) / 16.0
CUT = (0.34, 0.70, 0.975)     # share of pixels that fall below each threshold: dark, dark green, light green; the rest is the pale tone
DITHER = 0.06                 # dither amplitude in luminance units (0..1)
ZONE = (80, 56, 52, 40)       # enemy zone: centre x, centre y, half width, half height (game pixels; the enemy is drawn near (80, 58))


def enemy_mask():
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt(((xx - ZONE[0]) / ZONE[2]) ** 2 + ((yy - ZONE[1]) / ZONE[3]) ** 2)
    return np.clip(1.0 - d, 0, 1) ** 0.7        # 1 in the centre, 0 outside the ellipse


def mode3(idx):
    out = idx.copy()
    h, w = idx.shape
    for y in range(h):
        for x in range(w):
            cnt = np.zeros(4, int)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w:
                        cnt[idx[yy, xx]] += 1
            if cnt[idx[y, x]] <= 2:                # a lone pixel (at most itself and one neighbour): take the majority
                out[y, x] = int(np.argmax(cnt))
    return out


def quantise(img):
    g = np.asarray(img.convert("L"), np.float32) / 255.0
    g = g.reshape(H, g.shape[0] // H, W, g.shape[1] // W).mean(axis=(1, 3))       # 8x8 box average
    lo, hi = np.percentile(g, 1), np.percentile(g, 99)
    g = np.clip((g - lo) / max(hi - lo, 1e-3), 0, 1)
    th = np.percentile(g, [c * 100 for c in CUT])
    g = g * (1.0 - 0.55 * enemy_mask())                                             # darker where the enemy stands
    bay = np.tile(BAYER, (H // 4, W // 4)) - 0.5
    idx = np.zeros(g.shape, np.int64)
    for t in th:
        idx += (g + bay * DITHER >= t).astype(np.int64)
    idx = mode3(idx)
    return Image.fromarray(PAL[idx], "RGB"), idx


if __name__ == "__main__":
    im, _ = quantise(Image.open(sys.argv[1]))
    im.save(sys.argv[2])
