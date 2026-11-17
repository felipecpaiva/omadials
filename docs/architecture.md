# omadials architecture

Status: design only, no plugin code yet (2026-11-17). Inputs: [research.md](research.md), [references.md](references.md),
[platform.md](platform.md), [controls.md](controls.md), [ux.md](ux.md), [engineering-standards.md](engineering-standards.md),
plus the house patterns in `omahop/docs/architecture.md`, `omahop/docs/file-contract.md` and `OmaBarConfigurator/docs/architecture.md`.
Claims nobody has checked on the machine are marked UNVERIFIED and point at a spike (S1 to S7, section 13).

## 1. Goals and non-goals

**Goals**
- One quarter-circle corner that holds the hardware quick settings, touch first, mouse and keyboard fine (ux.md section 1).
- Adding a control means one new folder and one catalog entry. The core does not change.
- Every rule that can be tested without a screen lives in pure JS with Node tests.
- One config file, `~/.config/omadials/config.json`, is the full contract for the plugin and for a later standalone settings app.
- Follows the Omarchy theme live, and costs nothing while closed.

**Non-goals**
- No launcher, media player, notifications or weather. Hardware settings only.
- No new gestures. 3 and 4 finger swipes stay as they are (ux.md section 2).
- No commands read from config, no network, no root, no writes to `shell.json`.
- No rotation control until `omarchy-z13/docs/plan.md` Step 3 is decided (controls.md, Rotation).
- No code copied from denon.corner, aryal or GPL shells (research.md, Code origin).

## 2. Conflicts between inputs, resolved

| Topic | Inputs say | Decision |
|---|---|---|
| Volume above 100% | controls.md: Z13 reads 110%, allow 150% or cap. ux.md section 4: cap at 100 | Setting `volume.maxPercent`, default 100 (ux.md wins). A value above the cap shows truthfully ("110%", knob pinned, over-cap tick); input never writes above the cap. |
| Invalid config | platform.md section 5, standards: "fall back, log once" | Report, skip, show (this brief): default at runtime, listed in the settings banner, warning dot on the gear, one journal line. The file is untouched until the user edits that field. |
| Control interface | controls.md: boolean `available`, 4 kinds | Superseded by section 4: closed `availability` set and a fifth kind, `stepped`. |
| Keyboard light | research.md step 1: a toggle. controls.md: a stepped dial | Kind `stepped`, placeable on a ring (snaps) or on the toggle arc (tap goes to the next level). |
| Wi-Fi password | ux.md section 3: inline. controls.md: stock panel | Quick detail includes inline password entry. UNVERIFIED S7: use `nmcli --ask` with credentials fed through process stdin, never argv, shell interpolation, journal, config or diagnostics. Without a physical keyboard show a reason and offer the stock network window. |
| Ring tolerance, trigger | references.md: 28 px, 12 px zone, 120 ms | ux.md wins: 44 px band, 32 px tap zone, 2 px pointer corner, 150 ms push. |
| Off state colour | references.md table: "muted" alpha | ux.md section 6 wins: never `muted` for text or off states. |
| Idle cost | standards: zero idle cost | The trigger zone is a static mask, no timer. Polls, processes, file watches and streams run only while open. Quickshell services are already live in the shell. |

## 3. Layers

```
                 config.json  (the contract, section 6)
                      |
  +-------------------v--------------------+      +-------------------+
  | Config: ConfigStore.qml                |      | logic/*.js (pure) |
  |  load, validate, migrate, atomic save  |<-----|  Geometry         |
  +-------------------+--------------------+      |  ValueMap         |
                      |                           |  ConfigSchema     |
  +-------------------v--------------------+      |  ConfigMigrate    |
  | Registry.qml + controls/catalog.json   |      |  Layout           |
  |  makes one backend per enabled id      |      |  Gesture          |
  +-------------------+--------------------+      |  CommandMachine   |
                      |                           |  Contrast         |
  +-------------------v--------------------+      +---------^---------+
  | Control backends  controls/<id>/       |                |
  |  same interface (ControlBase.qml)      |  used by every layer above Views
  |  commands only via CommandRunner.qml   |                |
  +-------------------+--------------------+                |
                      |                                     |
  +-------------------v--------------------+   +------------+------+
  | View models: vm/FanModel.qml           |   | theme/Theme.qml   |
  |  rings, toggle strip, readout, status  |   | sole reader of    |
  +-------------------+--------------------+   | Commons.*         |
                      |                        +---------+---------+
  +-------------------v--------------------+             |
  | Views: views/*  (window, rings,        |<------------+
  |  toggles, readout, detail host)        |
  +-------------------+--------------------+
                      |
  +-------------------v--------------------+
  | Settings: settings/* (panel kind)      |  writes config.json only
  +----------------------------------------+
```

