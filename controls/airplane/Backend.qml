import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "spec.js" as Spec
ControlBase {
    id: backend
    property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omadials"
    property var radios: []
    property var afterSave: null
    property bool journalReady: false
    property bool journalExists: false
    property var restoreData: null
    property FileView journal: FileView {
        path: backend.stateDir + "/airplane-restore.json"
        atomicWrites: true
        printErrors: false
        onSaved: { const next = backend.afterSave; backend.afterSave = null; if (next) next() }
        onSaveFailed: { backend.afterSave = null; backend.fail("Cannot save airplane restore journal") }
        onLoaded: {
            backend.journalReady = true; backend.journalExists = true
            try { backend.restoreData = JSON.parse(text()) }
            catch (error) { backend.fail("Invalid airplane restore journal") }
        }
        onLoadFailed: error => {
            backend.journalReady = true
            if (error !== FileViewError.FileNotFound) backend.fail("Cannot read airplane restore journal")
        }
    }
    function fail(message) { lastError = message; reason = message; writeState = "failed"; changed(message) }
    function refresh() {
        if (writeState === "pending") return
        runner.run(controlId, ["rfkill", "-J"], 10000, (out, code) => {
            const p = Spec.parse(out, code)
            availability = p.availability; reason = p.reason; value = p.value; radios = p.radios || []
        })
    }
    function sequence(commands, done) {
        if (!commands.length) { done(); return }
        const argv = commands[0]
        if (!runner.run(controlId, argv, 10000, (out, code, error) => {
            if (code) { fail(error || "Radio command failed; restore journal retained"); refresh() }
            else sequence(commands.slice(1), done)
        })) fail("Radio command is busy")
    }
    function set(v) {
        if (typeof v !== "boolean" || v === value || writeState === "pending" || !journalReady || availability !== "available") return
        if (v) {
            if (journalExists) { fail("Restore the previous airplane session first"); return }
            writeState = "pending"
            // Get the baseline again immediately before persisting it.
            runner.run(controlId + ":baseline", ["rfkill", "-J"], 10000, (out, code) => {
                const baseline = Spec.parse(out, code)
                if (baseline.availability !== "available") { fail(baseline.reason); return }
                restoreData = {version: 1, radios: baseline.radios}
                sequence([["mkdir", "-p", stateDir]], () => {
                    afterSave = () => {
                        journalExists = true
                        sequence([["rfkill", "block", "all"]], () => {
                            runner.run(controlId, ["rfkill", "-J"], 10000, (out, code) => {
                                const p = Spec.parse(out, code)
                                value = p.value
                                if (p.availability !== "available" || !p.value) fail("Airplane mode did not verify; journal retained")
                                else writeState = "idle"
                            })
                        })
                    }
                    journal.setText(JSON.stringify(restoreData))
                })
            })
        } else {
            if (!Spec.journalValid(restoreData)) { fail("No valid saved radio set; refusing to unblock all radios"); return }
            writeState = "pending"
            sequence(Spec.restore(restoreData.radios), () => {
                runner.run(controlId, ["rfkill", "-J"], 10000, (out, code) => {
                    const p = Spec.parse(out, code)
                    const ok = p.radios && restoreData.radios.every(r => p.radios.some(n => n.id === r.id && n.soft === r.soft))
                    if (!ok) { fail("Radio restore did not verify; journal retained"); return }
                    sequence([["rm", "--", journal.path]], () => { journalExists = false; restoreData = null; writeState = "idle"; refresh() })
                })
            })
        }
    }
    function startEvents() {
        if (active) runner.run(controlId + ":events", ["rfkill", "event"], 35000, () => { if (active) startEvents() }, () => refresh())
    }
    onActiveChanged: { if (active) { refresh(); startEvents() } else runner.cancel(controlId + ":events") }
}
