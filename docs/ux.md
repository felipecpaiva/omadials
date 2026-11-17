# omadials UX and visual design

Written 2026-11-17, design only. Main device: Z13, 1600x1000 logical px. All sizes are logical px.

## 1. Experience principles

1. **One gesture to open, one to change.** Any setting is at most 2 touches from closed.
2. **Nothing jumps under a finger.** A tap never changes a dial value; only drag, wheel or keys do.
3. **Thumb sized.** Targets at least 48 px, ring bands at least 44 px.
4. **Stays in the corner.** Drill-downs open inside the corner. One stated exception (section 3).
5. **Looks like the theme.** Every color is a theme role and follows live switches.
6. **Truthful state.** Toggles show the state read back from the system. Missing hardware hides its control.
7. **Never steals.** No new gestures, no focus theft, no clicks taken while closed outside the small trigger zone.

## 2. Opening and closing

| Trigger | Rule |
|---|---|
| Corner tap (touch) | A quarter-disc zone of radius 32 px in the chosen corner. Press and release inside it within 400 ms, moving under 10 px, opens. |
| Corner drag (touch) | Press in the zone and drag outward: the fan grows with the finger and stays open if released past 40% of its radius. |
| Pointer push (mouse, touchpad) | Pointer rests in the 2 px corner for 150 ms (setting, 0 to 500). Not while a button is held (window drags). |
| Keybind | Runs `omarchy-shell omadials toggle`. Never takes a chord the user already binds. |
| IPC | `omarchy-shell omadials open`, `close`, `toggle`. |
| Bar button | Optional `bar-widget`, off by default. |

The trigger zone is a layer input mask, and a mask cannot tell touch from mouse. So the zone also eats mouse clicks on whatever sits under it. Rules: the zone is small (32 px); it is off while a fullscreen window is on that output; it never exists on the lock screen; settings warn when the bar or dock sits on that corner.

**Closing.** Outside tap or click, Escape, the keybind, IPC `close`, or a workspace switch. While open, the mask covers the whole output as a transparent click catcher, so the outside tap only closes and the app under it does not get that one click. That is the price of reliable dismissal without exclusive focus. Pointer-opened fans also close 600 ms after the pointer leaves. Idle timeout: 10 s (setting, off allowed). Nothing closes during a drag or long-press.

**Focus.** `OnDemand`, never `Exclusive`: Hyprland refuses focus calls during an exclusive grab and refocuses the old window on unmap. Keyboard and IPC opens request focus so arrows and Escape work at once.

**Gestures.** We add no swipes. 3-finger and 4-finger touchpad swipes stay untouched.

## 3. Layout model

From the outside in, around the corner origin:

- **Dial rings.** Each ring is a 4 px track in a 44 px band. The ring listed first in settings is the outermost. A level label (icon and number) sits at the ring's start, on the side edge.
- **Toggle arc.** Round toggles, 40 px drawn, 48 px hit area, pitch 48 px along the arc.
- **Corner readout.** Large battery %, "On battery, 2 h 50 m", and a 48 px power profile chip.
- **Status line.** Above the readout, names the last touched control ("Wi-Fi: on, HomeNet"). Replaces hover tips.
- **Settings gear.** 48 px, at the end of the toggle arc.

Every arc sweeps 6 to 84 degrees, inset so no target touches a bezel.

**Capacity.** Radius R is S 300, M 380 (default), L 460, capped at 45% of the output's shorter side so portrait works. Toggles that fit = floor(r_toggle x 1.36 rad / 48).

| Size | Dials | Toggle arc radius | Toggles per page |
|---|---|---|---|
| S | 2 | 180 | 5 |
| M | 3 | 216 | 6 |
| L | 4 | 252 | 7 |

**Overflow.** Dials have a hard cap per size; settings refuse more and suggest a larger size (rings cannot page: a swipe across rings is a drag). Extra toggles go to page 2: the last slot becomes "more" with a page dot; wheel or a swipe along the arc also pages. A second arc would crowd the readout, and a flick-scroll on a thin arc misfires.

**Drill-down.** Long-press a toggle or a dial label (or Shift+Enter) and the quarter disc morphs into a rounded square of R x R anchored to the same corner. Header with back button and name, then 48 px rows (6 at M before scrolling).

| From | Detail |
|---|---|
| Wi-Fi | Radio switch, networks, tap to connect. A new secured network asks for a password inline. With no keyboard attached it says so and offers "Open Wi-Fi settings" (the exception in principle 4; the Z13 has no on-screen keyboard yet). |
| Bluetooth | Power, paired devices with battery, connect or disconnect. |
| Volume, mic | Output or input device picker, mute. |
| Brightness | Monitor picker, then per-monitor brightness. Refresh rate and scale for the picked monitor. |
| Power profile | Saver, balanced, performance. |

