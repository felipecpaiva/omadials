pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: opening
    required property var store
    required property var theme
    HelpText { theme: opening.theme; text: "Open when the pointer rests in the corner. This version always enables pointer opening." }
    SettingField { theme: opening.theme; store: opening.store; path: "trigger.pushDelayMs"; label: "Delay"; hint: "Milliseconds before opening. Zero opens immediately."; kind: "number"; maximum: 500 }
}
