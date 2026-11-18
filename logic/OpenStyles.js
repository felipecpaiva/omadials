.pragma library
// The open and close motion (docs/experience.md, "Open and close"). One open amount p, 0 = the closed tab and
// 1 = the full corner, maps to everything that is drawn. Ported from docs/prototype/motion-lab.html in real pixels.
// Every style starts and ends on the closed tab: at p = 0 nothing is drawn outside the tab disc and the tab overlay is
// fully on top; at p = 1 every part sits at its final place and the overlay is gone.
const STYLES=Object.freeze(['morph','hybrid','lens','cascade','minimal','fan']);
// The closed tab (views/TabMark.qml draws it from these): disc radius, mini ring radii per tab style, stroke, knob.
const TAB=Object.freeze({radius:42,stroke:2.5,knob:8,battery:38,mini:Object.freeze({rings2knob:[32,21],rings3:[32,24,16],rings3knob:[32,24,16]}),
    knob0:Object.freeze({rings2knob:true,rings3:false,rings3knob:true})});
const KNOB=14, STROKES=Object.freeze({thin:2,normal:4,bold:6});
// How far parts reach from their radius, for the clip: a toggle circle is 40 px wide, a curved label sits 8 to 20 px
// inside its ring, and the readout block (Geometry.textBoxes) lies within about 140 to 204 px of the corner.
const TOGGLE_HALF=20, LABEL_IN=20, LABEL_OUT=8, READOUT_NEAR=140, READOUT_FAR=204;
const EPS=1e-9, TAB_FADE=0.18, SWEEP_MAX=1.06, MINIMAL_FADE=2.2, LENS_OVER=6;
const CURVES=Object.freeze({decel:[0.05,0.7,0.1,1],accel:[0.3,0,0.8,0.15],win:[0,0,0,1],snap:[0.42,1.67,0.21,0.9]});
// Spring response in seconds (mass 1, stiffness (2π/response)², damping ratio 1 - bounce) or a tween in ms and curve.
const TIMING=Object.freeze({
    morph:{open:{response:0.30},close:{response:0.22}},
    hybrid:{open:{response:0.30},close:{response:0.20}},
    lens:{open:{ms:260,curve:'decel'},close:{ms:170,curve:'accel'}},
    cascade:{open:{response:0.34},close:{response:0.22}},
    minimal:{open:{ms:160,curve:'win'},close:{ms:110,curve:'accel'}},
    fan:{open:{ms:300,curve:'snap'},close:{ms:170,curve:'accel'}},
    still:{open:{ms:160,curve:'win'},close:{ms:110,curve:'accel'}}   // reduced motion: Minimal without movement
});
const DEFAULT_BOUNCE=0.06, FLICK_SPEED=1.5, FLICK_BOUNCE=0.15, MIN_TRAVEL=0.25, HALF=0.5;
// Drag: rubber band past the full radius, flick smoothing, and the projected end state on release.
const BAND_STIFF=0.55, BAND_REACH=0.3, FLICK_SMOOTH=0.4, PROJECT_S=0.12, MS=1000;

function clamp(v,lo,hi) { return Math.max(lo===undefined ? 0 : lo, Math.min(hi===undefined ? 1 : hi, v)); }
function lerp(a,b,t) { return a+(b-a)*t; }
// A part that starts once the corner is `from` open and takes `span` of the travel.
function after(p,from,span) { const t=(p-from)/span; return t>1-EPS ? 1 : clamp(t); }   // EPS: staggers summed in floats
// A staggered part i of n. The step shrinks when needed so the last part still lands by p = 1 (the lab's staggers
// overran p = 1 with 6 or more toggles or 4 rings; this is the one deliberate change from the lab).
function stagger(p,start,step,span,i,n) {
    const fit=n>1 ? Math.min(step,Math.max(0,1-start-span)/(n-1)) : step;
    return after(p,start+i*fit,span);
}
// How much of a band from lo to hi a circular clip of radius clipR shows, 0 to 1.
function cover(clipR,lo,hi) { return clamp((clipR-lo)/Math.max(EPS,hi-lo)); }
function strokeFor(thickness) { return STROKES[thickness]||STROKES.normal; }
// s.tab is the tab size setting (cornerIcon.scale, 0.5 to 1); s.mini comes already scaled from TabMark.
function tabR(s) { return TAB.radius*(s.tab||1); }
function miniOf(s,i) {
    const m=s.mini||[];
    return i<m.length ? {r:m[i],has:true} : {r:m.length ? m[m.length-1] : tabR(s)*HALF,has:false};
}
function ringDefaults(s,i) { return {r:s.radii[i],sweep:1,value:1,width:s.strokes[i],knob:1,knobSize:KNOB,alpha:1,grow:1}; }
const ONE=function(){return {};};

