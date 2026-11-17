pragma ComponentBehavior: Bound
import QtQuick
Canvas {
    id: drawing
    required property var theme
    required property string styleKey
    required property string choice
    implicitWidth: 64; implicitHeight: 42
    onChoiceChanged: requestPaint()
    onThemeChanged: requestPaint()
    Connections { target: drawing.theme; function onAccentChanged() { drawing.requestPaint() } }
    onPaint: {
        const ctx = getContext("2d"); ctx.reset();
        ctx.strokeStyle = theme.accent; ctx.fillStyle = theme.text;
        ctx.lineWidth = styleKey === "thickness" ? ({thin:1,normal:3,bold:6})[choice] : 3;
        if (styleKey === "track") ctx.setLineDash(choice === "solid" ? [] : choice === "dotted" ? [2,4] : choice === "dashed" ? [6,4] : [12,5]);
        ctx.beginPath(); ctx.arc(32,40,28,Math.PI,Math.PI*2); ctx.stroke();
        if (styleKey === "knob" && choice !== "none") {
            if (choice === "round") { ctx.beginPath(); ctx.arc(32,12,5,0,Math.PI*2); ctx.fill() }
            else ctx.fillRect(29,6,6,12);
        }
    }
}
