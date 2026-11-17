# omadials controls: hardware backends

Written 2026-11-17 on the Z13 (Omarchy 4.5, Quickshell 0.3.2). Read-only checks only; nothing was changed.
Tags: [verified Z13] = a read command was run here. [from source] = read in `/usr/share/omarchy/bin/*` or QML typeinfo. [untested] = not run.

## Quickshell on this machine

- Quickshell 0.3.2, Omarchy build [verified Z13].
- Modules on disk [verified Z13]: `Bluetooth`, `Networking`, `Hyprland`, `Io`, `Services/{Pipewire,UPower,Notifications,Mpris,Polkit,SystemTray}`, `Wayland` (idle inhibitor, idle notify, screencopy), `I3`, `WindowManager`, `Widgets`.
- Rule for the plugin: use a Quickshell service where one exists (live, no polling), otherwise one `Process` call plus the cheapest event trigger.

## Summary table

| Control | Widget | Read | Write | Event source | Availability check | Root? |
|---|---|---|---|---|---|---|
| Screen brightness | dial | `brightnessctl -m -d <dev>` | `omarchy-brightness-display --monitor M N%` | poll | `/sys/class/backlight/*`, or DDC monitor | no |
| Keyboard backlight | dial (steps) | `brightnessctl -m -d asus::kbd_backlight` | `brightnessctl -d <dev> set N` | poll | `/sys/class/leds/*kbd_backlight*` | no |
| Output volume, mute | dial + toggle | Quickshell Pipewire | Pipewire `audio.volume`, `audio.muted` | Pipewire | default sink exists | no |
| Mic volume, mute | dial + toggle | Quickshell Pipewire | same; `omarchy-audio-input-mute` for LED | Pipewire | default source exists | no |
| Output / input device | picker | Pipewire nodes | `omarchy-audio-output-set-default <id> <name>` | Pipewire | 2 or more nodes | no |
| Wi-Fi radio, networks | toggle + picker | `Quickshell.Networking`, `nmcli radio wifi` | `nmcli radio wifi on/off` | Networking | `nmcli` shows `wifi` device | no |
| Bluetooth | toggle + picker | `Quickshell.Bluetooth` | `omarchy-bluetooth-power on/off` | Bluetooth | default adapter exists | no |
| Night light | toggle | `omarchy toggle nightlight --status` | `omarchy toggle nightlight` | poll | `which hyprsunset` | no |
| Do not disturb | toggle | `omarchy-shell notifications isDnd` | `omarchy toggle notification silencing` | inotify `notifications/quiet.json` | `omarchy-shell` works | no |
| Keep awake | toggle | `omarchy toggle idle status` | `omarchy toggle idle stay-awake` / `allow-idle` | inotify `indicators/stay-awake` | always | no |
| Power profile | picker | `powerprofilesctl get` | `omarchy-powerprofiles-set autodetect <p>` | D-Bus | `omarchy-powerprofiles-list` | no |
| Battery, time left | readout | Quickshell UPower | none | UPower | `omarchy-battery-present` | no |
| Charge limit | dial | sysfs `charge_control_end_threshold` | `asusctl battery limit N` | poll | file and `asusctl` | no |
| Pen, peripheral batteries | readout | UPower devices | none | UPower | non-laptop battery devices | no |
| Touchpad | toggle | state file | `omarchy toggle touchpad on/off` | inotify state file | `omarchy-hw-touchpad` | no |
| Touchscreen | toggle | state file | `omarchy toggle touchscreen on/off` | inotify state file | `omarchy-hw-touchscreen` | no |
| Displays | picker + dial | `hyprctl -j monitors all` | `hyprctl`, `omarchy-hyprland-monitor-scaling` | Hyprland IPC | monitors list | no |
| Rotation | later | `monitor-sensor` | undecided | iio D-Bus | `which monitor-sensor` | no |
| GPU mode | readout | `supergfxctl -g` | `omarchy toggle hybrid gpu` | poll | `which supergfxctl` | yes |
| Airplane mode | toggle | `rfkill -J` | `rfkill block/unblock all` | `rfkill event` | `rfkill list` | no |
| Screen recording | toggle | `omarchy-capture-screenrecording --status` | same, `--stop-recording` | poll | `which gpu-screen-recorder` | no |
| Camera, mic privacy | readout | Pipewire streams | none | Pipewire | camera node | no |

