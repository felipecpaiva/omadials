# Spike results (plan phase P1)

Run on the Z13 on 2026-11-17: Omarchy 4.5, Hyprland 0.56.2, Quickshell 0.3.2, eDP-1 2560x1600 at 180 Hz, scale 1.6
(logical 1600x1000). Each spike is a small throwaway under `spikes/`. Most ran as a separate `qs -p` process, so the
real shell was never at risk. Every system change was restored and read back.

| Spike | Question | Result | How verified | What it changes |
|---|---|---|---|---|
| S1 | Plugin-local `pragma Singleton` | **Pass** | Test plugin with a `qmldir` singleton loaded in the real shell; the service logged the singleton's value. Enabling a new plugin needed no shell restart | `theme/Theme.qml` may be a singleton; v0.1 can still pass it as a property |
| S2 | FileView sees a file created after load | **Pass** | `spikes/s2-fileview`: missing at start (load failed), then create, change, delete each fired `fileChanged` | Keep awake and other state files are watched, not polled |
| S3 | Input mask: corner zone, full-screen catcher, icon behind windows | **Pass** | `spikes/s3-mask` (two layer surfaces: input-less tab on `Bottom`, zone on `Top` over the output with a 32 px mask, an 8 s safety close). Screenshots: the tab hides under a window covering the corner; the open quarter draws over windows. Input batch with a uinput mouse (`spikes/s3-mask/run-batch1.sh`): tap opens, second tap closes, an outside click closes and does not reach the app below, the focused window keeps focus, clicks pass through when closed. A click on the `OnDemand` layer does **not** take keyboard focus: an Escape after a pointer open went to the focused app | Two windows per output. Pointer and touch opens never rely on Escape; keybind and IPC opens must request focus (check that with a command open, not a key test) |
| S4 | Screen reader on a layer surface | **Fail** | `spikes/s4-a11y`: AT-SPI lists the `qs` app with zero children, with and without `QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1`. No screen reader is installed | Known limit on Quickshell 0.3.2. Keep `Accessible` names in QML anyway, a full keyboard path, truthful status text and `status()` IPC. Recheck on each Quickshell release |
| S5 | Display refresh and scale writes with revert | **Pass** | `hyprctl eval 'hl.monitor({...})'` switched 180 to 60 Hz and back; timed revert armed | Displays detail writes through `hl.monitor` with the confirm and revert countdown. Read the current scale first and write it back unchanged |
| S6 | Power profile events | **Pass (read only)** | `org.freedesktop.UPower.PowerProfiles` `ActiveProfile` is `emits-change`; read `balanced`. The profile was not changed | Listen for property changes; no polling |
| S7 | Wi-Fi password through stdin | **Not run** | The maintainer did not approve a connect test | Inline password ships off; the Wi-Fi quick detail opens the full window for secured networks until S7 passes |
| S8 | Game mode runtime writes and exact revert | **Pass, with a design change** | The stock flags (`omarchy-hyprland-toggle no-animations`) reload Hyprland, and on this machine a reload reset the scale from 1.6 to 2 (hyprmoncfg sets 1.6 at runtime, `monitors.lua` falls back to 2). Restored by hand. Runtime `hyprctl eval 'hl.config({...})'` turned animations and shadows off and back with no reload and no scale change | Game mode uses runtime `hl.config` writes only, never the stock flags or a reload. It records the values it read and restores exactly those. A Hyprland reload drops runtime values, so game mode reads back after any reload and shows off if they are gone |
| S9 | Theme command | **Pass** | `omarchy-theme-set "Flexoki Light"` then `omarchy-theme-set "Tokyo Night"`; `omarchy-theme-current` read back both | Theme toggle and picker call `omarchy-theme-set <name>` with fixed argv; names from `omarchy-theme-list` |
| P1.8 | Per-app volume and media players | **Pass for audio; players untested** | `spikes/p18-pipewire`: default sink and its volume (1.10) read; a silent `pw-play` stream showed as an app stream with its own volume. Mpris loaded; no player was running | Per-app volume detail is buildable. Mpris discovery needs a running player to confirm |
| P1.9 | Rendering budget | **Pass** | `spikes/p19-render`: three ring arcs (one dashed) changing every frame with `Shape.CurveRenderer` at 180 Hz: 1081 frames, average 5.56 ms, p95 5.94, p99 6.48, max 6.88 | Use `Shape` with `CurveRenderer`. No custom shader needed |

## Still open in P1

- Keyboard focus after a keybind or IPC open, the Hyprland layer fade on first open, and a 60 fps capture of the open
  motion. Checked in P3 on the real plugin.
- S7 (not approved today).
- Mpris with a running player.
