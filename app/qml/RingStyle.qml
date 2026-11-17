import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ColumnLayout {
    id: ringStyleEditor
    required property var theme
    required property var store
    required property string path
    property bool readout: false
    property bool compact: false
    Layout.fillWidth: true
    Repeater {
        model: ringStyleEditor.compact ? ["track","knob","thickness"] : []
        SettingField {
            required property string modelData
            theme: ringStyleEditor.theme
            store: ({value:function(p) { return ringStyleEditor.store.value(p) },set:function(p,v) { return ringStyleEditor.store.setCommonStyle(p,v) }})
            path: ringStyleEditor.path+"."+modelData
            label: ({track:qsTr("Track"),knob:qsTr("Knob"),thickness:qsTr("Thickness")})[modelData]
            help: ({track:qsTr("The line around each ring."),knob:qsTr("The marker at the current value."),thickness:qsTr("How bold the rings look.")})[modelData]
            kind: "choice"
            choices: modelData === "track" ? ["solid","dashed","dotted","segmented"] : modelData === "knob" ? ["round","bar","none"] : ["thin","normal","bold"]
        }
    }
    Repeater {
        model: ["track","knob","thickness"]
        ColumnLayout {
            required property string modelData
            visible: !ringStyleEditor.compact
            Layout.fillWidth: true
            Label { text: ({track:qsTr("Track"),knob:qsTr("Knob"),thickness:qsTr("Thickness")})[modelData] }
            Label { text: ({track:qsTr("The line around the ring."),knob:qsTr("The marker at the current value."),thickness:qsTr("How bold the ring looks.")})[modelData]; color: ringStyleEditor.theme.secondary; font.pixelSize: 12 }
            PictureChoices {
                theme: ringStyleEditor.theme; store: ringStyleEditor.store; path: ringStyleEditor.path + "." + modelData
                values: modelData === "track" ? ["solid","dashed","dotted","segmented"] : modelData === "knob" ? (ringStyleEditor.readout ? ["none"] : ["round","bar","none"]) : ["thin","normal","bold"]
            }
        }
    }
}
