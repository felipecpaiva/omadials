import QtQuick
import Quickshell.Networking
import "../../core"
import "map.js" as Map
ControlBase {
    // Plain loops: Quickshell lists do not offer every Array method (flatMap failed on the device).
    property var device: {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; i++) {
            const d = devices[i]
            if (d.type !== DeviceType.Wifi || (parameter.interface && parameter.interface !== "auto" && d.name !== parameter.interface)) continue
            const nets = d.networks.values
            for (let j = 0; j < nets.length; j++) if (nets[j].connected) return nets[j]
        }
        return null
    }
    kind: "readout"
    availability: "available"
    connected: device !== null
    value: Map.reading(connected, device ? device.signalStrength : null, false)
    valueText: Map.text(connected, value)
    detailKind: "rows"
    detailRows: [{key: "source", label: label, sub: valueText, state: connected, icon: icon}]
}
