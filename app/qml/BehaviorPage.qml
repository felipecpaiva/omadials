import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: page
    required property var store
    required property var theme
    spacing: 16
    SettingsCard {
        theme: page.theme; title: qsTr("Closing")
        SettingField { store: page.store; theme: page.theme; path: "behavior.idleTimeoutS"; label: qsTr("Close after"); help: qsTr("Seconds without activity before the corner closes."); kind: "choice"; choices: [0,5,10,20,30]; words: [qsTr("Never"),qsTr("5 s"),qsTr("10 s"),qsTr("20 s"),qsTr("30 s")] }
        SettingField { store: page.store; theme: page.theme; path: "behavior.closeOnPointerLeave"; label: qsTr("Close when the pointer leaves"); help: qsTr("Close the corner when you move back to your work."); kind: "bool" }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Dials")
        SettingField { store: page.store; theme: page.theme; path: "dialInteraction.fineEnabled"; label: qsTr("Fine control when you drag away from the ring"); help: qsTr("Move outward to make smaller changes."); kind: "bool" }
        SettingField { store: page.store; theme: page.theme; path: "dialInteraction.snap"; label: qsTr("Snap to 0, 25, 50, 75 and 100 %"); help: qsTr("Pause near these values to land on them."); kind: "bool" }
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: qsTr("Volume can go above 100 %"); wrapMode: Text.WordWrap; Layout.fillWidth: true }
                Label { text: qsTr("Allow a maximum of 150 %. Loud audio may distort."); color: page.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
            Switch { checked: page.store.config.options.volume.maxPercent>100; Accessible.name: qsTr("Volume can go above 100 %"); onClicked: page.store.set("options.volume.maxPercent",checked?150:100) }
        }
        Label { text: qsTr("Maximum: %1 %").arg(page.store.config.options.volume.maxPercent); color: page.theme.secondary; font.pixelSize: 12 }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Theme toggle")
        ThemeChoices { store: page.store; theme: page.theme }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Game mode")
        Label { text: qsTr("When game mode is on, turn off:"); wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Repeater {
            model: [{key:"animations",label:qsTr("Animations")},{key:"blur",label:qsTr("Blur")},{key:"shadows",label:qsTr("Shadows")}]
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: modelData.label }
                    Label { text: qsTr("Restore the previous setting when game mode ends."); color: page.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
                Switch { checked: page.store.config.gameMode[modelData.key] === false; Accessible.name: modelData.label; onClicked: page.store.set("gameMode."+modelData.key,!checked) }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: qsTr("Window gaps become 0") }
                Label { text: qsTr("Remove the space between windows during game mode."); color: page.theme.secondary; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            Switch {
                checked: page.store.config.gameMode.gapsIn===0 && page.store.config.gameMode.gapsOut===0
                Accessible.name: qsTr("Window gaps become 0")
                onClicked: page.store.setMany([{path:"gameMode.gapsIn",value:checked?0:5},{path:"gameMode.gapsOut",value:checked?0:10}])
            }
        }
    }
}
