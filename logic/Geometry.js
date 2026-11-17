.pragma library
const BAND = 44, TARGET = 48, CAP = 0.45, ARC_LENGTH = 1.36;
const RING_START = 3, RING_END = 87, ARC_START = 6, ARC_END = 84;
const LABEL_OFFSET = 14, LABEL_PAD = 10, BUBBLE_DISTANCE = 56;
const DEGREES = 180, HALF = 0.5;
const BUBBLE_HALF_WIDTH=30, BUBBLE_HALF_HEIGHT=16, CLEARANCE=8;
const TEXT_INSET=12, TEXT_GAP=8, READOUT_WIDTH=150, READOUT_DEPTH=112, STATUS_DEPTH=132, STATUS_WIDTH=120, STATUS_HEIGHT=36;
const SIZES = Object.freeze({S: {radius:330, toggle:200, rings:2}, M: {radius:420, toggle:240, rings:3}, L: {radius:500, toggle:280, rings:4}});
const CORNERS = Object.freeze(['bottom-left','bottom-right','top-left','top-right']);
function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
// Canonical coordinates are screen positions with the origin at bottom-left.
function fromCanonical(p, width, height, corner) {
    if (CORNERS.indexOf(corner) < 0) throw new Error('Unknown corner');
    return {x:corner.indexOf('right') >= 0 ? width-p.x : p.x,
        y:corner.indexOf('top') >= 0 ? height-p.y : p.y};
}
function toCanonical(p, width, height, corner) { return fromCanonical(p, width, height, corner); }
function polar(x, y, H) { return {d:Math.hypot(x,H-y), a:Math.atan2(x,H-y)*DEGREES/Math.PI}; }
function angleToFraction(a, toggle) {
    const lo=toggle ? ARC_START : RING_START, hi=toggle ? ARC_END : RING_END;
    return clamp((a-lo)/(hi-lo),0,1);
}
function fractionToAngle(f, toggle) {
    const lo=toggle ? ARC_START : RING_START, hi=toggle ? ARC_END : RING_END;
    return lo+clamp(f,0,1)*(hi-lo);
}
function ringRadii(R,n) { return Array.from({length:n},function(_,i){return R-BAND*HALF-BAND*i;}); }
function hitRing(d,radii,band) {
    const width=band === undefined ? BAND : band;
    return radii.findIndex(function(r){return Math.abs(d-r)<=width*HALF;});
}
function knobPos(r,a,H) { const t=a*Math.PI/DEGREES; return {x:r*Math.sin(t),y:H-r*Math.cos(t)}; }
function arcSlots(r,pitch) {
    const step=(pitch || TARGET)/r*DEGREES/Math.PI;
    const count=Math.max(0,Math.floor(r*ARC_LENGTH/(pitch || TARGET)));
    return {count:count,step:step,angles:Array.from({length:count},function(_,i){return ARC_START+step*(i+HALF);})};
}
function capacity(size,shortSide) {
    const requested=SIZES[size];
    if (!requested) throw new Error('Unknown size');
    const R=Math.min(requested.radius,CAP*shortSide);
    // A full slot needs its bands plus one toggle target radius. No target scaling.
    const effective=R < requested.rings*BAND+TARGET ? 'S' : size;
    const spec=SIZES[effective];
    const rings=Math.max(0,Math.min(spec.rings,Math.floor((R-TARGET)/BAND)));
    const toggle=Math.max(0,Math.min(spec.toggle,R-rings*BAND-TARGET*HALF));
    return {size:effective,R:R,rings:rings,toggleRadius:toggle,toggles:arcSlots(toggle).count,
        capped:R<requested.radius,reason:effective!==size ? 'Compact fallback' : R<requested.radius ? 'Screen cap' : ''};
}
function labelPath(r,H,width,height,corner) {
    const radius=r-LABEL_OFFSET;
    const start=Math.asin(Math.min(1,LABEL_PAD/radius))*DEGREES/Math.PI;
    let a=fromCanonical(knobPos(radius,start,H),width,height,corner);
    let b=fromCanonical(knobPos(radius,RING_END,H),width,height,corner);
    if(a.x>b.x) { const p=a;a=b;b=p; }
    return {start:a,end:b,radius:radius,textAnchor:corner.indexOf('right')>=0 ? 'end' : 'start',textOffset:corner.indexOf('right')>=0 ? 1 : 0,sweep:corner.indexOf('top')>=0 ? 0 : 1};
}
function bubblePos(p,width,height) {
    const dx=width*HALF-p.x,dy=height*HALF-p.y,d=Math.hypot(dx,dy);
    const q=d ? {x:p.x+BUBBLE_DISTANCE*dx/d,y:p.y+BUBBLE_DISTANCE*dy/d} : p;
    return {x:clamp(q.x,CLEARANCE+BUBBLE_HALF_WIDTH,width-CLEARANCE-BUBBLE_HALF_WIDTH),
        y:clamp(q.y,CLEARANCE+BUBBLE_HALF_HEIGHT,height-CLEARANCE-BUBBLE_HALF_HEIGHT)};
}

function textBoxes(width,height,corner) {
    function rect(x,depth,w,h) {
        const a=fromCanonical({x:x,y:height-depth-h},width,height,corner);
        const b=fromCanonical({x:x+w,y:height-depth},width,height,corner);
        return {x:Math.min(a.x,b.x),y:Math.min(a.y,b.y),width:w,height:h};
    }
    const chip=READOUT_WIDTH-TARGET-TEXT_GAP;
    return {readout:rect(TEXT_INSET,TEXT_INSET,READOUT_WIDTH,READOUT_DEPTH),
        status:rect(TEXT_INSET,STATUS_DEPTH,STATUS_WIDTH,STATUS_HEIGHT),
        profile:rect(TEXT_INSET,TEXT_INSET,chip,TARGET),
        gear:rect(TEXT_INSET+chip+TEXT_GAP,TEXT_INSET,TARGET,TARGET)};
}
const TEXT_LINE=18, LABEL_WIDTH=96, LABEL_HEIGHT=40, DETAIL_INSET=16;
function labelBoxes(radii,width,height,corner) {
    return radii.map(function(r){
        const center=fromCanonical({x:LABEL_WIDTH*HALF,y:height-r+BAND*HALF},width,height,corner);
        return {x:center.x-LABEL_WIDTH*HALF,y:center.y-LABEL_HEIGHT*HALF,width:LABEL_WIDTH,height:LABEL_HEIGHT};
    });
}
// Measured rows grow upwards from their minimum height in the normally laid out detail square.
function detailRows(R,heights,width,height,corner) {
    const anchor=fromCanonical({x:0,y:height-R},width,height,corner);
    const left=corner.indexOf('right')>=0 ? anchor.x-R : anchor.x;
    const top=corner.indexOf('top')>=0 ? anchor.y-R : anchor.y;
    let y=top+DETAIL_INSET+TARGET;
    const rows=heights.map(function(h){const row={x:left+DETAIL_INSET,y:y,width:R-DETAIL_INSET-DETAIL_INSET,height:Math.max(TARGET,h)};y+=row.height;return row;});
    return {rows:rows,contentHeight:y-top+DETAIL_INSET,scrollable:y+DETAIL_INSET>top+R};
}
function batteryLineBox(width,height,corner) {
    const bounds=textBoxes(width,height,corner).readout;
    return {x:bounds.x,y:corner.indexOf('top')>=0 ? bounds.y+TARGET : height-TEXT_INSET-TARGET-TEXT_LINE,width:READOUT_WIDTH,height:TEXT_LINE};
}
