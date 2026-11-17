import QtQuick
import "../../core"
import "spec.js" as Spec

CommandControl {
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
        dispatch({type: "SET", value: native, argv: Spec.write(native, Object.assign({}, options, {maxLevel: range.max}))})
    }
}
