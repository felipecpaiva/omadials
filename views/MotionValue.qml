import QtQuick
import "../logic/Motion.js" as Motion

QtObject {
    id: channel
    required property var theme
    required property real target
    required property real base
    property real initial: 0
    property real travel: 1
    property real delay: 0
    property bool direct: false
    property bool proportional: true
    property real value: initial
    property bool ready: false
    property real runDuration: 0
    property real runFrom: 0
    property real runTo: 0
    onTargetChanged: retarget()
    onDirectChanged: retarget()
    Component.onCompleted: { value = initial; ready = true; retarget() }
    function retarget() {
        if (!ready) return
        const current = value
        animation.stop()
        value = current
        if (direct || theme.reduceMotion) { value = target; return }
        runDuration = theme.duration(proportional ? Motion.retargetDuration(base,[{current:current,to:target,travel:travel}]) : base)
        runFrom = current; runTo = target
        if (current !== target) animation.start()
    }
    property SequentialAnimation animation: SequentialAnimation {
        PauseAnimation { duration: channel.theme.duration(channel.delay) }
        NumberAnimation {
            target: channel; property: "value"; from: channel.runFrom; to: channel.runTo; duration: channel.runDuration
            easing.type: Easing.BezierSpline; easing.bezierCurve: channel.theme.easeOut
        }
    }
    property Connections reduction: Connections {
        target: channel.theme
        function onReduceMotionChanged() { if (channel.theme.reduceMotion) { channel.animation.stop(); channel.value = channel.target } }
    }
}
