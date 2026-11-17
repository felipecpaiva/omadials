.pragma library
// Tiny looping previews of the animation styles for the settings pickers, after docs/prototype/motion-lab.html.
// Pure: the open amount over one loop, and one frame drawn on a 2D canvas with theme colours.
const STYLES = ['morph', 'hybrid', 'lens', 'cascade', 'minimal', 'fan'];
const SPRINGS = ['morph', 'hybrid', 'cascade'];
// [open, close] in ms at speed 1, from the lab.
const TIMES = {morph: [300, 220], hybrid: [300, 200], lens: [260, 170], cascade: [340, 220], minimal: [160, 110], fan: [300, 170]};
const HOLD_MS = 450;     // pause on the open corner and on the tab between plays
const SETTLE = 1.6;      // a spring gets this many durations to come to rest
const REST = 0.7;        // open amount drawn while not playing, where the styles look different
const TAB = 0.26, RINGS = [0.86, 0.62], MINI = [0.76, 0.5], VALUES = [0.79, 0.88], A0 = 3, A1 = 87;
function clamp(v, lo, hi) { return Math.max(lo === undefined ? 0 : lo, Math.min(hi === undefined ? 1 : hi, v)); }
function lerp(a, b, t) { return a + (b - a) * t; }
function after(p, from, span) { return clamp((p - from) / span); }
// Spring step response: mass 1, stiffness (2 pi / duration) squared, damping ratio 1 - bounce.
function spring(t, dur, bounce) {
    const w = 2 * Math.PI / dur, z = 1 - clamp(bounce, 0, 0.9);
    if (z >= 1) return 1 - Math.exp(-w * t) * (1 + w * t);
    const wd = w * Math.sqrt(1 - z * z);
    return 1 - Math.exp(-z * w * t) * (Math.cos(wd * t) + z * w / wd * Math.sin(wd * t));
}
function ease(style, t, opening) {
    if (!opening) return t * t * t;
    if (style === 'fan') { const u = t - 1; return 1 + 2.2 * u * u * u + 1.2 * u * u; }   // overshoots a little
    return 1 - Math.pow(1 - t, style === 'minimal' ? 4 : 3);
}
function phases(style, speed) {
    const t = TIMES[style] || TIMES.minimal, k = (SPRINGS.indexOf(style) >= 0 ? SETTLE : 1) / clamp(speed || 1, 0.5, 2);
    return [t[0] * k, HOLD_MS, t[1] * k, HOLD_MS];
}
function cycle(style, speed) { return phases(style, speed).reduce(function(a, b) { return a + b; }, 0); }
// Open amount at `ms` into the loop: 0 is the closed tab, 1 the full corner.
function openAmount(style, speed, bounce, ms) {
    const ph = phases(style, speed), s = clamp(speed || 1, 0.5, 2), t = TIMES[style] || TIMES.minimal;
    const isSpring = SPRINGS.indexOf(style) >= 0;
    const move = function(at, i, opening) {
        if (isSpring) return opening ? spring(at, t[i] / s, bounce) : 1 - spring(at, t[i] / s, bounce);
        const f = ease(style, clamp(at / ph[i]), opening);
        return opening ? f : 1 - f;
    };
    let at = ((ms % cycle(style, speed)) + cycle(style, speed)) % cycle(style, speed);
    if (at < ph[0]) return move(at, 0, true);
    at -= ph[0];
    if (at < ph[1]) return 1;
    at -= ph[1];
    if (at < ph[2]) return move(at, 2, false);
    return 0;
}
function ring(i, extra) { return Object.assign({r: RINGS[i], sweep: 1, value: 1, width: 1, alpha: 1}, extra || {}); }
// One frame in units of the corner radius, as the lab's styles describe it.
function frame(style, p) {
    const grow = lerp(TAB, 1, p), f = {surf: grow, clip: grow, alpha: 1, tab: 1 - after(p, 0, 0.18), rings: [ring(0), ring(1)]};
    if (style === 'morph') f.rings = [0, 1].map(function(i) { const q = after(p, i * 0.05, 0.9); return ring(i, {r: lerp(MINI[i] * TAB, RINGS[i], q)}); });
    else if (style === 'lens') { f.surf = 1; f.clip = lerp(TAB, 1.03, p); }
    else if (style === 'cascade') f.rings = [0, 1].map(function(i) { return ring(i, {alpha: after(p, 0.25 + i * 0.1, 0.25), value: after(p, 0.35 + i * 0.1, 0.5)}); });
    else if (style === 'minimal') f.alpha = clamp(p * 2.2);
    else if (style === 'fan') { f.surf = f.clip = lerp(TAB, 1, clamp(p * 1.4)); f.rings = [0, 1].map(function(i) { return ring(i, {sweep: after(p, 0.15 + i * 0.08, 0.7), alpha: after(p, 0.1, 0.2)}); }); }
    return f;
}
// Draws open amount p into a w by h canvas, corner at the bottom left. colours: {surface, edge, track, accent}.
function draw(ctx, w, h, style, p, colours) {
    const R = Math.min(w, h) - 2, rad = function(a) { return (a - 90) * Math.PI / 180; }, f = frame(style, p);
    const arc = function(r, a1, colour, width) { ctx.beginPath(); ctx.arc(0, h, r, rad(A0), rad(Math.max(A0 + 0.01, a1))); ctx.strokeStyle = colour; ctx.lineWidth = width; ctx.stroke(); };
    const disc = function(r) { ctx.beginPath(); ctx.moveTo(0, h); ctx.arc(0, h, Math.max(0, r), rad(0), rad(90)); ctx.closePath(); ctx.fillStyle = colours.surface; ctx.fill(); ctx.strokeStyle = colours.edge; ctx.lineWidth = 1; ctx.stroke(); };
    ctx.reset(); ctx.lineCap = 'round';
    if (f.alpha > 0.001) {
        ctx.save(); ctx.globalAlpha = f.alpha;
        ctx.beginPath(); ctx.moveTo(0, h); ctx.arc(0, h, Math.max(0, f.clip * R), rad(0), rad(90)); ctx.closePath(); ctx.clip();
        disc(f.surf * R);
        f.rings.forEach(function(g, i) {
            if (g.alpha <= 0) return;
            const end = A0 + (A1 - A0) * clamp(g.sweep, 0, 1.06);
            ctx.globalAlpha = f.alpha * g.alpha;
            arc(g.r * R, end, colours.track, 3);
            arc(g.r * R, Math.min(end, A0 + (A1 - A0) * VALUES[i] * g.value), colours.accent, 3);
        });
        ctx.restore();
    }
    if (f.tab > 0) {   // the closed tab lies on top while it fades, so every loop starts and ends on it
        ctx.save(); ctx.globalAlpha = f.tab; disc(TAB * R);
        MINI.forEach(function(m, i) { arc(m * TAB * R, A1, colours.track, 1.5); arc(m * TAB * R, A0 + (A1 - A0) * VALUES[i], colours.accent, 1.5); });
        ctx.restore();
    }
}
