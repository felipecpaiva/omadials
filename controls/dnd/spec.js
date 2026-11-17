.pragma library
function good(value) { return {availability: 'available', value: value, reason: ''}; }
function bad(text, code) { return {availability: code ? 'unavailable' : 'error', value: null, reason: text || 'Empty command response'}; }

const watch = "file", interval = 4000, timeout = 10000;
function read(options) { return ['omarchy-shell','notifications','isDnd']; }
function parse(text, code) {
    if (code !== 0) return bad(text, code);
    text = text.trim();
    try { if (text === 'on' || text === 'off') return good(text === 'on'); } catch (error) { return bad(text, 0); }
    return bad(text, 0);
}
function write(value, options) { return typeof value === 'boolean' ? ['omarchy','toggle','notification','silencing'] : null; }

function probe(options) { return read(options); }
