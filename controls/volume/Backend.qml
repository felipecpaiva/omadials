import QtQuick
import Quickshell.Services.Pipewire
import "../../core"
import "map.js" as Map
import "../../logic/ValueMap.js" as ValueMap

ControlBase {
    id: backend
    property var node: Pipewire.defaultAudioSink
    property var audio: node ? node.audio : null
    property bool muted: audio ? audio.muted : false
    property real capPercent: options.maxPercent || 100
    property PwObjectTracker tracker: PwObjectTracker { objects: backend.node ? [backend.node] : [] }
    kind: "dial"
    range: ({min: 0, max: capPercent, floor: 0, step: 1, unit: "%"})
    availability: audio ? "available" : "unavailable"
    reason: audio ? "" : "No default audio sink"
    value: Map.reading(audio)
    valueText: value === null ? "unknown" : value + "%" + (muted ? " (muted)" : "")
    detailKind: "rows"
    function set(v) {
        const next = Number.isFinite(v) ? Map.input(ValueMap.input(v, range), capPercent) : null
        if (audio && next !== null) audio.volume = next
    }
    function activate(key) {
        if (key !== "mute" || !audio) return
        audio.muted = !audio.muted
    }
    detailRows: [{key: "mute", label: muted ? "Unmute" : "Mute", sub: "", state: muted, icon: ""}]
}
