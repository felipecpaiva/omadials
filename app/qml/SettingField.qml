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
    property var choices: []
    property string kind: "text"
    property string hint: ""
    readonly property var current: store.value(path)
    Layout.fillWidth: true
    Layout.minimumHeight: 48
    Label { Layout.fillWidth: true; Layout.preferredWidth: 220; text: field.label; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
    CheckBox {
        visible: field.kind === "bool"; checked: field.current === true
        Accessible.name: field.label
        onClicked: field.store.set(field.path,checked)
    }
    ComboBox {
        visible: field.kind === "choice" || field.kind === "editableChoice"
        Layout.preferredWidth: 250; editable: field.kind === "editableChoice"
        model: Labels.options(field.choices); textRole: "label"; valueRole: "value"
        currentIndex: field.choices.map(String).indexOf(String(field.current))
        displayText: currentIndex < 0 ? String(field.current ?? "") : currentText
        Accessible.name: field.label
        onActivated: field.store.set(field.path,field.choices[currentIndex])
        onAccepted: field.store.set(field.path,editText)
    }
    TextField {
        visible: ["text","number","list"].indexOf(field.kind) >= 0
        Layout.preferredWidth: 250
        text: field.kind === "list" ? (field.current || []).join(", ") : String(field.current ?? "")
        placeholderText: field.hint; Accessible.name: field.label; selectByMouse: true
        onEditingFinished: {
            let v = field.kind === "number" ? Number(text) : field.kind === "list" ? text.split(",").map(function(s) { return s.trim() }).filter(function(s) { return s.length }) : text;
            field.store.set(field.path,v);
        }
    }
}
