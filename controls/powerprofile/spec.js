.pragma library
function good(value) { return {availability: 'available', value: value, reason: ''}; }
function bad(text, code) { return {availability: code ? 'unavailable' : 'error', value: null, reason: text || 'Empty command response'}; }

const watch = "service", interval = 4000, timeout = 10000;
function read(options) { return ['powerprofilesctl','get']; }
function parse(text, code) {
    if (code !== 0) return bad(text, code);
    text = text.trim();
    try { if (['performance','balanced','power-saver'].indexOf(text) >= 0) return good(text); } catch (error) { return bad(text, 0); }
    return bad(text, 0);
}
function write(value, options) { return ['performance','balanced','power-saver'].indexOf(value) >= 0 ? ['omarchy-powerprofiles-set','autodetect',value] : null; }

function probe(options) { return read(options); }
