"""SVG-first social cards, README banners and marketplace artwork."""
from final_common import *
URL = 'github.com/felipecpaiva/omadials'
TAG = "Turn, don't hunt."
def card(name,w,h,light=False,banner=False):
    bg,fg,ac=(PAPER,BG,DEEP) if light else (BG,WHITE,CORAL)
    suffix='-light' if light else ''
    # Two deliberate columns, with the frame mark given room to breathe.
    pad=int(w*.065); scale=w/1280
    body=rect(0,0,w,h,0,bg)
    body+=embed(LOGO/f'wordmark{suffix}.svg',pad,h*.19,w*.46,w*.46*96/420)
    body+=text(TAG,pad,h*(.78 if banner else .57),30*scale if banner else 38*scale,fg)
    if not banner:
        body+=text('Quick settings from the corner.',pad,h*.67,19*scale,fg)
        body+=text(URL,pad,h*.89,17*scale,fg)
        body+=text('Independent community project.',pad,h*.95,13*scale,fg)
    size=min(w*.29,h*.70)
    body+=embed(LOGO/f'icon{suffix}.svg',w-pad-size,(h-size)/2,size,size)
    save(ROOT/name,body,w,h)
if __name__=='__main__':
    card('social/github-social-preview.svg',1280,640)
    card('social/card-wide.svg',1200,630)
    card('social/card-wide-light.svg',1200,630,True)
    card('social/card-square.svg',1080,1080)
    card('social/banner-dark.svg',1600,400,banner=True)
    card('social/banner-light.svg',1600,400,True,True)
    # Marketplace uses brand artwork while the plugin is in development.
    card('social/marketplace-preview.svg',1280,720)
    png(ROOT/'social/marketplace-preview.svg',ROOT.parent/'preview.png')
    png(LOGO/'app-icon.svg',ROOT/'social/avatar-400.png',400,400)
