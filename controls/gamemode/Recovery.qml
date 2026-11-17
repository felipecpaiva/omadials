import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "map.js" as Map

// A detached, single-instance supervisor. It exists only while a journal exists.
ShellRoot {
    id: recovery
    property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omadials"
    property var saved: null
    property bool initialized: false
    property bool restoring: false
    property bool failed: false
    CommandRunner { id: commands }
    IpcHandler {
        target: "recovery"
        function ready(): string { return recovery.initialized && !recovery.failed ? "ready" : "checking" }
    }
    FileView {
        id: journal
        path: recovery.stateDir + "/game-restore.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                recovery.saved = JSON.parse(text())
                if (!Map.validJournal(recovery.saved)) throw new Error("Invalid recovery journal")
                recovery.initialized = true
                if (recovery.saved.instance !== Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) recovery.discard()
                else owner.reload()
            } catch (error) { recovery.fail(String(error)) }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) { if (!recovery.restoring) Qt.quit() }
            else recovery.fail("Cannot load game journal")
        }
    }
    FileView {
        id: owner
        path: recovery.saved ? "/proc/" + recovery.saved.ownerPid + "/stat" : ""
        printErrors: false
        onLoaded: {
            try { if (Map.processStart(text()) !== recovery.saved.ownerStart) recovery.restore() }
            catch (error) { recovery.fail(String(error)) }
        }
        onLoadFailed: error => {
            if (!recovery.initialized) return
            if (error === FileViewError.FileNotFound) recovery.restore()
            else recovery.fail("Cannot check game owner process")
        }
    }
    Timer {
        interval: 1000; repeat: true
        running: recovery.initialized && !recovery.restoring && !recovery.failed
        onTriggered: owner.reload()
    }
    function fail(message) {
        failed = true
        console.error("Game recovery: " + message + "; journal retained")
    }
    function run(argv, done) {
        if (!commands.run("recover", argv, 10000, (out, code, error) => {
            if (code) fail(error || "Recovery command failed")
            else done(out)
        })) fail("Recovery command is busy")
    }
    function discard() {
        // The old compositor's runtime overrides died with it.
        restoring = true
        run(["rm", "--", journal.path], () => run(["rmdir", stateDir + "/game-restore.lock"], () => Qt.quit()))
    }
    function readOptions(index, result) {
        if (index === Map.OPTIONS.length) {
            if (!Map.equal(result, saved.baseline)) { fail("Baseline read-back failed"); return }
            discard(); return
        }
        const option = Map.OPTIONS[index]
        run(["hyprctl", "-j", "getoption", option.read], out => {
            try { result[option.key] = Map.parse(out, option); readOptions(index + 1, result) }
            catch (error) { fail(String(error)) }
        })
    }
    function restore() {
        if (!initialized || restoring || failed || !saved) return
        restoring = true
        // The writer holds this session lock for the complete journal lifetime.
        // Take ownership only after its process identity has disappeared.
        run(["hyprctl", "eval", Map.lua(saved.baseline)], () => readOptions(0, {}))
    }
}
