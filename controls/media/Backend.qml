import QtQuick
import Quickshell.Services.Mpris
import "../../core"
import "map.js" as Map
ControlBase {
    id: backend
    property var players: Mpris.players.values
    property var player: players.find(p => p.dbusName === parameter.player) || players[0] || null
    kind: "toggle"
    availability: player ? "available" : "unavailable"
    reason: player ? "" : "No media player"
    value: player ? player.isPlaying : null
    valueText: player ? player.trackTitle || player.identity : "No media player"
    detailKind: "custom"
    property url detailComponent: Qt.resolvedUrl("../../views/details/MediaDetail.qml")
    detailRows: Map.rows(players).concat(player ? [
        {key: "previous", label: "Previous", sub: "", state: player.canGoPrevious, icon: ""},
        {key: "play", label: player.isPlaying ? "Pause" : "Play", sub: "", state: player.canTogglePlaying, icon: ""},
        {key: "next", label: "Next", sub: "", state: player.canGoNext, icon: ""}] : [])
    function set(v) {
        if (!player) return
        if (v && player.canPlay) player.play()
        else if (!v && player.canPause) player.pause()
    }
    function activate(key) {
        if (!player) return
        if (key === "play" && player.canTogglePlaying) player.togglePlaying()
        else if (key === "previous" && player.canGoPrevious) player.previous()
        else if (key === "next" && player.canGoNext) player.next()
        else if (players.some(p => p.dbusName === key)) parameter = {player: key}
    }
}
