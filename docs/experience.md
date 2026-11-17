# omadials experience and motion

Design specification, 2026-11-17. Quickshell 0.3.2. All distances are logical px. This extends `ux.md`, it does not replace its sizes, gestures or acceptance criteria. `architecture.md` resolves backend and password handling. The shared checks are in [acceptance.md](acceptance.md).

## Feel

1. Grow from the corner. The origin never moves. Rings unfold from the side edge toward the other edge.
2. Follow the finger exactly. Input has no easing, inertia or delayed knob. A tap only reveals a value.
3. Settle calmly. Motion starts promptly, slows once and stops. No rotation or elastic stretch. Only the open motion may bounce, and only by the configured amount or after a flick (see Open and close).
4. Keep work available. Pending work belongs to one control. Other controls, Back and dismissal still work.
5. Tell the truth. Preview, pending, confirmed, failed and unavailable have distinct words or outlines.

## Motion contract

All eased rows below use **E** unless marked otherwise. E is Qt `Easing.Bezier`, `easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1]`. The browser equivalent is `cubic-bezier(0.23, 1, 0.32, 1)`. Linear means Qt `Easing.Linear`. The open and close motion is the one exception: it has its own styles, springs and curves, set in the next section.

Every visual duration and stagger passes through `theme.duration(ms)`. Gesture thresholds and real command deadlines do not. View properties contain rendered progress only. `vm/FanModel.qml` owns session state, selected control, arc offset, detail id, displayed draft, confirmed value and status. Control backends own command state. Views receive these through the view model. A view must never infer success from the end of an animation.

`logic/Geometry.js` supplies canonical points, radii, sweep mapping, bubble positions and corner transforms. `logic/Gesture.js` classifies taps, drags and long presses. Visual interpolation stays in `views/`. `theme/Theme.qml` alone reads stock style and colour roles. Views call named view model intents. They never run commands, read backend services or discover geometry independently.

At M, R = 420, three 44 px ring bands, 4 px strokes, 240 px toggle radius, 40 px visible toggle circles and 48 px hit targets. Ring sweep = 3 to 87 degrees, toggle sweep = 6 to 84 degrees. Ring radii are Geometry output, not independent motion constants. The prototype uses band centres R-22, R-66 and R-110 as the decided Geometry implementation, checked at every size. No motion alters hit target dimensions. A valid corner tap still opens after movement under 10 px, even if a drag preview began at 6 px. Tap classification takes priority on release when its time and inside-zone checks pass.

## Open and close

One number, the open amount p, drives the whole open and close motion: 0 is the closed tab, 1 is the full corner.
`logic/OpenStyles.js` maps p to everything that is drawn (disc radius, clip radius, each ring's radius, sweep, width,
value factor, knob alpha and size, alpha, toggle alpha and scale, label and readout alpha, tab overlay alpha), and the
timing of each style. It is a port of `docs/prototype/motion-lab.html` in real pixels for S, M and L. `views/Fan.qml`
draws one frame from it; nothing else animates during an open or close.

The style is `animation.style` (file-contract.md), default **Tab morph**. Speed (`animation.speed`, 0.5x to 2x)
divides every duration. Bounce (`animation.bounce`, 0 to 0.35, default 0.06) is used by the spring styles when they
open. Springs have mass 1, stiffness (2π / response)² and damping 4π(1 - bounce) / response (damping ratio 1 - bounce).

