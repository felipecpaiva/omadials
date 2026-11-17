pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../logic/ConfigSchema.js" as Schema
import "../logic/ConfigMigrate.js" as Migrate

Item {
    id: configStore
    readonly property string path: Quickshell.env("HOME") + "/.config/omadials/config.json"
    property var catalog: undefined
    property var validationResources: ({ icons: [], themes: [] })
    property var config: Schema.validate(Schema.DEFAULTS, catalog, validationResources).config
    property var errors: []
    property string rawText: ""
    property bool loaded: false
    property bool readOnly: false
    property bool saving: false
    readonly property bool canUndo: undoTimer.running && !saving
    readonly property int undoDurationMs: 10000
    property string previousText: ""
    property string pendingText: ""
    property string pendingPrevious: ""
    property bool undoing: false
    property string lastProblem: ""

    function problem(message) {
        errors = errors.concat([{ path: path, code: "io_error", message: message }]);
        if (lastProblem !== message) console.warn("omadials: " + message);
        lastProblem = message;
    }
    function accept(text) {
        if (loaded && text !== rawText && (!saving || text !== pendingText)) undoTimer.stop();
        rawText = text;
        let result = Schema.validate(text, catalog, validationResources);
        try {
            let migration = Migrate.migrate(JSON.parse(text));
            readOnly = result.readOnly || migration.readOnly;
            result.errors = result.errors.concat(migration.errors.filter(function(e) {
                return !result.errors.some(function(r) { return r.path === e.path && r.code === e.code; });
            }));
        } catch (e) { readOnly = true; }
        config = result.config;
        errors = result.errors;
        loaded = true;
        let summary = errors.map(function(e) { return e.message; }).join("; ");
        if (summary && summary !== lastProblem) console.warn("omadials: " + summary);
        lastProblem = summary;
    }
    function reload() { if (!saving) file.reload(); }
    function value(key) {
        return key.split(".").reduce(function(at, k) { return at === undefined ? undefined : at[k]; }, config);
    }
    function set(key, value) { return setMany([{ path: key, value: value }]); }
    function setMany(changes) {
        if (saving) return false;
        file.reload(); // Blocking read patches the latest disk contents, preserving unknown keys.
        file.text();
        if (!loaded || readOnly) { problem("Config is read only; repair its JSON or version first."); return false; }
        try {
            let next = rawText;
            changes.forEach(function(change) { next = Schema.patch(next, change.path, change.value); });
            let checked = Schema.validate(next, catalog, validationResources);
            let baseline = Schema.validate(rawText, catalog, validationResources).errors;
            let added = checked.errors.filter(function(e) {
                return changes.some(function(c) { return e.path === c.path || e.path.indexOf(c.path + ".") === 0; })
                    || !baseline.some(function(old) { return old.path === e.path && old.code === e.code; });
            });
            if (added.length) { errors = errors.concat(added); return false; }
            return write(next, false);
        } catch (e) { problem(String(e)); return false; }
    }
    function reset(keys) {
        if (!keys) {
            file.reload(); file.text();
            return write(JSON.stringify(Schema.DEFAULTS, null, 2) + "\n", false);
        }
        return setMany(keys.map(function(k) { return { path: k, value: k.split(".").reduce(function(a,p) { return a[p]; }, Schema.DEFAULTS) }; }));
    }
    function write(text, isUndo) {
        if (saving || !loaded) return false;
        pendingPrevious = rawText;
        pendingText = text;
        undoing = isUndo;
        saving = true;
        file.setText(text); // atomicWrites uses a sibling temporary file and rename.
        return true;
    }
    function undo() {
        if (!canUndo) return;
        file.reload(); file.text();
        if (canUndo) write(previousText, true);
    }
    onCatalogChanged: if (loaded) accept(rawText)
    onValidationResourcesChanged: if (loaded) accept(rawText)
    Timer { id: undoTimer; interval: configStore.undoDurationMs }
    FileView {
        id: file
        path: configStore.path
        atomicWrites: true
        blockLoading: true
        blockWrites: true
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: if (!configStore.saving) reload()
        onLoaded: configStore.accept(text())
        onLoadFailed: function(error) {
            configStore.loaded = true;
            if (error === FileViewError.FileNotFound) {
                configStore.accept(JSON.stringify(Schema.DEFAULTS, null, 2) + "\n");
            } else { configStore.readOnly = true; configStore.problem("Cannot read config: " + error); }
        }
        onSaved: {
            configStore.accept(configStore.pendingText);
            configStore.previousText = configStore.pendingPrevious;
            configStore.saving = false;
            if (configStore.undoing) undoTimer.stop(); else undoTimer.restart();
            configStore.pendingText = "";
        }
        onSaveFailed: function(error) {
            configStore.saving = false;
            configStore.pendingText = "";
            configStore.problem("Cannot save config (ensure ~/.config/omadials exists): " + error);
        }
    }
}
