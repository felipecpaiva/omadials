import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Labels.js" as Labels
RowLayout {
    id: field
    required property var theme
    required property var store
    required property string path
    required property string label
    property string help: "Changes apply immediately."
    property var choices: []
    property var words: []
    property string kind: "text"
    property string hint: ""
    readonly property var current: store.value(path)
    Layout.fillWidth: true
    Layout.minimumHeight: 56
    spacing: 16
    ColumnLayout {
        Layout.fillWidth: true; spacing: 4
        Label { Layout.fillWidth: true; text: field.label; wrapMode: Text.WordWrap; color: field.theme.text }
        Label { Layout.fillWidth: true; text: field.help; wrapMode: Text.WordWrap; color: field.theme.secondary; font.pixelSize: 12 }
    }
    Switch {
        visible: field.kind === "bool"; checked: field.current === true
        Accessible.name: field.label
        onClicked: field.store.set(field.path,checked)
    }
    ComboBox {
        visible: field.kind === "choice" || field.kind === "editableChoice"
        Layout.preferredWidth: 190; editable: field.kind === "editableChoice"
        model: field.choices.map(function(v,i) { return {value:v,label:field.words[i] || Labels.label(v)} })
        textRole: "label"; valueRole: "value"
        currentIndex: field.choices.map(String).indexOf(String(field.current))
        displayText: currentIndex < 0 ? String(field.current ?? "") : currentText
        Accessible.name: field.label
        onActivated: field.store.set(field.path,field.choices[currentIndex])
        onAccepted: field.store.set(field.path,editText)
    }
    TextField {
        visible: field.kind === "text" || field.kind === "number"
        Layout.preferredWidth: 150
        text: String(field.current ?? "")
        placeholderText: field.hint; Accessible.name: field.label; selectByMouse: true
        onEditingFinished: field.store.set(field.path,field.kind === "number" ? Number(text) : text)
    }
}
