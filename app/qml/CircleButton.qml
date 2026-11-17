import QtQuick
import QtQuick.Controls
// A 48 px icon button: "add" (plus in a circle), "remove" (minus in a circle) or "edit" (pencil).
AbstractButton {
    id: button
    required property var theme
    property string kind: "add"
    implicitWidth: 48; implicitHeight: 48
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    Accessible.role: Accessible.Button
    Accessible.name: text
    ToolTip.visible: hovered && text.length > 0
    ToolTip.text: text
    ToolTip.delay: 600
    readonly property color ink: !enabled ? theme.edge : kind === "remove" && hovered ? theme.warn : kind === "add" ? theme.accent : theme.text
    background: Rectangle {
        radius: button.theme.radius
        color: button.down || button.hovered ? button.theme.off : button.theme.clear
        border.width: button.visualFocus ? 2 : 0; border.color: button.theme.accent
    }
    contentItem: Item {
        Rectangle {
            visible: button.kind !== "edit"; anchors.centerIn: parent
            width: 26; height: 26; radius: 13; color: button.theme.clear
            border.width: 2; border.color: button.ink
        }
        Rectangle { visible: button.kind !== "edit"; anchors.centerIn: parent; width: 12; height: 2; color: button.ink }
        Rectangle { visible: button.kind === "add"; anchors.centerIn: parent; width: 2; height: 12; color: button.ink }
        Text {
            visible: button.kind === "edit"; anchors.centerIn: parent
            text: "\u{F03EB}"; font.family: "Symbols Nerd Font"; font.pixelSize: 22; color: button.ink
        }
    }
}
