"""v2 post-process: raw 1024 SDXL image -> 16x16 4-colour icon (transparent bg, 1-px #071821 outline).
Differences from v1 (pp.py, untouched): the outline is taken from the subject silhouette itself (no 2 px borders),
body shading uses 3 tones (#306850 / #86C06C / #E0F8CF), #071821 inside only for the deepest shadows, and a 3x3 mode
filter removes speckle so clusters read as pixel art. Pillow + numpy only. Deterministic."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image
import pp

D, O, G, W = pp.PAL["#"], pp.PAL["o"], pp.PAL["g"], pp.PAL["w"]


def _shift(a, dy, dx, fill=False):
    p = np.pad(a, 1, constant_values=fill)
    return p[1 + dy:1 + dy + a.shape[0], 1 + dx:1 + dx + a.shape[1]]


def silhouette(img, sub):
    """Return (L float [sub,sub], mask bool [sub,sub]) of the subject fitted (aspect kept) and centred in sub x sub."""
    m = pp.subject_mask(img)
    r = pp.fit_subject(img, m, sub)
    if r is None:
        return None
    L, C = r
    return L, C >= 0.5


def mode_filter(idx, mask, nlev=4):
    """3x3 majority over level indices (only inside mask); ties keep the centre value."""
    out = idx.copy()
    h, w = idx.shape
    for y in range(h):
        for x in range(w):
            if not mask[y, x]:
                continue
            cnt = np.zeros(nlev, int)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and mask[yy, xx]:
                        cnt[idx[yy, xx]] += 1
            best = cnt.max()
            if cnt[idx[y, x]] != best:
                out[y, x] = int(np.argmax(cnt))
    return out


def body_levels(L, mask, dark_frac=0.07):
    """Level index per pixel: 0 dark(#), 1 o, 2 g, 3 w, ranked on the subject's own luminance range."""
    v = L[mask]
    lo, hi = np.percentile(v, 3), np.percentile(v, 97)
    if hi - lo < 1e-3:
        hi = lo + 1e-3
    n = np.clip((L - lo) / (hi - lo), 0, 1)
    dark_cut = np.percentile(n[mask], dark_frac * 100)
    rest = (n - dark_cut) / max(1e-3, 1 - dark_cut)
    idx = np.where(n <= dark_cut, 0, 1 + np.minimum((np.clip(rest, 0, 0.999) * 3).astype(int), 2))
    return idx


def render(L, mask, size=None):
    """Silhouette boundary -> #071821; interior -> mode-filtered 3-tone body."""
    idx = body_levels(L, mask)
    idx = mode_filter(idx, mask)
    bound = mask & ~(_shift(mask, -1, 0) & _shift(mask, 1, 0) & _shift(mask, 0, -1) & _shift(mask, 0, 1))
    pal = [D, O, G, W]
    h, w = mask.shape
    out = np.zeros((h, w, 4), np.uint8)
    for y in range(h):
        for x in range(w):
            if not mask[y, x]:
                continue
            c = D if bound[y, x] else pal[idx[y, x]]
            out[y, x] = (*c, 255)
    return pp.cleanup(out)


def make_item(raw_path, size=16):
    img = Image.open(raw_path)
    r = silhouette(img, size)
    if r is None:
        return None
    L, mask = r
    out = render(L, mask)
    return Image.fromarray(pp.snap_palette(out), "RGBA")


def make_glyph(raw_path, sub):
    """Same, but returns an RGBA array of the subject for placing inside a badge frame (outline kept)."""
    img = Image.open(raw_path)
    r = silhouette(img, sub)
    if r is None:
        return None
    L, mask = r
    return render(L, mask)
