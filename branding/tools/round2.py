#!/usr/bin/env python3
"""Local Round 2 vector construction and librsvg exports."""
from wordmark import *
import math, shutil, xml.etree.ElementTree as ET
from PIL import Image

def arc(r,a,b,c,w):
    def pt(t):
        t=math.radians(t); return (2+r*math.cos(t),14-r*math.sin(t))
    x,y=pt(a); u,v=pt(b)
    return path(f'M{x:g} {y:g} A{r} {r} 0 0 {int(b<a)} {u:g} {v:g}',c,w)
def dial(frame,main,accent):
    s=''
    if frame: s+=path('M0.8 2.2V13.3Q0.8 15.2 2.7 15.2H13.8',main,.85)
    for r,end,c in [(11,53,accent),(7.3,65,main)]:
        s+=arc(r,90,0,main,.48)
        s+=arc(r,90 if r==11 else 0,end,c,1.25)
        x=2+r*math.cos(math.radians(end)); y=14-r*math.sin(math.radians(end))
        s+=dot(x,y,1.05,c)
    # Two toggle buttons sit on an implied inner concentric arc, never at its centre.
    for a in (28,72):
        s+=dot(2+3.5*math.cos(math.radians(a)),14-3.5*math.sin(math.radians(a)),.7,main)
    return s
variants=[('v1b-track',False,'Two independent dial tracks','Thin quarter tracks carry unequal thick fills and round knobs. Two inner toggle buttons float away from the empty origin.'),('v1c-frame',True,'Dials from a screen corner','A rounded L-shaped tile edge anchors the same two dials, making the empty corner read as a control panel.')]
for name,frame,title,idea in variants:
    d=ROOT/'explorations'/name; d.mkdir(exist_ok=True)
    for file,main,accent in [('icon',WHITE,'#ff8c78'),('icon-light',BG,'#a83e2c'),('icon-mono',BG,BG),('icon-mono-dark',WHITE,WHITE)]:
        (d/f'{file}.svg').write_text(svg(dial(frame,main,accent),512,512,'0 0 16 16'))
    for size in (512,32,16): png(d/'icon.svg',d/f'icon-{size}.png',size,size)
    for suffix,main,accent in [('',WHITE,'#ff8c78'),('-light',BG,'#a83e2c')]:
        shutil.copyfile(ROOT/'explorations/v1-quadrant'/f'wordmark{suffix}.svg',d/f'wordmark{suffix}.svg')
        (d/f'lockup{suffix}.svg').write_text(svg(f'<g transform="scale(6)">{dial(frame,main,accent)}</g>'+lettering('omadials',116,74,84,main),532,96))
    sheet=rect(0,0,1024,1024,0,BG)+lettering(name,48,64,32,'#ff8c78')+lettering(title,48,112,27,WHITE)
    sheet+=f'<g transform="translate(256 140) scale(32)">{dial(frame,WHITE,"#ff8c78")}</g>'
    sheet+=lettering('omadials',48,750,90,WHITE)+lettering('Unequal fills. Empty origin. Two toggles.',48,810,23,WHITE)
    sheet+=rect(48,852,440,136,8,PAPER)+f'<g transform="translate(200 864) scale(7)">{dial(frame,BG,"#a83e2c")}</g>'
    sheet+=f'<g transform="translate(620 864) scale(7)">{dial(frame,WHITE,WHITE)}</g>'
    (d/'concept.svg').write_text(svg(sheet,1024,1024)); png(d/'concept.svg',d/'concept.png')
    (d/'notes.md').write_text(f'''# {title}

{idea}

Construction: concentric quarter tracks on a 16 by 16 grid, centred at (2,14). Outer radius 11, inner radius 7.3. Tracks are 0.48 units, fills 1.25, knobs 2.1 in diameter. Outer fill ends at 53 degrees; inner fill runs from 0 to 65 degrees, in the opposite direction. The opposing fills and unequal travel distances prevent a regular signal-bar rhythm. Toggle centres sit on radius 3.5 at 28 and 72 degrees. There is no dot at the arc origin.

Palette: coral #ff8c78 on graphite #16181d; deep #a83e2c on paper #f4f3f0; near white #f4f5f7. Coral contrast 7.84:1; deep contrast 5.58:1. Mono versions use the same geometry without colour dependence.

At 16 px: the master uses the native 16-unit grid. Both track tails, unequal knobs and separated toggles remain visible. No separate small master is needed. The framed version adds a 0.85-unit rounded L edge with a clear gap below the tracks.

RSS comparison: unlike the reference dot plus two uniform arcs, these have an empty origin, two off-axis knobs, thin unfilled track tails and two displaced toggles. Visual review of 16, 32 and 512 px exports is recorded in the Round 2 review file. The quadrant family resemblance remains, but my judgment is that the mark reads as dials rather than RSS or Wi-Fi.

All PNGs are rendered from SVG with local librsvg. Wordmarks use the original outlined JetBrains Mono Bold artwork. icon.svg is for dark surfaces, icon-light.svg for light, icon-mono.svg is graphite and icon-mono-dark.svg is near white, all on transparency.

Original artwork made for this project, released under its MIT licence unless the maintainer chooses otherwise. Not affiliated with or endorsed by Omarchy.
''')
# Preserve the original board before replacing it, including on repeated builds.
if not (ROOT/'board-round1.png').exists(): shutil.copyfile(ROOT/'board.png',ROOT/'board-round1.png')
parts=[rect(0,0,1800,1730,0,PAPER)]
def label(x,y,t,size=20,c=BG): parts.append(lettering(t,x,y,size,c))
def embed(p,x,y,w,h):
    root=ET.parse(p).getroot(); box=list(map(float,root.attrib['viewBox'].split()))
    parts.append(f'<g transform="translate({x} {y}) scale({w/box[2]} {h/box[3]})">'+''.join(ET.tostring(e,encoding='unicode') for e in root)+'</g>')
