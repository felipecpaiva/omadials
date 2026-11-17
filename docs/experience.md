# omadials experience and motion

Design specification, 2026-11-17. Quickshell 0.3.2. All distances are logical px. This extends `ux.md`, it does not replace its sizes, gestures or acceptance criteria. `architecture.md` resolves backend and password handling. The shared checks are in [acceptance.md](acceptance.md).

## Feel

1. Grow from the corner. The origin never moves. Rings unfold from the side edge toward the other edge.
2. Follow the finger exactly. Input has no easing, inertia or delayed knob. A tap only reveals a value.
3. Settle without overshoot. Motion starts promptly, slows once and stops. No rotation, bounce or elastic stretch.
4. Keep work available. Pending work belongs to one control. Other controls, Back and dismissal still work.
5. Tell the truth. Preview, pending, confirmed, failed and unavailable have distinct words or outlines.

## Motion contract

All eased rows below use **E** unless marked otherwise. E is Qt `Easing.Bezier`, `easing.bezierCurve: [0.23, 1, 0.32, 1, 1, 1]`. The browser equivalent is `cubic-bezier(0.23, 1, 0.32, 1)`. Linear means Qt `Easing.Linear`. No springs are used. Early drag-open release returns closed using E over 120 ms without overshoot.

Every visual duration and stagger passes through `theme.duration(ms)`. Gesture thresholds and real command deadlines do not. View properties contain rendered progress only. `vm/FanModel.qml` owns session state, selected control, arc offset, detail id, displayed draft, confirmed value and status. Control backends own command state. Views receive these through the view model. A view must never infer success from the end of an animation.

`logic/Geometry.js` supplies canonical points, radii, sweep mapping, bubble positions and corner transforms. `logic/Gesture.js` classifies taps, drags and long presses. Visual interpolation stays in `views/`. `theme/Theme.qml` alone reads stock style and colour roles. Views call named view model intents. They never run commands, read backend services or discover geometry independently.

At M, R = 420, three 44 px ring bands, 4 px strokes, 240 px toggle radius, 40 px visible toggle circles and 48 px hit targets. Ring sweep = 3 to 87 degrees, toggle sweep = 6 to 84 degrees. Ring radii are Geometry output, not independent motion constants. The prototype uses band centres R-22, R-66 and R-110 as the decided Geometry implementation, checked at every size. No motion alters hit target dimensions. A valid corner tap still opens after movement under 10 px, even if a drag preview began at 6 px. Tap classification takes priority on release when its time and inside-zone checks pass.

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

On open the icon fades out with the hint timing (80 ms) while the fan enters; on close it returns after the close completes. `aboveWindows: false` moves only the icon behind windows; the tap zone stays above them. Reduced motion shows and hides the icon instantly.


## Storyboard

Times start at the trigger. Stagger is zero unless stated. Opacity values are 0 to 1. Scale is uniform about the corner for the fan and about the centre for a control. Numbers below are base milliseconds.

| Moment and trigger | What moves, from and to | Duration, curve, stagger |
|---|---|---|
| Closed, no input | No visible surface, rings or perpetual hint. The static radius 32 trigger mask and the configured corner tab exist. No work loop. | 0, none |
| Pointer enters the 2 px corner, no buttons held | Hint arc at radius 24 changes opacity 0 to 0.7. No fan preview or value change. Leave cancels dwell and fades hint 0.7 to 0. | 80 in, 80 out, E |
| Pointer stays for 150 ms | Open. The hint fades to 0 with the entry. Ignore pushes while any button is down. After dismissal suppress another push until the pointer leaves the 2 px zone. | 150 dwell, real time; 80 hint fade, E |
| Corner tap, valid release inside radius 32 | Surface scale 0.6 to 1 and opacity 0 to 1. No rotation. Readout and toggles opacity 0 to 1 with the surface. | 180, E |
| Rings on open | Each ring's reveal q goes 0 to 1. Track and fill are clipped to angle `3 + 84*q`. Fill endpoint is `min(valueAngle, revealAngle)`. Knob opacity equals q and sits at its true value throughout. Labels opacity equals q. Values never animate from zero on open. | 180 each, E; outer starts 0, middle 20, inner 40. L adds 60. M finishes at 220, L at 240 |
| Corner drag-open | Once movement exceeds 6 px, p = clamp(distance from corner / R, 0, 1). Opacity = p, scale = 0.6 + 0.4*p, ring reveal = p, no stagger. Finger owns p directly. It never edits a dial on this gesture. | 0, direct |
| Release corner drag | Strictly past 0.4 commits open. At or below 0.4 returns closed. Continue from the displayed scale, opacity and reveal. | Remaining fraction of 180 for open; full 120 for early return closed, E, no stagger |
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
| Close by outside tap, Escape, corner tap again, keybind, IPC, workspace switch, pointer leave or idle | Surface and all children fade from current opacity to 0, scale from current scale to 0.8 about corner. Cancel ring staggers. No reverse ring cascade. Detail closes in its current shape. Keep outside catcher through final frame, then restore only trigger mask. | 120, E, no stagger |
| Reopen or reverse during close | Cancel completion callbacks and restart from each displayed property. Target scale 1, opacity 1 and ring reveal 1. Do not seed 0.6 again. Generation tokens discard stale completions. | 180 times largest remaining normalised distance, E, no stagger |

Keyboard and IPC opens request OnDemand focus. Tap opens never request Exclusive focus. Outside dismissal consumes that one click. Pointer sessions close 600 ms after leaving the fan, cancelled on re-entry. Idle closes after 10000 ms without user activity. Pause both timers during any captured gesture or long press. Restart them on release. A pending command does not extend the session forever; it survives dismissal in the backend and is read again on open.

A timeout is an event, not a frame animation. No motion duration changes a command timeout. The prototype fakes a slow Wi-Fi command at 1500 ms and a Bluetooth failure at 900 ms. Those are demonstration delays, not backend policy.

### Interruption rules

Sample current presentation values before cancelling an animator. A new animation uses those values as its start. Retarget duration is the base duration multiplied by the largest remaining distance divided by that property's full travel, capped at the base duration. Zero distance finishes synchronously. Use separate opacity, scale, reveal and shape-radius channels. Do not compute scale from opacity during reversal: close ends at 0.8, first open starts at 0.6.

All callbacks carry a session or transition generation. Old callbacks cannot hide a newly opened fan. Input masks and accessibility visibility follow semantic state, not a rounded opacity comparison. Detail morph and close can overlap on independent channels. No view destruction until close completes. A forced close from output loss, lock or fullscreen suppresses the trigger and snaps hidden immediately.

## Visual learning and improvements

| Visual idea | Keep | Improve |
|---|---|---|
| Quarter disc rooted in the corner | A calm surface with concentric hairline arcs | Independent shell plugin, no bar neck or attachment |
| Values read by angle | Knobs travel on the same arc as input | 6 px threshold, tap never edits, band remains locked |
| Big battery readout inside the fan | Light numerals and a compact profile chip | 48 px profile target and readable status instead of hover-only hints |
| Filled round toggles | Filled on, outlined off, contrasting glyphs | Pending, rollback, long press and touch access |
| Small entry from the origin | Scale plus fade | No rotating text, overshoot or colour-coded rings; stagger the ring sweep |
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

`theme.reduceMotion` is authoritative. Turning it on mid-transition immediately sets every channel to its current semantic target and cancels animation callbacks.

| Animation family | Reduced version |
|---|---|
| Hint, entry, close, reversal and ring stagger | Instant visibility and final geometry; no hint fade or stagger |
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
