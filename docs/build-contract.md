# Build contract (P3 to P7)

How parallel work on the plugin stays compatible. Read with `architecture.md` (sections 4 to 8), `ux.md`,
`experience.md`, `acceptance.md`, `spikes.md` and `engineering-standards.md`.

## Ownership (one owner per file)

| Track | Owns | Never edits |
|---|---|---|
| Controls | `core/ControlBase.qml`, `core/CommandRunner.qml`, `core/CommandControl.qml`, `core/Registry.qml`, `controls/catalog.json`, `controls/<id>/*`, their `*.test.mjs` | `views/`, `vm/`, `settings/`, `Service.qml` |
| Views | `views/*`, `vm/FanModel.qml` | `core/`, `controls/`, `settings/`, `Service.qml` |
| Settings | `core/ConfigStore.qml`, `settings/*` | `views/`, `vm/`, `controls/`, `Service.qml` |
| Integration (maintainer session) | `Service.qml`, `manifest.json`, `theme/Theme.qml`, `logic/*`, `test/run-all.sh`, live tests | |

## Interfaces

- **Controls** implement `ControlBase` (architecture section 4). Views read only those members. `value` is native
  (percent for dials), with `range`; views map it with `logic/ValueMap.js`.
- **Registry** exposes `controls` (all), `rings` (shown dial and readout controls in ring order, capped by size),
  `toggles` (shown arc controls in order), `byId(id)`, and `status()` JSON. It reads `ConfigStore.config`.
- **ConfigStore** exposes `config` (validated, defaults filled by `logic/ConfigSchema.js`), `errors` (list),
  `set(path, value)` (atomic write, report never silently fix), `undo()`, and reloads live on file change.
- **FanModel** exposes `open`, `wantsKeyboard`, `show(keyboard)`, `close()`, `toggle()`, `activity()`, `status`
  (text), `detail` (id or ""), `openDetail(id)`, `closeDetail()`, plus layout from `logic/Layout.js`.
- **Theme** (`theme/Theme.qml`): roles `surface, edge, text, secondary, track, accent, ink, off, warn`, `font`,
  `reduceMotion`, `easeOut`, `duration(ms)`. Views get it as a required property `theme`.

## QML rules learned on the device

- Property names must not start with a capital letter (`R`, `W`, `H` fail to load).
- Do not redeclare FINAL Item properties (`top`, `right`, `x`, `y`, `width`, `radius` on Item, `state`, ...).
- Give root ids that cannot shadow a property name (`theme: theme` binds to itself). Use `omadialsTheme`-style ids.
- Files under `controls/<id>/` load on demand, so a sibling `.qml` there is not a type. Create it with
  `Qt.createComponent(Qt.resolvedUrl("Name.qml")).createObject(parent, props)`.
- The shell caches components: a file change needs `omarchy-restart-shell` to show.
- A click on an `OnDemand` layer does not take keyboard focus (spike S3). Only keybind and IPC opens request focus.
- Screen readers see nothing on Quickshell layer surfaces (spike S4). Still set `Accessible.name` and `role`.
- Game mode writes Hyprland at runtime with `hyprctl eval 'hl.config({...})'`, never the stock reload flags (spike S8).
- Use `Shape` with `preferredRendererType: Shape.CurveRenderer` for arcs (spike P1.9). Arc angles from
  `Geometry.qtArc(a0, a1, corner)`.

## Code rules

- QML at most 150 lines per file (hard cap 200), JS at most 250. No magic numbers in QML for gesture thresholds or
  timings: use `logic/Gesture.js`, `logic/Motion.js` and the Theme duration.
- Only `core/CommandRunner.qml` creates `Process`. Only `theme/Theme.qml` imports `qs.Commons` (Service.qml may
  import it for `ShellIpc`). No colour literals in QML. Argv arrays only, never `sh -c`.
- Every file passes `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml <file>` with no errors.
- Plain English comments, no em dash or en dash. No private info. Do not commit; the integration session commits.
