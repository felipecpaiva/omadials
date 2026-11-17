import QtQuick
Text {
    property var theme
    width: parent.width
    textFormat: Text.PlainText
    wrapMode: Text.Wrap
    color: theme.text
    font.family: theme.font
    font.pixelSize: 14
}
