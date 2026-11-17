import QtQuick
import "../logic/Labels.js" as Labels
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: page
    required property var store
    required property var theme
    required property var registry
    property bool confirming: false
    spacing: 16
    Label { text: qsTr("omadials settings 0.7.0"); font.pixelSize: 18 }
    Label { text: qsTr("Quick settings in a screen corner. Adjust your rings and toggles without leaving your work."); Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.theme.secondary }
    SettingsButton { theme: page.theme; text: qsTr("Read the README"); onClicked: backend.openReadme() }
    SettingsCard {
        theme: page.theme; title: qsTr("Plugin status")
        SettingsButton { theme: page.theme; text: qsTr("Refresh plugin status"); onClicked: backend.refreshStatus() }
        Label { visible: backend.status.charAt(0)!=="{"; text: backend.status; color: page.theme.secondary; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText }
        Repeater {
            model: page.registry.controls
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Label { text: modelData.label; Layout.preferredWidth: 140; wrapMode: Text.WordWrap }
                Label {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.PlainText; color: page.theme.secondary
                    text: Labels.statusText(modelData)
                }
            }
        }
        SettingsButton { theme: page.theme; text: qsTr("Copy details"); onClicked: backend.copyDetails() }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Advanced")
        Label { text: qsTr("Settings file"); font.bold: true }
        Label { text: page.store.path; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText; color: page.theme.secondary }
        SettingsButton { theme: page.theme; text: qsTr("Open folder"); onClicked: backend.openFolder() }
        SettingField { store: page.store; theme: page.theme; path: "trigger.tapZone"; label: qsTr("Corner works when the tab is hidden"); help: qsTr("For \"Show the tab: Never\". On: the corner still opens from the screen corner, and it can catch clicks meant for a window."); kind: "bool" }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Reset")
        Label { text: qsTr("Replace every setting with its default. Undo is available for 10 seconds."); color: page.theme.secondary; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        SettingsButton { theme: page.theme; text: qsTr("Reset everything to defaults"); onClicked: page.confirming=true }
        ColumnLayout {
            visible: page.confirming
            Label { text: qsTr("Reset everything, including unrecognized settings?"); Layout.fillWidth: true; wrapMode: Text.WordWrap }
            RowLayout {
                SettingsButton { theme: page.theme; text: qsTr("Reset everything"); onClicked: { page.store.reset(); page.confirming=false } }
                SettingsButton { theme: page.theme; text: qsTr("Cancel"); onClicked: page.confirming=false }
            }
        }
    }
}