Still open: replace the bar's audio, network and power widgets, or sit beside them.

## 4. Interaction per widget

**Dial drag.**
- Ring pick: the band under the finger at touch-down, locked for the whole drag.
- Start: a drag starts after 6 px of movement. A press with no movement only shows the value bubble.
- Value: the angle of the finger around the corner origin, mapped from the sweep start (0%) to the sweep end (100%). The knob follows the finger absolutely; outside the sweep it clamps.
- Direction: the value grows away from the side edge (left or right), toward the top or bottom edge, in every corner. Labels and minimum always sit on the side edge.
- Resolution: at M the inner ring sweeps about 370 px (3.7 px per percent), so no fine-drag mode.
- Floors: brightness stops at 1%, never 0, so a drag cannot black out the screen. Volume caps at 100.
- Mute: tapping the dial label mutes volume or mic.
- Brightness is written on release; the knob previews it.

**Wheel and touchpad scroll** over a ring: 5% per notch, 1% with Shift. Smooth scroll adds pixel deltas into whole steps.

**Keyboard.**
- Tab order: rings outer to inner, toggles in arc order, profile chip, gear.
- Arrows change the focused dial by 5% (Shift 1%). Page Up and Page Down change it by 25%. Home and End set the floor and 100.
- Enter or Space toggles. Shift+Enter or the Menu key opens the detail. Escape goes back from a detail, then closes.

**Toggles.** Tap flips. Long-press (450 ms, a fill ring grows from 150 ms, 10 px of movement cancels) opens the detail. A pending outline shows until the read-back confirms; on failure the old state stays and the status line says why.

**Value bubble** (feedback in place of haptics). During a drag or scroll a pill shows the value 56 px from the contact point, toward the screen center, clear of the thumb. It fades 600 ms after the last change.

**Accessibility.**
- `Accessible.name` and role on every control: "Volume, 40 percent" (Slider), "Wi-Fi, on" (CheckBox).
- Never color alone: on is filled, off is outlined, muted has a slashed icon. Text follows `Style.font`.

## 5. Corners, monitors, rotation

- All 4 corners mirror the geometry (`x -> width - x`, `y -> height - y`). List order runs from the side edge toward the top or bottom edge.
- One fan at a time. A corner trigger opens on its own output; keybind and IPC on the focused output. Trigger outputs: all (default), focused, or a named list. Unplugging the output closes the fan.
- Rotation: anchors are logical, so "bottom-left" is the visual bottom-left as the tablet is held. R re-clamps to 45% of the new shorter side and capacity is recounted; scale changes do the same.

## 6. Theming

Theme lives at `~/.local/state/omarchy/current/theme`. Bind to `Commons.Color` and `Commons.Style` properties, never copy them, so a theme switch recolors with no reload.

| Element | Role |
|---|---|
| Fan surface | `Color.popups.background` (theme alpha) |
| Surface edge | `Color.popups.border`, 1 px |
| Text, icons | `Color.popups.text` |
| Secondary text | `Color.foreground` at 70% alpha |
| Ring track | `Color.foreground` at 18% alpha |
| Ring fill, knob | `Color.accent` |
| Knob outline | `Color.background`, 2 px |
| Toggle off | `Style.normalFill` + `Style.normalBorderColor`, icon in foreground |
| Toggle on | `Color.accent` fill, icon in `Color.background` |
| Hover, focus, pressed | `Style.hoverFill`, `Style.focusBorderColor`, `Style.pressedFill` |
| Warning (battery under 15%, write failed) | `Color.urgent` plus an icon |
| Detail card corners | `Style.cornerRadius` |

**Contrast rules**, measured on real themes:

| Theme | muted on bg | accent on bg | foreground on accent | background on accent |
|---|---|---|---|---|
| White | 3.95 | 5.1 | 4.12 | 5.1 |
| Tokyo Night | 1.91 | 6.79 | 1.19 | 6.79 |
| Flexoki Light | 2.0 | 6.36 | 2.93 | 6.36 |

- `muted` never carries text or a needed cue. This corrects the `platform.md` plan to draw off states with it.
- Glyphs on an accent fill use `background`. If `accent` on `background` is under 3:1 at runtime, fills fall back to `foreground`.
- White has a grey accent and near-black urgent, so states differ by shape and fill, not hue. All rings share `accent` (no per-ring tints as in the reference).
- Text needs 4.5:1. Rings, knobs and toggle edges need 3:1.

Light and dark come free from the roles.

## 7. Motion

Durations go through `Style.duration(ms)` with `Style.easeOut`.

| Event | Motion |
|---|---|
| Open | Scale 0.6 to 1 from the corner origin plus fade, 180 ms. Rings follow 20 ms apart. |
| Close | Fade and scale to 0.8, 120 ms. |
| External value change | Knob glides 120 ms. During a drag it tracks 1:1. |
| Toggle press | Scale 0.92 in 80 ms, fill cross-fades 120 ms. |
| Drill-down | Disc to square morph, 200 ms. |
| Page change | Toggles slide along the arc, 160 ms. |

