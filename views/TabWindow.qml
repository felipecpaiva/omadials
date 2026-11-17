pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../logic/Geometry.js" as Geometry
import "../logic/ValueMap.js" as ValueMap
import "../logic/Motion.js" as Motion

// Quickshell creates this type through its engine.
// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: tab
    required property var theme
    required property var model
    AnimatedTheme { id: tabPalette; source: tab.theme }
    property string corner: "bottom-left"
    property string iconMode: "always"
    property bool iconAboveWindows: true
    property bool approaching: false
    property bool fanPresenting: model.open
    property bool suppressed: false
    signal iconFailed(string source)
    property string source: "default"
    property string tabStyle: "rings2knob"
    readonly property var origin: Geometry.fromCanonical({x:0,y:height},width,height,corner)
    WlrLayershell.namespace: "omadials-tab"
    WlrLayershell.layer: iconAboveWindows ? WlrLayer.Top : WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region {}
    Item {
        anchors.fill: parent
        opacity: tabMotion.value
        MotionValue { id: tabMotion; theme: tabPalette; target: !tab.suppressed && !tab.fanPresenting && (tab.iconMode === "always" || tab.iconMode === "onApproach" && tab.approaching) ? 1 : 0; base: Motion.TIMES.hint }
        Rectangle { x: tab.origin.x-42; y: tab.origin.y-42; width: 84; height: 84; radius: 42; color: tabPalette.surface; border.color: tabPalette.edge }
        // The tab is a tiny live readout: each mini ring is filled to its dial's real value (outer ring = first dial).
        Repeater {
            id: miniRings
            model: customIcon.visible ? [] : tab.tabStyle === "rings2knob" ? [32,21] : [32,24,16]
            Shape {
                id: miniRing
                required property real modelData
                required property int index
                readonly property var control: tab.model.rings.length > index ? tab.model.rings[index] : null
                readonly property real level: control && control.kind !== "readout" ? (ValueMap.fraction(control.value, control.range) || 0) : 0
                readonly property real endAngle: Geometry.RING_START + (Geometry.RING_END - Geometry.RING_START) * level
                anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
                readonly property var trackArc: Geometry.qtArc(Geometry.RING_START, Geometry.RING_END, tab.corner)
                readonly property var fillArc: Geometry.qtArc(Geometry.RING_START, Math.max(Geometry.RING_START + 0.01, endAngle), tab.corner)
                ShapePath {
                    strokeColor: tabPalette.track; strokeWidth: 2.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: tab.origin.x; centerY: tab.origin.y; radiusX: miniRing.modelData; radiusY: miniRing.modelData; startAngle: miniRing.trackArc.start; sweepAngle: miniRing.trackArc.sweep }
                }
                ShapePath {
                    strokeColor: tabPalette.accent; strokeWidth: 2.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: tab.origin.x; centerY: tab.origin.y; radiusX: miniRing.modelData; radiusY: miniRing.modelData; startAngle: miniRing.fillArc.start; sweepAngle: miniRing.fillArc.sweep }
                }
            }
        }
        Rectangle {   // the knob rides the outer ring's value
            readonly property var outer: miniRings.count > 0 ? miniRings.itemAt(0) : null
            readonly property var pos: Geometry.fromCanonical(Geometry.knobPos(32, outer ? outer.endAngle : 48, tab.height), tab.width, tab.height, tab.corner)
            visible: !customIcon.visible && tab.tabStyle !== "rings3";  // knob for rings2knob and rings3knob
            x: pos.x-4; y: pos.y-4; width: 8; height: 8; radius: 4; color: tabPalette.accent
        }
        Image {
            id: customIcon
            x: tab.corner.indexOf("right") >= 0 ? tab.width-28 : 8
            y: tab.corner.indexOf("top") >= 0 ? 8 : tab.height-28
            width: 20; height: 20; source: tab.source === "default" ? "" : (tab.source.indexOf("/") >= 0 ? tab.source : "image://icon/"+tab.source)
            visible: status === Image.Ready
            onStatusChanged: if (status === Image.Error) tab.iconFailed(tab.source)
        }
    }
}