Import rules. Each one is a grep gate in `test/isolation.sh`, in the style of OmaBar's `run-all.sh`.

| Layer | May use | Must not use |
|---|---|---|
| `logic/` | nothing (no Qt, no other logic file) | anything |
| `core/ConfigStore.qml` | `logic/ConfigSchema.js`, `logic/ConfigMigrate.js`, FileView | views, controls |
| `core/CommandRunner.qml` | `Quickshell.Io.Process` | the only file allowed to start a process |
| `controls/<id>/` | `core/ControlBase.qml`, `core/CommandControl.qml`, the runner (injected), Quickshell services, `logic/` | views, other controls, `Commons` |
| `vm/` | registry, config, `logic/` | runner, `Process` |
| `views/`, `settings/` | vm, Theme, `logic/Geometry.js`, `logic/Gesture.js`, control methods `set`, `refresh`, `activate` | `Process`, `Util.exec*`, `Commons.*`, runner |
| `theme/Theme.qml` | `Commons.Color`, `Commons.Style` | everything else |

`logic/` files never import each other. omahop's loader (strip `.pragma library`, wrap in `new Function`) cannot follow `.import`, so composition happens in QML, which passes one module's result into the next.

## 4. Control contract

Every control inherits `core/ControlBase.qml`; views see only this interface (extends controls.md, Proposed common backend interface).

| Member | Type | Meaning |
|---|---|---|
| `id` | string | Stable, used in config (`brightness`). |
| `kind` | `"dial" \| "stepped" \| "toggle" \| "picker" \| "readout"` | Closed set. |
| `placements` | list of `"ring" \| "arc" \| "chip" \| "readout"` | Where it may sit. From the catalog. |
| `availability` | `"probing" \| "available" \| "unavailable" \| "error"` | Closed set. |
| `reason` | string | Required, non-empty, for `unavailable` and `error`. |
| `value` | number, int, bool, string or `null` | Native units: percent for dials, level index for stepped, bool, option key, text. `null` means unknown, never 0. |
| `range` | `{min, max, floor, step, unit}` | Dials. `floor` is 1 for brightness (ux.md section 4). |
| `steps` | list of `{key, label}` | Stepped and picker. |
| `writeState` | `"idle" \| "pending" \| "failed"` | Drives the pending outline (ux.md section 4, Toggles). |
| `lastError` | string | Shown on the status line. |
| `label`, `icon`, `valueText` | string | `valueText` is "65%", "Balanced", "On, HomeNet". |
| `detailKind` | `"none" \| "rows" \| "custom" \| "external"` | What a long press opens. |
| `detailRows` | list of `{key, label, sub, state, icon}` | For `rows` (networks, devices, monitors). |
| `set(v)` | method | Non-blocking. The value shown comes back through the read path. |
| `refresh()` | method | Re-read now. Called on open. |
| `activate(rowKey)` | method | Picks a detail row. |
| `active` | bool, input | True while the fan is open. Gates every poll and watch. |
| `changed(reason)` | signal | For the status line. |

How each state shows:

| `availability` | Corner | Settings |
|---|---|---|
| `probing` | Slot kept, drawn as an empty outline, no input | "Checking" |
| `available` | Normal | Normal |
| `unavailable` | Hidden, slot freed (ux.md principle 6) | Greyed, "Not found on this machine" plus `reason` |
| `error` | Shown with a warning icon, input off, status line shows `reason` | Listed in the problems banner |

Exhaustive mapping without a compiler: each closed set is a frozen array in the module that owns it (`KINDS`, `AVAILABILITY`, `WRITE_STATES`, `DETAIL_KINDS`). Mappers `switch` over it and return `{error: "unknown_<set>"}` otherwise, and a test walks every member through every mapper. Parsed command output passes a runtime guard: unknown text becomes `error` with the raw text as reason (coding-approach, discriminated unions).

### Two backend styles, one interface

