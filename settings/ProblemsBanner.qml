pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: problemsBanner
    required property var store
    required property var registry
    required property var theme
    readonly property var problems: store.errors.concat((registry.controls || []).filter(function(c) {
        return c.availability === "error";
    }).map(function(c) { return { message: c.label + ": " + c.reason }; }))
    visible: problems.length > 0
    Text {
        Layout.fillWidth: true
        text: "Settings problems. Runtime defaults are used for invalid fields; the file is preserved until edited."
        textFormat: Text.PlainText; wrapMode: Text.WordWrap
        color: problemsBanner.theme.warn; font.family: problemsBanner.theme.font
    }
    Repeater {
        model: problemsBanner.problems
        Text {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.message; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere
            color: problemsBanner.theme.text; font.family: problemsBanner.theme.font
        }
    }
}
