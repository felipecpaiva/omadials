pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell
import "../logic/Glyphs.js" as Glyphs

Item {
    id: iconItem
    required property var theme
    required property string name
    property color ink: theme.text
    readonly property string glyph: Glyphs.glyph(name)
    Image {
        id: image
        anchors.fill: parent; fillMode: Image.PreserveAspectFit
        source: iconItem.name && !iconItem.glyph ? Quickshell.iconPath(iconItem.name,true) : ""
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1; colorizationColor: iconItem.ink }
    }
    Text {
        anchors.centerIn: parent; visible: !!iconItem.glyph || image.status !== Image.Ready
        text: iconItem.glyph || (iconItem.name ? iconItem.name.substring(0,1).toUpperCase() : "?")
        color: iconItem.ink; font.family: iconItem.theme.font; font.pixelSize: Math.round(Math.min(iconItem.width, iconItem.height) * 0.9) || 14
    }
}
