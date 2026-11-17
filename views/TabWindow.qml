pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../logic/Motion.js" as Motion

// Quickshell creates this type through its engine.
// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: tab
    required property var theme
    required property var model
    AnimatedTheme { id: tabPalette; source: tab.theme }
    property string corner: "bottom-left"
    property string iconMode: "always"
    property bool iconAboveWindows: true
    property bool approaching: false
    // The corner window draws this same tab while it opens or closes. `fanPresenting` is true once that copy is on
    // screen; then this tab hides at once. The hand-off back is instant too, and `shown` reports when this tab has
    // really reached the screen again, so the corner hides its copy only then: no frame without a tab.
    property bool fanPresenting: false
    property bool suppressed: false
    signal iconFailed(string source)
    property string source: "default"
    property string tabStyle: "rings2knob"
    readonly property bool wanted: !suppressed && (iconMode === "always" || iconMode === "onApproach" && approaching)
    property bool drawn: false
    readonly property bool shown: drawn && mark.opacity >= 1
    WlrLayershell.namespace: "omadials-tab"
    WlrLayershell.layer: iconAboveWindows ? WlrLayer.Top : WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    mask: Region {}
    MotionValue { id: tabMotion; theme: tabPalette; target: tab.wanted ? 1 : 0; base: Motion.TIMES.hint }
    TabMark {
        id: mark
        anchors.fill: parent
        opacity: tab.fanPresenting ? 0 : tabMotion.value
        theme: tabPalette; model: tab.model; corner: tab.corner; tabStyle: tab.tabStyle; source: tab.source
        onIconFailed: s => tab.iconFailed(s)
    }
    Connections {
        target: mark.Window.window
        enabled: tab.drawn !== (mark.opacity >= 1)
        function onFrameSwapped() { tab.drawn = mark.opacity >= 1 }
    }
}