## Per-control details

### Screen brightness
- Read [verified Z13]: `brightnessctl -m -d amdgpu_bl1` gives `amdgpu_bl1,backlight,42598,65%,65535`. Parse field 4 (percent).
- Write [from source]: `omarchy-brightness-display [--no-osd] [--monitor NAME] [+N%|N%-|N%|off|on]`. It picks the path itself: internal panels (`eDP-`, `LVDS-`, `DSI-`) use brightnessctl, Apple displays use `omarchy-brightness-display-apple`, other external monitors use `omarchy-brightness-display-ddc <monitor> [+N%|N%-|N%]` (needs `ddcutil`).
- DDC gotchas [from source]: the bus is cached 60 s when unavailable, a probe is slow (seconds), and the monitor may not support DDC/CI. Read DDC only on open, never on the UI thread.
- Root: none if the user has the stock udev backlight rule (works here) [verified Z13]. If brightnessctl cannot write, hide the dial.
- Detection: `ls /sys/class/backlight` non-empty. A desktop with one DDC monitor has no backlight, so also offer the dial per external monitor after a lazy DDC probe.
- Event: sysfs may not emit inotify [untested]; poll every 2 s while open.

### Keyboard backlight
- Read [verified Z13]: `brightnessctl -m -d asus::kbd_backlight` gives `...,2,67%,3` (levels 0-3, so 4 steps).
- Write [from source]: `omarchy-brightness-keyboard up|down|cycle|off|restore` (saves the level in `$XDG_RUNTIME_DIR` for lock). For an absolute level use `brightnessctl -d asus::kbd_backlight set N` [untested].
- Treat it as a stepped dial: snap to `max` steps. Do not use percent.
- Detection [from source]: first of `/sys/class/leds/*kbd_backlight*`. Absent on desktops: hide.

### Output volume and mute
- Read: `Quickshell.Services.Pipewire` `Pipewire.defaultAudioSink.audio.volume` and `.muted`; wrap in `PwObjectTracker` or the audio property stays null [from source, standard Quickshell usage; untested here].
- CLI check [verified Z13]: `wpctl status` shows sink 60 "Ryzen HD Audio Controller Analog Stereo [vol: 1.10]". The volume is above 1.0, so the dial must allow 0 to 150% and show an overdrive zone, or cap at 100%.
- Write: set `audio.volume` through Pipewire. Alternative stock helper: `omarchy-audio-output-volume raise|lower|mute-toggle|+N|-N` (shows the OSD; resolves through DSP sinks via `omarchy-audio-output-sink`) [from source].

### Mic volume and mute
- Read [verified Z13]: source 61 vol 1.00 via `wpctl status`. Quickshell: `Pipewire.defaultAudioSource.audio`.
- Write: Pipewire property, or `omarchy-audio-input-mute` (toggle only; also drives the mic-mute LED through `omarchy-brightness-keyboard-mute` and shows an OSD) [from source]. Use the stock command for the mute toggle so the LED stays right.

### Default output / input device
- Read: Pipewire `nodes` filtered by `isSink` and `audio` (outputs) or not `isSink` (inputs); skip streams.
- Write [from source]: `omarchy-audio-output-set-default <node-id> <sink-name>` (also moves app streams; skips EasyEffects). `omarchy-audio-input-set-default` exists for inputs (args not read yet) [untested].
- Verified Z13: one sink and one source only, so the picker is hidden here. Show a picker only when 2 or more.

### Wi-Fi radio and network list
- Read [verified Z13]: `nmcli radio` shows `WIFI enabled`; `nmcli -t -f SSID,SIGNAL,IN-USE dev wifi list` lists networks (one in use). Quickshell 0.3.2 has `Quickshell.Networking` [verified Z13 on disk, API not exercised].
- Write: `nmcli radio wifi on|off` [from source of research table, untested]. Connect to a saved network: `nmcli con up <name>`; a new secured network uses the quick detail password field through a secure stdin flow, UNVERIFIED S7 in architecture.md. Never put passwords in argv. Without a keyboard offer the stock panel.
- Detection: `nmcli -t -f TYPE dev` contains `wifi` [verified Z13: `wlp194s0`]. If NetworkManager is absent (Omarchy may use iwd on some builds), `Quickshell.Networking` or `iwctl` is the fallback [untested].

