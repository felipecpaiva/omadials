import QtQuick
import Quickshell.Services.UPower

// The open quarter: surface, rings and the corner readout. Motion follows experience.md (180 ms open, 20 ms ring stagger,
// 120 ms close to 0.8, shared ease-out curve). Behaviors start from the shown value, so a reversal never jumps.
Item {
  id: fan
  required property var theme
  required property var model
  required property string corner
  required property real R
  required property var radii
  required property var origin
  required property real screenWidth
  required property real screenHeight

  readonly property bool open: model.open
  opacity: open ? 1 : 0
  visible: opacity > 0
  transform: Scale { id: zoom; origin.x: fan.origin.x; origin.y: fan.origin.y; xScale: fan.open ? 1 : (fan.visible ? 0.8 : 0.6); yScale: xScale
    Behavior on xScale { NumberAnimation { duration: fan.theme.duration(fan.open ? 180 : 120); easing.type: Easing.BezierSpline; easing.bezierCurve: fan.theme.easeOut } } }
  Behavior on opacity { NumberAnimation { duration: fan.theme.duration(fan.open ? 180 : 120); easing.type: Easing.BezierSpline; easing.bezierCurve: fan.theme.easeOut } }

  Rectangle {   // the quarter disc: a circle centred on the corner, the screen edges cut the rest
    x: fan.origin.x - fan.R; y: fan.origin.y - fan.R; width: 2 * fan.R; height: width; radius: fan.R
    color: fan.theme.surface; border.color: fan.theme.edge; border.width: 1
  }

  Repeater {
    model: fan.model.rings
    Ring {
      required property var modelData
      required property int index
      anchors.fill: parent
      theme: fan.theme; corner: fan.corner; radius: fan.radii[index]
      screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
      value: modelData.value; label: modelData.label
      reveal: fan.open ? 1 : 0
      Behavior on reveal { SequentialAnimation {
        PauseAnimation { duration: fan.open ? fan.theme.duration(index * 20) : 0 }
        NumberAnimation { duration: fan.theme.duration(fan.open ? 180 : 120); easing.type: Easing.BezierSpline; easing.bezierCurve: fan.theme.easeOut } } }
    }
  }

  Text {   // corner readout: battery number (more readout pieces arrive with the layout pass)
    readonly property bool right: fan.corner.indexOf("right") >= 0
    readonly property bool top: fan.corner.indexOf("top") >= 0
    text: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
    color: fan.theme.text; font.family: fan.theme.font; font.pixelSize: 40
    x: right ? fan.screenWidth - 12 - width : 12
    y: top ? 12 : fan.screenHeight - 12 - height - 60
  }
}
