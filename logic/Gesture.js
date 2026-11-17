.pragma library
const DRAG=6, LABEL_CANCEL=10, HOLD_START=150, HOLD=450, TAP=400, TAP_MOVE=10;
const TRIGGER=32, PUSH=2, DWELL=150, OPEN_THRESHOLD=0.4, LEAVE=600, IDLE=10000;
const FINE_NEAR=22, FINE_FAR=66, FINE_GAIN=0.25, FINER_GAIN=0.1;
const DETENT=25, SNAP_WINDOW=2, PERCENT=100, SWEEP=84, ARC_START=6, ARC_END=84, TARGET=48, DEGREES=180, HALF=0.5;
function clamp(v,lo,hi) {return Math.max(lo,Math.min(hi,v));}
function begin(owner,id,p,time,value) {
    return {owner:owner,id:id,start:p,last:p,time:time,moved:false,holdCancelled:false,consumed:false,raw:value,gain:1,lastAngle:null,detent:null};
}
function move(s,p) {
    const d=Math.hypot(p.x-s.start.x,p.y-s.start.y);
    return Object.assign({},s,{last:p,moved:s.moved||d>=DRAG,
        holdCancelled:s.holdCancelled||d>=(s.owner==='label' ? LABEL_CANCEL : DRAG)});
}
function hold(s,time) {
    const elapsed=time-s.time;
    const fired=!s.holdCancelled&&!s.consumed&&elapsed>=HOLD;
    return {state:Object.assign({},s,{consumed:s.consumed||fired}),action:fired ? 'hold' : null,
        progress:s.holdCancelled||s.consumed ? 0 : clamp((elapsed-HOLD_START)/(HOLD-HOLD_START),0,1)};
}
function release(s,time,cancel,progress,insideZone) {
    if(cancel)return {action:s.owner==='arc'||s.owner==='toggle'&&s.moved ? 'snap' : 'cancel',id:s.id};
    if(s.consumed)return {action:null,id:s.id};
    if(s.owner==='corner') {
        const tap=time-s.time<=TAP&&Math.hypot(s.last.x-s.start.x,s.last.y-s.start.y)<TAP_MOVE&&insideZone;
        return {action:tap||progress>OPEN_THRESHOLD ? 'open' : 'close',id:s.id};
    }
    return {action:s.moved ? (s.owner==='ring' ? 'commit' : 'snap') : 'tap',id:s.id};
}
function pushAllowed(x,y,buttons,mode) {return x<=PUSH&&y<=PUSH&&!buttons&&mode!=='onApproach';}
function dwell(elapsed,inside,buttons,mode,delay) {return inside&&!buttons&&mode!=='onApproach'&&elapsed>=(delay===undefined ? DWELL : delay);}
function fineGain(distance,enabled) {return !enabled ? 1 : distance>FINE_FAR ? FINER_GAIN : distance>FINE_NEAR ? FINE_GAIN : 1;}
function dial(s,angle,distance,options) {
    const gain=fineGain(distance,options.fineEnabled),first=s.lastAngle===null;
    let raw=s.raw;
    if(first&&gain===1)raw=(angle-options.startAngle)/SWEEP*PERCENT;
    else if(!first&&gain===s.gain)raw+=(angle-s.lastAngle)/SWEEP*PERCENT*gain;
    raw=clamp(raw,0,PERCENT);
    const detent=Math.round(raw/DETENT)*DETENT;
    const snapped=options.snap&&Math.abs(raw-detent)<=SNAP_WINDOW;
    const mark=snapped ? detent : null;
    return {state:Object.assign({},s,{raw:raw,lastAngle:angle,gain:gain,detent:mark}),value:Math.max(options.floor || 0,snapped ? detent : raw),tick:mark!==null&&mark!==s.detent};
}
// Offset is in slots. Tangential travel is direct, with no inertia.
function arcMove(offset,tangential,max) {return clamp(offset-tangential/TARGET,0,max);}
function arcSnap(offset,direction,max) {return clamp(Math.round(offset)+(direction || 0),0,max);}
function arcHit(angle,radius) {const half=TARGET/radius*DEGREES/Math.PI*HALF;return angle>=ARC_START+half&&angle<=ARC_END-half;}
function dismissal(captured,longPress,elapsed,kind) {
    return !captured&&!longPress&&elapsed>=(kind==='leave' ? LEAVE : IDLE);
}
const STATES=Object.freeze(['closed','hinting','opening','open','dragging','detail','closing']);
const EVENTS=Object.freeze(['PUSH_ENTER','PUSH_LEAVE','DWELL','OPEN','CORNER_TAP','CORNER_DOWN','RING_DOWN','MOVE','RELEASE','CANCEL','DETAIL','BACK','ESCAPE','DISMISS','ARC_DOWN','ARC_WHEEL','ACTIVATE','ADJUST','EXTERNAL','COMMAND','AVAILABILITY','THEME','REDUCE','GEOMETRY','FORCE_HIDE','SETTLED']);
const TIMEOUT_REASONS=Object.freeze(['leaveTimeout','idleTimeout']);
function initial() {return {phase:'closed',generation:0,capture:null,deferred:null,detailId:null};}
// Classification and session transitions are pure. Views execute the named effects.
function reduce(previous,event) {
    const s=Object.assign({},previous),effects=[];
    function transition(phase) {s.phase=phase;s.generation++;effects.push({action:phase,generation:s.generation});}
    function endCapture(cancel,destination) {
        const owner=s.capture&&s.capture.owner;
        effects.push({action:cancel ? 'cancelCapture' : 'releaseCapture',capture:s.capture});s.capture=null;
        transition(destination||(owner==='corner' ? 'closing' : 'open'));
        effects.push({action:'relayout'});
        if(s.deferred){s.deferred=null;transition('closing');}
    }
    if(EVENTS.indexOf(event.type)<0)return {state:s,effects:effects,error:'unknown_event'};
    switch(event.type) {
    case 'FORCE_HIDE': s.capture=null;s.deferred=null;transition('closed');effects.push({action:'suppressTrigger'});break;
    case 'GEOMETRY':
        if(s.capture)endCapture(true);
        if(event.outputLost)transition('closed');effects.push({action:'snapGeometry'});break;
    case 'PUSH_ENTER':
        if(s.phase==='closed'&&!event.buttons&&event.mode!=='onApproach'){s.phase='hinting';effects.push({after:event.delay===undefined ? DWELL : event.delay,action:'dwell'});}break;
    case 'PUSH_LEAVE':if(s.phase==='hinting')s.phase='closed';break;
    case 'DWELL':if(s.phase==='hinting'&&event.inside&&!event.buttons)transition('opening');break;
    case 'OPEN':case 'CORNER_TAP':
        if(s.capture)break;
        if(event.type==='CORNER_TAP'&&(s.phase==='opening'||s.phase==='open'))transition('closing');
        else if(['closed','hinting','closing'].indexOf(s.phase)>=0)transition('opening');break;
    case 'CORNER_DOWN':case 'RING_DOWN':case 'ARC_DOWN': {
        const owner=event.type==='CORNER_DOWN' ? 'corner' : event.type==='RING_DOWN' ? 'ring' : 'arc';
        const allowed=owner==='corner' ? ['closed','hinting'] : ['opening','open'];
        if(allowed.indexOf(s.phase)>=0&&!s.capture){s.capture=begin(owner,event.id,event.point,event.time,event.value);s.phase='dragging';}break;
    }
    case 'MOVE':if(s.capture)s.capture=move(s.capture,event.point);break;
    case 'RELEASE':case 'CANCEL':
        if(s.capture){
            const result=release(s.capture,event.time,event.type==='CANCEL',event.progress,event.insideZone);
            const owner=s.capture.owner;
            endCapture(event.type==='CANCEL',owner==='corner'&&result.action==='open' ? 'opening' : undefined);effects.push(result);
        }break;
    case 'DETAIL':
        if(!s.capture&&event.supported&&['opening','open','detail'].indexOf(s.phase)>=0){
            s.detailId=event.id;if(s.phase!=='detail')transition('detail');
        }break;
    case 'BACK':if(s.phase==='detail')transition('open');break;
    case 'ESCAPE':case 'DISMISS':
        if(s.capture){if(event.type==='ESCAPE'||TIMEOUT_REASONS.indexOf(event.reason)<0)s.deferred=event;}
        else if(event.type==='ESCAPE'&&s.phase==='detail')transition('open');
        else if(['opening','open','detail'].indexOf(s.phase)>=0)transition('closing');break;
    case 'SETTLED':
        if(event.generation===s.generation){if(s.phase==='opening')s.phase='open';else if(s.phase==='closing')s.phase='closed';}break;
    case 'ARC_WHEEL':if(s.phase==='open')effects.push({action:'arcSnap',direction:event.direction});break;
    case 'EXTERNAL':case 'COMMAND':effects.push({action:s.capture&&s.capture.owner==='ring' ? 'storeConfirmed' : 'reconcile',event:event});break;
    case 'AVAILABILITY':effects.push({action:'disableWrites',id:event.id});if(!s.capture)effects.push({action:'relayout'});break;
    case 'REDUCE':if(event.enabled)effects.push({action:'finishChannels'});break;
    case 'THEME':effects.push({action:'retargetColours'});break;
    case 'ACTIVATE':case 'ADJUST':if(['open','detail'].indexOf(s.phase)>=0)effects.push({action:'intent',event:event});break;
    default:break;
    }
    return {state:s,effects:effects};
}
