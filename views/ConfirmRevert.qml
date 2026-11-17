import QtQuick
import "details"
Column {
    id: confirmation
    property var theme
    property var model
    property var session
    spacing: 8
    visible: !!session && session.phase !== "idle" && session.phase !== "reading"
    DetailText {
        theme: confirmation.theme
        text: !confirmation.session ? "" : confirmation.session.phase === "confirm" ?
            "Keep refresh rate? Reverting in " + confirmation.session.remaining + " s" : confirmation.session.phase
    }
    DetailButton {
        theme: confirmation.theme; model: confirmation.model
        text: "Keep"; enabled: !!confirmation.session && confirmation.session.phase === "confirm"
        onClicked: confirmation.session.confirm()
    }
    DetailButton {
        theme: confirmation.theme; model: confirmation.model
        text: "Revert"; enabled: !!confirmation.session && ["confirm","revertFailed"].includes(confirmation.session.phase)
        onClicked: confirmation.session.revert()
    }
}
