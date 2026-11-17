import QtQuick
import QtQuick.Layouts
Text {
    required property var theme
    Layout.fillWidth: true
    color: theme.secondary
    font.family: theme.font
    textFormat: Text.PlainText
    wrapMode: Text.WordWrap
}
