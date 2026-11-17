.pragma library
function good(value) { return {availability: 'available', value: value, reason: ''}; }
function bad(text, code) { return {availability: code ? 'unavailable' : 'error', value: null, reason: text || 'Empty command response'}; }

const watch = "file", interval = 4000, timeout = 10000;
function read(options) { return ['omarchy-theme-current']; }
function parse(text, code) {
    if (code !== 0) return bad(text, code);
    text = text.trim();
    try { if (text && text !== 'Unknown') return good(text); } catch (error) { return bad(text, 0); }
    return bad(text, 0);
}
function write(value, options) { return typeof value === 'string' && value.trim() ? ['omarchy-theme-set',value] : null; }

function probe(options) { return read(options); }
