pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: behaviorPage
    required property var store
    required property var theme
    Repeater {
        model: [
            {p:"behavior.idleTimeoutS", l:"Idle timeout (seconds)", k:"number"},
            {p:"behavior.closeOnPointerLeave", l:"Close on pointer leave", k:"bool"},
            {p:"dialInteraction.fineEnabled", l:"Outward fine control", k:"bool"},
            {p:"dialInteraction.snap", l:"Magnetic snap", k:"bool"},
            {p:"options.volume.maxPercent", l:"Volume cap (%)", k:"choice", c:[100,150]},
            {p:"themePair.light", l:"Light theme", k:"text"},
            {p:"themePair.dark", l:"Dark theme", k:"text"},
            {p:"gameMode.animations", l:"Game mode: animations", k:"bool"},
            {p:"gameMode.blur", l:"Game mode: blur", k:"bool"},
            {p:"gameMode.shadows", l:"Game mode: shadows", k:"bool"},
            {p:"gameMode.gapsIn", l:"Game mode: inner gaps", k:"number"},
            {p:"gameMode.gapsOut", l:"Game mode: outer gaps", k:"number"}
        ]
        SettingField {
            required property var modelData
            theme: behaviorPage.theme; store: behaviorPage.store
            path: modelData.p; label: modelData.l
            kind: modelData.p.indexOf("themePair.") === 0 ? "editableChoice" : modelData.k
            choices: modelData.p.indexOf("themePair.") === 0 ? [""].concat(behaviorPage.store.validationResources.themes || []) : modelData.c || []
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Fine control slows the dial as you move outward. Snap attracts values to 0, 25, 50, 75 and 100%. Game mode applies the values above at runtime and restores the previous values when disabled.\nSettings: omarchy-shell shell toggle io.github.felipecpaiva.omadials\nFan keybind command: omarchy-shell omadials toggle"
        textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere
        color: behaviorPage.theme.secondary; font.family: behaviorPage.theme.font
    }
    SettingsButton {
        theme: behaviorPage.theme; text: "Reset Behavior"
        onClicked: behaviorPage.store.reset(["behavior","dialInteraction","options.volume.maxPercent","themePair","gameMode"])
    }
}
