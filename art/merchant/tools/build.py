"""Write candidate frames/strips and the 4x preview sheet. Run from repo root: python -I art/merchant/tools/build.py [recommended letter]"""
import sys,os,glob
sys.path.insert(0,os.path.dirname(__file__))
from cands import *
from PIL import ImageDraw, ImageFont
ROOT='art/merchant'; Z=4
GOLD=(240,200,90)   # scr_loot.gml Merchant_EnsureInRoom: image_blend = make_color_rgb(240,200,90) -> GameMaker multiplies each channel
FLOOR=(224,248,207,255); DARK=(7,24,33,255)
def tint(im,rgb=GOLD):
    out=im.copy(); px=out.load()
    for y in range(out.height):
        for x in range(out.width):
            r,g,b,a=px[x,y]
            if a: px[x,y]=(r*rgb[0]//255,g*rgb[1]//255,b*rgb[2]//255,a)
    return out
def sheet_frames(path):
    fs=sorted(glob.glob(path+'/*.png')); return [Image.open(f).convert('RGBA') for f in fs]
def game_frames(name): return sheet_frames('sprites/'+name)
os.makedirs(ROOT+'/candidates',exist_ok=True)
for k in 'ABCD':
    fr=frames(k)
    for i,f in enumerate(fr): f.save(f'{ROOT}/candidates/cand_{k}_{i}.png')
    st=Image.new('RGBA',(16*len(fr),16)); [st.paste(f,(16*i,0)) for i,f in enumerate(fr)]; st.save(f'{ROOT}/candidates/cand_{k}_strip.png')
rec=sys.argv[1] if len(sys.argv)>1 else 'C'
try: F=ImageFont.load_default(size=13); FS=ImageFont.load_default(size=11)
except TypeError: F=FS=ImageFont.load_default()
nobody=game_frames('nobody_down'); knight=game_frames('knight_down'); stranger=game_frames('stranger_moving')
CW=16*Z*2+24; PAD=14
cols=[('CURRENT\nplaceholder',nobody,'gold'),('A',frames('A'),''),('B',frames('B'),''),('C',frames('C'),''),('D',frames('D'),''),('PLAYER\n(scale)',knight,'')]
rows=[('NO TINT (floor)',FLOOR,False),('GOLD TINT as in game (floor)',FLOOR,True),('GOLD TINT in a dark alcove',DARK,True)]
RH=16*Z+PAD*2+20
W=len(cols)*CW+170; H=len(rows)*RH+34
sh=Image.new('RGBA',(W,H),(60,70,60,255)); d=ImageDraw.Draw(sh)
d.text((8,6),f'merchant candidates, 4x, two idle frames each. Recommended: {rec}',font=F,fill=(255,255,255,255))
for r,(rl,bg,tinted) in enumerate(rows):
    y0=34+r*RH
    d.rectangle([160,y0,W,y0+RH-4],fill=bg)
    d.text((6,y0+PAD),rl.replace(' (','\n('),font=FS,fill=(255,255,255,255))
    for c,(cl,fr,mode) in enumerate(cols):
        x0=170+c*CW
        if r==0 and cl.startswith('CURRENT'): pass
        for i,f in enumerate(fr):
            g=f
            gold=(tinted and c<5) or (c==0 and mode=='gold' and r>0)
            if c==0 and r==0: g=f                 # row 1 shows the placeholder untinted (it is the Nobody sprite)
            elif c==0 and r>0: g=tint(f)
            elif c in (1,2,3,4) and tinted: g=tint(f)
            sh.alpha_composite(g.resize((16*Z,16*Z),Image.NEAREST),(x0+i*(16*Z+6),y0+PAD))
        lab=cl.replace('\n',' ') if r else cl.split('\n')[0]
        col=(7,24,33,255) if bg==FLOOR else (224,248,207,255)
        d.text((x0,y0+PAD+16*Z+2),(cl if c in(0,5) else cl+(' *rec' if cl==rec else '')).replace('\n',' '),font=FS,fill=col)
sh.save(ROOT+'/merchant_preview.png'); print(sh.size)
