pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
Rectangle {
    id: card
    required property var theme
    required property string title
    default property alias rows: cardRows.data
    Layout.fillWidth: true
    implicitHeight: cardRows.implicitHeight + 24
    color: theme.off
    border.color: theme.edge
    radius: 8
    ColumnLayout {
        id: cardRows
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 10
        Text { text: card.title; color: card.theme.text; font.family: card.theme.font; font.bold: true }
    }
}
