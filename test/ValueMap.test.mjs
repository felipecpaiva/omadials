import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const V=load('ValueMap'),range={min:0,max:100,floor:1};
// A-DIAL-3, A-DIAL-8, A-ACCESS-4
 test('native mapping, brightness floor and truthful over-cap readings',()=>{
    assert.equal(V.nativeValue(0,range),1);assert.equal(V.fromAngle(3,range),1);
    assert.equal(V.angle(50,range),45);assert.equal(V.fraction(null,range),null);
    assert.deepEqual(V.reading(140,range),{value:140,fraction:1,overCap:true});
    assert.equal(V.input(160,{min:0,max:150}),150);assert.equal(V.stepped(1.6,['a','b','c']),2);
});
test('wheel and smooth pixel accumulation',()=>{
    assert.equal(V.wheel(50,-1,false,range).value,55);assert.equal(V.wheel(50,-1,true,range).value,51);
    const a=V.wheel(50,24,false,range,0,true);assert.equal(a.value,50);assert.equal(a.remainder,24);
    const b=V.wheel(a.value,25,false,range,a.remainder,true);assert.equal(b.value,45);assert.equal(b.remainder,1);
    assert.equal(V.wheel(50,-48,false,range,0,true).value,55);
});
test('every keyboard adjustment and endpoints',()=>{
    for(const k of ['ArrowUp','ArrowRight']){assert.equal(V.keyboard(50,k,false,range),55);assert.equal(V.keyboard(50,k,true,range),51);}
    for(const k of ['ArrowDown','ArrowLeft'])assert.equal(V.keyboard(50,k,false,range),45);
    for(const [key,value] of [['PageUp',75],['PageDown',25],['Home',1],['End',100],['Other',50]])assert.equal(V.keyboard(50,key,false,range),value);
});
// A-DIAL-7
 test('stepped crossing ticks once and endpoint holds do not repeat',()=>{
    const steps=['off','low','high'];
    assert.deepEqual(V.stepTransition(0,1,steps),{value:1,tick:true});
    assert.deepEqual(V.stepTransition(2,10,steps),{value:2,tick:false});
    assert.equal(V.stepTransition(2,1,steps).tick,true);assert.equal(V.stepTransition(1,2,steps).tick,true);
});