// Each style: p and size data to the raw shape {surf, clip, alpha, labels, ring(i), toggle(j)}. frame() applies the clip.
const SHAPES=Object.freeze({
    morph:function(p,s,n,m) {
        const r=lerp(tabR(s),s.R,p);
        return {surf:r,clip:r,alpha:1,labels:after(p,0.72,0.28),
            ring:function(i){const q=stagger(p,0,0.05,0.9,i,n),mini=miniOf(s,i);   // rings leave a little apart, outer first
                return {r:lerp(mini.r,s.radii[i],p),width:lerp(TAB.stroke*(s.tab||1),s.strokes[i],q),knob:i===(s.knobRing||0)&&s.knob&&mini.has ? 1 : q,
                    knobSize:lerp(TAB.knob*(s.tab||1),KNOB,q),alpha:mini.has ? 1 : q,grow:q};},
            toggle:function(j){return {alpha:stagger(p,0.6,0.04,0.3,j,m)};}};
    },
    hybrid:function(p,s) {
        const r=lerp(tabR(s),s.R,p);
        return {surf:r,clip:r,alpha:1,labels:after(p,0.6,0.4),ring:ONE,toggle:function(){return {alpha:after(p,0.5,0.4)};}};
    },
    lens:function(p,s) { return {surf:s.R,clip:lerp(tabR(s),s.R+LENS_OVER,p),alpha:1,labels:1,ring:ONE,toggle:ONE}; },
    cascade:function(p,s,n,m) {
        const r=lerp(tabR(s),s.R,p);
        return {surf:r,clip:r,alpha:1,labels:after(p,0.7,0.3),
            ring:function(i){return {alpha:stagger(p,0.25,0.1,0.25,i,n),value:stagger(p,0.35,0.1,0.5,i,n)};},
            toggle:function(j){return {alpha:stagger(p,0.55,0.05,0.2,j,m),scale:lerp(0.7,1,stagger(p,0.55,0.05,0.3,j,m))};}};
    },
    minimal:function(p,s) {
        const r=lerp(tabR(s),s.R,p);
        return {surf:r,clip:r,alpha:clamp(p*MINIMAL_FADE),labels:1,ring:ONE,toggle:ONE};
    },
    fan:function(p,s,n,m) {
        const r=lerp(tabR(s),s.R,clamp(p*1.4));
        return {surf:r,clip:r,alpha:1,labels:after(p,0.7,0.3),
            ring:function(i){return {sweep:stagger(p,0.15,0.08,0.7,i,n),alpha:after(p,0.1,0.2)};},
            toggle:function(j){return {alpha:stagger(p,0.5,0.05,0.2,j,m),scale:lerp(0.6,1,stagger(p,0.5,0.05,0.35,j,m))};}};
    },
    still:function(p,s) { return {surf:s.R,clip:s.R,alpha:clamp(p*MINIMAL_FADE),labels:1,ring:ONE,toggle:ONE}; }
});

// size: {R, radii[], strokes[], toggleRadius, toggles (visible slots), mini[] (tab mini radii, [] for a custom icon),
// knob (the tab has a knob on its first mini ring)}. Returns the drawing parameters for one frame:
// disc (surface radius), clip, alpha (whole body), tab (overlay alpha), readout (battery and profile text alpha),
// rings[{r, sweep, width, value (factor), alpha, cover (stroke inside the clip), knob, knobSize, label, grow}],
// toggles[{alpha, scale}].
function frame(style,p,size) {
    const n=size.radii.length,m=size.toggles||0,sh=(SHAPES[style]||SHAPES.morph)(p,size,n,m),c=sh.clip;
    const rings=size.radii.map(function(rf,i){
        const g=Object.assign(ringDefaults(size,i),sh.ring(i));
        g.sweep=clamp(g.sweep,0,SWEEP_MAX); g.value=clamp(g.value);
        g.cover=cover(c,g.r-g.width*HALF,g.r+g.width*HALF);
        g.knob*=cover(c,g.r-g.knobSize*HALF,g.r+g.knobSize*HALF);
        g.label=sh.labels*cover(c,rf-LABEL_IN,rf-LABEL_OUT);     // labels stay at the final radius and fade
        return g;
    });
    const toggles=[];
    for(let j=0;j<m;j++) {
        const t=Object.assign({alpha:1,scale:1},sh.toggle(j));
        t.alpha*=cover(c,size.toggleRadius-TOGGLE_HALF,size.toggleRadius+TOGGLE_HALF);
        toggles.push(t);
    }
    return {disc:Math.max(0,Math.min(sh.surf,c)),clip:c,alpha:sh.alpha,tab:1-after(p,0,TAB_FADE),
        readout:sh.labels*cover(c,Math.min(READOUT_NEAR,size.R*HALF),Math.min(READOUT_FAR,size.R)),rings:rings,toggles:toggles};
}
// How p moves from `from` to `to`: {response, bounce, velocity} for a spring, {ms, curve} for a tween.
// opts: {speed, bounce} from the config. A flick out adds a little bounce; closing never bounces.
function timing(style,from,to,flick,opts) {
    const o=opts||{},speed=o.speed>0 ? o.speed : 1,opening=to>HALF,t=(TIMING[style]||TIMING.morph)[opening ? 'open' : 'close'];
    if(t.response) {
        const b=typeof o.bounce==='number' ? o.bounce : DEFAULT_BOUNCE;
        return {response:t.response/speed,bounce:opening ? (flick>FLICK_SPEED ? Math.max(b,FLICK_BOUNCE) : b) : 0,velocity:flick ? flick : undefined};
    }
    return {ms:t.ms/speed*Math.max(MIN_TRAVEL,Math.abs(to-from)),curve:CURVES[t.curve]};
}
// The finger's distance from the corner as an open amount, with a rubber band past the full radius.
function dragAmount(d,R) {
    let q=(d-TAB.radius)/Math.max(1,R-TAB.radius);
    if(q>1)q=1+(1-1/((q-1)*BAND_STIFF+1))*BAND_REACH;
    return Math.max(0,q);
}
// Smoothed finger speed in open amounts per second.
function flickVelocity(v,dd,dtMs,R) { return lerp(v,dd/Math.max(1,R-TAB.radius)/(Math.max(1,dtMs)/MS),FLICK_SMOOTH); }
// The flick's destination decides, not the lift point.
function opensOnRelease(p,v,threshold) { return p+v*PROJECT_S>threshold; }
