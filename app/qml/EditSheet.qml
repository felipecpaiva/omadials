import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// The Edit sheet for one control: its icon, then ring style and wheel step, or what tapping and holding do.
Pane {
    id: sheet
    objectName: "editSheet"
    required property var store
    required property var registry
    required property var theme
    required property string controlId
    property bool showProblems: false
    signal closeRequested()
    onControlIdChanged: options.ownStyle = false
    readonly property var control: registry.controls.find(function(c) { return (c.controlId || c.id) === sheet.controlId }) || null
    ControlModel { id: cm; control: sheet.control; store: sheet.store; registry: sheet.registry }
    padding: 16
    background: Rectangle { color: sheet.theme.surface; radius: sheet.theme.radius; border.width: 1; border.color: sheet.theme.accent }
    contentItem: ColumnLayout {
        spacing: 12
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            ControlIcon { theme: sheet.theme; store: sheet.store; name: cm.icon }
            Label { Layout.fillWidth: true; text: qsTr("Edit %1").arg(cm.name); font.bold: true; font.pixelSize: 18; elide: Text.ElideRight }
            SettingsButton { theme: sheet.theme; text: qsTr("Done"); onClicked: sheet.closeRequested() }
        }
        Loader {
            active: sheet.showProblems; visible: active; Layout.fillWidth: true
            sourceComponent: ProblemsBanner { store: sheet.store; registry: sheet.registry; theme: sheet.theme; page: cm.group === "toggles" ? 2 : 1 }
        }
        ScrollView {
            id: scroll; objectName: "sheetScroll"
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.preferredHeight: body.implicitHeight
            clip: true; contentWidth: availableWidth
            ColumnLayout {
                id: body
                width: scroll.availableWidth; spacing: 16
                IconGrid {
                    theme: sheet.theme; store: sheet.store; path: "controls." + sheet.controlId + ".icon"
                    defaultIcon: cm.group === "readoutRings" ? (cm.entry.source || "laptopBattery") : (sheet.control?.icon || sheet.controlId)
                }
                ControlOptions {
                    id: options
                    theme: sheet.theme; store: sheet.store; control: sheet.control || ({id:sheet.controlId})
                    entryPath: cm.entryPath; group: cm.group; catalogEntry: cm.catalogEntry
                }
            }
        }
    }
}
