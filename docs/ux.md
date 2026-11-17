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

The trigger zone is a layer input mask, and a mask cannot tell touch from mouse. So the zone also eats mouse clicks on whatever sits under it. Rules: the zone is small (32 px); it is off while a fullscreen window is on that output; it never exists on the lock screen; settings warn when the bar or dock sits on that corner.

**Closing.** Outside tap or click, Escape, the keybind, IPC `close`, or a workspace switch. While open, the mask covers the whole output as a transparent click catcher, so the outside tap only closes and the app under it does not get that one click. That is the price of reliable dismissal without exclusive focus. Pointer-opened fans also close 600 ms after the pointer leaves. Idle timeout: 10 s (setting, off allowed). Nothing closes during a drag or long-press.

**Focus.** `OnDemand`, never `Exclusive`: Hyprland refuses focus calls during an exclusive grab and refocuses the old window on unmap. Keyboard and IPC opens request focus so arrows and Escape work at once.

**Gestures.** We add no swipes. 3-finger and 4-finger touchpad swipes stay untouched.

## 3. Layout model

From the outside in, around the corner origin:

- **Dial rings.** Each ring defaults to a 4 px track in a 44 px band. The ring listed first in settings is the outermost. Labels follow the ring curve as specified in section 5.
- **Toggle arc.** Round toggles, 40 px drawn, 48 px hit area, pitch 48 px along the arc.
- **Corner readout.** Large battery %, "On battery, 2 h 50 m", and a 48 px power profile chip.
- **Status line.** Above the readout, names the last touched control ("Wi-Fi: on, HomeNet"). Replaces hover tips.
- **Settings gear.** 48 px, beside the power profile chip in the corner readout; never consumes an arc slot (P0.2).

Dial rings sweep 3 to 87 degrees, so they run close to both screen edges (about 19 px at M); the knob still clears the bezel. The toggle arc keeps 6 to 84 degrees so its 48 px targets never touch an edge.

**Capacity.** Radius R is S 330, M 420 (default), L 500, capped at 45% of the output's shorter side so portrait works. Toggles that fit = floor(r_toggle x 1.36 rad / 48).

| Size | Dials | Toggle arc radius | Visible toggle slots |
|---|---|---|---|
| S | 2 | 200 | 5 |
| M | 3 | 240 | 6 |
| L | 4 | 280 | 7 |

**Expansion size is a user choice** (Settings, Size: Compact, Normal, Large). Each size also sets how much text the corner carries:

| Size | Ring labels | Corner readout | Status line |
|---|---|---|---|
| Compact (S) | Icon and value only | 28 px battery number and the profile chip; no battery line | Never inside the fan: a notice beside it for 2.5 s after an action; errors stay until the next action |
| Normal (M) | Icon, name and value | 40 px battery number, battery line, profile chip | Inside, up to 2 lines; then up to 4 with battery number and line hidden; then the notice |
| Large (L) | Icon, name and value | 48 px battery number, battery line, profile chip | As Normal, with more room |

When the screen cap makes a size smaller than its nominal radius, Settings says so (for example Large on the Z13 shows "capped at 432 px").

**Overflow.** Rings, including readouts, have a hard cap: S 2, M 3, L 4. Settings refuse extra rings with a size hint. Toggles form one ordered scrollable strip on the arc. Press and slide after 6 px, following tangential finger travel 1:1 without inertia. Movement at 6 px cancels hold. Release snaps to the nearest slot over 160 ms using the shared E curve, without overshoot. Wheel scrolls one slot. Theme-only end fades indicate remaining items.

**Text geometry.** Geometry returns a reserved box for status, battery line, dial labels, toggle names in details, detail rows and readout labels. Text wraps inside that box, never truncates, never uses ellipsis, and never overlaps another box or target. Minimum font size is 12 px. Status uses the rules below. Rows grow with wrapped text above their 48 px minimum. At M and L, status uses a 120 px box with up to two 18 px lines. Longer status hides the battery number and line and uses a 144 px box with up to four lines above the profile chip. If it still does not fit, show the whole text in a 260 px notice beside the fan. Compact always uses the notice for 2.5 s after an action; errors remain until the next action. Short status restores battery copy. No clipping, ellipsis, overlap or font below 12 px. No font shrinking below 12 px. Support 32-byte SSIDs, long Bluetooth names and translations 1.4 times longer.

