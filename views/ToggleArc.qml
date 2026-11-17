pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Geometry.js" as Geometry
import "../logic/Gesture.js" as Gesture
import "../logic/Motion.js" as Motion

Item {
    id: arc
    required property var theme
    required property var model
    required property string corner
    required property real radius
    required property real screenWidth
    required property real screenHeight
    readonly property var slots: Geometry.arcSlots(radius)
    readonly property real maxOffset: Math.max(0,model.toggles.length-slots.count)
    property bool dragging: false
    property int pressedIndex: -1
    property var gesture: null
    property real startAngle: 0
    property real startOffset: 0
    property real offset: model.arcOffset
    Connections { target: arc.model; function onOpenChanged() { if (arc.model.open) { snapAnimation.stop(); arc.dragging = true; arc.offset = 0; arc.dragging = false } } }
    onOffsetChanged: model.arcOffset = offset
    Behavior on offset { enabled: !arc.dragging; NumberAnimation { id: snapAnimation; duration: arc.theme.duration(Motion.TIMES.snap); easing.type: Easing.BezierSpline; easing.bezierCurve: arc.theme.easeOut } }
    onDraggingChanged: if (dragging) snapAnimation.stop()
    Connections {
        target: arc.theme
        function onReduceMotionChanged() {
            if (arc.theme.reduceMotion) { snapAnimation.complete(); if (holdFill.progress > 0) holdAnimation.complete() }
        }
    }
    function polar(px,py) { const c = Geometry.toCanonical({x:px,y:py},screenWidth,screenHeight,corner); return Geometry.polar(c.x,c.y,screenHeight) }
    Repeater {
        id: buttons
        model: arc.model.toggles
        ToggleButton {
            required property var modelData
            required property int index
            readonly property real angle: Geometry.ARC_START + arc.slots.step * (index-arc.offset+0.5)
            readonly property var pos: Geometry.fromCanonical(Geometry.knobPos(arc.radius,angle,arc.screenHeight),arc.screenWidth,arc.screenHeight,arc.corner)
            x: pos.x-width/2; y: pos.y-height/2
            visible: Gesture.arcHit(angle,arc.radius)
            opacity: modelData.availability === "available" ? 1 : 0.5
            theme: arc.theme; control: modelData; model: arc.model
            down: arc.pressedIndex === index && !arc.dragging
            holdProgress: down ? holdFill.progress : 0
            enabled: visible && modelData.availability === "available"
        }
    }
    QtObject { id: holdFill; property real progress: 0 }
    SequentialAnimation {
        id: holdAnimation
        PauseAnimation { duration: Gesture.HOLD_START }
        NumberAnimation { target: holdFill; property: "progress"; from: 0; to: 1; duration: arc.theme.reduceMotion ? 0 : Gesture.HOLD-Gesture.HOLD_START }
    }
    Timer {
        id: hold; interval: Gesture.HOLD
        onTriggered: {
            arc.gesture = Object.assign({},arc.gesture,{consumed:true})
            arc.model.captured = false; arc.model.action(arc.model.toggles[arc.pressedIndex],true)
        }
    }
    MouseArea {
        anchors.fill: parent
        onPressed: m => {
            const p = arc.polar(m.x,m.y)
            if (Math.abs(p.d-arc.radius) > Gesture.TARGET/2 || !Gesture.arcHit(p.a,arc.radius)) { m.accepted = false; return }
            const i = Math.round((p.a-Geometry.ARC_START)/arc.slots.step-0.5+arc.offset)
            if (i < 0 || i >= arc.model.toggles.length) { m.accepted = false; return }
            snapAnimation.stop()
            arc.pressedIndex = i; arc.startAngle = p.a; arc.startOffset = arc.offset
            arc.gesture = Gesture.begin("toggle",i,{x:m.x,y:m.y},Date.now(),0)
            arc.model.captured = true; arc.model.activity(); holdFill.progress = 0; holdAnimation.start(); hold.start()
        }
        onPositionChanged: m => {
            if (!pressed || !arc.gesture || arc.gesture.consumed) return
            arc.gesture = Gesture.move(arc.gesture,{x:m.x,y:m.y})
            if (!arc.gesture.moved) return
            hold.stop(); holdAnimation.stop(); arc.dragging = true
            const travel = (arc.polar(m.x,m.y).a-arc.startAngle)*Math.PI/180*arc.radius
            arc.offset = Gesture.arcMove(arc.startOffset,travel,arc.maxOffset)
        }
        function finish(cancel) {
            hold.stop(); holdAnimation.stop(); holdFill.progress = 0
            if (arc.gesture && !cancel && !arc.gesture.consumed && !arc.gesture.moved) {
                const c = arc.model.toggles[arc.pressedIndex]
                if (c && c.availability === "available") { arc.model.action(c,false); arc.model.report(c) }
            }
            arc.dragging = false; arc.offset = Gesture.arcSnap(arc.offset,0,arc.maxOffset)
            arc.pressedIndex = -1; arc.gesture = null; arc.model.releaseCapture()
        }
        onReleased: finish(false)
        onCanceled: finish(true)
        onWheel: w => {
            const p = arc.polar(w.x,w.y)
            if (Math.abs(p.d-arc.radius)>Gesture.TARGET/2) { w.accepted = false; return }
            arc.offset = Gesture.arcSnap(arc.offset,w.angleDelta.y < 0 ? 1 : -1,arc.maxOffset); arc.model.activity()
        }
    }
    Repeater {
        model: 2
        Rectangle {
            required property int index
            readonly property var pos: Geometry.fromCanonical(Geometry.knobPos(arc.radius,index ? Geometry.ARC_END : Geometry.ARC_START,arc.screenHeight),arc.screenWidth,arc.screenHeight,arc.corner)
            x: pos.x-8; y: pos.y-8; width: 16; height: 16; radius: 8
            visible: index ? arc.offset < arc.maxOffset : arc.offset > 0
            gradient: Gradient { GradientStop { position: 0; color: arc.theme.surface } GradientStop { position: 1; color: Qt.alpha(arc.theme.surface,0) } }
        }
    }
}
