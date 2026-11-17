import QtQuick
import "../../core"
import "spec.js" as Spec
CommandControl {
    id: backend
    spec: Spec
    kind: "stepped"
    range: ({min:20, max:100, floor:20, step:1, unit:"%"})
    steps: Array.from({length:81}, (_, i) => ({key:i + 20, label:String(i + 20) + "%"}))
    property bool writable: false
    valueText: value === null ? "unknown" : String(value) + "%" + (writable ? "" : " (read only)")
    function refresh() {
        if (writeState === "pending") return
        execute(Spec.read(), "read", machine.generation)
        runner.run(controlId + ":writer", ["which", "asusctl"], 10000, (out, code) => { writable = code === 0 && out.trim().length > 0 })
    }
    function set(v) {
        if (!writable || availability !== "available" || writeState === "pending" || v === value) return
        const native = Spec.normalize(v)
        const argv = Spec.write(native)
        if (argv) dispatch({type:"SET", value:native, argv:argv})
    }
}
