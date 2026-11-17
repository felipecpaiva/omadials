import QtQuick

QtObject {
    id: controlBase
    property string controlId: ""
    property string kind: "toggle"
    property var placements: []
    property string availability: "probing"
    property string reason: ""
    property var value: null
    property var range: ({min: 0, max: 100, floor: 0, step: 1, unit: "%"})
    property var steps: []
    property string writeState: "idle"
    property string lastError: ""
    property string label: ""
    property string icon: ""
    property string valueText: value === null ? "unknown" : typeof value === "boolean" ? (value ? "On" : "Off") : String(value)
    property string detailKind: "none"
    property var detailRows: []
    property bool connected: false
    property var parameter: ({})
    property var options: ({})
    property var configuration: ({})
    required property var runner
    property bool active: false
    signal changed(string reason)
    function set(v) { }
    function refresh() { }
    function activate(rowKey) {
        if (["switch", "switchRadio", "switchPower", "tap"].indexOf(rowKey) >= 0) set(!value)
        else if (rowKey === "nextStep") set((Number(value) + 1) % (steps.length || 4))
    }
    Component.onDestruction: if (runner) {
        runner.cancel(controlId)
        runner.cancel(controlId + ":events")
        runner.cancel(controlId + ":themes")
        runner.cancel(controlId + ":profiles")
    }
    onActiveChanged: if (active) refresh()
}
