pragma ComponentBehavior: Bound
import QtQuick
Column {
    id: themeDetail
    property var theme
    property var control
    property var model
    spacing: 8
    DetailText { theme: themeDetail.theme; text: themeDetail.control ? themeDetail.control.lastError : ""; visible: text.length > 0 }
    DetailText { theme: themeDetail.theme; text: "Loading themes"; visible: !themeDetail.control || !themeDetail.control.detailRows.length }
    Repeater {
        model: themeDetail.control ? themeDetail.control.detailRows : []
        DetailButton {
            required property var modelData
            theme: themeDetail.theme; model: themeDetail.model
            text: (themeDetail.control.currentTheme === modelData.key ? "✓ " : "") + modelData.label
            enabled: themeDetail.control.writeState !== "pending"
            onClicked: themeDetail.control.choose(modelData.key)
        }
    }
}
