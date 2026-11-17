import QtQuick
import Quickshell.Io
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
        if (writeState !== "pending") execute(Spec.read(options), "read", machine.generation)
    }
    valueText: value === null ? "unknown" : value + "%"
    // Live while closed, with no process: the internal panel's sysfs file reports every write (checked on the Z13),
    // so the closed corner tab can show the real level. Reads with brightnessctl still run while open.
    readonly property string sysDir: "/sys/class/backlight/" + (options.device || "amdgpu_bl1")
    property real sysMax: 0
    property FileView sysMaxFile: FileView { path: backend.sysDir + "/max_brightness"; printErrors: false
        onLoaded: { backend.sysMax = Number(text().trim()) || 0; backend.sysLevel.reload() } }
    property FileView sysLevel: FileView { path: backend.sysDir + "/brightness"; printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const raw = Number(text().trim())
            if (backend.sysMax > 0 && Number.isFinite(raw) && !backend.active && backend.writeState !== "pending")
                backend.dispatch({type: "READ", availability: "available", value: Math.max(1, Math.round(raw / backend.sysMax * 100)), reason: ""})
        }
    }
}
