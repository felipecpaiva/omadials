.pragma library
function good(value) { return {availability: 'available', value: value, reason: ''}; }
function bad(text, code) { return {availability: code ? 'unavailable' : 'error', value: null, reason: text || 'Empty command response'}; }

const watch = "poll", interval = 4000, timeout = 10000;
function read(options) { return ['omarchy','toggle','nightlight','--status']; }
function parse(text, code) {
    if (code !== 0) return bad(text, code);
    text = text.trim();
    try { const v = JSON.parse(text); if (typeof v.enabled === 'boolean') return good(v.enabled); } catch (error) { return bad(text, 0); }
    return bad(text, 0);
}
function write(value, options) { return typeof value === 'boolean' ? ['omarchy','toggle','nightlight'] : null; }

function probe(options) { return read(options); }
