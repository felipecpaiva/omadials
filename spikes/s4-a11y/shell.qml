// Spike S4: does a layer surface expose accessible names and values over AT-SPI?
// Run: QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1 timeout 20 qs -p spikes/s4-a11y
import QtQuick
import Quickshell
import Quickshell.Wayland
ShellRoot {
  PanelWindow {
    WlrLayershell.namespace: "omadials-s4"
    WlrLayershell.layer: WlrLayer.Top
    anchors { bottom: true; left: true }
    implicitWidth: 120; implicitHeight: 60
    color: "#2020262c"
    Item {
      anchors.fill: parent
      Accessible.role: Accessible.Slider
      Accessible.name: "Volume"
      Accessible.description: "40 percent"
      property real value: 40
    }
  }
}
