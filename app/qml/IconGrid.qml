pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Glyphs.js" as Glyphs
// Icon choice as a grid of the built-in glyphs only (never a file system scan, see docs/performance.md),
// plus any icon theme name typed in.
ColumnLayout {
    id: grid
    required property var store
    required property var theme
    required property string path
    required property string defaultIcon
    readonly property string current: store.value(path) || "default"
    readonly property var names: ["default"].concat(Object.keys(Glyphs.GLYPHS))
    Layout.fillWidth: true
    spacing: 8
    Label { text: qsTr("Icon") }
    Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: grid.theme.secondary; font.pixelSize: 12; text: qsTr("Pick a built-in icon, or type the name of one from your desktop icon theme.") }
    Flow {
        Layout.fillWidth: true; spacing: 6
        Repeater {
            model: grid.names
            AbstractButton {
                id: choice
                required property string modelData
                width: 44; height: 44; hoverEnabled: true; focusPolicy: Qt.TabFocus
                readonly property bool chosen: grid.current === modelData
                Accessible.role: Accessible.Button
                Accessible.name: modelData === "default" ? qsTr("Default icon") : modelData
                ToolTip.visible: hovered; ToolTip.delay: 600
                ToolTip.text: modelData === "default" ? qsTr("Default") : modelData
                background: Rectangle {
                    radius: grid.theme.radius
                    color: choice.chosen ? grid.theme.off : choice.hovered ? grid.theme.surface : grid.theme.clear
                    border.width: choice.chosen || choice.visualFocus ? 2 : 1
                    border.color: choice.chosen || choice.visualFocus ? grid.theme.accent : grid.theme.edge
                }
                contentItem: Text {
                    text: Glyphs.glyph(choice.modelData === "default" ? grid.defaultIcon : choice.modelData)
                    font.family: "Symbols Nerd Font"; font.pixelSize: 22
                    color: choice.chosen ? grid.theme.accent : grid.theme.text
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                onClicked: grid.store.set(grid.path, modelData)
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        TextField {
            id: typed; objectName: "iconNameField"
            Layout.fillWidth: true
            placeholderText: qsTr("Type an icon name")
            Accessible.name: qsTr("Type an icon name")
            selectByMouse: true
            text: grid.names.indexOf(grid.current) < 0 ? grid.current : ""
            onEditingFinished: { let name = text.trim(); if ((name || "default") !== grid.current) grid.store.set(grid.path, name || "default") }
        }
        ControlIcon { theme: grid.theme; store: grid.store; name: grid.names.indexOf(grid.current) < 0 ? grid.current : ""; visible: name.length > 0 }
    }
}