| Style (key) | What moves | Open | Close |
|---|---|---|---|
| Tab morph (`morph`) | The disc grows from the tab (42 px) to R. Each mini ring flies out to its full ring (radius, stroke 2.5 px to the ring's width, knob 8 px to 14 px), outer first, 0.05 of p apart. Rings without a mini ring, and knobs the tab lacks, fade in as they travel. Toggles fade in from p = 0.6, labels from 0.72. | Spring 0.30 s, configured bounce | Spring 0.22 s, bounce 0 |
| Hybrid (`hybrid`) | One radius grows the disc and opens the clip together; the full rings are revealed as the clip passes them. Toggles fade in from 0.5, labels from 0.6. | Spring 0.30 s | Spring 0.20 s, bounce 0 |
| Lens (`lens`) | The full disc is in place; a circular clip opens from 42 px to R + 6. | 260 ms, (0.05, 0.7, 0.1, 1) | 170 ms, (0.3, 0, 0.8, 0.15) |
| Spring cascade (`cascade`) | The disc springs out of the tab; rings fade in one by one from p = 0.25, 0.1 apart, and each fill and knob sweeps up to its value from 0.35. Toggles fade in and scale 0.7 to 1 from 0.55, 0.05 apart. | Spring 0.34 s | Spring 0.22 s, bounce 0 |
| Minimal (`minimal`) | A short grow out of the tab with a fade (body alpha 2.2 p). | 160 ms, (0, 0, 0, 1) | 110 ms, (0.3, 0, 0.8, 0.15) |
| Fan (`fan`) | The disc grows out of the tab by p = 0.71; each ring's sweep unfolds from the screen edge, outer first, 0.08 apart over 0.7 of p. Toggles pop in (scale 0.6 to 1) from 0.5, 0.05 apart. | 300 ms, (0.42, 1.67, 0.21, 0.9) | 170 ms, (0.3, 0, 0.8, 0.15) |

Rules for every style:

1. **First and last frames are the closed tab.** At p = 0 the tab overlay (`views/TabMark.qml`, the same drawing as
   the closed tab) is fully on top and the rest is hidden; checked pixel by pixel for every tab style in a standalone
   spike. The overlay fades out by p = 0.18 and back in on close. At p = 1 every part is at its final place.
   `test/OpenStyles.test.mjs` checks both ends for every style, size, short screen and tab style, and that every value
   stays finite for p from -0.2 to 1.2.
2. **Geometry, never scale.** Radius, sweep, width and alpha are animated as geometry. Strokes and text are never
   scaled. The clip is resolved in OpenStyles into geometry (disc radius = min(surface, clip), each part's alpha times
   how much of its band the clip covers), so no layer or mask is created.
3. **Staggers land by p = 1.** A stagger step shrinks when there are more rings or toggles than the lab drew (L has
   four rings, seven toggle slots), so nothing is still fading at rest. This is the one deliberate change from the lab.
4. **Labels and marks stay on the final radius** and fade; hit tests always use the final radii.
5. **Interruptions keep motion.** A spring keeps its velocity when retargeted; a tween restarts from the shown value
   over its time times the remaining distance (at least a quarter). Reopening during a close never jumps.
6. **Drag to open.** Once the finger has moved 6 px from a closed corner, p = (distance - 42) / (R - 42) directly
   from the finger, with a rubber band past R: 1 + (1 - 1 / ((q - 1) · 0.55 + 1)) · 0.3. On release the flick decides,
   not the lift point: open when p + 0.12 · velocity > 0.4. The spring styles start from the finger's velocity; an
   outward flick faster than 1.5 open amounts per second opens with bounce at least 0.15. Closing never bounces.
7. **Exit is shorter than entry and never bounces.**
8. **Clock only while moving.** The open amount is a spring stepped in a `FrameAnimation` with the real frame time
   (1 ms substeps, frames over 50 ms clamped), or a bezier tween; the clock runs only while the value moves and stops
   at rest (`views/MotionValue.qml`, math in `logic/Motion.js`). Closed and open at rest run no clock.
9. **Colours from the theme roles only**, so the motion follows the active Omarchy theme live.
10. **Reduced motion** (`theme.reduceMotion`) always uses Minimal without movement: the full disc in place, faded in
    over 160 ms and out over 110 ms. No grow, no clip, no stagger, no bounce.

**Seam rule.** The closed tab lives in its own window (TabWindow, above or behind windows) and the corner in
another; the two commit separately. When the corner starts opening it draws the tab itself (the overlay above), and
the TabWindow's tab hides only after the corner window has put that frame on screen. When it closes, the TabWindow's
tab shows again at once, and the corner hides its copy only after the TabWindow has put its tab on screen. So there is
never a frame without a tab, and the hand-off itself is instant in both directions (no 80 ms hint fade).

Measured on the Z13 (180 Hz, standalone spike with the real views, opened and closed every 0.6 s for 8 s): every style
averages 5.55 to 5.56 ms per frame while moving, worst 6.6 to 9.5 ms on a quiet machine. A released drag continues
from the finger's value and velocity with no jump.

## Dial precision

Normal drag follows the finger without easing. Outward distance is measured from the locked ring centre, so the rule works for every ring and corner. Beyond the 22 px half band, gain is 0.25. Beyond 66 px, gain is 0.1. Fine mode integrates angle deltas into an unsnapped draft. The knob leaves the finger and the bubble says "Fine". Every gain transition rebases the last angle. Returning to normal keeps the draft and uses gain 1 from that angle, without a jump. A fresh normal drag maps the finger angle directly. This deliberate clutch is the exception to "knob under the finger".

Marks stay visible at 0, 25, 50, 75 and 100. Snap attracts the displayed value within 2 percentage points. The unsnapped draft keeps moving so it can escape. Settings can disable attraction, not marks. Each detent entry gives one existing 40/80 ms visual tick. No Z13 haptics.

## Order and text layout

Order changes only in settings, never from usage. Toggle scrolling resets to the first slot on each open.

Labels follow each ring curve, 14 px inside the track and starting 10 px from the side edge, always left to right. Normal battery text is 40 px, Compact 28 px and Large 48 px. The profile and gear each keep a 48 px target. Compact omits ring names and the battery line.

At M and L, status uses a 120 px box with up to two 18 px lines. Longer status hides the battery number and line and uses a 144 px box with up to four lines above the profile chip. If it still does not fit, show the whole text in a 260 px notice beside the fan. Compact always uses the notice for 2.5 s after an action; errors remain until the next action. Short status restores battery copy. No clipping, ellipsis, overlap or font below 12 px.

## Media detail

At M the three 44 px bands use 132 px. A progress readout would replace brightness, volume or mic under the three-ring cap. It also cannot fit track title and three 48 px transport targets. The R by R detail can fit a 48 px header, two title lines, a 48 px progress row and three 48 px transport controls with room to scroll. Choose a media detail, reached by holding the volume label or tapping Media. Volume detail includes the Media button. No progress ring.

Storyboard: open, normal drag, outward fine clutch, detent escape, toggle scroll, app sliders and output picker, media transport, theme picker, return and close. Prototype data and commands are fake.


## Corner icon

The configured tab marks the closed corner. `cornerIcon.mode` (ux.md section 5) decides:

| Mode | Closed look | Pointer enters the 32 px zone | Opens by |
|---|---|---|---|
| `always` | Corner tab visible | No change; push dwell and hint arc as before | Tap, click, push dwell, keybind, IPC |
| `onApproach` | Nothing | Tab fades 0 to 1 in 80 ms, E; fades out in 80 ms on leave. Replaces the hint arc. Push dwell is off | Tap, click, keybind, IPC |
| `never` | Nothing | Hint arc and push dwell as before | Tap, click, push dwell, keybind, IPC |

On open and close the tab hands over to the corner window's copy of it instantly, by the seam rule in Open and close. The 80 ms fade is only for `onApproach`. `aboveWindows: false` moves only the icon behind windows; the tap zone stays above them. Reduced motion shows and hides the icon instantly.


## Storyboard

Times start at the trigger. Stagger is zero unless stated. Opacity values are 0 to 1. Scale is uniform about the corner for the fan and about the centre for a control. Numbers below are base milliseconds.

| Moment and trigger | What moves, from and to | Duration, curve, stagger |
|---|---|---|
| Closed, no input | No visible surface, rings or perpetual hint. The static radius 32 trigger mask and the configured corner tab exist. No work loop. | 0, none |
| Pointer enters the 2 px corner, no buttons held | Hint arc at radius 24 changes opacity 0 to 0.7. No fan preview or value change. Leave cancels dwell and fades hint 0.7 to 0. | 80 in, 80 out, E |
| Pointer stays for 150 ms | Open. The hint fades to 0 with the entry. Ignore pushes while any button is down. After dismissal suppress another push until the pointer leaves the 2 px zone. | 150 dwell, real time; 80 hint fade, E |
| Corner tap, valid release inside radius 32 | Open amount 0 to 1 in the configured style (Open and close). | Style timing |
| Rings on open | As the style sets them from the open amount. Fill endpoint is `min(valueAngle, sweepAngle)`. Only Spring cascade sweeps values up from zero. | Style timing |
| Corner drag-open | Once movement exceeds 6 px, the finger owns the open amount directly, with the rubber band past R (Open and close, rule 6). It never edits a dial on this gesture. | 0, direct |
| Release corner drag | The projected amount p + 0.12 · velocity strictly past 0.4 commits open, otherwise closed. Continue from the shown amount with the finger's velocity. | Style timing |
| Press a ring | Lock band at down, show bubble opacity 0 to 1. No value update until movement reaches 6 px. A stationary release does not write. | Bubble 80, E |
| Drag a dial | Disable value Behaviors before taking input. Angle maps 3 to 87 degrees to floor through max. Knob position, fill and integer label update on the same frame. Bubble is 56 px toward screen centre, clamped inside output with 8 px clearance. Brightness preview stops at 1%, other floors at 0. | 0, direct, no stagger |
| Step or endpoint tick | At a discrete level change, knob outline width 2 to 3 then 3 to 2. Endpoint uses width 4 instead of 3. No knob translation or value overshoot. Tick once on entry to floor or max, rearm after leaving by at least one logical step. Coalesce multiple crossed steps into one tick per frame; do not buzz every percent on continuous dials. | Attack 40, recovery 80, E on each leg |
| Release dial | Keep the preview value. The live writer sends the released value last; during the drag it already wrote the newest value about every 50 ms, one write in flight. Keep pending feedback until read-back. No inertial movement. If confirmation differs, glide from current visual value to confirmed value. | Same value 0; correction 120, E |
| Value bubble after drag, scroll or key change | Reset hide deadline on each change. At 600 ms after last change, opacity 1 to 0. During a held pointer keep it visible. Digits change immediately, no rolling counter. | Hold 600 real ms, fade 80, E |
| Toggle pointer down | Scale 1 to 0.92. Press fill uses the theme pressed role. Hit target stays 48. On release or cancel return from current scale to 1. A cancel does not toggle. | Press 80, return 120, E |
| Valid toggle tap | Optimistic proposed fill and glyph ink cross-fade from old to proposed state. Mark status "Wi-Fi: turning on" or "turning off". Do not announce confirmed on yet. | 120, E |
| Pending command | A 2 px dashed outline appears immediately. Its dash phase advances 0 to one dash period of 12 px while pending. It does not pulse the whole control. Reject duplicate taps on this control. Other controls work. | 900 per period, Linear, repeat only while pending |
| Command confirms | Keep confirmed fill. Pending outline opacity 1 to 0. Replace status with read-back state. No second scale pulse. | 80, E |
| Command fails or times out | Cross-fade proposed fill back to last confirmed fill. Replace pending outline with warning icon and "Could not change Bluetooth: reason". Keep error until the next user action or successful refresh. No shake. Never retry from the view. | Rollback 120, E; warning appears immediately |
| Long press on toggle or dial label | At 150 ms start an outline fill at 0 degrees. It reaches 360 at 450 ms. Movement of 6 px cancels toggle hold; dial label hold cancels at 10 px. A completed hold consumes release so no toggle follows. | 300, Linear; real hold deadline 450 |
| Arc scroll | After 6 px cancel hold; tangential travel updates arc offset 1:1. No easing during capture. Theme-only end fades show hidden items. | 0, direct |
| Arc release or wheel | Snap to nearest slot; wheel advances one slot. Retarget from current offset. Capture interrupts snap; close cancels it; the next open resets to the first slot. | 160, E, no overshoot |
| Enter detail | R x R bounds and corner anchor stay fixed. Far-corner surface radius R to theme.radius. Straight edges stay on the two screen edges. Fan content opacity 1 to 0 in first 80 ms. Detail content opacity 0 to 1 from 80 ms onward. No text scaling or rotation. | Radius 200, E; outgoing 80, E; incoming 120, E, delay 80 |
| Wi-Fi, outputs or displays detail loads | Asynchronous Loader. Header and Back exist immediately. Reserve rows at least 48 px tall, growing for wrapped text; show static "Loading" until rows arrive. Replace text in place, no growing card or row cascade. New secured Wi-Fi uses inline password entry, gated by S7; no keyboard offers the full window. Never put credentials in argv. | Data replacement 0, no stagger |
| Back or Escape in detail | Reverse radius to R over 200. Detail fades out in first 80, fan fades in over following 120. Restore prior arc offset and focused control. Escape again closes even during this transition. | 200, E; 80 out, 120 in, delay 80 |
| External dial update while open | Numeric label takes the truthful value immediately. Fill angle and knob share one displayed-value interpolation from current value to new. Retarget every newer update from the displayed point. An over-cap value remains truthful in text, knob pins at max with an over-cap mark. | 120, E |
| External update while dragging | Keep finger ownership of displayed draft. Store newest confirmed backend value in the model. After release, reconcile using the backend command result, not a stale queued animation. | Direct during drag; reconciliation 120, E |
| Control becomes unavailable | During probing keep an empty outlined slot with input off. Available is normal. Error keeps the slot with warning and input off. Missing control is hidden per UX. Freeze positions during any active gesture. Disable its writes immediately and show reason. Remove it and recompute geometry after release; remaining positions snap. For temporary error keep its slot and a warning icon; never show false off. | No removal animation, 0 |
| Close by outside tap, Escape, corner tap again, keybind, IPC, workspace switch, pointer leave or idle | Open amount from its shown value to 0 in the style, back into the tab. Detail closes in its current shape. Keep outside catcher through final frame, then restore only trigger mask. | Style close timing, no bounce |
| Reopen or reverse during close | Retarget the open amount from its shown value; a spring keeps its velocity. Never seed 0 again. | Style timing; tweens scale by the remaining distance |

Keyboard and IPC opens request OnDemand focus. Tap opens never request Exclusive focus. Outside dismissal consumes that one click. Pointer sessions close 600 ms after leaving the fan, cancelled on re-entry. Idle closes after 10000 ms without user activity. Pause both timers during any captured gesture or long press. Restart them on release. A pending command does not extend the session forever; it survives dismissal in the backend and is read again on open.

A timeout is an event, not a frame animation. No motion duration changes a command timeout. The prototype fakes a slow Wi-Fi command at 1500 ms and a Bluetooth failure at 900 ms. Those are demonstration delays, not backend policy.

### Interruption rules

Sample current presentation values before cancelling an animator. A new animation uses those values as its start. Retarget duration is the base duration multiplied by the largest remaining distance divided by that property's full travel, capped at the base duration. Zero distance finishes synchronously. The open and close motion is one channel, the open amount; detail shape and content keep their own channels.

All callbacks carry a session or transition generation. Old callbacks cannot hide a newly opened fan. Input masks and accessibility visibility follow semantic state, not a rounded opacity comparison. Detail morph and close can overlap on independent channels. No view destruction until close completes. A forced close from output loss, lock or fullscreen suppresses the trigger and snaps hidden immediately.

## Visual learning and improvements

| Visual idea | Keep | Improve |
|---|---|---|
| Quarter disc rooted in the corner | A calm surface with concentric hairline arcs | Independent shell plugin, no bar neck or attachment |
| Values read by angle | Knobs travel on the same arc as input | 6 px threshold, tap never edits, band remains locked |
| Big battery readout inside the fan | Light numerals and a compact profile chip | 48 px profile target and readable status instead of hover-only hints |
| Filled round toggles | Filled on, outlined off, contrasting glyphs | Pending, rollback, long press and touch access |
| Small entry from the origin | Grows out of the tab | No rotating text, scaled strokes or colour-coded rings; six chosen styles, Tab morph by default |
| Quiet idle | Nothing moves until asked | Fullscreen and lock suppression; zero closed polling |

## Match to stock Omarchy

Installed source values recorded on 2026-11-17. These are observations, not measured frame times.

| Installed source, file:line | Actual value | Use here |
|---|---|---|
| `/usr/share/omarchy/shell/Commons/Style.qml:365` | `duration(ms)` returns 0 when reduced motion is true | Every visual time including stagger |
| `/usr/share/omarchy/shell/Commons/Style.qml:371` | `[0.23,1,0.32,1,1,1]` | E for all settling motion |
| `/usr/share/omarchy/shell/Ui/KeyboardPanel.qml:530` | 180 show, 120 hide; Bezier at lines 531-532 | Exact entry and exit timing and curve pair |
| `/usr/share/omarchy/shell/plugins/dock/DockWindow.qml:282` | 120 tuck, 180 reveal; OutCubic at 283 | Same asymmetric timing. Keep shared E as UX requires, rather than the dock's gentler curve |
| `/usr/share/omarchy/shell/Ui/Button.qml:139` | Colour 120 | Toggle fill transition |
| `/usr/share/omarchy/shell/Ui/WidgetButton.qml:140` | Colour 160 | Theme cross-fade uses this 160 ms family |
| `/usr/share/omarchy/shell/Ui/KeyboardPanel.qml:58` | 200 with shared Bezier at 59-60 | Detail morph duration |
| `/usr/share/omarchy/shell/plugins/dock/DockWindow.qml:194` | Namespace, Top layer at 195, no keyboard focus at 196 | Stable layer surface pattern; our focus is OnDemand as UX requires |
| `/usr/share/omarchy/shell/plugins/dock/DockWindow.qml:212` | Region mask, hidden content click-through; lifecycle described at 10-12 | Keep surface mapped if spike S3 permits; change mask, animate contents |
| `/usr/share/omarchy/default/hypr/looknfeel.lua:70` | easeOutQuint control points (0.23,1), (0.32,1) | Shared shell curve has the same points |
| `/usr/share/omarchy/default/hypr/looknfeel.lua:85` | layers speed 3.81, easeOutQuint | Context only, not a Qt duration |
| `/usr/share/omarchy/default/hypr/looknfeel.lua:86` | layersIn speed 4, easeOutQuint, fade | Avoid stacking this fade with our own entry |
| `/usr/share/omarchy/default/hypr/looknfeel.lua:87` | layersOut speed 1.5, linear, fade | Avoid stacking this exit with ours |
| `/usr/share/omarchy/default/hypr/looknfeel.lua:88` | fadeLayersIn speed 1.79, almostLinear | Context, no invented conversion to milliseconds |
| `/usr/share/omarchy/default/hypr/looknfeel.lua:89` | fadeLayersOut speed 1.39, almostLinear | Context, verify actual layer lifecycle before shipping |
| `/usr/share/omarchy/default/hypr/looknfeel.lua:73` | almostLinear points (0.5,0.5), (0.75,1) | Keep compositor curve outside the content animator |

Keep the window mapped with invisible contents if supported. On first mapping, compositor fade may still apply. Verify S3 and the namespace rules before claiming exact timings on hardware. No system configuration changes are part of this design.

## Reduced motion

`theme.reduceMotion` is authoritative. Turning it on mid-transition immediately sets every channel to its current semantic target and cancels animation callbacks. The open amount is the exception: it switches to Minimal without movement and fades from where it is.

| Animation family | Reduced version |
|---|---|
| Hint, reversal and ring stagger | Instant; no hint fade or stagger |
| Open and close | Minimal without movement: the full disc in place, a 160 ms fade in and 110 ms fade out |
| Direct corner or dial drag | Still follows input 1:1, with no autonomous frames |
| Bubble, labels and external values | Show, update and hide instantly; keep the 600 ms information hold |
| Tick | Static endpoint mark or stepped value text. No outline pulse |
| Press, toggle fill, confirm, failure | Instant scale/state change; error icon and words remain |
| Pending outline | Static dashed ring, no dash-phase animation |
| Long press | Static hold marker at 150 ms; opens at the same 450 ms deadline |
| Arc snap and detail | Replace instantly, preserve focus and target sizes |
| Theme switch | All roles switch in one frame |

Slow motion in the prototype multiplies visual durations and staggers by 4. Input remains direct. Dwell, long press, timeouts and fake command delays stay real time. Reduced motion wins over slow motion.

## Themes while open

Cross-fade surface, border, text, secondary text, track, fill, knob, glyph ink and warning roles from their current rendered colours to the new theme over 160 ms, E. Theme bindings remain live through the adapter. Cache only the transient start colours for interpolation, never replace the role bindings with a copied palette. A second theme change retargets from the displayed colours. No geometry, reload or input state changes.

Resolve contrast fallback at the new endpoint. Intermediate interpolation can reduce contrast when light and dark swap. Keep text and icon colour pairs snapped to their new endpoint if the current interpolated pair fails 4.5:1 for text or 3:1 for controls. The prototype illustrates palette interpolation; it does not certify contrast across installed themes.

## Four corners

Canonical origin is bottom-left. Map points through Geometry, then apply a positive uniform scale around the chosen screen corner. Right corners mirror x positions. Top corners mirror y positions. Top-right mirrors both positions. Never negative-scale a parent containing glyphs or text. Reveal always runs from the vertical edge to the horizontal edge. Text remains upright and row order remains top to bottom in detail views. Detail header and rows are laid out normally inside the anchored square. The far-corner surface radius moves between R and theme.radius in every corner.

An output rotation or scale change cancels captured gestures without writing a brightness draft. Recompute R and capacity, then snap to the new geometry. Unplug closes immediately. Do not animate a fan across outputs.

## Performance budget

Target: 60 fps on Z13 at 2560x1600, scale 1.6667. That mode is about 1536x960 logical px, unlike the 1600x1000 design example in UX. M still fits the 45% cap. Budget is 16.67 ms per frame, p95 frame interval at most 16.67 ms, p99 at most 20 ms, no interval above 33.34 ms in a warmed 30 s drag/open/detail run. Measure cold first open separately. Targets are not measurements.

Use Qt Quick scene graph transforms for scale and knob position, opacity nodes for fades. Keep text out of a scaled bitmap cache. Use `Shape` with `Shape.CurveRenderer` for static fan and track paths. Prefer an analytic fragment shader for ring fill and sweep clipping so animated angles update uniforms rather than rebuilding paths. Use the configured 2, 4 or 6 px stroke in local space. If the shader is unavailable, update only the changed ring's Shape path, never all rings or the whole window. Profile that fallback before shipping. No Canvas full-surface repaint per pointer move.

Detail morph may update one bounded Shape path for 200 ms. It has no blur, shadow animation or live background capture. Tick may update only the knob outline geometry. Pending dashes use a bounded shader phase or a small local Shape, never an application-wide timer. Theme changes update colour uniforms and material colours. Text changes only when its displayed integer or string changes. Layout, R, target bounds, font size, battery readout and list heights never animate.

UI-thread work target below 4 ms per frame, render work below 8 ms. Coalesce pointer updates to one presentation per frame while retaining the newest point. No subprocesses, probes, file access, allocation-heavy model rebuilds or synchronous Loader on the frame path. No running animation clock when closed or open at rest. Measure CPU, GPU and frame pacing before shipping, as engineering standards require. The SVG browser prototype redraws local SVG content for clarity and is not a Qt performance implementation or benchmark.

## Interaction state machine

The state set is exactly `closed`, `hinting`, `opening`, `open`, `dragging`, `detail`, `closing`. Detail morph progress, arc scrolling progress and command state are orthogonal data, not additional interaction states.

The event set is exactly `PUSH_ENTER`, `PUSH_LEAVE`, `DWELL`, `OPEN`, `CORNER_TAP`, `CORNER_DOWN`, `RING_DOWN`, `MOVE`, `RELEASE`, `CANCEL`, `DETAIL`, `BACK`, `ESCAPE`, `DISMISS`, `ARC_DOWN`, `ARC_WHEEL`, `ACTIVATE`, `ADJUST`, `EXTERNAL`, `COMMAND`, `AVAILABILITY`, `THEME`, `REDUCE`, `GEOMETRY`, `FORCE_HIDE`, `SETTLED`. Event payloads carry ids, values and reasons. DISMISS reasons are outside, keybind, IPC, workspace, leaveTimeout, idleTimeout. COMMAND phases are pending, confirmed, failed. FORCE_HIDE reasons are lock, fullscreen, outputLost. These reason and phase sets are closed too.

| State | Event and guard | Next state | Motion or action |
|---|---|---|---|
| closed | PUSH_ENTER, no buttons | hinting | Hint in, start dwell |
| hinting | PUSH_LEAVE | closed | Hint out, cancel dwell |
| hinting | DWELL, pointer still inside | opening | Pointer-session entry |
| closed, hinting, closing | OPEN or CORNER_TAP | opening | New entry or reverse from current |
| closed, hinting | CORNER_DOWN | dragging | Capture owner=corner; hold values |
| opening | SETTLED, current generation | open | Enable resting layout |
| opening, open | RING_DOWN | dragging | Capture owner=ring; value bubble, no write |
| dragging | MOVE | dragging | Threshold then direct corner progress or dial angle |
| dragging | RELEASE, owner=corner and p>0.4 | opening | Complete remaining entry |
| dragging | RELEASE, owner=corner and p<=0.4 | closing | 120 ms return on E |
| dragging | RELEASE, owner=ring | open | Commit only if drag threshold passed; reconcile |
| dragging | CANCEL | open if ring, closing if corner | Discard brightness draft; release capture |
| opening, open | DETAIL, supported and no capture | detail | Morph in, load asynchronously |
| detail | DETAIL | detail | Replace detail id, no second shape morph |
| detail | BACK or ESCAPE | open | Reverse shape; restore arc offset and focus |
| opening, open | ESCAPE or CORNER_TAP | closing | Close from presentation |
| opening, open, detail | DISMISS | closing | Close; timeout guards require no held gesture |
| dragging | DISMISS or ESCAPE | dragging | Ignore timeouts, defer deliberate dismissal until release |
| closing | SETTLED, current generation | closed | Restore trigger-only mask |
| opening, open | ARC_DOWN | dragging | Capture owner=arc; cancel snap |
| dragging | MOVE, owner=arc | dragging | After 6 px cancel hold; direct tangential offset |
| dragging | RELEASE or CANCEL, owner=arc | open | Snap nearest slot, 160 ms E |
| open | ARC_WHEEL | open | Advance one slot, 160 ms E |
| open, detail | ACTIVATE or ADJUST | same | Named model intent, press/fill or value motion |
| Any | EXTERNAL or COMMAND | same | Retarget visual value; ring capture wins draft ownership |
| Any | AVAILABILITY | same | Disable writes; defer removal until capture ends |
| Any | THEME or REDUCE | same | Retarget colours or finish all channels |
| Any | GEOMETRY | closed if output lost, otherwise same with capture cancelled | Recompute and snap; apply cancel destination if dragging |
| Any | FORCE_HIDE | closed | Cancel all captures and visual clocks; suppress trigger |
| Any | Any remaining event/guard failure | same | No action; stale SETTLED ignored |

Deferred deliberate dismissal is delivered as DISMISS immediately after RELEASE or CANCEL. A cancelled long press is not a dial drag. Pointer leave and idle use the existing UX deadlines. Command machines continue independently when the view is closed.

## Acceptance

Use the shared [acceptance checklist](acceptance.md).

## Geometry and device checks

The closed geometry decisions are in `architecture.md` section 14.

- Early drag-open release: 120 ms return on E, no overshoot.
- Ring radii: R - 22 - 44 x i, checked per size in the Geometry tests.
- Small outputs: fall back to Compact, then fewer rings; targets never shrink.
- Compositor fade stacking and theme contrast during a cross-fade stay open as Z13 checks (plan P1.3 and P2.6).

## Prototype scope

Open [the motion prototype](prototype/motion.html) locally. It simulates controls and commands. It does not verify Hyprland focus, layer input masks, real backends, touch hardware, Qt shaders or frame pacing. Those need the plan P1 device checks.


**Ring cap at Large:** the cap is four rings (decision 6). The three dials fill three; the fourth slot holds a readout ring when one is added. The prototype has only three ring slots.
