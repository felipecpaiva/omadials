// Spike P1.8: per-app audio streams (Pipewire) and media players (Mpris), read only.
// Run: timeout 10 qs -p spikes/p18-pipewire
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
ShellRoot {
  PwObjectTracker { objects: Pipewire.nodes.values }
  Timer {
    interval: 2500; running: true
    onTriggered: {
      const nodes = Pipewire.nodes.values
      for (const n of nodes) if (n.isStream) console.log("RESULT stream app=" + (n.properties["application.name"] || n.name) + " sink=" + n.isSink + " vol=" + (n.audio ? n.audio.volume.toFixed(2) : "?") + " muted=" + (n.audio ? n.audio.muted : "?"))
      console.log("RESULT default sink=" + (Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.description : "none") + " vol=" + (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume.toFixed(2) : "?"))
      console.log("RESULT sinks=" + nodes.filter(n => n.isSink && !n.isStream).map(n => n.description).join(" | "))
      for (const p of Mpris.players.values) console.log("RESULT player=" + p.identity + " state=" + p.playbackState + " title=" + (p.trackTitle ? "yes" : "no") + " canSeek=" + p.canSeek)
      console.log("RESULT players=" + Mpris.players.values.length)
      Qt.quit()
    }
  }
}
