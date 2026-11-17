pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Geometry.js" as Geometry
import "../logic/Motion.js" as Motion

Rectangle {
    id: bubble
    required property var theme
    required property var model
    required property real screenWidth
    required property real screenHeight
    readonly property var pos: Geometry.bubblePos(model.contact,screenWidth,screenHeight)
    x: Math.max(Geometry.CLEARANCE,Math.min(screenWidth-width-Geometry.CLEARANCE,pos.x-width/2))
    y: pos.y-height/2
    width: copy.implicitWidth + 24; height: Math.max(32,copy.implicitHeight+12); radius: height/2
    color: theme.surface; border.color: theme.edge
    opacity: bubbleMotion.value; visible: opacity > 0
    MotionValue { id: bubbleMotion; theme: bubble.theme; target: bubble.model.bubbleVisible ? 1 : 0; base: Motion.TIMES.bubble }
    Text { id: copy; anchors.centerIn: parent; text: bubble.model.bubbleText + (bubble.model.fine ? " · Fine" : ""); color: bubble.theme.text; font.family: bubble.theme.font; font.pixelSize: 14 }
}
