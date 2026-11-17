import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const O=load('OpenStyles'), G=load('Geometry');
const near=(a,b,msg)=>assert.ok(Math.abs(a-b)<1e-9,`${msg}: ${a} != ${b}`);
// Real size data, built the way views/Fan.qml builds it, for every size and tab style (and a custom icon tab).
function sizes() {
    const out=[];
    for(const size of ['S','M','L'])for(const shortSide of [1600,700])for(const tab of ['rings2knob','rings3','rings3knob','custom']) {
        const c=G.capacity(size,shortSide),radii=G.ringRadii(c.R,c.rings);
        out.push({name:`${size}@${shortSide} ${tab}`,R:c.R,radii,strokes:radii.map((_,i)=>O.strokeFor(['thin','normal','bold'][i%3])),
            toggleRadius:c.toggleRadius,toggles:G.arcSlots(c.toggleRadius).count,
            mini:tab==='custom' ? [] : O.TAB.mini[tab],knob:tab!=='custom'&&O.TAB.knob0[tab]});
    }
    return out;
}
// At p = 0 the frame is the closed tab: the overlay is fully on, and nothing of the body shows outside the tab disc.
function assertClosedTab(f,s,msg) {
    const R=O.TAB.radius,body=f.alpha>0;
    assert.equal(f.tab,1,msg+' tab overlay');
    if(!body)return;
    assert.ok(f.disc<=R,msg+' disc');
    assert.equal(f.readout,0,msg+' readout');
    f.toggles.forEach((t,j)=>assert.equal(t.alpha,0,`${msg} toggle ${j}`));
    f.rings.forEach((g,i)=>{
        if(g.alpha*g.cover>0)assert.ok(g.r+g.width/2<=R,`${msg} ring ${i} stroke inside the tab`);
        if(g.alpha*g.knob>0)assert.ok(g.r+g.knobSize/2<=R,`${msg} ring ${i} knob inside the tab`);
        assert.equal(g.alpha*g.label,0,`${msg} ring ${i} label`);
        // A ring drawn at p = 0 is the tab's own mini ring, exactly.
        if(g.alpha*g.cover>0){assert.equal(g.r,s.mini[i],`${msg} ring ${i} is mini`);assert.equal(g.width,O.TAB.stroke);assert.equal(g.value,1);assert.equal(g.sweep,1);}
    });
}
function assertFullCorner(f,s,msg) {
    assert.equal(f.tab,0,msg+' tab');assert.equal(f.alpha,1,msg+' alpha');near(f.disc,s.R,msg+' disc');assert.equal(f.readout,1,msg+' readout');
    assert.equal(f.toggles.length,s.toggles);
    f.toggles.forEach((t,j)=>{assert.equal(t.alpha,1,`${msg} toggle ${j} alpha`);assert.equal(t.scale,1,`${msg} toggle ${j} scale`);});
    f.rings.forEach((g,i)=>{
        near(g.r,s.radii[i],`${msg} ring ${i} r`);near(g.width,s.strokes[i],`${msg} ring ${i} width`);
        for(const k of ['sweep','value','alpha','cover','knob','label','grow'])assert.equal(g[k],1,`${msg} ring ${i} ${k}`);
        near(g.knobSize,O.KNOB,`${msg} ring ${i} knob size`);
    });
}
for(const style of [...O.STYLES,'still'])test(`${style}: p = 0 is the closed tab, p = 1 the full corner, finite throughout`,()=>{
    for(const s of sizes()) {
        assertClosedTab(O.frame(style,0,s),s,`${style} ${s.name} p=0`);
        assertFullCorner(O.frame(style,1,s),s,`${style} ${s.name} p=1`);
        for(let p=-0.2;p<=1.2001;p+=0.01) {
            const f=O.frame(style,p,s),nums=[f.disc,f.clip,f.alpha,f.tab,f.readout,...f.rings.flatMap(Object.values),...f.toggles.flatMap(Object.values)];
            nums.forEach(v=>assert.ok(Number.isFinite(v),`${style} ${s.name} p=${p}`));
            assert.ok(f.disc>=0&&f.tab>=0&&f.tab<=1&&f.alpha>=0&&f.alpha<=1);
        }
    }
});
test('the closed tab matches the tab drawing: two or three minis inside the 42 px disc, knob on the first',()=>{
    for(const [k,m] of Object.entries(O.TAB.mini))m.forEach(r=>assert.ok(r+O.TAB.knob/2<=O.TAB.radius,k));
    assert.deepEqual(O.STYLES,['morph','hybrid','lens','cascade','minimal','fan']);
});
test('timing: springs per style, speed scales, flick bounce only when opening, tweens shrink with distance',()=>{
    const morph=O.timing('morph',0,1,0,{speed:1,bounce:0.06});
    near(morph.response,0.30,'open response');assert.equal(morph.bounce,0.06);assert.equal(morph.velocity,undefined);
    near(O.timing('morph',1,0,0,{speed:2}).response,0.11,'close at 2x');assert.equal(O.timing('morph',1,0,-3,{bounce:0.3}).bounce,0);
    assert.equal(O.timing('morph',0.5,1,2,{bounce:0.06}).bounce,0.15);assert.equal(O.timing('morph',0.5,1,2,{}).velocity,2);
    assert.equal(O.timing('cascade',0,1,0,{bounce:0.2}).bounce,0.2);
    const lens=O.timing('lens',0,1,0,{speed:1});assert.equal(lens.ms,260);assert.deepEqual(lens.curve,[0.05,0.7,0.1,1]);
    assert.equal(O.timing('lens',0.9,1,0,{}).ms,260*0.25,'short travel keeps a quarter');
    assert.equal(O.timing('minimal',1,0,0,{speed:0.5}).ms,220);assert.deepEqual(O.timing('fan',0,1,0,{}).curve,[0.42,1.67,0.21,0.9]);
    assert.equal(O.timing('still',0,1,0,{}).ms,160);
});
test('drag: tab edge is 0, full radius 1, rubber band past it, flick projection decides',()=>{
    assert.equal(O.dragAmount(42,420),0);assert.equal(O.dragAmount(10,420),0);assert.equal(O.dragAmount(420,420),1);
    const a=O.dragAmount(600,420),b=O.dragAmount(2000,420);assert.ok(a>1&&b>a&&b<1.3);
    assert.equal(O.opensOnRelease(0.3,0,0.4),false);assert.equal(O.opensOnRelease(0.3,1,0.4),true);assert.equal(O.opensOnRelease(0.6,-2,0.4),false);
    near(O.flickVelocity(0,37.8,10,420),0.4*0.1/0.01,'smoothed speed');
});
// Maintainer: no element may vanish mid-motion. In Tab morph every ring stays inside the growing disc.
test('tab morph rings never leave the disc', ()=>{
    for (const sz of sizes()) for (let k=0;k<=100;k++) {
        const p=k/100, f=O.frame('morph',p,sz);
        (f.rings||f.ring).forEach((g,i) => { if (g.alpha>0.01) assert.ok(g.r + g.width/2 <= f.disc + 0.5, `${sz.name} p=${p} ring ${i} r ${g.r} surf ${f.surf}`); });
    }
});
