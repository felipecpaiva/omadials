pragma ComponentBehavior: Bound
import QtQuick
Column {
    id: mediaDetail
    property var theme
    property var control
    property var model
    readonly property var player: control ? control.player : null
    spacing: 8
    DetailText { theme: mediaDetail.theme; text: mediaDetail.player ? mediaDetail.player.trackTitle || "Unknown title" : "No media playing" }
    DetailText { theme: mediaDetail.theme; text: mediaDetail.player ? mediaDetail.player.trackArtist || "Unknown artist" : ""; visible: !!mediaDetail.player }
    DetailText { theme: mediaDetail.theme; text: mediaDetail.player ? mediaDetail.player.identity : ""; visible: !!mediaDetail.player }
    DetailText {
        theme: mediaDetail.theme; visible: !!mediaDetail.player
        text: mediaDetail.player && mediaDetail.player.positionSupported && mediaDetail.player.lengthSupported ?
            Math.floor(mediaDetail.player.position) + " / " + Math.floor(mediaDetail.player.length) + " seconds" : "Progress unavailable"
    }
    Rectangle {
        width: parent.width; height: 4; color: mediaDetail.theme.track
        Rectangle {
            height: parent.height; color: mediaDetail.theme.accent
            width: parent.width * (mediaDetail.player && mediaDetail.player.length > 0 ? Math.max(0,Math.min(1,mediaDetail.player.position/mediaDetail.player.length)) : 0)
        }
    }
    Timer {
        interval: 1000; repeat: true
        running: !!mediaDetail.player && mediaDetail.player.isPlaying && mediaDetail.player.positionSupported
        onTriggered: mediaDetail.player.positionChanged()
    }
    Row {
        width: parent.width; spacing: 8; visible: !!mediaDetail.player
        DetailButton { theme: mediaDetail.theme; model: mediaDetail.model; box: ({x:0,y:0,width:(parent.width-16)/3,height:48}); text: "Previous"; enabled: !!mediaDetail.player && mediaDetail.player.canGoPrevious; onClicked: mediaDetail.control.activate("previous") }
        DetailButton { theme: mediaDetail.theme; model: mediaDetail.model; box: ({x:0,y:0,width:(parent.width-16)/3,height:48}); text: mediaDetail.player && mediaDetail.player.isPlaying ? "Pause" : "Play"; enabled: !!mediaDetail.player && mediaDetail.player.canTogglePlaying; onClicked: mediaDetail.control.activate("play") }
        DetailButton { theme: mediaDetail.theme; model: mediaDetail.model; box: ({x:0,y:0,width:(parent.width-16)/3,height:48}); text: "Next"; enabled: !!mediaDetail.player && mediaDetail.player.canGoNext; onClicked: mediaDetail.control.activate("next") }
    }
    Repeater {
        model: mediaDetail.control ? mediaDetail.control.players : []
        DetailButton {
            required property var modelData
            theme: mediaDetail.theme; model: mediaDetail.model
            text: (modelData === mediaDetail.player ? "✓ " : "") + modelData.identity
            onClicked: mediaDetail.control.activate(modelData.dbusName)
        }
    }
}
