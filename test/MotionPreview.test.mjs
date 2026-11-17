import test from 'node:test';
import assert from 'node:assert/strict';
import {load} from './load.mjs';
const M=load('MotionPreview');
test('every style loop starts on the tab, reaches the open corner and ends on the tab',()=>{
    for (const style of M.STYLES) for (const speed of [0.5,1,2]) {
        const [open,hold]=M.phases(style,speed), total=M.cycle(style,speed);
        assert.ok(Math.abs(M.openAmount(style,speed,0.06,0))<1e-9,style);
        assert.ok(Math.abs(M.openAmount(style,speed,0.06,open+hold/2)-1)<1e-9,style);
        assert.ok(Math.abs(M.openAmount(style,speed,0.06,open-1)-1)<0.02,style+' settles '+speed);
        assert.equal(M.openAmount(style,speed,0.06,total-1),0,style);
    }
});
test('faster speed means a shorter loop, and bounce overshoots only spring styles',()=>{
    assert.ok(M.cycle('morph',2)<M.cycle('morph',1) && M.cycle('morph',1)<M.cycle('morph',0.5));
    const peak=(style,bounce)=>Math.max(...Array.from({length:200},(_,i)=>M.openAmount(style,1,bounce,i*M.phases(style,1)[0]/200)));
    assert.ok(peak('cascade',0.35)>1.05);
    assert.ok(peak('cascade',0)<=1+1e-9);
    assert.equal(peak('lens',0.35),peak('lens',0));
});
test('at p 0 every style is exactly the tab, at p 1 the full corner',()=>{
    for (const style of M.STYLES) {
        const f0=M.frame(style,0), f1=M.frame(style,1);
        assert.equal(f0.tab,1,style); assert.ok(f0.alpha===0 || f0.clip<=M.TAB+1e-9,style);
        assert.equal(f1.tab,0,style); assert.ok(f1.surf>=1 && f1.clip>=1,style);
        assert.ok(f1.rings.every(g=>g.alpha===1 && g.sweep>=1 && g.value===1),style);
    }
});
