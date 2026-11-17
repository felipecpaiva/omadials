pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import "../logic/Gesture.js" as Gesture
import "../logic/Motion.js" as Motion

FocusScope {
    id: button
    required property var theme
    required property var control
    required property var model
    property bool down: false
    property real holdProgress: 0
    property bool proposed: false
    readonly property bool on: control.writeState === "pending" ? proposed : !!control.value
    width: Gesture.TARGET; height: Gesture.TARGET
    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: control.label + ", " + control.valueText
    Accessible.checked: on
    scale: pressMotion.value
    MotionValue { id: pressMotion; theme: button.theme; initial: 1; travel: 0.08; target: button.down ? 0.92 : 1; base: button.down ? Motion.TIMES.press : Motion.TIMES.return }
    Rectangle {
        anchors.centerIn: parent; width: 40; height: 40; radius: 20
        color: button.on ? button.theme.accent : button.theme.off
        border.color: button.activeFocus ? button.theme.text : button.theme.edge
        Behavior on color { ColorAnimation { id: fillMotion; duration: button.theme.duration(Motion.TIMES.fill) } }
    }
    Shape {
        anchors.fill: parent; preferredRendererType: Shape.CurveRenderer
        ShapePath {
            id: outline
            strokeColor: button.control.writeState === "failed" ? button.theme.warn : button.theme.text
            strokeWidth: 2; fillColor: "transparent"; strokeStyle: ShapePath.DashLine; dashPattern: [3,3]
            NumberAnimation on dashOffset {
                from: 0; to: 12; duration: button.theme.duration(Motion.TIMES.pending); loops: Animation.Infinite
                running: button.control.writeState === "pending" && !button.theme.reduceMotion && button.model.open
            }
            PathAngleArc { centerX: 24; centerY: 24; radiusX: 22; radiusY: 22; startAngle: -90; sweepAngle: button.control.writeState === "pending" || button.control.writeState === "failed" ? 360 : button.holdProgress * 360 }
        }
    }
    ControlIcon { anchors.centerIn: parent; width: 20; height: 20; theme: button.theme; name: button.control.icon; ink: button.on ? button.theme.ink : button.theme.text; visible: button.control.writeState !== "failed" }
    Text { anchors.centerIn: parent; text: "⚠"; visible: button.control.writeState === "failed"; color: button.theme.warn; font.family: button.theme.font; font.pixelSize: 18 }
    Connections { target: button.theme; function onReduceMotionChanged() { if (button.theme.reduceMotion) fillMotion.complete() } }
    Connections { target: button.model; function onActionRequested(control) { if (control === button.control) button.proposed = !control.value } }
    Connections {
        target: button.control
        function onChanged(reason) { button.model.report(button.control) }
        function onWriteStateChanged() { if (button.control.writeState === "failed") button.model.report(button.control) }
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu || (event.key === Qt.Key_Return && event.modifiers & Qt.ShiftModifier)) button.model.action(button.control,true)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) { button.model.action(button.control,false); button.model.activity() }
        else { event.accepted = false; return }
        event.accepted = true
    }
}
