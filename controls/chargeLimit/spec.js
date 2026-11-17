.pragma library
const watch = "poll", interval = 4000, timeout = 10000;
function read() { return ['cat','/sys/class/power_supply/BAT0/charge_control_end_threshold']; }
function probe() { return read(); }
function parse(text, code) {
    const n = Number(text.trim());
    return !code && text.trim() && Number.isInteger(n) && n >= 20 && n <= 100 ?
        {availability:'available', value:n, reason:''} : {availability:code ? 'unavailable':'error', value:null, reason:'Cannot read charge limit'};
}
function write(v) { return Number.isInteger(v) && v >= 20 && v <= 100 ? ['asusctl','battery','limit',String(v)] : null; }

function normalize(v) { return Number.isFinite(v) ? Math.round(Math.max(20, Math.min(100, v))) : null; }
