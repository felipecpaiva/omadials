import QtQuick
import "displays.js" as Displays

QtObject {
    id: displays
    required property var runner
    property string jobPrefix: "displays"
    property var monitors: []
    property var levels: ({})
    property string error: ""
    property var rollback: null
    property string phase: "idle"
    property int remaining: 0
    property double deadline: 0
    readonly property var focused: monitors.find(m => m.focused) || null
    property Timer countdown: Timer {
        interval: 100; repeat: true; running: displays.phase === "confirm"
        onTriggered: {
            displays.remaining = Math.max(0,Math.ceil((displays.deadline-Date.now())/1000))
            if (!displays.remaining) displays.revert()
        }
    }
    function refresh() {
        runner.run(jobPrefix+":list", ["hyprctl","-j","monitors","all"], Displays.COMMAND_TIMEOUT, (out, code, err) => {
            if (code) { error = err || "Cannot read displays"; return }
            monitors = Displays.parse(out)
            monitors.forEach(m => readBrightness(m))
        })
    }
    function readBrightness(m) {
        const internal = /^(eDP-|LVDS-|DSI-)/.test(m.name)
        const argv = internal ? ["brightnessctl","-m"] : ["omarchy-brightness-display-ddc",m.name]
        runner.run(jobPrefix+":read:"+m.name, argv, 10000, (out, code) => {
            const next = Object.assign({},levels)
            next[m.name] = code ? null : Displays.brightness(out,internal)
            levels = next
        })
    }
    function setBrightness(m, value) {
        if (!Number.isFinite(value) || levels[m.name] === null || levels[m.name] === undefined) return
        const percent = Math.round(Math.max(1,Math.min(100,value)))
        runner.run(jobPrefix+":brightness:"+m.name, ["omarchy-brightness-display","--no-osd","--monitor",m.name,percent+"%"], 10000, (out, code, err) => {
            error = code ? err || "Brightness failed" : ""
            readBrightness(m)
        })
    }
    function choose(mode) {
        if (phase !== "idle" || !focused) return
        phase = "reading"
        const name = focused.name
        // Snapshot immediately before the write, not from a stale detail list.
        const accepted = runner.run(jobPrefix+":snapshot", ["hyprctl","-j","monitors"], Displays.COMMAND_TIMEOUT, (out, code, err) => {
            const m = Displays.parse(out).find(item => item.name === name && item.focused)
            const argv = !code && m ? Displays.argv(m,mode) : null
            if (!argv) { phase = "idle"; error = err || "Display changed; reopen detail"; return }
            rollback = Displays.argv(m,Displays.currentMode(m))
            phase = "applying"
            const started = runner.run(jobPrefix+":mode", argv, Displays.COMMAND_TIMEOUT, (text, status, failure) => {
                if (status || !/^ok\s*$/i.test(text.trim())) { error = failure || text || "Refresh change failed"; revert(); return }
                deadline = Date.now()+Displays.CONFIRM_SECONDS*1000
                remaining = Displays.CONFIRM_SECONDS; phase = "confirm"
            })
            if (!started) { rollback = null; phase = "idle"; error = "Display command busy" }
        })
        if (!accepted) { phase = "idle"; error = "Display read busy" }
    }
    function confirm() { if (phase === "confirm") { rollback = null; phase = "idle"; refresh() } }
    function revert() {
        if (!rollback || phase === "reverting") return
        phase = "reverting"
        const accepted = runner.run(jobPrefix+":revert", rollback, Displays.COMMAND_TIMEOUT, (out, code, err) => {
            if (code || !/^ok\s*$/i.test(out.trim())) { error = err || out || "Revert failed; retry"; phase = "revertFailed" }
            else { rollback = null; phase = "idle"; refresh() }
        })
        if (!accepted) { phase = "revertFailed"; error = "Revert busy; retry" }
    }
}
