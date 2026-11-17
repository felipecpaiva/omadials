import QtQuick
import "../logic/Glyphs.js" as Glyphs
// Draws a built-in glyph by name, or else the named icon from the desktop icon theme.
Item {
    id: icon
    required property var theme
    required property var store
    required property string name
    property int size: 24
    property color color: theme.accent
    implicitWidth: size + 8; implicitHeight: size + 8
    readonly property string glyph: Glyphs.glyph(name)
    Text { anchors.centerIn: parent; visible: icon.glyph.length > 0; text: icon.glyph; font.family: "Symbols Nerd Font"; font.pixelSize: icon.size; color: icon.color }
    Image {
        anchors.centerIn: parent; width: icon.size; height: icon.size; sourceSize.width: icon.size; sourceSize.height: icon.size
        visible: !icon.glyph.length; source: visible && icon.name.length ? icon.store.io.iconUrl(icon.name) : ""
    }
}
