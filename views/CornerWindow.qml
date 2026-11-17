import QtQuick
import Quickshell
import Quickshell.Wayland
import "../logic/Geometry.js" as Geometry

// One output's corner: a small tap zone while closed, a full-output click catcher while open (spike S3).
PanelWindow {
  id: win
  required property var theme
  required property var model          // FanModel: rings, battery, open state
  property string corner: "bottom-left"
  property string size: "M"

  readonly property real outW: width
  readonly property real outH: height
  readonly property var cap: Geometry.capacity(size, Math.min(outW, outH))
  readonly property real fanRadius: cap.R
  readonly property var origin: Geometry.fromCanonical({ x: 0, y: outH }, outW, outH, corner)
  readonly property var radii: Geometry.ringRadii(fanRadius, model.rings.length)

  WlrLayershell.namespace: "omadials"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: model.open && model.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  mask: Region { item: win.model.open ? catcher : zone }

  Item { id: catcher; anchors.fill: parent }
  Item { id: zone; width: 32; height: 32; x: win.corner.indexOf("right") >= 0 ? win.outW - 32 : 0; y: win.corner.indexOf("top") >= 0 ? 0 : win.outH - 32 }

  Fan {
    id: fan
    anchors.fill: parent
    theme: win.theme; model: win.model; corner: win.corner
    fanRadius: win.fanRadius; radii: win.radii; origin: win.origin; screenWidth: win.outW; screenHeight: win.outH
  }

  FanInput {
    anchors.fill: parent
    model: win.model; corner: win.corner; fanRadius: win.fanRadius; radii: win.radii; screenWidth: win.outW; screenHeight: win.outH
  }
}
