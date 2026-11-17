# omadials references (learning only, no code copied)

Read 2026-11-17. denon.corner at `e4f2b6a` (MIT). aryal.control-center v1.3.5 (untrusted, nothing run).
Paths: D = `omarchy-dotfiles/plugins`, A = the aryal clone.

## 1. denon.corner

### Structure
- `D/denon.corner/Corner.qml` (381 lines): state, widgets and gestures in one file. It is a `Panel` of the denon bar (`:20`), so it is welded to that bar. Learn from it, do not reuse.
- `D/denon.bar/panels/PanelHost.qml`: full-screen overlay, fan shape, open animation (`:177-202`, `:253-259`). `PopupPanel.qml`: places the card at the rail corner (`:70`). `PanelMotion.qml`: hover coordinator, 65 or 170 ms delay (`:94`).
- `D/denon.shell/Bar.qml:1829-1841`: hot corner, an invisible 18 px strip with a `HoverHandler`.
- Screenshot: quarter disc bottom-left, three arcs (brightness, volume, mic) with a number at each top end, round toggles on an inner arc, big battery percent, profile and Record below.

### Interaction model
- Open: hot corner hover, or a rail grip (`Corner.qml:129-131`). The overlay takes keyboard focus (`PanelHost.qml:38`).
- Drag: one `MouseArea` over the fan (`:283-320`). Press picks a ring, moves update it. Wheel gives 5 percent per notch (`:314`). Brightness uses a draft applied on release (`:299`, `:311`).
- Toggles: left click flips state at once, re-read after 450 ms (`:71`). Right click opens the stock panel (`:240`).
- Close: Escape (`:257`). Profile label cycles on click (`:111`).

### Geometry (plain words and formulas)
Work in a square of side R (denon: R = 440 scaled units). The center of every arc is the screen corner. In item coordinates for the bottom-left corner, the center is `(0, R)`.

1. **Polar mapping** (`:287-290`). For a point `(x, y)`: `dx = x`, `dy = R - y`. Distance `d = sqrt(dx*dx + dy*dy)`. Angle `a = atan2(dx, dy)`. This angle is measured from straight up (the vertical screen edge) toward the right. Value `f = clamp(a / (pi/2), 0, 1)`. So `f = 0` on the vertical edge and `f = 1` on the horizontal edge.
2. **Ring picking** (`:291-297`). Rings have radii `R-40`, `R-90`, `R-140`. A press picks the ring whose radius is within 24 of `d`. No match means the press is ignored, so toggles and labels still get it. The ring is locked for the whole drag, even if the pointer leaves the band.
3. **Ring drawing** (`:159-175`). A grey track is a 90 degree arc starting at -90 degrees (12 o'clock, Qt angles run clockwise from 3 o'clock). The fill is the same arc with sweep `90 * value`, with a 0.5 degree minimum so a zero value still shows a dot.
4. **Knob position** (`:176-184`). With `theta = value * pi/2`: `x = r*sin(theta) - w/2`, `y = R - r*cos(theta) - w/2`.
5. **Toggles** (`:209-221`). Same formula on one inner radius (262) with fixed angles in degrees: 21, 32, 43, 54, 65, 76 (11 degree step). Diameter 46. The chord between neighbours is about 50, so they barely clear each other.
6. **Fan shape** (`PanelHost.qml:177-202`). A closed path: concave neck arc, big arc of radius R, concave neck arc, straight lines back. We need no necks.
7. **Open animation**. A `reveal` value runs 0 to 1. Scale is `0.6 + 0.4*reveal` and rotation is `-(1-reveal)*14` degrees, both about the corner point. Opacity is `min(1, 1.6*reveal)`.

**Mirroring for 4 corners (our design, not in the reference).** Pick flags `mx` (right corner) and `my` (top corner). Convert a pointer point into canonical space: `cx = mx ? W - x : x`, `cy = my ? H - y : y`, where W and H are the item size. Then run the bottom-left math unchanged, with `dy = H - cy`. To place any knob or toggle, compute canonical `(px, py)`, then map back with `x = mx ? W - px : px` and `y = my ? H - py : py`. Mirror positions only. Never use a negative item scale, because it flips text and icons. `f = 0` then always sits on the vertical screen edge.

### State reading
- One `sh -c` printing `key=value` lines, on open and every 4 s while open, skipped if still running (`:67-100`). Live: Pipewire via `PwObjectTracker` (`:37-43`), UPower (`:47-58`, battery may be 0..1 or 0..100). Writes use `Quickshell.execDetached`.

### Theming
`Commons.Color.popups.text`, `popups.background`, `accent`, `urgent` (`:27-33`). Muted and hair colors are text at alpha 0.6 and 0.16. `Style.space(n)` scales sizes. On-state fills with accent and flips the glyph to the background color (`:221`).

### Settings
None. Everything is hard-coded (radii, angles, list of toggles).

### Learn
- Ring by press, value by angle. Draft brightness. Optimistic toggles. Poll only while open.

