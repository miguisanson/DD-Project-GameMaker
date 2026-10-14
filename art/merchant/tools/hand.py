"""Hand-drawn 16x16 merchant (the structure guide for ComfyUI and the fallback candidate).
Legend: . clear, D #071821, m #86C06C, L #E0F8CF, g #306850"""
from PIL import Image
PAL={'.':(0,0,0,0),'D':(7,24,33,255),'g':(48,104,80,255),'m':(134,192,108,255),'L':(224,248,207,255)}
A=["................",
   ".....DDDDDD.....",
   "....DDDDDDDDmm..",
   "...DDDDDDDDDmmm.",
   "...DDDDDDDDDDmm.",
   "...DDLDDDLDDDmm.",
   "...DDDDDDDDDDmm.",
   "..DDDDDDDDDDDDm.",
   ".DDDDDDDDDDDDDDm",
   ".DDDDDDDDDDDDDDm",
   ".DDDDDDDDDDDDDDm",
   ".DDDDDDDDDDDDDD.",
   ".DDDDDDDDDDDDDD.",
   ".DDDDDDDDDDDDDD.",
   ".DDDDDDDDDDDDDD.",
   "................"]
def img(rows):
    im=Image.new('RGBA',(16,16))
    for y,r in enumerate(rows):
        for x,c in enumerate(r): im.putpixel((x,y),PAL[c])
    return im
if __name__=='__main__':
    import sys
    img(A).save(sys.argv[1])
