# omadials brand kit

Chosen direction: v1c-frame. The original exploration files are preserved.

Start with [board.png](board.png), the full overview. Inspect [pixel-check.png](pixel-check.png) for native 16 and 32 px icons and nearest-neighbour enlargements.

## Usage

`logo/icon.svg` is the transparent colour master for dark surfaces. `icon-light.svg` uses deep coral on light. `icon-mono.svg` is graphite on transparency; `icon-mono-dark.svg` is near white. Each has PNG exports at 1024, 512, 256, 128, 64, 32 and 16 px. `mask.svg` is a pure black silhouette on transparency, with a 512 px PNG. Use its alpha channel for masking. `app-icon.svg` adds a graphite tile for avatar slots.

Wordmarks and lockups without a surface suffix are transparent for dark surfaces; `-light` is transparent for light. `-on-dark` and `-on-paper` include backgrounds. All lettering is JetBrains Mono Bold converted to paths with fontTools. PNGs come from SVG via rsvg-convert.

README banners: `social/banner-dark.png` and `social/banner-light.png`, 1600 by 400, with the tagline "Turn, don't hunt."

Marketplace preview: [../preview.png](../preview.png), 1280 by 720. This is brand artwork, not a screenshot of a working plugin. Its source is `social/marketplace-preview.svg`. Feature demos are deferred until the plugin exists.

## Contrast

WCAG sRGB relative luminance, calculated from the palette hex values:

| Pair | Ratio |
|---|---:|
| Coral #ff8c78 / graphite #16181d | 7.84:1 |
| Deep #a83e2c / paper #f4f3f0 | 5.58:1 |
| Near white #f4f5f7 / graphite | 16.28:1 |
| Graphite / paper | 16.00:1 |
| Deep / near white | 5.68:1 |
| Coral / paper | 2.04:1, do not use |

## Rebuild

Run `python3 branding/tools/<script>.py` from the repo root in this order: `logo`, `kit`, `social`, `sheet`, `terminal`, `final_board`. Requires Python, fontTools, Pillow, JetBrains Mono Nerd Font Bold and rsvg-convert. No browser is used. Exploration builders are separate and are not part of this rebuild.

## Verification

Reviewed the final overview, social card, one-page sheet and 16/32 px colour and monochrome pixel checks. The chosen native 16-unit geometry retains separate arcs and toggles without hinting. Social preview is 1280 by 640 and below 1 MB. All final SVG artwork uses paths for text. No em dash or en dash in final text. No Omarchy logo is included.

## Final files

