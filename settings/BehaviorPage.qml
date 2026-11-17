pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: behaviorPage
    required property var store
    required property var theme
    required property var registry
    spacing: 16
    SettingsCard {
        theme: behaviorPage.theme; title: "Closing"
        SettingField { theme: behaviorPage.theme; store: behaviorPage.store; path: "behavior.idleTimeoutS"; label: "Close after"; hint: "Seconds without activity."; choices: [0,5,10,20,30]; choiceLabels: ["Never","5 s","10 s","20 s","30 s"] }
        SettingField { theme: behaviorPage.theme; store: behaviorPage.store; path: "behavior.closeOnPointerLeave"; label: "Close when the pointer leaves"; hint: "Dismiss the corner when you move away."; kind: "bool" }
    }
    SettingsCard {
        theme: behaviorPage.theme; title: "Dials"
        SettingField { theme: behaviorPage.theme; store: behaviorPage.store; path: "dialInteraction.fineEnabled"; label: "Fine control when you drag away from the ring"; hint: "Move outward for smaller adjustments."; kind: "bool" }
        SettingField { theme: behaviorPage.theme; store: behaviorPage.store; path: "dialInteraction.snap"; label: "Snap to 0, 25, 50, 75 and 100 %"; hint: "Pause at these common values as you drag."; kind: "bool" }
        SettingField { theme: behaviorPage.theme; store: behaviorPage.store; path: "options.volume.maxPercent"; label: "Volume can go above 100 %"; hint: "Choose the maximum volume. Amplification may distort sound."; choices: [100,150]; choiceLabels: ["Off, maximum 100 %","On, maximum 150 %"] }
    }
    ThemePairCard { theme: behaviorPage.theme; store: behaviorPage.store; registry: behaviorPage.registry }
    SettingsCard {
        theme: behaviorPage.theme; title: "Game mode"
        HelpText { theme: behaviorPage.theme; text: "When game mode is on, turn off:" }
        Repeater {
            model: [{p:"animations",l:"Animations"},{p:"blur",l:"Blur"},{p:"shadows",l:"Shadows"}]
            SettingField { required property var modelData; theme: behaviorPage.theme; store: behaviorPage.store; path: "gameMode." + modelData.p; label: modelData.l; hint: "Restore the previous setting when game mode ends."; kind: "bool"; inverted: true }
        }
        GapSwitch { theme: behaviorPage.theme; store: behaviorPage.store }
    }
}
