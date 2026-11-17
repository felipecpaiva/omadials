pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../logic/Geometry.js" as Geometry
import "../logic/Labels.js" as Labels
ColumnLayout {
    id: controlsPage
    required property var store
    required property var registry
    required property var theme
    property bool togglesOnly: false
    readonly property var capacity: Geometry.capacity(store.config.size, Quickshell.screens.length ? Math.min(Quickshell.screens[0].width,Quickshell.screens[0].height) : 1080)
    readonly property int ringCount: store.config.dials.concat(store.config.readoutRings).filter(e => controlsPage.store.config.controls[e.id]?.shown).length
    readonly property var orderedControls: {
        const cfg = store.config;
        const entries = togglesOnly ? cfg.toggles : cfg.dials.concat(cfg.readoutRings).slice().sort((a,b) => a.order-b.order);
        const ids = entries.map(e => e.id);
        return (registry.controls || []).filter(c => togglesOnly ? c.placements.indexOf("arc") >= 0 : c.placements.indexOf("ring") >= 0 && (cfg.toggles.every(e => e.id !== c.controlId)) && (c.kind !== "readout" || ids.indexOf(c.controlId) >= 0))
            .slice().sort((a,b) => (ids.indexOf(a.controlId) < 0 ? 999 : ids.indexOf(a.controlId)) - (ids.indexOf(b.controlId) < 0 ? 999 : ids.indexOf(b.controlId)));
    }
    spacing: 12
    HelpText { theme: controlsPage.theme; text: controlsPage.togglesOnly ? controlsPage.capacity.toggles + " visible without scrolling at this size" : controlsPage.ringCount + " of " + controlsPage.capacity.rings + " rings fit at " + Labels.label(controlsPage.store.config.size) }
    SettingsCard {
        visible: !controlsPage.togglesOnly
        theme: controlsPage.theme; title: "All rings"
        RingStyleFields { theme: controlsPage.theme; store: controlsPage.store; stylePath: "ringStyle"; common: true }
    }
    Repeater {
        model: controlsPage.orderedControls
        SettingsCard {
            id: controlCard
            required property var modelData
            theme: controlsPage.theme; title: controlCard.modelData.label
            ControlRow { Layout.fillWidth: true; control: controlCard.modelData; placementGroup: controlsPage.togglesOnly ? "toggles" : controlCard.modelData.kind === "readout" ? "readoutRings" : "dials"; store: controlsPage.store; registry: controlsPage.registry; theme: controlsPage.theme }
        }
    }
    AddReadoutCard { registry: controlsPage.registry; visible: !controlsPage.togglesOnly; theme: controlsPage.theme; store: controlsPage.store }
}
