"""Post-process: raw SDXL image -> 16x16 4-colour icon with transparent bg and 1-px #071821 outline.
Pillow + numpy only. Deterministic."""
from collections import deque
import numpy as np
from PIL import Image

PAL = {"#": (7,24,33), "o": (48,104,80), "g": (134,192,108), "w": (224,248,207)}
PAL_LIST = [PAL["#"], PAL["o"], PAL["g"], PAL["w"]]

def subject_mask(img):
    """Flat-background removal: flood fill from the border over pixels close to the border colour."""
    a = np.asarray(img.convert("RGB").resize((192,192), Image.BOX)).astype(int)
    border = np.concatenate([a[0], a[-1], a[:,0], a[:,-1]])
    bg = np.median(border, axis=0)
    close = np.abs(a - bg).sum(axis=2) < 70
    seen = np.zeros(close.shape, bool); dq = deque()
    h, w = close.shape
    for x in range(w):
        for y in (0, h-1):
            if close[y,x] and not seen[y,x]: seen[y,x]=True; dq.append((y,x))
    for y in range(h):
        for x in (0, w-1):
            if close[y,x] and not seen[y,x]: seen[y,x]=True; dq.append((y,x))
    while dq:
        y,x = dq.popleft()
        for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny,nx = y+dy,x+dx
            if 0<=ny<h and 0<=nx<w and close[ny,nx] and not seen[ny,nx]:
                seen[ny,nx]=True; dq.append((ny,nx))
    return ~seen   # 192x192 bool, True = subject

def fit_subject(img, mask, sub):
    """Crop to subject bbox, fit into sub x sub (aspect kept, centred). Returns (L float 0..1 [sub,sub], cover float [sub,sub])."""
    ys, xs = np.where(mask)
    if len(ys) < 20: return None
    s = img.size[0] / 192
    x0,x1,y0,y1 = int(xs.min()*s), int((xs.max()+1)*s), int(ys.min()*s), int((ys.max()+1)*s)
    rgb = img.convert("RGB").crop((x0,y0,x1,y1))
    m = Image.fromarray((mask*255).astype(np.uint8)).resize(img.size, Image.NEAREST).crop((x0,y0,x1,y1))
    w,h = rgb.size; k = sub/max(w,h)
    nw, nh = max(1,round(w*k)), max(1,round(h*k))
    # box-average to 4x the target, then to the target (area average = clean cluster colours)
    rgb = rgb.resize((nw*4,nh*4), Image.BOX).resize((nw,nh), Image.BOX)
    m = m.resize((nw*4,nh*4), Image.BOX).resize((nw,nh), Image.BOX)
    L = np.zeros((sub,sub)); C = np.zeros((sub,sub))
    ox, oy = (sub-nw)//2, (sub-nh)//2
    L[oy:oy+nh, ox:ox+nw] = np.asarray(rgb.convert("L"))/255
    C[oy:oy+nh, ox:ox+nw] = np.asarray(m)/255
    return L, C

def quantize(L, C, levels):
    """levels: list of palette colours dark->light. Contrast-stretch on subject pixels, then rank-quantize."""
    sel = C >= 0.5
    out = np.zeros(L.shape + (4,), np.uint8)
    if sel.sum() == 0: return out
    v = L[sel]; lo, hi = np.percentile(v, 4), np.percentile(v, 96)
    if hi - lo < 1e-3: hi = lo + 1e-3
    n = np.clip((L - lo) / (hi - lo), 0, 1)
    idx = np.minimum((n * len(levels)).astype(int), len(levels)-1)
    for y,x in zip(*np.where(sel)):
        out[y,x,:3] = levels[idx[y,x]]; out[y,x,3] = 255
    return out

