pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Ui
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
    spacing: 12
    Text {
        Layout.preferredWidth: 150
        Layout.fillWidth: true
        text: field.label
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: field.theme.text
        font.family: field.theme.font
    }
    CheckBox {
        visible: field.kind === "bool"
        checked: field.current === true
        Accessible.name: field.label
        onClicked: field.store.set(field.path, checked)
        palette.windowText: field.theme.text
        palette.highlight: field.theme.accent
        palette.base: field.theme.surface
        palette.button: field.theme.off
    }
    // Fixed choices use the stock themed dropdown and show words, not config keys.
    Dropdown {
        visible: field.kind === "choice"
        Layout.preferredWidth: 175
        showLabel: false
        options: Labels.options(field.choices)
        value: String(field.current ?? "")
        foreground: field.theme.text; background: field.theme.surface; accent: field.theme.accent; fontFamily: field.theme.font
        onChanged: (v) => { const i = field.choices.map(String).indexOf(v); if (i >= 0) field.store.set(field.path, field.choices[i]) }
    }
    ComboBox {
        visible: field.kind === "editableChoice"
        editable: true
        Layout.preferredWidth: 175
        model: field.choices
        currentIndex: field.choices.indexOf(field.current)
        Accessible.name: field.label
        onActivated: field.store.set(field.path, field.choices[currentIndex])
        onAccepted: if (editable) field.store.set(field.path, editText)
        palette.buttonText: field.theme.text
        palette.text: field.theme.text
        palette.button: field.theme.off
        palette.base: field.theme.surface
        palette.window: field.theme.surface
        palette.highlight: field.theme.accent
        palette.highlightedText: field.theme.ink
        font.family: field.theme.font
    }
    TextField {
        visible: field.kind === "text" || field.kind === "number" || field.kind === "list"
        Layout.preferredWidth: 175
        text: field.kind === "list" ? (field.current || []).join(", ") : String(field.current ?? "")
        placeholderText: field.hint
        Accessible.name: field.label
        color: field.theme.text
        font.family: field.theme.font
        selectByMouse: true
        background: Rectangle { color: field.theme.off; border.color: field.theme.edge }
        onEditingFinished: {
            let v = field.kind === "number" ? Number(text) : field.kind === "list"
                ? text.split(",").map(function(s) { return s.trim(); }).filter(function(s) { return s.length; }) : text;
            field.store.set(field.path, v);
        }
    }
}
