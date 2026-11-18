import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S=loadLocal('./map.js');
assert.equal(S.reading(true,0.55,false),55);
assert.equal(S.reading(false,0.55,false),null);
assert.equal(S.reading(true,0,true),null);
assert.equal(S.reading(true,0,false),0);
assert.equal(S.reading(true,NaN,false),null);
assert.equal(S.text(false,null),'not connected');
assert.equal(S.text(true,null),'unknown');
assert.equal(S.low(20,false,20),true);
assert.equal(S.low(21,false,20),false);
assert.equal(S.low(5,true,20),false);
assert.equal(S.low(null,false,20),false);
