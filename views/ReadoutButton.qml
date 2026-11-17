pragma ComponentBehavior: Bound
import QtQuick

FocusScope {
    id: button
    required property var theme
    required property var box
    required property string text
    signal clicked()
    x: box.x; y: box.y; width: box.width; height: Math.max(48,copy.implicitHeight+16)
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Rectangle { anchors.fill: parent; radius: 12; color: button.theme.off; border.color: button.activeFocus ? button.theme.text : button.theme.edge }
    Text { id: copy; anchors.centerIn: parent; width: parent.width-12; text: button.text; wrapMode: Text.WrapAnywhere; horizontalAlignment: Text.AlignHCenter; color: button.theme.text; font.family: button.theme.font; font.pixelSize: 12 }
    MouseArea { anchors.fill: parent; onClicked: button.clicked() }
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
}
