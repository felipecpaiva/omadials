pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Labels.js" as Labels

ColumnLayout {
    id: sourceRow
    required property var theme
    required property var store
    required property var control
    required property string entryPath
    readonly property var entry: store.value(entryPath) || ({})
    readonly property var sources: ["bluetoothBattery","wifiSignal","laptopBattery","penBattery"]
    property string selectedSource: entry.source || (["bluetoothBattery","wifiSignal","laptopBattery","penBattery"].indexOf(control.controlId || control.id) >= 0 ? (control.controlId || control.id) : "laptopBattery")
    property string identity: entry.deviceAddress || entry.devicePath || entry.interface || ""
    readonly property string deviceKey: selectedSource === "bluetoothBattery" ? "deviceAddress"
        : selectedSource === "penBattery" ? "devicePath" : "interface"
    function apply() {
        let next;
        try { next = JSON.parse(JSON.stringify(entryPath.split(".").reduce(function(a,k) { return a[k]; }, JSON.parse(store.rawText)))); }
        catch (e) { next = JSON.parse(JSON.stringify(entry)); }
        next.id = next.id || control.controlId || control.id;
        if (next.order === undefined) next.order = store.config.dials.concat(store.config.readoutRings)
            .reduce(function(n,e) { return Math.max(n,e.order + 1); },0);
        next.source = selectedSource;
        delete next.deviceAddress; delete next.devicePath; delete next.interface;
        if (selectedSource !== "laptopBattery") next[deviceKey] = identity || (deviceKey === "interface" ? "auto" : "");
        next.style = Object.assign({}, next.style || {}, {knob:"none"});
        store.set(entryPath, next);
    }
    RowLayout {
        Text { text: "Readout source"; color: sourceRow.theme.text; font.family: sourceRow.theme.font }
        ComboBox {
            model: Labels.options(sourceRow.sources)
            textRole: "label"
            currentIndex: sourceRow.sources.indexOf(sourceRow.selectedSource)
            Accessible.name: "Readout source"
            palette.button: sourceRow.theme.off; palette.buttonText: sourceRow.theme.text
            palette.window: sourceRow.theme.surface; palette.text: sourceRow.theme.text
            palette.highlight: sourceRow.theme.accent; palette.highlightedText: sourceRow.theme.ink
            onActivated: { sourceRow.selectedSource = sourceRow.sources[currentIndex]; sourceRow.identity = ""; }
        }
    }
    TextField {
        Layout.fillWidth: true
        visible: sourceRow.selectedSource !== "laptopBattery"
        text: sourceRow.identity
        placeholderText: sourceRow.deviceKey === "interface" ? "Interface, or auto" : sourceRow.deviceKey === "deviceAddress" ? "Bluetooth address" : "UPower device path"
        Accessible.name: "Readout device identity"
        color: sourceRow.theme.text; font.family: sourceRow.theme.font
        background: Rectangle { color: sourceRow.theme.off; border.color: sourceRow.theme.edge }
        onTextEdited: sourceRow.identity = text
    }
    Repeater {
        model: sourceRow.control.detailRows || []
        SettingsButton {
            required property var modelData
            theme: sourceRow.theme; text: modelData.label
            onClicked: sourceRow.identity = modelData.key
        }
    }
    SettingsButton { theme: sourceRow.theme; text: "Apply source and device"; onClicked: sourceRow.apply() }
}
