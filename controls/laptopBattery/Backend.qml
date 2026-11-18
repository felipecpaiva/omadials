import QtQuick
import Quickshell.Services.UPower
import "../../core"
import "map.js" as Map
ControlBase {
    property var device: UPower.displayDevice
    kind: "readout"
    availability: "available"
    connected: device !== null && device.ready && device.isPresent
    value: Map.reading(connected, device ? device.percentage : null, !device || device.state === UPowerDeviceState.Unknown)
    valueText: Map.text(connected, value)
    readonly property bool charging: !!device && (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.FullyCharged)
    detailKind: "rows"
    detailRows: [{key: "source", label: label, sub: valueText, state: connected, icon: icon}]
}
