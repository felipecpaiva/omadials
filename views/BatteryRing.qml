pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../logic/Geometry.js" as Geometry

// The battery ring (cornerIcon.battery): thin, read only, the theme's warn colour when low. TabMark draws it inside
// the closed tab; Fan draws it at the disc edge, growing with the disc, so it is the same ring closed and open.
Shape {
    id: ring
    required property var theme
    required property var model
    required property string corner
    required property point origin
    required property real radius
    required property real stroke
    readonly property var bat: model.battery
    readonly property real level: bat && bat.value !== null ? bat.value / 100 : 0
    readonly property var trackArc: Geometry.qtArc(Geometry.RING_START, Geometry.RING_END, corner)
    readonly property var fillArc: Geometry.qtArc(Geometry.RING_START, Math.max(Geometry.RING_START + 0.01, Geometry.RING_START + (Geometry.RING_END - Geometry.RING_START) * level), corner)
    visible: !!bat && bat.value !== null && !(model.config.cornerIcon && model.config.cornerIcon.battery === false)
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeColor: ring.theme.track; strokeWidth: ring.stroke; fillColor: "transparent"; capStyle: ShapePath.RoundCap
        PathAngleArc { centerX: ring.origin.x; centerY: ring.origin.y; radiusX: ring.radius; radiusY: ring.radius; startAngle: ring.trackArc.start; sweepAngle: ring.trackArc.sweep }
    }
    ShapePath {
        strokeColor: ring.model.batteryLow ? ring.theme.warn : ring.theme.accent; strokeWidth: ring.stroke; fillColor: "transparent"; capStyle: ShapePath.RoundCap
        PathAngleArc { centerX: ring.origin.x; centerY: ring.origin.y; radiusX: ring.radius; radiusY: ring.radius; startAngle: ring.fillArc.start; sweepAngle: ring.fillArc.sweep }
    }
}
