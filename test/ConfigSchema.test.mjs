import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {load} from './load.mjs';
const C=load('ConfigSchema');
const clone=x=>JSON.parse(JSON.stringify(x));
const catalog=Object.keys(C.DEFAULTS.controls).concat(['headphones','signal']).map(id=>({id,kind:['headphones','signal'].includes(id)?'readout':'dial',placements:['brightness','volume','mic','headphones','signal'].includes(id)?['ring']:['arc']}));
const validate=x=>C.validate(x,catalog,{themes:['white','tokyo-night'],icons:['custom-icon']});
function at(obj,path,value){const keys=path.split('.');let cur=obj;for(const k of keys.slice(0,-1))cur=cur[k]??={};cur[keys.at(-1)]=value;return obj;}
for(const name of ['valid','invalid','partial','unknown-keys'])test(`config fixture ${name}`,()=>{
    const fixture=JSON.parse(readFileSync(new URL(`fixtures/${name}.json`,import.meta.url),'utf8'));
    const original=clone(fixture.input),r=validate(fixture.input);
    assert.deepEqual(r.errors.map(e=>[e.path,e.code]),fixture.errors);assert.deepEqual(fixture.input,original);
    for(const [path,value] of Object.entries(fixture.expected)){
        assert.deepEqual(path.split('.').reduce((o,k)=>o[k],r.config),value);
    }
});
// A-TOGGLE-6, A-DIAL-9, A-ICON-4
const enumPaths={corner:'corner',size:'size',mode:'outputs.mode',iconMode:'cornerIcon.mode',track:'ringStyle.track',knob:'ringStyle.knob',thickness:'ringStyle.thickness',tabStyle:'tabStyle',toggleScroll:'toggleScroll',style:'animation.style'};
for(const [key,path] of Object.entries(enumPaths))test(`every ${key} enum accepts members and reports invalid values`,()=>{
    for(const value of C.ENUMS[key])assert.ok(!validate(at({version:1},path,value)).errors.some(e=>e.path===path));
    const r=validate(at({version:1},path,'invalid'));
    assert.ok(r.errors.some(e=>e.path===path&&e.code==='unknown_value'));
});
for(const id of ['wifi','bluetooth','kbdlight','theme','media','dnd'])test(`${id} catalog action enums`,()=>{
    const actions=C.ACTIONS[id]||['switch','quickDetail'];
    for(const field of ['tapAction','holdAction']){
        for(const value of actions){const e={id,tapAction:actions[0],holdAction:'quickDetail',[field]:value};assert.equal(validate({version:1,toggles:[e]}).errors.length,0);}
        assert.ok(validate({version:1,toggles:[{id,[field]:'run-shell'}]}).errors.some(e=>e.path.endsWith(field)&&e.code==='unknown_value'));
    }
});
for(const source of C.ENUMS.source)test(`readout source ${source}`,()=>{
    const e={id:'headphones',order:4,source,...(source==='bluetoothBattery'?{deviceAddress:'00:11:22:33:44:55'}:source==='penBattery'?{devicePath:'/org/freedesktop/UPower/devices/test'}:source==='wifiSignal'?{interface:'auto'}:{})};
    assert.equal(validate({version:1,readoutRings:[e]}).errors.length,0);
    const invalid=validate({version:1,readoutRings:[{...e,source:'invalid'}]});assert.ok(invalid.errors.some(e=>e.code==='unknown_value'));
});
test('bounds, typed fields, fine settings and cap enum',()=>{
    for(const [path,bad] of [['trigger.pushDelayMs',501],['trigger.pushDelayMs',-1],['behavior.idleTimeoutS',121],['dialInteraction.snapWindowPercent',2.01],['dialInteraction.fineDistancesPx',[66,22]],['dialInteraction.fineGains',[0,1]],['options.volume.maxPercent',125],['gameMode.gapsIn',-1],['outputs.names',[42]],['controls.wifi.shown','yes']]){
        assert.ok(validate(at({version:1},path,bad)).errors.length,path);
    }
    for(const v of [100,150])assert.equal(validate({version:1,options:{volume:{maxPercent:v}}}).errors.length,0);
    assert.ok(validate({version:1,size:'S'}).errors.some(e=>e.code==='over_capacity'));
    assert.ok(validate({version:1,dials:[{id:'volume',order:0},{id:'brightness',order:0}]}).errors.some(e=>e.code==='duplicate_control'));
    assert.ok(validate({version:1,dials:[{id:'wifi'}]}).errors.some(e=>e.code==='wrong_placement'));
    assert.ok(validate({version:1,readoutRings:[{id:'headphones',order:4,source:'wifiSignal',style:{knob:'round'}}]}).errors.some(e=>e.code==='wrong_placement'));
});
test('parse protection, required version, newer version and preserved unknown keys',()=>{
    assert.equal(validate('{').readOnly,true);assert.equal(validate('{').errors[0].code,'parse_error');
    assert.ok(!validate({}).errors.some(e=>e.path==='version'),'an empty file means defaults');
    assert.ok(validate({size:'S'}).errors.some(e=>e.path==='version'),'settings without a version are reported');
    assert.equal(validate({version:2}).readOnly,true);
    const original={version:1,future:{x:42},controls:{futureControl:{shown:true}}};
    const text=C.patch(JSON.stringify(original),'size','L');
    assert.deepEqual(JSON.parse(text),{...original,size:'L'});
    assert.throws(()=>C.patch('{','size','S'));assert.throws(()=>C.patch('{"version":2}','size','S'));
    assert.throws(()=>C.patch('{"version":1}','__proto__.bad',true));
    assert.equal({}.bad,undefined);
});
test('catalog options and resource validation',()=>{
    const custom=catalog.concat([{id:'extra',placements:['arc'],options:{mode:{default:'auto',enum:['auto','manual']}}}]);
    assert.equal(C.validate({version:1,options:{extra:{mode:'bad'}}},custom).errors[0].code,'unknown_value');
    assert.equal(validate({version:1,cornerIcon:{source:'custom-icon'},themePair:{light:'white',dark:'tokyo-night'}}).errors.length,0);
    assert.ok(validate({version:1,cornerIcon:{source:'bad name'}}).errors.some(e=>e.path==='cornerIcon.source'));
    assert.ok(validate({version:1,themePair:{dark:'missing'}}).errors.some(e=>e.path==='themePair.dark'));
});

