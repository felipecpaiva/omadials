import QtQuick
// Where one control lives in the config, and the edits that put it in or take it out of the corner.
QtObject {
    id: model
    required property var control
    required property var store
    required property var registry
    property string forcedGroup: ""
    readonly property string key: control ? (control.controlId || control.id) : ""
    readonly property string group: forcedGroup || (!control ? "dials" : control.kind === "readout" ? "readoutRings"
        : store.config.toggles.some(function(e) { return e.id === model.key }) ? "toggles"
        : store.config.dials.some(function(e) { return e.id === model.key }) ? "dials"
        : control.defaultPlacement === "arc" ? "toggles" : "dials")
    readonly property bool shown: store.config.controls[key]?.shown || false
    readonly property int entryIndex: store.config[group].findIndex(function(e) { return e.id === model.key })
    readonly property string entryPath: group + "." + rawIndex(key, group)
    readonly property var entry: store.value(entryPath) || ({})
    readonly property var catalogEntry: (registry.catalog || []).find(function(c) { return c.id === model.key }) || ({})
    readonly property var sourceNames: ({bluetoothBattery:qsTr("Bluetooth device battery"),wifiSignal:qsTr("Wi-Fi signal"),laptopBattery:qsTr("Laptop battery"),penBattery:qsTr("Pen battery")})
    readonly property string name: group === "readoutRings" ? (sourceNames[entry.source] || qsTr("Display ring")) : (control?.label || key)
    // The icon name to draw: the chosen one, else the control's own glyph, else the display ring's source glyph.
    readonly property string icon: {
        let chosen = store.config.controls[key]?.icon;
        return chosen && chosen !== "default" ? chosen : group === "readoutRings" ? (entry.source || "laptopBattery") : (control?.icon || key);
    }
    // Some controls are only checked when the corner opens: show nothing rather than a value that looks broken.
    readonly property string valueText: !control || control.value == null || key === "theme" ? ""
        : typeof control.value === "boolean" ? (control.value ? qsTr("On") : qsTr("Off")) : qsTr("%1 %").arg(Math.round(Number(control.value)))
    function rawList(list) {
        try { let entries = JSON.parse(store.rawText)[list]; return Array.isArray(entries) ? entries : store.config[list]; }
        catch (e) { return store.config[list]; }
    }
    function rawIndex(id, list) {
        let entries = rawList(list), index = entries.findIndex(function(e) { return e && e.id === id });
        return index < 0 ? entries.length : index;
    }
    // Removing only hides the control: its entry, icon and style stay for when it is added back.
    function setShown(on) {
        let changes = [{path:"controls." + key + ".shown", value:on}];
        if (on && entryIndex < 0) {
            let entries = rawList(group).slice(), added = {id:key};
            if (group === "toggles") {
                added.tapAction = (catalogEntry.tapActions || ["quickDetail"])[0];
                added.holdAction = "quickDetail";
            } else {
                added.order = store.config.dials.concat(store.config.readoutRings).reduce(function(n,e) { return Math.max(n,e.order + 1) },0);
            }
            entries.push(added); changes.push({path:group,value:entries});
        }
        return store.setMany(changes);
    }
    // Moves this control to where targetKey is now in the corner order, keeping every other entry's place.
    function moveTo(targetKey) {
        if (targetKey === key) return false;
        if (group === "toggles") {
            let list = rawList("toggles").slice();
            let from = list.findIndex(function(e) { return e && e.id === model.key }), to = list.findIndex(function(e) { return e && e.id === targetKey });
            if (from < 0 || to < 0) return false;
            list.splice(to,0,list.splice(from,1)[0]);
            return store.set("toggles",list);
        }
        let rings = [];
        ["dials","readoutRings"].forEach(function(g) {
            model.store.config[g].forEach(function(e) { rings.push({g:g,i:model.rawIndex(e.id,g),order:e.order,id:e.id}) });
        });
        rings.sort(function(a,b) { return a.order - b.order });
        let orders = rings.map(function(r) { return r.order });
        let from = rings.findIndex(function(r) { return r.id === model.key }), to = rings.findIndex(function(r) { return r.id === targetKey });
        if (from < 0 || to < 0) return false;
        rings.splice(to,0,rings.splice(from,1)[0]);
        let changes = [];
        rings.forEach(function(r,n) { if (r.order !== orders[n]) changes.push({path:r.g + "." + r.i + ".order",value:orders[n]}) });
        return store.setMany(changes);
    }
}
