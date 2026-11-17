import QtQuick
import Quickshell.Io
import "../logic/CommandMachine.js" as Machine

ControlBase {
    id: commandControl
    required property var spec
    property var machine: Object.assign(Machine.initial(null), {availability: "probing"})
    // A spec with sysfs(options) is read from a watched file: no process per read, no polling, live while closed.
    readonly property var sys: spec.sysfs ? spec.sysfs(options) : null
    property int pollInterval: !sys && spec.watch === "poll" ? (spec.interval || 4000) : 0
    property string sysMaxText: ""
    property FileView sysMaxFile: FileView { path: commandControl.sys && commandControl.sys.max ? commandControl.sys.max : ""; printErrors: false
        onLoaded: { commandControl.sysMaxText = text(); commandControl.sysFile.reload() } }
    property FileView sysFile: FileView { path: commandControl.sys ? commandControl.sys.path : ""; printErrors: false; watchChanges: true
        onFileChanged: reload()
        onLoaded: if (commandControl.writeState !== "pending" && (!commandControl.sys.max || commandControl.sysMaxText))
            commandControl.dispatch(Object.assign({type: "READ"}, commandControl.spec.fromSys(text(), commandControl.sysMaxText, commandControl.options)))
        onLoadFailed: commandControl.dispatch({type: "READ", availability: "unavailable", value: null, reason: "Cannot read " + commandControl.sys.path}) }
    value: machine.value
    availability: machine.availability
    writeState: machine.writeState
    lastError: machine.lastError
    reason: machine.lastError
    property Timer poll: Timer {
        interval: Math.max(1, commandControl.pollInterval)
        running: commandControl.active && commandControl.pollInterval > 0
        repeat: true
        onTriggered: commandControl.refresh()
    }
    property Timer reread: Timer {
        property int generation: 0
        interval: Machine.READ_DELAY
        onTriggered: commandControl.dispatch({type: "REREAD", argv: commandControl.spec.read(commandControl.options), generation: generation})
    }
    function dispatch(event) {
        const next = Machine.reduce(machine, event)
        machine = next.state
        changed(lastError)
        next.effects.forEach(effect => {
            if (effect.run) execute(effect.run, effect.phase, effect.generation)
            else if (effect.type === "REREAD") {
                reread.generation = effect.generation
                reread.restart()
            }
        })
    }
    function execute(argv, phase, generation) {
        const accepted = runner.run(controlId, argv, spec.timeout || 10000, (out, code, error) => {
            if (phase === "write") dispatch({type: "WRITTEN", code: code, reason: error, generation: generation})
            else {
                const parsed = spec.parse(out, code)
                if (parsed.range) range = parsed.range
                if (parsed.steps) steps = parsed.steps
                dispatch(Object.assign({type: "READ", generation: generation}, parsed))
            }
        })
        if (!accepted && phase === "write") dispatch({type: "FAIL", reason: "Control is busy", generation: generation})
    }
    function refresh() {
        if (sys) { if (writeState !== "pending") sysFile.reload(); return }
        if (writeState !== "pending") execute(machine.availability === "probing" ? spec.probe(options) : spec.read(options), "read", machine.generation)
    }
    function set(v) {
        if (writeState === "pending" || availability !== "available" || v === value) return
        const argv = spec.write(v, options)
        if (argv) dispatch({type: "SET", value: spec.normalize ? spec.normalize(v, options) : v, argv: argv})
    }
}
