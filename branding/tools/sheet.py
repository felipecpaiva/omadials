"""One-page brand sheet and numerical WCAG sRGB contrast record."""
from final_common import *
import json
pairs=[('Coral / graphite',CORAL,BG),('Deep / paper',DEEP,PAPER),('Near white / graphite',WHITE,BG),('Graphite / paper',BG,PAPER),('Deep / near white',DEEP,WHITE),('Coral / paper',CORAL,PAPER)]
def build():
    b=rect(0,0,1400,1700,0,PAPER)+embed(LOGO/'lockup-light.svg',64,52,665,120)
    b+=text('BRAND SHEET / v1c-frame',64,220,24)
    b+=text("Turn, don't hunt.",64,268,32)
    b+=text('Quick settings from a screen corner.',64,306,20)
    for i,(name,bg) in enumerate([('icon',BG),('icon-light',PAPER),('icon-mono',PAPER),('icon-mono-dark',BG)]):
        x=64+i*318
        b+=rect(x,346,284,210,12,bg)+embed(LOGO/f'{name}.svg',x+58,365,168,168)+text(name,x,590,17)
    b+=text('01 / PALETTE AND CONTRAST',64,658,24)
    for i,(name,c) in enumerate([('Graphite',BG),('Near white',WHITE),('Coral',CORAL),('Deep',DEEP),('Paper',PAPER)]):
        x=64+i*256
        b+=rect(x,688,224,60,6,c)+text(name,x,778,18)+text(c,x,805,18)
    for i,(label,a,c) in enumerate(pairs):
        x=64+(i%2)*650; y=854+(i//2)*36
        b+=text(f'{label}: {contrast(a,c):.2f}:1',x,y,19)
    lines=[
      (1000,'02 / TYPE AND SPACING',24),
      (1040,'JetBrains Mono Bold: wordmark and headings. Regular: body.',20),
      (1076,'Lowercase omadials. Say "oh-ma-dials". Wordmark is outlined.',20),
      (1112,'16-unit icon grid. Clear space: 2 units beyond the SVG bounds.',20),
      (1148,'Minimum icon: 16 px. Minimum lockup: 180 px wide.',20),
      (1184,'Layout unit: 8 px. Gaps: 16 or 24 px. Card padding: 6.5%.',20),
      (1250,'03 / DO',24),
      (1290,'Use coral on graphite and deep on light surfaces.',20),
      (1326,'Keep the frame, unequal sweeps, knobs and toggles intact.',20),
      (1362,'Use supplied vectors and retain clear space.',20),
      (1420,'04 / DO NOT',24),
      (1460,'Do not stretch, rotate, recolour or add glow or gradients.',20),
      (1496,'Do not use coral on paper: below 3:1. Text needs 4.5:1.',20),
      (1532,"Do not use Omarchy's logo or imply official endorsement.",20),
      (1600,'Original artwork: MIT. Typeface: SIL Open Font License.',17),
      (1634,'Not affiliated with or endorsed by Omarchy.',17)]
    for y,s,z in lines: b+=text(s,64,y,z)
    save(ROOT/'brand-sheet.svg',b,1400,1700)
    (ROOT/'contrast-final.json').write_text(json.dumps([dict(pair=n,foreground=a,background=c,ratio=contrast(a,c)) for n,a,c in pairs],indent=2)+'\n')
    (ROOT/'brand-sheet.html').write_text('<!doctype html><meta charset="utf-8"><title>omadials brand sheet</title><style>body{margin:0;background:#f4f3f0}img{display:block;width:100%;max-width:1400px}@media print{@page{size:A4;margin:0}img{width:210mm;height:255mm}}</style><img src="brand-sheet.svg" alt="omadials brand guidelines: palette, contrast, type, spacing and usage">')
if __name__=='__main__': build()
