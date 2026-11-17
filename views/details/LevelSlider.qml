import QtQuick
import QtQuick.Controls
Column {
    id: level
    property var theme
    property var model
    property string label: ""
    property real reading: 0
    property real maximum: 100
    property real minimum: 0
    signal committed(real value)
    width: parent.width
    spacing: 4
    DetailText { theme: level.theme; text: level.label + ": " + Math.round(slider.pressed ? slider.value : level.reading) + "%" }
    Slider {
        id: slider
        width: parent.width; height: 48
        from: level.minimum; to: level.maximum; stepSize: 1
        value: level.reading
        Accessible.name: level.label
        onPressedChanged: {
            if (level.model) { level.model.captured = pressed; level.model.activity() }
            if (!pressed) level.committed(value)
        }
        onMoved: if (!pressed) { level.committed(value); if (level.model) level.model.activity() }
        background: Rectangle { x: 0; y: 22; width: slider.width; height: 4; radius: 2; color: level.theme.track }
        handle: Rectangle { x: slider.visualPosition*(slider.width-width); y: 14; width: 20; height: 20; radius: 10; color: level.theme.accent; border.color: slider.activeFocus ? level.theme.text : level.theme.edge }
    }
    Component.onDestruction: if (model && slider.pressed) { model.captured = false; model.activity() }
}
