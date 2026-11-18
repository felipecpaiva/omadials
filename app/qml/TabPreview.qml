import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Geometry.js" as Geometry
RowLayout {
    id: tab
    required property var store
    required property var theme
    Label { text: qsTr("Closed tab"); color: tab.theme.secondary; Layout.fillWidth: true; font.pixelSize: 12 }
    Canvas {
        id: drawing; implicitWidth: 50; implicitHeight: 50
        opacity: tab.store.config.cornerIcon.mode === "never" ? .25 : 1
        onPaint: {
            let c=getContext("2d");c.reset();
            if(tab.store.config.cornerIcon.source!=="default") return;
            let cfg=tab.store.config, k=cfg.cornerIcon.scale || 1, radii=(cfg.tabStyle==="rings2knob"?[32,21]:[32,24,16]).map(function(r) { return r*k });
            function point(r,a) {return Geometry.fromCanonical(Geometry.knobPos(r,a,50),50,50,cfg.corner)}
            radii.forEach(function(r) {
                c.beginPath(); c.lineWidth=2.5*k; c.strokeStyle=tab.theme.accent;
                for(let a=3;a<=87;a++) {let p=point(r,a);if(a===3)c.moveTo(p.x,p.y);else c.lineTo(p.x,p.y)}
                c.stroke();
            });
            if(cfg.tabStyle!=="rings3") {let p=point(32*k,48);c.beginPath();c.fillStyle=tab.theme.accent;c.arc(p.x,p.y,4*k,0,Math.PI*2);c.fill()}
        }
    }
    Image { visible: tab.store.config.cornerIcon.source!=="default"; source: visible ? tab.store.io.iconUrl(tab.store.config.cornerIcon.source) : ""; Layout.preferredWidth: 24 * (tab.store.config.cornerIcon.scale || 1); Layout.preferredHeight: Layout.preferredWidth }
    Connections { target: tab.store; function onConfigChanged() { drawing.requestPaint() } }
    Connections { target: tab.theme; function onAccentChanged() { drawing.requestPaint() } }
}
