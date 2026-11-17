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
