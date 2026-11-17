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
            text: modelData.code && modelData.code !== "io_error"
                ? modelData.path + ": " + ({parse_error:"The file is not valid JSON. Fix the file or Reset all.",newer_version:"This file needs a newer version of omadials Settings.",wrong_type:"This setting has the wrong value type.",out_of_range:"This value is outside the allowed range.",unknown_value:"This value or setting is not recognized.",unknown_control:"This control is not recognized.",duplicate_control:"This control or ring order is repeated.",wrong_placement:"This field or control cannot be used here.",over_capacity:"Too many rings are shown for this size."})[modelData.code]
                : modelData.message; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere
            color: problemsBanner.theme.text; font.family: problemsBanner.theme.font
        }
    }
}
