# omadials branding

Three initial explorations made on 2026-11-17. The maintainer selected v1-quadrant for refinement. Read [BRIEF.md](BRIEF.md) for the product, constraints and references.

## The three explorations

| Folder | Idea | Accent on graphite | Deep on paper |
|--------|------|--------------------|---------------|
| [v1-quadrant](explorations/v1-quadrant/) | Two corner arcs, an outer drag knob and inner toggles. The product, simplified. | Coral `#ff8c78`, 7.84:1 | `#a83e2c`, 5.58:1 |
| [v2-knob](explorations/v2-knob/) | One bold open sweep and a round knob. One gesture. | Cyan `#52d9e8`, 10.53:1 | `#006b78`, 5.61:1 |
| [v3-monogram](explorations/v3-monogram/) | A lowercase d with an inner concentric arc. The name in an initial. | Lavender `#c2a0ff`, 8.26:1 | `#7041ac`, 6.22:1 |

The family ground is graphite `#16181d`; the main mark and dark wordmark use near white `#f4f5f7`. Light previews use paper `#f4f3f0`. Each direction uses one accent hue, with a deep variant replacing it on light surfaces. Ratios use WCAG relative luminance from linearized sRGB. Unrounded results are recorded in [contrast.json](contrast.json).

Each folder contains `icon.svg` (transparent real vector master), `icon-light.svg`, `icon-mono.svg`, `icon-mono-dark.svg`, `icon-512.png`, `icon-32.png`, `icon-16.png`, `concept.svg` and its 1024 by 1024 `concept.png`, `wordmark.svg`, `wordmark-light.svg`, `lockup.svg`, `lockup-light.svg`, and `notes.md`.

Standard icons, wordmarks and lockups are for dark surfaces. The `-light` files use graphite lettering and the deep accent for light surfaces. `icon-mono.svg` is graphite on transparent; `icon-mono-dark.svg` is near white on transparent. All lettering reads `omadials` in lowercase.

Compare them in [board.html](board.html) or [board.png](board.png). Both show the master at 512 px, small sizes including 32 and 16 px, colour on light, both one-colour versions, wordmarks, lockups and contrast values. The HTML also links each concept sheet and notes. [pixel-check.png](pixel-check.png) enlarges the native 16 px colour exports with nearest-neighbour scaling.

## Round 2

The selected quadrant now has two refinements: [v1b-track](explorations/v1b-track/) uses two thin complete quarter tracks, opposing unequal fills, off-axis knobs and two inner toggles; [v1c-frame](explorations/v1c-frame/) adds a rounded L-shaped screen-corner edge. Both keep the arc origin empty and retain the coral and graphite palette, with deep coral on paper.

[board.html](board.html) and [board.png](board.png) compare the original with both refinements, including a locally drawn RSS shape for contrast. The original three-direction board is preserved as [board-round1.png](board-round1.png). Each new folder contains the full icon, wordmark, lockup, notes and concept file set, including vector concept sources.

The actual 16, 32 and 512 px PNG exports were visually inspected in [round2-review.png](round2-review.png). In my judgment neither refinement primarily reads as RSS or Wi-Fi at 16 px after reversing the inner fill. Track retains a faint quarter-fan association; frame makes the clearer control-panel silhouette. Knobs are clearer at 32 and 512 px. The native grid works without a separate small master.

Rebuild only Round 2 locally with `PYTHONDONTWRITEBYTECODE=1 python3 branding/tools/round2.py`. This uses librsvg, fontTools and Pillow, with no network or git. The earlier rebuild commands below regenerate Round 1 and should only be used when intentionally restoring that board.

## How they were made

- Original icon geometry drawn directly as SVG paths and circular arcs on a 16 by 16 coordinate grid. No raster artwork is embedded in the masters. The marks use no gradients, shadows or glow.
- JetBrains Mono Bold lettering converted into actual vector paths with fontTools. The installed source is `/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf`. Wordmarks need no installed font to render.
- Concept sheets are deterministic presentations of those same vectors, with palette swatches, computed contrast values and one-colour previews. No generated images were used at any step.
- `tools/build.py`, `tools/wordmark.py`, `tools/board.py` and `tools/board_fallback.py` were adapted from the supplied OmaBar tools for the omadials name, palette and original marks. Other copied kit tools are retained as reference and are not part of this exploration rebuild.
- Chromium was attempted for the board but could not start in the sandbox because its Crashpad socket operation was denied. `tools/board_fallback.py` produced the PNG with librsvg, using the actual vector artwork and outlined captions. The PNG is a comparison board, not a browser screenshot. Its source is `board.svg`; browser diagnostics are in `chromium.log`.
- All outputs, browser profile and cache paths stay inside `branding/`. No source files in OmaBarConfigurator or omagnet were edited. No commits, pushes or network uploads were made.

### Rebuild

```sh
python3 branding/tools/build.py
python3 branding/tools/board.py
python3 branding/tools/verify.py
```

Needs Python with fontTools, JetBrains Mono Bold, `rsvg-convert`, `magick` and `chromium`. Chromium failure automatically selects the librsvg fallback.

### Review

Every SVG was rendered with librsvg. Concept sheets, the comparison board, native 16 px exports and enlarged pixel views were visually checked. Ring gaps, the open dial and the d counter remain separate at small sizes. The board includes light and dark one-colour silhouettes. `tools/verify.py` verifies deliverable names, raster dimensions, path-only icon masters, outlined wordmarks, SVG rendering and contrast thresholds, and scans text files for U+2013 and U+2014. Its result is recorded in `verification.json`.

This is an exploration set. The chosen-direction production kit listed separately in the brief has not been commissioned by this task.

## Licence

Original artwork made for this project and released under the project's MIT licence unless the maintainer chooses otherwise. Not affiliated with or endorsed by Omarchy. JetBrains Mono is licensed under the SIL Open Font License; the wordmarks contain outlines only.
