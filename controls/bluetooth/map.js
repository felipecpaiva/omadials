.pragma library
function rows(devices) {
    return devices.map(d => ({key: d.address, label: d.name || d.deviceName || d.address,
        sub: d.batteryAvailable ? Math.round(d.battery * 100) + '%' : '', state: d.connected, icon: d.icon || ''}));
}
function reading(device) { return device && device.connected && device.batteryAvailable ? Math.round(device.battery * 100) : null; }
