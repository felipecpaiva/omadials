import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
ApplicationWindow {
    id: win
    width: 1200; height: 850; minimumWidth: 720; minimumHeight: 540
    visible: true; title: qsTr("omadials settings"); color: uiTheme.background
    Material.theme: Material.Dark
    Material.accent: desktopTheme.accent
    Material.roundedScale: desktopTheme.radius
    AppTheme { id: uiTheme }
    readonly property bool narrow: width < 1060
    // The control in the Edit sheet, by id: pages and rows are rebuilt, the edited control is not.
    property string editingId: ""
    readonly property bool editing: editingId !== "" && configStore.config.controls[editingId]?.shown === true
        && controlRegistry.controls.some(function(c) { return (c.controlId || c.id) === win.editingId })
    function openEditor(id, toggle) { pages.currentIndex = toggle ? 2 : 1; editingId = id }
    ConfigStore { id: configStore; objectName: "configStore"; io: backend }
    QtObject {
        id: controlRegistry
        property var catalog: configStore.catalog
        property var statusControls: []
        property var controls: {
            let list = catalog.map(function(c) {
                let status = statusControls.find(function(s) { return (s.controlId || s.id) === c.id }) || {};
                return Object.assign({},c,status,{availability:status.availability || "unknown",reason:status.reason || "Refresh plugin status"});
            });
            configStore.config.readoutRings.forEach(function(r) {
                let status = statusControls.find(function(s) { return s.id === r.id }) || {};
                if (!list.some(function(c) { return c.id === r.id })) list.push(Object.assign({id:r.id,label:"Display ring",kind:"readout",placements:["ring"],availability:"unknown",reason:"Refresh plugin status"},status));
            });
            return list;
        }
    }
    Connections { target: backend; function onStatusReceived(data) { controlRegistry.statusControls = data.controls || [] } }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: backend.refreshStatus() }
    Shortcut { sequence: "Ctrl+Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }
    Shortcut { sequences: [StandardKey.Undo]; context: Qt.ApplicationShortcut; onActivated: configStore.undo() }
    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; onActivated: help.open() }
    Dialog {
        id: help; title: qsTr("Keyboard shortcuts"); anchors.centerIn: parent; modal: true
        standardButtons: Dialog.Ok
        Label { text: qsTr("Ctrl+Q: Quit\nCtrl+Z: Undo for 10 seconds\n?: Show shortcuts\nTab: Move between fields"); textFormat: Text.PlainText }
    }
    RowLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 20
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true
        ColumnLayout {
            Layout.preferredWidth: 150; Layout.fillWidth: false; Layout.fillHeight: true; spacing: 8
            Label { text: qsTr("omadials"); font.pixelSize: 22; font.bold: true; Layout.bottomMargin: 20 }
            Repeater {
                model: [qsTr("Corner"),qsTr("Rings"),qsTr("Toggles"),qsTr("Behavior"),qsTr("About")]
                Button {
                    required property int index; required property string modelData
                    Layout.fillWidth: true; text: modelData
                    highlighted: pages.currentIndex === index
                    contentItem: Label { text: parent.text; color: parent.highlighted ? uiTheme.ink : uiTheme.text; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; leftPadding: 14 }
                    background: Rectangle { color: parent.highlighted ? uiTheme.accent : uiTheme.clear; radius: uiTheme.radius }
                    onClicked: { win.editingId = ""; pages.currentIndex = index }
                }
            }
            Item { Layout.fillHeight: true }
            Label { text: qsTr("Saved as you go"); color: uiTheme.secondary; font.pixelSize: 12 }
            Button { text: qsTr("Show the corner"); Layout.fillWidth: true; onClicked: backend.showOnScreen() }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            GridLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                columns: win.narrow ? 1 : 2; columnSpacing: 20; rowSpacing: 14
                Pane {
                    Layout.row: 0; Layout.column: win.narrow ? 0 : 1
                    Layout.fillWidth: win.narrow; Layout.preferredWidth: win.editing ? 440 : Math.max(280,liveDrawing.implicitWidth+24)
                    Layout.alignment: Qt.AlignTop
                    padding: 12
                    background: Rectangle { color: uiTheme.surface; radius: uiTheme.radius }
                    CornerPreview {
                        id: liveDrawing; registry: controlRegistry; objectName: "livePreview"; width: parent.width; store: configStore; theme: uiTheme
                        editingId: win.editing ? win.editingId : ""; compact: win.editing
                        onEditRequested: function(id, toggle) { win.openEditor(id, toggle) }
                    }
                }
                Loader {
                    id: sheetLoader; objectName: "sheetLoader"
                    active: win.editing; visible: active
                    Layout.row: 1; Layout.column: win.narrow ? 0 : 1
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 440
                    sourceComponent: EditSheet {
                        store: configStore; registry: controlRegistry; theme: uiTheme; controlId: win.editingId; showProblems: win.narrow
                        onCloseRequested: win.editingId = ""
                    }
                }
                ScrollView {
                    id: scroll; objectName: "scroll"
                    Layout.row: win.narrow ? 1 : 0; Layout.column: 0; Layout.rowSpan: win.narrow ? 1 : 2
                    visible: !(win.narrow && win.editing)
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true; contentWidth: availableWidth
                    ColumnLayout {
                        width: scroll.availableWidth; spacing: 16
                        Label { text: [qsTr("Corner"),qsTr("Rings"),qsTr("Toggles"),qsTr("Behavior"),qsTr("About")][pages.currentIndex]; font.pixelSize: 26; font.bold: true }
                        ProblemsBanner { store: configStore; registry: controlRegistry; theme: uiTheme; page: pages.currentIndex }
                        Loader {
                            id: pages; objectName: "pages"; Layout.fillWidth: true
                            property int currentIndex: 0
                            sourceComponent: [cornerPage,ringsPage,togglesPage,behaviorPage,aboutPage][currentIndex]
                            onCurrentIndexChanged: if (scroll.contentItem) scroll.contentItem.contentY = 0
                        }
                    }
                }
            }
            UndoBar { store: configStore; theme: uiTheme }
        }
    }
    Component { id: cornerPage; CornerPage { store: configStore; theme: uiTheme } }
    Component { id: ringsPage; ControlsPage { store: configStore; registry: controlRegistry; theme: uiTheme; toggles: false; editingId: win.editingId; onEditRequested: function(id) { win.editingId = id } } }
    Component { id: togglesPage; ControlsPage { store: configStore; registry: controlRegistry; theme: uiTheme; toggles: true; editingId: win.editingId; onEditRequested: function(id) { win.editingId = id } } }
    Component { id: behaviorPage; BehaviorPage { store: configStore; theme: uiTheme } }
    Component { id: aboutPage; AboutPage { store: configStore; theme: uiTheme; registry: controlRegistry } }
    Component.onCompleted: backend.refreshStatus()
}