**Ring settings.** Global style defaults and per-ring overrides: track solid, dashed, dotted or segmented (ticks at steps); knob round, bar or none; thickness thin 2 px, normal 4 px or bold 6 px. All stay inside the 44 px band with 48 px touch targets and theme roles only.

**Readout rings.** Existing kind `readout`, no knob, flat end caps and an explicit read-only label. Tap opens related detail; drag, wheel and adjustment keys never write. Choices: selected Bluetooth device battery, Wi-Fi signal, laptop battery and UPower pen battery. A disconnected device stays dimmed with "not connected", value null, never a fake 0%. All count toward the ring cap.

**Drill-down.** Long-press a toggle or a dial label (or Shift+Enter) and the quarter disc morphs into a rounded square of R x R anchored to the same corner. Header with back button and name, then rows at least 48 px tall. Rows wrap and grow; scroll when their measured heights exceed the detail.

| From | Detail |
|---|---|
| Wi-Fi | Radio switch, networks, tap to connect. A new secured network asks for a password inline. With no keyboard attached it says so and offers "Open Wi-Fi settings" (the exception in principle 4; the Z13 has no on-screen keyboard yet). |
| Bluetooth | Power, paired devices with battery, connect or disconnect. |
| Volume, mic | Output or input device picker, mute; volume includes named per-app sliders and a Media action. Holding Volume opens Media, also by Shift+Enter. |
| Brightness | Monitor picker, then per-monitor brightness. Refresh rate and scale for the picked monitor. |
| Power profile | Saver, balanced, performance. |

omadials sits beside bar widgets and never edits the bar (architecture.md decision 2).

## 4. Interaction per widget

**Dial drag.**
- Ring pick: the band under the finger at touch-down, locked for the whole drag.
- Start: a drag starts after 6 px of movement. A press with no movement only shows the value bubble.
- Value: the angle of the finger around the corner origin, mapped from the sweep start (0%) to the sweep end (100%). A fresh normal drag follows the finger absolutely; outside the sweep it clamps. Fine control uses relative angle changes as described below.
- Direction: the value grows away from the side edge (left or right), toward the top or bottom edge, in every corner. Labels and minimum always sit on the side edge.
- Fine control: outward distance from the locked ring centre selects gain 0.25 beyond 22 px and 0.1 beyond 66 px. Rebase at each gain transition. Returning uses gain 1 without a jump. See experience.md, Dial precision.
- Floors: brightness stops at 1%, never 0, so a drag cannot black out the screen. Volume input caps at the configured maximum, default 100%, up to 150%. Existing over-cap values remain truthful.
- Mute: tapping the dial label mutes volume or mic.
- Brightness is written on release; the knob previews it.

**Wheel and touchpad scroll** over a ring: 5% per notch, 1% with Shift. Smooth scroll adds pixel deltas into whole steps.

**Keyboard.**
- Tab order: rings outer to inner, toggles in arc order, profile chip, gear.
- Arrows change the focused dial by 5% (Shift 1%). Page Up and Page Down change it by 25%. Home and End set the floor and configured maximum.
- Enter or Space toggles. Shift+Enter or the Menu key opens the detail. Escape goes back from a detail, then closes.

**Toggles.** Settings choose tap and hold actions from each control's closed catalog set. Defaults: tap switches, hold opens quick detail. Wi-Fi supports switchRadio, quickDetail and fullWindow for either action. Long-press is 450 ms, with a fill ring from 150 ms; 6 px movement cancels hold and starts arc scroll. A pending outline shows until the read-back confirms; on failure the old state stays and the status line says why.

**Value bubble** (feedback in place of haptics). During a drag or scroll a pill shows the value 56 px from the contact point, toward the screen center, clear of the thumb. It fades 600 ms after the last change.

**Accessibility.**
- `Accessible.name` and role on every control: "Volume, 40 percent" (Slider), "Wi-Fi, on" (CheckBox).
- Never color alone: on is filled, off is outlined, muted has a slashed icon. Text follows `Style.font`.

## Defaults (decided 2026-11-17, plan P0.2)

- **Corner tab:** two rings and a knob. Three rings stays available in Settings.
- **Size:** Normal (M, 420 px).
- **Settings from the corner:** a 48 px gear button beside the power profile chip, in the corner readout. The chip shrinks to make room. Keybind and the app launcher also open Settings.
- **Toggles, in order:** Wi-Fi, Bluetooth, night light, do not disturb, keep awake, keyboard light; then by scrolling: airplane, game mode, theme, media. Touchpad, touchscreen and recording are available but off. Compact shows the first 5 without scrolling, Normal 6, Large 7.

