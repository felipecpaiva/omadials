import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S=loadLocal('./map.js');
assert.equal(S.reading({volume:1.1}),110);
assert.equal(S.reading(null),null);
assert.equal(S.reading({volume:NaN}),null);
assert.equal(S.input(150,100),1);
assert.equal(S.input(150,150),1.5);
assert.equal(S.input(-1,100),0);
assert.equal(S.input(NaN,100),null);
