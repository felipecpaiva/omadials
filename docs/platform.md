# omadials platform contract (Omarchy 4.5 shell)

How verified: read the stock shell in `/usr/share/omarchy/shell` and the validator `/usr/share/omarchy/bin/omarchy-plugin-validate` on 2026-11-17. Nothing was run against the live session. Paths below are relative to the shell folder unless they start with `/` or `~`. `validate:N` means line N of the validator.

## 1. Manifest schema

Required: `schemaVersion` (the JSON number 1, not "1"), `id`, `name`, `version`, `kinds` (non-empty array), `entryPoints` (object) (validate:44-54, `services/PluginRegistry.qml:48`). Optional fields we use: `author`, `description`, `license`, `keepLoaded`, `barWidget`.

- `id`: `^[A-Za-z0-9][A-Za-z0-9._-]*$`, no `..`, and never `omarchy.*` (validate:57-60). Ours: `io.github.felipecpaiva.omadials`.
- Kinds the validator knows, each needing its own entry point key (validate:117-130): `bar`->`bar`, `bar-widget`->`barWidget`, `menu`->`menu`, `overlay`->`overlay`, `panel`->`panel`, `service`->`service`. A kind without its key fails validation.
- Entry points must be relative, free of `..`, and exist (validate:96-107). Symlinks anywhere in the folder are refused (validate:135).
- `keepLoaded: true` mounts a panel at startup and keeps it alive (`shell.qml:1056`, `:1402`). Stock use: `plugins/osd/manifest.json`. A `service` is always mounted at startup (`plugins/README.md:6-9`).
- `barWidget` object: `defaultSection` must be one of left, centerBegin, center, centerEnd, tray, right (validate:75-86). Placement is only for bar widgets: `PluginRegistry.setEnabled(id, value, placement)` (`services/PluginRegistry.qml:497-578`). Services and panels have no placement; they place themselves.
- There is no per-plugin `settings` schema in the manifest. The only form hook is `settingsForm` inside `barWidget` metadata (`shell.qml:1472`, used by `plugins/panels/weather/manifest.json:19`). Settings are our own (section 5).
- "Enabled" means the id appears in `shell.json` (`services/PluginRegistry.qml:136-148`).

Copy `plugins/dock/manifest.json`; ours is `["service","panel"]` like omahop's manifest.

## 2. Lifecycle and IPC

- The shell loads a plugin entry as a QML root `Item` and injects properties if the root declares them: `shell`, `manifest`, `omarchyPath`, `service`, `pluginRegistry`, `barWidgetRegistry` (`shell.qml:1400-1412`). Declare `property var shell: null` and `property var manifest: null` (see `plugins/dock/Dock.qml:14-15`).
- Panels (not keepLoaded) load only while summoned: `active: keepLoaded || openPanelIds[id]` (`shell.qml:1402`). A panel root implements `open(payloadJson)` and `close()` (`plugins/osd/Osd.qml:74-81`; omahop `SettingsPanel.qml:45,64`).
- Reload on file change: the registry watches local plugin folders; a change fires `onLocalPluginChanged`, then `reloadPlugins()` clears the component cache and rescans (`shell.qml:1517-1560`). keepLoaded plugins survive the reload (`shell.qml:1059`). Manual: `omarchy-shell shell rescanPlugins` (`shell.qml:1793`). Do not run it on the live session during research.
- Config reload: `shell.json` and the defaults file are `FileView`s with `watchChanges: true`, `onFileChanged: reload()` (`shell.qml:134-156`). `shell reloadConfig` forces it (`:1800`).
- IPC: declare `ShellIpc { target: "omadials"; function toggle(): string {...} }` (`Commons/ShellIpc.qml:7-12`, stock: `plugins/dock/Dock.qml:347-352`, `plugins/osd/Osd.qml:116-124`). It registers in `Commons/IpcRegistry.qml:34`, and only declared functions are callable (`:56`). Call it with `omarchy-shell omadials toggle`. Functions need typed args and return a `string` or `void`.
- Open or close any panel plugin: `omarchy-shell shell summon|toggle|hide <id>` (`shell.qml:1181`, `services/PluginShellApi.qml:46-58`). omahop's desktop entry uses `omarchy-shell shell toggle <id>` (omahop repo `omahop.desktop:6`).
- Plugins reach services through `shell.serviceFor(id)`, `shell.summon`, `shell.updateEntryInline`, `shell.mutateShellConfig` (`services/PluginShellApi.qml:30-66`).

