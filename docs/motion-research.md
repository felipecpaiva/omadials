# Open and close motion: research

2026-11-17. The maintainer found the open and close animation unsatisfying ("the last piece of the initial experience").
This file holds the research; the chosen motion goes into `experience.md` after the motion lab comparison.

## Why the current motion feels off

- It scales the whole disc from 0.6, so stroke widths and knobs scale too: the rings look rubbery, not solid.
- Nothing connects the closed tab to the open disc. A 180 ms zoom and fade reads as "something appeared", not as
  "the tab grew".

## What the best products do (sources)

- **Apple** springs are set by a perceived duration and a bounce. Bounce 0 is the default; 0.15 barely bouncy, 0.3
  clearly, above 0.4 exaggerated. Retargeting keeps velocity, and a finished gesture hands its velocity to the spring.
  With mass 1: stiffness = (2π / duration)², damping ratio = 1 − bounce (0.30 s ≈ 440, 0.25 s ≈ 630, 0.35 s ≈ 320).
  https://developer.apple.com/videos/play/wwdc2023/10158/
- **Apple, fluid interfaces:** start at 100% damping; overshoot only when the gesture carries momentum; pick the end
  state from the projected release velocity; rubber band at limits; track 1:1; Control Center modules grow up and out
  toward the finger; exit along the entrance path. https://developer.apple.com/videos/play/wwdc2018/803/
  Rubber band: `b = (1 − 1/(x·0.55/d + 1))·d`. https://www.holko.pl/2014/07/06/inertia-bouncing-rubber-banding-uikit-dynamics/
- **Reduced motion:** replace motion with a dissolve or highlight fade.
  https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria
- **Material 3:** spatial springs damping 0.9 (stiffness 1400 fast, 700 default, 300 slow); effects springs damping 1
  (3800, 1600, 800); emphasized decelerate `(0.05,0.7,0.1,1)` in, emphasized accelerate `(0.3,0,0.8,0.15)` out;
  container transform 300 ms in, 250 ms out.
  https://raw.githubusercontent.com/material-components/material-components-android/master/docs/theming/Motion.md
- **Windows 11:** enter `(0,0,0,1)` at 167, 250 or 333 ms; exit 167 ms with a fade; minimum an 83 ms linear fade.
  https://learn.microsoft.com/en-us/windows/apps/design/signature-experiences/motion
- **Quickshell shells:** caelestia uses Material 3 Expressive, spatial overshoot `(0.38,1.21,0.22,1)` at 500 ms and
  fast `(0.42,1.67,0.21,0.9)` at 350 ms (https://raw.githubusercontent.com/caelestia-dots/shell/main/plugin/src/Caelestia/Config/tokens.hpp);
  end-4 enters 400 ms emphasized decelerate and exits 200 ms emphasized accelerate
  (https://raw.githubusercontent.com/end-4/dots-hyprland/main/dots/.config/quickshell/ii/modules/common/Appearance.qml).
- **Qt:** `SpringAnimation` keeps velocity when its target changes (interruptible) but takes no initial velocity, so a
  drag hand-off needs a small spring stepped in a `FrameAnimation`. https://doc.qt.io/qt-6/qml-qtquick-springanimation.html

## Principles for omadials

1. Grow from the tab, not from an abstract corner point.
2. Exit at about half the entry time, with no bounce.
3. Overshoot only after momentum (a flick).
4. Stagger by distance from the corner; all content in place within about 300 ms, usable by about 150 ms.
5. Never scale strokes or text: animate radius, angle and opacity.

## Candidates (compared in the motion lab)

1. **Tab morph:** the disc radius grows from the tab (42 px) to R; each mini ring flies out to its full ring. Spring
   0.30 s, bounce 0.08; rings start 0, 25, 50 ms; toggles fade in after 60% of R. Close: toggles fade 80 ms, radius
   0.20 s, bounce 0.
2. **Radial clip reveal:** the full disc is drawn in place and a circular mask grows from 42 to R + 8 with
   `(0.05,0.7,0.1,1)` over 280 ms, plus scale 0.97 to 1. Close: mask shrinks 160 ms with `(0.3,0,0.8,0.15)`.
3. **Spring cascade:** scale 0.88 to 1 on a 0.35 s spring, bounce 0.12; rings 30 ms apart; knobs sweep from 0 to their
   values with bounce 0.2. Close: 0.22 s, bounce 0, to 0.92 with a fade.
4. **Minimal fast:** opacity 120 ms `(0,0,0,1)` and a 10 px slide out of the corner over 160 ms. Close: 83 ms linear
   fade. Also the reduced-motion basis.
5. **Fan unfold:** each ring's angle grows from the screen edge to 90° in 240 ms with `(0.42,1.67,0.21,0.9)`, outer
   rings 25 ms ahead; toggles pop along the arc. Close: fold back in 140 ms.
6. **Hybrid (recommended first):** candidate 1's radius spring drives candidate 2's mask: one number controls shape
   and reveal. All content in about 300 ms, usable at about 150 ms. Close 0.18 s critically damped.

## Technical findings on the Z13 (2026-11-17)

Measured with standalone `qs -p` spikes (never the real shell), 180 Hz, scale 1.6.

- **Today's motion has a kink.** `Behavior` + `NumberAnimation` (MotionValue) changes velocity when retargeted: a
  0 to 1 then back to 0 test held at 0.925 for one frame, then dropped to 0.794 in one 5.5 ms frame.
- **`SpringAnimation` judders here.** It updates every 16.6 ms, once per three 180 Hz frames, and starts about 20 ms
  late. Its rule: every 16 ms, `v += (spring*diff - damping*v)/mass; x += v*0.016`.
- **A small spring stepped in `FrameAnimation`** with real `frameTime` updates every frame and keeps velocity through
  a retarget. Mapping with mass 1: stiffness = (2π/response)², damping = 4π(1 − bounce)/response.
- **Reveal cost** (420 px disc, three live arcs, retargeted every 320 ms for 8 s): no dropped frames for scale, clip
  rect, ShaderEffect wipe or MultiEffect mask; average 5.56 ms, worst 6.8 to 7.2 ms. Creating a layer at each open
  costs a missed frame (8.57 ms worst): keep layers alive. `Fan` fills the output, so any layer must sit on a
  disc-sized item, never the window.
- **Cheapest of all:** animate the disc radius and the ring sweeps as geometry (Shape CurveRenderer), no layer.
- **Morph:** the tab and the fan are separate layer surfaces that commit independently (up to one frame apart). For a
  true morph, draw the tab inside CornerWindow when it is above windows; when behind windows, start the fan at the
  tab's exact shape and hide the tab after the fan's first frame.
- **Hyprland:** our windows stay mapped, so open and close never trigger a compositor fade. They fade once on first
  map; Omarchy's syntax to stop that is `hl.layer_rule({ match = { namespace = "^omadials(-tab)?$" }, no_anim = true })`
  (not applied: we do not edit the Hyprland config).

**Technical recommendation:** replace MotionValue's NumberAnimation with a FrameAnimation spring (open: response
0.30 s, bounce 0 to 0.1; close: 0.22 s, bounce 0); reveal by radius and sweep geometry; draw the tab in CornerWindow
for the morph. This favours the Tab morph and Hybrid candidates.
