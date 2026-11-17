pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
// The Edit sheet for one control: icon, then ring style and wheel step, or the toggle gestures.
Rectangle {
    id: editSheet
    required property var theme
    required property var store
    required property var registry
    required property string controlId
    required property bool toggle
    signal closeRequested
    readonly property var control: (registry.controls || []).find(c => (c.controlId || c.id) === controlId) || null
    readonly property string group: toggle ? "toggles" : control && control.kind === "readout" ? "readoutRings" : "dials"
    readonly property int entryIndex: store.config[group].findIndex(e => e.id === editSheet.controlId)
    readonly property var catalogEntry: (registry.catalog || []).find(c => c.id === editSheet.controlId) || ({})
    color: theme.surface
    border.color: theme.edge
    radius: 8
    // Keeps clicks between the sheet's controls from reaching the page underneath.
    MouseArea { anchors.fill: parent }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "Edit " + (editSheet.control ? editSheet.control.label : ""); elide: Text.ElideRight; color: editSheet.theme.text; font.family: editSheet.theme.font; font.bold: true }
            SettingsButton { theme: editSheet.theme; text: "Done"; onClicked: editSheet.closeRequested() }
        }
        Flickable {
            id: sheetScroll
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; contentWidth: width; contentHeight: sheetBody.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: sheetBody
                width: sheetScroll.width; spacing: 12
                IconGrid {
                    theme: editSheet.theme; store: editSheet.store
                    path: "controls." + editSheet.controlId + ".icon"; fallback: editSheet.control ? editSheet.control.icon : ""
                }
                Loader {
                    Layout.fillWidth: true
                    active: !!editSheet.control && editSheet.entryIndex >= 0
                    sourceComponent: ControlOptions {
                        theme: editSheet.theme; store: editSheet.store; control: editSheet.control
                        entryPath: editSheet.group + "." + editSheet.entryIndex; group: editSheet.group; catalogEntry: editSheet.catalogEntry
                    }
                }
            }
        }
    }
}
