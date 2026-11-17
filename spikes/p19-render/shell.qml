// Spike P1.9: frame times while 3 dashed ring arcs (QtQuick.Shapes, CurveRenderer) change angle every frame.
// Run: timeout 15 qs -p spikes/p19-render
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
ShellRoot {
  PanelWindow {
    WlrLayershell.namespace: "omadials-p19"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { bottom: true; left: true }
    implicitWidth: 420; implicitHeight: 420
    color: "transparent"
    mask: Region {}
    property real t: 0
    id: win
    Repeater {
      model: 3
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: "#ff8c78"; strokeWidth: 4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
          strokeStyle: index === 1 ? ShapePath.DashLine : ShapePath.SolidLine
          PathAngleArc {
            centerX: 0; centerY: 420; radiusX: 398 - index * 44; radiusY: radiusX
            startAngle: -87; sweepAngle: 84 * (0.5 + 0.5 * Math.sin(win.t + index))
          }
        }
      }
    }
    FrameAnimation {
      running: true
      property var dts: []
      onTriggered: {
        win.t += frameTime * 3
        if (elapsedTime > 1) dts.push(frameTime * 1000)
        if (elapsedTime > 7) {
          const s = dts.slice().sort((a, b) => a - b)
          const p = q => s[Math.min(s.length - 1, Math.floor(q * s.length))].toFixed(2)
          console.log("RESULT frames=" + s.length + " avg=" + (s.reduce((a, b) => a + b, 0) / s.length).toFixed(2) + "ms p95=" + p(0.95) + " p99=" + p(0.99) + " max=" + s[s.length - 1].toFixed(2))
          Qt.quit()
        }
      }
    }
  }
}