### Bluetooth power and devices
- Read: `Quickshell.Bluetooth` (`Bluetooth.defaultAdapter.enabled`, `.devices`) [on disk verified]. CLI check [verified Z13]: `bluetoothctl show` gives `Powered: yes`.
- Write [from source]: `omarchy-bluetooth-power on|off|toggle|is-on`. Use this, not `bluetoothctl power`: Omarchy uses the rfkill soft block as the state so it survives reboot, and `bluetoothctl power on` fails while blocked.
- Devices: connect with `omarchy-bluetooth-device` (args not read) or Quickshell `device.connect()` [untested].

### Night light
- Read [verified Z13]: `omarchy toggle nightlight --status` gives `{"enabled":false,"temperature":null}` (hyprsunset not running now, so temperature is null).
- Write [from source]: `omarchy toggle nightlight` flips between 4000 K and 6500 K (off also resets to identity). It starts `hyprsunset` if needed and retries up to 10 times.
- Temperature dial: `hyprctl hyprsunset temperature <K>` works only while hyprsunset runs [from source]. Offer a dial 2500-6000 K only as an optional extra; the toggle alone matches stock. Setting an arbitrary temperature will not persist across a restart [untested].

### Do not disturb
- Read [verified Z13]: `omarchy-shell notifications isDnd` prints `off`.
- Write [from source]: `omarchy toggle notification silencing` (calls `toggleDnd`, then refreshes the indicators). The state is under `~/.local/state/omarchy/notifications/` (`quiet.json` exists) [verified Z13 listing; file meaning untested], a good inotify target.

### Keep awake
- Read [verified Z13]: `omarchy toggle idle status` gives `{"enabled":false,...}`. The state is just a file: `~/.local/state/omarchy/indicators/stay-awake` [from source; absent now, matches false].
- Write [from source]: `omarchy toggle idle stay-awake` or `allow-idle` (explicit, safer than `toggle`).
- Event: inotify on the file's directory (the file does not exist when off).

### Power profile
- Read [verified Z13]: `powerprofilesctl get` gives `balanced`; `list` shows performance, balanced, power-saver.
- Write [from source]: `omarchy-powerprofiles-set autodetect <profile>`. It saves the choice per AC or battery and refreshes the shell. Use it rather than `powerprofilesctl set` so Omarchy's restore logic stays consistent.
- Available profiles: `omarchy-powerprofiles-list` (so power-saver may be missing on some machines) [from source].
- Event: D-Bus `net.hadess.PowerProfiles` `ActiveProfile` changes (or `org.freedesktop.UPower.PowerProfiles`) [untested]. Otherwise poll on open.

### Battery, time left, charge limit
- Read [verified Z13]: UPower BAT0 shows `state: charging`, `percentage: 31%`, `time to full: 43.2 minutes`. `omarchy-battery-status` prints `Battery 31%  ·  34m to full  ·  67.5W / 70Wh`; `omarchy-battery-present` exits 0 when there is a battery. Use `Quickshell.Services.UPower` (`UPower.displayDevice`, `UPower.onBattery`) for live values.
- Charge limit read [verified Z13]: `/sys/class/power_supply/BAT0/charge_control_end_threshold` is `85`; `asusctl battery info` prints `Current battery charge limit: 85%`. The sysfs file is generic (many laptops: ThinkPad, Framework) so the read works beyond ASUS.
- Charge limit write: `asusctl battery limit <20-100>` (talks to `asusd`, no sudo) [from source of `--help`, untested]. A generic writer needs root for sysfs and is not safe to ship; show it read-only when `asusctl` is missing.

