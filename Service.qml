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

  Theme { id: omadialsTheme }
  Volume.Control { id: volumeControl }
  FanModel { id: fanModel; rings: [volumeControl] }

  Variants {
    model: Quickshell.screens
    CornerWindow {
      required property var modelData
      screen: modelData
      theme: omadialsTheme
      model: fanModel
    }
  }

  ShellIpc {
    target: "omadials"
    function open(): string { fanModel.show(true); return "ok" }
    function close(): string { fanModel.close(); return "ok" }
    function toggle(): string { if (fanModel.open) fanModel.close(); else fanModel.show(true); return "ok" }
    function status(): string { return JSON.stringify({ version: "0.1.0", open: fanModel.open, volume: volumeControl.percent }) }
  }
}
