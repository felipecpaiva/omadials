pragma ComponentBehavior: Bound
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
  property string icon: ""
  property real startAngle: Geometry.RING_START
  property real pad: Geometry.LABEL_PAD + (icon ? 24 : 0)
  property real size: 12

  readonly property var pathGeometry: Geometry.labelPath(radius + Geometry.LABEL_OFFSET, screenHeight, screenWidth, screenHeight, corner)
  readonly property bool rightCorner: corner.indexOf("right") >= 0
  readonly property bool turnWithAngle: corner === "bottom-left" || corner === "top-right"
  readonly property real degPerPx: 180 / Math.PI / Math.max(1, radius)

  FontMetrics { id: fm; font.family: root.theme.font; font.pixelSize: root.size }

  function offsets() {
    const out = []; let along = 0, line = 0
    for (const ch of root.text) {
      const w = fm.advanceWidth(ch)
      const r = root.pathGeometry.radius-line*(root.size+2)
      const capacity = r*(Geometry.RING_END-root.startAngle)*Math.PI/Geometry.DEGREES-root.pad
      if (along+w > capacity) { line++; along = 0 }
      out.push({center:along+w/2,line:line}); along += w
    }
    const totals = []
    out.forEach(function(p,i) { totals[p.line] = p.center+fm.advanceWidth(root.text[i])/2 })
    return {glyphs:out,totals:totals}
  }
  readonly property var layout: offsets()

  ControlIcon {
    readonly property real angle: root.startAngle + (Geometry.LABEL_PAD+8)*root.degPerPx
    readonly property var p: Geometry.fromCanonical(Geometry.knobPos(root.pathGeometry.radius,angle,root.screenHeight),root.screenWidth,root.screenHeight,root.corner)
    x: p.x-8; y: p.y-8; width: 16; height: 16
    theme: root.theme; name: root.icon; visible: !!root.icon
  }
  Repeater {
    model: root.text.length
    Text {
      required property int index
      readonly property var glyph: root.layout.glyphs[index]
      readonly property real glyphRadius: root.pathGeometry.radius-glyph.line*(root.size+2)
      readonly property real along: root.rightCorner ? root.layout.totals[glyph.line]-glyph.center : glyph.center
      readonly property real angle: root.startAngle + (root.pad + along) * Geometry.DEGREES/Math.PI/Math.max(1,glyphRadius)
      readonly property var p: Geometry.fromCanonical(Geometry.knobPos(glyphRadius, angle, root.screenHeight), root.screenWidth, root.screenHeight, root.corner)
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