## 3. Windows

Pattern to copy: `plugins/dock/DockWindow.qml`.

- Layer and focus: `WlrLayershell.layer: WlrLayer.Top`, `keyboardFocus: WlrKeyboardFocus.None` (`:195-196`). A settings window uses `WlrLayer.Overlay` and `Exclusive` (omahop `SettingsPanel.qml:96-97`). `Ui/OverlayWindow.qml:15-17` wraps `shown`, `shownLayer`, `shownKeyboardFocus`.
- Namespace: `WlrLayershell.namespace: "omarchy-dock"` (`:194`). Use `omadials` so Hyprland layer rules can target it.
- Anchors: two true edges give a corner. Dock sets four booleans in `anchors {}` (`:202-207`). Ours: `bottom`+`left` etc., chosen from the setting.
- Exclusion: `exclusionMode: ExclusionMode.Normal`, `exclusiveZone: 0` so windows are not pushed (`:199-200`).
- Input mask: `mask: Region { item: ... }` with child `Region`s (`:212-217`). The window can be large and transparent while only the trigger strip or the open quarter circle takes input. OSD uses an empty `Region {}` to be click-through (`plugins/osd/Osd.qml:133`).
- Hot corner: a small `Item` in the mask plus a `HoverHandler` (dock `edgeTrigger`, `:215`, `:230`).
- Multi-monitor: `Variants { model: Quickshell.screens; delegate: Component { DockWindow { required property var modelData; screen: modelData } } }` (`plugins/dock/Dock.qml:384-395`). Decision for omadials: open only on one screen (the focused or a chosen one), so a `Variants` with a `visible` guard.
- Motion: wrap every duration in `Style.duration(ms)`; it returns 0 when animations are off (`Commons/Style.qml:365`). Use `Style.easeOut` (`:372`).

## 4. Theming

Import `qs.Commons` and `qs.Ui`. Singletons: `Color` (`Commons/Color.qml`), `Style` (`Commons/Style.qml`), `Util`.

Color roles:
- Foundation (`Color.qml:19-23`): `foreground`, `background`, `accent`, `urgent`, `muted`.
- Surface groups (`:79-137`): `bar` (background, text, active), `popups` (background, text, border), `tooltip`, `notifications`, `menu` (background, text, border, scrim, selectedBackground, selectedText, selectedBorder), `polkit`, `lock`, `imagePicker`. Missing roles fall back to the foundation (`:10-11`).
- Our choice: draw the dial surface from `Color.popups.*`, active arcs from `Color.accent`, warnings from `Color.urgent`. Not `Color.muted` for text or off states: it measures 1.91:1 on Tokyo Night and 2.0:1 on Flexoki Light (`docs/ux.md`, theming section, corrected 2026-11-17). Never hard-code colors (OmaBar quality bar section 5).
- Helpers: `Color.pick`, `Color.composed`, `Util.alpha(color, a)` (`Util.qml:44`).

Style tokens:
- Fonts: `Style.font.family` (alias, follows `omarchy font set`), `resolvedFamily`, `baseSize`, and size tokens such as `caption`, `bodySmall` (`Style.qml:323-340`).
- Spacing: `Style.spacing.xxs...huge`, `controlGap`, `controlHeight`, `panelGap`, `panelPadding` (`:233-262`). `Style.space(px)` scales a pixel value (`:221`).
- Shape: `Style.cornerRadius` (mirrors Hyprland rounding), `Style.gapsOut` (`:33-34`). Interaction state tokens: `normalFillAlpha`, `selectedFillAlpha`, borders (`:72-94`).