def cleanup(rgba):
    """Drop orphan pixels (no 4-neighbour opaque), fill 1-px holes."""
    a = rgba[...,3] > 0
    p = np.pad(a, 1); nb = p[:-2,1:-1].astype(int)+p[2:,1:-1]+p[1:-1,:-2]+p[1:-1,2:]
    rgba = rgba.copy()
    rgba[a & (nb == 0)] = 0
    a = rgba[...,3] > 0; p = np.pad(a, 1)
    nb = p[:-2,1:-1].astype(int)+p[2:,1:-1]+p[1:-1,:-2]+p[1:-1,2:]
    for y,x in zip(*np.where(~a & (nb >= 3))):
        nbrs = [rgba[y+dy,x+dx,:3] for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)) if 0<=y+dy<rgba.shape[0] and 0<=x+dx<rgba.shape[1] and rgba[y+dy,x+dx,3]]
        rgba[y,x,:3] = np.round(np.mean(nbrs,axis=0)); rgba[y,x,3] = 255
    return rgba

def add_outline(rgba, size):
    """Place into size x size canvas centred, add 1-px #071821 outline (8-neighbour) around opaque pixels."""
    h,w = rgba.shape[:2]
    canvas = np.zeros((size,size,4), np.uint8)
    oy, ox = (size-h)//2, (size-w)//2
    canvas[oy:oy+h, ox:ox+w] = rgba
    a = canvas[...,3] > 0; p = np.pad(a, 1); ring = np.zeros_like(a)
    for dy in (-1,0,1):
        for dx in (-1,0,1):
            ring |= p[1+dy:1+dy+size, 1+dx:1+dx+size]
    ring &= ~a
    canvas[ring,:3] = PAL["#"]; canvas[ring,3] = 255
    return canvas

def snap_palette(rgba):
    """Guarantee only the 4 exact colours (+ alpha 0 or 255)."""
    out = rgba.copy(); a = out[...,3] > 0
    px = out[...,:3].astype(int)
    d = ((px[:,:,None,:] - np.array(PAL_LIST)[None,None,:,:])**2).sum(-1)
    out[...,:3] = np.array(PAL_LIST, np.uint8)[d.argmin(-1)]
    out[...,3] = np.where(a, 255, 0); out[~a] = 0
    return out

def make_item(raw_path, size=16):
    img = Image.open(raw_path); m = subject_mask(img)
    r = fit_subject(img, m, size-2)
    if r is None: return None
    L, C = r
    q = cleanup(quantize(L, C, [PAL["#"], PAL["o"], PAL["g"], PAL["w"]]))
    return Image.fromarray(snap_palette(add_outline(q, size)), "RGBA")

def badge_base():
    """Round status badge: #071821 ring, #306850 disc (matches poison_status etc.)."""
    im = np.zeros((16,16,4), np.uint8)
    for y in range(16):
        for x in range(16):
            d = ((x-7.5)**2 + (y-7.5)**2) ** 0.5
            if d <= 7.9: im[y,x] = (*PAL["o"],255)
            if 6.9 < d <= 7.9: im[y,x] = (*PAL["#"],255)
    return im

def make_badge(raw_path=None, glyph_rgba=None):
    """Badge with a glyph inside. glyph: from raw SDXL (3-level: dark/mid/light) or a prepared RGBA array (<=10x10)."""
    base = badge_base()
    if glyph_rgba is None:
        img = Image.open(raw_path); m = subject_mask(img)
        r = fit_subject(img, m, 8)
        if r is None: return None
        L, C = r
        q = cleanup(quantize(L, C, [PAL["#"], PAL["g"], PAL["w"]]))
        glyph_rgba = add_outline(q, 10)
    h,w = glyph_rgba.shape[:2]
    ys, xs = np.where(glyph_rgba[...,3] > 0)
    gy0, gy1, gx0, gx1 = ys.min(), ys.max()+1, xs.min(), xs.max()+1
    g = glyph_rgba[gy0:gy1, gx0:gx1]; gh, gw = g.shape[:2]
    oy, ox = 8 - gh//2 - (gh%2)*0 , 8 - gw//2
    oy = (16-gh)//2; ox = (16-gw)//2
    sl = base[oy:oy+gh, ox:ox+gw]
    m = g[...,3] > 0
    sl[m] = g[m]
    return Image.fromarray(snap_palette(base), "RGBA")

def score(im):
    """Heuristic to auto-pick the best candidate: filled area 40-75% and use of >=3 colours."""
    a = np.asarray(im); op = a[...,3] > 0
    fill = op.mean(); cols = len({tuple(c) for c in a[op][:, :3]})
    return -abs(fill - 0.55) + 0.05*cols