label(32,52,'omadials / Round 2 / corner controls',32)
label(32,88,'Same quadrant concept. Different control silhouettes.',20)
names=['v1-quadrant']+[v[0] for v in variants]
html=['<!doctype html><html lang="en"><meta charset="utf-8"><title>omadials Round 2</title><style>body{background:#f4f3f0;color:#16181d;font:16px monospace;margin:24px}main{display:flex;gap:20px}article{width:544px;background:white;padding:16px}figure{margin:12px 0;padding:16px;background:#16181d;color:#f4f5f7}.light{background:#f4f3f0;color:#16181d}.row{display:flex;gap:28px;align-items:center}img{vertical-align:middle}a{color:inherit}</style><h1>omadials / Round 2</h1><p>Corner controls: original, track refinement and screen-corner refinement.</p><main>']
for i,name in enumerate(names):
    x=24+i*592; d=ROOT/'explorations'/name
    parts.append(rect(x,112,568,1250,12,'#ffffff')); label(x+16,150,name,26)
    parts.append(rect(x+12,174,544,544,8,BG)); embed(d/'icon.svg',x+28,190,512,512)
    label(x+16,751,'512 px / actual SVG',18)
    parts.append(rect(x+12,770,544,88,8,BG))
    for size,dx in [(64,28),(32,210),(16,394)]:
        embed(d/'icon.svg',x+dx,782+(64-size)/2,size,size); label(x+dx+size+8,820,str(size),16,WHITE)
    for j,(f,bg) in enumerate([('icon-light',PAPER),('icon-mono',PAPER),('icon-mono-dark',BG)]):
        parts.append(rect(x+12+j*180,880,172,152,8,bg)); embed(d/f'{f}.svg',x+38+j*180,892,128,128)
    label(x+16,1060,'Light colour / mono light / mono dark',16)
    for y,suffix,bg in [(1080,'',BG),(1210,'-light',PAPER)]:
        parts.append(rect(x+12,y,544,120,8,bg)); embed(d/f'lockup{suffix}.svg',x+28,y+12,512,93)
    base=f'explorations/{name}/'
    html.append(f'<article><h2>{name}</h2><figure><img src="{base}icon.svg" width="512" height="512"></figure><figure class="row">'+''.join(f'<span><img src="{base}icon-{s if s!=64 else 512}.png" width="{s}" height="{s}"> {s} px</span>' for s in (64,32,16))+'</figure><figure class="light row">'+''.join(f'<img src="{base}{f}.svg" width="128" height="128">' for f in ('icon-light','icon-mono'))+f'</figure><figure><img src="{base}icon-mono-dark.svg" width="128"><img src="{base}lockup.svg" width="512"></figure><figure class="light"><img src="{base}lockup-light.svg" width="512"></figure><p><a href="{base}concept.png">Concept</a> / <a href="{base}notes.md">Notes</a></p></article>')
rss=path('M3 2 A11 11 0 0 1 14 13',BG,1.8)+path('M3 6 A7 7 0 0 1 10 13',BG,1.8)+dot(3,13,1.1,BG)
label(32,1410,'RSS shape / hand-drawn reference silhouette',25)
for sz,x in [(128,32),(32,230),(16,330)]: parts.append(f'<g transform="translate({x} 1440) scale({sz/16})">{rss}</g>'); label(x,1598,f'{sz} px',16)
label(450,1480,'Reference: origin dot + two uniform arcs',20)
label(450,1520,'Refinements: empty origin + unequal dial knobs',20)
label(32,1686,'Coral #ff8c78 / graphite #16181d / deep #a83e2c / paper #f4f3f0',20)
(ROOT/'board.svg').write_text(svg(''.join(parts),1800,1730)); png(ROOT/'board.svg',ROOT/'board.png')
html.append('</main><section><h2>RSS shape</h2><p>Hand-drawn reference silhouette: origin dot and two uniform arcs.</p>'+svg(rss,128,128,'0 0 16 16')+svg(rss,32,32,'0 0 16 16')+svg(rss,16,16,'0 0 16 16')+'</section><p>Coral #ff8c78 on graphite #16181d. Deep #a83e2c on paper #f4f3f0. Independent project, not affiliated with or endorsed by Omarchy.</p></html>')
(ROOT/'board.html').write_text(''.join(html))
# A review sheet composites the actual PNG exports without resampling the native examples.
review=Image.new('RGB',(1800,850),BG)
for i,name in enumerate(names):
    d=ROOT/'explorations'/name
    for size,y in [(512,0),(32,540),(16,610)]:
        im=Image.open(d/f'icon-{size}.png'); review.paste(im,(i*600+20,y),im)
    im=Image.open(d/'icon-16.png').resize((160,160),Image.Resampling.NEAREST); review.paste(im,(i*600+220,610),im)
review.save(ROOT/'round2-review.png')
