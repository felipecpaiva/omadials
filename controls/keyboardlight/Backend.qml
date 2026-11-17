import QtQuick
import "../../core"
import "spec.js" as Spec

CommandControl {
    property string detectedDevice: ""
    function refresh() {
        if (writeState === "pending") return
        runner.run(controlId, ["ls", "/sys/class/leds"], 10000, (out, code) => {
            detectedDevice = Spec.detect(out, code)
            if (!detectedDevice) { dispatch({type:"READ", availability:"unavailable", value:null, reason:"No keyboard backlight"}); return }
            execute(Spec.read(Object.assign({}, options, {device: options.device || detectedDevice})), "read", machine.generation)
        })
    }
    function execute(argv, phase, generation) {
        if (phase === "read") argv = Spec.read(Object.assign({}, options, {device: options.device || detectedDevice}))
        const accepted = runner.run(controlId, argv, Spec.timeout, (out, code, error) => {
            if (phase === "write") dispatch({type:"WRITTEN", code:code, reason:error, generation:generation})
            else {
                const parsed = Spec.parse(out, code)
                if (parsed.range) range = parsed.range
                if (parsed.steps) steps = parsed.steps
                dispatch(Object.assign({type:"READ", generation:generation}, parsed))
            }
        })
        if (!accepted && phase === "write") dispatch({type:"FAIL", reason:"Control is busy", generation:generation})
    }
    spec: Spec
    kind: "stepped"
    detailKind: "rows"
    detailRows: steps.map(s => ({key: String(s.key), label: s.label, sub: "", state: s.key === value, icon: ""}))
    function activate(key) {
        if (key === "nextStep" || key === "tap") set((Number(value) + 1) % (range.max + 1))
        else if (detailRows.some(r => r.key === key)) set(Number(key))
    }
    function set(v) {
        if (!Number.isFinite(v) || writeState === "pending" || availability !== "available") return
        const native = Math.round(Math.max(0, Math.min(range.max, v)))
        dispatch({type: "SET", value: native, argv: Spec.write(native, Object.assign({}, options, {maxLevel: range.max, device: options.device || detectedDevice}))})
    }
}
