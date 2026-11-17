import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../logic/Glyphs.js" as Glyphs
import "../logic/Geometry.js" as Geometry
ColumnLayout {
    id: preview
    required property var store
    required property var theme
    required property var registry
    readonly property var controls: registry.controls
    implicitWidth: capacity.R*0.6
    readonly property var config: store.config
    readonly property var capacity: Geometry.capacity(config.size, Math.min(Screen.width,Screen.height))
    property string editingId: ""
    property bool compact: false
    signal editRequested(string id, bool toggle)
    // One list for drawing and for clicks, so a click always finds the ring or toggle drawn there.
    readonly property var shapes: {
        let cfg = config, rings = cfg.dials.concat(cfg.readoutRings).filter(function(e) { return cfg.controls[e.id]?.shown })
            .sort(function(a,b) { return a.order - b.order }).slice(0,capacity.rings);
        let toggles = cfg.toggles.filter(function(e) { return cfg.controls[e.id]?.shown });
        return {rings:rings, radii:Geometry.ringRadii(capacity.R,rings.length),
            toggles:toggles.slice(0,Geometry.arcSlots(capacity.toggleRadius).count), angles:Geometry.arcSlots(capacity.toggleRadius).angles};
    }
    function hit(x, y) {
        let R = capacity.R, p = Geometry.toCanonical({x:x/0.6,y:y/0.6},R,R,config.corner), polar = Geometry.polar(p.x,p.y,R);
        let toggle = shapes.toggles.findIndex(function(e,i) {
            let t = Geometry.knobPos(preview.capacity.toggleRadius,shapes.angles[i],R);
            return Math.hypot(t.x - p.x, t.y - p.y) <= 30;
        });
        if (toggle >= 0) return {id:shapes.toggles[toggle].id, toggle:true};
        let ring = Geometry.hitRing(polar.d, shapes.radii);
        return ring >= 0 ? {id:shapes.rings[ring].id, toggle:false} : null;
    }
    LabelText {
        Layout.fillWidth: true
        text: qsTr("Live preview at 60 %")
        color: preview.theme.secondary
    }
    Canvas {
        id: canvas
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: preview.capacity.R * 0.6
        Layout.preferredHeight: preview.capacity.R * 0.6
        onPaint: {
            let ctx = getContext("2d"); ctx.reset();
            let cfg = preview.config, R = preview.capacity.R, scale = 0.6;
            function point(radius,angle) {
                return Geometry.fromCanonical(Geometry.knobPos(radius,angle,R),R,R,cfg.corner);
            }
            function arc(radius,start,end,color,width) {
                ctx.beginPath();
                for (let a=start;a<=end;a+=1) {
                    let p=point(radius,a);
                    if (a===start) ctx.moveTo(p.x*scale,p.y*scale); else ctx.lineTo(p.x*scale,p.y*scale);
                }
                ctx.strokeStyle=color;ctx.lineWidth=width*scale;ctx.stroke();
            }
            let rings=preview.shapes.rings, radii=preview.shapes.radii;
            rings.forEach(function(entry,i) {
                let style=Object.assign({},cfg.ringStyle,entry.style || {});
                if (entry.id === preview.editingId) { ctx.globalAlpha=.3; arc(radii[i],3,87,preview.theme.accent,30); ctx.globalAlpha=1 }
                ctx.setLineDash(style.track === "solid" ? [] : style.track === "dotted" ? [2,4] : [8,4]);
                let width=({thin:2,normal:4,bold:6})[style.thickness];
                arc(radii[i],3,87,preview.theme.track,width);
                ctx.setLineDash([]);
                let control=preview.controls.find(function(c) { return c.id===entry.id }), fraction=control && typeof control.value==="number" ? Math.max(0,Math.min(1,control.value/100)) : .5;
                let angle=3+fraction*84;
                arc(radii[i],3,angle,preview.theme.accent,width);
                if (style.knob !== "none") {
                    let p=point(radii[i],angle);ctx.fillStyle=preview.theme.accent;
                    if (style.knob === "bar") ctx.fillRect(p.x*scale-2,p.y*scale-7,4,14);
                    else {ctx.beginPath();ctx.arc(p.x*scale,p.y*scale,5,0,2*Math.PI);ctx.fill()}
                }
            });
            let toggles=preview.shapes.toggles;
            preview.shapes.angles.slice(0,toggles.length).forEach(function(a,i) {
                let p=point(preview.capacity.toggleRadius,a), edited=toggles[i].id===preview.editingId;
                ctx.beginPath();ctx.arc(p.x*scale,p.y*scale,edited?13:10,0,2*Math.PI);
                ctx.fillStyle=preview.theme.off;ctx.fill();ctx.strokeStyle=edited?preview.theme.accent:preview.theme.edge;ctx.lineWidth=edited?3:1;ctx.stroke();
                ctx.fillStyle=preview.theme.text; ctx.font="12px Symbols Nerd Font"; ctx.textAlign="center"; ctx.textBaseline="middle";
                ctx.fillText(Glyphs.glyph(toggles[i].id),p.x*scale,p.y*scale);
            });
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) { let found = preview.hit(mouse.x, mouse.y); if (found) preview.editRequested(found.id, found.toggle) }
        }
    }
    LabelText {
        Layout.fillWidth: true
        text: qsTr("Click a ring or toggle to edit it.")
        color: preview.theme.secondary; font.pixelSize: 11
    }
    LabelText {
        visible: preview.capacity.capped && !preview.compact
        text: qsTr("Limited to %1 px on this screen").arg(Math.round(preview.capacity.R))
        color: preview.theme.secondary
    }
    TabPreview { visible: !preview.compact; store: preview.store; theme: preview.theme; Layout.fillWidth: true }
    LabelText { visible: !preview.compact; text: qsTr("Values are examples until the plugin reports them."); color: preview.theme.secondary; font.pixelSize: 11; Layout.fillWidth: true }
    onControlsChanged: canvas.requestPaint()
    onConfigChanged: canvas.requestPaint()
    onEditingIdChanged: canvas.requestPaint()
    onCapacityChanged: canvas.requestPaint()
    Connections { target: preview.theme; function onAccentChanged() { canvas.requestPaint() } }
    component LabelText: Text {
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
    }
}