1. **Command backends** (brightness, keyboard light, Wi-Fi radio, night light, DND, keep awake, power profile, airplane, touchpad, touchscreen, charge limit, recording). A pure `spec.js` gives `probe` and `read` argv, `parse(stdout, code)` to `{availability, value, reason}`, `write(value)` to argv, and a `watch` descriptor. `Backend.qml` is a 10-line `CommandControl`, which feeds runner results into `logic/CommandMachine.js`, a reducer `(state, event) -> {state, effects}` (effects: `{run: argv}`, `{after: ms}`). All timing (optimistic toggle, re-read after 450 ms, debounce) lives in the reducer, so Node tests it.
2. **Service backends** (volume, mic, batteries, Bluetooth, Wi-Fi networks, audio devices, displays) bind to Quickshell Pipewire, UPower, Bluetooth, Networking or Hyprland (controls.md). Pure mapping lives in `map.js`. Writes with an Omarchy helper still use the runner (`omarchy-bluetooth-power`, `omarchy-audio-input-mute` for the LED).

### Event source or poll

`watch` is a closed set: `service` (binding), `file` (FileView `watchChanges`), `stream` (such as `rfkill event`), or `poll` (2 s brightness, 4 s otherwise; controls.md rule 1). All start when `active` turns true, stop when it turns false, and each open calls `refresh()` once. UNVERIFIED: FileView firing for a file created after load (keep awake's state file is absent when off). Spike S2; if not, that control polls.

### Adding a control (the scalability story)

1. Make `controls/<id>/` with `Backend.qml` and either `spec.js` or `map.js`, a test `<id>.test.mjs`, and optionally `Detail.qml`.
2. Add one entry to `controls/catalog.json`: id, kind, placements, label, icon, default placement, and an `options` schema (types, limits, defaults).

QML cannot list a folder, so the catalog is the one audited index (references.md: fixed list, no commands from files); `test/catalog-check.mjs` fails on an entry without a folder or a folder without an entry. Options sit under `options.<id>` and are validated against the catalog schema, so adding a control never bumps the config version. The registry creates `controls/<id>/Backend.qml` only for enabled ids, or all while settings is open.

## 5. Pure logic modules

All files are `.pragma library`, have no Qt calls, have no cross-imports, and stay under 250 lines.

| File | Holds |
|---|---|
| `Geometry.js` | `toCanonical` and `fromCanonical` (4-corner mirroring, positions only, never a negative scale; references.md, Mirroring), `polar(x, y, H)`, `angleToFraction` over the 6 to 84 degree sweep, `fractionToAngle`, `ringRadii(R, n)`, `hitRing(d, radii, band)`, `knobPos`, `arcSlots(r, pitch)`, `capacity(size, shortSide)` (R = S 330, M 420, L 500, clamped to 45% of the short side; toggles = floor(r x 1.36 / 48); ux.md section 3), `bubblePos` (56 px toward the screen centre). |
| `ValueMap.js` | Native value, fraction and angle conversions. Stepped snapping. `floor`. The over-cap case. Wheel steps (5%, 1% with Shift, pixel deltas into whole steps). Keyboard steps (5, 1, 25, Home, End). |
| `Gesture.js` | Reducer for tap, drag-open (past 40%), 6 px drag start, ring lock, long press (450 ms, fill from 150 ms, 6 px cancels toggle hold, 10 px dial label hold), push dwell. Every threshold is a named constant from ux.md sections 2 and 4. |
| `Layout.js` | Config, catalog, availability and capacity in; rings outer to inner, toggle strip offset and scroll bounds, readout, over-capacity errors out. |
| `ConfigSchema.js` | `DEFAULTS` (the one place), `LIMITS`, closed enums, `validate(obj, catalog)` to `{config, errors}`, `patch(text, path, value)`, which keeps unknown keys. |
| `ConfigMigrate.js` | Ordered pure steps `vN -> vN+1`. |
| `CommandMachine.js` | Command backend reducer (section 4). |
| `Contrast.js` | Relative luminance, contrast ratio, `isLight`, accent fallback (ux.md section 6). |

Test runner: house style, `node` with no npm packages. `test/load.mjs` strips `.pragma library` and evaluates the file with `new Function`, as `omahop/tests/config_io.test.mjs` does. Tests are `test/*.test.mjs` and `controls/*/*.test.mjs`, all run by `bash test/run-all.sh` (engineering-standards.md, Definition of done).

## 6. Config contract

Path `~/.config/omadials/config.json` (platform.md section 5, option B). Draft v1 with defaults (not frozen until v0.5):

```json
{
  "version": 1,
  "corner": "bottom-left",
  "size": "M",
  "outputs": { "mode": "all", "names": [] },
  "trigger": { "tapZone": true, "pushDelayMs": 150 },
  "cornerIcon": { "mode": "always", "aboveWindows": true, "source": "default" },
  "controls": { "brightness": { "shown": true, "icon": "default" }, "wifi": { "shown": true, "icon": "default" } },
  "behavior": { "idleTimeoutS": 10, "closeOnPointerLeave": true },
  "ringStyle": { "track": "solid", "knob": "round", "thickness": "normal" },
  "readoutRings": [
    { "id": "headphones", "kind": "readout", "source": "bluetoothBattery", "deviceAddress": "AA:BB:CC:DD:EE:FF", "enabled": false, "order": 2 },
    { "id": "signal", "kind": "readout", "source": "wifiSignal", "interface": "auto", "enabled": false, "order": 3 }
  ],
  "dials": [
    { "id": "brightness", "enabled": true },
    { "id": "volume", "enabled": true },
    { "id": "mic", "enabled": true }
  ],
  "toggles": [
    { "id": "wifi", "enabled": true, "tapAction": "switchRadio", "holdAction": "quickDetail" },
    { "id": "bluetooth", "enabled": true },
    { "id": "nightlight", "enabled": true },
    { "id": "dnd", "enabled": true },
    { "id": "keepawake", "enabled": true },
    { "id": "kbdlight", "enabled": true },
    { "id": "airplane", "enabled": false },
    { "id": "touchpad", "enabled": false },
    { "id": "touchscreen", "enabled": false },
    { "id": "recording", "enabled": false }
  ],
  "readout": { "battery": true, "powerProfile": true, "penBattery": true },
  "options": {
    "brightness": { "wheelStep": 5, "monitor": "auto" },
    "volume": { "wheelStep": 5, "maxPercent": 100 },
    "mic": { "wheelStep": 5 }
  }
}
```

Enums: `corner` is `top-left | top-right | bottom-left | bottom-right`. `size` is `S | M | L`. `outputs.mode` is `all | focused | named`. Limits: `pushDelayMs` 0 to 500, `idleTimeoutS` 0 (off) to 120, `maxPercent` 100 or 150. List order is display order: the first dial is the outermost ring (ux.md section 3).

**Validation.** Each error is `{path, code, message}` with `code` from a closed set: `parse_error`, `newer_version`, `wrong_type`, `out_of_range`, `unknown_value`, `unknown_control`, `duplicate_control`, `wrong_placement`, `over_capacity`. The bad entry is skipped, or for a scalar its default is used, and it is shown (section 2). Unknown top-level keys and unknown control ids are kept on disk (a newer version may know them) and reported once. A file that does not parse keeps the last good config, or the defaults, and puts settings into read-only mode with "Fix the file or Reset". A broken file is never overwritten silently.

**Writes.** Only the settings writer writes. It re-reads the text, patches the one changed path, and writes with FileView `atomicWrites: true` (the app uses `QSaveFile`), after a fixed-argv `mkdir -p` (omahop `SettingsStore.qml`). Debounced 300 ms, serialised, newest wins.

**Live reload.** `watchChanges: true`; a reload re-validates and the registry diffs enabled ids, within 1 s (ux.md acceptance 22). Our own write echoes are harmless.

**Migration.** `version` is required. Older files are migrated in memory and written back only on the next user change, after a one-time copy to `config.v<N>.bak`. A `version` newer than ours opens read-only with a warning, never downgraded. Each migration step ships with a fixture pair in `test/fixtures/config/`.

**Contract for the app.** Schema v1 freezes at v0.5 in `docs/file-contract.md` (omahop style). The fixtures (input, expected config, expected errors) are the conformance suite for both writers.

## 7. Plugin layout

Size budget: QML at most 150 lines (hard cap 200, standards); JS at most 250. Checked with `wc -l` in `run-all.sh`.

| Path | Purpose |
|---|---|
| `manifest.json` | Kinds, entry points |
| `Service.qml` | Root: builds Theme, ConfigStore, Registry, FanModel, one CornerWindow per screen, ShellIpc (80) |
| `core/ConfigStore.qml` | Load, watch, validate, migrate, patch-write (120) |
| `core/CommandRunner.qml` | The only `Process` owner: argv arrays, timeout, one in flight per key (120) |
| `core/ControlBase.qml` | The interface, no behaviour (60) |
| `core/CommandControl.qml` | Runs a `spec.js` through CommandMachine (110) |
| `core/Registry.qml` | Catalog plus config to live backends; `status()` JSON (100) |
| `theme/Theme.qml` | Role mapping (section 8) (120) |
| `vm/FanModel.qml` | Layout.js output as models; status line text (120) |
| `views/CornerWindow.qml` | PanelWindow, anchors, mask, focus `OnDemand`, namespace `omadials` (120) |
| `views/TriggerZone.qml` | Tap zone and push dwell, feeds Gesture.js (90) |
| `views/Fan.qml` | Composes surface, rings, arc, readout; open motion (120) |
| `views/FanSurface.qml` | Quarter-disc and detail-square shape (80) |
| `views/RingStack.qml`, `Ring.qml`, `Knob.qml` | Track and fill drawing, one knob (60 to 90 each) |
| `views/RingInput.qml` | Press, drag, wheel, keys on the rings (130) |
| `views/ToggleArc.qml`, `ToggleButton.qml` | Scrollable arc, one toggle with long press fill (100 each) |
| `views/Readout.qml`, `ProfileChip.qml`, `StatusLine.qml`, `ValueBubble.qml` | Corner texts and feedback (60 to 90 each) |
| `views/DetailHost.qml`, `DetailRows.qml` | Loader for the detail, generic row list (90 each) |
| `views/ConfirmRevert.qml` | Confirm plus revert countdown (section 10) (80) |
| `settings/SettingsPanel.qml` | Panel root: `open`, `close`, window, page switch (120) |
| `settings/CornerPage.qml`, `ControlsPage.qml`, `ControlRow.qml`, `BehaviorPage.qml`, `AboutPage.qml` | One page or row each (150 max) |
| `settings/ProblemsBanner.qml`, `UndoBar.qml`, `PreviewPane.qml` | Config errors, 10 s Undo, live preview at 60% (90 each) |
| `controls/catalog.json` | The audited control index |
| `controls/<id>/...` | Section 4 |
| `logic/*.js` | Section 5 |
| `test/run-all.sh`, `load.mjs`, `*.test.mjs`, `isolation.sh`, `scrub.sh`, `qml-health.sh`, `fixtures/` | Checks |
| `README.md`, `LICENSE`, `preview.png`, `docs/` | Listing material |

```json
{
  "schemaVersion": 1,
  "id": "io.github.felipecpaiva.omadials",
  "name": "omadials",
  "version": "0.1.0",
  "author": "Felipe Paiva",
  "license": "MIT",
  "description": "Quick settings in a screen corner: tap the corner for brightness, volume and toggles. Settings: omarchy-shell omadials settings",
  "kinds": ["service", "panel"],
  "entryPoints": { "service": "Service.qml", "panel": "settings/SettingsPanel.qml" }
}
```

`bar-widget` is left out for now (decision 4). The panel is not `keepLoaded` (platform.md section 7).

IPC target `omadials` (platform.md section 2; typed args, string or void returns):

| Function | Does |
|---|---|
| `open()`, `close()`, `toggle()` | Fan on the focused output, focus requested (ux.md section 2) |
| `detail(id: string): string` | Opens the fan at that control's detail; returns `ok` or an error code |
| `settings()` | Summons the panel |
| `status(): string` | JSON: version, schema version, each control's id, kind, availability and reason, config errors. Used by the standalone app |

## 8. Theme adapter

`theme/Theme.qml` is the only file that names `Commons.Color` or `Commons.Style`, always qualified: Qt 6.12's own `Color` hides the unqualified name (OmaBar `test/run-all.sh` gate, omacom/omarchy#14553). It exposes omadials roles as bindings, never copies (platform.md section 4).

| omadials role | Source (ux.md section 6) |
|---|---|
| `surface`, `surfaceEdge`, `text` | `Color.popups.background`, `.border`, `.text` |
| `textSecondary` | `foreground` at 70% |
| `track` | `foreground` at 18% |
| `fill`, `knob` | `accent`, or `foreground` if accent on background is under 3:1 |
| `onFill` (glyph on a fill) | `background` |
| `knobOutline` | `background` |
| `toggleOff`, `toggleOffEdge` | `Style.normalFill`, `Style.normalBorderColor` |
| `hover`, `focusEdge`, `pressed` | `Style.hoverFill`, `Style.focusBorderColor`, `Style.pressedFill` |
| `warn` | `urgent` |
| `radius`, `font`, `duration(ms)`, `ease`, `reduceMotion` | `Style.*` |
| `isLight` | `Contrast.isLight(background)` |

`muted` is never mapped. A grep gate rejects `Commons.` outside `theme/` and colour literals in QML (ux.md acceptance 18). Plugin-local `pragma Singleton` is unproven (no house plugin uses one), so v0.1 builds one Theme in `Service.qml` and passes it as a `required property Theme theme`. If spike S1 proves a plugin-local singleton, only the wiring changes.

## 9. Settings app decision

The maintainer asked for "an isolated App to configure and adjust all the details".

| | (a) Shell panel | (b) Standalone C++/Qt Quick app | (c) Panel now, app later, same contract |
|---|---|---|---|
| Theme | Exact and live, reuses `qs.Ui` | Rebuilt from `colors.toml`, accent and a few roles (platform.md section 7) | Panel exact, app close |
| Isolation | Same process as the shell | Own process, a crash spares the shell | Both exist |
| Live preview | Real corner component | Drawn from `logic/Geometry.js`, plus "Show on screen" over IPC | Both |
| Install | `omarchy plugin add`, marketplace ready | PKGBUILD, AUR or `omarchy-pkgs` PR | Two releases |
| Effort | Low, omahop pattern | High | Highest, but staged |

**Recommendation: (c), with the app as a named milestone (v0.7), not "someday".** The panel ships first: cheap, exact theme, proven on the marketplace by omahop and OmaBar. The app follows the schema freeze, so it never chases a moving contract. Until then the panel loads only on demand and never touches the corner service.

How (b) is added with no plugin change:
- Its contract exists now: `config.json` v1, `controls/catalog.json` (names, kinds, placements, option schemas), IPC `status()` for availability, IPC `open`.
- It reuses `logic/ConfigSchema.js`, `ConfigMigrate.js`, `Layout.js` and `Geometry.js` unchanged, vendored by tag with a hash check.
- Both writers pass `test/fixtures/config/` and patch the latest text, so concurrent use loses at most the older of two simultaneous edits.
- It calls `omarchy-shell` with fixed `QProcess` argv only.

## 10. QML and JS practices we commit to

- Typed properties; `var` only for store JSON, deep-copied before it reaches `logic/` (OmaBar FINDINGS: `Array.isArray` fails across the host boundary).
- `required property` for all inputs. No parent-id reach, no context properties, no globals. No logic in delegates.
- `Loader` (`asynchronous: true`) for detail views and settings pages.
- Motion through `theme.duration(ms)`, ease out, under 300 ms. `Behavior` only on visual properties, off while dragging so the knob tracks 1:1 (ux.md section 7). Reduced motion snaps and dashes the pending outline.
- `Accessible.name` and `role` on every control ("Volume, 40 percent"). State never by colour alone. `textFormat: Text.PlainText` on every Text.
- Nothing synchronous on the UI path; every process is async with a timeout; DDC probes only on open (controls.md).
- Fixed argv arrays built from validated values; SSIDs and device names are argv elements. `Util.execDetached` (`bash -lc`) and `sh -c` are banned by grep.
- Errors surface: status line and control for backends, banner and gear for config, `test/qml-health.sh` for load errors. Empty catches only on side-channel refreshes, commented (coding-approach, Async worker point 3).
- `qmllint` and `qmlformat` when present, else `SKIP` (standards).

## 11. Safety

| Risk | Guard |
|---|---|
| Touchscreen off on a tablet | Refused when no keyboard or pointer is attached (checked live on each attempt). Otherwise a confirm, then a 15 s revert countdown that only a non-touch input can keep (controls.md, Touchpad and touchscreen). |
| Display changes (refresh, scale) | Same confirm and revert countdown. Writes UNVERIFIED (controls.md, Displays): spike S5 before v0.5. |
| Airplane mode | On: save the soft-block state of each radio to `~/.local/state/omadials/airplane-restore.json`, then `rfkill block all`. Off: unblock only what was on (controls.md, Airplane mode). Bluetooth restore goes through `omarchy-bluetooth-power`. |
| Root controls | GPU mode is a read-only chip; its detail explains the stock command and never runs it. Charge limit writes only through `asusctl`; without it, read-only. |
| Black screen | Brightness floor 1%. |
| Hidden writes | Every written file is listed in the README and the marketplace notes: `~/.config/omadials/config.json`, `config.v<N>.bak` (migration only), `~/.local/state/omadials/airplane-restore.json`. Nothing else. Never `shell.json`. No network (platform.md section 8). |
| Clicks taken | No trigger zone on fullscreen outputs or the lock screen; settings warn when the bar or dock shares the corner (ux.md section 2). |

## 12. Testing

| Level | What | How |
|---|---|---|
| Unit | Every `logic/` file: mirroring for 4 corners, capacity table, hit-test edges, over-cap volume, gesture thresholds, every closed set through every mapper, contrast on the 3 themes in ux.md | `node`, `test/load.mjs` |
| Contract, per backend | `spec.js` parse on real captured output (from controls.md: `brightnessctl -m`, `nmcli`, `powerprofilesctl`, `omarchy toggle ... --status`), plus empty, garbage and non-zero exit. A fake runner drives CommandMachine: probe, read, optimistic set, re-read, failure revert, poll only while `active` | `controls/<id>/<id>.test.mjs` |
| Shared contract | Catalog matches folders; every catalog option schema validates; config fixtures give the expected errors | `test/catalog-check.mjs`, fixtures |
| Static gates | Isolation greps (section 3), no colour literals, no `execDetached` or `sh -c`, line budgets, scrub (no dashes, no private data) | `test/isolation.sh`, `test/scrub.sh` |
| Plugin | `omarchy plugin validate .` | in `run-all.sh` when `omarchy` exists |
| Hand, on the Z13 | ux.md section 10 items, per milestone below | Checklist in `docs/batch-log.md`, with screenshots |

No live input automation by default. A live test runs only after asking whether the machine is in use, and restarting the shell is announced first (it can change the theme, OmaBar section 9).

## 13. Milestones

Every milestone is shippable from the public repo. "Z13" means a live hand test on the device.

| Version | Scope | Exit criteria |
|---|---|---|
| v0.1 Corner | Logic modules with tests, ConfigStore (read only, defaults), runner, registry, bottom-left M fan, 3 dials, 6 toggles, readout, IPC, keybind docs. Spikes S1 singleton, S2 FileView on a created file, S3 mask regions switching closed and open | `run-all.sh` green, validate passes. Z13: acceptance 2, 4, 8, 9, 10, 17, 18 |
| v0.2 Touch | Tap and drag-open, push dwell, long press, value bubble, status line, keyboard order, accessibility, reduced motion. S4: screen reader on a layer surface | Z13: acceptance 1, 3, 5, 6, 7, 11 to 15, 19 |
| v0.3 Settings | Panel, all 4 corners, 3 sizes, arc scrolling, outputs, problems banner, Undo, preview | Z13: 16, 20 to 23, portrait rotation |
| v0.4 Details | Wi-Fi rows and secured inline connect (S7), keyboard fallback, Bluetooth, audio devices, power profile, brightness per monitor | Contract tests per detail. Z13: each detail by hand |
| v0.5 Extras | Keyboard light, charge limit, pen battery, touchpad, touchscreen guard, airplane restore, recording, refresh and scale with revert (S5). Schema v1 frozen, `docs/file-contract.md` | Z13: every guard in section 11 tried by hand |
| v0.6 Listing | README with written-files list, preview, marketplace notes, validate commit | Marketplace issue filed |
| v0.7 App | Standalone `omadials-settings` (C++/Qt Quick, qmake), reuses logic JS, fixtures pass | App edits apply live to the plugin. Z13: theme switch in the app |
| v1.0 | Multi-monitor checked on a real second screen (no virtual monitors), S6 power profile D-Bus, bug fixes only after | Two weeks of daily use on the Z13 with no open blocker |

## 14. Open decisions for the maintainer

| # | Question | Recommendation |
|---|---|---|
| 1 | Settings app timing | Panel at v0.3, app at v0.7 after the schema freeze (section 9). |
| 2 | Replace the bar's audio, network and power widgets, or sit beside them (open since research.md) | Sit beside. Removing stock widgets is the user's choice and OmaBar already does it. |
| 3 | Volume above 100% | Default cap 100, setting up to 150, truthful display above the cap (section 2). |
| 4 | `bar-widget` kind | Leave out. With it, install prompts for a bar section and places an entry (OmaBar section 6), which breaks "installing changes nothing you can see". Tap, keybind and IPC cover it; revisit on request. |
| 6 | Thinner readout bands for more rings? | Keep 44 px bands, 48 px targets and S 2 / M 3 / L 4 cap. Thin strokes do not make more touch room. |
| 5 | Default toggle set at M | Wi-Fi, Bluetooth, night light, DND, keep awake, keyboard light (research.md step 1). Airplane, touchpad, touchscreen and recording are available but off by default. |


### Round 2 contract additions (sections 4 and 6)

Catalog exposes closed `tapActions` and `holdActions` per control. Wi-Fi: `switchRadio | quickDetail | fullWindow`; Bluetooth: `switchPower | quickDetail | fullWindow`; stepped keyboard light: `nextStep | quickDetail`; other boolean toggles: `switch | quickDetail`. Both action fields use the respective control set. Defaults are the first action for tap and quickDetail for hold. These are identifiers resolved in backend code, never commands in config.

Toggle array order is display order; enabled controls alone form the scrollable strip. Every toggle stores tapAction and holdAction. Ring array order is outer to inner. During the draft period, dials and readoutRings merge by explicit `order` (add order to each dial when mixing); duplicate positions report duplicate_control, never reorder silently. A ring may override `style: {track, knob, thickness}`; omitted fields inherit ringStyle. Track is `solid | dashed | dotted | segmented`, knob `round | bar | none`, thickness `thin | normal | bold` mapping to 2/4/6 px. Readouts force no knob by contract: a non-none explicit override is a reported wrong_placement error. Render dash patterns as shader uniforms.

readoutRings source is `bluetoothBattery | wifiSignal | laptopBattery | penBattery`. Bluetooth requires deviceAddress; pen requires devicePath from UPower; Wi-Fi interface is auto or a detected interface; laptop uses UPower display device. Selected source identity persists across disconnects. Extend ControlBase with `connected` bool and `parameter` validated catalog data. Disconnected selected readout remains visible, dimmed with value null and valueText "not connected"; unknown value stays null with "unknown". This is a specific exception to missing-hardware slot removal. Tap opens related detail; set/drag/wheel are unsupported. Geometry reserves label rectangles and wrapping row heights per ux.md. Combined dial/readout cap is S 2, M 3, L 4.

Validation reports unknown values and incompatible fields in the problems banner, keeps the original file and never silently fixes it. Settings expose all fields above. Schema remains draft until v0.5.

### S7, secured Wi-Fi stdin spike (v0.4 exit gate)

UNVERIFIED. Prototype is simulation only. Verify Quickshell Process stdin lifecycle with `nmcli --ask` for a new secured network, successful connect, wrong password, cancellation, timeout and device removal. Password must never enter argv, environment, config, logs or error text. Use fixed argv with network identity as a separate argument, feed only the credential to stdin after the expected prompt, close stdin and clear the input on completion/cancel. Audit process argv and diagnostic paths without recording the secret. If stdin prompting cannot be made reliable, spike a NetworkManager secret-agent API instead. Do not ship real inline credentials until verified. No physical keyboard: explain that the Z13 has no on-screen keyboard and offer the full stock network window.

Section 14 open question: should readouts use thinner bands to fit more? Recommendation: keep the same 44 px band, 48 px target and ring cap for now. A thinner stroke is already supported; it does not create more safe touch capacity.


## Round 3 config and recovery

Draft config adds `dialInteraction: {snap: true, snapWindowPercent: 2, fineEnabled: true, fineDistancesPx: [22,66], fineGains: [0.25,0.1]}`, `toggleScroll: "resetOnOpen"`, `themePair: {light: "Paper Light", dark: "Midnight"}`, and `gameMode: {animations: false, blur: false, shadows: false, gapsIn: 0, gapsOut: 0}`. Theme names in the prototype are fake; real choices come from installed themes. Distances are increasing nonnegative numbers, gains are greater than zero and at most one, snap window is 0 to 2. Game fields are optional typed allowlisted options, never commands. Theme ids must match installed entries. Settings expose snap, fine enable, the theme pair, game option selection and values. Media is an optional toggle and a volume detail action. Per-app sliders are transient Pipewire node state, never persisted.

Only settings changes order. Reset scroll on open. FanModel owns the continuous unsnapped draft, last angle and fine gain. Geometry supplies the inside-fan reserved boxes. Gain changes rebase before integrating. Snap is presentation plus the submitted value, not a mutation of the continuous draft.

S8 game runtime writes, UNVERIFIED: confirm the installed Hyprland runtime read/write API and exact typed read-back for animations, blur, shadows and both gap values. Do not assume keyword syntax on a Lua-config build. Before any write, atomically persist a versioned restore journal under `~/.local/state/omadials/game-restore.json`, with compositor instance id, baseline and intended values. Apply serially and read back. On partial failure restore all changed values. Off restores the baseline exactly, verifies, then deletes the journal. A shell-independent user-session recovery helper watches shell exit and logout, restores before compositor exit when possible, and shares a lock with the writer. On restart, recover the journal before allowing new writes. Same compositor: restore before accepting input; new compositor: discard old runtime journal because runtime overrides died with it. Unknown instance or failed restore leaves a visible recovery error, journal intact and game mode disabled. Never edit Hyprland config. Spike must test forced shell death, logout, partial writes and concurrent external option changes. Baseline restoration intentionally replaces external changes to options owned during game mode.

S9 theme command, UNVERIFIED: verify installed `omarchy-theme-set <installed-name>` via fixed argv, read-back, errors and event propagation. No source or machine checks were run. Tap selects the opposite configured theme (if neither is active, choose dark); hold lists installed themes. Never write theme files directly.

Written-files inventory additionally includes the game restore journal. Recovery is the narrow exception to closed-state inactivity: it runs only while a restore journal exists.
