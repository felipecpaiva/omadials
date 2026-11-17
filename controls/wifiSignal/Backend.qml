import QtQuick
import Quickshell.Networking
import "../../core"
import "map.js" as Map
ControlBase {
    property var device: Networking.devices.values.filter(d => d.type === DeviceType.Wifi && (!parameter.interface || parameter.interface === "auto" || d.name === parameter.interface)).flatMap(d => d.networks.values).find(n => n.connected) || null
    kind: "readout"
    availability: "available"
    connected: device !== null
    value: Map.reading(connected, device ? device.signalStrength : null, false)
    valueText: Map.text(connected, value)
    detailKind: "rows"
    detailRows: [{key: "source", label: label, sub: valueText, state: connected, icon: icon}]
}
