pragma ComponentBehavior: Bound
import QtQuick

FocusScope {
    id: row
    required property var theme
    required property var control
    required property var rowData
    required property var model
    implicitHeight: Math.max(48,copy.implicitHeight+20)
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: copy.text
    Rectangle { anchors.fill: parent; color: row.activeFocus ? row.theme.off : Qt.alpha(row.theme.surface,0); border.color: row.theme.edge; radius: 8 }
    Text {
        id: copy; x: 12; y: 10; width: parent.width-24
        text: (row.rowData.icon ? row.rowData.icon+" " : "") + row.rowData.label + (row.rowData.sub ? "\n"+row.rowData.sub : "") + (row.rowData.state ? " · "+row.rowData.state : "")
        wrapMode: Text.WrapAnywhere; color: row.theme.text; font.family: row.theme.font; font.pixelSize: 14
    }
    function pick() { control.activate(rowData.key); model.activity() }
    MouseArea { anchors.fill: parent; onClicked: row.pick() }
    Keys.onReturnPressed: pick()
    Keys.onSpacePressed: pick()
}
