import QtQuick
import Quickshell.Bluetooth
import "../../core"
import "map.js" as Map
ControlBase {
    property var device: Bluetooth.devices.values.find(d => d.address.toUpperCase() === (parameter.deviceAddress || "").toUpperCase()) || null
    kind: "readout"
    availability: "available"
    connected: device !== null && device.connected
    value: Map.reading(connected, device ? device.battery : null, !device || !device.batteryAvailable)
    valueText: Map.text(connected, value)
    detailKind: "rows"
    detailRows: [{key: "source", label: label, sub: valueText, state: connected, icon: icon}]
}
