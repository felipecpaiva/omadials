pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.Ui as Ui
SettingsCard {
    id: addReadout
    required property var store
    property string selectedSource: "laptopBattery"
    property string selectedDevice: ""
    title: "Add a display ring"
    required property var registry
    SettingsResources { id: devices; loadIcons: false; loadPens: true; registry: addReadout.registry; store: addReadout.store }
    HelpText { theme: addReadout.theme; text: "Display rings show a reading without a dial knob." }
    Ui.Dropdown {
        Layout.fillWidth: true; showLabel: false
        options: [{value:"bluetoothBattery",label:"Bluetooth device battery"},{value:"wifiSignal",label:"Wi-Fi signal"},{value:"laptopBattery",label:"Laptop battery"},{value:"penBattery",label:"Pen battery"}]
        value: addReadout.selectedSource
        foreground: addReadout.theme.text; background: addReadout.theme.surface; accent: addReadout.theme.accent; fontFamily: addReadout.theme.font
        onChanged: v => { addReadout.selectedSource = v; addReadout.selectedDevice = "" }
    }
    Ui.Dropdown {
        visible: addReadout.selectedSource === "bluetoothBattery" || addReadout.selectedSource === "penBattery"
        Layout.fillWidth: true; showLabel: false
        options: addReadout.selectedSource === "penBattery" ? devices.penDevices : Bluetooth.devices.values.map(d => ({value:d.address,label:d.name || d.address}))
        value: addReadout.selectedDevice
        foreground: addReadout.theme.text; background: addReadout.theme.surface; accent: addReadout.theme.accent; fontFamily: addReadout.theme.font
        onChanged: v => addReadout.selectedDevice = v
    }
    HelpText { theme: addReadout.theme; visible: addReadout.selectedSource === "penBattery" && !devices.penDevices.length; text: "No pen battery found on this machine. Connect your pen and reopen settings to check again." }
    SettingsButton {
        theme: addReadout.theme; text: "Add display ring"
        enabled: ["bluetoothBattery","penBattery"].indexOf(addReadout.selectedSource) < 0 || !!addReadout.selectedDevice
        onClicked: {
            const cfg = addReadout.store.config;
            const id = "display" + Date.now();
            const order = cfg.dials.concat(cfg.readoutRings).reduce((n,e) => Math.max(n,e.order + 1),0);
            let entry = {id:id,source:addReadout.selectedSource,order:order,style:{knob:"none"}};
            if (entry.source === "bluetoothBattery") entry.deviceAddress = addReadout.selectedDevice;
            if (entry.source === "penBattery") entry.devicePath = addReadout.selectedDevice;
            if (entry.source === "wifiSignal") entry.interface = "auto";
            addReadout.store.setMany([{path:"readoutRings",value:cfg.readoutRings.concat([entry])},{path:"controls." + id,value:{shown:true,icon:"default"}}]);
        }
    }
}
