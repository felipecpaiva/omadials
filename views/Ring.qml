pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../logic/Geometry.js" as Geometry
import "../logic/ValueMap.js" as ValueMap
import "../logic/Motion.js" as Motion
import "../logic/Gesture.js" as Gesture

// One dial ring: track, fill, knob and its curved label. Pure view: value and reveal come from outside.
Item {
  id: root
  required property var theme
  required property string corner
  required property real radius
  required property real screenWidth
  required property real screenHeight
  required property var control
  required property var model
  property var style: model.ringStyle(control)
  property bool compact: false
  readonly property bool readOnly: control.kind === "readout"
  readonly property real targetValue: model.draftControl === control ? ValueMap.fraction(model.draft, control.range) : (ValueMap.fraction(control.value, control.range) || 0)
  readonly property real value: valueMotion.value
  MotionValue { id: valueMotion; theme: root.theme; initial: root.targetValue; target: root.targetValue; direct: root.model.draftControl === root.control; base: Motion.TIMES.value; proportional: false }
  property real reveal: 1         // 0..1 sweep shown during the open motion
  readonly property string reading: model.draftControl === control ? Math.round(model.draft) + (control.range.unit || "") : control.valueText
  property string label: (compact ? "" : control.label + " ") + reading + (readOnly ? " · read only" : "")
  property real stroke: style.thickness === "thin" ? 2 : style.thickness === "bold" ? 6 : 4
  property real outline: 2
  readonly property real segmentCount: (control.steps || []).length > 1 ? control.steps.length-1 : Math.max(1,(control.range.max-control.range.min)/(control.range.step || Gesture.DETENT))
  readonly property var pattern: style.track === "dotted" ? [0.01,3] : style.track === "segmented" ? [1,Math.max(0.1,radius*Gesture.SWEEP*Math.PI/Geometry.DEGREES/segmentCount/stroke-1)] : [4,3]
  readonly property real a0: Geometry.RING_START
  readonly property real a1: Geometry.RING_END
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
      strokeColor: root.theme.track; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: root.readOnly ? ShapePath.FlatCap : ShapePath.RoundCap
      strokeStyle: root.style.track === "solid" ? ShapePath.SolidLine : ShapePath.DashLine
      dashPattern: root.pattern
      PathAngleArc { centerX: root.origin.x; centerY: root.origin.y; radiusX: root.radius; radiusY: root.radius; startAngle: root.track.start; sweepAngle: root.track.sweep }
    }
    ShapePath {
      strokeColor: root.control.value === null || root.control.availability === "probing" ? Qt.alpha(root.theme.accent,0) : root.theme.accent; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: root.readOnly ? ShapePath.FlatCap : ShapePath.RoundCap
      strokeStyle: root.style.track === "solid" ? ShapePath.SolidLine : ShapePath.DashLine
      dashPattern: root.pattern
      PathAngleArc { centerX: root.origin.x; centerY: root.origin.y; radiusX: root.radius; radiusY: root.radius; startAngle: root.fill.start; sweepAngle: root.fill.sweep }
    }
  }
  Rectangle {
    visible: !root.readOnly && root.style.knob !== "none" && root.control.value !== null
    width: root.style.knob === "bar" ? 6 : 14; height: 14; radius: root.style.knob === "bar" ? 2 : 7
    x: root.knob.x - width/2; y: root.knob.y - height/2
    color: root.theme.accent; border.color: root.theme.ink; border.width: root.outline
    opacity: root.reveal
  }
  Rectangle {
    visible: root.control.value !== null && root.control.value > root.control.range.max
    x: root.knob.x-3; y: root.knob.y-12; width: 6; height: 4; color: root.theme.text
  }
  Connections {
    target: root.control
    function onChanged(reason) { if (root.model.open && root.model.draftControl !== root.control) root.model.report(root.control) }
    function onWriteStateChanged() { if (root.model.open) root.model.report(root.control) }
  }
  Connections {
    target: root.model
    function onTickSerialChanged() { if (root.model.tickControl === root.control && !root.theme.reduceMotion) tick.restart() }
  }
  Connections { target: root.theme; function onReduceMotionChanged() { if (root.theme.reduceMotion) { tick.stop(); root.outline = 2 } } }
  SequentialAnimation {
    id: tick
    NumberAnimation { target: root; property: "outline"; to: 3; duration: root.theme.duration(Motion.TIMES.tickIn) ; easing.type: Easing.BezierSpline; easing.bezierCurve: root.theme.easeOut }
    NumberAnimation { target: root; property: "outline"; to: 2; duration: root.theme.duration(Motion.TIMES.tickOut) ; easing.type: Easing.BezierSpline; easing.bezierCurve: root.theme.easeOut }
  }
  Repeater {
    model: 5
    Rectangle {
      required property int index
      readonly property var pos: Geometry.fromCanonical(Geometry.knobPos(root.radius, root.a0 + index * Gesture.DETENT / Gesture.PERCENT * Gesture.SWEEP, root.screenHeight), root.screenWidth, root.screenHeight, root.corner)
      x: pos.x - 2; y: pos.y - 2; width: 4; height: 4; radius: 2
      color: root.theme.text; opacity: root.reveal
    }
  }
  CurvedLabel {
    anchors.fill: parent
    theme: root.theme; text: root.label; icon: root.control.icon; corner: root.corner
    radius: root.radius - 14; screenWidth: root.screenWidth; screenHeight: root.screenHeight
    opacity: root.reveal
  }
}
