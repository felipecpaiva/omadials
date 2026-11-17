import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
ApplicationWindow {
    id: win
    width: 900; height: 800; minimumWidth: 700; minimumHeight: 500
    visible: true; title: qsTr("omadials Settings"); color: "#0e0e10"
    Material.theme: Material.Dark
    Material.accent: desktopTheme.accent
    Material.roundedScale: desktopTheme.radius
    QtObject {
        id: uiTheme
        property string accent: desktopTheme.accent
        property string ink: desktopTheme.accentForeground
        property int radius: desktopTheme.radius
        property string surface: "#171719"
        property string text: "#eeeeee"
        property string secondary: "#bbbbbb"
        property string warn: "#ffb86c"
        property string off: "#252528"
        property string edge: "#555558"
        property string track: "#454548"
        property string font: "sans-serif"
    }
    ConfigStore { id: configStore; objectName: "configStore"; io: backend }
    QtObject {
        id: controlRegistry
        property var catalog: configStore.catalog
        property var statusControls: []
        property var controls: {
            let list = catalog.map(function(c) {
                let status = statusControls.find(function(s) { return (s.controlId || s.id) === c.id }) || {};
                return Object.assign({},c,{availability:status.availability || "unknown",reason:status.reason || "Check plugin status"});
            });
            configStore.config.readoutRings.forEach(function(r) {
                if (!list.some(function(c) { return c.id === r.id })) list.push({id:r.id,label:r.id,kind:"readout",placements:["ring"],availability:"unknown",reason:"Readout instance"});
            });
            return list;
        }
    }
    Connections { target: backend; function onStatusReceived(data) { controlRegistry.statusControls = data.controls || [] } }
    Shortcut { sequence: "Ctrl+Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }
    Shortcut { sequences: [StandardKey.Undo]; context: Qt.ApplicationShortcut; onActivated: configStore.undo() }
    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; onActivated: help.open() }
    Dialog {
        id: help; title: qsTr("Keyboard shortcuts"); anchors.centerIn: parent; modal: true
        standardButtons: Dialog.Ok
        Label { text: qsTr("Ctrl+Q: Quit\nCtrl+Z: Undo for 10 seconds\n?: Show shortcuts\nTab: Move between fields"); textFormat: Text.PlainText }
    }
    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 12
            RowLayout {
                Repeater {
                    model: [qsTr("Corner"),qsTr("Controls"),qsTr("Behavior"),qsTr("About")]
                    Button { required property int index; required property string modelData; text: modelData; highlighted: pages.currentIndex === index; onClicked: pages.currentIndex = index }
                }
                Item { Layout.fillWidth: true }
                Button { text: qsTr("Show on screen"); onClicked: backend.showOnScreen() }
            }
            Label { Layout.fillWidth: true; text: qsTr("Changes apply immediately. Invalid fields are reported and preserved."); wrapMode: Text.WordWrap; textFormat: Text.PlainText }
            Label { visible: configStore.readOnly; text: qsTr("Config is read only. Fix the file or Reset all in About."); color: uiTheme.warn; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Label { visible: backend.error.length > 0; text: backend.error; color: uiTheme.warn; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true; textFormat: Text.PlainText }
            ScrollView {
                id: scroll; objectName: "scroll"; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; contentWidth: availableWidth
                ColumnLayout {
                    width: scroll.availableWidth; spacing: 12
                    ProblemsBanner { store: configStore; registry: controlRegistry; theme: uiTheme }
                    Loader {
                        id: pages; objectName: "pages"; Layout.fillWidth: true
                        property int currentIndex: 0
                        sourceComponent: [cornerPage,controlsPage,behaviorPage,aboutPage][currentIndex]
                        onCurrentIndexChanged: if (scroll.contentItem) scroll.contentItem.contentY = 0
                    }
                }
            }
            UndoBar { store: configStore; theme: uiTheme }
        }
    }
    Component { id: cornerPage; CornerPage { store: configStore; theme: uiTheme } }
    Component { id: controlsPage; ControlsPage { store: configStore; registry: controlRegistry; theme: uiTheme } }
    Component { id: behaviorPage; BehaviorPage { store: configStore; theme: uiTheme } }
    Component {
        id: aboutPage
        ColumnLayout {
            AboutPage { store: configStore; theme: uiTheme }
            Button { text: qsTr("Refresh plugin status"); onClicked: backend.refreshStatus() }
            Label { Layout.fillWidth: true; text: backend.status; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere }
        }
    }
    Component.onCompleted: backend.refreshStatus()
}
