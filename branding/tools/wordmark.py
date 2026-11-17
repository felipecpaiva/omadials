#!/usr/bin/env python3
"""Shared omadials vector geometry and outlined JetBrains Mono Bold lettering."""
from pathlib import Path
import subprocess
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
ROOT = Path(__file__).resolve().parents[1]
FONT = Path('/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf')
BG, WHITE, PAPER = '#16181d', '#f4f5f7', '#f4f3f0'
font = TTFont(FONT)
glyphs, cmap = font.getGlyphSet(), font.getBestCmap()
def svg(body,w,h,view=None):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{view or f"0 0 {w} {h}"}">{body}</svg>\n'
def lettering(text,x,baseline,size,fill):
    scale=size/font['head'].unitsPerEm
    paths=[]
    for ch in text:
        g=glyphs[cmap[ord(ch)]]; pen=SVGPathPen(glyphs); g.draw(pen)
        paths.append(f'<path d="{pen.getCommands()}" transform="translate({x:g} {baseline:g}) scale({scale:g} {-scale:g})"/>')
        x+=g.width*scale
    return f'<g fill="{fill}">'+''.join(paths)+'</g>'
def rect(x,y,w,h,r,c):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{c}"/>'
def path(d,c,width):
    return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'
def dot(x,y,r,c):
    return f'<path fill="{c}" d="M{x-r} {y}a{r} {r} 0 1 0 {2*r} 0a{r} {r} 0 1 0 {-2*r} 0Z"/>'
def mark(kind,main,accent):
    if kind=='quadrant':
        return (path('M2 3A11 11 0 0 1 13 14',main,1.8)
          +path('M2 3A11 11 0 0 1 10.67 7.23',accent,1.8)+dot(10.67,7.23,1.5,accent)
          +path('M2 7A7 7 0 0 1 9 14',main,1.8)+dot(2,11,1,main)+dot(5,14,1,main))
    if kind=='knob':
        return (path('M4.46 11.54A5 5 0 1 1 11.54 11.54',main,2.4)
          +path('M13 8A5 5 0 0 1 11.54 11.54',accent,2.4)+dot(11.54,11.54,1.8,accent))
    return (path('M13 2V10A5 5 0 1 1 8 5H13',main,2)
       +path('M10 10A2 2 0 1 1 8 8',accent,1.4))
def png(src,out,w=None,h=None):
    subprocess.run(['rsvg-convert']+(['-w',str(w)] if w else [])+(['-h',str(h)] if h else [])+['-o',str(out),str(src)],check=True)
def luminance(h):
    rgb=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return sum(c*w for c,w in zip([v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb],[.2126,.7152,.0722]))
def contrast(a,b):
    x,y=sorted([luminance(a),luminance(b)])
    return (y+.05)/(x+.05)
DIRECTIONS=[
 dict(folder='v1-quadrant',kind='quadrant',accent='#ff8c78',deep='#a83e2c',title='From the corner',tag='Sweep your settings.',idea='Two quarter arcs grow from a bottom-left anchor. A coral outer sweep ends in a round drag knob; two inner dots suggest toggles.',small='The 1.8 px rings leave 2.2 px radial gaps. The two 2 px toggles stay separate from the inner ring. The knob adds a local bulge, even in one colour.'),
 dict(folder='v2-knob',kind='knob',accent='#52d9e8',deep='#006b78',title='One gesture',tag='Turn, then carry on.',idea='A single bold open dial ends in a cyan round knob. The empty centre and open lower sector focus the mark on one sweeping gesture.',small='The 2.4 px stroke and broad empty centre hold at 16 px. A 3.6 px knob makes the endpoint wider than the arc. The lower opening stays clear in one colour.'),
 dict(folder='v3-monogram',kind='monogram',accent='#c2a0ff',deep='#7041ac',title='The dial d',tag='The name in a turn.',idea='A lowercase d has an upright stem and a circular bowl. A second concentric, open arc inside the bowl turns the initial into plural dials.',small='The 2 px outer bowl and stem carry the lowercase d silhouette. The inner arc is 1.4 px wide with a 1.3 px radial gap. It remains a separate arc in one colour.')]
