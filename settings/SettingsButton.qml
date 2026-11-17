pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

Button {
    id: settingsButton
    required property var theme
    implicitHeight: 48
    Accessible.name: text
    font.family: theme.font
    contentItem: Text {
        text: settingsButton.text
        textFormat: Text.PlainText
        color: settingsButton.theme.text
        font: settingsButton.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        color: settingsButton.down ? settingsButton.theme.track : settingsButton.theme.off
        border.color: settingsButton.activeFocus ? settingsButton.theme.accent : settingsButton.theme.edge
    }
}
