import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import "theme"
import "core"
import "vm"
import "views"

// Root: builds the theme, the config store, the control registry and the model, puts one corner and one tab window
// on every output, and answers `omarchy-shell omadials ...`. The settings panel reads registry, configStore and theme.
Item {
  id: root
  property string omarchyPath: ""
  property var shell: null

  readonly property alias theme: omadialsTheme
  readonly property alias configStore: store
  readonly property alias registry: controlRegistry
  readonly property var config: store.config

  Theme { id: omadialsTheme }
  ConfigStore { id: store; catalog: controlRegistry.catalog }
  Registry { id: controlRegistry; store: store; active: fanModel.open }
  // The settings folder must exist before the store starts watching, or a later first file is never seen.
  Component.onCompleted: controlRegistry.runner.run("config-dir", ["mkdir", "-p", Quickshell.env("HOME") + "/.config/omadials"], 3000,
    () => store.reload())
  FanModel {
    id: fanModel
    registry: controlRegistry
    config: root.config
    battery: controlRegistry.revision >= 0 ? controlRegistry.byId("laptopBattery") : null
    profile: controlRegistry.revision >= 0 ? controlRegistry.byId("powerprofile") : null
    onSettingsRequested: root.openSettings()
  }

  function openSettings() { if (root.shell) root.shell.summon("io.github.felipecpaiva.omadials", "{}") }
  function showFan() { fanModel.show(false) }
  function focusedScreen() {
    const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    return Quickshell.screens.find(s => s.name === name) || null
  }

  Variants {
    model: Quickshell.screens
    Item {
      id: perOutput
      required property var modelData
      // Quiet over a fullscreen app on this output. The lock screen needs nothing: session lock covers every layer.
      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property bool fullscreen: !!(hyprMonitor && hyprMonitor.activeWorkspace && hyprMonitor.activeWorkspace.hasFullscreen)
      CornerWindow {
        id: corner
        screen: perOutput.modelData
        theme: omadialsTheme
        model: fanModel
        corner: root.config.corner
        size: root.config.size
        iconMode: root.config.cornerIcon ? root.config.cornerIcon.mode : "always"
        suppressed: perOutput.fullscreen
      }
      TabWindow {
        screen: perOutput.modelData
        theme: omadialsTheme
        model: fanModel
        corner: root.config.corner
        iconMode: root.config.cornerIcon ? root.config.cornerIcon.mode : "always"
        iconAboveWindows: root.config.cornerIcon ? root.config.cornerIcon.aboveWindows : true
        source: root.config.cornerIcon ? root.config.cornerIcon.source : "default"
        tabStyle: root.config.tabStyle || "rings2knob"
        approaching: corner.approaching
        fanPresenting: corner.fanPresenting
        suppressed: perOutput.fullscreen
      }
    }
  }

  ShellIpc {
    target: "omadials"
    function open(): string { fanModel.output = root.focusedScreen(); fanModel.show(true); return "ok" }
    function close(): string { fanModel.close(); return "ok" }
    function toggle(): string { if (fanModel.open) fanModel.close(); else { fanModel.output = root.focusedScreen(); fanModel.show(true) } return "ok" }
    function settings(): string { root.openSettings(); return "ok" }
    // Open the corner straight at one control's detail: `omarchy-shell omadials detail volume`.
    function detail(id: string): string {
      const c = controlRegistry.byId(id)
      if (!c) return "unknown control: " + id
      fanModel.output = root.focusedScreen(); fanModel.show(true); fanModel.openDetail(c)
      return "ok"
    }
    // Run one control action, as a tap would: `omarchy-shell omadials activate gameMode switch`. For keybinds and scripts.
    function activate(id: string, action: string): string {
      const c = controlRegistry.byId(id)
      if (!c) return "unknown control: " + id
      if (c.availability !== "available") return "unavailable: " + c.reason
      c.activate(action || "tap")
      return "ok"
    }
    function status(): string {
      const s = JSON.parse(controlRegistry.status())
      s.open = fanModel.open
      s.configErrors = store.errors
      return JSON.stringify(s)
    }
  }
}
