# Settings validation (v0.7, 2026-11-17)

The maintainer asked us to check every settings option before v0.7 is called ready, with a focus on the experience and how it looks.
Each row has three checks:

- **Writes:** the app control changes the config file.
- **Effect:** the plugin reads that key and changes its behaviour.
- **Looks:** the control reads well in a dark and a light theme.

How we checked:

- **Writes:** offscreen app tests in `app/tests/settings_tests.cpp`.
- **Effect:** we searched the plugin code for each key (`Service.qml core controls views vm logic`), and used IPC (`status`, `detail`, `activate`) where no pointer is needed.
- **Looks:** the `sweep` test slot (`OMADIALS_SWEEP=1 OMADIALS_SWEEP_THEME=<theme>`). It takes full-height and narrow shots of every page, using a copy of the theme's `colors.toml` in a temporary state folder.
- **Contrast:** we computed it for all 23 installed themes with `logic/Contrast.js`.

The marks mean:

- ✅ works.
- ❌ broken.
- ⚠ works, but it is confusing or looks wrong.
- "hand" means only a person can judge it (feel, hover, touch).

## What was fixed (2026-11-17, same day)

- Screens: the plugin now honours all, focused and named screens (`Service.qml`, per-output `allowed`).
- "Open when the pointer rests" has its own key, `trigger.push`. It no longer changes "Show the tab".
- Close when the pointer leaves: FanInput only starts the leave timer when the setting is on.
- Wheel step: `ValueMap.wheel` takes the ring's `wheelStep`.
- Tap zone, renamed "Corner works when the tab is hidden": when it is off, the corner catches the pointer only while the tab is always drawn.
- Game mode: a switch left off keeps the value from before game mode. Gaps off writes `null`, which means "leave the gaps alone".
- Colours: light themes use `Material.Light`. Lines and fills are the text colour at a low opacity, and a weak accent falls back to the text colour. Every shot was retaken on `tokyo-night`, `white` and `rose-pine`.
- Rows: no "No value yet"; the Theme row shows no on or off state; the Touchscreen glyph is a tapping finger.

The table below is the state **before** these fixes. Rows marked ❌ for Effect are fixed in code and the plugin loads, but checking them needs a pointer, so they are still waiting for a live check.

## Corner page

| Control | Key | Writes | Effect | Looks | Note |
|---|---|---|---|---|---|
| Corner (4 pictures) | `corner` | ✅ | ✅ Service, Registry | ✅ dark, ❌ light | |
| Screens | `outputs.mode`, `outputs.names` | ✅ | ❌ | ✅ | **Dead:** every screen always gets the corner (`Variants` over all screens). |
| Size | `size` | ✅ | ✅ | ✅ dark, ❌ light | |
| Tab style (3 pictures + own icon) | `tabStyle`, `cornerIcon.source` | ✅ | ✅ | ✅ dark, ❌ light | |
| Show the tab | `cornerIcon.mode` | ✅ | ✅ TabWindow | ✅ | |
| Above windows | `cornerIcon.aboveWindows` | ✅ | ✅ | ✅ | |
| Open when the pointer rests | `cornerIcon.mode` (same key) | ⚠ | ⚠ | ⚠ | **Two controls, one key.** Switching this on turns "Never" into "Always", so the tab appears. Switching it off turns the choice into "When the pointer is near". |
| Opening delay | `trigger.pushDelayMs` | ✅ | ✅ FanInput dwell | ✅ | |

## Rings page

| Control | Key | Writes | Effect | Looks | Note |
|---|---|---|---|---|---|
| All rings: Track, Knob, Thickness | `ringStyle.*` | ✅ | ✅ Ring, Fan | ✅ | |
| Edit, Remove, Add, drag order | `dials`, `controls.<id>.shown` | ✅ (existing test) | ✅ Registry | ✅ | Drag feel: hand. |
| Edit sheet: icon | `controls.<id>.icon` | ✅ | ✅ | ✅ | |
| Edit sheet: per-ring style | `dials[].style` | ✅ | ✅ | ✅ | |
| Edit sheet: wheel step | `options.<id>.wheelStep` | ✅ | ❌ | ✅ | **Dead:** `ValueMap.wheel` never gets the step. |
| Display rings: add with source | `readoutRings` | ✅ | ✅ | ✅ | |

