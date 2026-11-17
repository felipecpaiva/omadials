import test from 'node:test';
import assert from 'node:assert/strict';
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
