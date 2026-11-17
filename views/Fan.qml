pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Geometry.js" as Geometry
import "../logic/Motion.js" as Motion

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
    readonly property bool open: model.open
    readonly property bool presenting: opacity > 0
    readonly property real morph: shapeMotion.value
    opacity: alphaMotion.value
    visible: presenting
    MotionValue { id: shapeMotion; theme: fanPalette; target: fan.forceHidden ? 0 : fan.model.detail ? 1 : 0; direct: fan.forceHidden; base: Motion.TIMES.detail }
    MotionValue { id: alphaMotion; theme: fanPalette; target: fan.forceHidden ? 0 : fan.model.preview >= 0 ? fan.model.preview : fan.open ? 1 : 0; direct: fan.forceHidden || fan.model.preview >= 0; base: fan.open ? Motion.TIMES.open : Motion.TIMES.close }
    MotionValue { id: scaleMotion; theme: fanPalette; initial: 0.6; travel: 0.4; target: fan.forceHidden ? 0.6 : fan.model.preview >= 0 ? 0.6+0.4*fan.model.preview : fan.open ? 1 : fan.presenting ? 0.8 : 0.6; direct: fan.forceHidden || fan.model.preview >= 0; base: fan.open ? Motion.TIMES.open : Motion.TIMES.close }
    transform: Scale { origin.x: fan.origin.x; origin.y: fan.origin.y; xScale: scaleMotion.value; yScale: xScale }
    Rectangle {
        readonly property real extent: fan.fanRadius*(2-fan.morph)
        width: extent; height: extent; radius: fan.fanRadius*(1-fan.morph)+fan.detailRadius*fan.morph
        x: fan.corner.indexOf("right") >= 0 ? fan.screenWidth-fan.fanRadius : -fan.fanRadius*(1-fan.morph)
        y: fan.corner.indexOf("top") >= 0 ? -fan.fanRadius*(1-fan.morph) : fan.screenHeight-fan.fanRadius
        color: fanPalette.surface; border.color: fanPalette.edge
    }
    Item {
        anchors.fill: parent; opacity: contentMotion.value; visible: opacity > 0
        MotionValue { id: contentMotion; theme: fanPalette; initial: 1; target: fan.model.detail ? 0 : 1; base: fan.model.detail ? Motion.TIMES.detailOut : Motion.TIMES.detailIn; delay: fan.model.detail ? 0 : Motion.TIMES.detailOut }
        Repeater {
            model: fan.model.rings.slice(0,fan.radii.length)
            Ring {
                id: dial
                required property var modelData
                required property int index
                anchors.fill: parent; theme: fanPalette; model: fan.model; control: modelData
                corner: fan.corner; radius: fan.radii[index]; compact: fan.size === "S"
                screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
                reveal: revealMotion.value
                opacity: modelData.availability === "available" && !(modelData.kind === "readout" && !modelData.connected) ? 1 : 0.5
                MotionValue {
                    id: revealMotion; theme: fanPalette
                    target: fan.forceHidden ? 0 : fan.model.preview >= 0 ? fan.model.preview : fan.open ? 1 : 0
                    direct: fan.forceHidden || fan.model.preview >= 0; base: fan.open ? Motion.TIMES.open : Motion.TIMES.close
                    delay: fan.open && dial.reveal === 0 ? dial.index*Motion.TIMES.stagger : 0
                }
            }
        }
        Repeater {
            model: fan.model.rings.slice(0,fan.radii.length)
            RingFocus {
                required property var modelData
                required property int index
                control: modelData; model: fan.model
                box: Geometry.labelBoxes(fan.radii,fan.screenWidth,fan.screenHeight,fan.corner)[index]
            }
        }
    }
    FanInput {
        id: input; anchors.fill: parent; enabled: fan.model.open; model: fan.model; corner: fan.corner; fanRadius: fan.fanRadius
        radii: fan.radii; screenWidth: fan.screenWidth; screenHeight: fan.screenHeight; iconMode: fan.iconMode
    }
    ToggleArc {
        anchors.fill: parent; opacity: contentMotion.value; visible: opacity > 0; enabled: !fan.model.detail
        theme: fanPalette; model: fan.model; corner: fan.corner; radius: fan.toggleRadius
        screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
    }
    Readout {
        anchors.fill: parent; opacity: contentMotion.value; visible: opacity > 0; enabled: !fan.model.detail
        theme: fanPalette; model: fan.model; corner: fan.corner; size: fan.size; fanRadius: fan.fanRadius
        screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
    }
    DetailHost {
        theme: fanPalette; model: fan.model; corner: fan.corner; fanRadius: fan.fanRadius
        screenWidth: fan.screenWidth; screenHeight: fan.screenHeight
    }
    ValueBubble { theme: fanPalette; model: fan.model; screenWidth: fan.screenWidth; screenHeight: fan.screenHeight }
}
