import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const G=load('Geometry');
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-8,`${a} != ${b}`);
// A-SIZE-1, A-SIZE-2, A-SIZE-3
for(const corner of G.CORNERS)for(const size of ['S','M','L'])test(`${corner} ${size} geometry`,()=>{
    const c=G.capacity(size,1600),spec=G.SIZES[size];
    assert.equal(c.R,spec.radius);assert.equal(c.rings,spec.rings);assert.equal(c.toggles,{S:5,M:6,L:7}[size]);
    const radii=G.ringRadii(c.R,c.rings);
    radii.forEach((r,i)=>{
        assert.equal(r,c.R-22-44*i);assert.equal(G.hitRing(r,radii),i);
        for(const f of [0,0.25,0.5,0.75,1]){
            const p=G.knobPos(r,G.fractionToAngle(f),1200);
            const mirrored=G.fromCanonical(p,1800,1200,corner);
            const restored=G.toCanonical(mirrored,1800,1200,corner);near(restored.x,p.x);near(restored.y,p.y);
            const polar=G.polar(p.x,p.y,1200);near(polar.d,r);near(G.angleToFraction(polar.a),f);
        }
        const path=G.labelPath(r,1200,1800,1200,corner);
        assert.ok(path.start.x<path.end.x);assert.equal(path.radius,r-14);
    });
    const slots=G.arcSlots(c.toggleRadius);assert.equal(slots.count,c.toggles);
    slots.angles.forEach(a=>assert.ok(a>=6+slots.step/2&&a<=84-slots.step/2));
});
test('sweeps, hit boundaries, bubble and cap',()=>{
    assert.equal(G.fractionToAngle(0),3);assert.equal(G.fractionToAngle(1),87);
    assert.equal(G.fractionToAngle(0,true),6);assert.equal(G.fractionToAngle(1,true),84);
    assert.equal(G.angleToFraction(-40),0);assert.equal(G.angleToFraction(100),1);
    assert.equal(G.hitRing(122,[100]),0);assert.equal(G.hitRing(122.01,[100]),-1);
    const p=G.bubblePos({x:50,y:50},1000,1000);near(Math.hypot(p.x-50,p.y-50),56);
    for(const size of ['S','M','L'])assert.equal(G.capacity(size,960).R,Math.min(G.SIZES[size].radius,432));
    assert.equal(G.capacity('L',300).size,'S');assert.ok(G.capacity('L',300).rings<2);
    assert.throws(()=>G.capacity('XL',1000));
});
// A-DIAL-4, A-SIZE-4
 test('reserved text rectangles mirror without negative dimensions and bubble clears edges',()=>{
    for(const corner of G.CORNERS){
        const boxes=G.textBoxes(1600,1000,corner);
        for(const r of Object.values(boxes)){assert.ok(r.width>0&&r.height>0);assert.ok(r.x>=0&&r.y>=0);}
        assert.equal(boxes.status.width,120);assert.equal(boxes.status.height,36);
        assert.ok(boxes.profile.width>=48);assert.equal(boxes.gear.width,48);
    }
    const bubble=G.bubblePos({x:-100,y:-100},1600,1000);assert.equal(bubble.x,38);assert.equal(bubble.y,24);
});
test('label reservations and growing detail rows stay upright in every corner and size',()=>{
    for(const corner of G.CORNERS)for(const size of ['S','M','L']){
        const cap=G.capacity(size,1200),labels=G.labelBoxes(G.ringRadii(cap.R,cap.rings),1800,1200,corner);
        assert.equal(labels.length,cap.rings);for(const box of labels){assert.equal(box.width,96);assert.equal(box.height,40);assert.ok(box.x>=0&&box.y>=0);}
        const d=G.detailRows(cap.R,[18,72,96,300],1800,1200,corner);
        assert.equal(d.rows[0].height,48);assert.equal(d.rows[1].height,72);assert.equal(d.scrollable,true);
        for(let i=1;i<d.rows.length;i++)assert.equal(d.rows[i].y,d.rows[i-1].y+d.rows[i-1].height);
        assert.equal(G.batteryLineBox(1800,1200,corner).height,18);
    }
});
