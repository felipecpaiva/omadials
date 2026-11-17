import QtQuick
import Quickshell.Bluetooth
import "../../core"
import "map.js" as Map
ControlBase {
    id: backend
    property var adapter: Bluetooth.defaultAdapter
    kind: "toggle"
    value: adapter ? adapter.enabled : null
    availability: adapter ? "available" : "unavailable"
    reason: adapter ? "" : "No Bluetooth adapter"
    detailKind: "rows"
    detailRows: Map.rows(adapter ? adapter.devices.values : [])
    function set(v) {
        if (!adapter || typeof v !== "boolean" || writeState === "pending") return
        writeState = "pending"
        if (!runner.run(controlId, ["omarchy-bluetooth-power", v ? "on" : "off"], 10000, (out, code, error) => {
            writeState = code || value !== v ? "failed" : "idle"
            lastError = code ? error || "Bluetooth power failed" : value !== v ? "Bluetooth did not confirm requested power" : ""
            changed(lastError)
        })) { writeState = "failed"; lastError = "Bluetooth is busy" }
    }
    signal fullWindowRequested()
    function activate(key) {
        if (key === "switchPower" || key === "tap") { set(!value); return }
        if (key === "fullWindow") { fullWindowRequested(); return }
        const device = adapter ? adapter.devices.values.find(d => d.address === key) : null
        if (device) { if (device.connected) device.disconnect(); else device.connect() }
    }
}