test('readout style inheritance, incompatible fields and icon runtime fallback',()=>{
    const r=validate({version:1,readoutRings:[{id:'headphones',order:4,source:'laptopBattery',style:{thickness:'bold'}}]});
    assert.equal(r.errors.length,0);assert.equal(r.config.readoutRings[0].style.knob,'none');
    assert.ok(validate({version:1,readoutRings:[{id:'headphones',order:4,source:'laptopBattery',interface:'auto'}]}).errors.some(e=>e.code==='wrong_placement'));
    const icon=validate({version:1,cornerIcon:{source:'bad name'}});assert.equal(icon.config.cornerIcon.source,'default');assert.ok(icon.errors.length);
});
test('partial control objects retain defaults and malformed containers report errors',()=>{
    assert.equal(validate({version:1,controls:{wifi:{icon:'custom-icon'}}}).config.controls.wifi.shown,true);
    for(const key of ['controls','options','dials','readoutRings','toggles','outputs','trigger','behavior','gameMode']){
        assert.ok(validate({version:1,[key]:42}).errors.some(e=>e.code==='wrong_type'),key);
    }
    const bad=validate(JSON.parse('{"version":1,"__proto__":{"polluted":true},"options":{"volume":{"constructor":1}}}'));
    assert.ok(bad.errors.length>=2);assert.equal({}.polluted,undefined);
    assert.ok(validate({version:1,readoutRings:[{id:'headphones',order:4}]}).errors.some(e=>e.path.endsWith('source')));
});
// The shipped defaults validate cleanly against the shipped catalog.
test('defaults validate against the catalog', async()=>{
    const fs=await import('node:fs');
    const cat=JSON.parse(fs.readFileSync(new URL('../controls/catalog.json',import.meta.url),'utf8'));
    const r=C.validate({},cat.controls||cat);
    assert.deepEqual(r.errors,[]);
});
test('the shipped defaults validate cleanly as a whole file', async()=>{
    const fs=await import('node:fs');
    const cat=JSON.parse(fs.readFileSync(new URL('../controls/catalog.json',import.meta.url),'utf8'));
    assert.deepEqual(C.validate(C.DEFAULTS,cat).errors,[]);
});
test('a readout ring is checked by its source against the real catalog', async()=>{
    const fs=await import('node:fs');
    const cat=JSON.parse(fs.readFileSync(new URL('../controls/catalog.json',import.meta.url),'utf8'));
    const r=C.validate({version:1,readoutRings:[{id:'signal',order:3,source:'wifiSignal',interface:'auto'}]},cat);
    assert.deepEqual(r.errors,[]);
});
test('default toggles start with Wi-Fi and keep hidden extras last (ux.md Defaults)',()=>{
    const ids=C.DEFAULTS.toggles.map(t=>t.id);
    assert.equal(ids[0],'wifi'); assert.deepEqual(ids.slice(-2),['touchpad','touchscreen']);
});
test('icons need no installed-icon list: plain names and local svg or png files pass, junk is reported', ()=>{
    for (const ok of ['default','audio-volume-high','wifi','/home/u/icons/x.svg']) assert.equal(C.validate({version:1,cornerIcon:{source:ok}},catalog).errors.length,0,ok);
    for (const bad of ['a b','../x.svg','$(rm)','x'.repeat(65)]) assert.ok(C.validate({version:1,cornerIcon:{source:bad}},catalog).errors.some(e=>e.path==='cornerIcon.source'),bad);
});
test('animation: defaults to Tab morph at 1x with bounce 0.06; bad values are reported and fall back',()=>{
    assert.deepEqual(validate({version:1}).config.animation,{style:'morph',speed:1,bounce:0.06});
    assert.equal(validate({version:1,animation:{style:'fan',speed:0.5,bounce:0}}).errors.length,0);
    assert.equal(validate({version:1,animation:{speed:2,bounce:0.35}}).errors.length,0);
    for(const [path,bad,code] of [['animation.speed',0.49,'out_of_range'],['animation.speed',2.01,'out_of_range'],['animation.bounce',-0.01,'out_of_range'],
        ['animation.bounce',0.36,'out_of_range'],['animation.speed','fast','wrong_type'],['animation.style','bounce','unknown_value'],['animation.extra',1,'unknown_value'],['animation',7,'wrong_type']]){
        const r=validate(at({version:1},path,bad));
        assert.ok(r.errors.some(e=>e.path===path&&e.code===code),`${path}=${bad}`);
        assert.deepEqual(r.config.animation,{style:'morph',speed:1,bounce:0.06});
    }
});
test('theme pair names match the installed list loosely and are kept before the list loads', ()=>{
    const res={themes:['Catppuccin Latte','Tokyo Night']};
    assert.deepEqual(C.validate({version:1,themePair:{light:'catppuccin-latte',dark:'tokyo-night'}},catalog,res).errors,[]);
    assert.ok(C.validate({version:1,themePair:{dark:'nope'}},catalog,res).errors.some(e=>e.path==='themePair.dark'));
    assert.deepEqual(C.validate({version:1,themePair:{light:'catppuccin-latte'}},catalog,{themes:[]}).errors,[]);
});
test('theme toggle: an old togglePair tap reads as the theme list, with no error', ()=>{
    const r=validate({version:1,toggles:[{id:'theme',tapAction:'togglePair',holdAction:'quickDetail'}]});
    assert.equal(r.config.toggles.find(t=>t.id==='theme').tapAction,'quickDetail');
    assert.deepEqual(r.errors.filter(e=>e.path.startsWith('toggles')),[]);
});
test('game mode: null gaps mean leave the gaps alone, with no error', ()=>{
    const r=validate({version:1,gameMode:{gapsIn:null,gapsOut:null}});
    assert.equal(r.config.gameMode.gapsIn,null); assert.equal(r.config.gameMode.gapsOut,null);
    assert.deepEqual(r.errors.filter(e=>e.path.startsWith('gameMode')),[]);
});
