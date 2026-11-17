pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: cornerPage
    required property var store
    required property var theme
    spacing: 12
    Repeater {
        model: [
            {p:"corner", l:"Corner", c:["top-left","top-right","bottom-left","bottom-right"]},
            {p:"size", l:"Size", c:["S","M","L"]},
            {p:"tabStyle", l:"Corner tab", c:["rings2knob","rings3"]},
            {p:"cornerIcon.mode", l:"Icon mode", c:["always","onApproach","never"]},
            {p:"cornerIcon.source", l:"Corner icon", c:[]},
            {p:"cornerIcon.aboveWindows", l:"Above windows", k:"bool"},
            {p:"outputs.mode", l:"Trigger outputs", c:["all","focused","named"]},
            {p:"outputs.names", l:"Output names (comma separated)", k:"list"},
            {p:"trigger.pushDelayMs", l:"Pointer push delay (ms)", k:"number"},
            {p:"trigger.tapZone", l:"Tap zone", k:"bool"}
        ]
        SettingField {
            required property var modelData
            theme: cornerPage.theme; store: cornerPage.store
            path: modelData.p; label: modelData.l
            choices: modelData.p === "cornerIcon.source" ? ["default"].concat(cornerPage.store.validationResources.icons || []) : modelData.c || []
            kind: modelData.p === "cornerIcon.source" ? "editableChoice" : modelData.k || (choices.length ? "choice" : "text")
        }
    }
    Text {
        Layout.fillWidth: true
        text: "S fits 2 rings, M fits 3, L fits 4. The corner is capped at 45% of the shorter screen side; fewer controls may fit. Hide a ring before choosing a smaller size. The tap zone works in every icon mode when enabled."
        textFormat: Text.PlainText; wrapMode: Text.WordWrap
        color: cornerPage.theme.secondary; font.family: cornerPage.theme.font
    }
    CornerPreview { Layout.fillWidth: true; store: cornerPage.store; theme: cornerPage.theme }
    SettingsButton {
        theme: cornerPage.theme; text: "Reset Corner"
        onClicked: cornerPage.store.reset(["corner","size","tabStyle","cornerIcon","outputs","trigger"])
    }
}
