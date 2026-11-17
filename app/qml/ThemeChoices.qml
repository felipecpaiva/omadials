import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: pair
    required property var store
    required property var theme
    Layout.fillWidth: true
    Repeater {
        model: ["light","dark"]
        RowLayout {
            id: choice
            required property string modelData
            readonly property var names: pair.store.validationResources.themes || []
            readonly property string suggested: pair.store.validationResources[modelData + "Theme"] || ""
            readonly property string selected: pair.store.config.themePair[modelData] || suggested
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label { text: choice.modelData === "light" ? qsTr("Light theme") : qsTr("Dark theme") }
                Label { text: qsTr("Used when you switch themes from the corner."); color: pair.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            }
            ComboBox {
                Layout.preferredWidth: 190; model: choice.names
                currentIndex: choice.names.indexOf(choice.selected)
                displayText: choice.selected || qsTr("No installed themes")
                Accessible.name: choice.modelData === "light" ? qsTr("Light theme") : qsTr("Dark theme")
                onActivated: {
                    let changes=[{path:"themePair."+choice.modelData,value:choice.names[currentIndex]}];
                    let other=choice.modelData === "light" ? "dark" : "light";
                    if(!pair.store.config.themePair[other] && pair.store.validationResources[other+"Theme"]) changes.push({path:"themePair."+other,value:pair.store.validationResources[other+"Theme"]});
                    pair.store.setMany(changes);
                }
            }
        }
    }
    Label { visible: !(pair.store.validationResources.themes || []).length; text: qsTr("Install a light and a dark Omarchy theme to use this toggle."); color: pair.theme.secondary; Layout.fillWidth: true; wrapMode: Text.WordWrap }
}
