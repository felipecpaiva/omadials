import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S = loadLocal('./spec.js');
const sample = "amdgpu_bl1,backlight,42598,65%,65535";
assert.equal(S.parse(sample, 0).value, 65);
for (const [text, code] of [['',0],['garbage',0],[sample,1]]) { const p = S.parse(text, code); assert.ok(['error','unavailable'].includes(p.availability)); assert.ok(p.reason); }
assert.equal(S.normalize(0), 1); assert.equal(S.normalize(101), 100); assert.deepEqual(S.write(65, {monitor:'eDP-1'}), ['omarchy-brightness-display','--no-osd','--monitor','eDP-1','65%']);
import {load} from '../../test/load.mjs';
const M = load('CommandMachine');
let state = M.initial(null);
state = M.reduce(state, {type:'READ', ...S.parse(sample,0)}).state;
const confirmed = state.value;
const requested = typeof confirmed === 'boolean' ? !confirmed : typeof confirmed === 'number' ? confirmed + 1 : confirmed;
let result = M.reduce(state, {type:'SET', value:requested, argv:S.write(requested,{})});
assert.equal(result.state.writeState,'pending');
assert.equal(result.effects[0].phase,'write');
const generation = result.state.generation;
result = M.reduce(result.state,{type:'WRITTEN',code:0,generation});
assert.equal(result.effects[0].after,450);
result = M.reduce(result.state,{type:'READ',availability:'available',value:requested,generation});
assert.equal(result.state.writeState,'idle');
result = M.reduce(result.state,{type:'SET',value:confirmed,argv:S.write(confirmed,{})});
result = M.reduce(result.state,{type:'WRITTEN',code:1,reason:'failed',generation:result.state.generation});
assert.equal(result.state.value,requested);
assert.equal(result.state.writeState,'failed');
console.log('PASS command backend');

const catalog=JSON.parse(readFileSync(new URL('../catalog.json',import.meta.url),'utf8'));
assert.equal(new Set(catalog.map(c=>c.id)).size,catalog.length);
for (const entry of catalog) {
    assert.ok(['dial','stepped','toggle','picker','readout'].includes(entry.kind));
    assert.ok(entry.placements.length);
    const folder=new URL('../'+entry.folder+'/',import.meta.url);
    assert.ok(readFileSync(new URL('Backend.qml',folder),'utf8').length);
    const names=entry.options || {};
    for (const option of Object.values(names)) {
        assert.equal(typeof option.default,option.type);
        if (option.min !== undefined) assert.ok(option.default >= option.min);
        if (option.max !== undefined) assert.ok(option.default <= option.max);
    }
}
