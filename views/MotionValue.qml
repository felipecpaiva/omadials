import QtQuick
import "../logic/Motion.js" as Motion

// One animated number. A tween (bezier, retargets from the shown value) by default, or a spring stepped every frame
// with the real frame time when `plan` says so (keeps its velocity through a retarget, takes a flick velocity).
// The frame clock runs only while the value moves and stops at rest.
QtObject {
    id: channel
    required property var theme
    required property real target
    property real base: 0
    property real initial: 0
    property real travel: 1
    property real delay: 0
    property bool direct: false
    property bool proportional: true
    property var curve: null        // [x1, y1, x2, y2]; the theme's ease-out when null
    // function(from, to) returning {response, bounce, velocity} (spring) or {ms, curve} (tween). It replaces base,
    // curve and the reduced-motion snap, which the plan handles itself.
    property var plan: null
    // Optional function() returning whether to follow the target directly, read fresh at each retarget. Use it when
    // `direct` and `target` derive from the same source: their bindings update in no fixed order, and a stale `direct`
    // would snap the value (a drag released at 0.5 jumped to 0).
    property var follows: null
    property real value: initial
    property real velocity: 0
    readonly property bool moving: clock.running
    property var run: null
    property bool ready: false
    onTargetChanged: retarget()
    onDirectChanged: retarget()
    Component.onCompleted: { value = initial; ready = true; retarget() }
    function retarget() {
        if (!ready) return
        const now = follows ? follows() : direct
        const p = plan && !now ? plan(value, target) : null
        if (now || (!p && theme.reduceMotion)) { clock.stop(); run = null; velocity = 0; value = target; return }
        const wait = -(p ? delay : theme.duration(delay))
        if (p && p.response) {
            if (p.velocity !== undefined) velocity = p.velocity
            run = { spring: true, response: p.response, bounce: p.bounce, elapsed: wait }
        } else {
            const ms = p ? p.ms : theme.duration(proportional ? Motion.retargetDuration(base, [{ current: value, to: target, travel: travel }]) : base)
            run = { spring: false, from: value, ms: ms, curve: p ? p.curve : (curve || theme.easeOut.slice(0, 4)), elapsed: wait }
            velocity = 0
        }
        if (value !== target || velocity !== 0) clock.restart()
        else { clock.stop(); run = null }
    }
    function step(dt) {
        const r = run
        if (!r) { clock.stop(); return }
        const t = Math.min(Motion.MAX_DT, dt)
        r.elapsed += t * Motion.MS
        if (r.elapsed < 0) return
        if (r.spring) {
            const s = Motion.springStep(value, velocity, target, t, r.response, r.bounce)
            velocity = s.v; value = s.x
            if (s.done) { clock.stop(); run = null }
        } else {
            value = Motion.tweenAt(r.from, target, r.elapsed, r.ms, r.curve)
            if (r.elapsed >= r.ms) { clock.stop(); run = null }
        }
    }
    property FrameAnimation clock: FrameAnimation { onTriggered: channel.step(channel.clock.frameTime) }
    property Connections reduction: Connections {
        target: channel.theme
        function onReduceMotionChanged() {
            if (channel.plan) channel.retarget()
            else if (channel.theme.reduceMotion) { channel.clock.stop(); channel.run = null; channel.value = channel.target }
        }
    }
}
