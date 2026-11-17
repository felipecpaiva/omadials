import QtQuick
import "../logic/CommandMachine.js" as Machine

ControlBase {
    id: commandControl
    required property var spec
    property var machine: Object.assign(Machine.initial(null), {availability: "probing"})
    property int pollInterval: spec.watch === "poll" ? (spec.interval || 4000) : 0
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
        if (writeState !== "pending") execute(machine.availability === "probing" ? spec.probe(options) : spec.read(options), "read", machine.generation)
    }
    function set(v) {
        if (writeState === "pending" || availability !== "available" || v === value) return
        const argv = spec.write(v, options)
        if (argv) dispatch({type: "SET", value: spec.normalize ? spec.normalize(v, options) : v, argv: argv})
    }
}
