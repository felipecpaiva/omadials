import QtQuick
import Quickshell.Networking
import "../../core"
import "map.js" as Map

ControlBase {
    id: backend
    property var devices: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)
    kind: "toggle"
    value: Networking.wifiEnabled
    availability: devices.length ? "available" : "unavailable"
    reason: devices.length ? "" : "No Wi-Fi device"
    detailKind: "rows"
    detailRows: Map.rows(devices.map(d => ({name: d.name, networks: d.networks.values})), WifiSecurityType.Open)
    function run(argv) {
        if (writeState === "pending") return
        writeState = "pending"
        if (!runner.run(controlId, argv, 30000, (out, code, error) => {
            writeState = code ? "failed" : "idle"
            lastError = code ? error || "Wi-Fi command failed" : ""
            changed(lastError)
        })) { writeState = "failed"; lastError = "Wi-Fi is busy" }
    }
    function set(v) { if (typeof v === "boolean") run(["nmcli", "radio", "wifi", v ? "on" : "off"]) }
    function activate(key) {
        if (key === "switchRadio" || key === "tap") { set(!value); return }
        if (key === "fullWindow") { fullWindowRequested(); return }
        const row = detailRows.find(r => r.key === key)
        if (!row) return
        const action = Map.action(row)
        if (action === "fullWindow") { fullWindowRequested(); return }
        if (action === "saved") run(["nmcli", "con", "up", row.label])
        else devices.forEach(d => d.networks.values.forEach(n => {
            if (d.name + "/" + n.name === key) n.connect()
        }))
    }
    onActiveChanged: {
        devices.forEach(d => { d.scannerEnabled = active })
        if (active) refresh()
    }
    signal fullWindowRequested()
}
