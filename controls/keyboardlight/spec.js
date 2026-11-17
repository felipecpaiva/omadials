.pragma library
function good(value) { return {availability: 'available', value: value, reason: ''}; }
function bad(text, code) { return {availability: code ? 'unavailable' : 'error', value: null, reason: text || 'Empty command response'}; }
function normalize(v, options) { return Math.round(Math.max(0, Math.min(options.maxLevel || 3, v))); }
const watch = "poll", interval = 4000, timeout = 10000;
function read(options) { return ['brightnessctl', '-m', '-d', options.device || 'asus::kbd_backlight']; }
function parse(text, code) {
    if (code !== 0) return bad(text, code);
    text = text.trim();
    try { const f = text.split(','); const n = Number(f[2]), max = Number(f[4]);
        if (f.length === 5 && Number.isInteger(n) && Number.isInteger(max) && max > 0 && n >= 0 && n <= max) return Object.assign(good(n), {range: {min:0, max:max, floor:0, step:1, unit:""},
            steps:Array.from({length:max+1}, (_,i) => ({key:i,label:String(i)}))}); } catch (error) { return bad(text, 0); }
    return bad(text, 0);
}
function write(value, options) { if (!Number.isFinite(value)) return null; return ['brightnessctl', '-d', options.device || 'asus::kbd_backlight', 'set', String(normalize(value, options))]; }

function probe(options) { return read(options); }

function detect(text, code) {
    return code ? '' : text.trim().split(/\s+/).filter(n => /^[^/]*kbd_backlight[^/]*$/.test(n)).sort()[0] || '';
}
