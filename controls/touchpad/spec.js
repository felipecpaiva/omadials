.pragma library
const revertMs = 15000;
const watch = "file", timeout = 10000;
function read() { return ['omarchy-hw-touchpad']; }
function probe() { return read(); }
function parse(text, code) {
    const name = text.trim();
    return code || !name ? {availability:'unavailable', value:null, reason:'No touchpad attached'} :
        {availability:'available', value:true, reason:'', name:name};
}
function write(value) { return typeof value === 'boolean' ? ['omarchy','toggle','touchpad',value ? 'on' : 'off'] : null; }
function usableInput(text, code) {
    if (code) return false;
    try {
        const devices = JSON.parse(text);
        // Missing enabled information cannot prove that an input is usable.
        return ['keyboards','mice'].some(group => Array.isArray(devices[group]) && devices[group].some(d =>
            d && typeof d.name === 'string' && d.name.length > 0 && (d.enabled === true || d.enabled === 1)
            && !/virtual|power.button|video.bus|sleep.button/i.test(d.name)));
    } catch (error) { return false; }
}
