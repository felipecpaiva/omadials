"""Outlined JetBrains Mono Bold wordmarks and horizontal lockups."""
from final_common import *
for kind in ('wordmark','lockup'):
    w=420 if kind=='wordmark' else 532
    for suffix,ink in [('',WHITE),('-light',BG)]:
        # Rebuild lettering with fontTools, retaining the exploration's metrics.
        body=text('omadials',8 if kind=='wordmark' else 116,74,84,ink)
        if kind=='lockup': body=embed(LOGO/f'icon{suffix}.svg',0,0,96,96)+body
        save(LOGO/f'{kind}{suffix}.svg',body,w,96)
        surface='dark' if not suffix else 'paper'
        save(LOGO/f'{kind}-on-{surface}.svg',rect(0,0,w+48,144,0,BG if not suffix else PAPER)+f'<g transform="translate(24 24)">{body}</g>',w+48,144)
