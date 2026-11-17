import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const C=load('CommandMachine');
// A-TOGGLE-3, A-TOGGLE-9
for(const [set,map] of [['KINDS','kind'],['AVAILABILITY','availability'],['WRITE_STATES','writeState'],['DETAIL_KINDS','detailKind']])test(`${set} exhaustive mapping and unknown guard`,()=>{
    assert.ok(Object.isFrozen(C[set]));for(const value of C[set])assert.equal(C[map](value),value);
    assert.ok(C[map]('unrecognised').error);
});
const set=(s,value=65)=>C.reduce(s,{type:'SET',value,argv:['fake-volume',String(value)],timeoutMs:2000});
test('volume fake runner end to end with read-back confirmation',()=>{
    let r=set(C.initial(40));assert.equal(r.state.value,65);assert.equal(r.state.confirmed,40);assert.equal(r.state.writeState,'pending');
    const run=r.effects[0];assert.deepEqual(run.run,['fake-volume','65']);assert.equal(r.effects[1].after,2000);
    const runner=effect=>({type:'WRITTEN',generation:effect.generation,code:effect.run[0]==='fake-volume'?0:1});
    r=C.reduce(r.state,runner(run));assert.equal(r.effects[0].after,450);
    r=C.reduce(r.state,{type:'REREAD',generation:run.generation,argv:['fake-volume-read']});assert.equal(r.effects[0].phase,'read');
    r=C.reduce(r.state,{type:'READ',generation:run.generation,availability:'available',value:65});
    assert.equal(r.state.confirmed,65);assert.equal(r.state.writeState,'idle');
});
for(const event of [{type:'FAIL',reason:'refused'},{type:'TIMEOUT'},{type:'WRITTEN',code:1,reason:'exit failure'},{type:'READ',availability:'available',value:20}])test(`failure rollback ${event.type} ${event.code??''}`,()=>{
    const pending=set(C.initial(40));const r=C.reduce(pending.state,event);
    assert.equal(r.state.writeState,'failed');assert.equal(r.state.value,40);assert.equal(r.state.confirmed,40);assert.ok(r.state.lastError);
    assert.equal(r.effects.length,0);
    const refreshed=C.reduce(r.state,{type:'READ',availability:'available',value:42});assert.equal(refreshed.state.lastError,'');assert.equal(refreshed.state.value,42);
});
test('pending dedupe, stale callbacks and independent command machines',()=>{
    const a=set(C.initial(40));assert.deepEqual(set(a.state,70),{state:a.state,effects:[]});
    assert.deepEqual(C.reduce(a.state,{type:'TIMEOUT',generation:0}),{state:a.state,effects:[]});
    assert.equal(set(C.initial(10),20).state.value,20);
    let s=C.reduce(a.state,{type:'FAIL',reason:'no'}).state;s=set(s,80).state;
    assert.equal(C.reduce(s,{type:'TIMEOUT',generation:1}).state.writeState,'pending');
});
test('unknown backend output is error, unavailable disables writes',()=>{
    for(const value of ['unexpected','unavailable','error']){
        const r=C.reduce(C.initial(40),{type:'READ',availability:value,value:false});
        assert.equal(r.state.availability,'error');assert.ok(r.state.lastError.includes(value));
    }
    let s=C.reduce(C.initial(40),{type:'READ',availability:'unavailable',reason:'No device'}).state;
    assert.equal(set(s).effects.length,0);assert.equal(s.lastError,'No device');
});
