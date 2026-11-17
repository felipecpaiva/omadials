import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {load} from './load.mjs';
const M=load('ConfigMigrate');
test('v1 round trip preserves unknown data without a backup or mutation',()=>{
    const original={version:1,future:{x:[1,2,3]}},r=M.migrate(original);
    assert.deepEqual(r.config,original);assert.notEqual(r.config,original);assert.equal(r.changed,false);assert.equal(r.backup,null);assert.equal(r.readOnly,false);
});
test('newer, missing and undocumented older versions are never rewritten',()=>{
    for(const version of [undefined,0,-1,1.5,2]){
        const obj={version,future:42},r=M.migrate(obj);assert.equal(r.readOnly,true);assert.ok(r.errors.length);assert.equal(r.config.future,42);
    }
});

test('future migration steps run in order on copies and request the original-version backup',()=>{
    const source=readFileSync(new URL('../logic/ConfigMigrate.js',import.meta.url),'utf8').replace(/^\.pragma library\n/,'').replace('const VERSION=1','const VERSION=3');
    const migrate=new Function(source+';return migrate')();
    const original={version:1,unknown:{value:42}}, calls=[];
    const result=migrate(original,{1:c=>{calls.push(1); return {...c,version:2};},2:c=>{calls.push(2); return {...c,version:3};}});
    assert.deepEqual(calls,[1,2]); assert.equal(result.backup,'config.v1.bak');
    assert.equal(result.changed,true); assert.deepEqual(original,{version:1,unknown:{value:42}});
    assert.equal(migrate(original,{1:c=>c}).readOnly,true);
    assert.equal(migrate(original,{}).readOnly,true);
});
