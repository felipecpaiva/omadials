pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Geometry.js" as Geometry
import "../logic/Gesture.js" as Gesture
import "../logic/ValueMap.js" as ValueMap
import "../logic/OpenStyles.js" as OpenStyles

MouseArea {
    id: input
    required property var model
    required property string corner
    required property real fanRadius
    required property var radii
    required property real screenWidth
    required property real screenHeight
    property var targetScreen: null
    property bool pushSuppressed: false
    property bool approaching: false
    property int ring: -1
    property point start
    property bool dragging: false
    property bool labelHit: false
    property bool consumed: false
    property bool startedClosed: false
    property double pressedAt: 0
    property real remainder: 0
    property real flick: 0           // drag-open speed, open amounts per second
    property real lastDistance: 0
    property double lastAt: 0
    hoverEnabled: true
    function polarOf(px, py) {
        const c = Geometry.toCanonical({x:px,y:py}, screenWidth, screenHeight, corner)
        return Geometry.polar(c.x, c.y, screenHeight)
    }
    Timer { id: dwell; interval: input.model.config.trigger ? input.model.config.trigger.pushDelayMs : Gesture.DWELL; onTriggered: { input.model.output = input.targetScreen; input.pushSuppressed = true; input.model.pointerSession = true; input.model.show(false) } }
    Timer { id: leave; interval: Gesture.LEAVE; onTriggered: { if (!input.model.captured) input.model.close() } }
    Timer { id: hold; interval: Gesture.HOLD; onTriggered: { input.consumed = true; input.model.captured = false; input.model.action(input.model.rings[input.ring],true) } }
    onPressed: m => {
        start = Qt.point(m.x,m.y); pressedAt = Date.now(); dragging = false; consumed = false
        startedClosed = !model.open; if (startedClosed && targetScreen) model.output = targetScreen; dwell.stop(); model.activity()
        const p = polarOf(m.x,m.y)
        flick = 0; lastDistance = p.d; lastAt = pressedAt
        ring = model.open && !model.detail ? Geometry.hitRing(p.d,radii) : -1
        labelHit = false
        const boxes = model.open && !model.detail ? Geometry.labelBoxes(radii,screenWidth,screenHeight,corner) : []
        for (let i = 0; i < boxes.length; i++) {
            const b = boxes[i]
            if (m.x >= b.x && m.x <= b.x+b.width && m.y >= b.y-(Gesture.TARGET-b.height)/2 && m.y <= b.y+b.height+(Gesture.TARGET-b.height)/2) { ring = i; labelHit = true; break }
        }
        if (ring >= 0) {
            const c = model.rings[ring]
            if (c.availability !== "available") { ring = -1; return }
            if (labelHit || c.kind === "readout") { model.captured = true; hold.start(); model.bubble(c,start) }
            else model.beginDial(c,start)
        } else if (p.d <= Gesture.TRIGGER) model.captured = true
    }
    onPositionChanged: m => {
        const p = polarOf(m.x,m.y)
        approaching = p.d <= Gesture.TRIGGER
        if (!pressed) {
            const c = Geometry.toCanonical({x:m.x,y:m.y},screenWidth,screenHeight,corner)
            if (!Gesture.pushAllowed(c.x,screenHeight-c.y,0,pushEnabled)) pushSuppressed = false
            if (leaveCloses && model.pointerSession && model.open && p.d > fanRadius && !model.captured) { if (!leave.running) leave.start() } else leave.stop()
            if (!model.open && !pushSuppressed && Gesture.pushAllowed(c.x,screenHeight-c.y,m.buttons,pushEnabled)) { if (!dwell.running) dwell.start() }
            else dwell.stop()
            return
        }
        const distance = Math.hypot(m.x-start.x,m.y-start.y)
        if (startedClosed && model.captured && distance >= Gesture.DRAG) {   // the finger owns the open amount
            const now = Date.now()
            flick = OpenStyles.flickVelocity(flick, p.d - lastDistance, now - lastAt, fanRadius); lastDistance = p.d; lastAt = now
            model.preview = OpenStyles.dragAmount(p.d, fanRadius); return
        }
        if (distance >= (labelHit ? Gesture.LABEL_CANCEL : Gesture.DRAG)) hold.stop()
        if (ring < 0 || consumed || labelHit || model.rings[ring].kind === "readout") return
        if (distance < Gesture.DRAG && !dragging) return
        dragging = true; model.moveDial(p.a,p.d-radii[ring],Qt.point(m.x,m.y)); model.activity()
    }
    onReleased: m => {
        hold.stop()
        const p = polarOf(m.x,m.y), c = ring >= 0 ? model.rings[ring] : null
        if (c && !labelHit && c.kind !== "readout") model.commitDial(dragging,false)
        else {
            model.releaseCapture()
            if (c && !consumed && Math.hypot(m.x-start.x,m.y-start.y) < Gesture.TAP_MOVE) {
                if (c.kind === "readout") model.openDetail(c)
                else if (labelHit) model.action(c,false)
            } else if (!c && p.d <= Gesture.TRIGGER && Date.now()-pressedAt <= Gesture.TAP && Math.hypot(m.x-start.x,m.y-start.y) < Gesture.TAP_MOVE) { model.pointerSession = false; model.toggle() }
            else if (!c && startedClosed) model.release(model.preview >= 0 && OpenStyles.opensOnRelease(model.preview, flick, Gesture.OPEN_THRESHOLD), model.preview >= 0 ? flick : 0)
            else if (!c && model.open && p.d > fanRadius) model.close()
        }
        ring = -1; dragging = false
    }
    readonly property bool pushEnabled: !model.config.trigger || model.config.trigger.push !== false
    readonly property bool leaveCloses: !model.config.behavior || model.config.behavior.closeOnPointerLeave !== false
    // Only a real exit: the closed-corner input also "exits" when the fan opens and turns it off, with the pointer still in place.
    onExited: { approaching = false; dwell.stop(); if (enabled && leaveCloses && model.pointerSession && model.open && !model.captured) leave.restart() }
    onCanceled: { hold.stop(); if (model.draftControl) model.commitDial(false,true); else model.releaseCapture(); ring = -1; if (startedClosed) model.close() }
    onWheel: w => {
        const p = polarOf(w.x,w.y), i = Geometry.hitRing(p.d,radii)
        if (!model.open || model.detail || i < 0) { w.accepted = false; return }
        const c = model.rings[i]
        if (c.kind === "readout" || c.availability !== "available") return
        const pixel = w.pixelDelta.y !== 0
        const result = ValueMap.wheel(c.value,pixel ? -w.pixelDelta.y : -w.angleDelta.y,!!(w.modifiers & Qt.ShiftModifier),c.range,remainder,pixel,c.options ? c.options.wheelStep : 0)
        remainder = result.remainder; c.set(result.value); model.report(c); model.bubble(c,Qt.point(w.x,w.y),result.value); model.releaseCapture()
    }
}
