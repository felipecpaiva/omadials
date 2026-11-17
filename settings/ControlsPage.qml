pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../logic/Geometry.js" as Geometry
import "../logic/Labels.js" as Labels
// Rings or Toggles as an edit list: "In the corner" in corner order, then "Not in the corner".
ColumnLayout {
    id: controlsPage
    required property var store
    required property var registry
    required property var theme
    required property var host
    property bool togglesOnly: false
    readonly property var capacity: Geometry.capacity(store.config.size, Quickshell.screens.length ? Math.min(Quickshell.screens[0].width,Quickshell.screens[0].height) : 1080)
    readonly property int ringCount: store.config.dials.concat(store.config.readoutRings).filter(e => controlsPage.store.config.controls[e.id]?.shown).length
    // Toggles scroll along the arc, so only rings have a hard limit.
    readonly property bool full: !togglesOnly && ringCount >= capacity.rings
    readonly property var orderedControls: {
        const cfg = store.config;
        const entries = togglesOnly ? cfg.toggles : cfg.dials.concat(cfg.readoutRings).slice().sort((a,b) => a.order-b.order);
        const ids = entries.map(e => e.id);
        return (registry.controls || []).filter(c => togglesOnly ? c.placements.indexOf("arc") >= 0 : c.placements.indexOf("ring") >= 0 && (cfg.toggles.every(e => e.id !== c.controlId)) && (c.kind !== "readout" || ids.indexOf(c.controlId) >= 0))
            .slice().sort((a,b) => (ids.indexOf(a.controlId) < 0 ? 999 : ids.indexOf(a.controlId)) - (ids.indexOf(b.controlId) < 0 ? 999 : ids.indexOf(b.controlId)));
    }
    function groupOf(c) { return togglesOnly ? "toggles" : c.kind === "readout" ? "readoutRings" : "dials"; }
    function inCorner(c) {
        const key = c.controlId || c.id;
        return !!store.config.controls[key]?.shown && store.config[groupOf(c)].some(e => e.id === key);
    }
    readonly property var inside: orderedControls.filter(c => controlsPage.inCorner(c))
    readonly property var outside: orderedControls.filter(c => !controlsPage.inCorner(c))
    spacing: 12
    HelpText { theme: controlsPage.theme; text: controlsPage.togglesOnly ? controlsPage.capacity.toggles + " visible without scrolling at this size" : controlsPage.ringCount + " of " + controlsPage.capacity.rings + " rings fit at " + Labels.label(controlsPage.store.config.size) }
    SettingsCard {
        visible: !controlsPage.togglesOnly
        theme: controlsPage.theme; title: "All rings"
        RingStyleFields { theme: controlsPage.theme; store: controlsPage.store; stylePath: "ringStyle"; common: true }
    }
    SettingsCard {
        theme: controlsPage.theme; title: "In the corner"
        HelpText { visible: !controlsPage.inside.length; theme: controlsPage.theme; text: "Nothing here yet. Add one below." }
        Repeater {
            model: controlsPage.inside
            ControlRow { Layout.fillWidth: true; inCorner: true; placementGroup: controlsPage.groupOf(modelData); store: controlsPage.store; registry: controlsPage.registry; theme: controlsPage.theme; host: controlsPage.host }
        }
    }
    SettingsCard {
        visible: controlsPage.outside.length > 0
        theme: controlsPage.theme; title: "Not in the corner"
        HelpText { visible: controlsPage.full; theme: controlsPage.theme; text: "Remove one first, or choose a larger size." }
        Repeater {
            model: controlsPage.outside
            ControlRow { Layout.fillWidth: true; inCorner: false; full: controlsPage.full; placementGroup: controlsPage.groupOf(modelData); store: controlsPage.store; registry: controlsPage.registry; theme: controlsPage.theme; host: controlsPage.host }
        }
    }
    AddReadoutCard { registry: controlsPage.registry; visible: !controlsPage.togglesOnly; full: controlsPage.full; theme: controlsPage.theme; store: controlsPage.store }
}
