.pragma library
function reading(connected, fraction, unknown) {
    return connected && !unknown && Number.isFinite(fraction) && fraction >= 0 && fraction <= 1 ? Math.round(fraction * 100) : null;
}
// Low: at or below the threshold and not charging, so a plugged-in laptop never shows the warning.
function low(value, charging, threshold) { return value !== null && value !== undefined && !charging && value <= threshold; }
function text(connected, value) { return !connected ? 'not connected' : value === null ? 'unknown' : value + '%'; }
