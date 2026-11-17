pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Gesture.js" as Gesture
import "../logic/ValueMap.js" as ValueMap
import "../logic/Motion.js" as Motion
import "../logic/Layout.js" as Layout

QtObject {
    id: session
    property var registry: null
    property var output: null
    property var config: ({})
    property var frozenRings: []
    property var frozenToggles: []
    property var rings: registry ? (captured ? frozenRings : registry.rings) : []
    readonly property var toggles: registry ? (captured ? frozenToggles : registry.toggles) : []
    property bool open: false
    property real preview: -1       // the open amount while a finger drags the corner open, -1 otherwise
    property real flick: 0          // that finger's speed (open amounts per second) at release; the open motion starts from it
    property bool pointerSession: false
    property int tickSerial: 0
    property var tickControl: null
    property bool wantsKeyboard: false
    property bool captured: false
    onCapturedChanged: { if (captured && registry) { frozenRings = registry.rings.slice(); frozenToggles = registry.toggles.slice() } }
    property bool deferredClose: false
    property string status: ""
    property bool statusError: false
    property double statusAt: 0
    property string detail: ""
    property var detailControl: null
    property real arcOffset: 0
    property var draftControl: null
    property var gesture: null
    property real draft: 0
    property bool fine: false
    property bool bubbleVisible: false
    property point contact: Qt.point(0, 0)
    property string bubbleText: ""
    property var battery: null
    property string batteryLine: battery ? battery.label : ""
    property var profile: null
    signal settingsRequested()
    signal actionRequested(var control)
    property Timer idle: Timer {
        interval: session.config.behavior ? session.config.behavior.idleTimeoutS * 1000 : Gesture.IDLE
        onTriggered: { if (!session.captured) session.close() }
    }
    // Dials write live while dragged (maintainer request): at most one write in flight, always the newest value.
    // A value released while a write is still running is written as soon as that write ends.
    property var liveControl: null
    property real liveValue: -1
    property real lastLive: -1
    property Timer liveWrite: Timer {
        interval: 50; repeat: true
        running: !!session.liveControl
        onTriggered: {
            const c = session.liveControl
            if (!c || c.availability !== "available") { session.liveControl = null; return }
            if (c.writeState === "pending") return
            const v = Math.round(session.captured && session.draftControl === c ? session.draft : session.liveValue)
            if (v !== session.lastLive) { session.lastLive = v; c.set(v) }
            else if (!(session.captured && session.draftControl === c)) session.liveControl = null
        }
    }
    property Timer bubbleTimer: Timer { interval: Motion.TIMES.bubbleHold; onTriggered: session.bubbleVisible = false }
    function textLayout(size, measure, screen, corner, radius, elapsed) { return Layout.textLayout(size,status,measure,screen,corner,radius,statusError,elapsed) }
    function activity() { if (open && idle.interval > 0) idle.restart() }
    function show(keyboard) { preview = -1; wantsKeyboard = keyboard === true; arcOffset = 0; open = true; activity() }
    function close() {
        if (captured) { deferredClose = true; return }
        preview = -1; open = false; wantsKeyboard = false; detail = ""; detailControl = null
        bubbleVisible = false; idle.stop()
    }
    function toggle() { if (open) close(); else show(false) }
    function release(opening, velocity) { flick = velocity; if (opening) show(false); else close(); flick = 0 }
    function say(text, error, user) { status = text; statusError = !!error; statusAt = Date.now(); if (user !== false) activity() }
    function report(control) {
        say(control.label + ": " + (control.writeState === "failed" ? control.lastError : control.writeState === "pending" ? "changing…" : control.valueText), control.writeState === "failed", false)
    }
    function action(control, hold) {
        if (!control || control.availability !== "available" || control.writeState === "pending") return
        const entry = (config.toggles || []).find(function(e) { return e.id === control.controlId })
        const name = entry ? (hold ? entry.holdAction : entry.tapAction) : (hold || control.kind === "readout" ? "quickDetail" : "tap")
        if (name === "quickDetail") openDetail(control)
        else { actionRequested(control); control.activate(name) }
        report(control); activity()
    }
    function openDetail(control) {
        const c = typeof control === "string" ? (registry ? registry.byId(control) : null) : control
        if (!c || c.detailKind === "none") return
        detailControl = c; detail = c.controlId; activity()
        if (c.detailKind === "external") { c.activate("quickDetail"); closeDetail() }
    }
    function forceHide() { captured = false; deferredClose = false; draftControl = null; gesture = null; close() }
    function closeDetail() { detail = ""; detailControl = null; activity() }
    function releaseCapture() {
        captured = false; draftControl = null; gesture = null; fine = false
        bubbleTimer.restart(); activity()
        if (deferredClose) { deferredClose = false; close() }
    }
    function bubble(control, point, value) {
        contact = point; bubbleText = value === undefined ? control.valueText : Math.round(value) + (control.range.unit || "")
        bubbleVisible = true; bubbleTimer.stop()
    }
    function beginDial(control, point) {
        if (control.kind === "readout" || control.value === null || control.availability !== "available") return
        captured = true; draftControl = control; draft = control.value
        gesture = Gesture.begin("ring", control.controlId, point, Date.now(), ValueMap.fraction(control.value, control.range) * 100)
        bubble(control, point)
    }
    function moveDial(angle, distance, point) {
        if (!draftControl || !gesture) return
        const opts = config.dialInteraction || {snap:true, fineEnabled:true}
        const result = Gesture.dial(gesture, angle, distance, {startAngle:ValueMap.START, snap:opts.snap, fineEnabled:opts.fineEnabled})
        if (result.tick) { tickControl = draftControl; tickSerial++ }
        gesture = result.state; draft = ValueMap.nativeValue(result.value / 100, draftControl.range)
        if (liveControl !== draftControl) { liveControl = draftControl; lastLive = Math.round(draftControl.value === null ? -1 : draftControl.value) }
        fine = gesture.gain < 1; bubble(draftControl, point, draft)
    }
    function commitDial(moved, cancel) {
        if (draftControl && draftControl.kind !== "readout" && moved && !cancel && draftControl.availability === "available") {
            liveValue = draft; liveControl = draftControl; report(draftControl)   // the live writer sends the final value
        }
        releaseCapture()
    }
    function ringStyle(control) {
        const entries = (config.dials || []).concat(config.readoutRings || [])
        const e = entries.find(function(entry) { return entry.id === control.controlId })
        return Object.assign({track:"solid", knob:"round", thickness:"normal"}, config.ringStyle || {}, e ? e.style || {} : {})
    }
}
