// Spike S3: corner tap zone mask, full-screen catcher when open, icon tab on the Bottom layer.
// Run: timeout 600 qs -p spikes/s3-mask ; drive with: qs -p spikes/s3-mask ipc call s3 open|close|state
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root
  property bool open: false
  property int taps: 0
  property int outside: 0
  // Safety: an open spike never stays open; its full-screen catcher would eat every click.
  Timer { interval: 8000; running: root.open; onTriggered: { root.open = false; console.log("S3 safety close") } }
  // Safety: an open spike never stays open; its full-screen catcher would eat every click.
  Timer { id: safetyClose; interval: 8000; running: root.open; onTriggered: { root.open = false; console.log("S3 safety close") } }

  // Tab drawn behind windows; takes no input at all.
  PanelWindow {
    id: tab
    WlrLayershell.namespace: "omadials-s3-tab"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { bottom: true; left: true }
    implicitWidth: 42; implicitHeight: 42
    color: "transparent"
    mask: Region {}
    Rectangle { width: 84; height: 84; radius: 42; x: -42; y: 0; color: "#c0ff8c78" }
  }

  // Tap zone above windows when closed; whole-screen catcher when open.
  PanelWindow {
    id: zone
    WlrLayershell.namespace: "omadials-s3-zone"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region { item: root.open ? catcher : hit }

    Item { id: catcher; anchors.fill: parent }
    Rectangle {
      visible: root.open; width: 840; height: 840; radius: 420; x: -420; y: parent.height - 420
      color: "#d020262c"
    }
    Item { id: hit; width: 32; height: 32; y: parent.height - 32 }

    MouseArea {
      anchors.fill: parent
      onClicked: (m) => {
        const inZone = Math.hypot(m.x, parent.height - m.y) <= 32
        if (inZone) { root.taps++; root.open = !root.open; console.log("S3 tap zone, open=" + root.open) }
        else if (root.open) { root.outside++; root.open = false; console.log("S3 outside tap closed") }
      }
    }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: { root.open = false; console.log("S3 escape closed") } }
  }

  IpcHandler {
    target: "s3"
    function open(): void { root.open = true }
    function close(): void { root.open = false }
    function state(): string { return JSON.stringify({ open: root.open, taps: root.taps, outside: root.outside }) }
  }
}