Live update: a theme switch calls IPC `applyTheme(colorsB64, shellB64)`, which runs `Color.loadColors` and `Color.loadShell` (`shell.qml:1772-1785`). `Color.shellValues` is reassigned whole, so every `Color.*` and `Style.*` binding re-evaluates without a reload (`Color.qml:25-28`). `~/.config/omarchy/shell.toml` is watched for user overrides (`:246-251`). Bind to the properties, never copy them into a plain `var` at startup.

Light vs dark: there is no `isLight` or mode property. Verified by grep of `Commons/` and `Ui/`. The theme folder has no light marker file either. Derive it from `Color.background` luminance (`Qt.color`: `0.2126*r + 0.7152*g + 0.0722*b > 0.5`). Prefer roles that already adapt over branching on this.

## 5. Settings storage

| Option | How | Fit |
|---|---|---|
| A. Entry in `shell.json` `plugins[]` | `shell.updateEntryInline(id, settings)` merges the object into the plugin's entry and persists (`shell.qml:1107-1140`, `services/PluginShellApi.qml:62`). Read from `shell.shellConfig`. The file is watched and written with `atomicWrites: true` (`shell.qml:151-155`) | One file the user already backs up. But the shell owns the file: our standalone app would have to edit shell internals, and `omarchy bar defaults` style resets can touch it |
| B. Own file in `~/.config/<name>/` | omahop: `FileView { watchChanges: true; onFileChanged: reload() }` (`ConfigReader.qml:30-37`), writes with `atomicWrites: true` (`SettingsStore.qml:90`), `mkdir -p` first (`:75`). Note: omahop's file is TOML (`config.toml`), not JSON | Fully ours, readable from QML and C++, survives plugin reinstall. Recommended |
| C. Own file in `~/.config/omarchy/` | OmaBar uses `~/.config/omarchy/oma-bar-configurator.json` (OmaBarConfigurator repo `docs/SUBMISSION.md`) | Same as B, but next to Omarchy config; fine, but B keeps uninstall simple |

Decision for omadials: option B, `~/.config/omadials/config.json`, versioned with a `version` key, unknown keys kept, bad values fall back to defaults and log once (OmaBar standards). Write to a temp file in the same folder then rename (`atomicWrites: true` does this in QML; do the same in C++ with `QSaveFile`). Live reload comes free from `watchChanges`. The writer must never touch `shell.json`.

## 6. Shared helpers and services

- `Util.execDetached(cmd)` runs `bash -lc` (`Util.qml:68`). `Util.execArgv(argv)` passes args without shell parsing, preferred for anything built from input (`:77`). `Util.shellQuote` (`:64`), `Util.clamp`, `Util.wheelSteps` (`:21`, `:31`).
- Run-and-read: `Quickshell.Io.Process` with a `StdioCollector`, as in `plugins/menu/Menu.qml:331` (`powerprofilesctl`, `omarchy-powerprofiles-set`).
- Quickshell services used by stock: `Quickshell.Services.Pipewire` (`plugins/panels/audio/Panel.qml:6,17-19`: `defaultAudioSink`, `defaultAudioSource`, `nodes`), `UPower` (`plugins/panels/power/Panel.qml:4,29`: `displayDevice`), `Mpris` (media). Keep a `PwObjectTracker` on any node you read, and do not read `node.properties` before it is bound: stock warns this can destabilize Pipewire (`Panel.qml:76-85`).
- Quickshell 0.3.2 ships `Quickshell.Networking` and `Quickshell.Bluetooth` (`/usr/lib/qt6/qml/Quickshell/`), and the stock panels use them (`shell/plugins/panels/network/Panel.qml`, `panels/bluetooth/Panel.qml`). Use them for live state; writes still go through Omarchy helpers (`omarchy-bluetooth-power`, `nmcli`). Corrected 2026-11-17 after `docs/controls.md` found the modules. Command details: `docs/controls.md`.
- Omarchy-owned shell services: `services/BrightnessModel.js`, `services/BrightnessKeys.qml`, plugin `omarchy.nightlight`, `omarchy.battery`, `omarchy.idle` (`plugins/README.md:34-36`). A plugin can reach a first-party service with `shell.firstPartyServiceFor(id)` (`services/PluginShellApi.qml:36`). Prefer CLI calls: they stay stable across shell refactors.

