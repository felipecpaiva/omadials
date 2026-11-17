.pragma library
const PERCENT=100, STEP=5, FINE_STEP=1, PAGE_STEP=25, PIXELS_PER_STEP=48;
const START=3, END=87;
function clamp(v,min,max) {return Math.max(min,Math.min(max,v));}
function floor(range) {return range.floor === undefined ? range.min : Math.max(range.min,range.floor);}
function input(v,range) {return clamp(v,floor(range),range.max);}
function fraction(v,range) {return v===null ? null : clamp((v-range.min)/(range.max-range.min),0,1);}
function nativeValue(f,range) {return input(range.min+clamp(f,0,1)*(range.max-range.min),range);}
function angle(v,range) {const f=fraction(v,range);return f===null ? null : START+(END-START)*f;}
function fromAngle(a,range) {return nativeValue((a-START)/(END-START),range);}
function reading(v,range) {return {value:v,fraction:fraction(v,range),overCap:v!==null&&v>range.max};}
function stepped(v,steps) {return clamp(Math.round(v),0,steps.length-1);}
function wheel(value,delta,shift,range,remainder,pixel,step) {
    const total=(remainder || 0)+delta;
    const count=pixel ? Math.trunc(total/PIXELS_PER_STEP) : Math.sign(delta);
    return {value:input(value-count*(shift ? FINE_STEP : (step>0 ? step : STEP)),range),remainder:pixel ? total-count*PIXELS_PER_STEP : 0};
}
function keyboard(value,key,shift,range) {
    const step=shift ? FINE_STEP : STEP;
    switch(key) {
    case 'ArrowUp': case 'ArrowRight': return input(value+step,range);
    case 'ArrowDown': case 'ArrowLeft': return input(value-step,range);
    case 'PageUp': return input(value+PAGE_STEP,range);
    case 'PageDown': return input(value-PAGE_STEP,range);
    case 'Home': return floor(range);
    case 'End': return range.max;
    default: return value;
    }
}
function stepTransition(previous,value,steps) {
    const before=stepped(previous,steps),after=stepped(value,steps);
    return {value:after,tick:before!==after};
}
