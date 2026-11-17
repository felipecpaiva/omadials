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
    RingStyle { visible: options.group !== "toggles"; theme: options.theme; store: options.store; path: options.entryPath + ".style"; readout: options.group === "readoutRings" }
    Button {
        visible: options.group !== "toggles"; text: qsTr("Use the common style")
        onClicked: {
            let entry=JSON.parse(JSON.stringify(options.entry)); delete entry.style;
            if(options.group === "readoutRings") entry.style={knob:"none"};
            options.store.set(options.entryPath,entry);
        }
    }
    ReadoutSourceRow { visible: options.group === "readoutRings"; theme: options.theme; store: options.store; control: options.control; entryPath: options.entryPath }
    SettingField {
        visible: options.group === "dials" && options.control.id !== "chargeLimit"
        theme: options.theme; store: options.store; path: "options." + options.control.id + ".wheelStep"
        label: qsTr("Wheel step"); help: qsTr("Percentage points per wheel tick, from 1 to 25."); kind: "number"
    }
}
