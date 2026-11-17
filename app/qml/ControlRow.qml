pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Glyphs.js" as Glyphs

Item {
    id: controlRow
    implicitHeight: rowBody.implicitHeight
    required property var control
    required property var registry
    required property var store
    required property var theme
    property bool expanded: false
    property string forcedGroup: ""
    signal dropRequested(string id)
    readonly property string controlKey: (control.controlId || control.id)
    readonly property string group: forcedGroup || (control.kind === "readout" ? "readoutRings"
        : store.config.toggles.some(function(e) { return e.id === controlRow.controlKey }) ? "toggles"
        : store.config.dials.some(function(e) { return e.id === controlRow.controlKey }) ? "dials"
        : control.defaultPlacement === "arc" ? "toggles" : "dials")
    readonly property int entryIndex: store.config[group].findIndex(function(e) { return e.id === controlRow.controlKey; })
    readonly property string entryPath: group + "." + rawIndex(controlKey, group)
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
        try { let list = JSON.parse(store.rawText)[key]; return Array.isArray(list) ? list : store.config[key]; }
        catch (e) { return store.config[key]; }
    }
    function rawIndex(id, key) {
        let entries = rawList(key), index = entries.findIndex(function(e) { return e && e.id === id });
        return index < 0 ? entries.length : index;
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
            let entries = rawList(group).slice(), from = rawIndex(controlKey,group), target = from + delta;
            if (target < 0 || target >= entries.length) return;
            let tmp = entries[target]; entries[target] = entries[from]; entries[from] = tmp;
            store.set(group, entries); return;
        }
        let rings = [];
        ["dials","readoutRings"].forEach(function(g) {
            controlRow.store.config[g].forEach(function(e,i) { rings.push({g:g,i:controlRow.rawIndex(e.id,g),order:e.order,id:e.id}); });
        });
        rings.sort(function(a,b) { return a.order-b.order; });
        let at = rings.findIndex(function(e) { return e.id === controlRow.controlKey; }), to = at + delta;
        if (to < 0 || to >= rings.length) return;
        store.setMany([{path:rings[at].g+"."+rings[at].i+".order",value:rings[to].order},
            {path:rings[to].g+"."+rings[to].i+".order",value:rings[at].order}]);
    }
    DropArea { anchors.fill: parent; onDropped: function(drop) { controlRow.dropRequested(drop.source.controlKey); drop.acceptProposedAction() } }
    ColumnLayout {
    id: rowBody; width: parent.width
    RowLayout {
        Layout.fillWidth: true; spacing: 4
        Item {
            id: handle; implicitWidth: 24; implicitHeight: 42
            property string controlKey: controlRow.controlKey
            Label { anchors.centerIn: parent; text: "⠿"; color: controlRow.theme.secondary }
            Item {
                id: dragProxy; width: 1; height: 1
                property string controlKey: controlRow.controlKey
                Drag.active: drag.active; Drag.source: dragProxy
                Drag.supportedActions: Qt.MoveAction
            }
            DragHandler { id: drag; target: dragProxy; onActiveChanged: if (!active) { dragProxy.Drag.drop(); dragProxy.x=0; dragProxy.y=0 } }
        }
        ToolButton { text: "↑"; Accessible.name: qsTr("Move %1 up").arg(controlRow.control.label); onClicked: controlRow.move(-1) }
        ToolButton { text: "↓"; Accessible.name: qsTr("Move %1 down").arg(controlRow.control.label); onClicked: controlRow.move(1) }
        Label { text: Glyphs.glyph(controlRow.control.icon || controlRow.controlKey); font.family: "Symbols Nerd Font"; font.pixelSize: 22; color: controlRow.theme.accent }
        Button {
            Layout.fillWidth: true
            text: controlRow.control.label + (controlRow.expanded ? " ▴" : " ▾")
            flat: true; onClicked: controlRow.expanded = !controlRow.expanded
        }
        Label { text: controlRow.control.value == null ? qsTr("Unknown") : typeof controlRow.control.value === "boolean" ? (controlRow.control.value ? qsTr("On") : qsTr("Off")) : qsTr("%1 %").arg(Math.round(Number(controlRow.control.value))); color: controlRow.theme.secondary; font.pixelSize: 12 }
        Switch {
            text: qsTr("Show"); checked: controlRow.store.config.controls[controlRow.controlKey]?.shown || false
            Accessible.name: qsTr("Show %1").arg(controlRow.control.label)
            onClicked: controlRow.showControl(checked)
        }
    }
    Label {
        visible: controlRow.group !== "toggles"
        text: {
            let style=controlRow.store.value(controlRow.entryPath + ".style");
            return !style || Object.keys(style).every(function(k) { return style[k]===controlRow.store.config.ringStyle[k] || controlRow.group==="readoutRings" && k==="knob" }) ? qsTr("Uses the common style") : qsTr("Custom");
        }
        color: controlRow.theme.secondary; font.pixelSize: 12
    }
    ColumnLayout {
        visible: controlRow.expanded; Layout.fillWidth: true; spacing: 12
        IconPicker { theme: controlRow.theme; store: controlRow.store; path: "controls." + controlRow.controlKey + ".icon"; controlId: controlRow.controlKey }
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
}
