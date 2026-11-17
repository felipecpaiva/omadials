import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const G=load('Gesture'),p={x:0,y:0};
const begin=(owner='ring')=>G.begin(owner,'brightness',p,0,50);
// A-DIAL-1, A-DIAL-2, A-DIAL-5, A-DIAL-6
for(const distance of [0,5,5.999,6,10,100])test(`ring lock and drag threshold ${distance}`,()=>{
    const s=G.move(begin(),{x:distance,y:0});assert.equal(s.id,'brightness');assert.equal(s.moved,distance>=6);
    assert.equal(G.release(s,200,false).action,distance>=6?'commit':'tap');
    assert.equal(G.release(s,200,true).action,'cancel');
});
// A-TOGGLE-5, A-DETAIL-2
for(const owner of ['toggle','label'])test(`${owner} hold deadlines and cancellation`,()=>{
    const s=begin(owner);assert.equal(G.hold(s,149).progress,0);assert.equal(G.hold(s,150).progress,0);
    assert.equal(G.hold(s,300).progress,0.5);assert.equal(G.hold(s,449).action,null);
    const h=G.hold(s,450);assert.equal(h.action,'hold');assert.equal(G.hold(h.state,451).action,null);
    assert.equal(G.release(h.state,460,false).action,null);
    const threshold=owner==='label'?10:6;
    assert.equal(G.hold(G.move(s,{x:threshold-0.01,y:0}),450).action,'hold');
    assert.equal(G.hold(G.move(s,{x:threshold,y:0}),450).action,null);
});
// A-OPEN-1, A-OPEN-2, A-ICON-2
 test('corner tap has priority over preview, strict movement and progress bounds',()=>{
    assert.equal(G.release(G.move(begin('corner'),{x:8,y:0}),400,false,0.1,true).action,'open');
    assert.equal(G.release(begin('corner'),401,false,0.4,true).action,'close');
    assert.equal(G.release(begin('corner'),401,false,0.40001,true).action,'open');
    assert.equal(G.release(G.move(begin('corner'),{x:10,y:0}),400,false,0.1,true).action,'close');
    assert.equal(G.release(begin('corner'),200,true,1,true).action,'cancel');
    assert.equal(G.pushAllowed(2,2,0,'always'),true);assert.equal(G.pushAllowed(2.01,2,0,'always'),false);
    assert.equal(G.pushAllowed(1,1,1,'always'),false);assert.equal(G.pushAllowed(1,1,0,'onApproach'),false);
    assert.equal(G.dwell(149,true,0,'always'),false);assert.equal(G.dwell(150,true,0,'always'),true);
    assert.equal(G.dwell(500,false,0,'always'),false);assert.equal(G.dwell(500,true,1,'always'),false);
    assert.equal(G.dwell(500,true,0,'onApproach'),false);assert.equal(G.dwell(0,true,0,'always',0),true);
});
// A-DIAL-11, A-DIAL-12
 test('fine boundaries, rebase and continuous unsnapped detent escape',()=>{
    for(const [d,g] of [[22,1],[22.001,0.25],[66,0.25],[66.001,0.1]])assert.equal(G.fineGain(d,true),g);
    assert.equal(G.fineGain(100,false),1);
    const options={startAngle:3,fineEnabled:true,snap:false,floor:1};
    let a=G.dial(begin(),45,0,options);assert.equal(a.value,50);
    let b=G.dial(a.state,50,30,options);assert.equal(b.value,50);
    let c=G.dial(b.state,58.4,30,options);assert.ok(Math.abs(c.value-52.5)<1e-9);
    let d=G.dial(c.state,60,0,options);assert.equal(d.value,c.value);
    let e=G.dial(d.state,68.4,0,options);assert.ok(Math.abs(e.value-62.5)<1e-9);
    const snap={...options,snap:true};
    a=G.dial(begin(),3+84*0.52,0,snap);assert.equal(a.value,50);assert.equal(a.tick,true);
    b=G.dial(a.state,3+84*0.519,0,snap);assert.equal(b.tick,false);assert.notEqual(b.state.raw,50);
    c=G.dial(b.state,3+84*0.521,0,snap);assert.ok(c.value>52);
    assert.equal(G.dial(begin(),-100,0,snap).value,1);
});
// A-TOGGLE-4, A-CLOSE-1
 test('arc scroll direct travel, slot snap, hit limits and dismissal deadlines',()=>{
    assert.equal(G.arcMove(2,48,5),1);assert.equal(G.arcMove(0,48,5),0);assert.equal(G.arcMove(5,-48,5),5);
    assert.equal(G.arcSnap(1.5,0,5),2);assert.equal(G.arcSnap(1.2,1,5),2);assert.equal(G.arcSnap(0,-1,5),0);
    assert.equal(G.arcHit(6,240),false);assert.equal(G.arcHit(45,240),true);assert.equal(G.arcHit(84,240),false);
    assert.equal(G.dismissal(false,false,599,'leave'),false);assert.equal(G.dismissal(false,false,600,'leave'),true);
    assert.equal(G.dismissal(false,false,9999,'idle'),false);assert.equal(G.dismissal(false,false,10000,'idle'),true);
    assert.equal(G.dismissal(true,false,20000,'idle'),false);assert.equal(G.dismissal(false,true,20000,'idle'),false);
});
// A-OPEN-4, A-CLOSE-1, A-THEME-4
 test('session reducer reversals, capture ownership and deferred dismissal',()=>{
    let s=G.reduce(G.initial(),{type:'OPEN'}).state;
    assert.equal(s.phase,'opening');const old=s.generation;
    s=G.reduce(s,{type:'DISMISS',reason:'outside'}).state;assert.equal(s.phase,'closing');
    s=G.reduce(s,{type:'OPEN'}).state;assert.equal(s.phase,'opening');
    assert.equal(G.reduce(s,{type:'SETTLED',generation:old}).state.phase,'opening');
    s=G.reduce(s,{type:'SETTLED',generation:s.generation}).state;
    s=G.reduce(s,{type:'RING_DOWN',id:'volume',point:p,time:0,value:50}).state;
    assert.equal(s.phase,'dragging');assert.equal(s.capture.id,'volume');
    assert.equal(G.reduce(s,{type:'EXTERNAL'}).effects[0].action,'storeConfirmed');
    s=G.reduce(s,{type:'DISMISS',reason:'idleTimeout'}).state;assert.equal(s.deferred,null);
    s=G.reduce(s,{type:'ESCAPE'}).state;assert.ok(s.deferred);
    const ended=G.reduce(s,{type:'CANCEL',time:100});assert.equal(ended.state.phase,'closing');assert.equal(ended.state.capture,null);
    const forced=G.reduce(s,{type:'FORCE_HIDE',reason:'lock'});assert.equal(forced.state.phase,'closed');assert.equal(forced.state.capture,null);
    assert.equal(G.reduce(s,{type:'REDUCE',enabled:true}).effects[0].action,'finishChannels');
});
test('corner session tap and drag destinations, push guard and geometry cancellation',()=>{
    let s=G.reduce(G.initial(),{type:'PUSH_ENTER',buttons:1}).state;assert.equal(s.phase,'closed');
    s=G.reduce(s,{type:'PUSH_ENTER',mode:'onApproach'}).state;assert.equal(s.phase,'closed');
    s=G.reduce(s,{type:'PUSH_ENTER'}).state;assert.equal(s.phase,'hinting');
    s=G.reduce(s,{type:'PUSH_LEAVE'}).state;assert.equal(s.phase,'closed');
    s=G.reduce(s,{type:'CORNER_DOWN',point:p,time:0}).state;
    let r=G.reduce(s,{type:'RELEASE',time:100,insideZone:true,progress:0});assert.equal(r.state.phase,'opening');
    assert.equal(r.effects.filter(e=>e.action==='closing').length,0);
    r=G.reduce(s,{type:'RELEASE',time:500,insideZone:false,progress:0.4});assert.equal(r.state.phase,'closing');
    r=G.reduce(s,{type:'GEOMETRY'});assert.equal(r.state.phase,'closing');assert.equal(r.state.capture,null);
    assert.equal(G.reduce(s,{type:'GEOMETRY',outputLost:true}).state.phase,'closed');
    assert.equal(G.reduce(s,{type:'MADE_UP'}).error,'unknown_event');
});
test('detail replacement keeps transition generation and Back restores open state',()=>{
    const opened={...G.initial(),phase:'open'};
    const a=G.reduce(opened,{type:'DETAIL',id:'wifi',supported:true}).state;
    assert.equal(a.phase,'detail');
    const b=G.reduce(a,{type:'DETAIL',id:'bluetooth',supported:true}).state;assert.equal(b.generation,a.generation);assert.equal(b.detailId,'bluetooth');
    assert.equal(G.reduce(b,{type:'BACK'}).state.phase,'open');assert.equal(G.reduce(b,{type:'ESCAPE'}).state.phase,'open');
    assert.equal(G.reduce(opened,{type:'DETAIL',supported:false}).state.phase,'open');
});
