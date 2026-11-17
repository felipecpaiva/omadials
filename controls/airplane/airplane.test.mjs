import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S=loadLocal('./spec.js');
const radios=[{id:0,type:'wlan',soft:'unblocked'},{id:1,type:'bluetooth',soft:'blocked'}];
assert.equal(S.parse(JSON.stringify({rfkilldevices:radios}),0).value,false);
assert.deepEqual(S.restore(radios),[['rfkill','unblock','0']]);
assert.deepEqual(S.restore([{id:1,type:'bluetooth',soft:'unblocked'}]),[['omarchy-bluetooth-power','on']]);
for (const text of ['', '{}', 'garbage', '{"rfkilldevices":[]}']) assert.equal(S.parse(text,0).availability,'error');
assert.equal(S.parse(JSON.stringify({rfkilldevices:radios}),1).availability,'error');
assert.equal(S.journalValid({version:1,radios}),true);
assert.ok(!S.journalValid({version:2,radios}));
