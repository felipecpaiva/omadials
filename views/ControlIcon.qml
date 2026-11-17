pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell

Item {
    id: iconItem
    required property var theme
    required property string name
    property color ink: theme.text
    Image {
        id: image
        anchors.fill: parent; fillMode: Image.PreserveAspectFit
        source: iconItem.name ? Quickshell.iconPath(iconItem.name,true) : ""
        layer.enabled: true
        layer.effect: MultiEffect { colorization: 1; colorizationColor: iconItem.ink }
    }
    Text {
        anchors.centerIn: parent; visible: image.status !== Image.Ready
        text: iconItem.name ? iconItem.name.substring(0,1).toUpperCase() : "?"
        color: iconItem.ink; font.family: iconItem.theme.font; font.pixelSize: 14
    }
}