## Toggles page

| Control | Key | Writes | Effect | Looks | Note |
|---|---|---|---|---|---|
| Edit, Remove, Add, order | `toggles`, `controls.<id>.shown` | ✅ | ✅ | ⚠ | Rows show "No value yet" for controls that are only checked when the corner opens; the About page says this in a clearer way. |
| When tapped, When held | `toggles[].tapAction`, `holdAction` | ✅ | ✅ FanModel | ✅ | |
| Theme row | | | | ⚠ | Shows "Off". It has no on or off state now; it should show the theme name. |
| Touchscreen icon | | | | ⚠ | Draws as ">" (a glyph is missing in the app font). |

## Behavior page

| Control | Key | Writes | Effect | Looks | Note |
|---|---|---|---|---|---|
| Close after | `behavior.idleTimeoutS` | ✅ | ✅ FanModel | ✅ | |
| Close when the pointer leaves | `behavior.closeOnPointerLeave` | ✅ | ❌ | ✅ | **Dead:** FanInput always starts the leave timer. |
| Animation style, speed, bounce | `animation.*` | ✅ | ✅ | ✅ | Feel: hand. |
| Fine control | `dialInteraction.fineEnabled` | ✅ | ✅ Gesture | ✅ | Feel: hand. |
| Snap | `dialInteraction.snap` | ✅ | ✅ | ✅ | |
| Volume above 100 % | `options.volume.maxPercent` | ✅ | ✅ volume Backend | ✅ | On/off only (150 or 100). `settings-ux.md` asked for a maximum field. We keep on/off, which is simpler. |
| Game mode: animations, blur, shadows | `gameMode.*` | ✅ | ✅ map.js | ✅ | |
| Window gaps become 0 | `gameMode.gapsIn`, `gapsOut` | ✅ | ⚠ | ✅ | **Off forces gaps to 5 and 10** during game mode, so a person with other gaps gets changed gaps. Off should leave the gaps alone. |

## About page

| Control | Key | Writes | Effect | Looks | Note |
|---|---|---|---|---|---|
| Plugin status, Copy details, Refresh | | | ✅ | ⚠ | The buttons look like plain text. |
| Open by tapping the corner | `trigger.tapZone` | ✅ | ❌ | ✅ | **Dead:** the CornerWindow mask ignores it. |
| Reset, Undo | all | ✅ (existing test) | ✅ | ✅ | |

## Keys with no control (by design unless noted)

- `dialInteraction.snapWindowPercent`, `fineDistancesPx`, `fineGains`: **not read by the plugin**. Gesture.js uses its own constants. Hidden on purpose; the schema still accepts them.
- `readout.battery`, `readout.powerProfile`, `readout.penBattery`: **not read**. They are left over from the first draft.
- `options.brightness.monitor`: set from the displays detail in the corner, not in the app. ✅
- `toggleScroll`: one value only. ✅
- `themePair`: removed from the app on 2026-11-17. Old files still load.

## Theme colours

Checked over the 23 installed themes:

- **Light themes are broken.** The app forces `Material.Dark`, so control text stays white on a light background. On `white`, the corner and size names, the "All screens" box, the switch labels and the page titles cannot be read.
- `muted` used for borders is 1.1 to 1.9 against the card on most themes, so the card edges are close to invisible. `selection` used for the "off" fill and the selected card is 1.0 to 1.4. Use the text colour at a low opacity instead, which gives contrast in every theme.
- The accent against the card is under 3:1 on `white` (2.8) and `rose-pine` (2.9). Use the same fallback the plugin uses (`Contrast.accent`: use the foreground when the accent is too weak).
- On most themes `foreground` equals `bright_foreground`, so help lines look the same as labels. Use the text colour at about 70 % opacity for help lines.
- Some labels use the theme text colour and some use the Material default, so the same kind of label shows in two colours.

## Hand checks for the maintainer

These need a person and a pointer:

- dial drag feel with fine control and snap;
- the 6 animation styles at speed 0.5, 1 and 2;
- drag-to-reorder in the Rings and Toggles lists;
- touch on the Z13 screen;
- hover states on the picture buttons.
