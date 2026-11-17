pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Ui as Ui
ColumnLayout {
    id: sourceRow
    required property var theme
    required property var store
    required property var control
    required property string entryPath
    readonly property var entry: store.value(entryPath) || ({})
    readonly property var devices: Bluetooth.devices.values
    visible: entry.source === "bluetoothBattery"
    HelpText { theme: sourceRow.theme; text: "Bluetooth device" }
    Ui.Dropdown {
        Layout.fillWidth: true
        showLabel: false
        options: sourceRow.devices.map(d => ({value:d.address,label:d.name || d.address}))
        value: sourceRow.entry.deviceAddress || ""
        foreground: sourceRow.theme.text; background: sourceRow.theme.surface; accent: sourceRow.theme.accent; fontFamily: sourceRow.theme.font
        onChanged: v => sourceRow.store.set(sourceRow.entryPath + ".deviceAddress", v)
    }
}
