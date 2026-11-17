pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Gesture.js" as Gesture
// A 48 px round-target icon button for the edit lists. A warning button turns the warn colour on hover.
SettingsButton {
    id: rowButton
    property bool warning: false
    text: ""
    implicitWidth: Gesture.TARGET; implicitHeight: Gesture.TARGET
    foreground: rowButton.warning && rowButton.hot ? rowButton.theme.warn : rowButton.theme.text
    opacity: enabled ? 1 : 0.4
    Accessible.name: rowButton.tooltipText
}
