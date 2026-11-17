pragma ComponentBehavior: Bound
import QtQuick
import ".."
import "../../controls/brightness/displays.js" as Displays
Column {
    id: displayDetail
    property var theme
    property var model
    property var control
    readonly property var session: control ? control.displays : null
    spacing: 8
    onSessionChanged: if (session) session.refresh()
    DetailText { theme: displayDetail.theme; text: displayDetail.session ? displayDetail.session.error : ""; visible: text.length > 0 }
    DetailText { theme: displayDetail.theme; text: "Loading displays"; visible: !displayDetail.session || !displayDetail.session.monitors.length }
    Repeater {
        model: displayDetail.session ? displayDetail.session.monitors : []
        Column {
            id: monitorRow
            required property var modelData
            width: displayDetail.width
            LevelSlider {
                theme: displayDetail.theme; model: displayDetail.model
                label: monitorRow.modelData.name
                minimum: 1
                enabled: !!displayDetail.session && displayDetail.session.levels[monitorRow.modelData.name] !== null && displayDetail.session.levels[monitorRow.modelData.name] !== undefined
                reading: enabled ? displayDetail.session.levels[monitorRow.modelData.name] : 0
                onCommitted: value => displayDetail.session.setBrightness(monitorRow.modelData,value)
            }
            DetailText {
                theme: displayDetail.theme
                text: "Brightness unavailable"; visible: displayDetail.session.levels[monitorRow.modelData.name] === null
            }
        }
    }
    ConfirmRevert { width: parent.width; theme: displayDetail.theme; model: displayDetail.model; session: displayDetail.session }
    DetailText { theme: displayDetail.theme; text: displayDetail.session && displayDetail.session.focused ? displayDetail.session.focused.name + " refresh rate" : "No focused monitor" }
    Repeater {
        model: displayDetail.session && displayDetail.session.focused ? Displays.rates(displayDetail.session.focused) : []
        DetailButton {
            required property string modelData
            theme: displayDetail.theme; model: displayDetail.model
            text: modelData
            enabled: displayDetail.session.phase === "idle"
            onClicked: displayDetail.session.choose(modelData)
        }
    }
}
