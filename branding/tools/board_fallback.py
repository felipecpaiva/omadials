#!/usr/bin/env python3
"""Render the omadials comparison board with actual nested vector artwork."""
from wordmark import *
import html
import xml.etree.ElementTree as ET

def render():
    parts=[rect(0,0,1860,2020,0,PAPER)]
    def text(x,y,s,size=18,c=BG): parts.append(lettering(s,x,y,size,c))
    def image(p,x,y,w,h):
        root=ET.parse(p).getroot()
        vw,vh=map(float,root.attrib.get('viewBox',f'0 0 {root.attrib["width"]} {root.attrib["height"]}').split()[2:])
        body=''.join(ET.tostring(e,encoding='unicode') for e in root)
        parts.append(f'<g transform="translate({x} {y}) scale({w/vw} {h/vh})">{body}</g>')
    text(32,58,'omadials / three explorations',34)
    text(32,94,'From the corner. Turn, do not hunt. Original vectors / 16 px grid.',20)
    for i,v in enumerate(DIRECTIONS):
        x=32+i*606; d=ROOT/'explorations'/v['folder']
        parts.append(rect(x,126,584,1830,14,'#ffffff'))
        text(x+24,170,v['folder'],25)
        text(x+24,208,v['title'],20)
        parts.append(rect(x+20,232,544,544,10,BG)); image(d/'icon.svg',x+36,248,512,512)
        text(x+28,806,'512 px master / transparent on graphite',17)
        parts.append(rect(x+20,830,544,120,10,BG))
        image(d/'icon.svg',x+40,854,64,64); text(x+120,886,'64',16,WHITE)
        image(d/'icon.svg',x+220,870,32,32); text(x+266,886,'32',16,WHITE)
        image(d/'icon.svg',x+400,878,16,16); text(x+430,886,'16',16,WHITE)
        text(x+24,988,'COLOUR LIGHT / MONO LIGHT / MONO DARK',16)
        for name,offset,bg in [('icon-light',20,PAPER),('icon-mono',204,PAPER),('icon-mono-dark',388,BG)]:
            parts.append(rect(x+offset,1010,176,160,10,bg)); image(d/f'{name}.svg',x+offset+32,1034,112,112)
        for suffix,bg,y in [('',BG,1200),('-light',PAPER,1420)]:
            parts.append(rect(x+20,y,544,196,10,bg))
            image(d/f'wordmark{suffix}.svg',x+40,y+16,420,96)
            image(d/f'lockup{suffix}.svg',x+40,y+104,480,86)
        text(x+24,1662,'PALETTE / WCAG CONTRAST',18)
        for j,c in enumerate([BG,WHITE,v['accent'],v['deep']]):
            parts.append(rect(x+24+j*136,1686,120,40,5,c)); text(x+24+j*136,1750,c,15)
        text(x+24,1796,f'Accent / graphite {contrast(v["accent"],BG):.2f}:1',19)
        text(x+24,1832,f'Deep / paper {contrast(v["deep"],PAPER):.2f}:1',19)
        text(x+24,1890,v['tag'],21)
    text(32,1998,'Independent project. Not affiliated with or endorsed by Omarchy. Rendered from SVG with librsvg.',16)
    (ROOT/'board.svg').write_text(svg(''.join(parts),1860,2020)); png(ROOT/'board.svg',ROOT/'board.png')
if __name__=='__main__': render()