### Pen and peripheral batteries
- Read [verified Z13]: `upower -e` lists `battery_hid_0018o04F3o43C7x0008_battery_7`, model `ELAN9008:00 04F3:43C7 Stylus`, `percentage: 0%`. A 0% reading may mean "unknown" or empty; treat it as unknown when `state` is unknown [untested].
- Quickshell UPower `UPower.devices`, filter type battery and `isLaptopBattery == false` [on disk verified, filter untested].

### Touchpad and touchscreen
- Read [verified Z13]: there is no status command. `omarchy-hw-touchpad` prints `asustek-computer-inc.-gz302ea-keyboard-touchpad`; `omarchy-hw-touchscreen` prints `elan9008:00-04f3:43c7`. State is a plain file `~/.local/state/omarchy/toggles/hypr/<kind>-disabled-name` that holds the device name when disabled [from source]. The file exists = disabled. Live check: `hyprctl devices -j` (if a device shows `enabled`; field not confirmed) [untested].
- Write [from source]: `omarchy toggle touchpad on|off|toggle`, same for `touchscreen`. It uses `hyprctl eval hl.device({...enabled=...})`.
- Gotcha for the Z13: the "touchpad" is on the detachable keyboard, so it disappears when detached (device name prints empty, `rc=1`): hide the toggle then.
- Gotcha: turning off the touchscreen on a tablet removes the way to turn it back on. Add a confirm, and never allow it when no keyboard or pointer is attached.

### Displays
- Read [verified Z13]: `hyprctl -j monitors all` gives eDP-1 at 2560x1600, 180 Hz, scale 1.6, `transform 0`, `vrr false`, `mirrorOf none`, with `availableModes` (13 here). `omarchy-monitor-state` wraps the common fields [from source].
- Scale write [from source]: `omarchy-hyprland-monitor-scaling up|down|SCALE` on the focused monitor; allowed steps 1, 1.25, 1.6, 2, 3, 4, rounded to a clean value. Picker with those steps. It logs each change.
- Refresh rate, per-monitor on/off, mirror: Hyprland monitor rules via `hyprctl` (`hyprctl keyword monitor` is the older route; on this Omarchy rules are Lua, so check `hl.monitor` and `hyprctl eval` before writing) [untested, do not guess]. Stock helpers exist: `omarchy-hyprland-monitor-internal`, `-internal-mirror`, `-clamshell`, `-external-active`, `-laptop` [from source names; args not read].
- Event: Hyprland IPC `monitoradded`, `monitorremoved`, `configreloaded` via `Quickshell.Hyprland`; re-read on each.

### Rotation
- `monitor-sensor` (iio-sensor-proxy) is installed [verified Z13]; Hyprland `transform` is 0 now. Auto-rotation is undecided, see the omarchy-z13 plan (github.com/felipecpaiva/omarchy-z13, `docs/plan.md` Step 3). Build nothing until that is decided.

### GPU mode
- `supergfxctl` is not installed on this Z13 [verified Z13: command not found]; `omarchy-hw-hybrid-gpu` exits 1 [verified Z13]. So the control must be hidden here.
- Where present [from source]: read `supergfxctl -g` (prints Integrated, Hybrid, ...); write through `omarchy toggle hybrid gpu`, which uses sudo, asks for confirmation, and may need a logout. Never run it from a dial. Show as a read-only chip with a "details" action.

### Airplane mode
- No Omarchy command exists (grep found none) [verified Z13]. Use `rfkill -J` to read, `rfkill block all` / `unblock all` to write, `rfkill event` for changes [untested]. Radios seen: `hci0`, `asus-wlan`, `asus-bluetooth`, `phy0`, all unblocked [verified Z13].
- Gotcha: Omarchy persists Bluetooth through rfkill, so turning airplane mode off must restore only what was on before. Store the prior state.

### Screen recording
- Read [from source]: `omarchy-capture-screenrecording --status` answers whether our recording runs (kept read-only for the bar). Verified Z13: it printed nothing while idle; exit code not recorded.
- Write [from source]: `omarchy capture screenrecording [--with-desktop-audio] [--with-microphone-audio]` starts (it opens a region picker); `--stop-recording` stops. Backend `gpu-screen-recorder` is installed [verified Z13], with `wf-recorder` fallback.

