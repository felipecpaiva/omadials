import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const L=load('Labels');
test('known values read as words, unknown values are spaced and capitalised',()=>{
    assert.equal(L.label('bottom-left'),'Bottom left');
    assert.equal(L.label('M'),'Normal');
    assert.equal(L.label('rings2knob'),'2 rings and a knob');
    assert.equal(L.label('someNewAction'),'Some new action');
    assert.deepEqual(L.options(['S']),[{value:'S',label:'Compact'}]);
});
