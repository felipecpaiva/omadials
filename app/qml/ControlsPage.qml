pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: controlsPage
    required property var store
    required property var registry
    required property var theme
    readonly property int ringCount: store.config.dials.concat(store.config.readoutRings).filter(function(e) {
        return controlsPage.store.config.controls[e.id]?.shown;
    }).length
    readonly property int ringCap: ({S:2,M:3,L:4})[store.config.size]
    readonly property int arcCount: store.config.toggles.filter(function(e) {
        return controlsPage.store.config.controls[e.id]?.shown;
    }).length
    readonly property var orderedControls: {
        let cfg = store.config;
        let ringIds = cfg.dials.concat(cfg.readoutRings).slice().sort(function(a,b) { return a.order-b.order; }).map(function(e) { return e.id; });
        let ids = ringIds.concat(cfg.toggles.map(function(e) { return e.id; }));
        return (registry.controls || []).slice().sort(function(a,b) {
            let ai = ids.indexOf(a.controlId || a.id), bi = ids.indexOf(b.controlId || b.id);
            return (ai < 0 ? ids.length : ai) - (bi < 0 ? ids.length : bi);
        });
    }
    Text {
        Layout.fillWidth: true
        text: controlsPage.ringCount + " of " + controlsPage.ringCap + " rings fit at " + controlsPage.store.config.size
            + ". Toggles: " + Math.min(controlsPage.arcCount, ({S:5,M:6,L:7})[controlsPage.store.config.size])
            + " visible, " + controlsPage.arcCount + " total (scrollable). Order changes only here; scroll resets on open."
        textFormat: Text.PlainText; wrapMode: Text.WordWrap
        color: controlsPage.theme.text; font.family: controlsPage.theme.font
    }
    Repeater {
        model: controlsPage.orderedControls
        ControlRow {
            required property var modelData
            Layout.fillWidth: true
            control: modelData
            store: controlsPage.store; registry: controlsPage.registry; theme: controlsPage.theme
        }
    }
    SettingsButton {
        theme: controlsPage.theme; text: "Reset Controls"
        onClicked: controlsPage.store.reset(["controls","dials","toggles","readoutRings","ringStyle","readout"])
    }
}
