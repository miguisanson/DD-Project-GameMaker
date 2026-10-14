"""Reduce a ComfyUI render to a 16x16 palette sprite: bg removal, bbox fit, area average, nearest palette colour, eye glints kept."""
from PIL import Image, ImageDraw
import numpy as np, sys
PAL=[(7,24,33),(48,104,80),(134,192,108),(224,248,207)]
def remove_bg(im,tol=55):
    a=np.asarray(im.convert('RGB')).astype(int)
    h,w,_=a.shape
    ref=np.median(np.concatenate([a[:8].reshape(-1,3),a[:,:8].reshape(-1,3),a[:,-8:].reshape(-1,3)]),axis=0)
    dist=np.sqrt(((a-ref)**2).sum(2))
    cand=dist<tol
    # flood from border
    from collections import deque
    bg=np.zeros((h,w),bool); q=deque()
    for x in range(w):
        for y in (0,h-1):
            if cand[y,x] and not bg[y,x]: bg[y,x]=True;q.append((y,x))
    for y in range(h):
        for x in (0,w-1):
            if cand[y,x] and not bg[y,x]: bg[y,x]=True;q.append((y,x))
    while q:
        y,x=q.popleft()
        for dy,dx in((1,0),(-1,0),(0,1),(0,-1)):
            yy,xx=y+dy,x+dx
            if 0<=yy<h and 0<=xx<w and cand[yy,xx] and not bg[yy,xx]: bg[yy,xx]=True;q.append((yy,xx))
    return ~bg
def reduce(path,size=16,maxw=15,maxh=15,tol=55,thr=0.5,eye_thr=215):
    im=Image.open(path).convert('RGB'); m=remove_bg(im,tol)
    # drop tiny specks: keep the largest component
    ys,xs=np.where(m); x0,x1,y0,y1=xs.min(),xs.max()+1,ys.min(),ys.max()+1
    crop=im.crop((x0,y0,x1,y1)); mc=Image.fromarray((m[y0:y1,x0:x1]*255).astype('uint8'))
    w,h=crop.size; s=min(maxw/w,maxh/h); nw,nh=max(1,round(w*s)),max(1,round(h*s))
    # fit by area average; weight colour by mask so edges don't bleed bg colour
    arr=np.asarray(crop).astype(float)*(np.asarray(mc)[...,None]/255.)
    cs=Image.fromarray(arr.astype('uint8')).resize((nw,nh),Image.BOX); ms=mc.resize((nw,nh),Image.BOX)
    c=np.asarray(cs).astype(float); k=np.asarray(ms).astype(float)/255.
    col=c/np.maximum(k[...,None],1e-3)
    # eye glints: very bright green pixels in the full-res crop -> mark in a hi-res mask, then downsample (any hit)
    full=np.asarray(crop).astype(int)
    glint=((full[...,1]>190)&(full[...,0]>120)&(np.asarray(mc)>0)).astype(float)
    # glints only count inside the upper (head) 60%
    glint[int(h*0.6):]=0
    g=np.asarray(Image.fromarray((glint*255).astype('uint8')).resize((nw,nh),Image.BOX)).astype(float)/255.
    out=Image.new('RGBA',(size,size),(0,0,0,0))
    ox=(size-nw)//2; oy=size-nh
    for y in range(nh):
        for x in range(nw):
            if k[y,x]<thr: continue
            p=col[y,x]
            if g[y,x]>0.12: rgb=PAL[3]
            else: rgb=min(PAL,key=lambda q:sum((q[i]-p[i])**2 for i in range(3)))
            out.putpixel((ox+x,oy+y),rgb+(255,))
    return out
if __name__=='__main__':
    reduce(sys.argv[1]).save(sys.argv[2])
