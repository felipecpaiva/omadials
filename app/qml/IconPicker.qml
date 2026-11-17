import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Glyphs.js" as Glyphs
RowLayout {
    id: picker
    required property var store
    required property var theme
    required property string path
    required property string controlId
    property string label: qsTr("Icon")
    Layout.fillWidth: true
    ColumnLayout {
        Layout.fillWidth: true
        Label { text: picker.label }
        Label { text: qsTr("Choose an icon from your desktop icon theme."); color: picker.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }
    Label { text: Glyphs.glyph(picker.store.value(picker.path) === "default" ? picker.controlId : picker.store.value(picker.path)); font.family: "Symbols Nerd Font"; font.pixelSize: 24; color: picker.theme.accent }
    Image { visible: picker.store.value(picker.path)!=="default"; source: visible ? picker.store.io.iconUrl(picker.store.value(picker.path)) : ""; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
    ComboBox {
        Layout.preferredWidth: 170
        property var names: ["default"].concat(picker.store.validationResources.icons || [])
        model: names; currentIndex: names.indexOf(picker.store.value(picker.path))
        displayText: currentIndex === 0 ? qsTr("Default") : currentText
        Accessible.name: picker.label
        onActivated: picker.store.set(picker.path,names[currentIndex])
    }
}
