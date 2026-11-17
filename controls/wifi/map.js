.pragma library
function rows(devices, openSecurity) {
    const result = [];
    devices.forEach(d => (d.networks || []).forEach(n => result.push({key: d.name + '/' + n.name,
        label: n.name, sub: Math.round(n.signalStrength * 100) + '%', state: n.connected, icon: '',
        known: n.known, secured: n.security !== openSecurity})));
    return result;
}
function action(network) { return network.known ? 'saved' : network.secured ? 'fullWindow' : 'connect'; }
