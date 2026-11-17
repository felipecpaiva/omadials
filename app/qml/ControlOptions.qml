import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: options
    required property var theme
    required property var store
    required property var control
    required property string entryPath
    required property string group
    property var catalogEntry: ({})
    readonly property var entry: store.value(entryPath) || ({})
    Layout.fillWidth: true
    spacing: 12
    Repeater {
        model: options.group === "toggles" ? ["tapAction","holdAction"] : []
        SettingField {
            required property string modelData
            theme: options.theme; store: options.store; path: options.entryPath + "." + modelData
            label: modelData === "tapAction" ? qsTr("When tapped") : qsTr("When held")
            help: modelData === "tapAction" ? qsTr("A quick press on this toggle.") : qsTr("Press and hold for more options.")
            kind: "choice"
            choices: options.catalogEntry[modelData === "tapAction" ? "tapActions" : "holdActions"] || ["switch","quickDetail"]
            words: choices.map(function(v) { return ({switchRadio:qsTr("Switch on or off"),switchPower:qsTr("Switch on or off"),switch:qsTr("Switch on or off"),quickDetail:qsTr("Open the quick list"),fullWindow:qsTr("Open the full window"),nextStep:qsTr("Choose the next level"),togglePair:qsTr("Switch light or dark theme")})[v] })
        }
    }
    // "Off" has no form in the config until a style is picked, so it only reveals the choices here.
    property bool ownStyle: false
    readonly property bool usesCommon: {
        let style = entry.style, common = store.config.ringStyle;
        return !style || Object.keys(style).every(function(k) { return style[k] === common[k] || options.group === "readoutRings" && k === "knob" });
    }
    RowLayout {
        visible: options.group !== "toggles"; Layout.fillWidth: true; spacing: 16
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4
            Label { text: qsTr("Use the common style") }
            Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; color: options.theme.secondary; font.pixelSize: 12; text: qsTr("The style set in All rings. Turn off to give this ring its own look.") }
        }
        Switch {
            objectName: "commonStyleSwitch"
            checked: options.usesCommon && !options.ownStyle
            Accessible.name: qsTr("Use the common style")
            onToggled: {
                options.ownStyle = !checked;
                if (!checked) return;
                let entry = JSON.parse(JSON.stringify(options.entry)); delete entry.style;
                if (options.group === "readoutRings") entry.style = {knob:"none"};
                options.store.set(options.entryPath,entry);
            }
        }
    }
    RingStyle {
        visible: options.group !== "toggles" && (options.ownStyle || !options.usesCommon)
        theme: options.theme; store: options.store; path: options.entryPath + ".style"; readout: options.group === "readoutRings"
    }
    Loader {
        active: options.group === "readoutRings"; visible: active; Layout.fillWidth: true
        sourceComponent: ReadoutSourceRow { theme: options.theme; store: options.store; control: options.control; entryPath: options.entryPath }
    }
    SettingField {
        visible: options.group === "dials" && options.control.id !== "chargeLimit"
        theme: options.theme; store: options.store; path: "options." + options.control.id + ".wheelStep"
        label: qsTr("Wheel step"); help: qsTr("Percentage points per wheel tick, from 1 to 25."); kind: "number"
    }
}
