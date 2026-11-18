# Settings validation (v0.7, 2026-11-17)

The maintainer asked us to check every settings option before v0.7 is called ready, with a focus on the experience and how it looks.

Each option gets three checks:

- **Writes:** using the control changes the config file.
- **Effect:** the plugin reads the key and acts on it.
- **Looks:** the control reads well in dark and light themes.

Each check has one of three states:

- **run:** a test or a live run proved it.
- **code:** fixed in code and the plugin loads, but no run has proved it yet.
- **hand:** needs a person and a pointer.

## How to rerun

```sh
make -C app/tests
cd <empty folder>
OMADIALS_SWEEP=1 OMADIALS_SWEEP_THEME=white QT_QPA_PLATFORM=offscreen <repo>/app/tests/settings-tests sweep
```

The `sweep` test slot does three things:

1. It takes full-height shots of every page, at 1200 px and at 720 px wide, in the given theme. The theme comes from a copy of its `colors.toml` in a temporary state folder.
2. It drives 52 control changes the way a click does (`toggle` + `clicked`, `activated`, `moved`). After each change it reads the saved value back. The results go to `sweep-<theme>-writes.txt`, and the test fails on any mismatch.
3. It replaces the theme folder the way Omarchy does, waits for the new colours, and takes a shot.

On 2026-11-17 it passed 52 of 52 on `tokyo-night`, `white` and `rose-pine`. The theme switch passed too.

For the Effect check, we searched the plugin (`Service.qml core controls views vm logic`) for each key. We also opened the real corner with IPC (`open`, `detail`, no pointer) and took a `grim` shot.

## Status per option

| Page | Option | Key | Writes | Effect | Looks |
|---|---|---|---|---|---|
| Corner | Corner | `corner` | run | run (IPC open) | run |
| Corner | Screens | `outputs.*` | run | code (was dead; this machine has one screen, so not testable here) | run |
| Corner | Size | `size` | run | run | run |
| Corner | Tab style, own icon | `tabStyle`, `cornerIcon.source` | run | code read | run |
| Corner | Tab size (new, 2026-11-18) | `cornerIcon.scale` | run | run (unit tests at 0.5; live shot at 0.6) | run |
| Corner | Show the tab | `cornerIcon.mode` | run | code read | run |
| Corner | Above windows | `cornerIcon.aboveWindows` | run | code read | run |
| Corner | Open when the pointer rests | `trigger.push` (new) | run, and `cornerIcon.mode` stays unchanged | run (live, run-p5) | run |
| Corner | Opening delay | `trigger.pushDelayMs` | run | code read; hand | run |
| Rings | All rings style | `ringStyle.*` | run | run (was hidden by the built-in ring styles; IPC open shot) | run |
| Rings | Edit sheet | `controls.<id>.icon`, `dials[].style` | existing test | code read | run |
| Rings | Wheel step | `options.<id>.wheelStep` | existing test | unit test for the step; by hand the touchpad wheel changes the volume on the ring. A synthetic uinput wheel never reached the ring, so the step size is not measured live | run |
| Rings | Add, Remove, order | `dials`, `controls.<id>.shown` | existing test | code read; drag order is hand | run |
| Toggles | Add, Remove, When tapped, When held | `toggles`, `controls.<id>.shown` | existing test | code read | run |
| Toggles | Theme toggle tap | `toggles[theme].tapAction` | run (schema test) | run (IPC `detail theme` shows the installed theme list) | run |
| Behavior | Close after | `behavior.idleTimeoutS` | run | code read | run |
| Behavior | Close when the pointer leaves | `behavior.closeOnPointerLeave` | run | run (live, run-p5) | run |
| Behavior | Animation style, speed, bounce | `animation.*` | run | code read; feel is hand | run |
| Behavior | Fine control, Snap | `dialInteraction.*` | run | code read; feel is hand | run |
| Behavior | Volume above 100 % | `options.volume.maxPercent` | run | code read | run |
| Behavior | Game mode switches | `gameMode.*` | run, gaps off writes `null` | run (unit test); code (an off switch used to force a value) | run |
| About | Corner works when the tab is hidden | `trigger.tapZone` | run | run (live hover, run-p5) | run |
| About | Reset, Undo, Copy details, Open folder | | existing test | | run |

