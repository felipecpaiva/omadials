pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: undoBar
    required property var store
    required property var theme
    visible: store.canUndo
    Text {
        text: "Settings changed. Undo is available for 10 seconds."
        Layout.fillWidth: true; wrapMode: Text.WordWrap
        color: undoBar.theme.text; font.family: undoBar.theme.font
    }
    SettingsButton { theme: undoBar.theme; text: "Undo"; onClicked: undoBar.store.undo() }
}
