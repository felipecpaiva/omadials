import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const L=load('Layout'),G=load('Geometry');
const measure=(text,width)=>Math.ceil(text.length/(width/7))*18;
// A-SIZE-4, A-SIZE-5, A-TOGGLE-1, A-TOGGLE-2
for(const corner of G.CORNERS)for(const size of ['S','M','L'])test(`${corner} ${size} text and strip layout`,()=>{
    const screen={width:1800,height:1200},cap=G.capacity(size,1200);
    const short=L.textLayout(size,'Wi-Fi on',measure,screen,corner,cap.R,false,0);
    assert.equal(short.ringNames,size!=='S');assert.equal(short.batteryFont,{S:28,M:40,L:48}[size]);
    assert.equal(short.mode,size==='S'?'notice':'short');assert.ok(short.profile.width>=48);assert.equal(short.gear.width,48);
    assert.ok(short.profile.x+48<=short.gear.x||short.gear.x+48<=short.profile.x);
    const medium=L.textLayout(size,'x'.repeat(60),measure,screen,corner,cap.R,false,0);
    assert.equal(medium.mode,size==='S'?'notice':'long');
    assert.equal(medium.hideBattery,size!=='S');
    const long=L.textLayout(size,'x'.repeat(200),measure,screen,corner,cap.R,false,0);
    assert.equal(long.mode,'notice');assert.equal(long.status.width,260);
    const back=corner.replace('right','left').replace('top','bottom');
    const canonical=L.textLayout(size,'Wi-Fi on',measure,screen,back,cap.R,false,0);
    if(corner.includes('right'))assert.equal(short.status.x,1800-canonical.status.x-short.status.width);
    if(corner.includes('top'))assert.equal(short.status.y,1200-canonical.status.y-short.status.height);
    const entries=Array.from({length:10},(_,i)=>({id:'t'+i}));
    const config={controls:Object.fromEntries(entries.map(e=>[e.id,{shown:true}])),toggles:entries,dials:[],readoutRings:[]};
    const catalog=entries.map(e=>({...e,kind:'toggle',placements:['arc']}));
    const layout=L.arrange(config,catalog,{},cap,0);
    assert.equal(layout.visible.length,cap.toggles);assert.equal(layout.maxOffset,10-cap.toggles);
    assert.equal(layout.fadeBefore,false);assert.equal(layout.fadeAfter,true);assert.equal(L.openOffset(),0);
});
test('notice deadlines and error persistence',()=>{
    const f=(error,elapsed)=>L.textLayout('S','status',measure,{width:1600,height:1000},'bottom-left',330,error,elapsed);
    assert.equal(f(false,2499).noticeVisible,true);assert.equal(f(false,2500).noticeVisible,false);assert.equal(f(true,10000).noticeVisible,true);
});
test('availability, hard cap, readout disconnect and capture freeze',()=>{
    const entries=['a','b','c','d'].map((id,order)=>({id,order}));
    const config={dials:entries.slice(0,3),readoutRings:entries.slice(3),controls:Object.fromEntries(entries.map(e=>[e.id,{shown:true}]))};
    const catalog=entries.map(e=>({...e,placements:['ring'],kind:e.id==='d'?'readout':'dial'}));
    let l=L.arrange(config,catalog,{a:'unavailable',b:'error',d:'unavailable'},{rings:2,toggles:5},0);
    assert.deepEqual(l.rings.map(e=>e.id),['b','c']);assert.equal(l.errors[0].code,'over_capacity');
    l=L.arrange(config,catalog,{a:'unavailable'},{rings:4,toggles:5},0);assert.ok(l.rings.some(e=>e.id==='d'));
    assert.deepEqual(L.arrange(config,catalog,{}, {rings:1,toggles:5},0,true,l).rings,l.rings);
});
