import QtQuick

// Session state for the corner: open or closed, idle close, and the ring list the views draw.
QtObject {
  id: model
  property bool open: false
  property bool wantsKeyboard: false
  property var rings: []
  property Timer idle: Timer { interval: 10000; onTriggered: model.close() }   // never stays open by itself
  function activity() { if (open) idle.restart() }
  function show(keyboard) { wantsKeyboard = keyboard === true; open = true; idle.restart() }
  function close() { open = false; wantsKeyboard = false; idle.stop() }
  function toggle() { if (open) close(); else show(false) }
}