## 5. Corners, monitors, rotation

- **Corner choice.** Settings pick the corner (bottom-left default) with a live preview.
- **Ring labels.** Each dial label (icon, name, value) follows its ring's curve on the corner side of the track, 14 px inside it, starting 10 px from the side edge. The text path always runs left to right, so glyphs stay upright in all 4 corners.
- **Corner icon.** A small mark shows where omadials lives. Default: a 42 px quarter tab in the theme surface colour with a 1 px edge, holding a mini dial. The default is two rings with a knob; three rings is a Settings choice. It is the closed shape of the fan itself, so opening reads as the tab growing. It mirrors toward its corner (it has no text). A custom icon sits inside the same tab. `cornerIcon.mode` is a closed set: `always`, `onApproach` (hidden until the pointer enters the 32 px tap zone, fades in over 80 ms, a click opens; push-to-open is off in this mode), `never`. `cornerIcon.aboveWindows`: on, the icon floats over windows; off, it sits behind windows and shows only on an empty desktop. `cornerIcon.source`: `default`, an icon theme name, or a local SVG or PNG file (read only, size limited, validated; invalid falls back to default and is reported).
- **The tap zone always works.** In every icon mode, and with the icon behind a window, the 32 px zone stays above windows and a tap opens. Only the icon moves. The reveal area is the tap zone itself, never larger, because a layer mask that sees the pointer also catches clicks (spike S3). The icon hides over fullscreen windows and on the lock screen, like the zone.

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

- `muted` never carries text or a needed cue. Use the roles in this section for off states.
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
| External value change | Knob glides 120 ms. During normal drag it tracks 1:1; fine control uses the selected gain. |
| Toggle press | Scale 0.92 in 80 ms, fill cross-fades 120 ms. |
| Drill-down | Disc to square morph, 200 ms. |
| Arc release | Nearest slot snap, 160 ms, shared E, no overshoot. |

**Reduced motion** (`Style.reduceMotion`, set when Hyprland animations are off): everything snaps; the pending outline is a static dashed ring.

## 8. Configuration experience

- **Show or hide every control.** Each toggle and each dial ring has its own Show switch. A hidden ring frees its band and the rings close the gap; a hidden toggle leaves the arc. Hidden controls stop all reads and polling. Hiding is not the same as missing hardware: missing is greyed with a reason, hidden is the user's choice.
- **Pick the icon of each control.** Every toggle and ring label offers a short list of icons from the Omarchy icon theme, plus any icon theme name. Theme colours only. An unknown name falls back to the default icon and is reported in settings, never silently.

A shell `panel` (`platform.md` 7a), opened from the gear or IPC. It writes `~/.config/omadials/config.json` on every change, and the corner applies it live.

| Page | Contents |
|---|---|
| Corner | 4-corner picker, size S, M, L, tab style, icon mode, source and layering, trigger outputs, pointer push delay, tap zone on or off |
| Controls | Dials list and Toggles list |
| Behavior | Idle timeout, close on pointer leave, keybind shown with its command |
| About | Version, reset all |

**Controls page.**
- Rows: 48 px drag handle, up and down buttons (keyboard, and touch without dragging), enable switch, name, options chevron.
- A counter shows "6 of 6 fit at M" and shows the visible slot count and scrollable total. Missing hardware is greyed: "Not found on this machine".
- Per-control options: wheel step, brightness monitor, tapAction and holdAction from the control catalog, ring style, readout device picker, volume cap, fine control, snap, theme pair and game options.

**Live preview.** The right half draws the real corner component at 60% scale; "Show on screen" opens the real fan.

**Reset.** Per page and all, with no confirm dialog: an "Undo" bar stays 10 s.

## 9. Mockups

The [motion prototype](prototype/motion.html) shows the open corner, labels and gear placement.

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
| Toggles (6 visible, 10 shown)    |   +-----+                 |
|  = [x] Wi-Fi        ^ v  >       |                           |
|  = [x] Bluetooth    ^ v  >       |   [Show on screen]        |
|  = [ ] GPU mode  Not found here  |                           |
|                    [Reset page]  |                           |
+--------------------------------------------------------------+
```

## 10. Acceptance

Use the shared [acceptance checklist](acceptance.md).
