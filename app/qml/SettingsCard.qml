import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Pane {
    id: card
    required property var theme
    property string title
    default property alias rows: body.data
    Layout.fillWidth: true
    padding: 16
    background: Rectangle { color: card.theme.surface; radius: card.theme.radius }
    contentItem: ColumnLayout {
        id: body; spacing: 10
        Label { text: card.title; font.bold: true; font.pixelSize: 16; color: card.theme.text; visible: text.length > 0 }
    }
}
