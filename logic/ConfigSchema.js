.pragma library
const DEFAULTS = {
    "version": 1,
    "corner": "bottom-left",
    "size": "M",
    "outputs": {"mode":"all","names":[]},
    "trigger": {"tapZone":true,"pushDelayMs":150},
    "cornerIcon": {"mode":"always","aboveWindows":true,"source":"default"},
    "controls": {
        "brightness": {"shown":true,"icon":"default"},
        "volume": {"shown":true,"icon":"default"},
        "mic": {"shown":true,"icon":"default"},
        "wifi": {"shown":true,"icon":"default"},
        "bluetooth": {"shown":true,"icon":"default"},
        "nightlight": {"shown":true,"icon":"default"},
        "dnd": {"shown":true,"icon":"default"},
        "keepawake": {"shown":true,"icon":"default"},
        "kbdlight": {"shown":true,"icon":"default"},
        "airplane": {"shown":true,"icon":"default"},
        "gameMode": {"shown":true,"icon":"default"},
        "theme": {"shown":true,"icon":"default"},
        "media": {"shown":true,"icon":"default"},
        "touchpad": {"shown":false,"icon":"default"},
        "touchscreen": {"shown":false,"icon":"default"},
        "recording": {"shown":false,"icon":"default"},
        "headphones": {"shown":false,"icon":"default"},
        "signal": {"shown":false,"icon":"default"}
    },
    "behavior": {"idleTimeoutS":10,"closeOnPointerLeave":true},
    "ringStyle": {"track":"solid","knob":"round","thickness":"normal"},
    "readoutRings": [],
    "dials": [{"id":"brightness","order":0,"style":{"track":"solid","knob":"round","thickness":"normal"}},{"id":"volume","order":1,"style":{"track":"solid","knob":"round","thickness":"normal"}},{"id":"mic","order":2,"style":{"track":"solid","knob":"round","thickness":"normal"}}],
    "toggles": [{"id":"wifi","tapAction":"switchRadio","holdAction":"quickDetail"},{"id":"bluetooth","tapAction":"switchPower","holdAction":"quickDetail"},{"id":"nightlight","tapAction":"switch","holdAction":"quickDetail"},{"id":"dnd","tapAction":"switch","holdAction":"quickDetail"},{"id":"keepawake","tapAction":"switch","holdAction":"quickDetail"},{"id":"kbdlight","tapAction":"nextStep","holdAction":"quickDetail"},{"id":"airplane","tapAction":"switch","holdAction":"quickDetail"},{"id":"gameMode","tapAction":"switch","holdAction":"quickDetail"},{"id":"theme","tapAction":"togglePair","holdAction":"quickDetail"},{"id":"media","tapAction":"quickDetail","holdAction":"quickDetail"}],
    "readout": {"battery":true,"powerProfile":true,"penBattery":true},
    "options": {"brightness":{"wheelStep":5,"monitor":"auto"},"volume":{"wheelStep":5,"maxPercent":100},"mic":{"wheelStep":5}},
    "tabStyle": "rings2knob",
    "dialInteraction": {"snap":true,"snapWindowPercent":2,"fineEnabled":true,"fineDistancesPx":[22,66],"fineGains":[0.25,0.1]},
    "toggleScroll": "resetOnOpen",
    "themePair": {"light":"","dark":""},
    "gameMode": {"animations":false,"blur":false,"shadows":false,"gapsIn":0,"gapsOut":0}
};
const VERSION=1, INDENT=2, MAX_RINGS=Object.freeze({S:2,M:3,L:4});
const LIMITS=Object.freeze({pushDelayMs:[0,500],idleTimeoutS:[0,120],maxPercent:[100,150],snapWindowPercent:[0,2],gain:[0,1]});
const ENUMS=Object.freeze({corner:['top-left','top-right','bottom-left','bottom-right'],size:['S','M','L'],mode:['all','focused','named'],iconMode:['always','onApproach','never'],track:['solid','dashed','dotted','segmented'],knob:['round','bar','none'],thickness:['thin','normal','bold'],source:['bluetoothBattery','wifiSignal','laptopBattery','penBattery'],tabStyle:['rings2knob','rings3'],toggleScroll:['resetOnOpen']});
const ERROR_CODES=Object.freeze(['parse_error','newer_version','wrong_type','out_of_range','unknown_value','unknown_control','duplicate_control','wrong_placement','over_capacity']);
const ACTIONS=Object.freeze({wifi:['switchRadio','quickDetail','fullWindow'],bluetooth:['switchPower','quickDetail','fullWindow'],kbdlight:['nextStep','quickDetail'],theme:['togglePair','quickDetail'],media:['quickDetail']});
const ORDER_LIMITS=Object.freeze([0,Number.MAX_SAFE_INTEGER]), WHEEL_MIN=0;
const UPOWER_PREFIX="/org/freedesktop/UPower/devices/";
const SAFE_KEYS=Object.freeze(['__proto__','prototype','constructor']);
function clone(v) {return JSON.parse(JSON.stringify(v));}
function object(v) {return v!==null&&typeof v==='object'&&!list(v);}
function list(v) {return Object.prototype.toString.call(v)==='[object Array]';}
function validate(obj,catalog,resources) {
    const errors=[],config=clone(DEFAULTS),input=typeof obj==='string' ? parse(obj) : obj;
    function error(path,code) {errors.push({path:path,code:code,message:code+' at '+path});}
    function parse(text) {try{return JSON.parse(text);}catch(e){error('', 'parse_error');return null;}}
    if(!object(input)) {
        if(!errors.length)error('', 'wrong_type');
        return {config:config,errors:errors,readOnly:errors.some(function(e){return e.code==='parse_error';})};
    }
    function scalar(v,def,path,en,limits) {
        if(v===undefined)return clone(def);
        if(typeof v!==typeof def||typeof v==='number'&&!Number.isFinite(v)){error(path,'wrong_type');return clone(def);}
        if(en&&en.indexOf(v)<0){error(path,'unknown_value');return clone(def);}
        if(limits&&(v<limits[0]||v>limits[1])){error(path,'out_of_range');return clone(def);}
        return v;
    }
    function fields(src,defs,path) {
        if(src===undefined)return clone(defs);
        if(!object(src)){error(path,'wrong_type');return clone(defs);}
        const out=clone(defs);
        Object.keys(src).forEach(function(k){
            const p=path ? path+'.'+k : k;
            if(SAFE_KEYS.indexOf(k)>=0||!Object.prototype.hasOwnProperty.call(defs,k)){error(p,'unknown_value');return;}
            const d=defs[k],v=src[k];
            if(object(d))out[k]=fields(v,d,p);
            else if(list(d)) {
                if(!list(v))error(p,'wrong_type');else out[k]=clone(v);
            } else {
                const en=path==='cornerIcon' ? (k==='mode' ? ENUMS.iconMode : null) : ENUMS[k];
                out[k]=scalar(v,d,p,en,LIMITS[k]);
            }
        });return out;
    }
    // Lists and catalog-owned maps have their own validation below.
    const base=clone(DEFAULTS);
    ['controls','dials','toggles','readoutRings','options','gameMode'].forEach(function(k){delete base[k];});
    const top={};Object.keys(input).forEach(function(k){if(SAFE_KEYS.indexOf(k)>=0||!Object.prototype.hasOwnProperty.call(DEFAULTS,k))error(k,'unknown_value');else if(k in base)top[k]=input[k];});
    Object.assign(config,fields(top,base,''));
    // A missing or empty file means defaults, not an error. A file with settings must say its version.
    if(input.version===undefined){if(Object.keys(input).length)error('version','wrong_type');}
    else if(input.version>VERSION)error('version','newer_version');
    else if(input.version!==VERSION)error('version','unknown_value');
    const controls=catalog||Object.keys(DEFAULTS.controls).map(function(id){
        const readout=id==='headphones'||id==='signal',ring=readout||DEFAULTS.dials.some(function(d){return d.id===id;});
        return {id:id,placements:ring ? ['ring'] : ['arc'],kind:readout ? 'readout' : ring ? 'dial' : 'toggle'};
    });
    const by=Object.create(null);controls.forEach(function(c){by[c.id]=c;});
    if(input.controls!==undefined) {
        if(!object(input.controls))error('controls','wrong_type');else Object.keys(input.controls).forEach(function(id){
            if(!by[id]){error('controls.'+id,'unknown_control');return;}
            config.controls[id]=fields(input.controls[id],DEFAULTS.controls[id]||{shown:false,icon:'default'},'controls.'+id);
        });
    }
    function icon(value,path) {
        if(value==='default')return value;
        if(resources&&resources.icons&&resources.icons.indexOf(value)>=0)return value;
        error(path,'unknown_value');return 'default';
    }
    config.cornerIcon.source=icon(config.cornerIcon.source,'cornerIcon.source');
    Object.keys(config.controls).forEach(function(id){config.controls[id].icon=icon(config.controls[id].icon,'controls.'+id+'.icon');});
    const seen=Object.create(null),orders=Object.create(null);
    ['dials','readoutRings','toggles'].forEach(function(key){
        const entries=input[key]===undefined ? config[key] : input[key];
        if(!list(entries)){error(key,'wrong_type');return;}
        config[key]=[];
        entries.forEach(function(e,i){
            const p=key+'.'+i;
            if(!object(e)||typeof e.id!=='string'){error(p,'wrong_type');return;}
            const c=by[e.id];if(!c){error(p+'.id','unknown_control');return;}
            if(seen[e.id]){error(p+'.id','duplicate_control');return;}
            const placement=key==='toggles' ? 'arc' : 'ring';
            if((c.placements&&c.placements.indexOf(placement)<0)||(key==='readoutRings'&&c.kind!=='readout')||(key==='dials'&&c.kind==='readout')){error(p,'wrong_placement');return;}
            const out={id:e.id};
            if(key==='toggles') {
                const actions=ACTIONS[e.id]||['switch','quickDetail'];
                out.tapAction=scalar(e.tapAction,actions[0],p+'.tapAction',c.tapActions||actions);
                out.holdAction=scalar(e.holdAction,'quickDetail',p+'.holdAction',c.holdActions||actions);
            } else {
                out.order=scalar(e.order,i,p+'.order',null,ORDER_LIMITS);
                if(!Number.isInteger(out.order)){error(p+'.order','wrong_type');return;}
                if(orders[out.order]){error(p+'.order','duplicate_control');return;}
                orders[out.order]=true;
                if(e.style!==undefined)out.style=fields(e.style,config.ringStyle,p+'.style');
                if(key==='readoutRings') {
                    if(e.source===undefined){error(p+'.source','wrong_type');return;}
                    out.source=scalar(e.source,'laptopBattery',p+'.source',ENUMS.source);
                    if(object(e.style)&&e.style.knob!==undefined&&e.style.knob!=='none'){error(p+'.style.knob','wrong_placement');return;}
                    out.style=Object.assign({},out.style,{knob:'none'});
                    const field=out.source==='bluetoothBattery' ? 'deviceAddress' : out.source==='penBattery' ? 'devicePath' : out.source==='wifiSignal' ? 'interface' : null;
                    ['deviceAddress','devicePath','interface'].forEach(function(k){if(e[k]!==undefined&&k!==field)error(p+'.'+k,'wrong_placement');});
                    if(field) {
                        out[field]=scalar(e[field],field==='interface' ? 'auto' : '',p+'.'+field);
                        if(!out[field]||out[field].indexOf('<')>=0){error(p+'.'+field,'unknown_value');return;}
                        if(field==='deviceAddress'&&!/^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i.test(out[field])){error(p+'.'+field,'unknown_value');return;}
                        if(field==='devicePath'&&out[field].indexOf(UPOWER_PREFIX)!==0){error(p+'.'+field,'unknown_value');return;}
                    }
                }
            }
            const allowed=key==='toggles' ? ['id','tapAction','holdAction'] : key==='dials' ? ['id','order','style'] : ['id','order','style','source','deviceAddress','devicePath','interface'];
            Object.keys(e).forEach(function(k){if(allowed.indexOf(k)<0)error(p+'.'+k,'unknown_value');});
            seen[e.id]=true;config[key].push(out);
        });
    });
    const count=config.dials.concat(config.readoutRings).filter(function(e){return config.controls[e.id]&&config.controls[e.id].shown;}).length;
    if(count>MAX_RINGS[config.size])error('dials','over_capacity');
    config.options=clone(DEFAULTS.options);
    if(input.options!==undefined) {
        if(!object(input.options))error('options','wrong_type');else Object.keys(input.options).forEach(function(id){
            if(!by[id]){error('options.'+id,'unknown_control');return;}
            const defs=DEFAULTS.options[id]||{},spec=by[id].options||{};
            const values=input.options[id];if(!object(values)){error('options.'+id,'wrong_type');return;}
            const out=clone(defs);
            Object.keys(values).forEach(function(k){
                const p='options.'+id+'.'+k,s=spec[k];
                if(SAFE_KEYS.indexOf(k)>=0||(!Object.prototype.hasOwnProperty.call(defs,k)&&!s)){error(p,'unknown_value');return;}
                const def=s ? s.default : defs[k];
                out[k]=scalar(values[k],def,p,s&&s.enum,k==='maxPercent' ? null : s ? [s.min===undefined ? -Infinity:s.min,s.max===undefined ? Infinity:s.max] : null);
                if(k==='wheelStep'&&out[k]<=WHEEL_MIN){error(p,'out_of_range');out[k]=defs[k];}
                if(k==='maxPercent'&&LIMITS.maxPercent.indexOf(out[k])<0){error(p,'unknown_value');out[k]=defs[k];}
            });config.options[id]=out;
        });
    }
    config.gameMode=fields(input.gameMode,DEFAULTS.gameMode,'gameMode');
    ['gapsIn','gapsOut'].forEach(function(k){if(config.gameMode[k]<0){error('gameMode.'+k,'out_of_range');config.gameMode[k]=DEFAULTS.gameMode[k];}});
    ['fineDistancesPx','fineGains'].forEach(function(k){
        const a=config.dialInteraction[k],def=DEFAULTS.dialInteraction[k];
        const valid=a.length===def.length&&a.every(function(v,i){return typeof v==='number'&&Number.isFinite(v)&&(k==='fineGains' ? v>0&&v<=1 : v>=0&&(i===0||v>a[i-1]));});
        if(!valid){error('dialInteraction.'+k,'out_of_range');config.dialInteraction[k]=clone(def);}
    });
    if(!config.outputs.names.every(function(v){return typeof v==='string'&&v.length>0;})){error('outputs.names','wrong_type');config.outputs.names=[];}
    if(config.outputs.mode==='named'&&!config.outputs.names.length)error('outputs.names','unknown_value');
    ['light','dark'].forEach(function(k){const v=config.themePair[k];if(v&&(!resources||!resources.themes||resources.themes.indexOf(v)<0)){error('themePair.'+k,'unknown_value');config.themePair[k]='';}});
    return {config:config,errors:errors,readOnly:input.version>VERSION};
}
function patch(text,path,value) {
    const obj=JSON.parse(text),keys=typeof path==='string' ? path.split('.') : path.slice();
    if(!keys.length||keys.some(function(k){return SAFE_KEYS.indexOf(k)>=0;}))throw new Error('Unsafe path');
    if(obj.version>VERSION)throw new Error('Newer version is read only');
    let at=obj;
    keys.slice(0,-1).forEach(function(k){if(at[k]===undefined)at[k]={};if(!object(at[k])&&!list(at[k]))throw new Error('Invalid path');at=at[k];});
    at[keys[keys.length-1]]=value;
    return JSON.stringify(obj,null,INDENT)+'\n';
}
