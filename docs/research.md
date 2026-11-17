# omadials research: a control corner for Omarchy

Started 2026-11-17. Status: research only, no plugin code yet.
Reference: `denon.corner` from [denonmaryland/omarchy-dotfiles](https://github.com/denonmaryland/omarchy-dotfiles)
at `e4f2b6a` (MIT), github.com/denonmaryland/omarchy-dotfiles. Screenshot: `docs/fastfetch-corner.webp` in that repo.

## The idea

One plugin that opens a quarter-circle panel from a screen corner. It holds most hardware quick settings,
so the bar needs fewer widgets. The user picks the corner, the controls and their order.

## What the reference does (how verified: read `plugins/denon.corner/Corner.qml`, 381 lines)

- 3 concentric arcs you drag along: brightness, volume, mic (`Corner.qml:269-320`). Ring is picked by
  distance from the corner, value by angle (`:287-297`). Mouse wheel works on each ring.
- 6 round toggles on an inner arc at fixed angles (`:326-331`): Wi-Fi, Bluetooth, night light, DND,
  keep awake, Dropbox. Left click toggles, right click opens the full stock panel.
- Battery % and time left in the corner; power profile label cycles saver, balanced, performance; Record.
- State: one `sh -c` poll every 4 s while open (`:75-100`). Volume and mic are live via Pipewire,
  battery via UPower.

Parts it borrows from elsewhere (must be rebuilt or copied with credit):

| Part | Where | Size |
|---|---|---|
| Quarter-circle shape and open animation (rotate + scale from the corner) | `denon.bar/panels/PanelHost.qml:177-202`, `:253-259` | ~40 lines |
| Hot corner trigger | `denon.shell/Bar.qml:1829-1841` | ~15 lines |
| Placement next to a left or right rail | `denon.bar/panels/PopupPanel.qml:30-33, 70` | replaced by our own window |

## Feasibility: yes (how verified: read stock plugin code on this Z13, Omarchy 4.5.0-3)

A plugin can own its own corner window with no bar. Stock proof: `omarchy.dock` is a `service` plugin
whose `DockWindow.qml` is a `PanelWindow` anchored to a screen edge (`:202-207`), layer `Top`, no keyboard
focus (`:195-196`), with an input `mask` that is only a small `edgeTrigger` while hidden (`:212-215`).
Our corner window is the same pattern anchored to 2 edges (for example `bottom` + `left`).

Plugin shape we would use:

| Kind | Role |
|---|---|
| `service` (keepLoaded) | The corner window: trigger zone + the fan. Owns IPC `open`, `close`, `toggle` |
| `panel` | Settings window (corner, size, which controls, order), same pattern as omahop's `SettingsPanel.qml` + `ConfigReader.qml` (FileView on a JSON file) |
| `bar-widget` (optional) | A small button for people who want one |

Tools: `omarchy plugin validate <folder>`, `omarchy plugin clone <id>`.

## Z13 control inventory (how verified: read-only commands on the Z13, 2026-11-17; nothing toggled)

| Control | Read | Write | Root? | Live source |
|---|---|---|---|---|
| Screen brightness | `brightnessctl -m -d amdgpu_bl1` | `omarchy-brightness-display` | no | poll |
| Keyboard backlight | `brightnessctl -m -d asus::kbd_backlight` (0-3) | `omarchy-brightness-keyboard` | no | poll |
| Volume, mic | Pipewire (Quickshell) | Pipewire | no | live |
| Output / input device | Pipewire | `omarchy-audio-output-set-default`, `-input-set-default` | no | live |
| Wi-Fi radio | `nmcli radio wifi` | `nmcli radio wifi on/off` | no | poll |
| Bluetooth | `bluetoothctl show` | `omarchy-bluetooth-power` | no | poll |
| Night light | `omarchy toggle nightlight --status` | `omarchy toggle nightlight` | no | poll |
| Do not disturb | `omarchy-shell notifications isDnd` | `omarchy toggle notification silencing` | no | poll |
| Keep awake | `omarchy toggle idle status` | `omarchy toggle idle toggle` | no | poll |
| Power profile | `powerprofilesctl get` | `omarchy-powerprofiles-set` | no | poll (D-Bus possible) |
| Battery, time left | UPower | - | - | live |
| Pen battery | UPower device `hid-0018:04F3:43C7...-battery` | - | - | live |
| Charge limit | `/sys/class/power_supply/BAT0/charge_control_end_threshold` (85 now) | `asusctl battery ...` | check | poll |
| Touchpad on/off | - | `omarchy toggle touchpad` | no | poll |
| Touchscreen on/off | - | `omarchy toggle touchscreen` | no | poll |
| Refresh rate | `hyprctl monitors -j` (eDP-1 2560x1600 @180, 13 modes) | `hyprctl` monitor rule | no | event |
| Scale | same | `omarchy-hyprland-monitor-scaling` | no | event |
| GPU mode | supergfxd | `omarchy toggle hybrid gpu` | check | poll |
| Rotation | `monitor-sensor` present | not decided, see `omarchy-z13/docs/plan.md` Step 3 | - | - |
| Record screen | - | Omarchy capture command | no | - |

Not available here: no `snip`, no Dropbox. `asusctl` is installed (aura, leds, profile, fan-curve, battery).
Every control must hide itself when its read command fails (desktop without battery, no keyboard light).

## Touch gaps in the reference (the Z13 is a tablet)

| Gap | Fix |
|---|---|
| Hot corner is pointer-only | Tap zone in the corner (the dock's masked trigger, but tap, not hover) + keybind + IPC + optional bar button. No new swipe: 3 fingers = workspaces, 4 = Mission Control, touchscreen gestures need `hyprgrass` (not installed) |
| "More" is on right click | Long-press, or a small chevron on each toggle |
| Tips only on hover | Labels under toggles, or a label line that shows the last touched control |
| Profile label is a 12 px target | Make it a toggle-sized chip (46 px like the toggles) |
| Arc ring tolerance 24 px | Fine for a finger; keep, maybe 28 px |
| Geometry fixed to bottom-left | Mirror the angle math per corner (`x -> width - x`, `y -> height - y`); follow screen rotation |
| Full-screen overlay with exclusive keyboard focus (`PanelHost.qml:38`) | Use `OnDemand` focus. See the exclusive-layer focus note: Hyprland refocuses the old window on unmap |

## Duplicates and upstream

How verified: `gh` search of omacom/omarchy-plugin-marketplace issues and omacom/omarchy discussions,
2026-11-17. Keyword search only; no plugin READMEs or source read. Closed issues may be rejected listings.

**No radial hardware corner exists.** Several rectangular control centers do:

| Plugin | Link | Overlap |
|---|---|---|
| `aryal.control-center` (404Prabhat) | [repo](https://github.com/404Prabhat/omarchy-control-center), marketplace #8001 | HIGH: tile grid, Edit mode, `EdgeSummon.qml` 12 px hot corner (120 ms). Closest competitor |
| bahman777 control-center | [repo](https://github.com/bahman777/omarchy-control-center), #14886 | Medium: GNOME/macOS-style tiles and sliders |
| JeoCrypto control-center | [repo](https://github.com/JeoCrypto/omarchy-control-center), #14579 | Medium: bar button, stock `omarchy-toggle-*` helpers |
| culcat ControlCenter | [repo](https://github.com/culcat/ControlCenter), #14506 | Medium |
| brm-src plugin-control-center | [repo](https://github.com/brm-src/plugin-control-center), #14553 | Medium (unread) |
| jesse-chelin control-centre | [repo](https://github.com/jesse-chelin/omarchy-control-centre), #4603 | Medium |
| Radial launchers (Omarchy Pie #12418, radial-menu #9218, OmaWheel #13488) | marketplace issues | Low: radial, but launchers, not settings |

Upstream: no issue or PR for a built-in quick-settings panel. Upstream interest is a settings app
(Omaset for 4.6, discussion [#18962](https://github.com/omacom/omarchy/discussions/18962); searchable settings
[#15428](https://github.com/omacom/omarchy/discussions/15428)). Nothing related in `docs/contributions.md`.

Our edge: the radial form is open ground, and none of the above is touch-first or knows the Z13 extras
(keyboard light, refresh rate, charge limit, pen battery). Before building, read `aryal.control-center`
(hot corner and Edit mode) to borrow ideas. caelestia and end-4 are GPL-3.0: design ideas only, no code.

## Code origin

Decided 2026-11-17: written from scratch to our engineering standards (`docs/engineering-standards.md`). No code is copied from the reference, so no third-party notice is needed.

## Build plan (draft, 4 steps, each one usable)

1. **Window + fan, fixed controls.** Service plugin, bottom-left, brightness/volume/mic arcs and the 6 toggles
   (Dropbox swapped for keyboard backlight). Tap zone + keybind + IPC.
2. **Touch pass.** Long-press for more, bigger targets, labels. Test on the Z13 by hand.
3. **Settings panel.** Corner, size, control list and order, JSON config. Hide missing hardware.
4. **Z13 extras.** Refresh rate, charge limit, pen battery, touchscreen toggle, rotation once decided.

## Decisions

| Question | Answer (2026-11-17) |
|---|---|
| Name | `omadials`, plugin id `io.github.felipecpaiva.omadials` |
| Public or private | Public, marketplace target |
| Copy or rewrite | Rewrite from scratch |
| Branding | Same method as omagnet and OmaBar: `branding/BRIEF.md`, then explorations |

Still open: does it replace bar widgets (audio, network, power) or sit beside them.
