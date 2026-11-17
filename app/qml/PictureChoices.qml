import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Labels.js" as Labels
ColumnLayout {
    id: choices
    required property var store
    required property var theme
    required property string path
    property var values: []
    property var words: []
    property var descriptions: []
    property string drawing: "ring"
    property var fallback: undefined
    signal chosen(var value)
    Layout.fillWidth: true
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Repeater {
            model: choices.values
            Button {
                id: button
                required property var modelData
                required property int index
                Layout.fillWidth: true; Layout.preferredWidth: 1
                implicitHeight: choices.descriptions.length ? 124 : 98
                Accessible.name: choices.words[index] || Labels.label(modelData)
                highlighted: (choices.store.value(choices.path) ?? choices.fallback) === modelData
                onClicked: { if (choices.path.indexOf("ringStyle.")===0) choices.store.setCommonStyle(choices.path,modelData); else choices.store.set(choices.path,modelData); choices.chosen(modelData) }
                background: Rectangle { color: button.highlighted ? choices.theme.off : choices.theme.clear; border.width: button.highlighted ? 2 : 1; border.color: button.highlighted ? choices.theme.accent : choices.theme.edge; radius: choices.theme.radius }
                contentItem: ColumnLayout {
                    Canvas {
                        id: picture; Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 64; implicitHeight: 40
                        onPaint: {
                            let c=getContext("2d"); c.reset(); c.strokeStyle=choices.theme.accent; c.fillStyle=choices.theme.accent; c.lineWidth=2;
                            let v=String(button.modelData);
                            if (choices.drawing === "corner") {
                                c.strokeStyle=choices.theme.edge; c.strokeRect(4,2,56,34);
                                c.fillRect(v.indexOf("left")>=0?5:45,v.indexOf("top")>=0?3:23,14,12);
                            } else {
                                let n=choices.drawing === "size" ? button.index+2 : v.indexOf("3")>=0 ? 3 : 2;
                                for(let i=0;i<n;i++) {
                                    c.lineWidth=choices.path.endsWith("thickness") ? ({thin:1,normal:3,bold:5})[v] : 2;
                                    c.setLineDash(v==="dashed"?[5,3]:v==="dotted"?[1,3]:v==="segmented"?[8,5]:[]);
                                    c.beginPath(); c.arc(10,38,12+i*8,-Math.PI/2,0); c.stroke();
                                }
                                c.setLineDash([]);
                                if(v.indexOf("knob")>=0 || v==="round" || v==="bar") {
                                    if(v==="bar") c.fillRect(31,17,4,12);
                                    else {c.beginPath();c.arc(30,18,4,0,Math.PI*2);c.fill()}
                                }
                            }
                        }
                        Connections { target: choices.theme; function onAccentChanged() { picture.requestPaint() } }
                    }
                    Label { Layout.fillWidth: true; text: choices.words[button.index] || Labels.label(button.modelData); horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; font.pixelSize: 12 }
                    Label { visible: choices.descriptions.length > 0; Layout.fillWidth: true; text: choices.descriptions[button.index] || ""; color: choices.theme.secondary; wrapMode: Text.WordWrap; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                }
            }
        }
    }
}
