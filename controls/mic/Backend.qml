import QtQuick
import Quickshell.Services.Pipewire
import "../../core"
import "map.js" as Map
import "../../logic/ValueMap.js" as ValueMap

ControlBase {
    id: backend
    property var node: Pipewire.defaultAudioSource
    property var audio: node ? node.audio : null
    property bool muted: audio ? audio.muted : false
    property real capPercent: options.maxPercent || 100
    property PwObjectTracker tracker: PwObjectTracker { objects: backend.node ? [backend.node] : [] }
    property bool inputDevice: true
    property var devices: Pipewire.nodes.values.filter(n => !n.isStream && n.isSink !== inputDevice && n.audio)
    property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)
    function selectDevice(device) {
        if (devices.indexOf(device) < 0) return
        if (inputDevice) Pipewire.preferredDefaultAudioSource = device
        else Pipewire.preferredDefaultAudioSink = device
    }
    kind: "dial"
    range: ({min: 0, max: capPercent, floor: 0, step: 1, unit: "%"})
    availability: audio ? "available" : "unavailable"
    reason: audio ? "" : "No default audio source"
    value: Map.reading(audio)
    valueText: value === null ? "unknown" : value + "%" + (muted ? " (muted)" : "")
    detailKind: "custom"
    property url detailComponent: Qt.resolvedUrl("../../views/details/AudioDetail.qml")
    function set(v) {
        const next = Number.isFinite(v) ? Map.input(ValueMap.input(v, range), capPercent) : null
        if (audio && next !== null) audio.volume = next
    }
    function activate(key) {
        if (key !== "mute" || !audio) return
        runner.run(controlId + ":mute", ["omarchy-audio-input-mute"], 10000, (out, code, error) => { lastError = code ? error || "Mute failed" : ""; changed(lastError) })
    }
    detailRows: [{key: "mute", label: muted ? "Unmute" : "Mute", sub: "", state: muted, icon: ""}]
}
