import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "../logic/Geometry.js" as Geometry
import "../logic/Labels.js" as Labels
ColumnLayout {
    id: page
    required property var store
    required property var registry
    required property var theme
    required property bool toggles
    readonly property var capacity: Geometry.capacity(store.config.size,Math.min(Screen.width,Screen.height))
    readonly property var entries: toggles ? store.config.toggles : store.config.dials.concat(store.config.readoutRings).slice().sort(function(a,b) { return a.order-b.order })
    readonly property var orderedControls: {
        let ids=entries.map(function(e) { return e.id });
        let available=registry.controls.filter(function(c) { return page.toggles ? c.placements.indexOf("arc")>=0 : c.kind!=="readout" && c.defaultPlacement==="ring" || ids.indexOf(c.id)>=0 });
        return available.sort(function(a,b) { let ai=ids.indexOf(a.id),bi=ids.indexOf(b.id); return (ai<0?999:ai)-(bi<0?999:bi) });
    }
    readonly property int count: entries.filter(function(e) { return page.store.config.controls[e.id]?.shown }).length
    spacing: 16
    Label {
        Layout.fillWidth: true; wrapMode: Text.WordWrap; color: page.theme.secondary
        text: page.toggles ? qsTr("%1 visible without scrolling at this size").arg(Math.min(page.count,page.capacity.toggles))
            : qsTr("%1 of %2 rings fit at %3").arg(page.count).arg(page.capacity.rings).arg(Labels.label(page.store.config.size))
    }
    SettingsCard {
        visible: !page.toggles
        theme: page.theme; title: qsTr("All rings")
        Label { text: qsTr("The common style for rings without custom choices."); color: page.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RingStyle { theme: page.theme; store: page.store; path: "ringStyle"; compact: true }
    }
    SettingsCard {
        theme: page.theme; title: page.toggles ? qsTr("Toggle controls") : qsTr("Ring controls")
        Repeater {
            model: page.orderedControls
            ControlRow {
                required property var modelData
                Layout.fillWidth: true
                control: modelData; store: page.store; registry: page.registry; theme: page.theme
                forcedGroup: page.toggles ? "toggles" : ""
                onDropRequested: function(id) {
                    let from=page.entries.findIndex(function(e) { return e.id===id });
                    let to=page.entries.findIndex(function(e) { return e.id===controlKey });
                    if(from<0||to<0) return;
                    let row=pageRow(id);
                    if(row) row.move(to-from);
                }
                function pageRow(id) {
                    for(let i=0;i<parent.children.length;i++) if(parent.children[i].controlKey===id) return parent.children[i];
                    return null;
                }
            }
        }
    }
    SettingsCard {
        visible: !page.toggles
        theme: page.theme; title: qsTr("Add a display ring")
        ReadoutSourceRow { theme: page.theme; store: page.store; control: ({}); entryPath: "readoutRings." + page.store.config.readoutRings.length; adding: true }
    }
}
