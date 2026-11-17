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
  FanModel {
    id: fanModel
    registry: controlRegistry
    config: root.config
    battery: controlRegistry.revision >= 0 ? controlRegistry.byId("laptopBattery") : null
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
      CornerWindow {
        id: corner
        screen: perOutput.modelData
        theme: omadialsTheme
        model: fanModel
        corner: root.config.corner
        size: root.config.size
        iconMode: root.config.cornerIcon ? root.config.cornerIcon.mode : "always"
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
      }
    }
  }

  ShellIpc {
    target: "omadials"
    function open(): string { fanModel.output = root.focusedScreen(); fanModel.show(true); return "ok" }
    function close(): string { fanModel.close(); return "ok" }
    function toggle(): string { if (fanModel.open) fanModel.close(); else { fanModel.output = root.focusedScreen(); fanModel.show(true) } return "ok" }
    function settings(): string { root.openSettings(); return "ok" }
    function status(): string {
      const s = JSON.parse(controlRegistry.status())
      s.open = fanModel.open
      s.configErrors = store.errors
      return JSON.stringify(s)
    }
  }
}
