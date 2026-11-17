import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../logic/Geometry.js" as Geometry
ColumnLayout {
    id: page
    required property var store
    required property var theme
    property bool choosingIcon: store.config.cornerIcon.source !== "default"
    spacing: 16
    SettingsCard {
        theme: page.theme; title: qsTr("Where")
        Label { text: qsTr("Corner"); color: page.theme.text }
        Label { text: qsTr("Pick the corner that feels easiest to reach."); color: page.theme.secondary; font.pixelSize: 12 }
        PictureChoices { store: page.store; theme: page.theme; path: "corner"; values: ["top-left","top-right","bottom-left","bottom-right"]; drawing: "corner" }
        SettingField { store: page.store; theme: page.theme; path: "outputs.mode"; label: qsTr("Screens"); help: qsTr("Choose where the corner is available."); kind: "choice"; choices: ["all","focused","named"]; words: [qsTr("All screens"),qsTr("Focused screen"),qsTr("Choose screens")] }
        Repeater {
            model: page.store.config.outputs.mode === "named" ? page.store.validationResources.screens || [] : []
            CheckBox {
                required property string modelData
                text: modelData; checked: page.store.config.outputs.names.indexOf(modelData) >= 0
                onClicked: {
                    let names=page.store.config.outputs.names.slice();
                    if(checked) names.push(modelData); else names=names.filter(function(n) { return n!==modelData });
                    page.store.set("outputs.names",names);
                }
            }
        }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Size")
        PictureChoices { store: page.store; theme: page.theme; path: "size"; drawing: "size"; values: ["S","M","L"]; descriptions: [qsTr("Room for two rings"),qsTr("Room for three rings"),qsTr("Room for four rings")] }
        Label {
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.theme.secondary; font.pixelSize: 12
            property var cap: Geometry.capacity(page.store.config.size,Math.min(Screen.width,Screen.height))
            text: cap.capped ? qsTr("%1 is limited to %2 px on this screen").arg(({S:qsTr("Compact"),M:qsTr("Normal"),L:qsTr("Large")})[page.store.config.size]).arg(Math.round(cap.R)) : qsTr("Hide a ring before choosing a smaller size.")
        }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Corner tab")
        Label { text: qsTr("Style"); color: page.theme.text }
        Label { text: qsTr("Choose a small hint for the closed corner."); color: page.theme.secondary; font.pixelSize: 12 }
        RowLayout {
            Layout.fillWidth: true
            PictureChoices { store: page.store; theme: page.theme; path: "tabStyle"; values: ["rings2knob","rings3","rings3knob"]; onChosen: { page.store.set("cornerIcon.source","default"); page.choosingIcon=false } }
            Button { text: qsTr("✦\nYour own icon"); Layout.preferredWidth: 100; implicitHeight: 98; onClicked: page.choosingIcon=true; highlighted: page.choosingIcon }
        }
        IconPicker { visible: page.choosingIcon; store: page.store; theme: page.theme; path: "cornerIcon.source"; controlId: "settings"; label: qsTr("Your own icon") }
        SettingField { store: page.store; theme: page.theme; path: "cornerIcon.mode"; label: qsTr("Show the tab"); help: qsTr("The corner can still open when the tab is hidden."); kind: "choice"; choices: ["always","onApproach","never"]; words: [qsTr("Always"),qsTr("When the pointer is near"),qsTr("Never")] }
        SettingField { store: page.store; theme: page.theme; path: "cornerIcon.aboveWindows"; label: qsTr("Above windows"); help: qsTr("Off: the tab hides behind windows; the corner still opens"); kind: "bool" }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Opening")
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Label { Layout.fillWidth: true; text: qsTr("Open when the pointer rests in the corner"); wrapMode: Text.WordWrap }
                Label { Layout.fillWidth: true; text: qsTr("Off: open the corner with a tap or a drag."); wrapMode: Text.WordWrap; color: page.theme.secondary; font.pixelSize: 12 }
            }
            Switch { checked: page.store.config.trigger.push !== false; Accessible.name: qsTr("Open when the pointer rests in the corner"); onClicked: page.store.set("trigger.push",checked) }
        }
        RowLayout {
            visible: page.store.config.trigger.push !== false
            Label { text: qsTr("Delay"); Layout.fillWidth: true }
            Slider { from: 0; to: 500; stepSize: 10; value: page.store.config.trigger.pushDelayMs; Accessible.name: qsTr("Opening delay"); onMoved: page.store.set("trigger.pushDelayMs",Math.round(value)) }
            Label { text: qsTr("%1 ms").arg(page.store.config.trigger.pushDelayMs); Layout.preferredWidth: 55 }
        }
    }
}
