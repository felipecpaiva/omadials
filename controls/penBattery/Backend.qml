import QtQuick
import Quickshell.Services.UPower
import "../../core"
import "map.js" as Map
ControlBase {
    id: backend
    property string sourceNativePath: ""
    property string observed: JSON.stringify(UPower.devices.values.map(d => [d.nativePath, d.percentage, d.state, d.isPresent]))
    onObservedChanged: if (active) refresh()
    onParameterChanged: { sourceNativePath = ""; if (active) refresh() }
    function refresh() {
        const selected = parameter.devicePath
        if (typeof selected !== "string" || !selected.startsWith("/org/freedesktop/UPower/devices/")) return
        runner.run(controlId, ["upower", "-i", selected], 10000, (out, code, error) => {
            if (parameter.devicePath !== selected) return
            sourceNativePath = Map.nativePath(out, code) || ""
            lastError = code ? error || "Cannot resolve selected UPower device" : ""
        })
    }
    property var device: UPower.devices.values.find(d => !d.isLaptopBattery && !!sourceNativePath && d.nativePath === sourceNativePath) || null
    kind: "readout"
    availability: "available"
    connected: device !== null && device.ready && device.isPresent
    value: Map.reading(connected, device ? device.percentage : null, !device || device.state === UPowerDeviceState.Unknown)
    valueText: Map.text(connected, value)
    detailKind: "rows"
    detailRows: [{key: "source", label: label, sub: valueText, state: connected, icon: icon}]
}
