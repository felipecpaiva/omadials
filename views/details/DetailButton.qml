import QtQuick
import ".."
ReadoutButton {
    id: actionButton
    property var model
    box: ({x: 0, y: 0, width: parent.width, height: 48})
    opacity: enabled ? 1 : 0.5
    onClicked: if (model) model.activity()
}
