#!/usr/bin/env python3
"""Build the HTML board; try Chromium, then use a vector comparison board."""
from wordmark import *
import os
os.environ['XDG_CACHE_HOME']=str(ROOT/'.cache')
os.environ['XDG_CONFIG_HOME']=str(ROOT/'.browser-config')
parts=['''<!doctype html><html lang="en"><meta charset="utf-8"><title>omadials / three explorations</title><style>
*{box-sizing:border-box}body{margin:32px;background:#f4f3f0;color:#16181d;font:16px/1.5 'JetBrains Mono',monospace}h1{margin:0}main{display:grid;grid-template-columns:repeat(3,584px);gap:22px}article{background:white;border-radius:14px;padding:20px}h2{font-size:24px}figure{margin:20px 0;padding:16px;border-radius:10px}img{display:block;max-width:100%}.dark{background:#16181d;color:#f4f5f7}.light{background:#f4f3f0}.row{display:flex;align-items:center;gap:32px}.swatch{width:120px;height:40px;border-radius:5px}small{font-size:13px}figcaption{margin-top:10px}footer{margin-top:28px}</style><h1>omadials / three explorations</h1><p>From the corner. Turn, do not hunt. Original vectors / 16 px grid.</p><main>''']
for v in DIRECTIONS:
    p='explorations/'+v['folder']
    parts.append(f'<article><h2>{v["folder"]}</h2><p>{v["title"]}</p><figure class="dark"><img src="{p}/icon.svg" width="512" height="512"><figcaption>512 px vector master</figcaption></figure><figure class="dark row">')
    for s in (64,32,16): parts.append(f'<div><img src="{p}/icon-{s if s!=64 else 512}.png" width="{s}" height="{s}"><small>{s} px</small></div>')
    parts.append('</figure><div class="row" style="gap:8px">')
    for file,bg,label in [('icon-light','light','Colour light'),('icon-mono','light','Mono light'),('icon-mono-dark','dark','Mono dark')]:
        parts.append(f'<figure class="{bg}"><img src="{p}/{file}.svg" width="112" height="112"><figcaption>{label}</figcaption></figure>')
    parts.append('</div>')
    for suffix,bg in [('', 'dark'),('-light','light')]:
        parts.append(f'<figure class="{bg}"><img src="{p}/wordmark{suffix}.svg" width="420" height="96"><img src="{p}/lockup{suffix}.svg" width="512" height="93"></figure>')
    parts.append('<div class="row" style="gap:10px">')
    for c in [BG,WHITE,v['accent'],v['deep']]: parts.append(f'<div><div class="swatch" style="background:{c}"></div><small>{c}</small></div>')
    parts.append(f'</div><p>Accent / graphite {contrast(v["accent"],BG):.2f}:1<br>Deep / paper {contrast(v["deep"],PAPER):.2f}:1</p><p>{v["idea"]}</p><a href="{p}/concept.png">1024 px concept sheet</a> / <a href="{p}/notes.md">Notes</a></article>')
parts.append('</main><footer>Independent project. Not affiliated with or endorsed by Omarchy.</footer></html>')
(ROOT/'board.html').write_text('\n'.join(parts))
try:
    r=subprocess.run(['chromium','--headless','--disable-gpu','--no-sandbox','--disable-crash-reporter','--hide-scrollbars',f'--user-data-dir={ROOT}/.chromium-profile','--window-size=1860,2300',f'--screenshot={ROOT}/board.png','file://'+str(ROOT/'board.html')],capture_output=True,timeout=25)
    (ROOT/'chromium.log').write_bytes(r.stderr)
    if r.returncode: raise RuntimeError('Chromium failed')
    print('Board PNG rendered with Chromium')
except (RuntimeError,subprocess.TimeoutExpired):
    from board_fallback import render
    render(); print('Chromium unavailable; board PNG rendered with librsvg fallback')
