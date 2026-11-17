pragma ComponentBehavior: Bound
import QtQuick
import "../logic/MotionPreview.js" as MotionPreview
// A small drawing of one animation style. It loops while hovered (so on screen), plays twice when chosen,
// and otherwise rests on a mid-open frame with no clock running.
Canvas {
    id: motionPicture
    required property var theme
    required property string styleKey
    property real speed: 1
    property real bounce: 0.06
    property bool active: true
    property bool selected: false
    property bool hovered: false
    property real clock: 0
    implicitWidth: 66; implicitHeight: 64
    onPaint: {
        const p = loop.running ? MotionPreview.openAmount(styleKey, speed, bounce, clock) : MotionPreview.REST;
        MotionPreview.draw(getContext("2d"), width, height, styleKey, p, theme);
    }
    onClockChanged: requestPaint()
    function replay() {
        loop.stop();
        if (!active || !(hovered || selected) || theme.reduceMotion) return;
        loop.loops = hovered ? Animation.Infinite : 2;
        loop.duration = loop.to = MotionPreview.cycle(styleKey, speed);   // set here: a binding may update after this handler
        loop.start();
    }
    Component.onCompleted: replay()
    onHoveredChanged: replay()
    onSelectedChanged: replay()
    onActiveChanged: replay()
    onSpeedChanged: replay()   // a running animation keeps its old length, so restart it
    onBounceChanged: replay()
    Connections { target: motionPicture.theme; function onAccentChanged() { motionPicture.requestPaint() } function onSurfaceChanged() { motionPicture.requestPaint() } }
    NumberAnimation {
        id: loop
        target: motionPicture; property: "clock"
        from: 0
        onRunningChanged: { motionPicture.clock = 0; motionPicture.requestPaint() }
    }
}
