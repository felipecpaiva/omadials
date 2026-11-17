import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const qml=readFileSync(new URL('../core/ConfigStore.qml',import.meta.url),'utf8');
const writeSource=qml.slice(qml.indexOf('function write('),qml.indexOf('function undo('));
const write=new Function('context','text','isUndo',`with(context) { ${writeSource}; return write(text,isUndo); }`);
function context({exists=false,missing=true,migrating=true}={}) {
    const calls=[];
    return {calls,saving:false,loaded:true,rawText:'{"version":1,"original":"bytes"}\n',path:'/config/config.json',pendingPrevious:'',pendingText:'',undoing:false,
        Migrate:{migrate:()=>({changed:migrating,backup:'config.v1.bak'})},
        backupExists:exists,backupMissing:missing,
        backup:{path:'',reload:()=>calls.push('inspect'),text:()=>'',setText:t=>calls.push(['backup',t])},
        file:{setText:t=>calls.push(['config',t])},problem:t=>calls.push(['problem',t])};
}
test('migrating write waits for backup save and preserves exact old bytes',()=>{
    const c=context(); assert.equal(write(c,'new',false),true);
    assert.deepEqual(c.calls,['inspect',['backup','{"version":1,"original":"bytes"}\n']]);
    assert.equal(c.backup.path,'/config/config.v1.bak');
    assert.ok(qml.includes('onSaved: file.setText(configStore.pendingText)'));
});
test('existing migration backup is retained and inspection failures abort',()=>{
    const c=context({exists:true});write(c,'new',false);
    assert.deepEqual(c.calls,['inspect',['config','new']]);
    const bad=context({missing:false});assert.equal(write(bad,'new',false),false);
    assert.equal(bad.saving,false);assert.ok(!bad.calls.some(c=>Array.isArray(c)&&c[0]==='config'));
});
test('v1 writes do not create a backup',()=>{
    const c=context({migrating:false});write(c,'new',false);
    assert.deepEqual(c.calls,[['config','new']]);
});

test('explicit reset can replace malformed JSON',()=>{
    const c=context();c.rawText='{';assert.equal(write(c,'new',false),true);
    assert.deepEqual(c.calls,[['config','new']]);
});
