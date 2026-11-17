import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
function loadLocal(name) {
    const source = readFileSync(new URL(name, import.meta.url), 'utf8');
    const names = [...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m => m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/, '') + `;return {${names.join(',')}};`)();
}
const S=loadLocal('./map.js');
assert.deepEqual(S.rows([]),[]);
const rows=S.rows([{name:'wlan0',networks:[{name:'a:b',signalStrength:.65,known:true,connected:true,security:1}]}],10);
assert.equal(rows[0].label,'a:b'); assert.equal(rows[0].sub,'65%');
assert.equal(S.action(rows[0]),'saved');
assert.equal(S.action({known:false,secured:true}),'fullWindow');
assert.equal(S.action({known:false,secured:false}),'connect');

assert.equal(S.rows([{name:"wlan0",networks:[{name:"secure",signalStrength:1,security:0}]}],10)[0].secured,true);
assert.equal(S.rows([{name:"wlan0",networks:[{name:"open",signalStrength:1,security:10}]}],10)[0].secured,false);
