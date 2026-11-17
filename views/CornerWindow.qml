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

  readonly property real W: width
  readonly property real H: height
  readonly property var cap: Geometry.capacity(size, Math.min(W, H))
  readonly property real R: cap.R
  readonly property var origin: Geometry.fromCanonical({ x: 0, y: H }, W, H, corner)
  readonly property var radii: Geometry.ringRadii(R, model.rings.length)

  WlrLayershell.namespace: "omadials"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: model.open && model.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  mask: Region { item: win.model.open ? catcher : zone }

  Item { id: catcher; anchors.fill: parent }
  Item { id: zone; width: 32; height: 32; x: win.corner.indexOf("right") >= 0 ? win.W - 32 : 0; y: win.corner.indexOf("top") >= 0 ? 0 : win.H - 32 }

  Fan {
    id: fan
    anchors.fill: parent
    theme: win.theme; model: win.model; corner: win.corner
    R: win.R; radii: win.radii; origin: win.origin; screenWidth: win.W; screenHeight: win.H
  }

  FanInput {
    anchors.fill: parent
    model: win.model; corner: win.corner; R: win.R; radii: win.radii; screenWidth: win.W; screenHeight: win.H
  }
}
