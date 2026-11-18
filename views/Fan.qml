pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Geometry.js" as Geometry
import "../logic/Motion.js" as Motion
import "../logic/OpenStyles.js" as OpenStyles

Item {
    id: fan
    required property var theme
    required property var model
    required property string corner
    required property real fanRadius
    required property var radii
    required property var origin
    required property real screenWidth
    required property real screenHeight
    AnimatedTheme { id: fanPalette; source: fan.theme }
    Keys.onEscapePressed: { if (model.detail) model.closeDetail(); else model.close() }
    Keys.onBackPressed: { if (model.detail) model.closeDetail(); else model.close() }
    property bool forceHidden: false
    property real detailRadius: 12
    property string size: "M"
    property real toggleRadius: 240
    property string iconMode: "always"
    property alias approaching: input.approaching
    property string tabStyle: "rings2knob"
    property string tabSource: "default"
    readonly property bool open: model.open
    // One open amount drives the whole open and close motion: 0 is the closed tab, 1 the full corner.
    readonly property real amount: openMotion.value
    readonly property bool presenting: !forceHidden && (amount > 0 || open)
    readonly property real morph: shapeMotion.value
    readonly property var animation: model.config.animation || ({})
    readonly property string style: fanPalette.reduceMotion ? "still" : animation.style || "morph"
    readonly property var shownRings: model.rings.slice(0, radii.length)
    readonly property var sizes: ({ R: fanRadius, radii: radii, toggleRadius: toggleRadius, toggles: Geometry.arcSlots(toggleRadius).count,
        strokes: shownRings.map(c => OpenStyles.strokeFor(model.ringStyle(c).thickness)), mini: tabMark.mini, knob: tabMark.knob, tab: tabMark.tabScale })
    readonly property var frame: OpenStyles.frame(style, amount, sizes)
    function plan(from, to) { return OpenStyles.timing(style, from, to, model.flick, animation) }
    MotionValue {
        id: openMotion; theme: fanPalette; target: fan.forceHidden ? 0 : fan.model.preview >= 0 ? fan.model.preview : fan.open ? 1 : 0; direct: fan.forceHidden || fan.model.preview >= 0; plan: fan.plan
        follows: () => fan.forceHidden || fan.model.preview >= 0 }
    MotionValue { id: shapeMotion; theme: fanPalette; target: fan.forceHidden ? 0 : fan.model.detail ? 1 : 0; direct: fan.forceHidden; base: Motion.TIMES.detail }
    MotionValue { id: contentMotion; theme: fanPalette; initial: 1; target: fan.model.detail ? 0 : 1; base: fan.model.detail ? Motion.TIMES.detailOut : Motion.TIMES.detailIn; delay: fan.model.detail ? 0 : Motion.TIMES.detailOut }
    Item {
        id: body          // everything but the tab overlay; Minimal fades it as one. Hidden while the opaque tab
        anchors.fill: parent; opacity: fan.frame.alpha; visible: fan.frame.tab < 1   // covers it: no doubled edge
        Rectangle {
            readonly property real disc: fan.frame.disc
            readonly property real extent: disc*(2-fan.morph)
            width: extent; height: extent; radius: disc*(1-fan.morph)+fan.detailRadius*fan.morph
            x: fan.corner.indexOf("right") >= 0 ? fan.screenWidth-disc : -disc*(1-fan.morph)
            y: fan.corner.indexOf("top") >= 0 ? -disc*(1-fan.morph) : fan.screenHeight-disc
            color: fanPalette.surface; border.color: fanPalette.edge
        }
        Item {
            anchors.fill: parent; opacity: contentMotion.value; visible: opacity > 0
            BatteryRing {   // the tab's battery ring, kept the same gap inside the disc edge as it grows
                anchors.fill: parent; theme: fanPalette; model: fan.model; corner: fan.corner
                origin: Qt.point(fan.origin.x, fan.origin.y); stroke: OpenStyles.TAB.stroke * tabMark.tabScale
                radius: Math.max(OpenStyles.TAB.battery * tabMark.tabScale, fan.frame.disc - (OpenStyles.TAB.radius - OpenStyles.TAB.battery) * tabMark.tabScale - 6 * Math.min(1, Math.max(0, fan.amount)))   // 6 px more inside when open: off the edge line
            }
            Repeater {
                model: fan.shownRings
                Ring {
                    required property var modelData
                    required property int index
                    anchors.fill: parent; theme: fanPalette; model: fan.model; control: modelData
                    corner: fan.corner; radius: fan.radii[index]; compact: fan.size === "S"
                    screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
                    look: fan.frame.rings[index]
                    opacity: (modelData.availability === "available" && !(modelData.kind === "readout" && !modelData.connected) ? 1 : 0.5) * look.alpha
                }
            }
            Repeater {
                model: fan.shownRings
                RingFocus {
                    required property var modelData
                    required property int index
                    control: modelData; model: fan.model
                    box: Geometry.labelBoxes(fan.radii,fan.screenWidth,fan.screenHeight,fan.corner)[index]
                }
            }
        }
    }
    FanInput {
        id: input; anchors.fill: parent; enabled: fan.model.open; model: fan.model; corner: fan.corner; fanRadius: fan.fanRadius
        radii: fan.radii; screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
    }
    ToggleArc {
        anchors.fill: parent; opacity: contentMotion.value * fan.frame.alpha; visible: opacity > 0 && body.visible; enabled: !fan.model.detail; reveal: fan.frame.toggles
        theme: fanPalette; model: fan.model; corner: fan.corner; radius: fan.toggleRadius
        screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
    }
    Readout {
        anchors.fill: parent; opacity: contentMotion.value * fan.frame.alpha * fan.frame.readout; visible: opacity > 0; enabled: !fan.model.detail
        theme: fanPalette; model: fan.model; corner: fan.corner; size: fan.size; fanRadius: fan.fanRadius
        screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
    }
    DetailHost {
        theme: fanPalette; model: fan.model; corner: fan.corner; fanRadius: fan.fanRadius
        screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
    }
    ValueBubble { theme: fanPalette; model: fan.model; screenWidth: fan.screenWidth; screenHeight: fan.screenHeight }
    TabMark {   // on top while it fades out by p = 0.18, so the first and last frames are the tab itself
        id: tabMark
        anchors.fill: parent; opacity: fan.frame.tab * (fan.iconMode === "always" || (fan.iconMode === "onApproach" && fan.approaching) ? 1 : 0); visible: opacity > 0   // no tab pops in when the icon is hidden
        theme: fanPalette; model: fan.model; corner: fan.corner; tabStyle: fan.tabStyle; source: fan.tabSource
    }
}
