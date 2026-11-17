pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Ui as Ui
import "../logic/Labels.js" as Labels
RowLayout {
    id: field
    required property var theme
    required property var store
    required property string path
    required property string label
    property var choices: []
    property var choiceLabels: []
    property string kind: "choice"
    property string hint: ""
    property real minimum: 0
    property real maximum: 25
    property bool inverted: false
    readonly property var current: store.value(path)
    Layout.fillWidth: true
    Layout.minimumHeight: 52
    spacing: 12
    ColumnLayout {
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: field.label; wrapMode: Text.WordWrap; color: field.theme.text; font.family: field.theme.font }
        HelpText { theme: field.theme; text: field.hint; visible: text.length > 0 }
    }
    Ui.ToggleSwitch {
        visible: field.kind === "bool"
        checked: field.inverted ? !field.current : field.current === true
        foreground: field.theme.text; accent: field.theme.accent
        Accessible.name: field.label
        activeFocusOnTab: true
        function apply() { field.store.set(field.path, field.inverted ? checked : !checked) }
        onToggled: apply()
        Keys.onSpacePressed: apply()
    }
    Ui.Dropdown {
        visible: field.kind === "choice" || field.kind === "editableChoice"
        Layout.preferredWidth: 185
        showLabel: false
        options: field.choices.map((v, i) => ({value:String(v), label:field.choiceLabels[i] || Labels.label(v)}))
        value: String(field.current ?? "")
        foreground: field.theme.text; background: field.theme.surface; accent: field.theme.accent; fontFamily: field.theme.font
        Accessible.name: field.label
        onChanged: v => { const i = field.choices.map(String).indexOf(v); if (i >= 0) field.store.set(field.path, field.choices[i]) }
    }
    ColumnLayout {
        visible: field.kind === "number"
        Layout.preferredWidth: 170
        HelpText { theme: field.theme; text: String(field.current ?? field.minimum) }
        Ui.PanelSlider {
            Layout.fillWidth: true
            minimum: field.minimum; maximum: field.maximum; integer: true; step: 1
            value: Number(field.current ?? field.minimum)
            trackColor: field.theme.track; fillColor: field.theme.accent; knobColor: field.theme.text; tickColor: field.theme.surface
            Accessible.name: field.label
            onReleased: v => field.store.set(field.path, Math.round(v))
        }
    }
}
