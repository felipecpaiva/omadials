.pragma library
function good(value) { return {availability: 'available', value: value, reason: ''}; }
function bad(text, code) { return {availability: code ? 'unavailable' : 'error', value: null, reason: text || 'Empty command response'}; }
function normalize(v) { return Math.round(Math.max(1, Math.min(100, v))); }
const watch = "poll", interval = 2000, timeout = 10000;
function read(options) { return ["brightnessctl", "-m", "-d", options.device || "amdgpu_bl1"]; }
function parse(text, code) {
    if (code !== 0) return bad(text, code);
    text = text.trim();
    try { const f = text.split(','); const n = Number(f[3]?.replace('%',''));
        if (f.length === 5 && /%$/.test(f[3]) && Number.isFinite(n) && n >= 0 && n <= 100) return good(n); } catch (error) { return bad(text, 0); }
    return bad(text, 0);
}
function write(value, options) { if (!Number.isFinite(value)) return null;
    const argv = ['omarchy-brightness-display', '--no-osd'];
    if (options.monitor && options.monitor !== 'auto') argv.push('--monitor', options.monitor);
    return argv.concat([String(normalize(value)) + '%']); }

function probe(options) { return read(options); }
