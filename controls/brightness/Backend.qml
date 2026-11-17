import QtQuick
import "../../core"
import "spec.js" as Spec
CommandControl {
    id: backend
    spec: Spec
    detailKind: "custom"
    property url detailComponent: Qt.resolvedUrl("../../views/details/DisplaysDetail.qml")
    // Built from its path: control folders load on demand, so Quickshell never registers their sibling types.
    property var displays: Qt.createComponent(Qt.resolvedUrl("DisplaySession.qml")).createObject(backend, { runner: backend.runner, jobPrefix: backend.controlId + ":displays" })
    range: ({min: 0, max: 100, floor: 1, step: 1, unit: "%"})
    function refresh() {
        const monitor = options.monitor || "auto"
        if (monitor !== "auto" && !/^(eDP-|LVDS-|DSI-)/.test(monitor)) {
            dispatch({type: "READ", availability: "unavailable", value: null,
                reason: "External DDC read argv is not specified in controls.md"})
            return
        }
        if (writeState !== "pending") sysFile.reload()   // sysfs read, see spec.sysfs
    }
    valueText: value === null ? "unknown" : value + "%"
}
