.pragma library
function reading(connected, fraction, unknown) {
    return connected && !unknown && Number.isFinite(fraction) && fraction >= 0 && fraction <= 1 ? Math.round(fraction * 100) : null;
}
function text(connected, value) { return !connected ? 'not connected' : value === null ? 'unknown' : value + '%'; }
