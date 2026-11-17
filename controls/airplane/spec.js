.pragma library
function parse(text, code) {
    try {
        if (code) throw new Error('rfkill failed');
        const radios = JSON.parse(text).rfkilldevices;
        if (!Array.isArray(radios) || !radios.length) throw new Error('No radios');
        if (!radios.every(r => Number.isInteger(r.id) && typeof r.type === 'string' && ['blocked','unblocked'].indexOf(r.soft) >= 0)) throw new Error('Invalid rfkill state');
        return {availability: 'available', value: radios.every(r => r.soft === 'blocked'), reason: '', radios: radios};
    } catch (error) { return {availability: 'error', value: null, reason: String(error)}; }
}
function restore(radios) {
    return radios.filter(r => r.soft === 'unblocked').map(r => r.type === 'bluetooth' ?
        ['omarchy-bluetooth-power','on'] : ['rfkill','unblock',String(r.id)]);
}
function journalValid(v) { return v && v.version === 1 && Array.isArray(v.radios) && v.radios.length && v.radios.every(r => Number.isInteger(r.id) && ['blocked','unblocked'].indexOf(r.soft) >= 0 && typeof r.type === 'string'); }