### Avoid
- Hard-coded corner and controls, no settings, no touch path, hover tooltips, right click for "more".
- Exclusive keyboard focus, a 12 px profile target, no availability check.

## 2. aryal.control-center

### Structure
- `manifest.json`: kind `bar-widget` only. Entry `Panel.qml`.
- `Panel.qml` (2701 lines): popup, tiles, edit mode, notifications, telemetry, weather, all in one file. `Model.js` (about 34 KB): normalise, order, resolve, parse, search.
- `control-center.json`: 26 tile definitions as data (wifi, bluetooth, nightlight, dnd, volume slider, brightness slider, power actions...). Each has `id`, `kind` (toggle, slider, action, hidden), `read` argv, `readMode`, `onCommand`, `offCommand`, `needsBin`, `detail` (provider panel).
- `EdgeSummon.qml` (96 lines): the hot corner window.

### Hot corner (`EdgeSummon.qml`)
- A `PanelWindow` on all four edges, layer Overlay, no keyboard focus (`:22-52`). Its `mask` is two 12 px squares at the top corners (`:35-48`), the rest is click-through.
- Each square has a hover-only `MouseArea` with `acceptedButtons: Qt.NoButton` (`:69-95`). A 120 ms timer fires only if the pointer is still inside (`:54-66`).
- Owner calls `summonLeft()` or `summonRight()` (`Panel.qml:246`). Limit: top corners, hover only, no touch.

### Tiles and registration
- Tiles are data. `Model.assemble` merges the JSON catalog with tiles from plugin manifests (`Model.js:543-603`). A generic engine runs `read`, compares with `readValue` (`Model.js:478`), runs `onCommand` or `offCommand`. Sliders drag vertically in the tile (`Panel.qml` ~880).

### Edit mode
- Flag `editMode` (`:75`, `:841`). Drag lifts a ghost, release maps its center to a grid slot (`:902-925`). Arrows swap (`:858`). Long press opens a provider and icon sheet (`:1087`). Closing resets edit mode (`:742-746`).

### Availability detection
- `needsBin` and `needsAnyBin` per tile. One subprocess probes all names on every open (`:421-440`). `isAvailable` hides tiles with a missing tool (`:52-58`).

### State reading
- 400 ms `Timer` only while open (`:526-540`), one command per tile, one at a time. Volume is live Pipewire.

### Settings persistence
- JSON in `$HOME`, written by a python helper via temp file plus `os.replace` (`:760-820`). Writes are serialized, a newer edit replaces a queued one. Versioned, with legacy fallback.

### Theming
`Color.accent`, `Color.urgent`, `Color.foreground`, `Qt.alpha(...)` for fills (`:118-130`), `Style.space`, `Style.hoverFillFor`, `bar.fontFamily`. A few hard-coded fonts ("Inter") break theme consistency (`:2292`).

### Learn
- Masked layer with dwell. Data catalog plus `needsBin`. Atomic queued writes.

### Avoid
- A 2.7k line `Panel.qml`, python in QML strings, `cat` for reads (use `FileView`), hard-coded fonts (`:2292`), arbitrary commands from files.

## 3. Decision table

| Idea | From | Verdict | Why |
|---|---|---|---|
| Press picks ring by radius, value by angle | denon | Adapt | Core feel. 28 px tolerance, ring locked per drag |
| Mirror input and output coordinates per corner | our design | Adopt | One math for 4 corners and rotation |
| Draft brightness, apply on release | denon | Adopt | Fewer backend calls |
| Optimistic toggle, re-read after 450 ms | denon | Adopt | Instant feel, self-correcting |
| Disc open animation (scale, small turn) | denon | Adapt | Same feel, own code |
| Concave necks into a rail | denon | Avoid | We float, no rail |
| Hover hot corner | denon | Adapt | Add tap zone, keybind, IPC for touch |
| Masked layer window, 12 px zone, 120 ms dwell | aryal | Adapt | Click-through, no fly-by opens |
| Exclusive keyboard focus overlay | denon | Avoid | Hyprland refocus bug, use OnDemand |
| Poll only while open | both | Adopt | Cheap, plus live Pipewire and UPower |
| One `sh -c` of key=value lines | denon | Avoid | Opaque, one reader per control |
| `needsBin` hides missing hardware | aryal | Adopt | No battery or keyboard light on some machines |
| Tiles as data | aryal | Adapt | Fixed audited list, no commands from files |
| Edit mode with drag reorder | aryal | Adapt | Settings panel first |
| Atomic queued versioned JSON writes | aryal | Adapt | Use `FileView`, no python |
| Right click for more, hover tooltips | denon | Avoid | No touch support. Use long press, labels |
| Theme colors with alpha for muted | both | Adopt | Follows Omarchy themes |
| One huge file | both | Avoid | Split geometry, controls, readers, settings |

Not checked: aryal on screen, exact stock `Color` and `Style` names.
