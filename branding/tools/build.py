#!/usr/bin/env python3
"""Rebuild omadials explorations. All output stays inside branding/."""
from wordmark import *
import json
ratios={}
for v in DIRECTIONS:
    folder,kind,accent,deep=[v[k] for k in ('folder','kind','accent','deep')]
    d=ROOT/'explorations'/folder; d.mkdir(parents=True,exist_ok=True)
    a,b=contrast(accent,BG),contrast(deep,PAPER)
    assert a>=3 and b>=4.5
    ratios[folder]={'accent':accent,'on_graphite':a,'deep':deep,'on_paper':b}
    for name,main,c in [('icon',WHITE,accent),('icon-light',BG,deep),('icon-mono',BG,BG),('icon-mono-dark',WHITE,WHITE)]:
        (d/f'{name}.svg').write_text(svg(mark(kind,main,c),512,512,'0 0 16 16'))
    for suffix,main,c in [('',WHITE,accent),('-light',BG,deep)]:
        (d/f'wordmark{suffix}.svg').write_text(svg(lettering('omadials',8,74,84,main),420,96))
        (d/f'lockup{suffix}.svg').write_text(svg(f'<g transform="scale(6)">{mark(kind,main,c)}</g>'+lettering('omadials',116,74,84,main),532,96))
    for size in (512,32,16): png(d/'icon.svg',d/f'icon-{size}.png',size,size)
    sheet=rect(0,0,1024,1024,0,BG)+lettering(folder.upper(),56,68,26,accent)
    sheet+=lettering(v['title'],56,116,32,WHITE)
    sheet+=f'<g transform="translate(312 132) scale(25)">{mark(kind,WHITE,accent)}</g>'
    sheet+=lettering('omadials',56,626,92,WHITE)+lettering(v['tag'],56,680,26,WHITE)
    sheet+=rect(56,716,912,1,0,'#555963')
    for i,(c,label) in enumerate([(BG,'16181D'),(WHITE,'F4F5F7'),(accent,accent[1:].upper()),(deep,deep[1:].upper())]):
        x=56+i*232
        sheet+=rect(x,750,48,44,6,c)+lettering(label,x+58,780,20,WHITE)
    sheet+=lettering(f'Accent / graphite {a:.2f}:1',56,834,20,WHITE)
    sheet+=lettering(f'Deep / paper {b:.2f}:1',536,834,20,WHITE)
    sheet+=rect(56,866,208,112,10,PAPER)
    sheet+=f'<g transform="translate(120 874) scale(6)">{mark(kind,BG,BG)}</g>'
    sheet+=f'<g transform="translate(312 874) scale(6)">{mark(kind,WHITE,WHITE)}</g>'
    sheet+=rect(488,866,208,112,10,PAPER)+f'<g transform="translate(552 874) scale(6)">{mark(kind,BG,deep)}</g>'
    sheet+=lettering('MONO + LIGHT',728,920,20,WHITE)
    (d/'concept.svg').write_text(svg(sheet,1024,1024)); png(d/'concept.svg',d/'concept.png')
    (d/'notes.md').write_text(f'''# {v['title']}

{v['idea']}

Palette: graphite {BG}; near white {WHITE}; paper {PAPER}; accent {accent}; deep accent {deep}. WCAG sRGB contrast: accent on graphite {a:.2f}:1 (minimum 3:1); deep on paper {b:.2f}:1 (minimum 4.5:1). Deep replaces the accent in light icons and lockups.

Own silhouette: curved dial geometry differs from Omarchy's chunky pixel mark, omagnet's four-part snap grid and OmaBar's horizontal pills on a rail. This direction uses {'a corner-anchored quarter fan' if kind=='quadrant' else 'one open circular sweep with a knob' if kind=='knob' else 'an asymmetric lowercase d with a concentric arc counter'}.

At 16 px: {v['small']}

Typeface: lowercase omadials in JetBrains Mono Bold, outlined with fontTools. All icons are transparent; icon.svg is for dark, icon-light.svg for light, icon-mono.svg is graphite and icon-mono-dark.svg is near white. Wordmarks and lockups follow the same surface naming.

Construction: original paths and circular arcs on a 16 by 16 grid. PNG exports and the 1024 px concept sheet are rendered from those real vectors with librsvg. No generated images, embedded raster masters, gradients, shadows or glow.

Original artwork made for this project, released under the project's MIT licence unless the maintainer chooses otherwise. Not affiliated with or endorsed by Omarchy.
''')
(ROOT/'contrast.json').write_text(json.dumps(ratios,indent=2)+'\n')
print(json.dumps(ratios,indent=2))
