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
test('status rows read as words',()=>{
    assert.equal(L.statusText({availability:'probing',hidden:true}),'Hidden');
    assert.equal(L.statusText({availability:'probing'}),'Checked when the corner opens');
    assert.equal(L.statusText({availability:'available'}),'Working');
    assert.equal(L.statusText({availability:'unavailable',reason:'No media player'}),'Not on this machine (No media player)');
    assert.equal(L.statusText({availability:'error',reason:'Busy'}),'Problem: Busy');
});
test('animation styles read as words with a one line description each',()=>{
    assert.equal(L.label('morph'),'Tab morph');
    assert.equal(L.label('cascade'),'Spring cascade');
    for (const key of ['morph','hybrid','lens','cascade','minimal','fan']) {
        const text=L.description(key);
        assert.ok(text.length>0 && text.length<=100 && !/[\u2013\u2014\n]/.test(text),key);
    }
    assert.equal(L.description('unknown'),'');
});
