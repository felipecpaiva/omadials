import QtQuick
import "../logic/ConfigSchema.js" as Schema
import "../logic/ConfigMigrate.js" as Migrate
Item {
    id: store
    required property var io
    readonly property string path: io.path
    property var catalog: JSON.parse(io.asset("/controls/catalog.json"))
    property var validationResources: io.resources("")
    property var config: Schema.clone(Schema.DEFAULTS)
    property var errors: []
    property string rawText: ""
    property bool exists: false
    property bool loaded: false
    property bool readOnly: false
    property bool saving: false
    property string previousText: ""
    property string writtenText: ""
    readonly property bool canUndo: undoTimer.running
    Timer { id: undoTimer; interval: 10000 }
    Connections { target: store.io; function onFileChanged() { store.reload() } }
    function problem(message) { errors = errors.concat([{path:path,code:"io_error",message:message}]) }
    function reload() {
        let result = io.read();
        if (!result.ok) { readOnly = true; problem(io.error); return false }
        let text = result.exists ? result.text : JSON.stringify(Schema.DEFAULTS,null,2) + "\n";
        if (loaded && text !== rawText) undoTimer.stop();
        exists = result.exists; rawText = text; loaded = true;
        validationResources = io.resources(text);
        let checked = Schema.validate(text,catalog,validationResources);
        readOnly = checked.readOnly;
        try {
            let migration = Migrate.migrate(JSON.parse(text)); readOnly = readOnly || migration.readOnly;
            migration.errors.forEach(function(e) { if (!checked.errors.some(function(r) { return r.path === e.path && r.code === e.code })) checked.errors.push(e) });
        } catch (e) { readOnly = true }
        if (!checked.errors.some(function(e) { return e.code === "parse_error" })) config = checked.config;
        errors = checked.errors; return true;
    }
    function value(key) { return key.split(".").reduce(function(a,k) { return a == null ? undefined : a[k] },config) }
    function set(key,value) { return setMany([{path:key,value:value}]) }
    function setMany(changes) {
        if (!reload() || readOnly) { problem("Config is read only. Fix the file or Reset all."); return false }
        try {
            changes = changes.slice();
            // "Choose screens" with none picked is invalid, so start with every screen picked; the person then unticks.
            if (changes.some(function(c) { return c.path === "outputs.mode" && c.value === "named" }) && !config.outputs.names.length
                && !changes.some(function(c) { return c.path === "outputs.names" }))
                changes.push({path: "outputs.names", value: (validationResources.screens || []).slice()});
            let next = rawText;
            changes.forEach(function(c) { next = Schema.patch(next,c.path,c.value) });
            validationResources = io.resources(next);
            let baseline = Schema.validate(rawText,catalog,validationResources).errors;
            let added = Schema.validate(next,catalog,validationResources).errors.filter(function(e) {
                return changes.some(function(c) { return e.path === c.path || e.path.indexOf(c.path + ".") === 0 }) || !baseline.some(function(old) { return old.path === e.path && old.code === e.code })
            });
            if (added.length) { errors = errors.concat(added); return false }
            return write(next,false);
        } catch (e) { problem(String(e)); return false }
    }
    function useDefault(key) {
        let keys=key.split("."), fallback=keys.reduce(function(a,k) { return a == null ? undefined : a[k] },Schema.DEFAULTS);
        return set(key,fallback);
    }
    function setCommonStyle(key,value) {
        if (!reload() || readOnly) return false;
        let field=key.split(".")[1], changes=[{path:key,value:value}], raw=JSON.parse(rawText);
        ["dials","readoutRings"].forEach(function(group) {
            let entries=raw[group];
            if (!Array.isArray(entries)) return;
            entries.forEach(function(entry,index) {
                if (!entry.style || entry.style[field]!==config.ringStyle[field] || group==="readoutRings" && field==="knob") return;
                let style=Schema.clone(entry.style); delete style[field];
                changes.push({path:group+"."+index+".style",value:style});
            });
        });
        return setMany(changes);
    }
    function write(text,isUndo) {
        let before = rawText;
        if (!io.write(text,rawText,exists)) { problem(io.error); return false }
        reload(); previousText = before; writtenText = text;
        if (isUndo) undoTimer.stop(); else undoTimer.restart(); return true;
    }
    function undo() { if (canUndo && reload() && rawText === writtenText && canUndo) write(previousText,true) }
    function reset(keys) {
        if (!keys) {
            if (!reload()) return false;
            try { if (JSON.parse(rawText).version > Schema.VERSION) { problem("Newer config is read only."); return false } } catch (e) { /* Explicit reset repairs malformed JSON. */ }
            return write(JSON.stringify(Schema.DEFAULTS,null,2) + "\n",false);
        }
        return setMany(keys.map(function(k) { return {path:k,value:k.split(".").reduce(function(a,p) { return a[p] },Schema.DEFAULTS)} }));
    }
    Component.onCompleted: reload()
}
