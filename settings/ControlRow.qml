pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: controlRow
    required property var control
    required property var registry
    required property var store
    required property var theme
    property bool expanded: false
    readonly property string controlKey: (control.controlId || control.id)
    readonly property string group: control.kind === "readout" ? "readoutRings"
        : (control.placements || []).indexOf("ring") >= 0 ? "dials" : "toggles"
    readonly property int entryIndex: store.config[group].findIndex(function(e) { return e.id === controlRow.controlKey; })
    readonly property string entryPath: group + "." + (entryIndex < 0 ? store.config[group].length : entryIndex)
    readonly property var catalogEntry: (registry.catalog || []).find(function(c) { return c.id === controlRow.controlKey; }) || ({})
    readonly property string availabilityText: {
        switch (control.availability) {
        case "probing": return "Checking";
        case "available": return "";
        case "unavailable": return "Not found on this machine: " + control.reason;
        case "error": return "Error: " + control.reason;
        default: return "Unknown availability: " + control.availability;
        }
    }
    function rawList(key) {
        try { return JSON.parse(store.rawText)[key] || store.config[key]; }
        catch (e) { return store.config[key]; }
    }
    function showControl(shown) {
        let changes = [{path:"controls." + controlKey + ".shown", value:shown}];
        if (shown && entryIndex < 0) {
            let entries = rawList(group).slice();
            let entry = {id:controlKey};
            if (group === "toggles") {
                entry.tapAction = (catalogEntry.tapActions || ["quickDetail"])[0];
                entry.holdAction = "quickDetail";
            } else {
                let rings = store.config.dials.concat(store.config.readoutRings);
                entry.order = rings.reduce(function(n,e) { return Math.max(n,e.order + 1); },0);
                if (group === "readoutRings") { entry.source = "laptopBattery"; entry.style = {knob:"none"}; }
            }
            entries.push(entry); changes.push({path:group,value:entries});
        }
        store.setMany(changes);
    }
    function move(delta) {
        if (entryIndex < 0) return;
        if (group === "toggles") {
            let entries = rawList(group).slice(), target = entryIndex + delta;
            if (target < 0 || target >= entries.length) return;
            let tmp = entries[target]; entries[target] = entries[entryIndex]; entries[entryIndex] = tmp;
            store.set(group, entries); return;
        }
        let rings = [];
        ["dials","readoutRings"].forEach(function(g) {
            controlRow.store.config[g].forEach(function(e,i) { rings.push({g:g,i:i,order:e.order,id:e.id}); });
        });
        rings.sort(function(a,b) { return a.order-b.order; });
        let at = rings.findIndex(function(e) { return e.id === controlRow.controlKey; }), to = at + delta;
        if (to < 0 || to >= rings.length) return;
        store.setMany([{path:rings[at].g+"."+rings[at].i+".order",value:rings[to].order},
            {path:rings[to].g+"."+rings[to].i+".order",value:rings[at].order}]);
    }
    RowLayout {
        Layout.fillWidth: true
        SettingsButton { theme: controlRow.theme; text: "Up"; onClicked: controlRow.move(-1) }
        SettingsButton { theme: controlRow.theme; text: "Down"; onClicked: controlRow.move(1) }
        SettingsButton {
            Layout.fillWidth: true
            theme: controlRow.theme; text: controlRow.control.label + (controlRow.expanded ? " ▴" : " ▾")
            onClicked: controlRow.expanded = !controlRow.expanded
        }
        SettingsButton {
            theme: controlRow.theme
            text: controlRow.store.config.controls[controlRow.controlKey]?.shown ? "Shown" : "Hidden"
            onClicked: controlRow.showControl(!controlRow.store.config.controls[controlRow.controlKey]?.shown)
        }
    }
    Text {
        visible: text.length > 0; Layout.fillWidth: true
        text: controlRow.availabilityText
        textFormat: Text.PlainText; wrapMode: Text.WordWrap
        color: controlRow.theme.secondary; font.family: controlRow.theme.font
    }
    ColumnLayout {
        visible: controlRow.expanded
        Layout.fillWidth: true
        SettingField {
            theme: controlRow.theme; store: controlRow.store
            path: "controls." + controlRow.controlKey + ".icon"; label: "Icon theme name"
            kind: "editableChoice"; choices: ["default"].concat(controlRow.store.validationResources.icons || [])
        }
        Loader {
            Layout.fillWidth: true
            active: controlRow.expanded && (controlRow.entryIndex >= 0 || controlRow.group === "readoutRings")
            sourceComponent: ControlOptions {
                theme: controlRow.theme; store: controlRow.store; control: controlRow.control
                entryPath: controlRow.entryPath; group: controlRow.group; catalogEntry: controlRow.catalogEntry
            }
        }
    }
}
