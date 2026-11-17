"""Shared SVG composition for the final kit. No browser required."""
from wordmark import *
import xml.etree.ElementTree as ET
CORAL, DEEP = '#ff8c78', '#a83e2c'
LOGO = ROOT/'logo'
CHOSEN = ROOT/'explorations/v1c-frame'
def embed(p,x,y,w,h):
    root=ET.parse(p).getroot()
    vx,vy,vw,vh=map(float,root.attrib['viewBox'].split())
    body=''.join(ET.tostring(e,encoding='unicode') for e in root)
    return f'<g transform="translate({x} {y}) scale({w/vw} {h/vh}) translate({-vx} {-vy})">{body}</g>'
def save(p,body,w,h):
    p=Path(p); p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(svg(body,w,h)); png(p,p.with_suffix('.png'))
def text(s,x,y,size=20,c=BG): return lettering(s,x,y,size,c)