- [logo/app-icon.png](logo/app-icon.png)
- [logo/app-icon.svg](logo/app-icon.svg)
- [logo/icon-1024.png](logo/icon-1024.png)
- [logo/icon-128.png](logo/icon-128.png)
- [logo/icon-16.png](logo/icon-16.png)
- [logo/icon-256.png](logo/icon-256.png)
- [logo/icon-32.png](logo/icon-32.png)
- [logo/icon-512.png](logo/icon-512.png)
- [logo/icon-64.png](logo/icon-64.png)
- [logo/icon-light-1024.png](logo/icon-light-1024.png)
- [logo/icon-light-128.png](logo/icon-light-128.png)
- [logo/icon-light-16.png](logo/icon-light-16.png)
- [logo/icon-light-256.png](logo/icon-light-256.png)
- [logo/icon-light-32.png](logo/icon-light-32.png)
- [logo/icon-light-512.png](logo/icon-light-512.png)
- [logo/icon-light-64.png](logo/icon-light-64.png)
- [logo/icon-light.svg](logo/icon-light.svg)
- [logo/icon-mono-1024.png](logo/icon-mono-1024.png)
- [logo/icon-mono-128.png](logo/icon-mono-128.png)
- [logo/icon-mono-16.png](logo/icon-mono-16.png)
- [logo/icon-mono-256.png](logo/icon-mono-256.png)
- [logo/icon-mono-32.png](logo/icon-mono-32.png)
- [logo/icon-mono-512.png](logo/icon-mono-512.png)
- [logo/icon-mono-64.png](logo/icon-mono-64.png)
- [logo/icon-mono-dark-1024.png](logo/icon-mono-dark-1024.png)
- [logo/icon-mono-dark-128.png](logo/icon-mono-dark-128.png)
- [logo/icon-mono-dark-16.png](logo/icon-mono-dark-16.png)
- [logo/icon-mono-dark-256.png](logo/icon-mono-dark-256.png)
- [logo/icon-mono-dark-32.png](logo/icon-mono-dark-32.png)
- [logo/icon-mono-dark-512.png](logo/icon-mono-dark-512.png)
- [logo/icon-mono-dark-64.png](logo/icon-mono-dark-64.png)
- [logo/icon-mono-dark.svg](logo/icon-mono-dark.svg)
- [logo/icon-mono.svg](logo/icon-mono.svg)
- [logo/icon.svg](logo/icon.svg)
- [logo/lockup-light.png](logo/lockup-light.png)
- [logo/lockup-light.svg](logo/lockup-light.svg)
- [logo/lockup-on-dark.png](logo/lockup-on-dark.png)
- [logo/lockup-on-dark.svg](logo/lockup-on-dark.svg)
- [logo/lockup-on-paper.png](logo/lockup-on-paper.png)
- [logo/lockup-on-paper.svg](logo/lockup-on-paper.svg)
- [logo/lockup.png](logo/lockup.png)
- [logo/lockup.svg](logo/lockup.svg)
- [logo/mask-512.png](logo/mask-512.png)
- [logo/mask.svg](logo/mask.svg)
- [logo/wordmark-light.png](logo/wordmark-light.png)
- [logo/wordmark-light.svg](logo/wordmark-light.svg)
- [logo/wordmark-on-dark.png](logo/wordmark-on-dark.png)
- [logo/wordmark-on-dark.svg](logo/wordmark-on-dark.svg)
- [logo/wordmark-on-paper.png](logo/wordmark-on-paper.png)
- [logo/wordmark-on-paper.svg](logo/wordmark-on-paper.svg)
- [logo/wordmark.png](logo/wordmark.png)
- [logo/wordmark.svg](logo/wordmark.svg)
- [social/avatar-400.png](social/avatar-400.png)
- [social/banner-dark.png](social/banner-dark.png)
- [social/banner-dark.svg](social/banner-dark.svg)
- [social/banner-light.png](social/banner-light.png)
- [social/banner-light.svg](social/banner-light.svg)
- [social/card-square.png](social/card-square.png)
- [social/card-square.svg](social/card-square.svg)
- [social/card-wide-light.png](social/card-wide-light.png)
- [social/card-wide-light.svg](social/card-wide-light.svg)
- [social/card-wide.png](social/card-wide.png)
- [social/card-wide.svg](social/card-wide.svg)
- [social/github-social-preview.png](social/github-social-preview.png)
- [social/github-social-preview.svg](social/github-social-preview.svg)
- [social/marketplace-preview.png](social/marketplace-preview.png)
- [social/marketplace-preview.svg](social/marketplace-preview.svg)
- [terminal/banner.ansi](terminal/banner.ansi)
- [terminal/banner.txt](terminal/banner.txt)
- [terminal/lettering.png](terminal/lettering.png)
- [terminal/lettering.svg](terminal/lettering.svg)
- [board.svg](board.svg)
- [board.png](board.png)
- [pixel-check.png](pixel-check.png)
- [brand-sheet.svg](brand-sheet.svg)
- [brand-sheet.png](brand-sheet.png)
- [brand-sheet.html](brand-sheet.html)
- [contrast-final.json](contrast-final.json)
- [Marketplace preview](../preview.png)

## Licence

Original artwork released under the project's MIT licence unless the maintainer chooses otherwise. JetBrains Mono is under the SIL Open Font License. Not affiliated with or endorsed by Omarchy.