## What was wrong, and the fix

- **Five options saved but did nothing:**
  - Screens: every screen always got the corner. Fix: an `allowed` flag per output in `Service.qml`.
  - Close when the pointer leaves: the leave timer always ran. Fix: `FanInput.leaveCloses`.
  - Wheel step: `ValueMap.wheel` now takes the ring's step.
  - Tap zone: the window mask ignored it. Fix: `CornerWindow.zoneActive`. With the option off, a tab set to "Never" has no zone. "When the pointer is near" keeps its zone, because it needs the zone to see the pointer arrive.
  - Rest to open: it shared `cornerIcon.mode` with "Show the tab", so switching it changed the tab. Fix: it has its own key, `trigger.push`.
- **Resting opened the corner, then it closed 0.6 s later** when "Close when the pointer leaves" was on (the default). The closed-corner input turns off as the fan opens, and that counted as the pointer leaving. Fix: only a real exit starts the leave timer. Found and proved by the live check `test/live/run-p5.sh`.
- **All rings style did nothing (found by the maintainer).** The built-in ring list gave each ring its own solid, round, normal style, and that hid the All rings choice. The write test passed because the file was right; only the corner was wrong. Fix: the built-in rings have no own style. Proved live with a shot after the fix.
- **"Choose screens" could not be picked.** The choice was rejected when no screen was selected yet. Fix: picking it now selects every screen first.
- **Game mode switches left off forced a value** (gaps 5 and 10, animations on). Fix: an off switch now keeps the value from before game mode.
- **Light themes:** the app forced `Material.Dark`, so the text stayed white on light backgrounds. Fix: light themes use `Material.Light`.
- **Weak lines and fills:** the theme's `muted` and `selection` colours were 1.0 to 1.9:1 against the cards on most of the 23 themes. Fix: lines and fills now use the text colour at a low opacity.
- **Weak accent:** on `white` (2.8:1) and `rose-pine` (2.9:1) the accent was too faint. Fix: a weak accent falls back to the text colour, as in the plugin.
- **Help lines** looked the same as the labels on most themes. Fix: help lines use the text colour at 72 % opacity.
- **Rows:**
  - "No value yet" is gone.
  - The Theme row no longer shows "Off".
  - The Touchscreen glyph showed as ">"; it is now a tapping finger.
  - About buttons looked like plain text; they now use `SettingsButton`.

## Keys with no control

- `dialInteraction.snapWindowPercent`, `fineDistancesPx`, `fineGains`: the plugin does not read these (Gesture.js uses its own constants). The schema still accepts them.
- `readout.battery`, `powerProfile`, `penBattery`: not read. They are left over from the first draft.
- `options.brightness.monitor`: set from the displays detail in the corner.
- `themePair`: removed from the app on 2026-11-17. Old files still load. A bad name in an old file can still raise a banner that has no card to fix it.

## Hand checks for the maintainer

1. Rest to open: turn "Open when the pointer rests" off. Rest the pointer in the corner. The corner must stay closed.
2. Tap zone: set "Show the tab: Never" and turn "Corner works when the tab is hidden" off. Rest the pointer in the corner, then tap it. Nothing must open, and a window under the corner must get the click.
3. Close when the pointer leaves: turn it off. Open the corner by resting, then move away. The corner must stay open until the "Close after" time.
4. Wheel step: set it to 10 on Volume. One wheel notch on the ring must change the volume by 10.
5. Feel: dial drag with fine control and snap; the 6 animation styles at speed 0.5, 1 and 2; drag-to-reorder; touch on the Z13 screen; hover on the picture buttons.
