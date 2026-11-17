import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "spec.js" as Spec
CommandControl {
    id: backend
    spec: Spec
    kind: "toggle"
    property string currentTheme: machine.value || ""
    value: false
    valueText: currentTheme || "unknown"
    detailKind: "custom"
    property url detailComponent: Qt.resolvedUrl("../../views/details/ThemeDetail.qml")
    property FileView themeWatch: FileView {
        path: backend.active ? Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name" : ""
        watchChanges: backend.active
        printErrors: false
        onFileChanged: { reload(); backend.refresh() }
    }
    function refresh() {
        if (writeState !== "pending") execute(Spec.read(options), "read", machine.generation)
        runner.run(controlId + ":themes", ["omarchy-theme-list"], 10000, (out, code, error) => {
            if (code) { lastError = error || "Cannot list themes"; return }
            detailRows = out.trim().split("\n").filter(n => n.trim()).map(n => ({key: n, label: n, sub: "", state: n === currentTheme, icon: ""}))
        })
    }
    function choose(name) {
        if (writeState === "pending" || name === currentTheme) return
        if (detailRows.some(r => r.key === name)) dispatch({type: "SET", value: name, argv: Spec.write(name, options)})
        else { lastError = "Configured theme is not installed"; changed(lastError) }
    }
    // No light and dark pair: omadials follows whatever Omarchy theme is active. A tap opens the installed theme list.
    function set(v) { }
    function activate(key) { if (key !== "quickDetail" && key !== "tap") choose(key) }
}
