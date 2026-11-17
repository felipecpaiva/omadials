import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S=loadLocal('./map.js');
const intended=S.intended({animations:false,blur:false,shadows:false,gapsIn:0,gapsOut:0});
assert.match(S.lua(intended),/^hl\.config\(/);
assert.equal(S.parse('{"bool":true}',S.OPTIONS[0]),true);
assert.equal(S.parse('{"custom":"5 5 5 5"}',S.OPTIONS[3]),'5 5 5 5');
assert.throws(()=>S.parse('{}',S.OPTIONS[0]));
assert.throws(()=>S.parse('garbage',S.OPTIONS[0]));
assert.throws(()=>S.lua({...intended,gapsIn:'0;exec'}));
assert.ok(S.equal(intended,{...intended,gapsIn:'0 0 0 0'}));
assert.ok(!S.equal(intended,{...intended,animations:true}));
assert.ok(S.validJournal({version:1,instance:'test',ownerPid:123,ownerStart:'999',baseline:intended,intended}));
assert.ok(!S.validJournal({version:1,instance:'',baseline:intended,intended}));

assert.equal(S.processStart('123 (a tricky ) name) S ' + Array(18).fill('0').join(' ') + ' 999'), '999');
assert.throws(()=>S.processStart('invalid'));
// Read-back from Hyprland 0.56 (spike S8): gaps arrive as css text.
assert.equal(loadLocal('map.js').parse('{"option": "general:gaps_in", "css": "0 0 0 0", "set": true }',{key:'gapsIn',type:'gaps'}),'0 0 0 0');
