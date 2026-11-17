.pragma library
const CURVE=Object.freeze([0.23,1,0.32,1]);
const ITERATIONS=40, CUBIC=3, HALF=0.5, SLOW_FACTOR=4;
const TIMES=Object.freeze({open:180,close:120,stagger:20,hint:80,press:80,return:120,fill:120,value:120,bubble:80,bubbleHold:600,tickIn:40,tickOut:80,pending:900,detail:200,detailOut:80,detailIn:120,snap:160,theme:160});
function cubic(t,a,b) {const u=1-t;return CUBIC*u*u*t*a+CUBIC*u*t*t*b+t*t*t;}
function ease(x) {
    if(x<=0)return 0;if(x>=1)return 1;
    let lo=0,hi=1;
    for(let i=0;i<ITERATIONS;i++) {const t=(lo+hi)*HALF;if(cubic(t,CURVE[0],CURVE[2])<x)lo=t;else hi=t;}
    return cubic((lo+hi)*HALF,CURVE[1],CURVE[3]);
}
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
