pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../logic/Geometry.js" as Geometry
import "../logic/Labels.js" as Labels
// Rings or Toggles as an edit list: "In the corner" in corner order, then "Not in the corner".
ColumnLayout {
    id: page
    required property var store
    required property var registry
    required property var theme
    required property bool toggles
    property string editingId: ""
    // The row showing up and down buttons (long press, or the last moved); kept by id because a move rebuilds rows.
    property string movingId: ""
    signal editRequested(string id)
    readonly property var capacity: Geometry.capacity(store.config.size,Math.min(Screen.width,Screen.height))
    readonly property var entries: toggles ? store.config.toggles : store.config.dials.concat(store.config.readoutRings).slice().sort(function(a,b) { return a.order - b.order })
    readonly property var ids: entries.map(function(e) { return e.id })
    readonly property var controls: registry.controls.filter(function(c) {
        return page.toggles ? c.placements.indexOf("arc") >= 0 : c.kind !== "readout" && c.defaultPlacement === "ring" || page.ids.indexOf(c.id) >= 0;
    })
    function shown(id) { return page.store.config.controls[id]?.shown === true }
    function byId(id) { return page.controls.find(function(c) { return c.id === id }) }
    // Rows are keyed by id strings, so a status refresh (new control objects every second) does not rebuild them.
    readonly property string inCornerKey: ids.filter(function(id) { return page.shown(id) && page.byId(id) }).join(",")
    readonly property string notInCornerKey: controls.map(function(c) { return c.id }).filter(function(id) { return page.inCorner.indexOf(id) < 0 })
        .sort(function(a,b) { let ai=page.ids.indexOf(a),bi=page.ids.indexOf(b); return (ai < 0 ? 999 : ai) - (bi < 0 ? 999 : bi) }).join(",")
    readonly property var inCorner: inCornerKey ? inCornerKey.split(",") : []
    readonly property var notInCorner: notInCornerKey ? notInCornerKey.split(",") : []
    readonly property bool full: !toggles && inCorner.length >= capacity.rings
    readonly property var sourceIds: ["laptopBattery","wifiSignal","bluetoothBattery","penBattery"]
    readonly property var sourceNames: [qsTr("Laptop battery"),qsTr("Wi-Fi signal"),qsTr("Bluetooth device battery"),qsTr("Pen battery")]
    function rowFor(id) {
        for (let i = 0; i < cornerList.children.length; i++) if (cornerList.children[i].controlKey === id) return cornerList.children[i];
        return null;
    }
    function move(id, delta) {
        let at = inCorner.indexOf(id), to = at + delta;
        if (at < 0 || to < 0 || to >= inCorner.length) return;
        let focused = rowFor(id).activeFocus;
        movingId = id;
        rowFor(id).controlModel.moveTo(inCorner[to]);
        if (focused) Qt.callLater(function() { let row = page.rowFor(id); if (row) row.focusHandle() });
    }
    spacing: 16
    SettingsCard {
        visible: !page.toggles
        theme: page.theme; title: qsTr("All rings")
        Label { text: qsTr("The common style for every ring that does not have its own."); color: page.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RingStyle { theme: page.theme; store: page.store; path: "ringStyle"; compact: true }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("In the corner")
        Label {
            objectName: "capacityLine"
            Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.theme.secondary; font.pixelSize: 12
            text: (page.toggles ? qsTr("%1 visible without scrolling at this size").arg(Math.min(page.inCorner.length,page.capacity.toggles))
                : qsTr("%1 of %2 rings fit at %3").arg(page.inCorner.length).arg(page.capacity.rings).arg(Labels.label(page.capacity.size)))
                + qsTr(". Drag the handle to change the order.")
        }
        ColumnLayout {
            id: cornerList; Layout.fillWidth: true; spacing: 4
            Repeater {
                model: page.inCorner
                ControlRow {
                    required property string modelData
                    control: page.byId(modelData); store: page.store; registry: page.registry; theme: page.theme
                    forcedGroup: page.toggles ? "toggles" : ""
                    editing: page.editingId === controlKey
                    moving: page.movingId === controlKey
                    onMoveModeToggled: function(id) { page.movingId = page.movingId === id ? "" : id }
                    onEditRequested: function(id) { page.editRequested(id) }
                    onRemoved: function(id) { if (page.editingId === id) page.editRequested("") }
                    onMoveRequested: function(id, delta) { page.move(id, delta) }
                    onDropRequested: function(fromId, toId) { let row = page.rowFor(fromId); if (row) row.controlModel.moveTo(toId) }
                }
            }
        }
        Label { visible: !page.inCorner.length; text: qsTr("Nothing here yet. Add one below."); color: page.theme.secondary }
    }
    SettingsCard {
        theme: page.theme; title: qsTr("Not in the corner")
        Label {
            objectName: "fullLine"
            visible: page.full; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.theme.warn
            text: qsTr("The corner is full. Remove one first, or choose a larger size.")
        }
        Repeater {
            model: page.notInCorner
            ControlRow {
                required property string modelData
                control: page.byId(modelData); store: page.store; registry: page.registry; theme: page.theme
                forcedGroup: page.toggles ? "toggles" : ""; inCorner: false; addEnabled: !page.full
            }
        }
        Label { visible: !page.toggles; text: qsTr("New display ring"); font.bold: true; Layout.topMargin: 8 }
        Repeater {
            model: page.toggles ? [] : page.sourceIds
            DisplayRingRow {
                required property int index
                required property string modelData
                store: page.store; theme: page.theme; source: modelData; name: page.sourceNames[index]; addEnabled: !page.full
            }
        }
        Label { visible: page.toggles && !page.notInCorner.length; text: qsTr("Every toggle is in the corner."); color: page.theme.secondary }
    }
}
