.pragma library
function reading(audio) {
    return audio && Number.isFinite(audio.volume) && audio.volume >= 0 ? Math.round(audio.volume * 100) : null;
}
function input(value, cap) { return Number.isFinite(value) ? Math.max(0, Math.min(cap, value)) / 100 : null; }
