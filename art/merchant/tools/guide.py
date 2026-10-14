"""Build the 1024 structure guide for img2img: the game's 16x16 proportions (big hood, short cloak body) as a soft silhouette."""
from PIL import Image, ImageDraw, ImageFilter
import sys
W=1024
bg=(134,192,108)
im=Image.new('RGB',(W,W),bg)
d=ImageDraw.Draw(im)
u=W/22        # character cell; char spans ~ 14u wide, 15u tall
x0=W/2; top=W*0.12
# backpack (behind, lighter brown-green) wider than body, peeks above shoulder
d.rounded_rectangle([x0-6.6*u,top+5.2*u,x0+6.6*u,top+13.2*u],radius=1.8*u,fill=(90,100,60))
d.rounded_rectangle([x0-3.2*u,top+3.9*u,x0+3.2*u,top+6.5*u],radius=1.2*u,fill=(90,100,60))
# cloak body
d.polygon([(x0-3.4*u,top+6*u),(x0+3.4*u,top+6*u),(x0+5.6*u,top+15*u),(x0-5.6*u,top+15*u)],fill=(10,30,36))
# hood
d.ellipse([x0-4.6*u,top,x0+4.6*u,top+7.6*u],fill=(10,30,36))
# face void + eyes
d.ellipse([x0-2.9*u,top+2.0*u,x0+2.9*u,top+6.2*u],fill=(2,10,14))
for ex in (-1.3,1.3):
    d.ellipse([x0+ex*u-0.38*u,top+3.6*u,x0+ex*u+0.38*u,top+4.3*u],fill=(224,248,207))
im=im.filter(ImageFilter.GaussianBlur(5))
im.save(sys.argv[1])
