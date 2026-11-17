import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "spec.js" as Spec
CommandControl {
    id: backend
    spec: Spec
    property FileView stateWatch: FileView {
        path: backend.active ? Quickshell.env("HOME") + "/.local/state/omarchy/indicators/stay-awake" : ""
        watchChanges: backend.active
        printErrors: false
        onFileChanged: { reload(); backend.refresh() }
    }
}
