import QtQuick
import Quickshell.Services.UPower
import "../../core"
import "spec.js" as Spec
CommandControl {
    id: backend
    spec: Spec
    kind: "picker"
    detailKind: "rows"
    steps: detailRows.map(r => ({key: r.key, label: r.label}))
    readonly property var names: ({ "balanced": "Balanced", "performance": "Performance", "power-saver": "Power saver" })
    valueText: value === null ? "unknown" : (names[value] || String(value))
    property Connections profileEvents: Connections {
        target: backend.active ? PowerProfiles : null
        function onProfileChanged() { backend.refresh() }
    }
    function refresh() {
        if (writeState !== "pending") execute(Spec.read(options), "read", machine.generation)
        runner.run(controlId + ":profiles", ["omarchy-powerprofiles-list"], 10000, (out, code, error) => {
            if (code) { lastError = error || "Cannot list power profiles"; return }
            const names = out.trim().split(/\s+/).filter(n => ["balanced", "performance", "power-saver"].indexOf(n) >= 0)
            detailRows = names.map(n => ({key: n, label: n, sub: "", state: n === value, icon: ""}))
        })
    }
    function activate(key) { if (detailRows.some(r => r.key === key)) set(key) }
}
