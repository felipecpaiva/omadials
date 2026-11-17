import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Labels.js" as Labels
ColumnLayout {
    id: banner
    required property var store
    required property var registry
    required property var theme
    required property int page
    function owner(path) {
        if (/^(corner|size|outputs|trigger.push|tabStyle)/.test(path)) return 0;
        if (/^(dials|readoutRings|ringStyle|options.*wheelStep)/.test(path)) return 1;
        if (/^toggles/.test(path)) return 2;
        if (/^(behavior|dialInteraction|themePair|gameMode|options.volume.max)/.test(path)) return 3;
        if (/^controls/.test(path)) {
            let id=path.split(".")[1];
            return store.config.toggles.some(function(e) { return e.id===id }) ? 2 : 1;
        }
        return 4;
    }
    function name(path) {
        let names={corner:qsTr("Corner"),size:qsTr("Size"),outputs:qsTr("Screens"),trigger:qsTr("Opening"),cornerIcon:qsTr("Corner tab"),tabStyle:qsTr("Corner tab"),dials:qsTr("Ring controls"),readoutRings:qsTr("Display rings"),ringStyle:qsTr("All rings"),toggles:qsTr("Toggle controls"),controls:qsTr("Control appearance"),options:qsTr("Dial options"),behavior:qsTr("Closing"),dialInteraction:qsTr("Dials"),themePair:qsTr("Theme toggle"),gameMode:qsTr("Game mode")};
        return names[path.split(".")[0]] || qsTr("Settings file");
    }
    readonly property var problems: store.errors.filter(function(e) { return banner.owner(e.path)===banner.page })
    visible: problems.length>0 || page===4 && backend.error.length>0
    Layout.fillWidth: true
    Label { visible: banner.page===4 && backend.error.length>0; text: backend.error; color: banner.theme.warn; Layout.fillWidth: true; wrapMode: Text.WordWrap }
    Repeater {
        model: banner.problems
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true; color: banner.theme.warn; wrapMode: Text.WordWrap; textFormat: Text.PlainText
                text: banner.name(modelData.path) + ": " + (modelData.code==="io_error" ? modelData.message : modelData.code==="over_capacity" ? qsTr("Hide a ring or choose a larger size.") : modelData.code==="newer_version" ? qsTr("Open this file with a newer version of the app.") : qsTr("This setting needs attention. Choose a valid value or use the default."))
            }
            Button {
                visible: banner.page!==4 && modelData.code!=="unknown_control"
                text: qsTr("Use the default")
                onClicked: banner.store.useDefault(modelData.path)
            }
        }
    }
}
