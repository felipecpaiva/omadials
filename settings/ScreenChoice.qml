pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Ui as Ui
RowLayout {
    id: screenChoice
    required property var theme
    required property var store
    required property string screenName
    Layout.fillWidth: true
    HelpText { theme: screenChoice.theme; text: screenChoice.screenName }
    Ui.ToggleSwitch {
        checked: screenChoice.store.config.outputs.names.indexOf(screenChoice.screenName) >= 0
        foreground: screenChoice.theme.text; accent: screenChoice.theme.accent
        Accessible.name: screenChoice.screenName
        onToggled: {
            let names = screenChoice.store.config.outputs.names.filter(n => n !== screenChoice.screenName);
            if (!checked) names.push(screenChoice.screenName);
            screenChoice.store.setMany([{path:"outputs.names",value:names},{path:"outputs.mode",value:names.length ? "named" : "all"}]);
        }
    }
}
