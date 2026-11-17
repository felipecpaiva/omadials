.pragma library
const SUPERVISOR_RETRY_MS = 100, SUPERVISOR_ATTEMPTS = 20;
const OPTIONS = Object.freeze([
    {key:'animations', read:'animations:enabled', group:'animations', field:'enabled', type:'bool'},
    {key:'blur', read:'decoration:blur:enabled', group:'decoration', field:'blur', type:'bool'},
    {key:'shadows', read:'decoration:shadow:enabled', group:'decoration', field:'shadow', type:'bool'},
    {key:'gapsIn', read:'general:gaps_in', group:'general', field:'gaps_in', type:'gaps'},
    {key:'gapsOut', read:'general:gaps_out', group:'general', field:'gaps_out', type:'gaps'}
]);
function parse(text, option) {
    const v = JSON.parse(text);
    if (option.type === 'bool' && typeof v.bool === 'boolean') return v.bool;
    if (option.type === 'bool' && (v.int === 0 || v.int === 1)) return v.int === 1;
    // Hyprland 0.56 reports gaps as {css: "0 0 0 0"}; older builds used {custom: ...}.
    const gaps = typeof v.css === 'string' ? v.css : v.custom;
    if (option.type === 'gaps' && typeof gaps === 'string' && /^\d+(?:\.\d+)?(?:\s+\d+(?:\.\d+)?){0,3}$/.test(gaps.trim())) return gaps.trim();
    throw new Error('Invalid read-back for ' + option.key);
}
function intended(config) {
    const result = {};
    OPTIONS.forEach(o => {
        const v = config[o.key];
        if (o.type === 'bool' && typeof v === 'boolean') result[o.key] = v;
        else if (o.type === 'gaps' && Number.isFinite(v) && v >= 0) result[o.key] = String(v);
        else throw new Error('Invalid game option ' + o.key);
    });
    return result;
}
function lua(values) {
    function b(k) { if (typeof values[k] !== 'boolean') throw new Error('Invalid boolean'); return String(values[k]); }
    function g(k) {
        const s = String(values[k]);
        if (!/^\d+(?:\.\d+)?(?:\s+\d+(?:\.\d+)?){0,3}$/.test(s)) throw new Error('Invalid gaps');
        return '"' + s + '"';
    }
    return 'hl.config({animations={enabled=' + b('animations') + '},decoration={blur={enabled=' + b('blur') +
        '},shadow={enabled=' + b('shadows') + '}},general={gaps_in=' + g('gapsIn') + ',gaps_out=' + g('gapsOut') + '}})';
}
function equal(a, b) {
    return OPTIONS.every(o => {
        if (o.type === 'bool') return a[o.key] === b[o.key];
        const normalize = v => { const n = String(v).split(/\s+/).map(Number); return n.length === 1 ? [n[0],n[0],n[0],n[0]] : n; };
        return JSON.stringify(normalize(a[o.key])) === JSON.stringify(normalize(b[o.key]));
    });
}
function validJournal(v) {
    try { return v.version === 1 && typeof v.instance === 'string' && !!v.instance && Number.isInteger(v.ownerPid) && v.ownerPid > 0 && /^\d+$/.test(v.ownerStart) && !!lua(v.baseline) && !!lua(v.intended); }
    catch (error) { return false; }
}

function processStart(text) {
    const fields = text.slice(text.lastIndexOf(')') + 2).trim().split(/\s+/);
    if (!/^\d+$/.test(fields[19] || '')) throw new Error('Invalid process identity');
    return fields[19];
}
