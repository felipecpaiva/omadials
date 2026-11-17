.pragma library
const CONFIRM_SECONDS = 10, COMMAND_TIMEOUT = 5000;
function parse(text) {
    try { return JSON.parse(text).filter(m => !m.disabled && m.name); } catch (_) { return []; }
}
function currentMode(m) { return m.width + 'x' + m.height + '@' + m.refreshRate; }
function rates(m) {
    return (m.availableModes || []).filter(mode => mode.startsWith(m.width + 'x' + m.height + '@'));
}
function argv(m, mode) {
    if (!m || !rates(m).concat([currentMode(m)]).includes(mode) ||
        !Number.isFinite(m.scale) || m.scale <= 0 || !Number.isFinite(m.x) || !Number.isFinite(m.y)) return null;
    return ['hyprctl', 'eval', 'hl.monitor({ output = ' + JSON.stringify(m.name) +
        ', mode = ' + JSON.stringify(mode.replace(/Hz$/, '')) + ', position = ' + JSON.stringify(m.x + 'x' + m.y) +
        ', scale = ' + m.scale + ' })'];
}
function brightness(text, internal) {
    const value = Number(internal ? text.trim().split(',')[3]?.replace('%','') : text.trim());
    return text.trim() && Number.isFinite(value) && value >= 0 && value <= 100 ? value : null;
}
