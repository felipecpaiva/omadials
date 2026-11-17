"""Render lowercase outlined lettering to plain-text half blocks."""
from final_common import *
from PIL import Image
import io
out=ROOT/'terminal'; out.mkdir(exist_ok=True)
# A tiny vector text master, rasterised by librsvg before half-block encoding.
(out/'lettering.svg').write_text(svg(text('omadials',0,11,14,'#ffffff'),68,14))
png(out/'lettering.svg',out/'lettering.png')
im=Image.open(out/'lettering.png').convert('RGBA')
lines=[]
for y in range(0,14,2):
    line=''
    for x in range(68):
        a=im.getpixel((x,y))[3]>=100; b=im.getpixel((x,y+1))[3]>=100
        line+=' ▀▄█'[int(a)+2*int(b)]
    lines.append(line.rstrip())
plain='\n'.join(lines)+"\n\nTurn, don't hunt.\n"
(out/'banner.txt').write_text(plain)
(out/'banner.ansi').write_text('\x1b[38;2;255;140;120m'+plain+'\x1b[0m\n')
