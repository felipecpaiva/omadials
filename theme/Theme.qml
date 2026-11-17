import QtQuick
import qs.Commons

// The only file that reads Omarchy's theme (architecture section 8). Views read these roles, never Commons.
QtObject {
  readonly property color surface: Color.popups.background
  readonly property color edge: Qt.alpha(Color.foreground, 0.22)
  readonly property color text: Color.popups.text
  readonly property color secondary: Qt.alpha(Color.foreground, 0.72)
  readonly property color track: Qt.alpha(Color.foreground, 0.28)
  readonly property color accent: Color.accent
  readonly property color ink: Color.background
  readonly property color off: Qt.alpha(Color.foreground, 0.10)
  readonly property color warn: Color.urgent
  readonly property string font: Style.fontFamily
  // Follows Hyprland animations: off (also in game mode) means every motion is instant.
  readonly property bool reduceMotion: Style.reduceMotion
  readonly property var easeOut: Style.easeOut
  function duration(ms) { return Style.duration(ms) }
}
