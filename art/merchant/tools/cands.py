"""Clean 16x16 merchant candidates (A-C pixel-cleaned from ComfyUI renders, D hand-drawn). Legend: . clear, D #071821, g #306850, m #86C06C, L #E0F8CF"""
from PIL import Image
PAL={'.':(0,0,0,0),'D':(7,24,33,255),'g':(48,104,80,255),'m':(134,192,108,255),'L':(224,248,207,255)}
C={}
# A  pedlar: round hood, pack lumps either side of the shoulders (ComfyUI d65 seed 2)
C['A']=["................",
"......DDDD......",
"....DDDDDDDD....",
"...DgDDDDDDDD...",
"...DgDDDDDDDD...",
"...DDLDDDDLDD...",
"...DDDDDDDDDD...",
"..mDDDDDDDDDDm..",
".mmDDDDDDDDDDmm.",
".mgDDDDDDDDDDgm.",
".mgDDDDDDDDDDgm.",
".mgDDDDDDDDDDgm.",
"..gDDDDDDDDDDg..",
"..DDDDDDDDDDDD..",
"..DDDDDDDDDDDD..",
"..D.DD.DD.DD.D.."]
# B  toggle coat: tall narrow hood, clasp, pouches low on both hips (ComfyUI d80 seed 3)
C['B']=["................",
".....DDDDDD.....",
"....DggDDDDD....",
"...DgDDDDDDDD...",
"...DDDDDDDDDD...",
"...DDLDDDDLDD...",
"...DDDDDDDDDD...",
"....DDDDDDDD....",
"...DDDDmmDDDD...",
"..ggDDDDDDDDgg..",
".ggmDDDmmDDDmgg.",
".ggmDDDDDDDDmgg.",
".ggDDDDDDDDDDgg.",
"..gDDDDDDDDDDg..",
"...DDDDDDDDDD...",
"...D.DDDDDD.D..."]
# C  heavy pack: big pack with straps rising behind the hood (ComfyUI d80 seed 5)
C['C']=["................",
".....DDDDDD.....",
"....DDggggDD....",
"..gg.DDDDDD.gg..",
".gmg.DDDDDD.gmg.",
".gmgDDLDDLDDgmg.",
".gmgDDDDDDDDgmg.",
".gggDDDDDDDDggg.",
".ggDDDLDDLDDDgg.",
".ggDDDmDDmDDDgg.",
"..gDDDmDDmDDDg..",
"..gDDDDDDDDDDg..",
"..DDDDDDDDDDDD..",
"..DDDDDDDDDDDD..",
"..DDDDDDDDDDDD..",
"..D.DD.DD.DD.D.."]
# D  hand-drawn lantern bearer: pack on one shoulder, a pale lantern swinging at the hip
C['D']=["................",
".....DDDDD......",
"....DDDDDDD.....",
"...DgDDDDDDmm...",
"...DgDDDDDDDmm..",
"...DDLDDDLDDDm..",
"...DDDDDDDDDDm..",
"..DDDDDDDDDDDgm.",
".DDDDDDDDDDDDgm.",
".DDDDDDDDDDDDgm.",
".DDDDDDDDDDDDgg.",
".DDDDDDDDDDDmgm.",
".DDDDDDDDDDDDmm.",
".DDDDDDDDDDDDDD.",
".DDDDDDDDDDDDDD.",
".D.DD.DDD.DD.DD."]
def frame_b(rows):
    """idle bob: head+pack dip one pixel, hem stays (like the Stranger's 2-frame move)."""
    r=list(rows); r.pop(9); r.insert(0,'.'*16); return r
def img(rows):
    im=Image.new('RGBA',(16,16))
    for y,row in enumerate(rows):
        assert len(row)==16,(y,row)
        for x,c in enumerate(row): im.putpixel((x,y),PAL[c])
    return im
def frames(k): return [img(C[k]),img(frame_b(C[k]))]
