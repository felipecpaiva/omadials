import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S=loadLocal('./map.js');
assert.deepEqual(S.rows([]),[]);
assert.equal(S.rows([{address:'AA',batteryAvailable:true,battery:.8,connected:true}])[0].sub,'80%');
assert.equal(S.reading({connected:false,batteryAvailable:true,battery:.8}),null);
assert.equal(S.reading({connected:true,batteryAvailable:false}),null);
assert.equal(S.reading({connected:true,batteryAvailable:true,battery:0}),0);
