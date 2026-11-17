import QtQuick
import Quickshell
import qs.Commons
import "theme"
import "vm"
import "views"
import "controls/volume" as Volume

// Root: builds the theme, the model and one corner window per output, and answers `omarchy-shell omadials ...`.
Item {
  id: root
  property string omarchyPath: ""
  property var shell: null

  Theme { id: theme }
  Volume.Control { id: volume }
  FanModel { id: fan; rings: [volume] }

  Variants {
    model: Quickshell.screens
    CornerWindow {
      required property var modelData
      screen: modelData
      theme: theme
      model: fan
    }
  }

  ShellIpc {
    target: "omadials"
    function open(): string { fan.show(true); return "ok" }
    function close(): string { fan.close(); return "ok" }
    function toggle(): string { if (fan.open) fan.close(); else fan.show(true); return "ok" }
    function status(): string { return JSON.stringify({ version: "0.1.0", open: fan.open, volume: volume.percent }) }
  }
}
