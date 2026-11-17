import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const M=load('Motion');
// A-OPEN-3, A-OPEN-4, A-CLOSE-3, A-THEME-4
 test('Bezier solves x before y and never overshoots',()=>{
    assert.deepEqual(M.CURVE,[0.23,1,0.32,1]);assert.equal(M.ease(0),0);assert.equal(M.ease(1),1);
    // Independent parametric reference at t=0.5: x=0.33125, y=0.875.
    assert.ok(Math.abs(M.ease(0.33125)-0.875)<1e-10);
    let last=0;for(let i=0;i<=100;i++){const y=M.ease(i/100);assert.ok(y>=last&&y<=1);last=y;}
    assert.equal(M.TIMES.open,180);assert.equal(M.TIMES.close,120);assert.equal(M.TIMES.snap,160);
});
test('independent channels reverse from presentation and reject stale completions',()=>{
    const opacity=M.sample(0,1,60,180),scale=M.sample(0.6,1,60,180);
    assert.equal(M.sample(scale,0.8,0,120),scale);
    const ms=M.retargetDuration(120,[{current:opacity,to:0,travel:1},{current:scale,to:0.8,travel:0.2}]);
    assert.ok(Math.abs(ms-120*opacity)<1e-10);assert.equal(M.retargetDuration(180,[{current:0.9,to:1,travel:0.4}]),44.99999999999999);
    assert.equal(M.retargetDuration(180,[{current:1,to:1,travel:0}]),0);
    assert.throws(()=>M.retargetDuration(180,[{current:0,to:1,travel:0}]));
    assert.equal(M.currentGeneration(1,2),false);assert.equal(M.currentGeneration(2,2),true);
    assert.equal(M.duration(180,false,true),720);assert.equal(M.duration(180,true,true),0);
    assert.equal(M.sample(0,1,0,0),1);
});
const run=(x,v,target,hz,response,bounce,limit=2000)=>{let s={x,v,done:false},n=0;while(!s.done&&n<limit){s=M.springStep(s.x,s.v,target,1/hz,response,bounce);n++;}return {s,n};};
test('frame spring: reaches rest in finite frames, stops exactly on target, no overshoot at bounce 0',()=>{
    const {s,n}=run(0,0,1,180,0.3,0);assert.ok(s.done&&s.x===1&&s.v===0);assert.ok(n<180*2,`${n} frames`);
    let x=0,v=0,max=0;for(let i=0;i<360;i++){const r=M.springStep(x,v,1,1/180,0.3,0);x=r.x;v=r.v;max=Math.max(max,x);}assert.ok(max<=1+1e-9);
    let peak=0;x=0;v=0;for(let i=0;i<360;i++){const r=M.springStep(x,v,1,1/180,0.3,0.3);x=r.x;v=r.v;peak=Math.max(peak,x);}assert.ok(peak>1.01,'bounce overshoots');
});
test('frame spring: keeps velocity through a retarget and takes a flick',()=>{
    let r={x:0,v:0};for(let i=0;i<20;i++)r=M.springStep(r.x,r.v,1,1/180,0.3,0);
    const before=r.v;assert.ok(before>0);
    const next=M.springStep(r.x,r.v,0,1/180,0.22,0);assert.ok(next.v>0&&next.x>r.x,'still moving out right after retargeting to 0');
    const flick=M.springStep(0.5,4,1,1/180,0.3,0);assert.ok(flick.x>0.5+4/180*0.9);
});
test('frame spring: 60 Hz and 180 Hz agree, and a long frame is clamped',()=>{
    let a={x:0,v:0},b={x:0,v:0};for(let i=0;i<9;i++)a=M.springStep(a.x,a.v,1,1/60,0.3,0.06);for(let i=0;i<27;i++)b=M.springStep(b.x,b.v,1,1/180,0.3,0.06);
    assert.ok(Math.abs(a.x-b.x)<1e-3,`${a.x} ${b.x}`);   // under 0.5 px at R = 500
    const long=M.springStep(0,0,1,5,0.3,0),clamped=M.springStep(0,0,1,0.05,0.3,0);assert.equal(long.x,clamped.x);
});
test('tween: any bezier, ends exactly, starts from the shown value',()=>{
    assert.equal(M.tweenAt(0.3,1,0,100,[0.05,0.7,0.1,1]),0.3);assert.equal(M.tweenAt(0.3,1,100,100,[0,0,0,1]),1);assert.equal(M.tweenAt(0,1,5,0,[0,0,0,1]),1);
    let over=0;for(let t=0;t<=300;t+=5)over=Math.max(over,M.tweenAt(0,1,t,300,[0.42,1.67,0.21,0.9]));assert.ok(over>1,'snap curve overshoots');
    assert.ok(Math.abs(M.bezier([0.23,1,0.32,1],0.33125)-0.875)<1e-10);
});
