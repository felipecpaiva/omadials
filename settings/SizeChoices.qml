pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../logic/Geometry.js" as Geometry
ColumnLayout {
    id: sizeChoices
    required property var theme
    required property var store
    Repeater {
        model: [{value:"S",label:"Compact",help:"Two rings for the essentials."},{value:"M",label:"Normal",help:"Three rings with room for everyday controls."},{value:"L",label:"Large",help:"Four rings for more controls."}]
        ColumnLayout {
            id: sizeOption
            required property var modelData
            Layout.fillWidth: true
            SettingsButton { Layout.fillWidth: true; theme: sizeChoices.theme; text: sizeOption.modelData.label; selected: sizeChoices.store.config.size === sizeOption.modelData.value; onClicked: sizeChoices.store.set("size", sizeOption.modelData.value) }
            HelpText {
                theme: sizeChoices.theme
                readonly property var cap: Geometry.capacity(sizeOption.modelData.value, Quickshell.screens.length ? Math.min(Quickshell.screens[0].width,Quickshell.screens[0].height) : 1080)
                text: sizeOption.modelData.help + (cap.capped ? " " + sizeOption.modelData.label + " is limited to " + Math.round(cap.R) + " px on this screen." : "")
            }
        }
    }
}
