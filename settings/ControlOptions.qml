pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Ui as Ui

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
            label: modelData === "tapAction" ? "When tapped" : "When held"
            kind: "choice"
            choiceLabels: choices.map(v => ({switchRadio:"Switch on or off",switchPower:"Switch on or off",switch:"Switch on or off",quickDetail:"Open the quick list",fullWindow:"Open the full window",nextStep:"Go to the next level",togglePair:"Switch light or dark"})[v] || v)
            hint: "Choose what this gesture does."
            choices: controlOptions.catalogEntry[modelData === "tapAction" ? "tapActions" : "holdActions"] || controlOptions.fallbackActions
        }
    }
    // Defaults store a style equal to the common one, so "common" compares values; the flag lets the switch turn off.
    property bool customising: false
    readonly property bool common: !entry.style || ["track","knob","thickness"].every(k => controlOptions.group === "readoutRings" && k === "knob" || controlOptions.entry.style[k] === controlOptions.store.config.ringStyle[k])
    RowLayout {
        visible: controlOptions.group !== "toggles"
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "Use the common style"; color: controlOptions.theme.text; font.family: controlOptions.theme.font }
            HelpText { theme: controlOptions.theme; text: "Off: this ring gets its own track, knob and thickness." }
        }
        Ui.ToggleSwitch {
            checked: controlOptions.common && !controlOptions.customising
            foreground: controlOptions.theme.text; accent: controlOptions.theme.accent
            Accessible.name: "Use the common style"
            // checked still holds the old value here, as in SettingField.
            onToggled: {
                controlOptions.customising = checked;
                if (checked) return;
                let next = Object.assign({}, controlOptions.entry); delete next.style;
                if (controlOptions.group === "readoutRings") next.style = {knob:"none"};  // display rings never draw a knob
                controlOptions.store.set(controlOptions.entryPath, next);
            }
        }
    }
    RingStyleFields {
        visible: controlOptions.group !== "toggles" && (controlOptions.customising || !controlOptions.common)
        theme: controlOptions.theme; store: controlOptions.store
        stylePath: controlOptions.entryPath + ".style"; readout: controlOptions.group === "readoutRings"
    }
    ReadoutSourceRow {
        visible: controlOptions.group === "readoutRings"
        theme: controlOptions.theme; store: controlOptions.store
        control: controlOptions.control; entryPath: controlOptions.entryPath
    }
    SettingField {
        visible: controlOptions.group === "dials" && !!controlOptions.catalogEntry.options?.wheelStep
        theme: controlOptions.theme; store: controlOptions.store
        path: "options." + (controlOptions.control.controlId || controlOptions.control.id) + ".wheelStep"; label: "Wheel step"; hint: "Percentage points per wheel notch."; minimum: 1; kind: "number"
    }
    SettingField {
        visible: (controlOptions.control.controlId || controlOptions.control.id) === "brightness"
        theme: controlOptions.theme; store: controlOptions.store
        path: "options.brightness.monitor"; label: "Brightness monitor"; choices: ["auto"]
    }
}
