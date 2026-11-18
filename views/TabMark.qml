pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../logic/Geometry.js" as Geometry
import "../logic/ValueMap.js" as ValueMap
import "../logic/OpenStyles.js" as OpenStyles

// The closed tab: a small disc in the corner with live mini rings (outer ring = first dial) or a custom icon.
// TabWindow draws it while closed; Fan draws the same mark inside the corner window while it opens and closes, so
// the first and last frames of every open style are exactly this.
Item {
    id: mark
    required property var theme
    required property var model
    required property string corner
    property string tabStyle: "rings2knob"
    property string source: "default"
    signal iconFailed(string source)
    readonly property bool custom: customIcon.status === Image.Ready   // not `visible`: that turns false when hidden
    // What the open styles start from: the mini ring radii ([] for a custom icon) and whether a knob rides the first.
    // cornerIcon.scale (0.5 to 1): the whole tab shrinks around the corner, and the open styles start from it.
    readonly property real tabScale: model.config.cornerIcon && model.config.cornerIcon.scale > 0 ? model.config.cornerIcon.scale : 1
    readonly property bool battery: !custom && model.batteryRing   // the battery is rings[0], drawn as the outer mini ring
    readonly property var mini: custom ? [] : (battery ? [OpenStyles.TAB.battery] : []).concat(OpenStyles.TAB.mini[tabStyle] || OpenStyles.TAB.mini.rings2knob).map(r => r * tabScale)
    readonly property int knobRing: battery ? 1 : 0
    readonly property bool knob: !custom && OpenStyles.TAB.knob0[tabStyle] === true
    readonly property real tabRadius: OpenStyles.TAB.radius * tabScale
    readonly property var origin: Geometry.fromCanonical({ x: 0, y: height }, width, height, corner)
    Rectangle {
        x: mark.origin.x - mark.tabRadius; y: mark.origin.y - mark.tabRadius; width: mark.tabRadius * 2; height: width; radius: mark.tabRadius
        color: mark.theme.surface; border.color: mark.theme.edge
    }
    Repeater {
        id: miniRings
        model: mark.mini
        Shape {
            id: miniRing
            required property real modelData
            required property int index
            readonly property var control: mark.model.rings.length > index ? mark.model.rings[index] : null
            readonly property bool isBattery: !!control && control === mark.model.battery
            readonly property real level: control && (control.kind !== "readout" || isBattery) ? (ValueMap.fraction(control.value, control.range) || 0) : 0
            readonly property real endAngle: Geometry.RING_START + (Geometry.RING_END - Geometry.RING_START) * level
            readonly property var trackArc: Geometry.qtArc(Geometry.RING_START, Geometry.RING_END, mark.corner)
            readonly property var fillArc: Geometry.qtArc(Geometry.RING_START, Math.max(Geometry.RING_START + 0.01, endAngle), mark.corner)
            anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: mark.theme.track; strokeWidth: OpenStyles.TAB.stroke * mark.tabScale; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: mark.origin.x; centerY: mark.origin.y; radiusX: miniRing.modelData; radiusY: miniRing.modelData; startAngle: miniRing.trackArc.start; sweepAngle: miniRing.trackArc.sweep }
            }
            ShapePath {
                strokeColor: miniRing.isBattery && mark.model.batteryLow ? mark.theme.warn : mark.theme.accent; strokeWidth: OpenStyles.TAB.stroke * mark.tabScale; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: mark.origin.x; centerY: mark.origin.y; radiusX: miniRing.modelData; radiusY: miniRing.modelData; startAngle: miniRing.fillArc.start; sweepAngle: miniRing.fillArc.sweep }
            }
        }
    }
    Rectangle {   // the knob rides the outer ring's value
        readonly property var outer: miniRings.count > mark.knobRing ? miniRings.itemAt(mark.knobRing) : null
        readonly property real ringRadius: mark.mini.length > mark.knobRing ? mark.mini[mark.knobRing] : 0
        readonly property var pos: Geometry.fromCanonical(Geometry.knobPos(ringRadius, outer ? outer.endAngle : Geometry.RING_START, mark.height), mark.width, mark.height, mark.corner)
        visible: mark.knob
        x: pos.x - width / 2; y: pos.y - height / 2; width: OpenStyles.TAB.knob * mark.tabScale; height: width; radius: width / 2; color: mark.theme.accent
    }
    Image {
        id: customIcon
        readonly property real gap: 8 * mark.tabScale
        x: mark.corner.indexOf("right") >= 0 ? mark.width - gap - width : gap
        y: mark.corner.indexOf("top") >= 0 ? gap : mark.height - gap - height
        width: 20 * mark.tabScale; height: width; sourceSize: Qt.size(20, 20); source: mark.source === "default" ? "" : (mark.source.indexOf("/") >= 0 ? mark.source : "image://icon/" + mark.source)
        visible: mark.custom
        onStatusChanged: if (status === Image.Error) mark.iconFailed(mark.source)
    }
}
