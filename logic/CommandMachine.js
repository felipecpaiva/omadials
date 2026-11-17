.pragma library
const READ_DELAY=450;
const KINDS=Object.freeze(['dial','stepped','toggle','picker','readout']);
const AVAILABILITY=Object.freeze(['probing','available','unavailable','error']);
const WRITE_STATES=Object.freeze(['idle','pending','failed']);
const DETAIL_KINDS=Object.freeze(['none','rows','custom','external']);
function kind(v) {switch(v){case 'dial':case 'stepped':case 'toggle':case 'picker':case 'readout':return v;default:return {error:'unknown_kind'};}}
function availability(v) {switch(v){case 'probing':case 'available':case 'unavailable':case 'error':return v;default:return {error:'unknown_availability'};}}
function writeState(v) {switch(v){case 'idle':case 'pending':case 'failed':return v;default:return {error:'unknown_write_state'};}}
function detailKind(v) {switch(v){case 'none':case 'rows':case 'custom':case 'external':return v;default:return {error:'unknown_detail_kind'};}}
function initial(value) {return {confirmed:value,proposed:value,value:value,writeState:'idle',availability:'available',lastError:'',generation:0};}
// The runner owns real timeout policy. Every completion and timer echoes generation.
function reduce(previous,event) {
    const s=Object.assign({},previous),effects=[];
    function fail(reason) {s.writeState='failed';s.value=s.confirmed;s.proposed=s.confirmed;s.lastError=reason||'Command failed';}
    if(event.generation!==undefined&&event.generation!==s.generation)return {state:s,effects:effects};
    switch(event.type) {
    case 'SET':
        if(s.writeState==='pending'||s.availability!=='available')break;
        s.generation++;s.proposed=event.value;s.value=event.value;s.writeState='pending';s.lastError='';
        effects.push({run:event.argv,generation:s.generation,phase:'write'});
        if(event.timeoutMs!==undefined)effects.push({after:event.timeoutMs,type:'TIMEOUT',generation:s.generation});
        break;
    case 'WRITTEN':
        if(s.writeState!=='pending')break;
        if(event.code!==0)fail(event.reason);else effects.push({after:READ_DELAY,type:'REREAD',generation:s.generation});
        break;
    case 'REREAD':
        if(s.writeState==='pending')effects.push({run:event.argv,phase:'read',generation:s.generation});break;
    case 'READ': {
        const parsed=availability(event.availability);
        if(typeof parsed!=='string'||((parsed==='error'||parsed==='unavailable')&&!event.reason)) {
            s.availability='error';fail('Unknown or invalid backend state: '+String(event.availability));break;
        }
        s.availability=parsed;
        if(parsed==='error'||parsed==='unavailable'){fail(event.reason);break;}
        if(parsed==='probing')break;
        if(s.writeState==='pending'&&event.value!==s.proposed){fail(event.reason||'Read-back did not confirm requested value');break;}
        s.confirmed=event.value;s.value=event.value;s.proposed=event.value;s.writeState='idle';s.lastError='';break;
    }
    case 'FAIL':case 'TIMEOUT':
        if(s.writeState==='pending')fail(event.reason||(event.type==='TIMEOUT' ? 'Command timed out' : 'Command failed'));break;
    default: break;
    }
    return {state:s,effects:effects};
}
