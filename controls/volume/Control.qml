import QtQuick
import Quickshell.Services.Pipewire

// Volume backend: binds to the default Pipewire sink. Value is 0..1 of the cap; the reading stays truthful above it.
QtObject {
  id: root
  property real capPercent: 100
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool available: sink !== null && sink.audio !== null
  readonly property real percent: available ? Math.round(sink.audio.volume * 100) : 0
  readonly property real value: Math.min(1, percent / capPercent)
  readonly property string label: "♪ Volume " + percent + "%"
  property PwObjectTracker tracker: PwObjectTracker { objects: root.sink ? [root.sink] : [] }
  function set(fraction) {
    if (!available) return
    sink.audio.volume = Math.max(0, Math.min(1, fraction)) * capPercent / 100
  }
}
