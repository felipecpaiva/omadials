pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Glyphs.js" as Glyphs
import QtQuick.Layouts
import Quickshell
ColumnLayout {
    id: picker
    required property var theme
    required property var store
    required property string path
    property string label: "Icon"
    Layout.fillWidth: true
    RowLayout {
        Image { Layout.preferredWidth: 28; Layout.preferredHeight: 28; source: picker.store.value(picker.path) === "default" ? "" : Quickshell.iconPath(picker.store.value(picker.path) || "") }
        SettingField { theme: picker.theme; store: picker.store; path: picker.path; label: picker.label; hint: "Pick a built-in icon or type any installed icon name. Default keeps the original."; kind: "editableChoice"; choices: ["default"].concat(Object.keys(Glyphs.GLYPHS)) }
    }
}
