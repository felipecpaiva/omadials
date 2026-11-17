import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
// A display ring kind in "Not in the corner". Laptop battery and Wi-Fi signal are added at once; a Bluetooth
// device or pen first needs its device, so Add shows the source picker.
ColumnLayout {
    id: row
    required property var store
    required property var theme
    required property string source
    required property string name
    property bool addEnabled: true
    property bool picking: false
    Layout.fillWidth: true
    function add(fields) {
        let entry = Object.assign({}, fields, {id:"display" + Date.now()});
        entry.order = store.config.dials.concat(store.config.readoutRings).reduce(function(n,e) { return Math.max(n,e.order + 1) },0);
        let list = [];
        try { list = JSON.parse(store.rawText).readoutRings || []; } catch (e) { list = store.config.readoutRings; }
        if (store.setMany([{path:"readoutRings",value:list.concat([entry])},{path:"controls." + entry.id,value:{shown:true,icon:"default"}}])) picking = false;
    }
    RowLayout {
        Layout.fillWidth: true; Layout.preferredHeight: 60; Layout.leftMargin: 4; Layout.rightMargin: 4; spacing: 6
        ControlIcon { theme: row.theme; store: row.store; name: row.source; Layout.leftMargin: 8 }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Label { Layout.fillWidth: true; text: row.name; elide: Text.ElideRight; font.pixelSize: 15 }
            Label { Layout.fillWidth: true; text: qsTr("Display ring, shows a value without changing it"); color: row.theme.secondary; font.pixelSize: 12; elide: Text.ElideRight }
        }
        CircleButton {
            theme: row.theme; kind: "add"; enabled: row.addEnabled && !row.picking
            text: qsTr("Add a new display ring for %1").arg(row.name)
            onClicked: {
                if (row.source === "laptopBattery") row.add({source:"laptopBattery",style:{knob:"none"}});
                else if (row.source === "wifiSignal") row.add({source:"wifiSignal",interface:"auto",style:{knob:"none"}});
                else row.picking = true;
            }
        }
    }
    Loader {
        active: row.picking; visible: active; Layout.fillWidth: true; Layout.leftMargin: 48
        sourceComponent: ColumnLayout {
            ReadoutSourceRow {
                theme: row.theme; store: row.store; control: ({}); entryPath: ""; adding: true; source: row.source
                onAddRequested: function(fields) { row.add(fields) }
            }
            Button { text: qsTr("Cancel"); onClicked: row.picking = false }
        }
    }
}
