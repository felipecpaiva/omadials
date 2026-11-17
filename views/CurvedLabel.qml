import QtQuick
import "../logic/Geometry.js" as Geometry

// Text set along a ring, on its corner side, reading left to right with upright glyphs in every corner.
Item {
  id: root
  required property var theme
  required property string text
  required property real radius        // the label's own radius (ring radius minus the label offset)
  required property string corner
  required property real screenWidth
  required property real screenHeight
  property real startAngle: 3
  property real pad: 10
  property real size: 12

  readonly property bool rightCorner: corner.indexOf("right") >= 0
  readonly property bool turnWithAngle: corner === "bottom-left" || corner === "top-right"
  readonly property real degPerPx: 180 / Math.PI / Math.max(1, radius)

  FontMetrics { id: fm; font.family: root.theme.font; font.pixelSize: root.size }

  function offsets() {
    const out = []; let x = 0
    for (const ch of root.text) { const w = fm.advanceWidth(ch); out.push(x + w / 2); x += w }
    return { centers: out, total: x }
  }
  readonly property var layout: offsets()

  Repeater {
    model: root.text.length
    Text {
      required property int index
      readonly property real along: root.rightCorner ? root.layout.total - root.layout.centers[index] : root.layout.centers[index]
      readonly property real angle: root.startAngle + (root.pad + along) * root.degPerPx
      readonly property var p: Geometry.fromCanonical(Geometry.knobPos(root.radius, angle, root.screenHeight), root.screenWidth, root.screenHeight, root.corner)
      text: root.text[index]
      color: root.theme.text
      font.family: root.theme.font
      font.pixelSize: root.size
      x: p.x - width / 2
      y: p.y - height / 2
      rotation: root.turnWithAngle ? angle : -angle
    }
  }
}
