import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../core"
import "map.js" as Map

// Game mode: runtime Hyprland writes only (spike S8), never config files or a reload. Before writing it saves the values
// it read to a small journal, and turning off restores exactly those and checks them. The journal survives a shell
// restart, so game mode can still be turned off; a Hyprland reload drops runtime values, so the journal then clears itself.
ControlBase {
    id: backend
    readonly property string instance: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    readonly property string journalPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omadials/game-mode.json"
    property var saved: null      // {version, instance, baseline, intended} while game mode is on
    availability: instance ? "available" : "unavailable"
    reason: instance ? "" : "Not running under Hyprland"
    value: false

    property FileView journal: FileView {
        path: backend.journalPath
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text())
                backend.saved = j.version === 1 && j.instance === backend.instance ? j : null
            } catch (e) { backend.saved = null }
            backend.refresh()
        }
        onLoadFailed: { backend.saved = null; backend.refresh() }
        onSaveFailed: backend.fail("Cannot save the game mode journal")
    }
    property Connections events: Connections {
        target: backend.active || backend.saved ? Hyprland : null
        function onRawEvent(event) { if (event.name === "configreloaded") backend.refresh() }
    }

    function fail(message) { lastError = message; writeState = "failed"; changed(message) }
    function run(argv, done) {
        if (!runner.run(controlId, argv, 10000, (out, code, error) => { if (code) fail(error || "Hyprland refused the game mode change"); else done(out) }))
            fail("Game mode is busy")
    }
    function readOptions(done, index, result) {
        const i = index || 0, data = result || {}
        if (i === Map.OPTIONS.length) { done(data); return }
        const option = Map.OPTIONS[i]
        run(["hyprctl", "-j", "getoption", option.read], out => {
            try { data[option.key] = Map.parse(out, option); readOptions(done, i + 1, data) }
            catch (e) { fail(String(e)) }
        })
    }
    function clearJournal() { run(["rm", "-f", "--", journalPath], () => { saved = null; value = false; writeState = "idle" }) }
    function refresh() {
        if (writeState === "pending" || !instance) return
        readOptions(current => {
            value = !!saved && Map.equal(current, saved.intended)
            if (saved && !value) clearJournal()   // a reload or a manual change already put things back
        })
    }
    function set(v) {
        if (typeof v !== "boolean" || writeState === "pending" || !instance) return
        lastError = ""
        if (!v) {
            if (!saved) { value = false; return }
            writeState = "pending"
            run(["hyprctl", "eval", Map.lua(saved.baseline)], () => readOptions(current => {
                if (!Map.equal(current, saved.baseline)) { fail("Game mode restore did not verify"); return }
                clearJournal()
            }))
            return
        }
        writeState = "pending"
        readOptions(baseline => {
            let intended
            try { intended = Map.intended(configuration.gameMode || {}, baseline) } catch (e) { fail(String(e)); return }
            const data = { version: 1, instance: instance, baseline: baseline, intended: intended }
            run(["mkdir", "-p", journalPath.replace(/\/[^/]*$/, "")], () => {
                saved = data
                journal.setText(JSON.stringify(data))
                run(["hyprctl", "eval", Map.lua(intended)], () => readOptions(current => {
                    if (!Map.equal(current, intended)) { set(false); fail("Game mode did not apply"); return }
                    value = true; writeState = "idle"; changed("on")
                }))
            })
        })
    }
}
