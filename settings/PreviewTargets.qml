pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../logic/Geometry.js" as Geometry
// Sits over the preview drawing in the same coordinates: highlights the control being edited and turns a click
// on a ring or a toggle into its id. The preview fan itself stays disabled so it never runs a command.
Item {
    id: targets
    required property var theme
    required property var rings
    required property var toggles
    required property var radii
    required property real toggleRadius
    required property string corner
    property string highlightId: ""
    signal picked(string id, bool toggle)
    readonly property var slots: Geometry.arcSlots(toggleRadius)
    readonly property int ringIndex: rings.slice(0, radii.length).findIndex(c => c.controlId === targets.highlightId)
    readonly property int toggleIndex: toggles.slice(0, slots.count).findIndex(c => c.controlId === targets.highlightId)
    readonly property var origin: Geometry.fromCanonical({x:0, y:height}, width, height, corner)
    readonly property var arc: Geometry.qtArc(Geometry.RING_START, Geometry.RING_END, corner)
    function togglePos(i) {
        return Geometry.fromCanonical(Geometry.knobPos(toggleRadius, Geometry.ARC_START + slots.step*(i + 0.5), height), width, height, corner);
    }
    Shape {
        anchors.fill: parent
        visible: targets.ringIndex >= 0
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.alpha(targets.theme.accent, 0.35); strokeWidth: Geometry.BAND; fillColor: Qt.alpha(targets.theme.accent, 0)
            PathAngleArc {
                centerX: targets.origin.x; centerY: targets.origin.y
                radiusX: targets.ringIndex >= 0 ? targets.radii[targets.ringIndex] : 0; radiusY: radiusX
                startAngle: targets.arc.start; sweepAngle: targets.arc.sweep
            }
        }
    }
    Rectangle {
        readonly property var pos: targets.toggleIndex >= 0 ? targets.togglePos(targets.toggleIndex) : ({x:0, y:0})
        visible: targets.toggleIndex >= 0
        width: Geometry.TARGET; height: width; radius: width/2
        x: pos.x - width/2; y: pos.y - height/2
        color: Qt.alpha(targets.theme.accent, 0.25); border.color: targets.theme.accent; border.width: 3
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            const c = Geometry.toCanonical({x:mouse.x, y:mouse.y}, targets.width, targets.height, targets.corner);
            const p = Geometry.polar(c.x, c.y, targets.height);
            const ring = Geometry.hitRing(p.d, targets.radii);
            if (ring >= 0 && ring < targets.rings.length) { targets.picked(targets.rings[ring].controlId, false); return; }
            if (Math.abs(p.d - targets.toggleRadius) > Geometry.TARGET/2) return;
            const slot = Math.floor((p.a - Geometry.ARC_START)/targets.slots.step);
            if (slot >= 0 && slot < Math.min(targets.slots.count, targets.toggles.length)) targets.picked(targets.toggles[slot].controlId, true);
        }
    }
}
