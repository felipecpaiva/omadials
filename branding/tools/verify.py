#!/usr/bin/env python3
"""Check the complete exploration deliverables and record reproducible results."""
from wordmark import *
import json
import xml.etree.ElementTree as ET
expected=['icon.svg','icon-mono.svg','icon-light.svg','icon-mono-dark.svg','icon-512.png','icon-32.png','icon-16.png','concept.png','wordmark.svg','wordmark-light.svg','lockup.svg','lockup-light.svg','notes.md']
count=0
for v in DIRECTIONS:
    d=ROOT/'explorations'/v['folder']
    for name in expected: assert (d/name).is_file(),name
    for size in (16,32,512):
        dim=subprocess.check_output(['magick','identify','-format','%wx%h',str(d/f'icon-{size}.png')],text=True)
        assert dim==f'{size}x{size}'
    assert subprocess.check_output(['magick','identify','-format','%wx%h',str(d/'concept.png')],text=True)=='1024x1024'
    for p in d.glob('icon*.svg'):
        root=ET.parse(p).getroot()
        assert all(e.tag.split('}')[-1] in ('svg','path','g') for e in root.iter())
    for p in d.glob('wordmark*.svg'):
        root=ET.parse(p).getroot(); assert len(root.findall('.//{*}path'))==8
        assert not root.findall('.//{*}text')
    assert contrast(v['accent'],BG)>=3
    assert contrast(v['deep'],PAPER)>=4.5
for name in ('board.html','board.png','README.md'): assert (ROOT/name).is_file()
check=ROOT/'.verify-render.png'
for p in ROOT.rglob('*.svg'):
    png(p,check,64,64); count+=1
check.unlink()
scanned=0
for p in ROOT.rglob('*'):
    if p.is_file() and p.suffix in ('.py','.md','.html','.svg','.json','.log','.txt'):
        s=p.read_text(errors='replace')
        assert chr(0x2013) not in s and chr(0x2014) not in s,str(p)
        scanned+=1
result={'status':'passed','directions':3,'required_files_per_direction':len(expected),'svg_renders':count,'text_files_scanned':scanned,'contrast':'All accents >= 3:1 on graphite; all deep variants >= 4.5:1 on paper','raster_dimensions':'passed','masters':'path-only icons; eight outlined glyphs per wordmark','dash_scan':'passed'}
(ROOT/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
