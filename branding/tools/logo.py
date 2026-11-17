"""Export the chosen v1c-frame master and surface variants with librsvg."""
from final_common import *
import shutil
LOGO.mkdir(exist_ok=True)
for name in ('icon','icon-light','icon-mono','icon-mono-dark'):
    shutil.copyfile(CHOSEN/f'{name}.svg',LOGO/f'{name}.svg')
    for s in (1024,512,256,128,64,32,16):
        png(LOGO/f'{name}.svg',LOGO/f'{name}-{s}.png',s,s)
# Pure black, transparent outside the silhouette: alpha/luminance mask master.
s=(LOGO/'icon-mono.svg').read_text().replace(BG,'#000000')
(LOGO/'mask.svg').write_text(s)
png(LOGO/'mask.svg',LOGO/'mask-512.png',512,512)
# Optional graphite tile avatar, without changing the chosen glyph geometry.
save(LOGO/'app-icon.svg',rect(0,0,512,512,72,BG)+embed(LOGO/'icon.svg',48,48,416,416),512,512)
