pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Ui as Ui
RowLayout {
    id: gapSwitch
    required property var theme
    required property var store
    property var previousGaps: [5,10]
    HelpText { theme: gapSwitch.theme; text: "Window gaps become 0
Restore the previous gaps when game mode ends." }
    Ui.ToggleSwitch {
        checked: gapSwitch.store.config.gameMode.gapsIn === 0 && gapSwitch.store.config.gameMode.gapsOut === 0
        foreground: gapSwitch.theme.text; accent: gapSwitch.theme.accent
        Accessible.name: "Window gaps become 0"
        onToggled: {
            const g = gapSwitch.store.config.gameMode;
            if (!checked) gapSwitch.previousGaps = [g.gapsIn,g.gapsOut];
            gapSwitch.store.setMany([{path:"gameMode.gapsIn",value:checked ? gapSwitch.previousGaps[0] : 0},{path:"gameMode.gapsOut",value:checked ? gapSwitch.previousGaps[1] : 0}]);
        }
    }
}
