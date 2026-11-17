import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "spec.js" as Spec
ControlBase {
    id: backend
    property bool confirmation: false
    property bool stateKnown: false
    readonly property bool guarded: controlId === "touchscreen"
    detailKind: "rows"
    detailRows: confirmation ? [{key:"confirmOff", label:"Confirm touchscreen off (restores in 15 seconds)", sub:"", state:false, icon:""}] : []
    property FileView disabledState: FileView {
        path: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/hypr/" + backend.controlId + "-disabled-name"
        watchChanges: backend.active
        blockLoading: true
        printErrors: false
        onLoaded: { backend.stateKnown = true; backend.value = false }
        onLoadFailed: error => {
            backend.stateKnown = error === FileViewError.FileNotFound
            backend.value = backend.stateKnown ? true : null
            if (!backend.stateKnown) backend.fail("Cannot read input state")
        }
        onFileChanged: reload()
    }
    property Timer revert: Timer {
        interval: Spec.revertMs
        onTriggered: backend.apply(true)
    }
    function fail(message) { lastError = message; reason = message; writeState = "failed"; changed(message) }
    function refresh() {
        if (writeState === "pending") return
        runner.run(controlId, Spec.read(), 10000, (out, code) => {
            const parsed = Spec.parse(out, code)
            availability = parsed.availability; reason = parsed.reason
            if (availability === "available") { disabledState.reload(); disabledState.text() }
            else value = null
        })
    }
    function apply(v) {
        writeState = "pending"
        if (!runner.run(controlId, Spec.write(v), 10000, (out, code, error) => {
            if (code) fail(error || "Input command failed")
            else { writeState = "idle"; lastError = "" }
            refresh()
        })) fail("Input control is busy")
    }
    function set(v) {
        if (typeof v !== "boolean" || v === value || !stateKnown || availability !== "available" || writeState === "pending") return
        if (guarded && !v) { confirmation = true; changed("Open detail to confirm touchscreen off"); return }
        apply(v)
    }
    function activate(key) {
        if (key === "confirmOff" && confirmation && active && writeState !== "pending") {
            confirmation = false
            // Recheck after confirmation, immediately before the disable command.
            writeState = "pending"
            if (!runner.run(controlId, ["hyprctl", "devices", "-j"], 10000, (out, code) => {
                writeState = "idle"
                if (!active || !Spec.usableInput(out, code)) { fail("Cannot disable touchscreen without a verified usable keyboard or pointer"); return }
                // No input-source identity is exposed by ControlBase. Always revert; a touch cannot keep it off.
                revert.restart()
                apply(false)
            })) fail("Input check is busy")
        } else if (key === "switch" || key === "tap") set(!value)
    }
    onActiveChanged: { confirmation = false; if (active) refresh() }
    Component.onDestruction: if (revert.running) runner.run(controlId + ":restore", Spec.write(true), 10000, () => {})
}
