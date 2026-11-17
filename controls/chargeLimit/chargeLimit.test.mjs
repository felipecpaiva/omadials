import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const S=new Function(readFileSync(new URL('./spec.js',import.meta.url),'utf8').replace(/^\.pragma library\n/,'')+';return {read,parse,write,normalize}')();
assert.equal(S.parse('85\n',0).value,85);
for(const v of ['', '19','101','NaN','20.5']) assert.equal(S.parse(v,0).value,null);
assert.equal(S.parse('85',1).availability,'unavailable');
for(const v of [20,85,100]) assert.deepEqual(S.write(v),['asusctl','battery','limit',String(v)]);
for(const v of [19,101,20.5,'85',NaN]) assert.equal(S.write(v),null);

assert.equal(S.normalize(84.7),85);
assert.equal(S.normalize(NaN),null);
{ const {readFileSync:r}=await import('node:fs');const src=r(new URL('./spec.js',import.meta.url),'utf8');const n=[...src.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m=>m[1]);
  const C=new Function(src.replace(/^\.pragma library\s*\n/,'')+';return {'+n.join(',')+'};')();
  assert.equal(C.fromSys('85\n').value,85); assert.equal(C.fromSys('').availability,'error'); }
