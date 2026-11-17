import QtQuick
import "../../core"
import "spec.js" as Spec
CommandControl {
    id: backend
    spec: Spec
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
}
