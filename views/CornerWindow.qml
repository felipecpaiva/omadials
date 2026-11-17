pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../logic/Geometry.js" as Geometry
import "../logic/Gesture.js" as Gesture

// Quickshell creates PanelWindow through its engine despite its uncreatable qmltypes metadata.
// qmllint disable uncreatable-type
// One output's corner: a small tap zone while closed, a full-output click catcher while open (spike S3).
PanelWindow {
  // qmllint enable uncreatable-type
  id: win
  required property var theme
  required property var model          // FanModel: rings, battery, open state
  property string corner: "bottom-left"
  property real detailRadius: 12
  property string size: "M"
  readonly property bool selected: !model.output || model.output === screen
  property bool suppressed: false
  property string iconMode: "always"
  property string tabStyle: "rings2knob"
  property string tabSource: "default"
  // Seam with TabWindow (two layer surfaces commit separately). Opening: this window draws the tab itself first, and
  // `fanPresenting` turns true only once that frame is on screen, which hides the TabWindow's tab. Closing: the fan
  // stays until `tabShown` (the TabWindow's tab is on screen again, or not wanted), so no frame is without a tab.
  property bool tabShown: true
  property bool fanDrawn: false
  property bool handBack: false
  readonly property bool fanPresenting: fanDrawn && fan.presenting
  readonly property bool fanActive: selected && !suppressed && (fan.presenting || handBack)
  onTabShownChanged: if (tabShown) handBack = false
  Connections { target: fan; function onPresentingChanged() { win.handBack = !fan.presenting && !win.tabShown } }
  Connections {
    target: fan.Window.window
    enabled: win.fanDrawn !== (fan.visible && fan.presenting)
    function onFrameSwapped() { win.fanDrawn = fan.visible && fan.presenting }
  }
  readonly property bool approaching: fan.approaching || trigger.approaching

  property bool ready: false
  Component.onCompleted: ready = true
  function cancelForGeometry() { if (ready && selected && model.captured) { model.commitDial(false,true); model.preview = -1 } }
  onWidthChanged: cancelForGeometry()
  onHeightChanged: cancelForGeometry()
  onCornerChanged: cancelForGeometry()
  onSuppressedChanged: if (suppressed && selected) model.forceHide()
  readonly property real outW: width
  readonly property real outH: height
  readonly property var cap: Geometry.capacity(size, Math.min(outW, outH))
  readonly property real fanRadius: cap.R
  readonly property var origin: Geometry.fromCanonical({ x: 0, y: outH }, outW, outH, corner)
  readonly property var radii: Geometry.ringRadii(fanRadius, Math.min(cap.rings, model.rings.length))

  WlrLayershell.namespace: "omadials"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: selected && model.open && model.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  mask: Region {
    item: win.selected && !win.suppressed && (win.model.open || fan.presenting) ? catcher : (!win.suppressed && !win.model.open ? zone : emptyZone)
    shape: win.selected && (win.model.open || fan.presenting) ? RegionShape.Rect : RegionShape.Ellipse
  }

  Item { id: emptyZone }
  Item { id: catcher; anchors.fill: parent }
  Item { id: zone; width: Gesture.TRIGGER*2; height: width; x: win.origin.x-Gesture.TRIGGER; y: win.origin.y-Gesture.TRIGGER }

  Fan {
    id: fan
    anchors.fill: parent
    theme: win.theme; model: win.model; corner: win.corner
    visible: win.fanActive; tabStyle: win.tabStyle; tabSource: win.tabSource
    forceHidden: win.suppressed || !win.selected; detailRadius: win.detailRadius; size: win.cap.size; toggleRadius: win.cap.toggleRadius; iconMode: win.iconMode
    fanRadius: win.fanRadius; radii: win.radii; origin: win.origin; screenWidth: win.outW; screenHeight: win.outH
  }

  FanInput {
    id: trigger
    targetScreen: win.screen
    anchors.fill: parent
    enabled: !win.suppressed && !win.model.open
    visible: enabled
    model: win.model; corner: win.corner; fanRadius: win.fanRadius; radii: []
    screenWidth: win.outW; screenHeight: win.outH; iconMode: win.iconMode
  }
  Item {
    anchors.fill: parent; focus: win.selected && win.model.open && win.model.wantsKeyboard
    Keys.onEscapePressed: { if (win.model.detail) win.model.closeDetail(); else win.model.close() }
    Keys.onBackPressed: { if (win.model.detail) win.model.closeDetail(); else win.model.close() }
  }
}
