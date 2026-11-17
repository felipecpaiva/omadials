pragma ComponentBehavior: Bound
import QtQuick
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
        SettingField { theme: picker.theme; store: picker.store; path: picker.path; label: picker.label; hint: "Choose an installed icon, or Default for the original drawing."; choices: ["default"].concat(picker.store.validationResources.icons || []) }
    }
}
