import QtQuick
import QtQuick.Shapes
import "../logic/Geometry.js" as Geometry

// One dial ring: track, fill, knob and its curved label. Pure view: value and reveal come from outside.
Item {
  id: root
  required property var theme
  required property string corner
  required property real radius
  required property real screenWidth
  required property real screenHeight
  property real value: 0          // 0..1 of the ring
  property real reveal: 1         // 0..1 sweep shown during the open motion
  property string label: ""
  property real stroke: 4
  readonly property real a0: 3
  readonly property real a1: 87
  readonly property var origin: Geometry.fromCanonical({ x: 0, y: screenHeight }, screenWidth, screenHeight, corner)
  readonly property real shownEnd: a0 + (a1 - a0) * reveal
  readonly property real valueAngle: a0 + (a1 - a0) * Math.max(0, Math.min(1, value))
  readonly property var track: Geometry.qtArc(a0, Math.max(a0 + 0.01, shownEnd), corner)
  readonly property var fill: Geometry.qtArc(a0, Math.max(a0 + 0.01, Math.min(shownEnd, valueAngle)), corner)
  readonly property var knob: Geometry.fromCanonical(Geometry.knobPos(radius, valueAngle, screenHeight), screenWidth, screenHeight, corner)

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: root.theme.track; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathAngleArc { centerX: root.origin.x; centerY: root.origin.y; radiusX: root.radius; radiusY: root.radius; startAngle: root.track.start; sweepAngle: root.track.sweep }
    }
    ShapePath {
      strokeColor: root.theme.accent; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: ShapePath.RoundCap
      PathAngleArc { centerX: root.origin.x; centerY: root.origin.y; radiusX: root.radius; radiusY: root.radius; startAngle: root.fill.start; sweepAngle: root.fill.sweep }
    }
  }
  Rectangle {
    width: 14; height: 14; radius: 7
    x: root.knob.x - 7; y: root.knob.y - 7
    color: root.theme.accent; border.color: root.theme.ink; border.width: 2
    opacity: root.reveal
  }
  CurvedLabel {
    anchors.fill: parent
    theme: root.theme; text: root.label; corner: root.corner
    radius: root.radius - 14; screenWidth: root.screenWidth; screenHeight: root.screenHeight
    opacity: root.reveal
  }
}
