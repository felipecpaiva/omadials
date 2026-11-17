pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Labels.js" as Labels
import QtQuick.Layouts
import Quickshell
ColumnLayout {
    id: aboutPage
    required property var store
    required property var theme
    required property var registry
    property bool confirmingReset: false
    spacing: 16
    SettingsCard {
        theme: aboutPage.theme; title: "About omadials"
        HelpText { theme: aboutPage.theme; text: "Version 0.1.0. Quick settings in a screen corner." }
        SettingsButton { theme: aboutPage.theme; text: "Read the README"; onClicked: Qt.openUrlExternally(Qt.resolvedUrl("../README.md")) }
    }
    SettingsCard {
        theme: aboutPage.theme; title: "Plugin status"
        Repeater {
            model: aboutPage.registry.controls
            ColumnLayout {
            id: statusRow
                required property var modelData
                Layout.fillWidth: true
                Text { text: statusRow.modelData.label; color: aboutPage.theme.text; font.family: aboutPage.theme.font }
                HelpText { theme: aboutPage.theme; text: Labels.statusText(statusRow.modelData) }
            }
        }
        SettingsButton { theme: aboutPage.theme; text: "Copy details"; onClicked: Quickshell.clipboardText = aboutPage.registry.status() }
    }
    SettingsCard {
        theme: aboutPage.theme; title: "Advanced"
        HelpText { theme: aboutPage.theme; text: aboutPage.store.path; wrapMode: Text.WrapAnywhere }
        SettingsButton { theme: aboutPage.theme; text: "Open folder"; onClicked: Qt.openUrlExternally("file://" + aboutPage.store.path.slice(0,aboutPage.store.path.lastIndexOf("/"))) }
        SettingField { theme: aboutPage.theme; store: aboutPage.store; path: "trigger.tapZone"; label: "Open by tapping the corner"; hint: "Warning: the tap zone can intercept clicks intended for windows in the corner."; kind: "bool" }
    }
    SettingsCard {
        theme: aboutPage.theme; title: "Reset"
        HelpText { theme: aboutPage.theme; text: aboutPage.confirmingReset ? "Replace all settings with defaults? You can undo for 10 seconds after saving." : "Restore the original corner, controls and behavior." }
        SettingsButton { visible: !aboutPage.confirmingReset; theme: aboutPage.theme; text: "Reset everything to defaults"; onClicked: aboutPage.confirmingReset = true }
        RowLayout {
            visible: aboutPage.confirmingReset
            SettingsButton { theme: aboutPage.theme; text: "Reset everything"; onClicked: { if (aboutPage.store.reset()) aboutPage.confirmingReset = false } }
            SettingsButton { theme: aboutPage.theme; text: "Cancel"; onClicked: aboutPage.confirmingReset = false }
        }
    }
}
