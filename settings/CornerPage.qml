pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
ColumnLayout {
    id: cornerPage
    required property var store
    required property var theme
    property QtObject screenModeStore: QtObject {
        function value(path) { return cornerPage.store.value(path) }
        function set(path, value) {
            if (value === "named" && !cornerPage.store.config.outputs.names.length && Quickshell.screens.length)
                return cornerPage.store.setMany([{path:path,value:value},{path:"outputs.names",value:[Quickshell.screens[0].name]}]);
            return cornerPage.store.set(path,value);
        }
    }
    spacing: 16
    SettingsCard {
        theme: cornerPage.theme; title: "Where"
        PictureChoices { theme: cornerPage.theme; store: cornerPage.store; path: "corner"; label: "Corner"; choices: ["top-left","top-right","bottom-left","bottom-right"]; pictures: ["◜","◝","◟","◞"] }
        SettingField { theme: cornerPage.theme; store: cornerPage.screenModeStore; path: "outputs.mode"; label: "Screens"; hint: "Choose where the corner appears."; choices: ["all","focused","named"]; choiceLabels: ["All screens","Focused screen","Choose screens"] }
        Repeater {
            model: cornerPage.store.config.outputs.mode === "named" ? Quickshell.screens : []
            ScreenChoice { required property var modelData; theme: cornerPage.theme; store: cornerPage.store; screenName: modelData.name }
        }
    }
    SettingsCard {
        theme: cornerPage.theme; title: "Size"
        SizeChoices { theme: cornerPage.theme; store: cornerPage.store }
    }
    SettingsCard {
        theme: cornerPage.theme; title: "Corner tab"
        PictureChoices { theme: cornerPage.theme; store: cornerPage.store; path: "tabStyle"; label: "Style"; choices: ["rings2knob","rings3","rings3knob"]; pictures: ["◔ ◎","◎ ◎ ◎","◔ ◎ ◎"] }
        IconPicker { theme: cornerPage.theme; store: cornerPage.store; path: "cornerIcon.source"; label: "Your own icon" }
        SettingField { theme: cornerPage.theme; store: cornerPage.store; path: "cornerIcon.mode"; label: "Show the tab"; hint: "The corner can open even when the tab is hidden."; choices: ["always","onApproach","never"]; choiceLabels: ["Always","When the pointer is near","Never"] }
        SettingField { theme: cornerPage.theme; store: cornerPage.store; path: "cornerIcon.aboveWindows"; label: "Above windows"; hint: "Off: the tab hides behind windows; the corner still opens"; kind: "bool" }
    }
    SettingsCard {
        theme: cornerPage.theme; title: "Opening"
        OpeningSettings { theme: cornerPage.theme; store: cornerPage.store }
    }
}
