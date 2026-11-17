.pragma library
const VERSION=1;
// No pre-v1 file contract exists. Inventing a v0 transformation would lose data.
const STEPS=Object.freeze({});
function migrate(input,steps) {
    const config=JSON.parse(JSON.stringify(input)),original=config.version,errors=[];
    if(!Number.isInteger(original)||original<1)return {config:config,errors:[{path:'version',code:'wrong_type',message:'A version is required'}],readOnly:true};
    if(original>VERSION)return {config:config,errors:[{path:'version',code:'newer_version',message:'Newer config is read only'}],readOnly:true};
    const ordered=steps||STEPS;
    while(config.version<VERSION) {
        const step=ordered[config.version];
        if(!step)return {config:config,errors:[{path:'version',code:'unknown_value',message:'No migration step'}],readOnly:true};
        const next=step(JSON.parse(JSON.stringify(config)));
        if(!next||next.version!==config.version+1)return {config:config,errors:[{path:'version',code:'unknown_value',message:'Migration must advance exactly one version'}],readOnly:true};
        Object.assign(config,next);
    }
    return {config:config,errors:errors,readOnly:false,changed:config.version!==original,
        backup:config.version!==original ? 'config.v'+original+'.bak' : null};
}
