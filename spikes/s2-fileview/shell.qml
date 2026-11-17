// Spike S2: does FileView with watchChanges see a file that did not exist at load time?
// Run: timeout 12 qs -p spikes/s2-fileview  (it prints RESULT lines and quits)
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
  property string target: "/tmp/omadials-s2/state-flag"
  FileView {
    id: fv
    path: target
    watchChanges: true
    printErrors: false
    onFileChanged: { console.log("RESULT fileChanged fired"); reload() }
    onLoaded: console.log("RESULT loaded text=[" + text().trim() + "]")
    onLoadFailed: (e) => console.log("RESULT loadFailed " + e)
  }
  Timer { interval: 9000; running: true; onTriggered: { console.log("RESULT done"); Qt.quit() } }
}