### Camera and mic privacy
- No Omarchy privacy switch exists. Webcam is `ASUS 5M webcam` (v4l2) in `wpctl status` [verified Z13]. Readout only: a dot when a Pipewire stream captures from camera or mic [untested]. No toggle.

## Proposed common backend interface

Every control is one QML object with the same properties, so the dial UI has no control-specific code.

| Property | Meaning |
|---|---|
| `id` | Stable string used in the user's config (`brightness`) |
| `kind` | `dial`, `toggle`, `picker`, or `readout` |
| `available` | False hides the control; must settle without blocking the UI thread |
| `value` | 0 to 1 for a dial, boolean for a toggle, key for a picker, text for a readout |
| `min`, `max`, `step` | Dial range, or discrete levels (keyboard light, power profile) |
| `options` | Picker only: list of `{key, label, icon}` |
| `set(v)` | Non-blocking write; the shown value comes back through the read path |
| `label`, `icon` | Short name, icon, and a unit string such as `65%` |
| `busy`, `error` | Pending state and last failure text |
| `detailsTarget` | What long press opens: a stock panel or command, or empty |
| `refresh()` | Re-read now; called on open |

Rules:
1. Prefer a Quickshell service; else one `Process` read plus a file or D-Bus trigger. Poll only while the corner is open, every 2 to 4 s.
2. Writes go through stock `omarchy-*` helpers where they exist (they keep persistence and LED effects). Pass `--no-osd` where offered. Debounce drags and send the final value on release.
3. A failed read makes `available` false, never a plausible default. Show "unknown", not 0.
4. Dangerous writes (touchscreen off, display off, charge limit, GPU mode) need a confirm and a lockout guard.
5. A group with no hardware (battery on a desktop) disappears whole.


## Round 2 readout ring sources

All use existing kind `readout`, ring placement, null for unknown/disconnected, no writes or knob, flat caps and read-only labels. Tap opens related detail. Selected device identity is configurable and preserved when disconnected.

| Readout | Value source | Parameter and events | Verification |
|---|---|---|---|
| Bluetooth headset battery | UPower device percentage, matched to chosen Bluetooth device | deviceAddress; Bluetooth connection events and UPower device changes | UNVERIFIED: device-address mapping and headset battery support on this machine |
| Wi-Fi signal | `nmcli -t -f SSID,SIGNAL,IN-USE dev wifi list` or Quickshell.Networking signal | selected interface (auto default); Networking updates, bounded open-only fallback refresh | CLI list previously verified; Quickshell signal property and mapping UNVERIFIED |
| Laptop battery | Quickshell UPower displayDevice percentage | display device; UPower events | Earlier UPower CLI read verified; live QML binding UNVERIFIED |
| Pen battery | UPower devices percentage for selected stylus | devicePath; UPower events | Device enumeration previously verified; unknown-state mapping UNVERIFIED |

A disconnected device says "not connected", never 0%. An attached device without battery telemetry says "unknown". Do not interpret the earlier pen 0% sample as a reliable empty battery without a known state. No new machine commands were run for this design round.


## Round 3 service contracts

Per-app volume: use `Quickshell.Services.Pipewire` nodes for playing output streams, track each with PwObjectTracker, read and write its audio.volume. Keep node identity rather than app name as the row key; several streams from one app get distinct rows. Filter out devices and capture streams. Keep the output picker using the stock device helper described above. API filtering and stream lifetime handling remain UNVERIFIED on the Z13.

Media: `Quickshell.Services.Mpris` supplies players, title, artist, playback state, position, length and supported actions. Detail exposes previous, play/pause and next only when supported. Seek only when supported. Unknown length is explicit, never a fake zero. Prefer the playing player; keep an explicit selection until it disappears. Live Mpris binding is UNVERIFIED.

Game mode: read exact typed runtime option values, journal before writes, apply only selected allowlisted options, restore on off/logout/shell death. See architecture S8, UNVERIFIED. Never change config files.

Theme: use Omarchy's own `omarchy-theme-set` with one validated installed theme argument, then read back the active theme. See S9, UNVERIFIED. Prototype names and actions are fake.
