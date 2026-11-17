import QtQuick
import "../logic/Geometry.js" as Geometry
import "../logic/ValueMap.js" as ValueMap

// Pointer and touch on the corner. Tap the zone to open or close; outside closes; a ring changes only after a 6 px drag.
MouseArea {
  id: input
  required property var model
  required property string corner
  required property real R
  required property var radii
  required property real screenWidth
  required property real screenHeight

  property int ring: -1
  property point start
  property bool dragging: false
  property double pressedAt: 0

  function polarOf(x, y) {
    const c = Geometry.toCanonical({ x: x, y: y }, screenWidth, screenHeight, corner)
    return Geometry.polar(c.x, c.y, screenHeight)
  }
  onPressed: (m) => {
    start = Qt.point(m.x, m.y); pressedAt = Date.now(); dragging = false
    const p = polarOf(m.x, m.y)
    ring = model.open ? Geometry.hitRing(p.d, radii) : -1
    model.activity()
  }
  onPositionChanged: (m) => {
    if (ring < 0) return
    if (!dragging && Math.hypot(m.x - start.x, m.y - start.y) < 6) return
    dragging = true
    const p = polarOf(m.x, m.y)
    model.rings[ring].set(Math.max(0, Math.min(1, (p.a - 3) / 84)))
    model.activity()
  }
  onReleased: (m) => {
    const p = polarOf(m.x, m.y), quick = Date.now() - pressedAt <= 400 && Math.hypot(m.x - start.x, m.y - start.y) < 10
    if (!dragging && quick && p.d <= 32) model.toggle()
    else if (!dragging && model.open && p.d > R) model.close()
    ring = -1; dragging = false
  }
}
