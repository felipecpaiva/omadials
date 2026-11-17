pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../views" as Views
import "../logic/Gesture.js" as Gesture

// One row of the Rings or Toggles edit list. In the corner: handle, icon, name, value, Edit, Remove.
// Not in the corner: icon, name, Add. Removing only sets shown to false, so icon and style stay.
ColumnLayout {
    id: controlRow
    required property var modelData
    readonly property var control: modelData
    required property var registry
    required property var store
    required property var theme
    required property var host
    required property bool inCorner
    property bool full: false
    property string placementGroup: ""
    readonly property bool moveShown: host.moving === controlKey
    Component.onCompleted: if (moveShown && !host.editing) handle.forceActiveFocus()
    readonly property string controlKey: (control.controlId || control.id)
    readonly property string group: placementGroup || (control.kind === "readout" ? "readoutRings"
        : (control.placements || []).indexOf("ring") >= 0 ? "dials" : "toggles")
    readonly property int entryIndex: store.config[group].findIndex(function(e) { return e.id === controlRow.controlKey; })
    readonly property var catalogEntry: (registry.catalog || []).find(function(c) { return c.id === controlRow.controlKey; }) || ({})
    readonly property string iconName: { const i = store.config.controls[controlKey]?.icon; return i && i !== "default" ? i : control.icon; }
    readonly property string availabilityText: {
        switch (control.availability) {
        case "probing": return "";   // read when the corner opens; no noise in the list
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
    function isShown(id) { return !!store.config.controls[id]?.shown; }
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
        } else if (shown) {
            // A control added back goes to the end of the corner order, like a phone's control center editor.
            if (group === "toggles") {
                let entries = rawList(group).slice();
                entries.push(entries.splice(entryIndex, 1)[0]); changes.push({path:group,value:entries});
            } else changes.push({path:group + "." + entryIndex + ".order",
                value:store.config.dials.concat(store.config.readoutRings).reduce(function(n,e) { return Math.max(n,e.order + 1); },0)});
        }
        if (!shown && host.editing === controlKey) host.editing = "";
        store.setMany(changes);
    }
    // Moves past controls that are not in the corner, so every press visibly moves the row.
    function move(delta) {
        if (entryIndex < 0) return;
        if (group === "toggles") {
            let entries = rawList(group).slice(), target = entryIndex + delta;
            while (target >= 0 && target < entries.length && !isShown(entries[target].id)) target += delta;
            if (target < 0 || target >= entries.length) return;
            let tmp = entries[target]; entries[target] = entries[entryIndex]; entries[entryIndex] = tmp;
            store.set(group, entries); return;
        }
        let rings = [];
        ["dials","readoutRings"].forEach(function(g) {
            controlRow.store.config[g].forEach(function(e,i) {
                if (e.id === controlRow.controlKey || controlRow.isShown(e.id)) rings.push({g:g,i:i,order:e.order,id:e.id});
            });
        });
        rings.sort(function(a,b) { return a.order-b.order; });
        let at = rings.findIndex(function(e) { return e.id === controlRow.controlKey; }), to = at + delta;
        if (to < 0 || to >= rings.length) return;
        store.setMany([{path:rings[at].g+"."+rings[at].i+".order",value:rings[to].order},
            {path:rings[to].g+"."+rings[to].i+".order",value:rings[at].order}]);
    }
    RowLayout {
        Layout.fillWidth: true
        Item {
            id: handle
            visible: controlRow.inCorner
            Layout.preferredWidth: 24; Layout.preferredHeight: Gesture.TARGET
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Move " + controlRow.control.label + " with the up and down keys"
            Keys.onUpPressed: controlRow.move(-1)
            Keys.onDownPressed: controlRow.move(1)
            onActiveFocusChanged: if (activeFocus) controlRow.host.moving = controlRow.controlKey
            Text { anchors.centerIn: parent; text: "\u{F01DD}"; color: handle.activeFocus ? controlRow.theme.accent : controlRow.theme.secondary; font.family: controlRow.theme.font }
            MouseArea {
                anchors.fill: parent
                property real pressedY: 0
                onPressed: mouse => pressedY = mouse.y
                preventStealing: true
                onPressAndHold: controlRow.host.moving = controlRow.moveShown ? "" : controlRow.controlKey
                onReleased: mouse => { if (Math.abs(mouse.y-pressedY) >= Gesture.DRAG) controlRow.move(mouse.y > pressedY ? 1 : -1) }
            }
        }
        Views.ControlIcon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; theme: controlRow.theme; name: controlRow.iconName }
        Text { Layout.fillWidth: true; text: controlRow.control.label; elide: Text.ElideRight; color: controlRow.theme.text; font.family: controlRow.theme.font }
        Text { visible: controlRow.inCorner; text: controlRow.control.availability === "available" && controlRow.control.value !== null ? controlRow.control.valueText : ""; color: controlRow.theme.secondary; font.family: controlRow.theme.font }
        Repeater {
            model: controlRow.inCorner && controlRow.moveShown ? [{text:"Up",delta:-1},{text:"Down",delta:1}] : []
            SettingsButton {
                required property var modelData
                theme: controlRow.theme; text: modelData.text
                onClicked: controlRow.move(modelData.delta)
            }
        }
        RowIconButton {
            visible: controlRow.inCorner
            theme: controlRow.theme; iconText: "\u{F03EB}"; tooltipText: "Edit " + controlRow.control.label
            selected: controlRow.host.editing === controlRow.controlKey
            onClicked: controlRow.host.edit(controlRow.controlKey)
        }
        RowIconButton {
            visible: controlRow.inCorner; warning: true
            theme: controlRow.theme; iconText: "\u{F0377}"; tooltipText: "Remove " + controlRow.control.label
            onClicked: controlRow.showControl(false)
        }
        RowIconButton {
            visible: !controlRow.inCorner; enabled: !controlRow.full
            theme: controlRow.theme; iconText: "\u{F0419}"; tooltipText: "Add " + controlRow.control.label
            onClicked: controlRow.showControl(true)
        }
    }
    HelpText { visible: text.length > 0; theme: controlRow.theme; text: controlRow.availabilityText }
}
