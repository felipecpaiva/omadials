import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
import {load} from './load.mjs';
const C=load('Contrast');
// Fallbacks are the installed Omarchy colors.toml values read during implementation.
const fallback={white:{background:'#ffffff',foreground:'#000000',accent:'#6e6e6e'},'tokyo-night':{background:'#1a1b26',foreground:'#a9b1d6',accent:'#7aa2f7'},'flexoki-light':{background:'#FFFCF0',foreground:'#100F0F',accent:'#205EA6'}};
function palette(name){
    const path=`/usr/share/omarchy/themes/${name}/colors.toml`;
    if(!existsSync(path))return fallback[name];
    return Object.fromEntries([...readFileSync(path,'utf8').matchAll(/^(\w+)\s*=\s*"(#[a-f\d]{6})"/gim)].map(m=>[m[1],m[2]]));
}
// A-THEME-1, A-THEME-5
for(const name of Object.keys(fallback))test(`${name} real theme contrast`,()=>{
    const p=palette(name),r=C.roles(p);assert.equal(r.light,name!=='tokyo-night');
    assert.ok(r.textPass);assert.ok(r.controlsPass);assert.equal(r.ink,p.background);assert.equal(r.fill,p.accent);
    assert.ok(C.ratio(r.fill,r.ink)>=3);assert.ok(C.ratio(r.text,p.background)>=4.5);
    assert.ok(!Object.values(r).includes(p.muted));
});
test('luminance reference and accent fallback',()=>{
    assert.equal(C.luminance('#000000'),0);assert.equal(C.luminance('#ffffff'),1);assert.equal(C.ratio('#ffffff','#000000'),21);
    assert.equal(C.accent({background:'#ffffff',foreground:'#000000',accent:'#eeeeee'}),'#000000');
    assert.throws(()=>C.luminance('invalid'));
});
test('intermediate colours snap when text or control contrast fails',()=>{
    const current={ink:'#888888',fill:'#888888'},target={ink:'#ffffff',fill:'#000000'};
    assert.deepEqual(C.transitionPair(current,target,true),target);assert.deepEqual(C.transitionPair(current,target,false),target);
    assert.deepEqual(C.transitionPair(target,current,true),target);
});