## 7. Options for the configuration app

| | (a) `panel` in the shell | (b) standalone C++/Qt Quick app | (c) both, one JSON contract |
|---|---|---|---|
| Theming | Perfect and instant: same `Color`/`Style`, reuses `qs.Ui` (`Toggle`, `PanelSlider`, `Dropdown`, `NumberField`) | We rebuild it: watch `~/.local/state/omarchy/current/theme/colors.toml` and re-arm the watcher on each switch (omarchy-app skill, "Follow the theme live"). Only accent and a few roles, no `shell.toml` surface roles unless we parse them | Panel for daily use, app theming only matters if the app ships |
| Isolation | Same process as the bar | Own process | Mixed |
| Crash blast radius | A bad QML error in the panel can break plugin load; a hard crash takes the whole shell. omahop and OmaBar accept this | A crash closes only the app; the shell is untouched | Panel risk stays, unless the panel is optional |
| Packaging and marketplace | Single repo, `manifest.json` at root, installs with `omarchy plugin add`. Matches every accepted listing | Needs an Arch package (PKGBUILD) and, for a default install, a PR to `omacom/omarchy-pkgs`. The marketplace lists plugins, not packages; the plugin would need a hard dependency note | Two deliverables, two release processes |
| Effort | Low. We already have the omahop pattern | High: C++ backend, qmake, tests, packaging, translations, and a portal for file dialogs | Highest. Contract tests on both sides |
| Fit with live preview | Immediate: the dials re-read the config file as it changes | Same, through the file | Same |

Recommendation: start with (a). Reasons: the quarter-circle dials and the settings share one theme path, one repo and one install command; omahop and OmaBar already ship this way and passed the marketplace; the cost is a fraction of (b). Keep the JSON contract from section 5 plain and documented (`docs/file-contract.md` in the omahop style) so (b) can be added later as option (c) with no plugin change. Mitigate the blast radius by keeping the panel small, loading it only on demand (not keepLoaded), parsing config defensively, and keeping the corner window in the service.

## 8. Marketplace constraints

Sources: OmaBarConfigurator repo `docs/SUBMISSION.md`, omahop repo `docs/launch/marketplace-listing.md`, OmaBarConfigurator repo `docs/quality-bar.md`.

- Submit through the form at `omacom/omarchy-plugin-marketplace` (issue template `submit-plugin.yml`). Fields: repository URL, category (Appearance, Desktop, Developer Tools, Hardware, Kids, Productivity, System, Widgets, Other), 1 to 3 tags (more than three is rejected), maintainer notes. Likely category for us: Hardware or Desktop.
- Public repo, one plugin, `manifest.json` in the root, root README with install and removal sections, root license file (MIT), external dependencies documented (omahop listing table).
- Unique id outside `omarchy.*`, permanent once listed. Search the marketplace first.
- Must pass `omarchy plugin validate .` and cite the commit in the notes.
- Must not overwrite user config without consent. Name every path written in the README and notes; a desktop entry carries an ownership marker and an existing foreign file is backed up, never replaced (OmaBar, omahop).
- Optional root `preview.png` (omahop: 1280x640), with no personal data.
- The marketplace checks listings, not security: "Plugins run unsandboxed." So no network, no elevated rights, and no hidden writes. State this in the notes.
- Notes style: 4 to 10 lines, lead with what it is, name what it writes, end with validation evidence. List overlaps with core and known limits (omahop does).
- Our own bar: pass the OmaBar quality bar items that apply: fail safe (a bad config or missing tool never breaks the shell), zero idle cost (no timers while the corner is closed; poll only while open), no hard-coded colors, `textFormat: Text.PlainText` on displayed text, QML files under 200 lines, no em or en dashes, scrub check before every push.
