pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
Column {
    id: audioDetail
    property var theme
    property var control
    property var model
    spacing: 8
    PwObjectTracker { objects: audioDetail.control ? audioDetail.control.devices.concat(audioDetail.control.streams) : [] }
    DetailText { theme: audioDetail.theme; text: audioDetail.control && audioDetail.control.inputDevice ? "Input device" : "Output device" }
    Repeater {
        model: audioDetail.control ? audioDetail.control.devices : []
        DetailButton {
            required property var modelData
            theme: audioDetail.theme; model: audioDetail.model
            text: (audioDetail.control.node === modelData ? "✓ " : "") + (modelData.description || modelData.name)
            onClicked: audioDetail.control.selectDevice(modelData)
        }
    }
    DetailText { theme: audioDetail.theme; visible: !!audioDetail.control && !audioDetail.control.devices.length; text: "No audio devices" }
    DetailButton {
        theme: audioDetail.theme; model: audioDetail.model
        enabled: !!audioDetail.control && !!audioDetail.control.audio
        text: audioDetail.control && audioDetail.control.muted ? "Unmute" : "Mute"
        onClicked: audioDetail.control.activate("mute")
    }
    Repeater {
        model: audioDetail.control && !audioDetail.control.inputDevice ? audioDetail.control.streams : []
        Column {
            id: streamRow
            required property var modelData
            width: audioDetail.width; spacing: 4
            LevelSlider {
                theme: audioDetail.theme; model: audioDetail.model
                label: streamRow.modelData.properties["application.name"] || streamRow.modelData.name
                reading: streamRow.modelData.audio ? streamRow.modelData.audio.volume*100 : 0
                maximum: audioDetail.control.capPercent
                onCommitted: value => { if (streamRow.modelData.audio) streamRow.modelData.audio.volume = value/100 }
            }
            DetailButton {
                theme: audioDetail.theme; model: audioDetail.model
                text: streamRow.modelData.audio && streamRow.modelData.audio.muted ? "Unmute app" : "Mute app"
                onClicked: { const a = streamRow.modelData.audio; if (a) a.muted = !a.muted }
            }
        }
    }
    DetailButton {
        theme: audioDetail.theme; model: audioDetail.model
        visible: !!audioDetail.control && !audioDetail.control.inputDevice
        text: "Media"; onClicked: audioDetail.model.openDetail("media")
    }
}
