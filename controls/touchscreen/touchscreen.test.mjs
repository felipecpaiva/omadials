import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const source=readFileSync(new URL('./spec.js',import.meta.url),'utf8').replace(/^\.pragma library\n/,'');
const S=new Function(source+';return {read,parse,write,usableInput}')();
assert.equal(S.parse('',1).availability,'unavailable');
assert.equal(S.parse('device\n',0).availability,'available');
assert.deepEqual(S.write(false),['omarchy','toggle','touchscreen','off']);
assert.equal(S.write('off'),null);
for(const input of ['{}','{','{"keyboards":[{"name":"keyboard"}]}','{"mice":[{"name":"mouse","enabled":false}]}','{"keyboards":[{"name":"virtual keyboard","enabled":true}]}']) assert.equal(S.usableInput(input,0),false);
for(const group of ['keyboards','mice']) assert.equal(S.usableInput(JSON.stringify({[group]:[{name:'physical',enabled:true}]}),0),true);
assert.equal(S.usableInput('{"keyboards":[{"name":"physical","enabled":true}]}',1),false);
// Execute the backend's actual confirmation functions with a fake runner; no device commands run.
const qml=readFileSync(new URL('./Backend.qml',import.meta.url),'utf8');
const functions=qml.slice(qml.indexOf('function set('),qml.indexOf('onActiveChanged:'));
const invoke=new Function('context','method','argument',`with(context) { ${functions}; return method === 'set' ? set(argument) : activate(argument); }`);
function scenario(devices) {
    const writes=[], c={confirmation:false,active:true,guarded:true,stateKnown:true,availability:'available',value:true,writeState:'idle',Spec:S,
        changed:()=>{},fail:message=>writes.push(['fail',message]),apply:v=>writes.push(['write',v]),
        revert:{restart:()=>writes.push(['revert'])},runner:{run:(id,argv,timeout,done)=>{done(devices,0);return true;}},controlId:'touchscreen'};
    c.writes=writes;return c;
}
const blocked=scenario('{}');
invoke(blocked,'set',false);assert.equal(blocked.confirmation,true);assert.deepEqual(blocked.writes,[]);
invoke(blocked,'activate','confirmOff');assert.equal(blocked.writes[0][0],'fail');
const allowed=scenario('{"mice":[{"name":"physical","enabled":true}]}');
invoke(allowed,'activate','confirmOff');assert.deepEqual(allowed.writes,[]);
invoke(allowed,'set',false);invoke(allowed,'activate','confirmOff');
assert.deepEqual(allowed.writes,[['revert'],['write',false]]);
const closed=scenario('{"keyboards":[{"name":"physical","enabled":true}]}');
invoke(closed,'set',false);closed.active=false;invoke(closed,'activate','confirmOff');assert.deepEqual(closed.writes,[]);
