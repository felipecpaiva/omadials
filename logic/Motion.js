.pragma library
const CURVE=Object.freeze([0.23,1,0.32,1]);
const ITERATIONS=40, CUBIC=3, HALF=0.5, SLOW_FACTOR=4;
const TIMES=Object.freeze({open:180,close:120,stagger:20,hint:80,press:80,return:120,fill:120,value:120,bubble:80,bubbleHold:600,tickIn:40,tickOut:80,pending:900,detail:200,detailOut:80,detailIn:120,snap:160,theme:160});
function cubic(t,a,b) {const u=1-t;return CUBIC*u*u*t*a+CUBIC*u*t*t*b+t*t*t;}
// A CSS cubic-bezier [x1,y1,x2,y2]: solve x for t, then evaluate y (y may overshoot 1, as the Fan style's curve does).
function bezier(c,x) {
    if(x<=0)return 0;if(x>=1)return 1;
    let lo=0,hi=1;
    for(let i=0;i<ITERATIONS;i++) {const t=(lo+hi)*HALF;if(cubic(t,c[0],c[2])<x)lo=t;else hi=t;}
    return cubic((lo+hi)*HALF,c[1],c[3]);
}
function ease(x) {return bezier(CURVE,x);}
// Each channel supplies its own full travel, including scale's distinct close endpoint.
function retargetDuration(base,channels) {
    return base*Math.min(1,channels.reduce(function(max,c){
        const distance=Math.abs(c.to-c.current);
        if(c.travel<=0&&distance)throw new Error('Positive full travel required');
        return Math.max(max,distance ? distance/c.travel : 0);
    },0));
}
function duration(ms,reduced,slow) {return reduced ? 0 : ms*(slow ? SLOW_FACTOR : 1);}
function sample(from,to,elapsed,ms) {return ms<=0 ? to : from+(to-from)*ease(elapsed/ms);}
function currentGeneration(callbackGeneration,generation) {return callbackGeneration===generation;}
// Frame spring (docs/motion-research.md, technical findings): mass 1, stiffness (2π/response)², damping
// 4π(1 - bounce)/response, stepped with the real frame time in 1 ms substeps so 60 Hz and 180 Hz agree. Velocity is
// state, so a retarget keeps it and a flick can set it. At rest it snaps to the target and reports done.
const SUBSTEP=0.001, MAX_DT=0.05, REST_X=1e-4, REST_V=1e-3, MS=1000;
function springStep(x,v,target,dt,response,bounce) {
    const w=2*Math.PI/response,k=w*w,c=2*w*(1-bounce),t=Math.min(MAX_DT,Math.max(0,dt)),n=Math.max(1,Math.ceil(t/SUBSTEP)),h=t/n;
    for(let i=0;i<n;i++) {v+=(-k*(x-target)-c*v)*h;x+=v*h;}
    if(Math.abs(x-target)<REST_X&&Math.abs(v)<REST_V)return {x:target,v:0,done:true};
    return {x:x,v:v,done:false};
}
// A tween from `from` to `to` after `elapsed` of `ms` milliseconds on curve c.
function tweenAt(from,to,elapsed,ms,c) {return ms<=0||elapsed>=ms ? to : from+(to-from)*bezier(c,Math.max(0,elapsed)/ms);}
