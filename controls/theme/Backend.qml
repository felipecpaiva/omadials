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
    value: currentTheme === (configuration.themePair || {}).dark
    valueText: currentTheme || "unknown"
    detailKind: "rows"
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
    function set(v) {
        const pair = configuration.themePair || {}
        choose(currentTheme === pair.dark ? pair.light : pair.dark)
    }
    function activate(key) { if (key === "togglePair" || key === "tap") set(true); else choose(key) }
}
