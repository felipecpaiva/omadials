import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../core"
import "map.js" as Map
ControlBase {
    id: backend
    property string instance: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omadials"
    property var afterSave: null
    property var saved: null
    property bool ready: false
    property bool recoverySupervised: false
    property bool waitingRecovery: false
    property string ownerStart: ""
    property bool rollingBack: false
    property var supervisorDone: null
    property int supervisorAttempts: 0
    property Timer supervisorRetry: Timer {
        interval: Map.SUPERVISOR_RETRY_MS
        onTriggered: backend.checkSupervisor()
    }
    property FileView ownerIdentity: FileView {
        path: "/proc/" + Quickshell.processId + "/stat"
        onLoaded: backend.ownerStart = Map.processStart(text())
        onLoadFailed: backend.fail("Cannot identify the shell process")
    }
    availability: ready && !!instance && !!ownerStart ? "available" : "error"
    reason: lastError || (!ready ? "Checking game recovery" : !instance || !ownerStart ? "Unknown compositor or shell instance" : "")
    value: false
    property FileView journal: FileView {
        path: backend.stateDir + "/game-restore.json"
        atomicWrites: true; printErrors: false
        watchChanges: backend.waitingRecovery
        onFileChanged: reload()
        onSaved: { const next = backend.afterSave; backend.afterSave = null; if (next) next() }
        onSaveFailed: { backend.afterSave = null; backend.fail("Cannot save game restore journal") }
        onLoaded: {
            try {
                backend.saved = JSON.parse(text())
                if (!Map.validJournal(backend.saved)) throw new Error("Invalid game restore journal")
                if (!backend.instance) throw new Error("Unknown compositor instance")
                if (backend.saved.ownerPid === Quickshell.processId && backend.saved.ownerStart === backend.ownerStart && backend.saved.instance === backend.instance) backend.restore()
                else { backend.waitingRecovery = true; backend.supervise(() => {}) }
            } catch (error) { backend.fail(String(error)) }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                backend.saved = null; backend.waitingRecovery = false; backend.supervisorRetry.stop()
                backend.ready = true; backend.value = false
            }
            else backend.fail("Cannot read game restore journal")
        }
    }
    property Connections events: Connections {
        target: backend.active || backend.saved ? Hyprland : null
        function onRawEvent(event) { if (event.name === "configreloaded") backend.refresh() }
    }
    function fail(message) { lastError = message; writeState = "failed"; ready = false; changed(message) }
    function helperPath() { return decodeURIComponent(Qt.resolvedUrl("Recovery.qml").toString().replace(/^file:\/\//, "")) }
    function supervise(done) {
        supervisorDone = done; supervisorAttempts = 0
        command(["qs", "-d", "-n", "-p", helperPath()], () => checkSupervisor())
    }
    function checkSupervisor() {
        if (!saved) return
        runner.run(controlId, ["qs", "ipc", "-p", helperPath(), "call", "recovery", "ready"], 10000, (out, code) => {
            if (!code && out.trim() === "ready") {
                recoverySupervised = true
                const next = supervisorDone; supervisorDone = null
                if (next) next()
            } else if (++supervisorAttempts < Map.SUPERVISOR_ATTEMPTS) supervisorRetry.restart()
            else if (!waitingRecovery && saved) { lastError = "Recovery supervisor did not become ready"; restore() }
            else fail("Recovery supervisor did not become ready")
        })
    }
    function command(argv, done) {
        if (!runner.run(controlId, argv, 10000, (out, code, error) => {
            if (code) {
                if (saved && saved.ownerPid === Quickshell.processId && !rollingBack && !waitingRecovery) restore()
                else fail(error || "Game runtime command failed; journal retained")
            }
            else done(out)
        })) fail("Game runtime command is busy")
    }
    function readOptions(done, index, result) {
        const i = index || 0, data = result || {}
        if (i === Map.OPTIONS.length) { done(data); return }
        const option = Map.OPTIONS[i]
        command(["hyprctl", "-j", "getoption", option.read], out => {
            try { data[option.key] = Map.parse(out, option); readOptions(done, i + 1, data) }
            catch (error) {
                if (saved && !rollingBack && !waitingRecovery) restore()
                else fail(String(error))
            }
        })
    }
    function removeJournal() {
        command(["rm", "--", journal.path], () => command(["rmdir", stateDir + "/game-restore.lock"], () => {
            saved = null; ready = true; value = false; writeState = "idle"; rollingBack = false
        }))
    }
    function restore() {
        if (!saved || !Map.validJournal(saved) || saved.instance !== instance) { fail("Cannot restore unknown game session"); return }
        writeState = "pending"; rollingBack = true
        command(["hyprctl", "eval", Map.lua(saved.baseline)], () => readOptions(current => {
            if (!Map.equal(current, saved.baseline)) { fail("Game baseline restore did not verify"); return }
            removeJournal()
        }))
    }
    function refresh() {
        if (writeState === "pending" || waitingRecovery || !ready) return
        readOptions(current => {
            value = !!saved && Map.equal(current, saved.intended)
            if (saved && !value && Map.equal(current, saved.baseline)) removeJournal()
        })
    }
    function set(v) {
        if (typeof v !== "boolean" || !ready || writeState === "pending") return
        if (!v) { if (saved) restore(); return }
        if (saved || !instance || !ownerStart) return
        writeState = "pending"
        readOptions(baseline => {
            const data = {version: 1, instance: instance, ownerPid: Quickshell.processId,
                ownerStart: ownerStart, baseline: baseline, intended: Map.intended(configuration.gameMode || {})}
            command(["mkdir", "-p", stateDir], () => command(["mkdir", stateDir + "/game-restore.lock"], () => {
                afterSave = () => {
                    saved = data
                    supervise(() => command(["hyprctl", "eval", Map.lua(data.intended)], () => readOptions(current => {
                        if (!Map.equal(current, data.intended)) { restore(); return }
                        value = true; writeState = "idle"
                    })))
                }
                journal.setText(JSON.stringify(data))
            }))
        })
    }
}
