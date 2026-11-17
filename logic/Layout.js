.pragma library
const TARGET=48, INSET=12, GAP=8, LINE=18, SHORT_WIDTH=120, LONG_WIDTH=144;
const SHORT_LINES=2, LONG_LINES=4, NOTICE_WIDTH=260, NOTICE_HOLD=2500;
const READOUT_WIDTH=150, READOUT_DEPTH=112, STATUS_DEPTH=132, CHIP_WIDTH=READOUT_WIDTH-TARGET-GAP;
const BATTERY_FONT=Object.freeze({S:28,M:40,L:48});
function box(x,depth,width,height,screen,corner) {
    return {x:corner.indexOf('right')>=0 ? screen.width-x-width : x,
        y:corner.indexOf('top')>=0 ? depth : screen.height-depth-height,width:width,height:height};
}
// Text measurement is injected by the view. It must wrap anywhere, including long device names.
function textLayout(size,status,measure,screen,corner,R,error,elapsed) {
    let mode='short',hideBattery=false;
    if(size==='S')mode='notice';
    else if(measure(status,SHORT_WIDTH)>LINE*SHORT_LINES) {
        mode='long';hideBattery=true;
        if(measure(status,LONG_WIDTH)>LINE*LONG_LINES)mode='notice';
    }
    const notice=mode==='notice',long=mode==='long';
    const statusBox=box(notice ? R+GAP : INSET,notice ? INSET : long ? INSET+TARGET+GAP : STATUS_DEPTH,
        notice ? NOTICE_WIDTH : long ? LONG_WIDTH : SHORT_WIDTH,
        notice ? measure(status,NOTICE_WIDTH) : LINE*(long ? LONG_LINES : SHORT_LINES),screen,corner);
    return {mode:mode,hideBattery:hideBattery,batteryFont:BATTERY_FONT[size],ringNames:size!=='S',batteryLine:size!=='S'&&!hideBattery,
        noticeVisible:notice&&!!status&&(size!=='S'||error||elapsed<NOTICE_HOLD),status:statusBox,
        readout:box(INSET,INSET,READOUT_WIDTH,hideBattery ? TARGET : READOUT_DEPTH,screen,corner),
        profile:box(INSET,INSET,CHIP_WIDTH,TARGET,screen,corner),gear:box(INSET+CHIP_WIDTH+GAP,INSET,TARGET,TARGET,screen,corner)};
}
function arrange(config,catalog,availability,capacity,offset,captured,previous) {
    if(captured&&previous)return Object.assign({},previous,{frozen:true});
    const errors=[],rings=[],toggles=[],seen={};
    const entries=(config.dials||[]).concat(config.readoutRings||[]).slice().sort(function(a,b){return a.order-b.order;});
    function eligible(entry,placement) {
        const control=catalog.find(function(c){return c.id===entry.id;});
        if(!control){errors.push({id:entry.id,code:'unknown_control'});return false;}
        if(seen[entry.id]){errors.push({id:entry.id,code:'duplicate_control'});return false;}
        seen[entry.id]=true;
        if(control.placements.indexOf(placement)<0){errors.push({id:entry.id,code:'wrong_placement'});return false;}
        if(!config.controls[entry.id]||!config.controls[entry.id].shown)return false;
        return availability[entry.id]!=='unavailable'||control.kind==='readout';
    }
    entries.forEach(function(e){if(eligible(e,'ring')) {
        if(rings.length>=capacity.rings)errors.push({id:e.id,code:'over_capacity'});else rings.push(e);
    }});
    (config.toggles||[]).forEach(function(e){if(eligible(e,'arc'))toggles.push(e);});
    const max=Math.max(0,toggles.length-capacity.toggles),at=Math.max(0,Math.min(max,offset||0));
    return {rings:rings,toggles:toggles,offset:at,maxOffset:max,fadeBefore:at>0,fadeAfter:at<max,
        visible:toggles.slice(Math.ceil(at),Math.floor(at+capacity.toggles)),errors:errors,frozen:false};
}
function openOffset() {return 0;}
