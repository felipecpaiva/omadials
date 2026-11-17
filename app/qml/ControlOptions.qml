pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: controlOptions
    required property var theme
    required property var store
    required property var control
    required property string entryPath
    required property string group
    property var catalogEntry: ({})
    readonly property var entry: store.value(entryPath) || ({})
    readonly property var fallbackActions: {
        switch ((control.controlId || control.id)) {
        case "wifi": return ["switchRadio","quickDetail","fullWindow"];
        case "bluetooth": return ["switchPower","quickDetail","fullWindow"];
        case "kbdlight": return ["nextStep","quickDetail"];
        case "theme": return ["togglePair","quickDetail"];
        case "media": return ["quickDetail"];
        default: return ["switch","quickDetail"];
        }
    }
    Repeater {
        model: controlOptions.group === "toggles" ? ["tapAction","holdAction"] : []
        SettingField {
            required property string modelData
            theme: controlOptions.theme; store: controlOptions.store
            path: controlOptions.entryPath + "." + modelData
            label: modelData === "tapAction" ? "Tap action" : "Hold action"
            kind: "choice"
            choices: controlOptions.catalogEntry[modelData === "tapAction" ? "tapActions" : "holdActions"] || controlOptions.fallbackActions
        }
    }
    Repeater {
        model: controlOptions.group !== "toggles" && controlOptions.entry.id ? ["track","knob","thickness"] : []
        SettingField {
            required property string modelData
            theme: controlOptions.theme; store: controlOptions.store
            path: controlOptions.entryPath + ".style." + modelData; label: "Ring " + modelData
            kind: "choice"
            choices: modelData === "track" ? ["solid","dashed","dotted","segmented"] : modelData === "knob"
                ? (controlOptions.group === "readoutRings" ? ["none"] : ["round","bar","none"]) : ["thin","normal","bold"]
        }
    }
    ReadoutSourceRow {
        visible: controlOptions.group === "readoutRings"
        theme: controlOptions.theme; store: controlOptions.store
        control: controlOptions.control; entryPath: controlOptions.entryPath
    }
    SettingField {
        visible: controlOptions.group === "dials"
        theme: controlOptions.theme; store: controlOptions.store
        path: "options." + (controlOptions.control.controlId || controlOptions.control.id) + ".wheelStep"; label: "Wheel step (%)"; kind: "number"
    }
    SettingField {
        visible: (controlOptions.control.controlId || controlOptions.control.id) === "brightness"
        theme: controlOptions.theme; store: controlOptions.store
        path: "options.brightness.monitor"; label: "Brightness monitor"; hint: "auto"
    }
}
