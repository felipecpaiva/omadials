import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: row
    required property var theme
    required property var store
    required property var control
    required property string entryPath
    property bool adding: false
    signal addRequested(var fields)
    readonly property var entry: store.value(entryPath) || ({})
    property string source: entry.source || "laptopBattery"
    property int deviceIndex: 0
    readonly property var devices: (store.validationResources.devices || []).filter(function(d) { return d.source === row.source })
    readonly property var sources: ["bluetoothBattery","wifiSignal","laptopBattery","penBattery"]
    readonly property var names: [qsTr("Bluetooth device battery"),qsTr("Wi-Fi signal"),qsTr("Laptop battery"),qsTr("Pen battery")]
    Component.onCompleted: { store.io.refreshDevices(); store.validationResources=store.io.resources(store.rawText) }
    Layout.fillWidth: true
    Label { text: qsTr("Source") }
    Label { text: qsTr("Display rings show a value without changing it."); color: row.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    ComboBox { model: row.names; currentIndex: row.sources.indexOf(row.source); Accessible.name: qsTr("Display ring source"); onActivated: { row.source=row.sources[currentIndex]; row.deviceIndex=0 } }
    ComboBox {
        visible: row.source !== "laptopBattery"
        Layout.fillWidth: true; model: row.devices; textRole: "name"
        currentIndex: row.deviceIndex; Accessible.name: qsTr("Device")
        onActivated: row.deviceIndex=currentIndex
    }
    Label {
        visible: row.source !== "laptopBattery" && !row.devices.length
        text: qsTr("No devices found. Connect a device, then refresh."); color: row.theme.secondary; wrapMode: Text.WordWrap; Layout.fillWidth: true
    }
    Button { visible: row.source !== "laptopBattery"; text: qsTr("Refresh devices"); onClicked: { row.store.io.refreshDevices(); row.store.validationResources=row.store.io.resources(row.store.rawText) } }
    Button {
        text: row.adding ? qsTr("Add display ring") : qsTr("Apply source and device")
        enabled: row.source === "laptopBattery" || row.devices.length > 0
        onClicked: {
            let next=JSON.parse(JSON.stringify(row.entry));
            next.source=row.source; next.style=Object.assign({},next.style || {},{knob:"none"});
            delete next.deviceAddress; delete next.devicePath; delete next.interface;
            if(row.source!=="laptopBattery") next[({bluetoothBattery:"deviceAddress",penBattery:"devicePath",wifiSignal:"interface"})[row.source]]=row.devices[row.deviceIndex].key;
            if(row.adding) row.addRequested(next); else row.store.set(row.entryPath,next);
        }
    }
}
