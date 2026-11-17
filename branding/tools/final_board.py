"""Final overview and nearest-neighbour pixel inspection, no browser."""
from final_common import *
from PIL import Image, ImageDraw
import io

def build():
    im=Image.new('RGB',(1200,640),PAPER); d=ImageDraw.Draw(im)
    for row,(name,bg) in enumerate([('icon',BG),('icon-light',PAPER),('icon-mono',PAPER),('icon-mono-dark',BG)]):
        y=row*160; d.rectangle((0,y,1200,y+159),fill=bg)
        fg=WHITE if bg==BG else BG
        d.text((16,y+12),name,fill=fg)
        for x,s in [(240,16),(720,32)]:
            src=Image.open(LOGO/f'{name}-{s}.png').convert('RGBA')
            im.paste(src,(x,y+36),src)
            z=src.resize((s*3,s*3),Image.Resampling.NEAREST); im.paste(z,(x+60,y+36),z)
            z=src.resize((s*4,s*4),Image.Resampling.NEAREST); im.paste(z,(x+180,y+26),z)
    im.save(ROOT/'pixel-check.png')
    b=rect(0,0,1800,2050,0,PAPER)
    b+=text('omadials / final brand kit',48,64,32)
    b+=embed(ROOT/'social/github-social-preview.svg',48,100,1104,552)
    b+=embed(ROOT/'brand-sheet.svg',1190,100,560,680)
    b+=embed(ROOT/'social/banner-dark.svg',48,700,1104,276)
    b+=embed(ROOT/'social/banner-light.svg',48,1000,1104,276)
    b+=embed(ROOT/'social/marketplace-preview.svg',48,1320,880,495)
    for i,(n,bg) in enumerate([('icon',BG),('icon-light',PAPER),('icon-mono',PAPER),('icon-mono-dark',BG)]):
        x=1190+(i%2)*280; y=850+(i//2)*310
        b+=rect(x,y,260,260,12,bg)+embed(LOGO/f'{n}.svg',x+24,y+24,212,212)+text(n,x,y+288,17)
    b+=text('TERMINAL / plain half-block text',990,1550,20)
    for i,line in enumerate((ROOT/'terminal/banner.txt').read_text().splitlines()):
        b+=text(line,990,1582+i*20,17)
    b+=text('Native 16 and 32 px colour and mono checks: pixel-check.png',48,1910,22)
    b+=text('SVG sources / librsvg exports / outlined JetBrains Mono Bold',48,1950,22)
    b+=text('Not affiliated with or endorsed by Omarchy.',48,2000,18)
    save(ROOT/'board.svg',b,1800,2050)
if __name__=='__main__': build()
