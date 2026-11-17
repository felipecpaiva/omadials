import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S = loadLocal('./spec.js');
const sample = "asus::kbd_backlight,leds,2,67%,3";
assert.equal(S.parse(sample, 0).value, 2);
for (const [text, code] of [['',0],['garbage',0],[sample,1]]) { const p = S.parse(text, code); assert.ok(['error','unavailable'].includes(p.availability)); assert.ok(p.reason); }
assert.equal(S.normalize(2.9, {}),3); assert.equal(S.normalize(-1, {}),0);
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

assert.equal(S.detect('other\nfoo::kbd_backlight\n',0),'foo::kbd_backlight');
assert.equal(S.detect('other',0),'');
assert.equal(S.detect('foo::kbd_backlight',1),'');
{ const {readFileSync:r}=await import('node:fs');const src=r(new URL('./spec.js',import.meta.url),'utf8');const n=[...src.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m=>m[1]);
  const K=new Function(src.replace(/^\.pragma library\s*\n/,'')+';return {'+n.join(',')+'};')();
  assert.equal(K.fromSys('2','3').value,2); assert.equal(K.fromSys('2','3').steps.length,4); assert.equal(K.fromSys('9','3').availability,'error'); }
