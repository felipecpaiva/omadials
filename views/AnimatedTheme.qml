import QtQuick
import "../logic/Contrast.js" as Contrast
import "../logic/Motion.js" as Motion

QtObject {
    id: palette
    required property var source
    function hex(c) { return "#" + [c.r,c.g,c.b].map(function(v) { return Math.round(v*255).toString(16).padStart(2,"0") }).join("") }
    readonly property bool textSafe: Contrast.ratio(hex(textBlend),hex(surfaceBlend)) >= Contrast.TEXT_RATIO
    readonly property bool controlSafe: Contrast.ratio(hex(accentBlend),hex(inkBlend)) >= Contrast.CONTROL_RATIO
    readonly property color targetAccent: Contrast.ratio(hex(source.accent),hex(source.ink)) >= Contrast.CONTROL_RATIO ? source.accent : source.text
    readonly property color surface: textSafe ? surfaceBlend : source.surface
    readonly property color text: textSafe ? textBlend : source.text
    readonly property color accent: controlSafe ? accentBlend : targetAccent
    readonly property color ink: controlSafe ? inkBlend : source.ink
    readonly property string font: source.font
    readonly property bool reduceMotion: source.reduceMotion
    readonly property var easeOut: source.easeOut
    function duration(ms) { return source.duration(ms) }
    property color surfaceBlend: source.surface
    property color textBlend: source.text
    property color accentBlend: targetAccent
    property color inkBlend: source.ink
    property color edge: source.edge
    property color secondary: source.secondary
    property color track: source.track
    property color off: source.off
    property color warn: source.warn
    Behavior on surfaceBlend { ColorAnimation { id: surfaceMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on textBlend { ColorAnimation { id: textMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on accentBlend { ColorAnimation { id: accentMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on inkBlend { ColorAnimation { id: inkMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on edge { ColorAnimation { id: edgeMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on secondary { ColorAnimation { id: secondaryMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on track { ColorAnimation { id: trackMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on off { ColorAnimation { id: offMotion; duration: palette.duration(Motion.TIMES.theme) } }
    Behavior on warn { ColorAnimation { id: warnMotion; duration: palette.duration(Motion.TIMES.theme) } }
    property Connections reduction: Connections {
        target: palette.source
        function onReduceMotionChanged() {
            if (palette.reduceMotion) [surfaceMotion,textMotion,accentMotion,inkMotion,edgeMotion,secondaryMotion,trackMotion,offMotion,warnMotion].forEach(function(a) { a.complete() })
        }
    }
}