**Reduced motion** (`Style.reduceMotion`, set when Hyprland animations are off): everything snaps; the pending outline is a static dashed ring.

## 8. Configuration experience

A shell `panel` (`platform.md` 7a), opened from the gear or IPC. It writes `~/.config/omadials/config.json` on every change, and the corner applies it live.

| Page | Contents |
|---|---|
| Corner | 4-corner picker, size S, M, L, trigger outputs, pointer push delay, tap zone on or off |
| Controls | Dials list and Toggles list |
| Behavior | Idle timeout, close on pointer leave, keybind shown with its command |
| About | Version, reset all |

**Controls page.**
- Rows: 48 px drag handle, up and down buttons (keyboard, and touch without dragging), enable switch, name, options chevron.
- A counter shows "6 of 6 fit at M" and marks page 2 items. Missing hardware is greyed: "Not found on this machine".
- Per-control options: wheel step, brightness monitor, default detail.

**Live preview.** The right half draws the real corner component at 60% scale; "Show on screen" opens the real fan.

**Reset.** Per page and all, with no confirm dialog: an "Undo" bar stays 10 s.

## 9. Mockups

Open corner, bottom-left, size M:

```
|
|  [sun] 72  ------------------.
|                               `--.
|  [spk] 40  ---------o.            `-.
|                       `--.           `.
|  [mic] 15  ---o.          `-.         \
|                 `-.          \         \
|      (wifi)        `.         \         |
|          (bt)         \         |        |
|  Wi-Fi: on, HomeNet  (moon)    |        o
|              (dnd)    |         |        |
|  On battery, 2 h 50 m  (cup)   |        |
|  72%      [Balanced]   (more) (gear)    |
+-----------------------------------------+--
```

Drill-down, Wi-Fi:

```
|  < Wi-Fi                  [ on ]   |
|  ------------------------------    |
|  HomeNet          connected  ****  |
|  Office-5G        saved      ***   |
|  Cafe             open       **    |
|  Neighbor         locked     *     |
|  Open Wi-Fi settings  >            |
+------------------------------------+--
```

Settings window:

```
+--------------------------------------------------------------+
| omadials                                                     |
| [Corner] [Controls] [Behavior] [About]                       |
|--------------------------------------------------------------|
| Dials (3 of 3 fit at M)          |   live preview            |
|  = [x] Brightness   ^ v  >       |                           |
|  = [x] Volume       ^ v  >       |   .--.                    |
|  = [x] Mic          ^ v  >       |   |   `.                  |
|  = [ ] Kbd light    ^ v  >       |   | o  \                  |
| Toggles (6 of 6, 2 on page 2)    |   +-----+                 |
|  = [x] Wi-Fi        ^ v  >       |                           |
|  = [x] Bluetooth    ^ v  >       |   [Show on screen]        |
|  = [ ] GPU mode  Not found here  |                           |
|                    [Reset page]  |                           |
+--------------------------------------------------------------+
```

## 10. UX acceptance checklist

1. A corner tap opens the fan. A drag past 40% opens; released before 40% it springs closed.
2. Every trigger, dismissal and timeout in section 2 behaves as written.
3. Pointer push never opens during a window drag.
4. Keybind and IPC opens get keyboard focus; Escape goes back, then closes (verify by hand).
5. An outside tap closes, and the app under it gets no click. The old window keeps focus after close.
6. 3-finger and 4-finger swipes behave the same with omadials on and off.
7. No trigger zone with a fullscreen window or on the lock screen.
8. Tapping any ring without moving changes no value.
9. A drag that drifts into another band keeps adjusting the first ring.
10. Brightness never goes below 1%; volume never above 100.
11. Every target measures 48 px or more; every ring band 44 px or more.
12. Long-press at 450 ms opens the detail, and 10 px of movement cancels it.
13. The value bubble is never under the contact point.
14. Tab reaches every control in the documented order; arrows, Page keys, Home and End work.
15. A screen reader reads names and values on the layer surface (verify by hand).
16. All 4 corners mirror correctly; portrait rotation keeps R within 45% of the short side.
17. A live switch White to Tokyo Night to Flexoki Light recolors with no reload and passes the contrast rules.
18. No hard-coded color exists in QML (grep for `#` color literals outside tests).
19. With animations off, open, close and drill-down are instant.
20. Enabling a 7th toggle at M creates page 2; enabling a 4th dial at M is refused with a size hint.
21. Missing hardware hides its control in the corner and greys it in settings.
22. Settings changes show in the preview and in the open corner within 1 s.
23. Reset all, then Undo, restores the old config exactly.
